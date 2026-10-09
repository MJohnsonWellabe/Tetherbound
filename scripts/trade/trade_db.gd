extends RefCounted

## D39 (OF31). Prices, and the two transactions that move them.
##
## Read once from data/config/trade.json, the same "load+parse a data file"
## shape `autoload/item_db.gd` uses, and for the same reason: a price lookup
## must not be a file read. No number in this file is a literal -- every price,
## the currency id and the starting float all come from the config, so retuning
## the economy is a JSON edit and never a code edit (CLAUDE.md's own rule for
## data that varies per item).
##
## Nodeless on purpose. `buy()`/`sell()` take the inventory they are moving
## things through, so tests/test_trade.gd can drive real transactions against a
## real `inventory.gd` with no tree, no autoloads and no scene -- which is what
## makes the coin arithmetic cheap to guard.
##
## Coins are an ORDINARY item (see items.json's `_comment_coin`): buying is
## "remove N coins, add 1 thing", selling is the reverse, both through the same
## satchel every other item lives in. There is no balance field anywhere.

const CONFIG_PATH := "res://data/config/trade.json"

## What a transaction can refuse for. Returned as a string rather than a bool so
## the panel can say WHICH thing went wrong -- "no room" and "no coins" are
## different problems and a player who is told neither will conclude the shop is
## broken. "" means the transaction went through.
const OK := ""
const REFUSED_UNKNOWN := "unknown"
const REFUSED_NOT_SOLD := "not_sold"
const REFUSED_NOT_BOUGHT := "not_bought"
const REFUSED_NO_COINS := "no_coins"
const REFUSED_NO_ITEM := "no_item"
const REFUSED_NO_ROOM := "no_room"

var _config: Dictionary = {}


func _init(path: String = CONFIG_PATH) -> void:
	_config = _read(path)


func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("trade config missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("trade config is not a JSON object: %s" % path)
		return {}
	return parsed as Dictionary


## The whole parsed config, for the callers that need the parts this class does
## not wrap (the creature traders, which `creature_trade.gd` reads statically).
func config() -> Dictionary:
	return _config


## The item id the village counts in. Everything else in this file goes through
## it rather than naming "coin" directly.
func currency_id() -> String:
	return str(_config.get("currency", "coin"))


func starting_coins() -> int:
	return maxi(0, int(_config.get("starting_coins", 0)))


func vendor_ids() -> Array:
	var vendors: Variant = _config.get("vendors", {})
	return (vendors as Dictionary).keys() if typeof(vendors) == TYPE_DICTIONARY else []


func vendor(vendor_id: String) -> Dictionary:
	var vendors: Variant = _config.get("vendors", {})
	if typeof(vendors) != TYPE_DICTIONARY:
		return {}
	var entry: Variant = (vendors as Dictionary).get(vendor_id, {})
	return entry as Dictionary if typeof(entry) == TYPE_DICTIONARY else {}


func vendor_title(vendor_id: String) -> String:
	return str(vendor(vendor_id).get("title", "Store"))


func goods(vendor_id: String) -> Dictionary:
	var entry: Variant = vendor(vendor_id).get("goods", {})
	return entry as Dictionary if typeof(entry) == TYPE_DICTIONARY else {}


## Every id this vendor deals in at all, in the file's own order -- which is the
## order the panel lists them in, so the JSON is the layout.
func traded_ids(vendor_id: String) -> Array:
	return goods(vendor_id).keys()


## What the vendor is willing to hand over: the ids with a positive `stock`.
func stocked_ids(vendor_id: String) -> Array:
	return traded_ids(vendor_id).filter(
		func(id: Variant) -> bool: return buy_price(vendor_id, str(id)) > 0 and stock(vendor_id, str(id)) > 0
	)


func _entry(vendor_id: String, item_id: String) -> Dictionary:
	var raw: Variant = goods(vendor_id).get(item_id, {})
	return raw as Dictionary if typeof(raw) == TYPE_DICTIONARY else {}


## What the player pays for one; 0 for an item this vendor does not sell.
func buy_price(vendor_id: String, item_id: String) -> int:
	return maxi(0, int(_entry(vendor_id, item_id).get("buy", 0)))


## What the player is paid for one; 0 for an item this vendor will not take.
func sell_price(vendor_id: String, item_id: String) -> int:
	return maxi(0, int(_entry(vendor_id, item_id).get("sell", 0)))


func stock(vendor_id: String, item_id: String) -> int:
	return maxi(0, int(_entry(vendor_id, item_id).get("stock", 0)))


func sells(vendor_id: String, item_id: String) -> bool:
	return stock(vendor_id, item_id) > 0 and buy_price(vendor_id, item_id) > 0


func buys(vendor_id: String, item_id: String) -> bool:
	return sell_price(vendor_id, item_id) > 0


## --- the two transactions ------------------------------------------------------
##
## Both are all-or-nothing. Coins leave only if the goods fit, and goods leave
## only if the coins fit -- a half-completed trade is a player watching their
## wood vanish for nothing, which is worse than a refusal.

## Buy `count` of `item_id` from `vendor_id`, paying out of `inventory`.
## Returns "" on success, or one of the REFUSED_* reasons.
func buy(inventory: RefCounted, vendor_id: String, item_id: String, count: int = 1) -> String:
	if inventory == null or count <= 0:
		return REFUSED_UNKNOWN
	if not goods(vendor_id).has(item_id):
		return REFUSED_UNKNOWN
	if not sells(vendor_id, item_id):
		return REFUSED_NOT_SOLD
	var price := buy_price(vendor_id, item_id) * count
	var coin := currency_id()
	if int(inventory.call("count", coin)) < price:
		return REFUSED_NO_COINS
	if not bool(inventory.call("has_room_for", item_id, count)):
		return REFUSED_NO_ROOM
	if not bool(inventory.call("remove", coin, price)):
		return REFUSED_NO_COINS
	var leftover := int(inventory.call("add", item_id, count))
	if leftover > 0:
		# Should be unreachable -- has_room_for() was just asked. Put the
		# coins back rather than eating them if it ever is reached.
		inventory.call("add", coin, price)
		if leftover < count:
			inventory.call("remove", item_id, count - leftover)
		return REFUSED_NO_ROOM
	return OK


## Sell `count` of `item_id` to `vendor_id`, paid into `inventory`.
func sell(inventory: RefCounted, vendor_id: String, item_id: String, count: int = 1) -> String:
	if inventory == null or count <= 0:
		return REFUSED_UNKNOWN
	if not goods(vendor_id).has(item_id):
		return REFUSED_UNKNOWN
	if not buys(vendor_id, item_id):
		return REFUSED_NOT_BOUGHT
	if item_id == currency_id():
		# Selling coins for coins is not a trade; refuse rather than letting a
		# malformed config turn the panel into a laundry.
		return REFUSED_UNKNOWN
	var payment := sell_price(vendor_id, item_id) * count
	if int(inventory.call("count", item_id)) < count:
		return REFUSED_NO_ITEM
	if not bool(inventory.call("has_room_for", currency_id(), payment)):
		return REFUSED_NO_ROOM
	if not bool(inventory.call("remove", item_id, count)):
		return REFUSED_NO_ITEM
	var leftover := int(inventory.call("add", currency_id(), payment))
	if leftover > 0:
		inventory.call("add", item_id, count)
		if leftover < payment:
			inventory.call("remove", currency_id(), payment - leftover)
		return REFUSED_NO_ROOM
	return OK


## What a refusal should SAY, in the panel, to the player. Kept beside the
## reasons themselves so a new refusal cannot be added without a sentence.
static func refusal_text(reason: String, item_name: String = "that") -> String:
	match reason:
		REFUSED_NOT_SOLD:
			return "%s is not for sale here." % item_name
		REFUSED_NOT_BOUGHT:
			return "Nobody here wants %s." % item_name
		REFUSED_NO_COINS:
			return "Not enough coins."
		REFUSED_NO_ITEM:
			return "You have no %s to sell." % item_name
		REFUSED_NO_ROOM:
			return "No room in your satchel."
		OK:
			return ""
		_:
			return "That trade cannot be made."
