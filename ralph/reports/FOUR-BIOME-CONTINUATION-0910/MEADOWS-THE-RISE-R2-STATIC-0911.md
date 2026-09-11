# Meadows named location — The Rise R2 static candidate (2026-09-11)

## Disposition

**STATIC CANDIDATE; production visual proof pending.** The accepted wide approach
already has a strong rocky landform, but the ordinary road-end view is dominated
by the identity pass's own oversized foreground stones. They turn into near-black
walls at night and hide most of the singular wind-shaped tree they were meant to
frame. This candidate corrects that authored cluster rather than thinning shared
scatter or changing the road, terrain, camera or night curve.

## Bounded change

- Keeps exactly one `TwistedTree_3` and three distinct `Rock_Medium_*` models.
- Moves the tree only 1.6m uphill inside its existing r12 clearing and grows it
  from 1.14 to 1.34 so its trunk/canopy survive the closer gameplay view.
- Re-seats all three rocks farther uphill and reduces the largest from
  `[2.05,2.65,1.75]` to `[1.25,1.55,1.10]`; the other two follow the same
  descending scale ladder. All remain within 8m of the tree, at least 23m from
  the road-end stand, inside the named region and at least 18m off both roads.
- Retains the installed nature family, warm leaf treatment, location name,
  trailhead sign, terrain, Stronghold approach, collisions, props outside this
  four-piece cluster, creatures, gatherables and all gameplay.
- Adds a dedicated non-overwriting eight-frame day/night harness: wide route
  arrival, crown-focused road end, matched canonical region stand, and west-foot
  profile.

## Exact scope and overlap

- `data/config/bands/band1_lower_meadows/props.json` — order 1052 only
- `tests/test_rise_visual_identity.gd`
- `tools/capture_the_rise_identity.gd`
- this report

All target paths were clean before editing. Shared Band 1 vegetation, canonical
generated scatter, terrain, landmarks, route data, assets and other location
sources are untouched.

## Acceptance still required

- Focused identity suite passed first-attempt after the complete candidate:
  **4 tests / 49 assertions / 0 failed**.
- Godot 4.7 `--check-only` passed for the focused test and new capture harness;
  `git diff --check` also passed.
- Coordinated real Compatibility-renderer capture must produce 8/8 valid R2
  frames without regenerating scatter.
- Independent review must verify that the tree now owns the composition, the
  smaller stones still anchor it to the rise, the canonical road-end view has
  usable negative space, and day/night frames do not reveal floating pieces or
  a new obstruction.

Until those receipts exist, The Rise remains **POLISH**, not hard PASS.
