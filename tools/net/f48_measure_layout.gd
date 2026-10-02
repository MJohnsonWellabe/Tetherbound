extends "res://tests/helpers/f48_net_proof.gd"

## Explicit solo observation before build/join, never a required smoke replacement.
func suite() -> String:
	return "measure_layout"

func _build() -> Dictionary:
	var saves: Variant = _profile.get("saves", [])
	if not saves is Array or saves.is_empty() or not saves[0] is String:
		_profile_errors.append("Native ground observation requires the disclosed original host input")
		return {}
	var steps: Array = [_entry(0, "load_save", {"from": saves[0]}, "Load disclosed initial mechanics input without starting host/join/build")]
	steps.append(_entry(0, "f48_measure_layout", {"points": {"actor_start": [-16, 14], "forge": [-16, 10],
		"kitchen": [-16, 25], "altar_planned": [-10, 8], "home_arch": [94.2, 14],
		"tidewake_arch": [98, 19.9], "meadows_pedestal": [102.5, 4.8], "master_t1": [440, 1780]}}))
	return {"name": "F48 actual initial terrain measurement", "claim": "Read-only native terrain points, no physical or transaction acceptance credit",
		"peers": 1, "scene": "title", "budget_s": 600, "build_allowance_s": 300, "steps": steps}
