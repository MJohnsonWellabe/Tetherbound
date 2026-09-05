extends Node3D

## Read-only projection of canonical quest facts into the inhabited world.
## No inventory, quest completion, save file or new creature is owned here.
const DATA := preload("res://scripts/world/cloudreach_physical_rules.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const CLOTH := preload("res://assets/environment/team_tether/hall/banner_cloth.gdshader")
const REST := preload("res://scripts/world/rest_point.gd")
var config: Dictionary = {}
var world: Node3D
var chapter: Node
var presentation: Node
var player: Node3D
var people: Dictionary = {}
var markers: Dictionary = {}
var anchors: Dictionary = {}
var board: Node3D
var signal_audio: AudioStreamPlayer3D
var signal_count := 0
var _revision := -1
var _signal_left := 0.0
var _state: Dictionary = {}
var _configured := false


static func state_for(flags: RefCounted, data: Dictionary) -> Dictionary:
	var state := {"people": {}, "surveys": {}, "restored": DATA.holds(flags, ["cloudreach_winds_restored"]),
		"circuit": DATA.holds(flags, ["side_cliff_circuit_complete"]),
		"mastery": DATA.holds(flags, ["defeated_cloudreach_tavi_rematch"])}
	state["bells"] = state.restored or DATA.holds(flags, ["side_three_bells_complete"])
	for spec: Dictionary in data.get("travelers", []):
		var visible_now := false
		for flag: String in spec.get("reveal_any", []):
			visible_now = visible_now or DATA.holds(flags, [flag])
		if visible_now:
			var returned := not str(spec.get("return_flag", "")).is_empty() and DATA.holds(flags, [spec["return_flag"]])
			state.people[spec.id] = {"position": spec.return_position if returned else spec.position, "returned": returned}
	for spec: Dictionary in data.get("survey_markers", []):
		state.surveys[spec.id] = DATA.holds(flags, [spec.flag])
	return state


func configure(owner_world: Node3D, chapter_node: Node, arena: Node) -> void:
	world = owner_world
	chapter = chapter_node
	presentation = arena
	player = world.get_node("Player")
	config = DATA.read("res://data/config/cloudreach_npc_runtime.json").get("world_payoffs", {})
	_build_signal()
	_build_markers()
	_build_board()
	_build_anchor_states()
	add_to_group("progression_restore")
	_configured = true
	sync_progression()


func _ground(at: Vector3) -> Vector3:
	var height := float(world.call("ground_height_near", at))
	if is_nan(height) or absf(height - at.y) > 4.0:
		push_error("Cloudreach payoff has no intended floor at " + str(at))
		return Vector3.INF
	return Vector3(at.x, height, at.z)


func _process(delta: float) -> void:
	if not _configured:
		return
	var game := get_node("/root/Game")
	if str(game.get("current_realm")) != "cloudreach":
		signal_audio.stop()
		return
	var flags: RefCounted = game.get("progression")
	if int(flags.get("revision")) != _revision:
		sync_progression()
	if bool(_state.get("bells", false)):
		_signal_left -= delta
		if _signal_left <= 0.0 and player.global_position.distance_to(signal_audio.global_position) < signal_audio.max_distance:
			signal_audio.play()
			signal_count += 1
			_signal_left = float(config.route_signal.interval_seconds)
	_patrol(delta)


func sync_progression() -> void:
	if not _configured:
		return
	var flags: RefCounted = get_node("/root/Game").get("progression")
	_revision = int(flags.get("revision"))
	var next := state_for(flags, config)
	if next == _state:
		return
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel != null and panel.call("is_open"):
		_revision = -1
		return
	_state = next
	_sync_people()
	for id: String in markers:
		var marker: Node3D = markers[id]
		marker.visible = bool(_state.surveys.get(id, false))
		for prompt: Node in marker.find_children("*", "Node3D", true, false):
			if prompt.has_method("set_enabled"):
				prompt.call("set_enabled", marker.visible)
	board.visible = bool(_state.circuit)
	board.get_node("MasterySeal").visible = bool(_state.mastery)
	for entry: Dictionary in anchors.values():
		(entry.bottled as Node3D).visible = not bool(_state.restored)
		(entry.wind as Node3D).visible = bool(_state.restored)
		for mesh: MeshInstance3D in entry.materials:
			mesh.material_override = entry.materials[mesh].restored if _state.restored else entry.materials[mesh].original
	if not bool(_state.bells):
		signal_audio.stop()
	_signal_left = 0.0


func restore_progression_from_game(_game: Node) -> void:
	_state = {}
	_revision = -1
	sync_progression()


func _sync_people() -> void:
	for spec: Dictionary in config.get("travelers", []):
		var id := str(spec.id)
		if not _state.people.has(id):
			if people.has(id):
				(people[id].root as Node).queue_free()
				people.erase(id)
			continue
		var target := _ground(DATA.vec(_state.people[id].position))
		if target == Vector3.INF:
			continue
		if not people.has(id):
			var root := PEOPLE.new()
			root.name = id
			add_child(root)
			var npc_spec := spec.duplicate(true)
			npc_spec["position"] = [target.x, target.y, target.z]
			if spec.has("return_flag"):
				npc_spec["greeting_when"] = [{"if_flag":spec.return_flag,"conversation":spec.get("return_greeting", "cloudreach_shelter_pair_home")}]
			root.call("build_specs", player, [npc_spec])
			var body := root.get_node(NodePath(str(spec.name))) as Node3D
			people[id] = {"root":root,"body":body,"spec":spec,"home":target,"returned":_state.people[id].returned,"to_end":true,"pause":0.0}
		var record: Dictionary = people[id]
		if record.home != target or record.returned != _state.people[id].returned:
			(record.body as Node3D).call("stand_at",target.x,target.z,target.y)
			record.home = target
			record.returned = _state.people[id].returned
			record.to_end = true
			record.pause = 0.0


func _patrol(delta: float) -> void:
	for record: Dictionary in people.values():
		var body: Node3D = record.body
		var spec: Dictionary = record.spec
		if not spec.has("walk_to") or player.global_position.distance_to(body.global_position) < 4.5:
			body.call("play",body.call("clip_for","idle"))
			continue
		if float(record.pause) > 0.0:
			record.pause = float(record.pause) - delta
			body.call("play",body.call("clip_for","idle"))
			continue
		var target := DATA.vec(spec.walk_to) if bool(record.to_end) else record.home as Vector3
		var offset := target - body.global_position
		offset.y = 0.0
		if offset.length() < 0.2:
			record.to_end = not bool(record.to_end)
			record.pause = float(config.walk_pause_seconds)
			continue
		var at := body.global_position + offset.normalized() * minf(offset.length(), float(config.walk_speed_mps) * delta)
		var floor_y := float(world.call("ground_height_near", at))
		if is_nan(floor_y) or absf(floor_y - at.y) > 1.0:
			record.to_end = not bool(record.to_end)
			record.pause = float(config.walk_pause_seconds)
			continue
		body.global_position = Vector3(at.x, floor_y, at.z)
		body.rotation.y = atan2(offset.x, offset.z)
		body.call("play",body.call("clip_for","walk"))


func _build_signal() -> void:
	signal_audio = AudioStreamPlayer3D.new()
	signal_audio.name = "ThreeBellsRouteSignal"
	signal_audio.stream = load(str(config.route_signal.source))
	signal_audio.bus = "Ambience"
	signal_audio.pitch_scale = float(config.route_signal.pitch_scale)
	signal_audio.max_distance = float(config.route_signal.max_distance_m)
	signal_audio.unit_size = 12.0
	signal_audio.volume_db = -5.0
	signal_audio.position = DATA.vec(config.route_signal.position)
	add_child(signal_audio)


func _build_markers() -> void:
	for spec: Dictionary in config.get("survey_markers", []):
		var at := _ground(DATA.vec(spec.position))
		if at == Vector3.INF:
			continue
		var marker := Node3D.new()
		marker.name = "Survey_" + str(spec.id)
		add_child(marker)
		marker.global_position = at
		markers[str(spec.id)] = marker
		var materials: Dictionary = world.get("_materials")
		for x: float in [-3.2, 3.2]:
			world.call("_cylinder",marker,"LandingPole",Vector3(x,1.6,0),0.075,3.2,materials.wood)
			_cloth(marker, "LandingStreamer", Vector3(x,2.5,0), Vector2(0.8,1.15), Color("#e7e0bb"))
		var ring := MeshInstance3D.new()
		ring.name = "LandingRing"
		var mesh := TorusMesh.new()
		mesh.inner_radius = 2.25
		mesh.outer_radius = 2.43
		mesh.rings = 32
		mesh.ring_segments = 6
		ring.mesh = mesh
		ring.material_override = _material(Color("#d6d4b4"))
		ring.position.y = 0.10
		marker.add_child(ring)
		var rest := REST.new()
		rest.name = "SurveyRest"
		marker.add_child(rest)
		rest.call("build",{"at":[at.x,at.z],"height":at.y,"label":str(spec.label)+" · rest","craft":false,"radius":3.2})
		# RestPoint builds in world coordinates; this marker supplies the parent transform.
		rest.position -= at
		var label := Label3D.new()
		label.name = "LandingLabel"
		label.text = str(spec.label)
		label.font_size = 36
		label.pixel_size = 0.012
		label.position = Vector3(0,2.9,0)
		label.modulate = Color("#f5ecd2")
		marker.add_child(label)
		marker.visible = false


func _build_board() -> void:
	board = Node3D.new()
	board.name = "CliffCircuitTeamBoard"
	add_child(board)
	var at := _ground(DATA.vec(config.circuit_board.position))
	if at != Vector3.INF:
		board.position = at
	board.rotation.y = deg_to_rad(float(config.circuit_board.facing_degrees))
	var materials: Dictionary = world.get("_materials")
	for x: float in [-1.1,1.1]:
		world.call("_box",board,"BoardPost",Vector3(x,1.1,0),Vector3(0.16,2.2,0.16),materials.wood,false)
	world.call("_box",board,"TimberBoard",Vector3(0,1.8,0),Vector3(2.6,1.3,0.16),materials.wood,false)
	var title := Label3D.new()
	title.text = "CLIFF CIRCUIT"
	title.font_size = 40
	title.pixel_size = 0.009
	title.position = Vector3(0,2.17,0.095)
	board.add_child(title)
	# Five linked places are the permanent team's mark, never extra slots.
	for index in 5:
		var mark := MeshInstance3D.new()
		mark.name = "TeamPlace%d" % index
		var mesh := SphereMesh.new()
		mesh.radius = 0.12
		mesh.height = 0.24
		mark.mesh = mesh
		mark.material_override = _material(Color("#e5d0a0"))
		mark.position = Vector3((index-2)*0.40,1.76,0.16)
		board.add_child(mark)
		if index > 0:
			world.call("_box",board,"TeamLink",mark.position-Vector3(0.2,0,0.015),Vector3(0.2,0.035,0.035),materials.bronze,false)
	var mastery := Label3D.new()
	mastery.name = "MasterySeal"
	mastery.text = "MASTERY · COMPLETE"
	mastery.font_size = 29
	mastery.pixel_size = 0.0075
	mastery.position = Vector3(0,1.37,0.10)
	mastery.modulate = Color("#e7d499")
	board.add_child(mastery)
	board.visible = false


func _build_anchor_states() -> void:
	for spec: Dictionary in (chapter.get("_runtime") as Dictionary).get("anchors", []):
		var root := chapter.get_node_or_null(NodePath(str(spec.id))) as Node3D
		if root != null:
			_anchor(str(spec.id),root)
	var physical: Node = chapter.call("physical_runtime")
	for id: String in physical.get("_prompts"):
		var entry: Dictionary = physical.get("_prompts")[id]
		if str(entry.spec.get("kind", "")) == "anchor":
			_anchor(id,entry.root)
	for id: String in presentation.get("_relays"):
		_anchor("summit_"+id,presentation.get("_relays")[id])


func _anchor(id: String, target: Node3D) -> void:
	var root := Node3D.new()
	root.name = "AnchorState_"+id
	add_child(root)
	root.global_position = target.global_position
	var materials := {}
	for node: Node in target.find_children("*","MeshInstance3D",true,false):
		var mesh := node as MeshInstance3D
		var original := mesh.material_override
		if original is StandardMaterial3D:
			var freed := original.duplicate() as StandardMaterial3D
			freed.emission_enabled = false
			freed.albedo_color = Color("#849184")
			materials[mesh] = {"original":original,"restored":freed}
	var bottled := Node3D.new()
	bottled.name = "BottledTetherWind"
	root.add_child(bottled)
	var teal := _material(Color("#409ca4"))
	teal.emission_enabled = true
	teal.emission = Color("#367d87")
	teal.emission_energy_multiplier = 0.35
	world.call("_cylinder",bottled,"CompressedWind",Vector3(0,1.8,0),0.12,2.4,teal)
	for height: float in [0.75,2.85]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.38
		torus.outer_radius = 0.51
		torus.rings = 24
		torus.ring_segments = 6
		ring.mesh = torus
		ring.position.y = height
		ring.material_override = teal
		bottled.add_child(ring)
	var wind := Node3D.new()
	wind.name = "FreedNaturalWind"
	root.add_child(wind)
	for index in 3:
		var ribbon := _cloth(wind,"OpenWindTrail",Vector3(1.4,1.35+index*0.7,index*0.32),Vector2(4.8,0.26),Color("#b9d5c0"))
		ribbon.rotation.y = 0.25+index*0.12
		(ribbon.material_override as ShaderMaterial).set_shader_parameter("sway",0.3)
	wind.visible = false
	anchors[id] = {"root":root,"bottled":bottled,"wind":wind,"materials":materials}
	(presentation.call("atmosphere_bindings") as Dictionary).natural_anchor_wind.append(wind)


func _cloth(parent: Node3D, label: String, at: Vector3, size: Vector2, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := PlaneMesh.new()
	mesh.orientation = PlaneMesh.FACE_Z
	mesh.size = size
	mesh.subdivide_width = 8
	mesh.subdivide_depth = 6
	node.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = CLOTH
	material.set_shader_parameter("colour",color)
	material.set_shader_parameter("selvage_colour",color.darkened(0.18))
	material.set_shader_parameter("use_device",0.0)
	material.set_shader_parameter("size",size)
	material.set_shader_parameter("notch_depth",0.12)
	material.set_shader_parameter("phase",at.y*1.7)
	node.material_override = material
	node.position = at
	parent.add_child(node)
	return node


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material
