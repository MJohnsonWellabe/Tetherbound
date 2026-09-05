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


func test_glow_tolerates_model_mesh_freed_before_suspension_and_finish() -> void:
	var body := StandInBody.new()
	var glow: Node = GLOW.attach(body, GLOW.Mode.FLASH, {"duration": 0.1}, 0.85)
	assert_true(glow != null)
	body.mesh_node.free()
	body.mesh_node = null
	glow.call("suspend", true)
	glow.call("suspend", false)
	glow.call("advance", 0.2)
	assert_true(glow.call("finished"))
	assert_true(glow.is_queued_for_deletion())
	assert_eq(glow.call("mesh_count"), 0)
	body.free()


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


## --- the catch-seal composite (N14-ROUTED-FOLLOWUPS, from N07-VFX-POLISH) ----
##
## N07 finished the seal's ring and its colour and then listed four things it
## could not reach from its own file. All four are fixed together, because all
## four are the same composite: the orb at the moment it seals.
##
## These are bounds tests on the numbers, not on how they look -- the looking is
## a blind judge's job and the sheet is in this lane's report. What each one
## holds is the ARITHMETIC the change was argued from, so a later retune that
## walks past the reason has to answer for it.

const IMPACT_FLASH := preload("res://scripts/combat/impact_flash.gd")
const ORB := preload("res://scripts/combat/orb.gd")


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


## `impact_flash.gd` is shared by every attack in the game, which is exactly why
## N07 refused to soften it in place. The softness must therefore be OFF unless
## a caller's own data asks for it.
func test_spike_softness_is_opt_in_and_off_for_every_attack() -> void:
	var combat := _json("res://data/config/combat.json")
	var impact: Dictionary = combat.get("impact", {})
	for key: String in ["quick", "charged"]:
		var spec: Dictionary = impact.get(key, {})
		assert_false(spec.has("spike_softness"),
			"combat.json's %s attack opted into spike softness; every blow in the game just changed look without a judged render" % key)

	var flash: Node3D = IMPACT_FLASH.new()
	assert_almost_eq(float(flash.get("_spike_softness")), 0.0, 0.0001,
		"the default is not 0.0, so an attack that names no softness no longer draws the spike it always has")
	flash.free()


func test_the_catch_seal_is_the_one_effect_that_asks_for_soft_spikes() -> void:
	var vfx: Dictionary = _json("res://data/config/catching.json").get("vfx", {})
	var caught: Dictionary = vfx.get("caught", {})
	var softness := float(caught.get("spike_softness", 0.0))
	assert_true(softness > 0.0,
		"the seal no longer softens its spikes; N07's routed finding is back")
	assert_true(softness <= 1.0, "softness is a 0-1 fraction; %f is out of range" % softness)
	# The other two catch effects play at different moments and were not judged
	# with the seal. Silence here is deliberate, not an oversight.
	for key: String in ["strike", "breakout"]:
		assert_false((vfx.get(key, {}) as Dictionary).has("spike_softness"),
			"%s opted in without a render; only the seal was judged" % key)


## The claim the retune was argued from, and specifically the half the first
## attempt got wrong: it is the SLOWEST motes that have to clear the orb, not
## the fastest. The shipped burst's leading edge was already 0.672 m out at
## three ticks and clear of a 0.60 m orb; its slowest third was at 0.224 m,
## sitting inside it. That tail is what N07's judge read as "dust or mud kicked
## up" burying the orb, and a retune that raises the ceiling without raising the
## floor leaves it exactly where it was.
##
## `vfx_burst.gd` eases the displacement rather than running it at constant
## speed (`1 - (1 - u)^2.2`), so this test asks that curve rather than
## multiplying speed by time -- which is the arithmetic error the first pass
## made, and it under-reported the reach by a factor of two.
func test_the_slowest_catch_burst_motes_clear_the_orb_by_the_third_tick() -> void:
	var burst: Dictionary = _json("res://data/config/vfx.json").get("catch_burst", {})
	assert_false(burst.is_empty(), "catch_burst is gone from vfx.json")
	var orb_radius := float(_json("res://data/config/catching.json").get("throw", {}).get("radius", 0.6))
	var duration := float(burst.get("duration", 1.0))
	var speed := float(burst.get("speed", 0.0))
	var variance := float(burst.get("speed_variance", 0.0))

	var u: float = (3.0 * TICK) / duration
	var eased: float = 1.0 - pow(1.0 - u, 2.2)
	var slowest: float = speed * (1.0 - variance) * eased * duration
	var fastest: float = speed * (1.0 + variance) * eased * duration

	assert_true(slowest >= orb_radius,
		"at three ticks the SLOWEST motes are %.3fm from the centre of a %.2fm orb -- still inside it, which is the finding" % [slowest, orb_radius])
	assert_true(fastest > slowest,
		"the spread collapsed to a single speed; the burst reads as one expanding shell rather than a spray")
	# And not so hard or so thin that the sparkle stops being one.
	assert_true(float(burst.get("duration", 0.0)) >= 0.45,
		"the burst now ends before the seal does")
	assert_true(int(burst.get("count", 0)) >= 10,
		"fewer than ten motes is not a burst any more")
	assert_true(variance >= 0.2,
		"with no speed spread every mote arrives at the same radius at the same instant")


## The resolve camera has to clear a creature standing at the orb AND keep the
## orb the size the framing pass settled on. Half the frame width at the subject
## is distance * tan(fov / 2); that product is the number that must not move.
func test_the_resolve_camera_clears_an_ally_without_shrinking_the_orb() -> void:
	var camera: Dictionary = _json("res://data/config/catching.json").get("resolve_camera", {})
	assert_false(camera.is_empty(), "resolve_camera is gone from catching.json")
	var distance := float(camera.get("distance", 0.0))
	var fov := float(camera.get("fov", 0.0))
	var height := float(camera.get("height", 0.0))
	var pitch := absf(float(camera.get("pitch_start_deg", 0.0)))

	# A deployed creature is roughly a metre and a half across at the shoulder,
	# so a lens closer than that to the orb it is standing over is inside it.
	assert_true(distance >= 3.0,
		"the lens is %.2fm from the orb; an ally standing at the seal is between it and its subject, which the judge called 'indistinguishable from a bug'" % distance)

	# `height` is NOT the camera's elevation -- `camera_rig.gd:380` makes it the
	# pivot offset, i.e. how far above the orb the frame is CENTRED. The first
	# pass at this raised it to clear a creature and rendered a seal with the
	# orb sliced off the bottom edge. It has to stay small.
	assert_true(height <= 0.8,
		"the frame is centred %.2fm above the orb; at this shot's %.2fm half-height the orb slides off the bottom edge" % [
			height, distance * tan(deg_to_rad(fov) * 0.5)])

	# The lens is lifted by the PITCH instead, which moves the camera without
	# moving the frame. Elevation above the pivot is distance * sin(pitch).
	var lens_above_pivot: float = distance * sin(deg_to_rad(pitch))
	var standoff: float = distance * cos(deg_to_rad(pitch))
	assert_true(lens_above_pivot + height >= 2.2,
		"the lens sits %.2fm over the ground -- chest height on a deployed creature standing at the seal, which is how it ends up inside one" % (lens_above_pivot + height))
	assert_true(standoff >= 2.0,
		"the lens is only %.2fm horizontally from the orb; it clears a creature's height but not its bulk" % standoff)

	# The framing the earlier pass settled on, held to within 10%: the previous
	# rejected attempt (3.2 / fov 50) reads 1.49m here against the 1.12m that
	# was accepted, which is the "orb huddled small at the bottom of the frame"
	# this bound exists to catch.
	var half_frame: float = distance * tan(deg_to_rad(fov) * 0.5)
	assert_true(absf(half_frame - 1.12) <= 0.112,
		"half the frame at the orb is %.2fm against the 1.12m the framing pass accepted; the orb changed size on screen" % half_frame)


## The halo the judge called "the clearest rendering bug in the catch sequence":
## a straight-edged disc with a linear ramp. Rounder rim, curved falloff.
func test_the_orb_halo_is_round_enough_and_falls_off_on_a_curve() -> void:
	assert_true(int(ORB.HALO_SEGMENTS) >= 28,
		"at %d segments the halo shows its own polygon edges as the straight lines the judge called a trapezoid" % int(ORB.HALO_SEGMENTS))
	assert_true(int(ORB.HALO_RINGS) >= 2,
		"one ring means one linear ramp from centre to rim, which is the hard cone edge being fixed")
	assert_true(float(ORB.HALO_FALLOFF_EXP) > 1.0,
		"an exponent of 1 or less is a linear (or worse) ramp; a glow needs to fall off faster than its radius grows")
