extends SceneTree

## Drive a system through the real game and write down what it did.
##
##   godot --headless --path . --script tools/play_session.gd -- party
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/play_session.gd -- party
##
## This produces the evidence a blind judge reads (`.claude/skills/systems-judge`).
## It is not a test: it asserts nothing and it never fails. Its whole job is to
## exercise a system in the real scene and record what the game did, so that
## somebody who has not seen the code can decide whether the milestone's
## acceptance bullets are met.
##
## THE ONE RULE THIS FILE HAS: **log facts, never conclusions.**
##
## `party is full, refused: "you can only keep five"` is a fact. `the five-pal
## cap works correctly` is a conclusion, and writing it here would hand the judge
## the answer instead of the evidence — which is the entire thing the blind gate
## exists to prevent. If a line in this file could be wrong while the game is
## right, or right while the game is wrong, it does not belong here.
##
## The corollary is uncomfortable and deliberate: a bullet this session does not
## exercise comes back NOT SHOWN, and the judge treats that as a failure. A
## harness that quietly skips the hard part produces a transcript full of
## silences, and the rubric is written to refuse on silences.
##
## Input is driven through the real actions, like every smoke test, so a broken
## binding shows up here rather than on the handheld.

const SCENE := "res://scenes/world/meadows_playground.tscn"

## Long enough for terrain to stream, collision to build and the director to
## place its creatures. Same figure the smokes use.
const SETTLE_FRAMES := 240

var _log: PackedStringArray = []
var _system: String = ""
var _shots: int = 0
var _world: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_system = _requested_system()
	if _system == "":
		print("usage: play_session.gd -- <system>   (party | release | inventory | home)")
		quit(2)
		return

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	note("session: %s" % _system)
	note("scene: %s" % SCENE)

	match _system:
		"party":
			await _session_party()
		_:
			note("no session is written for '%s' yet" % _system)

	_write()
	quit(0)


## --- the sessions ---------------------------------------------------------
##
## Each one walks the acceptance bullets of its milestone in order and records
## what the game did at each step. Where a bullet cannot be exercised yet, it
## says so IN THE LOG rather than skipping quietly — an admitted gap is evidence,
## a silent one is a lie by omission.

## M4 — Party.
##
## Written from the acceptance bullets in `docs/MEADOWS_VERTICAL_SLICE.md`
## BEFORE the system was built, and deliberately not adjusted afterwards to suit
## what got built. That ordering is the point: a session written from the
## implementation only ever exercises the parts that happen to work, and its
## silences are exactly where the bugs live.
##
## It walks the ten bullets in order. Anything missing is reported as missing —
## `probe()` below never crashes on an absent API, because a session that dies
## halfway produces a short transcript that reads like a clean run.
func _session_party() -> void:
	var party: Object = _find("Party")
	var director: Object = _find("EncounterDirector")
	var save: Object = root.get_node_or_null(^"/root/SaveManager")

	note("--- bullet: catch pal ---")
	await _catch_one(party)

	note("--- bullet: up to five pals ---")
	note("capacity reported: %s" % probe(party, "capacity"))
	note("size before filling: %s" % probe(party, "size"))

	# Fill the rest, then push past the ceiling. The refusal IS the bullet — a cap
	# that only holds because nothing ever leans on it is not a cap.
	var species: Array = ["starter_ground", "wild_rabbit", "wild_bristler"]
	for i in 6:
		var id: String = species[i % species.size()]
		var added: Variant = _add_pal(party, id)
		note("add #%d (%s): accepted=%s  size now=%s" % [i + 1, id, added, probe(party, "size")])
	note("refusal message: %s" % probe(party, "last_refusal"))
	note("size after pushing past the ceiling: %s" % probe(party, "size"))

	note("--- bullet: nickname ---")
	var to_name: Object = _member(party, 0)
	if to_name == null:
		note("no member to rename")
	else:
		note("name before renaming: %s (nickname field: '%s')" % [
			probe(to_name, "display"), field(to_name, "nickname")
		])
		# A name nothing could mistake for a default or a slot label. The first
		# version of this session named every pal "Pal1".."Pal5" as it added them,
		# which a blind reviewer correctly read as positional labels rather than
		# as evidence anybody could rename anything.
		note("rename to 'Thistle' accepted: %s" % probe(to_name, "rename", ["Thistle"]))
		note("name after renaming: %s (nickname field: '%s')" % [
			probe(to_name, "display"), field(to_name, "nickname")
		])
		# The refusal: an all-whitespace name must not leave a nameless pal.
		note("rename to '   ' accepted: %s" % probe(to_name, "rename", ["   "]))
		note("name after the refused rename: %s" % probe(to_name, "display"))
		note("other members are still unnamed: %s, %s" % [
			probe(_member(party, 1), "display"), probe(_member(party, 2), "display")
		])

	note("--- bullet: levels, HP/ATK/DEF, trait, nickname, appraisal ---")
	var first: Object = _member(party, 0)
	if first == null:
		note("no member at index 0; per-pal bullets unevidenced")
	else:
		note("member 0 display: %s" % probe(first, "display"))
		for name: String in ["level", "xp", "nickname", "trait_id", "hp", "max_hp", "attack", "defence"]:
			note("member 0 %s: %s" % [name, field(first, name)])
		note("member 0 appraisal: %s" % [probe(first, "appraisal")])
		if first.has_method("grant_xp"):
			var before: Variant = field(first, "level")
			first.call("grant_xp", 100000)
			note("after granting 100000 xp: level %s -> %s, max_hp now %s" % [
				before, field(first, "level"), field(first, "max_hp")
			])
		else:
			note("grant_xp: ABSENT — levelling unevidenced")

	note("--- bullet: switching ---")
	note("active index before: %s" % field(party, "active_index"))
	note("set_active(2) accepted: %s" % probe(party, "set_active", [2]))
	note("active index after: %s" % field(party, "active_index"))
	note("set_active(99) accepted: %s" % probe(party, "set_active", [99]))
	note("active index after out-of-range: %s" % field(party, "active_index"))

	note("--- bullet: persistent party data ---")
	var before_records: Variant = probe(party, "to_records")
	note("records before save: %s" % [before_records])
	if save != null and save.has_method("save"):
		note("save() returned: %s" % save.call("save", 0))
		# Clear in memory, then reload. Reading back a number the same object
		# still holds proves nothing about persistence.
		if party.has_method("clear"):
			party.call("clear")
			note("size after clearing in memory: %s" % probe(party, "size"))
		note("load_slot(0) returned: %s" % save.call("load_slot", 0))
		note("size after reload: %s" % probe(party, "size"))
		note("records after reload: %s" % [probe(party, "to_records")])
	else:
		note("SaveManager.save: ABSENT — persistence unevidenced")

	note("--- bullet: simple party menu ---")
	await _open_party_menu()


## Open the party screen through the real input action, not by instancing it.
## A screen that only appears when a test constructs it is not reachable by a
## player.
func _open_party_menu() -> void:
	await _tap("party_menu")
	var stack: Object = _find("ScreenStack")
	if stack == null:
		note("ScreenStack: ABSENT — no screen opened")
	else:
		note("screen open after pressing 'party_menu': %s" % probe(stack, "is_open"))
		var top: Variant = probe(stack, "top")
		note("top screen: %s" % (top.name if top is Node else top))
	await shot("party_menu")

	# Move the selection and photograph it again, so the judge can see whether
	# selection is visible at all.
	#
	# Held for several frames rather than one. A single-physics-frame press is
	# 1/60th of a second, which is shorter than any tap a person can make, and a
	# menu that required one would be unusable — so a one-frame press tests the
	# harness's timing rather than the menu's.
	await _tap("move_back")
	await shot("party_menu_moved")

	await _tap("menu_cancel")
	if stack != null:
		note("screen open after 'menu_cancel': %s" % probe(stack, "is_open"))


## Catch a wild pal for real: walk to it, engage, weaken it, throw until it
## resolves, and report the party before and after.
##
## The first version of this session skipped all of that and logged
## `director reports caught: 5` — a counter printed by the system that owns it,
## immediately after five direct roster insertions. The blind judge called it
## "consistent with the counter simply counting adds" and refused the bullet.
## It was right: a number a system reports about itself is not evidence that the
## thing happened.
func _catch_one(party: Object) -> void:
	var director: Object = _find("EncounterDirector")
	var manager: Object = _find("CombatManager")
	var player: CharacterBody3D = _find("Player") as CharacterBody3D
	var rig: Node3D = _find("CameraRig") as Node3D
	if director == null or manager == null or player == null:
		note("cannot attempt a catch: director/manager/player missing")
		return

	var wild: Node3D = null
	var wilds: Variant = probe(director, "wild_pals")
	if wilds is Array and not (wilds as Array).is_empty():
		wild = (wilds as Array)[0]
	if wild == null:
		note("no wild pal in the world to catch")
		return
	note("target: %s at %.0f, %.0f" % [wild.name, wild.global_position.x, wild.global_position.z])
	note("party size before the catch: %s" % probe(party, "size"))

	# Walk to it, then engage.
	for i in 1500:
		var to: Vector3 = wild.global_position - player.global_position
		to.y = 0.0
		if to.length() <= 4.0:
			break
		if rig != null:
			rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame
	await _tap("interact")
	note("fight started: %s" % probe(manager, "is_fighting"))
	if not bool(probe(manager, "is_fighting")):
		note("could not start a fight; the catch is unevidenced")
		return

	# The hard rule, checked where it lives: a pal you already own cannot be
	# caught. CLAUDE.md states it and catch_math enforces it.
	var catch_math := load("res://scripts/combat/catch_math.gd")
	note("can a trainer-owned pal be caught? %s" % catch_math.can_be_caught(false, true))
	note("can a fainted wild pal be caught? %s" % catch_math.can_be_caught(true, false))
	note("can a healthy wild pal be caught? %s" % catch_math.can_be_caught(false, false))

	var foe: Object = probe(manager, "enemy")
	var before: int = int(probe(party, "size"))
	var throws := 0
	for attempt in 40:
		if not bool(probe(manager, "is_fighting")):
			break
		# Weakened directly rather than by fighting: this is evidence about
		# catching, and grinding it down through combat would be evidence about
		# combat. smoke_catching does the same for the same reason.
		if foe != null:
			foe.set("hp", float(foe.get("max_hp")) * 0.08)
		var aim: Object = probe(manager, "throw_aim")
		if aim != null and int(probe(manager, "orbs_left")) <= 1:
			aim.call("refill")
		var pal: Object = probe(manager, "active_pal")
		if pal != null:
			pal.set("hp", float(pal.get("max_hp")))
		if not await _throw_at(manager, player, rig, wild):
			continue
		throws += 1
		for i in 240:
			await physics_frame
			if int(probe(party, "size")) > before:
				break
		if int(probe(party, "size")) > before:
			break

	note("throws made: %d" % throws)
	note("fight outcome: %s" % probe(manager, "outcome"))
	note("party size after the catch: %s" % probe(party, "size"))
	var caught_member: Object = _member(party, before)
	if caught_member != null:
		note("caught creature is now party member %d: %s (%s)" % [
			before, probe(caught_member, "display"), field(caught_member, "species_id")
		])
	# Leave the fight so the rest of the session is not run inside one.
	for i in 200:
		await physics_frame
		if not bool(probe(manager, "is_fighting")):
			break


## Open the aim, point it at the creature, and release.
##
## The orb flies on a real arc, so aiming straight at the target undershoots by
## the drop over the flight — a player compensates by eye and this has to do it
## by arithmetic. Aimed through the camera rig rather than by handing the orb a
## direction, so a broken aim camera shows up here instead of being quietly
## worked around. Same approach `smoke_catching` uses, for the same reason.
func _throw_at(manager: Object, player: Node3D, rig: Node3D, wild: Node3D) -> bool:
	if not bool(probe(manager, "is_aiming")):
		await _tap("combat_throw")
	if not bool(probe(manager, "is_aiming")):
		return false

	var catch_cfg := load("res://scripts/combat/catch_math.gd")
	var cfg: Dictionary = catch_cfg.config().get("throw", {})
	var speed := float(cfg.get("speed", 17.0))
	var gravity := float(cfg.get("gravity", 14.0))
	var origin: Vector3 = player.global_position + Vector3.UP * float(cfg.get("spawn_height", 1.5))
	var centre: Vector3 = wild.call("centre") if wild.has_method("centre") else wild.global_position
	var to: Vector3 = centre - origin
	var flat := Vector2(to.x, to.z).length()
	if rig != null:
		rig.set("yaw", atan2(-to.x, -to.z))
		var flight := flat / maxf(speed, 0.01)
		rig.set("pitch", atan2(to.y + 0.5 * gravity * flight * flight, maxf(flat, 0.01)))
	for i in 4:
		await physics_frame
	await _tap("combat_throw")
	return true


## Press an action the way a person would, and let the game settle.
func _tap(action: String) -> void:
	Input.action_press(action)
	for i in 8:
		await physics_frame
	Input.action_release(action)
	for i in 14:
		await physics_frame


## --- probes ---------------------------------------------------------------
##
## Everything below refuses to crash. An absent method is a FACT about the
## build and belongs in the transcript; an exception is a truncated transcript
## that a reader cannot tell apart from a short clean run.

func _find(node_name: String) -> Object:
	if _world == null:
		return null
	var direct: Node = _world.get_node_or_null(NodePath(node_name))
	if direct != null:
		return direct
	var found: Array[Node] = _world.find_children(node_name, "", true, false)
	return found[0] if not found.is_empty() else null


func probe(target: Object, method: String, args: Array = []) -> Variant:
	if target == null:
		return "<no object>"
	if not target.has_method(method):
		return "<no method %s>" % method
	return target.callv(method, args)


func field(target: Object, property: String) -> Variant:
	if target == null:
		return "<no object>"
	var value: Variant = target.get(property)
	return value if value != null else "<no property %s>" % property


func _member(party: Object, index: int) -> Object:
	var got: Variant = probe(party, "at", [index])
	return got if got is Object else null


## Build a pal and offer it to the party. Kept here rather than in the party so
## the session does not depend on a convenience method the system might not have.
func _add_pal(party: Object, species_id: String) -> Variant:
	var species := load("res://scripts/pals/pal_species.gd")
	if species == null or not party.has_method("add"):
		return "<cannot add>"
	var instance: Variant = species.spawn(species_id)
	if instance == null:
		return "<spawn failed for %s>" % species_id
	# Deliberately NOT named here. The first version of this session set every
	# nickname as it added the pal, which made "nickname" indistinguishable from
	# "positional label" in the transcript — a blind reviewer read Pal1..Pal5,
	# matched them to the slot indices, and refused the bullet. A nickname is
	# only evidence when the player set it.
	return party.call("add", instance)


## --- recording ------------------------------------------------------------

## One observed fact. Printed as well as stored, so a crashed session still
## leaves everything it got as far as.
func note(line: String) -> void:
	_log.append(line)
	print("  %s" % line)


## A numbered frame, for anything the judge has to look at rather than read.
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		note("frame '%s': not captured (headless)" % label)
		return
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		note("frame '%s': capture failed" % label)
		return
	_shots += 1
	var path := "res://shots/session_%s_%02d_%s.png" % [_system, _shots, label]
	image.save_png(path)
	note("frame '%s' -> %s" % [label, path])


func _write() -> void:
	var path := "res://shots/session_%s.log" % _system
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("could not write %s" % path)
		return
	file.store_string("\n".join(_log) + "\n")
	print("wrote %s (%d lines, %d frames)" % [path, _log.size(), _shots])


## Everything after `--`, so Godot's own arguments are not mistaken for ours.
func _requested_system() -> String:
	var args := OS.get_cmdline_user_args()
	return str(args[0]) if args.size() > 0 else ""
