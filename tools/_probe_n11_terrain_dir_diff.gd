extends SceneTree

## N11-TERRAIN-BAKE-0905. Compare EVERY Terrain3DRegion `.res` in two data
## directories by DECODED content (height_range, height_map, control_map,
## color_map pixels), the same comparison `_probe_ow5b_region_content_diff.gd`
## makes for one file, done for a whole bake in one Godot launch instead of
## 64 of them. Same reason as that probe: Terrain3D's on-disk serialization is
## not byte-reproducible run to run (the ZSTD frame differs), so `cmp` on the
## `.res` files says nothing about whether the terrain changed. The decoded
## maps are the thing a re-bake can actually change.
##
##   godot --headless --path . --script tools/_probe_n11_terrain_dir_diff.gd -- <res://dir_a> <res://dir_b>
##
## Prints one line per region and a summary. Exit 0 when every region present
## in either directory decodes identically; exit 1 when any region differs,
## is missing on one side, or fails to load. Reads only; writes nothing.


func _region_files(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for name in dir.get_files():
		if name.begins_with("terrain3d") and name.ends_with(".res"):
			out.append(name)
	out.sort()
	return out


func _diff_image(a: Image, b: Image) -> int:
	if a == null or b == null:
		return -1
	if a.get_size() != b.get_size():
		return -1
	var diffs := 0
	for y in a.get_height():
		for x in a.get_width():
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				diffs += 1
	return diffs


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("usage: -- <res://dir_a> <res://dir_b>")
		quit(1)
		return
	var dir_a: String = args[0]
	var dir_b: String = args[1]
	var names := {}
	for n in _region_files(dir_a):
		names[n] = true
	for n in _region_files(dir_b):
		names[n] = true
	var sorted := names.keys()
	sorted.sort()
	print("comparing %d region file(s): %s vs %s" % [sorted.size(), dir_a, dir_b])

	var identical := 0
	var differing := 0
	var missing := 0
	for name in sorted:
		var path_a := "%s/%s" % [dir_a, name]
		var path_b := "%s/%s" % [dir_b, name]
		if not FileAccess.file_exists(path_a) or not FileAccess.file_exists(path_b):
			print("  %s: MISSING on one side (a=%s b=%s)" % [name, FileAccess.file_exists(path_a), FileAccess.file_exists(path_b)])
			missing += 1
			continue
		var a: Resource = ResourceLoader.load(path_a, "", ResourceLoader.CACHE_MODE_IGNORE)
		var b: Resource = ResourceLoader.load(path_b, "", ResourceLoader.CACHE_MODE_IGNORE)
		if a == null or b == null:
			print("  %s: FAILED TO LOAD (a=%s b=%s)" % [name, a, b])
			missing += 1
			continue
		var range_same: bool = a.get("height_range") == b.get("height_range")
		var h := _diff_image(a.get("height_map"), b.get("height_map"))
		var c := _diff_image(a.get("control_map"), b.get("control_map"))
		var col := _diff_image(a.get("color_map"), b.get("color_map"))
		if range_same and h == 0 and c == 0 and col == 0:
			identical += 1
			print("  %s: identical (height_range %s)" % [name, a.get("height_range")])
		else:
			differing += 1
			print("  %s: DIFFERS -- height_range %s vs %s, height_map %d px, control_map %d px, color_map %d px (-1 = size/null mismatch)" % [
				name, a.get("height_range"), b.get("height_range"), h, c, col])

	print("summary: %d identical, %d differing, %d missing/unloadable of %d" % [identical, differing, missing, sorted.size()])
	quit(0 if (differing == 0 and missing == 0 and sorted.size() > 0) else 1)
