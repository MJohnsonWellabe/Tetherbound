extends SceneTree

## Photograph the release ceremony's two screens, without playing the game.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/preview_ceremony.gd
##
## `tools/play_session.gd -- release` is the evidence and this is not. That
## session boots the meadow, fights, throws until something is caught and takes
## about thirty-five minutes; this loads the menu layer over a flat backdrop and
## takes seconds. It exists so a layout can be iterated on by LOOKING at it,
## which is the only way a clipped panel or an unreadable line is ever found.
##
## The clipping this tool was written for: the first rendered ceremony cut the
## appraisal off after two of its seven lines, and the farewell sliced "You
## appraised it" in half. Every assertion passed. `screen.gd` will happily draw a
## panel whose contents are taller than it is, and nothing in the code can tell.
##
## WORST CASE, DELIBERATELY. The party it builds is not a plausible one — it is
## six pals chosen so that every screen shows the most text it can ever show: the
## longest trait description in `traits.json`, the longest species name, levels
## in double digits so the xp line is at its widest. A layout that fits the
## average party is a layout that clips on somebody's actual save.

const PARTY := preload("res://scripts/pals/party.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const TRAITS := preload("res://scripts/pals/pal_traits.gd")
const CEREMONY := preload("res://scripts/pals/release_ceremony.gd")
const STACK_SCENE := "res://scenes/ui/screen_stack.tscn"
const OUT := "res://shots/_ceremony_%s.png"

## Long enough for the screens to lay out and for a `fit_content` RichTextLabel
## to have measured its own text. One frame is not enough; a container that has
## not finished sizing photographs as if the content fitted.
const SETTLE := 30

## Long enough for a held direction to be seen by `_physics_process`, and long
## enough after release that the next press is a fresh one rather than the
## hold-to-repeat of this one. `screen_stack.gd`'s NAV_DELAY is 0.40s; 8 frames
## at 60Hz is well inside it.
const HOLD_FRAMES := 8
const RELEASE_FRAMES := 6

var _stack: Node = null
var _release: Control = null
var _shots: int = 0
var _last_fingerprint: String = ""


func _init() -> void:
	_run()


func _run() -> void:
	var backdrop := _backdrop()
	root.add_child(backdrop)

	var stack_scene := load(STACK_SCENE) as PackedScene
	_stack = stack_scene.instantiate()
	root.add_child(_stack)
	_release = _stack.get_node_or_null(^"ReleaseScreen") as Control
	if _release == null:
		print("no ReleaseScreen under the screen stack; nothing to photograph")
		quit(2)
		return

	await process_frame

	var party := _worst_case_party()
	var newcomer := _worst_case_newcomer()
	var ceremony: RefCounted = CEREMONY.open(party, newcomer)
	if ceremony == null:
		print("the ceremony refused to open on a party of %d" % party.size())
		quit(2)
		return

	print("party: %s" % ", ".join(_names(party.members())))
	print("newcomer: %s" % newcomer.display())

	_release.call("set_ceremony", ceremony)
	_stack.call("push", _release)
	await _settle()
	_audit_cards(ceremony)
	await _shot("six")

	# The longest card, focused. The first frame lands on the newcomer; step to
	# the pal with the longest trait description, which is the one that clips.
	await _press("move_right")
	await _settle()
	await _shot("six_focused")

	# Refused exit — the screen has to say why and stay, and the message is extra
	# text in a panel that was already the tightest thing here.
	await _press("menu_cancel")
	await _settle()
	await _shot("six_refused")

	# Into the farewell. Confirm on a card chooses it and pushes.
	await _press("menu_confirm")
	await _settle()
	await _shot("farewell")
	print("stack depth at the farewell: %d" % int(_stack.call("depth")))

	print("wrote %d frames" % _shots)
	quit(0)


## --- the worst case --------------------------------------------------------

## Six pals built to make every screen as tall as it can get: the longest trait
## description in the data, the longest species display name, and levels high
## enough that the xp line is at its widest.
func _worst_case_party() -> RefCounted:
	var party: RefCounted = PARTY.new()
	var species := _longest_species()
	var levels := [1, 9, 14, 22, 37]
	# A DIFFERENT trait on every pal.
	#
	# The first version of this gave all five the longest trait description, to
	# make the panel as tall as it could be. That made the layout worst case and
	# the identity best case: every card showed the same trait, so a screen
	# drawing card 3 from pal 1 would have looked perfectly correct. A real run
	# then produced six cards whose traits disagreed with the party, and this
	# tool could not have caught it.
	#
	# Length is still covered — `_longest_trait()` is first in the list, so one
	# card always carries the tallest text.
	var traits := _distinct_traits()
	for i in PARTY.MAX_PARTY:
		var pal: RefCounted = SPECIES.spawn(species)
		pal.assign_trait(str(traits[i % traits.size()]))
		pal.set_level(int(levels[i]))
		# A name at the width the rename screen allows, so the card is not
		# photographed with a short one and called fine.
		pal.rename("Thunderpaw" if i % 2 == 0 else "Marigold")
		pal.hp = pal.max_hp * (0.08 if i == 1 else 1.0)
		party.add(pal)
	return party


func _worst_case_newcomer() -> RefCounted:
	var pal: RefCounted = SPECIES.spawn(_longest_species())
	pal.assign_trait(_longest_trait())
	pal.set_level(31)
	# Deliberately NOT renamed. The newcomer has never been named — it falls back
	# to its species display name, which is the longest string that line can hold.
	pal.hp = pal.max_hp * 0.02
	return pal


## Every trait in the data, longest description first so the tall case is always
## on a card, and so no two pals in the preview share one.
func _distinct_traits() -> Array:
	var ids: Array = TRAITS.ids().duplicate()
	ids.sort_custom(func(a: String, b: String) -> bool:
		return str(TRAITS.definition(a).get("description", "")).length() \
			> str(TRAITS.definition(b).get("description", "")).length())
	return ids


func _longest_trait() -> String:
	var best := ""
	var best_length := -1
	for id: String in TRAITS.ids():
		var text := str(TRAITS.definition(id).get("description", ""))
		if text.length() > best_length:
			best_length = text.length()
			best = id
	return best


func _longest_species() -> String:
	var best := ""
	var best_length := -1
	for id: String in SPECIES.table().keys():
		var text := str(SPECIES.definition(id).get("display_name", id))
		if text.length() > best_length:
			best_length = text.length()
			best = id
	return best


func _names(members: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for member: Variant in members:
		out.append(str((member as RefCounted).call("display")))
	return out


## --- does the screen show the pals it was given? ----------------------------

## Compare, card by card, what the screen DREW against what the ceremony HOLDS.
##
## The M5 gate refused on exactly this and it took a blind reviewer to see it:
## the transcript's reading of the card labels said one thing and the rendered
## pixels said another, for three of six pals, with the trait and the max HP
## moving together — which is the signature of a card drawn from the wrong pal
## rather than of a formatting slip.
##
## Comparing a label to the object it is supposed to be describing is the check
## that finds that, and it costs nothing. Reading the label alone cannot: a card
## showing a plausible trait for a plausible creature looks right in isolation,
## and it is only wrong relative to what it was asked to draw.
func _audit_cards(ceremony: RefCounted) -> void:
	var drawn := _trait_labels(_release)
	var count: int = int(ceremony.call("count"))
	print("--- what each card DREW vs what the ceremony HOLDS ---")
	if drawn.size() != count:
		print("  %d trait labels on screen for %d candidates" % [drawn.size(), count])

	var wrong := 0
	for i in count:
		var pal: RefCounted = ceremony.call("at", i) as RefCounted
		var held := "<none>" if pal == null else str(pal.get("trait_id"))
		var expected := TRAITS.display_name(held) if TRAITS.has(held) else held
		var shown: String = str(drawn[i]) if i < drawn.size() else "<no label>"
		var agrees := shown == expected
		if not agrees:
			wrong += 1
		print("  card %d: drew '%s'   ceremony holds '%s' (%s)%s" % [
			i, shown, expected, held, "" if agrees else "   <-- MISMATCH"
		])
	if wrong > 0:
		print("  %d of %d cards are drawing a pal the ceremony did not give them" % [wrong, count])
	else:
		print("  every card drew the pal it was given")


## The `Trait` label of each card, in the order they are laid out. Same walk the
## evidence session uses, so the two agree about what "on screen" means.
func _trait_labels(node: Node) -> PackedStringArray:
	var out := PackedStringArray()
	var item := node as CanvasItem
	if item != null and not item.is_visible_in_tree():
		return out
	if node.name == &"Trait":
		var text: Variant = node.get("text")
		if text is String and not (text as String).is_empty():
			out.append(text as String)
	for child in node.get_children():
		out.append_array(_trait_labels(child))
	return out


## --- driving and capture ---------------------------------------------------

## Press through the real actions, so a screen that does not respond here does
## not respond on the handheld either.
##
## HELD across physics frames, not pressed and released in one call. The two
## kinds of input in `screen_stack.gd` are read differently: buttons come from
## `Input.is_action_just_pressed()`, which latches for the frame the press was
## recorded in, but DIRECTIONS come from `Input.get_axis()`, which reports what
## is held right now. A press and release inside one call is never held during a
## physics frame, so the axis reads zero and the cursor does not move.
##
## The first version of this file did exactly that, and the cost was the shape of
## the mistake rather than its size: frames 01 and 02 came out byte-identical, so
## the tool reported photographing "the focused card" while photographing the
## same card twice. A harness that silently does nothing is worse than one that
## fails, because its output looks like evidence.
func _press(action: StringName) -> void:
	Input.action_press(action)
	for i in HOLD_FRAMES:
		await physics_frame
	Input.action_release(action)
	for i in RELEASE_FRAMES:
		await physics_frame


func _settle() -> void:
	for i in SETTLE:
		await process_frame


## Capture, and say so out loud when the picture did not change.
##
## Every frame here is taken after an input that is supposed to have changed
## something. Two identical frames therefore mean the input did nothing, and that
## is precisely the failure this tool shipped with: a press-and-release that
## never survived to a physics frame produced two byte-identical PNGs, and the
## log said "frame 'six_focused'" over a photograph of the unfocused screen.
##
## Nothing here fails the run — this is a preview, not a test. But a harness that
## quietly does nothing is worse than one that breaks, because its output still
## looks like evidence, so the fact goes in the log where it cannot be missed.
func _shot(name: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	_shots += 1
	var path := OUT % ("%02d_%s" % [_shots, name])
	image.save_png(path)

	var fingerprint: String = image.get_data().get_string_from_ascii().sha256_text()
	var note := ""
	if fingerprint == _last_fingerprint:
		note = "   <-- IDENTICAL to the previous frame; the input before it changed nothing"
	_last_fingerprint = fingerprint
	print("frame '%s' -> %s%s" % [name, path, note])


## Something behind the menus that is not black, so a panel's edge is visible
## against it and a screen that failed to draw does not photograph as a
## convincing dark rectangle.
func _backdrop() -> Node:
	var layer := CanvasLayer.new()
	layer.layer = -10
	var rect := ColorRect.new()
	rect.color = Color(0.29, 0.38, 0.26)
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	layer.add_child(rect)
	return layer
