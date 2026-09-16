extends RefCounted

## Opt-in network-smoke observer. No waits, state writes, or arbitration.
## The production handler's two synchronous signals bound the observation;
## unrelated enemy turns before/after it cannot contaminate these snapshots.
var expected: Dictionary = {}
var receipt: Dictionary = {}
var _read: Callable
var _started := false


func arm(identity: Dictionary, read_state: Callable) -> void:
	expected = identity.duplicate(true)
	_read = read_state
	receipt = {}
	_started = false


func started(intent: Dictionary, peer_id: int) -> void:
	if not _matches(intent, peer_id) or not receipt.is_empty():
		return
	_started = true
	receipt = expected.duplicate(true)
	receipt["before"] = (_read.call() as Dictionary).duplicate(true)


func finished(intent: Dictionary, peer_id: int, verdict: Dictionary) -> void:
	if not _started or not _matches(intent, peer_id) or receipt.has("after"):
		return
	receipt["after"] = (_read.call() as Dictionary).duplicate(true)
	receipt["verdict"] = verdict.duplicate(true)
	receipt["complete"] = true


func _matches(intent: Dictionary, peer_id: int) -> bool:
	return str(intent.get("kind", "")) == "strike_intent" \
		and str(intent.get("encounter_id", "")) == str(expected.get("encounter_id", "")) \
		and int(intent.get("action", -1)) == int(expected.get("action", -2)) \
		and peer_id == int(expected.get("peer_id", -1))


static func assess(row: Dictionary, identity: Dictionary, not_before_ms: int) -> Dictionary:
	var bad := {"ok": false, "why": "missing or mismatched strike transaction"}
	if not bool(row.get("complete", false)):
		return bad
	for key in ["encounter_id", "peer_id", "action", "victim_peer_id"]:
		if not row.has(key) or row[key] != identity.get(key):
			return bad
	var before: Dictionary = row.get("before", {})
	var after: Dictionary = row.get("after", {})
	for snapshot: Dictionary in [before, after]:
		if str(snapshot.get("encounter_id", "")) != str(identity.encounter_id) \
				or int(snapshot.get("victim_peer_id", -1)) != int(identity.victim_peer_id):
			return bad
		for key in ["victim_hp", "opponent_hp"]:
			if not snapshot.has(key) or not is_finite(float(snapshot[key])) or float(snapshot[key]) <= 0.0:
				return {"ok": false, "why": "transaction lacks live finite HP"}
		if int(snapshot.get("struck_count", -1)) < 0:
			return bad
	if int(before.get("host_now_ms", -1)) < not_before_ms \
			or int(after.get("host_now_ms", -1)) < int(before.host_now_ms):
		return {"ok": false, "why": "stale transaction"}
	var verdict: Dictionary = row.get("verdict", {})
	if bool(verdict.get("ok", true)) or str(verdict.get("code", "")) != "friendly_target" \
			or str(verdict.get("kind", "")) != "strike_intent" \
			or int(verdict.get("peer", -1)) != int(identity.peer_id):
		return {"ok": false, "why": "transaction did not refuse the correlated friendly strike"}
	for key in ["victim_hp", "opponent_hp"]:
		if absf(float(after[key]) - float(before[key])) >= 0.001:
			return {"ok": false, "why": "%s changed inside authoritative strike transaction" % key}
	if int(after.struck_count) != int(before.struck_count):
		return {"ok": false, "why": "opponent blow occurred inside strike transaction"}
	return {"ok": true, "why": "correlated refused strike changed neither HP nor opponent-hit count"}
