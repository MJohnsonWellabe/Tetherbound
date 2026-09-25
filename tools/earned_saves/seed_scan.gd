extends SceneTree

## Read-only seed scan for the earned C1 chain: counts the practice-meadow
## training bodies (bramblebun/mudsnout within the team segment's radius) that
## a world seed produces, using production `spawn_tables.plan_for`. Pure data;
## no world, no save. Usage:
##   godot --headless --path . --script tools/earned_saves/seed_scan.gd -- --from=1 --to=200
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const SPAWN_TABLES := preload("res://scripts/combat/spawn_tables.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CHAPTER_CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const TEAM := preload("res://tests/helpers/meadows_earned_team_segment.gd")


func _init() -> void:
	var from := 1
	var to := 200
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--from="):
			from = int(arg.split("=")[1])
		elif arg.begins_with("--to="):
			to = int(arg.split("=")[1])
	var director: Node = DIRECTOR.new()
	var entries: Array = director.call("spawns_config").get("spawns", []) as Array
	var exceptional: Array = []
	for id: Variant in SPECIES.table():
		if not str(id).begins_with("_") and SPECIES.definition(str(id)).has("variant_of"):
			exceptional.append(str(id))
	for world_seed in range(from, to + 1):
		var plan := SPAWN_TABLES.plan_for(entries, world_seed, SPAWN_TABLES.config(),
			CHAPTER_CURVE.config(), exceptional)
		var bodies := 0
		for entry: Variant in entries:
			var spawn: Dictionary = entry
			var order := int(spawn.get("order", -1))
			var species := str((plan.get(order, {}) as Dictionary).get("species", spawn.get("species", "")))
			var c: Array = spawn.get("centre", [0, 0, 0])
			if Vector2(float(c[0]), float(c[2])).distance_to(TEAM.PRACTICE_CENTRE) > TEAM.PRACTICE_RADIUS:
				continue
			if species in ["bramblebun", "mudsnout"]:
				bodies += int(spawn.get("count", 1))
		print("SEED %d bodies=%d" % [world_seed, bodies])
	director.free()
	quit(0)
