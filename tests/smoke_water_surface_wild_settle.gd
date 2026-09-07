extends SceneTree

const DIRECTOR := preload("res://scripts/combat/water_encounter_director.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const SPECIES := "mosshell"
const SURFACE_Y := 10.0
const SUBMERGE := 0.28
const SETTLE_FRAMES := 180


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node3D.new()
	stage.name = "WaterSurfaceSettleStage"
	root.add_child(stage)
	var wild: Node3D = CREATURE_SCENE.instantiate()
	wild.set_script(DIRECTOR.SurfaceWild)
	wild.name = "SurfaceMosshell"
	stage.add_child(wild)
	if not bool(wild.call("populate", SPECIES, null)):
		_fail("could not populate surface test creature")
		return
	wild.call("configure_water_surface", SURFACE_Y, SUBMERGE)
	if not bool(wild.call("place_on_ground", Vector3(0.0, -65.0, 0.0))):
		_fail("surface placement refused")
		return
	var expected := SURFACE_Y - float(wild.call("body_height")) * SUBMERGE
	var maximum_error := 0.0
	for _frame in SETTLE_FRAMES:
		await physics_frame
		maximum_error = maxf(maximum_error, absf(wild.global_position.y - expected))
	if maximum_error > 0.001:
		_fail("surface wild sank during settle: max error %.4fm" % maximum_error)
		return
	if absf(wild.velocity.y) > 0.001:
		_fail("surface wild retained vertical velocity: %.4f" % wild.velocity.y)
		return
	print("WATER SURFACE WILD SETTLE PASS: %d frames, max drift %.4fm" % [SETTLE_FRAMES, maximum_error])
	quit(0)


func _fail(message: String) -> void:
	push_error("WATER SURFACE WILD SETTLE FAIL: " + message)
	quit(1)
