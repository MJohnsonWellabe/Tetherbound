extends "res://tests/helpers/f48_net_proof.gd"

## Explicit prerequisite producer tool, never a substitute for F48's 24 cuts.
## ROOT alone runs this under its native lease with a pinned disclosed test
## configuration overlay. It uses the production saved-input loader, ordinary
## guest title picker and paid build inputs (host Session transport setup is
## the existing disclosed harness shortcut),
## asserts the actual accepted journal/save and captures the resulting files.
func suite() -> String:
	return "bootstrap_altar"

func _build() -> Dictionary:
	var saves: Variant = _profile.get("saves")
	if not saves is Array or saves.size() != 2:
		_profile_errors.append("Paid Altar bootstrap requires two original distinct v28 saved inputs")
		return {}
	if str(_profile.get("provenance", "")).is_empty(): _profile_errors.append("Disclose original inputs and mechanics setup")
	var steps: Array = [_entry("all", "f48_require_configuration", {"files": _profile.get("test_configuration"), "scope": _profile.get("configuration_scope", "bootstrap")})]
	_admit(steps, saves, 2)
	steps.append(_entry(0, "f48_require", {"flags": [
		{"file": "res://data/config/stations.json", "path": "runtime_enabled"},
		{"file": "res://data/config/essence.json", "path": "altar_building_runtime_enabled"},
		{"file": "res://data/config/essence.json", "path": "altar_runtime_enabled"}],
		"nodes": [{"path": "Game/Session", "methods": ["host_altar_building", "apply_altar_building_owner"]}]}))
	steps.append_array(_route("bootstrap_altar", 0))
	steps.append(_entry(0, "f48_assert_altar_build", {"since": "admitted"}))
	steps.append(_entry(1, "f48_assert", {"since": "admitted", "unchanged": ["inventory", "party", "redesign_character", "satchel_escrow"]}))
	steps.append(_entry("all", "capture_saves", {"label": "actual-paid-altar"}))
	return {"name": "F48 actual paid Altar prerequisite producer", "claim": "Disclosed initial mechanics stock/configuration; actual ordinary build journal, no earned campaign or F48 criterion credit. " + str(_profile.provenance),
		"peers": 2, "scene": "title", "budget_s": 600, "build_allowance_s": 300, "steps": steps}
