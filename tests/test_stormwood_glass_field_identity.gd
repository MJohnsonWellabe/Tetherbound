extends "res://tests/test_case.gd"

const PRESENTATION := preload("res://scripts/world/stormwood_glass_field.gd")
const SITE_CONFIG := "res://data/config/stormwood_glass_field.json"
const WORLD_CONFIG := "res://data/config/stormwood_world.json"
const ENCOUNTER_CONFIG := "res://data/config/stormwood_encounters.json"


class FlatWorld:
	extends Node3D
	func ground_height_at(_x: float, _z: float, _preferred_y: float = NAN) -> float:
		return 100.0


func test_glass_field_builds_a_readable_non_colliding_strike_corridor() -> void:
	var world := FlatWorld.new()
	var field := PRESENTATION.new()
	world.add_child(field)
	field.build(world, false)
	assert_eq(field.find_children("StormglassCluster_*", "Node3D", true, false).size(), 8,
		"the approach lost its repeated stormglass field rhythm")
	assert_true(field.find_children("GlassShard*", "MeshInstance3D", true, false).size() >= 48,
		"the field no longer reads as a stormglass event rather than ordinary grass")
	assert_eq(field.find_children("FusedStrikeScar", "MeshInstance3D", true, false).size(), 8,
		"each shard family needs a fused impact seat")
	assert_eq(field.find_children("GlassFissure*", "MeshInstance3D", true, false).size(), 24,
		"the fused ground lost its branching lightning language")
	assert_eq(field.find_children("BlastedTree_*", "Node3D", true, false).size(), 4,
		"blasted trees no longer frame the route at human scale")
	assert_eq(field.find_children("TetherWarningStandard_*", "Node3D", true, false).size(), 2,
		"the final approach lost its Team Tether warning threshold")
	assert_eq(field.find_children("ResidualStrikeGlow", "OmniLight3D", true, false).size(), 3,
		"the night route lost its restrained residual-strike cadence")
	for light: Node in field.find_children("ResidualStrikeGlow", "OmniLight3D", true, false):
		assert_true((light as OmniLight3D).light_energy <= 0.85 and (light as OmniLight3D).omni_range <= 18.0,
			"local night emphasis escaped the bounded location-light budget")
	assert_true(field.find_children("*", "CollisionObject3D", true, false).is_empty(),
		"visual identity added collision to the road, fight, or final approach")
	world.free()


func test_glass_field_dressing_keeps_the_authored_route_and_encounter_clear() -> void:
	var site: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SITE_CONFIG))
	assert_eq(site.get("origin", []), [-310.0, 5050.0], "visual origin drifted from the named location")
	assert_eq(site.get("heading_to", []), [-100.0, 5350.0], "field no longer points toward the Outer Works")
	var half_width := float(site.route_half_width_m)
	var spread := float(site.shard_spread_m)
	for raw: Dictionary in site.get("clusters", []):
		assert_true(absf(float(raw.at[0])) - spread > half_width,
			"%s intrudes into the critical road corridor" % str(raw.id))
	for raw: Dictionary in site.get("blasted_trees", []):
		assert_true(absf(float(raw.at[0])) > half_width + 10.0,
			"%s crowds the route camera envelope" % str(raw.id))
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WORLD_CONFIG))
	assert_eq(_entry(world.landmarks, "glass_field").position, [-310.0, 100.0, 5050.0],
		"map/discovery seat moved during visual recovery")
	assert_eq(_entry(world.routes, "deepwood_road").points,
		[[-650.0,3550.0],[-450.0,3960.0],[-890.0,4490.0],[-150.0,4460.0],[-310.0,5050.0],[-100.0,5350.0],[-100.0,5470.0]],
		"critical Dynamo route moved during visual recovery")
	var encounters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ENCOUNTER_CONFIG))
	var alpha := _entry(encounters.named_encounters, "glass_field_alpha")
	assert_eq(alpha.position, [-250.0, 100.0, 5080.0], "named alpha moved during location dressing")
	assert_eq(alpha.placeholder_species, "voltarach")
	assert_eq(alpha.level, 42)
	assert_true(alpha.catchable and alpha.once_only)
	var source := FileAccess.get_file_as_string("res://scripts/world/stormwood_world.gd")
	assert_true(source.contains('field.name = "GlassFieldPresentation"') and
		source.contains("field.build(self, simulation_only)"),
		"production Stormwood no longer mounts the Glass Field identity")


func _entry(entries: Array, wanted: String) -> Dictionary:
	for raw: Variant in entries:
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == wanted:
			return raw as Dictionary
	return {}
