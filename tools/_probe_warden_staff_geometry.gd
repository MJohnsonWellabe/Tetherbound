extends SceneTree

## WARDEN-STAFF-0909. Initialized component proof for the actual production
## Warden config and rank path. This deliberately runs after the SceneTree is
## active: BoneAttachment3D global transforms are undefined off-tree, and the
## staff's contract is that its five real nodes follow the right hand through
## motion. This installed rig names that bone `RightHand`.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")

const STAFF_PARTS := [
	"accessory_tether_staff_shaft",
	"accessory_tether_staff_control_ring",
	"accessory_tether_staff_control_hub",
	"accessory_tether_staff_leaf_left",
	"accessory_tether_staff_leaf_right",
]

var _assertions := 0
var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		_failures += 1
		push_error("WARDEN STAFF: %s" % message)


func _part(model: Node3D, part_name: String) -> MeshInstance3D:
	return model.call("find_part", part_name) as MeshInstance3D


func _attachment(part: MeshInstance3D) -> BoneAttachment3D:
	return part.get_parent() as BoneAttachment3D if part != null else null


func _check_pose(model: Node3D, label: String) -> void:
	var shaft := _part(model, STAFF_PARTS[0])
	var ring := _part(model, STAFF_PARTS[1])
	var hub := _part(model, STAFF_PARTS[2])
	var leaf_left := _part(model, STAFF_PARTS[3])
	var leaf_right := _part(model, STAFF_PARTS[4])
	if shaft == null or ring == null or hub == null or leaf_left == null or leaf_right == null:
		_check(false, "%s is missing at least one staff part" % label)
		return

	var grip := _attachment(shaft)
	_check(grip != null and grip.bone_name == "RightHand",
		"%s shaft is not attached to the installed RightHand bone" % label)
	if grip == null:
		return
	var grip_origin := grip.global_position
	var shaft_axis := shaft.global_basis.y.normalized()
	var shaft_center := shaft.global_position
	var along_grip := (grip_origin - shaft_center).dot(shaft_axis)
	var off_axis := ((grip_origin - shaft_center) - shaft_axis * along_grip).length()
	_check(absf(along_grip) < 0.825, "%s hand origin lies beyond the 1.65m shaft" % label)
	_check(off_axis < 0.02, "%s shaft misses Hand.R by %.4fm" % [label, off_axis])

	var top := shaft_center + shaft_axis * 0.825
	var bottom := shaft_center - shaft_axis * 0.825
	var head_distance := minf(top.distance_to(ring.global_position), bottom.distance_to(ring.global_position))
	_check(head_distance < 0.04,
		"%s control ring leaves a %.3fm gap from both shaft ends" % [label, head_distance])
	_check(ring.global_position.distance_to(hub.global_position) < 0.002,
		"%s control hub is not centred in its ring" % label)
	_check(leaf_left.global_position.distance_to(ring.global_position) < 0.14,
		"%s left leaf is detached from the control head" % label)
	_check(leaf_right.global_position.distance_to(ring.global_position) < 0.14,
		"%s right leaf is detached from the control head" % label)

	# Each piece uses its own BoneAttachment3D so config remains ordinary, but
	# all attachments must resolve the same live bone transform. If one falls
	# back to `_art`, this catches the prop splitting apart as the clip advances.
	for part_name: String in STAFF_PARTS.slice(1):
		var attachment := _attachment(_part(model, part_name))
		_check(attachment != null and attachment.bone_name == "RightHand",
			"%s %s is not attached to RightHand" % [label, part_name])
		if attachment != null:
			_check(attachment.global_position.distance_to(grip_origin) < 0.002,
				"%s %s resolved a different bone origin" % [label, part_name])

	print("WARDEN STAFF POSE %s grip=%s shaft_center=%s axis=%s head_gap=%.4f" % [
		label, grip_origin, shaft_center, shaft_axis, head_distance])


func _run() -> void:
	var direct := CHARACTER_MODEL.config_for("warden")
	var ranked := NPC_RANKS.config_for("warden")
	_check(not direct.is_empty(), "production art.json has no Warden config")
	_check(not ranked.is_empty(), "production rank path has no Warden config")
	var direct_accessories: Array = direct.get("accessories", [])
	var ranked_accessories: Array = ranked.get("accessories", [])
	_check(direct_accessories.size() == 5,
		"direct Warden should declare five staff pieces, got %d" % direct_accessories.size())
	_check(ranked_accessories.size() > direct_accessories.size(),
		"rank path did not append its badge pieces after the identity staff")
	# Deep-copy proof: mutating the returned rank config must not mutate either
	# a subsequent rank result or art.json's freshly parsed identity config.
	(ranked_accessories[0] as Dictionary)["name"] = "mutated_probe_value"
	var ranked_again: Dictionary = NPC_RANKS.config_for("warden")
	_check(str(((ranked_again.get("accessories", []) as Array)[0] as Dictionary).get("name", "")) ==
		"tether_staff_shaft", "rank accessory merge aliases mutable config data")
	_check(str(((CHARACTER_MODEL.config_for("warden").get("accessories", []) as Array)[0] as Dictionary).get("name", "")) ==
		"tether_staff_shaft", "rank accessory merge mutated the base identity config")

	var model := Node3D.new()
	model.name = "InitializedWardenStaffProbe"
	model.set_script(CHARACTER_MODEL)
	root.add_child(model)
	_check(bool(model.call("build_from_config", ranked_again)),
		"actual ranked Warden failed to build")
	await process_frame

	for part_name: String in STAFF_PARTS:
		_check(_part(model, part_name) != null, "%s was not instantiated" % part_name)
	var shaft := _part(model, STAFF_PARTS[0])
	_check(shaft != null and shaft.mesh is CylinderMesh,
		"staff shaft did not instantiate the configured cylinder")
	if shaft != null and shaft.mesh is CylinderMesh:
		var cylinder := shaft.mesh as CylinderMesh
		_check(is_equal_approx(cylinder.height, 1.65),
			"shaft height is %.3f, expected 1.65" % cylinder.height)
		_check(is_equal_approx(cylinder.top_radius * 2.0, 0.035),
			"shaft diameter is %.3f, expected 0.035" % (cylinder.top_radius * 2.0))

	var anim: AnimationPlayer = model.call("animation_player")
	_check(anim != null and anim.has_animation("idle") and anim.has_animation("walk"),
		"actual Warden is missing idle or walk")
	if anim != null:
		anim.play("idle")
		anim.seek(0.0, true)
		await process_frame
		_check_pose(model, "idle-0.00")
		if shaft != null:
			var axis := shaft.global_basis.y.normalized()
			var end_a := shaft.global_position + axis * 0.825
			var end_b := shaft.global_position - axis * 0.825
			var low_y := minf(end_a.y, end_b.y)
			var high_y := maxf(end_a.y, end_b.y)
			_check(low_y >= -0.12 and low_y <= 0.16,
				"idle shaft low end is %.3fm, not fitted to the standing ground plane" % low_y)
			_check(high_y > 1.25 and high_y < 1.65,
				"idle shaft high end is %.3fm, outside the board-16 shoulder-height silhouette" % high_y)
			var idle_ring := _part(model, STAFF_PARTS[1])
			var idle_grip := _attachment(shaft)
			_check(idle_ring != null and idle_grip != null and
				idle_ring.global_position.y > idle_grip.global_position.y,
				"idle control head is not above the gripping hand")
		anim.seek(0.72, true)
		await process_frame
		_check_pose(model, "idle-0.72")
		anim.play("walk")
		anim.seek(0.28, true)
		await process_frame
		_check_pose(model, "walk-0.28")
		anim.seek(0.91, true)
		await process_frame
		_check_pose(model, "walk-0.91")

	model.queue_free()
	await process_frame
	print("warden staff geometry: %d assertions, %d failed" % [_assertions, _failures])
	quit(1 if _failures > 0 else 0)
