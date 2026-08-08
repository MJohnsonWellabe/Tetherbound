extends SceneTree

## Close the game, open it again, and find your world where you left it.
##
##   godot --headless --path . --script tests/smoke_persistence.gd
##
## Headless, like every other smoke — `tools/run_smokes.sh` has the measured
## reason.
##
## WHAT THIS IS NOT: another round-trip test. `tests/test_save_manager.gd`
## already proves the envelope, and `tests/smoke_build.gd` already proves that
## structures survive a save and a reload. Both of those pass by CALLING `save()`
## and `load_slot()` themselves, and both passed for two milestones while the
## shipping game called neither. A player who built a house and closed the window
## lost the house, and nothing in the suite could tell.
##
## So nothing below calls `SaveManager.save()` or `SaveManager.load_slot()`. The
## save has to be written by the game's own lifecycle — the autosave that fires
## when a piece is placed, and the write that happens on the window close request
## — and the load has to be the one `SaveDirector` does at boot, with no help.
## The world is then TORN DOWN and a completely fresh one is built from the same
## scene, which is as close to a second launch as one process can get.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const SAVE_PATH := "user://save_0.json"

## Long enough for Terrain3D to publish its collision and for the encounter
## director to have spawned the wild pals and granted the starter — the other
## smokes use 240–300 for the same reason.
const SETTLE_FRAMES := 300
## Frames to let the first world actually go away before the second is built.
const TEARDOWN_FRAMES := 30

## The pal the "player" acquires in the first session, and the name that has to
## come back in the second. A nickname because it is the one field no default can
## accidentally reproduce: a species and a level could both be right by luck.
const KEPT_SPECIES := "wild_rabbit"
const KEPT_NICKNAME := "Thimble"

## A stronghold's worth of pieces, laid down so the save being timed is not a
## two-line file. Autosave runs on the main thread; if a real save costs a frame
## the player feels it as a hitch every time they place a wall, and "it seemed
## fast with one door in it" is not a measurement.
const STRONGHOLD_PIECES := 60
## Half a frame at 60fps. Not a design number — a ceiling loose enough not to
## flap on a loaded machine and tight enough that a save which started costing a
## whole frame would trip it.
const WRITE_BUDGET_USEC := 8000

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	# Start from nothing. A leftover save from another smoke would make an empty
	# first session look like a restored one.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	var expected: Dictionary = await _first_session()
	if expected.is_empty():
		_report()
		return
	await _second_session(expected)
	_report()


## --- session one: play, then close the window ------------------------------

func _first_session() -> Dictionary:
	print("--- session 1 ---")
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for _i in SETTLE_FRAMES:
		await physics_frame

	var director: Node = world.get_node_or_null(^"SaveDirector")
	var structures: Node3D = world.get_node_or_null(^"Structures") as Node3D
	var build: Node = world.get_node_or_null(^"BuildMode")
	var party: Node = world.get_node_or_null(^"Party")
	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if director == null or structures == null or build == null or party == null or player == null:
		_fail("the scene is missing SaveDirector, Structures, BuildMode, Party or Player")
		return {}

	# A first run must be a new game, in silence.
	if not bool(director.call("is_booted")):
		_fail("SaveDirector never finished booting; nothing below it can work")
		return {}
	if bool(director.call("restored_at_boot")):
		_fail("a first run with no save file claimed to have restored one")
	if FileAccess.file_exists(SAVE_PATH):
		_fail("booting a fresh world wrote a save file before the player did anything")

	# --- the player acquires a pal ------------------------------------------
	# Through `party.add()`, which is the same call the catch path makes. Running
	# a real fight to get there is smoke_catching's job; what is under test here
	# is whether the pal is still there tomorrow.
	var kept: RefCounted = SPECIES.spawn(KEPT_SPECIES)
	if kept == null:
		_fail("species '%s' is missing from species.json" % KEPT_SPECIES)
		return {}
	kept.nickname = KEPT_NICKNAME
	kept.hp = maxf(1.0, kept.max_hp * 0.5)
	if not bool(party.call("add", kept)):
		_fail("could not add a pal to the party: %s" % party.call("last_refusal"))
		return {}
	var party_size: int = int(party.call("size"))
	print("party after catching: %d" % party_size)

	# --- the player has been gathering --------------------------------------
	# Building COSTS materials now, and a new trainer starts with an axe, a pickaxe
	# and nothing to build with — so a smoke that walked straight into build mode
	# would be refused for entirely the right reason and fail for the wrong one.
	# Through `TrainerInventory.add()`, which is the same call gathering makes.
	var bag: Node = world.get_node_or_null(^"TrainerInventory")
	if bag == null:
		_fail("the scene is missing TrainerInventory; building cannot be paid for")
		return {}
	for material: String in ["wood", "stone", "fiber"]:
		bag.call("add", material, 90)

	# --- the player builds something ----------------------------------------
	# Driven through the real input actions and the real BuildMode, because the
	# point is that BUILDING triggers a save. `structures.place()` called directly
	# would place a piece and never emit `placed`, which is exactly the sort of
	# side door that made the save system look connected when it was not.
	var writes_before: int = int(director.call("writes"))
	var placed: int = await _build_through_the_real_input(build, structures)
	if placed == 0:
		_fail("could not place anything through build mode; the autosave event was never exercised")
		return {}
	print("placed %d piece(s) through build mode" % placed)

	# The event autosave. Nobody called save(); placing did.
	for _i in 30:
		await physics_frame
	if int(director.call("writes")) <= writes_before:
		_fail("placing a structure did not trigger an autosave")
	if not FileAccess.file_exists(SAVE_PATH):
		_fail("no save file after placing a structure; the autosave did not reach the disk")
	else:
		print("autosave after building: reason '%s', %d us" % [
			director.call("last_reason"), director.call("last_write_usec")
		])

	# --- and keeps building -------------------------------------------------
	# Laid down directly rather than through the input layer: what these are for
	# is WEIGHT, so the save being timed below is a stronghold rather than a
	# single door. Every one of them still has to come back in session two.
	var origin: Vector3 = player.global_position
	var bulk := 0
	for i in STRONGHOLD_PIECES:
		var at := Vector3(origin.x + 12.0 + float(i % 10) * 4.0, 0.0, origin.z + 12.0 + float(i / 10) * 4.0)
		at.y = float(world.call("ground_height_at", at.x, at.z))
		if is_nan(at.y):
			continue
		if structures.call("place", "floor_wooddark", at, 0.0) != null:
			bulk += 1
	print("stronghold: %d pieces total" % structures.call("count"))
	if bulk < STRONGHOLD_PIECES / 2:
		_fail("only %d of %d bulk pieces placed; the write below is not being timed against a real save" % [
			bulk, STRONGHOLD_PIECES
		])

	# --- the player closes the window ---------------------------------------
	# `propagate_notification` is precisely what the engine does with a window
	# close request before it acts on `auto_accept_quit`.
	var writes_before_quit: int = int(director.call("writes"))
	world.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	if int(director.call("writes")) != writes_before_quit + 1:
		_fail("closing the window did not write a save")
	if str(director.call("last_reason")) != "quit":
		_fail("the close request saved for the wrong reason: '%s'" % director.call("last_reason"))
	var quit_usec: int = int(director.call("last_write_usec"))
	print("quit save: %d pieces + %d pals in %d us (budget %d)" % [
		structures.call("count"), party.call("size"), quit_usec, WRITE_BUDGET_USEC
	])
	if quit_usec > WRITE_BUDGET_USEC:
		# Autosave runs on the main thread. A save that costs a frame is a hitch
		# every time the player places a wall, which is the moment they are least
		# willing to forgive one.
		_fail("a %d-piece save took %d us, over the %d us budget; autosave will visibly hitch" % [
			structures.call("count"), quit_usec, WRITE_BUDGET_USEC
		])

	var expected := {
		"party_size": party_size,
		"structures": structures.call("records"),
		"nickname": KEPT_NICKNAME,
		"hp": float(kept.hp),
	}

	# --- the process goes away ----------------------------------------------
	root.remove_child(world)
	world.queue_free()
	for _i in TEARDOWN_FRAMES:
		await physics_frame
	print("session 1 torn down")
	return expected


## Open build mode, aim, and press the place button, all through the input map.
##
## Returns how many pieces landed. Retries with a rotation and a step forward
## because the ghost refuses uneven ground, and where the player happens to be
## standing is terrain data rather than anything this test controls.
func _build_through_the_real_input(build: Node, structures: Node3D) -> int:
	var before: int = int(structures.call("count"))

	await _tap("build_toggle")
	for _i in 4:
		await physics_frame
	if not bool(build.call("is_open")):
		_fail("build_toggle did not open build mode")
		return 0

	for attempt in 6:
		if bool(build.call("ghost_valid")):
			await _tap("combat_quick")
			for _i in 4:
				await physics_frame
			if int(structures.call("count")) > before:
				break
		else:
			print("ghost refused (%s); rotating and stepping" % build.call("refusal"))
			await _tap("build_rotate")
			# Locomotion is suspended in build mode, so nudge the trainer directly
			# rather than pretending a movement input would do anything.
			var player: CharacterBody3D = build.get_node_or_null(build.get("player_path")) as CharacterBody3D
			if player != null:
				player.global_position += Vector3(2.5, 0.0, 2.5)
			for _i in 6:
				await physics_frame

	await _tap("build_toggle")
	for _i in 4:
		await physics_frame
	return int(structures.call("count")) - before


func _tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await physics_frame


## --- session two: launch again, change nothing, look --------------------------

func _second_session(expected: Dictionary) -> void:
	print("--- session 2 ---")
	if not FileAccess.file_exists(SAVE_PATH):
		_fail("there is no save file to launch into")
		return

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for _i in SETTLE_FRAMES:
		await physics_frame

	var director: Node = world.get_node_or_null(^"SaveDirector")
	var structures: Node3D = world.get_node_or_null(^"Structures") as Node3D
	var party: Node = world.get_node_or_null(^"Party")
	if director == null or structures == null or party == null:
		_fail("the second world is missing SaveDirector, Structures or Party")
		return

	if not bool(director.call("restored_at_boot")):
		_fail("the second launch did not restore the save; the player's world is gone")
		return
	print("restored at boot")

	# --- the stronghold -----------------------------------------------------
	var was: Array = expected["structures"]
	var now: Array = structures.call("records")
	if now.size() != was.size():
		_fail("built %d pieces and %d came back" % [was.size(), now.size()])
	for i in mini(was.size(), now.size()):
		var before: Dictionary = was[i]
		var after: Dictionary = now[i]
		for key: String in ["piece", "x", "y", "z", "yaw_deg"]:
			var same: bool = (str(before[key]) == str(after[key])) if key == "piece" \
				else is_equal_approx(float(before[key]), float(after[key]))
			if not same:
				_fail("piece %d came back with a different '%s': %s -> %s" % [
					i, key, before[key], after[key]
				])

	# --- the party ----------------------------------------------------------
	if int(party.call("size")) != int(expected["party_size"]):
		_fail("the party had %d pals and %d came back" % [expected["party_size"], party.call("size")])
	var names: Array[String] = []
	var found: RefCounted = null
	for member: Variant in party.call("members"):
		names.append(str((member as RefCounted).nickname))
		if str((member as RefCounted).nickname) == KEPT_NICKNAME:
			found = member
	print("party after relaunch: %s" % [names])
	if found == null:
		_fail("the pal named '%s' did not come back" % KEPT_NICKNAME)
	elif not is_equal_approx(float(found.hp), float(expected["hp"])):
		# A pal that comes back at full health has been re-spawned from its
		# species rather than restored, which reads as working until the player
		# notices the game healed their party overnight.
		_fail("'%s' came back on %.1f HP, not the %.1f it was left on" % [
			KEPT_NICKNAME, found.hp, expected["hp"]
		])

	# The returning player must not be handed a starter pal on top of the party
	# they already have.
	if int(party.call("size")) > int(expected["party_size"]):
		_fail("the second launch granted a starter pal on top of a restored party")


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("persistence: OK — a session's party and buildings are written by the " +
			"game's own autosave and quit path, and are still there after a relaunch.")
		quit(0)
	else:
		for line in _failures:
			print("persistence FAIL: %s" % line)
		quit(1)
