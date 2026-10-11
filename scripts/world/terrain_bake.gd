extends RefCounted

## Freshness guard for the `data/terrain/playground` bake, the same shape as
## `scripts/world/scatter_bake.gd`'s `config_fingerprint()`/`is_fresh()` pair
## for the OTHER offline bake `build_playground_terrain.gd` produces.
##
## `build_playground_terrain.gd` reads exactly one data input --
## `data/config/terrain_playground.json` (via `playground_heightfield.gd::
## load_config()`) -- to produce the committed `.res` region files under
## `data/terrain/playground/`. Nothing else on disk feeds that bake: no band
## files, no second config, unlike the scatter bake this mirrors. This file
## is the only thing that reads or writes `data/terrain/<world_name>/
## manifest.json`; `build_playground_terrain.gd` is the only thing that
## calls `write_manifest`.
##
## HARNESS-HYGIENE-0903: added after `terrain_playground.json` was edited
## (doc-path text in comments, during the 2026-09-02 repository reset) with
## no re-bake, and nothing on disk or in CI could tell. `data/scatter/
## playground` already had exactly this guard; `data/terrain/playground` had
## none.

const CONFIG_PATH := "res://data/config/terrain_playground.json"

# Approved F17 village-only authoring snapshot, independently reviewed before
# any regional writer runs. Other config authoring needs a new scoped review.
# Includes the reviewed Berry Field decoration correction over the original
# 8ee152 village snapshot; all other generator input hashes remain unchanged.
const VILLAGE_INPUT_SHA256 := {
 "res://data/config/terrain_playground.json": "4552d95dc3b945ec4606fd9586c5ee65ebfb0d5e8331d9f8b9da0ae230cd6bf2",
 "res://data/config/vegetation.json": "4e3331edea4ceb764bf57bb422dc7db676a3e0acad412dd23d42939cd55593df",
 "res://data/config/bands/band1_lower_meadows/vegetation.json": "ca69f88bff234b00e92529e01c4e0125166d11e0ab9b077e894d262d3b06db05",
 "res://data/config/bands/band2_stone_and_root/vegetation.json": "2695ecadd6458d3aa1e6fe520c8637adfe2e652f1a73dbee5cce00cab9a28a58",
 "res://data/config/bands/band3_the_river_lock/vegetation.json": "0493ecf1641a1c901b9eb6d4544709c558bbf172b72b5c6579333384f4b8ef6b",
 "res://data/config/bands/band4_upper_meadows_ironwood/vegetation.json": "f451051c1520ce5fac9f0e92ecb5415f2459d8a0c62b3eb16d04e3009a325906",
 "res://data/config/bands/band5_stronghold_approach/vegetation.json": "e705c91104d1b0b1892d0da89dbfc432277a4008160c38825b6e1d64cbfc0877"
}
const VILLAGE_SOURCE := "d5ab7d73b31cdd5a24cd45501c980bd4aa553687"
const VILLAGE_BASE := "b2ea1455abdda7f2a7078ed1f148d5c40952c9fc"
const VILLAGE_REGIONS := [[-1,-1],[-1,0],[0,-1],[0,0]]


static func village_input_hashes() -> Dictionary:
	var out := {}
	for path: String in VILLAGE_INPUT_SHA256:
		if not FileAccess.file_exists(path):
			return {}
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(normalised_text(FileAccess.get_file_as_string(path)).to_utf8_buffer())
		out[path] = hash.finish().hex_encode()
	return out


static func scope_inputs_match(inputs: Variant) -> bool:
	return inputs is Dictionary and inputs == VILLAGE_INPUT_SHA256 and village_input_hashes() == inputs


static func read_village_scope(path: String, selection: Array) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path) or not same_regions(selection, VILLAGE_REGIONS):
		return {}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary or raw.get("kind") != "F17_reviewed_village_only" \
			or raw.get("baseline") != VILLAGE_BASE or raw.get("approved_source") != VILLAGE_SOURCE \
			or not same_regions(raw.get("regions"), VILLAGE_REGIONS) or not scope_inputs_match(raw.get("inputs")):
		return {}
	return {"source_inputs":raw.inputs.duplicate(true), "scope_sha256":FileAccess.get_sha256(path),
		"approved_source":VILLAGE_SOURCE,"baseline":VILLAGE_BASE}


static func same_regions(left: Variant, right: Variant) -> bool:
	var canonical_left := canonical_regions(left)
	var canonical_right := canonical_regions(right)
	return not canonical_left.is_empty() and canonical_left == canonical_right


static func canonical_regions(raw: Variant) -> Array:
	if not valid_region_selection(raw):
		return []
	var out: Array = []
	for pair: Array in raw:
		out.append([int(pair[0]),int(pair[1])])
	return out



## Hash of the one file this bake depends on. Whole raw text, not a parsed
## subset -- matching `scatter_bake.gd::config_fingerprint()`'s own choice,
## any text change (including a comment) invalidates the bake, except Git's
## LF/CRLF checkout conversion, which does not alter the authored terrain.
## any byte change (including a comment) is a real edit to the file the bake
## reads and has to be able to invalidate a bake, not just a schema change.
##
## N11-TERRAIN-BAKE-0905: line endings are normalised before hashing. A
## checkout with `core.autocrlf` (the owner's Windows working copy) hands
## `get_as_text()` the same file with `\r\n` endings, and that hashed to a
## different number: `f2dd20e4` stamped 4395215917 into this manifest from a
## Windows bake, which is exactly the CRLF hash of the config whose LF hash is
## 1823724492, so Linux CI read a freshly baked manifest as stale. The bake
## parses the JSON, which is byte-for-byte the same on both sides once the
## line endings are dropped, so the ending is not an input and must not be
## part of the fingerprint. An LF file hashes exactly as it did before this
## change; no committed manifest moves.
static func config_fingerprint() -> int:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return 0
	return fingerprint_for_source(file.get_as_text())


## The canonical source hash, also usable without rewriting a live config.
static func fingerprint_for_source(source: String) -> int:
	# Keep the committed Linux fingerprint valid on Windows without rebaking.
	var mixed := source.replace("\r\n", "\n").hash() + int(CONFIG_PATH.hash())
	# Masked to 53 bits for the same reason `scatter_bake.gd` masks its own
	# fingerprint: this number is written into manifest.json and read back
	# through `JSON.parse_string`, which has no integer type -- every number
	# comes back as a double, and doubles stop representing consecutive
	# integers exactly past 2^53. See that file's own comment for the
	# concrete failure this avoids.
	return mixed & 0x1FFFFFFFFFFFFF


## The text a fingerprint hashes: the file's bytes with every `\r\n` folded
## to `\n`. Shared with `scatter_bake.gd::config_fingerprint()` so the two
## guards agree on what a line ending is.
static func normalised_text(text: String) -> String:
	return text.replace("\r\n", "\n")


static func manifest_path(data_dir: String) -> String:
	return "%s/manifest.json" % data_dir


static func read_manifest(data_dir: String) -> Dictionary:
	var file := FileAccess.open(manifest_path(data_dir), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## True only when `data_dir` holds a manifest stamped from the EXACT config
## this call site is about to use. False for "no bake yet" and for "bake is
## stale" alike, same as `scatter_bake.gd::is_fresh()` -- both mean "the
## committed data cannot be trusted to match the live config," and the
## caller does not need to tell them apart.
static func is_terrain_bake_fresh(data_dir: String = "res://data/terrain/playground") -> bool:
	var manifest := read_manifest(data_dir)
	if manifest.is_empty():
		return false
	return int(manifest.get("config_fingerprint", 0)) == config_fingerprint()


static func is_generation_usable(data_dir: String = "res://data/terrain/playground") -> bool:
	var patches: Variant = read_manifest(data_dir).get("regional_updates", [])
	if patches is Array and not patches.is_empty():
		return is_incremental_usable(data_dir, config_fingerprint())
	return is_terrain_bake_fresh(data_dir)


## Stamp `data_dir/manifest.json` with the fingerprint of the config that
## just produced it. Called only after a FULL bake (every region in the
## configured world bounds) -- `build_playground_terrain.gd` also supports
## baking an explicit `--regions=` subset for the bit-identity test, and a
## partial run must never stamp the whole world fresh, so it skips this call
## entirely rather than being told to leave it out here.
static func write_manifest(data_dir: String, region_count: int) -> void:
	var absolute := ProjectSettings.globalize_path(data_dir)
	if not DirAccess.dir_exists_absolute(absolute):
		DirAccess.make_dir_recursive_absolute(absolute)
	var manifest := {
		"config_fingerprint": config_fingerprint(),
		"regions": region_count,
		"_comment": "Generated by scripts/world/build_playground_terrain.gd (full bake only). Do not hand-edit -- re-run the bake after any change to data/config/terrain_playground.json.",
	}
	var manifest_file := FileAccess.open(manifest_path(data_dir), FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest, "  "))
	manifest_file = null


## A regional generation retains the original full-bake fingerprint. Its
## separately named patch records only the regions actually rewritten.
## Full-world freshness remains false until a full bake is performed.
static func is_incremental_usable(data_dir: String, fingerprint: int) -> bool:
	var manifest := read_manifest(data_dir)
	var region_count: Variant = manifest.get("regions")
	if region_count is int or region_count is float:
		var available := 0
		for name: String in DirAccess.get_files_at(data_dir):
			if _safe_region_filename(name):
				available += 1
		if available != int(region_count):
			return false
	var patches: Variant = manifest.get("regional_updates", [])
	if not patches is Array or patches.is_empty():
		return false
	var patch: Variant = patches[-1]
	if not patch is Dictionary or int(patch.get("config_fingerprint", -1)) != fingerprint:
		return false
	if data_dir.begins_with("res://data/") and not scope_inputs_match(patch.get("source_inputs")):
		return false
	# Every receipt contributes to the current generation. A later write only
	# supersedes the same filename, never validation of disjoint older patches.
	var effective := {}
	for receipt: Variant in patches:
		if not receipt is Dictionary or not valid_region_selection(receipt.get("regions")):
			return false
		var files: Variant = receipt.get("files")
		if not files is Dictionary or files.is_empty():
			return false
		for name: String in files:
			if not _safe_region_filename(name) or str(files[name]).length() != 64:
				return false
			effective[name] = files[name]
	for name: String in effective:
		if FileAccess.get_sha256(data_dir.path_join(name)) != str(effective[name]):
			return false
	return true


static func _safe_region_filename(name: String) -> bool:
	return not name.is_empty() and name == name.get_file() and not name.contains("..") \
		and (name.ends_with(".res") or name.ends_with(".bin"))


static func valid_region_selection(raw: Variant) -> bool:
	if not raw is Array or raw.is_empty():
		return false
	var seen := {}
	for pair: Variant in raw:
		if not pair is Array or pair.size() != 2:
			return false
		for coordinate: Variant in pair:
			if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)) \
					or float(coordinate) != floorf(float(coordinate)) or absf(float(coordinate)) > 1024:
				return false
		var key := "%d:%d" % [int(pair[0]), int(pair[1])]
		if seen.has(key):
			return false
		seen[key] = true
	return true


## Offline writer transaction, used by both village bakes. Every selected
## region is staged first. Metadata is promoted last; synchronous failures
## restore the original files by rename, preserving their bytes and mtimes.
## A previous generation is retained in the staging directory for recovery.
## This does not promise fsync or power-loss atomicity across multiple files.
static func promote_regional_update(data_dir: String, stage_dir: String,
		files: Array[String], patch: Dictionary, fail_after: int = -1) -> bool:
	if files.is_empty() or data_dir.simplify_path() == stage_dir.simplify_path():
		return false
	var prior := read_manifest(data_dir)
	if prior.is_empty() or not valid_region_selection(patch.get("regions")):
		return false
	var seen := {}
	var hashes := {}
	for name: String in files:
		if not _safe_region_filename(name) or seen.has(name) \
				or not FileAccess.file_exists(stage_dir.path_join(name)):
			return false
		seen[name] = true
		var digest := FileAccess.get_sha256(stage_dir.path_join(name))
		if digest.is_empty():
			return false
		hashes[name] = digest
	var next := prior.duplicate(true)
	var raw_updates: Variant = next.get("regional_updates", [])
	if not raw_updates is Array:
		return false
	var updates: Array = raw_updates
	var receipt := patch.duplicate(true)
	receipt["files"] = hashes
	updates.append(receipt)
	next["regional_updates"] = updates
	# Caller-supplied metadata can only add explicit regional identity bounds.
	if patch.get("identity_high_water") is Dictionary:
		next["identity_high_water"] = patch.identity_high_water.duplicate(true)
		next["stable_harvest_ids"] = true
	if patch.has("region_catalog"):
		if not valid_region_selection(patch.region_catalog):
			return false
		next["regions"] = patch.region_catalog.duplicate(true)
	var staged_manifest := stage_dir.path_join("manifest.next.json")
	var output := FileAccess.open(staged_manifest, FileAccess.WRITE)
	if output == null:
		return false
	# Parsed provenance numbers must round-trip exactly, including the 53-bit
	# original full-bake fingerprint retained by a regional update.
	output.store_string(JSON.stringify(next, "  ", true, true))
	output.flush()
	var write_ok := output.get_error() == OK
	output.close()
	if not write_ok:
		return false
	var backup_dir := stage_dir.path_join("previous")
	if DirAccess.dir_exists_absolute(backup_dir) \
			or DirAccess.make_dir_recursive_absolute(backup_dir) != OK:
		return false
	var installed: Array[String] = []
	var moved: Array[String] = []
	var success := true
	for name: String in files + ["manifest.json"]:
		var live := data_dir.path_join(name)
		var staged := staged_manifest if name == "manifest.json" else stage_dir.path_join(name)
		if fail_after >= 0 and installed.size() == fail_after:
			success = false
			break
		if FileAccess.file_exists(live):
			if DirAccess.rename_absolute(live, backup_dir.path_join(name)) != OK:
				success = false
				break
			moved.append(name)
		if DirAccess.rename_absolute(staged, live) != OK:
			success = false
			break
		installed.append(name)
	if success:
		return true
	for name: String in installed:
		if DirAccess.rename_absolute(data_dir.path_join(name), stage_dir.path_join("failed_" + name)) != OK:
			push_error("Regional bake rollback could not retain failed region: " + name)
	for name: String in moved:
		if DirAccess.rename_absolute(backup_dir.path_join(name), data_dir.path_join(name)) != OK:
			push_error("Regional bake rollback could not restore previous region: " + name)
	return false
