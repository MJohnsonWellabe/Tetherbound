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
## forever with no error (ralph/conventions.md, "Art pipeline traps").
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
## separate times (ralph/VISUAL_LEDGER.md, "This sweep's own harness defects"):
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
			{"label": "route-out", "mode": "standing", "at": [10.0, -10.0], "look": [-14.0, 14.0],
			 "_why": "T1-VILLAGE 2026-08-30. Standing at the well (paths.routes' own hub) looking down the FIRST leg of the 'Pond' route (terrain_playground.json paths.routes[2]: [10,-10] -> [-14,14] -> ... -> [-105,115]), the bearing toward the pond valley and the open basin band1/spawns.json's own comment calls Creek Hollow. sec12 asks for a composed sightline out of the village toward the early-adventure route; this is the one this file has never shot."}
		]
	},
	{
		"id": "02-mill-pond",
		"night": false,
		"_why": "data/config/village.json's OW5D-relocated pond group: mill [-382,514], footbridge [-386.3,520], ranger_station [-350,507]; band1 props.json `bridge_repair_site` centroid [-391.4,521.1].",
		"shots": [
			{"label": "approach", "mode": "approach", "at": [-330.0, 492.0], "look": [-350.0, 507.0],
			 "_why": "the pond route's own first waypoint. village.json's ranger_station entry names the route as points [-80,85] -> [-105,115] in the pre-OW5D frame; the OW5D offset is (-250,+407), so the route runs (-330,492) -> (-355,522) now. Standing at its head looks at the ranger station -- 'the first built thing between the settlement and the pond valley' in that file's own words -- with the mill beyond it.\n\nThe first draft of this eye was (-352,545) and the raycast reported no collision under it with an analytic height of -20.20 against a pond surface at -17.0: it was IN THE WATER, 38m north of the ranger station. Kept in the comment rather than silently corrected, because 'a plausible-looking coordinate 40m from the thing it names' is how this sweep has produced six frames of the wrong subject."},
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
			 "look_marker": ["BurrowWarrens", "guardian"],
			 "_why": "standing in the guardian's chamber looking at the guardian -- the deepest authored room and the thing in it that gives the warrens their identity. No offset: the site is yawed 315 degrees, so a world-axis nudge does not stay inside the room it was measured in, and an offset also forfeits the marker's authoritative floor Y."}
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
			{"label": "approach", "mode": "approach", "relay": true, "at": [-46.0, 0.0], "look": [-14.0, 0.0],
			 "_why": "32m out on the gate's own axis, outside the front wall line"},
			{"label": "standing", "mode": "standing", "relay": true, "at": [-8.0, -2.0], "look": [7.0, -9.0],
			 "_why": "just inside the gate on the yard floor, looking at the apparatus on its pad"},
			{"label": "apparatus", "mode": "detail", "relay": true, "at": [1.0, -4.0], "look": [7.0, -9.0],
			 "back": 3.0, "up": 2.4, "look_up": -2.1,
			 "_why": "the relay apparatus itself -- a Team Tether hero object, and the site's identity.\n\nROUND 2 (tools/_probe_detail_shots.gd): this is the critic's own named case -- 'an apparatus on a 10m deck'. tether_relay.json sets `deck_y` 10.0 and the installed hero mesh (`Model`, under `ApparatusSeam`) measures y 10.00..14.20, 6.67m across, centred on world y 12.10. The bare RIG's `look_up` 1.6 means nothing at this look point: the ground raycast here does not find the compound floor at all, it hits the APPARATUS'S OWN box collider top at y 14.20 (proven by the eye/back ground sweep sitting flat at 4.9-5.8 everywhere EXCEPT this one point, and by 14.20 matching `Model`'s own measured top to the centimetre) -- so `look_up` 1.6 aimed 1.6m ABOVE the apparatus's own peak, at open sky, which is exactly the 'shot about the dirt' failure mode inverted (a shot about the sky over the hero object instead of the hero object). `look_up` -2.1 reconstructs the apparatus's true centre height through that same ground reading (14.20 - 2.1 = 12.10), which is the only way to aim at it correctly given `_ground_at` returns that collider hit either way. `back` 3.0 is this round's ruler floor -- the FOV fit alone only needs 4.81m of camera-to-look distance and the eye already stands 7.81m off, so no extra `back` was owed for size. `up` 2.4 puts the camera at world y ~7.4 at this back (ground under the camera itself reads normally, ~4.96, since the collider-hit only happens exactly at the apparatus's own footprint) -- BELOW the 10.0m deck, so the shot looks UP at the apparatus the way an object standing on a raised pad over a person's head should be seen, rather than being framed at deck height or above it."}
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
			{"label": "fire", "mode": "detail", "at": [-230.0, 6471.0], "look": [-233.1, 6474.3],
			 "back": 3.0, "up": 2.2, "look_up": -5.05,
			 "_why": "the bonfire and its stone ring, the camp's one warm thing.\n\nROUND 2 (tools/_probe_detail_shots.gd): this is the critic's other named case -- 'a fire on the ground'. `Bonfire_Fire` (this look point IS its authored position, unlike the relay camp's) measures y 2.69..8.34, but that top is `campfire_glow.gd`'s own smoke column (`SMOKE_TOP_HEIGHT` 4.6, counter-scaled to stay absolute regardless of the log model's 0.38 scale) reaching into the box collider the ground raycast at this exact look point then hits -- confirmed the same way as the apparatus: the eye/back sweep sits flat at 2.7-4.1 everywhere except this one point (8.34), and 8.34 matches the fire's own measured top. Aiming at the geometric CENTRE of that box (y 5.51, roughly the smoke column's own midpoint) would point at thin rising smoke, not the fire -- the flame/embers/light that give a campfire its identity sit within `campfire_glow.gd`'s own constants (`EMBER_HEIGHT` 0.85, `LIGHT_HEIGHT` 0.55) of the base, so the aim height used here is base + 0.6 = 3.29, not the tall box's centre. `look_up` -5.05 reconstructs that through the same collider-hit ground reading (3.29 = 8.34 - 5.05). `back` 3.0 (this round's ruler floor) comfortably covers the tighter fit that aim needs (4.58m unmargined, against 2.83m if the whole smoke column were the target). `up` 2.2 puts the camera clearly above the flame's own height at this back (ground under the camera reads ~2.97, a real value off the fire's own footprint), looking down into the fire the way the task's own guidance for this exact case asks for, rather than level with a point of thin smoke."}
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
			 "_why": "standing in the courtyard looking on toward the tether approach. This is where oxblood belongs and where the structures round found none. No offset, for the same reason as the warrens den: site yaw 90 rotates every local, and the marker's own Y is the floor."}
		]
	},
	{
		"id": "11-castle-landmark",
		"night": false,
		"_why": "The OTHER stronghold. `scripts/world/landmark.gd` builds building_prefabs.json's `castle` -- 132 modules, four corner towers, a two-module gate and nine oxblood `Banner` modules -- at RISE_CENTRE + OFFSET = (140,-90) + (89.8,-54.4) = (229.8,-144.4), two hardcoded constants from the pre-corridor world. That is 7,708 m from the stronghold the player actually reaches at (0,7560), and `castle` is referenced in exactly one file.\n\nThis site is shot for one reason: to decide which of two very different fixes the structures round's 'the castle is untextured blockout, no stone material, no crenellation, no banners' actually needs. If the castle renders CORRECTLY here, in the world, then the art is fine and the defect is siting -- a const that OW5D's relocation left behind. If it renders as untextured blockout HERE too, then its retint or its OBJ/MTL materials are not loading and that is a material bug to fix, not a coordinate. The structures survey shoots prefabs on a bare stage, so it cannot tell those two apart; this can.\n\nThe gate faces local -z (its two TallWallEntrance modules sit at local x 2.0, z -8.448, and all nine banners hang between z -9.648 and -11.8). landmark.gd sets no rotation, so local -z is world -z: the gate faces south and every eye below stands south of the site.",
		"shots": [
			{"label": "approach", "mode": "approach", "at": [231.8, -214.0], "look": [231.8, -150.0],
			 "back": 10.0, "up": 5.0, "look_up": 8.0,
			 "_why": "64m due south of the gate on its own axis, aimed 8m up so the towers and the keep cap at 21.7m are in frame rather than cropped at the wall line"},
			{"label": "gate", "mode": "standing", "at": [231.8, -166.0], "look": [231.8, -152.0],
			 "look_up": 5.0,
			 "_why": "at the gate, eye height, where a player would stand to walk in"},
			{"label": "banners", "mode": "detail", "at": [217.4, -172.0], "look": [217.4, -154.0],
			 "back": 8.0, "up": 2.2, "look_up": 9.5,
			 "_why": "the west gate flank, where four Banner modules hang at 6.4m and 13.2m. Aimed 9.5m up because a shot composed on the ground line crops the very thing it is asking about -- the oxblood the structures round went looking for and did not find."}
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


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
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
func _pin(time: String) -> void:
	if _weather != null:
		_weather.set_process(true)
		_weather.set_physics_process(true)
		_weather.call("set_weather", "clear")
	if _look != null:
		_look.set_process(true)
		_look.set_physics_process(true)
		_look.call("apply_time", time)
	for i in 30:
		await physics_frame
	if _weather != null:
		_weather.set_process(false)
		_weather.set_physics_process(false)
	if _look != null:
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
		for i in ARRIVE_FRAMES:
			await physics_frame

	var ground := _ground_at(eye, floor_hint)
	_place(eye, ground)
	_frame(back, _ground_at(back, floor_hint), target, _ground_at(target, look_hint), up_m, look_up)
	for i in (SETTLE_FRAMES if first else HOP_FRAMES):
		await physics_frame

	_hide_huds()
	_frame(back, _ground_at(back, floor_hint), target, _ground_at(target, look_hint), up_m, look_up)
	for i in POSE_FRAMES:
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
	print("  %-26s %-5s eye(%.0f, %.1f, %.0f)  %d creatures, %d people within 160m" % [
		frame_name, suffix, eye.x, ground, eye.y, _creatures_near(here), _people_near(here)])


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
		query.transform = Transform3D(Basis(), Vector3(candidate.x, ground + 1.3, candidate.y))
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
