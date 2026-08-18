extends Node3D

## R2.3: a gather point bolted onto one of `vegetation.gd`'s OWN scattered
## trees or rocks, instead of one of `harvest_node.gd`'s ~10 authored tutorial
## props. The tree/rock itself is the MultiMesh instance already rendered by
## `vegetation.gd` — this only adds a small marker so the owner's reported
## "gathering seems to randomly pop up" (nothing distinguishes a harvestable
## prop from a decorative one until the prompt appears at close range) has an
## answer at a real approach distance.
##
## The marker is a small standalone glint, not a tint on the tree/rock's own
## material. A per-instance MultiMesh colour multiply was tried first (the
## same mechanism R7.1-remainder uses for grass jitter) and reached two
## independent blind critics reading it as "diseased/scorched foliage... a
## texture-atlas glitch" rather than a marker, on both a red-dominant and a
## gold-balanced attempt — the leaf mesh's own baked per-vertex shading
## variation survives any multiply, so the failure was structural, not a
## colour-tuning miss. A small unshaded sphere sidesteps it entirely: it
## reads as UI-adjacent (a resource glint, the genre's own convention) rather
## than as part of the tree.
##
## R2.3-remainder: the plain sphere shipped but a fresh blind critic called it
## "a flat, unshaded, arbitrarily-positioned sticker... reads as a debug/
## placeholder, not a designed interact-here affordance" — no gradient, no
## glow falloff. The glint is now a small bright core wrapped in a soft
## radial-gradient halo (a billboard quad sampling a procedural
## GradientTexture2D, additive-blended so it actually falls off to nothing
## rather than hard-cutting at a mesh edge) plus a handful of slow-drifting
## GPUParticles3D motes — the two untried levers this item's own remainder
## named ("real light falloff or a GPUParticles3D sparkle rather than a flat
## unshaded mesh"). No new asset files: the gradient and the particle's
## colour ramp are both built procedurally in code.
##
## OW7: the glint was still the ONLY thing at a wood point, and the owner
## played it and said so — "wood to pick up doesn't look like wood, it's just
## random yellow glowing spots." Rendering the frame shows exactly that: two
## gold blobs hanging in open air over grass. Every round above tuned how the
## MARKER looked, and none of them noticed that a "wood" point is bolted onto
## one of the scatter's own LIVING trees, so there was no wood-shaped object
## anywhere for the marker to mark. No amount of gradient fixes that. A pile of
## cut logs now stands at the point and the glint sits on top of it, so the
## thing a player recognises is the resource and the glow only says which one.
##
## HARVEST-ALL/D60, owner directive: "once it's chopped it should disappear
## and not regrow." This used to be a prompt-and-glint cooldown rather than a
## hide/show — a living tree vanishing read as a bug where a pile vanishing
## reads as "spent, come back later". That reasoning no longer applies: every
## tree and stone in the meadow is now harvestable, so what actually
## disappears is the WHOLE placement (the tree/rock's own render instance and
## collider, via `vegetation.gd::harvest_permanently`) alongside this node —
## not a dim-and-wait marker on a tree that stays standing. See that
## function's own header for the removal mechanism and D60 for why
## permanent, unbounded removal is the owner's explicit call.
##
## RG10, owner directive, and it SUPERSEDES everything above about the glint:
## "Items to harvest shouldn't be gold lit up orbs. They shouldn't light up
## at all." Everything this header describes up to here was built for a real
## reason — the owner's own earlier report that gathering "seems to randomly
## pop up" — and iterated through two blind critics before landing on the
## core+halo+sparkle shape. The newer word wins anyway, the same way `D23`
## lets a later owner directive outrank the reasoning that came before it.
## The glint is gone: no `_glint` node, no core/halo/sparkle billboards, no
## `GPUParticles3D`. At HARVEST-ALL density that marker had also stopped
## doing the job it was built for — nearly every tree and rock in the meadow
## carried one, so "which ones glint" had stopped being information (D60's
## own flag, never resolved until now). What carries the "this is gatherable"
## read now is the object's own state: a wood point already stands a real
## woodpile (`_build_resource_prop` below), and a stone point is already
## sitting on the rock itself — RG9's chop-then-gather split (a standing tree
## you chop, a felled log you gather) makes that read even sharper without
## this file doing anything further, since only the FELLED stage is ever a
## `vegetation_harvest_point`.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")

var _item_id: String = ""
var _amount: int = 0
var _prompt: Node3D = null
## HARVEST-ALL. Which placement this node belongs to, so `_on_gathered()` can
## tell `vegetation.gd::harvest_permanently()` exactly which render instance
## and collider to remove. "" / -1 (the defaults) for a caller that predates
## HARVEST-ALL or a standalone test — `_on_gathered()` falls back to freeing
## just this node in that case, see its own comment.
var _harvest_layer: String = ""
var _harvest_index: int = -1


## RG9: no resource prop is built here any more -- the woodpile OW7 built on
## a still-standing tree moved to `felled_resource.gd`, which is where a pile
## of cut logs actually belongs (the STANDING stage is a living tree; nothing
## should be lying at its base yet). This is now just the interact prompt and
## the group membership that let a swing find a living tree/rock to chop --
## the tree/rock itself, drawn by `vegetation.gd`'s own scatter, is the whole
## visual.
func setup(spec: Dictionary) -> void:
	_item_id = str(spec.get("item", "wood"))
	_amount = int(spec.get("amount", 2))
	_harvest_layer = str(spec.get("harvest_layer", ""))
	_harvest_index = int(spec.get("harvest_index", -1))
	var prompt_height := float(spec.get("prompt_height", 1.4))

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * prompt_height
	_prompt.call("configure", str(spec.get("label", "Chop")), 2.6, true)
	_prompt.connect("activated", _on_gathered)
	add_child(_prompt)


## RG9, owner directive: "You shouldn't be able to gather a standing tree.
## You should have to chop it. Then it becomes downed wood. Then you gather
## that. Same for stone." This is now the CHOP, not the gather -- the tool
## check and the tool's wear are unchanged from before RG9, but a successful
## chop no longer pays the resource into the satchel directly. It stands a
## `felled_resource.gd` pickup where the tree/rock stood (`vegetation.gd::
## fell()`) and THAT is what actually pays out, bare-handed, the next time
## it is gathered -- the tool already did its job here.
##
## No `has_room_for` check here any more, on purpose: a full satchel used to
## refuse the chop itself, which made no sense once chopping stopped putting
## anything IN the satchel. A player can always chop; a felled pile with
## nowhere to go simply waits on the ground, same as any other gather point
## the satchel has no room for.
func _on_gathered() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; chopped %s into nothing" % _item_id)
		return
	var inventory: RefCounted = game.get("inventory")
	var items: RefCounted = game.get("items")
	if items == null or inventory == null:
		return
	var gathered: Dictionary = HARVEST_LOGIC.gather(_item_id, _amount, inventory, items)
	var actual_amount: int = int(gathered["amount"])
	if actual_amount <= 0:
		# The wrong tool for this resource: refused, and the tree stays put for
		# whenever the player comes back with the right one.
		return
	var required_slot: int = int(gathered["required_slot"])
	if required_slot >= 0:
		inventory.call("damage_tool", required_slot)

	# HARVEST-ALL/D60: chopped stays chopped. The tree/rock's own render
	# instance and collider go with it (vegetation.gd::harvest_permanently,
	# called inside fell() below), not just this marker -- there is no
	# respawn any more. The parent IS the Vegetation node (vegetation.gd::
	# _spawn_harvest_point add_child()s this directly), so no separate
	# reference has to be threaded in.
	var vegetation := get_parent()
	if vegetation != null and vegetation.has_method("fell") and not _harvest_layer.is_empty():
		vegetation.call("fell", _harvest_layer, _harvest_index, actual_amount)
	else:
		# A standalone test, or a caller that predates HARVEST-ALL/RG9:
		# nothing to tell the world about, so just remove this node's own
		# marker. No felled pickup stands in this fallback path -- a caller
		# in this shape (no `vegetation.gd` parent at all) has nowhere for
		# one to make sense.
		queue_free()


func _ready() -> void:
	# So a tool swing can find this without knowing which of the two gather
	# scripts drew it (`harvest_logic.gd::GROUP`).
	add_to_group(HARVEST_LOGIC.GROUP)

## Gather this spot, the same as pressing the interact prompt on it.
##
## Public so a tool swing (`scripts/player/tool_hold.gd`) can drive the exact
## same path the prompt drives -- one gather implementation, two ways to reach
## it, so a swing and a press can never disagree about yield, tool gating,
## durability or respawn.
func gather() -> void:
	_on_gathered()

