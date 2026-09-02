extends SceneTree

## OWNER-0902-REST-VISIBILITY, half 2. Owner playtest 2026-09-02, finding 7,
## verbatim: "No way to tell when a creature finishes resting." Wants a
## rest-progress/time-remaining indicator, "in the menu or elsewhere."
##
## Renders the two real surfaces that now carry it, at the real ROG Ally
## handheld resolution (1280x800), with a creature genuinely mid-rest in a
## real placed creature_bed (real catalogue+placer path, same as
## tools/_probe_camp_split.gd and tools/gate_f/probe_rest_cycle_e2e.gd) so
## the numbers on screen are the real system's, not a hand-typed stand-in:
##
##   rest_bed_panel   - standing at the bed, the rest panel open
##                       (creature_bed_panel.gd), showing "Resting -- HP
##                       n/m . 1:23 left" on the resting creature's row.
##   rest_team_menu   - the pause menu's Creatures tab (tab_creatures.gd),
##                       "the menu" the owner explicitly named as an
##                       acceptable home, showing the same countdown on the
##                       roster row without needing to be anywhere near the
##                       bed.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/gate_f/capture_rest_progress_indicator.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240
const POSE_FRAMES := 8

var _world: Node
var _game: Node
var _player: CharacterBody3D
var _placer: Node
var _failures: Array[String] = []
var _written: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_placer = get_first_node_in_group("build_placer")
	if _game == null or _player == null or _placer == null:
		push_error("Meadows did not stand up Game, Player, and BuildPlacer")
		quit(1)
		return

	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")
	_game.set("free_build", false)
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "wood", 30)
	inventory.call("add", "stone", 30)
	inventory.call("add", "fiber", 30)

	await _teleport_to(Vector3(90.0, 0.0, 90.0))
	var creature_bed := await _place("creature_bed", Vector3(90.0, 0.0, 90.0))
	if creature_bed == null:
		_report()
		return

	var party: RefCounted = _game.get("party")
	var creature: RefCounted = party.call("at", 0)
	if creature == null:
		creature = _game.call("make_creature", "terrapup")
		party.call("add", creature)
	# Mid-recovery, not freshly fainted and not full -- a real, non-trivial
	# countdown for the frame to show, the same state a player checking
	# partway through a rest would actually see.
	creature.set("max_hp", 120.0)
	creature.set("hp", 40.0)
	creature.set("fainted", false)
	creature.set("resting", true)
	# `_place()`'s real catalogue+placer path already assigned this bed its
	# real `placed_buildings` index (`build_placer.gd`'s own `set_build_index`
	# call) -- reused here rather than re-deriving it, so `occupant_index()`
	# on the bed and `rest_bed_index` on the creature genuinely agree the way
	# a real `assign_creature()` call would leave them.
	creature.set("rest_bed_index", int(creature_bed.call("build_index")))

	await _teleport_to(creature_bed.global_position + Vector3(0.0, 0.0, 1.0))
	var bed_prompt := creature_bed.get_node_or_null(^"Interactable")
	if bed_prompt == null:
		_failures.append("placed creature_bed has no Interactable prompt")
		_report()
		return
	bed_prompt.emit_signal("activated")
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("rest_bed_panel")

	var panel := _find_by_script(root, "creature_bed_panel.gd")
	if panel != null and bool(panel.call("is_open")):
		panel.call("close")
	for i in POSE_FRAMES:
		await process_frame

	var menu: Node = _game.call("menu")
	if menu == null:
		_failures.append("autoload did not stand up the menu")
		_report()
		return
	menu.call("open", "creatures")
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("rest_team_menu")

	_report()


func _place(id: String, at: Vector3) -> Node3D:
	await _teleport_to(at)
	_game.set("pending_build", id)
	for i in 20:
		await physics_frame
	if not bool(_placer.get("_ghost_ok")):
		_failures.append("'%s' ghost is red at %s (reason: %s)" % [id, at, str(_placer.get("_ghost_reason"))])
		return null
	var before: Array[Node] = get_nodes_in_group("placed_building")
	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 15:
		await physics_frame
	_game.set("pending_build", "")
	for i in 5:
		await physics_frame
	for node: Node in get_nodes_in_group("placed_building"):
		if before.has(node):
			continue
		if str(node.get_meta("building_id", "")) == id:
			return node as Node3D
	_failures.append("arming and pressing build_place for '%s' planted nothing" % id)
	return null


func _teleport_to(at: Vector3) -> void:
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else 0.0
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 12:
		await physics_frame


func _find_by_script(node: Node, suffix: String) -> Node:
	var script: Script = node.get_script()
	if script != null and str(script.resource_path).ends_with(suffix):
		return node
	for child in node.get_children():
		var found := _find_by_script(child, suffix)
		if found != null:
			return found
	return null


func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		_failures.append("%s: save_png failed (%d)" % [name, error])
		return
	_written.append(path)
	print("  %-16s -> %s" % [name, path])


func _report() -> void:
	print("")
	print("%d frames -> %s" % [_written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
