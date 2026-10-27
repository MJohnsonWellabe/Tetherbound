# Meshy batch 1 (Creatures lane, 23 Oct 2026): naturalistic remakes for F36#0

Purpose: bring starters and most-seen main-path creatures to the owner's style bar (Galecrest, Tanglevolt, Stormcapra, Stormursa;
`docs/reference/owner-creature-style-bar.png`), keeping identity. Same two-step route as the Meadowhart nat-v1 pilot
(`assets/creatures/tetherbound/meadowhart/candidate_nat1022/source/meshy_provenance.jsonl`):
1. concept: `/openapi/v1/image-to-image` (nano-banana-pro), refs = the identity reference below + the pilot's `style_wolf.png` and `style_bear.png`, prompt = the `.prompt.txt` file;
2. 3D: multi-image-to-3D from the chosen concept, textured, then I rig it here (measured quadruped rig, `rig_bird` for Pipwing) and author its clips.

Scale check: every target height is the installed `placeholder.height`, all above the 1.80 m trainer; no creature shrinks.
Staticub is drafted as a juvenile so that it reads clearly younger than adult Stormursa (5.00 m), the F29#3 cub/adult ask.
Starters Terrapup, Ripplet and Galewisp already have nat-v1 concepts and GLBs (`assets_raw/naturalistic/`, archive), so they are not in this batch.
Every result stays flag-off until it passes a judged round.

| Species | Target height | Identity reference | Prompt |
|---|---|---|---|
| mudsnout | 2.00 m (trainer 1.80, ratio 1.11) | `assets/creatures/tetherbound/mudsnout/reference/native-standing-v1.png` | `ralph/reports/CREATURES/close-1024/meshy-batch1/mudsnout.prompt.txt` |
| trailpup | 2.30 m (trainer 1.80, ratio 1.28) | `assets/creatures/tetherbound/trailpup/reference/three_quarter.png` | `ralph/reports/CREATURES/close-1024/meshy-batch1/trailpup.prompt.txt` |
| sparkit | 1.95 m (trainer 1.80, ratio 1.08) | `assets/creatures/tetherbound/sparkit/reference/side.png` | `ralph/reports/CREATURES/close-1024/meshy-batch1/sparkit.prompt.txt` |
| staticub | 3.25 m (trainer 1.80, ratio 1.81) | `assets/creatures/tetherbound/staticub/reference/native-standing-v1.png` | `ralph/reports/CREATURES/close-1024/meshy-batch1/staticub.prompt.txt` |
| burrowback | 2.95 m (trainer 1.80, ratio 1.64) | `assets/creatures/tetherbound/burrowback/reference/native-standing-v1.png` | `ralph/reports/CREATURES/close-1024/meshy-batch1/burrowback.prompt.txt` |
| mosshell | 2.50 m (trainer 1.80, ratio 1.39) | `assets/creatures/tetherbound/mosshell/reference/three_quarter.png` | `ralph/reports/CREATURES/close-1024/meshy-batch1/mosshell.prompt.txt` |
| paddlenewt | 2.15 m (trainer 1.80, ratio 1.19) | `assets/creatures/tetherbound/paddlenewt/reference/three_quarter.png` | `ralph/reports/CREATURES/close-1024/meshy-batch1/paddlenewt.prompt.txt` |
| pipwing | 1.90 m (trainer 1.80, ratio 1.06) | `assets/creatures/tetherbound/pipwing/reference/three_quarter.png` | `ralph/reports/CREATURES/close-1024/meshy-batch1/pipwing.prompt.txt` |
| veridian | 5.80 m (trainer 1.80, ratio 3.22) | `assets/creatures/tetherbound/veridian/reference/native-standing-v1.png` | `ralph/reports/CREATURES/close-1024/meshy-batch1/veridian.prompt.txt` |
| mirejaw | 2.80 m (trainer 1.80, ratio 1.56) | `assets/creatures/tetherbound/mirejaw/reference/native-standing-v1.png` | `ralph/reports/CREATURES/close-1024/meshy-batch1/mirejaw.prompt.txt` |
