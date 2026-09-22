extends "res://tests/test_case.gd"

# ROADMAP Phase 1 item 8: "Close progression/economy/care solvency ... Prove
# solo and four-player ledgers with two-loss recovery".
#
# Most of item 8's economy is already held elsewhere, and this file deliberately
# does not repeat it: `test_trade.gd` owns vendor atomicity, refusals and the
# no-buy-then-sell-at-profit rule; `test_encounter_rewards.gd` owns per-
# participant addressing; `test_reward_delivery.gd` owns full-satchel
# pending/settle; `test_chapter_rewards.gd` owns the reward map and its TM sink.
#
# What nothing checked is the question item 8 actually asks: can a player who
# does only what the chapter REQUIRES afford to lose twice? Optional content is
# optional. A chapter that is solvent only for a completionist is not solvent.
#
# Every figure here is read from shipping data or from a SYSTEMS line that names
# it, never invented.

const REWARDS := preload("res://scripts/net/encounter_rewards.gd")

const AUDIT_PATH := "res://data/config/chapter_rewards.json"
const TRADE_PATH := "res://data/config/trade.json"

const REALM := "meadows"

## SYSTEMS §"Target supply policy": "After tournament, roadside supply stock per
## character per earned day: 2 small potions, 1 revive, 3 food." That is the
## document's own figure for what one recovery costs to restock, so it is the
## basket a loss is priced at rather than a number chosen here. Food is left out
## because SYSTEMS also says a player with zero coins "can ... gather basic
## food" -- charging for it would contradict the same paragraph.
const LOSS_BASKET := {"potion_small": 2, "revive": 1}

## "two-loss recovery", from item 8's own wording.
const LOSSES := 2

## Peer ids: a joiner's is a large random 32-bit number, so nothing here may
## assume an ordering or a small value.
const FOUR_PEERS := [1, 1_369_099_083, 884_120_557, 2_014_773_311]


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _price(item_id: String) -> int:
	var vendors: Dictionary = _json(TRADE_PATH).get("vendors", {}) as Dictionary
	var dearest := 0
	for raw: Variant in vendors.values():
		var goods: Dictionary = (raw as Dictionary).get("goods", {}) as Dictionary
		if goods.has(item_id):
			dearest = maxi(dearest, int((goods[item_id] as Dictionary).get("buy", 0)))
	return dearest


func _loss_basket_price() -> int:
	var total := 0
	for item_id: String in LOSS_BASKET:
		total += _price(item_id) * int(LOSS_BASKET[item_id])
	return total


## Coins the chapter pays for content it REQUIRES, per the reward map's own
## `required` column, plus the starting float. Optional rows are excluded on
## purpose: that exclusion is the whole point of the check.
func _required_income() -> int:
	var income := int(_json(TRADE_PATH).get("starting_coins", 0))
	for raw: Variant in (_json(AUDIT_PATH).get("activities", []) as Array):
		if raw is not Dictionary:
			continue
		var row := raw as Dictionary
		if not bool(row.get("required", false)):
			continue
		var reward: Dictionary = row.get("reward", {}) as Dictionary
		for key: String in ["coins", "coin"]:
			var value: Variant = reward.get(key, 0)
			if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
				income += int(value)
	return income


func _optional_income() -> int:
	var income := 0
	for raw: Variant in (_json(AUDIT_PATH).get("activities", []) as Array):
		if raw is not Dictionary:
			continue
		var row := raw as Dictionary
		if bool(row.get("required", false)):
			continue
		var reward: Dictionary = row.get("reward", {}) as Dictionary
		for key: String in ["coins", "coin"]:
			var value: Variant = reward.get(key, 0)
			if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
				income += int(value)
	return income


func test_the_prices_this_check_is_built_on_are_real() -> void:
	# Without this, every figure below could be zero and the ledger would
	# "balance" against nothing.
	for item_id: String in LOSS_BASKET:
		assert_true(_price(item_id) > 0,
			"no vendor sells '%s'; the loss basket this file prices is imaginary" % item_id)
	assert_true(_loss_basket_price() > 0, "the loss basket costs nothing")
	assert_true(_required_income() > 0, "the reward map records no required coin income")


func test_the_required_route_alone_pays_for_two_losses() -> void:
	# The solo ledger. A player who skips every optional activity must still be
	# able to restock after losing twice.
	var income := _required_income()
	var cost := _loss_basket_price() * LOSSES
	assert_true(income >= cost,
		("the chapter's REQUIRED content pays %d coins and recovering from %d losses costs %d; "
		+ "the Meadows is solvent only for a completionist") % [income, LOSSES, cost])


func test_optional_content_is_a_margin_and_not_the_budget() -> void:
	# The other half of the same question. If the optional activities carried
	# most of the chapter's money, "required-route solvency" would be true by a
	# hair and false the moment anything was retuned.
	var required := _required_income()
	var optional := _optional_income()
	assert_true(optional > 0,
		"the reward map records no optional coin income; item 6's activities pay nothing")
	assert_true(required > optional,
		("optional content pays %d coins against the required route's %d; the chapter's money "
		+ "is in content a player can walk past") % [optional, required])


func test_four_players_are_each_owed_the_whole_payout_not_a_share_of_it() -> void:
	# The four-player ledger. If a payout were divided, the solvency proved
	# above would be a solo-only result and co-op would quietly be four times
	# poorer per head -- which is exactly the failure a per-participant journal
	# exists to prevent, and worth pinning against the ledger figures rather
	# than only in the abstract.
	var spec := {
		"id": "solvency_probe",
		"defeat_flag": "defeated_captain_field",
		"reward": {"coins": 150, "items": [{"id": "revive", "count": 2}]},
	}
	var solo: Array = REWARDS.grants(spec, REALM, [FOUR_PEERS[0]])
	var four: Array = REWARDS.grants(spec, REALM, FOUR_PEERS)
	assert_eq(four.size(), solo.size(),
		"a four-player fight produced a different number of grants than a solo one")

	var checked := 0
	for raw: Variant in four:
		var grant := raw as Dictionary
		var peers: Array = grant.get("peers", []) as Array
		assert_eq(peers.size(), FOUR_PEERS.size(),
			"grant '%s' does not address all four participants" % grant.get("source", ""))
		for solo_raw: Variant in solo:
			var solo_grant := solo_raw as Dictionary
			if str(solo_grant.get("source", "")) != str(grant.get("source", "")):
				continue
			checked += 1
			assert_eq(int(grant.get("count", 0)), int(solo_grant.get("count", -1)),
				("'%s' pays a different amount with four players than with one; "
				+ "the payout is being shared out") % grant.get("source", ""))
	assert_true(checked >= 2,
		"only %d components were compared solo against four-player; this check has gone quiet"
		% checked)
