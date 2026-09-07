extends Node3D

## The physical presentation shared by ancient and player-built Stormglass
## Arches. Travel, pairing, ledger claims, and authored-footing rules belong
## to the Stormwood runtime; this node is deliberately only the gate a player
## can see and walk through.
##
## `WallEntrance.obj` is an installed castle-kit mesh.  It is normalized from
## its imported height to the Stormwood contract's four metre arch, then
## centred on the x/z origin and grounded at y = 0.  This keeps a placed arch
## compatible with BuildPlacer's normal root transform and with an ancient
## arch mounted on terrain.

const MESH_PATH := "res://assets/buildings/quaternius_castle/WallEntrance.obj"

const HEIGHT := 4.0
const OUTER_WIDTH := 4.0
## Measured from WallEntrance.obj after its 4m height normalization: its
## inside edges sit about 2.28m apart and its crown clears about 2.56m.  The
## collision is held a few centimetres inside that visual opening so players
## do not clip a visible jamb while its centre remains comfortably walkable.
const OPEN_WIDTH := 2.2
const OPEN_HEIGHT := 2.5
const FRAME_DEPTH := 1.45

const STORMGLASS_DARK := Color("172b45")
const STORMGLASS_DIM := Color("345b75")
const STORMGLASS_LIT := Color("7fddff")

const STATE_VALID := &"valid"
const STATE_INVALID := &"invalid"
const STATE_UNSUPPORTED := &"unsupported"

static var _state_materials: Dictionary = {}

var _frame: MeshInstance3D = null
var _stormglass: StandardMaterial3D = null


## Normal BuildPlacer ghost entry point. Ghosts have the real silhouette but
## never a body, so a preview cannot block its own placement ray or the player.
func build_ghost() -> void:
	_spawn(false)


## Normal BuildPlacer real entry point. Collision deliberately comprises two
## jambs and a lintel: a single enclosing AABB would close the very passage
## the arch promises to the player.
func build_real() -> void:
	_spawn(true)


func _spawn(solid: bool) -> void:
	if _frame != null:
		return
	var mesh := load(MESH_PATH) as Mesh
	if mesh == null:
		push_warning("Stormwood arch mesh missing: %s" % MESH_PATH)
		return
	var bounds := mesh.get_aabb()
	if bounds.size.y <= 0.001:
		push_warning("Stormwood arch mesh has no usable height: %s" % MESH_PATH)
		return
	var scale := HEIGHT / bounds.size.y
	_frame = MeshInstance3D.new()
	_frame.name = "StormglassFrame"
	_frame.mesh = mesh
	_frame.scale = Vector3.ONE * scale
	_frame.position = Vector3(-bounds.get_center().x * scale, -bounds.position.y * scale,
		-bounds.get_center().z * scale)
	_stormglass = _stormglass_material()
	_frame.material_override = _stormglass
	add_child(_frame)
	if solid:
		_add_open_passage_collision()


func _stormglass_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = STORMGLASS_DARK
	material.metallic = 0.45
	material.roughness = 0.22
	material.emission_enabled = true
	material.emission = STORMGLASS_DIM
	material.emission_energy_multiplier = 0.0
	return material


## Called by the Stormwood arch runtime after its paired/lit state changes.
## A Break may pass a value above 1 to make a linked arch flare without
## duplicating presentation geometry or creating another light owner.
func set_lit(lit: bool, flare: float = 1.0) -> void:
	if _stormglass == null:
		return
	_stormglass.emission = STORMGLASS_LIT if lit else STORMGLASS_DIM
	_stormglass.emission_energy_multiplier = maxf(0.0, flare) * 2.8 if lit else 0.0


func is_lit() -> bool:
	return _stormglass != null and _stormglass.emission_energy_multiplier > 0.0


func _add_open_passage_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "ArchCollision"
	var jamb_width := (OUTER_WIDTH - OPEN_WIDTH) * 0.5
	_add_box(body, Vector3(-(OPEN_WIDTH + jamb_width) * 0.5, HEIGHT * 0.5, 0.0),
		Vector3(jamb_width, HEIGHT, FRAME_DEPTH))
	_add_box(body, Vector3((OPEN_WIDTH + jamb_width) * 0.5, HEIGHT * 0.5, 0.0),
		Vector3(jamb_width, HEIGHT, FRAME_DEPTH))
	var lintel_height := HEIGHT - OPEN_HEIGHT
	_add_box(body, Vector3(0.0, OPEN_HEIGHT + lintel_height * 0.5, 0.0),
		Vector3(OPEN_WIDTH, lintel_height, FRAME_DEPTH))
	add_child(body)


func _add_box(body: StaticBody3D, at: Vector3, size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = at
	body.add_child(collision)


static func _material_for_state(state: StringName) -> StandardMaterial3D:
	if _state_materials.has(state):
		return _state_materials[state]
	var colour: Color
	match state:
		STATE_INVALID:
			colour = Color(UITokens.DANGER, 0.45)
		STATE_UNSUPPORTED:
			colour = Color(UITokens.WARNING, 0.45)
		_:
			colour = Color(UITokens.TEAL.lerp(Color(0.35, 0.9, 0.4), 0.6), 0.5)
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_state_materials[state] = material
	return material


## Matches the three-state ghost API BuildPlacer already probes for.
func tint_ghost_state(state: StringName) -> void:
	if _frame != null:
		_frame.material_override = _material_for_state(state)


func tint_ghost(ok: bool) -> void:
	tint_ghost_state(STATE_VALID if ok else STATE_INVALID)
