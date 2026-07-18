# MORGELON

Body-horror evidence game for Cocos2D-ObjC, with a playable web prototype.

**Fiction.** Inspired by contested phenomena (threads, ticks, needles, dismissal) — not medical advice.

## Thesis

Threads come out everywhere. Doctors call them crazy and tell them to leave. Trees grow like aspens in the blood. Vaccine?? No one knows. Flooding the zones and lies. The appearance of mischief is evidence enough with power.

## Play (web)

Open `web/index.html` in a browser, or serve the folder:

```bash
cd Morgelon/web && python3 -m http.server 8765
```

Then visit `http://localhost:8765`.

Path: **Clinic → Body (pull threads) → Flooded zones → Aspen / blood**.

## iOS (Cocos2D)

`Classes/` contains scene scaffolding on Cocos2D-ObjC:

| Scene | Role |
| --- | --- |
| `MorgelonTitleScene` | Brand entry |
| `MorgelonClinicScene` | Medical dismissal |
| `MorgelonBodyScene` | Thread extraction / bloom |
| `MorgelonFloodScene` | Quarantine lies / vaccine unknown |
| `MorgelonAspenScene` | Ending — mischief as power |
| `MorgelonState` | Threads, evidence, denial, bloom, power |

Wire `AppDelegate` into an Xcode target that links this repo’s `cocos2d` product (same pattern as `tests/PerformanceTests`).

## Systems

- **Threads** — pull filaments; each pull raises bloom and evidence.
- **Denial** — clinic and flood responses feed the aspen bloom.
- **Power** — evidence × persistence; ascent when mischief is undeniable.
