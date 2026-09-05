extends "res://tests/test_case.gd"

## N10-HARNESS-TESTS-0905. The harness/segment defects three lanes found on
## 2026-09-04 and correctly did not fix, pinned so they cannot come back.
##
## Every test here exercises the real thing -- the harness's own cost model,
## the game's own save reader, the shipped terrain config, the committed
## telemetry -- rather than reading a script's source text for a phrase.

const HARNESS := preload("res://tools/gate_f/operator_harness.gd")
const S09_SEED := preload("res://tools/gate_f/build_s09_entry_synthetic.gd")
const S06_SEED := preload("res://tools/gate_f/build_s06_entry_synthetic.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SPAWN_TABLES := preload("res://scripts/combat/spawn_tables.gd")
const CHAPTER_CURVE := preload("res://scripts/creatures/chapter_curve.gd")

const SEGMENTS := "res://tools/gate_f/segments/"
const TERRAIN := "res://data/config/terrain_playground.json"
const COMBAT := "res://data/config/combat.json"
const BANDS := "res://data/config/bands"
## Where committed Gate F telemetry lives. Absent from the CI checkout, which
## sparse-checks out `!/ralph/` -- see `_route_row_counts`.
const REPORTS := "res://ralph/reports"


# --- CL-H1 / W21: the cost model must price every step it can launch --------

## `chip_to_floor` had no case in `_predict_frames`, so the catch-all priced a
## step that can spend fifteen swings at thirty settle frames each at ONE
## frame. The cost gate exists to refuse a segment the box cannot afford, and
## it cannot do that on a number that is out by 500x.
func test_chip_to_floor_is_priced_at_its_full_swing_budget() -> void:
	var defaults: int = HARNESS._predict_frames([
		{"id": "A-01", "action": "chip_to_floor", "args": {}},
	])
	# `_step_chip_to_floor`'s own defaults: max_presses 15, settle_frames 30,
	# plus the four frames every injected press costs (`press`/`press_until`
	# use the same +4).
	assert_eq(defaults, 15 * (30 + 4),
		"a chip with no explicit budget must price at what it can actually cost")
	var named: int = HARNESS._predict_frames([
		{"id": "A-02", "action": "chip_to_floor",
			"args": {"max_presses": 6, "settle_frames": 10}},
	])
	assert_eq(named, 6 * (10 + 4), "an explicit budget must be priced at ITS worst case")
	assert_true(defaults > 100,
		"the catch-all's 1 frame is the defect: a step this expensive must never be free")


# --- CL-H4 / 2.14: the route-row thresholds must leave real headroom --------

## S02-60 was re-derived to 80% of the shortest healthy completion this segment
## has ever recorded. S04-61 and S05-60 were not: they were picked to sit under
## one or three cited runs and landed at 92% and 98.8% of their own shortest,
## which is a flake waiting for one slow run rather than a check that a
## recorder stopped.
func test_the_route_row_thresholds_leave_headroom_below_the_shortest_run() -> void:
	if not DirAccess.dir_exists_absolute(REPORTS):
		print("    (skipped: %s is not in this checkout — verify-unit-tests sparse-checks out "
			% REPORTS + "!/ralph/. Run this locally or in a full checkout.)")
		return
	for segment in ["S02", "S04", "S05"]:
		var shortest := _shortest_healthy_route(segment)
		if shortest <= 0:
			print("    (skipped %s: no committed telemetry to derive from)" % segment)
			continue
		var want := _route_rows_asserted(segment)
		assert_true(want > 0, "%s has no route_rows_at_least assert to check" % segment)
		assert_true(float(want) <= float(shortest) * 0.85,
			("%s asserts %d rows against a shortest healthy completion of %d (%.1f%%). "
			+ "S02-60's method is 80%%; anything over 85%% fails a working recorder on an "
			+ "ordinarily slow run.") % [segment, want, shortest, 100.0 * want / shortest])


# --- W21 finding 5: the S09 seed's satchel must actually land ---------------

## `build_s09_entry_synthetic.gd` declared `{"id": "revive", "count": 2}` and
## the loaded game reported `revive: 0` -- along with every other line. There
## is no `count` in the save format: `save_game.gd::_stack_from_json` reads
## `n`. This drives the seed's own layout through the game's own reader.
func test_the_s09_seed_satchel_survives_the_games_own_save_reader() -> void:
	var db: RefCounted = ITEM_DB.new()
	var slots: Array = S09_SEED.inventory_slots(db)
	assert_eq(slots.size(), INVENTORY.SLOT_COUNT,
		"the seed must write one entry per slot, positionally, the way _array_to_inventory reads")

	var bag: RefCounted = INVENTORY.new(db)
	var save: RefCounted = SAVE_GAME.new()
	# Round-tripped through JSON first, because that is what actually happens:
	# the builder writes a file and the loader parses it.
	var round_tripped: Variant = JSON.parse_string(JSON.stringify(slots))
	save._array_to_inventory(round_tripped, bag)

	for entry: Dictionary in S09_SEED.SATCHEL:
		var id := str(entry["id"])
		var want := int(entry["count"])
		assert_eq(int(bag.count(id)), want,
			("the seed declares %d x %s and the loaded satchel holds %d. "
			+ "A stack with no `n` loads as that item at zero.") % [want, id, int(bag.count(id))])


# --- W21 finding: S06's seed must carry recoveries for its own fights -------

func test_the_s06_seed_carries_a_revive_for_every_fight_it_scripts() -> void:
	var fights := _fight_count("S06")
	assert_true(fights >= 3, "S06 is expected to script at least three fights; found %d" % fights)
	var revives := 0
	for entry: Dictionary in S06_SEED.SATCHEL:
		if str(entry.get("id", "")) == "revive":
			revives = int(entry.get("n", 0))
	assert_true(revives > fights,
		("S06 seeds %d Revive(s) against %d scripted fights. Once the last one is spent every "
		+ "later `focus_item {item: \"revive\"}` FAILs naming an empty bag, and the step reports "
		+ "a defect in the recovery ladder that is really a defect in the seed.") % [revives, fights])


# --- CL-H3's remaining third: no walk may be scripted into a terrain carve --

## `S09-33` drove straight at (45, 7440) from the outer watch and stopped 81.3 m
## short, inside `sigil_gate_gorge_west` -- an authored 11 m-deep trench whose
## whole purpose is that the Sigil gate is the only way through it. Measured
## twice, by two lanes. Every `move_to` leg in a Gate 3 segment is checked here
## against every carve the terrain config authors, because a waypoint that
## crosses one cannot be walked by anything and is not a walker defect.
func test_no_gate3_walk_leg_is_scripted_across_an_authored_terrain_carve() -> void:
	var carves := _carves()
	assert_true(carves.size() >= 4, "terrain_playground.json authors no carves to check against")
	for segment in ["S06", "S07", "S08", "S09"]:
		var legs := _walk_legs(segment)
		for leg: Dictionary in legs:
			for carve: Dictionary in carves:
				var gap := _segment_gap(leg["from"], leg["to"], carve["a"], carve["b"])
				assert_true(gap >= float(carve["block"]),
					("%s %s walks from (%.1f, %.1f) to (%.1f, %.1f), which passes %.2f m from "
					+ "the centre line of `%s` -- an authored %.0f m-deep carve %.1f m wide at "
					+ "the rim. Nothing can walk that line; the waypoint has to route around it.")
					% [segment, str(leg["id"]), float(leg["from"].x), float(leg["from"].y),
						float(leg["to"].x), float(leg["to"].y), gap, str(carve["id"]),
						float(carve["depth"]), 2.0 * float(carve["block"])])



# --- item 10: a waypoint that cannot reach what it is aimed at --------------

## `S08-26` walked to spawn order 4020's authored `centre` and `S08-27` pressed
## `interact` there. `encounter_director.gd::_engageable()` searches
## `engage_range` (6 m); `_pick_clear_spot` scatters that cluster's four bodies
## across its authored `radius` (15.1 m) and, measured live, put the nearest at
## 9.70 m. There was never anything to engage, on any run, which is why two
## lanes reproduced the same silence by two different methods. A step that
## needs to reach a creature has to walk to the CREATURE (`move_to_entity`),
## not to the middle of where its cluster was authored.
func test_no_gate3_walk_aims_at_a_spawn_centre_it_cannot_engage_from() -> void:
	var engage := _engage_range()
	assert_true(engage > 0.0, "data/config/combat.json has no flow.engage_range to check against")
	var clusters := _spawn_clusters()
	assert_true(clusters.size() > 50, "found only %d spawn clusters; the table did not load" % clusters.size())
	for segment in ["S06", "S07", "S08", "S09"]:
		for raw: Variant in (_segment(segment).get("steps", []) as Array):
			var step := raw as Dictionary
			if str(step.get("action", "")) != "move_to":
				continue
			var at: Array = (step.get("args", {}) as Dictionary).get("at", []) as Array
			if at.size() < 2:
				continue
			var here := Vector2(float(at[0]), float(at[1]))
			for cluster: Dictionary in clusters:
				if here.distance_to(cluster["centre"]) > 0.5:
					continue
				assert_true(float(cluster["radius"]) <= engage,
					("%s %s walks to (%.1f, %.1f), which is the authored centre of spawn order %d "
					+ "(%s x%d, radius %.1f m). The director only offers an engage inside %.1f m, and "
					+ "the cluster's bodies scatter across that whole radius, so standing on the centre "
					+ "reaches nothing. Use move_to_entity.")
					% [segment, str(step.get("id", "")), here.x, here.y, int(cluster["order"]),
						str(cluster["species"]), int(cluster["count"]), float(cluster["radius"]), engage])


## Item 9. A step whose own title says it engages or challenges must be
## `interact_with`: that verb presses only when the arbiter has a live prompt
## whose text is the one the step means, and names what it saw otherwise. A
## bare `press interact` cannot tell a live offer from no offer, which is how
## S08-27 banked sixteen green presses into an unengaged world.
func test_no_gate3_engage_or_challenge_step_is_a_bare_press() -> void:
	for segment in ["S06", "S07", "S08", "S09"]:
		for raw: Variant in (_segment(segment).get("steps", []) as Array):
			var step := raw as Dictionary
			if str(step.get("action", "")) != "press":
				continue
			var args: Dictionary = step.get("args", {}) as Dictionary
			if str(args.get("control", "")) != "interact":
				continue
			var title := str(step.get("title", "")).to_lower()
			var engages := title.contains("engage") or title.contains("challenge") \
				or title.contains("fight ")
			assert_false(engages,
				("%s %s (\"%s\") is a bare `press interact`. An engage or a challenge has to be "
				+ "`interact_with` with the prompt text it means, or a press into nothing reads as a "
				+ "pass.") % [segment, str(step.get("id", "")), str(step.get("title", ""))])


## The other half of the same site, and the reason `operator_harness.gd` pins
## `TB_WORLD_SEED`. `data/config/spawn_tables.json` set `roll_new_worlds` true
## on 2026-09-02, so a new game rolls a seed and every cluster naming a `table`
## re-draws its species from it. Seed 0 is the authored world and nothing else
## is. This exercises the real roller.
func test_only_the_authored_seed_gives_the_segments_the_species_they_name() -> void:
	var cfg: Dictionary = SPAWN_TABLES.config()
	var entries := _spawn_entries()
	assert_false(entries.is_empty(), "no spawn entries to roll")
	var authored: Dictionary = SPAWN_TABLES.plan_for(entries, 0, cfg, CHAPTER_CURVE.config(), [])
	assert_true(authored.is_empty(),
		"seed 0 must not enter the roller at all -- that is what makes it the authored world")
	var moved := 0
	for seed_value in [1, 7, 12345, 2129586928]:
		var plan: Dictionary = SPAWN_TABLES.plan_for(entries, seed_value, cfg,
			CHAPTER_CURVE.config(), [])
		for entry: Dictionary in entries:
			var order := int(entry.get("order", -1))
			if not plan.has(order):
				continue
			if str((plan[order] as Dictionary).get("species", "")) != str(entry.get("species", "")):
				moved += 1
	assert_true(moved > 0,
		("a rolled seed must be able to change the species standing at an authored cluster -- if it "
		+ "cannot, this test is not measuring the thing operator_harness.gd pins the seed for"))
	assert_true(bool(SPAWN_TABLES.rolls_new_worlds(cfg)),
		("spawn_tables.json's `roll_new_worlds` is false again. If a new game no longer rolls, say so "
		+ "in operator_harness.gd::_pin_world_seed's own note rather than leaving it claiming a hazard "
		+ "that no longer exists."))


# --- helpers ----------------------------------------------------------------

func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())


func _segment(id: String) -> Dictionary:
	var raw: Variant = _read_json(SEGMENTS + id + ".json")
	return raw as Dictionary if raw is Dictionary else {}


func _fight_count(id: String) -> int:
	var fights := 0
	var index := 0
	var last := -99
	for raw: Variant in (_segment(id).get("steps", []) as Array):
		var step := raw as Dictionary
		var action := str(step.get("action", ""))
		var args: Dictionary = step.get("args", {}) as Dictionary
		if action == "fight_until_resolved":
			fights += 1
			last = index
		elif action == "press" and str(args.get("control", "")) == "combat_quick" \
				and int(args.get("times", 1)) > 1:
			# A counted press block is a fragment of a fight, not a fight: one
			# fight is regularly scripted as two or three blocks with a
			# `party_cycle` or a `wait` wedged between them (S06's Warrens
			# guardian is three). Blocks within a few steps of each other are
			# the same fight; a fresh one is a block that stands alone.
			if last < 0 or index - last > 3:
				fights += 1
			last = index
		index += 1
	return fights


## Every `move_to` leg as {id, from, to} in x/z, chained the way the segment
## actually walks them. The first leg's start is the entry save's own position,
## which is unknown here, so it is skipped rather than guessed.
func _walk_legs(id: String) -> Array:
	var out: Array = []
	var previous: Vector2 = Vector2.INF
	for raw: Variant in (_segment(id).get("steps", []) as Array):
		var step := raw as Dictionary
		if str(step.get("action", "")) != "move_to":
			continue
		var at: Array = (step.get("args", {}) as Dictionary).get("at", []) as Array
		if at.size() < 2:
			continue
		var here := Vector2(float(at[0]), float(at[1]))
		if previous != Vector2.INF:
			out.append({"id": str(step.get("id", "")), "from": previous, "to": here})
		previous = here
	return out


## Every authored terrain carve as a centre-line segment plus the half-width no
## walk may come inside of (the trench plus its rim).
func _carves() -> Array:
	var raw: Variant = _read_json(TERRAIN)
	var out: Array = []
	if not raw is Dictionary:
		return out
	for entry: Variant in ((raw as Dictionary).get("crossings", []) as Array):
		var crossing := entry as Dictionary
		var carve: Dictionary = crossing.get("carve", {}) as Dictionary
		if carve.is_empty():
			continue
		var centre: Array = carve.get("centre", []) as Array
		if centre.size() < 2:
			continue
		var axis := deg_to_rad(float(carve.get("axis_deg", 0.0)))
		var half := float(carve.get("half_length", 0.0))
		# `Vector2.RIGHT.rotated(axis_deg)`, the convention every consumer of
		# this data uses (`playground_heightfield.gd`, `gated_crossing.gd`,
		# `road_gate.gd`, `severed_spokes.gd`): axis 0 runs along +x.
		var along := Vector2.RIGHT.rotated(axis) * half
		var mid := Vector2(float(centre[0]), float(centre[1]))
		out.append({
			"id": str(crossing.get("id", "")),
			"a": mid - along, "b": mid + along,
			"block": float(carve.get("half_width", 0.0)) + float(carve.get("rim", 0.0)),
			"depth": float(carve.get("depth", 0.0)),
		})
	return out


## Shortest distance between two 2D segments. Zero when they cross.
func _segment_gap(p1: Vector2, p2: Vector2, q1: Vector2, q2: Vector2) -> float:
	if _crosses(p1, p2, q1, q2):
		return 0.0
	return minf(
		minf(_point_gap(p1, q1, q2), _point_gap(p2, q1, q2)),
		minf(_point_gap(q1, p1, p2), _point_gap(q2, p1, p2)))


func _point_gap(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length := ab.length_squared()
	var t := 0.0 if length == 0.0 else clampf((p - a).dot(ab) / length, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _crosses(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var d1 := (a - c).cross(d - c)
	var d2 := (b - c).cross(d - c)
	var d3 := (c - a).cross(b - a)
	var d4 := (d - a).cross(b - a)
	return ((d1 > 0.0) != (d2 > 0.0)) and ((d3 > 0.0) != (d4 > 0.0))


func _route_rows_asserted(id: String) -> int:
	for raw: Variant in (_segment(id).get("steps", []) as Array):
		var step := raw as Dictionary
		var args: Dictionary = step.get("args", {}) as Dictionary
		if str(args.get("check", "")) == "route_rows_at_least":
			return int(args.get("rows", 0))
	return 0


## The shortest healthy completion on record for `segment`, in route.csv rows.
## Filtered exactly as S02-60's own derivation filters: a run whose measured
## rate is not ~2 rows per play second is on a different clock and is excluded
## rather than averaged in.
func _shortest_healthy_route(segment: String) -> int:
	var shortest := -1
	var runs := DirAccess.open(REPORTS)
	if runs == null:
		return -1
	for run in runs.get_directories():
		var path := "%s/%s/%s/telemetry/route.csv" % [REPORTS, run, segment]
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var lines := file.get_as_text().strip_edges().split("\n")
		var rows := lines.size() - 1
		if rows < 2:
			continue
		var last := float(lines[lines.size() - 1].split(",")[0])
		if last <= 0.0 or float(rows) / last < 1.9:
			continue
		if shortest < 0 or rows < shortest:
			shortest = rows
	return shortest


func _engage_range() -> float:
	var raw: Variant = _read_json(COMBAT)
	if not raw is Dictionary:
		return 0.0
	return float(((raw as Dictionary).get("flow", {}) as Dictionary).get("engage_range", 0.0))


## Every spawn entry in the merged table -- the per-band files plus the root
## one -- exactly as `encounter_director.gd` reads them.
func _spawn_entries() -> Array:
	var out: Array = []
	var paths: Array[String] = ["res://data/config/spawns.json"]
	var bands := DirAccess.open(BANDS)
	if bands != null:
		for band in bands.get_directories():
			paths.append("%s/%s/spawns.json" % [BANDS, band])
	for path in paths:
		var raw: Variant = _read_json(path)
		if not raw is Dictionary:
			continue
		for entry: Variant in ((raw as Dictionary).get("spawns", []) as Array):
			if entry is Dictionary:
				out.append(entry)
	return out


func _spawn_clusters() -> Array:
	var out: Array = []
	for entry: Dictionary in _spawn_entries():
		var centre: Array = entry.get("centre", []) as Array
		if centre.size() < 3:
			continue
		out.append({
			"order": int(entry.get("order", -1)),
			"species": str(entry.get("species", "")),
			"count": int(entry.get("count", 1)),
			"radius": float(entry.get("radius", 0.0)),
			"centre": Vector2(float(centre[0]), float(centre[2])),
		})
	return out

