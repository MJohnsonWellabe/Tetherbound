extends "res://tests/test_case.gd"

## HANDOFF proof for every CI segment boundary (tests/helpers/ci_segments.gd).
##
## For each committed checkpoint under tests/fixtures/segments/: it is at the
## current save VERSION, loads through the production `SaveGame.load_slot`,
## meets the boundary's start contract (the same dictionary the producer's end
## and the consumer's start assert), still matches its manifest digest, and was
## produced by the producer scenario as it is now. A failure names the command
## that regenerates the checkpoint. The negative cases prove a deliberately
## stale checkpoint fails loudly instead of passing.
##
##   godot --headless --path . --script tests/run_tests.gd -- --only=ci_segment_handoffs

const SEGMENTS := preload("res://tests/helpers/ci_segments.gd")
const WORK := "user://test_ci_segment_handoffs/"
const SCRATCH := "user://test_ci_segment_handoffs_copy/"


func after_each() -> void:
	SEGMENTS.SPLIT_FIXTURE.wipe(WORK)
	SEGMENTS.SPLIT_FIXTURE.wipe(SCRATCH)


## The boundaries under test: all, or one chain's (TB_SEGMENT_CHAIN, as CI's
## per-chain handoff job sets it).
func _boundaries() -> Array:
	var chain := OS.get_environment("TB_SEGMENT_CHAIN")
	return SEGMENTS.boundary_names().filter(func(b: String) -> bool:
		return chain.is_empty() or str(SEGMENTS.BOUNDARIES[b]["chain"]) == chain)


func _roles(boundary: String) -> Array:
	return (SEGMENTS.BOUNDARIES[boundary]["roles"] as Dictionary).keys()


func test_the_selected_chain_has_boundaries() -> void:
	assert_false(_boundaries().is_empty(), "no boundaries for chain '%s'" % OS.get_environment("TB_SEGMENT_CHAIN"))


func test_every_boundary_has_a_committed_checkpoint_per_role() -> void:
	for boundary: String in _boundaries():
		var manifest := SEGMENTS.read_manifest(boundary)
		assert_false(manifest.is_empty(), "%s has no manifest: %s" % [boundary, SEGMENTS.regen_hint(boundary)])
		for role: String in _roles(boundary):
			assert_true(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(
				SEGMENTS.checkpoint_dir(boundary, role))), "%s:%s checkpoint missing: %s"
				% [boundary, role, SEGMENTS.regen_hint(boundary)])
			assert_true(FileAccess.file_exists(ProjectSettings.globalize_path(str(
				SEGMENTS.role_spec(boundary, role).producer))), "%s:%s producer exists" % [boundary, role])


func test_every_checkpoint_is_fresh() -> void:
	for boundary: String in _boundaries():
		for role: String in _roles(boundary):
			var stale := SEGMENTS.staleness(boundary, role, WORK)
			assert_true(stale.is_empty(), "STALE: " + "; ".join(stale))


func test_every_checkpoint_loads_and_meets_its_start_contract() -> void:
	for boundary: String in _boundaries():
		for role: String in _roles(boundary):
			var loaded := SEGMENTS.load_captured(SEGMENTS.checkpoint_dir(boundary, role), WORK)
			assert_true(bool(loaded.get("ok", false)), "%s:%s production load: %s" % [boundary, role, str(loaded.get("detail", ""))])
			if not bool(loaded.get("ok", false)):
				continue
			var failures := SEGMENTS.evaluate(boundary, role, loaded.game)
			assert_true(failures.is_empty(), "%s:%s start contract: %s; %s"
				% [boundary, role, "; ".join(failures), SEGMENTS.regen_hint(boundary)])


## Negative: a checkpoint whose saved state differs from what its producer
## recorded (one creature's level raised by hand) is refused by digest.
func test_hand_edited_checkpoint_is_stale() -> void:
	var edited_any := false
	for boundary: String in _boundaries():
		for role: String in _roles(boundary):
			var copy := _copy_role(boundary, role)
			if not _edit_first(copy.path_join("characters"), RegEx.create_from_string("\"level\":\\s*(\\d+)"),
					func(m: RegExMatch) -> String: return "\"level\": %d" % (int(m.get_string(1)) + 1)):
				continue # a role with no creature (the midride host)
			edited_any = true
			var text := "; ".join(SEGMENTS.staleness(boundary, role, WORK, copy))
			assert_true(text.contains(SEGMENTS.regen_hint(boundary)),
				"hand-edited %s:%s must be stale and name its regeneration command; got: %s" % [boundary, role, text])
	assert_true(edited_any, "found a creature level to edit")


## Negative: a checkpoint written by an older save version (RD-35: refused,
## never converted) fails on its version, naming the regeneration command.
func test_old_version_checkpoint_is_stale() -> void:
	for boundary: String in _boundaries():
		for role: String in _roles(boundary):
			var copy := _copy_role(boundary, role)
			assert_true(_edit_first(copy.path_join("worlds"), RegEx.create_from_string("\"version\":\\s*(\\d+)"),
				func(_m: RegExMatch) -> String: return "\"version\": 27"), "found %s:%s world version" % [boundary, role])
			var text := "; ".join(SEGMENTS.staleness(boundary, role, WORK, copy))
			assert_true(text.contains("world document is version 27") and text.contains(SEGMENTS.regen_hint(boundary)),
				"old-version %s:%s must be stale: %s" % [boundary, role, text])


## Negative: the producer changed (its scenario/script or the contract moved
## its fingerprint) -> stale, even though the files themselves are intact.
func test_changed_producer_makes_checkpoint_stale() -> void:
	for boundary: String in _boundaries():
		for role: String in _roles(boundary):
			var row: Dictionary = ((SEGMENTS.read_manifest(boundary).get("roles", {}) as Dictionary)
				.get(role, {}) as Dictionary).duplicate()
			row["producer_fingerprint"] = "0".repeat(64)
			var text := "; ".join(SEGMENTS.staleness(boundary, role, WORK, "", row))
			assert_true(text.contains("different producer") and text.contains(SEGMENTS.regen_hint(boundary)),
				"changed producer of %s:%s must be stale: %s" % [boundary, role, text])


## Negative: the contract is read, not decorative -- a checkpoint checked
## against another boundary role's contract is rejected.
func test_contract_mismatch_is_reported() -> void:
	for boundary: String in _boundaries():
		for role: String in _roles(boundary):
			var loaded := SEGMENTS.load_captured(SEGMENTS.checkpoint_dir(boundary, role), WORK)
			var other := ["midride/setup", "guest"] if boundary.begins_with("bracket") or role == "host" \
				else ["bracket/after_semi", "solo"]
			var failures := SEGMENTS.evaluate(str(other[0]), str(other[1]), loaded.game)
			assert_false(failures.is_empty(), "%s:%s must fail %s:%s's contract" % [boundary, role, other[0], other[1]])


func _copy_role(boundary: String, role: String) -> String:
	var dst := ProjectSettings.globalize_path(SCRATCH).path_join(role)
	var src := ProjectSettings.globalize_path(SEGMENTS.checkpoint_dir(boundary, role))
	SEGMENTS.SPLIT_FIXTURE.wipe(dst + "/")
	for sub: String in ["saves", "worlds", "characters"]:
		SEGMENTS._copy_tree(src.path_join(sub), dst.path_join(sub))
	return dst


## Rewrite the first match of `re` in the first JSON file under `dir`.
func _edit_first(dir: String, re: RegEx, replace: Callable) -> bool:
	for f: String in SEGMENTS._files(dir):
		var text := FileAccess.get_file_as_string(f)
		var m := re.search(text)
		if m == null:
			continue
		text = text.substr(0, m.get_start()) + str(replace.call(m)) + text.substr(m.get_end())
		var out := FileAccess.open(f, FileAccess.WRITE)
		out.store_string(text)
		out.close()
		return true
	return false
