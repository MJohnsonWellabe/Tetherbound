extends RefCounted

## The existing regional monument rule has one world settlement and a personal
## recipient. First valid ceremony interaction reserves the freed Guardian;
## reconnect resumes that exact character's five-slot choice.
const CODEC := preload("res://scripts/save/water_capture_codec.gd")

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
			game.world.load_data(before)
			game.world.revision = revision
			ledger.seq = sequence
			return verdict
		ops.append_array(verdict.delta.ops)
	if not game.save_system.save_world(game, game.world.world_id):
		game.world.load_data(before)
		game.world.revision = revision
		ledger.seq = sequence
		return {"ok": false, "reason": "Could not save the release. Try again."}
	return {"ok": true, "delta": {"seq": ledger.seq, "realm": "water", "ops": ops}}

static func begin(game: Object, ledger: RefCounted, character: String, creature: RefCounted) -> Dictionary:
	if not preload("res://scripts/world/water_alpha_rewards.gd")._ready_host(game, ledger) or character.strip_edges().is_empty():
		return {"ok": false, "reason": "The realm cannot begin that ceremony."}
	if not game.world.flags.has("water_guardian_freed"):
		return {"ok": false, "reason": "The Guardian is still tethered."}
	var id: String = (game.world.world_id + ":guardian").sha256_text()
	if game.world.flags.has("water_guardian_claimed"):
		var existing: Dictionary = game.world.water_capture_claims.get(id, {})
		return {"ok": str(existing.get("character_id", "")) == character,
			"reason": "The Guardian's companionship has already been offered."}
	var payload := CODEC.encode(creature)
	if str(payload.get("species_id", "")) != "water_abyssal_guardian":
		return {"ok": false, "reason": "The Guardian is not ready."}
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var sequence: int = ledger.seq
	var result: Dictionary = ledger.commit({"kind": "set_world_flag", "realm": "water", "id": "water_guardian_claimed"}, 1)
	if not result.get("ok", false):
		return result
	game.world.water_capture_claims[id] = {"id": id, "source": "guardian", "world_id": game.world.world_id,
		"character_id": character, "creature": payload}
	if not game.save_system.save_world(game, game.world.world_id):
		game.world.load_data(before)
		game.world.revision = revision
		ledger.seq = sequence
		return {"ok": false, "reason": "Could not save the ceremony. Try again."}
	return result
