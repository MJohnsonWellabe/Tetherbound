extends RefCounted

## Synchronous local half of a durable host capture claim. Caller acknowledges
## the host and clears pending_catch only after ok. Failed writes restore the
## exact live objects, including party selection and polling revisions.
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")

static func settle(game: Object, claim: Dictionary, pending: RefCounted, release_index: int = -1) -> Dictionary:
	if game == null or game.local == null or game.world == null:
		return {"ok": false, "reason": "Capture owner is unavailable."}
	var id: Variant = claim.get("id", "")
	if not id is String or id.is_empty() or str(claim.get("character_id", "")) != str(game.local.character_id) or str(claim.get("world_id", "")) != str(game.world.world_id):
		return {"ok": false, "reason": "Capture claim belongs to another character or world."}
	var receipt: String = "water_capture_receipt:" + id
	var flags: RefCounted = game.local.flags
	var party: RefCounted = game.local.party
	if flags.has(receipt):
		return {"ok": true, "already": true}
	if pending == null or not is_instance_of(pending, INSTANCE) or party.members().has(pending):
		return {"ok": false, "reason": "Pending capture is invalid or already owned."}
	if game.save_system == null or not game.save_system.has_method("save_character"):
		return {"ok": false, "reason": "Character save is unavailable."}
	if party.is_full() and (release_index < 0 or release_index > 5):
		return {"ok": false, "reason": "Choose one creature to release before accepting the capture."}
	var before: Array = party.members()
	var active: int = party.get("_active")
	var best: int = party.get("_best")
	var party_revision: int = party.revision
	var flag_data: Dictionary = flags.save_data()
	var flag_revision: int = flags.revision
	var skills: RefCounted = game.local.get("skills")
	var skills_before: Dictionary = skills.save_data() if skills != null else {}
	var skills_revision: int = int(skills.revision) if skills != null else 0
	var released: RefCounted = null
	if party.is_full():
		if release_index == 5:
			released = pending
		else:
			released = party.remove_at(release_index)
			party.add(pending)
			party.move(party.size() - 1, release_index)
			# The replacement occupies the chosen slot; other members retain
			# both order and selection. A released Best Creature loses its title.
			party.set("_active", active)
			party.set("_best", -1 if best == release_index else best)
	elif not party.add(pending):
		return {"ok": false, "reason": "The capture could not join the party."}
	flags.set_flag(receipt)
	if skills != null:
		preload("res://scripts/player/skills_activity.gd").new(skills).record_catch(id, true, true)
	if not game.save_system.save_character(game, str(game.local.character_id)):
		# No await occurs between mutation, persistence and rollback. Assigning
		# the original shallow list restores identities rather than decoding
		# new creatures and breaking references held by riding/combat.
		party.set("_creatures", before)
		party.set("_active", active)
		party.set("_best", best)
		party.revision = party_revision
		flags.load_data(flag_data)
		flags.revision = flag_revision
		if skills != null:
			skills.load_data(skills_before)
			skills.revision = skills_revision
		return {"ok": false, "reason": "The character could not be saved; the capture remains pending."}
	return {"ok": true, "already": false, "released": released}
