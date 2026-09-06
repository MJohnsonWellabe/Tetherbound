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
## Row 21's `party_grant`: the opening's own door into `Game.party`, and the
## level curve `adopt_starter()` reads for a starter.
const PARTY_SEAM := preload("res://scripts/story/party_seam.gd")
const NET_PROGRESSION := preload("res://scripts/creatures/progression.gd")
const NET_REWARDS := preload("res://scripts/net/encounter_rewards.gd")
## Wave 6 lanes 6.B/6.C. Riding and Fly.
const NET_RIDING := preload("res://scripts/world/riding_controller.gd")
const SPECIES_DATA := preload("res://scripts/creatures/creature_species.gd")

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

## Acceptance item 6. Everything this peer's own catch attempt produced, kept
## apart from the fight's own state on purpose: the LOSER of the race has no
## decision, no resolution and no orb -- only a refusal -- and a probe that read
## the outcome off the fight would report the same "nothing happened" for a
## loser and for a peer whose throw never left the harness.
var _catch_encounter_id: String = ""
var _catch_orb_id: String = "orb_basic"
var _catch_launch: Vector3 = Vector3.ZERO
var _catch_direction: Vector3 = Vector3.FORWARD
## "" (never threw), "answered" (the host is this process and arbitrated in the
## call), or "pending" (a client, waiting for the host). `pending` is NOT a
## refusal; see `_throw_orb()`.
var _catch_submit: String = ""
## The shape `submit_encounter_intent` handed back on this peer's own throw.
var _catch_local_verdict: Dictionary = {}
## `combat_manager.gd::catch_resolved` -- emitted only on the peer that actually
## played a decision, which is the winner and nobody else.
var _catch_resolutions: Array = []
## `catch_refused` sentences: what the player was shown.
var _catch_refusals: Array = []
## `caught_by_other` -- §8 step 4, the message every OTHER participant gets when
## somebody's catch lands.
var _catch_caught_by_other: Array = []


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
			# `data` is the one passthrough: a step that has a STRUCTURED
			# answer -- not just a verdict and a sentence -- puts it there and
			# it reaches `net_harness.gd::step()`'s return value intact. Added
			# for row 8, where a host striker's §5 refusal is the return value of
			# `submit_encounter_intent` and nothing else (finding F4), so the
			# smoke had no way to read `ok`/`pending`/`code` off the strike arm.
			# `{}` when a step names none, so every step written before this line
			# is byte-for-byte unchanged on the wire.
			_send({"type": "verdict", "id": msg.get("id", ""),
				"verdict": str(result.get("verdict", "ERROR")),
				"detail": str(result.get("detail", "")),
				"data": (result.get("data", {}) as Dictionary),
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
		"place_stand_in":
			out = await _step_place_stand_in(args)
		"party_grant":
			out = _step_party_grant(args)
		"save_character_here":
			out = _step_save_character_here(args)
		"wipe_character":
			out = _step_wipe_character(args)
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
		"menu_toggle":
			out = await _step_menu_toggle(args)
		"catch_throw":
			out = _step_catch_throw(args)
		"dismiss_dialogue":
			out = await _step_dismiss_dialogue(args)
		"ride_setup":
			out = await _step_ride_setup(args)
		"ride_mount":
			out = await _step_ride_mount(args)
		"ride_dismount":
			out = await _step_ride_dismount(args)
		"fly_setup":
			out = await _step_fly_setup(args)
		"fly_launch":
			out = await _step_fly_launch(args)
		"fly_land":
			out = await _step_fly_land(args)
		"fly_claim_anchor":
			out = await _step_fly_claim_anchor(args)
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
	# Same reason as `_compute_state_hash`: a scratch slot a smoke reads back is
	# not a save of record, so it does not write the D100 split.
	if not bool(save_system.call("save", game, SAVE_SCRATCH_SLOT, false)):
		return {"verdict": "FAIL", "detail": "save to slot %d refused" % SAVE_SCRATCH_SLOT}
	var path := str(save_system.call("slot_path", SAVE_SCRATCH_SLOT))
	return {"verdict": "PASS", "detail": "saved slot %d to %s" % [SAVE_SCRATCH_SLOT, path]}


## The subdirectory names under a D100 save root, sorted, or [] when the root
## does not exist. `DirAccess.get_directories_at` on a missing path pushes an
## error and returns nothing, and "the directory is not there" is exactly the
## answer a client is supposed to give -- not a harness fault.
func _save_dir_entries(root_path: String) -> Array:
	if not DirAccess.dir_exists_absolute(root_path):
		return []
	var listed: PackedStringArray = DirAccess.get_directories_at(root_path)
	var out: Array = Array(listed)
	out.sort()
	return out


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
	# Lane 7.A fix, kept, with lane 6.B's opt-out folded in AFTER it rather
	# than instead of it. The binding is POLLED, not read once.
	#
	# On the HOST the encounter record exists the moment the press lands, so a
	# single read was correct for every smoke written before this one -- all of
	# which engage from peer 0. On a CLIENT it cannot be: the intent goes to
	# the host, `submit()` answers `{"ok": false, "pending": true}`, and the
	# record comes back a round trip later. Reading `encounter_id()` once and
	# calling an empty string a failure is the "pending is not a refusal" trap,
	# and it reported as "a fight started but it is not bound to an encounter
	# record" -- which reads like the encounter protocol failing rather than
	# like this arm being host-only. Measured on
	# `smoke_net_host_exit_saves.gd`'s first client-side engage; see
	# MP-7A-RELIABILITY-0906 finding F2.
	#
	# A budget rather than a fixed wait so the host path still returns on its
	# first poll and costs nothing.
	#
	# `require_record` (lane 6.B, default TRUE so every older smoke is
	# byte-for-byte unchanged) only decides what happens when the budget is
	# SPENT. 6.B saw a client's engage never bind and passed false so a riding
	# lane would not report lane 4.C's red as its own; with the poll above, a
	# binding that merely arrives late now binds, and the escape hatch is only
	# reached when it genuinely never does. Either way the fact is REPORTED.
	var bind_budget := maxi(1, int(args.get("bind_budget_frames", 600)))
	var id := ""
	for i in bind_budget:
		id = str(manager.call("encounter_id"))
		if not id.is_empty():
			return {"verdict": "PASS", "detail": "engaged %s as encounter %s (bound after %d frame(s))"
				% [str(body.get("species_id")), id, i]}
		if not bool(manager.call("is_fighting")):
			return {"verdict": "FAIL",
				"detail": "the fight ended before it was ever bound to an encounter record"}
		await physics_frame
	if not bool(args.get("require_record", true)):
		return {"verdict": "PASS",
			"detail": "engaged %s; fight running, NO encounter record bound within %d frames"
				% [str(body.get("species_id")), bind_budget]}
	return {"verdict": "FAIL",
		"detail": "a fight started but it was never bound to an encounter record within %d frames"
			% bind_budget}


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
	#
	# `exact` skips that query and uses the literal coordinates. Added for the
	# boss smoke, where the caller's Y comes off the encounter record -- the
	# opponent's OWN height, host truth -- and asking the world for a different
	# one is the thing that goes wrong: inside the stronghold the terrain height
	# under the Warden Arena is metres away from the floor the fight is standing
	# on, and both creatures were placed 6-8 m above the boss (finding F2).
	# OFF by default, so every caller written before this line is unchanged.
	if bool(args.get("exact", false)):
		node.global_position = target
	elif node.has_method("place_on_ground"):
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


## Stage B row 8. Move this peer's OWN LOCAL stand-in for the opponent.
##
## A joiner in a fight it did not start is fighting beside a body of its own:
## `encounter_director.gd::join_encounter()` binds the manager to
## `nearest_live_wild()`, whichever ambient creature happens to be closest to the
## joining player. Wild bodies are not replicated (the acceptance file's first
## known-open, lane 4.B's H1), so that stand-in can be ten metres from where the
## host holds the real opponent -- and the joiner's own combat manager keeps
## pulling its creature back to it, which is what makes a deliberately-placed
## creature drift away from the fight it is supposed to be swinging at.
##
## This arm moves the stand-in to where the host says the opponent is, so the
## joiner's LOCAL view agrees with the host's. It changes nothing about any
## outcome: `MP_ENCOUNTER_PROTOCOL.md` §2 resolves every strike against HOST
## positions, which is exactly what keeps the drift cosmetic in the first place.
## It is the thing wild replication will do for free when it lands, done by hand
## in the meantime so a smoke's geometry is not a lottery over which ambient
## creature stood nearest.
##
## Deliberately NOT a way to move the HOST's opponent: on the host this body IS
## the authoritative one, so the step refuses there rather than quietly letting a
## smoke teleport the creature everyone is fighting.
func _step_place_stand_in(args: Dictionary) -> Dictionary:
	var manager := _combat_manager()
	if manager == null:
		return {"verdict": "ERROR", "detail": "no CombatManager in this scene"}
	var sess := _session()
	if sess != null and bool(sess.call("is_active")) and bool(sess.call("is_host")):
		return {"verdict": "ERROR",
			"detail": "this peer is the HOST -- its opponent body is the authoritative one, "
				+ "and this arm only moves a joiner's local stand-in"}
	var body: Variant = manager.call("enemy_body")
	if body == null or not is_instance_valid(body):
		return {"verdict": "FAIL", "detail": "this peer has no opponent body to move"}
	var at: Array = args.get("at", []) as Array
	if at.size() != 3:
		return {"verdict": "ERROR", "detail": "place_stand_in needs args.at = [x, y, z]"}
	var node: Node3D = body
	node.global_position = Vector3(float(at[0]), float(at[1]), float(at[2]))
	if node is CharacterBody3D:
		(node as CharacterBody3D).velocity = Vector3.ZERO
	# `home` too, or the wild wanders straight back to where it was standing:
	# `wild_creature.gd`'s peaceful tick returns it to `home` and the combat tick
	# repositions around it.
	if node.get("home") != null:
		node.set("home", node.global_position)
	for i in maxi(0, int(args.get("settle", 20))):
		await physics_frame
	var p: Vector3 = node.global_position
	return {"verdict": "PASS", "detail": "local stand-in '%s' stands at (%.2f, %.2f, %.2f)"
		% [str(node.name), p.x, p.y, p.z]}


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
	# The LOCAL verdict, reported as fields and not only inside the detail
	# string. On a HOST striker `submit_encounter_intent` commits synchronously
	# and the answer -- including a §5 refusal -- is this return value; only a
	# CLIENT's answer arrives later through `note_encounter_refusal`, which is
	# what the `encounter`/`boss` probes' `refusal` reads. A smoke asserting on a
	# host's refusal had nowhere to read it (row 8, finding F4).
	#
	# `pending` is carried through verbatim. A client's `{"ok": false, "pending":
	# true}` is the host being asked, NOT the host saying no, and collapsing the
	# two is how a "refused" is reported that never happened.
	return {"verdict": "PASS", "detail": "submitted %s strike (local verdict ok=%s pending=%s code=%s)"
		% [slot, str(verdict.get("ok", false)), str(verdict.get("pending", false)),
		   str(verdict.get("code", ""))],
		"data": {
			"ok": bool(verdict.get("ok", false)),
			"pending": bool(verdict.get("pending", false)),
			"code": str(verdict.get("code", "")),
			"reason": str(verdict.get("reason", "")),
		}}


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
## Who is holding the screen, as `sequence_director.gd::_refresh_lockout()`
## itself asks it. Read-only and defensive: every field is absent rather than
## guessed when the node that answers for it is missing.
func _lockout_report() -> Dictionary:
	var out := {}
	var director := _sequence_director()
	if director != null:
		out["fading"] = director.has_method("is_fading") and bool(director.call("is_fading"))
		out["adopting"] = bool(director.get("_adopting"))
		var dialogue: Variant = director.get("_dialogue")
		out["dialogue"] = dialogue != null and (dialogue as Object).has_method("is_open") \
			and bool((dialogue as Object).call("is_open"))
		var picker: Variant = director.get("_starter_picker")
		out["picker"] = picker != null and (picker as Object).has_method("is_open") \
			and bool((picker as Object).call("is_open"))
		var prompt: Variant = director.get("_name_prompt")
		out["name_prompt"] = prompt != null and (prompt as Object).has_method("is_open") \
			and bool((prompt as Object).call("is_open"))
		out["beat"] = str(director.get("_beat"))
	var manager := _combat_manager()
	out["fighting"] = manager != null and bool(manager.call("is_fighting"))
	var encounter := _encounter_director()
	out["trainer_battle"] = encounter != null and encounter.has_method("trainer_battle_active") \
		and bool(encounter.call("trainer_battle_active"))
	var game := root.get_node_or_null(^"Game")
	out["pending_build"] = str(game.get("pending_build")) if game != null else ""
	var downed := _downed_state()
	out["downed"] = downed != null and downed.has_method("is_downed") and bool(downed.call("is_downed"))
	return out


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
	## Stop EARLY, with the named number of their creatures still queued, rather
	## than fighting the whole team down. -1 (the default) fights to the end, so
	## every caller written before this line runs the fight it ran.
	##
	## `smoke_net_shared_boss.gd` needs this because §10 scaling is applied at
	## SEND-OUT (`encounter_director.gd::_send_next_trainer_creature`), so the
	## creature that was already on the field when a second player joined is not
	## scaled -- the record's row is re-derived, the body's stats are not. To
	## assert scaling at two participants the smoke has to reach a creature that
	## came out AFTER the join, which is the boss's second.
	var stop_at := int(args.get("stop_when_creatures_left", -1))
	while bool(director.call("trainer_battle_active")) and frames < budget:
		await physics_frame
		frames += 1
		if not bool(manager.call("is_fighting")):
			# The beat between their creatures. Nothing to do but let it pass.
			continue
		# Checked BEFORE the ceiling below, so an early stop hands the caller a
		# creature at full health rather than one already pulled down to it.
		if stop_at >= 0 and int(director.call("trainer_creatures_left")) <= stop_at:
			return {"verdict": "PASS",
				"detail": "stopped with %d of their creatures still queued after %d frames / %d swings"
					% [int(director.call("trainer_creatures_left")), frames, swings]}
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
		# `smoke_boss.gd`'s own allowance, for its own stated reason and with the
		# same words: "the opponent's HP is pulled low so a level-1 starter can
		# finish a level-20 ace inside a CI budget: this test is about WIRING,
		# not balance." A headless peer fights with the starter
		# `deploy_creature` adopted, and the Warden fields five creatures at
		# levels 18-20; measured without this, see MP-ROWS-8-21-0906 finding F3.
		#
		# OFF by default (0.0), so every caller that existed before this line --
		# row 7's trainer payout among them -- runs the fight it ran.
		#
		# It touches `hp`, never `max_hp`, and a smoke asserting on §10 scaling
		# must therefore read `max_hp`/`attack`/`defence` BEFORE calling this
		# arm. `smoke_net_shared_boss.gd` does, and says so.
		var ceiling := float(args.get("enemy_hp_ceiling", 0.0))
		if ceiling > 0.0:
			var theirs: Variant = (opponent as Node3D).get("instance")
			if theirs != null and float((theirs as RefCounted).get("hp")) > ceiling:
				(theirs as RefCounted).set("hp", ceiling)
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


## Row 21. What this process holds in MEMORY for the local character: the party
## as `<species>@<level>` rows, the WHOLE satchel, and the PLAYER-scoped flags
## named by the caller.
##
## The party is reported as species+level rather than as a count. A count of 1
## before and 1 after would pass a restore that came back with somebody else's
## creature, and "the same character" is the row.
##
## The satchel is the whole thing, not a list of named items, so the comparison
## against the file is total. Read through `gate_f_probe.gd::inventory_snapshot`
## -- id -> count over every occupied slot -- for the reason that file exists:
## one definition of "what is this peer carrying", shared with every other
## smoke.
##
## The flags asked about are checked against `Game.local.flags` -- the PLAYER
## half -- and NOT against `Game.progression`, the merged view. A world flag
## reaches every peer through the host's snapshot, so reading the merged view
## would let a world flag stand in for the player-scoped one the character file
## is supposed to carry.
func _character_view(game: Node, args: Dictionary) -> Dictionary:
	var local: Variant = game.get("local")
	if local == null:
		return {}
	var party_rows: Array = []
	var party: Variant = (local as RefCounted).get("party")
	if party != null:
		for i in int((party as RefCounted).call("size")):
			var member: Variant = (party as RefCounted).call("at", i)
			if member != null:
				party_rows.append("%s@%d" % [str((member as RefCounted).get("species_id")),
					int((member as RefCounted).get("level"))])
	var flags_set: Dictionary = {}
	var flags: Variant = (local as RefCounted).get("flags")
	for flag: Variant in args.get("flags", []):
		flags_set[str(flag)] = flags != null and bool((flags as RefCounted).call("has", str(flag)))
	return {
		"party": party_rows,
		"party_size": party_rows.size(),
		"satchel": _probe.call("inventory_snapshot"),
		"player_flags": flags_set,
		"display_name": str((local as RefCounted).get("display_name")),
		"satiety": float((local as RefCounted).get("satiety")),
	}


## Row 21. The same things, read out of `character_save.gd::state()` -- i.e. out
## of the FILE -- in the same shape, so the smoke compares like with like
## instead of comparing a shape to a claim.
##
## `state()`'s `party` and `inventory` are the SAVED rows, not live objects, so
## both are read off dictionaries. A saved stack is `{"id", "n"}` --
## `autoload/inventory.gd`'s own shape, which `save_game.gd::_stack_from_json`
## round-trips verbatim -- and NOT `{"item_id", "count"}`; reading the wrong
## pair here would report an empty satchel for a full one, which fails in the
## direction that looks like the feature being broken.
func _character_file_view(state: Dictionary, args: Dictionary) -> Dictionary:
	var party_rows: Array = []
	for raw: Variant in (state.get("party", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var row := raw as Dictionary
		party_rows.append("%s@%d" % [str(row.get("species_id", "")), int(row.get("level", 0))])
	var satchel: Dictionary = {}
	for raw: Variant in (state.get("inventory", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var stack := raw as Dictionary
		var id := str(stack.get("id", ""))
		if id.is_empty():
			continue
		satchel[id] = int(satchel.get(id, 0)) + int(stack.get("n", 0))
	var held: Array = []
	var raw_flags: Variant = state.get("flags", {})
	if typeof(raw_flags) == TYPE_DICTIONARY:
		var ids: Variant = (raw_flags as Dictionary).get("flags", [])
		if typeof(ids) == TYPE_ARRAY:
			held = ids as Array
	var flags_set: Dictionary = {}
	for flag: Variant in args.get("flags", []):
		flags_set[str(flag)] = held.has(str(flag))
	return {
		"party": party_rows,
		"party_size": party_rows.size(),
		"satchel": satchel,
		"player_flags": flags_set,
		"display_name": str(state.get("display_name", "")),
		"satiety": float(state.get("satiety", -1.0)),
	}


## Row 21. Put a creature in this peer's PARTY, through the seam the opening
## itself uses.
##
## `deploy_creature` is not this: it calls `adopt_starter()`, which spawns the
## ally BODY and sets `_ally`, and never touches `Game.party` -- the opening adds
## the chosen creature separately, through `party_seam.gd`. Measured on row 21's
## first run: a peer that had "deployed its own creature" still reported a party
## of zero, so a reconnect smoke asserting on the party had nothing to assert on.
##
## `party_seam.gd::add()` is that separate door and its own header calls itself
## "the one place the opening sequence touches the party", so this is the
## production path and not a poke at `autoload/party.gd`. The instance is built
## the way `adopt_starter()` builds one -- `SPECIES.spawn()` then `set_level()` at
## `progression.json`'s own `starter_level` -- so what lands in the party is an
## ordinary creature of the kind the game hands out, not a hand-assembled one.
##
## The five-creature rule is untouched: `party.add()` is what enforces it and it
## is the thing being called, so a sixth is refused here exactly as it is
## refused everywhere else, and the refusal is reported.
func _step_party_grant(args: Dictionary) -> Dictionary:
	var species := str(args.get("species", "bramblebun"))
	var creature: RefCounted = SPECIES_DATA.spawn(species)
	if creature == null:
		return {"verdict": "ERROR", "detail": "species.json has no '%s'" % species}
	var cfg: Dictionary = NET_PROGRESSION.config()
	var level := int(args.get("level",
		int((cfg.get("level", {}) as Dictionary).get("starter_level", 3))))
	creature.call("set_level", level, cfg)
	if not bool(PARTY_SEAM.add(creature, str(args.get("nickname", "")))):
		return {"verdict": "FAIL",
			"detail": "party_seam.add('%s') refused -- the party is full (five, and there is no sixth slot)"
				% species}
	var game := root.get_node_or_null(^"Game")
	var party: Variant = game.get("party") if game != null else null
	var size := int((party as RefCounted).call("size")) if party != null else -1
	if not PARTY_SEAM.has_game_state():
		return {"verdict": "FAIL",
			"detail": "party_seam is running on its FALLBACK array, not Game.party -- "
				+ "a creature added here would never reach the real party"}
	return {"verdict": "PASS", "detail": "'%s' at level %d joined the party (%d member(s))"
		% [species, level, size]}


## Row 21. Write this peer's own save through the production autosave door.
##
## `Game.autosave_here()` and nothing hand-rolled: D100 routes there, and on a
## client it is exactly `session.gd::_save_character_here()` -- the call a real
## disconnect makes. A step that called `save_character()` itself would be
## testing this file's idea of how a character is written rather than the
## game's.
func _step_save_character_here(_args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var local: Variant = game.get("local")
	var character_id := str((local as RefCounted).get("character_id")) if local != null else ""
	var wrote_world := bool(game.call("autosave_here"))
	var save_system: Variant = game.get("save_system")
	var on_disk := false
	if save_system != null and not character_id.is_empty():
		var characters: Variant = (save_system as RefCounted).call("characters")
		on_disk = characters != null and bool((characters as RefCounted).call("has", character_id))
	if not on_disk:
		return {"verdict": "FAIL",
			"detail": "autosave_here() left no character file for '%s' (wrote_world=%s)"
				% [character_id, str(wrote_world)]}
	return {"verdict": "PASS", "detail": "character '%s' is on disk (wrote_world=%s)"
		% [character_id, str(wrote_world)]}


## Row 21. Install a BLANK character over the top of this process's own, in
## memory only, leaving the file on disk alone.
##
## This is the step that makes the reconnect assertion falsifiable. Lane 7.A's
## smoke asserted that a rejoiner's party was unchanged, and that was true
## because the process never restarted and never lost it -- its own header says
## so. After this step the process holds nothing, so a party that comes back
## after the rejoin can only have come off the file.
##
## `PlayerState.load_data({})` and not a hand-written clear: it is the game's
## own loader, so what is left behind is exactly the blank character a freshly
## booted process holds (`_array_to_party`/`_array_to_inventory` both clear
## before they fill, `flags.load_data({})` empties the player half, satiety
## returns to 100, the pose and maps empty). `character_id` is deliberately
## preserved -- `load_data` defaults it to the current value when the payload
## names none -- because the id is how the rejoin finds the file, and a harness
## that wiped it would be testing nothing.
func _step_wipe_character(_args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var local: Variant = game.get("local")
	if local == null:
		return {"verdict": "ERROR", "detail": "no Game.local to wipe"}
	var party: Variant = (local as RefCounted).get("party")
	var before := int((party as RefCounted).call("size")) if party != null else -1
	var character_id := str((local as RefCounted).get("character_id"))
	(local as RefCounted).call("load_data", {})
	var after := int((party as RefCounted).call("size")) if party != null else -1
	var kept := str((local as RefCounted).get("character_id"))
	if kept != character_id:
		return {"verdict": "FAIL", "detail": "the wipe lost the character id ('%s' -> '%s')"
			% [character_id, kept]}
	return {"verdict": "PASS",
		"detail": "in-memory character blanked (party %d -> %d), id '%s' kept, file untouched"
			% [before, after, kept]}


func _progression_store() -> RefCounted:
	var game := root.get_node_or_null(^"Game")
	return game.get("progression") as RefCounted if game != null else null



# --- acceptance item 16 (D102): a menu does not freeze other players ----------
#
# One arm and one probe. The arm presses the REAL button on the REAL pause
# shell; the probe reads `SceneTree.paused` at the source. Nothing here opens a
# panel by calling `open()`, for the reason `tests/smoke_menu.gd`'s own header
# gives: calling the method proves the method works, not that the button
# reaches it.

## Open or close `Game.menu()` with its configured button, and prove it landed.
##
## Deliberately NOT `_step_press`. `_inject`'s own header records that this file
## puts the PHYSICS frame first because every gameplay action `peer_runner.gd`
## drives (`jump`, movement, `interact`) is polled from `_physics_process`, and
## that a menu polled from `_process` needs the opposite ordering -- "if a
## menu-focused action needs this file later, gate the idle-frame placement on
## the control rather than reverting this wholesale". This is that gate:
## `game_menu.gd::_read_actions()` is called from `_process` (line 523) and
## reads `Input.is_action_just_pressed` for BOTH `open_action` and
## `close_action`, so an idle frame has to come first or the just-pressed flag
## has already expired by the time the shell looks.
##
## The verdict is read off `is_open()` rather than off the injection returning
## ok: a press that was delivered and ignored is exactly the failure this arm
## exists to catch.
func _step_menu_toggle(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null or not game.has_method("menu"):
		return {"verdict": "ERROR", "detail": "no /root/Game with a menu()"}
	var menu: Variant = game.call("menu")
	if menu == null:
		return {"verdict": "ERROR", "detail": "the Game autoload stood up no menu"}
	var shell: Node = menu
	var want := bool(args.get("open", true))
	if bool(shell.call("is_open")) == want:
		return {"verdict": "PASS",
			"detail": "the menu was already %s" % ("open" if want else "shut")}
	var action := str(args.get("action", "game_menu" if want else "menu_cancel"))
	# B is the BACK button, not a close button: `game_menu.gd`'s own comment on
	# `close_action` says so, and `data/config/menu.json` binds `menu_cancel` to
	# it. A tab that has taken the screen for itself -- the Backpack tab's drop
	# target picker is the one this smoke walks into, because holding the stick
	# inside the shell is exactly what a player who forgot the panel was up
	# does -- consumes the first press to back out of ITSELF, and the shell
	# never sees it. So this presses like a player leaving a menu: again, until
	# it is out, up to `presses`. Opening needs one and takes one.
	var presses := maxi(1, int(args.get("presses", 1 if want else 3)))
	var within := maxi(1, int(args.get("within_frames", 90)))
	for attempt in presses:
		var down := _press_edge(action, true)
		if not bool(down.get("ok", false)):
			return {"verdict": "ERROR", "detail": "could not inject '%s': %s"
				% [action, str(down.get("why", ""))]}
		await process_frame
		await physics_frame
		_press_edge(action, false)
		for i in within:
			await process_frame
			await physics_frame
			if bool(shell.call("is_open")) == want:
				return {"verdict": "PASS",
					"detail": "the menu is %s %d frames after press %d of '%s' (context '%s', tree paused=%s)"
						% ["open" if want else "shut", i + 1, attempt + 1, action,
							str(_probe.call("input_context")), str(paused)]}
	return {"verdict": "FAIL",
		"detail": "%d press(es) of '%s' did not %s the menu within %d frames each (it is still %s, context '%s')"
			% [presses, action, "open" if want else "close", within,
				"open" if bool(shell.call("is_open")) else "shut",
				str(_probe.call("input_context"))]}


# --- acceptance item 6: the first-successful-catch rule, over the wire --------
#
# Two arms and one probe, and they are the `pickup_take` pattern applied to a
# fight: the coordinator awaits each verdict before sending the next, so two
# "throw now" messages are always a round trip apart and the race the item is
# about cannot form. `at_unix_ms` ARMS the throw and answers immediately, so
# both peers can be armed and then both throw at one shared wall-clock instant
# (one machine, contract §2). Lane 3.B's answer, reused rather than reinvented.

## Start listening for everything a catch can tell this peer, before either
## throw. Idempotent, and separate from the throw so a peer that LOSES -- and
## therefore never plays a decision -- is still listening when the winner's
## `caught_by` arrives.
func _catch_watch() -> void:
	var manager := _combat_manager()
	if manager == null:
		return
	if not manager.is_connected("catch_resolved", _on_catch_resolved):
		manager.connect("catch_resolved", _on_catch_resolved)
	if not manager.is_connected("catch_refused", _on_catch_refused):
		manager.connect("catch_refused", _on_catch_refused)
	if not manager.is_connected("caught_by_other", _on_caught_by_other):
		manager.connect("caught_by_other", _on_caught_by_other)


func _on_catch_resolved(success: bool, shakes: int) -> void:
	_catch_resolutions.append({"caught": success, "shakes": shakes})


func _on_catch_refused(reason: String) -> void:
	_catch_refusals.append(reason)


func _on_caught_by_other(peer_id: int, species_id: String) -> void:
	_catch_caught_by_other.append({"peer": peer_id, "species": species_id})


## Throw an orb at the fight's opponent, through the one door
## `combat_manager.gd` itself submits catches through
## (`_submit_catch_attempt` -> `submit_encounter_intent`). Same precedent as
## `_step_strike`: the harness supplies what a controller supplies -- where the
## throw left the hand, which way it went, and which orb was spent -- and
## nothing that decides the outcome. The host re-derives the closest approach
## against its OWN position for the creature and rolls with its own `_rng`
## (`catch_arbiter.gd`), so nothing here can buy this peer a catch.
##
## The one thing this arm sets that a real throw would have set already is
## `_catch_awaiting_host`. `_on_orb_struck()` sets it on the way into
## `_submit_catch_attempt()`, and `apply_host_catch_verdict()` drops any answer
## that arrives while it is false -- so without it the host's reply would be
## discarded and the smoke would measure silence on both peers. A real orb
## flight cannot be driven headlessly (`throw_aim.gd` needs an aim, a wind-up
## and a projectile); the ARBITRATION is what item 6 is about, and everything
## from `submit_encounter_intent` onward is the shipping path.
##
## `args.at_unix_ms` arms instead of throwing. `args.target` is where the
## thrower aimed, which the coordinator reads off the HOST's record so both
## peers aim at the same creature.
func _step_catch_throw(args: Dictionary) -> Dictionary:
	var director := _encounter_director()
	var manager := _combat_manager()
	if director == null or manager == null:
		return {"verdict": "ERROR", "detail": "no EncounterDirector/CombatManager"}
	var id := str(manager.call("encounter_id"))
	if id.is_empty():
		return {"verdict": "FAIL", "detail": "this peer is not in a networked fight"}
	var player := _probe.call("player") as Node3D
	if player == null:
		return {"verdict": "ERROR", "detail": "no live player to throw from"}
	var aim: Array = args.get("target", []) as Array
	if aim.size() != 3:
		return {"verdict": "ERROR", "detail": "catch_throw needs args.target = [x, y, z]"}
	_catch_watch()
	_catch_orb_id = str(args.get("orb_id", "orb_basic"))
	# `throw.spawn_height` / `spawn_forward` from data/config/catching.json, so
	# the launch point is the one a real throw would have had.
	_catch_launch = player.global_position + Vector3(0.0, 1.5, 0.0)
	var toward := Vector3(float(aim[0]), float(aim[1]), float(aim[2])) - _catch_launch
	if toward.length_squared() <= 0.000001:
		return {"verdict": "ERROR", "detail": "catch_throw target is the launch point"}
	_catch_direction = toward.normalized()
	_catch_encounter_id = id
	var at := float(args.get("at_unix_ms", 0.0))
	if at > 0.0:
		_throw_orb_at.call_deferred(at)
		return {"verdict": "PASS", "detail": "armed a throw at %s for %.0f" % [id, at]}
	return _throw_orb()


## Hold until the shared instant, then throw. Detached (`call_deferred`) so the
## arming step can answer the coordinator straight away; it keeps running
## because each `await physics_frame` resumes it off the tree's own signal.
func _throw_orb_at(at_unix_ms: float) -> void:
	while Time.get_unix_time_from_system() * 1000.0 < at_unix_ms:
		await physics_frame
	_throw_orb()


func _throw_orb() -> Dictionary:
	var director := _encounter_director()
	var manager := _combat_manager()
	if director == null or manager == null:
		_catch_submit = "no_manager"
		return {"verdict": "ERROR", "detail": "no EncounterDirector/CombatManager"}
	manager.set("_catch_awaiting_host", true)
	var verdict: Dictionary = director.call("submit_encounter_intent", {
		"kind": "catch_attempt",
		"encounter_id": _catch_encounter_id,
		"launch_point": [_catch_launch.x, _catch_launch.y, _catch_launch.z],
		"direction": [_catch_direction.x, _catch_direction.y, _catch_direction.z],
		"orb_id": _catch_orb_id,
	})
	_catch_local_verdict = {
		"ok": bool(verdict.get("ok", false)),
		"pending": bool(verdict.get("pending", false)),
		"code": str(verdict.get("code", "")),
		"reason": str(verdict.get("reason", "")),
		"caught": bool((verdict.get("delta", {}) as Dictionary).get("caught", false)),
	}
	# `pending` is NOT a refusal -- it is what a client's `submit()` returns
	# while the host answers, and the answer lands later on
	# `apply_host_catch_verdict()` through `_deliver_encounter_verdict`. Only
	# the host's own throw is answered here and now, exactly as
	# `combat_manager.gd::_submit_catch_attempt()` does it.
	_catch_submit = "pending" if bool(verdict.get("pending", false)) else "answered"
	if not bool(verdict.get("pending", false)):
		manager.call("apply_host_catch_verdict", verdict)
	return {"verdict": "PASS", "detail": "threw at %s (ok=%s pending=%s code=%s)"
		% [_catch_encounter_id, str(verdict.get("ok", false)),
			str(verdict.get("pending", false)), str(verdict.get("code", ""))]}
# --- Wave 6 lanes 6.B and 6.C: riding and Fly, with everybody else still playing
#
# Seven arms and two probes. Everything they touch is shipping code: the mount
# is `riding_controller.gd::mount()` (the same call the interact press makes,
# with the same refusals), the launch is the real second-airborne-Jump the
# player makes, and the landing anchor goes through the real client->host
# round trip. What the harness supplies is what a PLAYER would have supplied
# by playing for two hours -- the creature in the party, the saddle in the
# satchel, the Fly unlock -- and every one of those is SETUP, granted
# explicitly and named as such below.
#
# THE SETUP RULE, and why it is written out here rather than assumed. Lane
# 6.A's two smokes never granted Cloudreach's realm key and then reported
# "enter_realm refused", which reads as though realm shells had failed
# outright when what had actually failed was the fixture. So: every grant
# below is a `SETUP` line in its own detail string, and every step that
# CANNOT run because its setup did not take returns a detail that says which
# grant is missing -- never a bare refusal that reads like the feature.

## SETUP, and a reproduction of a finding this lane did not fix.
##
## MEASURED, three local runs of `tests/smoke_net_fly.gd` deep. A peer that
## JOINS a session boots into the opening's `house` beat holding an OPEN
## DIALOGUE BOX, and never closes it. `sequence_director._refresh_lockout()`
## reads that box as a panel every frame, and a panel is modal, so it calls
## `set_locomotion_enabled(false)` every frame for the rest of the session. The
## client can then neither walk nor jump: it is not slow, it is switched off.
## The probe row that pinned it, off the joining peer:
##
##     locomotion=false carried=false on_floor=true
##     lockout={"beat":"house","dialogue":true,"adopting":false,"fading":false,
##              "picker":false,"name_prompt":false,"fighting":false}
##
## That is the opening sequence on a joining client, which belongs to Wave 2/5
## and not to riding or Fly, so it is recorded rather than fixed
## (`ralph/reports/MP-6BC-RIDING-FLY-0906/REPORT.md`, finding F2). It also
## explains the divergence `tests/smoke_net_movement_two_peers.gd`'s own
## constant block records and calls "not understood": the host walks out and
## the client does not, because on the client locomotion was never on.
##
## What this step does is what a PLAYER does with a dialogue box: presses
## `interact` until it is gone. That is the production advance
## (`dialogue_panel.gd::_physics_process`), not a state poke, and it is bounded
## -- a box that will not close is reported as such rather than pressed at
## forever.
func _step_dismiss_dialogue(args: Dictionary) -> Dictionary:
	var detail := await _clear_open_dialogue(int(args.get("presses", 40)))
	for f in maxi(0, int(args.get("settle", 30))):
		await physics_frame
	var player := _probe.call("player") as Node3D
	return {"verdict": "FAIL" if detail.begins_with("STUCK") else "PASS",
		"detail": "SETUP: %s; locomotion now %s"
			% [detail, str(player.call("locomotion_enabled")) if player != null else "?"]}


## Press `interact` until the opening's dialogue box is gone, and say what
## happened. Called from `_step_dismiss_dialogue` and from the two Fly steps
## that CANNOT work while it is open -- the box opens partway through the
## `house` beat rather than at boot, so clearing it once after the handshake is
## not enough and the clear has to sit next to the thing it is a precondition
## for.
func _clear_open_dialogue(presses_allowed: int) -> String:
	var director := _sequence_director()
	if director == null:
		return "no SequenceDirector here; nothing holding the screen"
	var dialogue: Variant = director.get("_dialogue")
	if dialogue == null or not (dialogue is Object) or not (dialogue as Object).has_method("is_open"):
		return "no dialogue panel to close"
	var panel := dialogue as Object
	if not bool(panel.call("is_open")):
		return "no dialogue box was open"
	var presses := 0
	for i in maxi(1, presses_allowed):
		if not bool(panel.call("is_open")):
			break
		await _press_edge("interact", true)
		for f in 2:
			await physics_frame
		await _press_edge("interact", false)
		for f in 6:
			await physics_frame
		presses += 1
	if bool(panel.call("is_open")):
		return "STUCK: the opening dialogue would not close after %d interact presses (beat '%s')" \
			% [presses, str(director.get("_beat"))]
	return "closed the opening dialogue in %d presses" % presses


## SETUP. Put the mount in this peer's party, bring it out, and put the saddle
## in the satchel. None of this is the thing under test: a player reaches it by
## catching a Meadowhart and winning the tournament that unlocks the saddle
## recipe (D48 SS4), which a two-peer smoke is not going to play through.
##
## The one thing it deliberately does NOT do is fit the saddle. Fitting is
## `mount()`'s own job (OP-0904-3: getting on IS putting it on), so a smoke
## that pre-fitted it would be testing a state the game never reaches by
## itself.
func _step_ride_setup(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	var director := _encounter_director()
	if game == null or director == null:
		return {"verdict": "ERROR", "detail": "no /root/Game or EncounterDirector in this scene"}
	var species := str(args.get("species", "meadowhart"))
	if not SPECIES_DATA.is_rideable(species):
		return {"verdict": "ERROR",
			"detail": "SETUP: species.json says '%s' is not rideable" % species}
	var party: RefCounted = game.get("party")
	var satchel: RefCounted = game.get("inventory")
	if party == null or satchel == null:
		return {"verdict": "ERROR", "detail": "no Game.party or Game.inventory"}
	# SETUP: the tack. `_has_tack()` counts it in the satchel, so a missing
	# grant would refuse the mount for a reason that is about the fixture.
	var required := str(SPECIES_DATA.rideable(species).get("requires_item", ""))
	if not required.is_empty():
		satchel.call("add", required, 1)
	# SETUP: the animal. Whatever the opening left standing beside this trainer
	# is not the species under test, so it is put away first -- the same order
	# `tests/smoke_riding.gd::_put_the_mount_in_the_world()` uses.
	if director.call("ally_body") != null:
		director.call("dismiss_active_creature")
		for i in 20:
			await physics_frame
	var mount: RefCounted = SPECIES_DATA.spawn(species)
	if mount == null or not bool(party.call("add", mount)):
		return {"verdict": "FAIL",
			"detail": "SETUP failed: could not put a %s in this peer's party" % species}
	for i in int(party.call("size")):
		if party.call("at", i) == mount:
			party.call("set_active", i)
			break
	if party.call("active") != mount:
		return {"verdict": "FAIL",
			"detail": "SETUP failed: the party would not make the %s active" % species}
	if director.call("ally_body") == null:
		await director.call("summon_active_creature")
	for i in maxi(0, int(args.get("settle", 90))):
		await physics_frame
		var standing: Variant = director.call("ally_body")
		if standing != null and is_instance_valid(standing) and (standing as Node3D).visible:
			break
	var body: Variant = director.call("ally_body")
	if body == null or not is_instance_valid(body):
		return {"verdict": "FAIL",
			"detail": "SETUP failed: the %s never appeared in this peer's world" % species}
	return {"verdict": "PASS",
		"detail": "SETUP: %s standing as %s, %s in the satchel"
			% [species, str((body as Node).name), required if not required.is_empty() else "no tack needed"]}


## Get on. The production door, with the production refusals -- `mount()`
## returns false for no saddle, a fainted mount, a running fight and a mount
## out of reach, and every one of those is a real answer rather than a harness
## failure, so a false is reported with the reason the game itself would give.
func _step_ride_mount(args: Dictionary) -> Dictionary:
	var riding := _riding_controller()
	if riding == null:
		return {"verdict": "ERROR", "detail": "no RidingController in this scene"}
	var director := _encounter_director()
	var body: Variant = director.call("ally_body") if director != null else null
	if body == null or not is_instance_valid(body):
		return {"verdict": "FAIL",
			"detail": "SETUP incomplete: this peer has no creature out to ride (run ride_setup)"}
	# Stand the trainer next to their own animal. `MOUNT_RADIUS` is 4.5 m and a
	# summoned creature normally lands well inside that, but a peer that walked
	# since the summon has not -- and the refusal for distance is the one
	# refusal that would read exactly like the feature being broken.
	var player := _probe.call("player") as Node3D
	if player != null:
		player.global_position = (body as Node3D).global_position + Vector3(1.2, 0.0, 0.0)
		player.velocity = Vector3.ZERO
		for i in 10:
			await physics_frame
	if not bool(riding.call("mount")):
		return {"verdict": "FAIL",
			"detail": "mount() refused: %s" % str(riding.call("interaction_offer",
				player.global_position if player != null else Vector3.ZERO).get("label", "no prompt"))}
	for i in maxi(0, int(args.get("settle", 30))):
		await physics_frame
	var mount: Variant = riding.call("mount_body")
	return {"verdict": "PASS", "detail": "riding %s"
		% (str((mount as Node).name) if mount != null and is_instance_valid(mount) else "?")}


func _step_ride_dismount(args: Dictionary) -> Dictionary:
	var riding := _riding_controller()
	if riding == null:
		return {"verdict": "ERROR", "detail": "no RidingController in this scene"}
	if not bool(riding.call("is_mounted")):
		return {"verdict": "FAIL", "detail": "this peer was not on a mount"}
	riding.call("dismount")
	for i in maxi(0, int(args.get("settle", 30))):
		await physics_frame
	var player := _probe.call("player") as Node3D
	return {"verdict": "PASS", "detail": "dismounted; trainer visible=%s on_floor=%s"
		% [str(player.visible) if player != null else "?",
			str(player.call("is_on_floor")) if player != null else "?"]}


func _riding_controller() -> Node:
	if current_scene == null:
		return null
	return current_scene.get_node_or_null(^"RidingController")


func _fly_controller() -> Node:
	var player := _probe.call("player") as Node3D
	if player == null:
		return null
	var fly: Variant = player.get("fly_controller")
	return fly as Node if fly is Node else null


## SETUP. The Fly unlock flag, a carrier in the party, and a rested trainer.
##
## `fly_traversal.json`'s mentor loaner only stands in inside Cloudreach, so a
## Meadows smoke has to bring its own carrier -- which is the ordinary path
## anyway (`eligible_creature()` prefers the party's active carrier over the
## loaner everywhere). The unlock flag is the Windscar trial's reward and is
## granted here for the same reason the saddle is: playing to it is not what
## this smoke is about.
func _step_fly_setup(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	var fly := _fly_controller()
	if game == null or fly == null:
		return {"verdict": "ERROR", "detail": "no /root/Game or FlyController on this peer's player"}
	var species := str(args.get("species", "galecrest"))
	if not bool(SPECIES_DATA.fly_capability(species).get("can_carry", false)):
		return {"verdict": "ERROR",
			"detail": "SETUP: fly_traversal.json has no carrier capability for '%s'" % species}
	var progression: RefCounted = game.get("progression")
	if progression == null:
		return {"verdict": "ERROR", "detail": "no Game.progression"}
	# SETUP: the unlock. Without it `can_launch()` answers "Complete the
	# Windscar flight trial", which is a fixture failure wearing the feature's
	# words.
	progression.call("set_flag", "fly_traversal_unlocked")
	var party: RefCounted = game.get("party")
	if party == null:
		return {"verdict": "ERROR", "detail": "no Game.party"}
	var carrier: RefCounted = SPECIES_DATA.spawn(species)
	if carrier == null or not bool(party.call("add", carrier)):
		return {"verdict": "FAIL",
			"detail": "SETUP failed: could not put a %s in this peer's party" % species}
	for i in int(party.call("size")):
		if party.call("at", i) == carrier:
			party.call("set_active", i)
			break
	var player := _probe.call("player") as Node3D
	if player != null:
		# SETUP: stamina. `minimum_launch_stamina` is 18 and a peer that has
		# been walking may be under it.
		var vitals: Variant = player.get("vitals")
		if vitals != null:
			(vitals as RefCounted).call("rest")
	for i in maxi(0, int(args.get("settle", 30))):
		await physics_frame
	# SETUP: somewhere with sky over it.
	#
	# Measured, not assumed. On this smoke's first local run every launch was
	# refused, and the reason was not Fly: a fresh boot stands the trainer
	# INSIDE Grandpa's farmhouse (the same fixture fact
	# `tests/smoke_net_movement_two_peers.gd` records from the walking side),
	# and `can_launch()`'s overhead shape query finds the ceiling. Asked from
	# the ground that refusal is invisible -- `can_launch()` short-circuits on
	# "jump first" -- so the search below asks `launch_blockers()`, which is
	# the same checks with only the airborne one taken out. One implementation,
	# and the harness never re-derives what counts as a legal launch.
	var screen := await _clear_open_dialogue(40)
	var cleared := await _stand_somewhere_launchable(fly, int(args.get("search_rings", 3)))
	var stood := _probe.call("player") as Node3D
	return {"verdict": "PASS",
		"detail": "SETUP: fly_traversal_unlocked set, %s active, anchor=%s, screen: %s, launch site: %s (locomotion=%s carried=%s on_floor=%s)"
			% [species, str(fly.get("safe_anchor")), screen, cleared,
				str(stood.call("locomotion_enabled")) if stood != null else "?",
				str(stood.call("is_carried")) if stood != null else "?",
				str(stood.call("is_on_floor")) if stood != null else "?"]}


## Walk the trainer out from wherever it is until the game itself says a launch
## from here would be legal. Returns what happened, for the step's detail.
##
## The body is placed rather than walked, for `_step_explore_at()`'s stated
## reason: a scripted walk in a headless smoke dies against terrain and reports
## on the terrain rather than on what is being tested. Ground height is taken
## from the world's own `ground_height_at` where the scene offers one, which is
## the same door `creature_body.place_on_ground` asks first (D09).
func _stand_somewhere_launchable(fly: Node, rings: int) -> String:
	var player := _probe.call("player") as Node3D
	if player == null:
		return "no player to stand anywhere"
	var blocked := await _blockers_with_the_screen_free(fly)
	if blocked.is_empty():
		return "already clear where it stood"
	var start := player.global_position
	var world: Node = _probe.call("world")
	var reach := 0.0
	for ring in maxi(1, rings):
		var radius := 20.0 * float(ring + 1)
		reach = radius
		for step_index in 6:
			var angle := TAU * float(step_index) / 6.0
			var at := start + Vector3(cos(angle), 0.0, sin(angle)) * radius
			if world != null and world.has_method("ground_height_at"):
				var height := float(world.call("ground_height_at", at.x, at.z))
				if not is_nan(height):
					at.y = height + 0.4
			player.global_position = at
			player.velocity = Vector3.ZERO
			# Long enough for Terrain3D's camera-following collision to stream
			# in under the new spot: a body placed ahead of its own ground
			# falls, and a falling body answers every question wrongly. This is
			# the FENCE/teleport trap `docs/00_START_HERE.md` records.
			for i in 24:
				await physics_frame
			if not player.is_on_floor():
				continue
			blocked = await _blockers_with_the_screen_free(fly)
			if blocked.is_empty():
				return "cleared at (%.1f, %.1f) after %.0f m" % [at.x, at.z, radius]
	player.global_position = start
	for i in 24:
		await physics_frame
	return "NO clear launch site found within %.0f m; last refusal '%s'" % [reach, blocked]


## `launch_blockers()`, asked once this peer's screen is actually its own.
##
## MEASURED, and this is why it is not simply a call. The opening's `house`
## beat opens and re-opens Grandpa's dialogue box while the trainer is still
## inside the farmhouse, and while it is open `sequence_director` holds
## locomotion down -- so `launch_blockers()` answers "Fly is unavailable while
## riding or in combat" for a spot whose only real problem might be the ceiling,
## or none at all. Asking through here presses the box away and waits a bounded
## number of frames for the lockout to lift, so what comes back is a fact about
## the SPOT rather than about the beat. A lockout that never lifts is returned
## as itself rather than waited on forever.
func _blockers_with_the_screen_free(fly: Node) -> String:
	await _clear_open_dialogue(20)
	var blocked := str(fly.call("launch_blockers"))
	for i in 60:
		if blocked != "Fly is unavailable while riding or in combat.":
			return blocked
		await physics_frame
		blocked = str(fly.call("launch_blockers"))
	return blocked


## Launch. The production input, not a state poke: a Jump off the ground, then
## a second Jump while airborne, which is `fly_controller.physics_step()`'s own
## `Input.is_action_just_pressed("jump") and not is_on_floor()`.
func _step_fly_launch(args: Dictionary) -> Dictionary:
	var fly := _fly_controller()
	if fly == null:
		return {"verdict": "ERROR", "detail": "no FlyController on this peer's player"}
	# SETUP first, every time: the opening's dialogue box opens partway through
	# the `house` beat, and while it is open `sequence_director` holds this
	# peer's locomotion down -- which `can_launch()` reports as "Fly is
	# unavailable while riding or in combat", a sentence about the FEATURE for
	# a problem that is entirely the fixture's. See `_step_dismiss_dialogue`.
	var screen := await _clear_open_dialogue(40)
	var reason := await _blockers_with_the_screen_free(fly)
	var player := _probe.call("player") as Node3D
	# `height` stands the trainer up in the air before the launch press, and is
	# the Meadows' stand-in for a Cloudreach ledge.
	#
	# It is HARNESS PLACEMENT, exactly as `_step_teleport` and `_step_explore_at`
	# are, and it is not what is under test: the launch itself is still the
	# production `Input.is_action_just_pressed("jump")` while off the floor, and
	# `can_launch()` still refuses it for every real reason. What it buys is
	# AIRTIME. A glide sinks at `fly_traversal.json`'s 2 m/s, and a Meadows hop
	# clears about two metres, so a launch off flat ground is a one-second
	# flight -- over before a friend's peer has drawn a single frame of it, and
	# a smoke asserting on that would be asserting on a race it set up itself.
	# Sixty metres is thirty seconds, which is a flight somebody can watch.
	var height := float(args.get("height", 0.0))
	for attempt in maxi(1, int(args.get("attempts", 3))):
		if height > 0.0 and player != null:
			player.global_position += Vector3.UP * height
			player.velocity = Vector3.ZERO
			for i in 4:
				await physics_frame
		else:
			await _press_edge("jump", true)
			for i in 3:
				await physics_frame
			await _press_edge("jump", false)
			for i in 6:
				await physics_frame
		await _press_edge("jump", true)
		for i in 3:
			await physics_frame
		await _press_edge("jump", false)
		for i in maxi(0, int(args.get("settle", 20))):
			await physics_frame
		if bool(fly.call("is_flying")):
			return {"verdict": "PASS", "detail": "flying (%s) at y=%.2f on attempt %d"
				% [str(fly.get("state")),
					player.global_position.y if player != null else NAN, attempt]}
		# Between attempts the trainer has to be back on the floor for the
		# first Jump to be a jump at all.
		for i in 90:
			await physics_frame
	return {"verdict": "FAIL",
		"detail": "the second airborne Jump did not launch; screen: %s; launch_blockers() said '%s', now '%s'"
			% [screen, reason, str(fly.call("launch_blockers"))]}


## Come down. Holds the descend action until the body is on the floor, which is
## the same touchdown a player reaches -- `physics_step()`'s `is_on_floor()`
## branch, which is what proposes the landing anchor.
func _step_fly_land(args: Dictionary) -> Dictionary:
	var fly := _fly_controller()
	var player := _probe.call("player") as Node3D
	if fly == null or player == null:
		return {"verdict": "ERROR", "detail": "no FlyController or player on this peer"}
	if not bool(fly.call("is_flying")):
		return {"verdict": "PASS", "detail": "already grounded"}
	await _press_edge("fly_descend", true)
	var budget := maxi(1, int(args.get("budget_frames", 900)))
	var landed := false
	for i in budget:
		await physics_frame
		if not bool(fly.call("is_flying")):
			landed = true
			break
	await _press_edge("fly_descend", false)
	for i in maxi(0, int(args.get("settle", 30))):
		await physics_frame
	if not landed:
		return {"verdict": "FAIL", "detail": "still airborne after %d frames at y=%.2f"
			% [budget, player.global_position.y]}
	return {"verdict": "PASS", "detail": "landed at (%.2f, %.2f, %.2f); anchor report %s"
		% [player.global_position.x, player.global_position.y, player.global_position.z,
			JSON.stringify(fly.call("anchor_report"))]}


## Forge a landing-anchor claim and send it to the host.
##
## This is the adversary the arbiter exists for, and it is deliberately NOT a
## polite API call: it goes through this peer's own outbound trainer proxy,
## down the same RPC a real client's landing goes down, carrying a position the
## client made up. If the host grants it, a client can name its own recovery
## point anywhere in the world -- which is `MP_ENCOUNTER_PROTOCOL.md` SS2 broken
## for Fly. The smoke asserts the refusal.
func _step_fly_claim_anchor(args: Dictionary) -> Dictionary:
	var fly := _fly_controller()
	var proxy := _own_proxy("trainer")
	if fly == null:
		return {"verdict": "ERROR", "detail": "no FlyController on this peer's player"}
	if proxy == null:
		return {"verdict": "ERROR",
			"detail": "SETUP incomplete: this peer has no outbound trainer proxy (no session?)"}
	var at: Array = args.get("at", []) as Array
	if at.size() != 3:
		return {"verdict": "ERROR", "detail": "fly_claim_anchor needs args.at = [x, y, z]"}
	var before: Dictionary = fly.call("anchor_report")
	var game := root.get_node_or_null(^"Game")
	var realm := str(args.get("realm", str(game.get("current_realm")) if game != null else ""))
	proxy.call("request_landing_anchor",
		Vector3(float(at[0]), float(at[1]), float(at[2])), realm)
	for i in maxi(0, int(args.get("settle", 60))):
		await physics_frame
	var after: Dictionary = fly.call("anchor_report")
	return {"verdict": "PASS", "detail": "claimed (%.1f, %.1f, %.1f); refusals %d -> %d, accepts %d -> %d, code '%s'"
		% [float(at[0]), float(at[1]), float(at[2]),
			int(before.get("refusals", 0)), int(after.get("refusals", 0)),
			int(before.get("accepts", 0)), int(after.get("accepts", 0)),
			str(after.get("last_code", ""))]}



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
		"party":
			# Contract §5's `party` probe, "the Gate F `party_state()` shape".
			# Named in the contract from Wave 0 and first needed here: lane
			# 7.A's reconnect row has to compare the character that came back
			# against the one that left, and `assert party_size` can only
			# compare against a number this file would have to hard-code.
			return _probe.call("party_state")
		"world_snapshot":
			# `Game.world_snapshot()` -- EXACTLY the payload the host puts on
			# the wire in `session.gd::_rpc_snapshot`, asked of whichever peer
			# is being probed. On the host it is the truth; on a late joiner it
			# is what that joiner would itself now serialise, after the four
			# live-scene sync seams have run.
			#
			# This, and not the merged save file, is the honest world-vs-world
			# comparison: the save file's `progression` key is world flags
			# MERGED WITH the local player's own, so two peers holding
			# identical worlds legitimately differ there, and a smoke diffing
			# it would report a divergence that is not one.
			var wsgame := root.get_node_or_null(^"Game")
			if wsgame == null or not wsgame.has_method("world_snapshot"):
				return {}
			return wsgame.call("world_snapshot")
		"save_dict":
			# Contract §5: "the full world save dictionary -- large, for
			# diffing a late joiner against the host in 7.A". The WHOLE
			# dictionary, not the hashed subset: the hash answers "do these
			# agree", and this answers "on which key do they not", which is
			# the difference between a smoke that reports a divergence and one
			# that reports a divergence AND says where.
			#
			# `world_seed` is left in rather than erased the way
			# `_compute_state_hash()` erases it. The seed is pinned identically
			# across a run (net_harness.gd::_spawn_peer sets TB_WORLD_SEED), so
			# it is a key that SHOULD match, and hiding it here would hide the
			# one case where it does not.
			return _save_dictionary()
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
		"riding":
			# Wave 6 lane 6.B. Two halves, and the SECOND is the deliverable.
			#
			# `local` is what this peer is doing itself. `remote` is what this
			# peer can SEE of everybody else's ride: for each other peer's
			# trainer body, whether it is drawn as riding, which creature it is
			# sitting on, how far the rider is from the mount right now, and
			# whether the seated pose actually reached the skeleton.
			#
			# `gap` is the number the smoke asserts on and it is deliberately
			# measured live rather than derived: a rider and a mount that are
			# two independently interpolated bodies read as ONE animal only for
			# as long as the distance between them stays put. `seated` is the
			# other half of the same claim -- `trainer_model.gd::ride_pose_
			# applied()`'s own comment says why a VISIBLE rider is not the same
			# claim as a SEATED one, and a trainer drawn standing bolt upright
			# on a creature's back is the owner's own OP-0904-3 bug.
			var riding_node := _riding_controller()
			var ride_local := {}
			if riding_node != null:
				var mount_body: Variant = riding_node.call("mount_body")
				var local_player := _probe.call("player") as Node3D
				var local_model: Node = local_player.get_node_or_null(^"Model") \
					if local_player != null else null
				ride_local = {
					"mounted": bool(riding_node.call("is_mounted")),
					"mount": str((mount_body as Node).name) \
						if mount_body != null and is_instance_valid(mount_body) else "",
					"species": str((mount_body as Node3D).get("species_id")) \
						if mount_body != null and is_instance_valid(mount_body) else "",
					"saddle_worn": mount_body != null and is_instance_valid(mount_body) \
						and (mount_body as Node).get_node_or_null(^"RideSaddle") != null,
					"seated": local_model != null and local_model.has_method("ride_pose_applied") \
						and bool(local_model.call("ride_pose_applied")),
					"speed": float(riding_node.call("ride_speed_now")),
				}
			var ride_remote := {}
			for body in get_nodes_in_group(&"remote_trainer"):
				if not is_instance_valid(body) or not (body is Node3D):
					continue
				var rider: Node3D = body
				if rider.is_multiplayer_authority():
					continue
				var rider_mount: Node3D = null
				for creature in get_nodes_in_group(&"remote_creature"):
					if creature is Node3D and is_instance_valid(creature) \
							and int((creature as Node3D).get("owner_peer_id")) == int(rider.get("peer_id")):
						rider_mount = creature as Node3D
						break
				var rider_model: Node = rider.get_node_or_null(^"Model")
				ride_remote[str(int(rider.get("peer_id")))] = {
					"riding": bool(rider.get("net_riding")),
					"carried": bool(rider.get("net_carried")),
					"saddled": bool(rider.get("net_creature_saddled")),
					"visible": rider.visible,
					"mount": str(rider_mount.name) if rider_mount != null else "",
					"mount_species": str(rider_mount.get("species_id")) if rider_mount != null else "",
					"mount_saddle_worn": rider_mount != null \
						and rider_mount.get_node_or_null(^"RideSaddle") != null,
					"gap": rider.global_position.distance_to(rider_mount.global_position) \
						if rider_mount != null else -1.0,
					"above": rider.global_position.y - rider_mount.global_position.y \
						if rider_mount != null else 0.0,
					"seated": rider_model != null and rider_model.has_method("ride_pose_applied") \
						and bool(rider_model.call("ride_pose_applied")),
					"pos": [rider.global_position.x, rider.global_position.y, rider.global_position.z],
				}
			return {"local": ride_local, "remote": ride_remote}
		"flying":
			# Wave 6 lane 6.C, same shape and the same reason. `local` is this
			# peer's own flight and its landing-anchor ledger; `remote` is what
			# this peer DRAWS of somebody else's -- which is the half that was
			# missing entirely, because a flying trainer used to replicate as a
			# trainer falling.
			#
			# `carrier` is the name of the bird node standing over the remote
			# body's head. Reported by NAME rather than by a live scan for a
			# mesh, for `remote_presentation`'s reason one file over: what is
			# being asserted is that the art was BUILT, and a node that exists
			# is the durable proof of that.
			var fly_node := _fly_controller()
			var fly_player := _probe.call("player") as Node3D
			var fly_local := {}
			if fly_node != null:
				fly_local = {
					"flying": bool(fly_node.call("is_flying")),
					"state": str(fly_node.get("state")),
					# The reasons a launch would be refused RIGHT NOW, and the
					# two player facts behind the most confusing of them. A run
					# that cannot get off the ground has to say why in its own
					# output: the first run of `smoke_net_fly.gd` reported
					# "the second airborne Jump did not launch" three times
					# over while the actual answer was a farmhouse ceiling.
					"blockers": str(fly_node.call("launch_blockers")),
					"locomotion": fly_player != null \
						and bool(fly_player.call("locomotion_enabled")),
					"carried": fly_player != null and bool(fly_player.call("is_carried")),
					"on_floor": fly_player != null and bool(fly_player.call("is_on_floor")),
					# Which owner of the screen is holding locomotion down, when
					# one is. `sequence_director._refresh_lockout()` re-applies
					# its answer every frame, so a locomotion lock that persists
					# is one of these four still reading true -- naming them is
					# the difference between a finding with a reproduction and
					# "the client cannot move".
					"lockout": _lockout_report(),
					"species": str(fly_node.call("carrier_species_id")),
					"y": fly_player.global_position.y if fly_player != null else 0.0,
					"carrier": fly_player != null \
						and fly_player.get_node_or_null(^"FlyCompanionPresentation") != null,
					"anchor": fly_node.call("anchor_report"),
				}
			var fly_remote := {}
			for body in get_nodes_in_group(&"remote_trainer"):
				if not is_instance_valid(body) or not (body is Node3D):
					continue
				var flier: Node3D = body
				if flier.is_multiplayer_authority():
					continue
				var flier_model: Node = flier.get_node_or_null(^"Model")
				fly_remote[str(int(flier.get("peer_id")))] = {
					"flying": bool(flier.get("net_flying")),
					"state": str(flier.get("net_fly_state")),
					"species": str(flier.get("net_fly_species")),
					"visible": flier.visible,
					"carrier": flier.get_node_or_null(^"FlyCompanionPresentation") != null,
					"hanging": flier_model != null and flier_model.has_method("is_riding") \
						and bool(flier_model.get("_fly_hang")),
					"pos": [flier.global_position.x, flier.global_position.y, flier.global_position.z],
					"y": flier.global_position.y,
				}
			return {"local": fly_local, "remote": fly_remote}
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
		"boss":
			# Stage B Wave 8, row 8. What `smoke_net_shared_boss.gd` asserts on:
			# the ONE host record two pilots are in, and -- the part row 7 never
			# had to ask -- what §10 / D-MP12 scaling did to the opponent
			# standing in it.
			#
			# Three sets of numbers, from three places, because the claim is a
			# comparison between them and collapsing any two would make it
			# unfalsifiable:
			#
			#   * `record` -- the host's encounter record (§3: "the `hp` on this
			#     record is THE hit points"), including the `scaling` row the
			#     host stamped when `participants` last changed;
			#   * `live` -- the opponent creature instance actually on the
			#     field, AFTER `encounter_director.gd::
			#     _scale_opponent_for_the_session()` has had it;
			#   * `authored` -- the same team entry rebuilt from
			#     `trainers.json` through the production
			#     `trainer_npc.gd::creature_for()`, UNSCALED. Keyed by species,
			#     which is unique across the Warden's five.
			#
			# `authored` is deliberately re-derived rather than hard-coded in
			# the smoke: `creature_for()` is fully deterministic (no level roll,
			# no IV roll, no trait roll -- `creature_instance.gd::from_species`
			# defaults every one of them), so this is the SAME authored source
			# the fight itself read, and a species curve retune moves both sides
			# together instead of turning this into a false red. What must NOT
			# move together is hp against attack/defence, and that is what the
			# smoke compares.
			var bdirector := _encounter_director()
			var bmanager := _combat_manager()
			if bdirector == null or bmanager == null:
				return {"available": false}
			var brec: Dictionary = bdirector.call("encounter_record")
			var bopponent: Dictionary = brec.get("opponent", {}) as Dictionary
			var bargs: Dictionary = msg.get("args", {}) as Dictionary
			var btrainer := str(bargs.get("trainer", "warden_aldis"))
			var bspec: Dictionary = NET_TRAINERS.trainer(btrainer)
			var authored: Dictionary = {}
			for entry: Variant in NET_TRAINERS.team_of(bspec):
				if typeof(entry) != TYPE_DICTIONARY:
					continue
				var built: RefCounted = NET_TRAINERS.creature_for(entry as Dictionary)
				if built == null:
					continue
				authored[str(built.get("species_id"))] = {
					"level": int(built.get("level")),
					"max_hp": float(built.get("max_hp")),
					"attack": float(built.get("attack")),
					"defence": float(built.get("defence")),
					"attack_cooldown": float((built.get("combat_override") as Dictionary)
						.get("attack_cooldown", 0.0)),
				}
			var live: Dictionary = {}
			var benemy: Variant = bmanager.call("enemy_body")
			if benemy != null and is_instance_valid(benemy):
				var binstance: Variant = (benemy as Node3D).get("instance")
				if binstance != null:
					live = {
						"species_id": str((binstance as RefCounted).get("species_id")),
						"level": int((binstance as RefCounted).get("level")),
						"hp": float((binstance as RefCounted).get("hp")),
						"max_hp": float((binstance as RefCounted).get("max_hp")),
						"attack": float((binstance as RefCounted).get("attack")),
						"defence": float((binstance as RefCounted).get("defence")),
						"attack_cooldown": float(((binstance as RefCounted)
							.get("combat_override") as Dictionary).get("attack_cooldown", 0.0)),
					}
			return {
				"available": true,
				"is_boss": NET_TRAINERS.is_boss(bspec),
				"trainer": btrainer,
				"defeat_flag": str(bspec.get("defeat_flag", "")),
				"reward_flags": NET_TRAINERS.reward_flags(bspec),
				"team_size": NET_TRAINERS.team_of(bspec).size(),
				"battle_active": bool(bdirector.call("trainer_battle_active")),
				"battle_id": str(bdirector.call("trainer_battle_id")),
				"creatures_left": int(bdirector.call("trainer_creatures_left")),
				"record": {
					"id": str(brec.get("encounter_id", "")),
					"bound_id": str(bmanager.call("encounter_id")),
					"kind": str(brec.get("kind", "")),
					"phase": str(brec.get("phase", "")),
					"realm": str(brec.get("realm", "")),
					"seq": int(brec.get("seq", 0)),
					"participants": (brec.get("participants", {}) as Dictionary).keys(),
					"hp": float(bopponent.get("hp", -1.0)),
					"hp_max": float(bopponent.get("hp_max", -1.0)),
					"species_id": str(bopponent.get("species_id", "")),
					"position": bopponent.get("position", []),
					"scaling": brec.get("scaling", {}),
					# §10's targeting spread, as the host's own tally: how many
					# times `pick_struck` has chosen each participant to be hit.
					# `host_pick_struck_participant`'s own header says a pick IS
					# a hit on this path ("`move_connects` is the miss test, and
					# both branches deal damage once a participant has been
					# picked"), so a tally that did not move over a window is the
					# host saying the boss landed nothing on that peer in it.
					# Row 8 uses it to take the boss OUT of its friendly-fire
					# measurement: the victim's creature is standing in a live
					# boss fight and the boss hits it (finding F9).
					"struck_counts": brec.get("struck_counts", {}),
				},
				"local_peer_id": bdirector.call("_local_peer_id"),
				"live": live,
				"authored": authored,
				# §10's gate, reported so a scaling assertion that goes red says
				# WHICH of the four conditions
				# `encounter_director.gd::_scale_opponent_for_the_session()`
				# refused on. Without it "live == authored" is indistinguishable
				# between "the multiplier was not applied", "the multiplier was
				# applied and then overwritten" and "the host does not think it
				# is in a session".
				"scaling_gate": {
					"is_host": bool(bdirector.call("_is_host")),
					"is_multi_peer": bool(bdirector.call("_is_multi_peer")),
					"encounter_host": bdirector.get("_encounter_host") != null,
					"director_encounter_id": str((bdirector.get("_encounter") as Dictionary)
						.get("encounter_id", "")),
				},
				"refusal": bmanager.get("last_encounter_refusal"),
			}
		"character_restore":
			# Stage B Wave 8, row 21. The two halves the reconnect smoke has to
			# tell apart: what this process holds in MEMORY, and what
			# `user://characters/<id>/character.json` holds ON DISK.
			#
			# Reported side by side and never merged, because the whole point of
			# the row is which of the two a rejoiner's party came from. Lane
			# 7.A's smoke could only read the first, so "the character survived"
			# was true by the process never having lost it.
			var crargs: Dictionary = msg.get("args", {}) as Dictionary
			var crgame := root.get_node_or_null(^"Game")
			if crgame == null:
				return {}
			var crlocal: Variant = crgame.get("local")
			var crsave: Variant = crgame.get("save_system")
			var crid := str(crargs.get("character_id", ""))
			if crid.is_empty() and crlocal != null:
				crid = str((crlocal as RefCounted).get("character_id"))
			var crfile: Dictionary = {}
			if crsave != null and not crid.is_empty():
				var crchars: Variant = (crsave as RefCounted).call("characters")
				if crchars != null and bool((crchars as RefCounted).call("has", crid)):
					crfile = (crchars as RefCounted).call("state", crid) as Dictionary
			return {
				"character_id": crid,
				"live": _character_view(crgame, crargs),
				"file": _character_file_view(crfile, crargs),
				"file_exists": not crfile.is_empty(),
			}
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
		"local_pause":
			# Acceptance item 16 / D102. Everything the "a menu does not freeze
			# other players" smoke reads, off this process's own live objects.
			#
			# `paused` is `SceneTree.paused` on THIS peer, read at the source:
			# this script IS the SceneTree (see the header), so this is the same
			# bit the six panels used to set unconditionally, not a frame
			# counter something was inferred from.
			#
			# `multi_peer` is asked of the SESSION and never of `multiplayer`:
			# under Godot's default `OfflineMultiplayerPeer` a process with no
			# session at all reports `is_server() == true` and
			# `get_unique_id() == 1`, so that API cannot tell solo from host.
			# `Game.is_multi_peer()` is `session.gd::is_multi_peer()` with a null
			# guard -- `peer_count() > 1`, which is false solo, false before the
			# session node exists, and false for a one-peer session.
			var lgame := root.get_node_or_null(^"Game")
			var lowner := _probe.call("input_owner_node") as Node
			var lmenu: Variant = lgame.call("menu") if lgame != null \
				and lgame.has_method("menu") else null
			return {
				"paused": paused,
				"context": str(_probe.call("input_context")),
				"owner": str(lowner.name) if lowner != null else "",
				"menu_open": lmenu != null and bool((lmenu as Node).call("is_open")),
				"multi_peer": lgame != null and lgame.has_method("is_multi_peer") \
					and bool(lgame.call("is_multi_peer")),
				"session_peers": _session_peer_ids().size(),
				"physics_frame": _physics_count,
			}
		"catch":
			# Acceptance item 6. The catch race, from this peer's side.
			#
			# `party` is read by SPECIES rather than by slot index (CLAUDE.md:
			# address inventory by identity, never by slot number), and
			# `pending` is `Game.pending_catch` -- the release ceremony's seam,
			# which is where a catch into a FULL belt goes. It is counted beside
			# the party on purpose: the five-creature limit is a hard rule, and
			# a conservation check that looked only at `party.size()` would read
			# a creature parked on that seam as a creature that vanished.
			var cgame := root.get_node_or_null(^"Game")
			var cmanager := _combat_manager()
			var cparty: Variant = cgame.get("party") if cgame != null else null
			var species: Array = []
			if cparty != null:
				for member: Variant in ((cparty as RefCounted).call("members") as Array):
					species.append(str((member as RefCounted).get("species_id")))
			var pending: Variant = cgame.get("pending_catch") if cgame != null else null
			return {
				"available": cmanager != null,
				"encounter_id": _catch_encounter_id,
				"submit": _catch_submit,
				"verdict": _catch_local_verdict,
				"resolutions": _catch_resolutions,
				"refusals": _catch_refusals,
				"caught_by_other": _catch_caught_by_other,
				# The manager's own last refusal, the field the player-facing
				# HUD reads. Reported beside the signal log because a refusal
				# that set the field but emitted nothing (or the reverse) is a
				# half-told player.
				"last_refusal": cmanager.get("last_encounter_refusal") if cmanager != null else {},
				"party": species,
				"party_size": species.size(),
				"party_full": cparty != null and bool((cparty as RefCounted).call("is_full")),
				"pending": str((pending as RefCounted).get("species_id")) if pending != null else "",
				"owned": species.size() + (1 if pending != null else 0),
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
		"autosave_dict":
			# Lane 7.A. The AUTOSAVE FILE, re-read off disk. Deliberately not
			# `save_dict`: that probe SAVES first and reads back what it just
			# wrote, so it always reflects live memory and could never fail a
			# "did the exit actually write this?" assertion. `saved_world_
			# buildings` is the same shape for lane 3.C's explicit `save_world`
			# scratch slot; the host's own `leave()` writes the AUTOSAVE slot,
			# which is a different file and is the one §17 item 24 is about.
			#
			# `{}` and not `null` when there is no file: a caller can tell
			# "nothing written" from "no answer" by asking `is_empty()`,
			# without `int(null)` aborting the check around it.
			var adgame := root.get_node_or_null(^"Game")
			if adgame == null:
				return {}
			var adsys: Variant = adgame.get("save_system")
			if adsys == null:
				return {}
			var adpath := str(adsys.call("slot_path", int(adgame.call("autosave_slot"))))
			if not FileAccess.file_exists(adpath):
				return {}
			var adf := FileAccess.open(adpath, FileAccess.READ)
			if adf == null:
				return {}
			var adtext := adf.get_as_text()
			adf.close()
			var adparsed: Variant = JSON.parse_string(adtext)
			if typeof(adparsed) != TYPE_DICTIONARY:
				return {}
			return adparsed as Dictionary
		"worlds_dir_entries":
			# D100's `user://worlds/` -- the host-owned world save directory.
			#
			# Re-pointed by lane 1.C, which wrote the split. This was a FORWARD
			# assertion while nobody wrote that directory: a client reporting 0
			# proved nothing, because the host reported 0 too. It is a real
			# comparison now -- the host's is non-empty and the client's is
			# still empty -- which is what the smoke asserts.
			return _save_dir_entries("user://worlds")
		"characters_dir_entries":
			# D100's `user://characters/` -- the PORTABLE half, which every
			# peer writes for itself and only for itself. The client half of
			# the pair above: a client writes no world and exactly one
			# character.
			return _save_dir_entries("user://characters")
		"character_file":
			# The local peer's own character file, as `{id, keys}` -- enough for
			# a smoke to assert whose it is and that it carries a character
			# rather than a world, without shipping the whole payload through
			# the coordinator.
			var cgame := root.get_node_or_null(^"Game")
			if cgame == null:
				return null
			var csave: Variant = cgame.get("save_system")
			if csave == null:
				return null
			var ids: Array = _save_dir_entries("user://characters")
			if ids.is_empty():
				return {}
			var cdata: Dictionary = (csave.call("characters") as RefCounted).call("read", str(ids[0]))
			return {"id": str(ids[0]), "keys": cdata.keys(), "party": (cdata.get("party", []) as Array).size()}
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
## The whole save dictionary this process would write right now, re-read off
## disk. Contract §5's `save_dict` probe and `_compute_state_hash()` share this
## one function deliberately: a lane that diffs two peers key by key and a
## detector that hashes a subset of the same keys must be reading the SAME
## bytes, or a green hash beside a red diff is unexplainable.
##
## Returns `{}` (never `null`) on any failure so a caller can tell "no keys"
## from "no answer" by asking `is_empty()` -- `int(null)` is 0 in GDScript and
## a probe that answered `null` here would abort a comparison rather than fail
## it (lane 7.A's own trap list).
func _save_dictionary() -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {}
	var save_system: Variant = game.get("save_system")
	if save_system == null:
		return {}
	# `write_split` false: this is a hash/inspection probe, not a save of record.
	# D100's world/character files are written by the real autosave sites; a
	# heartbeat that also wrote them would mint a world named after the scratch
	# slot and stamp that id onto `Game.local`, which the peer registry
	# advertises. `{}` (never `null`) on failure -- see this function's own
	# contract note above.
	if not bool(save_system.call("save", game, HASH_SCRATCH_SLOT, false)):
		return {}
	var path := str(save_system.call("slot_path", HASH_SCRATCH_SLOT))
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func _compute_state_hash() -> Variant:
	var full := _save_dictionary()
	if full.is_empty():
		return null
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
