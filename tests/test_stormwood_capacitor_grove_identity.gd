extends "res://tests/test_case.gd"

const PRESENTATION := preload("res://scripts/world/stormwood_capacitor_grove.gd")
const ARCH_RUNTIME := preload("res://scripts/world/stormwood_arch_runtime.gd")
const SITE_CONFIG := "res://data/config/stormwood_capacitor_grove.json"
const WORLD_CONFIG := "res://data/config/stormwood_world.json"
const ARCH_CONFIG := "res://data/config/stormwood_arches.json"
const ENCOUNTER_CONFIG := "res://data/config/stormwood_encounters.json"
const PICKUP_CONFIG := "res://data/config/stormwood_pickups.json"


class FlatWorld:
	extends Node3D
	func ground_height_at(_x: float, _z: float, _preferred_y: float = NAN) -> float:
		return 86.0


func test_capacitor_crescent_has_readable_visual_hierarchy_without_collision() -> void:
	var world := FlatWorld.new()
	var site := PRESENTATION.new()
	world.add_child(site)
	site.position = Vector3(-1040.0, 86.0, 3070.0)
	site.build(world, false)
	for id: String in ["west", "crown", "east"]:
		var bank := site.get_node_or_null(NodePath("CapacitorBank_%s" % id)) as Node3D
		assert_true(bank != null, "capacitor crescent lost the %s bank" % id)
		if bank != null:
			assert_true(bank.get_node_or_null(^"InstalledPylon") != null,
				"%s bank lost its installed Dynamo-family pylon" % id)
			assert_eq(bank.find_children("ChargeRing*", "MeshInstance3D", true, false).size(), 3,
				"%s bank no longer has a controlled three-ring charge rhythm" % id)
	assert_true(site.get_node_or_null(^"OverheadCollector/StormglassCore") != null,
		"the grove lost its overhead focal crown")
	assert_eq(site.find_children("ConductorArc*", "MeshInstance3D", true, false).size(), 3,
		"the three banks no longer compose into one readable installation")
	var light := site.get_node_or_null(^"CapacitorAfterglow") as OmniLight3D
	assert_true(light != null and light.omni_range <= 18.0 and light.light_energy <= 1.5,
		"local night focus escaped its restrained location-scale budget")
	assert_true(site.find_children("*", "CollisionObject3D", true, false).is_empty(),
		"visual dressing changed footing, road, or encounter collision")
	world.free()


func test_capacitor_identity_preserves_socket_and_gameplay_placements() -> void:
	assert_true(ARCH_RUNTIME != null, "production arch runtime no longer parses")
	var site: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SITE_CONFIG))
	assert_eq((site.get("banks", []) as Array).size(), 3,
		"the authored crescent must keep three dominant banks")
	assert_eq(site.get("origin", []), [-1040.0, 3070.0],
		"visual grounding must remain registered to the functional footing")
	for raw: Dictionary in site.get("banks", []):
		var at := Vector2(float(raw.at[0]), float(raw.at[1]))
		assert_true(at.length() >= 10.0,
			"capacitor dressing intrudes into the nine-metre arch build socket")
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WORLD_CONFIG))
	assert_eq(_entry(world.get("landmarks", []), "capacitor_grove").get("position", []),
		[-1080.0, 86.0, 3020.0], "map/discovery seat moved during visual recovery")
	var arches: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARCH_CONFIG))
	assert_eq(_entry(arches.get("footings", []), "capacitor_grove").get("at", []),
		[-1040.0, 3070.0], "functional arch footing moved during visual recovery")
	var encounters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ENCOUNTER_CONFIG))
	assert_eq(_entry(encounters.get("named_encounters", []), "capacitor_alpha").get("position", []),
		[-1080.0, 86.0, 3020.0], "named alpha moved during visual recovery")
	var pickups: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PICKUP_CONFIG))
	assert_true(_has_pickup_at(pickups.get("pickups", []), Vector2(-1080.0, 3020.0)),
		"authored Capacitor Grove pickup moved during visual recovery")
	var source := FileAccess.get_file_as_string("res://scripts/world/stormwood_arch_runtime.gd")
	assert_true(source.contains('str(socket.id) == "capacitor_grove"') and
		source.contains('grove.name = "CapacitorGrovePresentation"'),
		"the production footing no longer mounts its visual identity")


func _entry(entries: Array, wanted: String) -> Dictionary:
	for raw: Variant in entries:
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == wanted:
			return raw as Dictionary
	return {}


func _has_pickup_at(entries: Array, wanted: Vector2) -> bool:
	for raw: Variant in entries:
		if raw is not Dictionary:
			continue
		var position: Array = (raw as Dictionary).get("position", [])
		if position.size() >= 3 and Vector2(float(position[0]), float(position[2])).is_equal_approx(wanted):
			return true
	return false
