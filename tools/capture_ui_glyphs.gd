extends SceneTree

## Frames of the five panels EV9's input-glyph slice touched, for the local
## blind-judge pass conventions.md requires before shipping visual-affecting
## work.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_ui_glyphs.gd
##
## Opens each panel through its own real API (dialogue_panel.start(),
## name_prompt.open(), starter_picker.open()) rather than driving the full
## button-press sequence smoke_opening.gd already covers -- this needs
## pixels, not proof the flow works. The exploration and combat prompts are
## simpler still: both are drawn from a plain string
## (`interaction_arbiter`/`encounter_director`'s own `prompt()`), so this sets
## that string directly through `prompt_arbiter.gd`'s real `format()` rather
## than staging a whole interactable or a live fight.
##
## Writes shots/ui_glyphs/*.png.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const DIALOGUE := "res://scripts/ui/dialogue_panel.gd"
const NAME_PROMPT := "res://scripts/ui/name_prompt.gd"
const STARTER_PICKER := "res://scripts/ui/starter_picker.gd"
const PROMPTS := preload("res://scripts/world/prompt_arbiter.gd")

const OUT_DIR := "res://shots/ui_glyphs"

## OW8 moved the exploration prompt into the shared bottom dock -- "the prompt
## and the hotbar share one container, so neither can be laid into the other".
## This tool still asked for `Root/Prompt`, got null, and then assigned
## `.visible` on it, which aborted the whole capture with "Invalid assignment
## of property 'visible' ... on a base object of type 'null instance'". So the
## glyph frames the visual-judge pass wants have not been renderable since that
## merge, and nothing said so -- a capture tool is not a test and no shard runs
## it. `playground_hud.gd`'s own `_prompt_label` is the authority for this path.
## The COMBAT HUD kept its own `Root/Prompt`; only the exploration one moved.
const EXPLORATION_PROMPT := ^"Root/BottomDock/Prompt"

## The persistent legend, which is a SIBLING of the prompt in the same dock.
##
## It has to be hidden alongside the prompt when the combat frame is staged.
## `playground_hud.gd::_exploration_legend_should_show()` already returns false
## while `_combat_is_running()`, so in a real fight a player never sees the
## legend and the combat prompt together -- but this tool fakes the fight by
## setting `combat.visible = true` without one running, so the legend stays up
## and the two draw over each other. A blind visual critic shown that frame
## reported the overprint as the single most severe defect in the set, which is
## correct about the pixels and wrong about the game. Hidden here so the frame
## shows what is actually on screen during a fight.
const EXPLORATION_LEGEND := ^"Root/BottomDock/ExplorationLegend"
const SETTLE_FRAMES := 300
const POSE_FRAMES := 6


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var written: Array[String] = []
	var failures: Array[String] = []

	# NOT AN EV9 BUG, found while building this capture: CombatHUD's Prompt
	# row is never hidden outside a fight (by design -- it has to keep
	# showing "Engage X" before a fight starts) and encounter_director.prompt()
	# DELEGATES to the same arbiter interaction_arbiter.gd drives whenever one
	# is present, so CombatHUD silently mirrors WHATEVER exploration prompt is
	# showing, not just an engage offer -- confirmed here: both panels read
	# "Get up" off the bed's real offer, stacked on screen, simultaneously.
	# Recorded as its own BACKLOG.md item (EV9-double-prompt) rather than
	# fixed here -- it is a combat/exploration arbitration bug, not a glyph
	# one, and touching that logic is a different-shaped task. Isolating
	# each HUD explicitly below so these two shots stay clean regardless.
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	var combat: CanvasLayer = world.get_node_or_null(^"CombatHUD") as CanvasLayer

	# 1. Exploration HUD contextual prompt -- the bible sec16 element itself.
	# The player starts in bed, which registers a real "Get up" offer through
	# interaction_arbiter.gd -- letting that stand rather than poking the
	# label directly gets a real, organically-arbitrated prompt.
	if hud != null:
		if combat != null:
			combat.visible = false
		var prompt_label: RichTextLabel = hud.get_node_or_null(EXPLORATION_PROMPT) as RichTextLabel
		if prompt_label != null:
			for i in 30:
				await physics_frame
			await _shoot("exploration-prompt", written, failures)
		else:
			failures.append("exploration-prompt: HUD has no RichTextLabel at %s" % EXPLORATION_PROMPT)
	else:
		failures.append("exploration-prompt: no PlaygroundHUD in the scene")

	# 2. Combat HUD engage prompt -- same string shape, different HUD. No
	# live fight is staged (smoke_combat.gd already proves that path); this
	# only needs the label to hold real formatted text for one screenshot,
	# with the exploration HUD's own prompt hidden so it cannot bleed in the
	# same way (see the note above).
	if combat != null:
		combat.visible = true
		if hud != null:
			var explore_prompt: Control = hud.get_node_or_null(EXPLORATION_PROMPT) as Control
			if explore_prompt != null:
				explore_prompt.visible = false
			var explore_legend: Control = hud.get_node_or_null(EXPLORATION_LEGEND) as Control
			if explore_legend != null:
				explore_legend.visible = false
			else:
				failures.append("combat-prompt: no %s to hide; the staged frame will "
					% EXPLORATION_LEGEND + "show the legend under the combat prompt, "
					+ "which is a capture artifact and not what a fight looks like")
		var combat_prompt: RichTextLabel = combat.get_node_or_null(^"Root/Prompt") as RichTextLabel
		if combat_prompt != null:
			# combat_hud.gd's own _process polls _director.call("prompt") every
			# frame and would overwrite this synthetic value before the shot.
			combat.set_process(false)
			combat_prompt.text = PROMPTS.format(PROMPTS.offer("Engage Bramblebun", 3.0))
			for i in 30:
				await physics_frame
			await _shoot("combat-prompt", written, failures)
		else:
			failures.append("combat-prompt: no Root/Prompt RichTextLabel on CombatHUD")
		combat.visible = false
		if hud != null:
			var restore_prompt: Control = hud.get_node_or_null(EXPLORATION_PROMPT) as Control
			if restore_prompt != null:
				restore_prompt.visible = true
			var restore_legend: Control = hud.get_node_or_null(EXPLORATION_LEGEND) as Control
			if restore_legend != null:
				restore_legend.visible = true
	else:
		failures.append("combat-prompt: no CombatHUD in the scene (skipping)")

	# 3. Dialogue panel, opened for real through its own runner.
	var dialogue: CanvasLayer = world.get_node_or_null(^"DialoguePanel") as CanvasLayer
	if dialogue != null and dialogue.get_script() != null:
		if bool(dialogue.call("start", "grandpa_house")):
			await _shoot("dialogue-panel", written, failures)
			dialogue.call("close")
		else:
			failures.append("dialogue-panel: start('grandpa_house') refused")
	else:
		failures.append("dialogue-panel: no DialoguePanel in the scene")

	# 4. Starter picker, opened directly with the three known starters.
	var picker: CanvasLayer = world.get_node_or_null(^"StarterPicker") as CanvasLayer
	if picker != null:
		picker.call("open", ["terrapup", "ripplet", "galewisp"] as Array[String])
		for i in POSE_FRAMES * 4:
			await physics_frame
		await _shoot("starter-picker", written, failures)
	else:
		failures.append("starter-picker: no StarterPicker in the scene")

	# 5. Name prompt, opened directly.
	var namer: CanvasLayer = world.get_node_or_null(^"NamePrompt") as CanvasLayer
	if namer != null and namer.get_script() != null:
		namer.call("open", "Terrapup")
		await _shoot("name-prompt", written, failures)
	else:
		failures.append("name-prompt: no NamePrompt in the scene")

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _shoot(name: String, written: Array[String], failures: Array[String]) -> void:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		failures.append("%s: save_png failed (%d)" % [name, error])
		return
	written.append(path)
	print("  %-18s -> %s" % [name, path])
