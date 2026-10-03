extends SceneTree

## Component regression for freed references observed in earned R9.
## Actual presenter classes, detached visual fixtures; no travel/play verdict.
const CAPTURE := preload("res://tests/helpers/f18_presentation_capture.gd")
const HOME := preload("res://scripts/world/home_key.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	var observer := CAPTURE.new()
	observer.set("_game", root.get_node(^"Game"))
	observer.set("_started_msec", Time.get_ticks_msec())
	root.add_child(observer)
	observer.set_process(false)
	var key := HOME.new()
	var remote := HOME.new()
	key.add_child(remote)
	for presenter: Node in [key, remote]:
		for pair: Array in [["_actor", Node3D.new()], ["_rig", Skeleton3D.new()],
			["_prop", BoneAttachment3D.new()], ["_glow", OmniLight3D.new()],
			["_audio", AudioStreamPlayer.new()]]:
			presenter.set(str(pair[0]), pair[1])
			(pair[1] as Node).free()
	var sample: Dictionary = observer.call("_snapshot", key, Time.get_ticks_msec(), false)
	var failures: Array[String] = []
	for field: String in ["raise_actor", "rig", "key_prop", "glow", "audio"]:
		if sample.get(field, {}).get("present") != false: failures.append("freed local " + field)
	if sample.get("bone_pose_rotations") != {} or not sample.get("transition") is Dictionary:
		failures.append("snapshot incomplete after freed local references")
	var remotes: Array = sample.get("remote_raises", [])
	if remotes.size() != 1: failures.append("actual detached remote presenter not observed")
	else:
		for field: String in ["actor", "rig", "prop", "glow", "audio"]:
			if remotes[0].get(field, {}).get("present") != false: failures.append("freed remote " + field)
	key.free()
	observer.free()
	print("F18_PRESENTATION_LIFETIME ", JSON.stringify({"failures": failures,
		"local_fields": 5, "remote_fields": 5, "transition_snapshot_present": sample.get("transition") is Dictionary,
		"fixture": "detached actual HomeKey presenters with explicitly freed visual nodes; no travel acceptance"}))
	quit(0 if failures.is_empty() else 1)
