extends RefCounted

## Freed-legendary offer for the Abyssal Guardian (CLAUDE.md, WORLD §2.3,
## BOSSES §4.12, MULTIPLAYER §95). The host owns ONE shared freeing and records
## a separate, once-only offer for EACH participant in the fight that freed it,
## bound to that participant's stable character. Each participant accepts or
## refuses independently; a non-participant receives nothing; no character is
## offered the same world instance's Guardian twice.
##
## Participants (mirrors `stronghold_climax.gd::may_receive` + its journal
## reader, with one deliberate tightening):
##   * Every character with a journaled `world.reward_deliveries` row whose
##     source starts `trainer:water_trainer_nerissa:`, WHATEVER its status.
##     The host decided who took part when it wrote the row; `pending` only
##     means that character has not yet saved the payout (offline, full bag).
##   * Only when there is NO such row at all (a solo world, or a world whose
##     Nerissa payout predates delivery rows) is the host's own local
##     character the one participant. Unlike the Meadows reader, an empty set
##     is NOT "anyone": in co-op an unidentified guest must not qualify.
##
## World instance. Offers are keyed by the WORLD INSTANCE (MULTIPLAYER §95:
## "keyed by world instance, source and stable character ID"), never by
## `world.world_id` alone: that is the local save-slot locator "slot-%d"
## (save_game.gd `_world_id_for`), and two different hosts' worlds are both
## "slot-0". The instance is `world.reward_delivery_namespace` (random, minted
## by world_identity.gd, replicated to joiners in the world snapshot).
## Documented fallback: ONLY when that namespace is empty (a world not yet
## re-saved by its host since identities existed, or a bare fixture) the
## instance is the world_id, the best identity such a world has.
##
## Offer ids are sha256(instance + ":guardian:" + character_id) and every claim
## records `world_instance`, so a character that accepted in its own slot-0
## world is offered afresh -- never silently acknowledged away -- in another
## host's slot-0 world. "No offer is granted twice to the same character" is
## therefore enforced PER WORLD INSTANCE; a once-ever guard across different
## worlds would need an owner ruling and is deliberately not invented here.
##
## The world flag `water_claim:guardian:offered:<sha256(character)>` (declared
## world prefix `water_claim:`) is written in the same journal as the claim, or
## by a refusal made before any claim existed. It survives the claim's
## removal, so a resolved (accepted OR refused) character is never offered a
## second one in this world. A reconnecting character with a still-pending
## claim receives that same claim again (idempotent replay, no write).
##
## World restoration (`water_guardian_settled`, `water_currents_restored`,
## `realm_relic_water_earned`) settles exactly once for the world, on the FIRST
## participant resolution, accept or refuse (BOSSES §4.11/§4.12). It never
## depends on any particular participant accepting; later resolutions write
## nothing. OPEN DECISION (not decided here): a world whose only participants
## left and never return, with a non-participant host, stays unsettled; a
## host-side timeout / tether-release settle is a product call.
##
## `water_guardian_claimed` is kept only as a world-level "an offer has been
## made" marker for existing readers; it no longer locks anyone out.
##
## Legacy (single-recipient) worlds: their claim id was sha256(world_id +
## ":guardian"), hashed on the slot locator, so the bare receipt
## `water_capture_receipt:<legacy id>` on a character cannot say WHICH slot-0
## world issued it. It is honoured only for claims the host stamps
## `legacy_world: true`, i.e. only inside a world instance that itself made a
## legacy offer (LEGACY_FLAG, or `water_guardian_claimed` with no per-character
## offer marker yet, or its legacy claim still pending). There the legacy
## recipient is acknowledged without a duplicate; in any other world the
## receipt blocks nothing. A pending legacy claim is replayed for its
## recipient. Other participants in legacy worlds receive their own offer;
## world restoration already happened and is not written again.
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const TRAINER_ID := "water_trainer_nerissa"
const OFFERED_PREFIX := "water_claim:guardian:offered:"
const LEGACY_FLAG := "water_claim:guardian:legacy_offer"
const RECEIPT_PREFIX := "water_capture_receipt:"
const CLAIMED := "water_guardian_claimed"
const SETTLEMENT := ["water_guardian_settled", "water_currents_restored", "realm_relic_water_earned"]

## The world instance offers are keyed by (see header for the fallback).
static func world_instance(world: RefCounted) -> String:
	if world == null:
		return ""
	var raw: Variant = world.get("reward_delivery_namespace")
	if typeof(raw) == TYPE_STRING and not (raw as String).is_empty():
		return raw as String
	return str(world.get("world_id"))

static func claim_id(instance: String, character_id: String) -> String:
	return (instance + ":guardian:" + character_id).sha256_text()

## The pre-F14 id. It hashed the save-slot locator and cannot be re-keyed.
static func legacy_claim_id(world_id: String) -> String:
	return (world_id + ":guardian").sha256_text()

static func offered_flag(character_id: String) -> String:
	return OFFERED_PREFIX + character_id.sha256_text()

## Characters with ANY journaled Nerissa reward delivery in this world.
static func participants(world: RefCounted) -> Array:
	var out: Array = []
	var deliveries: Variant = world.get("reward_deliveries") if world != null else null
	if not deliveries is Dictionary:
		return out
	var prefix := "trainer:%s:" % TRAINER_ID
	for raw: Variant in (deliveries as Dictionary).values():
		if not raw is Dictionary or not str(raw.get("source", "")).begins_with(prefix):
			continue
		var character := str(raw.get("character_id", ""))
		if not character.is_empty() and not out.has(character):
			out.append(character)
	return out

## Pure rule, testable without a world. `participant_characters` empty means
## "no Nerissa row exists at all": only the host's local character qualifies.
static func may_receive(character_id: String, participant_characters: Array,
		host_local_character: String, already_resolved: bool) -> bool:
	if already_resolved or character_id.is_empty():
		return false
	if not participant_characters.is_empty():
		return participant_characters.has(character_id)
	return character_id == host_local_character

static func host_local_character(game: Object) -> String:
	var local: Variant = game.get("local") if game != null else null
	return str(local.get("character_id")) if local != null else ""

## View-side rule for any peer (host or joiner): may this game's own local
## character still answer its Guardian here? Presentation only; the host
## decides in begin()/refuse().
static func local_may_answer(game: Object) -> bool:
	if game == null or game.get("world") == null:
		return false
	var character := host_local_character(game)
	if character.is_empty() or has_been_offered(game.world, character):
		return false
	var found := participants(game.world)
	if not found.is_empty():
		return found.has(character)
	return game.has_method("is_host") and bool(game.call("is_host"))

## True when this character already resolved its Guardian or still holds an
## unresolved offer in this world (any peer's view of the world flags).
static func has_been_offered(world: RefCounted, character_id: String) -> bool:
	return world != null and not character_id.is_empty() and world.flags.has(offered_flag(character_id))

static func pending_claim_for(world: RefCounted, character_id: String) -> Dictionary:
	for raw: Variant in world.water_capture_claims.values():
		if raw is Dictionary and str(raw.get("source", "")) == "guardian" \
				and str(raw.get("character_id", "")) == character_id \
				and str(raw.get("world_id", "")) == str(world.world_id):
			return raw
	return {}

## This world instance made a pre-F14 single-recipient offer.
static func is_legacy_world(world: RefCounted) -> bool:
	if world == null:
		return false
	if world.flags.has(LEGACY_FLAG) or world.water_capture_claims.has(legacy_claim_id(str(world.world_id))):
		return true
	if not world.flags.has(CLAIMED):
		return false
	for flag: Variant in world.flags.all_set():
		if str(flag).begins_with(OFFERED_PREFIX):
			return false
	return true

## Character-side guard: this character already owns its receipt for this
## claim, or -- only for a claim its host stamped `legacy_world` -- received
## that world's single legacy offer.
static func already_received(flags: RefCounted, claim: Dictionary) -> bool:
	if flags == null:
		return false
	if flags.has(RECEIPT_PREFIX + str(claim.get("id", ""))):
		return true
	return str(claim.get("source", "")) == "guardian" and claim.get("legacy_world", false) == true \
		and flags.has(RECEIPT_PREFIX + legacy_claim_id(str(claim.get("world_id", ""))))

## A received claim belongs to the world instance this peer is in. Claims
## without `world_instance` (ordinary capture claims) keep the world_id check.
static func claim_matches_world(claim: Dictionary, world: RefCounted) -> bool:
	if world == null or str(claim.get("world_id", "")) != str(world.world_id):
		return false
	return not claim.has("world_instance") or str(claim.world_instance) == world_instance(world)

static func _refuse(code: String, reason: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": reason}

static func _restore(game: Object, ledger: RefCounted, before: Dictionary, revision: int, sequence: int) -> void:
	game.world.load_data(before)
	game.world.revision = revision
	ledger.seq = sequence

## Commit world flags; on any refusal restore and return the verdict.
static func _commit_flags(game: Object, ledger: RefCounted, flags: Array, ops: Array,
		before: Dictionary, revision: int, sequence: int) -> Dictionary:
	for flag: String in flags:
		var verdict: Dictionary = ledger.commit({"kind": "set_world_flag", "realm": "water", "id": flag}, 1)
		if not verdict.get("ok", false):
			_restore(game, ledger, before, revision, sequence)
			return verdict
		ops.append_array(verdict.delta.ops)
	return {"ok": true}

static func _settlement_flags(world: RefCounted) -> Array:
	var out: Array = []
	if not world.flags.has(SETTLEMENT[0]):
		for flag: String in SETTLEMENT:
			if not world.flags.has(flag):
				out.append(flag)
	return out

static func release(game: Object, ledger: RefCounted) -> Dictionary:
	if not preload("res://scripts/world/water_alpha_rewards.gd")._ready_host(game, ledger) or not game.world.flags.has("water_captain_nerissa_defeated"):
		return {"ok": false, "reason": "The captain still controls the tether."}
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var sequence: int = ledger.seq
	var ops: Array = []
	var committed := _commit_flags(game, ledger, ["water_tether_disabled", "water_guardian_freed"], ops, before, revision, sequence)
	if not committed.ok:
		return committed
	if not game.save_system.save_world(game, game.world.world_id):
		_restore(game, ledger, before, revision, sequence)
		return {"ok": false, "reason": "Could not save the release. Try again."}
	return {"ok": true, "delta": {"seq": ledger.seq, "realm": "water", "ops": ops}}

## Reserve this participant's own offer. One synchronous transaction: claim,
## offered marker and world file, or none of them.
static func begin(game: Object, ledger: RefCounted, character: String, creature: RefCounted) -> Dictionary:
	if not preload("res://scripts/world/water_alpha_rewards.gd")._ready_host(game, ledger) or character.strip_edges().is_empty():
		return _refuse("not_ready", "The realm cannot begin that ceremony.")
	if not game.world.flags.has("water_guardian_freed"):
		return _refuse("tethered", "The Guardian is still tethered.")
	var existing := pending_claim_for(game.world, character)
	if not existing.is_empty():
		# Reconnect/replay: the same character's unresolved offer, unchanged.
		return {"ok": true, "code": "replay", "id": str(existing.id)}
	if has_been_offered(game.world, character):
		return _refuse("already_resolved", "You have already answered the Guardian's offer in this world.")
	if not may_receive(character, participants(game.world), host_local_character(game), false):
		return _refuse("not_participant", "Only those who fought Captain Nerissa to free the Guardian receive its offer.")
	var payload := CODEC.encode(creature)
	if str(payload.get("species_id", "")) != "water_abyssal_guardian":
		return _refuse("not_ready", "The Guardian is not ready.")
	var legacy := is_legacy_world(game.world)
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var sequence: int = ledger.seq
	var ops: Array = []
	var flags: Array = [offered_flag(character)]
	if legacy and not game.world.flags.has(LEGACY_FLAG):
		flags.append(LEGACY_FLAG) # sticky: this instance made a legacy offer
	if not game.world.flags.has(CLAIMED):
		flags.append(CLAIMED)
	var committed := _commit_flags(game, ledger, flags, ops, before, revision, sequence)
	if not committed.ok:
		return committed
	var instance := world_instance(game.world)
	var id := claim_id(instance, character)
	var claim := {"id": id, "source": "guardian", "world_id": game.world.world_id,
		"world_instance": instance, "character_id": character, "creature": payload}
	if legacy:
		claim["legacy_world"] = true
	game.world.water_capture_claims[id] = claim
	if not game.save_system.save_world(game, game.world.world_id):
		_restore(game, ledger, before, revision, sequence)
		return _refuse("journal_failed", "Could not save the ceremony. Try again.")
	return {"ok": true, "code": "", "id": id, "delta": {"seq": ledger.seq, "realm": "water", "ops": ops}}

## Host settlement of ONE participant's offer, accepted (their character saved
## the receipt) or refused. Removes only that claim; restores the world once.
static func resolve(game: Object, ledger: RefCounted, id: String, character: String, accepted: bool) -> Dictionary:
	if not preload("res://scripts/world/water_alpha_rewards.gd")._ready_host(game, ledger) or character.is_empty():
		return _refuse("not_ready", "The realm cannot settle that ceremony.")
	var claim: Dictionary = game.world.water_capture_claims.get(id, {})
	if claim.is_empty():
		if has_been_offered(game.world, character):
			return {"ok": true, "code": "already_resolved", "accepted": accepted}
		return _refuse("no_claim", "No Guardian offer is waiting for you.")
	if str(claim.get("source", "")) != "guardian" or str(claim.get("character_id", "")) != character:
		return _refuse("wrong_character", "That offer belongs to another character.")
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var sequence: int = ledger.seq
	var flags: Array = []
	if not has_been_offered(game.world, character):
		flags.append(offered_flag(character)) # a legacy claim predates the marker
	if is_legacy_world(game.world) and not game.world.flags.has(LEGACY_FLAG):
		flags.append(LEGACY_FLAG)
	flags.append_array(_settlement_flags(game.world))
	var ops: Array = []
	var committed := _commit_flags(game, ledger, flags, ops, before, revision, sequence)
	if not committed.ok:
		return committed
	game.world.water_capture_claims.erase(id)
	if not game.save_system.save_world(game, game.world.world_id):
		_restore(game, ledger, before, revision, sequence)
		return _refuse("journal_failed", "Could not save the ceremony. Try again.")
	return {"ok": true, "code": "", "accepted": accepted, "delta": {"seq": ledger.seq, "realm": "water", "ops": ops}}

## Refusal of this character's pending claim (WaterCaptureClaims path).
static func decline(game: Object, ledger: RefCounted, character: String) -> Dictionary:
	if game == null or game.get("world") == null:
		return _refuse("not_ready", "The realm cannot settle that ceremony.")
	var claim := pending_claim_for(game.world, character)
	return resolve(game, ledger, str(claim.get("id", "")), character, false)

## Explicit "Decline the Deep Watcher" from the chamber: refuses a pending
## claim, or -- for a participant who never invited it -- journals the offered
## marker (and the one-time world settlement) with no claim and no creature.
static func refuse(game: Object, ledger: RefCounted, character: String) -> Dictionary:
	if not preload("res://scripts/world/water_alpha_rewards.gd")._ready_host(game, ledger) or character.strip_edges().is_empty():
		return _refuse("not_ready", "The realm cannot settle that ceremony.")
	if not game.world.flags.has("water_guardian_freed"):
		return _refuse("tethered", "The Guardian is still tethered.")
	if not pending_claim_for(game.world, character).is_empty():
		return decline(game, ledger, character)
	if has_been_offered(game.world, character):
		return {"ok": true, "code": "already_resolved", "accepted": false}
	if not may_receive(character, participants(game.world), host_local_character(game), false):
		return _refuse("not_participant", "Only those who fought Captain Nerissa to free the Guardian receive its offer.")
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var sequence: int = ledger.seq
	var flags: Array = [offered_flag(character)]
	if is_legacy_world(game.world) and not game.world.flags.has(LEGACY_FLAG):
		flags.append(LEGACY_FLAG)
	flags.append_array(_settlement_flags(game.world))
	var ops: Array = []
	var committed := _commit_flags(game, ledger, flags, ops, before, revision, sequence)
	if not committed.ok:
		return committed
	if not game.save_system.save_world(game, game.world.world_id):
		_restore(game, ledger, before, revision, sequence)
		return _refuse("journal_failed", "Could not save your answer. Try again.")
	return {"ok": true, "code": "", "accepted": false, "delta": {"seq": ledger.seq, "realm": "water", "ops": ops}}
