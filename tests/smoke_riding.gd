extends SceneTree

## `R6.1`/`R6.2`: can the player get on their Meadowhart, go somewhere faster
## than they could run, and get off again in one piece?
##
##   godot --headless --path . --script tests/smoke_riding.gd
##
## Riding is the kind of feature unit tests are structurally blind to. Every
## question worth asking about it is about two nodes agreeing on one transform
## across real physics frames: does the CREATURE move when the stick moves, does
## the camera follow the creature rather than the trainer standing invisibly
## inside it, and — the one that actually costs a playthrough if it is wrong —
## is the player still visible, still solid and still on the ground afterwards.
##
## So this drives the real scene, the real `interact` binding through the real
## interaction arbiter, and the real `Game.inventory`, the same way
## `smoke_creature_control.gd` drives `creature_recall`.
##
## What it pins, in order:
##
##   1. mounting is REFUSED with no saddle, and the prompt says what is missing
##   2. with a saddle, the ordinary interact press mounts
##   3. the stick moves the CREATURE, faster than the trainer's own walk speed
##   4. the camera is following the mount, not the trainer
##   5. the interact press dismounts, and the trainer is visible and grounded
##   6. despawning the mount mid-ride does not strand the player
##   7. mounting is refused while a fight is running

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

## The species under test. Read from the data rather than typed, so R8.5 adding
## a second mount or the owner retiring this one does not leave this file
## quietly testing nothing.
const MOUNT_SPECIES := "meadowhart"

const SETTLE_FRAMES := 300

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _riding: Node = null
var _director: Node = null
var _manager: Node = null
var _arbiter: Node = null
var _party: RefCounted = null
var _bag: RefCounted = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_riding = _world.get_node_or_null(^"RidingController")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_manager = _world.get_node_or_null(^"CombatManager")
	_arbiter = _world.get_node_or_null(^"InteractionArbiter")
	var game := root.get_node_or_null(^"/root/Game")
	if _player == null or _rig == null or _riding == null or _director == null \
			or _manager == null or _arbiter == null or game == null:
		_fail("the scene is missing the player, camera rig, riding controller, director, manager, arbiter or Game")
		_report()
		return
	_party = game.get("party")
	_bag = game.get("inventory")

	if not SPECIES.is_rideable(MOUNT_SPECIES):
		_fail("species.json says '%s' is not rideable; R6.2's whole premise is gone" % MOUNT_SPECIES)
		_report()
		return

	if not await _put_the_mount_in_the_world():
		_report()
		return

	await _refuses_without_a_saddle()
	_bag.call("add", "saddle", 1)
	await _mounts_on_the_interact_press()
	await _the_stick_moves_the_creature()
	await _dismounts_and_gives_the_body_back()
	await _despawning_the_mount_does_not_strand_the_player()
	await _refuses_mid_fight()
	_report()


## Seed the party with a Meadowhart and bring it out, the same way
## `smoke_creature_control.gd` seeds its two: straight into `Game.party`, then
## through the director's real `summon_active_creature()`.
func _put_the_mount_in_the_world() -> bool:
	# Whatever the opening left standing beside the trainer is not the species
	# under test; put it away first so the summon below is unambiguous.
	if _director.call("ally_body") != null:
		_director.call("dismiss_active_creature")
		for i in 20:
			await physics_frame

	var mount: RefCounted = SPECIES.spawn(MOUNT_SPECIES)
	if mount == null or not bool(_party.call("add", mount)):
		_fail("could not put a %s in the party" % MOUNT_SPECIES)
		return false
	for i in int(_party.call("size")):
		if _party.call("at", i) == mount:
			_party.call("set_active", i)
			break
	if _party.call("active") != mount:
		_fail("the party would not make the %s active" % MOUNT_SPECIES)
		return false

	if _director.call("ally_body") == null:
		await _director.call("summon_active_creature")
	for i in 90:
		await physics_frame
		var body: Node3D = _director.call("ally_body")
		if body != null and is_instance_valid(body) and body.visible:
			break
	var body: Node3D = _director.call("ally_body")
	if body == null or not is_instance_valid(body):
		_fail("the %s never appeared in the world; nothing below can be tested" % MOUNT_SPECIES)
		return false
	if str(body.get("species_id")) != MOUNT_SPECIES:
		_fail("the creature standing out is a %s, not the %s under test"
			% [str(body.get("species_id")), MOUNT_SPECIES])
		return false
	print("setup: a %s is out and following" % MOUNT_SPECIES)
	return true


## R6.2's gate. Owning the creature is not owning the tack.
func _refuses_without_a_saddle() -> void:
	if int(_bag.call("count", "saddle")) > 0:
		_bag.call("remove", "saddle", int(_bag.call("count", "saddle")))
	await _stand_beside_the_mount()

	if bool(_riding.call("mount")):
		_fail("mounted with no saddle in the satchel")
		_riding.call("dismount")
		return
	var offer: Dictionary = _riding.call("interaction_offer", _player.global_position)
	if offer.is_empty():
		_fail("standing next to a rideable creature with no saddle offered no line at all")
		return
	if bool(offer.get("actionable", true)):
		_fail("the no-saddle line is actionable; pressing it would do nothing: '%s'" % str(offer.get("label")))
	if not str(offer.get("label", "")).contains("Saddle"):
		_fail("the no-saddle line does not name the saddle: '%s'" % str(offer.get("label")))
	print("no saddle: refused, and the prompt says '%s'" % str(offer.get("label")))


## The button. Not `mount()` — the whole controller-first claim is that riding
## is on the verb the player already has, arbitrated against everything else
## standing nearby.
func _mounts_on_the_interact_press() -> void:
	await _stand_beside_the_mount()
	if _arbiter.call("winning_provider") != _riding:
		_fail("the ride offer is not winning the prompt while standing next to the mount; the line is '%s'"
			% str(_arbiter.call("prompt")))
		return
	await _press("interact")
	for i in 20:
		await physics_frame
	if not bool(_riding.call("is_mounted")):
		_fail("the interact press next to a rideable creature did not mount it")
		return
	if bool(_player.call("rider_visible")):
		_fail("the trainer's own body is still drawn while mounted")
	if _player.call("carrier") != _director.call("ally_body"):
		_fail("the player is mounted but is not being carried by the creature")
	print("mounted: '%s' put the trainer on the %s" % [str(_arbiter.call("prompt")), MOUNT_SPECIES])


## The core of R6.1: the stick drives the CREATURE, and it beats running.
##
## Measured as ground actually covered by the mount, converted back to m/s,
## rather than by reading the multiplier back out of the config file — the bug
## this exists for is the one where the number is right and nothing moves.
##
## Four directions, not one. The Meadows is a real place with trees, rock
## outcrops, fences and a village in it, and a creature that happens to be
## standing with a slope or a wall directly in front of it goes nowhere no
## matter how well riding works — so a single fixed heading would be testing
## the scatter seed rather than the feature. The claim under test is "a mount
## carries the player faster than the player can walk", and one clean run
## proves it; every heading being blocked would be the genuine failure.
func _the_stick_moves_the_creature() -> void:
	if not bool(_riding.call("is_mounted")):
		_fail("not mounted; the ride-speed check cannot run")
		return
	var mount: Node3D = _riding.call("mount_body")
	var expected: float = float(_riding.call("ride_speed"))
	var walk := _walk_speed()
	if expected <= walk:
		_fail("the configured ride speed (%.2f m/s) does not beat walking (%.2f m/s)" % [expected, walk])

	# Onto open ground first. The ride starts wherever the opening left the
	# trainer — in the yard, between the house, the fence and the rise — and a
	# mount wedged against a wall is a fair thing for the GAME to do and a
	# useless thing to measure a top speed against. `place_on_ground` is the
	# creature's own relocation call (D09: ask the world, do not raycast), and
	# the rider comes along because the rider is parented to the answer.
	mount.call("place_on_ground", Vector3(0.0, 0.0, 0.0))
	for i in 30:
		await physics_frame

	var frames := 90
	var seconds := float(frames) / float(Engine.physics_ticks_per_second)
	var best_peak := 0.0
	var best_travel := 0.0
	var best_action := ""
	var player_kept_up := false
	for action in ["move_forward", "move_back", "move_left", "move_right"]:
		var start: Vector3 = mount.global_position
		var player_start: Vector3 = _player.global_position
		var peak := 0.0
		Input.action_press(action)
		for i in frames:
			await physics_frame
			peak = maxf(peak, Vector3(mount.velocity.x, 0.0, mount.velocity.z).length())
		Input.action_release(action)
		for i in 20:
			await physics_frame

		var travelled := Vector3(mount.global_position.x - start.x, 0.0,
			mount.global_position.z - start.z).length()
		print("  %s: %.1f m in %.1fs (peak %.2f m/s)" % [action, travelled, seconds, peak])
		if peak > best_peak:
			best_peak = peak
			best_travel = travelled
			best_action = action
			# The trainer went WITH it. This is the invisible-body-left-behind
			# bug, checked on the run that actually covered ground.
			player_kept_up = _player.global_position.distance_to(player_start) >= travelled * 0.5
		if peak > walk and travelled > walk * seconds * 0.5:
			break

	# Peak speed is the claim, not average displacement. Ground covered over a
	# fixed window is the product of the ride speed AND the meadow: a run that
	# climbs the rise, brushes a tree or crosses a fence line covers less
	# distance at exactly the same speed, and none of that is riding being
	# broken. The average is printed either way, and a run with a real peak and
	# no displacement at all is caught by the second assertion below.
	if best_peak <= walk:
		_fail("the mount never got above %.2f m/s on the stick, in any direction; walking is %.2f m/s"
			% [best_peak, walk])
		return
	if best_travel < walk * seconds * 0.5:
		_fail("the mount hit %.2f m/s but only covered %.1f m in %.1fs; it is not actually going anywhere"
			% [best_peak, best_travel, seconds])
		return
	print("moved: %.2f m/s peak on %s, %.1f m covered in %.1fs, against a %.2f m/s walk and a configured %.2f m/s ride"
		% [best_peak, best_action, best_travel, seconds, walk, expected])
	if not player_kept_up:
		_fail("the mount travelled %.1f m and the trainer did not go with it" % best_travel)
	var gap := _player.global_position.distance_to(mount.global_position)
	if gap > 3.0:
		_fail("the player is %.1f m from the mount they are supposed to be sitting on" % gap)

	# And the camera is looking at the mount rather than at where the trainer
	# would have been standing.
	var to_mount := _rig.global_position.distance_to(mount.global_position)
	if to_mount > 12.0:
		_fail("the camera rig is %.1f m from the mount; it is not following it" % to_mount)
	else:
		print("camera: rig is %.1f m from the mount, following it" % to_mount)


## Getting off has to give back everything getting on took: control, the body,
## the collider and the camera.
func _dismounts_and_gives_the_body_back() -> void:
	if not bool(_riding.call("is_mounted")):
		_fail("not mounted; the dismount check cannot run")
		return
	await _press("interact")
	for i in 60:
		await physics_frame
	await _assert_the_player_is_back("dismount")
	print("dismounted: the trainer is visible, solid and standing on the ground")


## The guard rail that costs a save file if it is missing: the mount is freed
## while the player is on it (a dismiss press, a fight tearing it down, a scene
## change). The player must not be left invisible, collisionless and pinned to a
## node that no longer exists.
func _despawning_the_mount_does_not_strand_the_player() -> void:
	await _stand_beside_the_mount()
	if not bool(_riding.call("mount")):
		_fail("could not remount for the despawn check")
		return
	for i in 10:
		await physics_frame
	if not bool(_director.call("dismiss_active_creature")):
		_fail("could not dismiss the mount out from under the rider")
		return
	for i in 90:
		await physics_frame
	if bool(_riding.call("is_mounted")):
		_fail("the riding controller still thinks it is mounted on a freed body")
	await _assert_the_player_is_back("despawn")
	print("despawn: the mount was freed mid-ride and the trainer landed on their feet")


## Mounting is not a move you make in a fight. The combat manager drives the
## same body for the length of one, and `creature_body.request_move` only has
## room for one driver — the same rule `dismiss_active_creature` already keeps.
func _refuses_mid_fight() -> void:
	if _director.call("ally_body") == null:
		await _director.call("summon_active_creature")
		for i in 90:
			await physics_frame
	var wild: Node3D = _director.call("wild_creature")
	if wild == null:
		_fail("no wild creature in the world; the mid-fight refusal cannot be tested")
		return

	var spot := wild.global_position - wild.global_basis.z * 2.5
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", atan2(-(wild.global_position.x - spot.x), -(wild.global_position.z - spot.z)))
	for i in 30:
		await physics_frame
	await _press("interact")
	for i in 60:
		await physics_frame
	if not bool(_manager.call("is_fighting")):
		_fail("could not enter combat; the mid-fight refusal could not be tested")
		return
	if bool(_riding.call("mount")):
		_fail("mounted in the middle of a fight")
		_riding.call("dismount")
		return
	var offer: Dictionary = _riding.call("interaction_offer", _player.global_position)
	if not offer.is_empty():
		_fail("the ride prompt is still offering mid-fight: '%s'" % str(offer.get("label")))
	print("mid-fight: mounting correctly refused")


## --- helpers ----------------------------------------------------------------

## Everything "the player is a normal player again" means, in one place, so the
## dismount path and the despawn path are held to the same standard.
func _assert_the_player_is_back(context: String) -> void:
	if bool(_riding.call("is_mounted")):
		_fail("%s: still mounted" % context)
	if _player.call("carrier") != null:
		_fail("%s: the player is still being carried by something" % context)
	if not bool(_player.call("rider_visible")):
		_fail("%s: the trainer's body was never made visible again" % context)
	if not _player.visible:
		_fail("%s: the player node itself is hidden" % context)
	if _player.collision_layer == 0:
		_fail("%s: the player has no collision layer; they would walk through the world" % context)

	# Grounded. Given a few frames of gravity, a player who is standing on
	# something reports it; one dropped inside terrain or into the sky does not.
	var grounded := false
	for i in 120:
		await physics_frame
		if _player.is_on_floor():
			grounded = true
			break
	if not grounded:
		_fail("%s: the player never reached the ground (y=%.1f)" % [context, _player.global_position.y])

	# And they can walk. A player left with locomotion disabled is stuck in a
	# different, quieter way.
	if _player.has_method("locomotion_enabled") and not bool(_player.call("locomotion_enabled")):
		_fail("%s: locomotion is still disabled" % context)


## Teleport beside the mount rather than walk to it — `smoke_catching.gd`'s own
## reason: by this point in the run the trainer could be anywhere the previous
## step left them, and the terrain query keeps this on the ground.
func _stand_beside_the_mount() -> void:
	var body: Node3D = _director.call("ally_body")
	if body == null or not is_instance_valid(body):
		return
	var spot := body.global_position + body.global_basis.x * 1.3
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 0.5
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame


func _walk_speed() -> float:
	var file := FileAccess.open("res://data/config/movement.json", FileAccess.READ)
	if file == null:
		return 5.0
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return 5.0
	return float(((parsed as Dictionary).get("locomotion", {}) as Dictionary).get("walk_speed", 5.0))


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("riding: OK — saddled, mounted, ridden, dismounted, and refused when it had to be.")
		quit(0)
		return
	for line in _failures:
		print("riding FAIL: %s" % line)
	quit(1)
