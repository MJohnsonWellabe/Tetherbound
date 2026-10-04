extends RefCounted

## Original local geometry for flowing move objects. No scene/collision/query
## or particle emitter lives here; the caller retains its frozen flight clock.
static func water_stream(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var around := clampi(int(profile.get("segments", 18)), 8, 32)
	var along := clampi(int(profile.get("flow_segments", 14)), 4, 24)
	var length := size * float(profile.get("height_ratio", 3.0))
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in along:
		for x in around:
			var widen := bool(profile.get("widen", false))
			var a := _flow_vertex(x, y, around, along, size, length, widen)
			var b := _flow_vertex(x + 1, y, around, along, size, length, widen)
			var c := _flow_vertex(x + 1, y + 1, around, along, size, length, widen)
			var d := _flow_vertex(x, y + 1, around, along, size, length, widen)
			_surface_quad(mesh, [a,b,c,d], [Vector2(float(x)/around,float(y)/along), Vector2(float(x+1)/around,float(y)/along),Vector2(float(x+1)/around,float(y+1)/along),Vector2(float(x)/around,float(y+1)/along)])
	mesh.surface_end()
	return mesh

static func _flow_vertex(x: int, y: int, around: int, along: int, size: float, length: float, widen: bool) -> Vector3:
	var angle := TAU * float(x) / float(around)
	var f := float(y) / float(along)
	var radius := size * (0.74 + 0.13 * sin(f * 17.3 + angle * 3.0))
	if widen: radius *= lerpf(0.12, 1.0, f)
	var center := Vector3(sin(f * 8.1) * size * 0.1, (f - 0.5) * length, cos(f * 7.7) * size * 0.08)
	return center + Vector3(cos(angle),0,sin(angle)) * radius

## A continuous curling crest, not an upright rectangular sheet. Its front
## points along -Z and the caller rotates it into frozen planar travel.
static func rolling_wave(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var across := clampi(int(profile.get("segments", 24)), 8, 36)
	var curl := clampi(int(profile.get("curl_segments", 12)), 6, 20)
	var half_width := size * float(profile.get("width_ratio", 3.2))
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in across:
		for y in curl:
			var a := _wave_vertex(float(x)/across,float(y)/curl,size,half_width)
			var b := _wave_vertex(float(x+1)/across,float(y)/curl,size,half_width)
			var c := _wave_vertex(float(x+1)/across,float(y+1)/curl,size,half_width)
			var d := _wave_vertex(float(x)/across,float(y+1)/curl,size,half_width)
			_surface_quad(mesh,[a,b,c,d],[Vector2(float(x)/across,float(y)/curl),Vector2(float(x+1)/across,float(y)/curl),Vector2(float(x+1)/across,float(y+1)/curl),Vector2(float(x)/across,float(y+1)/curl)])
	mesh.surface_end()
	return mesh

static func _wave_vertex(u: float, v: float, size: float, half_width: float) -> Vector3:
	var angle := lerpf(-PI*0.5,PI*0.78,v)
	var taper := 0.74 + 0.26*sin(u*PI)
	var radius := size*taper*(0.95-0.33*v)
	return Vector3(lerpf(-half_width,half_width,u), size*0.75 + sin(angle)*radius, -cos(angle)*radius)

## A splash crown: curved sheets of water thrown up and outward around the
## contact point (UV.y runs base to lip, so the water shader foams the lips).
static func splash_crown(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var petals := clampi(int(profile.get("crown_petals", 9)), 4, 16)
	var rows := clampi(int(profile.get("crown_rows", 6)), 3, 10)
	var height := size * float(profile.get("crown_height_ratio", 1.4))
	var flare := size * float(profile.get("crown_flare_ratio", 1.1))
	var gap := clampf(float(profile.get("crown_gap", 0.18)), 0.0, 0.45)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in petals:
		var a0 := TAU * (float(k) + gap * 0.5) / float(petals)
		var a1 := TAU * (float(k + 1) - gap * 0.5) / float(petals)
		# Each petal has its own height so the crown reads as thrown water.
		var tall := 0.72 + 0.28 * sin(float(k) * 2.39 + 1.3)
		for r in rows:
			var v0 := float(r) / float(rows)
			var v1 := float(r + 1) / float(rows)
			var p00 := _crown_point(a0, v0, size, height * tall, flare)
			var p10 := _crown_point(a1, v0, size, height * tall, flare)
			var p11 := _crown_point(a1, v1, size, height * tall, flare)
			var p01 := _crown_point(a0, v1, size, height * tall, flare)
			_surface_quad(mesh, [p00, p10, p11, p01], [Vector2(0.0, v0), Vector2(1.0, v0), Vector2(1.0, v1), Vector2(0.0, v1)])
	mesh.surface_end()
	return mesh

static func _crown_point(angle: float, v: float, size: float, height: float, flare: float) -> Vector3:
	# Radius widens toward the lip (a flared cup) and the lip curls outward.
	var radius := size * 0.35 + flare * pow(v, 1.6)
	var y := height * sin(v * PI * 0.5)
	return Vector3(cos(angle) * radius, y, sin(angle) * radius)

static func ice_crystal(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var sides := clampi(int(profile.get("segments", 6)), 4, 8)
	var length := size * float(profile.get("height_ratio", 3.8))
	var lower := Vector3(0,-length*0.45,0)
	var tip := Vector3(size*0.14,length*0.55,size*0.07)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in sides:
		var angle := TAU*float(i)/sides
		var next := TAU*float(i+1)/sides
		var a := Vector3(cos(angle)*size, -length*0.12,sin(angle)*size)
		var b := Vector3(cos(next)*size,-length*0.12,sin(next)*size)
		_surface_triangle(mesh,a,b,tip,[Vector2(0,0.3),Vector2(1,0.3),Vector2(0.5,1)])
		_surface_triangle(mesh,b,a,lower,[Vector2(1,0.3),Vector2(0,0.3),Vector2(0.5,0)])
	mesh.surface_end()
	return mesh

static func _surface_quad(mesh: ImmediateMesh, points: Array, uv: Array) -> void:
	_surface_triangle(mesh,points[0],points[1],points[2],[uv[0],uv[1],uv[2]])
	_surface_triangle(mesh,points[0],points[2],points[3],[uv[0],uv[2],uv[3]])

static func _surface_triangle(mesh: ImmediateMesh, a: Vector3,b: Vector3,c: Vector3,uv: Array) -> void:
	# The tube/curl/crystal parameter loops advance around, then along the
	# surface. Reverse that inward winding so physical light reaches the
	# exterior; cull-disabled material alone would hide incorrect normals.
	var normal := (c-a).cross(b-a).normalized()
	if normal.is_zero_approx(): return
	var points: Array[Vector3] = [a, c, b]
	var uv_order: Array[int] = [0, 2, 1]
	for i in 3:
		mesh.surface_set_normal(normal)
		mesh.surface_set_uv(uv[uv_order[i]])
		mesh.surface_set_color(Color.WHITE)
		mesh.surface_add_vertex(points[i])
