extends RefCounted

## Kenney Input Prompts glyphs for the narrative UI (dialogue, naming, the
## starter picker -- EV9's first slice, replacing literal "[X] / [E]" bracket
## text with a real icon) and, since `HD1`, combat's own Actions row. Bible
## sec18.
##
## KNOWN LIMITATION, inherited from the bracket text this replaces rather than
## introduced by it: this maps each action's DEFAULT device binding
## (project.godot), not whatever the player rebound it to in tab_settings.gd.
## The bracket hints had the identical gap -- "[X] / [E]" never read
## key_bindings.gd either. Making this rebinding-aware needs that live
## InputMap lookup threaded through every call site, which is real work and a
## separate ship from "put an icon where a bracket used to be".
##
## `HD1`: device is now the LAST INPUT USED, tracked by the `Game` autoload
## (the project's one singleton -- this does not add a second one) rather
## than "is a pad connected", which is what bible sec18 actually asks for:
## live switching as the player's hands move between keyboard and pad.

const DIR := "res://assets/ui/input_prompts/"

## One file per id/device, EXCEPT "horizontal": a blind visual-judge pass
## found Kenney's own combined "arrows_horizontal"/"dpad_horizontal" icons
## (and, separately, "keyboard_enter") illegible at the ~28px this renders
## at -- fine-detail glyphs and baked-in multi-letter text (full "ENTER")
## survive a 64px source down to a few dozen screen pixels far worse than a
## single bold letter or arrowhead does. "horizontal" is an Array of two
## single-direction icons shown side by side instead of one combined glyph;
## every other id stays a single file.
const GLYPHS := {
	"interact": {"keyboard": "keyboard_e.png", "gamepad": "xbox_button_x.png"},
	"confirm": {"keyboard": "keyboard_return.png", "gamepad": "xbox_button_a.png"},
	"cancel": {"keyboard": "keyboard_escape.png", "gamepad": "xbox_button_b.png"},
	"horizontal": {
		"keyboard": ["keyboard_arrow_left.png", "keyboard_arrow_right.png"],
		"gamepad": ["xbox_dpad_left.png", "xbox_dpad_right.png"],
	},
	"pal_recall": {"keyboard": "keyboard_r.png", "gamepad": "xbox_dpad_up.png"},
	## Combat's five verbs (`HD1`). `combat_quick`/`combat_charged` bind to
	## mouse buttons on keyboard-and-mouse, not keys -- the "keyboard" bucket
	## key is kept for both (matching every other entry's two-way device
	## split) even though the icon itself is a mouse glyph.
	"quick": {"keyboard": "mouse_left.png", "gamepad": "xbox_button_a.png"},
	"charged": {"keyboard": "mouse_right.png", "gamepad": "xbox_button_x.png"},
	"throw": {"keyboard": "keyboard_f.png", "gamepad": "xbox_rb.png"},
	## `combat_run` binds to Escape/gamepad-B -- physically identical to
	## `cancel` above, so combat_hud.gd's Run AND Cancel verbs both reach for
	## the `cancel` id directly rather than this duplicating its two files.
}


static func using_gamepad() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var game: Node = tree.root.get_node_or_null(^"Game") if tree != null else null
	if game != null and game.has_method("last_input_was_gamepad"):
		return bool(game.call("last_input_was_gamepad"))
	# No Game autoload in this context (an isolated test harness, say) --
	# fall back to the old "is a pad connected" check rather than assume
	# keyboard, which was this function's only signal before HD1.
	return not Input.get_connected_joypads().is_empty()


## Inline BBCode image tag(s) for a glyph id, sized to sit on one text line.
## The caller's RichTextLabel needs `bbcode_enabled = true`. Falls back to the
## id itself in brackets for an unknown key, so a typo shows as broken text
## rather than a blank gap that reads as the icon loaded and was empty.
##
## Default 36, not 28: a blind critic still called `cancel`'s keyboard icon
## ("ESC", 3 letters baked into a 64px source) illegible mush at 28px after
## round 2 already swapped the two worse offenders (enter's 5-letter text,
## the combined arrows glyph) for simpler symbols. 28->36 was the smallest
## step that read clearly in a local crop test; every other glyph here is
## already simple enough that a larger render only helps it too.
static func icon(id: String, px: int = 36) -> String:
	if not GLYPHS.has(id):
		return "[%s]" % id
	var device := "gamepad" if using_gamepad() else "keyboard"
	var entry: Variant = GLYPHS[id][device]
	var files: Array = entry if entry is Array else [entry]
	var tags: Array[String] = []
	for file: String in files:
		tags.append("[img=%dx%d]%s%s[/img]" % [px, px, DIR, file])
	return "".join(tags)
