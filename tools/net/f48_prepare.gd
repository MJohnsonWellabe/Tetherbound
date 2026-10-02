extends "res://tests/helpers/f48_net_proof.gd"

## ROOT runs this explicitly under its native lease. The unchanged original
## loop and oracles run once; captures only retain genuine before-operation
## inputs. This has no CI peers header and cannot replace a required smoke.
func suite() -> String:
	return "prepare_inputs"

func _build() -> Dictionary:
	var saves: Variant = _profile.get("saves", [])
	if not saves is Array or saves.size() != 2 or str(_profile.get("provenance", "")).is_empty():
		_profile_errors.append("Input production requires two distinct actual v28 starts and disclosed origin")
		return {}
	var steps: Array = []
	_admit(steps, saves, 2)
	# These remain prerequisite snapshots, never readiness claims: the complete
	# packager refuses a missing genuine caught source, paid Altar or route.
	for label: String in ["f48-loop-input", "f48-before-release", "f48-before-essence_spend"]:
		_capture_prepared_start(steps, label)
	_loop(steps, true)
	return {"name": "F48 genuine before-operation input producer",
		"claim": "Original full loop/oracles plus detached actual input snapshots; all24cut tests still required. " + str(_profile.provenance),
		"peers": 2, "scene": "title", "budget_s": 3600, "build_allowance_s": 300, "steps": steps}
