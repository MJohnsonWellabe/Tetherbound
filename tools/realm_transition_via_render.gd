extends SceneTree

## Fixed render.yml entry for the original Linux Game/native realm harness.
## Original deadlines, subprocesses, expected errors and result checks remain
## in verify-realm-transition.py; this only retains receipts in the workspace.
func _init() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		printerr("realm_transition_via_render: this fixed harness accepts no user arguments")
		quit(2)
		return
	var project: String = ProjectSettings.globalize_path("res://")
	var output_parent: String = project.path_join(".tmp/realm-transition-via-render-%d" % OS.get_process_id())
	if DirAccess.dir_exists_absolute(output_parent) or FileAccess.file_exists(output_parent):
		printerr("realm_transition_via_render: fresh receipt directory required")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(output_parent) != OK:
		printerr("realm_transition_via_render: could not create receipt directory")
		quit(2)
		return
	OS.set_environment("RUNNER_TEMP", output_parent)
	var output: Array = []
	var code: int = OS.execute("python3", [project.path_join("tools/ci/verify-realm-transition.py")], output, true)
	for chunk: Variant in output: print(str(chunk))
	print("realm_transition_via_render: original harness exit %d" % code)
	quit(code)
