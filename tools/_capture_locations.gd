extends SceneTree

## THE LOCATIONS PASS. One survey that photographs the game's PLACES -- the
## village, the quarry, the Burrow Warrens, the Tether Relay, the mill sites,
## the Upper Meadows camps, the Stronghold -- rather than the route between
## them or the prefabs they are built from.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_locations.gd [-- --only=<site>]
##
## NEVER with `--headless` and a real rendering driver: that combination hangs
## forever with no error (docs/AGENT_WORKFLOW.md, "Art pipeline traps").
##
## WHY THIS TOOL EXISTS, given two surveys already shoot this world.
## `_probe_corridor_survey.gd` shoots the travel corridor: points on a route,
## chosen to answer "does the journey read as one place". `_capture_structures
## .gd` shoots prefabs: one building on a bare stage, chosen to answer "is this
## model good". Neither answers the question a player actually asks on arrival
## -- *is this somewhere I want to be* -- because that question is about a site
## WITH its props, its NPCs and its creatures around it, seen from the angles
## arrival and standing put you at. A place photographed from the road is a
## landmark; a place photographed on a turntable is an asset. This shoots
## neither.
##
## So every site gets three eyes, and they are three different questions:
##
##   approach  -- does it announce itself from the distance you first see it,
##                and is there a landmark read? Camera high and well back.
##   standing  -- eye height, at the spot a player actually stops. This is the
##                frame that decides whether the site is a place or a clearing
##                with objects in it.
##   detail    -- the one thing that gives the site its identity, with the
##                trainer beside it so criterion 8 has its ruler at the scale
##                the detail is judged at.
##
## COORDINATES ARE NEVER INVENTED HERE. Three sources, in order of preference:
##
## 1. The site node's own placement API, where it has one -- `Stronghold` and
##    `BurrowWarrens` expose `marker(id)` returning a WORLD Vector3 built by
##    `to_global()` from their config's chamber list, and `TetherRelay` exposes
##    `world_of(local)`. Asking those is strictly better than transcribing
##    coordinates: the answer comes from the same code that stood the building
##    up, so a site that moves moves this survey with it, and a yaw this file
##    got wrong cannot silently mis-frame a shot.
## 2. `data/config/*.json` positions read straight out (village.json's
##    structures, old_quarry.json's foundations and pylons, the band
##    `props.json` cluster centroids).
## 3. Nothing else. There is no viewpoint below that was chosen by eye.
##
## THE CORRECTIONS BELOW ARE NOT MINE. They are `_probe_corridor_survey.gd`'s,
## carried over deliberately, because this sweep has now watched a fix that
## lived in one tool fail to protect the next tool that did the same thing six
## separate times (archive/ralph/VISUAL_LEDGER.md, "This sweep's own harness defects"):
##
##  - carry the PLAYER to each viewpoint, not just the camera: creature
##    spawning is driven off the player, and the 1.80 m trainer is the rubric's
##    ruler;
##  - `_clear_of_bodies()` before seating, because authored site coordinates
##    frequently hold an NPC and a capsule spawned centre-on-centre inside
##    another capsule has no lateral escape vector, so depenetration launches
##    the player straight up. That is the "trainer standing on the NPC's head"
##    a blind critic found in three corridor frames and a second critic found
##    again in three ground frames. This survey seats itself on authored site
##    coordinates by DESIGN -- it is the tool in this sweep most likely to hit
##    it, not least;
##  - pin the clock AND FREEZE both `WorldLook` and `WorldWeather`, because a
##    pin that is not frozen wears off and the late frames come back in dusk;
##  - hand the capture camera to Terrain3D, or the frames are of whatever
##    coarse LOD happened to reach the eye;
##  - raycast-reseat every eye, because the analytic heightfield and the
##    streamed collision surface disagree by up to 22 m near the river;
##  - hide every CanvasLayer once deep and again before every shutter.
##
## FRAME BUDGET, stated because a survey that does not reach its first shutter
## is the most expensive failure available here. Measured on this box: ~2.4 s
## per awaited frame at 1280x800 under llvmpipe on the loaded world.
##
##   boot                                90 frames
##   two clock pins            2 x  30 =  60
##   day, 10 sites            10 x  86 = 860
##   night, 4 sites            4 x  86 = 344
##                                      -----
##                                      1354 frames ~= 54 minutes
##
## The 86 per site is the arithmetic that makes three shots per site
## affordable: ARRIVE 18 + SETTLE 40 + POSE 4 is paid ONCE, on arrival, and the
## two shots after it are a few metres of camera move inside a region Terrain3D
## has already streamed and the director has already populated -- HOP 8 + POSE
## 4 each. Budgeting three full arrivals per site instead would be 10 minutes
## of pure re-settling for frames that would look identical.
##
## MEASURED on this box, 2026-08-23, one-site smoke run (`--only=04-warrens`):
## process start to first shutter 231 s for 182 frames, then 12 frames per
## extra shot in 25 s and 13 s. That is ~1.3 s per awaited frame, roughly HALF
## the 2.4 s the ledger records -- and the world it renders is BIGGER (223,889
## scattered props here against the corridor's 143,630). The ledger's figure is
## not wrong, it was measured under different contention; both are worth having
## because the honest planning number is "measure it on the day", not either
## constant. At 1.3 s the budget above is ~32 minutes, not 54.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/locations"

## Terrain3D streams its mesh off the PLAYER position, not the camera -- a
## player parked far from the camera degrades the whole scene (sky, terrain,
## near props) while every Environment/sky value at shutter still reads
## correct (see tools/survey.gd's PARK_DISTANCE comment for the measured A/B).
## This tool already carries the player to every shot's own `eye` point, so
## this constant/print exist to make that guarantee loud rather than assumed.
const MAX_CAMERA_PLAYER_DISTANCE := 20.0

const BOOT_FRAMES := 90
const SETTLE_FRAMES := 40    # on arrival at a site, so spawning catches up
const ARRIVE_FRAMES := 18    # after the analytic seat, before the ray reseat
const HOP_FRAMES := 8        # between shots WITHIN a site, already streamed
const POSE_FRAMES := 4
const FOV := 70.0

## Camera placement per question. `back` is metres behind the player along the
## view line, `up` is metres above the ground under the camera.
##
## `standing` is 1.70 rather than the corridor's 2.40 on purpose: this is the
## one frame in the set asking what the site looks like from where a person
## stands in it, and a camera two and a half metres up answers a different
## question -- it flatters a site by showing its layout from above, which is
## exactly the read that lets "props on a lawn" pass.
const RIG := {
	"approach": {"back": 7.0, "up": 3.2},
	"standing": {"back": 3.2, "up": 1.70},
	"detail":   {"back": 5.0, "up": 1.60},
}

## Ten sites, each with three eyes. `at`/`look` are WORLD metres unless the
## shot carries `relay` (local metres through `TetherRelay.world_of`) or
## `marker`/`look_marker` (a site node's own world marker, plus an optional
## world offset).
##
## Provenance for every coordinate is in each site's `_why`; nothing here was
## picked by eye.
const SITES := [
	{
		"id": "01-village",
		"night": true,
		"_why": "data/config/village.json: square flat centre [10,-10], well at [10,-10], workshop [2,2], cottage_a [18,-2], cottage_b [21,-14], inn [-1.5,-9], and Grandpa's farmhouse_shell at [-22,-16]. The fence runs at [14,-20] and [19.5,-25.5] mark the practice-meadow path, which is the direction a player first walks in from.",
		"shots": [
			{"label": "approach", "mode": "approach", "at": [27.0, -31.0], "look": [10.0, -10.0],
			 "_why": "on the practice-meadow path outside the fence runs, the bearing day one arrives on"},
			{"label": "standing", "mode": "standing", "at": [10.0, -15.5], "look": [3.0, 1.0],
			 "_why": "stopped at the well on the square's south side, looking north across it at the workshop -- where the four dirt paths meet"},
			{"label": "twins", "mode": "detail", "at": [-11.5, -21.0], "look": [-11.5, -12.0],
			 "back": 15.0, "up": 2.6,
			 "_why": "the inn [-1.5,-9] and Grandpa's farmhouse_shell [-22,-16] in ONE frame, 20.5m apart, camera far enough back to hold both. VISUAL_STRUCTURES round 1: 'the inn IS farmhouse_shell with a hue-shifted roof, and they stand side by side as visible twins'. This eye exists to make that claim checkable or refute it."},
			{"label": "grandpa-yard", "mode": "standing", "marker": ["GrandpaHouse", "outside"],
			 "look_marker": ["GrandpaHouse", "door"],
			 "_why": "T1-VILLAGE 2026-08-30. The opening's own establishing shot: standing in Grandpa's yard at the house's own `outside` marker (~7.5m off the door, the point the starter row already stands at) looking back at the door. TETHERBOUND_VISUAL_STUNNING_PASS.md sec6/sec16 name this exact yard/house pair a priority and no existing capture in this file stands here."},
			{"label": "tournament", "mode": "standing", "at": [14.0, 5.0], "look": [20.0, 15.0],
			 "_why": "T1-VILLAGE 2026-08-30. tournament.json `board.position` [20,15], `facing_deg` 205 -- the north field behind the square, Bryn's practice ground (playground_world.gd's own comment). Eye stands on the walk-up line from the well toward the board, which is also roughly the bearing `board.facing_deg` 205 was tuned to be read head-on from. sec16 names 'the village tournament area' a priority alongside Grandpa's house and no existing capture in this file has ever stood here."},
			{"label": "route-out", "mode": "standing", "at": [14.0, 20.0], "look": [13.11, 30.37],
			 "_why": "VP2-NIGHT judge pass, 2026-09-02: 'no gate is visible on any road frame -- make the TrailGate/RoadGate visible in at least one route-out frame.' OLD stand (T1-VILLAGE 2026-08-30): at [10,-10] (the well) looking [-14,14], the first leg of the Pond route -- a real road but one with no gate on it anywhere along its authored length, which is exactly why the judge could not find one.\n\nNEW stand aims at TrailGate instead: `data/config/village_boundary.json` gates.entries['TrailGate'] sits `at` [13.79,22.4] on the corridor spine (`terrain_playground.json` trail.bands[0], band1_lower_meadows: authored points [27.5,-16] -> [14,20] -> [8,90] -> ...) -- the road crosses the village fence there, so this is a real gate on a real road, not an invented one. `at` [14,20] is that polyline's own waypoint immediately before the crossing (not picked by eye), 2.41m short of the gate (dx=-0.21, dz=2.4, hypot=2.41) -- close enough that the leaf (`road_gate.gd`/`village_boundary.json` wall.gate_clear_m: a 4.07m-wide leaf) reads large in the near-foreground rather than as a distant speck, and with the default `standing` back (3.2) pulling the camera to about (14.27,16.81) -- still south of the gate on the same road, so nothing about this eye needed overriding.\n\n`look` is deliberately NOT the gate's own coordinate. This file's own header trap (`_ground_at` returning a prop's own box-collider top rather than terrain -- the mill-wheel/apparatus/campfire/bench entries above all hit this) applies to a gate leaf exactly as it does to a fire or a bench: `road_gate.gd::_build_gate_collision` sizes the leaf's collision box from its own AABB (+`vault_guard_m` 1.0, per village_boundary.json's own `_comment_vault_guard`), so a look point sitting on the leaf's own footprint would raycast to the LEAF'S collision top, not the road under it, and `look_up`'s default 1.6 would aim into the sky over the gate the same way the apparatus shot's own fix describes. Instead `look` continues 8m PAST the gate along the trail's own next leg (14,20)->(8,90): unit vector (-6,70)/70.257 = (-0.0854,0.9963), so gate [13.79,22.4] + 8*(-0.0854,0.9963) = (13.11,30.37) -- still on the authored road, off the leaf's own box, so `_ground_at` reads real terrain there and the bare RIG's `look_up` needs no collider correction. Because this look point is directly beyond the gate on the same straight road the eye also stands on, the leaf sits physically between camera and aim point either way -- centred in the frame, not merely somewhere in it. Shot label kept as `route-out` so filenames still match earlier rounds."}
		]
	},
	{
		"id": "02-mill-pond",
		"night": false,
		"_why": "data/config/village.json's OW5D-relocated pond group: mill [-382,514], footbridge [-386.3,520], ranger_station [-350,507]; band1 props.json `bridge_repair_site` centroid [-391.4,521.1].",
		"shots": [
			{"label": "approach", "mode": "approach", "at": [-330.0, 492.0], "look": [-350.0, 507.0],
			 "back": 13.0, "up": 9.2,
			 "_why": "the pond route's own first waypoint. village.json's ranger_station entry names the route as points [-80,85] -> [-105,115] in the pre-OW5D frame; the OW5D offset is (-250,+407), so the route runs (-330,492) -> (-355,522) now. Standing at its head looks at the ranger station -- 'the first built thing between the settlement and the pond valley' in that file's own words -- with the mill beyond it.\n\nThe first draft of this eye was (-352,545) and the raycast reported no collision under it with an analytic height of -20.20 against a pond surface at -17.0: it was IN THE WATER, 38m north of the ranger station. Kept in the comment rather than silently corrected, because 'a plausible-looking coordinate 40m from the thing it names' is how this sweep has produced six frames of the wrong subject.\n\nCODE-BLIND JUDGE, 2026-09-02: the shipped frame (bare RIG `back` 7.0/`up` 3.2) came back filled with leaf cards, camera seated inside a tree canopy on this trail-side approach -- `trees` (data/config/vegetation.json) are the everyday 7-9m broadleaf and this layer's own `corridor_fill.trail_bias` 0.85 sites most of its fill BESIDE the authored trail this eye stands on, so a copse this close to the route is the expected case, not a fluke. Pulled `back` 7.0->13.0 (+6m further from the target along the same eye->target axis) and `up` 3.2->9.2 (+6m higher above the ground under the camera -- ground-relative, per `_frame()`, not an absolute Y) to clear a canopy whose typical crown base sits well under the new eye height even on the tallest 9m form, without re-aiming: same `at`/`look`, so the shot still stands at the route's own first waypoint looking at the ranger station with the mill beyond it."},
			{"label": "standing", "mode": "standing", "at": [-388.0, 526.0], "look": [-382.0, 514.0],
			 "_why": "on the crossing just downstream of the footbridge, looking up at the mill's north face. Ray-seated at -16.5 against a pond surface of -17.0, so this stands on the bank rather than in the water -- checked, because the approach eye 30m away did NOT and it would have been easy to condemn all three together."},
			{"label": "wheel", "mode": "detail", "at": [-390.0, 512.0], "look": [-386.0, 514.0],
			 "back": 5.5, "up": 2.2, "look_up": 2.0,
			 "_why": "the mill's own local -x, where village.json says the wheel hangs over the stream carve (yaw_deg is 0, so local -x is world -x). The recipe contains no wheel module at all -- 78 modules, every one a wall, roof, window, corner, border or fence -- so this frame exists to show what stands there instead.\n\nROUND 2 (tools/_probe_detail_shots.gd): the node actually standing at this look point is `mill_10`, the WHOLE building -- 8.42w x 14.69h x 8.03d, y -17.06..-2.37 in world metres. The bare RIG (`look_up` 1.6) aimed 1.6m above a ground reading of -12.25, i.e. at world y -10.65 -- inside the mill's own vertical span, so this shot was not actually 'about the dirt', but it was aiming at the tower's mid-height for no reason tied to the wheel. Fitting the WHOLE 14.69m building in frame needs a camera 16.8m from this look point (vertical FOV is the binding constraint: `(top - centre_h) / tan(23.6deg)` = 7.34 / 0.4366) -- an approach-shot distance, not a detail crop, and the point of this eye is the WEST WALL NEAR THE WATERLINE where the wheel would attach, not the roofline. `look_up` 2.0 aims 2.0m above the -12.25 ground reading (itself very likely the mill's own wall face, not the true carve floor -- the eye/back ground sweep declines smoothly from -16.50 toward -20 as the camera pulls back into open water, and -12.25 sitting 4+m ABOVE that trend at the exact wall footprint is the same 'raycast hits the thing you're framing, not the terrain under it' effect `_probe_detail_shots.gd`'s header documents), landing the aim comfortably inside the wall's own span rather than at its roof. `back` 5.5 is a deliberately bounded crop (roughly a person's reach of wall, not the tower) rather than the FOV-fit distance for the whole building. `up` 2.2: the ground under the camera at back 5.5 is itself deep in the carve (~-17.3, interpolated from the same sweep), so a modest above-local-ground height keeps the camera reading as standing in the streambed looking up at the bank, which is the honest read of a wheel that would meet the water here."}
		]
	},
	{
		"id": "03-quarry",
		"night": false,
		"_why": "data/config/old_quarry.json: foundations [397,1805] and [404,1794]; the lit pylon run [404,1804] -> [418.1,1763.2] on the stronghold bearing. band2 props.json `quarry_station` centroid [401.9,1800.2].",
		"shots": [
			{"label": "approach", "mode": "approach", "at": [368.0, 1832.0], "look": [400.0, 1800.0],
			 "_why": "in on the road from the north-west, the bearing the larger foundation's standing course faces"},
			{"label": "standing", "mode": "standing", "at": [400.0, 1803.0], "look": [418.0, 1764.0],
			 "_why": "on the quarry floor between the two foundations, looking down the lit conduit run as it walks away over the hill -- the whole point of the site per old_quarry.json's own evidence note"},
			{"label": "conduit-head", "mode": "detail", "at": [399.0, 1809.0], "look": [404.0, 1804.0],
			 "back": 3.0, "up": 1.8, "look_up": -0.92,
			 "_why": "the conduit head pylon on the quarry floor, the one piece of present-tense machinery here.\n\nROUND 2 (tools/_probe_detail_shots.gd): `Pylon_0` measures y -0.72..3.88 (4.60m tall, matching old_quarry.json's configured `height`) and 2.97-4.19m across, centred on world y 1.58. Ground at the look point raycasts to 2.50 -- a real terrain reading, not a collider artifact (the eye/back ground sweep rises smoothly through it, 8 separate samples from -0.41 to 2.98). `look_up` -0.92 aims at the pylon's own centre height (1.58 = 2.50 - 0.92), per the eye already standing 7.07m off -- MORE than the 5.26m the vertical FOV alone needs at that aim height, so no extra `back` was owed for size; the bare RIG's `back` 5.0 was pure excess distance, shrinking an already-small subject further for no reason. `back` 3.0 keeps the player a legible ruler in frame (the floor this round used everywhere the FOV math alone would ask for less) while still landing well inside the fit. `up` 1.8, close to the bare default, because this subject was never the 'aiming at dirt' failure -- it is a modest, roughly person-scale machine and a near-eye-height camera reads it correctly."}
		]
	},
	{
		"id": "04-warrens",
		"night": false,
		"_why": "data/config/burrow_warrens.json site [-357,2610] yaw 315. Every eye here is asked of the node itself (`BurrowWarrens.marker`) rather than transcribed, because a 315-degree yaw makes hand-rotating five chamber locals a guess this file should not be making.",
		"shots": [
			{"label": "approach", "mode": "approach", "marker": ["BurrowWarrens", "entrance"],
			 "look_marker": ["BurrowWarrens", "hall"], "pull_back": 30.0,
			 "_why": "30m straight out in FRONT of the mouth, on the axis the cave itself runs. The first draft of this shot used a hand-written world offset of (+24,+24) from the entrance and its frame came back with no cave in it: the site is yawed 315 degrees, so the mouth faces (+x,-z), and moving +z walked sideways past the mound instead of standing off from it. `pull_back` takes the direction from the two markers -- entrance out through the hall -- so the shot cannot be wrong about which way the door faces."},
			{"label": "standing", "mode": "standing", "marker": ["BurrowWarrens", "entrance"],
			 "look_marker": ["BurrowWarrens", "hall"],
			 "_why": "at the mouth looking in, the threshold shot"},
			{"label": "den", "mode": "interior", "marker": ["BurrowWarrens", "den"],
			 "look_marker": ["BurrowWarrens", "guardian"], "back": 1.5, "up": 2.2, "look_up": 1.15,
			 "_why": "standing in the guardian's chamber looking at the guardian -- the deepest authored room and the thing in it that gives the warrens their identity. No offset: the site is yawed 315 degrees, so a world-axis nudge does not stay inside the room it was measured in, and an offset also forfeits the marker's authoritative floor Y.\n\nFIX (JUDGE-round1 PLACES, 04-* section): this frame rendered as 'a flat teal-green fill with faceted diagonal shading bands ... consistent with the camera being clipped inside collision geometry', identical before/after -- a persistent camera fault, not an art defect. Re-deriving every number this shot depends on turns up nothing that puts the bare RIG (back 3.2, up 1.70) camera point outside the den's own 16x14x4.8m room: burrow_warrens.json's `den` chamber and the guardian's `offset` [3,4] both resolve inside it, and `BurrowWarrens.marker('guardian')` is not a guess -- `creature_body.gd::place_on_ground`/`_seat_over_footprint` snap the spawn's authored y (floor+0.5) straight back down to `built_floor_height_at()`'s flat _floor_y, so eye and look share the SAME Y the chamber marker does, not the offset y this shot's own comment used to assume. What the room DOES carry, per `data/config/burrow_warrens.json`'s own `_comment_caps`, is wall-hugging decorative rock with a documented history of exactly this failure ('a five-metre-wide rock... one ended up between the camera and the guardian -- the exact failure this pass exists to replace') -- capped since at `wall_width_cap_m` 1.9 off an `edge_band_m` up to 1.7, which can still reach within ~4.35m of the near (hall-side) wall on an unlucky seed roll, only 1.8m short of the OLD back-3.2 camera point. Since the render is broken anyway, this round does not trust a second single computed point: `back` 1.5 (down from 3.2) keeps the camera within 1.5m of the chamber's own mathematical centre, >3m clear of every wall on every axis regardless of the interior-rock seed, and `up` 2.2 (from 1.70) lifts it clear of anything sunk near the floor. `look_up` 1.15 replaces the bare RIG's chest-height 1.6 -- tuned for people and buildings -- with the guardian's own half-height at its `scale` 1.35 (species.json burrowback placeholder height 1.7 x 1.35 / 2 = 1.15), since the flat cave floor means eye, back and look all share one Y and 1.6 was aiming near the top of a ~2.3m creature rather than its centre."}
		]
	},
	{
		"id": "05-relay-camp",
		"night": true,
		"_why": "band3 props.json `relay_approach_checkpoint` centroid [240.9,3673.7] and `riverwatch_rest` [211,3700.2]. This is the site the corridor's `05-band3-relay` frame photographed and the critic called 'a campfire with no camp around it, a banner and a grunt with nothing to guard'.",
		"shots": [
			{"label": "approach", "mode": "approach", "at": [213.0, 3648.0], "look": [241.0, 3674.0],
			 "_why": "up the road from the south-west, the bearing the checkpoint faces"},
			{"label": "standing", "mode": "standing", "at": [238.0, 3670.0], "look": [252.0, 3686.0],
			 "_why": "inside the checkpoint looking through it toward the relay -- the frame that asks whether this is a camp or a prop scatter"},
			{"label": "fire", "mode": "detail", "at": [237.0, 3678.0], "look": [241.4, 3667.3],
			 "back": 3.0, "up": 1.8, "look_up": -5.05,
			 "_why": "the campfire and what is (or is not) arranged around it.\n\nFIX (AUDIT-E E4, tools/_probe_detail_shots.gd re-run against this corrected look): the prior round's own FINDING said this shot's `look` was 6.72m off band3_the_river_lock/props.json's real `Bonfire_Fire`/`campfire_stone_ring` at (241.4, 3667.3) and left the fix out of scope; this round makes it. `at`/`back`/`up` are unchanged -- the probe's own FOV-fit check confirms the existing eye is already 11.57m from the corrected look point against a 6.47m minimum to fit the fire's whole bounding box, so nothing needed to move closer, only aim correctly.\n\n`look_up` -5.05, not the Bench-height 0.24 the prior round used: the ground raycast AT THE REAL FIRE'S OWN POSITION hits the same collider-top artifact ridge-camp's own fire shot already documented, not real terrain -- 'ground at look point' reads 1.79, matching `Bonfire_Fire`'s own measured top (1.79) to the centimetre, while the real ground reads -3.86 to -3.91 across the checkpoint's other furniture (`Bench`/`Bag`/`Bucket_Wooden_1`/`campfire_stone_ring`, all within 0.12m of each other). Aiming at the flame/embers rather than the tall smoke column above them uses the same base+0.6 rule ridge-camp's own shot derived from campfire_glow.gd's EMBER_HEIGHT/LIGHT_HEIGHT constants: -3.26 (= -3.86 + 0.6) reconstructed through the collider-hit reading (-3.26 = 1.79 + -5.05). The checkpoint's own watch-post furniture the prior round found instead (Bench, Bag, Bucket) all sit within 2.7m of this same corrected look point, so the frame still holds the fire's actual surroundings, not just the fire alone."}
		]
	},
	{
		"id": "06-relay",
		"night": false,
		"_why": "data/config/tether_relay.json site centre [350,3760]. Yard walls run local x -14..+10, z -16..+16; gate at local [-14,0] opening 6.8; apparatus at local [7,-9] with its console at [2.9,-9]. Local metres are put through `TetherRelay.world_of()`, the builder's own frame, so the -34.4-degree approach bearing does not have to be re-derived here.",
		"shots": [
			{"label": "approach", "mode": "approach", "relay": true, "at": [-20.0, 0.0], "look": [-14.0, 0.0],
			 "back": 4.0,
			 "_why": "6m out on the gate's own axis, outside the front wall line.\n\nFIX (JUDGE-round1 PLACES, 06-* section): this frame rendered as 'a flat green fill with light-green triangular facets, consistent with the camera clipped inside terrain or canopy geometry', identical before/after. `tether_relay.json`'s own `site._ground` names exactly how far this site's ground is actually known: 'ground runs -5.6m at s=-24 up to -1.0m at s=+20 ... every wall, leg and pad is seated on its own sampled ground' -- and says nothing about ground past s=-24. The old eye at s=-46 already stood 22m past that edge, unprobed, and the bare RIG's `back` 7.0 (mode approach, not `relay`-mapped, so it moves the WORLD-space camera in the same s-direction here) walked it a further 7m out to s=-53, 29m into ground this file never asked the heightfield about -- exactly the kind of raycast this file's own header warns can return a prop's (or here, a tree's) own collider top instead of real terrain, which is what a camera that ends up INSIDE a canopy looks like. New eye s=-20, t=0 sits 6m out from the front wall (s=-14, unchanged from the reasoning the old `_why` already gave) and inside the last 4m of the site's own probed band. `back` 4.0 (overriding the mode default 7.0) keeps the final camera point at s=-24 -- the site's own outermost sampled point, not a metre past it. `up`/`look_up` are unchanged: the ground under them was the defect, not the height above it."},
			{"label": "standing", "mode": "standing", "relay": true, "at": [-8.0, -2.0], "look": [7.0, -9.0],
			 "_why": "just inside the gate on the yard floor, looking at the apparatus on its pad"},
			{"label": "apparatus", "mode": "detail", "relay": true, "at": [14.0, -4.0], "look": [7.0, -9.0],
			 "back": 3.0, "up": 2.4, "look_up": -2.1,
			 "_why": "the relay apparatus itself -- a Team Tether hero object, and the site's identity.\n\nFIX 3 (code-blind judge pass): 'the trainer is clipped onto a roof and the camera stares into the sun.' Two separate defects, addressed together by moving the eye; `look`/`up`/`look_up` are unchanged.\n\nSTARING INTO THE SUN. `data/config/art.json`'s `sun` block sets `pitch_deg` -44, `yaw_deg` 140 (world_look.gd rotates the DirectionalLight3D so light travels FROM the yaw direction TOWARD the opposite one -- that file's own `_comment_yaw_visual_light` names the 140 value directly). Running that rotation through Basis.from_euler's YXZ order the same way world_look.gd's own comment verifies it (`sun_dir.z > 0 at yaw -40 = north`) gives a light-TRAVEL direction of world (-0.462,-0.695,0.551) at yaw 140 -- i.e. the sun itself sits toward world (0.462,0.695,-0.551), horizontally (0.643,-0.766) once normalised: south, with a lean east. The OLD eye (1,-4) looked at the apparatus (7,-9) along local (6,-5) -> world (-0.739,-7.775) normalised (-0.095,-0.995) -- within 0.7 percent of `_u`'s own value (0.565,-0.826) mapped to local `(0.826,-0.565)`, itself EXACTLY world (0,-1) by this same site's own basis (solved directly: local (ds,dt) satisfying `_u*ds+_p*dt=(0,-1)` gives (0.825,-0.565)), the site's own due-south direction -- so the old shot looked almost exactly toward where the sun sits. New eye (14,-4) looks at the same (7,-9) along local (-7,-5) -> world (-0.939,0.343), whose dot product against the sun's own horizontal direction (0.643,-0.766) is -0.867 (about 150 degrees off dead-on, i.e. the sun sits mostly BEHIND this camera, front-lighting the apparatus rather than glaring into the lens).\n\nCLIPPED ONTO A ROOF. This file's own header trap (`_ground_at` returning a prop's own collider top, not terrain) is the apparatus's OWN case, already named in this shot's prior round -- but that trap is at the LOOK point, not the eye: the prior round's own ground sweep found the eye/back reading a flat, ordinary 4.9-5.8m 'everywhere EXCEPT [the look] point', so the ruler trainer this file always seats at `at` was standing on real ground, not a roof, even before this fix -- the read was almost certainly this shot's extreme low, close, steeply-upward composition (back 3.0, camera well under the 10.0m deck, aimed at an object whose conductor arms and manifolds oversail the pad) putting the object's own overhead massing directly above the ruler in frame, rather than a bad ground seat. Nothing in `relay_site.json` stands anyone at this shot's coordinates, so there was no authored position to fix. The reframe happens to remove any ambiguity anyway: `tether_relay.json`'s `apparatus.massing.grounding_base.radius` is 3.4m and the pad itself (`decks[1]`) runs local s[2,12] t[-14,-4] -- the new eye (14,-4) sits a clean 2m past the pad's own s edge and 8.6m from the apparatus centre (vs. the model's 3.4m footprint), so `_ground_at` reads open ground with no nearby collider to catch, the same way the un-moved `standing` eye already does.\n\nFOOTPRINT AND HAZARD CLEARANCE (checked, not assumed): east_run's own last pylon sits at local (14.5,-9), 5.2m from the new eye and 4.3m from the new back point (18.7,-9 is not on the eye/back line; nearest approach is well past 3m) -- clear of its own 1.7m collision box. The new back point (16.4,-2.3, from `back` 3.0 along the same line) stays inside `site._ground`'s own probed band (out to local s=+20). `up`/`look_up` are unchanged from the prior round's own derivation (still valid: the LOOK point did not move, so the same collider-hit reconstruction -- the apparatus's `Model` measures y 10.00..14.20, centred 12.10, and the ground raycast at (7,-9) still hits that same 14.20 top -- still gives `look_up` -2.1 = 12.10 - 14.20). `up` 2.4 is carried over rather than re-derived against a fresh ground probe at the NEW back point (out of this pass's tooling budget); it keeps the camera comfortably below the 10.0m deck across the whole 2.3-6.9m relief `relay_site.json`'s own OW5E note records within 15m of the pad, so the shot still looks UP at the apparatus rather than level with it.\n\nSTAFFING (FIX 2, tether_relay.json's own `deck_people`): Relay Platform Hand (local 10.6,-7.3) sits 4.7m along this eye's own view axis against the apparatus centre's 8.6m -- nearer the camera than the object, so it stands unoccluded in the near ground rather than behind the object's 3.4m bulk. Relay Console Guard (local 2.9,-7.0) sits past the apparatus on this axis and is the harder figure to keep clear in THIS shot specifically (the console faces west, back down the gantry, away from this south-east eye) -- it is what the `standing` eye below (approaching from the west) exists to cover instead."},
			{"label": "road", "mode": "approach", "relay": true, "at": [0.0, 0.0], "look": [-155.07, 21.26],
			 "_why": "CORRIDOR LANE PARITY. tools/_capture_corridor.gd (origin/claude/vp-corridor, 43defff6) station 11 ('11-relay') seats the player at world XZ (350.0,3760.0) looking at world XZ (280.0,3900.0) -- the view walking IN along the road, which this file's own three 06-relay eyes (approach/standing/apparatus) never reproduce because all three stand well inside or at the gate, not on the corridor's own approach line. Converted into this site's own local (s,t) frame per this site's `_why` and `tether_relay.json`'s `_frame` comment (world_of(local) = centre + u*local.x + p*local.y, centre [350,3760], u = (0.565,-0.826) normalised, p = (-u.y,u.x)):\n\nnormalised u = (0.565,-0.826)/|(0.565,-0.826)| = (0.565,-0.826)/1.00075 = (0.564576,-0.825380); p = (0.825380,0.564576).\n\nEYE: world (350,3760) - centre (350,3760) = offset (0,0) -> local (0,0) -- station 11's eye IS this site's own centre, to the metre.\n\nLOOK: world (280,3900) - centre (350,3760) = offset (-70,140). local s = offset.dot(u) = (-70)(0.564576)+(140)(-0.825380) = -39.5203 + -115.5532 = -155.0736. local t = offset.dot(p) = (-70)(0.825380)+(140)(0.564576) = -57.7766 + 79.0406 = 21.2641. Rounded to (-155.07, 21.26).\n\nNo `back`/`up`/`look_up` override: mode `approach` (back 7.0, up 3.2) is the same rig this site's own `approach` shot uses for the same kind of question (does the site read from the road), and nothing about this pair of points is known to hit this file's own collider-top trap -- the look point sits 156.5m out along open corridor ground the corridor lane itself already stands a station on, not on a prop's own footprint."}
		]
	},
	{
		"id": "07-mill-crossing",
		"night": false,
		"_why": "band3 props.json `old_mill_crossing_gear` centroid [-152.1,4186.7] and `old_mill_yard` [-140.3,4219]. SE22's crossing, the one authored way over the river.",
		"shots": [
			{"label": "approach", "mode": "approach", "at": [-168.0, 4160.0], "look": [-152.0, 4187.0],
			 "_why": "up the near bank from the south, the side the player reaches first"},
			{"label": "standing", "mode": "standing", "at": [-150.0, 4192.0], "look": [-140.0, 4219.0],
			 "_why": "on the crossing looking across at the mill yard on the far bank"},
			{"label": "yard", "mode": "detail", "at": [-144.0, 4212.0], "look": [-140.0, 4219.0],
			 "back": 1.0, "up": 1.8, "look_up": 0.72,
			 "_why": "the mill yard's own gear cluster on the far side.\n\nROUND 2 (tools/_probe_detail_shots.gd): `Bench` (the cluster's largest, most central piece) measures y -3.57..-3.03, centred on -3.30, 2.47-3.06m across; ground at the look point reads -4.02, a real terrain value (matches the eye's own -3.14 closely, not an outlier). `look_up` 0.72 aims at that centre (-3.30 = -4.02 + 0.72). `back` is capped at 1.0 rather than this round's usual 3.0 ruler floor for a hazard this file's own header already names: the ground sweep along the eye-to-look line here PLUNGES from -3.25 at back 1 to -22.11 by back 8 before popping back to -1.91 at back 15 -- this shot sits on the river crossing, and the camera's own line of retreat walks straight over the channel, where 'the analytic heightfield and the streamed collision surface disagree by up to 22m' (this file's own header, on the river). `back` 2.0 or beyond seats the camera in that chasm; 1.0 is the last sample confirmed on the near bank (-3.25, consistent with the eye and the look point both). `up` 1.8 matches this round's other ground-clutter subjects -- a near-eye-height camera reading gear at rest on a yard floor."}
		]
	},
	{
		"id": "08-ridge-camp",
		"night": true,
		"_why": "band4 props.json `ridge_patrol_camp`: tent [-238.3,6473.6], bonfire and stone ring [-233.1,6474.3], stool [-232.1,6473.5], crates/barrel/bag/rope/whetstone/axe around [-235,6472], three rocks on the west flank. Centroid [-235.9,6471.7]. This is the Upper Meadows' only authored camp.",
		"shots": [
			{"label": "approach", "mode": "approach", "at": [-258.0, 6450.0], "look": [-236.0, 6472.0],
			 "_why": "up the ridge from the south-west, past the rock flank"},
			{"label": "standing", "mode": "standing", "at": [-236.5, 6468.0], "look": [-234.0, 6476.0],
			 "_why": "standing in the camp between the crates and the fire, looking at the tent-and-fire pair"},
			{"label": "fire", "mode": "detail", "at": [-230.0, 6471.0], "look": [-233.9, 6473.7],
			 "back": 3.0, "up": 2.2, "look_up": -5.49,
			 "_why": "the bonfire and its stone ring, the camp's one warm thing.\n\nROUND 2 (tools/_probe_detail_shots.gd): this is the critic's other named case -- 'a fire on the ground'. `Bonfire_Fire` (this look point IS its authored position, unlike the relay camp's) measures y 2.69..8.34, but that top is `campfire_glow.gd`'s own smoke column (`SMOKE_TOP_HEIGHT` 4.6, counter-scaled to stay absolute regardless of the log model's 0.38 scale) reaching into the box collider the ground raycast at this exact look point then hits -- confirmed the same way as the apparatus: the eye/back sweep sits flat at 2.7-4.1 everywhere except this one point (8.34), and 8.34 matches the fire's own measured top. Aiming at the geometric CENTRE of that box (y 5.51, roughly the smoke column's own midpoint) would point at thin rising smoke, not the fire -- the flame/embers/light that give a campfire its identity sit within `campfire_glow.gd`'s own constants (`EMBER_HEIGHT` 0.85, `LIGHT_HEIGHT` 0.55) of the base, so the aim height used here is base + 0.6 = 3.29, not the tall box's centre. `look_up` -5.05 reconstructs that through the same collider-hit ground reading (3.29 = 8.34 - 5.05). `back` 3.0 (this round's ruler floor) comfortably covers the tighter fit that aim needs (4.58m unmargined, against 2.83m if the whole smoke column were the target). `up` 2.2 puts the camera clearly above the flame's own height at this back (ground under the camera reads ~2.97, a real value off the fire's own footprint), looking down into the fire the way the task's own guidance for this exact case asks for, rather than level with a point of thin smoke.\n\nAUDIT-E E4 re-clustering (this branch): the fire, its ring and the stool moved 1.0m toward the camp's supply pile so the whole arrangement reads as one camp (see band4 props.json's own `_why_reclustered`), and the fire's `glow_scale` 1.8 makes the fire itself the audit's OTHER named fix (too small/dim behind the player's own head). Both move `look`: re-run against the moved fire, the same collider-hit pattern reproduces at the new position (`ground at look point` 8.22, matching the moved `Bonfire_Fire`'s own new top of 8.22 to the centimetre; new base 2.13). Same base+0.6 rule, new numbers: aim height 2.73 (=2.13+0.6), `look_up` -5.49 (=2.73-8.22). `back`/`up` unchanged -- the probe's own FOV-fit check says the now-larger (`glow_scale` 1.8) fire needs the camera only 6.97m out to fit whole, against the unchanged eye's 4.74m plus this shot's existing back 3.0 (7.74m), so the existing rig still comfortably frames it without widening the shot."}
		]
	},
	{
		"id": "09-waystop",
		"night": false,
		"_why": "band5 props.json `the_waystop`: bench [-26.5,7457], anvil-log [-24,7458.8], bag [-25.2,7456], bucket [-27.8,7459.4]. Centroid [-25.9,7457.8], and the last rest before the stronghold gate.",
		"shots": [
			{"label": "approach", "mode": "approach", "at": [-44.0, 7440.0], "look": [-26.0, 7458.0],
			 "_why": "up the road from the south-west"},
			{"label": "standing", "mode": "standing", "at": [-29.0, 7454.0], "look": [-24.0, 7462.0],
			 "_why": "at the bench, looking on toward the gate"},
			{"label": "bench", "mode": "detail", "at": [-23.0, 7454.0], "look": [-26.5, 7457.0],
			 "back": 3.0, "up": 1.8, "look_up": -0.27,
			 "_why": "the bench and anvil-log -- whether a rest stop reads as somewhere someone sat.\n\nROUND 2 (tools/_probe_detail_shots.gd): `Bench` measures y 1.45..1.98, centred on 1.71, 3.22-3.28m across. Ground at the look point reads 1.98 -- ANOTHER collider-hit artifact, this time the bench's own box top: the eye/back ground sweep declines smoothly from 1.01 at the eye through -0.56 by back 15, and 1.98 sitting well above that whole trend, matching the bench's own measured top exactly, is the tell. `look_up` -0.27 reconstructs the bench's true centre through that same reading (1.71 = 1.98 - 0.27) -- the bare RIG's `look_up` 1.6 would have aimed at 1.98+1.6=3.58, more than 1.5m above a bench that tops out at 1.98, i.e. at the empty air over a rest stop rather than the rest stop. `back` 3.0 is this round's ruler floor, well past the 2.88m the bench alone needs at that aim height. `up` 1.8, matching the round's other ground-clutter subjects."}
		]
	},
	{
		"id": "10-stronghold",
		"night": true,
		"_why": "data/config/stronghold.json site [0,7560] yaw 90; chambers outer_works/courtyard/tether_approach/warden_arena/legendary_chamber; approach pylon run starts [-40,7010]. Interior eyes are asked of `Stronghold.marker()` -- the node's own `to_global()` of each chamber centre -- because site yaw 90 rotates every chamber local, and getting that rotation wrong by hand would photograph the inside of a wall.",
		"shots": [
			{"label": "approach", "mode": "approach", "marker": ["Stronghold", "entrance"],
			 "look_marker": ["Stronghold", "outer_works"], "pull_back": 110.0,
			 "back": 12.0, "up": 6.0,
			 "_why": "110m straight out from the gate, well back and high, because the ONE thing the stronghold has to do at this distance is announce itself. VISUAL_STRUCTURES round 1 calls it 'the game's antagonist made of nothing'; this is the eye that claim has to be answered at. `pull_back` rather than a world coordinate because site yaw 90 turns the route's front to face WEST -- a hand-written eye due south of [0,7560] would have photographed a side wall and called it the approach."},
			{"label": "gate", "mode": "standing", "marker": ["Stronghold", "entrance"],
			 "look_marker": ["Stronghold", "outer_works"],
			 "_why": "at the entrance mark looking into the outer works -- the gate slot at the height a 1.80m person meets it"},
			{"label": "courtyard", "mode": "interior", "marker": ["Stronghold", "courtyard"],
			 "look_marker": ["Stronghold", "tether_approach"],
			 "_why": "standing in the courtyard looking on toward the tether approach. This is where oxblood belongs and where the structures round found none. No offset, for the same reason as the warrens den: site yaw 90 rotates every local, and the marker's own Y is the floor."},
			{"label": "gate-face", "mode": "standing", "marker": ["Stronghold", "entrance"],
			 "look_marker": ["Stronghold", "outer_works"], "pull_back": -33.1,
			 "_why": "VP-HALL-FIX ITEM2 (2026-09-02). 15m out from the gate ARCH (not the jambs, not the mouth wall face), on the arch's own centreline, so the two ground-level sentries now posted at the gate posts (`stronghold.json`'s `gate_sentries`, x +-2.0) read at native size flanking the doorway. Derived the way this file's own header requires -- from the same code the building itself runs, not a guessed coordinate.\n\n`stronghold.gd::_build_gate_frame`/`_build_gate_arch_and_portcullis`, `outer_works` at local [0,0] size [20,24], `site.wall_thickness` 1.2, `site.ramp_run` 40.0: mouth outer face `_mouth_outer_z()` = -12.0; jamb face `jamb_z` = -12.0 - 1.2 + 1.2*0.5 - 1.0*0.5(jamb_proud) = -13.1; the voussoir ring itself (the actual arch, standing proud of the jambs per that function's own comment) sits at `proud_z` = jamb_z - 1.0*0.5 - 0.62*0.5(ring_depth) - 0.06 = -13.97. World arch z = site.z 7560.0 + -13.97 = 7546.03, at lateral world x = site.x 8.0 (outer_works' own centre, unchanged by the door). `ramp_foot`/`entrance` marker sits at local z = (mouth -12.0 - wall_t 1.2) - ramp_run 40.0 = -53.2, world z 7506.8 -- the same 41.2m-out-from-the-mouth arithmetic the `hall-100m/200m/400m` shots above already use and verify.\n\n`pull_back` moves the eye from `entrance` along `(entrance - outer_works).normalized()`, which is world (0,-1) here since both markers share x=8.0 -- so the eye stays on the arch's own centreline (x=8.0) at every pull_back value, and a negative pull_back walks it NORTH, back toward the building, past where `entrance` stands. Target eye z = arch z 7546.03 - 15.0 = 7531.03; pull_back = entrance z 7506.8 - eye z 7531.03 = -24.23.\n\nTHE HEADER'S OWN TRAP: `look_marker` (`outer_works`) hands the target a real floor_hint, so `_ground_at`'s `_is_interior(floor_hint)` branch returns that marker's own Y directly -- no raycast at the look point at all, so the arch's own geometry (which the look line passes straight through, both points sharing x=8.0) cannot be hit as a false 'ground'. The EYE, by contrast, gets `floor_y` reset to NaN by `pull_back` (same as every other pull_back shot here) and is genuinely raycast at z~-28.97 local -- but that point sits on the open centre of the ramp deck itself: `causeway`'s own dressing (kerb piers, braziers, banner piers) all stand off-centreline per `stronghold.json`'s own placement notes ('the centre lane stays completely clear end to end' -- the walking lane a raycast here has to land on, not a prop's box), and the ramp is real walkable collision the player crosses every playthrough, unlike the unprobed open terrain the 100/200/400m stands' own `up` insurance exists for. No `back`/`up`/`look_up` override: mode `standing`'s own rig (back 3.2, up 1.70, look_up 1.6) is the same one the `gate` shot above already uses for the same kind of question at the same site, and look_up 1.6 aims at a real grunt's own head/torso height off the outer_works floor, not the arch's masonry above it.\n\nVP-PLACES DECISION-hall-sentries.md FAILURE B (2026-09-02): pull_back -24.23 also put the eye's own clearance capsule bottom flush on `ApproachRampBody`'s top surface, so `_clear_of_bodies` read it as occupied and shoved the eye 6m west, off the 7m-wide deck entirely. Fixed at the capsule (lifted 0.15m so a body the eye was just ray-seated on no longer counts as a blocker) AND here: pull_back tightened -24.23 -> -33.1, eye at world z 7539.9 (7.0m south of the sentries, on the deck), camera at (8, deck-1.15, 7536.7), 10.2m from the posts, pitched up 6.7 degrees. Distance was tightened, not just unstuck: at 1280x720 vertical fov 70 (514 px per unit tan), a 1.8m sentry only reaches 33-42px at the old 22-28m stand-off -- too small to read as a figure -- versus 91px (68px on the 960x540 sheet) at 10.2m."}
		]
	},
	{
		"id": "11-castle-landmark",
		"night": false,
		"_why": "RETARGETED. T1-HALL merged the detached castle this site used to shoot into the Meadows Hall -- `data/config/stronghold.json`'s own `_comment_where`: 'the castle IS the Meadows Hall IS the stronghold -- one location, not the works behind a separate castle 154m away.' `scripts/world/landmark.gd`'s castle at (229.8,-144.4) retired and `playground_world.gd` stopped calling it, so the three shots that used to stand here photographed empty hills -- JUDGE-round1 PLACES (11-* section): 'effectively empty frames ... despite their names, neither shows any castle.'\n\nRe-aimed at `Stronghold`'s own `entrance`/`outer_works` markers rather than a transcribed coordinate, per this file's #1 source-of-truth rule -- the site has already moved once (OW5D put it at [0,7560] yaw 90 'very likely WRONG'; T1-HALL re-probed and moved it again to [8,7560] yaw 0) without every caller following, and a marker-based shot moves with it if it moves a third time.\n\nThree distances along the causeway axis, per the task that dispatched this fix: 100m, 200m and 400m out from the Hall's own MOUTH (`outer_works`' -z wall face -- yaw 0 keeps local and world identical, so `stronghold.json`'s `chambers[0]` `at`[0,0] + `size`[20,24] puts that face at local z=-12, world z=7560-12=7548, the same arithmetic `stronghold.gd::_mouth_outer_z()` runs). `entrance` (== `ramp_foot`, built by `stronghold.gd::_build_approach_ramp`) sits a further `ramp_run`(40) + `wall_thickness`(1.2) = 41.2m out, at world z=7506.8 -- so `pull_back` from `entrance` for a shot `D` metres out from the mouth is `D - 41.2 - back`. The 400m stand is the important one (VISUAL_STRUCTURES' 'the game's antagonist made of nothing' is the claim it has to answer, and the task names it the evidence stand for whether the silhouette separates from the ground), so it carries the most `up`; 100m and 200m are closer establishing beats on the same line. Renamed hall-100m/200m/400m from approach/gate/banners because the subject changed from the retired castle's own gate and banner wall to the Hall's silhouette at a set of distances -- the capture report should explain the filename change.",
		"shots": [
			{"label": "hall-400m", "mode": "approach", "marker": ["Stronghold", "entrance"],
			 "look_marker": ["Stronghold", "outer_works"], "pull_back": 353.8,
			 "back": 5.0, "up": 28.0, "look_up": 14.0,
			 "_why": "400m out from the Hall's mouth (world z=7548-400=7148). `pull_back` 353.8 = 400 - 41.2 (entrance's own offset from the mouth, derived above) - `back` 5.0. This point is well past `stronghold.json`'s own probed grid (x[-72,40] z[7490,7682]) -- like `06-relay`'s approach fix above, this is beyond directly-verified ground, so `up` 28.0 is deliberate insurance, well above every relief the probe DID record near the site (+4.8 courtyard rise, +7..+9 western shoulder, -8..-16 ravine, all inside +-16m), rather than a claim this file pretends is measured. `look_up` 14.0 keeps the aim on the Hall's own upper works -- `legendary_chamber` alone runs to height 22 -- rather than its floor, so the massing frames against sky the way the evidence stand needs."},
			{"label": "hall-200m", "mode": "approach", "marker": ["Stronghold", "entrance"],
			 "look_marker": ["Stronghold", "outer_works"], "pull_back": 153.8,
			 "back": 5.0, "up": 18.0, "look_up": 10.0,
			 "_why": "200m out (world z=7548-200=7348). `pull_back` 153.8 = 200 - 41.2 - `back` 5.0. `up`/`look_up` scaled down from the 400m stand for the closer, more oblique establishing beat this distance asks for; ground here is equally unprobed, same insurance reasoning."},
			{"label": "hall-100m", "mode": "approach", "marker": ["Stronghold", "entrance"],
			 "look_marker": ["Stronghold", "outer_works"], "pull_back": 53.8,
			 "back": 5.0, "up": 10.0, "look_up": 8.0,
			 "_why": "100m out (world z=7548-100=7448). `pull_back` 53.8 = 100 - 41.2 - `back` 5.0. Closest of the three: 42m past the south edge of `stronghold.json`'s own probed grid (z>=7490) and 32m further from the mouth than the probe's own sampled trail point at (20,7480) -- still beyond directly-verified ground, so `up` 10.0 is the same insurance as the other two stands, scaled to the shorter distance."}
		]
	},
]

## Night is the four sites a player is genuinely in after dark: the village
## they sleep in, the two camps they rest at, and the stronghold they finish in
## (data/config/stronghold_occupation.json runs the place at night). The
## warrens are not here on purpose -- a cave lit by its own five lights renders
## the same at both clocks, so a night pass there buys a duplicate frame.

var _field: RefCounted = null
var _world: Node = null
var _player: Node3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null
var _failures: int = 0
var _written: int = 0

## FAST ITERATION MODE. On with `--fast` (a user script arg) or `VP_FAST=1` in
## the environment. Halves every settle wait below (floor 2 frames, via
## `_frames()`) and turns off MSAA/SSAA on the capture viewport. Output
## filenames and directories are unchanged -- this trades fidelity for a
## quicker local loop, never for the numbers that ship as evidence.
static var _fast_mode: bool = false


static func _frames(n: int) -> int:
	return maxi(2, n / 2) if _fast_mode else n


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	_fast_mode = "--fast" in OS.get_cmdline_user_args() or OS.get_environment("VP_FAST") == "1"
	if _fast_mode:
		print("[fast] iteration mode: settle halved, msaa off")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in _frames(BOOT_FRAMES):
		await physics_frame
	print("[locations] world up, boot settled")

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	for node in _all(_world):
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false

	_player = _world.get_node_or_null(^"Player") as Node3D
	if _player == null:
		print("FAIL no Player node; the frames would have no 1.80m ruler in them")
		quit(1)
		return

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()
	if _fast_mode:
		root.msaa_3d = Viewport.MSAA_DISABLED
		root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	else:
		print("WARN no Terrain.set_camera(); frames will be of whatever LOD reaches the eye")

	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	if _look == null:
		print("WARN no WorldLook; the day/night pin cannot be applied or frozen")
	if _weather == null:
		print("WARN no WorldWeather; weather cannot be pinned to clear")

	# Say out loud which site nodes answered, because a missing node does not
	# make a shot fail loudly -- it makes it fall back to the world origin and
	# photograph an empty meadow, which is the exact silence this sweep has
	# already spent three rounds on.
	for node_name: String in ["Village", "OldQuarry", "BurrowWarrens", "TetherRelay",
			"Stronghold", "StrongholdSilhouette", "MillCrossing", "VillageNPCs",
			"RelayNPCs", "Trainers", "EncounterDirector"]:
		if _world.get_node_or_null(NodePath(node_name)) == null:
			print("WARN site node %s is not in the tree" % node_name)

	# `--only=` takes a COMMA-SEPARATED list, not one substring. A survey's
	# frames are not all invalidated together -- this run's first pass left
	# exactly two sites needing another shutter out of eleven, and matching one
	# substring would have meant two full boots to fix them.
	var only: Array[String] = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			for piece: String in arg.substr(7).split(",", false):
				var trimmed := piece.strip_edges()
				if trimmed != "":
					only.append(trimmed)
	if not only.is_empty():
		print("[locations] --only=%s: re-shooting matching sites only" % ", ".join(only))

	await _pin("day")
	for entry: Variant in SITES:
		var site: Dictionary = entry as Dictionary
		if _selected(only, str(site["id"])):
			await _shoot_site(site, "day")

	if _any_night(only):
		await _pin("night")
		for entry: Variant in SITES:
			var site: Dictionary = entry as Dictionary
			if bool(site.get("night", false)) and _selected(only, str(site["id"])):
				await _shoot_site(site, "night")

	print("")
	print("locations survey: %d frames written, %d failed, into %s" % [
		_written, _failures, OUT_DIR])
	print("Software rendering under the Compatibility renderer: composition,")
	print("density and silhouette are trustworthy; frame times are not a")
	print("performance measurement.")
	quit(0 if _failures == 0 else 1)


func _selected(only: Array[String], site_id: String) -> bool:
	if only.is_empty():
		return true
	for want: String in only:
		if want in site_id:
			return true
	return false


## Skip the night pin entirely when nothing selected shoots at night -- it is
## 30 awaited frames, and a targeted re-shoot of two daylight sites should not
## pay a minute to pin a clock it never uses.
func _any_night(only: Array[String]) -> bool:
	for entry: Variant in SITES:
		var site: Dictionary = entry as Dictionary
		if bool(site.get("night", false)) and _selected(only, str(site["id"])):
			return true
	return false


## Pin the clock to `time`, then STOP both clocks. Order matters and freezing
## matters: a pin that is not frozen wears off across a multi-site pass and the
## late frames come back in a dusk wash under whatever weather rolled.
##
## R6-CLOCK-FREEZE. `_look.set_process(true)` here used to stay true for the
## whole 30-frame wait below, on the (false) assumption that apply_time()
## needed a live `_process` to take effect -- it does not, it is an ordinary
## synchronous write (see the sibling tools/_capture_ground_and_sky.gd's own
## header, which freezes WorldLook once and never unfreezes it for exactly
## this reason). Those 30 unfrozen frames instead let world_look.gd's passive
## clock advance `_elapsed_seconds` on every one of them; under software
## rendering that is tens of real seconds, which at day_length_seconds/24 =
## 25 real seconds per in-game hour is enough to walk a "night" pin most of
## the way back toward day before the first shot ever fires. Freezing the
## clock (rather than toggling `_look`'s whole `_process`) keeps apply_time()
## pinned through the wait without needing that wait at all -- kept anyway so
## an older WorldLook without set_clock_frozen (has_method guard below) still
## gets the previous, drift-prone-but-working behaviour instead of a hard fail.
func _pin(time: String) -> void:
	if _weather != null:
		_weather.set_process(true)
		_weather.set_physics_process(true)
		_weather.call("set_weather", "clear")
	var look_frozen := _look != null and _look.has_method("set_clock_frozen")
	if _look != null:
		if look_frozen:
			_look.call("set_clock_frozen", true)
		else:
			_look.set_process(true)
			_look.set_physics_process(true)
		_look.call("apply_time", time)
	for i in _frames(30):
		await physics_frame
	if _weather != null:
		_weather.set_process(false)
		_weather.set_physics_process(false)
	if _look != null and not look_frozen:
		_look.set_process(false)
		_look.set_physics_process(false)
	print("[locations] clock pinned to %s and frozen" % time)


## A site is arrived at ONCE. The first shot pays the full Terrain3D stream and
## encounter-director settle; the two after it are a camera move inside a
## region that is already standing, so they cost a hop.
func _shoot_site(site: Dictionary, suffix: String) -> void:
	var site_id: String = str(site["id"])
	var shots: Array = site["shots"] as Array
	print("[%s] %s" % [site_id, suffix])
	for i in shots.size():
		var shot: Dictionary = shots[i] as Dictionary
		await _shoot(site_id, shot, suffix, i == 0)


func _shoot(site_id: String, shot: Dictionary, suffix: String, first: bool) -> void:
	var label: String = str(shot["label"])
	var frame_name := "%s-%s" % [site_id, label]
	var resolved := _resolve(shot)
	if resolved.is_empty():
		print("  FAIL %s-%s: could not resolve its viewpoint" % [frame_name, suffix])
		_failures += 1
		return

	var eye: Vector2 = resolved["eye"]
	var target: Vector2 = resolved["look"]
	var floor_hint: float = resolved["floor"]
	var look_hint: float = resolved["look_floor"]
	if eye.is_equal_approx(target):
		print("  FAIL %s-%s: eye and look resolved to the same point" % [frame_name, suffix])
		_failures += 1
		return

	var look_up := float(shot.get("look_up", 1.6))
	var mode: String = str(shot.get("mode", "standing"))
	var default_rig: Dictionary = RIG.get(mode, RIG["standing"]) as Dictionary
	var back_m := float(shot.get("back", default_rig["back"]))
	var up_m := float(shot.get("up", default_rig["up"]))

	var toward := (target - eye).normalized()
	eye = _clear_of_bodies(eye, toward, _ground_at(eye, floor_hint))
	var back := eye - toward * back_m

	if first:
		# Pass one: the analytic seat, so Terrain3D has somewhere to stream to.
		# There is no collision to raycast against until the camera is already
		# standing there, so the real seat cannot be asked for yet. An interior
		# shot skips this entirely -- its floor is a built box, not terrain, and
		# the analytic heightfield under a cave is metres of solid rock.
		var seat: float = _ground_at(eye, floor_hint) if _is_interior(floor_hint) else float(_field.height_at(eye.x, eye.y))
		_place(eye, seat)
		_frame(back, _ground_at(back, floor_hint), target, _ground_at(target, look_hint), up_m, look_up)
		for i in _frames(ARRIVE_FRAMES):
			await physics_frame

	var ground := _ground_at(eye, floor_hint)
	_place(eye, ground)
	_frame(back, _ground_at(back, floor_hint), target, _ground_at(target, look_hint), up_m, look_up)
	for i in _frames(SETTLE_FRAMES if first else HOP_FRAMES):
		await physics_frame

	_hide_huds()
	_frame(back, _ground_at(back, floor_hint), target, _ground_at(target, look_hint), up_m, look_up)
	for i in _frames(POSE_FRAMES):
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("  FAIL %s-%s: viewport returned no image" % [frame_name, suffix])
		_failures += 1
		return
	var path := "%s/%s-%s.png" % [OUT_DIR, frame_name, suffix]
	if image.save_png(path) != OK:
		print("  FAIL %s-%s: save_png" % [frame_name, suffix])
		_failures += 1
		return
	_written += 1
	var here := Vector3(eye.x, ground, eye.y)
	var cam_player_dist := _camera.global_position.distance_to(_player.global_position)
	print("  %-26s %-5s eye(%.0f, %.1f, %.0f)  %d creatures, %d people within 160m  cam-player %.1fm" % [
		frame_name, suffix, eye.x, ground, eye.y, _creatures_near(here), _people_near(here), cam_player_dist])
	if cam_player_dist > MAX_CAMERA_PLAYER_DISTANCE:
		push_warning("_capture_locations.gd: %s-%s stands %.1fm from the player (max %.1fm) -- Terrain3D streaming may be degraded for this frame" % [
			frame_name, suffix, cam_player_dist, MAX_CAMERA_PLAYER_DISTANCE])


## Turn a shot's declared viewpoint into world metres. Three declaration forms,
## and the order here is the order of trust: a site node's own placement API
## beats a local frame, which beats a raw world pair.
##
## The eye and the look target carry SEPARATE floors, and that separation is
## the fix for a bug this file had on its first parse-clean draft. A shot at
## the warrens mouth looks at the `hall` marker, which is underground: taking
## the target's height from the ordinary downward raycast returns the MOUND'S
## ROOF, and `look_at` then aims the camera up the outside of the hill instead
## of into the cave. Same shape of error inside the stronghold. So a point that
## came from a marker keeps the marker's own Y -- that Y IS the chamber floor,
## built by the site's own `to_global()` -- and only a point that had to be
## ray-seated asks the terrain.
##
## A marker's Y stops being authoritative the moment an `offset` moves the
## point off it, because the offset is in world axes and the floor it was
## measured on is a room the offset may have left.
func _resolve(shot: Dictionary) -> Dictionary:
	var floor_y := NAN
	var look_floor := NAN
	var eye := Vector2.ZERO
	var look := Vector2.ZERO

	if shot.has("marker"):
		var spec: Array = shot["marker"] as Array
		var got := _marker(str(spec[0]), str(spec[1]))
		if is_nan(got.y):
			return {}
		eye = Vector2(got.x, got.z)
		floor_y = got.y
	elif bool(shot.get("relay", false)):
		var local: Array = shot["at"] as Array
		var mapped: Variant = _relay_world(Vector2(float(local[0]), float(local[1])))
		if mapped == null:
			return {}
		eye = mapped as Vector2
	else:
		var at: Array = shot["at"] as Array
		eye = Vector2(float(at[0]), float(at[1]))

	if shot.has("offset"):
		var off: Array = shot["offset"] as Array
		eye += Vector2(float(off[0]), float(off[1]))
		floor_y = NAN

	if shot.has("look_marker"):
		var lspec: Array = shot["look_marker"] as Array
		var lgot := _marker(str(lspec[0]), str(lspec[1]))
		if is_nan(lgot.y):
			return {}
		look = Vector2(lgot.x, lgot.z)
		look_floor = lgot.y
	elif bool(shot.get("relay", false)):
		var llocal: Array = shot["look"] as Array
		var lmapped: Variant = _relay_world(Vector2(float(llocal[0]), float(llocal[1])))
		if lmapped == null:
			return {}
		look = lmapped as Vector2
	else:
		var l: Array = shot["look"] as Array
		look = Vector2(float(l[0]), float(l[1]))

	# `pull_back` stands the eye off along the line the look target already
	# defines, rather than at a world coordinate someone had to reason about a
	# site yaw to write down. The stronghold is the case that forced it: its
	# route is yawed 90 degrees, so the gate faces west, and an "approach" eye
	# placed due south of the site centre photographs a side wall.
	if shot.has("pull_back"):
		var away := (eye - look).normalized()
		if away.is_zero_approx():
			print("  WARN pull_back has no direction; eye and look coincide")
			return {}
		eye += away * float(shot["pull_back"])
		floor_y = NAN
	return {"eye": eye, "look": look, "floor": floor_y, "look_floor": look_floor}


## Ask a site node where one of its own marks is, in world metres. Both
## `stronghold.gd` and `burrow_warrens.gd` build these with `to_global()` from
## their config's chamber list, so the answer already carries the site's yaw
## and its ground snap. Returns a NaN-y Vector3 when the node or the mark is
## missing, and says which, because a silent Vector3.ZERO here photographs the
## world origin and reads as "the site did not build".
func _marker(node_name: String, key: String) -> Vector3:
	var node: Node = _world.get_node_or_null(NodePath(node_name))
	if node == null or not node.has_method("marker"):
		print("  WARN %s has no marker() to ask for '%s'" % [node_name, key])
		return Vector3(NAN, NAN, NAN)
	if node.has_method("has_marker") and not bool(node.call("has_marker", key)):
		print("  WARN %s has no mark '%s'; it knows %s" % [
			node_name, key,
			str(node.call("marker_names")) if node.has_method("marker_names") else "(unlisted)"])
		return Vector3(NAN, NAN, NAN)
	var got: Vector3 = node.call("marker", key)
	if got.is_equal_approx(Vector3.ZERO):
		print("  WARN %s.marker('%s') is the world origin; treating as missing" % [node_name, key])
		return Vector3(NAN, NAN, NAN)
	if _is_marker_fallback(node, got):
		print("  WARN %s does not know the mark '%s'; marker() fell back to the node's own position" % [
			node_name, key])
		return Vector3(NAN, NAN, NAN)
	return got


## The relay's yard is authored in its own (s,t) frame off a -34.4 degree
## approach bearing. `tether_relay.gd::world_of` is the builder's own mapping;
## re-deriving it here would be a second copy of a rotation that has already
## moved once (OW5D) and would be wrong the next time it moves.
func _relay_world(local: Vector2) -> Variant:
	var node: Node = _world.get_node_or_null(^"TetherRelay")
	if node == null or not node.has_method("world_of"):
		print("  WARN TetherRelay has no world_of(); its yard cannot be framed")
		return null
	return node.call("world_of", local) as Vector2


func _is_interior(floor_hint: float) -> bool:
	return not is_nan(floor_hint)


## Interiors are built boxes: their floor is the marker's own Y and a downward
## raycast from 400 m up would return the mound's roof or the keep's ceiling.
## Everything else gets the streamed collision surface.
func _ground_at(at: Vector2, floor_hint: float) -> float:
	if _is_interior(floor_hint):
		return floor_hint
	return _surface(at)


## `marker()` on `burrow_warrens.gd` returns the NODE'S OWN POSITION for a key
## it does not know -- a documented fallback, not a bug, but one that resolves
## silently to the site's mouth and would photograph the wrong room while every
## line of output looked healthy. `stronghold.gd` has `has_marker()` and is
## checked directly; the warrens have not, so the fallback is detected by
## recognising it.
func _is_marker_fallback(node: Node, got: Vector3) -> bool:
	var node3d: Node3D = node as Node3D
	if node3d == null:
		return false
	return got.distance_to(node3d.global_position) < 0.01


## A HUD that did not exist at boot -- a combat HUD, a prompt, an interaction
## card raised by standing next to something -- is still a HUD in the frame.
## Re-hidden before every shutter, shallowly: the deep walk is 143,630 nodes
## and CanvasLayers are never buried inside the scatter.
func _hide_huds() -> void:
	for node in _world.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
	for node in root.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false


## Trainer and villager bodies (`npc_body.gd`) are STATIC capsule colliders
## parked dead-centre on their own authored `position`, and this survey seats
## itself on authored site coordinates by design -- so it is the tool in this
## sweep MOST likely to land on one, not least. A player capsule spawned
## centred on another capsule has no lateral escape vector, so Godot's
## depenetration shoves it straight UP the shared axis: that is the "trainer
## standing on the NPC's head" a blind critic found in three corridor frames
## and a second critic found again in three ground frames after the corridor's
## fix was not ported. No walking player ever produces it. Step the seat aside
## before framing rather than photograph the harness's own mistake.
func _clear_of_bodies(eye: Vector2, toward: Vector2, ground: float) -> Vector2:
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return eye
	# Perpendicular to the view line, so a step aside barely changes the shot.
	var aside := Vector2(-toward.y, toward.x).normalized()
	# Remembered across attempts, because `blocker` is empty on the attempt
	# that SUCCEEDS -- reporting it there named nothing and made the NOTE read
	# "was occupied by ", which is exactly the kind of silent diagnostic this
	# survey exists to avoid.
	var occupant := ""
	for attempt in 4:
		var candidate := eye if attempt == 0 else eye + aside * 2.0 * float(attempt)
		var query := PhysicsShapeQueryParameters3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.6
		capsule.height = 2.6
		query.shape = capsule
		# Lifted 0.15m off `ground`: a capsule resting on the ramp/floor body
		# the eye was just ray-seated onto is not "occupied" -- at ground+1.3
		# the capsule's own bottom touched that surface and intersect_shape
		# reported it as a blocker (only `Terrain` bodies are filtered out).
		query.transform = Transform3D(Basis(), Vector3(candidate.x, ground + 1.45, candidate.y))
		query.collide_with_bodies = true
		query.collide_with_areas = false
		if _player != null:
			query.exclude = [_player.get_rid()]
		var blocker := ""
		for hit: Dictionary in space.intersect_shape(query, 4):
			var body: Node = hit.get("collider") as Node
			if body == null or _under_terrain(body):
				continue
			blocker = body.name
			if occupant == "":
				occupant = body.name
			break
		if blocker == "":
			if attempt > 0:
				print("  NOTE (%.0f,%.0f) was occupied by %s; landing moved %.1fm aside" % [
					eye.x, eye.y, occupant, (candidate - eye).length()])
			return candidate
	print("  WARN (%.0f,%.0f) is occupied by %s and four steps aside did not clear it" % [
		eye.x, eye.y, occupant])
	return eye


## Terrain3D's own collision is a StaticBody3D too, and the occupancy capsule's
## lower edge can graze a slope. Only a body OUTSIDE the Terrain node counts as
## something worth stepping around.
func _under_terrain(body: Node) -> bool:
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain == null:
		return false
	var node: Node = body
	while node != null:
		if node == terrain:
			return true
		node = node.get_parent()
	return false


func _place(at: Vector2, ground: float) -> void:
	_player.global_position = Vector3(at.x, ground + 0.4, at.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO


func _frame(eye: Vector2, eye_ground: float, target: Vector2, target_ground: float,
		up_m: float, look_up: float) -> void:
	_camera.global_position = Vector3(eye.x, eye_ground + up_m, eye.y)
	# Aimed at chest height on the target by default, so a shot that is about a
	# building is not composed as a shot about the dirt. `look_up` raises that
	# for the shots where the subject is genuinely overhead: a 70-degree camera
	# is about +/-23 degrees vertically, which at 20 m reaches 8.7 m, so a
	# castle banner at 13.2 m composed on the ground line is simply not in the
	# picture that is supposed to be asking about it.
	_camera.look_at(Vector3(target.x, target_ground + look_up, target.y), Vector3.UP)


## The analytic heightfield and the streamed collision surface disagree -- by
## nearly 3 m on ordinary ground and up to 22 m near the river channel. Seating
## an eye on the analytic value buries the camera inside the terrain wherever
## the real ground is higher, and what comes back is the UNDERSIDE of the
## ground: a flat dead-coloured plane with the world ending in mid-air above
## it, which a critic reported as a water plane because there was no way to
## know better. Raycast, and say so out loud when the ray misses.
func _surface(at: Vector2) -> float:
	var analytic: float = _field.height_at(at.x, at.y)
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return analytic
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 400.0, at.y), Vector3(at.x, analytic - 400.0, at.y))
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		print("  WARN no collision under (%.0f, %.0f); analytic %.2f may be under the surface" % [
			at.x, at.y, analytic])
		return analytic
	return float((hit["position"] as Vector3).y)


## How populated the frame's neighbourhood actually is, printed beside every
## shot, and the check that SETTLE_FRAMES is still long enough.
##
## Asked the director rather than walked from the scene tree: `is_in_group(
## "creatures")` returns zero -- `encounter_director.gd` puts spawned bodies in
## no group at all -- and a name walk over 143,630 props costs more than the
## shot does. `wild_creatures()` is the director's own registry.
func _creatures_near(at: Vector3) -> int:
	var director: Node = _world.get_node_or_null(^"EncounterDirector")
	if director == null or not director.has_method("wild_creatures"):
		return -1
	var n := 0
	for wild: Variant in director.call("wild_creatures"):
		var body: Node3D = wild as Node3D
		if body != null and is_instance_valid(body):
			if body.global_position.distance_to(at) <= 160.0:
				n += 1
	return n


## The people count is the other half of "is this a place". A site with props
## and no one in it is the defect this survey exists to photograph, and a
## number beside the frame is what turns "it feels empty" into a fact the next
## round can compare against.
##
## Walked from the three placer containers rather than the whole tree, for the
## same cost reason as above: these hold tens of bodies, the world holds
## 143,630 props.
func _people_near(at: Vector3) -> int:
	var n := 0
	for container_name: String in ["VillageNPCs", "RelayNPCs", "Trainers"]:
		var container: Node = _world.get_node_or_null(NodePath(container_name))
		if container == null:
			continue
		for child in container.get_children():
			var body: Node3D = child as Node3D
			if body != null and is_instance_valid(body):
				if body.global_position.distance_to(at) <= 160.0:
					n += 1
	return n


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out
