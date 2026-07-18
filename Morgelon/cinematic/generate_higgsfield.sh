#!/usr/bin/env bash
# Generate Morgelon cinematic stills + clips via Higgsfield AI.
# Requires: higgsfield auth login
#   or: export HF_CREDENTIALS='KEY_ID:KEY_SECRET'
#   or: export HF_KEY='KEY_ID:KEY_SECRET'
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/assets"
STORY="$ROOT/storyboard.json"
MANIFEST="$OUT/manifest.json"

mkdir -p "$OUT/stills" "$OUT/clips"

if ! command -v higgsfield >/dev/null 2>&1; then
  echo "higgsfield CLI not found. Install: curl -fsSL https://raw.githubusercontent.com/higgsfield-ai/cli/main/install.sh | sh" >&2
  exit 1
fi

if ! higgsfield auth token >/dev/null 2>&1; then
  echo "Not authenticated with Higgsfield." >&2
  echo "Run:  higgsfield auth login" >&2
  echo "Or set: export HF_CREDENTIALS='KEY_ID:KEY_SECRET'" >&2
  exit 2
fi

command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }

python3 - <<'PY' "$STORY" "$OUT" "$MANIFEST"
import json, subprocess, sys, time, urllib.request
from pathlib import Path

story_path, out_dir, manifest_path = map(Path, sys.argv[1:4])
story = json.loads(story_path.read_text())
out_stills = out_dir / "stills"
out_clips = out_dir / "clips"
entries = []


def run_json(cmd):
    print("+", " ".join(cmd), flush=True)
    proc = subprocess.run(cmd, check=True, capture_output=True, text=True)
    text = proc.stdout.strip()
    if not text:
        text = proc.stderr.strip()
    # CLI may print progress lines before JSON — take the last JSON object/array.
    for line in reversed(text.splitlines()):
        line = line.strip()
        if line.startswith("{") or line.startswith("["):
            return json.loads(line)
    return json.loads(text)


def first_result_url(payload):
    if payload is None:
        return None
    if isinstance(payload, list):
        for item in payload:
            url = first_result_url(item)
            if url:
                return url
        return None
    if not isinstance(payload, dict):
        return None
    for key in ("result_url", "min_result_url", "url"):
        val = payload.get(key)
        if isinstance(val, str) and val.startswith("http"):
            return val
    results = payload.get("results") or payload.get("output") or payload.get("data")
    url = first_result_url(results)
    if url:
        return url
    for val in payload.values():
        if isinstance(val, (dict, list)):
            url = first_result_url(val)
            if url:
                return url
    return None


def download(url, dest: Path):
    print(f"↓ {url} -> {dest}", flush=True)
    urllib.request.urlretrieve(url, dest)


for shot in story["shots"]:
    sid = shot["id"]
    still = out_stills / f"{sid}.png"
    clip = out_clips / f"{sid}.mp4"

    if not still.exists():
        payload = run_json([
            "higgsfield", "generate", "create", "cinematic_studio_2_5",
            "--prompt", shot["image_prompt"],
            "--aspect_ratio", "16:9",
            "--resolution", "2k",
            "--wait",
            "--json",
        ])
        url = first_result_url(payload)
        if not url:
            raise SystemExit(f"No still URL for {sid}: {payload}")
        download(url, still)

    if not clip.exists():
        duration = min(15, max(5, int(shot.get("duration_sec", 8))))
        payload = run_json([
            "higgsfield", "generate", "create", "cinematic_studio_video_3_5",
            "--prompt", shot["video_prompt"],
            "--start-image", str(still),
            "--aspect_ratio", "16:9",
            "--duration", str(duration),
            "--genre", "horror",
            "--camera_style", shot.get("camera_style", "intimate_observer"),
            "--light_scheme", shot.get("light_scheme", "practicals"),
            "--color_grading", shot.get("color_grading", "cold_steel"),
            "--prompt_language", "en",
            "--generate_audio", "false",
            "--resolution", "720p",
            "--wait",
            "--json",
        ])
        url = first_result_url(payload)
        if not url:
            raise SystemExit(f"No clip URL for {sid}: {payload}")
        download(url, clip)

    entries.append({
        "id": sid,
        "slug": shot["slug"],
        "still": f"stills/{sid}.png",
        "clip": f"clips/{sid}.mp4" if clip.exists() else None,
        "duration_sec": shot.get("duration_sec", 8),
        "narration": shot["narration"],
        "on_screen": shot["on_screen"],
        "support": shot["support"],
    })

manifest_path.write_text(json.dumps({
    "title": story["title"],
    "logline": story["logline"],
    "disclaimer": story["disclaimer"],
    "source": "higgsfield",
    "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "shots": entries,
}, indent=2) + "\n")
print(f"Wrote {manifest_path}")
PY

echo "Done. Assets in $OUT"
