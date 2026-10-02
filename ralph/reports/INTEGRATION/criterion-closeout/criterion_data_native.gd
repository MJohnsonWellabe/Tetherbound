extends SceneTree

## ROOT-only serialized execution request. This evidence probe does not enable
## flags, persist progress, grant rewards or claim controller/visual/co-op play.
## Disclosed fixtures: detached production species at level15; synthetic host
## station context used ONLY to exercise pure loadout staging. No context is
## passed to a live authority service. No save, receipt or ACK is invented.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const TMS := preload("res://scripts/creatures/tm_db.gd")
const TYPES := preload("res://scripts/combat/type_chart.gd")
const LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
const SOURCE_COMMIT := "582b2f13cc531f5cf733c43281c1100a6baa319b"
var checks: Dictionary = {}
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(criterion: String, condition: bool, label: String) -> void:
	checks[criterion] = int(checks.get(criterion, 0)) + 1
	if not condition:
		failures.append(criterion + ": " + label)


func read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		failures.append("Invalid JSON: " + path)
		return {}
	return parsed


func _run() -> void:
	var moves := MOVES.load_default()
	var tms := TMS.new()
	var learnsets := read_json("res://data/moves/learnsets.json")
	var signatures := read_json("res://data/moves/ultimates.json")
	var visuals: Dictionary = signatures.get("visuals", {})
	var rows: Dictionary = learnsets.get("species", {})
	var species: Dictionary = SPECIES.table()
	var shared: Array[String] = []
	var utilities: Array[String] = []
	var roles := {}
	for move_id: String in moves.move_ids():
		var move: Dictionary = moves.move(move_id)
		if move.get("slot") == "utility": utilities.append(move_id)
		if move.get("slot") == "ultimate" and move.get("ultimate", {}).get("unique") == false:
			shared.append(move_id)
	check("F23#1", TEACHING.learnset_errors(learnsets, moves).is_empty(), "actual native learnset validator accepts all authored rows")
	check("F23#2", utilities.size() >= 10, "at least ten registered utility moves")
	check("F35#0", shared.size() >= 16 and shared.size() <= 20, "shared signature count 16..20")
	check("F23#1", species.size() == 69, "57 base + twelve canonical water adapters; reserved bear not fabricated")
	for species_id: String in species:
		var row: Dictionary = rows.get(species_id, {})
		check("F23#1", not row.is_empty(), species_id + " has learnset")
		var early := TEACHING.available_moves(species_id, 1, [])
		var at_five := TEACHING.available_moves(species_id, 5, [])
		var at_fifteen := TEACHING.available_moves(species_id, 15, [])
		for unlock: Dictionary in row.get("unlocks", []):
			var id := str(unlock.get("move_id", ""))
			if unlock.get("level", 0) == 5:
				check("F23#1", not early.has(id) and at_five.has(id), species_id + " L5 gate " + id)
			if unlock.get("level", 0) == 15:
				check("F23#1", not at_five.has(id) and at_fifteen.has(id), species_id + " L15 gate " + id)
		# Every completed-tier prefix is a detached policy fixture, never an
		# earned feast claim. Exact set equality also rejects later-tier leakage.
		for tier: int in range(1, 6):
			var prefix: Array = []
			var preceding: Array = []
			for completed: int in range(1, tier + 1): prefix.append(completed)
			for completed: int in range(1, tier): preceding.append(completed)
			var after := TEACHING.available_moves(species_id, 1, prefix)
			var before := TEACHING.available_moves(species_id, 1, preceding)
			var expected_after: Array[String] = []
			var expected_before: Array[String] = []
			for authored: Dictionary in row.get("unlocks", []):
				var id := str(authored.get("move_id", ""))
				var level_one: bool = authored.has("level") and int(authored.level) <= 1
				var gate: int = int(authored.get("breakthrough_tier", 0))
				if level_one or (gate >= 1 and gate <= tier):
					if not expected_after.has(id): expected_after.append(id)
				if level_one or (gate >= 1 and gate < tier):
					if not expected_before.has(id): expected_before.append(id)
			after.sort()
			before.sort()
			expected_after.sort()
			expected_before.sort()
			check("F23#1", after == expected_after, species_id + " exact completed prefix1.." + str(tier))
			check("F23#1", before == expected_before, species_id + " exact preceding prefix for tier" + str(tier))
			for id: String in expected_after:
				if not expected_before.has(id):
					check("F23#1", not before.has(id) and after.has(id), species_id + " newly unlocked tier" + str(tier) + " excludes preceding tier " + id)
		var legal: Array[String] = []
		for id: String in at_fifteen:
			if moves.slot(id) == "utility": legal.append(id)
		check("F23#2", legal.size() >= 2, species_id + " at least two level-unlocked utility choices")
		roles[str(row.get("role_family", ""))] = true
		var creature: RefCounted = SPECIES.spawn(species_id)
		check("F35#0", creature != null, species_id + " actual species spawn")
		if creature == null: continue
		var ultimate := str(creature.get("move_ultimate"))
		check("F35#0", ultimate == str(row.get("ultimate", "")) and moves.slot(ultimate) == "ultimate",
			species_id + " production initial signature mapping")
		if moves.move(ultimate).get("ultimate", {}).get("unique") == false:
			check("F35#0", shared.has(ultimate), species_id + " belongs to declared shared signatures")
			check("F35#0", moves.move(ultimate).get("type") == species[species_id].get("type"), species_id + " primary type matches shared signature")
			check("F35#0", visuals.get(ultimate, {}).get("role") == row.get("role_family"), species_id + " exact shared signature type-role binding")
		creature.call("set_level", 15, {"level": {"cap": 60}})
		for index: int in legal.size():
			var request := {"edit_id": "criterion-native-" + str(index), "expected_revision": int(creature.get("loadout_revision")),
				"creature_uid": str(creature.get("uid")), "quick": str(creature.get("move_quick")),
				"charged": str(creature.get("move_charged")), "utility": legal[index]}
			var context := {"owned_creature_uids": [str(creature.get("uid"))], "station_kind": "altar", "within_reach": true, "in_combat": false}
			var result := TEACHING.stage_loadout_edit(creature, request, context, moves)
			check("F23#2", result.get("ok") == true and result.get("loadout", {}).get("utility") == legal[index], species_id + " legal utility stages through production equip policy")
			context.within_reach = false
			check("F23#2", TEACHING.stage_loadout_edit(creature, request, context, moves).get("ok") == false, species_id + " out-of-reach refuses")
		creature = null
	for role: String in ["WALL", "CHARGER", "CURRENT", "DIVER"]:
		check("F23#2", roles.has(role), "role covered " + role)
	for tm_id: String in tms.tm_ids():
		var tm: Dictionary = tms.tm(tm_id)
		var id := str(tm.get("move_id", ""))
		var primary := str(moves.move(id).get("type", ""))
		check("F23#1", tm.get("compatible_types") == [primary], tm_id + " canonical primary type only")
		for type_id: String in TYPES.known_types():
			check("F23#1", TEACHING.can_learn(type_id, tm_id, tms) == (type_id == primary), tm_id + " actual compatibility " + type_id)
	for move_id: String in moves.move_ids():
		check("F25#1", not LIBRARY.resolve(moves.move(move_id).get("vfx", {})).is_empty(), move_id + " actual native archetype resolution")
	check("F25#1", LIBRARY.resolve({"archetype": "criterion-native-unknown"}).is_empty(), "unmapped archetype refuses in production resolver")
	print("CRITERION_DATA_NATIVE_RESULT " + JSON.stringify({"fixture_source_commit": SOURCE_COMMIT,
		"checks_by_criterion": checks, "failures": failures, "shared_count": shared.size(), "utility_count": utilities.size(),
		"live_species": species.size(), "completed": true, "breakthrough_prefixes_checked": [1, 2, 3, 4, 5],
		"scope": "detached production catalogue/lookup/equip policy; no controller, earned state, save, ACK, co-op or visual proof"}))
	quit(0 if failures.is_empty() else 1)
