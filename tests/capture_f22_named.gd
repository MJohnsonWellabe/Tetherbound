extends "res://tests/smoke_f22_pattern_bands.gd"

## F22#4 C3 evidence: rendered footage of each named trainer fight on the C2
## flat fixture, built exactly as smoke_f22_pattern_bands --named builds it
## (same rosters, levels, party, authored F22 pattern row, production bodies,
## manager and wild AI), piloted by the COMBAT §7 switching reader so each
## send-out's pattern cycle plays out. Frames are saved at each tell (once the
## shape has been shown for the reader's 0.25 s), at the strike and just after
## it, plus one frame as each send-out enters. Labels are opaque (fight_a..);
## the mapping is in a key file the judge never receives. Evidence only.
##
##   xvfb-run -a -s "-screen 0 960x540x24" godot --path . --rendering-driver opengl3 \
##     --resolution 960x540 --fixed-fps 30 --script res://tests/capture_f22_named.gd -- \
##     --seeds=12 --named=<id,...> --out=<abs dir> [--starter=terrapup]
##
## Disclosed fixture: flat 100 m floor with a plain ground-coloured plane, one
## sun and a sky colour (no world, no storm clock, no Dynamo controller); an
## oblique camera that frames both fighters from the side. One seed per fight.
const TELLS_PER_SENDOUT := 3


class Recorder:
	extends "res://tests/helpers/f22_pattern_pilot.gd"
	var camera: Camera3D
	var out_dir := ""
	var label := ""
	var saved := 0
	var tree: SceneTree
	var _side := Vector3.ZERO
	var _was_telling := false
	var _tell_frame := -1
	var _tell_shot := false
	var _after_at := -1
	var _sendout_seen := -1
	var _tells_this_sendout := 0

	func _act(policy: String) -> void:
		super._act(policy)
		if not is_instance_valid(_wild) or not is_instance_valid(_ally): return
		var mid := (_wild.global_position + _ally.global_position) * 0.5
		var gap := _wild.global_position.distance_to(_ally.global_position)
		var line := _wild.global_position - _ally.global_position
		line.y = 0.0
		var side := line.normalized().cross(Vector3.UP) if line.length() > 0.1 else Vector3.BACK
		if side.z < 0.0: side = -side
		# Track the side quickly so neither fighter hides the other.
		_side = _side.lerp(side, 0.3).normalized() if _side != Vector3.ZERO else side
		# Frame both bodies and the attacker's whole shape: a ring centred on
		# a large attacker must stay on screen with its safe edge visible.
		var config: Dictionary = _wild.combat_config() if _wild.has_method("combat_config") else {}
		var ring := float(config.get("range", 0.0)) if str(config.get("telegraph_shape", "")) == "ring" else 0.0
		var span := maxf(gap + _ally.body_radius() + _wild.body_radius(), ring * 2.0)
		span = maxf(span, 4.0)
		camera.global_position = mid + _side * (4.0 + span * 1.1) + Vector3.UP * (4.0 + span * 0.7)
		camera.look_at(mid + Vector3.UP * 0.8, Vector3.UP)
		var sendout := int(_tally.get("f22_sendouts", 0))
		if sendout != _sendout_seen:
			_sendout_seen = sendout
			_tells_this_sendout = 0
			# A tell cut off by the previous send-out's faint is not a strike.
			_was_telling = false
			_after_at = -1
			_shot("s%d_enter" % sendout)
		var telling := bool(_manager.enemy_is_winding_up())
		if telling and not _was_telling:
			_tell_frame = _frames
			_tell_shot = false
			_tells_this_sendout += 1
		var capture := _tells_this_sendout <= TELLS_PER_SENDOUT
		if telling and capture and not _tell_shot and _frames - _tell_frame >= int(0.25 * Engine.physics_ticks_per_second):
			_tell_shot = true
			_shot("s%d_t%d_tell" % [sendout, _tells_this_sendout])
		if not telling and _was_telling and capture:
			# A tell that ended before the reader could see it for 0.25 s was cut
			# short (the attacker was staggered or fainted), not a strike.
			_shot("s%d_t%d_%s" % [sendout, _tells_this_sendout, "strike" if _tell_shot else "cut"])
			_after_at = _frames + int(0.4 * Engine.physics_ticks_per_second)
		if _after_at >= 0 and _frames >= _after_at:
			_after_at = -1
			_shot("s%d_t%d_after" % [sendout, _tells_this_sendout])
		_was_telling = telling

	func _shot(tag: String) -> void:
		_save.call_deferred("%s/%s_%03d_%s.png" % [out_dir, label, saved, tag])
		saved += 1

	## Only shot frames are drawn (software GL is ~1 fps at full rate).
	func _save(path: String) -> void:
		RenderingServer.render_loop_enabled = true
		await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png(path)
		RenderingServer.render_loop_enabled = false


var _out := ""
var _starter := "terrapup"


func _init() -> void:
	super()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		elif arg.begins_with("--starter="): _starter = arg.trim_prefix("--starter=")


func _run() -> void:
	print("F22_NAMED run ", _named)
	RenderingServer.render_loop_enabled = false
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
	var errors: Array[String] = []
	var patterns: Dictionary = MATH.config().get("patterns", {})
	var rosters := _trainer_rosters(patterns)
	var cases := _cases(errors)
	var key := {}
	var index := 0
	for id: String in _named:
		var label := "fight_" + char(97 + index)
		index += 1
		var found := {}
		for entry: Dictionary in cases:
			for pick: Dictionary in rosters.get(entry.id, []):
				if str(pick.id) == id: found = {"entry": entry, "team": pick.team}
		if found.is_empty():
			push_error("capture_f22_named: no roster for " + id)
			continue
		var entry: Dictionary = found.entry
		var party := _party(int(entry.level), _starter)
		var foes: Array = []
		for member: Dictionary in found.team:
			var built: RefCounted = TRAINERS.creature_for(member)
			if built != null: foes.append(built)
		var pilot := Recorder.new()
		pilot.camera = camera
		pilot.out_dir = _out
		pilot.label = label
		pilot.tree = self
		pilot.context = {"chapter": entry.chapter, "band": entry.id, "floor_trainer": false,
			"after_south_bridge": bool(entry.get("after_south_bridge", true))}
		if (patterns.get("named", {}) as Dictionary).has("named_" + id):
			pilot.context["pattern_id"] = "named_" + id
		var result: Dictionary = await pilot.fight(self, party, foes, true,
			hash("f22/%s/%s/%d" % [entry.id, _starter, 0]), "SWITCH_READER")
		key[label] = {"trainer": id, "band": entry.id, "starter": _starter, "frames": pilot.saved,
			"won": result.get("won"), "seconds": result.get("seconds"), "party_lost_frac": result.get("party_lost_frac")}
		print("F22_NAMED captured ", label, " ", id, " frames=", pilot.saved, " won=", result.get("won"))
	var file := FileAccess.open(_out + "/KEY_DO_NOT_SHOW_JUDGE.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(key, "\t"))
	file.close()
	quit(0)
