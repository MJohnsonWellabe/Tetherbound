extends "res://tests/test_case.gd"

## Two live verbs may not share one physical controller input.
##
## This is the check the d-pad collision needed and did not have.
## `tests/test_world_verb_input_owner_enforcement.gd` asks a different, also
## useful question -- does a world-verb poller consult `input_owner.gd` before
## reading a d-pad action -- and it cannot answer this one. D32's
## `combat_switch_left` and HD2's `hotbar_2` were both correctly gated, both
## legitimately live during a fight, and both bound to joypad button 13. Every
## gate in the project was satisfied and one press still did two things. The
## owner found it by playing.
##
## So: `data/config/input_contexts.json` says which actions are live together,
## `project.godot` says what they are bound to, and this file crosses the two.
## The declaration is the useful artefact -- it is the only place in the repo
## that answers "what else does this button do right now?" without reading six
## comment blocks -- which is why it is config rather than a const in here.
##
## ## What this does NOT check
##
## Keyboard bindings. The 2026-08-22 directive is about the pad, keyboard keeps
## separate keys for verbs the pad retired (torch on L, the build hammer on B),
## and a desktop player has a hundred keys rather than fourteen buttons. A
## keyboard pass would need its own declaration of what "live" means there.
##
## It also cannot tell whether the declaration is TRUE -- whether the satchel
## tab really does read `backpack_split` and really is the only tab that does.
## Every entry cites the code it came from in its own `_comment`, and the
## coverage assertion below at least stops an action being added with nowhere
## declared. A wrong declaration is still possible; an undeclared one is not.

const CONTEXTS_PATH := "res://data/config/input_contexts.json"
const PROJECT_PATH := "res://project.godot"


func test_the_declaration_and_the_input_map_both_parse() -> void:
	# Neither half is hand-typed here, so if either parser breaks, every check
	# below passes for the wrong reason. This is the guard against that.
	var bindings := _pad_bindings()
	assert_true(bindings.size() >= 30, "expected project.godot's [input] section to yield 30+ actions, got %d -- the parser or the file format changed" % bindings.size())
	assert_eq(str(bindings.get("hotbar_2", "")), "pad:13", "hotbar_2 should parse as d-pad left")
	assert_eq(str(bindings.get("combat_quick", "")), "axis:5:+", "combat_quick should parse as RT")

	var declared := _contexts()
	assert_true(declared.size() >= 5, "expected several declared contexts, got %d" % declared.size())
	assert_true(declared.has("combat"), "the combat context is the one the d-pad bug lived in; it must be declared")


func test_every_action_is_declared_live_somewhere() -> void:
	var bindings := _pad_bindings()
	var config := _config()
	var seen: Dictionary = {}
	for context in _contexts().values():
		for action: String in context:
			seen[action] = true
	for action: String in config.get("context_free", []):
		seen[action] = true

	for action: String in bindings.keys():
		assert_true(seen.has(action), "project.godot binds '%s' but data/config/input_contexts.json never says where it is live -- add it to a context, or to `context_free` with a reason" % action)


func test_no_declared_action_has_gone_missing_from_the_input_map() -> void:
	var bindings := _pad_bindings()
	for name: String in _contexts().keys():
		for action: String in _contexts()[name]:
			assert_true(bindings.has(action), "context '%s' declares '%s', which project.godot has no action for -- a rename left the declaration stale" % [name, action])


func test_no_two_live_actions_share_a_joypad_input() -> void:
	var bindings := _pad_bindings()
	var alias_of := _alias_groups()

	for name: String in _contexts().keys():
		var by_code: Dictionary = {}
		var actions: Array = _contexts()[name]
		actions.sort()
		for action: String in actions:
			var code := str(bindings.get(action, ""))
			# An action with no pad binding at all cannot collide on one. Those
			# are real and deliberate: CONTROLLER-MAP took the pad button off
			# the torch, the build hammer, the tool swing, flee and the throw.
			if code.is_empty():
				continue
			if not by_code.has(code):
				by_code[code] = action
				continue
			var other := str(by_code[code])
			if alias_of.get(action, action) == alias_of.get(other, other):
				continue
			_fail(
				"context '%s': '%s' and '%s' are both live and both bound to %s. One press, two verbs. Held-button chords are banned (ralph/OWNER_DIRECTIVES_2026-08-22.md section 1), so the fix is to move or merge a verb, not to make one of them a hold." % [
					name, other, action, _human(code),
				]
			)


# --- reading the two files --------------------------------------------------


## action -> the ONE joypad binding code it has, in the same "pad:N" /
## "axis:N:+" spelling `scripts/ui/key_bindings.gd::code()` uses, so the two
## halves of the project agree on what identity means for a binding.
##
## Parsed out of `project.godot`'s text rather than read off the live
## `InputMap`, for the same reason `key_bindings.gd` snapshots the defaults:
## the InputMap in a running game already has the player's overrides applied,
## and this is a check on what the game SHIPS with.
func _pad_bindings() -> Dictionary:
	var text := FileAccess.get_file_as_string(PROJECT_PATH)
	var out: Dictionary = {}
	var section := text.substr(text.find("[input]"))
	var action_re := RegEx.new()
	action_re.compile("(?m)^([a-z_][a-z0-9_]*)=\\{")
	var button_re := RegEx.new()
	button_re.compile("InputEventJoypadButton[^)]*\"button_index\":(\\d+)")
	var motion_re := RegEx.new()
	motion_re.compile("InputEventJoypadMotion[^)]*\"axis\":(\\d+),\"axis_value\":(-?[\\d.]+)")

	var matches := action_re.search_all(section)
	for i in matches.size():
		var name := matches[i].get_string(1)
		var from: int = matches[i].get_end()
		var to: int = matches[i + 1].get_start() if i + 1 < matches.size() else section.length()
		var body := section.substr(from, to - from)
		var button := button_re.search(body)
		if button:
			out[name] = "pad:%s" % button.get_string(1)
			continue
		var motion := motion_re.search(body)
		if motion:
			# The move/look sticks bind the SAME axis twice, once per
			# direction, and that is not a collision -- `move_left` and
			# `move_right` are one stick. The sign is part of the identity,
			# exactly as `key_bindings.gd::code()` writes it.
			var sign_text := "+" if float(motion.get_string(2)) >= 0.0 else "-"
			out[name] = "axis:%s:%s" % [motion.get_string(1), sign_text]
			continue
		out[name] = ""
	return out


func _config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTEXTS_PATH))
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


## Context name -> the full flattened list of actions live in it, with
## `includes` expanded. Kept as a plain function rather than cached in a var so
## a single test file can be run twice without stale state.
func _contexts() -> Dictionary:
	var raw: Variant = _config().get("contexts", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var table := raw as Dictionary
	var out: Dictionary = {}
	for name: String in table.keys():
		out[name] = _expand(name, table, [])
	return out


func _expand(name: String, table: Dictionary, seen: Array) -> Array:
	if seen.has(name) or not table.has(name):
		return []
	seen.append(name)
	var entry: Dictionary = table[name]
	var out: Array = []
	for parent: String in entry.get("includes", []):
		for action: String in _expand(parent, table, seen):
			if not out.has(action):
				out.append(action)
	for action: String in entry.get("actions", []):
		if not out.has(action):
			out.append(action)
	return out


## action -> the name of the alias group it belongs to (its own name when it is
## in none). Two actions in the same group may share a button: they are one
## verb reached two ways, and the config has to justify each pair.
func _alias_groups() -> Dictionary:
	var out: Dictionary = {}
	for group: Array in _config().get("aliases", []):
		if group.is_empty():
			continue
		for action: String in group:
			out[action] = str(group[0])
	return out


## The binding code as a person would say it, so a failure names a button
## rather than a number. Reuses data/config/menu.json's own glyph table, which
## is the project's single answer to "what is joypad button 9 called".
func _human(code: String) -> String:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/menu.json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		return code
	var glyphs: Variant = _find_glyphs(parsed as Dictionary)
	var parts := code.split(":")
	var key := "_".join(parts) if parts[0] == "axis" else code.replace(":", "_")
	if typeof(glyphs) == TYPE_DICTIONARY and (glyphs as Dictionary).has(key):
		return "%s (%s)" % [str((glyphs as Dictionary)[key]), code]
	return code


func _find_glyphs(node: Dictionary) -> Variant:
	if node.has("glyphs"):
		return node["glyphs"]
	for value: Variant in node.values():
		if typeof(value) == TYPE_DICTIONARY:
			var found: Variant = _find_glyphs(value as Dictionary)
			if found != null:
				return found
		elif typeof(value) == TYPE_ARRAY:
			for item: Variant in value as Array:
				if typeof(item) == TYPE_DICTIONARY:
					var found_in_array: Variant = _find_glyphs(item as Dictionary)
					if found_in_array != null:
						return found_in_array
	return null
