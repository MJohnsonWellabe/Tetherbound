extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 5 lane 5.A. THE acceptance bar for the whole lane, and it is a
## PLAYER EXPERIENCE rather than a data-model claim (directive rule 3):
##
##   **a character who has not done the opening can join a world where the boss
##   is already dead, and act immediately** -- no soft-lock, no invisible gate.
##
##   godot --headless --path . --script tests/smoke_net_behind_character_joins_ahead_world.gd
##
## or, with isolation, orphan-kill and a run-directory artifact:
##
##   tools/net/run_net_smoke.sh net_behind_character_joins_ahead_world
##
## ## The shape of the run
##
## Both peers boot fresh, so peer 1 is genuinely behind: no opening beats, no
## creature, standing in Grandpa's farmhouse where the front door is a solid box
## until `walk_out` and the screen is fading in from black. The host then sets
## `defeated_warden` -- a WORLD flag (D99), the chapter's boss -- and peer 1
## joins that world.
##
## What is then asserted about peer 1, and every one of them is a way the old
## code locked them out:
##
##   1. Their WORLD says the boss is dead. Without this nothing below means
##      anything: it would be asserting about a peer that never got the
##      snapshot.
##   2. They still do NOT personally hold the opening beats. This is the half
##      that would be wrong if the fix were "make the flags world-scoped": the
##      main story advanced once for the world, and this character's own
##      tutorial history is still their own (D99).
##   3. Their sequence director agrees the world has moved on.
##   4. Their locomotion is enabled and their input context is `world` -- not a
##      fade, not a modal panel. This is "act immediately", literally.
##   5. They have a creature. A trainer with nothing at their heel cannot act at
##      all, whatever the gates say, and the opening is what suspends the
##      sandbox starter.
##   6. They can actually WALK -- the stick moves their body. A locomotion flag
##      that reads true over a body pinned to a bed pose would pass (4) and fail
##      the player.
##
## And about the HOST, throughout: it did not have peer 1's personal beats
## granted to it, and it is not frozen. One player's story position is not the
## other's, and one player being behind is not a thing that happens TO anybody.
##
## ## Debug order if it fails
##
## Did the boss flag commit on the host (step detail), does the joiner's world
## read it (if not, the snapshot or the delta did not arrive), does the joiner's
## `world_moved_on` read true (if not, `WORLD_MOVED_ON_FLAGS` and the flag
## disagree, or the director is reading the merged view instead of the world),
## and only then the locomotion/context/party/walk assertions -- those four are
## the catch-up itself, and they fail in the order the catch-up runs.

## The boss. `defeated_warden` is `world` in `data/progression/flag_scopes.json`
## and is in `sequence_director.gd::WORLD_MOVED_ON_FLAGS`; both are pinned by
## `tests/test_story_world_catchup.gd` so this smoke can name the id plainly.
const BOSS_FLAG := "defeated_warden"
## An opening beat the joiner must NOT be handed. `opening:` is a `player`
## prefix (D99): the world moving on does not rewrite whose tutorial it was.
const OPENING_BEAT_FLAG := "opening:beat:house"
## Frames for the catch-up to run once the world says the boss is dead: it
## clears the fade, carries the beat, opens the door and adopts a companion,
## and `adopt_starter()` waits on Terrain3D's collision the way every spawn in
## this game does.
const CATCH_UP_FRAMES := 240
## How far the joiner has to move to have "acted". Deliberately small and for a
## measured reason: `smoke_net_movement_two_peers.gd` records that a fresh boot
## walks 2.71 m before it meets a wall, and its own bar is 2.0 m for exactly
## that reason. A player who cannot move at all -- the soft-lock this smoke is
## about -- reports 0.00 m and fails this by the whole margin.
const WALK_M := 1.0
const WALK_FRAMES := 240


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")

	# --- the handshake, copied verbatim from smoke_net_movement_two_peers.gd ---
	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session,
		"a Session exists to host/join (lane 2.A); without it nobody can join anybody's world")
	if not have_session:
		quit(await finish())
		return

	var hosted: Dictionary = await step(0, "host", {})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))

	# The world is ahead BEFORE anybody joins it. Committed through the ledger,
	# which is the same path `encounter_director.gd` takes when the Warden
	# actually falls -- not a poke into a flag store.
	var boss: Dictionary = await step(0, "story_flag", {"flag": BOSS_FLAG, "scope": "world"})
	check(str(boss.get("verdict", "")) == "PASS",
		"the host's world records that the Warden is dead (%s)" % str(boss.get("detail", "")))

	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(str(joined.get("verdict", "")) == "PASS",
		"a character with no opening progress joined a world whose boss is dead (%s)"
			% str(joined.get("detail", "")))
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry holds both players (%s)" % [i, str(seen.get("detail", ""))])
	# --- end of the copied handshake ------------------------------------------

	await step(1, "wait", {"frames": CATCH_UP_FRAMES})

	var joiner = await _story(1)
	check(joiner is Dictionary, "the joiner answered the story probe")
	if not joiner is Dictionary:
		quit(await finish())
		return
	var row: Dictionary = joiner

	# 1. The world crossed.
	check(_flag(row, "world", BOSS_FLAG) == true,
		"the joiner's WORLD says the Warden is dead")

	# 2. And their own history did not. This is the assertion that fails if
	#    somebody "fixes" rule 3 by making opening beats world-scoped.
	check(_flag(row, "player", OPENING_BEAT_FLAG) == false,
		"the joiner did NOT inherit somebody else's tutorial (%s is still theirs to have or not)"
			% OPENING_BEAT_FLAG)

	# 3. The director agrees.
	check(row.has("world_moved_on") and bool(row["world_moved_on"]),
		"the joiner's sequence director reads the world as moved on")

	# 4. Nothing is holding the screen or the body.
	check(str(row.get("context", "")) == "world",
		"the joiner is in the world, not behind a fade or a modal panel (context '%s')"
			% str(row.get("context", "")))
	check(row.has("locomotion") and bool(row["locomotion"]),
		"the joiner's own locomotion is enabled")

	# 5. They have something to act WITH.
	check(row.has("party"), "the story probe reports a party size")
	check(int(row.get("party", 0)) > 0,
		"the joiner has a creature (a trainer with nothing at their heel cannot act at all)")

	# 6. And they can actually move.
	var before = await probe(1, "position")
	var walk: Dictionary = await step(1, "stick", {"x": 0.0, "y": -1.0, "frames": WALK_FRAMES})
	check(str(walk.get("verdict", "")) == "PASS",
		"the joiner held the stick forward (%s)" % str(walk.get("detail", "")))
	var after = await probe(1, "position")
	var moved := _planar(before, after)
	check(moved >= WALK_M,
		"the joiner actually walked (%.2f m, wanted at least %.2f m)" % [moved, WALK_M])

	# The host, all the while: not given the joiner's beats, and not frozen.
	var host = await _story(0)
	check(host is Dictionary, "the host answered the story probe")
	if host is Dictionary:
		var host_row: Dictionary = host
		check(_flag(host_row, "player", OPENING_BEAT_FLAG) == false,
			"the host was not handed the joiner's personal tutorial beat either")
		check(host_row.has("locomotion") and bool(host_row["locomotion"]),
			"the host is not frozen by somebody else arriving behind")
		check(_flag(host_row, "world", BOSS_FLAG) == true,
			"and the host's world still says what it said")

	quit(await finish())


func _story(peer: int) -> Variant:
	return await probe(peer, "story", {
		"world_flags": [BOSS_FLAG],
		"player_flags": [OPENING_BEAT_FLAG],
	})


## `null` rather than `false` for a key the probe did not report, so "the peer
## never answered" cannot be read as "the peer answered no". `has()` before
## `get()` on purpose: a missing key would otherwise make this return `false`
## and quietly satisfy a negative assertion it never actually tested.
func _flag(row: Dictionary, store: String, flag: String) -> Variant:
	if not row.has(store):
		return null
	var block: Variant = row[store]
	if not block is Dictionary or not (block as Dictionary).has(flag):
		return null
	return bool((block as Dictionary)[flag])


## Planar distance between two `[x, y, z]` probe answers, ignoring height: the
## question is whether they walked, and a body settling onto the ground is not
## walking.
func _planar(a: Variant, b: Variant) -> float:
	if not a is Array or not b is Array or (a as Array).size() < 3 or (b as Array).size() < 3:
		return -1.0
	return Vector2(float(a[0]) - float(b[0]), float(a[2]) - float(b[2])).length()
