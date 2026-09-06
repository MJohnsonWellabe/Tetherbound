extends SceneTree

## §10 / D-MP12 / D100: does the participant-count multiplier reach the CREATURE?
##
##   godot --headless --path . --script tests/smoke_encounter_scaling.gd
##
## `tests/test_encounter_rewards.gd` already owns §10's table
## (`encounter_host.gd::scaling_for()`) and §10's record
## (`host.scaling(id)`). Both were green while the multiplier reached nothing at
## all: `encounter_director.gd::_scale_opponent_for_the_session()` ran at
## send-out, BEFORE `_start_fight()` opened or resumed the record it reads its
## multiplier off, so the first creature of a trainer's roster found no record
## and every later one found the participant list §9 empties at each round
## boundary -- an identity row. Measured on the Warden at two participants:
## burrowback and galecrest both fought at their authored attack, defence and
## cooldown while the record beside them said `stat_multiplier` 1.1. Recorded as
## finding F1 of `ralph/reports/MP-ROWS-8-21-0906/REPORT.md`.
##
## **Nothing had ever asserted that the multiplier reaches a live creature.**
## That gap is this file.
##
## ## What it asserts, in the order a fight meets it
##
##   1. **One participant is the identity.** The fight opens with only the host
##      in the record, and the creature on the field carries its AUTHORED attack,
##      defence and attack cooldown -- byte for byte the fight a solo player has.
##   2. **A mid-fight join reaches the creature already standing there.** §10:
##      "re-derived when `participants` changes, including a mid-fight join or
##      leave". The creature's live attack and defence become authored x
##      `stat_multiplier`, and the BODY's live attack cooldown -- the number the
##      swing timer actually reads, not the one on the instance -- becomes
##      authored x `attack_cooldown_multiplier`.
##   3. **NEVER HP x players**, asserted at that same moment and again on every
##      later creature. §10's one outright prohibition.
##   4. **It does not compound.** The host re-derives on every landed strike as
##      well as on every join and leave, so the same creature is scaled again and
##      again; each time it must land on authored x row, never on the previous
##      answer x row. This is asserted directly (the change is applied eleven
##      more times and the numbers do not move), across a row that MOVES (a third
##      peer joins the same creature and it lands on authored x the three-player
##      row, not on the two-player answer x it), and across a three-creature
##      roster (the second and third creature are scaled exactly once, not
##      squared).
##   5. **A leave puts it back.** With the joiner gone the row is the identity
##      again and the live creature is the authored one -- including its
##      `combat_override` dictionary key for key, so a creature that authored no
##      `attack_cooldown` cannot acquire one just for having been in a fight that
##      emptied out.
##
## Assertion count is printed on every run, pass or fail. A break that makes this
## file run FEWER assertions is a function aborting, not a test failing.
##
## ## The session double, and why there is one
##
## `_scale_opponent_for_the_session()` asks the session exactly four questions --
## `is_active`, `is_host`, `is_multi_peer` and `local_peer_id` -- plus `peers()`
## for the re-seat between rounds. Everything else in the path is production: the
## real `encounter_host.gd` mints the record and stamps the row, the real
## `encounter_director.gd` opens, resumes, joins and leaves it, the real
## `wild_creature.gd` body reads the cooldown, and the real `trainer_npc.gd`
## builds the roster.
##
## Standing up a genuine two-process session to ask those four questions is
## `tests/smoke_net_shared_boss.gd`'s job, and that file asserts the same claim
## over a real ENet link against the real `session.gd` -- so the double here
## cannot quietly answer for production. What it buys is the part the net smoke
## cannot reach inside a CI budget: three rounds of one roster, a join, eleven
## re-derivations and a leave, all deterministic and all measured.
##
## A double that lied would have to lie in the same direction as a real session
## does, which is why it answers a fixed host id of 1 and a fixed second peer id
## that is a large random 32-bit number -- the ENet spike's finding 2, and the
## same shape `test_encounter_rewards.gd` uses.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

const SETTLE_FRAMES := 300
## `stronghold_checkpoint`: three creatures, and every one of them authors its
## own `attack_cooldown` in `data/config/bands/band5_stronghold_approach/
## trainers.json`. Named here rather than discovered, on `smoke_boss.gd`'s
## precedent: a designer who retunes this roster turns the count assertion below
## into a legible one-line failure instead of a smoke that silently asserts
## whatever the table happens to say. The Warden's own opener authors NO
## cooldown (finding F3), which is why he is not the roster used here -- a
## cooldown measurement on him compares 0.0 to 0.0 and says nothing.
const TRAINER_ID := "stronghold_checkpoint"
const EXPECTED_TEAM := 3

## Only the listen server is 1; a joiner is a large random 32-bit number (the
## ENet spike's finding 2). Nothing here may assume an ordering or a small value.
const PEER_HOST := 1
const PEER_GUEST := 1_369_099_083
const PEER_THIRD := 884_120_557

const CONFIG_PATH := "res://data/config/multiplayer.json"

## How many extra times the host's own re-derivation is driven over one creature,
## to prove it lands on the same numbers rather than compounding. Eleven is
## arbitrary and deliberately more than two: a squaring bug is visible at the
## second call and an eleventh call at 1.1 would read 2.85x.
const RE_DERIVATIONS := 11

## A hard ceiling on driving one creature down, so a director that never resolves
## a round fails instead of hanging CI.
const ROUND_FRAME_LIMIT := 4000
## The opponent's HP is pulled to this before each swing so a starter can finish a
## level-16 roster inside a CI budget -- exactly the allowance `smoke_boss.gd` and
## `smoke_trainer_battle.gd` make, and for the same reason: this file is about
## whether a multiplier reaches a creature, not about balance. `hp` is the only
## thing it touches; `max_hp`, `attack`, `defence` and `combat_override` -- every
## number asserted below -- are never written by it.
const ENEMY_HP_CEILING := 6.0

var _failures: Array[String] = []
var _checks: int = 0
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _session: Node = null
var _spec: Dictionary = {}
## species_id -> the authored numbers, rebuilt through the production
## `trainer_npc.gd::creature_for()`. Deterministic: `creature_instance.gd::
## from_species` rolls no level, no IV and no trait, so this is the same authored
## source the fight itself read, and a species-curve retune moves both sides
## together instead of turning this into a false red.
var _authored: Dictionary = {}
var _configured_stat: float = 1.0
var _configured_cooldown: float = 1.0
## The THREE-participant row. A second row is what makes the compounding claim
## provable at all: with only one non-identity row in play, "authored x row" and
## "the previous answer x row" are the same number on a creature that is only
## ever scaled once.
var _configured_stat_3: float = 1.0
var _configured_cooldown_3: float = 1.0


## The four questions `_scale_opponent_for_the_session()` asks a session, and the
## fifth (`peers()`) that `_resume_trainer_encounter()` asks to decide who may be
## put back into the next round. Nothing else. See this file's header.
class SessionDouble extends Node:
	## Everybody the session holds. `_resume_trainer_encounter()` reads this to
	## decide who may be put back into the next round, and refuses to re-seat a
	## peer the session no longer has -- so a peer that leaves the fight below is
	## taken out of here too, exactly as a real disconnect would take it out of
	## `peer_registry.gd`.
	var ids: Array[int] = [1, 1_369_099_083]

	func is_active() -> bool:
		return true

	func is_host() -> bool:
		return true

	func is_multi_peer() -> bool:
		return ids.size() > 1

	func local_peer_id() -> int:
		return 1

	func peers() -> Array:
		var rows: Array = []
		for id: int in ids:
			rows.append({"peer_id": id})
		return rows


func _init() -> void:
	_run()


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		return
	_failures.append(message)


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	_spec = TRAINERS.trainer(TRAINER_ID)
	if _spec.is_empty():
		_fail("trainers.json has no trainer '%s'; nothing here can run" % TRAINER_ID)
		_report()
		return

	if not _read_the_configured_row():
		_report()
		return
	_build_the_authored_table()

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	if not await _collect_nodes():
		_report()
		return

	_seat_the_session_double()
	if not await _open_the_battle():
		_report()
		return

	await _round_one_is_the_identity_until_somebody_joins()
	await _the_later_creatures_are_scaled_exactly_once()
	_report()


## `data/config/multiplayer.json`'s two-participant row, read straight out of the
## data file rather than through the code that applies it. A code/config
## divergence fails here rather than agreeing with itself.
func _read_the_configured_row() -> bool:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		_fail("cannot read %s" % CONFIG_PATH)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("%s is not a JSON object" % CONFIG_PATH)
		return false
	var rows: Variant = ((parsed as Dictionary).get("encounter", {}) as Dictionary) \
		.get("scaling", {})
	var by_count: Variant = (rows as Dictionary).get("by_participants", {}) if rows is Dictionary else {}
	var row: Variant = (by_count as Dictionary).get("2", {}) if by_count is Dictionary else {}
	if not (row is Dictionary) or (row as Dictionary).is_empty():
		_fail("%s configures no scaling row for 2 participants" % CONFIG_PATH)
		return false
	_configured_stat = float((row as Dictionary).get("stat_multiplier", 1.0))
	_configured_cooldown = float((row as Dictionary).get("attack_cooldown_multiplier", 1.0))
	var row3: Variant = (by_count as Dictionary).get("3", {}) if by_count is Dictionary else {}
	if not (row3 is Dictionary) or (row3 as Dictionary).is_empty():
		_fail("%s configures no scaling row for 3 participants" % CONFIG_PATH)
		return false
	_configured_stat_3 = float((row3 as Dictionary).get("stat_multiplier", 1.0))
	_configured_cooldown_3 = float((row3 as Dictionary).get("attack_cooldown_multiplier", 1.0))
	# THE TWO CHECKS THAT KEEP EVERY COMPARISON BELOW HONEST. At 1.0 every
	# assertion in this file is `authored == authored` and would pass a build
	# that scaled nothing at all.
	_check(_configured_stat > 1.0,
		"the two-player stat_multiplier is above 1.0 (%.4f) -- at 1.0 every comparison in this file"
			% _configured_stat
		+ " is authored-against-itself and proves nothing")
	_check(_configured_cooldown < 1.0,
		"and its attack_cooldown_multiplier is below 1.0 (%.4f) -- one body facing two people swings"
			% _configured_cooldown
		+ " more often, and at 1.0 the cooldown assertions prove nothing")
	# THE CHECK THAT MAKES THE COMPOUNDING CLAIM MEAN ANYTHING. With the three-
	# participant row equal to the two-participant one, "authored x 1.15" and
	# "authored x 1.1 x 1.15" would be the only two candidates and the first
	# assertion below could not tell a re-derivation from a compounding one.
	_check(_configured_stat_3 > _configured_stat,
		"the three-player stat_multiplier (%.4f) is above the two-player one (%.4f), so a re-derivation"
			% [_configured_stat_3, _configured_stat]
		+ " and a compounding are different numbers")
	return _configured_stat > 1.0 and _configured_cooldown < 1.0 \
		and _configured_stat_3 > _configured_stat


func _build_the_authored_table() -> void:
	for entry: Variant in TRAINERS.team_of(_spec):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var built: RefCounted = TRAINERS.creature_for(entry as Dictionary)
		if built == null:
			continue
		var override: Dictionary = built.get("combat_override") as Dictionary
		_authored[str(built.get("species_id"))] = {
			"level": int(built.get("level")),
			"max_hp": float(built.get("max_hp")),
			"attack": float(built.get("attack")),
			"defence": float(built.get("defence")),
			"combat_override": override.duplicate(true),
			"attack_cooldown": _resolved_cooldown(override),
		}
	_check(_authored.size() == EXPECTED_TEAM,
		"'%s' fields %d creatures with distinct species (got %d: %s)"
			% [TRAINER_ID, EXPECTED_TEAM, _authored.size(), str(_authored.keys())])


## The cooldown a body would actually swing at: the creature's own G-2 override
## when it names one, and `combat.json`'s `enemy_trainer` baseline when it does
## not. The same resolution `wild_creature.gd::_enemy_config_for_this_body()`
## performs and the same one `encounter_director.gd::_take_scaling_base()` has to
## take its base from, written out here independently so the two must agree.
func _resolved_cooldown(override: Dictionary) -> float:
	if override.has("attack_cooldown"):
		return float(override["attack_cooldown"])
	var trainer_baseline: Dictionary = MATH.config().get("enemy_trainer", {}) as Dictionary
	if trainer_baseline.has("attack_cooldown"):
		return float(trainer_baseline["attack_cooldown"])
	var enemy: Dictionary = MATH.config().get("enemy", {}) as Dictionary
	return float(enemy.get("attack_cooldown", 1.1))


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _rig == null or _manager == null or _director == null:
		_fail("the scene is missing the player, camera rig, combat manager or director")
		return false
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", "terrapup")
	if _director.call("ally_instance") == null:
		_fail("the player has no creature to fight with")
		return false
	return true


## The double goes on the DIRECTOR rather than replacing `/root/Game/Session`:
## the director caches its session in `_wire_creature_replication()` during
## `_ready()`, which has already run by the time this scene is standing, and
## swapping an autoload's child out from under everything else in the world would
## be a much larger lie than answering four questions.
##
## The multiplayer peer is cleared at the same time, so `_can_encounter_rpc()`
## answers FALSE and the director sends nothing down a wire that does not exist.
## Godot installs an `OfflineMultiplayerPeer` by default -- under which
## `has_multiplayer_peer()` is true, which is the same default that
## `trainer_spawn.gd::_is_host()`'s comment says cost this project a day -- so
## without this the host would try to `rpc_id()` the second peer id and log an
## engine error per re-derivation. Nothing below asserts on anything that
## travels: every branch measured here is the host's own local one.
func _seat_the_session_double() -> void:
	var api := get_multiplayer()
	if api != null:
		api.multiplayer_peer = null
	_check(not (api != null and api.has_multiplayer_peer()),
		"this process holds no multiplayer peer, so the host's own local branch is what runs")
	_session = SessionDouble.new()
	_session.name = "SessionDouble"
	_world.add_child(_session)
	_director.set("_session", _session)
	_check(bool(_director.call("_is_host")) and bool(_director.call("_is_multi_peer")),
		"the director reads this process as the host of a multi-peer session (host %s, multi %s)"
			% [str(_director.call("_is_host")), str(_director.call("_is_multi_peer"))])
	_check(int(_director.call("_local_peer_id")) == PEER_HOST,
		"and as peer %d (got %d)" % [PEER_HOST, int(_director.call("_local_peer_id"))])


func _open_the_battle() -> bool:
	if not bool(_director.call("can_challenge", _spec)):
		_fail("'%s' will not take the challenge (nothing out: %s, already beaten: %s)"
			% [TRAINER_ID, str(_director.call("no_usable_ally")),
			   str(TRAINERS.already_beaten(_spec, _progression()))])
		return false
	# The production call, and `trainer` is legally null -- `begin_trainer_battle`
	# says so. The fight forms in front of the player where they are standing,
	# which is the open meadow: no building claims it, so nothing about the
	# geometry can colour a measurement about arithmetic.
	if not bool(_director.call("begin_trainer_battle", _spec, null)):
		_fail("begin_trainer_battle('%s') refused" % TRAINER_ID)
		return false
	for i in 45:
		await physics_frame
	if not bool(_manager.call("is_fighting")):
		_fail("the challenge did not start a fight; nothing below this point was tested")
		return false
	return true


# --- round one: identity, then a join ------------------------------------------------

func _round_one_is_the_identity_until_somebody_joins() -> void:
	var live := _live()
	if live.is_empty():
		_fail("no opponent creature on the field after the challenge opened")
		return
	var species := str(live.get("species_id", ""))
	var authored: Dictionary = _authored.get(species, {}) as Dictionary
	_check(not authored.is_empty(),
		"the creature on the field ('%s') is one of the trainer's authored %d (%s)"
			% [species, EXPECTED_TEAM, str(_authored.keys())])
	if authored.is_empty():
		return

	var id := str(_record().get("encounter_id", ""))
	_check(not id.is_empty(), "the host minted an encounter record for the fight")
	_check(_participants(id) == 1,
		"and only this peer is in it so far (%d participant(s))" % _participants(id))
	# 1. ONE PARTICIPANT IS THE IDENTITY. A session that nobody else has joined
	# yet must fight exactly the fight a solo player fights.
	_assert_scaled_by(live, authored, 1.0, 1.0, "with one participant")

	# 2. A MID-FIGHT JOIN. Through the host's own door -- `engage` with an
	# `encounter_id` is §6's join, and `_host_commit_encounter()` is where every
	# intent in the protocol lands, the host's own included.
	var verdict: Dictionary = _director.call("_host_commit_encounter",
		{"kind": "engage", "encounter_id": id}, PEER_GUEST)
	_check(bool(verdict.get("ok", false)),
		"a second peer joined the fight already in progress (%s)" % str(verdict.get("reason", "")))
	_check(_participants(id) == 2,
		"and the record now holds 2 participants (got %d)" % _participants(id))
	var row: Dictionary = _stamped(id)
	_check(absf(float(row.get("stat_multiplier", -1.0)) - _configured_stat) < 0.0001,
		"the join re-derived the record's own row to the two-player one (%.4f, configured %.4f)"
			% [float(row.get("stat_multiplier", -1.0)), _configured_stat])

	live = _live()
	_assert_scaled_by(live, authored, _configured_stat, _configured_cooldown,
		"on the creature already standing on the field when the second peer arrived")

	# 4a. IT DOES NOT COMPOUND. The host re-derives on every landed strike, not
	# only on a join, so the same creature goes through this path over and over.
	# Driven directly here because a strike is not needed to prove arithmetic --
	# `_host_after_encounter_change()` is the function every one of those paths
	# ends in.
	for i in RE_DERIVATIONS:
		_director.call("_host_after_encounter_change", id, 0)
	live = _live()
	_assert_scaled_by(live, authored, _configured_stat, _configured_cooldown,
		"after the host re-derived the row %d more times" % RE_DERIVATIONS)

	# 4b. A THIRD PEER, on the same creature. This is where compounding actually
	# bites: the row MOVES, so the scaler writes the same creature a second time
	# with a different multiplier, and the only way to land on authored x 1.15 is
	# to have kept the authored number. Scaling the live value instead reads
	# authored x 1.1 x 1.15, which these tolerances separate by four decimal
	# places.
	_session.set("ids", [PEER_HOST, PEER_GUEST, PEER_THIRD] as Array[int])
	verdict = _director.call("_host_commit_encounter",
		{"kind": "engage", "encounter_id": id}, PEER_THIRD)
	_check(bool(verdict.get("ok", false)),
		"a third peer joined the same fight (%s)" % str(verdict.get("reason", "")))
	_check(_participants(id) == 3,
		"and the record holds 3 participants (got %d)" % _participants(id))
	live = _live()
	_assert_scaled_by(live, authored, _configured_stat_3, _configured_cooldown_3,
		"on the same creature once a third peer had joined")

	# ...and back down again. A leave is re-derived exactly as a join is, so the
	# creature must return to the TWO-player numbers, not stay at the three's and
	# not divide its way back to something a little off.
	_session.set("ids", [PEER_HOST, PEER_GUEST] as Array[int])
	verdict = _director.call("_host_commit_encounter",
		{"kind": "disengage", "encounter_id": id}, PEER_THIRD)
	_check(bool(verdict.get("ok", false)),
		"the third peer left again (%s)" % str(verdict.get("reason", "")))
	_check(_participants(id) == 2,
		"and the record is back to 2 participants (got %d)" % _participants(id))
	live = _live()
	_assert_scaled_by(live, authored, _configured_stat, _configured_cooldown,
		"on the same creature once the third peer had left again")


# --- rounds two and three, plus the leave ---------------------------------------------

func _the_later_creatures_are_scaled_exactly_once() -> void:
	var seen: Array[String] = [str(_live().get("species_id", ""))]
	for round_index in [2, 3]:
		if not await _fell_the_current_creature():
			return
		var live := _live()
		if live.is_empty():
			_fail("the trainer's creature %d never came out" % round_index)
			return
		var species := str(live.get("species_id", ""))
		_check(not seen.has(species),
			"creature %d is a different one ('%s'; already seen %s)"
				% [round_index, species, str(seen)])
		seen.append(species)
		var authored: Dictionary = _authored.get(species, {}) as Dictionary
		_check(not authored.is_empty(),
			"creature %d ('%s') is one of the trainer's authored %d"
				% [round_index, species, EXPECTED_TEAM])
		if authored.is_empty():
			return
		var id := str(_record().get("encounter_id", ""))
		_check(_participants(id) == 2,
			"both peers are still in the record for creature %d (%d participant(s)) -- §9 empties the"
				% [round_index, _participants(id)]
			+ " list at every round boundary and `_resume_trainer_encounter()` puts them back")
		# 4b. THE COMPOUNDING CLAIM, on the path that would produce it. Every
		# creature after the first is scaled by a row that was already applied to
		# the creature before it; each must land on authored x row, never on
		# authored x row x row. At 1.1 a squared multiplier reads 1.21, which
		# these tolerances separate by three orders of magnitude.
		_assert_scaled_by(live, authored, _configured_stat, _configured_cooldown,
			"on the trainer's creature %d, sent out into a fight two people were already in"
				% round_index)

	# 5. A LEAVE PUTS IT BACK. §10 re-derives on a leave exactly as on a join,
	# and with the joiner gone the row is the identity again.
	var id := str(_record().get("encounter_id", ""))
	var species := str(_live().get("species_id", ""))
	var authored: Dictionary = _authored.get(species, {}) as Dictionary
	_session.set("ids", [PEER_HOST] as Array[int])
	var verdict: Dictionary = _director.call("_host_commit_encounter",
		{"kind": "disengage", "encounter_id": id}, PEER_GUEST)
	_check(bool(verdict.get("ok", false)),
		"the second peer left the fight (%s)" % str(verdict.get("reason", "")))
	_check(_participants(id) == 1,
		"and the record is back to one participant (got %d)" % _participants(id))
	var live := _live()
	_assert_scaled_by(live, authored, 1.0, 1.0, "once the second peer had left")
	# The `combat_override` dictionary goes back VERBATIM, not rebuilt at
	# `base x 1.0`: a creature that authored no `attack_cooldown` (the Warden's
	# opening burrowback authors none) must not acquire one just for having been
	# in a fight that emptied out.
	var restored: Dictionary = live.get("combat_override", {}) as Dictionary
	var authored_override: Dictionary = authored.get("combat_override", {}) as Dictionary
	var restored_keys: Array = restored.keys()
	var authored_keys: Array = authored_override.keys()
	restored_keys.sort()
	authored_keys.sort()
	_check(restored_keys == authored_keys,
		"and its combat_override carries exactly the keys it was authored with (%s, authored %s)"
			% [str(restored_keys), str(authored_keys)])


# --- the assertion itself --------------------------------------------------------------

## Attack, defence, hit points and the BODY's live attack cooldown, against the
## authored numbers times the row that is supposed to be in force.
##
## `max_hp` is asserted against the authored number with NO multiplier applied at
## any row, which is §10's one outright prohibition: a boss with four times the
## health is four times as LONG, not four times as interesting.
##
## The cooldown is read off the body's own `_combat_cfg` rather than off the
## instance's `combat_override`, deliberately. `wild_creature.gd::set_engaged()`
## snapshots that config when the fight opens -- which is BEFORE the record this
## scaler reads even exists -- so a `combat_override` written afterwards would sit
## on the instance and never reach a single swing. Asserting on the instance would
## pass a build in which the number never reached the fight, which is exactly the
## class of defect this file exists for.
func _assert_scaled_by(live: Dictionary, authored: Dictionary,
		stat: float, cooldown: float, when: String) -> void:
	if live.is_empty() or authored.is_empty():
		_fail("nothing to measure %s" % when)
		return
	var want_attack := float(authored.get("attack", 0.0)) * stat
	var want_defence := float(authored.get("defence", 0.0)) * stat
	var want_cooldown := maxf(0.1, float(authored.get("attack_cooldown", 0.0)) * cooldown)
	var got_attack := float(live.get("attack", -1.0))
	var got_defence := float(live.get("defence", -1.0))
	var got_cooldown := float(live.get("body_attack_cooldown", -1.0))
	var got_hp_max := float(live.get("max_hp", -1.0))
	var authored_hp := float(authored.get("max_hp", -2.0))

	_check(authored_hp > 0.0, "the authored creature has real hit points %s (%.3f)" % [when, authored_hp])
	_check(absf(got_attack - want_attack) < 0.001,
		"attack is the authored %.3f x %.4f = %.3f %s (got %.3f)"
			% [float(authored.get("attack", 0.0)), stat, want_attack, when, got_attack])
	_check(absf(got_defence - want_defence) < 0.001,
		"defence is the authored %.3f x %.4f = %.3f %s (got %.3f)"
			% [float(authored.get("defence", 0.0)), stat, want_defence, when, got_defence])
	_check(absf(got_cooldown - want_cooldown) < 0.001,
		"the BODY swings on the authored %.3f x %.4f = %.3f %s (got %.3f) -- read off the body's own"
			% [float(authored.get("attack_cooldown", 0.0)), cooldown, want_cooldown, when, got_cooldown]
		+ " combat config, which is the number the swing timer uses")
	# §10's forbidden knob, asserted at every row including the identity.
	_check(absf(got_hp_max - authored_hp) < 0.001,
		"and max_hp is the AUTHORED %.3f %s, never multiplied by players (got %.3f;"
			% [authored_hp, when, got_hp_max]
		+ " x %.4f would be %.3f)" % [stat, authored_hp * stat])
	print("%s: attack %.3f defence %.3f cooldown %.3f max_hp %.3f" % [
		when, got_attack, got_defence, got_cooldown, got_hp_max])


# --- driving the fight ------------------------------------------------------------------

## Put the current creature down so the next one steps up, through the real
## combat path: the player's own quick attack, with the opponent's `hp` pulled to
## a ceiling first. Nothing this touches is asserted on anywhere in this file.
func _fell_the_current_creature() -> bool:
	var was := str(_live().get("species_id", ""))
	var frames := 0
	while frames < ROUND_FRAME_LIMIT:
		frames += 1
		if not bool(_director.call("trainer_battle_active")):
			_fail("the whole battle ended while trying to fell '%s'" % was)
			return false
		if not bool(_manager.call("is_fighting")):
			await physics_frame
			continue
		var live := _live()
		if str(live.get("species_id", "")) != was and not live.is_empty():
			# The next creature is out and the fight has re-opened around it.
			for i in 10:
				await physics_frame
			return true
		var mine: RefCounted = _manager.call("active_creature") as RefCounted
		if mine != null:
			mine.set("hp", float(mine.get("max_hp")))
		var opponent := _opponent_body()
		var ally: Node3D = _director.call("ally_body") as Node3D
		if opponent == null or ally == null:
			await physics_frame
			continue
		var theirs: RefCounted = opponent.get("instance") as RefCounted
		if theirs != null and float(theirs.get("hp")) > ENEMY_HP_CEILING:
			theirs.set("hp", ENEMY_HP_CEILING)
		var to := opponent.global_position - ally.global_position
		to.y = 0.0
		_rig.set("yaw", atan2(-to.x, -to.z))
		if to.length() > _reach(ally, opponent):
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("quick_ready")):
			await _press("combat_quick")
		else:
			await physics_frame
	_fail("'%s' was never felled inside %d frames" % [was, ROUND_FRAME_LIMIT])
	return false


## `smoke_boss.gd`'s own floor, and its comment carries the reason: a fixed
## "get within 2m" gate assumes two capsules can physically close to that
## distance, which is not true of every matchup, and a loop that never lets go of
## movement never swings at all.
func _reach(ally: Node3D, opponent: Node3D) -> float:
	var cfg: Dictionary = MATH.config().get("player_quick", {}) as Dictionary
	var span := float(cfg.get("range", 2.6))
	span += float(ally.call("body_radius")) + float(opponent.call("body_radius"))
	return maxf(1.0, span)


# --- reads ------------------------------------------------------------------------------

func _opponent_body() -> Node3D:
	return _world.find_child("TrainerCreature_%s_*" % TRAINER_ID, true, false) as Node3D


## The creature actually on the field, plus the cooldown its BODY is swinging on.
func _live() -> Dictionary:
	var body := _opponent_body()
	if body == null or not is_instance_valid(body):
		return {}
	var instance: Variant = body.get("instance")
	if instance == null:
		return {}
	var creature := instance as RefCounted
	var cfg: Dictionary = body.get("_combat_cfg") as Dictionary
	return {
		"species_id": str(creature.get("species_id")),
		"level": int(creature.get("level")),
		"hp": float(creature.get("hp")),
		"max_hp": float(creature.get("max_hp")),
		"attack": float(creature.get("attack")),
		"defence": float(creature.get("defence")),
		"combat_override": (creature.get("combat_override") as Dictionary).duplicate(true),
		"body_attack_cooldown": float(cfg.get("attack_cooldown", -1.0)),
	}


func _record() -> Dictionary:
	return _director.call("encounter_record") as Dictionary


func _host() -> RefCounted:
	return _director.get("_encounter_host") as RefCounted


func _participants(encounter_id: String) -> int:
	var host := _host()
	if host == null or encounter_id.is_empty():
		return -1
	return int(host.call("participant_count", encounter_id))


func _stamped(encounter_id: String) -> Dictionary:
	var host := _host()
	if host == null or encounter_id.is_empty():
		return {}
	return host.call("scaling", encounter_id) as Dictionary


func _progression() -> RefCounted:
	var game := root.get_node_or_null(^"/root/Game")
	return game.get("progression") as RefCounted if game != null else null


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)


func _report() -> void:
	print("")
	print("§10 scaling: %d assertion(s) run, %d failure(s)" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("encounter scaling: OK -- §10's multiplier reaches the creature, exactly once, at every row.")
		quit(0)
		return
	for line in _failures:
		print("encounter scaling FAIL: %s" % line)
	quit(1)
