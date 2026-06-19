import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Loads `minilm.tflite` and `vocab.txt` from assets, tokenises text
/// using an on-device WordPiece implementation, and returns a
/// 384-dimensional L2-normalised sentence embedding.
class EmbeddingService {
  // ── Singleton ────────────────────────────────────────────────────────────────
  EmbeddingService._();
  static final EmbeddingService instance = EmbeddingService._();

  // ── Constants ───────────────────────────────────────────────────────────────
  static const int _seqLen  = 128;
  static const int _clsTokenId = 101;   // [CLS]
  static const int _sepTokenId = 102;   // [SEP]
  static const int _padTokenId = 0;     // [PAD]
  static const int _unkTokenId = 100;   // [UNK]

  // ── State ───────────────────────────────────────────────────────────────────
  late final Interpreter _interpreter;
  late final Map<String, int> _vocab;   // token → id
  bool _isInitialized = false;

  /// Whether [init] has completed successfully.
  bool get isInitialized => _isInitialized;

  // ── Initialisation ──────────────────────────────────────────────────────────

  /// Call once before using [getEmbedding]. Loads model and vocab from assets.
  Future<void> initialize() async {
    if (_isInitialized) return;
    await Future.wait([_loadModel(), _loadVocab()]);
    _isInitialized = true;
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model/minilm.tflite');
  }

  Future<void> _loadVocab() async {
    final raw = await rootBundle.loadString('assets/model/vocab.txt');
    final lines = raw.split('\n');
    _vocab = {};
    for (int i = 0; i < lines.length; i++) {
      final token = lines[i].trim();
      if (token.isNotEmpty) _vocab[token] = i;
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns a 384-dimensional L2-normalised embedding for [text].
  ///
  /// Throws [StateError] if [initialize] has not been called (or has not completed).
  List<double> getEmbedding(String text) {
    if (!_isInitialized) {
      throw StateError(
        'EmbeddingService is not initialised. '
        'Await EmbeddingService.initialize() before calling getEmbedding().',
      );
    }

    // ── Build input tensors ──────────────────────────────────────────────────
    // tokenize() returns exactly _seqLen IDs: [CLS] + tokens + [SEP] + [PAD]s
    final ids = tokenize(text);

    // attentionMask: 1 for every real token, 0 for every [PAD]
    final attentionMask = ids
        .map((id) => id != _padTokenId ? 1 : 0)
        .toList();

    // tokenTypeIds: all zeros (single-sentence input, no segment B)
    final tokenTypeIds = List<int>.filled(_seqLen, 0);

    // Wrap in outer list to represent batch size 1 → shape [1, 128]
    final inputIds      = [ids];
    final attnMask      = [attentionMask];
    final tokenTypesIn  = [tokenTypeIds];

    // ── Output buffer ────────────────────────────────────────────────────────
    // Shape [1, 384]: one sentence embedding of 384 dimensions
    final outputBuffer = [List<double>.filled(384, 0.0)];
    const int outputIdx = 0;

    // ── Inference ────────────────────────────────────────────────────────────
    final inputTensorCount = _interpreter.getInputTensors().length;
    final List<Object> inputs;
    if (inputTensorCount == 3) {
      inputs = [inputIds, attnMask, tokenTypesIn];
    } else {
      inputs = [inputIds, attnMask];
    }

    _interpreter.runForMultipleInputs(
      inputs,
      {outputIdx: outputBuffer},
    );

    // Return the inner 384-element list (unwrap the batch dimension)
    return outputBuffer[0];
  }

  void dispose() => _interpreter.close();

  // ── Tokenisation ────────────────────────────────────────────────────────────

  /// Converts [text] into a fixed-length list of exactly [_seqLen] token IDs:
  ///   [CLS] + word-piece tokens + [SEP] + [PAD]s (or truncated to fit).
  ///
  /// Split pattern covers ASCII whitespace, common punctuation, and the
  /// Hindi danda (।) and double-danda (॥) characters.
  List<int> tokenize(String text) {
    // Normalise and split
    final cleaned = text.trim();
    // Split on: whitespace, . , ! ? ; : ( ) [ ] " ' / - and Hindi dandas
    final words = cleaned
        .split(RegExp('[\\s.,!?;:()\\[\\]"\'/\\-।॥]+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // WordPiece each word into sub-token IDs
    final tokenIds = <int>[];
    for (final word in words) {
      tokenIds.addAll(_wordPieceTokenize(word));
    }

    // Build final sequence: [CLS] + tokens + [SEP], then pad / truncate
    final maxContent = _seqLen - 2; // reserve slots for CLS + SEP
    final content    = tokenIds.length > maxContent
        ? tokenIds.sublist(0, maxContent)
        : tokenIds;

    final result = <int>[
      _clsTokenId,
      ...content,
      _sepTokenId,
    ];

    // Pad to exactly _seqLen
    while (result.length < _seqLen) {
      result.add(_padTokenId);
    }

    // Should already be exactly _seqLen; guard just in case
    return result.sublist(0, _seqLen);
  }

  // ── WordPiece ───────────────────────────────────────────────────────────────

  /// Tokenises a single [word] into a list of vocabulary IDs using the
  /// WordPiece algorithm (the same algorithm used by BERT-family models).
  ///
  /// Lookup order for each candidate substring:
  ///   1. Exact match in vocab
  ///   2. Lowercase version
  ///   3. Returns [[_unkTokenId]] if the whole word cannot be decomposed.
  List<int> _wordPieceTokenize(String word) {
    if (word.isEmpty) return [];

    // Fast path: whole word is in vocab (covers most CJK / accented tokens)
    final wholeId = _vocabId(word);
    if (wholeId != null) return [wholeId];

    final result  = <int>[];
    int start = 0;

    while (start < word.length) {
      int end     = word.length;
      int? foundId;
      String? foundSub;

      // Try progressively shorter substrings from [start..end)
      while (end > start) {
        final raw = word.substring(start, end);
        final sub = start == 0 ? raw : '##$raw';

        final id = _vocabId(sub);
        if (id != null) {
          foundId  = id;
          foundSub = sub;
          break;
        }
        end--;
      }

      if (foundId == null) {
        // No sub-token found for the remainder → whole word is UNK
        return [_unkTokenId];
      }

      result.add(foundId);
      start += (start == 0 ? foundSub!.length : foundSub!.length - 2);
    }

    return result.isEmpty ? [_unkTokenId] : result;
  }

  // ── Vocab helpers ───────────────────────────────────────────────────────────

  /// Returns the vocabulary ID for [token], trying exact then lowercase.
  /// Returns null if neither is found.
  int? _vocabId(String token) =>
      _vocab[token] ?? _vocab[token.toLowerCase()];
}
