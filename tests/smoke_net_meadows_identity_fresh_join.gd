extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Owner 2026-09-12 T4#1-#5: the production proof that the Meadows multiplayer
## front door carries two players' chosen identities all the way onto the real
## bodies each screen draws, and that a fresh late arrival enters the playable
## village with exactly one creature.
##
##   tools/net/run_net_smoke.sh meadows_identity_fresh_join
##
## Both processes boot the real title scene. The host finishes the same
## character-card/name continuation as Start New Game; the joiner uses
## `production_join`, which builds the world and calls the title's `_begin_join`
## just as a typed/LAN address does. The runner supplies choices because there
## is no human to click the two modal panels, but the production title helper is
## the only code allowed to write them.
##
## The evidence stays deliberately separated:
##   * PlayerState says what this player chose;
##   * the local Player/Model says what body this screen actually built;
##   * each Session registry says what crossed the handshake;
##   * each current-scene remote_trainer/Model says what body the viewer got;
##   * each body-owned Label3D says the chosen name and its actual fixed-size
##     settings (not values copied out of the .tscn source);
##   * each production full-map surface reports only the other same-realm body
##     as its named remote-player marker, at the position that surface draws;
##   * the joiner's real transform is tested against village_boundary.gd; and
##   * the joiner's real Party is sampled before and after another world delta.
##
## The second delta is the duplicate-starter negative control. Every world
## delta calls SequenceDirector.restore_progression_from_game(), which re-arms
## behind-character catch-up. A missing `_late_arrival_handled` latch therefore
## turns the one starter into two here; merely waiting after the first grant
## would not exercise that failure.

const HOST_NAME := "Rowan"
const HOST_APPEARANCE := "kael"
const CLIENT_NAME := "Juniper"
const CLIENT_APPEARANCE := "sera"
const MOVED_ON_FLAG := "defeated_warden"
const SECOND_WORLD_DELTA := "road_gate_open"
const STARTER_FLAG := "opening:starter_granted"
const CATCH_UP_FRAMES := 300
const DUPLICATE_GUARD_FRAMES := 240
const MAP_MARKER_NEAR_M := 1.5

var _assertions := 0
var _opening_together := false
## `--host-starter=N` / `--guest-starter=N` (opening-together only): how many
## `ui_right` presses each peer makes in the real starter picker, i.e. which of
## opening.json's `starters.species` it takes. One press (the second starter)
## when not given.
var _starter_presses: Array = [1, 1]
## The name each peer typed in the real naming grid (opening-together only).
var _typed_names: Array = ["", ""]
## `--cold` (opening-together only): after the rejoin, kill the guest's process
## and start a fresh one on the same user-data home, from the title.
var _cold := false


func _initialize() -> void:
	_run()


func _run() -> void:
	_opening_together = OS.get_cmdline_user_args().has("--opening-together")
	_cold = _opening_together and OS.get_cmdline_user_args().has("--cold")
	for arg: String in OS.get_cmdline_user_args():
		for pair: Array in [["--host-starter=", 0], ["--guest-starter=", 1]]:
			if arg.begins_with(str(pair[0])):
				_starter_presses[int(pair[1])] = int(arg.trim_prefix(str(pair[0])))
	# Both production title transitions can spend one long blocking frame
	# building the Meadows. The ordinary step deadline remains the hard bound;
	# this only tells the heartbeat guard that a silent build is expected.
	heartbeat_silence_tolerance_s = 240.0
	if not await launch(2, "title"):
		quit(await finish())
		return

	_check(_peers.size() == 2, "coordinator tracked exactly two peers")
	if _opening_together:
		# This mode includes both production world builds and two physical UI
		# openings; the default late-arrival witness retains its existing budget.
		_step_phase_deadline_ms = Time.get_ticks_msec() + (900.0 if _cold else 600.0) * 1000.0
	var before_host := await _session(0)
	var port := int(before_host.get("enet_port", 0))
	_check(port > 0, "the harness assigned the host a positive isolated UDP port (%d)" % port)

	var hosted: Dictionary = await step(0, "production_host", {
		"port": port,
		"appearance_id": HOST_APPEARANCE,
		"display_name": HOST_NAME,
	}, 12000)
	_check(str(hosted.get("verdict", "")) == "PASS",
		"the chosen host identity entered through the production title and hosted (%s)"
			% str(hosted.get("detail", "")))
	if str(hosted.get("verdict", "")) != "PASS":
		await _end()
		return

	if not _opening_together:
		# Default coverage remains the moved-on late-arrival contract.
		var moved_on: Dictionary = await step(0, "story_flag",
			{"flag": MOVED_ON_FLAG, "scope": "world"})
		_check(str(moved_on.get("verdict", "")) == "PASS",
			"the host moved the world past the opening through the production ledger (%s)"
				% str(moved_on.get("detail", "")))
		await step(0, "wait", {"frames": CATCH_UP_FRAMES})

	var joined: Dictionary = await step(1, "production_join", {
		"host": "127.0.0.1",
		"port": port,
		"returning_route": false,
		"character": {
			"appearance_id": CLIENT_APPEARANCE,
			"display_name": CLIENT_NAME,
		},
	}, 12000)
	_check(str(joined.get("verdict", "")) == "PASS",
		"the distinct fresh identity joined through the production title path (%s)"
			% str(joined.get("detail", "")))
	if str(joined.get("verdict", "")) != "PASS":
		await _end()
		return

	for peer in 2:
		var both: Dictionary = await step(peer, "expect_peers", {"count": 2})
		_check(str(both.get("verdict", "")) == "PASS",
			"peer %d's production registry holds both players (%s)"
				% [peer, str(both.get("detail", ""))])
	await step(1, "wait", {"frames": CATCH_UP_FRAMES})
	if _opening_together:
		for peer in 2:
			if not await _complete_fresh_opening(peer):
				await _end()
				return

	var host_session := await _session(0)
	var client_session := await _session(1)
	_check(bool(client_session.get("snapshot_ready", false)),
		"the fresh client applied the host snapshot rather than merely opening a socket")
	var host_peer_id := int(host_session.get("peer_id", 0))
	var client_peer_id := int(client_session.get("peer_id", 0))
	_check(host_peer_id == 1 and client_peer_id > 1 and host_peer_id != client_peer_id,
		"the session assigned two distinct real peer ids (host %d, client %d)"
			% [host_peer_id, client_peer_id])

	var expected := {
		str(host_peer_id): {"name": HOST_NAME, "appearance": HOST_APPEARANCE},
		str(client_peer_id): {"name": CLIENT_NAME, "appearance": CLIENT_APPEARANCE},
	}
	_check(HOST_NAME != CLIENT_NAME and HOST_APPEARANCE != CLIENT_APPEARANCE,
		"the test chose distinct names and distinct appearance ids")
	_assert_registry("host", host_session, expected)
	_assert_registry("client", client_session, expected)

	var host_identity := await _identity(0)
	var client_identity := await _identity(1)
	_assert_local_identity("host", host_identity, HOST_NAME, HOST_APPEARANCE)
	_assert_local_identity("fresh client", client_identity, CLIENT_NAME, CLIENT_APPEARANCE)
	_check(str(client_identity.get("realm", "")) == "meadows",
		"the fresh client ended in the Meadows realm")
	_check(bool(client_identity.get("inside_grandpas_village", false)),
		"the fresh client's real Player transform is inside Grandpa's Village (%s)"
			% str((client_identity.get("body", {}) as Dictionary).get("position", [])))

	# Every process holds both production remote-trainer bodies (including its
	# own hidden outbound proxy). Check both identities on both viewers; then
	# separately demand that the OTHER player's body and badge are visible.
	for viewer in 2:
		var value: Variant = await probe(viewer, "remote_trainers")
		var bodies: Dictionary = value as Dictionary if value is Dictionary else {}
		_check(bodies.size() == 2,
			"viewer %d has exactly two production trainer bodies in its scene (got %d)"
				% [viewer, bodies.size()])
		for peer_key: String in expected.keys():
			_assert_remote_identity(viewer, peer_key, bodies.get(peer_key, {}),
				expected[peer_key] as Dictionary,
				int(peer_key) != (host_peer_id if viewer == 0 else client_peer_id))

	# T4#1 is asserted on the shipping map, not inferred from the bodies above.
	# Open that surface with its real controller shortcut on each peer, then ask
	# the active tab for the exact filtered rows its draw loop consumes.
	await _assert_full_map_remote_marker(0, host_peer_id, client_peer_id, CLIENT_NAME)
	await _assert_full_map_remote_marker(1, client_peer_id, host_peer_id, HOST_NAME)

	# The moved-on world's catch-up must grant one, and the starter receipt must
	# live on this character. A non-empty count is not enough: exactly one is
	# the contract and the row is retained for the later equality check.
	if _opening_together:
		for peer in 2:
			var chosen := _starter_species(int(_starter_presses[peer]))
			var rows: Array = (host_identity if peer == 0 else client_identity).get("party", []) as Array
			_check(rows.size() == 1 and str(rows[0]).begins_with(chosen + "@"),
				"peer %d holds the starter it picked in the real picker, %s (%s)" % [peer, chosen, str(rows)])
			await _assert_named_starter(peer, "after the opening")
	var first_party: Array = client_identity.get("party", []) as Array
	_check(int(client_identity.get("party_size", -1)) == 1 and first_party.size() == 1,
		("the completed opening left the fresh client exactly one starter (%s)" if _opening_together \
		else "the moved-on host granted the fresh client exactly one starter (%s)")
			% str(first_party))
	for peer in (2 if _opening_together else 1):
		var receipt_peer: int = peer if _opening_together else 1
		var first_story := await _story(receipt_peer, [STARTER_FLAG])
		_check(_player_flag(first_story, STARTER_FLAG) == true,
			"peer %d's production starter grant recorded its character receipt" % receipt_peer)
	if _opening_together:
		for peer in 2:
			var reloaded: Dictionary = await step(peer, "save_reload_here", {})
			_check(str(reloaded.get("verdict", "")) == "PASS",
				"peer %d preserved its starter UID through production save/load (%s)" % [
					peer, str(reloaded.get("detail", ""))])
			var reloaded_rows: Array = (await _identity(peer)).get("party", []) as Array
			var picked := _starter_species(int(_starter_presses[peer]))
			_check(reloaded_rows.size() == 1 and str(reloaded_rows[0]).begins_with(picked + "@"),
				"peer %d still holds its %s after load (%s)" % [peer, picked, str(reloaded_rows)])
			var saved_story := await _story(peer, [STARTER_FLAG])
			_check(_player_flag(saved_story, STARTER_FLAG) == true,
				"peer %d retained its starter receipt after load" % peer)
			var saved_orbs: Dictionary = await step(peer, "assert", {"check": "inventory_count",
				"item": "orb_basic", "min": 45, "max": 50})
			_check(str(saved_orbs.get("verdict", "")) == "PASS",
				"peer %d retained its opening catch supplies after load" % peer)
			await _assert_named_starter(peer, "after load")
		await _rejoin_with_starter(port)
		await _assert_roads_agree("after the rejoin")
		if _cold:
			await _cold_reconnect(port)

	if not _opening_together:
		var second: Dictionary = await step(0, "story_flag",
			{"flag": SECOND_WORLD_DELTA, "scope": "world"})
		_check(str(second.get("verdict", "")) == "PASS",
			"a second production world delta re-armed catch-up (%s)"
				% str(second.get("detail", "")))
		await step(1, "wait", {"frames": DUPLICATE_GUARD_FRAMES})
		var after := await _identity(1)
		var after_party: Array = after.get("party", []) as Array
		_check(int(after.get("party_size", -1)) == 1 and after_party == first_party,
			"the re-armed late-arrival path did not duplicate or replace the starter (%s -> %s)"
				% [str(first_party), str(after_party)])

	await _end()


## Opt-in proof that two genuinely fresh peers can each traverse the shipping
## opening. Every position comes from the passive production probe and every
## transition is ordinary movement or a physical joypad action.
func _complete_fresh_opening(peer: int) -> bool:
	var opening := await _opening(peer)
	_check(bool(opening.get("sequence_present", false)),
		"peer %d has the production Meadows opening director" % peer)
	if not bool(opening.get("sequence_present", false)):
		return false
	if not await _move_to_opening_point(peer, opening.get("bed_prompt", []), "bed prompt", 1.5):
		return false
	if not await _press_opening(peer, "interact", "got up from the bed"):
		return false
	opening = await _opening(peer)
	var markers: Dictionary = opening.get("markers", {}) as Dictionary
	if not await _move_to_opening_point(peer, markers.get("stairs_top", []), "stairs top", 0.8):
		return false
	if not await _move_to_opening_point(peer, markers.get("stairs_bottom", []), "stairs bottom", 0.8):
		return false
	# Stay outside the player's 0.4m and NPC's 0.36m collision radii while
	# remaining well inside Grandpa's authored 3.8m interaction radius.
	if not await _move_to_opening_point(peer, opening.get("grandpa_prompt", []), "Grandpa prompt", 0.9):
		return false
	opening = await _opening(peer)
	if not bool((opening.get("dialogue", {}) as Dictionary).get("is_open", false)):
		if not await _press_opening(peer, "interact", "opened Grandpa's briefing"):
			return false
		opening = await _wait_opening_modal(peer, "dialogue", 60)
	if not bool((opening.get("dialogue", {}) as Dictionary).get("is_open", false)):
		print("opening briefing state: ", opening)
		_check(false, "peer %d reached Grandpa but the briefing dialogue never opened (beat %s)" % [
			peer, str(opening.get("beat", ""))])
		return false
	var dismissed: Dictionary = await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 30})
	_check(str(dismissed.get("verdict", "")) == "PASS",
		"peer %d closed Grandpa's real briefing (%s)" % [peer, str(dismissed.get("detail", ""))])
	if str(dismissed.get("verdict", "")) != "PASS":
		return false
	opening = await _wait_opening_modal(peer, "starter_picker", 120)
	_check(bool((opening.get("starter_picker", {}) as Dictionary).get("is_open", false)),
		"peer %d's starter picker opened after the briefing" % peer)
	if not bool((opening.get("starter_picker", {}) as Dictionary).get("is_open", false)):
		return false
	for press in int(_starter_presses[peer]):
		if not await _press_opening(peer, "ui_right", "moved the starter choice"):
			return false
	if not await _press_opening(peer, "menu_confirm", "chose the starter orb"):
		return false
	opening = await _wait_opening_modal(peer, "name_prompt", 120)
	_check(bool((opening.get("name_prompt", {}) as Dictionary).get("is_open", false)),
		"peer %d's naming grid opened after the starter choice" % peer)
	if not bool((opening.get("name_prompt", {}) as Dictionary).get("is_open", false)):
		return false
	# Type the selected first letter, then navigate using the live cursor rather
	# than assuming every command crossed the modal's input edge on the same frame.
	await step(peer, "wait", {"frames": 12})
	if not await _press_opening(peer, "menu_confirm", "typed one creature-name letter"):
		return false
	for attempt in 20:
		opening = await _opening(peer)
		var cursor: Dictionary = (opening.get("name_prompt", {}) as Dictionary).get("entry", {}) as Dictionary
		if str(cursor.get("cell", "")) == "\n":
			break
		var action := "ui_down" if int(cursor.get("row", -1)) < 7 else "ui_right"
		var moved_cursor: Dictionary = await step(peer, "press", {"action": action, "tap_frames": 3})
		if str(moved_cursor.get("verdict", "")) != "PASS":
			_check(false, "peer %d could not navigate its naming grid" % peer)
			return false
		await step(peer, "wait", {"frames": 12})
	opening = await _opening(peer)
	var entry: Dictionary = (opening.get("name_prompt", {}) as Dictionary).get("entry", {}) as Dictionary
	_check(int(entry.get("row", -1)) == 7 and int(entry.get("column", -1)) == 4
			and str(entry.get("cell", "")) == "\n" and not str(entry.get("text", "")).is_empty(),
		"peer %d reached the real naming Done cell (%s)" % [peer, str(entry)])
	if int(entry.get("row", -1)) != 7 or int(entry.get("column", -1)) != 4 \
			or str(entry.get("cell", "")) != "\n" or str(entry.get("text", "")).is_empty():
		return false
	_typed_names[peer] = str(entry.get("text", ""))
	if not await _press_opening(peer, "menu_confirm", "finished naming the starter"):
		return false
	opening = await _opening(peer)
	if not await _move_to_opening_point(peer, opening.get("grandpa_prompt", []), "return to Grandpa", 0.9):
		return false
	opening = await _opening(peer)
	if not bool((opening.get("dialogue", {}) as Dictionary).get("is_open", false)):
		if not await _press_opening(peer, "interact", "opened Grandpa's catch-supply reply"):
			return false
		opening = await _wait_opening_modal(peer, "dialogue", 60)
	if not bool((opening.get("dialogue", {}) as Dictionary).get("is_open", false)):
		_check(false, "peer %d returned to Grandpa but the catch-supply dialogue never opened" % peer)
		return false
	dismissed = await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 30})
	_check(str(dismissed.get("verdict", "")) == "PASS",
		"peer %d closed Grandpa's catch-supply reply (%s)" % [peer, str(dismissed.get("detail", ""))])
	var party: Dictionary = await step(peer, "assert", {"check": "party_size", "equals": 1})
	_check(str(party.get("verdict", "")) == "PASS",
		"peer %d received exactly one named starter (%s)" % [peer, str(party.get("detail", ""))])
	var orbs: Dictionary = await step(peer, "assert", {"check": "inventory_count",
		"item": "orb_basic", "min": 45, "max": 50})
	_check(str(orbs.get("verdict", "")) == "PASS",
		"peer %d received the opening Basic Orb grant (%s)" % [peer, str(orbs.get("detail", ""))])
	return str(dismissed.get("verdict", "")) == "PASS" \
		and str(party.get("verdict", "")) == "PASS" and str(orbs.get("verdict", "")) == "PASS"


func _opening(peer: int) -> Dictionary:
	var value: Variant = await probe(peer, "meadows_opening")
	return value as Dictionary if value is Dictionary else {}


func _wait_opening_modal(peer: int, key: String, attempts: int) -> Dictionary:
	var state: Dictionary = {}
	for _attempt in attempts:
		state = await _opening(peer)
		if bool((state.get(key, {}) as Dictionary).get("is_open", false)):
			return state
		await step(peer, "wait", {"frames": 2})
	return state


func _move_to_opening_point(peer: int, raw: Variant, label: String,
		close_enough: float) -> bool:
	var point: Array = raw as Array if raw is Array else []
	if point.size() < 3:
		_check(false, "peer %d opening probe has no %s position" % [peer, label])
		return false
	var moved: Dictionary = await step(peer, "move_to", {"x": float(point[0]), "z": float(point[2]),
		"close_enough": close_enough, "budget_frames": 1200})
	_check(str(moved.get("verdict", "")) == "PASS",
		"peer %d reached %s by ordinary movement (%s)" % [peer, label, str(moved.get("detail", ""))])
	print("opening peer %d %s position=%s target=%s" % [peer, label,
		str(await probe(peer, "position")), str(point)])
	return str(moved.get("verdict", "")) == "PASS"


func _press_opening(peer: int, action: String, claim: String) -> bool:
	var pressed: Dictionary = await step(peer, "press", {"action": action})
	_check(str(pressed.get("verdict", "")) == "PASS",
		"peer %d %s with physical '%s' (%s)" % [peer, claim, action, str(pressed.get("detail", ""))])
	return str(pressed.get("verdict", "")) == "PASS"


func _assert_registry(viewer: String, session: Dictionary, expected: Dictionary) -> void:
	var rows: Array = session.get("rows", []) as Array
	_check(rows.size() == 2, "%s registry contains exactly two identity rows" % viewer)
	var actual := {}
	for raw: Variant in rows:
		if raw is Dictionary:
			var row := raw as Dictionary
			actual[str(int(row.get("peer_id", 0)))] = {
				"name": str(row.get("display_name", "")),
				"appearance": str(row.get("appearance_id", "")),
			}
	_check(actual == expected,
		"%s registry carries both chosen names/appearances exactly (%s)"
			% [viewer, str(actual)])


func _assert_local_identity(label: String, identity: Dictionary, name: String,
		appearance: String) -> void:
	_check(str(identity.get("display_name", "")) == name,
		"%s PlayerState retained chosen name '%s'" % [label, name])
	_check(str(identity.get("appearance_id", "")) == appearance,
		"%s PlayerState retained chosen appearance '%s'" % [label, appearance])
	_check(not str(identity.get("character_id", "")).is_empty(),
		"%s has a minted portable character id" % label)
	var body: Dictionary = identity.get("body", {}) as Dictionary
	_check(bool(body.get("exists", false)) and bool(body.get("in_current_scene", false)),
		"%s has a real Player body under its current production scene" % label)
	_check(bool(body.get("model_exists", false)) and bool(body.get("model_has_art", false))
			and str(body.get("model_appearance_id", "")) == appearance,
		"%s's live Player/Model built real art for chosen appearance '%s'"
			% [label, str(body.get("model_appearance_id", ""))])


func _assert_remote_identity(viewer: int, peer_key: String, raw: Variant,
		expected: Dictionary, should_be_visible: bool) -> void:
	var row: Dictionary = raw as Dictionary if raw is Dictionary else {}
	var label := "viewer %d body %s" % [viewer, peer_key]
	_check(not row.is_empty(), "%s exists" % label)
	_check(bool(row.get("in_current_scene", false)),
		"%s belongs to the viewer's current production scene" % label)
	_check(str(row.get("display_name", "")) == str(expected.get("name", "")),
		"%s carries chosen display name '%s'" % [label, str(row.get("display_name", ""))])
	_check(bool(row.get("model_has_art", false))
			and str(row.get("appearance_id", "")) == str(expected.get("appearance", ""))
			and str(row.get("model_appearance_id", "")) == str(expected.get("appearance", "")),
		"%s and its live Model carry built art for chosen appearance '%s'"
			% [label, str(expected.get("appearance", ""))])
	var plate: Dictionary = row.get("nameplate", {}) as Dictionary
	_check(bool(plate.get("exists", false))
			and str(plate.get("text", "")) == str(expected.get("name", "")),
		"%s's actual Nameplate shows chosen name '%s'"
			% [label, str(plate.get("text", ""))])
	_check(bool(plate.get("fixed_size", false))
			and int(plate.get("font_size", 999)) <= 30
			and int(plate.get("outline_size", 999)) <= 6,
		"%s uses compact fixed-size nameplate settings (font %d, outline %d)"
			% [label, int(plate.get("font_size", -1)), int(plate.get("outline_size", -1))])
	if should_be_visible:
		_check(bool(row.get("visible", false)) and bool(plate.get("visible", false)),
			"%s is the other player and both its body and chosen-name badge are visible" % label)


func _assert_full_map_remote_marker(viewer: int, own_peer_id: int,
		other_peer_id: int, other_name: String) -> void:
	var opened: Dictionary = await step(viewer, "menu_toggle",
		{"open": true, "action": "map", "within_frames": 120})
	_check(str(opened.get("verdict", "")) == "PASS",
		"viewer %d opened the production full map with its physical map shortcut (%s)"
			% [viewer, str(opened.get("detail", ""))])
	await step(viewer, "wait", {"frames": 12})
	var value: Variant = await probe(viewer, "map_remote_players")
	var report: Dictionary = value as Dictionary if value is Dictionary else {}
	_check(bool(report.get("menu_open", false)) and str(report.get("tab_id", "")) == "map"
			and bool(report.get("surface_exists", false))
			and bool(report.get("surface_visible", false))
			and str(report.get("surface_script", "")) == "res://scripts/ui/tab_map.gd",
		"viewer %d's active visible menu surface is the production full-map tab"
			% viewer)
	_check(bool(report.get("map_state_bound", false))
			and str(report.get("displayed_realm", "")) == "meadows",
		"viewer %d's full map is bound to its live Meadows MapState" % viewer)
	var rows: Array = report.get("rows", []) as Array
	_check(rows.size() == 1,
		"viewer %d's full map renders exactly one remote player row (got %s)"
			% [viewer, str(rows)])
	var row: Dictionary = {}
	if rows.size() == 1 and rows[0] is Dictionary:
		row = rows[0] as Dictionary
	_check(int(row.get("peer_id", 0)) == other_peer_id
			and int(row.get("peer_id", 0)) != own_peer_id,
		"viewer %d's map includes only the other peer %d, never own hidden proxy %d"
			% [viewer, other_peer_id, own_peer_id])
	_check(str(row.get("display_name", "")) == other_name,
		"viewer %d's map labels the other player with chosen name '%s'"
			% [viewer, other_name])
	var owner_position: Variant = await probe(1 - viewer, "position")
	var marker_position: Variant = row.get("position", [])
	var gap := _planar_gap(marker_position, owner_position)
	_check(gap >= 0.0 and gap <= MAP_MARKER_NEAR_M,
		"viewer %d's map marker agrees with peer %d's live position within %.1f m (%.2f m)"
			% [viewer, other_peer_id, MAP_MARKER_NEAR_M, gap])
	var closed: Dictionary = await step(viewer, "menu_toggle",
		{"open": false, "action": "menu_cancel", "within_frames": 120})
	_check(str(closed.get("verdict", "")) == "PASS",
		"viewer %d closed the production full map cleanly (%s)"
			% [viewer, str(closed.get("detail", ""))])


func _planar_gap(a: Variant, b: Variant) -> float:
	if not a is Array or not b is Array or (a as Array).size() < 3 or (b as Array).size() < 3:
		return -1.0
	return Vector2(float((a as Array)[0]) - float((b as Array)[0]),
		float((a as Array)[2]) - float((b as Array)[2])).length()


## The starter this peer picked, under the name it typed, and nothing else.
func _assert_named_starter(peer: int, when: String) -> void:
	var identity := await _identity(peer)
	var rows: Array = identity.get("party", []) as Array
	var names: Array = identity.get("party_names", []) as Array
	var picked := _starter_species(int(_starter_presses[peer]))
	_check(rows.size() == 1 and str(rows[0]).begins_with(picked + "@") and names == [_typed_names[peer]]
			and not str(_typed_names[peer]).is_empty(),
		"peer %d's starter is its %s named '%s' %s (%s %s)" % [peer, picked, _typed_names[peer], when, str(rows), str(names)])


## A starter that already exists crosses a join: the guest's link dies, its
## live character is blanked, and the same character comes back through the
## title's returning route. What it holds then came from its saved character
## and the join, not from memory.
func _rejoin_with_starter(port: int) -> void:
	var before := await _identity(1)
	var character_id := str(before.get("character_id", ""))
	var starter_uids: Array = before.get("party_uids", []) as Array
	_check(starter_uids.size() == 1 and not str(starter_uids[0]).is_empty(),
		"the guest's starter has a UID before the drop (%s)" % str(starter_uids))
	var counted: Dictionary = await step(1, "assert", {"check": "inventory_count", "item": "orb_basic", "min": 0})
	var orbs_before := int(str(counted.get("detail", "")).get_slice("count ", 1).to_int()) \
		if str(counted.get("detail", "")).contains("count ") else -1
	_check(orbs_before >= 45, "the guest's orb count before the drop is read (%d)" % orbs_before)
	var saved: Dictionary = await step(1, "save_character_here", {})
	_check(str(saved.get("verdict", "")) == "PASS", "the guest's character is written (%s)" % str(saved.get("detail", "")))
	var dropped: Dictionary = await step(1, "drop_link", {"settle_frames": 60})
	_check(str(dropped.get("verdict", "")) == "PASS", "the guest's link dies (%s)" % str(dropped.get("detail", "")))
	var alone: Dictionary = await step(0, "expect_peers", {"count": 1}, 900)
	_check(str(alone.get("verdict", "")) == "PASS", "the host sees the guest gone (%s)" % str(alone.get("detail", "")))
	var wiped: Dictionary = await step(1, "wipe_character", {})
	_check(str(wiped.get("verdict", "")) == "PASS", "the guest's live character is blanked (%s)" % str(wiped.get("detail", "")))
	var back: Dictionary = await step(1, "production_join", {
		"host": "127.0.0.1", "port": port, "returning_route": true, "budget_frames": 6000,
		"character": {"character_id": character_id, "appearance_id": CLIENT_APPEARANCE, "display_name": CLIENT_NAME},
	}, 12000)
	_check(str(back.get("verdict", "")) == "PASS",
		"the same character rejoins through the title's returning route (%s)" % str(back.get("detail", "")))
	for peer in 2:
		var both: Dictionary = await step(peer, "expect_peers", {"count": 2})
		_check(str(both.get("verdict", "")) == "PASS", "peer %d sees both players again (%s)" % [peer, str(both.get("detail", ""))])
	var rejoined := await _identity(1)
	_check(rejoined.get("party_uids", []) == starter_uids,
		"the rejoined guest holds the SAME starter creature, not a new one (UID %s -> %s)"
			% [str(starter_uids), str(rejoined.get("party_uids", []))])
	# The rejoin mints a new peer id: both registries must name the returning
	# character and the host, and nobody else.
	for viewer in 2:
		var sess := await _session(viewer)
		var chars: Array = []
		for raw: Variant in (sess.get("rows", []) as Array):
			if raw is Dictionary:
				chars.append(str((raw as Dictionary).get("character_id", "")))
		chars.sort()
		var want := [character_id, str((await _identity(0)).get("character_id", ""))]
		want.sort()
		_check(chars == want, "peer %d's registry after the rejoin holds exactly the host and the returning character (%s)" % [viewer, str(chars)])
	await _assert_named_starter(1, "after rejoining")
	var story := await _story(1, [STARTER_FLAG])
	_check(_player_flag(story, STARTER_FLAG) == true, "the rejoined guest kept its starter receipt")
	var orbs: Dictionary = await step(1, "assert", {"check": "inventory_count", "item": "orb_basic",
		"min": orbs_before, "max": orbs_before})
	_check(str(orbs.get("verdict", "")) == "PASS",
		"the rejoined guest holds exactly the %d orbs it had before the drop (%s)" % [orbs_before, str(orbs.get("detail", ""))])
	await _assert_named_starter(0, "with the guest back")


## Both peers hold the same road layout: the road bands each built from the
## terrain config it loaded, and its live baked ground at every road vertex.
func _assert_roads_agree(when: String) -> void:
	var host_roads: Variant = await probe(0, "road_signature")
	var guest_roads: Variant = await probe(1, "road_signature")
	var h: Dictionary = host_roads if host_roads is Dictionary else {}
	var g: Dictionary = guest_roads if guest_roads is Dictionary else {}
	_check(bool(h.get("available", false)) and bool(g.get("available", false))
			and int(h.get("bands", 0)) > 0 and int(h.get("points", 0)) > 0
			and str(h.get("signature", "")) == str(g.get("signature", "")),
		"both peers hold the same road layout %s (host %d bands / %d points %s, guest %d / %d %s)"
			% [when, int(h.get("bands", 0)), int(h.get("points", 0)), str(h.get("signature", "")).left(12),
				int(g.get("bands", 0)), int(g.get("points", 0)), str(g.get("signature", "")).left(12)])


## A COLD reconnect: the guest's process is killed outright (no save, no leave),
## a fresh process boots the title on the same user-data home, and the same
## character comes back through the title's returning route. Everything it
## holds then came off disk.
func _cold_reconnect(port: int) -> void:
	var before := await _identity(1)
	var character_id := str(before.get("character_id", ""))
	var uids: Array = before.get("party_uids", []) as Array
	var counted: Dictionary = await step(1, "assert", {"check": "inventory_count", "item": "orb_basic", "min": 0})
	var orbs_before := int(str(counted.get("detail", "")).get_slice("count ", 1).to_int()) \
		if str(counted.get("detail", "")).contains("count ") else -1
	var saved: Dictionary = await step(1, "save_character_here", {})
	_check(str(saved.get("verdict", "")) == "PASS", "COLD: the guest's character is on disk before its process dies (%s)" % str(saved.get("detail", "")))
	var p: Dictionary = _peers[1]
	p["quit_sent"] = true
	var pid := int(p.get("pid", -1))
	if pid > 0 and OS.is_process_running(pid):
		OS.execute("kill", ["-9", str(pid)])
	for _i in 600:
		await process_frame
		if not OS.is_process_running(pid):
			break
	p["exited"] = true
	_check(not OS.is_process_running(pid), "COLD: the guest's process is gone (pid %d, killed -9)" % pid)
	# A killed process sends no disconnect: the host learns of it only through
	# ENet's peer timeout (session.gd peer_timeout_min_ms 135 s .. max 180 s).
	# Wall time, not frames. ENet's peer timeout (session.gd: minimum 135 s,
	# maximum 180 s) is tested only when a reliable command reaches its
	# backed-off retransmit timeout, so the drop lands between 135 s and 180 s
	# plus one capped retransmit interval (measured: 148.9 s, 183.4 s, and one
	# run past 190 s). 240 s bounds that; a longer silence is a real hang.
	var alone: Dictionary = await step(0, "expect_peers", {"count": 1, "budget_s": 240.0}, 15000)
	_check(str(alone.get("verdict", "")) == "PASS", "COLD: the host times the dead guest out (%s)" % str(alone.get("detail", "")))
	if not await _relaunch_guest():
		return
	var back: Dictionary = await step(1, "production_join", {
		"host": "127.0.0.1", "port": port, "returning_route": true, "pick_saved": true, "budget_frames": 6000,
		"character": {"character_id": character_id, "appearance_id": CLIENT_APPEARANCE, "display_name": CLIENT_NAME},
	}, 12000)
	_check(str(back.get("verdict", "")) == "PASS",
		"COLD: a fresh guest process rejoins as the same character through the title's returning route (%s)" % str(back.get("detail", "")))
	for peer in 2:
		var both: Dictionary = await step(peer, "expect_peers", {"count": 2})
		_check(str(both.get("verdict", "")) == "PASS", "COLD: peer %d sees both players again (%s)" % [peer, str(both.get("detail", ""))])
	var after := await _identity(1)
	_check(str(after.get("character_id", "")) == character_id and after.get("party_uids", []) == uids,
		"COLD: the fresh process holds the same character and the SAME starter (UID %s -> %s)" % [str(uids), str(after.get("party_uids", []))])
	await _assert_named_starter(1, "after the cold reconnect")
	var story := await _story(1, [STARTER_FLAG])
	_check(_player_flag(story, STARTER_FLAG) == true, "COLD: the starter receipt came back from disk")
	var orbs: Dictionary = await step(1, "assert", {"check": "inventory_count", "item": "orb_basic",
		"min": orbs_before, "max": orbs_before})
	_check(str(orbs.get("verdict", "")) == "PASS",
		"COLD: exactly the %d orbs it had before its process died (%s)" % [orbs_before, str(orbs.get("detail", ""))])
	await _assert_named_starter(0, "with the cold guest back")
	await _assert_roads_agree("after the cold reconnect")


## A fresh process for peer 1 on its own user-data home and log, booted at the
## title, then wait for its hello.
func _relaunch_guest() -> bool:
	var controls := CONTROL_PORTS.reserve(1, 0)
	if not bool(controls.ok):
		_check(false, "COLD: could not reserve a control port for the relaunch")
		return false
	var old: Dictionary = _peers[1]
	var server: TCPServer = controls.servers[0]
	_control_servers.append(server)
	# Its own log: the killed process's log is evidence too.
	var cold_log := str(old.log_path).get_basename() + "-cold.log"
	var pid := _spawn_peer(1, "client", int(controls.ports[0]), enet_port_for(1), "title",
		str(old.home), cold_log, [])
	print("coordinator: relaunched peer 1 (client) pid=%d at the title" % pid)
	_peers[1] = {
		"index": 1, "role": "client", "server": server, "sock": null, "rx_buf": "",
		"pid": pid, "home": old.home, "log_path": cold_log, "control_port": int(controls.ports[0]),
		"hashes": [], "hello": null, "exited": false, "unexpected_exit": false,
		"quit_sent": false, "last_heartbeat_t": 0.0, "last_heartbeat": null,
		"heartbeat_deferred_until_s": 0.0, "last_verdict": null, "last_value": null,
	}
	var deadline := Time.get_ticks_msec() + DEFAULT_HELLO_BUDGET_S * 1000.0
	while Time.get_ticks_msec() < deadline:
		await process_frame
		_pump_once()
		if (_peers[1] as Dictionary).get("hello") != null:
			return true
	_check(false, "COLD: the relaunched guest never said hello")
	return false


## opening.json's starter at picker index `index` (the picker opens on 0).
func _starter_species(index: int) -> String:
	var opening: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/opening.json"))
	var species: Array = ((opening as Dictionary).get("starters", {}) as Dictionary).get("species", []) \
		if opening is Dictionary else []
	return str(species[index]) if index >= 0 and index < species.size() else "?"


func _session(peer: int) -> Dictionary:
	var value: Variant = await probe(peer, "session")
	return value as Dictionary if value is Dictionary else {}


func _identity(peer: int) -> Dictionary:
	var value: Variant = await probe(peer, "player_identity")
	return value as Dictionary if value is Dictionary else {}


func _story(peer: int, flags: Array) -> Dictionary:
	var value: Variant = await probe(peer, "story", {"player_flags": flags})
	return value as Dictionary if value is Dictionary else {}


func _player_flag(story: Dictionary, flag: String) -> Variant:
	var player: Variant = story.get("player", null)
	if not player is Dictionary or not (player as Dictionary).has(flag):
		return null
	return bool((player as Dictionary)[flag])


func _check(condition: bool, message: String) -> void:
	_assertions += 1
	check(condition, message)


func _end() -> void:
	print("assertions run: %d" % _assertions)
	quit(await finish())
