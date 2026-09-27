extends Node

## F04 #2/#3/#6 frame observer for the three Sigil captains and the Warden
## (ACCEPTANCE §6.1 F04; BOSSES §4.3 and §4.5). Added to the SceneTree root by
## `tests/smoke_meadows_f04_bosses_run.gd`, which runs the continuous Meadows
## smoke from an earned checkpoint: every fight is the production one, won by
## that smoke's own controller-input fighting. This node is PASSIVE: it never
## presses, moves, heals, writes a flag or touches a save.
##
## For each TARGET fight it saves production-camera frames (HUD as the player
## sees it) at:
##   - the NAMED member's tells (the creature that carries the fight's shape,
##     NAMED below): tell start, mid-tell, the strike and the recovery after it
##     (`<id>-m<i>-<species>-t<k>-<phase>.png`); plus one frame ENTRY_S after
##     that member is sent out (the reposition read, DIVER especially);
##   - the aftermath, AFTERMATH_S seconds after the fight resolves
##     (`<id>-after-<s>s.png`), i.e. after the level-up line has cleared.
## Each frame has a JSON sidecar: which bodies are in the camera frustum, their
## distances, and the visible HUD/toast text at that moment.
##
## `render_fights_only` (DISCLOSED harness speed-up for llvmpipe): the render
## loop is off except from a target fight's start until its last aftermath
## frame. `render_captures_only` goes further: it is on only for the few frames
## each capture draws. Physics, AI, input and saves do not depend on drawing.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
## Team index -> BOSSES shape, for the members that carry each fight's question.
const NAMED := {
	"captain_riverwatch": {0: "WALL", 2: "CURRENT"},
	"captain_field": {1: "CHARGER", 2: "CURRENT"},
	"captain_ridge": {2: "DIVER"},
	"warden_aldis": {0: "WALL", 1: "DIVER", 2: "CURRENT", 3: "CHARGER", 4: "ACE"},
}
const TELLS_PER_MEMBER := 2
const ENTRY_S := 1.5
const AFTERMATH_S := [2.5, 5.0, 8.0, 12.0]
const RECOVERY_S := 0.45

var out_dir := "user://f04_bosses"
var render_fights_only := false
var render_captures_only := false
var frames: Array = []

var _phys := 0
var _id := ""
var _fight0 := 0
var _manager: Node = null
var _enemy: Node3D = null
var _member := -1
var _enemy_species := ""
var _tells_by_member := {}
var _pending: Array = []
var _render_until := -1
var _capturing := false


func _init(dir: String = "", fights_only: bool = false, captures_only: bool = false) -> void:
	name = "MeadowsF04BossesObserver"
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not dir.is_empty():
		out_dir = dir
	render_fights_only = fights_only or captures_only
	render_captures_only = captures_only


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	if render_fights_only:
		RenderingServer.render_loop_enabled = false
	print("F04 BOSSES observer out=%s render_fights_only=%s" % [out_dir, str(render_fights_only)])


func _physics_process(_delta: float) -> void:
	_phys += 1
	var scene := get_tree().current_scene
	var director: Node = scene.get_node_or_null(^"EncounterDirector") if scene != null else null
	var manager: Node = scene.get_node_or_null(^"CombatManager") if scene != null else null
	var id := str(director.call("trainer_battle_id")) \
		if director != null and director.has_method("trainer_battle_id") else ""
	if not _id.is_empty() and id != _id:
		_end_fight()
	if _id.is_empty() and NAMED.has(id):
		_begin_fight(id, manager)
	if render_fights_only and not _capturing:
		RenderingServer.render_loop_enabled = _phys < _render_until \
			or (not render_captures_only and not _id.is_empty())
	if _id.is_empty():
		return
	_manager = manager
	var enemy: Node3D = null
	if _manager != null and _manager.has_method("is_fighting") and bool(_manager.call("is_fighting")):
		enemy = _manager.call("enemy_body") as Node3D
	if enemy != _enemy or (enemy != null and _species_of(enemy) != _enemy_species):
		_bind_enemy(enemy)


func _process(_delta: float) -> void:
	if _capturing or _pending.is_empty():
		return
	var due: Dictionary = _pending[0]
	if _phys < int(due["at"]):
		return
	_pending.pop_front()
	_capture(due)


func _hz() -> int:
	return Engine.physics_ticks_per_second


func _begin_fight(id: String, manager: Node) -> void:
	_id = id
	_fight0 = _phys
	_manager = manager
	_member = -1
	_tells_by_member = {}
	print("F04 BOSSES begin %s" % id)


func _end_fight() -> void:
	_bind_enemy(null)
	var spec := TRAINERS.trainer(_id)
	var game := get_tree().root.get_node_or_null(^"Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	var flag := str(spec.get("defeat_flag", ""))
	var won := progression != null and not flag.is_empty() and bool(progression.call("has", flag))
	print("F04 BOSSES end %s won=%s after %.1fs" % [_id, str(won), float(_phys - _fight0) / _hz()])
	if won:
		for s: float in AFTERMATH_S:
			_queue("%s-after-%02ds" % [_id, int(round(s))], s, {"kind": "aftermath", "after_s": s})
		if not render_captures_only:
			_render_until = _phys + int((float(AFTERMATH_S.back()) + 1.0) * _hz())
	_id = ""


func _bind_enemy(enemy: Node3D) -> void:
	if _enemy != null and is_instance_valid(_enemy) and _enemy.has_signal("telegraph_started") \
			and _enemy.is_connected("telegraph_started", _on_tell):
		_enemy.disconnect("telegraph_started", _on_tell)
	_enemy = enemy if enemy != null and is_instance_valid(enemy) else null
	_enemy_species = _species_of(_enemy)
	if _enemy == null:
		return
	# The send-out's team index: the next team slot holding this species.
	var team := TRAINERS.team_of(TRAINERS.trainer(_id))
	var next := _member + 1
	for i in range(_member + 1, team.size()):
		if str((team[i] as Dictionary).get("species", "")) == _enemy_species:
			next = i
			break
	_member = next
	var shape := str((NAMED[_id] as Dictionary).get(_member, ""))
	print("F04 BOSSES %s member %d %s shape=%s" % [_id, _member, _species(), shape])
	if shape.is_empty():
		return
	_queue("%s-m%d-%s-entry" % [_id, _member, _species()], ENTRY_S, {"kind": "entry", "shape": shape})
	if _enemy.has_signal("telegraph_started"):
		_enemy.connect("telegraph_started", _on_tell)


func _on_tell(seconds: float) -> void:
	if _id.is_empty() or _enemy == null:
		return
	var shape := str((NAMED[_id] as Dictionary).get(_member, ""))
	if shape.is_empty():
		return
	var k := int(_tells_by_member.get(_member, 0)) + 1
	_tells_by_member[_member] = k
	if k > TELLS_PER_MEMBER:
		return
	var base := "%s-m%d-%s-t%d" % [_id, _member, _species(), k]
	var meta := {"kind": "tell", "shape": shape, "tell_s": snappedf(seconds, 0.01)}
	_queue(base + "-a-start", 0.05, meta)
	_queue(base + "-b-mid", seconds * 0.5, meta)
	_queue(base + "-c-strike", seconds + 0.1, meta)
	_queue(base + "-d-recovery", seconds + RECOVERY_S, meta)
	# Drawn continuously through the tell, so each frame lands on its moment.
	_render_until = maxi(_render_until, _phys + int((seconds + RECOVERY_S + 0.3) * _hz()))


func _queue(tag: String, after_s: float, meta: Dictionary) -> void:
	var entry := {"at": _phys + maxi(1, int(after_s * _hz())), "tag": tag, "id": _id, "meta": meta}
	_pending.append(entry)
	_pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["at"]) < int(b["at"]))


func _species() -> String:
	return _species_of(_enemy)


func _species_of(body: Node) -> String:
	if body == null or not is_instance_valid(body):
		return ""
	var s: Variant = body.get("species_id")
	return str(s) if s != null else str(body.name)


func _capture(due: Dictionary) -> void:
	_capturing = true
	# A few drawn frames first, so a render loop that was off has settled.
	var warm := 2 if RenderingServer.render_loop_enabled else 4
	RenderingServer.render_loop_enabled = true
	for i in warm:
		await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [out_dir, str(due["tag"])]
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(path) if image != null else ERR_CANT_CREATE
	var ctx := _context(str(due["id"]))
	ctx["meta"] = due["meta"]
	ctx["png"] = path
	ctx["saved"] = err == OK
	var file := FileAccess.open("%s/%s.json" % [out_dir, str(due["tag"])], FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(ctx, "  "))
		file.close()
	frames.append(ctx)
	print("F04 BOSSES frame %s saved=%s" % [str(due["tag"]), str(err == OK)])
	_capturing = false


func _context(id: String) -> Dictionary:
	var scene := get_tree().current_scene
	var camera := get_viewport().get_camera_3d()
	var out := {"fight": id, "game_frame": Engine.get_physics_frames()}
	var bodies := {}
	if scene != null:
		var player := scene.get_node_or_null(^"Player") as Node3D
		if player != null:
			bodies["player"] = player
		var director := scene.get_node_or_null(^"EncounterDirector")
		if director != null and director.has_method("ally_body"):
			var ally := director.call("ally_body") as Node3D
			if ally != null and is_instance_valid(ally):
				bodies["ally"] = ally
		if _enemy != null and is_instance_valid(_enemy):
			bodies["enemy"] = _enemy
		for node: Node in scene.find_children("*", "Node3D", true, false):
			if str(node.get_meta("trainer_id", "")) == id:
				bodies["trainer"] = node
				break
	for key: String in bodies:
		var body := bodies[key] as Node3D
		var p := body.global_position
		var row := {"pos": [snappedf(p.x, 0.1), snappedf(p.y, 0.1), snappedf(p.z, 0.1)]}
		if camera != null:
			row["in_frustum"] = camera.is_position_in_frustum(p + Vector3.UP)
			row["camera_m"] = snappedf(camera.global_position.distance_to(p), 0.1)
		out[key] = row
	if camera != null:
		var c := camera.global_position
		out["camera"] = [snappedf(c.x, 0.1), snappedf(c.y, 0.1), snappedf(c.z, 0.1)]
	out["hud_text"] = _visible_text()
	return out


## Every visible, non-empty Label/RichTextLabel on screen: which toast or line
## the frame carries, so a frame with the level-up line still up is known.
func _visible_text() -> Array:
	var out: Array = []
	for node: Node in get_tree().root.find_children("*", "Control", true, false):
		var c := node as Control
		if not c.is_visible_in_tree():
			continue
		var text := ""
		if c is Label:
			text = (c as Label).text
		elif c is RichTextLabel:
			text = (c as RichTextLabel).get_parsed_text()
		text = text.strip_edges()
		if not text.is_empty() and text.length() < 160:
			out.append(text)
	return out
