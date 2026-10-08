extends "res://tests/test_case.gd"

## Actual Game/MapState/Backpack methods in an initialized native child.
## Session recording and maintenance are disclosed doubles; no transport proof.
const NATIVE := preload("res://tests/helpers/passive_native_case.gd")
const GAME_FIXTURE := preload("res://tests/test_canonical_guest_passive_fence.gd")
const PLAYER_FIXTURE := preload("res://tests/test_den_groom_saved_transaction.gd")
const MAP := preload("res://autoload/map_state.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const REPLAY := preload("res://scripts/net/owner_passive_replay.gd")
const FEED := preload("res://scripts/creatures/progression_feed.gd")

class RecordingSession extends Node:
	var blocked := false
	var active := true
	var canonical := false
	var packets: Array[Dictionary] = []
	func _owner_training_mutation_blocked(_player: RefCounted) -> bool: return blocked
	func _altar_current_epoch() -> String: return "hook-fixture"
	func canonical_guest_passive() -> bool: return canonical
	func owner_passive_recording_active() -> bool: return active
	func record_owner_passive_input(packet: Dictionary) -> void: packets.append(packet.duplicate(true))

class MenuFixture extends Node:
	var game: Node
	var messages: Array[String] = []
	func say(message: String) -> void: messages.append(message)
	func is_open() -> bool: return true

var game: Node
var owner_session: RecordingSession
var original_feed: RefCounted
var _native_ready := false
var _native_completed := false

func _native_setup() -> void:
	original_feed = FEED._active
	game = GAME_FIXTURE.GameFixture.new()
	game.local = PLAYER_FIXTURE.new()._player()
	game._ensure_containers()
	assert_true(game.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")))
	game.actor = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(game.actor)
	owner_session = RecordingSession.new()
	game.session = owner_session
	game.quest_log = GAME_FIXTURE.QuestFixture.new()
	var map := MAP.new()
	map.set_extent(Vector2(-16, -16), 16, 16, 4.0)
	map.configure({"reveal_radius": 1.0, "landmarks": [
		{"id": "hook_a", "position": [3.0, 0.0], "discover_radius": 0.25},
		{"id": "hook_b", "position": [3.0, 0.0], "discover_radius": 0.25}]})
	game.map = map
	game._travel_pos = Vector3.ZERO
	game._travel_pos_valid = false
	game._discovery_elapsed = 0.0
	_native_ready = true

func _native_cleanup() -> void:
	if is_instance_valid(game):
		if is_instance_valid(game.actor): game.actor.free()
		game.free()
	if is_instance_valid(owner_session): owner_session.free()
	FEED.set_active(original_feed)

func _native_case_game_records_exact_ticks_discoveries_and_replays_live_record() -> void:
	var before: Dictionary = RECORD.portable_projection(game.local.save_data())
	var uids: Array[String] = []
	for card: Dictionary in before.party: uids.append(card.uid)
	game._process(0.25)
	game._process(0.25)
	game.actor.position = Vector3(3, 0, 0)
	game._process(0.5)
	game.actor.position = Vector3(3, 0, 4)
	game._process(0.5)
	var packets: Array[Dictionary] = owner_session.packets
	assert_eq(packets.size(), 7)
	var operations: Array = []
	for packet: Dictionary in packets: operations.append(packet.op)
	assert_eq(operations, ["condition", "condition", "discovery", "condition", "discovery", "condition", "discovery"])
	assert_eq([packets[0].delta, packets[1].delta, packets[3].delta, packets[5].delta], [0.25, 0.25, 0.5, 0.5])
	for index: int in [0, 1, 3, 5]:
		assert_eq(packets[index].uids, uids, "single original frame records complete ordered roster")
		assert_eq(packets[index].size(), 3, "compact inputs do not contain card snapshots or owner results")
	assert_false(packets[2].travel_valid)
	assert_eq(packets[2].to, [0.0, 0.0, 0.0])
	assert_eq(packets[4].from, [0.0, 0.0, 0.0])
	assert_eq(packets[4].to, [3.0, 0.0, 0.0])
	assert_true(packets[4].travel_valid)
	assert_eq(packets[4].new_landmarks, ["hook_a", "hook_b"])
	assert_eq(packets[6].from, [3.0, 0.0, 0.0])
	assert_eq(packets[6].to, [3.0, 0.0, 4.0])
	assert_eq(packets[6].new_landmarks, [])
	var cursor := REPLAY.begin(before, {})
	var context := {"max_elapsed": 2.0, "max_speed": 40.0, "realm": "meadows", "landmarks": {
		"hook_a": {"position": Vector3(3, 0, 0), "discover_radius": 0.25},
		"hook_b": {"position": Vector3(3, 0, 0), "discover_radius": 0.25}}}
	for index: int in packets.size():
		var packet: Dictionary = packets[index].duplicate(true)
		packet.version = 1
		packet.sequence = index + 1
		var result := REPLAY.apply(cursor, packet, context)
		assert_true(result.ok, str(result))
		if result.get("ok") != true: return
		cursor = result.cursor
	var live: Dictionary = RECORD.portable_projection(game.local.save_data())
	assert_eq(var_to_bytes(cursor.state), var_to_bytes(live), "same original arithmetic, no normalization or field exclusion")
	for card: Dictionary in live.party:
		assert_eq(card.distance_m_together, 7.0)
		assert_eq(card.landmarks_visited_together, 1)
	assert_eq(cursor.discovered.meadows, game.map.save_data().landmarks)
	_native_completed = true

func _native_case_game_fence_blocks_recording_but_disabled_recorder_keeps_care() -> void:
	var before: Dictionary = RECORD.portable_projection(game.local.save_data())
	owner_session.blocked = true
	game._process(0.5)
	assert_eq(owner_session.packets, [])
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), var_to_bytes(before))
	assert_eq([game.autosave_ticks, game.bed_ticks, game.catch_ticks], [0, 0, 0])
	assert_false(game._travel_pos_valid)
	owner_session.blocked = false
	owner_session.active = false
	game._process(0.5)
	assert_eq(owner_session.packets, [])
	assert_true(game.party.at(0).nourishment < before.party[0].nourishment)
	assert_eq([game.autosave_ticks, game.bed_ticks, game.catch_ticks], [1, 1, 1])
	owner_session.active = true
	owner_session.canonical = true
	var nourishment: float = game.party.at(0).nourishment
	game._process(0.5)
	assert_eq(owner_session.packets, [], "no condition-input claim when local condition was suppressed")
	assert_eq(game.party.at(0).nourishment, nourishment)
	_native_completed = true

func _native_case_backpack_target_guard_precedes_any_care_or_item_write() -> void:
	var menu := MenuFixture.new()
	menu.game = game
	var tab := preload("res://scripts/ui/tab_backpack.gd").new()
	tab.menu = menu
	tab.set("_targeting", 0)
	tab.set("_targeting_food", "fixture-food")
	owner_session.blocked = true
	var before: Dictionary = RECORD.portable_projection(game.local.save_data())
	tab.call("_on_target_row", 0)
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), var_to_bytes(before))
	assert_eq(menu.messages.size(), 1)
	assert_eq(tab.get("_targeting"), 0, "blocked choice remains retryable")
	assert_eq(owner_session.packets, [])
	tab.set("_targeting", -1)
	game.items = preload("res://autoload/item_db.gd").new()
	assert_eq(game.inventory.add("travel_pack", 1), 0)
	assert_eq(game.inventory.add("berries", 4), 0)
	assert_eq(game.inventory.add("potion_small", 1), 0)
	var patient: RefCounted = game.party.at(0)
	patient.hp = float(patient.max_hp) - 10.0
	assert_true(game.assign_hotbar(0, "potion_small"))
	var packed := var_to_bytes(RECORD.portable_projection(game.local.save_data()))
	# Use the real field-consumption handler in the existing native case;
	# this detached Label receives its toast, not a visual/layout witness.
	var hud := preload("res://scripts/ui/playground_hud.gd").new()
	var message := Label.new()
	hud.add_child(message)
	hud.set("_game", game)
	hud.set("_party", game.party)
	hud.set("_hotbar_message", message)
	hud.call("_use_hotbar_slot", 0)
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), packed,
		"pending owner decision preserves both the quick-bar item and creature health")
	assert_eq(message.text, "Saving your last action. Try again in a moment.")
	var held_slot := -1
	var berry_slot := -1
	for index: int in game.inventory.slot_count():
		if game.inventory.stack_at(index).get("id") == "travel_pack":
			held_slot = index
		if game.inventory.stack_at(index).get("id") == "berries": berry_slot = index
	assert_true(held_slot >= 0)
	assert_true(berry_slot >= 0)
	tab.set("_held", held_slot)
	tab.call("_on_slot", (held_slot + 1) % game.inventory.slot_count())
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), packed,
		"pending owner decision preserves exact bag slots during a held-stack move")
	assert_eq(tab.get("_held"), held_slot, "blocked move remains retryable")
	tab.set("_held", -1)
	tab.set("_focused", berry_slot)
	tab.call("_split")
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), packed,
		"pending owner decision preserves every slot during a stack split")
	tab.call("_equip", "travel_pack")
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), packed,
		"pending owner decision preserves both the selected bag piece and equipment")
	assert_eq(menu.messages.size(), 4)
	owner_session.blocked = false
	tab.call("_equip", "travel_pack")
	assert_eq(game.player_equipment.equipped_in("backpack"), "travel_pack", "ordinary wear still works")
	assert_eq(game.inventory.count("travel_pack"), 0)
	var worn := var_to_bytes(RECORD.portable_projection(game.local.save_data()))
	owner_session.blocked = true
	tab.call("_unequip", "backpack")
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), worn,
		"pending owner decision preserves the worn piece and every bag slot")
	assert_eq(menu.messages.size(), 6)
	owner_session.blocked = false
	tab.call("_unequip", "backpack")
	assert_eq(game.player_equipment.equipped_in("backpack"), "")
	assert_eq(game.inventory.count("travel_pack"), 1, "ordinary removal returns exactly the original piece")
	tab.call("_split")
	assert_eq(game.inventory.count("berries"), 4, "ordinary split conserves the original quantity")
	assert_eq(game.inventory.stack_at(berry_slot).get("n"), 2, "ordinary split leaves the original half")
	var berry_stacks := 0
	for index: int in game.inventory.slot_count():
		if game.inventory.stack_at(index).get("id") == "berries": berry_stacks += 1
	assert_eq(berry_stacks, 2, "ordinary split makes exactly two stacks")
	hud.call("_use_hotbar_slot", 0)
	assert_eq(patient.hp, patient.max_hp, "ordinary quick-bar healing still works after settlement")
	assert_eq(game.inventory.count("potion_small"), 0, "ordinary quick-bar healing spends exactly the original dose")
	hud.free()
	assert_eq(game.inventory.add("axe", 1), 0)
	var tool_slot := int(game.inventory.find_slot("axe"))
	game.inventory.damage_tool(tool_slot, 5)
	tab.set("_focused", tool_slot)
	packed = var_to_bytes(RECORD.portable_projection(game.local.save_data()))
	owner_session.blocked = true
	# Poll Use on fresh physics-frame edges, as the actual menu does.
	# Keep the input/mode guards observable rather than bypassing them.
	assert_true(tab.visible)
	assert_true(menu.is_open())
	assert_eq([tab.get("_targeting"), tab.get("_confirming"), tab.get("_held")], [-1, -1, -1])
	Input.action_press("interact")
	await (Engine.get_main_loop() as SceneTree).physics_frame
	assert_true(Input.is_action_just_pressed("interact"), "blocked repair receives the original Use edge")
	tab.call("_read_use")
	Input.action_release("interact")
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), packed,
		"pending owner decision preserves original tool wear when Use requests repair")
	assert_eq(menu.messages.back(), "Saving your last action. Try again in a moment.")
	owner_session.blocked = false
	Input.action_press("interact")
	await (Engine.get_main_loop() as SceneTree).physics_frame
	assert_true(Input.is_action_just_pressed("interact"), "ordinary repair receives a separate Use edge")
	tab.call("_read_use")
	Input.action_release("interact")
	assert_eq(game.inventory.durability_at(tool_slot), game.inventory.max_durability_at(tool_slot),
		"ordinary Use repairs the same tool after settlement")
	assert_eq(game.inventory.count("axe"), 1, "repair keeps exactly the original tool")
	var trade := preload("res://scripts/trade/trade_db.gd").new()
	var coin: String = trade.currency_id()
	var price: int = trade.buy_price("mira", "potion_small")
	var original_coins: int = game.inventory.count(coin)
	assert_eq(game.inventory.add(coin, price * 2), 0)
	var shop := preload("res://scripts/ui/shop_panel.gd").new()
	shop.game = game
	shop.set("_trade", trade)
	shop.set("_vendor_id", "mira")
	var shop_message := Label.new()
	shop.add_child(shop_message)
	shop.set("_message", shop_message)
	packed = var_to_bytes(RECORD.portable_projection(game.local.save_data()))
	owner_session.blocked = true
	assert_eq(shop.buy_one("potion_small"), "owner_save_pending")
	assert_eq(shop.sell_one("berries"), "owner_save_pending")
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), packed,
		"pending owner decision preserves every shop item and coin during buy and sell")
	assert_eq(shop_message.text, "Saving your last action. Try again in a moment.")
	owner_session.blocked = false
	assert_eq(shop.buy_one("potion_small"), "")
	assert_eq(game.inventory.count("potion_small"), 1, "ordinary purchase gives exactly one dose")
	assert_eq(game.inventory.count(coin), original_coins + price, "ordinary purchase keeps the configured price")
	assert_eq(shop.sell_one("berries"), "")
	assert_eq(game.inventory.count("berries"), 3, "ordinary sale takes exactly one berry")
	assert_eq(game.inventory.count(coin), original_coins + price + trade.sell_price("mira", "berries"),
		"ordinary sale pays exactly the configured price")
	shop.free()
	var species := preload("res://scripts/creatures/creature_species.gd")
	var giving: RefCounted = species.spawn("paddlenewt")
	var incoming: RefCounted = species.spawn("bramblebun")
	var giving_index: int = game.party.size()
	var starter: RefCounted = game.party.at(1)
	assert_true(game.party.add(giving))
	var party_count: int = game.party.size()
	var swap := preload("res://scripts/ui/swap_panel.gd").new()
	swap.game = game
	swap.set("_trade", trade)
	swap.set("_trader_id", "oskar")
	var authored_offer := preload("res://scripts/trade/creature_trade.gd").offer_for_day(swap.call("_config"), "oskar", 0)
	assert_false(authored_offer.is_empty(), "swap keeps the authored trader and offer period")
	swap.set("_offer", authored_offer)
	swap.set("_offer_creature", incoming)
	swap.set("_pending_index", giving_index)
	packed = var_to_bytes(RECORD.portable_projection(game.local.save_data()))
	owner_session.blocked = true
	assert_eq(swap.confirm_swap(), "owner_save_pending")
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), packed,
		"pending owner decision cannot replace an owned creature UID through an NPC swap")
	assert_eq(swap.get("_pending_index"), giving_index, "blocked swap keeps the exact selected creature retryable")
	assert_eq(swap.get("_offer_creature"), incoming, "blocked swap keeps the original offer")
	owner_session.blocked = false
	assert_eq(swap.confirm_swap(), "")
	assert_eq(game.party.size(), party_count, "ordinary swap preserves the original party count below the five cap")
	assert_eq(game.party.at(giving_index), incoming, "ordinary retry takes only the original NPC offer")
	assert_eq(game.party.at(1), starter, "original player-exclusive starter is retained")
	assert_false(game.party.members().has(giving), "only the selected wild creature leaves")
	assert_eq(swap.get("_pending_index"), -1)
	assert_eq(swap.get("_offer_creature"), null)
	swap.free()
	tab.free()
	menu.free()
	_native_completed = true

func _native_case_game_same_stream_fence_reset_replays_exactly() -> void:
	# Actual Game fence and discovery accounting reproduce the rejected F48
	# displacement, including its active 0.504022s discovery window. The host
	# placement proof is a disclosed fixture; this case is not transport proof.
	var before: Dictionary = RECORD.portable_projection(game.local.save_data())
	game.actor.position = Vector3(0.0, 0.900942385196686, 0.0)
	game._process(0.5)
	game._process(0.004022000000004)
	var frozen := var_to_bytes(RECORD.portable_projection(game.local.save_data()))
	var count: int = owner_session.packets.size()
	var active_discovery_elapsed: float = game._discovery_elapsed
	owner_session.blocked = true
	game._process(0.75)
	assert_eq(owner_session.packets.size(), count, "fence emits no care input")
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), frozen, "fence applies no care or bond")
	assert_true(game._travel_pos_valid, "stationary fence preserves the last actual discovery baseline")
	assert_true(game._travel_fenced)
	assert_eq(game._discovery_elapsed, active_discovery_elapsed, "paused frames are absent from active discovery time")
	game.actor.position = Vector3(-16.0, 1.11597406864166, 14.0)
	owner_session.blocked = false
	game._process(0.5)
	var reset: Dictionary = owner_session.packets.back()
	assert_eq(reset.op, "discovery")
	assert_false(reset.travel_valid)
	assert_eq(reset.from, owner_session.packets[1].to)
	assert_eq(reset.to, [game.actor.position.x, game.actor.position.y, game.actor.position.z])
	assert_true(REPLAY._vector(reset.from).distance_to(REPLAY._vector(reset.to)) > 40.0 * (active_discovery_elapsed + 0.5))
	var context := {"max_elapsed": 2.0, "max_speed": 40.0, "realm": "meadows", "landmarks": {}}
	var cursor := REPLAY.begin(before, {})
	for index: int in owner_session.packets.size():
		var packet: Dictionary = owner_session.packets[index].duplicate(true)
		packet.version = 1
		packet.sequence = index + 1
		if index == owner_session.packets.size() - 1:
			var refused := REPLAY.apply(cursor, packet, context)
			assert_false(refused.ok, "owner reset alone has no host provenance")
			assert_eq(refused.code, "travel_baseline_mismatch")
			context.travel_reset_authorized = true
			context.travel_reset_position = reset.to.duplicate()
		var applied := REPLAY.apply(cursor, packet, context)
		assert_true(applied.ok, str(applied))
		if applied.get("ok") != true: return
		cursor = applied.cursor
	var live := RECORD.portable_projection(game.local.save_data())
	assert_eq(var_to_bytes(cursor.state), var_to_bytes(live), "full portable record matches exact Game arithmetic after fence")
	for card: Dictionary in live.party:
		assert_eq(card.distance_m_together, before.party[0].distance_m_together, "arrival displacement gives no walking credit")
	context.erase("travel_reset_authorized")
	context.erase("travel_reset_position")
	game.actor.position.x += 3.0
	game._process(0.5)
	for index: int in range(count + 2, owner_session.packets.size()):
		var packet: Dictionary = owner_session.packets[index].duplicate(true)
		packet.version = 1
		packet.sequence = index + 1
		var applied := REPLAY.apply(cursor, packet, context)
		assert_true(applied.ok, str(applied))
		if applied.get("ok") != true: return
		cursor = applied.cursor
	live = RECORD.portable_projection(game.local.save_data())
	assert_eq(var_to_bytes(cursor.state), var_to_bytes(live), "ordinary movement resumes exact full-record replay")
	for card: Dictionary in live.party:
		assert_eq(card.distance_m_together, before.party[0].distance_m_together + 3.0)
	# The original camp refusal had exactly the same endpoint as its cursor.
	# A stationary owner fence must not manufacture an unauthorized reset.
	count = owner_session.packets.size()
	frozen = var_to_bytes(live)
	owner_session.blocked = true
	game._process(0.75)
	assert_eq(owner_session.packets.size(), count)
	assert_eq(var_to_bytes(RECORD.portable_projection(game.local.save_data())), frozen)
	assert_true(game._travel_pos_valid)
	assert_true(game._travel_fenced)
	owner_session.blocked = false
	game._process(0.5)
	var stationary: Dictionary = owner_session.packets.back()
	assert_true(stationary.travel_valid)
	assert_eq(stationary.from, stationary.to)
	assert_false(game._travel_fenced)
	# Exactly the added active half-second; blocked time remains excluded.
	context.max_elapsed = 2.5
	for index: int in range(count, owner_session.packets.size()):
		var packet: Dictionary = owner_session.packets[index].duplicate(true)
		packet.version = 1
		packet.sequence = index + 1
		var applied := REPLAY.apply(cursor, packet, context)
		assert_true(applied.ok, str(applied))
		if applied.get("ok") != true: return
		cursor = applied.cursor
	live = RECORD.portable_projection(game.local.save_data())
	assert_eq(var_to_bytes(cursor.state), var_to_bytes(live), "stationary fence replays without any reset authorization")
	for card: Dictionary in live.party:
		assert_eq(card.distance_m_together, before.party[0].distance_m_together + 3.0, "stationary resume grants zero distance")
	owner_session.blocked = true
	game._process(0.75)
	# This isolated Game case has no destination scene to mount its map.
	# Reuse the existing real map while testing only realm continuity.
	var existing_map: RefCounted = game.map
	game.current_realm = "water"
	game.map = existing_map
	owner_session.blocked = false
	game._process(0.5)
	assert_false(owner_session.packets.back().travel_valid, "same coordinates in a new realm do not preserve continuity")
	assert_eq(owner_session.packets.back().from, owner_session.packets.back().to)
	owner_session.blocked = true
	game._process(0.75)
	game._travel_pos_valid = false # Existing arm/readmit invalidation.
	owner_session.blocked = false
	game._process(0.5)
	assert_false(owner_session.packets.back().travel_valid, "fence completion never restores a baseline invalidated by stream admission")
	_native_completed = true

func test_actual_game_input_hooks_replay_identically() -> void:
	NATIVE.run_case(self, "res://tests/test_owner_passive_game_hooks.gd", "_native_case_game_records_exact_ticks_discoveries_and_replays_live_record", 34)

func test_actual_game_existing_fence_and_disabled_recorder() -> void:
	NATIVE.run_case(self, "res://tests/test_owner_passive_game_hooks.gd", "_native_case_game_fence_blocks_recording_but_disabled_recorder_keeps_care", 10)

func test_actual_backpack_target_fence() -> void:
	NATIVE.run_case(self, "res://tests/test_owner_passive_game_hooks.gd", "_native_case_backpack_target_guard_precedes_any_care_or_item_write", 5)

func test_actual_game_same_stream_fence_reset() -> void:
	NATIVE.run_case(self, "res://tests/test_owner_passive_game_hooks.gd", "_native_case_game_same_stream_fence_reset_replays_exactly", 22)
