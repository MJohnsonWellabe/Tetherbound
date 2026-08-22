extends "res://tests/test_case.gd"

## Static enforcement for the INPUT-OWNER defect class (OW10 / OP21-03 /
## OP21-06): a world-verb poller that reads a d-pad action Godot's own
## `ui_*` focus navigation ALSO drives, without first asking
## `input_owner.gd` who owns input right now.
##
## `scripts/combat/encounter_director.gd::_read_creature_control_input()`
## was exactly this bug: it read the directional creature-switch actions
## (then on gamepad d-pad left/right, joypad buttons 13/14 -- the same
## physical d-pad `ui_left`/`ui_right` drive Control focus with)
## unconditionally, with no call anywhere near `INPUT_OWNER.current()`.
## CONTROLLER-MAP has since merged those two actions into one `party_cycle`
## press on LB, so the d-pad now carries the hotbar and nothing else -- but
## the hotbar actions are still on it, so this check still has work to do. A
## text-scanning test rather than another behavioral smoke test on purpose:
## `smoke_build_owns_creature_cycle.gd` (this same task) proves the ONE
## regression the owner reported actually reproduces and stays fixed, but a
## behavioral test only ever proves the case it was written for. This file
## is the shared-layer guarantee CLAUDE.md's "systemic architecture defect
## class, not one more `if`" asks for: it fails on ANY future function added
## to the files below that reads one of these actions and forgets the
## check, not only on the one the owner happened to hit.
##
## ## Scope and the tradeoff taken
##
## Enforcement is scoped to the two scripts that are Tetherbound's only
## ALWAYS-ON exploration-tier pollers -- nodes that run continuously during
## ordinary unpaused exploration, where a non-pausing modal (Build) can
## genuinely be up at the same time:
##
##   - `scripts/ui/playground_hud.gd` (the hotbar and world-hotkey polls)
##   - `scripts/combat/encounter_director.gd` (creature-control/engage)
##
## `scripts/ui/combat_hud.gd` also reads `party_cycle`
## (mid-fight creature switching), but only from inside a block its own
## `_process` gates on `is_fighting` -- and both `game_menu.gd` and the
## world hotkey that opens Build are themselves gated off during a fight
## (see `game_menu.gd::_refusal_reason()` and
## `playground_hud.gd::_world_input_allowed()`'s combat check), so a modal
## structurally cannot be up at the same time that poll runs. It is
## deliberately left out of `POLLER_FILES` rather than made to satisfy a
## check that does not apply to it.
##
## This is a real, stated tradeoff, not an oversight: a brand-new
## THIRD always-on exploration poller, in some file this list does not
## name, reading one of these actions would NOT be caught here. Tetherbound
## has exactly two such nodes today (one HUD, one encounter director) by
## design -- there is one always-on world HUD and one always-on encounter
## director scene-wide -- so the list is small and stable, not a growing
## hand-maintained burden, and CLAUDE.md prefers the smallest coherent fix
## over a large framework. If a third always-on poller is ever added, add
## its path to `POLLER_FILES` in the same commit -- the same discipline
## `input_owner.gd`'s own header already asks of every non-pausing panel.
##
## Colliding actions themselves are NOT hand-picked: they are parsed fresh
## from `project.godot` every run, keyed on the physical buttons
## (joypad 11/12/13/14 -- the whole d-pad) that collide with Godot's
## built-in `ui_up`/`ui_down`/`ui_left`/`ui_right` focus navigation, so a
## future rebind that moves a new action onto that d-pad is caught
## automatically without anyone updating this file.
##
## The complementary check -- two actions that are BOTH live in the same
## context and BOTH on one button, which no amount of `input_owner.gd`
## discipline would have caught -- is `tests/test_input_context_collisions.gd`.

const POLLER_FILES := [
	"res://scripts/ui/playground_hud.gd",
	"res://scripts/combat/encounter_director.gd",
]

## project.godot: joypad button_index for d-pad down/left/right -- the three
## physical buttons Godot's built-in `ui_down`/`ui_left`/`ui_right` bind to
## by default, and therefore the ones any custom action sharing them can
## silently steal focus navigation from. `input_owner.gd`'s own file header
## documents this for the hotbar leak. `ui_up` (button 11) joined the list
## in CONTROLLER-MAP, which put `hotbar_3` there -- before that no action
## was bound to it and it was omitted rather than included for symmetry.
const COLLIDING_JOYPAD_BUTTONS := [11, 12, 13, 14]


func test_project_dpad_actions_actually_parse() -> void:
	# If this parses to nothing, the regex broke and every check below would
	# pass for the wrong reason -- silently testing nothing. Guard it the
	# same way `smoke_menu_owns_dpad.gd` guards its own "does the hotbar
	# even fire" precondition.
	var colliding := _colliding_actions()
	assert_true(colliding.size() >= 2, "expected multiple project.godot actions bound to the shared d-pad buttons, got %s -- the parser or project.godot's format changed" % str(colliding))
	assert_true(colliding.has("hotbar_2"), "known d-pad-left action hotbar_2 did not parse")


func test_exploration_pollers_check_input_owner_before_reading_shared_dpad_actions() -> void:
	var colliding := _colliding_actions()
	for path in POLLER_FILES:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.is_empty(), "%s could not be read" % path)
		if text.is_empty():
			continue
		var functions := _split_into_functions(text)
		for func_name in functions.keys():
			var body: String = functions[func_name]
			var reads := _actions_read_by(body, text)
			var reads_colliding_action := ""
			for action in colliding:
				if reads.has(action):
					reads_colliding_action = action
					break
			if reads_colliding_action.is_empty():
				continue
			if not _consults_input_owner(func_name, functions):
				_fail(
					"%s :: %s() reads '%s', which shares a physical d-pad button with Godot's ui_* focus navigation (project.godot), but neither it nor a function it calls consults INPUT_OWNER.current() -- this is the exact OW10/OP21-03 collision class" % [
						path, func_name, reads_colliding_action,
					]
				)


## What action name(s) does a call to `is_action_just_pressed`/
## `is_action_pressed` inside `body` actually resolve to?
##
## Three shapes are handled, because `POLLER_FILES` uses all three:
##
##   1. a literal argument -- `is_action_just_pressed("creature_recall")`
##      (`encounter_director.gd::_read_creature_control_input`)
##   2. an array-indexed identifier -- `is_action_just_pressed(HOTBAR_ACTIONS[i])`
##      (`playground_hud.gd::_read_hotbar_input`) -- resolved by finding
##      `HOTBAR_ACTIONS`'s own `:=  [...]` declaration anywhere in the file
##      and reading its literal elements.
##   3. anything else (a bare local variable) -- falls back to every literal
##      action name that appears anywhere else in the same function body,
##      which covers a value built by a local ternary/branch a few lines
##      above the call, at the cost of being slightly permissive about
##      exactly which literal fed which call. Good enough for a check that
##      only needs "was this action name anywhere near an is_action call in
##      this function", not a precise data-flow proof.
func _actions_read_by(body: String, file_text: String) -> Array[String]:
	var out: Array[String] = []
	var call_re := RegEx.new()
	call_re.compile("is_action_(?:just_)?pressed\\(\\s*([^)]+?)\\s*\\)")
	var lit_re := RegEx.new()
	lit_re.compile("&?\"([a-zA-Z0-9_]+)\"")
	var idx_re := RegEx.new()
	idx_re.compile("^(\\w+)\\s*\\[")
	var any_call := false
	for m in call_re.search_all(body):
		any_call = true
		var expr: String = m.get_string(1)
		var direct := lit_re.search(expr)
		if direct:
			out.append(direct.get_string(1))
			continue
		var idx_m := idx_re.search(expr)
		if idx_m:
			var ident: String = idx_m.get_string(1)
			var decl_re := RegEx.new()
			decl_re.compile("(?s)%s\\s*:=\\s*\\[(.*?)\\]" % ident)
			var decl := decl_re.search(file_text)
			if decl != null:
				for lm in lit_re.search_all(decl.get_string(1)):
					out.append(lm.get_string(1))
	# Shape 3: a bare local variable. Rather than trace its assignment,
	# every literal in the function is in scope for "was a colliding action
	# read here" once we know at least one is_action call happened.
	if any_call:
		for lm in lit_re.search_all(body):
			out.append(lm.get_string(1))
	return out


## True if `func_name`'s own body mentions INPUT_OWNER, or it calls (one hop)
## another function in the same file whose body does. One hop is enough for
## every poller in `POLLER_FILES` today -- both route through a single named
## gate (`_world_input_allowed()`, `_read_creature_control_input`'s own
## direct check) -- and going further would be call-graph tracing this task
## explicitly asked not to build.
func _consults_input_owner(func_name: String, functions: Dictionary) -> bool:
	var body: String = functions[func_name]
	if body.contains("INPUT_OWNER"):
		return true
	var call_re := RegEx.new()
	call_re.compile("\\b(\\w+)\\s*\\(")
	for m in call_re.search_all(body):
		var called: String = m.get_string(1)
		if called == func_name:
			continue
		if functions.has(called) and (functions[called] as String).contains("INPUT_OWNER"):
			return true
	return false


## Splits a GDScript file into {function_name: body_text_including_signature},
## by `\nfunc `. Good enough for this file's purpose -- it does not need to
## understand nested classes or lambdas, only to find named top-level
## functions and read what they call.
func _split_into_functions(text: String) -> Dictionary:
	var out: Dictionary = {}
	var func_re := RegEx.new()
	func_re.compile("(?m)^func\\s+(\\w+)\\s*\\(")
	var matches := func_re.search_all(text)
	for i in matches.size():
		var m := matches[i]
		var name: String = m.get_string(1)
		var start: int = m.get_start()
		var end: int = text.length() if i == matches.size() - 1 else matches[i + 1].get_start()
		out[name] = text.substr(start, end - start)
	return out


## DPAD-COLLISION. `test_exploration_pollers_check_input_owner_before_reading_shared_dpad_actions`
## above proves every poller that reads a shared d-pad action first asks
## `INPUT_OWNER`. It does NOT prove the two actions sharing a button are
## actually safe to share it -- `hotbar_2`/`hotbar_3` and
## `combat_switch_left`/`combat_switch_right` (project.godot: both pairs on
## joypad 13/14) each independently consulted `INPUT_OWNER` correctly and the
## test above stayed green throughout, because `INPUT_OWNER` only answers
## "does some OTHER panel own input right now" -- it has no opinion on
## whether TWO exploration-tier pollers are reading the same physical button
## at the same time as each other. They were, during plain exploration with
## no panel open at all, and one d-pad press fired both a hotbar slot and a
## party cycle.
##
## This is that second, previously-unproven guarantee: no two actions live in
## the SAME context share a physical joypad button. `ACTION_CONTEXT` is the
## hand-classified answer to "when can this action actually fire" a full
## action-map audit produced (see this task's own report for the reasoning
## behind every entry) -- project.godot's text alone cannot express that,
## since it is code (gating checks scattered across pollers) that decides it,
## not config. Two actions in DIFFERENT (mutually exclusive) contexts sharing
## a button is the legitimate, common reuse pattern this project relies on
## throughout (`hotbar_4`/`build_rotate`, `creature_recall`/
## `build_snap_cycle`, `torch_toggle`/`backpack_split`, `tool_cycle`/
## `hotbar_5`, ...); two actions in the SAME context sharing one is the
## defect class this file exists to catch.
const ACTION_CONTEXT := {
	# exploration: unconditional during ordinary play, or gated only by
	# `playground_hud.gd::_world_input_allowed()` / the equivalent checks in
	# `encounter_director.gd::_read_creature_control_input()` (a fight, the
	# arbiter disabled, or a panel in INPUT_OWNER's group) -- genuinely live
	# with nothing else open.
	"jump": "exploration",
	"sprint": "exploration",
	"interact": "exploration",
	"inventory": "exploration",
	"map": "exploration",
	"creature_recall": "exploration",
	"combat_switch_left": "exploration",
	"combat_switch_right": "exploration",
	"torch_toggle": "exploration",
	"build_open": "exploration",
	"torch_place": "exploration",
	"use_tool": "exploration",
	# CONTROLLER-MAP: LB, read by `encounter_director.gd::_read_creature_control_input()`
	# (guarded off mid-fight) AND by `combat_hud.gd::_handle_switch_input()`
	# (combat only) -- the same "cycle party member" verb in both contexts,
	# never both at once. Classified here rather than under "combat" because
	# it consolidated the old `combat_switch_left`/`combat_switch_right` pair,
	# which lived in this section.
	"party_cycle": "exploration",
	# CONTROLLER-MAP: R3, read continuously by `camera_rig.gd` during live
	# play, paused-panel-independent like the rest of this section.
	"camera_recenter": "exploration",
	"hotbar_1": "exploration",
	"hotbar_2": "exploration",
	"hotbar_3": "exploration",
	"hotbar_4": "exploration",
	"hotbar_5": "exploration",

	# combat: read only while `CombatManager.is_fighting()` (or the
	# trainer-battle equivalent) is true -- mutually exclusive with
	# "exploration" and "build" below, since neither ordinary movement/build
	# state exists mid-fight.
	"combat_quick": "combat",
	"combat_charged": "combat",
	"combat_throw": "combat",
	"combat_run": "combat",

	# build: read only while a ghost is armed (`build_placer.gd`:
	# `pending_build != ""`), itself further gated by INPUT_OWNER --
	# mutually exclusive with "exploration" (`sequence_director.gd` disables
	# the arbiter, and `_world_input_allowed()`'s own check, while building)
	# and with "combat" (a fight cannot start with a ghost armed).
	"build_place": "build",
	"build_cancel": "build",
	"build_rotate_left": "build",
	"build_rotate_right": "build",
	"build_snap_cycle": "build",
	"build_rotate": "build",
	"build_dismantle": "build",

	# menu: read only from inside a tree-paused panel, or by the pause shell
	# itself deciding whether to open/close/switch tabs -- mutually exclusive
	# with everything above because a paused tree stops every exploration
	# poller outright, and the shell's own shortcut/open reads explicitly
	# stand aside for a live build ghost (`game_menu.gd::_read_actions()`).
	"ui_accept": "menu",
	"menu_confirm": "menu",
	"menu_cancel": "menu",
	"menu_tab_right": "menu",
	# CONTROLLER-MAP: LB, the same "step tab/category left" verb
	# `menu_tab_right` steps right for, read by both the pause shell
	# (`game_menu.gd::_read_actions`) and build_menu.gd's category cycling --
	# see `menu_tab_right`'s own entry above.
	"menu_tab_left": "menu",
	"tool_cycle": "menu",
	"backpack_drop": "menu",
	"backpack_split": "menu",
	"backpack_assign": "menu",
	# CONTROLLER-MAP: gamepad Menu, `game_menu.gd::_read_actions`'s own
	# `open_action` -- "by the pause shell itself deciding whether to open"
	# per this section's header comment.
	"game_menu": "menu",
}


## A new action added to project.godot's `[input]` block with a joypad event
## and left out of `ACTION_CONTEXT` above would otherwise silently skip the
## collision check below rather than fail it -- exactly the shape of gap that
## let `combat_switch_left`/`combat_switch_right` reach exploration without
## ever being checked against the hotbar. This fails loudly instead.
func test_every_joypad_bound_action_is_classified() -> void:
	var by_button := _actions_by_joypad_button()
	var unclassified: Array[String] = []
	for actions in by_button.values():
		for action: String in actions:
			if not ACTION_CONTEXT.has(action) and not unclassified.has(action):
				unclassified.append(action)
	assert_true(
		unclassified.is_empty(),
		"project.godot binds a joypad button for %s, which ACTION_CONTEXT does not classify -- add it (with the same reasoning every other entry carries) before this check can trust it is safe" % str(unclassified)
	)


## `ui_accept`/`menu_confirm` (joypad button 0, both "menu") is the one
## deliberate exception: project.godot's own UI-PAD1 comment on `ui_accept`
## says outright that sharing A with `menu_confirm` is intentional, not a
## collision -- both mean "confirm" on the same screen, read by two different
## systems (a focused `Button`'s built-in `ui_accept`, and this project's own
## `menu_confirm` poll) rather than two DIFFERENT verbs racing for one press.
## Pressing A does the one thing the player expects either way; there is no
## second, unrelated effect to hide. Every other pair this test finds in the
## same context is exactly that second, unrelated-effect shape, which is why
## this is a one-entry exception list and not a way to silence a real find.
##
## `game_menu`/`backpack_drop` (joypad button 6, both "menu") is the second:
## `game_menu.gd::_read_actions()`'s own CONTROLLER-MAP comment says the
## sharing is deliberate -- gamepad Menu opens the shell (read only while
## unpaused) and is reused as `backpack_drop` inside the satchel tab (read
## only while that tab is open, tree paused). One is never live while the
## other is; a real close verb was kept off this button for exactly that
## reason ("Menu could not also close it").
const ALLOWED_SAME_CONTEXT_PAIRS := [
	["ui_accept", "menu_confirm"],
	["game_menu", "backpack_drop"],
]


func _is_allowed_same_context_pair(a: String, b: String) -> bool:
	for pair in ALLOWED_SAME_CONTEXT_PAIRS:
		if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
			return true
	return false


## The actual guarantee: no two actions classified into the SAME context
## share a physical joypad button. Fails with the exact button and pair on a
## real collision, the same way the OP21-06 fix would have if this had
## existed then.
func test_no_two_same_context_actions_share_a_joypad_button() -> void:
	var by_button := _actions_by_joypad_button()
	for button in by_button.keys():
		var actions: Array = by_button[button]
		if actions.size() < 2:
			continue
		for i in actions.size():
			for j in range(i + 1, actions.size()):
				var a: String = actions[i]
				var b: String = actions[j]
				if not ACTION_CONTEXT.has(a) or not ACTION_CONTEXT.has(b):
					continue # already failed by test_every_joypad_bound_action_is_classified
				if _is_allowed_same_context_pair(a, b):
					continue
				if ACTION_CONTEXT[a] == ACTION_CONTEXT[b]:
					_fail(
						"'%s' and '%s' both bind joypad button %d and are BOTH classified '%s' -- two world verbs live in the same context share one physical button, the exact OP21-06/DPAD-COLLISION defect class (a press of that button fires both, with no way to press only one)" % [
							a, b, int(button), ACTION_CONTEXT[a],
						]
					)


## Every action->button pair in project.godot's `[input]` block, grouped by
## button. Separate from `_colliding_actions()` above (which only cares about
## the three d-pad buttons Godot's own `ui_*` focus navigation uses) -- this
## one needs the full table, every button, for the general cross-context
## check above.
func _actions_by_joypad_button() -> Dictionary:
	var text := FileAccess.get_file_as_string("res://project.godot")
	var out: Dictionary = {}
	var block_re := RegEx.new()
	block_re.compile("(?ms)^(\\w+)=\\{(.*?)\\n\\}")
	var button_re := RegEx.new()
	button_re.compile("InputEventJoypadButton[^)]*\"button_index\"\\s*:\\s*(\\d+)")
	for block in block_re.search_all(text):
		var name: String = block.get_string(1)
		var body: String = block.get_string(2)
		for bm in button_re.search_all(body):
			var button := int(bm.get_string(1))
			if not out.has(button):
				out[button] = []
			if not (out[button] as Array).has(name):
				(out[button] as Array).append(name)
	return out


## Parses `project.godot`'s `[input]` block fresh on every run -- see the
## file header on why this is deliberately not a hand-maintained list.
func _colliding_actions() -> Array[String]:
	var text := FileAccess.get_file_as_string("res://project.godot")
	var out: Array[String] = []
	var block_re := RegEx.new()
	block_re.compile("(?ms)^(\\w+)=\\{(.*?)\\n\\}")
	var button_re := RegEx.new()
	button_re.compile("InputEventJoypadButton[^)]*\"button_index\"\\s*:\\s*(\\d+)")
	for block in block_re.search_all(text):
		var name: String = block.get_string(1)
		var body: String = block.get_string(2)
		for bm in button_re.search_all(body):
			if int(bm.get_string(1)) in COLLIDING_JOYPAD_BUTTONS:
				out.append(name)
				break
	return out
