extends SceneTree

## Does `scripts/debug/gate_f_probe.gd` actually agree with the live game?
##
##   godot --headless --path . --script tests/smoke_gate_f_probe.gd
##
## **Headless, never under xvfb** — this renders nothing, and under software GL
## it takes 25x longer and flakes under load (`docs/AGENT_WORKFLOW.md`).
##
## ## Why this is a smoke test and not a unit test
##
## `tests/run_tests.gd` runs every test file from its own `_init`, which is
## before Godot has registered the main loop. `Engine.get_main_loop()` returns a
## null Object there, so a unit test has no tree, no `/root/Game` and nothing to
## ask. The first cut of `tests/test_gate_f_instrumentation.gd` had three such
## tests and all three passed by returning early on a null tree — an assertion
## that cannot fail, which this repo has already shipped a real bug behind.
## Source-level contracts stayed in that file; everything needing live state is
## here.
##
## ## What it is for
##
## `docs/acceptance/GATE_F_MASTER_PROTOCOL.md` §C.5 is the whole point of the probe:
## telemetry reads live game state, "never a parallel reimplementation". A probe
## that disagrees with the game is worse than no probe — the operator writes
## down what it said and Phase B reasons about a number no player ever saw. The
## only way to check that is to stand a real world up and compare.
##
## So each phase below reads something through the probe and then reads the SAME
## thing through the object the game itself uses, and fails when they differ. It
## is not asserting that the probe returns a plausible value; it is asserting
## that it returns the game's value.
##
## Two phases, cheap first:
##
##   1. no world in the tree. The probe is asked for everything twice a second,
##      including at the title and during a scene swap when half of what it looks
##      for does not exist. An accessor that errors there takes a four-hour run
##      down mid-segment.
##   2. the real Meadows. Objective, region, party, vitals, camera, clock and
##      the point-of-interest scan, each against the game's own reader.
##
## Phase 2 costs about ninety seconds of world stand-up on this container. That
## is the price of checking the thing the protocol actually depends on.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const PROBE := preload("res://scripts/debug/gate_f_probe.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const CREATURE_CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const SETTLE_FRAMES := 240

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_with_no_world()
	await _with_the_real_meadows()
	_finish()


# --- phase 1: nothing loaded -------------------------------------------------

func _with_no_world() -> void:
	var probe: RefCounted = PROBE.new(self)
	_expect(probe.call("world") == null, "world() must be null with no current scene")
	_expect(probe.call("player") == null, "player() must be null with no world")
	# `no_scene`, not `world`. Every world-verb gate reads permissively when the
	# node it asks about is absent, so a probe that only checked those gates
	# would report an empty tree as free run of the map -- which it did, until
	# `selfcheck_capture.json` caught the title screen reporting `world`.
	_expect(str(probe.call("input_context")) == "no_scene",
		"with nothing loaded the honest input context is 'no_scene', got '%s'"
			% str(probe.call("input_context")))
	_expect((probe.call("combat_state") as Dictionary).is_empty(),
		"combat_state() must be empty rather than a fabricated resting fight")
	_expect((probe.call("camera_pose") as Dictionary).is_empty(),
		"camera_pose() must be empty with no rig")
	_expect(int(probe.call("refresh_pois")) == 0, "no world means no points of interest")
	# INF, not 0. A zero here would reset the dead-travel meter on every single
	# frame of a title screen and quietly zero the pacing study.
	_expect(is_inf(float(probe.call("nearest_poi_dist", Vector3.ZERO))),
		"with no points of interest the nearest distance is INF, not 0")
	_expect(str(probe.call("region_at", Vector3(99999.0, 0.0, 99999.0))) == "corridor",
		"a position inside no authored region reports 'corridor' (§C.1)")

	# `input_state()` is the half of the input report that is NOT a name, and
	# the schema doc promises that when the name and the booleans disagree the
	# booleans are believed. Every gate a world-verb poll reads has to be there.
	var state: Dictionary = probe.call("input_state")
	for key in ["owner", "combat_running", "combat_aiming", "arbiter_enabled",
			"pending_build", "tree_paused", "focus_owner", "focus_text", "mouse_mode"]:
		_expect(state.has(key),
			"input_state() has no '%s'. §8 asks which surface a press reached, and a context NAME alone cannot answer it." % key)


# --- phase 2: the real world -------------------------------------------------

func _with_the_real_meadows() -> void:
	var packed := load(WORLD_SCENE) as PackedScene
	if packed == null:
		_fail("could not load %s" % WORLD_SCENE)
		return
	var world: Node3D = packed.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	var player := world.get_node_or_null(^"Player") as Node3D
	if game == null or player == null:
		_fail("the real Game/Player lifecycle was not available after boot")
		return
	var probe: RefCounted = PROBE.new(self)

	_the_objective_is_the_one_the_hud_draws(probe, game)
	_the_region_is_the_one_map_state_resolves(probe, game, player)
	_the_party_is_the_live_party(probe, game)
	_the_vitals_are_the_live_vitals(probe, game)
	_the_camera_pose_is_the_live_rig(probe, world)
	_the_clock_is_world_looks_own(probe, world)
	_the_poi_scan_finds_real_content(probe, player)
	_the_input_context_agrees_with_the_gates(probe)


## `tab_quest_log.gd` and `playground_hud.gd`'s tracked line both read
## `quest_log.gd`. The probe must return the same string, or the operator's
## note and the player's screen disagree about what the game asked for.
func _the_objective_is_the_one_the_hud_draws(probe: RefCounted, game: Node) -> void:
	var progression: Variant = game.get("progression")
	var expected := str(QUEST_LOG.new().call("tracked_text", progression))
	var got: Dictionary = probe.call("tracked_objective")
	_expect(str(got.get("text", "")) == expected,
		"tracked_objective().text is '%s'; quest_log.gd::tracked_text() says '%s'"
			% [str(got.get("text", "")), expected])
	if expected.is_empty():
		return
	_expect(not str(got.get("id", "")).is_empty(),
		"tracked_objective() returned text '%s' with no id; the id is how Phase B cites a beat" % expected)
	# The id must be a flag the store actually knows about, not a label the
	# probe invented: the whole reason it is recovered by matching back through
	# the reader is so it names a real `flag_id`.
	var objectives: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/progression/objectives.json"))
	var known := false
	for raw: Variant in ((objectives as Dictionary).get("main", []) as Array):
		if typeof(raw) == TYPE_DICTIONARY and str((raw as Dictionary).get("flag_id", "")) == str(got.get("id", "")):
			known = true
	_expect(known, "tracked_objective().id '%s' is not a flag_id in objectives.json" % str(got.get("id", "")))


func _the_region_is_the_one_map_state_resolves(probe: RefCounted, game: Node, player: Node3D) -> void:
	var map: Variant = game.get("map")
	var here := player.global_position
	var direct: Dictionary = map.call("_region_at", Vector2(here.x, here.z))
	var expected := "corridor" if direct.is_empty() else str(direct.get("id", "corridor"))
	_expect(str(probe.call("region_at", here)) == expected,
		"region_at() says '%s'; map_state.gd's own containment says '%s'"
			% [str(probe.call("region_at", here)), expected])


## Add a creature through the live party and check the probe sees it, with the
## condition fields read from `creature_condition.gd::summary()` rather than
## thresholded independently.
func _the_party_is_the_live_party(probe: RefCounted, game: Node) -> void:
	var party: Variant = game.get("party")
	var before := (probe.call("party_state") as Array).size()
	_expect(before == int(party.call("size")),
		"party_state() reports %d creatures; the live party holds %d" % [before, int(party.call("size"))])

	var creature: Variant = game.call("make_creature", "terrapup", "ProbeCheck")
	if creature == null:
		_fail("could not make a creature to check party_state() against")
		return
	party.call("add", creature)
	var rows: Array = probe.call("party_state")
	_expect(rows.size() == before + 1, "party_state() did not see a creature the live party holds")
	if rows.is_empty():
		return
	var row: Dictionary = rows[rows.size() - 1]
	for key in ["species", "name", "level", "xp", "hp", "max_hp", "fed", "rested", "bond"]:
		_expect(row.has(key), "party_state() row has no '%s' (§C.1's table)" % key)
	_expect(str(row.get("species", "")) == "terrapup", "party_state() read the wrong creature")
	_expect(int(row.get("level", -1)) == int(creature.get("level")),
		"party_state() level %s does not match the creature's own %d"
			% [str(row.get("level")), int(creature.get("level"))])
	var summary: Dictionary = CREATURE_CONDITION.summary(creature, CREATURE_CONDITION.config())
	_expect(bool(row.get("fed", false)) == bool(summary.get("fed", false)),
		"party_state().fed disagrees with creature_condition.gd::summary() -- the reader tournament.gd gates entry on")
	_expect(bool(row.get("rested", false)) == bool(summary.get("rested", false)),
		"party_state().rested disagrees with creature_condition.gd::summary()")
	party.call("clear")


func _the_vitals_are_the_live_vitals(probe: RefCounted, game: Node) -> void:
	var vitals: Variant = game.call("player_vitals")
	if vitals == null:
		_fail("Game has no live vitals object to check against")
		return
	var got: Dictionary = probe.call("player_vitals")
	_expect(absf(float(got.get("hp", -1.0)) - float(vitals.get("health"))) < 0.001,
		"player_vitals().hp does not match the live vitals' health")
	_expect(absf(float(got.get("stamina", -1.0)) - float(vitals.get("stamina"))) < 0.001,
		"player_vitals().stamina does not match the live vitals")
	_expect(absf(float(got.get("satiety", -1.0)) - float(vitals.get("satiety"))) < 0.001,
		"player_vitals().satiety does not match the live vitals")


## Degrees, not radians. The rig stores radians; the neighbouring `heading`
## field in the same event is degrees, and two angle units in one record is how
## a Phase B reader ends up plotting a 6.28-degree pan.
func _the_camera_pose_is_the_live_rig(probe: RefCounted, world: Node3D) -> void:
	var rig := world.get_node_or_null(^"CameraRig") as SpringArm3D
	if rig == null:
		_fail("the world has no CameraRig to check camera_pose() against")
		return
	rig.set("yaw", 0.5)
	var pose: Dictionary = probe.call("camera_pose")
	_expect(absf(float(pose.get("yaw", 0.0)) - rad_to_deg(0.5)) < 0.01,
		"camera_pose().yaw is %s; the rig's yaw of 0.5 rad is %.2f degrees"
			% [str(pose.get("yaw")), rad_to_deg(0.5)])
	_expect(absf(float(pose.get("distance", -1.0)) - rig.spring_length) < 0.001,
		"camera_pose().distance must be the SpringArm's live spring_length -- collision shortens the arm and the short one is what the player sees")
	var camera := rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera != null:
		_expect(absf(float(pose.get("fov", -1.0)) - camera.fov) < 0.001,
			"camera_pose().fov does not match the live camera")


func _the_clock_is_world_looks_own(probe: RefCounted, world: Node3D) -> void:
	var look := world.get_node_or_null(^"WorldLook")
	if look == null:
		_fail("the world has no WorldLook to check clock_weather() against")
		return
	var cycle: Variant = look.get("_cycle")
	var got: Dictionary = probe.call("clock_weather")
	if cycle != null:
		var expected := float(cycle.call("hour_at", float(look.get("_elapsed_seconds"))))
		_expect(absf(float(got.get("hour", -1.0)) - expected) < 0.05,
			"clock_weather().hour is %s; WorldLook's own cycle says %.3f" % [str(got.get("hour")), expected])
	var weather := world.get_node_or_null(^"WorldWeather")
	if weather != null:
		_expect(str(got.get("weather", "")) == str(weather.call("weather")),
			"clock_weather().weather does not match WorldWeather's own answer")


## The point-of-interest scan is the input to the dead-travel meter, and the
## meter is §D's whole pacing study. An empty scan would make every walk read as
## infinite dead travel; a scan that never comes back below 30 m would make it
## always read as zero.
func _the_poi_scan_finds_real_content(probe: RefCounted, player: Node3D) -> void:
	var count := int(probe.call("refresh_pois"))
	_expect(count > 0,
		"the point-of-interest scan found nothing in the whole Meadows. Every dead-travel figure would then be the length of the segment.")
	var here := float(probe.call("nearest_poi_dist", player.global_position))
	_expect(not is_inf(here),
		"nearest_poi_dist() is INF at the spawn point, which the village's own landmarks and interactables should be well inside")
	# A sanity bound rather than an exact number: the spawn stands in the
	# village, and a nearest POI kilometres away would mean the scan is
	# measuring against the wrong coordinate space.
	_expect(here < 500.0,
		"nearest point of interest is %.0f m from the spawn point; that is not the village this scan is supposed to be looking at" % here)


## The context name must never contradict the gates it is a name over. This is
## the promise `tools/gate_f/SEGMENT_SCHEMA.md` makes to Phase B, and it is the
## one thing about `input_context()` that can be checked mechanically.
func _the_input_context_agrees_with_the_gates(probe: RefCounted) -> void:
	var context := str(probe.call("input_context"))
	var state: Dictionary = probe.call("input_state")
	if bool(state.get("combat_running", false)):
		_expect(context == "combat" or context == "combat_aim",
			"a fight is running and input_context says '%s'" % context)
		return
	if not str(state.get("owner", "")).is_empty():
		_expect(context != "world",
			"'%s' holds the input-owner group and input_context still says 'world'" % str(state.get("owner")))
		return
	if context == "world":
		_expect(bool(state.get("arbiter_enabled", true)),
			"input_context says 'world' while the interaction arbiter is disabled; that state is 'locked'")
		_expect(str(state.get("pending_build", "")).is_empty(),
			"input_context says 'world' while a build ghost is armed; that state is 'build_placement'")


# --- reporting ---------------------------------------------------------------

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("gate-f probe: OK -- every accessor agreed with the live game it reads")
	else:
		for line in _failures:
			print("gate-f probe FAIL: %s" % line)
	quit(0 if _failures.is_empty() else 1)
