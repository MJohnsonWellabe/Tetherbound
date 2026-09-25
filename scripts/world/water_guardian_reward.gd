extends RefCounted

## Freed-legendary offer for the Abyssal Guardian (CLAUDE.md, WORLD §2.3,
## BOSSES §4.12). The host owns ONE shared freeing and records a separate,
## once-only offer for EACH participant in the fight that freed it, bound to
## that participant's stable character. Each participant accepts or refuses
## independently; a non-participant receives nothing; no character is offered
## this world's Guardian twice.
##
## Participants (mirrors `stronghold_climax.gd::may_receive` + its journal
## reader, with one deliberate tightening):
##   * The characters with an ACCEPTED `world.reward_deliveries` row whose
##     source starts `trainer:water_trainer_nerissa:` -- Nerissa's defeat pays
##     every participant through the per-participant reward_grant journal, so
##     that journal is the durable answer to "who fought the freeing fight".
##   * When no such row exists (a solo world, or a world whose Nerissa payout
##     predates delivery rows) the ONLY participant is the host's own local
##     character. Unlike the Meadows reader, an empty set is NOT "anyone": in
##     co-op an unidentified guest must not qualify by default.
##
## Offer ids are sha256(world_id + ":guardian:" + character_id). The world flag
## `water_claim:guardian:offered:<sha256(character)>` (declared world prefix
## `water_claim:`) is written in the same journal as the claim and marks that
## the character has been offered its Guardian; it survives the claim's
## removal, so a resolved (accepted OR refused) character is never offered a
## second one. A reconnecting character with a still-pending claim receives
## that same claim again (idempotent replay, no write).
##
## World restoration (`water_guardian_settled`, `water_currents_restored`,
## `realm_relic_water_earned`) settles exactly once for the world, on the FIRST
## participant resolution, accept or refuse (BOSSES §4.11: "No relic or
## Guardian is delivered until the player deliberately releases and resolves
## the offer"; §4.12: "refusal still settles the offer"). It never depends on
## any particular participant accepting, and later resolutions write nothing.
##
## `water_guardian_claimed` is kept only as a world-level "an offer has been
## made" marker for existing readers; it no longer locks anyone out.
##
## Legacy (single-recipient) worlds: their claim id was sha256(world_id +
## ":guardian"). A pending legacy claim is found by its character and replayed.
## An already-acknowledged legacy recipient is recognised on their own
## character by `water_capture_receipt:<legacy id>` (see `already_received`),
## so a new offer to them is acknowledged without granting a duplicate. Other
## participants in such worlds receive their own offer under the new rule;
## world restoration already happened and is not written again.
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const TRAINER_ID := "water_trainer_nerissa"
const OFFERED_PREFIX := "water_claim:guardian:offered:"
const RECEIPT_PREFIX := "water_capture_receipt:"
const CLAIMED := "water_guardian_claimed"
const SETTLEMENT := ["water_guardian_settled", "water_currents_restored", "realm_relic_water_earned"]

static func claim_id(world_id: String, character_id: String) -> String:
	return (world_id + ":guardian:" + character_id).sha256_text()

static func legacy_claim_id(world_id: String) -> String:
	return (world_id + ":guardian").sha256_text()

static func offered_flag(character_id: String) -> String:
	return OFFERED_PREFIX + character_id.sha256_text()

## Characters with an accepted Nerissa reward delivery in this world.
static func participants(world: RefCounted) -> Array:
	var out: Array = []
	var deliveries: Variant = world.get("reward_deliveries") if world != null else null
	if not deliveries is Dictionary:
		return out
	var prefix := "trainer:%s:" % TRAINER_ID
	for raw: Variant in (deliveries as Dictionary).values():
		if not raw is Dictionary or not str(raw.get("source", "")).begins_with(prefix) \
				or str(raw.get("status", "")) != "accepted":
			continue
		var character := str(raw.get("character_id", ""))
		if not character.is_empty() and not out.has(character):
			out.append(character)
	return out

## Pure rule, testable without a world.
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

## True when this character already resolved its Guardian or still holds an
## unresolved offer in this world (host view).
static func has_been_offered(world: RefCounted, character_id: String) -> bool:
	return world != null and not character_id.is_empty() and world.flags.has(offered_flag(character_id))

static func pending_claim_for(world: RefCounted, character_id: String) -> Dictionary:
	for raw: Variant in world.water_capture_claims.values():
		if raw is Dictionary and str(raw.get("source", "")) == "guardian" \
				and str(raw.get("character_id", "")) == character_id \
				and str(raw.get("world_id", "")) == str(world.world_id):
			return raw
	return {}

## Character-side guard: this character already owns its receipt for this
## claim, or received the single legacy offer in this same world.
static func already_received(flags: RefCounted, claim: Dictionary) -> bool:
	if flags == null:
		return false
	if flags.has(RECEIPT_PREFIX + str(claim.get("id", ""))):
		return true
	return str(claim.get("source", "")) == "guardian" \
		and flags.has(RECEIPT_PREFIX + legacy_claim_id(str(claim.get("world_id", ""))))

static func _refuse(code: String, reason: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": reason}

static func _restore(game: Object, ledger: RefCounted, before: Dictionary, revision: int, sequence: int) -> void:
	game.world.load_data(before)
	game.world.revision = revision
	ledger.seq = sequence

static func release(game: Object, ledger: RefCounted) -> Dictionary:
	if not preload("res://scripts/world/water_alpha_rewards.gd")._ready_host(game, ledger) or not game.world.flags.has("water_captain_nerissa_defeated"):
		return {"ok": false, "reason": "The captain still controls the tether."}
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var sequence: int = ledger.seq
	var ops: Array = []
	for flag: String in ["water_tether_disabled", "water_guardian_freed"]:
		var verdict: Dictionary = ledger.commit({"kind": "set_world_flag", "realm": "water", "id": flag}, 1)
		if not verdict.get("ok", false):
			_restore(game, ledger, before, revision, sequence)
			return verdict
		ops.append_array(verdict.delta.ops)
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
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var sequence: int = ledger.seq
	var ops: Array = []
	var flags: Array = [offered_flag(character)]
	if not game.world.flags.has(CLAIMED):
		flags.append(CLAIMED)
	for flag: String in flags:
		var verdict: Dictionary = ledger.commit({"kind": "set_world_flag", "realm": "water", "id": flag}, 1)
		if not verdict.get("ok", false):
			_restore(game, ledger, before, revision, sequence)
			return verdict
		ops.append_array(verdict.delta.ops)
	var id := claim_id(game.world.world_id, character)
	game.world.water_capture_claims[id] = {"id": id, "source": "guardian", "world_id": game.world.world_id,
		"character_id": character, "creature": payload}
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
	if not game.world.flags.has(SETTLEMENT[0]):
		for flag: String in SETTLEMENT:
			if not game.world.flags.has(flag):
				flags.append(flag)
	var ops: Array = []
	for flag: String in flags:
		var verdict: Dictionary = ledger.commit({"kind": "set_world_flag", "realm": "water", "id": flag}, 1)
		if not verdict.get("ok", false):
			_restore(game, ledger, before, revision, sequence)
			return verdict
		ops.append_array(verdict.delta.ops)
	game.world.water_capture_claims.erase(id)
	if not game.save_system.save_world(game, game.world.world_id):
		_restore(game, ledger, before, revision, sequence)
		return _refuse("journal_failed", "Could not save the ceremony. Try again.")
	return {"ok": true, "code": "", "accepted": accepted, "delta": {"seq": ledger.seq, "realm": "water", "ops": ops}}

## Refusal path a UI can call (via WaterCaptureClaims.decline_pending on the
## character's peer). The Guardian is not granted; the offer is settled.
static func decline(game: Object, ledger: RefCounted, character: String) -> Dictionary:
	if game == null or game.get("world") == null:
		return _refuse("not_ready", "The realm cannot settle that ceremony.")
	var claim := pending_claim_for(game.world, character)
	return resolve(game, ledger, str(claim.get("id", "")), character, false)
