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
## T5-CADENCE. What a night costs and pays, shared with the authored camps --
## see `_on_rest()` below and `night_rest.gd`'s own header.
const NIGHT_REST := preload("res://scripts/world/night_rest.gd")
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

const FADE_SECONDS := 1.2

const FIRE_LIGHT_BASE_ENERGY := 2.8
## T1-LIGHT, JUDGE-3 sec1b: same fix as campfire_glow.gd's own
## `DAY_ENERGY_SCALE`, see that constant's comment for the full reasoning
## (a permanently-lit ground fire cannot switch fully off in daylight
## without looking broken, so this scales the disc down below ambient
## daylight instead of hiding it).
const FIRE_LIGHT_DAY_SCALE := 0.16

var _ghost_meshes: Array[MeshInstance3D] = []
var _ghost_tent: Node3D = null
var _ghost_ring: Node3D = null
var _ghost_bed: Node3D = null
## T1-LIGHT, JUDGE-3 sec1b. This fire's own light, built below, is a SEPARATE
## OmniLight3D from campfire_glow.gd's -- the player-built camp never
## instantiates that class at all, only its `ignite()`/`texture_logs()`
## static helpers for the mesh's own Fire surface, so fixing
## campfire_glow.gd (its day/night energy scale, its softer
## omni_attenuation) never touched this light. Confirmed this is the actual
## source of the judged "unshaped blown-out disc... brighter at its centre
## than the sky, in daylight" (`tools/_capture_t1_camp.gd`'s own
## `01-camp-establishing.png`/`02-camp-close.png`, built via
## `build_real()`): a same-image pixel diff against a rebuilt
## campfire_glow.gd showed zero change here, and the fire mesh this rig
## renders never goes through `CAMPFIRE_GLOW.ignite()`'s own OmniLight
## instantiation at all -- this is it.
var _fire_light: OmniLight3D = null
var _fire_light_world_look: Node = null
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

	_fire_light = OmniLight3D.new()
	_fire_light.position = Vector3(0.0, 1.2, 0.0)
	_fire_light.light_color = Color(1.0, 0.72, 0.45)
	_fire_light.light_energy = FIRE_LIGHT_BASE_ENERGY
	_fire_light.omni_range = 10.0
	# Same reasoning as campfire_glow.gd's own LIGHT_ATTENUATION: the default
	# 1.0 exponent reads as a hard-ish edge at `omni_range`'s own cutoff.
	_fire_light.omni_attenuation = 1.8
	_fire_light.shadow_enabled = true
	add_child(_fire_light)

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
		CAMPFIRE_GLOW.texture_logs(fire)
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


## Lazy-looked-up every tick, not cached at `build_real()` time -- the same
## `torch.gd::_is_on()` OF18 lesson `campfire_glow.gd::_daylight_scale()`
## already restates: a camp can be built and placed before `world_look.gd`
## has joined the "day_cycle" group, and caching null at that moment would
## leave the fire at full daylight energy forever.
func _process(_delta: float) -> void:
	if _fire_light == null:
		return
	if _fire_light_world_look == null or not is_instance_valid(_fire_light_world_look):
		_fire_light_world_look = get_tree().get_first_node_in_group(&"day_cycle")
	var is_dark := true
	if _fire_light_world_look != null and _fire_light_world_look.has_method("is_dark"):
		is_dark = bool(_fire_light_world_look.call("is_dark"))
	_fire_light.light_energy = FIRE_LIGHT_BASE_ENERGY * (1.0 if is_dark else FIRE_LIGHT_DAY_SCALE)


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


## Rest: fade out, new day, everyone healed, fade in.
##
## T5-CADENCE moved the body of this out to `scripts/world/night_rest.gd`. It
## is unchanged -- same fade, same day advance, same `player_slept_at_home`,
## same completed creature-bed rests, same trainer heal, same morning reset,
## same autosave -- and it moved for one reason: the AUTHORED camps in the
## Meadows (`trail_camp`, `ranger_camp`, `riverwatch_rest`) now offer rest too,
## through `rest_point.gd`, and T4-REGIONS' audit is a standing warning about
## what happens when the world has two half-answers to one question. There is
## one definition of what a night costs and pays, and both callers use it.
func _on_rest() -> void:
	NIGHT_REST.rest(self)


## R2.4. Open the craft screen — data/recipes/recipes.json's base tier,
## orb_basic and potion_small, spent and granted through GameState.craft().
func _on_craft() -> void:
	if _craft_panel == null:
		_craft_panel = CRAFT_PANEL.new()
		get_tree().root.add_child(_craft_panel)
	_craft_panel.call("open")


## Kept as a thin forward: `tests/` and `tools/gate_f/probe_bed_rest_sequence.gd`
## call this directly to pass a night without waiting on a tween, and the point
## of the move above was to have ONE body, not to break the callers that pass a
## night the fast way.
func _pass_the_night(game: Node) -> void:
	NIGHT_REST.pass_the_night(self, game)
