extends "res://tools/earned_saves/earned_chain_runner.gd"

## F31#2 actual-path witness: hanging a biome relic in the Shrine Room unlocks
## the next tier's attachment recipes, and the player carries ONE chosen relic
## power. Starts from the disclosed generated profile `f31_relic_power`
## (tests/fixtures/earned_saves/generated_boundary_profiles.json) through the
## runner's generated-fixture path, then plays only ordinary inputs:
##
##   godot --headless --path . --script tests/smoke_f31_relic_hang_power.gd
##
## 1. Home Key home, walk to the Meadows pedestal, hang the Meadows relic and
##    choose its power in the chooser (ui_down/ui_accept): the relic_hang
##    receipt grants exactly the four Tidewake attachment recipes, once.
## 2. Re-open the chooser at the pedestal and choose the same power: still one.
## 3. Hang the Tidewake relic (approached from the room's centre) and defer (menu_cancel): Meadows stays the only
##    power, the Cloudreach column is added without duplicates. Then choose
##    the Tidewake (water) power: it REPLACES Meadows; one active power.
## 4. Production save_game/load_game and world rebuild (_reload_transition):
##    hung relics, recipes and the one chosen power survive.
## Not claimed: earned Meadows campaign, two-peer rejoin, visuals.

const PORTAL := preload("res://tests/helpers/f49_portal_travel.gd")
const TIDEWAKE := ["altar_tidewake", "den_tidewake", "forge_tidewake", "kitchen_tidewake"]
const CLOUDREACH := ["altar_cloudreach", "den_cloudreach", "forge_cloudreach", "kitchen_cloudreach"]


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	segment = "f31_relic_power"
	game = root.get_node("Game")
	var scratch := OS.get_user_data_dir().path_join("f31_relic_power_%d_%d" % [OS.get_process_id(), Time.get_ticks_msec()])
	save_dir = scratch.path_join(segment + "/save")
	receipt_path = scratch.path_join(segment + "/receipt.json")
	generated_fixture = true
	game.set("save_system", SAVE.new(scratch + "_working"))
	if not await _generate_boundary_fixture():
		_finish()
		return
	disclosures.append("Generated profile f31_relic_power: Meadows and Tidewake relics held before any hang (setup).")
	var travel := PORTAL.new(self, game)
	var cid := str(game.local.character_id)
	# 1. Hang Meadows, choose its power through the real chooser.
	if not await travel.home_key() or not await travel.hang_relic("meadows", "meadows"):
		failures.append_array(travel.failures)
		_finish()
		return
	_expect(["meadows"], TIDEWAKE, "meadows", "1 meadows hung + power chosen")
	_check(_personal().transaction_receipts.has("relic_hang:meadows:" + cid), "1 the hang holds its relic_hang receipt")
	_check(_personal().relics_held == ["tidewake"], "1 the Meadows relic left the satchel for the pedestal")
	# 2. Re-open the chooser at the pedestal; the same choice stacks nothing.
	if not await travel.activate(_pedestal_prompt("meadows")) or not await travel.settle_power_chooser("meadows"):
		failures.append_array(travel.failures)
		_finish()
		return
	_expect(["meadows"], TIDEWAKE, "meadows", "2 re-opened chooser, same power")
	# 3. Hang the next relic and defer; then choose it.
	# Approach the Tidewake pedestal from the room's centre: from the Meadows
	# pedestal beside it, a 2.5 m stop leaves Meadows the nearer provider.
	if not await travel.activate(_pedestal_prompt("tidewake"), [_room_side("tidewake")]):
		failures.append_array(travel.failures)
		_finish()
		return
	for frame in 720:
		if (_personal().relics_hung as Array).has("tidewake"): break
		await process_frame
	if not (_personal().relics_hung as Array).has("tidewake") or not await travel.settle_power_chooser():
		failures.append("tidewake hang did not land or its chooser did not close")
		failures.append_array(travel.failures)
		_finish()
		return
	_expect(["meadows", "tidewake"], TIDEWAKE + CLOUDREACH, "meadows", "3 tidewake hung, choice deferred")
	if not await travel.activate(_pedestal_prompt("tidewake")) or not await travel.settle_power_chooser("water"):
		failures.append_array(travel.failures)
		_finish()
		return
	_expect(["meadows", "tidewake"], TIDEWAKE + CLOUDREACH, "water", "3 the Tidewake power replaced Meadows")
	# 4. Production save/load.
	if not await _reload_transition("f31_relic_power"):
		_finish()
		return
	_expect(["meadows", "tidewake"], TIDEWAKE + CLOUDREACH, "water", "4 after save/load")
	print("F31_RELIC_HANG_POWER " + JSON.stringify({"passed": failures.is_empty(), "relics_hung": _personal().relics_hung,
		"attachment_recipes": _personal().get("attachment_recipes", []), "active_power": str(game.realm_hearts.active_id()),
		"hearts_save": game.realm_hearts.save_data()}))
	_finish()


func _personal() -> Dictionary:
	return game.local.get("redesign_character")


func _pedestal_prompt(biome: String) -> Node3D:
	for candidate: Node in get_nodes_in_group("crossing_hall_pedestals"):
		if candidate.get_meta("biome", "") != biome: continue
		for child: Node in candidate.find_children("*", "", true, false):
			if child.has_method("interaction_offer"): return child as Node3D
	return null


func _room_side(biome: String) -> Vector3:
	var centre := Vector3.ZERO
	var count := 0
	var at := Vector3.ZERO
	for candidate: Node in get_nodes_in_group("crossing_hall_pedestals"):
		centre += (candidate as Node3D).global_position
		count += 1
		if candidate.get_meta("biome", "") == biome: at = (candidate as Node3D).global_position
	centre /= maxi(count, 1)
	var side := centre - at
	side.y = 0.0
	return at + side.normalized() * 2.0


func _expect(hung: Array, recipes: Array, power: String, label: String) -> void:
	var known: Array = (_personal().get("attachment_recipes", []) as Array).duplicate()
	known.sort()
	var want := recipes.duplicate()
	want.sort()
	var have_hung: Array = (_personal().relics_hung as Array).duplicate()
	have_hung.sort()
	_check(have_hung == hung, "%s: relics_hung %s" % [label, str(have_hung)])
	_check(known == want, "%s: attachment recipes %s" % [label, str(known)])
	_check(str(game.realm_hearts.active_id()) == power and game.realm_hearts.save_data().size() == 1,
		"%s: exactly one active relic power %s (%s)" % [label, power, str(game.realm_hearts.save_data())])


func _check(ok: bool, label: String) -> void:
	print("F31 RELIC %s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok: failures.append(label)
