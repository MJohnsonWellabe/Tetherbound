extends "res://tests/test_case.gd"

## X05 / MULTIPLAYER §1.1 step 5: the host refuses a mismatched build or
## content with a readable reason before admission.

const FINGERPRINT := preload("res://scripts/net/build_fingerprint.gd")
const TMP_ROOT := "user://test_build_fingerprint_tree"


func _local() -> Dictionary:
	return {"wire_protocol": FINGERPRINT.WIRE_PROTOCOL, "engine": "4.7.0.stable",
		"content": "0123456789abcdef0123456789abcdef"}


func test_identical_fingerprint_is_admitted() -> void:
	var verdict := FINGERPRINT.compare(_local(), _local())
	assert_true(bool(verdict["ok"]))
	assert_eq(verdict["code"], "")


func test_wire_protocol_marker_is_pinned() -> void:
	# Changing this is a deliberate compatibility break: bump it together with
	# the RPC surface and update this line in the same change.
	assert_eq(FINGERPRINT.WIRE_PROTOCOL, "tetherbound-invite-v6")


func test_current_fingerprint_matches_itself_and_names_every_part() -> void:
	var here := FINGERPRINT.current()
	assert_eq(here["wire_protocol"], FINGERPRINT.WIRE_PROTOCOL)
	assert_true(str(here["engine"]).begins_with("4.7."), str(here["engine"]))
	assert_eq(str(here["content"]).length(), 64, "SHA-256 hex over res://data JSON")
	assert_true(bool(FINGERPRINT.compare(here, FINGERPRINT.current())["ok"]))


func test_missing_or_malformed_fingerprint_is_refused_not_admitted() -> void:
	for claim: Variant in [null, "v5", 5, {}, {"wire_protocol": FINGERPRINT.WIRE_PROTOCOL},
			{"wire_protocol": 5, "engine": "4.7.0.stable", "content": "x"}]:
		var verdict := FINGERPRINT.compare(_local(), claim)
		assert_false(bool(verdict["ok"]), "claim %s must be refused" % str(claim))
		assert_eq(verdict["code"], "incompatible_version")
		assert_true(str(verdict["reason"]).contains("Update Tetherbound"), str(verdict["reason"]))


func test_each_mismatch_names_what_differs() -> void:
	var theirs := _local()
	theirs["wire_protocol"] = FINGERPRINT.WIRE_PROTOCOL + "-older"
	var verdict := FINGERPRINT.compare(_local(), theirs)
	assert_eq(verdict["code"], "incompatible_version")
	assert_true(str(verdict["reason"]).contains("network versions"), str(verdict["reason"]))
	assert_true(str(verdict["reason"]).contains("host %s, yours %s-older" % [FINGERPRINT.WIRE_PROTOCOL, FINGERPRINT.WIRE_PROTOCOL]))

	theirs = _local()
	theirs["engine"] = "4.6.2.stable"
	verdict = FINGERPRINT.compare(_local(), theirs)
	assert_true(str(verdict["reason"]).contains("host engine 4.7.0.stable, yours 4.6.2.stable"),
		str(verdict["reason"]))

	theirs = _local()
	theirs["content"] = "fedcba9876543210fedcba9876543210"
	verdict = FINGERPRINT.compare(_local(), theirs)
	assert_true(str(verdict["reason"]).contains("different game content (host 01234567, yours fedcba98)"),
		str(verdict["reason"]))


func test_content_hash_is_order_independent_and_sensitive_to_bytes_and_paths() -> void:
	_write_tree({"a.json": "{\"x\":1}", "sub/b.json": "{\"y\":2}", "skip.bin": "ignored"})
	var first := FINGERPRINT.hash_content_under(TMP_ROOT)
	assert_eq(first, FINGERPRINT.hash_content_under(TMP_ROOT), "deterministic")
	assert_eq(first.length(), 64)

	_write_tree({"skip.bin": "changed binary is not content"})
	assert_eq(FINGERPRINT.hash_content_under(TMP_ROOT), first, "only JSON is hashed")

	_write_tree({"sub/b.json": "{\"y\":3}"})
	var changed := FINGERPRINT.hash_content_under(TMP_ROOT)
	assert_ne(changed, first, "one changed tunable changes the fingerprint")

	_write_tree({"sub/b.json": "{\"y\":2}"})
	assert_eq(FINGERPRINT.hash_content_under(TMP_ROOT), first, "restoring the bytes restores the hash")

	DirAccess.rename_absolute(TMP_ROOT.path_join("a.json"), TMP_ROOT.path_join("c.json"))
	assert_ne(FINGERPRINT.hash_content_under(TMP_ROOT), first, "a renamed file is different content")
	_remove_tree(TMP_ROOT)


func test_token_is_the_short_display_form() -> void:
	assert_eq(FINGERPRINT.token(_local()), "%s|4.7.0.stable|01234567" % FINGERPRINT.WIRE_PROTOCOL)


func _write_tree(files: Dictionary) -> void:
	for rel: String in files:
		var path := TMP_ROOT.path_join(rel)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(str(files[rel]))
		f.close()


func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		dir.remove(file_name)
	for sub in dir.get_directories():
		_remove_tree(path.path_join(sub))
	DirAccess.remove_absolute(path)
