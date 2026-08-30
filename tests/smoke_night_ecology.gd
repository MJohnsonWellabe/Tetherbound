extends SceneTree

## T5-CAMPS: does night change the world in the first hour?
##
##   godot --headless --path . --script tests/smoke_night_ecology.gd
##
## `ralph/reports/REGION_AUDIT_2026-08-30.md` gap 7: bands 0 and 1 carried zero
## night-gated spawns -- 0 `time` entries across all 55 clusters -- so the
## player's entire opening was identical by day and after dark, in a game that
## ships a real day/night clock. Criterion 13 of the region checklist
## (`ralph/MEADOWS_EXIT_CRITERION.md` section E) is a PER-REGION requirement and
## band 2 was the only region in the chapter meeting it.
##
## This is deliberately not a config test. `ralph/MEADOWS_EXIT_CRITERION.md`'s
## evidence rule is explicit that "config-level assertions and passing tests are
## not evidence that a player can reach a thing. A played path is." Asserting
## that `"time": "night"` appears in a JSON file would prove nothing that
## grepping the file does not already prove -- and the failure mode this content
## is most likely to have is precisely one a config assertion cannot see: a
## creature that is gated correctly and standing somewhere the player can never
## get to, or standing nowhere at all. That is not hypothetical here. This
## file's sibling `data/config/spawns.json` records, in its own
## `_comment_placement`, that Galecrest and Burrowback were once authored onto a
## rocky rise whose rim is a closed >45-degree band -- "measured at 71 of 72
## radial approaches unwalkable" -- so neither could be met, fought or caught.
## Night gating hides that class of mistake BETTER than day content does,
## because the player only ever has a chance to notice after dark.
##
## So the test boots the real world and, in the order the player meets it:
##
##   * asserts bands 0/1 author night-gated clusters at all -- the regression
##     guard, so this cannot silently go back to zero
##   * asserts every one of those clusters actually STOOD ITS BODIES UP, by
##     name, in the running scene: data and world agreeing is half the subject
##   * asserts each owl found ground under it, because `encounter_director.gd`
##     only push_error()s on a missed ground query and a test that ignored that
##     would pass over a creature falling through the world
##   * pins the clock to DAY and asserts they are all hidden
##   * pins the clock to NIGHT and asserts they are all visible -- the same
##     `_sync_spawn_gates()` path the shipping build runs every frame
##   * walks the player to the grove and asserts the director OFFERS
##     "Engage Duskhush" where they are standing, which is the difference
##     between a creature existing and a creature the player can meet
##
## The last one is the point. A gated creature that is visible but never
## engageable is scenery with a schedule.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const SPAWNS_CONFIG := "res://data/config/spawns.json"

## The audit's finding is about bands 0 and 1, which share one spawn file.
## `band1_lower_meadows` runs from the home meadow at negative z up to the South
## Bridge; band 0 is its southern end rather than a separate directory (the
## audit's own note: "Band 0 has no data/config/bands/band0/ directory").
## Band 0 is everything south of the road gate out of the village; the split is
## only used to report the two regions separately, since criterion 13 is judged
## per region and the audit failed BOTH.
const BAND0_MAX_Z := 400.0
## The South Bridge at z=1330 is the band 1 -> band 2 handover; past it is band
## 2, which already met criterion 13 and is not this lane's subject.
const BAND1_MAX_Z := 1360.0

## The player needs something to fight WITH before `_engageable()` will offer a
## wild at all -- same call `sequence_director.gd` makes once a name is
## confirmed, and the same one `smoke_aggression.gd` uses for the same reason.
const STARTER := "terrapup"

const SETTLE_FRAMES := 240
const GATE_FRAMES := 30

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	var authored := _authored_night_clusters()
	if authored.is_empty():
		print("night ecology FAIL: bands 0/1 author no night-gated spawns at all.")
		print("  This is the exact state ralph/reports/REGION_AUDIT_2026-08-30.md gap 7 measured:")
		print("  the chapter's opening reads identically by day and after dark.")
		quit(1)
		return

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var director: Node = world.get_node_or_null(^"EncounterDirector")
	var look: Node = world.get_node_or_null(^"WorldLook")
	if player == null or director == null or look == null:
		print("night ecology FAIL: the scene has no Player, no EncounterDirector or no WorldLook")
		quit(1)
		return

	_report_what_is_authored(authored)
	var bodies := _every_night_cluster_stood_its_bodies_up(director, authored)
	_every_owl_found_ground(world, bodies)
	await _hidden_by_day(look, bodies)
	await _present_after_dark(look, bodies)
	await _the_player_can_meet_one(world, player, director, look, authored)

	print("")
	if _failures.is_empty():
		print("night ecology smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("FAIL: %s" % line)
	print("night ecology smoke test FAILED (%d)" % _failures.size())
	quit(1)


## Every `time: night` cluster this band authors, as {order: entry}.
func _authored_night_clusters() -> Dictionary:
	var out := {}
	var parsed: Dictionary = BAND_CONTENT.load_config(SPAWNS_CONFIG, "spawns")
	var merged: Array = parsed.get("spawns", []) as Array
	for entry: Variant in merged:
		if not (entry is Dictionary):
			continue
		var spawn: Dictionary = entry
		if str(spawn.get("time", "")) != "night":
			continue
		# Band-local: this band's reserved order range is 1000-1999, and the
		# pre-split entries it kept are all below 100. Reading the merged array
		# and filtering by position is what keeps this test honest about WHERE
		# the content is rather than which file it happens to live in.
		var centre: Array = spawn.get("centre", [])
		if centre.size() < 3:
			continue
		if float(centre[2]) > BAND1_MAX_Z:
			continue
		out[int(spawn.get("order", -1))] = spawn
	return out


func _report_what_is_authored(authored: Dictionary) -> void:
	var band0 := 0
	var band1 := 0
	var owls := 0
	for order: int in authored:
		var spawn: Dictionary = authored[order]
		owls += int(spawn.get("count", 0))
		if float((spawn.get("centre", []) as Array)[2]) <= BAND0_MAX_Z:
			band0 += 1
		else:
			band1 += 1
	print("night-gated clusters in bands 0/1: %d (%d individuals)" % [authored.size(), owls])
	print("  band 0 (home meadow)     %d cluster(s)" % band0)
	print("  band 1 (oak grove ring)  %d cluster(s)" % band1)
	if band0 == 0:
		_fail("band 0 still has no night-gated spawn; the home meadow reads the same after dark")
	if band1 == 0:
		_fail("band 1 still has no night-gated spawn")


## The bodies each authored night cluster actually stood up, by node name.
## `encounter_director.gd` names them "Wild_<species>_<order>_<n>".
func _every_night_cluster_stood_its_bodies_up(director: Node, authored: Dictionary) -> Array[Node3D]:
	var found: Array[Node3D] = []
	var wilds: Array = director.call("wild_creatures")
	for order: int in authored:
		var spawn: Dictionary = authored[order]
		var species := str(spawn.get("species", ""))
		var want := int(spawn.get("count", 0))
		var prefix := "Wild_%s_%d_" % [species, order]
		var mine: Array[Node3D] = []
		for wild: Variant in wilds:
			if wild is Node3D and str((wild as Node3D).name).begins_with(prefix):
				mine.append(wild)
		if mine.size() != want:
			_fail("cluster %d authors %d %s but the world stood up %d" % [
				order, want, species, mine.size()])
		found.append_array(mine)
	print("night bodies standing in the world: %d" % found.size())
	return found


## A creature with no ground under it is unreachable no matter how correct its
## gate is. `encounter_director.gd` push_error()s on a missed ground query and
## then spawns anyway, so this is the assertion that turns that into a failure.
func _every_owl_found_ground(world: Node, bodies: Array[Node3D]) -> void:
	var worst := 0.0
	var worst_name := ""
	for wild in bodies:
		var ground := float(world.call("ground_height_at", wild.global_position.x, wild.global_position.z))
		var off := absf(wild.global_position.y - ground)
		if off > worst:
			worst = off
			worst_name = str(wild.name)
	# Bodies stand with their feet on the ground but are positioned by origin,
	# so a metre or two of offset is the creature's own height, not a fall.
	if worst > 3.0:
		_fail("%s stands %.1fm off the ground; it may have spawned inside or under the terrain" % [
			worst_name, worst])
	else:
		print("every night body is on the ground (worst offset %.2fm, %s)" % [worst, worst_name])


func _hidden_by_day(look: Node, bodies: Array[Node3D]) -> void:
	await _pin_clock(look, "day")
	var showing := 0
	for wild in bodies:
		if wild.visible:
			showing += 1
	if showing > 0:
		_fail("%d night-gated creature(s) are visible in broad daylight; the gate is not holding" % showing)
	else:
		print("by day:   %d/%d night bodies hidden" % [bodies.size(), bodies.size()])


func _present_after_dark(look: Node, bodies: Array[Node3D]) -> void:
	await _pin_clock(look, "night")
	if not bool(look.call("is_dark")):
		_fail("WorldLook does not report is_dark() after apply_time('night'); the clock never reached night")
		return
	var hidden := 0
	for wild in bodies:
		if not wild.visible:
			hidden += 1
	if hidden > 0:
		_fail("%d night-gated creature(s) are still hidden after dark; the player can never meet them" % hidden)
	else:
		print("at night: %d/%d night bodies present" % [bodies.size(), bodies.size()])


## `apply_time()` sets the hour; `set_process(false)` stops the clock walking
## back off it, the same pin `tools/_capture_band2_2044_night.gd` uses. The
## gates are re-read in `encounter_director.gd::_process`, so the frames after
## the pin are what actually opens or closes them.
func _pin_clock(look: Node, preset: String) -> void:
	look.call("apply_time", preset)
	look.set_process(false)
	for i in GATE_FRAMES:
		await physics_frame


## The played path. Stand the player in the oak grove ring after dark and ask
## the director what it is offering where they are -- not whether a creature
## exists somewhere, but whether this one can be engaged from here.
func _the_player_can_meet_one(world: Node, player: CharacterBody3D, director: Node, look: Node, authored: Dictionary) -> void:
	# The deepest cluster in the grove: the one with the most individuals past
	# the band-0 hook, which is where the population is meant to read as a
	# population rather than as a single call in the dark.
	var best_order := -1
	var best_count := -1
	for order: int in authored:
		var spawn: Dictionary = authored[order]
		var centre: Array = spawn.get("centre", [])
		if float(centre[2]) <= BAND0_MAX_Z:
			continue
		if int(spawn.get("count", 0)) > best_count:
			best_count = int(spawn.get("count", 0))
			best_order = order
	if best_order < 0:
		_fail("no band-1 night cluster to walk to")
		return

	if director.call("ally_instance") == null:
		await director.call("adopt_starter", STARTER)
	# Adopting a starter runs game state that can put the clock back to morning,
	# which closes every gate this test just opened. Re-pin AFTER it, so the
	# offer below is read in the same world state the assertion describes.
	await _pin_clock(look, "night")

	# Walk to the nearest body of that cluster rather than to the cluster's
	# authored centre: the scatter is seeded, so the centre is a point in the
	# data and the creature is a point in the world, and the player meets the
	# second one.
	var prefix := "Wild_duskhush_%d_" % best_order
	var target: Node3D = null
	for wild: Variant in director.call("wild_creatures"):
		if wild is Node3D and str((wild as Node3D).name).begins_with(prefix):
			target = wild
			break
	if target == null:
		_fail("cluster %d stood up no body to walk to" % best_order)
		return

	var spot := target.global_position
	spot.x += 2.0
	spot.y = float(world.call("ground_height_at", spot.x, spot.z)) + 1.0
	player.global_position = spot
	player.velocity = Vector3.ZERO
	for i in GATE_FRAMES:
		await physics_frame

	if not target.visible:
		_fail("the target Duskhush is hidden at the moment the offer is read; the clock came off night")
	var offer: Dictionary = director.call("interaction_offer", player.global_position)
	# `prompt_arbiter.gd`'s offers are keyed `label`/`actionable`, not `text` --
	# reading the wrong key here reported "the player cannot meet it" against a
	# live, actionable "Engage Duskhush", which is exactly the false negative
	# this test exists to avoid producing.
	var label := str(offer.get("label", ""))
	var actionable := bool(offer.get("actionable", false))
	print("standing at %s (%.0f, %.0f) after dark, the game offers: %s%s" % [
		str(target.name), spot.x, spot.z,
		("<nothing>" if label.is_empty() else label),
		("" if actionable else "  (NOT actionable)")])
	if not label.contains("Duskhush"):
		_fail("standing beside a night-gated Duskhush after dark, the game offers '%s' -- the player cannot meet it" % label)
	elif not actionable:
		_fail("the engage prompt for a night-gated Duskhush is offered but not actionable; pressing the button does nothing")
