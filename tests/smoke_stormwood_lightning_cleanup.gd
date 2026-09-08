extends SceneTree

## Real warning/impact/timeout lifecycle without building a terrain world.
const LIGHTNING := preload("res://scripts/world/stormwood_lightning.gd")

class WorldFixture extends Node3D:
	var simulation_only := false

class SessionFixture extends Node:
	func local_peer_id() -> int: return 1

class LightningFixture extends LIGHTNING:
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var world := WorldFixture.new()
	root.add_child(world)
	var session := SessionFixture.new()
	world.add_child(session)
	var lightning := LightningFixture.new()
	world.add_child(lightning)
	lightning.world = world
	lightning.session = session
	lightning._receive({"id": 1, "kind": "warning", "at": Vector3.ZERO})
	var impacted: Node = lightning._visuals[1]
	lightning._receive({"id": 1, "kind": "impact", "at": Vector3.ZERO, "hits": {}})
	lightning._receive({"id": 2, "kind": "warning", "at": Vector3.ONE})
	var expired: Node = lightning._visuals[2]
	await create_timer(0.3).timeout
	var impact_freed := not is_instance_valid(impacted)
	await create_timer(3.0).timeout
	var expiry_freed := not is_instance_valid(expired)
	var clean := lightning._visuals.is_empty()
	print("LIGHTNING CLEANUP impact_freed=%s expiry_freed=%s registry_empty=%s" % [
		impact_freed, expiry_freed, clean])
	world.free()
	quit(0 if impact_freed and expiry_freed and clean else 1)
