# F36#0 naturalistic creatures on main: GPU pass (24 Oct 2026)

**Verdict:**
- **CONFIRMED (â‰¥7.5): Terrapup 7.64** (shipping at 3.20 m) **and Burrowback 7.61.**
- **REOPENED: the other twelve.** Five are within 0.6 of the bar: Mosshell water form 7.41, Mosshell 7.36, Ripplet 7.26, Nightburrow 7.01, Bramblebun 6.95.

Medium and High scored identically for every species, from every judge.

## Run

- **Source:** main 7b5d351da (after the Creatures landing).
- **Capture:** `tools/art_pipeline/capture_f36_poses.gd --species=ripplet,cindercub,terrapup,bramblebun,mudsnout,trailpup,paddlenewt,burrowback,veridian,mosshell,water_mosshell,nightburrow,stormtrail,riftfrill --whole-body --context`, with no `--candidate` (shipping poses).
  - Medium and High, Forward+ on a GTX 1060, 1920x1080.
  - 305 frames per preset, all present.
  - Queue: `f36_0_main_queue.ps1.txt`.
- **Sides:** each species is one set, Medium on one side and High on the other (sides shuffled). Five frames per side:
  - standing, hit react, faint mid and faint end;
  - the travel role: ridden, swimming or carrying, whichever the species has.
  - Builder: `build_yard_f36main.ps1.txt`.

## Yardstick

- **Batches:** two batches of seven species. Each was built with `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`, so every batch has its own anchors.
- **Judges:** three fresh code-blind judges per batch, each given `JUDGE_PROMPT.md` (main, owner creature style bar) verbatim. No recorded defects.

| Batch | Slope | Intercept | r | Anchor RMSE | Confirming | Warnings |
|---|---|---|---|---|---|---|
| b1 | 1.148 | âˆ’0.127 | 0.93 | 0.50 | yes | Terrapup maps above the top anchor (7.53): extrapolated, allowed in a confirming batch |
| b2 | 0.856 | 2.019 | 0.88 | 0.52 | yes | Burrowback likewise |

| Species | Batch | Raw (j1/j2/j3) | Mapped per judge | **Mapped mean** | CPU (close-1024) |
|---|---|---|---|---|---|
| **terrapup** (3.20 m) | b1 | 6.3 / 7.0 / 7.0 | 7.11 / 7.91 / 7.91 | **7.64** | 7.62 at 3.85 m |
| **burrowback** | b2 | 6.8 / 6.2 / 6.6 | 7.84 / 7.33 / 7.67 | **7.61** | 7.23 |
| water_mosshell | b2 | 6.6 / 6.3 / 6.0 | 7.67 / 7.41 / 7.16 | 7.41 | 7.19 |
| mosshell | b2 | 6.5 / 6.3 / 5.9 | 7.58 / 7.41 / 7.07 | 7.36 | 7.31 |
| ripplet | b1 | 6.2 / 6.5 / 6.6 | 6.99 / 7.34 / 7.45 | 7.26 | â€“ |
| nightburrow (remake mesh) | b2 | 6.0 / 5.9 / 5.6 | 7.16 / 7.07 / 6.81 | 7.01 | unjudged |
| bramblebun | b1 | 5.8 / 6.0 / 6.7 | 6.53 / 6.76 / 7.57 | 6.95 | 7.57 |
| paddlenewt | b1 | 5.9 / 5.8 / 6.0 | 6.65 / 6.53 / 6.76 | 6.65 | 6.88 |
| veridian | b2 | 5.3 / 5.25 / 5.2 | 6.56 / 6.5 / 6.47 | 6.52 | 6.82 |
| stormtrail (remake mesh) | b2 | 5.0 / 5.0 / 4.5 | 6.30 / 6.30 / 5.87 | 6.16 | unjudged |
| cindercub | b1 | 5.2 / 5.3 / 5.8 | 5.84 / 5.96 / 6.53 | 6.11 | â€“ |
| riftfrill (remake mesh) | b2 | 4.9 / 4.6 / 4.6 | 6.21 / 5.96 / 5.96 | 6.04 | unjudged |
| mudsnout | b1 | 4.9 / 4.8 / 6.0 | 5.50 / 5.39 / 6.76 | 5.88 | 7.40 |
| trailpup | b1 | 4.8 / 5.0 / 5.5 | 5.39 / 5.62 / 6.19 | 5.73 | 7.49 |

The raw scores are listed per judge as j1/j2/j3 of that batch. j2's veridian is the mean of its Medium and High scores (5.2/5.3).

## What the judges saw (every judge unless noted)

1. **Swimming frames:**
   - What: every swimmer stands or hovers in its walk pose on top of a flat blue water slab, with a hard white gradient edge on the right. It reads as walking on water.
   - Where: bramblebun, paddlenewt, trailpup, cindercub, mudsnout, mosshell, nightburrow, riftfrill and stormtrail.
   - Cause: the `--context` swim stage of the capture tool (a flat plane). The water forms judged separately (water_mosshell ridden) read fine.
2. **Scale against the 1.80 m ruler:** trailpup (head at shoulder), paddlenewt, riftfrill, mudsnout and cindercub stand at or below the trainer, which breaks the rule that every creature stands taller.
3. **Identity and value:**
   - trailpup and mudsnout read as generic stock animals with no Tetherbound marking;
   - cindercub and stormtrail are near-black on the dark stage, so the face and eyes are lost;
   - riftfrill is a glossy, plastic violet off the creature board;
   - veridian's bone-white bands read as a skeleton.
4. **Faint poses:**
   - veridian's neck stays vertical through faint mid;
   - Mosshell's faint barely differs from standing;
   - nightburrow has a stray vertical line above its back in faint mid and faint end;
   - stormtrail has floating specks above it when it faints.
5. **Strongest:**
   - Terrapup: badger with a mossy shell, rideable, with a clear face stripe.
   - Burrowback: naturalistic fur with integrated rock-moss plates, "Stormursa-level".
   - Mosshell and its water form.

## Files

- `_sheet_f36_0_gpu_main.png`: all fourteen standing at Medium with their mapped scores (41 KB).
- `yardstick/b1`, `yardstick/b2`:
  - `key.json`, `sets.md`, `candidates.json`, `recorded_defects.txt`, `judge_prompt_filled.txt`;
  - `j1.json`â€“`j3.json`: per-set scores with the judges' notes condensed;
  - `batch.json`, `mapped.json`.
- Per-frame captures stay local.
