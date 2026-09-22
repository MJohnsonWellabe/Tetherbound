extends Node3D

## T3-ACTIVITIES. Spec sec6's "Broken Cart: gather materials to repair a
## bridgehand's cart" -- Band 1's Local Request.
##
## Reuses two mechanisms that already exist rather than inventing a third
## "turn in materials" system: `item_gate.gd` (SB10, already the South Bridge
## key's and the three Sigils' own "does the player have what it takes" check
## -- a multi-item gate consumes exactly one of each id it names, which is
## what "gather wood, stone and fiber and hand them over" needs) and the
## `building_prefabs.gd`/`Prop_Wagon` visual `data/config/village.json`
## already parks once by the workshop (`_why`: "Bible secE names carts among
## what embeds a building"). No new mesh, no new turn-in mechanic.
##
## Deliberately NOT `road_gate.gd`: that file's own leaf/lock/wing machinery
## exists to physically block a road, and a parked cart on the shoulder blocks
## nothing. This is the same shape stripped to what a stationary, repairable
## prop actually needs -- a visual, a collision box so it reads as a real
## object, a prompt, and the shared item_gate contract.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const ITEM_GATE := preload("res://scripts/world/item_gate.gd")
## Stage B lane 5.A. A repaired cart is a WORLD fact.
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")

const PREFAB_NAME := "wagon"
const ITEM_IDS := ["wood", "stone", "fiber"]
const FLAG_ID := "band1_broken_cart_repaired"
const MET_FLAG := "broken_cart_met"
const BROKEN_CONVERSATION := "broken_cart_broken"
const REPAIRED_CONVERSATION := "broken_cart_repaired"

## The source wagon is one imported mesh (`Prop_Wagon` / `Cube.043`), not a
## wheel rig. The honest broken read is therefore the complete cart resting on
## its low side. Repair straightens that same mesh, adds installed kit pieces
## over the low-side wheel, and rolls the complete visual+collision farther
## onto the existing shoulder. At this site's 40-degree yaw the configured
## offset is about (+0.79, +2.34) world XZ and the assembly turns to present a
## three-quarter silhouette: the cart's solid edge remains about six metres
## from the route centre and over twenty metres from the approach fence.
const DEFAULT_BROKEN_ROLL_DEG := 11.0
const DEFAULT_BROKEN_LIFT_M := 0.19
const DEFAULT_REPAIRED_LOCAL_OFFSET := Vector3(-0.9, 0.0, 2.3)
const DEFAULT_REPAIRED_YAW_DEG := -25.0
const DEFAULT_REPAIR_SECONDS := 1.1
const PATCH_PREFAB := "cart_repair_patch"
const CHOCKS_PREFAB := "cart_repair_chocks"

var _gate: RefCounted = null
var _prompt: Node3D = null
var _assembly: Node3D = null
var _wagon: Node3D = null
var _patch: Node3D = null
var _chocks: Node3D = null
var _broken_roll_deg := DEFAULT_BROKEN_ROLL_DEG
var _broken_lift_m := DEFAULT_BROKEN_LIFT_M
var _repaired_local_offset := DEFAULT_REPAIRED_LOCAL_OFFSET
var _repaired_yaw_deg := DEFAULT_REPAIRED_YAW_DEG
var _repair_seconds := DEFAULT_REPAIR_SECONDS
var _repaired_assembly_position := Vector3.ZERO
var _pose_tween: Tween = null
## Set when THIS peer asked to fix the cart and the host had not answered yet.
## Its cost is taken when the world flag it asked for actually lands, never on
## the request itself. See `_on_tried()`.
var _owed_turn_in := false


func build(world: Node3D, at: Vector2, yaw_deg: float) -> void:
	_gate = ITEM_GATE.new(ITEM_IDS, FLAG_ID)
	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		push_error("no building recipes; the broken cart cannot build its wagon")
		return
	var template_holder := Node3D.new()
	template_holder.name = "PrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	prefabs.call("set_template_holder", template_holder)

	_wagon = prefabs.call("instantiate", PREFAB_NAME)
	if _wagon == null:
		push_error("broken cart prefab missing: %s" % PREFAB_NAME)
		return
	_patch = prefabs.call("instantiate", PATCH_PREFAB)
	_chocks = prefabs.call("instantiate", CHOCKS_PREFAB)
	if _patch == null or _chocks == null:
		push_error("broken cart repair presentation prefabs are missing")
		_free_detached_presentation()
		return
	_read_presentation(prefabs.call("recipe", PATCH_PREFAB) as Dictionary)

	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the broken cart at %.0f, %.0f" % [at.x, at.y])
		return

	position = Vector3(at.x, ground - 0.05, at.y)
	rotation.y = deg_to_rad(yaw_deg)

	_assembly = Node3D.new()
	_assembly.name = "WagonAssembly"
	add_child(_assembly)
	_wagon.name = "Wagon"
	_wagon.position.y = _broken_lift_m
	_wagon.rotation.z = deg_to_rad(_broken_roll_deg)
	_assembly.add_child(_wagon)

	_patch.name = "RepairPatch"
	_patch.visible = false
	_wagon.add_child(_patch)
	_chocks.name = "RepairChocks"
	_chocks.visible = false
	add_child(_chocks)

	var repaired_offset_world := Basis(Vector3.UP, rotation.y) * _repaired_local_offset
	var repaired_x := at.x + repaired_offset_world.x
	var repaired_z := at.y + repaired_offset_world.z
	var repaired_ground: float = float(world.call("ground_height_at", repaired_x, repaired_z))
	if is_nan(repaired_ground):
		push_error("no ground under the repaired cart at %.0f, %.0f" % [repaired_x, repaired_z])
		return
	_repaired_assembly_position = Vector3(
		_repaired_local_offset.x, repaired_ground - ground, _repaired_local_offset.z)

	# Ask for the assembly's AABB so the broken roll/lift is included. The same
	# conservative box moves with the assembly during the repair and remains a
	# close fit after the wagon straightens.
	var aabb: AABB = prefabs.call("combined_aabb", _assembly)
	var body := StaticBody3D.new()
	body.name = "Collision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size
	shape.shape = box
	shape.position = aabb.get_center()
	body.add_child(shape)
	_assembly.add_child(body)

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 1.0
	_prompt.call("configure", "Look at the cart", 3.6, true)
	_prompt.connect("activated", _on_tried)
	add_child(_prompt)

	# Stage B lane 5.A: a repaired cart is a WORLD fact (D99), so the pose is
	# restored from the world's store and re-checked when a delta lands --
	# a cart the other player fixed is fixed here too.
	add_to_group("progression_restore")
	STORY_LEDGER.listen(self, _on_delta_applied)
	restore_progression_from_game(get_node_or_null(^"/root/Game"))


func is_repaired() -> bool:
	return STORY_LEDGER.world_flag(self, FLAG_ID)


## The `progression_restore` seam: a save load, a joiner's snapshot, or another
## peer's delta. Idempotent.
func restore_progression_from_game(_game: Node) -> void:
	if is_repaired():
		_apply_repaired_pose(false)
	else:
		_apply_broken_pose()


func _on_delta_applied(delta: Dictionary) -> void:
	if not _delta_replaces_flag(delta):
		return
	if STORY_LEDGER.delta_sets_world_flag(delta, FLAG_ID):
		_settle_owed_turn_in()
		_apply_repaired_pose(true)
	else:
		# The flag came back off. Whatever this peer still owed is owed no
		# longer; it must not pay for a cart that is broken again.
		_owed_turn_in = false
		_apply_broken_pose()


## Take the payment this peer promised when its request was still pending, at
## the moment the world fact it asked for actually arrives.
##
## Only the peer that ASKED owes anything: `_owed_turn_in` is set solely in
## `_on_tried()`, so a friend who merely watches the cart get fixed is never
## charged for it. It is cleared before spending, so a second delta for the same
## flag -- a re-send, a reconnect snapshot, a late duplicate -- cannot take the
## materials twice.
func _settle_owed_turn_in() -> void:
	if not _owed_turn_in:
		return
	_owed_turn_in = false
	var game := get_node_or_null(^"/root/Game")
	take_owed_payment(game.get("inventory") if game != null else null)


## The payment itself, separated from finding the inventory so it can be driven
## directly by a test. Returns whether the cost was actually taken.
func take_owed_payment(inventory: RefCounted) -> bool:
	if inventory == null or _gate == null:
		return false
	if not _gate.can_open(inventory):
		# The materials went somewhere else while the host was deciding. The
		# cart is fixed and the world says so; this peer does not pay for what
		# it no longer has, and does not pay twice. Reported, not silent.
		push_warning("cart turn-in committed but this peer no longer holds the cost")
		return false
	_gate.spend(inventory)
	if _prompt != null:
		_prompt.call("set_enabled", false)
	return true


func _read_presentation(recipe: Dictionary) -> void:
	var presentation: Dictionary = recipe.get("presentation", {})
	_broken_roll_deg = float(presentation.get("broken_roll_deg", DEFAULT_BROKEN_ROLL_DEG))
	_broken_lift_m = float(presentation.get("broken_lift_m", DEFAULT_BROKEN_LIFT_M))
	_repair_seconds = maxf(0.01,
		float(presentation.get("repair_seconds", DEFAULT_REPAIR_SECONDS)))
	_repaired_yaw_deg = float(presentation.get(
		"repaired_yaw_deg", DEFAULT_REPAIRED_YAW_DEG))
	var raw_offset: Array = presentation.get("repaired_local_offset", [])
	if raw_offset.size() >= 3:
		_repaired_local_offset = Vector3(
			float(raw_offset[0]), float(raw_offset[1]), float(raw_offset[2]))


func _delta_replaces_flag(delta: Dictionary) -> bool:
	for raw: Variant in delta.get("ops", []):
		if raw is Dictionary:
			var op := raw as Dictionary
			if str(op.get("scope", "")) == "world" and str(op.get("op", "")) == "flag" \
					and str(op.get("id", "")) == FLAG_ID:
				return true
	return false


func _free_detached_presentation() -> void:
	for raw: Variant in [_wagon, _patch, _chocks]:
		var node := raw as Node3D
		if node != null and is_instance_valid(node) and node.get_parent() == null:
			node.free()
	_wagon = null
	_patch = null
	_chocks = null


func _apply_broken_pose() -> void:
	if _assembly == null or _wagon == null:
		return
	if _pose_tween != null and _pose_tween.is_valid():
		_pose_tween.kill()
	_assembly.position = Vector3.ZERO
	_assembly.rotation.y = 0.0
	_wagon.position.y = _broken_lift_m
	_wagon.rotation.z = deg_to_rad(_broken_roll_deg)
	if _patch != null and is_instance_valid(_patch):
		_patch.visible = false
	if _chocks != null and is_instance_valid(_chocks):
		_chocks.visible = false
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.call("set_enabled", true)


## One terminal presentation path for the local press, another peer's delta,
## save restore and late join. Re-entry is harmless: an in-flight tween is
## replaced and an already-terminal cart simply receives the same transforms.
func _apply_repaired_pose(animate: bool) -> void:
	if _assembly == null or _wagon == null:
		return
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.call("set_enabled", false)
	if _patch != null and is_instance_valid(_patch):
		_patch.visible = true
	if _chocks != null and is_instance_valid(_chocks):
		_chocks.visible = true
	if _pose_tween != null and _pose_tween.is_valid():
		_pose_tween.kill()
	if not animate:
		_assembly.position = _repaired_assembly_position
		_assembly.rotation.y = deg_to_rad(_repaired_yaw_deg)
		_wagon.position.y = 0.0
		_wagon.rotation.z = 0.0
		return
	_pose_tween = create_tween().set_parallel(true)
	_pose_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_pose_tween.tween_property(_assembly, "position", _repaired_assembly_position, _repair_seconds)
	_pose_tween.tween_property(_assembly, "rotation:y",
		deg_to_rad(_repaired_yaw_deg), _repair_seconds)
	_pose_tween.tween_property(_wagon, "position:y", 0.0, _repair_seconds)
	_pose_tween.tween_property(_wagon, "rotation:z", 0.0, _repair_seconds)


func _on_tried() -> void:
	if is_repaired():
		return
	var game := get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	# Meeting the cart is a world fact too (`broken_cart_met`), so it is
	# committed rather than written locally: a friend who walks up second finds
	# a cart the world has already been introduced to.
	STORY_LEDGER.write_flag(self, MET_FLAG)
	if inventory == null or not _gate.can_open(inventory):
		_say(BROKEN_CONVERSATION)
		return
	var verdict := STORY_LEDGER.set_world_flag(self, FLAG_ID)
	if not bool(verdict.get("ok", false)) and not bool(verdict.get("pending", false)):
		_say(BROKEN_CONVERSATION)
		return
	# PAY WHEN THE WORLD AGREES, NOT WHEN THIS PEER ASKS.
	#
	# `ledger_claim.gd` says it plainly: pending must change nothing locally.
	# This path used to spend the moment it had asked, which split the cost from
	# the public fact in both directions. Two peers who both walked up could
	# both pay for the one idempotent flag -- the host's second commit is a
	# no-op, so the materials simply vanished -- and a refusal or a disconnect
	# after a `pending` stranded the payer's materials for a cart that never got
	# fixed.
	#
	# A host answers `ok` synchronously, so it pays here and nothing is
	# outstanding. A client answers `pending`, and its payment now waits for the
	# same delta that repairs the cart: `_on_delta_applied()` spends exactly
	# when the flag it asked for actually lands. If the host refuses, or the
	# client drops, the delta never arrives and nothing was taken.
	if bool(verdict.get("ok", false)):
		_gate.spend(inventory)
		_prompt.call("set_enabled", false)
	else:
		_owed_turn_in = true
	_say(REPAIRED_CONVERSATION)


func _say(conversation_id: String) -> void:
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		push_warning("no node in the 'dialogue_panel' group; the cart has nothing to say")
		return
	if bool(panel.call("is_open")):
		return
	panel.call("start", conversation_id)
