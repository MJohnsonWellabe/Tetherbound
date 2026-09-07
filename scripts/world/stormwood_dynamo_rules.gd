extends RefCounted

## Authoritative encounter state, advanced by the host controller. This policy
## does not start a trainer fight or award progression by itself.
const PATH := "res://data/config/stormwood_dynamo.json"
const PHASES := ["bank_cycle", "overload", "break_core", "released"]
var config: Dictionary
var phase := "bank_cycle"
var elapsed := 0.0
var conduits: Array[int] = []
var attempt := 0
var _last_cycle := 0

func _init() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string(PATH))

func reset() -> void:
	phase = "bank_cycle"
	elapsed = 0.0
	conduits.clear()
	_last_cycle = 0
	attempt += 1

func update_team(remaining: int, total: int) -> void:
	if phase in ["break_core", "released"] or total <= 0:
		return
	if remaining <= 0:
		_set_phase("break_core")
	elif remaining * 2 <= total and phase == "bank_cycle":
		_set_phase("overload")

func _set_phase(next: String) -> void:
	phase = next
	elapsed = 0.0
	_last_cycle = 0
	conduits.clear()

func advance(seconds: float) -> Dictionary:
	if phase == "released" or not is_finite(seconds) or seconds <= 0.0:
		return bank_state()
	elapsed += seconds
	var current := bank_state()
	if phase == "break_core" and int(current.cycle) > _last_cycle:
		# Missing the four-conduit window restarts that challenge; it never
		# silently awards victory or respawns a defeated trainer team.
		conduits.clear()
	_last_cycle = int(current.cycle)
	return current

func bank_state() -> Dictionary:
	if phase == "released":
		return {"bank": -1, "state": "quiet", "charge": 0.0, "cycle": _last_cycle, "serial": -1}
	var timing: Dictionary = config.phases[phase]
	var charge := float(timing.charge_seconds)
	var fire := float(timing.fire_seconds)
	var period := charge + fire + float(timing.recovery_seconds)
	var serial := floori((elapsed + 0.0000001) / period)
	var within := maxf(0.0, elapsed - float(serial) * period)
	return {"bank": serial % int(config.bank_count),
		"state": "charge" if within < charge else ("fire" if within < charge + fire else "recovery"),
		"charge": clampf(within / charge, 0.0, 1.0),
		"cycle": floori(float(serial) / float(config.bank_count)), "serial": serial}

func bank_position(index: int) -> Vector2:
	return Vector2.RIGHT.rotated(TAU * float(index) / float(config.bank_count)) * float(config.bank_radius_m)

func on_plate(local: Vector2) -> bool:
	for point: Array in config.plates:
		if local.distance_to(Vector2(float(point[0]), float(point[1]))) <= float(config.plate_radius_m):
			return true
	return false

func in_discharge_lane(local: Vector2, bank: int) -> bool:
	if bank < 0 or bank >= int(config.bank_count) or local.length() > float(config.arena_radius_m) or on_plate(local):
		return false
	var direction := bank_position(bank).normalized()
	return absf(local.cross(direction)) <= float(config.lane_half_width_m)

func strike_conduit(index: int, creature_local: Vector2, piloted: bool) -> bool:
	if phase != "break_core" or not piloted or index < 0 or index >= int(config.bank_count) or conduits.has(index):
		return false
	if not creature_local.is_finite() or creature_local.distance_to(bank_position(index)) > float(config.conduit_reach_m) + 0.00001:
		return false
	conduits.append(index)
	if conduits.size() == int(config.bank_count):
		phase = "released"
	return true

func save_data() -> Dictionary:
	return {"phase": phase, "elapsed": elapsed, "conduits": conduits.duplicate(), "attempt": attempt, "cycle": _last_cycle}

func load_data(data: Dictionary) -> void:
	phase = str(data.get("phase", "bank_cycle"))
	if not PHASES.has(phase):
		phase = "bank_cycle"
	var raw: Variant = data.get("elapsed", 0.0)
	elapsed = maxf(0.0, float(raw)) if (raw is int or raw is float) and is_finite(float(raw)) else 0.0
	conduits.clear()
	var saved: Variant = data.get("conduits", [])
	if saved is Array:
		for id: Variant in saved:
			if (id is int or id is float) and int(id) >= 0 and int(id) < int(config.bank_count) and not conduits.has(int(id)):
				conduits.append(int(id))
	attempt = maxi(0, int(data.get("attempt", 0)))
	_last_cycle = int(bank_state().cycle) if phase != "released" else maxi(0, int(data.get("cycle", 0)))
