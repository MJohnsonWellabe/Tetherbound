extends SceneTree

## Every building and every player-buildable structure, photographed for a
## blind visual critic: the 18 `data/config/building_prefabs.json` recipes,
## the 9 `data/items/buildables.json` pieces (camp, floor, wall, door, roof,
## fence, workbench, storage, creature_bed), and the assembled village square
## as a place. One standard establishing frame plus one close frame per
## structure, THE SAME 1.80 m TRAINER (`scenes/player/player.tscn`) standing
## beside every single one of them as the ruler -- criterion 8 (scale
## agreement, `.claude/skills/visual-judge/SKILL.md`) is unanswerable without
## it, and a doorway a person cannot walk through is a defect only visible
## with them in frame.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_structures.gd
##
## NEVER `--headless` with `--rendering-driver opengl3`: verified 2026-08-22
## (docs/AGENT_WORKFLOW.md, "Art pipeline traps") that combination hangs
## forever with no error and no crash -- it prints its first line and then
## sits in silence until killed, leaving a zombie Godot process pinned to
## this worktree burning CPU. Drop `--headless`, keep `xvfb-run` for the
## virtual display.
##
## ## Supersedes tools/capture_buildings.gd -- does not touch it
##
## `capture_buildings.gd` boots the full `meadows_playground.tscn` (village,
## vegetation scatter, stronghold, ~130k+ instances) for nine fixed
## exploration viewpoints of the settlement as it is SITED in the world, and
## none of it puts a 1.80m ruler in frame. That tool is left alone -- it
## still answers its own question (does the settlement read right from the
## paths a player actually walks) -- but it cannot answer this task's
## question (does EVERY prefab, including the ten this repo has added since
## R9.4 wrote that file, hold up against a ruler) without either a full-world
## boot per structure (ruinously slow, see the frame budget below) or
## teaching it to carry a player around, which is most of this file. This
## tool photographs every prefab and every buildable STANDALONE instead --
## see "Why standalone" below -- which is the only way the frame budget
## clears twenty minutes at all.
##
## ## Why standalone, not `meadows_playground.tscn`
##
## `tools/_probe_corridor_survey.gd` measured the real cost on this box:
## ~2.4s per awaited frame under llvmpipe software rendering, driven by the
## full world's 143,630 scattered props -- NOT by resolution or by what the
## camera happens to be pointed at. Every frame this tool awaits pays that
## same per-frame tax regardless of scene weight, so the only lever is
## fewer, lighter awaited frames.
##
## `scripts/world/building_prefabs.gd::instantiate(name)` builds any of the
## 18 recipes from its own JSON with no world dependency at all (confirmed:
## `landmark.gd` calls it directly for the castle, and every "castle" `_why`
## comment in the JSON is written assuming exactly this path). Every
## player-buildable piece is the same story -- `build_piece.gd`,
## `camp.gd`, `build_door.gd`, `storage_container.gd` and `creature_bed.gd`
## all expose a no-argument `build_real()` requiring nothing but being
## parented somewhere in a live tree (`tools/capture_site_shots.gd` and
## `tools/capture_build_kit_house.gd` already do exactly this). So every shot
## here is: one small flat pad, one sun, the ONE thing being photographed,
## and the real `player.tscn` -- never the 143,630-prop world.
##
## The one shot that is not a single structure -- the assembled village
## square -- still does not need the real world: `data/config/village.json`'s
## own `at`/`yaw_deg` fields are the real placement, so the cluster is
## reproduced by calling `instantiate()` once per structure at those same
## relative coordinates on the same flat pad, rather than paying for
## everything else `meadows_playground.tscn` would drag in with it.
##
## ## Frame budget (measured arithmetic, not a guess)
##
## 27 individual structures (18 prefabs + 9 buildables), each: 8 physics
## frames for the player's CharacterBody3D to register on-floor and settle
## into an idle pose (it is placed already touching the flat pad, not
## dropped from height, so this is a floor-snap settle, not a fall) + 2 pose
## frames for the standard shot + 2 pose frames for the close shot
## = 12 awaited frames * 27 = 324.
## The village cluster: same 8-frame settle (still exactly one physics body)
## + 2 shots * 2 pose frames = 12.
## Total = 336 awaited frames * 2.4s/frame (the CORRIDOR SURVEY'S OWN
## measured worst case, for a scene two orders of magnitude heavier than any
## stage this file builds) = 806s = ~13.4 minutes. Comfortably under the
## twenty-minute target, with the real number almost certainly lower: none
## of these stages carries more than a few dozen mesh instances, nothing
## like the corridor survey's 143,630 scattered props that produced the
## 2.4s/frame figure in the first place -- but nothing here bets on that,
## since this file cannot be run to check.
##
## ## "Identical camera/lighting/framing", at wildly different sizes
##
## cottage_b is 4m x 4m; the castle prefab is ~40m x 44m with a ~29m keep.
## One literal fixed camera distance cannot frame both without either the
## cottage filling three pixels or the castle's gate being unreadable, so
## "identical" here means an identical FORMULA applied to every structure's
## own measured AABB, not an identical transform: same FOV (55 deg), same
## azimuth (-35 deg off the recipe's own +z "front", per
## `building_prefabs.json`'s own convention comment), same lighting rig, same
## settle/pose frame counts, and a distance/eye-height that scale with the
## structure's own measured size (`_frame_for()`). The close shot is the
## same formula at ~a third of the distance, capped so a very large structure
## still gets a genuinely CLOSE look rather than a smaller wide shot -- R9.4's
## own finding was that two landmark assets only read as untextured blockout
## once the camera moved close; an 85-110m shot could not see it, and the
## castle's own standard shot is necessarily in roughly that range.
##
## Bounding boxes are MEASURED, not guessed: `_measure()` walks every
## MeshInstance3D under the structure's own root the same way
## `building_prefabs.gd::combined_aabb()` and `tools/_probe_aabb.gd` do
## (mesh AABB carried through its own chain of local transforms), so the
## printed dimensions are the real placed geometry, including whatever a
## kit module's import scale actually produced -- not the recipe's authored
## module positions, which are an input to the geometry, not a measurement
## of it.

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const BUILD_DOOR := preload("res://scripts/build/build_door.gd")
const CAMP := preload("res://scripts/build/camp.gd")
const STORAGE_CONTAINER := preload("res://scripts/build/storage_container.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const BUILDING_PREFABS := preload("res://scripts/world/building_prefabs.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

const BUILDABLES_JSON := "res://data/items/buildables.json"
const OUT_DIR := "res://shots/structures"

## The 18 prefabs, in the task's own listing order.
const PREFAB_NAMES: Array[String] = [
	"workshop", "cottage_a", "cottage_b", "well", "fence_run", "wagon",
	"square_oak_a", "square_oak_b", "farmhouse_shell", "inn", "castle",
	"road_gate_leaf", "mill", "footbridge", "ranger_station", "south_bridge",
	"quarry_foundation", "south_bridge_gate",
]

## `build_placer.gd::STATEFUL_IDS` -- the buildable ids that carry their own
## hand-authored script instead of `build_piece.gd`'s generic mesh loader.
## Mirrored here rather than re-derived so this file's dispatch matches the
## real game's placement dispatch exactly.
const STATEFUL_IDS: Array[String] = ["camp", "storage", "creature_bed", "door"]

const SETTLE_FRAMES := 8   # physics: floor-snap settle, not a fall (see header)
const POSE_FRAMES := 2     # process: materials/shadows steady before shutter
const FOV := 55.0
## Degrees off the recipe's own +z "front" (building_prefabs.json's file-level
## convention comment) for the standard 3/4 view -- one fixed angle, applied
## through the same distance/height formula to every structure (see header).
const AZIMUTH_DEG := -35.0
const MARGIN := 1.15
## The close shot's standoff, measured from the structure's FRONT FACE rather
## than from its centre -- see `_shoot_structure`. Measuring from the centre is
## what put the camera inside the eaves of every tall building on the round-1
## sheet: a 9m building's own half-depth ate most of a 5.4m centre distance.
const CLOSE_FACTOR := 0.32
const CLOSE_MIN := 3.0
const CLOSE_MAX := 9.0
## A person's eye, and the top of a door they can walk through. The close frame
## is composed around these two numbers instead of around the structure's
## height, so it always shows something a player would actually be looking at.
const EYE_HEIGHT := 1.7
const DOOR_HEAD_HEIGHT := 2.1

var _prefabs: RefCounted = null
var _holder: Node3D = null
var _shot_index := 0
var _written: Array[String] = []
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_holder = Node3D.new()
	_holder.name = "PrefabTemplateHolder"
	root.add_child(_holder)

	_prefabs = BUILDING_PREFABS.new()
	_prefabs.call("set_template_holder", _holder)
	if not _prefabs.call("load_recipes"):
		_failures.append("building_prefabs.json failed to load -- no prefab shots possible")
	else:
		for prefab_name in PREFAB_NAMES:
			await _shoot_prefab(prefab_name)

	var buildables := _load_buildables()
	if buildables.is_empty():
		_failures.append("no buildables parsed from %s" % BUILDABLES_JSON)
	else:
		for entry: Variant in buildables:
			await _shoot_buildable(entry as Dictionary)

	await _shoot_village()

	print("")
	print("%d frames -> %s" % [_written.size(), OUT_DIR])
	print("Software rendering under the Compatibility renderer (D06): composition,")
	print("silhouette, proportion and scale relationships are trustworthy here;")
	print("fine lighting judgements and frame times are not.")

	if not _failures.is_empty():
		print("")
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


# --- per-structure capture ---------------------------------------------------


func _shoot_prefab(prefab_name: String) -> void:
	if not _prefabs.call("has_prefab", prefab_name):
		_failures.append("%s: no such prefab in building_prefabs.json" % prefab_name)
		return

	var world := _stage(60.0)
	var node: Node3D = _prefabs.call("instantiate", prefab_name)
	if node == null:
		_failures.append("%s: instantiate() returned null" % prefab_name)
		world.queue_free()
		return
	world.add_child(node)

	var aabb := _measure(node)
	if aabb.size == Vector3.ZERO:
		_failures.append("%s: measured AABB is empty -- no mesh found" % prefab_name)

	var door: Dictionary = _prefabs.call("door_spec", prefab_name)
	var trainer_x := NAN
	if not door.is_empty():
		var door_at: Array = door.get("at", [])
		if door_at.size() >= 1:
			trainer_x = float(door_at[0]) + 1.4

	await _shoot_structure(world, prefab_name, aabb, trainer_x)
	world.queue_free()


func _shoot_buildable(entry: Dictionary) -> void:
	var id := str(entry.get("id", ""))
	if id.is_empty():
		_failures.append("buildables.json: entry with no id")
		return

	var world := _stage(20.0)
	var piece := _build_buildable(id, world)
	if piece == null:
		_failures.append("%s: could not build a piece to photograph" % id)
		world.queue_free()
		return

	var aabb := _measure(piece)
	if aabb.size == Vector3.ZERO:
		_failures.append("%s: measured AABB is empty -- no mesh found" % id)

	await _shoot_structure(world, id, aabb, NAN)
	world.queue_free()


func _build_buildable(id: String, world: Node3D) -> Node3D:
	if id in STATEFUL_IDS:
		var piece: Node3D = null
		match id:
			"camp":
				piece = CAMP.new()
			"storage":
				piece = STORAGE_CONTAINER.new()
			"creature_bed":
				piece = CREATURE_BED.new()
			"door":
				piece = BUILD_DOOR.new()
		if piece == null:
			return null
		world.add_child(piece)
		if id == "creature_bed":
			# player_built=false: this is a photograph, not a real placement,
			# and the true arg would flip the "creature_bed_built" ladder
			# flag on whatever /root/Game state this process happens to boot
			# with (creature_bed.gd's own header explains why the flag write
			# exists at all). The stronghold's own authored rest point passes
			# the same false for the same reason.
			piece.call("build_real", false)
		else:
			piece.call("build_real")
		return piece

	if not ResourceLoader.exists(BUILDABLES_JSON):
		return null
	var buildables := _load_buildables()
	var mesh_path := ""
	var model_scale := Vector3.ONE
	for entry: Variant in buildables:
		var d := entry as Dictionary
		if str(d.get("id", "")) == id:
			mesh_path = str(d.get("mesh", ""))
			if d.has("scale"):
				var arr: Array = d["scale"]
				if arr.size() >= 3:
					model_scale = Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
			break
	if mesh_path.is_empty() or not ResourceLoader.exists(mesh_path):
		return null

	var p := BUILD_PIECE.new()
	world.add_child(p)
	p.call("build_real", mesh_path, {}, model_scale)
	return p


## Shared standard+close framing, trainer placement and shutter for one
## structure already parented into `world`. `aabb` is in the structure's own
## local space (its root has not been translated), and `trainer_x_override`
## is NAN unless the recipe has a real door -- see `_shoot_prefab`.
func _shoot_structure(world: Node3D, name: String, aabb: AABB, trainer_x_override: float) -> void:
	_shot_index += 1
	var frame := _frame_for(aabb)
	var center: Vector3 = frame["center"]
	var distance: float = frame["distance"]
	var eye_h: float = frame["eye_h"]

	var front_z := aabb.position.z + aabb.size.z
	var trainer_x := center.x + 1.7 if is_nan(trainer_x_override) else trainer_x_override
	var trainer_pos := Vector3(trainer_x, 0.0, front_z + 1.3)

	var player := await _spawn_trainer(world, trainer_pos, center)
	if player == null:
		_failures.append("%s: no trainer in frame -- criterion 8 is unanswerable without it" % name)

	print("%02d  %-20s  bbox %.2fw x %.2fh x %.2fd m" % [
		_shot_index, name, aabb.size.x, aabb.size.y, aabb.size.z])

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 400.0
	world.add_child(camera)
	camera.make_current()

	var azimuth := deg_to_rad(AZIMUTH_DEG)
	var dir := Vector2(sin(azimuth), cos(azimuth))

	# Standard establishing shot.
	var eye_xz := Vector2(center.x, center.z) + dir * distance
	camera.global_position = Vector3(eye_xz.x, eye_h, eye_xz.y)
	camera.look_at(Vector3(center.x, aabb.position.y + aabb.size.y * 0.42, center.z), Vector3.UP)
	await _shoot_frame("%s/%02d-%s.png" % [OUT_DIR, _shot_index, name])

	# Close frame -- same angle, pulled in, so a defect that only reads up
	# close (R9.4's own finding) has somewhere to show up.
	#
	# It is composed around a PERSON AT THE DOOR, not around the structure's
	# own height. The previous version pulled the establishing shot in along
	# its own axis, and a third of the round-1 sheet came back framed inside
	# the eaves showing nothing judgeable. That was not bad luck: for a 9m
	# building the eye sat at `size.y * 0.35` = 3.1m and aimed at
	# `size.y * 0.55` = 5.0m, from 5.4m measured from the CENTRE -- of which
	# the building's own half-depth took ~4m, leaving the camera about a metre
	# off the wall, looking up into the roof overhang. It also pushed the
	# 1.80m trainer out of frame, which makes the rubric's scale criterion
	# unanswerable on the very shot most likely to show a scale error.
	#
	# So: standoff measured from the front face, eye at standing height, aim at
	# door-head height, and the frame centred between the door and the trainer
	# so both are in it. Every close frame is now what a player walking up to
	# the door sees.
	var half_depth := aabb.size.z * 0.5
	var close_distance := half_depth + clampf(distance * CLOSE_FACTOR, CLOSE_MIN, CLOSE_MAX)
	var close_x := (center.x + 0.85) if is_nan(trainer_x_override) else (trainer_x_override - 0.7)
	var close_target_y := clampf(aabb.position.y + aabb.size.y * 0.55, 0.6, DOOR_HEAD_HEIGHT)
	var close_eye_xz := Vector2(close_x, center.z) + dir * close_distance
	camera.global_position = Vector3(close_eye_xz.x, EYE_HEIGHT, close_eye_xz.y)
	camera.look_at(Vector3(close_x, close_target_y, center.z), Vector3.UP)
	await _shoot_frame("%s/%02d-%s-close.png" % [OUT_DIR, _shot_index, name])


func _shoot_village() -> void:
	_shot_index += 1
	var world := _stage(70.0)

	# `data/config/village.json`'s own `at`/`yaw_deg` -- the real placement,
	# reproduced on a flat pad rather than the full world (see header).
	# `farmhouse_shell` is not in that file (village.json's own comment: it is
	# grandpa_house.gd's exterior, sited and rotated separately) -- position
	# and yaw are grandpa_house.gd's own HOUSE_AT/`shell.rotation.y`.
	var structures: Array = [
		{"prefab": "well", "at": Vector2(10.0, -10.0), "yaw": 15.0},
		{"prefab": "workshop", "at": Vector2(2.0, 2.0), "yaw": -125.0},
		{"prefab": "wagon", "at": Vector2(6.5, -1.5), "yaw": -150.0},
		{"prefab": "cottage_a", "at": Vector2(18.0, -2.0), "yaw": -135.0},
		{"prefab": "cottage_b", "at": Vector2(21.0, -14.0), "yaw": -70.0},
		{"prefab": "fence_run", "at": Vector2(14.0, -20.0), "yaw": 55.0},
		{"prefab": "fence_run", "at": Vector2(19.5, -25.5), "yaw": 55.0},
		{"prefab": "fence_run", "at": Vector2(3.0, -18.0), "yaw": 100.0},
		{"prefab": "square_oak_a", "at": Vector2(25.5, -9.5), "yaw": 40.0, "scale": 1.25},
		{"prefab": "square_oak_b", "at": Vector2(1.0, 10.5), "yaw": 160.0, "scale": 1.15},
		{"prefab": "inn", "at": Vector2(-1.5, -9.0), "yaw": 90.0},
		{"prefab": "farmhouse_shell", "at": Vector2(-22.0, -16.0), "yaw": 90.0},
	]

	var placed := 0
	for entry: Variant in structures:
		var d := entry as Dictionary
		var prefab_name := str(d["prefab"])
		if not _prefabs.call("has_prefab", prefab_name):
			_failures.append("village cluster: no such prefab %s" % prefab_name)
			continue
		var node: Node3D = _prefabs.call("instantiate", prefab_name)
		if node == null:
			_failures.append("village cluster: instantiate(%s) returned null" % prefab_name)
			continue
		var at: Vector2 = d["at"]
		node.position = Vector3(at.x, 0.0, at.y)
		node.rotation.y = deg_to_rad(float(d["yaw"]))
		if d.has("scale"):
			node.scale = Vector3.ONE * float(d["scale"])
		world.add_child(node)
		placed += 1

	if placed == 0:
		_failures.append("village cluster: nothing placed -- skipping the shot")
		world.queue_free()
		return

	print("%02d  %-20s  %d structures placed (approx span x[-25,30] z[-30,15]m)" % [
		_shot_index, "village", placed])

	var player := await _spawn_trainer(world, Vector3(11.5, 0.0, -9.0), Vector3(10.0, 1.5, -10.0))
	if player == null:
		_failures.append("village: no trainer in frame")

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 400.0
	world.add_child(camera)
	camera.make_current()

	# Wide: the approach a player actually walks in on
	# (`tools/capture_buildings.gd`'s own "06-settlement-approach" vantage,
	# same absolute coordinates -- village.json's positions ARE this file's
	# local space, so no translation is needed).
	camera.global_position = Vector3(34.0, 4.0, -48.0)
	camera.look_at(Vector3(12.0, 3.0, -8.0), Vector3.UP)
	await _shoot_frame("%s/%02d-village.png" % [OUT_DIR, _shot_index])

	# Close: standing at the well, human eye height, looking at the workshop
	# and cottage cluster -- conversation distance, with the trainer as ruler.
	camera.global_position = Vector3(14.5, 1.6, -14.0)
	camera.look_at(Vector3(4.0, 2.5, 0.0), Vector3.UP)
	await _shoot_frame("%s/%02d-village-close.png" % [OUT_DIR, _shot_index])

	world.queue_free()


# --- staging ------------------------------------------------------------------


## A flat, collidable pad plus one outdoor sun/sky rig -- same lighting for
## every structure (identical framing's other half; see header). `half_size`
## sizes the pad to the structure (a cottage needs far less ground than the
## 40m castle or the multi-building village cluster).
func _stage(half_size: float) -> Node3D:
	var world := Node3D.new()
	root.add_child(world)

	var env_holder := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_holder.environment = env
	world.add_child(env_holder)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48.0, 40.0, 0.0)
	world.add_child(sun)

	var body := StaticBody3D.new()
	body.name = "Ground"
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(half_size * 2.0, half_size * 2.0)
	mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.31, 0.38, 0.22)
	material.roughness = 1.0
	mesh.material_override = material
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half_size * 2.0, 0.4, half_size * 2.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.2, 0.0)
	body.add_child(shape)
	world.add_child(body)

	return world


## The real `player.tscn`, standing already-grounded at `at` (feet at y=0,
## the pad's own surface -- `scenes/player/player.tscn`'s Player node origin
## IS the feet; the 1.8m capsule is centred 0.9m above it) and faced toward
## `look_toward`. `player_controller.gd::_ready()` only wires a CameraRig if
## one exists at the sibling NodePath it looks up (`get_node_or_null`) -- none
## is built here, since every shot in this file uses its own fixed Camera3D,
## not the exploration rig.
func _spawn_trainer(world: Node3D, at: Vector3, look_toward: Vector3) -> Node3D:
	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	if player == null:
		return null
	player.name = "Trainer"
	world.add_child(player)
	player.global_position = at
	player.velocity = Vector3.ZERO

	for i in SETTLE_FRAMES:
		await physics_frame

	var model := player.get_node_or_null(^"Model") as Node3D
	if model != null:
		var to_target := look_toward - at
		model.rotation.y = atan2(to_target.x, to_target.z)

	return player


func _shoot_frame(path: String) -> bool:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % path)
		return false
	var error := image.save_png(path)
	if error != OK:
		_failures.append("%s: save_png failed (%d)" % [path, error])
		return false
	_written.append(path)
	print("    -> %s" % path)
	return true


# --- measurement and framing --------------------------------------------------


## Same distance/height formula for every structure, scaled by its own
## measured size -- see header, "Identical camera/lighting/framing".
func _frame_for(aabb: AABB) -> Dictionary:
	var center := aabb.get_center()
	var footprint_diag := Vector2(aabb.size.x, aabb.size.z).length()
	var span := maxf(footprint_diag, aabb.size.y * 1.3)
	var distance := span * MARGIN + 3.0
	var eye_h := clampf(aabb.size.y * 0.35, 1.7, 12.0)
	return {"center": center, "distance": distance, "eye_h": eye_h}


## Combined AABB of every mesh under `node`, in `node`'s own local space --
## same transform walk as `building_prefabs.gd::combined_aabb()` and
## `tools/_probe_aabb.gd` (glTF meshes sit under importer-added transform
## nodes, so each mesh AABB is carried through its own chain of local
## transforms). Written locally rather than calling the prefab composer's own
## method so this one function measures prefabs AND buildable pieces --
## `build_piece.gd` wraps its loaded model in a private `_model` var with no
## public AABB accessor of its own.
func _measure(node: Node3D) -> AABB:
	return _combined(node, node)


func _combined(node: Node, ancestor: Node3D) -> AABB:
	var result := AABB()
	var has := false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var xform := _relative_transform(node, ancestor)
		result = xform * (node as MeshInstance3D).mesh.get_aabb()
		has = true
	for child in node.get_children():
		var sub := _combined(child, ancestor)
		if sub.size != Vector3.ZERO or sub.position != Vector3.ZERO:
			result = result.merge(sub) if has else sub
			has = true
	return result


func _relative_transform(node: Node, ancestor: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var walk: Node = node
	while walk != null and walk != ancestor:
		if walk is Node3D:
			xform = (walk as Node3D).transform * xform
		walk = walk.get_parent()
	return xform


func _load_buildables() -> Array:
	var file := FileAccess.open(BUILDABLES_JSON, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return []
	var list: Variant = (parsed as Dictionary).get("buildables", [])
	return list if list is Array else []
