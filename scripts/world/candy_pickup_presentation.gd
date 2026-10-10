extends RefCounted

## Regional adapters share the existing Meadows tier treatment. The cache
## itself keeps ownership of interaction and claims; only its visual is dressed.
const CONFIG := "res://data/config/candy_pickup_presentation.json"
const TIERS := preload("res://scripts/world/band_pickups.gd")


static func apply(pickup: Node3D, item_id: String, definition: Dictionary, placement_id: String) -> void:
	if not TIERS.CANDY_LOOK.has(item_id):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not parsed is Dictionary or not bool(parsed.get("enabled", false)):
		return
	var badge := Color(str(definition.get("colour", "#ffffff")))
	TIERS.dress(pickup, item_id, badge, TIERS.spin_phase_for(placement_id))
	_regional_tier(pickup, item_id, badge, parsed.get("regional_tiers", {}))


## P2-045 judge round 1: at regional camera distance Good and Great read as
## bloom-dominated see-through puffs that differ mainly by glow colour, and
## Great vanished on pale sand. Per tier, from config: an opaque body with its
## own albedo and a low emission, a smaller shared glow, and a lift for the
## body (its ground ring is lowered by the same amount so it stays down).
## Installed candy mesh only; the Meadows look is untouched.
static func _regional_tier(pickup: Node3D, item_id: String, badge: Color, tiers: Variant) -> void:
	if not tiers is Dictionary or not (tiers as Dictionary).get(item_id) is Dictionary:
		return
	var tier: Dictionary = (tiers as Dictionary)[item_id]
	var mesh: MeshInstance3D = TIERS._first_mesh(pickup)
	if mesh == null:
		return
	var body := mesh.material_override as StandardMaterial3D
	if body != null:
		body = body.duplicate() as StandardMaterial3D
		body.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		if tier.has("albedo"):
			body.albedo_color = Color(str(tier.albedo))
		if tier.has("emission"):
			body.emission_energy_multiplier = float(tier.emission)
		mesh.material_override = body
	if tier.has("glow_scale"):
		TIERS.PICKUP_GLOW.attach(pickup, badge, -1.0, float(tier.glow_scale))
	var lift := float(tier.get("lift_m", 0.0))
	if lift != 0.0:
		mesh.position.y += lift
		var ring := mesh.get_node_or_null(^"TierRing") as Node3D
		if ring != null:
			ring.position.y -= lift
