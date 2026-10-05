extends "res://tests/test_case.gd"

## F01#6a part 2. A guest's dialogue gifts are claimed from the host as authored
## reward_grants (scripts/net/world_ledger.gd DIALOGUE_GIVE_GATES) instead of
## landing only in the guest's local satchel, which left the host's admitted
## copy of the character without Grandpa's pack, the catch orbs or Tam's tools.
## Run through the real WorldLedger commit, the way a guest's claim arrives.

const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")

const WORLD_ID := "gift-world"
const GUEST_PEER := 7
const GUEST := "gift-guest"


func _ledger() -> Array:
	var world: RefCounted = WORLD_STATE.new()
	world.set("world_id", WORLD_ID)
	return [world, WORLD_LEDGER.new(world)]


func _claim(conversation: String, item: String, count: int, character: String = GUEST) -> Dictionary:
	return {"kind": "reward_grant", "realm": "meadows",
		"source": WORLD_LEDGER.dialogue_give_source(conversation, item), "item": item, "count": count,
		"peers": [GUEST_PEER], "_reward_recipients": [{"peer": GUEST_PEER, "character_id": character}]}


func _authored(conversation: String, item: String) -> int:
	for give: Dictionary in WORLD_LEDGER.dialogue_gives():
		if give.conversation == conversation and give.item == item:
			return int(give.count)
	return 0


func test_every_authored_dialogue_gift_is_classified() -> void:
	var gives := WORLD_LEDGER.dialogue_gives()
	assert_true(gives.size() >= 12, "the authored dialogue gifts are read from data/dialogue (%d)" % gives.size())
	var seen: Dictionary = {}
	for give: Dictionary in gives:
		var conversation := str(give.conversation)
		assert_true(WORLD_LEDGER.DIALOGUE_GIVE_GATES.has(conversation) or WORLD_LEDGER.DIALOGUE_GIVE_REFUSED.has(conversation),
			"%s's give:%s is classified for guests (gate it or list it as refused)" % [conversation, give.item])
		var source := WORLD_LEDGER.dialogue_give_source(conversation, str(give.item))
		assert_false(seen.has(source), "%s gives %s once, so its source is unambiguous" % [conversation, give.item])
		seen[source] = true
	# The scan reaches the band files the runner also plays (review finding:
	# a non-recursive scan never saw data/dialogue/bands/*.json).
	assert_true(seen.has(WORLD_LEDGER.dialogue_give_source("village_nessa_overlook_gift", "berries")),
		"Nessa's band1 trail-food gift (data/dialogue/bands) is among the scanned gifts")


func test_an_authored_opening_gift_is_journaled_once_for_the_guest() -> void:
	var setup := _ledger()
	var world: RefCounted = setup[0]
	var ledger: RefCounted = setup[1]
	var orbs := _authored("grandpa_first_catch", "orb_basic")
	assert_true(orbs > 0, "Grandpa's catch supplies are authored")
	var first: Dictionary = ledger.call("commit", _claim("grandpa_first_catch", "orb_basic", orbs), GUEST_PEER)
	assert_true(bool(first.get("ok")), "an authored gift is accepted (%s)" % str(first))
	assert_eq(world.reward_deliveries.size(), 1)
	var ops: Array = WORLD_LEDGER.player_ops_for(first.delta, GUEST_PEER)
	assert_eq(ops.size(), 1)
	var delivery: Dictionary = (ops[0] as Dictionary).get("delivery", {})
	var total := 0
	for stack: Dictionary in delivery.get("stacks", []):
		assert_eq(str(stack.id), "orb_basic")
		total += int(stack.n)
	assert_eq(total, orbs, "the host delivers exactly the authored count")
	var replay: Dictionary = ledger.call("commit", _claim("grandpa_first_catch", "orb_basic", orbs), GUEST_PEER)
	assert_eq(str(replay.get("code", "")), "already_taken", "a second claim, a replay or a rejoin pays nothing")
	assert_eq(world.reward_deliveries.size(), 1)
	var other: Dictionary = ledger.call("commit", _claim("grandpa_first_catch", "orb_basic", orbs, "another-guest"), GUEST_PEER)
	assert_true(bool(other.get("ok")), "each character receives its own once")


func test_the_delivered_gift_lands_once_in_the_guests_satchel() -> void:
	var setup := _ledger()
	var ledger: RefCounted = setup[1]
	var verdict: Dictionary = ledger.call("commit", _claim("grandpa_first_catch", "revive", _authored("grandpa_first_catch", "revive")), GUEST_PEER)
	var delivery: Dictionary = (WORLD_LEDGER.player_ops_for(verdict.delta, GUEST_PEER)[0] as Dictionary).get("delivery", {})
	var player: RefCounted = PLAYER_STATE.new()
	player.call("configure", ITEM_DB.new())
	player.set("character_id", GUEST)
	assert_true(bool(REWARD_DELIVERY.apply(player, delivery).get("settled")))
	var count := int(player.inventory.call("count", "revive"))
	assert_eq(count, _authored("grandpa_first_catch", "revive"))
	REWARD_DELIVERY.apply(player, delivery)
	assert_eq(int(player.inventory.call("count", "revive")), count, "a re-delivered row grants nothing twice")


func test_a_tampered_or_unauthored_gift_is_refused() -> void:
	var setup := _ledger()
	var world: RefCounted = setup[0]
	var ledger: RefCounted = setup[1]
	var orbs := _authored("grandpa_first_catch", "orb_basic")
	assert_eq(str(ledger.call("commit", _claim("grandpa_first_catch", "orb_basic", orbs + 1), GUEST_PEER).get("code", "")),
		"not_authored", "a changed count mints nothing")
	assert_eq(str(ledger.call("commit", _claim("grandpa_first_catch", "tm_thunder_break", 1), GUEST_PEER).get("code", "")),
		"unknown_source", "an item the conversation never gives is unknown")
	assert_eq(str(ledger.call("commit", _claim("no_such_conversation", "orb_basic", orbs), GUEST_PEER).get("code", "")),
		"unknown_source")
	assert_eq(str(ledger.call("commit", _claim("village_quarry_foreman_hammer", "hammer", 1), GUEST_PEER).get("code", "")),
		"unknown_source", "a gift the host cannot verify a guest reached is refused for guests")
	assert_eq(world.reward_deliveries.size(), 0, "no refused claim journals anything")


func test_a_progression_gift_before_its_prerequisite_is_refused() -> void:
	var setup := _ledger()
	var world: RefCounted = setup[0]
	var ledger: RefCounted = setup[1]
	var gear := _authored("relay_captive_freed", "mill_bridge_gear")
	assert_eq(gear, 1, "the relay captive's key item is authored")
	var early: Dictionary = ledger.call("commit", _claim("relay_captive_freed", "mill_bridge_gear", gear), GUEST_PEER)
	assert_eq(str(early.get("code", "")), "not_earned",
		"a guest cannot claim the captive's key before the relay captain falls in the host's world")
	assert_eq(world.reward_deliveries.size(), 0)
	world.flags.set_flag("relay_captain_defeated")
	var earned: Dictionary = ledger.call("commit", _claim("relay_captive_freed", "mill_bridge_gear", gear), GUEST_PEER)
	assert_true(bool(earned.get("ok")), "once the host's world holds the prerequisite, the key is delivered (%s)" % str(earned))


func test_the_host_keeps_the_direct_give() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/story/sequence_director.gd")
	var branch_at := source.find("if _gifts_route_through_host(game):")
	var direct_at := source.find("var leftover := int(inventory.call(\"add\", item_id, count))")
	assert_true(branch_at >= 0 and direct_at > branch_at, "only an admitted guest routes; everyone else adds directly")
	var gate_at := source.find("func _gifts_route_through_host")
	var gate := source.substr(gate_at, 400)
	assert_true(gate.contains("not bool((session as Node).call(\"is_host\"))") and gate.contains("client_character_save_ready"),
		"the host, solo and a pending joiner never route")
