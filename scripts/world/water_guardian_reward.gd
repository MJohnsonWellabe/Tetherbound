extends RefCounted

## AUTHORITY DEPENDENCY -- OPEN F14 BLOCKER (not fixable inside this file's
## ownership; ledger_rpc.gd / world_ledger.gd are shared). Every rule below is
## enforced only for intents that reach begin()/refuse()/resolve(). The generic
## ledger path accepts ANY peer's intent: ledger_rpc.gd:446-460 `_rpc_intent`
## (any_peer) -> `_commit_here` (ledger_rpc.gd:283) -> world_ledger.gd:168
## `set_world_flag` -> `_set_world_flag` (world_ledger.gd:569-581), which checks
## neither the flag's owner nor the sender, and accepts `value: false`. A client
## can therefore write or CLEAR `water_guardian_freed`, the settlement flags,
## `water_claim:guardian:offered:<hash>` (deny another participant's offer, or
## erase its own answer), LEGACY_FLAG and legacy recipient markers. Likewise
## `reward_grant`: ledger_rpc.gd:295-298 + `_reward_recipients`
## (ledger_rpc.gd:367-392) take the client's `source` and `peers`, and
## world_ledger.gd:646 `_reward_grant` journals any source, so a client can
## mint a `trainer:water_trainer_nerissa:` delivery row and become a
## "participant" below. Until the shared ledger refuses client-originated
## writes to host-owned ids (Guardian/`water_claim:` flags, trainer reward
## sources), the participant and once-only guarantees hold only against honest
## clients.
##
## PARTICIPANT RECORDING -- OPEN F14 BLOCKER (needs encounter_director.gd, a
## shared file). Participant rows below exist ONLY for host-run Nerissa fights:
## `_record_trainer_defeat_for_the_session` journals a per-participant
## `reward_grant` only on the host. A guest-run Nerissa fight pays the guest
## through the solo path and currently yields NO participant rows, so the
## host-local fallback below applies to it: the host's own character is
## treated as the one participant and the guest who actually fought is not.
## That is a known open defect, not fixed here.
##
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
##   * Only when there is NO such row at all AND the session is SOLO (a solo
##     world, or a world whose Nerissa payout predates delivery rows) is the
##     host's own local character the one participant. Unlike the Meadows
##     reader, an empty set is NOT "anyone": in co-op an unidentified guest
##     must not qualify. INTERIM (same rule as F05): in a MULTI-PEER session
##     an empty journal offers NOBODY -- a guest may have fought Nerissa alone
##     on its own client (no rows), and the host who did not fight must not be
##     presumed the participant. The real fix journals client-run wins on the
##     host (branch ralph/trainer-participants-host). A host left solo after
##     such a guest disconnects is still treated as solo (disclosed gap).
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
## Exception (conservative, see Legacy below): a PRE-F14 receipt cannot name
## its instance, so a legacy receipt for the same world_id blocks the offer.
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
## made" marker for existing readers; outside legacy worlds (below) it no
## longer locks anyone out.
##
## Legacy (single-recipient) worlds -- CONSERVATIVE, never a second Guardian.
## The pre-F14 model made ONE offer per world: begin() set
## `water_guardian_claimed` and a claim with id sha256(world_id + ":guardian"),
## and the acknowledgement erased that claim and set the settlement flags. It
## never recorded per-character markers, so once its claim is erased such a
## world cannot say who received the Guardian (the recipient's character only
## holds `water_capture_receipt:<legacy id>`, which the host cannot see for a
## guest). A world is a legacy world (is_legacy_world) when LEGACY_FLAG is set,
## its legacy claim is still pending, or `water_guardian_claimed` / any
## settlement flag is set with no per-character offer marker. In a legacy
## world:
##   * begin() NEVER mints a Guardian offer for anyone (code `legacy_world`);
##     the only Guardian interaction is the replay and resolution of a still-
##     pending legacy claim for its own recipient;
##   * refuse() writes nothing for a character without that pending claim;
##   * resolving the pending legacy claim journals the recipient's offered
##     marker, LEGACY_FLAG (sticky: the world stays legacy) and
##     `water_claim:guardian:legacy_recipient:<sha256(character)>`;
##     restoration already happened and is not written again.
## Character side (already_received): a character holding the legacy receipt
## `water_capture_receipt:<sha256(claim.world_id + ":guardian")>` is treated
## as having ALREADY RECEIVED any Guardian claim naming that world_id; its
## claim is acknowledged with no creature, so a legacy recipient can never be
## given a second Guardian even where the host could not identify it.
##
## OPEN OWNER QUESTION (unresolved, NOT granted here): whether the OTHER
## participants of a legacy world's freeing should later receive their own
## offers, and whether a legacy receipt that came from a DIFFERENT slot-0
## world (the bare receipt cannot say which world issued it) should still
## block that character's offer in this one. Both are withheld until an owner
## ruling; the cost of this default is that such characters get no offer.
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const TRAINER_ID := "water_trainer_nerissa"
const OFFERED_PREFIX := "water_claim:guardian:offered:"
const LEGACY_FLAG := "water_claim:guardian:legacy_offer"
const LEGACY_RECIPIENT_PREFIX := "water_claim:guardian:legacy_recipient:"
const WORLD_IDENTITY := preload("res://scripts/save/world_identity.gd")
## Edda's ceremony speech (water_characters.json / water.json).
const EDDA_ID := "water_edda"
const EDDA_OFFER := "water_edda_guardian_offer"
const EDDA_NEUTRAL := "water_edda_guardian_neutral"
const EDDA_POST := "water_edda_post"
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

static func legacy_recipient_flag(character_id: String) -> String:
	return LEGACY_RECIPIENT_PREFIX + character_id.sha256_text()

## Journal the recipient of a still-pending legacy claim when that claim is
## answered (resolve(); header: Legacy). Provenance only: no offer depends on it.
static func _legacy_observation_flags(world: RefCounted) -> Array:
	var legacy: Variant = world.water_capture_claims.get(legacy_claim_id(str(world.world_id)), {})
	var recipient := str((legacy as Dictionary).get("character_id", "")) if legacy is Dictionary else ""
	if recipient.is_empty() or world.flags.has(legacy_recipient_flag(recipient)):
		return []
	return [legacy_recipient_flag(recipient)]

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
## "no Nerissa row exists at all": solo, only the host's local character
## qualifies; in a multi-peer session nobody does (header: Participants).
static func may_receive(character_id: String, participant_characters: Array,
		host_local_character: String, already_resolved: bool, multi_peer: bool = false) -> bool:
	if already_resolved or character_id.is_empty():
		return false
	if not participant_characters.is_empty():
		return participant_characters.has(character_id)
	return not multi_peer and character_id == host_local_character

## Whether somebody else is in this game's session (false solo / no session).
static func is_multi_peer(game: Object) -> bool:
	return game != null and game.has_method("is_multi_peer") and bool(game.call("is_multi_peer"))

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
	if is_legacy_world(game.world):
		# No new offers in a legacy world; only a still-pending legacy claim.
		return not pending_claim_for(game.world, character).is_empty()
	var found := participants(game.world)
	if not found.is_empty():
		return found.has(character)
	return game.has_method("is_host") and bool(game.call("is_host")) and not is_multi_peer(game)

## True when this character already resolved its Guardian or still holds an
## unresolved offer in this world (any peer's view of the world flags).
## Which conversation Edda opens for this peer's own character: the offer only
## for a character that may still answer (or holds its pending claim here), a
## neutral line for anyone else once the Guardian is free (her ordinary
## post-restoration greeting once the currents are restored), and "" (the
## cast's ordinary greeting) before the freeing. Presentation only; the host
## still decides.
static func edda_conversation(game: Object, holds_pending_claim: bool) -> String:
	if game == null or game.get("world") == null or not game.world.flags.has("water_guardian_freed"):
		return ""
	if holds_pending_claim or local_may_answer(game):
		return EDDA_OFFER
	return EDDA_POST if game.world.flags.has("water_currents_restored") else EDDA_NEUTRAL

## Routes Edda's greet prompt through edda_conversation(): the cast's own
## dialogue guards read flags only and cannot express "this character may still
## answer". Her other conversations are unchanged (requested "" = cast's pick).
static func gate_edda_offer(cast: Node, bodies: Dictionary, game: Object) -> void:
	var body: Object = bodies.get(EDDA_ID)
	var prompt: Object = body.call("prompt_node") if body != null and body.has_method("prompt_node") else null
	if cast == null or prompt == null or not prompt.has_signal("activated"):
		return
	for connection: Dictionary in prompt.get_signal_connection_list("activated"):
		var target: Callable = connection.callable
		if target.get_object() == cast:
			prompt.disconnect("activated", target)
	prompt.connect("activated", func() -> void:
		var ledger: Variant = game.get("ledger")
		var claims: Node = (ledger as Node).get_node_or_null("WaterCaptureClaims") if ledger is Node else null
		var holds := claims != null and not str(claims.call("pending_guardian_id")).is_empty()
		cast.call("start_conversation", EDDA_ID, edda_conversation(game, holds)))

static func has_been_offered(world: RefCounted, character_id: String) -> bool:
	return world != null and not character_id.is_empty() and world.flags.has(offered_flag(character_id))

static func pending_claim_for(world: RefCounted, character_id: String) -> Dictionary:
	for raw: Variant in world.water_capture_claims.values():
		if raw is Dictionary and str(raw.get("source", "")) == "guardian" \
				and str(raw.get("character_id", "")) == character_id \
				and str(raw.get("world_id", "")) == str(world.world_id):
			return raw
	return {}

## This world instance made a pre-F14 single-recipient offer (header: Legacy).
## An old-model world that already claimed OR settled its Guardian carries
## `water_guardian_claimed` and/or the settlement flags but no per-character
## offer marker; the new model always journals an offer marker with either.
static func is_legacy_world(world: RefCounted) -> bool:
	if world == null:
		return false
	if world.flags.has(LEGACY_FLAG) or world.water_capture_claims.has(legacy_claim_id(str(world.world_id))):
		return true
	var old_model_marker: bool = world.flags.has(CLAIMED)
	for flag: String in SETTLEMENT:
		old_model_marker = old_model_marker or world.flags.has(flag)
	if not old_model_marker:
		return false
	for flag: Variant in world.flags.all_set():
		if str(flag).begins_with(OFFERED_PREFIX):
			return false
	return true

## Character-side guard: this character already owns its receipt for this
## claim, or holds the pre-F14 receipt for a Guardian of this claim's world_id.
## Conservative (header: Legacy): the bare legacy receipt cannot name its world
## instance, so it blocks every Guardian claim naming that world_id rather than
## risk a second Guardian for a legacy recipient.
static func already_received(flags: RefCounted, claim: Dictionary) -> bool:
	if flags == null:
		return false
	if flags.has(RECEIPT_PREFIX + str(claim.get("id", ""))):
		return true
	return str(claim.get("source", "")) == "guardian" \
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
	# Identity before any claim can be minted, so a live host never keys a claim
	# on the slot locator (a failed journal below restores it as well).
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var sequence: int = ledger.seq
	WORLD_IDENTITY.ensure(game.world)
	if not game.world.flags.has("water_guardian_freed"):
		return _refuse("tethered", "The Guardian is still tethered.")
	var existing := pending_claim_for(game.world, character)
	if not existing.is_empty():
		# Reconnect/replay: the same character's unresolved offer, unchanged.
		return {"ok": true, "code": "replay", "id": str(existing.id)}
	if has_been_offered(game.world, character):
		return _refuse("already_resolved", "You have already answered the Guardian's offer in this world.")
	if is_legacy_world(game.world):
		# Conservative (header: Legacy): never a new Guardian offer here.
		_restore(game, ledger, before, revision, sequence)
		return _refuse("legacy_world", "The Guardian's companionship was already given in this world.")
	if not may_receive(character, participants(game.world), host_local_character(game), false, is_multi_peer(game)):
		return _refuse("not_participant", "Only those who fought Captain Nerissa to free the Guardian receive its offer.")
	var payload := CODEC.encode(creature)
	if str(payload.get("species_id", "")) != "water_abyssal_guardian":
		return _refuse("not_ready", "The Guardian is not ready.")
	var ops: Array = []
	var flags: Array = [offered_flag(character)]
	if not game.world.flags.has(CLAIMED):
		flags.append(CLAIMED)
	var committed := _commit_flags(game, ledger, flags, ops, before, revision, sequence)
	if not committed.ok:
		return committed
	var instance := world_instance(game.world)
	var id := claim_id(instance, character)
	var claim := {"id": id, "source": "guardian", "world_id": game.world.world_id,
		"world_instance": instance, "character_id": character, "creature": payload}
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
	flags.append_array(_legacy_observation_flags(game.world))
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
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var sequence: int = ledger.seq
	WORLD_IDENTITY.ensure(game.world) # same rule as begin(); restored on failure
	if not game.world.flags.has("water_guardian_freed"):
		return _refuse("tethered", "The Guardian is still tethered.")
	if not pending_claim_for(game.world, character).is_empty():
		return decline(game, ledger, character)
	if has_been_offered(game.world, character):
		return {"ok": true, "code": "already_resolved", "accepted": false}
	if is_legacy_world(game.world):
		# Nothing offered here, so nothing to refuse (header: Legacy).
		_restore(game, ledger, before, revision, sequence)
		return _refuse("legacy_world", "The Guardian's companionship was already given in this world.")
	if not may_receive(character, participants(game.world), host_local_character(game), false, is_multi_peer(game)):
		return _refuse("not_participant", "Only those who fought Captain Nerissa to free the Guardian receive its offer.")
	var flags: Array = [offered_flag(character)]
	flags.append_array(_settlement_flags(game.world))
	var ops: Array = []
	var committed := _commit_flags(game, ledger, flags, ops, before, revision, sequence)
	if not committed.ok:
		return committed
	if not game.save_system.save_world(game, game.world.world_id):
		_restore(game, ledger, before, revision, sequence)
		return _refuse("journal_failed", "Could not save your answer. Try again.")
	return {"ok": true, "code": "", "accepted": false, "delta": {"seq": ledger.seq, "realm": "water", "ops": ops}}
