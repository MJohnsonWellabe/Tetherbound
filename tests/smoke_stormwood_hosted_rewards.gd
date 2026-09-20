extends SceneTree

## Stormwood deliberately routes trainer rounds through its host-owned hub in
## solo as well as multiplayer.  This focused smoke proves that the hub payout
## uses reward authority (solo/host), not the shared director's narrower
## active-network authority, and that the real ledger keeps every component
## exactly once.
const DIRECTOR := preload("res://scripts/combat/stormwood_encounter_director.gd")
const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const REWARDS := preload("res://scripts/net/encounter_rewards.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TEST_ITEM := "good_candy"
const CHARACTER_ID := "character-stormwood-hosted-reward-fixture"


class SessionFixture extends Node:
	var host := true
	var active := false

	func is_host() -> bool:
		return host

	func is_active() -> bool:
		return active

	func local_peer_id() -> int:
		return 1


class DirectorFixture extends DIRECTOR:
	func _ready() -> void:
		pass


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_finish(false, "Game autoload is unavailable")
		return
	game.set("save_system", SAVE_GAME.new(
		"user://stormwood_reward_authority_%d/" % Time.get_ticks_usec()))
	var session := SessionFixture.new()
	var director := DirectorFixture.new()
	root.add_child(session)
	root.add_child(director)
	director.set("_session", session)

	var all_ok := true
	var spec := {
		"id": "stormwood_hosted_reward_authority",
		"name": "Stormwood reward authority fixture",
		"defeat_flag": "stormwood:trainer:stormwood_hosted_reward_authority:defeated",
		"reward": {"items": [{"id": TEST_ITEM, "count": 2}]},
	}

	# An inactive session is ordinary solo.  Both the durable world fact and
	# the participant's item/receipt must be committed by the production paths.
	_reset_character(game)
	session.host = true
	session.active = false
	all_ok = _check(not bool(director.call("_is_host")),
		"solo fixture is outside the shared director's active-network host gate") and all_ok
	director.call("award_hosted_trainer", spec, [1])
	all_ok = _check(bool(game.get("progression").call("has", spec.defeat_flag)),
		"solo records the hosted trainer defeat flag") and all_ok
	all_ok = _check(_item_count(game, TEST_ITEM) == 2,
		"solo grants the authored item through the real ledger") and all_ok
	var source := REWARDS.source_for(str(spec.id), "item:" + TEST_ITEM)
	all_ok = _check(_durable_delivery_settled(game, source),
		"solo records the stable character delivery and durable acceptance") and all_ok
	director.call("award_hosted_trainer", spec, [1])
	all_ok = _check(_item_count(game, TEST_ITEM) == 2
			and (game.get("world").reward_deliveries as Dictionary).size() == 1
			and _durable_delivery_settled(game, source),
		"replaying the hosted payout cannot duplicate inventory or its durable receipt") and all_ok

	# The same path remains valid for a live host.
	_reset_character(game)
	session.host = true
	session.active = true
	director.call("award_hosted_trainer", spec, [1])
	all_ok = _check(bool(game.get("progression").call("has", spec.defeat_flag))
			and _item_count(game, TEST_ITEM) == 2
			and _durable_delivery_settled(game, source),
		"active host commits world fact and durable participant grant") and all_ok

	# A live client must not write either half locally.
	_reset_character(game)
	session.host = false
	session.active = true
	director.call("award_hosted_trainer", spec, [1])
	all_ok = _check(not bool(game.get("progression").call("has", spec.defeat_flag))
			and _item_count(game, TEST_ITEM) == 0,
		"active client refuses the complete hosted payout") and all_ok

	# Captain Marrow is authored without an item payout, but the same repaired
	# guard must still settle the Dynamo climax's canonical defeat fact offline.
	var marrow := _trainer_spec("captain_marrow_dynamo_core")
	_reset_character(game)
	session.host = true
	session.active = false
	director.call("award_hosted_trainer", marrow, [1])
	all_ok = _check(not marrow.is_empty()
			and bool(game.get("progression").call("has", str(marrow.get("defeat_flag", "")))),
		"solo Dynamo payout records Captain Marrow's authored defeat fact") and all_ok

	director.free()
	session.free()
	_finish(all_ok, "hosted reward authority and ledger settlement")


func _trainer_spec(id: String) -> Dictionary:
	for spec: Dictionary in CATALOGUE.trainer_specs():
		if str(spec.get("id", "")) == id:
			return spec
	return {}


func _reset_character(game: Node) -> void:
	game.call("reset_for_new_game")
	# New Game identity is normally minted by the title flow before gameplay.
	# This scene-less fixture must supply the same stable durable identity.
	game.get("local").character_id = CHARACTER_ID


func _durable_delivery_settled(game: Node, source: String) -> bool:
	var world_namespace := str(game.get("world").reward_delivery_namespace)
	var id := REWARD_DELIVERY.delivery_id(world_namespace, source, CHARACTER_ID)
	var world_row: Variant = (game.get("world").reward_deliveries as Dictionary).get(id)
	var character_row: Variant = (game.get("local").satchel_escrow as Dictionary).get(id)
	return not id.is_empty() and world_row is Dictionary and character_row is Dictionary \
		and str((world_row as Dictionary).get("status", "")) == "accepted" \
		and str((character_row as Dictionary).get("status", "")) == "settled"


func _item_count(game: Node, id: String) -> int:
	var inventory: RefCounted = game.get("inventory") as RefCounted
	return int(inventory.call("count", id)) if inventory != null else -1


func _check(condition: bool, label: String) -> bool:
	print("%s  %s" % ["PASS" if condition else "FAIL", label])
	return condition


func _finish(ok: bool, label: String) -> void:
	print("STORMWOOD HOSTED REWARDS %s: %s" % ["PASS" if ok else "FAIL", label])
	quit(0 if ok else 1)
