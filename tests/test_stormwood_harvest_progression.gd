extends "res://tests/test_case.gd"

const RUNTIME := preload("res://scripts/world/stormwood_harvest_runtime.gd")
const CROWN_SITE := "stormwood_harvest_conductor_run_071"
const SECOND_CROWN_SITE := "stormwood_harvest_conductor_run_072"
const VERGE_SITE := "stormwood_harvest_cinder_verge_003"


class Flags extends RefCounted:
	var revision := 0
	var values: Dictionary = {}

	func has(id: String) -> bool:
		return values.has(id)

	func set_flag(id: String) -> void:
		if values.has(id):
			return
		values[id] = true
		revision += 1


class ChapterFixture extends Node:
	var events: Array[String] = []

	func emit_event(event_id: String) -> void:
		events.append(event_id)


class WorldFixture extends Node3D:
	var simulation_only := false


func _fixture(flags: Flags) -> Dictionary:
	var world := WorldFixture.new()
	var chapter := ChapterFixture.new()
	chapter.name = "StormwoodChapter"
	world.add_child(chapter)
	var runtime := RUNTIME.new()
	runtime.world = world
	runtime._flags = flags
	runtime._catalogue = RUNTIME.read()
	return {"world": world, "chapter": chapter, "runtime": runtime}


func _dispose(fixture: Dictionary) -> void:
	(fixture.runtime as Node).free()
	(fixture.world as Node).free()


func test_authored_crown_claim_reconciles_through_the_chapter_event() -> void:
	var flags := Flags.new()
	flags.set_flag("harvest_node:order:" + CROWN_SITE)
	var fixture := _fixture(flags)

	fixture.runtime._process(0.0)
	assert_true(fixture.chapter.events.is_empty(), "crown harvest waits for the authored recipe prerequisite")

	flags.set_flag("stormwood:arch_recipe_known")
	fixture.runtime._process(0.51)
	assert_true(fixture.chapter.events.is_empty(), "one three-unit claim cannot complete preparation for the six-unit arch")
	flags.set_flag("harvest_node:order:" + SECOND_CROWN_SITE)
	fixture.runtime._process(0.51)
	assert_eq(fixture.chapter.events, ["harvest:crown_grade"], "enough shared Crown claims emit the exact chapter event")

	flags.set_flag("stormwood:crown_glass_gathered")
	fixture.runtime._process(0.51)
	assert_eq(fixture.chapter.events, ["harvest:crown_grade"], "completed crown objective is not emitted again")
	_dispose(fixture)


func test_sufficient_early_claims_reconcile_when_recipe_is_learned() -> void:
	var flags := Flags.new()
	flags.set_flag("harvest_node:order:" + CROWN_SITE)
	flags.set_flag("harvest_node:order:" + SECOND_CROWN_SITE)
	var fixture := _fixture(flags)
	fixture.runtime._process(0.0)
	assert_true(fixture.chapter.events.is_empty())
	flags.set_flag("stormwood:arch_recipe_known")
	fixture.runtime._process(0.51)
	assert_eq(fixture.chapter.events, ["harvest:crown_grade"])
	_dispose(fixture)


func test_readiness_uses_catalogue_amounts_and_unique_shared_claims() -> void:
	var flags := Flags.new()
	flags.set_flag("harvest_node:order:" + CROWN_SITE)
	flags.set_flag("harvest_node:order:" + VERGE_SITE)
	var catalogue := RUNTIME.read()
	assert_eq(RUNTIME.claimed_crown_glass(catalogue, flags), 3, "ordinary stormglass and unclaimed Crown sites do not count")
	var site: Dictionary = {}
	for row: Dictionary in catalogue.sites:
		if str(row.id) == CROWN_SITE:
			site = row.duplicate(true)
	assert_false(site.is_empty())
	site.amount = RUNTIME.crown_glass_cost() - 1
	assert_eq(RUNTIME.claimed_crown_glass({"sites": [site, site]}, flags), site.amount,
		"a repeated catalogue row cannot turn one claim into two grants")
	var fixture := _fixture(flags)
	fixture.runtime._catalogue = {"sites": [site]}
	flags.set_flag("stormwood:arch_recipe_known")
	fixture.runtime._process(0.0)
	assert_true(fixture.chapter.events.is_empty(), "readiness requires the production cost, not a fixed count of sites")
	site.amount += 1
	fixture.runtime._process(0.51)
	assert_eq(fixture.chapter.events, ["harvest:crown_grade"], "catalogue yield reaching the production cost completes gathering")
	_dispose(fixture)


func test_saved_completion_and_authority_shell_are_not_rewritten() -> void:
	var flags := Flags.new()
	flags.set_flag("stormwood:arch_recipe_known")
	flags.set_flag("stormwood:crown_glass_gathered")
	var fixture := _fixture(flags)
	fixture.runtime._process(0.0)
	assert_true(flags.has("stormwood:crown_glass_gathered"), "old completed saves remain completed without reconstructed claims")
	assert_true(fixture.chapter.events.is_empty())
	_dispose(fixture)
	flags = Flags.new()
	flags.set_flag("stormwood:arch_recipe_known")
	flags.set_flag("harvest_node:order:" + CROWN_SITE)
	flags.set_flag("harvest_node:order:" + SECOND_CROWN_SITE)
	fixture = _fixture(flags)
	fixture.world.simulation_only = true
	fixture.runtime._process(0.0)
	assert_true(fixture.chapter.events.is_empty(), "simulation shell does not add another event attribution path")
	assert_eq(RUNTIME.crown_glass_cost(), 6, "current Crown footing substitutes Crown glass in the real six-unit arch recipe")
	_dispose(fixture)


func test_crown_reconciliation_does_not_change_cinder_verge_behavior() -> void:
	var flags := Flags.new()
	flags.set_flag("harvest_node:order:" + VERGE_SITE)
	var fixture := _fixture(flags)

	fixture.runtime._process(0.0)
	assert_eq(fixture.chapter.events, ["harvest:verge_stormglass"])
	_dispose(fixture)
