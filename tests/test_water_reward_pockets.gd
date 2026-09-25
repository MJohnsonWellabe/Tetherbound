extends "res://tests/test_case.gd"
## F13: Tidewake's eight authored reward pockets (water_world.json
## `reward_pockets`). The six single-item pockets are filled by EXISTING
## personal Skill Candy rows moved inside the pocket radius; no item, tier,
## amount or claim policy changes. `cradle_shell_nest` pays the
## `side_water_cradle_care` gather (WORLD.md Tidewake local chains: the dry
## nest's 4 Reef Stone, once) through one existing Tidal Cradle seam moved
## into it. `reed_root_hollow` has no matching item and stays explicitly
## unresolved pending an owner decision. The chain's 3 berries are Otto's
## return payout (side_water_cradle_care, tests/test_water_cradle_care.gd), so
## the Tidal Cradle berries row stands at its original inland spot again.
## Analytic heightfield checks here; the baked-ground walk from each island's
## landing and the real Interact claim are tests/smoke_water_pocket_walk_claim.gd.
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const RULE := preload("res://scripts/world/water_personal_pickup.gd")
const PICKUPS := "res://data/config/water_pickups.json"
const DRY_MIN_M := 0.8
const DOCK_RULES := preload("res://scripts/world/water_dock_rules.gd")
## Positions before this change, to prove each move actually took the claim.
const OLD_POSITIONS := {
	"water:deep_watch:pickup:002": Vector2(1398.0, 3542.0),
	"water:lantern_cove:pickup:002": Vector2(-326.0, 158.0),
	"water:gull_rest:pickup:002": Vector2(-52.0, 804.0),
	"water:salt_crown:pickup:001": Vector2(6.0, 2316.0),
	"water:drowned_garden:pickup:002": Vector2(1158.0, 2270.0),
	"water:brine_steps:pickup:001": Vector2(372.0, 552.0),
}
const MAX_SLOPE_DEG := 35.0
## Pocket -> the existing row placed in it. Lantern Cove uses pickup:002
## (97 m from the pocket) rather than pickup:001 (163 m): the nearer tier-I row.
const FILLED := {
	"deep_watch_tidecoil_cache": "water:deep_watch:pickup:002",
	"lantern_hidden_cache": "water:lantern_cove:pickup:002",
	"gull_research_satchel": "water:gull_rest:pickup:002",
	"salt_bell_terrace": "water:salt_crown:pickup:001",
	"garden_exposed_vault": "water:drowned_garden:pickup:002",
	"brine_upper_shelf": "water:brine_steps:pickup:001",
}
## Composite role with no existing item identity. Owner decision required;
## this test proves it is still reserved, not that it pays out.
const UNRESOLVED := {
	"reed_root_hollow": "recipe_and_reed_fiber",
}
## side_water_cradle_care gather: the existing Tidal Cradle seam moved into the
## nest, with the chain's authored amount. Former position proves the move.
const CRADLE := "cradle_shell_nest"
const CRADLE_ROWS := {
	"water:tidal_cradle:harvest:007": {"item": "reef_stone", "amount": 4, "was": Vector2(568.0, 1698.0)},
}
## The berries row that briefly paid at the nest, back at its original spot
## with its original single berry; Otto's return pays the chain's 3 berries.
const CRADLE_BERRIES := "water:tidal_cradle:pickup:009"
const CRADLE_BERRIES_HOME := Vector2(592.0, 1668.0)

var _field
var _world: Dictionary
var _data: Dictionary
var _camps: Array = []
var _dock: Dictionary
var _characters: Dictionary

func before_each() -> void:
	super.before_each()
	_field = FIELD.new()
	_world = FIELD.load_config()
	_data = JSON.parse_string(FileAccess.get_file_as_string(PICKUPS))
	_camps = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_camps.json")).camps
	_dock = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_dock_actions.json"))
	_characters = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))

func _xz(at: Array) -> Vector2:
	return Vector2(float(at[0]), float(at[2]))

func _claim_radius() -> float:
	var tuning: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
	return float(tuning.get("pickups", {}).get("claim_radius_m", 3.6))


func _people(island_id: String) -> Array[Vector2]:
	var centre := Vector2.ZERO
	for island: Dictionary in _world.islands:
		if str(island.id) == island_id:
			centre = Vector2(float(island.center_xz_m[0]), float(island.center_xz_m[1]))
	var out: Array[Vector2] = []
	for list: String in ["npcs", "trainers"]:
		for person: Dictionary in _characters.get(list, []):
			if str(person.get("island_id", "")) == island_id and person.has("island_local_offset"):
				var offset: Array = person.island_local_offset
				out.append(centre + Vector2(float(offset[0]), float(offset[2])))
	return out


func _dry_footing(p: Vector2) -> bool:
	for offset: Vector2 in [Vector2.ZERO, Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var q := p + offset
		if not (_field.height_at(q.x, q.y) >= DRY_MIN_M and _field.slope_degrees_at(q.x, q.y) <= MAX_SLOPE_DEG):
			return false
	return true

## 2 m grid flood fill over cells that are dry and within the MAX_SLOPE_DEG
## walk-slope limit, inside the island's bounds.
func _connected(a: Vector2, b: Vector2, island_id: String) -> bool:
	var island: Dictionary = {}
	for spec: Dictionary in _world.islands:
		if spec.id == island_id:
			island = spec
	if island.is_empty():
		return false
	var reach := float(island.shore_radius_m) + 20.0
	var lo := Vector2(island.center_xz_m[0], island.center_xz_m[1]) - Vector2(reach, reach)
	var hi := lo + Vector2(reach, reach) * 2.0
	var step := 2.0
	var start := Vector2i(roundi((a.x - lo.x) / step), roundi((a.y - lo.y) / step))
	var goal := Vector2i(roundi((b.x - lo.x) / step), roundi((b.y - lo.y) / step))
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		if cell.distance_to(goal) <= 1.5:
			return true
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next := cell + d
			if seen.has(next):
				continue
			seen[next] = true
			var w := lo + Vector2(next) * step
			if w.x < lo.x or w.y < lo.y or w.x > hi.x or w.y > hi.y:
				continue
			if _field.height_at(w.x, w.y) >= DRY_MIN_M and _field.slope_degrees_at(w.x, w.y) <= MAX_SLOPE_DEG:
				queue.append(next)
	return false

func _pocket(id: String) -> Dictionary:
	for pocket: Dictionary in _world.reward_pockets:
		if pocket.id == id:
			return pocket
	return {}

func test_eight_pockets_are_six_filled_cradle_paid_and_one_unresolved() -> void:
	assert_eq(_world.reward_pockets.size(), 8, "WORLD §6.1 authors eight reward pockets")
	for pocket: Dictionary in _world.reward_pockets:
		assert_true(FILLED.has(pocket.id) or UNRESOLVED.has(pocket.id) or pocket.id == CRADLE,
			"Every pocket is filled, the Cradle chain payout, or explicitly unresolved: " + str(pocket.id))
	assert_eq(FILLED.size() + UNRESOLVED.size() + 1, 8)

## The shared placement contract every pocket row meets: on the pocket's
## island, analytic y, footing dry and within the MAX_SLOPE_DEG walk-slope
## limit (not "gentle": pockets sit on 8-31 degree ground), connected to a
## landing, spaced from every other placement and clear of people, camps, dock
## equipment and landings.
func _assert_pocket_placement(row: Dictionary, pocket: Dictionary) -> void:
	var at := _xz(row.position)
	assert_eq(row.island_id, pocket.island_id, "Row stays on the pocket's island")
	assert_true(_xz(pocket.position).distance_to(at) <= float(pocket.radius_m), "Row inside pocket radius: " + str(row.id))
	assert_true(_dry_footing(at), "Dry footing within the walk-slope limit at " + str(row.id))
	assert_almost_eq(float(row.position[1]), _field.height_at(at.x, at.y), 0.01, "Authored y is the analytic ground: " + str(row.id))
	assert_eq(_field.island_id_at(at.x, at.y), pocket.island_id, "Ground belongs to the pocket island")
	var landing_connected := false
	for anchor: Dictionary in _world.anchors:
		if anchor.island_id == pocket.island_id and anchor.kind != "rest_shoal":
			assert_true(_xz(anchor.safe_position).distance_to(at) >= 12.0, "Landing stays clear")
			landing_connected = landing_connected or _connected(_xz(anchor.safe_position), at, str(pocket.island_id))
	assert_true(landing_connected, "Dry ground within the walk-slope limit connects a landing to " + str(row.id))
	for other: Dictionary in _data.pickups + _data.harvest:
		if other.id != row.id:
			assert_true(at.distance_to(_xz(other.position)) >= 5.99, "Placement spacing kept: " + str(row.id))
	var clearance := float(_data.validation.npc_and_trainer_clearance_m)
	for person: Vector2 in _people(str(pocket.island_id)):
		assert_true(person.distance_to(at) >= clearance, "NPC/trainer clearance at " + str(row.id))
	for camp: Dictionary in _camps:
		assert_true(Vector2(float(camp.at[0]), float(camp.at[1])).distance_to(at) >= clearance, "Camp clearance at " + str(row.id))
	for action: Dictionary in _dock.actions:
		var equipment := DOCK_RULES.action_position(action, _world, _field.height_at)
		if equipment.is_finite():
			assert_true(Vector2(equipment.x, equipment.z).distance_to(at) >= clearance, "Dock equipment clearance at " + str(row.id))

func test_single_item_pockets_hold_exactly_one_matching_existing_row() -> void:
	for pocket_id: String in FILLED:
		var pocket := _pocket(pocket_id)
		assert_false(pocket.is_empty(), "Pocket exists in config: " + pocket_id)
		if pocket.is_empty():
			continue
		var centre := _xz(pocket.position)
		var inside: Array[Dictionary] = []
		for row: Dictionary in _data.pickups:
			if row.item_id == pocket.reward_role and _xz(row.position).distance_to(centre) <= float(pocket.radius_m):
				inside.append(row)
		assert_eq(inside.size(), 1, "Exactly one %s row inside %s" % [pocket.reward_role, pocket_id])
		if inside.size() != 1:
			continue
		var row: Dictionary = inside[0]
		assert_eq(row.id, FILLED[pocket_id], "Pocket holds the documented existing row")
		assert_eq(row.get("reward_pocket_id", ""), pocket_id, "Row names its pocket")
		assert_eq(row.category, "skill_candy")
		assert_eq(row.claim_policy, "character_once", "Personal claim semantics unchanged")
		assert_eq(int(row.quantity), 1, "Amount unchanged")
		_assert_pocket_placement(row, pocket)
		var at := _xz(row.position)
		# The host claim rule accepts a character standing at the new spot.
		var context := {"peer": 7, "character_id": "pocket-check", "realm": "water",
			"position": Vector3(at.x, _field.height_at(at.x, at.y), at.y)}
		# Disclosed fixture: a pocket gated by its named resolution (Deep Watch's
		# Tidecoil cache) is proven locked here, then checked with its gate met.
		var unlocked := {}
		for flag: Variant in row.get("requires_world_flags", []):
			unlocked[str(flag)] = true
		if not unlocked.is_empty():
			assert_eq(RULE.evaluate({"pickup_id": row.id, "realm": "water", "personal_claimed": false}, context, {}).code,
				"locked", "Gated pocket refuses before its world flag: " + str(row.id))
		var verdict := RULE.evaluate({"pickup_id": row.id, "realm": "water", "personal_claimed": false}, context, unlocked)
		assert_true(verdict.ok, "Host claim accepted at the pocket: " + str(row.id))
		# Just inside the host's claim reach still succeeds; the row's former
		# position (the empty pocket's old occupant spot) is now out of reach.
		# The host measures 3D distance, so on a slope a sideways step reaches
		# less far; every standing spot 3 m out that is within 3D reach must be
		# accepted, and at least one such spot must exist around the pocket.
		var target := Vector3(at.x, _field.height_at(at.x, at.y), at.y)
		var reachable := 0
		for step in 16:
			var near := at + Vector2(cos(TAU * step / 16.0), sin(TAU * step / 16.0)) * 3.0
			var stand := Vector3(near.x, _field.height_at(near.x, near.y), near.y)
			if stand.distance_to(target) > _claim_radius() - 0.05:
				continue
			reachable += 1
			context.position = stand
			assert_true(RULE.evaluate({"pickup_id": row.id, "realm": "water", "personal_claimed": false}, context, unlocked).ok,
				"Host claim accepted 3 m away within reach: " + str(row.id))
		assert_true(reachable > 0, "Some standing spot 3 m away can claim " + str(row.id))
		var old_at: Vector2 = OLD_POSITIONS[row.id]
		context.position = Vector3(old_at.x, _field.height_at(old_at.x, old_at.y), old_at.y)
		assert_eq(RULE.evaluate({"pickup_id": row.id, "realm": "water", "personal_claimed": false}, context, unlocked).code,
			"too_far", "Former position no longer claims: " + str(row.id))

func test_cradle_nest_pays_the_care_chain_once() -> void:
	var pocket := _pocket(CRADLE)
	assert_false(pocket.is_empty(), "Cradle nest pocket authored")
	if pocket.is_empty():
		return
	assert_eq(pocket.reward_role, "reefstone_and_mount_care", "Pocket role unchanged")
	var inside := {}
	for kind: String in ["pickups", "harvest"]:
		for row: Dictionary in _data[kind]:
			if _xz(row.position).distance_to(_xz(pocket.position)) <= float(pocket.radius_m):
				inside[row.id] = row
			if row.get("reward_pocket_id", "") == CRADLE:
				assert_true(CRADLE_ROWS.has(row.id), "Only the documented rows name the nest: " + str(row.id))
	assert_eq(inside.keys().size(), CRADLE_ROWS.size(), "The nest holds exactly the chain's Reef Stone seam")
	var paid := {}
	for id: String in CRADLE_ROWS:
		var spec: Dictionary = CRADLE_ROWS[id]
		assert_true(inside.has(id), "Nest holds " + id)
		if not inside.has(id):
			continue
		var row: Dictionary = inside[id]
		assert_eq(row.get("reward_pocket_id", ""), CRADLE, "Row names the nest")
		assert_eq(row.item_id, spec.item, "Existing item identity: " + id)
		assert_true(_xz(row.position).distance_to(spec.was) > 100.0, "Row actually moved from its former spot: " + id)
		_assert_pocket_placement(row, pocket)
		if row.has("yield"):
			# A harvest seam: one durable world-once gather, tool-gated.
			assert_eq(row.gather_action, "pickaxe", "Reef Stone is mined")
			paid[row.item_id] = int(row["yield"])
		else:
			# An ordinary world-once find: one claim for the world, never renewable.
			assert_eq(row.claim_policy, "existing_world_pickup_policy", "Berries use the ordinary once-per-world find")
			assert_eq(row.category, "food")
			paid[row.item_id] = int(row.quantity)
	assert_eq(paid, {"reef_stone": 4}, "WORLD side_water_cradle_care: the dry nest's 4 Reef Stone, once")
	var berries: Dictionary = {}
	for row: Dictionary in _data.pickups:
		if row.id == CRADLE_BERRIES:
			berries = row
	assert_false(berries.is_empty(), "Tidal Cradle berries row still authored")
	assert_almost_eq(_xz(berries.position).distance_to(CRADLE_BERRIES_HOME), 0.0, 0.01, "Berries back at their original inland spot")
	assert_eq(int(berries.get("quantity", 0)), 1, "Original single berry find")
	assert_false(berries.has("reward_pocket_id"), "Berries no longer name the nest")
	# Moves stay on the island: per-island and per-item row counts unchanged.
	var cradle := {"pickups": 0, "harvest": 0}
	var rows := {"berries": 0, "reef_stone": 0}
	for row: Dictionary in _data.pickups:
		cradle.pickups += 1 if row.island_id == "tidal_cradle" else 0
		rows.berries += 1 if row.item_id == "berries" else 0
	for row: Dictionary in _data.harvest:
		cradle.harvest += 1 if row.island_id == "tidal_cradle" else 0
		rows.reef_stone += 1 if row.item_id == "reef_stone" else 0
	assert_eq(cradle.pickups, int(_data.census.by_island.tidal_cradle.pickups))
	assert_eq(cradle.harvest, int(_data.census.by_island.tidal_cradle.harvest))
	assert_eq(rows.berries, int(_data.census.pickup_item_counts.berries), "Census item counts are row counts")
	assert_eq(rows.reef_stone, int(_data.census.harvest_item_counts.reef_stone))
	# The saddle's four Reef Stone near the Cradle landing are untouched.
	var near_landing := 0
	for row: Dictionary in _data.harvest:
		if row.item_id == "reef_stone" and row.island_id == "tidal_cradle" and _xz(row.position).distance_to(Vector2(535.497, 1352.51)) < 60.0:
			near_landing += int(row["yield"])
	assert_eq(near_landing, 4, "Saddle Reef Stone by the Cradle arrival unchanged")

func test_composite_pockets_remain_explicitly_unresolved() -> void:
	var registered := {}
	for entry: Dictionary in _data.planned_item_registrations:
		registered[entry.id] = true
	for pocket_id: String in UNRESOLVED:
		var pocket := _pocket(pocket_id)
		assert_false(pocket.is_empty(), "Composite pocket still authored: " + pocket_id)
		assert_eq(pocket.get("reward_role", ""), UNRESOLVED[pocket_id], "Composite role unchanged")
		assert_false(registered.has(UNRESOLVED[pocket_id]), "No invented item for composite role " + pocket_id)
		for row: Dictionary in _data.pickups:
			assert_ne(row.get("reward_pocket_id", ""), pocket_id, "No row claims unresolved pocket " + pocket_id)

func test_candy_tiers_and_identities_unchanged() -> void:
	var tiers := {}
	var ids := {}
	for row: Dictionary in _data.pickups + _data.harvest:
		assert_false(ids.has(row.id), "Unique placement id: " + str(row.id))
		ids[row.id] = true
		if row.get("category", "") == "skill_candy":
			tiers[row.item_id] = int(tiers.get(row.item_id, 0)) + int(row.quantity)
	assert_eq(tiers, {"skill_candy_i": 7, "skill_candy_ii": 4, "skill_candy_iii": 1}, "Skill Candy 7/4/1 split")
	assert_eq(_data.pickups.size(), 200)
	assert_eq(_data.harvest.size(), 182)
	assert_eq(int(_data.census.pickup_item_counts.skill_candy_i), 7)
	assert_eq(int(_data.census.pickup_item_counts.skill_candy_ii), 4)
	assert_eq(int(_data.census.pickup_item_counts.skill_candy_iii), 1)

func test_every_pickup_keeps_dry_spawn_ground() -> void:
	# water_scene_pickups refuses a spawn whose ground is below sea level.
	for row: Dictionary in _data.pickups:
		var at := _xz(row.position)
		var height: float = _field.height_at(at.x, at.y)
		assert_true(is_finite(height) and height >= 0.0, "Pickup has dry spawn ground: " + str(row.id))
		if row.has("reward_pocket_id"):
			assert_true(height >= DRY_MIN_M, "Pocket row meets the file's dry minimum: " + str(row.id))
