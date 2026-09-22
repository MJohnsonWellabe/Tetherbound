# D36 — Named map regions: a handful of large zones, not one per destination

**Date:** 2026-08-14 · **Decided by:** the owner, playtest pass — "name some
of the areas and uncover them like fortnite maps do," then a direct
correction once the first cut shipped: "we shouldn't have region labels
that close together. that should all just be Grandpa's village. look at a
fortnite map. the regions are much larger and the names aren't close."

## The decision

A named region is a large, named AREA of the Meadows — broader than a
`D33` landmark (a landmark is a single point of interest; a region is the
ground around a whole cluster of them) — discovered by the player physically
entering it, not by proximity. Entering an undiscovered region for the first
time shows a Fortnite-style location banner (top-centre, ~3.2s, one-shot —
see "What it is not" below) and permanently labels that area on the full map
screen. Regions, like landmarks, live in `data/config/map_landmarks.json`
and ride the same `MapState` (`D33`) — one map database, still.

Today's regions (`Grandpa's Village`, `The Pond`, `The Rise`) are few and
large on purpose. `Grandpa's Village` alone covers the entire starting
hub — the village square, Grandpa's house, and the practice meadow, all
genuinely part of the same place a new player spends their first minutes
in — rather than three separate regions for three destinations 15–35m
apart. The Pond and The Rise are 150m+ from the village and 230m from each
other: real, separate places a player walks TO, not names crowded into one
corner of the map.

## Why this shipped wrong once already

The first cut named the village square, Grandpa's house and the practice
meadow as three *separate* regions, because each already has its own
`display_name` on a real destination (`terrain_playground.json`'s own
`paths.routes[].label`) and treating "give a place a name" and "give a
route's endpoint a name" as the same operation was the easy default. It
technically worked — each fired its own banner, each got its own label —
but at the Meadows' map scale, three centres only 15–35m apart put three
names within a few pixels of each other on the full map, and they read as
overlapping clutter rather than geography. A collision-avoidance pass
(`tab_map.gd::_draw_region_label`) was added to keep any two labels that
land close from garbling into each other — it stays as a backstop for
whatever regions a later biome adds, but it was never the fix. The fix was
recognizing that "the village square," "Grandpa's house" and "the practice
meadow" are one place, not three, exactly the way a Fortnite map names
Tilted Towers once, not once per building inside it.

**The lesson, generalized:** a named region is a judgment call about what
counts as one place to a player standing in it, not a mechanical property
you can read off "does this destination already have a label string
somewhere." Every existing named destination becoming its own region was
the wrong default specifically because it skipped that judgment call.

## What it is not

- **Not a persistent HUD element.** The banner is read-and-cleared
  (`MapState::take_pending_region_announcement()`), fires once per region
  per save (discovery persists through save/load — `tests/test_map_state.gd`
  pins this), and auto-hides after `REGION_BANNER_SECONDS`. A player who has
  already found a region never sees its banner again, including after
  reloading.
- **Not a second database.** `MapState._region_defs`/`_discovered_regions`
  sit alongside the landmark and fog-grid state `D33` already put there.
  `regions()` hands both the minimap and the full map the same discovered
  set, the same "one mechanism answers the question" reasoning `D33`/`D09`
  already establish for everything else on the map.
- **Not proximity-based.** Like landmarks, entry is a real position check
  (`update_region`) against each region's authored centre/radius, run from
  `game_state.gd`'s own discovery tick — walking near a region's edge on a
  road that skirts past it does not discover it.

## What changes on disk

- `data/config/map_landmarks.json` — new top-level `regions` array:
  `{id, display_name, centre, radius}`. Three entries today; later biome
  bands add more the same way `D23`'s progression already adds landmarks.
- `autoload/map_state.gd` — `_region_defs`/`_discovered_regions`/
  `_current_region_id`/`_pending_region_announcement`, `update_region()`,
  `regions()`, `take_pending_region_announcement()`; persisted in
  `save_data()`/`load_data()` under a `"regions"` key.
- `autoload/game_state.gd` — `map.update_region(player.global_position)`
  runs alongside the existing `map.mark_visited(...)` call on the same
  throttled discovery tick.
- `scripts/ui/playground_hud.gd` — the banner: a plain outlined `Label`,
  same "legibility outline, no panel" call the objective block already
  makes, polled every frame the same read-and-clear way `_hotbar_message`
  already works.
- `scripts/ui/tab_map.gd` — region name labels drawn on the full map after
  the fog/icon passes, with the collision-avoidance backstop described
  above (8px real padding, not a hairline non-overlap — a render at 2px
  proved technically clear but still visually cramped).

## What it supersedes

The first-cut five-region layout (`village_square`, `grandpas_meadow`,
`practice_meadow`, `the_pond`, `the_rise`) — replaced by the three above
before it ever reached the owner as a finished feature to sign off on twice.
