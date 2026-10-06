extends "res://tests/test_case.gd"

## Detached ownership/composition controls, not native prompt/contact,
## transport, key debit, durable save or owner ACK proof.
const HALL := preload("res://scripts/world/crossing_hall.gd")
const ACTION := preload("res://scripts/world/portal_arch.gd")

func test_hero_plaque_preserves_visible_named_signs_and_a_separate_static_emblem() -> void:
	var hall: Node3D = HALL.new()
	var slot := Node3D.new()
	hall.add_child(slot)
	var board := Label3D.new()
	board.name = "BiomeSign"
	board.text = "Tidewake"
	slot.add_child(board)
	var state := Label3D.new()
	state.name = "StateSign"
	state.text = "Locked"
	slot.add_child(state)
	var membrane := MeshInstance3D.new()
	membrane.name = "PortalSurface"
	membrane.material_override = StandardMaterial3D.new()
	slot.add_child(membrane)
	hall.call("_place_hero_arch_signs", slot, board, state, "tidewake")
	hall.get("_arches")["tidewake"] = slot
	assert_eq(slot.get_node(^"BiomeSign"), board)
	assert_eq(slot.get_node(^"StateSign"), state)
	assert_eq(board.text, "Tidewake")
	assert_true(board.visible)
	assert_true(state.visible)
	assert_false(board.no_depth_test)
	assert_false(board.double_sided)
	assert_eq(board.billboard, BaseMaterial3D.BILLBOARD_DISABLED)
	assert_true(board.position.y > 3.6, "candidate lettering does not occupy the passage")
	var emblem := slot.get_node(^"BiomeKeystone/BiomeEmblem") as Node3D
	assert_true(emblem.visible)
	hall.call("apply_display", {"portal_unlocks": ["tidewake"]})
	assert_eq(state.text, "Open", "the existing public display still owns the visible state text")
	assert_true(emblem.visible, "static identification is independent of earned shrine display")
	assert_eq(slot.get_child_count(), 4, "no extra plaque, action or collider is invented")
	hall.free()

func test_hero_cradles_follow_only_the_latest_shared_shrine_display() -> void:
	var hall: Node3D = HALL.new()
	for biome: String in ["meadows", "tidewake", "cloudreach", "stormwood"]:
		var slot := Node3D.new()
		hall.add_child(slot)
		hall.get("_pedestals")[biome] = slot
		hall.call("_add_hero_relic", slot, biome)
		var relic := slot.get_node(^"DisplayedRelic") as Node3D
		assert_false(relic.visible, "an empty cradle does not invent an earned relic")
		assert_true(relic.get_child_count() > 0, "each live biome has a physical relic, not metadata alone")
		hall.call("apply_display", {"shrine_display": {biome: true}})
		assert_true(relic.visible)
		assert_true(bool(slot.get_meta("relic_displayed")))
		hall.call("apply_display", {"shrine_display": {biome: false}})
		assert_false(relic.visible, "a fresh world display replaces the prior display")
		hall.call("apply_display", {})
		assert_false(relic.visible, "missing shared display is empty, not a cached personal hang")
	var reserved := Node3D.new()
	hall.add_child(reserved)
	hall.call("_add_hero_relic", reserved, "biome5")
	assert_eq(reserved.get_child_count(), 0, "sealed future biomes do not acquire a fabricated relic")
	var stock := Node3D.new()
	hall.add_child(stock)
	hall.get("_pedestals")["stock"] = stock
	hall.call("apply_display", {"shrine_display": {"stock": true}})
	assert_true(bool(stock.get_meta("relic_displayed")))
	assert_eq(stock.get_child_count(), 0, "fallback presentation remains unchanged")
	hall.free()

func test_hero_arch_membrane_and_stone_follow_the_existing_display_state() -> void:
	var hall: Node3D = HALL.new()
	var slot := Node3D.new()
	var action := Node3D.new()
	action.name = "PortalAction"
	slot.add_child(action)
	var membrane := MeshInstance3D.new()
	membrane.name = "PortalSurface"
	membrane.mesh = QuadMesh.new()
	membrane.material_override = StandardMaterial3D.new()
	slot.add_child(membrane)
	hall.call("_add_hero_stone_infill", slot)
	var stone := slot.get_node(^"PortalStoneInfill") as MeshInstance3D
	hall.call("_set_hero_arch_state", slot, "sealed")
	assert_true(membrane.visible, "installed fallback does not adopt candidate state geometry")
	assert_false(stone.visible)
	slot.set_meta("hero_art_used", true)
	for state: String in ["open", "locked", "sealed", "stirred"]:
		hall.call("_set_hero_arch_state", slot, state)
		assert_eq(membrane.visible, state in ["open", "locked"], "live states retain the actual membrane")
		assert_eq(stone.visible, state in ["sealed", "stirred"], "reserved states retain a physical-looking stone infill")
		assert_eq((stone.material_override as StandardMaterial3D).emission_enabled, state == "stirred", "sealed stone is unlit; the existing stirred state is preserved")
	assert_eq(slot.get_node(^"PortalAction"), action, "presentation cannot replace the canonical input carrier")
	assert_eq(slot.get_child_count(), 3, "state changes cannot duplicate surfaces or input")
	slot.free()
	hall.free()

func test_disabled_or_unavailable_hero_art_preserves_the_original_slot_carrier() -> void:
	var hall: Node3D = HALL.new()
	var slot := Node3D.new()
	var original := Node3D.new()
	original.name = "PortalAction"
	slot.add_child(original)
	for kind: String in ["arch", "pedestal"]:
		var asset := "res://assets/environment/crossing_hall/portal_arch/portal_arch.tscn" if kind == "arch" else "res://assets/environment/crossing_hall/shrine_pedestal/shrine_pedestal.tscn"
		for enabled: bool in [false, true]:
			var art := {"enabled": enabled}
			art[kind + "_model"] = "res://missing_hall_hero_candidate.tscn" if enabled else asset
			hall.set("_config", {"hero_art": art})
			assert_false(bool(hall.call("_add_hero_model", slot, kind)), "disabled or unavailable candidates use installed art")
			assert_eq(slot.get_child_count(), 1, "art lookup cannot mount an input carrier or duplicate a slot")
			assert_eq(slot.get_node(^"PortalAction"), original)
			assert_false(slot.has_meta("hero_art_used"), "unaccepted art cannot be recorded as installed")
	slot.free()
	hall.free()

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
