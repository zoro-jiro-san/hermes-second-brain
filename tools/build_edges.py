#!/usr/bin/env python3
"""
Build edges for knowledge graph from extracted entities and research files.
Implements simple co-occurrence + keyword matching as specified.
"""

import json
import re
from pathlib import Path
from collections import defaultdict

# Paths
ENTITIES_PATH = Path("/home/tokisaki/work/synthesis/entities.quick.json")
RESEARCH_DIR = Path("/home/tokisaki/work/research-swarm/outputs")
OUTPUT_PATH = Path("/home/tokisaki/work/synthesis/graph.edges.json")

# Load entities
with open(ENTITIES_PATH, 'r') as f:
    entities = json.load(f)

# Build lookup dicts
repos = {e['label']: e for e in entities if e['type'] == 'repo'}
persons = {e['label']: e for e in entities if e['type'] == 'person'}
techs = {e['label']: e for e in entities if e['type'] == 'tech'}
patterns = {e['label']: e for e in entities if e['type'] == 'pattern'}

# All entity labels for quick lookup
all_entities = {e['label']: e for e in entities}

# Find all research files
research_files = sorted(RESEARCH_DIR.glob("research_*.md"))
print(f"Found {len(research_files)} research files")

edges = []

def confidence_from_context(matches, keyword_present=False):
    """Calculate confidence based on number of entity mentions and keyword presence."""
    base = 0.5  # base confidence for co-occurrence
    count_bonus = min(0.3, len(matches) * 0.1)
    keyword_bonus = 0.2 if keyword_present else 0.0
    return min(1.0, base + count_bonus + keyword_bonus)

# Text normalization: lowercase, collapse whitespace
def normalize(text):
    return re.sub(r'\s+', ' ', text.lower())

for rfile in research_files:
    filename = rfile.name
    print(f"Processing {filename}...")
    
    with open(rfile, 'r') as f:
        content = f.read()
    
    content_norm = normalize(content)
    lines = content.split('\n')
    
    # Determine the main repo for this research file (from entities or filename mapping)
    # The entities have source_file field matching the research filename
    file_repos = [e['label'] for e in entities if e['source_file'] == filename and e['type'] == 'repo']
    main_repo = file_repos[0] if file_repos else None
    
    # --- RULE 1: tech/tool X + repo Y → Y -> uses -> X ---
    # Find co-occurrence of any repo and any tech in the same paragraph/section
    for repo_label, repo_entity in repos.items():
        # Check if repo is mentioned in this file
        if repo_label.lower() in content_norm:
            for tech_label, tech_entity in techs.items():
                if tech_label.lower() in content_norm:
                    # Simple heuristic: if they appear in the same paragraph or within 5 lines of each other
                    # Search for co-occurrence in same sentences/paragraphs
                    sent_boundaries = re.split(r'[.!?]\s+', content)
                    for sent in sent_boundaries:
                        sent_norm = normalize(sent)
                        if repo_label.lower() in sent_norm and tech_label.lower() in sent_norm:
                            # Found in same sentence - higher confidence
                            edge = {
                                'from': repo_label,
                                'to': tech_label,
                                'relation': 'uses',
                                'confidence': 0.8,
                                'source_file': filename
                            }
                            if edge not in edges:
                                edges.append(edge)
                            break
                    else:
                        # Not in same sentence but both in file - medium confidence
                        edge = {
                            'from': repo_label,
                            'to': tech_label,
                            'relation': 'uses',
                            'confidence': 0.6,
                            'source_file': filename
                        }
                        if edge not in edges:
                            edges.append(edge)
    
    # --- RULE 2: main repo RepoA mentions another repo RepoB in "related projects" or "similar to" → related_to ---
    if main_repo:
        # Look for sections with keywords indicating related/similar repos
        related_keywords = ['related projects', 'similar projects', 'alternatives', 'inspired by', 
                           'similar to', 'like', 'comparable', 'see also', 'related repos',
                           'fork of', 'based on', 'derived from']
        
        for line in lines:
            line_norm = normalize(line)
            if any(kw in line_norm for kw in related_keywords):
                # Find all repo mentions in this line or nearby context
                for repo_label, repo_entity in repos.items():
                    if repo_label != main_repo and repo_label.lower() in line_norm:
                        edge = {
                            'from': main_repo,
                            'to': repo_label,
                            'relation': 'related_to',
                            'confidence': 0.9 if any(kw in line_norm for kw in ['similar to', 'based on']) else 0.7,
                            'source_file': filename
                        }
                        if edge not in edges:
                            edges.append(edge)
    
    # --- RULE 3: pattern P + tech T together → T -> implements -> P ---
    # Look for sentences that mention both a tech and a pattern
    sent_boundaries = re.split(r'[.!?]\s+', content)
    for sent in sent_boundaries:
        sent_norm = normalize(sent)
        techs_in_sent = [t for t in techs if t.lower() in sent_norm]
        patterns_in_sent = [p for p in patterns if p.lower() in sent_norm]
        
        if techs_in_sent and patterns_in_sent:
            # Multiple combinations possible
            for tech in techs_in_sent:
                for pattern in patterns_in_sent:
                    # Increase confidence if keywords like "implements", "follows", "uses", "pattern" are present
                    impl_keywords = ['implements', 'follows', 'adopts', 'uses.*pattern', 'pattern of', 
                                   'based on.*pattern', 'employs', 'leverages']
                    kw_present = any(re.search(kw, sent_norm) for kw in impl_keywords)
                    
                    edge = {
                        'from': tech,
                        'to': pattern,
                        'relation': 'implements',
                        'confidence': 0.85 if kw_present else 0.65,
                        'source_file': filename
                    }
                    if edge not in edges:
                        edges.append(edge)
    
    # --- RULE 4: person cited as author/creator → person -> created -> repo ---
    # Check for main repo authorship
    if main_repo:
        # Look for explicit author/creator mentions in the file
        for person_label in persons:
            # Skip generic "Hermes Agent" mentions as they're typically the researcher, not creator
            if person_label.lower() in ['hermes agent']:
                continue
                
            # Check if person is explicitly cited as author/creator/maintainer
            author_patterns = [
                rf'by\s+{re.escape(person_label)}',
                rf'{re.escape(person_label)}\s+\(.*(author|creator|maintainer|developer)',
                rf'author[:\s]+{re.escape(person_label)}',
                rf'creator[:\s]+{re.escape(person_label)}',
                rf'originated by\s+{re.escape(person_label)}',
                rf'{re.escape(person_label)}\'s repository',
                rf'^{re.escape(person_label)}'  # at start of line as attribution
            ]
            
            for ap in author_patterns:
                if re.search(ap, content, re.IGNORECASE):
                    edge = {
                        'from': person_label,
                        'to': main_repo,
                        'relation': 'created',
                        'confidence': 0.95,
                        'source_file': filename
                    }
                    if edge not in edges:
                        edges.append(edge)
                    break
    
    print(f"  Accumulated {len(edges)} edges so far")

# Deduplicate edges with highest confidence
final_edges = []
seen = {}
for edge in edges:
    key = (edge['from'], edge['to'], edge['relation'])
    if key not in seen or edge['confidence'] > seen[key]['confidence']:
        seen[key] = edge

final_edges = list(seen.values())
print(f"\nTotal unique edges: {len(final_edges)}")

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

with open(OUTPUT_PATH, 'w') as f:
    json.dump(output_data, f, indent=2)

print(f"Wrote edges to {OUTPUT_PATH}")
print(f"\nEdge breakdown by relation type:")
from collections import Counter
relation_counts = Counter(e['relation'] for e in output_data)
for rel, count in relation_counts.most_common():
    print(f"  {rel}: {count}")
