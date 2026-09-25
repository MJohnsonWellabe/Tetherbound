extends Node3D

## `stormwood_pims_parcels`: Pim hands over sealed parcels, three existing
## households on the lit arch roads receive them, and Pim pays the courier's
## rate.
##
## Deliveries are three world-scoped facts counted by the chain's second step
## (WORLD §11: "Delivery is three flags, not three new inventory items").
## Each finished recipient conversation submits its fact through the chapter's
## realm-ledger writer. The payoff is two small potions per character, once,
## through the ledger's existing `reward_grant`: its delivery id is keyed by
## source and stable character, so a second claim by the same character is
## refused by the host. The player-scoped receipt flag rides that same delivery
## and hides Pim's thanks branch once the local character is paid.
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
const CRATE := "res://assets/props/quaternius_fantasy/Crate_Wooden.gltf"
const CHAIN := "stormwood_pims_parcels"
const REVEALED := "stormwood:lantern_pools_linked"
const STEP_1 := "stormwood:side_pims_parcels_1"
const STEP_2 := "stormwood:side_pims_parcels_2"
const COMPLETE := "stormwood:side_pims_parcels_complete"
const DELIVERED_PREFIX := "stormwood:side_pims_parcels_delivered:"
const REWARD_SOURCE := "stormwood_pims_parcels"
const REWARD_ITEM := "potion_small"
const REWARD_COUNT := 2
const REWARD_FLAG := "stormwood_pims_parcels_reward_received"
const PIM := "courier_pim"
const OFFER := "stormwood_pim_parcels_offer"
const PROGRESS := "stormwood_pim_parcels_progress"
const RETURN := "stormwood_pim_parcels_return"
const THANKS := "stormwood_pim_parcels_thanks"
## Recipients, in the order the quest text names them. Each is an existing
## resident at an arch-road settlement (pairs A, B and C).
const RECIPIENTS: Array[String] = ["cook_marl", "trader_oswin", "caretaker_lio"]

var world: Node3D
var game: Node
var _crates := {}
var _revision := -1
var _claiming := false


static func delivered_flag(recipient: String) -> String:
	return DELIVERED_PREFIX + recipient


static func delivery_conversation(recipient: String) -> String:
	return "stormwood_pim_parcel_%s" % recipient


## Greeting branches to put in front of an NPC's normal ones, in priority order.
static func branches_for(actor_id: String) -> Array:
	if actor_id == PIM:
		return [
			{"if_flag": COMPLETE, "unless_flag": REWARD_FLAG, "conversation": THANKS},
			{"if_flag": STEP_2, "unless_flag": COMPLETE, "conversation": RETURN},
			{"if_flag": STEP_1, "unless_flag": STEP_2, "conversation": PROGRESS},
			{"if_flag": REVEALED, "unless_flag": STEP_1, "conversation": OFFER},
		]
	if RECIPIENTS.has(actor_id):
		return [{"if_flag": STEP_1, "unless_flag": delivered_flag(actor_id),
			"conversation": delivery_conversation(actor_id)}]
	return []


## Chapter events a finished conversation submits, and whether it claims the
## courier's rate for the local character.
static func outcome_for(conversation_id: String) -> Dictionary:
	match conversation_id:
		OFFER:
			return {"events": ["side:%s:step_1" % CHAIN], "claim": false}
		RETURN:
			return {"events": ["side:%s:step_3" % CHAIN], "claim": true}
		THANKS:
			return {"events": [], "claim": true}
	for recipient: String in RECIPIENTS:
		if conversation_id == delivery_conversation(recipient):
			return {"events": ["count:" + delivered_flag(recipient)], "claim": false}
	return {}


static func reward_intent() -> Dictionary:
	return {"kind": "reward_grant", "realm": "stormwood", "source": REWARD_SOURCE,
		"item": REWARD_ITEM, "count": REWARD_COUNT, "flag": REWARD_FLAG}


func mount(owner_world: Node3D) -> void:
	world = owner_world
	game = get_node("/root/Game")
	add_to_group("progression_restore")
	if bool(world.get("simulation_only")):
		set_process(false)
		return
	var positions := {}
	var npcs: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_npcs.json"))
	for actor: Dictionary in (npcs as Dictionary).get("characters", []):
		positions[str(actor.get("id", ""))] = actor.get("position", [])
	for recipient: String in RECIPIENTS:
		var at: Array = positions.get(recipient, [])
		if at.size() < 3:
			continue
		# The delivered parcel stands beside the resident: supplies received
		# are visible in the settlement, not only in the quest log.
		var x := float(at[0]) + 1.6
		var z := float(at[2]) + 1.2
		var crate := (load(CRATE) as PackedScene).instantiate() as Node3D
		crate.name = "PimParcel_%s" % recipient
		crate.position = Vector3(x, world.ground_height_at(x, z), z)
		crate.scale = Vector3.ONE * 0.7
		crate.visible = false
		add_child(crate)
		_crates[recipient] = crate
	restore_progression_from_game(game)


func _process(_delta: float) -> void:
	if game != null and int(game.get("progression").get("revision")) != _revision:
		restore_progression_from_game(game)


func restore_progression_from_game(_game: Node) -> void:
	if game == null:
		return
	var flags: RefCounted = game.get("progression")
	_revision = int(flags.get("revision"))
	# A committed delta or a client's refusal both advance or settle the
	# claim; either way another finished conversation may try again.
	_claiming = false
	for recipient: String in _crates:
		(_crates[recipient] as Node3D).visible = bool(flags.has(delivered_flag(recipient)))


## Called by the chapter adapter for every finished conversation. Returns true
## when the conversation belonged to this chain.
func dialogue_finished(conversation_id: String, chapter: Node) -> bool:
	var outcome := outcome_for(conversation_id)
	if outcome.is_empty():
		return false
	for event: String in outcome.events:
		chapter.call("emit_event", event)
	if bool(outcome.claim):
		claim_reward()
	return true


func claim_reward() -> void:
	if _claiming or game == null:
		return
	var flags: RefCounted = game.get("progression")
	if not bool(flags.has(COMPLETE)) and not bool(flags.has(STEP_2)):
		return
	if bool(flags.has(REWARD_FLAG)):
		return
	var inventory: RefCounted = game.get("inventory")
	if inventory != null and not bool(inventory.call("has_room_for", REWARD_ITEM, REWARD_COUNT)):
		game.call("push_world_message", "Make room for Pim's two small potions, then speak to Pim again.")
		return
	_claiming = true
	var verdict := LEDGER_CLAIM.submit(self, reward_intent())
	_claiming = bool(verdict.get("pending", false))
	if bool(verdict.get("ok", false)):
		game.call("push_world_message", "Pim's courier rate — 2 Small Potions.")
