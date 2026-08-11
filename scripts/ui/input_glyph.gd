extends RefCounted

## Kenney Input Prompts glyphs for the handful of actions the narrative UI
## prompts for (dialogue, naming, the starter picker) -- EV9's first slice,
## replacing literal "[X] / [E]" bracket text with a real icon. Bible sec18.
##
## KNOWN LIMITATION, inherited from the bracket text this replaces rather than
## introduced by it: this maps each action's DEFAULT device binding
## (project.godot), not whatever the player rebound it to in tab_settings.gd.
## The bracket hints had the identical gap -- "[X] / [E]" never read
## key_bindings.gd either. Making this rebinding-aware needs that live
## InputMap lookup threaded through every call site, which is real work and a
## separate ship from "put an icon where a bracket used to be".
##
## Device is CONNECTED JOYPAD PRESENT, not last-input-used the way bible
## sec18 actually asks for (live switching as the player's hands move between
## keyboard and pad). That needs a shared observer reachable from every
## scene, and project.godot's own Game autoload comment is explicit that it
## means to stay the project's only singleton -- so this does not add a
## second one for a first slice. Correct for the primary target (the ROG
## Ally always has a pad connected) and honest about the gap rather than
## quietly pretending to solve it.

const DIR := "res://assets/ui/input_prompts/"

const GLYPHS := {
	"interact": {"keyboard": "keyboard_e.png", "gamepad": "xbox_button_x.png"},
	"confirm": {"keyboard": "keyboard_enter.png", "gamepad": "xbox_button_a.png"},
	"cancel": {"keyboard": "keyboard_escape.png", "gamepad": "xbox_button_b.png"},
	"horizontal": {"keyboard": "keyboard_arrows_horizontal.png", "gamepad": "xbox_dpad_horizontal.png"},
}


static func using_gamepad() -> bool:
	return not Input.get_connected_joypads().is_empty()


## Inline BBCode image tag for a glyph id, sized to sit on one text line.
## The caller's RichTextLabel needs `bbcode_enabled = true`. Falls back to the
## id itself in brackets for an unknown key, so a typo shows as broken text
## rather than a blank gap that reads as the icon loaded and was empty.
static func icon(id: String, px: int = 28) -> String:
	if not GLYPHS.has(id):
		return "[%s]" % id
	var device := "gamepad" if using_gamepad() else "keyboard"
	var file: String = GLYPHS[id][device]
	return "[img=%dx%d]%s%s[/img]" % [px, px, DIR, file]
