extends "res://tests/test_case.gd"

## F04/F10#2 co-op: an ordinary shared wild fight's host runtime
## (`shared_wild_host_fight.gd`, via `stormwood_authoritative_fight.gd`) must
## honour a travelling lunge's own contact outcome exactly as the solo manager
## does. Before this the host added a second impulse after the charge and
## judged the blow by the cone from where the charge stopped, so a co-op player
## who read the lane and stepped off it could still be hit.
const RUNTIME := preload("res://scripts/combat/shared_wild_host_fight.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")


class Body extends Node3D:
	var outcome: Dictionary = {}
	var impulses := 0
	func combat_config() -> Dictionary: return {"power": 10.0, "lunge": 5.5, "range": 2.6, "cone_degrees": 90.0}
	func centre() -> Vector3: return position
	func facing() -> Vector3: return Vector3.FORWARD
	func add_impulse(_direction: Vector3, _strength: float) -> void: impulses += 1
	func take_lunge_outcome() -> Dictionary:
		var out := outcome.duplicate()
		outcome.clear()
		return out


class Link extends Node:
	var picks := 0
	var deliveries: Array = []
	func host_pick_struck_participant(_id: String, _cfg: Dictionary, _o: Vector3, _f: Vector3) -> Dictionary:
		picks += 1
		return {"peer_id": 2, "card": {"defence": 10.0, "creature_type": "water"}}
	func host_deliver_enemy_hit(_id: String, peer_id: int, payload: Dictionary) -> void:
		deliveries.append({"peer_id": peer_id, "payload": payload})


func _runtime(outcome: Dictionary) -> Array:
	var runtime := RUNTIME.new()
	var body := Body.new()
	body.outcome = outcome
	var link := Link.new()
	runtime.set("_wild", body)
	runtime.set("_enemy", CREATURE.from_species("voltarach", {
		"display_name": "Voltarach", "type": "electric", "base_hp": 100.0,
		"base_attack": 20.0, "base_defence": 20.0}))
	runtime.set("_moves", RUNTIME.MOVE_DB.new())
	runtime.authority_link = link
	runtime.set("_encounter_link", runtime)
	runtime.set("_encounter_id", "fight-1")
	runtime.state = RUNTIME.State.ACTIVE
	return [runtime, body, link]


func _free(parts: Array) -> void:
	for node: Node in parts:
		node.free()


func test_a_charge_that_reached_nobody_misses_everybody() -> void:
	var parts := _runtime({"contact": false, "stopped_by": "distance", "travelled": 5.5})
	var misses: Array = []
	var swings: Array = []
	parts[0].attack_missed.connect(func(by_player: bool) -> void: misses.append(by_player))
	parts[0].swung.connect(func() -> void: swings.append(true))
	parts[0].call("_on_enemy_strike")
	assert_eq(parts[2].picks, 0, "no cone pick after a lane that reached nobody")
	assert_eq(parts[2].deliveries.size(), 0, "and no damage to any participant")
	assert_eq(misses, [false], "a miss by the opponent, for everybody")
	assert_eq(swings.size(), 1, "the swing is still presented")
	assert_eq(parts[1].impulses, 0, "the charge already travelled; no second shove")
	_free(parts)


func test_a_charge_that_connected_is_delivered_by_the_host() -> void:
	var parts := _runtime({"contact": true, "stopped_by": "contact", "travelled": 3.0})
	parts[0].call("_on_enemy_strike")
	assert_eq(parts[2].picks, 1, "the host still picks who was struck")
	assert_eq(parts[2].deliveries.size(), 1, "and delivers that blow")
	assert_eq(parts[1].impulses, 0, "the charge already travelled; no second shove")
	_free(parts)


func test_an_ordinary_strike_is_unchanged() -> void:
	var parts := _runtime({})
	parts[0].call("_on_enemy_strike")
	assert_eq(parts[1].impulses, 1, "the ordinary impulse lunge")
	assert_eq(parts[2].picks, 1, "judged by the ordinary cone pick")
	assert_eq(parts[2].deliveries.size(), 1)
	_free(parts)
