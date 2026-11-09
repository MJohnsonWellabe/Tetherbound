extends "res://tests/test_case.gd"

const DELIVERY := preload("res://scripts/net/trainer_reward_delivery.gd")
const PARTY := preload("res://autoload/party.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

class MessageSink extends Node:
	var lines: Array[String] = []
	func push_world_message(line: String) -> void:
		lines.append(line)

func test_persistent_reward_pays_only_nonfainted_owned_creatures() -> void:
	var party := PARTY.new()
	var healthy := CREATURE.from_species("terrapup", {"display_name": "Healthy", "base_hp": 100.0})
	var fainted := CREATURE.from_species("terrapup", {"display_name": "Fainted", "base_hp": 100.0})
	fainted.fainted = true
	party.add(healthy)
	party.add(fainted)
	var sink := MessageSink.new()
	DELIVERY.apply(party, sink, {"xp": 1, "line": "Trainer defeated."})
	assert_eq(healthy.xp, 1)
	assert_eq(fainted.xp, 0)
	assert_eq(sink.lines.size(), 1)
	assert_eq(sink.lines[0], "Trainer defeated.")
	sink.free()

func test_no_xp_payload_keeps_party_unchanged_and_empty_message_is_silent() -> void:
	var party := PARTY.new()
	var creature := CREATURE.from_species("terrapup", {"display_name": "Healthy", "base_hp": 100.0})
	party.add(creature)
	var sink := MessageSink.new()
	DELIVERY.apply(party, sink, {})
	assert_eq(creature.xp, 0)
	assert_true(sink.lines.is_empty())
	sink.free()
