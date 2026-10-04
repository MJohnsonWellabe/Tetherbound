extends SceneTree

## Owner ruling 2026-10-04: Grandpa's home has one free creature bed that heals
## creatures through the ordinary creature_bed path. Boots the real Meadows
## world and checks the built bed (placement, reserved index, prompt, no
## tournament credit), then puts a hurt party creature to bed through the bed's
## own assign_creature and runs Game's own bed-recovery tick for
## progression.json's creature_bed.full_heal_seconds.
##
##   godot --headless --path . --script tests/smoke_home_creature_bed.gd
const SCENE := "res://scenes/world/meadows_playground.tscn"
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok:
		_failures.append(what)


func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	var party: RefCounted = game.get("party")
	if (party.call("members") as Array).is_empty():
		party.call("add", game.call("make_creature", "terrapup"))
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 240:
		await physics_frame
	var spec: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/config/village.json")) as Dictionary).home_creature_bed
	var bed := world.get_node_or_null("GrandpaHouse/HomeCreatureBed") as Node3D
	_check(bed != null and bed.get_script() == preload("res://scripts/build/creature_bed.gd"), "the home bed is the installed creature_bed component")
	if bed == null:
		quit(1)
		return
	var want := Vector2(float(spec.at[0]), float(spec.at[1]))
	_check(Vector2(bed.global_position.x, bed.global_position.z).distance_to(want) < 0.05, "home bed stands at its authored spot %s (got %s)" % [want, bed.global_position])
	_check(absf(bed.global_position.y - float(world.call("ground_height_at", want.x, want.y))) < 0.05, "home bed stands on the ground")
	_check(int(bed.call("build_index")) == int(spec.bed_index) and int(spec.bed_index) <= -10, "home bed uses its reserved authored index %d" % int(spec.bed_index))
	var prompt := bed.get_node_or_null("Interactable")
	_check(prompt != null, "home bed carries the ordinary 'Rest a Creature' prompt")
	_check(not bool(game.get("progression").call("has", "creature_bed_built")), "the free bed does not credit the player's own Build a Creature Bed rung")
	# Nothing solid but the bed itself and the ground inside its footprint.
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 1.2, 2.05)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(bed.global_basis, bed.global_position + Vector3(0, 0.9, 0))
	var foreign: Array[String] = []
	for hit: Dictionary in world.get_world_3d().direct_space_state.intersect_shape(query, 16):
		var node := hit.collider as Node
		if node != null and not bed.is_ancestor_of(node) and node != bed and not str(node.name).begins_with("Terrain"):
			foreign.append(str(node.get_path()))
	_check(foreign.is_empty(), "home bed footprint is clear of other colliders %s" % str(foreign))
	# Heal through the bed's own occupancy and Game's own recovery tick.
	var creature: RefCounted = party.call("at", 0)
	var max_hp := float(creature.get("max_hp"))
	creature.set("hp", max_hp * 0.1)
	_check(bool(bed.call("assign_creature", 0)), "a hurt party creature can be put to bed at home")
	_check(bool(creature.get("resting")) and int(creature.get("rest_bed_index")) == int(spec.bed_index), "the creature rests in the home bed")
	var seconds := PROGRESSION.creature_bed_full_heal_seconds(PROGRESSION.config())
	var steps := 60
	for _i in steps:
		game.call("_tick_creature_bed_recovery", seconds / float(steps))
	_check(is_equal_approx(float(creature.get("hp")), max_hp), "home bed heals to full in creature_bed.full_heal_seconds (%.0f s): hp %.1f / %.1f" % [seconds, float(creature.get("hp")), max_hp])
	_check(bool(bed.call("wake_creature_early")) and not bool(creature.get("resting")), "the creature can be woken from the home bed")
	print("home creature bed: %s" % ("OK" if _failures.is_empty() else "FAIL %s" % str(_failures)))
	quit(0 if _failures.is_empty() else 1)
