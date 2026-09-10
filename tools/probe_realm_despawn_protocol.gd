extends SceneTree

const PEER := preload("res://tools/probe_realm_despawn_protocol_peer.gd")

func _initialize() -> void:
	var hub := PEER.new()
	hub.name = "ProtocolProbe"
	root.add_child.call_deferred(hub)
