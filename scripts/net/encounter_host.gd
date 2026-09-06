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
##   `not_catchable`      §8 -- a trainer's creature can never be caught
##   `already_resolving`  §8 -- another peer's catch attempt committed first
##   `malformed`          the intent is missing a field it needs
##
## A strike that connects with nothing is `ok` with `"hit": false` in the
## delta: missing is a legal outcome of a legal swing, not a refusal.

const MATH := preload("res://scripts/combat/combat_math.gd")

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
	_add_participant(record, peer_id, creature_uid, character_id)
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
	_add_participant(record, peer_id, creature_uid, character_id)
	seq += 1
	record["seq"] = seq
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
	participants.erase(peer_id)
	seq += 1
	record["seq"] = seq
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

## §3. The record's `hp` is THE hit points. The host writes it here from its own
## simulation and everybody else reads it; nothing else is authoritative.
func set_opponent_hp(encounter_id: String, hp: float, hp_max: float) -> void:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return
	var opponent: Dictionary = rec["opponent"]
	opponent["hp"] = maxf(0.0, hp)
	opponent["hp_max"] = maxf(1.0, hp_max)
	seq += 1
	rec["seq"] = seq


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
## `origin`, `facing`. It carries no damage number and no target -- that
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
	var encounter_id := str(intent.get("encounter_id", ""))
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return _refuse("strike_intent", peer_id, "unknown_encounter", "That fight is over.")
	if not (rec["participants"] as Dictionary).has(peer_id):
		return _refuse("strike_intent", peer_id, "not_participant",
			"You are not in that fight.")
	var phase := str(rec.get("phase", ""))
	if phase != "active":
		return _refuse("strike_intent", peer_id, "wrong_phase",
			"That fight is not taking attacks right now.")
	# `has()` before `get()`, deliberately and everywhere in this function: a
	# missing key read straight through `get()` returns null, `int(null)` is 0
	# and `Vector3(null)` is the origin -- which turns a malformed intent into a
	# strike resolved at the world origin instead of into a refusal.
	if not intent.has("move") or not (intent["move"] is Dictionary):
		return _refuse("strike_intent", peer_id, "malformed",
			"That attack did not say what it was.")
	var move: Dictionary = intent["move"]
	var facing := to_vec3(intent.get("facing", []))
	if facing.length_squared() <= 0.000001:
		return _refuse("strike_intent", peer_id, "malformed",
			"That attack did not say which way it faced.")

	var host_origin := to_vec3(view.get("origin", []))
	var now_ms := int(view.get("now_ms", 0))

	# §5's whole point, and the reason `friendly_target` is a refusal rather
	# than a damage number of zero: WHO the swing resolved onto is decided
	# BEFORE any roll, from bodies the host holds, by owner id (4.B's H5).
	var friendly := _friendly_body_struck(move, host_origin, facing, peer_id, rec, view)
	if not friendly.is_empty():
		return _refuse("strike_intent", peer_id, "friendly_target",
			"You can't attack your own side.")

	var connected := _connects_now_or_recently(move, host_origin, facing, rec, intent, now_ms)
	return _ok("strike_intent", peer_id, {
		"encounter_id": encounter_id,
		"hit": bool(connected.get("hit", false)),
		"target": "opponent" if bool(connected.get("hit", false)) else "",
		"connected_at_ms": int(connected.get("at_ms", now_ms)),
	})


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


# --- §8's phase, driven by catch_arbiter.gd ---------------------------------------

## Move the record's phase. `catch_arbiter.gd` owns WHO wins a catch; the phase
## it wins lives here, because the phase is the record's and the record is this
## file's.
func set_phase(encounter_id: String, phase: String) -> void:
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return
	rec["phase"] = phase
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
	var rec: Dictionary = encounters.get(encounter_id, {})
	if rec.is_empty():
		return
	rec["phase"] = "done"
	seq += 1
	rec["seq"] = seq


## Forget a finished fight. Kept separate from `close()` so a participant can
## still be told the record's final state before it stops existing.
func forget(encounter_id: String) -> void:
	encounters.erase(encounter_id)


# --- internals ---------------------------------------------------------------------

func _add_participant(rec: Dictionary, peer_id: int, creature_uid: String,
		character_id: String) -> void:
	(rec["participants"] as Dictionary)[peer_id] = {
		"character_id": character_id,
		"creature_uid": creature_uid,
		"joined_seq": seq,
	}


static func _opponent_row(opponent: Dictionary) -> Dictionary:
	var hp_max := maxf(1.0, float(opponent.get("hp_max", 1.0)))
	return {
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
