extends "res://tests/test_case.gd"

## F14#1: no Water wild cluster may roam into a trainer's fight ring. The Venn
## capture showed a roadside pair 6.9 m from his spot standing between the
## fighters and the fight camera. A site centre must clear the trainer's spot by
## the arena radius, the camera-edge occluder margin (combat.json arena) and the
## site's own roam radius. Positions resolve exactly as the runtime adapter
## does: the reused NPC body's island offset from the island centre.

const WORLD := "res://data/config/water_world.json"
const CHARACTERS := "res://data/config/water_characters.json"
const ENCOUNTERS := "res://data/config/water_encounters.json"
const COMBAT := "res://data/config/combat.json"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


static func trainer_spots(world: Dictionary, characters: Dictionary) -> Dictionary:
	var centres: Dictionary = {}
	for island: Dictionary in world.get("islands", []):
		centres[str(island.id)] = island.center_xz_m
	var bodies: Dictionary = {}
	for npc: Dictionary in characters.get("npcs", []):
		bodies[str(npc.id)] = npc
	var spots: Dictionary = {}
	for trainer: Dictionary in characters.get("trainers", []):
		var source: Dictionary = bodies.get(str(trainer.get("npc_entity_id", "")), trainer)
		var offset: Array = source.get("island_local_offset", [])
		var centre: Variant = centres.get(str(source.get("island_id", "")))
		if centre == null or offset.size() != 3:
			continue
		spots[str(trainer.id)] = Vector2(float(centre[0]) + float(offset[0]), float(centre[1]) + float(offset[2]))
	return spots


static func conflicts(spots: Dictionary, sites: Array, ring_m: float) -> Array[String]:
	var out: Array[String] = []
	for id: String in spots:
		var spot: Vector2 = spots[id]
		for site: Dictionary in sites:
			var at: Array = site.get("position", [])
			if at.size() != 3:
				continue
			var clearance := ring_m + float(site.get("radius_m", 0.0))
			var gap := spot.distance_to(Vector2(float(at[0]), float(at[2])))
			if gap < clearance:
				out.append("%s: %s at %.1f m (needs %.1f)" % [id, str(site.id), gap, clearance])
	return out


func test_no_wild_cluster_roams_into_a_trainer_fight_ring() -> void:
	var arena: Dictionary = _json(COMBAT).get("arena", {})
	var ring_m := float(arena.get("radius", 0.0)) + float(arena.get("occluder_clear_margin", 0.0))
	assert_true(ring_m >= 11.0, "combat arena radius is read from config")
	var spots := trainer_spots(_json(WORLD), _json(CHARACTERS))
	assert_true(spots.has("water_trainer_venn") and spots.has("water_trainer_sera"),
		"trainer spots resolve through reused NPC bodies")
	var found := conflicts(spots, _json(ENCOUNTERS).get("wild_sites", []), ring_m)
	assert_true(found.is_empty(), "wild clusters clear every trainer ring: %s" % ", ".join(found))


func test_the_check_catches_the_captured_venn_conflict() -> void:
	var spots := {"water_trainer_venn": Vector2(311.779, 3894.433)}
	var old_site := {"id": "road_visibility_veilfall_exploration_spine_02",
		"position": [305.343, 141.681, 3896.829], "radius_m": 3.0}
	assert_eq(conflicts(spots, [old_site], 13.0).size(), 1, "the 6.9 m pair from the capture is rejected")
