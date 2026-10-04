extends "res://tests/helpers/f48_net_proof.gd"
## Actual post-boss host plus an original nonparticipant guest. Input production
## only; the inherited behind oracle, real portal writers and rejoin stay intact.

func suite() -> String:
	return "prepare_behind"

func _build() -> Dictionary:
	var saves: Variant = _profile.get("saves", [])
	if not saves is Array or saves.size() != 2 or str(_profile.get("provenance", "")).is_empty():
		_profile_errors.append("Require actual post-boss host and distinct original behind guest")
		return {}
	var steps: Array = []
	steps.append(_entry("all", "f48_watch_owner_saves"))
	_admit(steps, saves, 2)
	_capture_prepared_start(steps, "f48-behind-input")
	_behind(steps)
	return {"name": "F48 actual behind Tidewake input producer", "claim": "Actual original key unlock, behind arrival and rejoin; no earned campaign credit",
		"peers": 2, "scene": "title", "budget_s": 3600, "build_allowance_s": 300, "steps": steps}
