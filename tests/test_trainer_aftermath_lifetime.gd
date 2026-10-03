extends "res://tests/test_case.gd"

const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")

class Panel extends Node:
	signal line_presented(conversation_id: String, is_last: bool)
	signal finished(conversation_id: String)

## Disclosed signal emitter and detached director: the production callbacks,
## initialized SceneTree timers, node deletion and handover tween are actual.
## This does not claim a played victory, camera or durable reward.
func run_initialized_lifetime_case(tree: SceneTree) -> Dictionary:
	var director := DIRECTOR.new()
	var panel := Panel.new()
	var player := Node3D.new()
	tree.root.add_child(panel)
	tree.root.add_child(player)
	var shown := Node3D.new()
	tree.root.add_child(shown)
	director._bind_victory_aftermath(panel, shown, player, 0.01)
	panel.line_presented.emit("victory", false)
	assert_false(shown.has_meta(&"handed"), "earlier dialogue lines do not hand over tokens")
	panel.line_presented.emit("victory", true)
	await tree.create_timer(0.05).timeout
	assert_true(shown.has_meta(&"handed"), "actual last-line timer starts the production handover")
	panel.finished.emit("victory")
	assert_eq(panel.get_signal_connection_list("line_presented").size(), 0)
	shown.free()
	for moment: String in ["before_last", "after_schedule", "player_deleted", "director_deleted"]:
		shown = Node3D.new()
		tree.root.add_child(shown)
		director._bind_victory_aftermath(panel, shown, player, 0.01)
		if moment == "before_last":
			shown.free()
			for _frame in 43: panel.line_presented.emit("victory", true)
		elif moment == "after_schedule":
			panel.line_presented.emit("victory", true)
			shown.free()
			await tree.create_timer(0.05).timeout
		elif moment == "player_deleted":
			player.free()
			panel.line_presented.emit("victory", true)
			await tree.create_timer(0.05).timeout
			assert_true(shown.has_meta(&"handed"), "token cleanup tolerates a removed player")
			shown.free()
			player = null
		else:
			director.free()
			panel.line_presented.emit("victory", true)
			assert_false(shown.has_meta(&"handed"))
			shown.free()
		panel.finished.emit("victory")
		assert_eq(panel.get_signal_connection_list("line_presented").size(), 0, moment)
		assert_eq(panel.get_signal_connection_list("finished").size(), 0, moment)
	panel.free()
	await tree.process_frame
	return {"assertions": assertion_count, "failures": failures.duplicate(), "completed": true}

func test_native_tokens_player_and_director_can_expire_during_victory_dialogue() -> void:
	var suffix := "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var path := "user://aftermath-lifetime-" + suffix + ".gd"
	var log_path := ProjectSettings.globalize_path("user://aftermath-lifetime-" + suffix + ".log")
	var runner := FileAccess.open(path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null: return
	runner.store_string('''extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var test: RefCounted = load("res://tests/test_trainer_aftermath_lifetime.gd").new()
	var result: Dictionary = await test.call("run_initialized_lifetime_case", self)
	test = null
	await process_frame
	print("TRAINER_AFTERMATH_LIFETIME_RESULT=" + JSON.stringify(result))
	quit(0 if result.completed == true and result.assertions == 13 and result.failures.is_empty() else 1)
''')
	runner.close()
	var absolute := ProjectSettings.globalize_path(path)
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_true(FileAccess.file_exists(log_path))
	if FileAccess.file_exists(log_path): combined += "\n" + FileAccess.get_file_as_string(log_path)
	var result: Dictionary = {}
	var results := 0
	for line: String in "\n".join(output).split("\n"):
		if not line.begins_with("TRAINER_AFTERMATH_LIFETIME_RESULT="): continue
		results += 1
		var parsed: Variant = JSON.parse_string(line.trim_prefix("TRAINER_AFTERMATH_LIFETIME_RESULT="))
		if parsed is Dictionary: result = parsed
	assert_eq(results, 1, combined)
	assert_eq(result.get("assertions", 0), 13)
	assert_true(result.get("completed") == true)
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_false(combined.contains("ERROR:") or combined.contains("SCRIPT ERROR"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use")
		or combined.contains("RID allocations") or combined.contains("RIDs of type"), combined)
	assert_eq(code, 0, combined)
