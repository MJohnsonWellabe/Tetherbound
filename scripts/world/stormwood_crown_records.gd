extends Node3D

## The three surviving Crown records for `stormwood_crown_remembers`.
##
## Each record is a readable glass-scored stone on the Crown island around the
## heartstone grove. Reading one plays its authored conversation; reading it to
## its last line (the panel's `completed`, not a cancelled `finished`) submits
## the record's count fact through the chapter's existing realm-ledger writer.
## The chain's steps count those facts, so any first record finds the chain and
## all three complete the reading. Nothing here writes the
## main Heartstone/Rootgate flags or grants an item: Wen points to the existing
## Crown cache pickup, which keeps its original one-time receipt.
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const STONE := "res://assets/environment/stylized_nature/Rock_Medium_2.gltf"
const CROWN_REACHED := "stormwood:crown_reached"
const COUNT_PREFIX := "stormwood:side_crown_remembers_record:"
const COL_GLYPH := Color("9deaf2")

## World XZ seats around the heartstone grove (700, 2712). Kept clear of the
## authored Crown reward pockets and Wen's standing point.
const RECORDS := [
	{"id": "rain_ledger", "at": [672.0, 2732.0], "yaw": 35.0},
	{"id": "root_census", "at": [733.0, 2716.0], "yaw": -70.0},
	{"id": "reversal_mark", "at": [690.0, 2684.0], "yaw": 160.0},
]

var world: Node3D
var game: Node
var prompts := {}
var _revision := -1


static func record_ids() -> Array[String]:
	var out: Array[String] = []
	for record: Dictionary in RECORDS:
		out.append(str(record.id))
	return out


static func conversation_for(record_id: String) -> String:
	return "stormwood_crown_record_%s" % record_id


static func count_flag_for(record_id: String) -> String:
	return COUNT_PREFIX + record_id


## The chapter event a finished record conversation submits, or "" when the id
## is not a Crown record.
static func event_for_conversation(conversation_id: String) -> String:
	for record_id: String in record_ids():
		if conversation_id == conversation_for(record_id):
			return "count:" + count_flag_for(record_id)
	return ""


func mount(owner_world: Node3D) -> void:
	world = owner_world
	game = get_node("/root/Game")
	add_to_group("progression_restore")
	var local := not bool(world.get("simulation_only"))
	for record: Dictionary in RECORDS:
		var seat := Node3D.new()
		seat.name = "CrownRecord_%s" % str(record.id)
		var x := float(record.at[0])
		var z := float(record.at[1])
		seat.position = Vector3(x, world.ground_height_at(x, z), z) - position
		seat.rotation.y = deg_to_rad(float(record.yaw))
		add_child(seat)
		var solid := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.4, 1.6, 0.6)
		collision.shape = box
		collision.position.y = 0.8
		solid.add_child(collision)
		seat.add_child(solid)
		if not local:
			continue
		_dress(seat)
		var prompt := INTERACTABLE.new()
		prompt.name = "RecordInteractable"
		prompt.position = Vector3(0, 0.9, -0.9)
		seat.add_child(prompt)
		prompt.activated.connect(_read.bind(str(record.id)))
		prompts[str(record.id)] = prompt
	if local:
		var panel := world.get_node_or_null("DialoguePanel")
		if panel != null:
			panel.connect("completed", _dialogue_finished)
	restore_progression_from_game(game)


func _process(_delta: float) -> void:
	if game != null and int(game.get("progression").get("revision")) != _revision:
		restore_progression_from_game(game)


func restore_progression_from_game(_game: Node) -> void:
	if game == null:
		return
	var flags: RefCounted = game.get("progression")
	_revision = int(flags.get("revision"))
	var reached := bool(flags.has(CROWN_REACHED))
	for record_id: String in prompts:
		var prompt: Node = prompts[record_id]
		var read := bool(flags.has(count_flag_for(record_id)))
		prompt.call("configure", "Reread the Crown record" if read else "Read the Crown record", 2.6, reached)
		prompt.set("actionable", reached)


func _read(record_id: String) -> void:
	if not game.get("progression").has(CROWN_REACHED):
		return
	var panel := world.get_node_or_null("DialoguePanel")
	if panel == null or bool(panel.call("is_open")):
		return
	panel.call("start", conversation_for(record_id))


func _dialogue_finished(conversation_id: String) -> void:
	var event := event_for_conversation(conversation_id)
	if event == "" or bool(game.get("progression").has(event.trim_prefix("count:"))):
		return
	var chapter := world.get_node_or_null("StormwoodChapter")
	if chapter != null:
		chapter.call("emit_event", event)
	restore_progression_from_game(game)


func _dress(seat: Node3D) -> void:
	var stone := (load(STONE) as PackedScene).instantiate() as Node3D
	var bounds := BOUNDS.measure(stone)
	var factor := 1.5 / maxf(0.1, bounds.size.y)
	stone.scale = Vector3(1.0, 1.0, 0.55) * factor
	stone.position.y = -bounds.position.y * factor
	seat.add_child(stone)
	# A scored glyph plate on the reading face, lit from below like the rest
	# of the Stormwood: readable at night without a HUD marker.
	var glyph := MeshInstance3D.new()
	glyph.name = "RecordGlyph"
	var plate := QuadMesh.new()
	plate.size = Vector2(0.7, 0.5)
	glyph.mesh = plate
	var material := StandardMaterial3D.new()
	material.albedo_color = COL_GLYPH
	material.emission_enabled = true
	material.emission = COL_GLYPH
	material.emission_energy_multiplier = 1.6
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	glyph.material_override = material
	glyph.position = Vector3(0, 0.95, -0.45)
	glyph.rotation.y = PI
	seat.add_child(glyph)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 0.4, -1.0)
	light.light_color = COL_GLYPH
	light.light_energy = 0.8
	light.omni_range = 4.0
	light.shadow_enabled = false
	seat.add_child(light)
