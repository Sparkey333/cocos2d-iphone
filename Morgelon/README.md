# MORGELON

Colorado mountain horror — **three concepts** mainstream horror usually blocks or exhausts:

1. **The Single Tree** — clonal aspens graft hikers (not mushroom zombies)  
2. **High Consensus** — altitude creates agreement, not delirium  
3. **Leaf-Peeping Eschaton** — tourist / DJI beauty completes the harvest (not haunted VHS)  

Details: [`CONCEPTS.md`](CONCEPTS.md) · body engine: [`EXTRACTION.md`](EXTRACTION.md) · systems: [`DESIGN.md`](DESIGN.md)

Fiction. Obey park & drone law. **Prosthetics only** — never dig at real sores for footage.

## Google Photos + Drive bridge

Auto-import inspiration media (Drive folder sync, Photos Picker, inbox/Takeout, optional rclone):

See [`bridge/README.md`](bridge/README.md).

```bash
cd Morgelon/bridge
cp .env.example .env   # add client_secret.json + Drive folder id
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python -m morgelon_bridge auth
python -m morgelon_bridge sync      # Drive + inbox
python -m morgelon_bridge photos    # pick from Google Photos
python -m morgelon_bridge daemon    # keep polling
```

Gallery: `web/inspiration.html` after imports.

## Download (DMG)

Build locally:

```bash
# needs genisoimage + libdmg-hfsplus `dmg` binary (see packaging/build_dmg.sh)
./Morgelon/packaging/build_dmg.sh ./Morgelon/dist
open ./Morgelon/dist/Morgelon.dmg
```

Cloud artifact: `Morgelon.dmg` (macOS) — double-click **Open Morgelon.command** inside.

Premium design: [`PREMIUM.md`](PREMIUM.md)

## Web

```bash
cd Morgelon/web && python3 -m http.server 8765
```

| URL | What |
| --- | --- |
| `/` | Cinematic |
| `/concepts.html` | The three engines |
| `/direct.html` | Colorado one-day DJI order |
| `/game.html` | Evidence path (hold-to-extract) |

## Shoot (Colorado)

Full call sheet: [`cinematic/DIRECTOR_BRIEF.md`](cinematic/DIRECTOR_BRIEF.md)

```text
Morgelon/cinematic/assets/plates/DJI/MORG_CO_A01.mp4
```

One-day order: drone canopy → lot ritual → unison overlook turn → graft macro → valley airlock.

## Higgsfield

Cloud agent cannot finish OAuth for you. On your Mac:

```bash
higgsfield auth login
cd Morgelon/cinematic && ./generate_higgsfield.sh
./packaging/build_dmg.sh ./dist   # rebuild DMG with Cinema Studio clips
```

Notes: [`cinematic/HIGGSFIELD_STATUS.md`](cinematic/HIGGSFIELD_STATUS.md) · storyboard: `cinematic/storyboard.json`
