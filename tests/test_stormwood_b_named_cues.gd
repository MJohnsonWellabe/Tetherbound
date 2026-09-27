extends "res://tests/test_case.gd"

## F10#2 granted combat keys (coordinator grant on #345), both opt-in:
##   `route_cue_seconds` -- a visible route line for N seconds BEFORE the
##     ordinary tell (BOSSES §7 Capacitor Alpha: "1.1 s visible route-line cue
##     + .8 s strike tell"); the tell and its announcement follow unchanged.
##   `guard_stance` -- the Crown Guardian's "stationary frontal guard stance"
##     LOOK: a frontal cone drawn for the tell with the body's own range and
##     cone. Presentation only: no block, no damage change (COMBAT: no shields).
## Unset, neither key changes anything.

const WILD := preload("res://scripts/creatures/wild_creature.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")


class Target extends Node3D:
	func body_radius() -> float: return 0.6
	func centre() -> Vector3: return position


func _creature() -> RefCounted:
	var creature: RefCounted = CREATURE.from_species("voltarach", {
		"display_name": "Voltarach", "type": "electric", "base_hp": 100.0,
		"base_attack": 20.0, "base_defence": 20.0,
	})
	creature.move_quick = "spark_nip"
	return creature


## A body mid-fight with `override` merged into the shared enemy block, the way
## `_enemy_config_for_this_body()` merges an authored `combat` row.
func _wild(override: Dictionary) -> Node3D:
	var wild: Node3D = WILD.new()
	wild.set("instance", _creature())
	wild.combat_override = override
	wild.set("_combat_cfg", wild.call("_enemy_config_for_this_body"))
	var target := Target.new()
	target.position = Vector3(0.0, 0.0, 3.0)
	wild.add_child(target)
	wild.set("engaged", true)
	wild.set("_opponent", target)
	return wild


func _tells(wild: Node3D) -> Array:
	var tells: Array = []
	wild.connect("telegraph_started", func(seconds: float) -> void: tells.append(seconds))
	return tells


func test_both_keys_are_whitelisted_overrides() -> void:
	assert_true(WILD._COMBAT_OVERRIDE_KEYS.has("route_cue_seconds"))
	assert_true(WILD._COMBAT_OVERRIDE_KEYS.has("guard_stance"))
	assert_false((MATH.config().get("enemy", {}) as Dictionary).has("route_cue_seconds"),
		"the shared enemy block never opts in")
	assert_false((MATH.config().get("enemy", {}) as Dictionary).has("guard_stance"))


func test_unset_keys_leave_the_tell_exactly_as_before() -> void:
	var wild := _wild({})
	var tells := _tells(wild)
	var telegraph := float(MATH.config().get("enemy", {}).get("telegraph", 0.55))
	wild.call("_enter", AI.Intent.TELEGRAPH)
	assert_eq(tells.size(), 1, "the tell is announced the instant it starts")
	assert_almost_eq(float(tells[0]), telegraph, 0.0001, "for exactly the profile's tell")
	assert_almost_eq(float(wild.get("_beat_left")), telegraph, 0.0001, "no cue time is added")
	assert_almost_eq(float(wild.call("route_cue_left")), 0.0, 0.0001)
	assert_eq(wild.find_child("GuardCone", true, false), null, "no guard cone")
	assert_eq(wild.find_child("LungeLane", true, false), null, "no route line")
	assert_true(wild.get("_combat_cfg") == MATH.config().get("enemy", {}),
		"an unset override keeps the very same shared enemy block")
	wild.free()


func test_route_cue_shows_the_route_first_then_the_ordinary_tell() -> void:
	var wild := _wild({"route_cue_seconds": 1.1, "telegraph": 0.8, "lunge": 5.5, "lunge_travels": true})
	var tells := _tells(wild)
	wild.call("_enter", AI.Intent.TELEGRAPH)
	assert_eq(tells.size(), 0, "the ring and anticipation wait for the route cue")
	assert_almost_eq(float(wild.get("_beat_left")), 1.9, 0.0001, "1.1 s cue + 0.8 s tell")
	assert_almost_eq(float(wild.call("route_cue_left")), 1.1, 0.0001)
	assert_false(bool(wild.call("is_winding_up")), "the cue comes before the wind-up (no interrupt or HUD warning yet)")
	assert_false(bool(wild.call("is_rooted")), "and the HUD never calls the body open while its route is drawn")
	assert_false(bool(wild.call("_lunge_heading_is_locked")), "the route still tracks during the cue")
	# The lock clock measures the 0.8 s tell only: still unlocked just before the
	# tell starts, locked inside it (lane lock at half the tell).
	wild.set("_beat_left", 0.9)
	assert_false(bool(wild.call("_lunge_heading_is_locked")), "unlocked 0.1 s before the tell")
	# The tick counts the beat and the cue down together.
	wild.set("_beat_left", 1.3)
	wild.call("_advance_route_cue", 0.6)
	assert_eq(tells.size(), 0, "0.6 s in, still the route cue")
	wild.set("_beat_left", 0.8)
	wild.call("_advance_route_cue", 0.5)
	assert_eq(tells.size(), 1, "the ordinary tell starts when the cue ends")
	assert_almost_eq(float(tells[0]), 0.8, 0.0001, "and it is the authored 0.8 s tell")
	assert_true(bool(wild.call("is_winding_up")), "the wind-up is the tell proper")
	wild.set("_beat_left", 0.3)
	assert_true(bool(wild.call("_lunge_heading_is_locked")), "locked late in the tell")
	wild.call("_advance_route_cue", 0.5)
	assert_eq(tells.size(), 1, "announced once")
	wild.call("_enter", AI.Intent.RECOVER)
	assert_almost_eq(float(wild.call("route_cue_left")), 0.0, 0.0001)
	wild.free()


func test_route_cue_ends_with_its_tell() -> void:
	var wild := _wild({"route_cue_seconds": 1.1})
	var strikes: Array = []
	wild.connect("strike_ready", func() -> void: strikes.append(true))
	wild.call("_enter", AI.Intent.TELEGRAPH)
	wild.call("_enter", AI.Intent.REPOSITION)
	assert_almost_eq(float(wild.call("route_cue_left")), 0.0, 0.0001, "leaving the tell drops the cue")
	assert_eq(strikes.size(), 1, "a strike that does not travel still resolves as before")
	wild.free()


func test_guard_stance_draws_the_hit_shape_and_changes_no_numbers() -> void:
	var plain := _wild({"telegraph": 0.85, "cone_degrees": 90.0, "power": 12.0})
	var guarded := _wild({"telegraph": 0.85, "cone_degrees": 90.0, "power": 12.0, "guard_stance": true})
	var tells := _tells(guarded)
	guarded.call("_enter", AI.Intent.TELEGRAPH)
	assert_eq(tells.size(), 1, "the tell is announced as usual")
	var cone := guarded.find_child("GuardCone", true, false) as MeshInstance3D
	assert_true(cone != null, "a frontal guard cone is drawn for the tell")
	var cfg: Dictionary = guarded.call("combat_config")
	assert_almost_eq(float(cone.get_meta("reach")), float(cfg.get("range", 2.6)), 0.0001,
		"as long as the swing's own reach")
	assert_almost_eq(float(cone.get_meta("cone_degrees")), 90.0, 0.0001, "and as wide as its own cone")
	for key: String in ["power", "range", "cone_degrees", "telegraph", "recovery", "attack_cooldown"]:
		assert_eq(guarded.call("combat_config").get(key), plain.call("combat_config").get(key),
			"guard_stance changes no fight number (%s)" % key)
	assert_false(guarded.has_method("block") or guarded.has_method("is_blocking"), "no block verb exists")
	guarded.call("_enter", AI.Intent.RECOVER)
	assert_eq(guarded.get("_guard_cone"), null, "the cone ends with the tell")
	plain.free()
	guarded.free()


func test_stormwood_data_opts_the_two_fights_in() -> void:
	var named := {}
	for row: Dictionary in CATALOGUE.encounter_catalogue().get("named_encounters", []):
		named[str(row.id)] = CATALOGUE.named_combat(row)
	assert_almost_eq(float(named.capacitor_alpha.get("route_cue_seconds", 0.0)), 1.1, 0.0001,
		"Capacitor Alpha shows its route for BOSSES' 1.1 s")
	assert_true(bool(named.capacitor_alpha.get("lunge_travels", false)), "and really dives down it")
	assert_almost_eq(float(named.capacitor_alpha.telegraph), 0.8, 0.0001, "before BOSSES' 0.8 s tell")
	assert_true(bool(named.crown_guardian.get("guard_stance", false)), "the Crown Guardian plants its guard")
	for id: String in named:
		if id != "capacitor_alpha":
			assert_false(named[id].has("route_cue_seconds"), "%s has no route cue" % id)
		if id != "crown_guardian":
			assert_false(named[id].has("guard_stance"), "%s has no guard stance" % id)


func test_every_exit_from_a_tell_drops_the_cue_and_the_cone() -> void:
	var override := {"route_cue_seconds": 1.1, "guard_stance": true, "telegraph": 0.8}
	# Stagger in the tell proper (a route cue cannot be staggered, coordinator
	# interim ruling 5860078626 option (a)): no cone, no cue.
	var staggered := _wild(override)
	staggered.call("_enter", AI.Intent.TELEGRAPH)
	assert_true(staggered.find_child("GuardCone", true, false) != null, "precondition: cone drawn")
	staggered.call("_advance_route_cue", 2.0)
	assert_true(bool(staggered.call("apply_poise_damage", 999.0, true)), "the tell proper can be staggered")
	assert_eq(staggered.get("_guard_cone"), null, "a stagger drops the guard cone")
	assert_almost_eq(float(staggered.call("route_cue_left")), 0.0, 0.0001, "and the route cue")
	staggered.free()
	# Disengage (fight over, party wipe) mid-tell.
	var released := _wild(override)
	released.call("_enter", AI.Intent.TELEGRAPH)
	released.call("set_engaged", false)
	assert_eq(released.get("_guard_cone"), null, "leaving the fight drops the guard cone")
	assert_almost_eq(float(released.call("route_cue_left")), 0.0, 0.0001)
	released.free()
	# Faint mid-tell.
	var fainted := _wild(override)
	fainted.call("_enter", AI.Intent.TELEGRAPH)
	fainted.call("notify_fainted")
	assert_eq(fainted.get("_guard_cone"), null, "a faint drops the guard cone")
	fainted.free()


## F10#2 C2 (coordinator interim ruling 5860078626, option (a)): a masher must
## not stagger the body out of its route cue before a reader can use it. Hits
## during the cue drain no poise; the tell proper staggers as before.
func test_a_route_cue_cannot_be_staggered() -> void:
	var wild := _wild({"route_cue_seconds": 1.1, "telegraph": 0.8, "lunge": 5.5, "lunge_travels": true})
	var tells := _tells(wild)
	wild.call("_reset_poise")
	wild.call("_enter", AI.Intent.TELEGRAPH)
	assert_false(bool(wild.call("apply_poise_damage", 999.0)), "a heavy hit mid-cue does not stagger")
	assert_false(bool(wild.call("apply_poise_damage", 999.0, true)), "nor does a forced stagger")
	assert_false(bool(wild.call("is_staggered")))
	assert_almost_eq(float(wild.get("_poise")), float(wild.call("_poise_max")), 0.0001, "hits during the cue drain no poise")
	assert_almost_eq(float(wild.call("route_cue_left")), 1.1, 0.0001, "the cue keeps running")
	wild.call("_advance_route_cue", 1.2)
	assert_eq(tells.size(), 1, "the tell proper is announced after the cue")
	assert_true(bool(wild.call("apply_poise_damage", 999.0)), "a breaking hit in the tell proper still staggers")
	wild.free()


func test_bodies_without_a_route_cue_stagger_as_before() -> void:
	var wild := _wild({"telegraph": 0.8})
	wild.call("_reset_poise")
	wild.call("_enter", AI.Intent.TELEGRAPH)
	assert_true(bool(wild.call("apply_poise_damage", 999.0)), "no cue: an ordinary tell still staggers")
	wild.free()
