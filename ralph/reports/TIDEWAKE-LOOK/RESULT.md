# Tidewake look lane: decluttered beach scenes (tb/tidewake-look)

Owner feedback, 31 Oct 2026: "The locations in tidewake look bad. They're just too cluttered. ... Have a beach bar, beach huts, different assets to make the beach scenes look better."

Goal: each of the 22 non-Veilfall Tidewake named locations reads as one clean, composed beach scene around one Meshy focal piece (hut, bar, fishing shack, market stall, lookout tower, canoe rack). Declutter competing props; keep route, collisions, gameplay objects, NPC posts, pickups and harvest nodes.

Rows served: F39#30, F39#32, P2-008, P2-011, P2-009, P2-026, P2-057; F13#5 (inhabited docks).

## Status (31 Oct, ~5 PM CT)
- Meshy 1031 set imported on this branch (textures mode 2).
- Two OFF sections in `data/config/tidewake_look.json`:
  - `beach_scene_candidate`: one focal piece per site, with clearings.
  - `beach_declutter_candidate`: dock hamlets slimmed to two beach huts and a few working props.
- `test_tidewake_look_profile` and `test_water_landmark_destinations` pass (8 tests, 280 assertions, 0 failed).
- **GPU arm requested:** TW-look-1, `tb/tidewake-1-on` 29ca0d23b. Six islands at +0.64 CPU mapped. See GPU-PASS/NOTE.md.

## Rounds (mapped CPU Bar A, three code-blind judges, standard prompt and anchors)

| Round | Arm | Main | Arm | Delta | Notes |
|---|---|---|---|---|---|
| r1 | s2 (scene + declutter) | 5.59 | 6.03 | +0.45 | 10/11 islands up. Gull Rest +0.88, Salt Crown +0.75, Tidal Cradle +0.65, Drowned Garden +0.56, Lantern Cove +0.52, First Shore +0.49. Shellwatch -0.16. `r1/VERDICT.md` |

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
