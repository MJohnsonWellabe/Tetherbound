extends RefCounted

## One bounded presentation pool per host encounter. Mesh cores and mesh
## impacts remain visible even when decorative particle slots are exhausted.
static var _next_token: int = 0
static var _leases: Dictionary = {}

static func reserve(encounter_id: String, impact: int, trail: int, cap: int) -> int:
	_next_token += 1
	cap = maxi(0, cap)
	impact = clampi(impact, 0, cap)
	trail = clampi(trail, 0, cap)
	# Make room for contact first. Evict existing trail slots before admitting
	# fewer impact motes. Callers observe leases each frame and prune ribbons.
	for token: Variant in _leases:
		var lease: Dictionary = _leases[token]
		if str(lease.encounter_id) != encounter_id: continue
		if used(encounter_id) + impact <= cap: break
		lease.trail = maxi(0, int(lease.trail) - mini(int(lease.trail), used(encounter_id) + impact - cap))
	var available := maxi(0, cap - used(encounter_id))
	var granted_impact := mini(impact, available)
	var granted_trail := mini(trail, available - granted_impact)
	_leases[_next_token] = {"encounter_id": encounter_id, "impact": granted_impact, "trail": granted_trail}
	return _next_token

static func used(encounter_id: String) -> int:
	var total := 0
	for lease: Dictionary in _leases.values():
		if str(lease.encounter_id) == encounter_id: total += int(lease.impact) + int(lease.trail)
	return total

static func allocation(token: int) -> Dictionary:
	return (_leases.get(token, {"impact": 0, "trail": 0}) as Dictionary).duplicate()

## Lights use the same lifetime token but never spend particle slots. The cap
## is global across encounter IDs because one viewport can see several fights.
static func reserve_light(token: int, cap: int) -> bool:
	if not _leases.has(token) or cap <= 0: return false
	if bool(_leases[token].get("light", false)): return true
	if lights_used() >= cap: return false
	_leases[token]["light"] = true
	return true

static func lights_used() -> int:
	var total := 0
	for lease: Dictionary in _leases.values():
		if bool(lease.get("light", false)): total += 1
	return total

static func release(token: int) -> void:
	_leases.erase(token)
