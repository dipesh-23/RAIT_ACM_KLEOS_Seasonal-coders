import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class EmbeddingService {
  static final EmbeddingService instance = EmbeddingService._internal();
  EmbeddingService._internal();

  Interpreter? _interpreter;
  Map<String, int> _vocab = {};
  bool _isInitialized = false;

  static const int _maxLength = 128;
  static const int _embeddingDim = 384;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      await _loadVocab();
      await _loadModel();
      _isInitialized = true;
    } catch (e) {
      // Graceful degradation — embedding service fails silently
      // App will use keyword fallback in triage engine
      _isInitialized = false;
    }
  }

  Future<void> _loadVocab() async {
    try {
      final vocabString =
          await rootBundle.loadString('assets/model/vocab.txt');
      final lines = vocabString.split('\n');
      _vocab = {};
      for (int i = 0; i < lines.length; i++) {
        final token = lines[i].trim();
        if (token.isNotEmpty) {
          _vocab[token] = i;
        }
      }
    } catch (_) {
      _vocab = {};
    }
  }

  Future<void> _loadModel() async {
    final modelData = await rootBundle.load('assets/model/minilm.tflite');
    final buffer = modelData.buffer;
    final modelBytes =
        buffer.asUint8List(modelData.offsetInBytes, modelData.lengthInBytes);

    // Check if placeholder file — real TFLite starts with magic bytes
    if (modelBytes.length < 8 || modelBytes[4] != 0x20) {
      throw Exception('Placeholder TFLite file — real model not loaded');
    }

    _interpreter = Interpreter.fromBuffer(modelBytes);
  }

  List<int> _tokenize(String text) {
    if (_vocab.isEmpty) return List.filled(_maxLength, 0);

    final clsId = _vocab['[CLS]'] ?? 101;
    final sepId = _vocab['[SEP]'] ?? 102;
    final unkId = _vocab['[UNK]'] ?? 100;
    final padId = _vocab['[PAD]'] ?? 0;

    final normalised = text.toLowerCase().trim();
    final tokens = <int>[clsId];

    // Simple whitespace + subword tokenization
    final words = normalised.split(RegExp(r'\s+'));
    for (final word in words) {
      if (tokens.length >= _maxLength - 1) break;
      if (word.isEmpty) continue;

      if (_vocab.containsKey(word)) {
        tokens.add(_vocab[word]!);
      } else {
        // WordPiece: try character-level subwords
        bool addedAny = false;
        String remaining = word;
        while (remaining.isNotEmpty && tokens.length < _maxLength - 1) {
          int matchLen = remaining.length;

          bool found = false;
          while (matchLen > 0) {
            final sub = addedAny
                ? '##${remaining.substring(0, matchLen)}'
                : remaining.substring(0, matchLen);
            if (_vocab.containsKey(sub)) {
              tokens.add(_vocab[sub]!);
              remaining = remaining.substring(matchLen);
              addedAny = true;
              found = true;
              break;
            }
            matchLen--;
          }
          if (!found) {
            tokens.add(unkId);
            break;
          }
        }
        if (!addedAny) tokens.add(unkId);
      }
    }

    tokens.add(sepId);

    // Pad to maxLength
    while (tokens.length < _maxLength) {
      tokens.add(padId);
    }

    return tokens.sublist(0, _maxLength);
  }

  Future<List<double>> getEmbedding(String text) async {
    if (!_isInitialized || _interpreter == null) {
      // Return zero vector as graceful fallback
      return List.filled(_embeddingDim, 0.0);
    }

    try {
      final inputIds = _tokenize(text);
      final attentionMask =
          inputIds.map((id) => id != 0 ? 1 : 0).toList();
      final tokenTypeIds = List.filled(_maxLength, 0);

      // Shape [1, 128]
      final inputIdsTensor = [inputIds];
      final attentionMaskTensor = [attentionMask];
      final tokenTypeIdsTensor = [tokenTypeIds];

      // Output shape [1, 128, 384]
      final outputTensor = [
        List.generate(
            _maxLength, (_) => List.filled(_embeddingDim, 0.0))
      ];

      _interpreter!.runForMultipleInputs(
        [inputIdsTensor, attentionMaskTensor, tokenTypeIdsTensor],
        {0: outputTensor},
      );

      // Mean pooling over non-padding tokens
      final mask = attentionMask;
      final validCount = mask.reduce((a, b) => a + b);
      final pooled = List.filled(_embeddingDim, 0.0);

      for (int t = 0; t < _maxLength; t++) {
        if (mask[t] == 1) {
          for (int d = 0; d < _embeddingDim; d++) {
            pooled[d] += outputTensor[0][t][d];
          }
        }
      }

      for (int d = 0; d < _embeddingDim; d++) {
        pooled[d] /= validCount.toDouble();
      }

      return pooled;
    } catch (_) {
      return List.filled(_embeddingDim, 0.0);
    }
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = sqrt(normA) * sqrt(normB);
    if (denom == 0.0) return 0.0;
    return (dot / denom).clamp(0.0, 1.0);
  }
}
