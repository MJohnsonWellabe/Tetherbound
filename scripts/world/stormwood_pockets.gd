extends Node3D

## WORLD §5.1 dead-end pockets: five walled clearings off the Stormwood roads,
## each holding one existing optional reward. Each clearing is closed on every
## side by a dead-trunk palisade with invisible static collision, except one
## mouth that faces its nearest road. `wall_boxes` is the single geometry
## source for the runtime colliders, the palisade and the tests.
const CONFIG_PATH := "res://data/config/stormwood_pockets.json"
const TRUNKS: Array[String] = [
	"res://assets/environment/stylized_nature/DeadTree_1.gltf",
	"res://assets/environment/stylized_nature/DeadTree_2.gltf",
	"res://assets/environment/stylized_nature/DeadTree_3.gltf",
]
## Collision reaches this far below the local ground so a slope under a
## 4 m segment never opens a gap beneath the wall.
const FOOTING_DEPTH_M := 3.0
const TRUNK_SCALE := 2.2


static func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH)) as Dictionary


## Horizontal frame of a pocket: `forward` points out through the mouth.
static func frame(pocket: Dictionary) -> Dictionary:
	var yaw := deg_to_rad(float(pocket.mouth_yaw_deg))
	var forward := Vector2(sin(yaw), cos(yaw))
	return {"centre": Vector2(float(pocket.at[0]), float(pocket.at[1])), "forward": forward,
		"right": Vector2(forward.y, -forward.x)}


## Wall segments as {centre: Vector2, along: Vector2 (unit), length: float}.
## The four sides sit just outside the interior square; the mouth side leaves
## a centred gap of `mouth_width_m`.
static func wall_boxes(pocket: Dictionary, cfg: Dictionary) -> Array[Dictionary]:
	var half := float(cfg.interior_half_m)
	var thick := float(cfg.wall_thickness_m)
	var reach := half + thick
	var offset := half + thick * 0.5
	var gap := float(cfg.mouth_width_m) * 0.5
	var runs: Array = [
		[Vector2(-reach, -offset), Vector2(reach, -offset)],  # back
		[Vector2(-offset, -reach), Vector2(-offset, reach)],  # left
		[Vector2(offset, -reach), Vector2(offset, reach)],  # right
		[Vector2(-reach, offset), Vector2(-gap, offset)],  # mouth, left of the gap
		[Vector2(gap, offset), Vector2(reach, offset)],  # mouth, right of the gap
	]
	var f: Dictionary = frame(pocket)
	var out: Array[Dictionary] = []
	for run: Array in runs:
		var a := _to_world(f, run[0])
		var b := _to_world(f, run[1])
		var pieces := maxi(1, ceili(a.distance_to(b) / float(cfg.wall_segment_m)))
		var along := (b - a).normalized()
		for i in pieces:
			var p0 := a.lerp(b, float(i) / pieces)
			var p1 := a.lerp(b, float(i + 1) / pieces)
			out.append({"centre": (p0 + p1) * 0.5, "along": along, "length": p0.distance_to(p1)})
	return out


## True when `at` lies inside the pocket's walkable interior square.
static func contains(pocket: Dictionary, cfg: Dictionary, at: Vector2) -> bool:
	var f: Dictionary = frame(pocket)
	var local := at - (f.centre as Vector2)
	var half := float(cfg.interior_half_m)
	return absf(local.dot(f.right)) <= half and absf(local.dot(f.forward)) <= half


static func _to_world(f: Dictionary, local: Vector2) -> Vector2:
	return (f.centre as Vector2) + (f.right as Vector2) * local.x + (f.forward as Vector2) * local.y


func build(world: Node3D) -> void:
	var cfg := config()
	var height := float(cfg.wall_height_m)
	var thick := float(cfg.wall_thickness_m)
	var show_models := not bool(world.get("simulation_only"))
	for pocket: Dictionary in cfg.pockets:
		var body := StaticBody3D.new()
		body.name = "Pocket_%s" % str(pocket.id)
		add_child(body)
		var walls := wall_boxes(pocket, cfg)
		for index in walls.size():
			var wall: Dictionary = walls[index]
			var centre: Vector2 = wall.centre
			var along: Vector2 = wall.along
			var ground := float(world.call("ground_height_at", centre.x, centre.y))
			var collision := CollisionShape3D.new()
			collision.name = "Wall%02d" % index
			var shape := BoxShape3D.new()
			shape.size = Vector3(float(wall.length), height + FOOTING_DEPTH_M, thick)
			collision.shape = shape
			collision.position = Vector3(centre.x, ground + (height - FOOTING_DEPTH_M) * 0.5, centre.y)
			collision.rotation.y = atan2(-along.y, along.x)
			body.add_child(collision)
			if show_models:
				_palisade(world, body, centre - along * float(wall.length) * 0.5, along, float(wall.length),
					float(cfg.palisade_spacing_m), index)


func _palisade(world: Node3D, parent: Node3D, start: Vector2, along: Vector2, length: float, spacing: float, salt: int) -> void:
	# At most `spacing` apart: the trunks read as the solid wall the collider is.
	var count := maxi(1, ceili(length / spacing))
	for i in count:
		var at := start + along * (float(i) + 0.5) * length / count
		var model := (load(TRUNKS[(salt + i) % TRUNKS.size()]) as PackedScene).instantiate() as Node3D
		model.position = Vector3(at.x, float(world.call("ground_height_at", at.x, at.y)) - 0.3, at.y)
		model.scale = Vector3.ONE * TRUNK_SCALE
		model.rotation.y = float((salt * 7 + i * 13) % 360) * PI / 180.0
		parent.add_child(model)
