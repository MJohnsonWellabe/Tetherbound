extends "res://tests/test_case.gd"

## combat.json `arena.wild_post_clearance_1112` (LANE-THINGS, 12 Nov 2026):
## in Stormwood, wild spawns and wander targets keep clear of named
## conversation posts. Ships OFF until judged; OFF changes nothing.

const DIRECTOR := preload("res://scripts/combat/stormwood_encounter_director.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

var _director: Node = null


func before_each() -> void:
	_director = DIRECTOR.new()
	# Off the tree the realm lookup would ask for /root/Game; this is not Meadows.
	_director._meadows_ground_cached = 0


func after_each() -> void:
	_set_flag(false)
	if _director != null and is_instance_valid(_director):
		_director.free()


func _block() -> Dictionary:
	return (MATH.config().get("arena", {}) as Dictionary).get("wild_post_clearance_1112", {})


func _set_flag(on: bool) -> void:
	_block()["enabled"] = on


func test_ships_off_with_its_scope_declared() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json"))
	var block: Dictionary = (raw.get("arena", {}) as Dictionary).get("wild_post_clearance_1112", {})
	assert_false(bool(block.get("enabled", true)), "OFF until judged")
	assert_true(str(block.get("scope", "")).contains("host-authoritative"), "spawn placement is declared host-authoritative")
	assert_eq(float((block.get("radius_m", {}) as Dictionary).get("stormwood", 0.0)), 16.0)


func test_posts_cover_every_trainer_and_character() -> void:
	var posts: Array[Vector2] = DIRECTOR.conversation_posts()
	var trainers: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_trainers.json"))
	var people: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_npcs.json"))
	assert_eq(posts.size(), (trainers.trainers as Array).size() + (people.characters as Array).size())
	# Officer Nysa's post, as authored (x, z).
	assert_true(posts.has(Vector2(-890.0, 4482.0)), "Nysa's post is one of them")


func test_off_changes_nothing() -> void:
	_set_flag(false)
	var nysa := Vector3(-888.0, 52.0, 4483.0)
	assert_true(_director._clear_of_named_trainer_grounds(nysa), "OFF: a spot beside Nysa is allowed, as on main")
	assert_eq(_director._out_of_named_trainer_grounds(nysa), nysa, "OFF: nothing is pushed")


func test_on_pushes_a_spot_beside_a_post_out_to_the_radius_and_leaves_far_spots() -> void:
	_set_flag(true)
	var post := Vector2(-890.0, 4482.0)
	var beside := Vector3(-888.0, 52.0, 4483.0)
	assert_false(_director._clear_of_named_trainer_grounds(beside), "ON: a wander target beside Nysa is refused")
	var moved: Vector3 = _director._out_of_named_trainer_grounds(beside)
	assert_true(Vector2(moved.x, moved.z).distance_to(post) >= 16.0, "ON: a spawn beside Nysa is pushed out to the radius")
	assert_eq(moved.y, beside.y, "height is left to the ground snap")
	var far := Vector3(-850.0, 52.0, 4460.0)
	assert_true(_director._clear_of_named_trainer_grounds(far), "well outside the radius of every post is untouched")
	assert_eq(_director._out_of_named_trainer_grounds(far), far)
