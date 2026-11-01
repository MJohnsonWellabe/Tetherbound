extends "res://tools/phase2_capture_dialogue.gd"

## Diagnostic for GPU DLG-1 (14 of 34 dialogue frames had the conversation
## camera inactive). At the moment the capture opens the panel, print what the
## conversation camera would resolve: the arbiter's winning provider, every
## provider within 8 m (enabled, radius, distance, whether it resolves to a
## character) and the conversation camera's result. Prints only; changes nothing.
const CONV := preload("res://scripts/player/conversation_camera.gd")
var _probe_frame := ""


func _capture_row(row: Dictionary) -> void:
	_probe_frame = str(row.frame_id)
	await super._capture_row(row)


func _settle_dialogue_capture() -> bool:
	var ok := await super._settle_dialogue_capture()
	var arbiter := get_first_node_in_group("interaction_arbiter")
	var winner: Variant = arbiter.call("winning_provider") if arbiter != null else null
	var conv := get_first_node_in_group(CONV.GROUP)
	var line := {"frame": _probe_frame,
		"winner": str(winner.get_path()) if is_instance_valid(winner) and winner is Node else "null",
		"winner_resolves": is_instance_valid(winner) and winner is Node3D and CONV.resolve_speaker(winner as Node3D) != null,
		"pushed_in": conv != null and bool(conv.call("is_pushed_in")),
		"player": _player.global_position}
	var near: Array = []
	for node: Node in root.find_children("*", "Node3D", true, false):
		if node.has_method("interaction_offer"):
			var n3 := node as Node3D
			var d := n3.global_position.distance_to(_player.global_position)
			if d < 8.0:
				near.append({"path": str(n3.get_path()).right(70), "enabled": node.get("enabled"),
					"radius": node.get("radius"), "dist": snappedf(d, 0.01),
					"resolves": CONV.resolve_speaker(n3) != null,
					"offer": not (node.call("interaction_offer", _player.global_position) as Dictionary).is_empty()})
	line["near"] = near
	print("DLG_PROBE ", JSON.stringify(line))
	return ok


## Custom per-launch flow; not validated for batched --jobs launches.
func _supports_jobs() -> bool:
	return false
