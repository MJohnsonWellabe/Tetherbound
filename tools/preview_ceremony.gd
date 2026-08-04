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

var _stack: Node = null
var _release: Control = null
var _shots: int = 0


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
	await _shot("six")

	# The longest card, focused. The first frame lands on the newcomer; step to
	# the pal with the longest trait description, which is the one that clips.
	_press("move_right")
	await _settle()
	await _shot("six_focused")

	# Refused exit — the screen has to say why and stay, and the message is extra
	# text in a panel that was already the tightest thing here.
	_press("menu_cancel")
	await _settle()
	await _shot("six_refused")

	# Into the farewell. Confirm on a card chooses it and pushes.
	_press("menu_confirm")
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
	var trait_id := _longest_trait()
	var species := _longest_species()
	var levels := [1, 9, 14, 22, 37]
	for i in PARTY.MAX_PARTY:
		var pal: RefCounted = SPECIES.spawn(species)
		pal.assign_trait(trait_id)
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


## --- driving and capture ---------------------------------------------------

## Press through the real actions, so a screen that does not respond here does
## not respond on the handheld either.
func _press(action: StringName) -> void:
	Input.action_press(action)
	Input.action_release(action)


func _settle() -> void:
	for i in SETTLE:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	_shots += 1
	var path := OUT % ("%02d_%s" % [_shots, name])
	image.save_png(path)
	print("frame '%s' -> %s" % [name, path])


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
