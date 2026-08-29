extends SceneTree

## T3-ENCOUNTER. Census a rolled world without booting one.
##
##   godot --headless --path . --script tools/_probe_rolled_population.gd
##   godot --headless --path . --script tools/_probe_rolled_population.gd -- --seeds=1,7,42
##
## `spawn_tables.gd::plan_for()` is a pure function, so the whole population a
## seed produces can be measured here in a second rather than by standing 886
## creatures on Terrain3D and counting them. Prints, per seed: the species
## census, how far it moved from the authored world, the scarce-tier and alpha
## budgets actually spent per region, and the closest two scarce encounters --
## which is the owner's own named failure ("one clearing with five exotics")
## measured rather than asserted.
##
## Seed 0 is printed first and deliberately: it must come back identical to the
## authored world, and seeing that in the same table as the rolled ones is the
## clearest statement of what this system does and does not change.

const SPAWN_TABLES := preload("res://scripts/combat/spawn_tables.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const CHAPTER_CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


func _init() -> void:
	var seeds: Array[int] = [0, 1, 7, 42, 1337]
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seeds="):
			seeds = []
			for raw in argument.trim_prefix("--seeds=").split(","):
				if raw.strip_edges().is_valid_int():
					seeds.append(int(raw.strip_edges()))

	var entries: Array = BAND_CONTENT.load_config(
		"res://data/config/spawns.json", "spawns").get("spawns", []) as Array
	var cfg := SPAWN_TABLES.config()
	var curve := CHAPTER_CURVE.config()
	var exceptional: Array = []
	for id: Variant in SPECIES.table():
		if not str(id).begins_with("_") and SPECIES.definition(str(id)).has("variant_of"):
			exceptional.append(str(id))

	var rolled_clusters := 0
	for entry: Variant in entries:
		if str((entry as Dictionary).get("table", "")) != "":
			rolled_clusters += 1
	print("spawn table: %d clusters, %d rolled, %d anchored" % [
		entries.size(), rolled_clusters, entries.size() - rolled_clusters])
	print("aspect variants counted as already-exceptional: %s" % str(exceptional))

	for world_seed: int in seeds:
		_report(entries, world_seed, cfg, curve, exceptional)

	# Nothing here needs a running tree, and a SceneTree script that does not
	# quit sits in its main loop forever with its output still buffered -- which
	# reads exactly like a hang.
	quit()


func _report(entries: Array, world_seed: int, cfg: Dictionary, curve: Dictionary, exceptional: Array) -> void:
	var plan := SPAWN_TABLES.plan_for(entries, world_seed, cfg, curve, exceptional)
	var census := {}
	var moved := 0
	var population := 0
	var alphas := {}
	var scarce: Array = []

	for entry: Variant in entries:
		var spawn: Dictionary = entry
		var order := int(spawn.get("order", -1))
		var species := str(spawn.get("species", ""))
		var result: Dictionary = plan.get(order, {})
		if not result.is_empty():
			if str(result.get("species", species)) != species:
				moved += 1
			species = str(result.get("species", species))
		var count := int(spawn.get("count", 1))
		census[species] = int(census.get(species, 0)) + count
		population += count

		var centre := _centre_of(spawn)
		var region := str(CHAPTER_CURVE.region_at(centre.z, curve).get("id", ""))
		if spawn.has("alpha") or spawn.has("elder") or result.has("alpha"):
			alphas[region] = int(alphas.get(region, 0)) + 1
		var tier := _tier_of(species, str(spawn.get("table", "")), cfg)
		if tier == "rare" or tier == "exceptional":
			scarce.append({"at": centre, "species": species, "region": region})

	var closest := INF
	for i in scarce.size():
		for j in range(i + 1, scarce.size()):
			var d: float = (scarce[i]["at"] as Vector3).distance_to(scarce[j]["at"] as Vector3)
			closest = minf(closest, d)

	var label := "AUTHORED (seed 0)" if world_seed == SPAWN_TABLES.AUTHORED_SEED else "seed %d" % world_seed
	print("\n=== %s ===" % label)
	print("  population %d in %d clusters; %d clusters changed species" % [
		population, entries.size(), moved])
	var names: Array = census.keys()
	names.sort()
	var line: PackedStringArray = []
	for id: Variant in names:
		line.append("%s %d" % [str(id), int(census[id])])
	print("  census: %s" % ", ".join(line))
	print("  alphas per region: %s" % str(alphas))
	print("  scarce (rare+) encounters: %d; closest pair %s" % [
		scarce.size(), "n/a" if closest == INF else "%.0fm" % closest])
	for item: Variant in scarce:
		print("    %s in %s at %s" % [
			str((item as Dictionary)["species"]), str((item as Dictionary)["region"]),
			str((item as Dictionary)["at"])])


func _tier_of(species: String, table_name: String, cfg: Dictionary) -> String:
	if table_name == "":
		return ""
	for entry: Variant in (SPAWN_TABLES.table(table_name, cfg).get("entries", []) as Array):
		if str((entry as Dictionary).get("species", "")) == species:
			return str((entry as Dictionary).get("tier", ""))
	return ""


func _centre_of(spawn: Dictionary) -> Vector3:
	var raw: Variant = spawn.get("centre", [])
	var list: Array = raw if raw is Array else []
	if list.size() < 3:
		return Vector3.ZERO
	return Vector3(float(list[0]), float(list[1]), float(list[2]))
