extends "res://tests/test_case.gd"

const RUNTIME := preload("res://scripts/world/stormwood_harvest_runtime.gd")
const CROWN_SITE := "stormwood_harvest_conductor_run_071"
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
	assert_eq(fixture.chapter.events, ["harvest:crown_grade"], "claimed crown-grade site emits the exact chapter event")

	flags.set_flag("stormwood:crown_glass_gathered")
	fixture.runtime._process(0.51)
	assert_eq(fixture.chapter.events, ["harvest:crown_grade"], "completed crown objective is not emitted again")
	_dispose(fixture)


func test_crown_reconciliation_does_not_change_cinder_verge_behavior() -> void:
	var flags := Flags.new()
	flags.set_flag("harvest_node:order:" + VERGE_SITE)
	var fixture := _fixture(flags)

	fixture.runtime._process(0.0)
	assert_eq(fixture.chapter.events, ["harvest:verge_stormglass"])
	_dispose(fixture)
