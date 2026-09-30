extends "res://tests/test_case.gd"

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const TERRAIN := preload("res://scripts/world/terrain_bake.gd")
const VEGETATION := preload("res://scripts/world/vegetation.gd")


func test_legacy_order_is_the_existing_runtime_identity_before_conversion() -> void:
	var rows := [_row(2, 25), _row(0, 300), _row(1, 20)]
	assert_true(BAKE.orders_are_dense(rows))
	var ordered: Array = BAKE._reorder(rows.duplicate(true))
	for index: int in ordered.size():
		assert_eq(float(ordered[index].position.x), [300.0, 20.0, 25.0][index])
		assert_false(ordered[index].has("harvest_identity"), "old-format dictionaries and array-index behavior stay intact")
	assert_false(BAKE.orders_are_dense([_row(2, 20), _row(4, 25)]), "gapped old order is never silently reinterpreted")
	assert_false(BAKE.orders_are_dense([_row(0, 20), _row(0, 25)]))


func test_regional_scatter_preserves_outside_and_matched_runtime_harvest_keys() -> void:
	var root := "user://regional-identity-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root)
	_write(root.path_join("manifest.json"), JSON.stringify({"base_seed": 7, "region_size": 256,
		"config_fingerprint": 37, "regions": [[0, 0], [1, 1]]}))
	BAKE._write_region(root.path_join("region_0_0.bin"), {"trees": {"kept": [_row(1, 20), _row(2, 25)], "drained": []}})
	BAKE._write_region(root.path_join("region_1_1.bin"), {"trees": {"kept": [_row(0, 300)], "drained": []}})
	var outside_hash := FileAccess.get_sha256(root.path_join("region_1_1.bin"))
	var result: Dictionary = BAKE.write_regions("playground", {"trees": [_placement(20), _placement(40), _placement(300)]}, {}, 256, 7, [[0, 0]], root)
	assert_true(bool(result.get("ok", false)), str(result))
	var rows: Array = []
	for name: String in ["region_0_0.bin", "region_1_1.bin"]:
		var layers := {}
		BAKE._read_region(FileAccess.open(root.path_join(name), FileAccess.READ), layers, {})
		rows.append_array(layers.trees)
	var ordered: Array = BAKE._reorder(rows, true)
	var vegetation := VEGETATION.new()
	vegetation._mark_harvestable({"trees": ordered})
	assert_eq(ordered.map(func(row: Dictionary) -> int: return int(row.harvest_index)), [0, 1, 3],
		"existing actual layer#index keys survive; removed key2 stays retired and the addition uses key3")
	assert_eq(int(vegetation.get("_harvest_layer_counts").trees), 4, "bitset includes identity holes")
	vegetation.free()
	assert_eq(FileAccess.get_sha256(root.path_join("region_1_1.bin")), outside_hash)
	var manifest := TERRAIN.read_manifest(root)
	assert_eq(int(manifest.config_fingerprint), 37, "regional writer never restamps the original full-bake fingerprint")
	assert_eq(int(manifest.identity_high_water.trees), 3)
	result = BAKE.write_regions("playground", {"trees": [_placement(20), _placement(50), _placement(300)]}, {}, 256, 7, [[0, 0]], root)
	assert_true(bool(result.get("ok", false)), str(result))
	var layers := {}
	BAKE._read_region(FileAccess.open(root.path_join("region_0_0.bin"), FileAccess.READ), layers, {})
	assert_eq((layers.trees as Array).map(func(row: Dictionary) -> int: return int(row.order)), [1, 4],
		"another removal/addition cannot impersonate retired keys2 or3")
	assert_eq(FileAccess.get_sha256(root.path_join("region_1_1.bin")), outside_hash)
	result = BAKE.write_regions("playground", {"trees": [_placement(20), _placement(300)]}, {}, 256, 7, [[0, 0]], root)
	assert_true(bool(result.get("ok", false)), str(result))
	layers = {}
	BAKE._read_region(FileAccess.open(root.path_join("region_0_0.bin"), FileAccess.READ), layers, {})
	manifest = TERRAIN.read_manifest(root)
	ordered = BAKE._reorder(layers.trees, true, int(manifest.identity_high_water.trees) + 1)
	vegetation = VEGETATION.new()
	vegetation._mark_harvestable({"trees": ordered})
	assert_eq(int(vegetation.get("_harvest_layer_counts").trees), 5,
		"removing the highest identity cannot shrink a saved harvest bitset")
	vegetation.free()


func test_regional_promotion_rolls_back_and_keeps_untouched_generation_bytes() -> void:
	var root := "user://regional-commit-%d" % Time.get_ticks_usec()
	var stage := root + "-stage"
	DirAccess.make_dir_recursive_absolute(root)
	DirAccess.make_dir_recursive_absolute(stage)
	_write(root.path_join("manifest.json"), '{"config_fingerprint":37,"regions":3}')
	for name: String in ["region_0_0.bin", "region_1_0.bin", "region_2_0.bin"]:
		_write(root.path_join(name), "old:" + name)
		if name != "region_2_0.bin":
			_write(stage.path_join(name), "new:" + name)
	var prior_manifest := FileAccess.get_file_as_bytes(root.path_join("manifest.json"))
	var original_time := FileAccess.get_modified_time(root.path_join("region_0_0.bin"))
	var outside_hash := FileAccess.get_sha256(root.path_join("region_2_0.bin"))
	var names: Array[String] = ["region_0_0.bin", "region_1_0.bin"]
	var patch := {"regions": [[0, 0], [1, 0]], "config_fingerprint": 999}
	assert_false(TERRAIN.promote_regional_update(root, stage, names, patch, 1), "injected failure after first install exercises real rollback")
	assert_eq(FileAccess.get_file_as_string(root.path_join("region_0_0.bin")), "old:region_0_0.bin")
	assert_eq(FileAccess.get_file_as_string(root.path_join("region_1_0.bin")), "old:region_1_0.bin")
	assert_eq(FileAccess.get_modified_time(root.path_join("region_0_0.bin")), original_time)
	assert_eq(FileAccess.get_file_as_bytes(root.path_join("manifest.json")), prior_manifest)
	assert_eq(FileAccess.get_sha256(root.path_join("region_2_0.bin")), outside_hash)
	stage = root + "-next"
	DirAccess.make_dir_recursive_absolute(stage)
	for name: String in names:
		_write(stage.path_join(name), "new:" + name)
	assert_true(TERRAIN.promote_regional_update(root, stage, names, patch))
	assert_eq(int(TERRAIN.read_manifest(root).config_fingerprint), 37)
	assert_true(TERRAIN.is_incremental_usable(root, 999))
	assert_false(TERRAIN.is_incremental_usable(root, 1000), "unrelated later source edits cannot reuse this regional receipt")
	assert_eq(FileAccess.get_sha256(root.path_join("region_2_0.bin")), outside_hash)
	assert_false(TERRAIN.read_village_scope("", TERRAIN.VILLAGE_REGIONS).size() > 0)
	var scope_file := root + "-scope.json"
	var proof := {"kind":"F17_reviewed_village_only","baseline":TERRAIN.VILLAGE_BASE,
		"approved_source":TERRAIN.VILLAGE_SOURCE,"regions":TERRAIN.VILLAGE_REGIONS,
		"inputs":TERRAIN.village_input_hashes()}
	_write(scope_file,JSON.stringify(proof))
	assert_false(TERRAIN.read_village_scope(scope_file,[[0,0]]).size() > 0,"foreign selection refused")
	assert_true(TERRAIN.read_village_scope(scope_file,TERRAIN.VILLAGE_REGIONS).size() > 0,"actual approved sources match complete seven-input receipt")
	proof.inputs["res://data/config/terrain_playground.json"] = "forged authoring hash"
	_write(scope_file,JSON.stringify(proof))
	assert_false(TERRAIN.read_village_scope(scope_file,TERRAIN.VILLAGE_REGIONS).size() > 0,"foreign source receipt refused")
	assert_false(TERRAIN.valid_region_selection([]))
	assert_false(TERRAIN.valid_region_selection([[0, 0], [0, 0]]))
	assert_false(TERRAIN.valid_region_selection([[0.5, 0]]))
	assert_false(BAKE.valid_world_selection([[9, 0]], {"min_x": -512, "max_x": 512, "min_z": -512, "max_z": 512}, 256))


func test_stable_generation_restores_old_bitset_prefix_and_empty_layer_bounds() -> void:
	var root := "user://regional-empty-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root)
	_write(root.path_join("manifest.json"), JSON.stringify({"base_seed":7, "region_size":256,
		"config_fingerprint":37, "regions":[[0,0]]}))
	var old: Array = []
	for index: int in 8:
		old.append(_row(index, 20 + index))
	BAKE._write_region(root.path_join("region_0_0.bin"), {"trees":{"kept":old,"drained":[]}})
	var placements: Array = []
	for index: int in 9:
		placements.append(_placement(20 + index))
	assert_true(bool(BAKE.write_regions("playground", {"trees":placements}, {},256,7,[[0,0]],root).ok))
	var bounds := BAKE.stable_identity_bounds(TERRAIN.read_manifest(root))
	assert_eq(int(bounds.trees), 9)
	var rows := {}
	BAKE._read_region(FileAccess.open(root.path_join("region_0_0.bin"),FileAccess.READ),rows,{})
	var vegetation := VEGETATION.new()
	vegetation._mark_harvestable({"trees":BAKE._reorder(rows.trees,true,9)},bounds)
	var game := SavedHarvest.new()
	game.harvested_vegetation = {"trees":Marshalls.raw_to_base64(PackedByteArray([129]))}
	vegetation.restore_from_game(game)
	assert_eq(vegetation.get("_harvested").trees, PackedByteArray([129,0]),
		"old harvested identities0/7 survive growth8→9; all new slots are zero")
	vegetation.free()
	assert_true(bool(BAKE.write_regions("playground",{}, {},256,7,[[0,0]],root).ok))
	bounds = BAKE.stable_identity_bounds(TERRAIN.read_manifest(root))
	vegetation = VEGETATION.new()
	vegetation._mark_harvestable({},bounds)
	vegetation.restore_from_game(game)
	assert_eq(int(vegetation.get("_harvest_layer_counts").trees),9,"empty layer retains retired bound independently of placements")
	assert_eq(vegetation.get("_harvested").trees,PackedByteArray([129,0]))
	vegetation.free()
	assert_true(bool(BAKE.write_regions("playground",{"trees":[_placement(40)]},{},256,7,[[0,0]],root).ok))
	rows = {}
	BAKE._read_region(FileAccess.open(root.path_join("region_0_0.bin"),FileAccess.READ),rows,{})
	assert_eq(int(rows.trees[0].order),9,"new layer occupant never impersonates any retired key")
	# A removed old layer still has to prove its old array identities before
	# globally activating stable IDs for files outside the selected region.
	root += "-invalid"
	DirAccess.make_dir_recursive_absolute(root)
	_write(root.path_join("manifest.json"),JSON.stringify({"base_seed":7,"region_size":256,
		"config_fingerprint":37,"regions":[[0,0],[1,1]]}))
	BAKE._write_region(root.path_join("region_0_0.bin"),{})
	BAKE._write_region(root.path_join("region_1_1.bin"),{"trees":{"kept":[_row(2,300)],"drained":[]}})
	var before := FileAccess.get_sha256(root.path_join("manifest.json"))
	assert_eq(str(BAKE.write_regions("playground",{}, {},256,7,[[0,0]],root).code),"legacy_order_not_dense")
	assert_eq(FileAccess.get_sha256(root.path_join("manifest.json")),before)



func test_disjoint_receipts_validate_all_effective_hashes_and_allow_supersession() -> void:
	var root := "user://regional-hashes-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root)
	_write(root.path_join("manifest.json"),'{"config_fingerprint":37,"regions":2}')
	for name: String in ["region_0_0.bin","region_1_0.bin"]:
		_write(root.path_join(name),"base:"+name)
	for index: int in 2:
		var stage := root + "-stage%d" % index
		DirAccess.make_dir_recursive_absolute(stage)
		var name := "region_%d_0.bin" % index
		_write(stage.path_join(name),"patch%d" % index)
		var files: Array[String] = [name]
		assert_true(TERRAIN.promote_regional_update(root,stage,files,{"regions":[[index,0]],"config_fingerprint":100+index}))
	assert_true(TERRAIN.is_incremental_usable(root,101))
	_write(root.path_join("region_0_0.bin"),"corruption in older disjoint patch")
	assert_false(TERRAIN.is_incremental_usable(root,101))
	var stage := root + "-supersede"
	DirAccess.make_dir_recursive_absolute(stage)
	_write(stage.path_join("region_0_0.bin"),"new authorized replacement")
	var files: Array[String] = ["region_0_0.bin"]
	assert_true(TERRAIN.promote_regional_update(root,stage,files,{"regions":[[0,0]],"config_fingerprint":102}))
	assert_true(TERRAIN.is_incremental_usable(root,102),"later receipt supersedes only its rewritten file")
	DirAccess.remove_absolute(root.path_join("region_1_0.bin"))
	assert_false(TERRAIN.is_incremental_usable(root,102))
	# A matching base fingerprint must not short-circuit regional validation.
	root += "-fresh-base"
	DirAccess.make_dir_recursive_absolute(root)
	_write(root.path_join("manifest.json"),JSON.stringify({"config_fingerprint":TERRAIN.config_fingerprint(),"regions":1}))
	_write(root.path_join("region_0_0.bin"),"base")
	stage = root + "-patch"
	DirAccess.make_dir_recursive_absolute(stage)
	_write(stage.path_join("region_0_0.bin"),"patch")
	assert_true(TERRAIN.promote_regional_update(root,stage,["region_0_0.bin"],
		{"regions":[[0,0]],"config_fingerprint":TERRAIN.config_fingerprint()}))
	assert_true(TERRAIN.is_terrain_bake_fresh(root),"original full-generation provenance remains unchanged")
	assert_true(TERRAIN.is_generation_usable(root))
	_write(root.path_join("region_0_0.bin"),"corrupted after same-source regional patch")
	assert_true(TERRAIN.is_terrain_bake_fresh(root))
	assert_false(TERRAIN.is_generation_usable(root),"matching base provenance cannot bypass effective regional hashes")


class SavedHarvest extends RefCounted:
	var world: RefCounted = null
	var harvested_vegetation: Dictionary = {}
	var felled_vegetation: Dictionary = {}
	var world_flags: Dictionary = {}


func _row(order: int, coordinate: float) -> Dictionary:
	return {"order": order, "placement": _placement(coordinate)}


func _placement(coordinate: float) -> Dictionary:
	return {"model": "fixture_oak", "position": Vector3(coordinate, 0, coordinate), "yaw": 0.0, "scale": 1.0}


func _write(path: String, source: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(source)
	file.close()
