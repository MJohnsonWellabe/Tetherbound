extends "res://tests/test_case.gd"

const CODEC := preload("res://scripts/save/save_document.gd")

func test_python_and_native_codec_share_one_exact_wire_fixture() -> void:
	var text := FileAccess.get_file_as_string("res://tests/fixtures/save-codec-v1.json")
	var decoded: Dictionary = CODEC.parse(text)
	assert_eq(var_to_bytes(decoded.float32_height), var_to_bytes(Vector3(-16.0, 1.115974118232727, 14.0).y))
	assert_eq(var_to_bytes(decoded.care), var_to_bytes(100.0 - (1.0 / 60.0) * 0.2))
	assert_eq(var_to_bytes(decoded.subnormal), var_to_bytes("0100000000000000".hex_decode().decode_double(0)))
	assert_eq(decoded.min_int, -9223372036854775807 - 1)
	assert_eq(decoded.max_int, 9223372036854775807)
	assert_eq(JSON.parse_string(CODEC.stringify(decoded)), JSON.parse_string(text))

func test_exact_numeric_bits_survive_repeated_json_storage() -> void:
	var values := [Vector3(-16.0, 1.115974118232727, 14.0).y, 100.0 - (1.0 / 60.0) * 0.2,
		0.0, -0.0, 1.0, 0.00000000000001, "0100000000000000".hex_decode().decode_double(0), 1.7976931348623157e308,
		-9223372036854775807 - 1, 9223372036854775807, 9007199254740991, 1, false, null]
	var before := {"version": 28, "values": values}
	var after := before.duplicate(true)
	for _cycle: int in 5:
		after = CODEC.parse(CODEC.stringify(after))
		for index: int in values.size():
			assert_eq(var_to_bytes(after.values[index]).hex_encode(), var_to_bytes(values[index]).hex_encode())
	assert_eq(after.version, 28)
	assert_eq(typeof(after.version), TYPE_INT)

func test_collision_dictionaries_and_original_strings_survive() -> void:
	var original := {"$tb_float64": "not numeric", "nested": [{"$tb_dictionary": [["a", 3.25]]},
		{"$tb_int64": "123"}], "normal": "000000000000f03f"}
	assert_eq(CODEC.parse(CODEC.stringify(original)), original)
	assert_eq(CODEC.parse(CODEC.stringify({&"interned_key": 3.25})), {"interned_key": 3.25})

func test_plain_json_remains_readable_and_old_readers_cannot_use_envelope() -> void:
	var old := '{"version":28,"party":[{"nourishment":99.779509810833}],"flags":[]}'
	assert_eq(CODEC.parse(old), JSON.parse_string(old))
	assert_eq(CODEC.parse('{"version":28,"$tb_float64":"original legacy text"}'), {"version": 28.0, "$tb_float64": "original legacy text"})
	var raw: Dictionary = JSON.parse_string(CODEC.stringify(CODEC.parse(old)))
	assert_false(raw.has("version"), "old gameplay schema reader must refuse the envelope")
	assert_eq(CODEC.parse(CODEC.stringify(CODEC.parse(old))), CODEC.parse(old))

func test_malformed_or_nonfinite_numeric_tags_are_refused() -> void:
	for payload: Variant in [
		{"x": {"$tb_float64": "000000000000f07f"}}, # infinity
		{"x": {"$tb_float64": "000000000000f87f"}}, # NaN
		{"x": {"$tb_float64": "xyz"}},
		{"x": {"$tb_float64": 123}},
		{"x": {"$tb_float64": "000000000000f03f", "other": 1}},
		{"x": {"$tb_int64": "9223372036854775808"}},
		{"x": {"$tb_int64": "01"}},
		{"x": {"$tb_dictionary": [["$tb_float64", "text"], ["$tb_float64", "duplicate"]]}},
		{"x": 1.25}, {"x": 9007199254740992}]:
		assert_eq(CODEC.parse(JSON.stringify({"format": CODEC.FORMAT, "codec_version": 1, "payload": payload})), null)
	assert_eq(CODEC.stringify({"x": INF}), "")
	assert_eq(CODEC.stringify({"x": NAN}), "")
	assert_eq(CODEC.stringify({1: "non-string dictionary key"}), "")
	assert_eq(CODEC.parse('{"format":"tetherbound-save","codec_version":2,"payload":{}}'), null)
	assert_eq(CODEC.parse('{"format":"tetherbound-save","codec_version":true,"payload":{}}'), null)
	assert_eq(CODEC.parse('{"format":"tetherbound-save","codec_version":1,"payload":{'), null)
