extends "res://tests/test_case.gd"

## F38 P2-033 (22 Oct review): the judged state skipped the tier dressing for a
## Meshy candy (it carries its own colours) and scaled its glow by the
## visual's `glow_scale`. A generic candy keeps the tint, medallion and ring.

const BAND_PICKUPS := preload("res://scripts/world/band_pickups.gd")
const ITEM_CACHE_PICKUP := preload("res://scripts/world/item_cache_pickup.gd")
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")
const RUNS_IN_INITIALIZED_TREE := true

var _host: Node3D = null


func after_each() -> void:
	if is_instance_valid(_host):
		_host.free()
	_host = null


func _pickup(meshy: bool) -> Node3D:
	_host = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(_host)
	var pickup: Node3D = ITEM_CACHE_PICKUP.new()
	var visual := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	visual.add_child(mesh)
	if meshy:
		visual.set_meta(&"meshy_item_visual", true)
		visual.set_meta(&"glow_scale", 0.45)
	pickup.add_child(visual)
	pickup.set("_visual", visual)
	_host.add_child(pickup)
	return pickup


func _glow_scale(pickup: Node3D) -> float:
	var field := PICKUP_GLOW._field_for(pickup, false)
	if field == null:
		return -1.0
	for entry: Dictionary in field.get("_entries"):
		if entry.get("node") == pickup:
			return float(entry.get("scale", -1.0))
	return -1.0


func test_meshy_candy_skips_the_tier_dressing_and_scales_its_glow() -> void:
	var pickup := _pickup(true)
	BAND_PICKUPS.dress(pickup, "rare_candy", Color.WHITE)
	assert_eq(pickup.find_child("TierMedallion", true, false), null, "no medallion on a Meshy candy")
	assert_eq(pickup.find_child("TierRing", true, false), null, "no tier ring on a Meshy candy")
	var mesh := pickup.find_child("*", true, false) as Node3D
	for raw: Node in pickup.find_children("*", "MeshInstance3D", true, false):
		assert_eq((raw as MeshInstance3D).material_override, null, "the Meshy candy keeps its own materials")
	if PICKUP_GLOW.is_enabled():
		assert_almost_eq(_glow_scale(pickup), BAND_PICKUPS.glow_scale_for("rare_candy") * 0.45, 0.001,
			"the glow is scaled by the visual's glow_scale")
	assert_true(mesh != null, "the pickup has a visual")


func test_generic_candy_keeps_the_tier_dressing() -> void:
	var pickup := _pickup(false)
	BAND_PICKUPS.dress(pickup, "rare_candy", Color.WHITE)
	var dressed := false
	for raw: Node in pickup.find_children("*", "MeshInstance3D", true, false):
		dressed = dressed or (raw as MeshInstance3D).material_override != null
	assert_true(dressed, "a generic candy is tinted")
	if PICKUP_GLOW.is_enabled():
		assert_almost_eq(_glow_scale(pickup), BAND_PICKUPS.glow_scale_for("rare_candy"), 0.001,
			"a generic candy's glow keeps the tier scale")
