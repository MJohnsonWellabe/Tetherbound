extends RefCounted

## Leaf envelopes measured from installed source meshes, in model metres.
## See canopy-shelter-bounds.md. Gameplay deliberately treats the envelope
## as continuous shelter rather than exposing players through alpha-card gaps.
const LEAF_ENVELOPES := {
	"TwistedTree_2.gltf": Vector2(7.069222, 18.747728),
	"TwistedTree_4.gltf": Vector2(7.286967, 18.536760),
	"CommonTree_3.gltf": Vector2(2.352236, 9.182418),
}

static func under_canopy(at: Vector3, batches: Array) -> bool:
	for batch: Dictionary in batches:
		var model := str(batch.get("model", "")).get_file()
		if not LEAF_ENVELOPES.has(model):
			continue
		var envelope: Vector2 = LEAF_ENVELOPES[model]
		# These are the collision streamer's live baked placements. Chopping
		# removes a placement from this same array, even outside render range.
		for placement: Dictionary in batch.get("placements", []):
			var origin: Vector3 = placement.get("position", Vector3.INF)
			var scale := float(placement.get("scale", 1.0))
			if not origin.is_finite() or scale <= 0:
				continue
			var radius := envelope.x * scale
			if at.y <= origin.y + envelope.y * scale and Vector2(at.x-origin.x, at.z-origin.z).length_squared() <= radius * radius:
				return true
	return false
