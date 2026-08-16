extends SceneTree

## Can the context prompt ever sit on top of the hotbar?
##
##   godot --headless --path . --script tests/smoke_prompt_hotbar_dock.gd
##
## OW8, and this is the owner's THIRD report of it: the recall / "put away"
## prompt rendering on top of the hotbar. Two fixes shipped before this one and
## it came back after both, because both were the same kind of fix — move a
## control up by a hand-measured number (26px, then another 20px). Each number
## described one arrangement of one frame.
##
## What defeated them is that neither control is a fixed-height box.
## `HotbarPanel/Margin/Layout/Message` is `visible = false` most of the time and
## joins the panel's VBox as a real row the instant a hotbar slot answers,
## measured growing the panel 30px — which is exactly the gap the first fix had
## bought. And the prompt itself grows: it is `fit_content`, so a long creature
## name wraps to a second line and the label gets taller.
##
## So this does not check a gap. Both controls now live in one bottom-anchored
## `Root/BottomDock` VBoxContainer, and a VBox lays its children out in sequence
## — they cannot be positioned into each other at any height. This test asserts
## that property holds under the two things that broke it before, at the size
## the UI is actually judged at (`ENVIRONMENT_AND_UI_BIBLE` §17: the Ally's
## 1920x1080 seven-inch panel, not a desktop window):
##
##   1. quiet — no message row, short prompt
##   2. the hotbar's message row showing (what beat fix #1)
##   3. a realistically long prompt that wraps (what fix #2 never considered)
##   4. both at once
##
## Rects come from `get_global_rect()` — real engine geometry after layout, not
## authored offsets, which is the distinction the OF17 pass had to learn: a
## Control forced past its minimum size grows its cached rect and never writes
## that growth back to its offsets.

const HUD_SCENE := "res://scenes/ui/playground_hud.tscn"
const SETTLE := 8

## The Ally's panel. Read from ProjectSettings so this tracks the project's own
## authoring resolution rather than a second copy of it.
var _screen := Vector2i(1920, 1080)

## A put-away line with a long name in it, plus the glyph the real prompt
## carries. `_show_prompt` builds exactly this shape.
## Long enough to actually wrap in the prompt's 800px, which is the point —
## a "long" line that still fits on one row tests nothing the short one didn't.
## Verified wrapping: this measures 78px tall against the short line's 39.
const LONG_PROMPT := "[img=36x36]res://assets/ui/input_prompts/keyboard_r.png[/img]   Put Thunderbristle Junior away        [img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Talk to the Warden of the Upper Meadows about the relay"
const SHORT_PROMPT := "[img=36x36]res://assets/ui/input_prompts/keyboard_r.png[/img]   Put Pip away"

var _failures: Array[String] = []
var _hotbar: Control = null
var _prompt: RichTextLabel = null
var _message: Label = null
## Height of the one-line prompt, so the wrapping cases can prove they wrapped.
var _short_prompt_height := 0.0


func _init() -> void:
	_run()


func _run() -> void:
	for i in SETTLE:
		await process_frame

	_screen = Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 1080)),
	)
	root.size = _screen
	for i in SETTLE:
		await process_frame

	var packed: PackedScene = load(HUD_SCENE)
	if packed == null:
		print("FAIL: could not load %s" % HUD_SCENE)
		quit(1)
		return
	var hud: Node = packed.instantiate()
	root.add_child(hud)
	for i in SETTLE:
		await process_frame

	_hotbar = hud.find_child("HotbarPanel", true, false) as Control
	_prompt = hud.find_child("Prompt", true, false) as RichTextLabel
	_message = hud.find_child("Message", true, false) as Label
	if _hotbar == null or _prompt == null or _message == null:
		print("FAIL: HUD is missing HotbarPanel, Prompt or the hotbar Message row")
		quit(1)
		return

	# The structural claim itself: one parent owns both. Asserted rather than
	# assumed, because every rect check below passes trivially the moment the
	# prompt is empty — this is what says the fix is the container and not a
	# lucky pair of offsets.
	if _prompt.get_parent() != _hotbar.get_parent():
		_fail("the prompt and the hotbar do not share a parent (%s vs %s) — nothing stops them being laid into each other" % [
			_prompt.get_parent().name if _prompt.get_parent() != null else "<none>",
			_hotbar.get_parent().name if _hotbar.get_parent() != null else "<none>",
		])
	elif not (_prompt.get_parent() is BoxContainer):
		_fail("the prompt and hotbar share %s, which is not a BoxContainer — sequence is not guaranteed" % _prompt.get_parent().get_class())
	else:
		print("  ok    both live in one %s (%s)" % [
			_prompt.get_parent().get_class(), _prompt.get_parent().name,
		])

	await _case("quiet", false, SHORT_PROMPT)
	_short_prompt_height = _prompt.get_global_rect().size.y
	await _case("hotbar message showing", true, SHORT_PROMPT)
	await _case("long prompt wraps", false, LONG_PROMPT, true)
	await _case("message showing AND long prompt", true, LONG_PROMPT, true)

	_report()


func _case(label: String, message_showing: bool, prompt_text: String, wrapped_expected: bool = false) -> void:
	_message.visible = message_showing
	if message_showing:
		_message.text = "Ridge Tonic restores 80."
	_prompt.text = prompt_text
	for i in SETTLE:
		await process_frame

	var hotbar_rect := _hotbar.get_global_rect()
	var prompt_rect := _prompt.get_global_rect()
	if wrapped_expected and prompt_rect.size.y <= _short_prompt_height:
		_fail("%s: the prompt did not actually grow (%.0fpx vs the short line's %.0f) — this case is not testing wrapping" % [
			label, prompt_rect.size.y, _short_prompt_height,
		])
		return
	if hotbar_rect.intersects(prompt_rect):
		_fail("%s: the prompt overlaps the hotbar — hotbar %s, prompt %s" % [
			label, hotbar_rect, prompt_rect,
		])
		return

	# Not off the bottom of the screen either: a stack that avoids overlap by
	# pushing the prompt past the panel edge has not solved anything.
	if prompt_rect.end.y > float(_screen.y):
		_fail("%s: the prompt runs off the bottom of the screen (ends %.0f, screen %d)" % [
			label, prompt_rect.end.y, _screen.y,
		])
		return

	print("  ok    %s: hotbar %s, prompt %s, gap %.0fpx" % [
		label, hotbar_rect, prompt_rect, prompt_rect.position.y - hotbar_rect.end.y,
	])


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report() -> void:
	print("")
	print("prompt/hotbar dock, measured at %s" % _screen)
	if _failures.is_empty():
		print("OK")
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
