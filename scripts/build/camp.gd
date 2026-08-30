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
## T1-CAMP/§17: was `kenney_survival/bedroll.obj` at scale 2.6. Investigated
## and rejected first as a MATERIAL problem, then fixed as the actual
## COMPOSITION problem it was. Side by side with the Meshy tent and creature
## bed (tools/_capture_t1_camp_assets.gd's own close frames), the Kenney
## bedroll was the one flat-shaded, textureless object in an otherwise
## richly-textured kit -- no fabric weave, no stitching, no wood-grain tie
## detail, just solid colour blocks. A runtime `albedo_color` multiply (the
## mechanism `build_material_finish.gd` already uses project-wide) was tried
## first and measured with pixel sampling (PIL) to make it read MORE
## saturated red under this scene's ACES tonemap, not less, at two
## strengths -- reverted (see the git history on this line for that
## finding). Tinting a flat-shaded asset was never going to fix a
## flat-shaded asset; the fix is to stop using it.
##
## `camp_bed.glb` already IS the game's answer to "a sleeping surface at a
## Meshy-camp-set site": `band1_lower_meadows/props.json`'s own authored
## trail_camp places this exact mesh as the generic camp sleeping surface
## ("matching the board's own PAL BED panel", `docs/ASSET_LEDGER.md`), not
## exclusively as a creature prop -- `scripts/build/creature_bed.gd` is a
## second, independent use of the same installed asset, not the asset's only
## intended role. Reusing it here for the player's own sleeping spot is the
## same "reuse what's installed" move, gives the player's bedroll the exact
## same weathered-fabric/lashed-log finish as the tent beside it, and needs
## no new sourcing, no new provenance row, and no Meshy credit.
const PLAYER_BED := "res://assets/props/generated_camp/camp_bed.glb"
## Measured (tools/_probe_t1_camp.gd): camp_bed.glb is 1.229 x 0.409 x 1.901m
## raw (needs no scaling, same as its creature_bed.gd use) with its own
## origin 0.215m above its geometric base -- the same sink compensation
## creature_bed.gd now carries. Positioned clear of STONE_RING_SCALE's own
## ~0.8m radius from the fire and away from TENT_POSITION's footprint on the
## opposite side, in the same "beside the fire, outside the tent" spot the
## old bedroll held.
const PLAYER_BED_POSITION := Vector3(2.3, 0.215, 0.7)
const PLAYER_BED_ROTATION_DEG := 20.0
## FIRST-HOUR-FUN-REBUILD. The player-built Camp is the compact mandatory
## campsite, so it must visibly carry the promised shelter as well as the fire
## and bedroll it already had. This owner-reference-derived tent is already
## installed and used by authored Meadows camps; BUILD_PIECE instantiates its
## glb scene with the same collision/ghost behavior as other placeables.
const TENT := "res://assets/props/generated_camp/camp_tent.glb"
## T1-CAMP: measured (tools/_probe_t1_camp.gd) -- camp_tent.glb's own local
## origin sits 0.611m above its own geometric base, the same glTF-export
## quirk `docs/ASSET_LEDGER.md` already documents a `sink_m: -0.64`
## compensation for on this same mesh's AUTHORED placement
## (band1_lower_meadows/props.json). That compensation lives in props.gd's
## scatter path; camp.gd positions this node directly with no such support,
## so the player-built tent was sitting with its own origin AT ground level
## -- meaning the visible mesh's true base was 0.611m BELOW the ground
## plane, burying roughly half the tent's height and reading as a
## knee-high toy in an otherwise human-scale camp. The y term below restores
## true ground contact.
const TENT_POSITION := Vector3(-1.65, 0.611, -0.85)

## T1-CAMP: the campfire had no stone ring at all -- every AUTHORED camp in
## the game (band1/band3/band4's trail_camp clusters, the stronghold rest
## point) pairs `Bonfire_Fire` with this same Meshy-generated ring, but the
## PLAYER-built camp (this file) never did, so the one campsite every player
## actually places read as bare logs dropped on grass while every scripted
## one nearby looked deliberately built. Same asset family as the tent
## (both from the owner-directed camp-set generation, docs/ASSET_LEDGER.md),
## so this also directly serves §17's "share one material/style family".
const STONE_RING := "res://assets/props/generated_camp/campfire_stone_ring.glb"
## Measured (tools/_probe_t1_camp.gd): the ring is a flat 2.00m-diameter
## mesh. The authored trail_camp scales it to 1.05 (~2.1m) around a
## Bonfire_Fire at scale 0.45 (~0.98m footprint) in open ground with room to
## spare. This camp's own layout is tighter (TENT_POSITION above sits only
## 0.85m from the fire's own centre once its footprint is subtracted) and
## its Bonfire_Fire runs at FIRE_SCALE (0.55, ~1.1m footprint) -- 0.8
## (~1.6m) is the largest scale that clears the tent's edge with a small
## margin while still leaving the fire's own footprint a believable ~20cm
## gap to the stones, the same "logs inside an empty ring; the glow is
## `ignite()`, not this mesh" composition the authored recipe's own `_why`
## describes.
const STONE_RING_SCALE := 0.8
const FIRE_SCALE := 0.55

## T1-CAST-FIX (JUDGE-3 sec1b: the lit fire "reads as a yellow crystal
## cluster, not a fire"). The visible flame is now the Meshy-generated flame
## sculpt that has sat unused under generated_camp/ since the authored
## trail_camp reverted it -- props.json's `_why` records that revert as "an
## opaque carved spire with no emissive light cast", which an isolation
## render (tools/_capture_flame_isolation.gd) showed was never a SHAPE
## problem: raw, the sculpt is a genuinely flame-shaped swirl that merely
## reads as carved wood because nothing lit it. `ignite_mesh()` +
## `hide_fire_surface()` are the fix: the sculpt glows from its own baked
## warm-to-hot gradient and Bonfire_Fire's old faceted `Fire` cone (the
## actual "crystal" in the judgement) is hidden underneath it. Energy 3.5:
## after `ignite_mesh` switched to a pure-emitter material with a MULTIPLIED
## emission tint (see its own header for the round-2 white-out that forced
## that), the isolation sweep read 2.0 as flat matte red-orange, 3.5 as an
## orange flame with a genuinely hot pale core, and 5.0 as pale yellow
## throughout -- the old 0.5 belongs to the pre-multiply material and would
## render nearly black now.
const CAMP_FLAME := "res://assets/props/generated_camp/camp_flame.glb"
## Raw sculpt is 2.00m tall x ~0.5m wide (isolation probe); the log pile it
## sits on tops out at 0.616m raw * FIRE_SCALE = ~0.34m world
## (tools/_probe_flame_fit.gd). 0.85 gives a ~1.7m flame over a ~1.2m-wide
## pile -- up from a first-pass 0.7 after a blind judgement on the wider
## gameplay-distance frame said the flame was "nearly invisible" inside its
## own glow; the sculpt's silhouette, not the halo, has to be what carries
## at range. The base sinks below the pile's top so the flame emerges from
## between the logs rather than balancing on them.
const CAMP_FLAME_SCALE := 0.85
const CAMP_FLAME_POSITION := Vector3(0.0, 0.18, 0.0)
const CAMP_FLAME_ENERGY := 3.5
## See the overlay comment in `_spawn_meshes` -- a halo at 1.0 swallowed the
## sculpt whole ("one additive yellow ball"), none left it hard-edged, and
## 0.45 still read at distance as "a static glow/light blob" with the flame
## lost inside it. 0.3 keeps just enough soft bloom at the flame's base.
const HALO_FRACTION := 0.3

const FADE_SECONDS := 1.2

var _ghost_meshes: Array[MeshInstance3D] = []
var _ghost_tent: Node3D = null
var _ghost_ring: Node3D = null
var _ghost_bed: Node3D = null
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

	# T1-CAST-FIX round 2: no standalone OmniLight here any more. It predates
	# the CampfireGlow overlay this camp's fire now carries (which brings its
	# own flickering fire light, the same one every authored campfire uses),
	# and the two lights stacked -- a blind judgement on the doubled-up frame
	# called the ground pool "much larger and brighter than the small visible
	# flame geometry would justify."

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
	_ghost_ring = null
	_ghost_bed = null
	var tent := BUILD_PIECE.new()
	add_child(tent)
	tent.position = TENT_POSITION
	if solid:
		tent.call("build_real", TENT)
	else:
		tent.call("build_ghost", TENT)
		_ghost_tent = tent
	var ring := BUILD_PIECE.new()
	add_child(ring)
	if solid:
		ring.call("build_real", STONE_RING, {}, Vector3.ONE * STONE_RING_SCALE)
	else:
		ring.call("build_ghost", STONE_RING, Vector3.ONE * STONE_RING_SCALE)
		_ghost_ring = ring
	var bed := BUILD_PIECE.new()
	add_child(bed)
	bed.position = PLAYER_BED_POSITION
	bed.rotation.y = deg_to_rad(PLAYER_BED_ROTATION_DEG)
	if solid:
		bed.call("build_real", PLAYER_BED)
	else:
		bed.call("build_ghost", PLAYER_BED)
		_ghost_bed = bed
	var fire := _mesh(BONFIRE, Vector3.ZERO, FIRE_SCALE)
	# The fire, lit -- only on the real thing: the drag-around ghost is meant
	# to read as a preview, not as a fire already burning. Bonfire_Fire's own
	# faceted `Fire` cone is hidden and the generated flame sculpt stands in
	# its place (see CAMP_FLAME's header for the JUDGE-3 history that forced
	# this); the logs keep the shared bark retexture. The overlay is the same
	# light/embers/smoke rig every authored campfire gets through props.gd's
	# glow branches, built WITHOUT its billboard halo (`new(false)`) because
	# the sculpt already supplies the flame's visible shape -- the exact
	# pairing props.gd's `glow: "flame_mesh"` branch shipped -- EXCEPT the
	# halo, which stays on at HALO_FRACTION: a blind pass on the halo-less
	# frame called the sculpt "a distinct, clean outline... rather than a
	# soft, feathered/glowing falloff" (no bloom post-process exists under
	# the Compatibility renderer, so an emissive mesh never glows on its
	# own), and the FULL-size halo re-rendered as one additive yellow ball
	# that swallowed the sculpt entirely. The fraction is the manual bloom
	# in between: a soft edge hugging the sculpt without replacing its
	# silhouette (`campfire_glow.gd`'s `halo_scale` header). Child of `fire`
	# itself (not of `self`) so the counter-scale cancels `FIRE_SCALE` the
	# way props.gd counter-scales its own `scale_factor` -- the overlay's
	# sizes are absolute metres and must not shrink with the log pile
	# (`campfire_glow.gd`'s own header).
	if fire != null and solid:
		CAMPFIRE_GLOW.hide_fire_surface(fire)
		CAMPFIRE_GLOW.texture_logs(fire)
		var flame_scene := load(CAMP_FLAME) as PackedScene
		if flame_scene != null:
			var flame := flame_scene.instantiate() as Node3D
			flame.name = "CampFlame"
			flame.position = CAMP_FLAME_POSITION
			flame.scale = Vector3.ONE * CAMP_FLAME_SCALE
			add_child(flame)
			CAMPFIRE_GLOW.ignite_mesh(flame, CAMP_FLAME_ENERGY, true)
		var overlay: Node3D = CAMPFIRE_GLOW.new(true, HALO_FRACTION)
		overlay.scale = Vector3.ONE / FIRE_SCALE
		fire.add_child(overlay)
	if not solid:
		if fire != null:
			_ghost_meshes.append(fire)
		return
	for m in [fire]:
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
	if _ghost_ring != null and is_instance_valid(_ghost_ring):
		_ghost_ring.call("tint_ghost", ok)
	if _ghost_bed != null and is_instance_valid(_ghost_bed):
		_ghost_bed.call("tint_ghost", ok)


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
