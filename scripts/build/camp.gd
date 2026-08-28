extends Node3D

## The first camp: a campfire and a bedroll, and the rest that ends day one.
##
## data/items/buildables.json has carried `camp` ("contains: Campfire,
## Bedroll") since the build screen shipped, with a comment admitting nothing
## places geometry. This is the geometry: the Quaternius Survival pack's
## bonfire (docs/ASSET_LEDGER.md) with a light and embers, and a bedroll built
## from the furniture bed at ground level. Resting fades the world out,
## advances `Game.day`, heals the party and the trainer, and fades back in —
## GAME_DESIGN.md's early tutorial ends exactly here: "build campfire + bed
## and rest with starter."

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const CRAFT_PANEL := preload("res://scripts/ui/craft_panel.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const CAMPFIRE_GLOW := preload("res://scripts/world/campfire_glow.gd")
const BONFIRE := "res://assets/props/quaternius_survival/Bonfire_Fire.obj"
## BAND1-D1: was `quaternius_furniture/BedTwin.obj` scaled to 0.45 -- an
## indoor bed frame standing in for a bedroll, which is what was available
## when this shipped. A real bedroll is now vendored (Kenney Survival Kit,
## CC0, docs/ASSET_LEDGER.md) because the authored trail camp needed one, and
## the player-built camp wanted exactly the same prop. Authored small, so its
## scale below is 2.6 where the bed frame's was 0.45.
## The .obj rather than the .glb sibling beside it, deliberately: `_mesh()`
## below loads a bare Mesh, which is what Godot's OBJ import produces, while
## a .glb arrives as a PackedScene and would not load here at all. The .glb
## stays for `props.gd`, which instantiates scenes and keeps multi-part props
## intact. Both are the same model from the same fetch and share the one
## vendored `Textures/colormap.png` their MTL/glTF both point at.
const BEDROLL := "res://assets/props/kenney_survival/bedroll.obj"
const BEDROLL_SCALE := 2.6
## FIRST-HOUR-FUN-REBUILD. The player-built Camp is the compact mandatory
## campsite, so it must visibly carry the promised shelter as well as the fire
## and bedroll it already had. This owner-reference-derived tent is already
## installed and used by authored Meadows camps; BUILD_PIECE instantiates its
## glb scene with the same collision/ghost behavior as other placeables.
const TENT := "res://assets/props/generated_camp/camp_tent.glb"
const TENT_POSITION := Vector3(-1.65, 0.0, -0.85)

const FADE_SECONDS := 1.2

var _ghost_meshes: Array[MeshInstance3D] = []
var _ghost_tent: Node3D = null
## R2.4. Instantiated once, on the first "Craft" activation — most camps are
## visited for rest and never opened for crafting, so building the panel's
## whole node tree up front would be work most players never see the result
## of.
var _craft_panel: CanvasLayer = null


## The see-through preview the placer drags around. No collision, no prompt.
func build_ghost() -> void:
	_spawn_meshes(false)


## The real thing: solid, lit, and offering rest.
func build_real() -> void:
	_spawn_meshes(true)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 1.2, 0.0)
	light.light_color = Color(1.0, 0.72, 0.45)
	light.light_energy = 2.8
	light.omni_range = 10.0
	light.shadow_enabled = true
	add_child(light)

	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(1.6, 0.5, 0.0)
	prompt.call("configure", "Rest until morning", 2.6, true)
	prompt.connect("activated", _on_rest)
	add_child(prompt)

	# R2.4. A second offer at the same fire, its own priority-1 position so
	# both prompts arbitrate cleanly rather than landing on top of one
	# another at distance zero — interactable.gd's own `priority` export
	# exists exactly for two real offers this close together.
	var craft_prompt: Node3D = INTERACTABLE.new()
	craft_prompt.name = "CraftInteractable"
	craft_prompt.position = Vector3(-1.6, 0.5, 0.0)
	craft_prompt.call("configure", "Craft", 2.6, true)
	craft_prompt.connect("activated", _on_craft)
	add_child(craft_prompt)


func _spawn_meshes(solid: bool) -> void:
	_ghost_meshes.clear()
	_ghost_tent = null
	var tent := BUILD_PIECE.new()
	add_child(tent)
	tent.position = TENT_POSITION
	if solid:
		tent.call("build_real", TENT)
	else:
		tent.call("build_ghost", TENT)
		_ghost_tent = tent
	var fire := _mesh(BONFIRE, Vector3.ZERO, 0.55)
	# The bonfire mesh's own `Fire` surface, lit. `Bonfire_Fire.obj` was long
	# believed to be one combined mesh whose flame could not be addressed --
	# true of the OBJ file, false of what Godot imports, since the OBJ loader
	# splits by material (BAND1-D1, tools/_probe_bonfire_fire.gd). Until this,
	# the player-built camp's fire was a pile of unlit logs with a light
	# floating above it, which is the same defect the authored trail camp
	# failed a blind judgement on. Only on the real thing: the drag-around
	# ghost is meant to read as a preview, not as a fire already burning.
	if fire != null and solid:
		CAMPFIRE_GLOW.ignite(fire)
	var roll := _mesh(BEDROLL, Vector3(1.8, 0.0, 0.6), BEDROLL_SCALE)
	if roll != null:
		roll.rotation.y = deg_to_rad(30.0)
	if not solid:
		for m in [fire, roll]:
			if m != null:
				_ghost_meshes.append(m)
		return
	for m in [fire, roll]:
		if m == null:
			continue
		var aabb: AABB = (m.mesh as Mesh).get_aabb()
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = aabb.size * m.scale.x
		shape.shape = box
		body.add_child(shape)
		body.position = m.position + Vector3(0.0, aabb.size.y * 0.5 * m.scale.x, 0.0)
		body.rotation.y = m.rotation.y
		add_child(body)


func _mesh(path: String, at: Vector3, scale_factor: float) -> MeshInstance3D:
	if not ResourceLoader.exists(path):
		push_warning("camp piece missing: %s" % path)
		return null
	var mesh := MeshInstance3D.new()
	mesh.mesh = load(path)
	mesh.position = at
	mesh.scale = Vector3.ONE * scale_factor
	add_child(mesh)
	return mesh


## Legal (green) or not (red), at ghost alpha either way.
func tint_ghost(ok: bool) -> void:
	var colour := Color(0.5, 1.0, 0.5, 0.45) if ok else Color(1.0, 0.4, 0.4, 0.45)
	for m in _ghost_meshes:
		if m == null or not is_instance_valid(m):
			continue
		var material := StandardMaterial3D.new()
		material.albedo_color = colour
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.material_override = material
	if _ghost_tent != null and is_instance_valid(_ghost_tent):
		_ghost_tent.call("tint_ghost", ok)


## Rest: fade out, new day, everyone healed, fade in. The fade is the same
## two-node canvas the opening's wake uses, built here because a camp can
## exist in a world with no sequence director.
func _on_rest() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the night cannot pass")
		return

	var layer := CanvasLayer.new()
	layer.layer = 15
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	add_child(layer)

	var tween := create_tween()
	tween.tween_property(rect, "color:a", 1.0, FADE_SECONDS * 0.5)
	tween.tween_callback(func() -> void: _pass_the_night(game))
	tween.tween_interval(0.4)
	tween.tween_property(rect, "color:a", 0.0, FADE_SECONDS * 0.5)
	tween.tween_callback(layer.queue_free)


## R2.4. Open the craft screen — data/recipes/recipes.json's base tier,
## orb_basic and potion_small, spent and granted through GameState.craft().
func _on_craft() -> void:
	if _craft_panel == null:
		_craft_panel = CRAFT_PANEL.new()
		get_tree().root.add_child(_craft_panel)
	_craft_panel.call("open")


func _pass_the_night(game: Node) -> void:
	var day := int(game.call("advance_day"))
	# GATEB-FLAGS: `player_slept_at_home`, data/progression/objectives.json's
	# ladder. Set here, on the actual completed rest, not on the interact
	# prompt firing -- the objective asks for the sleep itself, not the
	# attempt to start one.
	var progression: RefCounted = game.get("progression")
	if progression != null:
		progression.call("set_flag", "player_slept_at_home")
	# Gate A creature-bed contract: sleep completes only pals physically put
	# to bed. Non-resting party members keep their current HP, which is the
	# meaningful preparation tradeoff the bed is supposed to create.
	game.call("complete_creature_bed_rests")
	# The trainer too — find them by the vitals they carry.
	var world := get_parent()
	var player := world.get_node_or_null(^"Player")
	if player != null:
		var vitals: RefCounted = player.get("vitals")
		if vitals != null and vitals.has_method("rest"):
			vitals.call("rest")
	# "rest to morning" (R5.1) — by group rather than a direct reference, so a
	# camp in a scene with no day/night setup (a test scene, say) still rests
	# fine with nothing to reset.
	for look: Node in get_tree().get_nodes_in_group("day_cycle"):
		if look.has_method("reset_to_morning"):
			look.call("reset_to_morning")
	# R3.1. "Frequent autosave" — resting is the natural checkpoint this game
	# already asks the player to return to, the same precedent survival games
	# with a sleep beat use for it.
	game.call("save_game", int(game.call("autosave_slot")))
	print("[camp] rested; day %d" % day)
