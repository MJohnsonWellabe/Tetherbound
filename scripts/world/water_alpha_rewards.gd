extends RefCounted

## Host-only Aquaryn result journal. Caller supplies identities captured by its
## validated encounter, NEVER identities or an outcome from a client request.
## All mutation uses the existing WorldLedger. Nothing is published until the
## complete outcome/entitlement set has reached SaveGame.save_world().
## Returned deltas must be delivered through the existing ledger transport;
## player ops need its local application too, including in offline play.
const RESOLVED := "water_aquaryn_resolved"
const STONE := "water_swim_stone_earned"
const PREFIX := "water_claim:alpha:aquaryn:"

static func entitlement(character_id: String) -> String:
	return PREFIX + "entitled:" + character_id.sha256_text()

static func outcome_flag(outcome: String) -> String:
	return PREFIX + "outcome:" + outcome

static func _refuse(code: String) -> Dictionary:
	return {"ok": false, "code": code, "delta": {"ops": []}}

static func _ready_host(game: Object, ledger: RefCounted) -> bool:
	return game != null and game.has_method("is_host") and bool(game.call("is_host")) \
		and ledger != null and ledger.get("world") == game.get("world") \
		and game.get("world") != null and not str(game.get("world").world_id).is_empty() \
		and game.get("save_system") != null

## One synchronous transaction: no signal/RPC/await between the first mutation
## and the disk journal. A repeated resolution cannot append late bystanders.
static func resolve(game: Object, ledger: RefCounted, outcome: String, characters: Array, capture: Dictionary = {}) -> Dictionary:
	if not _ready_host(game, ledger):
		return _refuse("not_host_or_ready")
	if outcome not in ["won", "caught"]:
		return _refuse("not_a_victory")
	var eligible: Array[String] = []
	for raw: Variant in characters:
		if not raw is String or raw.is_empty() or raw.strip_edges() != raw:
			return _refuse("invalid_character")
		if not eligible.has(raw):
			eligible.append(raw)
	if eligible.is_empty():
		return _refuse("no_participants")
	var world: RefCounted = ledger.get("world")
	if world.flags.has(RESOLVED):
		return {"ok": true, "code": "already_resolved", "delta": {"ops": []}}
	var before: Dictionary = world.save_data()
	var before_revision: int = world.revision
	var before_sequence: int = ledger.seq
	if outcome == "caught":
		if capture.is_empty() or not eligible.has(str(capture.get("character_id", ""))) \
				or str(capture.get("world_id", "")) != world.world_id \
				or str(capture.get("creature", {}).get("species_id", "")) != "water_aquaryn":
			return _refuse("missing_capture_claim")
		world.water_capture_claims[str(capture.id)] = capture.duplicate(true)
	var ops: Array = []
	var flags: Array[String] = [RESOLVED, outcome_flag(outcome)]
	for character: String in eligible:
		flags.append(entitlement(character))
	for flag: String in flags:
		var verdict: Dictionary = ledger.commit({"kind": "set_world_flag", "realm": "water", "id": flag}, 1)
		if not bool(verdict.get("ok", false)):
			world.load_data(before)
			world.revision = before_revision
			ledger.seq = before_sequence
			return _refuse("ledger_refused")
		ops.append_array(verdict.delta.ops)
	if not bool(game.get("save_system").save_world(game, world.world_id)):
		world.load_data(before)
		world.revision = before_revision
		ledger.seq = before_sequence
		return _refuse("journal_failed")
	return {"ok": true, "code": "", "delta": {"seq": ledger.seq, "realm": "water", "ops": ops}}

static func capture_claim(world_id: String, character: String, creature: Dictionary) -> Dictionary:
	return {"id": (world_id + ":aquaryn").sha256_text(), "world_id": world_id,
		"character_id": character, "creature": creature.duplicate(true)}

static func entitled(world: RefCounted, character_id: String) -> bool:
	return world != null and not character_id.is_empty() and world.flags.has(RESOLVED) \
		and world.flags.has(entitlement(character_id))

## character_id and peer_id MUST come from the host's current session registry.
## The durable entitlement deliberately has no consumed bit: a lost packet or
## reconnect with a new peer ID re-delivers this idempotent personal flag. No
## inventory item is granted, so a full bag cannot destroy the traversal unlock.
static func grant(game: Object, ledger: RefCounted, character_id: String, peer_id: int) -> Dictionary:
	if not _ready_host(game, ledger):
		return _refuse("not_host_or_ready")
	if peer_id <= 0 or not entitled(ledger.world, character_id):
		return _refuse("not_entitled")
	return ledger.commit({"kind": "grant_player_flag", "realm": "water", "id": STONE, "peers": [peer_id]}, 1)
