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
