# GPU pass: P2-018 shiny palette distinction: REOPENED (Medium 5.30, High 5.10)

22 Oct 2026, ~02:45 CT. Remote GPU lane (owner's Windows desktop).

- **Renderer:** Forward+ on Vulkan, NVIDIA GeForce GTX 1060 3GB, 1920x1080. The presets were set through the tool's look-dev bootstrap, which records `preset`, `renderer forward_plus` and the adapter in each manifest.
- **Source:** origin/main 9db3d2146, unmodified. `creature_surface_finishes.json` is as landed: the P2-018 rows are ON and P2-030's `shiny_fallback` is OFF.
- **Command:** `godot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --script res://tools/phase2_capture_creatures.gd -- --biome=<meadows|stormwood|cloudreach> --poses=idle,shiny_idle --only=<rows> --preset=<Medium|High> --source-commit=9db3d2146d0587d189cf172567b17345f31a0abd --output=res://.artifacts/phase2/<fresh>`.
- **Rows:** the 13 listed in `SHARED-ART/close-1020/NOTE.md`:
  - Meadows: nightburrow, stormtrail, riftfrill.
  - Stormwood: sparkit, stormtrail.
  - Cloudreach: cloudfang, galecrest, breezetail, cliffspike, pebbik, stormcapra, solmane, aeriex.
- **Frames:** 26 per preset; all exit 0.
- **Rejected first attempt:** it omitted `--source-commit`, which the bootstrap requires, and was re-run.

**Anchor:** none. The CPU P2-018 sheet was never committed (the SHARED-ART folder holds only NOTE.md), so this row has no same-scale CPU anchor. For calibration, the same judges in the same batch scored the P2-095 and P2-094 CPU anchors 1.1–1.4 below their CPU judges.

## Judging

Three fresh code-blind judges scored this in one batch with P2-095/096 and P2-094. Prompt: `judge_prompt.md`; scores: `p2_gpu_key.json`.

| Render | j1/j2/j3 | Mean | Verdict |
|---|---|---|---|
| **GPU Medium** | 5.2/5.4/5.3 | **5.30** | PARTIAL ×3 |
| **GPU High** | 5.0/5.2/5.1 | **5.10** | PARTIAL ×3 |

High is lower only because the Cloudreach stand was raining in the High run, which dulls the shinies.

**Bar A below 7.5: REOPENED.** No flat-magenta shiny and no oxblood anywhere (all three judges).

Per creature (j1 / j2 / j3):
- **DISTINCT ×3:** nightburrow, both stormtraits, riftfrill, sparkit, breezetail, cliffspike.
- **WEAK ×3:** cloudfang (white → cream), galecrest (cyan wingtips only), stormcapra (faint blue fleece, crystals blue → gold).
- **aeriex:** DISTINCT, DISTINCT, WEAK.
- **pebbik:** DISTINCT, DISTINCT, BROKEN (mint and purple blotching, "skull-like" eye sockets).
- **solmane:** **BROKEN ×3**. Noisy cyan and yellow camouflage blotches with dark eye smudges; it reads as a hue-threshold texture fault, not a designed colourway (`gpu-p2018-cloudreach-*/cloudreach__solmane__shiny_idle.jpg`).

## Judges' asks

1. **Needs new art:** repaint the main body colour, not just the trims, on cloudfang, galecrest, stormcapra and aeriex.
2. **Needs new art:** rebuild the solmane (and ideally pebbik) shinies as clean two- or three-colour blocks with intact faces.
3. **Fixable in scene:** add a shiny cue on reveal (sparkle burst or rim glint), and light the Stormwood stand so small shinies read against the dark ground.
4. **Outside this row:** stormtrail's shiny loses its spark accents, and sparkit and stormtrail stand shorter than the 1.80 m trainer.

Sheet: `_sheet_p2_018_gpu_medium.png` (GPU Medium, each creature normal | shiny).

## Yardstick rejudge (22 Oct, ~12:00 CT): mapped 5.88 (Medium) / 5.94 (High), REOPENED

Batch: `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`. Anchors: craft (after/before), F36#0 gap C1, F36 NPC C1, F04#6 r22. The candidates are the overnight GPU frames, Medium vs High as sides A/B (shuffled): P2-018 per biome (normal | shiny grids), the P2-095/096 craft panel, and the P2-094 wall (close + full). Three fresh judges, `JUDGE_PROMPT.md` verbatim. Calibration: linear slope 0.618, intercept 3.218, r 0.813, anchor RMSE 0.563, top anchor 7.53 (a confirming batch), no warnings, `above_top_anchor` false for every candidate. Files in `yardstick/`.

| Biome | Medium mapped | High mapped | Shiny defect (judge calls, both sides) |
|---|---|---|---|
| Meadows (nightburrow, stormtrail, riftfrill) | 6.18 | 6.18 | FIXED ×6 |
| Stormwood (sparkit, stormtrail) | 5.34 | 5.34 | FIXED ×6 |
| Cloudreach (8 rows) | 6.12 | 6.31 | FIXED ×4, PARTIAL ×2 (cloudfang, stormcapra weak) |

**P2-018: mapped 5.88 (Medium) / 5.94 (High), below 7.5: REOPENED.** The recorded defect is answered: no magenta multiply, and the shinies are distinct. The score is held down by:
- small creatures well below the 1.80 m trainer;
- dark normals that vanish on dark ground (Stormwood stormtrail);
- one repeated pale or albino shiny formula;
- flat stands (bare Stormwood mud, a flat Cloudreach green plane).
