extends RefCounted

## Stage B lane 6.D. THE PICTURE ON SOMEBODY ELSE'S BODY.
##
## `scripts/vfx/combat_vfx.gd` puts a hit spark, a KO puff, a catch sparkle and
## a level-up flourish on screen; `companion_presence.gd` makes a creature react
## to the fight it just won; `world_audio.gd` gives all of it a sound. Every one
## of those fires off something only the LOCAL process knows -- its own combat
## manager's signals, its own party's numbers -- so on `remote_creature.gd` and
## `remote_trainer.gd`, which are the bodies another peer's trainer and creature
## wear in this process, none of them fire at all. A friend's fight is a pair of
## models sliding around in silence.
##
## This file is the one door those three layers go through for a body this
## process does not own. It is pure and static on purpose: no node, no session,
## no `Game`, so the bodies keep owning their own authority and their own RPC
## and nothing here can accidentally become a second place that decides who is
## who.
##
## ## Presentation, and ONLY presentation
##
## Nothing here changes a number, and nothing here is allowed to. The rule the
## encounter protocol is built on (`docs/specs/MP_ENCOUNTER_PROTOCOL.md` §2-§3:
## the host's record IS the hit points) survives exactly as long as no picture
## is ever the thing that decides an outcome. So:
##
##   * every payload this file reads was produced by `sample()` on the OWNER of
##     the body, off numbers the host already wrote there -- a hit landed on a
##     client's creature is `apply_host_enemy_hit`, a level came from the host's
##     reward grant -- and is carried to the viewer as a picture to draw, never
##     as a number to apply;
##   * `play()` writes to nothing but the scene: it spawns effect nodes, queues
##     a companion reaction and asks for a sound. Delete this file and the
##     project loses pictures and nothing else, which is the same bargain
##     `world_audio.gd`'s header strikes.
##
## ## Why the owner publishes, rather than each viewer working it out
##
## A viewer has nothing to work it out FROM. A remote body has no combat
## manager, no party, and no encounter record of its own -- the record only
## reaches the participants of that fight, so a bystander standing on the ridge
## watching two friends fight would still see silence. The owner, on the other
## hand, is the one process where the host's answer has already landed. So the
## owner's outbound proxy samples those numbers each tick (exactly as it already
## samples its position) and publishes the DIFFERENCE, and every other peer
## draws it. That is replicated state; it is not a local signal reaching across
## the wire, and the viewer never listens to a local combat manager for it.

const VFX := preload("res://scripts/vfx/combat_vfx.gd")

## The kinds a body may publish. Anything else is dropped rather than guessed
## at, so a typo is a missing picture and never a wrong one.
const KIND_HIT := "hit"
const KIND_KNOCKOUT := "knockout"
const KIND_CATCH := "catch"
const KIND_LEVEL_UP := "level_up"
const KIND_VICTORY := "victory"

const KINDS := [KIND_HIT, KIND_KNOCKOUT, KIND_CATCH, KIND_LEVEL_UP, KIND_VICTORY]


static func is_kind(kind: String) -> bool:
	return KINDS.has(kind)


# --- the owner's side: what a body is allowed to publish ------------------------

## The numbers a creature's owner may publish about it, off the live instance
## the host has already written to. `has()` before every `get()`, deliberately:
## a missing key read straight through `get()` is `null`, `int(null)` is 0 and
## `float(null)` is 0.0 -- which would turn "this instance has no level field"
## into "this creature dropped to level 0", i.e. a flourish on every tick.
##
## An empty Dictionary means "nothing to say about this body", which is what a
## peer with no creature out has, and `diff()` reports nothing for it.
static func sample(instance: Variant) -> Dictionary:
	if instance == null or not (instance is Object):
		return {}
	var obj := instance as Object
	var out: Dictionary = {}
	var hp_max: float = 1.0
	if obj.get("max_hp") != null:
		hp_max = maxf(float(obj.get("max_hp")), 1.0)
	out["hp_max"] = hp_max
	if obj.get("hp") != null:
		out["hp"] = float(obj.get("hp"))
	if obj.get("level") != null:
		out["level"] = int(obj.get("level"))
	if obj.get("fainted") != null:
		out["fainted"] = bool(obj.get("fainted"))
	return out


## What changed between two samples, as the events to publish. Returns them in
## the order they should be drawn: the blow, then the fall it caused.
##
## Only DOWNWARD hp and UPWARD level produce an event. A creature healed at a
## bed, or one whose level was rolled back by a load, is not a picture -- and a
## `level` that fell would otherwise fire a flourish the moment a save loaded.
static func diff(before: Dictionary, after: Dictionary) -> Array:
	var events: Array = []
	if before.is_empty() or after.is_empty():
		return events
	if before.has("hp") and after.has("hp"):
		var hp_max: float = maxf(float(after.get("hp_max", 1.0)), 1.0)
		var drop: float = float(before["hp"]) - float(after["hp"])
		if drop > 0.001:
			events.append({"kind": KIND_HIT, "fraction": clampf(drop / hp_max, 0.0, 1.0)})
	if not bool(before.get("fainted", false)) and bool(after.get("fainted", false)):
		events.append({"kind": KIND_KNOCKOUT})
	if before.has("level") and after.has("level"):
		var levels: int = int(after["level"]) - int(before["level"])
		if levels > 0:
			events.append({"kind": KIND_LEVEL_UP, "levels": levels})
	return events


## The world's `CombatManager`, found by walking up from `from` -- the same walk
## `companion_presence.gd::_resolve_context()` does, and for its reason: the
## world is whichever ancestor owns one, never `tree.current_scene`, which is
## null in every `--script` smoke and capture run.
##
## Used ONLY on the owner's side of a body, to notice the two moments that have
## no number to sample: a fight ending in a win, and a catch sealing. Both are
## outcomes the host has already decided by the time this manager reports them
## (`apply_host_catch_verdict`, `apply_encounter_record`); reading them here
## publishes a picture of a decision, and never makes one. A VIEWER must never
## reach for this -- its combat manager is running its own fight, not the
## friend's.
## The world's `EncounterDirector`, by the same walk and for the same reason.
##
## Used ONLY on the owner's side, and only to answer one question this file
## cannot answer any other way: WHICH creature instance the local deployed body
## stands for. `Game.party.active()` is not that answer -- measured, not assumed:
## `encounter_director.gd::adopt_starter()` builds an instance and stands a body
## on it without ever putting it in the party, so `active()` is null for the
## whole of the opening and every harness deploy, and a sampler pointed at it
## publishes nothing at all. `ally_instance()` is the instance the body was
## built around, which is the same source `combat_vfx.gd::_body_for()` already
## uses to decide whose flourish to play.
static func find_encounter_director(from: Node) -> Node:
	if from == null or not from.is_inside_tree():
		return null
	var node: Node = from.get_parent()
	while node != null:
		var found := node.get_node_or_null(^"EncounterDirector")
		if found != null:
			return found
		node = node.get_parent()
	return null


static func find_combat_manager(from: Node) -> Node:
	if from == null or not from.is_inside_tree():
		return null
	var node: Node = from.get_parent()
	while node != null:
		var found := node.get_node_or_null(^"CombatManager")
		if found != null:
			return found
		node = node.get_parent()
	return null


# --- the viewer's side: drawing it ----------------------------------------------

## Draw `kind` on `body`, a body this process does not own. Returns the node the
## effect spawned when there is one (which is what `tests/smoke_net_hearts.gd`
## asserts on: a picture is a node that exists, not a frame anyone judged), or
## null when the effect layer is switched off, the kind is unknown, or the
## picture is a reaction rather than a node.
##
## `host` for the burst is the body's PARENT, the same host `combat_manager.gd`
## hands `VFX.hit()` -- a burst parented to the body itself would be dragged
## along by the interpolation that is still walking that body toward its next
## replicated position, and a spark that follows the creature reads as a glow.
static func play(body: Node3D, kind: String, payload: Dictionary = {}) -> Node:
	if body == null or not is_instance_valid(body):
		return null
	var host: Node = body.get_parent()
	if host == null:
		host = body
	var at: Vector3 = body.call("centre") if body.has_method("centre") else body.global_position
	var spawned: Node = null
	match kind:
		KIND_HIT:
			spawned = VFX.hit(host, at, null, false, body, float(payload.get("fraction", 0.0)))
		KIND_KNOCKOUT:
			spawned = VFX.knockout(host, at, body)
		KIND_CATCH:
			spawned = VFX.catch_success(host, at)
		KIND_LEVEL_UP:
			spawned = VFX.level_up(body, maxi(int(payload.get("levels", 1)), 1))
		KIND_VICTORY:
			pass
		_:
			return null
	_react(body, kind)
	_sound(body, kind, at)
	return spawned


## The companion layer's half. A remote creature body carries its own `Presence`
## (`remote_creature.gd` attaches one), and this is what tells it a fight was
## won or a level was gained on the other side of the wire -- the events its
## owner's `combat_manager.gd` would have called `on_event` for locally.
##
## Addressed to THIS body's own presence node, never through
## `SceneTree.call_group(companion_presence.GROUP, ...)` the way the local
## fight does: the group holds every companion in the process, so a group call
## would make the local player's creature celebrate a friend's win too.
static func _react(body: Node3D, kind: String) -> void:
	if kind != KIND_VICTORY and kind != KIND_LEVEL_UP:
		return
	var presence: Node = body.get_node_or_null(^"Presence")
	if presence == null or not presence.has_method("on_event"):
		return
	presence.call("on_event", "victory")


## The audio half. `world_audio.gd` is a listener on the local fight and has
## nothing to listen to for somebody else's, so it grew one public entry for
## this. Resolved by group rather than by node path: the world node that owns it
## is lane 6.A's file and its name is not this file's business.
static func _sound(body: Node3D, kind: String, at: Vector3) -> void:
	if not body.is_inside_tree():
		return
	var tree := body.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(&"world_audio"):
		if is_instance_valid(node) and node.has_method("on_remote_event"):
			node.call("on_remote_event", kind, at)
