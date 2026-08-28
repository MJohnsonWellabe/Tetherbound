extends RefCounted

## Reads and writes the scatter placement bake — a second, offline output of
## the same pass `scatter_rules.gd::all_placements` runs at load time.
##
## `all_placements` is pure and seeded, and pure of the heightfield too:
## same config in, same 23,707 placements out, always. Nothing about that
## needs to happen while the player is staring at a loading screen. This file
## is the disk format that lets it happen once, offline, instead — vegetation.gd
## reads the result instead of recomputing it.
##
## One file per Terrain3D region (`region_of`, floor-divided by `region_size`),
## not one monolithic file, so a region can stream on its own later without a
## rewrite of this format. `scatter_rules.gd` itself stays pure: it does no
## file I/O and does not know this bake exists. This file is the only thing
## that reads or writes `data/scatter/<world_name>/`.
##
## PERF1 (playground_heightfield.gd's own caching) and this bake are
## independent optimisations of the same measured cost (23,707 placements,
## `height_at` at 230 µs/call) — see `docs/decisions/D53`. This file never
## touches `playground_heightfield.gd` or `water.gd`.

const MAGIC := 0x53434154 # "SCAT"
const FORMAT_VERSION := 1

## Bytes of a placement record before its has-normal flag: order (32), model
## index (16), position (3 x float32), yaw (float64), scale (float64). See
## `_write_placement`, which is the only thing that writes this layout, and
## `_skip_placements`, which is the only thing that relies on it being fixed.
const PLACEMENT_FIXED_BYTES := 4 + 2 + 12 + 8 + 8

## For the band `vegetation.json` files `config_fingerprint()` has to cover; see
## its own header. This file still does no other content loading.
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")


## Every file the placement pass reads, hashed together. Baked placements are
## only trusted when this matches the value stamped into every region file at
## bake time — a bake against an older config is a staleness class that does
## not exist before this file, so it must be loud rather than silently served.
##
## GATE-D. This used to hash only the two head files, and that was wrong from
## the moment BAND-SPLIT-2 cut `clearings` and `footprints` out of
## `data/config/vegetation.json` into `data/config/bands/<band>/vegetation.json`.
## `scatter_rules.gd::config()` merges those back and
## `scatter_rules.gd::_place_layer` drops any placement that lands inside one,
## so a band author adding a clearing around their own camp changed WHERE
## SCATTER GOES and did not change this number. `is_fresh` then said yes, the
## stale bake was served, and the camp stayed buried in grass with nothing
## anywhere reporting a problem — the exact silent-staleness failure the
## paragraph above says must be loud.
##
## Found while setting up Gate D, where five regional lanes author five band
## directories concurrently and every one of them has a reason to add a
## clearing. Hashing the band files makes the first such edit fail
## `tests/test_scatter_perf_budget.gd`'s freshness assertion instead, which is
## a re-bake somebody has to run rather than a defect nobody can see.
static func config_fingerprint() -> int:
	var paths: Array[String] = [
		"res://data/config/vegetation.json",
		"res://data/config/terrain_playground.json",
	]
	# Order is fixed by BAND_CONTENT.BANDS, not by a directory listing, for the
	# same reason that const exists: a scan would silently pick up a stray
	# directory or silently miss one in an export, and either would move this
	# number for a reason nobody could trace.
	for band in BAND_CONTENT.BANDS:
		paths.append("res://data/config/bands/%s/vegetation.json" % band)

	var mixed := 0
	for path in paths:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			# A band with no vegetation.json is normal, not an error — most
			# bands have none. Skip it rather than returning 0, which would
			# mean "no bake is ever fresh" for every band that has not needed
			# a clearing yet. The two head files are still required: those
			# genuinely missing means the config is broken.
			if path.begins_with("res://data/config/bands/"):
				continue
			return 0
		mixed = mixed ^ (file.get_as_text().hash() + int(path.hash()) + 0x9e3779b9 + (mixed << 6) + (mixed >> 2))
	# GATE-D: masked to 53 bits, and it has to be.
	#
	# This number is written into `manifest.json` and read back through
	# `JSON.parse_string`, which has no integer type -- every number comes back
	# as a double. A 64-bit hash does not survive that: the first value this
	# function produced after the band files joined the hash was
	# -7753574619431497427, and the manifest read back
	# -7753574619431496704, off by 723 because the magnitude is ~860x past the
	# 2^53 where doubles stop representing consecutive integers exactly.
	#
	# `is_fresh()` then compared the two and said no, so the suite failed with
	# "the bake is stale" on a bake that had just been written from the very
	# config it was being compared against -- and the advice in that failure
	# ("re-run the bake and commit the result") could never have fixed it.
	#
	# Masking rather than changing the manifest format keeps every existing
	# reader working and needs no migration. 53 bits is far more than a
	# staleness check needs; the alternative, storing it as a string, buys
	# 11 more bits of hash for a format change nothing else wants.
	return mixed & 0x1FFFFFFFFFFFFF


## Floor-divided region coordinate for a world-space spot, matching the
## lattice Terrain3D regions sit on (boundaries at every multiple of
## `region_size`, per `docs/decisions/D50`/`OW5A-rework`'s region-alignment
## finding). Purely a partitioning key for THIS bake format — it does not
## need to match Terrain3D's own internal region indexing, only to be
## deterministic and stable so a placement always lands in the same file.
static func region_of(spot: Vector2, region_size: float) -> Vector2i:
	return Vector2i(floori(spot.x / region_size), floori(spot.y / region_size))


static func _bake_dir(world_name: String) -> String:
	return "res://data/scatter/%s" % world_name


static func _region_path(world_name: String, region: Vector2i) -> String:
	return "%s/region_%d_%d.bin" % [_bake_dir(world_name), region.x, region.y]


static func _manifest_path(world_name: String) -> String:
	return "%s/manifest.json" % _bake_dir(world_name)


## True if a bake exists on disk and was produced from the exact config this
## call site is about to use. False for "no bake yet" and for "bake is
## stale" alike — both mean "fall back to computing", the caller does not
## need to tell them apart.
static func is_fresh(world_name: String, base_seed: int) -> bool:
	var manifest := _read_manifest(world_name)
	if manifest.is_empty():
		return false
	return int(manifest.get("base_seed", -1)) == base_seed \
		and int(manifest.get("config_fingerprint", 0)) == config_fingerprint()


static func _read_manifest(world_name: String) -> Dictionary:
	var file := FileAccess.open(_manifest_path(world_name), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## Load every region file for `world_name` and merge them back into the same
## shape `scatter_rules.all_placements` returns: `{ layer_name: Array[Dictionary] }`,
## with `drained_out` filled the same way (layer_name -> Array of the
## instances the drain filter removed, for `vegetation.gd::restore_drained()`).
##
## Region files partition placements spatially, which is not the order
## `all_placements` builds them in (clump by clump across the whole world).
## `_mark_harvestable` (vegetation.gd) picks harvest points by STRIDING
## through a layer's placement array, so a reordered array would silently
## choose different trees as gatherable — a real behaviour change, not a
## cosmetic one. Each placement's original index within its own kept/drained
## array is written alongside it (`_bucket`/`_write_placement`) and used here
## to restore the exact original order per layer, independent of which
## region file it came from.
static func load_all(
	world_name: String, drained_out: Dictionary = {},
	skip_layers: Dictionary = {}, skipped_out: Dictionary = {}
) -> Dictionary:
	var manifest := _read_manifest(world_name)
	var by_layer_unordered: Dictionary = {}
	var drained_unordered: Dictionary = {}
	var regions: Array = manifest.get("regions", [])
	var region_list: Array[Vector2i] = []
	for entry: Variant in regions:
		var pair: Array = entry
		region_list.append(Vector2i(int(pair[0]), int(pair[1])))
	region_list.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x or (a.x == b.x and a.y < b.y))

	# GF-B-001. Split timing, printed once, in `vegetation.gd`'s own boot-phase
	# style. This load is the single largest phase of the New Game stall and
	# the two halves below behave nothing alike -- one is file I/O and
	# Dictionary construction, the other is a sort per layer -- so a single
	# figure for the pair cannot say which one a change moved.
	var t_read0 := Time.get_ticks_msec()
	for region in region_list:
		var path := _region_path(world_name, region)
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("scatter bake manifest names region %s but %s is missing" % [region, path])
			continue
		_read_region(file, by_layer_unordered, drained_unordered, skip_layers, skipped_out)
	var t_read1 := Time.get_ticks_msec()

	var by_layer: Dictionary = {}
	var placements := 0
	for layer_name: String in by_layer_unordered.keys():
		placements += (by_layer_unordered[layer_name] as Array).size()
		by_layer[layer_name] = _reorder(by_layer_unordered[layer_name])
	for layer_name: String in drained_unordered.keys():
		placements += (drained_unordered[layer_name] as Array).size()
		drained_out[layer_name] = _reorder(drained_unordered[layer_name])
	var skipped := 0
	for count: Variant in skipped_out.values():
		skipped += int(count)
	print("[scatter bake] load phases (ms): read[%d regions, %d placements, %d skipped]=%d reorder[%d layers]=%d" % [
		region_list.size(), placements, skipped, t_read1 - t_read0,
		by_layer.size() + drained_out.size(), Time.get_ticks_msec() - t_read1])
	return by_layer


## `entries` is an Array of `{ order: int, placement: Dictionary }`, gathered
## across however many region files held pieces of this layer. `order` restores
## the exact array position `all_placements` gave each one.
##
## GF-B-001. Placed directly rather than sorted. `write_all` stamps each
## placement with its own index within its layer's kept (or drained) array --
## `for i in kept_list.size(): _bucket(..., i)` -- and every placement is
## written to exactly one region file, so the orders gathered here for a layer
## are exactly the integers 0 .. n-1, each once. A permutation that dense does
## not need comparing: `out[order] = placement` puts every entry where the sort
## would have put it, in one pass instead of n log n calls into a GDScript
## lambda.
##
## That was 4,900-5,500 ms of the New Game stall on this box, and unlike the
## file read above it did not get cheaper on a warm page cache across three
## repetitions in one process -- it is CPU, and it is the comparator.
##
## The density is checked, not assumed. A region file written by some other
## version of `write_all` could carry orders this reasoning does not cover, and
## a silently mis-ordered scatter is a real behaviour change: `_mark_harvestable`
## walks each layer's array by index, so a different order chooses different
## trees as gatherable. Anything that is not a dense permutation falls back to
## the original sort, which is kept below verbatim.
static func _reorder(entries: Array) -> Array[Dictionary]:
	var count := entries.size()
	var out: Array[Dictionary] = []
	out.resize(count)
	var seen := PackedByteArray()
	seen.resize(count)
	var dense := true
	for entry: Variant in entries:
		var wrapped: Dictionary = entry
		var order := int(wrapped["order"])
		if order < 0 or order >= count or seen[order] == 1:
			dense = false
			break
		seen[order] = 1
		out[order] = wrapped["placement"]
	if dense:
		return out

	push_warning("scatter bake orders are not a dense permutation; sorting instead")
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["order"]) < int(b["order"]))
	var sorted: Array[Dictionary] = []
	for entry: Variant in entries:
		sorted.append((entry as Dictionary)["placement"])
	return sorted


static func _read_region(
	file: FileAccess, by_layer: Dictionary, drained_out: Dictionary,
	skip_layers: Dictionary = {}, skipped_out: Dictionary = {}
) -> void:
	var magic := file.get_32()
	var version := file.get_32()
	if magic != MAGIC or version != FORMAT_VERSION:
		push_error("scatter bake region file has an unrecognised header (magic %d version %d)" % [magic, version])
		return
	var model_count := file.get_32()
	var models: Array[String] = []
	for i in model_count:
		models.append(file.get_pascal_string())

	var layer_count := file.get_32()
	for l in layer_count:
		var layer_name := file.get_pascal_string()
		var kept_count := file.get_32()
		var drained_count := file.get_32()
		# GF-B-001. A layer the caller will not build is walked past, not read.
		#
		# The grass field owns the ground plane on this build, and
		# `vegetation.gd` drops the four layers it replaces the moment the load
		# returns: 661,543 of 765,391 placements, 86.8% of everything this
		# function reads, constructed as two Dictionaries each and immediately
		# discarded. The caller knows which layers those are BEFORE the load --
		# `grass_field.suppressed_layers()` is a config read -- so it can say
		# so, and this can decline to build them.
		#
		# Recorded in `skipped_out` as the KEPT count only, which is what
		# `vegetation.gd`'s "left unbuilt" line has always counted, so that
		# number stays the same across this change instead of quietly gaining
		# the drained ones.
		if skip_layers.has(layer_name):
			_skip_placements(file, kept_count + drained_count)
			skipped_out[layer_name] = int(skipped_out.get(layer_name, 0)) + kept_count
			continue
		if not by_layer.has(layer_name):
			by_layer[layer_name] = []
		var kept: Array = by_layer[layer_name]
		for i in kept_count:
			kept.append(_read_placement(file, models))
		if drained_count > 0:
			if not drained_out.has(layer_name):
				drained_out[layer_name] = []
			var drained: Array = drained_out[layer_name]
			for i in drained_count:
				drained.append(_read_placement(file, models))


## Walk the file past `count` placement records without building anything.
##
## The record is fixed width apart from the optional normal, so this is a seek
## plus one byte read per placement rather than the two Dictionary allocations
## `_read_placement` costs. It must stay in step with `_write_placement`: if
## that layout ever changes, `PLACEMENT_FIXED_BYTES` changes with it or every
## skipped layer desynchronises the read of the layer AFTER it. Nothing else
## in this file depends on the record being fixed width.
static func _skip_placements(file: FileAccess, count: int) -> void:
	for i in count:
		file.seek(file.get_position() + PLACEMENT_FIXED_BYTES)
		if file.get_8() == 1:
			file.seek(file.get_position() + 12)


static func _read_placement(file: FileAccess, models: Array[String]) -> Dictionary:
	var order := file.get_32()
	var model_index := file.get_16()
	var pos := Vector3(file.get_float(), file.get_float(), file.get_float())
	var yaw := file.get_double()
	var scale := file.get_double()
	var placement := {
		"model": models[model_index],
		"position": pos,
		"yaw": yaw,
		"scale": scale,
	}
	if file.get_8() == 1:
		placement["normal"] = Vector3(file.get_float(), file.get_float(), file.get_float())
	return {"order": order, "placement": placement}


## Write the bake: one region file per Terrain3D region touched by any
## placement, plus a manifest recording what produced them. `by_layer` and
## `drained_out` are exactly `all_placements`' own return value and its
## `drained_out` out-parameter — this function partitions them by position,
## it does not recompute or reorder anything within a placement.
static func write_all(
	world_name: String, by_layer: Dictionary, drained_out: Dictionary,
	region_size: float, base_seed: int
) -> Dictionary:
	var dir_path := _bake_dir(world_name)
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))

	# region -> layer_name -> { kept: Array, drained: Array }, each entry
	# `{ order, placement }` where `order` is this placement's index within
	# its OWN kept/drained array — see `load_all`'s `_reorder` for why.
	var by_region: Dictionary = {}
	var total_kept := 0
	var total_drained := 0
	for layer_name: String in by_layer.keys():
		var kept_list: Array = by_layer[layer_name]
		for i in kept_list.size():
			_bucket(by_region, region_size, layer_name, kept_list[i], "kept", i)
			total_kept += 1
	for layer_name: String in drained_out.keys():
		var drained_list: Array = drained_out[layer_name]
		for i in drained_list.size():
			_bucket(by_region, region_size, layer_name, drained_list[i], "drained", i)
			total_drained += 1

	var region_list: Array = []
	var bytes_written := 0
	var regions: Array[Vector2i] = []
	for key: Variant in by_region.keys():
		regions.append(key as Vector2i)
	regions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x or (a.x == b.x and a.y < b.y))
	for region: Vector2i in regions:
		var path := _region_path(world_name, region)
		bytes_written += _write_region(path, by_region[region])
		region_list.append([region.x, region.y])

	var manifest := {
		"base_seed": base_seed,
		"region_size": region_size,
		"config_fingerprint": config_fingerprint(),
		"regions": region_list,
		"placements_kept": total_kept,
		"placements_drained": total_drained,
		"bytes": bytes_written,
		"format_version": FORMAT_VERSION,
		"_comment": "Generated by scripts/world/bake_playground_scatter.gd. Do not hand-edit -- re-run the bake after any change to vegetation.json or terrain_playground.json. See docs/decisions/D53.",
	}
	var manifest_file := FileAccess.open(_manifest_path(world_name), FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest, "  "))
	manifest_file = null

	return {"regions": regions.size(), "bytes": bytes_written, "kept": total_kept, "drained": total_drained}


static func _bucket(by_region: Dictionary, region_size: float, layer_name: String, placement: Dictionary, bucket: String, order: int) -> void:
	var pos: Vector3 = placement["position"]
	var region := region_of(Vector2(pos.x, pos.z), region_size)
	if not by_region.has(region):
		by_region[region] = {}
	var layers: Dictionary = by_region[region]
	if not layers.has(layer_name):
		layers[layer_name] = {"kept": [], "drained": []}
	(layers[layer_name][bucket] as Array).append({"order": order, "placement": placement})


static func _write_region(path: String, layers: Dictionary) -> int:
	# Model paths deduplicated into a small per-region table -- a handful of
	# distinct strings shared by thousands of instances, so writing the full
	# path per placement would dominate the file size for no reason.
	var model_index: Dictionary = {}
	var model_list: Array[String] = []
	var layer_names: Array = layers.keys()
	layer_names.sort()
	for layer_name: String in layer_names:
		var entry: Dictionary = layers[layer_name]
		for group in ["kept", "drained"]:
			for wrapped: Variant in (entry[group] as Array):
				var model := str(((wrapped as Dictionary)["placement"] as Dictionary)["model"])
				if not model_index.has(model):
					model_index[model] = model_list.size()
					model_list.append(model)

	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_32(MAGIC)
	file.store_32(FORMAT_VERSION)
	file.store_32(model_list.size())
	for model in model_list:
		file.store_pascal_string(model)

	file.store_32(layer_names.size())
	for layer_name: String in layer_names:
		file.store_pascal_string(layer_name)
		var entry: Dictionary = layers[layer_name]
		var kept: Array = entry["kept"]
		var drained: Array = entry["drained"]
		file.store_32(kept.size())
		file.store_32(drained.size())
		for wrapped: Variant in kept:
			_write_placement(file, wrapped as Dictionary, model_index)
		for wrapped: Variant in drained:
			_write_placement(file, wrapped as Dictionary, model_index)

	var size := file.get_length()
	file = null
	return size


static func _write_placement(file: FileAccess, wrapped: Dictionary, model_index: Dictionary) -> void:
	var placement: Dictionary = wrapped["placement"]
	var pos: Vector3 = placement["position"]
	file.store_32(int(wrapped["order"]))
	file.store_16(model_index[str(placement["model"])])
	file.store_float(pos.x)
	file.store_float(pos.y)
	file.store_float(pos.z)
	file.store_double(float(placement["yaw"]))
	file.store_double(float(placement["scale"]))
	if placement.has("normal"):
		file.store_8(1)
		var normal: Vector3 = placement["normal"]
		file.store_float(normal.x)
		file.store_float(normal.y)
		file.store_float(normal.z)
	else:
		file.store_8(0)
