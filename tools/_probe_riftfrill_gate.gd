extends SceneTree

## D71/T3-SUNSTONE, Job 3: is Riftfrill genuinely in the game?
##
##   godot --headless --path . --script tools/_probe_riftfrill_gate.gd
##
## T3-CREATURES's own handover verified the night/weather gate mechanism by
## READING `encounter_director.gd::_gate_active()` end to end and called it
## "real and complete" -- but also said plainly: "Nobody has seen any of these
## four creatures in the running game." This probe closes that gap for
## Riftfrill specifically, live, in one boot: does the species entry resolve
## to a real wild body at the authored coordinate, is the ground under it
## walkable, and does `_sync_spawn_gates()` actually flip its visibility when
## the world clock crosses into night -- rather than trusting that the code
## path which does that for Duskhush/Reedwing also does it here.
##
## Does NOT attempt visual verification (deliberately, per this lane's brief:
## the variant renders as an unmodified Paddlenewt until T1-CREATURE-ART lands
## the recolour/VFX, and a frame of that would judge the missing art, not this
## lane's work).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240

const RIFTFRILL_AT := Vector2(-176.0, 4098.0)
const DAY_HOUR := 12.0
const NIGHT_HOUR := 2.0


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var field: RefCounted = HEIGHTFIELD.new()
	var ground: float = field.call("height_at", RIFTFRILL_AT.x, RIFTFRILL_AT.y)
	if is_nan(ground):
		print("FAIL: no ground under the authored Riftfrill coordinate (%.1f, %.1f)" % [RIFTFRILL_AT.x, RIFTFRILL_AT.y])
	else:
		print("ground under Riftfrill's coordinate: %.2fm -- real, walkable heightfield" % ground)

	var director: Node = world.get_node_or_null(^"EncounterDirector")
	if director == null:
		print("FAIL: no EncounterDirector in the booted scene")
		quit(1)
		return

	var riftfrill: Node3D = null
	for wild: Node3D in world.get_tree().get_nodes_in_group(&"wild_creature"):
		if str(wild.get("species_id")) == "riftfrill":
			riftfrill = wild
			break
	if riftfrill == null:
		# Fall back to the director's own gate table in case this build's
		# wild bodies are not (also) in a "wild_creature" group.
		var gates: Dictionary = director.get("_wild_gates")
		for wild: Node3D in gates.keys():
			if is_instance_valid(wild) and str(wild.get("species_id")) == "riftfrill":
				riftfrill = wild
				break

	if riftfrill == null:
		print("FAIL: no live wild body with species_id 'riftfrill' found in the booted world")
		quit(1)
		return

	var dist := Vector2(riftfrill.global_position.x, riftfrill.global_position.z).distance_to(RIFTFRILL_AT)
	print("found riftfrill wild body at (%.1f, %.1f), %.1fm from the authored centre" % [
		riftfrill.global_position.x, riftfrill.global_position.z, dist])

	var look: Node = world.get_node_or_null(^"WorldLook")
	if look == null:
		print("FAIL: no WorldLook; cannot exercise the night gate")
		quit(1)
		return
	var cycle: RefCounted = look.get("_cycle")

	look.set("_elapsed_seconds", float(cycle.call("elapsed_for_hour", DAY_HOUR)))
	look.call("_apply_blended", DAY_HOUR)
	for i in 5:
		await physics_frame
	print("hour %.1f (day)   riftfrill.visible = %s" % [DAY_HOUR, riftfrill.visible])

	look.set("_elapsed_seconds", float(cycle.call("elapsed_for_hour", NIGHT_HOUR)))
	look.call("_apply_blended", NIGHT_HOUR)
	for i in 5:
		await physics_frame
	print("hour %.1f (night) riftfrill.visible = %s" % [NIGHT_HOUR, riftfrill.visible])

	quit(0)
