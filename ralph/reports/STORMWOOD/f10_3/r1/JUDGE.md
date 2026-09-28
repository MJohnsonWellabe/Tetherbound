# F10#3 round 1: code-blind judge on the integrated lightning shape (PARTIAL)

## What was judged
- **Code:** `tb/stormwood` 2c8a3660, which is main plus Codex's judged lightning shape (20f86ab4), ported file by file.
- **Captures:** local xvfb + opengl3 at 1280×720 with `--fixed-fps 60`, on Mesa llvmpipe software GL.
  - `tools/vis_capture_strike_motion.gd --only=quick --vis-child`:
    - seqX: hour 12, normal motion;
    - seqY: hour 0, normal motion;
    - seqZ: hour 0, reduced motion.
    - 19 frames each; the judge saw 9 per sequence, in `strikes/`.
  - `tools/capture_stormwood_surge_phases.gd --only=quick,night`: 8 phase stills, shuffled and renamed in `phases/`. `phases_blind_key.json` maps them back.
- **Staging, disclosed:** one staged warning and impact through the lightning node's client path, aimed at the trainer, with no damage. Random strikes are pushed out, the surge clock is pinned, the hour is frozen, the trainer is teleported to the Cinder Verge stand, and the HUD is hidden.

## Verdict (subagent; pixels only)

| Q | Result | Judge |
|---|---|---|
| Q1 zone of about 3 m | PARTIAL | The radius measures about 3–3.5 m. At t000 it is "a thin, segmented magenta outline … more like a selection or target circle". The gold road cracks pulse inside it. |
| Q2 time left | **FAIL** | "t080 against t110 is barely different … nothing makes the last moment unmistakable". |
| Q3 impact | PARTIAL | A jagged branching bolt lands at the player's feet and reads as lightning. A high side fork appears to land near the tower rock. The bolt is identical across sequences. |
| Q4 reduced motion | **PASS** | There is no white-out or strobe, and the warning and impact stay readable. |
| Q5 night = noon | **PASS** | The sequences are near pixel-identical, which is the owner's pinned storm. |
| Q6 phases without HUD | PARTIAL | All eight stills were grouped correctly into Calm, Building, Break and Fading (the key confirms it). "Building against Fading is separable": Fading shows the bright cloud break. Break against Building is the weak pair, and Break stills show no lightning. |

**Overall: PARTIAL.** Ranked fixes:
1. A readable countdown and an unmistakable final moment.
2. The road cracks compete with the warning.
3. The zone looks off-centre. The ring is centred on the trainer's feet; the close camera behind the trainer compresses its far half.
4. A stray high fork.
5. The empty outline at t000.
6. Break has no signature at rest.
7. The bolt is identical from strike to strike.

**Round 2 response** (73173db1): items 1, 2 and 5. Item 3 is perspective, not placement. Items 4 and 7 belong to Codex's judged bolt art, and item 6 is left as it is.
