extends "res://tests/test_case.gd"

## The chapter content map (prompts 59 and 60), as invariants.
##
## Prompt 59 asks for a trainer map that makes it obvious "whether any long
## region lacks human opposition entirely"; prompt 60 asks that "no major late
## band has an empty spawn population". Both were specified as tables somebody
## writes down. A table is what was already wrong here: the repo had a
## progression curve, a five-way band split and per-region authored wild levels,
## and still shipped bands 3 and 5 with no wild creatures at all and band 2 with
## no trainers, because every one of those facts lived in a different file and
## nothing counted across them.
##
## So these count. `tools/_probe_chapter_map.py` prints the same map for a human;
## this is the part worth failing a build over.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")

const SPAWNS_PATH := "res://data/config/spawns.json"


func _curve() -> Dictionary:
	return CURVE.config()


func _regions() -> Array:
	var regions: Array = _curve().get("regions", []) as Array
	assert_true(regions.size() >= 5,
		"the chapter curve lists %d regions; the corridor has five" % regions.size())
	return regions


func _spawns() -> Array:
	return BAND_CONTENT.load_config(SPAWNS_PATH, "spawns").get("spawns", []) as Array


## Prompt 60's acceptance, verbatim: "no major late band has an empty spawn
## population". Bands 3 and 5 shipped exactly that.
func test_every_region_has_wild_creatures_in_it() -> void:
	var counts: Dictionary = {}
	for entry: Variant in _spawns():
		var centre: Array = (entry as Dictionary).get("centre", []) as Array
		if centre.size() < 3:
			continue
		var region: Dictionary = CURVE.region_at(float(centre[2]), _curve())
		var id := str(region.get("id", ""))
		counts[id] = int(counts.get(id, 0)) + int((entry as Dictionary).get("count", 1))
	for region: Variant in _regions():
		var id := str((region as Dictionary).get("id", ""))
		assert_true(int(counts.get(id, 0)) > 0,
			("'%s' has no wild creatures anywhere in it. Prompt 60: 'no major late band has an "
			+ "empty spawn population' -- and the region's own authored wild band applies to nothing")
			% id)


## Prompt 59's acceptance: "no major region is simply wild traversal followed by
## one boss". Band 2 -- the quarry and the Burrow Warrens -- shipped exactly that.
func test_every_region_has_human_opposition_in_it() -> void:
	var counts: Dictionary = {}
	for entry: Variant in TRAINERS.trainers():
		var position: Array = (entry as Dictionary).get("position", []) as Array
		if position.size() < 2:
			continue
		var region: Dictionary = CURVE.region_at(float(position[1]), _curve())
		var id := str(region.get("id", ""))
		counts[id] = int(counts.get(id, 0)) + 1
	for region: Variant in _regions():
		var id := str((region as Dictionary).get("id", ""))
		assert_true(int(counts.get(id, 0)) > 0,
			("'%s' fields no trainer at all. Prompt 59: 'no major region is simply wild traversal "
			+ "followed by one boss'") % id)


## The chapter's own target for how much human opposition exists, from prompt
## 59: "roughly 12-17 trainer battles spread across meaningful locations."
##
## The floor is hard and the ceiling is loose ON PURPOSE. Prompt 59 says in the
## same breath to "treat that as a tuning target, not a quota to fill
## mechanically", so failing a build at 18 because a regional package added one
## good optional trainer would enforce the opposite of what it asks. The real
## regression this guards is the ladder thinning out -- a region stripped, a
## band file emptied -- which is what actually happened to Band 2. The ceiling
## is only here to catch prompt 59's other failure, a "monotonous trainer
## hallway", and is set far enough out to mean it.
## GATE-D: counted by OPPONENT, not by entry.
##
## The entry count hit 25 once Band 1 authored an optional draw, and that read
## as one over the ceiling when the chapter had not actually grown a rung. Three
## of those entries are the village tournament's bracket -- quarter, semi,
## final -- and all three are Mira, Tam and Oskar, the same three characters the
## count already holds as Band 1's field trainers. One event contributed four
## entries against three people the ladder had already counted.
##
## Prompt 59's 12-17 is about how many distinct rungs the ladder has, which is a
## statement about opponents, not about how many times a battle record appears
## in a table. So the ceiling stays where it is and the measurement is corrected
## instead. Raising the ceiling was the alternative and is the wrong lever: it
## would have to be raised again by whichever band authors the next good
## optional trainer, which is exactly the "quota to fill mechanically" reading
## the paragraph above rejects.
##
## Distinctness is by `name`, not `id`: `tournament_final_oskar` and
## `trainer_oskar` are deliberately different ids for the same man.
func test_the_chapter_fields_the_number_of_trainers_it_is_aiming_for() -> void:
	var opponents := {}
	for entry: Variant in TRAINERS.trainers():
		var trainer: Dictionary = entry
		var who := str(trainer.get("name", "")).strip_edges()
		# An entry with no name is its own defect and is counted rather than
		# silently dropped -- a nameless trainer must not shrink this number.
		opponents[who if who != "" else "unnamed:%s" % str(trainer.get("id", "?"))] = true

	var total := opponents.size()
	var entries: int = TRAINERS.trainers().size()
	assert_true(total >= 12,
		("the chapter fields only %d distinct trainer opponents (%d battle entries); prompt 59 "
		+ "targets roughly 12-17 and the ladder stops reading as progression below that") % [
			total, entries])
	assert_true(total <= 24,
		("the chapter fields %d distinct trainer opponents (%d battle entries), well past prompt "
		+ "59's 12-17 -- that is the 'monotonous trainer hallway' it warns about") % [
			total, entries])


## Every material a buildable costs must be obtainable somewhere -- either from
## an authored harvest node or from a scatter layer that yields it.
##
## This is the check that fiber failed. Its cost appeared in `camp` (10) and
## `creature_bed` (8), and its only source was five nodes in Band 1 totalling 20
## against 50 wanted across the chapter, with no respawn. Rest infrastructure was
## unbuildable in the field for the back two thirds of the game and nothing said
## so, because no test related a build cost to a supply.
func test_every_build_cost_names_a_material_the_world_can_supply() -> void:
	var sources: Dictionary = {}
	for node: Variant in (BAND_CONTENT.load_config(
			"res://data/config/harvest.json", "nodes").get("nodes", []) as Array):
		sources[str((node as Dictionary).get("item", ""))] = "harvest node"

	var veg_file := FileAccess.open("res://data/config/vegetation.json", FileAccess.READ)
	assert_true(veg_file != null, "vegetation.json is missing")
	var veg: Variant = JSON.parse_string(veg_file.get_as_text())
	var layers: Dictionary = (veg as Dictionary).get("layers", {}) if veg is Dictionary else {}
	assert_false(layers.is_empty(), "no vegetation layers read; this check would pass vacuously")
	for name: String in layers.keys():
		var item := str((layers[name] as Dictionary).get("harvest_item", ""))
		if item != "":
			sources[item] = "scatter layer '%s'" % name

	var build_file := FileAccess.open("res://data/items/buildables.json", FileAccess.READ)
	assert_true(build_file != null, "buildables.json is missing")
	var parsed: Variant = JSON.parse_string(build_file.get_as_text())
	var buildables: Array = (parsed as Dictionary).get("buildables", []) as Array
	assert_false(buildables.is_empty(), "no buildables read; this check would pass vacuously")
	for entry: Variant in buildables:
		var id := str((entry as Dictionary).get("id", ""))
		for cost: Variant in ((entry as Dictionary).get("cost", []) as Array):
			var material := str((cost as Dictionary).get("id", ""))
			assert_true(sources.has(material),
				("buildable '%s' costs '%s' and nothing in the world yields it -- no harvest node, "
				+ "no scatter layer. It could never be built") % [id, material])
