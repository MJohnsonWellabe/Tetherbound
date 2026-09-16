extends "res://tools/gate_f/operator_harness.gd"

## Exercises the real scheduler, PNG writer, barrier and inventory using a
## generated fixture image and controlled clock; no claim of gameplay evidence.
class FixtureProbe extends RefCounted:
	var fighting := true
	func clock_weather() -> Dictionary:
		return {"hour": 12.0, "weather": "fixture"}
	func input_state() -> Dictionary:
		return {"combat_running": fighting}
	func encounter_director() -> Node:
		return null
	func input_context() -> String:
		return "combat" if fighting else "exploration"
	func player() -> Node3D:
		return null

var fixture_time := 0.0
var fixture_empty := false
var fixture_dark := false
var failures: Array[String] = []


func _run() -> void:
	_probe = FixtureProbe.new()
	_out_dir = ProjectSettings.globalize_path("user://gate-f-prescribed-fixture-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_out_dir.path_join("shots"))
	_segment_id = "fixture"
	var args := {"id": "S04-SEQ-final", "hz": 1.0, "seconds": 40.0,
		"background": true, "class": "14", "hud": "on", "intended_proof": "fixture only"}
	_planned_captures = _plan_captures([{"id": "fixture-step", "action": "capture_seq", "args": args}])
	_check(_start_capture_sequence(args, "fixture-step").begins_with("scheduled"), "start schedules")
	RenderingServer.frame_post_draw.disconnect(_background_capture_tick)
	_check(_manifest.is_empty(), "starting does not synchronously capture or wait")
	for i in 40:
		await process_frame
		fixture_time = float(i)
		(_probe as FixtureProbe).fighting = i < 12
		_background_capture_tick()
		_background_capture_tick()
		_check(_manifest.size() == i + 1, "one ID per distinct framebuffer")
	_check(_frames.is_empty(), "generic recorder never pays named debt")
	_write_inventory()
	var pending := _read_json(_out_dir.path_join("INVENTORY.json"))
	_check(not bool(pending.complete), "forty frames without full window/barrier stay incomplete")
	_check(bool(_evidence_missing), "unverified window marks evidence missing")
	fixture_time = 40.0
	var result := await _step_capture_seq_complete({"id": "S04-SEQ-final"})
	_check(not result.begins_with("FAIL"), "completion barrier passes full window")
	_check(result.contains("combat=12, aftermath=28"), "barrier reports actual contexts")
	_write_inventory()
	var inventory := _read_json(_out_dir.path_join("INVENTORY.json"))
	_check(bool(inventory.complete), "verified complete window pays inventory")
	_check(int(inventory.captures.present) == 40, "all forty PNGs exist on disk")
	_check(str(_manifest[0].hud) == "on" and str(_manifest[0].intended_proof) == "fixture only", "authored metadata preserved")
	_check(bool(_manifest[0].combat_running) and not bool(_manifest[39].combat_running), "shot rows retain context")
	_check(float(_manifest[39].sequence.elapsed) == 39.0, "actual sample time retained")
	fixture_empty = true
	_check(_write_prescribed_capture({"id": "empty"}, "fixture").begins_with("FAIL"), "empty image fails writer")
	fixture_empty = false
	fixture_dark = true
	_check(_write_prescribed_capture({"id": "dark"}, "fixture").begins_with("FAIL"), "degenerate image fails writer")
	_check(str(_manifest[-1].degenerate) != "", "degeneracy diagnostic retained")
	_check(_start_capture_sequence(args, "duplicate").begins_with("HARNESS-ERROR"), "cannot overwrite named sequence")
	print("prescribed capture fixture output: ", _out_dir)
	for failure in failures:
		push_error(failure)
	print("PASS prescribed window scheduler/writer/barrier/inventory" if failures.is_empty() else "FAIL prescribed window fixture")
	quit(0 if failures.is_empty() else 1)


func _capture_available() -> bool:
	return true


func _play_t() -> float:
	return fixture_time


func _prescribed_capture_image() -> Image:
	if fixture_empty:
		return Image.new()
	var picture := Image.create(32, 32, false, Image.FORMAT_RGB8)
	picture.fill(Color.BLACK if fixture_dark else Color.CORNFLOWER_BLUE)
	return picture


func _uncommittable(_rows: Array) -> Array:
	return []


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
