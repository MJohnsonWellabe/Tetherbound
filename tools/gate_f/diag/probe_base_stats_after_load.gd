extends SceneTree

## GAME-F4 reproduction: a creature loaded from a save loses its species base
## stats, and the first level-up after that collapses it to ~1 HP.
##
##   godot --headless --path . --script tools/gate_f/diag/probe_base_stats_after_load.gd
##
## Runs in about a second and needs no world, because the defect is entirely in
## `scripts/save/save_game.gd`'s party round trip and `creature_instance.gd`'s
## stat recompute. Both are plain `RefCounted` scripts, so this drives the REAL
## production code -- not a copy of it -- with `autoload/party.gd` as the
## container the real loader writes into.
##
## What it does, in the order a player does it:
##
##   1. make the chapter's starter the way the opening makes it (`from_species`,
##      level 3, iv 0.5) and record its stats;
##   2. round-trip it through `save_game.gd`'s own `_party_to_array` /
##      `_array_to_party` -- the exact pair the Save tab and the title screen's
##      Load use;
##   3. level it up once, through `gain_xp`, the way winning a fight does;
##   4. print what the stats became, beside what they should have been.
##
## Measured by ralph/GATE-F-FULL on 2026-08-30 against `main` at 453107fb, in
## play as well as here: S03 loaded S02's exit save, Moss the level-3 ripplet
## went to level 4 mid-fight, and `max_hp` went 117.60 -> 1.18 with `attack`
## 26.40 -> 1.15 and `defence` 18.70 -> 1.15. Both of the player's creatures
## ended that segment fainted and the village ladder could not finish.
##
## EXIT CODES: 0 = the round trip preserves the stats (the defect is fixed);
## 1 = reproduced.

const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const PARTY := preload("res://autoload/party.gd")
const PROGRESSION_PATH := "res://data/config/progression.json"

const SPECIES_ID := "ripplet"
const START_LEVEL := 3


func _init() -> void:
	quit(_run())


func _run() -> int:
	var cfg := _progression_cfg()
	if cfg.is_empty():
		print("PROBE ERROR: could not read %s" % PROGRESSION_PATH)
		return 2
	var definition: Dictionary = SPECIES.definition(SPECIES_ID)
	if definition.is_empty():
		print("PROBE ERROR: no species '%s' in data/creatures/species.json" % SPECIES_ID)
		return 2

	# 1. The starter, as the opening grants it.
	var before: RefCounted = INSTANCE.from_species(SPECIES_ID, definition, -1.0, cfg, [0.5, 0.5, 0.5])
	before.set_level(START_LEVEL, cfg)
	print("fresh  L%d  base_hp=%.1f  max_hp=%.2f  attack=%.2f  defence=%.2f" % [
		int(before.get("level")), float(before.get("base_hp")), float(before.get("max_hp")),
		float(before.get("attack")), float(before.get("defence"))])

	# 2. Through the production save round trip.
	var save: RefCounted = SAVE_GAME.new()
	var out_party: RefCounted = PARTY.new()
	out_party.call("add", before)
	var serialised: Array = save.call("_party_to_array", out_party)
	print("saved keys: %s" % [", ".join(PackedStringArray((serialised[0] as Dictionary).keys()))])
	var in_party: RefCounted = PARTY.new()
	save.call("_array_to_party", serialised, in_party)
	var after: RefCounted = (in_party.call("members") as Array)[0]
	print("loaded L%d  base_hp=%.1f  max_hp=%.2f  attack=%.2f  defence=%.2f" % [
		int(after.get("level")), float(after.get("base_hp")), float(after.get("max_hp")),
		float(after.get("attack")), float(after.get("defence"))])

	# 3. One level-up, the way winning a fight does it.
	var needed := int(after.call("xp_to_next", cfg))
	var gained := int(after.call("gain_xp", needed, cfg))
	print("levelled +%d -> L%d  max_hp=%.2f  attack=%.2f  defence=%.2f" % [
		gained, int(after.get("level")), float(after.get("max_hp")),
		float(after.get("attack")), float(after.get("defence"))])

	# 4. What it should have been: the same level-up on the creature that never
	#    went through a save. Same code, same config, same rolls.
	before.call("gain_xp", int(before.call("xp_to_next", cfg)), cfg)
	print("expected  L%d  max_hp=%.2f  attack=%.2f  defence=%.2f" % [
		int(before.get("level")), float(before.get("max_hp")),
		float(before.get("attack")), float(before.get("defence"))])

	var ok := is_equal_approx(float(after.get("max_hp")), float(before.get("max_hp"))) \
		and is_equal_approx(float(after.get("attack")), float(before.get("attack"))) \
		and is_equal_approx(float(after.get("defence")), float(before.get("defence")))
	if ok:
		print("")
		print("PASS -- a loaded creature levels up to the same stats as one that never was saved.")
		return 0
	print("")
	print("REPRODUCED -- GAME-F4.")
	print("  base_hp survived the round trip as %.1f; creature_instance.gd:62 declares 1.0 as the" % float(after.get("base_hp")))
	print("  class default, and save_game.gd::_array_to_party never sets it. The stored max_hp/")
	print("  attack/defence are restored directly, so nothing is visibly wrong until the first")
	print("  _apply_level_stats() -- a level-up, an elixir, or an evolution -- recomputes every")
	print("  stat from base_hp and gets ~1.")
	print("  save_game.gd:751 and creature_instance.gd:40 both say the repair is done 'on the next")
	print("  apply_species_definition'. NO SUCH FUNCTION EXISTS anywhere in the repo -- those two")
	print("  comments are its only mentions.")
	return 1


func _progression_cfg() -> Dictionary:
	var file := FileAccess.open(PROGRESSION_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
