extends "res://scripts/world/realm_gate.gd"

## The Waterward gate is deliberately a specialisation of RealmGate rather
## than a second presentation/input component. Water's entry key is the one
## realm entitlement authored as a one-time key: the host clears it and opens
## the reusable gate in one journaled transaction. Once open, this physical
## gate is the authority check, so its call to Game enters through the already
## authorised path instead of asking the now-consumed key a second time.

const WATERWARD_FLAG := "stormwood:waterward_revealed"
const WATER_KEY_FLAG := "realm_key_water"
const WATER_GATE_FLAG := "realm_gate_water_unlocked"
const UNLOCK_INTENT := "ending_water_gate_unlock"


## RealmGate's base `_ready()` wires the prompt to its own statically bound
## handler. Replace that connection explicitly: overriding `try_unlock` or even
## `_on_activated` does not redirect calls compiled inside a base GDScript.
func _ready() -> void:
	super._ready()
	var prompt := get_node_or_null(^"Interactable")
	if prompt == null:
		push_error("StormwoodWaterGate: inherited prompt was not built")
		return
	for connection: Dictionary in prompt.activated.get_connections():
		var callback: Callable = connection.get("callable", Callable()) as Callable
		if callback.is_valid() and callback.get_object() == self \
				and callback.get_method() == &"_on_activated":
			prompt.activated.disconnect(callback)
	prompt.activated.connect(_on_water_activated)


## Water's prompt handler must name Water's concrete operations directly: the
## first press consumes/key-opens atomically and the second enters through the
## already-authorised physical gate.
func _on_water_activated() -> void:
	var game := _game()
	match state_for(game):
		STATE_UNLOCKABLE:
			if try_unlock(game):
				_refresh(game)
				if game != null and game.has_method("push_world_message"):
					game.call("push_world_message", "The way to %s is open." % destination_label)
		STATE_UNLOCKED:
			try_enter(game)
		_:
			pass


func try_unlock(game: Node) -> bool:
	if is_unlocked(game):
		return true
	if game == null or not has_key(game):
		return false
	var session: Node = game.get("session") as Node
	if session == null or not session.has_method("request_stormwood_encounter"):
		return false
	session.call("request_stormwood_encounter", {"kind": UNLOCK_INTENT})
	# Host/solo dispatch is synchronous. A client truthfully remains pending
	# until the host's committed delta reaches its progression store.
	return is_unlocked(game)


func try_enter(game: Node) -> bool:
	if game == null or not is_unlocked(game) or destination_realm.is_empty():
		return false
	if not game.has_method("enter_realm"):
		push_error("StormwoodWaterGate: Game has no enter_realm method")
		return false
	# Game's generic realm entitlement check still names the key. This gate has
	# already converted that key into the durable world unlock, so the third
	# argument means "pre-authorised by the physical gate", not debug travel.
	game.call("enter_realm", destination_realm, destination_entry_id, true)
	return true


## Pure host-side proximity policy. The actor position comes from
## StormwoodEncounterHub.actor_for(peer), never from the request.
static func request_allowed(flags: RefCounted, actor_position: Vector3,
		gate_position: Vector3, radius_m: float) -> bool:
	return flags != null and bool(flags.call("has", WATERWARD_FLAG)) \
		and actor_position.is_finite() and gate_position.is_finite() \
		and is_finite(radius_m) and radius_m > 0.0 \
		and actor_position.distance_to(gate_position) <= radius_m


## Commit key consumption and reusable unlock as one externally visible unit.
## Two ordinary WorldLedger commits build the exact canonical flag ops, but no
## delta is published until both mutations have reached the world save. Any
## refusal or failed journal restores the whole world and sequence first.
static func host_commit(game: Object, ledger: RefCounted) -> Dictionary:
	if game == null or not game.has_method("is_host") or not bool(game.call("is_host")):
		return _refuse("not_host", "Only the host can open the Waterward gate.")
	var world: RefCounted = game.get("world") as RefCounted
	var saver: RefCounted = game.get("save_system") as RefCounted
	if world == null or ledger == null or ledger.get("world") != world or saver == null:
		return _refuse("not_ready", "The Waterward gate is not ready yet.")
	var flags: RefCounted = world.get("flags") as RefCounted
	if flags == null:
		return _refuse("not_ready", "The Waterward gate is not ready yet.")
	if bool(flags.call("has", WATER_GATE_FLAG)):
		return {"ok": true, "code": "already_open", "reason": "",
			"delta": {"seq": int(ledger.get("seq")), "realm": "stormwood", "ops": []}}
	if not bool(flags.call("has", WATERWARD_FLAG)):
		return _refuse("waterward_hidden", "Read the cleared Waterward sky first.")
	if not bool(flags.call("has", WATER_KEY_FLAG)):
		return _refuse("missing_key", "The Waterward key has not been earned.")
	var world_id := str(world.get("world_id"))
	if world_id.is_empty():
		return _refuse("not_ready", "The world record is not ready to save.")

	var before: Dictionary = world.call("save_data")
	var before_revision := int(world.get("revision"))
	var before_sequence := int(ledger.get("seq"))
	var ops: Array = []
	for change: Dictionary in [
		{"id": WATER_KEY_FLAG, "value": false},
		{"id": WATER_GATE_FLAG, "value": true},
	]:
		var verdict: Dictionary = ledger.call("commit", {
			"kind": "set_world_flag", "realm": "stormwood",
			"id": str(change.id), "value": bool(change.value),
		}, 1)
		if not bool(verdict.get("ok", false)):
			_restore(world, ledger, before, before_revision, before_sequence)
			return _refuse("ledger_refused", "The Waterward lock did not turn. Try again.")
		ops.append_array((verdict.get("delta", {}) as Dictionary).get("ops", []))
	if not bool(saver.call("save_world", game, world_id)):
		_restore(world, ledger, before, before_revision, before_sequence)
		return _refuse("journal_failed", "The Waterward gate could not save. The key remains safe.")
	return {"ok": true, "code": "opened", "reason": "", "delta": {
		"seq": int(ledger.get("seq")), "realm": "stormwood", "ops": ops}}


static func _restore(world: RefCounted, ledger: RefCounted, before: Dictionary,
		before_revision: int, before_sequence: int) -> void:
	world.call("load_data", before)
	world.set("revision", before_revision)
	ledger.set("seq", before_sequence)


static func _refuse(code: String, reason: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": reason,
		"delta": {"seq": 0, "realm": "", "ops": []}}
