extends "res://tests/test_case.gd"

## BUILD-SIZE. Godot normally converts an image to VRAM compression when the
## editor first discovers that it is used by a 3D scene. Tetherbound's art
## installer and CI are headless, so that editor-only detection left hundreds
## of runtime textures Lossless and made the Windows pack unnecessarily large.
##
## UI plates stay Lossless for sharp text and icons. Generator crops under a
## `reference/` folder are not runtime art and must be hidden by `.gdignore`;
## unsuffixed extracted generator inputs are excluded too.


func _collect_files(directory: String, suffix: String, output: Array[String]) -> void:
	var access := DirAccess.open(directory)
	assert_true(access != null, "cannot inspect %s" % directory)
	if access == null:
		return
	access.list_dir_begin()
	var name := access.get_next()
	while name != "":
		if name != "." and name != "..":
			var path := directory.path_join(name)
			if access.current_is_dir():
				_collect_files(path, suffix, output)
			elif name.ends_with(suffix):
				output.append(path.replace("\\", "/"))
		name = access.get_next()
	access.list_dir_end()


func _collect_reference_directories(directory: String, output: Array[String]) -> void:
	var access := DirAccess.open(directory)
	assert_true(access != null, "cannot inspect %s" % directory)
	if access == null:
		return
	access.list_dir_begin()
	var name := access.get_next()
	while name != "":
		if name != "." and name != ".." and access.current_is_dir():
			var path := directory.path_join(name)
			if name == "reference":
				output.append(path)
			else:
				_collect_reference_directories(path, output)
		name = access.get_next()
	access.list_dir_end()


func _is_generator_input_sidecar(path: String) -> bool:
	var name := path.get_file()
	return name.ends_with("_extracted_base_color.png.import") \
		or name.ends_with("_extracted_emissive.png.import")


func test_every_runtime_3d_texture_uses_vram_compression() -> void:
	var imports: Array[String] = []
	_collect_files(ProjectSettings.globalize_path("res://assets"), ".import", imports)
	var runtime_count := 0
	var offenders: Array[String] = []
	for absolute in imports:
		var relative := absolute.trim_prefix(ProjectSettings.globalize_path("res://").replace("\\", "/"))
		if relative.begins_with("assets/ui/") or relative.contains("/reference/") \
				or _is_generator_input_sidecar(relative):
			continue
		var text := FileAccess.get_file_as_string(absolute)
		if not text.contains('importer="texture"'):
			continue
		runtime_count += 1
		var has_vram_path := text.contains("path.s3tc=") or text.contains("path.bptc=")
		if not text.contains("compress/mode=2") \
				or not text.contains('"vram_texture": true') \
				or not text.contains('"imported_formats": ["s3tc_bptc"]') \
				or not has_vram_path \
				or not text.contains("detect_3d/compress_to=0"):
			offenders.append(relative)

	assert_true(runtime_count >= 350,
		"found only %d runtime 3D texture imports; the inventory walk is not proving the asset tree" % runtime_count)
	assert_true(offenders.is_empty(),
		"runtime 3D textures must be fully reimported with VRAM Compressed (mode 2); run "
		+ "tools/art_pipeline/texture_import_policy.py --apply:\n  "
		+ "\n  ".join(offenders))


func test_every_generator_reference_directory_is_ignored() -> void:
	var references: Array[String] = []
	_collect_reference_directories(ProjectSettings.globalize_path("res://assets/creatures"), references)
	_collect_reference_directories(ProjectSettings.globalize_path("res://assets/characters"), references)
	var offenders: Array[String] = []
	for directory in references:
		if not FileAccess.file_exists(directory.path_join(".gdignore")):
			offenders.append(directory)

	assert_true(references.size() >= 100,
		"found only %d reference directories; the inventory walk is not proving the asset tree" % references.size())
	assert_true(offenders.is_empty(),
		"generator reference art would be imported and packed without .gdignore:\n  "
		+ "\n  ".join(offenders))
