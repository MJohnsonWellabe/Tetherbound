extends "res://tests/smoke_cloudreach_loaner_witness.gd"

## Chapter card C1 (Cloudreach earned flight route), owner/coordinator #356 13:30:
## "From the M4 save, ordinary play traverses all six regions, trains and
## remounts Fly, reaches the aviary/Veyra without an uncleared-gate bypass or
## lost companion, and enters Stormwood by the earned key."
##
## One uninterrupted run of the F06#3 full-chapter loaner witness from the earned
## `c1_arrival` save, with three additions:
##   1. the F06#2 exhausted-fall (bad landing) attempt on the flight leg
##      (`want_exhausted_fall`, the same helper branch the Fly-training witness runs);
##   2. a per-frame region ledger (map `region_at`, foot vs Fly);
##   3. after the chapter, the save/reload and the post-chapter loaner probe, the
##      existing `tests/helpers/earned_stormward_handoff.gd` walks the actual
##      Stormward stair and presses Interact twice at the real gate (unlock by the
##      earned key, then travel) until Stormwood settles.
##
##   godot --headless --path . --script tests/smoke_cloudreach_b_c1_card.gd -- \
##     --from-save=res://tests/fixtures/earned_saves/c1_arrival --accelerated --live-combat
const C1_DIR := "res://ralph/reports/CLOUDREACH/b/c1-card"
const STORMWARD := preload("res://tests/helpers/earned_stormward_handoff.gd")
const C1_MAP_STATE := preload("res://scripts/world/cloudreach_map_state.gd")

## The handoff helper reads these off its route object.
var failures: Array[String] = []
var c1_world_config: Dictionary = {}
var c1_regions: Dictionary = {}
var c1_region_order: Array[String] = []
var stormwood: Dictionary = {}
var _stormwood_running := false
var _crossed := false


func _run() -> void:
	c1_world_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_world.json"))
	want_exhausted_fall = true
	await super._run()


func _witness_dir(_base: String) -> String:
	return C1_DIR + ("/latest-run" if not from_save.is_empty() else "/fixture-dry-run")


func _party_ids() -> Array[int]:
	var ids: Array[int] = []
	for member: RefCounted in game.party.members():
		ids.append(member.get_instance_id())
	return ids


func _fail(message: String) -> bool:
	# Recorded only when it actually fails the run: the helper withdraws the
	# exhausted-fall / pre-Voss overfly's expected recovery (not a failure).
	var was_failed := failed
	var result: bool = super._fail(message)
	if not was_failed and failed:
		failures.append(message)
	return result


## Diagnostic: when a walk stalls, record every character body near the
## trainer (wild creatures, the companion, NPCs), so a blocker the slide
## contacts never reported is named instead of being called a flake.
func _log(kind: String, details: Dictionary = {}) -> void:
	if kind in ["collision_block", "precision_timeout"] and is_instance_valid(world) and is_instance_valid(player):
		var owner_node: Node = INPUT_OWNER.current(self)
		details["control"] = {"locomotion_enabled": player.locomotion_enabled(), "carried": player.is_carried(),
			"on_floor": player.is_on_floor(), "flying": fly != null and fly.is_flying(),
			"controlled_body": str(runtime.controlled_body().get_path()) if runtime != null else "",
			"dialogue_open": world.get_node("DialoguePanel").is_open(),
			"input_owner": str(owner_node.get_path()) if owner_node != null else "",
			"finale_phase": str(runtime.finale.phase) if runtime != null and runtime.finale != null else "",
			"manager_state": int(manager.state) if manager != null else -1,
			"wanted_dir": str(player.get("_wanted_dir")), "deflect": str(player.get("_deflect")),
			"time_scale": Engine.time_scale}
		var near: Array[Dictionary] = []
		for node: Node in world.find_children("*", "CharacterBody3D", true, false):
			var body := node as CharacterBody3D
			if body == player: continue
			var d := body.global_position.distance_to(player.global_position)
			if d < 8.0:
				near.append({"path": str(body.get_path()), "position": str(body.global_position), "distance_m": snappedf(d, 0.01),
					"layer": body.collision_layer, "velocity": str(body.velocity)})
		details["nearby_bodies"] = near
		details["player_mask"] = player.collision_mask
	super._log(kind, details)


func _unfail() -> void:
	super._unfail()
	if not failures.is_empty():
		failures.remove_at(failures.size() - 1)


func _record_frame() -> void:
	if _crossed or not is_instance_valid(world) or not is_instance_valid(player):
		simulated_seconds += 1.0 / 60.0
		return
	super._record_frame()
	var body: Node3D = runtime.controlled_body() if runtime != null else player
	var region := C1_MAP_STATE.region_at(c1_world_config, body.global_position)
	if region.is_empty():
		return
	var mode := "fly" if fly != null and fly.is_flying() else ("foot" if player.is_on_floor() else "air")
	if not c1_regions.has(region):
		c1_regions[region] = {"foot": 0, "fly": 0, "air": 0}
		c1_region_order.append(region)
	c1_regions[region][mode] += 1


func _finish() -> void:
	if completed_route and not failed and leg.is_empty() and not post_chapter_probe.is_empty() and stormwood.is_empty():
		if not _stormwood_running:
			_stormwood_running = true
			_enter_stormwood()
		return
	if completed_route and stormwood.is_empty() and not failed:
		# The loaner probe runs first (its own _finish); Stormwood follows it.
		super._finish()
		return
	_write_c1()
	super._finish()


func _enter_stormwood() -> void:
	stage = "c1_stormwood_entry"
	var keys_before := _party_keys()
	# After the route's disk reload the five are new objects with the same
	# persisted identity (checked by key); the helper compares instance ids
	# across the crossing itself.
	initial_party_ids = _party_ids()
	var key_before := _has("realm_key_stormwood")
	var unlocked_before := _has("realm_gate_stormwood_unlocked")
	var from_world := world
	var outcome: Dictionary = await STORMWARD.new().run(self, RouteAdapter.new(self))
	_crossed = true
	var arrived: Node = outcome.get("world")
	var arrival_player: Node3D = arrived.get_node_or_null("Player") if is_instance_valid(arrived) else null
	stormwood = {"ok": bool(outcome.get("ok", false)), "failures": outcome.get("failures", []),
		"key_before": key_before, "gate_unlocked_before": unlocked_before, "gate_unlocked_after": _has("realm_gate_stormwood_unlocked"),
		"key_retained": _has("realm_key_stormwood"), "realm": str(game.current_realm),
		"scene": str(arrived.name) if is_instance_valid(arrived) else "", "left_cloudreach": not is_instance_valid(from_world),
		"arrival_position": str(arrival_player.global_position) if arrival_player != null else "",
		"party_keys_equal": _party_keys() == keys_before, "party_size": game.party.members().size(),
		"species": game.party.members().map(func(m: RefCounted) -> String: return str(m.species_id))}
	_log("c1_stormwood_entry", stormwood)
	_require(bool(stormwood.ok) and stormwood.realm == "stormwood" and not bool(stormwood.gate_unlocked_before)
		and bool(stormwood.key_before) and bool(stormwood.key_retained) and bool(stormwood.party_keys_equal)
		and int(stormwood.party_size) == expected_party_size,
		"C1 entered Stormwood through the Stormward gate by the earned key with the same five: " + str(stormwood))
	_finish()


func _write_c1() -> void:
	var expected: Array[String] = []
	var region_rows: Array[Dictionary] = []
	var all_regions := true
	for entry: Dictionary in c1_world_config.get("regions", []):
		var id := str(entry.id)
		var mode := str(entry.get("access", {}).get("mode", "ground"))
		var counts: Dictionary = c1_regions.get(id, {})
		var ok := int(counts.get("fly", 0)) > 0 if mode == "fly_only" else int(counts.get("foot", 0)) >= 60
		all_regions = all_regions and ok
		region_rows.append({"region": id, "access_mode": mode, "frames": counts, "passed": ok})
	var fly_launches := launches.size()
	var recoveries := rows.filter(func(r: Dictionary) -> bool: return str(r.kind).contains("exhausted"))
	var verdict := {"card": "C1", "passed": completed_route and not failed and all_regions and bool(stormwood.get("ok", false)),
		"start_state": _start_state_label(), "combat_mode": "live_input" if live_combat else "mechanics_only_test_lethal",
		"accelerated": accelerated, "stage": stage, "distance_m": distance_m,
		"regions": region_rows, "region_order": c1_region_order, "fly_launches": fly_launches,
		"exhausted_fall": exhausted_fall, "sealed_attempt": sealed_attempt, "trial_escape": trial_escape,
		"pre_voss_overfly_recoveries": overfly_recoveries, "post_chapter_probe": post_chapter_probe,
		"loaner_violations": violations, "stormwood": stormwood,
		"exhausted_rows": recoveries.size(), "static_stall_sidesteps": static_sidesteps,
		"owned_carrier_fly": "OPEN DEBT: no starter path gives a flier (opening.json starters terrapup/ripplet/galewisp; only galecrest has a fly_traversal carry capability, and galewisp has none). The earned five (ripplet, bramblebun, mudsnout x2, veridian) have no carrier, so every flight is Maela's loaner. A wild galecrest is catchable in Meadows band 1; an earned save that caught one would close this.",
		"failure": rows.filter(func(r: Dictionary) -> bool: return r.kind == "FAIL")}
	DirAccess.make_dir_recursive_absolute(_witness_dir(C1_DIR))
	var file := FileAccess.open(_witness_dir(C1_DIR) + "/c1.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(verdict, "  "))
	file.close()
	print("C1 CARD %s regions=%s launches=%d stormwood=%s" % ["PASS" if verdict.passed else "FAIL",
		JSON.stringify(region_rows.map(func(r: Dictionary) -> String: return "%s:%s" % [r.region, "ok" if r.passed else "MISSING"])),
		fly_launches, str(stormwood.get("ok", false))])


## The handoff helper takes its route as a RefCounted; forward to this run.
class RouteAdapter extends RefCounted:
	var host: SceneTree

	func _init(owner: SceneTree) -> void:
		host = owner

	func _get(property: StringName) -> Variant:
		return host.get(property)

	func _party_ids() -> Array[int]:
		return host._party_ids()

	func _record_frame() -> void:
		host._record_frame()

	func _navigate(target: Vector3) -> bool:
		return await host._navigate(target)

	func _walk(target: Vector3, radius: float = 0.75) -> bool:
		return await host._walk(target, radius)

	func _tap(action: String) -> void:
		await host._tap(action)

	func _fail(message: String) -> bool:
		return host._fail(message)
