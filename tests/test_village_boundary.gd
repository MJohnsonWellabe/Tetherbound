extends "res://tests/test_case.gd"

## OP-0830-1. The village boundary's geometry, checked without booting a world.
##
## The owner's report is that the village gate "doesn't keep you in", and the
## fix is an authored fence line with the gates as holes in it. Two things about
## that line can be wrong in ways no green flag would ever show, and both are
## cheap to check here rather than in a five-minute scene boot:
##
##   1. **Something the opening needs falls outside it.** Grandpa's farmhouse,
##      the village cast, the tournament ground and the practice meadow the
##      first catch happens in all have to be inside, or the boundary has locked
##      the player away from their own chapter. Every one of the points below is
##      a real coordinate read out of the file that places the thing.
##   2. **A road crosses the line where there is no gate.** That is a road
##      dead-ending at a fence, which reads as a broken world rather than as a
##      gate — and the four village roads are authored in
##      `terrain_playground.json`, not here, so this cannot be kept true by
##      staring at the polygon.
##
## `smoke_opening.gd` and `tools/_probe_village_gate_escape.gd` are what prove
## the barrier actually holds a player; this is what proves the shape is sane
## before anything spends five minutes finding out.

const BOUNDARY := preload("res://scripts/world/village_boundary.gd")
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"

## Places that must be inside the fence, and where each coordinate comes from.
## Written out rather than loaded, on purpose: the point of the check is that a
## human decided each of these belongs to Band 0, and a loader would silently
## start including whatever moved into range later.
const MUST_BE_INSIDE := {
	"Grandpa's farmhouse (playground_world.gd HOUSE_AT)": Vector2(-22.0, -16.0),
	"the farmhouse's far corner": Vector2(-27.5, -19.5),
	"the village well / square (paths.routes origin)": Vector2(10.0, -10.0),
	"Tam the smith (village_npcs)": Vector2(8.0, -16.0),
	"Mira (village_npcs)": Vector2(19.0, -1.0),
	"Oskar (village_npcs)": Vector2(22.0, -6.0),
	"Halda the registrar (village_npcs)": Vector2(23.5, 11.5),
	"the tournament board": Vector2(20.0, 15.0),
	"the practice bramblebun (band1 spawns order 0)": Vector2(30.0, -40.0),
	"the practice meadow road's end (paths.routes)": Vector2(30.0, -40.0),
	"Grandpa's farm plots": Vector2(-24.4, -6.6),
}

## Places that must be OUTSIDE it — the fence is the edge of Band 0, not a wall
## round the whole chapter.
const MUST_BE_OUTSIDE = {
	"The Rise trailhead signpost": Vector2(75.4, -38.9),
	"the first Band 1 pipwing": Vector2(20.0, 80.0),
	"the pond": Vector2(-105.0, 115.0),
	"the South Bridge": Vector2(0.0, 1330.0),
}


var config: Dictionary = {}
var outline: PackedVector2Array = PackedVector2Array()


func before_each() -> void:
	config = BOUNDARY.load_config()
	outline = BOUNDARY.outline(config)


func test_the_outline_is_an_authored_line_and_not_a_box() -> void:
	assert_true(outline.size() >= 8,
		"the village outline has %d points; a settlement edge that reads as built needs more than a box" % outline.size())


func test_everything_band_0_needs_is_inside_the_fence() -> void:
	for what: String in MUST_BE_INSIDE:
		var at: Vector2 = MUST_BE_INSIDE[what]
		assert_true(BOUNDARY.contains(outline, at),
			"%s is at (%.1f, %.1f), OUTSIDE the village boundary -- the opening cannot reach its own content" % [what, at.x, at.y])


func test_the_fence_is_the_edge_of_band_0_and_not_of_the_chapter() -> void:
	for what: String in MUST_BE_OUTSIDE:
		var at: Vector2 = MUST_BE_OUTSIDE[what]
		assert_false(BOUNDARY.contains(outline, at),
			"%s is at (%.1f, %.1f), INSIDE the village boundary -- the fence has swallowed the chapter" % [what, at.x, at.y])


## Every authored village road that leaves the settlement must leave through a
## gate. A crossing with no gate within `gate_clear_m` is a road that stops at a
## fence.
func test_every_road_leaves_through_a_gate() -> void:
	var routes := _routes()
	assert_true(not routes.is_empty(), "no paths.routes in %s; this check is vacuous" % TERRAIN_CONFIG)
	var gates := _gate_positions(config)
	var wall: Variant = config.get("wall", {})
	var clear: float = float((wall as Dictionary).get("gate_clear_m", 3.4)) if wall is Dictionary else 3.4

	for label: String in routes:
		var points: Array = routes[label]
		for i in points.size() - 1:
			var from: Vector2 = points[i]
			var to: Vector2 = points[i + 1]
			for crossing: Vector2 in _crossings(outline, from, to):
				var nearest := INF
				for gate: Vector2 in gates:
					nearest = minf(nearest, gate.distance_to(crossing))
				assert_true(nearest <= clear + 1.0,
					"the '%s' road crosses the village boundary at (%.1f, %.1f) and the nearest gate is %.1fm away; that road dead-ends at a fence" % [
						label, crossing.x, crossing.y, nearest])


## A gate that is not ON the line is either a leaf standing in open grass (the
## defect being fixed) or a hole in a fence with nothing in it.
func test_every_gate_stands_on_the_boundary_line() -> void:
	var gates := _gate_positions(config)
	assert_true(gates.size() >= 1, "the village boundary authors no gates at all; the settlement has no door")
	for gate: Vector2 in gates:
		var nearest := INF
		for i in outline.size():
			var a := outline[i]
			var b := outline[(i + 1) % outline.size()]
			nearest = minf(nearest, gate.distance_to(Geometry2D.get_closest_point_to_segment(gate, a, b)))
		assert_true(nearest <= 0.5,
			"the gate at (%.1f, %.1f) sits %.2fm off the boundary line; it is not a hole in anything" % [
				gate.x, gate.y, nearest])


func _gate_positions(config: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var block: Variant = config.get("gates", {})
	if not block is Dictionary:
		return out
	var entries: Variant = (block as Dictionary).get("entries", [])
	if not entries is Array:
		return out
	for raw: Variant in entries as Array:
		if not raw is Dictionary:
			continue
		var at: Variant = (raw as Dictionary).get("at", [])
		if at is Array and (at as Array).size() >= 2:
			out.append(Vector2(float(at[0]), float(at[1])))
	return out


func _routes() -> Dictionary:
	var out: Dictionary = {}
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		return out
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return out
	var paths: Variant = (parsed as Dictionary).get("paths", {})
	if not paths is Dictionary:
		return out
	var routes: Variant = (paths as Dictionary).get("routes", [])
	if not routes is Array:
		return out
	for raw: Variant in routes as Array:
		if not raw is Dictionary:
			continue
		var entry := raw as Dictionary
		var points: Variant = entry.get("points", [])
		if not points is Array:
			continue
		var line: Array = []
		for p: Variant in points as Array:
			if p is Array and (p as Array).size() >= 2:
				line.append(Vector2(float(p[0]), float(p[1])))
		if line.size() >= 2:
			out[str(entry.get("label", "unnamed"))] = line
	return out


## Where a segment crosses the closed outline. Returns every crossing, not the
## first: a road that leaves and re-enters needs a gate at both.
func _crossings(outline: PackedVector2Array, from: Vector2, to: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var hit: Variant = Geometry2D.segment_intersects_segment(from, to, a, b)
		if hit != null:
			out.append(hit as Vector2)
	return out


## --- GAME-F1: the first day's gathering nodes ------------------------------
##
## `MUST_BE_INSIDE` above is hand-written on purpose, and its comment says why:
## *"a loader would silently start including whatever moved into range later."*
## That is the right rule for landmarks. It is the wrong rule for the twenty
## band-1 harvest nodes that make up the chapter's first gathering lesson,
## and GAME-F1 is what the wrong rule cost.
##
## When the outline was rerouted on 2026-08-30, two nodes -- (44,-24) and
## (52,-30) -- ended up outside it. Nothing failed, because the nodes were on
## nobody's list. The fence is a hard `StaticBody3D`, so the chapter's own
## first gathering lesson sent the player out through their own gate and back
## for two of its twenty stops, and a player who has not yet found the gate key
## could not reach either at all. Worse and quieter: one of the two is a STONE
## node, and the village only authors three. With it unreachable the reachable
## stone (6) fell below the 8 that `progression.json`'s `home.required_pieces`
## (one Camp, one Creature Bed) actually costs -- so the opening's build rung
## became unaffordable without anyone writing a number down wrong.
##
## Hand-listing twenty coordinates here would not fix it either: they would be
## a COPY of `harvest.json`, and a node moved there would leave this file
## happily checking the old spot. So this reads the live file, and keeps the
## human decision where it belongs -- in the COUNT. Add or remove a village
## node and this fails until a person confirms the new number, which is exactly
## the review `MUST_BE_INSIDE`'s comment is protecting.

const HARVEST_CONFIG := "res://data/config/bands/band1_lower_meadows/harvest.json"

## The village square/well, `paths.routes`' own origin and the same anchor
## `MUST_BE_INSIDE` uses.
const VILLAGE_CENTRE := Vector2(10.0, -10.0)

## Everything band 1 authors for the first day's gathering lies within 47 m of
## the well; the next node in the file is 152 m away, at the pond. 80 m sits in
## the middle of that gap with room on both sides, so the selection is not
## sensitive to a node being nudged a few metres.
const VILLAGE_HARVEST_RADIUS := 80.0

## HUMAN DECISION. The number of authored gathering stops the first day walks.
## If this fails, a node was added to or removed from the village area: confirm
## the new node belongs inside the fence, then update this number.
##
## 20 -> 23: owner playtest 2026-08-30B item 15, "there needs to be more
## berries in the village" -- three new berry nodes (harvest.json orders
## 1031-1033), confirmed inside the fence by this same test file.
const VILLAGE_HARVEST_NODES := 23


func _village_harvest_nodes() -> Array:
	var file := FileAccess.open(HARVEST_CONFIG, FileAccess.READ)
	assert_true(file != null, "%s is missing" % HARVEST_CONFIG)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "%s is not a JSON object" % HARVEST_CONFIG)
	if not parsed is Dictionary:
		return []
	var out: Array = []
	for raw: Variant in ((parsed as Dictionary).get("nodes", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var node: Dictionary = raw
		var at: Array = node.get("at", []) as Array
		if at.size() < 2:
			continue
		var point := Vector2(float(at[0]), float(at[1]))
		if point.distance_to(VILLAGE_CENTRE) <= VILLAGE_HARVEST_RADIUS:
			out.append({"at": point, "item": str(node.get("item", "")), "label": str(node.get("label", ""))})
	return out


func test_the_village_gathering_lesson_is_the_size_a_human_signed_off() -> void:
	var nodes := _village_harvest_nodes()
	assert_eq(nodes.size(), VILLAGE_HARVEST_NODES,
		"%d band-1 harvest nodes now stand within %.0f m of the village well, not the %d this test was told to expect. A node was added or removed: confirm it belongs inside the fence, then update VILLAGE_HARVEST_NODES." % [nodes.size(), VILLAGE_HARVEST_RADIUS, VILLAGE_HARVEST_NODES])


## The check GAME-F1 exists for.
func test_every_village_harvest_node_is_inside_the_fence() -> void:
	for entry: Dictionary in _village_harvest_nodes():
		var at: Vector2 = entry["at"]
		assert_true(BOUNDARY.contains(outline, at),
			"the '%s' node (%s) at (%.1f, %.1f) is OUTSIDE the village boundary -- the first day's gathering lesson sends the player through their own gate, and a player without the gate key cannot reach it at all" % [entry["label"], entry["item"], at.x, at.y])
