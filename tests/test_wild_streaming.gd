extends "res://tests/test_case.gd"

## STREAM-D: distance-based activation for wild creatures.
##
## `encounter_director.gd::_tick_streaming()` is the fix for the density the
## owner has asked for (~70 -> 700-1100 creatures across the chapter): a
## cluster far from the player must not tick, one near the player must tick
## exactly as it always has, and a creature engaged/fainting/respawning must
## never be switched off regardless of distance — deactivating one mid-catch
## would be the exact bug this file exists to keep out.
##
## Per docs/decisions/D02 the suite is pure logic; nothing here touches
## Terrain3D or a live physics tick. `_tick_streaming()` itself does not need
## either — it only reads `Node3D.global_position` (works on a freestanding
## node never added to a tree) and calls `set_physics_process()`/
## `is_physics_processing()` (also freestanding-safe: the flag is just Node
## state, and only the ENGINE actually calling `_physics_process()` needs a
## live tree). So `encounter_director.gd` is instantiated directly here, its
## private streaming fields are populated by hand to the shape
## `_spawn_creatures()` would have built, and its private functions are
## called directly — the same "assert the thing exists, then assert it
## behaves" the task asked for, without the multi-minute Terrain3D boot the
## smoke tests already own (`smoke_aggression.gd`, `smoke_traversal.gd`).

const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")


func _new_director() -> Node:
	# `.new()`, never added to a tree: `_ready()` (which needs a real player/
	# manager NodePath and a live `get_tree()`) never runs, and nothing this
	# file calls needs it to.
	return DIRECTOR.new()


func _fake_player(pos: Vector3) -> CharacterBody3D:
	# `_player` is typed `CharacterBody3D` on the real node (the real Player
	# scene's body), and `.set()` on a typed script var enforces that type at
	# runtime the same as a direct assignment would.
	var player := CharacterBody3D.new()
	player.global_position = pos
	return player


func _member(pos: Vector3) -> Node3D:
	var wild := Node3D.new()
	wild.global_position = pos
	wild.set_physics_process(true)  # matches a freshly instantiated body's real default
	return wild


func _cluster(centre: Vector3, radius: float, members: Array[Node3D]) -> Dictionary:
	return {"centre": centre, "radius": radius, "members": members, "active": true}


func _cleanup(director: Node, player: Node3D, members: Array[Node3D]) -> void:
	director.free()
	player.free()
	for m in members:
		if is_instance_valid(m):
			m.free()


# --- the thing exists --------------------------------------------------------

func test_tick_streaming_and_activation_margin_exist_and_are_callable() -> void:
	var director := _new_director()
	assert_true(director.has_method("_tick_streaming"))
	assert_true(director.has_method("_set_wild_active"))
	assert_true(director.has_method("_activation_radius_margin"))
	var margin: float = director.call("_activation_radius_margin")
	assert_true(margin > 0.0, "activation margin must clear a real detection range, not be zero/negative")
	director.free()


# --- it behaves: a distant cluster sleeps, a near one does not ---------------

func test_distant_cluster_is_deactivated_near_cluster_stays_active() -> void:
	var director := _new_director()
	var player := _fake_player(Vector3.ZERO)
	var near_members: Array[Node3D] = [_member(Vector3(5, 0, 0)), _member(Vector3(-4, 0, 3))]
	var far_members: Array[Node3D] = [_member(Vector3(2000, 0, 0))]
	director.set("_player", player)
	director.set("_clusters", [
		_cluster(Vector3(0, 0, 0), 10.0, near_members),
		_cluster(Vector3(2000, 0, 0), 10.0, far_members),
	] as Array[Dictionary])

	director.call("_tick_streaming")

	for m in near_members:
		assert_true(m.is_physics_processing(), "a cluster the player is standing inside must keep ticking")
	for m in far_members:
		assert_false(m.is_physics_processing(), "a cluster 2km away must stop ticking")

	# And the reverse transition, in one call: walk the player to the far
	# cluster and back nowhere near the first — this is the "per-cluster
	# check", not "compute once and never revisit" — asserted directly rather
	# than assumed from the first half.
	player.global_position = Vector3(2000, 0, 0)
	director.call("_tick_streaming")
	for m in far_members:
		assert_true(m.is_physics_processing(), "the cluster the player just walked into must wake up")
	for m in near_members:
		assert_false(m.is_physics_processing(), "the cluster the player just left must go back to sleep")

	_cleanup(director, player, near_members + far_members)


# --- it behaves: engaged / fainting / respawning are never touched -----------

func test_engaged_fainting_and_respawning_members_are_never_deactivated() -> void:
	var director := _new_director()
	var player := _fake_player(Vector3.ZERO)
	var engaged := _member(Vector3(5000, 0, 0))
	var fainting := _member(Vector3(5000, 0, 0))
	var respawning := _member(Vector3(5000, 0, 0))
	var ordinary := _member(Vector3(5000, 0, 0))
	var members: Array[Node3D] = [engaged, fainting, respawning, ordinary]

	director.set("_player", player)
	director.set("_engaged_with", engaged)
	director.set("_faint_timers", {fainting: 2.0})
	director.set("_respawn_timers", {respawning: 10.0})
	director.set("_clusters", [_cluster(Vector3(5000, 0, 0), 10.0, members)] as Array[Dictionary])

	director.call("_tick_streaming")

	assert_true(engaged.is_physics_processing(), "a creature mid-fight (and mid-catch, which happens inside a fight) must never be deactivated")
	assert_true(fainting.is_physics_processing(), "a fainting creature's physics_process is notify_fainted()'s own business, not streaming's")
	assert_true(respawning.is_physics_processing(), "a respawning creature's physics_process is _tick_respawn()'s own business, not streaming's")
	assert_false(ordinary.is_physics_processing(), "an ordinary same-cluster member with none of the three guards must still deactivate")

	_cleanup(director, player, members)


# --- it behaves: deactivate/reactivate is a no-op on identity ----------------

func test_deactivate_reactivate_round_trip_is_identical() -> void:
	var director := _new_director()
	var player := _fake_player(Vector3.ZERO)
	var wild := _member(Vector3(9000, 0, 0))
	# A marker that would NOT survive a real despawn/respawn (queue_free + a
	# fresh instantiate()) — this is the thing a naive "streaming despawns
	# the cluster" implementation would break and this call would not catch.
	var identity_marker := RefCounted.new()
	wild.set_meta("identity", identity_marker)
	var original_position := wild.global_position

	director.set("_player", player)
	director.set("_clusters", [_cluster(Vector3(9000, 0, 0), 10.0, [wild])] as Array[Dictionary])

	director.call("_tick_streaming")  # far: deactivates
	assert_false(wild.is_physics_processing())
	assert_true(is_instance_valid(wild), "deactivation must not free the node")
	assert_eq(wild.global_position, original_position, "deactivation must not move the creature")
	assert_eq(wild.get_meta("identity"), identity_marker, "deactivation must not rebuild the creature")

	player.global_position = Vector3(9000, 0, 0)
	director.call("_tick_streaming")  # near: reactivates
	assert_true(wild.is_physics_processing())
	assert_eq(wild.global_position, original_position, "reactivation must not move the creature")
	assert_eq(wild.get_meta("identity"), identity_marker, "reactivation must hand back the SAME node, not a re-rolled one")

	_cleanup(director, player, [wild])


# --- it behaves: a gated-invisible member is left to the gate system ---------

func test_gated_invisible_member_is_left_alone_by_streaming() -> void:
	var director := _new_director()
	var player := _fake_player(Vector3.ZERO)
	var gated := _member(Vector3.ZERO)
	gated.visible = false
	gated.set_physics_process(false)  # what R5.3's gate sync already did to it

	# Cluster starts marked inactive so the player standing right on top of it
	# is a real activate TRANSITION, and `_set_wild_active()`'s gate-skip
	# branch actually runs rather than the call being skipped entirely because
	# nothing changed.
	var cluster := _cluster(Vector3.ZERO, 10.0, [gated])
	cluster["active"] = false

	director.set("_player", player)
	director.set("_wild_gates", {gated: {"time": "night"}})
	director.set("_clusters", [cluster] as Array[Dictionary])

	director.call("_tick_streaming")
	assert_false(gated.is_physics_processing(), "streaming must not turn on a creature the gate has hidden")

	_cleanup(director, player, [gated])
