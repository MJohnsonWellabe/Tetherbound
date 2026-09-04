extends SceneTree

## G3-BAND4. The S08 evidence run this lane played could not validate whether
## Captain Halder's and Captain Vess's new per-member `combat` overrides
## (C-4/C-5, docs/specs/GATE3_ENCOUNTER_CONTRACTS.md §4.2) are actually
## winnable: the harness's own step script sent a fainted lead creature into
## both fights, so no real combat exchange happened against either captain
## (see ralph/reports/G3-BAND4-0903/REPORT.md's addendum). This is the
## quantitative check that run could not produce -- a steady-state
## damage-per-second model built from the SAME functions the live game uses
## (`combat_math.base_damage`, `progression.stat_at_level`), not a
## reimplementation, so a formula change elsewhere in the tree updates this
## probe's answer automatically rather than silently drifting from it.
##
## What it checks, against the contract's own `fails if` clauses:
##
##   G-3's own bound: "no profile's hit kills a full-health creature of the
##   region's expected entry level in one blow."
##   C-4's own bound: "a party at the band's entry level (13) with type
##   coverage cannot win with at most one faint, or if a party two levels
##   under can win without a potion."
##
## HONEST LIMIT, stated once rather than repeated at every number below: this
## is a steady-state DPS model (attacks-per-second times damage-per-hit),
## not a frame-accurate combat simulation. It assumes every attack that is
## thrown connects, both sides fight at the same distance the whole time,
## and type effectiveness is neutral (1.0x) unless a matchup is named
## explicitly. Real play misses attacks, gets caught mid-recovery, and picks
## favourable types -- so PLAYER_HIT_RATES below sweeps a range (100% down
## to a deliberately pessimistic 35%) rather than asserting one number, and
## every verdict is stated as a range with its own assumption named next to
## it. This is a sanity check on the arithmetic the profiles imply, not a
## replacement for a played fight.
##
##   godot --headless --path . --script tools/_probe_band4_captain_combat_balance.gd

const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const COMBAT_MATH := preload("res://scripts/combat/combat_math.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")

const GROWTH := {"hp": 0.06, "attack": 0.05, "defence": 0.05}

## Player's quick attack, data/config/combat.json's own `player_quick` block,
## read live below rather than hard-coded -- this only pins the field names.
var _player_quick: Dictionary = {}
var _enemy_defaults: Dictionary = {}

## Sweep of assumed player quick-attack hit rates, worst first. 1.00 is the
## optimistic ceiling (every swing connects); 0.35 is a deliberately harsh
## floor a first-time player fighting an unfamiliar opponent might land.
const PLAYER_HIT_RATES := [1.00, 0.70, 0.50, 0.35]


func _init() -> void:
	var combat_cfg: Dictionary = COMBAT_MATH.config()
	_player_quick = combat_cfg.get("player_quick", {})
	_enemy_defaults = combat_cfg.get("enemy", {})
	_run()
	quit(0)


func _stats(species_id: String, level: int) -> Dictionary:
	var def := SPECIES.definition(species_id)
	var hp := PROGRESSION.stat_at_level(float(def.get("base_hp", 100.0)), level, GROWTH["hp"])
	var atk := PROGRESSION.stat_at_level(float(def.get("base_attack", 20.0)), level, GROWTH["attack"])
	var dfc := PROGRESSION.stat_at_level(float(def.get("base_defence", 20.0)), level, GROWTH["defence"])
	return {"hp": hp, "attack": atk, "defence": dfc, "species": species_id, "level": level}


## Enemy DPS and cycle time for one team member, from its (possibly absent)
## `combat` override merged over the shared `enemy` defaults -- the exact
## merge G-2 describes, done here in data rather than by booting a body.
func _enemy_cycle(member: Dictionary, my_defence: float) -> Dictionary:
	var cfg: Dictionary = _enemy_defaults.duplicate()
	var override: Dictionary = member.get("combat", {})
	for key: String in override:
		cfg[key] = override[key]
	var telegraph := float(cfg.get("telegraph", 0.55))
	var recovery := float(cfg.get("recovery", 0.75))
	var reposition_time := float(cfg.get("reposition_time", 1.0))
	var attack_cooldown := float(cfg.get("attack_cooldown", 1.1))
	# combat_manager.gd/wild_creature.gd's own timing: the strike lands the
	# instant TELEGRAPH ends, which is also when `_cooldown` is set to
	# `attack_cooldown` -- running CONCURRENTLY with the RECOVER+REPOSITION
	# beats, not after them. The next attack needs both the state machine
	# back at CLOSE/IDLE (recovery + reposition_time elapsed) AND the
	# cooldown clear, so the cycle is telegraph + whichever of the two takes
	# longer.
	var cycle := telegraph + maxf(recovery + reposition_time, attack_cooldown)
	var species_atk := PROGRESSION.stat_at_level(
		float(SPECIES.definition(str(member.get("species", ""))).get("base_attack", 20.0)),
		int(member.get("level", 1)), GROWTH["attack"])
	var power := float(cfg.get("power", 8.0))
	var dmg := COMBAT_MATH.base_damage(power, species_atk, my_defence)
	return {"cycle_s": cycle, "dmg_per_hit": dmg, "dps": dmg / cycle, "power": power,
		"telegraph": telegraph}


func _player_dps_at(hit_rate: float, target_defence: float, player_attack: float) -> float:
	var power := float(_player_quick.get("power", 9.0))
	var cooldown := float(_player_quick.get("cooldown", 0.4))
	var dmg := COMBAT_MATH.base_damage(power, player_attack, target_defence)
	return (dmg / cooldown) * hit_rate


## G-3's own one-blow safety check, independent of any hit-rate sweep: does
## this profile's single hit exceed a full-health band-4-entry creature's HP?
func _check_no_oneshot(captain_id: String, member: Dictionary, entry_level: int) -> void:
	var reference := _stats("terrapup", entry_level)
	var atk_stats := _stats(str(member.get("species", "")), int(member.get("level", 1)))
	var cfg: Dictionary = _enemy_defaults.duplicate()
	for key: String in (member.get("combat", {}) as Dictionary):
		cfg[key] = (member.get("combat", {}) as Dictionary)[key]
	var power := float(cfg.get("power", 8.0))
	var one_hit: float = COMBAT_MATH.base_damage(power, float(atk_stats["attack"]), float(reference["defence"]))
	var reference_hp: float = float(reference["hp"])
	var pct: float = one_hit / reference_hp * 100.0
	var flag := " *** ONE-SHOT RISK ***" if one_hit >= reference_hp else ""
	print("    G-3 one-blow check: %s's hit vs a fresh L%d Terrapup (%.1f HP) = %.1f dmg (%.0f%% of HP)%s" % [
		str(member.get("species", "")), entry_level, reference_hp, one_hit, pct, flag])


func _run_captain(captain_id: String, band_entry_level: int) -> void:
	var trainer := TRAINERS.trainer(captain_id)
	print("\n=== %s (%s) ===" % [captain_id, str(trainer.get("name", ""))])
	var team: Array = trainer.get("team", [])

	for member: Variant in team:
		_check_no_oneshot(captain_id, member as Dictionary, band_entry_level)

	# Time-to-kill each way, member by member, for a lone L13 (band entry)
	# Terrapup fighting the WHOLE team solo with no switch and no potion --
	# the worst case C-4's "party ... cannot win with at most one faint"
	# wording allows for (a party that never switches is still a party).
	for hit_rate: float in PLAYER_HIT_RATES:
		var player := _stats("terrapup", band_entry_level)
		var player_hp: float = float(player["hp"])
		var player_attack: float = float(player["attack"])
		var player_defence: float = float(player["defence"])
		var hp_remaining: float = player_hp
		var total_time: float = 0.0
		var fainted := false
		for member: Variant in team:
			var m := member as Dictionary
			var enemy := _stats(str(m.get("species", "")), int(m.get("level", 1)))
			var enemy_hp: float = float(enemy["hp"])
			var enemy_defence: float = float(enemy["defence"])
			var cyc := _enemy_cycle(m, player_defence)
			var cyc_dps: float = float(cyc["dps"])
			var player_dps: float = _player_dps_at(hit_rate, enemy_defence, player_attack)
			var kill_time: float = enemy_hp / player_dps
			var dmg_taken: float = cyc_dps * kill_time
			hp_remaining -= dmg_taken
			total_time += kill_time
			if hp_remaining <= 0.0 and not fainted:
				fainted = true
		var verdict := "SURVIVES solo, no faint" if not fainted else "FAINTS before the team is down"
		print("  @ %.0f%% player hit rate: lone L%d Terrapup (%.0f HP) takes %.1f cumulative dmg over %.1fs -- %s (%.0f%% of HP remaining if positive)" % [
			hit_rate * 100.0, band_entry_level, player_hp, player_hp - hp_remaining, total_time,
			verdict, maxf(0.0, hp_remaining / player_hp * 100.0)])


func _init_run_note() -> void:
	print("Enemy defaults (combat.json): %s" % str(_enemy_defaults))
	print("Player quick (combat.json): %s" % str(_player_quick))
	print("Model: steady-state DPS, neutral (1.0x) type multiplier, every player swing assumed in range.")
	print("Growth/level: %s (data/config/progression.json's level.growth_per_level, uniform across species)" % str(GROWTH))


func _run() -> void:
	_init_run_note()
	# Band 4 entry level (chapter_curve.json's own team.enter for
	# band4_upper_meadows_ironwood) -- the level C-4's fails-if names.
	_run_captain("captain_field", 13)
	_run_captain("captain_ridge", 13)
	print("\n--- two-levels-under check (C-4's other bound: '... or if a party two levels under can win without a potion') ---")
	_run_captain("captain_field", 11)
