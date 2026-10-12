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
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")

const PREFAB_NAME := "wagon"
const ITEM_IDS := ["wood", "stone", "fiber"]
const FLAG_ID := "band1_broken_cart_repaired"
const MET_FLAG := "broken_cart_met"

## Coll's thanks. The repair used to be the one Meadows activity that spent
## materials and paid nothing back; every other one returns something the five
## can use (Doss pays 45 coins and a large potion for less). 25 coins is about
## double the materials' shop value -- a modest net gain, not a farm. Paid as an
## ordinary per-character `reward_grant`, so the ledger journals it by stable
## source: idempotent across re-sends and reconnects, held pending on a full
## satchel, and only ever addressed to the peer who actually paid. TUNABLE.
const REWARD_SOURCE := "broken_cart_coll:repair"
const REWARD_COINS := 25
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
## F03#1 r11 judge: Coll says the wheel is cracked and the axle split, but the
## one-piece wagon looked whole. While broken, a clip shader hides the
## low-side (-x) wheel on the wagon and a second copy of the same mesh, clipped
## to just that wheel, lies flat beside the cart; repair clears both. The
## wheel's centre and radius are in Prop_Wagon's own mesh space (measured from
## Cube.043's vertices: x +-0.78..0.98, y 0..1.06, z -2.91..-1.81).
const WHEEL_CENTRE := Vector3(-0.88, 0.55, -2.36)
const WHEEL_RADIUS := 0.6
const WHEEL_SIDE_X := 0.74
## Where the loose wheel lies, cart-local, and Coll's stand.
const LOOSE_WHEEL_AT := Vector3(-2.0, 0.1, -0.9)
const COLL_AT := Vector2(2.1, -0.6)
const COLL_SPEC := {"name": "Coll", "config_key": "villager_keeper"}
## F03#1 r11 judge: the hand-in has to be readable at the cart. Once the
## satchel holds one of each material the prompt names the turn-in and its
## cost; otherwise it stays the inspection prompt. Checked on a short timer.
const LOOK_LABEL := "Look at the cart"
const REPAIR_LABEL := "Repair the cart: hand over wood, stone, fiber"
const LABEL_CHECK_S := 0.4
var _label_clock := 0.0
const NPC := preload("res://scripts/npc/npc_body.gd")
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const WHEEL_CLIP_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_col : source_color = vec4(1.0);
uniform vec3 wheel_centre;
uniform float wheel_radius;
uniform float side_x;
uniform bool keep_wheel;
varying vec3 local_pos;
void vertex() { local_pos = VERTEX; }
void fragment() {
	bool in_wheel = (local_pos.x * sign(wheel_centre.x) > side_x)
		&& length(local_pos.yz - wheel_centre.yz) < wheel_radius;
	if (in_wheel != keep_wheel) { discard; }
	ALBEDO = texture(albedo_tex, UV).rgb * albedo_col.rgb;
	ROUGHNESS = 0.85;
}
"""
const CHOCKS_PREFAB := "cart_repair_chocks"

var _gate: RefCounted = null
var _prompt: Node3D = null
var _assembly: Node3D = null
var _wagon: Node3D = null
var _patch: Node3D = null
var _chocks: Node3D = null
## The wagon's own mesh instances and their clip materials (broken state).
var _wagon_meshes: Array[MeshInstance3D] = []
var _wheel_clip_shader: Shader = null
var _loose_wheel: Node3D = null
## Per wagon mesh: [original surface override per surface, clip material per
## surface]. Cached once at build, so repeated pose calls never read back a
## clip material as the "original" (r12 render: the cart went white) and
## repair restores the prefab's own (possibly tinted) overrides exactly.
var _wagon_surfaces: Dictionary = {}
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
	_build_broken_wheel()
	_build_coll(world)

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
	_prompt.call("configure", LOOK_LABEL, 3.6, true)
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
	_pay_back()
	return true


## Only called after this peer's own cost was really taken, so a watcher who
## never paid is never thanked.
func _pay_back() -> void:
	LEDGER_CLAIM.submit(self, {
		"kind": "reward_grant",
		"realm": "meadows",
		"source": REWARD_SOURCE,
		"item": "coin",
		"count": REWARD_COINS,
	})


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
	_set_wheel_off(true)
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
	_set_wheel_off(false)
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
		_pay_back()
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


## Broken-state presentation: clip the low-side wheel off the wagon and lay a
## wheel-only copy of the same mesh flat beside it. No new asset.
func _build_broken_wheel() -> void:
	_wheel_clip_shader = Shader.new()
	_wheel_clip_shader.code = WHEEL_CLIP_SHADER
	for node: Node in _wagon.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			_wagon_meshes.append(mi)
	if _wagon_meshes.is_empty():
		return
	for mi: MeshInstance3D in _wagon_meshes:
		var originals: Array = []
		var clips: Array = []
		for surface in mi.mesh.get_surface_count():
			originals.append(mi.get_surface_override_material(surface))
			clips.append(_clip_material(mi, surface, false))
		_wagon_surfaces[mi] = [originals, clips]
	var source := _wagon_meshes[0]
	_loose_wheel = Node3D.new()
	_loose_wheel.name = "LooseWheel"
	add_child(_loose_wheel)
	_loose_wheel.position = LOOSE_WHEEL_AT
	# The wheel's axle runs along mesh x; rolling 90 degrees lays it flat.
	_loose_wheel.rotation = Vector3(0.0, deg_to_rad(20.0), deg_to_rad(90.0))
	var wheel := MeshInstance3D.new()
	wheel.name = "Wheel"
	wheel.mesh = source.mesh
	wheel.position = -WHEEL_CENTRE
	for surface in source.mesh.get_surface_count():
		wheel.set_surface_override_material(surface, _clip_material(source, surface, true))
	_loose_wheel.add_child(wheel)


func _clip_material(source: MeshInstance3D, surface: int, keep_wheel: bool) -> ShaderMaterial:
	var original := source.get_active_material(surface) as BaseMaterial3D
	var material := ShaderMaterial.new()
	material.shader = _wheel_clip_shader
	if original != null:
		material.set_shader_parameter("albedo_tex", original.albedo_texture)
		material.set_shader_parameter("albedo_col", original.albedo_color)
	material.set_shader_parameter("wheel_centre", WHEEL_CENTRE)
	material.set_shader_parameter("wheel_radius", WHEEL_RADIUS)
	material.set_shader_parameter("side_x", WHEEL_SIDE_X)
	material.set_shader_parameter("keep_wheel", keep_wheel)
	return material


func _set_wheel_off(off: bool) -> void:
	for mi: MeshInstance3D in _wagon_meshes:
		if not is_instance_valid(mi) or not _wagon_surfaces.has(mi):
			continue
		var originals: Array = _wagon_surfaces[mi][0]
		var clips: Array = _wagon_surfaces[mi][1]
		for surface in mi.mesh.get_surface_count():
			mi.set_surface_override_material(surface, clips[surface] if off else originals[surface])
	if _loose_wheel != null and is_instance_valid(_loose_wheel):
		_loose_wheel.visible = off


## Coll, the cart's owner, stands by it in the installed villager body his
## portrait already uses (villager_male = villager_keeper). Presence only: the
## cart's own prompt stays the one interaction.
func _build_coll(world: Node3D) -> void:
	var player := world.get_node_or_null(^"Player") as Node3D
	var npc: Node3D = NPC.new()
	npc.name = "Coll"
	add_child(npc)
	if not bool(npc.call("setup_from_config", VILLAGE_NPCS.model_config(COLL_SPEC), player)):
		npc.queue_free()
		return
	var at := global_transform * Vector3(COLL_AT.x, 0.0, COLL_AT.y)
	if not bool(npc.call("stand_at", at.x, at.z)):
		npc.queue_free()
		return
	var to := global_position - npc.global_position
	npc.global_rotation.y = atan2(to.x, to.z)


func _process(delta: float) -> void:
	_label_clock -= delta
	if _label_clock > 0.0 or _prompt == null or not is_instance_valid(_prompt) or _gate == null:
		return
	_label_clock = LABEL_CHECK_S
	var game := get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	var ready := inventory != null and not is_repaired() and bool(_gate.can_open(inventory))
	var label := REPAIR_LABEL if ready else LOOK_LABEL
	if str(_prompt.get("label")) != label:
		_prompt.set("label", label)
