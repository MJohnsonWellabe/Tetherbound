# Station 14 (ridge-camp-approach) — decision: **A. ROOT CAUSE FOUND + fix**

## Evidence
1. The camp exists and renders (all 15 props load from disk; `tools/_capture_locations.gd` "08-ridge-camp" frames its fire at 5 m). Props get Y from `playground_world.ground_height_at` = Terrain3DData.get_height, same as the trainer and signpost that DO render — no streaming/flag gating anywhere in `props.gd`/`playground_world.gd`.
2. Projecting every camp prop through the tool's own camera maths (fov 70, BACK 4.2, UP 2.4, 1280x720) from the current eye (-280,6460)/look (-242.7,6470.2): all props land at x 595–687, y 365–385 — a ~90x20 px patch at 41–48 m (tent 31x19 px, fire 28 px wide). It sits dead centre, directly behind the "Watchtower Spur" signpost (`terrain_playground.json` spokes, at (-278.05,6461.56) = 6 m from the camera, x≈585, spanning y 320–500) and just above the parked player's head (x≈660, y≈383). The dark blob behind the sign in round-6/7 PNGs at (600–640, 330–345) IS the tent. Nothing "fails to render"; the camp is 18 px tall and masked by the sign + player.
3. The 9.2/4.8/3.6 m `_surface()` variance is real but irrelevant to the miss: the ray never excludes bodies, and the tool PLACES the player at the very XZ it then queries (capsule top ≈ ground+2.2), plus Captain Vess's capsule at (-280,6460), prop BoxShape colliders, and flying galecrests (spawns 4010/4054). Even a 5 m error at 40 m is 7° of pitch inside a 70° FOV — it cannot push the camp out of frame.
4. No Godot probe was needed (godot pid 32469 was busy throughout); decided from code + the lane's PNGs + projection maths.

## Fix (one round, `tools/_capture_corridor.gd` only — no data changes)
1. **Re-site the stand to the camp clearing's trail-side edge** (line ~127, `STATIONS`):
   `["14-ridge-camp-approach", Vector2(-254.5, 6465.7), Vector2(-235.0, 6470.0)]`
   - eye = `vegetation.json clearings[order 4000]` centre (-241.8,6468.5) + its radius 13 m along the line to band4 pt14 (-280,6460): the last 13 m of the approach walk from the trail into the camp. Documented site coordinate, not eyeballed (same licence as stations 05/11/12).
   - look = `trainers.json patrol_ridgeline.position` (-235,6470), the Team Tether grunt posted at the camp. From this pair the props project at 15–22 m: tent 84x50 px at x≈488, fire 66 px at x≈546, crate/barrel pile x≈584–612, log seats x≈474/615, grunt 38 px tall at x≈640 above the player's head (player body x 603–677, y ≥ ~420). Captain Vess and the signpost are 26 m behind the camera, out of frame.
   - Update the header comment for 14 (lines ~104–109) to say this.
2. **Make `_surface()` use the bake, not a raycast** (line ~441): replace the body with
   `var h: Variant = _world.call("ground_height_at", at.x, at.y)`; `if h is float and not is_nan(h): return h`; otherwise fall through to the existing raycast, but add `query.exclude = [_player.get_rid()]` and reject hits whose collider is not `_under_terrain(...)` (re-query with that RID appended to `exclude`, up to 8 times) before returning. This removes the player/trainer/prop/galecrest hits that produced 9.2/4.8/3.6.
3. **Fix the proof coordinates** in `_proof_camp_in_fov` (line ~325): the props moved 7 m in round 7 but the proof still unprojects the OLD fire/tent. Use fire `(-240.73, 6472.18)`, tent `(-245.13, 6472.08)`, and add crate `(-243.43, 6469.68)`. Also print the tent's on-screen height: unproject `Vector3(x, ground, z)` and `Vector3(x, ground+1.5, z)` and print `abs(dy)` as `tent_px`.
4. Re-render with `--only=14-ridge-camp-approach` (xvfb, opengl3, no --headless), save to round8, paste the `[14 proof]` lines into REPORT.md, and replace the "STILL NOT FIXED" section with this diagnosis (camp was in frame at 18 px behind the signpost; not a height bug).

## Proof criterion (all three must hold)
- `[14 proof]` prints fire, tent and crate `inside_frame=true` with x in [400, 720] and y in [330, 450], and `tent_px >= 40`.
- Two consecutive `_surface(eye)` calls differ by < 0.2 m (print both once in `_shoot` for this station).
- The round-8 PNG, cropped 3x over x 420–760 / y 330–470, shows a tent, a fire ring/flame, the crate+barrel pile and the grunt in one clearing with the player at bottom centre; the "Watchtower Spur" sign and Captain Vess are NOT in frame.
