extends "res://tests/test_case.gd"

## The rolling Windows download (release.yml) uploads one zip, and GitHub
## refuses a release asset of 2 GiB or more. With `all_resources` the Windows
## preset packed tests/ (1.1 GB of earned-save fixtures), ralph/ (lane reports
## and contact sheets) and archive/ into the .pck: 5.48 GB, zipped about 2.8 GB,
## so the 11 Nov Release runs failed at upload and the `latest` release lost its
## zip. The game never loads those folders (only a provenance string in
## character_appearance_variants.json names a ralph/ script), and KICKOFF.cmd
## runs from a fresh repo clone, not the .pck. The Linux Test preset that CI
## runs keeps its own filter.

const PRESETS := "res://export_presets.cfg"


func _windows_exclude() -> String:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(PRESETS), OK, "export_presets.cfg loads")
	for section in cfg.get_sections():
		if str(cfg.get_value(section, "name", "")) == "Windows Desktop":
			return str(cfg.get_value(section, "exclude_filter", ""))
	return ""


func test_windows_export_leaves_out_dev_folders() -> void:
	var filters := _windows_exclude().split(",", false)
	var trimmed: Array[String] = []
	for f in filters:
		trimmed.append(f.strip_edges())
	for needed in ["docs/*", "*.md", "tests/*", "ralph/*", "archive/*"]:
		assert_true(trimmed.has(needed), "Windows export excludes %s" % needed)


func test_runtime_code_does_not_load_excluded_folders() -> void:
	for dir in ["res://scripts", "res://scenes"]:
		_assert_no_refs(dir)


func _assert_no_refs(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	for sub in d.get_directories():
		_assert_no_refs(path.path_join(sub))
	for f in d.get_files():
		if not (f.ends_with(".gd") or f.ends_with(".tscn")):
			continue
		var text := FileAccess.get_file_as_string(path.path_join(f))
		for bad in ["res://tests/", "res://ralph/", "res://archive/"]:
			assert_false(text.contains(bad), "%s must not load %s (excluded from the Windows export)" % [path.path_join(f), bad])
