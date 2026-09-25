extends SceneTree
## WO-F09-04: compare two Stormwood terrain data dirs channel by channel
## (decoded height/control/colour images and height_range per region, plus one
## sha256 over every region's height bytes), independent of how the resource
## files happen to be compressed.
##
##   godot --headless --path . --script tools/probe_stormwood_terrain_channels.gd -- --a=<dir> --b=<dir>
func _sha(bytes: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()
func _init() -> void:
	var a := ""
	var b := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--a="): a = arg.substr(4)
		if arg.begins_with("--b="): b = arg.substr(4)
	var files := DirAccess.get_files_at(a)
	var n := 0
	var height_diff := 0
	var color_diff := 0
	var range_diff := 0
	var ctrl_diff := 0
	var painted_a := 0
	var painted_b := 0
	var other_b := {}
	var ha := HashingContext.new(); ha.start(HashingContext.HASH_SHA256)
	var hb := HashingContext.new(); hb.start(HashingContext.HASH_SHA256)
	files.sort()
	for f in files:
		if not f.ends_with(".res"): continue
		n += 1
		var ra: Resource = ResourceLoader.load(a + "/" + f, "", ResourceLoader.CACHE_MODE_IGNORE)
		var rb: Resource = ResourceLoader.load(b + "/" + f, "", ResourceLoader.CACHE_MODE_IGNORE)
		var hda: PackedByteArray = (ra.get("height_map") as Image).get_data()
		var hdb: PackedByteArray = (rb.get("height_map") as Image).get_data()
		ha.update(hda); hb.update(hdb)
		if hda != hdb: height_diff += 1
		if (ra.get("color_map") as Image).get_data() != (rb.get("color_map") as Image).get_data(): color_diff += 1
		if ra.get("height_range") != rb.get("height_range"): range_diff += 1
		var ca: PackedByteArray = (ra.get("control_map") as Image).get_data()
		var cb: PackedByteArray = (rb.get("control_map") as Image).get_data()
		if ca != cb: ctrl_diff += 1
		for i in range(0, cb.size(), 4):
			var va := ca.decode_u32(i)
			var vb := cb.decode_u32(i)
			if va != 1: painted_a += 1
			if vb != 1:
				painted_b += 1
				other_b["%x" % vb] = other_b.get("%x" % vb, 0) + 1
	print("COMPARE regions=%d height_map_differs=%d color_map_differs=%d height_range_differs=%d control_differs=%d" % [n, height_diff, color_diff, range_diff, ctrl_diff])
	print("COMPARE height sha256 over all regions a=%s" % ha.finish().hex_encode())
	print("COMPARE height sha256 over all regions b=%s" % hb.finish().hex_encode())
	print("COMPARE non-default control texels a=%d b=%d values_b=%s" % [painted_a, painted_b, str(other_b)])
	quit(0)
