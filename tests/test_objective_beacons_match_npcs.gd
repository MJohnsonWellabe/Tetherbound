extends "res://tests/test_case.gd"

## Playtest (2026-09-29): the "Meet Tam" story beacon pointed at (8, -16) while Tam
## the smith, the villager whose `village_tam_tools` conversation gives the tools,
## stands at (8, 12): 28 m apart, so the story sent the player to the wrong spot.
## A beacon that names a villager must sit on that villager.

const OBJECTIVES_PATH := "res://data/progression/objectives.json"
const NPCS_PATH := "res://data/config/village_npcs.json"
## A beacon is a marker over the character, not a stand-in for a whole area.
const MAX_BEACON_OFFSET_M := 6.0


func _read(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## Every objective carrying a `beacon`, at any depth.
func _beacons(node: Variant, out: Array) -> void:
	if node is Dictionary:
		var beacon: Variant = (node as Dictionary).get("beacon", null)
		if beacon is Dictionary and (beacon as Dictionary).has("position"):
			out.append({"id": str((node as Dictionary).get("id", "")), "beacon": beacon})
		for value: Variant in (node as Dictionary).values():
			_beacons(value, out)
	elif node is Array:
		for value: Variant in (node as Array):
			_beacons(value, out)


func _villagers() -> Dictionary:
	var by_name := {}
	var data: Variant = _read(NPCS_PATH)
	assert_true(data is Dictionary, "the village roster parses")
	for villager: Variant in (data as Dictionary).get("villagers", []):
		by_name[str((villager as Dictionary).get("name", ""))] = (villager as Dictionary).get("position", [])
	return by_name


func test_a_beacon_that_names_a_villager_sits_on_that_villager() -> void:
	var beacons: Array = []
	_beacons(_read(OBJECTIVES_PATH), beacons)
	assert_true(beacons.size() > 0, "the objective ladder carries beacons")
	var villagers := _villagers()
	var checked := 0
	for entry: Dictionary in beacons:
		var beacon: Dictionary = entry["beacon"]
		var who := str(beacon.get("display_name", ""))
		if not villagers.has(who):
			continue
		checked += 1
		var at: Array = beacon["position"]
		var home: Array = villagers[who]
		var offset := Vector2(float(at[0]) - float(home[0]), float(at[1]) - float(home[1])).length()
		assert_true(offset <= MAX_BEACON_OFFSET_M,
			"objective %s: the beacon for %s is %.1f m from where %s stands (max %.1f m)" % [
				entry["id"], who, offset, who, MAX_BEACON_OFFSET_M])
	assert_true(checked >= 2, "the check reaches Tam's and Halda's beacons")


func test_the_meet_tam_beacon_is_at_the_smiths_workshop() -> void:
	var beacons: Array = []
	_beacons(_read(OBJECTIVES_PATH), beacons)
	var tam: Array = _villagers().get("Tam", [])
	var found := false
	for entry: Dictionary in beacons:
		if entry["id"] == "village_tools":
			found = true
			var at: Array = (entry["beacon"] as Dictionary)["position"]
			assert_almost_eq(float(at[0]), float(tam[0]), MAX_BEACON_OFFSET_M, "x matches Tam's")
			assert_almost_eq(float(at[1]), float(tam[1]), MAX_BEACON_OFFSET_M, "z matches Tam's")
	assert_true(found, "the village_tools objective exists")
