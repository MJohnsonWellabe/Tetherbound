extends "res://tests/test_case.gd"

const ANIMATOR := preload("res://scripts/creatures/creature_animator.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const BODY_SCENE := preload("res://scenes/creatures/creature.tscn")

const ATTACK_LENGTH := 23.0 / 24.0
const CONTACT_PHASE := 15.0 / 23.0

var _player: AnimationPlayer
var _animator: RefCounted


func before_each() -> void:
	_player = AnimationPlayer.new()
	var library := AnimationLibrary.new()
	for clip: String in ["idle", "walk", "run", "attack", "hit", "faint"]:
		var animation := Animation.new()
		animation.length = ATTACK_LENGTH if clip == "attack" else 0.5
		library.add_animation(clip, animation)
	_player.add_animation_library("", library)
	_animator = ANIMATOR.new(_player, {
		"idle": "idle", "walk": "walk", "run": "run", "attack": "attack",
		"hit": "hit", "faint": "faint", "attack_contact_phase": CONTACT_PHASE,
	})


func after_each() -> void:
	_player.free()


func test_real_wild_telegraph_uses_profile_duration_and_emits_same_gameplay_time() -> void:
	for telegraph: float in [0.4, 1.0]:
		var wild: Node = WILD.new()
		wild.set("_animator", _animator)
		wild.set("_combat_cfg", {"telegraph": telegraph})
		var emitted: Array[float] = []
		wild.telegraph_started.connect(func(seconds: float) -> void: emitted.append(seconds))
		wild.call("_enter", AI.Intent.TELEGRAPH)

		assert_eq(emitted.size(), 1, "the production WildCreature emits one telegraph")
		assert_almost_eq(emitted[0], telegraph, 0.0001, "visual timing preserves the gameplay duration")
		assert_eq(_player.current_animation, "attack", "the real transition starts anticipation")
		assert_almost_eq(_player.speed_scale, ATTACK_LENGTH * CONTACT_PHASE / telegraph, 0.0001,
			"playback reaches the authored contact at impact")
		assert_true(float(_animator.get("_hold")) >= telegraph,
			"the complete clip cannot finish before the telegraph")
		wild.free()
		_animator.call("cancel_hold")


func test_impact_continues_from_contact_without_restart_then_movement_resets_speed() -> void:
	# The unit runner itself executes from SceneTree._init, where AnimationPlayer
	# cannot build caches or advance. Run this one case in a tiny initialized
	# child tree so the assertion covers actual engine playback rather than a
	# mirrored duration calculation.
	var run_id := "%s-%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	var path := "user://creature-attack-telegraph-child-%s.gd" % run_id
	var log_path := ProjectSettings.globalize_path("user://creature-attack-telegraph-child-%s.log" % run_id)
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null, "child runner can be written")
	if file == null:
		return
	file.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_creature_attack_telegraph_animation.gd").new()\n\ttest._case_impact_continues_in_initialized_tree()\n\ttest._case_engagement_boundaries_in_initialized_tree()\n\tprint("ATTACK_TIMING_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count == 16 else 1)\n')
	file.close()
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script", ProjectSettings.globalize_path(path),
		"--log-file", log_path], output, true)
	var result: Variant = null
	# Godot redirects the child's print stream into --log-file on Windows, so
	# parse that explicit retained output rather than assuming OS.execute also
	# mirrors it into the parent array. Read and echo errors BEFORE handling a
	# nonzero child exit so an empty OS pipe cannot hide the underlying failure.
	var result_lines := FileAccess.get_file_as_string(log_path).split("\n") if FileAccess.file_exists(log_path) else PackedStringArray()
	var engine_errors: Array[String] = []
	for line: String in result_lines:
		var clean := line.strip_edges()
		if clean.begins_with("ERROR:") or clean.begins_with("SCRIPT ERROR:"):
			engine_errors.append(clean)
			print("[attack-timing-child] " + clean)
		if line.begins_with("ATTACK_TIMING_RESULT="):
			result = JSON.parse_string(line.trim_prefix("ATTACK_TIMING_RESULT="))
	for chunk: String in output:
		for line: String in chunk.split("\n"):
			var clean := line.strip_edges()
			if clean.begins_with("ERROR:") or clean.begins_with("SCRIPT ERROR:"):
				engine_errors.append(clean)
				print("[attack-timing-child] " + clean)
	assert_eq(engine_errors, [], "initialized child emits no engine errors")
	assert_eq(code, 0, "initialized AnimationPlayer child exits cleanly: %s" % "\n".join(output))
	if code != 0:
		return
	assert_true(result is Dictionary, "child returns structured animation assertions")
	if result is Dictionary:
		assert_eq(result.get("failures", []), [], "initialized animation assertions pass")


func _case_impact_continues_in_initialized_tree() -> void:
	var fixture := Node.new()
	fixture.name = "CreatureAttackTimingFixture"
	(Engine.get_main_loop() as SceneTree).root.add_child(fixture)
	var player := AnimationPlayer.new()
	fixture.add_child(player)
	var library := AnimationLibrary.new()
	for clip: String in ["idle", "walk", "run", "attack", "hit", "faint"]:
		var animation := Animation.new()
		animation.length = ATTACK_LENGTH if clip == "attack" else 0.5
		library.add_animation(clip, animation)
	player.add_animation_library("", library)
	var animator: RefCounted = ANIMATOR.new(player, {
		"idle": "idle", "walk": "walk", "run": "run", "attack": "attack",
		"hit": "hit", "faint": "faint", "attack_contact_phase": CONTACT_PHASE,
	})

	assert_true(animator.call("begin_attack_telegraph", 1.0), "annotated rig opts into anticipation")
	player.advance(1.0)
	var before_impact := player.current_animation_position
	animator.call("play_once", "attack")
	assert_eq(player.current_animation, "attack", "impact keeps the same attack clip")
	assert_true(before_impact > 0.0, "the real AnimationPlayer advanced before impact")
	assert_almost_eq(player.current_animation_position, ATTACK_LENGTH * CONTACT_PHASE, 0.002,
		"impact resolves at the authored contact pose rather than frame zero")
	assert_almost_eq(player.get_playing_speed(), 1.0, 0.0001, "effective recovery speed is one")

	animator.call("cancel_hold")
	animator.call("tick", 0.016, 2.0, 3.0)
	assert_eq(player.current_animation, "run", "movement cancels the remaining attack hold")
	assert_almost_eq(player.speed_scale, 1.0, 0.0001, "movement cannot inherit telegraph speed")
	assert_almost_eq(player.get_playing_speed(), 1.0, 0.0001, "effective locomotion speed is one")
	fixture.free()


func _case_engagement_boundaries_in_initialized_tree() -> void:
	var fixture := Node3D.new()
	fixture.name = "CreatureEngagementBoundaryFixture"
	(Engine.get_main_loop() as SceneTree).root.add_child(fixture)
	var wild: Node = BODY_SCENE.instantiate()
	wild.set_script(WILD)
	fixture.add_child(wild)
	var target := Node3D.new()
	fixture.add_child(target)
	var player := AnimationPlayer.new()
	wild.add_child(player)
	var library := AnimationLibrary.new()
	for clip: String in ["idle", "walk", "run", "attack", "hit", "faint"]:
		var animation := Animation.new()
		animation.length = ATTACK_LENGTH if clip == "attack" else 0.5
		library.add_animation(clip, animation)
	player.add_animation_library("", library)
	var animator: RefCounted = ANIMATOR.new(player, {
		"idle": "idle", "walk": "walk", "run": "run", "attack": "attack",
		"hit": "hit", "faint": "faint", "attack_contact_phase": CONTACT_PHASE,
	})
	wild.set("_animator", animator)
	wild.call("set_engaged", true, target)
	wild.set("_combat_cfg", {"telegraph": 1.0})
	wild.call("_enter", AI.Intent.TELEGRAPH)
	assert_true(float(animator.get("_hold")) > 1.0, "stationary wind-up owns a hold through impact")
	assert_true(player.get_playing_speed() < 1.0, "long telegraph is visibly slowed")

	# Failed-catch breakout reactivates directly with true after absorb suspended
	# physics, so this actual true boundary must clear the prior telegraph.
	wild.call("set_engaged", true, target)
	assert_almost_eq(float(animator.get("_hold")), 0.0, 0.0001, "true boundary clears the old hold")
	assert_eq(str(animator.get("_telegraph_attack_clip")), "", "true boundary clears timed attack identity")
	assert_almost_eq(player.get_playing_speed(), 1.0, 0.0001, "true boundary clears the old playback rate")

	wild.set("_combat_cfg", {"telegraph": 1.0})
	wild.call("_enter", AI.Intent.TELEGRAPH)
	assert_eq(str(animator.get("_telegraph_attack_clip")), "attack", "reactivation can start one fresh wind-up")
	animator.call("play_faint")
	wild.call("set_engaged", false)
	assert_true(bool(animator.get("_finished")), "false boundary never revives a fainted animator")
	assert_false(bool(wild.get("engaged")), "actual false boundary still disengages the body")
	fixture.free()


func test_hit_reaction_interrupts_timed_attack_and_restores_authored_speed() -> void:
	assert_true(_animator.call("begin_attack_telegraph", 1.0), "timed attack starts")
	_animator.call("play_once", "hit")
	assert_eq(_player.current_animation, "hit", "hit reaction still takes priority")
	assert_almost_eq(_player.speed_scale, 1.0, 0.0001, "hit reaction uses its authored speed")
	assert_almost_eq(_player.get_playing_speed(), 1.0, 0.0001, "effective hit speed is one")
	assert_eq(str(_animator.get("_telegraph_attack_clip")), "", "interrupted timing state is cleared")


func test_unannotated_animation_map_preserves_impact_time_playback() -> void:
	var legacy := ANIMATOR.new(_player, {
		"idle": "idle", "walk": "walk", "run": "run", "attack": "attack",
		"hit": "hit", "faint": "faint",
	})
	assert_false(legacy.call("begin_attack_telegraph", 0.4), "an unverified clip family does not borrow Torrentoad timing")
	assert_eq(_player.current_animation, "", "legacy body stays in its existing pose during telegraph")
	legacy.call("play_once", "attack")
	assert_eq(_player.current_animation, "attack", "legacy attack still begins at the existing impact call")
	assert_almost_eq(_player.get_playing_speed(), 1.0, 0.0001, "legacy attack keeps authored playback speed")


func test_torrentoad_metadata_reaches_the_installed_glb_contact_key() -> void:
	var look: Dictionary = SPECIES.table()["torrentoad"]["placeholder"]
	var packed := load(str(look["model"])) as PackedScene
	assert_true(packed != null, "Torrentoad installed GLB loads")
	if packed == null:
		return
	var model := packed.instantiate()
	var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	assert_eq(players.size(), 1, "installed Torrentoad carries one AnimationPlayer")
	if players.is_empty():
		model.free()
		return
	var player := players[0] as AnimationPlayer
	var animations: Dictionary = look["animations"]
	var clip := str(animations["attack"])
	var length := float(player.get_animation(clip).length)
	assert_almost_eq(length, 23.0 / 24.0, 0.000001, "installed sampler spans 23 frame intervals")
	assert_almost_eq(length * float(animations["attack_contact_phase"]), 15.0 / 24.0, 0.000001,
		"configured phase resolves to the authored frame-15 contact at 0.625 seconds")
	model.free()
