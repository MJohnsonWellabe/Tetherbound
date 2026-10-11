extends Node3D
## Owned physical sites; chapter owners mount these after their terrain is ready.
## Arena combat uses the existing director through MasterDuel, never a second
## trainer combat implementation. Every interaction is tap-start.
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const NPC := preload("res://scripts/npc/npc_body.gd")
const INTERACT := preload("res://scripts/world/interactable.gd")
const HARVEST := preload("res://scripts/masters/attuned_herb.gd")
@export var master_id := ""
## Lookups find sites by group instead of walking the realm every poll.
const FOUNDATION_GROUP := &"foundation_master_sites"
signal challenge_requested(site: Node3D)
signal chest_requested(site: Node3D)
var _definition: Dictionary = {}
var _mounted := false

func _enter_tree() -> void:
	add_to_group(FOUNDATION_GROUP)

func mount(world: Node3D, player: Node3D) -> bool:
	if _mounted: return true
	_definition = BREAKTHROUGH.master(master_id)
	if _definition.is_empty() or world == null or not world.has_method("ground_height_at"): return false
	var raw: Array = _definition.position
	var y: float = float(world.call("ground_height_at", float(raw[0]), float(raw[2])))
	if str(_definition.access) == "fly_only":
		# An isolated authored supported pad, beyond the existing crown needles.
		# Its declared altitude is intentional; no grounded route is introduced.
		y = float(raw[1])
	elif world.has_method("ground_height_near"):
		y = float(world.call("ground_height_near", Vector3(float(raw[0]), float(raw[1]), float(raw[2]))))
	if not is_finite(y): return false
	global_position = Vector3(float(raw[0]), y, float(raw[2]))
	_build_arena()
	if str(_definition.access) == "fly_only": _build_fly_supports()
	var npc := NPC.new()
	npc.name = "Master"
	add_child(npc)
	if not npc.setup(str(_definition.humanoid_key), player):
		npc.queue_free()
		return false
	npc.position = _vec(_definition.npc_offset)
	var prompt: Node3D = npc.add_prompt("Challenge %s" % str(_definition.name), float(_definition.prompt_radius_m))
	prompt.connect("activated", func() -> void: challenge_requested.emit(self))
	var reveal := Label3D.new()
	reveal.text = "%s · Lv %d\n%s · %s · %s\n%s" % [_definition.name, _definition.cap_level,
		_definition.species_id.capitalize(), "/".join(_definition.creature_types), _definition.profile, _definition.combat.question]
	reveal.font_size = 44
	# Free-standing world text: face the camera upright, never read mirrored.
	reveal.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	reveal.position = Vector3(0, 3, -4)
	add_child(reveal)
	var chest := Node3D.new()
	chest.name = "RecipeChest"
	chest.position = _vec(_definition.chest_offset)
	add_child(chest)
	var packed: Variant = load("res://assets/props/quaternius_fantasy/Chest_Wood.gltf")
	if packed is PackedScene: chest.add_child(packed.instantiate())
	var chest_prompt := INTERACT.new()
	chest_prompt.configure("Open %s's recipe chest" % str(_definition.name), float(_definition.prompt_radius_m), true)
	chest_prompt.connect("activated", func() -> void: chest_requested.emit(self))
	chest.add_child(chest_prompt)
	_build_sign(world)
	if int(_definition.tier) == 1: _mount_attuned_garden(world)
	if world.has_method("register_runtime_surface"):
		var radius := float(_definition.arena_radius_m)
		world.call("register_runtime_surface", {"kind": "ellipse", "centre": Vector2(global_position.x, global_position.z),
			"half": Vector2(radius, radius), "height": global_position.y + 0.2})
	# Presentation only: a realm may re-skin the generic pad and signpost in
	# its own families (Cloudreach seats a fly-only pad on a rooted rock islet).
	# Collision and every interaction above are unchanged.
	if world.has_method("dress_master_site"): world.call("dress_master_site", self, _definition)
	_mounted = true
	return true

## Built-floor consumers use the live pad collision, including its transform,
## rather than seating creatures in the terrain beneath this raised floor.
func built_floor_height_at(x: float, z: float) -> float:
	if not _mounted or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() \
		or not is_finite(x) or not is_finite(z): return NAN
	var body := get_node_or_null(^"ArenaCollision") as StaticBody3D
	if body == null or body.get_parent() != self or not body.is_inside_tree() or not body.is_node_ready() \
		or body.is_queued_for_deletion() or (body.collision_layer & 0x7FFFFFFF) == 0: return NAN
	var collision: CollisionShape3D = null
	for child: Node in body.get_children():
		if child is CollisionShape3D:
			if collision != null: return NAN
			collision = child as CollisionShape3D
		elif child is CollisionPolygon3D: return NAN
	if collision == null or not collision.is_inside_tree() or not collision.is_node_ready() \
		or collision.is_queued_for_deletion() or collision.disabled: return NAN
	var cylinder := collision.shape as CylinderShape3D
	if cylinder == null or not is_finite(cylinder.radius) or cylinder.radius <= 0.0 \
		or not is_finite(cylinder.height) or cylinder.height <= 0.0: return NAN
	var pose := collision.global_transform
	if not pose.origin.is_finite() or not pose.basis.x.is_finite() or not pose.basis.y.is_finite() \
		or not pose.basis.z.is_finite() or absf(pose.basis.determinant()) <= 0.000001: return NAN
	# A horizontal cylinder cap is a floor. Tilted or sheared geometry cannot
	# supply this scalar height contract; retain the normal terrain fallback.
	if pose.basis.y.y <= 0.0 or not pose.basis.y.normalized().is_equal_approx(Vector3.UP) \
		or not is_zero_approx(pose.basis.x.y) or not is_zero_approx(pose.basis.z.y) \
		or not is_zero_approx(pose.basis.x.normalized().dot(pose.basis.z.normalized())): return NAN
	var local := pose.affine_inverse() * Vector3(x, pose.origin.y, z)
	if not local.is_finite() or Vector2(local.x, local.z).length() > cylinder.radius: return NAN
	var top := pose * Vector3(0.0, cylinder.height * 0.5, 0.0)
	return top.y if top.is_finite() else NAN

func _build_arena() -> void:
	var radius := float(_definition.arena_radius_m)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.35
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("777969")
	material.roughness = 1.0
	mesh.material = material
	var visible := MeshInstance3D.new()
	visible.name = "ArenaFloor"
	visible.mesh = mesh
	visible.position.y = 0.025
	add_child(visible)
	var body := StaticBody3D.new()
	body.name = "ArenaCollision"
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = mesh.height
	collision.shape = shape
	body.position = visible.position
	body.add_child(collision)
	add_child(body)

func _build_sign(world: Node3D) -> void:
	var raw: Array = _definition.sign_position
	var y: float = float(world.call("ground_height_at", float(raw[0]), float(raw[2])))
	if str(_definition.access) == "fly_only": y = float(raw[1])
	if not is_finite(y): return
	var sign := Node3D.new()
	sign.name = "MasterSignpost"
	world.add_child(sign)
	sign.global_position = Vector3(float(raw[0]), y, float(raw[2]))
	var pole := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = Vector3(0.18, 2.4, 0.18)
	pole.mesh = shape
	pole.position.y = 1.2
	sign.add_child(pole)
	var words := Label3D.new()
	words.text = str(_definition.sign_text) + "\nFollow the side path →"
	var presentation: Dictionary = BREAKTHROUGH.masters().sign_presentation
	words.font_size = int(presentation.font_size)
	words.pixel_size = float(presentation.pixel_size_m)
	words.width = float(_definition.get("sign_width_px", presentation.width_px))
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.outline_size = int(presentation.outline_size)
	words.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	words.position = _vec(_definition.get("sign_text_offset_m", presentation.text_offset_m))
	sign.add_child(words)
	var lead := NPC.new()
	lead.name = "MasterLead"
	sign.add_child(lead)
	if lead.setup(str(_definition.lead_cast), null):
		lead.position = Vector3(3.5, 0, 0)
		var prompt: Node3D = lead.add_prompt("Ask %s about the Master" % str(_definition.lead_name))
		prompt.connect("activated", func() -> void:
			var service: Node = get_meta("breakthrough_service", null)
			if service != null: service.call("_message", str(_definition.lead_text)))

func _build_fly_supports() -> void:
	for offset: Array in _definition.get("support_offsets", []):
		var support := MeshInstance3D.new()
		var pillar := CylinderMesh.new()
		pillar.top_radius = float(_definition.get("support_radius_m", 2.0))
		pillar.bottom_radius = pillar.top_radius * 1.3
		pillar.height = float(_definition.get("support_depth_m", 40.0))
		support.mesh = pillar
		support.position = Vector3(float(offset[0]), -pillar.height * 0.5, float(offset[1]))
		add_child(support)

func _mount_attuned_garden(world: Node3D) -> void:
	for row: Dictionary in BREAKTHROUGH.feasts().get("attuned_sources", {}).get("nodes", []):
		var y: float = float(world.call("ground_height_at", float(row.at[0]), float(row.at[1])))
		if not is_finite(y): continue
		var node := HARVEST.new()
		node.source_id = str(row.id)
		node.service = get_meta("breakthrough_service", null)
		node.name = str(row.id)
		world.add_child(node)
		node.global_position = Vector3(float(row.at[0]), y, float(row.at[1]))
		node.setup(row)

static func _vec(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
