extends "res://tests/test_case.gd"

## F04: a named CHARGER's lunge travels, shows its lane, and hits only on real
## contact; every other opponent strikes exactly as before.
##
## The unit runner executes from SceneTree._init, with no tree and no physics
## steps, so the physics half -- a real body running down its heading on a real
## floor, stopping at contact, at its full length and at a wall; the lane, the
## heading lock, stagger and disengage; and an ordinary wild's positions pinned
## against the pre-change tree -- is `tests/smoke_charger_lunge.gd`, run here as
## a child process so CI's unit job runs it. This file also holds the rules that
## need no tree: the opt-in, the contact test, the manager's hit delivery and
## the data that opts bodies in.

const WILD := preload("res://scripts/creatures/wild_creature.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

const CHARGER := {
	"preferred_range": 4.5, "lunge": 7.0, "telegraph": 0.8, "recovery": 0.9,
	"attack_cooldown": 1.6, "power": 10.4, "lunge_travels": true,
}


class Target extends Node3D:
	var radius := 0.6
	func body_radius() -> float: return radius
	func centre() -> Vector3: return position


## A stand-in opponent for the manager, with or without a lunge report.
class StrikeBody extends Target:
	var instance: RefCounted = null
	var profile: Dictionary = {}
	var outcome: Dictionary = {}
	var reports_lunge := false
	var impulses := 0
	func combat_config() -> Dictionary: return profile
	func facing() -> Vector3: return Vector3.BACK
	func add_impulse(_direction: Vector3, _strength: float) -> void: impulses += 1
	func play_attack() -> void: pass
	func play_hit() -> void: pass
	func play_faint() -> void: pass


class LungeReportingBody extends StrikeBody:
	func take_lunge_outcome() -> Dictionary:
		var out := outcome.duplicate()
		outcome.clear()
		return out


class HostLink extends Node:
	var delivered := 0
	func is_encounter_host() -> bool: return true
	func host_pick_struck_participant(_id: String, _cfg: Dictionary, _origin: Vector3,
			_facing: Vector3) -> Dictionary:
		return {"peer_id": 2, "card": {"creature_type": "water", "secondary_type": "", "defence": 10.0}}
	func local_encounter_peer_id() -> int: return 1
	func host_deliver_enemy_hit(_id: String, _peer: int, _row: Dictionary) -> void:
		delivered += 1


func _creature() -> RefCounted:
	var creature: RefCounted = CREATURE.from_species("tuskroot", {
		"display_name": "Tuskroot", "type": "ground", "base_hp": 100.0,
		"base_attack": 20.0, "base_defence": 20.0,
	})
	creature.move_quick = "root_nibble"
	return creature


func test_swept_contact_is_a_path_test_not_a_distance_roll() -> void:
	var reach := 2.0
	assert_true(WILD.swept_contact(Vector2(0, 0), Vector2(0, 7), Vector2(1.5, 4.0), reach),
		"a target beside the middle of the path is reached")
	assert_false(WILD.swept_contact(Vector2(0, 0), Vector2(0, 7), Vector2(2.5, 4.0), reach),
		"a target that stepped a body-width off the lane is not")
	assert_false(WILD.swept_contact(Vector2(0, 0), Vector2(0, 7), Vector2(0.0, 9.5), reach),
		"a target beyond the end of the lane is not reached")
	assert_true(WILD.swept_contact(Vector2(0, 0), Vector2(0, 7), Vector2(0.0, 8.9), reach),
		"the body's front at the lane's end still reaches")
	assert_false(WILD.swept_contact(Vector2(0, 0), Vector2(0, 7), Vector2(0.0, -2.5), reach),
		"nothing behind the start is reached")
	assert_true(WILD.swept_contact(Vector2(3, 3), Vector2(3, 3), Vector2(4, 3), reach),
		"a zero-length step still tests the point it is at")


func test_ordinary_wild_strikes_at_the_end_of_its_wind_up_as_before() -> void:
	var wild := WILD.new()
	wild.set("instance", _creature())
	wild.set("_combat_cfg", MATH.config().get("enemy", {}))
	var target := Target.new()
	target.position = Vector3(0.0, 0.0, 3.0)
	wild.add_child(target)
	wild.set("engaged", true)
	wild.set("_opponent", target)
	var strikes: Array = []
	wild.connect("strike_ready", func() -> void: strikes.append(true))
	assert_false(bool(wild.call("lunge_travels")), "the shared enemy block does not opt in")
	wild.call("_enter", AI.Intent.TELEGRAPH)
	assert_eq(wild.find_child("LungeLane", true, false), null, "no lane for an ordinary wind-up")
	wild.call("_enter", AI.Intent.RECOVER)
	assert_eq(strikes.size(), 1, "the strike is announced the instant the wind-up ends")
	assert_false(bool(wild.call("is_lunging")))
	assert_false(bool(wild.call("combat_burst_active")), "no travel is started")
	assert_true((wild.call("take_lunge_outcome") as Dictionary).is_empty(),
		"no lunge report, so the manager keeps its cone test")
	assert_true(bool(wild.call("is_rooted")), "recovery is still the open window")
	wild.free()


func test_trainer_overlay_and_other_profiles_cannot_opt_in_by_accident() -> void:
	var enemy: Dictionary = MATH.config().get("enemy", {})
	var trainer: Dictionary = MATH.config().get("enemy_trainer", {})
	assert_false(enemy.has("lunge_travels"), "wild baseline stays instantaneous")
	assert_false(trainer.has("lunge_travels"), "the trainer baseline stays instantaneous")
	var wild := WILD.new()
	wild.trainer_owned = true
	wild.combat_override = {"lunge": 5.5, "telegraph": 0.4}
	assert_false(bool((wild.call("_enemy_config_for_this_body") as Dictionary).get("lunge_travels", false)),
		"a DIVER-shaped override does not travel")
	wild.combat_override = CHARGER.duplicate()
	assert_true(bool((wild.call("_enemy_config_for_this_body") as Dictionary).get("lunge_travels", false)),
		"the opt-in key survives the override whitelist")
	wild.free()


func _manager_with(wild: StrikeBody) -> Dictionary:
	var manager := COMBAT.new()
	var enemy := _creature()
	var ally := _creature()
	ally.hp = 100000.0
	ally.max_hp = 100000.0
	wild.instance = enemy
	var ally_body := StrikeBody.new()
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
	var log := {"hits": 0, "misses": 0}
	manager.hit_landed.connect(func(on_enemy: bool, _amount: float) -> void:
		if not on_enemy: log.hits += 1)
	manager.attack_missed.connect(func(by_player: bool) -> void:
		if not by_player: log.misses += 1)
	return {"manager": manager, "ally_body": ally_body, "arena": arena, "log": log}


func _free_manager(fixture: Dictionary, wild: Node) -> void:
	(fixture.manager as Node).free()
	(fixture.arena as Node).free()
	(fixture.ally_body as Node).free()
	wild.free()


func _strike(fixture: Dictionary) -> void:
	var impact: Dictionary = MATH.config().get("impact", {})
	var old := bool(impact.get("enabled", true))
	impact["enabled"] = false
	(fixture.manager as Node).call("_on_enemy_strike")
	impact["enabled"] = old


func test_manager_lands_a_charge_only_on_reported_contact() -> void:
	# A cone that would hit anything: the report, not the cone, decides.
	var generous := {"power": 10.4, "range": 50.0, "cone_degrees": 360.0, "lunge": 7.0}
	var wild := LungeReportingBody.new()
	wild.profile = generous
	wild.outcome = {"contact": false, "stopped_by": "distance", "travelled": 7.0}
	var fixture := _manager_with(wild)
	_strike(fixture)
	assert_eq(int(fixture.log.hits), 0, "a sidestepped charge does not hit, whatever the cone says")
	assert_eq(int(fixture.log.misses), 1, "it is reported as a miss")
	assert_eq(wild.impulses, 0, "the body already travelled; no second shove")

	# A cone that would miss everything: the report of contact lands the blow.
	wild.profile = {"power": 10.4, "range": 0.0, "cone_degrees": 1.0, "lunge": 7.0}
	wild.outcome = {"contact": true, "stopped_by": "contact", "travelled": 4.2}
	_strike(fixture)
	assert_eq(int(fixture.log.hits), 1, "a charge that reached the target hits")
	_free_manager(fixture, wild)


func test_manager_keeps_the_cone_test_for_every_other_opponent() -> void:
	var wild := StrikeBody.new()
	wild.profile = {"power": 8.0, "range": 50.0, "cone_degrees": 360.0, "lunge": 3.4}
	var fixture := _manager_with(wild)
	_strike(fixture)
	assert_eq(int(fixture.log.hits), 1, "an ordinary strike inside its cone still hits")
	assert_eq(wild.impulses, 1, "and still carries its lunge impulse")
	wild.profile = {"power": 8.0, "range": 0.0, "cone_degrees": 1.0, "lunge": 3.4}
	_strike(fixture)
	assert_eq(int(fixture.log.misses), 1, "an ordinary strike outside its cone still misses")
	_free_manager(fixture, wild)

	# A reporting body with nothing to report (an ordinary wild_creature) too.
	var ordinary := LungeReportingBody.new()
	ordinary.profile = {"power": 8.0, "range": 50.0, "cone_degrees": 360.0, "lunge": 3.4}
	var second := _manager_with(ordinary)
	_strike(second)
	assert_eq(int(second.log.hits), 1, "an empty report falls back to the cone test")
	assert_eq(ordinary.impulses, 1)
	_free_manager(second, ordinary)


func test_host_reports_a_charge_that_reached_nobody_as_a_miss() -> void:
	var wild := LungeReportingBody.new()
	wild.profile = {"power": 10.4, "range": 50.0, "cone_degrees": 360.0, "lunge": 7.0}
	wild.outcome = {"contact": false, "stopped_by": "obstacle", "travelled": 2.0}
	var fixture := _manager_with(wild)
	var link := HostLink.new()
	(fixture.manager as Node).add_child(link)
	(fixture.manager as Node).set("_encounter_link", link)
	_strike(fixture)
	assert_eq(link.delivered, 0, "no participant is picked for a charge that touched nobody")
	assert_eq(int(fixture.log.misses), 1)
	wild.outcome = {"contact": true, "stopped_by": "contact", "travelled": 4.0}
	_strike(fixture)
	assert_eq(link.delivered, 1, "on contact the host still delivers to the struck participant")
	_free_manager(fixture, wild)


## Only the named Meadows CHARGERs travel. The data is scanned rather than
## pinned by path so a new band file cannot quietly opt a body in.
func test_only_named_charger_profiles_opt_in() -> void:
	var opted := 0
	var dir := DirAccess.open("res://data/config/bands")
	assert_ne(dir, null)
	if dir == null:
		return
	for band: String in dir.get_directories():
		var path := "res://data/config/bands/%s/trainers.json" % band
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			continue
		for trainer: Variant in (parsed as Dictionary).get("trainers", []):
			for member: Variant in (trainer as Dictionary).get("team", []):
				if not member is Dictionary:
					continue
				var combat: Dictionary = (member as Dictionary).get("combat", {}) as Dictionary
				if not bool(combat.get("lunge_travels", false)):
					continue
				opted += 1
				assert_almost_eq(float(combat.get("preferred_range", 0.0)), 4.5, 0.0001,
					"'%s' opts a non-CHARGER into lunge_travels" % (trainer as Dictionary).get("id", "?"))
				assert_almost_eq(float(combat.get("lunge", 0.0)), 7.0, 0.0001)
	assert_eq(opted, 3, "Vance's and Halder's Tuskroot and the Warden's Meadowhart, no more")


func test_physics_smoke_passes_in_an_initialized_tree() -> void:
	var log_path := ProjectSettings.globalize_path("user://charger-lunge-smoke-%s.log" % OS.get_process_id())
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script",
		ProjectSettings.globalize_path("res://tests/smoke_charger_lunge.gd"),
		"--log-file", log_path], output, true)
	var lines := PackedStringArray()
	if FileAccess.file_exists(log_path):
		lines = FileAccess.get_file_as_string(log_path).split("\n")
	for chunk: String in output:
		lines.append_array(chunk.split("\n"))
	var errors: Array[String] = []
	var summary := ""
	for line: String in lines:
		var clean := line.strip_edges()
		if clean.begins_with("SCRIPT ERROR:") or clean.begins_with("FAIL"):
			errors.append(clean)
			print("[charger-lunge-smoke] " + clean)
		if clean.begins_with("smoke_charger_lunge:"):
			summary = clean
	assert_eq(errors, [], "the physics smoke reports no failures or script errors")
	assert_eq(code, 0, "the physics smoke exits cleanly (%s)" % summary)
	assert_true(summary.ends_with(" 0 failed") and not summary.begins_with("smoke_charger_lunge: 0 checks"),
		"the physics smoke ran its checks: '%s'" % summary)
