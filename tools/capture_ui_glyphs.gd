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

	# 1. Exploration HUD contextual prompt -- the bible sec16 element itself.
	# The player starts in bed, which registers a real "Get up" offer through
	# interaction_arbiter.gd -- letting that stand rather than poking the
	# label directly gets a real, organically-arbitrated prompt instead of a
	# synthetic one, and sidesteps whatever RichTextLabel does with a rapid
	# text swap right before a screenshot (a first attempt here showed a
	# doubled line after overwriting the label's text once by hand).
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		var prompt_label: RichTextLabel = hud.get_node_or_null(^"Root/Prompt") as RichTextLabel
		if prompt_label != null:
			for i in 30:
				await physics_frame
			print("  prompt label text: %s" % prompt_label.text)
			print("  prompt label global_rect: %s" % prompt_label.get_global_rect())
			_dump_richtextlabels(world, "  ")
			await _shoot("exploration-prompt", written, failures)
		else:
			failures.append("exploration-prompt: HUD has no Root/Prompt RichTextLabel")
	else:
		failures.append("exploration-prompt: no PlaygroundHUD in the scene")

	# 2. Combat HUD engage prompt -- same string, different HUD. No live fight
	# is staged (smoke_combat.gd already proves that path); this only needs
	# the label to hold real formatted text for one stable screenshot.
	var combat: CanvasLayer = world.get_node_or_null(^"CombatHUD") as CanvasLayer
	if combat != null:
		combat.visible = true
		var combat_prompt: RichTextLabel = combat.get_node_or_null(^"Root/Prompt") as RichTextLabel
		if combat_prompt != null:
			# combat_hud.gd's own _process polls _director.call("prompt") every
			# frame (real, empty, since no fight is staged here) and would
			# silently overwrite this synthetic value before the screenshot.
			combat.set_process(false)
			combat_prompt.text = PROMPTS.format(PROMPTS.offer("Engage Bramblebun", 3.0))
			for i in 30:
				await physics_frame
			await _shoot("combat-prompt", written, failures)
		else:
			failures.append("combat-prompt: no Root/Prompt RichTextLabel on CombatHUD")
		combat.visible = false
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


func _dump_richtextlabels(node: Node, indent: String) -> void:
	if node is RichTextLabel:
		var rtl := node as RichTextLabel
		if not rtl.text.is_empty():
			print("%s%s text=%s visible_in_tree=%s rect=%s" % [
				indent, rtl.get_path(), rtl.text, rtl.is_visible_in_tree(), rtl.get_global_rect()
			])
	for child in node.get_children():
		_dump_richtextlabels(child, indent)


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
