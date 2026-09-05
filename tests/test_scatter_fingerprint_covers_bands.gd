extends "res://tests/test_case.gd"

## GATE-D. `scatter_bake.gd::config_fingerprint()` decides whether the baked
## scatter on disk is still trusted. It used to hash only the two head configs,
## `data/config/vegetation.json` and `data/config/terrain_playground.json`, and
## that stopped being the whole input the moment BAND-SPLIT-2 cut `clearings`
## and `footprints` out into `data/config/bands/<band>/vegetation.json`.
##
## Those two arrays are not decoration. `scatter_rules.gd::config()` merges them
## back at load, and `_place_layer` drops any placement landing inside one, so a
## band author who adds a clearing around their own camp has changed where
## scatter goes. With the old fingerprint that change moved nothing, `is_fresh`
## kept saying yes, and the stale bake was served — the camp stayed buried in
## grass and nothing anywhere reported a problem. Silent staleness is precisely
## what `config_fingerprint`'s own header says must not happen.
##
## This matters most under Gate D, where five regional lanes author five band
## directories concurrently and every one of them has a reason to add a
## clearing. With the fingerprint covering the band files, the first such edit
## fails `tests/test_scatter_perf_budget.gd`'s freshness assertion instead: a
## re-bake somebody has to run, rather than a defect nobody can see.
##
## Verified before shipping by running both recipes side by side against the
## same perturbed file: the old two-head-file loop did NOT move, the current
## one did. That is the property this file asserts, measured rather than
## assumed -- an assertion that cannot fail is not a test, and one that passes
## because the fingerprint happens to change for some unrelated reason would be
## worse.

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")


func _band_veg_path(band: String) -> String:
	return "res://data/config/bands/%s/vegetation.json" % band


func test_lf_and_crlf_band_configs_share_the_same_fingerprint() -> void:
	var path := _band_veg_path(BAND_CONTENT.BANDS[0])
	var source := FileAccess.get_file_as_string(path).replace("\r\n", "\n")
	assert_false(source.is_empty())
	var mixed := 12345
	var expected := mixed ^ (source.hash() + int(path.hash()) + 0x9e3779b9 + (mixed << 6) + (mixed >> 2))
	assert_eq(BAKE.mix_config_source(mixed, source, path), expected,
		"the existing Linux hash remains unchanged")
	assert_eq(BAKE.mix_config_source(mixed, source.replace("\n", "\r\n"), path), expected,
		"a Windows checkout must trust the same authored bake")
	assert_ne(BAKE.mix_config_source(mixed, "{\"radius\": 1}\n", path),
		BAKE.mix_config_source(mixed, "{\"radius\": 2}\r\n", path),
		"negative control: an actual clearing edit still invalidates its bake")


## The load-bearing property. Perturb one band's vegetation.json on disk, take
## the fingerprint again, restore the file, and assert the number moved.
##
## It writes to the real file rather than a fixture because the fingerprint
## hashes real paths by design — a fixture copy would prove that hashing a
## fixture works and nothing about the file the game actually reads. The
## original bytes are captured first and written back in the same call, and the
## test asserts the restore succeeded so a failure here cannot leave the repo
## dirty without saying so.
func test_a_band_clearing_moves_the_scatter_fingerprint() -> void:
	var band: String = BAND_CONTENT.BANDS[0]
	var path := _band_veg_path(band)

	var original := FileAccess.get_file_as_string(path)
	assert_ne(original, "", "%s is empty or unreadable; this test needs a real band file" % path)

	var before := BAKE.config_fingerprint()

	# Any byte change will do, and that is the whole claim: the fingerprint
	# hashes this file's TEXT, so any edit to it -- a clearing added, a radius
	# retuned, a footprint moved -- has to move the number. Authoring a real
	# clearing here would test the JSON schema instead, and would need this test
	# to know a valid clearing's shape, which is band_content.gd's business.
	var perturbed := original + "\n"
	assert_ne(perturbed, original, "could not perturb %s" % path)

	var writer := FileAccess.open(path, FileAccess.WRITE)
	assert_true(writer != null, "cannot open %s for writing" % path)
	writer.store_string(perturbed)
	writer.close()

	var after := BAKE.config_fingerprint()

	var restore := FileAccess.open(path, FileAccess.WRITE)
	assert_true(restore != null, "cannot reopen %s to restore it" % path)
	restore.store_string(original)
	restore.close()
	assert_eq(FileAccess.get_file_as_string(path), original,
		"failed to restore %s; the working tree is now dirty" % path)

	assert_ne(after, before,
		"adding a clearing to a band's vegetation.json did not move the scatter fingerprint, "
		+ "so a stale bake would be served for it")




## GATE-D. The fingerprint has to survive a round trip through `manifest.json`,
## and a 64-bit one does not.
##
## `JSON.parse_string` has no integer type: every number comes back as a double,
## which stops representing consecutive integers exactly past 2^53. The first
## value `config_fingerprint()` produced after the band files joined the hash
## was ~860x past that, and read back off by 723 -- so `is_fresh()` compared a
## freshly written bake against the config it had just been written from and
## said no. The suite failed with "the bake is stale", and the advice in that
## failure, re-run the bake, could never have fixed it.
##
## Verified failable before shipping: removing the `& 0x1FFFFFFFFFFFFF` mask
## fails this test with the real pre-fix numbers.
func test_the_fingerprint_survives_a_json_round_trip() -> void:
	var fingerprint := BAKE.config_fingerprint()
	assert_true(fingerprint >= 0 and fingerprint <= 0x1FFFFFFFFFFFFF,
		"config_fingerprint() returned %d, outside the 53-bit range a JSON double " % fingerprint
		+ "can hold exactly; manifest.json will read it back as a different number")

	# Not a proxy for the round trip -- actually do it.
	var round_tripped: Variant = JSON.parse_string(JSON.stringify({"f": fingerprint}))
	assert_true(round_tripped is Dictionary, "could not round-trip the fingerprint through JSON")
	assert_eq(int((round_tripped as Dictionary)["f"]), fingerprint,
		"the fingerprint changed passing through JSON, which is exactly what "
		+ "manifest.json does to it on every bake")

## A band with no vegetation.json is the normal case, not an error -- most bands
## had none until Gate D. The missing-file branch must skip, not return 0:
## returning 0 would make `is_fresh` false forever for any band without one and
## turn the freshness check into a permanent "re-bake now" nobody could satisfy.
##
## GATE-D, second pass: this used to assert against whichever real band files
## happened to be absent, and it stopped covering anything the moment D3, D4 and
## D5 each authored a clearing -- all five bands have a vegetation.json now. Its
## own failure message said so ("this test no longer covers the missing-file
## branch and needs rewriting against a temp path"), which is the failure that
## sent me here. So it now MAKES the condition instead of hoping for it: move a
## real band file aside, take the fingerprint, put it back. A test that quietly
## stops testing anything is the thing this repo's conventions warn about by
## name.
func test_a_band_with_no_vegetation_file_does_not_void_the_fingerprint() -> void:
	var band: String = BAND_CONTENT.BANDS[0]
	var path := _band_veg_path(band)
	var original := FileAccess.get_file_as_string(path)
	assert_ne(original, "", "%s is empty or unreadable; this test needs a real band file" % path)

	var with_file := BAKE.config_fingerprint()
	assert_ne(with_file, 0, "fingerprint was 0 with every band file present")

	# Remove it for real. DirAccess.remove_absolute rather than a rename, so the
	# absent branch is reached by the same FileAccess.file_exists check the
	# production path uses.
	var absolute := ProjectSettings.globalize_path(path)
	var removed := DirAccess.remove_absolute(absolute) == OK
	assert_true(removed, "could not remove %s to create the missing-file condition" % path)

	var without_file := BAKE.config_fingerprint()

	var writer := FileAccess.open(path, FileAccess.WRITE)
	if writer != null:
		writer.store_string(original)
		writer.close()
	assert_eq(FileAccess.get_file_as_string(path), original,
		"failed to restore %s; the working tree is now dirty" % path)

	assert_ne(without_file, 0,
		"config_fingerprint() returned 0 with one band's vegetation.json absent. "
		+ "Absent is normal, and 0 means no bake is ever fresh for that band.")
	assert_ne(without_file, with_file,
		"removing a band's vegetation.json did not move the fingerprint, so the "
		+ "file is not actually in the hash")
