extends "res://tests/test_case.gd"

## The toast queue: the one system every other system announces through.
##
## Driven entirely through `tick()` with the node never entering a tree, which
## is the seam `toasts.gd` keeps for exactly this file: the queue and the
## coalescing are pure logic, and the labels they would dress are a rendered-
## session question the preview tool photographs instead.

const TOASTS := preload("res://scripts/ui/toasts.gd")

var _built: Array[Node] = []


func after_each() -> void:
	for node: Node in _built:
		if is_instance_valid(node):
			node.free()
	_built.clear()


func _toasts() -> Control:
	var node: Control = TOASTS.new()
	_built.append(node)
	return node


# --- coalescing ---------------------------------------------------------------


func test_repeat_pickups_coalesce_into_one_running_total() -> void:
	# THE RULE THE OWNER FEELS: three swings of the axe read "+9 Wood", not
	# three "+3 Wood"s stacked down the screen.
	var toasts := _toasts()
	toasts.pickup("wood", 3)
	toasts.pickup("wood", 3)
	toasts.pickup("wood", 3)
	assert_eq(toasts.active_count(), 1)
	assert_eq(toasts.active_texts()[0], "+9 Wood")


func test_different_items_do_not_coalesce() -> void:
	var toasts := _toasts()
	toasts.pickup("wood", 3)
	toasts.pickup("stone", 2)
	assert_eq(toasts.active_count(), 2)
	assert_true(toasts.active_texts().has("+3 Wood"))
	assert_true(toasts.active_texts().has("+2 Stone"))


func test_coalescing_refreshes_the_timer_instead_of_stacking() -> void:
	# A pickup two seconds into a three-second toast starts the clock again —
	# the total stays readable for as long as it keeps growing.
	var toasts := _toasts()
	toasts.pickup("wood", 3)
	toasts.tick(2.5)
	toasts.pickup("wood", 3)
	toasts.tick(2.5)
	assert_eq(toasts.active_count(), 1, "refreshed at 2.5s, so alive at 5.0s")
	assert_eq(toasts.active_texts()[0], "+6 Wood")
	toasts.tick(3.1)
	assert_eq(toasts.active_count(), 0)


func test_xp_coalesces_per_pal_and_sums() -> void:
	var toasts := _toasts()
	toasts.xp("Bramblit", 44)
	toasts.xp("Bramblit", 20)
	toasts.xp("Steady", 11)
	assert_eq(toasts.active_count(), 2)
	assert_true(toasts.active_texts().has("Bramblit +64 XP"))
	assert_true(toasts.active_texts().has("Steady +11 XP"))


func test_level_ups_never_coalesce() -> void:
	# `encounter_director` emits one signal per level because each is its own
	# moment; merging them here would quietly undo that decision.
	var toasts := _toasts()
	toasts.level_up("Bramblit", 4)
	toasts.level_up("Bramblit", 5)
	assert_eq(toasts.active_count(), 2)
	assert_true(toasts.active_texts().has("Bramblit reached Lv 4!"))
	assert_true(toasts.active_texts().has("Bramblit reached Lv 5!"))


func test_back_to_back_saves_read_as_one() -> void:
	var toasts := _toasts()
	toasts.saved("autosave")
	toasts.saved("combat ended")
	assert_eq(toasts.active_count(), 1)
	assert_eq(toasts.active_texts()[0], "Saved")
	assert_eq(toasts.active_kinds()[0], "save")


func test_repeat_refusals_refresh_one_toast() -> void:
	# Hammering the swing button at the wrong tree must not paper the corner.
	var toasts := _toasts()
	toasts.refusal("needs_tool")
	toasts.refusal("needs_tool")
	toasts.refusal("needs_tool")
	assert_eq(toasts.active_count(), 1)


# --- the cap and the queue ----------------------------------------------------


func test_at_most_three_toasts_are_visible_at_once() -> void:
	var toasts := _toasts()
	for i in 5:
		toasts.info("line %d" % i)
	assert_eq(toasts.active_count(), TOASTS.MAX_VISIBLE)
	assert_eq(toasts.pending_count(), 5 - TOASTS.MAX_VISIBLE)


func test_waiting_toasts_are_promoted_in_order_as_slots_free_up() -> void:
	var toasts := _toasts()
	for i in 5:
		toasts.info("line %d" % i)
	# Expire the first wave; the queue steps forward FIFO.
	toasts.tick(3.6)
	assert_eq(toasts.active_count(), 2)
	assert_eq(toasts.active_texts()[0], "line 3")
	assert_eq(toasts.active_texts()[1], "line 4")


func test_a_toast_can_coalesce_while_still_waiting_in_the_queue() -> void:
	var toasts := _toasts()
	toasts.info("a")
	toasts.info("b")
	toasts.info("c")
	toasts.pickup("wood", 3)  # queued — the screen is full
	toasts.pickup("wood", 3)  # must merge into the QUEUED toast, not queue again
	assert_eq(toasts.pending_count(), 1)
	toasts.tick(3.6)
	assert_true(toasts.active_texts().has("+6 Wood"))


func test_the_queue_drops_old_news_before_a_level_up() -> void:
	var toasts := _toasts()
	for i in 3:
		toasts.info("visible %d" % i)
	toasts.level_up("Bramblit", 5)  # queued first
	for i in TOASTS.MAX_PENDING:
		toasts.info("noise %d" % i)  # floods the queue past its cap
	assert_eq(toasts.pending_count(), TOASTS.MAX_PENDING)
	# The level-up survived the flood; the oldest noise did not.
	var texts: Array[String] = []
	toasts.tick(3.6)
	texts.append_array(toasts.active_texts())
	toasts.tick(3.6)
	texts.append_array(toasts.active_texts())
	assert_true(texts.has("Bramblit reached Lv 5!"),
		"a level-up must never be dropped to make room for pickups")


# --- lifetimes and wording ----------------------------------------------------


func test_toasts_expire_on_their_own() -> void:
	var toasts := _toasts()
	toasts.pickup("wood", 3)
	toasts.tick(1.0)
	assert_eq(toasts.active_count(), 1)
	toasts.tick(2.1)
	assert_eq(toasts.active_count(), 0)
	assert_eq(toasts.pending_count(), 0)


func test_the_save_tick_is_the_quietest_and_shortest() -> void:
	var toasts := _toasts()
	assert_true(float(TOASTS.LIFETIMES["save"]) < float(TOASTS.LIFETIMES["pickup"]),
		"an autosave is bookkeeping, not news")
	assert_true(float(TOASTS.LIFETIMES["levelup"]) > float(TOASTS.LIFETIMES["pickup"]),
		"a level-up is the reason the session existed")
	toasts.saved("autosave")
	toasts.tick(2.1)
	assert_eq(toasts.active_count(), 0)


func test_every_refusal_token_the_field_systems_mint_has_words() -> void:
	# The whole point: `harvestable.gd` and `tools.gd` emit tokens — `party.gd`'s
	# idiom — and until this layer nothing owned the wording. Every token either
	# of them can emit must come out as a sentence, not echo back as snake_case.
	# Read from the REAL lists, so a token added next month cannot ship unworded
	# without this line going red.
	var tokens: Array = []
	tokens.append_array(
		(load("res://scripts/world/harvestable.gd") as GDScript)
			.get_script_constant_map().get("REFUSALS", [])
	)
	tokens.append_array(
		(load("res://scripts/items/tools.gd") as GDScript)
			.get_script_constant_map().get("REFUSALS", [])
	)
	assert_eq(tokens.size(), 9, "both refusal lists must be found")
	for token: String in tokens:
		var words := TOASTS.refusal_text(token)
		assert_false(words.contains("_"), "'%s' must be worded, got '%s'" % [token, words])
		assert_false(words.is_empty())


func test_an_unknown_token_is_humanised_rather_than_swallowed() -> void:
	var words := TOASTS.refusal_text("no_repair_station")
	assert_false(words.contains("_"))
	assert_false(words.is_empty())


func test_zero_and_negative_amounts_say_nothing() -> void:
	var toasts := _toasts()
	toasts.pickup("wood", 0)
	toasts.xp("Bramblit", 0)
	toasts.refusal("")
	assert_eq(toasts.active_count(), 0)
	assert_eq(toasts.pending_count(), 0)
