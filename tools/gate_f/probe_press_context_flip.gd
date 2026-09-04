extends SceneTree

## W02-HARNESS-CONTEXT-0904 / CL-H13. Reproduces, deterministically and
## without walking a segment, the `input_context -> build_catalogue` flip the
## Gate 3 lanes hit at Oreth (S08-93), at Captain Vance (S07-57, before its
## mouse routing) and "after Captain Riverwatch" (Riverwatch IS Oreth: the
## same S08-93 step, seen from a second run) -- and shows the mechanism-level
## fix (`operator_harness.gd::_resolve_press`) holding it closed on the same
## commit.
##
## ## What it does
##
##   1. seeds slot 4 from a synthetic entry save (`build_s08_entry_synthetic.gd`
##      for Oreth, `build_s07_entry_synthetic.gd` for Vance), stands the real
##      Meadows up, loads through the production `Game.load_game()`;
##   2. teleports the trainer onto the captain's own challenge line;
##   3. puts the party's lead in the state under test (`--ally=fit|fainted|
##      undeployed`);
##   4. runs the EXACT step shape the segment JSON uses at that site
##      (S08-89..S08-95 / S07-50..S07-58), with the harness's own injection
##      semantics (`_edge`: the physical binding via `Input.parse_input_event`
##      AND the paired `Input.action_press`; one idle frame down, N physics
##      frames held, the release edge, one idle frame up);
##   5. traces, on EVERY process frame, `input_context`, `is_fighting`,
##      `trainer_battle_active`, the arbiter's `enabled`, whether the Build
##      catalogue is open, and which of the watched actions the game sees as
##      just-pressed -- printing a row whenever any of it changes;
##   6. reports FLIPPED if `build_catalogue` was ever the live context, CLEAN
##      otherwise, and exits 2 / 0 accordingly.
##
## `--mode=blind` injects exactly as `press` did before CL-H13 (the
## reproduction). `--mode=guarded` asks the harness's own static
## `_resolve_press()` before every press, the way `press` does now, and
## refuses what it refuses (the fix, on the same path).
##
##   godot --headless --path . --script tools/gate_f/probe_press_context_flip.gd -- \
##     --seed=<dir>/S07-exit.json --site=oreth --ally=fainted --mode=blind
##   godot --headless --path . --script tools/gate_f/probe_press_context_flip.gd -- \
##     --seed=<dir>/S06-exit.json --site=vance --ally=fit --mode=guarded
##
## `--out=<file>` also writes the trace rows as CSV.

const HARNESS := preload("res://tools/gate_f/operator_harness.gd")
const PROBE := preload("res://scripts/debug/gate_f_probe.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SLOT := 4
const SETTLE_FRAMES := 240

## The step shapes, transcribed from the segment JSONs (S08.json steps 104-110,
## S07.json steps 66-79) -- `press` args verbatim, `wait` in seconds.
const SITES := {
	"oreth": {
		"trainer": "captain_riverwatch",
		"steps": [
			{"id": "S08-89", "press": "interact", "hold": "tap"},
			{"id": "S08-90", "press": "interact", "hold": "tap", "times": 12, "settle": 20},
			{"id": "S08-91", "wait": 3.0},
			{"id": "S08-92", "press": "combat_quick", "hold": "tap", "times": 40, "settle": 30},
			{"id": "S08-93", "press": "combat_charged", "hold": "long"},
			{"id": "S08-94", "press": "combat_quick", "hold": "tap", "times": 24, "settle": 30},
			{"id": "S08-95", "wait": 10.0},
		],
	},
	"vance": {
		"trainer": "relay_captain",
		"steps": [
			{"id": "S07-50", "press": "interact", "hold": "tap"},
			{"id": "S07-51", "advance_dialogue": true},
			{"id": "S07-52", "wait": 3.0},
			{"id": "S07-54", "press": "combat_quick", "hold": "tap", "times": 10, "settle": 30},
			{"id": "S07-54b", "press": "party_cycle", "hold": "tap"},
			{"id": "S07-54c", "press": "combat_quick", "hold": "tap", "times": 10, "settle": 30},
			{"id": "S07-54d", "press": "party_cycle", "hold": "tap"},
			{"id": "S07-54e", "press": "combat_quick", "hold": "tap", "times": 10, "settle": 30},
			{"id": "S07-55", "press": "party_cycle", "hold": "tap"},
			{"id": "S07-56", "press": "combat_quick", "hold": "tap", "times": 13, "settle": 30},
			{"id": "S07-56b", "press": "party_cycle", "hold": "tap"},
			{"id": "S07-56c", "press": "combat_quick", "hold": "tap", "times": 13, "settle": 30},
			{"id": "S07-57", "press": "combat_charged", "hold": "long"},
			{"id": "S07-57b", "press": "party_cycle", "hold": "tap"},
			{"id": "S07-58", "press": "combat_quick", "hold": "tap", "times": 10, "settle": 30},
			{"id": "S07-59", "wait": 10.0},
		],
	},
}

## Every action the watched bindings can reach, so the trace shows what the
## GAME saw pressed, not what the step named.
const WATCHED := ["interact", "build_place", "combat_quick", "map_zoom_in", "build_rotate_right",
	"combat_charged", "build_shortcut", "map_zoom_out", "build_rotate_left",
	"party_cycle", "menu_tab_left", "menu_cancel", "hotbar_1", "build_open"]

var _seed := ""
var _site := "oreth"
var _ally := "fit"
var _mode := "blind"
var _out := ""

var _world: Node
var _game: Node
var _player: CharacterBody3D
var _probe: RefCounted
var _manager: Node
var _director: Node
var _panel: Node
var _rig: Node3D

var _frame := 0
var _last_row := ""
var _rows: PackedStringArray = []
var _contexts_seen := {}
var _flipped_at := ""
var _refused: Array[String] = []
var _landed := 0
var _fights_started := 0
var _step_now := "-"
var _contexts_table := {}


func _init() -> void:
	call_deferred("_run")


func _arg(name: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):
			return a.substr(name.length() + 3)
	return fallback


func _run() -> void:
	_seed = _arg("seed", "")
	_site = _arg("site", "oreth")
	_ally = _arg("ally", "fit")
	_mode = _arg("mode", "blind")
	_out = _arg("out", "")
	if _seed.is_empty() or not SITES.has(_site) or not _mode in ["blind", "guarded"] \
			or not _ally in ["fit", "fainted", "undeployed"]:
		print("PROBE FAIL: needs --seed=<save json> --site=oreth|vance --ally=fit|fainted|undeployed --mode=blind|guarded")
		quit(2)
		return
	_contexts_table = HARNESS._load_input_contexts()

	# --- seed the slot, stand the world up, load through the real path ---
	var save := SAVE_GAME.new()
	var slot_dst: String = save.slot_path(SLOT)
	DirAccess.make_dir_recursive_absolute(slot_dst.get_base_dir())
	var seed_abs := ProjectSettings.globalize_path(_seed) if _seed.begins_with("res://") else _seed
	if not FileAccess.file_exists(seed_abs):
		print("PROBE FAIL: no seed at %s" % seed_abs)
		quit(2)
		return
	var out := FileAccess.open(slot_dst, FileAccess.WRITE)
	out.store_buffer(FileAccess.get_file_as_bytes(seed_abs))
	out.close()

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	_game = root.get_node_or_null(^"Game")
	if _game == null or not bool(_game.call("load_game", SLOT)):
		print("PROBE FAIL: the seed would not load")
		quit(2)
		return
	for i in 90:
		await physics_frame

	_probe = PROBE.new(self)
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	var trainers := _world.get_node_or_null(^"Trainers")
	if _player == null or _manager == null or _director == null or _panel == null or trainers == null:
		print("PROBE FAIL: the scene is missing Player, CombatManager, EncounterDirector, DialoguePanel or Trainers")
		quit(2)
		return

	# --- stand on the captain's challenge line ---
	var trainer_id := str((SITES[_site] as Dictionary)["trainer"])
	var body: Node3D = trainers.call("body_for", trainer_id) as Node3D
	if body == null:
		print("PROBE FAIL: trainer '%s' was never stood up" % trainer_id)
		quit(2)
		return
	var spec: Dictionary = TRAINERS.trainer(trainer_id)
	var facing_rad := deg_to_rad(float(spec.get("facing_deg", 0.0)))
	var spot := body.global_position + Vector3(sin(facing_rad), 0.0, cos(facing_rad)) * 2.6
	if _world.has_method("ground_height_at"):
		spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	if _rig != null:
		_rig.global_position = spot
	for i in 120:
		await physics_frame
	var toward := body.global_position - _player.global_position
	toward.y = 0.0
	if _rig != null and toward.length() > 0.01:
		_rig.set("yaw", atan2(-toward.x, -toward.z))
	for i in 30:
		await physics_frame
	print("standing %.1f m from %s (%s) at %s" % [
		_player.global_position.distance_to(body.global_position), trainer_id,
		str(spec.get("name", "")), str(_player.global_position)])

	# --- the lead's state under test ---
	var party: RefCounted = _game.get("party")
	match _ally:
		"fit":
			for c: RefCounted in party.call("members"):
				c.set("hp", c.get("max_hp"))
				c.set("fainted", false)
			if _director.call("ally_instance") == null:
				_director.call("summon_active_creature")
				for i in 30:
					await physics_frame
		"fainted":
			if _director.call("ally_instance") == null:
				_director.call("summon_active_creature")
				for i in 30:
					await physics_frame
			var lead: RefCounted = _director.call("ally_instance")
			if lead != null:
				lead.set("hp", 0.0)
				lead.set("fainted", true)
		"undeployed":
			pass
	for i in 30:
		await physics_frame
	print("ally=%s: deployed=%s fainted=%s can_challenge=%s prompt=\"%s\"" % [
		_ally, str(_director.call("ally_instance") != null),
		str(_director.call("ally_instance") != null and bool((_director.call("ally_instance") as RefCounted).get("fainted"))),
		str(_director.call("can_challenge", spec)), str(_director.call("prompt"))])
	print("mode=%s site=%s  input_context before the shape: %s" % [_mode, _site, _probe.call("input_context")])

	# --- trace every process frame while the shape runs ---
	process_frame.connect(_sample)
	if _manager.has_signal("exited"):
		_manager.connect("exited", func(_outcome: String) -> void: pass)
	print("")
	print("frame | step     | input_context     | fight | battle | arbiter | catalogue | just-pressed")
	for step: Dictionary in (SITES[_site] as Dictionary)["steps"]:
		_step_now = str(step["id"])
		if step.has("wait"):
			for i in int(round(float(step["wait"]) * float(Engine.physics_ticks_per_second))):
				await physics_frame
			continue
		if step.has("advance_dialogue"):
			await _advance_dialogue()
			continue
		await _press_step(step)
	process_frame.disconnect(_sample)

	# --- verdict ---
	print("")
	var final_context := str(_probe.call("input_context"))
	var catalogue_open := _catalogue_open()
	print("=== %s / ally=%s / mode=%s ===" % [_site, _ally, _mode])
	print("  presses landed: %d   refused: %d   fights started: %d" % [_landed, _refused.size(), _fights_started])
	for r in _refused:
		print("    refused: %s" % r)
	print("  contexts seen: %s" % ", ".join(_contexts_seen.keys()))
	print("  final input_context: %s   build catalogue open: %s" % [final_context, str(catalogue_open)])
	if not _out.is_empty():
		var f := FileAccess.open(_out, FileAccess.WRITE)
		if f != null:
			f.store_line("frame,step,input_context,fighting,battle,arbiter_enabled,catalogue_open,just_pressed")
			for row in _rows:
				f.store_line(row)
			f.close()
			print("  trace: %s (%d rows)" % [_out, _rows.size()])
	if not _flipped_at.is_empty():
		print("VERDICT: FLIPPED -- input_context became build_catalogue during %s" % _flipped_at)
		quit(2)
	else:
		print("VERDICT: CLEAN -- input_context never became build_catalogue")
		quit(0)


func _catalogue_open() -> bool:
	for node: Node in get_nodes_in_group(BUILD_MENU.GROUP):
		if node.has_method("is_open") and bool(node.call("is_open")):
			return true
	return false


func _sample() -> void:
	_frame += 1
	var context := str(_probe.call("input_context"))
	_contexts_seen[context] = true
	if context == "build_catalogue" and _flipped_at.is_empty():
		_flipped_at = "%s (frame %d)" % [_step_now, _frame]
	var fighting := bool(_manager.call("is_fighting"))
	var battle := bool(_director.call("trainer_battle_active"))
	var arbiter: Node = _probe.call("interaction_arbiter") as Node
	var enabled := arbiter != null and bool(arbiter.call("enabled"))
	var pressed: PackedStringArray = []
	for a: String in WATCHED:
		if Input.is_action_just_pressed(StringName(a)):
			pressed.append(a)
	var catalogue := _catalogue_open()
	var key := "%s|%s|%s|%s|%s|%s" % [context, fighting, battle, enabled, catalogue, ",".join(pressed)]
	var row := "%d,%s,%s,%s,%s,%s,%s,%s" % [_frame, _step_now, context, fighting, battle, enabled, catalogue, "+".join(pressed)]
	_rows.append(row)
	if key != _last_row:
		_last_row = key
		print("%5d | %-8s | %-17s | %-5s | %-6s | %-7s | %-9s | %s" % [
			_frame, _step_now, context, str(fighting), str(battle), str(enabled), str(catalogue), "+".join(pressed)])


func _hold_frames(spec: String) -> int:
	match spec:
		"long":
			return HARNESS.HOLD_LONG
		"short":
			return HARNESS.HOLD_SHORT
		_:
			return HARNESS.HOLD_TAP


## The `press` step, with the harness's own edges and timing.
func _press_step(step: Dictionary) -> void:
	var control := str(step["press"])
	var frames := _hold_frames(str(step.get("hold", "tap")))
	var times := int(step.get("times", 1))
	var settle := int(step.get("settle", 8))
	for i in times:
		if _mode == "guarded":
			var verdict: Dictionary = HARNESS._resolve_press(control, str(_probe.call("input_context")), "", _contexts_table)
			if not bool(verdict.get("ok", true)):
				var line := "%s press %d/%d: %s" % [str(step["id"]), i + 1, times, str(verdict.get("why", ""))]
				_refused.append(line)
				print("      REFUSED %s" % line)
				return
		var was_fighting := bool(_manager.call("is_fighting"))
		await _inject(control, frames)
		_landed += 1
		if not was_fighting and bool(_manager.call("is_fighting")):
			_fights_started += 1
		for f in settle:
			await process_frame


## `advance_dialogue_until_closed`'s shape, reduced: press interact while the
## panel is open, stop when it closes.
func _advance_dialogue() -> void:
	for i in 60:
		if not bool(_panel.call("is_open")):
			return
		await _inject("interact", HARNESS.HOLD_TAP)
		_landed += 1
		for f in 30:
			await process_frame


## `operator_harness.gd::_inject` / `_edge`, verbatim in effect: the physical
## binding through `Input.parse_input_event` AND the paired action state, one
## idle frame down, N physics frames held, the release edge, one idle frame up.
func _inject(control: String, frames: int) -> void:
	_edge(control, true)
	await process_frame
	for i in maxi(1, frames):
		await physics_frame
	_edge(control, false)
	await process_frame
	await physics_frame


func _edge(control: String, pressed: bool) -> void:
	var action := StringName(control)
	var binding: InputEvent = HARNESS._physical_binding(action, "")
	if binding is InputEventJoypadButton:
		var b := InputEventJoypadButton.new()
		b.button_index = (binding as InputEventJoypadButton).button_index
		b.pressed = pressed
		Input.parse_input_event(b)
	elif binding is InputEventJoypadMotion:
		var m := InputEventJoypadMotion.new()
		m.axis = (binding as InputEventJoypadMotion).axis
		m.axis_value = (binding as InputEventJoypadMotion).axis_value if pressed else 0.0
		Input.parse_input_event(m)
	elif binding is InputEventKey:
		var k := InputEventKey.new()
		k.keycode = (binding as InputEventKey).keycode
		k.physical_keycode = (binding as InputEventKey).physical_keycode
		k.pressed = pressed
		Input.parse_input_event(k)
	if pressed:
		Input.action_press(action, 1.0)
	else:
		Input.action_release(action)
