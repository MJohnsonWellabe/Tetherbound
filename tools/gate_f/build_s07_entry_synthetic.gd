extends SceneTree

## G3-BAND3-0903. Hand-authors the `S06-exit` entry save that S07 loads.
##
## ## Why this exists, stated plainly
##
## Modelled directly on `tools/gate_f/seed_s09_exit.gd` -- read that file's own
## header first; the reasoning below only states where this one differs. This
## lane's brief was corrected mid-run to add a played S07 (river arrival ->
## relay pickets -> officer -> relay captain -> captive -> Old Mill Crossing
## restored) because CLAUDE.md's binding rule is that a region is done when
## the complete player path produces the intended experience, and config
## inspection plus unit tests cannot answer whether the relay escalates.
##
## No completed Gate F run has ever produced a real `S06-exit.json` either.
## The archived ones this session found and checked
## (`ralph/reports/gate-f-run-20260831T185555Z/S06/saves/S06-exit.json` and
## three siblings) all hold the SAME two-creature, level 2-3, fainted party at
## the South Bridge (z≈1325) -- 1855m short of Band 3's own entry (z≈3180),
## the identical "held one fainted level-4 creature ... testing nothing"
## defect `seed_s09_exit.gd`'s own header records for the archived
## `S09-exit.json`. So this entry state is CONSTRUCTED here too, and every
## evidence claim from a run seeded by this file takes the form "S07, given a
## clean entry, does X" -- never "the chapter does X".
##
## ## The assumptions, each with its source
##
##   * PARTY OF FIVE, level ~10. `data/config/chapter_curve.json`'s
##     `band3_the_river_lock` region states `team: {"enter": 10, "exit": 13,
##     "expected_members": 5}` -- the five is normally full by the relay
##     (that file's own `temptations` note), so this is the first band where a
##     catch costs somebody. Lead at 10, bench 9-10, the same light spread
##     `seed_s09_exit.gd` uses for its own party (20/19/19/19/19) rather than
##     one flat number.
##   * ONE STARTER, FOUR CAUGHT. The lead is the player's own starter
##     (Terrapup here, arbitrarily -- the three are mechanically identical at
##     this level and nothing downstream reads which one); the other four are
##     ordinary Band 1/2 wild species (mudsnout, burrowback, galecrest,
##     mosshell), never a starter (D72: starters belong to the opening choice
##     alone).
##   * FULL HP AND ENERGY, nobody fainted, satiety full. The Warrens' own
##     guardian fight is the last real cost before this segment and a player
##     who beat it and walked out would have had every chance to rest at the
##     ranger camp spur or ride the tent/campfire loop back in the village;
##     same "fair start" reasoning `seed_s09_exit.gd` gives for its own party.
##   * FLAGS: every main-chain flag from the opening through `warrens_cleared`,
##     the exact prefix of `seed_s09_exit.gd`'s own `FLAGS` constant up to and
##     including that entry -- Band 3 begins the moment the Warrens are done,
##     so nothing past it belongs in a Band 3 ENTRY save. NOT
##     `relay_captain_defeated`/`captive_rescued`/`relay_disabled`/
##     `mill_crossing_restored` -- those are this segment's own work.
##   * POSITION: `burrow_warrens.gd`'s own `marker("entrance")`, the same
##     pattern `seed_s09_exit.gd` uses for the Hall threshold -- 3m outside the
##     den mouth, facing out, which is where a player who just cleared the
##     Warrens and walked out is standing. This cannot rot the way a literal
##     coordinate would if the site is ever re-sited.
##   * SATCHEL: an early-band-3 loadout. Potions and a few basic orbs, the
##     tools the player has had since the village, no relay-tier items (the
##     relay TMs and greater orbs are this band's own reward, not something the
##     player should arrive already holding).
##
##   godot --headless --path . --script tools/gate_f/build_s07_entry_synthetic.gd -- --out <dir>

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINER_NPCS := preload("res://scripts/world/trainer_npc.gd")
const SETTLE_FRAMES := 420
const SLOT := 4

## Lead first. `party.gd::add` appends, and index 0 is the active creature.
const PARTY: Array[Dictionary] = [
	{"species": "terrapup", "level": 10, "nickname": "Tup", "bond": 40},
	{"species": "mudsnout", "level": 9, "nickname": "", "bond": 22},
	{"species": "burrowback", "level": 10, "nickname": "", "bond": 18},
	{"species": "galecrest", "level": 9, "nickname": "", "bond": 15},
	{"species": "mosshell", "level": 10, "nickname": "", "bond": 12},
]

const SATCHEL: Array[Dictionary] = [
	{"id": "potion_small", "n": 6},
	{"id": "potion_large", "n": 2},
	{"id": "revive", "n": 1},
	{"id": "berries", "n": 8},
	{"id": "orb_basic", "n": 6},
	{"id": "orb_greater", "n": 2},
	{"id": "axe", "n": 1},
	{"id": "pickaxe", "n": 1},
	{"id": "knife", "n": 1},
	{"id": "hammer", "n": 1},
	{"id": "torch", "n": 1},
]

const HOTBAR: Array[String] = ["potion_small", "potion_large", "revive", "berries", "orb_basic"]

## Every main-chain flag up to and including `warrens_cleared`, in the exact
## order `seed_s09_exit.gd`'s own `FLAGS` constant states them (that file is
## the audited source for this prefix; not re-derived from objectives.json
## here so the two seeds cannot silently disagree about the opening).
const FLAGS: Array[String] = [
	"opening:beat:wake", "opening:beat:house", "opening:beat:choose",
	"opening:starter_granted", "opening:beat:return_starter", "opening:beat:name",
	"opening:beat:walk_out", "opening:beat:encounter", "opening:beat:road",
	"road_gate_open",
	"tam_tools_given",
	"tournament_team_ready", "tournament_training_ready",
	"home_materials_gathered", "home_built", "creature_bed_built",
	"player_slept_at_home", "tournament_team_fed",
	"tournament_entered", "tournament_won",
	"south_bridge_open",
	"warrens_cleared",
]

## A day into the second real day of play is plausible for "opening through
## the Warrens"; only reachable effect is the farm/satiety clock, which S07
## does not read.
const DAY := 2

var _out_dir := ""


func _init() -> void:
	_run()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if _out_dir == "--out":
			_out_dir = arg
		elif arg == "--out":
			_out_dir = "--out"
	if _out_dir == "" or _out_dir == "--out":
		print("SEED FAIL: needs --out <directory>")
		quit(2)
		return

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("SEED FAIL: no Game autoload")
		quit(1)
		return

	game.call("reset_for_new_game")

	# --- the belt ---
	var party: RefCounted = game.get("party")
	for spec: Dictionary in PARTY:
		var creature: RefCounted = TRAINER_NPCS.creature_for(spec)
		if creature == null:
			print("SEED FAIL: species.json does not know '%s'" % str(spec.get("species", "")))
			quit(1)
			return
		creature.set("nickname", str(spec.get("nickname", "")))
		creature.set("bond", int(spec.get("bond", 0)))
		# Full HP is not a field to set blindly: `set_level` already sizes
		# max_hp off the level, so this tops the instance up to whatever that
		# arithmetic produced rather than writing a number of its own.
		creature.set("hp", float(creature.get("max_hp")))
		creature.set("fainted", false)
		creature.set("energy", 100.0)
		creature.set("nourishment", 100.0)
		creature.set("happiness", 100.0)
		creature.set("battles_fought", 8)
		creature.set("levels_gained_with_you", int(spec.get("level", 1)) - 2)
		if not bool(party.call("add", creature)):
			print("SEED FAIL: party refused '%s'; the belt is five and only five" % str(spec.get("species", "")))
			quit(1)
			return
	party.call("set_active", 0)

	# --- the satchel ---
	var inventory: RefCounted = game.get("inventory")
	for stack: Dictionary in SATCHEL:
		var left: int = int(inventory.call("add", str(stack.get("id", "")), int(stack.get("n", 0))))
		if left > 0:
			print("SEED WARN: %d x %s did not fit the satchel" % [left, str(stack.get("id", ""))])
	for i in HOTBAR.size():
		game.call("assign_hotbar", i, HOTBAR[i])

	# --- the flags ---
	var progression: RefCounted = game.get("progression")
	for flag: String in FLAGS:
		progression.call("set_flag", flag)

	game.set("day", DAY)
	game.set("satiety", 100.0)

	# --- stand the player just outside the Warrens mouth ---
	var warrens := _find_by_script(world, "burrow_warrens.gd")
	if warrens == null:
		print("SEED FAIL: no burrow_warrens in the booted world; there is no exit to stand on")
		quit(1)
		return
	var threshold: Vector3 = warrens.call("marker", "entrance")
	var player: Node3D = world.get_node_or_null(^"Player")
	if player == null:
		print("SEED FAIL: no Player node")
		quit(1)
		return
	# Half a metre of air, then let the character body settle onto whatever is
	# actually under it -- the same reasoning `seed_s09_exit.gd` gives: writing
	# a y by hand is how a save comes back with the player's feet inside the
	# ground.
	player.global_position = threshold + Vector3(0.0, 0.5, 0.0)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	# Face north, out of the mound and up the spine toward the river/relay.
	var model := player.get_node_or_null(^"Model") as Node3D
	if model != null:
		model.global_rotation.y = 0.0
	for i in 120:
		await physics_frame

	print("player settled at %s (warrens entrance marker %s)" % [str(player.global_position), str(threshold)])

	# --- write it ---
	if not bool(game.call("save_game", SLOT)):
		print("SEED FAIL: save_game(%d) refused" % SLOT)
		quit(1)
		return
	var src: String = ProjectSettings.globalize_path(str((game.get("save_system") as RefCounted).call("slot_path", SLOT)))
	var dst := _out_dir.path_join("S06-exit.json")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var bytes := FileAccess.get_file_as_bytes(src)
	var out := FileAccess.open(dst, FileAccess.WRITE)
	if out == null:
		print("SEED FAIL: could not write %s" % dst)
		quit(1)
		return
	out.store_buffer(bytes)
	out.close()

	# --- say what was written, in the game's own words ---
	print("=== seeded S06-exit (synthetic Band 3 entry) ===")
	print("  file: %s (%d bytes)" % [dst, bytes.size()])
	print("  day %d, satiety %.0f" % [int(game.get("day")), float(game.get("satiety"))])
	print("  party %d/5:" % int(party.call("size")))
	for member: Variant in party.call("members"):
		var c := member as RefCounted
		print("    %-12s L%-3d hp %.1f/%.1f  type=%s  quick=%s charged=%s" % [
			str(c.get("nickname")), int(c.get("level")), float(c.get("hp")), float(c.get("max_hp")),
			str(c.get("creature_type")), str(c.get("move_quick")), str(c.get("move_charged"))])
	print("  flags set: %d" % (progression.call("all_set") as Array).size())
	var quest_log: RefCounted = game.get("quest_log")
	print("  tracked objective: %s" % str(quest_log.call("tracked_text", progression)))
	quit(0)


func _find_by_script(node: Node, suffix: String) -> Node:
	var script: Variant = node.get_script()
	if script != null and str(script.resource_path).ends_with(suffix):
		return node
	for child in node.get_children():
		var found := _find_by_script(child, suffix)
		if found != null:
			return found
	return null
