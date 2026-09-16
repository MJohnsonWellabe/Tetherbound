extends TestCase

const HARNESS := preload("res://tools/gate_f/operator_harness.gd")

class Wild extends Node3D:
	var alive := true
	var species_id := "bramblebun"
	var kind := "wild"
	func is_alive() -> bool:
		return alive


class TargetProbe extends RefCounted:
	var scene: Node3D
	var actor: Node3D
	func world() -> Node:
		return scene
	func player() -> Node3D:
		return actor
	func _poi_kind(node: Node3D) -> String:
		return node.kind if node is Wild else ""


func test_entity_lookup_selects_nearest_live_wild_and_advances_after_defeat() -> void:
	# The synchronous unit runner is still in SceneTree._init. Follow the
	# isolated-child convention used by test_combat_realm_owned_begin so real
	# global transforms exist before exercising the production distance sort.
	var runner_path := "user://gate-f-live-targets-child.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_gate_f_live_targets.gd").new()\n\ttest._case_nearest_live_in_entered_tree()\n\tprint("LIVE_TARGET_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count == 9 else 1)\n')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(runner_path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script", absolute,
		"--log-file", ProjectSettings.globalize_path("user://gate-f-live-targets-child.log")], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR") or combined.contains("ERROR:"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("LIVE_TARGET_RESULT="):
			result = JSON.parse_string(line.trim_prefix("LIVE_TARGET_RESULT="))
	assert_eq(int(result.get("assertions", 0)), 9, "Child must finish all actual lookup checks")
	assert_eq(result.get("failures", ["missing result"]), [])


func _case_nearest_live_in_entered_tree() -> void:
	var harness := HARNESS.new()
	var probe := TargetProbe.new()
	probe.scene = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(probe.scene)
	assert_true(probe.scene.is_inside_tree(), "distance sorting requires real global transforms")
	# Use an ordinary nonmatching actor name: the player's own creature below
	# intentionally shares the requested species, but is not a wild provider.
	probe.actor = Node3D.new()
	probe.actor.name = "Player"
	probe.scene.add_child(probe.actor)
	harness._probe = probe
	var nodes: Array[Wild] = []
	# Insertion order is deliberately opposite nearest order. The distant
	# expansion spawn must never displace a nearby eligible training target.
	for distance in [400.0, 24.0, 12.0, 3.0, 2.0, 1.0]:
		var node := Wild.new()
		node.name = "Candidate%d" % nodes.size()
		node.position = Vector3(distance, 0.0, 0.0)
		probe.scene.add_child(node)
		nodes.append(node)
	nodes[3].alive = false
	nodes[4].visible = false
	nodes[5].kind = "companion"
	var trainer := Wild.new()
	trainer.kind = "trainer"
	trainer.position = Vector3(0.5, 0.0, 0.0)
	probe.scene.add_child(trainer)
	nodes[2].species_id = "pipwing"
	var args := {"rank": 0, "require_alive": true}
	var generic: Dictionary = harness._find_entity("poi:wild", args)
	assert_true(generic.ok and generic.node == nodes[2],
		"generic wild selects nearby other species while excluding closer trainer and ally")
	trainer.queue_free()
	nodes[2].species_id = "bramblebun"
	var selected: Dictionary = harness._find_entity("bramblebun", args)
	assert_true(selected.ok)
	assert_true(selected.node == nodes[2], "nearest means live wild, excluding corpse, hidden body and own ally")
	assert_true(str(selected.how).contains("species_id"), "exercise the actual species lookup branch")
	# Production is_alive changes immediately when the foe faints, before its
	# body is hidden. The next round must therefore move to another live foe.
	nodes[2].alive = false
	selected = harness._find_entity("bramblebun", args)
	assert_true(selected.ok)
	assert_true(selected.node == nodes[1], "a visible defeated body must not be retried")
	nodes[1].visible = false
	selected = harness._find_entity("bramblebun", args)
	assert_true(selected.node == nodes[0], "the far live wild remains eligible only after nearer candidates are unavailable")
	nodes[0].alive = false
	selected = harness._find_entity("bramblebun", args)
	assert_false(selected.ok, "own ally must not become a species fallback when all wilds are unavailable")
	probe.scene.free()
	harness.free() # Before the harness's deferred production _run can execute.


func test_caught_defeated_and_hidden_bodies_are_not_live_approach_targets() -> void:
	var wild := Wild.new()
	assert_true(HARNESS._available_live_target(wild))
	wild.alive = false
	assert_false(HARNESS._available_live_target(wild), "caught/defeated nodes can remain in the scene")
	wild.alive = true
	wild.visible = false
	assert_false(HARNESS._available_live_target(wild))
	wild.free()
	var prop := Node3D.new()
	assert_false(HARNESS._available_live_target(prop), "named scenery cannot satisfy an alive creature request")
	prop.free()
