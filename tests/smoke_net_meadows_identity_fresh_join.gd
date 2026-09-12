extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Owner 2026-09-12 T4#2-#5: the production proof that the Meadows multiplayer
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

var _assertions := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	# Both production title transitions can spend one long blocking frame
	# building the Meadows. The ordinary step deadline remains the hard bound;
	# this only tells the heartbeat guard that a silent build is expected.
	heartbeat_silence_tolerance_s = 240.0
	if not await launch(2, "title"):
		quit(await finish())
		return

	_check(_peers.size() == 2, "coordinator tracked exactly two peers")
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

	# Move the world past its opening before the fresh player arrives. This is
	# the same ledger door the Warden defeat uses, not a write into a flag store.
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

	# The moved-on world's catch-up must grant one, and the starter receipt must
	# live on this character. A non-empty count is not enough: exactly one is
	# the contract and the row is retained for the later equality check.
	var first_party: Array = client_identity.get("party", []) as Array
	_check(int(client_identity.get("party_size", -1)) == 1 and first_party.size() == 1,
		"the moved-on host granted the fresh client exactly one starter (%s)"
			% str(first_party))
	var first_story := await _story(1, [STARTER_FLAG])
	_check(_player_flag(first_story, STARTER_FLAG) == true,
		"the production late-arrival grant recorded its character receipt")

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
	_check(bool(body.get("model_exists", false))
			and str(body.get("model_appearance_id", "")) == appearance,
		"%s's live Player/Model built chosen appearance '%s'"
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
	_check(str(row.get("appearance_id", "")) == str(expected.get("appearance", ""))
			and str(row.get("model_appearance_id", "")) == str(expected.get("appearance", "")),
		"%s and its live Model carry chosen appearance '%s'"
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
