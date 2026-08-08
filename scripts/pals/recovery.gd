extends Node

## What it takes to get a pal back on its feet.
##
## GAME_DESIGN.md §16, in full, is four lines: a pal at 0 HP passes out, is
## unavailable, and DOES NOT AUTO-REVIVE WITH TIME IN THE FIELD; it comes back
## from a special revival item, or from recovery in its physical pal bed at home.
## Beds also speed normal HP recovery and contribute to rest and bond. This file
## is those four lines and nothing else.
##
## Until it existed the rule was unreachable in the other direction: nothing in
## the game could leave a pal fainted, because `encounter_director` healed the
## whole party every time a fight ended. Deleting that loop is what makes the
## faint real; this is what makes it survivable.
##
## THE TWO ROUTES BACK, and they are deliberately unequal:
##
##   * `revive_with_item()` — instant, and finite. There is no recipe and no drop
##     table, so the draughts the player starts with are all the draughts there
##     are. Spending one is the decision the item exists to create.
##   * `rest()` — free, and slow. A bed takes `bed_revive_seconds` to bring a
##     fainted pal round and then heals it at `bed_hp_per_second`, both from
##     data/config/party.json. Instant recovery at a bed would be the blanket
##     heal again with extra steps.
##
## A PAL BED IS NOT A JOB, and this is the file most likely to break that hard
## rule by accident, because "a system that puts creatures in buildings" is the
## exact shape of one. So, explicitly: `begin_rest()` is called INTO the bed from
## here and the bed never reaches out; a bed has no output, no throughput and no
## assignment; and a resting pal produces nothing whatsoever. What a pal gets out
## of a bed is its own health back. `tests/test_stations.gd` has
## `test_no_station_can_be_told_to_work`, and nothing here may make it fail.
##
## No tree required for the rules. `tick()`, `rest()`, `wake()` and the save
## round trip all work on loose objects, which is how `tests/test_recovery.gd`
## proves them without a scene — docs/decisions/D02. Only the visible body needs
## a world, and its absence degrades to "recovery works, you cannot see it".

const PARTY := preload("res://scripts/pals/party.gd")
## For `data/config/party.json`, through the one reader of it.
const PAL := preload("res://scripts/pals/pal_instance.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const STATION := preload("res://scripts/building/station.gd")
const INVENTORY := preload("res://scripts/items/inventory.gd")
const DEFS := preload("res://scripts/items/item_defs.gd")
## The same body and the same scene the encounter director deploys a fighter
## with. A resting pal is the creature the player owns, not a second kind of
## thing that happens to look like it.
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
const BODY_SCRIPT := preload("res://scripts/pals/pal_body.gd")

## The key this system owns inside `SaveManager`'s one envelope.
##
## A pal left asleep has to still be asleep after a reload, or the save has
## quietly ended a recovery the player was waiting out. The pals themselves come
## back through the `party` domain and the beds through `structures`, so what is
## written here is only the JOIN between them plus how far along each nap is.
const SAVE_DOMAIN := "recovery"

## How long a restored nap keeps trying to find its pal and its bed. Generous:
## `structures.load_data()` rebuilds every placed piece, and a large village
## takes more than one frame.
const PENDING_SECONDS := 5.0

## Why the last call was refused, as a stable token — `party.gd`'s idiom, and its
## reason holds: this file has no business knowing how a refusal is worded.
const REFUSED_NOT_A_PAL := "not_a_pal"
const REFUSED_ALREADY_RESTING := "already_resting"
const REFUSED_NOTHING_TO_DO := "nothing_to_do"
const REFUSED_NO_HOME := "no_home"
const REFUSED_NO_BED := "no_free_pal_bed"
const REFUSED_NOT_DOWN := "not_down"
const REFUSED_NO_ITEM := "no_revival_item"

## Why a rest ended, alongside `RestStation.REASON_DONE` and `REASON_REMOVED`.
const REASON_FULL := "recovered"
const REASON_LEFT_HOME := "left_home"
const REASON_FIGHT := "fight_started"

## How a pal came back, for anything listening.
const BY_BED := "bed"
const BY_ITEM := "item"

## A pal lay down / got up. `rest_finished` carries how many seconds it slept,
## and NOTHING READS IT YET — that is the seam for §12's bond, which does not
## exist. No bond number is invented here; when bond lands, it hangs off this
## signal and needs no change on this side.
signal rest_started(pal: RefCounted, bed: Node)
signal rest_finished(pal: RefCounted, seconds: float, reason: String)
## A pal is conscious again, and which of §16's two routes did it.
signal pal_revived(pal: RefCounted, how: String)

@export var party_path: NodePath
@export var home_path: NodePath
## The trainer, for the "are we at home" question. Optional: without one, nothing
## is automatic and `rest()` still works when something calls it.
@export var player_path: NodePath
## The combat manager, so a fight starting at home wakes the sleepers rather than
## leaving a pal in bed and in the arena at once. Optional.
@export var combat_path: NodePath
## Where a resting pal's body is parented. Defaults to this node's parent, which
## is the world in the shipping scene.
@export var world_path: NodePath
## A trainer inventory owned by somebody else. Optional, and see `inventory()`.
@export var inventory_path: NodePath

var _party: Object = null
var _home: Object = null
var _player: Node3D = null
var _combat: Node = null
var _world: Node = null

## One entry per sleeping pal: `{pal, bed, seconds, body}`. An Array of
## Dictionaries rather than a Dictionary keyed by pal, because a `RefCounted` key
## is a perfectly good way to leak the very object a party is supposed to own.
var _resting: Array[Dictionary] = []

## Restored records waiting for the party and the beds to exist. See `load_data`.
var _pending: Array = []
var _pending_left: float = 0.0

var _bag: RefCounted = null
var _refusal: String = ""


func _ready() -> void:
	_party = get_node_or_null(party_path)
	_home = get_node_or_null(home_path)
	_player = get_node_or_null(player_path) as Node3D
	_combat = get_node_or_null(combat_path)
	_world = get_node_or_null(world_path)
	if _world == null:
		_world = get_parent()
	if _combat != null and _combat.has_signal("entered"):
		_combat.connect("entered", _on_fight_started)
	_ensure_bag()
	_register()


## The seam a test binds through, so none of the rules below need a scene.
func bind(party: Object, home: Object, world: Node = null) -> void:
	_party = party
	_home = home
	_world = world


func last_refusal() -> String:
	return _refusal


## --- the trainer's items --------------------------------------------------

## Where the revival draughts are kept.
##
## THIS IS A SEAM AND IT IS IN THE WRONG PLACE. `scripts/items/` shipped a
## complete slot/stack inventory with no owner anywhere in the scene — nothing
## instantiates one for the trainer. A revival item has to be HELD to be spent,
## so this file is the first thing in the game to need a bag and therefore the
## first thing to make one.
##
## It is arranged to be taken away again: point `inventory_path` at whatever ends
## up owning the trainer's bag (M9's survival loop is where it belongs) and this
## node stops making one, stops saving one, and simply spends from theirs. The
## items are saved under their own key inside this domain rather than mixed into
## the resting records, so moving them is a copy of one array.
func inventory() -> Object:
	# Guarded rather than trusted: this node is exercised outside a tree by
	# `tests/test_recovery.gd`, and `get_node_or_null` on an empty path from a
	# node with no parent is not a question worth asking.
	var external: Node = null
	if not inventory_path.is_empty() and is_inside_tree():
		external = get_node_or_null(inventory_path)
	if external != null and external.has_method("remove") and external.has_method("has"):
		return external
	if external != null and external.has_method("inventory"):
		var held: Object = external.call("inventory")
		if held != null:
			return held
	_ensure_bag()
	return _bag


## True while this node is the one holding the trainer's items — i.e. nobody else
## has claimed the seam yet. What `save_data()` uses to decide whether the items
## are its business.
func owns_inventory() -> bool:
	return inventory() == _bag


func _ensure_bag() -> void:
	if _bag != null:
		return
	_bag = INVENTORY.new()
	var stock := int(config().get("starting_revival_items", 3))
	if stock > 0:
		_bag.call("add", revival_item(), stock)


func revival_item() -> String:
	return str(config().get("revival_item", "revival_draught"))


func revival_item_name() -> String:
	return DEFS.display_name(revival_item())


func revival_items_left() -> int:
	var bag := inventory()
	return int(bag.call("count_of", revival_item())) if bag != null else 0


## --- §16, route one: the item ---------------------------------------------

## Spend a revival draught on a fainted pal.
##
## Refused, with a reason, on a pal that is not down — the item is checked
## against the creature BEFORE it is consumed, so a misfired button costs
## nothing. §16 gives the item no other job: it does not heal a standing pal,
## because that is what a bed is for and an item that did both would make the
## beds pointless the moment the player had two draughts.
func revive_with_item(pal: RefCounted) -> bool:
	_refusal = ""
	if pal == null:
		_refusal = REFUSED_NOT_A_PAL
		return false
	if not bool(pal.get("fainted")):
		_refusal = REFUSED_NOT_DOWN
		return false
	var bag := inventory()
	if bag == null or not bool(bag.call("has", revival_item(), 1)):
		_refusal = REFUSED_NO_ITEM
		return false
	if not bool(bag.call("remove", revival_item(), 1)):
		_refusal = REFUSED_NO_ITEM
		return false
	pal.call("revive", float(config().get("revival_item_hp_fraction", 0.5)))
	pal_revived.emit(pal, BY_ITEM)
	return true


## --- §16, route two: the bed ----------------------------------------------

## Is there anything a bed could do for this pal?
##
## Fainted, or hurt. A pal at full health gets nothing from lying down today —
## §16's other half of a bed is bond, bond does not exist, and putting five
## healthy creatures to bed for a benefit the game does not have would be five
## bodies asleep in the base for no reason.
func needs_rest(pal: RefCounted) -> bool:
	if pal == null:
		return false
	return bool(pal.get("fainted")) or float(pal.get("hp")) < float(pal.get("max_hp"))


func is_resting(pal: RefCounted) -> bool:
	return _index_of(pal) >= 0


func resting() -> Array:
	var out: Array = []
	for entry: Dictionary in _resting:
		out.append(entry["pal"])
	return out


func resting_count() -> int:
	return _resting.size()


## Seconds this pal has been in its bed, or -1 if it is not in one. What a HUD
## would draw a recovery bar from.
func seconds_rested(pal: RefCounted) -> float:
	var at := _index_of(pal)
	return -1.0 if at < 0 else float(_resting[at]["seconds"])


## Put a pal to bed. `bed` may be given; otherwise a free pal bed at home is
## found.
##
## CALLED INTO THE BED, never the other way round. The bed learns that a pal is
## in it and learns nothing else — not what a pal is, not what resting does, not
## when it ends.
func rest(pal: RefCounted, bed: Node = null, seconds_already: float = 0.0) -> bool:
	_refusal = ""
	if pal == null:
		_refusal = REFUSED_NOT_A_PAL
		return false
	if is_resting(pal):
		_refusal = REFUSED_ALREADY_RESTING
		return false
	if not needs_rest(pal):
		_refusal = REFUSED_NOTHING_TO_DO
		return false

	var target := bed
	if target == null:
		if _home == null or not bool(_home.call("has_home")):
			_refusal = REFUSED_NO_HOME
			return false
		target = _home.call("free_pal_bed") as Node
		if target == null:
			# Five pals, one pal per bed. The answer is "build another", and it
			# has to reach the player as a refusal rather than as a pal that
			# silently never recovers.
			_refusal = REFUSED_NO_BED
			return false

	if not bool(target.call("begin_rest", pal)):
		_refusal = str(target.call("last_refusal"))
		return false

	var entry := {
		"pal": pal,
		"bed": target,
		"seconds": maxf(0.0, seconds_already),
		"body": null,
	}
	_resting.append(entry)
	entry["body"] = _show_resting(pal, target)
	rest_started.emit(pal, target)
	return true


## Get a pal up. Returns false if it was not in a bed.
func wake(pal: RefCounted, reason: String = REASON_FULL) -> bool:
	var at := _index_of(pal)
	if at < 0:
		_refusal = REFUSED_NOT_A_PAL
		return false
	_release(_resting[at], reason)
	_resting.remove_at(at)
	return true


func wake_all(reason: String = REASON_FULL) -> int:
	var woken := _resting.size()
	for entry: Dictionary in _resting:
		_release(entry, reason)
	_resting.clear()
	return woken


## Advance every nap. Split out from `_process` so a test can drive it a frame at
## a time without a tree, the way `save_director.tick()` is.
func tick(delta: float) -> void:
	_retry_pending(delta)

	for entry: Dictionary in _resting.duplicate():
		var pal: RefCounted = entry["pal"]
		var bed: Node = entry["bed"]
		# The bed can go away under a sleeper — the player demolishes it, or a
		# load rebuilds the village — and `RestStation` wakes its occupants on the
		# way out. Noticing here rather than subscribing keeps one source of truth
		# and avoids a signal that fires back into the call that caused it.
		if pal == null:
			_resting.erase(entry)
			continue
		if bed == null or not is_instance_valid(bed) or not bool(bed.call("is_resting", pal)):
			wake(pal, STATION.RestStation.REASON_REMOVED)
			continue

		entry["seconds"] = float(entry["seconds"]) + delta

		if bool(pal.get("fainted")):
			# §16: the wait is the cost. Nothing happens to a fainted pal's health
			# until it has been in the bed long enough to come round at all.
			if float(entry["seconds"]) >= revive_seconds():
				pal.call("revive", float(config().get("bed_revive_hp_fraction", 0.35)))
				pal_revived.emit(pal, BY_BED)
			continue

		pal.call("heal", float(config().get("bed_hp_per_second", 4.0)) * delta)
		if float(pal.get("hp")) >= float(pal.get("max_hp")):
			wake(pal, REASON_FULL)


## The automatic half: bring your pals home and they go to bed.
##
## There is no "rest" button, and this is why. The verbs a screen can offer live
## in `scripts/ui/`, the input map is a separate file again, and neither belongs
## to this milestone — but a recovery system nothing can reach is the "written
## and never called" shape this project keeps getting bitten by. So the trigger
## is the one the player already performs: walking home. Standing in your base
## with a hurt pal puts it in a free pal bed; leaving takes it out again, because
## a creature cannot be asleep in a bed you are two hundred metres away from.
##
## This is NOT a pal doing a job. Nothing is assigned, nothing is produced, and
## the only thing that happens to the creature is that it gets its own health
## back.
func attend(trainer_point: Vector3) -> void:
	if _fight_running():
		wake_all(REASON_FIGHT)
		return
	if _home == null or not bool(_home.call("has_home")):
		wake_all(REASON_LEFT_HOME)
		return
	if not bool(_home.call("is_at_home", trainer_point, _resting.size() > 0)):
		wake_all(REASON_LEFT_HOME)
		return

	for entry: Variant in _roster():
		var pal: RefCounted = entry as RefCounted
		if pal == null or is_resting(pal) or not needs_rest(pal):
			continue
		# The fainted go first: with fewer beds than pals, a bed spent on a
		# scratched pal while another lies unconscious is the wrong bed.
		if not bool(pal.get("fainted")) and _someone_is_down_and_awake():
			continue
		rest(pal)


func _process(delta: float) -> void:
	tick(delta)
	if _player != null and is_instance_valid(_player):
		attend(_player.global_position)


## --- what the player is told ----------------------------------------------

## Every owned pal is down. The state this milestone exists to make reachable.
func all_pals_down() -> bool:
	return PARTY.none_standing(_roster())


func revive_seconds() -> float:
	return maxf(0.0, float(config().get("bed_revive_seconds", 45.0)))


func config() -> Dictionary:
	return PAL.config().get("recovery", {})


## --- the visible pal ------------------------------------------------------

## Stand the creature at its bed so the player can see it resting.
##
## MEADOWS_VERTICAL_SLICE.md M6 asks for "visible pal rest behavior", and outside
## a fight an owned pal has no body in the world at all — the only ones that
## exist are the wild creatures and the one hidden body the director deploys. So
## a resting pal gets its own, built from the same scene and the same species
## data as the one that fights, put on the bed's own `rest_point()`, and switched
## out of physics: it is asleep, it is not walking anywhere, and gravity has
## nothing to add to a creature already on the ground.
##
## The clip comes from DATA, never from a name in this file — `pal_animator.gd`
## is emphatic about that and it is right: every pack names its clips
## differently. A species may declare `animations.rest`; the three shipped
## creatures do not, so the fallback is the tunable in party.json, which is `sit`
## because there is no sleep or lie-down clip anywhere in that pack. A creature
## sitting down at its bed is the most honest thing the art can do.
func _show_resting(pal: RefCounted, bed: Node) -> Node3D:
	if _world == null or not is_instance_valid(_world) or not _world.is_inside_tree():
		return null
	var body: Node3D = PAL_SCENE.instantiate()
	body.name = "RestingPal"
	body.set_script(BODY_SCRIPT)
	_world.add_child(body)
	body.call("setup", str(pal.get("species_id")))

	var index: int = int(bed.call("occupants").find(pal))
	var spot: Vector3 = bed.call("rest_point", maxi(0, index))
	if not bool(body.call("place_on_ground", spot)):
		body.global_position = spot
	# Physics off rather than merely still: a `CharacterBody3D` left processing
	# would keep integrating gravity and friction against terrain collision that
	# may not have finished building, and a sleeping creature that slides down a
	# hill is not resting.
	body.set_physics_process(false)
	_play_rest_clip(body, str(pal.get("species_id")))
	return body


func _play_rest_clip(body: Node3D, species_id: String) -> void:
	var clip := _rest_clip(species_id)
	if clip.is_empty():
		return
	var players: Array[Node] = body.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	if not player.has_animation(clip):
		# Said once, and not fatal. A creature standing in its idle beside its bed
		# is worse than one sitting in it and much better than nothing.
		push_warning("no '%s' clip on '%s'; it will rest in its idle pose" % [clip, species_id])
		return
	var animation := player.get_animation(clip)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR
	player.play(clip, 0.2)


func _rest_clip(species_id: String) -> String:
	var animations: Variant = SPECIES.placeholder(species_id).get("animations", {})
	if animations is Dictionary:
		var named := str((animations as Dictionary).get("rest", ""))
		if not named.is_empty():
			return named
	return str(config().get("rest_clip", ""))


## --- internals ------------------------------------------------------------

func _release(entry: Dictionary, reason: String) -> void:
	var pal: RefCounted = entry["pal"]
	var bed: Node = entry["bed"]
	if bed != null and is_instance_valid(bed) and bool(bed.call("is_resting", pal)):
		bed.call("end_rest", pal, reason)
	var body: Node = entry["body"]
	if body != null and is_instance_valid(body):
		body.queue_free()
	entry["body"] = null
	rest_finished.emit(pal, float(entry["seconds"]), reason)


func _index_of(pal: RefCounted) -> int:
	for i in _resting.size():
		if _resting[i]["pal"] == pal:
			return i
	return -1


func _roster() -> Array:
	if _party == null or not _party.has_method("members"):
		return []
	var list: Variant = _party.call("members")
	return list if list is Array else []


func _someone_is_down_and_awake() -> bool:
	for entry: Variant in _roster():
		var pal: RefCounted = entry as RefCounted
		if pal != null and bool(pal.get("fainted")) and not is_resting(pal):
			return true
	return false


func _fight_running() -> bool:
	return _combat != null and is_instance_valid(_combat) and bool(_combat.call("is_fighting"))


func _on_fight_started() -> void:
	wake_all(REASON_FIGHT)


func _exit_tree() -> void:
	wake_all(STATION.RestStation.REASON_REMOVED)


## --- the `recovery` save domain -------------------------------------------
##
## A pal left asleep must still be asleep after a reload, part-way through the
## same nap. Without that, saving and loading is a way to cancel §16's cost — and
## `SaveDirector` autosaves on a timer, so it would happen to a player who did
## nothing but stand still.


func save_data() -> Dictionary:
	var out: Dictionary = {"resting": _resting_records()}
	if owns_inventory():
		out["items"] = _bag.call("to_records")
	return out


## Which party SLOT is asleep, how far along, and WHERE the bed was.
##
## Not a reference to the pal and not one to the bed: neither survives a file.
## The pal comes back through the `party` domain as the nth record, and the bed
## comes back through `structures` at the same coordinates, so a slot index and a
## position are the only two things that can still mean something tomorrow.
func _resting_records() -> Array:
	var roster := _roster()
	var out: Array = []
	for entry: Dictionary in _resting:
		var slot: int = roster.find(entry["pal"])
		if slot < 0:
			continue
		var bed: Node = entry["bed"]
		var where: Vector3 = (bed.call("where") as Vector3) if bed != null and is_instance_valid(bed) else Vector3.ZERO
		out.append({
			"pal": slot,
			"seconds": float(entry["seconds"]),
			"x": where.x,
			"y": where.y,
			"z": where.z,
		})
	return out


func load_data(data: Dictionary) -> void:
	wake_all(STATION.RestStation.REASON_REMOVED)
	if data.has("items"):
		_bag = INVENTORY.from_records(data.get("items", []))
	var records: Variant = data.get("resting", [])
	_pending = (records as Array).duplicate(true) if records is Array else []
	# The party and the beds are other domains and may not have been handed their
	# own records yet — `SaveManager` walks contributors in registration order and
	# this file has no business depending on that order. So the restore is tried
	# now and retried for a few seconds afterwards.
	_pending_left = PENDING_SECONDS
	_apply_pending()


func _retry_pending(delta: float) -> void:
	if _pending.is_empty():
		return
	_pending_left -= delta
	if _pending_left <= 0.0:
		push_warning("%d resting pal(s) could not be put back in their beds after a load" % _pending.size())
		_pending.clear()
		return
	_apply_pending()


func _apply_pending() -> void:
	if _pending.is_empty():
		return
	var roster := _roster()
	if roster.is_empty():
		return
	var left: Array = []
	for record: Variant in _pending:
		if not record is Dictionary:
			continue
		var slot := int((record as Dictionary).get("pal", -1))
		if slot < 0 or slot >= roster.size():
			# The party shrank between the save and the load — a released pal, a
			# record that would not rebuild. One nap is lost, not the save.
			continue
		var pal: RefCounted = roster[slot]
		var where := Vector3(
			float((record as Dictionary).get("x", 0.0)),
			float((record as Dictionary).get("y", 0.0)),
			float((record as Dictionary).get("z", 0.0))
		)
		var bed: Node = null
		if _home != null:
			bed = _home.call("bed_nearest", where) as Node
		if bed == null:
			left.append(record)
			continue
		rest(pal, bed, float((record as Dictionary).get("seconds", 0.0)))
	_pending = left


## Same lazy re-registration as `party_manager` and `structures`: under
## `--script` the autoloads are attached only after the entry point's `_init()`
## returns, so `_ready()` here can run in a tree with no `/root/SaveManager` in
## it. `register()` is idempotent for exactly this reason.
func _register(manager: Node = null) -> void:
	var target: Node = manager if manager != null else get_node_or_null(^"/root/SaveManager")
	if target != null and target.has_method("register"):
		target.call("register", SAVE_DOMAIN, self)
