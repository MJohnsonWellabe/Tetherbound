You are the Tetherbound VIS-TIDEWAKE lane (4 Nov 2026). Your branch: tb/vis-tidewake-1104. Create it from origin/main, work and push only there. Lane folder: ralph/reports/LANES/VIS-TIDEWAKE/.

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

Scope: ONLY the tidewake items below. The visual lane on tb/creatures-ralph keeps creatures, poses and its in-flight arms (Fulgocobra 6.52; Stormwood storm-light set F41#2/#5; Meadows Blender ridge F38#24; hud_lean). Read its ralph/reports/LANES/CREATURES-RALPH/READY.md and VERDICTs on origin/tb/creatures-ralph before starting so you do not redo or fight its arms. Items marked LATEST already have work in flight there: build on it (merge origin/tb/creatures-ralph if you need its arm), do not duplicate it.

Your items (board id, current score and source, criterion). Lowest first, but batch by shared capture stand:
- F39#21 [F39] unscored: F39 (2) impact>12 item P2-103 named fight victory hierarchy: Named fight victory reward panels sit over the full exploration HUD team roster hotbar an
- F39#30 [F39] unscored: The biome frame matrix (approach, gameplay camera, reverse, detail, day/night, weather, a real fight) passes the new bar on High and Medium.
- F39#32 [F39] unscored: No flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the matrix.
- F39#31 [F39] 3.35 CPU: The hero landmark (Veilfall) reads at distance and up close.
- F39#3 [F39] 4.85 GPU item: F39 (1) top-20 item P2-011 named destination read: Several named route destinations read as unmarked grassy slopes or small generic structures instead
- F39#15 [F39] 4.85 GPU item: F39 (2) impact>12 item P2-026 Veilfall approach shallows: A ruler-straight chain of nearly identical tan discs with white rims makes the Veilfall appr
- F39#8 [F39] 4.97 GPU item: F39 (1) top-20 item P2-108 Aquaryn mounted-water pose: The seated Aquaryn rider traverses turquoise water while the mount stays tall and nearly static
- F13#5 [other] 3.61 GPU: Currents, inhabited docks and Veilfall distance read pass T2 matrix
- F39#17 [F39] 5.08 GPU item: F39 (2) impact>12 item P2-067 current restoration environment: The restored current removes the white flow streaks while shoreline sandbars water colo
- F39#16 [F39] 5.18 GPU item: F39 (2) impact>12 item P2-066 live current streaks: Live currents use long bright evenly spaced parallel white streaks that read like guide lanes on t
- F39#5 [F39] 5.20 GPU item: F39 (1) top-20 item P2-071 surface swimming trainer pose: During the swim crossing the submerged trainer remains upright with relaxed arms and visible
- F39#24 [F39] 5.32 GPU item: F39 (2) impact>12 item P2-029 creature rest poses: Riptusk and Torrentoad resting poses roll onto their backs with limbs raised and read as distressed
- F39#27 [F39] 5.48 GPU item: F39 (2) impact>12 item P2-057 grass around named characters: Dense pale grass reaches knee to waist height around Tidewake characters and hides much o
- F39#1 [F39] 5.56 GPU item: F39 (1) top-20 item P2-008 shore landforms: Repeated grassy domes with steep smooth gray rock skirts lack layered shore ecology and clear grass-to-san
- F39#6 [F39] 5.61 GPU item: F39 (1) top-20 item P2-028 creature faint state: Several fainted aquatic creatures keep raised alert heads or upright crouches instead of reading as d
- F39#22 [F39] 5.62 GPU item: F39 (2) impact>12 item P2-109 Aquaryn dismount camera obstruction: After dismount the camera sits close behind Aquaryn so its back and fins fill much 
- F39#7 [F39] 5.65 GPU item: F39 (1) top-20 item P2-089 fight actor composition: Close-range fight staging lets allies, enemies and sometimes the trainer intersect, so heads and l
- F39#20 [F39] 5.70 GPU item: F39 (2) impact>12 item P2-090 fight background creature ground contact: A small blue creature-like figure remains partly buried in sand behind Ripplet
- F39#2 [F39] 5.78 GPU item: F39 (1) top-20 item P2-010 Veilfall silhouette: The distant Veilfall mountain reads as a near-geometric dark cone with narrow broken waterfall streaks
- F39#14 [F39] 5.78 GPU item: F39 (2) impact>12 item P2-072 swimmer water contact: The moving trainer leaves little localized wake splash foam or displaced-water ring while a hard 
- F39#19 [F39] 5.78 GPU item: F39 (2) impact>12 item P2-088 fight team roster contrast: The left team roster fades to pale low-contrast text against terrain during active combat — 
- F39#4 [F39] 5.90 GPU item: F39 (1) top-20 item P2-030 shiny creature finish: Several shiny variants become near-uniform hot magenta and lose their ordinary species material and 
