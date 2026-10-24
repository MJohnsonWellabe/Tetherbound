# F36#1 held shove hit on main: GPU pass (24 Oct 2026)

**Verdict:**
- **CONFIRMED (the recipe maps to 7.5 or more):** Tanglevolt 7.89, Frostclaw 7.88, Stormcapra 7.79, Cloudfang 7.73, Breezetail 7.69, Craghorn 7.66.
- **REOPENED:**
  - Close to the bar: Aquaryn 7.49, Tidecoil 7.45.
  - No gain over shipping: Solmane 7.33 (shipping 7.26).
  - Below the bar: Cliffspike 7.03, Thundertunnel 6.91, Voltwig 6.89, Pebbik 6.89.
  - **Below shipping:** Galecrest 6.62 against 6.72, and **Stormraven 5.81 against 6.09**.

## Scope

- **Species checked:** the 15 species in `enabled_species` whose CPU candidate scored 7.0 or more in close-1024 b2-b4 and b8-b9. Only those could confirm 7.5.
- **Not checked here:** the other 35 enabled species, which are CPU-provisional or below-bar ONs. A GPU pass on them would confirm or reopen nothing at 7.5.

## Run

- **Source:** main 7b5d351da.
- **Captures** (`capture_f36_poses.gd --species=<15> --whole-body --context`), all at 1920x1080 on the GTX 1060 (Forward+):
  - recipe: `--candidate` at Medium;
  - shipping: no flag, at Medium;
  - recipe: `--candidate` at High, as a check.
- **Shipping-run errors:** the shipping run exits 1 on travel clips some species do not have (`galecrest: missing fly_grip clip`). Every species still has its hit and faint frames, the only frames judged.
- **Medium vs High:** spot-checked; they match, as they have in every earlier creature batch.
- **Sides:** each species is one set, recipe against shipping, at Medium. Five frames per side: standing, hit react, hit recover, faint mid and faint end, the same as the CPU r3 builds. Builder: `build_yard_f36_1.ps1.txt`.

## Yardstick

- **Batches:** three batches of five species. Each was built with `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`, so every batch has its own anchors.
- **Judges:** three fresh code-blind judges per batch, each given `JUDGE_PROMPT.md` (main) verbatim. No recorded defects.

| Batch | Slope | Intercept | r | Anchor RMSE | Confirming | Note |
|---|---|---|---|---|---|---|
| b1 | 0.974 | 1.042 | 0.90 | 0.54 | yes | All five recipes map above the top anchor (7.53): extrapolated, allowed in a confirming batch |
| b2 | 1.170 | −0.235 | 0.98 | 0.24 | yes | Frostclaw likewise |
| b3 | 0.614 | 3.163 | 0.77 | 0.67 | yes | **Weak fit:** the low slope compresses scores toward about 6.9, so read b3 as "below 7.5" rather than as precise values |

| Species | Batch | Recipe mapped (per judge) | **Recipe** | Shipping | Gain | CPU recipe (shipping) |
|---|---|---|---|---|---|---|
| tanglevolt | b1 | 8.15 / 7.47 / 8.05 | **7.89** | 6.04 | +1.85 | 7.99 (7.45) |
| frostclaw | b2 | 7.72 / 7.96 / 7.96 | **7.88** | 6.67 | +1.21 | 7.34 (7.08) |
| stormcapra | b1 | 8.05 / 7.47 / 7.86 | **7.79** | 6.23 | +1.56 | 7.63 (7.04) |
| cloudfang | b1 | 7.86 / 7.47 / 7.86 | **7.73** | 6.95 | +0.78 | 7.82 (7.35) |
| breezetail | b1 | 8.05 / 7.37 / 7.66 | **7.69** | 7.01 | +0.68 | 7.73 (6.71) |
| craghorn | b1 | 7.76 / 7.37 / 7.86 | **7.66** | 6.79 | +0.87 | 7.89 (6.90) |
| aquaryn | b2 | 7.37 / 7.37 / 7.72 | 7.49 | 6.16 | +1.33 | 7.29 (6.27) |
| tidecoil | b2 | 7.26 / 7.37 / 7.72 | 7.45 | 6.16 | +1.29 | 7.43 (6.16) |
| solmane | b2 | 7.49 / 7.49 / 7.02 | 7.33 | 7.26 | +0.07 | 7.31 (6.37) |
| cliffspike | b3 | 6.97 / 7.22 / 6.91 | 7.03 | 6.85 | +0.18 | 7.16 (6.71) |
| thundertunnel | b3 | 6.85 / 7.15 / 6.72 | 6.91 | 6.64 | +0.27 | 7.22 (6.74) |
| voltwig | b3 | 6.85 / 7.09 / 6.72 | 6.89 | 6.70 | +0.19 | 7.04 (6.65) |
| pebbik | b3 | 6.97 / 7.03 / 6.66 | 6.89 | 6.46 | +0.43 | 7.09 (6.68) |
| galecrest | b3 | 6.79 / 6.54 / 6.54 | 6.62 | 6.72 | **−0.10** | 7.01 (6.87) |
| stormraven | b2 | 5.62 / 5.38 / 6.44 | 5.81 | 6.09 | **−0.28** | 7.47 (6.65) |

## What the judges saw

1. **Recipe sides** (all three judges in b1 and b2): the faint lies grounded on the side or belly and reads without a label. The hit react rears up and reads, though several judges called it a pounce more than a flinch, and a few saw it lift off the floor.
2. **Shipping sides:**
   - the hit react is nearly identical to standing;
   - the faint end often sits upright facing the camera;
   - on Tanglevolt and Stormcapra the shipping faint **flips belly-up and floats**, showing a white-and-black piebald underside.
   - This is why the recipe gains most on those two.
3. **Stormraven:** both arms read as a flat navy mass with no face. The recipe's faint stretches the body into a squashed feather slab, which reads as mesh distortion; the shipping faint balls up. Below shipping.
4. **Galecrest:** a pale, thin, all-white silhouette with no face read. The recipe's faint crumples into a small tangled knot of wings that looks partly sunk into the floor; the shipping faint splays its wings like shards. No gain.
5. **Recurring outside the pose:**
   - near-black values: Thundertunnel;
   - **Frostclaw:** a dark sphere sits at the trainer's feet in every frame of both arms, which two judges flagged as an artefact (possibly a detached tail tip). Worth a look by Creatures, even though the recipe confirms;
   - Voltwig's flat olive material without leaf detail.

## Files

- `_sheet_f36_1_gpu_main.png`: Tanglevolt and Stormcapra, shipping then recipe; standing, hit react, faint mid and faint end at Medium (60 KB).
- `yardstick/b1`–`b3`:
  - `key.json`, `sets.md`, `candidates.json`, `recorded_defects.txt`, `judge_prompt_filled.txt`;
  - `j1.json`–`j3.json`: scores with notes condensed;
  - `batch.json`, `mapped.json`.
- `f36_1_main_queue.ps1.txt`, `build_yard_f36_1.ps1.txt`.
- Per-frame captures stay local.
