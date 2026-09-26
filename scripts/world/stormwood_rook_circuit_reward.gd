extends Node

## `stormwood_deepwood_circuit` payoff (owner ruling 2026-09-26): Rook pays
## one TM: Thunder Break per character, once, when the circuit is returned.
##
## Same shape as Pim's courier rate (stormwood_pims_parcels.gd): the payment is
## the ledger's existing `reward_grant`, whose delivery id is keyed by (world
## namespace, source, stable character) -- MULTIPLAYER's personal-once receipt.
## A second claim by the same character in this world is refused by the host,
## and the replicated delivery journal is how every peer knows it was paid.
## Finishing the return conversation completes the world chain once and claims
## for the local character; any other character (a co-op companion, or the
## same player in another world) collects their own TM from Rook's thanks.
##
## Rook's thanks is not his greeting forever (exactly Pim's rule): once this
## character has heard it while paid in this world, he returns to his story
## lines. That preference is the player-scoped `RECEIVED_FLAG`; it only chooses
## a greeting, and is dropped again in a world that still owes this character
## the TM, so a receipt from another world can never hide an owed payment.
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")
const CHAIN := "stormwood_deepwood_circuit"
const ROOK := "ace_trainer_rook"
const STEP_2 := "stormwood:side_deepwood_circuit_2"
const COMPLETE := "stormwood:side_deepwood_circuit_complete"
const RETURN := "stormwood_rook_circuit_return"
const THANKS := "stormwood_rook_circuit_thanks"
const REWARD_SOURCE := "stormwood_deepwood_circuit"
const REWARD_ITEM := "tm_thunder_break"
const REWARD_COUNT := 1
const PAID_MESSAGE := "Rook's circuit prize: TM: Thunder Break."
## Player-scoped in flag_scopes.json: this character heard Rook's thanks with
## the TM paid. A greeting preference, never the payment guard.
const RECEIVED_FLAG := "stormwood:deepwood_circuit_reward_received"

var game: Node
var _revision := -1
var _world_revision := -1
var _claiming := false
var _announce_payment := false
## This character finished Rook's thanks; `RECEIVED_FLAG` is set once paid.
var _thanks_heard := false


static func reward_intent() -> Dictionary:
	return {"kind": "reward_grant", "realm": "stormwood", "source": REWARD_SOURCE,
		"item": REWARD_ITEM, "count": REWARD_COUNT}


## Greeting branch to put in front of Rook's circuit branches: once the chain is
## complete, any character may collect a TM not yet paid to them in this world.
static func branches_for(actor_id: String) -> Array:
	if actor_id == ROOK:
		return [{"if_flag": COMPLETE, "unless_flag": RECEIVED_FLAG, "conversation": THANKS}]
	return []


## Chapter events a finished conversation submits, and whether it claims the
## TM for the local character. Empty when the conversation is not Rook's.
static func outcome_for(conversation_id: String) -> Dictionary:
	match conversation_id:
		RETURN:
			return {"events": ["side:%s:step_3" % CHAIN], "claim": true}
		THANKS:
			return {"events": [], "claim": true}
	return {}


## Whether this world's delivery journal already holds `character`'s TM.
static func paid_in_world(world_state: Object, character: String) -> bool:
	if world_state == null:
		return false
	var id := REWARD_DELIVERY.delivery_id(str(world_state.get("reward_delivery_namespace")),
		REWARD_SOURCE, character)
	return not id.is_empty() and (world_state.get("reward_deliveries") as Dictionary).has(id)


func _paid() -> bool:
	if game == null:
		return false
	var local: Variant = game.get("local")
	if not local is Object:
		return false
	return paid_in_world(game.get("world"), str((local as Object).get("character_id")))


func mount(owner_world: Node3D) -> void:
	game = get_node_or_null("/root/Game")
	if owner_world != null and bool(owner_world.get("simulation_only")):
		set_process(false)
		return
	var transport := LEDGER_CLAIM.transport(self)
	if transport != null:
		transport.connect("intent_refused", _on_intent_refused)


func _process(_delta: float) -> void:
	if game == null:
		return
	var world_revision := int(game.get("world").get("revision"))
	if int(game.get("progression").get("revision")) == _revision and world_revision == _world_revision:
		return
	_revision = int(game.get("progression").get("revision"))
	_world_revision = world_revision
	# The delivery landing in this world's journal is the acknowledgement for
	# host, solo and client alike.
	if _paid():
		_claiming = false
		if _announce_payment:
			_announce_payment = false
			game.call("push_world_message", PAID_MESSAGE)
	_update_thanks_receipt()


## Heard while paid here: Rook returns to his story greeting. Still owed here
## (a receipt from another world): he keeps his thanks, which pays the TM.
func _update_thanks_receipt() -> void:
	var player_flags: RefCounted = game.call("player_flags") if game.has_method("player_flags") else null
	if player_flags == null:
		return
	var paid := _paid()
	if paid and _thanks_heard:
		_thanks_heard = false
		player_flags.call("set_flag", RECEIVED_FLAG)
	elif not paid and bool(game.get("progression").has(COMPLETE)) and bool(player_flags.call("has", RECEIVED_FLAG)):
		player_flags.call("set_flag", RECEIVED_FLAG, false)


## Called by the chapter for every finished conversation. Returns true when the
## conversation belonged to Rook's circuit payoff.
func dialogue_finished(conversation_id: String, chapter: Node) -> bool:
	var outcome := outcome_for(conversation_id)
	if outcome.is_empty():
		return false
	for event: String in outcome.events:
		chapter.call("emit_event", event)
	if conversation_id == THANKS:
		_thanks_heard = true
	if bool(outcome.claim):
		claim_reward()
	if game != null:
		_update_thanks_receipt()
	return true


func claim_reward() -> void:
	if _claiming or game == null:
		return
	var flags: RefCounted = game.get("progression")
	if not bool(flags.has(COMPLETE)) and not bool(flags.has(STEP_2)):
		return
	if _paid():
		return
	var inventory: RefCounted = game.get("inventory")
	if inventory != null and not bool(inventory.call("has_room_for", REWARD_ITEM, REWARD_COUNT)):
		game.call("push_world_message", "Make room for Rook's TM, then speak to Rook again.")
		return
	_claiming = true
	_announce_payment = true
	_revision = -1
	var verdict := LEDGER_CLAIM.submit(self, reward_intent())
	if not LEDGER_CLAIM.in_flight(verdict):
		_claiming = false
		_announce_payment = false


## A client's refusal arrives here, not as the submit verdict. The ledger has
## already spoken the reason; release the latch so Rook can be asked again.
func _on_intent_refused(kind: String, _code: String, _reason: String, _detail: Dictionary) -> void:
	if kind == "reward_grant" and _claiming:
		_claiming = false
		_announce_payment = false
