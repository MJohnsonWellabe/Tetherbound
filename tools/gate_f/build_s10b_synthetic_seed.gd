extends SceneTree

## GATE-F-LEG-S10CDE. Hand-authored `S10b-exit` seed save for S10c/S10d/S10e,
## constructed because `ralph/GATE-F-FOUNDATION` and `ralph/GATE-F-LEG-S10AB`
## do not exist yet at the time S10c/S10d/S10e were driven (see this lane's
## own handover report for the full statement of this assumption).
##
## Builds a save matching what a real S10b exit SHOULD look like: a settled
## five-creature roster (the freed legendary joined, one prior catch released
## per the ceremony), full HP, every main-chain objective flag through
## `settle_the_roster` set (so the tracked objective is exactly #27,
## `see_what_changed`, as S10c-89 asserts), positioned at the Hall exit /
## approach-drain start. Uses the REAL species/level arithmetic
## (`creature_species.gd::spawn` + `creature_instance.gd::set_level`) rather
## than hand-typed stat numbers, so the party's stats are exactly what the
## game itself would have produced for a team at these levels — the only
## thing invented here is which species and which levels, not how their
## stats are derived.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

const OUT_PATH := "res://ralph/reports/gate-f-run-GATE-F-LEG-S10CDE/S10b/saves/S10b-exit.json"

## The team: four caught along the journey plus the freed legendary. Levels
## approximate a ~19-20 team per the brief; veridian is 22, matching
## `stronghold_climax.json`'s own `legendary.level`.
const TEAM := [
	{"species": "terrapup", "level": 19, "nickname": "Bramble", "bond": 62, "battles_fought": 24, "caught_on_day": 1, "levels_gained_with_you": 18},
	{"species": "mudsnout", "level": 20, "nickname": "Digger", "bond": 55, "battles_fought": 21, "caught_on_day": 2, "levels_gained_with_you": 16},
	{"species": "brooktail", "level": 19, "nickname": "Ripple", "bond": 48, "battles_fought": 19, "caught_on_day": 4, "levels_gained_with_you": 13},
	{"species": "tuskroot", "level": 20, "nickname": "Anvil", "bond": 51, "battles_fought": 23, "caught_on_day": 6, "levels_gained_with_you": 11},
	{"species": "veridian", "level": 22, "nickname": "Veridian", "bond": 20, "battles_fought": 1, "caught_on_day": 8, "levels_gained_with_you": 0},
]

## Every main-chain flag through `settle_the_roster` (objectives.json's 26
## entries before `see_what_changed`), so the tracked objective is exactly
## #27 on load. `meadows_acknowledged` (#27's own flag) is deliberately NOT
## set — S10c/d/e's own walk-back is what is supposed to set it.
const FLAGS := [
	"opening:beat:choose", "opening:beat:return_starter", "opening:beat:walk_out",
	"opening:beat:road", "road_gate_open", "tam_tools_given",
	"tournament_team_ready", "tournament_training_ready", "home_materials_gathered",
	"home_built", "creature_bed_built", "player_slept_at_home",
	"tournament_entered", "tournament_won", "south_bridge_open",
	"warrens_cleared", "relay_captain_defeated", "captive_rescued",
	"relay_disabled", "mill_crossing_restored",
	"defeated_captain_field", "defeated_captain_ridge", "defeated_captain_riverwatch",
	"hall_approach_open",
	"defeated_stronghold_patrol", "defeated_stronghold_courtyard", "defeated_stronghold_elite",
	"defeated_warden",
	"legendary_freed", "legendary_joined", "legendary_settled",
	"learned_legendary_is_the_source",
]


func _init() -> void:
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
			"happiness": 80.0,
			"rested_seconds_left": 0.0,
		})

	# Position: the Hall exit / approach-drain start. stronghold.json's own
	# comment gives the ramp-foot ground at (8,7508) ~ -4.8; the player is
	# placed comfortably above it and let physics settle it onto the real
	# terrain on load, exactly as a walked arrival would.
	var pose := {
		"position": [8.0, 20.0, 7508.0],
		"model_yaw": 3.14159,
		"camera_yaw": 3.14159,
		"camera_pitch": -0.2,
	}

	var data := {
		"version": 15,
		"day": 9,
		"party": party,
		"inventory": [],
		"hotbar": ["", "potion_small", "berries", "revive", "torch"],
		"placed_buildings": [],
		"farm_plots": [],
		"death_satchels": [],
		"satiety": 82.0,
		"map": {
			"cell": 4.0,
			"dynamic_markers": [],
			"grid_x": 512,
			"grid_z": 2048,
			"landmarks": [
				"grandpa_house", "village", "road_gate", "band1_trail_camp",
				"south_bridge", "old_quarry", "burrow_warrens_mouth",
				"tether_relay", "mill_crossing", "ironwood_grove",
				"sigil_gate", "stronghold_approach",
			],
			"origin_x": -1024.0,
			"origin_z": -512.0,
			"regions": [
				"grandpas_village", "the_rise", "the_pond", "the_old_quarry",
				"the_burrow_warrens", "the_tether_relay", "the_long_water",
				"the_ironwood_grove", "the_ridgeline_watch",
			],
			"visited_b64": "",
		},
		"progression": {"flags": FLAGS},
		"harvested_vegetation": {},
		"world_seed": 0,
		"felled_vegetation": {},
		"player_pose": pose,
	}

	var dir := OUT_PATH.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("could not open %s for write" % OUT_PATH)
		quit(1)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[seed] wrote synthetic S10b-exit.json: %d party members, %d flags, day %d"
		% [party.size(), FLAGS.size(), int(data["day"])])
	for c: Dictionary in party:
		print("  - %s (%s) L%d hp=%.2f/%.2f atk=%.2f def=%.2f"
			% [c["nickname"], c["species_id"], c["level"], c["hp"], c["max_hp"], c["attack"], c["defence"]])
	quit(0)
