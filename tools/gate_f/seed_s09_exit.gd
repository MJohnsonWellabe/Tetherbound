extends SceneTree

## GATE-F-LEG-S10AB. Hand-authors the `S09-exit` entry save that S10a loads.
##
## ## Why this exists, stated plainly
##
## This lane tests S10a (Hall gauntlet) and S10b (Warden / legendary / release
## ceremony) IN ISOLATION. Their protocol entry save is `S09-exit`, the exit
## state of the Stronghold-approach segment -- and no completed Gate F run has
## ever produced a real one. The only `S09-exit.json` in the repo
## (`ralph/reports/gate-f-run-20260828T183531Z/S09/saves/`) holds ONE fainted
## level-4 creature, eight opening flags and a player standing at z=1318 --
## 6.2 km short of the Hall. Loading it would test nothing this lane is for.
##
## So the entry state is CONSTRUCTED here, and every evidence claim that comes
## out of a run seeded by this file is conditional on that. The honest form of
## any finding is "S10a/S10b, given a clean entry, does X" -- never "the
## chapter does X". This file is the definition of "clean entry" and is
## committed precisely so that assumption is auditable rather than implied.
##
## ## The assumptions, each with its source
##
##   * PARTY OF FIVE, levels 19-20. `data/config/progression.json`'s
##     `_comment_award_sh47` states the curve's own design target: "the main
##     line alone arrives level with the boss", where the boss is the Warden's
##     level-20 ace (`tests/test_trainers_data.gd::
##     test_the_critical_path_alone_pays_for_the_warden_ready_level` fails the
##     build if the critical path stops paying for it). So the lead sits at
##     L20 -- level with the ace, not above it -- and the bench at L19, which
##     is where `party_share` 0.5 leaves creatures that fought alongside it.
##     NOT levelled to the cap: an over-levelled seed would hide exactly the
##     balance defects this lane is meant to find.
##   * FIVE SPECIES, three types. Ground / Water / Air is the whole Meadows
##     type set a player can actually field by band 5, and one of each plus
##     two is the shape the chapter's own trainers are built against.
##   * FULL HP AND ENERGY, nobody fainted, satiety full. S09's own span ends
##     at a "final camp decision" (protocol section B) -- a player who camped
##     before the Hall arrives topped up, and that is the FAIR start this
##     lane's brief asks for.
##   * FLAGS: every main-chain flag from the opening through
##     `hall_approach_open` (the three-Sigil gate; `playground_world.gd::
##     SIGIL_GATE_FLAG`), plus S09's own two approach fights. NOT the three
##     `defeated_stronghold_*` flags -- those are S10a's own work and seeding
##     them would seed the thing under test.
##   * POSITION: the Hall threshold, taken from the LIVE building's own
##     `entrance` marker rather than a literal, so this cannot rot the way the
##     step-scripts' hard-coded coordinates did.
##   * SATCHEL: a climax loadout. Potions, revives and food in quantity,
##     greater orbs (unusable against a trainer -- CLAUDE.md: trainer-owned
##     creatures cannot be caught -- and carried anyway, because a player
##     arriving here would be), the three Sigils, and the tools they have had
##     since the village.
##
##   godot --headless --path . --script tools/gate_f/seed_s09_exit.gd -- --out <dir>

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINER_NPCS := preload("res://scripts/world/trainer_npc.gd")
const SETTLE_FRAMES := 420
const SLOT := 4

## Lead first. `party.gd::add` appends, and index 0 is the active creature.
const PARTY: Array[Dictionary] = [
	{"species": "terrapup", "level": 20, "nickname": "Tup", "bond": 100},
	{"species": "ripplet", "level": 19, "nickname": "Ripple", "bond": 72},
	{"species": "galecrest", "level": 19, "nickname": "Gale", "bond": 64},
	{"species": "tuskroot", "level": 19, "nickname": "Tusk", "bond": 58},
	{"species": "duskhush", "level": 19, "nickname": "Dusk", "bond": 44},
]

const SATCHEL: Array[Dictionary] = [
	{"id": "potion_large", "n": 8},
	{"id": "potion_small", "n": 12},
	{"id": "revive", "n": 4},
	{"id": "berries", "n": 10},
	{"id": "orb_greater", "n": 5},
	{"id": "orb_basic", "n": 8},
	{"id": "field_sigil", "n": 1},
	{"id": "ridge_sigil", "n": 1},
	{"id": "river_sigil", "n": 1},
	{"id": "axe", "n": 1},
	{"id": "pickaxe", "n": 1},
	{"id": "knife", "n": 1},
	{"id": "hammer", "n": 1},
	{"id": "torch", "n": 1},
]

const HOTBAR: Array[String] = ["potion_large", "potion_small", "revive", "berries", "orb_greater"]

## Every main-chain flag up to and including the Sigil gate, in
## `data/progression/objectives.json`'s own order, plus the beat flags the
## opening sets on the way. `fight_through_the_hall` is the first objective
## NOT satisfied here, which is exactly what S10a-11 asserts.
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
	"relay_captain_defeated", "captive_rescued", "relay_disabled",
	"mill_crossing_restored",
	"defeated_captain_field", "defeated_captain_ridge", "defeated_captain_riverwatch",
	"hall_approach_open",
	"defeated_stronghold_outer_watch", "defeated_stronghold_checkpoint",
]

## The day a 3-4 hour chapter's finale plausibly falls on. Only reachable
## effect is the farm/satiety clock, neither of which either segment reads.
const DAY := 6

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
		creature.set("battles_fought", 24)
		creature.set("levels_gained_with_you", int(spec.get("level", 1)) - 3)
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

	# --- stand the player on the Hall threshold ---
	var stronghold := _find_by_script(world, "stronghold.gd")
	if stronghold == null:
		print("SEED FAIL: no stronghold in the booted world; there is no threshold to stand on")
		quit(1)
		return
	var threshold: Vector3 = stronghold.call("marker", "entrance")
	var player: Node3D = world.get_node_or_null(^"Player")
	if player == null:
		print("SEED FAIL: no Player node")
		quit(1)
		return
	# Half a metre of air, then let the character body settle onto whatever is
	# actually under it. Writing a y by hand is how a save comes back with the
	# player's feet inside the causeway.
	player.global_position = threshold + Vector3(0.0, 0.5, 0.0)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	# Face up the causeway, into the Hall.
	var model := player.get_node_or_null(^"Model") as Node3D
	if model != null:
		model.global_rotation.y = 0.0
	for i in 120:
		await physics_frame

	print("player settled at %s (threshold marker %s)" % [str(player.global_position), str(threshold)])

	# --- write it ---
	if not bool(game.call("save_game", SLOT)):
		print("SEED FAIL: save_game(%d) refused" % SLOT)
		quit(1)
		return
	var src: String = ProjectSettings.globalize_path(str((game.get("save_system") as RefCounted).call("slot_path", SLOT)))
	var dst := _out_dir.path_join("S09-exit.json")
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
	print("=== seeded S09-exit ===")
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
