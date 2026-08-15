extends SceneTree

## OF31/D39. Can you actually buy, sell and swap in the real village?
##
##   godot --headless --path . --script tests/smoke_village_trade.gd
##
## **Headless, never under xvfb** — docs/HANDOFF.md §10, same as every other
## scene-booting test here.
##
## The sibling of `tests/smoke_village_smith.gd`, and split from
## `tests/test_trade.gd` for the same reason that file is split from
## `tests/test_dialogue_runner.gd`: the arithmetic and the cap invariants are
## unit-testable in milliseconds and live there, while everything proven HERE is
## a Node reading `/root/Game` in `_process` — the `shop:` effect reaching
## `sequence_director.gd`, the panel it lazily builds under the SceneTree root,
## and those panels moving the REAL satchel and the REAL party.
##
## What it drives, end to end:
##   1. Mira's conversation, opened the way `village_npcs.gd` opens it.
##   2. The starting float landing in the real satchel.
##   3. The store opening by itself once the dialogue box closes.
##   4. A real purchase and a real sale through the panel's own buttons.
##   5. Oskar's conversation, the swap screen, and a real creature swap.
##   6. The five-cap holding across that swap, in the live party autoload.
##   7. The refusal that matters: a party of one will not trade its last.
##   8. Mira's cottage really has an inside, and it is where she is standing.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const VILLAGERS_PATH := "res://data/config/village_npcs.json"
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const TRADE_DB := preload("res://scripts/trade/trade_db.gd")
const CREATURE_TRADE := preload("res://scripts/trade/creature_trade.gd")
const PARTY := preload("res://autoload/party.gd")

const SETTLE_FRAMES := 240

const MIRA_FLAG := "mira_shop_open"
const OSKAR_FLAG := "oskar_trade_open"
const MIRA_INTRO := "village_mira_shop_intro"
const OSKAR_INTRO := "village_oskar_trade_intro"

var _failures: Array[String] = []
var _game: Node = null
var _panel: Node = null
var _world: Node = null
var _trade: RefCounted = null


func _init() -> void:
	_run()


func _run() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		print("FAIL: could not load %s" % SCENE)
		quit(1)
		return

	_trade = TRADE_DB.new()
	_world = packed.instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"/root/Game")
	if _game == null:
		_fail("no Game autoload; there is nobody to trade with")
		_report()
		return
	_panel = get_first_node_in_group("dialogue_panel")
	if _panel == null:
		_fail("nothing is in the 'dialogue_panel' group; village_npcs.gd has nowhere to speak")
		_report()
		return

	# A save carried in from an earlier run would start with every branch spent.
	var progression: RefCounted = _game.get("progression")
	progression.call("set_flag", MIRA_FLAG, false)
	progression.call("set_flag", OSKAR_FLAG, false)

	await _the_shop_opens_itself_and_the_float_arrives()
	await _buying_and_selling_move_the_real_satchel()
	await _the_swap_screen_opens_from_oskars_line()
	await _a_full_party_is_still_five_after_a_real_swap()
	await _a_lone_creature_is_never_traded_away()
	_miras_cottage_has_an_inside_and_she_is_in_it()

	_report()


## --- the store ------------------------------------------------------------------

func _the_shop_opens_itself_and_the_float_arrives() -> void:
	var mira := _villager("Mira")
	var progression: RefCounted = _game.get("progression")
	var chosen := VILLAGE_NPCS.greeting_for(mira, progression)
	if chosen != MIRA_INTRO:
		_fail("a fresh save should greet Mira with '%s'; got '%s'" % [MIRA_INTRO, chosen])
		return
	print("branch: fresh save -> %s" % chosen)

	var inventory: RefCounted = _game.get("inventory")
	var coin := str(_trade.call("currency_id"))
	var before := int(inventory.call("count", coin))

	await _play(MIRA_INTRO)

	var gained := int(inventory.call("count", coin)) - before
	var expected := int(_trade.call("starting_coins"))
	print("float: %s %d -> %d" % [coin, before, int(inventory.call("count", coin))])
	if gained != expected:
		_fail("Mira's opening should hand over %d coins; the satchel gained %d" % [expected, gained])
	if not bool(progression.call("has", MIRA_FLAG)):
		_fail("the shop-opening conversation did not set '%s'" % MIRA_FLAG)

	# The panel is not opened by the conversation -- it is opened by the
	# director, one frame after the dialogue box closes.
	for i in 6:
		await process_frame
	var shop := _shop()
	if shop == null:
		_fail("no ShopPanel was built; the shop: effect never reached the director")
		return
	if not bool(shop.call("is_open")):
		_fail("the store did not open after Mira's line")
	if str(shop.call("vendor_id")) != "mira":
		_fail("the store opened for '%s' rather than mira" % str(shop.call("vendor_id")))
	print("shop: open for %s" % str(shop.call("vendor_id")))


func _buying_and_selling_move_the_real_satchel() -> void:
	var shop := _shop()
	if shop == null:
		return
	var inventory: RefCounted = _game.get("inventory")
	var coin := str(_trade.call("currency_id"))

	# Buy. The panel's own button handler, not trade_db directly.
	var price := int(_trade.call("buy_price", "mira", "potion_small"))
	var coins_before := int(inventory.call("count", coin))
	var potions_before := int(inventory.call("count", "potion_small"))
	var reason := str(shop.call("buy_one", "potion_small"))
	await process_frame
	if reason != "":
		_fail("buying a potion was refused: %s" % reason)
	else:
		var spent := coins_before - int(inventory.call("count", coin))
		var got := int(inventory.call("count", "potion_small")) - potions_before
		print("buy: potion_small for %d (spent %d, got %d)" % [price, spent, got])
		if spent != price or got != 1:
			_fail("buying one potion should cost %d and give 1; spent %d, got %d" % [price, spent, got])

	# Sell. Materials are put in by hand -- gathering is not what is in question.
	inventory.call("add", "wood", 6)
	var paid := int(_trade.call("sell_price", "mira", "wood"))
	coins_before = int(inventory.call("count", coin))
	var wood_before := int(inventory.call("count", "wood"))
	reason = str(shop.call("sell_one", "wood"))
	await process_frame
	if reason != "":
		_fail("selling wood was refused: %s" % reason)
	else:
		var earned := int(inventory.call("count", coin)) - coins_before
		var given := wood_before - int(inventory.call("count", "wood"))
		print("sell: wood for %d (earned %d, gave %d)" % [paid, earned, given])
		if earned != paid or given != 1:
			_fail("selling one wood should pay %d and take 1; earned %d, gave %d" % [paid, earned, given])

	shop.call("close")
	await process_frame


## --- the swap -------------------------------------------------------------------

func _the_swap_screen_opens_from_oskars_line() -> void:
	var progression: RefCounted = _game.get("progression")
	var chosen := VILLAGE_NPCS.greeting_for(_villager("Oskar"), progression)
	if chosen != OSKAR_INTRO:
		_fail("a fresh save should greet Oskar with '%s'; got '%s'" % [OSKAR_INTRO, chosen])
		return
	await _play(OSKAR_INTRO)
	for i in 6:
		await process_frame
	var swap := _swap()
	if swap == null:
		_fail("no SwapPanel was built; the shop:creatures effect never reached the director")
		return
	if not bool(swap.call("is_open")):
		_fail("the swap screen did not open after Oskar's line")
	if swap.call("offer_creature") == null:
		_fail("the swap screen opened with nothing on offer")
	else:
		print("swap: offering %s" % str((swap.call("offer_creature") as RefCounted).call("label")))


## The non-negotiable one, driven through the LIVE party autoload rather than a
## fixture: five in, five out, and the creature that left is really gone.
func _a_full_party_is_still_five_after_a_real_swap() -> void:
	var swap := _swap()
	if swap == null:
		return
	var party: RefCounted = _game.get("party")
	var progression: RefCounted = _game.get("progression")
	# Fill to the cap. The opening leaves the player with one starter.
	var filler := ["terrapup", "ripplet", "galewisp", "bramblebun", "mudsnout"]
	var i := 0
	while int(party.call("size")) < PARTY.MAX_CREATURES and i < filler.size():
		var creature: RefCounted = _game.call("make_creature", str(filler[i]), "")
		if creature != null:
			party.call("add", creature)
		i += 1
	if int(party.call("size")) != PARTY.MAX_CREATURES:
		_fail("could not fill the party to %d for the cap test" % PARTY.MAX_CREATURES)
		return

	var incoming: RefCounted = swap.call("offer_creature")
	var giving: RefCounted = party.call("at", 1)
	swap.call("pick", 1)
	var reason := str(swap.call("confirm_swap"))
	await process_frame
	if reason != "":
		_fail("a full party refused a swap: %s" % reason)
		return

	var size := int(party.call("size"))
	print("swap: party %d -> %d, gave %s, got %s" % [
		PARTY.MAX_CREATURES, size, str(giving.call("label")), str(incoming.call("label"))
	])
	if size != PARTY.MAX_CREATURES:
		_fail("the party is %d after a swap; the five-cap is not structural" % size)
	if size > PARTY.MAX_CREATURES:
		_fail("THE PARTY EXCEEDED FIVE")
	if not (party.call("members") as Array).has(incoming):
		_fail("Oskar's creature never joined the party")
	if (party.call("members") as Array).has(giving):
		_fail("the creature you traded away is still in the party")

	var period := int(CREATURE_TRADE.offer_for_day(
		_trade.call("config"), "oskar", int(_game.get("day"))
	).get("period", 0))
	if not bool(progression.call("has", CREATURE_TRADE.swap_flag("oskar", period))):
		_fail("the swap did not record itself; the pen could be emptied in one visit")


## The other end of the invariant, live: a lone creature is not tradeable.
func _a_lone_creature_is_never_traded_away() -> void:
	var swap := _swap()
	if swap == null:
		return
	var party: RefCounted = _game.get("party")
	var progression: RefCounted = _game.get("progression")
	# Back down to one, and clear the one-swap-per-rotation flag so the refusal
	# under test is the LAST-CREATURE rule and not the already-traded one.
	while int(party.call("size")) > 1:
		party.call("remove_at", int(party.call("size")) - 1)
	var period := int(CREATURE_TRADE.offer_for_day(
		_trade.call("config"), "oskar", int(_game.get("day"))
	).get("period", 0))
	progression.call("set_flag", CREATURE_TRADE.swap_flag("oskar", period), false)

	swap.call("open", "oskar")
	await process_frame
	var keeping: RefCounted = party.call("at", 0)
	swap.call("pick", 0)
	var reason := str(swap.call("confirm_swap"))
	await process_frame
	print("swap: one-creature party -> %s" % reason)
	if reason != CREATURE_TRADE.REFUSED_LAST_CREATURE:
		_fail("a party of one should refuse with '%s'; got '%s'" % [
			CREATURE_TRADE.REFUSED_LAST_CREATURE, reason
		])
	if int(party.call("size")) != 1 or party.call("at", 0) != keeping:
		_fail("the refused swap took the player's last creature anyway")
	swap.call("close")


## --- the interior ----------------------------------------------------------------

## "He has a store in his house." The store is only real if the house is.
func _miras_cottage_has_an_inside_and_she_is_in_it() -> void:
	var village := _world.get_node_or_null(^"Village")
	if village == null:
		_fail("no Village node; nothing was placed")
		return
	var cottage: Node3D = null
	for child in village.get_children():
		if str(child.name).begins_with("cottage_a"):
			cottage = child as Node3D
	if cottage == null:
		_fail("cottage_a was never placed")
		return
	var interior := cottage.get_node_or_null(^"Interior")
	if interior == null:
		_fail("cottage_a has no Interior; village.json's `interior` key did nothing")
		return
	if interior.get_child_count() < 3:
		_fail("the shop interior is empty")
	if interior.get_node_or_null(^"ShopLight") == null:
		_fail("the shop has no light; the doorway leads into a black room")

	# The doorway is a real hole rather than the one-AABB fallback: authored
	# colliders mean several shapes, and the fallback is exactly one.
	var collision := cottage.get_node_or_null(^"Collision")
	var shapes := collision.get_child_count() if collision != null else 0
	print("cottage_a: %d collider boxes, %d interior pieces" % [shapes, interior.get_child_count()])
	if shapes < 5:
		_fail("cottage_a has %d collider boxes; it is still a solid brick" % shapes)

	var mira := _world.get_node_or_null(^"VillageNPCs/Mira") as Node3D
	if mira == null:
		_fail("Mira is not in the world")
		return
	var inside: Vector3 = cottage.to_local(mira.global_position)
	print("Mira stands at cottage-local %.2f, %.2f" % [inside.x, inside.z])
	if absf(inside.x) > 1.69 or absf(inside.z) > 2.69:
		_fail("Mira is standing outside her own shop, at local %.2f, %.2f" % [inside.x, inside.z])


## --- driving ---------------------------------------------------------------------

func _play(conversation_id: String) -> void:
	if not bool(_panel.call("start", conversation_id)):
		_fail("the dialogue panel refused to start '%s'" % conversation_id)
		return
	var guard := 0
	while bool(_panel.call("is_open")) and guard < 64:
		await process_frame
		_panel.call("advance")
		guard += 1
	await process_frame
	await process_frame
	if guard >= 64:
		_fail("'%s' never closed" % conversation_id)


func _shop() -> Node:
	return root.get_node_or_null(^"ShopPanel")


func _swap() -> Node:
	return root.get_node_or_null(^"SwapPanel")


func _villager(who: String) -> Dictionary:
	var file := FileAccess.open(VILLAGERS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	for entry: Variant in ((parsed as Dictionary).get("villagers", []) as Array):
		if entry is Dictionary and str((entry as Dictionary).get("name", "")) == who:
			return entry as Dictionary
	return {}


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("smoke: OK")
		quit(0)
	else:
		for line in _failures:
			print("smoke FAIL: %s" % line)
		quit(1)
