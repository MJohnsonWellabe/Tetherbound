extends SceneTree
## Realm-load profile: where the Meadows cold terrain-data cost goes.
## Part 1: ResourceLoader.load of each region file. Part 2: a bare Terrain3D
## given the same data_directory (what playground_world does).
const DIR := "res://data/terrain/playground"
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var files := DirAccess.get_files_at(DIR)
	var t0 := Time.get_ticks_msec()
	var n := 0
	if OS.get_cmdline_user_args().has("--loader"):
		for f in files:
			if f.ends_with(".res"):
				var r := ResourceLoader.load(DIR.path_join(f), "", ResourceLoader.CACHE_MODE_IGNORE)
				n += 1 if r != null else 0
		print("TERRAIN_PROF loader regions=%d ms=%d" % [n, Time.get_ticks_msec() - t0])
	else:
		var terrain: Node3D = ClassDB.instantiate("Terrain3D")
		root.add_child(terrain)
		await process_frame
		var t1 := Time.get_ticks_msec()
		terrain.set("data_directory", DIR)
		print("TERRAIN_PROF terrain3d data_directory ms=%d" % (Time.get_ticks_msec() - t1))
	quit(0)
