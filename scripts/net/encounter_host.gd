extends RefCounted

## Stage B Wave 4 lane 4.C. THE ENCOUNTER HOST: one authority per fight.
##
## `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §3-§6 and §9. The record this file
## holds IS the fight: its `hp` is the hit points, its `participants` is who is
## in it, its `phase` is what it is doing. A client renders that record and
## never decrements a number in it "for responsiveness" -- a bar that un-drops
## is worse than a bar that lags.
##
## ## Pure, for the same reason `world_ledger.gd` is
##
## No scene tree, no `multiplayer`, no `Game`, no node. Every position this
## file tests is passed IN as a `Vector3` by whoever holds the bodies
## (`encounter_director.gd`, which is the transport, exactly as
## `ledger_rpc.gd` is the transport for the ledger). That is what lets
## `tests/test_encounter_host_rejects_friendly_strike.gd` drive the friendly-fire
## refusal deterministically and headlessly, with no networking and no world.
##
## It also keeps the ONE rule the protocol exists to enforce (§2) checkable by
## reading one file: **no peer may author both a hit and the position it landed
## on**. Nothing here reads a payload's position to decide an outcome. The
## caller hands in the host's own positions; the intent's own `origin` reaches
## exactly one line (`_retro_window_applies`) and can only ever LOSE the striker
## its latency tolerance, never win it a hit.
##
## ## The verdict
##
## `world_ledger.gd`'s exact shape, so no caller branches on the type of the
## answer and `ledger_rpc.gd`'s consumers can read an encounter refusal with the
## code they already have:
##
##     {"ok": bool, "kind": String, "peer": int, "code": String,
##      "reason": String, "pending": false, "delta": Dictionary}
##
## Refusal codes, all stable enough to branch on:
##   `unknown_encounter`  no such `encounter_id`, or it is already `done`
##   `not_participant`    this peer is not in that fight
##   `wrong_phase`        the fight is resolving or over
##   `friendly_target`    §5 -- the strike resolved onto another participant's
##                        creature or trainer. A REFUSAL, never a damage
##                        number of zero.
##   `replayed_action`    the action id did not advance for this participant
##   `cooldown`           the host's deadline for the preceding action remains
##   `not_catchable`      §8 -- a trainer's creature can never be caught
##   `already_resolving`  §8 -- another peer's catch attempt committed first
##   `malformed`          the intent is missing a field it needs
##
## A strike that connects with nothing is `ok` with `"hit": false` in the
## delta: missing is a legal outcome of a legal swing, not a refusal.

const MATH := preload("res://scripts/combat/combat_math.gd")
const TRAINING_WORLD := preload("res://autoload/world_state.gd")
const ACTOR_AUTHORITY := preload("res://scripts/net/character_authority.gd")
const UTILITY_EFFECTS := preload("res://scripts/combat/utility_effects.gd")
const TETHER_COMMANDS := preload("res://scripts/combat/tether_commands.gd")
const ACTOR_MOVE_DB := preload("res://scripts/creatures/move_db.gd")
var _actor_moves: RefCounted = null
var _staging_saved_item_character := ""

const CONFIG_PATH := "res://data/config/multiplayer.json"

## §5's latency tolerance and §8's arbitration backstop, both from
## `data/config/multiplayer.json`'s `encounter` block. Cached per-process the
## way every other config reader here does it.
static var _config_cache: Dictionary = {}


## The `encounter` block of `data/config/multiplayer.json`. Empty when the file
## or the block is missing, so every reader below falls back to its own literal
## and a partial edit cannot crash a fight.
static func config() -> Dictionary:
	if not _config_cache.is_empty():
		return _config_cache
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var block: Variant = (parsed as Dictionary).get("encounter", {})
	if block is Dictionary:
		_config_cache = block
	return _config_cache


static func strike_latency_tolerance_ms() -> int:
	return int(config().get("strike_latency_tolerance_ms", 250))


static func catch_arbitration_window_ms() -> int:
	return int(config().get("catch_arbitration_window_ms", 6000))


static func catch_finish_timeout_s() -> float:
	return maxf(0.1, float(config().get("catch_finish_timeout_s", 5.0)))


static func catch_finish_result_ttl_s() -> float:
	return maxf(1.0, float(config().get("catch_finish_result_ttl_s", 30.0)))


## §10 / D-MP12. What `participant_count` people fighting one opponent costs
## the opponent, from `multiplayer.json`'s `encounter.scaling.by_participants`.
##
## Composition first, health second, and **never HP x players**: there is no
## hp key in the table and none is read here, so the failure §10 names outright
## -- a boss with four times the health being four times as LONG rather than
## four times as interesting -- is not reachable by editing config.
##
## A count of 1 is the identity row, so a solo player's fight is untouched by
## every line of this. A count above the largest row clamps to it: a five-player
## session is scaled as four, never as unscaled, which is the direction a
## missing row has to fail in.
##
## Returns `{"stat_multiplier": float, "attack_cooldown_multiplier": float}`,
## always populated, so no caller branches on a missing key. There is
## deliberately no `opponents_extra`: §10's third clause is "extra opponents or
## roles WHERE THE ENCOUNTER DEFINES THEM", and on this tree no encounter does
## -- `combat_manager.gd` holds one opponent body and a trainer's roster is
## authored and finite. The composition half that IS implementable is
## `pick_struck()` below, plus the cooldown. `multiplayer.json` carries the same
## reasoning where a future edit has to read it.
static func scaling_for(participant_count: int) -> Dictionary:
	var identity := {"stat_multiplier": 1.0, "attack_cooldown_multiplier": 1.0}
	# No `maxi(1, ...)` clamp here, deliberately, and 4.C's F7 is the precedent:
	# break S of this lane's break/fail/revert set removed it and every
	# assertion stayed green, because a count of 0 (or a negative one) looks up
	# a row the table does not have and falls through to the identity below --
	# which is the answer the clamp was written to produce. A line no test can
	# turn red is a line that is not enforcing anything, so it is gone rather
	# than left standing as if it were protection. The BEHAVIOUR is still
	# pinned, by `test_a_count_of_zero_or_less_is_read_as_one_player`.
	var count := participant_count
	var table: Variant = config().get("scaling", {})
	if not (table is Dictionary):
		return identity
	var rows: Variant = (table as Dictionary).get("by_participants", {})
	if not (rows is Dictionary) or (rows as Dictionary).is_empty():
		return identity
	var by_count: Dictionary = rows as Dictionary
	# Clamp DOWNWARD to the largest authored row rather than falling back to the
	# identity: a count the table does not name is a bigger group than anybody
	# tuned for, and answering "no scaling at all" there would make the fight
	# get easier the more people joined.
	var highest := 0
	for key: Variant in by_count.keys():
		highest = maxi(highest, int(key))
	if highest <= 0:
		return identity
	var wanted := str(mini(count, highest))
	if not by_count.has(wanted):
		return identity
	var row: Variant = by_count[wanted]
	if not (row is Dictionary):
		return identity
	return {
		"stat_multiplier": maxf(0.01, float((row as Dictionary).get("stat_multiplier", 1.0))),
		"attack_cooldown_multiplier":
			maxf(0.01, float((row as Dictionary).get("attack_cooldown_multiplier", 1.0))),
	}


## Live encounters, `encounter_id` -> record (§3). Only the host ever writes
## this map through `open`/`join`/`strike`/`leave`; a client holds one record it
## was handed, in `encounter_director.gd`, and never mutates it.
var encounters: Dictionary = {}

## Host commit counter, rides every record as `seq` so a peer can spot a gap.
var seq: int = 0

## Minted ids are `<host peer id>:<n>`, unique for the session because only one
## process ever mints them.
var _minted: int = 0
var _host_peer_id: int = 1

## Host-owned action ledger, encounter id -> peer id -> accepted action state.
## A departed bound actor's entry temporarily uses its stable-character String
## key in this SAME cache; active peer keys are ints. Rejoin transfers it back.
## This deliberately does not ride the replicated encounter record: clients
## need the verdict and shared HP, not authority internals they could mistake
## for something they are allowed to write back.
var _strike_authority: Dictionary = {}

## Debug-only evidence, encounter id -> peer id -> the latest strike receipt.
## One detached row replaces the preceding row for that participant. It never
## rides the replicated encounter record and no combat decision reads it.
var _strike_receipts: Dictionary = {}
var _vitals_namespace: String = Crypto.new().generate_random_bytes(16).hex_encode()


func _init(host_peer_id: int = 1) -> void:
	_host_peer_id = host_peer_id


# --- opening, joining, leaving -------------------------------------------------

## Open a fight. `opponent` is the row §3 names: `species_id`, `level`, `hp`,
## `hp_max`, `owner_npc`. `kind` is "wild" | "trainer" | "boss" -- ONE record
## covers all three, because a boss is data and not a code path (§1).
##
## Returns the record, already carrying `peer_id` as its first participant.
func open(peer_id: int, realm: String, kind: String, opponent: Dictionary,
		creature_uid: String = "", character_id: String = "") -> Dictionary:
	_minted += 1
	seq += 1
	var id := "%d:%d" % [_host_peer_id, _minted]
	var record := {
		"encounter_id": id,
		# D97: explicit, never a global "current realm". Two peers stand in two
		# realms at once from Wave 6 and a fight stamped with whichever realm
		# the host happens to be standing in is a Cloudreach fight filed in the
		# Meadows.
		"realm": realm,
		"kind": kind,
		"opponent": _opponent_row(opponent),
		"participants": {},
		"phase": "active",
		"seq": seq,
	}
	encounters[id] = record
	_strike_authority[id] = {}
	_strike_receipts[id] = {}
	_add_participant(record, peer_id, creature_uid, character_id)
	_restamp_scaling(record)
	return record


## §6. A second player joins a fight already running. No phase change, no reset,
## no re-intro camera for anyone already in it -- this function deliberately
## touches nothing but `participants` and `seq`, so there is no line here that
## could reset a fight even by accident.
##
## Arriving late costs nothing (§7 pays each participant), so there is no
## eligibility cut-off either; `joined_seq` is recorded for 4.D's rewards to
## read, not to gate on.
func join(encounter_id: String, peer_id: int, creature_uid: String = "",
		character_id: String = "") -> Dictionary:
	var record: Dictionary = encounters.get(encounter_id, {})
	if record.is_empty() or str(record.get("phase", "")) == "done":
		return _refuse("engage", peer_id, "unknown_encounter",
			"That fight is over.")
	var participants: Dictionary = record["participants"]
	if participants.has(peer_id):
		# Re-sending `engage` for a fight you are already in is not an error and
		# must not re-seat you at a new `joined_seq`; a retried intent is the
		# ordinary shape of an unreliable world.
		return _ok("engage", peer_id, {"encounter_id": encounter_id, "rejoined": true})
	# Stable admitted owner identity cannot alias another participant, even
	# before either body is bound. Otherwise retained HP can be overwritten.
	if not character_id.is_empty():
		for other_peer: Variant in participants:
			if (participants[other_peer] as Dictionary).get("character_id") == character_id:
				return _refuse("engage", peer_id, "duplicate_character", "That character is already in this fight.")
	_strike_state_for(encounter_id).erase(peer_id)
	_add_participant(record, peer_id, creature_uid, character_id)
	seq += 1
	record["seq"] = seq
	# §10: re-derived whenever `participants` changes, a mid-fight join
	# included. The record carries the answer so every participant's process
	# reads the same one rather than each recomputing it from its own idea of
	# who is in the fight.
	_restamp_scaling(record)
	return _ok("engage", peer_id, {"encounter_id": encounter_id, "joined": true})


## §9. `disengage`, a disconnect and a downed trainer are the SAME event here:
## remove the participant, keep the fight alive if anyone remains, and do not
## reset it. The last participant leaving ends it -- with the HP it has, because
## a creature that heals instantly because everyone walked away is an exploit.
func leave(encounter_id: String, peer_id: int) -> Dictionary:
	var record: Dictionary = encounters.get(encounter_id, {})
	if record.is_empty():
		return _refuse("disengage", peer_id, "unknown_encounter", "That fight is over.")
	var participants: Dictionary = record["participants"]
	var departing: Dictionary = participants.get(peer_id, {})
	var stable_id := str(departing.get("character_id", ""))
	if not stable_id.is_empty() and (departing.has("actor_vitals") or departing.has("move_resources")):
		var retained: Dictionary = record.get("retained_actor_participants", {})
		record["retained_actor_participants"] = retained
		retained[stable_id] = departing
		# Move the SAME private action authority to stable identity while its
		# peer is absent. Round reset/close still clears this existing cache.
		var authority := _strike_state_for(encounter_id)
		if authority.has(peer_id): authority[stable_id] = authority[peer_id]
	participants.erase(peer_id)
	_strike_state_for(encounter_id).erase(peer_id)
	(_strike_receipts.get(encounter_id, {}) as Dictionary).erase(peer_id)
	seq += 1
	record["seq"] = seq
	# A leaver stops being a target and stops being scaled for. Both halves are
	# the same §10 sentence -- re-derived when `participants` changes -- and the
	# fight is deliberately NOT reset by either (§9).
	(record.get("struck_counts", {}) as Dictionary).erase(peer_id)
	_restamp_scaling(record)
	if participants.is_empty():
		record["phase"] = "done"
	return _ok("disengage", peer_id,
		{"encounter_id": encounter_id, "remaining": participants.size()})


func record(encounter_id: String) -> Dictionary:
	return encounters.get(encounter_id, {})


func is_participant(encounter_id: String, peer_id: int) -> bool:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return false
	return (rec["participants"] as Dictionary).has(peer_id)


## Every peer that should be told about this record.
func participants_of(encounter_id: String) -> Array:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return []
	var out: Array = []
	for key: Variant in (rec["participants"] as Dictionary).keys():
		out.append(int(key))
	return out


# --- the opponent's hit points and where it is ---------------------------------

## §3. The record's `hp` and COMBAT-1 break state are host truth. They are
## stamped together after a strike so an observer can never receive new HP
## beside poise from the preceding hit.
func set_opponent_hp(encounter_id: String, hp: float, hp_max: float,
		combat_state: Dictionary = {}) -> void:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return
	var opponent: Dictionary = rec["opponent"]
	opponent["hp"] = maxf(0.0, hp)
	opponent["hp_max"] = maxf(1.0, hp_max)
	for key: String in ["poise", "poise_max", "staggered", "critical_ready", "stagger_left"]:
		if combat_state.has(key):
			opponent[key] = combat_state[key]
	seq += 1
	rec["seq"] = seq


## Lane 4.D. The SAME fight, against their next creature.
##
## A trainer battle is one encounter that happens to have several creatures in
## it -- `encounter_director.gd::_trainer_battle_anchor`'s own header says so --
## and §7 pays "every participant" of that one encounter. Minting a fresh record
## per round would quietly drop a joiner between rounds: they joined round one's
## record and the win is recorded against round three's, so the person who
## fought two thirds of the boss is paid for none of it.
##
## So a round change swaps the OPPONENT and keeps everything else: the id, the
## participants, their `joined_seq`, the phase. The position history is cleared
## with the opponent it described, because a strike tested against where the
## previous creature was standing is a ghost hit on a body that has left the
## field.
func set_opponent(encounter_id: String, opponent: Dictionary) -> bool:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty() or str(rec.get("phase", "")) == "done":
		return false
	rec["opponent"] = _opponent_row(opponent)
	# A new roster member is a new action lifecycle. No cooldown or action id
	# from the departed body may suppress the opening move of the next round.
	_strike_authority[encounter_id] = {}
	_strike_receipts[encounter_id] = {}
	seq += 1
	rec["seq"] = seq
	return true


## Record where the host's own opponent body is, right now, on the host's clock.
##
## §5 step 3's history. A player on a 60 ms link swung at where the creature
## VISIBLY was, which is where the host had it a round trip ago, so the connect
## test is allowed to succeed against any sample inside
## `strike_latency_tolerance_ms`. Samples older than that are dropped on the
## way in: an unbounded history would let a strike land against a position the
## creature left five seconds ago, which is the ghost hit this window exists to
## bound.
func note_opponent_position(encounter_id: String, at: Vector3, now_ms: int) -> void:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return
	var opponent: Dictionary = rec["opponent"]
	opponent["position"] = [at.x, at.y, at.z]
	var samples: Array = opponent.get("samples", []) as Array
	samples.append([now_ms, at.x, at.y, at.z])
	var cutoff := now_ms - strike_latency_tolerance_ms()
	while not samples.is_empty() and int((samples[0] as Array)[0]) < cutoff:
		samples.remove_at(0)
	opponent["samples"] = samples
	# COMBAT-2. This is the host's per-tick clock feed and it precedes every
	# record publication, so bring each participant's Wind up to the same clock
	# here. Otherwise a waiting participant's row stays frozen at its
	# post-action value and every broadcast overwrites their regenerating pool.
	advance_wind(encounter_id, now_ms)


## Regenerate every participant's stored Wind to `now_ms` from that row's own
## stored profile. Idempotent on the host clock (regeneration starts from
## max(updated, ready) and `wind_updated_ms` advances), so a later preview or
## commit at the same instant cannot regenerate twice. Rows that have never
## spent Wind carry no pool yet and are left alone.
func advance_wind(encounter_id: String, now_ms: int) -> void:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return
	for row: Variant in (rec.get("participants", {}) as Dictionary).values():
		if not row is Dictionary: continue
		var pools: Array = row.get("move_resources", {}).values()
		if row.has("wind"): pools.append(row)
		for pool: Dictionary in pools:
			if not pool.has("wind"): continue
			_advance_participant_wind(pool, {"max": float(pool.get("wind_max", 100.0)),
				"regen_per_second": float(pool.get("wind_regen_per_second", 18.0))}, now_ms)


func opponent_position(encounter_id: String) -> Vector3:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return Vector3.ZERO
	return to_vec3((rec["opponent"] as Dictionary).get("position", []))


func opponent_hp(encounter_id: String) -> float:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return 0.0
	return float((rec["opponent"] as Dictionary).get("hp", 0.0))


# --- §5: resolving a strike ------------------------------------------------------

## Validate a `strike_intent` against the host's own view of the world.
##
## `intent` is what the player DID and nothing about what happened (§4): `move`,
## `origin`, `facing`, and a monotonic `action`. It carries no damage number and no target -- that
## asymmetry is the protocol.
##
## `view` is what the HOST holds, and every position in it is the host's own:
##
##     {
##       "now_ms":  int,      # the host's clock
##       "origin":  Vector3,  # the host's copy of the STRIKING creature
##       "bodies":  Array,    # every deployed body the host holds, as
##                            # {"owner_peer_id": int, "position": Vector3,
##                            #  "role": "creature"|"trainer"}
##     }
##
## The opponent's position comes from the record, never from `view`, so a caller
## cannot substitute one.
##
## Returns the verdict shape. On `ok` the delta carries
## `{"hit": bool, "target": "opponent"|"", "connected_at_ms": int}` -- whether
## the swing landed, which the caller then rolls damage for with the HOST's own
## `_rng` (the roll is deliberately NOT made here: the damage arithmetic lives
## in `combat_manager.gd` beside the creature stats it reads, and a second copy
## of it in this file would be a second copy that eventually disagrees).
func validate_strike(intent: Dictionary, peer_id: int, view: Dictionary) -> Dictionary:
	if not pending_tether_items(str(intent.get("encounter_id", ""))).is_empty():
		return _refuse("strike_intent", peer_id, "item_save_pending", "The original item is still being saved.")
	var encounter_id := str(intent.get("encounter_id", ""))
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return _refuse("strike_intent", peer_id, "unknown_encounter", "That fight is over.")
	if not (rec["participants"] as Dictionary).has(peer_id):
		return _refuse("strike_intent", peer_id, "not_participant",
			"You are not in that fight.")
	var phase := str(rec.get("phase", ""))
	if phase != "active":
		return _record_strike_receipt(intent, peer_id, view, rec,
			_refuse("strike_intent", peer_id, "wrong_phase",
				"That fight is not taking attacks right now."))
	# `has()` before `get()`, deliberately and everywhere in this function: a
	# missing key read straight through `get()` returns null, `int(null)` is 0
	# and `Vector3(null)` is the origin -- which turns a malformed intent into a
	# strike resolved at the world origin instead of into a refusal.
	if not intent.has("move") or not (intent["move"] is Dictionary):
		return _record_strike_receipt(intent, peer_id, view, rec,
			_refuse("strike_intent", peer_id, "malformed",
				"That attack did not say what it was."))
	var move: Dictionary = intent["move"]
	var facing := to_vec3(intent.get("facing", []))
	if facing.length_squared() <= 0.000001:
		return _record_strike_receipt(intent, peer_id, view, rec,
			_refuse("strike_intent", peer_id, "malformed",
				"That attack did not say which way it faced."))
	if not intent.has("action") or typeof(intent["action"]) != TYPE_INT \
			or int(intent["action"]) <= 0:
		return _refuse("strike_intent", peer_id, "malformed",
			"That attack did not carry a valid action id.")

	var host_origin := to_vec3(view.get("origin", []))
	var now_ms := int(view.get("now_ms", 0))
	var action := int(intent["action"])
	var authority := strike_authority_state(encounter_id, peer_id)
	var started := move_commit(encounter_id, peer_id, action)
	var from_start := not started.is_empty()
	if from_start and (action != int(authority.last_action) or started.get("resolved") == true or now_ms < int(started.strike_at_ms) \
		or view.get("move_actor_binding") != started.binding or intent.get("move_id") != started.move_id \
		or intent.get("slot") != started.slot or move != started.move):
		return _refuse("strike_intent", peer_id, "stale_move_start", "That move cannot arrive from this creature now.")
	var participant: Dictionary = (rec.get("participants", {}) as Dictionary).get(peer_id, {})
	var last_action := maxi(int(authority.get("last_action", 0)),
		int(participant.get("wind_last_action", 0)))
	if action <= last_action and not from_start:
		return _record_strike_receipt(intent, peer_id, view, rec,
			_refuse("strike_intent", peer_id, "replayed_action",
				"That attack was already handled."))
	if now_ms < int(authority.get("deadline_ms", 0)) and not from_start:
		return _record_strike_receipt(intent, peer_id, view, rec,
			_refuse("strike_intent", peer_id, "cooldown",
				"That move is still recovering."))

	# §5's whole point, and the reason `friendly_target` is a refusal rather
	# than a damage number of zero: WHO the swing resolved onto is decided
	# BEFORE any roll, from bodies the host holds, by owner id (4.B's H5).
	var friendly := _friendly_body_struck(move, host_origin, facing, peer_id, rec, view)
	if not friendly.is_empty():
		if from_start:
			started["resolved"] = true
			_strike_state_for(encounter_id)[peer_id]["move_start"] = started
			_strike_state_for(encounter_id)[peer_id]["move_starts"][str(action)] = started
		return _record_strike_receipt(intent, peer_id, view, rec,
			_refuse("strike_intent", peer_id, "friendly_target",
				"You can't attack your own side."), true)

	var connected := _connects_now_or_recently(move, host_origin, facing, rec, intent, now_ms)
	var lock_ms := move_lock_ms(move)
	var deadline_ms := int(authority.deadline_ms) if from_start else now_ms + lock_ms
	var starts: Dictionary = _strike_state_for(encounter_id).get(peer_id, {}).get("move_starts", {})
	_strike_state_for(encounter_id)[peer_id] = {
		"last_action": action,
		"accepted_at_ms": now_ms,
		"deadline_ms": deadline_ms,
		"cooldown_ms": lock_ms,
	}
	if from_start:
		started["resolved"] = true
		_strike_state_for(encounter_id)[peer_id]["move_start"] = started
		starts[str(action)] = started
	_strike_state_for(encounter_id)[peer_id]["move_starts"] = starts
	return _record_strike_receipt(intent, peer_id, view, rec,
		_ok("strike_intent", peer_id, {
		"encounter_id": encounter_id,
		"hit": bool(connected.get("hit", false)),
		"target": "opponent" if bool(connected.get("hit", false)) else "",
		"connected_at_ms": int(connected.get("at_ms", now_ms)),
		"accepted_action": action,
		"accepted_at_ms": now_ms,
		"cooldown_deadline_ms": deadline_ms,
		}), true)


## The director supplies the admitted owned row and actual body binding. The
## client names only a slot; costs, timing, cooldown and resources are host data.
## Keep the start beside the existing strike authority, never on a client card.
func authorize_move_start(intent: Dictionary, peer: int, owned: Dictionary,
		binding: Dictionary, move: Dictionary, wind_profile: Dictionary, now_ms: int) -> Dictionary:
	var id := str(intent.get("encounter_id", ""))
	if not pending_tether_items(id).is_empty(): return _refuse("move_start", peer, "item_save_pending", "The original item is still being saved.")
	var rec: Dictionary = encounters.get(id, {})
	var participant: Dictionary = rec.get("participants", {}).get(peer, {})
	var uid := str(owned.get("uid", ""))
	var slot := str(intent.get("slot", ""))
	var move_id := str(owned.get("move_" + slot, ""))
	if rec.get("phase") != "active" or participant.is_empty() or uid.is_empty() \
		or binding.get("creature_uid") != uid or binding.get("character_id") != participant.get("character_id") \
		or int(binding.get("deployment_generation", 0)) < 1 or int(binding.get("body_instance_id", 0)) < 1 \
		or float(owned.get("hp", 0.0)) <= 0.0 or owned.get("fainted") == true \
		or slot not in ["quick", "charged", "utility", "ultimate"] \
		or move_id.is_empty() or not owned.get("known_moves", []).has(move_id) \
		or move.get("move_id") != move_id or move.get("slot") != slot \
		or typeof(intent.get("action")) != TYPE_INT or int(intent.action) <= 0 or now_ms < 0:
		return _refuse("move_start", peer, "invalid_actor_move", "That equipped move is unavailable.")
	if slot in ["utility", "ultimate"] and not (MATH.config().get("move_commit", {}).get("live_moves", []) as Array).has(move_id):
		return _refuse("move_start", peer, "move_not_mounted", "That move is not available in this build yet.")
	if slot == "ultimate" and not preload("res://scripts/vfx/ultimates/ultimate_library.gd").available(move_id):
		return _refuse("move_start", peer, "move_not_mounted", "That ultimate is not available in this build yet.")
	var authority: Dictionary = _strike_state_for(id).get(peer, {})
	var starts: Dictionary = authority.get("move_starts", {})
	if starts.size() >= int(MATH.config().get("utility_limits", {}).get("receipt_limit_per_encounter", 4096)):
		return _refuse("move_start", peer, "receipt_budget", "This encounter cannot accept another move safely.")
	var action := int(intent.action)
	if action <= maxi(int(authority.get("last_action", 0)), int(participant.get("wind_last_action", 0))):
		return _refuse("move_start", peer, "replayed_action", "That move was already handled.")
	if now_ms < int(authority.get("deadline_ms", 0)):
		return _refuse("move_start", peer, "recovering", "Your creature is still committed.")
	var resources: Dictionary = participant.get("move_resources", {})
	var actor: Dictionary = resources.get(uid, {"energy": 0.0, "ultimate_meter": 0.0, "cooldowns": {}}).duplicate(true)
	if resources.is_empty() and participant.has("wind"):
		for key: String in ["wind", "wind_updated_ms", "wind_ready_at_ms", "wind_last_action"]:
			if participant.has(key): actor[key] = participant[key]
	actor["tether_rally_until_ms"] = int(participant.get("tether_commands", {}).get("rally_until_ms", 0))
	_advance_participant_wind(actor, wind_profile, now_ms)
	if now_ms < int(actor.get("cooldowns", {}).get(slot, 0)):
		return _refuse("move_start", peer, "cooldown", "That move is still cooling down.")
	var wind_cost := maxf(0.0, float(move.get("wind_cost", 0.0)))
	var energy_cost := maxf(0.0, float(move.get("energy_cost", 0.0)))
	if float(actor.energy) + 0.001 < energy_cost:
		return _refuse("move_start", peer, "insufficient_energy", "Land quick hits to build Energy.")
	var exhausted := float(actor.wind) + 0.001 < wind_cost
	if exhausted and slot not in ["quick", "charged"]:
		return _refuse("move_start", peer, "insufficient_wind", "Your creature needs more Wind.")
	var maximum := float(MATH.config().get("ultimate", {}).get("maximum", 100.0))
	if slot == "ultimate" and float(actor.ultimate_meter) < maximum:
		return _refuse("move_start", peer, "ultimate_not_ready", "Build the Ultimate meter with landed hits.")
	var frozen := move.duplicate(true)
	if exhausted:
		frozen.windup = float(frozen.get("windup", 0.18)) * float(MATH.config().get("wind", {}).get("exhausted_windup_scale", 2.0))
		frozen.power = float(frozen.get("power", 9.0)) * float(MATH.config().get("wind", {}).get("exhausted_power_scale", 0.6))
	frozen["wind_exhausted"] = exhausted
	var windup_ms := ceili(float(frozen.get("windup", 0.18)) * 1000.0)
	var recover_ms := ceili(float(frozen.get("recovery", 0.22)) * 1000.0)
	var ready_at := now_ms + windup_ms + recover_ms
	actor.wind = maxf(0.0, float(actor.wind) - wind_cost)
	actor.energy = maxf(0.0, float(actor.energy) - energy_cost)
	if slot == "ultimate": actor.ultimate_meter = 0.0
	actor.wind_last_action = action
	actor.wind_ready_at_ms = ready_at + ceili(float(MATH.config().get("wind", {}).get("regen_delay", 0.6)) * 1000.0)
	actor.cooldowns[slot] = now_ms + ceili(float(frozen.get("cooldown", 0.0)) * 1000.0)
	resources[uid] = actor
	participant["move_resources"] = resources
	participant["move_resource_uid"] = uid
	participant["wind_last_action"] = action
	var action_identity := str(frozen.get("action_id", ""))
	if action_identity.is_empty():
		action_identity = preload("res://scripts/creatures/move_mastery.gd").new_action_identity("%s:%s:%d" % [id, uid, action])
	var started := {"action": action, "creature_uid": uid, "binding": binding.duplicate(true),
		"move_id": move_id, "slot": slot, "move": frozen, "started_at_ms": now_ms,
		"strike_at_ms": now_ms + windup_ms, "ready_at_ms": ready_at,
		"resolved": false, "credited": false,
		"mastery_uses": int(owned.get("move_mastery_uses", {}).get(move_id, 0)),
		"action_id": action_identity}
	# Preserve immutable accepted-action history owned by AcceptedActionHost.
	authority["last_action"] = action
	authority["accepted_at_ms"] = now_ms
	authority["deadline_ms"] = ready_at
	authority["cooldown_ms"] = windup_ms + recover_ms
	authority["move_start"] = started
	starts[str(action)] = started
	authority["move_starts"] = starts
	_strike_state_for(id)[peer] = authority
	seq += 1
	rec.seq = seq
	var delta := move_resource_snapshot(id, peer, uid)
	delta.merge({"encounter_id": id, "accepted_action": action, "creature_uid": uid,
		"move": frozen.duplicate(true), "slot": slot, "wind_exhausted": exhausted}, true)
	return _ok("move_start", peer, delta)


func move_commit(id: String, peer: int, action: int = 0) -> Dictionary:
	var authority: Dictionary = (_strike_authority.get(id, {}) as Dictionary).get(peer, {})
	var started: Dictionary = authority.get("move_start", {}) if action == 0 else authority.get("move_starts", {}).get(str(action), {})
	return started.duplicate(true)


func move_resource_snapshot(id: String, peer: int, uid: String) -> Dictionary:
	var participant: Dictionary = encounters.get(id, {}).get("participants", {}).get(peer, {})
	var actor: Dictionary = participant.get("move_resources", {}).get(uid, {})
	if actor.is_empty(): return {}
	return {"creature_uid": uid, "energy": float(actor.energy), "ultimate_meter": float(actor.ultimate_meter),
		"utility_cooldown_s": maxf(0.0, float(int(actor.get("cooldowns", {}).get("utility", 0)) - Time.get_ticks_msec()) / 1000.0),
		"wind": float(actor.get("wind", 0.0)), "wind_max": float(actor.get("wind_max", 100.0)),
		"wind_ready_at_ms": int(actor.get("wind_ready_at_ms", 0))}


func cancel_move_start(id: String, peer: int) -> void:
	var started: Dictionary = (_strike_authority.get(id, {}) as Dictionary).get(peer, {}).get("move_start", {})
	if started.is_empty(): return
	started["cancelled"] = true
	started["resolved"] = true


## Called only after the existing host damage writer committed a positive
## actual HP debit. One retained action can credit these encounter meters once.
func credit_move_hit(id: String, peer: int, action: int, actual_hp_debit: float,
		target_uid: String = "", target_hp_before: float = 0.0, target_generation: int = 0,
		source_hp: float = 0.0) -> Dictionary:
	var started: Dictionary = (_strike_authority.get(id, {}) as Dictionary).get(peer, {}).get("move_starts", {}).get(str(action), {})
	if started.get("action") != action or started.get("resolved") != true or started.get("credited") == true \
		or not is_finite(actual_hp_debit) or actual_hp_debit <= 0.0: return {}
	var participant: Dictionary = encounters.get(id, {}).get("participants", {}).get(peer, {})
	var actor: Dictionary = participant.get("move_resources", {}).get(started.creature_uid, {})
	if actor.is_empty(): return {}
	if TETHER_COMMANDS.enabled() and participant.get("tether_commands") is Dictionary:
		var binding: Dictionary = started.move.get("actor_binding", {})
		var command_actor := {"character_id": participant.character_id, "encounter_id": id,
			"creature_uid": started.creature_uid, "generation": int(started.binding.deployment_generation), "hp": source_hp}
		var receipt := {"action_id": started.action_id, "attacker_uid": started.creature_uid,
			"generation": int(started.binding.deployment_generation), "landed": true,
			"command_meter_credited": started.get("command_meter_credited", false)}
		if not binding.is_empty():
			var command := TETHER_COMMANDS.stage_landed(participant.tether_commands, command_actor,
				started.move, receipt, actual_hp_debit, target_uid, target_generation, Time.get_ticks_msec())
			if command.get("ok") == true:
				participant.tether_commands = command.state
				started["command_meter_credited"] = command.receipt.command_meter_credited
	var energy: Dictionary = MATH.config().get("energy", {})
	var ultimate: Dictionary = MATH.config().get("ultimate", {})
	if started.slot == "quick": actor.energy = minf(float(energy.get("max", 100.0)), float(actor.energy) + float(started.move.get("energy_gain", energy.get("gain_per_quick", 26.0))))
	actor.ultimate_meter = minf(float(ultimate.get("maximum", 100.0)), float(actor.ultimate_meter)
		+ float(ultimate.get("landed_gain", {}).get(started.slot, 0.0)) * _gear_gain(started.move))
	started.credited = true
	if int(started.get("mastery_uses", 300)) < 300 and not target_uid.is_empty() \
		and target_uid != started.creature_uid and is_finite(target_hp_before) and target_hp_before >= actual_hp_debit:
		started["mastery_pending"] = true
		started["mastery_outcome"] = {"action_id": str(started.action_id), "move_id": str(started.move_id),
			"attacker_uid": str(started.creature_uid), "target_uid": target_uid,
			"target_hp_before": target_hp_before, "applied_damage": actual_hp_debit}
	seq += 1
	encounters[id].seq = seq
	return move_resource_snapshot(id, peer, str(started.creature_uid))


## F33: the Charm's ultimate gain, frozen into the accepted action on the
## host, bounded by gear.json limits (never above the cap, never below one).
static func _gear_gain(move: Variant) -> float:
	var raw: Variant = move.get("gear_ultimate_gain_multiplier", 1.0) if move is Dictionary else 1.0
	var cap: Variant = preload("res://scripts/creatures/creature_gear.gd").config().get("limits", {}).get("ultimate_gain_multiplier_cap", 1.0)
	if not (raw is int or raw is float) or not is_finite(float(raw)) or not (cap is int or cap is float): return 1.0
	return clampf(float(raw), 1.0, maxf(1.0, float(cap)))


func move_mastery_outcome(id: String, peer: Variant, action: int) -> Dictionary:
	var started: Dictionary = (_strike_authority.get(id, {}) as Dictionary).get(peer, {}).get("move_starts", {}).get(str(action), {})
	if started.get("mastery_pending") != true or not started.get("mastery_outcome") is Dictionary: return {}
	return {"encounter_id": id, "peer": peer, "action": action,
		"binding": started.binding.duplicate(true), "outcome": started.mastery_outcome.duplicate(true),
		"context": started.move.get("mastery_context", {}).duplicate(true)}


## The director calls this after the live utility consumer committed its
## original effect. Status casts earn mastery without inventing an HP debit.
func self_utility_power(id: String, uid: String, now_ms: int) -> float:
	return UTILITY_EFFECTS.power_multiplier(encounters.get(id, {}).get("utility_state", {}), uid, now_ms)


## A self status utility (Hearten) the host accepted at move start: stage its
## status on this encounter's utility state. No HP, meter or mastery here.
func apply_self_status_utility(id: String, uid: String, move_id: String, move: Dictionary,
		source_position: Vector3, source_hp: float, source_max_hp: float, action_id: String, now_ms: int) -> bool:
	var rec: Dictionary = encounters.get(id, {})
	if rec.is_empty() or str(move.get("utility", {}).get("scope", "")) != "self" \
		or str(move.get("utility", {}).get("kind", "")) not in ["next_hit_buff", "movement_buff"]: return false
	var state: Dictionary = rec.get("utility_state", UTILITY_EFFECTS.empty_state(id, 0))
	var staged := UTILITY_EFFECTS.stage_application(state, move_id, move, {"encounter_id": id, "generation": 0,
		"action_id": action_id, "source_uid": uid, "target_uid": uid, "source_position": source_position,
		"target_position": source_position, "source_hp": source_hp, "source_max_hp": source_max_hp,
		"hostile": false, "geometry_connected": true}, now_ms,
		int(MATH.config().get("utility_limits", {}).get("receipt_limit_per_encounter", 4096)))
	if staged.get("ok") != true: return false
	rec["utility_state"] = staged.state
	return true


## Hearten is spent by the first hit that actually debits HP.
func consume_next_hit(id: String, uid: String, now_ms: int) -> void:
	var rec: Dictionary = encounters.get(id, {})
	if rec.is_empty() or not rec.get("utility_state") is Dictionary: return
	var staged := UTILITY_EFFECTS.stage_consume_next_hit(rec.utility_state, uid, now_ms)
	if staged.get("ok") == true: rec["utility_state"] = staged.state


## Tier is frozen once on the existing admitted participant, from host gear.
func bind_tether_commands(id: String, peer: int, admitted: Dictionary) -> void:
	if not TETHER_COMMANDS.enabled(): return
	var participant: Dictionary = encounters.get(id, {}).get("participants", {}).get(peer, {})
	if participant.is_empty() or participant.has("tether_commands") \
		or admitted.get("character_id") != participant.get("character_id"): return
	var equipment := preload("res://scripts/player/player_equipment.gd").new()
	equipment.configure(preload("res://autoload/item_db.gd").new())
	equipment.load_data(admitted.get("equipment", {}))
	var state := TETHER_COMMANDS.admission(str(participant.character_id), id, equipment.command_pouch_tier())
	if state.is_empty(): return
	participant["tether_commands"] = state
	seq += 1
	encounters[id].seq = seq


## A presentation count from the same first non-empty saved pouch slot used by
## Item staging. Current owner inventory is read; the admitted gear tier stays
## frozen. This neither chooses a packet item nor spends a stack.
func tether_pouch_view(id: String, peer: int, admitted: Dictionary) -> Dictionary:
	var unavailable := {"pouch_count": 0, "item_consumer_ready": false}
	var participant: Dictionary = encounters.get(id, {}).get("participants", {}).get(peer, {})
	var commands: Dictionary = participant.get("tether_commands", {})
	if not TETHER_COMMANDS.enabled() or commands.is_empty() \
		or admitted.get("character_id") != participant.get("character_id") \
		or not ACTOR_AUTHORITY.errors(admitted, str(participant.get("character_id", ""))).is_empty(): return unavailable
	var rules := preload("res://scripts/world/death_satchel_rules.gd")
	var inventory: RefCounted = rules.inventory_from(admitted.inventory)
	var counts := {}
	for stack: Variant in admitted.inventory:
		if stack is Dictionary: counts[stack.id] = inventory.call("count", str(stack.id))
	var item := TETHER_COMMANDS.first_pouch_item(admitted.redesign_character.get("tether_pouch", []),
		rules.db().get("_items"), counts, int(commands.tier))
	return {"pouch_count": int(counts.get(item, 0)), "item_consumer_ready": not item.is_empty()}


func tether_rally(id: String, peer: int, now_ms: int) -> Dictionary:
	var participant: Dictionary = encounters.get(id, {}).get("participants", {}).get(peer, {})
	return TETHER_COMMANDS.rally_modifiers(participant.get("tether_commands", {}), str(participant.get("character_id", "")), now_ms)


## Host actor/geometry view only. No packet-owned gear, HP, inventory or UID.
## Item and joint switch stay unavailable until their atomic adapters exist.
func commit_tether_command(request: Dictionary, peer: int, view: Dictionary, now_ms: int) -> Dictionary:
	if not TETHER_COMMANDS.valid_intent(request): return _refuse("tether_command", peer, "invalid_request", "That command is unavailable.")
	var id: String = request.encounter_id
	if not pending_tether_items(id).is_empty(): return _refuse("tether_command", peer, "item_save_pending", "The original item is still being saved.")
	var rec: Dictionary = encounters.get(id, {})
	var participant: Dictionary = rec.get("participants", {}).get(peer, {})
	if rec.get("phase") != "active" or participant.is_empty() or not participant.get("tether_commands") is Dictionary:
		return _refuse("tether_command", peer, "stale_actor", "That encounter is unavailable.")
	var actor: Dictionary = view.get("actor", {})
	# The director already authenticated the current body/UID/generation.
	# move_resource_uid identifies the last spent pool, including after switch.
	if actor.get("character_id") != participant.character_id or actor.get("encounter_id") != id:
		return _refuse("tether_command", peer, "stale_actor", "That creature is unavailable.")
	var host := view.duplicate(true)
	host.merge({"peer_id": peer, "owner_admitted": true, "encounter_active": true,
		"unlocked_commands": ["rally", "snare"],
		"accepted_receipt": {"action_id": "command:%s:%s:%d:%d" % [id, participant.character_id, int(request.generation), int(request.sequence)],
			"character_id": participant.character_id, "encounter_id": id, "attacker_uid": actor.creature_uid,
			"generation": actor.generation, "sequence": request.sequence, "command_id": request.command_id, "command_committed": false}}, true)
	host["target_snare"] = rec.get("opponent", {}).get("tether_snare", {})
	host["admitted_character_ids"] = []
	for row: Dictionary in rec.participants.values(): host.admitted_character_ids.append(row.character_id)
	var plan := TETHER_COMMANDS.stage_command(participant.tether_commands, request, host, now_ms)
	if plan.get("ok") != true: return _refuse("tether_command", peer, str(plan.get("code", "invalid_request")), str(plan.get("reason", "Command unavailable.")))
	if plan.effect.kind == "rally":
		for pool: Dictionary in participant.get("move_resources", {}).values():
			_advance_participant_wind(pool, {"max": pool.get("wind_max", 100.0), "regen_per_second": pool.get("wind_regen_per_second", 18.0)}, now_ms)
			pool["tether_rally_until_ms"] = plan.effect.until_ms
	elif plan.effect.kind == "snare":
		rec.opponent["tether_snare"] = plan.effect.status
	else: return _refuse("tether_command", peer, "transaction_unavailable", "That command is unavailable.")
	participant["tether_commands"] = plan.state
	participant.tether_commands["last_receipt"] = plan.receipt
	seq += 1
	rec.seq = seq
	return {"ok": true, "kind": "tether_command", "peer": peer, "code": "accepted", "reason": "", "pending": false,
		"delta": {"tether_commands": plan.state.duplicate(true), "effect": plan.effect.duplicate(true)}}


## Freeze the real host command before its single full-character decision.
## Only a current bound actor and settled admitted health may reserve it.
## This spends neither inventory nor meter and never changes HP or a body.
func prepare_tether_item_command(request: Dictionary, peer: int, admitted: Dictionary,
		binding: Dictionary, revision: int, world_namespace: String, epoch: String, now_ms: int) -> Dictionary:
	if not TETHER_COMMANDS.enabled() or not TETHER_COMMANDS.valid_intent(request) or request.command_id != "item_throw" \
		or revision < 0 or revision >= 2147483647 or not UTILITY_EFFECTS._identity(world_namespace) \
		or not UTILITY_EFFECTS._identity(epoch) or not has_method("_binding_current"):
		return {"ok": false, "code": "item_unavailable"}
	var id: String = request.encounter_id
	var rec: Dictionary = encounters.get(id, {})
	var participant: Dictionary = rec.get("participants", {}).get(peer, {})
	if participant.is_empty() or rec.get("phase") != "active" or not participant.get("tether_commands") is Dictionary \
		or admitted.get("character_id") != participant.get("character_id") \
		or not ACTOR_AUTHORITY.errors(admitted, str(participant.character_id)).is_empty() \
		or binding.get("deployment_generation") != request.generation \
		or call("_binding_current", id, peer, binding) != true: return {"ok": false, "code": "stale_actor"}
	var existing: Dictionary = participant.tether_commands.get("item_pending", {})
	if not existing.is_empty():
		if existing.intent.request != request or existing.binding != binding \
			or existing.context.world_namespace != world_namespace or existing.context.session_id != epoch:
			return {"ok": false, "code": "item_original_pending"}
		return {"ok": true, "original": existing}
	if not pending_tether_items(id).is_empty() or not pending_actor_vitals(id).is_empty() \
		or call("move_action_publication_pending", id) == true: return {"ok": false, "code": "item_baseline_pending"}
	for state: Dictionary in _strike_authority.get(id, {}).values():
		for started: Dictionary in state.get("move_starts", {}).values():
			if started.get("resolved") != true and started.get("cancelled") != true:
				return {"ok": false, "code": "item_baseline_pending"}
	var uid: String = binding.creature_uid
	var vitals: Dictionary = participant.get("actor_vitals", {}).get(uid, {})
	var owned: Dictionary = {}
	for card: Dictionary in admitted.party:
		if card.uid == uid: owned = card
	if owned.is_empty() or int(vitals.get("revision", -1)) != int(vitals.get("settled_revision", -2)) \
		or not ACTOR_AUTHORITY.equivalent(vitals.get("hp"), owned.hp) \
		or not ACTOR_AUTHORITY.equivalent(vitals.get("max_hp"), owned.max_hp) or vitals.get("fainted") != owned.fainted:
		return {"ok": false, "code": "item_baseline_pending"}
	var actor := {"character_id": participant.character_id, "creature_uid": uid, "encounter_id": id,
		"generation": request.generation, "body_generation": vitals.body_generation,
		"body_instance_id": vitals.body_instance_id, "vitals_revision": vitals.revision,
		"hp": vitals.hp, "max_hp": vitals.max_hp}
	var receipt := {"action_id": "command:%s:%s:%d:%d" % [id, participant.character_id, int(request.generation), int(request.sequence)],
		"character_id": participant.character_id, "encounter_id": id, "attacker_uid": uid,
		"generation": request.generation, "sequence": request.sequence, "command_id": "item_throw", "command_committed": false}
	var inventory := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(admitted.inventory)
	var counts := {}
	for stack: Variant in admitted.inventory:
		if stack is Dictionary: counts[stack.id] = inventory.call("count", str(stack.id))
	var items: RefCounted = preload("res://scripts/world/death_satchel_rules.gd").db()
	var plan := TETHER_COMMANDS.stage_command(participant.tether_commands, request,
		{"actor": actor, "peer_id": peer, "owner_admitted": true, "encounter_active": true,
			"unlocked_commands": ["item_throw"], "accepted_receipt": receipt,
			"pouch": admitted.redesign_character.get("tether_pouch", []), "items": items.get("_items"),
			"inventory_counts": counts, "item_transaction_ready": true, "item_can_apply": true}, now_ms)
	if plan.get("ok") != true: return plan
	var candidate := TETHER_COMMANDS.stage_item_use(admitted, plan.effect,
		{"actor": actor, "owner_admitted": true, "encounter_active": true})
	if candidate.get("ok") != true: return candidate
	var context := {"character_id": participant.character_id, "expected_revision": revision,
		"source_key": "tether_item:" + str(receipt.action_id), "in_range": true, "in_combat": true,
		"foundation_runtime_authorized": true, "item_runtime_authorized": true,
		"world_namespace": world_namespace, "session_id": epoch, "item_actor": actor}
	var original := {"encounter_id": id, "peer_id": peer, "character_id": participant.character_id,
		"intent": {"request": request.duplicate(true), "effect": plan.effect.duplicate(true)}, "context": context,
		"command_before": participant.tether_commands.duplicate(true), "command_plan": plan.duplicate(true),
		"binding": binding.duplicate(true), "actor_committed": false, "presented": false}
	var originals: GDScript = load("res://scripts/combat/accepted_action_host.gd")
	for field: String in ["intent", "context", "command_before", "command_plan", "binding"]:
		original[field] = originals._original(original[field])
	participant.tether_commands["item_pending"] = original
	return {"ok": true, "original": original}


## At most one original per participant. Departed originals remain on the
## same retained participant and also fence round teardown and replacement.
func pending_tether_items(id: String) -> Array[Dictionary]:
	var rec: Dictionary = encounters.get(id, {})
	var rows: Array = rec.get("participants", {}).values()
	rows.append_array(rec.get("retained_actor_participants", {}).values())
	var pending: Array[Dictionary] = []
	for participant: Dictionary in rows:
		var original: Dictionary = participant.get("tether_commands", {}).get("item_pending", {})
		if not original.is_empty() and original.get("presented") != true: pending.append(original)
	return pending


## Release only a saved original after its canonical actor commit. Retain one
## correlated result in the same command state to repair a lost owner reply.
func finalize_saved_tether_item(original: Dictionary, training: Dictionary, deliveries: Dictionary,
		world_namespace: String, world_id: String) -> Dictionary:
	if original.get("actor_committed") != true or original.get("presented") == true \
		or training.get("action") != "tether_item" or training.get("status") != "accepted" \
		or not TRAINING_WORLD.training_row_valid(training, world_namespace, world_id) \
		or not ACTOR_AUTHORITY.equivalent(deliveries.get(training.get("delivery_id")), training) \
		or not ACTOR_AUTHORITY.equivalent(original.get("intent"), training.get("intent")) \
		or not ACTOR_AUTHORITY.equivalent(original.get("context"), training.get("host_context")):
		return {"ok": false, "code": "item_decision_unavailable"}
	# A tonic stays private until Session has installed this SAME saved original
	# into the admitted timed consumer, before releasing its debit/meter receipt.
	var items: RefCounted = preload("res://scripts/world/death_satchel_rules.gd").db()
	if items.call("definition", str(original.intent.effect.item_id)).has("creature_buff") \
		and original.get("tonic_receipt") != training.receipt:
		return {"ok": false, "code": "item_buff_consumer_unavailable"}
	var rec: Dictionary = encounters.get(original.encounter_id, {})
	var rows: Array = rec.get("participants", {}).values()
	rows.append_array(rec.get("retained_actor_participants", {}).values())
	for participant: Dictionary in rows:
		if not is_same(participant.get("tether_commands", {}).get("item_pending"), original): continue
		var uid: String = original.intent.effect.creature_uid
		var actor: Dictionary = participant.get("actor_vitals", {}).get(uid, {})
		if actor.get("training_receipt") != training.receipt \
			or actor.get("training_character_revision") != training.character_revision \
			or participant.tether_commands.get("last_receipt") != original.command_plan.receipt:
			return {"ok": false, "code": "item_commit_changed"}
		var result := {"request": original.intent.request.duplicate(true), "receipt": training.receipt,
			"character_id": training.character_id, "creature_uid": uid, "saved": true}
		participant.tether_commands["item_result"] = result
		participant.tether_commands.erase("item_pending")
		original["presented"] = true
		seq += 1
		rec.seq = seq
		return {"ok": true, "result": result.duplicate(true)}
	return {"ok": false, "code": "item_original_unavailable"}

func settle_tether_tonic_wind(character: String, uid: String, now_ms: int, profile: Dictionary = {}) -> void:
	for rec: Dictionary in encounters.values():
		var rows: Array = rec.get("participants", {}).values()
		rows.append_array(rec.get("retained_actor_participants", {}).values())
		for participant: Dictionary in rows:
			if participant.get("character_id") != character: continue
			var pool: Dictionary = participant.get("move_resources", {}).get(uid, {})
			if pool.is_empty(): continue
			var next := profile if not profile.is_empty() else {"max": pool.get("wind_max", 100.0),
				"regen_per_second": pool.get("wind_regen_per_second", 18.0)}
			_advance_participant_wind(pool, next, now_ms)


## An untouched reservation may be cancelled only before a durable decision.
func cancel_unjournaled_tether_item(original: Dictionary, deliveries: Dictionary,
		world_namespace: String) -> bool:
	if original.get("actor_committed") == true or original.get("presented") == true \
		or original.get("context", {}).get("world_namespace") != world_namespace: return false
	var character: String = str(original.get("character_id", ""))
	var row: Variant = deliveries.get(preload("res://scripts/creatures/essence.gd").training_delivery_id(world_namespace, character))
	if row is Dictionary and row.get("action") == "tether_item" \
		and row.get("intent", {}).get("request") == original.get("intent", {}).get("request"): return false
	var rec: Dictionary = encounters.get(original.get("encounter_id"), {})
	var rows: Array = rec.get("participants", {}).values()
	rows.append_array(rec.get("retained_actor_participants", {}).values())
	for participant: Dictionary in rows:
		if not is_same(participant.get("tether_commands", {}).get("item_pending"), original): continue
		var commands: Dictionary = participant.tether_commands.duplicate(true)
		commands.erase("item_pending")
		if not ACTOR_AUTHORITY.equivalent(commands, original.command_before): return false
		participant.tether_commands.erase("item_pending")
		original["cancelled"] = true
		original["presented"] = true
		return true
	return false


func acknowledge_move_mastery(id: String, peer: Variant, action: int, action_id: String) -> bool:
	var started: Dictionary = (_strike_authority.get(id, {}) as Dictionary).get(peer, {}).get("move_starts", {}).get(str(action), {})
	if started.get("action_id") != action_id or started.get("mastery_pending") != true: return false
	started["mastery_pending"] = false
	return true


func pending_move_mastery() -> Array[Dictionary]:
	var pending: Array[Dictionary] = []
	for id: String in _strike_authority:
		for key: Variant in _strike_authority[id]:
			# A departed participant retains the SAME obligation under stable
			# character. The host world writer does not require that peer online.
			for started: Dictionary in _strike_authority[id][key].get("move_starts", {}).values():
				if started.get("mastery_pending") == true:
					pending.append({"encounter_id": id, "peer": key, "action": int(started.action)})
	return pending


## COMBAT-3. Authorize and spend one movement burst as a single host operation.
## It shares the strike action sequence and deadline: a burst cannot cancel an
## accepted attack, and an attack cannot begin until the burst's 0.2s commit is
## over. The direction is the only client-authored geometry and is normalized;
## distance/duration/cost/profile are all host inputs.
func authorize_burst(encounter_id: String, peer_id: int, intent: Dictionary,
		profile: Dictionary, cost: float, now_ms: int, distance: float,
		duration: float, regen_delay_seconds: float) -> Dictionary:
	if not pending_tether_items(encounter_id).is_empty(): return _refuse("burst_intent", peer_id, "item_save_pending", "The original item is still being saved.")
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return _refuse("burst_intent", peer_id, "unknown_encounter", "That fight is over.")
	var participants: Dictionary = rec.get("participants", {}) as Dictionary
	if not participants.has(peer_id):
		return _refuse("burst_intent", peer_id, "not_participant",
			"You are not in that fight.")
	if str(rec.get("phase", "")) != "active":
		return _refuse("burst_intent", peer_id, "wrong_phase",
			"That fight is not taking movement right now.")
	if not intent.has("action") or typeof(intent["action"]) != TYPE_INT \
			or int(intent["action"]) <= 0:
		return _refuse("burst_intent", peer_id, "malformed",
			"That burst did not carry a valid action id.")
	var raw_direction: Variant = intent.get("direction", null)
	if not raw_direction is Array or raw_direction.size() < 3:
		return _refuse("burst_intent", peer_id, "malformed",
			"That burst did not say which way it moved.")
	for component: Variant in raw_direction.slice(0, 3):
		if not component is float and not component is int:
			return _refuse("burst_intent", peer_id, "malformed",
				"That burst carried an invalid direction.")
		if not is_finite(float(component)):
			return _refuse("burst_intent", peer_id, "malformed",
				"That burst carried an invalid direction.")
	var direction := Vector3(float(raw_direction[0]), 0.0, float(raw_direction[2]))
	if direction.length_squared() <= 0.000001:
		return _refuse("burst_intent", peer_id, "malformed",
			"Choose a direction before bursting.")
	direction = direction.normalized()
	var action := int(intent["action"])
	var authority := strike_authority_state(encounter_id, peer_id)
	var row: Dictionary = participants[peer_id]
	var last_action := maxi(int(authority.get("last_action", 0)),
		int(row.get("wind_last_action", 0)))
	var wind_preview := preview_wind(encounter_id, peer_id, profile, cost, now_ms)
	if action <= last_action:
		var replay := _refuse("burst_intent", peer_id, "replayed_action",
			"That burst was already handled.")
		(replay.get("delta", {}) as Dictionary).merge(wind_preview, true)
		return replay
	if now_ms < int(authority.get("deadline_ms", 0)):
		var cooling := _refuse("burst_intent", peer_id, "cooldown",
			"Your creature is still committed to its current action.")
		(cooling.get("delta", {}) as Dictionary).merge(wind_preview, true)
		return cooling
	if bool(wind_preview.get("wind_exhausted", true)):
		var tired := _refuse("burst_intent", peer_id, "insufficient_wind",
			"Your creature needs more Wind to burst.")
		(tired.get("delta", {}) as Dictionary).merge(wind_preview, true)
		return tired
	var safe_duration := maxf(0.01, duration)
	var wind_delta := commit_wind(encounter_id, peer_id, action, profile, cost,
		now_ms, safe_duration, regen_delay_seconds)
	var deadline_ms := now_ms + ceili(safe_duration * 1000.0)
	var starts: Dictionary = _strike_state_for(encounter_id).get(peer_id, {}).get("move_starts", {})
	_strike_state_for(encounter_id)[peer_id] = {
		"last_action": action, "accepted_at_ms": now_ms,
		"deadline_ms": deadline_ms, "cooldown_ms": ceili(safe_duration * 1000.0),
		"move_starts": starts,
	}
	var delta := {
		"encounter_id": encounter_id,
		"accepted_action": action,
		"accepted_at_ms": now_ms,
		"cooldown_deadline_ms": deadline_ms,
		"direction": [direction.x, 0.0, direction.z],
		"distance": maxf(0.0, distance),
		"duration": safe_duration,
	}
	delta.merge(wind_delta, true)
	return _ok("burst_intent", peer_id, delta)


## Read-only host evidence for the existing network probe. The returned value
## is detached so a fixture or probe cannot mutate the arbiter's latest row.
func latest_strike_receipt(encounter_id: String, peer_id: int) -> Dictionary:
	var by_peer: Dictionary = _strike_receipts.get(encounter_id, {}) as Dictionary
	var receipt: Dictionary = by_peer.get(peer_id, {}) as Dictionary
	if str(receipt.get("encounter_id", "")) != encounter_id:
		return {}
	return receipt.duplicate(true)


## COMBAT-2. The live Wind pool is authority state on the participant row so
## the same record broadcast that carries shared HP also gives every observer
## an absolute, ordered resource value. The deployment card supplies a
## snapshot profile; the host clock and accepted action ids exclusively own
## regeneration and spending from here on.
func preview_wind(encounter_id: String, peer_id: int, profile: Dictionary,
		cost: float, now_ms: int) -> Dictionary:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return {}
	var participants: Dictionary = rec.get("participants", {}) as Dictionary
	if not participants.has(peer_id):
		return {}
	var row := _participant_wind_row(participants[peer_id], str(profile.get("creature_uid", "")))
	_advance_participant_wind(row, profile, now_ms)
	var available := float(row.get("wind", 0.0))
	return {"wind": available, "wind_max": float(row.get("wind_max", 1.0)),
		"wind_exhausted": available + 0.001 < maxf(0.0, cost)}


## Commit exactly one accepted action. Repeating an action id returns the
## already-authoritative value and cannot drain twice. Recovery plus the quiet
## delay define the first host-clock instant at which regeneration may resume.
func commit_wind(encounter_id: String, peer_id: int, action: int,
		profile: Dictionary, cost: float, now_ms: int, recovery_seconds: float,
		regen_delay_seconds: float) -> Dictionary:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return {}
	var participants: Dictionary = rec.get("participants", {}) as Dictionary
	if not participants.has(peer_id):
		return {}
	var participant: Dictionary = participants[peer_id]
	var row := _participant_wind_row(participant, str(profile.get("creature_uid", "")), true)
	_advance_participant_wind(row, profile, now_ms)
	if action <= int(row.get("wind_last_action", 0)):
		return {"wind": float(row.get("wind", 0.0)),
			"wind_max": float(row.get("wind_max", 1.0)), "wind_duplicate": true}
	var available := float(row.get("wind", 0.0))
	var exhausted := available + 0.001 < maxf(0.0, cost)
	row["wind"] = maxf(0.0, available - maxf(0.0, cost))
	row["wind_last_action"] = action
	participant["wind_last_action"] = action
	row["wind_updated_ms"] = now_ms
	row["wind_ready_at_ms"] = now_ms + ceili(1000.0 * (maxf(0.0, recovery_seconds)
		+ maxf(0.0, regen_delay_seconds)))
	seq += 1
	rec["seq"] = seq
	return {"wind": float(row["wind"]), "wind_max": float(row["wind_max"]),
		"wind_exhausted": exhausted, "wind_ready_at_ms": int(row["wind_ready_at_ms"])}


func _participant_wind_row(participant: Dictionary, active_uid: String = "", install: bool = false) -> Dictionary:
	var uid := active_uid if not active_uid.is_empty() else str(participant.get("move_resource_uid", ""))
	if uid.is_empty(): return participant
	var resources: Dictionary = participant.get("move_resources", {})
	var row: Dictionary = resources.get(uid, {})
	if row.is_empty():
		row = {"energy": 0.0, "ultimate_meter": 0.0, "cooldowns": {}}
		if resources.is_empty() and participant.has("wind"):
			for key: String in ["wind", "wind_updated_ms", "wind_ready_at_ms", "wind_last_action"]:
				if participant.has(key): row[key] = participant[key]
	if install:
		row["tether_rally_until_ms"] = int(participant.get("tether_commands", {}).get("rally_until_ms", 0))
		resources[uid] = row
		participant["move_resources"] = resources
		participant["move_resource_uid"] = uid
	return row


func _advance_participant_wind(row: Dictionary, profile: Dictionary, now_ms: int) -> void:
	var maximum := maxf(1.0, float(profile.get("max", 100.0)))
	var regen := maxf(0.0, float(profile.get("regen_per_second", 18.0)))
	if not row.has("wind"):
		row["wind"] = maximum
		row["wind_updated_ms"] = now_ms
		row["wind_ready_at_ms"] = now_ms
		row["wind_last_action"] = 0
	# The supplied profile starts at this observation, not at the previous
	# update. Earn elapsed Wind under the stored rate/cap before changing it.
	var previous_maximum := maxf(1.0, float(row.get("wind_max", maximum)))
	var previous_regen := maxf(0.0, float(row.get("wind_regen_per_second", regen)))
	row["wind"] = clampf(float(row.get("wind", previous_maximum)), 0.0, previous_maximum)
	var updated := int(row.get("wind_updated_ms", now_ms))
	var ready := int(row.get("wind_ready_at_ms", now_ms))
	var regen_from := maxi(updated, ready)
	if now_ms > regen_from and float(row["wind"]) < previous_maximum:
		var boosted_ms := maxi(0, mini(now_ms, int(row.get("tether_rally_until_ms", 0))) - regen_from)
		var bonus := float(TETHER_COMMANDS.config().get("commands", {}).get("rally", {}).get("wind_regen_multiplier", 1.0)) - 1.0
		row["wind"] = minf(previous_maximum, float(row["wind"])
			+ previous_regen * (float(now_ms - regen_from) + float(boosted_ms) * bonus) / 1000.0)
	row["wind_updated_ms"] = maxi(updated, now_ms)
	row["wind_max"] = maximum
	row["wind_regen_per_second"] = regen
	row["wind"] = minf(float(row["wind"]), maximum)


## Preserve exactly one action-correlated observation per active participant.
## This runs after validation and only describes that result; acceptance,
## refusal, damage and target selection never read this diagnostic state.
## Geometry is evaluated only after production validation reached its actual
## arbitration branch. Early wrong-phase/replay/cooldown/malformed refusals must
## remain able to reject hostile value types without this observer converting
## fields that production never touched.
func _record_strike_receipt(intent: Dictionary, peer_id: int, view: Dictionary,
		rec: Dictionary, verdict: Dictionary, geometry_available: bool = false) -> Dictionary:
	if not intent.has("action") or typeof(intent["action"]) != TYPE_INT \
			or int(intent["action"]) <= 0:
		return verdict
	var encounter_id := str(intent.get("encounter_id", ""))
	if not _strike_receipts.has(encounter_id) \
			or not (rec.get("participants", {}) as Dictionary).has(peer_id):
		return verdict
	var delta: Dictionary = verdict.get("delta", {}) as Dictionary
	var ok := bool(verdict.get("ok", false))
	var hit := ok and bool(delta.get("hit", false))
	var outcome := "accepted" if hit else ("missed" if ok else "refused")
	var receipt := {
		"encounter_id": encounter_id,
		"peer_id": peer_id,
		"action": int(intent["action"]),
		"outcome": outcome,
		"ok": ok,
		"hit": hit,
		"code": str(verdict.get("code", "")),
		"reason": str(verdict.get("reason", "")),
		"delta": delta.duplicate(true),
		"geometry_available": geometry_available,
		"record_phase": str(rec.get("phase", "")),
		"record_seq": int(rec.get("seq", 0)),
		"authority": strike_authority_state(encounter_id, peer_id),
	}
	if geometry_available:
		var move: Dictionary = intent["move"] as Dictionary
		var host_origin := to_vec3(view.get("origin", []))
		var facing := to_vec3(intent.get("facing", []))
		var candidates: Array = []
		var opponent: Dictionary = rec.get("opponent", {}) as Dictionary
		var opponent_at := to_vec3(opponent.get("position", []))
		candidates.append({
			"owner_peer_id": 0,
			"role": "opponent",
			"position": _vec3_row(opponent_at),
			"distance": host_origin.distance_to(opponent_at),
			"connects": MATH.move_connects(move, host_origin, facing, opponent_at),
			"eligible": true,
		})
		var participants: Dictionary = rec.get("participants", {}) as Dictionary
		for raw: Variant in (view.get("bodies", []) as Array):
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var body: Dictionary = raw
			if not body.has("owner_peer_id") or not body.has("position"):
				continue
			var owner := int(body["owner_peer_id"])
			# Match `_friendly_body_struck`'s order: self and bodies owned by
			# nonparticipants are not arbitration candidates, so production never
			# converts their positions and neither may this observer.
			if owner == peer_id or not participants.has(owner):
				continue
			var at := to_vec3(body["position"])
			candidates.append({
				"owner_peer_id": owner,
				"role": str(body.get("role", "creature")),
				"position": _vec3_row(at),
				"distance": host_origin.distance_to(at),
				"connects": MATH.move_connects(move, host_origin, facing, at),
				"eligible": true,
			})
		receipt["host_now_ms"] = int(view.get("now_ms", 0))
		receipt["host_origin"] = _vec3_row(host_origin)
		receipt["facing"] = _vec3_row(facing)
		receipt["move"] = move.duplicate(true)
		receipt["candidates"] = candidates
	(_strike_receipts[encounter_id] as Dictionary)[peer_id] = receipt.duplicate(true)
	return verdict


static func _vec3_row(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


## The host lock covers the authored cooldown and, defensively, the whole move
## commitment. A malformed profile cannot become a zero-time attack stream.
static func move_lock_ms(move: Dictionary) -> int:
	var seconds := maxf(float(move.get("cooldown", 0.0)),
		float(move.get("windup", 0.1)) + float(move.get("recovery", 0.1)))
	return ceili(1000.0 * maxf(0.05, seconds))


## Read-only authority evidence for focused tests and the network harness.
## Missing state is explicit zeroes rather than the live Dictionary, so a
## caller cannot mutate the host ledger through a returned reference.
func strike_authority_state(encounter_id: String, peer_id: int) -> Dictionary:
	var by_peer: Dictionary = _strike_authority.get(encounter_id, {}) as Dictionary
	var state: Dictionary = by_peer.get(peer_id, {}) as Dictionary
	return {
		"last_action": int(state.get("last_action", 0)),
		"accepted_at_ms": int(state.get("accepted_at_ms", 0)),
		"deadline_ms": int(state.get("deadline_ms", 0)),
		"cooldown_ms": int(state.get("cooldown_ms", 0)),
	}


func _strike_state_for(encounter_id: String) -> Dictionary:
	if not _strike_authority.has(encounter_id):
		_strike_authority[encounter_id] = {}
	return _strike_authority[encounter_id] as Dictionary


## The closest body in the swing's cone that belongs to ANOTHER participant.
##
## "Resolved target" (§5) is the nearest thing the swing actually lands on, the
## same way a real hit would resolve, rather than "anything at all in the cone":
## a strike at the opponent with a teammate standing somewhere behind it is a
## legal strike, and refusing it would teach two players to fight from opposite
## sides of the field to stay out of each other's arcs.
##
## Ownership is read off the BODY (`owner_peer_id`, 4.B's H5), never off a node
## name and never off the payload. A body with `owner_peer_id` 0 belongs to
## nobody -- a wild creature -- and is not a friendly target.
func _friendly_body_struck(move: Dictionary, origin: Vector3, facing: Vector3,
		striker: int, rec: Dictionary, view: Dictionary) -> Dictionary:
	var participants: Dictionary = rec["participants"]
	var opponent := to_vec3((rec["opponent"] as Dictionary).get("position", []))
	var best: Dictionary = {}
	var best_distance := INF
	# The opponent is a candidate too, and it competes on distance: if the
	# opponent is nearer than the teammate, the swing resolved onto the
	# opponent and there is nothing friendly about it.
	if MATH.move_connects(move, origin, facing, opponent):
		best_distance = origin.distance_to(opponent)
	for raw: Variant in (view.get("bodies", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var body: Dictionary = raw
		if not body.has("owner_peer_id") or not body.has("position"):
			continue
		var owner := int(body["owner_peer_id"])
		if owner == striker:
			continue
		# The ONE guard that does the work, and deliberately the only one: a
		# body is friendly because its owner is IN THIS FIGHT, not because it
		# has an owner at all. An earlier draft also skipped `owner_peer_id`
		# 0 ("belongs to nobody") one line above; breaking that line left every
		# assertion in
		# `tests/test_encounter_host_rejects_friendly_strike.gd` green, because
		# peer id 0 is never a participant and this check had already caught
		# it. A line no test can turn red is a line that is not enforcing
		# anything, so it is gone rather than left to read as protection.
		if not participants.has(owner):
			# Somebody else's creature standing in the meadow, not in this
			# fight. Out of scope for the refusal: this rule is about the
			# people you are fighting BESIDE.
			continue
		var at := to_vec3(body["position"])
		if not MATH.move_connects(move, origin, facing, at):
			continue
		var distance := origin.distance_to(at)
		if distance < best_distance:
			best_distance = distance
			best = {"owner_peer_id": owner, "distance": distance,
				"role": str(body.get("role", "creature"))}
	return best


## §5 step 3. The connect test, run against the host's own opponent position,
## then -- only when the retro window applies -- against each sample the host
## took inside `strike_latency_tolerance_ms`.
func _connects_now_or_recently(move: Dictionary, origin: Vector3, facing: Vector3,
		rec: Dictionary, intent: Dictionary, now_ms: int) -> Dictionary:
	var opponent: Dictionary = rec["opponent"]
	var here := to_vec3(opponent.get("position", []))
	if MATH.move_connects(move, origin, facing, here):
		return {"hit": true, "at_ms": now_ms}
	if not _retro_window_applies(move, origin, intent):
		return {"hit": false, "at_ms": now_ms}
	var cutoff := now_ms - strike_latency_tolerance_ms()
	for raw: Variant in (opponent.get("samples", []) as Array):
		var sample: Array = raw as Array
		if sample == null or sample.size() != 4:
			continue
		var t := int(sample[0])
		if t < cutoff:
			continue
		var was := Vector3(float(sample[1]), float(sample[2]), float(sample[3]))
		if MATH.move_connects(move, origin, facing, was):
			return {"hit": true, "at_ms": t}
	return {"hit": false, "at_ms": now_ms}


## THE ONLY LINE IN THIS FILE THAT READS THE INTENT'S OWN `origin`, and §5 step
## 2 is explicit that it is used for the latency tolerance and nothing else.
##
## What it decides: whether this peer gets the retro test at all. A peer that
## reports standing roughly where the host has it is honestly late, and the
## creature it swung at really was somewhere else a round trip ago -- give it
## the window. A peer that reports standing somewhere the host never had it is
## not late, it is claiming a position, and it gets only the present-tick test
## against the host's own numbers.
##
## So a lying `origin` can only ever LOSE a striker its tolerance. It can never
## win a hit, because the test itself is run from `host_origin` in both
## branches. That is §2 ("a peer that lies about its position gets a strike that
## misses, not a strike that hits") reduced to one function.
##
## The agreement bar is the MOVE'S OWN REACH rather than a third tunable: a
## claim inside one swing-length of where the host has you is the same
## disagreement the connect test is already forgiving, and inventing a second
## number to express it would be a bar discovered by tuning rather than fixed by
## the protocol.
func _retro_window_applies(move: Dictionary, host_origin: Vector3, intent: Dictionary) -> bool:
	if not intent.has("origin"):
		# No claim at all is not a lie. A caller that does not fill in `origin`
		# (the host's own combat manager submits through the same door) is
		# trivially in agreement with the host.
		return true
	var claimed := to_vec3(intent["origin"])
	var reach := float(move.get("range", 2.6))
	return host_origin.distance_to(claimed) <= maxf(0.1, reach)


# --- §10: scaling, and who the opponent swings at ---------------------------------

## The scaling row this fight is running under right now. Read off the RECORD,
## so a participant's process and the host agree by construction rather than by
## each recomputing it from its own idea of who is in the fight.
func scaling(encounter_id: String) -> Dictionary:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return scaling_for(1)
	var row: Variant = rec.get("scaling", {})
	if row is Dictionary and not (row as Dictionary).is_empty():
		return row as Dictionary
	return scaling_for(1)


func participant_count(encounter_id: String) -> int:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return 0
	return (rec["participants"] as Dictionary).size()


## §5 / §10: which of the participants a connecting swing actually lands on.
##
## `candidates` is every participant the host's own geometry says the swing
## reached, as `{"peer_id": int, "distance": float}` rows -- the caller does the
## cone test against the bodies it holds, this file decides between the results.
##
## The policy is **least-struck first**, ties broken by distance. §10's own
## words: targeting is spread across participants "rather than one player
## tanking by standing still". Nearest-only is exactly that failure -- two
## players fighting one opponent means whoever steps closest absorbs the entire
## fight, and the other one is watching. Spreading it is the composition half of
## scaling, and it is why a second player makes the fight harder for BOTH of
## them without the opponent having a single extra hit point.
##
## With one candidate this returns that candidate, so a solo fight and a fight
## where the swing reached only one person behave exactly as they did before.
func pick_struck(encounter_id: String, candidates: Array) -> Dictionary:
	if candidates.is_empty():
		return {}
	if candidates.size() == 1:
		return candidates[0] as Dictionary
	var counts: Dictionary = _struck_counts(encounter_id)
	var best: Dictionary = {}
	var best_hits := -1
	var best_distance := INF
	for raw: Variant in candidates:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var row := raw as Dictionary
		var peer_id := int(row.get("peer_id", 0))
		var hits := int(counts.get(peer_id, 0))
		var distance := float(row.get("distance", INF))
		if best.is_empty() or hits < best_hits \
				or (hits == best_hits and distance < best_distance):
			best = row
			best_hits = hits
			best_distance = distance
	return best


## Record that `peer_id` took the opponent's swing, so the next one prefers
## somebody else. Called only when a blow actually LANDS: a swing that reached
## a player and rolled a miss has not shared the pressure around and must not
## count as if it had.
func note_struck(encounter_id: String, peer_id: int) -> void:
	var counts := _struck_counts(encounter_id)
	if counts.is_empty() and not encounters.has(encounter_id):
		return
	counts[peer_id] = int(counts.get(peer_id, 0)) + 1


## How many of the opponent's blows this participant has taken in this fight.
## Public because the spread policy is only worth having if a test can see it
## work, and reading it back is how `tests/test_encounter_rewards.gd` does that.
func struck_count(encounter_id: String, peer_id: int) -> int:
	return int(_struck_counts(encounter_id).get(peer_id, 0))


func _struck_counts(encounter_id: String) -> Dictionary:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return {}
	if not rec.has("struck_counts"):
		rec["struck_counts"] = {}
	return rec["struck_counts"] as Dictionary


## Re-derive §10's row from the record's own participant count. One place, so a
## future third way of changing `participants` cannot forget it.
func _restamp_scaling(rec: Dictionary) -> void:
	rec["scaling"] = scaling_for((rec["participants"] as Dictionary).size())


# --- §8's phase, driven by catch_arbiter.gd ---------------------------------------

## Move the record's phase. `catch_arbiter.gd` owns WHO wins a catch; the phase
## it wins lives here, because the phase is the record's and the record is this
## file's.
func set_phase(encounter_id: String, phase: String) -> void:
	if not pending_tether_items(encounter_id).is_empty(): return
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return
	rec["phase"] = phase
	# Catch resolution, a breakout back to active, and encounter resolution are
	# lifecycle boundaries. None inherits a half-spent attack from the previous
	# phase.
	_strike_authority[encounter_id] = {}
	seq += 1
	rec["seq"] = seq


func phase(encounter_id: String) -> String:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return "done"
	return str(rec.get("phase", "done"))


func kind(encounter_id: String) -> String:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return ""
	return str(rec.get("kind", ""))


func close(encounter_id: String) -> void:
	if not pending_tether_items(encounter_id).is_empty(): return
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return
	rec["phase"] = "done"
	var opponent: Dictionary = rec.get("opponent", {})
	if opponent.has("round_continues"):
		opponent["round_continues"] = false
	_strike_authority.erase(encounter_id)
	_strike_receipts.erase(encounter_id)
	seq += 1
	rec["seq"] = seq


## Forget a finished fight. Kept separate from `close()` so a participant can
## still be told the record's final state before it stops existing.
func forget(encounter_id: String) -> void:
	# A failed owner save/disconnect cannot turn an accepted faint into healthy
	# old portable HP. Teardown waits for the single Session registry's durable
	# handoff of every exact latest revision, including departed participants.
	if not pending_actor_vitals(encounter_id).is_empty() or not pending_tether_items(encounter_id).is_empty(): return
	encounters.erase(encounter_id)
	_strike_authority.erase(encounter_id)
	_strike_receipts.erase(encounter_id)


# --- internals ---------------------------------------------------------------------

func _add_participant(rec: Dictionary, peer_id: int, creature_uid: String,
		character_id: String) -> void:
	var retained: Dictionary = rec.get("retained_actor_participants", {})
	if not character_id.is_empty() and retained.has(character_id):
		var restored: Dictionary = retained[character_id]
		retained.erase(character_id)
		var authority := _strike_state_for(str(rec.encounter_id))
		if authority.has(character_id):
			authority[peer_id] = authority[character_id]
			authority.erase(character_id)
		# character_id and active UID are supplied by host admission, never by
		# the incoming intent. Binding a new body below rechecks owned UID.
		# A trainer round's re-seat (`_resume_trainer_encounter`) supplies no
		# UID: the same character keeps its retained active creature, which
		# its actor row is still bound to. A supplied UID still relabels, and
		# a real switch still rebinds through bind_actor_body's generation.
		if not creature_uid.is_empty(): restored["creature_uid"] = creature_uid
		(rec["participants"] as Dictionary)[peer_id] = restored
		return
	(rec["participants"] as Dictionary)[peer_id] = {
		"character_id": character_id,
		"creature_uid": creature_uid,
		"joined_seq": seq,
	}


static func _opponent_row(opponent: Dictionary) -> Dictionary:
	var hp_max := maxf(1.0, float(opponent.get("hp_max", 1.0)))
	var out := {
		"species_id": str(opponent.get("species_id", "")),
		"display_name": str(opponent.get("display_name", "")),
		"level": int(opponent.get("level", 1)),
		"hp": clampf(float(opponent.get("hp", hp_max)), 0.0, hp_max),
		"hp_max": hp_max,
		"moves": opponent.get("moves", []),
		"owner_npc": str(opponent.get("owner_npc", "")),
		"position": opponent.get("position", [0.0, 0.0, 0.0]),
		"samples": [],
	}
	# Shared-wild presentation, and a trainer round's mirror identity (F14#1),
	# are read-only client data. Preserve only their explicit schema; authority
	# still reads the established fields above.
	for key: String in ["card", "foot_position", "facing", "body_generation",
			"presentation_seq", "cue_serial", "telegraph_count", "strike_count", "cue",
			"body_scale", "alpha", "round", "round_continues", "arena_centre", "arena_radius_m", "named_encounter_id"]:
		if opponent.has(key):
			out[key] = opponent[key].duplicate(true) if opponent[key] is Dictionary \
				or opponent[key] is Array else opponent[key]
	return out


## An `[x, y, z]` array (what crosses the wire) or a `Vector3` (what a unit test
## finds it natural to pass) as a `Vector3`. Anything else is the origin, which
## is why every caller above checks `has()` first rather than relying on this to
## report a missing field.
static func to_vec3(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and (value as Array).size() == 3:
		var a: Array = value
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO


static func _ok(kind_name: String, peer_id: int, payload: Dictionary) -> Dictionary:
	var verdict := {
		"ok": true, "kind": kind_name, "peer": peer_id, "code": "",
		"reason": "", "pending": false,
		"delta": payload,
	}
	return verdict


static func _refuse(kind_name: String, peer_id: int, code: String, reason: String) -> Dictionary:
	return {
		"ok": false, "kind": kind_name, "peer": peer_id, "code": code,
		"reason": reason, "pending": false, "delta": {},
	}


## Internal canonical actor lifetime. The owning caller must first resolve
## admitted character/UID and the actual current host body; never packet HP.
func bind_actor_vitals(encounter_id: String, peer_id: int, character_id: String,
		owned_row: Dictionary, body_generation: int) -> Dictionary:
	if not pending_tether_items(encounter_id).is_empty(): return {"ok": false, "code": "item_save_pending"}
	var participant := _actor_participant(encounter_id, peer_id, character_id)
	var uid: Variant = owned_row.get("uid")
	var hp: Variant = owned_row.get("hp")
	var maximum: Variant = owned_row.get("max_hp")
	var fainted: Variant = owned_row.get("fainted")
	if participant.is_empty() or not UTILITY_EFFECTS._identity(uid) or body_generation < 1 \
		or body_generation > 2147483647 \
		or not UTILITY_EFFECTS._number(maximum, 1.0, 1000000000.0) \
		or not UTILITY_EFFECTS._number(hp, 0.0, float(maximum)) \
		or not fainted is bool or bool(fainted) != (float(hp) == 0.0):
		return {"ok": false, "code": "invalid_actor"}
	var actors: Dictionary = participant.get("actor_vitals", {})
	var actor: Dictionary = actors.get(uid, {})
	if actor.is_empty():
		if actors.size() >= 5: return {"ok": false, "code": "party_capacity"}
		actor = {"creature_uid": uid, "hp": float(hp), "max_hp": float(maximum),
			"fainted": fainted, "body_generation": body_generation, "revision": 0,
			"receipts": {}, "settled_revision": 0, "settlement_receipt": {}}
		actors[uid] = actor
		participant["actor_vitals"] = actors
	elif float(actor.max_hp) != float(maximum) or body_generation < int(actor.body_generation):
		return {"ok": false, "code": "stale_actor"}
	else:
		actor["body_generation"] = body_generation
	participant["creature_uid"] = uid
	participant["actor_bound_uid"] = uid
	participant["actor_generation"] = maxi(int(participant.get("actor_generation", 0)), body_generation)
	return {"ok": true, "vitals": _actor_vitals_view(actor)}

func bind_actor_body(encounter_id: String, peer_id: int, character_id: String,
		owned_row: Dictionary, host_body_instance_id: int) -> Dictionary:
	if not pending_tether_items(encounter_id).is_empty(): return {"ok": false, "code": "item_save_pending"}
	var participant := _actor_participant(encounter_id, peer_id, character_id)
	if participant.is_empty() or host_body_instance_id < 1 \
		or not UTILITY_EFFECTS._identity(owned_row.get("uid")):
		return {"ok": false, "code": "invalid_actor"}
	var uid := str(owned_row.uid)
	var actor: Dictionary = (participant.get("actor_vitals", {}) as Dictionary).get(uid, {})
	var generation := int(actor.get("body_generation", 0))
	if actor.is_empty() or str(participant.get("actor_bound_uid", "")) != uid \
		or int(actor.get("body_instance_id", 0)) != host_body_instance_id:
		var previous := int(participant.get("actor_generation", 0))
		if previous >= 2147483647: return {"ok": false, "code": "generation_exhausted"}
		generation = previous + 1
	var result := bind_actor_vitals(encounter_id, peer_id, character_id, owned_row, generation)
	if not bool(result.get("ok", false)): return result
	(participant.actor_vitals[uid] as Dictionary)["body_instance_id"] = host_body_instance_id
	return result

func actor_vitals(encounter_id: String, peer_id: int, creature_uid: String,
		body_generation: int) -> Dictionary:
	var participant := _actor_participant(encounter_id, peer_id)
	var actor: Dictionary = (participant.get("actor_vitals", {}) as Dictionary).get(creature_uid, {})
	if (_staging_saved_item_character.is_empty() and str(participant.get("creature_uid", "")) != creature_uid) or actor.is_empty() \
		or int(actor.body_generation) != body_generation: return {}
	return _actor_vitals_view(actor)

func stage_actor_vitals(encounter_id: String, peer_id: int, creature_uid: String,
		body_generation: int, expected_revision: int, action_id: String, kind: String,
		amount: float, receipt_limit: int) -> Dictionary:
	if _staging_saved_item_character.is_empty() and not pending_tether_items(encounter_id).is_empty():
		return {"ok": false, "code": "item_save_pending"}
	var before := actor_vitals(encounter_id, peer_id, creature_uid, body_generation)
	if before.is_empty() or expected_revision != int(before.revision) \
		or not UTILITY_EFFECTS._identity(action_id) or kind not in ["damage", "heal"] \
		or not is_finite(amount) or amount <= 0.0 or receipt_limit < 1 or receipt_limit > 65536:
		return {"ok": false, "code": "invalid_vitals"}
	var participant := _actor_participant(encounter_id, peer_id)
	var actor: Dictionary = participant.actor_vitals[creature_uid]
	if (actor.receipts as Dictionary).has(action_id): return {"ok": false, "code": "replayed_action"}
	if actor.receipts.size() >= receipt_limit: return {"ok": false, "code": "receipt_budget"}
	if bool(before.fainted): return {"ok": false, "code": "fainted"}
	var next_hp := maxf(0.0, float(before.hp) - amount) if kind == "damage" \
		else minf(float(before.max_hp), float(before.hp) + amount)
	if next_hp == float(before.hp): return {"ok": false, "code": "no_change"}
	var revision := int(before.revision) + 1
	var receipt := {"receipt_id": _vitals_namespace + ":" +
		(encounter_id + "|" + creature_uid + "|" + action_id + "|" + str(revision)).sha256_text(),
		"encounter_id": encounter_id, "creature_uid": creature_uid,
		"body_generation": body_generation, "vitals_revision": revision}
	receipt.make_read_only()
	return {"ok": true, "encounter_id": encounter_id, "peer_id": peer_id,
		"creature_uid": creature_uid, "body_generation": body_generation,
		"expected_revision": expected_revision, "action_id": action_id,
		"kind": kind, "amount": amount, "receipt_limit": receipt_limit,
		"hp_before": float(before.hp), "hp_after": next_hp,
		"max_hp": float(before.max_hp), "fainted": next_hp == 0.0,
		"revision": revision, "settlement_receipt": receipt}

func commit_actor_vitals(proposal: Dictionary) -> Dictionary:
	if not bool(proposal.get("ok", false)): return {"ok": false, "code": "invalid_proposal"}
	for key: String in ["encounter_id", "creature_uid", "action_id", "kind"]:
		if not proposal.get(key) is String: return {"ok": false, "code": "invalid_proposal"}
	for key: String in ["peer_id", "body_generation", "expected_revision", "receipt_limit"]:
		if not proposal.get(key) is int: return {"ok": false, "code": "invalid_proposal"}
	if not UTILITY_EFFECTS._number(proposal.get("amount"), 0.0, INF):
		return {"ok": false, "code": "invalid_proposal"}
	var verified := stage_actor_vitals(str(proposal.get("encounter_id", "")),
		int(proposal.get("peer_id", 0)), str(proposal.get("creature_uid", "")),
		int(proposal.get("body_generation", 0)), int(proposal.get("expected_revision", -1)),
		str(proposal.get("action_id", "")), str(proposal.get("kind", "")),
		float(proposal.get("amount", NAN)), int(proposal.get("receipt_limit", 0)))
	if not bool(verified.get("ok", false)) or verified != proposal:
		return {"ok": false, "code": "stale_proposal"}
	var participant := _actor_participant(str(proposal.encounter_id), int(proposal.peer_id))
	var actor: Dictionary = participant.actor_vitals[str(proposal.creature_uid)]
	actor["hp"] = proposal.hp_after
	actor["fainted"] = proposal.fainted
	actor["revision"] = proposal.revision
	actor["settlement_receipt"] = proposal.settlement_receipt.duplicate(true)
	(actor.receipts as Dictionary)[str(proposal.action_id)] = true
	seq += 1
	(encounters[str(proposal.encounter_id)] as Dictionary)["seq"] = seq
	return {"ok": true, "vitals": _actor_vitals_view(actor)}

func pending_actor_vitals(encounter_id: String) -> Array:
	var rec: Dictionary = encounters.get(encounter_id, {})
	var out: Array = []
	var rows: Array = (rec.get("participants", {}) as Dictionary).values()
	rows.append_array((rec.get("retained_actor_participants", {}) as Dictionary).values())
	for participant: Dictionary in rows:
		for actor: Dictionary in (participant.get("actor_vitals", {}) as Dictionary).values():
			if int(actor.revision) <= int(actor.settled_revision): continue
			var pending := _actor_vitals_view(actor)
			pending["character_id"] = str(participant.character_id)
			out.append(pending)
	return out

func acknowledge_actor_vitals(encounter_id: String, character_id: String,
		creature_uid: String, revision: int, receipt: Dictionary) -> bool:
	var rec: Dictionary = encounters.get(encounter_id, {})
	var rows: Array = (rec.get("participants", {}) as Dictionary).values()
	rows.append_array((rec.get("retained_actor_participants", {}) as Dictionary).values())
	for participant: Dictionary in rows:
		if str(participant.get("character_id", "")) != character_id: continue
		var actor: Dictionary = (participant.get("actor_vitals", {}) as Dictionary).get(creature_uid, {})
		if actor.is_empty() or revision != int(actor.revision) \
			or receipt != actor.settlement_receipt: return false
		actor["settled_revision"] = revision
		return true
	return false

func actor_encounter_is_current(encounter_id: String, peer_id: int, character_id: String) -> bool:
	if peer_id<=0 or character_id.is_empty(): return false
	var current: Dictionary = encounters.get(encounter_id,{})
	if str(current.get("phase",""))!="active": return false
	var participants: Variant = current.get("participants")
	if not participants is Dictionary or not participants.get(peer_id) is Dictionary \
		or participants[peer_id].get("character_id")!=character_id: return false
	for other_peer: Variant in participants:
		var row: Variant = participants[other_peer]
		if not row is Dictionary: return false
		if other_peer != peer_id and row.get("character_id") == character_id: return false
	for id: String in encounters:
		if id==encounter_id: continue
		var candidate: Dictionary = encounters[id]
		if str(candidate.get("phase","")) not in ["active","catching","resolving"]: continue
		var others: Variant = candidate.get("participants")
		if not others is Dictionary: return false
		for other_peer: Variant in others:
			var row: Variant = others[other_peer]
			if not row is Dictionary: return false
			if other_peer==peer_id or row.get("character_id")==character_id: return false
	return true

func _actor_participant(encounter_id: String, peer_id: int, character_id: String = "") -> Dictionary:
	var rec: Dictionary = encounters.get(encounter_id, {})
	# Only the exact saved-item baseline branch enters this private scope.
	# It settles the original retained canonical row after departure, without
	# making a departed body active or writing a replacement creature.
	if not _staging_saved_item_character.is_empty():
		var rows: Array = rec.get("participants", {}).values()
		rows.append_array(rec.get("retained_actor_participants", {}).values())
		for row: Dictionary in rows:
			if row.get("character_id") == _staging_saved_item_character: return row
		return {}
	if rec.is_empty() or str(rec.get("phase", "")) != "active": return {}
	var participant: Dictionary = (rec.get("participants", {}) as Dictionary).get(peer_id, {})
	if str(participant.get("character_id", "")).is_empty() \
		or (not character_id.is_empty() and str(participant.character_id) != character_id): return {}
	if not actor_encounter_is_current(encounter_id, peer_id, str(participant.character_id)): return {}
	return participant

static func _actor_vitals_view(actor: Dictionary) -> Dictionary:
	var out := actor.duplicate(true)
	out.erase("receipts")
	out.erase("body_instance_id")
	out.erase("training_receipt")
	out.erase("training_character_revision")
	return out

static func presentation_snapshot(rec: Dictionary) -> Dictionary:
	var out := rec.duplicate(true)
	out.erase("retained_actor_participants")
	out.erase("utility_state")
	for participant: Dictionary in (out.get("participants", {}) as Dictionary).values():
		if participant.get("tether_commands") is Dictionary: participant.tether_commands.erase("item_pending")
		participant.erase("actor_generation")
		participant.erase("actor_bound_uid")
		for actor: Dictionary in (participant.get("actor_vitals", {}) as Dictionary).values():
			actor.erase("receipts")
			actor.erase("body_instance_id")
			actor.erase("settlement_receipt")
			actor.erase("settled_revision")
	return out


## A detached trial reuses the same canonical self-heal resource validator;
## it is scoped to this one encounter/action and never kept as another roster.
## Real resources/HP stay untouched until silent world durability succeeds.
func stage_actor_heal_utility(intent: Dictionary, peer_id: int, view: Dictionary,
		move_id: String, wind_profile: Dictionary, receipt_limit: int) -> Dictionary:
	var id := str(intent.get("encounter_id", ""))
	var rec: Dictionary = encounters.get(id, {})
	if rec.is_empty() or str(rec.get("phase", "")) != "active" \
		or not is_participant(id, peer_id) or typeof(view.get("source_generation")) != TYPE_INT \
		or not UTILITY_EFFECTS._identity(view.get("source_uid")) \
		or typeof(view.get("now_ms")) != TYPE_INT or int(view.now_ms) < 0 \
		or not UTILITY_EFFECTS._point(view.get("origin")) \
		or typeof(intent.get("action")) != TYPE_INT or int(intent.action) <= 0:
		return {"ok": false, "code": "invalid_actor"}
	var uid := str(view.source_uid)
	var actor := actor_vitals(id, peer_id, uid, int(view.source_generation))
	if actor.is_empty() or bool(actor.fainted): return {"ok": false, "code": "invalid_actor"}
	if _actor_moves == null: _actor_moves = ACTOR_MOVE_DB.new()
	var move: Dictionary = _actor_moves.call("move", move_id)
	if not UTILITY_EFFECTS.valid_definition(move) or float(move.base_power) != 0.0 \
		or str(move.utility.kind) != "heal" or str(move.utility.scope) != "self":
		return {"ok": false, "code": "unsupported_heal"}
	# Same host tuning as ordinary player moves; raw MoveDB timings cannot
	# define a second unpaced utility action lifecycle.
	move = MATH.with_player_pace(move, "player_utility")
	var state: Dictionary = rec.get("utility_state", UTILITY_EFFECTS.empty_state(id, 0))
	var action_id := "%s:%d:%d:heal" % [id, peer_id, int(intent.action)]
	var host := {"encounter_id": id, "generation": 0, "action_id": action_id,
		"source_uid": uid, "target_uid": uid, "source_position": view.origin,
		"target_position": view.origin, "source_hp": float(actor.hp),
		"source_max_hp": float(actor.max_hp), "hostile": false, "geometry_connected": true}
	var effect := UTILITY_EFFECTS.stage_application(state, move_id, move, host, int(view.now_ms), receipt_limit)
	if not bool(effect.get("ok", false)): return effect # Full/faint refuses BEFORE spending anything.
	var proposal := stage_actor_vitals(id, peer_id, uid, int(view.source_generation),
		int(actor.revision), action_id, "heal", float(effect.receipt.hp_after) - float(actor.hp), receipt_limit)
	if not bool(proposal.get("ok", false)): return proposal
	var trial = get_script().new(_host_peer_id)
	trial.encounters[id] = rec.duplicate(true)
	trial._strike_authority[id] = (_strike_authority.get(id, {}) as Dictionary).duplicate(true)
	trial.seq = seq
	var canonical_view := view.duplicate(true)
	canonical_view["move_id"] = move_id
	var verdict: Dictionary = trial._authorize_actor_self_heal(intent, peer_id, canonical_view, move, wind_profile)
	if not bool(verdict.get("ok", false)): return verdict
	var after: Dictionary = (trial.encounters[id].participants[peer_id] as Dictionary)
	var resource_fields := ["wind", "wind_max", "wind_regen_per_second", "wind_updated_ms",
		"wind_last_action", "wind_ready_at_ms", "utility_deadlines"]
	var resources := {}
	for key: String in resource_fields: resources[key] = after[key]
	# No self heal can mint hostile landed authorization or meter/mastery gain.
	var authority: Dictionary = (trial._strike_authority[id][peer_id] as Dictionary).duplicate(true)
	return {"ok": true, "encounter_id": id, "peer_id": peer_id,
		"expected_seq": int(rec.seq), "intent": intent.duplicate(true), "view": canonical_view,
		"move_id": move_id, "wind_profile": wind_profile.duplicate(true), "receipt_limit": receipt_limit,
		"vitals_proposal": proposal, "effect": effect, "resources": resources,
		"authority": authority, "verdict": verdict, "resource_seq_delta": trial.seq - seq}


## Exact re-stage before ANY write. After success, no callbacks or fallible
## publication runs between actor HP and resource/status commit.
func commit_actor_heal_utility(bundle: Dictionary) -> Dictionary:
	if not bool(bundle.get("ok", false)) or not bundle.get("intent") is Dictionary \
		or not bundle.get("view") is Dictionary or not bundle.get("wind_profile") is Dictionary \
		or not bundle.get("move_id") is String or typeof(bundle.get("peer_id")) != TYPE_INT \
		or typeof(bundle.get("receipt_limit")) != TYPE_INT: return {"ok": false, "code": "invalid_bundle"}
	var verified := stage_actor_heal_utility(bundle.intent, int(bundle.peer_id), bundle.view,
		str(bundle.move_id), bundle.wind_profile, int(bundle.receipt_limit))
	if not bool(verified.get("ok", false)) or verified != bundle:
		return {"ok": false, "code": "stale_bundle"}
	var committed := commit_actor_vitals(bundle.vitals_proposal)
	if not bool(committed.get("ok", false)): return committed
	var rec: Dictionary = encounters[str(bundle.encounter_id)]
	var participant: Dictionary = rec.participants[int(bundle.peer_id)]
	# Apply only the existing resource fields: never replace an actor/party
	# with the staged pre-heal copy or restore its older HP accidentally.
	for key: String in bundle.resources:
		var raw: Variant = bundle.resources[key]
		participant[key] = raw.duplicate(true) if raw is Dictionary else raw
	_strike_state_for(str(bundle.encounter_id))[int(bundle.peer_id)] = bundle.authority.duplicate(true)
	rec["utility_state"] = (bundle.effect.state as Dictionary).duplicate(true)
	seq += int(bundle.resource_seq_delta)
	rec["seq"] = seq
	var verdict: Dictionary = bundle.verdict.duplicate(true)
	(verdict.delta as Dictionary)["utility_receipt"] = (bundle.effect.receipt as Dictionary).duplicate(true)
	return {"ok": true, "vitals": committed.vitals, "verdict": verdict}

## Heal-only authorization on a detached trial. It shares the existing action
## sequence, deadline, participant Wind and recovery; no hostile authorization,
## fake strike, second resource ledger, meter or mastery is introduced.
func _authorize_actor_self_heal(intent: Dictionary, peer_id: int, view: Dictionary,
		move: Dictionary, wind_profile: Dictionary) -> Dictionary:
	var id := str(intent.get("encounter_id", ""))
	var participant := _actor_participant(id, peer_id)
	if participant.is_empty() or typeof(intent.get("action")) != TYPE_INT \
		or int(intent.action) <= 0 or typeof(view.get("now_ms")) != TYPE_INT \
		or int(view.now_ms) < 0 or not UTILITY_EFFECTS.valid_definition(move) \
		or str(move.utility.kind) != "heal" or str(move.utility.scope) != "self" \
		or not UTILITY_EFFECTS._number(wind_profile.get("max"),1.0,1000000000.0) \
		or not UTILITY_EFFECTS._number(wind_profile.get("regen_per_second"),0.0,1000000000.0):
		return _refuse("utility_intent",peer_id,"invalid_heal","That heal could not commit safely.")
	var now_ms := int(view.now_ms)
	var action := int(intent.action)
	var authority := strike_authority_state(id,peer_id)
	if action <= maxi(int(authority.get("last_action",0)),int(participant.get("wind_last_action",0))):
		return _refuse("utility_intent",peer_id,"replayed_action","That action was already handled.")
	var deadlines: Dictionary = participant.get("utility_deadlines",{})
	var uid := str(view.get("source_uid", ""))
	if not UTILITY_EFFECTS._identity(uid):
		return _refuse("utility_intent",peer_id,"invalid_actor","That heal could not commit safely.")
	if now_ms < int(authority.get("deadline_ms",0)) or now_ms < int(deadlines.get(uid,0)):
		return _refuse("utility_intent",peer_id,"cooldown","That move is still recovering.")
	var wind_cfg: Dictionary = MATH.config().get("wind",{})
	var delay: Variant = wind_cfg.get("regen_delay")
	var recovery: Variant = move.get("recovery")
	if not UTILITY_EFFECTS._number(delay,0.0,1000.0) \
		or not UTILITY_EFFECTS._number(move.get("windup"),0.0,60.0) \
		or not UTILITY_EFFECTS._number(recovery,0.0,60.0):
		return _refuse("utility_intent",peer_id,"invalid_config","That heal could not commit safely.")
	var preview := preview_wind(id,peer_id,wind_profile,float(move.wind_cost),now_ms)
	if bool(preview.get("wind_exhausted",true)):
		return _refuse("utility_intent",peer_id,"insufficient_wind","Your creature needs more Wind.")
	var wind := commit_wind(id,peer_id,action,wind_profile,float(move.wind_cost),now_ms,
		float(move.windup) + float(recovery),float(delay))
	# Shared action recovery ends before this creature's separate utility
	# cooldown. A tag switch must not inherit another creature's ten-second lock.
	var lock_ms := ceili(1000.0 * maxf(0.05, float(move.windup) + float(recovery)))
	var deadline := now_ms + lock_ms
	_strike_state_for(id)[peer_id] = {"last_action":action,"accepted_at_ms":now_ms,
		"deadline_ms":deadline,"cooldown_ms":lock_ms}
	participant["utility_deadlines"] = deadlines.duplicate(true)
	participant.utility_deadlines[uid] = now_ms + ceili(float(move.cooldown)*1000.0)
	var delta := {"encounter_id":id,"accepted_action":action,"accepted_at_ms":now_ms,
		"cooldown_deadline_ms":deadline,"hit":false,"target":"self"}
	delta.merge(wind,true)
	return _ok("utility_intent",peer_id,delta)


## Only the current registry's exact typed Altar lineage may retire a stale
## inactive actor binding. No current participant or unsettled damage is reset.
func stage_actor_training_baseline(training: Dictionary, admitted: Dictionary,
		character_revision: int, world_namespace: String, world_id: String) -> Dictionary:
	var full_action: bool = preload("res://scripts/net/character_record_rules.gd").training_version(training) in [2, 3]
	if not TRAINING_WORLD.training_row_valid(training, world_namespace, world_id) \
		or (not full_action and not training.action in ["altar_spend", "wild_defeat"]) or admitted.get("character_id") != training.character_id \
		or character_revision < int(training.character_revision) or not admitted.get("party") is Array \
		or not admitted.get("redesign_character") is Dictionary \
		or not admitted.redesign_character.get("transaction_receipts", []).has(training.receipt):
		return {"ok":false,"code":"training_lineage_unavailable"}
	if full_action and (not preload("res://scripts/net/character_record_rules.gd").errors(admitted, training.character_id).is_empty() \
		or not has_method("move_action_publication_pending")):
		return {"ok":false,"code":"canonical_action_fence_unavailable"}
	if training.get("action") == "tether_item":
		return _stage_tether_item_baseline(training, admitted, character_revision, world_namespace, world_id)
	var old_party: Dictionary = {}
	var next_party: Dictionary = {}
	var current_party: Dictionary = {}
	for owned: Dictionary in training.before.party: old_party[owned.uid]=owned
	for owned: Dictionary in training.after.party: next_party[owned.uid]=owned
	for owned: Dictionary in admitted.party: current_party[owned.uid]=owned
	var changes: Array[Dictionary] = []
	for id: String in encounters:
		var record: Dictionary = encounters[id]
		for retained: bool in [false,true]:
			var participants: Dictionary = record.get("retained_actor_participants" if retained else "participants",{})
			for key: Variant in participants:
				var participant: Dictionary = participants[key]
				if participant.get("character_id") != training.character_id: continue
				if full_action and call("move_action_publication_pending", id) == true:
					return {"ok":false,"code":"training_move_action_pending"}
				if not retained and record.get("phase") != "done":
					return {"ok":false,"code":"training_actor_still_active"}
				var high_water := int(participant.get("actor_generation",0))
				for uid: String in participant.get("actor_vitals",{}):
					var actor: Dictionary = participant.actor_vitals[uid]
					# Prior released actor history stays in the same private record.
					# Both durable release histories must attest it, never a flag alone.
					if actor.get("training_retired") == true and not old_party.has(uid) and not next_party.has(uid) and not current_party.has(uid):
						var released := "release:" + uid
						if actor.get("training_receipt") != released or actor.get("body_instance_id") != 0 \
							or not admitted.redesign_character.transaction_receipts.has(released) \
							or not admitted.redesign_character.get("release_receipts", []).has(released) \
							or int(actor.get("settled_revision", -1)) != int(actor.get("revision", -2)):
							return {"ok":false,"code":"retired_actor_lineage_conflict"}
						continue
					var releasing: bool = full_action and ((training.action in ["trait_release", "essence_release"] and training.intent.creature_uid == uid) \
						or (training.action == "wild_capture" and training.intent.released_uid == uid)) \
						and old_party.has(uid) and not next_party.has(uid) and not current_party.has(uid)
					if releasing:
						var before_actor: Dictionary = old_party[uid]
						if int(actor.get("settled_revision", -1)) != int(actor.get("revision", -2)) \
							or not ACTOR_AUTHORITY.equivalent(actor.max_hp, before_actor.max_hp) \
							or not ACTOR_AUTHORITY.equivalent(actor.hp, before_actor.hp) or actor.fainted != before_actor.fainted:
							return {"ok":false,"code":"release_actor_baseline_conflict"}
						if actor.get("training_retired") == true and actor.get("training_receipt") == "release:" + uid \
							and actor.get("training_character_revision") == training.character_revision: continue
						high_water = maxi(high_water, int(actor.body_generation))
						if high_water >= 2147483647: return {"ok":false,"code":"generation_exhausted"}
						high_water += 1
						var retired_actor := actor.duplicate(true)
						retired_actor.body_generation = high_water
						retired_actor.body_instance_id = 0
						retired_actor.training_receipt = "release:" + uid
						retired_actor.training_character_revision = training.character_revision
						retired_actor.training_retired = true
						changes.append({"encounter_id": id, "retained": retained, "participant_key": key,
							"uid": uid, "before": actor.duplicate(true), "after": retired_actor,
							"participant_generation": participant.get("actor_generation", 0)})
						continue
					if not old_party.has(uid) or not next_party.has(uid) or not current_party.has(uid):
						return {"ok":false,"code":"training_actor_ownership_changed"}
					var old: Dictionary=old_party[uid]
					var next: Dictionary=next_party[uid]
					var current: Dictionary=current_party[uid]
					if int(actor.get("settled_revision",-1)) != int(actor.get("revision",-2)):
						return {"ok":false,"code":"training_actor_unsettled"}
					# An exact prior handoff or a fresh canonical post-training seed
					# is read-only. Replays can never restore earlier HP/generation.
					if actor.get("training_receipt")==training.receipt \
						and actor.get("training_character_revision")==training.character_revision: continue
					var card_changed: bool = full_action and (not ACTOR_AUTHORITY.equivalent(old, next) \
						or not ACTOR_AUTHORITY.equivalent(training.before.redesign_character.creatures.get(uid), training.after.redesign_character.creatures.get(uid)))
					if not card_changed and ACTOR_AUTHORITY.equivalent(actor.max_hp,current.max_hp) \
						and ACTOR_AUTHORITY.equivalent(actor.hp,current.hp) and actor.fainted==current.fainted \
						and ACTOR_AUTHORITY.equivalent(current.max_hp,next.max_hp): continue
					if not card_changed and ACTOR_AUTHORITY.equivalent(old.max_hp,next.max_hp) \
						and ACTOR_AUTHORITY.equivalent(old.hp,next.hp) and old.fainted==next.fainted: continue
					if not ACTOR_AUTHORITY.equivalent(actor.max_hp,old.max_hp) \
						or not ACTOR_AUTHORITY.equivalent(actor.hp,old.hp) or actor.fainted!=old.fainted \
						or not ACTOR_AUTHORITY.equivalent(current.max_hp,next.max_hp) \
						or not ACTOR_AUTHORITY.equivalent(current.hp,next.hp) or current.fainted!=next.fainted:
						return {"ok":false,"code":"training_actor_baseline_conflict"}
					high_water=maxi(high_water,int(actor.body_generation))
					if high_water>=2147483647: return {"ok":false,"code":"generation_exhausted"}
					high_water+=1
					var after_actor: Dictionary=actor.duplicate(true)
					after_actor.max_hp=next.max_hp
					after_actor.hp=next.hp
					after_actor.fainted=next.fainted
					after_actor.body_generation=high_water
					after_actor.body_instance_id=0
					after_actor.training_receipt=training.receipt
					after_actor.training_character_revision=training.character_revision
					# All original receipts/revisions remain; this is not damage/heal.
					changes.append({"encounter_id":id,"retained":retained,"participant_key":key,
						"uid":uid,"before":actor.duplicate(true),"after":after_actor,
						"participant_generation":participant.get("actor_generation",0)})
	return {"ok":true,"receipt":training.receipt,"character_revision":training.character_revision,
		"world_namespace":world_namespace,"world_id":world_id,"changes":changes}

## No await, signal, callback or generic maximum setter. The caller passes the
## current actual world carrier and the SAME registry, not packet state.
func commit_actor_training_baseline(proposal: Dictionary, training: Dictionary,
		admitted: Dictionary, character_revision: int, deliveries: Dictionary,
		world_namespace: String, world_id: String) -> bool:
	if training.get("status")!="accepted" or not ACTOR_AUTHORITY.equivalent(deliveries.get(training.get("delivery_id")),training): return false
	var verified: Dictionary=stage_actor_training_baseline(training,admitted,character_revision,world_namespace,world_id)
	if verified.get("ok")!=true or not ACTOR_AUTHORITY.equivalent(verified,proposal): return false
	if proposal.get("kind") == "tether_item":
		return _commit_tether_item_baseline(proposal, training)
	for change: Dictionary in proposal.changes:
		var participants: Dictionary=encounters[change.encounter_id].get("retained_actor_participants" if change.retained else "participants",{})
		var participant: Dictionary=participants[change.participant_key]
		participant.actor_vitals[change.uid]=change.after.duplicate(true)
		participant.actor_generation=maxi(int(participant.get("actor_generation",0)),int(change.after.body_generation))
		if participant.get("actor_bound_uid")==change.uid: participant.actor_bound_uid=""
	return true


## The saved item alone can carry an active owned effect. Its private
## participant original attests the real bound body; ordinary training still
## retires only inactive bodies through the unchanged branch above.
func _stage_tether_item_baseline(training: Dictionary, admitted: Dictionary,
		character_revision: int, world_namespace: String, world_id: String) -> Dictionary:
	if character_revision != int(training.character_revision) \
		or not preload("res://scripts/creatures/essence.gd").owner_matches_after(admitted, training.after):
		return {"ok": false, "code": "item_character_changed"}
	var changes: Array[Dictionary] = []
	for id: String in encounters:
		var rec: Dictionary = encounters[id]
		for retained: bool in [false, true]:
			var participants: Dictionary = rec.get("retained_actor_participants" if retained else "participants", {})
			for key: Variant in participants:
				var participant: Dictionary = participants[key]
				if participant.get("character_id") != training.character_id: continue
				var original: Dictionary = participant.get("tether_commands", {}).get("item_pending", {})
				if original.is_empty():
					# History without its private original cannot rewrite a later actor.
					continue
				if not ACTOR_AUTHORITY.equivalent(original.intent, training.intent) \
					or not ACTOR_AUTHORITY.equivalent(original.context, training.host_context) \
					or original.encounter_id != id: return {"ok": false, "code": "item_original_changed"}
				var frozen: Dictionary = original.context.item_actor
				var uid: String = frozen.creature_uid
				var actor: Dictionary = participant.get("actor_vitals", {}).get(uid, {})
				var next: Dictionary = {}
				for card: Dictionary in training.after.party:
					if card.uid == uid: next = card
				if actor.is_empty() or next.is_empty() or actor.get("body_generation") != frozen.body_generation \
					or actor.get("body_instance_id") != frozen.body_instance_id \
					or not ACTOR_AUTHORITY.equivalent(actor.max_hp, frozen.max_hp): return {"ok": false, "code": "item_body_changed"}
				if original.get("actor_committed") == true:
					if actor.get("training_receipt") != training.receipt or actor.get("training_character_revision") != training.character_revision \
						or not ACTOR_AUTHORITY.equivalent(actor.hp, next.hp) or actor.fainted != next.fainted \
						or participant.tether_commands.get("last_receipt") != original.command_plan.receipt:
						return {"ok": false, "code": "item_commit_changed"}
					continue
				var commands: Dictionary = participant.tether_commands.duplicate(true)
				commands.erase("item_pending")
				if not ACTOR_AUTHORITY.equivalent(commands, original.command_before) \
					or int(actor.revision) != int(frozen.vitals_revision) or actor.settled_revision != actor.revision \
					or not ACTOR_AUTHORITY.equivalent(actor.hp, frozen.hp) or actor.fainted != false:
					return {"ok": false, "code": "item_baseline_changed"}
				var vitals: Dictionary = {}
				if not ACTOR_AUTHORITY.equivalent(next.hp, frozen.hp):
					_staging_saved_item_character = str(training.character_id)
					vitals = stage_actor_vitals(id, int(original.peer_id), uid, int(frozen.body_generation), int(frozen.vitals_revision),
						str(original.intent.effect.action_id), "heal", float(next.hp) - float(frozen.hp),
						int(MATH.config().get("utility_limits", {}).get("receipt_limit_per_encounter", 0)))
					_staging_saved_item_character = ""
					if vitals.get("ok") != true: return {"ok": false, "code": "item_vitals_unavailable"}
				changes.append({"encounter_id": id, "retained": retained, "participant_key": key,
					"uid": uid, "vitals": vitals, "receipt": training.receipt})
	return {"ok": true, "kind": "tether_item", "receipt": training.receipt, "character_revision": training.character_revision,
		"world_namespace": world_namespace, "world_id": world_id, "changes": changes}


func _commit_tether_item_baseline(proposal: Dictionary, training: Dictionary) -> bool:
	for change: Dictionary in proposal.changes:
		var participant: Dictionary = encounters[change.encounter_id].get("retained_actor_participants" if change.retained else "participants", {})[change.participant_key]
		var original: Dictionary = participant.tether_commands.item_pending
		if not change.vitals.is_empty():
			_staging_saved_item_character = str(training.character_id)
			var committed := commit_actor_vitals(change.vitals)
			_staging_saved_item_character = ""
			if committed.get("ok") != true: return false
			if not acknowledge_actor_vitals(str(change.encounter_id), str(training.character_id), str(change.uid),
				int(change.vitals.revision), change.vitals.settlement_receipt): return false
		var actor: Dictionary = participant.actor_vitals[change.uid]
		actor["training_receipt"] = training.receipt
		actor["training_character_revision"] = training.character_revision
		participant.tether_commands = original.command_plan.state.duplicate(true)
		participant.tether_commands["last_receipt"] = original.command_plan.receipt.duplicate(true)
		participant.tether_commands["item_pending"] = original
		original["actor_committed"] = true
		seq += 1
		encounters[change.encounter_id].seq = seq
	return true
