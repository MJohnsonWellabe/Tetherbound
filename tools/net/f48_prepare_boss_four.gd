extends "res://tests/helpers/f48_net_proof.gd"

## Explicit input producer only. Retain the four distinct native admitted
## carriers, then run the original boss oracle; no substitute CI verdict.
func suite() -> String:
	return "prepare_boss_four"

func _build() -> Dictionary:
	var saves: Variant = _profile.get("saves", [])
	if not saves is Array or saves.size() != 4 or str(_profile.get("provenance", "")).is_empty():
		_profile_errors.append("Four distinct original sources and disclosed producer provenance required")
		return {}
	var steps: Array = []
	steps.append(_entry("all", "f48_watch_owner_saves"))
	_admit(steps, saves, 4)
	_capture_prepared_start(steps, "f48-boss-four-input")
	_boss(steps, 4)
	return {"name": "F48 genuine four-peer boss input producer",
		"claim": "Original four-peer boss oracle after exact input retention; no earned campaign credit. " + str(_profile.provenance),
		"peers": 4, "scene": "title", "budget_s": 3600, "build_allowance_s": 300, "steps": steps}
