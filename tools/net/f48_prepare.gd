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
	# The explicit producer may build its real paid prerequisite in the same
	# startup. The original suites and their admitted baseline stay unchanged.
	if bool(_profile.get("prepare_paid_altar", false)):
		_admit(steps, saves, 2, "initial-bootstrap")
		steps.append(_entry(0, "f48_watch_altar_save", {}, "Read-only actual transaction owner BOOL-save edge; no care exclusions or state writes"))
		steps.append_array(_route("bootstrap_altar", 0))
		steps.append(_entry(0, "f48_assert_altar_build", {"since": "initial-bootstrap"}))
		steps.append(_entry(1, "f48_assert", {"since": "initial-bootstrap", "unchanged": ["inventory", "party", "redesign_character", "satchel_escrow"]}))
		_capture_prepared_start(steps, "actual-paid-altar")
		steps.append(_entry("all", "f48_witness", {"remember": "admitted"}))
	else:
		_admit(steps, saves, 2)
	if bool(_profile.get("prepare_alpha_capture", false)):
		for peer: int in 2:
			steps.append(_entry(peer, "f48_fixture_capture", {"role": "host" if peer == 0 else "guest",
				"fixture_disclosure": "actual_shared_alpha_rng_and_actor_placement_no_earned_credit"}))
		_capture_prepared_start(steps, "actual-shared-alpha-catch")
		steps.append(_entry("all", "f48_witness", {"remember": "admitted-after-catch"}))
	# These remain prerequisite snapshots, never readiness claims: the complete
	# packager refuses a missing genuine caught source, paid Altar or route.
	for label: String in ["f48-loop-input", "f48-before-release", "f48-before-essence_spend"]:
		_capture_prepared_start(steps, label)
	_loop(steps, true)
	return {"name": "F48 genuine before-operation input producer",
		"claim": "Original full loop/oracles plus detached actual input snapshots; all24cut tests still required. " + str(_profile.provenance),
		"peers": 2, "scene": "title", "budget_s": 3600, "build_allowance_s": 300, "steps": steps}
