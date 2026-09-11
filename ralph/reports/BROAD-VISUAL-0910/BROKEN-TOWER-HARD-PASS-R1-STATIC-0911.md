# The Broken Tower — hard-pass R1 static candidate

## Disposition

**HOLD for production proof.** The authoritative location regrade keeps The
Broken Tower at POLISH. Its accepted brick leaves, fallen wall and two wards
establish a ruin, but the southwest road view still compresses to one thin dark
slab. At standing distance there is no readable former-watch function inside,
the route threshold dissolves into grass, and the night frame is black masonry
around two oversized white lens discs.

This candidate is deliberately confined to `RuinedWatchtower`. No shared world
system, scatter, band config or global exposure changes.

## Candidate

- Add the installed castle-family `WallEntranceBricks.obj` as a 6.45m-wide,
  6.50m-high route arch. It is shorter than the two surviving 11.73m leaves,
  offset and turned three degrees so it broadens the lower silhouette without
  repairing the ruin into symmetry.
- Give only the arch's two piers collision. Their inner faces leave a measured
  3.75m opening; there is no front-span or lintel collider and the original
  player route through the shell remains open.
- Add a partial four-plank upper watch deck, two surviving ledgers and a broken
  seven-rung ladder. These are visual-only timber remnants above the route: they
  explain that this was a staffed road watch instead of three unrelated wall
  slabs without promising a new traversable floor.
- Add four irregular route flagstones, sampled individually against live terrain
  after applying the landmark yaw. They give the grass-heavy arrival a readable
  threshold and add no collision.
- Move the outer ward remnant onto the west route pier, reduce the interior and
  exterior lens radii from 0.27/0.21m to 0.17/0.14m, and reduce their emission
  multipliers from 2.1/2.6 to 1.35/1.45. A bounded 19m cone from the modeled
  outer lens now lights the route arch and chamber masonry rather than relying
  on two saturated white dots in a black silhouette.

Existing installed wall leaves, textured stone treatment, fallen wall, rubble,
30m wildlife exclusion, reward pickups and all shared lighting/vegetation remain
unchanged.

## Exact path scope and overlap

All owned paths were clean before editing and do not overlap current shared,
Cloudreach, config, generated-scatter, import or user-dirty work:

- `scripts/world/watchtower_landmark.gd`
- `tests/test_broken_tower_landmark.gd`
- `tools/capture_broken_tower_identity.gd` (new)
- this report

No production renderer, scatter bake or commit was run in this static lane.

## Static validation

The final Windows Godot 4.7 focused run is green:

```text
test_broken_tower_landmark.gd + test_ridgeline_watch.gd
13 tests, 190 assertions, 0 failed
```

This constructs the real landmark and pins installed/textured arch art, the
6.2–6.7m lower silhouette, 3.5m minimum route opening, pier-only collision,
watch deck/ladder identity, four terrain-fitted collisionless flagstones,
smaller emissive lenses, bounded facade lighting, unchanged open ruin, adjacent
Ridgeline Watch separation and the existing wildlife exclusion.

Both changed GDScript entry points pass `--check-only` individually, and
`git diff --check` is clean for the owned paths.

## Production proof required

`tools/capture_broken_tower_identity.gd` is a dedicated six-frame harness: real
Meadows production scene, ordinary player position, clear authored day/night,
70-degree camera and 5.2m third-person stand-off. It captures the 47m southwest
route arrival, 21m arched threshold and 10m watch-remnant view at both clocks.
HUD and feedback overlays are hidden; it injects no landmark, light, terrain,
vegetation, encounter or progress state.

Accept strict hard PASS only if fresh production frames show a wider asymmetric
ruin on the real road, an unmistakable open arch and former-watch interior,
grounded threshold stones, teal rather than white lens sources, readable night
masonry, no clipped/floating pieces, and no nearby pickup/vegetation stealing
the landmark hierarchy.
