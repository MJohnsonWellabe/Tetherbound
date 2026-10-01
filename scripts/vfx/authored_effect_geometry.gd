extends RefCounted

## Authored silhouettes from the owner combat boards: deliberate curved
## tongues, sharp contact accents and directed chips. No world/gameplay query.
static func flame_tongue(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var half := size * float(profile.get("card_extent_scale", 3.2)) * 0.5
	var depth := size * float(profile.get("curve_depth_scale", 0.18))
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in 8:
		for x in 4:
			var u0 := float(x) / 4.0
			var u1 := float(x + 1) / 4.0
			var v0 := float(y) / 8.0
			var v1 := float(y + 1) / 8.0
			var a := Vector3((u0 * 2.0 - 1.0) * half, (1.0 - v0 * 2.0) * half, sin(u0 * PI) * depth)
			var b := Vector3((u1 * 2.0 - 1.0) * half, (1.0 - v0 * 2.0) * half, sin(u1 * PI) * depth)
			var c := Vector3((u1 * 2.0 - 1.0) * half, (1.0 - v1 * 2.0) * half, sin(u1 * PI) * depth)
			var d := Vector3((u0 * 2.0 - 1.0) * half, (1.0 - v1 * 2.0) * half, sin(u0 * PI) * depth)
			_triangle(mesh,a,c,b,[Vector2(u0,v0),Vector2(u1,v1),Vector2(u1,v0)])
			_triangle(mesh,a,d,c,[Vector2(u0,v0),Vector2(u0,v1),Vector2(u1,v1)])
	mesh.surface_end()
	return mesh

## One static contact mesh: several unequal tapered streaks with depth,
## never an extra emitter or independent particle lease.
static func contact_burst(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var count := clampi(int(profile.get("accent_count", 9)), 4, 18)
	var width := size * float(profile.get("accent_width_scale", 0.10))
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var angle := float(i) * 2.399963
		var direction := Vector3(cos(angle), sin(angle), sin(float(i) * 1.73) * 0.45).normalized()
		var side := direction.cross(Vector3.FORWARD).normalized()
		if side.is_zero_approx(): side = Vector3.UP
		var reach := size * (1.3 + absf(sin(float(i) * 2.17)) * 1.7)
		var root := direction * size * 0.12
		var middle := direction * reach * 0.42 + side * reach * 0.06
		var tip := direction * reach
		_triangle(mesh,root-side*width,middle-side*width*0.6,middle+side*width*0.6,[Vector2(0,0),Vector2(0,0.45),Vector2(1,0.45)])
		_triangle(mesh,root-side*width,middle+side*width*0.6,root+side*width,[Vector2(0,0),Vector2(1,0.45),Vector2(1,0)])
		_triangle(mesh,middle-side*width*0.6,tip,middle+side*width*0.6,[Vector2(0,0.45),Vector2(0.5,1),Vector2(1,0.45)])
	mesh.surface_end()
	return mesh

static func electrical_splash(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var count := clampi(int(profile.get("accent_count", 6)), 4, 18)
	var width := size * float(profile.get("accent_width_scale", 0.15))
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var angle := float(i) * 2.399963
		var direction := Vector3(cos(angle), sin(angle) * 0.75, sin(float(i) * 1.57) * 0.6).normalized()
		var side := direction.cross(Vector3.FORWARD).normalized()
		if side.is_zero_approx(): side = Vector3.UP
		var reach := size * (1.4 + absf(sin(float(i) * 2.19)) * 1.3)
		var points: Array[Vector3] = [Vector3.ZERO, direction*reach*0.28+side*reach*0.13,
			direction*reach*0.58-side*reach*0.09, direction*reach]
		for segment in 3:
			var w0 := width * (1.0 - float(segment) * 0.24)
			var w1 := width * (0.76 - float(segment) * 0.24)
			_triangle(mesh,points[segment]-side*w0,points[segment+1]-side*w1,points[segment+1]+side*w1,[Vector2(0,0),Vector2(0,1),Vector2(1,1)])
			_triangle(mesh,points[segment]-side*w0,points[segment+1]+side*w1,points[segment]+side*w0,[Vector2(0,0),Vector2(1,1),Vector2(1,0)])
	mesh.surface_end()
	return mesh

static func _triangle(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, uvs: Array[Vector2]) -> void:
	var normal := (b-a).cross(c-a).normalized()
	if normal.is_zero_approx(): return
	var points: Array[Vector3] = [a,b,c]
	for i in 3:
		mesh.surface_set_normal(normal)
		mesh.surface_set_uv(uvs[i])
		mesh.surface_set_color(Color.WHITE)
		mesh.surface_add_vertex(points[i])
