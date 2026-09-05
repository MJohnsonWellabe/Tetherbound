extends SceneTree

## N06-MAP-UI — the HUD minimap widget on its own, at a coverage that actually
## shows fog and landmark markers.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_capture_minimap_isolated_0905.gd -- --out=<dir>
##
## Rendered at the project's own 1920x1080 authoring canvas so the widget lands
## at its real 240px size in real pixels — `project.godot`'s `canvas_items`
## stretch would otherwise scale a Control sized in canvas units down to a
## third of itself at a 640-wide window, and a silhouette judged at a third
## size is not the silhouette the player sees.
##
## WHY THIS EXISTS, rather than another stand in `_capture_map_ui_0905.gd`.
## That tool's `hud_minimap` stand puts the player in the village at a 90 m
## span, where the starting reveal has already lifted every cell in the widget
## and no landmark marker falls inside it — so the widget renders identically
## before and after this lane's change, and proves nothing about either. A
## world boot costs ~45 minutes under software GL and the widget needs none of
## it: `minimap.gd::configure()` takes a `MapState` and a `Texture2D` directly.
## This stands the real widget up against a real `MapState` in seconds.
##
## HONEST ABOUT THE GROUND. The terrain here is a synthesised meadow-green
## gradient, not `map_baker.gd`'s bake — the baker needs a live world. It is
## the right stand-in for what is being judged (a fog value against ground, and
## a marker silhouette against ground) and the wrong one for judging the bake
## itself, which is not this lane's.

const MAP_STATE := preload("res://autoload/map_state.gd")
const MINIMAP := preload("res://scripts/ui/minimap.gd")
const LANDMARKS_PATH := "res://data/config/map_landmarks.json"

const WIDGET := 240.0
const SPAN_M := 90.0

var _out_dir := "res://shots/_diag"


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	var file := FileAccess.open(LANDMARKS_PATH, FileAccess.READ)
	if file == null:
		push_error("could not read %s" % LANDMARKS_PATH)
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("map_landmarks.json did not parse as a dictionary")
		quit(1)
		return

	var root_panel := ColorRect.new()
	root_panel.color = Color(0.10, 0.12, 0.14)
	root_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(root_panel)

	# Two stands, because the widget has two things to show and no single
	# player position shows both. `fog` stands at the far edge of the starting
	# reveal, where half the widget is ground the player has walked and half is
	# not — nothing extra is revealed, this is a real fresh save's own fog.
	# `markers` stands in the village, which is where the landmark markers are.
	for stand_name in ["fog", "markers"]:
		var stand := Vector3(0.0, 0.0, 120.0) if stand_name == "fog" else Vector3(0.0, 0.0, -20.0)

		var map_state: RefCounted = MAP_STATE.new()
		map_state.call("configure", parsed as Dictionary)
		# `mark_visited()` is what a walking player calls; it is also what
		# auto-discovers a landmark inside its own `discover_radius`. The fog
		# seed alone does NOT discover landmarks, so a stand that never called
		# it would draw no markers — which is a property of `MapState`, not of
		# this widget, and is why the marker stand walks the last step in. The
		# fog stand must NOT: `mark_visited` reveals a 45 m circle around the
		# player and would lift the very fog that stand exists to show.
		if stand_name == "markers":
			map_state.call("mark_visited", stand)

		var minimap: Control = MINIMAP.new()
		minimap.position = Vector2(120.0, 120.0)
		minimap.size = Vector2(WIDGET, WIDGET)
		minimap.custom_minimum_size = Vector2(WIDGET, WIDGET)
		root_panel.add_child(minimap)
		minimap.call("configure", map_state, _ground_texture(), SPAN_M)
		minimap.call("update_view", stand, 0.0, null)

		var fogged := 0
		var lifted := 0
		for iz in range(-12, 13):
			for ix in range(-12, 13):
				if bool(map_state.call("is_discovered", stand + Vector3(ix * 4.0, 0.0, iz * 4.0))):
					lifted += 1
				else:
					fogged += 1

		var visible_landmarks := 0
		for entry: Dictionary in (map_state.call("landmarks") as Array):
			if bool(entry.get("discovered", false)) or bool(entry.get("silhouette", false)):
				var pos: Vector2 = entry.get("position", Vector2.ZERO)
				if pos.distance_to(Vector2(stand.x, stand.z)) <= SPAN_M * 0.5:
					visible_landmarks += 1
		print("minimap_%s: inside the widget %d cell(s) revealed / %d fogged, %d landmark(s)"
			% [stand_name, lifted, fogged, visible_landmarks])

		for i in 12:
			await process_frame
		minimap.queue_redraw()
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			push_error("viewport returned no image")
			quit(1)
			return
		var path := "%s/minimap_%s.png" % [_out_dir, stand_name]
		var error := image.save_png(path)
		if error != OK:
			push_error("save_png failed (%d)" % error)
			quit(1)
			return
		print("  minimap_%s -> %s" % [stand_name, path])
		minimap.queue_free()
		await process_frame

	quit(0)



## A meadow-green ground with a gentle height ramp, standing in for
## `map_baker.gd`'s bake. Built from the SAME expression the baker uses for its
## meadow colour, so the fog-against-ground measurement this frame supports is
## against the real ground colour and not an invented one.
func _ground_texture() -> Texture2D:
	var meadow := UITokens.HP_GREEN.lerp(Color(0.5, 0.5, 0.5), 0.2)
	var pale_high := UITokens.GROUND_OCHRE.lerp(Color(0.85, 0.83, 0.78), 0.55)
	var size := 256
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var ramp := clampf((sin(x * 0.06) + cos(y * 0.05)) * 0.25 + 0.35, 0.0, 1.0)
			image.set_pixel(x, y, meadow.lerp(pale_high, ramp))
	return ImageTexture.create_from_image(image)
