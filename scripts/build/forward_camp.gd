extends Node3D

## Three usable pieces, one paid world record. Existing licensed camp/prop
## models; no new generated asset or independent building identities.
const RULES := preload("res://scripts/build/forward_camp_rules.gd")
const PIECE := preload("res://scripts/build/build_piece.gd")
const TENT := preload("res://scripts/build/camp_tent.gd")
const BED := preload("res://scripts/build/player_bed.gd")
const PROMPT := preload("res://scripts/world/interactable.gd")
const PANEL := preload("res://scripts/ui/craft_panel.gd")
const NIGHT := preload("res://scripts/world/night_rest.gd")
var _pieces: Array[Node3D] = []
var _prompts: Array[Node3D] = []
var _panel: CanvasLayer
var _pending_rest := {}
var camp_part := "workbench"

func build_ghost() -> void: _build(true)
func build_real() -> void: _build(false)

func _build(ghost: bool) -> void:
	var cfg := RULES.config()
	if cfg.is_empty(): return
	var shelter := TENT.new()
	add_child(shelter)
	var b: Array = cfg.bed_offset
	shelter.position=Vector3(b[0],b[1],b[2])
	shelter.call("build_ghost" if ghost else "build_real")
	_pieces.append(shelter)
	_model(BED.MESH_PATH,Vector3(b[0],b[1]+BED.BED_SINK,b[2]),ghost)
	var c: Array = cfg.cookpot_offset
	_model("res://assets/props/quaternius_fantasy/Pot_1.gltf",Vector3(c[0],c[1],c[2]),ghost)
	var w: Array = cfg.workbench_offset
	_model("res://assets/props/quaternius_fantasy/Workbench.gltf",Vector3(w[0],w[1],w[2]),ghost)
	if ghost: return
	for part: String in ["bed","cookpot","workbench"]:
		var p: Array = cfg[part+"_offset"]
		var prompt := PROMPT.new()
		prompt.position=Vector3(p[0],p[1]+0.6,p[2])
		prompt.call("configure",{"bed":"Rest team until morning","cookpot":"Cook travel meals","workbench":"Craft field kits and edit loadouts"}[part],float(cfg.interaction_radius_m),true)
		prompt.connect("activated",_activate.bind(part))
		add_child(prompt)
		_prompts.append(prompt)
	set_process(true)

func _model(path: String, at: Vector3, ghost: bool) -> void:
	var piece := PIECE.new()
	add_child(piece)
	piece.position=at
	piece.call("build_ghost" if ghost else "build_real",path)
	_pieces.append(piece)

func tint_ghost(ok: bool) -> void:
	for piece: Node3D in _pieces: piece.call("tint_ghost",ok)

func source_key() -> String:
	return "forward_camp:%s:%s" % [str(get_meta("realm","")),str(get_meta("building_uid",""))]

func _process(_delta: float) -> void:
	var game := get_node_or_null(^"/root/Game")
	var session: Node = game.get("session") as Node if game != null else null
	var available := RULES.config().get("runtime_enabled") == true and session != null \
		and session.has_method("forward_camp_available") and session.call("forward_camp_available",self) == true
	for prompt: Node3D in _prompts: prompt.set("actionable",available)

func _activate(part: String) -> void:
	if is_instance_valid(_panel) and _panel.call("is_open") == true: return
	camp_part=part
	var game := get_node_or_null(^"/root/Game")
	var session: Node = game.get("session") as Node if game != null else null
	if session == null: return
	if part != "bed":
		if not is_instance_valid(_panel):
			_panel=PANEL.new()
			get_tree().root.add_child(_panel)
		_panel.call("open_station",self)
		return
	# Retain the original rest intent on uncertain saves. Do not start the
	# sleep vote until the admitted team assignment is durably owner-saved.
	if _pending_rest.is_empty(): _pending_rest={"action_id":Crypto.new().generate_random_bytes(16).hex_encode()}
	if not session.has_method("forward_camp_prepare_rest"): return
	var result: Variant = session.call("forward_camp_prepare_rest",self,_pending_rest.duplicate(true))
	if result is Dictionary and result.get("ok") == true and result.get("durable") == true and result.get("settled") == true:
		_pending_rest={}
		NIGHT.rest(self)
	elif result is Dictionary:
		game.call("push_world_message",str(result.get("reason","Waiting for the team's saved rest transaction.")))

func open_loadouts() -> void:
	var game := get_node_or_null(^"/root/Game")
	var session: Node = game.get("session") as Node if game != null else null
	if session != null and session.has_method("open_creature_loadouts"):
		session.call("open_creature_loadouts",self,source_key())

func _exit_tree() -> void:
	if is_instance_valid(_panel): _panel.queue_free()
