extends SceneTree

## F03#0 lure cue witness. The lure walk's frames face along the road, so a
## cue beside the road can sit just off-frame and prove nothing either way.
## This renders the signal fire from road samples at set distances, two views
## each: `road` (the road's own heading at that sample, the direction that
## keeps the cue most in front) and `glance` (turned toward the cue).
##
##   flock <render-lock> xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tests/capture_lure_cue_views.gd -- --cue=bram|doss|juno|vault --out=DIR [--distances=m,m]
##
## Camera: a third-person rig's height (EYE_M over the terrain), 60 degree
## vertical FOV. The clock is frozen in the morning. Writes PNGs to --out.
## Inert by default: a standalone SceneTree script, not a test_*.gd.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const SETTLE_FRAMES := 240
const DENSIFY_M := 8.0
const EYE_M := 2.6
const FOV_DEG := 60.0
const DISTANCES_M := [220.0, 160.0, 110.0, 70.0]
## `--distances=480,420` overrides (Juno's patrol camp is ~470 m off any road).
const CUES := {
	"bram": Vector2(184.0, 901.0),
	"doss": Vector2(-11.0, 4184.5),
	"juno": Vector2(-175.0, 5470.0),
	"vault": Vector2(-351.0, 2611.8),
}

var _world: Node3D
var _terrain_data: Object
var _lines: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cue_id := "bram"
	var out := "user://lure_cue_views"
	var distances: Array = DISTANCES_M.duplicate()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--cue="):
			cue_id = a.trim_prefix("--cue=")
		elif a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--distances="):
			distances = []
			for part: String in a.trim_prefix("--distances=").split(","):
				distances.append(float(part))
	DirAccess.make_dir_recursive_absolute(out)
	var cue: Vector2 = CUES[cue_id]
	_load_roads()
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	var look := get_first_node_in_group(&"day_cycle")
	if look != null:
		look.call("reset_to_morning")
		look.call("set_clock_frozen", true)
	var terrain: Node = null
	for n in _world.find_children("*", "Terrain3D", true, false):
		terrain = n
		break
	_terrain_data = terrain.get("data") if terrain != null else null
	var cam := Camera3D.new()
	cam.fov = FOV_DEG
	cam.far = 2000.0
	root.add_child(cam)
	cam.make_current()
	# Whatever HUD the scene raises would cover the frame; hide CanvasLayers.
	for layer in _world.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = false
	var cue_top := Vector3(cue.x, _height(cue.x, cue.y) + 12.0, cue.y)
	for d: float in distances:
		var s := _sample_at(cue, d)
		if s.is_empty():
			print("[cue-view] %s no road sample near %.0f m" % [cue_id, d])
			continue
		var at: Vector2 = s.at
		var eye := Vector3(at.x, _height(at.x, at.y) + EYE_M, at.y)
		var heading: Vector2 = s.heading
		var to_cue := (cue - at).normalized()
		if heading.dot(to_cue) < 0.0:
			heading = -heading
		var off_deg := rad_to_deg(heading.angle_to(to_cue))
		for view: String in ["road", "glance"]:
			var dir2: Vector2 = heading if view == "road" else to_cue
			var target := eye + Vector3(dir2.x, 0.0, dir2.y) * 50.0
			if view == "glance":
				target = cue_top
			cam.global_position = eye
			cam.look_at(target, Vector3.UP)
			for i in 30:
				await process_frame
			await RenderingServer.frame_post_draw
			var file := "%s/%s_%03dm_%s.png" % [out, cue_id, int(d), view]
			root.get_texture().get_image().save_png(file)
			print("[cue-view] %s d=%.0fm at=(%.1f,%.1f) cue_off_road_heading=%.0fdeg %s" % [
				cue_id, at.distance_to(cue), at.x, at.y, off_deg, file])
	quit(0)


func _height(x: float, z: float) -> float:
	return float(_terrain_data.call("get_height", Vector3(x, 0, z))) if _terrain_data != null else 0.0


func _load_roads() -> void:
	var terrain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN_PATH))
	var trail := terrain.get("trail", {}) as Dictionary
	for key: String in ["bands", "loops", "shortcuts"]:
		for entry: Variant in (trail.get(key, []) as Array):
			var pts: Array = (entry as Dictionary).get("points", [])
			if pts.size() >= 2:
				_lines.append(pts)


## The densified road sample whose distance to `cue` is nearest `d`, with the
## road's heading there.
func _sample_at(cue: Vector2, d: float) -> Dictionary:
	var best := {}
	var best_err := INF
	for pts: Array in _lines:
		for j in range(1, pts.size()):
			var a := Vector2(float(pts[j - 1][0]), float(pts[j - 1][1]))
			var b := Vector2(float(pts[j][0]), float(pts[j][1]))
			var steps := maxi(1, int(ceil(a.distance_to(b) / DENSIFY_M)))
			for s in steps + 1:
				var p := a.lerp(b, float(s) / float(steps))
				var err := absf(p.distance_to(cue) - d)
				if err < best_err:
					best_err = err
					best = {"at": p, "heading": (b - a).normalized()}
	return best
