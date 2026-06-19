"""
convert_model.py
----------------
Converts paraphrase-multilingual-MiniLM-L12-v2 from HuggingFace into a
TFLite file with dynamic-range quantization.

Requirements (must be pre-installed):
    sentence-transformers, transformers, tensorflow, numpy
"""

import os
import numpy as np
import tensorflow as tf
from transformers import AutoTokenizer, TFAutoModel

# ── Config ────────────────────────────────────────────────────────────────────
MODEL_NAME   = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
SAVED_MODEL_DIR = "minilm_saved_model"
TFLITE_PATH     = "minilm.tflite"
SEQ_LEN = 128

print(f"[1/6] Loading TF model: {MODEL_NAME}")
tf_model  = TFAutoModel.from_pretrained(MODEL_NAME, from_pt=True)
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)

# ── Mean-pooling + L2-norm wrapper ────────────────────────────────────────────
class EmbeddingModel(tf.Module):
    def __init__(self, model):
        super().__init__()
        self.model = model

    @tf.function(input_signature=[
        tf.TensorSpec(shape=[1, SEQ_LEN], dtype=tf.int32, name="input_ids"),
        tf.TensorSpec(shape=[1, SEQ_LEN], dtype=tf.int32, name="attention_mask"),
        tf.TensorSpec(shape=[1, SEQ_LEN], dtype=tf.int32, name="token_type_ids"),
    ])
    def serving(self, input_ids, attention_mask, token_type_ids):
        outputs = self.model(
            input_ids=input_ids,
            attention_mask=attention_mask,
            token_type_ids=token_type_ids,
            training=False,
        )
        token_embeddings = outputs.last_hidden_state          # [1, seq, hidden]
        mask = tf.cast(
            tf.expand_dims(attention_mask, -1), dtype=tf.float32
        )                                                      # [1, seq, 1]
        sum_emb  = tf.reduce_sum(token_embeddings * mask, axis=1)   # [1, hidden]
        count    = tf.reduce_sum(mask, axis=1)                      # [1, 1]
        mean_emb = sum_emb / tf.maximum(count, 1e-9)               # [1, hidden]

        # L2 normalise
        embedding = tf.math.l2_normalize(mean_emb, axis=-1)   # [1, hidden]
        return {"embedding": embedding}

print("[2/6] Wrapping model with mean-pooling and L2 normalisation")
wrapper = EmbeddingModel(tf_model)

# ── Save as SavedModel ────────────────────────────────────────────────────────
print(f"[3/6] Saving SavedModel to '{SAVED_MODEL_DIR}/'")
tf.saved_model.save(
    wrapper,
    SAVED_MODEL_DIR,
    signatures={"serving_default": wrapper.serving},
)

# ── Convert to TFLite with dynamic-range quantization ─────────────────────────
print("[4/6] Converting to TFLite (dynamic-range quantization)")
converter = tf.lite.TFLiteConverter.from_saved_model(SAVED_MODEL_DIR)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open(TFLITE_PATH, "wb") as f:
    f.write(tflite_model)
print(f"      Saved '{TFLITE_PATH}' ({os.path.getsize(TFLITE_PATH) / 1e6:.2f} MB)")

# ── Inspect tensor details ────────────────────────────────────────────────────
print("\n[5/6] Tensor details")
interpreter = tf.lite.Interpreter(model_path=TFLITE_PATH)
interpreter.allocate_tensors()

input_details  = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("\n  INPUT tensors:")
for d in input_details:
    print(f"    name={d['name']:40s}  shape={d['shape']}  dtype={d['dtype'].__name__}")

print("\n  OUTPUT tensors:")
for d in output_details:
    print(f"    name={d['name']:40s}  shape={d['shape']}  dtype={d['dtype'].__name__}")

# ── Inference test ─────────────────────────────────────────────────────────────
print('\n[6/6] Running inference test: "breathing difficulty"')
TEST_TEXT = "breathing difficulty"

encoded = tokenizer(
    TEST_TEXT,
    max_length=SEQ_LEN,
    padding="max_length",
    truncation=True,
    return_tensors="np",
)

def _pad_int32(arr):
    out = np.zeros((1, SEQ_LEN), dtype=np.int32)
    out[0, :arr.shape[1]] = arr[0]
    return out

input_ids      = _pad_int32(encoded["input_ids"].astype(np.int32))
attention_mask = _pad_int32(encoded["attention_mask"].astype(np.int32))
token_type_ids = _pad_int32(
    encoded.get("token_type_ids", np.zeros_like(encoded["input_ids"])).astype(np.int32)
)

# Map by name to be order-independent
name_to_detail = {d["name"]: d for d in input_details}
for detail in input_details:
    name = detail["name"]
    if "input_ids" in name:
        interpreter.set_tensor(detail["index"], input_ids)
    elif "attention_mask" in name:
        interpreter.set_tensor(detail["index"], attention_mask)
    elif "token_type_ids" in name:
        interpreter.set_tensor(detail["index"], token_type_ids)

interpreter.invoke()

output = interpreter.get_tensor(output_details[0]["index"])
l2_norm = np.linalg.norm(output)
print(f"  Output shape : {output.shape}")
print(f"  L2 norm      : {l2_norm:.6f}  (should be ≈ 1.0 after normalisation)")
print("\n✅ Conversion complete.")
