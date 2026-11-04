You are the Tetherbound VIS-MEADOWS lane (4 Nov 2026). Your branch: tb/vis-meadows-1104. Create it from origin/main, work and push only there. Lane folder: ralph/reports/LANES/VIS-MEADOWS/.

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

Scope: ONLY the meadows items below. The visual lane on tb/creatures-ralph keeps creatures, poses and its in-flight arms (Fulgocobra 6.52; Stormwood storm-light set F41#2/#5; Meadows Blender ridge F38#24; hud_lean). Read its ralph/reports/LANES/CREATURES-RALPH/READY.md and VERDICTs on origin/tb/creatures-ralph before starting so you do not redo or fight its arms. Items marked LATEST already have work in flight there: build on it (merge origin/tb/creatures-ralph if you need its arm), do not duplicate it.

Your items (board id, current score and source, criterion). Lowest first, but batch by shared capture stand:
- F38#0 [F38] unscored: After F26 look-dev, the biome is re-captured (≥200 frames) and its catalog rows re-scored against the new bar.
- F38#41 [F38] unscored: No flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the matrix.
- F38#24 [F38] 4.42 GPU item: F38 (2) impact>12 item P2-014 distant mountains: The mountain backdrop has hard isolated facets and dark slash shapes instead of continuous landform s  [LATEST: Blender ridge arm built OFF on tb/creatures-ralph (map_paint/ridge), not yet judged]
- F38#17 [F38] 5.02 GPU item: F38 (1) top-20 item P2-087 named trainer dialogue subject visibility: Several named trainer dialogue views show only the player and terrain with no sp
- F38#30 [F38] 5.10 GPU item: F38 (2) impact>12 item P2-012 Burrow Warrens hillside: The hillside beside the Burrow entrance exposes a broad rectangular brown terrain face with str
- F38#13 [F38] 5.21 GPU item: F38 (1) top-20 item P2-059 catch sequence camera framing: The catch camera jumps from a wide aim view to a tight downward view that crops the companio
- F38#22 [F38] 5.30 GPU item: F38 (2) impact>12 item P2-006 mill and settlements: The mill water is a broad flat blue surface with abrupt sparse banks and nearby settlements have l
- F38#33 [F38] 5.42 GPU item: F38 (2) impact>12 item P2-061 catch result hierarchy: Catch breakout and success text compete with persistent creature cards, actions and nearby same-
- F38#29 [F38] 5.51 GPU item: F38 (2) impact>12 item P2-065 trainer defeated presentation: The bridge grunt and Warden remain upright in similar neutral postures after victory whil
- F38#6 [F38] 5.52 GPU item: F38 (1) top-20 item P2-033 ground pickup identity: Many unrelated ground pickups share small glowing plants, orbs or generic crates, so their item ide
- F38#23 [F38] 5.59 GPU item: F38 (2) impact>12 item P2-013 Tether Relay yard: Tall flowers and grass grow densely through the flat trafficked relay yard around guards crates and r
- F38#37 [F38] 5.61 GPU item: F38 (2) impact>12 item P2-079 Meadows dialogue rock obstruction: Large rock faces fill the camera and hide the named speaker during dialogue — fixed o
- F38#2 [F38] 5.62 GPU item: F38 (1) top-20 item P2-016 creature hurt and movement poses: Hurt and moving frames often retain the idle silhouette so the state is difficult to read
- F38#26 [F38] 5.62 GPU item: F38 (2) impact>12 item P2-020 creature ground contact: Dense foreground grass obscures several creatures feet and lower outlines in the normal camera 
- F38#19 [F38] 5.72 GPU item: F38 (1) top-20 item P2-004 exploration HUD: The many dark boxed HUD panels and outlined text occupy a large share of the exploration view — fixed on m  [LATEST: CPU 5.92 (comforter landed #807; HUD boxes remain; hud_lean 5.64 OFF)]
- F38#20 [F38] 5.79 GPU item: F38 (2) impact>12 item P2-003 Team Tether stronghold: The stronghold reads as a small dark ruin behind dominant pylons on approach and as a broad spar
- F38#7 [F38] 5.82 GPU item: F38 (1) top-20 item P2-058 catch aim readability: The capture chance and aim reticle sit on the target and busy grass with little separation from flow
- F38#32 [F38] 5.85 GPU item: F38 (2) impact>12 item P2-035 camp and workshop prop legibility: Small camp and workshop props overlap nearby signs grass creatures or other tools so 
- F38#15 [F38] 5.88 GPU item: F38 (1) top-20 item P2-069 flight and landing pose read: Flight retains a similar spread-wing silhouette in air and the grounded return shows no bird 
- F38#35 [F38] 5.88 GPU item: F38 (2) impact>12 item P2-050 human post poses: Many named villagers and trainers hold the same straight neutral stance with arms down despite differe
- F38#1 [F38] 5.91 GPU item: F38 (1) top-20 item P2-015 creature collapse and rest: Several fainted bodies remain upright or float above the grass and some resting poses do not se
