import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Frame-level Voice Activity Detection (VAD) based noise suppressor.
///
/// ## Algorithm
/// 1. **Calibration** — first [calibrationFramesNeeded] frames build the
///    ambient noise-floor RMS. Frames whose own RMS exceeds
///    [calibrationSpeechCeiling] are skipped so that speech at session start
///    cannot inflate the noise floor.
/// 2. **Speech detection** — after calibration a 5-frame rolling RMS average
///    is compared against `noiseFloor × gateThresholdMultiplier`.
/// 3. **Hangover** — once a speech frame is detected, [hangoverFrames]
///    additional frames are passed through regardless of energy, so trailing
///    phonemes (plosives, fricatives) are never clipped.
/// 4. **Pass-through** — speech frames are returned **byte-for-byte
///    unchanged** — the waveform Vosk sees is never sample-modified.
/// 5. **Silence** — non-speech frames outside hangover return a zero-filled
///    buffer. Vosk treats silence correctly in its HMM.
class NoiseSuppressor {
  // ---------------------------------------------------------------------------
  // Calibration state
  // ---------------------------------------------------------------------------

  double _noiseFloorRms = 0.0;
  double _calibrationSumSq = 0.0;
  int _calibrationSampleCount = 0;
  int _calibrationFrameCount = 0;
  bool _isCalibrated = false;

  // ---------------------------------------------------------------------------
  // Rolling RMS smoother (5-frame window)
  // ---------------------------------------------------------------------------

  static const int _rmsWindowSize = 5;
  final List<double> _rmsHistory = [];
  double _smoothedRms = 0.0;

  // ---------------------------------------------------------------------------
  // Hangover state
  // ---------------------------------------------------------------------------

  int _hangoverRemaining = 0;

  // ---------------------------------------------------------------------------
  // Tuning constants
  // ---------------------------------------------------------------------------

  /// Frames used to measure the ambient noise floor.
  /// Only frames below [calibrationSpeechCeiling] are included.
  /// At ~50 ms/frame → ≈ 600 ms of actual silence needed.
  static const int calibrationFramesNeeded = 12;

  /// During calibration, any frame whose RMS exceeds this value is treated as
  /// speech and skipped, protecting the noise floor estimate.
  /// 0.02 ≈ a soft voice at 30 cm; anything louder is likely speech.
  static const double calibrationSpeechCeiling = 0.02;

  /// A smoothed-RMS above `noiseFloor × gateThresholdMultiplier` is speech.
  /// 1.3 is conservative — passes quiet speakers; the hangover handles edges.
  static const double gateThresholdMultiplier = 1.3;

  /// Extra frames passed after the last speech frame to avoid clipping
  /// trailing fricatives / plosives (e.g. "s", "t", "k").
  static const int hangoverFrames = 6;

  // smoothingAlpha: used for the per-sample EMA profile (debugging only).
  static const double smoothingAlpha = 0.85;

  // ---------------------------------------------------------------------------
  // Public accessors
  // ---------------------------------------------------------------------------

  bool get isCalibrated => _isCalibrated;
  int get calibrationFrameCount => _calibrationFrameCount;
  double get noiseFloorRms => _noiseFloorRms;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  void reset() {
    _isCalibrated = false;
    _calibrationFrameCount = 0;
    _noiseFloorRms = 0.0;
    _calibrationSumSq = 0.0;
    _calibrationSampleCount = 0;
    _rmsHistory.clear();
    _smoothedRms = 0.0;
    _hangoverRemaining = 0;
    debugPrint('[NOISE] NoiseSuppressor reset — recalibrating.');
  }

  /// Main entry point. Accepts raw PCM-16 LE [bytes] and returns either:
  /// - The **original** bytes if this frame is speech or within hangover, or
  /// - A zero-filled [Uint8List] of the same length if the frame is noise.
  ///
  /// During calibration (first [calibrationFramesNeeded] qualifying frames)
  /// always returns the original bytes so Vosk keeps receiving audio.
  Uint8List process(Uint8List bytes) {
    if (bytes.isEmpty) return bytes;

    // ── Decode PCM-16 LE → RMS ──────────────────────────────────────────────
    final int sampleCount = bytes.length ~/ 2;
    final ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.length);

    double sumSq = 0.0;
    for (int i = 0; i < sampleCount; i++) {
      final double s = bd.getInt16(i * 2, Endian.little) / 32768.0;
      sumSq += s * s;
    }
    final double frameRms =
        sampleCount > 0 ? math.sqrt(sumSq / sampleCount) : 0.0;

    // ── Update rolling RMS smoother ─────────────────────────────────────────
    _rmsHistory.add(frameRms);
    if (_rmsHistory.length > _rmsWindowSize) _rmsHistory.removeAt(0);
    _smoothedRms =
        _rmsHistory.reduce((a, b) => a + b) / _rmsHistory.length;

    // ── Calibration phase ────────────────────────────────────────────────────
    if (!_isCalibrated) {
      _updateCalibration(frameRms, sumSq, sampleCount);
      return bytes; // always pass through during calibration
    }

    // ── VAD gate ─────────────────────────────────────────────────────────────
    final double speechThreshold = _noiseFloorRms * gateThresholdMultiplier;
    final bool isSpeech = _smoothedRms > speechThreshold;

    if (isSpeech) {
      _hangoverRemaining = hangoverFrames; // restart hangover countdown
      return bytes; // speech — pass original bytes to Vosk untouched
    }

    if (_hangoverRemaining > 0) {
      _hangoverRemaining--;
      return bytes; // trailing speech — pass through to avoid phoneme clipping
    }

    // Noise frame — send silence so Vosk doesn't accumulate garbage input.
    return Uint8List(bytes.length);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _updateCalibration(
      double frameRms, double sumSq, int sampleCount) {
    if (_isCalibrated) return;

    // Skip frames that look like speech — protects the noise floor estimate
    // when the user starts talking before calibration is complete.
    if (frameRms > calibrationSpeechCeiling) {
      debugPrint('[NOISE] Calibration frame skipped (RMS=${frameRms.toStringAsFixed(5)} > ceiling).');
      return;
    }

    _calibrationSumSq += sumSq;
    _calibrationSampleCount += sampleCount;
    _calibrationFrameCount++;

    if (_calibrationFrameCount >= calibrationFramesNeeded) {
      _isCalibrated = true;
      _noiseFloorRms = _calibrationSampleCount > 0
          ? math.sqrt(_calibrationSumSq / _calibrationSampleCount)
          : 0.001; // fallback: nearly silent floor

      // Guard against a near-zero floor (silent room) which would gate nothing.
      if (_noiseFloorRms < 0.0005) _noiseFloorRms = 0.0005;

      debugPrint(
          '[NOISE] CALIBRATED — noise floor RMS: '
          '${_noiseFloorRms.toStringAsFixed(6)}, '
          'speech threshold: '
          '${(_noiseFloorRms * gateThresholdMultiplier).toStringAsFixed(6)}');
    }
  }
}
