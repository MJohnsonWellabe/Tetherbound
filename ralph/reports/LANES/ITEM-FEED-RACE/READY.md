STATUS: ready (land; multiplayer bug fix)
BRANCH: tb/item-feed-race
HEAD: see git log

# Guest feast-feed race (LANE-MESHY, 9 Nov)

- Symptom (CI PR #867, smoke_net_f48_coop_loop feast step): the guest cooked (dish +1) but `f28_feed` found no enabled "Pup · " button, so no feed, cap stayed 10, 0 feast_feed receipts.
- Cause: scripts/masters/breakthrough_panel.gd built the guest's feed list from the personal view it had at that moment, which can predate the cook that just settled (the dish not yet in the guest's inventory), so the Pup row had nothing to feed. `view_arrived()` only rebuilt a list built with NO view, so the newer post-cook view never refreshed it. The separate `owner_passive_checkpoint_pending` -> ok sequence on the press is the panel's existing retry and was already handled.
- Fix: the panel records a key (sha256 of the view) for the view it built from; `view_arrived()` now also rebuilds when the arriving view differs, and never mid-action, for a closed panel or for an identical view (no loop; shown buttons kept).
- New test: tests/test_breakthrough_panel_view_refresh.gd (identical view keeps the list; a newer view rebuilds once; pending action and hidden panel never rebuild; a list built without a view still rebuilds).
- Checks: tests grepping f28_feed / feast / breakthrough_panel / view_arrived + the new test: 184 tests, 0 failed. Net smokes, each `GODOT_BIN=/usr/local/bin/godot tools/net/run_net_smoke.sh <name>`: f48_coop_loop x3 ALL CHECKS PASSED (run 1, 2, 3); f28_feast ALL CHECKS PASSED; f48_feast_feed ALL CHECKS PASSED. The smokes were not changed.
