# Routes meadows-1031: Meadows trained lineage (F49#0)

Scope: Meadows only (coordinator, 31 Oct 2026). Tidewake is tb/routes-f49; Cloudreach/Stormwood/homecoming is tb/routes-sky-storm.

Goal: one fresh-title Meadows lineage on `--training-profile=meadows_training_v1`, each piece loading the previous piece's saved output:
opening_village → opening_team → camp_tournament → bridge → training_t1_earn → t1_altar_1..5 → t1_master → t1_kitchen → t1_feed → t1_return → warrens → relay → training_t2_earn → t2_altar_1..5 → t2_master → t2_kitchen → t2_feed → t2_return → sigils → hall → warden → tidewake_handoff (order: `tests/helpers/f49_disk_handoff.gd` TRAINED_MEADOWS_PIECES).

Run: CPU container, Godot 4.7 headless, one Godot at a time, run checkout detached at one SHA; fixtures are committed from a sparse side worktree as `tests/fixtures/earned_saves/f49_mt_<piece>/`. Driver: `tools/earned_saves/routes_kit/chain.sh` runner `et` (added 27b2406d).

## Log
- 2026-10-31 STARTED from origin/main a41e1b30. Godot 4.7 runs; disk 19 GB free. Import warming.
- 2026-10-31 21:45Z Owner direction via coordinator: do not reprove what is proven. Bridge starts from the committed earned `meadows_chain_ev_fights/camp_tournament` (opening_team-first lineage, eb8180ed) with `--pinned-start --historical-team-start` (818d2b5c). Focused tests on 818d2b5c: test_f49_training_prefix + test_altar_training_piece 14/102/0.
- 2026-10-31 21:59Z RUNNING chain on 818d2b5c: bridge → t1 loop → warrens → relay → t2 loop → sigils → hall → warden → tidewake_handoff (`~/rb/chain1.out`), autocommit each pass as `f49_mt_<piece>`.
