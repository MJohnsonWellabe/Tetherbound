STATUS: land

Bug fix: Stormward Overlook blank banner pane and white beacon ball (`pane_fix_1112`, ON).
Files: `scripts/world/cloudreach_stormward_overlook.gd`, `data/config/cloudreach_stormward_overlook_visual.json`, `tests/test_overlook_pane_fix.gd`, this report folder. Nothing else from tb/below6.
Checks: `--only=overlook` 7 tests, 0 failed. CPU before/after in `_sheet_before_after.jpg`. No GPU verdict yet: landed as a bug fix on the coordinator's instruction; a GPU re-score of the overlook route frames should follow.
