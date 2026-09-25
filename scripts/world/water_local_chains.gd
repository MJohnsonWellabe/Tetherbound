extends Node3D
## F13 Tidewake local chains, scene side. Holds no chain state: every step is
## a `water_dock_action` intent the host arbitrates with
## `water_local_chain_rules.gd`, and completion is read back from the committed
## world delta. Speech steps arrive from WaterChapter's guarded conversations.
## The step's message is shown only to the peer who asked for it; a refusal is
## already spoken by LedgerClaim (host/solo) or the ledger's verdict (client).
const RULES := preload("res://scripts/world/water_local_chain_rules.gd")
const CLAIM := preload("res://scripts/world/ledger_claim.gd")
const INTENT := "water_dock_action"
var _world: Node3D
var _game: Node
## step id -> the world flag its commit writes, while this peer awaits it.
var _pending: Dictionary = {}


func build(world: Node3D) -> void:
	_world = world
	_game = get_node_or_null("/root/Game")
	CLAIM.listen(self, _on_delta)
	var ledger: Node = CLAIM.transport(self)
	if ledger != null and not ledger.intent_refused.is_connected(_on_refused):
		ledger.intent_refused.connect(_on_refused)


## Ask the host to record one chain step for this peer's character. Returns
## the ledger verdict ({} when nothing was sent).
func request_step(step_id: String) -> Dictionary:
	if _world == null or _world.simulation_only or _pending.has(step_id) or not RULES.has_step(step_id):
		return {}
	var row := RULES.step(step_id)
	_pending[step_id] = str(row.get("flag", ""))
	var verdict := CLAIM.submit(self, {"kind": INTENT, "realm": "water", "action_id": step_id, "inventory": {}})
	if not CLAIM.in_flight(verdict):
		_pending.erase(step_id)
	return verdict


func pending_steps() -> Array:
	return _pending.keys()


func _on_delta(delta: Dictionary) -> void:
	for step_id: String in _pending.keys():
		if CLAIM.sets_world_flag(delta, str(_pending[step_id])):
			_pending.erase(step_id)
			var message := str(RULES.step(step_id).get("message", ""))
			if _game != null and not message.is_empty():
				_game.push_world_message(message)


func _on_refused(kind: String, _code: String, _reason: String, _detail: Dictionary) -> void:
	if kind == INTENT:
		_pending.clear()
