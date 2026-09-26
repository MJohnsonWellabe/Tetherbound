extends SceneTree

## VIS lane audit capture: one tool that photographs the production subjects a
## code-blind judge grades against docs/design/ART_DIRECTION.md.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_visual_audit.gd -- --section=roster
##
## Never combine `--headless` with a rendering driver (WORKFLOW §7). Offload
## through `.github/workflows/render.yml` (WORKFLOW §8), one dispatch per
## section/region so they run in parallel:
##
##   --section=roster              every species.json creature beside the real
##                                 1.80 m trainer: front 3/4, rear 3/4 and an
##                                 attack-pose side view, then height-sorted
##                                 line-up pages. Scale is measured from the
##                                 rendered AABB and written to the manifest.
##   --section=cast                every art.json humanoid, the four generic
##                                 ranks and the three named captains through
##                                 their production config paths, beside the
##                                 trainer, plus line-up pages. The Warden is
##                                 art.json `warden` and rank `warden`.
##   --section=region --region=<meadows|cloudreach|stormwood|tidewake>
##                                 the production chapter scene; see REGIONS.
##
## Common flags: `--only=a,b` limits subjects/rows by id; `--fast` shortens
## settles (iteration only, never evidence); `--out=res://...` output root.
##
## STAGES. Roster and cast use the calibrated neutral stage from
## tools/_capture_creature_roster.gd (floor albedo renders at its own value, a
## rim keeps dark bodies judgeable) so material colour is trustworthy. The
## region section uses only the production scene, WorldLook clock and the
## production CameraRig; nothing in it is lit or tinted by this tool.
##
## OUTPUT: <out>/<section>[/<region>]/NNN_<name>.png, manifest.jsonl (one JSON
## object per frame or SKIP), and `_sheet_*.jpg` contact sheets small enough to
## commit under ralph/reports/VISUAL/.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const NPC_BODY := preload("res://scripts/npc/npc_body.gd")
const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")

const DEFAULT_OUT := "res://shots/visual_audit"
const TRAINER_HEIGHT := 1.8
const STAGE_FOV := 40.0
const LINEUP_PAGE := 8
const SHEET_CELL_W := 400

var _out := DEFAULT_OUT
var _section := "roster"
var _region := ""
var _only := {}
var _fast := false

var _dir := ""
var _manifest: FileAccess = null
var _frames: Array = []
var _skips: Array = []
var _counter := 0

# Stage state.
var _stage: Node3D = null
var _trainer: Node3D = null
var _camera: Camera3D = null


func _init() -> void:
	# Deferred: autoloads (Game) join the tree only after _init returns.
	_run.call_deferred()


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--section="):
			_section = arg.substr(10)
		elif arg.begins_with("--region="):
			_region = arg.substr(9)
		elif arg.begins_with("--only="):
			for part: String in arg.substr(7).split(",", false):
				_only[part.strip_edges()] = true
		elif arg == "--fast":
			_fast = true
		elif arg.begins_with("--out="):
			_out = arg.substr(6)


func _run() -> void:
	_parse_args()
	if DisplayServer.get_name() == "headless":
		print("visual audit: headless has no renderer; run under xvfb-run with --rendering-driver opengl3")
		quit(1)
		return
	_dir = "%s/%s" % [_out, _section] if _region.is_empty() else "%s/%s/%s" % [_out, _section, _region]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	_manifest = FileAccess.open(_dir + "/manifest.jsonl", FileAccess.WRITE)
	var ok := true
	match _section:
		"roster":
			await _run_roster()
		"cast":
			await _run_cast()
		"region":
			ok = await _run_region()
		_:
			push_error("visual audit: unknown --section=%s" % _section)
			ok = false
	_finish(ok)


## --- neutral stage (roster + cast) ----------------------------------------------

func _build_stage() -> void:
	await process_frame
	_stage = Node3D.new()
	root.add_child(_stage)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.20, 0.22, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.82)
	# Calibrated in tools/_capture_creature_roster.gd so the floor renders at
	# its own albedo with the rim on; do not retune by eye.
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_node.environment = env
	_stage.add_child(env_node)
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(-35.0), 0.0)
	key.light_energy = 0.55
	key.shadow_enabled = true
	_stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation = Vector3(deg_to_rad(-18.0), deg_to_rad(158.0), 0.0)
	rim.light_energy = 0.5
	rim.light_color = Color(0.86, 0.90, 1.0)
	_stage.add_child(rim)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.33, 0.30)
	floor_mesh.material_override = mat
	_stage.add_child(floor_mesh)
	# A 1 m grid of thin lines so heights can be read off the frame as well as
	# off the manifest.
	for i in range(-20, 21):
		for axis in 2:
			var line := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(40.0, 0.004, 0.015) if axis == 0 else Vector3(0.015, 0.004, 40.0)
			line.mesh = box
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(0.36, 0.40, 0.36) if i % 5 != 0 else Color(0.45, 0.50, 0.45)
			line.material_override = lm
			line.position = Vector3(0, 0.002, i) if axis == 0 else Vector3(i, 0.002, 0)
			_stage.add_child(line)
	_trainer = Node3D.new()
	_trainer.set_script(NPC_BODY)
	_stage.add_child(_trainer)
	_trainer.call("setup", "trainer", null)
	_camera = Camera3D.new()
	_camera.fov = STAGE_FOV
	_camera.far = 400.0
	_stage.add_child(_camera)
	_camera.make_current()
	for i in (4 if _fast else 10):
		await physics_frame


## Frame a group whose feet sit on y=0 between x0..x1 and whose tallest member
## is `top` metres, from a 3/4 azimuth `az_deg` (0 = straight on from +Z).
func _frame(x0: float, x1: float, top: float, az_deg: float, depth: float = 0.0) -> void:
	var centre := Vector3((x0 + x1) * 0.5, top * 0.5, 0.0)
	var half_w := maxf((x1 - x0) * 0.5 + 0.8, depth * 0.5 + 0.8)
	var half_h := top * 0.5 + 0.35
	var vfov := deg_to_rad(STAGE_FOV) * 0.5
	var aspect := 16.0 / 9.0
	var viewport := root.get_visible_rect().size
	if viewport.y > 0:
		aspect = viewport.x / viewport.y
	var hfov := atan(tan(vfov) * aspect)
	var dist := maxf(half_h / tan(vfov), half_w / tan(hfov)) * 1.12 + depth * 0.5
	var az := deg_to_rad(az_deg)
	var dir := Vector3(sin(az), 0.0, cos(az))
	var eye := centre + dir * dist
	eye.y = maxf(1.45, top * 0.55)
	_camera.global_position = eye
	_camera.look_at(centre, Vector3.UP)


func _spawn_creature(id: String, at: Vector3, yaw_deg: float) -> Node3D:
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.name = "Audit_%s" % id
	body.set_script(BODY)
	_stage.add_child(body)
	body.call("setup", id, false)
	body.global_position = at
	body.rotation.y = deg_to_rad(yaw_deg)
	body.set_physics_process(false)
	_seat(body.get_node_or_null(^"Model") as Node3D, body, at)
	return body


func _seat(pivot: Node3D, body: Node3D, at: Vector3) -> void:
	if pivot == null:
		return
	var box: AABB = RENDER_BOUNDS.measure(pivot)
	if box.size == Vector3.ZERO:
		return
	var foot: float = box.position.y * pivot.global_transform.basis.get_scale().y
	body.global_position = Vector3(at.x, at.y - foot, at.z)


func _measured(pivot: Node3D) -> Vector3:
	if pivot == null:
		return Vector3.ZERO
	var box: AABB = RENDER_BOUNDS.measure(pivot)
	return box.size * pivot.global_transform.basis.get_scale()


## --- roster -------------------------------------------------------------------

func _species_ids() -> Array[String]:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures/species.json"))
	var ids: Array[String] = []
	if parsed is Dictionary:
		var table: Variant = (parsed as Dictionary).get("species", parsed)
		if table is Dictionary:
			for key: String in (table as Dictionary).keys():
				if key.begins_with("_"):
					continue
				ids.append(key)
	return ids


func _run_roster() -> void:
	await _build_stage()
	var heights := {}
	var ids := _species_ids()
	_log_line({"kind": "note", "text": "roster: %d species in data/creatures/species.json" % ids.size()})
	for id: String in ids:
		if not _only.is_empty() and not _only.has(id):
			continue
		if not SPECIES.has(id):
			_skip(id, "SPECIES.has() false")
			continue
		var body := _spawn_creature(id, Vector3.ZERO, -30.0)
		for i in (3 if _fast else 8):
			await physics_frame
		var pivot := body.get_node_or_null(^"Model") as Node3D
		var size := _measured(pivot)
		var data_h := float(SPECIES.placeholder(id).get("height", 0.0))
		heights[id] = size.y
		var has_model := bool(body.call("has_model"))
		var ratio := size.y / TRAINER_HEIGHT
		var info := {"subject": id, "measured_h": snappedf(size.y, 0.01), "measured_len": snappedf(maxf(size.x, size.z), 0.01),
			"data_h": data_h, "ratio_to_trainer": snappedf(ratio, 0.01), "has_model": has_model,
			"flag": ("SHORTER_THAN_TRAINER" if size.y < TRAINER_HEIGHT else "")}
		var half_len := maxf(size.x, size.z) * 0.5
		_trainer.global_position = Vector3(-(half_len + 1.1), 0.0, 0.0)
		_trainer.rotation.y = deg_to_rad(20.0)
		var x0 := _trainer.global_position.x - 0.4
		var x1 := half_len
		var top := maxf(size.y, TRAINER_HEIGHT)
		# Front three-quarter, idle.
		body.rotation.y = deg_to_rad(-30.0)
		_frame(x0, x1, top, 18.0, maxf(size.x, size.z) * 0.4)
		await _shoot("%s_front" % id, info.merged({"view": "front34_idle"}))
		# Rear three-quarter.
		body.rotation.y = deg_to_rad(150.0)
		await _shoot("%s_rear" % id, info.merged({"view": "rear34_idle"}))
		# Side, mid-attack: the animation pose question (clipping, anticipation).
		body.rotation.y = deg_to_rad(-90.0)
		_frame(x0, x1, top, 0.0, maxf(size.x, size.z) * 0.4)
		if body.has_method("play_attack"):
			body.call("play_attack")
		for i in (4 if _fast else 9):
			await process_frame
		await _shoot("%s_attack" % id, info.merged({"view": "side_attack_pose"}))
		body.queue_free()
		await process_frame
	_trainer.rotation.y = 0.0
	await _roster_lineups(heights)
	_write_sheet("_sheet_roster_front", "_front")
	_write_sheet("_sheet_roster_lineups", "lineup")


func _roster_lineups(heights: Dictionary) -> void:
	var ids: Array = heights.keys()
	ids.sort_custom(func(a, b): return float(heights[a]) < float(heights[b]))
	var page := 0
	var i := 0
	while i < ids.size():
		var chunk: Array = ids.slice(i, i + LINEUP_PAGE)
		var bodies: Array[Node3D] = []
		var x := 0.0
		_trainer.global_position = Vector3(0.0, 0.0, 0.0)
		x = 1.2
		var top := TRAINER_HEIGHT
		var depth := 0.0
		for id: String in chunk:
			var body := _spawn_creature(id, Vector3.ZERO, -90.0)
			var size := _measured(body.get_node_or_null(^"Model") as Node3D)
			var width := maxf(size.x, size.z)
			var at := Vector3(x + width * 0.5, 0.0, 0.0)
			body.global_position = Vector3(at.x, body.global_position.y, 0.0)
			x += width + 0.6
			top = maxf(top, size.y)
			depth = maxf(depth, minf(size.x, size.z))
			bodies.append(body)
		for k in (6 if _fast else 16):
			await physics_frame
		_frame(-0.6, x, top, 0.0, 0.0)
		page += 1
		await _shoot("lineup_%02d" % page, {"subject": "lineup", "members": chunk,
			"heights": chunk.map(func(id): return snappedf(float(heights[id]), 0.01)), "view": "side_height_sorted"})
		for body in bodies:
			body.queue_free()
		await process_frame
		i += LINEUP_PAGE


## --- cast ---------------------------------------------------------------------

func _cast_entries() -> Array:
	var entries: Array = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	if parsed is Dictionary:
		for key: String in (parsed as Dictionary).keys():
			var v: Variant = (parsed as Dictionary)[key]
			if v is Dictionary and (v as Dictionary).has("model"):
				entries.append({"slug": key, "kind": "config", "key": key})
	for rank: String in ["grunt", "officer", "captain", "warden"]:
		entries.append({"slug": "rank_" + rank, "kind": "rank", "key": rank})
	for cap: String in ["captain_field", "captain_ridge", "captain_riverwatch"]:
		entries.append({"slug": cap, "kind": "trainer", "key": cap})
	return entries


func _cast_config(entry: Dictionary) -> Dictionary:
	match str(entry["kind"]):
		"config":
			return CHARACTER_MODEL.config_for(str(entry["key"]))
		"rank":
			return NPC_RANKS.config_for(str(entry["key"]))
		"trainer":
			var spec: Dictionary = TRAINER_NPC.trainer(str(entry["key"]))
			return {} if spec.is_empty() else TRAINER_NPC.model_config(spec)
	return {}


func _build_person(cfg: Dictionary, at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.set_script(CHARACTER_MODEL)
	holder.position = at
	_stage.add_child(holder)
	if not bool(holder.call("build_from_config", cfg)):
		holder.queue_free()
		return null
	if holder.has_method("play"):
		holder.call("play", "idle")
	return holder


func _run_cast() -> void:
	await _build_stage()
	var built: Array = []
	for entry: Dictionary in _cast_entries():
		var slug := str(entry["slug"])
		if not _only.is_empty() and not _only.has(slug):
			continue
		var cfg := _cast_config(entry)
		if cfg.is_empty():
			_skip(slug, "no config via %s" % str(entry["kind"]))
			continue
		var person := _build_person(cfg, Vector3(0.9, 0, 0))
		if person == null:
			_skip(slug, "build_from_config failed")
			continue
		_trainer.global_position = Vector3(-0.9, 0, 0)
		for i in (4 if _fast else 12):
			await process_frame
		var h := float(person.call("height")) if person.has_method("height") else 0.0
		var info := {"subject": slug, "kind": entry["kind"], "config_h": snappedf(h, 0.01)}
		person.rotation.y = deg_to_rad(-20.0)
		_frame(-1.4, 1.4, maxf(h, TRAINER_HEIGHT), 12.0)
		await _shoot("%s_front" % slug, info.merged({"view": "front34_idle"}))
		person.rotation.y = deg_to_rad(160.0)
		await _shoot("%s_rear" % slug, info.merged({"view": "rear34_idle"}))
		# Face close-up: named NPCs need distinct hair/face treatment.
		person.rotation.y = 0.0
		var head := Vector3(0.9, maxf(h, 1.0) * 0.93, 0.0)
		_camera.global_position = head + Vector3(0.0, 0.05, 1.3)
		_camera.look_at(head, Vector3.UP)
		await _shoot("%s_face" % slug, info.merged({"view": "face"}))
		person.queue_free()
		built.append(entry)
		await process_frame
	# Line-up pages: trainer first on every page.
	var i := 0
	var page := 0
	while i < built.size():
		var chunk: Array = built.slice(i, i + 10)
		var people: Array = []
		_trainer.global_position = Vector3(0, 0, 0)
		var x := 1.1
		for entry: Dictionary in chunk:
			var p := _build_person(_cast_config(entry), Vector3(x, 0, 0))
			if p != null:
				people.append(p)
			x += 1.1
		for k in (6 if _fast else 16):
			await process_frame
		_frame(-0.6, x - 0.5, 2.1, 0.0)
		page += 1
		await _shoot("lineup_%02d" % page, {"subject": "cast_lineup", "members": chunk.map(func(e): return e["slug"]), "view": "front_lineup"})
		for p in people:
			p.queue_free()
		await process_frame
		i += 10
	_write_sheet("_sheet_cast_front", "_front")
	_write_sheet("_sheet_cast_faces", "_face")
	_write_sheet("_sheet_cast_lineups", "lineup")


## --- region -------------------------------------------------------------------

## Region state.
var _world: Node3D = null
var _player: CharacterBody3D = null
var _rig: SpringArm3D = null
var _rcam: Camera3D = null
var _look: Node = null
var _director: Node = null
var _rest_pitch_deg := -12.0

## Filled from the landmark survey; one entry per chapter.
const REGION_SPECS := {}

const HOURS := {"day": 10.0, "dusk": 18.3, "night": 23.0}
const FLOOR_WAIT_MAX := 600
const RENDERED_FRAMES := 5
const POSE_FRAMES := 14


func _run_region() -> bool:
	if not REGION_SPECS.has(_region):
		push_error("visual audit: unknown --region=%s (have %s)" % [_region, REGION_SPECS.keys()])
		return false
	var spec: Dictionary = REGION_SPECS[_region]
	if not await _boot_region(spec):
		return false
	var times: Array = spec.get("times", ["day", "dusk", "night"])
	for row: Dictionary in spec["rows"]:
		var id := str(row["id"])
		if not _only.is_empty() and not _only.has(id):
			continue
		var row_times: Array = row.get("times", times)
		for t: String in row_times:
			await _apply_time(spec, t)
			await _capture_region_row(row, t)
	_write_sheet("_sheet_%s_day" % _region, "_day")
	_write_sheet("_sheet_%s_dusk" % _region, "_dusk")
	_write_sheet("_sheet_%s_night" % _region, "_night")
	for extra: String in spec.get("sheet_tags", []):
		_write_sheet("_sheet_%s_%s" % [_region, extra], "_" + extra)
	return true


func _boot_region(spec: Dictionary) -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("visual audit: Game autoload missing")
		return false
	game.call("reset_for_new_game")
	var save_script: Script = load("res://scripts/save/save_game.gd")
	game.set("save_system", save_script.new("user://capture_visual_audit_%s/" % _region))
	game.set("current_realm", str(spec["realm"]))
	var party: RefCounted = game.get("party")
	for species: String in spec.get("party", ["terrapup", "bramblebun", "mudsnout", "galecrest", "brooktail"]):
		party.call("add", SPECIES.spawn(species))
	var progression: RefCounted = game.get("progression")
	for flag: String in spec.get("flags", []):
		progression.call("set_flag", flag)
	var scene: PackedScene = load(str(spec["scene"]))
	if scene == null:
		push_error("visual audit: could not load %s" % spec["scene"])
		return false
	_world = scene.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	_player = _world.find_child("Player", true, false) as CharacterBody3D
	_rig = _world.find_child("CameraRig", true, false) as SpringArm3D
	_rcam = (_rig.get_node_or_null(^"Camera3D") if _rig != null else null) as Camera3D
	_look = _world.find_child("WorldLook", true, false)
	if _player == null or _rig == null or _rcam == null:
		push_error("visual audit: production Player/CameraRig/Camera3D missing in %s" % spec["scene"])
		return false
	var cam_cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/movement.json"))
	if cam_cfg is Dictionary:
		_rest_pitch_deg = float(((cam_cfg as Dictionary).get("camera", {}) as Dictionary).get("pitch_start_deg", -12.0))
	RenderingServer.render_loop_enabled = false
	var booted := false
	for i in 1200:
		await process_frame
		_director = _world.find_child("EncounterDirector", true, false)
		if _director != null and i >= 30:
			booted = true
			print("visual audit: %s booted after %d frames" % [_region, i])
			break
	if not booted:
		print("visual audit: WARN EncounterDirector never appeared in %s; continuing with scene only" % _region)
	for i in 10:
		await physics_frame
	_rcam.make_current()
	if _director != null and _director.has_method("summon_active_creature"):
		_director.call("summon_active_creature")
		for i in 60:
			await physics_frame
	return true


func _apply_time(spec: Dictionary, t: String) -> void:
	# Stormwood has no day/night (owner ruling, ART_DIRECTION §3.3): its "times"
	# are storm phases, applied through the spec's phase hook.
	if spec.has("phase_hook"):
		var hook: Callable = Callable(self, str(spec["phase_hook"]))
		await hook.call(t)
		return
	if _look == null or not HOURS.has(t):
		return
	var hour: float = HOURS[t]
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	var cycle: Variant = _look.get("_cycle")
	if cycle != null and _look.has_method("_apply_blended"):
		_look.set("_elapsed_seconds", float((cycle as Object).call("elapsed_for_hour", hour)))
		_look.call("_apply_blended", hour)
	elif _look.has_method("apply_time"):
		_look.call("apply_time", {"day": "day", "dusk": "golden", "night": "night"}.get(t, "day"))


func _ally() -> Node3D:
	if _director == null or not _director.has_method("ally_body"):
		return null
	var body := _director.call("ally_body") as Node3D
	return body if body != null and is_instance_valid(body) else null


func _ground_guess(x: float, z: float, hint_y: float) -> float:
	for method: String in ["ground_height_near", "ground_height_at"]:
		if not _world.has_method(method):
			continue
		var y: float = NAN
		if method == "ground_height_near" and _region == "tidewake":
			y = float(_world.call(method, x, z))
		elif method == "ground_height_near":
			y = float(_world.call(method, Vector3(x, hint_y + 3.0, z)))
		else:
			y = float(_world.call(method, x, z))
		if is_finite(y):
			return y
	return hint_y


func _floor_hit(spot: Vector3, reach: float = 40.0) -> float:
	var query := PhysicsRayQueryParameters3D.create(spot + Vector3.UP * reach, spot + Vector3.DOWN * reach)
	query.collision_mask = _player.collision_mask
	var exclude: Array[RID] = [_player.get_rid()]
	var ally := _ally()
	if ally is CollisionObject3D:
		exclude.append((ally as CollisionObject3D).get_rid())
	query.exclude = exclude
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(query)
	return NAN if hit.is_empty() else float((hit["position"] as Vector3).y)


func _seat_player(stand: Vector3) -> Dictionary:
	RenderingServer.render_loop_enabled = false
	var y := _ground_guess(stand.x, stand.z, stand.y)
	var spot := Vector3(stand.x, y, stand.z)
	var floor_y := NAN
	for i in FLOOR_WAIT_MAX:
		_player.global_position = spot + Vector3.UP * 0.3
		_player.velocity = Vector3.ZERO
		floor_y = _floor_hit(spot, 6.0)
		if not is_nan(floor_y):
			break
		await physics_frame
	if is_nan(floor_y):
		# Water or an uncollided surface: stand on the drawn height, reported.
		floor_y = y
	_player.global_position = Vector3(stand.x, floor_y + 0.05, stand.z)
	_player.velocity = Vector3.ZERO
	for i in (6 if _fast else 12):
		await physics_frame
	return {"feet": _player.global_position, "floor": floor_y}


func _capture_region_row(row: Dictionary, t: String) -> void:
	var id := str(row["id"])
	var name := "%s_%s_%s" % [_region, id, t]
	var stands: Array = row.get("stands", [])
	if stands.is_empty():
		_skip(name, "row has no stand")
		return
	var stand: Vector3 = stands[0]
	var seat := await _seat_player(stand)
	var feet: Vector3 = seat["feet"]
	var target: Vector3 = row.get("target", feet + Vector3.FORWARD * 50.0)
	if row.has("target_ground"):
		target.y = _ground_guess(target.x, target.z, target.y) + float(row["target_ground"])
	var d := target - feet
	var yaw := atan2(-d.x, -d.z)
	var pitch_min := deg_to_rad(float(_rig.get("_pitch_min")))
	var pitch_max := deg_to_rad(float(_rig.get("_pitch_max")))
	var pitch := deg_to_rad(_rest_pitch_deg)
	if row.has("pitch_deg"):
		pitch = deg_to_rad(float(row["pitch_deg"]))
	else:
		var pivot_y := feet.y + float(_rig.get("_height"))
		var flat := maxf(Vector2(d.x, d.z).length(), 0.01)
		pitch = maxf(pitch, atan2(target.y - pivot_y, flat) - deg_to_rad(_rcam.fov * 0.5 - 6.0))
	pitch = clampf(pitch, pitch_min, pitch_max)
	var model := _player.get_node_or_null(^"Model") as Node3D
	if model != null:
		var fwd := Basis(Vector3.UP, yaw) * Vector3.FORWARD
		model.rotation.y = atan2(fwd.x, fwd.z)
	_rig.set("yaw", yaw)
	_rig.set("pitch", pitch)
	_rig.rotation = Vector3(pitch, yaw, 0.0)
	_rig.global_position = feet + Vector3.UP * float(_rig.get("_height"))
	_rig.spring_length = float(_rig.get("_distance"))
	var ally := _ally()
	var companion := "none"
	if ally != null:
		var basis := Basis(Vector3.UP, yaw)
		var spot := feet + basis * Vector3(1.9, 0.0, -1.6)
		var fy := _floor_hit(spot, 6.0)
		ally.global_position = Vector3(spot.x, (fy if is_finite(fy) else feet.y) + 0.05, spot.z)
		if ally is CharacterBody3D:
			(ally as CharacterBody3D).velocity = Vector3.ZERO
		companion = str(ally.get("species_id")) if ally.get("species_id") != null else ally.name
	for i in POSE_FRAMES - RENDERED_FRAMES:
		await process_frame
	RenderingServer.render_loop_enabled = true
	for i in RENDERED_FRAMES:
		await process_frame
	_rig.set("yaw", yaw)
	_rig.set("pitch", pitch)
	for node in root.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
	var dist := Vector2(d.x, d.z).length()
	await _shoot(name, {"subject": id, "label": row.get("label", id), "region": _region, "time": t,
		"feet": _v(feet), "target": _v(target), "target_dist_m": snappedf(dist, 0.1),
		"yaw_deg": snappedf(rad_to_deg(yaw), 0.1), "pitch_deg": snappedf(rad_to_deg(pitch), 0.1),
		"camera": _v(_rcam.global_position), "companion": companion, "why": row.get("why", "")})


func _v(p: Vector3) -> Array:
	return [snappedf(p.x, 0.1), snappedf(p.y, 0.1), snappedf(p.z, 0.1)]


## --- output -------------------------------------------------------------------

func _shoot(name: String, info: Dictionary) -> void:
	for i in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_skip(name, "viewport returned no image")
		return
	_counter += 1
	var file := "%03d_%s.png" % [_counter, name]
	if image.save_png("%s/%s" % [_dir, file]) != OK:
		_skip(name, "save_png failed")
		return
	var entry := info.duplicate()
	entry["kind"] = "frame"
	entry["file"] = file
	_log_line(entry)
	_frames.append({"name": file, "image": image})


func _skip(name: String, why: String) -> void:
	var line := "SKIP %s: %s" % [name, why]
	_skips.append(line)
	_log_line({"kind": "skip", "subject": name, "text": why})


func _log_line(d: Dictionary) -> void:
	var line := JSON.stringify(d)
	print("AUDIT " + line)
	if _manifest != null:
		_manifest.store_line(line)
		_manifest.flush()


func _write_sheet(stem: String, contains: String) -> void:
	var picked: Array = []
	for f: Dictionary in _frames:
		if str(f["name"]).contains(contains):
			picked.append(f)
	contact_sheet(picked, "%s/%s.jpg" % [_dir, stem], 5, SHEET_CELL_W)


static func contact_sheet(frames: Array, path: String, columns: int, cell_w: int) -> void:
	if frames.is_empty():
		return
	var first: Image = frames[0]["image"]
	var cell_h := int(round(float(cell_w) * float(first.get_height()) / float(first.get_width())))
	var rows := int(ceil(float(frames.size()) / float(columns)))
	var gap := 4
	var sheet := Image.create(columns * cell_w + (columns + 1) * gap, rows * cell_h + (rows + 1) * gap, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.08, 0.08, 0.09))
	for i in frames.size():
		var img: Image = (frames[i]["image"] as Image).duplicate()
		img.convert(Image.FORMAT_RGB8)
		img.resize(cell_w, cell_h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(img, Rect2i(0, 0, cell_w, cell_h),
			Vector2i(gap + (i % columns) * (cell_w + gap), gap + int(float(i) / float(columns)) * (cell_h + gap)))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	sheet.save_jpg(path, 0.82)
	print("AUDIT sheet %s (%d frames)" % [path, frames.size()])


func _finish(ok: bool) -> void:
	RenderingServer.render_loop_enabled = true
	var summary := "visual audit %s%s: %d frames, %d skips" % [_section, ("/" + _region) if not _region.is_empty() else "", _frames.size(), _skips.size()]
	_log_line({"kind": "summary", "text": summary})
	for s in _skips:
		print(s)
	if _manifest != null:
		_manifest.close()
	quit(0 if ok and not _frames.is_empty() else 1)
