# Stormwood F09 (WO-F09-01): in-engine visual evidence

These frames were captured by `tools/capture_stormwood_f09_pockets_roads.gd` in the
production `scenes/world/stormwood.tscn`. The runs used xvfb and opengl3 on llvmpipe at
1280x720, and the frames are JPG at quality 0.8.

- `after/` is branch `ralph/stormwood-f09-walkable-roads` @ 7edd51b5f. It has 28 frames.
  The per-frame records (player and camera position, prompt text, surge phase, reward
  node state, staged flags) are in `after/frames_after.json`.
- `before/` is the same tool on the same checkout, run for the road and forest groups
  only (8 frames). Before the run, these paths were checked out from `origin/main`
  (a0fde6d76):
  - `data/config/stormwood_world.json`
  - `stormwood_encounters.json`
  - `stormwood_pickups.json`
  - `stormwood_vegetation.json`
  - `data/scatter/stormwood/`
  - `scripts/world/stormwood_scatter.gd`
  - `scripts/world/stormwood_world.gd`

  They were restored with `git checkout HEAD -- <paths>` afterwards, and `git status`
  was clean. `stormwood_vegetation.json` had to be included: it feeds the scatter-bake
  fingerprint, so without it main's bake would read as stale and no forest would load.
  The pockets config and script stayed on disk, but main's `stormwood_world.gd` never
  loads them: the log shows `pockets node present: false`. Both runs log
  `scatter bake fresh: true`.
- Sheets:
  - `sheet_pockets_after.jpg`: 5 pockets × 4 views.
  - `sheet_roads_forest_before_after.jpg`: before and after, side by side, for items 2–4.

## Camera and state (every frame)

- **Camera.** The production player camera (`CameraRig/Camera3D`) follows the real
  trainer. There is no free camera and no survey stand. Placement matches
  `capture_stormwood_lane_evidence.gd`: one `Game.debug_teleport_to`, then the Player
  is set at the stand point facing the subject, and the rig gets its target, yaw and
  pitch and settles on its own. The camera sits 5.4–5.9 m behind the trainer. The
  `b2_reward` views orbit the rig 24° off the trainer's back.
- **Staged state.** Every frame is staged; none was earned by play.
  - The day clock is pinned to day.
  - The Surge clock is re-pinned to Calm (elapsed 60 s) before every frame.
  - The HUD is visible. It shows the fresh-save objective "Find Ashfoot Waycamp".
  - `rootgate_south_closed` has no progression flag. Every later frame has
    **`stormwood:rootgate_released` set by the tool**, which is needed for the
    Deepwood/Dynamo pockets and roads.
  - `Engine.max_physics_steps_per_frame` is raised to 20 during the waits so game time
    keeps moving under software GL.
- **No fights.** No frame is in a fight (`in_fight: false` for all).
- **Missing import.** Both runs log the same missing import:
  `Rocks_Diffuse_meadows.png` (.ctex absent from `.godot/imported`), used by harvest
  rock nodes. It is an environment cache gap, not an F09 change.

## 1. Pockets (after only; pockets do not exist on main)

Stands are derived from `data/config/stormwood_pockets.json`:

- **a:** 30 m out along the mouth axis from the mouth centre, which is the road side
  because the mouth faces the road.
- **b:** the mouth centre, facing the pocket centre.
- **b2:** 2 m from the moved pickup, facing it. The pickup prompt range is 2.4 m, so the
  prompt is out of range from the mouth (11.7–11.8 m).
- **c:** 7 m outside the outer face of the right-hand side wall, facing the pocket
  centre.

| Frame | What is visible |
|---|---|
| `pocket_verge_ash_hollow_a_approach` | A dense clump of giant dark dead trunks on open meadow. A big trunk on the left screens part of the mouth, but the reward's green glow shows through the gap at frame centre. A yellow creature stands on the right. |
| `pocket_verge_ash_hollow_b_mouth` | Two huge trunks frame a clear 5 m opening. Inside is a flowered clearing with the green reward glow at the back. Blue sky shows between trunks and branches at the back wall, above trunk-base height. |
| `pocket_verge_ash_hollow_b2_reward` | "Take Good Candy" prompt. The candy glow sits on the grass beside the trainer and is not floating. **Through the back wall the outside meadow and a creature are visible, between trunks at roughly 2–5 m height** (right of centre), and meadow also shows at upper left. |
| `pocket_verge_ash_hollow_c_side_wall` | Side wall reads as one continuous mass of dark trunks at ground level. A few specks of sky show through branch tangles high up. |
| `pocket_hollows_moss_nook_a_approach` | Grey dead-trunk clump on open ground. **A large mossy boulder stands just outside the mouth, left of centre, and screens the left half of the mouth** from this stand. The reward glow shows to its right. |
| `pocket_hollows_moss_nook_b_mouth` | Wide opening between two grey trunks, with the reward glow at the back. **Sky and meadow show through the back wall** left of the reward. |
| `pocket_hollows_moss_nook_b2_reward` | "Take Great Candy" prompt. The candy glow sits on the ground. **Meadow and horizon are visible between back-wall trunks at mid-height** (upper left, and centre-left). |
| `pocket_hollows_moss_nook_c_side_wall` | Solid grey trunk wall at ground level. One small sky gap between trunks around 3 m up, just left of centre. |
| `pocket_conductor_ridge_cleft_a_approach` | **A large scatter-tree trunk fills the right third of the frame beside the stand.** The pocket clump is visible behind the trainer, but the mouth is not readable. |
| `pocket_conductor_ridge_cleft_b_mouth` | Opening between two dark trunks, with the reward glow small at the back. Distant green shows through the back wall below the branch line. |
| `pocket_conductor_ridge_cleft_b2_reward` | "Take Great Candy" prompt, with the candy on the ground. **Three see-through gaps in the back wall** (left edge, centre, right of centre) show outside meadow and hills at 2–4 m height. |
| `pocket_conductor_ridge_cleft_c_side_wall` | Solid trunk wall at ground level. Only small branch-level specks of sky. |
| `pocket_deepwood_ridge_shelter_a_approach` | The pocket clump sits at the foot of a steep green hillside, with a leafy scatter tree just right of it. The mouth is not distinguishable at this distance. |
| `pocket_deepwood_ridge_shelter_b_mouth` | Opening between two trunks, with the pink Revive glow at the back. Green hillside shows faintly through the back wall. |
| `pocket_deepwood_ridge_shelter_b2_reward` | "Take Revive" prompt. The pink glow and plant sit on the ground. The hillside behind shows between back-wall trunks at the left edge and upper right. |
| `pocket_deepwood_ridge_shelter_c_side_wall` | Solid grey trunk wall with a large scatter trunk in the left foreground. No gap is visible at trunk height. |
| `pocket_dynamo_scorch_pen_a_approach` | The stand is on a steep slope below the pocket. The grey trunk clump is on the rise with leafy trees on both sides. The mouth is not readable. |
| `pocket_dynamo_scorch_pen_b_mouth` | Opening between two trunks, with the floor rising toward the reward glow. **Sky, and a purple creature outside the pocket, are visible through the back wall** upper-left of centre. |
| `pocket_dynamo_scorch_pen_b2_reward` | "Take Stoneguard Brew" prompt, with the pickup on the ground. **Sky and meadow show between back-wall trunks** at centre-top and right. |
| `pocket_dynamo_scorch_pen_c_side_wall` | Mostly solid dark trunk wall. There is one narrow bright gap between trunks around 2–3 m up, just right of the trainer. |

Every reward node was found and visible. Each sits 0.35 m above the terrain height at
its point, the same for all five.

## 2. Rerouted Rootgate approach (before and after)

| Frame | Stand | Before (main) | After (F09) |
|---|---|---|---|
| `rootgate_south_closed` | conductor_road (-650,3420) facing north to the gate (-650,3550), no flag | Narrow valley with steep bare green walls close on both sides. Two leafy trees in the middle. The closed Rootgate (bare grey dead trees) is at the far end. | Same valley, now lined with leafy trees on both sides that hide most of the green walls. The grey gate trees are at the end, and a blue-purple wolf-like creature lies beside the line of the road. |
| `rootgate_south_open` | same stand, `rootgate_released` staged | Same valley, gate trees gone, open sky at the end. | Gate gone. Two wolf-like creatures walk up the valley floor. |
| `rootgate_north_open` | deepwood_road (-650,3680) facing south | Valley floor with mossy rocks at the left and a steep green wall on the right. | Rocks gone. Taller leafy trees line both sides, and a small creature is in the distance. |

On main, (-650,3420) and (-650,3680) are off the road (conductor_road ran
(-1120,3290)→(-650,3550)). No distinct road surface is visible in either build; the
route reads only as the valley floor.

## 3. dynamo_west_approach (before and after)

| Frame | Stand | Before (main) | After (F09) |
|---|---|---|---|
| `dynamo_west_mid` | (-704,4813), 8 m back from the (-700,4820) vertex, facing (-480,5120) | Open grassland with scattered trees. A grey stone rod-station tower on a hill with glass shards is the clear focal point. | More trees line the line of the road. The tower is mostly hidden behind a tree, and only its faint top shows. No road surface is visible. |
| `dynamo_west_ember_arrival` | (-168,5232), 30 m before Ember Bivouac (-140,5242) on the last leg, facing the camp | Two huge dark trunks block the centre and right of the view, and two wolves are on the slope. | Trunks gone. There is an open slope with mushrooms and bushes, an orange-roofed cottage on the rise, wolves, and a large grey trunk at the right edge. **No Ember Bivouac tent or fire can be identified in the frame** in either build. |

## 4. Re-planted forest (before and after)

| Frame | Stand | Before (main) | After (F09) |
|---|---|---|---|
| `forest_ash_road_1060` | ash_road (-593,1055) facing (-380,1400) | Avenue of leafy trees. **A mossy boulder sits on the line of the road** straight ahead. | Similar avenue, with no boulder on the road line and a clearer view down the road. |
| `forest_hollows_ash_road` | ash_road through Glowmoss Hollows (-536,1514) facing (-900,1780) | Leafy trees on both sides, with a leafy moss creature ahead. | Denser, more tunnel-like avenue. A green moss lizard stands beside the trainer. |
| `forest_deepwood_matrix_stand` | (-470,3905), the earlier lane tool's `matrix_forest_day` stand | Matches the earlier frame: two bears, a cottage, and a dark trunk on the left. | Same cottage and one bear. A large dark trunk fills the left, with a fern in front and a bush on the right. The composition is close to before. |

## Defects seen

- **See-through palisade gaps.** In all five pockets, the back wall seen from inside
  (the b2 frames, and b for verge, hollows and dynamo) shows the outside meadow, sky
  and even creatures between trunks at about 2–5 m height. At the base the trunks
  mostly touch. The side walls seen from outside (c) read as solid at trunk height,
  with only small gaps: in hollows and dynamo, a bright gap at 2–3 m. The collider is
  a solid box, so these gaps can be seen through but not walked through.
- **The palisade does not read as a palisade.** At `TRUNK_SCALE` 2.2 the DeadTree
  models are giant multi-metre trunks with wide branch crowns. Each pocket reads as a
  dense grove of huge dead trees, not a built wall.
- **The mouth is not readable from the road-side approach** in conductor
  (a scatter trunk beside the stand), deepwood and dynamo (distance and slope). In
  hollows, a mossy boulder just outside the mouth screens half of it. Only verge shows
  the reward glow through the mouth from 30 m.
- **Pockets are not blocked by trees.** No scatter tree or rock stands inside any
  pocket.
- **Ember Bivouac is not identifiable** from 30 m on the new road's last leg.
- **No floating or buried objects** were seen. The pickups sit on the ground, and the
  trainer is grounded in every frame.
- **No visible road surface.** The rerouted legs and `dynamo_west_approach` are
  visually indistinguishable from the surrounding grass in these views.
- `wo03_after/` (WO-F09-03, branch `ralph/stormwood-f09-pocket-spurs`): the same tool's `spurs` group. It holds one frame per pocket from its joined road 18 m before the spur junction, facing 30 m up the spur, plus one mid-spur frame (Verge), with records in `frames_wo03.json`. The sheet is `sheet_wo03_spurs.jpg`.
