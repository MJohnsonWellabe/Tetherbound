You are the Tetherbound VIS-CLOUDREACH lane (4 Nov 2026). Your branch: tb/vis-cloudreach-1104. Create it from origin/main, work and push only there. Lane folder: ralph/reports/LANES/VIS-CLOUDREACH/.

Read CLAUDE.md first; it is binding. The coordinator is session session_01CfKRDSan7LUFmNAx6VWNUy. It lands your judged gains in PRs with full-ci and merges them; never push to main yourself.

OWNER DIRECTION (4 Nov 2026, verbatim): "Don't get rid of meshy models but you could move them off main or something. Get more done. Start extra sessions. Code everything under 6 up to above six. Set up a fast way to judge. I'll start the remote later to confirm but keep coding up any changes a judge has previously said then anything a new judge on CPU says."
Earlier (2 Nov): there are no Meshy credits and the GPU is off, so new meshes are built in Blender, and everything is captured and judged on CPU.

How to work an item:
1. **Code what judges already asked for.** For every item in your list, first find the fixes earlier judges asked for, in `ralph/reports` (GPU item-scores under `ralph/reports/VISUAL/item-scores/`, earlier lanes' VERDICT.md files, and `recorded_defects.txt`). Implement them behind a scoped config flag that defaults OFF (with `_why` and `scope`). Then capture the base and the candidate in the same CPU run on the same stands, and judge both.
2. **Then work what the new CPU judges ask for.** Each round, implement what your own judges named as remaining.
3. **Yardstick:** `tools/visual_judge`: `JUDGE_PROMPT.md` verbatim, `anchor_tiles.py` with at least 3 anchor pairs per folder, 3 fresh code-blind judge subagents launched in ONE message so they run in parallel, and `calibrate.py`. An item is done at a mapped CPU score of 6.0 or above. Record it as "CPU <base> -> <cand>". If a fast judge kit appears on main (`tools/visual_judge/quick_judge*`), use it.
4. **Turning a flag on:** only after a judged gain. Put the score in `_why` and add a test that asserts the flag is ON and records the score. Run the touched tests and `tests/test_texture_import_policy.gd` (new textures must be in VRAM-compressed import mode) before you push.
5. **Hard rules:**
   - Red and oxblood are reserved for Team Tether.
   - Never shrink a creature; grow the smaller side.
   - No camera reframing just to dodge a defect.
   - Never weaken, skip or quarantine tests.
   - New meshes are built in Blender, each with a drafted reference, a 1.80 m trainer scale check and provenance, and flag-OFF until judged.
   - Never commit per-frame captures. Commit only verdicts, small JSON and at most one `_sheet*.png`/jpg under 1.5 MB per round.
   - Never print or commit any API key.

Setup (CPU only):
1. Get the FULL working tree. It is about 7 GB, so mind your disk and delete large temporaries.
2. Godot 4.7 headless at `/usr/local/bin/godot`, or install 4.7-stable. Run `godot --headless --path . --import` once.
3. For new meshes, install portable Blender 4.2 LTS into scratch.
4. Captures run on llvmpipe at Low/Compatibility, using the `phase2_capture_*` tools and the `capture_*_matrix` tools under `tools/`. Each GPU item-score row in `ralph/reports/VISUAL/item-scores/<biome>/job.json` carries its frame's repro command.
5. Run one Godot capture at a time, and judge while the next capture runs.

Cadence:
- Push at least hourly to your branch.
- Keep `ralph/reports/LANES/<LANE>/READY.md` current: each landing-ready flag, its CPU score, its test, and the commit.
- Never sit idle. Before ending any turn, arm `send_later` 20–30 minutes out, or keep a background capture or waiter running that wakes you.
- If you are blocked, write the blocker in READY.md and move to the next item.

Scope: ONLY the cloudreach items below. The visual lane on tb/creatures-ralph keeps creatures, poses and its in-flight arms (Fulgocobra 6.52; Stormwood storm-light set F41#2/#5; Meadows Blender ridge F38#24; hud_lean). Read its ralph/reports/LANES/CREATURES-RALPH/READY.md and VERDICTs on origin/tb/creatures-ralph before starting so you do not redo or fight its arms. Items marked LATEST already have work in flight there: build on it (merge origin/tb/creatures-ralph if you need its arm), do not duplicate it.

Your items (board id, current score and source, criterion). Lowest first, but batch by shared capture stand:
- F40#0 [F40] unscored: After F26 look-dev, the biome is re-captured (≥200 frames) and its catalog rows re-scored against the new bar.
- F40#18 [F40] unscored: F40 (2) impact>12 item P2-118 full-party catch choice legibility: The full-party caught-creature choice panel leaves the earlier battle HUD visible th
- F40#19 [F40] unscored: The biome frame matrix (approach, gameplay camera, reverse, detail, day/night, weather, a real fight) passes the new bar on High and Medium.
- F40#21 [F40] unscored: No flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the matrix.
- F40#6 [F40] 4.92 GPU item: F40 (1) top-20 item P2-105 mounted terrace edge and cloud crossing: The mounted deer and seated trainer retain their upright riding silhouette while t
- F40#11 [F40] 5.16 GPU item: F40 (2) impact>12 item P2-106 terrace edge clouds: Flat white polygonal cloud puffs cover the terrace cliff edge and read as loose foreground shapes a
- F40#1 [F40] 5.29 GPU item: F40 (1) top-20 item P2-021 open terrain: Broad level grass fields and sparse ordinary trees dominate Cloudreach views where layered elevated land and 
- F40#9 [F40] 5.50 GPU item: F40 (2) impact>12 item P2-068 named NPC post readability: Several named Cloudreach NPCs look small or partly hidden behind the foreground trainer and 
- F40#4 [F40] 5.64 GPU item: F40 (1) top-20 item P2-023 exposed landform edges: Floating island undersides form blunt dark slabs and several cliffs and grassy shelves have conspic
- F40#8 [F40] 5.72 GPU item: F40 (2) impact>12 item P2-053 bright Cloudreach route markers: Saturated cyan posts rings and rails at the bridge and flight aerie compete with the bu
- F40#2 [F40] 5.81 GPU item: F40 (1) top-20 item P2-022 summit aviary: The summit landmark reads as a small skeletal dome on grass beside a separate court instead of a layered sto
- F40#17 [F40] 5.90 GPU item: F40 (2) impact>12 item P2-102 High Perches rim mushroom: A yellow mushroom cluster appears suspended beyond the grassy rim with no ground beneath its 
