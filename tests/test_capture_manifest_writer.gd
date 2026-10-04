extends "res://tests/test_case.gd"

const WRITER := preload("res://tools/capture_manifest_writer.gd")


func _path() -> String:
	var directory := "user://capture-manifest-test-" + Crypto.new().generate_random_bytes(12).hex_encode()
	assert_eq(DirAccess.make_dir_recursive_absolute(directory), OK, "fresh isolated receipt fixture")
	return directory + "/manifest.json"


func _read(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_repeated_publication_retains_previous_complete_snapshot() -> void:
	var path := _path()
	var first := {"frames": ["first"], "complete": false}
	var second := {"frames": ["first", "second"], "complete": false}
	var final := {"frames": ["first", "second", "third"], "complete": true}
	assert_eq(WRITER.write_json(path, first), OK, "first snapshot publishes")
	assert_eq(_read(path), first, "first snapshot readable")
	assert_eq(WRITER.write_json(path, second), OK, "Windows replacement publishes")
	assert_eq(_read(path + ".previous"), first, "prior generation retained")
	assert_eq(WRITER.write_json(path, final), OK, "third snapshot publishes")
	assert_eq(_read(path), final, "completed generation readable")
	assert_eq(_read(path + ".previous"), second, "immediately preceding snapshot retained")
	assert_false(FileAccess.file_exists(path + ".pending"), "successful promotion consumes pending file")


func test_interrupted_staging_preserves_published_frames() -> void:
	var path := _path()
	var first := {"frames": ["first"], "complete": false}
	assert_eq(WRITER.write_json(path, first), OK, "baseline publishes")
	var pending := FileAccess.open(path + ".pending", FileAccess.WRITE)
	pending.store_string('{"frames":[')
	pending.flush()
	pending.close()
	assert_eq(_read(path), first, "partial new write never truncates published frames")
	var final := {"frames": ["first", "second"], "complete": true}
	assert_eq(WRITER.write_json(path, final), OK, "fresh complete staging replaces interrupted bytes")
	assert_eq(_read(path), final, "new generation publishes after interruption")
	assert_eq(_read(path + ".previous"), first, "old published frames remain recoverable")


func test_staging_open_failure_preserves_published_receipt() -> void:
	var path := _path()
	var first := {"frames": ["first"], "complete": false}
	assert_eq(WRITER.write_json(path, first), OK, "baseline publishes")
	assert_eq(DirAccess.make_dir_absolute(path + ".pending"), OK, "block pending file with directory")
	assert_true(WRITER.write_json(path, {"frames": ["first", "second"]}) != OK, "staging failure is reported")
	assert_eq(_read(path), first, "failed staging preserves canonical snapshot")
	assert_true(DirAccess.dir_exists_absolute(path + ".pending"), "blocking path is retained")


func test_backup_failure_preserves_published_receipt_and_pending_bytes() -> void:
	var path := _path()
	var first := {"frames": ["first"], "complete": false}
	var next := {"frames": ["first", "second"], "complete": false}
	assert_eq(WRITER.write_json(path, first), OK, "baseline publishes")
	assert_eq(DirAccess.make_dir_absolute(path + ".previous"), OK, "block backup with directory")
	assert_true(WRITER.write_json(path, next) != OK, "backup failure is reported")
	assert_eq(_read(path), first, "failed backup preserves canonical snapshot")
	assert_eq(_read(path + ".pending"), next, "unpublished candidate retained for diagnosis")
	assert_true(DirAccess.dir_exists_absolute(path + ".previous"), "blocking backup path is retained")


func test_promotion_failure_retains_unpublished_candidate() -> void:
	var path := _path()
	var next := {"frames": ["first"], "complete": false}
	assert_eq(DirAccess.make_dir_absolute(path), OK, "block canonical file with directory")
	assert_true(WRITER.write_json(path, next) != OK, "promotion failure is reported")
	assert_eq(_read(path + ".pending"), next, "failed promotion retains staged candidate")
	assert_true(DirAccess.dir_exists_absolute(path), "blocking canonical path is retained")


func test_locked_pending_promotion_restores_previous_receipt() -> void:
	var path := _path()
	var first := {"frames": ["first"], "complete": false}
	var next := {"frames": ["first", "second"], "complete": false}
	assert_eq(WRITER.write_json(path, first), OK, "baseline publishes")
	var seed := FileAccess.open(path + ".pending", FileAccess.WRITE)
	seed.store_string("staging seed")
	seed.close()
	# Windows CRT handles permit reads/writes but do not share deletion. This
	# allows staging and backup, then refuses promotion of the held file.
	var held := FileAccess.open(path + ".pending", FileAccess.READ)
	assert_true(held != null, "hold staging handle")
	var error := WRITER.write_json(path, next)
	held.close()
	if OS.get_name() != "Windows":
		# POSIX permits renaming an open file; the same fixture must publish.
		assert_eq(error, OK, "open readers permit promotion on this platform")
		assert_eq(_read(path), next, "new generation publishes")
		assert_eq(_read(path + ".previous"), first, "previous generation retained")
		return
	assert_true(error != OK, "locked promotion reports failure")
	assert_eq(_read(path), first, "rollback restores previously published receipt")
	assert_eq(_read(path + ".pending"), next, "completed failed candidate retained")
	assert_false(FileAccess.file_exists(path + ".previous"), "rollback consumed previous path, proving backup succeeded")
