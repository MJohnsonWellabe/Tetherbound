extends SceneTree

## F22#3 evidence: rendered footage of five creatures of five combat roles
## fighting on the C2 flat fixture (production bodies, manager, wild AI and
## F22 pattern consumer, piloted by the shared F22 READER so the opponent's
## full pattern cycle plays out). Frames go to a code-blind judge who must name
## each creature's role from the footage alone. Evidence only; nothing saved.
##
##   xvfb-run -a -s "-screen 0 960x540x24" godot --path . --rendering-driver opengl3 \
##     --resolution 960x540 --fixed-fps 30 --script res://tests/capture_f22_roles.gd -- --out=<abs dir>
##
## Disclosed fixture: flat 100 m floor with a plain grass-coloured plane, one
## sun and a sky colour; an oblique camera that frames both fighters from the
## player's side. Labels in the output are opaque (creature_a..e); the mapping
## is written to a separate key file the judge never receives.
const PILOT := preload("res://tests/helpers/f22_pattern_pilot.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const RETAINED := ["bramblebun", "mudsnout", "pipwing", "trailpup"]
## opaque label -> [species, role override, trainer_owned]
const CASES := [
	["creature_a", "reedwing", "", false],
	["creature_b", "tuskroot", "", false],
	["creature_c", "meadowhart", "ACE", true],
	["creature_d", "mosshell", "", false],
	["creature_e", "brooktail", "", false],
]
const LEVEL := 24
const FRAME_EVERY_S := 0.4
const MAX_FRAMES := 36


class Recorder:
	extends "res://tests/helpers/f22_pattern_pilot.gd"
	var camera: Camera3D
	var out_dir := ""
	var label := ""
	var saved := 0
	var _next := 0.0
	var tree: SceneTree
	var _side := Vector3.ZERO

	func _act(policy: String) -> void:
		super._act(policy)
		if not is_instance_valid(_wild) or not is_instance_valid(_ally): return
		var mid := (_wild.global_position + _ally.global_position) * 0.5
		var gap := _wild.global_position.distance_to(_ally.global_position)
		# Side-on to the line between the fighters, so neither hides the other.
		var line := _wild.global_position - _ally.global_position
		line.y = 0.0
		var side := line.normalized().cross(Vector3.UP) if line.length() > 0.1 else Vector3.BACK
		if side.z < 0.0: side = -side
		_side = _side.lerp(side, 0.08).normalized() if _side != Vector3.ZERO else side
		camera.global_position = mid + _side * (9.0 + gap * 0.6) + Vector3.UP * (6.0 + gap * 0.3)
		camera.look_at(mid + Vector3.UP * 0.8, Vector3.UP)
		var now := float(_frames) / Engine.physics_ticks_per_second
		if now >= _next and saved < MAX_FRAMES:
			_next = now + FRAME_EVERY_S
			_save.call_deferred(now)

	func _save(now: float) -> void:
		await RenderingServer.frame_post_draw
		var image := tree.root.get_texture().get_image()
		image.save_png("%s/%s_%02d.png" % [out_dir, label, saved])
		saved += 1


var _out := ""
var _only: PackedStringArray = []


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="): _only = arg.trim_prefix("--only=").split(",", false)
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	var stage := Node3D.new()
	root.add_child(stage)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100.0, 100.0)
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color(0.36, 0.52, 0.27)
	plane.material = grass
	ground.mesh = plane
	stage.add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	sun.shadow_enabled = true
	stage.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.76, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.78, 0.8)
	stage.add_child(env)
	var camera := Camera3D.new()
	camera.fov = 55.0
	stage.add_child(camera)
	camera.make_current()
	var key := {}
	for spec: Array in CASES:
		if not _only.is_empty() and not _only.has(str(spec[0])): continue
		var party: Array[RefCounted] = []
		for id: String in ["terrapup"] + RETAINED:
			var creature: RefCounted = SPECIES.spawn(id)
			creature.call("set_level", LEVEL + 4, PROGRESSION.config())
			party.append(creature)
		var foe: RefCounted = SPECIES.spawn(str(spec[1]))
		foe.call("set_level", LEVEL, PROGRESSION.config())
		var pilot := Recorder.new()
		pilot.camera = camera
		pilot.out_dir = _out
		pilot.label = str(spec[0])
		pilot.tree = self
		pilot.context = {"chapter": "water", "band": "f22_roles", "after_south_bridge": true}
		if not str(spec[2]).is_empty(): pilot.context["role"] = spec[2]
		var result: Dictionary = await pilot.fight(self, party, [foe], bool(spec[3]), hash("f22roles/" + str(spec[0])), "READER")
		key[spec[0]] = {"species": spec[1], "role_override": spec[2], "frames": pilot.saved, "won": result.get("won")}
		print("F22_ROLES captured ", spec[0], " frames=", pilot.saved)
	var file := FileAccess.open(_out + "/KEY_DO_NOT_SHOW_JUDGE%s.json" % ("" if _only.is_empty() else "_" + "_".join(_only)), FileAccess.WRITE)
	file.store_string(JSON.stringify(key, "\t"))
	file.close()
	quit(0)
