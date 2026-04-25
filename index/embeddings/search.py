#!/usr/bin/env python3
"""Search the wiki using TF-IDF lexical index."""
import json, sys, math
from pathlib import Path

REPO = Path(__file__).parent.parent.parent
INDEX_DIR = REPO / "index" / "embeddings"

def load_index():
    with open(INDEX_DIR / "index.json") as f:
        data = json.load(f)
    return data["docs"], data["index"]

def tokenize(text):
    import re
    words = re.findall(r'\b\w+\b', text.lower())
    return [w for w in words if len(w) > 2]

def search(query, top_k=5):
    docs, index = load_index()
    query_terms = tokenize(query)
    
    scores = [0.0] * len(docs)
    for term in query_terms:
        if term in index:
            for doc_id, weight in index[term].items():
                scores[int(doc_id)] += weight
    
    # Sort by score
    results = sorted([(scores[i], docs[i]["file"]) for i in range(len(docs)) if scores[i] > 0], reverse=True)
    return results[:top_k]

if __name__ == "__main__":
    q = sys.argv[1] if len(sys.argv) > 1 else ""
    for score, file in search(q):
        print(f"[{score:.4f}] {file}")
