extends SceneTree

## SE23: is the Tether Relay Station a real place you can walk into, cross,
## and switch off?
##
##   godot --headless --path . --script tests/smoke_relay.gd
##
## The unit suite cannot see any of this. A compound built from primitive
## boxes either has decks a CharacterBody3D can stand on and a gate it can
## walk through, or it is a diorama the player falls past — and the only way
## to tell the two apart is to boot the world, stand in it and push. Same
## reason `smoke_warrens.gd` exists for the dungeon, and this file borrows its
## `_put_down` / `_push` harness verbatim rather than inventing a second one.
##
## What it asserts, in the order the player meets it:
##
##   * the station built at all, at the coordinate `relay_site.json` named
##   * the gate is OPEN: walking up the approach gets you inside the compound
##   * the raised decks are FLOORS: the player stands on the gantry and on the
##     apparatus pad at the authored height, not through them
##   * the ramp is the route: it is walkable, and the pad is not reachable by
##     walking at its side
##   * the console sets the flag exactly ONCE and is one-way
##   * the conduits are lit before and dead after
##   * the `requires_flag` gate refuses when its flag is unset
##   * the drained ground is present, and is the WORST in the region (D41)
##
## The trainers are not FOUGHT here. `smoke_trainer_battle.gd` is the test
## that pilots a trainer fight, and SE25 owns the relay's own four; re-running
## that here would be a second copy of the same coverage plus minutes of CI.
## What this proves is that the site the fights happen on is real.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const RELAY_CONFIG := "res://data/config/tether_relay.json"
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SETTLE_FRAMES := 240
const PUSH_FRAMES := 200

var _failures: Array[String] = []
var _config: Dictionary = {}


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	_config = _json(RELAY_CONFIG)
	if _config.is_empty():
		print("relay FAIL: data/config/tether_relay.json is missing or unreadable")
		quit(1)
		return

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var relay: Node3D = world.get_node_or_null(^"TetherRelay") as Node3D
	if player == null or relay == null:
		print("relay FAIL: the scene has no Player or no TetherRelay node")
		quit(1)
		return

	var game := root.get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression == null:
		print("relay FAIL: no Game autoload with a progression store")
		quit(1)
		return
	# A fresh station, whatever a save left behind.
	progression.call("set_flag", str(relay.call("console_flag")), false)
	# The shipped console now gates on the relay captain (see below). The
	# one-way test is about the console, not the gate, so grant the captain
	# here rather than teaching that test about a second subject.
	progression.call("set_flag", "relay_captain_defeated")

	var stats: Dictionary = relay.call("stats")
	print("relay stands at %s: %s" % [stats.get("centre"), stats])

	_the_station_stands(relay, stats)
	await _the_gate_is_open_and_the_yard_is_walkable(world, player, relay)
	await _the_decks_are_floors(player, relay)
	await _the_ramp_is_the_route(player, relay)
	_the_console_is_one_way(relay, progression)
	_the_console_can_be_gated(relay, progression)
	_the_ground_is_drained(relay)
	await _the_local_ground_heals_on_disable(relay)

	print("")
	if _failures.is_empty():
		print("relay smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## The station is where SE25/SE27 said it would be, and it is made of the
## things the item asks for. The coordinate is ADOPTED from relay_site.json,
## so this checks the two files still agree rather than checking a literal.
func _the_station_stands(relay: Node3D, stats: Dictionary) -> void:
	var authored := _site_centre()
	var built: Vector2 = stats.get("centre", Vector2.INF)
	if authored == Vector2.INF:
		_fail("data/config/relay_site.json names no site centre to adopt")
	elif built.distance_to(authored) > 0.01:
		_fail("the relay built at %s but relay_site.json (SE25/SE27) says %s — the two files must agree"
			% [built, authored])
	if int(stats.get("walls", 0)) < 3:
		_fail("the compound has %d wall runs; it does not enclose anything" % int(stats.get("walls", 0)))
	if int(stats.get("decks", 0)) < 2:
		_fail("the station has %d raised decks; there is no traversal" % int(stats.get("decks", 0)))
	if int(stats.get("ramps", 0)) < 1:
		_fail("the station has no ramp, so nothing raised can be reached")
	if int(stats.get("pylons", 0)) < 6:
		_fail("only %d pylons stand; the conduit runs do not converge on anything"
			% int(stats.get("pylons", 0)))
	if relay.get_node_or_null(^"ApparatusSeam/Console") == null:
		_fail("there is no Console on the apparatus seam — the thing SE23 exists to let the player disable")


## The gate is open and the compound is enterable. Dropped on the approach
## road outside the wall, pushing straight up the site's own axis ends up
## inside — no leaves, no lock, nothing to unlock.
func _the_gate_is_open_and_the_yard_is_walkable(world: Node, player: CharacterBody3D,
		relay: Node3D) -> void:
	var outside: Vector2 = relay.call("world_of", Vector2(-24.0, 0.0))
	var inside: Vector2 = relay.call("world_of", Vector2(-2.0, 0.0))
	var ground: float = float(world.call("ground_height_at", outside.x, outside.y))
	await _put_down(player, Vector3(outside.x, ground + 1.2, outside.y))
	if not player.is_on_floor():
		_fail("the player does not stand on the ground on the relay's approach road")
	var toward := Vector3(inside.x - outside.x, 0.0, inside.y - outside.y).normalized()
	var before := player.global_position
	await _push(player, toward, _frames_for(outside.distance_to(inside)))
	var here: Vector2 = relay.call("local_of",
		Vector2(player.global_position.x, player.global_position.z))
	var travelled := before.distance_to(player.global_position)
	# In the site's own frame, so the question is "did they get past the gate
	# line", not "did they stop near a point". A push budget long enough to
	# reach the yard is also long enough to walk out the far side of it, and
	# measuring distance-to-target scored that overshoot as a failure to enter.
	var gate_line := float((_config.get("gate", {}) as Dictionary).get("at", [-14.0, 0.0])[0])
	print("walked %.1fm up the approach; ended at s=%.1f, t=%.1f against a gate line at s=%.1f" % [
		travelled, here.x, here.y, gate_line])
	if here.x < gate_line + 2.0:
		_fail("walking straight up the approach never got past the gate (s=%.1f, gate at s=%.1f) — the gate is not open"
			% [here.x, gate_line])
	if absf(here.y) > 6.0:
		_fail("the walk up the approach was deflected %.1fm off the road axis; something is standing in the gateway"
			% absf(here.y))


## The raised decks are floors. Put down just above each one, the player
## should end up resting ON it at the authored `deck_y`, not falling past it
## to the yard several metres below.
func _the_decks_are_floors(player: CharacterBody3D, relay: Node3D) -> void:
	for entry: Variant in _config.get("decks", []):
		var deck: Dictionary = entry as Dictionary
		var at: Array = deck.get("at", [])
		if at.size() < 2:
			continue
		var id := str(deck.get("id", "deck"))
		var top := float(deck.get("deck_y", 0.0))
		var spot: Vector2 = relay.call("world_of", Vector2(float(at[0]), float(at[1])))
		await _put_down(player, Vector3(spot.x, top + 1.2, spot.y))
		var resting := player.global_position.y
		print("dropped onto the %s deck (top y=%.2f); player rests at y=%.2f, on_floor=%s" % [
			id, top, resting, player.is_on_floor()])
		if not player.is_on_floor():
			_fail("the player never settled on the %s deck" % id)
		if absf(resting - top) > 1.0:
			_fail("the player fell through the %s deck: rests at y=%.2f against a deck top of y=%.2f"
				% [id, resting, top])


## The ramp is the route to the console, and it is the ONLY one. Two halves:
## walking up the ramp gets you to deck height, and walking at the pad's side
## from the yard does not.
func _the_ramp_is_the_route(player: CharacterBody3D, relay: Node3D) -> void:
	var ramps: Array = _config.get("ramps", [])
	if ramps.is_empty():
		return
	var ramp: Dictionary = ramps[0] as Dictionary
	var from: Array = ramp.get("from", [])
	var to: Array = ramp.get("to", [])
	if from.size() < 2 or to.size() < 2:
		return
	var top := float(ramp.get("deck_y", 0.0))
	var foot_local := Vector2(float(from[0]), float(from[1]))
	var head_local := Vector2(float(to[0]), float(to[1]))
	# Start a little BEFORE the foot, so the run includes stepping onto the
	# ramp from the yard — a lip the player cannot mount is the same bug as a
	# ramp that is too steep.
	var start_local := foot_local + (foot_local - head_local).normalized() * 2.0
	var foot: Vector2 = relay.call("world_of", start_local)
	var head: Vector2 = relay.call("world_of", head_local)
	var ground := _ground_under(relay, start_local)
	await _put_down(player, Vector3(foot.x, ground + 1.2, foot.y))
	var climbed := await _push(player, Vector3(head.x - foot.x, 0.0, head.y - foot.y).normalized(),
		_frames_for(foot.distance_to(head)))
	print("walked up the ramp from y=%.2f; reached y=%.2f against a deck top of y=%.2f" % [
		ground, climbed, top])
	if climbed < top - 1.0:
		_fail("the ramp did not carry the player to deck height (y=%.2f, deck top y=%.2f) — the console is unreachable"
			% [climbed, top])

	# And the pad is not reachable by walking at its flank from the yard.
	var pad_local := _deck_local("pad")
	if pad_local == Vector2.INF:
		return
	var beside := pad_local + Vector2(0.0, 12.0)
	var beside_xz: Vector2 = relay.call("world_of", beside)
	var pad_ground := _ground_under(relay, beside)
	await _put_down(player, Vector3(beside_xz.x, pad_ground + 1.2, beside_xz.y))
	var pad_xz: Vector2 = relay.call("world_of", pad_local)
	var peak := await _push(player,
		Vector3(pad_xz.x - beside_xz.x, 0.0, pad_xz.y - beside_xz.y).normalized(),
		_frames_for(beside_xz.distance_to(pad_xz)))
	var deck_top := _deck_top("pad")
	print("walked at the pad's flank from the yard; reached y=%.2f against a deck top of y=%.2f" % [
		peak, deck_top])
	if peak > deck_top - 0.8:
		_fail("the player climbed onto the apparatus pad from the yard; the traversal is not the route")


## The console sets its flag once, kills every lit conduit, and does not come
## back. Pressed through the node's own public entry point rather than through
## the prompt, for the same reason `smoke_warrens.gd` calls
## `grant_clear_reward()` directly: the interaction arbiter is
## `smoke_interactable_sightline.gd`'s subject, and this test is about what
## the switch DOES.
func _the_console_is_one_way(relay: Node3D, progression: RefCounted) -> void:
	var flag: String = str(relay.call("console_flag"))
	if bool(progression.call("has", flag)):
		_fail("the relay was already disabled before the console was touched")
		return
	var lit_before := int(relay.call("lit_conduit_count"))
	if lit_before <= 0:
		_fail("nothing on the site was lit before the console was used; there is no state to change")

	if not bool(relay.call("disable_relay")):
		_fail("using the console did nothing")
		return
	if not bool(progression.call("has", flag)):
		_fail("using the console did not set '%s'" % flag)
	var lit_after := int(relay.call("lit_conduit_count"))
	print("lit surfaces: %d before the console, %d after" % [lit_before, lit_after])
	if lit_after != 0:
		_fail("%d surfaces are still lit after the relay was disabled" % lit_after)

	if bool(relay.call("disable_relay")):
		_fail("the console fired a second time; disabling the relay is supposed to be one-way")
	if not bool(progression.call("has", flag)):
		_fail("the flag did not survive a second press")


## The `requires_flag` gate, in two halves.
##
## SE25 has landed, so the first half is no longer hypothetical: assert the
## SHIPPED config actually names the relay captain. This was the gap — the
## mechanism was tested with an invented flag while `tether_relay.json` left
## `requires_flag` empty, so the console shipped open and a player could shut
## the relay down without ever meeting the captain, in defiance of
## objectives.json's own beat order (captain -> captive -> relay). A test that
## only ever exercises a flag it made up cannot see that.
func _the_console_can_be_gated(relay: Node3D, progression: RefCounted) -> void:
	var flag: String = str(relay.call("console_flag"))
	var config: Dictionary = relay.get("_config")
	var console: Dictionary = (config.get("apparatus", {}) as Dictionary).get("console", {})
	var shipped_gate := str(console.get("requires_flag", ""))
	if shipped_gate != "relay_captain_defeated":
		_fail("the shipped console gates on '%s'; objectives.json orders the captain before the relay, so it must gate on 'relay_captain_defeated'" % shipped_gate)

	progression.call("set_flag", flag, false)
	var restore := shipped_gate
	console["requires_flag"] = "smoke_relay_gate"

	if bool(relay.call("disable_relay")):
		_fail("the console fired with its `requires_flag` unset; SE25's gate would not hold")
	if bool(progression.call("has", flag)):
		_fail("a refused console still set the flag")
	progression.call("set_flag", "smoke_relay_gate")
	if not bool(relay.call("disable_relay")):
		_fail("the console still refused after its `requires_flag` was set")
	print("the requires_flag gate refused while unset and opened once set")

	console["requires_flag"] = restore
	progression.call("set_flag", "smoke_relay_gate", false)


## GATE3_ENCOUNTER_CONTRACTS.md V-5, G3-BAND3-0903. D41: drained ground heals
## when the machinery fails. The relay's own dead-ground skin should start
## fading the moment ITS console goes quiet, not wait for the chapter's
## `legendary_freed` ending (`meadow_healing.gd`'s own generic sweep). By this
## point in the run the relay has already been disabled twice
## (`_the_console_is_one_way`, then again inside `_the_console_can_be_gated`'s
## own `requires_flag` toggle), so `heal()` has already been called at least
## once — this only has to prove the fade actually runs to completion, not
## trigger it a third time.
func _the_local_ground_heals_on_disable(relay: Node3D) -> void:
	if not bool(relay.call("dead_ground_visible")):
		_fail("the relay's dead ground was never visible to begin with; this proves nothing about healing it")
		return
	var config: Dictionary = relay.get("_config")
	var seconds: float = float((config.get("dead_ground", {}) as Dictionary).get("heal_on_disable_seconds", 12.0))
	var frames := int(ceil(seconds * 60.0)) + 60
	for i in frames:
		await physics_frame
	if not bool(relay.call("healed")):
		_fail("the relay's dead ground did not finish healing %.1fs after the console was disabled" % seconds)
	if bool(relay.call("dead_ground_visible")):
		_fail("the relay's dead ground is still visible after it finished healing")
	print("local ground heal: healed=%s dead_ground_visible=%s (%.1fs after disable)" % [
		str(relay.call("healed")), str(relay.call("dead_ground_visible")), seconds])


## D41 at full strength. Two things, both read from the ONE authored source
## (`terrain_playground.json`'s `drains` block, through
## `playground_heightfield.drain_factor()` — the same function the bake and
## `scatter_rules.gd` ask): the ground at the relay is drained, and it is
## drained HARDER than the quarry, which is the whole point of the rung.
func _the_ground_is_drained(relay: Node3D) -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	if not field.has_method("drain_factor"):
		_fail("playground_heightfield.gd has no drain_factor(); SD16's mechanism is gone")
		return
	var pad_local := _deck_local("pad")
	var pad: Vector2 = relay.call("world_of", pad_local if pad_local != Vector2.INF else Vector2.ZERO)
	var at_relay := float(field.call("drain_factor", pad.x, pad.y))
	var at_quarry := float(field.call("drain_factor", 27.0, 162.0))
	var far_off := float(field.call("drain_factor", 0.0, 0.0))
	print("drain: %.2f at the relay pad, %.2f at the quarry head, %.2f at the village square" % [
		at_relay, at_quarry, far_off])
	if at_relay <= 0.0:
		_fail("the ground at the relay is not drained at all; D41's worst station has no damage")
	if at_relay <= at_quarry:
		_fail("the relay's drain (%.2f) is not worse than the quarry's (%.2f); D41 says it is the worst in the chapter"
			% [at_relay, at_quarry])
	if far_off > 0.01:
		_fail("the village square is drained (%.2f); the damage is supposed to be local to the stations" % far_off)

	# The skin that stands in for the un-re-baked colour map. If it is ever
	# turned off after a real bake, this check turns off with it.
	var dead_ground: Dictionary = _config.get("dead_ground", {})
	if bool(dead_ground.get("enabled", false)):
		if relay.get_node_or_null(^"DeadGround") == null:
			_fail("dead_ground is enabled in the config but no DeadGround skin was built")


## --- harness ---------------------------------------------------------------


func _site_centre() -> Vector2:
	var site: Dictionary = _json("res://data/config/relay_site.json").get("site", {})
	var centre: Array = site.get("centre", [])
	if centre.size() < 2:
		# SE25/SE27's file may not have landed in this branch yet; fall back to
		# the relay's own config, which is where the adopted value is copied.
		centre = (_config.get("site", {}) as Dictionary).get("centre", []) as Array
	if centre.size() < 2:
		return Vector2.INF
	return Vector2(float(centre[0]), float(centre[1]))


func _deck_local(id: String) -> Vector2:
	for entry: Variant in _config.get("decks", []):
		var deck: Dictionary = entry as Dictionary
		if str(deck.get("id", "")) != id:
			continue
		var at: Array = deck.get("at", [])
		if at.size() >= 2:
			return Vector2(float(at[0]), float(at[1]))
	return Vector2.INF


func _deck_top(id: String) -> float:
	for entry: Variant in _config.get("decks", []):
		var deck: Dictionary = entry as Dictionary
		if str(deck.get("id", "")) == id:
			return float(deck.get("deck_y", 0.0))
	return 0.0


func _ground_under(relay: Node3D, local: Vector2) -> float:
	var field: RefCounted = HEIGHTFIELD.new()
	var at: Vector2 = relay.call("world_of", local)
	return float(field.call("height_at", at.x, at.y))


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## Borrowed verbatim from smoke_warrens.gd — see its own comments for why the
## controller's `_physics_process` is suspended for the length of a push.
func _put_down(player: CharacterBody3D, at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	for i in 40:
		await physics_frame


## Returns the HIGHEST y the body reached during the push, which is the honest
## question for a ramp: a push long enough to top out is also long enough to
## walk off the far side of the deck it tops out on, and a final-position
## reading would then report the fall instead of the climb.
##
## `frames` is sized per call rather than fixed, because the budget is a
## DISTANCE: at 4 m/s and 60Hz these runs are 12-24m long and a one-size
## budget either stops the long one short (which read as "the gate is not
## open" when the gate was wide open) or runs the short one off a walkway.
func _push(player: CharacterBody3D, direction: Vector3, frames: int = PUSH_FRAMES) -> float:
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	var peak := player.global_position.y
	player.set_physics_process(false)
	for i in frames:
		player.velocity.x = flat.x * 4.0
		player.velocity.z = flat.z * 4.0
		player.velocity.y = 0.0 if player.is_on_floor() else player.velocity.y - 0.5
		player.move_and_slide()
		peak = maxf(peak, player.global_position.y)
		await physics_frame
	player.set_physics_process(true)
	return peak


## Physics frames to walk `metres` at the push speed, with half again for the
## slopes, steps and wall-slides on the way.
func _frames_for(metres: float) -> int:
	return int(ceil(metres / 4.0 * 60.0 * 1.5))
