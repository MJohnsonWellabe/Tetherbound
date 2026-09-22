# D72 — gathered things stay gone everywhere, and starters stay exclusive everywhere

**Date:** 2026-09-03 · **Decided by:** direct implementation, per owner directive.
**Source:** `docs/owner/OWNER_PLAYTEST_2026-09-03.md`, findings 5 and 10.

## The decisions

**1. A gathered thing never comes back, including the tutorial's own hand-placed
nodes.** Owner, verbatim: *"When you gather something it shouldn't come back.
A bush, a tree, a stone. It should be gone. Same for potions and so on."*

`vegetation.gd`'s own trees and rocks already worked this way (D60/D67:
`harvest_permanently()`, replayed from a saved bitset on load) and so did every
other one-time pickup in the game (`key_pickup.gd`, `item_cache_pickup.gd`,
`tm_pickup.gd`, each a `progression` flag checked in `setup()`). The one
holdout was `harvest_node.gd` — the dozen-ish hand-placed tutorial spots from
`data/config/bands/<band>/harvest.json` (wood, stone, fiber, berries, and the
band-4 ironwood/rootstone deposits, including a `potion_large` node in Band 1)
— which D67 explicitly scoped out ("it does not touch `harvest_node.gd`'s ~10
authored tutorial spots, which keep their single-step gather-and-respawn
behaviour unchanged") on a 60-second timer. It is now the same shape as the
other three one-time pickups: a `progression` flag keyed `harvest_node:<id>`,
checked in `setup()` (so an already-gathered node deactivates itself the
moment the scene builds it) and replayed on a mid-session load through the
existing `progression_restore` group (`autoload/game_state.gd::load_game()`),
which `key_pickup.gd`/`item_cache_pickup.gd`/`tm_pickup.gd` already answer.

The id is derived, not assigned by a caller: an authored band node carries
`order` (`band_content.gd`'s merge enforces it globally unique), used as
`order:<n>`; a caller with no `order` — `burrow_warrens.gd`'s hand-placed
deposits, this file's own tests — falls back to `<item>@<at>`, which is exactly
as stable for a fixed, hand-authored spec. No save-format version bump: the
flag lives in `autoload/progression_state.gd`'s existing flat store, which
`scripts/save/save_game.gd` has persisted since VERSION 3 (SB9). Adding more
flag ids to an already-generic store is not a format change.

`_respawn_left` stays declared, always `0.0`, rather than being deleted: two
test helpers outside this lane's ownership
(`tests/helpers/gate_a_material_route.gd::_is_unspent()`,
`tests/helpers/gate_a_npc_gather_segment.gd::_nearest_authored_node()`) read
it with `node.get("_respawn_left")` and `float()` that result, which errors
outright on a field that no longer exists (`float(null)` is a runtime error,
not a coercion to `0.0` — checked directly). A gathered node is freed outright
now, so those callers' own `is_inside_tree()` / prompt-enabled checks already
exclude it without ever reading the dead field again.

**2. No starter may appear anywhere else in the game.** Owner, verbatim: *"No
one else in the game should have any of the starters."* `terrapup` (Ground),
`ripplet` (Water) and `galewisp` (Air) — `data/config/opening.json`'s
`starters.species` — are meant to be unique to the player's own opening
choice; the other two stay with Grandpa, and nothing else should be able to
hand one out. `terrapup` and `galewisp` had leaked into six trainer-team
entries across three bands (Oskar's two Band 1 fights, Pell's Band 2 warrens
picket, Orrin's and Officer Dell's Band 3 relay-site fights) — nobody had
checked the *authored trainer rosters* against this rule, only the wild spawn
tables (already clean: `test_spawns_data.gd`'s
`test_starter_species_never_spawn_in_the_ordinary_wild_population` and
`test_spawn_tables.gd`'s `test_no_starter_species_can_be_rolled` predate this
item and already passed). `ripplet` never leaked anywhere. `data/config/trade.json`
(Mira's goods, Oskar's creature swaps) and `data/config/burrow_warrens.json`
(its own residents and guardian) were already clean.

Each occurrence was replaced with the nearest non-starter of the same type
already used in that same band file, at the closest authored level, never
duplicating a species already in the same trainer's own team:

| Band | Trainer | Level | Was | Now |
|---|---|---|---|---|
| 1 | Oskar (first fight) | 6 | terrapup | meadowhart (exact level match) |
| 1 | Oskar (tournament final) | 10 | terrapup | mudsnout (exact level match) |
| 2 | Pell (warrens picket) | 10 | terrapup | bramblebun |
| 2 | Pell (warrens picket) | 11 | galewisp | duskhush |
| 3 | Orrin (relay site) | 9 | terrapup | burrowback |
| 3 | Officer Dell (relay site) | 10 | galewisp | galecrest |

None of these swaps touch a trainer's team *size*, level curve, or the
Ground/Water/Air composition any `_why_team` comment already argued for
(Pell's team is still "Ground, Ground, Air" — see that file's own comment,
untouched because it never named a species).

## Verification

`tests/test_harvest.gd` (extended): `flag_id()`/`was_taken()` are pure and
parameterized the same way `test_item_cache_pickup.gd` already proves for
`item_cache_pickup.gd`; `setup()` derives a stable id from `order` when
present and falls back to `<item>@<at>` when absent; `restore_progression_from_game()`
deactivates a node whose flag is already set and leaves an ungathered one
alone; `setup()` itself leaves a fresh node active with no Game autoload
present (the same "resolves to null, stays cautious" contract every other
one-time pickup already has). The old respawn-timer test is gone — there is
no timer left to prove.

`tests/test_starters_are_exclusive.gd` (new): reads `trainers.json`,
`spawns.json` and `spawn_tables.json` through the real band-merge
(`band_content.gd`), plus `trade.json` and `burrow_warrens.json` directly, and
fails if a starter id appears anywhere a `"species"` key can name one —
individually per table, and once more as a single recursive sweep across all
of them together, so a new authoring mistake in any shape is caught by the
same test rather than needing a new one written for it. Also pins
`opening.json`'s own starter list against what this test expects, so the two
can never quietly drift apart.

## What this does not do

- It does not change catching, the opening's own starter-choice flow, or
  anything about `scripts/ui/starter_picker.gd`.
- It does not touch `vegetation.gd`'s own permanence (D60/D67) or the other
  three one-time-pickup scripts — all three already worked this way and are
  unchanged; this item only closes the one gap D67 named and left open.
- It does not add a berry-farm exception: `farm_plot.gd`'s plots are the
  player's own planted crop, share `harvest_logic.gd::GROUP` for till/sow/pick
  only, and stay renewable on purpose — nothing here touches them.
- It does not re-balance the economy. A separate count of Band 1's reachable
  wood/stone/fiber sources against the tent/campfire/bedroll/house/tools
  recipe costs is recorded in the same session's completion report, not here.
