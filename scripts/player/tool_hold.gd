extends Node3D

## The tool currently in the trainer's hand, and the swing that uses it.
##
## Owner playtest report: *"the tools exist but you can't pull them out when
## you're exploring and use them."* That was exactly right. A tool was an
## inventory row and nothing more: pressing its hotbar slot only ever repaired
## it, nothing was ever drawn in the trainer's hand, and harvesting was a
## proximity `interact` press that silently consulted the satchel to decide
## whether you owned the right tool. The tool gating in
## `scripts/world/harvest_logic.gd` was real and invisible.
##
## The owner picked the Palworld/Valheim shape: press the slot, the tool is in
## your hand and stays there until you switch away; swing it at a tree and the
## tree gives wood. So this node owns two things and deliberately no more:
##
##   1. **What is in the hand.** `GameState.equipped_tool` is the id; this
##      watches it and swaps the bone-attached prop to match.
##   2. **The swing.** A windup-free animation trigger plus a forward cone test
##      against whatever harvest nodes are in reach.
##
## It does NOT own the harvest arithmetic. `harvest_logic.gd` and
## `item_db.gd::harvest_yield` decide what a gather yields; this node forwards
## the held id so that shared arithmetic can verify the tool that visibly
## swung. A swing is just a second way to ask, alongside the interact prompt.
##
## ## Why the props are bone-attached the way they are
##
## Find `Model`'s `Skeleton3D`, hang a `BoneAttachment3D` off the named bone,
## parent the prop to it, and fall back to a plain offset from the body when
## the rig has no such bone (a capsule stand-in, a bare test scene). Kept as
## the ONE hand-attachment system in the game, deliberately -- OW12
## (2026-08-16) retired `scripts/player/torch.gd`'s own earlier copy of this
## same code so the torch's mesh reaches the hand through here too, rather
## than maintaining two versions of "put a thing in the trainer's hand".
## `torch.gd` now only owns the light, synced each frame to wherever this
## node's own `prop_node()` says the mesh actually is.
##
## The meshes are the ones already vendored for the village work area
## (`Axe_Bronze`, `Pickaxe_Bronze`, `Knife`) -- D24's "one prop family", no new
## asset family for this. Which mesh a tool uses, and how it sits in the hand,
## is data on the item itself (`data/items/items.json`'s `held_model`,
## `held_offset`, `held_rotation_deg`), not a table in here.

const HAND_BONE := "Hand.R"
## Bones to try, in order, for the hand the prop hangs off. Rigs in this project
## have come from more than one source and do not agree on a name. Falls
## through to the body offset if none of these exist.
const HAND_BONE_CANDIDATES := ["Hand.R", "hand.R", "RightHand", "mixamorig:RightHand", "Hips"]

## How far in front of the trainer a swing reaches, and how wide the arc is.
## Matched to the interact prompt's own reach so that anything you could have
## gathered by walking up and pressing interact is also something you can hit.
## TUNABLE.
const SWING_REACH := 3.2
const SWING_ARC_DEGREES := 110.0

## Seconds a swing takes. The gather resolves at the midpoint so the yield lands
## with the impact rather than on the button press. TUNABLE.
const SWING_SECONDS := 0.45

const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")
const COMBAT_MATH := preload("res://scripts/combat/combat_math.gd")

signal swing_started()
signal swing_connected(node: Node)

var _equipped: String = ""
var _prop_root: Node3D = null
var _prop: Node3D = null
var _swing_left: float = 0.0
var _swing_resolved: bool = true


func _process(delta: float) -> void:
	_sync_equipped()
	if _swing_left > 0.0:
		_swing_left -= delta
		# Resolved at the midpoint, once -- the impact, not the press and not
		# the recovery.
		if not _swing_resolved and _swing_left <= SWING_SECONDS * 0.5:
			_swing_resolved = true
			_resolve_swing()


## Whether a swing is currently playing. The player controller reads this to
## refuse a second swing on top of the first.
func is_swinging() -> bool:
	return _swing_left > 0.0


func equipped() -> String:
	return _equipped


## The prop currently bone-attached to the trainer's hand, or null when
## nothing is equipped or the equipped item carries no `held_model` (the
## fishing rod). Public so a sibling system that needs to know "what mesh is
## actually in the hand right now" -- `scripts/player/torch.gd`, whose own
## light has to find the torch prop without a second hand-attachment system
## of its own -- and a smoke test can both ask without reaching past this
## node into a private field.
func prop_node() -> Node3D:
	return _prop


## Begin a swing. Refused (returns false) with nothing in hand or with one
## already running, so the caller can play its own refusal.
func swing() -> bool:
	if _equipped.is_empty() or is_swinging():
		return false
	_swing_left = SWING_SECONDS
	_swing_resolved = false
	swing_started.emit()
	return true


## --- what is in the hand ---------------------------------------------------

func _sync_equipped() -> void:
	var game := get_node_or_null(^"/root/Game")
	var wanted := str(game.get("equipped_tool")) if game != null else ""
	if wanted == _equipped:
		return
	_equipped = wanted
	_rebuild_prop()


func _rebuild_prop() -> void:
	if _prop != null and is_instance_valid(_prop):
		_prop.queue_free()
	_prop = null
	if _equipped.is_empty():
		return

	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	var db: RefCounted = game.get("items")
	if db == null:
		return
	var definition := db.call("definition", _equipped) as Dictionary
	var model_path := str(definition.get("held_model", ""))
	# A tool with no mesh (the fishing rod) is still equipped and still
	# functional -- it simply is not drawn. Returning here rather than refusing
	# the equip keeps "what is in my hand" and "what can I see" separable.
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		return

	var scene: PackedScene = load(model_path)
	if scene == null:
		return
	_prop = scene.instantiate() as Node3D
	if _prop == null:
		return

	_ensure_prop_root()
	_prop_root.add_child(_prop)
	_prop.position = _vector3_from(definition.get("held_offset", [0.0, 0.0, 0.0]))
	_prop.rotation_degrees = _vector3_from(definition.get("held_rotation_deg", [0.0, 0.0, 0.0]))


## The node props hang off: a `BoneAttachment3D` on the trainer's hand when the
## rig has one, otherwise this node itself, offset out from the body. Built once
## and kept, so switching tools does not churn the skeleton's children.
func _ensure_prop_root() -> void:
	if _prop_root != null and is_instance_valid(_prop_root):
		return
	var skeleton := _find_player_skeleton()
	if skeleton != null:
		for bone in HAND_BONE_CANDIDATES:
			if skeleton.find_bone(bone) < 0:
				continue
			var attachment := BoneAttachment3D.new()
			attachment.name = "ToolAttachment"
			attachment.bone_name = bone
			skeleton.add_child(attachment)
			_prop_root = attachment
			return
	_prop_root = self


## `character_model.gd::skeleton()` off the player's own `Model` child -- the
## identical lookup `torch.gd::_find_player_skeleton()` does, and null for
## anything with no such rig.
func _find_player_skeleton() -> Skeleton3D:
	var parent := get_parent()
	if parent == null:
		return null
	var model := parent.get_node_or_null(^"Model")
	if model == null or not model.has_method("skeleton"):
		return null
	return model.call("skeleton") as Skeleton3D


## --- the swing -------------------------------------------------------------

## Everything harvestable in front of the trainer, nearest first, gathered
## through the node's OWN interaction contract so a swing and the interact
## prompt can never disagree about what a node yields.
func _resolve_swing() -> void:
	var body := get_parent() as Node3D
	if body == null:
		return
	var origin := body.global_position
	var facing := _facing_direction(body)

	var best: Node = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(HARVEST_LOGIC.GROUP):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		var target := (node as Node3D).global_position
		# The same cone arithmetic combat uses to decide whether a swing
		# connects (`combat_math.gd::in_hit_cone`) -- horizontal only, so a
		# node uphill of you is not unhittable for a reason you cannot see.
		if not COMBAT_MATH.in_hit_cone(origin, facing, target, SWING_REACH, SWING_ARC_DEGREES):
			continue
		var distance := origin.distance_to(target)
		if distance < best_distance:
			best_distance = distance
			best = node

	if best == null:
		return
	if best.has_method("gather"):
		# Forward the identity of the prop whose swing is resolving. Harvest
		# nodes use this exact held id rather than inferring permission from any
		# unrelated tool elsewhere in the Satchel. Other harvestables accept the
		# optional argument and retain their ungated semantics.
		best.call("gather", _equipped)
		swing_connected.emit(best)


## RG2. `body` (the `CharacterBody3D` this node is a child of) never rotates
## on its own -- `player_controller.gd::_apply_movement()` writes `velocity`
## directly in world space and turns only `Model`, the child that actually
## animates (`_face()`; `combat_manager.gd`'s own placement code says so in
## so many words: "the controller owns the model's yaw during exploration").
## So a cone test against `body`'s own basis was checking the direction the
## trainer spawned facing, forever, not the direction they walked up facing --
## which is why a swing connected only by accident and the owner's ROG report
## was "I can't swing at the stones or trees or anything."
##
## `Model`'s own forward is `+basis.z`, not Godot's usual `-basis.z` -- the
## rig is authored facing the opposite way from the engine default, and
## `_face()`'s `rotation.y = atan2(direction.x, direction.z)` was tuned
## against that real mesh, not against the convention. Verified directly
## (a smoke repro that walks the player up to a harvestable, turns ONLY
## `Model` toward it via that exact formula, and swings): `-basis.z` pointed
## the cone backward and the swing whiffed every time; `+basis.z` connects.
## Falls back to `body` itself with the engine's ordinary `-basis.z` when
## there is no `Model` child to ask (a capsule stand-in, a stripped-down test
## rig) -- that fallback body was never turned by anything with an opinion
## either way, so there is no measured convention to match, only the default.
func _facing_direction(body: Node3D) -> Vector3:
	var model := body.get_node_or_null(^"Model") as Node3D
	return model.global_transform.basis.z if model != null else -body.global_transform.basis.z


func _vector3_from(value: Variant) -> Vector3:
	if typeof(value) != TYPE_ARRAY:
		return Vector3.ZERO
	var array := value as Array
	if array.size() < 3:
		return Vector3.ZERO
	return Vector3(float(array[0]), float(array[1]), float(array[2]))
