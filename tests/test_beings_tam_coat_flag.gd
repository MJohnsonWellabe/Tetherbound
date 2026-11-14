extends "res://tests/test_case.gd"

## BEINGS-TAM-COAT (F38#16): appearance variant `beings_meadows_tam_coat`, OFF
## until GPU-judged. Tam's tournament coat is slate blue with a matching plate,
## so she no longer shares Mira's olive hooded coat. Attached to village Tam
## (the body met at the tournament ring) and the tournament trainer entry; her
## lines drawn with tam.png show the variant plate. Mira never changes. No body
## or face swap.

const VAR := preload("res://scripts/characters/appearance_variants.gd")
const MODEL := preload("res://scripts/characters/character_model.gd")
const TRAINERS := "res://data/config/bands/band1_lower_meadows/trainers.json"
const ID := "beings_meadows_tam_coat"


func _trainer(id: String) -> Dictionary:
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(TRAINERS))
	var rows: Array = (doc as Dictionary).get("trainers", []) if doc is Dictionary else doc
	for row: Dictionary in rows:
		if str(row.get("id", "")) == id:
			return row
	return {}


func _look(row: Dictionary, settings: Dictionary) -> Dictionary:
	var key := str(row.get("config_key", ""))
	return MODEL.with_appearance_variant(MODEL.config_for(key), key, str(row.get("appearance_variant_id", "")), settings)


const VILLAGE := preload("res://scripts/world/village_npcs.gd")


func _villager(name: String) -> Dictionary:
	var village: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/village_npcs.json"))
	for row: Dictionary in village.get("villagers", []):
		if str(row.get("name", "")) == name:
			return row
	return {}


func test_record_is_off_and_on_tam_only() -> void:
	var record: Dictionary = (VAR.load_config().get("variants", {}) as Dictionary).get(ID, {})
	assert_false(record.is_empty(), "the record exists")
	assert_false(bool(record.get("enabled", true)), "it is OFF until GPU-judged")
	assert_false(record.has("body_model_override"), "no body or face swap")
	assert_eq(str(_trainer("tournament_semi_tam").get("appearance_variant_id", "")), ID)
	assert_eq(str(_trainer("tournament_quarter_mira").get("appearance_variant_id", "")), "", "Mira is unchanged")
	assert_eq(str(_villager("Tam").get("appearance_variant_id", "")), ID, "village Tam wears it (she is the body at the ring)")
	assert_eq(str(_villager("Mira").get("appearance_variant_id", "")), "", "village Mira is unchanged")
	assert_eq(str(record.get("replaces_portrait", "")), "res://assets/ui/portraits/tam.png", "it names the plate it replaces")


func test_off_and_on() -> void:
	var settings := VAR.load_config()
	var tam := _trainer("tournament_semi_tam")
	assert_eq(str(_look(tam, settings).get("appearance_variant_id", "")), "", "OFF: Tam wears the shared coat")
	var on := settings.duplicate(true)
	((on.variants as Dictionary)[ID] as Dictionary)["enabled"] = true
	var look := _look(tam, on)
	assert_true(str(look.get("body_albedo_override", "")).ends_with("_tam_coat.png"), "ON: Tam wears the blue coat")
	assert_true(str(look.get("portrait", "")).ends_with("npc_identity_meadows_tam_coat.png"), "ON: with its matching plate")
	assert_true(ResourceLoader.exists(str(look.get("portrait", ""))))
	var mira := _look(_trainer("tournament_quarter_mira"), on)
	assert_eq(str(mira.get("appearance_variant_id", "")), "", "ON: Mira is unchanged")


func test_village_identity_follows_the_record() -> void:
	var tam := _villager("Tam")
	assert_true(VILLAGE.variant_identity(tam).is_empty(), "OFF: village Tam speaks with her lines' own plate")
	assert_true(VILLAGE.variant_identity(_villager("Mira")).is_empty(), "Mira has no variant identity")
