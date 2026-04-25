#!/usr/bin/env python3
"""
Update knowledge graph by extracting [[wikilinks]] from wiki pages.

This script:
- Loads existing graph nodes/edges from memory/
- Scans all wiki/*.md files
- Extracts [[wikilink]] patterns
- Creates 'page' nodes for each wiki page
- Creates 'links_to' edges between pages based on wikilinks
- Merges with existing graph (no duplicates)
- Saves updated graph back to memory/

Node ID format: page:<stem>  (e.g. page:GraphRAG)
Edge relation: links_to
Confidence: 0.9 (high — explicit author link)
"""

import re
import json
import sys
from pathlib import Path
from collections import defaultdict

REPO = Path(__file__).parent.parent
WIKI_DIR = REPO / "wiki"
MEMORY_DIR = REPO / "memory"

# Regex for [[wikilink]] — supports [[Page Name]] and [[Page Name|alias]]
WIKILINK_RE = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')

def slugify(text):
    """Convert page title to filename stem (Obsidian's default behavior)."""
    # Obsidian replaces spaces with underscores in filenames? Actually it keeps spaces.
    # But wikilinks use the page title. We need to map title → filename.
    # Simplification: use lowercased title with spaces, match against .md stems (with spaces preserved)
    return text.strip()

def load_json(path):
    if path.exists():
        with open(path, 'r') as f:
            return json.load(f)
    return []

def save_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def main():
    print(f"[graph-update] Scanning {WIKI_DIR}...")

    # Load existing graph
    nodes = load_json(MEMORY_DIR / "graph.nodes.json")
    edges = load_json(MEMORY_DIR / "graph.edges.json")

    # Build lookup maps
    nodes_by_id = {n['id']: n for n in nodes}
    edges_by_key = {(e['from'], e['to'], e['relation']): e for e in edges}

    # Track new page nodes
    page_nodes = {}   # id -> node dict
    page_edges = []  # list of new edge dicts

    # Scan wiki files
    md_files = sorted(WIKI_DIR.glob("*.md"))
    print(f"[graph-update] Found {len(md_files)} wiki pages")

    for md_path in md_files:
        stem = md_path.stem  # filename without .md
        page_id = f"page:{stem}"
        title = stem  # could read frontmatter 'title' but stem is canonical

        # Create/update page node
        if page_id not in nodes_by_id:
            page_node = {
                "id": page_id,
                "type": "page",
                "label": title,
                "description": f"Wiki page: {md_path.name}",
                "source_files": [md_path.name],
                "url": ""
            }
            page_nodes[page_id] = page_node
            print(f"[graph-update]  + Node: {page_id}")
        else:
            # Existing node — ensure source_files includes this page
            existing = nodes_by_id[page_id]
            if md_path.name not in existing.get('source_files', []):
                existing['source_files'].append(md_path.name)

        # Extract wikilinks from file content
        try:
            content = md_path.read_text()
        except Exception as e:
            print(f"[graph-update]  ! Cannot read {md_path}: {e}")
            continue

        # Find all wikilinks
        links = WIKILINK_RE.findall(content)
        linked_titles = [slugify(link) for link in links]

        for link_title in linked_titles:
            # Normalize: wikilink title may have underscores or spaces
            # Try direct match first
            target_stem = link_title.replace('_', ' ')
            # Check if target page exists as a file
            target_path = WIKI_DIR / f"{target_stem}.md"
            if not target_path.exists():
                # Try original link_title as filename
                target_path = WIKI_DIR / f"{link_title}.md"
                target_stem = link_title

            if target_path.exists():
                target_id = f"page:{target_stem}"
                edge_key = (page_id, target_id, "links_to")

                # Avoid self-links and duplicates
                if page_id != target_id and edge_key not in edges_by_key:
                    edge = {
                        "from": page_id,
                        "to": target_id,
                        "relation": "links_to",
                        "confidence": 0.9,
                        "source_file": md_path.name
                    }
                    page_edges.append(edge)
                    edges_by_key[edge_key] = edge
                    # print(f"[graph-update]  + Edge: {page_id} → {target_id}")
            else:
                # Broken wikilink (target doesn't exist) — skip for now, lint will catch
                pass

    # Merge new nodes and edges
    nodes_updated = nodes[:]
    for page_id, node in page_nodes.items():
        if page_id not in nodes_by_id:
            nodes_updated.append(node)

    edges_updated = edges[:]
    for edge in page_edges:
        if (edge['from'], edge['to'], edge['relation']) not in edges_by_key:
            edges_updated.append(edge)

    # Save
    save_json(MEMORY_DIR / "graph.nodes.json", nodes_updated)
    save_json(MEMORY_DIR / "graph.edges.json", edges_updated)

    # Stats
    new_nodes = len(page_nodes)
    new_edges = len(page_edges)
    print(f"[graph-update] ✓ Added {new_nodes} page nodes, {new_edges} edges")
    print(f"[graph-update] Total nodes: {len(nodes_updated)}, edges: {len(edges_updated)}")
    print(f"[graph-update] Graph updated successfully")

    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"[graph-update] ERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
