#!/usr/bin/env bash
# ============================================================
# patch-graph.sh — Fix Japanese URL encoding + add dangling node support
#
# Patches the graph plugin after `npx quartz plugin install`.
# Must run BEFORE `npx quartz build`.
# ============================================================
set -eo pipefail

GRAPH_FILE=".quartz/plugins/graph/src/components/scripts/graph.inline.ts"

if [[ ! -f "$GRAPH_FILE" ]]; then
    echo "WARN: Graph plugin file not found at $GRAPH_FILE, skipping patch"
    exit 0
fi

echo "Patching graph plugin for Japanese URL support and dangling nodes..."

# Use node.js for reliable patching of complex JavaScript
node -e "
const fs = require('fs');
let code = fs.readFileSync('$GRAPH_FILE', 'utf8');

// --- Patch 1: Decode URI in getSlugFromUrl ---
// Fix: window.location.pathname returns percent-encoded Japanese text
code = code.replace(
  'var slug = getFullSlugFromUrl();',
  'var slug = decodeURIComponent(getFullSlugFromUrl());'
);

// --- Patch 2: Add dangling link nodes (gray nodes for non-existent links) ---
// Insert dangling-link collection code before the neighbourhood construction
const danglingCode = \`
      // --- Dangling links: collect link targets not in contentIndex ---
      var danglingNodes = new Set();
      data.forEach(function (details, source) {
        var outgoing = details.links || [];
        for (var i = 0; i < outgoing.length; i++) {
          var dest = simplifySlug(outgoing[i]);
          if (!validLinks.has(dest)) {
            danglingNodes.add(dest);
            links.push({ source: source, target: dest });
          }
        }
      });

\`;
code = code.replace(
  'var neighbourhood = new Set();',
  danglingCode + '      var neighbourhood = new Set();'
);

// --- Patch 3: Color dangling nodes lightgray ---
code = code.replace(
  'function nodeColor(d) {',
  'function nodeColor(d) {\\n        if (d.dangling) { return lightgray; }'
);

// --- Patch 4: Mark dangling nodes + better display name ---
code = code.replace(
  'var text = isTag ? \"#\" + url.substring(5) : data.get(url)?.title || url;',
  'var text = isTag ? \"#\" + url.substring(5) : data.get(url)?.title || decodeURIComponent(url).replace(/-/g, \" \");'
);

code = code.replace(
  /var node = \{(\s+)id: url,(\s+)text: text,/,
  'var isDangling = danglingNodes.has(url);\\n        var node = {\$1id: url,\$2text: text,\\n          dangling: isDangling,'
);

fs.writeFileSync('$GRAPH_FILE', code);
console.log('Patches applied successfully.');
"

echo "Graph plugin patched:"
echo "  - URL decoding for Japanese filenames"
echo "  - Dangling link nodes shown as gray dots"
