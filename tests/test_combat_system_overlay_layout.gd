extends "res://tests/test_case.gd"

## F42#2: the move cluster and ultimate ring sit inside the 1920×1080 canvas,
## in the lower-right corner (UX §3.2). A bare `position` write on the
## bottom-right-anchored cluster once put it off-screen at the top-left, and
## the in-fight capture showed no move slots or ultimate ring at all.
const RUNS_IN_INITIALIZED_TREE := true
const OVERLAY := preload("res://scripts/ui/combat_system_overlay.gd")


func test_move_cluster_is_on_screen_in_the_lower_right() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var canvas := Control.new()
	canvas.size = Vector2(1920, 1080)
	tree.root.add_child(canvas)
	var overlay: Control = OVERLAY.new()
	canvas.add_child(overlay)
	var moves: Control = overlay.get("_moves")
	var rect := Rect2(moves.position, moves.size)
	assert_eq(overlay.size, Vector2(1920, 1080), "overlay fills the canvas")
	assert_true(Rect2(Vector2.ZERO, overlay.size).encloses(rect), "cluster inside the canvas: %s" % str(rect))
	assert_true(rect.position.x > 960.0 and rect.position.y > 540.0, "cluster in the lower-right quadrant: %s" % str(rect))
	var caption: Label = overlay.get("_meter_caption")
	caption.text = "Ultimate · 100%\nReady · Tap RB"
	assert_true(caption.get_combined_minimum_size().y < 160.0, "the ultimate caption wraps by words, not letters: %s" % str(caption.get_combined_minimum_size()))
	overlay.call("_layout_commands")
	var lane: Control = overlay.get("_command_box")
	var lane_rect := Rect2(lane.position, lane.size)
	assert_true(Rect2(Vector2.ZERO, overlay.size).encloses(lane_rect) and lane_rect.position.y > 540.0,
		"command lane on screen, bottom half: %s" % str(lane_rect))
	canvas.queue_free()


## F42#2 judge r1: the command columns read in cost order (matching the bar's
## ticks) and a pad shows d-pad art, not "D-pad left" text.
func test_command_lane_orders_columns_by_cost_and_uses_dpad_art() -> void:
	var meter := preload("res://scripts/ui/tether_command_meter.gd")
	var cfg: Dictionary = preload("res://scripts/combat/tether_commands.gd").config()
	var costs: Array = meter._ids().map(func(id: String) -> float: return float(cfg.commands[id].cost))
	var sorted := costs.duplicate()
	sorted.sort()
	assert_eq(costs, sorted, "columns in cost order")
	assert_true(meter._button("D-pad left", true).contains("xbox_dpad_left.png"), "pad shows d-pad art")
	assert_eq(meter._button("D-pad left", false), "D-pad left", "keyboard keeps the name")


## The overlay's text has no backing panel: the subject fade keeps it at the
## readable foreground floor instead of ~0.3 (F42#2 judge: lane at ~25%).
func test_overlay_text_never_fades_below_the_foreground_floor() -> void:
	var floor_alpha := float(preload("res://scripts/combat/combat_math.gd").config().hud_subject_fade.foreground_alpha_floor)
	assert_true(floor_alpha >= 0.75, "configured floor is readable")
	var hud := FileAccess.get_file_as_string("res://scripts/ui/combat_hud.gd")
	assert_true(hud.contains("panel.modulate.a = maxf(level, foreground_floor)"), "overlay controls take the floor")


## Before the first acknowledged sync the real snapshot stays hidden (its
## security contract, test_move_commit_runtime), and the placeholder keeps the
## F42 layout with zero meters and no command available: never a pool value.
func test_presync_placeholder_carries_no_pool_value() -> void:
	var commands := preload("res://scripts/combat/tether_commands.gd")
	var previous: Dictionary = commands.config()
	commands._config = previous.duplicate(true)
	commands._config.feature_flags.ui_enabled = true
	var manager := preload("res://scripts/combat/combat_manager.gd").new()
	manager._moves = preload("res://scripts/creatures/move_db.gd").load_default()
	var first: RefCounted = preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")
	manager._party.assign([first])
	manager._active_index = 0
	manager._apply_move_resources({"creature_uid":first.uid, "ultimate_meter":36.0})
	manager.state = manager.State.ACTIVE
	var director := preload("res://scripts/combat/encounter_director.gd").new()
	director._deployment_identity = {1:{"character_id":"owner_a", "creature_uid":first.uid, "generation":1}}
	manager._encounter_link = director
	manager._encounter_id = "enc-now"
	manager._tether_command_view = {"encounter_id":"prior-encounter", "character_id":"owner_a", "meter":80.0}
	manager._initialize_wind()
	assert_eq(manager.new_system_combat_snapshot(), {"active":false}, "real snapshot still hidden for a prior view")
	var stand_in: Dictionary = manager.new_system_combat_placeholder()
	assert_true(stand_in.get("active") == true and stand_in.get("placeholder") == true)
	assert_eq(float(stand_in.ultimate_meter), 0.0, "no ultimate pool value")
	assert_eq(int(stand_in.commands.meter), 0, "no prior encounter's meter")
	assert_false(stand_in.commands.active, "no command offered")
	for slot: String in stand_in.slots: assert_false(stand_in.slots[slot].ready, slot + " not offered as ready")
	manager.state = manager.State.INACTIVE
	assert_eq(manager.new_system_combat_placeholder(), {"active":false}, "outside a fight nothing")
	commands._config = previous
	director.free()
	manager.free()


## The legacy caller (exploration and non-overlay HUD) still hides an inactive
## lane; only the F42 overlay keeps it visible (r2 capture: the lane lingered
## into exploration after the fight).
func test_inactive_lane_hides_unless_the_overlay_keeps_it() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var lane: Control = preload("res://scripts/ui/tether_command_meter.gd").new()
	tree.root.add_child(lane)
	lane.call("present", {"active": false, "meter": 0}, true)
	assert_false(lane.visible, "inactive snapshot outside the overlay: hidden")
	lane.call("present", {"active": false, "meter": 0}, true, true)
	assert_true(lane.visible, "the overlay keeps it up, muted")
	lane.queue_free()


## F42#2 reopened: an offline trainer duel has no tether deployment, so the
## real snapshot and the pre-sync stand-in were both hidden and the legacy grid
## drew, with a literal "[jump] Dodge". Every fight now keeps the F42 overlay.
func _offline_duel_manager() -> Node:
	var manager: Node = preload("res://scripts/combat/combat_manager.gd").new()
	manager.name = "OfflineDuelManager"
	manager._moves = preload("res://scripts/creatures/move_db.gd").load_default()
	var first: RefCounted = preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")
	manager._party.assign([first])
	manager._active_index = 0
	manager._encounter_kind = "trainer"
	manager.state = manager.State.ACTIVE
	manager._initialize_wind()
	return manager


func test_no_deployment_stand_in_uses_local_truth_and_offers_no_command() -> void:
	var manager := _offline_duel_manager()
	var uid := str(manager.active_creature().uid)
	var local: Dictionary = manager.new_system_combat_placeholder()
	assert_true(local.get("active") == true and local.get("placeholder") == true, "an offline duel keeps the F42 layout")
	assert_eq(local.slots.quick.ready, manager.quick_ready(), "offline readiness is the manager's own")
	assert_eq(float(local.ultimate_meter), 0.0, "begin() cleared the meter; nothing local refills it")
	assert_false(local.commands.active, "no command offered without a deployment")
	assert_eq(int(local.commands.meter), 0)
	# A link that never admitted this creature: still no pool value.
	manager._party_ultimate[uid] = 64.0
	var director := preload("res://scripts/combat/encounter_director.gd").new()
	manager._encounter_link = director
	var linked: Dictionary = manager.new_system_combat_placeholder()
	assert_true(linked.get("active") == true, "an unadmitted link keeps the layout too")
	assert_eq(float(linked.ultimate_meter), 0.0, "no host pool value without an admitted deployment")
	assert_eq(manager.new_system_combat_snapshot(), {"active":false}, "the real snapshot's contract is unchanged")
	director.free()
	manager.free()


func test_offline_trainer_duel_draws_the_overlay_not_the_legacy_grid() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var holder := Node.new()
	tree.root.add_child(holder)
	var manager := _offline_duel_manager()
	holder.add_child(manager)
	var hud: Node = preload("res://scenes/combat/combat_hud.tscn").instantiate()
	hud.set("manager_path", NodePath("../OfflineDuelManager"))
	holder.add_child(hud)
	for _i in 3: hud._process(1.0 / 60.0)
	var overlay: Control = hud.get("_system_overlay")
	assert_true(is_instance_valid(overlay) and overlay.visible, "the F42 overlay draws in an offline duel")
	assert_false((hud.get("_grid_panel") as Control).visible, "the legacy grid stays hidden")
	for node: Node in hud.find_children("*", "", true, false):
		var text := ""
		if node is Label: text = (node as Label).text
		elif node is RichTextLabel: text = (node as RichTextLabel).text
		if node is CanvasItem and (node as CanvasItem).is_visible_in_tree():
			assert_false(text.contains("[jump]"), "no raw jump token: %s" % text)
	holder.queue_free()
