# MORGELON

Horror story + video-game cinematic about threads, clinic denial, flooded zones, and aspens in the blood.

**Fiction.** Not medical advice.

## Watch the cinematic

```bash
cd Morgelon/web && python3 -m http.server 8765
```

Open `http://localhost:8765` → **Play cinematic**.

Interactive evidence path: `http://localhost:8765/game.html`

## Higgsfield AI assets

Stills currently in `cinematic/assets/stills/` are interim key art so the film can run now.

To regenerate **Cinema Studio** stills + horror clips with [Higgsfield](https://higgsfield.ai):

```bash
# once
curl -fsSL https://raw.githubusercontent.com/higgsfield-ai/cli/main/install.sh | sh
higgsfield auth login

# generate 8 stills (cinematic_studio_2_5) + 8 clips (cinematic_studio_video_3_5, genre=horror)
cd Morgelon/cinematic
./generate_higgsfield.sh
```

Storyboard + prompts: `cinematic/storyboard.json`  
Pipeline writes: `cinematic/assets/{stills,clips}/` and refreshes `manifest.json`  
The web player reads that manifest and prefers `clip` over Ken Burns stills.

### Shot list

| ID | Beat |
| --- | --- |
| 01_title | Brand / venous aspen forest |
| 02_clinic | Doctors tell them to leave |
| 03_thread | Filaments |
| 04_mischief | Ticks, needles, genetic mischief |
| 05_flood | Flooding the zones and lies |
| 06_vaccine | Vaccine?? No one knows |
| 07_aspen | Trees in the blood |
| 08_power | Appearance of mischief is evidence enough with power |

## Cocos2D scenes

`Classes/` — ObjC scene scaffolding (Title → Clinic → Body → Flood → Aspen) for an iOS target on this engine.
