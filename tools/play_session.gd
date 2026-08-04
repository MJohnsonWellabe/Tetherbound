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

	note("--- bullet: up to five pals ---")
	note("party node present: %s" % (party != null))
	note("save manager present: %s" % (save != null))
	if party == null:
		note("no party system in the scene; every bullet below is unevidenced")
		return
	note("capacity reported: %s" % probe(party, "capacity"))
	note("size at start: %s" % probe(party, "size"))

	# Fill it, then overfill it. The refusal is the bullet — a cap that only
	# holds because nothing ever pushes on it is not a cap.
	var species: Array = ["starter_ground", "wild_rabbit", "wild_bristler"]
	for i in 6:
		var id: String = species[i % species.size()]
		var added: Variant = _add_pal(party, id, "Pal%d" % (i + 1))
		note("add #%d (%s): accepted=%s  size now=%s" % [i + 1, id, added, probe(party, "size")])
	note("refusal message: %s" % probe(party, "last_refusal"))
	note("size after six attempts: %s" % probe(party, "size"))

	note("--- bullet: levels, HP/ATK/DEF, trait, nickname, appraisal ---")
	var first: Object = _member(party, 0)
	if first == null:
		note("no member at index 0; per-pal bullets unevidenced")
	else:
		note("member 0 display: %s" % probe(first, "display"))
		for name: String in ["level", "xp", "nickname", "trait_id", "hp", "max_hp", "attack", "defence"]:
			note("member 0 %s: %s" % [name, field(first, name)])
		note("member 0 appraisal: %s" % probe(first, "appraisal"))
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
	note("records before save: %s" % before_records)
	if save != null and save.has_method("save"):
		note("save() returned: %s" % save.call("save", 0))
		# Clear in memory, then reload. Reading back a number the same object
		# still holds proves nothing about persistence.
		if party.has_method("clear"):
			party.call("clear")
			note("size after clearing in memory: %s" % probe(party, "size"))
		note("load_slot(0) returned: %s" % save.call("load_slot", 0))
		note("size after reload: %s" % probe(party, "size"))
		note("records after reload: %s" % probe(party, "to_records"))
	else:
		note("SaveManager.save: ABSENT — persistence unevidenced")

	note("--- bullet: catch pal ---")
	if director != null and director.has_method("caught"):
		note("director reports caught: %s" % director.call("caught").size())
	else:
		note("director caught(): ABSENT")

	note("--- bullet: simple party menu ---")
	await _open_party_menu()


## Open the party screen through the real input action, not by instancing it.
## A screen that only appears when a test constructs it is not reachable by a
## player.
func _open_party_menu() -> void:
	Input.action_press("inventory")
	await physics_frame
	Input.action_release("inventory")
	for i in 20:
		await physics_frame
	var stack: Object = _find("ScreenStack")
	if stack == null:
		note("ScreenStack: ABSENT — no screen opened")
	else:
		note("screen open after pressing 'inventory': %s" % probe(stack, "is_open"))
		var top: Variant = probe(stack, "top")
		note("top screen: %s" % (top.name if top is Node else top))
	await shot("party_menu")

	# Move the selection and photograph it again, so the judge can see whether
	# selection is visible at all.
	Input.action_press("move_back")
	await physics_frame
	Input.action_release("move_back")
	for i in 12:
		await physics_frame
	await shot("party_menu_moved")

	Input.action_press("menu_cancel")
	await physics_frame
	Input.action_release("menu_cancel")
	for i in 12:
		await physics_frame
	if stack != null:
		note("screen open after 'menu_cancel': %s" % probe(stack, "is_open"))


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
func _add_pal(party: Object, species_id: String, nickname: String) -> Variant:
	var species := load("res://scripts/pals/pal_species.gd")
	if species == null or not party.has_method("add"):
		return "<cannot add>"
	var instance: Variant = species.spawn(species_id)
	if instance == null:
		return "<spawn failed for %s>" % species_id
	if "nickname" in instance:
		instance.nickname = nickname
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
