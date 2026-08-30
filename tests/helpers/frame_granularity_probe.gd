extends SceneTree

## How long a process frame and a physics frame actually take, in the real
## production world, on THIS machine.
##
## Written for T2-FLAKE. `gate_a_opening_drive.gd`'s aim loop is a control loop:
## it reads an angular error, deflects a stick, and waits one frame for the
## camera to turn. `camera_rig.gd::_apply_look()` integrates that deflection
## against `delta` in `_process`, so the turn the loop gets per sample is
## proportional to the REAL SECONDS the sample took -- and the loop's step size
## was tuned against a 16.7ms one. This prints the number that assumption stands
## or falls on, so the next investigation does not have to infer it from a
## failure message.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"


func _init() -> void:
	_run()


func _run() -> void:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for _i in 300:
		await physics_frame

	var t0 := Time.get_ticks_usec()
	for _i in 120:
		await physics_frame
	var physics_ms := (Time.get_ticks_usec() - t0) / 1000.0 / 120.0

	t0 = Time.get_ticks_usec()
	for _i in 120:
		await process_frame
	var process_ms := (Time.get_ticks_usec() - t0) / 1000.0 / 120.0

	print("FRAME GRANULARITY: physics_frame %.1f ms, process_frame %.1f ms" % [
		physics_ms, process_ms])
	print("FRAME GRANULARITY: an aim sample tuned for 16.7 ms is %.1fx off on physics, %.1fx on process" % [
		physics_ms / 16.7, process_ms / 16.7])
	quit(0)
