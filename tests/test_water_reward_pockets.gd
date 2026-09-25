extends "res://tests/test_case.gd"
## F13: Tidewake's eight authored reward pockets (water_world.json
## `reward_pockets`). The six single-item pockets are filled by EXISTING
## personal Skill Candy rows moved inside the pocket radius; no item, tier,
## amount or claim policy changes. The two composite pockets have no matching
## item and stay explicitly unresolved pending an owner decision.
## Analytic heightfield evidence only; not a Terrain3D bake or walked route.
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const RULE := preload("res://scripts/world/water_personal_pickup.gd")
const PICKUPS := "res://data/config/water_pickups.json"
const DRY_MIN_M := 0.8
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
## Composite roles with no existing item identity. Owner decision required;
## this test proves they are still reserved, not that they pay out.
const UNRESOLVED := {
	"reed_root_hollow": "recipe_and_reed_fiber",
	"cradle_shell_nest": "reefstone_and_mount_care",
}

var _field
var _world: Dictionary
var _data: Dictionary

func before_each() -> void:
	super.before_each()
	_field = FIELD.new()
	_world = FIELD.load_config()
	_data = JSON.parse_string(FileAccess.get_file_as_string(PICKUPS))

func _xz(at: Array) -> Vector2:
	return Vector2(float(at[0]), float(at[2]))

func _dry_footing(p: Vector2) -> bool:
	for offset: Vector2 in [Vector2.ZERO, Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var q := p + offset
		if not (_field.height_at(q.x, q.y) >= DRY_MIN_M and _field.slope_degrees_at(q.x, q.y) <= MAX_SLOPE_DEG):
			return false
	return true

## 2 m grid flood fill over dry, gentle cells within the island's bounds.
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

func test_eight_pockets_are_six_filled_plus_two_unresolved() -> void:
	assert_eq(_world.reward_pockets.size(), 8, "WORLD §6.1 authors eight reward pockets")
	for pocket: Dictionary in _world.reward_pockets:
		assert_true(FILLED.has(pocket.id) or UNRESOLVED.has(pocket.id), "Every pocket is either filled or explicitly unresolved: " + str(pocket.id))
	assert_eq(FILLED.size() + UNRESOLVED.size(), 8)

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
		assert_eq(row.island_id, pocket.island_id, "Row stays on the pocket's island")
		assert_eq(row.category, "skill_candy")
		assert_eq(row.claim_policy, "character_once", "Personal claim semantics unchanged")
		assert_eq(int(row.quantity), 1, "Amount unchanged")
		var at := _xz(row.position)
		assert_true(_dry_footing(at), "Dry, gentle footing at " + str(row.id))
		assert_almost_eq(float(row.position[1]), _field.height_at(at.x, at.y), 0.01, "Authored y is the analytic ground: " + str(row.id))
		assert_eq(_field.island_id_at(at.x, at.y), pocket.island_id, "Ground belongs to the pocket island")
		var landing_connected := false
		for anchor: Dictionary in _world.anchors:
			if anchor.island_id == pocket.island_id and anchor.kind != "rest_shoal":
				assert_true(_xz(anchor.safe_position).distance_to(at) >= 12.0, "Landing stays clear")
				landing_connected = landing_connected or _connected(_xz(anchor.safe_position), at, str(pocket.island_id))
		assert_true(landing_connected, "Dry, gentle ground connects a landing to " + str(row.id))
		for other: Dictionary in _data.pickups + _data.harvest:
			if other.id != row.id:
				assert_true(at.distance_to(_xz(other.position)) >= 5.99, "Placement spacing kept: " + str(row.id))
		# The host claim rule accepts a character standing at the new spot.
		var context := {"peer": 7, "character_id": "pocket-check", "realm": "water",
			"position": Vector3(at.x, _field.height_at(at.x, at.y), at.y)}
		var verdict := RULE.evaluate({"pickup_id": row.id, "realm": "water", "personal_claimed": false}, context, {})
		assert_true(verdict.ok, "Host claim accepted at the pocket: " + str(row.id))

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
