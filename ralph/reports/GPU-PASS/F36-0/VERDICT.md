# GPU pass: F36#0 creature ledger, 16 ON rows: round 1 all REOPENED (best Ripplet 6.93)

22 Oct 2026, ~01:00 CT. Remote GPU lane (owner's Windows desktop).

- **Renderer:** Forward+ on Vulkan 1.3.280, NVIDIA GeForce GTX 1060 3GB (driver 560.94), real GPU.
- **Preset:** `user://graphics_override.cfg` set to Medium, then High. The stage tool builds its own `WorldEnvironment` and never calls the graphics-preset API. The preset's environment features (fog, SSAO, SSIL, glow) don't reach this stage, so Medium and High differ only in renderer project settings. All three judges saw the two renders as identical.
- **Resolution:** 1280x720.
- **Source:** origin/main 9db3d2146, unmodified.
- **Command:** `godot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1280x720 --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=ripplet,burrowback,meadowhart,galecrest,mirejaw,riverdrake,aeriex,tanglevolt,fulgocobra,tuskroot,stormcapra,staticub,voltarach,veridian,abyssal_guardian,stormursa --whole-body --context --out=<dir>`. Exit 1 only because of the tool's pose-inventory errors (missing fly_grip/swim/ride clips on several species); all 265 frames were written.
- **Capture mode:** non-candidate, so each model plays its own installed clips. This matches the CPU gap-round anchor's mode. The enabled F36#1 pose recipes are not shown here; they need `--candidate`, so a round 2 with recipe poses is queued.
- **Grandpa (row 25):** not re-scored. It already passed on GPU Medium frames at 7.53.

## Judging

Three fresh code-blind judges, one batch on one scale:
- **Anchor:** the committed CPU sheet `CREATURES/close-1020/_sheet-f36-0-gap-round.png`. They scored creatures 2, 4, 5, 6 and 8, both variants; the judges weren't told which variant is ON.
- **GPU sheets:** four sheets, four creatures each, standing / hit react / faint mid / faint end, with Medium and High rows per creature.

Judges saw only the sheets, frames, `docs/reference` boards and ART_DIRECTION (`judge_prompt.md`). The code → species map was withheld (`f36_0_gpu_r1_key.json`).

**Anchor, the ON variant on the CPU sheet, scored on this scale** (CPU judges in brackets):

| Species | This scale | CPU judges |
|---|---|---|
| riverdrake | 5.27 | 6.83 |
| tanglevolt | 3.80 | 7.17 |
| fulgocobra | 3.97 | 6.93 |
| stormcapra | 4.27 | 6.90 |
| galecrest | 3.53 | 6.47 |

The judges identified anchor creatures 2/4/6/8 as the same models as the GPU rows and scored them alike: GPU ≈ CPU on one scale.

**GPU results** (Medium = High for every judge; j1/j2/j3, mean, CPU score in brackets):

| Species | j1/j2/j3 | Mean | CPU | Verdict |
|---|---|---|---|---|
| ripplet | 6.8/7.2/6.8 | 6.93 | 6.70 | REOPENED |
| veridian | 6.4/6.6/6.6 | 6.53 | 6.90 | REOPENED |
| burrowback | 5.8/6.6/6.4 | 6.27 | 6.87 | REOPENED |
| aeriex | 5.2/6.2/5.6 | 5.67 | 6.93 | REOPENED |
| meadowhart | 5.4/5.6/5.4 | 5.47 | 6.83 | REOPENED |
| riverdrake | 4.4/6.4/5.0 | 5.27 | 6.83 | REOPENED |
| abyssal_guardian | 4.6/5.4/5.2 | 5.07 | 6.73 | REOPENED |
| tuskroot | 4.6/4.6/4.8 | 4.67 | 7.03 | REOPENED |
| stormcapra | 4.3/4.6/4.6 | 4.50 | 6.90 | REOPENED |
| staticub | 4.0/4.4/4.4 | 4.27 | 6.90 | REOPENED |
| stormursa | 4.0/4.4/4.2 | 4.20 | 6.73 | REOPENED |
| mirejaw | 4.0/4.0/3.6 | 3.87 | historical ON | REOPENED |
| tanglevolt | 3.6/3.8/4.0 | 3.80 | 7.17 | REOPENED |
| voltarach | 3.4/3.6/4.0 | 3.67 | historical ON | REOPENED |
| fulgocobra | 3.3/3.5/4.0 | 3.60 | 6.93 | REOPENED |
| galecrest | 3.3/3.8/3.4 | 3.50 | 6.47 (historical ON) | REOPENED |

The roster mean is 4.83. Bar B: yes on sheet 1 only (ripplet, burrowback, meadowhart, galecrest), from all three judges.

No oxblood leaks onto any friendly creature (all three judges).

## Judges' asks (all three)

1. **Two art styles (needs new art).**
   - About half the ON roster reads as realistic, sourced, photo-textured meshes with no stylised face: tanglevolt, the staticub/stormursa bears, fulgocobra, voltarach, galecrest, mirejaw, stormcapra and tuskroot.
   - They sit beside the stylised ripplet, burrowback, veridian, aeriex and riverdrake.
   - Stormursa reads as the staticub mesh scaled up, with no identity of its own.
2. **Hurt and faint poses in this capture (fixable in scene).**
   - Hit react ≈ standing everywhere.
   - These faints never collapse: ripplet, burrowback, riverdrake, abyssal, staticub, stormursa.
   - These flip belly-up and float, or break material: meadowhart, mirejaw, tanglevolt, tuskroot, stormcapra.
   - Fulgocobra rears instead of fainting.
   - These are the installed clips, not the enabled recipes (see round 2).
3. **Faces, palette and scale.**
   - Faces are small or unreadable on about half the roster.
   - Dark, low-value palettes melt at small size: galecrest, fulgocobra, voltarach, tanglevolt.
   - Scale: mirejaw stands below the trainer; burrowback is borderline; voltarach is very large; fulgocobra's ruler is hidden behind the coil in standing frames.

Sheet: `_sheet_f36_0_gpu_medium_standing.png` (all 16 ON creatures standing, GPU Medium, named). Per-frame captures stay local.

## Round 2 (22 Oct, ~03:00 CT): shipped recipe poses (`--candidate`), all 16 still REOPENED

- **Capture:** the same tool and stage at GPU Medium with `--candidate`, which plays the `f36_candidate/*` enabled recipe clips.
- **Result:** all 16 species installed their recipe (exit 0, 345 frames). Columns: standing, hit react, hit recover (phase .75), faint mid, faint end.
- **Judging:** three fresh code-blind judges, the same anchor (gap-round sheet) and the same prompt (`judge_prompt_r2.md`, one row per creature). Scores are in `f36_0_gpu_r2_key.json`.

**Anchor ON variants on this scale:** riverdrake 5.17, tanglevolt 3.57, fulgocobra 3.60, stormcapra 4.17, galecrest 3.67. Round 1 gave 5.27 / 3.80 / 3.97 / 4.27 / 3.53, so the scale is stable across rounds.

| Species | Round 2 j1/j2/j3 | R2 mean | R1 mean | Verdict |
|---|---|---|---|---|
| ripplet | 6.8/6.4/6.6 | 6.60 | 6.93 | REOPENED |
| veridian | 5.3/5.4/6.8 | 5.83 | 6.53 | REOPENED |
| burrowback | 5.2/5.5/6.0 | 5.57 | 6.27 | REOPENED |
| meadowhart | 5.4/5.0/6.3 | 5.57 | 5.47 | REOPENED |
| abyssal_guardian | 5.2/5.5/5.8 | 5.50 | 5.07 | REOPENED |
| riverdrake | 5.0/5.6/5.5 | 5.37 | 5.27 | REOPENED |
| aeriex | 4.6/5.3/5.6 | 5.17 | 5.67 | REOPENED |
| tuskroot | 4.6/5.2/5.0 | 4.93 | 4.67 | REOPENED |
| stormcapra | 4.3/4.5/4.8 | 4.53 | 4.50 | REOPENED |
| mirejaw | 4.0/3.8/4.5 | 4.10 | 3.87 | REOPENED |
| staticub | 4.0/3.8/4.0 | 3.93 | 4.27 | REOPENED |
| galecrest | 3.6/4.2/3.5 | 3.77 | 3.50 | REOPENED |
| tanglevolt | 3.5/4.0/3.8 | 3.77 | 3.80 | REOPENED |
| stormursa | 3.6/3.6/3.3 | 3.50 | 4.20 | REOPENED |
| voltarach | 3.4/3.5/3.5 | 3.47 | 3.67 | REOPENED |
| fulgocobra | 3.8/3.4/3.0 | 3.40 | 3.60 | REOPENED |

The roster mean is 4.69 (round 1: 4.83). Bar B: yes on sheet 1 from two of three judges; otherwise no. No oxblood leaks (all three).

**What the recipe poses change.**
- **Readable faints:** they now read for ripplet (on its side), riverdrake, tuskroot, abyssal_guardian and aeriex.
- **Still no faint:** voltarach, mirejaw and fulgocobra never visibly faint.
- **New breakages, fixable in pose:** galecrest's wings splay into a tangle. Veridian's and meadowhart's antlers pass through the floor. Stormcapra's face disappears into the wool.

**Finding (same as F29#3):** stormursa's faint end shows grey, untextured, stretched slabs at the hind leg and forelimbs, all three judges. Staticub's faint end shows smeared flank fur. Tanglevolt's faint material breaks into white and grey patches.

The asks are unchanged from round 1. Top of the list is the split style: about half the ON roster is realistic, sourced meshes with decals beside the stylised ripplet, veridian, burrowback, tuskroot and abyssal_guardian. That needs new art. Faces and unreadable dark palettes follow.

Sheet: `_sheet_f36_0_gpu_r2_standing_faint.png` (round 2, standing | faint end for all 16, named).

## Yardstick rejudge (22 Oct, ~12:15 CT): Ripplet GPU-CONFIRMED (7.89); the other 15 ON rows REOPENED

**Batch:** `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`.
- **Anchors:** F36#0 gap C3, craft, P2-094 r4, F36 NPC C1.
- **Candidates:** 16 species. The sides are GPU Medium round 2 (`--candidate`, the enabled recipe poses, as shipped) against round 1 (installed clips), shuffled. Each side shows standing, hit react, hit recover, faint mid and faint end on the stage beside the 1.80 m ruler.
- **Judging:** three fresh judges, `JUDGE_PROMPT.md` verbatim.

**Calibration:** linear slope 1.041, intercept 0.632, r 0.920, anchor RMSE 0.533, top anchor 7.53 (a confirming batch). One warning: Ripplet's shipping recipe (and Aeriex's installed clips) meet the bar only above the top anchor. That is extrapolated, but the batch's anchors reach 7.35 or more, so this is the confirming batch.

| Species | Shipping (recipe poses) mapped | Installed clips mapped | Verdict |
|---|---|---|---|
| **ripplet** | **7.89** | 7.26 | **CONFIRMED** (above the top anchor; confirming batch) |
| riverdrake | 7.33 | 6.50 | REOPENED (0.17 short) |
| meadowhart | 7.19 | 6.43 | REOPENED |
| burrowback | 7.16 | 6.71 | REOPENED |
| aeriex | 7.16 | 7.54 | REOPENED (the installed clips would pass; the recipe arm does not) |
| abyssal_guardian | 6.85 | 5.98 | REOPENED |
| tuskroot | 6.71 | 6.67 | REOPENED |
| stormursa | 6.64 | 5.56 | REOPENED |
| staticub | 6.43 | 5.80 | REOPENED |
| stormcapra | 6.36 | 6.46 | REOPENED |
| veridian | 6.19 | 6.88 | REOPENED |
| mirejaw | 6.12 | 6.22 | REOPENED |
| tanglevolt | 6.12 | 5.73 | REOPENED |
| galecrest | 5.56 | 5.87 | REOPENED |
| fulgocobra | 5.56 | 5.21 | REOPENED |
| voltarach | 5.49 | 5.42 | REOPENED |

The shipping roster mean is 6.55. The recipe poses beat the installed clips on 11 of 16 species. They lose on aeriex, veridian (the antlers twist vertical in faint), stormcapra (the head is lost in the wool), mirejaw and galecrest.

The judges' asks:
- **Faints, fixable in scene:** these sit up, stay standing or fold upright: galecrest, tanglevolt, staticub, voltarach, fulgocobra (rears), abyssal on one side.
- **Identity loss on faint:** belly-up colour loss (mirejaw, veridian); the tuskroot shell vanishes; stormcapra becomes a headless wool blob.
- **Dark creatures:** voltarach, fulgocobra, galecrest and tanglevolt need rim light and value separation.
- **Faces, needs new art:** voltarach, galecrest and fulgocobra need readable faces and colour blocks.

Sheet: `yardstick/_sheet_f36_0_yardstick_ripplet.png`.
