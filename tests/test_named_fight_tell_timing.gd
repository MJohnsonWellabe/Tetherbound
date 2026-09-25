extends "res://tests/test_case.gd"

# ACCEPTANCE §6.1 F04, "the specified tell/recovery", for every Meadows named
# fight: the Warrens guardian, the relay officers (Dell, Vance), the three Sigil
# captains (Oreth, Halder, Vess), Keeper Hald and the Warden.
#
# `test_named_fight_profiles.gd` already holds the CHARGER/ACE tell FLOORS on
# the raw `combat` blocks. This file pins the tell and recovery each creature
# EFFECTIVELY fights with, to the exact numbers docs/design/BOSSES.md writes, and
# resolves them the way the game does rather than by re-implementing the merge:
#
#   trainer member -> trainer_npc.gd::creature_for(entry)   (member `combat`)
#                  -> wild_creature.gd body, trainer_owned=true
#                  -> _enemy_config_for_this_body()        (enemy -> enemy_trainer -> member)
#   Warrens guardian -> wild body (not trainer-owned) with the guardian `combat`
#                  and `signature_move` as its charged move, as burrow_warrens.gd
#                  and encounter_director.gd build it.
#
# A body that authors `charged_every` runs a quick/charged sequence; the charged
# step's tell/recovery come from `_select_attack()` (charged_telegraph /
# charged_recovery, floored there), exactly as `_enter(TELEGRAPH)` reads them.
# Otherwise the tell/recovery are `combat_ai.gd::duration_for()` on the merged
# config, again exactly what `_enter()` uses.
#
# CI's sparse checkout excludes /docs/, so -- like the profile test -- the
# contract is TRANSCRIBED into PINS below and each pin carries the BOSSES text it
# comes from. When BOSSES is readable, `test_every_citation_is_still_in_bosses`
# fails if a cited line has been edited, so the copy cannot drift silently.
#
# What is deliberately NOT pinned: a field BOSSES gives no value for. DIVER and
# the baseline members have no recovery in BOSSES; CURRENT has no tell of its
# own and is held only to the §1 ordinary floor. §2.1's per-chapter clamp is a
# "target recipe, not a claim that the current trainer controller consumes" it,
# and applies to §§5–8 rows without a §4 specification -- not pinned here.

const WILD := preload("res://scripts/creatures/wild_creature.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const BOSSES := "res://docs/design/BOSSES.md"
const BANDS_DIR := "res://data/config/bands"
const WARRENS := "res://data/config/burrow_warrens.json"
const EPS := 0.0001

const FLOOR_ORDINARY := "| Ordinary boss telegraph floor | 0.8 s |"
const WALL_ROW := "| WALL | telegraph .85 s, recovery 1.1 s"
const CHARGER_ROW := "| CHARGER | preferred range 4.5 m, lunge 7 m, telegraph .8 s, recovery .9 s"
const DIVER_ROW := "| DIVER | telegraph .4 s only with long positional cue"
const CURRENT_ROW := "| CURRENT | cooldown .7 s, recovery .55 s"
const ACE_ROW := "| ACE | telegraph 1.1 s, recovery 1.2 s"
const GUARDIAN_QUICK := "Ordinary pressure follows WALL: .85 s tell and 1.1 s recovery."
const GUARDIAN_FIST := "Target timing is 1.1 s ground/foreleg tell, 0.8 s active commitment and 1.2 s recovery."
const VANCE_TUSK := "Tuskroot closes 7 m after a .8 s minimum full-body charge cue, then recovers .9 s."
const W_WALL := "| 1 | Burrowback18 | WALL; .85 s tell, 1.1 s recovery;"
const W_DIVER := "| 2 | Galecrest18 | DIVER; positional entry plus .4 s strike tell"
const W_CURRENT := "| 3 | Brooktail19 | CURRENT; .7 s cooldown/.55 s recovery;"
const W_CHARGER := "| 4 | Meadowhart19 | CHARGER; 7 m lunge, .8 s visible charge floor, .9 s recovery;"
const W_ACE := "| 5 | Tuskroot20 | ACE/Earth Fist; 2.5 s first delay, 1.1 s signature tell, 6.5 m/72° cone, 1.2 s recovery;"
const HEAVY_FLOOR := "| Heavy/signature telegraph floor | 1.1 s |"

## [fight, member index (-1 = the Warrens guardian), species, attack, field,
##  op ("eq" exact / "ge" floor), value, citations...]
const PINS := [
	# §4.1 Burrow Warrens guardian: WALL quick, then Earth Fist on the charged slot.
	["warrens_guardian", -1, "burrowback", "quick", "telegraph", "eq", 0.85, GUARDIAN_QUICK],
	["warrens_guardian", -1, "burrowback", "quick", "recovery", "eq", 1.1, GUARDIAN_QUICK],
	["warrens_guardian", -1, "burrowback", "charged", "telegraph", "eq", 1.1, GUARDIAN_FIST],
	["warrens_guardian", -1, "burrowback", "charged", "recovery", "eq", 1.2, GUARDIAN_FIST],
	# §5 relay_officer_dell: "relay officer composition", no profile -> §1 floor.
	["relay_officer_dell", 0, "mosshell", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["relay_officer_dell", 1, "burrowback", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["relay_officer_dell", 2, "galecrest", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	# §4.2 Captain Vance.
	["relay_captain", 0, "galecrest", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["relay_captain", 1, "duskhush", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["relay_captain", 2, "tuskroot", "quick", "telegraph", "eq", 0.8, VANCE_TUSK, CHARGER_ROW],
	["relay_captain", 2, "tuskroot", "quick", "recovery", "eq", 0.9, VANCE_TUSK, CHARGER_ROW],
	# §4.3 Oreth: WALL -> baseline -> CURRENT.
	["captain_riverwatch", 0, "mosshell", "quick", "telegraph", "eq", 0.85, WALL_ROW],
	["captain_riverwatch", 0, "mosshell", "quick", "recovery", "eq", 1.1, WALL_ROW],
	["captain_riverwatch", 1, "trailpup", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["captain_riverwatch", 2, "brooktail", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["captain_riverwatch", 2, "brooktail", "quick", "recovery", "eq", 0.55, CURRENT_ROW],
	# §4.3 Halder: baseline -> CHARGER -> CURRENT.
	["captain_field", 0, "duskhush", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["captain_field", 1, "tuskroot", "quick", "telegraph", "eq", 0.8, CHARGER_ROW],
	["captain_field", 1, "tuskroot", "quick", "recovery", "eq", 0.9, CHARGER_ROW],
	["captain_field", 2, "meadowhart", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["captain_field", 2, "meadowhart", "quick", "recovery", "eq", 0.55, CURRENT_ROW],
	# §4.3 Vess: baseline -> baseline -> DIVER.
	["captain_ridge", 0, "trailpup", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["captain_ridge", 1, "duskhush", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["captain_ridge", 2, "galecrest", "quick", "telegraph", "eq", 0.4, DIVER_ROW],
	# §4.4 Keeper Hald: DIVER -> baseline -> WALL.
	["stronghold_elite", 0, "galecrest", "quick", "telegraph", "eq", 0.4, DIVER_ROW],
	["stronghold_elite", 1, "burrowback", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["stronghold_elite", 2, "mosshell", "quick", "telegraph", "eq", 0.85, WALL_ROW],
	["stronghold_elite", 2, "mosshell", "quick", "recovery", "eq", 1.1, WALL_ROW],
	# §4.5 Warden Aldis, row by row.
	["warden_aldis", 0, "burrowback", "quick", "telegraph", "eq", 0.85, W_WALL, WALL_ROW],
	["warden_aldis", 0, "burrowback", "quick", "recovery", "eq", 1.1, W_WALL, WALL_ROW],
	["warden_aldis", 1, "galecrest", "quick", "telegraph", "eq", 0.4, W_DIVER, DIVER_ROW],
	["warden_aldis", 2, "brooktail", "quick", "telegraph", "ge", 0.8, FLOOR_ORDINARY],
	["warden_aldis", 2, "brooktail", "quick", "recovery", "eq", 0.55, W_CURRENT, CURRENT_ROW],
	["warden_aldis", 3, "meadowhart", "quick", "telegraph", "ge", 0.8, W_CHARGER],
	["warden_aldis", 3, "meadowhart", "quick", "telegraph", "eq", 0.8, CHARGER_ROW],
	["warden_aldis", 3, "meadowhart", "quick", "recovery", "eq", 0.9, W_CHARGER, CHARGER_ROW],
	["warden_aldis", 4, "tuskroot", "quick", "telegraph", "ge", 1.1, W_ACE, HEAVY_FLOOR],
	["warden_aldis", 4, "tuskroot", "quick", "telegraph", "eq", 1.1, ACE_ROW],
	["warden_aldis", 4, "tuskroot", "quick", "recovery", "eq", 1.2, W_ACE, ACE_ROW],
]

## Every Meadows named fight must be pinned member-for-member, so a roster that
## grows a creature cannot slip in unpinned.
const TEAM_SIZES := {
	"relay_officer_dell": 3, "relay_captain": 3, "captain_riverwatch": 3,
	"captain_field": 3, "captain_ridge": 3, "stronghold_elite": 3, "warden_aldis": 5,
}


func _read_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _trainer(id: String) -> Dictionary:
	for band: String in DirAccess.get_directories_at(BANDS_DIR):
		var path := "%s/%s/trainers.json" % [BANDS_DIR, band]
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = _read_json(path)
		var rows: Variant = (parsed as Dictionary).get("trainers", []) if parsed is Dictionary else parsed
		if rows is not Array:
			continue
		for raw: Variant in (rows as Array):
			if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
				return raw as Dictionary
	return {}


func _members(trainer: Dictionary) -> Array:
	for key: String in ["creatures", "team", "members"]:
		var rows: Variant = trainer.get(key, [])
		if rows is Array and not (rows as Array).is_empty():
			return rows as Array
	return []


func _guardian() -> Dictionary:
	var warrens: Variant = _read_json(WARRENS)
	return ((warrens as Dictionary).get("guardian", {}) as Dictionary) if warrens is Dictionary else {}


## A body built the way the game builds this fight's creature, before engage.
func _probe(fight: String, index: int) -> WILD:
	var body := WILD.new()
	if index < 0:
		var spec := _guardian()
		body.instance = SPECIES.spawn(str(spec.get("species", "")))
		var charged := str(spec.get("signature_move", ""))
		if body.instance != null and not charged.is_empty():
			body.instance.set("move_charged", charged)
		body.combat_override = (spec.get("combat", {}) as Dictionary).duplicate(true)
		body.trainer_owned = false
	else:
		var entry: Dictionary = _members(_trainer(fight))[index] as Dictionary
		var creature: RefCounted = TRAINER_NPC.creature_for(entry)
		body.instance = creature
		body.combat_override = (creature.get("combat_override") as Dictionary).duplicate(true)
		body.trainer_owned = true
	body._combat_cfg = body._enemy_config_for_this_body()
	return body


## {"quick": {telegraph, recovery}, "charged": {...}} -- the beats `_enter()`
## would time. "charged" is present only for a body with a named-attack cadence.
func _timings(body: WILD) -> Dictionary:
	var cfg: Dictionary = body._combat_cfg
	var out := {}
	if int(cfg.get("charged_every", 0)) > 0 and body.instance != null:
		var cadence := int(cfg.get("charged_every", 0))
		for step: int in range(cadence):
			var attack: Dictionary = body._select_attack()
			var slot := "charged" if (step + 1) % cadence == 0 else "quick"
			out[slot] = {"telegraph": float(attack.get("telegraph", 0.0)),
				"recovery": float(attack.get("recovery", 0.0)), "move_id": str(attack.get("move_id", ""))}
	else:
		out["quick"] = {"telegraph": AI.duration_for(AI.Intent.TELEGRAPH, cfg),
			"recovery": AI.duration_for(AI.Intent.RECOVER, cfg)}
	return out


func test_every_meadows_named_fight_fights_with_the_bosses_tell_and_recovery() -> void:
	var cache := {}
	var checked := 0
	for pin: Array in PINS:
		var fight := str(pin[0])
		var index := int(pin[1])
		var key := "%s#%d" % [fight, index]
		if not cache.has(key):
			if index >= 0:
				var members := _members(_trainer(fight))
				assert_true(index < members.size(), "'%s' has no member %d" % [fight, index + 1])
				if index >= members.size():
					continue
				assert_eq(str((members[index] as Dictionary).get("species", "")), str(pin[2]),
					"'%s' member %d is no longer the %s BOSSES names; re-read its row" % [fight, index + 1, pin[2]])
			else:
				assert_eq(str(_guardian().get("species", "")), str(pin[2]), "the Warrens guardian changed species")
			var body := _probe(fight, index)
			cache[key] = _timings(body)
			body.free()
		var timings: Dictionary = cache[key]
		var attack := str(pin[3])
		assert_true(timings.has(attack), "'%s' member %d has no %s attack to time" % [fight, index + 1, attack])
		if not timings.has(attack):
			continue
		var got := float((timings[attack] as Dictionary)[str(pin[4])])
		var want := float(pin[6])
		var label := "'%s' %s (member %d) %s %s is %.2fs; BOSSES: \"%s\"" % [
			fight, pin[2], index + 1, attack, pin[4], got, pin[7]]
		if str(pin[5]) == "eq":
			assert_almost_eq(got, want, EPS, label + " -> exactly %.2fs" % want)
		else:
			assert_true(got >= want - EPS, label + " -> at least %.2fs" % want)
		checked += 1
	assert_eq(checked, PINS.size(), "every transcribed pin must be checked")


func test_the_guardian_earth_fist_is_the_charged_step_of_its_sequence() -> void:
	# §4.1: "`guardian.combat.charged_every=2` alternates a quick with the
	# existing charged-slot Earth Fist, beginning with quick." Without this the
	# 1.1/1.2 s pins above could be timing some other move.
	var body := _probe("warrens_guardian", -1)
	assert_eq(int(body._combat_cfg.get("charged_every", 0)), 2, "the guardian alternates quick and Earth Fist")
	var first: Dictionary = body._select_attack()
	var second: Dictionary = body._select_attack()
	assert_ne(str(first.get("move_id", "")), "earth_fist", "the sequence begins with quick")
	assert_eq(str(second.get("move_id", "")), "earth_fist", "the charged step is Earth Fist")
	body.free()


func test_every_member_of_every_named_meadows_fight_is_pinned() -> void:
	var pinned := {}
	for pin: Array in PINS:
		pinned["%s#%d" % [pin[0], int(pin[1])]] = true
	for fight: String in TEAM_SIZES:
		var members := _members(_trainer(fight))
		assert_eq(members.size(), int(TEAM_SIZES[fight]),
			"'%s' changed size; pin its new member's tell/recovery against BOSSES" % fight)
		for index: int in range(members.size()):
			assert_true(pinned.has("%s#%d" % [fight, index]),
				"'%s' member %d has no tell pin" % [fight, index + 1])
	assert_true(pinned.has("warrens_guardian#-1"), "the Warrens guardian is pinned")


func test_every_citation_is_still_in_bosses() -> void:
	var text := FileAccess.get_file_as_string(BOSSES)
	if text.is_empty():
		assert_true(true, "BOSSES.md is absent (CI excludes /docs/); pins run from the transcription")
		return
	var seen := {}
	for pin: Array in PINS:
		for i: int in range(7, pin.size()):
			var cite := str(pin[i])
			if seen.has(cite):
				continue
			seen[cite] = true
			assert_true(text.contains(cite),
				"BOSSES no longer contains the line this pin cites; re-read it: \"%s\"" % cite)
