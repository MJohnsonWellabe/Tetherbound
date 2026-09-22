extends "res://tests/test_case.gd"

const WILD := preload("res://scripts/creatures/wild_creature.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const TYPE_CHART := preload("res://scripts/combat/type_chart.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")


class Target extends Node3D:
	var radius := 0.6
	func body_radius() -> float: return radius
	func centre() -> Vector3: return position


class CombatBody extends Target:
	var instance: RefCounted = null
	var profile: Dictionary = {}
	func combat_config() -> Dictionary: return profile
	func facing() -> Vector3: return Vector3.BACK
	func add_impulse(_direction: Vector3, _strength: float) -> void: pass
	func play_attack() -> void: pass
	func play_hit() -> void: pass
	func play_faint() -> void: pass


class HostLink extends Node:
	var payload: Dictionary = {}
	func host_pick_struck_participant(_id: String, _cfg: Dictionary, _origin: Vector3,
			_facing: Vector3) -> Dictionary:
		return {"peer_id": 2, "card": {"creature_type": "water", "secondary_type": "" , "defence": 10.0}}
	func local_encounter_peer_id() -> int: return 1
	func host_deliver_enemy_hit(_id: String, _peer: int, row: Dictionary) -> void:
		payload = row.duplicate(true)


func _creature() -> RefCounted:
	var creature: RefCounted = CREATURE.from_species("guardian", {
		"display_name": "Guardian", "type": "ground", "base_hp": 100.0,
		"base_attack": 20.0, "base_defence": 20.0,
	})
	creature.move_quick = "gale_peck"
	creature.move_charged = "earth_fist"
	return creature


func _wild() -> Node:
	var wild := WILD.new()
	var target := Target.new()
	target.position = Vector3(0.0, 0.0, 3.0)
	wild.set("instance", _creature())
	wild.set("_opponent", target)
	wild.set("_combat_cfg", {
		"power": 12.0, "telegraph": 0.85, "recovery": 1.1,
		"range": 2.6, "cone_degrees": 90.0, "lunge": 3.4,
		"preferred_range": 2.1, "body_clearance": 1.0, "damage_scale": 1.6,
		"charged_every": 2, "charged_telegraph": 1.1,
		"charged_recovery": 1.2, "charged_face_lock_fraction": 0.5,
	})
	wild.add_child(target)
	return wild


func _finish_attack(wild: Node) -> void:
	wild.call("_enter", AI.Intent.RECOVER)
	wild.call("_enter", AI.Intent.REPOSITION)
	wild.call("_enter", AI.Intent.CLOSE)


func test_rotated_parent_world_direction_keeps_facing_and_quick_cone() -> void:
	var origin := Vector3(17.0, 0.0, -23.0)
	var identity_basis := Basis.IDENTITY
	var identity_target := origin + Vector3(0.0, 0.0, 4.0)
	var identity_yaw := BODY.yaw_in_parent(identity_target - origin, identity_basis)
	var identity_facing := identity_basis * Basis(Vector3.UP, identity_yaw).z
	assert_true(identity_facing.normalized().dot((identity_target - origin).normalized()) > 0.999,
		"identity-parent control preserves world facing")
	assert_true(MATH.move_connects({"range": 6.0, "cone_degrees": 90.0},
		origin, identity_facing, identity_target), "identity-parent quick cone connects")

	var warrens_basis := Basis(Vector3.UP, deg_to_rad(-45.0))
	var rotated_target := origin + warrens_basis * Vector3(0.0, 0.0, 4.0)
	var rotated_yaw := BODY.yaw_in_parent(rotated_target - origin, warrens_basis)
	var rotated_facing := warrens_basis * Basis(Vector3.UP, rotated_yaw).z
	assert_true(rotated_facing.normalized().dot((rotated_target - origin).normalized()) > 0.999,
		"a translated Warrens-like parent converts world direction to local yaw")
	assert_true(MATH.move_connects({"range": 6.0, "cone_degrees": 90.0},
		origin, rotated_facing, rotated_target),
		"a world-facing quick cone connects under the Warrens-like parent yaw")


func test_opted_in_body_alternates_and_freezes_its_named_attack() -> void:
	var wild := _wild()
	wild.call("_enter", AI.Intent.TELEGRAPH)
	var quick: Dictionary = wild.call("combat_config")
	assert_eq(str(quick.move_id), "gale_peck", "the first cadence attempt freezes the quick id")
	(wild.get("instance") as RefCounted).set("move_quick", "burrow_strike")
	assert_eq(str((wild.call("combat_config") as Dictionary).move_id), "gale_peck",
		"a committed quick cannot reread a changed instance slot")
	(wild.get("instance") as RefCounted).set("move_quick", "gale_peck")
	assert_eq(int(quick.cone_degrees), 90, "quick keeps the enemy geometry")
	_finish_attack(wild)
	wild.call("_enter", AI.Intent.TELEGRAPH)
	var heavy: Dictionary = wild.call("combat_config")
	assert_eq(str(heavy.move_id), "earth_fist")
	assert_almost_eq(float(heavy.telegraph), 1.1)
	assert_almost_eq(float(heavy.recovery), 1.2)
	assert_almost_eq(float(heavy.cone_degrees), 72.0)
	assert_almost_eq(float(heavy.lunge), 6.5)
	assert_almost_eq(float(heavy.power), 19.2, 0.0001,
		"enemy base power is scaled once; the move multiplier is applied by CombatManager")
	var frozen := heavy.duplicate(true)
	wild.set("engaged", true)
	wild.set("combat_override", {"charged_every": 2, "charged_telegraph": 9.0})
	wild.call("refresh_combat_profile")
	assert_eq(wild.call("combat_config"), frozen, "refresh cannot rewrite a committed tell")
	var replacement := Target.new()
	replacement.position = Vector3(4.0, 0.0, 3.0)
	wild.set("_opponent", replacement)
	assert_eq(wild.call("combat_config"), frozen, "retarget cannot rewrite a committed tell")
	wild.set("_beat_left", 0.54)
	assert_true(wild.call("_selected_heading_is_locked"), "the heavy heading locks in its final half")
	wild.set("_poise", 0.0)
	assert_true(wild.call("apply_poise_damage", 1.0), "stagger interrupts the committed heavy")
	assert_false((wild.call("combat_config") as Dictionary).has("move_id"),
		"a cancelled heavy cannot leak into stagger recovery")
	wild.call("_enter", AI.Intent.REPOSITION)
	wild.call("_enter", AI.Intent.CLOSE)
	wild.call("_enter", AI.Intent.TELEGRAPH)
	assert_eq(str((wild.call("combat_config") as Dictionary).move_id), "gale_peck",
		"the interrupted heavy still consumes its cadence attempt")
	wild.free()


func test_host_resolver_uses_selected_move_id_for_type_and_payload() -> void:
	var manager := COMBAT.new()
	var enemy := _creature()
	manager.set("_enemy", enemy)
	manager.set("_moves", MOVE_DB.new())
	manager.set("_encounter_id", "named-attack")
	var link := HostLink.new()
	manager.add_child(link)
	manager.set("_encounter_link", link)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	manager.set("_rng", rng)
	var cfg := {"move_id": "earth_fist", "power": 12.0, "range": 5.0,
		"cone_degrees": 72.0, "lunge": 6.5}
	var moves := MOVE_DB.new()
	var expected_type := TYPE_CHART.multiplier_dual("ground", "water", "")
	var reference_rng := RandomNumberGenerator.new()
	reference_rng.seed = 7
	var expected_damage := MATH.rolled_damage(12.0,
		enemy.effective_attack(PROGRESSION.config()), 10.0, reference_rng.randf(),
		moves.power("earth_fist"), expected_type)
	assert_true(manager.call("_host_resolve_enemy_strike_for_a_participant", cfg,
		Vector3.ZERO, Vector3.FORWARD))
	assert_eq(str(link.payload.move_id), "earth_fist")
	assert_almost_eq(float(link.payload.type_mult), expected_type)
	assert_almost_eq(float(link.payload.damage), expected_damage)
	assert_ne(float(link.payload.type_mult), TYPE_CHART.multiplier_dual("air", "water", ""),
		"this would expose a regression to the quick fallback")
	rng.seed = 7
	var legacy := {"power": 12.0, "range": 5.0, "cone_degrees": 72.0, "lunge": 6.5}
	assert_true(manager.call("_host_resolve_enemy_strike_for_a_participant", legacy,
		Vector3.ZERO, Vector3.FORWARD))
	assert_eq(str(link.payload.move_id), "gale_peck", "missing move_id retains legacy quick damage")
	assert_almost_eq(float(link.payload.type_mult), TYPE_CHART.multiplier_dual("air", "water", ""))
	manager.free()


func test_solo_resolver_uses_the_same_selected_move() -> void:
	var manager := COMBAT.new()
	var enemy := _creature()
	var ally := _creature()
	ally.creature_type = "water"
	ally.hp = 1000.0
	var wild := CombatBody.new()
	wild.instance = enemy
	wild.profile = {"move_id": "earth_fist", "power": 12.0, "range": 5.0,
		"cone_degrees": 360.0, "lunge": 0.0}
	var ally_body := CombatBody.new()
	ally_body.instance = ally
	ally_body.position = Vector3(0.0, 0.0, 2.0)
	var arena := Node3D.new()
	manager.set("_moves", MOVE_DB.new())
	manager.set("_enemy", enemy)
	manager.set("_wild", wild)
	manager.set("_ally_body", ally_body)
	manager.set("_arena", arena)
	manager.set("_party", [ally] as Array[RefCounted])
	manager.set("_active_index", 0)
	manager.set("state", COMBAT.State.ACTIVE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	manager.set("_rng", rng)
	var landed: Array = []
	manager.hit_landed.connect(func(on_enemy: bool, amount: float) -> void:
		if not on_enemy: landed.append(amount))
	var impact: Dictionary = MATH.config().get("impact", {})
	var old_impact := bool(impact.get("enabled", true))
	impact["enabled"] = false
	assert_true(MATH.move_connects(wild.profile, wild.centre(), wild.facing(), ally_body.centre()),
		"the selected heavy fixture must be inside its own cone")
	manager.call("_on_enemy_strike")
	impact["enabled"] = old_impact
	var reference_rng := RandomNumberGenerator.new()
	reference_rng.seed = 11
	var expected := MATH.rolled_damage(12.0, enemy.effective_attack(PROGRESSION.config()),
		ally.effective_defence(PROGRESSION.config()), reference_rng.randf(),
		MOVE_DB.new().power("earth_fist"), TYPE_CHART.multiplier_dual("ground", "water", ""))
	assert_eq(landed.size(), 1)
	if landed.is_empty():
		manager.free()
		arena.free()
		wild.free()
		ally_body.free()
		return
	assert_almost_eq(float(landed[0]), expected, 0.0001,
		"solo uses the same selected move multiplier and type as host delivery")
	manager.free()
	arena.free()
	wild.free()
	ally_body.free()


func test_absent_cadence_keeps_legacy_quick_fallback() -> void:
	var wild := _wild()
	wild.set("_combat_cfg", {"range": 2.6, "cone_degrees": 90.0, "telegraph": 0.8,
		"recovery": 0.75, "preferred_range": 2.1, "body_clearance": 1.0})
	wild.call("_enter", AI.Intent.TELEGRAPH)
	assert_false((wild.call("combat_config") as Dictionary).has("move_id"))
	assert_true((wild.get("_selected_attack") as Dictionary).is_empty(),
		"ordinary bodies do not allocate a selected-attack snapshot")
	wild.free()
