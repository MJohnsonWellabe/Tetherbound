extends SceneTree

## Net harness peer process. Stage B Wave 0 lane 0.F.
## docs/specs/MP_NET_HARNESS_CONTRACT.md §2-§5.
##
##   godot --headless --path . --script tools/net/peer_runner.gd -- \
##       --role=host --peer=0 --control-port=27901 --enet-port=27801 --scene=world
##
## One process, one peer. Boots the requested scene the same way
## tests/smoke_playground.gd does (load -> instantiate -> root.add_child ->
## settle), connects OUT to the coordinator's TCP control port (the
## coordinator is the TCPServer -- tests/helpers/net_harness.gd), announces
## itself with `hello`, then executes `step`/`probe`/`quit` messages as they
## arrive, replying with `verdict`/`value`, and heartbeats every
## HEARTBEAT_FRAMES physics frames with a world-state hash (contract §7).
##
## ## Two existing seams reused, not reinvented
##
##   * `scripts/debug/gate_f_probe.gd` -- the same read-only state accessors
##     Gate F uses (player(), input_context(), party_state(), flags(), ...).
##   * `tests/helpers/stick_navigator.gd` -- the same wall-aware walker
##     `move_to` needs, constructed exactly the way every Gate F harness
##     constructs it: `(tree, player, rig, drive_callable)`.
##
## `tools/gate_f/operator_harness.gd`'s press/hold/stick injection
## (`_inject`/`_edge`/`_press_axis`) is PORTED below rather than preloaded and
## called: every one of those methods reads and writes that file's own
## instance state (`_last_input`, `_stick_left`, `_tick()`'s pacing/telemetry
## bookkeeping), which does not belong to a peer process and cannot be shared
## across two unrelated SceneTree instances. The one piece of that file that
## IS reused directly, by preload, is `_physical_binding` -- it is `static`
## and reads only the live InputMap, so a second copy of it here would be
## exactly the kind of drift this repo's own tooling exists to avoid (see that
## file's header on `input_contexts.json` and the KBM-parity bug a duplicated
## copy would risk repeating). The physical/polled double-injection itself
## (both a real InputEvent AND the paired `Input.action_press`/`release`) is
## ported verbatim in spirit: that file's header explains why a press that
## only ever did one or the other reaches half the game.
##
## ## Spike advice carried over
## (ralph/reports/MP-0C-SPIKE-ENET-0905/REPORT.md)
##
##   1. Every flag a signal sets lives in a Dictionary state box, never a bare
##      local -- a GDScript lambda captures an outer bool/int BY VALUE, so
##      `var connected := false; sig.connect(func(): connected = true)` never
##      moves the variable a polling loop reads. `_rx_state` below is that box
##      for this file's own two flags (`quit`, `quit_code`).
##   2. Every real id worth knowing is logged with the honest number, not a
##      guess -- `hello`'s `pid` and this peer's own control-channel index are
##      both logged verbatim. There is no real ENet peer id yet: Wave 0 has no
##      Session to host/join (contract §1), so `probe session` reports a
##      Wave-0-honest stub (see `_execute_probe`) rather than inventing one.
##   3. (spawner authority set before tree entry) does not apply until Wave 2
##      hands this a real `MultiplayerSpawner`; noted here so it is not
##      forgotten when it does.

const GATE_F_HARNESS := preload("res://tools/gate_f/operator_harness.gd")
const PROBE := preload("res://scripts/debug/gate_f_probe.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const CLOUDREACH_SCENE := "res://scenes/world/cloudreach_cliffs.tscn"

const DEFAULT_SETTLE_FRAMES := 240
const HEARTBEAT_FRAMES := 60
## ~10s of idle-frame polling for the initial TCP connect, matching the
## spike's own FRAME_BUDGET for "this should be instant; anything longer means
## the coordinator is not up".
const CONNECT_BUDGET_FRAMES := 600

## Contract §7: the world-save keys excluded from the desync hash because they
## are expected to differ per peer/instant rather than agree ("player state is
## by construction different per peer"). ONE list, in one place -- read back by
## `tests/helpers/net_harness.gd` (by preloading this file) for NET_RUN.json,
## rather than copied a second time there.
const STATE_HASH_EXCLUDED_KEYS: Array[String] = ["clock_elapsed_seconds", "player_pose"]

## NOT part of the contract's own list (§7 names exactly the two keys above).
## Added after 0.F's own verification hit a measured, reproducible flake:
## `satiety` (`autoload/game_state.gd`) drains continuously with real elapsed
## time, the same way `clock_elapsed_seconds` itself does -- so hashing its
## leaf FLOAT rather than the elapsed-time input that produces it occasionally
## catches two independently-scheduled OS processes a fraction of a second
## apart and reads a real, harmless timing gap as a desync. Measured live on
## two save files that agreed on every OTHER field: 99.7202222222249 vs
## 99.7868888888909. Contract §6 already says two processes "cannot be
## frame-locked" for a `race` step; the same fact applies to wall time between
## any two continuously-draining stats, not only to steps.
##
## Flagged for the contract's owner rather than folded into
## `STATE_HASH_EXCLUDED_KEYS` silently: `MP_NET_HARNESS_CONTRACT.md`'s own
## rule is "fix the harness or amend this document in the same commit -- never
## both silently", and lane 0.F does not own that file. Kept as its own
## constant (also printed into `NET_RUN.json`, separately labelled) so the
## deviation is visible evidence, not a quiet rewrite of §7's list -- see the
## lane report's findings for the reconciliation this needs.
const WAVE0_PROVISIONAL_EXCLUDED_KEYS: Array[String] = ["satiety"]

## A save slot outside the game's own UI range. `scripts/save/save_game.gd`'s
## SLOT_COUNT is 5 (slots 0..4); nothing under `scripts/ui` ever writes slot 4,
## so hashing here can never clobber a save a player made, or a save another
## smoke seeded and is asserting against.
const HASH_SCRATCH_SLOT := 4

var _role := ""
var _peer_index := -1
var _control_port := 0
var _enet_port := 0
var _scene_name := "world"

var _sock: StreamPeerTCP = null
var _rx_buf := ""
var _probe: RefCounted = null
var _physics_count := 0
## Spike advice #1: a Dictionary state box, not bare locals, for everything a
## signal or an async branch sets and a loop elsewhere reads.
var _rx_state := {"quit": false, "quit_code": 0}
var _held_actions := {}


func _initialize() -> void:
	var args := _parse_args()
	_role = str(args.get("role", ""))
	_peer_index = int(args.get("peer", -1))
	_control_port = int(args.get("control-port", 0))
	_enet_port = int(args.get("enet-port", 0))
	_scene_name = str(args.get("scene", "world"))

	if _role.is_empty() or _control_port <= 0:
		push_error("peer_runner: --role and --control-port are required (got role='%s' control-port=%d)"
			% [_role, _control_port])
		quit(2)
		return

	_probe = PROBE.new(self)
	print("peer[%d/%s]: starting scene=%s control_port=%d enet_port=%d xdg_data_home=%s"
		% [_peer_index, _role, _scene_name, _control_port, _enet_port, OS.get_environment("XDG_DATA_HOME")])

	await _boot_scene(_scene_name, DEFAULT_SETTLE_FRAMES)

	var connected := await _connect_control(_control_port)
	if not connected:
		push_error("peer_runner: could not reach coordinator on 127.0.0.1:%d within budget" % _control_port)
		quit(2)
		return

	_send({"type": "hello", "peer": _peer_index, "role": _role, "pid": OS.get_process_id(),
		"godot_version": String(Engine.get_version_info().get("string", "")),
		"main_sha": _git_sha()})

	physics_frame.connect(_on_physics_frame)
	await _main_loop()


# --- boot ---------------------------------------------------------------------

func _boot_scene(which: String, settle: int) -> void:
	if which == "loopback":
		_boot_loopback()
	else:
		var path := WORLD_SCENE
		if which == "title":
			path = TITLE_SCENE
		elif which == "cloudreach":
			path = CLOUDREACH_SCENE
		var packed: PackedScene = load(path)
		if packed == null:
			push_error("peer_runner: could not load scene '%s' (%s)" % [which, path])
			quit(2)
			return
		if current_scene != null:
			var old := current_scene
			root.remove_child(old)
			old.queue_free()
			await process_frame
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		current_scene = scene
	for i in maxi(0, settle):
		await physics_frame
	_scene_name = which


## The Wave-0 loopback world: no packed scene, just the bare Node the ENet
## spike (`tools/net/_spike_enet.gd`) stood up, for control-channel-only runs
## that do not want to pay the Meadows' boot cost. Has no Player/CameraRig, so
## `move_to`/`assert near`/etc correctly report "no live player" rather than
## silently no-op.
func _boot_loopback() -> void:
	if current_scene != null:
		var old := current_scene
		root.remove_child(old)
		old.queue_free()
	var w := Node.new()
	w.name = "NetLoopback"
	root.add_child(w)
	current_scene = w


# --- control channel ------------------------------------------------------------

func _connect_control(port: int) -> bool:
	_sock = StreamPeerTCP.new()
	var err := _sock.connect_to_host("127.0.0.1", port)
	if err != OK:
		push_error("peer_runner: connect_to_host(127.0.0.1, %d) failed err=%d" % [port, err])
		return false
	var frames := 0
	while frames < CONNECT_BUDGET_FRAMES:
		_sock.poll()
		var status := _sock.get_status()
		if status == StreamPeerTCP.STATUS_CONNECTED:
			return true
		if status == StreamPeerTCP.STATUS_ERROR:
			return false
		await process_frame
		frames += 1
	return false


func _send(msg: Dictionary) -> void:
	if _sock == null:
		return
	_sock.poll()
	if _sock.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return
	_sock.put_data((JSON.stringify(msg) + "\n").to_utf8_buffer())


func _poll_socket() -> void:
	if _sock == null:
		return
	_sock.poll()
	if _sock.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		print("peer[%d/%s]: control socket status=%d, treating as coordinator gone" %
			[_peer_index, _role, _sock.get_status()])
		_rx_state["quit"] = true
		_rx_state["quit_code"] = 2
		return
	var n := _sock.get_available_bytes()
	if n > 0:
		var res: Array = _sock.get_data(n)
		if int(res[0]) == OK:
			_rx_buf += (res[1] as PackedByteArray).get_string_from_utf8()


func _pop_line() -> String:
	var idx := _rx_buf.find("\n")
	if idx < 0:
		return ""
	var line := _rx_buf.substr(0, idx)
	_rx_buf = _rx_buf.substr(idx + 1)
	return line


func _main_loop() -> void:
	while not bool(_rx_state.get("quit", false)):
		await process_frame
		_poll_socket()
		while true:
			var line := _pop_line()
			if line.is_empty():
				break
			var parsed = JSON.parse_string(line)
			if typeof(parsed) != TYPE_DICTIONARY:
				print("peer[%d/%s]: WARN unparseable control line: %s" % [_peer_index, _role, line])
				continue
			await _handle_message(parsed)
	quit(int(_rx_state.get("quit_code", 0)))


func _handle_message(msg: Dictionary) -> void:
	var kind := str(msg.get("type", ""))
	match kind:
		"step":
			var result := await _execute_step(msg)
			_send({"type": "verdict", "id": msg.get("id", ""),
				"verdict": str(result.get("verdict", "ERROR")),
				"detail": str(result.get("detail", "")),
				"frames_used": int(result.get("frames_used", 0))})
		"probe":
			var value = await _execute_probe(msg)
			_send({"type": "value", "id": msg.get("id", ""), "value": value})
		"quit":
			_rx_state["quit"] = true
			_rx_state["quit_code"] = int(msg.get("code", 0))
		_:
			print("peer[%d/%s]: WARN unknown message type '%s'" % [_peer_index, _role, kind])


func _on_physics_frame() -> void:
	_physics_count += 1
	if _physics_count % HEARTBEAT_FRAMES == 0:
		_send_heartbeat()


func _send_heartbeat() -> void:
	var player := _probe.call("player") as Node3D
	var pos = null
	if player != null:
		var p: Vector3 = player.global_position
		pos = [p.x, p.y, p.z]
	_send({"type": "heartbeat", "frame": Engine.get_process_frames(), "physics_frame": _physics_count,
		"t": Time.get_ticks_msec() / 1000.0, "pos": pos,
		"context": str(_probe.call("input_context")),
		"state_hash": _compute_state_hash(),
		# No real Session yet (Wave 0, contract §1) -- honestly empty rather
		# than fabricated.
		"session_peers": []})


# --- step vocabulary --------------------------------------------------------

func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	var args: Dictionary = (msg.get("args", {}) as Dictionary)
	var before := _physics_count
	var out: Dictionary
	match action:
		"boot":
			out = await _step_boot(args)
		"wait":
			out = await _step_wait(args)
		"press":
			out = await _step_press(args)
		"hold":
			out = await _step_hold(args)
		"release":
			out = await _step_release(args)
		"stick":
			out = await _step_stick(args)
		"move_to":
			out = await _step_move_to(args)
		"assert":
			out = _step_assert(args)
		_:
			out = {"verdict": "ERROR", "detail": "unknown action '%s'" % action}
	out["frames_used"] = _physics_count - before
	return out


func _step_boot(args: Dictionary) -> Dictionary:
	var which := str(args.get("scene", _scene_name))
	var settle := int(args.get("settle_frames", DEFAULT_SETTLE_FRAMES))
	await _boot_scene(which, settle)
	return {"verdict": "PASS", "detail": "booted %s (%d settle frames)" % [which, settle]}


func _step_wait(args: Dictionary) -> Dictionary:
	var frames := int(args.get("frames", 0))
	if args.has("seconds"):
		frames = int(round(float(args["seconds"]) * float(Engine.physics_ticks_per_second)))
	for i in maxi(0, frames):
		await physics_frame
	return {"verdict": "PASS", "detail": "waited %d physics frames" % frames}


## One edge of one action: the physical InputEvent AND the paired polled
## state, always -- see this file's header. Ported from
## `tools/gate_f/operator_harness.gd::_edge`, trimmed to the event kinds a net
## smoke actually needs (no mouse aiming in Wave 0).
func _press_edge(action: String, pressed: bool) -> Dictionary:
	var a := StringName(action)
	if not InputMap.has_action(a):
		return {"ok": false, "why": "no input action '%s' in the live InputMap" % action}
	var binding: InputEvent = GATE_F_HARNESS._physical_binding(a)
	if binding == null:
		return {"ok": false, "why": "action '%s' has no physical binding to inject" % action}
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
	elif binding is InputEventMouseButton:
		var mb := InputEventMouseButton.new()
		mb.button_index = (binding as InputEventMouseButton).button_index
		mb.pressed = pressed
		Input.parse_input_event(mb)
	else:
		return {"ok": false, "why": "action '%s' binds an event type this harness cannot synthesize (%s)"
			% [action, binding.get_class()]}
	if pressed:
		Input.action_press(a, 1.0)
	else:
		Input.action_release(a)
	return {"ok": true}


## Ported from `operator_harness.gd::_inject`: one idle frame with the control
## held BEFORE any physics frame (every menu polls
## `Input.is_action_just_pressed` from `_process`, which is idle), then the
## held physics frames, then the release edge, then one more idle+physics
## frame so a release-edge reader sees it too.
func _inject(action: String, frames: int) -> Dictionary:
	var down := _press_edge(action, true)
	if not bool(down.get("ok", false)):
		return down
	await process_frame
	for i in maxi(1, frames):
		await physics_frame
	var up := _press_edge(action, false)
	await process_frame
	await physics_frame
	return {"ok": bool(up.get("ok", false)), "why": str(up.get("why", ""))}


func _step_press(args: Dictionary) -> Dictionary:
	var action := str(args.get("action", ""))
	var times := int(args.get("times", 1))
	var gap := int(args.get("gap_frames", 18))
	for i in maxi(1, times):
		var r := await _inject(action, 1)
		if not bool(r.get("ok", false)):
			return {"verdict": "ERROR", "detail": "press '%s' could not be injected: %s"
				% [action, str(r.get("why", ""))]}
		if i < times:
			for g in gap:
				await physics_frame
	return {"verdict": "PASS", "detail": "pressed '%s' x%d" % [action, times]}


func _step_hold(args: Dictionary) -> Dictionary:
	var action := str(args.get("action", ""))
	var frames := int(args.get("frames", 0))
	var down := _press_edge(action, true)
	if not bool(down.get("ok", false)):
		return {"verdict": "ERROR", "detail": "hold '%s' could not be injected: %s"
			% [action, str(down.get("why", ""))]}
	_held_actions[action] = true
	await process_frame
	for i in frames:
		await physics_frame
	return {"verdict": "PASS", "detail": "holding '%s' (%d frames elapsed, still down)" % [action, frames]}


func _step_release(args: Dictionary) -> Dictionary:
	var action := str(args.get("action", ""))
	var up := _press_edge(action, false)
	_held_actions.erase(action)
	await process_frame
	if bool(up.get("ok", false)):
		return {"verdict": "PASS", "detail": "released '%s'" % action}
	return {"verdict": "ERROR", "detail": "release '%s' failed: %s" % [action, str(up.get("why", ""))]}


## Ported from `operator_harness.gd::_press_axis`: the polled action state AND
## a real `InputEventJoypadMotion`, so a menu focus walk and a poll-only
## reader both see the same deflection. Left stick only -- `move_to` is the
## only Wave-0 caller of the drive callable, and the raw `stick` action below
## covers the right stick the same way for a segment that wants it directly.
func _press_axis(action: StringName, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength <= 0.001:
		Input.action_release(action)
	else:
		Input.action_press(action, strength)
	var binding := GATE_F_HARNESS._physical_binding(action)
	var motion := binding as InputEventJoypadMotion
	if motion == null:
		return
	var m := InputEventJoypadMotion.new()
	m.axis = motion.axis
	m.axis_value = signf(motion.axis_value) * strength
	Input.parse_input_event(m)


func _drive_left(local_x: float, local_y: float) -> void:
	_press_axis(&"move_right", clampf(local_x, 0.0, 1.0))
	_press_axis(&"move_left", clampf(-local_x, 0.0, 1.0))
	_press_axis(&"move_back", clampf(local_y, 0.0, 1.0))
	_press_axis(&"move_forward", clampf(-local_y, 0.0, 1.0))


func _drive_right(local_x: float, local_y: float) -> void:
	_press_axis(&"look_right", clampf(local_x, 0.0, 1.0))
	_press_axis(&"look_left", clampf(-local_x, 0.0, 1.0))
	_press_axis(&"look_down", clampf(local_y, 0.0, 1.0))
	_press_axis(&"look_up", clampf(-local_y, 0.0, 1.0))


func _step_stick(args: Dictionary) -> Dictionary:
	var which := str(args.get("stick", "left"))
	var x := float(args.get("x", 0.0))
	var y := float(args.get("y", 0.0))
	var frames := int(args.get("frames", 10))
	var drive := _drive_left if which == "left" else _drive_right
	drive.call(x, y)
	for i in frames:
		await physics_frame
	drive.call(0.0, 0.0)
	await physics_frame
	return {"verdict": "PASS", "detail": "%s stick (%.2f, %.2f) for %d frames" % [which, x, y, frames]}


## Walked, never teleported -- `tests/helpers/stick_navigator.gd` is the
## repo's one wall-aware walker, reused rather than copied (see that file's
## own header on why a second copy is one that stops being fixed).
func _step_move_to(args: Dictionary) -> Dictionary:
	var player := _probe.call("player") as Node3D
	var rig := _probe.call("camera_rig") as Node3D
	if player == null or rig == null:
		return {"verdict": "ERROR", "detail": "no live player/camera_rig to walk (scene '%s')" % _scene_name}
	var x := float(args.get("x", 0.0))
	var z := float(args.get("z", 0.0))
	var close := float(args.get("close_enough", 0.8))
	var budget := int(args.get("budget_frames", 2400))
	var nav = NAVIGATOR.new(self, player, rig, Callable(self, "_drive_left"))
	var target := Vector3(x, player.global_position.y, z)
	var arrived: bool = await nav.walk_to(target, budget, close)
	_drive_left(0.0, 0.0)
	if arrived:
		return {"verdict": "PASS", "detail": "arrived within %.2f m of (%.1f, %.1f)" % [close, x, z]}
	var gap := Vector2(player.global_position.x - x, player.global_position.z - z).length()
	return {"verdict": "FAIL", "detail": "did not reach (%.1f, %.1f): %.2f m short of close_enough=%.2f"
		% [x, z, gap, close]}


## Semantics ported verbatim from `operator_harness.gd::_step_assert`'s own
## cases -- the exact comparisons and messages, not re-derived, for the same
## reason this whole file reads state through `gate_f_probe.gd` rather than a
## second copy of the game's own rules.
func _step_assert(args: Dictionary) -> Dictionary:
	var check := str(args.get("check", ""))
	var r := _run_assert(check, args)
	return {"verdict": "PASS" if bool(r.get("ok", false)) else "FAIL", "detail": str(r.get("actual", ""))}


func _run_assert(check: String, args: Dictionary) -> Dictionary:
	match check:
		"input_context":
			var want := str(args.get("equals", ""))
			var have := str(_probe.call("input_context"))
			return {"ok": have == want, "actual": "input_context=%s (wanted %s)" % [have, want]}
		"near":
			var at: Array = args.get("at", []) as Array
			var within := float(args.get("within", 5.0))
			var player := _probe.call("player") as Node3D
			if player == null or at.size() < 2:
				return {"ok": false, "actual": "no live player, or at:[x,z] missing"}
			var d := Vector2(player.global_position.x - float(at[0]),
				player.global_position.z - float(at[1])).length()
			return {"ok": d <= within, "actual": "%.2f m from (%.1f, %.1f), wanted within %.2f"
				% [d, float(at[0]), float(at[1]), within]}
		"party_size":
			var have := (_probe.call("party_state") as Array).size()
			if args.has("min"):
				var want_min := int(args["min"])
				return {"ok": have >= want_min, "actual": "party size %d (wanted >= %d)" % [have, want_min]}
			var want := int(args.get("equals", -1))
			return {"ok": have == want, "actual": "party size %d (wanted %d)" % [have, want]}
		"inventory_count":
			var item_id := str(args.get("item", ""))
			if item_id.is_empty():
				return {"ok": false, "actual": "inventory_count check has no item:\"...\""}
			var count := int((_probe.call("inventory_snapshot") as Dictionary).get(item_id, 0))
			var ok := true
			if args.has("max"):
				ok = ok and count <= int(args["max"])
			if args.has("min"):
				ok = ok and count >= int(args["min"])
			if args.has("equals"):
				ok = ok and count == int(args["equals"])
			return {"ok": ok, "actual": "%s count %d" % [item_id, count]}
		"flag_set":
			var flag := str(args.get("flag", ""))
			var have: Array = _probe.call("flags")
			return {"ok": have.has(flag), "actual": "flag %s %s" % [flag,
				"set" if have.has(flag) else "NOT set"]}
		_:
			return {"ok": false, "actual": "unknown assert check '%s'" % check}


# --- probes -----------------------------------------------------------------

func _execute_probe(msg: Dictionary) -> Variant:
	var what := str(msg.get("what", ""))
	match what:
		"position":
			var player := _probe.call("player") as Node3D
			if player == null:
				return null
			var p: Vector3 = player.global_position
			return [p.x, p.y, p.z]
		"input_context":
			return str(_probe.call("input_context"))
		"state_hash":
			return _compute_state_hash()
		"session":
			# Wave 0 honesty (contract §1): no Session API exists to host/join
			# yet, so this is a stub shape, not a fabricated peer list.
			return {"is_server": _role == "host", "peer_id": 0, "peers": [], "realm": "meadows"}
		_:
			return null


## Contract §7: `hash()` of `JSON.stringify(<world save dictionary>, "", true)`
## with `STATE_HASH_EXCLUDED_KEYS` removed. Before Wave 1 lands the
## dictionary is `Game.save_system.save()`'s -- and `save_game.gd` builds that
## dictionary and writes it to disk in the same breath, with no
## dictionary-only accessor -- so this calls the game's own public `save()`
## into `HASH_SCRATCH_SLOT` and reads back the exact bytes it wrote, rather
## than re-deriving the dictionary a second way. Each peer's `user://` is
## already isolated by its own `XDG_DATA_HOME` (contract §2), so this can
## never collide with a real save slot or another peer's.
func _compute_state_hash() -> int:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return 0
	var save_system: Variant = game.get("save_system")
	if save_system == null:
		return 0
	if not bool(save_system.call("save", game, HASH_SCRATCH_SLOT)):
		return 0
	var path := str(save_system.call("slot_path", HASH_SCRATCH_SLOT))
	if not FileAccess.file_exists(path):
		return 0
	var f := FileAccess.open(path, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return 0
	var data: Dictionary = parsed
	for k in STATE_HASH_EXCLUDED_KEYS:
		data.erase(k)
	for k in WAVE0_PROVISIONAL_EXCLUDED_KEYS:
		data.erase(k)
	# Wave 0 has no Session to negotiate a shared seed yet (contract §1):
	# `data/config/spawn_tables.json`'s `roll_new_worlds` ships true (owner
	# directive D-0830-1), so a fresh New Game rolls its own `world_seed` at
	# random per process. `tests/helpers/net_harness.gd::_spawn_peer` pins
	# every peer in a run to the SAME `TB_WORLD_SEED`, but
	# `spawn_tables.gd::resolve_seed()`'s own docstring is explicit that the
	# override applies "at the point of use", not to the raw value
	# `game_state.gd::new_game()` rolls and stores -- so the two peers' saved
	# `world_seed` genuinely differ (measured live: 490178442 vs 736055304)
	# even though everything that field's roll actually FEEDS (every spawn
	# table lookup) already resolves identically via the pinned override --
	# confirmed live: with the pin in place, `world_seed` was the ONLY key
	# that ever differed between two independently-booted peers. Normalizing
	# it here, for hashing only, says "the value every peer is actually
	# resolving to" rather than "which process's RNG happened to roll it",
	# without touching the live Game node or the save a player would load.
	if data.has("world_seed"):
		var pinned := OS.get_environment("TB_WORLD_SEED").strip_edges()
		if not pinned.is_empty() and pinned.is_valid_int():
			data["world_seed"] = int(pinned)
	return hash(JSON.stringify(data, "", true))


# --- misc ---------------------------------------------------------------------

func _parse_args() -> Dictionary:
	var out := {}
	for raw in OS.get_cmdline_user_args():
		var s: String = raw
		if s.begins_with("--"):
			s = s.substr(2)
		var eq := s.find("=")
		if eq >= 0:
			out[s.substr(0, eq)] = s.substr(eq + 1)
		else:
			out[s] = true
	return out


func _git_sha() -> String:
	var output := []
	var code := OS.execute("git", ["rev-parse", "--short=12", "HEAD"], output, true)
	if code == 0 and output.size() > 0:
		return str(output[0]).strip_edges()
	return ""
