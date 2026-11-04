You are the Tetherbound VIS-STORMWOOD lane (4 Nov 2026). Your branch: tb/vis-stormwood-1104. Create it from origin/main, work and push only there. Lane folder: ralph/reports/LANES/VIS-STORMWOOD/.

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

Scope: ONLY the stormwood items below. The visual lane on tb/creatures-ralph keeps creatures, poses and its in-flight arms (Fulgocobra 6.52; Stormwood storm-light set F41#2/#5; Meadows Blender ridge F38#24; hud_lean). Read its ralph/reports/LANES/CREATURES-RALPH/READY.md and VERDICTs on origin/tb/creatures-ralph before starting so you do not redo or fight its arms. Items marked LATEST already have work in flight there: build on it (merge origin/tb/creatures-ralph if you need its arm), do not duplicate it.

Your items (board id, current score and source, criterion). Lowest first, but batch by shared capture stand:
- F41#22 [F41] unscored: The biome frame matrix (approach, gameplay camera, reverse, detail, day/night, weather, a real fight) passes the new bar on High and Medium.
- F41#24 [F41] unscored: No flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the matrix.
- F22#4 [other] unscored: Named fights (Warden, captains, relay officers, Nerissa, Veyra, Stormwood finale) each present a distinct pattern and pass C2/C3 on the new timings; t
- F41#18 [F41] 3.91 GPU item: F41 (2) impact>12 item P2-056 uniformed character readability: Dark uniformed officers and trainers blend into the purple rainy forest and lack legibl
- F41#8 [F41] 4.03 GPU item: F41 (1) top-20 item P2-055 named character silhouettes: Many distinct named roles in Tidewake and Stormwood repeat the same face body and outfit silho
- F41#1 [F41] 4.41 GPU item: F41 (1) top-20 item P2-037 Stormheart finale: The Stormheart finale reads as a dark cylindrical ring with a hole rather than a giant living tree with 
- F41#4 [F41] 4.54 GPU item: F41 (1) top-20 item P2-038 named destination identities: Several named destinations read as similar grass and trees without a distinct subject in the 
- F41#21 [F41] 4.92 GPU item: F41 (2) impact>12 item P2-111 Hollows victory reward tiles: The Hollows victory acknowledgement visually groups with the persistent quickbar so its it
- F41#16 [F41] 5.05 GPU item: F41 (2) impact>12 item P2-110 Hollows fight loss result clarity: After the creature falls a large out-of-fight message appears over the exploration HU
- F41#10 [F41] 5.06 GPU item: F41 (2) impact>12 item P2-070 Glass Sink landmark: The named Glass Sink appears as an abrupt unmarked terrain edge over a uniform checker-textured voi
- F41#5 [F41] 5.24 GPU item: F41 (1) top-20 item P2-039 forest ground and distance layers: Uniform grass and flower carpet across broad flat land weakens the deep wet ancient fore  [LATEST: CPU 5.84 (storm-light set on tb/creatures-ralph, tests pending)]
- F41#9 [F41] 5.40 GPU item: F41 (1) top-20 item P2-046 harvest resource identity: Several harvest nodes look like ordinary stone mushrooms trees or foliage without a readable cue
- F41#19 [F41] 5.68 GPU item: F41 (2) impact>12 item P2-043 Glass Field spike bases: Blue glass spikes rise from a flat dark base with grass passing through it and a rigid white se
- F41#20 [F41] 5.68 GPU item: F41 (2) impact>12 item P2-084 named character dialogue reuse: Distinct named Stormwood characters use identical dialogue lines — fixed on main with a 
- F41#2 [F41] 5.69 GPU item: F41 (1) top-20 item P2-042 Surge phase presentation: Calm Building and Fading weather stills remain difficult to distinguish while Break reads mainly   [LATEST: CPU 5.80 (storm-light set on tb/creatures-ralph, tests pending)]
- F41#15 [F41] 5.90 GPU item: F41 (2) impact>12 item P2-083 dialogue foreground obstruction: Large foreground creatures or overhead geometry hide the named speaker in several dialo
- F41#3 [F41] 5.98 GPU item: F41 (1) top-20 item P2-092 named wild fight actor spacing: Voltarach and Sparkit crowd into the same space so the boss legs mask or intersect the ally
