extends "res://tests/test_case.gd"

## D39 (OF31). The village economy: Mira's prices and Oskar's swap.
##
## Two halves, and they fail in different ways.
##
## The PRICES half is arithmetic on a real `inventory.gd` -- coins in, goods
## out, and the one rule that must never break (`sell < buy`, or the village is
## an infinite coin loop). A price table is exactly the kind of data that rots
## quietly: a typo makes a save richer every second and nobody notices until the
## economy is meaningless.
##
## The SWAP half is CLAUDE.md's five-creature cap, which `OF31`'s brief called
## non-negotiable and which is right to call that. A trade that can produce a
## sixth creature breaks a hard rule of the game, so the invariant is checked
## from both ends: a FULL party must still be five afterwards, and a party of
## one must refuse outright rather than leave the player with nothing.
##
## Everything here runs with no scene, no autoloads and no tree: `trade_db.gd`
## and `creature_trade.gd` take the inventory/party they operate on, which is
## what makes the invariants cheap enough to guard on every push.

const TRADE_DB := preload("res://scripts/trade/trade_db.gd")
const CREATURE_TRADE := preload("res://scripts/trade/creature_trade.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")

const SPECIES_PATH := "res://data/creatures/species.json"
const VENDOR := "mira"
const TRADER := "oskar"

var _trade: RefCounted = null
var _items: RefCounted = null
var _inventory: RefCounted = null


func before_each() -> void:
	_trade = TRADE_DB.new()
	_items = ITEM_DB.new()
	_inventory = INVENTORY.new(_items)


## --- the money -----------------------------------------------------------------

func test_the_currency_is_a_real_stacking_item() -> void:
	var coin := str(_trade.currency_id())
	assert_ne(coin, "", "trade.json names no currency")
	assert_true(_items.has(coin), "the currency '%s' is not in items.json" % coin)
	assert_true(_items.stack_size(coin) > 1, "coins should stack; a one-per-slot currency eats the satchel")


## The rule the whole economy rests on. A vendor who pays more for a thing than
## they charge for it is an infinite coin loop, and a player who finds one has
## no way to un-find it.
func test_no_vendor_pays_more_than_they_charge() -> void:
	var checked := 0
	for raw_vendor: Variant in _trade.vendor_ids():
		var vendor_id := str(raw_vendor)
		for raw_item: Variant in _trade.traded_ids(vendor_id):
			var item_id := str(raw_item)
			var buy := int(_trade.buy_price(vendor_id, item_id))
			var sell := int(_trade.sell_price(vendor_id, item_id))
			checked += 1
			assert_true(sell >= 0 and buy >= 0, "'%s' prices '%s' negatively" % [vendor_id, item_id])
			if buy > 0:
				assert_true(sell < buy,
					"'%s' buys %s at %d and sells it at %d -- an infinite coin loop" % [
						vendor_id, item_id, sell, buy
					])
	assert_true(checked >= 5, "trade.json should price a starter list; priced %d" % checked)


func test_every_priced_item_is_a_real_item() -> void:
	for raw_vendor: Variant in _trade.vendor_ids():
		var vendor_id := str(raw_vendor)
		for raw_item: Variant in _trade.traded_ids(vendor_id):
			assert_true(_items.has(str(raw_item)),
				"'%s' prices '%s', which items.json does not define" % [vendor_id, str(raw_item)])


func test_the_merchant_stocks_something_and_buys_something() -> void:
	assert_true((_trade.stocked_ids(VENDOR) as Array).size() >= 3,
		"a store with nothing on the shelves is not a store")
	var bought := (_trade.traded_ids(VENDOR) as Array).filter(
		func(id: Variant) -> bool: return bool(_trade.buys(VENDOR, str(id)))
	)
	assert_true(bought.size() >= 4, "the owner asked for a merchant who BUYS goods too")
	for material in ["wood", "stone", "fiber", "berries"]:
		assert_true(_trade.buys(VENDOR, material),
			"the meadow's own materials should be sellable; '%s' is not" % material)


## --- buying and selling ----------------------------------------------------------

func test_buying_moves_coins_out_and_goods_in() -> void:
	var coin := str(_trade.currency_id())
	var price := int(_trade.buy_price(VENDOR, "potion_small"))
	assert_true(price > 0, "the store should sell a small potion")
	_inventory.add(coin, price * 2)

	assert_eq(_trade.buy(_inventory, VENDOR, "potion_small", 1), TRADE_DB.OK)
	assert_eq(int(_inventory.count("potion_small")), 1, "the potion never arrived")
	assert_eq(int(_inventory.count(coin)), price, "the coins were not taken")


func test_selling_moves_goods_out_and_coins_in() -> void:
	var coin := str(_trade.currency_id())
	var paid := int(_trade.sell_price(VENDOR, "wood"))
	assert_true(paid > 0, "Mira should buy wood")
	_inventory.add("wood", 10)

	assert_eq(_trade.sell(_inventory, VENDOR, "wood", 4), TRADE_DB.OK)
	assert_eq(int(_inventory.count("wood")), 6, "four wood should have left the satchel")
	assert_eq(int(_inventory.count(coin)), paid * 4, "the payment did not arrive")


func test_a_purchase_you_cannot_afford_is_refused_and_costs_nothing() -> void:
	var coin := str(_trade.currency_id())
	var price := int(_trade.buy_price(VENDOR, "revive"))
	_inventory.add(coin, price - 1)

	assert_eq(_trade.buy(_inventory, VENDOR, "revive", 1), TRADE_DB.REFUSED_NO_COINS)
	assert_eq(int(_inventory.count("revive")), 0, "a refused purchase handed over goods anyway")
	assert_eq(int(_inventory.count(coin)), price - 1, "a refused purchase still took coins")


func test_selling_what_you_do_not_have_is_refused() -> void:
	assert_eq(_trade.sell(_inventory, VENDOR, "berries", 1), TRADE_DB.REFUSED_NO_ITEM)
	assert_eq(int(_inventory.count(str(_trade.currency_id()))), 0,
		"a refused sale paid out anyway")


func test_the_store_refuses_what_it_does_not_stock() -> void:
	_inventory.add(str(_trade.currency_id()), 9999)
	assert_eq(_trade.buy(_inventory, VENDOR, "wood", 1), TRADE_DB.REFUSED_NOT_SOLD,
		"materials are bought by Mira, not sold by her")
	assert_eq(_trade.buy(_inventory, VENDOR, "castle_gate_key", 1), TRADE_DB.REFUSED_UNKNOWN,
		"an unpriced item must not be purchasable")


func test_coins_cannot_be_sold_for_coins() -> void:
	_inventory.add(str(_trade.currency_id()), 50)
	assert_ne(_trade.sell(_inventory, VENDOR, str(_trade.currency_id()), 1), TRADE_DB.OK,
		"a vendor who buys coins for coins is a laundry")


## Every refusal has a sentence. A shop that silently does nothing reads as
## broken, which is exactly what the owner reported about potions in OF16.
func test_every_refusal_says_something() -> void:
	for reason in [
		TRADE_DB.REFUSED_UNKNOWN, TRADE_DB.REFUSED_NOT_SOLD, TRADE_DB.REFUSED_NOT_BOUGHT,
		TRADE_DB.REFUSED_NO_COINS, TRADE_DB.REFUSED_NO_ITEM, TRADE_DB.REFUSED_NO_ROOM,
	]:
		assert_ne(TRADE_DB.refusal_text(reason, "Wood"), "",
			"refusal '%s' has no sentence" % reason)
	assert_eq(TRADE_DB.refusal_text(TRADE_DB.OK), "", "success is not a refusal")


## D39 chose to hand the player a starting float in Mira's first conversation.
## The config and the line that speaks it have to agree, or the sentence is a
## lie the player can count in their own satchel.
func test_the_starting_float_matches_what_mira_says() -> void:
	var expected := int(_trade.starting_coins())
	assert_true(expected > 0, "D39 chose a starting float; trade.json says %d" % expected)
	var probe: RefCounted = RUNNER.new()
	assert_true(probe.start("village_mira_shop_intro"), "Mira has no shop-opening conversation")
	var given := 0
	while probe.is_active():
		for effect: String in probe.drain_effects():
			var parts: Array = RUNNER.parse_effect(effect)
			if str(parts[0]) != "give":
				continue
			var pieces: PackedStringArray = str(parts[1]).split(":")
			if str(pieces[0]) == str(_trade.currency_id()):
				given += int(pieces[1])
		probe.advance()
	assert_eq(given, expected,
		"trade.json's starting_coins is %d and the dialogue hands over %d" % [expected, given])


## --- the creature swap -----------------------------------------------------------

func _species_table() -> Dictionary:
	var file := FileAccess.open(SPECIES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return (parsed as Dictionary).get("species", {}) as Dictionary


func _make(species_id: String) -> RefCounted:
	var definition: Dictionary = _species_table().get(species_id, {}) as Dictionary
	return CREATURE_INSTANCE.from_species(species_id, definition)


func _party_of(count: int) -> RefCounted:
	var party: RefCounted = PARTY.new()
	var roster := ["terrapup", "ripplet", "galewisp", "bramblebun", "mudsnout"]
	for i in count:
		party.add(_make(str(roster[i % roster.size()])))
	return party


func _offer_now() -> Dictionary:
	return CREATURE_TRADE.offer_for_day(_trade.config(), TRADER, 1)


func _offered() -> RefCounted:
	var offer := _offer_now()
	return CREATURE_TRADE.offered_creature(
		offer, _species_table().get(str(offer.get("species", "")), {}) as Dictionary, TRADER
	)


func test_the_trader_offers_real_species() -> void:
	var table := _species_table()
	var offers: Array = CREATURE_TRADE.offers(_trade.config(), TRADER)
	assert_true(offers.size() >= 2, "a rotating offer needs something to rotate through")
	for raw: Variant in offers:
		var entry := raw as Dictionary
		assert_true(table.has(str(entry.get("species", ""))),
			"Oskar offers '%s', which species.json does not define" % str(entry.get("species", "")))
		assert_true(int(entry.get("level", 0)) >= 1, "an offer with no level")


## The offer must be a function of the day and nothing else -- otherwise a
## player can re-open the panel until they like the creature.
func test_the_offer_rotates_by_day_and_never_re_rolls() -> void:
	var config: Dictionary = _trade.config()
	var rotation := maxi(1, int(CREATURE_TRADE.trader(config, TRADER).get("rotation_days", 1)))
	var count: int = (CREATURE_TRADE.offers(config, TRADER) as Array).size()
	assert_eq(
		CREATURE_TRADE.offer_index(config, TRADER, 1),
		CREATURE_TRADE.offer_index(config, TRADER, 1),
		"the same day gave two different offers"
	)
	assert_ne(
		CREATURE_TRADE.offer_index(config, TRADER, 1),
		CREATURE_TRADE.offer_index(config, TRADER, 1 + rotation),
		"the offer never changes"
	)
	assert_eq(
		CREATURE_TRADE.offer_index(config, TRADER, 1),
		CREATURE_TRADE.offer_index(config, TRADER, 1 + rotation * count),
		"the offer list should wrap"
	)


func test_the_offered_creature_is_the_same_creature_every_time_you_look() -> void:
	var first := _offered()
	var second := _offered()
	assert_ne(first, null, "no creature stands behind the offer")
	assert_eq(str(first.species_id), str(second.species_id))
	assert_eq(int(first.level), int(second.level))
	assert_almost_eq(float(first.max_hp), float(second.max_hp), 0.001,
		"re-opening the panel re-rolled the creature's stats")
	assert_almost_eq(float(first.attack), float(second.attack), 0.001)
	assert_eq(str(first.trait_primary), str(second.trait_primary))
	assert_eq(int(first.level), int(_offer_now().get("level", 0)),
		"the offer's level is not the creature's level")


## THE cap test. CLAUDE.md: "Player can own only five creatures total."
func test_a_full_party_is_still_five_after_a_swap() -> void:
	var party := _party_of(PARTY.MAX_CREATURES)
	assert_eq(int(party.size()), PARTY.MAX_CREATURES, "the fixture did not fill the party")
	var incoming := _offered()

	assert_eq(CREATURE_TRADE.swap(party, 2, incoming), CREATURE_TRADE.OK)
	assert_eq(int(party.size()), PARTY.MAX_CREATURES,
		"a swap changed the party size; the five-cap is not structural")
	assert_true(int(party.size()) <= PARTY.MAX_CREATURES, "the party exceeded five")
	assert_true(party.members().has(incoming), "the trader's creature never joined")
	for member: Variant in party.members():
		assert_ne(str((member as RefCounted).species_id), "", "a swap left a hole in the party")


func test_the_creature_you_gave_away_is_gone() -> void:
	var party := _party_of(3)
	var giving: RefCounted = party.at(1)
	assert_eq(CREATURE_TRADE.swap(party, 1, _offered()), CREATURE_TRADE.OK)
	assert_false(party.members().has(giving), "the creature you traded away is still in the party")
	assert_eq(int(party.size()), 3, "a swap is one out, one in")


## The other end of the invariant: a swap must never empty the party.
func test_a_one_creature_party_refuses_the_trade() -> void:
	var party := _party_of(1)
	var keeping: RefCounted = party.at(0)
	assert_eq(CREATURE_TRADE.swap(party, 0, _offered()), CREATURE_TRADE.REFUSED_LAST_CREATURE)
	assert_eq(int(party.size()), 1, "the refused swap changed the party anyway")
	assert_eq(party.at(0), keeping, "the refused swap took the player's last creature")


func test_swapping_a_slot_that_is_empty_is_refused() -> void:
	var party := _party_of(2)
	assert_eq(CREATURE_TRADE.swap(party, 4, _offered()), CREATURE_TRADE.REFUSED_BAD_SLOT)
	assert_eq(CREATURE_TRADE.swap(party, -1, _offered()), CREATURE_TRADE.REFUSED_BAD_SLOT)
	assert_eq(int(party.size()), 2, "a refused swap changed the party")


func test_a_swap_with_nothing_on_offer_is_refused() -> void:
	var party := _party_of(3)
	assert_eq(CREATURE_TRADE.swap(party, 0, null), CREATURE_TRADE.REFUSED_NO_OFFER)
	assert_eq(int(party.size()), 3)


## The one-swap-per-rotation flag has to rotate WITH the offer, or a single
## trade would close the trader down permanently.
func test_the_taken_flag_is_keyed_to_the_rotation_period() -> void:
	assert_ne(CREATURE_TRADE.swap_flag(TRADER, 0), CREATURE_TRADE.swap_flag(TRADER, 1),
		"two different periods share one flag; trading once would close the pen forever")
	assert_eq(CREATURE_TRADE.swap_flag(TRADER, 3), CREATURE_TRADE.swap_flag(TRADER, 3))
	assert_false(CREATURE_TRADE.swap_flag(TRADER, 0).contains(":"),
		"a progression flag id is one word, not a payload")


func test_every_swap_refusal_says_something() -> void:
	for reason in [
		CREATURE_TRADE.REFUSED_NO_OFFER, CREATURE_TRADE.REFUSED_BAD_SLOT,
		CREATURE_TRADE.REFUSED_LAST_CREATURE, CREATURE_TRADE.REFUSED_NO_ROOM,
		CREATURE_TRADE.REFUSED_TAKEN,
	]:
		assert_ne(CREATURE_TRADE.refusal_text(reason), "", "refusal '%s' has no sentence" % reason)
