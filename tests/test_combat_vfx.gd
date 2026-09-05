extends "res://tests/test_case.gd"

## W09-VFX (CL-A2). The combat VFX layer, driven by REAL damage events on a
## bare CombatManager -- the same reflection style tests/test_combat_progression.gd
## uses -- with stand-in bodies that answer exactly the calls the manager makes
## of a creature body during a strike.
##
## What "real" means here: nothing below calls `combat_vfx.hit()` to check
## that it spawns something. The first two tests drive
## `combat_manager.gd::_on_enemy_strike()` -- the foe's swing resolving against
## the piloted creature, hit cone, rolled damage, `take_damage`, faint handling
## and all -- and assert the spark, the body flash and the KO puff came out of
## THAT path, at the arena the manager parented them under. Seen red (2026-09-04)
## with the `VFX.hit` line removed from `_flash_at()`: "no HitSpark under the
## arena after a landed blow". The direct-call tests further down cover the
## sizing and tinting rules, and the watcher tests cover level-ups against a
## real `autoload/party.gd` and a real `gain_xp()`.
##
## The unit runner never enters a SceneTree or processes a frame
## (`tests/test_party_seam.gd`'s header), so every effect is walked through its
## life by hand through the same `advance()` its `_physics_process` calls, and
## "freed" is asserted as `is_queued_for_deletion()` -- the delete queue only
## flushes on a frame this runner never runs. The fixture is freed whole at the
## end of each test so nothing leaks into the next.

const COMBAT_MANAGER := preload("res://scripts/combat/combat_manager.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const PARTY := preload("res://autoload/party.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const VFX := preload("res://scripts/vfx/combat_vfx.gd")
const BURST := preload("res://scripts/vfx/vfx_burst.gd")
const GLOW := preload("res://scripts/vfx/body_glow.gd")
const FLOURISH := preload("res://scripts/vfx/level_up_flourish.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}

const TICK := 1.0 / 60.0


## Answers every call `_on_enemy_strike()` / `_flash_at()` make of a body, and
## carries a drawable mesh so the body flash has something to overlay.
class StandInBody extends Node3D:
	var instance: RefCounted = null
	var height: float = 1.0
	var radius: float = 0.5
	var hits: int = 0
	var faints: int = 0
	var _pivot: Node3D = null
	var mesh_node: MeshInstance3D = null

	func _init() -> void:
		_pivot = Node3D.new()
		_pivot.name = "Model"
		add_child(_pivot)
		mesh_node = MeshInstance3D.new()
		mesh_node.mesh = BoxMesh.new()
		_pivot.add_child(mesh_node)

	func model_pivot() -> Node3D:
		return _pivot

	func centre() -> Vector3:
		return position + Vector3.UP * height * 0.5

	func facing() -> Vector3:
		return Vector3(0.0, 0.0, 1.0)

	func body_radius() -> float:
		return radius

	func body_height() -> float:
		return height

	func combat_config() -> Dictionary:
		return {"power": 8.0, "range": 10.0, "cone_degrees": 360.0, "lunge": 0.0}

	func add_impulse(_direction: Vector3, _strength: float) -> void:
		pass

	func face_towards(_spot: Vector3) -> void:
		pass

	func play_attack() -> void:
		pass

	func play_hit() -> void:
		hits += 1

	func play_faint() -> void:
		faints += 1

	func set_engaged(_value: bool, _target: Node = null) -> void:
		pass


## Stands where EncounterDirector stands for the watcher: which creature is
## deployed, and in which body.
class StandInDirector extends Node:
	var ally: RefCounted = null
	var body: Node3D = null

	func ally_instance() -> RefCounted:
		return ally

	func ally_body() -> Node3D:
		return body


var _root: Node3D = null
var _arena: Node3D = null
var _wild: StandInBody = null
var _ally: StandInBody = null
var _impact_was_enabled: bool = true


func before_each() -> void:
	VFX.set_enabled_override(null)
	# combat.json's own impact_flash.gd ring is not under test and, spawned in
	# a detached fixture, would only print a global-transform error. Off for
	# the test, restored after, through the same cached dictionary the manager
	# reads.
	var impact: Dictionary = MATH.config().get("impact", {})
	_impact_was_enabled = bool(impact.get("enabled", true))
	impact["enabled"] = false
	_root = Node3D.new()
	_arena = Node3D.new()
	_arena.name = "CombatArena"
	_root.add_child(_arena)
	_wild = StandInBody.new()
	_wild.name = "Wild"
	_wild.position = Vector3.ZERO
	_root.add_child(_wild)
	_ally = StandInBody.new()
	_ally.name = "Ally"
	_ally.position = Vector3(0.0, 0.0, 1.5)
	_root.add_child(_ally)


func after_each() -> void:
	VFX.set_enabled_override(null)
	var impact: Dictionary = MATH.config().get("impact", {})
	impact["enabled"] = _impact_was_enabled
	if _root != null:
		_root.free()
		_root = null
	_arena = null
	_wild = null
	_ally = null


func _creature(level: int, nickname: String) -> RefCounted:
	var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	creature.set_level(level, PROGRESSION.config())
	creature.nickname = nickname
	return creature


## A manager mid-fight: the foe (`_wild`) squared up against the piloted
## creature (`_ally_body`), party seated, arena open. Nothing here needs
## `_ready()` except the move table, which is built by hand.
func _manager_in_a_fight(ally_hp: float) -> Node:
	var mgr: Node = COMBAT_MANAGER.new()
	var foe := _creature(5, "")
	var mine := _creature(5, "Champ")
	mine.hp = ally_hp
	_wild.instance = foe
	_ally.instance = mine
	mgr.set("_moves", MOVE_DB.new())
	mgr.set("_wild", _wild)
	mgr.set("_ally_body", _ally)
	mgr.set("_enemy", foe)
	mgr.set("_arena", _arena)
	mgr.set("_party", [mine] as Array[RefCounted])
	mgr.set("_active_index", 0)
	mgr.set("state", COMBAT_MANAGER.State.ACTIVE)
	return mgr


func _children_named(parent: Node, name: String) -> Array:
	var out: Array = []
	for child in parent.get_children():
		if child.name == name:
			out.append(child)
	return out


func _glows_on(body: Node) -> Array:
	var out: Array = []
	for child in body.get_children():
		if child.get_script() == GLOW:
			out.append(child)
	return out


# --- the damage path ---------------------------------------------------------

func test_a_landed_blow_spawns_a_spark_and_a_body_flash_that_live_and_free() -> void:
	var mgr := _manager_in_a_fight(200.0)
	var landed: Array = []
	mgr.connect("hit_landed", func(on_enemy: bool, amount: float) -> void: landed.append([on_enemy, amount]))

	mgr.call("_on_enemy_strike")
	mgr.free()

	assert_eq(landed.size(), 1, "the foe's swing must have connected for this test to mean anything")
	assert_eq(_ally.hits, 1, "the struck body played its hit reaction")

	var sparks := _children_named(_arena, VFX.NAME_HIT_SPARK)
	assert_eq(sparks.size(), 1, "no HitSpark under the arena after a landed blow")
	assert_eq(_children_named(_arena, VFX.NAME_KO_PUFF).size(), 0, "a blow that left the bar standing must not puff")
	var glows := _glows_on(_ally)
	assert_eq(glows.size(), 1, "the struck body did not get its flash")
	if sparks.is_empty() or glows.is_empty():
		return

	var spark: Node3D = sparks[0]
	var glow: Node = glows[0]
	assert_true(spark.get_script() == BURST, "the spark is a vfx_burst.gd node")
	assert_true(_ally.mesh_node.material_overlay != null, "the flash is drawn as a material overlay on the body's mesh")
	assert_eq(_ally.mesh_node.material_overlay, glow.get("_material"), "the overlay is the flash's own material")

	# It lives: a fifth of a second in, the spark is still alive and the flash
	# has faded but not finished.
	for i in 12:
		spark.call("advance", TICK)
		glow.call("advance", TICK)
	assert_false(bool(spark.call("finished")), "the spark died inside 0.2 s; it has to outlive combat.json's 0.26 s ring")
	assert_false(spark.is_queued_for_deletion(), "the spark was freed before its life ran out")

	# It frees: past its duration the spark queues itself, and the flash puts
	# the mesh back exactly as it found it.
	var budget := int(ceil(float(spark.call("duration")) / TICK)) + 4
	for i in budget:
		spark.call("advance", TICK)
		glow.call("advance", TICK)
	assert_true(bool(spark.call("finished")), "the spark never finished")
	assert_true(spark.is_queued_for_deletion(), "a finished spark must free its node")
	assert_true(bool(glow.call("finished")), "the flash never finished")
	assert_true(glow.is_queued_for_deletion(), "a finished flash must free its node")
	assert_eq(_ally.mesh_node.material_overlay, null, "the flash left its overlay on the body's mesh")


func test_the_blow_that_empties_the_bar_adds_a_ko_puff() -> void:
	var mgr := _manager_in_a_fight(1.0)
	mgr.call("_on_enemy_strike")
	var outcome := str(mgr.get("_outcome"))
	mgr.free()

	assert_eq(_ally.faints, 1, "a 1 HP creature taking a real blow must faint")
	assert_eq(outcome, "lost", "a wild fight ends when the piloted creature faints")
	assert_eq(_children_named(_arena, VFX.NAME_HIT_SPARK).size(), 1, "the killing blow still sparks")
	var puffs := _children_named(_arena, VFX.NAME_KO_PUFF)
	assert_eq(puffs.size(), 1, "no KoPuff after the blow that emptied the bar")
	if puffs.is_empty():
		return
	var puff: Node3D = puffs[0]
	assert_almost_eq(puff.position.y, _ally.centre().y, 0.01, "the puff rises from the fainted body's centre")
	var budget := int(ceil(float(puff.call("duration")) / TICK)) + 4
	for i in budget:
		puff.call("advance", TICK)
	assert_true(puff.is_queued_for_deletion(), "a finished puff must free its node")


func test_the_layer_switched_off_spawns_nothing_and_the_fight_still_resolves() -> void:
	VFX.set_enabled_override(false)
	var mgr := _manager_in_a_fight(1.0)
	mgr.call("_on_enemy_strike")
	var outcome := str(mgr.get("_outcome"))
	mgr.free()
	assert_eq(outcome, "lost", "switching the VFX off must not touch the fight")
	assert_eq(_arena.get_child_count(), 0, "vfx.json enabled=false must spawn nothing")
	assert_eq(_glows_on(_ally).size(), 0, "vfx.json enabled=false must not flash the body")


# --- sizing and tint --------------------------------------------------------

func test_a_heavy_blow_bursts_bigger_than_a_light_one() -> void:
	var light: Node3D = VFX.hit(_arena, Vector3.ZERO, null, false, _wild, 0.02)
	var heavy: Node3D = VFX.hit(_arena, Vector3.ZERO, null, false, _wild, 0.5)
	var charged: Node3D = VFX.hit(_arena, Vector3.ZERO, null, true, _wild, 0.5)
	assert_true(light != null and heavy != null and charged != null, "every hit spawns a spark")
	if light == null or heavy == null or charged == null:
		return
	assert_true(float(heavy.call("burst_scale")) > float(light.call("burst_scale")) * 1.3,
		"damage must scale the spark (light %.2f, heavy %.2f)" % [float(light.call("burst_scale")), float(heavy.call("burst_scale"))])
	assert_true(float(charged.call("burst_scale")) > float(heavy.call("burst_scale")),
		"the charged move bursts bigger than a quick one of the same bite")


func test_the_spark_is_tinted_by_the_moves_type() -> void:
	var water: Variant = VFX.tint_for_type("water")
	assert_true(water is Color, "water is a mapped type")
	assert_eq(VFX.tint_for_type(""), null, "no type, no tint")
	assert_eq(VFX.tint_for_type("no_such_type"), null, "an unmapped type falls back to the caller's default")
	var expected := Color(str(VFX.config().get("type_colours", {}).get("water", "")))
	assert_eq(water, expected, "the tint is the colour vfx.json maps for the type")
	# The spark carries the move's HUE, saturated for the field (vfx.json
	# `tint_saturation`): a water hit is a bluer blue, never a different colour.
	var spark: Node3D = VFX.hit(_arena, Vector3.ZERO, water, false, _wild, 0.1)
	assert_true(spark != null, "a tinted hit spawns a spark")
	if spark != null:
		var got: Color = spark.call("colour")
		assert_almost_eq(got.h, (water as Color).h, 0.02, "the spark keeps the move's hue")
		assert_true(got.s >= (water as Color).s - 0.001, "saturation is boosted, never washed out")
	var plain: Node3D = VFX.hit(_arena, Vector3.ZERO, null, false, _wild, 0.1)
	assert_true(plain != null, "an untinted hit spawns a spark")
	if plain != null:
		assert_almost_eq((plain.call("colour") as Color).h, VFX.default_colour().h, 0.02, "no tint means the default hue")


func test_a_sealed_catch_bursts() -> void:
	var burst: Node3D = VFX.catch_success(_arena, Vector3(1.0, 0.5, 2.0))
	assert_true(burst != null, "a catch must burst")
	if burst == null:
		return
	assert_eq(burst.name, VFX.NAME_CATCH_BURST)
	assert_eq(burst.position, Vector3(1.0, 0.5, 2.0), "the burst sits on the orb")


# --- the level-up watcher ---------------------------------------------------

func test_the_watcher_flourishes_the_deployed_creature_when_its_level_rises() -> void:
	var party: RefCounted = PARTY.new()
	var mine := _creature(3, "Champ")
	party.call("add", mine)
	var director := StandInDirector.new()
	director.ally = mine
	director.body = _ally
	_root.add_child(director)
	var watcher: Node = VFX.new()
	_root.add_child(watcher)

	assert_eq((watcher.call("poll_party", party, director, 0.0) as Array).size(), 0, "the first poll only takes the snapshot")
	assert_eq((watcher.call("poll_party", party, director, 0.1) as Array).size(), 0, "nothing changed, nothing fires")

	var before: int = mine.level
	var gained: int = mine.gain_xp(int(mine.xp_to_next(PROGRESSION.config())) + 1, PROGRESSION.config())
	assert_true(gained >= 1 and mine.level > before, "gain_xp must actually raise the level for this test")

	var seen: Array = watcher.call("poll_party", party, director, 0.2)
	assert_eq(seen.size(), 1, "the watcher missed a real level-up")
	if seen.is_empty():
		return
	assert_eq(seen[0]["creature"], mine)
	assert_eq(int(seen[0]["levels"]), mine.level - before)

	var flourishes: Array = []
	for child in _ally.get_children():
		if child.get_script() == FLOURISH:
			flourishes.append(child)
	assert_eq(flourishes.size(), 1, "no LevelUpFlourish on the deployed body")
	assert_eq(_glows_on(_ally).size(), 1, "the level-up carries a rim glow on the body")
	assert_eq((watcher.call("poll_party", party, director, 0.3) as Array).size(), 0, "the same rise must not fire twice")
	if flourishes.is_empty():
		return
	var flourish: Node3D = flourishes[0]
	var budget := int(ceil(float(flourish.call("duration")) / TICK)) + 4
	for i in budget:
		flourish.call("advance", TICK)
	assert_true(flourish.is_queued_for_deletion(), "a finished flourish must free its node")
	assert_true(float(flourish.call("duration")) >= 1.2 and float(flourish.call("duration")) <= 2.5,
		"the flourish is a ~1.5 s moment, not a blink or a loop (%.2f s)" % float(flourish.call("duration")))


func test_the_watcher_records_a_newcomer_without_flourishing_and_only_lights_the_deployed_body() -> void:
	var party: RefCounted = PARTY.new()
	var mine := _creature(3, "Champ")
	var bench := _creature(3, "Bench")
	party.call("add", mine)
	var director := StandInDirector.new()
	director.ally = mine
	director.body = _ally
	_root.add_child(director)
	var watcher: Node = VFX.new()
	_root.add_child(watcher)
	watcher.call("poll_party", party, director, 0.0)

	# A creature that arrives at level 3 did not level to 3.
	party.call("add", bench)
	assert_eq((watcher.call("poll_party", party, director, 1.0) as Array).size(), 0, "a newly added member is not a level-up")

	# The bench member levels in its orb: the watcher sees it, but there is no
	# body in the world to light, so nothing is drawn (vfx.json bench_on_trainer off).
	bench.gain_xp(int(bench.xp_to_next(PROGRESSION.config())) + 1, PROGRESSION.config())
	var seen: Array = watcher.call("poll_party", party, director, 2.0)
	assert_eq(seen.size(), 1, "the bench rise is still detected")
	var flourishes := 0
	for child in _ally.get_children():
		if child.get_script() == FLOURISH:
			flourishes += 1
	assert_eq(flourishes, 0, "a bench level-up must not light the OTHER creature's body")

	# The progression-feed seam plays the same flourish for the deployed one.
	var played: bool = watcher.call("on_progression_event",
		{"kind": "level_up", "creature": mine, "levels_gained": 1}, director)
	assert_true(played, "a level_up feed event for the deployed creature flourishes it")
	assert_false(bool(watcher.call("on_progression_event", {"kind": "xp_gained", "creature": mine}, director)),
		"only level_up events are the flourish's business")
