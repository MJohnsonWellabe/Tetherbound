extends SceneTree

## Real shared HUD scenes, isolated lifecycle fixture. Actual captain/combat
## input and production arena evidence are separate production-integration smoke.
const WORLD_HUD:=preload("res://scenes/ui/playground_hud.tscn")
const COMBAT_HUD:=preload("res://scenes/combat/combat_hud.tscn")
const SPECIES:=preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION:=preload("res://scripts/creatures/progression.gd")
const GLYPHS:=preload("res://scripts/ui/input_glyph.gd")
const FEED:=preload("res://scripts/creatures/progression_feed.gd")
const INPUT_OWNER:=preload("res://scripts/ui/input_owner.gd")
class Manager extends Node:
	var _enemy_owned := true
class Director extends Node:
	var _trainer_spec := {"name":"Captain Veyra"}
var failures:Array[String]=[]
var checks:=0
var game:Node
var hud:CanvasLayer
var combat:CanvasLayer
var feed:CanvasLayer


func _init()->void:_run.call_deferred()


func _frames(count:int)->void:
	for i in count:await process_frame


func _check(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label);push_error(label)


func _capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://shots/hud-lifecycle")
	root.get_texture().get_image().save_png("res://shots/hud-lifecycle/"+label+".png")


func _run()->void:
	root.size=Vector2i(1280,800)
	# Production HUD authoring canvas is 1920 wide; render its normal stretch
	# at the actual 1280x800 handheld window, not a narrower fake author canvas.
	root.content_scale_size=Vector2i(1920,1200)
	game=root.get_node("Game")
	game.reset_for_new_game()
	game.set_process(false)
	for id:String in ["galecrest","mudsnout","bramblebun","terrapup","brooktail"]:
		game.party.add(SPECIES.spawn(id))
	var world:=Node.new()
	world.name="HudLifecycleFixture"
	root.add_child(world)
	current_scene=world
	hud=WORLD_HUD.instantiate()
	hud.name="PlaygroundHUD"
	world.add_child(hud)
	combat=COMBAT_HUD.instantiate()
	combat.name="CombatHUD"
	world.add_child(combat)
	await _frames(15)
	hud.set_process(false)
	combat.set_process(false)
	feed=get_first_node_in_group("progression_feedback_presenter")
	feed.set_process(false)
	_check(feed == hud and get_nodes_in_group("progression_feedback_presenter").size() == 1,"Production HUD owns one progression presenter")
	# Explicit overlapping historical-state fixture; no fake production verdict.
	hud._region_banner.text="Summit / Final Stronghold"
	hud._region_banner.show()
	hud._objective_text_label.text="Defeat Captain Veyra at the Eye of the Anchor."
	hud._objective_block.show()
	hud._reveal_objective_hint("Use lee zones, reposition through crosswinds, and switch creatures when Veyra changes pressure.")
	combat._enemy_name.text="Galewisp"
	var foe := SPECIES.spawn("galewisp")
	foe.level = 31
	var manager := Manager.new()
	var director := Director.new()
	world.add_child(manager)
	world.add_child(director)
	combat._enemy_eyebrow.text = combat.enemy_identity_text(foe, manager, director)
	_check(combat._enemy_eyebrow.text == "Captain Veyra · LEVEL 31", "Captain ownership and valid level use production identity formatter")
	combat._enemy_panel.show()
	await _frames(10)
	await _capture("before-overlapping-layers")
	hud.set_world_presentation_mode("combat")
	combat.set_world_presentation_mode("combat")
	_check(not hud._region_banner.visible,"Combat removes colliding location banner")
	_check(not hud._objective_hint_card.visible,"Combat telegraphs own instruction lane")
	_check(not hud._objective_block.visible,"Combat removes redundant tracked task")
	_check(not hud._hotbar_panel.visible,"Combat retains one combat control owner")
	await _capture("after-combat-priority")
	combat._outcome.text="stale result"
	combat._xp_line.text="stale XP"
	hud._reveal_objective_hint("Pilot your creature through the wind and strike the three exposed relays.")
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_X
	pad.pressed = true
	Input.parse_input_event(pad)
	await _frames(2)
	_check(GLYPHS.using_gamepad(), "Real joypad event selects controller prompt family")
	hud._prompt_label.text=GLYPHS.icon("interact") + " Strike the exposed west relay"
	hud._fit_prompt_pill()
	hud._prompt_label.show()
	hud.set_world_presentation_mode("relays")
	combat.set_world_presentation_mode("relays")
	_check(combat._outcome.text.is_empty() and combat._xp_line.text.is_empty(),"Relays atomically clear outcome and XP leftovers")
	_check(not combat._enemy_panel.visible and not combat._grid_panel.visible,"Relays release combat plates and move grid")
	_check(not hud._hotbar_panel.visible and not hud._exploration_legend.visible,"Relays remove exploration toolbar takeover")
	_check(hud._prompt_label.visible,"Relay interaction prompt remains visible")
	_check(hud._objective_hint_card.visible,"Only mechanic instruction remains")
	_check(is_equal_approx(hud._party_strip.scale.x * root.get_screen_transform().get_scale().x,1.0),"Relay rows retain native pixel text scale")
	var member:RefCounted=game.party.active()
	member.gain_xp(12,PROGRESSION.config())
	game.push_world_message("Captain Veyra's reward: 150 Coin, 1 Rare Candy")
	hud._update_world_message()
	feed._update_moment_banner()
	hud._apply_presentation_priority()
	await _frames(10)
	_check(feed.moment_visible(),"Production receipt reaches shared feed")
	_check(feed.moment_banner_text().contains("150 Coin"),"Receipt preserves actual payout wording")
	_check(feed.moment_banner_text().contains("Captain Veyra defeated"),"Receipt explicitly closes captain phase")
	_check(feed.moment_banner_text().contains("Next: disable the three exposed relays"),"Reward distinguishes continuing relay objective")
	_check(is_equal_approx(hud._party_strip.modulate.a,1.0),"Reward retains full party text contrast")
	_check(feed.moment_banner_text().contains("+12 XP"),"Shared receipt attributes XP")
	_check(not hud._objective_hint_card.visible,"Instruction yields while reward moment occupies top lane")
	_check(not hud._hotbar_panel.visible,"Reward does not reveal hotbar behind relay")
	_check(not combat._party_strip.visible,"Shared XP tick cannot resurrect the inactive combat party rail")
	await _capture("after-relay-reward")
	feed._moment_until = 0.0
	feed._update_moment_banner()
	hud._apply_presentation_priority()
	_check(hud._objective_hint_card.visible,"Mechanic instruction returns after reward")
	await _capture("after-relay-instruction")
	hud.set_world_presentation_mode("exploration")
	combat.set_world_presentation_mode("exploration")
	_check(hud._hotbar_panel.visible,"Exploration restores hotbar")
	_check(combat._outcome.text.is_empty(),"Exploration does not revive stale result")
	await _full_party_moment_layout()
	await _progression_reset_and_modal_lifecycle(member)
	print("HUD LIFECYCLE %s: %d checks"%["PASS" if failures.is_empty() else "FAIL",checks])
	world.queue_free()
	await _frames(3)
	# This short fixture emits eleven real level cues then quits immediately.
	# Stop its one-shots and let the audio thread release playback buffers before
	# shutdown; their normal duration exceeds the remaining test lifetime.
	for cue: AudioStreamPlayer in AudioManager._pool:
		if is_instance_valid(cue):
			cue.stop()
			cue.stream = null
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)


func _full_party_moment_layout() -> void:
	var cfg: Dictionary = PROGRESSION.config()
	for mode: String in ["exploration", "relays"]:
		hud.set_world_presentation_mode(mode)
		FEED.clear()
		var index := 0
		for member: RefCounted in game.party.members():
			member.set_level(40, cfg)
			member.xp = member.xp_to_next(cfg) - 1
			member.gain_xp(100 + index * 17, cfg)
			index += 1
		game.push_world_message("Captain Veyra's reward: 150 Coin, 1 Rare Candy")
		hud._update_world_message()
		# Five real level events and their receipt collapse through production.
		for i in 6:
			hud._update_moment_banner()
		hud._update_party_strip()
		hud._party_strip.show_strip()
		hud._apply_presentation_priority()
		await _frames(10)
		var rect: Rect2 = hud.moment_banner_rect()
		var canvas: Vector2 = hud._root.size
		var text: String = hud.moment_banner_text()
		_check(hud.moments_shown() == 6 and hud.moments_queued() == 0, mode + ": all five levels and receipt share one visible card")
		_check(not rect.intersects(hud._party_strip.get_global_rect()), mode + ": full-party receipt clears the actual roster bounds")
		_check(not rect.intersects(hud._prompt_label.get_global_rect()), mode + ": reward keeps the controller interaction prompt clear")
		_check(rect.position.x >= canvas.x * 0.60, mode + ": reward leaves the central creature view open")
		_check(rect.position.y >= canvas.y * 0.05 - 1 and rect.end.x <= canvas.x * 0.95 + 1 and rect.end.y <= canvas.y * 0.95 + 1, mode + ": whole receipt fits the handheld safe area")
		_check(rect.size.y <= canvas.y * 0.48, mode + ": five-member details remain a compact card")
		_check(text.contains("150 Coin, 1 Rare Candy"), mode + ": full-team layout retains exact payout")
		_check(text.count(" HP") == 5 and text.count(" ATK") == 5 and text.count(" DEF") == 5, mode + ": every member retains its stat deltas")
		index = 0
		for member: RefCounted in game.party.members():
			_check(text.contains("%s reached Lv 41 · +%d XP" % [member.label(), 100 + index * 17]), mode + ": level and XP stay attributed to " + member.label())
			_check(text.contains("EXP %d/%d" % [member.xp, member.xp_to_next(cfg)]), mode + ": exact XP progress remains visible for " + member.label())
			index += 1
		print("FULL PARTY HUD %s bounds=%s canvas=%s" % [mode, rect, canvas])
	hud.set_world_presentation_mode("exploration")


func _progression_reset_and_modal_lifecycle(member: RefCounted) -> void:
	FEED.clear()
	member.gain_xp(member.xp_to_next(PROGRESSION.config()), PROGRESSION.config())
	hud._update_moment_banner()
	_check(hud.moment_banner_visible(), "Fresh generation displays a new level moment")
	var previous_text: String = hud.moment_banner_text()
	var modal := Control.new()
	modal.name = "FlyDestinationPickerInputOwner"
	root.add_child(modal)
	modal.add_to_group(INPUT_OWNER.GROUP)
	# A nearly expired real banner must survive longer than its remaining hold.
	hud._moment_until = Time.get_ticks_msec()/1000.0 + 0.05
	hud._update_moment_banner()
	_check(not hud.moment_banner_visible(), "Modal ownership hides an already visible moment")
	var remaining: float = hud._moment_until - hud._moment_pause_started
	await create_timer(0.1).timeout
	modal.hide()
	hud._update_moment_banner()
	_check(hud.moment_banner_visible() and hud.moment_banner_text() == previous_text, "Closing modal restores the same earned moment")
	_check(hud._moment_until - Time.get_ticks_msec()/1000.0 >= remaining - 0.02, "Modal visit preserves the moment's reading time")
	modal.queue_free()
	paused = true
	_check(not hud.moment_banner_visible(), "Tree-pausing menus capture the pause before HUD processing stops")
	paused = false
	hud._update_moment_banner()
	_check(hud.moment_banner_visible(), "Unpausing resumes the earned moment")
	# A reset followed by an identical number of events can reuse the exact seq.
	# Epochs, not seq comparisons, must discard both the visible and queued save.
	var old_seq: int = FEED.latest_seq()
	FEED.clear()
	for i in old_seq:
		FEED.push("reward_summary", null, {"name":"Team", "receipt":"New save's reward: 1 Coin"})
	_check(FEED.latest_seq() == old_seq, "Reset fixture reuses the old sequence")
	hud._update_moment_banner()
	_check(hud.moment_banner_text().contains("New save") and not hud.moment_banner_text().contains("reached Lv"), "Same-sequence save reset discards the old banner")
	var strip: Control = combat._party_strip
	strip.hide_now()
	strip.progression_feedback_enabled = false
	member.gain_xp(1, PROGRESSION.config())
	strip._poll_feed()
	_check(not strip.visible, "Inactive combat strip cannot resurrect itself on a new feed generation")
