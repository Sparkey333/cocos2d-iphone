# MORGELON

Horror game / cinematic: **Resident Evil** facility structure × **fungal group mind** × **The Fly** practical body-horror production value.

**Fiction.** Not medical advice. No real injury — prosthetics, gel, fishing line.

## Pillars

See [`DESIGN.md`](DESIGN.md).

1. RE loop — keys, safe rooms, scarce resources, Joined encounters  
2. Chorus — mycelial hivemind; filaments carry memory  
3. The Fly look — wet macros, tragic transformation, lab-as-confession  

## Watch / play (web prototype)

```bash
cd Morgelon/web && python3 -m http.server 8765
```

| URL | What |
| --- | --- |
| `/` | Cinematic player |
| `/game.html` | Interactive evidence path |
| `/direct.html` | Pocket DJI director’s slate |

## You have DJI cameras — I’ll direct

Full call sheet: [`cinematic/DIRECTOR_BRIEF.md`](cinematic/DIRECTOR_BRIEF.md)

Drop plates:

```text
Morgelon/cinematic/assets/plates/DJI/MORG_D1_A01.mp4
```

Then cut into `cinematic/assets/clips/` (shot ids `01_title` … `08_power`) or use as Higgsfield `--video-references`.

## Higgsfield AI

```bash
higgsfield auth login
cd Morgelon/cinematic && ./generate_higgsfield.sh
```

Storyboard prompts already biased to The Fly + RE + Chorus: `cinematic/storyboard.json`.

## Cocos2D

`Classes/` — ObjC scene scaffolding for an iOS target on this engine.
