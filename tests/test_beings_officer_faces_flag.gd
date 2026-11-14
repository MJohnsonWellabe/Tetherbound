extends "res://tests/test_case.gd"

## BEINGS-OFFICER-FACES (F41#8, F41#18): appearance-variant records, OFF until
## GPU-judged. Maren keeps officer_b with her own hair and plate; Nysa keeps her
## officer_a face with her own hair and plate (owner, 13 Nov: Nysa keeps her
## current face and her gender stays unstated). Sera and Varga never change.

const VAR := preload("res://scripts/characters/appearance_variants.gd")
const MODEL := preload("res://scripts/characters/character_model.gd")
const TRAINERS := "res://data/config/stormwood_trainers.json"
const IDS := {"officer_maren_verge_rod": "beings_stormwood_maren", "officer_nysa_deepwood_rod": "beings_stormwood_nysa_hair"}


func _trainers() -> Dictionary:
	var out := {}
	for tr: Dictionary in (JSON.parse_string(FileAccess.get_file_as_string(TRAINERS)) as Dictionary).trainers:
		out[str(tr.id)] = tr
	return out


func _look(tr: Dictionary, settings: Dictionary) -> Dictionary:
	var key := str(tr.humanoid_key)
	return VAR.resolve(MODEL.with_body_flags(MODEL.config_for(key), key), key, str(tr.get("appearance_variant_id", "")), settings)


func test_records_are_off_and_attached_to_the_two_officers() -> void:
	var records: Dictionary = VAR.load_config().get("variants", {})
	var trainers := _trainers()
	for trainer_id: String in IDS:
		var record: Dictionary = records.get(IDS[trainer_id], {})
		assert_false(record.is_empty(), "%s exists" % IDS[trainer_id])
		assert_false(bool(record.get("enabled", true)), "%s is OFF until GPU-judged" % IDS[trainer_id])
		assert_eq(str((trainers[trainer_id] as Dictionary).get("appearance_variant_id", "")), IDS[trainer_id])
	for other: String in ["outerworks_lieutenant_sera", "lieutenant_varga_rodline_bridge"]:
		assert_eq(str((trainers[other] as Dictionary).get("appearance_variant_id", "")), "", "%s keeps its body" % other)


func test_off_nothing_changes() -> void:
	var settings := VAR.load_config()
	for trainer_id: String in IDS:
		var look := _look(_trainers()[trainer_id], settings)
		assert_eq(str(look.get("appearance_variant_id", "")), "", "OFF: %s resolves to its shared body" % trainer_id)


func test_on_maren_and_nysa_get_their_own_body_and_plate() -> void:
	var settings := VAR.load_config().duplicate(true)
	for id: String in IDS.values():
		((settings.variants as Dictionary)[id] as Dictionary)["enabled"] = true
	var trainers := _trainers()
	var maren := _look(trainers["officer_maren_verge_rod"], settings)
	assert_true(str(maren.get("body_albedo_override", "")).ends_with("_vis1_maren.png"), "Maren wears her hair texture")
	assert_true(str(maren.get("model", "")).ends_with("officer_b_lod0.glb"), "Maren keeps officer_b")
	var nysa := _look(trainers["officer_nysa_deepwood_rod"], settings)
	assert_true(str(nysa.get("model", "")).ends_with("officer_a_lod0.glb"), "Nysa keeps her own officer_a face")
	assert_true(str(nysa.get("body_albedo_override", "")).ends_with("_cloth2_nysa.png"), "Nysa wears her hair texture, built on the judged cloth")
	var plates := {}
	for look: Dictionary in [maren, nysa]:
		var plate := str(look.get("portrait", ""))
		assert_true(ResourceLoader.exists(plate), "%s plate exists" % plate.get_file())
		plates[plate] = true
	assert_eq(plates.size(), 2, "two distinct plates")
	var sera := _look(trainers["outerworks_lieutenant_sera"], settings)
	var varga := _look(trainers["lieutenant_varga_rodline_bridge"], settings)
	assert_eq(str(sera.get("appearance_variant_id", "")), "", "Sera is unchanged")
	assert_eq(str(varga.get("appearance_variant_id", "")), "", "Varga is unchanged")



func test_no_record_changes_a_presented_face() -> void:
	# Owner, 13 Nov 2026: these officers are told apart by hair colour and
	# plate only, never by a body or face swap.
	var records: Dictionary = VAR.load_config().get("variants", {})
	for id: String in IDS.values():
		assert_false((records.get(id, {}) as Dictionary).has("body_model_override"), "%s does not swap the body" % id)
