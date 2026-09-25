extends "res://tests/test_case.gd"

## F06 / SYSTEMS §8 ("No flight ... past unopened chapter gates"): the upper
## counterweight gate and its Fly seal, checked from data alone (no tree).
##
## The gate protects upper_cloudreach and summit_final_stronghold, so it stands
## where windscar_counterweight_pass enters the upper_cloudreach region bounds,
## past the Windscar beacon crown, bell and optional_loop pickups (Windscar
## content that must stay reachable before the upper unlock). On the ground the
## barrier spans the route ridge's full walkable top; in the air every stair
## point past the gate plane lies inside a restriction gated by
## cloudreach_upper_route_unlocked, and no legal pre-unlock point or volume
## touches one, with fly_controller's swept margins applied.

const WORLD_PATH := "res://data/config/cloudreach_world.json"
const PHYSICAL_PATH := "res://data/config/cloudreach_physical_runtime.json"
const VISUAL_PATH := "res://data/config/cloudreach_visual.json"
const BEACON_PATH := "res://data/config/cloudreach_windscar_beacon_visual.json"
const CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const FLY_PATH := "res://data/config/fly_traversal.json"
const GATE_ID := "upper_counterweight_gate"
const ROUTE_ID := "windscar_counterweight_pass"
const UPPER_FLAG := "cloudreach_upper_route_unlocked"
## Pre-unlock flags a player can hold while the upper route is still locked.
const PRE_UPPER_FLAGS := ["", "fly_traversal_unlocked", "cloudreach_act_i_complete"]
## `_route_ridge`: route width when a route authors none, and the largest
## shoulder flare (irregular = 0.84 + 0.18 sin + 0.08 cos).
const DEFAULT_ROUTE_WIDTH_M := 7.5
const MAX_SHOULDER_FLARE := 1.10
## scenes/player/player.tscn capsule radius.
const TRAINER_RADIUS_M := 0.4
## The authored beacon crown is 46 x 44 m around its anchor (beacon visual note).
const BEACON_CROWN_HALF := Vector2(23.0, 22.0)

var _world: Dictionary
var _physical: Dictionary
var _visual: Dictionary
var _beacon: Dictionary
var _chapter: Dictionary
var _fly: Dictionary


func before_each() -> void:
	_world = _read(WORLD_PATH)
	_physical = _read(PHYSICAL_PATH)
	_visual = _read(VISUAL_PATH)
	_beacon = _read(BEACON_PATH)
	_chapter = _read(CHAPTER_PATH)
	_fly = _read(FLY_PATH)


func test_gate_stands_where_the_pass_enters_upper_cloudreach_past_the_beacon() -> void:
	var gate := _gate()
	var line := _line()
	var at := _vec(gate.get("position", []))
	var progress := _progress(line, at)
	assert_true(float(progress["h"]) < 0.1, "the gate is on the %s polyline (%.2f m off)" % [ROUTE_ID, float(progress["h"])])
	var s_gate := float(progress["s"])
	var upper := _region_bounds("upper_cloudreach")
	assert_true(_in_bounds(_point_at(line, s_gate + 0.01), upper), "the gate point is inside upper_cloudreach")
	assert_false(_in_bounds(_point_at(line, s_gate - 1.0), upper), "one metre before the gate is still outside upper_cloudreach")
	assert_true((gate.get("protects_region_ids", []) as Array).has("upper_cloudreach"))
	for named: Dictionary in _beacon_points():
		var s := float(_progress(line, named["at"])["s"])
		assert_true(s < s_gate - 20.0, "%s (%.1f m along the pass) is before the gate (%.1f m)" % [named["name"], s, s_gate])


func test_gate_spans_the_route_ridge_walkable_width() -> void:
	var gate := _gate()
	var landmass: Dictionary = _visual.get("landmass", {})
	var route := _route(ROUTE_ID)
	var width := float(route.get("width_m", DEFAULT_ROUTE_WIDTH_M))
	var half := maxf(float(landmass.get("route_shoulder_min_half_width_m", 24.0)),
		width * float(landmass.get("route_shoulder_path_multiplier", 3.8)))
	var needed := 2.0 * (half * MAX_SHOULDER_FLARE + TRAINER_RADIUS_M)
	assert_true(float(gate.get("opening_width_m", 16.0)) >= needed,
		"the gate spans the walkable width: %.1f m >= %.1f m" % [float(gate.get("opening_width_m", 16.0)), needed])
	var drop := float(landmass.get("route_edge_drop_min_m", 4.0)) + 2.0 * float(landmass.get("route_edge_drop_range_m", 9.0))
	assert_true(float(gate.get("barrier_depth_below_m", 0.0)) >= drop,
		"the barrier reaches the ridge's deepest dropped edge: %.1f m >= %.1f m" % [float(gate.get("barrier_depth_below_m", 0.0)), drop])


func test_every_stair_point_past_the_gate_is_fly_sealed() -> void:
	var line := _line()
	var gate := _vec(_gate().get("position", []))
	var s_gate := float(_progress(line, gate)["s"])
	var half := _walkable_half_width()
	var seals := _upper_seals()
	assert_true(seals.size() >= 3, "upper, summit and counterweight-stair seals are authored")
	var total := _length(line)
	var s := s_gate + 0.25
	var misses: Array[String] = []
	while s <= total:
		var centre := _point_at(line, s)
		var dir := _dir_at(line, s)
		var right := Vector3(dir.z, 0.0, -dir.x)
		for step in 9:
			var lateral := lerpf(-half, half, float(step) / 8.0)
			var p := centre + right * lateral
			if not _inside_any(p, seals) and misses.size() < 8:
				misses.append("s=%.1f lateral=%.1f %s" % [s - s_gate, lateral, p])
		s += 2.0
	for raw: Variant in _route(ROUTE_ID).get("polyline", []):
		var vertex := _vec(raw)
		if float(_progress(line, vertex)["s"]) > s_gate and not _inside_any(vertex, seals):
			misses.append("polyline vertex %s" % vertex)
	assert_true(misses.is_empty(), "stair points past the gate outside every %s seal: %s" % [UPPER_FLAG, str(misses)])


func test_legal_pre_unlock_content_is_outside_every_upper_seal() -> void:
	var seals := _upper_seals()
	var line := _line()
	var gate := _vec(_gate().get("position", []))
	var s_gate := float(_progress(line, gate)["s"])
	var checked := 0
	# The stair on the open side of the gate, across its walkable width, up to
	# 5 m before the plane (axis-aligned slices reach 4.0 m + 0.75 m back).
	var half := _walkable_half_width()
	var s := 0.0
	while s <= s_gate - 5.0:
		var centre := _point_at(line, s)
		var dir := _dir_at(line, s)
		var right := Vector3(dir.z, 0.0, -dir.x)
		for step in 9:
			var p := centre + right * lerpf(-half, half, float(step) / 8.0)
			_assert_clear("open stair s=%.1f" % s, p, seals)
			checked += 1
		s += 2.0
	_assert_clear("gate approach stand 9 m before the gate", _point_at(line, s_gate - 9.0), seals)
	_assert_clear("the former gate position", Vector3(-123.4, 474.5, 2481.4), seals)
	for named: Dictionary in _beacon_points():
		_assert_clear(str(named["name"]), named["at"], seals)
		checked += 1
	for id: String in ["windscar_floor_loop", "windscar_to_high_roost_flight"]:
		var route_line := _polyline(_route(id))
		var t := 0.0
		var length := _length(route_line)
		while t <= length:
			_assert_clear("%s at %.0f m" % [id, t], _point_at(route_line, t), seals)
			checked += 1
			t += 5.0
	for landmark: Dictionary in _world.get("landmarks", []):
		if PRE_UPPER_FLAGS.has(str(landmark.get("requires_unlock", ""))):
			_assert_clear("landmark " + str(landmark.get("id", "")), _vec(landmark.get("position", [])), seals)
			checked += 1
	for gate_spec: Dictionary in _world.get("gates", []):
		if str(gate_spec.get("id", "")) != GATE_ID:
			_assert_clear("gate " + str(gate_spec.get("id", "")), _vec(gate_spec.get("position", [])), seals)
	for interaction: Dictionary in _physical.get("interactions", []):
		if not (interaction.get("requires_flags", []) as Array).has(UPPER_FLAG) and _pre_upper(interaction.get("requires_flags", [])):
			_assert_clear("interaction " + str(interaction.get("id", "")), _vec(interaction.get("position", [])), seals)
			checked += 1
	for objective: Dictionary in _physical.get("landing_objectives", []):
		if _pre_upper(objective.get("requires_flags", [])):
			_assert_clear("landing " + str(objective.get("id", "")), _vec(objective.get("position", [])), seals)
			checked += 1
	var trial: Dictionary = _physical.get("trial", {})
	_assert_box_clear("trial volume", AABB(_vec(trial.get("bounds_position", [])), _vec(trial.get("bounds_size", []))), seals)
	for trial_gate: Dictionary in trial.get("gates", []):
		_assert_clear("trial gate", _vec(trial_gate.get("position", [])), seals)
	var lift: Dictionary = trial.get("updraft", {})
	_assert_box_clear("trial updraft", AABB(_vec(lift.get("position", [])), _vec(lift.get("size", []))), seals)
	for draft: Dictionary in _physical.get("updrafts", []):
		if PRE_UPPER_FLAGS.has(str(draft.get("requires_flag", ""))):
			_assert_box_clear("updraft " + str(draft.get("id", "")), AABB(_vec(draft.get("position", [])), _vec(draft.get("size", []))), seals)
			checked += 1
	for pickup: Dictionary in _chapter.get("pickups", []):
		if str(pickup.get("region_id", "")) == "windscar_ravine" and PRE_UPPER_FLAGS.has(str(pickup.get("requires_unlock", ""))):
			_assert_clear("pickup " + str(pickup.get("id", "")), _vec(pickup.get("position", [])), seals)
			checked += 1
	for camp: Dictionary in (_chapter.get("camping_contract", {}) as Dictionary).get("camps", []):
		if str(camp.get("region_id", "")) == "windscar_ravine":
			_assert_clear("camp " + str(camp.get("id", "")), _vec(camp.get("position", [])), seals)
	assert_true(checked > 100, "legal pre-unlock content was actually sampled (%d)" % checked)


# --- helpers ------------------------------------------------------------------------

## A point is "clear" when fly_controller would not refuse it: its swept test
## grows each box by the body clearance sideways/up and the carried height down.
func _assert_clear(label: String, p: Vector3, seals: Array[Dictionary]) -> void:
	for seal: Dictionary in seals:
		if _swept(seal["bounds"]).has_point(p):
			assert_true(false, "%s %s is inside the Fly seal %s" % [label, p, seal["id"]])
			return


func _assert_box_clear(label: String, box: AABB, seals: Array[Dictionary]) -> void:
	for seal: Dictionary in seals:
		if _swept(seal["bounds"]).intersects(box):
			assert_true(false, "%s %s overlaps the Fly seal %s" % [label, box, seal["id"]])
			return


func _swept(box: AABB) -> AABB:
	var margin := float(_fly.get("body_clearance_m", 0.5))
	var height := float(_fly.get("collision_height_m", 4.5))
	return AABB(box.position - Vector3(margin, height, margin), box.size + Vector3(2.0 * margin, height + margin, 2.0 * margin))


func _inside_any(p: Vector3, seals: Array[Dictionary]) -> bool:
	for seal: Dictionary in seals:
		if (seal["bounds"] as AABB).has_point(p):
			return true
	return false


func _upper_seals() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for spec: Dictionary in _physical.get("restrictions", []):
		if str(spec.get("requires_flag", "")) == UPPER_FLAG:
			out.append({"id": str(spec.get("id", "")), "bounds": AABB(_vec(spec.get("position", [])), _vec(spec.get("size", [])))})
	return out


func _pre_upper(flags: Variant) -> bool:
	if not flags is Array:
		return true
	for flag: Variant in flags:
		if not PRE_UPPER_FLAGS.has(str(flag)) and str(flag).begins_with("cloudreach_upper"):
			return false
		if str(flag) in ["cloudreach_act_ii_complete", "cloudreach_upper_anchors_disabled", "defeated_cloudreach_voss",
				"side_aerie_observatory_surveyed", "sky_shrine_reached", "storm_anchor_engine_truth_learned"]:
			return false
	return true


func _walkable_half_width() -> float:
	var landmass: Dictionary = _visual.get("landmass", {})
	var width := float(_route(ROUTE_ID).get("width_m", DEFAULT_ROUTE_WIDTH_M))
	var half := maxf(float(landmass.get("route_shoulder_min_half_width_m", 24.0)),
		width * float(landmass.get("route_shoulder_path_multiplier", 3.8)))
	return half * MAX_SHOULDER_FLARE + TRAINER_RADIUS_M


func _beacon_points() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var anchor_xz: Array = _beacon.get("anchor_xz", [])
	var landmark_y := 500.0
	for landmark: Dictionary in _world.get("landmarks", []):
		if str(landmark.get("id", "")) == "windscar_beacon":
			landmark_y = float((landmark.get("position", [0, 500, 0]) as Array)[1])
	var anchor := Vector3(float(anchor_xz[0]), landmark_y, float(anchor_xz[1]))
	out.append({"name": "windscar beacon anchor", "at": anchor})
	var heading_raw: Array = _beacon.get("stand_heading_xz", [1, 0])
	var heading := Vector2(float(heading_raw[0]), float(heading_raw[1])).normalized() * float(_beacon.get("forward_offset_m", 15.0))
	out.append({"name": "windscar beacon arch", "at": anchor + Vector3(heading.x, 0.0, heading.y)})
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			out.append({"name": "windscar beacon crown corner", "at": anchor + Vector3(sx * BEACON_CROWN_HALF.x, 0.0, sz * BEACON_CROWN_HALF.y)})
	for raw: Variant in _beacon.get("pickup_ring_xz", []):
		var xz: Array = raw
		out.append({"name": "windscar beacon pickup", "at": Vector3(float(xz[0]), landmark_y, float(xz[1]))})
	for interaction: Dictionary in _physical.get("interactions", []):
		if str(interaction.get("id", "")) == "side_windscar_bell":
			out.append({"name": "side_windscar_bell", "at": _vec(interaction.get("position", []))})
	return out


func _gate() -> Dictionary:
	for spec: Dictionary in _world.get("gates", []):
		if str(spec.get("id", "")) == GATE_ID:
			return spec
	assert_true(false, "%s is authored" % GATE_ID)
	return {}


func _route(id: String) -> Dictionary:
	for spec: Dictionary in _world.get("routes", []):
		if str(spec.get("id", "")) == id:
			return spec
	assert_true(false, "route %s is authored" % id)
	return {}


func _line() -> Array[Vector3]:
	return _polyline(_route(ROUTE_ID))


func _polyline(route: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for raw: Variant in route.get("polyline", []):
		out.append(_vec(raw))
	return out


func _region_bounds(id: String) -> Dictionary:
	for region: Dictionary in _world.get("regions", []):
		if str(region.get("id", "")) == id:
			return region.get("bounds", {})
	return {}


func _in_bounds(p: Vector3, b: Dictionary) -> bool:
	return p.x >= float(b.get("min_x", 0)) and p.x <= float(b.get("max_x", 0)) \
		and p.y >= float(b.get("min_y", 0)) and p.y <= float(b.get("max_y", 0)) \
		and p.z >= float(b.get("min_z", 0)) and p.z <= float(b.get("max_z", 0))


## Plan-view closest point: arc length `s` to it and horizontal distance `h`.
func _progress(line: Array[Vector3], p: Vector3) -> Dictionary:
	var best := {"s": 0.0, "h": INF}
	var run := 0.0
	var flat := Vector3(p.x, 0.0, p.z)
	for i in line.size() - 1:
		var a := Vector3(line[i].x, 0.0, line[i].z)
		var b := Vector3(line[i + 1].x, 0.0, line[i + 1].z)
		var q := Geometry3D.get_closest_point_to_segment(flat, a, b)
		var h := flat.distance_to(q)
		if h < float(best["h"]):
			best = {"s": run + a.distance_to(q), "h": h}
		run += a.distance_to(b)
	return best


func _length(line: Array[Vector3]) -> float:
	var run := 0.0
	for i in line.size() - 1:
		run += Vector2(line[i + 1].x - line[i].x, line[i + 1].z - line[i].z).length()
	return run


## The polyline point at plan arc length `s` (height interpolated).
func _point_at(line: Array[Vector3], s: float) -> Vector3:
	var run := 0.0
	for i in line.size() - 1:
		var length := Vector2(line[i + 1].x - line[i].x, line[i + 1].z - line[i].z).length()
		if run + length >= s and length > 0.0:
			return line[i].lerp(line[i + 1], clampf((s - run) / length, 0.0, 1.0))
		run += length
	return line[line.size() - 1]


func _dir_at(line: Array[Vector3], s: float) -> Vector3:
	var run := 0.0
	for i in line.size() - 1:
		var d := line[i + 1] - line[i]
		d.y = 0.0
		if run + d.length() >= s or i == line.size() - 2:
			return d.normalized()
		run += d.length()
	return Vector3.FORWARD


func _vec(raw: Variant) -> Vector3:
	if not raw is Array or (raw as Array).size() < 3:
		return Vector3.INF
	var a: Array = raw
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func _read(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}
