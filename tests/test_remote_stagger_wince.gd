extends "res://tests/test_case.gd"

# P2-016 follow-up: a blow that staggered a player's creature reaches every other
# peer's copy as a hit carrying `stagger_seconds`; that copy holds the wince for
# it, bounded. A plain hit keeps the ordinary short wince.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const REMOTE_CREATURE := preload("res://scripts/creatures/remote_creature.gd")
const RUNS_IN_INITIALIZED_TREE := true

var _root: Node3D = null


func before_each() -> void:
	super.before_each()
	_root = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(_root)


func after_each() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null
	super.after_each()


func test_a_staggering_hit_holds_the_wince_on_a_remote_copy() -> void:
	var body := await _remote("mudsnout")
	body.call("play_presentation", "hit", {"kind": "hit", "fraction": 0.2, "stagger_seconds": 0.6})
	var animator: Object = body.get("_animator")
	assert_almost_eq(float(animator.get("_stagger_left")), 0.6, 0.0001, "the wince holds for the stagger")


func test_a_plain_hit_and_a_huge_report_are_bounded() -> void:
	var body := await _remote("mudsnout")
	body.call("play_presentation", "hit", {"kind": "hit", "fraction": 0.2})
	var animator: Object = body.get("_animator")
	assert_almost_eq(float(animator.get("_stagger_left")), 0.0, 0.0001, "a plain hit holds nothing")
	body.call("play_presentation", "hit", {"kind": "hit", "fraction": 0.2, "stagger_seconds": 99.0})
	assert_almost_eq(float(animator.get("_stagger_left")), REMOTE_CREATURE.MAX_REMOTE_STAGGER_S, 0.0001,
		"a peer's report is clamped")


func _remote(id: String) -> Node3D:
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(REMOTE_CREATURE)
	body.set("species_id", id)
	_root.add_child(body)
	for _i in 3:
		await (Engine.get_main_loop() as SceneTree).process_frame
	return body
