extends SceneTree

## W23-DIFFICULTY. How hard is an ORDINARY fight, measured rather than felt?
##
##   godot --headless --path . --script tests/smoke_combat_baseline.gd
##   godot --headless --path . --script tests/smoke_combat_baseline.gd -- --seeds=48
##   godot --headless --path . --script tests/smoke_combat_baseline.gd -- --all-trainers
##   godot --headless --path . --script tests/smoke_combat_baseline.gd -- --json=path
##
## The owner, on hardware (docs/owner/OWNER_PLAYTEST_2026-09-04.md, OP-0904-5):
## "Beating creatures and other trainers is way too easy." Named opponents
## have real behaviour from the G-2 per-encounter profiles; this says the
## BASELINE -- the ordinary wild, the ordinary trainer -- is soft. Before any
## number moves, the question has to be answerable in a table, and re-askable
## after: that is what this file is.
##
## WHAT IT RUNS. For every chapter_curve.json region, at that region's `team.enter`
## level, the typical five (`difficulty.party` in chapter_curve.json) fights
##   (a) every wild species the region's spawn table fields, at the band's median
##       level, count-weighted into one row (the lead fights; no switching);
##   (b) the band's weakest authored trainer, whole team, with the manager's own
##       auto-switch-on-faint (a trainer fight is a roster against a roster);
## plus the village tournament at its entry level and the Warden and the elite
## at the level the pacing probe says the team reaches them. N seeded runs of
## each, under one PILOT POLICY: close to reach, quick attack whenever it is
## ready, charged the moment the meter is full, chase when the opponent backs
## off, and DODGE NOTHING. No potions, no revives, no type-picking. That is the
## floor of competence, and it is the baseline the owner calls too easy: if this
## pilot wins every fight with most of its health, every real player does.
##
## WHAT IT IS MADE OF. Not a re-implementation of combat. Every number comes
## through the same readers the real fight uses -- `combat_math.rolled_damage`,
## `combat_ai.decide/duration_for/movement_for/speed_for`, `creature_instance`
## stats at level, `move_db` power and type, `type_chart`, `trainer_npc.team_of`
## and `creature_for` (moves and `combat` overrides included), and
## `wild_creature._enemy_config_for_this_body` for the merged per-body block.
## What is MODELLED rather than run is the physics: a 2D plane instead of the
## heightfield, capsule contact as a distance floor, the attack lunge as the
## displacement its impulse integrates to (lunge / impulse_damping), and the
## opponent always facing its target (which it does -- `_tick_combat` calls
## `face_towards` every tick). tests/smoke_combat.gd proves the WIRING in the
## real scene; this proves the ARITHMETIC of a whole fight, thousands of times,
## in seconds. The two are read together, never one instead of the other.
##
## WHAT IT ASSERTS. The `difficulty` block of chapter_curve.json names the
## targets (docs/decisions/D77): an ordinary wild at band entry costs the lead a
## real fraction of its health; the band's floor trainer is lost by this pilot
## some of the time without preparation; the tournament stays winnable at its
## entry level; the Warden stays winnable at the level the team reaches him and
## no harder-than-the-elite guard is broken; and G-3's own fails-if -- no hit
## anywhere in the chapter one-shots a full-health creature of the region's
## entry level. Each is a range read from data, so retuning the target is a
## config edit, and softening the game back below it fails this file.

const CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const TYPE_CHART := preload("res://scripts/combat/type_chart.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")

const SPAWNS_PATH := "res://data/config/spawns.json"
const TRAINERS_PATH := "res://data/config/trainers.json"

## Physics rate the real fight runs at. The AI's clocks and the player's
## cooldowns are all ticked per physics frame, so this is the resolution.
const DT := 1.0 / 60.0
## A fight that has not resolved in this much simulated time is a stall in the
## model, not a hard fight; reported as a loss and named.
const FIGHT_SECONDS_LIMIT := 240.0

enum Action { READY, WINDUP, RECOVERY }

var _seeds: int = 24
var _all_trainers: bool = false
var _json_path: String = ""
var _failures: Array[String] = []
var _moves: RefCounted = null
var _prog: Dictionary = {}
var _combat: Dictionary = {}
var _difficulty: Dictionary = {}
## Every row printed, for the --json dump and the assertions.
var _rows: Array[Dictionary] = []


func _init() -> void:
	_parse_args()
	_moves = MOVE_DB.load_default()
	_prog = PROGRESSION.config()
	_combat = MATH.config()
	_difficulty = CURVE.config().get("difficulty", {}) as Dictionary
	if _difficulty.is_empty():
		_fail("chapter_curve.json has no `difficulty` block; nothing to measure against")
	_run()
	_report()


func _parse_args() -> void:
	var args := OS.get_cmdline_user_args()
	for arg: String in args:
		if arg.begins_with("--seeds="):
			_seeds = maxi(1, int(arg.trim_prefix("--seeds=")))
		elif arg == "--all-trainers":
			_all_trainers = true
		elif arg.begins_with("--json="):
			_json_path = arg.trim_prefix("--json=")


# --- the run ------------------------------------------------------------------

func _run() -> void:
	var curve: Dictionary = CURVE.config()
	var regions: Array = CURVE.regions(curve)
	var party_species: Array = _difficulty.get("party", ["terrapup"]) as Array
	var pilot_seconds := 0.0
	var started := Time.get_ticks_msec()

	print("")
	print("== combat baseline: %d seeds per row, pilot = attack on cooldown, dodge nothing, no items ==" % _seeds)
	print("   party: %s" % ", ".join(PackedStringArray(party_species)))
	print("")
	print("%-34s %5s %5s | %6s %6s %6s %6s %6s %6s %6s" % [
		"row", "team", "foe", "win", "sec", "lead%", "party%", "faint", "prep", "maxhit"])
	print("%-34s %5s %5s | %6s %6s %6s %6s %6s %6s %6s" % [
		"", "lvl", "lvl", "rate", "mean", "lost", "lost", "rate", "rate", "frac"])
	print("-".repeat(103))

	for entry: Variant in regions:
		var region: Dictionary = entry as Dictionary
		var id := str(region.get("id", ""))
		var team: Dictionary = region.get("team", {}) as Dictionary
		var enter := int(team.get("enter", 1))
		var band: Array = region.get("wild_band", []) as Array
		var median := int((int(band[0]) + int(band[1])) / 2) if band.size() >= 2 else enter
		var wild_row := _wild_row(id, region, party_species, enter, median)
		_print_row(wild_row)
		var floor_spec := _floor_trainer_for(region, curve)
		if floor_spec.is_empty():
			print("%-34s   (no non-gate trainer stands in this region)" % ("%s trainer floor" % _short(id)))
		else:
			var row := _trainer_row("%s floor: %s" % [_short(id), str(floor_spec.get("id", ""))],
				id, "trainer_floor", floor_spec, party_species, enter, false)
			_print_row(row)
		if _all_trainers:
			for spec_v: Variant in _trainers_in(region, curve):
				var spec: Dictionary = spec_v as Dictionary
				if spec == floor_spec:
					continue
				_print_row(_trainer_row("  %s" % str(spec.get("id", "")), id, "trainer", spec,
					party_species, enter, false))

	# The village tournament: three separate challenges at the board's own entry
	# level, the party healed between rounds (the marshal's rule: "after healing
	# your creatures"). smoke_tournament_bracket.gd must keep winning this.
	var tournament_level := _tournament_level()
	for round_id: String in ["tournament_quarter_mira", "tournament_semi_tam", "tournament_final_oskar"]:
		var spec := _trainer_spec(round_id)
		if spec.is_empty():
			_fail("tournament round '%s' is not in trainers.json" % round_id)
			continue
		_print_row(_trainer_row("tournament: %s" % round_id.trim_prefix("tournament_"),
			"band1_lower_meadows", "tournament", spec, party_species, tournament_level, true))

	# The Hall: the elite and the Warden at the level the pacing probe says the
	# team reaches them (chapter_curve.json band 5 `tuning`: "the corrected probe
	# still fights the Warden at L19"). W-1: the Warden opens no softer than the
	# elite, so his row must not come out easier than Hald's.
	var hall_level := int(_difficulty.get("warden_level", 19))
	for hall_id: String in ["stronghold_elite", "warden_aldis"]:
		var spec := _trainer_spec(hall_id)
		if spec.is_empty():
			_fail("'%s' is not in trainers.json" % hall_id)
			continue
		_print_row(_trainer_row("hall: %s" % hall_id, "band5_stronghold_approach",
			"hall", spec, party_species, hall_level, false))

	pilot_seconds = (Time.get_ticks_msec() - started) / 1000.0
	print("-".repeat(103))
	print("   %d rows in %.1fs wall clock" % [_rows.size(), pilot_seconds])
	print("   faint = at least one party member knocked out; prep = a potion or a revive would be needed after (lead under %.0f%% or fainted)" % (
		float(_difficulty.get("potion_below_fraction", 0.3)) * 100.0))
	_assert_targets()


## One count-weighted row over every wild species the region's spawn table
## fields, each at the band's median level, lead vs wild, no switching.
func _wild_row(region_id: String, region: Dictionary, party_species: Array, enter: int, median: int) -> Dictionary:
	var weights := _species_weights_in(region)
	if weights.is_empty():
		_fail("region '%s' fields no wild spawns; nothing to measure" % region_id)
		return _blank_row("%s wild (median L%d)" % [_short(region_id), median], region_id, "wild", enter, median)
	var acc := _accumulator()
	var per_species: Dictionary = {}
	var total_weight := 0.0
	for species: String in weights:
		var w := float(weights[species])
		var sp := _accumulator()
		for i in _seeds:
			var party := _build_party(party_species, enter)
			var foe := _build_creature(species, median, {}, {})
			var foe_cfg := _enemy_config({}, false)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%s/%s/%d" % [region_id, species, i])
			var result := _simulate_battle(party, [foe], [foe_cfg], rng, false)
			_accumulate(sp, result, 1.0)
			_accumulate(acc, result, w)
		total_weight += w * _seeds
		per_species[species] = _finish(sp, _seeds)
	var row := _finish(acc, total_weight)
	row["row"] = "%s wild (median L%d)" % [_short(region_id), median]
	row["region"] = region_id
	row["kind"] = "wild"
	row["team_level"] = enter
	row["foe_level"] = median
	row["per_species"] = per_species
	_rows.append(row)
	return row


func _trainer_row(label: String, region_id: String, kind: String, spec: Dictionary,
		party_species: Array, level: int, heal_between_rounds: bool) -> Dictionary:
	var acc := _accumulator()
	var team: Array = TRAINERS.team_of(spec)
	var foe_levels: Array = []
	for member: Variant in team:
		foe_levels.append(int((member as Dictionary).get("level", 1)))
	for i in _seeds:
		var party := _build_party(party_species, level)
		var foes: Array[RefCounted] = []
		var cfgs: Array[Dictionary] = []
		for member: Variant in team:
			var creature: RefCounted = TRAINERS.creature_for(member as Dictionary)
			if creature == null:
				_fail("trainer '%s' fields a species that cannot be built" % str(spec.get("id", "")))
				continue
			foes.append(creature)
			cfgs.append(_enemy_config(creature.get("combat_override") as Dictionary, true))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%s/%s/%d" % [region_id, str(spec.get("id", "")), i])
		var result := _simulate_battle(party, foes, cfgs, rng, true)
		_accumulate(acc, result, 1.0)
	var row := _finish(acc, _seeds)
	row["row"] = label
	row["region"] = region_id
	row["kind"] = kind
	row["trainer"] = str(spec.get("id", ""))
	row["team_level"] = level
	row["foe_level"] = foe_levels.max() if not foe_levels.is_empty() else 0
	row["foe_levels"] = foe_levels
	row["heal_between_rounds"] = heal_between_rounds
	_rows.append(row)
	return row


# --- building the two sides ---------------------------------------------------

func _build_party(species: Array, level: int) -> Array[RefCounted]:
	var party: Array[RefCounted] = []
	for id: Variant in species:
		party.append(_build_creature(str(id), level, {}, {}))
	return party


func _build_creature(species: String, level: int, moves: Dictionary, combat: Dictionary) -> RefCounted:
	var creature: RefCounted = SPECIES.spawn(species)
	if creature == null:
		_fail("species '%s' is not in species.json" % species)
		return null
	creature.set_level(maxi(1, level), _prog)
	if moves.has("quick"):
		creature.move_quick = str(moves["quick"])
	if not combat.is_empty():
		creature.combat_override = combat.duplicate(true)
	return creature


## The block this body would actually fight with, through the real merge.
func _enemy_config(override: Dictionary, trainer_owned: bool) -> Dictionary:
	var body := WILD.new()
	body.combat_override = override if override != null else {}
	body.trainer_owned = trainer_owned
	var cfg: Dictionary = body._enemy_config_for_this_body()
	body.free()
	return cfg


func _radius_of(creature: RefCounted) -> float:
	var placeholder: Dictionary = SPECIES.placeholder(str(creature.species_id))
	return float(placeholder.get("radius", 0.4))


## The live body's own spacing arithmetic (and `damage_scale`), over the two
## radii in play -- the real static, not a copy of it.
func _spaced(cfg: Dictionary, mine: float, theirs: float) -> Dictionary:
	return WILD.spaced_config_for(cfg, mine, theirs)


## `combat_manager._move_profile` + `_with_reach_for_the_bodies`.
func _player_move(block: String, move_id: String, mine: float, theirs: float) -> Dictionary:
	var profile: Dictionary = (_combat.get(block, {}) as Dictionary).duplicate()
	if not move_id.is_empty():
		var move: Dictionary = _moves.call("move", move_id)
		for key: String in ["range", "cone_degrees", "windup", "recovery", "cooldown", "lunge"]:
			if move.has(key):
				profile[key] = float(move[key])
	var clearance: float = float((_combat.get("enemy", {}) as Dictionary).get("body_clearance", 1.35))
	profile["range"] = maxf(float(profile.get("range", 2.6)), (mine + theirs) * clearance + 0.5)
	profile["move_id"] = move_id
	return profile


# --- the fight ----------------------------------------------------------------

## A whole battle: the party (auto-switching on faint when `owned`, i.e. a
## trainer's roster) against `foes` in order. Returns the tally.
func _simulate_battle(party: Array[RefCounted], foes: Array, cfgs: Array, rng: RandomNumberGenerator, owned: bool) -> Dictionary:
	var result := {
		"won": false, "seconds": 0.0, "faints": 0, "max_hit_frac": 0.0,
		"lead_lost_frac": 0.0, "party_lost_frac": 0.0, "stalled": false,
	}
	var party_max := 0.0
	for c: RefCounted in party:
		party_max += float(c.max_hp)
	var lead: RefCounted = party[0]
	var active := 0
	var seconds := 0.0
	var flow: Dictionary = _combat.get("flow", {}) as Dictionary
	var faint_pause := float(flow.get("faint_pause", 1.6))
	var send_out := float(TRAINERS.flow().get("send_out_seconds", 1.6))

	var won_all := true
	for f in foes.size():
		var foe: RefCounted = foes[f]
		var cfg: Dictionary = cfgs[f]
		var outcome := _simulate_round(party, active, foe, cfg, rng, owned, result)
		seconds += float(outcome["seconds"])
		active = int(outcome["active"])
		if bool(outcome["stalled"]):
			result["stalled"] = true
		if not bool(outcome["won"]):
			won_all = false
			break
		seconds += faint_pause
		if f < foes.size() - 1:
			seconds += send_out

	result["won"] = won_all
	result["seconds"] = seconds
	var party_left := 0.0
	for c: RefCounted in party:
		party_left += float(c.hp)
	result["party_lost_frac"] = 1.0 - party_left / party_max if party_max > 0.0 else 0.0
	result["lead_lost_frac"] = 1.0 - lead.hp_fraction()
	return result


## One of the party against one opponent, until one side is down. When the
## opponent is a trainer's (`owned`), a faint on our side brings the next
## standing party member in, exactly as `combat_manager._handle_active_faint`.
func _simulate_round(party: Array[RefCounted], active: int, foe: RefCounted, cfg: Dictionary,
		rng: RandomNumberGenerator, owned: bool, tally: Dictionary) -> Dictionary:
	var out := {"won": false, "seconds": 0.0, "active": active, "stalled": false}
	var arena: Dictionary = _combat.get("arena", {}) as Dictionary
	var movement: Dictionary = _combat.get("creature_movement", {}) as Dictionary
	var flow: Dictionary = _combat.get("flow", {}) as Dictionary
	var pilot_speed := float(movement.get("speed", 5.6))
	var damping := maxf(0.1, float(movement.get("impulse_damping", 9.0)))

	var mine: RefCounted = party[active]
	var my_r := _radius_of(mine)
	var foe_r := _radius_of(foe)
	var spaced := _spaced(cfg, foe_r, my_r)

	# Positions on the plane. The foe at the origin, ours `separation` away.
	var foe_pos := Vector2.ZERO
	var my_pos := Vector2(0.0, float(arena.get("separation", 5.0)))
	var contact := my_r + foe_r

	# Opponent clocks, as `wild_creature.set_engaged(true)` starts them.
	var intent: int = AI.Intent.CLOSE
	var beat := 0.0
	var cooldown := float(cfg.get("first_attack_delay", 1.5))
	var side := 1.0 if rng.randf() < 0.5 else -1.0

	# Our clocks, as `combat_manager.begin` starts them.
	var action: int = Action.READY
	var action_timer := 0.0
	var pending: Dictionary = {}
	var quick_cd := 0.0
	var charged_cd := 0.0
	var guard := float(flow.get("input_guard", 0.25))

	var seconds := 0.0
	while seconds < FIGHT_SECONDS_LIMIT:
		seconds += DT
		# ---- the opponent (wild_creature._tick_combat) ----
		cooldown = maxf(0.0, cooldown - DT)
		beat = maxf(0.0, beat - DT)
		var to := my_pos - foe_pos
		var distance := to.length()
		var next: int = AI.decide(intent, distance, beat, cooldown, spaced)
		if next != intent:
			var previous := intent
			intent = next
			beat = AI.duration_for(intent, cfg)
			if previous == AI.Intent.TELEGRAPH:
				# Strike. Connect test on the live gap; the lunge is an
				# impulse whose position lands next frame.
				if distance <= float(spaced.get("range", 2.6)):
					var type_mult: float = TYPE_CHART.multiplier_dual(
						_moves.type_of(str(foe.move_quick)), str(mine.creature_type), str(mine.get("secondary_type")))
					var damage: float = MATH.rolled_damage(
						float(spaced.get("power", 8.0)), foe.effective_attack(_prog),
						mine.effective_defence(_prog, false, {}), rng.randf(),
						_moves.power(str(foe.move_quick)), type_mult)
					var frac := damage / maxf(1.0, float(mine.max_hp))
					if frac > float(tally["max_hit_frac"]):
						tally["max_hit_frac"] = frac
					var killed: bool = mine.take_damage(damage)
					if killed:
						tally["faints"] = int(tally["faints"]) + 1
						if not owned:
							out["seconds"] = seconds
							return out
						var next_index := _next_standing(party, active)
						if next_index < 0:
							out["seconds"] = seconds
							out["active"] = active
							return out
						active = next_index
						mine = party[active]
						my_r = _radius_of(mine)
						spaced = _spaced(cfg, foe_r, my_r)
						contact = my_r + foe_r
						action = Action.READY
						pending = {}
						quick_cd = 0.0
						charged_cd = 0.0
						guard = float(flow.get("input_guard", 0.25))
				var lunge_dir := to.normalized() if distance > 0.001 else Vector2.DOWN
				foe_pos += lunge_dir * float(cfg.get("lunge", 3.4)) / damping
				my_pos += lunge_dir * float(cfg.get("lunge", 3.4)) * 0.4 / damping
				cooldown = float(cfg.get("attack_cooldown", 1.1))
			elif intent == AI.Intent.REPOSITION:
				side = 1.0 if rng.randf() < 0.5 else -1.0
		var dir3: Vector3 = AI.movement_for(intent, Vector3(to.x, 0.0, to.y), side)
		if dir3 != Vector3.ZERO:
			foe_pos += Vector2(dir3.x, dir3.z) * AI.speed_for(intent, cfg) * DT

		# ---- ours (combat_manager._tick_active) ----
		quick_cd = maxf(0.0, quick_cd - DT)
		charged_cd = maxf(0.0, charged_cd - DT)
		guard = maxf(0.0, guard - DT)
		to = foe_pos - my_pos
		distance = to.length()
		if action != Action.READY:
			action_timer -= DT
			if action_timer <= 0.0:
				if action == Action.WINDUP:
					if distance <= float(pending.get("range", 2.6)):
						var is_quick: bool = bool(pending.get("is_quick", false))
						var move_id: String = str(pending.get("move_id", ""))
						var type_mult: float = TYPE_CHART.multiplier_dual(
							_moves.type_of(move_id), str(foe.creature_type), str(foe.get("secondary_type")))
						var damage: float = MATH.rolled_damage(
							float(pending.get("power", 9.0)), mine.effective_attack(_prog),
							foe.effective_defence(_prog), rng.randf(), _moves.power(move_id), type_mult)
						var killed: bool = foe.take_damage(damage)
						if is_quick:
							mine.gain_energy_from_quick()
						if killed:
							out["won"] = true
							out["seconds"] = seconds
							out["active"] = active
							return out
					action = Action.RECOVERY
					action_timer = float(pending.get("recovery", 0.2))
				else:
					action = Action.READY
					pending = {}
		elif guard <= 0.0:
			# The pilot policy.
			var reach := _player_move("player_quick", str(mine.move_quick), my_r, foe_r)
			if distance <= float(reach.get("range", 2.6)):
				if mine.can_use_charged() and charged_cd <= 0.0:
					mine.spend_charged()
					pending = _player_move("player_charged", str(mine.move_charged), my_r, foe_r)
					pending["is_quick"] = false
					charged_cd = float(pending.get("cooldown", 1.2))
					action = Action.WINDUP
					action_timer = float(pending.get("windup", 0.55))
					my_pos += to.normalized() * float(pending.get("lunge", 6.0)) / damping
				elif quick_cd <= 0.0:
					pending = reach
					pending["is_quick"] = true
					quick_cd = float(pending.get("cooldown", 0.4))
					action = Action.WINDUP
					action_timer = float(pending.get("windup", 0.18))
					my_pos += to.normalized() * float(pending.get("lunge", 3.6)) / damping
			else:
				my_pos += to.normalized() * pilot_speed * DT

		# ---- the two capsules cannot overlap ----
		var gap := foe_pos - my_pos
		if gap.length() < contact:
			var push := (gap.normalized() if gap.length() > 0.001 else Vector2.DOWN) * contact
			foe_pos = my_pos + push

	out["stalled"] = true
	out["seconds"] = seconds
	out["active"] = active
	return out


func _next_standing(party: Array[RefCounted], from: int) -> int:
	for step in range(1, party.size()):
		var index := (from + step) % party.size()
		var member: RefCounted = party[index]
		if not member.fainted and float(member.hp) > 0.0:
			return index
	return -1


# --- tallies ------------------------------------------------------------------

func _accumulator() -> Dictionary:
	return {"w": 0.0, "wins": 0.0, "seconds": 0.0, "lead": 0.0, "party": 0.0,
		"faint_runs": 0.0, "prep_runs": 0.0, "max_hit": 0.0, "stalls": 0.0}


func _accumulate(acc: Dictionary, result: Dictionary, weight: float) -> void:
	acc["w"] = float(acc["w"]) + weight
	if bool(result["won"]):
		acc["wins"] = float(acc["wins"]) + weight
	acc["seconds"] = float(acc["seconds"]) + float(result["seconds"]) * weight
	acc["lead"] = float(acc["lead"]) + float(result["lead_lost_frac"]) * weight
	acc["party"] = float(acc["party"]) + float(result["party_lost_frac"]) * weight
	if int(result["faints"]) > 0:
		acc["faint_runs"] = float(acc["faint_runs"]) + weight
	var potion_below := float(_difficulty.get("potion_below_fraction", 0.3))
	if int(result["faints"]) > 0 or float(result["lead_lost_frac"]) > 1.0 - potion_below:
		acc["prep_runs"] = float(acc["prep_runs"]) + weight
	acc["max_hit"] = maxf(float(acc["max_hit"]), float(result["max_hit_frac"]))
	if bool(result["stalled"]):
		acc["stalls"] = float(acc["stalls"]) + weight


func _finish(acc: Dictionary, _n: float) -> Dictionary:
	var w := maxf(0.000001, float(acc["w"]))
	return {
		"win_rate": float(acc["wins"]) / w,
		"seconds": float(acc["seconds"]) / w,
		"lead_lost": float(acc["lead"]) / w,
		"party_lost": float(acc["party"]) / w,
		"faint_rate": float(acc["faint_runs"]) / w,
		"prep_rate": float(acc["prep_runs"]) / w,
		"max_hit_frac": float(acc["max_hit"]),
		"stall_rate": float(acc["stalls"]) / w,
	}


func _blank_row(label: String, region_id: String, kind: String, team_level: int, foe_level: int) -> Dictionary:
	var row := _finish(_accumulator(), 1.0)
	row["row"] = label
	row["region"] = region_id
	row["kind"] = kind
	row["team_level"] = team_level
	row["foe_level"] = foe_level
	_rows.append(row)
	return row


func _print_row(row: Dictionary) -> void:
	var stall := "  STALL %.0f%%" % (float(row.get("stall_rate", 0.0)) * 100.0) \
		if float(row.get("stall_rate", 0.0)) > 0.0 else ""
	print("%-34s %5d %5d | %5.0f%% %6.1f %5.0f%% %5.0f%% %5.0f%% %5.0f%% %6.2f%s" % [
		str(row["row"]).left(34), int(row["team_level"]), int(row["foe_level"]),
		float(row["win_rate"]) * 100.0, float(row["seconds"]),
		float(row["lead_lost"]) * 100.0, float(row["party_lost"]) * 100.0,
		float(row["faint_rate"]) * 100.0, float(row["prep_rate"]) * 100.0,
		float(row["max_hit_frac"]), stall])


# --- content lookups ----------------------------------------------------------

func _short(region_id: String) -> String:
	return region_id.get_slice("_", 0)


func _spawns() -> Array:
	return BAND_CONTENT.load_config(SPAWNS_PATH, "spawns").get("spawns", []) as Array


func _trainers() -> Array:
	return BAND_CONTENT.load_config(TRAINERS_PATH, "trainers").get("trainers", []) as Array


func _trainer_spec(id: String) -> Dictionary:
	for entry: Variant in _trainers():
		if str((entry as Dictionary).get("id", "")) == id:
			return entry as Dictionary
	return {}


## Distinct species the region's clusters field, weighted by authored count.
func _species_weights_in(region: Dictionary) -> Dictionary:
	var curve: Dictionary = CURVE.config()
	var weights: Dictionary = {}
	for entry: Variant in _spawns():
		var spawn: Dictionary = entry as Dictionary
		var centre: Array = spawn.get("centre", []) as Array
		if centre.size() < 3:
			continue
		if str(CURVE.region_at(float(centre[2]), curve).get("id", "")) != str(region.get("id", "")):
			continue
		var species := str(spawn.get("species", ""))
		if not SPECIES.has(species):
			continue
		weights[species] = float(weights.get(species, 0.0)) + maxf(1.0, float(spawn.get("count", 1)))
	return weights


func _trainers_in(region: Dictionary, curve: Dictionary) -> Array:
	var out: Array = []
	for entry: Variant in _trainers():
		var spec: Dictionary = entry as Dictionary
		var position: Array = spec.get("position", []) as Array
		if position.size() < 2:
			continue
		if str(CURVE.region_at(float(position[1]), curve).get("id", "")) != str(region.get("id", "")):
			continue
		out.append(spec)
	return out


## The band's weakest authored trainer: lowest strongest-member level, ties
## broken by team level sum. Gate fights (the tournament rounds, the bridge)
## and the practice trainer are excluded -- the first are measured on their
## own rows, the second is the tutorial and is not the band's floor of danger.
func _floor_trainer_for(region: Dictionary, curve: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_key := [INF, INF]
	for spec_v: Variant in _trainers_in(region, curve):
		var spec: Dictionary = spec_v as Dictionary
		if bool(spec.get("gate_fight", false)) or str(spec.get("id", "")) == "practice_trainer":
			continue
		var top := 0
		var total := 0
		for member: Variant in TRAINERS.team_of(spec):
			var level := int((member as Dictionary).get("level", 1))
			top = maxi(top, level)
			total += level
		if top < best_key[0] or (top == best_key[0] and total < best_key[1]):
			best_key = [top, total]
			best = spec
	return best


func _tournament_level() -> int:
	var file := FileAccess.open("res://data/config/tournament.json", FileAccess.READ)
	if file == null:
		return 5
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return 5
	return int(((parsed as Dictionary).get("entry", {}) as Dictionary).get("min_level", 5))


# --- the bar ------------------------------------------------------------------

func _row_of(kind: String, region: String = "", trainer: String = "") -> Dictionary:
	for row: Dictionary in _rows:
		if str(row.get("kind", "")) != kind:
			continue
		if region != "" and str(row.get("region", "")) != region:
			continue
		if trainer != "" and str(row.get("trainer", "")) != trainer:
			continue
		return row
	return {}


func _assert_targets() -> void:
	if _difficulty.is_empty():
		return
	var wild_band: Array = _difficulty.get("wild_lead_hp_cost", []) as Array
	var floor_cost: Array = _difficulty.get("trainer_floor_lead_hp_cost", []) as Array
	var skip_wild: Array = _difficulty.get("wild_cost_exempt_regions", []) as Array
	var one_shot := float(_difficulty.get("max_single_hit_fraction", 1.0))

	for row: Dictionary in _rows:
		# G-3's fails-if, for every opponent measured: a full-health creature of
		# the region's entry level is never taken in one blow.
		if float(row["max_hit_frac"]) >= one_shot:
			_fail("%s: a single hit took %.0f%% of a full-health level-%d creature (limit %.0f%%)" % [
				str(row["row"]), float(row["max_hit_frac"]) * 100.0, int(row["team_level"]), one_shot * 100.0])
		if float(row.get("stall_rate", 0.0)) > 0.0:
			_fail("%s: %.0f%% of runs never resolved inside %.0fs of simulated fight" % [
				str(row["row"]), float(row["stall_rate"]) * 100.0, FIGHT_SECONDS_LIMIT])

	for row: Dictionary in _rows:
		var kind := str(row.get("kind", ""))
		if kind == "wild" and wild_band.size() >= 2 and not skip_wild.has(row.get("region", "")):
			var cost := float(row["lead_lost"])
			if cost < float(wild_band[0]) or cost > float(wild_band[1]):
				_fail("%s: an ordinary wild costs the lead %.0f%% of its health; the target is %.0f-%.0f%% (chapter_curve.json difficulty.wild_lead_hp_cost)" % [
					str(row["row"]), cost * 100.0, float(wild_band[0]) * 100.0, float(wild_band[1]) * 100.0])
			if float(row["win_rate"]) < 1.0:
				_fail("%s: the pilot LOST %.0f%% of ordinary wild fights at band entry; a wild is danger, not a wall" % [
					str(row["row"]), (1.0 - float(row["win_rate"])) * 100.0])
		elif kind == "trainer_floor":
			if floor_cost.size() >= 2:
				var cost := float(row["lead_lost"])
				if cost < float(floor_cost[0]) or cost > float(floor_cost[1]):
					_fail("%s: the band's floor trainer costs the lead %.0f%% of its health; the target is %.0f-%.0f%% (difficulty.trainer_floor_lead_hp_cost)" % [
						str(row["row"]), cost * 100.0, float(floor_cost[0]) * 100.0, float(floor_cost[1]) * 100.0])
			if float(row["win_rate"]) < float(_difficulty.get("trainer_floor_min_win_rate", 0.75)):
				_fail("%s: the band's WEAKEST trainer wipes the whole five %.0f%% of the time; a floor is danger, not a wall" % [
					str(row["row"]), (1.0 - float(row["win_rate"])) * 100.0])

	var tournament_floor := float(_difficulty.get("tournament_min_win_rate", 0.75))
	for row: Dictionary in _rows:
		if str(row.get("kind", "")) == "tournament" and float(row["win_rate"]) < tournament_floor:
			_fail("%s: won only %.0f%% at the board's own entry level; smoke_tournament_bracket needs %.0f%%" % [
				str(row["row"]), float(row["win_rate"]) * 100.0, tournament_floor * 100.0])

	var warden := _row_of("hall", "", "warden_aldis")
	var elite := _row_of("hall", "", "stronghold_elite")
	var warden_floor := float(_difficulty.get("warden_min_win_rate", 0.5))
	if not warden.is_empty():
		if float(warden["win_rate"]) < warden_floor:
			_fail("the Warden is won only %.0f%% of the time by a level-%d party; the floor is %.0f%%" % [
				float(warden["win_rate"]) * 100.0, int(warden["team_level"]), warden_floor * 100.0])
		if not elite.is_empty() and float(warden["party_lost"]) < float(elite["party_lost"]):
			_fail("W-1: the Warden costs the party %.0f%% but the elite costs %.0f%%; the Warden opens no softer than the elite" % [
				float(warden["party_lost"]) * 100.0, float(elite["party_lost"]) * 100.0])


# --- reporting ----------------------------------------------------------------

func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report() -> void:
	if _json_path != "":
		var file := FileAccess.open(_json_path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"seeds": _seeds, "rows": _rows}, "  "))
			file.close()
			print("wrote %s" % _json_path)
	print("")
	if _failures.is_empty():
		print("smoke_combat_baseline: OK (%d rows, %d seeds each)" % [_rows.size(), _seeds])
		quit(0)
		return
	print("smoke_combat_baseline: FAILED (%d):" % _failures.size())
	for failure: String in _failures:
		print("  - %s" % failure)
	quit(1)
