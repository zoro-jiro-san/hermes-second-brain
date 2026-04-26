#!/usr/bin/env python3
"""
Build edges for knowledge graph from wiki pages and raw research articles.
Implements co-occurrence + keyword matching to generate relationships.
"""

import json
import re
import sys
from pathlib import Path
from collections import Counter

# Fixed paths within the Second Brain repo
REPO = Path("/home/tokisaki/github/hermes-second-brain")
WIKI_DIR = REPO / "wiki"
RAW_DIR = REPO / "raw" / "articles"
MEMORY_DIR = REPO / "memory"
NODES_PATH = MEMORY_DIR / "graph.nodes.json"
EDGES_PATH = MEMORY_DIR / "graph.edges.json"

# Load entity nodes
if not NODES_PATH.exists():
    print(f"[ERROR] Nodes file not found: {NODES_PATH}", file=sys.stderr)
    sys.exit(1)

with open(NODES_PATH, 'r') as f:
    nodes = json.load(f)

# Build lookup dicts by type
repos = {e['label']: e for e in nodes if e.get('type') == 'repo'}
persons = {e['label']: e for e in nodes if e.get('type') == 'person'}
techs = {e['label']: e for e in nodes if e.get('type') == 'tech'}
patterns = {e['label']: e for e in nodes if e.get('type') == 'pattern'}

edges = []

def normalize(text):
    return re.sub(r'\s+', ' ', text.lower())

# Find all research source files
research_files = sorted(RAW_DIR.glob("research_*.md"))
print(f"[build_edges] Found {len(research_files)} research files")

for rfile in research_files:
    filename = rfile.name
    with open(rfile) as f:
        content = f.read()
    content_norm = normalize(content)
    lines = content.split('\n')

    # Determine main repo for this file from nodes' source_files
    file_repos = [
        e['label'] for e in nodes
        if e.get('type') == 'repo' and filename in e.get('source_files', [])
    ]
    main_repo = file_repos[0] if file_repos else None

    # RULE 1: repo + tech co-occurrence → uses
    for repo_label in repos:
        if repo_label.lower() in content_norm:
            for tech_label in techs:
                if tech_label.lower() in content_norm:
                    # Check sentence-level co-occurrence for higher confidence
                    sent_boundaries = re.split(r'[.!?]\s+', content)
                    found_same_sentence = False
                    for sent in sent_boundaries:
                        sent_norm = normalize(sent)
                        if repo_label.lower() in sent_norm and tech_label.lower() in sent_norm:
                            edges.append({
                                'from': repo_label,
                                'to': tech_label,
                                'relation': 'uses',
                                'confidence': 0.8,
                                'source_file': filename
                            })
                            found_same_sentence = True
                            break
                    if not found_same_sentence:
                        edges.append({
                            'from': repo_label,
                            'to': tech_label,
                            'relation': 'uses',
                            'confidence': 0.6,
                            'source_file': filename
                        })

    # RULE 2: main repo mentions other repos in "related" contexts → related_to
    if main_repo:
        related_keywords = [
            'related projects', 'similar projects', 'alternatives', 'inspired by',
            'similar to', 'like', 'comparable', 'see also', 'related repos',
            'fork of', 'based on', 'derived from'
        ]
        for line in lines:
            line_norm = normalize(line)
            if any(kw in line_norm for kw in related_keywords):
                for repo_label in repos:
                    if repo_label != main_repo and repo_label.lower() in line_norm:
                        confidence = 0.9 if any(kw in line_norm for kw in ['similar to', 'based on']) else 0.7
                        edges.append({
                            'from': main_repo,
                            'to': repo_label,
                            'relation': 'related_to',
                            'confidence': confidence,
                            'source_file': filename
                        })

    # RULE 3: tech + pattern together → implements
    sent_boundaries = re.split(r'[.!?]\s+', content)
    for sent in sent_boundaries:
        sent_norm = normalize(sent)
        techs_in_sent = [t for t in techs if t.lower() in sent_norm]
        patterns_in_sent = [p for p in patterns if p.lower() in sent_norm]
        if techs_in_sent and patterns_in_sent:
            impl_keywords = ['implements', 'follows', 'adopts', 'uses.*pattern', 'pattern of',
                           'based on.*pattern', 'employs', 'leverages']
            kw_present = any(re.search(kw, sent_norm) for kw in impl_keywords)
            for tech in techs_in_sent:
                for pattern in patterns_in_sent:
                    edges.append({
                        'from': tech,
                        'to': pattern,
                        'relation': 'implements',
                        'confidence': 0.85 if kw_present else 0.65,
                        'source_file': filename
                    })

    # RULE 4: person cited as author/creator → created
    if main_repo:
        for person_label in persons:
            if person_label.lower() in ['hermes agent']:
                continue
            author_patterns = [
                rf'by\s+{re.escape(person_label)}',
                rf'{re.escape(person_label)}\s+\(.*(author|creator|maintainer|developer)',
                rf'author[:\s]+{re.escape(person_label)}',
                rf'creator[:\s]+{re.escape(person_label)}',
                rf'originated by\s+{re.escape(person_label)}',
                rf'{re.escape(person_label)}\'s repository',
                rf'^{re.escape(person_label)}'
            ]
            for ap in author_patterns:
                if re.search(ap, content, re.IGNORECASE):
                    edges.append({
                        'from': person_label,
                        'to': main_repo,
                        'relation': 'created',
                        'confidence': 0.95,
                        'source_file': filename
                    })
                    break

# Deduplicate: keep highest confidence per (from, to, relation)
final_edges = []
seen = {}
for edge in edges:
    key = (edge['from'], edge['to'], edge['relation'])
    if key not in seen or edge['confidence'] > seen[key]['confidence']:
        seen[key] = edge

final_edges = list(seen.values())
print(f"[build_edges] Total unique edges: {len(final_edges)}")

# Write output
output_data = []
for edge in sorted(final_edges, key=lambda x: (x['from'], x['to'])):
    output_data.append({
        'from': edge['from'],
        'to': edge['to'],
        'relation': edge['relation'],
        'confidence': round(edge['confidence'], 2),
        'source_file': edge['source_file']
    })

EDGES_PATH.parent.mkdir(parents=True, exist_ok=True)
with open(EDGES_PATH, 'w') as f:
    json.dump(output_data, f, indent=2)

print(f"[build_edges] Wrote edges to {EDGES_PATH}")

# Summary stats
relation_counts = Counter(e['relation'] for e in output_data)
print("[build_edges] Edge breakdown:")
for rel, count in relation_counts.most_common():
    print(f"  {rel}: {count}")

sys.exit(0)
