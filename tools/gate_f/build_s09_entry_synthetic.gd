extends SceneTree

## G3-BAND5-0903 addendum. The `S09-entry` equivalent of
## `build_s10b_synthetic_seed.gd`, for the same reason that file exists: no
## completed Gate F run has ever produced a real `S08-exit.json`, so S09
## (Sigil gate -> outer watch -> checkpoint -> final camp decision -> Hall
## threshold) cannot be run in isolation without one being constructed.
##
## Modelled on `build_s10b_synthetic_seed.gd`'s approach (hand-built JSON,
## real species/level arithmetic via `creature_species.gd`/`progression.gd`,
## no full scene load) rather than `seed_s09_exit.gd`'s (which loads the
## whole world to read a live building marker) -- this seed's own position is
## open meadow at a fixed band boundary, not a building interior, so there is
## nothing live to read and the faster path is honest.
##
## Every claim from a run seeded by this file takes the form "S09, given a
## clean entry, does X" -- never "the chapter does X". Whether the team that
## actually finishes S08 matches this seed's assumptions is a separate
## question, answered by a real S01->S08 chain, not by this file.
##
## ## The assumptions, each with its source
##
##   * PARTY OF FIVE, entry level ~16. `data/config/chapter_curve.json`'s
##     band5 `team` block: `{"enter": 16, "exit": 20, "expected_members": 5}`.
##     Lead at 16 (the band's own floor, matching `wild_band: [14,17]` and
##     `trainer_levels: [15,20]` for the first fights this segment picks a
##     fight with), bench at 15-16 -- not already levelled toward 20, which
##     would hide this segment's own difficulty curve rather than test it.
##   * FIVE SPECIES, three types, mirroring `seed_s09_exit.gd`'s own species
##     choices (Ground/Water/Air is the whole type set a player can field by
##     band 5) so the two seeds describe the same travelling party at two
##     points on its curve, not two different parties.
##   * FLAGS: every main-chain flag through `hall_approach_open`
##     (`playground_world.gd::SIGIL_GATE_FLAG`) -- copied from
##     `seed_s09_exit.gd`'s own FLAGS list verbatim, MINUS its last two
##     (`defeated_stronghold_outer_watch`, `defeated_stronghold_checkpoint`),
##     because those are S09's OWN fights (S09-24..32, S09-34..40) and
##     seeding them would seed the thing under test. This mirrors that file's
##     own stated rule for `defeated_stronghold_*` exactly, one flag pair
##     earlier in the chain.
##   * FULL HP, ENERGY, SATIETY -- a player who won at the Ironwood Grove
##     captains and travelled the band 4/5 boundary un-ambushed arrives
##     intact; the segment's own rest-before-the-Hall beat (S09-42..55) is
##     what is under test, not a HP shortfall this seed invented.
##   * POSITION: the band 4/5 boundary at (0, 7000), the corridor's own
##     z=7000 line (`data/config/chapter_curve.json`'s band4 `z_to`, and
##     `tools/_probe_band5_approach.gd::_spine()`'s own first waypoint).
##     NOT literally at the Sigil gate (63.6,7400): S09-17's own first
##     `move_to` step walks TO the gate with a 49,500-frame budget, which
##     only measures anything if there is a real approach left to walk. A
##     literal at-the-gate entry would make that step (and this segment's
##     entire dead-travel headline) trivially zero, which is the one number
##     this whole addendum exists to measure honestly.
##   * INVENTORY: potions/orbs a travelling player would have restocked, plus
##     wood/stone/fiber for S09-47..50's own camp placement (`Camp` costs
##     12 wood / 8 stone / 10 fiber per that step's own comment) -- an empty
##     satchel would fail the build step for a reason that has nothing to do
##     with Band 5's own design.
##
##   godot --headless --path . --script tools/gate_f/build_s09_entry_synthetic.gd -- --out <run-dir>

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

## Lead first, mirroring `seed_s09_exit.gd`'s PARTY order (index 0 is active).
const TEAM := [
	{"species": "terrapup", "level": 16, "nickname": "Tup", "bond": 40, "battles_fought": 14, "caught_on_day": 1, "levels_gained_with_you": 15},
	{"species": "ripplet", "level": 16, "nickname": "Ripple", "bond": 30, "battles_fought": 11, "caught_on_day": 3, "levels_gained_with_you": 12},
	{"species": "galecrest", "level": 15, "nickname": "Gale", "bond": 26, "battles_fought": 9, "caught_on_day": 4, "levels_gained_with_you": 10},
	{"species": "tuskroot", "level": 15, "nickname": "Tusk", "bond": 24, "battles_fought": 10, "caught_on_day": 5, "levels_gained_with_you": 8},
	{"species": "duskhush", "level": 15, "nickname": "Dusk", "bond": 18, "battles_fought": 6, "caught_on_day": 5, "levels_gained_with_you": 5},
]

## Every main-chain flag through `hall_approach_open` -- `seed_s09_exit.gd`'s
## own FLAGS list, minus its final two (`defeated_stronghold_outer_watch`,
## `defeated_stronghold_checkpoint`), which are this segment's own work.
const FLAGS := [
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
]

const DAY := 5

var _out_dir := ""


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if _out_dir == "--out":
			_out_dir = arg
		elif arg == "--out":
			_out_dir = "--out"
	if _out_dir == "" or _out_dir == "--out":
		print("SEED FAIL: needs --out <run-dir>")
		quit(2)
		return

	var cfg := PROGRESSION.config()
	var party: Array = []
	for entry: Dictionary in TEAM:
		var creature: RefCounted = SPECIES.spawn(str(entry["species"]))
		if creature == null:
			push_error("unknown species '%s'; aborting" % str(entry["species"]))
			quit(1)
			return
		creature.set_level(int(entry["level"]), cfg)
		creature.nickname = str(entry.get("nickname", ""))
		creature.bond = int(entry.get("bond", 0))
		creature.battles_fought = int(entry.get("battles_fought", 0))
		creature.caught_on_day = int(entry.get("caught_on_day", 0))
		creature.levels_gained_with_you = int(entry.get("levels_gained_with_you", 0))
		party.append({
			"species_id": str(creature.species_id),
			"display_name": str(creature.display_name),
			"creature_type": str(creature.creature_type),
			"secondary_type": str(creature.secondary_type),
			"nickname": str(creature.nickname),
			"base_hp": float(creature.base_hp),
			"base_attack": float(creature.base_attack),
			"base_defence": float(creature.base_defence),
			"max_hp": float(creature.max_hp),
			"attack": float(creature.attack),
			"defence": float(creature.defence),
			"hp": float(creature.max_hp),
			"energy": 100.0,
			"fainted": false,
			"resting": false,
			"rested": true,
			"rest_bed_index": -1,
			"level": int(creature.level),
			"xp": int(creature.xp),
			"bond": int(creature.bond),
			"battles_fought": int(creature.battles_fought),
			"caught_on_day": int(creature.caught_on_day),
			"levels_gained_with_you": int(creature.levels_gained_with_you),
			"move_quick": str(creature.move_quick),
			"move_charged": str(creature.move_charged),
			"iv_hp": float(creature.iv_hp),
			"iv_attack": float(creature.iv_attack),
			"iv_defence": float(creature.iv_defence),
			"trait_primary": str(creature.trait_primary),
			"trait_secondary": str(creature.trait_secondary),
			"shiny": false,
			"boost_hp": 0,
			"boost_attack": 0,
			"boost_defence": 0,
			"nourishment": 100.0,
			"happiness": 78.0,
			"rested_seconds_left": 0.0,
		})

	# Band 4/5 boundary, open meadow -- see header. Y is set high and left for
	# physics to settle on load, the same convention `build_s10b_synthetic_
	# seed.gd` uses rather than reading live terrain.
	var pose := {
		"position": [0.0, 15.0, 7000.0],
		"model_yaw": 0.0,
		"camera_yaw": 0.0,
		"camera_pitch": -0.15,
	}

	var inventory: Array = [
		{"id": "potion_small", "count": 10},
		{"id": "potion_large", "count": 3},
		{"id": "revive", "count": 2},
		{"id": "berries", "count": 12},
		{"id": "orb_basic", "count": 6},
		{"id": "wood", "count": 20},
		{"id": "stone", "count": 16},
		{"id": "fiber", "count": 16},
		{"id": "axe", "count": 1},
		{"id": "pickaxe", "count": 1},
		{"id": "knife", "count": 1},
		{"id": "hammer", "count": 1},
		{"id": "torch", "count": 1},
	]

	var data := {
		"version": 16,
		"day": DAY,
		"party": party,
		"inventory": inventory,
		"hotbar": ["", "potion_small", "berries", "revive", "torch"],
		"placed_buildings": [],
		"farm_plots": [],
		"death_satchels": [],
		"satiety": 88.0,
		"map": {
			"cell": 4.0,
			"dynamic_markers": [],
			"grid_x": 512,
			"grid_z": 2048,
			"landmarks": [
				"grandpa_house", "village", "road_gate", "band1_trail_camp",
				"south_bridge", "old_quarry", "burrow_warrens_mouth",
				"tether_relay", "mill_crossing", "ironwood_grove",
			],
			"origin_x": -1024.0,
			"origin_z": -512.0,
			"regions": [
				"grandpas_village", "the_rise", "the_pond", "the_old_quarry",
				"the_burrow_warrens", "the_tether_relay", "the_long_water",
				"the_ironwood_grove",
			],
			"visited_b64": "",
		},
		"progression": {"flags": FLAGS},
		"harvested_vegetation": {},
		"world_seed": 0,
		"felled_vegetation": {},
		"player_pose": pose,
	}

	# Written as `S08-exit.json` so `seed_save`'s own `run://S08-exit.json`
	# resolution finds it: it checks `<run-dir>/saves/<name>` first.
	var dir := _out_dir.path_join("saves")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var dst := dir.path_join("S08-exit.json")
	var file := FileAccess.open(dst, FileAccess.WRITE)
	if file == null:
		push_error("could not open %s for write" % dst)
		quit(1)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[seed] wrote synthetic S08-exit.json: %d party members, %d flags, day %d"
		% [party.size(), FLAGS.size(), DAY])
	for c: Dictionary in party:
		print("  - %s (%s) L%d hp=%.2f/%.2f atk=%.2f def=%.2f"
			% [c["nickname"], c["species_id"], c["level"], c["hp"], c["max_hp"], c["attack"], c["defence"]])
	print("  wrote: %s" % dst)
	quit(0)
