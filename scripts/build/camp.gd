extends Node3D

## The first camp: a campfire and a bedroll, and the rest that ends day one.
##
## data/items/buildables.json has carried `camp` ("contains: Campfire,
## Bedroll") since the build screen shipped, with a comment admitting nothing
## places geometry. This is the geometry: the Quaternius Survival pack's
## bonfire (docs/ASSET_LEDGER.md) with a light and embers, and a bedroll built
## from the furniture bed at ground level. Resting fades the world out,
## advances `Game.day`, heals the party and the trainer, and fades back in —
## GAME_DESIGN.md's early tutorial ends exactly here: "build campfire + bed
## and rest with starter."

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const BONFIRE := "res://assets/props/quaternius_survival/Bonfire_Fire.obj"
const BEDROLL := "res://assets/props/quaternius_furniture/BedTwin.obj"

const FADE_SECONDS := 1.2

var _ghost_meshes: Array[MeshInstance3D] = []


## The see-through preview the placer drags around. No collision, no prompt.
func build_ghost() -> void:
	_spawn_meshes(false)


## The real thing: solid, lit, and offering rest.
func build_real() -> void:
	_spawn_meshes(true)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 1.2, 0.0)
	light.light_color = Color(1.0, 0.72, 0.45)
	light.light_energy = 2.8
	light.omni_range = 10.0
	light.shadow_enabled = true
	add_child(light)

	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(1.6, 0.5, 0.0)
	prompt.call("configure", "Rest until morning", 2.6, true)
	prompt.connect("activated", _on_rest)
	add_child(prompt)


func _spawn_meshes(solid: bool) -> void:
	_ghost_meshes.clear()
	var fire := _mesh(BONFIRE, Vector3.ZERO, 0.55)
	var roll := _mesh(BEDROLL, Vector3(1.8, 0.0, 0.6), 0.45)
	if roll != null:
		roll.rotation.y = deg_to_rad(30.0)
	if not solid:
		for m in [fire, roll]:
			if m != null:
				_ghost_meshes.append(m)
		return
	for m in [fire, roll]:
		if m == null:
			continue
		var aabb: AABB = (m.mesh as Mesh).get_aabb()
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = aabb.size * m.scale.x
		shape.shape = box
		body.add_child(shape)
		body.position = m.position + Vector3(0.0, aabb.size.y * 0.5 * m.scale.x, 0.0)
		body.rotation.y = m.rotation.y
		add_child(body)


func _mesh(path: String, at: Vector3, scale_factor: float) -> MeshInstance3D:
	if not ResourceLoader.exists(path):
		push_warning("camp piece missing: %s" % path)
		return null
	var mesh := MeshInstance3D.new()
	mesh.mesh = load(path)
	mesh.position = at
	mesh.scale = Vector3.ONE * scale_factor
	add_child(mesh)
	return mesh


## Legal (green) or not (red), at ghost alpha either way.
func tint_ghost(ok: bool) -> void:
	var colour := Color(0.5, 1.0, 0.5, 0.45) if ok else Color(1.0, 0.4, 0.4, 0.45)
	for m in _ghost_meshes:
		if m == null or not is_instance_valid(m):
			continue
		var material := StandardMaterial3D.new()
		material.albedo_color = colour
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.material_override = material


## Rest: fade out, new day, everyone healed, fade in. The fade is the same
## two-node canvas the opening's wake uses, built here because a camp can
## exist in a world with no sequence director.
func _on_rest() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the night cannot pass")
		return

	var layer := CanvasLayer.new()
	layer.layer = 15
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	add_child(layer)

	var tween := create_tween()
	tween.tween_property(rect, "color:a", 1.0, FADE_SECONDS * 0.5)
	tween.tween_callback(func() -> void: _pass_the_night(game))
	tween.tween_interval(0.4)
	tween.tween_property(rect, "color:a", 0.0, FADE_SECONDS * 0.5)
	tween.tween_callback(layer.queue_free)


func _pass_the_night(game: Node) -> void:
	var day := int(game.call("advance_day"))
	var party: RefCounted = game.get("party")
	if party != null:
		for member: Variant in (party.call("members") as Array):
			(member as RefCounted).call("heal_fully")
	# The trainer too — find them by the vitals they carry.
	var world := get_parent()
	var player := world.get_node_or_null(^"Player")
	if player != null:
		var vitals: RefCounted = player.get("vitals")
		if vitals != null and vitals.has_method("rest"):
			vitals.call("rest")
	# "rest to morning" (R5.1) — by group rather than a direct reference, so a
	# camp in a scene with no day/night setup (a test scene, say) still rests
	# fine with nothing to reset.
	for look: Node in get_tree().get_nodes_in_group("day_cycle"):
		if look.has_method("reset_to_morning"):
			look.call("reset_to_morning")
	print("[camp] rested; day %d" % day)
