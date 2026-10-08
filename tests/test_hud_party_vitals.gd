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

func _fixture(config: Dictionary = {}) -> Dictionary:
	var party := PARTY.new()
	for i in 2:
		party.add(CREATURE.from_species("terrapup", {"display_name": "Probe%d" % i, "base_hp": 100}))
	var hud := HUD.new()
	var strip := StripProbe.new()
	hud.set("_party", party)
	hud.set("_party_strip", strip)
	hud.call("_apply_hud_config", config)
	hud.call("_update_party_strip")
	return {"party": party, "hud": hud, "strip": strip}

func _dispose(f: Dictionary) -> void:
	f.strip.free()
	f.hud.free()

func test_benched_damage_and_faint_refresh_without_roster_change_or_reveal() -> void:
	var f := _fixture()
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
	var f := _fixture()
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

func test_missing_and_legacy_false_config_cannot_leave_stale_healthy_rows() -> void:
	for config: Dictionary in [{}, {"party_vitals_refresh_candidate": false}]:
		var f := _fixture(config)
		var creature: RefCounted = f.party.at(0)
		creature.take_damage(creature.max_hp)
		f.hud.call("_update_party_strip")
		assert_eq(f.strip.updates, 2)
		assert_eq(f.strip.entries[0].hp_fraction, 0.0)
		assert_true(f.strip.entries[0].fainted)
		assert_eq(f.strip.reveals, 1, "Live vitals must not change the reveal policy")
		f.hud.call("_update_party_strip")
		assert_eq(f.strip.updates, 2, "Unchanged faint state still uses the cache")
		_dispose(f)
