/// Stub EmbeddingService — TFLite model removed.
/// All calls are no-ops; the TriageEngine now uses keyword matching directly.
class EmbeddingService {
  // ── Singleton ────────────────────────────────────────────────────────────────
  EmbeddingService._();
  static final EmbeddingService instance = EmbeddingService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// No-op initialisation (model removed).
  Future<void> initialize() async {
    _isInitialized = true;
  }

  /// Stub — returns an empty list. Not used anymore.
  List<double> getEmbedding(String text) => [];

  void dispose() {}
}
