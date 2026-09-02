extends Node3D

## OP-0830-1 — the edge of the home settlement, so that the village gate is the
## door of something.
##
## 2026-08-30 owner playtest: *"the village gate is pointless. it doesn't keep
## you in. it should keep you in until you find the key."*
##
## Reproduced before anything was written. `tools/_probe_village_gate_escape.gd`
## stands the player in the square with no key and walks them out on sixteen
## bearings: **nine of them left the village**, up to 79m out.
## `tools/_probe_village_layout.gd` says why — sweeping 36 bearings for the
## nearest solid body between 20m and 90m of the well, **24 of them had nothing
## at all**. The gate's own `seal_half_width` wings covered about 24m of one
## bearing; the settlement was open on every other side. So the leaf, the key
## and the search for the key were all decoration, and `MEADOWS_PROGRESSION_SPEC`
## §1/§15's rule — the world itself creates the gate, never a UI lock and never
## a level requirement — was not being kept by the one gate the player meets
## first.
##
## What this file is NOT. It is not a second gate mechanism: every leaf here is
## `road_gate.gd`, the body SA7 wrote and `smoke_traversal.gd` already tests,
## configured with the same key and the same flag. It is not a boundary
## *system* either — `world_perimeter.gd` is that, at 20.5km, with a per-band
## style table and its own noise; this is 250m of one village's fence and
## borrowing that machinery would have cost more than it saved.
##
## What it IS: an authored closed line from `data/config/village_boundary.json`,
## dressed with the settlement's own `fence_run` prefab, with a hole wherever an
## authored road crosses it and a gate leaf standing in the hole. No road in the
## village dead-ends at a fence, which is the failure mode a naive ring has.
##
## ONE LOCK, TWO DOORS. Both leaves carry `castle_gate_key` and
## `road_gate_open`. `road_gate.gd` already restores its own open pose from that
## flag on `build()`, so a reload is free; `_sync_gates()` below is only what
## makes the *other* leaf swing on the frame the player opens the first one.
## That is what a village gate with one key actually is, and it is why the fence
## can cross two roads without needing two keys or a second progression fact.
##
## THE COLLISION LESSON IS IMPORTED, NOT RELEARNED. `road_gate.gd::_build_wings`
## records at length how a barrier sized from the ground under each panel's
## CENTRE leaks wherever the terrain falls across the panel's span — the Sigil
## Gate was walked around at +6.0m off centre while a span check reported a
## contiguous barrier the whole time, because that check projected onto the
## across-axis and was blind to Y. Every panel below is sized from the lowest
## and highest ground its own footprint spans.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const ROAD_GATE := preload("res://scripts/world/road_gate.gd")
const CONFIG_PATH := "res://data/config/village_boundary.json"

## OWNER-0901-VILLAGE-GATE-ROADS-V2. 2026-09-01 owner playtest, second
## reproduction of the same class of bug OP-0830-1 first found: "I can still
## jump it some places." Measured with `tools/_probe_village_gate_roads_v2.gd`
## against the LIVE built scene (not the prefab's own comment, which says "two
## courses tall (~1.4m)"): the real collision top above the ACTUAL ground a
## player stands on cleared jump apex by 0.06m-0.11m, both at the fence panels
## `_build_panel` builds below and at `road_gate.gd`'s own leaf (`_build_gates`
## passes this same value through as `vault_guard_m`) -- `movement.json`'s
## `jump.height` is 1.35m, and a running jump timed at several different
## frames near the wall's own base cleared it at both gates and 3 of 8 sampled
## fence panels in the probe's own live physics test. This is a collision-only
## pad added to the box TOP past where the visible mesh ends, the same
## invisible-collision-supports-a-visible-boundary pattern this file's own
## header already documents (`_why` above, MEADOWS_PROGRESSION_SPEC sec1E) --
## no visual change, the mesh height and course placement are untouched.
## 1.0m over the already-measured ~1.4-1.7m clearance puts the floor at
## roughly 2.4-2.7m, a full metre of margin over the 1.35m jump apex rather
## than the previous few centimetres. TUNABLE (`wall.vault_guard_m`).
const VAULT_GUARD_DEFAULT_M := 1.0

var _config: Dictionary = {}
var _gates: Array[Node3D] = []
var _all_open := false


## The authored outline, as `Vector2` world (x,z) points. Static and pure so the
## containment/crossing questions can be asked in a unit test without booting a
## world — the same split `item_gate.gd` keeps from `road_gate.gd`.
static func outline(config: Dictionary) -> PackedVector2Array:
	var out := PackedVector2Array()
	var block: Variant = config.get("outline", {})
	if not block is Dictionary:
		return out
	var points: Variant = (block as Dictionary).get("points", [])
	if not points is Array:
		return out
	for raw: Variant in points as Array:
		if raw is Array and (raw as Array).size() >= 2:
			out.append(Vector2(float(raw[0]), float(raw[1])))
	return out


static func load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("village_boundary.gd: %s is missing" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("village_boundary.gd: %s is not a JSON object" % CONFIG_PATH)
		return {}
	return parsed as Dictionary


## Is a world point inside the settlement? Even-odd ray cast, the ordinary
## polygon test — `Geometry2D.is_point_in_polygon` would do, and is used by the
## test; this exists so callers that already hold the outline do not have to
## rebuild it.
static func contains(points: PackedVector2Array, at: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(at, points)


func build(world: Node3D) -> void:
	_config = load_config()
	if _config.is_empty():
		return
	var points := outline(_config)
	if points.size() < 3:
		push_error("village_boundary.gd: the outline needs at least three points")
		return

	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		push_error("no building recipes; the village boundary has no fence")
		return
	# building_prefabs.gd caches an un-parented Node3D template tree per prefab
	# name; without a real SceneTree parent it leaks RenderingServer resources at
	# engine shutdown (see building_prefabs.gd's own header on `_holder`).
	var template_holder := Node3D.new()
	template_holder.name = "PrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	prefabs.call("set_template_holder", template_holder)

	_build_gates(world)
	_build_fence(world, prefabs, points)


## The leaves first, because the fence has to know where the holes are.
func _build_gates(world: Node3D) -> void:
	var block: Variant = _config.get("gates", {})
	if not block is Dictionary:
		return
	var entries: Variant = (block as Dictionary).get("entries", [])
	if not entries is Array:
		return
	var key_item := str(_config.get("key_item", "castle_gate_key"))
	var flag := str(_config.get("flag", "road_gate_open"))
	var wall: Variant = _config.get("wall", {})
	var wall_cfg: Dictionary = wall if wall is Dictionary else {}
	var vault_guard := float(wall_cfg.get("vault_guard_m", VAULT_GUARD_DEFAULT_M))
	for raw: Variant in entries as Array:
		if not raw is Dictionary:
			continue
		var entry := raw as Dictionary
		var at: Variant = entry.get("at", [])
		if not at is Array or (at as Array).size() < 2:
			continue
		var gate: Node3D = ROAD_GATE.new()
		gate.name = str(entry.get("id", "VillageGate"))
		gate.set("key_item_ids", key_item)
		gate.set("flag_id", flag)
		gate.set("prompt_text", str(entry.get("prompt", "Try the gate")))
		gate.set("locked_conversation", str(entry.get("locked_conversation", "road_gate_locked")))
		gate.set("unlocked_conversation", str(entry.get("unlocked_conversation", "road_gate_unlocked")))
		# No `seal_half_width`: the fence either side of this leaf IS the seal
		# now, and it is a real authored line rather than a guess at how far a
		# sliding player will go. That guess is what SA7's own comment records
		# raising from 12.0 to 20.0 and still losing.
		# `vault_guard_m`: same collision-only anti-vault pad `_build_panel`
		# gives the fence either side of this leaf, in the SAME value from the
		# SAME `wall` config block, so the leaf is never the weak point in a
		# line the rest of which was just raised. See this file's own
		# `VAULT_GUARD_DEFAULT_M` header for the OWNER-0901-VILLAGE-GATE-
		# ROADS-V2 measurement behind it.
		gate.set("vault_guard_m", vault_guard)
		add_child(gate)
		gate.call("build", world, Vector2(float(at[0]), float(at[1])), float(entry.get("yaw_deg", 0.0)))
		_gates.append(gate)


func gate_positions() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for gate: Node3D in _gates:
		out.append(Vector2(gate.global_position.x, gate.global_position.z))
	return out


## Walk the closed outline, laying one panel per `panel_length_m`, skipping the
## stretch each gate occupies.
##
## Panels are laid along each EDGE from its own start, rather than along one
## arc-length walk of the whole loop, so a corner always falls on a panel end.
## A panel that straddles a corner is a panel at the wrong angle to both edges,
## and at a 40-degree turn that is a visible hole in the silhouette.
func _build_fence(world: Node3D, prefabs: RefCounted, points: PackedVector2Array) -> void:
	var wall: Variant = _config.get("wall", {})
	var cfg: Dictionary = wall if wall is Dictionary else {}
	var prefab := str(cfg.get("prefab", "fence_run"))
	var panel_length := maxf(float(cfg.get("panel_length_m", 6.15)), 0.5)
	var courses: int = maxi(int(cfg.get("courses", 2)), 1)
	var course_rise := float(cfg.get("course_rise_m", 0.62))
	var sink := float(cfg.get("sink_m", 0.12))
	var clear := float(cfg.get("gate_clear_m", 3.4))
	var bury := float(cfg.get("bury_m", 1.0))
	var samples: int = maxi(int(cfg.get("footprint_samples", 5)), 2)
	var vault_guard := float(cfg.get("vault_guard_m", VAULT_GUARD_DEFAULT_M))
	var gates := gate_positions()
	var total_height := _fence_total_height(prefabs, prefab, courses, course_rise)

	var built := 0
	for i in points.size():
		var from := points[i]
		var to := points[(i + 1) % points.size()]
		var span := to - from
		var length := span.length()
		if length < 0.01:
			continue
		var direction := span / length
		var count: int = maxi(int(round(length / panel_length)), 1)
		var step := length / float(count)
		for p in count:
			var centre := from + direction * (step * (float(p) + 0.5))
			if _inside_a_gate(centre, gates, clear):
				continue
			if _build_panel(world, prefabs, prefab, centre, direction, step,
					courses, course_rise, sink, total_height, bury, samples, vault_guard, built):
				built += 1
	if built == 0:
		push_error("the village boundary built no fence at all; the settlement is open")

	_build_corner_guards(world, points, gates, clear, bury, vault_guard, total_height)


func _inside_a_gate(centre: Vector2, gates: Array[Vector2], clear: float) -> bool:
	for gate: Vector2 in gates:
		if centre.distance_to(gate) <= clear:
			return true
	return false


## The fence prefab's own stacked height, measured once from a throwaway
## instance rather than per panel — every panel uses the same prefab and the
## same course count, so the height is one number, not forty-nine identical
## measurements. `_build_corner_guards` needs this exact number too, so it is
## computed here rather than buried inside `_build_panel`.
func _fence_total_height(prefabs: RefCounted, prefab: String, courses: int, course_rise: float) -> float:
	var piece: Node3D = prefabs.call("instantiate", prefab)
	if piece == null:
		return 1.2
	var aabb: AABB = prefabs.call("combined_aabb", piece)
	piece.queue_free()
	return maxf(aabb.size.y + course_rise * float(courses - 1), 1.2)


## One panel: the visible fence at the ground height under its own centre, and
## a collider sized from the whole footprint it spans.
##
## Returns false when there is no ground under it — off the terrain entirely,
## which the outline should never be, but a panel hanging in the air is worse
## than a reported gap.
func _build_panel(world: Node3D, prefabs: RefCounted, prefab: String, centre: Vector2,
		direction: Vector2, length: float, courses: int, course_rise: float,
		sink: float, total_height: float, bury: float, samples: int, vault_guard: float, index: int) -> bool:
	var ground: float = float(world.call("ground_height_at", centre.x, centre.y))
	if is_nan(ground):
		return false

	var lowest := ground
	var highest := ground
	for s in samples:
		var t: float = -0.5 + float(s) / float(samples - 1)
		var probe := centre + direction * (length * t)
		var g: float = float(world.call("ground_height_at", probe.x, probe.y))
		if is_nan(g):
			continue
		lowest = minf(lowest, g)
		highest = maxf(highest, g)

	# `rotation.y = θ` carries local +X onto (cos θ, -sin θ) — measured, not
	# assumed (`road_gate.gd`'s own `tools/_probe_gate_leaf_axis.gd` note). The
	# fence prefabs lay their modules along local X, so the panel's yaw is the
	# angle that puts local +X on the edge direction.
	var yaw := atan2(-direction.y, direction.x)

	var panel := Node3D.new()
	panel.name = "FencePanel_%d" % index
	panel.position = Vector3(centre.x, ground - sink, centre.y)
	panel.rotation.y = yaw
	add_child(panel)

	for course in courses:
		var piece: Node3D = prefabs.call("instantiate", prefab)
		if piece == null:
			panel.queue_free()
			return false
		# Alternate courses are flipped, the same trick `road_gate_leaf` uses to
		# stack two runs of the one fence module without the join reading as a
		# repeat.
		piece.name = "Course%d" % course
		piece.position = Vector3(0.0, course_rise * float(course), 0.0)
		piece.rotation.y = PI if course % 2 == 1 else 0.0
		panel.add_child(piece)

	# Collision is the WHOLE footprint's span, sunk below the lowest ground it
	# crosses and topped a full panel height above the highest — see this file's
	# own header on why a centre sample is not enough. `vault_guard` extends the
	# COLLISION top only, past the visible fence's own silhouette — see this
	# file's own header const for why the mesh height alone is not enough.
	var bottom := lowest - bury
	var top := highest + total_height + vault_guard
	var body := StaticBody3D.new()
	body.name = "FencePanelCollision_%d" % index
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# A shade longer than the step so consecutive panels overlap rather than
	# meeting exactly: two boxes that share a face leave a seam a
	# CharacterBody3D can be squeezed through on a bad frame. This overlap is
	# only ever between two COLINEAR panels on the same straight edge — see
	# `_build_corner_guards` for the polygon-vertex case this does not cover.
	box.size = Vector3(length + 0.3, top - bottom, 0.5)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(centre.x, (bottom + top) * 0.5, centre.y)
	body.rotation.y = yaw
	add_child(body)
	return true


## OWNER-0902-VILLAGE-GATE-REGRESSION. A third owner reproduction of "the
## village gate is not on every exit"/"I can still jump it some places",
## after two earlier fixes (the outline itself, then a vault-height pad on
## every panel) each re-broke by direct play. Both earlier fixes treated the
## fence as a sequence of independent straight panels and never looked at
## what happens WHERE THEY MEET.
##
## Each panel above is a thin (0.5m) slab whose long axis runs along its own
## edge's direction, overshooting the edge's own endpoints by 0.15m (half of
## `_build_panel`'s 0.3m pad) so consecutive panels on the SAME straight edge
## overlap. That overlap is along a single shared direction and closes a gap
## between two colinear boxes fine. It does nothing for a POLYGON VERTEX,
## where two edges meet at an angle: the outline turns by anywhere from 5 to
## nearly 70 degrees at its 22 corners (measured directly from
## `village_boundary.json`'s own `outline.points`), and two thin oriented
## slabs that each end 0.15m past a shared point, at DIFFERENT angles, do not
## sweep the wedge between them — a box's own end is a flat cut perpendicular
## to its length, not a mitre matched to the next edge's angle. The sharper
## the turn, the wider that wedge, and nothing before this ever tested a
## corner: every probe (`tools/_probe_village_gate_roads_v2.gd`'s own PART 5,
## and the escape sweep before it) only ever sampled panel CENTRES or a
## handful of panels by index, never a vertex.
##
## The fix is not a bigger overlap number — no straight-panel overshoot closes
## a wedge whose width grows with the turn angle. It is a third kind of
## collider this file never had: one small AXIS-ALIGNED post per outline
## vertex, centred exactly on the vertex (which is where both adjacent
## panels' own centrelines terminate) and wide enough in every direction to
## overlap both of those thin 0.5m-thick slabs regardless of which way they
## turn. A square post covers a bend axis-aligned rectangles cannot, the same
## reason a fence POST exists at every real fence corner and not just panels.
func _build_corner_guards(world: Node3D, points: PackedVector2Array, gates: Array[Vector2],
		clear: float, bury: float, vault_guard: float, total_height: float) -> void:
	# Half-width of the square post, metres. OWNER-0902: first landed at 0.6,
	# which overlapped each adjacent panel's near corner by only ~0.3m of true
	# margin (measured directly: panel corners sat 0.29-0.30m from the vertex).
	# The exhaustive PART 6 sweep still caught ONE corner jumping out through
	# that overlap despite a measured VERTICAL clearance there of well over 2m
	# -- not a height defect, a seam: two separately-built StaticBody3D shapes
	# that only just overlap, at one specific running-jump timing out of seven
	# tried, let the character's swept collision query find daylight at the
	# exact line where the post's flat face meets the panel's flat face at an
	# angle. A knife's-edge overlap is exactly the kind of margin that holds on
	# most timings and fails on one. 1.1m turns that ~0.3m of true overlap into
	# ~0.8m -- not a tuned minimum, a decisive margin, because a value this
	# cheap (invisible collision only, never the visible mesh) is not worth
	# re-deriving to the metre a third time.
	const POST_HALF := 1.1
	const POST_SAMPLE_STEP_M := 1.1
	var n := points.size()
	var built := 0
	for i in n:
		var cur := points[i]
		if _inside_a_gate(cur, gates, clear):
			continue
		var prev := points[(i - 1 + n) % n]
		var next := points[(i + 1) % n]
		var to_prev := (prev - cur).normalized()
		var to_next := (next - cur).normalized()
		var lowest := INF
		var highest := -INF
		for probe: Vector2 in [cur, cur + to_prev * POST_SAMPLE_STEP_M, cur + to_next * POST_SAMPLE_STEP_M]:
			var g: float = float(world.call("ground_height_at", probe.x, probe.y))
			if is_nan(g):
				continue
			lowest = minf(lowest, g)
			highest = maxf(highest, g)
		if is_inf(lowest) or is_inf(highest):
			continue
		var bottom := lowest - bury
		var top := highest + total_height + vault_guard
		var body := StaticBody3D.new()
		body.name = "FenceCornerGuard_%d" % i
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(POST_HALF * 2.0, top - bottom, POST_HALF * 2.0)
		shape.shape = box
		body.add_child(shape)
		body.position = Vector3(cur.x, (bottom + top) * 0.5, cur.y)
		add_child(body)
		built += 1
	if built == 0 and n > 0:
		push_warning("village_boundary.gd: no corner guards built; every vertex sat inside a gate's clear zone")


## One lock, two doors. `road_gate.gd` restores its own open pose from the
## shared flag when it builds, so this only has to catch the frame on which the
## player opens one of them — and `open_permanently()` is idempotent, which is
## what lets this be a plain poll rather than a signal nobody else needs.
func _process(_delta: float) -> void:
	if _all_open or _gates.is_empty():
		return
	_sync_gates()


func _sync_gates() -> void:
	var any_open := false
	for gate: Node3D in _gates:
		if bool(gate.call("is_open")):
			any_open = true
			break
	if not any_open:
		return
	for gate: Node3D in _gates:
		gate.call("open_permanently")
	_all_open = true


## SG46, by the same route the road gate already takes: the Warden falls and the
## region's keyed gates stop being gates. Idempotent.
func open_permanently() -> void:
	for gate: Node3D in _gates:
		gate.call("open_permanently")
	_all_open = true
