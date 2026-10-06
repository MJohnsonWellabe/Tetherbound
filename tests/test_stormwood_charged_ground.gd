extends "res://tests/test_case.gd"

## Owner RD-14 (STATE item 13): Stormwood's charged ground (the glass sink)
## deals light contact damage to the trainer only, never lethal on the ordinary
## route; Rootiron and Stormglass trainer gear reduce it. Pure host/receiver
## rules over the real surge rules and gear config.

const CHARGED := preload("res://scripts/world/stormwood_charged_ground.gd")
const RULES := preload("res://scripts/world/stormwood_surge_rules.gd")
const SINK := Vector3(1100.0, -20.0, 2700.0) # Inside the authored annulus, below the island.
const ISLAND := Vector3(700.0, 80.0, 2700.0)


func _cfg() -> Dictionary:
	return RULES.new().config.charged_ground


func test_the_host_hits_only_grounded_trainers_on_charged_ground() -> void:
	var rules := RULES.new()
	assert_true(rules.in_glass_sink(SINK), "the fixture point is in the authored glass sink")
	var hits := CHARGED.host_hits(rules, {
		2: {"position": SINK, "ground_y": SINK.y, "in_fight": false},
		3: {"position": ISLAND, "ground_y": ISLAND.y, "in_fight": false},
		4: {"position": SINK + Vector3(5, 0, 0), "ground_y": SINK.y, "in_fight": true},
		5: {"position": SINK + Vector3(0, 6, 0), "ground_y": SINK.y, "in_fight": false}}, _cfg())
	assert_eq(hits.keys(), [2], "on the ground in the sink: hit; island, in a fight, or airborne: not")
	assert_eq(float(hits[2].damage), float(_cfg().damage_per_tick), "a light, config-driven hit")


func test_gear_reduces_it_and_it_never_takes_health_below_the_floor() -> void:
	var cfg := _cfg()
	var damage := float(cfg.damage_per_tick)
	assert_eq(CHARGED.health_after(100.0, 100.0, damage, 0.0, cfg), 100.0 - damage, "bare: the full light hit")
	assert_almost_eq(CHARGED.health_after(100.0, 100.0, damage, 0.4, cfg), 100.0 - damage * 0.6, 0.0001, "gear reduces it")
	var health := 100.0
	for tick in 500:
		health = CHARGED.health_after(health, 100.0, damage, 0.0, cfg)
	var floor_hp := 100.0 * float(cfg.health_floor_fraction)
	assert_almost_eq(health, floor_hp, 0.0001, "standing in it forever stops at the floor: never lethal")
	assert_eq(CHARGED.health_after(10.0, 100.0, damage, 0.0, cfg), 10.0, "below the floor (from elsewhere) it does nothing")
