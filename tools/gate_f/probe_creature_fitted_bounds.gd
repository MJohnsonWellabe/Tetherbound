extends SceneTree

## Runtime counterpart to creature_scale_ladder.py's GLB/accessor audit. This
## instantiates the production creature scene and asks CreatureBody's own
## RenderBounds path for the final fitted mesh, including all 12 namespaced
## Water presentations registered by CreatureSpecies.
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TRAINER_HEIGHT_M := 1.80
const TOLERANCE_M := 0.02
const REPORT_PATH := "res://ralph/reports/FOUR-BIOME-BUILD/road-visual-creatures/runtime-fitted-bounds.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node3D.new()
	stage.name = "FittedBoundsStage"
	root.add_child(stage)
	var rows: Array[Dictionary] = []
	var failures: Array[String] = []
	var ids: Array = SPECIES.table().keys()
	ids.sort()
	for id_variant: Variant in ids:
		var species_id := str(id_variant)
		var wild: Node3D = CREATURE_SCENE.instantiate()
		wild.set_script(CREATURE_BODY)
		wild.name = "Bounds_" + species_id
		stage.add_child(wild)
		wild.call("setup", species_id)
		var declared := float(wild.call("body_height"))
		var bounds: AABB = wild.call("_bounds", wild.get_node("Model"))
		var fitted := bounds.size.y
		rows.append({
			"id": species_id,
			"declared_height_m": snappedf(declared, 0.000001),
			"fitted_render_height_m": snappedf(fitted, 0.000001),
			"fitted_width_m": snappedf(bounds.size.x, 0.000001),
			"fitted_depth_m": snappedf(bounds.size.z, 0.000001),
		})
		if fitted <= TRAINER_HEIGHT_M:
			failures.append("%s fits to %.3fm, below trainer" % [species_id, fitted])
		if absf(fitted - declared) > TOLERANCE_M:
			failures.append("%s fits to %.3fm, declared %.3fm" % [species_id, fitted, declared])
		wild.free()
	var payload := {
		"trainer_height_m": TRAINER_HEIGHT_M,
		"tolerance_m": TOLERANCE_M,
		"species_count": rows.size(),
		"rows": rows,
		"failures": failures,
	}
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload, "  ") + "\n")
	if not failures.is_empty():
		for failure in failures:
			push_error("FITTED BOUNDS FAIL: " + failure)
		quit(1)
		return
	print("FITTED BOUNDS PASS: %d runtime presentations, min > %.2fm; mosshock and tanglevolt included" % [rows.size(), TRAINER_HEIGHT_M])
	quit(0)
