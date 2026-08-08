extends TestCase

## M12's riding rules, asserted against the data the game actually ships.
##
## Pure logic only, per docs/decisions/D02: which species can be ridden, where a
## rider ends up on each of them, how fast a mount travels against the trainer's
## own legs, and when a gallop runs out. No scene, no rendering and no input —
## how riding FEELS is a thing to be looked at, and `tools/preview_riding.gd`
## renders it for that.
##
## Several of these assert a MILESTONE BULLET rather than a function. "Clear
## advantage over running" and "no species-specific saddle clutter" are both
## checkable statements about two files, and a bullet phrased as a comparison
## should fail the build on the day it stops being true — which is the day
## somebody retunes `sprint_speed` and does not think about the mount.

const MOUNT := preload("res://scripts/pals/mount.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const DEFS := preload("res://scripts/items/item_defs.gd")

const MOVEMENT_PATH := "res://data/config/movement.json"

## The trainer, who is the ruler this whole milestone is measured against
## (docs/reviews/MA-04).
const TRAINER_HEIGHT := 1.80


func _movement() -> Dictionary:
	var file := FileAccess.open(MOVEMENT_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## --- the roster -------------------------------------------------------------

func test_some_species_are_rideable_and_most_are_not() -> void:
	var rideable: Array[String] = []
	for id in SPECIES.ids():
		if MOUNT.is_rideable(id):
			rideable.append(id)
	assert_false(rideable.is_empty(), "no species can be ridden; M12 has no mount")
	assert_true(rideable.size() < SPECIES.ids().size(),
		"every species is rideable, which means the flag is not deciding anything")


func test_every_species_declares_whether_it_can_be_ridden() -> void:
	# Explicit on all eight, the same rule `aggressive` follows: adding a species
	# should be a decision, not an inherited default.
	for id in SPECIES.ids():
		assert_true(SPECIES.definition(id).has("rideable"),
			"species '%s' does not say whether it can be ridden" % id)


## The clearance the RENDERED FRAMES established, in metres above the trainer's
## hip. At 0.10 his boot is on the grass and at 0.16 it is not — see
## `shots/riding/` and species.json's `_comment_rideable`. It is here rather than
## in the config because it is not a dial: it is a fact about a trainer who has
## no seated animation, and the day he gets one this number and that comment both
## change together.
const RIDING_CLEARANCE := 0.15

## How much faster than a sprint the SLOWEST mount must amble for M12's "clear
## advantage over running" to be honestly true.
const CLEAR_ADVANTAGE := 1.15


func test_the_rule_is_the_back_clears_the_trainers_hip() -> void:
	# species.json's `_comment_rideable` states the rule; this is it, executable.
	# A future species that is rideable and too low to sit on fails here rather
	# than in a screenshot of a trainer standing on the grass astride something.
	var hip := float(_movement().get("riding", {}).get("rider_hip_height", 1.05))
	assert_between(hip, 0.5, TRAINER_HEIGHT, "the trainer's hip is not on his body")
	for id in SPECIES.ids():
		if not MOUNT.is_rideable(id):
			continue
		var back := float(MOUNT.ride_data(id).get("back_height", 0.0))
		assert_true(back >= hip + RIDING_CLEARANCE,
			"'%s' is rideable but its back is %.2fm, under the %.2fm a %.2fm hip needs" % [
				id, back, hip + RIDING_CLEARANCE, hip])


func test_a_rideable_species_declares_where_its_back_is() -> void:
	for id in SPECIES.ids():
		if not MOUNT.is_rideable(id):
			continue
		var ride := MOUNT.ride_data(id)
		assert_true(ride.has("back_height"),
			"'%s' is rideable but nothing says where a rider sits on it" % id)
		assert_true(ride.has("back_forward"),
			"'%s' is rideable but nothing says how far along its back a rider sits" % id)


func test_a_creature_nobody_can_ride_carries_no_ride_tuning() -> void:
	# The other direction: ride numbers on an unrideable species are numbers
	# nothing reads, which is how a flag and its data drift apart.
	for id in SPECIES.ids():
		if MOUNT.is_rideable(id):
			continue
		assert_true(MOUNT.ride_data(id).is_empty(),
			"'%s' cannot be ridden but carries ride tuning" % id)


## --- where the rider ends up ------------------------------------------------

func test_the_seat_puts_the_riders_hips_on_the_creatures_back() -> void:
	var hip := float(_movement().get("riding", {}).get("rider_hip_height", 1.05))
	for id in SPECIES.ids():
		if not MOUNT.is_rideable(id):
			continue
		var seat := MOUNT.seat_offset(id)
		var back := float(MOUNT.ride_data(id).get("back_height", 0.0))
		assert_almost_eq(seat.y + hip, back, 0.0001,
			"'%s': the rider's hips are not on its back" % id)
		assert_almost_eq(seat.z, float(MOUNT.ride_data(id).get("back_forward", 0.0)), 0.0001)
		assert_almost_eq(seat.x, 0.0, 0.0001, "'%s': the rider is off to one side" % id)


func test_the_rider_is_never_placed_below_the_creatures_feet() -> void:
	# The seat is body-LOCAL and the body's origin is between the creature's
	# hooves, so a negative Y is a rider underground. It is the one arithmetic
	# mistake in this file that would be invisible in a wide shot.
	for id in SPECIES.ids():
		if not MOUNT.is_rideable(id):
			continue
		assert_true(MOUNT.seat_offset(id).y >= 0.0,
			"'%s' seats the rider %.2fm below its own feet" % [id, MOUNT.seat_offset(id).y])


## --- the milestone bullet: clear advantage over running ---------------------

func test_riding_is_faster_than_sprinting_on_every_mount() -> void:
	var loco: Dictionary = _movement().get("locomotion", {})
	var sprint := float(loco.get("sprint_speed", 7.6))
	var walk := float(loco.get("walk_speed", 4.2))
	assert_true(sprint > walk, "sprint is not faster than walking; the config is upside down")
	for id in SPECIES.ids():
		if not MOUNT.is_rideable(id):
			continue
		# The RESTING pace, not the gallop. The advantage has to survive a mount
		# whose stamina is spent, or riding is a burst rather than a way to cross
		# the meadow.
		#
		# And it is a MARGIN, not a strict inequality. The first tuning pass put
		# the slowest mount at 7.65 against a 7.6 sprint: five centimetres a
		# second, which passes `>` and is not "a clear advantage over running" by
		# any reading a player would recognise.
		assert_true(MOUNT.ride_speed(id, false) >= sprint * CLEAR_ADVANTAGE,
			"'%s' ambles at %.2f m/s against a %.2f sprint — %.0f%% is not a clear advantage" % [
				id, MOUNT.ride_speed(id, false), sprint,
				(MOUNT.ride_speed(id, false) / sprint - 1.0) * 100.0])


func test_the_gallop_is_faster_than_the_amble() -> void:
	for id in SPECIES.ids():
		if not MOUNT.is_rideable(id):
			continue
		assert_true(MOUNT.ride_speed(id, true) > MOUNT.ride_speed(id, false),
			"'%s' gallops no faster than it ambles" % id)


func test_mounts_do_not_all_travel_at_the_same_speed() -> void:
	var speeds := {}
	for id in SPECIES.ids():
		if MOUNT.is_rideable(id):
			speeds[snappedf(MOUNT.ride_speed(id, false), 0.01)] = true
	assert_true(speeds.size() > 1,
		"every mount travels at exactly one speed; `speed_scale` is doing nothing")


## --- the milestone bullet: one generic saddle -------------------------------

func test_there_is_exactly_one_saddle_in_the_game() -> void:
	# "No species-specific saddle clutter", as a check on the item table. A
	# `stag_saddle` added beside the generic one fails here on the day it is
	# written rather than the day somebody notices two saddles in the bag.
	var saddles: Array[String] = []
	for id: String in DEFS.ids():
		if id.contains("saddle") or id.contains("harness"):
			saddles.append(id)
	assert_eq(saddles.size(), 1, "expected one generic saddle, found: %s" % ", ".join(saddles))
	assert_eq(saddles[0], MOUNT.SADDLE_ITEM)


func test_the_saddle_is_a_real_item_that_does_not_stack() -> void:
	assert_true(DEFS.has(MOUNT.SADDLE_ITEM), "the riding saddle is not in the item tables")
	assert_eq(DEFS.stack_limit(MOUNT.SADDLE_ITEM), 1)
	assert_ne(DEFS.display_name(MOUNT.SADDLE_ITEM), MOUNT.SADDLE_ITEM,
		"the saddle has no display name and would show as its id")


func test_the_saddle_is_not_a_tool() -> void:
	# A tool is durable and `tools.gd` puts every tool in the hand cycle, so
	# filing the saddle there would give the trainer a saddle he can select and
	# swing. GAME_DESIGN.md §19: tools cannot damage pals or humans.
	assert_false(DEFS.is_tool_item(MOUNT.SADDLE_ITEM))
	assert_eq(DEFS.max_durability(MOUNT.SADDLE_ITEM), 0)


func test_no_species_names_its_own_saddle() -> void:
	# The schema half of "generic". A creature that could name its tack is the
	# first half of a per-species saddle table.
	for id in SPECIES.ids():
		var ride := MOUNT.ride_data(id)
		for key: String in ride.keys():
			assert_false(key.contains("saddle") and not key.begins_with("_"),
				"'%s' names its own saddle in '%s'" % [id, key])


## --- the mount's stamina ----------------------------------------------------

func test_a_gallop_runs_out() -> void:
	var legs := MOUNT.Legs.new()
	legs.configure(MOUNT.config().get("stamina", {}))
	assert_true(legs.can_gallop(), "a rested mount cannot gallop")
	for i in 600:
		legs.tick(0.1, true)
	assert_false(legs.can_gallop(), "a mount galloped for a minute without tiring")
	assert_almost_eq(legs.fraction(), 0.0, 0.001)


func test_a_blown_mount_recovers_but_not_instantly() -> void:
	var legs := MOUNT.Legs.new()
	legs.configure(MOUNT.config().get("stamina", {}))
	for i in 600:
		legs.tick(0.1, true)
	assert_false(legs.can_gallop())
	# One frame of standing still must not undo a minute of galloping; the
	# exhaustion threshold is what stops a stutter-gallop at zero.
	legs.tick(0.1, false)
	assert_false(legs.can_gallop(), "one tenth of a second of rest restored the gallop")
	for i in 300:
		legs.tick(0.1, false)
	assert_true(legs.can_gallop(), "a rested mount never recovers its gallop")


func test_resting_is_delayed_after_a_gallop() -> void:
	var legs := MOUNT.Legs.new()
	legs.configure(MOUNT.config().get("stamina", {}))
	legs.tick(1.0, true)
	var spent := legs.stamina
	assert_true(spent < legs.maximum, "galloping cost nothing")
	# Inside the delay, nothing comes back.
	legs.tick(minf(0.1, legs.regen_delay * 0.5), false)
	assert_almost_eq(legs.stamina, spent, 0.0001,
		"stamina regenerated during the delay, which makes the delay decoration")


func test_ambling_costs_the_mount_nothing() -> void:
	# The decision, as an assertion: the base pace is free forever, so a drained
	# mount is slower rather than stranded.
	var legs := MOUNT.Legs.new()
	legs.configure(MOUNT.config().get("stamina", {}))
	for i in 600:
		legs.tick(0.1, false)
	assert_almost_eq(legs.fraction(), 1.0, 0.001)
	assert_true(legs.can_gallop())


func test_the_mounts_stamina_is_not_the_trainers() -> void:
	# Two separate pools, in two separate places in the config. If riding ever
	# starts spending the trainer's meter, this is where it should be noticed.
	var cfg := _movement()
	var trainer: Dictionary = cfg.get("stamina", {})
	var mount_legs: Dictionary = cfg.get("riding", {}).get("stamina", {})
	assert_false(mount_legs.is_empty(), "the mount has no stamina block of its own")
	assert_false(trainer.is_empty(), "the trainer has no stamina block")
	assert_false(mount_legs.has("sprint_drain_per_second"),
		"the mount's stamina block has the trainer's drain key in it")


## --- refusals ---------------------------------------------------------------

func test_every_refusal_is_a_distinct_token() -> void:
	var seen := {}
	for token: String in MOUNT.REFUSALS:
		assert_false(seen.has(token), "duplicate refusal token '%s'" % token)
		assert_false(token.is_empty())
		seen[token] = true
	assert_eq(seen.size(), MOUNT.REFUSALS.size())


func test_an_unknown_species_cannot_be_ridden() -> void:
	assert_false(MOUNT.is_rideable("not_a_species"))
	assert_true(MOUNT.ride_data("not_a_species").is_empty())
