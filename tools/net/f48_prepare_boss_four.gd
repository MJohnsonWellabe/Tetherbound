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
	if OS.get_environment("TB_F48_CAPTURE_PLAYERS") == "1":
		var resolution := OS.get_environment("TB_NET_PROOF_RESOLUTION")
		if OS.get_environment("TB_NET_PROOF_RENDER") != "1" or resolution not in ["1280x720", "1920x1080"]:
			_profile_errors.append("Actual Players capture requires native peers at 1280x720 or 1920x1080")
			return {}
		# Observe the already admitted original four carriers. Only the existing
		# Menu input, visible Players button focus/A and ordinary B are used.
		# Host first/last guest focus discloses the production scroll and footer.
		var capture_args := {"players_capture": true,
			"characters": ["$character0", "$character1", "$character2", "$character3"]}
		for peer: int in [0, 1]:
			var role := "host" if peer == 0 else "guest"
			steps.append(_entry(peer, "menu_toggle", {"open": true}, "Ordinary Menu input before actual four-peer Players capture"))
			steps.append(_entry(peer, "f48_button", {"text": "Players"}, "Focus actual visible Players tab button and press A"))
			steps.append({"peer": peer, "probe": "session", "args": capture_args,
				"expect_data": {"players_capture": {"ready": true, "initial_focus": true}},
				"label": "Actual " + role + " Players rows, input owner, original characters, focus, scroll and footer at " + resolution})
			steps.append({"peer": peer, "action": "screenshot", "args": {"name": "f48-players-" + role + "-initial-" + resolution},
				"expect_data": {"captured": true}, "label": "Native actual-world Players composite; headless cannot pass"})
			if peer == 0:
				steps.append(_entry(peer, "press", {"action": "ui_down", "times": 2}, "Ordinary D-pad focus through the host's three guest rows"))
				steps.append({"peer": peer, "probe": "session", "args": capture_args,
					"expect_data": {"players_capture": {"ready": true, "last_guest_focus": true}},
					"label": "Actual last guest focus and production follow-focus scroll"})
				steps.append({"peer": peer, "action": "screenshot", "args": {"name": "f48-players-host-last-" + resolution},
					"expect_data": {"captured": true}, "label": "Native lower roster focus with actual footer and world context"})
			steps.append(_entry(peer, "menu_toggle", {"open": false, "presses": 1}, "One ordinary B closes Players before the unchanged boss route"))
			steps.append({"peer": peer, "probe": "local_pause",
				"expect_data": {"menu_open": false, "context": "world", "owner": "", "paused": false},
				"label": "Ordinary Players close restores actual world input"})
	_boss(steps, 4)
	return {"name": "F48 genuine four-peer boss input producer",
		"claim": "Original four-peer boss oracle after exact input retention; no earned campaign credit. " + str(_profile.provenance),
		"peers": 4, "scene": "title", "budget_s": 3600, "build_allowance_s": 300, "steps": steps}
