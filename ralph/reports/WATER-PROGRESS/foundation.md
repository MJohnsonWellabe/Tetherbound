# Water foundation evidence — 2026-09-06

Base: `e78f2ab45f5d22bbf2ffcbb0394bd5b17b99f779`. Owner-reference PR68 merged; `88840b47a4d16165c2347753bb36f65b59fa8e4e` is an ancestor of this Water branch. Worktree: `D:/Tetherbound-source/.worktrees/water`.

## Implemented but not a playable chapter

Pure personal Skills model: five skills, hidden early XP, later-realm reveal, configured caps/benefits, complete-tier Candy preserving within-level fraction, tolerant save data. Inventory consumption, activity attribution, save integration and menu visibility are pending.

Pure owned swimming state: human/mount/combat modes, partial-frame exhaustion damage, safe landing state, remote snapshots with sender/revision/type validation. Existing trainer proxy, actual movement, mounts and saves are not wired yet. Current field shares deterministic flow sampling for future physics and visuals; this is not real-peer runtime evidence.

Terrain heightfield: twelve islands, exact shoreline and landing sectors, sparse region coverage. First bake failed because 256-metre regions reached the Terrain3D region-map boundary. A second attempt exposed that `region_size` writes before node initialization silently keep the default. A tiny isolated probe proved the remedy: set after entering the tree, read back, then import. The bake now uses 512-metre regions at one-metre vertex spacing, 30 sparse regions, and rejects failed imports before per-pixel writes. A later scene/bake lane will ship those artifacts with readback evidence. No visual acceptance has occurred.

## Validation

Focused invocation: Godot 4.7 `--headless --path D:/Tetherbound-source/.worktrees/water --log-file <explicit-log> --script tests/run_tests.gd -- --only=player_skills,water_heightfield,water_current_field,swim_state`.

Initial combined result: 28 tests, 4,181 assertions, zero failures. Additional malformed network-scalar rejection checks followed. Full regression suite is pending, using a local untracked `override.cfg`; verified user directory is `C:/Users/mattj/AppData/Roaming/Tetherbound-Water-0906-Tests`, isolated from the concurrent Stormwood run. No full-suite pass or code-CI result is claimed here.

## Authored data census, runtime actuals zero

12 islands; 6 regions; 18 landmarks; 24 shore anchors plus one independent 60-metre First Shore lesson; 11 inter-island edges with 22 alternatives/current strips; 12 land spines, 4 loops, 3 shortcuts, 8 reserved reward pockets. Land planning polylines total 11,686.171 metres, ungraded; sheltered inter-island water polylines total 3,231.815 metres. Reserved pockets are not pickups.

12 species records, five explicitly compatible swim mounts; 18 NPCs, 24 trainers (12 critical/12 optional), 111 conversations, 168 dialogue entries. None is runtime-instantiated yet. Concrete encounter/pickup/harvest/crafting integration remains future work.

Independent crossing audit found Sirenseal's original 155 stamina left inadequate final-crossing reserve. Capacity is now 180, preserving its faster, shorter-endurance role. The 698.472-metre sheltered crossing at Swimming 10 leaves approximately 19.553% Sirenseal reserve. All five mounts now appear in the safety table. These are analytic budgets, not measured player crossings.

## Score

No player-facing Water subpath is proven on merged main. Score remains 0/100 until runtime and merge evidence earns credit. First checkpoint remains 2026-09-06 23:55:38 UTC; permissions troubleshooting does not reset the clock.
