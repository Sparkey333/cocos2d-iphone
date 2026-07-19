#!/usr/bin/env bash
# Build a macOS-openable Morgelon.dmg from the web slice + design docs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="${TMPDIR:-/tmp}/morgelon-dmg-stage"
OUT_DIR="${1:-$ROOT/dist}"
ISO="$OUT_DIR/Morgelon.iso"
DMG="$OUT_DIR/Morgelon.dmg"
DMG_BIN="${DMG_BIN:-/tmp/libdmg-hfsplus/build/dmg/dmg}"

mkdir -p "$OUT_DIR"
rm -rf "$STAGE"
mkdir -p "$STAGE/Morgelon"

# Web playable slice (copy real files; resolve asset symlinks)
mkdir -p "$STAGE/Morgelon/Play"
cp -a "$ROOT/web/." "$STAGE/Morgelon/Play/"
rm -rf "$STAGE/Morgelon/Play/assets/stills" "$STAGE/Morgelon/Play/assets/manifest.json"
mkdir -p "$STAGE/Morgelon/Play/assets/stills"
cp -a "$ROOT/cinematic/assets/stills/." "$STAGE/Morgelon/Play/assets/stills/"
cp -a "$ROOT/cinematic/assets/manifest.json" "$STAGE/Morgelon/Play/assets/manifest.json"

# Design / director docs
mkdir -p "$STAGE/Morgelon/Docs"
cp "$ROOT/README.md" "$ROOT/CONCEPTS.md" "$ROOT/DESIGN.md" "$ROOT/EXTRACTION.md" "$ROOT/PREMIUM.md" \
  "$ROOT/cinematic/DIRECTOR_BRIEF.md" "$ROOT/cinematic/storyboard.json" \
  "$ROOT/cinematic/HIGGSFIELD_STATUS.md" \
  "$STAGE/Morgelon/Docs/" 2>/dev/null || true

# macOS double-click helper
cat > "$STAGE/Morgelon/Open Morgelon.command" <<'EOS'
#!/bin/bash
cd "$(dirname "$0")/Play" || exit 1
PORT=8765
if command -v python3 >/dev/null 2>&1; then
  open "http://127.0.0.1:${PORT}/" 2>/dev/null || true
  exec python3 -m http.server "$PORT"
elif command -v python >/dev/null 2>&1; then
  open "http://127.0.0.1:${PORT}/" 2>/dev/null || true
  exec python -m SimpleHTTPServer "$PORT"
else
  open "Play/index.html" 2>/dev/null || open "index.html"
fi
EOS
chmod +x "$STAGE/Morgelon/Open Morgelon.command"

cat > "$STAGE/Morgelon/READ ME FIRST.txt" <<'EOS'
MORGELON — Premium horror game / cinematic slice
================================================
Fiction. Not medical advice. Prosthetics only for any real-world filming.

1. Double-click "Open Morgelon.command" (macOS) to serve + open the game
   OR open Play/index.html in a browser (some features need a local server).

2. Docs/ — concepts, premium design, Colorado DJI director brief, extraction bible

3. Higgsfield assets: run cinematic/generate_higgsfield.sh after
   `higgsfield auth login` on a machine with the CLI.

Colorado · Single Tree · High Consensus · Leaf-Peeping · Satisfying disgust
EOS

# ISO then UDIF DMG
rm -f "$ISO" "$DMG"
genisoimage -V "Morgelon" -D -R -apple -no-pad -o "$ISO" "$STAGE/Morgelon" 2>/dev/null \
  || genisoimage -V "Morgelon" -R -o "$ISO" "$STAGE/Morgelon"

if [[ ! -x "$DMG_BIN" ]]; then
  echo "dmg binary missing at $DMG_BIN — leaving ISO only" >&2
  ls -lh "$ISO"
  exit 0
fi

"$DMG_BIN" "$ISO" "$DMG"
rm -f "$ISO"
ls -lh "$DMG"
echo "Wrote $DMG"
