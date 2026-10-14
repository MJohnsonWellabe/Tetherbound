extends RefCounted

## Transform-only MultiMesh buffer. Keep basis rows and origin interleaved in
## RenderingServer order; no RNG, placement, color or custom-data changes.
static func append(buffer: PackedFloat32Array, value: Transform3D) -> void:
	buffer.append(value.basis.x.x)
	buffer.append(value.basis.y.x)
	buffer.append(value.basis.z.x)
	buffer.append(value.origin.x)
	buffer.append(value.basis.x.y)
	buffer.append(value.basis.y.y)
	buffer.append(value.basis.z.y)
	buffer.append(value.origin.y)
	buffer.append(value.basis.x.z)
	buffer.append(value.basis.y.z)
	buffer.append(value.basis.z.z)
	buffer.append(value.origin.z)
