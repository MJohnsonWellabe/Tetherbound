extends Node3D

## Something the player can walk up to and press a button on.
##
## Bolted onto whatever it belongs to as a child node, so the thing itself —
## Grandpa's body, a starter creature, a berry bush — stays ignorant of prompts. It
## measures from ITS OWN position rather than its parent's, which is what lets a
## large body offer its prompt from a door, a head, or a face rather than from
## the point between its feet.
##
## It offers; it does not act. `activated` is a signal and the listener decides
## what happens, because the same starter body is a thing you choose during the
## opening and a thing you feed later, and neither of those belongs in here.

const ARBITER := preload("res://scripts/world/prompt_arbiter.gd")
const ARBITER_NODE := preload("res://scripts/world/interaction_arbiter.gd")

## Metres above the caller's point the sight line is drawn to.
##
## The arbiter measures from the player's own origin, which sits on the ground
## between their feet (scenes/player/player.tscn: the capsule is offset up to
## y 0.9, the node itself is not). A line drawn from there skims every hummock,
## stair nose and doorsill between here and the prompt, so it is raised to
## roughly eye height on a 1.8m trainer. TUNABLE.
const SIGHT_EYE_HEIGHT := 1.4

## Metres of the sight line, at the prompt end, that are not tested.
##
## A prompt is routinely hung ON the thing it belongs to — Grandpa's chest at
## 0.6 of his height, a harvest tree's prompt on the trunk axis — or just
## outside it — a satchel's 0.6m, a storage chest's 0.7m. None of those bodies
## may occlude their own offer, and this file cannot work out from the node tree
## which collider belongs to whom: a scattered tree's trunk lives in one shared
## StaticBody3D that is a SIBLING of the prompt, and the bed's "Get up" prompt
## is parented to the world rather than to the bed. So the ray simply starts
## clear of whatever the prompt is bolted to. TUNABLE.
const SIGHT_SELF_CLEARANCE := 0.9

## Metres of the sight line, at the player end, that are not tested. The
## trainer's own capsule is 0.4m in radius (scenes/player/player.tscn) and the
## eye point is on its axis, so a ray run all the way to the eye ends inside the
## player and reports the player as the occluder every single time.
const SIGHT_TRAINER_CLEARANCE := 0.55

signal activated()

## What the button does, in the imperative and already containing the subject:
## "Talk to Grandpa", "Choose Terrapup". Written out in full rather than
## assembled from a verb and a name, because "Choose" and "Talk to" take their
## object differently and a template would eventually produce "Talk to to".
@export var label: String = ""

## Metres. Generous by default: a prompt that only appears when you are inside
## the body reads as a prompt that does not work.
@export var radius: float = 3.6

## Off means no offer at all — not a greyed one. The starters exist in the world
## before the choice is unlocked, and a visible "Choose Terrapup" the button
## refuses is worse than no prompt.
@export var enabled: bool = true

## Beats proximity when it has to. Left at zero for everything ordinary.
@export var priority: int = 0

var _arbiter: Node = null


func _ready() -> void:
	_attach()


## Find the arbiter and register. Through the group rather than an exported
## path: these bodies are spawned in code by the sequence director and can end
## up anywhere in the tree, so naming a path would mean the spawner knowing
## where the arbiter lives.
func _attach() -> void:
	if _arbiter != null and is_instance_valid(_arbiter):
		return
	_arbiter = get_tree().get_first_node_in_group(ARBITER_NODE.GROUP)
	if _arbiter == null:
		# Not an error. A scene with no arbiter — the combat sandbox — simply has
		# no prompts, and an interactable in it is inert rather than broken.
		return
	_arbiter.call("register", self)


func _exit_tree() -> void:
	if _arbiter != null and is_instance_valid(_arbiter):
		_arbiter.call("unregister", self)
	_arbiter = null


func configure(new_label: String, new_radius: float = -1.0, new_enabled: bool = true) -> void:
	label = new_label
	if new_radius > 0.0:
		radius = new_radius
	enabled = new_enabled


func set_enabled(value: bool) -> void:
	enabled = value


## --- the provider contract, see interaction_arbiter.gd ----------------------

func interaction_offer(from: Vector3) -> Dictionary:
	if not enabled or label == "" or not is_inside_tree():
		return {}
	var distance := from.distance_to(global_position)
	if distance > radius:
		return {}
	if not _has_line_of_sight(from):
		return {}
	return ARBITER.offer(label, distance, priority)


## Is there solid geometry between the player and this prompt?
##
## Raw distance on its own let the player finish Grandpa's ENTIRE opening —
## story, gifts, starter, naming — from the loft bedroom directly above him:
## ~2.9m of Euclidean distance, comfortably inside the 4.0m prompt radius
## (data/config/opening.json), through 0.25m of loft floor slab. Found by a
## blind playtest, and it is not specific to Grandpa: every offer in the game
## reached through every wall.
##
## The ray is cast FROM the prompt TOWARD the player rather than the other way
## round, and both ends are trimmed (see the two clearance constants). Starting
## at the prompt also means that when the trimmed origin is still inside the
## prompt's own body — a fat tree trunk — `hit_from_inside` staying false makes
## the physics server skip that shape, which is a second line of defence against
## a thing occluding itself.
##
## Refuses only what it can prove is blocked: with no world or no space state
## (a bare tool scene, a node not yet in a viewport) it offers. A prompt that
## never appears is worse than one that appears through a wall.
func _has_line_of_sight(from: Vector3) -> bool:
	var world := get_world_3d()
	if world == null:
		return true
	var space := world.direct_space_state
	if space == null:
		return true

	var eye := from + Vector3.UP * SIGHT_EYE_HEIGHT
	var to_eye := eye - global_position
	var span := to_eye.length()
	if span <= SIGHT_SELF_CLEARANCE + SIGHT_TRAINER_CLEARANCE:
		# Arm's reach. Nothing can fit in what is left of the line, and a
		# degenerate reversed ray would report nonsense.
		return true

	var direction := to_eye / span
	var query := PhysicsRayQueryParameters3D.create(
		global_position + direction * SIGHT_SELF_CLEARANCE,
		global_position + direction * (span - SIGHT_TRAINER_CLEARANCE))
	# Areas are triggers, not geometry — the house's own interior camera area
	# covers the whole ground floor and would occlude everything in it.
	query.collide_with_areas = false
	return space.intersect_ray(query).is_empty()


func interaction_activate() -> void:
	activated.emit()
