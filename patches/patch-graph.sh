#!/usr/bin/env bash
# ============================================================
# patch-graph.sh — Fix Japanese URL encoding + add dangling node support
#
# Patches the COMPILED graph plugin dist after `npx quartz plugin install`.
# The graph code is pre-bundled as a string literal in dist/components/index.js,
# so we must patch dist/ (not src/) for the changes to take effect.
#
# Must run BEFORE `npx quartz build`.
# ============================================================
set -eo pipefail

DIST_FILE=".quartz/plugins/graph/dist/components/index.js"

if [[ ! -f "$DIST_FILE" ]]; then
    echo "WARN: Graph plugin dist file not found at $DIST_FILE, skipping patch"
    exit 0
fi

echo "Patching graph plugin dist for Japanese URL support and dangling nodes..."

node -e "
const fs = require('fs');
let code = fs.readFileSync('$DIST_FILE', 'utf8');
let patchCount = 0;

// === Patch 1: Decode URI in getSlugFromUrl ===
// The minified getSlugFromUrl function:
//   function u(){var a=we(), ...}
// we() returns window.location.pathname (percent-encoded for Japanese)
// Fix: wrap with decodeURIComponent
const oldSlugFn = 'function u(){var a=we()';
const newSlugFn = 'function u(){var a=decodeURIComponent(we())';
if (code.includes(oldSlugFn)) {
    code = code.replace(oldSlugFn, newSlugFn);
    patchCount++;
    console.log('  [1/5] URL decoding: patched');
} else {
    console.log('  [1/5] URL decoding: pattern not found, SKIPPED');
}

// === Patch 2: Also collect dangling links ===
// Original: Xu.has(v)&&tu.push({source:l,target:v})
// This only adds links to valid (existing) targets.
// We also need to track dangling targets.
// We initialize danglingNodes set before the forEach, and add non-valid targets.
const oldLinkCheck = 'Xu.has(v)&&tu.push({source:l,target:v})';
const newLinkCheck = 'if(Xu.has(v)){tu.push({source:l,target:v})}else{_danglingNodes.add(v);tu.push({source:l,target:v})}';
if (code.includes(oldLinkCheck)) {
    code = code.replace(oldLinkCheck, newLinkCheck);
    patchCount++;
    console.log('  [2/5] Dangling link collection: patched');
} else {
    console.log('  [2/5] Dangling link collection: pattern not found, SKIPPED');
}

// Insert danglingNodes set initialization after Xu
// In minified code it's: ,Xu=new Set(eu.keys());
const oldValidLinks = 'Xu=new Set(eu.keys());';
const newValidLinks = 'Xu=new Set(eu.keys());var _danglingNodes=new Set();';
if (code.includes(oldValidLinks)) {
    code = code.replace(oldValidLinks, newValidLinks);
    patchCount++;
    console.log('  [3/5] DanglingNodes init: patched');
} else {
    console.log('  [3/5] DanglingNodes init: pattern not found, SKIPPED');
}

// === Patch 3: Color dangling nodes lightgray ===
// Original: function \$e(i){var l=i.id===m;return l?Ie:q.has(i.id)||i.id.startsWith(\"tags/\")?ue:ee}
// Add: if(i.dangling) return te;  (te = lightgray)
const oldColorFn = 'function \$e(i){var l=i.id===m;return l?Ie:';
const newColorFn = 'function \$e(i){if(i.dangling)return te;var l=i.id===m;return l?Ie:';
if (code.includes(oldColorFn)) {
    code = code.replace(oldColorFn, newColorFn);
    patchCount++;
    console.log('  [4/5] Dangling node color: patched');
} else {
    console.log('  [4/5] Dangling node color: pattern not found, SKIPPED');
}

// === Patch 4: Better display name for nodes + mark dangling ===
// Original node text: eu.get(i)?.title||i
// New: eu.get(i)?.title||decodeURIComponent(i).replace(/-/g,\" \")
// Also add dangling flag to node
const oldNodeText = 'eu.get(i)?.title||i';
const newNodeText = 'eu.get(i)?.title||decodeURIComponent(i).replace(/-/g,\" \")';
if (code.includes(oldNodeText)) {
    code = code.replace(oldNodeText, newNodeText);
    patchCount++;
    console.log('  [5/5] Node display name: patched');
} else {
    console.log('  [5/5] Node display name: pattern not found, SKIPPED');
}

// === Patch 5: Add dangling property to node object ===
// Minified: v={id:i,text:F,tags:A,
const oldNodeObj = 'v={id:i,text:F,tags:A,';
const newNodeObj = 'v={id:i,text:F,dangling:_danglingNodes.has(i),tags:A,';
if (code.includes(oldNodeObj)) {
    code = code.replace(oldNodeObj, newNodeObj);
    patchCount++;
    console.log('  [6/6] Node dangling flag: patched');
} else {
    console.log('  [6/6] Node dangling flag: pattern not found, SKIPPED');
}

fs.writeFileSync('$DIST_FILE', code);
console.log('');
console.log('Total patches applied: ' + patchCount + '/6');
if (patchCount < 4) {
    console.error('ERROR: Too few patches applied. Graph plugin may have been updated.');
    process.exit(1);
}
"

echo "Graph plugin dist patched successfully."
