extends SceneTree

## OWNER-0912 production receipt for the two riding complaints: the fitted
## saddle must remain visible on the animal's back, and the trainer must sit in
## it. Every accepted angle is paired in authored day/night. The harness uses
## the shipped Meadows scene, EncounterDirector, inventory/party state, and the
## real RidingController.mount() path; it never poses or reparents the rider.
##
## Run with a real Compatibility renderer (never --headless) and a new output:
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_riding.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/final-riding-03

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")

const READY_TIMEOUT_MS := 420_000
const POSE_FRAMES := 8
const CANONICAL_SPECIES := "meadowhart"
const FOV := 42.0
const EYE_BEHIND := 2.5
const EYE_SIDE := 4.8
const SIDE_EYE_BEHIND := 0.4
const SIDE_EYE_SIDE := 5.4
const EYE_ABOVE_SEAT := 0.35
const AIM_ABOVE_SEAT := 0.05
const NIGHT_KEY_ENERGY := 3.2
const NIGHT_RIM_ENERGY := 1.8
const OPEN_RIDE_XZ := Vector2(-25.0, -60.0)
const PLANNED := [
	{"frame": "01-unsaddled-three-quarter-day", "state": "unsaddled", "time": "day", "behind": EYE_BEHIND, "side": EYE_SIDE},
	{"frame": "01-unsaddled-three-quarter-night", "state": "unsaddled", "time": "night", "behind": EYE_BEHIND, "side": EYE_SIDE},
	{"frame": "02-mounted-three-quarter-day", "state": "mounted", "time": "day", "behind": EYE_BEHIND, "side": EYE_SIDE},
	{"frame": "02-mounted-three-quarter-night", "state": "mounted", "time": "night", "behind": EYE_BEHIND, "side": EYE_SIDE},
	{"frame": "03-mounted-side-day", "state": "mounted", "time": "day", "behind": SIDE_EYE_BEHIND, "side": SIDE_EYE_SIDE},
	{"frame": "03-mounted-side-night", "state": "mounted", "time": "night", "behind": SIDE_EYE_BEHIND, "side": SIDE_EYE_SIDE},
]

var _species := ""
var _out_dir := ""
var _failures: Array[String] = []
var _records: Array[Dictionary] = []
var _manifest: Dictionary = {}


func _init() -> void:
	_run()


func _parse_args() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--species="):
			_species = arg.trim_prefix("--species=").strip_edges()


func _run() -> void:
	_parse_args()
	if not FRESH_OUTPUT.create_fresh(_out_dir, "riding capture"):
		quit(1)
		return
	_begin_manifest()
	_write_manifest()
	if DisplayServer.get_name() == "headless":
		_failures.append("riding capture requires a rendering display")
		_finish(false)
		return
	if _species.is_empty():
		_species = _default_species()
	if _species.is_empty():
		_failures.append("no rideable species that requires a saddle")
		_finish(false)
		return
	_manifest["species_id"] = _species
	_write_manifest()

	var packed := load(SCENE) as PackedScene
	if packed == null:
		_failures.append("could not load the production Meadows scene")
		_finish(false)
		return
	var world := packed.instantiate() as Node3D
	root.add_child(world)
	if not await _wait_for_world(world):
		_failures.append("production Meadows scene did not finish building")
		_finish(false)
		return

	var player := world.get_node_or_null(^"Player") as Node3D
	var rig := world.get_node_or_null(^"CameraRig")
	var director := world.get_node_or_null(^"EncounterDirector")
	var riding := world.get_node_or_null(^"RidingController")
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var game := root.get_node_or_null(^"/root/Game")
	if player == null or director == null or riding == null or look == null or game == null:
		_failures.append("production player, director, riding controller, WorldLook or Game is missing")
		_finish(false)
		return
	var party: RefCounted = game.get("party")
	var bag: RefCounted = game.get("inventory")
	var progression: RefCounted = game.get("progression")
	if party == null or bag == null or progression == null:
		_failures.append("production party, inventory or progression store is missing")
		_finish(false)
		return
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	look.set_process(false)
	look.set_physics_process(false)
	_hide_overlays(world)

	# Begin from the actual unfitted state.
	var saddle_count := int(bag.call("count", "saddle"))
	if saddle_count > 0:
		bag.call("remove", "saddle", saddle_count)
	progression.call("set_flag", RIDING.saddle_fitted_flag(_species), false)
	if not await _bring_out_the_mount(director, party):
		_finish(false)
		return
	var mount := director.call("ally_body") as Node3D
	if mount == null:
		_failures.append("production director returned no ally body")
		_finish(false)
		return
	if _species == CANONICAL_SPECIES and (not mount.has_method("meadowhart_bare_body_present") \
			or not bool(mount.call("meadowhart_bare_body_present"))):
		_failures.append("production Meadowhart did not apply its bare-body source repair")
		_finish(false)
		return
	if mount.find_child("RideSaddle", true, false) != null:
		_failures.append("unfitted production mount already carries a RideSaddle")
		_finish(false)
		return
	var stand := Vector3(OPEN_RIDE_XZ.x, 0.0, OPEN_RIDE_XZ.y)
	if not bool(mount.call("place_on_ground", stand)):
		_failures.append("open riding stand has no Terrain3D ground")
		_finish(false)
		return
	player.global_position = mount.global_position + mount.global_basis.x * 1.8
	for _frame in 90:
		await physics_frame

	var camera := Camera3D.new()
	camera.name = "RidingAcceptanceCamera"
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var terrain := world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	var evidence_lights := _make_evidence_lights(world)
	for _frame in 60:
		await physics_frame

	for raw: Variant in PLANNED:
		var row := raw as Dictionary
		if str(row.state) == "unsaddled":
			await _shoot(look, camera, evidence_lights, player, mount, riding, row)

	# Use the production action, which consumes the real inventory item, fits
	# the production saddle visual, and creates the production rider carrier.
	bag.call("add", "saddle", 1)
	for _frame in 10:
		await physics_frame
	if not bool(riding.call("mount")):
		_failures.append("RidingController.mount() rejected the production %s" % _species)
		_finish(false)
		return
	for _frame in 60:
		await physics_frame
	if not bool(riding.call("is_mounted")) or riding.call("mount_body") != mount:
		_failures.append("production riding state did not bind the trainer to the summoned mount")
	if not RIDING.saddle_is_fitted(_species, progression):
		_failures.append("production mount path did not persist the fitted saddle flag")
	if mount.find_child("RideSaddle", true, false) == null:
		_failures.append("production mount has no RideSaddle visual after mounting")
	if not _failures.is_empty():
		_finish(false)
		return
	for raw: Variant in PLANNED:
		var row := raw as Dictionary
		if str(row.state) == "mounted":
			await _shoot(look, camera, evidence_lights, player, mount, riding, row)
	_finish(_failures.is_empty() and _records.size() == PLANNED.size())


func _default_species() -> String:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures/species.json"))
	if not parsed is Dictionary:
		return ""
	var table: Variant = (parsed as Dictionary).get("species", {})
	if not table is Dictionary:
		return ""
	# T0 #12 / T2 #7 are the Meadows riding-unlock visual, and the clean
	# acceptance smoke exercises Meadowhart. Alphabetically selecting the first
	# saddle mount picked Burrowback instead: its very broad armored shell hides
	# both legs from every useful side profile, so a complete receipt could not
	# judge the complaint the smoke had just measured. Keep --species available
	# for roster audits, but make the normal final receipt the canonical unlock.
	if (table as Dictionary).has(CANONICAL_SPECIES) \
			and RIDING.saddle_belongs_on(CANONICAL_SPECIES):
		return CANONICAL_SPECIES
	var ids: Array[String] = []
	for id: String in (table as Dictionary):
		if not id.begins_with("_") and RIDING.saddle_belongs_on(id):
			ids.append(id)
	ids.sort()
	return ids[0] if not ids.is_empty() else ""


func _bring_out_the_mount(director: Node, party: RefCounted) -> bool:
	if director.call("ally_body") != null:
		director.call("dismiss_active_creature")
		for _frame in 20:
			await physics_frame
	var instance: RefCounted = SPECIES.spawn(_species)
	if instance == null or not bool(party.call("add", instance)):
		_failures.append("could not put a production %s in the party" % _species)
		return false
	for index in int(party.call("size")):
		if party.call("at", index) == instance:
			party.call("set_active", index)
			break
	await director.call("summon_active_creature")
	for _frame in 120:
		await physics_frame
		var body := director.call("ally_body") as Node3D
		if body != null and is_instance_valid(body) and body.visible:
			return true
	_failures.append("the production %s never stood up in the world" % _species)
	return false


func _shoot(look: Node, camera: Camera3D, evidence_lights: Array[OmniLight3D],
		player: Node3D, mount: Node3D, riding: Node, row: Dictionary) -> void:
	var time_name := str(row.time)
	look.call("apply_time", time_name)
	if look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	# Frame the authored seat rather than a fraction of the creature's declared
	# height. That keeps the saddle/back junction, pelvis, and hanging legs in
	# the same paired frame even when mount proportions differ.
	var seat_local: Vector3 = SPECIES.rideable(_species).get("mount_offset", Vector3.UP)
	var seat_world := mount.to_global(seat_local)
	var centre := seat_world + Vector3.UP * AIM_ABOVE_SEAT
	var eye := seat_world \
		- mount.global_basis.z * float(row.behind) \
		+ mount.global_basis.x * float(row.side) \
		+ Vector3.UP * EYE_ABOVE_SEAT
	camera.global_position = eye
	camera.look_at(centre, Vector3.UP)
	_set_evidence_lights(evidence_lights, camera, seat_world, time_name == "night")
	for _frame in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var frame_name := str(row.frame)
	if image == null or image.is_empty():
		_failures.append("%s: viewport returned no image" % frame_name)
		return
	var path := "%s/%s.png" % [_out_dir, frame_name]
	if image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % frame_name)
		return
	var record := {
		"frame": frame_name,
		"state": str(row.state),
		"time": time_name,
		"file": path,
		"bytes": FileAccess.get_file_as_bytes(path).size(),
		"image_size": [image.get_width(), image.get_height()],
		"camera_transform": _transform(camera.global_transform),
		"mount_transform": _transform(mount.global_transform),
		"authored_seat_world": [seat_world.x, seat_world.y, seat_world.z],
		"capture_evidence_light": time_name == "night",
		"production_riding_mounted": bool(riding.call("is_mounted")),
		"production_mount_body_matches": riding.call("mount_body") == mount,
		"saddle_fitted_flag": RIDING.saddle_is_fitted(_species),
		"saddle_visual_present": mount.find_child("RideSaddle", true, false) != null,
		"meadowhart_bare_body_present": mount.has_method("meadowhart_bare_body_present") \
			and bool(mount.call("meadowhart_bare_body_present")),
	}
	if str(row.state) == "mounted":
		var limb_receipt := _rider_limb_receipt(player, camera, mount)
		if not bool(limb_receipt.get("complete", false)):
			_failures.append("%s: production rider limb bones could not be measured" % frame_name)
			return
		record["rider_near_leg"] = limb_receipt
	_records.append(record)
	_write_manifest()
	print("riding capture %s -> %s" % [frame_name, path])


func _begin_manifest() -> void:
	_manifest = {
		"production_scene": SCENE,
		"named_location": "Grandpa's Village open riding field",
		"output_directory": _out_dir,
		"capture_started_utc": Time.get_datetime_string_from_system(true),
		"display_server": DisplayServer.get_name(),
		"expected_frame_count": PLANNED.size(),
		"planned_frames": PLANNED.map(func(row: Dictionary) -> String: return str(row.frame)),
		"fixture_disclosure": "Production Meadows scene, Terrain3D, trainer, party, inventory, EncounterDirector and RidingController. Canonical Meadowhart is audit-added to the ephemeral party by default, summoned through EncounterDirector, fitted and mounted only by RidingController.mount(). Camera is framed from the authored seat; authored day/night clock frozen; clear weather and HUD hidden. Night frames use bounded capture-only key/rim evidence lights so the saddle/back and rider/seat interfaces remain judgeable. No rider pose, carrier, saddle transform, creature art, material, world geometry or progression reward injection.",
		"complete": false,
		"frames": [],
		"failures": [],
	}


func _write_manifest() -> void:
	_manifest["frames"] = _records
	_manifest["failures"] = _failures
	_manifest["captured_frame_count"] = _records.size()
	var file := FileAccess.open("%s/manifest.json" % _out_dir, FileAccess.WRITE)
	if file == null:
		if not _failures.has("manifest could not be written"):
			_failures.append("manifest could not be written")
		return
	file.store_string(JSON.stringify(_manifest, "\t") + "\n")
	file.close()


func _finish(requested_complete: bool) -> void:
	_manifest["capture_finished_utc"] = Time.get_datetime_string_from_system(true)
	_manifest["complete"] = requested_complete and _failures.is_empty() \
		and _records.size() == PLANNED.size()
	_write_manifest()
	quit(0 if bool(_manifest.complete) else 1)


func _hide_overlays(world: Node) -> void:
	for child: Node in world.find_children("*", "CanvasLayer", true, false):
		(child as CanvasLayer).visible = false


func _make_evidence_lights(world: Node3D) -> Array[OmniLight3D]:
	var lights: Array[OmniLight3D] = []
	for row: Dictionary in [
			{"name": "RidingEvidenceKey", "colour": Color("ffd5ad"), "range": 9.0},
			{"name": "RidingEvidenceRim", "colour": Color("a8c9ff"), "range": 7.0},
	]:
		var light := OmniLight3D.new()
		light.name = str(row.name)
		var colour: Color = row.get("colour", Color.WHITE)
		light.light_color = colour
		light.omni_range = float(row.range)
		light.light_energy = 0.0
		light.shadow_enabled = false
		world.add_child(light)
		lights.append(light)
	return lights


func _set_evidence_lights(lights: Array[OmniLight3D], camera: Camera3D,
		seat_world: Vector3, enabled: bool) -> void:
	if lights.size() != 2:
		return
	var view_from_seat := camera.global_position - seat_world
	var horizontal := Vector3(view_from_seat.x, 0.0, view_from_seat.z).normalized()
	if horizontal.is_zero_approx():
		horizontal = Vector3.FORWARD
	var side := Vector3.UP.cross(horizontal).normalized()
	lights[0].global_position = seat_world + horizontal * 2.0 + side * 1.2 + Vector3.UP * 1.8
	lights[1].global_position = seat_world - horizontal * 1.6 - side * 1.4 + Vector3.UP * 1.1
	lights[0].light_energy = NIGHT_KEY_ENERGY if enabled else 0.0
	lights[1].light_energy = NIGHT_RIM_ENERGY if enabled else 0.0


func _rider_limb_receipt(player: Node3D, camera: Camera3D, mount: Node3D) -> Dictionary:
	var model := player.get_node_or_null(^"Model")
	if model == null or not model.has_method("skeleton"):
		return {"complete": false}
	var skeleton := model.call("skeleton") as Skeleton3D
	if skeleton == null:
		return {"complete": false}
	var sides := {
		"left": ["LeftUpLeg", "LeftLeg", "LeftFoot"],
		"right": ["RightUpLeg", "RightLeg", "RightFoot"],
	}
	var chains: Dictionary = {}
	for side: String in sides:
		var points: Array[Vector3] = []
		for bone_name: String in sides[side]:
			var index := skeleton.find_bone(bone_name)
			if index < 0:
				return {"complete": false, "missing_bone": bone_name}
			points.append(skeleton.global_transform * skeleton.get_bone_global_pose(index).origin)
		chains[side] = points
	var left_points: Array[Vector3] = chains.left
	var right_points: Array[Vector3] = chains.right
	var near_side := "left" if camera.global_position.distance_to(left_points[2]) \
		<= camera.global_position.distance_to(right_points[2]) else "right"
	var near_points: Array[Vector3] = chains[near_side]
	var saddle := mount.find_child("RideSaddle", true, false) as Node3D
	return {
		"complete": true,
		"side": near_side,
		"hip_world": _point(near_points[0]),
		"knee_world": _point(near_points[1]),
		"ankle_world": _point(near_points[2]),
		"ankle_below_hip_m": near_points[0].y - near_points[2].y,
		"ankle_to_saddle_origin_m": near_points[2].distance_to(saddle.global_position) \
			if saddle != null else -1.0,
	}


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false


func _transform(value: Transform3D) -> Dictionary:
	return {
		"origin": [value.origin.x, value.origin.y, value.origin.z],
		"basis_x": [value.basis.x.x, value.basis.x.y, value.basis.x.z],
		"basis_y": [value.basis.y.x, value.basis.y.y, value.basis.y.z],
		"basis_z": [value.basis.z.x, value.basis.z.y, value.basis.z.z],
	}


func _point(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
