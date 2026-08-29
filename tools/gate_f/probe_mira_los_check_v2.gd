extends SceneTree

## T2-BUILDPLACE round 2 diagnostic: replaces the deleted, unreliable
## `probe_mira_los_check.gd` (round 1 reimplemented `_has_line_of_sight`'s
## raycast by hand and likely hit Mira's own collision body instead of real
## wall geometry). This one calls Mira's REAL, LIVE `Interactable` node's own
## `_has_line_of_sight()` and `interaction_offer()` methods directly -- no
## reimplementation of the clearance-trimmed raycast at all.
##
## OF31 moved Mira indoors (data/config/village_npcs.json:47): she stands
## inside cottage_a behind her counter, at the building's local (0,-1.4),
## the building at world (18,-2) yawed -135 deg. A straight-line walk whose
## stopping point lands within her 3.8m radius but OUTSIDE the cottage wall
## would pass the arbiter's distance check and still fail LOS forever --
## exactly the "still open" shape the prior session's handover described
## (walks landing 2.27-4.9m short, or reading refused with no clear reason).
##
## This probe:
##   1. prints Mira's live position, her Interactable's radius/global_position
##   2. sweeps a ring of points at several radii/angles around her, calling
##      her REAL _has_line_of_sight() and interaction_offer() on each, so the
##      open doorway direction (LOS clear) is directly distinguishable from
##      the wall directions (LOS blocked) -- a real answer, not a guess.
##   3. locates the real village_door.gd hinge nearest cottage_a, so the
##      doorway's actual world position is on record rather than derived by
##      hand-rolled trig.
##
##   godot --headless --path . --script tools/gate_f/probe_mira_los_check_v2.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const BRYN_POS := Vector2(13.0, 9.0)


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var mira := world.find_child("Mira", true, false)
	if mira == null:
		mira = _find_by_name(root, "Mira")
	if mira == null:
		print("PROBE FAIL: no node named Mira anywhere in the tree")
		quit(1)
		return
	var mira3d := mira as Node3D
	print("Mira live position: %s" % str(mira3d.global_position))

	var interactable := _find_interactable(mira)
	if interactable == null:
		print("PROBE FAIL: Mira has no Interactable child")
		quit(1)
		return
	var radius := float(interactable.get("radius"))
	print("Mira Interactable global_position: %s, radius: %.2f" % [
		str((interactable as Node3D).global_position), radius])

	var door := _find_by_script(root, "village_door.gd")
	if door != null:
		var nearest_door: Node3D = null
		var nearest_d := INF
		var d0 := (door as Node3D).global_position.distance_to(mira3d.global_position)
		if d0 < nearest_d:
			nearest_d = d0
			nearest_door = door as Node3D
		print("nearest village_door.gd found: %s at %s (%.2f m from Mira)" % [
			str((door as Node3D).name), str((door as Node3D).global_position), d0])
	else:
		print("no village_door.gd instance found anywhere")

	print("")
	print("Bryn's position (13,9) -> Mira: bearing %.1f deg, flat distance %.2f m" % [
		rad_to_deg(atan2(mira3d.global_position.x - BRYN_POS.x, -(mira3d.global_position.z - BRYN_POS.y))),
		Vector2(mira3d.global_position.x, mira3d.global_position.z).distance_to(BRYN_POS)])

	print("")
	print("--- LOS sweep around Mira (real _has_line_of_sight / interaction_offer) ---")
	print("angle_deg, radius_m, world_x, world_z, distance_ok, los_clear, offer_label")
	for radius_variant in [1.5, 2.0, 2.5, 3.0, 3.5, 3.8, 4.5]:
		var radius_m: float = radius_variant
		for angle_variant in range(0, 360, 15):
			var angle_deg: int = angle_variant
			var rad: float = deg_to_rad(float(angle_deg))
			var probe_pos: Vector3 = mira3d.global_position + Vector3(sin(rad), 0.0, cos(rad)) * radius_m
			# Ground-clamp isn't attempted here -- the flat interior/exterior at
			# this footprint is within a fraction of a metre of Mira's own y,
			# and _has_line_of_sight only cares about the horizontal path plus
			# the fixed eye-height offset it applies itself.
			probe_pos.y = mira3d.global_position.y
			var los: bool = bool(interactable.call("_has_line_of_sight", probe_pos))
			var offer: Dictionary = interactable.call("interaction_offer", probe_pos)
			var dist_ok: bool = probe_pos.distance_to((interactable as Node3D).global_position) <= radius
			print("%d, %.1f, %.2f, %.2f, %s, %s, %s" % [
				angle_deg, radius_m, probe_pos.x, probe_pos.z, dist_ok, los,
				str(offer.get("label", "(none)"))])

	quit(0)


func _find_interactable(node: Node) -> Node:
	for child in node.get_children():
		if str(child.name) == "Interactable":
			return child
		var script: Script = child.get_script()
		if script != null and str(script.resource_path).ends_with("interactable.gd"):
			return child
	return null


func _find_by_name(node: Node, name: String) -> Node:
	if str(node.name) == name:
		return node
	for child in node.get_children():
		var found := _find_by_name(child, name)
		if found != null:
			return found
	return null


func _find_by_script(node: Node, suffix: String) -> Node:
	var script: Script = node.get_script()
	if script != null and str(script.resource_path).ends_with(suffix):
		return node
	for child in node.get_children():
		var found := _find_by_script(child, suffix)
		if found != null:
			return found
	return null
