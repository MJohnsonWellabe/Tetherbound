extends RefCounted

## Read-only accessors over LIVE game state, for the Gate F operator harness.
##
## `ralph/GATE_F_INSTRUMENTATION_REQUEST.md` §2. Loaded by
## `tools/gate_f/operator_harness.gd` with `preload()`; deliberately NOT an
## autoload in `project.godot`, so a shipped build never carries it and no
## gameplay `_process` can reach it.
##
## ## The one rule this file exists to keep
##
## Every accessor reads what the GAME reads. Where the game has a public
## method, this calls it. Where it has only a private one, this calls the
## private one by name rather than re-deriving the answer. Nothing here
## recomputes a rule the game already owns.
##
## The reason is not tidiness. A telemetry field that disagrees with the game
## is worse than an absent one: the operator writes down "the quest log said
## X" and Phase B reasons about a number no player ever saw. Two concrete
## places this matters and where the temptation to reimplement is strongest:
##
##   * the tracked objective. `quest_log.gd::tracked_text()` walks the main
##     chain and returns the first unfinished label. Its `revealed_by` rule and
##     its `count_flags` suffix are both non-obvious. `tracked_objective()`
##     below calls it and then finds the ID by matching the answer back, rather
##     than walking `objectives.json` a second time and hoping the two loops
##     stay in step.
##   * the input context. See `input_context()`'s own header — the game has no
##     single resolver, so this reports the raw owner plus the exact booleans
##     the world-verb polls read, and never invents a verdict of its own.
##
## ## What is deliberately absent
##
## No VRAM, no device frame rate. `ralph/GATE_F_MASTER_PROTOCOL.md` §C.1 marks
## both [OWNER-ONLY]: this container has a software rasteriser and no handheld,
## so any number it produced would be a fabrication wearing a real field name.
## The fields do not exist rather than carrying a guess.

const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const CREATURE_CONDITION := preload("res://scripts/creatures/creature_condition.gd")

## The POI radius the corridor probe uses (`tools/_probe_gate_f_corridor.gd`'s
## `NOTICE_M`), restated here because §F fixes it at 30 m for the dead-travel
## definition. Not tunable: changing it changes what the protocol measures.
const POI_RADIUS_M := 30.0

## Region id reported when the player stands inside no authored region.
## §C.1's own wording: "region id ... or `corridor`".
const CORRIDOR := "corridor"

## Recognised by path so `input_context()` can name the title screen rather than
## describing it as "not the world". Kept here rather than read from
## `project.godot`'s `run/main_scene` because that key is what the game BOOTS
## into, which is a different question and would silently change meaning if the
## boot scene ever moved.
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"

var _tree: SceneTree = null
var _game: Node = null
## One QuestLog reader, reused. `quest_log.gd::_init` parses
## `objectives.json` on construction, so building one per event would reparse
## a file twice a second for the length of a segment.
var _log: RefCounted = null
## `creature_condition.gd::config()` is a static file read. Cached for the same
## reason, and because every party snapshot needs it once per creature.
var _condition_cfg: Dictionary = {}


func _init(tree: SceneTree) -> void:
	_tree = tree
	_log = QUEST_LOG.new()
	_condition_cfg = CREATURE_CONDITION.config()


## The live `Game` autoload, or null in a scene that has no autoloads (which
## no real segment is, but a unit test constructing this bare is).
func game() -> Node:
	if _game != null and is_instance_valid(_game):
		return _game
	if _tree == null or _tree.root == null:
		return null
	_game = _tree.root.get_node_or_null(^"Game")
	return _game


## The world scene, or null at the title.
func world() -> Node:
	if _tree == null:
		return null
	return _tree.current_scene


func player() -> Node3D:
	var w := world()
	if w == null:
		return null
	return w.get_node_or_null(^"Player") as Node3D


func camera_rig() -> Node3D:
	var w := world()
	if w == null:
		return null
	return w.get_node_or_null(^"CameraRig") as Node3D


func combat_manager() -> Node:
	var w := world()
	if w == null:
		return null
	return w.get_node_or_null(^"CombatManager")


## The EncounterDirector, for the one caller that needs to know a trainer
## battle is still running BETWEEN its rounds.
##
## GATE-F-LEG-S10AB. `CombatManager::is_fighting()` goes false in the gap
## between a trainer's creatures (`_trainer_send_delay`), so a driver that
## stopped on the first false would walk away from a five-creature Warden after
## his first one fell. `trainer_battle_active()` is the director's own answer
## and is what `_on_trainer_round_ended` is written against.
func encounter_director() -> Node:
	var w := world()
	if w == null:
		return null
	return w.get_node_or_null(^"EncounterDirector")


func world_look() -> Node:
	var w := world()
	if w == null:
		return null
	return w.get_node_or_null(^"WorldLook")


func world_weather() -> Node:
	var w := world()
	if w == null:
		return null
	return w.get_node_or_null(^"WorldWeather")


func interaction_arbiter() -> Node:
	var w := world()
	if w == null:
		return null
	return w.get_node_or_null(^"InteractionArbiter")


# --- objective ---------------------------------------------------------------

## `{id, text}` of the tracked objective, or `{}` when the chain is finished.
##
## `text` comes straight from `quest_log.gd::tracked_text()` — the same call
## `playground_hud.gd` draws its tracked line from, so the telemetry and the
## screen can never disagree about WHAT the player is being told.
##
## `id` is the harder half: `main_entries()` deliberately does not return
## `flag_id` (it is a view for a panel, not a database row), and no accessor
## exposes it. Rather than walk `objectives.json` a second time — a second copy
## of the `revealed_by` skip rule, which is exactly the divergence this file
## exists to prevent — this asks the reader for its answer first and then finds
## which authored entry produced it, using the reader's own `_label()` so a
## `count_flags` suffix matches too.
##
## Consequence worth stating plainly: if two objectives were ever authored with
## the identical label, this returns the first. That is a data problem, not a
## probe problem, and the `text` half stays correct regardless.
func tracked_objective() -> Dictionary:
	var g := game()
	if g == null:
		return {}
	var progression: Variant = g.get("progression")
	if progression == null:
		return {}
	var text := str(_log.call("tracked_text", progression))
	if text.is_empty():
		return {}
	var main: Variant = _log.get("_main")
	if typeof(main) == TYPE_ARRAY:
		for raw: Variant in (main as Array):
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var entry := raw as Dictionary
			if str(_log.call("_label", entry, progression)) == text:
				return {"id": str(entry.get("flag_id", "")), "text": text}
	return {"id": "", "text": text}


# --- party and vitals --------------------------------------------------------

## Per creature: `{species, name, level, xp, hp, max_hp, fed, rested, bond}`.
##
## `fed`/`rested` come from `creature_condition.gd::summary()`, which is the
## reader `tournament.gd::_write_entry_flags()` gates entry on. Reading
## `nourishment` and thresholding it here would be a second opinion about
## whether a creature has eaten, and the two would drift the first time
## `creature_condition.json` moved.
func party_state() -> Array:
	var out: Array = []
	var g := game()
	if g == null:
		return out
	var party: Variant = g.get("party")
	if party == null:
		return out
	for member: Variant in (party.call("members") as Array):
		if member == null:
			continue
		var summary: Dictionary = CREATURE_CONDITION.summary(member, _condition_cfg)
		out.append({
			"species": str(member.get("species_id")),
			"name": str(member.call("label")),
			"level": int(member.get("level")),
			"xp": int(member.get("xp")),
			"hp": float(member.get("hp")),
			"max_hp": float(member.get("max_hp")),
			"fed": bool(summary.get("fed", false)),
			"rested": bool(summary.get("rested", false)),
			"bond": int(member.get("bond")),
		})
	return out


## The piloted/deployed creature's name, or null when none is out.
##
## Mid-fight the answer is `combat_manager.gd::active_creature()` — the fight
## owns which creature is out and can switch it without the party's own active
## index moving. Outside a fight it is the party's active member.
func active_creature() -> Variant:
	var combat := combat_manager()
	if combat != null and combat.has_method("is_fighting") and bool(combat.call("is_fighting")):
		var fighting: Variant = combat.call("active_creature")
		if fighting != null:
			return str(fighting.call("label"))
	var g := game()
	if g == null:
		return null
	var party: Variant = g.get("party")
	if party == null:
		return null
	var active: Variant = party.call("active")
	return str(active.call("label")) if active != null else null


## `{hp, stamina, satiety}` from the live vitals object.
func player_vitals() -> Dictionary:
	var g := game()
	if g == null:
		return {}
	var vitals: Variant = g.call("player_vitals")
	if vitals == null:
		return {}
	return {
		"hp": float(vitals.get("health")),
		"stamina": float(vitals.get("stamina")),
		"satiety": float(vitals.get("satiety")),
	}


## `{item_id: count}` over every occupied satchel slot.
##
## Summed per item rather than listed per slot: §C.1 asks for a "full slot
## snapshot `{item: count}`", and two half-stacks of berries are four berries
## to everything downstream. Slot geometry is a satchel-UI question and
## `tab_backpack.gd` already owns it.
func inventory_snapshot() -> Dictionary:
	var out: Dictionary = {}
	var g := game()
	if g == null:
		return out
	var inventory: Variant = g.get("inventory")
	if inventory == null:
		return out
	for i in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", i)
		if stack.is_empty():
			continue
		var id := str(stack.get("id", ""))
		if id.is_empty():
			continue
		# `n`, not `count`. `autoload/inventory.gd` stores a stack as
		# `{"id": ..., "n": ...}` -- `stack_at()` returns a duplicate of that
		# dictionary and every reader in the game uses `n`. Reading `count`
		# returned the default 0 for every occupied slot, so this accessor
		# reported `{"axe": 0, "berries": 0, "orb_basic": 0, ...}`: the right
		# item ids with every quantity zero. That is coverage defect CD-6's
		# second half -- S03's `save` event described a satchel holding
		# `orb_basic x15, potion_small x3, berries x5, revive x2` as all zeros.
		# It also silently disabled the `gather` and `craft` detectors, which
		# compare two snapshots that were always equal.
		out[id] = int(out.get(id, 0)) + int(stack.get("n", 0))
	return out


## Which satchel CELL a given item is sitting in, or -1 when it is not carried.
##
## GAME-9 / RIG-24. `inventory_snapshot()` above deliberately throws slot
## geometry away, and for the evidence schema that is right. But a step that
## wants to bind the pickaxe to a hotbar slot has to put the cursor on the
## pickaxe's own cell first, and the only way S03 had to say that was a
## hardcoded count of `ui_right` presses derived from the order a FRESH save
## happens to fill the bag in.
##
## That count is wrong the moment the bag differs, and after a real 450-second
## replay it always differs: the run-4 evidence shows both Revive draughts
## spent and two of three potions drunk before the tools are ever bound, so
## every cell after the gap has moved and the presses land on the wrong items
## in silence. Six real gathers then reported the same wrong tool and
## `home_materials_gathered` never set.
##
## Cells, not stacks: a split stack of the same item occupies two cells and the
## first one found is the one the cursor can reach by counting from here.
func satchel_slot_of(item_id: String) -> int:
	var g := game()
	if g == null:
		return -1
	var inventory: Variant = g.get("inventory")
	if inventory == null:
		return -1
	for i in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", i)
		if str(stack.get("id", "")) == item_id:
			return i
	return -1


## How many cells wide the satchel grid is, read off the live grid rather than
## `data/config/menu.json`, so a caller stepping the cursor row by row is
## stepping the grid that exists. 0 when the Satchel is not built.
##
## Load-bearing for `satchel_focus()`'s callers: the cursor moves in rows and
## columns, and `ui_left` at a row's start does NOT wrap up to the previous
## row's end. S03 assumed it did ("three left from the knife's cell reaches the
## pickaxe's, wrapping up a grid row") and that single wrong assumption is what
## put `potion_small` on hotbar 3 and left the pickaxe unbound — GAME-9's
## `{hotbar_slot: 3, item: "knife"}` in full.
func satchel_columns() -> int:
	var tab := _satchel_tab()
	if tab == null:
		return 0
	var grid: Variant = tab.get("_grid")
	if grid == null or not (grid is GridContainer):
		return 0
	return maxi(1, (grid as GridContainer).columns)


## `{slot, item, ok}` — where the satchel cursor actually is, and what is under
## it. `ok` is false when the Satchel is not the surface holding focus, which is
## a different answer from "the cursor is on an empty cell" and must not be
## confused with it.
##
## Read off `tab_backpack.gd`'s own `_focused`, which its per-button
## `focus_entered` handler sets, rather than by matching the focused Control
## against the grid's children here: the tab already knows, and a second copy of
## "which cell is this" is a second answer that can disagree.
func satchel_focus() -> Dictionary:
	var out := {"slot": -1, "item": "", "ok": false}
	var tab := _satchel_tab()
	if tab == null:
		return out
	var slot := int(tab.get("_focused"))
	out["slot"] = slot
	out["ok"] = true
	var g := game()
	var inventory: Variant = g.get("inventory") if g != null else null
	if inventory == null or slot < 0 or slot >= int(inventory.call("slot_count")):
		return out
	var stack: Dictionary = inventory.call("stack_at", slot)
	out["item"] = str(stack.get("id", ""))
	return out


func _satchel_tab() -> Node:
	if _tree == null or _tree.root == null:
		return null
	for node: Node in _descendants(_tree.root):
		var script: Script = node.get_script() as Script
		if script != null and script.resource_path.ends_with("tab_backpack.gd"):
			return node
	return null


## `{hotbar_slot, item}` — which quick-bar slot holds the tool currently in
## hand, and what it is. `hotbar_slot` is -1 with nothing equipped, matching
## `game_state.gd::hotbar_slot_of()`'s own miss value.
func equipped() -> Dictionary:
	var g := game()
	if g == null:
		return {}
	var tool_id := str(g.get("equipped_tool"))
	if tool_id.is_empty():
		return {"hotbar_slot": -1, "item": ""}
	return {"hotbar_slot": int(g.call("hotbar_slot_of", tool_id)), "item": tool_id}


## Which quick-bar slot holds `item_id` RIGHT NOW, independent of what is
## currently equipped -- `game_state.gd::hotbar_slot_of()`'s own lookup,
## exposed directly. -1 if it is not on the bar at all. Exists because a
## fixed hotbar control number in a step script is a claim about where an
## assign sequence PUT something, and that claim goes stale exactly the way
## a fixed satchel offset did (`focus_item`'s own reason to exist): a bag
## reshuffle, a different assign order, or an item consumed and re-added
## can all move a tool to a different slot between one run and the next.
func hotbar_slot_of(item_id: String) -> int:
	var g := game()
	if g == null:
		return -1
	return int(g.call("hotbar_slot_of", item_id))


# --- input context -----------------------------------------------------------

## Who owns input right now, as the game itself decides it.
##
## **This is a report, not a resolver, and the distinction is load-bearing.**
## `data/config/input_contexts.json` says so in its own first line: "Nothing in
## the game reads this file at runtime." There is no function anywhere in
## `scripts/` that returns "we are in the `menu_backpack` context". The context
## map is a written-down contract that `tests/test_input_context_collisions.gd`
## checks against `project.godot`, and the game's real behaviour is four
## independent booleans that each world-verb poll asks for itself
## (`playground_hud.gd::_world_input_allowed`).
##
## So this returns a NAME that is a label over those booleans — never a fifth
## opinion about who should own input. `input_state()` below returns the raw
## booleans, and every event carries both. If the name and the booleans ever
## disagree, believe the booleans: they are what the game ran.
##
## The mapping, and the live read behind each:
##
##   `no_scene`        — nothing is loaded at all. The harness between boots.
##   `title`           — the title scene is up. Recognised by its scene path,
##                       not by "the world context did not apply": the first cut
##                       of this fell through every world-verb gate (no combat
##                       manager, no input owner, no armed ghost, no arbiter to
##                       be disabled) and reported the title screen as `world`,
##                       which `tools/gate_f/segments/selfcheck_capture.json`
##                       caught on its second step.
##   `scene:<name>`    — a scene with no Player in it that is not the title. An
##                       honest "I do not know what this is" rather than a guess.
##   `combat_aim`      — `CombatManager::is_aiming()`.
##   `combat`          — `CombatManager::is_fighting()`.
##   `build_catalogue` — a node in `build_menu.gd::GROUP` reporting `is_open()`.
##   `narrative_modal` — the owner is dialogue/name-prompt/starter-picker.
##   `menu_<tab>`      — the owner is the pause shell; the tab comes from
##                       `game_menu.gd::current_tab_id()`, so `menu_backpack`
##                       and `menu_map` are distinguished exactly as
##                       `input_contexts.json` names them.
##   `panel:<name>`    — some other member of `input_owner.gd::GROUP` owns
##                       input. Named rather than folded into "menu" because
##                       `input_contexts.json` has no context for the station
##                       panels and inventing one would be exactly the fabrication
##                       this file refuses. The node name is the honest answer.
##   `build_placement` — nothing owns input, no fight, and `Game.pending_build`
##                       is non-empty: a ghost is armed.
##   `locked`          — nothing owns input and the interaction arbiter is
##                       disabled. That is `sequence_director.gd`'s fade/cutscene
##                       lockout, during which world verbs are refused and the
##                       player genuinely controls nothing.
##   `world`           — everything else.
##
## Order matters and follows the game's own precedence: `_world_input_allowed`
## checks the fight first, then the arbiter, then the owner, so a fight with a
## panel open reports `combat` here for the same reason the hotbar stands down
## for the fight rather than for the panel.
func input_context() -> String:
	var scene := world()
	if scene == null:
		return "no_scene"
	# No body to pilot means this is not the world context, whatever else is or
	# is not true. Checked before the world-verb gates rather than after: every
	# one of those gates reads permissively when the node it asks about is
	# absent (`playground_hud.gd::_world_input_allowed`'s own null-safe
	# default), so a scene with none of them present falls all the way through
	# to `world` and reports the title screen as free run of the map.
	if player() == null:
		if scene.scene_file_path == TITLE_SCENE:
			return "title"
		return "scene:%s" % scene.scene_file_path.get_file().get_basename()
	var combat := combat_manager()
	if combat != null and combat.has_method("is_aiming") and bool(combat.call("is_aiming")):
		return "combat_aim"
	if combat != null and combat.has_method("is_fighting") and bool(combat.call("is_fighting")):
		return "combat"

	var owner := input_owner_node()
	if owner != null:
		var script_path := ""
		if owner.get_script() != null:
			script_path = str(owner.get_script().resource_path)
		if script_path.ends_with("build_menu.gd"):
			return "build_catalogue"
		if script_path.ends_with("dialogue_panel.gd") \
				or script_path.ends_with("name_prompt.gd") \
				or script_path.ends_with("starter_picker.gd"):
			return "narrative_modal"
		if script_path.ends_with("game_menu.gd"):
			var tab := ""
			if owner.has_method("current_tab_id"):
				tab = str(owner.call("current_tab_id"))
			return "menu" if tab.is_empty() else "menu_%s" % tab
		return "panel:%s" % owner.name

	var g := game()
	if g != null and not str(g.get("pending_build")).is_empty():
		return "build_placement"
	var arbiter := interaction_arbiter()
	if arbiter != null and arbiter.has_method("enabled") and not bool(arbiter.call("enabled")):
		return "locked"
	return "world"


## The node currently in `input_owner.gd::GROUP` and reporting itself open.
##
## Asked through `input_owner.gd::current()` rather than by walking the group
## here, because `_owns()` has a real rule in it (`is_open()` first, visibility
## only as the fallback) and a second copy of that rule is a second answer.
func input_owner_node() -> Node:
	if _tree == null:
		return null
	# Loaded by path rather than `preload`ed at the top of the file: this probe
	# is also constructed by unit tests that never load a UI scene, and a
	# preload chain into the menu stack costs them the whole UI tree.
	var script: GDScript = load("res://scripts/ui/input_owner.gd")
	if script == null:
		return null
	return script.call("current", _tree)


## The raw booleans every world-verb poll reads, plus who holds GUI focus.
##
## §C.1 calls `input_context` "the single most important field for §8", and §8
## is the exhaustion matrix — which is really asking "did this press reach the
## surface it should have". A name alone cannot answer that. These are the
## actual gates:
##
##   `owner`            — `input_owner.gd::current()`, by node name.
##   `combat_running`   — `CombatManager::is_fighting()`.
##   `combat_aiming`    — `CombatManager::is_aiming()`.
##   `arbiter_enabled`  — `interaction_arbiter.gd::enabled()`.
##   `pending_build`    — `Game.pending_build`, the armed-ghost string.
##   `tree_paused`      — `SceneTree.paused`. A paused tree is why the six
##                        pausing panels cannot leak: `PlaygroundHUD` is
##                        PAUSABLE and simply stops polling.
##   `focus_owner`      — the focused Control's node name, "" for none.
##   `focus_text`       — its `text` when it has one. A Button's label is what
##                        the operator can actually see, and "MarginContainer"
##                        is not evidence that focus is on Load Game.
##   `mouse_mode`       — captured/visible. The menu must release the mouse and
##                        restore it; `smoke_menu.gd` exists partly for this.
##   `prompt`           — `interaction_arbiter.gd::prompt()`, the live interact
##                        prompt text, "" when none is offered. A `press
##                        interact` step that presses blind against a refusal
##                        (wrong tool, out of range, wrong item) has no way to
##                        tell a silent no-op from a real success without this
##                        -- Fable's diagnosis of the S03 gather-ladder misses
##                        (2026-09-02) took real per-node correlation to find
##                        what one field here would have shown directly.
##   `prompt_distance`  — 3D distance from the player to the winning provider,
##                        -1.0 when there is none. Pairs with `prompt` to tell
##                        a genuine reach/LOS miss from a wrong-provider one.
func input_state() -> Dictionary:
	var out := {
		"owner": "",
		"combat_running": false,
		"combat_aiming": false,
		"arbiter_enabled": true,
		"pending_build": "",
		"tree_paused": false,
		"focus_owner": "",
		"focus_text": "",
		"mouse_mode": int(Input.get_mouse_mode()),
		"prompt": "",
		"prompt_distance": -1.0,
	}
	if _tree == null:
		return out
	out["tree_paused"] = _tree.paused
	var owner := input_owner_node()
	if owner != null:
		out["owner"] = str(owner.name)
	var combat := combat_manager()
	if combat != null:
		if combat.has_method("is_fighting"):
			out["combat_running"] = bool(combat.call("is_fighting"))
		if combat.has_method("is_aiming"):
			out["combat_aiming"] = bool(combat.call("is_aiming"))
	var arbiter := interaction_arbiter()
	if arbiter != null and arbiter.has_method("enabled"):
		out["arbiter_enabled"] = bool(arbiter.call("enabled"))
		if arbiter.has_method("prompt"):
			out["prompt"] = str(arbiter.call("prompt"))
		if not str(out["prompt"]).is_empty() and arbiter.has_method("winning_provider"):
			var provider: Variant = arbiter.call("winning_provider")
			var body := player()
			if provider is Node3D and body != null:
				out["prompt_distance"] = body.global_position.distance_to((provider as Node3D).global_position)
	var g := game()
	if g != null:
		out["pending_build"] = str(g.get("pending_build"))
	var viewport := _tree.root.get_viewport() if _tree.root != null else null
	if viewport != null:
		var focused := viewport.gui_get_focus_owner()
		if focused != null:
			out["focus_owner"] = str(focused.name)
			var text: Variant = focused.get("text")
			if typeof(text) == TYPE_STRING:
				out["focus_text"] = str(text)
	return out


# --- combat ------------------------------------------------------------------

## `{opponent_id, opponent_species, opponent_hp, phase, my_hp,
## target_on_screen}`, or `{}` when no fight is running.
##
## `opponent_hp` and `opponent_species` are arrays because §C.1 asks for them
## as arrays — a trainer fields a team. This build's `CombatManager` runs one
## enemy creature at a time (`_enemy`), so the arrays carry one entry each; the
## shape is kept so a later multi-enemy fight does not need a schema change,
## and the honest note is that a one-element array here means one enemy is out,
## not that the trainer owns one creature.
##
## `target_on_screen` is computed against the LIVE camera the player is looking
## through (`Viewport::get_camera_3d()`), not the rig's numbers. A fight can
## take the camera (`combat_camera`), and the question §5 asks is whether the
## thing you are fighting is visible — which only the camera actually rendering
## can answer.
func combat_state() -> Dictionary:
	var combat := combat_manager()
	if combat == null or not combat.has_method("is_fighting") or not bool(combat.call("is_fighting")):
		return {}
	var enemy: Variant = combat.call("enemy")
	var mine: Variant = combat.call("active_creature")
	var out := {
		"opponent_id": "",
		"opponent_species": [],
		"opponent_hp": [],
		"phase": _combat_phase(combat),
		"my_hp": float(mine.get("hp")) if mine != null else 0.0,
		"target_on_screen": false,
	}
	if enemy != null:
		out["opponent_id"] = str(enemy.call("label"))
		out["opponent_species"] = [str(enemy.get("species_id"))]
		out["opponent_hp"] = [float(enemy.get("hp"))]
	var body: Node3D = combat.call("enemy_body") as Node3D if combat.has_method("enemy_body") else null
	if body != null and body.is_inside_tree():
		out["target_on_screen"] = _in_frustum(body.global_position)
	return out


## `state`/`_action`/`_catch_phase` collapsed into one readable phase word.
##
## Read off the manager's own enums rather than inferred from HP or timers.
## `_action` and `_catch_phase` are private; there is no public accessor for
## either, and naming them is still closer to the truth than a phase this file
## decided for itself.
func _combat_phase(combat: Node) -> String:
	var catch_phase := int(combat.get("_catch_phase"))
	if catch_phase != 0:
		return ["none", "absorb", "wait", "shaking", "verdict"][clampi(catch_phase, 0, 4)]
	var state := int(combat.get("state"))
	if state == 2:
		return "resolving"
	var action := int(combat.get("_action"))
	if action == 1:
		return "windup"
	if action == 2:
		return "recovery"
	return "ready"


## Is `point` inside the frustum of the camera currently rendering?
func _in_frustum(point: Vector3) -> bool:
	if _tree == null or _tree.root == null:
		return false
	var camera := _tree.root.get_viewport().get_camera_3d()
	if camera == null:
		return false
	return camera.is_position_in_frustum(point)


# --- camera, clock, weather --------------------------------------------------

## `{yaw, pitch, distance, fov}` of the live gameplay camera.
##
## `yaw`/`pitch` in DEGREES. The rig stores radians (`camera_rig.gd::yaw`), and
## §C.1's neighbouring `heading` field is degrees; two angle units in one
## record is how a Phase B reader ends up plotting a 6.28-degree pan.
##
## `distance` is the SpringArm's live `spring_length` rather than the rig's
## configured `_distance`, because collision shortens the arm and what the
## player sees is the shortened one.
func camera_pose() -> Dictionary:
	var rig := camera_rig()
	if rig == null:
		return {}
	var out := {
		"yaw": rad_to_deg(float(rig.get("yaw"))),
		"pitch": rad_to_deg(float(rig.get("pitch"))),
		"distance": 0.0,
		"fov": 0.0,
	}
	var arm := rig as SpringArm3D
	if arm != null:
		out["distance"] = arm.spring_length
	var camera := rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera != null:
		out["fov"] = camera.fov
	return out


## `{hour, weather, sun_energy, preset}` from WorldLook/WorldWeather.
##
## The hour is `day_cycle.gd::hour_at(_elapsed_seconds)` — WorldLook's own
## `_process` line 86, called on WorldLook's own cycle object with WorldLook's
## own elapsed counter. There is no public accessor for it (`is_dark()` is the
## only thing that asks), and `tools/_capture_day_night_transition.gd` already
## reaches for the same two members, so this is the established way to read the
## clock rather than a new one.
func clock_weather() -> Dictionary:
	var out := {"hour": 0.0, "weather": "", "sun_energy": 0.0, "preset": ""}
	var look := world_look()
	if look != null:
		var cycle: Variant = look.get("_cycle")
		if cycle != null:
			var hour := float(cycle.call("hour_at", float(look.get("_elapsed_seconds"))))
			out["hour"] = hour
			out["preset"] = str(cycle.call("preset_at", hour))
	var w := world()
	var sun := w.get_node_or_null(^"Sun") as DirectionalLight3D if w != null else null
	if sun != null:
		out["sun_energy"] = sun.light_energy
	var weather := world_weather()
	if weather != null and weather.has_method("weather"):
		out["weather"] = str(weather.call("weather"))
	return out


# --- region and points of interest -------------------------------------------

## The authored region containing `pos`, or `corridor`.
##
## Calls `map_state.gd::_region_at()` — the game's own containment, including
## its "nearest centre among every region you are inside wins" tie-break, which
## `map_landmarks.json`'s own comment says is what resolves the deliberate
## Rise/Relay overlap. Re-implementing that here would report a different
## region than the one whose name the player just saw announced.
func region_at(pos: Vector3) -> String:
	var g := game()
	if g == null:
		return CORRIDOR
	var map: Variant = g.get("map")
	if map == null:
		return CORRIDOR
	var hit: Dictionary = map.call("_region_at", Vector2(pos.x, pos.z))
	if hit.is_empty():
		return CORRIDOR
	return str(hit.get("id", CORRIDOR))


## Metres to the nearest point of interest, or INF when the world holds none.
##
## The POI definition is §F's, and the classifier is
## `tools/_probe_gate_f_corridor.gd::_points_of_interest()` transplanted rather
## than re-invented: wild creature (visible only — R5.3's time/weather gates
## express themselves as visibility, and a gated-out creature is not an
## encounter), trainer, harvest node, camp, landmark, TM, key item. The two
## must agree or the corridor probe's chapter-wide dead-walk figure and this
## segment's live one measure different worlds.
##
## Rescanned on demand. `refresh_pois()` caches the scan; a 2 Hz trace that
## walked the whole scene tree twice a second would be the instrumentation
## overhead §8 asks about, and a bad answer to it.
func nearest_poi_dist(from: Vector3) -> float:
	if _pois.is_empty():
		return INF
	var here := Vector2(from.x, from.z)
	var best := INF
	for entry: Variant in _pois:
		var poi: Dictionary = entry
		var node: Node3D = instance_from_id(int(poi["id"])) as Node3D
		# A wild creature that has been caught, or a node freed by streaming,
		# stops being a POI the moment it leaves the tree.
		if node == null or not node.is_inside_tree():
			continue
		if poi["kind"] == "wild" and not node.visible:
			continue
		best = minf(best, here.distance_to(Vector2(node.global_position.x, node.global_position.z)))
	return best


var _pois: Array = []


## Rescan the world for points of interest. Call after any transition that adds
## or removes them — a region entry, a catch, a fight ending.
func refresh_pois() -> int:
	_pois.clear()
	var w := world()
	if w == null:
		return 0
	for node: Node in _descendants(w):
		var n3 := node as Node3D
		if n3 == null or not n3.is_inside_tree():
			continue
		var kind := _poi_kind(n3)
		if kind.is_empty():
			continue
		_pois.append({"id": n3.get_instance_id(), "kind": kind})
	return _pois.size()


## The kind word for a node, or "" when it is not a point of interest.
## Same script-path/meta tests `_probe_gate_f_corridor.gd` uses.
func _poi_kind(n3: Node3D) -> String:
	if n3.has_meta("trainer_id"):
		return "trainer"
	if n3.get_script() == null:
		return ""
	var path := str(n3.get_script().resource_path)
	if path.ends_with("wild_creature.gd"):
		return "wild"
	if path.ends_with("harvest_node.gd"):
		return "gather"
	if path.ends_with("camp.gd"):
		return "rest"
	if path.ends_with("landmark.gd"):
		return "landmark"
	if path.ends_with("tm_pickup.gd"):
		return "tm"
	if path.ends_with("key_pickup.gd"):
		return "key"
	return ""


func _descendants(node: Node) -> Array:
	var out: Array = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


# --- progression flags -------------------------------------------------------

## Every progression flag currently set, sorted. The event schema's `flags`
## field carries the DELTA; the harness diffs two of these to get it, so the
## flag names it reports are always names the store actually holds.
func flags() -> Array:
	var g := game()
	if g == null:
		return []
	var progression: Variant = g.get("progression")
	if progression == null:
		return []
	var raw: Variant = progression.call("all_set")
	if typeof(raw) != TYPE_ARRAY:
		return []
	var out: Array = (raw as Array).duplicate()
	out.sort()
	return out
