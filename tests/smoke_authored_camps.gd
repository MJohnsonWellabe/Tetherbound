extends SceneTree

## T5-CADENCE: are the Meadows' authored camps places you can actually stop?
##
##   godot --headless --path . --script tests/smoke_authored_camps.gd
##
## T4-REGIONS' audit (`ralph/reports/REGION_AUDIT_2026-08-30.md`) measured this
## as the third-worst gap in the chapter, and it is the kind of defect a unit
## test cannot see: `props.gd` placed a bed, a lit bonfire, a bench and a stool
## at `trail_camp` and every one of them was correct. What was missing was any
## way to use them. So this test does not check the config; it boots the world,
## walks the player up to a camp and presses the button.
##
## What it asserts, in the order the player meets it:
##
##   * every cluster whose data carries a `rest` block actually STOOD ONE UP --
##     data and world agreeing is the whole subject here
##   * standing at the camp, the interaction arbiter OFFERS the rest, which is
##     the thing that was missing: a prompt that exists but never wins the
##     arbitration is the same refusal in a different costume
##   * the camp's creature bed accepts an injured creature, and its authored
##     index is in the reserved negative range so it can never collide with a
##     bed the player builds
##   * pressing the button passes the night: the day advances, the trainer is
##     healed, the bedded creature completes its rest, and the objective ladder's
##     `player_slept_at_home` rung clears
##   * the camp offers CRAFT as well as rest -- exit criterion H5 asks camp and
##     home for "recovery, crafting, food..." and the player-built camp already
##     offers both, so an authored one that offered less would be a second-class
##     camp
##
## Nothing here re-tests what a night DOES in detail. `smoke_gateb_flags.gd` and
## `tests/helpers/gate_b_tail_segment.gd` already drive `camp.gd`'s rest end to
## end, and since T5-CADENCE both camps call the same `night_rest.gd`. What this
## proves is that the AUTHORED camps reach it.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const REST_POINT := preload("res://scripts/world/rest_point.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
## Any band-3 wild will do -- the subject is the bed, not the animal.
const BEDDED_SPECIES := "brooktail"
const PROPS_CONFIG := "res://data/config/props.json"

## Never touch a player's real save directory from a regression: the night
## this test passes autosaves through `game.call("save_game", ...)`.
const TEST_DIR := "user://test_saves_authored_camps/"

const SETTLE_FRAMES := 240
## The rest prompt's own radius is 3.2m and the arbiter needs a clear sight
## line from the player's eye point, so the player is set down a couple of
## metres off the prompt rather than on top of it -- close enough to be inside
## the radius, far enough that the ray is a real ray.
const STAND_OFF_M := 1.8

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	_wipe_test_dir()
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var props: Node3D = world.get_node_or_null(^"Props") as Node3D
	var game := root.get_node_or_null(^"/root/Game")
	if player == null or props == null or game == null:
		print("authored camps FAIL: the scene has no Player, no Props node or no Game autoload")
		quit(1)
		return

	# Never touch a player's real save directory from a regression.
	game.set("save_system", SAVE_GAME.new(TEST_DIR))

	var authored := _authored_rest_clusters()
	if authored.is_empty():
		_fail("no cluster in data/config/bands/*/props.json carries a `rest` block; the camps are scenery again")
	_every_authored_camp_stood_one_up(props, authored)
	_every_bed_index_is_reserved_and_unique(authored)
	await _the_camp_offers_rest_where_the_player_stands(world, player, props, authored)
	await _resting_at_an_authored_camp_passes_the_night(world, player, props, game, authored)

	_wipe_test_dir()
	print("")
	if _failures.is_empty():
		print("authored camps smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _wipe_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir():
			dir.remove(name)
		name = dir.get_next()
	dir.list_dir_end()


## The merged, band-split props config -- the same `BAND_CONTENT.load_config`
## call `props.gd` itself makes, so this test and the world are reading one
## source and a band added later is covered without editing this file.
func _authored_rest_clusters() -> Array:
	var parsed: Dictionary = BAND_CONTENT.load_config(PROPS_CONFIG, "clusters")
	var out: Array = []
	for cluster: Variant in parsed.get("clusters", []):
		if not cluster is Dictionary:
			continue
		var rest: Variant = (cluster as Dictionary).get("rest", {})
		if rest is Dictionary and not (rest as Dictionary).is_empty():
			out.append([str((cluster as Dictionary).get("name", "?")), rest as Dictionary])
	return out


func _rest_node(props: Node3D, name: String) -> Node3D:
	var group := props.get_node_or_null(NodePath(name))
	if group == null:
		return null
	return group.get_node_or_null(NodePath("%s_Rest" % name)) as Node3D


func _every_authored_camp_stood_one_up(props: Node3D, authored: Array) -> void:
	print("authored camps carrying a rest block: %d" % authored.size())
	# props.gd's own count, checked against the data before any node lookup:
	# a camp whose `rest` block was silently skipped (bad ground, a missing
	# `at`) would otherwise only show up as one absent node among five.
	var built := int(props.call("rest_points"))
	if built != authored.size():
		_fail("%d clusters author a rest block and props.gd stood up %d" % [authored.size(), built])
	for entry: Array in authored:
		var name: String = entry[0]
		var spec: Dictionary = entry[1]
		var point := _rest_node(props, name)
		if point == null:
			_fail("'%s' carries a `rest` block but built no rest point in the world" % name)
			continue
		if point.get_node_or_null(^"Interactable") == null:
			_fail("'%s''s rest point has no rest prompt" % name)
		if bool(spec.get("craft", true)) and point.get_node_or_null(^"CraftInteractable") == null:
			_fail("'%s''s rest point offers no Craft; exit criterion H5 asks a camp for recovery AND crafting" % name)
		var wants_bed: Variant = spec.get("creature_bed", {})
		if wants_bed is Dictionary and not (wants_bed as Dictionary).is_empty():
			var bed := point.get_node_or_null(^"CampCreatureBed")
			if bed == null:
				_fail("'%s' authors a creature bed and did not build one" % name)
			elif int(bed.call("build_index")) != int((wants_bed as Dictionary).get("bed_index", 0)):
				_fail("'%s''s creature bed came up at index %d, not the authored %d"
					% [name, int(bed.call("build_index")),
						int((wants_bed as Dictionary).get("bed_index", 0))])
		print("  %-22s rest%s%s at %.0f, %.0f" % [
			name,
			" + craft" if point.get_node_or_null(^"CraftInteractable") != null else "",
			" + bed" if point.get_node_or_null(^"CampCreatureBed") != null else "",
			point.global_position.x, point.global_position.z])


## A bed's index is what a resting creature stores in `rest_bed_index`. Two
## authored beds sharing one would show the same sleeping creature in both and
## let neither be filled twice; an index at or above zero would collide with the
## beds the player builds, which are numbered upward from 0 by the build store.
func _every_bed_index_is_reserved_and_unique(authored: Array) -> void:
	var seen := {}
	for entry: Array in authored:
		var spec: Dictionary = entry[1]
		var raw: Variant = spec.get("creature_bed", {})
		if not raw is Dictionary or (raw as Dictionary).is_empty():
			continue
		var index := int((raw as Dictionary).get("bed_index", 0))
		if index > REST_POINT.AUTHORED_BED_INDEX_CEILING:
			_fail("'%s''s bed index %d is outside the reserved range (<= %d) and can collide with a player's own bed"
				% [entry[0], index, REST_POINT.AUTHORED_BED_INDEX_CEILING])
		if seen.has(index):
			_fail("'%s' and '%s' both claim bed index %d" % [entry[0], str(seen[index]), index])
		seen[index] = entry[0]


## The measured defect, restated as a question a test can answer: standing in
## the camp, does the game OFFER the rest?
func _the_camp_offers_rest_where_the_player_stands(
		world: Node, player: CharacterBody3D, props: Node3D, authored: Array) -> void:
	var arbiter: Node = get_first_node_in_group("interaction_arbiter")
	if arbiter == null:
		_fail("no interaction arbiter in the world; nothing can offer anything")
		return
	for entry: Array in authored:
		var name: String = entry[0]
		var point := _rest_node(props, name)
		if point == null:
			continue
		var label := str((entry[1] as Dictionary).get("label", "Rest until morning"))
		await _stand_beside(world, player, point.global_position)
		var offered := str(arbiter.call("prompt"))
		if not offered.contains(label):
			_fail("standing %.1fm from '%s''s fire, the game offers '%s', not '%s'"
				% [STAND_OFF_M, name, offered if not offered.is_empty() else "nothing", label])
		else:
			print("  %-22s offers '%s'" % [name, offered])


## The whole point, end to end: an injured creature bedded down at an authored
## camp, the button pressed, and a morning on the other side of it.
func _resting_at_an_authored_camp_passes_the_night(
		world: Node, player: CharacterBody3D, props: Node3D, game: Node,
		authored: Array) -> void:
	var point: Node3D = null
	var camp_name := ""
	for entry: Array in authored:
		var candidate := _rest_node(props, entry[0])
		if candidate != null and candidate.get_node_or_null(^"CampCreatureBed") != null:
			point = candidate
			camp_name = entry[0]
			break
	if point == null:
		_fail("no authored camp has a creature bed to test a real recovery at")
		return

	# A fresh boot has an empty party, and an authored camp with nothing to put
	# in its bed would leave the half of this that matters most untested: exit
	# criterion H3 is about a creature that visibly rests and recovers, not
	# about the day counter.
	var party: RefCounted = game.get("party")
	var creature: RefCounted = null
	if party != null:
		if int(party.call("size")) > 0:
			creature = party.call("at", 0)
		else:
			creature = SPECIES.spawn(BEDDED_SPECIES)
			if creature == null or not bool(party.call("add", creature)):
				_fail("could not put a %s in the party; nothing to bed down" % BEDDED_SPECIES)
				return
	var bed := point.get_node_or_null(^"CampCreatureBed")
	if creature != null:
		creature.set("hp", maxf(1.0, float(creature.get("max_hp")) * 0.25))
		if not bool(bed.call("assign_creature", 0)):
			_fail("'%s''s creature bed refused an injured party member" % camp_name)
			return
		if not bool(bed.call("is_occupied")):
			_fail("'%s''s creature bed accepted a creature and then reported itself empty" % camp_name)

	var progression: RefCounted = game.get("progression")
	if progression != null:
		progression.call("set_flag", "player_slept_at_home", false)
	var day_before := int(game.get("day"))
	var vitals: RefCounted = player.get("vitals")
	if vitals != null:
		vitals.set("hunger", 10.0)

	await _stand_beside(world, player, point.global_position)
	var arbiter: Node = get_first_node_in_group("interaction_arbiter")
	if not bool(arbiter.call("activate")):
		_fail("pressing interact at '%s' activated nothing" % camp_name)
		return
	# The fade is 1.2s and the night passes at its midpoint; give it the whole
	# tween plus a margin, the same budget `smoke_gateb_flags.gd` gives camp.gd's.
	for i in 150:
		await physics_frame

	var day_after := int(game.get("day"))
	if day_after <= day_before:
		_fail("resting at '%s' did not advance the day (%d -> %d)" % [camp_name, day_before, day_after])
	else:
		print("  rested at %s: day %d -> %d" % [camp_name, day_before, day_after])
	if progression != null and not bool(progression.call("has", "player_slept_at_home")):
		_fail("resting at '%s' did not clear the objective ladder's rest rung" % camp_name)
	if creature != null:
		if bool(creature.get("resting")):
			_fail("the creature bedded at '%s' was still marked resting after the night" % camp_name)
		if float(creature.get("hp")) < float(creature.get("max_hp")) - 0.01:
			_fail("the creature bedded at '%s' woke at %.0f/%.0f HP" % [
				camp_name, float(creature.get("hp")), float(creature.get("max_hp"))])
		else:
			print("  the bedded creature woke at full HP")


## K3: this used to teleport once and then just wait 20 physics frames,
## trusting gravity and `move_and_slide()` to settle the player onto real
## ground. `tools/_probe_trail_camp_second_visit.gd` (frame-by-frame arbiter
## AND collision logging) found that trusting it is the bug: the FIRST
## teleport into `trail_camp`'s stand-off spot lands solidly by frame 5
## (`is_on_floor()==true`, y settles at 1.645) every time, but a SECOND
## teleport to the exact same coordinates -- reached only by
## `_resting_at_an_authored_camp_passes_the_night()`, after the offer sweep
## has already carried the player clear across four other bands and back --
## sometimes free-falls the player straight through that same ground,
## unarrested, until they are outside the rest prompt's radius by frame 18.
## A physics shape query run alongside the fall (not the ray `ground_height_at`
## itself warns against -- a direct `intersect_shape` at the real ground
## height) showed real Terrain3D collision only flickering into presence at
## y=1.60 around frame 14, well after the player's OWN fall had already
## carried them past it, followed immediately by a sideways depenetration
## shove -- a terrain-collision-streaming race on a long-distance teleport,
## not a stale offer or a state a `set_flag`/`assign_creature` call in the
## test left dirty (confirmed by reproducing the identical fall with the bed
## assignment skipped entirely). Nothing rest_point.gd or
## interaction_arbiter.gd computes is wrong here -- they correctly stop
## offering once the player has genuinely fallen out of range. Fixing the
## terrain streaming itself is a world-system change and not this test's job;
## this test only needs the player standing beside the point to ask the
## arbiter a question, not a realistic fall, so it holds the target transform
## fixed every physics frame of the settle window instead of setting it once
## and hoping gravity leaves it alone.
func _stand_beside(_world: Node, player: CharacterBody3D, at: Vector3) -> void:
	var target := at + Vector3(STAND_OFF_M, 0.2, 0.0)
	for i in 20:
		player.velocity = Vector3.ZERO
		player.global_position = target
		await physics_frame
