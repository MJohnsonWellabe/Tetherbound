extends RefCounted

## Host-only revive authorization. This holds no scene nodes, health, death, or
## transport state: its caller supplies the host's current peer/body views and
## turns the returned events into RPC/UI work.

var duration_s := 3.0
var radius_m := 2.5
var deadzone_m := 0.3

var _windows: Dictionary = {} # target -> { window, realm, remaining }
var _window_highwater: Dictionary = {} # target -> greatest seen downed window
var _attempts: Dictionary = {} # target -> one active revive record
var _attempt_highwater: Dictionary = {} # reviver -> latest cancelled/completed attempt
var _pending_events: Array[Dictionary] = []


func note_down(target: int, window: int, realm: String, window_s: float) -> bool:
	if target <= 0 or window <= 0 or realm.is_empty() or not is_finite(window_s) or window_s <= 0.0:
		return false
	if window <= int(_window_highwater.get(target, 0)):
		return false
	if _attempts.has(target):
		_cancel_target(target, "window_replaced")
	_windows[target] = {"window": window, "realm": realm, "remaining": window_s}
	_window_highwater[target] = window
	return true


func forget(peer: int) -> void:
	if peer <= 0:
		return
	_windows.erase(peer)
	if _attempts.has(peer):
		_cancel_target(peer, "peer_forgotten")
	for target: Variant in _attempts.keys().duplicate():
		var record: Dictionary = _attempts[target]
		if int(record.get("reviver", 0)) == peer:
			_cancel_target(int(target), "peer_forgotten")


func reset() -> void:
	_windows.clear()
	_window_highwater.clear()
	_attempts.clear()
	_attempt_highwater.clear()
	_pending_events.clear()


func has_window(peer: int) -> bool:
	return _windows.has(peer)


func record_for(reviver: int) -> Dictionary:
	for record: Dictionary in _attempts.values():
		if int(record.get("reviver", 0)) == reviver:
			return record.duplicate(true)
	return {}


func start(reviver: int, target: int, window: int, attempt: int, views: Dictionary) -> Dictionary:
	var base := {"reviver": reviver, "target": target, "window": window, "attempt": attempt, "elapsed": 0.0}
	if reviver <= 0 or target <= 0 or reviver == target or window <= 0 or attempt <= 0:
		return _start_result(base, "rejected", "invalid_request")
	var active: Dictionary = _attempts.get(target, {})
	if not active.is_empty():
		if int(active.reviver) == reviver and int(active.window) == window and int(active.attempt) == attempt:
			base.elapsed = float(active.elapsed)
			return _start_result(base, "duplicate", "")
	if attempt <= int(_attempt_highwater.get(reviver, 0)):
		return _start_result(base, "rejected", "stale_attempt")
	if not record_for(reviver).is_empty():
		return _start_result(base, "rejected", "reviver_busy")
	if not active.is_empty():
		return _start_result(base, "rejected", "busy")
	var downed: Dictionary = _windows.get(target, {})
	if downed.is_empty() or int(downed.window) != window:
		return _start_result(base, "rejected", "invalid_window")
	if _windows.has(reviver):
		return _start_result(base, "rejected", "reviver_downed")
	var checked := _checked_views(reviver, target, str(downed.realm), views)
	if not bool(checked.ok):
		return _start_result(base, "rejected", str(checked.reason))
	var reviver_view: Dictionary = checked.reviver
	var target_view: Dictionary = checked.target
	_attempts[target] = {
		"reviver": reviver, "target": target, "window": window, "attempt": attempt,
		"realm": str(downed.realm), "origin": reviver_view.position,
		"reviver_body_id": int(reviver_view.body_id), "target_body_id": int(target_view.body_id),
		"elapsed": 0.0,
	}
	_attempt_highwater[reviver] = attempt
	return _start_result(base, "started", "")


func cancel(reviver: int, attempt: int) -> void:
	if reviver <= 0 or attempt <= 0:
		return
	_attempt_highwater[reviver] = max(int(_attempt_highwater.get(reviver, 0)), attempt)
	for target: Variant in _attempts.keys().duplicate():
		var record: Dictionary = _attempts[target]
		if int(record.reviver) == reviver and int(record.attempt) == attempt:
			_attempts.erase(target)
			return


func tick(delta: float, views: Dictionary) -> Array[Dictionary]:
	var events := _pending_events.duplicate(true)
	_pending_events.clear()
	if not is_finite(delta) or delta < 0.0:
		return events
	for target: Variant in _windows.keys().duplicate():
		var downed: Dictionary = _windows[target]
		downed.remaining = float(downed.remaining) - delta
		if float(downed.remaining) > 0.0:
			_windows[target] = downed
			continue
		_windows.erase(target)
		if _attempts.has(target):
			_cancel_target(int(target), "window_expired", events)
		else:
			events.append(_event("cancelled", 0, int(target), int(downed.window), 0, 0.0, "window_expired"))
	for target: Variant in _attempts.keys().duplicate():
		if not _attempts.has(target):
			continue
		var record: Dictionary = _attempts[target]
		var downed: Dictionary = _windows.get(target, {})
		if downed.is_empty() or int(downed.window) != int(record.window):
			_cancel_target(int(target), "invalid_window", events)
			continue
		if _windows.has(int(record.reviver)):
			_cancel_target(int(target), "reviver_downed", events)
			continue
		var checked := _checked_views(int(record.reviver), int(record.target), str(record.realm), views,
			int(record.reviver_body_id), int(record.target_body_id))
		if not bool(checked.ok):
			_cancel_target(int(target), str(checked.reason), events)
			continue
		var reviver_view: Dictionary = checked.reviver
		if _xz_distance(record.origin, reviver_view.position) > deadzone_m:
			_cancel_target(int(target), "moved", events)
			continue
		record.elapsed = float(record.elapsed) + delta
		_attempts[target] = record
		if float(record.elapsed) < duration_s:
			events.append(_event("progress", int(record.reviver), int(target), int(record.window),
				int(record.attempt), float(record.elapsed), ""))
			continue
		# Remove the authorization first. A duplicate packet or competing reviver
		# can therefore never observe a live target after completion.
		_attempts.erase(target)
		_windows.erase(target)
		_attempt_highwater[int(record.reviver)] = max(int(_attempt_highwater.get(record.reviver, 0)), int(record.attempt))
		events.append(_event("completed", int(record.reviver), int(target), int(record.window),
			int(record.attempt), duration_s, ""))
	return events


func _cancel_target(target: int, reason: String, events: Array[Dictionary] = _pending_events) -> void:
	var record: Dictionary = _attempts.get(target, {})
	if record.is_empty():
		return
	_attempts.erase(target)
	_attempt_highwater[int(record.reviver)] = max(int(_attempt_highwater.get(record.reviver, 0)), int(record.attempt))
	events.append(_event("cancelled", int(record.reviver), target, int(record.window),
		int(record.attempt), float(record.elapsed), reason))


func _checked_views(reviver: int, target: int, realm: String, views: Dictionary,
		reviver_body_id: int = 0, target_body_id: int = 0) -> Dictionary:
	var reviver_view := _view(views, reviver)
	var target_view := _view(views, target)
	if reviver_view.is_empty() or target_view.is_empty():
		return {"ok": false, "reason": "invalid_peer"}
	if str(reviver_view.realm) != realm or str(target_view.realm) != realm:
		return {"ok": false, "reason": "realm_changed"}
	if reviver_body_id > 0 and (int(reviver_view.body_id) != reviver_body_id or int(target_view.body_id) != target_body_id):
		return {"ok": false, "reason": "body_replaced"}
	if reviver_view.position.distance_to(target_view.position) > radius_m:
		return {"ok": false, "reason": "out_of_range"}
	return {"ok": true, "reviver": reviver_view, "target": target_view}


func _view(views: Dictionary, peer: int) -> Dictionary:
	var raw: Variant = views.get(peer, {})
	if raw is not Dictionary:
		return {}
	var view := raw as Dictionary
	var position: Variant = view.get("position", Vector3.INF)
	if not bool(view.get("valid", false)) or view.get("realm", "") == "" or int(view.get("body_id", 0)) <= 0 \
			or position is not Vector3 or not (position as Vector3).is_finite():
		return {}
	return view


func _start_result(base: Dictionary, kind: String, reason: String) -> Dictionary:
	var result := base.duplicate(true)
	result.kind = kind
	result.reason = reason
	return result


func _event(kind: String, reviver: int, target: int, window: int, attempt: int,
		elapsed: float, reason: String) -> Dictionary:
	return {"kind": kind, "reviver": reviver, "target": target, "window": window,
		"attempt": attempt, "elapsed": elapsed, "reason": reason}


func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
