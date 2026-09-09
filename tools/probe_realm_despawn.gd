extends SceneTree

const PEER := preload("res://tools/probe_realm_despawn_peer.gd")

func _initialize() -> void:
	var hub := PEER.new()
	hub.name = "DespawnProbe"
	root.add_child.call_deferred(hub)
