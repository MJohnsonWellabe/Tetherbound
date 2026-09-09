extends RefCounted

## The production pylon GLB deliberately contains geometry and UVs only. Keep
## its installed live/dead finish in one place so every runtime consumer binds
## the same textures without adding whole-object emission under Compatibility.

const LIVE_ALBEDO := preload("res://assets/environment/team_tether/tether_pylon_albedo.png")
const DEAD_ALBEDO := preload("res://assets/environment/team_tether/tether_pylon_albedo_dead.png")

static var _live: StandardMaterial3D = null
static var _dead: StandardMaterial3D = null


static func material(lit: bool) -> StandardMaterial3D:
	var cached := _live if lit else _dead
	if cached != null:
		return cached
	var result := StandardMaterial3D.new()
	result.albedo_texture = LIVE_ALBEDO if lit else DEAD_ALBEDO
	result.roughness = 0.82
	result.metallic = 0.0
	if lit:
		_live = result
	else:
		_dead = result
	return result


## Applies the finish recursively because the imported scene owns the mesh
## below a transform root. Returns the number of real mesh instances bound.
static func apply(root: Node, lit: bool) -> int:
	if root == null:
		return 0
	var count := 0
	if root is MeshInstance3D:
		(root as MeshInstance3D).material_override = material(lit)
		count += 1
	for child: Node in root.get_children():
		count += apply(child, lit)
	return count
