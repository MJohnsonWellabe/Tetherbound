# Stronghold Approach identity pass — 2026-09-11

## Outcome

Stronghold Approach moves from **POLISH to POLISH (materially improved)**. The
real Band 5 spine now has three authored occupation reads instead of low supply
piles disappearing in a broad field: Corr's outer-watch muster, the road-drop
signal, and a paired gateward threshold. Repeated oxblood standards connect
those beats to the occupied Hall; one warm signal fire carries the sequence at
night. The Hall interior and Hall construction were not changed.

This is not yet an honest PASS. The production arrival still reads first as a
long pylon run across a broad meadow, and the Hall remains a relatively small
silhouette at the full 560 m arrival distance. The sequential road views are
substantially more authored, but they do not turn that far-arrival frame into a
commercial hero shot.

## Authored change

- `outer_watch_cache`: one 3.1x Hall-family oxblood standard and a working
  wagon make the first low cache read as an occupied muster post.
- `road_watch_drop`: one repeated standard plus a small warm signal basket
  turn the middle supply pile into a visible day/night waypoint.
- `gateward_processional_threshold`: paired 3.3x standards, short fence wings
  and grounded supplies frame the final road bend without closing it.
- Three local canopy-scale clearing masks protect those compositions; ground
  grass and flowers remain under the clearing system's existing rules.
- Every new prop collider is at least 5 m from the production Band 5 spine.

## Production evidence

Dedicated script: `tools/capture_stronghold_approach_identity.gd` (production
`meadows_playground.tscn`, ordinary Terrain3D/scatter/props/encounters/player/
HUD, clear weather, production 70-degree third-person camera; no progress or
encounter injection).

- `01-arrival-day.png`, `02-arrival-night.png`: complete named-place arrival
  and Hall destination silhouette.
- `03-outer-watch-day.png`: foreground muster occupation on the first real
  road leg.
- `04-road-drop-day.png`, `05-road-drop-night.png`: the repeated mid-ground
  standard and signal fire.
- `06-gateward-day.png`, `07-gateward-night.png`: Sigil-gate-to-Hall sequence
  and paired final threshold.
- `manifest.json`: exact positions, distances and capture disclosure.

## Validation

- `tests/test_stronghold_approach_visual_identity.gd`: **4 tests, 61
  assertions, 0 failed**. Pins three ordered beats, installed assets, oxblood
  reservation, warm signal treatment, local clearing radii, and >=5 m
  centreline clearance.
- `tests/test_band_content.gd`: **6 tests, 1,429 assertions, 0 failed**. The
  split-band merge remains complete, ordered and collision-free.

## Incidental defects visible in evidence

1. The full-distance Hall silhouette is still too small and horizontally thin
   to dominate the 560 m arrival frame; solving that belongs to Hall exterior
   massing or an authored overlook, not more roadside clutter.
2. A large live pylon can dominate an incautiously straight camera line across
   the road's bends. The dedicated evidence follows the actual route, but
   ordinary free camera can still produce this obstruction.
3. The HUD clock remains `00:00` while `WorldLook.apply_time()` correctly pins
   the requested day/night visual preset. This is capture telemetry/UI state,
   not evidence that the two lighting frames are identical.
4. Random wildlife can crowd the gateward view. No spawn was deleted or moved
   for a prettier frame; that ecology/gameplay remains production-authentic.

## Fastest remaining closure

Author one deliberate overlook/crest on the final third of Band 5 where the
existing road, gate and Hall align, then frame and test that arrival. If the
Hall must dominate from the canonical 560 m entry itself, its exterior crown
needs a wider/taller silhouette pass; roadside props alone cannot honestly
solve angular size at that distance.
