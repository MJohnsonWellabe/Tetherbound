extends SceneTree

## G3-BAND2. Hand-authors the `S05-exit` entry save that S06 loads.
##
## ## Why this exists, stated plainly
##
## This lane tests S06 (Stone & Root: bridge -> Old Quarry -> rootstone ->
## Burrow Warrens -> guardian -> exit toward river) IN ISOLATION, the same
## reason `seed_s09_exit.gd` exists for S10a/S10b -- modelled on it directly,
## per the Gate 3 coordinator's own instruction. No S05-exit.json in this repo
## is a clean one: every real Gate F attempt at S01-S05 that produced one
## either fainted a creature, stopped short of a party of three, or never set
## `tournament_won`/`south_bridge_open` (checked directly against
## `ralph/reports/gate-f-run-20260831T185555Z/S05/saves/S05-exit.json` before
## writing this file: party of 2, one at 0 HP, 16 flags, missing
## `tournament_won` and `home_built`). Loading one of those into S06 would
## test whatever S01-S05 happened to leave behind, not Band 2.
##
## So the entry state is CONSTRUCTED here, and every evidence claim that comes
## out of a run seeded by this file is conditional on that. The honest form of
## any finding is "S06, given a clean entry, does X" -- never "the chapter
## does X". This file is the definition of "clean entry" and is committed
## precisely so that assumption is auditable rather than implied.
##
## ## The assumptions, each with its source
##
##   * PARTY OF FOUR, level 8 lead, bench 6-8. `data/config/chapter_curve.json`
##     band2_stone_and_root's own `team` block: `{"enter": 8, "exit": 10,
##     "expected_members": 4}`. The lead (the starter) sits at the region's
##     own entry level; the bench sits a little under it, the shape
##     `seed_s09_exit.gd`'s own bench-under-lead convention already uses.
##     NOT levelled to band 2's exit (10) or ceiling: an over-levelled seed
##     would hide the exact balance defects this lane exists to find, the
##     same reasoning `seed_s09_exit.gd` states for its own party.
##   * SPECIES: `terrapup` (Ground) is the lead -- one of `opening.json`'s
##     three starters (`data/config/opening.json` `starters.species`:
##     terrapup/ripplet/galewisp), and the same starter `seed_s09_exit.gd`
##     leads with. The other three are drawn from `bramblebun`, `pipwing`
##     and `trailpup` -- all real Band 1 wild species
##     (`data/config/bands/band1_lower_meadows/spawns.json`), i.e. what a
##     player who caught along the way through Band 1 would actually be
##     carrying, not an invented roster.
##   * FULL HP AND ENERGY, nobody fainted, satiety full. A player who just
##     crossed the South Bridge is not assumed to have limped across it.
##   * FLAGS: every main-chain flag `seed_s09_exit.gd`'s own FLAGS array
##     carries up to and including `south_bridge_open` -- S05's own span per
##     `docs/acceptance/GATE_F_MASTER_PROTOCOL.md` section B is "leave village
##     -> pond -> optional detour -> South Bridge fight -> cross", and
##     `south_bridge_open` is that span's own last beat. NOT
##     `warrens_cleared` or anything past it -- seeding S06's own destination
##     flags would seed the thing under test, the same rule `seed_s09_exit.gd`
##     states for `defeated_stronghold_*`.
##   * POSITION: on the South Bridge, at the Band 1 / Band 2 boundary.
##     `S06.json`'s own `S06-12a` step says this in so many words: "S05 saved
##     ON the bridge, so this segment loads standing on the band 1/2
##     boundary". `scripts/world/world_perimeter.gd`'s `BAND1_Z1` constant
##     (1360.0) is the corridor's own data-driven boundary
##     (`chapter_curve.json`'s band1 row shares the same `z_to`, and
##     `tests/test_chapter_curve.gd` fails the build if the two ever
##     disagree), so the seed stands 1 m past it -- on the Band 2 side of the
##     cut, matching "the arrival side of the South Bridge cut" `S06-12a`
##     names. `south_bridge.gd` places no interior marker (it is a 14-line
##     stub; the crossing's geometry lives in `terrain_playground.json`'s
##     road/`drains` data), so x is read off the real `S05-exit.json` sample
##     inspected above (x=3.25, the bridge deck's own centreline) rather than
##     invented, and y is sampled live off the real terrain the same way
##     `seed_s09_exit.gd` samples the Hall threshold -- never written by hand.
##   * SATCHEL: a Band-1-exit loadout. Potions and orbs in the quantity a
##     tournament winner would be carrying, the tools handed out since the
##     village (axe, pickaxe, knife, hammer, torch -- the same list
##     `seed_s09_exit.gd` carries forward), and a working stock of base
##     materials (wood/stone/fiber) so `S06`'s own workbench-and-craft block
##     (`S06-36` through `S06-47`, arming a workbench and crafting
##     `orb_greater` plus a reinforced tool) is not gated on how much the
##     live walk happens to gather on the way in.
##
##   godot --headless --path . --script tools/gate_f/build_s06_entry_synthetic.gd -- --out <dir>

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINER_NPCS := preload("res://scripts/world/trainer_npc.gd")
const PERIMETER := preload("res://scripts/world/world_perimeter.gd")
const SETTLE_FRAMES := 420
const SLOT := 4

## Lead first. `party.gd::add` appends, and index 0 is the active creature.
const PARTY: Array[Dictionary] = [
	{"species": "terrapup", "level": 8, "nickname": "Tup", "bond": 46},
	{"species": "bramblebun", "level": 7, "nickname": "Bramble", "bond": 38},
	{"species": "pipwing", "level": 7, "nickname": "Pip", "bond": 30},
	{"species": "trailpup", "level": 6, "nickname": "Trail", "bond": 24},
]

const SATCHEL: Array[Dictionary] = [
	{"id": "potion_large", "n": 2},
	{"id": "potion_small", "n": 6},
	{"id": "revive", "n": 1},
	{"id": "berries", "n": 8},
	{"id": "orb_basic", "n": 6},
	{"id": "wood", "n": 16},
	{"id": "stone", "n": 12},
	{"id": "fiber", "n": 12},
	{"id": "axe", "n": 1},
	{"id": "pickaxe", "n": 1},
	{"id": "knife", "n": 1},
	{"id": "hammer", "n": 1},
	{"id": "torch", "n": 1},
]

const HOTBAR: Array[String] = ["potion_small", "berries", "orb_basic", "axe", "pickaxe"]

## S05's own span, per `docs/acceptance/GATE_F_MASTER_PROTOCOL.md` section B:
## "leave village -> pond -> optional detour -> South Bridge fight -> cross".
## The same main-chain prefix `seed_s09_exit.gd`'s own FLAGS array carries,
## cut at that span's own last beat (`south_bridge_open`) rather than carried
## on into Band 2's own flags -- see this file's header.
const FLAGS: Array[String] = [
	"opening:beat:wake", "opening:beat:house", "opening:beat:choose",
	"opening:starter_granted", "opening:beat:return_starter", "opening:beat:name",
	"opening:beat:walk_out", "opening:beat:encounter", "opening:beat:road",
	"road_gate_open",
	"tam_tools_given",
	"recipe_orb_basic", "mira_shop_open", "opening:mira_visited", "oskar_trade_open",
	"tournament_team_ready", "tournament_training_ready",
	"home_materials_gathered", "home_built", "creature_bed_built",
	"player_slept_at_home", "tournament_team_fed",
	"tournament_entered", "tournament_won",
	"south_bridge_open",
]

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
		creature.set("battles_fought", 9)
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

	# --- stand the player on the South Bridge, the Band 1 / Band 2 cut ---
	# x taken from the real S05-exit.json sample this file's header names
	# (the bridge deck's own centreline); z is 1 m past BAND1_Z1, on the
	# Band 2 side, matching S06.json's own "S05 saved ON the bridge" note.
	# y is sampled live off the real terrain, never written by hand.
	var player: Node3D = world.get_node_or_null(^"Player")
	if player == null:
		print("SEED FAIL: no Player node")
		quit(1)
		return
	var x := 3.25
	var z: float = PERIMETER.BAND1_Z1 + 1.0
	var ground: float = float(world.call("ground_height_at", x, z))
	if is_nan(ground):
		print("SEED FAIL: no ground under the South Bridge cut at %.2f, %.2f" % [x, z])
		quit(1)
		return
	player.global_position = Vector3(x, ground + 0.5, z)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	# Face north, deeper into Band 2 -- the direction of travel this save is
	# handed off in the middle of.
	var model := player.get_node_or_null(^"Model") as Node3D
	if model != null:
		model.global_rotation.y = 0.0
	for i in 120:
		await physics_frame

	print("player settled at %s (South Bridge cut target x=%.2f z=%.2f)" % [
		str(player.global_position), x, z])

	# --- write it ---
	if not bool(game.call("save_game", SLOT)):
		print("SEED FAIL: save_game(%d) refused" % SLOT)
		quit(1)
		return
	var src: String = ProjectSettings.globalize_path(str((game.get("save_system") as RefCounted).call("slot_path", SLOT)))
	var dst := _out_dir.path_join("S05-exit.json")
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
	print("=== seeded S05-exit (synthetic, for S06 in isolation) ===")
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
