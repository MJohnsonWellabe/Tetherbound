extends RefCounted

## A single capture record, using the same schema and reconstruction as saves.
## This adapter never touches a player's party or writes a file. The temporary
## decode Party is emptied before returning; it is not reserve creature storage.
const SAVE := preload("res://scripts/save/save_game.gd")
const PARTY := preload("res://autoload/party.gd")
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

class SingleMember extends RefCounted:
	var creature: RefCounted
	func _init(value: RefCounted) -> void:
		creature = value
	func members() -> Array:
		return [creature]

static func encode(creature: RefCounted) -> Dictionary:
	if creature == null or not is_instance_of(creature, INSTANCE):
		return {}
	var entries: Array = SAVE.new()._party_to_array(SingleMember.new(creature))
	var payload: Dictionary = entries[0]
	return payload if _valid(payload) else {}

static func decode(payload: Variant) -> RefCounted:
	if not _valid(payload):
		return null
	var temporary := PARTY.new()
	SAVE.new()._array_to_party([payload.duplicate(true)], temporary)
	return temporary.remove_at(0) if temporary.members().size() == 1 else null

static func _valid(payload: Variant) -> bool:
	if not payload is Dictionary:
		return false
	# Derive types/fields from the canonical writer so additions cannot silently
	# disappear from captures. Capture records are new records, not legacy saves.
	var schema: Dictionary = SAVE.new()._party_to_array(SingleMember.new(INSTANCE.new()))[0]
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
	for key: String in ["base_hp", "base_attack", "base_defence", "max_hp", "attack", "defence", "level"]:
		if float(payload[key]) <= 0.0:
			return false
	if float(payload.hp) < 0.0 or float(payload.hp) > float(payload.max_hp):
		return false
	if float(payload.swim_stamina_fraction) < 0.0 or float(payload.swim_stamina_fraction) > 1.0:
		return false
	return true
