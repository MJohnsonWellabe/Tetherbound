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
##   3. the RIDER is on the creature: visible, seated, and at the right height
##   4. the stick moves the CREATURE, faster than the trainer's own walk speed
##   5. the sprint button makes the mount run, and it beats a sprinting trainer
##   6. the jump button makes the mount leave the ground, and the rider goes up
##      with it and is still seated when it lands
##   7. the camera is following the mount, not the trainer
##   8. the interact press dismounts, and the trainer is visible and grounded
##   9. despawning the mount mid-ride does not strand the player
##  10. mounting is refused while a fight is running
##
## 3, 5 and 6 are OP-0904-3, the owner's own three riding items from the shipped
## build; the saddle rule that is his third is `tests/smoke_riding_saddle.gd`,
## which needs to stand a body of every rideable species up and does not belong
## in the middle of one continuous ride.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

## The species under test. Read from the data rather than typed, so R8.5 adding
## a second mount or the owner retiring this one does not leave this file
## quietly testing nothing.
const MOUNT_SPECIES := "meadowhart"

const SETTLE_FRAMES := 300

## The height of the low fences and rocks a walking trainer already gets over
## (`player_controller._try_step_up()`'s ledge probe plus the meadow's own low
## fence props). The bar the brief sets for a mounted hop: "a real hop that
## clears the low fences/rocks a walking player can vault".
const LOW_OBSTACLE_M := 0.6

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
	await _the_rider_is_on_the_creature()
	await _the_stick_moves_the_creature()
	await _the_mount_sprints()
	await _the_mount_jumps()
	await _dismounts_and_gives_the_body_back()
	await _despawning_the_mount_does_not_strand_the_player()
	# R8.5 before the mid-fight check on purpose: that check deliberately leaves
	# a fight RUNNING when it returns, and the director will not swap the active
	# creature out from under a live battle.
	await _the_legendarys_tier_is_above_it()
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


## R8.5 — the tier above Meadowhart, on the SAME system.
##
## Three claims, and the two that matter are not numbers. FASTER is checked
## against the live controller's own `ride_speed()` rather than against
## species.json. NEEDS NO TACK: the legendary's `requires_item` is empty, so it
## is mounted with an empty bag — checked by emptying the bag first, because
## "it carries you because it offered to" is only true if the game agrees when
## the saddle is gone. AND HOLDS GROUND NOTHING ELSE DOES:
## `climb_max_slope_deg` becomes the body's own `floor_max_angle` while ridden,
## asserted against the LIVE baseline the creature scene sets (55 degrees for
## every creature in the roster, 45 for the trainer) rather than against a
## number typed here — the first version of this test measured against 45,
## passed, and was proving nothing, because every creature already walks 55.
##
## And the ceiling: the mount must NOT be able to climb out of a severed
## spoke's carve, whose walls are 65-66 degrees. That is the carve-out D23 and
## CLAUDE.md hold over the whole chapter, and it is a data check here as well
## as a walking probe in tests/smoke_boss.gd, because the number is what would
## silently drift.
const LEGENDARY_SPECIES := "veridian"
## The shallowest wall on any severed spoke (storm_road: 11m over a 5m rim).
## Measured from terrain_playground.json rather than assumed.
const SHALLOWEST_SPOKE_WALL_DEG := 65.0

func _the_legendarys_tier_is_above_it() -> void:
	var legendary := SPECIES.rideable(LEGENDARY_SPECIES)
	if legendary.is_empty() or not SPECIES.is_rideable(LEGENDARY_SPECIES):
		_fail("species.json gives '%s' no rideable block; R8.5 has no mount" % LEGENDARY_SPECIES)
		return
	var mount_tier := float(SPECIES.rideable(MOUNT_SPECIES).get("ride_speed_multiplier", 0.0))
	var legendary_tier := float(legendary.get("ride_speed_multiplier", 0.0))
	if legendary_tier <= mount_tier:
		_fail("the legendary rides at x%.2f against %s's x%.2f; R8.5 asks for the tier ABOVE it"
			% [legendary_tier, MOUNT_SPECIES, mount_tier])
	if str(legendary.get("requires_item", "x")) != "":
		_fail("the legendary wants '%s' to be ridden; R8.5's tack-free mount is the advantage that is not a number"
			% str(legendary.get("requires_item", "")))
	if str(SPECIES.rideable(MOUNT_SPECIES).get("requires_item", "")) == "":
		_fail("%s stopped needing a saddle too; the legendary's advantage is meant to be its own" % MOUNT_SPECIES)
	var climb := float(legendary.get("climb_max_slope_deg", 0.0))
	if climb >= SHALLOWEST_SPOKE_WALL_DEG:
		_fail("the legendary can climb %.0f degrees and the shallowest severed-spoke wall is %.0f; the mount would open the Meadows"
			% [climb, SHALLOWEST_SPOKE_WALL_DEG])
	if float(SPECIES.rideable(MOUNT_SPECIES).get("climb_max_slope_deg", 0.0)) > 0.0:
		_fail("%s claims a climb limit too; the advantage is meant to be the legendary's alone" % MOUNT_SPECIES)

	# Live half: swap the party's active creature for the legendary, ride it,
	# and read the limit off the body the physics actually uses.
	var legendary_instance: RefCounted = SPECIES.spawn(LEGENDARY_SPECIES)
	if legendary_instance == null or not bool(_party.call("add", legendary_instance)):
		print("note: the party is full, so the legendary's live ride could not be driven here")
		return
	for i in int(_party.call("size")):
		if _party.call("at", i) == legendary_instance:
			_party.call("set_active", i)
			break
	if _director.call("ally_body") != null:
		_director.call("dismiss_active_creature")
		for i in 20:
			await physics_frame
	await _director.call("summon_active_creature")
	for i in 90:
		await physics_frame
		var out: Node3D = _director.call("ally_body")
		if out != null and is_instance_valid(out) and out.visible:
			break
	var body: Node3D = _director.call("ally_body")
	if body == null or not is_instance_valid(body) or str(body.get("species_id")) != LEGENDARY_SPECIES:
		_fail("the legendary never stood up in the world; its ride cannot be driven")
		return
	var walking_limit := rad_to_deg((body as CharacterBody3D).floor_max_angle)
	if climb <= walking_limit:
		_fail("the legendary's climb limit is %.0f degrees and every creature already walks %.0f; that is not an advantage"
			% [climb, walking_limit])
	# Empty the bag: the legendary needs no tack, and this is where that stops
	# being a data claim.
	var saddles := int(_bag.call("count", "saddle"))
	if saddles > 0:
		_bag.call("remove", "saddle", saddles)
	_player.global_position = body.global_position + Vector3(1.2, 0.4, 0.0)
	for i in 20:
		await physics_frame
	if not bool(_riding.call("mount")):
		_fail("the legendary refused to be mounted with an empty bag; it needs no tack")
		_bag.call("add", "saddle", maxi(saddles, 1))
		return
	for i in 10:
		await physics_frame
	var ridden_limit := float(_riding.call("ride_climb_limit_deg"))
	var ride_speed := float(_riding.call("ride_speed"))
	if ridden_limit <= walking_limit + 0.5:
		_fail("mounted, the legendary still treats %.0f degrees as floor; the climb advantage never reaches the body" % ridden_limit)
	if ride_speed <= _walk_speed():
		_fail("the legendary's live ride speed is %.2f m/s against a %.2f m/s walk" % [ride_speed, _walk_speed()])
	print("legendary: x%.2f (%.2f m/s live), no tack, %.0f-degree ground -- against %s's x%.2f, a saddle, and the roster's %.0f degrees"
		% [legendary_tier, ride_speed, ridden_limit, MOUNT_SPECIES, mount_tier, walking_limit])
	if not bool(_riding.call("dismount")):
		_fail("could not get off the legendary")
		return
	for i in 20:
		await physics_frame
	if is_instance_valid(body):
		var after := rad_to_deg((body as CharacterBody3D).floor_max_angle)
		if absf(after - walking_limit) > 0.5:
			_fail("after dismounting, the legendary's body still holds %.0f degrees (was %.0f); the perk leaked out of the ride"
				% [after, walking_limit])
		else:
			print("the climb advantage ended with the ride: back to %.0f degrees on foot" % after)
	if saddles > 0:
		_bag.call("add", "saddle", saddles)


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
	# OP-0904-3, and the assertion this line used to make was the exact
	# opposite: it PINNED the trainer's art being hidden while mounted, which
	# is the defect the owner reported. `_the_rider_is_on_the_creature()` below
	# takes the claim apart properly.
	if not bool(_player.call("rider_visible")):
		_fail("the trainer's own body is not drawn while mounted; the rider is invisible on the creature")
	if _player.call("carrier") != _director.call("ally_body"):
		_fail("the player is mounted but is not being carried by the creature")
	print("mounted: '%s' put the trainer on the %s" % [str(_arbiter.call("prompt")), MOUNT_SPECIES])


## OP-0904-3, item one. Owner, on hardware: "When you ride your person didn't
## show up on the creature."
##
## Three separate claims, because "visible" alone was never the whole bug and a
## test that only asked about visibility would pass on a trainer standing bolt
## upright on the animal's back:
##
##   * the art is on screen at all (`rider_visible`);
##   * the SEATED POSE actually reached the skeleton, checked as a real node
##     query on the rig rather than as a flag the model sets about itself;
##   * the rider is where a rider goes -- above the creature's feet, below its
##     own back line, and travelling WITH it.
func _the_rider_is_on_the_creature() -> void:
	if not bool(_riding.call("is_mounted")):
		_fail("not mounted; the rider check cannot run")
		return
	var mount: Node3D = _riding.call("mount_body")
	var model: Node3D = _player.get_node_or_null(^"Model") as Node3D
	if model == null:
		_fail("the player has no Model node; the rider cannot be checked")
		return
	if not bool(_player.call("rider_visible")) or not model.visible:
		_fail("the trainer's art is hidden while mounted; the rider is invisible on the creature")
	if model.has_method("is_riding") and not bool(model.call("is_riding")):
		_fail("the trainer's model was never told it is riding; it is standing on the creature's back")
	if model.has_method("ride_pose_applied") and not bool(model.call("ride_pose_applied")):
		_fail("the seated pose never reached the trainer's skeleton")

	# The pose is bones, so check the BONES. A rig whose hip and knee are still
	# at their rest rotation is a rig standing up, whatever any flag says.
	var skeleton: Skeleton3D = model.call("skeleton") if model.has_method("skeleton") else null
	if skeleton == null:
		_fail("the trainer has no skeleton; the seated pose cannot be verified")
	else:
		for bone_name in ["LeftUpLeg", "LeftLeg"]:
			var index := skeleton.find_bone(bone_name)
			if index < 0:
				_fail("the trainer rig has no '%s' bone; the seated pose cannot be verified" % bone_name)
				continue
			var rest: Quaternion = skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
			var pose: Quaternion = skeleton.get_bone_pose_rotation(index)
			var bend := rad_to_deg(rest.angle_to(pose))
			if bend < 20.0:
				_fail("the mounted trainer's %s is %.1f degrees from rest; the leg is straight, so they are standing on the creature, not sitting on it"
					% [bone_name, bend])
			else:
				print("  seated: %s bent %.1f degrees from rest" % [bone_name, bend])

	# And the body is on the animal rather than beside it or inside the ground.
	var lift := _player.global_position.y - mount.global_position.y
	if lift < 0.2:
		_fail("the rider's feet are %.2f m above the mount's; they are not on it" % lift)
	var reach := Vector2(_player.global_position.x - mount.global_position.x,
		_player.global_position.z - mount.global_position.z).length()
	if reach > 1.2:
		_fail("the rider is %.2f m to one side of the mount they are sitting on" % reach)
	print("rider: visible, seated, %.2f m up and %.2f m off centre on the %s"
		% [lift, reach, MOUNT_SPECIES])


## OP-0904-3, item two, first half: "You can't sprint or jump when riding."
##
## Measured as speed the mount actually reached with the button held against
## speed it reached without, on the SAME heading -- not against the number in
## riding.json, which is the bug this exists for. The bar is the trainer's own
## sprint: a mount that cannot beat a running player is a mount nobody rides.
func _the_mount_sprints() -> void:
	if not bool(_riding.call("is_mounted")):
		_fail("not mounted; the sprint check cannot run")
		return
	var mount: Node3D = _riding.call("mount_body")
	var walking_peak := await _peak_speed_holding(mount, [])
	var sprinting_peak := await _peak_speed_holding(mount, ["sprint"])
	var sprint_on_foot := _sprint_speed()
	if sprinting_peak <= walking_peak + 0.5:
		_fail("the mount peaked at %.2f m/s sprinting and %.2f m/s not; holding sprint while mounted does nothing"
			% [sprinting_peak, walking_peak])
		return
	if sprinting_peak <= sprint_on_foot:
		_fail("a sprinting mount reaches %.2f m/s and a sprinting trainer reaches %.2f; riding is the slower way to travel"
			% [sprinting_peak, sprint_on_foot])
	if bool(_riding.call("is_ride_sprinting")):
		_fail("the mount still reads as sprinting with the button released")
	print("sprint: %.2f m/s held against %.2f m/s not, and %.2f m/s on foot"
		% [sprinting_peak, walking_peak, sprint_on_foot])


## OP-0904-3, item two, second half. A REAL hop: the mount leaves the ground by
## enough to clear the low fences and rocks a walking player vaults, and the
## rider goes up with it and is still seated when it lands.
##
## The rise is measured against the height the hop ASKED for
## (`ride_jump_height`), with a generous floor rather than an exact match --
## the creature is standing on real terrain and a slope under its feet is not
## the jump failing.
func _the_mount_jumps() -> void:
	if not bool(_riding.call("is_mounted")):
		_fail("not mounted; the jump check cannot run")
		return
	var mount: CharacterBody3D = _riding.call("mount_body") as CharacterBody3D
	if mount == null:
		_fail("the mount is not a CharacterBody3D; the jump cannot be measured")
		return
	# Let it settle on the ground first: a hop measured from a body that is
	# still falling measures the fall.
	for i in 40:
		await physics_frame
	var floor_y := mount.global_position.y
	var rider_floor_y := _player.global_position.y
	var asked := float(_riding.call("ride_jump_height"))

	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")

	var peak := floor_y
	var rider_peak := rider_floor_y
	var left_the_ground := false
	for i in 90:
		await physics_frame
		peak = maxf(peak, mount.global_position.y)
		rider_peak = maxf(rider_peak, _player.global_position.y)
		if not mount.is_on_floor():
			left_the_ground = true
	var rise := peak - floor_y
	var rider_rise := rider_peak - rider_floor_y
	if not left_the_ground:
		_fail("the mount never left the floor on a jump press")
	if rise < asked * 0.6:
		_fail("the mount rose %.2f m on a jump that asked for %.2f m; that is not a hop that clears anything"
			% [rise, asked])
	# The fence and rock heights a walking player vaults, from the trainer's own
	# step-up allowance and the low fence props -- a mount that cannot clear
	# them is a downgrade on foot.
	if rise < LOW_OBSTACLE_M:
		_fail("the mount rose %.2f m and the low fences a walking player vaults are %.2f m"
			% [rise, LOW_OBSTACLE_M])
	if rider_rise < rise - 0.15:
		_fail("the mount rose %.2f m and the rider only %.2f m; the trainer did not go up with it"
			% [rise, rider_rise])
	var model: Node3D = _player.get_node_or_null(^"Model") as Node3D
	if model != null and model.has_method("is_riding") and not bool(model.call("is_riding")):
		_fail("the rider stopped being seated somewhere in the jump")
	if not bool(_riding.call("is_mounted")):
		_fail("the jump ended the ride")
	print("jump: the mount rose %.2f m (asked %.2f) and the rider rose %.2f with it"
		% [rise, asked, rider_rise])


## Peak horizontal speed the mount reaches with `held` pressed alongside a
## forward stick, over a fixed window. Shared by the sprint check so both halves
## of its comparison are measured exactly the same way.
func _peak_speed_holding(mount: Node3D, held: Array) -> float:
	for action in held:
		Input.action_press(action)
	Input.action_press("move_forward")
	var peak := 0.0
	for i in 70:
		await physics_frame
		peak = maxf(peak, Vector3(mount.velocity.x, 0.0, mount.velocity.z).length())
	Input.action_release("move_forward")
	for action in held:
		Input.action_release(action)
	for i in 20:
		await physics_frame
	return peak


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

	# RE-AIM BEFORE EVERY PRESS, AND POLL FOR THE FIGHT RATHER THAN COUNTING
	# FRAMES. This was one teleport, a flat 30-frame settle and a flat 60-frame
	# wait, and it failed intermittently — on CI first, then roughly one local
	# run in three. The creature is the moving part: wild creatures roam, so the
	# spot computed from its position is already stale by the time the player is
	# standing there, and on a slow frame it has walked out of interact range
	# before the press lands. Snapping to where it is NOW on each attempt
	# removes the race instead of widening the window and hoping.
	var entered := false
	for attempt in 4:
		var spot := wild.global_position - wild.global_basis.z * 2.5
		spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
		_player.global_position = spot
		_player.velocity = Vector3.ZERO
		_rig.set("yaw", atan2(
			-(wild.global_position.x - spot.x), -(wild.global_position.z - spot.z)))
		for i in 30:
			await physics_frame
		await _press("interact")
		for i in 90:
			if bool(_manager.call("is_fighting")):
				break
			await physics_frame
		if bool(_manager.call("is_fighting")):
			entered = true
			break
		if not is_instance_valid(wild):
			break
	if not entered:
		_fail("could not enter combat in 4 attempts; the mid-fight refusal could not be tested")
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

	# OP-0904-3: everything the seated pose did has to come back off. A rider
	# left seated walks around the meadow sitting in mid-air with their knees
	# up, and one left dropped by the seat offset walks with their feet
	# underground -- both are quieter than an invisible trainer and neither is
	# caught by a visibility check.
	var model: Node3D = _player.get_node_or_null(^"Model") as Node3D
	if model != null:
		if model.has_method("is_riding") and bool(model.call("is_riding")):
			_fail("%s: the trainer's model still thinks it is riding" % context)
		if absf(model.position.y) > 0.01:
			_fail("%s: the trainer's art is still offset %.2f m from the body; the seat drop was never undone"
				% [context, model.position.y])
		var anim: AnimationPlayer = model.call("animation_player") if model.has_method("animation_player") else null
		if anim != null and not anim.active:
			_fail("%s: the trainer's animation player is still switched off; the body would never move again" % context)
		# Deliberately NOT a bone-angle assertion here. With the mixer back on
		# it owns every bone this pose touched within a frame, and the clip it
		# resumes can legitimately be mid-stride -- a knee 60 degrees from rest
		# would be a correct walk, not a leftover saddle. `anim.active` above is
		# the honest form of the same claim.
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


## The trainer's own sprint, for the bar a mounted sprint has to beat. Read
## from the same file the controller reads rather than typed here.
func _sprint_speed() -> float:
	var file := FileAccess.open("res://data/config/movement.json", FileAccess.READ)
	if file == null:
		return 8.6
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return 8.6
	return float(((parsed as Dictionary).get("locomotion", {}) as Dictionary).get("sprint_speed", 8.6))


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
