extends "res://tests/test_case.gd"

## WORLD §6.1 closed-gate flank repair (F12). A movement probe walked around the
## closed Tidal Cradle barrier and swam outside the departure strip. These
## checks use the production current construction and the baked heightfield
## formula to show that no swimmer or swim mount can land on any landform
## behind an uncleared mandatory dock, that Fly treats the same volume as
## sealed, and that opening the dock removes the race without touching the
## authored crossing.

const SEALS := preload("res://scripts/world/water_gate_seals.gd")
const CURRENTS := preload("res://scripts/world/water_current_field.gd")
const HEIGHT := preload("res://scripts/world/water_heightfield.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLY := preload("res://scripts/player/fly_controller.gd")

const CHAIN := [
	"water_swim_lesson_complete",
	"water_dock_reedhaven_repaired",
	"water_dock_brine_steps_trial_won",
	"water_dock_shellwatch_residents_freed_and_pump_disabled",
	"water_aquaryn_resolved",
	"water_dock_salt_crown_landing_charted",
	"water_dock_sluice_isle_both_controls_disabled",
]

class Flags:
	extends RefCounted
	var ids: Dictionary = {}
	func has(id: String) -> bool:
		return ids.has(id)

class FakeGame:
	extends Node
	var progression: RefCounted

var _config: Dictionary
var _traversal: Dictionary
var _rules: Dictionary
var _seals: Array[Dictionary]


func before_each() -> void:
	_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	_traversal = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
	_rules = SEALS.load_rules()
	_seals = SEALS.compile(_config)


func _flags_before(gate_index: int) -> Flags:
	var flags := Flags.new()
	for index in gate_index:
		flags.ids[CHAIN[index]] = true
	return flags


func _field(flags: Flags) -> RefCounted:
	return CURRENTS.new(CURRENTS.with_closed_gates(_config, _traversal), flags)


func test_every_landform_behind_a_mandatory_dock_is_sealed_in_dock_order() -> void:
	var by_id: Dictionary = {}
	for seal: Dictionary in _seals:
		by_id[str(seal.id)] = seal
	assert_eq(_config.rest_shoals.size(), 17)
	for shoal: Dictionary in _config.rest_shoals:
		assert_true(by_id.has(str(shoal.id)), "rest shoal sealed: " + str(shoal.id))
	# Open arrival and optional open landing stay unsealed.
	assert_false(by_id.has("first_shore"))
	assert_false(by_id.has("lantern_cove"))
	var expected := {
		"reedhaven": 1, "gull_rest": 1, "brine_steps": 2, "shellwatch": 3, "tidal_cradle": 4,
		"salt_crown": 5, "drowned_garden": 5, "sluice_isle": 6, "deep_watch": 6, "veilfall": 7,
		"tidal_cradle_to_salt_crown_rest_01": 5, "tidal_cradle_to_salt_crown_rest_04": 5,
		"sluice_isle_to_veilfall_rest_06": 7, "brine_steps_to_shellwatch_rest_01": 3,
	}
	for id: String in expected:
		var seal: Dictionary = by_id.get(id, {})
		assert_eq(seal.get("required_flags", []), CHAIN.slice(0, int(expected[id])), id)
		assert_eq(seal.get("dock_ids", []).size(), int(expected[id]), id + " dock chain")
	# The reproduced flank: Cradle's first shoal waits on the shared Aquaryn fact.
	var shoal: Dictionary = by_id["tidal_cradle_to_salt_crown_rest_01"]
	assert_eq(SEALS.first_closed_dock(shoal, _flags_before(4)), "tidal_cradle_to_salt_crown_dock")
	assert_eq(str(shoal.label), "the tide race on the Salt Crown crossing")


func test_seal_follows_the_landforms_own_dock_fact() -> void:
	var salt_crown: Dictionary = {}
	for seal: Dictionary in _seals:
		if str(seal.id) == "salt_crown":
			salt_crown = seal
	assert_true(SEALS.is_sealed(salt_crown, _flags_before(4)))
	assert_false(SEALS.is_sealed(salt_crown, _flags_before(5)))
	assert_false(SEALS.is_sealed(salt_crown, null), "analytical callers see open water")
	# A fixture or legacy world holding only the final fact already reached it.
	var legacy := Flags.new()
	legacy.ids[CHAIN[4]] = true
	assert_false(SEALS.is_sealed(salt_crown, legacy))
	# The explanation still names the earliest dock the world has not cleared.
	var earlier := _flags_before(2)
	assert_eq(SEALS.first_closed_dock(salt_crown, earlier), "brine_steps_to_shellwatch_dock")


func test_a_later_fact_keeps_every_earlier_landform_open() -> void:
	# Legacy/fixture world: only the Aquaryn fact, none of the earlier docks.
	var legacy := Flags.new()
	legacy.ids[CHAIN[4]] = true
	var open_ids: Array[String] = []
	var sealed_ids: Array[String] = []
	for seal: Dictionary in _seals:
		(sealed_ids if SEALS.is_sealed(seal, legacy) else open_ids).append(str(seal.id))
	for id: String in ["reedhaven", "gull_rest", "brine_steps", "shellwatch", "tidal_cradle", "salt_crown",
			"drowned_garden", "reedhaven_to_brine_steps_rest_01", "brine_steps_to_shellwatch_rest_01",
			"shellwatch_to_tidal_cradle_rest_01", "tidal_cradle_to_salt_crown_rest_04"]:
		assert_true(open_ids.has(id), id + " stays open behind a later fact")
	for id: String in ["sluice_isle", "deep_watch", "veilfall", "salt_crown_to_sluice_isle_rest_01", "sluice_isle_to_veilfall_rest_06"]:
		assert_true(sealed_ids.has(id), id + " stays sealed ahead of the later fact")


func test_every_island_is_reached_by_a_dock_or_is_the_arrival() -> void:
	var sealed: Dictionary = {}
	for seal: Dictionary in _seals:
		if str(seal.kind) == "island":
			sealed[str(seal.id)] = true
	var open := 0
	for island: Dictionary in _config.islands:
		if not sealed.has(str(island.id)):
			open += 1
			assert_true(str(island.id) in ["first_shore", "lantern_cove"], "unsealed island is open by design: " + str(island.id))
	assert_eq(sealed.size() + open, _config.islands.size())


func test_race_outpaces_every_swimmer_and_swim_mount() -> void:
	var fastest := float(_traversal.human.speed_m_s)
	var mounts := 0
	for species_id: String in SPECIES.table():
		var mount: Dictionary = SPECIES.definition(species_id).get("swim_mount", {})
		if bool(mount.get("compatible", false)):
			mounts += 1
			fastest = maxf(fastest, float(mount.get("speed_mps", 0.0)))
	assert_true(mounts >= 5, "all compatible swim mounts were read")
	assert_true(float(_rules.strength_m_s) >= fastest * 1.15,
		"race %.2f m/s must beat the fastest swimmer %.2f m/s with margin" % [float(_rules.strength_m_s), fastest])
	# The full-strength core must be wide enough to matter, not a hairline wall.
	assert_true(float(_rules.width_m) - float(_rules.edge_blend_m) >= 8.0)


func test_core_band_pushes_every_heading_outward_while_the_chain_is_closed() -> void:
	var strength := float(_rules.strength_m_s)
	for seal: Dictionary in _seals:
		var chain: Array = seal.required_flags
		# Everything before the last gate is open: the realistic closed state.
		var closed := Flags.new()
		for index in chain.size() - 1:
			closed.ids[chain[index]] = true
		var field := _field(closed)
		var centre: Vector2 = seal.centre
		var inner := float(seal.shore_radius_m)
		var outer := SEALS.outer_radius(seal, _rules)
		var core := outer - float(_rules.edge_blend_m)
		var weakest := INF
		var inward := 0
		for step in 360:
			var angle := TAU * float(step) / 360.0
			var direction := Vector2(cos(angle), sin(angle))
			for radius: float in [inner, inner + 3.0, (inner + core) * 0.5, core - 0.01, (core + outer) * 0.5, outer - 0.2]:
				var point := centre + direction * radius
				if _nearer_sealed_shore(seal, Vector3(point.x, 0, point.y), closed):
					# Overlap owned by a neighbouring race, pushing away from it.
					continue
				var sample: Dictionary = field.sample(Vector3(point.x, 0, point.y))
				var velocity: Vector3 = sample.velocity
				var radial := velocity.x * direction.x + velocity.z * direction.y
				if radial < -0.0001:
					inward += 1
				if radius <= core:
					weakest = minf(weakest, radial)
					assert_eq(str(sample.get("seal", "")), str(seal.id))
		assert_eq(inward, 0, str(seal.id) + " never pulls inward")
		assert_almost_eq(weakest, strength, 0.001, str(seal.id) + " full-strength core")


func _nearer_sealed_shore(seal: Dictionary, point: Vector3, flags: Flags) -> bool:
	var own := SEALS.shore_gap(seal, point)
	for other: Dictionary in _seals:
		if other != seal and SEALS.is_sealed(other, flags) \
				and SEALS.velocity_at(other, _rules, point, flags) != Vector3.ZERO \
				and SEALS.shore_gap(other, point) < own:
			return true
	return false


func test_swimmers_and_mounts_cannot_land_but_open_gate_swimmer_can() -> void:
	var height := HEIGHT.new(_config)
	var exit_depth := float(_traversal.human.exit_depth_m)
	var slope := float(_config.terrain.get("outer_shore_slope", 0.35))
	var wading := exit_depth / slope
	var dt := 0.05
	for seal: Dictionary in _seals:
		var chain: Array = seal.required_flags
		var closed := Flags.new()
		for index in chain.size() - 1:
			closed.ids[chain[index]] = true
		var open := Flags.new()
		for flag: String in chain:
			open.ids[flag] = true
		var closed_field := _field(closed)
		var open_field := _field(open)
		var centre: Vector2 = seal.centre
		var inner := float(seal.shore_radius_m)
		var start_radius := SEALS.outer_radius(seal, _rules) + 2.0
		for heading in 8:
			var angle := TAU * float(heading) / 8.0 + 0.1
			var start := centre + Vector2(cos(angle), sin(angle)) * start_radius
			for speed: float in [float(_traversal.human.speed_m_s), 10.0]:
				var closest := _closest_approach(closed_field, start, centre, speed, dt, 90.0)
				assert_true(closest > inner + wading,
					"%s closed: %.1f m/s swimmer reached %.2f m from centre (shore %.1f)" % [seal.id, speed, closest, inner])
			# Positive control: the ordinary human reaches wading depth when open,
			# unless this heading starts inside another landform's shallows.
			var start_depth := -height.height_at(start.x, start.y)
			if start_depth > 1.2:
				var reached := _closest_approach(open_field, start, centre, float(_traversal.human.speed_m_s), dt, 90.0)
				assert_true(reached <= inner + wading, "%s open: swimmer reaches shallows (%.2f)" % [seal.id, reached])


func test_overlapping_races_hold_their_seam() -> void:
	# Pairs whose race discs overlap push toward each other along the line of
	# centres; entering the seam must still never reach either shallows.
	var exit_depth := float(_traversal.human.exit_depth_m)
	var wading := exit_depth / float(_config.terrain.get("outer_shore_slope", 0.35))
	var pairs := 0
	for a: Dictionary in _seals:
		for b: Dictionary in _seals:
			if str(a.id) >= str(b.id):
				continue
			var ca: Vector2 = a.centre
			var cb: Vector2 = b.centre
			var reach := SEALS.outer_radius(a, _rules) + SEALS.outer_radius(b, _rules)
			if ca.distance_to(cb) >= reach:
				continue
			pairs += 1
			var chain: Array = a.required_flags if a.required_flags.size() >= b.required_flags.size() else b.required_flags
			var closed := Flags.new()
			for index in chain.size() - 1:
				closed.ids[chain[index]] = true
			if not (SEALS.is_sealed(a, closed) and SEALS.is_sealed(b, closed)):
				continue
			var field := _field(closed)
			var axis := (cb - ca).normalized()
			var normal := Vector2(-axis.y, axis.x)
			var gap_a := float(a.shore_radius_m)
			var mid := ca + axis * (gap_a + (ca.distance_to(cb) - gap_a - float(b.shore_radius_m)) * 0.5)
			for side: float in [-1.0, 1.0]:
				var start := mid + normal * side * (SEALS.outer_radius(a, _rules) + 4.0)
				for target: Dictionary in [a, b]:
					for speed: float in [float(_traversal.human.speed_m_s), 10.0]:
						var closest := _closest_approach(field, start, target.centre, speed, 0.05, 90.0)
						assert_true(closest > float(target.shore_radius_m) + wading,
							"%s|%s seam: %.1f m/s reached %.2f m from %s" % [a.id, b.id, speed, closest, target.id])
	assert_true(pairs >= 2, "the known Brine/Shellwatch shoal overlaps are exercised")


func _closest_approach(field: RefCounted, start: Vector2, target: Vector2, speed: float, dt: float, seconds: float) -> float:
	var position := start
	var closest := position.distance_to(target)
	var elapsed := 0.0
	while elapsed < seconds:
		var toward := (target - position).normalized()
		var flow: Vector3 = field.sample(Vector3(position.x, 0, position.y)).velocity
		position += (toward * speed + Vector2(flow.x, flow.z)) * dt
		closest = minf(closest, position.distance_to(target))
		elapsed += dt
	return closest


func _landforms() -> Array[Dictionary]:
	var landforms: Array[Dictionary] = []
	var sealed: Dictionary = {}
	for seal: Dictionary in _seals:
		sealed[str(seal.id)] = seal.required_flags
	for island: Dictionary in _config.islands:
		landforms.append({"id": str(island.id), "centre": Vector2(float(island.center_xz_m[0]), float(island.center_xz_m[1])),
			"radius": float(island.shore_radius_m), "flags": sealed.get(str(island.id), [])})
	for shoal: Dictionary in _config.rest_shoals:
		landforms.append({"id": str(shoal.id), "centre": Vector2(float(shoal.center_xz_m[0]), float(shoal.center_xz_m[1])),
			"radius": float(shoal.shore_radius_m), "flags": sealed.get(str(shoal.id), [])})
	return landforms


func _at_least_as_gated(flags: Array, than: Array) -> bool:
	for flag: String in than:
		if not flags.has(flag):
			return false
	return true


func test_races_leave_every_less_gated_shore_and_anchor_swimmable() -> void:
	var landforms := _landforms()
	var margin := 4.0
	for seal: Dictionary in _seals:
		var outer := SEALS.outer_radius(seal, _rules)
		for land: Dictionary in landforms:
			if _at_least_as_gated(land.flags, seal.required_flags):
				continue
			var gap: float = (land.centre as Vector2).distance_to(seal.centre) - float(land.radius) - outer
			assert_true(gap >= margin, "%s race leaves %.1f m off %s" % [seal.id, gap, land.id])
	var island_flags: Dictionary = {}
	for land: Dictionary in landforms:
		island_flags[str(land.id)] = land.flags
	for anchor: Dictionary in _config.anchors:
		var flags: Array = island_flags.get(str(anchor.get("id", "")), island_flags.get(str(anchor.island_id), []))
		for seal: Dictionary in _seals:
			if _at_least_as_gated(flags, seal.required_flags):
				continue
			var outer := SEALS.outer_radius(seal, _rules)
			var volumes := SEALS.flight_volumes(seal, _rules)
			for key: String in ["safe_position", "shore_position", "swim_marker"]:
				if not anchor.has(key):
					continue
				var point := Vector3(float(anchor[key][0]), float(anchor[key][1]), float(anchor[key][2]))
				assert_true(Vector2(point.x, point.z).distance_to(seal.centre) > outer + margin,
					"%s.%s outside %s race" % [anchor.id, key, seal.id])
				for bounds: AABB in volumes:
					assert_false(bounds.has_point(point), "%s.%s outside %s flight seal" % [anchor.id, key, seal.id])


func test_flight_volumes_cover_only_equally_sealed_land() -> void:
	var height := HEIGHT.new(_config)
	var landforms := _landforms()
	var sea := float(_config.terrain.sea_level_m)
	for seal: Dictionary in _seals:
		var foreign := 0
		var covered := 0
		for bounds: AABB in SEALS.flight_volumes(seal, _rules):
			assert_true(bounds.position.y <= -80.0 and bounds.end.y >= 700.0, "vertical cover above Veilfall")
			var step := 2.0
			var x := bounds.position.x
			while x <= bounds.end.x:
				var z := bounds.position.z
				while z <= bounds.end.z:
					if height.height_at(x, z) > sea:
						covered += 1
						var owned := false
						for land: Dictionary in landforms:
							if Vector2(x, z).distance_to(land.centre) <= float(land.radius) + 0.5 \
									and _at_least_as_gated(land.flags, seal.required_flags):
								owned = true
								break
						if not owned:
							foreign += 1
					z += step
				x += step
		assert_true(covered > 0, str(seal.id) + " flight seal covers its own land")
		assert_eq(foreign, 0, str(seal.id) + " flight seal covers no earlier land")
		# Every point of the race disc is inside some volume.
		var outer := SEALS.outer_radius(seal, _rules)
		var centre: Vector2 = seal.centre
		for step in 72:
			var angle := TAU * float(step) / 72.0
			for radius: float in [0.0, outer * 0.5, outer - 0.01]:
				var point := Vector3(centre.x + cos(angle) * radius, 20.0, centre.y + sin(angle) * radius)
				var inside := false
				for bounds: AABB in SEALS.flight_volumes(seal, _rules):
					inside = inside or bounds.has_point(point)
				assert_true(inside, "%s disc covered at %.0f deg r%.1f" % [seal.id, rad_to_deg(angle), radius])


func test_fly_refuses_a_sealed_volume_until_its_dock_opens() -> void:
	var flags := Flags.new()
	var game := FakeGame.new()
	game.progression = flags
	var fly: Node = FLY.new()
	fly.set("_game", game)
	var docks := {"tidal_cradle_to_salt_crown_dock": "Tidal Cradle"}
	for index in 4:
		flags.ids[CHAIN[index]] = true
	var registered := SEALS.sync_flight(fly, _seals, _rules, flags, docks)
	var expected := 0
	for seal: Dictionary in _seals:
		if SEALS.is_sealed(seal, flags):
			expected += SEALS.flight_volumes(seal, _rules).size()
	assert_eq(registered, expected)
	assert_eq((fly.get("restrictions") as Array).size(), expected, "re-sync replaces, never accumulates")
	assert_eq(SEALS.sync_flight(fly, _seals, _rules, flags, docks), expected)
	assert_eq((fly.get("restrictions") as Array).size(), expected)
	var target: Dictionary = {}
	for seal: Dictionary in _seals:
		if str(seal.id) == "salt_crown":
			target = seal
	var centre: Vector2 = target.centre
	var outside := Vector3(centre.x + 600.0, 60.0, centre.y)
	var inside := Vector3(centre.x, 60.0, centre.y)
	var reason: String = fly.call("_restricted_reason", outside, inside)
	assert_true(reason.contains("the tide race around Salt Crown; clear the Tidal Cradle dock first"), reason)
	flags.ids[CHAIN[4]] = true
	# Even before the re-sync, the restriction's own flag now reads present.
	assert_eq(str(fly.call("_restricted_reason", outside, inside)), "")
	SEALS.sync_flight(fly, _seals, _rules, flags, docks)
	for entry: Dictionary in fly.get("restrictions"):
		assert_false(str(entry.id).begins_with("the tide race around Salt Crown"), "opened seal unregistered")
	fly.free()
	game.free()


func test_open_chain_restores_the_authored_crossing_current_exactly() -> void:
	var open := Flags.new()
	for flag: String in CHAIN:
		open.ids[flag] = true
	var production := _field(open)
	var authored := CURRENTS.new(_config, open)
	# Samples along every sheltered polyline, including inside former races.
	for current: Dictionary in _config.currents:
		var points: Array = current.polyline
		for index in range(1, points.size()):
			for t: float in [0.0, 0.5]:
				var a := Vector3(float(points[index - 1][0]), 0, float(points[index - 1][2]))
				var b := Vector3(float(points[index][0]), 0, float(points[index][2]))
				var point := a.lerp(b, t)
				assert_eq(production.sample(point).velocity, authored.sample(point).velocity, str(current.id))
