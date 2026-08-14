extends RefCounted

## The one place the opening sequence touches the party.
##
## **This is a seam, not a party.** CLAUDE.md's first hard rule is five creatures
## total and no storage beyond five, and the party that enforces it lives in
## `autoload/party.gd`, held by the `Game` autoload. This file's only job is to
## put a chosen or caught creature in there, and to keep working in a test process
## where the autoload is not running at all.
##
## ## The bug this file used to have, written down so it is not reintroduced
##
## The seam was written before the party landed, against a guess at its shape,
## and the guess was wrong in two ways that cancelled each other out into
## silence:
##
##   1. it looked up `/root/GameState`. The autoload is registered as **`Game`**
##      (project.godot `[autoload]`, docs/decisions/D14). The lookup never hit.
##   2. it called `add_creature()` / `party()` / `party_is_full()` on it. The real
##      API is `Game.party.add()` / `.members()` / `.is_full()`.
##
## Either defect alone pins the seam to its fallback forever, and the fallback
## is a five-slot array — so the seam looked healthy from the outside while
## running **a second, phantom party beside the real one**. A creature chosen in the
## opening never reached `Game.party`, and nothing said so: the party screen
## simply showed an empty party after the naming beat.
##
## Two rules come out of that, and both are enforced below:
##
##   - **A party that is present must be a party the seam binds to.** There was
##     no assertion to that effect anywhere; the test that should have said it
##     said `assert_true(answer or not answer)` instead, which is true whatever
##     the seam does. `tests/test_party_seam.gd` now asserts it in both
##     directions, and `tests/smoke_opening.gd` asserts it against the genuine
##     autoload in a booted scene.
##   - **Bind to the real party all-or-nothing.** If `Game.party` is there but
##     does not answer the whole interface, that is shouted about rather than
##     quietly worked around. A seam that binds `add()` but falls back for
##     `members()` is the phantom party again, one method at a time.
##
## The fallback stays, because the seam's purpose is to work either way: the
## unit suite runs under `--script`, which starts no autoloads at all, and the
## opening has to be playable in that process. It is deliberately NOT a party —
## a flat list and a refusal at five, exactly enough for the opening to play end
## to end and far too little to be mistaken for the real thing or to grow into
## storage.

## The autoload's node name, and the ONLY spelling of it in this file. It is the
## name in project.godot's `[autoload]` section and nothing else; keep those two
## in step and the seam works, let them drift and the opening quietly grows a
## second party again.
##
## Relative, not `/root/Game`. An absolute path is an engine error when there is
## no active scene tree, which is the unit runner's normal state — so fixing the
## name alone would have swapped a silent bug for a wall of errors.
const GAME_NODE := ^"Game"

## Mirrors `autoload/party.gd`'s MAX_CREATURES so a caller can ask without reaching
## for the autoload. The real limit is the party's to enforce; this is the number
## the seam refuses at while there is no party to ask. The two are asserted equal
## in the tests, because a fallback that allowed six would be a storage system.
const PARTY_LIMIT := 5

## The opening's own record, used only while there is no `Game`. Static so it
## survives the sequence director being freed, and cleared by `reset()` in tests.
static var _fallback: Array[RefCounted] = []

## Where to look for the autoload, when it is not the running tree's root.
##
## Null in the game, always. It exists because `Engine.get_main_loop()` is
## **null** throughout `tests/run_tests.gd` — the unit runner does all of its
## work inside `SceneTree._init()`, before the engine has installed the main loop
## — so without this there is no way for a unit test to put a party anywhere the
## seam would look, and the real path could only ever be covered by the
## scene-booting smoke tests.
##
## That is not a hypothetical cost. The seam having NO unit coverage of its real
## path is exactly how it shipped looking up a node name that does not exist. A
## four-line hook is cheaper than that happening a second time.
##
## Set by `set_root_for_tests`, cleared by `reset()`.
static var _root_override: Node = null


## The node whose children are searched for `Game`.
static func _search_root() -> Node:
	if _root_override != null:
		return _root_override
	var loop := Engine.get_main_loop() as SceneTree
	return loop.root if loop != null else null


## The real party, or null when there is none to bind to.
##
## Relative lookup from the scene root: an absolute `/root/...` path is an error
## when there is no active scene tree, which is exactly the case in the unit
## runner — the seam would have started pushing engine errors on every call the
## moment somebody fixed the node name alone.
static func _party() -> RefCounted:
	var root := _search_root()
	if root == null:
		return null
	var game: Node = root.get_node_or_null(GAME_NODE)
	if game == null:
		return null
	var party := game.get("party") as RefCounted
	if party == null:
		return null

	# All-or-nothing. A `Game.party` that cannot answer the whole interface is a
	# real breakage — most likely somebody renaming a method on autoload/party.gd
	# — and falling back would hide it behind a party that looks like it works.
	for required in ["add", "members", "is_full"]:
		if not party.has_method(required):
			push_error(
				"Game.party has no %s(); the opening cannot use the real party " % required
				+ "and is falling back to its own list. Fix the call in scripts/story/party_seam.gd."
			)
			return null
	return party


## Is the real party in the tree and usable? False means every call below is
## being served by the fallback.
static func has_game_state() -> bool:
	return _party() != null


## Give a caught or chosen creature its name and put it in the party.
##
## Returns false when the party is full. The opening can never see that — it
## adds two creatures to an empty party — but the caller is told rather than assuming,
## because the sixth-creature release ceremony is real design (GAME_DESIGN.md §3) and
## a seam that silently drops a creature would hide the day it starts mattering.
static func add(instance: RefCounted, nickname: String = "") -> bool:
	if instance == null:
		return false
	set_nickname(instance, nickname)

	var party := _party()
	if party != null:
		return bool(party.call("add", instance))

	if _fallback.size() >= PARTY_LIMIT:
		return false
	_fallback.append(instance)
	return true


## Name a creature.
##
## Writes `nickname`, which is the field `creature_instance.label()` reads and every
## nameplate goes through. It does NOT write `display_name`: that is the species
## name, and `tests/test_creature_nickname.gd` requires it to survive being nicknamed
## over, because the party screen has to be able to tell a Terrapup nobody
## renamed from one deliberately named "Terrapup".
##
## The `display_name` write is kept only for an instance with no `nickname`
## field at all, which no longer happens in this tree and is the last remnant of
## the same wrong guess documented at the top of this file. It is a fallback, not
## the path: naming through it is visible but lossy.
static func set_nickname(instance: RefCounted, nickname: String) -> void:
	if instance == null or nickname == "":
		return
	if "nickname" in instance:
		instance.set("nickname", nickname)
		return
	instance.display_name = nickname


## What the player is carrying. The real party's members when there is one, the
## opening's own list otherwise. A copy either way — nothing joins a party by
## being appended to the array this hands back.
static func party() -> Array:
	var party_manager := _party()
	if party_manager != null:
		return party_manager.call("members") as Array
	return _fallback.duplicate()


static func size() -> int:
	return party().size()


static func is_full() -> bool:
	var party_manager := _party()
	if party_manager != null:
		return bool(party_manager.call("is_full"))
	return size() >= PARTY_LIMIT


## Only for tests and for starting the opening over.
##
## Clears the fallback, and the test root hook. It does NOT empty the real party:
## that belongs to `Game` and outlives any one run of the opening, and a helper
## that quietly removed creatures would be a delete path CLAUDE.md puts at a release
## ceremony (M5). A test that wants the real party gone takes the whole thing
## away itself, in the open, where it can be seen.
static func reset() -> void:
	_fallback.clear()
	_root_override = null


## Point the seam at a node that stands in for the scene root, so a unit test can
## put a `Game` where the seam looks. See `_root_override` for why this cannot be
## done through the tree. Pass null, or call `reset()`, to put it back.
static func set_root_for_tests(root: Node) -> void:
	_root_override = root
