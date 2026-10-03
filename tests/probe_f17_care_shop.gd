extends SceneTree

## Declared detached UI fixture only; never an earned M1 or visual proof.
## It exercises the exact campaign purchase driver against production ShopPanel
## and the actual bound pad events, including button replacement after buying.
const HELPER := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")
const SHOP := preload("res://scripts/ui/shop_panel.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
var checks := 0
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(condition: bool, detail: String) -> void:
	checks += 1
	if not condition:
		failures.append(detail)

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	var old_inventory: RefCounted = game.get("inventory")
	var old_party: RefCounted = game.get("party")
	var inventory := INVENTORY.new(game.get("items"))
	var party := PARTY.new()
	# Explicit isolated fixtures, not supplies earned in a campaign.
	inventory.add("coin", 140)
	inventory.add("wood", 4)
	game.set("inventory", inventory)
	game.set("party", party)
	var panel := SHOP.new()
	root.add_child(panel)
	panel.open("mira")
	for _frame in 12:
		await process_frame
	var helper := HELPER.new()
	helper.set("_tree", self)
	helper.set("_game", game)
	helper.care_basket_purchases = 4
	_check(await helper._buy_care_basket(panel), "four physical paid purchases refused")
	_check((helper.get("_failures") as Array).is_empty(), "purchase driver reported failure")
	_check(inventory.count("potion_small") == 4, "four separate potion receipts missing")
	_check(inventory.count("coin") == 28, "four authored28coin deductions wrong")
	_check(inventory.count("wood") == 4, "unrelated inventory changed")
	_check(panel.is_open(), "purchase lost shop ownership")
	var focused: Control = root.gui_get_focus_owner()
	_check(focused != null and panel.is_ancestor_of(focused), "rebuilt purchase rows lost focus")
	var refused := HELPER.new()
	refused.set("_tree", self)
	refused.set("_game", game)
	refused.care_basket_purchases = 2
	_check(not await refused._buy_care_basket(panel), "insufficient funds were accepted")
	_check(inventory.count("coin") == 28 and inventory.count("potion_small") == 4, "refusal spent partial basket")
	panel.close()
	panel.queue_free()
	game.set("inventory", old_inventory)
	game.set("party", old_party)
	await process_frame
	print("F17 CARE SHOP DIAGNOSTIC " + JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures, "scope": "declared detached UI fixture; no earned journey"}))
	quit(0 if failures.is_empty() else 1)
