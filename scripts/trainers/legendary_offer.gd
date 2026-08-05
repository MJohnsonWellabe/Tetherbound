extends Node3D

## The tethered legendary at the Meadows stronghold, and what happens when the
## Warden goes down.
##
## MEADOWS_VERTICAL_SLICE.md M14, last four bullets: "free tethered Ground
## legendary", "legendary offers to join", "triggers release ceremony when full",
## "superior ride ability". `GAME_DESIGN.md` §3 gives the order and this node
## follows it exactly — defeat the Warden, disable the tether, free the pal, it
## offers, and if the player already has five the ceremony opens.
##
## THE OFFER GOES THROUGH THE CATCH PATH. There is no second way into the party
## and no second ceremony.
##
## `EncounterDirector.offer_pal()` calls the same `_keep()` a catch calls, which
## calls `Party.add()`, which refuses a sixth with `REFUSED_PARTY_FULL`, which
## the director re-emits as `caught_refused(token, instance)`, which
## `scripts/pals/release_prompt.gd` has been listening to since M5 and opens
## `release_ceremony` on. Nothing in this file knows what a ceremony is.
##
## That is not tidiness, it is D13 and D16. The moment a legendary can enter the
## party by a route that is not `Party.add()`, the five-pal cap has an exception
## in it; the moment it can wait somewhere while the player thinks, it is stored;
## and the moment the ceremony can be skipped for a special creature, the game's
## one irreversible decision is optional. So the most important creature in the
## region arrives through the narrowest door in the codebase.
##
## THE CONSEQUENCE, STATED SO IT IS NOT A SURPRISE: with a full party the
## ceremony presents six, and the legendary is one of the six. The player may
## choose to release IT. That is D16's "cancel, made explicit", it is permanent,
## and there is no second offer — `_resolved` below is one-way. Special-casing
## the legendary out of that would be exactly the exception the two decisions
## exist to forbid.

const DATA := preload("res://scripts/trainers/tether_data.gd")
const DRESS := preload("res://scripts/trainers/tether_dress.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
const BODY_SCRIPT := preload("res://scripts/pals/pal_body.gd")
## M12's riding, looked up rather than preloaded. See `_report_the_ride()`.
const MOUNT_PATH := "res://scripts/pals/mount.gd"

## The tether has been cut. The story moment, before anything is decided.
signal freed(species_id: String)
## The offer was accepted and handed to the party. `kept` is whether it went
## straight in; false means the party was full and the ceremony now owns the
## decision.
signal offered(species_id: String, kept: bool)

const PROMPT_OFFER := "[X] / [E]   %s steps down to you"
const PROMPT_TETHERED := "%s is on the line. The Warden holds it."
## Free, and further away than the offer can be accepted from.
##
## This state was missing and the preview tool found it: `tools/preview_warden.gd`
## cut the tether, stood the player eight metres off, asked for the prompt and
## got back an empty string. A creature the player has just fought a boss to
## free, standing in the open saying nothing until they happen to walk inside
## seven metres of it, is a story moment the player can miss entirely.
const PROMPT_FREED := "%s is loose. It is watching you."

var _instance: RefCounted = null
var _body: Node3D = null
var _pylon: Node3D = null
var _cables: Array[Node3D] = []

var _player: Node3D = null
var _director: Node = null
var _world: Node = null

var _free: bool = false
var _resolved: bool = false
var _approach: Vector3 = Vector3.ZERO


func configure(player: Node3D, director: Node, world: Node) -> bool:
	_player = player
	_director = director
	_world = world

	var cfg: Dictionary = DATA.legendary()
	var species := str(cfg.get("species", ""))
	if not SPECIES.has(species):
		push_error(("the legendary species '%s' is not in the species table. " % species)
			+ "scripts/trainers/tether_roster.register() should have put it there; see "
			+ "data/trainers/species_addendum.json.")
		return false
	_instance = SPECIES.spawn(species, 0.0)
	if _instance == null:
		return false
	# No trait, for `trainer_battle`'s reason: a story reward whose stats depend
	# on a hidden roll is a different reward each time it is given.
	_instance.assign_trait("")
	return true


## Stand it on the bluff, wire it to a pylon, and put the cables on.
func raise_the_rig(at: Vector3, pylon_at: Vector3, approach: Vector3) -> void:
	_approach = approach

	_body = PAL_SCENE.instantiate()
	_body.name = "MeadowsLegendary"
	# `pal_body`, NOT `wild_pal`. It has no combat brain and no `wants_to_engage`
	# signal, so there is no code path anywhere that could turn it into an
	# opponent — which is what keeps §28's "the unique pal voluntarily offers to
	# join" from quietly also being a creature you could pick a fight with.
	_body.set_script(BODY_SCRIPT)
	add_child(_body)
	_body.call("setup", _instance.species_id)
	if not bool(_body.call("place_on_ground", at)):
		_body.global_position = at
	_body.call("face_towards", approach)

	_pylon = DRESS.pylon(self, _ground(pylon_at))
	var anchor: Vector3 = _pylon.global_position + Vector3.UP * 1.9
	var on_it: Vector3 = _body.call("centre")
	# Two cables rather than one. One reads as a leash; two read as a rig, and
	# §28 asks for equipment rather than for a rope.
	_cables.append(DRESS.cable(self, anchor, on_it + Vector3(0.35, 0.15, 0.0)))
	_cables.append(DRESS.cable(self, anchor, on_it - Vector3(0.35, -0.1, 0.0)))


func _ground(at: Vector3) -> Vector3:
	if _world == null or not _world.has_method("ground_height_at"):
		return at
	var height: float = float(_world.call("ground_height_at", at.x, at.z))
	return at if is_nan(height) else Vector3(at.x, height, at.z)


## --- the Warden goes down --------------------------------------------------

## Cut the tether. Wired to `tether_trainer.beaten`.
##
## §3's step 3 and 4 — "disable/free the tether mechanism", "free the unique pal"
## — are one action here and are deliberately not a puzzle. The Warden IS the
## mechanism's guard; beating him is disabling it. A separate lever to pull
## afterwards would be a second thing to build and a second thing to fail to find.
func cut_the_tether() -> void:
	if _free:
		return
	_free = true
	for cable in _cables:
		if is_instance_valid(cable):
			cable.queue_free()
	_cables.clear()
	# The machine stays standing and stops being live. The reserved accent going
	# dark is the one place in the game it is allowed to stop meaning Team Tether.
	DRESS.go_dark(_pylon)
	freed.emit(_instance.species_id if _instance != null else "")


func is_free() -> bool:
	return _free


func is_resolved() -> bool:
	return _resolved


func instance() -> RefCounted:
	return _instance


func body() -> Node3D:
	return _body


## --- the offer -------------------------------------------------------------

func can_accept() -> bool:
	if not _free or _resolved or _body == null or _player == null:
		return false
	return _body.global_position.distance_to(_player.global_position) <= float(
		DATA.legendary().get("offer_range", 7.0)
	)


func prompt_line() -> String:
	if _instance == null or _resolved:
		return ""
	var name := str(_instance.call("display"))
	if not _free:
		if _body == null or _player == null:
			return ""
		if _body.global_position.distance_to(_player.global_position) > 14.0:
			return ""
		return PROMPT_TETHERED % name
	if not can_accept():
		# Free, and out of reach of the offer. It still says something, at the same
		# range it announced itself from while it was on the line.
		if _body != null and _player != null \
			and _body.global_position.distance_to(_player.global_position) <= 20.0:
			return PROMPT_FREED % name
		return ""
	return PROMPT_OFFER % name


## Accept. One-way; see the header.
func accept() -> bool:
	if not can_accept():
		return false
	if _director == null or not _director.has_method("offer_pal"):
		push_error("the legendary was accepted and there is no director to hand it to; it is lost")
		return false

	_resolved = true
	var before: int = _party_size()
	# THE ONLY LINE THAT MATTERS IN THIS FILE. Straight into the same function a
	# catch goes through.
	_director.call("offer_pal", _instance)
	var kept: bool = _party_size() > before

	if _body != null:
		_body.visible = false
	_report_the_ride()
	offered.emit(_instance.species_id, kept)
	return true


func _party_size() -> int:
	if _director == null or not _director.has_method("caught"):
		return 0
	return (_director.call("caught") as Array).size()


## --- the ride --------------------------------------------------------------

## M14's "superior ride ability".
##
## THERE IS NO CODE HERE THAT MAKES THE LEGENDARY RIDEABLE, and that is the
## correct amount.
##
## M12's riding landed mid-milestone as `scripts/pals/mount.gd`, and its contract
## is entirely data: `mount.is_rideable(id)` reads `rideable` off the species
## definition and `mount.ride_data(id)` reads `ride`, and `ride_speed()`
## multiplies `movement.json`'s pace by that block's `speed_scale`. A species in
## the table carrying those two keys is rideable, from any party slot, with
## nothing registered and nothing wired. So the ride is declared where every
## other mount's is — in the species data — and this function only CHECKS and
## REPORTS.
##
## An earlier draft of this file, written before riding existed, invented a
## `register_ride(species_id, ride)` hand-off and a tree search to find something
## to call it on. Every field it would have passed was made up. It is deleted:
## a seam against an API that does not exist is not a seam, it is a guess, and
## when the real one arrived it did not match in any particular.
##
## `load()` rather than `preload()` on purpose — riding is another agent's file
## and is newer than this one, so a hard compile-time dependency on it would take
## this milestone down with any revert of theirs. If it is not there, the ride is
## reported as unavailable and the legendary is still a creature you own.
func _report_the_ride() -> void:
	var id: String = _instance.species_id
	var ride: Dictionary = SPECIES.definition(id).get("ride", {})
	var rideable := bool(SPECIES.definition(id).get("rideable", false))

	if not ResourceLoader.exists(MOUNT_PATH):
		print(("[tether] the legendary declares rideable=%s speed_scale=%.2f and there is no riding "
			% [rideable, float(ride.get("speed_scale", 1.0))])
			+ "system in this build (%s is missing). §28's ultimate mount is data only." % MOUNT_PATH)
		return

	var mount: GDScript = load(MOUNT_PATH) as GDScript
	if mount == null or not rideable:
		push_warning(("the legendary is not rideable (rideable=%s). §28 and M14 both require it to be "
			% rideable) + "the region's ultimate mount; check `rideable` in data/trainers/species_addendum.json.")
		return

	# Reported as a COMPARISON, because "superior ride ability" is a comparative
	# claim and a bare number cannot be checked against it by anybody reading a
	# log. `tests/test_trainer_battle.gd` asserts the same inequality.
	var canter: float = float(mount.call("ride_speed", id, false))
	var gallop: float = float(mount.call("ride_speed", id, true))
	var best_other := 0.0
	var best_id := ""
	for other: String in SPECIES.ids():
		if other == id or not bool(SPECIES.definition(other).get("rideable", false)):
			continue
		var theirs: float = float(mount.call("ride_speed", other, true))
		if theirs > best_other:
			best_other = theirs
			best_id = other
	print("[tether] the legendary rides at %.1f canter / %.1f gallop; best other mount (%s) gallops %.1f" % [
		canter, gallop, best_id if not best_id.is_empty() else "none", best_other
	])
	if canter <= best_other:
		push_warning("the legendary's free canter is not faster than every other mount's gallop; "
			+ "§28's 'substantially better traversal' is not true of this build")


## --- walking down ----------------------------------------------------------

## Once it is loose, it comes down to the player rather than waiting to be
## climbed to.
##
## The flank above the Warden's post runs 43 to 51 degrees against the character
## controller's 45-degree limit, so there is no route up there and there is not
## meant to be — `settlement.json` puts the ruin on the skyline precisely because
## it cannot be reached. A freed creature that stayed on the wrong side of that
## would be a reward the player can see and cannot collect.
func _physics_process(_delta: float) -> void:
	if not _free or _resolved or _body == null:
		return
	var to := _approach - _body.global_position
	to.y = 0.0
	if to.length() < 0.6:
		if _player != null:
			_body.call("face_towards", _player.global_position)
		return
	_body.call("request_move", to.normalized(), 2.4)
