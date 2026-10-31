# Tidewake look lane: decluttered beach scenes (tb/tidewake-look)

Owner feedback, 31 Oct 2026: "The locations in tidewake look bad. They're just too cluttered. ... Have a beach bar, beach huts, different assets to make the beach scenes look better."

Goal: each of the 22 non-Veilfall Tidewake named locations reads as one clean, composed beach scene around one Meshy focal piece (hut, bar, fishing shack, market stall, lookout tower, canoe rack). Declutter competing props; keep route, collisions, gameplay objects, NPC posts, pickups and harvest nodes.

Rows served: F39#30, F39#32, P2-008, P2-011, P2-009, P2-026, P2-057; F13#5 (inhabited docks).

## Handoff (31 Oct 2026, late evening CT)

**State**
- `tb/tidewake-look` carries three OFF sections in `data/config/tidewake_look.json`:
  - `beach_scene_candidate`: one focal piece per site, with clearings.
  - `beach_declutter_candidate`: dock hamlets slimmed to two huts and four working props.
  - `beach_groups_candidate`: a two-to-three building hamlet per site.
- Loader changes:
  - `scripts/world/water_landmark_models.gd`: `grass_clear_m`, model-less clearings, the groups section and declutter drops.
  - `scripts/world/water_dock_dressing.gd`: the declutter merge.
- The Meshy 1031 set is imported.
- Tests: `test_tidewake_look_profile` and `test_water_landmark_destinations` pass (8 tests, 283 assertions, 0 failed).
- **GPU:** TW-look-2 is the live request (`tb/tidewake-2-on` 773118e1f, nine islands, +0.79 CPU on them). TW-look-1 is superseded.

**Open candidates**
- After the TW-look-2 capture, three small fixes landed:
  - Salt Crown shrine hut lowered.
  - Cropped Salt Crown bell-site hamlet removed.
  - Drowned Garden beach second hut restored.
  
  Each is under 0.5 on its own; they ride along with the next arm.
- **Parked by the stop rule** (two rounds under +0.5):
  - Brine Steps: +0.13, +0.16.
  - Shellwatch: -0.16, +0.35. The dock pump station fills the close view, and it is a dock action station.

  New idea needed. The likely one is to keep main's cottages there and trim only the prop litter; it was not run, because its expected gain is under 0.5.
- Veilfall is untouched (HERO-3, GPU lane).

**What worked**
- Focal pieces about 6 m past the spot, beside the route line.
- Clearings in front of the approach stand.
- Two-to-three building hamlets.
- Judges consistently reward "a hut cluster at the named location" and penalise lone huts on slopes.

**What didn't**
- Pieces 12 m out vanish behind dunes.
- Canoe racks read as white bones on CPU.
- Driftwood and shrub groups are invisible at stand distance.

**What still caps every island at about 6 (outside this lane)**
- Flat pale sand with no value variation.
- Untextured near-black dune faces.
- Grass as even carpets instead of grouped edges.
- No sea haze.

## Status (31 Oct, ~5 PM CT)
- Meshy 1031 set imported on this branch (textures mode 2).
- Two OFF sections in `data/config/tidewake_look.json`:
  - `beach_scene_candidate`: one focal piece per site, with clearings.
  - `beach_declutter_candidate`: dock hamlets slimmed to two beach huts and a few working props.
- `test_tidewake_look_profile` and `test_water_landmark_destinations` pass (8 tests, 280 assertions, 0 failed).
- **GPU arms requested** (see GPU-PASS/NOTE.md):
  - TW-look-1 (`tb/tidewake-1-on`): superseded.
  - **TW-look-2** (`tb/tidewake-2-on` 773118e1f): full stack, nine islands, +0.79 CPU mapped on those islands.

## Rounds (mapped CPU Bar A, three code-blind judges, standard prompt and anchors)

| Round | Arm | Main | Arm | Delta | Notes |
|---|---|---|---|---|---|
| r1 | s2 (scene + declutter) | 5.59 | 6.03 | +0.45 | 10/11 islands up. Gull Rest +0.88, Salt Crown +0.75, Tidal Cradle +0.65, Drowned Garden +0.56, Lantern Cove +0.52, First Shore +0.49. Shellwatch -0.16. `r1/VERDICT.md` |
| r2 | hamlet (`beach_groups_candidate`) vs s2 | 5.21 | 5.51 | +0.30 | Sluice +0.65; the other 10 islands under +0.5 (their first sub-0.5 round). Canoe racks dropped (they read as bones). `r2/VERDICT.md` |
| r3 | full stack vs main (direct) | 5.11 | 5.79 | **+0.68** | 9/11 islands at or above +0.59. Brine Steps +0.32, Shellwatch -0.09. **GPU arm TW-look-2** (`tb/tidewake-2-on` 773118e1f), supersedes TW-look-1. `r3/VERDICT.md` |

## How (runbook for this lane; reuses TECHNICAL §8.1)
- **Capture:** `phase2_capture_locations.gd --biome=water --times=day --views=approach,close --seed=2042`, one `--subset=water__<band>__<nn>` per site, `--tidewake-look-sections=...` for the arm, under xvfb at 1280x720. About 25 min for 22 sites.
- **Placement:**
  - Read the capture manifest's `target_position_xz` and `view_heading_xz`.
  - Each piece goes at spot + heading*d + right*l, where right = (-hz, hx). l > 0 shows on screen right.
  - Yaw faces the camera, plus or minus 25 degrees.
  - Pieces about 6 m past the spot frame well in both views. At 12 m they vanish behind dunes in the approach view.
- **Clearings:** `grass_clear_m` on a spec, or a model-less spec, puts a node in grass_field's `grass_clear` group. That clears the grass, the cover tier and the pebble field.
- **Judge sets:** one set per island, a 2x2 of its two sites (approach | close).
- **Pitfall:** `pgrep -f`/`kill` on a pattern that matches your own shell kills it (exit 144). Kill by PID.
