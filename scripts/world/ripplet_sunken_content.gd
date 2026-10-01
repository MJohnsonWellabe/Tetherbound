extends Node3D

## Existing interactables and reward journal; no alternate inventory or save.
const RULE := preload("res://scripts/world/ripplet_sunken_rules.gd")
const RIPPLET := preload("res://scripts/player/ripplet_traversal.gd")
const CLAIM := preload("res://scripts/world/ledger_claim.gd")
var world: Node3D
var _prompts: Dictionary = {}

func _ready() -> void:
	for row: Dictionary in RIPPLET.config().sites:
		var prompt := preload("res://scripts/world/interactable.gd").new()
		prompt.name = str(row.id)
		var at: Array = row.position
		prompt.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
		prompt.configure("Open sunken cache" if row.kind == "cache" else "Gather sunken bed", 3.6, false)
		prompt.activated.connect(_claim.bind(str(row.id)))
		add_child(prompt)
		_prompts[str(row.id)] = prompt
		if RIPPLET.config().presentation_enabled:
			var model: String = "res://assets/props/quaternius_fantasy/Crate_Wooden.gltf" if row.kind == "cache" else "res://assets/environment/stylized_nature/Flower_3_Group.gltf"
			var packed := load(model) as PackedScene
			if packed != null:
				var visual := packed.instantiate() as Node3D
				visual.position = prompt.position
				visual.scale = Vector3.ONE * 0.6
				add_child(visual)
				var shelf_scene := load("res://assets/environment/stylized_nature/Rock_Medium_1.gltf") as PackedScene
				if shelf_scene != null:
					var shelf := shelf_scene.instantiate() as Node3D
					shelf.position = prompt.position + Vector3.DOWN * 1.2
					shelf.scale = Vector3(2.0,1.4,2.0)
					add_child(shelf)

func _process(_delta: float) -> void:
	var game := get_node("/root/Game")
	var riding := world.get_node_or_null("RidingController")
	var eligible: bool = riding != null and riding.is_mounted() and riding.diving
	for id: String in _prompts:
		_prompts[id].set_enabled(eligible and not RULE.claim_key(RULE.site(id), game.world.flags, game.world.day).is_empty())

func _claim(id: String) -> void:
	var game := get_node("/root/Game")
	var director := world.get_node("EncounterDirector")
	if director.ally_instance() == null: return
	CLAIM.submit(self, {"kind":"ripplet_sunken_claim", "realm":"water", "site_id":id,
		"creature_uid":str(director.ally_instance().uid), "claim_key":RULE.claim_key(RULE.site(id), game.world.flags, game.world.day)})
