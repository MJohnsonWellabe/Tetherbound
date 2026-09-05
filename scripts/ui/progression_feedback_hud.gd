extends CanvasLayer

## One passive exploration/combat presenter. Game queue is drained here only;
## recent-event cursors remain available for CombatHUD and companion reactions.
const FEED := preload("res://scripts/creatures/progression_feed.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const BOND := preload("res://scripts/creatures/bond_milestones.gd")
const AUDIO := preload("res://scripts/audio/audio_manager.gd")
var _game: Node
var _feed: RefCounted
var _banner: PanelContainer
var _moment_label: RichTextLabel
var _progress_label: Label
var _moments: Array[Dictionary] = []
var _shown: Array[Dictionary] = []
var _left := 0.0
var _since_moment := INF
var banner_count := 0
var tick_count := 0
var _cfg: Dictionary
var _reward_receipt := ""
var _world_presentation_mode := "exploration"


func set_world_presentation_mode(mode: String) -> void:
	_world_presentation_mode = mode


func configure(game_state: Node) -> void:
	_game = game_state
	_feed = game_state.get("progression_feed")


func _ready() -> void:
	if not get_tree().get_nodes_in_group("progression_feedback_presenter").is_empty():
		queue_free()
		return
	add_to_group("progression_feedback_presenter")
	layer = 18
	_cfg = FEED.config()
	if _game == null:
		configure(get_node("/root/Game"))
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_banner = PanelContainer.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.055, 0.12, 0.15, 0.97)
	box.border_color = Color(0.86, 0.72, 0.36)
	box.set_border_width_all(2)
	box.set_corner_radius_all(9)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	_banner.add_theme_stylebox_override("panel", box)
	root.add_child(_banner)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(column)
	_moment_label = RichTextLabel.new()
	_moment_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment_label.focus_mode = Control.FOCUS_NONE
	_moment_label.bbcode_enabled = true
	_moment_label.fit_content = true
	_moment_label.scroll_active = false
	_moment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_moment_label.add_theme_font_size_override("normal_font_size", int(_cfg.detail_font_size))
	_moment_label.add_theme_font_size_override("bold_font_size", int(_cfg.detail_font_size))
	_moment_label.add_theme_color_override("default_color", Color(1, 0.86, 0.51))
	column.add_child(_moment_label)
	_progress_label = Label.new()
	_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_label.add_theme_font_size_override("font_size", int(_cfg.detail_font_size))
	_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_progress_label)
	_banner.hide()
	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	var viewport := get_viewport().get_visible_rect().size
	# The production canvas is authored at 1920 wide and stretches to handheld.
	# Feedback sizes are physical readable pixels, not shrinking canvas units.
	_moment_label.add_theme_font_size_override("normal_font_size", _font_px(int(_cfg.detail_font_size)))
	_moment_label.add_theme_font_size_override("bold_font_size", _font_px(int(_cfg.detail_font_size)))
	_progress_label.add_theme_font_size_override("font_size", _font_px(int(_cfg.detail_font_size)))
	var inset := float(_cfg.safe_area_inset)
	_banner.position = Vector2(viewport.x * 0.36, viewport.y * inset)
	_banner.size = Vector2(viewport.x * (1.0 - 0.36 - inset), 0)
	_banner.custom_minimum_size.x = viewport.x * (1.0 - 0.36 - inset)
	_fit_banner.call_deferred()


func _font_px(pixels: int) -> int:
	var scale := get_viewport().get_screen_transform().get_scale().x
	return roundi(pixels / maxf(0.1, scale))


func _readable_bbcode(value: String) -> String:
	return value.replace("[font_size=%d]" % int(_cfg.moment_font_size), "[font_size=%d]" % _font_px(int(_cfg.moment_font_size))).replace(
		"[font_size=18]", "[font_size=%d]" % _font_px(18))


func _fit_banner() -> void:
	# Autowrapped labels resolve their minimum height after width propagation.
	# Fit again after containers settle, not against their one-character width.
	await get_tree().process_frame
	if is_instance_valid(_banner):
		_banner.reset_size()


func _combat_active() -> bool:
	var scene := get_tree().current_scene
	var manager := scene.get_node_or_null("CombatManager") if scene != null else null
	var director := scene.get_node_or_null("EncounterDirector") if scene != null else null
	return (manager != null and int(manager.get("state")) != 0) or (director != null and director.has_method("trainer_battle_active") and bool(director.call("trainer_battle_active")))


func moment_visible() -> bool:
	return _banner != null and _banner.visible and _left > 0


func _process(delta: float) -> void:
	if _game == null:
		return
	var current_feed: RefCounted = _game.get("progression_feed")
	if current_feed != _feed:
		_feed = current_feed
		_moments.clear()
		_shown.clear()
		_left = 0.0
		_since_moment = INF
		_reward_receipt = ""
	var events: Array = _feed.call("drain")
	step(delta, events, _combat_active())


## Behaviour-test seam: same production queue handling and passive widgets.
func step(delta: float, events: Array, fighting: bool) -> void:
	_since_moment += delta
	_left = maxf(0, _left - delta)
	var ticks: Dictionary = {}
	for event: Dictionary in events:
		match str(event.kind):
			"reward_summary":
				_reward_receipt = str(event.receipt)
			"level_up", "bond_milestone":
				_moments.append(event)
			"xp_gained":
				var id := int(event.instance_id)
				if not ticks.has(id):
					ticks[id] = {}
				ticks[id]["xp"] = int(ticks[id].get("xp", 0)) + int(event.amount)
				tick_count += 1
			"bond_credit":
				var action := "route" if str(event.get("source", "")) == "fly_route" else str(_cfg.task_labels.get(event.task_id, "bond"))
				var id := int(event.instance_id)
				if not ticks.has(id):
					ticks[id] = {}
				ticks[id]["bond_reason"] = {"won": "victory", "fed": "meal", "rested": "rest", "discovered": "discovery", "travelled": "travel"}.get(action, action)
				tick_count += 1
	_update_strips(ticks)
	if fighting:
		_banner.hide()
		return
	if not _reward_receipt.is_empty() and _moments.is_empty():
		_show_reward_receipt()
		return
	if not _moments.is_empty():
		if _since_moment < float(_cfg.moment_cooldown_seconds):
			_shown.append_array(_moments)
			_moments.clear()
			_show_moments(false)
		else:
			_shown = _moments.duplicate()
			_moments.clear()
			_since_moment = 0.0
			_show_moments(true)
	elif _left <= 0:
		_banner.hide()
	else:
		_banner.show()


func _update_strips(ticks: Dictionary) -> void:
	var entries: Array = []
	var party: RefCounted = _game.get("party") if _game != null else null
	if party != null:
		for creature: RefCounted in party.call("members"):
			var next: int = creature.call("xp_to_next", PROGRESSION.config())
			var ordinary_fight := PROGRESSION.xp_award_for(int(creature.get("level")), PROGRESSION.config())
			var near := next - int(creature.get("xp")) <= maxi(int(_cfg.xp_near_threshold), int(ordinary_fight * float(_cfg.xp_near_fights)))
			var bond_near := false
			var task := BOND.current(creature, BOND.config())
			if not task.is_empty():
				bond_near = float(task.target) - float(creature.get(str(task.task))) <= float(_cfg.near_thresholds.get(task.task, 0))
			entries.append({"instance_id": creature.get_instance_id(), "xp": creature.get("xp"), "xp_to_next": next,
				"label": creature.call("label"), "level": creature.get("level"), "hp_fraction": creature.call("hp_fraction"),
				"active": creature == party.call("active"), "fainted": creature.get("fainted"), "resting": creature.get("resting"),
				"bond": creature.call("bond_nodes"), "near": near, "bond_near": bond_near, "pulse_seconds": _cfg.near_pulse_seconds})
	if is_inside_tree():
		for strip: Node in get_tree().get_nodes_in_group("progression_party_strips"):
			strip.call("update_progression", entries, ticks, float(_cfg.tick_seconds))


func _show_moments(play_sound: bool) -> void:
	var lines: PackedStringArray = []
	# One compact block per affected creature, even if several already-complete
	# ordered milestones unlock together. Never let five members overflow safety.
	var by_creature: Dictionary = {}
	for event: Dictionary in _shown:
		var id := int(event.instance_id)
		if not by_creature.has(id):
			by_creature[id] = {"id": id, "name": event.display_name, "level": 0, "bond": 0, "bond_gains": 0, "hp": 0.0, "attack": 0.0, "defence": 0.0, "trait": false, "evolution": false}
		var summary: Dictionary = by_creature[id]
		if str(event.kind) == "level_up":
			summary.level = int(event.new_level)
			for stat: String in ["hp", "attack", "defence"]:
				summary[stat] += float(event.get("stat_deltas", {}).get(stat, 0))
		else:
			summary.bond = maxi(int(summary.bond), int(event.node_index))
			summary.bond_gains += 1
		summary.trait = bool(summary.trait) or bool(event.get("trait_unlocked", false))
		summary.evolution = bool(summary.evolution) or bool(event.get("evolution_ready", false))
	var multiple := by_creature.size() > 1
	if multiple:
		lines.append("[font_size=%d][b]Your team grew stronger[/b][/font_size]" % int(_cfg.moment_font_size))
	for summary: Dictionary in by_creature.values():
		var creature := _member(int(summary.id))
		var xp := int(creature.get("xp")) if creature != null else 0
		var next := int(creature.call("xp_to_next", PROGRESSION.config())) if creature != null else 1
		var identity := str(summary.name).replace("[", "[lb]")
		var stats := "HP +%d / ATK +%d / DEF +%d" % [int(round(summary.hp)), int(round(summary.attack)), int(round(summary.defence))]
		if multiple:
			var row := "[b]%s[/b] · Bond strengthened" % identity
			if int(summary.level) > 0:
				row = "[b]%s[/b]  Lv %d · %s · EXP %d/%d" % [identity, int(summary.level), stats, xp, next]
			if summary.evolution and int(summary.bond) == 0:
				row += " · Evolution ready"
			lines.append("[font_size=18][color=#e5edec]" + row + "[/color][/font_size]")
		else:
			lines.append("[font_size=%d][b]%s%s[/b][/font_size]" % [int(_cfg.moment_font_size), identity, " reached Lv %d" % int(summary.level) if int(summary.level) > 0 else " · Bond strengthened"])
			if int(summary.level) > 0:
				lines.append("[font_size=18][color=#e5edec]Level gains: " + stats + "[/color][/font_size]")
				if summary.evolution and int(summary.bond) == 0:
					lines.append("[font_size=18][color=#bdebd4]Evolution ready · Open Team to choose[/color][/font_size]")
		if int(summary.bond) > 0:
			var bonus := int(round(int(summary.bond_gains) * float(PROGRESSION.config().bond.effects_per_node.attack_scale) * 100))
			var reward := "%sBond %d/5 · +%d%% attack and defence applied automatically" % [identity + " · " if multiple else "", int(summary.bond), bonus]
			if summary.trait:
				reward += " · Second trait revealed"
			if summary.evolution:
				reward += " · Evolution ready"
			lines.append("[font_size=18][color=#bdebd4]" + reward + "[/color][/font_size]")
			if creature != null:
				lines.append("[font_size=18][color=#e5edec]Next: " + BOND.next_action_text(creature) + ".[/color][/font_size]")
	_moment_label.text = _readable_bbcode("\n".join(lines))
	var latest: Dictionary = _shown.back()
	var xp: Dictionary = _feed.call("latest_for", int(latest.instance_id), "xp_gained")
	_progress_label.text = "All gains applied. Team shows detailed stats and bond tasks." if multiple else ("%s · EXP %d / %d to next level" % [latest.display_name, int(xp.get("xp", 0)), int(xp.get("xp_to_next", 0))] if not xp.is_empty() else "Bond rewards are automatic. Team shows every task.")
	if not _reward_receipt.is_empty():
		_progress_label.text = _reward_receipt
		if _world_presentation_mode == "relays":
			_progress_label.text = "Captain encounter complete. " + _reward_receipt + "\nNext: disable the three exposed relays."
		_reward_receipt = ""
	_left = float(_cfg.moment_seconds)
	_banner.show()
	_layout()
	if play_sound:
		banner_count += 1
		var audio_config: Dictionary = AUDIO.config()
		var cue := str(_cfg.level_sound if str(latest.kind) == "level_up" else _cfg.bond_sound)
		var path := str(audio_config.get("progression_cues", {}).get(cue, ""))
		if not path.is_empty():
			AUDIO.play_file(path, cue, "UI")
		var tween := create_tween()
		_banner.modulate.a = 0.0
		tween.tween_property(_banner, "modulate:a", 1.0, 0.2)


func _member(instance_id: int) -> RefCounted:
	var party: RefCounted = _game.get("party") if _game != null else null
	if party != null:
		for creature: RefCounted in party.call("members"):
			if creature.get_instance_id() == instance_id:
				return creature
	return null


func _show_reward_receipt() -> void:
	var title := "Victory rewards"
	if _reward_receipt.contains("'s reward:"):
		title = _reward_receipt.get_slice("'s reward:", 0) + " defeated"
	_moment_label.text = _readable_bbcode("[font_size=%d][b]%s[/b][/font_size]\n[color=#e5edec]%s[/color]" % [int(_cfg.moment_font_size), title.replace("[","[lb]"), _reward_receipt.replace("[","[lb]")])
	_reward_receipt = ""
	var member: RefCounted = _game.get("party").call("active")
	var earned: Dictionary = _feed.call("latest_for",member.get_instance_id(),"xp_gained") if member != null else {}
	_progress_label.text = "%s · +%d XP · EXP %d/%d" % [member.call("label"),int(earned.amount),int(earned.xp),int(earned.xp_to_next)] if not earned.is_empty() else "Rewards added to your satchel."
	if _world_presentation_mode == "relays":
		_progress_label.text += "\nNext: disable the three exposed relays."
	_banner.modulate.a = 1.0
	_banner.show()
	_left = float(_cfg.moment_seconds)
	_layout()
