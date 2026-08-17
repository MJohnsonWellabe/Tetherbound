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


## `data/config/vegetation.json` + `data/config/terrain_playground.json`,
## hashed together. Baked placements are only trusted when this matches the
## value stamped into every region file at bake time — a bake against an
## older config is a staleness class that does not exist before this file,
## so it must be loud rather than silently served.
static func config_fingerprint() -> int:
	var mixed := 0
	for path in ["res://data/config/vegetation.json", "res://data/config/terrain_playground.json"]:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return 0
		mixed = mixed ^ (file.get_as_text().hash() + int(path.hash()) + 0x9e3779b9 + (mixed << 6) + (mixed >> 2))
	return mixed


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
static func load_all(world_name: String, drained_out: Dictionary = {}) -> Dictionary:
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

	for region in region_list:
		var path := _region_path(world_name, region)
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("scatter bake manifest names region %s but %s is missing" % [region, path])
			continue
		_read_region(file, by_layer_unordered, drained_unordered)

	var by_layer: Dictionary = {}
	for layer_name: String in by_layer_unordered.keys():
		by_layer[layer_name] = _reorder(by_layer_unordered[layer_name])
	for layer_name: String in drained_unordered.keys():
		drained_out[layer_name] = _reorder(drained_unordered[layer_name])
	return by_layer


## `entries` is an Array of `{ order: int, placement: Dictionary }`, gathered
## across however many region files held pieces of this layer. Sorting by
## `order` restores the exact array position `all_placements` gave each one.
static func _reorder(entries: Array) -> Array[Dictionary]:
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["order"]) < int(b["order"]))
	var out: Array[Dictionary] = []
	for entry: Variant in entries:
		out.append((entry as Dictionary)["placement"])
	return out


static func _read_region(file: FileAccess, by_layer: Dictionary, drained_out: Dictionary) -> void:
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
