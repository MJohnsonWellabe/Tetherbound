extends SceneTree

## G3-BAND4 addendum. Hand-authors the `S07-exit` entry save that S08 loads.
##
## ## Why this exists, stated plainly
##
## Modelled directly on `tools/gate_f/seed_s09_exit.gd` — read that file's own
## header first; this is the same technique applied one segment earlier. S08
## (Upper Meadows / Band 4: crossing -> ironwood -> saddle & riding -> three
## captains -> three Sigils) is seeded from `run://S07-exit.json`
## (`tools/gate_f/segments/S08.json` step S08-03), and no completed Gate F run
## has ever produced a real one — the coordinator's own Gate 3 run is
## happening separately and is what will say whether a real player's S07 exit
## actually looks like this. So the entry state is CONSTRUCTED here, exactly
## as `seed_s09_exit.gd` constructs S10a/S10b's, and every claim this segment's
## evidence produces is conditional on that: "S08, given a clean entry, does
## X" — never "the chapter does X".
##
## ## The assumptions, each with its source
##
##   * PARTY OF FIVE, lead level 13. `data/config/chapter_curve.json`'s
##     `band4_upper_meadows_ironwood` region block: `"team": {"enter": 13,
##     "exit": 16, "expected_members": 5}` — read directly by
##     `tests/test_chapter_curve.gd::_team()` as a LEVEL (not a headcount);
##     `expected_members` is the separate headcount field. The SAME region's
##     own `enter` equals `band3_the_river_lock`'s `exit` (13), so this is
##     also literally where Band 3 is supposed to leave a team. Bench members
##     one level down (12), the same modest spread `seed_s09_exit.gd` uses for
##     its own lead/bench split (`progression.json`'s `party_share: 0.5`
##     narrows a two-level gap in practice, not a one-level one, over a whole
##     band).
##   * FIVE SPECIES, three types, NOT already evolved. Ground/Water/Air is
##     the whole type set a player can field this early (`seed_s09_exit.gd`'s
##     own reasoning) — `terrapup` (Ground starter), `ripplet` (Water
##     starter), `galecrest` (wild Air), `mudsnout` (wild Ground), `duskhush`
##     (wild Air), all already used or referenced as valid targets elsewhere
##     in this tree. Deliberately `mudsnout` and NOT its evolution `tuskroot`
##     here: `docs/specs/MEADOWS_PROGRESSION_SPEC.md`'s own evolution example
##     target is "around level 15", inside Band 4's own wild band (11-14) and
##     above this seed's level-13 entry — an already-evolved Tuskroot at
##     entry would assume the exact thing this band is partly FOR.
##   * FULL HP AND ENERGY, nobody fainted, satiety full — same "fair start"
##     reasoning as `seed_s09_exit.gd`: S07's own span ends at the restored
##     crossing, a natural stopping point, not mid-crisis.
##   * FLAGS: every main-chain flag from the opening through
##     `mill_crossing_restored` — `seed_s09_exit.gd`'s own FLAGS array up to
##     and including that exact flag, truncated there. NOT
##     `defeated_captain_field/ridge/riverwatch` and NOT `hall_approach_open`
##     — those are S08's own work, and seeding them would seed the thing
##     under test. `data/progression/objectives.json`'s `defeat_the_captains`
##     entry (`flag_id: hall_approach_open`) becomes the tracked objective
##     under exactly this flag set, matching S08-11's own assertion.
##   * POSITION: past the Old Mill Crossing, on the Band-4-facing side. Read
##     live from the crossing's own `far_point()` (`gated_crossing.gd`,
##     inherited by `mill_crossing.gd`) rather than a literal, the same
##     "ask the live building" rule `seed_s09_exit.gd` uses for the Hall
##     threshold. `far_point(35.0)` — FOUND THE HARD WAY, recorded so the next
##     run does not repeat it: an earlier cut of this file used
##     `far_point(20.0)` and the resulting S08 run stood the player at
##     (-152,-2.15,4223) and never moved again for the rest of its move_to
##     budget (route.csv: 300+ seconds at zero `dead_travel_m`, heading
##     spinning in place) — a stuck teleport-recovery loop, not a walker
##     defect. `tools/_probe_river_gate.gd`'s own header explains why: "11m of
##     Band 3 trail at x=-150 lies inside a river volume" (a CarveFailsafe
##     recovery box) and separately warns `ground_height_at` "is analytic and
##     misled three separate investigations of the phantom wall" at this exact
##     crossing — both point at the same neighbourhood a naive `far_point`
##     offset can land inside. That probe's own continuous-walk test measured
##     the Old Mill Crossing clear of every recovery volume out to +23.7m past
##     centre with zero world teleports; 35.0m keeps a real margin past that
##     proven-clear distance while staying near the crossing's authored road
##     stub (`road` runs to z 4235, centre z 4203 — 35.0m lands at z 4238,
##     3m past the stub's own last authored point, on natural spine ground).
##     A settle check below now asserts the body was not moved by anything but
##     gravity, so a future regression here fails loudly in this script's own
##     output instead of silently seeding a stuck run again. S08's own step
##     script has no "cross the bridge" move — its first content step
##     (S08-13) captures "Upper Meadows entry across the crossing" with no
##     walk before it — so the entry save itself has to already be on the far
##     side; this is that placement.
##   * SATCHEL: a mid-chapter loadout — potions, a revive, berries, both orb
##     tiers unlocked by Band 3 (`orb_basic`, `orb_greater`; NOT `orb_prime`,
##     which S08 itself crafts at its own workbench step), the tools carried
##     since the village, and the mill bridge gear is deliberately ABSENT —
##     `mill_crossing.gd`'s own `MILL_KEY_ITEM` is consumed by the crossing's
##     `item_gate.gd` the moment it opens, so a player standing past a
##     restored crossing does not still have it.
##   * DAY: 4. `seed_s09_exit.gd`'s own DAY 6 is the finale's plausible day;
##     Band 3->4 is roughly the chapter's midpoint, so one day short of that.
##     Neither segment reads the day for anything but the farm/satiety clock.
##
##   godot --headless --path . --script tools/gate_f/build_s08_entry_synthetic.gd -- --out <dir>

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINER_NPCS := preload("res://scripts/world/trainer_npc.gd")
const SETTLE_FRAMES := 420
const SLOT := 4

## Lead first. `party.gd::add` appends, and index 0 is the active creature.
const PARTY: Array[Dictionary] = [
	{"species": "terrapup", "level": 13, "nickname": "Tup", "bond": 55},
	{"species": "ripplet", "level": 12, "nickname": "Ripple", "bond": 40},
	{"species": "galecrest", "level": 12, "nickname": "Gale", "bond": 30},
	{"species": "mudsnout", "level": 12, "nickname": "Snout", "bond": 22},
	{"species": "duskhush", "level": 11, "nickname": "Dusk", "bond": 15},
]

const SATCHEL: Array[Dictionary] = [
	{"id": "potion_large", "n": 3},
	{"id": "potion_small", "n": 10},
	{"id": "revive", "n": 2},
	{"id": "berries", "n": 8},
	{"id": "orb_greater", "n": 3},
	{"id": "orb_basic", "n": 10},
	{"id": "axe", "n": 1},
	{"id": "pickaxe", "n": 1},
	{"id": "knife", "n": 1},
	{"id": "hammer", "n": 1},
	{"id": "torch", "n": 1},
]

const HOTBAR: Array[String] = ["potion_large", "potion_small", "revive", "berries", "orb_greater"]

## Every main-chain flag up to and including the Old Mill Crossing's own
## restoration flag — `seed_s09_exit.gd`'s FLAGS array, truncated at
## `mill_crossing_restored`. Kept in the same source order.
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
]

## The distance past the crossing's centre to stand, along its own `across`
## axis. See this file's header for why 35.0 and not the crossing's own
## `gate_offset` (7.4, the NEAR-side prompt distance S07-76 uses) or the
## originally-tried 20.0 (found stuck in a recovery volume).
const FAR_SIDE_DISTANCE := 35.0

## The day a chapter roughly at its midpoint plausibly falls on. See header.
const DAY := 4

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
		creature.set("battles_fought", 12)
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

	# --- stand the player past the restored crossing, on the band-4 side ---
	var crossing := _find_by_script(world, "mill_crossing.gd")
	if crossing == null:
		print("SEED FAIL: no Old Mill Crossing in the booted world; there is no far side to stand on")
		quit(1)
		return
	var far: Vector2 = crossing.call("far_point", FAR_SIDE_DISTANCE)
	var player: Node3D = world.get_node_or_null(^"Player")
	if player == null:
		print("SEED FAIL: no Player node")
		quit(1)
		return
	var ground := NAN
	if world.has_method("ground_height_at"):
		ground = float(world.call("ground_height_at", far.x, far.y))
	var start_y: float = (ground if not is_nan(ground) else 0.0) + 2.0
	# Two metres of air, then let the character body fall onto whatever is
	# actually under it. Writing a settled y by hand is how a save comes back
	# with the player's feet inside the road.
	player.global_position = Vector3(far.x, start_y, far.y)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	# Face away from the crossing, up the corridor toward the Ironwood Grove.
	var model := player.get_node_or_null(^"Model") as Node3D
	if model != null:
		model.global_rotation.y = 0.0
	var dropped_from: Vector3 = player.global_position
	for i in 120:
		await physics_frame

	# SETTLE CHECK. A recovery volume (CarveFailsafe) or any other world code
	# that moves the player on its own is exactly the failure this file's own
	# header records finding at far_point(20.0): the body never actually
	# fails to load, it just gets silently relocated the instant the world
	# claims it, and the resulting save then seeds a run that is stuck before
	# its first move_to step ever runs. Ordinary gravity settle only moves the
	# body a few metres vertically; the horizontal drift a recovery teleport
	# produces is much larger. This does not prove the spot is safe to WALK
	# from (only a real move_to does that), but it does catch the exact
	# failure mode found here.
	var settled: Vector3 = player.global_position
	var horizontal_drift := Vector2(settled.x - dropped_from.x, settled.z - dropped_from.z).length()
	if horizontal_drift > 3.0:
		print(("SEED WARN: the player drifted %.1fm horizontally while settling (dropped at %s, "
			+ "settled at %s) -- this is larger than gravity alone should move a body and matches "
			+ "the recovery-volume symptom this file's header records at the old far_point(20.0). "
			+ "The seed will still be written, but treat this run's S08 result as suspect until the "
			+ "route.csv confirms the walker actually left the crossing.") % [
				horizontal_drift, str(dropped_from), str(settled)])

	print("player settled at %s (crossing far_point(%.1f) = %s)" % [
		str(player.global_position), FAR_SIDE_DISTANCE, str(far)])

	# --- write it ---
	if not bool(game.call("save_game", SLOT)):
		print("SEED FAIL: save_game(%d) refused" % SLOT)
		quit(1)
		return
	var src: String = ProjectSettings.globalize_path(str((game.get("save_system") as RefCounted).call("slot_path", SLOT)))
	var dst := _out_dir.path_join("S07-exit.json")
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
	print("=== seeded S07-exit (S08 entry) ===")
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
