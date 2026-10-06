extends RefCounted

## A single capture record, using the same schema and reconstruction as saves.
## This adapter never touches a player's party or writes a file. The temporary
## decode Party is emptied before returning; it is not reserve creature storage.
const SAVE := preload("res://scripts/save/save_game.gd")
const PARTY := preload("res://autoload/party.gd")
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")

class SingleMember extends RefCounted:
	var creature: RefCounted
	func _init(value: RefCounted) -> void:
		creature = value
	func members() -> Array:
		return [creature]

static func encode(creature: RefCounted, character: Dictionary = {}) -> Dictionary:
	if creature == null or not is_instance_of(creature, INSTANCE):
		return {}
	var entries: Array = SAVE.new()._party_to_array(SingleMember.new(creature))
	var payload: Dictionary = entries[0]
	return payload if _valid(payload, character) else {}

## Portable owner records (character_record_rules.portable_projection) leave
## out each card's in-fight energy meter on purpose; every card shape this
## codec writes carries it. A card missing only that transient field decodes
## with an empty meter rather than failing as malformed.
static func _with_transient_energy(payload: Variant) -> Variant:
	if payload is Dictionary and not payload.has("energy"):
		var completed: Dictionary = payload.duplicate(true)
		completed.energy = 0.0
		return completed
	return payload

static func decode(payload: Variant, trait_record: Dictionary = {}) -> RefCounted:
	payload = _with_transient_energy(payload)
	if not _valid(payload) or (not trait_record.is_empty() and not valid_capture_traits(trait_record)):
		return null
	var temporary := PARTY.new()
	var character := {"creatures": {str(payload.uid): trait_record.duplicate(true)}} if not trait_record.is_empty() else {}
	if not trait_record.is_empty():
		# The source card is already validated above. Complete its transient
		# move mirror before the saved-party reader compares both carriers;
		# a trait-only mirror otherwise rejects every modern Alpha offer.
		character = TEACHING.character_loadout_mirror([payload], character)
	SAVE.new()._array_to_party([payload.duplicate(true)], temporary, character)
	var creature: RefCounted = temporary.remove_at(0) if temporary.members().size() == 1 else null
	if creature != null and not trait_record.is_empty():
		# Transient offer projection only. Durable ownership must install these
		# fields under this same UID in redesign_character.creatures.
		creature.set_meta("foundation_capture_traits", trait_record.duplicate(true))
	return creature

## Typed owner rows already contain the complete canonical UID mirror,
## including caught tiers. Its earned moves cannot be decoded as a tier-zero
## wild card. Validate both carriers before constructing the single member.
static func decode_owned(payload: Variant, character: Dictionary) -> RefCounted:
	payload = _with_transient_energy(payload)
	if not _valid(payload, character) or not character.get("creatures", {}).has(str(payload.get("uid", ""))) \
		or not SAVE.trait_party_errors([payload], character).is_empty(): return null
	var temporary := PARTY.new()
	SAVE.new()._array_to_party([payload.duplicate(true)], temporary, character)
	return temporary.remove_at(0) if temporary.members().size() == 1 else null

static func valid_capture_traits(raw: Variant) -> bool:
	if not raw is Dictionary or raw.size() != 4 or raw.get("traits_initialized") != true or not preload("res://scripts/creatures/traits.gd").trait_state_errors(raw).is_empty(): return false
	var source: Variant = raw.get("captured_from")
	return source is Dictionary and source.size() == 4 and source.get("kind") == "wild" \
		and preload("res://scripts/creatures/traits.gd").component(source.get("world_namespace")) \
		and preload("res://scripts/creatures/traits.gd").component(source.get("spawn_id")) \
		and preload("res://scripts/creatures/traits.gd").integer(source.get("spawn_generation"), 1, 2147483647)


static func _valid(payload: Variant, character: Dictionary = {}) -> bool:
	if not payload is Dictionary:
		return false
	# The canonical writer emits distinct complete legacy and initialized
	# loadout shapes. A blank instance describes only the former, while actual
	# species spawns can carry the latter even with new gameplay flags off.
	var schema: Dictionary = SAVE.new()._party_to_array(SingleMember.new(INSTANCE.new()))[0]
	var modern_template := INSTANCE.new()
	modern_template.loadout_initialized = true
	var modern_schema: Dictionary = SAVE.new()._party_to_array(SingleMember.new(modern_template))[0]
	if payload.size() == modern_schema.size(): schema = modern_schema
	if payload.size() != schema.size():
		return false
	for key: String in schema:
		if not payload.has(key):
			return false
		var value: Variant = payload[key]
		var expected := typeof(schema[key])
		if expected == TYPE_INT or expected == TYPE_FLOAT:
			if not (value is int or value is float) or not is_finite(float(value)):
				return false
			if expected == TYPE_INT and float(value) != floorf(float(value)):
				return false
		elif typeof(value) != expected:
			return false
	if not SPECIES.has(payload.species_id):
		return false
	# Exact shape/type checks precede semantic preflight. Partial, forged or
	# incompatible new loadout documents cannot fall back to legacy repair.
	if not TEACHING.party_loadout_errors([payload], character).is_empty(): return false
	for key: String in ["base_hp", "base_attack", "base_defence", "max_hp", "attack", "defence", "level"]:
		if float(payload[key]) <= 0.0:
			return false
	if float(payload.hp) < 0.0 or float(payload.hp) > float(payload.max_hp):
		return false
	if float(payload.swim_stamina_fraction) < 0.0 or float(payload.swim_stamina_fraction) > 1.0:
		return false
	return true
