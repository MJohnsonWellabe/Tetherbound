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
	## CONTROLLER-MAP (owner directive, 2026-08-22) re-authored the whole pad
	## map, so several entries below moved. The map is now: A jump, B hotbar 1,
	## X interact/place/throw, Y satchel (dismantle in build mode), View map,
	## Menu the game menu, L3 sprint, R3 recentre, LB cycle party member, RB
	## call out / put away, LT/RT charged/quick attack, d-pad left/up/right/down
	## hotbar 2-5. Torch and the build hammer are hotbar tools and have no pad
	## button at all any more, which is why their gamepad halves are gone.
	"interact": {"keyboard": "keyboard_e.png", "gamepad": "xbox_button_x.png"},
	"confirm": {"keyboard": "keyboard_return.png", "gamepad": "xbox_button_a.png"},
	"cancel": {"keyboard": "keyboard_escape.png", "gamepad": "xbox_button_b.png"},
	"horizontal": {
		"keyboard": ["keyboard_arrow_left.png", "keyboard_arrow_right.png"],
		"gamepad": ["xbox_dpad_left.png", "xbox_dpad_right.png"],
	},
	"creature_recall": {"keyboard": "keyboard_r.png", "gamepad": "xbox_rb.png"},
	## RG3's persistent exploration legend. These are the existing live
	## inventory/map actions (project.godot), not a second HUD-only binding
	## table. The three keycaps below come from the same vendored CC0 Kenney
	## Input Prompts pack as every neighbouring entry.
	"inventory": {"keyboard": "keyboard_i.png", "gamepad": "xbox_button_y.png"},
	"map": {"keyboard": "keyboard_m.png", "gamepad": "xbox_button_view.png"},
	# Full-map-only controls. Keyboard falls back to the live `=` / `-` key
	# names because the vendored keycap subset has no plus/minus art; controller
	# uses the exact trigger glyphs the dedicated actions bind.
	"map_zoom_in": {"gamepad": "xbox_rt.png"},
	"map_zoom_out": {"gamepad": "xbox_lt.png"},
	## The starting torch (owner playtest report: night is too dark, and the
	## player must have a torch from the beginning). Manual override on top of
	## `scripts/player/torch.gd`'s own automatic dusk/dawn behaviour.
	##
	## CONTROLLER-MAP: keyboard-only now. The owner's map has no torch button
	## ("torch doesn't need a button") -- the torch is a tool the player picks
	## on the hotbar, so the pad half was retired rather than moved. L stays
	## for a desktop player; R3 became `camera_recenter`.
	"torch_toggle": {"keyboard": "keyboard_l.png"},
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
	## CONTROLLER-MAP: the orb is selected on the hotbar and thrown with
	## interact, so the pad glyph is X, the same button `interact` draws.
	"throw": {"keyboard": "keyboard_f.png", "gamepad": "xbox_button_x.png"},
	## `combat_run` binds to Escape/gamepad-B -- physically identical to
	## `cancel` above, so combat_hud.gd's Run AND Cancel verbs both reach for
	## the `cancel` id directly rather than this duplicating its two files.

	## CONTROLLER-MAP collapsed D32's two directional switch actions into one
	## `party_cycle` press on LB -- which is what gave the d-pad back to the
	## hotbar during a fight. One glyph, therefore, not a left/right pair. No
	## keyboard entry: `party_cycle` is bound to C and no C keycap has been
	## extracted from the Kenney pack, so a desktop player gets `icon()`'s
	## "[C]" fallback, read live off the InputMap.
	"party_cycle": {"gamepad": "xbox_lb.png"},

	## HD2's quick-access hotbar. Five slots, each its own single direct
	## press on both devices (no select-then-confirm step) -- true parity is
	## what CLAUDE.md's "controller first" asks for, not keyboard getting a
	## one-press hotbar while a pad gets a slower cycle-and-confirm one.
	## Chosen from buttons nothing else in exploration reads: LB and D-pad
	## left/right/down are all free (D-pad up is `creature_recall`; A/B/X/Y
	## are jump/cancel/interact/inventory; RB and mouse-left/right were
	## combat-only).
	##
	## CONTROLLER-MAP: slot 1 is B and slots 2-5 are the d-pad read clockwise
	## from the left (left, up, right, down), in EVERY context including a
	## fight. Nothing else on the pad reads those five buttons in the world any
	## more, which is the whole point of the re-author: food and orbs stay
	## reachable mid-fight, and the OF21-era "these can never both mean
	## something at the same moment" arguments are no longer load-bearing
	## because there is no longer a second reader to argue about.
	"hotbar_1": {"keyboard": "keyboard_1.png", "gamepad": "xbox_button_b.png"},
	"hotbar_2": {"keyboard": "keyboard_2.png", "gamepad": "xbox_dpad_left.png"},
	"hotbar_3": {"keyboard": "keyboard_3.png", "gamepad": "xbox_dpad_up.png"},
	"hotbar_4": {"keyboard": "keyboard_4.png", "gamepad": "xbox_dpad_right.png"},
	"hotbar_5": {"keyboard": "keyboard_5.png", "gamepad": "xbox_dpad_down.png"},

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
	"build_snap_cycle": {"gamepad": "xbox_dpad_up.png"},
	"build_dismantle": {"keyboard": "keyboard_b.png", "gamepad": "xbox_button_y.png"},

	## OF21 input groundwork, wired for real by OF24: `playground_hud.gd`'s
	## `_read_world_hotkeys()` reads both straight from the world -- `build_open`
	## opens the build menu without a trip through the pause menu first, and
	## `torch_place` drew or stowed a free ground torch directly, the same
	## "wired ahead of a caller" pattern `build_place`/`build_cancel` used
	## above, finally given its caller. OW12 retired the ground torch;
	## `torch_place` now equips/stows the carried torch tool instead
	## (`playground_hud.gd::_arm_torch_placement`), same button, same
	## everything below.
	##
	## CONTROLLER-MAP: both are keyboard-only now. The build hammer and the
	## torch became hotbar tools -- select the tool, press interact -- so
	## neither keeps a pad button. Start/Menu went to `game_menu` and RT went
	## to `combat_quick` alone.
	"build_open": {"keyboard": "keyboard_b.png"},
	"torch_place": {"keyboard": "keyboard_p.png"},
	"game_menu": {"keyboard": "keyboard_escape.png", "gamepad": "xbox_button_start.png"},

	## OW1: the backpack's three own verbs, so its detail column can draw them
	## instead of listing "Drop" and "Split" as bare words with no button
	## attached -- the owner could not work out how to move a stack, and the one
	## place that would have told him was naming verbs without naming buttons.
	##
	## The keyboard defaults are G/H/J. When OW1 landed, the vendored Kenney
	## keycap sheet had no G, H or J PNG, so all three fell through `icon()`'s
	## own missing-device path to "[G]" / "[H]" / "[J]" -- read off the
	## InputMap, so a rebind in Settings cannot leave the legend lying. Same
	## treatment `build_snap_cycle` above already gets for Shift.
	##
	## PT-17 then sourced `keyboard_h.png` fresh from that same raw Kenney pack
	## (`docs/ASSET_LEDGER.md`) for its own rename verb, which reuses this same
	## `backpack_split` binding (H / gamepad R3) rather than adding a new
	## action -- see `tab_creatures.gd`'s own header for why borrowing beats a
	## second action, and `torch_toggle` above for R3's other, mutually
	## exclusive, world-context reader. So `backpack_split` gets real keyboard
	## art now; `backpack_drop` (G) and `backpack_assign` (J) still have none
	## and stay on the bracket-letter fallback until one is sourced for them
	## too.
	##
	## Files are reused, not new: Start is `backpack_drop`'s real button
	## (see data/config/menu.json's "Backpack" group note), R3 is
	## `backpack_split`'s. `backpack_assign` has no art at all: it went Y -> X ->
	## L3 in CONTROLLER-MAP (Y is `inventory`, X is the satchel's own Use verb,
	## and both are live on that tab at the same time), and L3 has no glyph.
	"backpack_drop": {"gamepad": "xbox_button_start.png"},
	"backpack_split": {"keyboard": "keyboard_h.png", "gamepad": "xbox_stick_r_press.png"},
	## CONTROLLER-MAP: `backpack_assign` is L3 / J. No left-stick-press PNG has
	## been extracted from the Kenney pack and no J keycap either, so the entry
	## is deliberately EMPTY: listing the id keeps `icon()` off its
	## "[backpack_assign]" unknown-id path and onto the "[J]" bound-key
	## fallback `build_snap_cycle` already uses for Shift.
	"backpack_assign": {},
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
##
## Public because the pause menu's footer needs the same answer for a plain
## Label that cannot draw a glyph at all — and needs it read off the InputMap
## rather than typed out, since the Settings tab lets the player move these.
static func key_name_for_action(action: String) -> String:
	if not InputMap.has_action(action):
		return action
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			# Godot 4.7 marks a physical binding as "Q - Physical", not the
			# "Q (Physical)" this line was written against — and only for keys
			# whose physical and logical layouts can differ, so "Enter" and
			# "Escape" came back clean and nothing noticed. Both forms are
			# trimmed rather than the current one only, because this string is
			# an engine display detail and has already moved once.
			var text := key.as_text().trim_suffix(" (Physical)").trim_suffix(" - Physical")
			if not text.is_empty():
				return text
	return action


## `device`, when given ("keyboard" or "gamepad"), overrides the auto-detected
## one. Added for OW1: the backpack's verb legend has to name BOTH halves of a
## dual binding the way the pause menu's own footer does ("Enter / A"), and a
## blind usability pass on a seven-inch proxy read the auto-detected single
## half as "this action has no controller binding at all". Auto-detection is
## still the default and still right for a legend with room for one glyph.
static func icon(id: String, px: int = 36, tint: Color = Color.WHITE, device_override: String = "") -> String:
	if not GLYPHS.has(id):
		return "[%s]" % id
	var device := device_override
	if device.is_empty():
		device = "gamepad" if using_gamepad() else "keyboard"
	# A glyph entry may cover only one device — build_snap_cycle has a pad
	# icon but no Shift keycap PNG exists to give it a keyboard one. Degrade
	# to the action's real bound key name ("[Shift]") rather than the raw
	# action id ("[BUILD_SNAP_CYCLE]"), which leaked into the build footer,
	# and instead of the hard indexing error smoke_free_build caught.
	if not (GLYPHS[id] as Dictionary).has(device):
		return "[%s]" % key_name_for_action(id)
	var entry: Variant = GLYPHS[id][device]
	var files: Array = entry if entry is Array else [entry]
	var colour_attr := "" if tint == Color.WHITE else " color=#%s" % tint.to_html(true)
	var tags: Array[String] = []
	for file: String in files:
		tags.append("[img=%dx%d%s]%s%s[/img]" % [px, px, colour_attr, DIR, file])
	return "".join(tags)
