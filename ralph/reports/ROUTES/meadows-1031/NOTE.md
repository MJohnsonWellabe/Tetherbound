# Routes meadows-1031: Meadows trained lineage (F49#0)

Scope: Meadows only (coordinator, 31 Oct 2026). Tidewake is tb/routes-f49; Cloudreach/Stormwood/homecoming is tb/routes-sky-storm.

Goal: one fresh-title Meadows lineage on `--training-profile=meadows_training_v1`, each piece loading the previous piece's saved output:
opening_village → opening_team → camp_tournament → bridge → training_t1_earn → t1_altar_1..5 → t1_master → t1_kitchen → t1_feed → t1_return → warrens → relay → training_t2_earn → t2_altar_1..5 → t2_master → t2_kitchen → t2_feed → t2_return → sigils → hall → warden → tidewake_handoff (order: `tests/helpers/f49_disk_handoff.gd` TRAINED_MEADOWS_PIECES).

Run: CPU container, Godot 4.7 headless, one Godot at a time, run checkout detached at one SHA; fixtures are committed from a sparse side worktree as `tests/fixtures/earned_saves/f49_mt_<piece>/`. Driver: `tools/earned_saves/routes_kit/chain.sh` runner `et` (added 27b2406d).

## Log
- 2026-10-31 STARTED from origin/main a41e1b30. Godot 4.7 runs; disk 19 GB free. Import warming.
- 2026-10-31 21:45Z Owner direction via coordinator: do not reprove what is proven. Bridge starts from the committed earned `meadows_chain_ev_fights/camp_tournament` (opening_team-first lineage, eb8180ed) with `--pinned-start --historical-team-start` (818d2b5c). Focused tests on 818d2b5c: test_f49_training_prefix + test_altar_training_piece 14/102/0.
- 2026-10-31 21:59Z RUNNING chain on 818d2b5c: bridge → t1 loop → warrens → relay → t2 loop → sigils → hall → warden → tidewake_handoff (`~/rb/chain1.out`), autocommit each pass as `f49_mt_<piece>`.
- 2026-10-31 22:49Z **bridge PASS** (818d2b5c, 3000 s, ordinary input): South Bridge grunt beaten, bridge crossed, ends on the far bank (8.0,-2.9,1339.8); profile meadows_training_v1; f49_pinned_start eb8180ed→818d2b5c, disclosed historical team start. Save `tests/fixtures/earned_saves/f49_mt_bridge/`; seam `seams/camp_tournament__bridge.json` MATCH. Party L8/8/7/5/5, cap 10.
- 2026-10-31 ~23:00Z **STOPPED by owner (usage)**, relayed by coordinator. training_t1_earn was killed about 10 min in (no result, nothing saved). Nothing is running.

## Handoff (state at stop)
- Proven here: camp_tournament → bridge (replaces the voided bridge proof). opening_team and camp_tournament are the existing historical PASS receipts (meadows_chain_ev_fights, kept as-is per owner 31 Oct).
- Next: run the rest from the committed bridge save on 818d2b5c (or later with --pinned-start). Rebuild the root: `mkdir -p ~/rb/ms_hist && for b in opening_team camp_tournament; do cp -r tests/fixtures/earned_saves/meadows_chain_ev_fights/$b ~/rb/ms_hist/; done; mkdir -p ~/rb/mt_bridge && cp -r ~/rb/ms_hist/* ~/rb/mt_bridge/ && mkdir -p ~/rb/mt_bridge/bridge && cp -r tests/fixtures/earned_saves/f49_mt_bridge/{save,receipt.json} ~/rb/mt_bridge/bridge/`, then `ET_EXTRA="--pinned-start --historical-team-start" chain.sh ~/rb/mt_bridge/bridge et:training_t1_earn:mt_t1_earn …` (step list in this note's goal line).
- Runbook: Godot in `~/godot-bin/godot` (installing to /usr/local/bin was refused in this container); import ≈60 min first time; edit worktree must be sparse non-cone including `/tests/fixtures/earned_saves/f49_mt_*/`, and the run checkout must be detached (sharing the branch ref dirties it after a commit); kill by PID, never `pkill -f` (exit 144 hit again).
- Owner direction (31 Oct): when the trained handoff exists, write a reviewed cross-cut seam manifest vs `f49_ms_tidewake_handoff` listing every differing field; Tidewake 01–05 are not re-run.
