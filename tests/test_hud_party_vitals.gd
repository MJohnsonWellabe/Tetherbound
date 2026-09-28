extends "res://tests/test_case.gd"

const HUD := preload("res://scripts/ui/playground_hud.gd")
const PARTY := preload("res://autoload/party.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

class StripProbe extends Control:
	var entries: Array = []
	var updates := 0
	var reveals := 0
	func update_from_party(rows: Array, _index: int, _out: bool) -> void:
		entries = rows.duplicate(true)
		updates += 1
	func show_strip() -> void:
		reveals += 1

func _fixture(enabled: bool) -> Dictionary:
	var party := PARTY.new()
	for i in 2:
		party.add(CREATURE.from_species("terrapup", {"display_name": "Probe%d" % i, "base_hp": 100}))
	var hud := HUD.new()
	var strip := StripProbe.new()
	hud.set("_party", party)
	hud.set("_party_strip", strip)
	hud.call("_apply_hud_config", {"party_vitals_refresh_candidate": enabled})
	hud.call("_update_party_strip")
	return {"party": party, "hud": hud, "strip": strip}

func _dispose(f: Dictionary) -> void:
	f.strip.free()
	f.hud.free()

func test_benched_damage_and_faint_refresh_without_roster_change_or_reveal() -> void:
	var f := _fixture(true)
	var revision: int = f.party.revision
	var benched: RefCounted = f.party.at(1)
	benched.take_damage(benched.max_hp / 2.0)
	f.hud.call("_update_party_strip")
	assert_almost_eq(f.strip.entries[1].hp_fraction, 0.5, 0.001)
	benched.take_damage(benched.max_hp)
	f.hud.call("_update_party_strip")
	assert_eq(f.strip.entries[1].hp_fraction, 0.0)
	assert_true(f.strip.entries[1].fainted)
	assert_eq(f.party.revision, revision)
	assert_eq(f.strip.updates, 3)
	assert_eq(f.strip.reveals, 1, "Vitals refresh must not reopen the roster")
	f.hud.call("_update_party_strip")
	assert_eq(f.strip.updates, 3, "Unchanged vitals keep the cache")
	_dispose(f)

func test_recovery_and_bed_assignment_refresh_existing_rows() -> void:
	var f := _fixture(true)
	var creature: RefCounted = f.party.at(0)
	creature.take_damage(creature.max_hp)
	f.hud.call("_update_party_strip")
	creature.heal_fully()
	f.hud.call("_update_party_strip")
	assert_eq(f.strip.entries[0].hp_fraction, 1.0)
	assert_false(f.strip.entries[0].fainted)
	creature.resting = true
	f.hud.call("_update_party_strip")
	assert_true(f.strip.entries[0].resting)
	creature.resting = false
	f.hud.call("_update_party_strip")
	assert_false(f.strip.entries[0].resting)
	assert_eq(f.strip.reveals, 1)
	_dispose(f)

func test_default_off_preserves_existing_refresh_behavior() -> void:
	var f := _fixture(false)
	var creature: RefCounted = f.party.at(0)
	creature.take_damage(creature.max_hp)
	f.hud.call("_update_party_strip")
	assert_eq(f.strip.updates, 1)
	assert_eq(f.strip.entries[0].hp_fraction, 1.0)
	assert_false(f.strip.entries[0].fainted)
	_dispose(f)
