# WATERSKY lane (tb/vis-water-sky): Tidewake F39 + Cloudreach F40 scene/material/placement

## Summary (1 Nov 2026, for the 18:00 UTC tb/vis-batch1 cutoff)

**Criteria closed: zero.** No GPU verdict yet. Every change is behind a flag that ships **OFF**. `MANIFEST.json` lists each item with its flag, camera set and stands. Per the coordinator's 1 Nov update there are no single-candidate READY lines.

Composition with other lanes: all flags are new keys in `data/config/cloudreach_grounding.json`, `data/config/tidewake_look.json` or `data/config/water_ground_cover.json`. Shared code is touched only where a flag reads:
- `cloudreach_world.gd`: the `_mesa` wall pushes (behaviour is unchanged when the flag is off);
- `grass_field.gd` / `grass_field.gdshader`: a feather uniform that defaults to 0;
- `water_world.gd`: a preview argument;
- `tidewake_look_profile.gd`: a sections switch;
- `cloudreach_look.gd`: two calls after the grounding pass.

tb/cloudreach-look's grounding pass is merged in as-is.

| Item(s) | Flag (set true) | CPU check (Low, llvmpipe), `_sheet_cpu_before_after.jpg` |
|---|---|---|
| Owner 31 Oct floating drums (P2-023): pieces sticking out of rock shoulders over meadows | `cloudreach_grounding.json:skip_floating_shelves` | **Row 1: the overhead "drum" at the owner stand is gone.** The shoulder wall now rises straight from the meadow. 102 pieces hidden realm-wide (wall shelves and rock outcrops 12 m or larger, hanging 3.2–45 m over walkable ground). |
| Owner floating drums: settlement cloud-ring cards standing on meadows | `cloudreach_grounding.json:skip_grounded_cloud_cards` | 45 cards hidden (150–300 m cumulus quads whose footprint meets walkable ground). Not visible at the owner stand. **Check the settlement and summit cloud-ring views (P2-021/P2-022) for thinning.** |
| Owner floating drums: drum bottoms and beacon plinths (from tb/cloudreach-look) | `cloudreach_grounding.json:enabled` | 277 seated, re-probe proof 0 failures. Costs about 6.6 s of CPU load. |
| Owner floating drums: cliff wall profile | `cloudreach_grounding.json:monotonic_walls` | Walls go top ≤ upper ≤ lower ≤ bottom (no bulge over a recess, no tuck under the crown). No visible change at the owner stand. Ride-along. |
| P2-025 grass through shrine paving | `cloudreach_grounding.json:clear_paved_grass` | **Row 4: all blades gone from the Sky Shrine dais.** 974 tufts cleared on level masonry/path box tops; the lawn is untouched. |
| P2-066, P2-067, P2-026 live currents read as road paint | `tidewake_look.json:watersky_sections_on` (brings the existing, never GPU-judged `current_flow` candidate into play) | **Rows 2–3: dashes, chevrons and rims gone.** In their place: broken bank seams, small wavelet caps, Meshy driftwood and spar buoys. |
| P2-008 hard grass carpet edge | `water_ground_cover.json:built_feather_enabled` | Small: blades thin out over 3 m beyond each clearing. Ride-along, not expected to gain 0.5 alone. |

How the owner stand was diagnosed: ray probes from `ownerdrum@16.5,4313.2@56`.
- The meadow there is the UpperPlateauCircuit route (y 849.7). It runs inside `Ridge003RockShoulder23`'s footprint, about 32 m under its crown.
- The "drum" overhead was that shoulder's 36 m `VegetatedGeologicalShelf0`, 8 m up, plus a 39 m rock outcrop 17 m up.
- The grounding pass skipped them because a road runs below, and a build-time skip could not see the road yet (routes register later). So the hide runs in the post-build grounding pass.

Tried and not included:
- `dune_grass_candidate`: strips the dune grass to bare sand, which is the P2-057 judges' complaint.
- `shore_surf_candidate`: no visible change at First Shore.

Tests (headless, `tests/run_tests.gd --only=test_cloudreach_monotonic_walls,test_cloudreach_paved_grass`): 4 tests, 0 failed.

Open after the batch verdict:
- P2-106 (terrace cloud puffs): no confident fix found.
- P2-057 (dark backlit figures on bare dunes): a lighting fix, out of this lane's scope.
- P2-090: the blob is likely a reef-stone gather node.
- P2-021 / P2-023 open terrain: needs new art (coordinator Meshy).
