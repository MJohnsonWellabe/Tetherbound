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
	"creature_recall": {"keyboard": "keyboard_r.png", "gamepad": "xbox_dpad_up.png"},
	## The starting torch (owner playtest report: night is too dark, and the
	## player must have a torch from the beginning). Manual override on top of
	## `scripts/player/torch.gd`'s own automatic dusk/dawn behaviour.
	"torch_toggle": {"keyboard": "keyboard_l.png", "gamepad": "xbox_button_start.png"},
	## Combat's five verbs (`HD1`). `combat_quick`/`combat_charged` bind to
	## mouse buttons on keyboard-and-mouse, not keys -- the "keyboard" bucket
	## key is kept for both (matching every other entry's two-way device
	## split) even though the icon itself is a mouse glyph.
	##
	## D35 (Palworld parity): gamepad defaults sit on the triggers --
	## `quick`=RT, `charged`=LT -- to match Palworld's RT-attack/LT-aim.
	##
	## FORMERLY a known glyph collision: `quick`/`charged` used to borrow
	## `xbox_rb.png`/`xbox_lb.png` (the SHOULDER icons) because the vendored
	## set had no trigger PNGs, which made `quick`'s icon visually identical
	## to `throw`'s (both `xbox_rb.png`, two different physical buttons drawn
	## side by side in combat_hud.gd's Actions row) -- exactly the "on-screen
	## control instruction lies about its binding" defect a blind playtest
	## flagged directly. `xbox_lt.png`/`xbox_rt.png` were already sitting in
	## the vendored raw pack (`assets_raw/vendor/kenney_input-prompts/Xbox
	## Series/Default/`, same CC0 pack `xbox_lb.png`/`xbox_rb.png` came
	## from) and just needed extracting -- no new asset generation, no new
	## licence to track.
	"quick": {"keyboard": "mouse_left.png", "gamepad": "xbox_rt.png"},
	"charged": {"keyboard": "mouse_right.png", "gamepad": "xbox_lt.png"},
	"throw": {"keyboard": "keyboard_f.png", "gamepad": "xbox_rb.png"},
	## `combat_run` binds to Escape/gamepad-B -- physically identical to
	## `cancel` above, so combat_hud.gd's Run AND Cancel verbs both reach for
	## the `cancel` id directly rather than this duplicating its two files.

	## D32's `combat_switch_left`/`combat_switch_right` (mid-combat creature
	## switching -- the move grid's Switch cell and, tap-vs-hold, the party
	## selector). Shares files with `horizontal`'s own left/right pair rather
	## than vendoring anything new: same left/right keyboard arrows, same
	## gamepad d-pad icons `hotbar_2`/`hotbar_3` above already borrow for the
	## identical physical buttons.
	"switch_left": {"keyboard": "keyboard_arrow_left.png", "gamepad": "xbox_dpad_left.png"},
	"switch_right": {"keyboard": "keyboard_arrow_right.png", "gamepad": "xbox_dpad_right.png"},

	## HD2's quick-access hotbar. Five slots, each its own single direct
	## press on both devices (no select-then-confirm step) -- true parity is
	## what CLAUDE.md's "controller first" asks for, not keyboard getting a
	## one-press hotbar while a pad gets a slower cycle-and-confirm one.
	## Chosen from buttons nothing else in exploration reads: Y, LB and
	## D-pad left/right/down are all free (D-pad up is `creature_recall`; A/B/X
	## are jump/cancel/interact; RB and mouse-left/right are combat-only).
	"hotbar_1": {"keyboard": "keyboard_1.png", "gamepad": "xbox_button_y.png"},
	"hotbar_2": {"keyboard": "keyboard_2.png", "gamepad": "xbox_dpad_left.png"},
	"hotbar_3": {"keyboard": "keyboard_3.png", "gamepad": "xbox_dpad_right.png"},
	"hotbar_4": {"keyboard": "keyboard_4.png", "gamepad": "xbox_dpad_down.png"},
	"hotbar_5": {"keyboard": "keyboard_5.png", "gamepad": "xbox_lb.png"},

	## Build-system v2's five verbs (D34). Nothing calls `icon()` with these ids
	## yet -- build_placer.gd is a later milestone -- so these are wired ahead
	## of a caller, the same order combat's row was added in for HD1.
	"build_place": {"keyboard": "mouse_left.png", "gamepad": "xbox_button_x.png"},
	"build_cancel": {"keyboard": "mouse_right.png", "gamepad": "xbox_button_b.png"},
	## Defaults are mouse wheel up/down and gamepad LT/RT (project.godot).
	## Gamepad side now uses the real trigger glyphs (`xbox_lt.png`/
	## `xbox_rt.png`, extracted from the same already-vendored Kenney pack
	## `quick`/`charged` draw on above) -- these used to borrow the LB/RB
	## shoulder icons, which is wrong on its face for a trigger-bound action.
	## Keyboard/mouse side still has no wheel-icon PNG extracted (only
	## mouse_left/right ever were), so it keeps borrowing the arrow-key
	## icons as the closest shape already on disk; wheel glyphs are a PC-only
	## gap the controller-first playtest report did not raise.
	"build_rotate_left": {"keyboard": "keyboard_arrow_left.png", "gamepad": "xbox_lt.png"},
	"build_rotate_right": {"keyboard": "keyboard_arrow_right.png", "gamepad": "xbox_rt.png"},
	## Keyboard default is Shift, which has no vendored keycap PNG at all (the
	## Kenney sheet in assets/ui/input_prompts/ never had one extracted). Rather
	## than point it at an unrelated icon, this id is left gamepad-only; a
	## caller wanting the keyboard glyph should show the word "Shift" directly
	## until a real Shift PNG is vendored, the same way combat_hud.gd reaches
	## for the `cancel` id instead of a `combat_run` entry that was never added.
	"build_snap_cycle": {"gamepad": "xbox_dpad_down.png"},
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
## `tint`, if given, recolours the glyph itself via BBCode `[img]`'s own
## `color=` attribute -- added because a caller wrapping the whole verb
## (icon and label together) in an outer `[color=...]` tag does NOT reach
## the image, only the text: a real defect a blind visual-judge pass on
## `HD1` caught directly (combat's dimmed verbs showed a greyed-out label
## next to a still-fully-saturated icon, reading as broken rather than
## disabled).
## The current keyboard binding's display name for an action, for glyphless
## fallbacks: "Shift" for build_snap_cycle. Falls back to the action id when
## the action has no key event at all (then the caller's brackets at least
## name the verb).
static func _key_name_for_action(action: String) -> String:
	if not InputMap.has_action(action):
		return action
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			var text := key.as_text().trim_suffix(" (Physical)")
			if not text.is_empty():
				return text
	return action


static func icon(id: String, px: int = 36, tint: Color = Color.WHITE) -> String:
	if not GLYPHS.has(id):
		return "[%s]" % id
	var device := "gamepad" if using_gamepad() else "keyboard"
	# A glyph entry may cover only one device — build_snap_cycle has a pad
	# icon but no Shift keycap PNG exists to give it a keyboard one. Degrade
	# to the action's real bound key name ("[Shift]") rather than the raw
	# action id ("[BUILD_SNAP_CYCLE]"), which leaked into the build footer,
	# and instead of the hard indexing error smoke_free_build caught.
	if not (GLYPHS[id] as Dictionary).has(device):
		return "[%s]" % _key_name_for_action(id)
	var entry: Variant = GLYPHS[id][device]
	var files: Array = entry if entry is Array else [entry]
	var colour_attr := "" if tint == Color.WHITE else " color=#%s" % tint.to_html(true)
	var tags: Array[String] = []
	for file: String in files:
		tags.append("[img=%dx%d%s]%s%s[/img]" % [px, px, colour_attr, DIR, file])
	return "".join(tags)
