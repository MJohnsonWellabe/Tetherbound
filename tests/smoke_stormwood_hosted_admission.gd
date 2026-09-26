extends SceneTree

## F11 witness run 27b: Officer Nysa's challenge dialogue finished and no battle
## ever began, with nothing logged. The host had admitted the player (a "state"
## event), and the hub retried `begin_hosted_round` every frame while it kept
## returning false: a companion body still being summoned after an LB send-out,
## or a wild fight that could not be yielded. The challenge stayed pending
## forever.
##
## This drives the production hub's `_receive` / `_process` / `_apply_state`
## with the director, combat manager and session replaced by stubs, and asserts
## each case ends within the admission window: in a start, or in an explicit
## logged `start_refused` with its reason that clears the pending state and
## sends the self-only withdrawal to the host. Negative control: with the
## window disabled (`ADMISSION_WINDOW_S` never reached) the old behaviour, still
## pending, is observed.

const HUB := preload("res://scripts/world/stormwood_encounter_hub.gd")

class StubSession extends Node:
	signal stormwood_encounter_message(event: Dictionary)
	var requests: Array = []
	func local_peer_id() -> int: return 1
	func is_host() -> bool: return true
	func is_active() -> bool: return false
	func request_stormwood_encounter(intent: Dictionary) -> void: requests.append(intent.duplicate(true))

class StubManager extends Node:
	var fighting := false
	var can_yield := false
	func is_fighting() -> bool: return fighting
	func yield_wild_fight_for_hosted_trainer() -> bool:
		if fighting and can_yield:
			fighting = false
			return true
		return false
	func apply_encounter_record(_rec: Dictionary, _quiet: bool = false) -> void: pass

class StubDirector extends Node:
	var hosted_round_blocker := ""
	## Frames until the companion body "arrives"; -1 never.
	var body_after := -1
	var calls := 0
	var begun := false
	func begin_hosted_round(_link: Node, _state: Dictionary) -> bool:
		calls += 1
		if body_after < 0 or calls <= body_after:
			hosted_round_blocker = "companion_not_deployed"
			return false
		hosted_round_blocker = ""
		begun = true
		return true
	func update_hosted_opponent(_state: Dictionary) -> void: pass
	func remove_hosted_observer(_id: String) -> void: pass
	func observe_hosted_state(_e: Dictionary) -> void: pass
	func observe_hosted_event(_id: String, _e: Dictionary) -> void: pass
	func end_hosted_trainer(_won: bool) -> void: pass

class StubWorld extends Node3D:
	var simulation_only := false

var _failures: Array[String] = []
var _passes := 0


func _init() -> void:
	_run.call_deferred()


func _case(label: String, body_after: int, fighting: bool, can_yield: bool, frames: int) -> Dictionary:
	var world := StubWorld.new()
	root.add_child(world)
	var manager := StubManager.new()
	manager.name = "CombatManager"
	manager.fighting = fighting
	manager.can_yield = can_yield
	world.add_child(manager)
	var director := StubDirector.new()
	director.body_after = body_after
	world.add_child(director)
	var session := StubSession.new()
	world.add_child(session)
	var hub := HUB.new()
	hub.world = world
	hub.director = director
	hub.session = session
	world.add_child(hub)
	session.stormwood_encounter_message.connect(Callable(hub, "_receive"))
	var refusals: Array = []
	session.stormwood_encounter_message.connect(func(event: Dictionary) -> void:
		if str(event.get("kind", "")) == "start_refused":
			refusals.append(event))
	hub.request_start("officer_nysa_deepwood_rod")
	hub.call("_receive", {"kind": "state", "trainer_id": "officer_nysa_deepwood_rod", "participants": [1],
		"record": {"encounter_id": "enc-nysa-1", "phase": "active"}, "team_entry": {}, "position": Vector3.ZERO})
	var frame := 0
	while frame < frames and not director.begun and refusals.is_empty():
		hub.call("_process", 1.0 / 60.0)
		frame += 1
	var out := {"begun": director.begun, "refusals": refusals, "frames": frame,
		"pending": not (hub.get("_pending_state") as Dictionary).is_empty(),
		"withdrawals": session.requests.filter(func(r: Dictionary) -> bool:
			return str(r.get("kind", "")) == "finalized_death_withdrawal"),
		"last_refusal": hub.last_start_refusal.duplicate()}
	print("ADMISSION %s: %s" % [label, str(out)])
	world.queue_free()
	return out


func _run() -> void:
	var window := int(ceil(HUB.ADMISSION_WINDOW_S * 60.0)) + 5
	# 1. The companion body arrives three frames later: the retry starts the battle.
	var late := _case("companion summoned late", 3, false, false, window)
	_expect(late.begun and (late.refusals as Array).is_empty(), "a companion that arrives within the window starts the battle")
	# 2. The companion never arrives: an explicit refusal within the window.
	var never := _case("companion never deployed", -1, false, false, window)
	_expect(not never.begun and (never.refusals as Array).size() == 1
		and str((never.refusals as Array)[0].reason) == "companion_not_deployed",
		"a companion that never deploys ends in start_refused(companion_not_deployed)")
	_expect(not bool(never.pending), "the pending admission is cleared")
	_expect((never.withdrawals as Array).size() == 1, "the host's fight gets the self-only withdrawal")
	_expect(str((never.last_refusal as Dictionary).get("reason", "")) == "companion_not_deployed", "the hub records the reason")
	# 3. A wild fight that cannot yield: an explicit refusal, never pending.
	var stuck := _case("wild fight cannot yield", 0, true, false, window)
	_expect(not stuck.begun and (stuck.refusals as Array).size() == 1
		and str((stuck.refusals as Array)[0].reason) == "engaged_in_wild_fight",
		"an unyieldable wild fight ends in start_refused(engaged_in_wild_fight)")
	# 4. A wild fight that can yield: the existing rule, the battle starts.
	var yields := _case("wild fight yields", 0, true, true, window)
	_expect(yields.begun, "a fleeable wild fight yields and the battle starts")
	# Negative control: short of the window the old behaviour, still pending.
	var short := _case("short of the window", -1, false, false, window - 30)
	_expect(bool(short.pending) and (short.refusals as Array).is_empty(), "negative control: before the window ends it is still pending")
	_finish()


func _expect(ok: bool, message: String) -> void:
	if ok:
		_passes += 1
		print("  PASS: ", message)
	else:
		_failures.append(message)
		print("  FAIL: ", message)


func _finish() -> void:
	print("STORMWOOD HOSTED ADMISSION %s: %d passed, %d failed" % [
		"OK" if _failures.is_empty() else "FAILED", _passes, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
