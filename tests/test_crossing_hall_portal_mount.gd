extends "res://tests/test_case.gd"

## Detached ownership/composition controls, not native prompt/contact,
## transport, key debit, durable save or owner ACK proof.
const HALL := preload("res://scripts/world/crossing_hall.gd")
const ACTION := preload("res://scripts/world/portal_arch.gd")

class SessionGateDouble extends Node:
	var enabled := false
	func portal_runtime_ready() -> bool: return enabled

func test_late_admitted_session_mounts_original_canonical_input_once_per_actual_slot() -> void:
	var hall: Node3D = HALL.new()
	var session: Node = SessionGateDouble.new()
	var slot := Node3D.new()
	slot.name = "Arch_tidewake"
	hall.add_child(slot)
	hall.get("_arches")["tidewake"] = slot
	hall.call("_mount_portal_actions", session)
	assert_eq(slot.get_child_count(), 0, "shipping gate remains authoritative")
	session.set("enabled", true)
	hall.call("_mount_portal_actions", session)
	var original: Node = slot.get_node_or_null(^"PortalAction")
	assert_true(original != null)
	if original != null:
		assert_eq(original.get_script(), ACTION)
		assert_eq(original.get("arch_id"), "tidewake")
		assert_eq(original.get("_row").key_item, "tidewake_portal_key")
		assert_eq(original.position, Vector3.ZERO, "actual parent owns the authored transform")
		hall.call("_mount_portal_actions", session)
		assert_eq(slot.get_child_count(), 1)
		assert_eq(slot.get_node(^"PortalAction"), original)
	session.set("enabled", false)
	hall.call("_mount_portal_actions", session)
	assert_eq(slot.get_child_count(), 1, "gate changes cannot replace a pending input carrier")
	# The same Hall presentation keeps reserved stone closures separate from
	# canonical portal inputs and host-owned unlock/stirred state.
	var visual: Node3D = HALL.new()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/crossing_hall.json"))
	visual.set("_config", config)
	assert_false(config.arch_sealed_infill.enabled, "unjudged infill ships off")
	for index: int in [1, 4, 5, 6, 7]:
		visual.call("_build_arch", config.arches[index])
		var arch: Node3D = visual.call("arch", str(config.arches[index].id))
		assert_false(arch.has_node(^"SealedStoneInfill"))
	config.arch_sealed_infill.enabled = true
	for index: int in [1, 4, 5, 6, 7]:
		var arch: Node3D = visual.call("arch", str(config.arches[index].id))
		visual.call("_build_arch_sealed_infill", arch)
		if index == 1:
			assert_false(arch.has_node(^"SealedStoneInfill"), "locked live road keeps original surface")
			continue
		var infill := arch.get_node_or_null(^"SealedStoneInfill") as Node3D
		assert_true(infill != null)
		if infill != null:
			assert_eq(infill.position, Vector3(0, .08, -.10))
			assert_eq(infill.scale, Vector3(.725, .76856847, 1))
		var count := arch.get_child_count()
		visual.call("_build_arch_sealed_infill", arch)
		assert_eq(arch.get_child_count(), count, "repeat build cannot duplicate closure")
	visual.call("apply_display", {})
	for index: int in [4, 5, 6, 7]:
		var arch: Node3D = visual.call("arch", str(config.arches[index].id))
		assert_eq(arch.get_meta("arch_state"), "sealed")
		assert_true((arch.get_node(^"SealedStoneInfill") as Node3D).visible)
		assert_false((arch.get_node(^"PortalSurface") as MeshInstance3D).visible)
	var stirred := {"fifth_arch_stirred": true, "portal_unlocks": ["tidewake"]}
	var before := stirred.duplicate(true)
	visual.call("apply_display", stirred)
	assert_eq(stirred, before, "presentation cannot mutate host gate state")
	var fifth: Node3D = visual.call("arch", "biome5")
	assert_eq(fifth.get_meta("arch_state"), "stirred")
	assert_false((fifth.get_node(^"SealedStoneInfill") as Node3D).visible)
	assert_true((fifth.get_node(^"PortalSurface") as MeshInstance3D).visible)
	assert_eq((visual.call("arch", "tidewake") as Node3D).get_meta("arch_state"), "open")
	visual.call("apply_display", {})
	assert_true((fifth.get_node(^"SealedStoneInfill") as Node3D).visible, "restored host view re-seals reserved road")
	visual.free()
	hall.free()
	session.free()

func test_foreign_slot_or_component_cannot_be_adopted_or_duplicated() -> void:
	var hall: Node3D = HALL.new()
	var foreign_world := Node3D.new()
	var session: Node = SessionGateDouble.new()
	session.set("enabled", true)
	var foreign_slot := Node3D.new()
	foreign_world.add_child(foreign_slot)
	hall.get("_arches")["cloudreach"] = foreign_slot
	hall.call("_mount_portal_actions", session)
	assert_eq(foreign_slot.get_child_count(), 0)
	var owned_slot := Node3D.new()
	hall.add_child(owned_slot)
	hall.get("_arches")["tidewake"] = owned_slot
	var foreign_action := Node3D.new()
	foreign_action.name = "PortalAction"
	owned_slot.add_child(foreign_action)
	hall.call("_mount_portal_actions", session)
	assert_eq(owned_slot.get_child_count(), 1)
	assert_eq(owned_slot.get_node(^"PortalAction"), foreign_action)
	assert_eq(foreign_action.get_script(), null)
	hall.free()
	foreign_world.free()
	session.free()
