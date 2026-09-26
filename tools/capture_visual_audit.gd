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
const LINEUP_PAGE := 5
const SHEET_CELL_W := 400

var _out := DEFAULT_OUT
var _section := "roster"
var _region := ""
var _only := {}
var _fast := false
var _kind := ""  # region rows: "", "env" or "places"
var _variant := ""  # region: "aftermath" for post-finale state

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
		elif arg.begins_with("--kind="):
			_kind = arg.substr(7)
		elif arg.begins_with("--variant="):
			_variant = arg.substr(10)
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
	_dir = "%s/%s" % [_out, _section] if _region.is_empty() else "%s/%s/%s%s%s" % [_out, _section, _region,
		("_" + _kind) if not _kind.is_empty() else "", ("_" + _variant) if not _variant.is_empty() else ""]
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

const HOURS := {"day": 10.0, "dusk": 18.3, "night": 23.0}
const FLOOR_WAIT_MAX := 600
const RENDERED_FRAMES := 4
const POSE_FRAMES := 14


func _run_region() -> bool:
	var spec := _region_spec(_region)
	if spec.is_empty():
		push_error("visual audit: unknown --region=%s (meadows|cloudreach|stormwood|tidewake)" % _region)
		return false
	if _variant == "aftermath":
		spec["flags"] = (spec.get("flags", []) as Array) + (spec.get("aftermath_flags", []) as Array)
	if not await _boot_region(spec):
		return false
	var rows: Array = _build_rows(spec)
	_log_line({"kind": "note", "text": "%s: %d rows (%s)" % [_region, rows.size(), _kind if not _kind.is_empty() else "env+places"]})
	for row: Dictionary in rows:
		var id := str(row["id"])
		if not _only.is_empty() and not _only.has(id):
			continue
		for t: String in row["times"]:
			await _capture_region_row(spec, row, t)
	_write_sheet("_sheet_%s_env" % _region, "_env_")
	_write_sheet("_sheet_%s_places" % _region, "_place_")
	return true


## --- region data: every row comes from shipped data, not from this tool ---------

const TIMES_DAYNIGHT := ["day", "dusk", "night"]

func _region_spec(region: String) -> Dictionary:
	match region:
		"meadows":
			return {"realm": "meadows", "scene": "res://scenes/world/meadows_playground.tscn", "biome": "meadows",
				"env_times": TIMES_DAYNIGHT, "place_times": ["day"], "major_times": ["day", "night"],
				"flags": [], "freeze_weather": true}
		"cloudreach":
			return {"realm": "cloudreach", "scene": "res://scenes/world/cloudreach_cliffs.tscn", "biome": "cloudreach",
				"env_times": TIMES_DAYNIGHT, "place_times": ["day"], "major_times": ["day", "night"],
				"party": ["galecrest", "bramblebun", "mudsnout", "terrapup", "brooktail"],
				"flags": ["realm_key_cloudreach", "realm_gate_cloudreach_unlocked", "cloudreach_chapter_started",
					"cloudreach_crisis_learned", "storm_anchor_lower_west_mapped", "storm_anchor_lower_east_mapped",
					"cloudreach_lower_anchors_investigated", "causeway_survivors_reconnected", "windscar_aerie_prepared",
					"cloudreach_act_i_complete", "fly_traversal_unlocked", "fly_tutorial_completed", "sky_shrine_reached",
					"cloudreach_shrine_vane_west_aligned", "cloudreach_shrine_vane_east_aligned",
					"cloudreach_shrine_vane_crown_aligned", "storm_anchor_engine_truth_learned",
					"cloudreach_upper_route_unlocked", "cloudreach_act_ii_complete"],
				"aftermath_flags": ["captain_veyra_defeated", "storm_anchor_network_disabled",
					"cloudreach_winds_restored", "stormward_route_revealed"]}
		"stormwood":
			# Fixed purple storm, no day/night (owner ruling): "times" are Surge phases.
			return {"realm": "stormwood", "scene": "res://scenes/world/stormwood.tscn", "biome": "stormwood",
				"env_times": ["calm", "building", "break"], "place_times": ["calm"], "major_times": ["calm", "break"],
				"phase_hook": "_stormwood_phase",
				"flags": ["realm_key_stormwood", "stormwood:rootgate_released"],
				"aftermath_flags": ["stormwood:long_storm_ended"]}
		"tidewake":
			return {"realm": "water", "scene": "res://scenes/world/water_archipelago.tscn", "biome": "water",
				"env_times": TIMES_DAYNIGHT, "place_times": ["day"], "major_times": ["day", "night"],
				"flags": ["realm_key_water"]}
	return {}


func _json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _p3(v: Variant) -> Vector3:
	var a: Array = v
	if a.size() >= 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3(float(a[0]), NAN, float(a[1]))


## Road polylines (y NAN where the data is 2-D), densified to 8 m steps.
func _roads() -> Array:
	var raw: Array = []
	match _region:
		"meadows":
			var trail: Dictionary = (_json("res://data/config/terrain_playground.json") as Dictionary).get("trail", {})
			for group: String in ["bands", "loops", "shortcuts"]:
				for r: Dictionary in trail.get(group, []):
					raw.append(r.get("points", []))
			var paths: Dictionary = (_json("res://data/config/terrain_playground.json") as Dictionary).get("paths", {})
			for r: Dictionary in paths.get("routes", []):
				raw.append(r.get("points", []))
		"cloudreach":
			for r: Dictionary in (_json("res://data/config/cloudreach_world.json") as Dictionary).get("routes", []):
				raw.append(r.get("polyline", []))
		"stormwood":
			for r: Dictionary in (_json("res://data/config/stormwood_world.json") as Dictionary).get("routes", []):
				raw.append(r.get("points", []))
		"tidewake":
			for r: Dictionary in (_json("res://data/config/water_world.json") as Dictionary).get("land_routes", []):
				raw.append(r.get("polyline", []))
	var out: Array = []
	for line: Array in raw:
		var pts: Array = []
		for i in line.size():
			var a := _p3(line[i])
			pts.append(a)
			if i + 1 < line.size():
				var b := _p3(line[i + 1])
				var n := int(Vector2(b.x - a.x, b.z - a.z).length() / 8.0)
				for k in range(1, n):
					pts.append(a.lerp(b, float(k) / float(n)))
		out.append(pts)
	return out


## Named places: the realm's landmark table (plus Meadows map regions/sites).
func _places() -> Array:
	var out: Array = []
	match _region:
		"meadows":
			var m: Dictionary = _json("res://data/config/map_landmarks.json")
			for l: Dictionary in m.get("landmarks", []):
				if not l.has("position"):
					_skip("place_" + str(l.get("id")), "no fixed position in map_landmarks.json (resolved at runtime)")
					continue
				out.append({"id": str(l["id"]), "label": str(l.get("display_name", l["id"])), "pos": _p3(l["position"]),
					"major": str(l.get("category", "")) == "major"})
			for r: Dictionary in m.get("regions", []):
				out.append({"id": str(r["id"]), "label": str(r.get("display_name", r["id"])), "pos": _p3(r.get("centre", r.get("position"))), "major": false})
			# WORLD.md Meadows spine sites not in the map tables.
			for extra: Array in [["south_bridge", "The South Bridge", [0.0, 1330.0]], ["trail_camp", "Trail Camp", [348.0, 919.5]],
					["old_quarry", "The Old Quarry", [403.0, 1794.0]], ["ranger_camp", "Abandoned Ranger Camp", [-259.0, 2256.5]],
					["burrow_warrens", "The Burrow Warrens", [-357.0, 2610.0]], ["stonewater_reach", "Stonewater Reach", [-120.0, 3420.0]],
					["tether_relay", "The Tether Relay", [350.0, 3760.0]], ["old_mill_crossing", "Old Mill Crossing", [-152.0, 4203.0]],
					["long_water", "Long Water", [-280.0, 4195.0]], ["ironwood_grove", "The Ironwood Grove", [-345.0, 5060.0]],
					["highfield", "Highfield", [400.0, 5900.0]], ["ridgeline_watch", "The Ridgeline Watch", [-250.0, 6490.0]],
					["broken_tower", "The Broken Tower", [40.0, 6800.0]], ["stronghold_approach", "Stronghold Approach", [0.0, 7000.0]],
					["meadows_hall", "Meadows Hall", [8.0, 7590.0]], ["the_pond", "The Pond", [-342.0, 507.0]],
					["the_rise", "The Rise", [88.0, -43.0]]]:
				out.append({"id": extra[0], "label": extra[1], "pos": _p3(extra[2]), "major": true})
		"cloudreach", "stormwood", "tidewake":
			var file: String = {"cloudreach": "cloudreach_world", "stormwood": "stormwood_world", "tidewake": "water_world"}[_region]
			for l: Dictionary in (_json("res://data/config/%s.json" % file) as Dictionary).get("landmarks", []):
				if not l.has("position"):
					continue
				out.append({"id": str(l["id"]), "label": str(l.get("display_name", l.get("name", l["id"]))), "pos": _p3(l["position"]),
					"major": str(l.get("category", "")) == "major" or bool(l.get("silhouette", false))})
	# Dedupe places within 40 m of an earlier one.
	var kept: Array = []
	for p: Dictionary in out:
		var dup := false
		for k: Dictionary in kept:
			if Vector2(p.pos.x, p.pos.z).distance_to(Vector2(k.pos.x, k.pos.z)) < 40.0:
				dup = true
				break
		if not dup:
			kept.append(p)
	return kept


## The road point that approaches `pos` from about 90 m (45..180 m window),
## preferring a similar height where the data is 3-D, and REQUIRING a clear
## sightline over the drawn terrain from eye height to 3 m above the landmark
## (the first pass stood players in gullies facing a hillside). Returns
## [stand, note].
func _approach(pos: Vector3, roads: Array) -> Array:
	var scored: Array = []
	for line: Array in roads:
		for q: Vector3 in line:
			var d := Vector2(q.x - pos.x, q.z - pos.z).length()
			if d < 45.0 or d > 180.0:
				continue
			var score := absf(d - 90.0)
			if is_finite(q.y) and is_finite(pos.y):
				score += absf(q.y - pos.y) * 1.5
			scored.append([score, q])
	# Off-road ring stands as a lower-priority fallback (a place with no road
	# within 180 m is itself a finding; the note says which kind was used).
	for ring: float in [70.0, 110.0]:
		for k in 12:
			var ang := TAU * float(k) / 12.0
			var q := Vector3(pos.x + sin(ang) * ring, NAN, pos.z + cos(ang) * ring)
			scored.append([200.0 + absf(ring - 90.0), q])
	scored.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	var target := pos
	var tg := _ground_guess(pos.x, pos.z, pos.y)
	target.y = (maxf(pos.y, tg) if is_finite(pos.y) else tg) + 3.0
	var tried := 0
	for entry: Array in scored:
		var q: Vector3 = entry[1]
		tried += 1
		if tried > 90:
			break
		var eye := Vector3(q.x, _ground_guess(q.x, q.z, q.y) + 2.6, q.z)
		var clear := true
		for k in range(1, 16):
			var t := float(k) / 16.0
			var at := eye.lerp(target, t)
			if _ground_guess(at.x, at.z, at.y) > at.y + 1.0:
				clear = false
				break
		if clear:
			var kind := "OFF-ROAD ring stand (no clear road approach)" if float(entry[0]) >= 200.0 else "road approach"
			return [q, "%s %.0f m, clear sightline (candidate %d)" % [kind, Vector2(q.x - pos.x, q.z - pos.z).length(), tried]]
	return [scored[0][1], "road approach, NO clear sightline among %d candidates (terrain occludes the landmark from its road)" % tried]


func _build_rows(spec: Dictionary) -> Array:
	var rows: Array = []
	if _kind != "places":
		# Environment: the hand-checked debug teleport spots, two per band/region.
		var spots: Dictionary = _json("res://data/config/debug_teleport_spots.json")
		for biome: Dictionary in spots.get("biomes", []):
			if str(biome.get("id")) != str(spec["biome"]):
				continue
			var band_list: Array = biome.get("bands", [])
			for bi in band_list.size():
				var band: Dictionary = band_list[bi]
				var list: Array = band.get("spots", [])
				for si in list.size():
					var spot: Dictionary = list[si]
					var at := _p3(spot["position"])
					var target: Vector3
					if spot.has("view_heading_deg") and spot["view_heading_deg"] != null:
						var h := deg_to_rad(float(spot["view_heading_deg"]))
						target = at + Vector3(sin(h), 0.0, cos(h)) * 90.0
					else:
						# Look along the journey: at the next spot (or back at the previous one).
						var nxt: Variant = null
						if si + 1 < list.size():
							nxt = list[si + 1]
						elif bi + 1 < band_list.size() and not (band_list[bi + 1].get("spots", []) as Array).is_empty():
							nxt = band_list[bi + 1]["spots"][0]
						elif si > 0:
							nxt = list[si - 1]
						target = _p3(nxt["position"]) if nxt != null else at + Vector3(0, 0, 90)
					target.y = NAN
					rows.append({"id": "env_%s_%d" % [str(band.get("id")), si], "label": "%s / %s" % [band.get("id"), spot.get("display_name")],
						"stands": [at], "target": target, "target_ground": 2.0, "times": spec["env_times"],
						"why": "debug_teleport_spots.json hand-checked stand; environment/terrain/sky/lighting"})
	if _kind != "env":
		var roads := _roads()
		for p: Dictionary in _places():
			var pos: Vector3 = p["pos"]
			var pick: Array = _approach(pos, roads)
			var stand: Variant = pick[0]
			var why := str(pick[1])
			if stand == null:
				stand = pos + Vector3(0, 0, -70)
				why = "NO road point 45-180 m from the landmark; stood 70 m south of it"
			var target := pos
			var tg := 3.0
			if not is_finite(target.y):
				target.y = NAN
			rows.append({"id": "place_%s" % p["id"], "label": p["label"], "stands": [stand], "target": target,
				"target_ground": tg, "times": spec["major_times"] if bool(p["major"]) else spec["place_times"], "why": why})
	return rows


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
	for i in 3000:
		await process_frame
		_director = _world.find_child("EncounterDirector", true, false)
		var shell_ok := not _world.has_method("shell_build_complete") or bool(_world.call("shell_build_complete"))
		if shell_ok and i >= 30:
			booted = true
			print("visual audit: %s booted after %d frames (director %s)" % [_region, i, _director != null])
			break
	if not booted:
		push_error("visual audit: %s shell never finished building; refusing partial-scene evidence" % _region)
		return false
	if bool(spec.get("freeze_weather", false)):
		var weather := _world.find_child("WorldWeather", true, false)
		if weather != null and weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
			weather.set_process(false)
			weather.set_physics_process(false)
	for i in 10:
		await physics_frame
	_rcam.make_current()
	if _director != null and _director.has_method("summon_active_creature"):
		_director.call("summon_active_creature")
		for i in 60:
			await physics_frame
	# DISCLOSED FIXTURE: no fight may take the camera mid-matrix (a wild engage
	# re-targets the rig to the combat pivot and it stays there). The director
	# is paused after the companion is out; creatures already streamed stay in
	# the world, frozen in place.
	if _director != null:
		_director.set_process(false)
		_director.set_physics_process(false)
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


## Stormwood Surge phase pin (tools/capture_stormwood_surge_phases.gd's method).
func _stormwood_phase(phase: String) -> void:
	var surge := _world.find_child("StormwoodSurge", true, false)
	var game := root.get_node_or_null(^"Game")
	if surge == null or game == null:
		return
	var aftermath := _variant == "aftermath"
	var rules: RefCounted = surge.get("rules")
	var region := str(surge.call("region_at", _player.global_position)) if surge.has_method("region_at") else ""
	var start := 0.0
	var t := 0.0
	while t < 6000.0 and rules != null:
		var r: Dictionary = rules.call("phase_at", t, region, false, aftermath)
		if str(r.get("phase", "")) == phase:
			start = t
			break
		t += 1.0
	var env: Dictionary = game.get("realm_environment")
	var storm: Dictionary = (env.get("stormwood", {}) as Dictionary).duplicate(true)
	storm["elapsed"] = start + 2.0
	storm["schema_version"] = 1
	env["stormwood"] = storm
	game.set("realm_environment", env)
	for i in 3:
		await process_frame
	if surge.has_method("settle_presentation"):
		surge.call("settle_presentation")
	for i in 12:
		await physics_frame


func _ally() -> Node3D:
	if _director == null or not _director.has_method("ally_body"):
		return null
	var body := _director.call("ally_body") as Node3D
	return body if body != null and is_instance_valid(body) else null


func _ground_guess(x: float, z: float, hint_y: float) -> float:
	var order: Array = ["ground_height_near", "ground_height_at"] if is_finite(hint_y) else ["ground_height_at", "ground_height_near"]
	if not is_finite(hint_y):
		hint_y = 0.0
	for method: String in order:
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


func _capture_region_row(spec: Dictionary, row: Dictionary, t: String) -> void:
	var id := str(row["id"])
	var name := "%s_%s_%s" % [_region, id, t]
	var stands: Array = row.get("stands", [])
	if stands.is_empty():
		_skip(name, "row has no stand")
		return
	var stand: Vector3 = stands[0]
	var seat := await _seat_player(stand)
	var feet: Vector3 = seat["feet"]
	if Vector2(feet.x, feet.z).distance_to(Vector2(stand.x, stand.z)) > 4.0:
		_skip(name, "trainer did not reach the stand %s (settled at %s)" % [_v(stand), _v(feet)])
		return
	RenderingServer.render_loop_enabled = false
	await _apply_time(spec, t)
	var target: Vector3 = row.get("target", feet + Vector3.FORWARD * 50.0)
	if row.has("target_ground") and not is_finite(target.y):
		target.y = _ground_guess(target.x, target.z, feet.y) + float(row["target_ground"])
	elif not is_finite(target.y):
		target.y = feet.y + 2.0
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
	if ally != null and not id.begins_with("env_"):
		# Place rows judge the landmark; park the companion out of shot.
		ally.global_position = feet + Basis(Vector3.UP, yaw) * Vector3(0.0, 0.0, 30.0)
		companion = "parked behind camera"
		ally = null
	if ally != null:
		var basis := Basis(Vector3.UP, yaw)
		var spot := feet + basis * Vector3(3.2, 0.0, -0.8)
		var fy := _floor_hit(spot, 6.0)
		ally.global_position = Vector3(spot.x, (fy if is_finite(fy) else feet.y) + 0.05, spot.z)
		if ally is CharacterBody3D:
			(ally as CharacterBody3D).velocity = Vector3.ZERO
		companion = str(ally.get("species_id")) if ally.get("species_id") != null else ally.name
	var interrupted: Array = _clear_interruptions()
	_rig.set("yaw", yaw)
	_rig.set("pitch", pitch)
	_rig.global_position = feet + Vector3.UP * float(_rig.get("_height"))
	for i in POSE_FRAMES - RENDERED_FRAMES:
		await process_frame
		interrupted += _clear_interruptions()
	RenderingServer.render_loop_enabled = true
	for i in RENDERED_FRAMES:
		await process_frame
		interrupted += _clear_interruptions()
	_rig.set("yaw", yaw)
	_rig.set("pitch", pitch)
	var arm := float(_rig.get("_distance"))
	var cam_gap := _rcam.global_position.distance_to(feet + Vector3.UP * float(_rig.get("_height")))
	if cam_gap > arm + 4.0:
		_skip(name, "camera %.1f m from the trainer pivot (rig detached); interruptions %s" % [cam_gap, interrupted])
		return
	for node in root.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
	var dist := Vector2(d.x, d.z).length()
	await _shoot(name, {"subject": id, "label": row.get("label", id), "region": _region, "time": t,
		"feet": _v(feet), "target": _v(target), "target_dist_m": snappedf(dist, 0.1),
		"yaw_deg": snappedf(rad_to_deg(yaw), 0.1), "pitch_deg": snappedf(rad_to_deg(pitch), 0.1),
		"camera": _v(_rcam.global_position), "companion": companion, "closed_dialogue": interrupted, "why": row.get("why", "")})


## An NPC greeting opened by walking onto a stand suspends the production rig
## (sequence_director: `_camera_rig.set_process(not panel)`), which leaves the
## camera at the previous stand. Close any open conversation and resume the rig.
func _clear_interruptions() -> Array:
	var closed: Array = []
	if _rig.get("_target") != _player and _rig.has_method("set_target"):
		_rig.call("set_target", _player)
		closed.append("rig_target_reset")
	for node in root.find_children("*", "", true, false):
		if node.has_method("is_open") and node.has_method("close") and node.has_method("start") and bool(node.call("is_open")):
			node.call("close")
			closed.append(str(node.name))
	_rig.set_process(true)
	_rig.set_physics_process(true)
	return closed


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
