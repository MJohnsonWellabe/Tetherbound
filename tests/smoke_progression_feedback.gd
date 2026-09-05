extends SceneTree

## PROGRESSION-VISIBLE (docs/prompts/73 §4): does the player SEE progression
## happen, on the real surfaces, from the real actions?
##
##   godot --headless --path . --script tests/smoke_progression_feedback.gd
##
## Boots the Meadows, then drives four real bond actions and two level-ups and
## reads the presenters back -- never the counters alone:
##
##   1. A wild fight won by real stick and button input (the same drive
##      `smoke_combat.gd` uses): the feed carries `xp_gained` and
##      `bond_credit(battles_fought)` for the ally, and the party strip's row
##      TICKED for it (`tick_count`, `last_tick_label`).
##   2. A meal through the Satchel screen's own target picker on pad input:
##      `bond_credit(feeds_together)`, strip tick "+bond · fed".
##   3. A landmark discovered by standing inside its own `discover_radius`
##      until `Game._process`'s discovery poll credits the party.
##   4. A night in a placed creature bed, assigned through the bed panel and
##      completed by the bedroll's own Rest interaction (the path
##      `smoke_gate_a_rest_torch.gd` proved): `bond_credit(rest_nights_together)`.
##   5. A level-up pushed DURING the fight (to the bench creature) stays queued
##      -- the banner must never cover combat controls -- and flushes at the
##      result beat; a level-up outside a fight shows the banner at once, at
##      1280x800, inside the 5% safe area, naming the creature, the level and
##      what changed. Two level-ups within the collapse window share one plate.
##   6. The Team screen shows every bond task with DONE/NEXT and the xp-to-next
##      line.
##
## Never `--headless` together with a rendering driver.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const FEED := preload("res://scripts/creatures/progression_feed.gd")
const BOND := preload("res://scripts/creatures/bond_milestones.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")

const SETTLE_FRAMES := 240
const FIGHT_FRAME_LIMIT := 2500
const WINDOW := Vector2i(1280, 800)
const CANVAS := Vector2i(1920, 1200)

var _failures: Array[String] = []
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _hud: Node = null
var _strip: Control = null
var _arbiter: Node = null
var _wild: Node3D = null
var _ally: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	# Headless has no real window, so the Ally-shaped canvas is asked for
	# directly: 1280x800 under project.godot's canvas_items/expand stretch is a
	# 1920x1200 canvas, which is what every HUD offset is laid out against.
	root.content_scale_size = CANVAS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_hud = _world.get_node_or_null(^"PlaygroundHUD")
	_arbiter = get_first_node_in_group("interaction_arbiter")
	if _game == null or _player == null or _rig == null or _manager == null or _director == null \
			or _hud == null or _arbiter == null:
		_fail("Meadows did not stand up Game, Player, CameraRig, CombatManager, EncounterDirector, PlaygroundHUD and the arbiter")
		_report()
		return
	_strip = _hud.get("_party_strip") as Control
	if _strip == null or not _strip.has_method("tick_count"):
		_fail("the world HUD has no party strip with tick evidence")
		_report()
		return
	var sequence := _world.find_child("SequenceDirector", true, false)
	if sequence != null and sequence.has_method("_set_beat"):
		sequence.call("_set_beat", "free_play")

	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", "ripplet")
	var party: RefCounted = _game.get("party")
	# The real flow seats the starter in the party the moment it is adopted
	# (`sequence_director.gd::_adopt` -> `party.add`); a harness boot that
	# skipped the opening has the director's ally but an empty belt, so seat
	# it the same way before adding one distinctly-named bench creature.
	var ally_instance: RefCounted = _director.call("ally_instance")
	if ally_instance != null and int(party.call("size")) == 0:
		party.call("add", ally_instance)
		party.call("set_active", 0)
	if int(party.call("size")) < 2:
		var bench: RefCounted = _game.call("make_creature", "bramblebun", "Bench")
		if bench == null or not bool(party.call("add", bench)):
			_fail("could not add a bench creature to the party (size %d)" % int(party.call("size")))
	for i in 30:
		await physics_frame
	print("party: %d creatures; active %d" % [int(party.call("size")), int(party.call("active_index"))])
	if int(party.call("size")) < 2:
		_report()
		return

	await _a_won_fight_ticks_xp_and_bond(party)
	await _a_meal_through_the_satchel_ticks_bond(party)
	await _a_landmark_discovery_credits_the_party(party)
	await _a_night_in_a_bed_credits_rest(party)
	await _a_level_up_outside_a_fight_is_a_banner_inside_the_safe_area(party)
	await _two_moments_collapse_into_one_plate(party)
	await _the_team_screen_answers_both_questions(party)
	_report()


# --- 1. the fight ------------------------------------------------------------------

func _a_won_fight_ticks_xp_and_bond(party: RefCounted) -> void:
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	_player.global_position = start
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame
	_wild = _director.call("wild_creature") as Node3D
	if _wild == null:
		_fail("the encounter director never spawned a wild creature")
		return
	var active_index := int(party.call("active_index"))
	var ally: RefCounted = party.call("at", active_index)
	var bench_index := 1 if active_index == 0 else 0
	var bench: RefCounted = party.call("at", bench_index)
	var battles_before := int(ally.get("battles_fought"))
	var ticks_before := int(_strip.call("tick_count", active_index))
	var moments_before := int(_hud.call("moments_shown"))
	var cursor := FEED.latest_seq()

	# Walk up and engage on real input.
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for i in 1800:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.6:
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 30:
		await physics_frame
	if not bool(_manager.call("is_fighting")):
		_fail("could not enter combat; the fight half of this smoke did not run")
		return
	_ally = _director.call("ally_body") as Node3D

	# 5a. A Moment during the fight must queue, never show over the controls.
	var cfg: Dictionary = PROGRESSION.config()
	bench.call("gain_xp", int(bench.call("xp_to_next", cfg)) - int(bench.get("xp")), cfg)
	for i in 12:
		await physics_frame
	if bool(_hud.call("moment_banner_visible")):
		_fail("a level-up banner showed DURING a fight; it must queue behind the result beat")
	elif int(_hud.call("moments_queued")) < 1:
		_fail("the bench creature's mid-fight level-up was not queued for the result beat")
	else:
		print("  ok    a mid-fight level-up is held (queued %d, banner hidden)" % int(_hud.call("moments_queued")))

	# Fight to a finish on the buttons.
	var frames := 0
	while bool(_manager.call("is_fighting")) and frames < FIGHT_FRAME_LIMIT:
		var creature: RefCounted = _manager.call("active_creature")
		if creature != null and creature.hp_fraction() < 0.4:
			creature.hp = creature.max_hp
		if _ally == null or _wild == null or not is_instance_valid(_wild):
			await physics_frame
			frames += 1
			continue
		var to := _wild.global_position - _ally.global_position
		to.y = 0.0
		_rig.set("yaw", atan2(-to.x, -to.z))
		if to.length() > 2.0:
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("charged_ready")):
			await _press("combat_charged")
		elif bool(_manager.call("quick_ready")):
			await _press("combat_quick")
		else:
			await physics_frame
		frames += 1
	if frames >= FIGHT_FRAME_LIMIT:
		_fail("the fight never resolved after %d action frames" % FIGHT_FRAME_LIMIT)
		return
	print("fight resolved after %d frames; outcome '%s'" % [frames, str(_manager.call("outcome"))])
	for i in 30:
		await physics_frame
	for raw: Variant in FEED.peek_since(cursor):
		var e := raw as Dictionary
		if str(e.get("kind", "")) == "level_up":
			print("  level_up seq %d: %s %d -> %d (%s)" % [int(e.get("seq", 0)), str(e.get("name", "")),
				int(e.get("old_level", 0)), int(e.get("new_level", 0)), str(e.get("source", ""))])

	if int(ally.get("battles_fought")) != battles_before + 1:
		_fail("the win did not credit battles_fought (%d -> %d)" % [battles_before, int(ally.get("battles_fought"))])
	var kinds := _kinds_for(ally, cursor)
	if not kinds.has("xp_gained"):
		_fail("no xp_gained reached the feed for the ally after a won fight")
	if not kinds.has("bond_credit"):
		_fail("no bond_credit reached the feed for the ally after a won fight")
	var ticks := int(_strip.call("tick_count", active_index)) - ticks_before
	var last := str(_strip.call("last_tick_label", active_index))
	if ticks < 2:
		_fail("the party strip ticked %d time(s) for the win; expected the xp tick and the bond tick" % ticks)
	elif last != "+bond · won":
		_fail("the strip's last tick for the win reads '%s', expected '+bond · won'" % last)
	else:
		print("  ok    the strip ticked %d times for the win; last '%s'" % [ticks, last])
	if str(_strip.call("bond_label_text", active_index)).is_empty():
		_fail("the strip row shows no bond pip")
	if float(_strip.call("xp_bar_value", active_index)) <= 0.0 and int(ally.get("xp")) > 0:
		_fail("the strip's xp sliver is empty although the ally banked xp")

	# 5b. The queued moment flushed at the result beat.
	for i in 90:
		if int(_hud.call("moments_shown")) > moments_before:
			break
		await physics_frame
	if int(_hud.call("moments_shown")) <= moments_before:
		_fail("the mid-fight level-up never flushed to the banner after the fight ended")
	else:
		var last_moment: Dictionary = _hud.call("last_moment")
		print("  ok    the queued level-up flushed at the result beat: '%s'" % str(_hud.call("moment_banner_text")))
		if str(last_moment.get("name", "")) != str(bench.call("label")):
			_fail("the flushed banner named '%s', not the bench creature that levelled" % str(last_moment.get("name", "")))
	# Let it age out before the next beat.
	for i in 240:
		if not bool(_hud.call("moment_banner_visible")):
			break
		await physics_frame


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await physics_frame


# --- 2. the meal --------------------------------------------------------------------

func _a_meal_through_the_satchel_ticks_bond(party: RefCounted) -> void:
	var index := int(party.call("active_index"))
	var creature: RefCounted = party.call("at", index)
	creature.set("nourishment", 40.0)
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "berries", 3)
	var slot := int(inventory.call("find_slot", "berries"))
	if slot < 0:
		_fail("berries never reached a satchel slot")
		return
	var feeds_before := int(creature.get("feeds_together"))
	var ticks_before := int(_strip.call("tick_count", index))
	var cursor := FEED.latest_seq()

	var menu: CanvasLayer = _game.call("menu")
	menu.call("open", "backpack")
	for i in 8:
		await process_frame
	var body: Node = _tab_body(menu, "backpack")
	if body == null:
		_fail("could not open the Satchel tab")
		return
	var buttons: Array = body.get("_buttons")
	if slot >= buttons.size():
		_fail("berries landed in slot %d, past the rendered grid" % slot)
		menu.call("close")
		return
	(buttons[slot] as Button).grab_focus()
	await process_frame
	await _tap("interact")
	if int(body.get("_targeting")) < 0:
		_fail("Use on Berries opened no target picker")
		menu.call("close")
		return
	var rows: Array = body.get("_target_rows")
	if index >= rows.size():
		_fail("the picker has no row for party slot %d" % index)
		menu.call("close")
		return
	var row := rows[index] as Button
	if row.disabled:
		_fail("the hungry creature's row is disabled: '%s'" % row.text)
		menu.call("close")
		return
	row.grab_focus()
	await process_frame
	await _tap("menu_confirm")
	for i in 6:
		await process_frame
	menu.call("close")
	for i in 30:
		await process_frame

	if int(creature.get("feeds_together")) != feeds_before + 1:
		_fail("feeding through the Satchel did not credit feeds_together (%d -> %d)" % [
			feeds_before, int(creature.get("feeds_together"))])
		return
	var kinds := _kinds_for(creature, cursor)
	if not kinds.has("bond_credit"):
		_fail("no bond_credit reached the feed for the meal")
	var ticks := int(_strip.call("tick_count", index)) - ticks_before
	var last := str(_strip.call("last_tick_label", index))
	if ticks < 1 or last != "+bond · fed":
		_fail("the strip did not tick '+bond · fed' for the meal (ticks %d, last '%s')" % [ticks, last])
	else:
		print("  ok    a Satchel meal ticked the strip: '%s'" % last)


# --- 3. the landmark -----------------------------------------------------------------

func _a_landmark_discovery_credits_the_party(party: RefCounted) -> void:
	var map: RefCounted = _game.get("map")
	var target: Dictionary = {}
	for entry: Variant in map.call("landmarks"):
		var l := entry as Dictionary
		if bool(l.get("dynamic", false)) or bool(l.get("discovered", false)):
			continue
		target = l
		break
	if target.is_empty():
		_fail("no undiscovered authored landmark to walk into")
		return
	var index := int(party.call("active_index"))
	var creature: RefCounted = party.call("at", index)
	var before := int(creature.get("landmarks_visited_together"))
	var ticks_before := int(_strip.call("tick_count", index))
	var cursor := FEED.latest_seq()
	var pos: Vector2 = target.get("position", Vector2.ZERO)
	await _teleport_to(Vector3(pos.x, 0.0, pos.y))
	# Two discovery polls (0.5s each) plus slack.
	for i in 90:
		await physics_frame
	if int(creature.get("landmarks_visited_together")) != before + 1:
		_fail("standing at landmark '%s' did not credit landmarks_visited_together (%d -> %d)" % [
			str(target.get("id", "")), before, int(creature.get("landmarks_visited_together"))])
		return
	var kinds := _kinds_for(creature, cursor)
	if not kinds.has("bond_credit"):
		_fail("no bond_credit reached the feed for the landmark")
	var last := str(_strip.call("last_tick_label", index))
	if int(_strip.call("tick_count", index)) <= ticks_before or last != "+bond · discovered":
		_fail("the strip did not tick '+bond · discovered' for the landmark (last '%s')" % last)
	else:
		print("  ok    discovering '%s' ticked the strip: '%s'" % [str(target.get("id", "")), last])


# --- 4. the night ----------------------------------------------------------------------

func _a_night_in_a_bed_credits_rest(party: RefCounted) -> void:
	var index := int(party.call("active_index"))
	var creature: RefCounted = party.call("at", index)
	# The active creature is out in the world; rest the BENCH creature (bed
	# assignment refuses a deployed body, see smoke_tournament_bracket.gd).
	var bench_index := 1 if index == 0 else 0
	var bench: RefCounted = party.call("at", bench_index)
	if bench == null:
		_fail("no bench creature to rest")
		return
	_game.set("free_build", true)
	var bed := await _place_fixture("creature_bed", Vector3(70.0, 0.0, 70.0))
	var tent := await _place_fixture("tent", Vector3(100.0, 0.0, 80.0))
	var bedroll := await _place_fixture("bedroll", Vector3(100.0, 0.0, 80.0))
	if bed == null or tent == null or bedroll == null:
		return
	var nights_before := int(bench.get("rest_nights_together"))
	var ticks_before := int(_strip.call("tick_count", bench_index))
	var cursor := FEED.latest_seq()

	var prompt := bed.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("placed creature bed has no interaction prompt")
		return
	await _teleport_near(prompt)
	if not await _wait_provider(prompt):
		_fail("creature-bed prompt never won arbitration")
		return
	await _tap("interact")
	var panel := await _wait_open_script("creature_bed_panel.gd")
	if panel == null:
		_fail("interact did not open the creature-bed panel")
		return
	# The panel lists the party in order; move focus to the bench row and accept.
	var rows: Variant = panel.get("_rows")
	if rows is Array and bench_index < (rows as Array).size() and (rows as Array)[bench_index] is Control:
		((rows as Array)[bench_index] as Control).grab_focus()
		await process_frame
	await _tap("ui_accept")
	if not bool(bench.get("resting")):
		# Fall back to whatever row the panel accepted, as long as someone rests.
		var anyone := false
		for i in int(party.call("size")):
			if bool((party.call("at", i) as RefCounted).get("resting")):
				anyone = true
				bench_index = i
				bench = party.call("at", i)
		if not anyone:
			_fail("the bed panel's accept assigned nobody to the bed")
			await _tap("menu_cancel")
			return
		nights_before = int(bench.get("rest_nights_together"))
		ticks_before = int(_strip.call("tick_count", bench_index))
	await _tap("menu_cancel")
	for i in 10:
		await process_frame

	var rest_prompt := bedroll.get_node_or_null(^"Interactable") as Node3D
	if rest_prompt == null:
		_fail("placed bedroll has no Rest interaction")
		return
	await _teleport_near(rest_prompt, Vector3.ZERO)
	if not await _wait_provider(rest_prompt):
		_fail("camp Rest prompt never won arbitration")
		return
	await _tap("interact")
	for i in 150:
		await physics_frame
	if int(bench.get("rest_nights_together")) != nights_before + 1:
		_fail("the night in the bed did not credit rest_nights_together (%d -> %d)" % [
			nights_before, int(bench.get("rest_nights_together"))])
		return
	var kinds := _kinds_for(bench, cursor)
	if not kinds.has("bond_credit"):
		_fail("no bond_credit reached the feed for the night")
	var last := str(_strip.call("last_tick_label", bench_index))
	if int(_strip.call("tick_count", bench_index)) <= ticks_before or last != "+bond · rested":
		_fail("the strip did not tick '+bond · rested' for the night (last '%s')" % last)
	else:
		print("  ok    a night in the bed ticked the strip: '%s'" % last)
	# The rest bonus xp is also a tick.
	if not kinds.has("xp_gained"):
		_fail("the rest bonus xp did not reach the feed")


# --- 5. the banner ---------------------------------------------------------------------

func _a_level_up_outside_a_fight_is_a_banner_inside_the_safe_area(party: RefCounted) -> void:
	var index := int(party.call("active_index"))
	var creature: RefCounted = party.call("at", index)
	var cfg: Dictionary = PROGRESSION.config()
	for i in 240:
		if not bool(_hud.call("moment_banner_visible")):
			break
		await physics_frame
	for i in 60:
		await physics_frame
	var shown_before := int(_hud.call("moments_shown"))
	var level_before := int(creature.get("level"))
	creature.call("gain_xp", int(creature.call("xp_to_next", cfg)) - int(creature.get("xp")), cfg)
	for i in 60:
		if int(_hud.call("moments_shown")) > shown_before:
			break
		await physics_frame
	await physics_frame
	if int(_hud.call("moments_shown")) <= shown_before or not bool(_hud.call("moment_banner_visible")):
		_fail("a level-up outside a fight produced no banner")
		return
	var text := str(_hud.call("moment_banner_text"))
	if not text.contains(str(creature.call("label"))) or not text.contains("reached Lv %d" % (level_before + 1)):
		_fail("the banner does not name the creature and its new level: '%s'" % text)
	if not text.contains("HP"):
		_fail("the banner does not say what changed: '%s'" % text)
	var rect: Rect2 = _hud.call("moment_banner_rect")
	var canvas: Vector2 = (_hud.get("_root") as Control).size
	var safe := canvas.y * 0.05
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_fail("the banner has no size")
	elif rect.position.y < safe or rect.end.y > canvas.y - safe \
			or rect.position.x < canvas.x * 0.05 or rect.end.x > canvas.x * 0.95:
		_fail("the banner %s is outside the 5%% safe area of the %s canvas" % [str(rect), str(canvas)])
	else:
		print("  ok    banner '%s' at %s inside the safe area of the %s canvas" % [text, str(rect), str(canvas)])
	var xp_line := str(_hud.call("creature_xp_line"))
	if not xp_line.contains("to Lv"):
		_fail("the world HUD's creature block does not say how close the next level is ('%s')" % xp_line)
	else:
		print("  ok    world HUD creature block reads '%s'" % xp_line)


func _two_moments_collapse_into_one_plate(party: RefCounted) -> void:
	var cfg: Dictionary = PROGRESSION.config()
	var a: RefCounted = party.call("at", 0)
	var b: RefCounted = party.call("at", 1)
	if a == null or b == null:
		return
	for i in 240:
		if not bool(_hud.call("moment_banner_visible")):
			break
		await physics_frame
	# Past the post-banner cooldown too.
	for i in 60:
		await physics_frame
	var shown_before := int(_hud.call("moments_shown"))
	a.call("gain_xp", int(a.call("xp_to_next", cfg)) - int(a.get("xp")), cfg)
	for i in 60:
		if int(_hud.call("moments_shown")) > shown_before:
			break
		await physics_frame
	b.call("gain_xp", int(b.call("xp_to_next", cfg)) - int(b.get("xp")), cfg)
	for i in 12:
		await physics_frame
	var text := str(_hud.call("moment_banner_text"))
	if int(_hud.call("moments_shown")) != shown_before + 2:
		_fail("two level-ups within the collapse window were not both shown (shown %d)" % (int(_hud.call("moments_shown")) - shown_before))
	elif not (text.contains(str(a.call("label"))) and text.contains(str(b.call("label")))):
		_fail("the collapsed banner does not list both creatures: '%s'" % text)
	elif int(_hud.call("moments_queued")) != 0:
		_fail("a second moment inside the collapse window was queued instead of joining the plate")
	else:
		print("  ok    two moments within the window share one plate: '%s'" % text)


# --- 6. the Team screen -----------------------------------------------------------------

func _the_team_screen_answers_both_questions(party: RefCounted) -> void:
	var menu: CanvasLayer = _game.call("menu")
	menu.call("open", "creatures")
	for i in 10:
		await process_frame
	var body: Node = _tab_body(menu, "creatures")
	if body == null:
		_fail("could not open the Team screen")
		return
	for i in 6:
		await process_frame
	var rows: Variant = body.get("_bond_rows")
	var total := BOND.milestones(BOND.config()).size()
	if not rows is Array or (rows as Array).size() != total:
		_fail("the Team screen does not show one row per bond task")
	else:
		var texts: Array[String] = []
		var next_rows := 0
		for label: Variant in rows as Array:
			var t := str((label as Label).text)
			texts.append(t)
			if t.begins_with("NEXT"):
				next_rows += 1
		if next_rows != 1:
			_fail("the Team screen marks %d rows NEXT, expected exactly one: %s" % [next_rows, str(texts)])
		var with_counter := 0
		for t in texts:
			if t.contains("/"):
				with_counter += 1
		if with_counter != total:
			_fail("not every bond task shows its counter: %s" % str(texts))
		else:
			print("  ok    Team screen bond rows: %s" % str(texts))
	var xp_next := body.get("_detail_xp_next") as Label
	if xp_next == null or not xp_next.text.contains("EXP to Lv"):
		_fail("the Team screen does not say how much EXP the next level needs")
	else:
		print("  ok    Team screen xp line: '%s'" % xp_next.text)
	var benefit := body.get("_bond_next_benefit") as Label
	if benefit == null or benefit.text.is_empty():
		_fail("the Team screen does not name the next node's benefit")
	else:
		print("  ok    Team screen next benefit: '%s'" % benefit.text)
	menu.call("close")
	for i in 6:
		await process_frame


# --- helpers ------------------------------------------------------------------------------

func _kinds_for(creature: RefCounted, since: int) -> Array[String]:
	var out: Array[String] = []
	var id := creature.get_instance_id()
	for raw: Variant in FEED.peek_since(since):
		var event := raw as Dictionary
		if int(event.get("creature_id", 0)) == id:
			out.append(str(event.get("kind", "")))
	return out


func _tab_body(menu: CanvasLayer, tab_id: String) -> Node:
	var tabs: Array = menu.get("_tabs") as Array
	var bodies: Array = menu.get("_bodies") as Array
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == tab_id:
			menu.call("select", i)
			return bodies[i] as Node
	return null


func _joy_event_for(action: String, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			var out := InputEventJoypadButton.new()
			out.device = 0
			out.button_index = button.button_index
			out.pressed = pressed
			return out
		var motion := event as InputEventJoypadMotion
		if motion != null:
			var out := InputEventJoypadMotion.new()
			out.device = 0
			out.axis = motion.axis
			out.axis_value = motion.axis_value if pressed else 0.0
			return out
	return null


func _tap(action: String) -> void:
	var mapped: InputEvent = _joy_event_for(action, true)
	if mapped == null:
		_fail("InputMap action '%s' has no joypad button or axis" % action)
		return
	Input.parse_input_event(mapped)
	await process_frame
	await process_frame
	Input.parse_input_event(_joy_event_for(action, false))
	for i in 5:
		await process_frame


func _teleport_to(at: Vector3) -> void:
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else _player.global_position.y
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 14:
		await physics_frame


func _teleport_near(prompt: Node3D, offset: Vector3 = Vector3(0.25, 0.0, 0.25)) -> void:
	var at := prompt.global_position + offset
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else at.y
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 18:
		await physics_frame


func _wait_provider(provider: Node) -> bool:
	for i in 45:
		await physics_frame
		if _arbiter.call("winning_provider") == provider:
			return true
	return false


func _wait_open_script(suffix: String) -> Node:
	for i in 45:
		await process_frame
		for node: Node in root.get_children():
			var script := node.get_script() as Script
			if script != null and str(script.resource_path).ends_with(suffix) \
					and node.has_method("is_open") and bool(node.call("is_open")):
				return node
	return null


func _place_fixture(id: String, at: Vector3) -> Node3D:
	await _teleport_to(at)
	_game.set("pending_build", id)
	for i in 18:
		await physics_frame
	var before: Array[Node] = get_nodes_in_group("placed_building")
	await _tap("build_place")
	for i in 24:
		await physics_frame
	await _tap("build_cancel")
	for node: Node in get_nodes_in_group("placed_building"):
		if before.has(node):
			continue
		if str(node.get_meta("building_id", "")) == id:
			return node as Node3D
	_fail("controller placement produced no '%s' fixture" % id)
	return null


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL: " + message)


func _report() -> void:
	if _failures.is_empty():
		print("\nProgression feedback: OK")
		quit(0)
	else:
		print("\nProgression feedback: %d failure(s)" % _failures.size())
		for f in _failures:
			print("  - " + f)
		quit(1)
