extends "res://tests/test_case.gd"

## F44#2: a replica applies the host's alpha_cycle ops even after the host's
## other redesign_world fields (bounty_day) moved, changes only alpha_cycles,
## and still refuses a plan whose alpha_cycles baseline it does not hold.
const WORLD := preload("res://autoload/world_state.gd")
const ALPHA := preload("res://scripts/repeatables/alpha_respawns.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const SITE := "hollows_alpha"
const NS := "world_a"


func _world() -> RefCounted:
	var world: RefCounted = WORLD.new()
	world.set("reward_delivery_namespace", NS)
	world.set("redesign_world", STATE.defaults("world"))
	return world


func _op(plan: Dictionary) -> Dictionary:
	return {"op": "alpha_cycle", "scope": "world", "world_namespace": NS, "plan": plan}


func test_replica_follows_host_alpha_ops_after_host_bounty_day_moved() -> void:
	var host := _world()
	var guest := _world()
	guest.redesign_world.portal_unlocks = ["tidewake"] # a replica-only field the ops must never touch
	var born := ALPHA.first_spawn(host.redesign_world, SITE, NS, false, false)
	assert_false(born.is_empty())
	if born.is_empty(): return
	assert_eq(host.apply_delta({"ops": [_op(born)]}), 1, "host applies its own first spawn")
	assert_eq(guest.apply_delta({"ops": [_op(born)]}), 1, "guest mirrors the first spawn")
	# Host mornings move bounty_day; this replica has not received that delta.
	host.redesign_world.bounty_day = 3
	var resolved := ALPHA.resolve(host.redesign_world, SITE, 1, 100, ["character_a"], "defeat")
	assert_true(resolved.get("ok", false), str(resolved))
	if resolved.get("ok") != true: return
	assert_eq(host.apply_delta({"ops": [_op(resolved)]}), 1)
	assert_eq(guest.apply_delta({"ops": [_op(resolved)]}), 1, "guest applies the resolve despite the host's other fields moving")
	var departed := ALPHA.depart(host.redesign_world, SITE, 1, "character_a", "meadows")
	assert_true(departed.get("ok", false), str(departed))
	if departed.get("ok") != true: return
	assert_eq(host.apply_delta({"ops": [_op(departed)]}), 1)
	assert_eq(guest.apply_delta({"ops": [_op(departed)]}), 1)
	var respawned := ALPHA.spawn(host.redesign_world, SITE, NS, 100 + int(ALPHA.config().respawn_days) * int(ALPHA.config().day_seconds), false, false)
	assert_true(respawned.get("ok", false), str(respawned))
	if respawned.get("ok") != true: return
	assert_eq(host.apply_delta({"ops": [_op(respawned)]}), 1)
	assert_eq(guest.apply_delta({"ops": [_op(respawned)]}), 1, "guest mirrors generation 2")
	assert_eq(guest.redesign_world.alpha_cycles, host.redesign_world.alpha_cycles, "replica alpha_cycles equal the host's")
	assert_eq(int(guest.redesign_world.alpha_cycles.sites[SITE].generation), 2)
	assert_eq(int(guest.redesign_world.bounty_day), 0, "the alpha ops left the replica's bounty_day alone")
	assert_eq(guest.redesign_world.portal_unlocks, ["tidewake"], "the alpha ops left the replica's other fields alone")
	assert_true(STATE.validate("world", guest.redesign_world, [], NS).is_empty())
	# Save/reload: the replica's carrier round-trips.
	var reloaded: Dictionary = JSON.parse_string(JSON.stringify(guest.redesign_world))
	assert_eq(ALPHA.retained_spawn(reloaded, SITE), respawned.record.spawn_traits)


func test_replica_refuses_an_alpha_op_whose_baseline_cycle_it_does_not_hold() -> void:
	var host := _world()
	var guest := _world()
	var born := ALPHA.first_spawn(host.redesign_world, SITE, NS, false, false)
	if born.is_empty(): return
	host.apply_delta({"ops": [_op(born)]})
	var resolved := ALPHA.resolve(host.redesign_world, SITE, 1, 100, ["character_a"], "defeat")
	if resolved.get("ok") != true: return
	# The guest missed the first spawn: its cycle baseline differs.
	assert_eq(guest.apply_delta({"ops": [_op(resolved)]}), 0, "a skipped baseline is refused, not overwritten")
	assert_true(guest.redesign_world.alpha_cycles.is_empty() or not guest.redesign_world.alpha_cycles.get("sites", {}).has(SITE))
	# A tampered plan (state not derived from its before) is refused too.
	var forged := resolved.duplicate(true)
	forged.state.alpha_cycles.sites[SITE].generation = 9
	assert_eq(host.apply_delta({"ops": [_op(forged)]}), 0, "a plan whose state is not the canonical result is refused")
	var other_ns := _op(resolved)
	other_ns.world_namespace = "world_b"
	assert_eq(host.apply_delta({"ops": [other_ns]}), 0, "a foreign world namespace is refused")
