import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Frame-level Voice Activity Detection (VAD) based noise suppressor.
///
/// Strategy: compare each frame's RMS energy against the calibrated noise-floor
/// RMS. If the frame is louder than the floor by [gateThresholdMultiplier],
/// pass the **original bytes unchanged** to Vosk. Otherwise return a zero
/// (silence) frame.
///
/// Crucially, speech frames are **never sample-modified** — this preserves the
/// exact waveform that Vosk's acoustic model was trained on.
class NoiseSuppressor {
  // ---------------------------------------------------------------------------
  // Calibration state
  // ---------------------------------------------------------------------------

  /// Per-sample EMA of absolute values — kept for inspection / debugging.
  List<double> _noiseProfile = [];

  /// Scalar RMS of the noise floor (computed once calibration completes).
  double _noiseFloorRms = 0.0;

  /// Accumulates sum-of-squares during calibration to derive RMS.
  double _calibrationSumSq = 0.0;
  int _calibrationSampleCount = 0;

  bool _isCalibrated = false;
  int _calibrationFrameCount = 0;

  // ---------------------------------------------------------------------------
  // Tuning constants
  // ---------------------------------------------------------------------------

  /// Number of audio frames that define the noise floor.
  /// Each chunk from `record` is typically 40–100 ms, so 15 frames ≈ 0.6–1.5 s.
  static const int calibrationFramesNeeded = 15;

  /// A frame whose RMS is above `noiseFloorRms × gateThresholdMultiplier`
  /// is classified as speech and passed through unchanged.
  /// 1.8 is deliberately conservative — better to let a little noise through
  /// than to accidentally gate out quiet speech.
  static const double gateThresholdMultiplier = 1.8;

  // smoothingAlpha kept for the noise-profile EMA (profile tracking only).
  static const double smoothingAlpha = 0.85;

  // ---------------------------------------------------------------------------
  // Public accessors
  // ---------------------------------------------------------------------------

  bool get isCalibrated => _isCalibrated;
  int get calibrationFrameCount => _calibrationFrameCount;
  List<double> get noiseProfile => List.unmodifiable(_noiseProfile);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  void reset() {
    _isCalibrated = false;
    _calibrationFrameCount = 0;
    _noiseProfile = [];
    _noiseFloorRms = 0.0;
    _calibrationSumSq = 0.0;
    _calibrationSampleCount = 0;
    debugPrint('[NOISE] NoiseSuppressor reset — recalibrating.');
  }

  /// Main entry point. Accepts raw PCM-16 LE [bytes] and returns either:
  /// - The **original** bytes if the frame is speech (RMS > threshold), or
  /// - A zero-filled [Uint8List] of the same length if the frame is noise.
  ///
  /// During calibration (first [calibrationFramesNeeded] frames) always
  /// returns the original bytes so Vosk keeps receiving audio.
  Uint8List process(Uint8List bytes) {
    if (bytes.isEmpty) return bytes;

    // Decode PCM-16 LE → float samples (needed for energy calculation).
    final int sampleCount = bytes.length ~/ 2;
    final ByteData bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.length);

    double sumSq = 0.0;
    final List<double> frame = List<double>.filled(sampleCount, 0.0);
    for (int i = 0; i < sampleCount; i++) {
      final double s = bd.getInt16(i * 2, Endian.little) / 32768.0;
      frame[i] = s;
      sumSq += s * s;
    }
    final double frameRms = math.sqrt(sumSq / sampleCount);

    // ── Calibration phase ────────────────────────────────────────────────────
    if (!_isCalibrated) {
      _updateNoiseProfile(frame, frameRms, sampleCount, sumSq);
      return bytes; // pass through unchanged during calibration
    }

    // ── VAD gate ─────────────────────────────────────────────────────────────
    // If this frame is louder than the noise floor × multiplier → speech.
    if (frameRms > _noiseFloorRms * gateThresholdMultiplier) {
      return bytes; // speech frame — pass original bytes to Vosk untouched
    }

    // Noise frame — send silence so Vosk doesn't accumulate garbage.
    return Uint8List(bytes.length);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _updateNoiseProfile(
      List<double> frame, double frameRms, int sampleCount, double sumSq) {
    if (_isCalibrated) return;

    // Per-sample EMA profile (for inspection).
    if (_noiseProfile.isEmpty) {
      _noiseProfile = List<double>.filled(frame.length, 0.0);
    }
    for (int i = 0; i < frame.length; i++) {
      _noiseProfile[i] =
          smoothingAlpha * _noiseProfile[i] + (1.0 - smoothingAlpha) * frame[i].abs();
    }

    // Accumulate sum-of-squares for RMS noise floor.
    _calibrationSumSq += sumSq;
    _calibrationSampleCount += sampleCount;
    _calibrationFrameCount++;

    if (_calibrationFrameCount >= calibrationFramesNeeded) {
      _isCalibrated = true;
      _noiseFloorRms = _calibrationSampleCount > 0
          ? math.sqrt(_calibrationSumSq / _calibrationSampleCount)
          : 0.001;
      debugPrint(
          '[NOISE] NOISE SUPPRESSOR CALIBRATED — noise floor RMS: '
          '${_noiseFloorRms.toStringAsFixed(6)}, '
          'speech threshold RMS: '
          '${(_noiseFloorRms * gateThresholdMultiplier).toStringAsFixed(6)}');
    }
  }
}
