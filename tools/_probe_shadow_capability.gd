extends SceneTree

## N14-ROUTED-FOLLOWUPS item 1, step 0: is the missing shadow a real gap in the
## resource, or is it software GL in this container refusing to draw one?
##
## N09's round-2 blind judge ranked "nothing in the game casts a shadow" as the
## loudest defect anywhere it looked, and priced the fix as "turn on shadow
## casting for the directional light". But `world_look.gd::_apply_sun()` already
## sets `shadow_enabled = true`, `meadows_playground.tscn`'s own Sun node sets it
## too, and `project.godot` sets a shadow atlas size and a soft-shadow filter
## quality. So before changing anything, this stands ONE box on ONE ground plane
## under a light configured exactly as the game configures its sun, renders it
## through the same `--rendering-driver opengl3` path every capture tool uses,
## and MEASURES the ground either side of where the shadow must fall.
##
##   xvfb-run -a -s "-screen 0 900x600x24" \
##     godot --path . --rendering-driver opengl3 --resolution 900x600 \
##     --script tools/_probe_shadow_capability.gd [-- --out=res://shots/n14/shadowprobe]
##
## Bare scene, no world load: seconds, not the 20-50 minutes a world stand costs.
## Never `--headless` together with a rendering driver (it hangs).
##
## Each variant prints `shadowed_luma`, `lit_luma` and their ratio. A renderer
## that draws no shadow at all reports ratio ~= 1.00 for EVERY variant including
## the deliberately-exaggerated control; a renderer that draws shadows reports a
## clearly darker shadowed sample and the variants separate.

const DEFAULT_OUT_DIR := "res://shots/n14/shadowprobe"
const SETTLE_FRAMES := 10

## The camera looks down the shadow's own length so the cast falls across the
## middle of frame; the two sample boxes are fixed rectangles in that frame.
const EYE := Vector3(7.5, 4.0, 9.0)
const TARGET := Vector3(0.0, 0.5, 0.0)
const FOV := 55.0

## Sample windows in normalised frame coordinates (x, y, w, h). `SHADOW` sits on
## the ground where the box's cast lands; `LIT` sits on the same ground plane,
## the same distance from camera, well clear of the cast.
##
## These were re-derived once, and the reason is worth keeping: the first pair
## was placed off a render made with an UNAIMED camera (see the `look_at` note
## below), so both windows sat on empty lit ground and every variant reported
## ratio ~1.00 -- the probe would have concluded "this renderer draws no
## shadows" while the saved PNG showed a perfectly good shadow. The windows are
## checked against the saved frame, not trusted.
const SHADOW_WINDOW := Rect2(0.395, 0.525, 0.050, 0.035)
const LIT_WINDOW := Rect2(0.600, 0.525, 0.050, 0.035)

## Every variant is the same scene with one thing changed. `game` is what
## `world_look.gd::_apply_sun()` + `data/config/art.json` actually install today.
const VARIANTS := [
	{
		"name": "a-game-settings",
		"why": "exactly what world_look.gd installs today",
		"shadow_enabled": true, "normal_bias": 1.7, "bias": 0.06, "blur": 1.0,
		"max_distance": 420.0, "splits": 2, "opacity": 1.0,
	},
	{
		"name": "b-shadows-off",
		"why": "control: shadows explicitly off. Must read ratio 1.00",
		"shadow_enabled": false, "normal_bias": 1.7, "bias": 0.06, "blur": 1.0,
		"max_distance": 420.0, "splits": 2, "opacity": 1.0,
	},
	{
		"name": "c-godot-default-bias",
		"why": "game settings but Godot's own default normal_bias 1.0 / bias 0.03",
		"shadow_enabled": true, "normal_bias": 1.0, "bias": 0.03, "blur": 1.0,
		"max_distance": 420.0, "splits": 2, "opacity": 1.0,
	},
	{
		"name": "d-short-reach",
		"why": "game settings but max_distance 100 instead of 420 (denser texels)",
		"shadow_enabled": true, "normal_bias": 1.7, "bias": 0.06, "blur": 1.0,
		"max_distance": 100.0, "splits": 2, "opacity": 1.0,
	},
	{
		"name": "e-short-reach-low-bias",
		"why": "both of the above together -- the plausible real fix",
		"shadow_enabled": true, "normal_bias": 0.8, "bias": 0.03, "blur": 1.0,
		"max_distance": 100.0, "splits": 2, "opacity": 1.0,
	},
	{
		"name": "f-exaggerated-control",
		"why": "control: everything favourable. If THIS reads 1.00 the renderer draws no shadows at all",
		"shadow_enabled": true, "normal_bias": 0.0, "bias": 0.0, "blur": 0.0,
		"max_distance": 50.0, "splits": 0, "opacity": 1.0,
	},
	{
		"name": "g-game-environment",
		"why": "game sun AND art.json's real environment (ambient_energy 1.9, ACES, exposure 0.6)",
		"shadow_enabled": true, "normal_bias": 1.7, "bias": 0.06, "blur": 1.0,
		"max_distance": 420.0, "splits": 2, "opacity": 1.0, "game_env": true,
	},
	{
		"name": "h-game-environment-ambient-1_0",
		"why": "the same, with ambient_energy dropped 1.9 -> 1.0",
		"shadow_enabled": true, "normal_bias": 1.7, "bias": 0.06, "blur": 1.0,
		"max_distance": 420.0, "splits": 2, "opacity": 1.0,
		"game_env": true, "ambient_energy": 1.0,
	},
	{
		"name": "i-game-environment-ambient-0_6",
		"why": "the same, with ambient_energy dropped 1.9 -> 0.6",
		"shadow_enabled": true, "normal_bias": 1.7, "bias": 0.06, "blur": 1.0,
		"max_distance": 420.0, "splits": 2, "opacity": 1.0,
		"game_env": true, "ambient_energy": 0.6,
	},
]

## `data/config/art.json`'s own `environment` block, as `world_look.gd`
## installs it. The point of variants g-i: a shadow the renderer DRAWS can
## still be invisible if the scene's flat ambient fill is bright enough to
## repaint it, and this file asks for `ambient_energy` 1.9.
const GAME_AMBIENT_ENERGY := 1.9
const GAME_AMBIENT_COLOUR := Color(0.616, 0.702, 0.776)  # #9db3c6
const GAME_SKY_CONTRIBUTION := 0.1
const GAME_EXPOSURE := 0.6
const GAME_WHITE := 6.0

static var _out_dir: String = DEFAULT_OUT_DIR


func _init() -> void:
	_run()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	print("renderer: %s" % ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	print("adapter : %s" % RenderingServer.get_video_adapter_name())
	print("driver  : %s" % RenderingServer.get_video_adapter_api_version())

	var world := Node3D.new()
	world.name = "ShadowProbe"
	root.add_child(world)

	var env_holder := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.62, 0.78)
	# A LOW ambient deliberately: a shadow is only visible to the extent the
	# scene's fill does not wash it out, and the point here is whether the
	# renderer draws one at all, not how the game's own ambient reads.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.72)
	env.ambient_light_energy = 0.30
	env_holder.environment = env
	world.add_child(env_holder)

	# Ground: a plain unlit-ish pale surface, the "pale ground" the judge's own
	# 8x zoom was looking at when it found zero darkening under the boots.
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(60.0, 60.0)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.78, 0.76, 0.68)
	gmat.roughness = 1.0
	ground.material_override = gmat
	world.add_child(ground)

	# One box standing on the ground, roughly a trainer's bulk.
	var box := MeshInstance3D.new()
	box.name = "Box"
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(0.8, 1.8, 0.8)
	box.mesh = bmesh
	box.position = Vector3(0.0, 0.9, 0.0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.35, 0.30, 0.26)
	bmat.roughness = 0.9
	box.material_override = bmat
	box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	world.add_child(box)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(1.0, 0.945, 0.847)
	sun.light_energy = 1.1
	# The same two angles `art.json` asks for and `world_look.gd` installs.
	sun.rotation = Vector3(deg_to_rad(-44.0), deg_to_rad(140.0), 0.0)
	world.add_child(sun)

	var camera := Camera3D.new()
	camera.far = 500.0
	camera.fov = FOV
	world.add_child(camera)
	camera.make_current()

	# Aim AFTER the tree has ticked: `look_at` needs the node to be inside the
	# tree, and in a `SceneTree` script `_init` runs before that is true. The
	# first version of this probe aimed here and silently rendered six frames
	# from an unaimed camera -- every ratio came back ~1.00, which is exactly
	# the answer it was looking for. Caught by reading the ERROR lines.
	for i in SETTLE_FRAMES:
		await process_frame
	camera.global_position = EYE
	camera.look_at(TARGET, Vector3.UP)
	for i in 4:
		await process_frame

	print("")
	print("%-24s %10s %10s %8s  %s" % ["variant", "shadowed", "lit", "ratio", "why"])
	var rows: Array[Dictionary] = []
	for entry: Variant in VARIANTS:
		var v: Dictionary = entry
		sun.shadow_enabled = bool(v["shadow_enabled"])
		sun.shadow_normal_bias = float(v["normal_bias"])
		sun.shadow_bias = float(v["bias"])
		sun.shadow_blur = float(v["blur"])
		sun.shadow_opacity = float(v["opacity"])
		sun.directional_shadow_max_distance = float(v["max_distance"])
		sun.directional_shadow_mode = int(v["splits"]) as DirectionalLight3D.ShadowMode
		if bool(v.get("game_env", false)):
			env.ambient_light_color = GAME_AMBIENT_COLOUR
			env.ambient_light_energy = float(v.get("ambient_energy", GAME_AMBIENT_ENERGY))
			env.ambient_light_sky_contribution = GAME_SKY_CONTRIBUTION
			env.tonemap_mode = Environment.TONE_MAPPER_ACES
			env.tonemap_exposure = GAME_EXPOSURE
			env.tonemap_white = GAME_WHITE
		else:
			env.ambient_light_color = Color(0.55, 0.62, 0.72)
			env.ambient_light_energy = 0.30
			env.ambient_light_sky_contribution = 0.0
			env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
			env.tonemap_exposure = 1.0
			env.tonemap_white = 1.0
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image == null:
			print("FAIL %s: no image" % v["name"])
			continue
		image.save_png("%s/%s.png" % [_out_dir, v["name"]])
		var shadowed := _mean_luma(image, SHADOW_WINDOW)
		var lit := _mean_luma(image, LIT_WINDOW)
		var ratio := (shadowed / lit) if lit > 0.0 else 1.0
		rows.append({"name": v["name"], "shadowed": shadowed, "lit": lit, "ratio": ratio})
		print("%-24s %10.4f %10.4f %8.3f  %s" % [v["name"], shadowed, lit, ratio, v["why"]])

	print("")
	var control := 1.0
	for row in rows:
		if row["name"] == "f-exaggerated-control":
			control = float(row["ratio"])
	if control > 0.90:
		print("VERDICT: even the exaggerated control shows no darkening (ratio %.3f)." % control)
		print("         This renderer/driver path draws NO directional shadow at all;" )
		print("         the resource setting is not the thing to change.")
	else:
		print("VERDICT: this path DOES draw directional shadows (control ratio %.3f)." % control)
		print("         Compare a-game-settings against it to see what the game loses.")
	quit(0)


## Rec.709 luma, the same weighting `tools/frame_stats.py` uses, averaged over a
## normalised rectangle of the frame.
func _mean_luma(image: Image, window: Rect2) -> float:
	var w := image.get_width()
	var h := image.get_height()
	var x0 := int(window.position.x * w)
	var y0 := int(window.position.y * h)
	var x1 := mini(w, int((window.position.x + window.size.x) * w))
	var y1 := mini(h, int((window.position.y + window.size.y) * h))
	var total := 0.0
	var n := 0
	for y in range(y0, y1):
		for x in range(x0, x1):
			var c := image.get_pixel(x, y)
			total += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			n += 1
	return (total / float(n)) if n > 0 else 0.0
