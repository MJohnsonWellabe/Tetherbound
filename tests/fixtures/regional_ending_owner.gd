extends RefCounted

## Synthetic contract double only. This is NOT an earned-save or gameplay proof.
## Foundations must separately prove host provenance, disk writes and reconnect.
const HOMECOMING := preload("res://scripts/story/regional_homecoming.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")

class Member:
	extends RefCounted
	var uid := ""
	var nickname := ""
	var display_name := ""
	var landmarks_visited_together := 0
	var battles_fought := 0
	var rest_nights_together := 0
	var feeds_together := 0

	func _init(display: String, nick: String = "") -> void:
		uid = display
		display_name = display
		nickname = nick

class PartyStub:
	extends RefCounted
	var rows: Array = []
	var revision := 0

	func members() -> Array:
		return rows.duplicate()

class LocalStub:
	extends RefCounted
	var character_id := "character-homecoming"
	var flags: RefCounted = PROGRESSION.new()
	var realm := "meadows"

class WorldStub:
	extends RefCounted
	var flags: RefCounted = PROGRESSION.new()

class SaverStub:
	extends RefCounted
	var result := true
	var calls := 0
	var saved_character := ""

	func save_character(_game: Object, character_id: String) -> bool:
		calls += 1
		saved_character = character_id
		return result

var world: RefCounted = WorldStub.new()
var local: RefCounted = LocalStub.new()
var party: RefCounted = PartyStub.new()
var save_system: RefCounted = SaverStub.new()
var messages: Array[String] = []
var accepted_outcome := false
var durable_home_return := true
var at_farm := true
var safe := true
var world_instance_id := "synthetic-world"
var session_epoch := "synthetic-session"
var outcome_id := "synthetic-accepted-finale"
var home_return_receipt := "synthetic-home-key-arrival"
var starter_uid := "Terrapup"
var chapter_choices: Array = ["meadows:refused", "water:accepted"]
var receipts: Dictionary = {}
var receipt_overrides: Dictionary = {}
var bool_only := false
var mutate_intent := false

func regional_ending_context() -> Dictionary:
	if not accepted_outcome or not world.flags.has(HOMECOMING.WORLD_FLAG):
		return {}
	return {"version": 1, "character_id": local.character_id,
		"world_instance_id": world_instance_id, "session_epoch": session_epoch,
		"outcome_id": outcome_id, "accepted_outcome": accepted_outcome,
		"home_return_receipt": home_return_receipt, "durable_home_return": durable_home_return,
		"party_revision": party.revision, "party_signature": HOMECOMING.party_signature(party),
		"starter_uid": starter_uid, "chapter_choices": chapter_choices.duplicate(),
		"realm": local.realm, "at_farm": at_farm, "safe": safe,
		"homecoming_seen": local.flags.has(HOMECOMING.SEEN_FLAG),
		"regional_credits_seen": local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG)}

func commit_regional_ending_ack(intent: Dictionary) -> Variant:
	if bool_only:
		return true
	if mutate_intent:
		intent["transaction_id"] = "wrong-owner-transaction"
	var id := str(intent.get("transaction_id", ""))
	if receipts.has(id):
		# A durable replay binds its envelope to the current validated request.
		var replay := intent.duplicate(true)
		replay.merge({"status": "committed", "durable": true})
		return replay
	if not save_system.save_character(self, local.character_id):
		return {"status": "rejected", "durable": false}
	local.flags.set_flag(str(intent.stage))
	var receipt := intent.duplicate(true)
	receipt.merge({"status": "committed", "durable": true})
	receipt.merge(receipt_overrides, true)
	receipts[id] = receipt.duplicate(true)
	return receipt

func push_world_message(message: String) -> void:
	messages.append(message)
