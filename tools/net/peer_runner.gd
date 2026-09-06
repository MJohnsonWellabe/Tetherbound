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
##      guess -- `hello`'s `pid`, `enet_port` and this peer's own
##      control-channel index are all logged verbatim, and from Wave 2 so is the
##      real ENet peer id (`probe session`, which reads the live
##      `scripts/net/session.gd` rather than the Wave-0 stub it replaced).
##   3. (spawner authority set before tree entry) does not apply until a lane
##      hands this a real `MultiplayerSpawner` -- 2.C owns the rigs; noted here
##      so it is not forgotten when it does.

const GATE_F_HARNESS := preload("res://tools/gate_f/operator_harness.gd")
const PROBE := preload("res://scripts/debug/gate_f_probe.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SPAWN_TABLES := preload("res://scripts/combat/spawn_tables.gd")
## Lane 3.D. The real shipping chest, driven by its real submit path -- these
## arms replace the panel's presses, not the container's ledger conversation.
const STORAGE_CONTAINER := preload("res://scripts/build/storage_container.gd")
const REALM_HEART_SHRINE := preload("res://scripts/world/realm_heart_shrine.gd")
const REMOTE_PRESENTATION := preload("res://scripts/net/remote_presentation.gd")
## Lane 3.B. The pickup race smoke stands a real one of these and presses it.
const ITEM_CACHE_PICKUP := preload("res://scripts/world/item_cache_pickup.gd")
## Lane 6.E. The berry bed the farm-race smoke contests.
const FARM_PLOT := preload("res://scripts/world/farm_plot.gd")
const FARM_LOGIC := preload("res://scripts/world/farm_logic.gd")
## Lane 5.C's two arms read the same authored cluster list the shipping node
## reads, rather than a second copy of the same loop.
const ALPHA_PINS := preload("res://scripts/world/alpha_pins.gd")
const TRADE_OFFER := preload("res://scripts/ui/trade_offer.gd")
const DROPPED_ITEM := preload("res://scripts/world/dropped_item.gd")
const DROPPED_ITEM_SPAWNER := preload("res://scripts/world/dropped_item_spawner.gd")
## Lane 5.D: the real bedroll and the real tent it needs over it.
const PLAYER_BED := preload("res://scripts/build/player_bed.gd")
const CAMP_TENT := preload("res://scripts/build/camp_tent.gd")
## Stage B lane 5.A. How a story trigger reaches the ledger, and how a story
## restore path asks the WORLD (never the merged view) what has happened.
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")


## Lane 4.D. The trainer table, read the way the game reads it.
const NET_TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const NET_REWARDS := preload("res://scripts/net/encounter_rewards.gd")

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const CLOUDREACH_SCENE := "res://scenes/world/cloudreach_cliffs.tscn"

## Wave 6 lane 6.A. Realm id -> the AUTHORED ROOT NAME of its world scene, and
## -> the `boot` step's name for it. The root name is what
## `change_scene_to_file()` puts at `/root/<name>`, and (per
## `scripts/net/realm_shells.gd`'s header) it is also where the host mounts a
## shell -- which is exactly why `_step_enter_realm` compares against
## `current_scene` and not merely against the node's existence.
const REALM_ROOT_NAMES := {
	"meadows": "MeadowsPlayground",
	"cloudreach": "CloudreachCliffs",
}
const REALM_SCENE_NAMES := {
	"meadows": "world",
	"cloudreach": "cloudreach",
}

const DEFAULT_SETTLE_FRAMES := 240
const HEARTBEAT_FRAMES := 60
## ~10s of idle-frame polling for the initial TCP connect, matching the
## spike's own FRAME_BUDGET for "this should be instant; anything longer means
## the coordinator is not up".
const CONNECT_BUDGET_FRAMES := 600

## Contract §4's default per-step budget, for the Wave 2 net steps that poll
## (`join`, `expect_peers`, `wait_flag`). Named here rather than read from
## `tests/helpers/net_harness.gd` -- that file is the COORDINATOR's, runs in a
## different process, and a peer that preloaded it to borrow one number would
## be importing the whole coordinator into every peer.
const NET_STEP_BUDGET_FRAMES := 3000

## Contract §7 as amended (`f090076c`, from this lane's own findings): the
## world-save keys actually HASHED, against today's v22 save format. An
## allowlist rather than an exclude-list on purpose -- the contract's own
## words are "From Wave 1 the hashed set is exactly `WorldState.save_data()`
## and the list above retires", i.e. this list is the thing that gets
## REPLACED wholesale, not patched; keeping only what should be hashed makes
## that swap a one-line change instead of an audit of everything NOT to hash.
## Printed into `NET_RUN.json` by `tests/helpers/net_harness.gd` (by preloading
## this file) rather than copied a second time there.
const HASHED_KEYS: Array[String] = ["progression", "placed_buildings", "farm_plots",
	"death_satchels", "harvested_vegetation", "felled_vegetation", "day"]

## Contract §7's own excluded list, restated here only for `NET_RUN.json`'s
## benefit (evidence of what was deliberately left out, not consulted by
## `_compute_state_hash` -- that function keeps `HASHED_KEYS` and drops
## everything else, so this list is not the mechanism, just the record).
const EXCLUDED_KEYS: Array[String] = ["party", "inventory", "hotbar", "satiety", "map",
	"realm_maps", "alpha_pins", "player_pose", "clock_elapsed_seconds", "current_realm",
	"pending_realm_entry", "realm_hearts", "version"]

## A save slot outside the game's own UI range. `scripts/save/save_game.gd`'s
## SLOT_COUNT is 5 (slots 0..4); nothing under `scripts/ui` ever writes slot 4,
## so hashing here can never clobber a save a player made, or a save another
## smoke seeded and is asserting against.
const HASH_SCRATCH_SLOT := 4

## Lane 3.C. A second scratch slot, for the explicit host save the shared-
## building smoke asserts against. Separate from `HASH_SCRATCH_SLOT` on
## purpose: that one is rewritten on EVERY heartbeat, so a smoke reading it
## back could never say whether it was looking at the save the `save_world`
## step made or at the one the next heartbeat made a frame later.
const SAVE_SCRATCH_SLOT := 3

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
## `input_contexts.json`, expanded, loaded once and reused -- same shape
## `operator_harness.gd::_press_guard` caches, via the same static loader.
var _input_contexts := {}
## Lane 3.D. The chest `storage_bind` planted in this process, and the verdict
## its last `storage_deposit`/`storage_withdraw` came back with.
var _storage_chest: Node3D = null
## Lane 5.B. The shrine this peer is standing at, stood up by `heart_bind`.
var _heart_shrine: Node3D = null
var _storage_last: Dictionary = {}
## Refusals the chest reported ASYNCHRONOUSLY -- a client's `submit()` only
## says "pending", and the host's `stale_revision` answer arrives later on
## `storage_container.gd`'s own `storage_refused` signal.
var _storage_refusals: Array = []
## Lane 3.B. The pickup `pickup_stand` planted in this process, and the verdict
## its last `pickup_take` came back with. A client's `submit()` only ever says
## "pending", so what actually happened is read afterwards off the world flag
## and the satchel, never off this verdict alone.
var _pickup_node: Node3D = null
## Lane 5.D: the bedroll this peer stood, so `sleep_press` presses the same one.
var _bedroll: Node3D = null
var _pickup_id: String = ""
var _pickup_item: String = ""
var _pickup_realm: String = "meadows"
## Refusals this peer's own pickup reported, off `item_cache_pickup.gd`'s own
## `claim_refused` -- which fires whether the host refused us synchronously
## (we ARE the host and lost) or a round trip later (we are a client).
var _pickup_refusals: Array = []
## What this peer's press actually found: "" (never pressed), "submitted" (the
## world had not yet recorded the find as taken, so `activated` reached
## `_on_picked_up` and an intent really went out), or "gone" (somebody else's
## claim had already committed and the delta had taken the prop down before this
## press landed). The second is not a failure -- it is
## the other legal shape of a lost race, and the one delta-driven removal
## produces most of the time. See `smoke_net_pickup_race.gd`.
var _pickup_press: String = ""

## Lane 6.E's farm race. Same shape as the pickup arms above and for the same
## reasons: the node is real `farm_plot.gd`, the press is the prompt's own
## `activated` signal, and the refusal is read off BOTH the transport (a
## client's, a round trip later) and this peer's own submit.
var _farm_node: Node3D = null
var _farm_index: int = -1
var _farm_realm: String = "meadows"
var _farm_crop: String = "berries"
var _farm_press: String = ""
var _farm_refusals: Array = []

## Lane 3.E. The verdict of this peer's last trade or drop arm, and every
## refusal sentence the ledger has sent it since the last one, so the smoke can
## assert that a loser was TOLD rather than silently dropped.
var _trade_last: Dictionary = {}
var _trade_refusals: Array = []
var _trade_wired: bool = false


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

	# `enet_port` is in the hello because a smoke has no other way to learn it:
	# the coordinator hands peer i `enet_base + i` (net_harness.gd::launch) from
	# a run-id-derived offset, and a `join` step needs the HOST's number, not
	# its own. Reported by the peer that owns it rather than recomputed.
	_send({"type": "hello", "peer": _peer_index, "role": _role, "pid": OS.get_process_id(),
		"enet_port": _enet_port,
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
		# Wave 2: a real `Session` exists, so this is the real registry --
		# `[]` only when this process has no session at all.
		"session_peers": _session_peer_ids()})


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
		"host":
			out = await _step_host(args)
		"join":
			out = await _step_join(args)
		"leave":
			out = await _step_leave(args)
		"expect_peers":
			out = await _step_expect_peers(args)
		"wait_flag":
			out = await _step_wait_flag(args)
		"wait_context":
			out = await _step_wait_context(args)
		"storage_place":
			out = await _step_storage_place(args)
		"storage_bind":
			out = await _step_storage_bind(args)
		"storage_grant":
			out = _step_storage_grant(args)
		"storage_transfer":
			out = _step_storage_transfer(args)
		"pickup_stand":
			out = await _step_pickup_stand(args)
		"pickup_take":
			out = _step_pickup_take(args)
		"farm_stand":
			out = await _step_farm_stand(args)
		"farm_pick":
			out = _step_farm_pick(args)
		"deploy_creature":
			out = await _step_deploy_creature(args)
		"build_place":
			out = await _step_build_place(args)
		"save_world":
			out = _step_save_world(args)
		"alpha_pin":
			out = _step_alpha_pin(args)
		"alpha_clear":
			out = _step_alpha_clear(args)
		"explore_at":
			out = await _step_explore_at(args)
		"trade_offer":
			out = _step_trade_offer(args)
		"trade_accept":
			out = _step_trade_accept(args)
		"trade_decline":
			out = _step_trade_decline(args)
		"item_drop":
			out = _step_item_drop(args)
		"item_pickup":
			out = _step_item_pickup(args)
		"engage_wild":
			out = await _step_engage_wild(args)
		"join_encounter":
			out = await _step_join_encounter(args)
		"teleport":
			out = await _step_teleport(args)
		"place_creature":
			out = await _step_place_creature(args)
		"strike":
			out = await _step_strike(args)
		"go_down":
			out = _step_go_down(args)
		"stand_by_downed":
			out = await _step_stand_by_downed(args)
		"trainer_battle":
			return await _step_trainer_battle(args)
		"win_trainer_battle":
			return await _step_win_trainer_battle(args)
		"sleep_stand":
			out = await _step_sleep_stand(args)
		"story_flag":
			out = await _step_story_flag(args)
		"sleep_press":
			out = _step_sleep_press(args)
		"heart_bind":
			out = _step_heart_bind(args)
		"heart_earn":
			out = _step_heart_earn(args)
		"heart_place":
			out = _step_heart_place(args)
		"heart_activate":
			out = _step_heart_activate(args)
		"present_publish":
			out = _step_present_publish(args)
		"present_damage":
			out = _step_present_damage(args)
		"enter_realm":
			out = await _step_enter_realm(args)
		"drop_link":
			out = await _step_drop_link(args)
		_:
			out = {"verdict": "ERROR", "detail": "unknown action '%s'" % action}
	out["frames_used"] = _physics_count - before
	return out


# --- lane 3.D: a shared chest -------------------------------------------------
#
# Four arms and one probe, standing in for the storage panel's two presses.
# Everything they touch is shipping code: `place_building` and `storage_txn` go
# through the real `Game.ledger`, the chest is a real `storage_container.gd`,
# and the transfer is its real `submit_deposit`/`submit_withdraw`. What the
# harness supplies is only what a panel supplies -- which row was pressed, and
# the revision the player was looking at when they pressed it.

## Plant a chest RECORD through the ledger. Host-side: the delta carries it to
## every peer, so the record lands at the SAME index everywhere, which is the
## address `storage_container.gd::container_key()` is derived from.
func _step_storage_place(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var transport: Node = game.get("ledger") as Node
	if transport == null:
		return {"verdict": "ERROR", "detail": "no Game.ledger to submit through"}
	var before_count := (game.get("placed_buildings") as Array).size()
	var verdict: Dictionary = transport.call("submit", {
		"kind": "place_building", "realm": str(args.get("realm", "meadows")),
		"id": "storage", "position": [0.0, 0.0, 0.0], "yaw_deg": 0.0, "paid": false,
	})
	# `pending` is NOT a refusal -- it is what a CLIENT's submit always returns
	# while the host has still to answer (`world_ledger.gd`'s verdict shape).
	# Treating it as failure made this arm usable only on the host, which is
	# exactly backwards for a smoke about a client writing world state, and it
	# is what made lane 6.A's disconnect smoke report "place_building refused:
	# pending" with an empty reason.
	var pending := bool(verdict.get("pending", false))
	if not bool(verdict.get("ok", false)) and not pending:
		return {"verdict": "FAIL", "detail": "place_building refused: %s / %s"
			% [str(verdict.get("code", "")), str(verdict.get("reason", ""))]}
	if pending:
		# Wait for the host's delta to land rather than reporting a record this
		# peer cannot yet see: the caller's next probe would otherwise race it.
		for _i in 600:
			await physics_frame
			if (game.get("placed_buildings") as Array).size() > before_count:
				break
	var buildings: Array = game.get("placed_buildings") as Array
	return {"verdict": "PASS", "detail": "chest record at index %d" % (buildings.size() - 1)}


## Stand a real chest node on that record, the way `build_placer.gd` does when
## it restores one: build it, stamp it with the record address, and hand it the
## record's saved contents (which is how a JOINER's chest arrives already
## holding what the host put in it).
func _step_storage_bind(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var index := int(args.get("index", -1))
	var realm := str(args.get("realm", "meadows"))
	if _storage_chest != null and is_instance_valid(_storage_chest):
		_storage_chest.queue_free()
		_storage_chest = null
	var chest: Node3D = STORAGE_CONTAINER.new()
	chest.name = "SmokeStorage"
	root.add_child(chest)
	chest.call("build_real")
	chest.set_meta(STORAGE_CONTAINER.PLACED_INDEX_META, index)
	chest.set_meta(STORAGE_CONTAINER.REALM_META, realm)
	var buildings: Array = game.get("placed_buildings") as Array
	if index >= 0 and index < buildings.size():
		var record: Dictionary = buildings[index] as Dictionary
		if record.has("state"):
			var state: RefCounted = chest.get("state")
			if state != null:
				state.call("load_data", record.get("state"))
	chest.connect("storage_refused", func(reason: String) -> void:
		_storage_refusals.append(reason))
	_storage_chest = chest
	_storage_last = {}
	_storage_refusals = []
	await physics_frame
	return {"verdict": "PASS", "detail": "bound %s" % str(chest.call("container_key"))}


## Put items in this peer's own satchel, so it has something to deposit.
func _step_storage_grant(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var satchel: RefCounted = game.get("inventory")
	if satchel == null:
		return {"verdict": "ERROR", "detail": "no Game.inventory"}
	var item := str(args.get("item", ""))
	var n := int(args.get("n", 0))
	var leftover := int(satchel.call("add", item, n))
	return {"verdict": "PASS", "detail": "granted %d %s (%d did not fit)" % [n - leftover, item, leftover]}


## One row press. `revision` is what the player was looking at; omit it (or -1)
## and the container reads the live one, which is what the panel does.
func _step_storage_transfer(args: Dictionary) -> Dictionary:
	if _storage_chest == null or not is_instance_valid(_storage_chest):
		return {"verdict": "ERROR", "detail": "no chest bound; run storage_bind first"}
	var direction := str(args.get("direction", "deposit"))
	var item := str(args.get("item", ""))
	var n := int(args.get("n", 0))
	var revision := int(args.get("revision", -1))
	_storage_refusals = []
	var verdict: Dictionary = _storage_chest.call(
		"submit_deposit" if direction == "deposit" else "submit_withdraw", item, n, revision)
	_storage_last = verdict
	return {"verdict": "PASS", "detail": "%s %d %s: ok=%s pending=%s code='%s'"
		% [direction, n, item, str(verdict.get("ok", false)), str(verdict.get("pending", false)),
			str(verdict.get("code", ""))]}


# --- lane 3.C: a shared building ----------------------------------------------
#
# Two arms and two probes. Everything they touch is shipping code: the placer
# is the world scene's own real `build_placer.gd`, the intent is its real
# `place_building`, and the save is the real `save_game.gd`. What the harness
# supplies is only what a player supplies -- the materials, the armed piece,
# and the press.

## Arm a piece and press Place, through the world's own real `build_placer.gd`.
##
## `_place()` is called directly rather than through an injected `build_place`
## press for one reason: a press only plants when the GHOST is green, and where
## a peer happens to spawn in the Meadows decides that. A smoke whose subject is
## "did a client's record reach the host" must not be able to go red because of
## the terrain under a spawn point. Everything downstream of the press -- the
## ticket, the intent, the verdict, the delta, the node -- is the shipping path
## untouched, and `_ghost_ok` is reported in the detail so a run can still say
## what the real press would have done.
func _step_build_place(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var placer: Node = null
	for node in get_nodes_in_group("build_placer"):
		placer = node
		break
	if placer == null:
		return {"verdict": "ERROR", "detail": "no build_placer in this peer's world"}
	var id := str(args.get("id", "floor"))
	# Free Build so the assertion is about the RECORD, not about whether this
	# peer's satchel happened to hold enough wood.
	game.set("free_build", true)
	game.set("pending_build", id)
	for i in int(args.get("arm_frames", 30)):
		await physics_frame
	var ghost_ok := bool(placer.get("_ghost_ok"))
	var before := (game.get("placed_buildings") as Array).size()
	placer.call("_place", game, id)
	for i in int(args.get("settle_frames", 6)):
		await physics_frame
	game.set("pending_build", "")
	var after := (game.get("placed_buildings") as Array).size()
	return {"verdict": "PASS", "detail": "pressed Place for '%s' (ghost_ok=%s); records %d -> %d"
		% [id, str(ghost_ok), before, after]}


## Write this peer's world to a save slot, the way an autosave does. On a host
## that is the world every other peer's records had to reach to be here at all;
## on a client D100 says it writes nothing of the world, which is why the smoke
## only ever asks the HOST for one.
func _step_save_world(_args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var save_system: Variant = game.get("save_system")
	if save_system == null:
		return {"verdict": "ERROR", "detail": "no Game.save_system"}
	if not bool(save_system.call("save", game, SAVE_SCRATCH_SLOT)):
		return {"verdict": "FAIL", "detail": "save to slot %d refused" % SAVE_SCRATCH_SLOT}
	var path := str(save_system.call("slot_path", SAVE_SCRATCH_SLOT))
	return {"verdict": "PASS", "detail": "saved slot %d to %s" % [SAVE_SCRATCH_SLOT, path]}


## `placed_buildings`, flattened to what a smoke can compare across two
## processes: the realm, the id and the position, in record order.
func _building_rows(raw: Variant) -> Array:
	var out: Array = []
	if not (raw is Array):
		return out
	for entry: Variant in (raw as Array):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var record := entry as Dictionary
		var position: Array = record.get("position", []) as Array
		out.append({
			"realm": str(record.get("realm", "meadows")),
			"id": str(record.get("id", "")),
			"position": [
				snappedf(float(position[0]), 0.01) if position.size() == 3 else 0.0,
				snappedf(float(position[1]), 0.01) if position.size() == 3 else 0.0,
				snappedf(float(position[2]), 0.01) if position.size() == 3 else 0.0,
			],
		})
	return out


# --- lane 3.E: item trading and dropped stacks --------------------------------
#
# Five arms and one probe, standing in for the Give row on the satchel's drop
# confirmation and the interact prompt on a stack lying on the ground.
# Everything they touch is shipping code: `trade_offer.gd`'s real offer /
# accept, the real `transfer_item` and `drop_item` intents through the real
# `Game.ledger`, and a real `dropped_item.gd` spawned by the real
# `dropped_item_spawner.gd` off the committed delta. What the harness supplies
# is only what a player supplies -- which row was pressed, and at whom.
#
# `storage_grant` is reused to stock a satchel; there is no second way to put
# items in a bag and adding one would be a second thing to keep true.

## Offer a stack to another peer. `to` is the other peer's real id, which the
## smoke reads out of the `session` probe rather than guessing (peer ids are
## large random 32-bit numbers, never indices).
func _step_trade_offer(args: Dictionary) -> Dictionary:
	var transport := _trade()
	if transport == null:
		return {"verdict": "ERROR", "detail": "no TradeOffer transport"}
	var answer: Dictionary = transport.call("offer", int(args.get("to", 0)),
		str(args.get("item", "")), int(args.get("n", 0)))
	_trade_last = answer
	return {"verdict": "PASS" if bool(answer.get("ok", false)) else "FAIL",
		"detail": "offer %d %s to %d: ok=%s reason='%s'"
			% [int(args.get("n", 0)), str(args.get("item", "")), int(args.get("to", 0)),
				str(answer.get("ok", false)), str(answer.get("reason", ""))]}


## Say yes to the offer this peer is holding.
func _step_trade_accept(_args: Dictionary) -> Dictionary:
	var transport := _trade()
	if transport == null:
		return {"verdict": "ERROR", "detail": "no TradeOffer transport"}
	var waiting: Dictionary = transport.call("incoming")
	if waiting.is_empty():
		return {"verdict": "FAIL", "detail": "no incoming offer to accept"}
	var answer: Dictionary = transport.call("accept")
	_trade_last = answer
	return {"verdict": "PASS" if bool(answer.get("ok", false)) else "FAIL",
		"detail": "accept %s: ok=%s reason='%s'"
			% [str(waiting.get("txn_id", "")), str(answer.get("ok", false)),
				str(answer.get("reason", ""))]}


func _step_trade_decline(_args: Dictionary) -> Dictionary:
	var transport := _trade()
	if transport == null:
		return {"verdict": "ERROR", "detail": "no TradeOffer transport"}
	var answer: Dictionary = transport.call("decline")
	_trade_last = answer
	return {"verdict": "PASS", "detail": "declined: reason='%s'" % str(answer.get("reason", ""))}


## Drop a stack on the ground, the same `drop_item` intent
## `tab_backpack.gd::_drop()` submits.
func _step_item_drop(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var transport: Node = game.get("ledger") as Node
	if transport == null:
		return {"verdict": "ERROR", "detail": "no Game.ledger to submit through"}
	var item := str(args.get("item", ""))
	var n := int(args.get("n", 0))
	var txn := str(args.get("txn_id", ""))
	if txn.is_empty():
		txn = "drop:%d:%d:%d" % [_local_peer_id_or_host(), Time.get_ticks_usec(), randi()]
	var verdict: Dictionary = transport.call("submit", {
		"kind": "drop_item", "realm": DROPPED_ITEM_SPAWNER.realm_of(self),
		"txn_id": txn, "item": item, "count": n,
		"position": args.get("position", [0.0, 0.0, 0.0]),
	})
	_trade_last = verdict
	if not bool(verdict.get("ok", false)) and not bool(verdict.get("pending", false)):
		return {"verdict": "FAIL", "detail": "drop refused: %s / %s"
			% [str(verdict.get("code", "")), str(verdict.get("reason", ""))]}
	return {"verdict": "PASS", "detail": "drop %d %s (txn %s): ok=%s pending=%s"
		% [n, item, txn, str(verdict.get("ok", false)), str(verdict.get("pending", false))]}


## Pick the nearest dropped stack up, through the real `dropped_item.gd`. `txn`
## picks a specific one when the smoke needs to be sure which.
func _step_item_pickup(args: Dictionary) -> Dictionary:
	var target: Node3D = null
	var want := str(args.get("txn", ""))
	for node in get_nodes_in_group(DROPPED_ITEM.GROUP):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if want.is_empty() or str(node.call("txn_id")) == want:
			target = node
			break
	if target == null:
		return {"verdict": "FAIL", "detail": "no dropped stack to pick up"}
	var verdict: Dictionary = target.call("pick_up")
	_trade_last = verdict
	if not bool(verdict.get("ok", false)) and not bool(verdict.get("pending", false)):
		return {"verdict": "FAIL", "detail": "pickup refused: %s / %s"
			% [str(verdict.get("code", "")), str(verdict.get("reason", ""))]}
	return {"verdict": "PASS", "detail": "picked up %s: ok=%s pending=%s"
		% [str(target.call("item_id")), str(verdict.get("ok", false)),
			str(verdict.get("pending", false))]}


## The offer transport, mounted on first ask and wired once to the ledger's
## refusal signal so a refusal this peer was sent is visible to the smoke.
func _trade() -> Node:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return null
	var transport: Node = TRADE_OFFER.attach(game)
	if transport != null and not _trade_wired:
		_trade_wired = true
		var ledger: Node = game.get("ledger") as Node
		if ledger != null:
			ledger.connect("intent_refused", func(kind: String, code: String, reason: String) -> void:
				_trade_refusals.append("%s/%s: %s" % [kind, code, reason]))
	return transport


func _local_peer_id_or_host() -> int:
	var sess := _session()
	return int(sess.call("local_peer_id")) if sess != null else 1


## `{id: count}` for every dropped stack this process is drawing. The net
## smoke's conservation check adds this to both satchels: an item on the ground
## still exists, and a drop that lost it would show up here as a shortfall
## rather than as a passing test.
func _dropped_counts() -> Dictionary:
	var out := {}
	for node in get_nodes_in_group(DROPPED_ITEM.GROUP):
		if not is_instance_valid(node):
			continue
		var n := int(node.call("count"))
		if n <= 0:
			continue
		var id := str(node.call("item_id"))
		out[id] = int(out.get(id, 0)) + n
	return out


## `{id: count}` for every stack an inventory holds -- addressed by item
## identity, never by slot number (CLAUDE.md).
func _storage_counts(inv: RefCounted) -> Dictionary:
	var out := {}
	if inv == null:
		return out
	for i in int(inv.call("slot_count")):
		var stack: Dictionary = inv.call("stack_at", i)
		if stack.is_empty():
			continue
		var id := str(stack.get("id", ""))
		out[id] = int(out.get(id, 0)) + int(stack.get("n", 0))
	return out


## The same map, read out of a `placed_buildings` record's `state` array --
## what the WORLD says the chest holds, as opposed to what the live node does.
func _storage_record_counts(game: Node, index: int) -> Dictionary:
	var out := {}
	var buildings: Array = game.get("placed_buildings") as Array
	if index < 0 or index >= buildings.size():
		return out
	var raw: Variant = (buildings[index] as Dictionary).get("state", [])
	if typeof(raw) != TYPE_ARRAY:
		return out
	for entry: Variant in (raw as Array):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var stack := entry as Dictionary
		var id := str(stack.get("id", ""))
		out[id] = int(out.get(id, 0)) + int(stack.get("n", 0))
	return out


# --- lane 5.D: sleep is a vote -------------------------------------------------
#
# Two arms and two probes. Nothing here simulates the vote: the bedroll is a
# real `player_bed.gd`, the tent over it is a real `camp_tent.gd` (CAMP-SHELTER-
# 0903 refuses a bedroll with no roof, and this smoke is not about that rule),
# and the press is the bedroll's own `Interactable.activated` -- the exact
# signal a controller press fires. From there it is shipping code all the way:
# `player_bed.gd::_on_rest` -> `night_rest.gd::rest()` -> the vote.


## Stand a bedroll with a tent over it, at this peer's own feet.
##
## At the PLAYER's position rather than at the origin: `camp_tent.gd::
## contains_point` is a real footprint test, and two nodes that merely share a
## coordinate the player is nowhere near would still satisfy it -- but a bedroll
## under the terrain is a worse thing to hand the rest path than one the player
## is standing on. Both are added to `placed_building` with the `building_id`
## meta a real placement would carry, because `_tent_overhead()` reads exactly
## those two things off whatever else is standing.
func _step_sleep_stand(_args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	if _bedroll != null and is_instance_valid(_bedroll):
		_bedroll.queue_free()
		_bedroll = null
	var player := _probe.call("player") as Node3D
	var at := player.global_position if player != null else Vector3.ZERO

	var tent: Node3D = CAMP_TENT.new()
	tent.name = "SmokeTent"
	root.add_child(tent)
	tent.global_position = at
	tent.call("build_real")
	tent.add_to_group("placed_building")
	tent.set_meta("building_id", "tent")

	var bed: Node3D = PLAYER_BED.new()
	bed.name = "SmokeBedroll"
	root.add_child(bed)
	bed.global_position = at
	bed.call("build_real")
	bed.add_to_group("placed_building")
	bed.set_meta("building_id", "bedroll")
	_bedroll = bed
	await physics_frame
	return {"verdict": "PASS", "detail": "bedroll + tent at (%.1f, %.1f, %.1f)" % [at.x, at.y, at.z]}


## Press it. The signal, not the private method, so a change that broke the
## wiring between the prompt and the rest would fail here rather than be routed
## around. A second press on the same bedroll is how a player withdraws a vote,
## and this arm sends whatever it is told to send.
func _step_sleep_press(_args: Dictionary) -> Dictionary:
	if _bedroll == null or not is_instance_valid(_bedroll):
		return {"verdict": "ERROR", "detail": "no bedroll standing; run sleep_stand first"}
	var prompt := _bedroll.get_node_or_null(^"Interactable")
	if prompt == null:
		return {"verdict": "ERROR", "detail": "the bedroll has no Interactable to press"}
	prompt.emit_signal("activated")
	return {"verdict": "PASS", "detail": "pressed the bedroll"}


# --- lane 3.B: one pickup, two hands ------------------------------------------
#
# Two arms and one probe. Everything they touch is shipping code: the prop is a
# real `item_cache_pickup.gd`, the press is its own `Interactable.activated`
# signal (the exact seam a controller press fires), and the claim goes through
# the real `Game.ledger`. What the harness supplies is only what a player
# supplies -- standing in front of it, and pressing.


## Stand a real cache pickup, at the same id on every peer, so both processes
## are pressing THE SAME find. No model path: the prop's geometry is not what
## this smoke is about, and `item_cache_pickup.gd` falls back to a plain box.
func _step_pickup_stand(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	if _pickup_node != null and is_instance_valid(_pickup_node):
		_pickup_node.queue_free()
		_pickup_node = null
	_pickup_id = str(args.get("id", "net_race_cache"))
	_pickup_item = str(args.get("item", "berries"))
	_pickup_realm = str(args.get("realm", "meadows"))
	var node: Node3D = ITEM_CACHE_PICKUP.new()
	node.name = "SmokePickup"
	root.add_child(node)
	node.call("setup", _pickup_item, "Take", "", 1.0, _pickup_id, _pickup_realm,
		int(args.get("count", 1)))
	_pickup_node = node
	_pickup_refusals = []
	_pickup_press = ""
	# BOTH refusal surfaces, because neither one alone sees both paths.
	#
	# A host that loses the race is refused synchronously inside `submit()`, and
	# the only thing that reports that is the prop's own `claim_refused`.
	#
	# A CLIENT hears `already_taken` a round trip later -- and by then the
	# winner's delta has usually already reached it and freed the prop, taking
	# that signal's connection with it. So the client's refusal is only
	# observable on the TRANSPORT, which is an autoload child and outlives any
	# prop. (The player still sees it either way: `ledger_rpc.gd::_rpc_verdict`
	# pushes the sentence to `Game` before it emits, and that is not a node
	# connection.) `_rpc_verdict` is addressed to the one peer whose intent it
	# was, so anything arriving on the transport here is ours.
	node.connect("claim_refused", _on_pickup_refused)
	var transport: Node = game.get("ledger") as Node
	if transport != null and not transport.is_connected("intent_refused", _on_intent_refused):
		transport.connect("intent_refused", _on_intent_refused)
	await physics_frame
	if not is_instance_valid(_pickup_node):
		# `setup()` frees the prop outright when the flag already says taken.
		return {"verdict": "PASS", "detail": "'%s' was already taken; nothing stands" % _pickup_id}
	return {"verdict": "PASS", "detail": "stood '%s' (%s)" % [_pickup_id, _pickup_item]}


## Press it. The signal, not the private method: `interactable.gd::activated`
## is what a real interact press emits, so a change that broke the wiring
## between the prompt and the claim would fail here rather than be routed
## around.
##
## `at_unix_ms` is what makes a two-peer race REPRODUCIBLE rather than a
## coin-flip on packet order. The coordinator talks to each peer over its own
## TCP control socket, one after the other and awaiting each verdict before it
## sends the next, so two "press now" messages are always a round trip apart --
## and a pickup is REMOVED by the winner's delta, so the second peer would
## routinely find nothing left to press and the smoke would assert nothing.
## Given a deadline this arm SCHEDULES the press and answers immediately, so
## both peers can be armed and then both press at the same instant off the
## wall clock they share (one machine, contract §2). Everything about the press
## itself is the shipping path.
func _step_pickup_take(args: Dictionary) -> Dictionary:
	if _pickup_node == null or not is_instance_valid(_pickup_node):
		return {"verdict": "ERROR", "detail": "no pickup standing; run pickup_stand first"}
	var at := float(args.get("at_unix_ms", 0.0))
	if at > 0.0:
		_press_pickup_at.call_deferred(at)
		return {"verdict": "PASS", "detail": "armed '%s' for %.0f" % [_pickup_id, at]}
	return _press_pickup()


## Hold until the shared instant, then press. Started detached (`call_deferred`)
## so the arming step can answer the coordinator straight away; it keeps running
## because each `await physics_frame` resumes it off the tree's own signal.
func _press_pickup_at(at_unix_ms: float) -> void:
	while Time.get_unix_time_from_system() * 1000.0 < at_unix_ms:
		await physics_frame
	_press_pickup()


func _press_pickup() -> Dictionary:
	# "Already gone" is read off the WORLD, not off the node. `_deactivate()`
	# calls `queue_free()`, which is deferred to the end of the frame, so a prop
	# taken down by a delta that landed EARLIER IN THIS SAME FRAME still passes
	# `is_instance_valid` -- the press reaches it and its own `_taken` guard
	# swallows it silently, and a harness that trusted the node would report a
	# submission that never happened. `was_taken()` is the prop's own public
	# static over the same flag the delta carries, so this asks exactly the
	# question `_on_picked_up` is about to ask itself.
	var game := root.get_node_or_null(^"Game")
	var already := game != null and bool(ITEM_CACHE_PICKUP.was_taken(
		game, _pickup_item, _pickup_id, _pickup_realm))
	if already or _pickup_node == null or not is_instance_valid(_pickup_node):
		# Not an error: somebody else's claim already committed and the delta
		# took this prop down, which is exactly what a lost race looks like.
		_pickup_press = "gone"
		return {"verdict": "PASS", "detail": "'%s' was already gone when the press landed" % _pickup_id}
	var prompt := _pickup_node.get_node_or_null(^"Interactable")
	if prompt == null:
		return {"verdict": "ERROR", "detail": "the pickup has no Interactable to press"}
	prompt.emit_signal("activated")
	_pickup_press = "submitted"
	return {"verdict": "PASS", "detail": "pressed '%s'" % _pickup_id}


## This peer's own claim was refused, reported by the prop itself (the host
## path). See `pickup_stand`.
func _on_pickup_refused(code: String, reason: String) -> void:
	_pickup_refusals.append({"code": code, "reason": reason})


# --- lane 6.E: one ripe berry bed, two hands ---------------------------------


## Stand a real `farm_plot.gd` at the same index on every peer, with a crop
## already ripe on it, so both processes are pressing THE SAME bed.
##
## SETUP, and it is worth naming: the bed's `{state, ripe_on_day}` record is
## written here with `Game.set_farm_plot()` -- the direct write lane 6.E's audit
## records as the one farm mutation with NO ledger op to carry it
## (`ralph/reports/MP-6E-CLOUDREACH-0906/REPORT.md`). That is the harness
## planting a crop, not the feature under test. What the smoke measures is the
## PICK, which is a `harvest` intent, and a failure there is the feature.
##
## A high index deliberately: `data/config/farm.json` numbers the farmhouse's
## real beds from 0, and this must contest its own bed rather than one the world
## already stood.
func _step_farm_stand(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	if _farm_node != null and is_instance_valid(_farm_node):
		_farm_node.queue_free()
		_farm_node = null
	_farm_index = int(args.get("index", 90))
	_farm_realm = str(args.get("realm", "meadows"))
	_farm_crop = str(args.get("crop_item", "berries"))
	var config := {
		"grow_days": 1,
		"yield": int(args.get("yield", 3)),
		"seed_item": "berry_seeds",
		"crop_item": _farm_crop,
	}
	var node: Node3D = FARM_PLOT.new()
	node.name = "SmokeFarmPlot"
	root.add_child(node)
	node.call("setup", _farm_index, config, _farm_realm)
	_farm_node = node
	_farm_press = ""
	_farm_refusals = []
	node.connect("harvest_refused", _on_farm_refused)
	# Ripe as of today, on every peer, so both name the same crop cycle: the
	# claim id is `farm:<realm>:<index>#<ripe_on_day>` and a bed whose ripening
	# day differed between peers would be two different crops, which would prove
	# nothing about a race.
	game.call("set_farm_plot", _farm_index,
		{"state": FARM_LOGIC.SOWN, "ripe_on_day": int(game.get("day"))})
	var transport: Node = game.get("ledger") as Node
	if transport != null and not transport.is_connected("intent_refused", _on_intent_refused):
		transport.connect("intent_refused", _on_intent_refused)
	await physics_frame
	return {"verdict": "PASS", "detail": "bed %d is ripe ('%s')"
		% [_farm_index, str(node.call("claim_flag"))]}


## Pick it. The prompt's own `activated` signal, and -- like `pickup_take` --
## `at_unix_ms` ARMS the press and answers immediately so both peers can press
## at one shared instant with both intents in flight before either delta lands.
func _step_farm_pick(args: Dictionary) -> Dictionary:
	if _farm_node == null or not is_instance_valid(_farm_node):
		return {"verdict": "ERROR", "detail": "no farm bed standing; run farm_stand first"}
	var at := float(args.get("at_unix_ms", 0.0))
	if at > 0.0:
		_press_farm_at.call_deferred(at)
		return {"verdict": "PASS", "detail": "armed bed %d for %.0f" % [_farm_index, at]}
	return _press_farm()


func _press_farm_at(at_unix_ms: float) -> void:
	while Time.get_unix_time_from_system() * 1000.0 < at_unix_ms:
		await physics_frame
	_press_farm()


func _press_farm() -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null or _farm_node == null or not is_instance_valid(_farm_node):
		_farm_press = "gone"
		return {"verdict": "PASS", "detail": "the bed was gone when the press landed"}
	# "Already picked" is read off the WORLD FLAG, not off the node: a bed whose
	# claim committed earlier in this same frame is still a perfectly valid
	# node, and a harness that trusted the node would report a submission that
	# never happened.
	if _farm_claimed(game):
		_farm_press = "gone"
		return {"verdict": "PASS", "detail": "bed %d was already picked" % _farm_index}
	var prompt := _farm_node.get_node_or_null(^"Interactable")
	if prompt == null:
		return {"verdict": "ERROR", "detail": "the bed has no Interactable to press"}
	prompt.emit_signal("activated")
	_farm_press = "submitted"
	return {"verdict": "PASS", "detail": "picked bed %d" % _farm_index}


## This peer's own pick was refused, reported by the bed itself (the host path).
func _on_farm_refused(code: String, reason: String) -> void:
	_farm_refusals.append({"code": code, "reason": reason})


## Does THIS peer's world say some claim on this bed has committed? Asked by
## prefix, not by exact id, so the answer does not depend on the two peers
## agreeing about which day the crop ripened.
func _farm_claimed(game: Node) -> bool:
	var world: Variant = game.get("world")
	var flags: Variant = (world as RefCounted).get("flags") if world != null else null
	if flags == null:
		return false
	var prefix := "farm:%s:%d#" % [_farm_realm, _farm_index]
	for raw: Variant in ((flags as RefCounted).call("all_set") as Array):
		if str(raw).begins_with(prefix):
			return true
	return false


## The same refusal, reported by the transport (the client path, and the only
## one that survives the prop being freed by the winner's delta).
func _on_intent_refused(kind: String, code: String, reason: String, _detail: Dictionary) -> void:
	if kind == "harvest":
		# Lane 6.E. A CLIENT's refusal arrives here a round trip later; a host's
		# arrives on the bed's own `harvest_refused`. Both surfaces, because
		# neither one alone sees both paths -- the same pair `pickup_stand`
		# already connects, and for the same measured reason.
		_farm_refusals.append({"code": code, "reason": reason})
		return
	if kind != "claim_pickup":
		return
	_pickup_refusals.append({"code": code, "reason": reason})


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


## Adapted from `operator_harness.gd::_inject`, with one deliberate
## divergence found and measured while fixing item 3 of the Opus review:
## that file's own ordering puts one IDLE frame between the press and the
## first physics frame, because every MENU it drives polls
## `Input.is_action_just_pressed` from `_process`. Measured live here that the
## same ordering starves a `_physics_process`-polled action instead:
## `Input.is_action_just_pressed("jump")` read true immediately after
## `_press_edge`, then **false** after a single `await process_frame` -- the
## flag is scoped to the frame the event was parsed in and had already
## expired by the time `player_controller.gd::_try_jump()`'s own
## `_physics_process` callback ran, so `jump` silently never fired
## (`_jump_buffered_for` never got zeroed, `try_spend_jump()` never even
## reached). Menu focus is not yet in this file's scope (no menu step exists
## in Wave 0's vocabulary) and every gameplay action `peer_runner.gd` drives
## (`jump`, movement, `interact`) is read from `_physics_process`, so the
## physics frame goes first here; if a menu-focused action needs this file
## later, gate the idle-frame placement on the control rather than reverting
## this wholesale.
func _inject(action: String, frames: int) -> Dictionary:
	var down := _press_edge(action, true)
	if not bool(down.get("ok", false)):
		return down
	for i in maxi(1, frames):
		await physics_frame
	var up := _press_edge(action, false)
	await process_frame
	await physics_frame
	return {"ok": bool(up.get("ok", false)), "why": str(up.get("why", ""))}


## CL-H13, ported: `GATE_F_HARNESS._resolve_press`/`_load_input_contexts` are
## both `static` and read only `data/config/input_contexts.json` plus the live
## InputMap, so reusing them by preload is the same call as
## `_physical_binding`'s -- not a second copy of the collision rule that
## `input_contexts.json`'s own header exists to keep singular. Resolved
## against the LIVE `input_context` every call, not cached: a fight can end
## mid-sequence and change what a control means (see that file's own comment
## on the same guard).
func _press_guard(action: String) -> Dictionary:
	if _input_contexts.is_empty():
		_input_contexts = GATE_F_HARNESS._load_input_contexts()
	var context := str(_probe.call("input_context"))
	return GATE_F_HARNESS._resolve_press(action, context, "", _input_contexts)


func _step_press(args: Dictionary) -> Dictionary:
	var action := str(args.get("action", ""))
	var times := int(args.get("times", 1))
	var gap := int(args.get("gap_frames", 18))
	for i in maxi(1, times):
		var guard := _press_guard(action)
		if not bool(guard.get("ok", true)):
			return {"verdict": "ERROR", "detail": "inert press, measuring nothing: %s"
				% str(guard.get("why", ""))}
		var r := await _inject(action, 1)
		if not bool(r.get("ok", false)):
			return {"verdict": "ERROR", "detail": "press '%s' could not be injected: %s"
				% [action, str(r.get("why", ""))]}
		if i < times:
			for g in gap:
				await physics_frame
	var confirm: Dictionary = args.get("confirm", {}) as Dictionary
	if not confirm.is_empty():
		# Item 3 (review): a transient effect (a jump's airtime is ~14
		# physics frames measured live, ~0.23s) cannot be caught by the
		# COORDINATOR polling `probe` once per network round trip -- each
		# round trip costs real wall clock the peer's own physics does not
		# wait for, so by the time a second or third probe comes back the
		# jump has already landed. Watched HERE instead, locally, one
		# physics_frame per iteration with no round trip, so the window is
		# real physics frames, not however long TCP + JSON happened to take.
		var result := await _confirm_after_press(confirm)
		if not bool(result.get("ok", false)):
			return {"verdict": "FAIL", "detail": str(result.get("detail", ""))}
		return {"verdict": "PASS", "detail": "pressed '%s' x%d; %s" % [action, times, str(result.get("detail", ""))]}
	return {"verdict": "PASS", "detail": "pressed '%s' x%d" % [action, times]}


## `confirm: {check, within_frames}` on a `press` step -- a same-process,
## frame-by-frame watch for an effect the press is claimed to cause, run right
## here rather than via repeated `probe` calls (see `_step_press`'s own
## comment on why that would miss it). Extensible: `check` is a small `match`,
## not a special case wired only for jump.
func _confirm_after_press(confirm: Dictionary) -> Dictionary:
	var check := str(confirm.get("check", ""))
	var within := maxi(1, int(confirm.get("within_frames", 40)))
	match check:
		"left_floor":
			var player := _probe.call("player") as Node3D
			if player == null or not player.has_method("is_on_floor"):
				return {"ok": false, "detail": "no live player (or no is_on_floor) to watch"}
			for i in within:
				await physics_frame
				if not bool(player.call("is_on_floor")):
					return {"ok": true, "detail": "left the floor %d physics frames after the press" % (i + 1)}
			return {"ok": false, "detail": "never left the floor within %d physics frames of the press" % within}
		_:
			return {"ok": false, "detail": "unknown confirm check '%s'" % check}


func _step_hold(args: Dictionary) -> Dictionary:
	var action := str(args.get("action", ""))
	var frames := int(args.get("frames", 0))
	var guard := _press_guard(action)
	if not bool(guard.get("ok", true)):
		return {"verdict": "ERROR", "detail": "inert hold, measuring nothing: %s" % str(guard.get("why", ""))}
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


# --- net steps (contract §4, made real by Wave 2 lane 2.A) --------------------

## The live `/root/Game/Session`, or null in a process whose Game never mounted
## one (the `loopback` scene still has the autoload, so in practice this is only
## null if the autoload itself failed).
func _session() -> Node:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return null
	return game.get("session") as Node


## Lane 6.A's measurement seam, the same field `tools/net/_probe_s2_shell.gd`
## reads so the numbers are comparable with spike S2's. -1 where /proc is not
## readable (not Linux), which a caller reports rather than treats as zero.
func _read_status_field_kb(field: String) -> int:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	if f == null:
		return -1
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with(field):
			return int(line.replace(field, "").replace("kB", "").strip_edges())
	return -1


func _session_peer_ids() -> Array:
	var sess := _session()
	if sess == null or not bool(sess.call("is_active")):
		return []
	var ids: Array = []
	for row: Variant in (sess.call("peers") as Array):
		ids.append(int((row as Dictionary).get("peer_id", 0)))
	return ids


func _step_host(args: Dictionary) -> Dictionary:
	var sess := _session()
	if sess == null:
		return {"verdict": "ERROR", "detail": "no Session mounted on /root/Game"}
	var port := int(args.get("port", _enet_port))
	var cap := int(args.get("max_peers", 0))
	var ok := bool(sess.call("host", port, cap))
	if not ok:
		return {"verdict": "FAIL", "detail": "Session.host(%d) refused (port already bound?)" % port}
	# Contract §4: `host` passes when Session.host() returned OK AND
	# multiplayer.is_server(). Both, not either -- a bound socket with no
	# server-side MultiplayerAPI would satisfy the first and nothing else.
	if not get_multiplayer().is_server():
		return {"verdict": "FAIL", "detail": "Session.host(%d) bound but multiplayer.is_server() is false" % port}
	return {"verdict": "PASS", "detail": "hosting udp/%d as peer %d" % [port, get_multiplayer().get_unique_id()]}


func _step_join(args: Dictionary) -> Dictionary:
	var sess := _session()
	if sess == null:
		return {"verdict": "ERROR", "detail": "no Session mounted on /root/Game"}
	var ip := str(args.get("host", "127.0.0.1"))
	var port := int(args.get("port", 0))
	if port <= 0:
		return {"verdict": "ERROR", "detail": "join step needs the host's enet port in args.port"}
	var summary: Dictionary = (args.get("character", {}) as Dictionary)
	if not bool(sess.call("join", ip, port, summary)):
		return {"verdict": "FAIL", "detail": "Session.join(%s, %d) could not open a client socket" % [ip, port]}
	# Contract §4: `join` passes when the handshake COMPLETED -- the world
	# snapshot applied, not merely a socket connected. `Session` exposes that as
	# `snapshot_ready()`, polled here a frame at a time (nothing in session.gd
	# is a coroutine; see that file's `_box` comment).
	var budget := int(args.get("budget_frames", NET_STEP_BUDGET_FRAMES))
	for i in maxi(1, budget):
		if bool(sess.call("handshake_failed")):
			return {"verdict": "FAIL", "detail": "Session.join(%s, %d) refused after %d frames" % [ip, port, i]}
		if bool(sess.call("is_active")) and bool(sess.call("snapshot_ready")):
			return {"verdict": "PASS",
				"detail": "joined %s:%d as peer %d after %d frames; snapshot applied; %d peer(s) in registry"
				% [ip, port, get_multiplayer().get_unique_id(), i, int(sess.call("peer_count"))]}
		await physics_frame
	return {"verdict": "FAIL", "detail": "Session.join(%s, %d) never applied a snapshot within %d frames"
		% [ip, port, budget]}


func _step_leave(args: Dictionary) -> Dictionary:
	var sess := _session()
	if sess == null:
		return {"verdict": "ERROR", "detail": "no Session mounted on /root/Game"}
	if not bool(sess.call("is_active")):
		return {"verdict": "FAIL", "detail": "no active session to leave"}
	var was_host := bool(sess.call("is_host"))
	sess.call("leave", str(args.get("reason", "left")))
	# A leaving HOST holds its socket open for CLOSE_FLUSH_FRAMES so the
	# reliable `session_ended` broadcast lands, so "left" is `is_active()` going
	# false, not the call returning. The peer keeps running for probes
	# afterwards (contract §4) -- this step must never quit the process.
	var budget := int(args.get("budget_frames", 600))
	for i in maxi(1, budget):
		if not bool(sess.call("is_active")):
			return {"verdict": "PASS", "detail": "%s left cleanly after %d frames"
				% ["host" if was_host else "client", i]}
		await physics_frame
	return {"verdict": "FAIL", "detail": "%s session was still active %d frames after leave()"
		% ["host" if was_host else "client", budget]}


## Wave 6 lane 6.A, directive rule 16. Cross a realm boundary WITHOUT leaving
## the session, through the one door the game itself uses --
## `Game.enter_realm()`. Deliberately not `change_scene_to_file()`: a smoke
## that swaps the scene by hand proves the scene loads and nothing about the
## announce/despawn/shell sequence that is the whole lane.
##
## `enter_realm()` calls `get_tree().change_scene_to_file()`, which is
## DEFERRED to the end of the frame, so the step polls for the new world root
## by name rather than returning on the call. It also updates `_scene_name`,
## so a later `boot` step with no explicit scene re-boots the right one.
func _step_enter_realm(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var realm := str(args.get("realm", ""))
	if realm.is_empty():
		return {"verdict": "ERROR", "detail": "enter_realm needs args.realm"}
	var was := str(game.get("current_realm"))
	if not bool(game.call("enter_realm", realm, str(args.get("entry", "")))):
		return {"verdict": "FAIL",
			"detail": "Game.enter_realm('%s') refused from '%s' (can_enter=%s)"
				% [realm, was, str(game.call("can_enter_realm", realm))]}
	var wanted := str(REALM_ROOT_NAMES.get(realm, ""))
	var budget := int(args.get("budget_frames", 6000))
	for i in maxi(1, budget):
		await physics_frame
		if str(game.get("current_realm")) != realm:
			continue
		if wanted.is_empty():
			break
		var world := root.get_node_or_null(NodePath(wanted))
		# `current_scene` and not merely "a node of that name": the host also
		# holds SHELLS at /root under their authored names, and a step that
		# accepted one of those would pass without the local player having
		# gone anywhere at all.
		if world != null and world == current_scene:
			_scene_name = str(REALM_SCENE_NAMES.get(realm, _scene_name))
			# Settle, so the arriving world has finished its procedural build
			# before anything is probed against it.
			for j in int(args.get("settle_frames", DEFAULT_SETTLE_FRAMES)):
				await physics_frame
			return {"verdict": "PASS",
				"detail": "crossed '%s' -> '%s' after %d frames; current scene is /root/%s"
					% [was, realm, i, wanted]}
	return {"verdict": "FAIL", "detail": "enter_realm('%s') never stood /root/%s up as the current scene within %d frames"
		% [realm, wanted, budget]}


## Wave 6 lane 6.A. Vanish, the way a lost connection does -- NOT the way
## `leave` does.
##
## `leave` is an orderly departure: it saves, it tells everybody, it waits for
## the flush. Deliverable 5 is about the other thing, the case that sank D97's
## first design: a peer whose link simply stops while it is mid-fight in a
## realm nobody else is standing in. So this closes the transport out from
## under the session without going through `Session.leave()` at all, and the
## host learns about it exactly as it would learn about a pulled cable --
## through `multiplayer.peer_disconnected`.
##
## The PROCESS deliberately stays alive. The harness treats a peer that exits
## unexpectedly as a fatal run fault (`net_harness.gd::_check_liveness`), and
## more usefully, a live process can still be probed afterwards to prove it
## really did lose its session rather than merely stop talking.
func _step_drop_link(args: Dictionary) -> Dictionary:
	var api := get_multiplayer()
	var peer: MultiplayerPeer = api.multiplayer_peer if api != null else null
	if peer == null or peer is OfflineMultiplayerPeer:
		return {"verdict": "FAIL", "detail": "no live multiplayer peer to drop"}
	# `close()` before detaching: ENet sends the disconnect immediately, so the
	# host does not have to sit out its own connection timeout before
	# `peer_disconnected` fires and the shell reconcile runs.
	peer.close()
	api.multiplayer_peer = null
	for i in maxi(0, int(args.get("settle_frames", 30))):
		await physics_frame
	return {"verdict": "PASS", "detail": "transport closed without a Session.leave()"}


func _step_expect_peers(args: Dictionary) -> Dictionary:
	var want := int(args.get("count", -1))
	if want < 0:
		return {"verdict": "ERROR", "detail": "expect_peers needs args.count"}
	var budget := int(args.get("budget_frames", NET_STEP_BUDGET_FRAMES))
	var have := -1
	for i in maxi(1, budget):
		var sess := _session()
		have = int(sess.call("peer_count")) if sess != null else -1
		if have == want:
			return {"verdict": "PASS", "detail": "registry reports %d peer(s) after %d frames" % [have, i]}
		await physics_frame
	return {"verdict": "FAIL", "detail": "registry reports %d peer(s), wanted %d" % [have, want]}


## Contract §4's `wait_flag`: a world or player flag becomes set within budget.
## `scope` picks the store -- "any" (the merged view every gameplay reader
## already uses), "world" or "player".
## Stage B lane 4.B. Put this peer's own creature out, through the one door
## the game itself uses -- `encounter_director.gd`. Deliberately NOT a direct
## `_spawn_ally_body` poke: a smoke that reaches past the public API proves
## the private one works and nothing else.
##
## `summon_active_creature()` first, because that is the real recall path and
## it is what a peer with a party does. It refuses when the party is empty
## (which is every peer in the opening beat, before the starter is chosen), so
## `adopt_starter()` is the fallback -- the same call the sandbox's own
## `default_starter` makes.
func _step_deploy_creature(args: Dictionary) -> Dictionary:
	var director := _encounter_director()
	if director == null:
		return {"verdict": "ERROR", "detail": "no EncounterDirector in this scene"}
	if director.call("ally_body") != null:
		return {"verdict": "PASS", "detail": "a creature was already out"}
	# The outcome is read off `ally_body()` rather than off either call's
	# return value, deliberately: both are coroutines, and a coroutine reached
	# through `Object.call()` hands back whatever it had at its first `await`,
	# not its eventual result. The body standing in the world is the honest
	# answer and it is the one the game itself acts on.
	await director.call("summon_active_creature")
	var species := str(args.get("species", "terrapup"))
	if director.call("ally_body") == null:
		await director.call("adopt_starter", species, str(args.get("nickname", "")))
	for i in maxi(0, int(args.get("settle", 30))):
		await physics_frame
	var body: Variant = director.call("ally_body")
	if body == null or not is_instance_valid(body):
		return {"verdict": "FAIL",
			"detail": "neither summon_active_creature() nor adopt_starter('%s') left a body standing" % species}
	return {"verdict": "PASS", "detail": "deployed %s" % str((body as Node).name)}


# --- lane 4.C: one wild, two players ------------------------------------------
#
# Four arms and one probe. Everything they touch is shipping code: the fight is
# started through the director's own `interaction_activate()` (the press the
# player makes), the join is `join_encounter()`, and a strike is
# `submit_encounter_intent()` -- the one door `combat_manager.gd` itself
# submits through. What the harness supplies is only what a controller supplies:
# where the creature stands and which way the swing faced.

## Walk to the nearest live wild and press the interact button on it.
##
## The teleport is the same one `tests/smoke_combat_camera.gd` uses to stand a
## trainer beside a creature; the ENGAGE itself is the production press, so a
## fight that would not start for a player does not start here either.
func _step_engage_wild(args: Dictionary) -> Dictionary:
	var director := _encounter_director()
	if director == null:
		return {"verdict": "ERROR", "detail": "no EncounterDirector in this scene"}
	var wild: Variant = director.call("nearest_live_wild")
	if wild == null:
		return {"verdict": "FAIL", "detail": "no live wild creature to engage"}
	var player := _probe.call("player") as Node3D
	if player == null:
		return {"verdict": "ERROR", "detail": "no live player"}
	var body: Node3D = wild
	player.global_position = body.global_position + Vector3(2.5, 0.0, 0.0)
	player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame
	director.call("interaction_activate")
	for i in maxi(0, int(args.get("settle", 30))):
		await physics_frame
	var manager := _combat_manager()
	if manager == null or not bool(manager.call("is_fighting")):
		return {"verdict": "FAIL", "detail": "the engage press did not start a fight"}
	var id := str(manager.call("encounter_id"))
	if id.is_empty():
		return {"verdict": "FAIL",
			"detail": "a fight started but it is not bound to an encounter record"}
	return {"verdict": "PASS", "detail": "engaged %s as encounter %s"
		% [str(body.get("species_id")), id]}


## Stand the trainer at a point. The travel itself, not a game action.
##
## A joining player walks to the fight; a headless harness cannot, and must not
## pretend to -- `tests/smoke_aggression.gd`'s own header documents a scripted
## walk dying against a Terrain3D snag, and a smoke that fails there is
## reporting on terrain rather than on what it is testing. Same teleport
## `tests/smoke_combat_camera.gd` uses to stand a trainer beside a creature.
func _step_teleport(args: Dictionary) -> Dictionary:
	var player := _probe.call("player") as Node3D
	if player == null:
		return {"verdict": "ERROR", "detail": "no live player"}
	var at: Array = args.get("at", []) as Array
	if at.size() != 3:
		return {"verdict": "ERROR", "detail": "teleport needs args.at = [x, y, z]"}
	player.global_position = Vector3(float(at[0]), float(at[1]), float(at[2]))
	player.velocity = Vector3.ZERO
	for i in maxi(0, int(args.get("settle", 30))):
		await physics_frame
	var p: Vector3 = player.global_position
	return {"verdict": "PASS", "detail": "trainer stands at (%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]}


## Protocol §6: join a fight already running, by id.
func _step_join_encounter(args: Dictionary) -> Dictionary:
	var director := _encounter_director()
	if director == null:
		return {"verdict": "ERROR", "detail": "no EncounterDirector in this scene"}
	var id := str(args.get("encounter_id", ""))
	if id.is_empty():
		return {"verdict": "ERROR", "detail": "join_encounter needs args.encounter_id"}
	if not bool(director.call("join_encounter", id)):
		return {"verdict": "FAIL", "detail": "join_encounter('%s') refused locally" % id}
	for i in maxi(0, int(args.get("settle", 60))):
		await physics_frame
	var manager := _combat_manager()
	if manager == null or not bool(manager.call("is_fighting")):
		return {"verdict": "FAIL", "detail": "the join did not put this peer in a fight"}
	# The stand-in this peer is fighting beside is reported, never asserted on:
	# until wild replication lands (4.B's H1) a joiner's opponent BODY is its own
	# local simulation, and everything that decides an outcome comes off the
	# host's record instead. Printing it is how a reader of a failed run can see
	# whether the two processes picked the same creature.
	var body: Variant = manager.call("enemy_body")
	var species := "?"
	var where := Vector3.ZERO
	if body != null and is_instance_valid(body):
		species = str((body as Node3D).get("species_id"))
		where = (body as Node3D).global_position
	return {"verdict": "PASS", "detail": "joined %s beside a local '%s' at (%.1f, %.1f)"
		% [id, species, where.x, where.z]}


## Stand this peer's OWN deployed creature somewhere. A peer owns its creature's
## transform (4.B) and replicates it, so this is a legal thing for a peer to do
## and the host learns about it exactly the way it learns about a player walking.
func _step_place_creature(args: Dictionary) -> Dictionary:
	var director := _encounter_director()
	if director == null:
		return {"verdict": "ERROR", "detail": "no EncounterDirector in this scene"}
	var body: Variant = director.call("ally_body")
	if body == null or not is_instance_valid(body):
		return {"verdict": "FAIL", "detail": "this peer has no creature out to place"}
	var at: Array = args.get("at", []) as Array
	if at.size() != 3:
		return {"verdict": "ERROR", "detail": "place_creature needs args.at = [x, y, z]"}
	var target := Vector3(float(at[0]), float(at[1]), float(at[2]))
	var node: Node3D = body
	# `place_on_ground` asks the world for the height rather than raycasting
	# (D09), which is what stops the body from being dropped a metre or two into
	# the air over sloping ground and then SLIDING while it settles -- measured
	# at up to 2 m of drift in a 20-frame settle, which is enough to walk a
	# deliberately-aimed swing out of its own cone.
	if node.has_method("place_on_ground"):
		node.call("place_on_ground", target)
	else:
		node.global_position = target
	if node.has_method("face_towards") and args.has("face"):
		var f: Array = args.get("face", []) as Array
		if f.size() == 3:
			node.call("face_towards", Vector3(float(f[0]), float(f[1]), float(f[2])))
	# Long enough for `remote_creature.gd`'s 0.08 s half-life to converge on
	# every other peer, and for the body to settle onto the ground it was
	# dropped over.
	for i in maxi(0, int(args.get("settle", 60))):
		await physics_frame
	return {"verdict": "PASS", "detail": "creature stands at (%.2f, %.2f, %.2f)"
		% [node.global_position.x, node.global_position.y, node.global_position.z]}


## Submit a `strike_intent` through the production door, with a chosen facing.
##
## The facing is the point of the arm. A button press always faces the
## opponent (`combat_manager.gd::_start_action()` calls `face_towards` on it),
## so a swing aimed at a TEAMMATE cannot be produced by pressing a button --
## which is exactly why §5's `friendly_target` refusal is a host-side rule and
## not a UI one, and why the harness has to be able to say what a modified
## client could say.
func _step_strike(args: Dictionary) -> Dictionary:
	var director := _encounter_director()
	var manager := _combat_manager()
	if director == null or manager == null:
		return {"verdict": "ERROR", "detail": "no EncounterDirector/CombatManager"}
	var id := str(manager.call("encounter_id"))
	if id.is_empty():
		return {"verdict": "FAIL", "detail": "this peer is not in a networked fight"}
	var body: Variant = director.call("ally_body")
	if body == null or not is_instance_valid(body):
		return {"verdict": "FAIL", "detail": "this peer has no creature out"}
	var creature: Variant = manager.call("active_creature")
	if creature == null:
		return {"verdict": "FAIL", "detail": "this peer has no active creature"}
	var origin: Vector3 = (body as Node3D).call("centre")
	var toward: Array = args.get("facing", []) as Array
	if toward.size() != 3:
		return {"verdict": "ERROR", "detail": "strike needs args.facing = [x, y, z]"}
	var facing := Vector3(float(toward[0]), float(toward[1]), float(toward[2]))
	facing.y = 0.0
	if facing.length_squared() <= 0.000001:
		return {"verdict": "ERROR", "detail": "strike facing is zero-length"}
	facing = facing.normalized()
	var slot := str(args.get("slot", "quick"))
	var verdict: Dictionary = director.call("submit_encounter_intent", {
		"kind": "strike_intent",
		"encounter_id": id,
		"slot": slot,
		"move_id": str((creature as RefCounted).get(
			"move_quick" if slot == "quick" else "move_charged")),
		"origin": [origin.x, origin.y, origin.z],
		"facing": [facing.x, facing.y, facing.z],
	})
	for i in maxi(0, int(args.get("settle", 45))):
		await physics_frame
	return {"verdict": "PASS", "detail": "submitted %s strike (local verdict ok=%s code=%s)"
		% [slot, str(verdict.get("ok", false)), str(verdict.get("code", ""))]}


func _combat_manager() -> Node:
	if current_scene == null:
		return null
	return current_scene.get_node_or_null(^"CombatManager")


func _encounter_director() -> Node:
	if current_scene == null:
		return null
	return current_scene.get_node_or_null(^"EncounterDirector")


# --- lane 5.B: a Heart is placed once, and worn by whoever wants it -----------
#
# Four arms and one probe. Everything they touch is shipping code: the shrine is
# a real `realm_heart_shrine.gd`, earning submits the same `set_world_flag`
# intent `alpha_pins.gd::clear_alpha()` submits, placing is the shrine's own
# `submit_place()` -- the exact call the interact prompt makes -- and activating
# is `RealmHeartState.activate()`, the call the prompt makes for its second
# press. What the harness supplies is only what a player supplies: which shrine
# they walked up to, and which press they made.

## Stand a real shrine in this process, the way `playground_world.gd` stands the
## authored one: build it, name it, and hand it the Heart it belongs to. Every
## peer binds its own, because the shrine is a scene node and scene nodes are
## not replicated -- what is shared is the FLAG the world holds, which is the
## whole point of the smoke.
func _step_heart_bind(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	if _heart_shrine != null and is_instance_valid(_heart_shrine):
		_heart_shrine.queue_free()
		_heart_shrine = null
	var heart := str(args.get("heart", "meadows"))
	var shrine: Node3D = REALM_HEART_SHRINE.new()
	shrine.name = "SmokeRealmHeartShrine"
	shrine.call("setup", heart, str(args.get("name", "Heart of Meadows")),
		str(args.get("realm", "meadows")))
	root.add_child(shrine)
	_heart_shrine = shrine
	return {"verdict": "PASS", "detail": "shrine bound to '%s', state %s"
		% [heart, str(shrine.call("current_state"))]}


## Earn the Heart. A world fact like any other, so it goes through the ledger --
## and it is submitted rather than written so that a CLIENT calling this arm
## behaves the way a client does (pending, then the delta), instead of the
## harness quietly writing a flag no host ever saw.
func _step_heart_earn(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var hearts: Variant = game.get("realm_hearts")
	var transport: Node = game.get("ledger") as Node
	if hearts == null or transport == null:
		return {"verdict": "ERROR", "detail": "no Game.realm_hearts or Game.ledger"}
	var heart := str(args.get("heart", "meadows"))
	var flag := str((hearts as RefCounted).call("earned_flag", heart))
	if flag.is_empty():
		return {"verdict": "FAIL", "detail": "no earned_flag for heart '%s'" % heart}
	var verdict: Dictionary = transport.call("submit", {
		"kind": "set_world_flag", "realm": str(args.get("realm", "meadows")), "id": flag,
	})
	if not (bool(verdict.get("ok", false)) or bool(verdict.get("pending", false))):
		return {"verdict": "FAIL", "detail": "set_world_flag refused: %s / %s"
			% [str(verdict.get("code", "")), str(verdict.get("reason", ""))]}
	return {"verdict": "PASS", "detail": "earned '%s' (%s)"
		% [flag, "committed" if bool(verdict.get("ok", false)) else "pending"]}


## Press "Place" at the bound shrine. The shipping call, verdict shape and all:
## `ok` on the host, `pending` on a client with the host still to answer, and
## neither is a failure here -- the assertion the smoke makes is what BOTH peers
## can see afterwards, not what this press returned.
func _step_heart_place(_args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	if _heart_shrine == null or not is_instance_valid(_heart_shrine):
		return {"verdict": "ERROR", "detail": "no shrine bound; call heart_bind first"}
	var verdict: Dictionary = _heart_shrine.call("submit_place", game)
	if bool(verdict.get("ok", false)):
		return {"verdict": "PASS", "detail": "placed here and now"}
	if bool(verdict.get("pending", false)):
		return {"verdict": "PASS", "detail": "submitted; the host has still to answer"}
	return {"verdict": "FAIL", "detail": "submit_place refused: %s / %s"
		% [str(verdict.get("code", "")), str(verdict.get("reason", ""))]}


## Press again: wear the Heart's power, or (with `release`) take it off. This is
## the PERSONAL half and it deliberately does not go near the ledger.
func _step_heart_activate(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var hearts: Variant = game.get("realm_hearts")
	if hearts == null:
		return {"verdict": "ERROR", "detail": "no Game.realm_hearts"}
	if bool(args.get("release", false)):
		(hearts as RefCounted).call("clear_active")
		return {"verdict": "PASS", "detail": "released"}
	var heart := str(args.get("heart", "meadows"))
	if not bool((hearts as RefCounted).call("activate", heart, game.get("progression"))):
		return {"verdict": "FAIL", "detail": "activate('%s') refused -- not placed here" % heart}
	return {"verdict": "PASS", "detail": "wearing '%s'" % heart}


# --- lane 6.D: a friend's fight is not silent ---------------------------------
#
# Two arms and one probe. `present_publish` is the owner pressing publish on its
# own outbound proxy -- the exact call `remote_creature.gd` /
# `remote_trainer.gd` make when they notice something -- and `present_damage`
# drives the SAMPLER instead, by taking hit points off the owner's creature the
# same way `combat_manager.gd::host_roll_damage()` does, so the whole path from
# "a number the host wrote" to "a picture on somebody else's screen" is what is
# under test rather than the RPC alone.

## Publish one presentation event from THIS peer's own outbound proxy.
func _step_present_publish(args: Dictionary) -> Dictionary:
	var kind := str(args.get("kind", REMOTE_PRESENTATION.KIND_CATCH))
	var role := str(args.get("role", "trainer"))
	var body := _own_proxy(role)
	if body == null:
		return {"verdict": "FAIL", "detail": "this peer has no %s proxy of its own to publish from" % role}
	body.call("broadcast_presentation", kind, args.get("payload", {}))
	return {"verdict": "PASS", "detail": "%s published '%s'" % [str(body.name), kind]}


## Take `fraction` of its maximum off this peer's own creature, through the same
## `take_damage()` the host rolls into, and let the owner's proxy notice on its
## next tick. Nothing here touches the wire: the publish is the shipping
## sampler's, which is the half worth proving.
func _step_present_damage(args: Dictionary) -> Dictionary:
	# The director's own `ally_instance()`, which is the object the deployed body
	# was built around. NOT `Game.party.active()`: `adopt_starter()` stands a
	# body on a fresh instance without adding it to the party, so `active()` is
	# null for exactly the peers this arm is used on.
	var director := _encounter_director()
	if director == null:
		return {"verdict": "ERROR", "detail": "no EncounterDirector in this scene"}
	var creature: Variant = director.call("ally_instance")
	if creature == null:
		return {"verdict": "FAIL", "detail": "this peer has no creature out to hurt"}
	var instance := creature as Object
	if not instance.has_method("take_damage"):
		return {"verdict": "ERROR", "detail": "creature instance has no take_damage()"}
	var before := float(instance.get("hp"))
	var amount := float(args.get("fraction", 0.25)) * maxf(float(instance.get("max_hp")), 1.0)
	instance.call("take_damage", amount)
	return {"verdict": "PASS", "detail": "hp %.1f -> %.1f" % [before, float(instance.get("hp"))]}


## This peer's OWN outbound proxy for `role`, i.e. the one body in that group
## whose authority is this process. That is the only body a peer may publish
## from, and `broadcast_presentation` refuses any other.
## The effect nodes lane 6.D's hooks leave behind for a body: the bursts
## `combat_vfx.gd` parents beside it, and the flourish/glow it parents onto it.
## Named rather than counted so a failure says WHICH picture is missing.
func _effect_node_names(body: Node3D) -> Array:
	var names: Array = []
	var host: Node = body.get_parent()
	if host != null:
		for child in host.get_children():
			var n := str(child.name)
			if n.begins_with("HitSpark") or n.begins_with("KoPuff") or n.begins_with("CatchBurst"):
				names.append(n)
	for child in body.get_children():
		var n := str(child.name)
		if n.begins_with("LevelUpFlourish") or n.begins_with("BodyGlow"):
			names.append(n)
	return names


func _own_proxy(role: String) -> Node3D:
	var group: StringName = &"remote_trainer" if role == "trainer" else &"remote_creature"
	for body in get_nodes_in_group(group):
		if body is Node3D and is_instance_valid(body) \
				and (body as Node3D).is_multiplayer_authority():
			return body as Node3D
	return null


## Lane 5.A. `scenes/world/meadows_playground.tscn`'s own node name, found the
## same way `_combat_manager()` and `_encounter_director()` find theirs.
func _sequence_director() -> Node:
	if current_scene == null:
		return null
	return current_scene.get_node_or_null(^"SequenceDirector")


# --- lane 5.C: personal fog, personal pins, a shared clear ---------------------
#
# Two arms and one probe. Between them they stand in for the two things a
# player does with an alpha -- walk close enough to notice it, and beat it --
# without needing a 300 m hike or a live fight in a smoke that is about state
# ownership rather than about either.
#
# Both go through shipping code. `alpha_pin` calls the same `MapState.pin_alpha`
# the real `AlphaPins._process()` calls, with a real authored cluster read from
# `alpha_pins.gd::build_clusters()`; the harness supplies only the proximity the
# player would have supplied by walking there. `alpha_clear` calls the shipping
# `AlphaPins.clear_alpha()`, which submits a `set_world_flag` intent through the
# real `Game.ledger`. Neither invents a rule.

## Stand this peer's trainer at (x, z) and let the game's OWN discovery tick
## lift the fog there. Returns once the tick has certainly sampled the new
## position.
##
## WHY THE POSITION IS SUPPLIED RATHER THAN WALKED TO, measured rather than
## assumed. `smoke_net_movement_two_peers.gd`'s own header records it: a fresh
## boot starts inside Grandpa's farmhouse in the opening beat, and forward from
## the spawn is a wall about three metres away, so a peer holding full stick for
## 300 frames travels 2.71 m -- entirely inside the 45 m circle
## `map_landmarks.json` reveals at boot. The first run of
## `smoke_net_fog_is_personal.gd` measured exactly that: 4428 cells before the
## walk and 4428 after. Walking further is a question about where a net smoke
## STARTS (the movement smoke assigns it to whichever lane teaches the harness
## to seed a post-opening save), not about whether fog is personal.
##
## So the harness supplies the standing position, exactly as `alpha_pin` above
## supplies the proximity, and nothing else: the REVEAL is
## `game_state.gd::_process`'s own `map.mark_visited(here)` on its own
## `_DISCOVERY_INTERVAL_S` clock, over the local player's own `MapState`. The
## body is placed the same way `operator_harness.gd::_step_teleport` places it,
## ground height included, so it lands on real terrain rather than under it.
func _step_explore_at(args: Dictionary) -> Dictionary:
	var player := _probe.call("player") as Node3D
	if player == null:
		return {"verdict": "ERROR", "detail": "no live Player to stand anywhere"}
	var at: Array = args.get("at", []) as Array
	if at.size() < 2:
		return {"verdict": "ERROR", "detail": "explore_at needs at:[x,z]"}
	var world: Node = _probe.call("world") as Node
	var y := player.global_position.y
	if world != null and world.has_method("ground_height_at"):
		y = float(world.call("ground_height_at", float(at[0]), float(at[1]))) + 1.0
	player.global_position = Vector3(float(at[0]), y, float(at[1]))
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	var rig := _probe.call("camera_rig") as Node3D
	if rig != null:
		rig.global_position = player.global_position
	# `_DISCOVERY_INTERVAL_S` is 0.5 s, so 60 physics frames is one interval at
	# the nominal rate; the default is four of them, which is slack enough that
	# a slow headless process still gets sampled and short enough that a fog
	# system that has stopped ticking still shows up as zero new cells.
	for i in maxi(1, int(args.get("settle", 240))):
		await physics_frame
	return {"verdict": "PASS", "detail": "stood at (%.0f, %.0f), y=%.1f" % [float(at[0]), float(at[1]), y]}


## Make sure the authored alpha at `order` is pinned on THIS peer's own map.
##
## ALREADY PINNED IS THE BEST OUTCOME, not a failure, and that distinction is a
## measured one. `pin_alpha()` returns true only when it pins something NEW, so
## the first version of this arm reported FAIL on a peer standing at the cluster
## -- because the shipping `AlphaPins` node's own 300 m proximity tick had
## already pinned it, which is the feature working. What the caller wants to
## know is whether this peer holds the pin, so that is what is reported, with
## the detail naming which of the two put it there.
func _step_alpha_pin(args: Dictionary) -> Dictionary:
	var order := int(args.get("order", -1))
	if order < 0:
		return {"verdict": "ERROR", "detail": "alpha_pin needs args.order"}
	var map: Variant = _local_map()
	if map == null:
		return {"verdict": "ERROR", "detail": "no Game.map on this peer"}
	var state: RefCounted = map
	if bool(state.call("is_alpha_pinned", order)):
		return {"verdict": "PASS",
			"detail": "order %d was already pinned by AlphaPins' own proximity tick" % order}
	for cluster: Dictionary in ALPHA_PINS.build_clusters():
		if int(cluster.get("order", -1)) != order:
			continue
		var at: Vector2 = cluster.get("position", Vector2.ZERO)
		state.call("pin_alpha", order, str(cluster.get("species", "")),
			str(cluster.get("display_name", "")), Vector3(at.x, 0.0, at.y), "alpha")
		var held := bool(state.call("is_alpha_pinned", order))
		return {"verdict": "PASS" if held else "FAIL",
			"detail": "pinned order %d here; map holds it: %s" % [order, str(held)]}
	return {"verdict": "ERROR", "detail": "no authored alpha cluster with order %d" % order}


## Beat the alpha at `order` -- the WORLD half, through the ledger.
func _step_alpha_clear(args: Dictionary) -> Dictionary:
	var order := int(args.get("order", -1))
	if order < 0:
		return {"verdict": "ERROR", "detail": "alpha_clear needs args.order"}
	var pins := _alpha_pins_node()
	if pins == null:
		return {"verdict": "ERROR", "detail": "no AlphaPins node in this scene"}
	var submitted := bool(pins.call("clear_alpha", order))
	return {"verdict": "PASS" if submitted else "FAIL",
		"detail": "clear_alpha(%d) submitted=%s" % [order, str(submitted)]}


## The `AlphaPins` node `playground_world.gd` drops into the world. It is added
## with `add_child(ALPHA_PINS.new())` and therefore carries an engine-assigned
## name, so it is found by the method it owns rather than by a name that is not
## authored anywhere and would silently change.
func _alpha_pins_node() -> Node:
	if current_scene == null:
		return null
	for child in current_scene.get_children():
		if child.has_method("clear_alpha") and child.has_method("tick"):
			return child
	return null


func _local_map() -> Variant:
	var game := root.get_node_or_null(^"Game")
	return game.get("map") if game != null else null


func _step_wait_flag(args: Dictionary) -> Dictionary:
	var flag := str(args.get("flag", ""))
	if flag.is_empty():
		return {"verdict": "ERROR", "detail": "wait_flag needs args.flag"}
	var scope := str(args.get("scope", "any"))
	var budget := int(args.get("budget_frames", NET_STEP_BUDGET_FRAMES))
	for i in maxi(1, budget):
		if _flag_is_set(flag, scope):
			return {"verdict": "PASS", "detail": "flag %s (%s) set after %d frames" % [flag, scope, i]}
		await physics_frame
	return {"verdict": "FAIL", "detail": "flag %s (%s) never set within %d frames" % [flag, scope, budget]}


func _flag_is_set(flag: String, scope: String) -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return false
	var store: Variant = null
	match scope:
		"world":
			store = game.call("world_flags") if game.has_method("world_flags") else null
		"player":
			store = game.call("player_flags") if game.has_method("player_flags") else null
		_:
			store = game.get("progression")
	if store == null:
		return false
	return bool((store as RefCounted).call("has", flag))


## Lane 2.B. Poll until this peer's input context becomes `equals`.
##
## `assert input_context` already exists and is the same comparison, but it is
## a SNAPSHOT: it answers on the frame it arrives and cannot wait. A peer that
## reaches the world by changing scene -- which is what a joiner coming off the
## title screen does, and the only honest way to test the path a player takes
## -- is blocked for the whole of that scene's build (~85 s for the Meadows,
## spike S2) and answers nothing at all until it is done. This is the wait,
## with the assertion built in, so a smoke does not have to spin probes at a
## process that is busy.
func _step_wait_context(args: Dictionary) -> Dictionary:
	var want := str(args.get("equals", ""))
	if want.is_empty():
		return {"verdict": "ERROR", "detail": "wait_context needs args.equals"}
	var budget := int(args.get("budget_frames", NET_STEP_BUDGET_FRAMES))
	var have := ""
	for i in maxi(1, budget):
		have = str(_probe.call("input_context"))
		if have == want:
			return {"verdict": "PASS", "detail": "input_context=%s after %d frames" % [have, i]}
		await physics_frame
	return {"verdict": "FAIL", "detail": "input_context=%s, wanted %s" % [have, want]}


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

# --- lane 4.E: down and revive ------------------------------------------------
#
# Two arms and one probe. Neither arm invents a death or a revive: `go_down`
# drives the SHIPPING lethal path (`vitals.health` to zero, then the player's
# own `died` signal -- byte for byte what `scripts/world/water.gd
# ::_apply_hazard_damage` does when a drowning turns fatal), and the revive
# itself is not an arm at all: the smoke stands the reviver next to the body
# and holds the real `interact` action through `hold`/`release`, which is the
# player's own input.


## Kill this peer outright, through the game's own signal.
##
## `emit_signal("died")` rather than a fall, because a reproducible lethal fall
## needs terrain the harness cannot promise it has; `water.gd` reaches the same
## signal the same way for the same reason. Everything downstream --
## `player_death.gd::_on_died`, `downed_state.gd::request_down`, the satchel,
## the respawn -- is untouched shipping code.
func _step_go_down(_args: Dictionary) -> Dictionary:
	var player := _probe.call("player") as Node3D
	if player == null:
		return {"verdict": "ERROR", "detail": "no live player to bring down (scene '%s')" % _scene_name}
	var vitals: Variant = player.get("vitals")
	if vitals == null:
		return {"verdict": "ERROR", "detail": "the player carries no vitals object"}
	if not player.has_signal("died"):
		return {"verdict": "ERROR", "detail": "the player has no `died` signal to emit"}
	(vitals as RefCounted).set("health", 0.0)
	player.emit_signal("died")
	return {"verdict": "PASS", "detail": "health 0 and `died` emitted"}


## Put this peer's rig `offset` metres from the downed teammate's body, so the
## revive hold has something to be held over.
##
## A placement rather than a walk, deliberately. `move_to` drives the real
## stick navigator, and what it measures is pathfinding -- which this smoke is
## not about, and which this repo has open stall findings against
## (FENCE-CORNER-0903). The thing under test is that a hold over a downed body
## revives it; standing the reviver there is setup, exactly as lane 3.B's
## `pickup_stand` stands its prop rather than making the smoke walk to one.
func _step_stand_by_downed(args: Dictionary) -> Dictionary:
	var player := _probe.call("player") as Node3D
	if player == null:
		return {"verdict": "ERROR", "detail": "no live player to move (scene '%s')" % _scene_name}
	# 1.8 m, not the metre the first run used. Two trainer capsules are 0.4 m
	# in radius each, and `remote_trainer.gd::SNAP_M` makes a placement of more
	# than five metres arrive on the far peer as a SNAP rather than a walk -- so
	# a reviver dropped a metre away lands interpenetrating the body it came to
	# help, `move_and_slide()` shoves the downed player into the farmhouse wall,
	# and `player_controller.gd`'s unstick lifts them 5.6 m into the air. That
	# is what the first run of this smoke produced (see the lane report's
	# findings). 1.8 m leaves a metre of clearance and is still comfortably
	# inside `revive_radius_m` of 2.5.
	var offset := float(args.get("offset", 1.8))
	var want := int(args.get("peer_id", 0))
	var body := _downed_body(want)
	if body == null:
		return {"verdict": "ERROR",
			"detail": "no downed teammate's body to stand by (peer_id=%d, %d remote bodies)"
				% [want, get_nodes_in_group(&"remote_trainer").size()]}
	player.global_position = body.global_position + Vector3(offset, 0.0, 0.0)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	await physics_frame
	var gap := player.global_position.distance_to(body.global_position)
	return {"verdict": "PASS", "detail": "standing %.2f m from peer %d's body"
		% [gap, int(body.get("peer_id"))]}


## The `remote_trainer` body of a peer this process knows to be downed. With a
## `peer_id` of 0 it takes the one body this process does NOT own that
## `downed_state.gd` has a window open for -- which in a two-peer session is
## exactly one body, and reporting null rather than guessing is what keeps a
## smoke from asserting against its own reflection.
func _downed_body(peer_id: int) -> Node3D:
	var state := _downed_state()
	var known: Array = []
	if state != null:
		var status: Variant = state.call("status")
		if status is Dictionary:
			known = (status as Dictionary).get("downed_peers", [])
	for node in get_nodes_in_group(&"remote_trainer"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		var b: Node3D = node
		var id := int(b.get("peer_id"))
		if peer_id != 0:
			if id == peer_id:
				return b
			continue
		if b.is_multiplayer_authority():
			continue
		if known.has(id):
			return b
	return null


## `/root/Game/DownedState` -- lane 4.E mounts it under the one autoload so the
## node path is identical in every process (see that file's header).
func _downed_state() -> Node:
	return root.get_node_or_null(^"Game/DownedState")


# --- lane 5.A: story flags and the gates that read them ------------------------
#
# One arm and one probe. The arm does not invent a story event: it submits the
# SAME intent the shipping trigger submits (`story_ledger.gd::write_flag()`,
# which is what `sequence_director.gd::_set_progression_flag`, `road_gate.gd`
# and `tether_relay.gd` all call), so what the smoke drives is the game's own
# path to the ledger rather than a test-only shortcut into a flag store.

## Submit one story flag through the ledger and report the verdict. `args.flag`
## is the id; `args.scope` is optional and only ever narrows -- omitted, D99's
## table decides, which is the case worth testing.
func _step_story_flag(args: Dictionary) -> Dictionary:
	var flag := str(args.get("flag", ""))
	if flag.is_empty():
		return {"verdict": "ERROR", "detail": "story_flag needs args.flag"}
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	if game.get("ledger") == null:
		return {"verdict": "ERROR", "detail": "no Game.ledger to submit through"}
	var scope := str(args.get("scope", ""))
	var verdict: Dictionary
	if scope == "world":
		verdict = STORY_LEDGER.set_world_flag(game, flag)
	elif scope == "player":
		verdict = STORY_LEDGER.grant_player_flag(game, flag, args.get("peers", []) as Array)
	else:
		verdict = STORY_LEDGER.write_flag(game, flag)
	var ok := bool(verdict.get("ok", false)) or bool(verdict.get("pending", false))
	return {
		"verdict": "PASS" if ok else "FAIL",
		"detail": "%s: ok=%s pending=%s code='%s' reason='%s'" % [
			flag, str(verdict.get("ok", false)), str(verdict.get("pending", false)),
			str(verdict.get("code", "")), str(verdict.get("reason", "")),
		],
	}


## Which nodes in this peer's world are gates, and whether each is open right
## now. Reported by NODE, not by flag: "the world says the bridge is open" and
## "the leaf this process is drawing has actually swung" are two different
## facts, and a delta that reached `WorldState` without re-posing the scene is
## exactly the failure that looks identical from the flag alone (lane 3.C's
## `placed_building_rows` vs `placed_building_nodes` split, same reasoning).
func _story_gate_rows() -> Array:
	var rows: Array = []
	for node in get_nodes_in_group("progression_restore"):
		if not is_instance_valid(node) or not node.has_method("is_open"):
			continue
		var flag: Variant = node.get("flag_id")
		rows.append({
			"node": str(node.name),
			"flag": "" if flag == null else str(flag),
			"open": bool(node.call("is_open")),
		})
	return rows


# --- lane 4.D: one trainer, two players, two rewards ---------------------------
#
# Two arms and one probe. The battle is started through the same
# `begin_trainer_battle()` `trainer_npc.gd` calls when a player presses the
# challenge prompt, and it is WON by real strikes through
# `submit_encounter_intent()` -- the one door `combat_manager.gd` itself
# submits through. What the harness supplies is only what a controller
# supplies: where the creature stands and which way the swing faced.


## Take up a named trainer's challenge.
##
## The teleport is the same one `_step_engage_wild` and `smoke_combat_camera`
## use, and for the reason `smoke_aggression.gd`'s header documents: a scripted
## walk across the Meadows dies against a Terrain3D snag, and a smoke that fails
## there is reporting on terrain rather than on what it is testing.
func _step_trainer_battle(args: Dictionary) -> Dictionary:
	var director := _encounter_director()
	if director == null:
		return {"verdict": "ERROR", "detail": "no EncounterDirector in this scene"}
	var trainer_id := str(args.get("trainer", "practice_trainer"))
	var spec: Dictionary = NET_TRAINERS.trainer(trainer_id)
	if spec.is_empty():
		return {"verdict": "ERROR", "detail": "trainers.json has no trainer '%s'" % trainer_id}
	var body: Node3D = _trainer_body_named(trainer_id)
	var player := _probe.call("player") as Node3D
	if player == null:
		return {"verdict": "ERROR", "detail": "no live player"}
	if body != null:
		player.global_position = body.global_position + Vector3(2.0, 0.0, 2.0)
		player.velocity = Vector3.ZERO
		for i in 20:
			await physics_frame
	if not bool(director.call("can_challenge", spec)):
		return {"verdict": "FAIL", "detail": "'%s' will not take the challenge (already beaten: %s, nothing out: %s)"
			% [trainer_id, str(NET_TRAINERS.already_beaten(spec, _progression_store())),
				str(director.call("no_usable_ally"))]}
	if not bool(director.call("begin_trainer_battle", spec, body)):
		return {"verdict": "FAIL", "detail": "begin_trainer_battle('%s') refused" % trainer_id}
	for i in maxi(0, int(args.get("settle", 45))):
		await physics_frame
	var manager := _combat_manager()
	if manager == null or not bool(manager.call("is_fighting")):
		return {"verdict": "FAIL", "detail": "the challenge did not start a fight"}
	return {"verdict": "PASS", "detail": "challenged %s; bound to encounter '%s' (%d creatures to come)"
		% [trainer_id, str(manager.call("encounter_id")),
			int(director.call("trainer_creatures_left"))]}


## Fight the trainer's whole team and win it, through the production strike
## path. `smoke_trainer_battle.gd`'s own loop, with the presses replaced by real
## `strike_intent` submissions so the HOST arbitrates every blow.
##
## The player's own creature is topped up between swings -- exactly what
## `smoke_trainer_battle.gd` does, and for the same reason: this arm is testing
## the payout at the end of a won battle, not the player's ability to survive
## one, and a creature that faints ends the battle in a LOSS and tests nothing.
func _step_win_trainer_battle(args: Dictionary) -> Dictionary:
	var director := _encounter_director()
	var manager := _combat_manager()
	if director == null or manager == null:
		return {"verdict": "ERROR", "detail": "no EncounterDirector/CombatManager"}
	if not bool(director.call("trainer_battle_active")):
		return {"verdict": "FAIL", "detail": "no trainer battle is running"}
	# PHYSICS FRAMES, not loop iterations, and bounded by the budget the
	# coordinator actually sent. The first version of this arm counted
	# iterations and burned ~24 frames inside each one, so a "2400" ceiling was
	# really 57,600 frames and the coordinator's own wall-clock deadline
	# expired first -- reported as "no verdict", which says nothing about the
	# battle. Leaving a margin below the budget means this arm answers with a
	# real verdict instead of being cut off.
	var budget := maxi(120, int(args.get("budget_frames", 2400)) - 240)
	## How often a swing is submitted. There is no cooldown to respect on this
	## path -- `submit_encounter_intent` goes straight to host arbitration --
	## so this is only the time the body needs to be placed and settle.
	var stride := maxi(4, int(args.get("stride", 20)))
	var swings := 0
	var frames := 0
	var creatures_seen := {}
	while bool(director.call("trainer_battle_active")) and frames < budget:
		await physics_frame
		frames += 1
		if not bool(manager.call("is_fighting")):
			# The beat between their creatures. Nothing to do but let it pass.
			continue
		if frames % stride != 0:
			continue
		var mine: Variant = manager.call("active_creature")
		if mine != null:
			# Exactly what `smoke_trainer_battle.gd` does, for its reason: this
			# arm is testing the payout at the end of a won battle, not the
			# player's ability to survive one, and a creature that faints ends
			# the battle in a LOSS and tests nothing.
			(mine as RefCounted).set("hp", float((mine as RefCounted).get("max_hp")))
		var opponent: Variant = manager.call("enemy_body")
		var body: Variant = director.call("ally_body")
		if opponent == null or not is_instance_valid(opponent) \
				or body == null or not is_instance_valid(body):
			continue
		creatures_seen[str((opponent as Node3D).name)] = true
		var target: Vector3 = (opponent as Node3D).call("centre")
		var stand := target + Vector3(1.1, 0.0, 0.0)
		if (body as Node3D).has_method("place_on_ground"):
			(body as Node3D).call("place_on_ground", stand)
		else:
			(body as Node3D).global_position = stand
		for i in 4:
			await physics_frame
			frames += 1
		if not bool(manager.call("quick_ready")):
			continue
		# The real BUTTON, not a hand-built `strike_intent`.
		#
		# FINDING, and it is why this arm looks different from
		# `_step_strike`: submitting the intent directly does land the host's
		# damage -- the record's hit points drop and both peers draw the same
		# bar -- but nothing ever performs the KILL, because
		# `apply_host_strike_verdict()` is what turns a host verdict into a
		# faint and only `combat_manager.gd::_submit_strike_intent()` calls it.
		# Measured: 108 direct submissions against Bryn's first creature, its
		# bar at the floor, and the battle still running. `_step_strike` exists
		# to say what a MODIFIED client could say (a swing aimed at a
		# teammate), which no button can produce; this arm needs a fight to
		# actually finish, so it presses the button a player presses and the
		# whole production path -- manager, host arbitration, verdict,
		# faint -- runs.
		var pressed := await _inject("combat_quick", 1)
		if not bool(pressed.get("ok", false)):
			return {"verdict": "ERROR", "detail": "press 'combat_quick' could not be injected: %s"
				% str(pressed.get("why", ""))}
		frames += 3
		swings += 1
	if bool(director.call("trainer_battle_active")):
		return {"verdict": "FAIL",
			"detail": "the battle never resolved in %d frames (%d swings, %d of their creatures met, %d still queued)"
				% [frames, swings, creatures_seen.size(), int(director.call("trainer_creatures_left"))]}
	# The payout is committed from `_finish_trainer_battle()` and the deltas
	# have to cross to the other peer before anybody asks about them.
	for i in maxi(0, int(args.get("settle", 120))):
		await physics_frame
	return {"verdict": "PASS", "detail": "battle won in %d frames / %d swings against %d of their creatures"
		% [frames, swings, creatures_seen.size()]}


## The placed body of a named trainer, or null. Asked of the placer's own
## `body_for()`, which reads the `trainer_id` META rather than a node name --
## `trainer_npc.gd::_spawn()` names the node after the DISPLAY name ("Bryn"),
## so matching by name would find the wrong person the moment two trainers
## share one.
##
## Null is a legal answer and the caller treats it as one: `begin_trainer_battle`
## documents a null trainer body, and a scene that placed nobody is a scene
## where `can_challenge()` is about to say so in words.
func _trainer_body_named(trainer_id: String) -> Node3D:
	var world := get_current_scene()
	if world == null:
		return null
	for node in world.find_children("*", "Node3D", true, false):
		if not is_instance_valid(node) or not node.has_method("body_for"):
			continue
		var body: Variant = node.call("body_for", trainer_id)
		if body != null and is_instance_valid(body):
			return body as Node3D
	return null


func _progression_store() -> RefCounted:
	var game := root.get_node_or_null(^"Game")
	return game.get("progression") as RefCounted if game != null else null


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
		"on_floor":
			var floor_player := _probe.call("player") as Node3D
			if floor_player == null or not floor_player.has_method("is_on_floor"):
				return null
			return bool(floor_player.call("is_on_floor"))
		"state_hash":
			return _compute_state_hash()
		"world_seed":
			# The RESOLVED seed -- what `spawn_tables.gd::resolve_seed()`
			# actually hands every spawn lookup, honoring `TB_WORLD_SEED` --
			# not the raw per-process roll `game_state.gd::new_game()` stores.
			# This is what the boot smoke asserts against the pin
			# (contract §7 amended: "asserted separately against the pin").
			var wgame := root.get_node_or_null(^"Game")
			if wgame == null:
				return null
			return int(SPAWN_TABLES.resolve_seed(int(wgame.get("world_seed"))))
		"map_fog":
			# Lane 5.C. What THIS peer has personally discovered: revealed fog
			# cells, discovered landmarks, and pinned alphas, off `Game.map` --
			# which is `PlayerState.map_for(realm)` for the LOCAL player. The
			# raw cell COUNT rather than the fraction, because the assertion is
			# "unchanged by what the other peer did", and a fraction rounds two
			# different maps onto the same number.
			var fog_map: Variant = _local_map()
			if fog_map == null:
				return null
			var fog_state: RefCounted = fog_map
			var revealed := 0
			for byte in (fog_state.call("visited_bytes") as PackedByteArray):
				if byte != 0:
					revealed += 1
			return {
				"cells": revealed,
				"grid": [int(fog_state.call("cell_grid_x")), int(fog_state.call("cell_grid_z"))],
				"landmarks": int(fog_state.call("discovered_landmark_count")),
				"alpha_pins": int(fog_state.call("alpha_pin_count")),
				"revision": int(fog_state.get("revision")),
			}
		"realm_heart":
			# Lane 5.B. The two halves of a Realm Heart, kept apart on purpose.
			#
			# `earned`/`placed` are read off `Game.world.flags` DIRECTLY rather
			# than through the merged progression view, and that is the
			# assertion: a placement that landed in this peer's own player
			# store would still answer `true` through the merged view on the
			# peer that made it, and `false` on its friend, which is exactly
			# the bug the ledger route exists to stop. Asking the world store
			# means "the WORLD says so", on both peers.
			#
			# `active` is the personal half, off this process's own
			# `RealmHeartState`. Two peers reporting two different values here
			# is the deliverable, not drift.
			var hgame := root.get_node_or_null(^"Game")
			if hgame == null:
				return null
			var hearts: Variant = hgame.get("realm_hearts")
			if hearts == null:
				return null
			var hargs: Dictionary = (msg.get("args", {}) as Dictionary)
			var heart := str(hargs.get("heart", "meadows"))
			var hworld: Variant = hgame.get("world")
			var hflags: Variant = (hworld as RefCounted).get("flags") if hworld != null else null
			var earned_id := str((hearts as RefCounted).call("earned_flag", heart))
			var placed_id := str((hearts as RefCounted).call("placed_flag", heart))
			var hprog: Variant = hgame.get("progression")
			return {
				"heart": heart,
				"earned_flag": earned_id,
				"placed_flag": placed_id,
				"earned_in_world": hflags != null and bool((hflags as RefCounted).call("has", earned_id)),
				"placed_in_world": hflags != null and bool((hflags as RefCounted).call("has", placed_id)),
				"earned": hprog != null and bool((hprog as RefCounted).call("has", earned_id)),
				"placed": hprog != null and bool((hprog as RefCounted).call("has", placed_id)),
				"active": str((hearts as RefCounted).call("active_id")),
				"stamina_multiplier": float((hearts as RefCounted).call("stamina_capacity_multiplier")),
				"shrine_state": "" if _heart_shrine == null or not is_instance_valid(_heart_shrine) \
					else str(_heart_shrine.call("current_state")),
			}
		"remote_presentation":
			# Lane 6.D. What this process has DRAWN on bodies it does not own,
			# keyed by node name. `plays` is the counter each body bumps in
			# `play_presentation()`, `last` the kind it drew, and `effect` the
			# NAME of the node that draw actually spawned -- which is what "the
			# hook fired" means here. `effects` is the weaker live scan of what
			# is standing under the body right now, kept only as a debugging
			# aid: these effects last a fraction of a second and free
			# themselves, so an empty `effects` beside a non-empty `effect`
			# means the picture played and finished, not that it never played.
			# Nobody judges what it looked like; that is Stage C's bar.
			var drawn := {}
			for group: StringName in [&"remote_creature", &"remote_trainer"]:
				for body in get_nodes_in_group(group):
					if not is_instance_valid(body) or not (body is Node3D):
						continue
					var pbody: Node3D = body
					if pbody.is_multiplayer_authority():
						continue
					drawn[str(pbody.name)] = {
						"role": "creature" if group == &"remote_creature" else "trainer",
						"plays": int(pbody.get("presentation_plays")),
						"last": str(pbody.get("last_presentation")),
						"effect": str(pbody.get("last_effect")),
						"effects": _effect_node_names(pbody),
						"presence": pbody.get_node_or_null(^"Presence") != null,
					}
			return drawn
		"remote_trainers":
			# Lane 2.C. Every OTHER peer's body as this process sees it:
			# the nodes `scripts/net/trainer_spawn.gd` spawned under D97's
			# authored `Spawned/Trainers` container, keyed by the real peer id
			# (which is a large random 32-bit number, never an index — ENet
			# spike finding 2), with the position this process is actually
			# drawing them at and the nameplate text it is actually showing.
			# `tests/smoke_net_movement_two_peers.gd` compares that position
			# against the owner's own reported position.
			var seen := {}
			for body in get_nodes_in_group(&"remote_trainer"):
				if not is_instance_valid(body) or not (body is Node3D):
					continue
				var b: Node3D = body
				var plate := b.get_node_or_null(^"Nameplate") as Label3D
				seen[str(int(b.get("peer_id")))] = {
					"pos": [b.global_position.x, b.global_position.y, b.global_position.z],
					"name": "" if plate == null else str(plate.text),
					"mine": b.is_multiplayer_authority(),
					"visible": b.visible,
					"anim": str(b.get("net_anim_state")),
					"sprinting": bool(b.get("net_sprinting")),
					"carried": bool(b.get("net_carried")),
				}
			return seen
		"day":
			# Stage B lane 5.D. `Game.day` on this peer, which under D105 is
			# host truth on every process. The whole negative half of
			# `smoke_net_sleep_vote.gd` is this number NOT moving while only
			# one of two players is in a bed.
			var dgame := root.get_node_or_null(^"Game")
			return null if dgame == null else int(dgame.get("day"))
		"sleep_vote":
			# Stage B lane 5.D. What this process believes about the vote:
			# whether it has mounted `night_rest.gd`'s `SleepVote` node at all,
			# whether THIS peer is lying down, who it thinks is still up, and
			# the replicated `sleeping` field off every registry row. The last
			# one is the host's actual tally as every peer received it.
			var sgame := root.get_node_or_null(^"Game")
			if sgame == null:
				return null
			var ssession: Node = sgame.get("session") as Node
			var vote: Node = null if ssession == null else ssession.get_node_or_null(^"SleepVote")
			var marks := {}
			if ssession != null:
				for raw: Variant in (ssession.call("peers") as Array):
					if typeof(raw) != TYPE_DICTIONARY:
						continue
					var srow: Dictionary = raw
					if not srow.has("peer_id"):
						continue
					marks[str(int(srow["peer_id"]))] = bool(srow.get("sleeping", false))
			return {
				"mounted": vote != null,
				"sleeping_here": vote != null and bool(vote.call("is_sleeping_here")),
				"awake": [] if vote == null else vote.call("awake_names"),
				"registry_sleeping": marks,
			}
		"deployed_creatures":
			# Stage B lane 4.B. Every DEPLOYED creature body this process is
			# holding, keyed by NODE NAME -- because there are three of them in
			# a two-peer session and two of them share an owner: the local
			# `follower_creature.gd` this peer pilots (`local` true), that
			# peer's own invisible outbound `remote_creature.gd` proxy, and the
			# other peer's visible proxy. Keying by owner id would collapse the
			# first two and hide exactly the case worth asserting.
			#
			# `owner`, `authority` and `mine` are reported separately and all
			# three matter: a body that exists with the WRONG authority looks
			# like a frozen creature, not like an error, so
			# `tests/smoke_net_deploy_two_creatures.gd` asserts on them rather
			# than on presence alone.
			var deployed := {}
			for body in get_nodes_in_group(&"deployed_creature"):
				if not is_instance_valid(body) or not (body is Node3D):
					continue
				var c: Node3D = body
				deployed[str(c.name)] = {
					"pos": [c.global_position.x, c.global_position.y, c.global_position.z],
					"owner": int(c.get("owner_peer_id")),
					"species": str(c.get("species_id")),
					"authority": c.get_multiplayer_authority(),
					"mine": c.is_multiplayer_authority(),
					"local": c.has_method("is_local_deployment") and bool(c.call("is_local_deployment")),
					"visible": c.visible,
				}
			return deployed
		"encounter":
			# Stage B lane 4.C. Everything `smoke_net_shared_wild_fight` asserts
			# on, read off this peer's own live objects: the encounter record it
			# is rendering (§3 -- the HP here IS the hit points), its own
			# creature's HP, and the last refusal the host gave it.
			#
			# The refusal is reported as well as the HP deliberately: §5 says a
			# silent no-op would pass the weaker half of the friendly-fire test
			# while hiding a targeting bug, so the smoke asserts BOTH that the
			# teammate took nothing and that the striker was told why.
			var edirector := _encounter_director()
			var emanager := _combat_manager()
			if edirector == null or emanager == null:
				return {"available": false}
			var rec: Dictionary = edirector.call("encounter_record")
			var opponent: Dictionary = rec.get("opponent", {}) as Dictionary
			var mine: Variant = edirector.call("ally_instance")
			var mine_body: Variant = edirector.call("ally_body")
			var joinable: Array = []
			for row: Variant in (edirector.call("joinable_encounters") as Array):
				joinable.append(str((row as Dictionary).get("encounter_id", "")))
			var out := {
				"available": true,
				"fighting": bool(emanager.call("is_fighting")),
				"id": str(rec.get("encounter_id", "")),
				"bound_id": str(emanager.call("encounter_id")),
				"kind": str(rec.get("kind", "")),
				"phase": str(rec.get("phase", "")),
				"seq": int(rec.get("seq", 0)),
				"realm": str(rec.get("realm", "")),
				"participants": (rec.get("participants", {}) as Dictionary).keys(),
				"opponent_hp": float(opponent.get("hp", -1.0)),
				"opponent_hp_max": float(opponent.get("hp_max", -1.0)),
				"opponent_species": str(opponent.get("species_id", "")),
				"opponent_pos": opponent.get("position", []),
				"refusal": emanager.get("last_encounter_refusal"),
				"joinable": joinable,
			}
			if mine != null:
				out["my_creature_hp"] = float((mine as RefCounted).get("hp"))
				out["my_creature_max_hp"] = float((mine as RefCounted).get("max_hp"))
			if mine_body != null and is_instance_valid(mine_body):
				var mb: Vector3 = (mine_body as Node3D).global_position
				out["my_creature_pos"] = [mb.x, mb.y, mb.z]
			return out
		"trainer_reward":
			# Lane 4.D. Everything `smoke_net_boss_rewards_each_participant`
			# asserts on, read off this peer's own live objects.
			#
			# The three questions are deliberately answered from three
			# different stores, because §7 says they are three different
			# facts and collapsing them would hide the bug this lane exists
			# to prevent:
			#
			#   * `world_flags` -- `Game.world.flags`, the WORLD half (D99).
			#     The defeat flag lives here and it is set once, for everybody.
			#   * `receipts` -- `world_ledger.gd::reward_flag(source, peer)`,
			#     also world-scoped, one per participant per source. This is
			#     what proves the PERSONAL half happened per person rather
			#     than once for the fight.
			#   * `satchel` and `party_xp` -- this peer's OWN inventory and
			#     party (D100: a peer's party is its own), which is where a
			#     payout that was announced but never landed shows up.
			var rgame := root.get_node_or_null(^"Game")
			if rgame == null:
				return null
			# Probe arguments arrive under `args`, not at the top level
			# (`net_harness.gd::probe()` sends `{"type","id","what","args"}`).
			var rargs: Dictionary = msg.get("args", {}) as Dictionary
			var rtrainer := str(rargs.get("trainer", "practice_trainer"))
			var rspec: Dictionary = NET_TRAINERS.trainer(rtrainer)
			var rworld: Variant = rgame.get("world")
			var rflags: Variant = (rworld as RefCounted).get("flags") if rworld != null else null
			var rsession: Node = rgame.get("session") as Node
			var rpeers: Array = []
			if rsession != null and rsession.has_method("peers"):
				for raw: Variant in (rsession.call("peers") as Array):
					if typeof(raw) == TYPE_DICTIONARY and (raw as Dictionary).has("peer_id"):
						rpeers.append(int((raw as Dictionary)["peer_id"]))
			var receipts := {}
			for source: Variant in rargs.get("sources", [NET_REWARDS.source_for(rtrainer, "coins")]):
				var per := {}
				for pid: Variant in rpeers:
					var receipt := "reward:%s:%d" % [str(source), int(pid)]
					per[str(int(pid))] = rflags != null \
						and bool((rflags as RefCounted).call("has", receipt))
				receipts[str(source)] = per
			var rinv: Variant = rgame.get("inventory")
			var satchel := {}
			for item: Variant in rargs.get("items", ["coin", "potion_small"]):
				satchel[str(item)] = 0 if rinv == null \
					else int((rinv as RefCounted).call("count", str(item)))
			var rparty: Variant = rgame.get("party")
			var xp_total := 0
			if rparty != null:
				for i in int((rparty as RefCounted).call("size")):
					var member: Variant = (rparty as RefCounted).call("at", i)
					if member != null:
						xp_total += int((member as RefCounted).get("xp"))
			var rdirector := _encounter_director()
			return {
				"trainer": rtrainer,
				"defeat_flag": str(rspec.get("defeat_flag", "")),
				"beaten": rflags != null and not str(rspec.get("defeat_flag", "")).is_empty() \
					and bool((rflags as RefCounted).call("has", str(rspec.get("defeat_flag", "")))),
				"can_challenge": rdirector != null \
					and bool(rdirector.call("can_challenge", rspec)),
				"battle_active": rdirector != null \
					and bool(rdirector.call("trainer_battle_active")),
				"receipts": receipts,
				"satchel": satchel,
				"party_xp": xp_total,
				"local_peer_id": 0 if rsession == null or not rsession.has_method("local_peer_id") \
					else int(rsession.call("local_peer_id")),
				"session_peers": rpeers,
			}
		"downed":
			# Lane 4.E. Everything the down/revive smoke asserts on, read off
			# this peer's own live objects: whether IT is downed and for how
			# much longer, whom it knows to be downed, what its health and
			# locomotion actually are, and how many death satchels the world
			# holds -- because "going down dropped no satchel" is the half of
			# the deliverable that a revive which still costs you your bag
			# would quietly fail.
			var dgame := root.get_node_or_null(^"Game")
			var dstate := _downed_state()
			if dgame == null:
				return null
			var dplayer := _probe.call("player") as Node3D
			var dvitals: Variant = dplayer.get("vitals") if dplayer != null else null
			var drow := {
				"available": dstate != null,
				"health": float((dvitals as RefCounted).get("health")) if dvitals != null else -1.0,
				"stamina": float((dvitals as RefCounted).get("stamina")) if dvitals != null else -1.0,
				"locomotion": dplayer != null and dplayer.has_method("locomotion_enabled") \
					and bool(dplayer.call("locomotion_enabled")),
				"satchels": (dgame.get("death_satchels") as Array).size(),
				"satchel_nodes": get_nodes_in_group(&"death_satchel").size(),
				"carried": _storage_counts(dgame.get("inventory") as RefCounted),
			}
			if dstate != null:
				var dstatus: Variant = dstate.call("status")
				if dstatus is Dictionary:
					drow.merge(dstatus as Dictionary, true)
			return drow
		"story":
			# Lane 5.A. Everything the two story smokes assert on, read off this
			# peer's own live objects: what THE WORLD says (never the merged
			# view -- a merged read cannot tell "the world opened this gate"
			# from "my own store happens to hold the id"), what THIS character
			# personally holds, whether the opening is still gating them, and
			# whether the gate NODES in front of them have actually re-posed.
			#
			# `args.world_flags` / `args.player_flags` name the ids to report,
			# so a smoke asks about its own flags rather than this file
			# carrying a list that goes stale.
			var story_game := root.get_node_or_null(^"Game")
			if story_game == null:
				return null
			var story_args: Dictionary = msg.get("args", {}) as Dictionary
			var world_store: Variant = STORY_LEDGER.world_flags(story_game)
			var local_store: Variant = story_game.call("player_flags") \
				if story_game.has_method("player_flags") else null
			var world_out := {}
			for raw: Variant in (story_args.get("world_flags", []) as Array):
				world_out[str(raw)] = world_store != null \
					and bool((world_store as RefCounted).call("has", str(raw)))
			var player_out := {}
			for raw: Variant in (story_args.get("player_flags", []) as Array):
				player_out[str(raw)] = local_store != null \
					and bool((local_store as RefCounted).call("has", str(raw)))
			var director := _sequence_director()
			var story_player := _probe.call("player") as Node3D
			var story_party: Variant = story_game.get("party")
			return {
				"world": world_out,
				"player": player_out,
				"beat": "" if director == null else str(director.call("beat")),
				"world_moved_on": director != null and director.has_method("world_has_moved_on") \
					and bool(director.call("world_has_moved_on")),
				"locomotion": story_player != null and story_player.has_method("locomotion_enabled") \
					and bool(story_player.call("locomotion_enabled")),
				"context": str(_probe.call("input_context")),
				"party": 0 if story_party == null else int((story_party as RefCounted).call("size")),
				"gates": _story_gate_rows(),
			}
		"realm":
			# Wave 6 lane 6.A. Where this peer is standing, and where it
			# believes everybody else is. The per-peer realms come off the
			# REGISTRY (`Session.realm_of`), never off `Game.current_realm`,
			# which D97 makes true of the local player only.
			var rgame := root.get_node_or_null(^"Game")
			if rgame == null:
				return null
			var rsess := _session()
			var by_peer: Dictionary = {}
			if rsess != null and bool(rsess.call("is_active")):
				for entry: Variant in (rsess.call("peers") as Array):
					if entry is Dictionary:
						by_peer[str(int((entry as Dictionary).get("peer_id", 0)))] = \
							str((entry as Dictionary).get("realm", ""))
			return {
				"current": str(rgame.get("current_realm")),
				"scene": str(current_scene.name) if current_scene != null else "",
				"peers": by_peer,
				"occupied": rsess.call("occupied_realms") if rsess != null \
					and bool(rsess.call("is_active")) else [],
			}
		"world_records":
			# Wave 6 lane 6.A deliverable 5. What the host holds, and what it
			# has actually WRITTEN. The live half alone would not prove
			# anything: the whole risk is a realm's world state that lives
			# only in a scene, and a scene that is freed without being read
			# back leaves `Game` looking exactly as it does here.
			#
			# So the on-disk half is the real assertion: the autosave slot is
			# re-read from `user://` and counted independently.
			var wrgame := root.get_node_or_null(^"Game")
			if wrgame == null:
				return null
			var by_realm: Dictionary = {}
			for entry: Variant in (wrgame.get("placed_buildings") as Array):
				if typeof(entry) != TYPE_DICTIONARY:
					continue
				var wrealm := str((entry as Dictionary).get("realm", "meadows"))
				by_realm[wrealm] = int(by_realm.get(wrealm, 0)) + 1
			var disk: Dictionary = {}
			var wrsave: Variant = wrgame.get("save_system")
			if wrsave != null:
				var slot := int(wrgame.call("autosave_slot"))
				var wrpath := str(wrsave.call("slot_path", slot))
				var wrf := FileAccess.open(wrpath, FileAccess.READ)
				if wrf != null:
					var parsed: Variant = JSON.parse_string(wrf.get_as_text())
					wrf.close()
					if parsed is Dictionary:
						for entry: Variant in ((parsed as Dictionary).get("placed_buildings", []) as Array):
							if typeof(entry) != TYPE_DICTIONARY:
								continue
							var drealm := str((entry as Dictionary).get("realm", "meadows"))
							disk[drealm] = int(disk.get(drealm, 0)) + 1
					disk["_file"] = wrpath
			return {"live": by_realm, "disk": disk}
		"realm_shells":
			# The host's headless shells: which realms this process is
			# simulating for somebody else, what each cost to stand up, and
			# how many bodies are standing in it. Empty on a client and in
			# solo, which is itself the assertion in
			# `smoke_net_split_realms.gd`.
			var shgame := root.get_node_or_null(^"Game")
			if shgame == null or not shgame.has_method("realm_shell_report"):
				return null
			var shreport: Dictionary = shgame.call("realm_shell_report")
			shreport["vm_hwm_kb"] = _read_status_field_kb("VmHWM:")
			shreport["vm_rss_kb"] = _read_status_field_kb("VmRSS:")
			return shreport
		"session":
			# Wave 2 (lane 2.A): a real `scripts/net/session.gd` exists, so
			# every field here is read off it. `available` stays as the first
			# key a reader checks -- false now means "no Session node", not
			# "no Session API".
			var sess := _session()
			if sess == null:
				return {"available": false}
			return {
				"available": true,
				"active": bool(sess.call("is_active")),
				"mode": str(sess.call("mode")),
				"is_host": bool(sess.call("is_host")),
				"peer_id": int(sess.call("local_peer_id")),
				"peer_count": int(sess.call("peer_count")),
				"snapshot_ready": bool(sess.call("snapshot_ready")),
				"registry_fingerprint": int(sess.call("registry_fingerprint")),
				"rows": sess.call("peers"),
				# The port this peer was assigned by the harness, so a joining
				# peer can be told where to connect without the coordinator
				# having to remember what it handed out.
				"enet_port": _enet_port,
			}
		"storage":
			# Lane 3.D. Everything the concurrency smoke asserts on, read off
			# this peer's own live objects: the revision it would quote next,
			# what its chest node holds, what the world record holds, what its
			# satchel holds, and the verdict of its last transfer.
			var sgame := root.get_node_or_null(^"Game")
			if sgame == null or _storage_chest == null or not is_instance_valid(_storage_chest):
				return null
			var skey := str(_storage_chest.call("container_key"))
			var sindex := int(_storage_chest.call("placed_index"))
			var stransport: Node = sgame.get("ledger") as Node
			var sbook: Variant = stransport.get("ledger") if stransport != null else null
			var sstate: RefCounted = _storage_chest.get("state")
			return {
				"container": skey,
				"index": sindex,
				"revision": int((sbook as RefCounted).call("storage_revision", skey)) if sbook != null else -1,
				"chest": _storage_counts(sstate.get("inventory") if sstate != null else null),
				"record": _storage_record_counts(sgame, sindex),
				"satchel": _storage_counts(sgame.get("inventory") as RefCounted),
				"last": {
					"ok": bool(_storage_last.get("ok", false)),
					"pending": bool(_storage_last.get("pending", false)),
					"code": str(_storage_last.get("code", "")),
					"reason": str(_storage_last.get("reason", "")),
				},
				"refusals": _storage_refusals.duplicate(),
			}
		"pickup":
			# Lane 3.B. Everything the pickup-race smoke asserts on, read off
			# this peer's own live objects: whether the prop is still standing,
			# whether the WORLD says the find is claimed, what this peer's
			# satchel holds, and the verdict/refusals of its own press.
			var kgame := root.get_node_or_null(^"Game")
			if kgame == null:
				return null
			var kflag := ITEM_CACHE_PICKUP.flag_id(_pickup_item, _pickup_id, _pickup_realm)
			var kworld: Variant = kgame.get("world")
			var kflags: Variant = (kworld as RefCounted).get("flags") if kworld != null else null
			return {
				"id": _pickup_id,
				"item": _pickup_item,
				"flag": kflag,
				"standing": _pickup_node != null and is_instance_valid(_pickup_node),
				"claimed": kflags != null and bool((kflags as RefCounted).call("has", kflag)),
				"satchel": _storage_counts(kgame.get("inventory") as RefCounted),
				"press": _pickup_press,
				"refusals": _pickup_refusals.duplicate(true),
			}
		"farm":
			# Lane 6.E. Everything the farm-race smoke asserts on, read off this
			# peer's own live objects: which bed and which crop cycle, what the
			# WORLD says about the claim, what the bed's own record now holds,
			# what this peer's satchel holds, and its press/refusals.
			var fgame := root.get_node_or_null(^"Game")
			if fgame == null or _farm_index < 0:
				return null
			var fplot: Dictionary = fgame.call("farm_plot_at", _farm_index)
			return {
				"index": _farm_index,
				"crop": _farm_crop,
				"flag": str(_farm_node.call("claim_flag")) if _farm_node != null \
					and is_instance_valid(_farm_node) else "",
				"claimed": _farm_claimed(fgame),
				"state": FARM_LOGIC.state_of(fplot, int(fgame.get("day"))),
				"satchel": _storage_counts(fgame.get("inventory") as RefCounted),
				"press": _farm_press,
				"refusals": _farm_refusals.duplicate(true),
			}
		"trade":
			# Lane 3.E. Everything the trade smoke asserts on, read off this
			# peer's own live objects: what its satchel holds, what it is
			# drawing on the ground, the offer it has out or waiting, and the
			# refusals the host has sent it.
			var tgame := root.get_node_or_null(^"Game")
			if tgame == null:
				return null
			var toffer: Node = TRADE_OFFER.attach(tgame)
			return {
				"satchel": _storage_counts(tgame.get("inventory") as RefCounted),
				"dropped": _dropped_counts(),
				"outgoing": toffer.call("outgoing") if toffer != null else {},
				"incoming": toffer.call("incoming") if toffer != null else {},
				"last": {
					"ok": bool(_trade_last.get("ok", false)),
					"pending": bool(_trade_last.get("pending", false)),
					"code": str(_trade_last.get("code", "")),
					"reason": str(_trade_last.get("reason", "")),
				},
				"refusals": _trade_refusals.duplicate(),
			}
		"placed_building_count":
			var pgame := root.get_node_or_null(^"Game")
			if pgame == null:
				return null
			return (pgame.get("placed_buildings") as Array).size()
		"placed_building_rows":
			# Lane 3.C. The RECORDS, flattened so two processes can be compared
			# directly. What the world says is standing.
			var rgame := root.get_node_or_null(^"Game")
			if rgame == null:
				return null
			return _building_rows(rgame.get("placed_buildings"))
		"placed_building_nodes":
			# Lane 3.C. The live NODES, which is the other half: a record that
			# arrived but planted nothing means the delta reached `WorldState`
			# and not `build_placer.gd`, and the two failures look identical
			# from the record alone.
			var nout: Array = []
			for node in get_nodes_in_group("placed_building"):
				nout.append({
					"id": str(node.get_meta("building_id", "")),
					"index": int(node.get_meta("placed_index", -1)),
					"realm": str(node.get_meta("realm", "")),
				})
			return nout
		"saved_world_buildings":
			# Lane 3.C, the reload half. `placed_buildings` read back out of the
			# FILE the `save_world` step wrote -- not out of memory. A record
			# that is in the host's RAM but not in its save is a record that
			# does not survive a reload, which is the whole acceptance bar.
			var sgame2 := root.get_node_or_null(^"Game")
			if sgame2 == null:
				return null
			var ssys: Variant = sgame2.get("save_system")
			if ssys == null:
				return null
			var spath := str(ssys.call("slot_path", SAVE_SCRATCH_SLOT))
			if not FileAccess.file_exists(spath):
				return null
			var sf := FileAccess.open(spath, FileAccess.READ)
			if sf == null:
				return null
			var stext := sf.get_as_text()
			sf.close()
			var sparsed: Variant = JSON.parse_string(stext)
			if typeof(sparsed) != TYPE_DICTIONARY:
				return null
			return _building_rows((sparsed as Dictionary).get("placed_buildings", []))
		"autosave_exists":
			# D100's client-never-writes-the-world assertion. Reads the real
			# file under THIS peer's own XDG_DATA_HOME (contract §2), so a host
			# and a client can be compared directly.
			var agame := root.get_node_or_null(^"Game")
			if agame == null:
				return null
			var asave: Variant = agame.get("save_system")
			if asave == null:
				return null
			return FileAccess.file_exists(str(asave.call("slot_path", int(agame.call("autosave_slot")))))
		"worlds_dir_entries":
			# D100's `user://worlds/` -- the host-owned world save directory.
			# It does not exist for anybody yet (the split is a later lane), so
			# a client asserting 0 here is a FORWARD assertion: it is written
			# now so the day the host starts writing that directory, a client
			# that also starts writing it fails this smoke rather than shipping.
			if not DirAccess.dir_exists_absolute("user://worlds"):
				return []
			var listed: PackedStringArray = DirAccess.get_directories_at("user://worlds")
			return Array(listed)
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
## `null` on any failure -- NEVER `0`. `0` is a legal `hash()` output (astronomically
## unlikely but real), so a peer that could not produce a hash at all must be
## distinguishable from a peer whose real state happened to hash to zero. The
## coordinator (`net_harness.gd::_handle_peer_line`) treats a `null` heartbeat
## `state_hash` as `ERROR: state hash unavailable`, a harness fault (exit 2),
## never as a silent "hashes agree" or a quiet desync.
func _compute_state_hash() -> Variant:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return null
	var save_system: Variant = game.get("save_system")
	if save_system == null:
		return null
	if not bool(save_system.call("save", game, HASH_SCRATCH_SLOT)):
		return null
	var path := str(save_system.call("slot_path", HASH_SCRATCH_SLOT))
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var full: Dictionary = parsed
	# Allowlist, not exclude-list -- see HASHED_KEYS's own comment. `world_seed`
	# is not in either list: contract §7 (amended) says it is ERASED from the
	# hashed dictionary entirely and asserted separately against the pin
	# (`probe world_seed`, resolved through `spawn_tables.gd::resolve_seed()`
	# so it reads what every peer's spawns actually use, not the raw per-process
	# roll `game_state.gd::new_game()` stores -- see that probe's own comment).
	var data := {}
	for k in HASHED_KEYS:
		if full.has(k):
			data[k] = full[k]
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
