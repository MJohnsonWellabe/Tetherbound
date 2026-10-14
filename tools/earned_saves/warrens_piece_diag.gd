extends SceneTree

## P0 warrens-refusal diagnostic (13 Oct): replay ONLY the Warrens piece from a
## saved handoff on the CURRENT commit, without the earned chain runner's
## same-commit provenance (this is a bisect/repro tool, not chain evidence).
## Copies <from>/save to <out>/save, loads slot 0 through the production title
## (Load -> Autosave), runs tests/helpers/meadows_earned_warrens_segment.gd and
## prints one WARRENS DIAG RESULT line.
##   godot --headless --path . --script tools/earned_saves/warrens_piece_diag.gd -- \
##     --from=<checkpoint dir holding save/> --out=<absent dir>
const SAVE := preload("res://scripts/save/save_game.gd")
const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const WARRENS := preload("res://tests/helpers/meadows_earned_warrens_segment.gd")

var failures: Array[String] = []
var game: Node


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var from_dir := ""
	var out_dir := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--from="): from_dir = ProjectSettings.globalize_path(arg.trim_prefix("--from=")).simplify_path()
		elif arg.begins_with("--out="): out_dir = ProjectSettings.globalize_path(arg.trim_prefix("--out=")).simplify_path()
		elif arg.begins_with("--release-route="): pass
	if from_dir.is_empty() or out_dir.is_empty() or DirAccess.dir_exists_absolute(out_dir) \
			or not CHECKPOINTS.copy_tree(from_dir.path_join("save"), out_dir.path_join("save")):
		_finish({"failures": ["usage: --from=<dir with save/> --out=<absent dir>"]})
		return
	game = root.get_node("Game")
	game.set("save_system", SAVE.new(out_dir.path_join("save") + "/"))
	var ok: bool = await _load()
	if not ok:
		_finish({"failures": failures})
		return
	var result: Dictionary = await WARRENS.new().run(self, current_scene, game)
	_finish(result)


## As tidewake_piece_runner.gd::_load_through_title.
func _load() -> bool:
	var title := (load("res://scenes/ui/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for _i in 10: await process_frame
	(title.get("_load_button") as Button).pressed.emit()
	await process_frame
	for node: Node in (title.get("_load_box") as Node).get_children():
		if node is Button and (node as Button).text.begins_with("Autosave") and not (node as Button).disabled:
			(node as Button).pressed.emit()
			break
	for _frame in 7200:
		await process_frame
		var scene := current_scene
		if scene != null and scene != title and is_instance_valid(scene) and scene.get_node_or_null("Player") != null \
				and str(game.get("pending_realm_entry")).is_empty() \
				and bool(game.call("_realm_scene_ready", scene, str(game.get("current_realm")))):
			for _i in 300: await physics_frame
			return true
	failures.append("the loaded save never reached a ready world scene")
	return false


func _finish(result: Dictionary) -> void:
	print("WARRENS DIAG RESULT " + JSON.stringify({"passed": bool(result.get("passed", false)),
		"failures": result.get("failures", failures)}).left(3000))
	quit(0 if bool(result.get("passed", false)) else 1)
