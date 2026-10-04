extends "res://tests/test_case.gd"

## F32 criterion #3: eight type crops grow on homestead plots; the Greenhouse
## (a Farm buildable, not an attachment) grows off-biome crops; every harvest
## is by hand.
##
## Disclosed fixtures: a detached WorldState per transaction step with the
## authored Meadows plot written through `set_farm_plot`; the character record
## is the ordinary PlayerState projection with seeds/hoe added; the frozen host
## context is built here (the live adapter derivation is exercised by
## tests/smoke_f32_type_crop_harvest.gd). Between sow and harvest the exact
## post-commit durable plot and owner state are carried into a fresh ledger
## world, because the owner save/ACK leg is not part of this pure suite.
## Production staging (f32_source_actions via foundation_actions.stage), the
## WorldLedger resource commit and DELIVERY.owner_plan are not mocked.
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const FARM := preload("res://scripts/world/farm_logic.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const STATION_RULES := preload("res://scripts/build/station_rules.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const CHARACTER := "type-crop-owner"
const TYPES := ["ground", "water", "air", "electric", "fire", "dark", "ice", "psychic"]
const PLOT_ID := "authored:0"

var _txn_counter := 0


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _farm() -> Dictionary:
	return _json("res://data/config/farm.json")


func _txn() -> String:
	_txn_counter += 1
	return ("crop-%d-%d" % [_txn_counter, Time.get_ticks_usec()]).md5_text()


func _character() -> Dictionary:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(ITEM_DB.new())
	player.character_id = CHARACTER
	player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	player.inventory.add("hoe", 1)
	for type_id: String in TYPES:
		player.inventory.add("seed_" + type_id, 2)
	return RECORD.portable_projection(player.save_data())


func _world(day: int, plot: Dictionary) -> RefCounted:
	var world := WORLD.new()
	world.world_id = "type-crop-slot"
	world.reward_delivery_namespace = "type-crop-namespace"
	world.day = day
	world.set_farm_plot(WORLD.resource_plot_index("meadows", PLOT_ID), plot)
	return world


func _context(world: RefCounted, revision: int, greenhouse: Variant) -> Dictionary:
	var live_plot: Dictionary = world.resource_plot_state("meadows", PLOT_ID)
	var context := {"character_id": CHARACTER, "expected_revision": revision,
		"source_key": "resource:meadows:" + PLOT_ID, "source_id": PLOT_ID,
		"world_id": world.world_id, "world_namespace": world.reward_delivery_namespace,
		"realm": "meadows", "actor_realm": "meadows", "host_day": int(world.day),
		"in_range": true, "in_combat": false, "modal_open": false,
		"registered_live_source": true, "source_generation": str(int(live_plot.revision)),
		"plot": live_plot, "equipped_tool": "", "resource_runtime_authorized": true,
		"foundation_runtime_authorized": true}
	if greenhouse != null:
		context.greenhouse_built = greenhouse
	return context


func _intent(world: RefCounted, action: String, crop_id: String) -> Dictionary:
	return {"operation": "farm", "request": {"plot_id": PLOT_ID, "action": action, "crop_id": crop_id,
		"expected_stock_revision": int(world.resource_plot_state("meadows", PLOT_ID).revision),
		"action_id": _txn()}}


## Stage + commit one farm verb through the real Foundation path. Returns the
## committed owner state, or {"refused": code} without touching either record.
func _commit(world: RefCounted, before: Dictionary, revision: int, action: String,
		crop_id: String, greenhouse: Variant) -> Dictionary:
	var context := _context(world, revision, greenhouse)
	var proposal := ACTIONS.stage(before, revision, "resource", _intent(world, action, crop_id), context, RECORD.errors)
	if proposal.get("ok") != true:
		return {"refused": str(proposal.get("code", ""))}
	proposal.character_revision = revision + 1
	var row := DELIVERY.make_record(world.world_id, world.reward_delivery_namespace, "type-crop-epoch",
		proposal, null, RECORD.errors)
	if row.is_empty():
		return {"refused": "row_invalid"}
	var verdict: Dictionary = LEDGER.new(world).commit_creature_training_delivery(row, 1)
	if verdict.get("ok") != true:
		return {"refused": "ledger:" + str(verdict.get("code", ""))}
	var owner := DELIVERY.owner_plan(before, row, RECORD.errors)
	if owner.get("ok") != true:
		return {"refused": "owner:" + str(owner.get("code", ""))}
	return {"state": owner.state, "receipt": row.receipt}


func _count(state: Dictionary, item: String) -> int:
	return BAG.inventory_from(state.inventory).count(item)


func _tilled() -> Dictionary:
	return {"state": FARM.TILLED, "ripe_on_day": 0, "revision": 1}


# --- eight crops ------------------------------------------------------------

func test_all_eight_type_crops_are_defined_with_registered_seeds_and_outputs() -> void:
	var config := _farm()
	var db := ITEM_DB.new()
	var order: Array = config.get("crop_order", [])
	var typed: Array = []
	for raw: Variant in order:
		var definition := FARM.crop_definition(config, str(raw))
		assert_false(definition.is_empty(), "crop %s has a valid host definition" % raw)
		if not str(definition.get("type", "")).is_empty():
			typed.append(str(definition.type))
	typed.sort()
	var expected := TYPES.duplicate()
	expected.sort()
	assert_eq(typed, expected, "exactly the eight type crops are in crop_order")
	for type_id: String in TYPES:
		var definition := FARM.crop_definition(config, type_id)
		assert_eq(definition.get("type"), type_id)
		assert_eq(definition.get("seed_item"), "seed_" + type_id)
		assert_true(db.has("seed_" + type_id), "seed_%s is a registered item" % type_id)
		assert_true(int(definition.get("grow_days", 0)) >= 1)
		for item: String in definition.outputs:
			assert_true(db.has(item), "%s output %s is a registered item" % [type_id, item])
		assert_eq(int(definition.outputs.get("essence_" + type_id, 0)) > 0, true, type_id + " yields its own essence")


func test_each_type_crop_ripens_only_on_its_host_day() -> void:
	var config := _farm()
	for type_id: String in TYPES:
		var grow := int(FARM.crop_definition(config, type_id).grow_days)
		var plot := FARM.planted_crop(_tilled(), 3, type_id, config, true)
		assert_eq(plot.get("state"), FARM.SOWN, type_id + " sown")
		assert_eq(plot.get("crop_id"), type_id)
		assert_eq(int(plot.get("ripe_on_day", 0)), 3 + grow)
		for day: int in range(3, 3 + grow):
			assert_eq(FARM.state_of(plot, day), FARM.SOWN, "%s still growing on day %d" % [type_id, day])
			assert_true(FARM.harvest_candidate(plot, day, config).is_empty(), type_id + " cannot be picked green")
		assert_eq(FARM.state_of(plot, 3 + grow), FARM.RIPE, type_id + " ripe on its configured day")


func test_each_type_crop_grows_through_the_host_transaction_on_the_authored_plot() -> void:
	var config := _farm()
	var native: Array = config.get("native_types", [])
	for type_id: String in TYPES:
		var definition := FARM.crop_definition(config, type_id)
		var grow := int(definition.grow_days)
		var before := _character()
		# Off-biome crops sow under a paid Greenhouse; native crops outdoors.
		var greenhouse := not native.has(type_id)
		var world := _world(2, _tilled())
		var sown := _commit(world, before, 0, "sow", type_id, greenhouse)
		assert_true(sown.has("state"), "%s sow committed: %s" % [type_id, sown])
		if not sown.has("state"): continue
		assert_eq(_count(sown.state, "seed_" + type_id), _count(before, "seed_" + type_id) - 1, type_id + " exactly one seed debited")
		for item: String in definition.outputs:
			assert_eq(_count(sown.state, item), _count(before, item), type_id + " sowing pays nothing")
		var plot: Dictionary = world.resource_plot_state("meadows", PLOT_ID)
		assert_eq(plot.get("state"), FARM.SOWN)
		assert_eq(plot.get("crop_id"), type_id)
		assert_eq(int(plot.get("planted_on_day", 0)), 2)
		assert_eq(int(plot.get("ripe_on_day", 0)), 2 + grow)
		assert_eq(int(plot.get("revision", 0)), 2)
		# Host world clock: advance the existing day counter to the ripe day.
		while int(world.day) < 2 + grow:
			assert_eq(FARM.state_of(world.resource_plot_state("meadows", PLOT_ID), int(world.day)), FARM.SOWN)
			world.advance_day()
		var stored: Dictionary = world.resource_plot_state("meadows", PLOT_ID)
		assert_eq(FARM.state_of(stored, int(world.day)), FARM.RIPE, type_id + " ripe on host day")
		assert_eq(stored.get("state"), FARM.SOWN, "growth is derived, not pushed into durable state")
		# Manual pick, staged against the carried durable plot and owner state.
		var picking := _world(int(world.day), stored)
		var picked := _commit(picking, sown.state, 1, "harvest", "", greenhouse)
		assert_true(picked.has("state"), "%s harvest committed: %s" % [type_id, picked])
		if not picked.has("state"): continue
		for item: String in definition.outputs:
			assert_eq(_count(picked.state, item) - _count(sown.state, item), int(definition.outputs[item]),
				"%s harvest pays exactly %s" % [type_id, item])
		assert_eq(picking.resource_plot_state("meadows", PLOT_ID).get("state"), FARM.TILLED, "picked bed stays worked")
		assert_true(picked.state.redesign_character.transaction_receipts.has(picked.receipt))


# --- native outdoors, off-biome under the Greenhouse -------------------------

func test_native_types_grow_outdoors_and_off_biome_types_need_the_greenhouse() -> void:
	var config := _farm()
	var native: Array = config.get("native_types", [])
	assert_false(native.is_empty(), "farm.json declares native types")
	for type_id: Variant in native:
		assert_true(TYPES.has(type_id), "native type %s is one of the eight" % type_id)
	assert_true(native.size() < TYPES.size(), "at least one type is off-biome")
	for type_id: String in TYPES:
		var is_native := native.has(type_id)
		assert_eq(FARM.can_grow(config, type_id, false), is_native, type_id + " outdoor rule")
		assert_true(FARM.can_grow(config, type_id, true), type_id + " grows with a Greenhouse")
		var before := _character()
		var outdoor := _world(2, _tilled())
		var plot_before: Dictionary = outdoor.resource_plot_state("meadows", PLOT_ID)
		var outdoor_result := _commit(outdoor, before, 0, "sow", type_id, false)
		if is_native:
			assert_true(outdoor_result.has("state"), "native %s sows outdoors: %s" % [type_id, outdoor_result])
		else:
			assert_eq(outdoor_result.get("refused"), "crop_locked_or_plot_busy", "off-biome %s refused outdoors" % type_id)
			assert_eq(outdoor.resource_plot_state("meadows", PLOT_ID), plot_before, "refusal leaves the plot")
			assert_eq(FARM.crop_label_for(_tilled(), 2, true, 1, config, type_id, false), "Needs a Greenhouse")
			var inside := _world(2, _tilled())
			var inside_result := _commit(inside, before, 0, "sow", type_id, true)
			assert_true(inside_result.has("state"), "off-biome %s accepted with a Greenhouse: %s" % [type_id, inside_result])
	# The host must state Greenhouse presence; a missing context never defaults open.
	assert_eq(_commit(_world(2, _tilled()), _character(), 0, "sow", "water", null).get("refused"),
		"greenhouse_context_required")


# --- the Greenhouse is a Farm buildable --------------------------------------

func test_greenhouse_is_a_farm_buildable_in_the_real_catalogue_not_an_attachment() -> void:
	var farm := _farm()
	var greenhouse: Dictionary = farm.get("greenhouse", {})
	assert_eq(greenhouse.get("buildable_id"), "greenhouse")
	assert_eq(greenhouse.get("station"), "farm")
	assert_eq(greenhouse.get("allows_off_biome_types"), true)
	var contract: Dictionary = greenhouse.get("buildable_candidate", {}).get("farm_contract", {})
	assert_eq(contract.get("one_farm_buildable_not_attachment"), true)
	assert_eq(contract.get("tier_attachment_track"), false)
	# Ordinary ItemDB catalogue (the build menu's source).
	var row: Dictionary = ITEM_DB.new().buildable("greenhouse")
	assert_false(row.is_empty(), "greenhouse is in the live build catalogue")
	assert_eq(row.get("station_id"), "farm")
	assert_eq(row.get("home_only"), true)
	assert_eq(row.get("cost"), greenhouse.buildable_candidate.get("cost"), "catalogue cost is the authored Greenhouse cost")
	# Station policy: one auxiliary Farm buildable, never an attachment row.
	var cfg := STATION_RULES.config()
	assert_false(cfg.is_empty(), "stations.json validates")
	assert_true(STATION_RULES.station(cfg, "farm"))
	assert_true(cfg.get("auxiliary_buildables", []).has("greenhouse"))
	assert_eq(cfg.get("greenhouse", {}).get("station_id"), "farm")
	assert_eq(int(cfg.get("greenhouse", {}).get("maximum_per_world", 0)), 1)
	assert_true(STATION_RULES.attachment(cfg, "greenhouse").is_empty(), "greenhouse is not an attachment")
	for attachment: Dictionary in cfg.get("attachments", []):
		assert_ne(attachment.get("station_id"), "farm", "no Farm attachment tier track: " + str(attachment.get("id")))
		assert_false(str(attachment.get("id")).contains("greenhouse"))
	assert_true(STATION_RULES.managed(cfg, "greenhouse"))
	var at := Vector3(-16, 0, 25)
	var first := STATION_RULES.placement(cfg, [], "greenhouse", "meadows", at, 0, {})
	assert_true(first.get("ok") == true, "greenhouse places at the homestead: " + str(first))
	assert_eq(first.get("parent_uid"), "", "greenhouse has no parent station")
	assert_eq(STATION_RULES.placement(cfg, [], "greenhouse", "meadows", at, 0, {}, "b1").get("code"),
		"attachment_parent_invalid", "greenhouse cannot snap to a station as an attachment")
	var built := [{"id": "greenhouse", "removed": false}]
	assert_eq(STATION_RULES.placement(cfg, built, "greenhouse", "meadows", at, 0, {}).get("code"),
		"greenhouse_already_built")


# --- every harvest by hand ---------------------------------------------------

func test_harvest_is_manual_and_days_never_move_produce_into_inventory() -> void:
	var farm := _farm()
	var runtime := _json("res://data/config/f32_runtime.json")
	assert_eq(farm.greenhouse.get("automatic_harvest"), false)
	assert_eq(farm.greenhouse.buildable_candidate.farm_contract.get("automatic_harvest"), false)
	assert_eq(farm.greenhouse.buildable_candidate.farm_contract.get("offline_production"), false)
	assert_eq(runtime.get("automatic_harvest"), false)
	assert_eq(runtime.get("manual_taps_only"), true)
	assert_eq(runtime.get("offline_production"), false)
	var before := _character()
	var world := _world(2, _tilled())
	var sown := _commit(world, before, 0, "sow", "ground", false)
	assert_true(sown.has("state"), str(sown))
	if not sown.has("state"): return
	var plot_after_sow: Dictionary = world.resource_plot_state("meadows", PLOT_ID)
	var saved_owner: Dictionary = sown.state.duplicate(true)
	# Many host days pass; nothing harvests, nothing pays, the crop waits.
	for step: int in 20:
		world.advance_day()
	var reloaded := WORLD.new()
	reloaded.load_data(JSON.parse_string(JSON.stringify(world.save_data())))
	var waiting: Dictionary = reloaded.resource_plot_state("meadows", PLOT_ID)
	assert_eq(waiting, plot_after_sow, "advancing days never rewrites the durable plot")
	assert_eq(FARM.state_of(waiting, int(reloaded.day)), FARM.RIPE, "crop is ripe and still on the plot")
	assert_eq(waiting.get("crop_id"), "ground")
	assert_eq(sown.state, saved_owner, "no produce reached the owner inventory")
	assert_eq(_count(sown.state, "essence_ground"), _count(before, "essence_ground"))
	assert_eq(_count(sown.state, "attuned_ground"), _count(before, "attuned_ground"))
	# Only a manual harvest intent moves it, and the client cannot name the crop.
	var picking := _world(int(reloaded.day), waiting)
	assert_eq(_commit(picking, sown.state, 1, "harvest", "ground", false).get("refused"), "client_crop_not_authority")
	var picked := _commit(picking, sown.state, 1, "harvest", "", false)
	assert_true(picked.has("state"), str(picked))
	if picked.has("state"):
		assert_eq(_count(picked.state, "essence_ground") - _count(sown.state, "essence_ground"), 3)
		assert_eq(_count(picked.state, "attuned_ground") - _count(sown.state, "attuned_ground"), 2)
	# A green crop cannot be picked early.
	var green := _world(2, plot_after_sow)
	assert_eq(_commit(green, sown.state, 1, "harvest", "", false).get("refused"), "crop_not_ripe")
