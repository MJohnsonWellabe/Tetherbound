extends RefCounted
## Samples the real tournament entry predicate once per explicitly authored round.
## A round already started always finishes its victory and recovery checks.
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
var _rounds: Dictionary = {}

func decide(meta: Dictionary, party: RefCounted) -> Dictionary:
	var key := str(meta.get("id", ""))
	if key.is_empty() or party == null:
		return {"ok": false, "omit": false, "actual": "FAIL training round lacks identity or live party"}
	if bool(meta.get("start", false)):
		if _rounds.has(key):
			return {"ok": false, "omit": false, "actual": "FAIL training round sampled twice"}
		_rounds[key] = TOURNAMENT.training_ready(party)
	if not _rounds.has(key):
		return {"ok": false, "omit": false, "actual": "FAIL training round continuation without start"}
	var omit := bool(_rounds[key])
	return {"ok": true, "omit": omit, "actual":
		"VERIFIED-CONDITION training round %s not needed: live tournament training_ready was true before round; no fight claimed" % key if omit else "training round started below live entry threshold"}
