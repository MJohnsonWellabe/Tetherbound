extends SceneTree

## Focused teardown lifecycle for the host-owned Stormwood opponent. Realm
## shell shutdown can remove the real wild body from the tree before its fight
## engine exits; cleanup must still clear the record without reading a detached
## Node3D's global transform.
const HOST_FIGHT := preload("res://scripts/combat/stormwood_authoritative_fight.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const CREATURE_BODY := preload("res://scenes/creatures/creature.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var engine := HOST_FIGHT.new()
	root.add_child(engine)
	var opponent: Node3D = CREATURE_BODY.instantiate()
	opponent.set_script(WILD)
	root.add_child(opponent)
	var target := Node3D.new()
	root.add_child(target)
	opponent.set("engaged", true)
	opponent.set("_opponent", target)
	engine.set("_wild", opponent)
	engine.set("_enemy", RefCounted.new())
	engine.set("_ally_body", target)

	# The exact shutdown ordering from the Livewire host tail: the body remains a
	# valid object but has already left SceneTree when the engine exits.
	root.remove_child(opponent)
	engine.call("stop_opponent")
	var clean := not bool(opponent.get("engaged")) \
		and opponent.get("_opponent") == null \
		and engine.get("_wild") == null \
		and engine.get("_enemy") == null \
		and engine.get("_ally_body") == null
	print("STORMWOOD AUTHORITATIVE TEARDOWN %s detached=%s clean=%s" % [
		"PASS" if clean else "FAIL", not opponent.is_inside_tree(), clean])
	opponent.free()
	target.free()
	engine.free()
	quit(0 if clean else 1)
