extends SceneTree

## Compare two Terrain3DRegion `.res` files by DECODED content
## (height_map/control_map/color_map pixels, height_range), not by raw file
## bytes. `tools/verify_incremental_bake_identity.sh` uses this.
##
## Why not `cmp`: the FIRST version of that test compared raw bytes and
## failed -- 3297 of 331558 bytes differing, starting right where the
## region's compressed image payload begins (a ZSTD frame). That looked like
## evidence the per-region bake was neighbour-dependent. It was not: baking
## the exact same single region TWICE, in two completely separate
## invocations with no other region ever involved, produced two files that
## differ in BOTH content bytes AND total size (331558 vs 331540), while this
## script's own pixel-by-pixel comparison of the same two files reports ZERO
## differing pixels in all three maps and an identical `height_range`.
## Terrain3D's on-disk serialization (compression, most likely -- the
## differing region always starts at the ZSTD magic number `28 B5 2F FD`) is
## simply not byte-reproducible run to run; the DECODED data is. So the
## question this bake's parallelism claim actually has to answer --
## "does baking a region alone produce the same terrain as baking it as part
## of a larger run" -- has to be asked of the decoded maps, not the file.
##
##   godot --headless --path . --script tools/_probe_ow5b_region_content_diff.gd -- <res://path/a.res> <res://path/b.res>
##
## Exit 0 and prints PASS if height_range and all three maps are pixel-for-
## pixel identical. Exit 1 and prints FAIL with the first mismatch otherwise.

func _diff_image(name: String, a: Image, b: Image) -> int:
	if a == null or b == null:
		print("  %s: one is null (a=%s b=%s)" % [name, a, b])
		return 1
	if a.get_size() != b.get_size():
		print("  %s: SIZE DIFFERS %s vs %s" % [name, a.get_size(), b.get_size()])
		return 1
	var w := a.get_width()
	var h := a.get_height()
	var diffs := 0
	var first := ""
	for y in h:
		for x in w:
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if ca != cb:
				if diffs == 0:
					first = "(%d,%d) a=%s b=%s" % [x, y, ca, cb]
				diffs += 1
	if diffs == 0:
		print("  %s: identical (%d pixels)" % [name, w * h])
		return 0
	print("  %s: %d / %d pixels differ, first at %s" % [name, diffs, w * h, first])
	return 1


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("usage: -- <res://a.res> <res://b.res>")
		quit(1)
		return
	var a: Resource = load(args[0])
	var b: Resource = load(args[1])
	if a == null or b == null:
		push_error("failed to load: a(%s)=%s b(%s)=%s" % [args[0], a, args[1], b])
		quit(1)
		return

	print("comparing decoded content: %s vs %s" % [args[0], args[1]])
	var fail := 0
	var range_a: Vector2 = a.get("height_range")
	var range_b: Vector2 = b.get("height_range")
	if range_a != range_b:
		print("  height_range DIFFERS: %s vs %s" % [range_a, range_b])
		fail += 1
	else:
		print("  height_range: identical %s" % range_a)
	fail += _diff_image("height_map", a.get("height_map"), b.get("height_map"))
	fail += _diff_image("control_map", a.get("control_map"), b.get("control_map"))
	fail += _diff_image("color_map", a.get("color_map"), b.get("color_map"))

	if fail == 0:
		print("PASS: decoded content identical")
		quit(0)
	else:
		print("FAIL: %d field(s)/map(s) differ" % fail)
		quit(1)
