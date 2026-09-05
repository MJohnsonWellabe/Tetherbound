extends SceneTree

## Real rendering + production award/rest/feed consumers in an isolated fixture.
## Does not substitute for the full Meadows fight/feed/landmark/bed route gate.
const PRESENTER := preload("res://scripts/ui/progression_feedback_hud.gd")
const STRIP := preload("res://scripts/ui/party_strip.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const BOND := preload("res://scripts/creatures/bond_milestones.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const PLAYER := preload("res://scenes/player/player.tscn")
var failures: Array[String] = []
var presenter: CanvasLayer
var game: Node
var strip: Control
var world: Node3D
var assertions := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _frames(count: int) -> void:
	for frame in count:
		await process_frame


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var path := "res://shots/progression-feedback/" + name + ".png"
	DirAccess.make_dir_recursive_absolute("res://shots/progression-feedback")
	_check(root.get_texture().get_image().save_png(path) == OK, "real rendered capture " + name)


func _run() -> void:
	await process_frame
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i(1280, 800)
	game = root.get_node("Game")
	game.set_process(false)
	game.reset_for_new_game()
	world = Node3D.new()
	world.name = "ProgressionFeedbackFixture"
	root.add_child(world)
	current_scene = world
	var floor := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(80, 80)
	floor.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.3, 0.16)
	floor.material_override = material
	world.add_child(floor)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	light.light_energy = 1.3
	world.add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(5, 4, 7)
	world.add_child(camera)
	camera.look_at(Vector3(0, 1, 0))
	camera.current = true
	var player: CharacterBody3D = PLAYER.instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	var entries: Array = []
	for species_id: String in ["mudsnout", "bramblebun", "terrapup", "galecrest", "brooktail"]:
		var creature: RefCounted = SPECIES.spawn(species_id)
		if creature == null:
			continue
		game.party.add(creature)
		entries.append({"label": creature.label(), "level": creature.level, "hp_fraction": 1.0, "tint": Color(0.4, 0.8, 0.6)})
	var layer := CanvasLayer.new()
	world.add_child(layer)
	strip = STRIP.new()
	layer.add_child(strip)
	strip.set_rest_position(Vector2(64, 300))
	strip.update_from_party(entries, 0)
	strip.set_pinned(true)
	presenter = PRESENTER.new()
	presenter.configure(game)
	world.add_child(presenter)
	presenter.set_process(false)
	await _frames(3)
	var active: RefCounted = game.party.active()
	active.xp = active.xp_to_next(PROGRESSION.config()) - 1
	var combat := COMBAT.new()
	combat._party.assign(game.party.members())
	combat._active_index = 0
	combat._enemy = SPECIES.spawn("bramblebun")
	combat._award_victory() # Production reward source; fixture does not fake combat completion.
	combat.free()
	var events: Array = game.drain_progression_events()
	presenter.step(0.1, events, true)
	_check(not presenter._banner.visible, "moments remain queued while combat owns controls")
	_check(presenter.tick_count >= game.party.size() * 2, "combat XP and bond ticks include every party member")
	presenter.step(0.1, [], false)
	await _frames(12)
	_check(presenter.banner_count == 1, "combat result produces one shared level banner")
	_check(presenter._moment_label.text.contains(active.label()), "level banner names the creature")
	_check(presenter._moment_label.text.contains("ATK"), "level banner shows real stat changes")
	_check(presenter._progress_label.text.contains("EXP"), "level banner shows current XP progress")
	await _capture("level-up")
	active.battles_fought = 49
	BOND.credit_battle(active)
	BOND.credit_feed(active)
	BOND.credit_landmark_visit(active)
	active.resting = true
	_check(game.complete_creature_bed_rests() == 1, "real bed completion awards only assigned creature")
	presenter.step(0.1, game.drain_progression_events(), false)
	await _frames(12)
	_check(presenter.banner_count == 1, "two moments inside five seconds collapse without duplicate sound/banner")
	_check(presenter._moment_label.text.contains("Bond 1/5"), "bond milestone states the new node")
	_check(presenter._moment_label.text.contains("attack and defence"), "bond milestone explains the benefit")
	_check(presenter._moment_label.text.contains("applied automatically"), "milestone explains reward application")
	_check(presenter._moment_label.text.contains("Discover 2 more landmarks"), "milestone gives next ordered action")
	_check(BOND.all_progress_text(active).contains("1/10"), "Team counter formatter exposes feeding before its ordered turn")
	_check(int(strip._progression_overlays[0].state.bond) == 1, "production party row receives bond state")
	await _capture("bond-milestone")
	# Full-party stress: no non-active member lost and all text stays inside safe area.
	for creature: RefCounted in game.party.members():
		creature.set_level(int(creature.level) + 1, PROGRESSION.config())
	presenter.step(0.1, game.drain_progression_events(), false)
	await _frames(12)
	var rect: Rect2 = presenter._banner.get_global_rect()
	_check(rect.position.x >= 64 and rect.position.y >= 40 and rect.end.x <= 1216.1 and rect.end.y <= 760, "five-member moment remains inside 5 percent handheld safe area")
	_check(rect.end.y <= 330, "five simultaneous level-ups leave the central playfield clear")
	_check(not presenter._progress_label.text.contains("Brooktail"), "group footer does not misattribute team progress")
	_check(presenter._banner.mouse_filter == Control.MOUSE_FILTER_IGNORE, "banner never owns input focus")
	_check(presenter._moment_label.mouse_filter == Control.MOUSE_FILTER_IGNORE and presenter._moment_label.focus_mode == Control.FOCUS_NONE, "moment text cannot intercept pointer or controller input")
	for creature: RefCounted in game.party.members():
		_check(presenter._moment_label.text.contains(creature.label()), "grouped banner retains " + creature.label())
	await _capture("full-party")
	# Eligibility is still read from actual rules/inventory, not fabricated by UI.
	active.battles_fought = 50
	active.landmarks_visited_together = 3
	active.distance_m_together = 4000
	game.inventory.add("heartstone", 1)
	active.set_level(15, PROGRESSION.config())
	presenter.step(6.0, game.drain_progression_events(), false)
	await _frames(3)
	_check(presenter._moment_label.text.contains("Evolution ready"), "level-only transition exposes real evolution eligibility")
	var overlay: Control = strip._progression_overlays[4]
	overlay.update_state({}, {}, 0.9)
	await _frames(2)
	for content: Node in overlay.get_parent().get_children():
		if content != overlay and content is CanvasItem:
			_check(content.modulate.a == 1.0, "vacated party slot restores normal row content")
	world.queue_free()
	await _frames(3)
	for child: Node in root.get_children():
		for audio: Node in child.get_children():
			if audio is AudioStreamPlayer:
				audio.stop()
				audio.stream = null
	await create_timer(0.2).timeout
	print("PROGRESSION FEEDBACK %s: %d assertions; shared combat/candy/rest/bond feed, queued moments, five-member safe-area UI" % ["PASS" if failures.is_empty() else "FAIL", assertions])
	quit(0 if failures.is_empty() else 1)
