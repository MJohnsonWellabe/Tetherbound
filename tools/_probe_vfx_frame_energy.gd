extends SceneTree

## W09-VFX (CL-A2). The number behind the picture: how many pixels of a
## captured frame are "bright warm" (the impact-energy measure the blind
## critic first used against `combat/05-quick-attack-lands` -- 10 pixels --
## and `palworld-01` -- 24,623) and how many are near-white, per frame, so two
## rounds of the same shot can be compared by count rather than by eye.
##
##   godot --headless --path . --script tools/_probe_vfx_frame_energy.gd -- --dir=res://shots/vfx
##
## Whole-frame counts, sampled every pixel. Headless is fine: this reads PNGs,
## it renders nothing.

func _init() -> void:
	var dir_path := "res://shots/vfx"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--dir="):
			dir_path = argument.substr("--dir=".length())
	var dir := DirAccess.open(dir_path)
	if dir == null:
		print("FAIL: cannot open %s" % dir_path)
		quit(1)
		return
	var files: Array[String] = []
	for file in dir.get_files():
		if file.ends_with("-clean.png") or file.ends_with("-hud.png"):
			files.append(file)
	files.sort()
	for file in files:
		var image := Image.load_from_file(ProjectSettings.globalize_path(dir_path.path_join(file)))
		if image == null:
			print("FAIL: %s did not load" % file)
			continue
		var counts := _count(image)
		print("[energy] %s: bright_warm=%d near_white=%d gold=%d" % [file, counts[0], counts[1], counts[2]])
	quit(0)


## bright_warm: R>200, G>160, B<190, R-B>35 (a lit orange/gold, the impact
## colour). near_white: all channels > 200 (a flash core or a white puff).
## gold: R>220, G>180, B<150 (the level-up / catch gold specifically).
func _count(image: Image) -> Array:
	var warm := 0
	var white := 0
	var gold := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			var r := c.r8
			var g := c.g8
			var b := c.b8
			if r > 200 and g > 160 and b < 190 and r - b > 35:
				warm += 1
			if r > 200 and g > 200 and b > 200:
				white += 1
			if r > 220 and g > 180 and b < 150:
				gold += 1
	return [warm, white, gold]
