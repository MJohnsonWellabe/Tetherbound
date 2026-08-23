extends SceneTree

## The download page's STORY frames, captured from the real game.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_site_story.gd
##
## `capture_site_shots.gd` shoots the opening beats around Grandpa's house.
## This is its sibling for everything the 2026-08-22 story rewrite of
## `site/index.html` actually needs and did not have: the village as a place
## with people in it, a villager mid-conversation, one of the seven severed
## roads, the Tether Relay's machinery, the stronghold at the distance the
## player first sees it, and the Old Mill Crossing.
##
## Same honesty rule as `tools/survey.sh` and `site/README.md`: these are real
## frames, no touch-ups, and a caption on the page may only claim what the
## frame shows.
##
## Vertical placement is DERIVED, never hardcoded: every eye and target is an
## XZ plus a height above the live terrain, because the authored sites have
## been relocated wholesale before (`OW5D`) and the last set of hardcoded
## coordinates left a camera inside a roof for months. `landmarks` below are
## the same numbers `data/config/map_landmarks.json` publishes, read from that
## file rather than copied, so a relocation moves these frames with it.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/story"
const LANDMARKS := "res://data/config/map_landmarks.json"
const SETTLE_FRAMES := 30
## Terrain3D streams regions toward the camera, and these viewpoints jump
## kilometres between shots -- the relay is 3.8km from the village and the
## stronghold 7.6km. A short settle renders the hole.
const PER_SHOT_FRAMES := 24


## name -> {eye_xz, eye_h, look_xz, look_h, [time], [dialogue], [player_xz]}.
## `eye_h`/`look_h` are metres above the terrain at that XZ.
##
## A shot may instead carry `focus_node` (a node name) plus `focus_offset`
## (Vector3, metres from that node) and `focus_aim_h` (metres above its origin
## to look at). Used for the legendary, which stands on an interior floor the
## terrain heightfield knows nothing about.
var _shots: Array = []


func _init() -> void:
	_run()


func _landmark(marks: Dictionary, id: String, fallback: Vector2) -> Vector2:
	for entry: Variant in marks.get("landmarks", []):
		if (entry as Dictionary).get("id", "") == id:
			var at: Array = (entry as Dictionary).get("position", [])
			if at.size() == 2:
				return Vector2(float(at[0]), float(at[1]))
	push_warning("landmark %s not in map_landmarks.json; using fallback" % id)
	return fallback


func _build_shots() -> void:
	var marks: Dictionary = {}
	var text := FileAccess.get_file_as_string(LANDMARKS)
	if not text.is_empty():
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary:
			marks = parsed as Dictionary

	var village := _landmark(marks, "village", Vector2(10.0, -10.0))
	var relay := _landmark(marks, "tether_relay", Vector2(350.0, 3760.0))
	var stronghold := _landmark(marks, "stronghold", Vector2(0.0, 7560.0))
	var mill := _landmark(marks, "old_mill_crossing", Vector2(-152.0, 4203.0))

	_shots = [
		# The square, from the lane on its south-east side looking across the
		# well at the workshop -- the composition the village was authored
		# around (`data/config/village.json`: the well is the square's centre,
		# the workshop the big building north of it).
		# Eye well clear of every structure in village.json -- the first cut at
		# [23, 1] was 8m from the cottage at [18, -2] and rendered its gable,
		# which is the same failure `capture_site_shots.gd`'s village viewpoint
		# has had for months. Nothing is authored east of x=26, so the camera
		# stands out there and looks back down the lane at the well.
		{
			"name": "village-square",
			"eye_xz": Vector2(32.0, 9.0), "eye_h": 13.5,
			"look_xz": village, "look_h": 1.0,
		},
		# There is no `village-people` shot. Two attempts at an eye-level
		# villager frame both rendered a cottage wall -- the square is dense and
		# the villagers stand against their own houses -- and `village-talk`
		# below already puts a named villager, her portrait and her actual
		# dialogue on screen, which is the frame that was wanted anyway.
		# A villager mid-conversation, with the real dialogue panel on screen
		# running a real line out of data/dialogue/village.json. Every other
		# frame in this run hides the CanvasLayers; this one needs one back.
		{
			"name": "village-talk",
			"eye_xz": Vector2(16.2, 2.4), "eye_h": 1.75,
			"look_xz": Vector2(19.0, -1.0), "look_h": 1.5,
			"player_xz": Vector2(17.2, 1.4),
			"dialogue": "village_mira",
		},
		# Two of SA4's seven severed outward roads, framed from the road a short
		# walk short of the blocker. The coordinates come from
		# `data/config/terrain_playground.json`'s own `spokes.routes` -- last
		# road point and blocker centre -- and NOT from
		# `tools/capture_severed_spokes.gd`, whose viewpoints are pre-OW5B and
		# put the eye ~700m from where these roads now are. A run using them
		# photographed empty meadow, which is the exact stale-coordinate
		# failure this file's header is about.
		#
		# The Gate Road at the sealed arch: the road runs through it and it
		# does not open any more.
		{
			"name": "severed-road",
			"eye_xz": Vector2(-660.0, 2513.0), "eye_h": 2.8,
			"look_xz": Vector2(-688.9, 2517.9), "look_h": 3.2,
		},
		# The Blighted Road, sealed. Chosen over the Storm Road for the second
		# frame because the Storm Road's blocker sits 25m from the stronghold,
		# which currently renders as an untextured blockout and would be in
		# shot behind it.
		{
			"name": "storm-road",
			"eye_xz": Vector2(-600.0, 4118.0), "eye_h": 2.8,
			"look_xz": Vector2(-640.4, 4117.4), "look_h": 2.6,
		},
		# The Tether Relay from outside its wall: the compound, the pylon line
		# and the drained ground it stands in.
		{
			"name": "relay-approach",
			"eye_xz": relay + Vector2(-44.0, -30.0), "eye_h": 11.0,
			"look_xz": relay + Vector2(4.0, -6.0), "look_h": 2.5,
		},
		# The apparatus itself. tether_relay.json puts it at local [7, -9] with
		# its console at [2.9, -9]; this stands where a player disabling it
		# stands.
		# First cut stood at local [-6,-16], which is inside the compound's own
		# wall run and rendered masonry with the apparatus behind it. This eye
		# is outside the south-east corner, above deck height, looking back at
		# the apparatus on its deck.
		{
			"name": "relay-machines",
			"eye_xz": relay + Vector2(26.0, -26.0), "eye_h": 7.0,
			"look_xz": relay + Vector2(7.0, -9.0), "look_h": 3.0,
		},
		# SITE-SHOTS: a close relay frame -- pylon line, sagging conduit and
		# the pale drained ground under it, standing where a player on the
		# approach actually is rather than looking down at the compound from
		# outside its wall the way `relay-approach` does. Sited on the
		# west_run pylons in `tether_relay.json` (local s=-18..-10, t=-22..-19,
		# converted through that file's own site frame: world = centre +
		# s*(0.565,-0.826) + t*(0.826,0.565)) -- the run the player has
		# actually been following since the quarry.
		{
			"name": "tether-site",
			"eye_xz": relay + Vector2(-41.7, 7.8), "eye_h": 2.3,
			"look_xz": relay + Vector2(-15.2, -4.3), "look_h": 3.2,
		},
		# Meadows Hall at the distance it first reads as a destination rather
		# than a building -- 7.6km from the village, which is the point: the
		# old page implied it was on the ridge above the square.
		{
			"name": "stronghold-approach",
			"eye_xz": stronghold + Vector2(0.0, -210.0), "eye_h": 26.0,
			"look_xz": stronghold, "look_h": 12.0,
		},
		# The bound legendary, in the chamber under Meadows Hall, inside the
		# containment ring the machine holds it in. `stronghold_climax.gd`
		# builds `BoundLegendary` at world load, so this is the real thing in
		# the real room -- not a creature posed on a backdrop. It is the last
		# thing in the chapter and the page shows it deliberately: the owner
		# asked for it.
		{
			"name": "legendary-bound",
			"focus_node": "BoundLegendary",
			# Above the containment ring rather than through it: the cage bars
			# are vertical, so an eye-level camera puts three of them across
			# the animal. Looking down over the rim clears them.
			"focus_offset": Vector3(5.0, 5.2, 5.6),
			"focus_aim_h": 1.3,
		},
		# SITE-SHOTS: the Warden, in the Warden Arena chamber under Meadows
		# Hall -- `stronghold_climax.gd` names his trainer node `WardenTrainer`
		# and parents it to the world directly (not under the climax node),
		# so `focus_node` finds him the same way `legendary-bound` finds the
		# bound creature. The chamber is a closed room (stronghold.json's
		# `warden_arena`, 24x26m, height 11m), so this frame is clear of
		# `SKY-PLANES` -- that defect is StormWall slabs at the storm_road
		# blocker, a different site entirely, not anything visible indoors.
		{
			"name": "warden",
			"focus_node": "WardenTrainer",
			"focus_offset": Vector3(2.6, 1.7, 3.0),
			"focus_aim_h": 1.55,
		},
		{
			"name": "mill-crossing",
			"eye_xz": mill + Vector2(-34.0, -30.0), "eye_h": 11.0,
			"look_xz": mill + Vector2(2.0, 2.0), "look_h": 4.5,
		},
	]


func _hide_canvas_layers(root_node: Node, hide: bool) -> void:
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = not hide
		stack.append_array(node.get_children())


## The dialogue panel is instanced by the world rather than sitting at a fixed
## path, so find it by the API it exposes instead of by node path.
func _find_dialogue_panel(root_node: Node) -> Node:
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.has_method("start") and node.has_method("is_open") and node.has_method("advance"):
			return node
		stack.append_array(node.get_children())
	return null


func _find_named(root_node: Node, wanted: String) -> Node3D:
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.name == wanted and node is Node3D:
			return node as Node3D
		stack.append_array(node.get_children())
	return null


func _run() -> void:
	_build_shots()

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await process_frame

	_hide_canvas_layers(world, true)

	var camera := Camera3D.new()
	camera.fov = 62.0
	camera.far = 4000.0
	root.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var look: Node = world.get_node_or_null(^"WorldLook")
	var panel: Node = _find_dialogue_panel(world)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var written := 0
	for shot: Dictionary in _shots:
		var name: String = shot["name"]
		# Resumable: a full run is minutes under llvmpipe and does not fit one
		# timeout budget.
		if FileAccess.file_exists("%s/%s.png" % [OUT, name]):
			print("skip -> %s.png (already captured)" % name)
			continue

		if look != null:
			look.call("apply_time", String(shot.get("time", "day")))

		if shot.has("focus_node"):
			var target: Node3D = _find_named(world, String(shot["focus_node"]))
			if target == null:
				print("warn: %s not in the tree; skipping %s" % [shot["focus_node"], name])
				continue
			var origin: Vector3 = target.global_position
			camera.global_position = origin + (shot["focus_offset"] as Vector3)
			camera.look_at(origin + Vector3(0.0, float(shot["focus_aim_h"]), 0.0))
			if player != null:
				player.global_position = origin + Vector3(5000.0, 0.0, 0.0)
			for i in PER_SHOT_FRAMES:
				await process_frame
			root.get_texture().get_image().save_png("%s/%s.png" % [OUT, name])
			written += 1
			print("shot -> %s.png" % name)
			continue

		var eye_xz: Vector2 = shot["eye_xz"]
		var look_xz: Vector2 = shot["look_xz"]
		var eye_ground := float(world.call("ground_height_at", eye_xz.x, eye_xz.y))
		var look_ground := float(world.call("ground_height_at", look_xz.x, look_xz.y))
		if is_nan(eye_ground):
			eye_ground = 0.0
		if is_nan(look_ground):
			look_ground = 0.0

		# Park the player where the shot wants them, or 5km away so they are
		# not a body standing in the middle of a landscape frame.
		if player != null:
			if shot.has("player_xz"):
				var pxz: Vector2 = shot["player_xz"]
				var pg := float(world.call("ground_height_at", pxz.x, pxz.y))
				player.global_position = Vector3(pxz.x, (0.0 if is_nan(pg) else pg) + 0.1, pxz.y)
				player.look_at(Vector3(look_xz.x, player.global_position.y, look_xz.y))
			else:
				player.global_position = Vector3(eye_xz.x + 5000.0, 0.0, eye_xz.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO

		camera.global_position = Vector3(eye_xz.x, eye_ground + float(shot["eye_h"]), eye_xz.y)
		camera.look_at(Vector3(look_xz.x, look_ground + float(shot["look_h"]), look_xz.y))

		var wants_dialogue: bool = shot.has("dialogue") and panel != null
		if wants_dialogue:
			_hide_canvas_layers(world, false)
			var started: bool = bool(panel.call("start", String(shot["dialogue"])))
			if not started:
				print("warn: dialogue %s did not start" % shot["dialogue"])

		for i in PER_SHOT_FRAMES:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT, name])
		written += 1
		print("shot -> %s.png" % name)

		if wants_dialogue:
			if bool(panel.call("is_open")):
				panel.call("close")
			_hide_canvas_layers(world, true)

	print("done: %d written, %d total in %s" % [written, _shots.size(), OUT])
	quit(0)
