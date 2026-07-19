# MORGELON

Colorado mountain horror — **three concepts** mainstream horror usually blocks or exhausts:

1. **The Single Tree** — clonal aspens graft hikers (not mushroom zombies)  
2. **High Consensus** — altitude creates agreement, not delirium  
3. **Leaf-Peeping Eschaton** — tourist / DJI beauty completes the harvest (not haunted VHS)  

Details: [`CONCEPTS.md`](CONCEPTS.md) · body engine: [`EXTRACTION.md`](EXTRACTION.md) · systems: [`DESIGN.md`](DESIGN.md)

Fiction. Obey park & drone law. **Prosthetics only** — never dig at real sores for footage.

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

```bash
higgsfield auth login
cd Morgelon/cinematic && ./generate_higgsfield.sh
```

Storyboard retuned to Colorado + the three concepts: `cinematic/storyboard.json`.
