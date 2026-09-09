extends SceneTree

func _initialize() -> void:
	var probe := preload("res://tools/probe_realm_transition_adapter_peer.gd").new()
	probe.name = "TransitionAdapterProbe"
	root.add_child.call_deferred(probe)
