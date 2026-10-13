# Meadows warrens on tb/ev-routes via the light cut: FAIL, guardian/wild action refusals (routes, Tue 13 Oct 2026, CT)
Input: Fights' earned bridge save (tests/fixtures/earned_saves/meadows_chain_ev_fights/bridge, producer eb8180edb).
Light cut eb8180edb → 700a77bc0 accepted by the runner's own check: the only touched piece path is the Stormwood-only director, which is foreign to Meadows (light_cut_warrens.json).
Consumer 700a77bc0 = tb/ev-routes with df513bbdb merged: Fights combat up to eb8180edb, without the arena slide (e8a2f63a6). 13:15–13:45 CT, 1778 s.

- Quarry: 7 rootstone stops; spike bypass; two wild wins (10 and 15 hits).
- Then `[session] research_event duty … held: journaled; awaiting publish` (never released). Immediately after it, 147× `[encounter] refused: ()` (empty verdict). The next wild fight landed 0 hits in 7200 frames.
  FAIL "Real wild combat did not win with landed strikes" (foe L14; party L6–9).
- **So the empty-verdict refusal reproduces without Fights' arena-slide change.**
  It follows a research_event duty that stays held; F49-0/HOME_KEY_STALL.md shows the same never-released research hold.
Context: warrens_light_r1_refusal_context.txt; filtered log: warrens_light_r1.log.gz.
