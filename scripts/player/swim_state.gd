extends RefCounted

## Shared traversal state for an owned trainer or mount. Only the owning peer
## advances resources; remote peers apply validated snapshots for presentation.
## Resource values remain on PlayerVitals / CreatureInstance, never this proxy.
enum Mode { LAND, HUMAN, MOUNTED, COMBAT_PAUSED }

var mode: int = Mode.LAND
var drowning: bool = false
var surface_y: float = 0.0
var stamina_fraction: float = 1.0
var owner_peer_id: int = 1
var revision: int = 0
var safe_landing: Vector3 = Vector3.ZERO
var has_safe_landing: bool = false
var _resume_mode: int = Mode.LAND
var _received_revision: int = -1


func enter_water(mounted: bool, water_y: float) -> void:
	if not is_finite(water_y):
		return
	surface_y = water_y
	var target := Mode.MOUNTED if mounted else Mode.HUMAN
	if mode == Mode.COMBAT_PAUSED:
		_resume_mode = target
	else:
		mode = target
	revision += 1


func reach_land(position: Vector3) -> void:
	if not position.is_finite():
		return
	mode = Mode.LAND
	_resume_mode = Mode.LAND
	drowning = false
	safe_landing = position
	has_safe_landing = true
	revision += 1


func pause_for_combat() -> void:
	if mode == Mode.COMBAT_PAUSED or mode == Mode.LAND:
		return
	_resume_mode = mode
	mode = Mode.COMBAT_PAUSED
	drowning = false
	revision += 1


## Caller checks whether the former mount still exists, is alive and fitted.
## Losing a mount during combat never grants its stamina to the human.
func resume_after_combat(mount_available: bool) -> void:
	if mode != Mode.COMBAT_PAUSED:
		return
	mode = _resume_mode
	if mode == Mode.MOUNTED and not mount_available:
		mode = Mode.HUMAN
	drowning = false
	revision += 1


## Returns resource deltas, not new resources: the caller applies these once
## to the actual human or mounted creature. No idle recovery in deep water.
## Only the portion of a frame AFTER exhaustion causes health loss.
func advance(peer_id: int, delta: float, stamina: float, capacity: float,
		drain_per_s: float, damage_per_s: float, efficiency: float = 1.0) -> Dictionary:
	var result := {"stamina_spent": 0.0, "health_lost": 0.0}
	if peer_id != owner_peer_id:
		return result
	for value in [delta, stamina, capacity, drain_per_s, damage_per_s, efficiency]:
		if not is_finite(float(value)):
			return result
	if delta <= 0.0 or capacity <= 0.0:
		return result
	stamina_fraction = clampf(stamina / capacity, 0.0, 1.0)
	if mode == Mode.LAND or mode == Mode.COMBAT_PAUSED:
		drowning = false
		return result
	var available := clampf(stamina, 0.0, capacity)
	var rate := maxf(0.0, drain_per_s) * clampf(efficiency, 0.0, 1.0)
	var spent := minf(available, rate * delta)
	var exhausted_seconds := delta if available <= 0.0 else 0.0
	if rate > 0.0 and available > 0.0:
		exhausted_seconds = maxf(0.0, delta - available / rate)
	stamina_fraction = clampf((available - spent) / capacity, 0.0, 1.0)
	drowning = stamina_fraction <= 0.0
	result.stamina_spent = spent
	result.health_lost = exhausted_seconds * maxf(0.0, damage_per_s)
	revision += 1
	return result


func snapshot() -> Dictionary:
	return {"version": 1, "owner_peer_id": owner_peer_id, "revision": revision,
		"mode": mode, "resume_mode": _resume_mode, "surface_y": surface_y,
		"stamina_fraction": stamina_fraction, "drowning": drowning,
		"has_safe_landing": has_safe_landing,
		"safe_landing": [safe_landing.x, safe_landing.y, safe_landing.z]}


## Transport supplies the actual RPC sender, never a sender claimed in data.
## Reconnect creates a fresh proxy; packet revisions are local to that session.
func apply_remote_snapshot(data: Dictionary, sender_peer_id: int) -> bool:
	for key in ["owner_peer_id", "version", "revision", "mode", "resume_mode"]:
		var raw: Variant = data.get(key)
		if not (raw is int or raw is float) or not is_finite(float(raw)):
			return false
		if float(raw) != floorf(float(raw)) or absf(float(raw)) > 2147483647.0:
			return false
	for key in ["surface_y", "stamina_fraction"]:
		var raw: Variant = data.get(key)
		if not (raw is int or raw is float) or not is_finite(float(raw)):
			return false
	for key in ["drowning", "has_safe_landing"]:
		if not data.get(key) is bool:
			return false
	if sender_peer_id != owner_peer_id or int(data.get("owner_peer_id", -1)) != owner_peer_id:
		return false
	if int(data.get("version", 0)) != 1:
		return false
	var incoming_revision := int(data.get("revision", -1))
	var incoming_mode := int(data.get("mode", -1))
	var incoming_resume := int(data.get("resume_mode", -1))
	if incoming_revision <= _received_revision or incoming_mode < Mode.LAND or incoming_mode > Mode.COMBAT_PAUSED:
		return false
	if incoming_resume < Mode.LAND or incoming_resume > Mode.MOUNTED:
		return false
	var incoming_surface := float(data.get("surface_y", NAN))
	var incoming_stamina := float(data.get("stamina_fraction", NAN))
	var landing: Variant = data.get("safe_landing", [])
	if not is_finite(incoming_surface) or not is_finite(incoming_stamina) or incoming_stamina < 0.0 or incoming_stamina > 1.0:
		return false
	if not landing is Array or landing.size() != 3:
		return false
	for component in landing:
		if not (component is float or component is int) or not is_finite(float(component)):
			return false
	var incoming_drowning := bool(data.get("drowning", false))
	if incoming_drowning and (incoming_mode == Mode.LAND or incoming_mode == Mode.COMBAT_PAUSED or incoming_stamina > 0.0):
		return false
	mode = incoming_mode
	_resume_mode = incoming_resume
	surface_y = incoming_surface
	stamina_fraction = incoming_stamina
	drowning = incoming_drowning
	has_safe_landing = bool(data.get("has_safe_landing", false))
	safe_landing = Vector3(float(landing[0]), float(landing[1]), float(landing[2]))
	_received_revision = incoming_revision
	revision = incoming_revision
	return true
