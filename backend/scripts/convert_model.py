#!/usr/bin/env python3
"""
convert_model.py — Run this ONCE before building the APK.
Converts paraphrase-multilingual-MiniLM-L12-v2 to TFLite format.

Usage:
    pip install sentence-transformers tensorflow
    python scripts/convert_model.py

Output:
    ../frontend/assets/model/minilm.tflite
    ../frontend/assets/model/vocab.txt  (auto-copied)
"""
import os
import shutil
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent.parent / "frontend" / "assets" / "model"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

MODEL_NAME = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
SAVED_MODEL_PATH = Path("/tmp/minilm_saved")
TFLITE_OUTPUT = OUTPUT_DIR / "minilm.tflite"
VOCAB_OUTPUT = OUTPUT_DIR / "vocab.txt"


def convert():
    print(f"Loading {MODEL_NAME} ...")
    from sentence_transformers import SentenceTransformer
    import tensorflow as tf
    import numpy as np

    model = SentenceTransformer(MODEL_NAME)

    # Save as SavedModel
    print("Saving as TF SavedModel ...")
    tf_model = model[0].auto_model  # Transformer backbone
    tf_model.save_pretrained(str(SAVED_MODEL_PATH))

    # Convert to TFLite
    print("Converting to TFLite with dynamic-range quantization ...")
    converter = tf.lite.TFLiteConverter.from_pretrained_model(
        str(SAVED_MODEL_PATH)
    )
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    with open(TFLITE_OUTPUT, "wb") as f:
        f.write(tflite_model)
    print(f"✓ Saved: {TFLITE_OUTPUT} ({len(tflite_model)//1024//1024} MB)")

    # Copy vocab.txt from HuggingFace cache
    cache_vocab = Path.home() / ".cache" / "huggingface" / "hub"
    vocab_files = list(cache_vocab.rglob("vocab.txt"))
    minilm_vocab = [v for v in vocab_files if "MiniLM" in str(v) or "multilingual" in str(v)]
    if minilm_vocab:
        shutil.copy(minilm_vocab[0], VOCAB_OUTPUT)
        print(f"✓ vocab.txt copied to {VOCAB_OUTPUT}")
    else:
        print("⚠ vocab.txt not found in cache. Download manually:")
        print("  https://huggingface.co/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2/resolve/main/vocab.txt")
        print(f"  Place at: {VOCAB_OUTPUT}")


if __name__ == "__main__":
    convert()
