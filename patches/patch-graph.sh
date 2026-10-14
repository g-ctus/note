#!/usr/bin/env bash
# ============================================================
# patch-graph.sh — Fix Japanese URL encoding + add dangling node support
#
# Patches the COMPILED graph plugin dist after `npx quartz plugin install`.
# The graph code is pre-bundled as a string literal in dist/components/index.js,
# so we must patch dist/ (not src/) for the changes to take effect.
#
# Must run BEFORE `npx quartz build`.
# Idempotent: safe to run on already-patched files (skips applied patches).
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
let alreadyCount = 0;

// === Patch 1: Decode URI in getSlugFromUrl ===
const oldSlugFn = 'function u(){var a=we()';
const newSlugFn = 'function u(){var a=decodeURIComponent(we())';
if (code.includes(newSlugFn)) {
    alreadyCount++;
    console.log('  [1/6] URL decoding: already applied');
} else if (code.includes(oldSlugFn)) {
    code = code.replace(oldSlugFn, newSlugFn);
    patchCount++;
    console.log('  [1/6] URL decoding: patched');
} else {
    console.log('  [1/6] URL decoding: pattern not found, SKIPPED');
}

// === Patch 2: Also collect dangling links ===
const oldLinkCheck = 'Xu.has(v)&&tu.push({source:l,target:v})';
const newLinkCheck = 'if(Xu.has(v)){tu.push({source:l,target:v})}else{_danglingNodes.add(v);tu.push({source:l,target:v})}';
if (code.includes(newLinkCheck)) {
    alreadyCount++;
    console.log('  [2/6] Dangling link collection: already applied');
} else if (code.includes(oldLinkCheck)) {
    code = code.replace(oldLinkCheck, newLinkCheck);
    patchCount++;
    console.log('  [2/6] Dangling link collection: patched');
} else {
    console.log('  [2/6] Dangling link collection: pattern not found, SKIPPED');
}

// === Patch 3: Insert danglingNodes set initialization ===
const oldValidLinks = 'Xu=new Set(eu.keys());';
const newValidLinks = 'Xu=new Set(eu.keys());var _danglingNodes=new Set();';
if (code.includes(newValidLinks)) {
    alreadyCount++;
    console.log('  [3/6] DanglingNodes init: already applied');
} else if (code.includes(oldValidLinks)) {
    code = code.replace(oldValidLinks, newValidLinks);
    patchCount++;
    console.log('  [3/6] DanglingNodes init: patched');
} else {
    console.log('  [3/6] DanglingNodes init: pattern not found, SKIPPED');
}

// === Patch 4: Color dangling nodes lightgray ===
const oldColorFn = 'function \$e(i){var l=i.id===m;return l?Ie:';
const newColorFn = 'function \$e(i){if(i.dangling)return te;var l=i.id===m;return l?Ie:';
if (code.includes(newColorFn)) {
    alreadyCount++;
    console.log('  [4/6] Dangling node color: already applied');
} else if (code.includes(oldColorFn)) {
    code = code.replace(oldColorFn, newColorFn);
    patchCount++;
    console.log('  [4/6] Dangling node color: patched');
} else {
    console.log('  [4/6] Dangling node color: pattern not found, SKIPPED');
}

// === Patch 5: Better display name for nodes ===
const oldNodeText = 'eu.get(i)?.title||i';
const newNodeText = 'eu.get(i)?.title||decodeURIComponent(i).replace(/-/g,\" \")';
if (code.includes(newNodeText)) {
    alreadyCount++;
    console.log('  [5/6] Node display name: already applied');
} else if (code.includes(oldNodeText)) {
    code = code.replace(oldNodeText, newNodeText);
    patchCount++;
    console.log('  [5/6] Node display name: patched');
} else {
    console.log('  [5/6] Node display name: pattern not found, SKIPPED');
}

// === Patch 6: Add dangling property to node object ===
const oldNodeObj = 'v={id:i,text:F,tags:A,';
const newNodeObj = 'v={id:i,text:F,dangling:_danglingNodes.has(i),tags:A,';
if (code.includes(newNodeObj)) {
    alreadyCount++;
    console.log('  [6/6] Node dangling flag: already applied');
} else if (code.includes(oldNodeObj)) {
    code = code.replace(oldNodeObj, newNodeObj);
    patchCount++;
    console.log('  [6/6] Node dangling flag: patched');
} else {
    console.log('  [6/6] Node dangling flag: pattern not found, SKIPPED');
}

fs.writeFileSync('$DIST_FILE', code);
const total = patchCount + alreadyCount;
console.log('');
console.log('Patches: ' + patchCount + ' applied, ' + alreadyCount + ' already present, ' + (6 - total) + ' skipped');
if (total < 4) {
    console.error('ERROR: Too few patches matched (' + total + '/6). Graph plugin may have been updated.');
    process.exit(1);
}
"

echo "Graph plugin dist patched successfully."
