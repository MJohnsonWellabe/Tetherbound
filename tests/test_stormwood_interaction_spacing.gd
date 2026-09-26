extends "res://tests/test_case.gd"

## No two Stormwood interaction providers authored in data may share one
## interaction circle: the arbiter offers whichever prompt is fractionally
## nearer, so a press meant for one can open the other. Found by the earned F11
## witness (run 22: a press for Officer Nysa was offered circuit Tavi, who stood
## exactly on her) and then by a static audit of every trainer, NPC, rod-line
## switch and camp prompt.
##
## Two circles overlap when their centres are closer than the sum of their
## radii: a trainer's challenge prompt 4.2 m (`trainer_npc.gd` PROMPT_RADIUS),
## an NPC's greeting 3.8 m (`npc_body.gd` add_prompt default), a rod-line switch
## 3.2 m at the station + (3, 0) (`stormwood_rod_stations.gd`), and a camp's
## rest prompt and creature bed the 3.6 m Interactable default.
const TRAINER_R := 4.2
const NPC_R := 3.8
const SWITCH_R := 3.2
const SWITCH_OFFSET := Vector2(3.0, 0.0)
const CAMP_R := 3.6
## A route pickup's prompt (`test_stormwood_pickups.gd` PICKUP_PROMPT_RADIUS_M).
const PICKUP_R := 2.4
const MAX_FLOOR_GAP_M := 10.0
## Pickup/NPC pairs `test_stormwood_pickups.gd` already lists as known.
const KNOWN_PICKUP_NPC: Array[String] = [
	"stormwood_pickup_route_19|",
	"stormwood_pickup_pocket_203|",
]
## One person authored twice: a talking NPC and the same person's trainer body
## on one spot. Whether they should be one body is an open design question
## (reported with WO-F11-04); listed so the list can only shrink.
const SAME_PERSON: Array[String] = [
	"captain_marrow_dynamo_core|captain_marrow",
	"courier_pim_pool_loop|courier_pim",
	"rook_circuit_lantern|ace_trainer_rook",
]


func _read(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


func _providers() -> Array:
	var out: Array = []
	for row: Dictionary in _read("res://data/config/stormwood_trainers.json").get("trainers", []):
		out.append({"kind": "trainer", "id": str(row.id), "at": Vector2(float(row.position[0]), float(row.position[2])), "y": float(row.position[1]), "r": TRAINER_R})
	for row: Dictionary in _read("res://data/config/stormwood_npcs.json").get("characters", []):
		out.append({"kind": "npc", "id": str(row.id), "at": Vector2(float(row.position[0]), float(row.position[2])), "y": float(row.position[1]), "r": NPC_R})
	for row: Dictionary in _read("res://data/config/stormwood_rod_stations.json").get("stations", []):
		out.append({"kind": "switch", "id": str(row.id), "at": Vector2(float(row.position[0]), float(row.position[1])) + SWITCH_OFFSET, "r": SWITCH_R})
	for row: Dictionary in _read("res://data/config/stormwood_camps.json").get("camps", []):
		out.append({"kind": "camp", "id": str(row.id), "at": Vector2(float(row.at[0]), float(row.at[1])), "r": CAMP_R})
		var bed: Dictionary = row.get("creature_bed", {})
		if not bed.is_empty():
			out.append({"kind": "camp", "id": str(row.id) + ":bed", "at": Vector2(float(bed.at[0]), float(bed.at[1])), "r": CAMP_R})
	for row: Dictionary in _read("res://data/config/stormwood_pickups.json").get("pickups", []):
		out.append({"kind": "pickup", "id": str(row.id), "at": Vector2(float(row.position[0]), float(row.position[2])), "y": float(row.position[1]), "r": PICKUP_R})
	return out


## Pairs that overlap. A camp's own rest prompt and bed, and two NPCs talking
## side by side (neither is a challenge or a switch), are ordinary neighbours.
static func overlaps(providers: Array) -> Array[String]:
	var out: Array[String] = []
	for i in providers.size():
		for j in range(i + 1, providers.size()):
			var a: Dictionary = providers[i]
			var b: Dictionary = providers[j]
			if (a.kind == "camp" and b.kind == "camp") or (a.kind == "npc" and b.kind == "npc") \
					or (a.kind == "pickup" and b.kind == "pickup"):
				continue
			# Different floors never share a circle: route pickup 19 lies on the
			# ground 150 m below Captain Marrow's Dynamo platform.
			if a.has("y") and b.has("y") and absf(float(a.y) - float(b.y)) > MAX_FLOOR_GAP_M:
				continue
			var gap := (a.at as Vector2).distance_to(b.at)
			if gap < float(a.r) + float(b.r):
				out.append("%s:%s|%s:%s %.1f m" % [a.kind, a.id, b.kind, b.id, gap])
	return out


func test_no_two_interaction_circles_overlap() -> void:
	for pair: String in overlaps(_providers()):
		var ids := pair.get_slice(" ", 0).replace("trainer:", "").replace("npc:", "")
		var known_pickup := false
		for prefix: String in KNOWN_PICKUP_NPC:
			known_pickup = known_pickup or (pair.begins_with("npc:") and pair.contains("pickup:" + prefix.trim_suffix("|")))
		assert_true(SAME_PERSON.has(ids) or known_pickup, "overlapping interaction circles: " + pair)


func test_same_person_pairs_are_still_real() -> void:
	# The exemption list only shrinks: every listed pair must still overlap.
	var found := overlaps(_providers()).map(func(pair: String) -> String:
		return pair.get_slice(" ", 0).replace("trainer:", "").replace("npc:", ""))
	for pair: String in SAME_PERSON:
		assert_true(found.has(pair), "same-person pair no longer overlaps; drop it from the list: " + pair)


func test_negative_control_detects_a_stacked_pair() -> void:
	var stacked := [{"kind": "trainer", "id": "a", "at": Vector2(-890, 4490), "r": TRAINER_R},
		{"kind": "trainer", "id": "b", "at": Vector2(-890, 4490), "r": TRAINER_R}]
	assert_eq(overlaps(stacked).size(), 1)
