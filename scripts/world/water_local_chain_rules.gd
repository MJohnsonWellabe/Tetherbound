extends RefCounted
## Host rule for F13 Tidewake local-chain steps (data/config/water_local_chains.json).
##
## A step is committed through the existing `water_dock_action` intent: the
## host's ledger bridge resolves the actor's peer, stable character id, realm
## and position (never trusting the request), and `water_dock_rules.gd`
## delegates any action id named here to `evaluate()`. That intent is already a
## durable world transaction (the world file is saved before publication), so
## chain records survive save/reconnect exactly like dock repairs.
##
## Records are WORLD facts under the declared world prefix `water_claim:`
## (`water_claim:local:<chain>:<step>`): one person's lead or report advances
## the chain for everyone in this world. Per-character payoffs stay the pocket
## rows' own receipts (`water_claim:<character>:<row id>`), which a step may
## require of THE REPORTING character through `requires_character_claims`.
const DATA := "res://data/config/water_local_chains.json"
const CAST := "res://data/config/water_characters.json"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")


static func load_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	return parsed if parsed is Dictionary else {}


static func step(id: String) -> Dictionary:
	for row: Variant in load_data().get("steps", []):
		if row is Dictionary and str((row as Dictionary).get("id", "")) == id:
			return row
	return {}


static func has_step(id: String) -> bool:
	return not id.is_empty() and not step(id).is_empty()


static func steps_for_chain(chain: String) -> Array:
	var out: Array = []
	for row: Variant in load_data().get("steps", []):
		if row is Dictionary and str((row as Dictionary).get("chain", "")) == chain:
			out.append(row)
	return out


## Horizontal standing point the host measures a step from. Speech steps use
## the speaker's authored placement (island centre + island-local offset, the
## same numbers `water_scene_npcs.gd` places the body with).
static func step_xz(row: Dictionary) -> Vector2:
	if str(row.get("kind", "")) == "speech":
		var cast: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAST))
		if not cast is Dictionary:
			return Vector2.INF
		for spec: Variant in (cast as Dictionary).get("npcs", []):
			if spec is Dictionary and str(spec.get("id", "")) == str(row.get("npc", "")):
				return _island_point(str(spec.island_id), spec.island_local_offset)
		return Vector2.INF
	var at: Variant = row.get("at_xz", [])
	if at is Array and (at as Array).size() == 2:
		return Vector2(float(at[0]), float(at[1]))
	return Vector2.INF


static func _island_point(island_id: String, offset: Variant) -> Vector2:
	if not offset is Array or (offset as Array).size() < 3:
		return Vector2.INF
	for island: Dictionary in FIELD.load_config().get("islands", []):
		if str(island.id) == island_id:
			return Vector2(float(island.center_xz_m[0]) + float(offset[0]),
				float(island.center_xz_m[1]) + float(offset[2]))
	return Vector2.INF


## Host reach from the step's standing point: speech steps measure from the
## speaker, site steps from their prop (the prompt's own radius plus slack).
static func reach_m(row: Dictionary) -> float:
	var data := load_data()
	if str(row.get("kind", "")) == "speech":
		return float(data.get("speech_radius_m", 6.0))
	return float(data.get("site_radius_m", 4.8))


## Species the live catalogue marks swim-mount compatible (the same
## `swim_mount.compatible` MountedSwimming reads; Water's roster registers them
## as `water_<species>`). A step's `requires_swimmer_or_flags` accepts one of
## these in the requester's party proof, or any of the named world flags.
static func swimmer_species() -> Array:
	var out: Array = []
	for id: Variant in SPECIES.table():
		if bool(SPECIES.definition(str(id)).get("swim_mount", {}).get("compatible", false)):
			out.append(str(id))
	return out


## Party proof is a client claim under the portable-character trust model (the
## same as dock inventory counts): an Array of species id Strings. Anything
## else proves nothing.
static func has_swimmer(party_species: Variant) -> bool:
	if not party_species is Array:
		return false
	var swimmers := swimmer_species()
	for species: Variant in party_species:
		if species is String and swimmers.has(species):
			return true
	return false


static func swimmer_condition_met(row: Dictionary, flags: Variant, party_species: Variant) -> bool:
	var alternatives: Variant = row.get("requires_swimmer_or_flags", null)
	if not alternatives is Array:
		return true
	for flag: Variant in alternatives:
		if flags != null and flags.has(str(flag)):
			return true
	return has_swimmer(party_species)


static func receipt(character: String, row_id: String) -> String:
	return "water_claim:" + character + ":" + row_id


## Everything a step needs from the world store and the actor, without position
## or inventory: what a scene prompt asks before it offers the action.
static func prerequisites_met(row: Dictionary, flags: Variant) -> bool:
	if flags == null:
		return false
	for flag: Variant in row.get("requires_flags", []):
		if not flags.has(str(flag)):
			return false
	return true


static func evaluate(intent: Dictionary, context: Dictionary, flags: Variant) -> Dictionary:
	var row := step(str(intent.get("action_id", "")))
	if row.is_empty():
		return _refuse("unknown_action", "That action is not available.")
	if str(context.get("realm", "")) != "water" or str(intent.get("realm", "")) != "water":
		return _refuse("wrong_realm", "Reach Tidewake first.")
	var actor := int(context.get("peer", 0))
	var character := str(context.get("character_id", ""))
	if actor <= 0 or character.is_empty():
		return _refuse("unknown_character", "Your character is not connected.")
	if flags == null:
		return _refuse("malformed", "The world record could not be checked.")
	var position: Variant = context.get("position")
	var target := step_xz(row)
	var radius := reach_m(row)
	if not position is Vector3 or not (position as Vector3).is_finite() or not target.is_finite() \
			or Vector2(position.x, position.z).distance_to(target) > radius:
		return _refuse("too_far", "Move closer first.")
	var flag := str(row.get("flag", ""))
	if flag.is_empty():
		return _refuse("malformed", "That step records nothing.")
	if flags.has(flag):
		return _refuse("already_done", str(row.get("done_reason", "That is already recorded in this world.")))
	if not prerequisites_met(row, flags):
		return _refuse("prerequisite", str(row.get("refusal", "Something else must happen first.")))
	for claim: Variant in row.get("requires_character_claims", []):
		if not flags.has(receipt(character, str(claim))):
			return _refuse("claim", str(row.get("claim_refusal", "Collect what you were sent for first.")))
	if not swimmer_condition_met(row, flags, intent.get("party_species", [])):
		return _refuse("swimmer", str(row.get("swimmer_refusal", "Bring a swimmer of your own first.")))
	var ops: Array = []
	for extra: Variant in row.get("also_records", []):
		if not flags.has(str(extra)):
			ops.append(_flag_op(str(extra)))
	ops.append(_flag_op(flag))
	# A grant is paid once: the step's own world record is its receipt and its
	# txn id, committed in the same delta.
	var grant: Variant = row.get("grant", {})
	if grant is Dictionary:
		for item: String in grant:
			ops.append({"op": "item_grant", "scope": "player", "peers": [actor], "item": item,
				"count": int(grant[item]), "txn_id": flag})
	return {"ok": true, "code": "", "reason": "", "ops": ops}


static func _flag_op(id: String) -> Dictionary:
	return {"op": "flag", "scope": "world", "realm": "water", "id": id, "value": true}


static func _refuse(code: String, reason: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": reason, "ops": []}
