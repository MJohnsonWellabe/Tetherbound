extends SceneTree

## GATE2-EVIDENCE-0903 (ROADMAP 2.8). Builds the `S03-exit.json` seed the Gate 2
## evidence run enters the tournament from, so S04 (tournament: sign-up -> three
## rounds -> win -> South Bridge objective) and S05 (leave village -> pond ->
## detour -> South Bridge fight -> cross) can be PLAYED through the real Gate F
## harness with telemetry, rather than posed.
##
##   godot --headless --path . --script tools/gate_f/build_gate2_seed.gd -- \
##       --out=ralph/reports/GATE2-EVIDENCE-0903/run/S03/saves/S03-exit.json
##
## Why a built seed and not a played S03. The freshest committed S03 exit save
## (`ralph/reports/gate-f-run-20260902T200321Z-s03fablefix11/S03/saves/S03-exit.json`)
## is a REAL played state -- opening, road gate, Tam's tools, the practice
## trainer, Mira, Oskar, twenty harvest nodes, tent/campfire/bedroll and one
## creature bed, all walked by the harness -- but S03 still ends short of the
## tournament's entry bar (`docs/00_START_HERE.md`: "Gate F S03 reached 6
## failures outside its lane's scope"): its five creatures sit at levels 2-3
## against `tournament.json`'s `min_level`, and the sleep/feed rungs are unset.
## Replaying S01-S03 would reproduce exactly that. So this file takes that
## real save and applies the SAME allowance `tests/smoke_gate_b_continuous.gd`
## makes in CI (`_ready_a_tournament_team`: level the party to the entry
## threshold through `creature_instance.set_level` with the real progression
## config) plus the flags the tail segment's rungs write
## (`player_slept_at_home`, `creature_bed_built_2/3`, `tournament_team_fed`).
## Everything else -- inventory, hotbar, placed buildings, harvested nodes,
## the map, the day, the player's pose -- is carried over untouched.
##
## What this grants is recorded in the evidence, not hidden: the tournament
## rounds, the walk south, the pond, the detour, the bridge fight and the
## crossing are all played for real from here.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

const DEFAULT_FROM := "res://ralph/reports/gate-f-run-20260902T200321Z-s03fablefix11/S03/saves/S03-exit.json"
const DEFAULT_OUT := "res://ralph/reports/GATE2-EVIDENCE-0903/run/S03/saves/S03-exit.json"

## Flags S03's own last rungs write (home_progress.gd counting three beds,
## player_bed.gd on a real rest, tournament.gd on a fed party). The volatile
## tournament flags are re-derived by `tournament.gd::_write_entry_flags` from
## the live party on load, so setting them here only matters until that poll.
const GRANTED_FLAGS := [
	"creature_bed_built_2", "creature_bed_built_3",
	"player_slept_at_home",
	"tournament_training_ready", "tournament_condition_ready", "tournament_team_fed",
]


func _init() -> void:
	var from := DEFAULT_FROM
	var out := DEFAULT_OUT
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--from="):
			from = arg.trim_prefix("--from=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	if not from.begins_with("res://") and not from.begins_with("user://") and not from.is_absolute_path():
		from = "res://" + from
	if not out.begins_with("res://") and not out.begins_with("user://") and not out.is_absolute_path():
		out = "res://" + out

	var file := FileAccess.open(from, FileAccess.READ)
	if file == null:
		push_error("[seed] cannot read %s" % from)
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		push_error("[seed] %s is not a save dictionary" % from)
		quit(1)
		return
	var data: Dictionary = parsed

	var entry := _tournament_entry()
	var floor_level := maxi(1, int(entry.get("min_level", 6)))
	var cfg := PROGRESSION.config()

	var party: Array = []
	for raw: Variant in (data.get("party", []) as Array):
		var old: Dictionary = raw
		var species_id := str(old.get("species_id", ""))
		var creature: RefCounted = SPECIES.spawn(species_id)
		if creature == null:
			push_error("[seed] unknown species '%s' in the source party" % species_id)
			quit(1)
			return
		var level := maxi(int(old.get("level", 1)), floor_level)
		creature.set_level(level, cfg)
		var member := old.duplicate(true)
		# Stats from the real arithmetic at the new level; identity, history and
		# moves carried from the played save.
		member["level"] = int(creature.level)
		member["xp"] = int(creature.xp)
		member["base_hp"] = float(creature.base_hp)
		member["base_attack"] = float(creature.base_attack)
		member["base_defence"] = float(creature.base_defence)
		member["max_hp"] = float(creature.max_hp)
		member["attack"] = float(creature.attack)
		member["defence"] = float(creature.defence)
		member["hp"] = float(creature.max_hp)
		member["fainted"] = false
		member["energy"] = 100.0
		member["nourishment"] = 100.0
		member["happiness"] = maxf(float(old.get("happiness", 0.0)), 80.0)
		member["rested"] = true
		member["resting"] = false
		member["rest_bed_index"] = -1
		member["rested_seconds_left"] = 3600.0
		member["levels_gained_with_you"] = int(old.get("levels_gained_with_you", 0)) \
			+ (level - int(old.get("level", 1)))
		party.append(member)
	data["party"] = party

	var progression: Dictionary = data.get("progression", {})
	var flags: Array = progression.get("flags", [])
	for id: String in GRANTED_FLAGS:
		if not flags.has(id):
			flags.append(id)
	progression["flags"] = flags
	data["progression"] = progression

	var dir := out.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var writer := FileAccess.open(out, FileAccess.WRITE)
	if writer == null:
		push_error("[seed] could not open %s for write" % out)
		quit(1)
		return
	writer.store_string(JSON.stringify(data, "\t"))
	writer.close()
	print("[seed] %s -> %s" % [from, out])
	print("[seed] party levelled to the tournament floor L%d (min_party_size %d); %d flags"
		% [floor_level, int(entry.get("min_party_size", 0)), flags.size()])
	for c: Dictionary in party:
		print("  - %s (%s) L%d hp=%.1f/%.1f atk=%.1f def=%.1f" % [str(c.get("nickname", "")),
			str(c.get("species_id", "")), int(c["level"]), float(c["hp"]), float(c["max_hp"]),
			float(c["attack"]), float(c["defence"])])
	print("[seed] granted flags: %s" % ", ".join(GRANTED_FLAGS))
	print("[seed] pose %s day %d" % [str(data.get("player_pose", {}).get("position")), int(data.get("day", 0))])
	quit(0)


func _tournament_entry() -> Dictionary:
	var file := FileAccess.open("res://data/config/tournament.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return (parsed as Dictionary).get("entry", {}) if parsed is Dictionary else {}
