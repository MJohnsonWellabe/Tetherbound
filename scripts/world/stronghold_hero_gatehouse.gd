extends RefCounted

## F38 P2-003 (close-1024, OFF until judged): the coordinator's Meshy hero
## gatehouse in front of the Meadows Hall's gate, so the stronghold reads as a
## fortress on the skyline rather than "a small dark ruin behind dominant
## pylons". Visual only: no collision, so the existing gate, ramp, doors and
## walkable route are unchanged. Uniform scale to `width_m`, base at the hall
## floor, centred on the gate mouth plus `offset` (local metres).

const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")


static func build(stronghold: Node3D, cfg: Dictionary, floor_y: float, mouth_z: float) -> Node3D:
	if not bool(cfg.get("enabled", false)):
		return null
	var scene := load(str(cfg.get("path", ""))) as PackedScene
	if scene == null:
		push_warning("stronghold hero gatehouse: %s did not load" % cfg.get("path", ""))
		return null
	var model := scene.instantiate() as Node3D
	var holder := Node3D.new()
	holder.name = "HeroGatehouse"
	stronghold.add_child(holder)
	holder.add_child(model)
	var bounds := RENDER_BOUNDS.measure(model)
	if bounds.size.x <= 0.001:
		holder.queue_free()
		return null
	var fit := float(cfg.get("width_m", 28.0)) / bounds.size.x
	model.scale = Vector3.ONE * fit
	model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * fit
	var offset: Array = cfg.get("offset", [0.0, 0.0, -4.0])
	holder.position = Vector3(float(offset[0]), floor_y + float(offset[1]), mouth_z + float(offset[2]))
	holder.rotation.y = deg_to_rad(float(cfg.get("yaw_deg", 0.0)))
	print("[stronghold] hero gatehouse: %.1f x %.1f x %.1f m" % [
		bounds.size.x * fit, bounds.size.y * fit, bounds.size.z * fit])
	return holder
