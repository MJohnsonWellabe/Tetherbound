extends SceneTree

## OWNER DIRECTIVE 2026-09-01 extension: "bigger or brighter", and other small
## creatures beside Bramblebun. Two additions to the 2026-08-31 session's own
## extension of this probe, same spirit (sweep the live species table against
## a real render, do not fake the lever by touching a node directly):
##   `--extra-emission=` sweeps `placeholder.field_emission`
##   (`creature_body.gd::_apply_field_brightness()`) at the SHIPPED height,
##   the emission-energy lever traced from `_apply_field_separation()`'s own
##   "these models are self-lit" reasoning for why the rim alone could not
##   reach bramblebun's target ratio.
##   `--species=` points the whole probe (camera stand, SHIPPED read, spawn)
##   at a different species than Bramblebun, so the same tool answers the
##   same question for terrapup and others without a rewrite.

## OWNER DIRECTIVE 2026-08-28 §2b, judged the way the owner will judge it: a
## wild creature at throwing range, in real grass, with the throw cone up.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_grass_separation.gd -- --out=ralph/reports/hud-catch/shots
##
## NEVER `--headless` with a real rendering driver -- see
## `tools/_capture_ui_survey.gd`'s header for that trap and what it has cost.
##
## Why this exists rather than reusing `capture_catch_sequence.gd`: that tool's
## aim frame moved between runs because THIS LANE also added target acquisition,
## so the before and after frames had different camera poses and a hand-placed
## measurement box across two framings measures the box. A controlled A/B has
## to hold the camera still and change one thing at a time, which is what this
## does: one world boot, one fixed camera pose, four variants of the same
## Bramblebun rendered from it.
##
##   A  0.78m, no rim   -- what the owner played
##   B  0.96m, no rim   -- scale alone
##   C  0.78m, rim 0.22 -- rim alone
##   D  0.96m, rim 0.22 -- what ships
##
## Both levers are isolated on purpose. The coordinator's rule is that if a
## creature clears the grass and is still invisible then height was never its
## problem -- C and B are what let that be answered instead of assumed.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const DEFAULT_SPECIES_ID := "bramblebun"
## Overridable by `--species=`; see this session's header note.
var SPECIES_ID := DEFAULT_SPECIES_ID
const SETTLE_FRAMES := 300
const POSE_FRAMES := 24

## Metres from the camera to the creature: the throwing range the launch log
## reports for a real fight (7.4-8.1m across four commits).
const RANGE := 7.6
const EYE_HEIGHT := 1.78

var _out_dir := "res://ralph/reports/hud-catch/shots"
var _world: Node = null
var _camera: Camera3D = null
var _body: Node3D = null
var _written: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return
	var extra_heights: Array[float] = []
	var extra_emissions: Array[float] = []
	var extra_degreens: Array[float] = []
	var extra_field_scales: Array[float] = []
	var skip_baseline := false
	# G3-CREATURE-COLOUR-0904. `--time=` points the probe's own WorldLook at a
	# named preset (`day`/`golden`/`night`/`dawn`) before shooting, the same
	# `apply_time()` call `tools/_capture_night_legibility.gd` uses -- without
	# this the probe always renders at whatever the scene boots at (day), which
	# cannot answer whether a value/hue lever tuned for the daytime grass-
	# separation bar also reads correctly once `world_look.gd`'s night grade and
	# this species' own time-of-day field-brightness scale are both live.
	var time_of_day := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
		elif arg.begins_with("--time="):
			time_of_day = arg.substr(7)
		elif arg.begins_with("--extra-heights="):
			for token in arg.substr(16).split(","):
				if token.strip_edges() != "":
					extra_heights.append(token.strip_edges().to_float())
		elif arg.begins_with("--extra-emission="):
			for token in arg.substr(17).split(","):
				if token.strip_edges() != "":
					extra_emissions.append(token.strip_edges().to_float())
		elif arg.begins_with("--extra-degreen="):
			for token in arg.substr(16).split(","):
				if token.strip_edges() != "":
					extra_degreens.append(token.strip_edges().to_float())
		elif arg.begins_with("--extra-field-scale="):
			# G3-CREATURE-COLOUR-0904. Sweeps `creature_body.gd::set_field_brightness_scale()`
			# directly -- the night-side lever `world_look.gd` normally drives off
			# `art.json`'s `creature_field_emission_scale` -- without needing a
			# config edit + engine restart per value tried. `--time=` still
			# decides the LIGHT the creature sits in; this decides how far the
			# per-species push is scaled down on top of it, so the two compose
			# exactly the way a real night does.
			for token in arg.substr(20).split(","):
				if token.strip_edges() != "":
					extra_field_scales.append(token.strip_edges().to_float())
		elif arg.begins_with("--species="):
			SPECIES_ID = arg.substr(10)
		elif arg == "--skip-baseline":
			skip_baseline = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	if time_of_day != "":
		var look: Node = _world.get_node_or_null(^"WorldLook")
		if look == null:
			print("WARNING: --time=%s given but no WorldLook in the scene" % time_of_day)
		else:
			# G3-CREATURE-COLOUR-0904. `world_look.gd::_process()` keeps the clock
			# running and re-blends the FULL environment (art.json's own
			# `creature_field_emission_scale` included) every BLEND_INTERVAL --
			# without freezing it, that continuous re-apply stomps a
			# `--extra-field-scale=` variant's manual override within a couple of
			# frames, and every variant in a sweep silently converges on
			# whatever art.json's OWN configured value is instead of the one
			# actually being tested. `set_clock_frozen()` is `world_look.gd`'s
			# own public API for exactly this (survey/capture tooling already
			# relies on it staying still).
			look.call("set_clock_frozen", true)
			look.call("apply_time", time_of_day)
			for i in SETTLE_FRAMES:
				await physics_frame
			print("time of day set to %s" % time_of_day)

	# A patch of open meadow with the grass field on. Taken from the same area
	# `capture_catch_sequence.gd` fights in, so the field is the one the owner
	# played rather than a bare test plane.
	var stand := Vector3(36.0, 0.0, -50.0)
	stand.y = _ground(stand)

	_camera = Camera3D.new()
	_world.add_child(_camera)
	_camera.global_position = stand + Vector3(0.0, EYE_HEIGHT, 0.0)
	var look_at := stand + Vector3(RANGE, 0.0, 0.0)
	look_at.y = _ground(look_at)
	_camera.look_at(look_at + Vector3(0.0, 0.45, 0.0), Vector3.UP)
	_camera.fov = 52.0
	_camera.make_current()

	# Re-bind the grass field to THIS camera, or the whole probe is worthless.
	# `grass_field.gd::_process` grows its ring around the camera
	# `playground_world.gd` bound at startup, and a probe that mints its own
	# camera gets a creature standing on baked ground cover with no field around
	# it at all. A first run did exactly that and produced four frames of a
	# rabbit on a lawn -- which cannot answer a question about tall grass.
	# `bind()` is grass_field.gd's own public API; nothing in that file changes.
	var field := _find_grass_field(_world)
	if field == null:
		print("WARNING: no GrassField in the scene; these frames do not test the field")
	else:
		field.call("bind", field.get("_terrain"), _camera)
		for i in 30:
			await physics_frame
		print("grass field re-bound to the probe camera")

	var variants: Array[Dictionary] = []
	if not skip_baseline:
		variants.append({"tag": "A-0.78-norim", "height": 0.78, "rim": 0.0, "emission": 0.0})
		variants.append({"tag": "B-0.96-norim", "height": 0.96, "rim": 0.0, "emission": 0.0})
		variants.append({"tag": "C-0.78-rim", "height": 0.78, "rim": 0.22, "emission": 0.0})
		variants.append({"tag": "D-0.96-rim", "height": 0.96, "rim": 0.22, "emission": 0.0})

	# SHIPPED: whatever height/field_rim/field_emission species.json currently
	# carries for this species, read live rather than hardcoded -- the gap the
	# audit addendum named (the two baseline heights above never test the real
	# shipped value).
	var species := load("res://scripts/creatures/creature_species.gd")
	var live_table: Dictionary = species.call("placeholder", SPECIES_ID)
	var shipped_height: float = float(live_table.get("height", 0.78))
	var shipped_rim: float = float(live_table.get("field_rim", 0.0))
	var shipped_emission: float = float(live_table.get("field_emission", 0.0))
	var shipped_degreen: float = float(live_table.get("field_degreen", 0.0))
	variants.append({
		"tag": "SHIPPED-%.2f" % shipped_height, "height": shipped_height, "rim": shipped_rim,
		"emission": shipped_emission, "degreen": shipped_degreen,
	})
	for h in extra_heights:
		variants.append({
			"tag": "TEST-h%.2f" % h, "height": h, "rim": shipped_rim, "emission": shipped_emission,
			"degreen": shipped_degreen,
		})
	for e in extra_emissions:
		variants.append({
			"tag": "TEST-e%.2f" % e, "height": shipped_height, "rim": shipped_rim, "emission": e,
			"degreen": shipped_degreen,
		})
	for g in extra_degreens:
		variants.append({
			"tag": "TEST-g%.2f" % g, "height": shipped_height, "rim": shipped_rim,
			"emission": shipped_emission, "degreen": g,
		})
	for fs in extra_field_scales:
		variants.append({
			"tag": "TEST-fs%.2f" % fs, "height": shipped_height, "rim": shipped_rim,
			"emission": shipped_emission, "degreen": shipped_degreen, "field_scale": fs,
		})

	for variant: Dictionary in variants:
		await _shoot(variant, look_at)

	print("")
	for line: String in _written:
		print("  %s" % line)
	print("%d frames -> %s" % [_written.size(), _out_dir])
	print("Software rendering: composition, contrast and readability only.")
	quit(0)


## One variant. The species table is edited in place around each shot so both
## levers really do run through the production path -- `creature_body.gd` reads
## `placeholder.height` and `placeholder.field_rim` from it -- rather than being
## faked by scaling a node, which is the invisible discrepancy PW2 forbids and
## which would not exercise the rim at all.
func _shoot(variant: Dictionary, at: Vector3) -> void:
	var species := load("res://scripts/creatures/creature_species.gd")
	var table: Dictionary = species.call("placeholder", SPECIES_ID)
	var original_height: float = float(table.get("height", 0.78))
	var original_rim: float = float(table.get("field_rim", 0.0))
	var original_emission: float = float(table.get("field_emission", 0.0))
	var original_degreen: float = float(table.get("field_degreen", 0.0))
	table["height"] = float(variant["height"])
	table["field_rim"] = float(variant["rim"])
	table["field_emission"] = float(variant.get("emission", 0.0))
	table["field_degreen"] = float(variant.get("degreen", 0.0))
	# ONLY when a variant opts in. An earlier version of this line ran
	# unconditionally with a `1.0` default, which silently overrode whatever
	# `--time=`/`apply_time()` had just set through the REAL config path
	# (`world_look.gd` reading `art.json`'s own `creature_field_emission_scale`)
	# -- every ordinary SHIPPED/height/emission/degreen variant was secretly
	# forced back to the daytime (1.0) scale even at `--time=night`, which is
	# exactly the config-driven behaviour this probe exists to verify. Leaving
	# the scale untouched here means those variants render whatever the clock
	# actually set; only an explicit `--extra-field-scale=` variant drives it
	# directly.
	if variant.has("field_scale"):
		CREATURE_BODY.set_field_brightness_scale(float(variant["field_scale"]))

	if _body != null and is_instance_valid(_body):
		_body.queue_free()
		await process_frame
	_body = _spawn(at)
	if _body == null:
		print("FAIL: could not spawn %s" % SPECIES_ID)
		return
	for i in POSE_FRAMES:
		await physics_frame
	print("  %s: rim materials on the model = %d" % [variant["tag"], _count_rim(_body)])

	var path := "%s/grass-%s.png" % [_out_dir, variant["tag"]]
	var image := get_root().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(path))
	_written.append("%-14s height %.2f rim %.2f emission %.2f degreen %.2f -> %s" % [
		variant["tag"], float(variant["height"]), float(variant["rim"]),
		float(variant.get("emission", 0.0)), float(variant.get("degreen", 0.0)), path])

	table["height"] = original_height
	table["field_rim"] = original_rim
	table["field_emission"] = original_emission
	table["field_degreen"] = original_degreen


## The same three steps `encounter_director.gd` takes for a real wild spawn:
## instantiate the scriptless body scene, attach `wild_creature.gd`, then
## `populate(species, player)`. Anything less would not run the production
## dressing path and the rim would never be applied.
func _spawn(at: Vector3) -> Node3D:
	var scene: PackedScene = load("res://scenes/creatures/creature.tscn")
	if scene == null:
		return null
	var body: Node3D = scene.instantiate()
	body.set_script(load("res://scripts/creatures/wild_creature.gd"))
	body.name = "GrassProbe_%s" % SPECIES_ID
	_world.add_child(body)
	body.global_position = at
	body.call("populate", SPECIES_ID, null)
	body.global_position = at
	return body


## How many of the body's surfaces actually carry a rim. A frame where the rim
## reads faintly and a frame where it was never applied look identical, and
## only one of them is a tuning question.
func _count_rim(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var material := instance.get_active_material(surface)
			if material is BaseMaterial3D and (material as BaseMaterial3D).rim_enabled:
				count += 1
	for child in node.get_children():
		count += _count_rim(child)
	return count


func _find_grass_field(node: Node) -> Node:
	if node.get_script() != null \
			and String(node.get_script().resource_path).ends_with("grass_field.gd"):
		return node
	for child in node.get_children():
		var found := _find_grass_field(child)
		if found != null:
			return found
	return null


func _ground(at: Vector3) -> float:
	if _world != null and _world.has_method("ground_height_at"):
		return float(_world.call("ground_height_at", at.x, at.z))
	return 0.0
