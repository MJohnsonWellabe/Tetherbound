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
