You are the Tetherbound JUDGE-KIT lane (4 Nov 2026). Your branch: tb/judge-kit-1104. Create it from origin/main, work and push only there. Lane folder: ralph/reports/LANES/JUDGE-KIT/.

Read CLAUDE.md first; it is binding. The coordinator is session session_01CfKRDSan7LUFmNAx6VWNUy. It lands your work in a PR with full-ci; never push to main.

OWNER (4 Nov 2026): "Set up a fast way to judge. I'll start the remote later to confirm but keep coding up any changes a judge has previously said then anything a new judge on CPU says." Four new region visual lanes (tb/vis-{meadows,tidewake,cloudreach,stormwood}-1104) and the visual lane on tb/creatures-ralph all capture on CPU (llvmpipe, Low/Compatibility) and judge with tools/visual_judge. Today one item takes about an hour per round. The owner explicitly authorised this tooling task; it is not ordinary harness work.

Goal: an A/B judging round for ONE item takes about 10 minutes or less on CPU, and its score stays comparable with today's.

Deliver:
1. `tools/visual_judge/quick_judge.py`, plus a short README section. Given an item id (e.g. F39#23) and an optional flag overlay (a JSON patch over data/config files), it:
   a. looks up that item's stands and repro commands, from ralph/reports/VISUAL/item-scores/<biome>/job.json and the board catalog;
   b. captures ONLY those stands, base and candidate, in one Godot process or one boot per side where the capture tool allows it;
   c. reuses an import cache and a prepared world, so it does no full re-import;
   d. builds the judge packet: base and candidate tiles, JUDGE_PROMPT.md verbatim, and 3 anchor pairs from anchor_tiles.py with cached anchor scores;
   e. writes a ready-to-paste instruction for launching the 3 code-blind judge subagents in ONE message, plus a `--finish` step that runs calibrate.py and writes VERDICT.md, mapped.json and a contact sheet in the lane's report folder.
2. Measured timings before and after on a real item, recorded in READY.md. Also a parity check: one item already scored the slow way (e.g. F39#23, CPU 6.91 in v1/b5 on tb/creatures-ralph) re-scored the quick way, within the anchor RMSE.
3. A focused test for the stand lookup and the overlay apply/revert (the overlay must restore every file byte-identically).

Do NOT change JUDGE_PROMPT.md, the anchors' meaning or calibrate.py's maths. Speed must never come from lowering the bar or reframing cameras.

Setup:
1. Get the full working tree. It is about 7 GB, so mind your disk.
2. Use Godot 4.7 headless, at /usr/local/bin/godot or by installing 4.7-stable, and import once.

Cadence:
- Push at least hourly.
- When the kit works, write READY.md and send the coordinator a short message: send_message to session_01CfKRDSan7LUFmNAx6VWNUy with the commit and the timings, so it can tell the region lanes.
- Never sit idle. Arm send_later 20–30 minutes out before ending any turn.
