extends "res://tests/test_case.gd"

## Rules behind the Cloudreach route-stall fixes (#294/#340). The walked
## witnesses are tests/smoke_cloudreach_route_blockers.gd,
## smoke_cloudreach_shrine_dais.gd and smoke_cloudreach_wild_site_resolution.gd.

const RUNTIME := preload("res://scripts/world/cloudreach_world_runtime.gd")
const DIRECTOR := preload("res://scripts/combat/cloudreach_encounter_director.gd")
const ENCOUNTERS := "res://data/config/cloudreach_encounters.json"
const WORLD := "res://data/config/cloudreach_world.json"


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_wild_site_resolution_fails_closed_beyond_the_limit() -> void:
	var sites: Array = [
		{"id": "near", "position": [0.0, 10.0, 0.0]},
		{"id": "far", "position": [100.0, 10.0, 0.0]},
		{"id": "nowhere", "position": [200.0, 10.0, 0.0]},
	]
	# A resolver shaped like `_resource_position`: `near` snaps 3 m, `far`
	# is bound 60 m away to "the nearest route anywhere", `nowhere` fails.
	var resolver := func(at: Vector3) -> Vector3:
		if is_equal_approx(at.x, 0.0):
			return at + Vector3(3.0, 0.5, 0.0)
		if is_equal_approx(at.x, 100.0):
			return at + Vector3(0.0, 0.0, 60.0)
		return Vector3.INF
	var out: Array = RUNTIME.resolve_wild_sites(sites, resolver, 45.0)
	assert_eq(out.size(), 1, "only the site that resolves within 45 m is kept")
	assert_eq(str(out[0].id), "near")
	assert_eq(out[0].position, [3.0, 10.5, 0.0], "a kept site takes its resolved home")


func test_air_patrols_keep_their_authored_flight_position() -> void:
	var patrol := {"id": "patrol", "placement_mode": "air_patrol", "position": [0.0, 458.0, 0.0], "ground_reference_y": 450.0}
	var regrounding := func(at: Vector3) -> Vector3:
		return Vector3(at.x, 450.06, at.z)
	var out: Array = RUNTIME.resolve_wild_sites([patrol], regrounding, 45.0)
	assert_eq(out.size(), 1)
	assert_eq(out[0].position, [0.0, 458.0, 0.0], "an Air patrol is not re-grounded onto the deck under it")


func test_trainer_corridor_exemption_is_an_explicit_field() -> void:
	assert_true(DIRECTOR.site_keeps_trainer_corridor_clear({"trainer_corridor_clear": true}))
	assert_false(DIRECTOR.site_keeps_trainer_corridor_clear({"trainer_corridor_clear": false}))
	assert_false(DIRECTOR.site_keeps_trainer_corridor_clear({"_why_road_visibility_0907": "a comment is not a switch"}),
		"a _why_* comment key alone no longer changes collision")


func test_every_road_pair_and_ravine_wind_keep_the_trainer_corridor() -> void:
	var road_pairs := 0
	for site: Dictionary in _json(ENCOUNTERS).get("wild_sites", []):
		var id := str(site.id)
		var ground := str(site.get("placement_mode", "ground")) == "ground"
		if (id.begins_with("road_visibility_") and ground) or id == "ravine_wind":
			road_pairs += 1
			assert_true(DIRECTOR.site_keeps_trainer_corridor_clear(site), "%s keeps the trainer corridor clear" % id)
	assert_true(road_pairs > 90, "the ROAD CP-2 pair set is present (%d)" % road_pairs)


func test_roost_perches_stands_on_high_roost_ground() -> void:
	var landmark := Vector3.INF
	for raw: Dictionary in _json(WORLD).get("landmarks", []):
		if str(raw.get("id", "")) == "high_roost_perches":
			landmark = Vector3(float(raw.position[0]), float(raw.position[1]), float(raw.position[2]))
	assert_true(landmark.is_finite(), "the high_roost_perches landmark exists")
	for site: Dictionary in _json(ENCOUNTERS).get("wild_sites", []):
		if str(site.id) != "roost_perches":
			continue
		var at := Vector3(float(site.position[0]), float(site.position[1]), float(site.position[2]))
		assert_true(Vector2(at.x - landmark.x, at.z - landmark.z).length() <= 30.0,
			"roost_perches is authored on the High Perches court, not bound to a road")
		assert_false(DIRECTOR.site_keeps_trainer_corridor_clear(site), "off-road, it needs no corridor exemption")
		return
	assert_true(false, "roost_perches site exists")


func test_the_corridor_exemption_follows_the_trainer_onto_a_mount() -> void:
	var mount := CharacterBody3D.new()
	var wild_a := CharacterBody3D.new()
	var wild_b := CharacterBody3D.new()
	var freed := CharacterBody3D.new()
	freed.free()
	assert_eq(DIRECTOR.keep_mount_corridor_clear([wild_a, wild_b, freed], mount), 2,
		"both living corridor wilds are exempted from the ridden mount")
	assert_true(wild_a.get_collision_exceptions().has(mount) and mount.get_collision_exceptions().has(wild_a),
		"the exemption is mutual, as the trainer's is")
	assert_true(mount.get_collision_exceptions().has(wild_b))
	assert_eq(DIRECTOR.keep_mount_corridor_clear([wild_a, wild_b], mount), 0, "re-applying adds nothing")
	assert_eq(DIRECTOR.keep_mount_corridor_clear([wild_a], null), 0, "no mount, no exemption")
	for body: Node in [mount, wild_a, wild_b]:
		body.free()
