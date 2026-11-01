# WATERSKY lane (tb/vis-water-sky): Tidewake F39 + Cloudreach F40 scene/material/placement

## Group 3 (1 Nov; shared cause 2, the camera has no speaker): flag `data/config/water_npc_posts_candidate.json:enabled`

A sweep of all 39 Tidewake dialogue posts on CPU (with the posts candidate) shows two-shot push-ins at almost every post. The two failures were NPCs standing on terrain slopes, out of reach of the stand-beside logic:
- **Resident Nalia (P2-074, GPU 3.54):** her authored post sits about 13 m up Shellwatch's dune-passage wall. Reposted onto the measured passage floor (16.5 m, flat). Now she is in the post view and gets a full push-in in dialogue (CPU before/after checked).
- **Trainer Rune:** stood about 5 m down the Gull Rest plateau edge. Reposted onto the flat plateau (29.1–29.4 m). Dialogue now gets a full push-in two-shot (CPU before/after checked).
- Cloudreach dialogue sweep: every speaker already gets a push-in on main (P2-076's Kelm and Veyra frames show the speaker); no change needed. Three posts (healer_iven, bridgekeeper_orrin, courier_neri) find no capture stand; they are not in the judged set.
- Not fixed: Evi, Morra and Fennel read, but against dark Veilfall rock. Nerissa's post frame (the catalogue plan stands outside her interior) is a capture-plan issue, not a game one.

## Group 2 (1 Nov, rolling batches; coordinator: shared fixes first). All flags OFF; entries in MANIFEST.json with "group": 2

| Fix | Flag (set true) | CPU check |
|---|---|---|
| Tidewake light and atmosphere | `tidewake_look.json:watersky_light_candidate.enabled` | Day: warmer, lower key with longer modelling shadows on the dunes; cooler ambient; aerial fog; character rim 0.35. Sand stays pale (r2 raised ambient 0.9 → 1.0 and exposure to 0.78 after r1 greyed it). Night: more fill (ambient 0.26 → 0.5, exposure 0.88, moon 1.1); figures and dunes read. |
| Cloudreach light and atmosphere | `cloudreach_light_candidate.json:enabled` | Day only: warmer, lower key; cooler, lower ambient (1.9 → 1.6) so pale stone reads warm against cool shade; contrast/saturation; aerial fog; rim. r1's night block darkened the night lawn, so night stays as shipped. |
| Cloudreach ground-cover clustering | `cloudreach_ground_cluster.json:enabled` | Dry (straw-olive) and lush (deep green) turf patches from one field; grass tufts thin on the dry patches and gather on the lush ones. r2 halves the patch size (frequency 0.07) so a frame shows both kinds. |
| Tidewake ground-cover clustering | `water_ground_cover.json:watersky_cluster_candidate.enabled` | Tighter, denser bush/flower drifts on dune grass. Barely visible at First Shore; ride-along. |

Stands: every Tidewake/Cloudreach location, route and dialogue frame that the item judging covers (`ralph/reports/VISUAL/item-scores/job.json`), by tool frame name. Tests: 6 tests, 0 failed (`test_cloudreach_ground_cluster`, `test_cloudreach_paved_grass`, `test_cloudreach_monotonic_walls`).

## Group 1 summary (1 Nov 2026)

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
- `cloudreach_grounding.json:skip_grounded_cloud_cards` (stays OFF, **not in the batch**). It hides 45 cloud-ring cards, but the regression check (sky_shrine and realm_gate approach, before/after) loses the good cumulus banks behind the plateaus. Also, the owner-stand card it targeted is transparent where the roof showed; the roof was the shoulder shelf.
- `dune_grass_candidate`: strips the dune grass to bare sand, which is the P2-057 judges' complaint.
- `shore_surf_candidate`: no visible change at First Shore.

P2-026 stand check (drowned_garden_terraces route_day and walk_01_day, before/after `current_flow`): the dashed translucent lane strip across the shoal chain is gone. The disc chain itself remains: the rest shoals are baked terrain, so they are not fixed here. No regression.

Regression check (sky_shrine 07, realm_gate_crag, three_bells_bridge approach, every manifest Cloudreach flag on): no visible change from the shelf, wall, grounding or paving passes at those stands.

Tests (headless, `tests/run_tests.gd --only=test_cloudreach_monotonic_walls,test_cloudreach_paved_grass`): 4 tests, 0 failed.

Open after the batch verdict:
- P2-106 (terrace cloud puffs): no confident fix found.
- P2-057 (dark backlit figures on bare dunes): a lighting fix, out of this lane's scope.
- P2-090: the blob is likely a reef-stone gather node.
- P2-021 / P2-023 open terrain: needs new art (coordinator Meshy).
