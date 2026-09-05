extends SceneTree

## Real shared HUD scenes, isolated lifecycle fixture. Actual captain/combat
## input and production arena evidence are separate production-integration smoke.
const WORLD_HUD:=preload("res://scenes/ui/playground_hud.tscn")
const COMBAT_HUD:=preload("res://scenes/combat/combat_hud.tscn")
const SPECIES:=preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION:=preload("res://scripts/creatures/progression.gd")
const GLYPHS:=preload("res://scripts/ui/input_glyph.gd")
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
	feed.step(0.1,game.drain_progression_events(),false)
	hud._apply_presentation_priority()
	await _frames(10)
	_check(feed.moment_visible(),"Production receipt reaches shared feed")
	_check(feed._moment_label.text.contains("150 Coin"),"Receipt preserves actual payout wording")
	_check(feed._moment_label.text.contains("Captain Veyra defeated"),"Receipt explicitly closes captain phase")
	_check(feed._progress_label.text.contains("Next: disable the three exposed relays"),"Reward distinguishes continuing relay objective")
	_check(is_equal_approx(hud._party_strip.modulate.a,1.0),"Reward retains full party text contrast")
	_check(feed._progress_label.text.contains("+12 XP"),"Shared receipt attributes XP")
	_check(not hud._objective_hint_card.visible,"Instruction yields while reward moment occupies top lane")
	_check(not hud._hotbar_panel.visible,"Reward does not reveal hotbar behind relay")
	_check(not combat._party_strip.visible,"Shared XP tick cannot resurrect the inactive combat party rail")
	await _capture("after-relay-reward")
	feed.step(4.0,[],false)
	hud._apply_presentation_priority()
	_check(hud._objective_hint_card.visible,"Mechanic instruction returns after reward")
	await _capture("after-relay-instruction")
	hud.set_world_presentation_mode("exploration")
	combat.set_world_presentation_mode("exploration")
	_check(hud._hotbar_panel.visible,"Exploration restores hotbar")
	_check(combat._outcome.text.is_empty(),"Exploration does not revive stale result")
	print("HUD LIFECYCLE %s: %d checks"%["PASS" if failures.is_empty() else "FAIL",checks])
	world.queue_free()
	await _frames(3)
	quit(0 if failures.is_empty() else 1)
