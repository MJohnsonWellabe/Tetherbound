extends SceneTree

## GATE-F-LEG-S09. Hand-authors a "clean" S09 entry seed: this is CONDITIONAL,
## ISOLATED evidence (S09 played in isolation from a hand-seeded idealised
## state), not a real earned S08-exit. See the run's own report for the
## honesty-rule framing.
##
## Builds a party of 5 at level 18 (progression.json's own comment: the
## Warden's ace runs level 20, and the main line should arrive "level with
## the boss" around L19-20 by the finale -- 18 sits just under that, matching
## the wake instruction's own assumption), full HP, carrying the three Sigil
## items and every Band 1-4 completion flag the Sigils/objective imply
## (south_bridge/quarry/warrens/relay/mill/captains), positioned on the
## causeway just south of the three-Sigil gate (SIGIL_GATE_AT, 63.6,7400) --
## the Band 4->5 crossing.
##
## Deliberately NOT set: `hall_approach_open` (the gate's own open flag /
## objective 19 completion) and any `defeated_stronghold_*` flag -- those are
## exactly what S09 itself is supposed to produce, and setting them in the
## seed would make "does the gate open" and "are the two approach fights
## real fights" untestable.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" ~/godot-bin/godot --path . \
##     --rendering-driver opengl3 --script tools/_probe_s09_seed.gd

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const SEED_LEVEL := 18
const OUT_PATH := "res://ralph/reports/gate-f-leg-s09/saves/S09-seed.json"

## The three-Sigil gate's own causeway, 5m short of the leaf.
##
## FIRST DRAFT of this constant placed the seed by interpolating along the
## coarse straight-line spine segment (80,7370)->(20,7480) at z=7390, landing
## at x=69.1 -- 5.5m EAST of the gate's own x=63.6. That is well outside the
## causeway's own measured walkable width at this distance from the gate
## (`_probe_sigil_gate_body.gd` measured the walkable 45-degree-standable gap
## AT the gate itself as world-x 63.16..64.04; the carve's fade collar widens
## it moving away from the gate, but the coarse spine is not the same line as
## the carved causeway's own centreline and diverges from it here). Loading
## the seed there dropped the player through unbaked/unstreamed terrain at
## boot -- confirmed by a per-frame trace (`tools/_probe_s09_drive.gd`'s own
## debug pass): `vy` was already -72 by the first walk frame, i.e. the fall
## started during the post-load settle, and the player's own `died()` fall-
## damage path fired and respawned them at the village fallback home,
## draining the whole satchel (including the three seeded Sigils) into a
## death satchel at (69,-77,7390) in the process. Centring the seed ON the
## gate's own x-axis instead keeps it inside the causeway's full width
## (measured at 14.1m, `road_gate.gd`'s own SIGIL-SEAL comment) rather than
## at its edge.
const SEED_AT := Vector2(63.6, 7392.0)

## The three Sigils (playground_world.gd::SIGIL_ITEM_IDS) and every flag the
## chapter's own progression implies a player holding them: the three
## captains beaten (data/progression/objectives.json's own count_flags for
## `defeat_the_captains`), plus the earlier bands' own gates/rescues
## (south_bridge_open/quarry/warrens/relay/mill), so band 5's own dialogue
## and world state reads as a real arrival rather than a flag-starved one.
const SEED_ITEMS := ["field_sigil", "ridge_sigil", "river_sigil"]
const SEED_FLAGS := [
	"opening:beat:wake", "opening:beat:house", "opening:beat:choose",
	"opening:starter_granted", "opening:beat:name", "opening:beat:walk_out",
	"opening:beat:encounter", "tam_tools_given",
	"defeated_south_bridge_grunt",
	"defeated_quarry_dorn", "defeated_warrens_pell",
	"relay_captain_defeated", "captive_rescued", "relay_disabled",
	"mill_crossing_restored",
	"defeated_captain_field", "defeated_captain_ridge", "defeated_captain_riverwatch",
]
const SEED_SUPPLIES := [
	["potion_small", 5], ["orb_basic", 5], ["wood", 20], ["stone", 12], ["fiber", 15],
]

var _team := [
	{"species": "burrowback"}, {"species": "duskhush"}, {"species": "trailpup"},
	{"species": "galecrest"}, {"species": "mosshell"},
]


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("SEED FAIL: no Game autoload booted")
		quit(1)
		return

	var party: RefCounted = game.get("party")
	var inventory: RefCounted = game.get("inventory")
	var progression: RefCounted = game.get("progression")
	if party == null or inventory == null or progression == null:
		print("SEED FAIL: Game is missing party/inventory/progression")
		quit(1)
		return

	party.call("clear")
	var species_db: Dictionary = _json("res://data/creatures/species.json").get("species", {})
	var cfg: Dictionary = _json("res://data/config/progression.json")
	for entry: Dictionary in _team:
		var id: String = entry["species"]
		var def: Dictionary = species_db.get(id, {})
		if def.is_empty():
			print("SEED FAIL: species '%s' not in species.json" % id)
			quit(1)
			return
		var creature: RefCounted = CREATURE_INSTANCE.from_species(id, def)
		creature.set("level", SEED_LEVEL)
		creature.call("_apply_level_stats", cfg)
		creature.set("hp", creature.get("max_hp"))
		creature.set("fainted", false)
		creature.set("energy", 100.0)
		creature.set("bond", 20)
		if not party.call("add", creature):
			print("SEED FAIL: party.add() refused '%s' (party cap hit early?)" % id)
			quit(1)
			return
	print("party seeded: %d/5 at level %d" % [int(party.call("size")), SEED_LEVEL])

	for id: String in SEED_ITEMS:
		var left: int = inventory.call("add", id, 1)
		if left > 0:
			print("SEED FAIL: satchel would not take '%s' (%d left over)" % [id, left])
			quit(1)
			return
	for pair: Array in SEED_SUPPLIES:
		inventory.call("add", pair[0], pair[1])
	print("held Sigils: %d/3 (field=%s ridge=%s river=%s)" % [
		[inventory.call("count", "field_sigil") > 0, inventory.call("count", "ridge_sigil") > 0,
			inventory.call("count", "river_sigil") > 0].count(true),
		str(inventory.call("count", "field_sigil") > 0), str(inventory.call("count", "ridge_sigil") > 0),
		str(inventory.call("count", "river_sigil") > 0)])

	for flag: String in SEED_FLAGS:
		progression.call("set_flag", flag)
	print("progression flags set: %d (hall_approach_open deliberately NOT set: %s)" % [
		SEED_FLAGS.size(), str(not progression.call("has", "hall_approach_open"))])

	var player: Node3D = world.get_node_or_null(^"Player")
	if player == null:
		print("SEED FAIL: no Player node")
		quit(1)
		return
	var heightfield: RefCounted = (load("res://scripts/world/playground_heightfield.gd") as GDScript).new()
	var at: Vector2 = SEED_AT
	var ground: float = heightfield.height_at(at.x, at.y)
	# 2.0m clearance, matching `playground_world.gd`'s own `SPAWN_CLEARANCE` --
	# not this probe's own guess, so the seed lands the same way the game's
	# own spawn logic would rather than risking an embed at a smaller margin.
	player.global_position = Vector3(at.x, ground + 2.0, at.y)
	player.velocity = Vector3.ZERO
	for i in 60:
		await physics_frame
	print("player seeded at (%.1f, %.2f, %.1f), %.1fm from the gate (63.6,7400)" % [
		player.global_position.x, player.global_position.y, player.global_position.z,
		Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(63.6, 7400.0))])

	game.set("day", 1)

	# Deploy the active creature -- RIG-11 (recorded in the prior Gate F run's
	# own S09 notes): a load restores the party but deploys nothing, and no
	# combat/gate assertion downstream means anything without a live ally.
	var director := world.get_node_or_null(^"EncounterDirector")
	if director != null and director.has_method("summon_active_creature"):
		director.call("summon_active_creature")

	# `Game.save_game(slot)` is the real production save path: it captures the
	# live player pose (`_capture_player_pose()`), syncs placed-building/death-
	# satchel/harvest state, THEN writes the slot. Calling `SaveGame.save()`
	# directly (this probe's first draft) skips all of that -- in particular
	# `saved_player_pose` stays whatever a fresh boot left it (empty), so the
	# very next load teleported the player back to the world's default spawn
	# instead of the seeded position. Using the real wrapper is both more
	# correct and closer to what a player's own Save button does.
	var save := SAVE_GAME.new()
	var slot_path: String = save.slot_path(4)
	DirAccess.make_dir_recursive_absolute(slot_path.get_base_dir())
	if not bool(game.call("save_game", 4)):
		print("SEED FAIL: Game.save_game() returned false")
		quit(1)
		return

	var out_abs := ProjectSettings.globalize_path(OUT_PATH)
	DirAccess.make_dir_recursive_absolute(out_abs.get_base_dir())
	var bytes := FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(slot_path))
	var out := FileAccess.open(out_abs, FileAccess.WRITE)
	out.store_buffer(bytes)
	out.close()
	print("wrote seed: %s (%d bytes)" % [OUT_PATH, bytes.size()])
	quit(0)


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
