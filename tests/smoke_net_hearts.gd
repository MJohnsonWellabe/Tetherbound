extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B lane 5.B (+ 6.D). THE player-visible outcome of the lane: one player
## sets a Realm Heart into its socket and BOTH see it placed, while the two of
## them wear different Heart powers at the same time.
##
##   godot --headless --path . --script tests/smoke_net_hearts.gd
##
## or, with isolation, orphan-kill and a run-directory artifact:
##
##   tools/net/run_net_smoke.sh net_hearts
##
## ## What it asserts, and why in this order
##
## **Earned and placed are the WORLD's.** Both are world flags
## (`data/progression/flag_scopes.json`), so both are read back off
## `Game.world.flags` DIRECTLY, on both peers, rather than through the merged
## progression view. That is the discriminating half: a placement written to the
## presser's own player store answers `true` through the merged view on the peer
## that made it and `false` on its friend, which looks exactly like success from
## inside the process that did it. Asking the world store asks "does the WORLD
## say so", and only a flag the host committed can answer yes on the peer that
## did not press anything.
##
## The press is made by the CLIENT, deliberately. On the host `submit()` commits
## in-process and the delta lands before it returns, so a host-side press would
## pass even if the client half of the route were dead. The client gets
## `pending`, changes nothing locally, and the flag arrives as a committed delta
## -- which is the route this lane exists to build.
##
## **Which Heart is active is YOURS.** `realm_hearts._active_id` lives on the
## player half of the state split and is never submitted anywhere, so the two
## peers are driven apart on purpose and both directions are checked: first the
## client wears the Meadows Heart while the host wears none, then the host puts
## it on and the client takes it off, and the pair reads the other way round.
## Nothing either peer did to its own selection moved its friend's.
##
## A note on why "different" is proved as `meadows` vs `""` rather than as two
## named Hearts: `data/config/realm_hearts.json` ships exactly one Heart today
## (`meadows`). Inventing a second one to make a prettier assertion would be
## inventing a game decision, so this smoke asserts what the shipped data can
## honestly support -- the selections differ, and each moves without disturbing
## the other. When Cloudreach's Heart lands in that config, the natural
## strengthening is one line: both peers active, on different ids.
##
## ## Lane 6.D rides along, and why here rather than in a smoke of its own
##
## 6.D needs exactly what this smoke has already built by its halfway point --
## two peers in one session, each drawing the other's body -- and CI's net shard
## runs every `peers: 2` file in full. A second file would pay for a second
## handshake to assert five more lines. The 6.D half is clearly fenced below and
## can be lifted into its own file the moment it needs more than that.
##
## What it asserts is the LANE, not the look: a friend's hit, knockout and catch
## reach the body this process is drawing for them, and leave behind a counter, a
## signal-driven `last` kind, and a real effect node under that body. Whether the
## picture is any good is Stage C's bar and there are deliberately no renders
## here.
##
## ## The debug order if it fails
##
## `placed_in_world` false on BOTH peers means the intent never committed -- look
## at the client's `heart_place` detail line (a refusal names its code) and then
## at whether `Game.ledger` is mounted at all. `placed_in_world` true on the
## presser only means the write went local: `submit_place()` fell through to
## `RealmHeartState.place()` because it found no transport. `active` equal on
## both peers means something replicated a selection that must never be
## replicated. For the 6.D half: `plays` zero with a body present means the RPC
## did not resolve (check the node names match across processes); `plays` non-zero
## with `effect` empty means the effect layer is switched off
## (`data/config/vfx.json`). `effect` is the NAME the draw recorded, not a live
## scan: every one of these effects is a fraction of a second long and frees
## itself, and the first run of this smoke reported "no effect node" purely
## because it looked 60 frames after the picture had finished.

## The Heart this smoke drives. One shrine, one flag pair, one power.
const HEART := "meadows"
const REALM := "meadows"

## Frames to let a committed delta cross and be applied before either peer is
## asked what the world says. Ten times the round trip a loopback ENet link
## needs, so a failure here is a route that does not work rather than one that
## was not waited for.
const SETTLE_FRAMES := 60


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")

	# The honest gate, copied from `smoke_net_movement_two_peers.gd`: without a
	# session there is nothing shared to assert about, and a pile of downstream
	# failures would all mean only that.
	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session, "a Session exists to host/join; without it nothing here is shared")
	if not have_session:
		quit(await finish())
		return

	var hosted: Dictionary = await step(0, "host", {})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined peer 0's world on port %d (%s)" % [port, str(joined.get("detail", ""))])
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry holds both players (%s)" % [i, str(seen.get("detail", ""))])

	var hashes_ok := await assert_all_hashes_equal(300)
	check(hashes_ok, "both peers hold the same world after the handshake")

	await _hearts()
	await _presentation()

	quit(await finish())


# --- lane 5.B ------------------------------------------------------------------

func _hearts() -> void:
	# Both peers stand at a shrine. The shrine is a scene node and scene nodes
	# are not replicated: what is shared is the flag underneath it, which is the
	# whole claim.
	for i in 2:
		var bound: Dictionary = await step(i, "heart_bind", {"heart": HEART, "realm": REALM})
		check(str(bound.get("verdict", "")) == "PASS",
			"peer %d is standing at a Realm Heart shrine (%s)" % [i, str(bound.get("detail", ""))])

	# Nothing is earned yet, so the shrine is not offering anything to press.
	# Asserted before the grant so a config that ships the flag already set
	# cannot make the rest of this smoke vacuous.
	for i in 2:
		var cold: Dictionary = await _heart_state(i)
		check(cold.has("placed_in_world") and not bool(cold["placed_in_world"]),
			"peer %d starts with no Heart in the socket" % i)

	# The host earns it. A world fact, submitted as a `set_world_flag` intent.
	var earned: Dictionary = await step(0, "heart_earn", {"heart": HEART, "realm": REALM})
	check(str(earned.get("verdict", "")) == "PASS",
		"peer 0 earned the Heart through the ledger (%s)" % str(earned.get("detail", "")))
	await step(1, "wait", {"frames": SETTLE_FRAMES})

	for i in 2:
		var after_earn: Dictionary = await _heart_state(i)
		check(after_earn.has("earned_in_world") and bool(after_earn["earned_in_world"]),
			"peer %d's WORLD says the Heart is earned" % i)
		check(after_earn.has("placed_in_world") and not bool(after_earn["placed_in_world"]),
			"peer %d's world still has an empty socket" % i)

	# THE PRESS, made by the client. See the header for why it is not the host's.
	var placed: Dictionary = await step(1, "heart_place", {})
	check(str(placed.get("verdict", "")) == "PASS",
		"peer 1 pressed Place at the shrine (%s)" % str(placed.get("detail", "")))
	await step(0, "wait", {"frames": SETTLE_FRAMES})
	await step(1, "wait", {"frames": SETTLE_FRAMES})

	# The deliverable. Both peers, off the world store, not the merged view.
	for i in 2:
		var seen: Dictionary = await _heart_state(i)
		check(seen.has("placed_in_world") and bool(seen["placed_in_world"]),
			"peer %d's WORLD says the Heart is placed -- one player put it in, both see it" % i)
		check(seen.has("shrine_state") and str(seen["shrine_state"]) != "earned_unplaced",
			"peer %d's shrine repainted off the placement (state '%s')"
				% [i, str(seen.get("shrine_state", ""))])

	# And the personal half. Only peer 1 puts the power on.
	var worn: Dictionary = await step(1, "heart_activate", {"heart": HEART})
	check(str(worn.get("verdict", "")) == "PASS",
		"peer 1 is wearing the Heart's power (%s)" % str(worn.get("detail", "")))
	await step(0, "wait", {"frames": SETTLE_FRAMES})

	var client_on: Dictionary = await _heart_state(1)
	var host_off: Dictionary = await _heart_state(0)
	check(client_on.has("active") and str(client_on["active"]) == HEART,
		"peer 1's active Heart is '%s' (got '%s')" % [HEART, str(client_on.get("active", ""))])
	check(host_off.has("active") and str(host_off["active"]) == "",
		"peer 0 wears no Heart while peer 1 wears one (got '%s')" % str(host_off.get("active", "")))
	check(client_on.has("active") and host_off.has("active")
			and str(client_on["active"]) != str(host_off["active"]),
		"the two peers hold DIFFERENT active Hearts at the same time")
	# The power is a real number, not just a string: peer 1's stamina cap is
	# doubled and peer 0's is not, in one world, at one moment.
	check(float(client_on.get("stamina_multiplier", 1.0)) > float(host_off.get("stamina_multiplier", 1.0)),
		"peer 1's Heart power is actually in effect and peer 0's is not (%.2f vs %.2f)"
			% [float(client_on.get("stamina_multiplier", 1.0)),
				float(host_off.get("stamina_multiplier", 1.0))])

	# Now the other way round, which is what rules out "the client's selection
	# simply leaked to the host one tick late".
	var host_on: Dictionary = await step(0, "heart_activate", {"heart": HEART})
	check(str(host_on.get("verdict", "")) == "PASS",
		"peer 0 can wear the same placed Heart too (%s)" % str(host_on.get("detail", "")))
	var released: Dictionary = await step(1, "heart_activate", {"release": true})
	check(str(released.get("verdict", "")) == "PASS",
		"peer 1 took its Heart power off (%s)" % str(released.get("detail", "")))
	await step(0, "wait", {"frames": SETTLE_FRAMES})
	await step(1, "wait", {"frames": SETTLE_FRAMES})

	var swapped_host: Dictionary = await _heart_state(0)
	var swapped_client: Dictionary = await _heart_state(1)
	check(swapped_host.has("active") and str(swapped_host["active"]) == HEART,
		"peer 0 is now wearing the Heart (got '%s')" % str(swapped_host.get("active", "")))
	check(swapped_client.has("active") and str(swapped_client["active"]) == "",
		"peer 1 is now wearing none (got '%s')" % str(swapped_client.get("active", "")))
	# The world fact did not move while the two selections did.
	for i in 2:
		var still: Dictionary = await _heart_state(i)
		check(still.has("placed_in_world") and bool(still["placed_in_world"]),
			"peer %d's world still holds the placed Heart after both selections moved" % i)


## `has()` before `get()` everywhere above, and this is why the probe is fetched
## through one helper: a probe that came back null (a peer that died, a timeout)
## reads as an empty Dictionary, every `has()` is false, and the checks FAIL --
## rather than `int(null)` quietly answering 0 and a whole block of assertions
## passing for a peer that was never there.
func _heart_state(peer: int) -> Dictionary:
	var value = await probe(peer, "realm_heart", {"heart": HEART})
	return value if value is Dictionary else {}


# --- lane 6.D ------------------------------------------------------------------

func _presentation() -> void:
	# Both peers put a creature out, so each has a `remote_creature.gd` body of
	# the other's to draw on. The trainer bodies are already standing from the
	# handshake.
	for i in 2:
		var out: Dictionary = await step(i, "deploy_creature", {})
		check(str(out.get("verdict", "")) == "PASS",
			"peer %d has a creature out (%s)" % [i, str(out.get("detail", ""))])
	await step(0, "wait", {"frames": SETTLE_FRAMES})

	var before := await _drawn(0)
	check(_role_count(before, "creature") == 1,
		"peer 0 is drawing peer 1's creature (%d bodies it does not own)"
			% _role_count(before, "creature"))
	check(_role_count(before, "trainer") == 1,
		"peer 0 is drawing peer 1's trainer (%d bodies it does not own)"
			% _role_count(before, "trainer"))
	check(_all_have_presence(before, "creature"),
		"the friend's creature carries a companion layer of its own")

	# THE SAMPLER. Hit points come off peer 1's creature the same way the host
	# rolls them off, and peer 1's outbound proxy notices on its next tick and
	# publishes. Nothing in this step touches the wire directly.
	var hurt: Dictionary = await step(1, "present_damage", {"fraction": 0.3})
	check(str(hurt.get("verdict", "")) == "PASS",
		"peer 1's creature took a blow (%s)" % str(hurt.get("detail", "")))
	await step(0, "wait", {"frames": SETTLE_FRAMES})

	var after_hit := await _drawn(0)
	var creature_row := _row_for(after_hit, "creature")
	check(not creature_row.is_empty(),
		"peer 0 still has peer 1's creature body to draw on")
	check(creature_row.has("plays") and int(creature_row["plays"]) > 0,
		"a hit on peer 1's creature drew something on peer 0's copy of it (%d plays)"
			% int(creature_row.get("plays", -1)))
	check(creature_row.has("last") and str(creature_row["last"]) == "hit",
		"the picture peer 0 drew was the hit (got '%s')" % str(creature_row.get("last", "")))
	check(creature_row.has("effect") and not str(creature_row["effect"]).is_empty(),
		"the hit built a real effect node on peer 0's screen ('%s')"
			% str(creature_row.get("effect", "")))

	# The knockout. Published directly rather than by emptying the bar, and the
	# reason is the smoke's own reliability rather than a gap in the code: a
	# creature that actually faints is a creature `encounter_director.gd` may
	# put away, and a body that has been recalled mid-assertion reads as "the
	# picture never arrived". The sampler's own `fainted` branch is one line
	# beside the `hp` branch this smoke just proved end to end
	# (`remote_presentation.gd::diff`), and `tests/smoke_vfx_lifecycle.gd`
	# already owns the puff itself. What is under test here is the KO reaching
	# a body this process does not own.
	var felled: Dictionary = await step(1, "present_publish",
		{"role": "creature", "kind": "knockout"})
	check(str(felled.get("verdict", "")) == "PASS",
		"peer 1 published its creature going down (%s)" % str(felled.get("detail", "")))
	await step(0, "wait", {"frames": SETTLE_FRAMES})

	var after_ko := await _drawn(0)
	var ko_row := _row_for(after_ko, "creature")
	check(ko_row.has("plays") and int(ko_row["plays"]) > int(creature_row.get("plays", 0)),
		"the knockout drew again on peer 0 (%d plays, was %d)"
			% [int(ko_row.get("plays", -1)), int(creature_row.get("plays", 0))])
	check(ko_row.has("last") and str(ko_row["last"]) == "knockout",
		"the last picture peer 0 drew was the knockout (got '%s')" % str(ko_row.get("last", "")))

	# The trainer half: a catch peer 1 sealed reaches peer 0's copy of peer 1.
	var caught: Dictionary = await step(1, "present_publish",
		{"role": "trainer", "kind": "catch"})
	check(str(caught.get("verdict", "")) == "PASS",
		"peer 1 published its catch (%s)" % str(caught.get("detail", "")))
	await step(0, "wait", {"frames": SETTLE_FRAMES})

	var after_catch := await _drawn(0)
	var trainer_row := _row_for(after_catch, "trainer")
	check(not trainer_row.is_empty(), "peer 0 still has peer 1's trainer body to draw on")
	check(trainer_row.has("plays") and int(trainer_row["plays"]) > 0,
		"peer 1's catch drew a sparkle on peer 0's copy of peer 1 (%d plays)"
			% int(trainer_row.get("plays", -1)))
	check(trainer_row.has("effect") and not str(trainer_row["effect"]).is_empty(),
		"the catch built a real effect node on peer 0's screen ('%s')"
			% str(trainer_row.get("effect", "")))

	# And the negative half, which is what makes the rest mean anything: peer 1
	# drew none of this on its OWN outbound proxies. A publisher that also
	# played locally would double every picture on the owner's screen.
	var owner_side := await _drawn(1)
	check(_row_for(owner_side, "creature").get("plays", 0) == 0
			or not _row_for(owner_side, "creature").has("plays"),
		"peer 1 drew nothing on its own copy of peer 0's creature from its own publishes")


## The `remote_presentation` probe, defensively: a null probe reads as `{}` and
## fails the checks rather than answering 0 for every count.
func _drawn(peer: int) -> Dictionary:
	var value = await probe(peer, "remote_presentation")
	return value if value is Dictionary else {}


func _row_for(drawn: Dictionary, role: String) -> Dictionary:
	for key: Variant in drawn.keys():
		var row: Variant = drawn[key]
		if row is Dictionary and str((row as Dictionary).get("role", "")) == role:
			return row as Dictionary
	return {}


func _role_count(drawn: Dictionary, role: String) -> int:
	var n := 0
	for key: Variant in drawn.keys():
		var row: Variant = drawn[key]
		if row is Dictionary and str((row as Dictionary).get("role", "")) == role:
			n += 1
	return n


func _all_have_presence(drawn: Dictionary, role: String) -> bool:
	var seen := false
	for key: Variant in drawn.keys():
		var row: Variant = drawn[key]
		if not (row is Dictionary) or str((row as Dictionary).get("role", "")) != role:
			continue
		seen = true
		if not bool((row as Dictionary).get("presence", false)):
			return false
	return seen
