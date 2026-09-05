extends SceneTree

## OP-0904-3 / CL-O3's third item, the half that needs a creature standing in
## the world.
##
##   godot --headless --path . --script tests/smoke_riding_saddle.gd
##
## Owner, playing the shipped build: *"Nothing that is rideable should come with
## a saddle on it. You have to build the saddle and put it on then it visually
## appears. It shouldn't visually be there."*
##
## `tests/test_riding_saddle.gd` holds the data half — which species the saddle
## belongs on, what a fit is, that it survives a save. This is the half only a
## body can answer, for EVERY species carrying a `rideable` block:
##
##   1. it stands up wearing nothing
##   2. with an empty satchel, fitting is refused and it still wears nothing
##   3. with the saddle built, fitting puts exactly one on
##   4. and it is STILL wearing it after being dismissed and called back out —
##      the bug this replaced was a saddle that existed only while you were
##      sitting on the animal, which is every moment except the ones a player
##      actually looks at their creature
##
## Driven through the REAL playground and the REAL encounter director rather
## than by parenting a creature scene to the root: the director's summon is the
## only path a creature ever reaches the world by, and it is the path that
## destroys and rebuilds the body on every dismiss — which is exactly what
## claim 4 is about.
##
## The roster is read from `data/creatures/species.json`. The brief names
## Terrapup, Tuskroot and Burrowback as the roster CL-O9's design contract will
## decide; this lane must not decide it, so this tests whatever the data says
## today and keeps testing it tomorrow.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")
const SETTLE_FRAMES := 300

var _failures: Array[String] = []
var _world: Node = null
var _director: Node = null
var _riding: Node = null
var _party: RefCounted = null
var _bag: RefCounted = null
var _progression: RefCounted = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_director = _world.get_node_or_null(^"EncounterDirector")
	_riding = _world.get_node_or_null(^"RidingController")
	var game := root.get_node_or_null(^"/root/Game")
	if _director == null or _riding == null or game == null:
		_fail("the playground is missing the encounter director, the riding controller or Game")
		_report()
		return
	_party = game.get("party")
	_bag = game.get("inventory")
	_progression = game.get("progression")
	if _party == null or _bag == null or _progression == null:
		_fail("Game has no party, inventory or progression store; the saddle rule cannot be driven")
		_report()
		return

	var rideable := _rideable_species()
	if rideable.is_empty():
		_fail("species.json declares no rideable species; there is nothing to check")
		_report()
		return
	print("rideable species in the data: %s" % ", ".join(rideable))

	for species_id in rideable:
		await _the_rule_holds_for(species_id)
	_report()


func _the_rule_holds_for(species_id: String) -> void:
	# Every species starts un-fitted with an empty satchel, whatever the last
	# one left behind — otherwise the second species inherits the first's state
	# and the "before" half measures nothing.
	_progression.call("set_flag", RIDING.saddle_fitted_flag(species_id), false)
	var saddles := int(_bag.call("count", "saddle"))
	if saddles > 0:
		_bag.call("remove", "saddle", saddles)

	var body := await _bring_out(species_id)
	if body == null:
		return
	var belongs := RIDING.saddle_belongs_on(species_id)

	# 1. NEVER AT SPAWN. The whole subtree, not just direct children: a saddle
	#    baked into a creature's own .glb would be a grandchild and would pass a
	#    shallow check while sitting visibly on the animal.
	var at_spawn := _saddle_nodes(body)
	if at_spawn > 0:
		_fail("%s stands up wearing %d saddle node(s); a rideable creature must come with none"
			% [species_id, at_spawn])

	# 2. BUILT FIRST. Nothing in the satchel, so nothing can be put on.
	if bool(_riding.call("fit_saddle", body)):
		_fail("%s was saddled with an empty satchel; the craft is meant to be the permission" % species_id)
	for i in 6:
		await physics_frame
	if _saddle_nodes(body) > 0:
		_fail("%s is wearing a saddle nobody built" % species_id)

	# 3. THEN IT APPEARS — exactly once.
	_bag.call("add", "saddle", 1)
	var fitted := bool(_riding.call("fit_saddle", body))
	if belongs and not fitted:
		_fail("%s wants a saddle, one is in the satchel, and fitting it was refused" % species_id)
	if not belongs and fitted:
		_fail("%s needs no tack and a saddle was fitted to it anyway" % species_id)
	for i in 6:
		await physics_frame
	var worn := _saddle_nodes(body)
	if belongs and worn != 1:
		_fail("%s carries %d saddle node(s) after being fitted; expected exactly one" % [species_id, worn])
	if not belongs and worn != 0:
		_fail("%s carries %d saddle node(s) and needs no tack at all" % [species_id, worn])
	if belongs and not RIDING.saddle_is_fitted(species_id):
		_fail("%s was fitted and the saved flag store does not agree" % species_id)

	# 4. AND IT STAYS. Dismissed and called back out is a brand-new body from
	#    the director; the controller's own per-frame refresh has to put the
	#    saddle back on it with nobody asking.
	_director.call("dismiss_active_creature")
	for i in 30:
		await physics_frame
	await _director.call("summon_active_creature")
	var again: Node3D = null
	for i in 120:
		await physics_frame
		again = _director.call("ally_body")
		if again != null and is_instance_valid(again) and again.visible:
			break
	if again == null or not is_instance_valid(again):
		_fail("%s never came back out after being dismissed" % species_id)
		return
	# A few more frames for the controller's refresh, which is a physics tick
	# and not a summon callback on purpose (see `_refresh_worn_saddle`).
	for i in 10:
		await physics_frame
	var after_resummon := _saddle_nodes(again)
	if belongs and after_resummon != 1:
		_fail("%s carries %d saddle node(s) after being called back out; the fitted saddle did not survive the resummon"
			% [species_id, after_resummon])
	if not belongs and after_resummon != 0:
		_fail("%s picked up %d saddle node(s) on a resummon" % [species_id, after_resummon])

	# 5. AND IT GOES AWAY IF THE FIT IS UNDONE. The mirror of claim 1: the
	#    refresh has to be a rule, not a one-way switch, or an un-fitted saddle
	#    is a saddle nothing can ever take off.
	_progression.call("set_flag", RIDING.saddle_fitted_flag(species_id), false)
	for i in 10:
		await physics_frame
	if _saddle_nodes(again) > 0:
		_fail("%s is still wearing a saddle after the fit was cleared" % species_id)

	print("  %s: %s" % [species_id,
		"none at spawn, none unbuilt, one fitted, one after a resummon, none once unfitted" if belongs
		else "needs no tack, and never wears one"])


## Put `species_id` in the party, make it active and bring it out through the
## director's real summon.
func _bring_out(species_id: String) -> Node3D:
	if _director.call("ally_body") != null:
		_director.call("dismiss_active_creature")
		for i in 30:
			await physics_frame
	var instance: RefCounted = SPECIES.spawn(species_id)
	if instance == null:
		_fail("could not spawn a %s" % species_id)
		return null
	if not bool(_party.call("add", instance)):
		_fail("the party would not take a %s (it holds %d)" % [species_id, int(_party.call("size"))])
		return null
	for i in int(_party.call("size")):
		if _party.call("at", i) == instance:
			_party.call("set_active", i)
			break
	await _director.call("summon_active_creature")
	for i in 150:
		await physics_frame
		var body: Node3D = _director.call("ally_body")
		if body != null and is_instance_valid(body) and body.visible \
				and str(body.get("species_id")) == species_id:
			return body
	_fail("the %s never stood up in the world" % species_id)
	return null


## Every species with a `rideable` block, from the real data file.
func _rideable_species() -> Array[String]:
	var found: Array[String] = []
	var file := FileAccess.open("res://data/creatures/species.json", FileAccess.READ)
	if file == null:
		return found
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return found
	var table: Variant = (parsed as Dictionary).get("species", {})
	if not table is Dictionary:
		return found
	for id: String in (table as Dictionary):
		if id.begins_with("_"):
			continue
		if SPECIES.is_rideable(id):
			found.append(id)
	found.sort()
	return found


## How many nodes anywhere under `node` are a saddle. Whole subtree, by name and
## by any name containing "saddle": one baked into a creature's own model would
## be neither a direct child nor named by us, and that is the case the owner's
## "it shouldn't visually be there" is actually about.
func _saddle_nodes(node: Node) -> int:
	var count := 0
	var name := str(node.name).to_lower()
	if name.contains("saddle") and not name.ends_with("removed"):
		count += 1
	for child in node.get_children():
		count += _saddle_nodes(child)
	return count


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("riding saddle: OK — never at spawn, built before fitted, one once fitted, still there after a resummon.")
		quit(0)
		return
	for line in _failures:
		print("riding saddle FAIL: %s" % line)
	quit(1)
