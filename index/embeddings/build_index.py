#!/usr/bin/env python3
"""Lightweight lexical search index (BM25-like) — no external deps."""
import json, re, math, sys
from pathlib import Path
from collections import defaultdict, Counter

REPO = Path(__file__).parent.parent.parent
WIKI = REPO / "wiki"
INDEX_DIR = REPO / "index" / "embeddings"

def tokenize(text):
    text = text.lower()
    words = re.findall(r'\b\w+\b', text)
    return [w for w in words if len(w) > 2]  # drop short words

docs = []
for md in sorted(WIKI.glob("*.md")):
    txt = md.read_text()
    # Strip frontmatter
    fm = re.search(r'---\s*.*?\s*---', txt, re.DOTALL)
    if fm:
        txt = txt[fm.end():]
    docs.append({"file": md.name, "text": txt})

N = len(docs)
print(f"Indexing {N} documents")

# Compute IDF
doc_freq = defaultdict(int)
for doc in docs:
    tokens = set(tokenize(doc["text"]))
    for t in tokens:
        doc_freq[t] += 1

idf = {t: math.log((N - df + 0.5) / (df + 0.5) + 1) for t, df in doc_freq.items()}

# Build index: term → {doc_id: tf_score}
index = defaultdict(dict)
for i, doc in enumerate(docs):
    tokens = tokenize(doc["text"])
    tf = Counter(tokens)
    for t, cnt in tf.items():
        if t in idf:
            index[t][i] = (cnt / len(tokens)) * idf[t]

# Save
(INDEX_DIR).mkdir(parents=True, exist_ok=True)
with open(INDEX_DIR / "index.json", "w") as f:
    json.dump({"docs": [{"file": d["file"]} for d in docs], "index": index}, f, indent=2)

print(f"Index built: {len(index)} terms, {N} docs → {INDEX_DIR}")
