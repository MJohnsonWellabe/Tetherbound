extends Node3D

## Something the player can walk up to and press a button on.
##
## Bolted onto whatever it belongs to as a child node, so the thing itself —
## Grandpa's body, a starter pal, a berry bush — stays ignorant of prompts. It
## measures from ITS OWN position rather than its parent's, which is what lets a
## large body offer its prompt from a door, a head, or a face rather than from
## the point between its feet.
##
## It offers; it does not act. `activated` is a signal and the listener decides
## what happens, because the same starter body is a thing you choose during the
## opening and a thing you feed later, and neither of those belongs in here.

const ARBITER := preload("res://scripts/world/prompt_arbiter.gd")
const ARBITER_NODE := preload("res://scripts/world/interaction_arbiter.gd")

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
	return ARBITER.offer(label, distance, priority)


func interaction_activate() -> void:
	activated.emit()
