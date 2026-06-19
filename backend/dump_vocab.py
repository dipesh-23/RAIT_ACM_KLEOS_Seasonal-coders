"""
dump_vocab.py
-------------
Loads the tokenizer for paraphrase-multilingual-MiniLM-L12-v2, sorts
the full vocabulary by token ID (ascending), and writes one token per
line to vocab.txt.

Requirements (must be pre-installed):
    transformers
"""

from transformers import AutoTokenizer

MODEL_NAME  = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
OUTPUT_FILE = "vocab.txt"

print(f"Loading tokenizer: {MODEL_NAME}")
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)

# vocab() returns {token_str: token_id}
vocab: dict[str, int] = tokenizer.get_vocab()

# Sort by token ID ascending
sorted_tokens = [token for token, _ in sorted(vocab.items(), key=lambda x: x[1])]

print(f"Writing {len(sorted_tokens)} tokens to '{OUTPUT_FILE}' ...")
with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    for token in sorted_tokens:
        f.write(token + "\n")

print(f"Total tokens written: {len(sorted_tokens)}")
