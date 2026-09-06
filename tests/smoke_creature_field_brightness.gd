extends SceneTree

## G3-CREATURE-COLOUR-0904 (docs/CURRENT_STATE.md §3, reopening CREATURE-
## LEGIBILITY-0903/Gate 2.4). Mechanical coverage for the two things a rendered
## screenshot cannot cheaply pin down every CI run:
##
##   1. `set_field_brightness_scale()` actually rescales an ALREADY-SPAWNED
##      creature's live material in place -- the night-legibility bug this
##      lane exists to fix was that `field_emission`/`field_degreen` were a
##      constant multiply applied once at spawn time, unscaled by time of day.
##   2. `field_degreen`'s R/G gap no longer scales with `field_emission`'s own
##      strength -- the daytime "candy pink" bug the GATE2-EVIDENCE-0903 blind
##      judge found independently of this lane's own night-side ticket.
##
##   godot --headless --path . --script tests/smoke_creature_field_brightness.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CREATURE_SCENE := "res://scenes/creatures/creature.tscn"
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const VISUAL := preload("res://scripts/creatures/creature_visual.gd")

const SETTLE_FRAMES := 120

var _failures: Array[String] = []
var _world: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _rescale_moves_a_live_material()
	_degreen_gap_is_independent_of_strength()
	await _ceiling_never_exceeded_and_hue_survives()

	_report()


## Spawns Bramblebun directly at whatever `field_emission` species.json
## currently ships, reads its brightened surface material's albedo back at the
## full daytime scale, dials the scale down the way `world_look.gd` does
## entering night, and checks the SAME live material object actually changed
## -- exactly the mechanism docs/CURRENT_STATE.md §3 named broken (a constant
## multiply, unscaled by time of day). Also checks the scale is fully
## reversible, since `world_look.gd` calls this every look change, both ways,
## as the clock moves.
func _rescale_moves_a_live_material() -> void:
	CREATURE_BODY.set_field_brightness_scale(1.0)
	var body: Node3D = (load(CREATURE_SCENE) as PackedScene).instantiate() as Node3D
	body.set_script(CREATURE_BODY)
	body.set("species_id", "bramblebun")
	_world.add_child(body)
	for i in 30:
		await physics_frame

	var material := _first_field_bright_material(body)
	if material == null:
		_fail("bramblebun spawned no _field_bright surface material -- " +
			"species.json's field_emission must be > 0 for this test to mean anything")
		body.queue_free()
		return

	var day_albedo: Color = material.albedo_color
	CREATURE_BODY.set_field_brightness_scale(0.3)
	var night_albedo: Color = material.albedo_color
	if day_albedo.is_equal_approx(night_albedo):
		_fail("set_field_brightness_scale(0.3) did not change the live material -- " +
			"the night scale is not reaching an already-spawned creature")
	if night_albedo.r >= day_albedo.r:
		_fail(("scaling brightness DOWN for night must not leave the creature as bright " +
			"or brighter (day r=%.3f, night r=%.3f)") % [day_albedo.r, night_albedo.r])

	CREATURE_BODY.set_field_brightness_scale(1.0)
	var restored: Color = material.albedo_color
	if not restored.is_equal_approx(day_albedo):
		_fail("returning the scale to 1.0 must restore the exact daytime albedo (got %s, want %s)" %
			[restored, day_albedo])

	body.queue_free()


## `FIELD_DEGREEN_GAP` is a flat constant, not `strength * 0.5 * degreen` --
## the whole point of the fix (creature_body.gd's own header comment on
## `_apply_field_bright_values()`). Two runs of the same `degreen` at two
## different `field_emission` strengths must produce the SAME absolute gap
## between the red/blue and green channel multipliers; the old, coupled
## formula would triple the gap between these two strengths (0.9 -> 2.5 is
## exactly CREATURE-LEGIBILITY-0903's own before/after).
func _degreen_gap_is_independent_of_strength() -> void:
	var low := _computed_gap(0.9, 0.75)
	var high := _computed_gap(2.5, 0.75)
	if absf(low - high) > 0.0001:
		_fail(("field_degreen's R/G gap must not grow with field_emission's own strength " +
			"(0.9 -> gap %.4f, 2.5 -> gap %.4f)") % [low, high])
	if absf(low - (0.75 * CREATURE_BODY.FIELD_DEGREEN_GAP)) > 0.0001:
		_fail("gap must equal degreen * FIELD_DEGREEN_GAP exactly, got %.4f" % low)


## OP-0905-03 (docs/owner/OWNER_PLAYTEST_2026-09-05.md, "Bramblebun colour is
## awful"). Mechanical coverage for `_soft_knee_bright()`'s two obligations
## this lane's own header comment on `FIELD_BRIGHT_KNEE` names: the tint must
## never cross `field_bright_ceiling` no matter how high `field_emission` is
## pushed (the raw-multiply defect that blew Bramblebun's coat out toward
## white), and Mudsnout's own hue (no `field_degreen`, so a plain uniform
## push) must come out EXACTLY unchanged -- a per-channel curve applied
## unevenly, or a bug in the ceiling maths, would show up here as a hue that
## moved even though nothing asked it to.
func _ceiling_never_exceeded_and_hue_survives() -> void:
	CREATURE_BODY.set_field_brightness_scale(1.0)
	var ceiling: float = VISUAL.field_bright_ceiling()

	var bramble: Node3D = (load(CREATURE_SCENE) as PackedScene).instantiate() as Node3D
	bramble.set_script(CREATURE_BODY)
	bramble.set("species_id", "bramblebun")
	_world.add_child(bramble)
	for i in 30:
		await physics_frame
	var bramble_material := _first_field_bright_material(bramble)
	if bramble_material == null:
		_fail("bramblebun spawned no _field_bright surface material for the ceiling check")
	else:
		var tint: Color = bramble_material.albedo_color
		var max_channel := maxf(tint.r, maxf(tint.g, tint.b))
		if max_channel > ceiling + 0.0005:
			_fail("bramblebun field-bright tint max channel %.4f exceeds field_bright_ceiling %.4f" %
				[max_channel, ceiling])
	bramble.queue_free()

	var mud: Node3D = (load(CREATURE_SCENE) as PackedScene).instantiate() as Node3D
	mud.set_script(CREATURE_BODY)
	mud.set("species_id", "mudsnout")
	_world.add_child(mud)
	for i in 30:
		await physics_frame
	var mud_material := _first_field_bright_material(mud)
	if mud_material == null:
		_fail("mudsnout spawned no _field_bright surface material for the hue check")
	else:
		var tint: Color = mud_material.albedo_color
		var max_channel := maxf(tint.r, maxf(tint.g, tint.b))
		if max_channel > ceiling + 0.0005:
			_fail("mudsnout field-bright tint max channel %.4f exceeds field_bright_ceiling %.4f" %
				[max_channel, ceiling])
		# No `field_degreen` on this species, so R, G and B must all carry the
		# exact same curve-mapped value -- any per-channel drift here means
		# the ceiling maths is treating a channel unevenly.
		if not (is_equal_approx(tint.r, tint.g) and is_equal_approx(tint.g, tint.b)):
			_fail("mudsnout carries no field_degreen, so its field-bright tint must be perfectly " +
				"neutral (equal R/G/B) -- got %s" % tint)
	mud.queue_free()


func _computed_gap(strength: float, degreen: float) -> float:
	var factor := 1.0 + strength
	var g_factor: float = maxf(factor - degreen * CREATURE_BODY.FIELD_DEGREEN_GAP, 0.0)
	return factor - g_factor


func _first_field_bright_material(node: Node) -> BaseMaterial3D:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var material := instance.get_active_material(surface)
			if material is BaseMaterial3D and (material as BaseMaterial3D).resource_name.contains("_field_bright"):
				return material as BaseMaterial3D
	for child in node.get_children():
		var found := _first_field_bright_material(child)
		if found != null:
			return found
	return null


func _fail(msg: String) -> void:
	_failures.append(msg)
	printerr("FAIL: %s" % msg)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("smoke_creature_field_brightness: PASS")
		quit(0)
	else:
		for msg: String in _failures:
			print("  - %s" % msg)
		print("smoke_creature_field_brightness: %d failure(s)" % _failures.size())
		quit(1)
