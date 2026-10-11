extends "res://tests/test_case.gd"

## The host resolves a peer's fighting creature for wild AI targeting and for
## judging that peer's strikes. A hidden member of the deployed group listed
## first (a mirror, a replacement still grounding, a body from the previous
## wild encounter) once won: the Stormwood Nysa press then logged 190 host
## misses and a Stormraven that never attacked.

const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")

var _bodies: Array[Node3D] = []
var _body_script: GDScript

func before_each() -> void:
	_body_script = GDScript.new()
	_body_script.source_code = "extends Node3D\nvar owner_peer_id := 0\n"
	_body_script.reload()

func after_each() -> void:
	for body: Node3D in _bodies:
		if is_instance_valid(body): body.free()
	_bodies.clear()

func _body(owner: int, visible: bool, at: Vector3) -> Node3D:
	var body := Node3D.new()
	body.set_script(_body_script)
	body.set("owner_peer_id", owner)
	body.visible = visible
	body.position = at
	_bodies.append(body)
	return body

func test_two_encounters_in_range_resolve_each_peer_to_its_visible_fighting_body() -> void:
	# Encounter A's stale hidden body for peer 2 is listed before peer 2's
	# visible creature now fighting encounter B beside it.
	var stale := _body(2, false, Vector3(-30, 0, 0))
	var fighting := _body(2, true, Vector3(4, 0, 1))
	var other_peer := _body(3, true, Vector3(6, 0, 2))
	var candidates: Array = [stale, other_peer, fighting]
	assert_eq(DIRECTOR.pick_peer_body(candidates, 2, 1, null), fighting,
		"the visible creature answers for its peer, not a hidden member listed first")
	assert_eq(DIRECTOR.pick_peer_body(candidates, 3, 1, null), other_peer)

func test_local_peer_answers_with_its_own_ally_body() -> void:
	var hidden_mirror := _body(1, false, Vector3(-30, 0, 0))
	var ally := _body(1, true, Vector3(2, 0, 0))
	assert_eq(DIRECTOR.pick_peer_body([hidden_mirror, ally], 1, 1, ally), ally)
	# Even while the ally is still grounding (hidden), it is the local body.
	ally.visible = false
	assert_eq(DIRECTOR.pick_peer_body([hidden_mirror, ally], 1, 1, ally), ally)

func test_hidden_body_is_only_a_fallback_and_absent_peer_has_none() -> void:
	var only_hidden := _body(4, false, Vector3.ZERO)
	assert_eq(DIRECTOR.pick_peer_body([only_hidden], 4, 1, null), only_hidden,
		"a peer whose only member is hidden still resolves to it")
	assert_eq(DIRECTOR.pick_peer_body([only_hidden], 5, 1, null), null)
