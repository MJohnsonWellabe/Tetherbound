extends Node3D

## A rigged human, loaded from a block in data/config/art.json and fitted to the
## height that block declares.
##
## Extracted from `scripts/player/trainer_model.gd`, which was the only thing in
## the project that could do this and is now one of two — Grandpa is the same
## rig, the same fitting problem, and the same five clip names. The trainer's
## own subclass keeps everything that is about the TRAINER (reading the
## controller's state to pick a clip, the throw animation) and nothing else.
##
## Nothing here reads gameplay state. A subclass decides what the body should be
## doing and calls `play()`; this decides how big it is and where its clips came
## from.

const CONFIG_PATH := "res://data/config/art.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

var _art: Node3D = null
var _body: MeshInstance3D = null
var _anim: AnimationPlayer = null
var _clips: Dictionary = {}
var _current: String = ""
## role -> m/s the clip was AUTHORED for (art.json `gait_reference_speeds`).
## Empty for characters whose config declares none; they play at 1x.
var _gait_speeds: Dictionary = {}

var _height: float = 1.8
var _model_yaw: float = 0.0
var _config_key: String = ""
var _cfg: Dictionary = {}

## True while the body is posed lying flat rather than standing (OF8's wake
## beat). See `set_lying()` for what this actually does to `_art`.
var _lying: bool = false

## Shared across every character built by any instance of this script, so that
## two NPCs asking for the same base model, surface and colour draw with one
## Material resource instead of one each — the sharing `vegetation.gd`'s own
## `_tint_for` cache already proves, keyed here by (model path, surface or
## part id, colour) instead of (source name, colour, swap). NP1: the board's
## "keep colour calls low by using shared materials" is a literal requirement,
## not a nice-to-have.
static var _variant_materials: Dictionary = {}


## Load the named block and stand the body up. False means nothing loaded and
## whatever placeholder the scene carries should stay visible.
func build(config_key: String) -> bool:
	_config_key = config_key
	return build_from_config(config_for(config_key))


## Same as `build()`, but takes the config dict directly instead of reading it
## from `art.json` by key. Exists so a test (or a future picker UI) can drive
## a one-off variant — hair colour, an accessory toggled on, a palette entry —
## without writing it into the shared production config file first.
func build_from_config(cfg: Dictionary) -> bool:
	_cfg = cfg
	_height = float(cfg.get("height", _height))
	_model_yaw = float(cfg.get("model_yaw", 0.0))
	_clips = cfg.get("clips", {})
	_gait_speeds = cfg.get("gait_reference_speeds", {})
	if not _build_art(str(cfg.get("model", ""))):
		return false
	_hide_placeholders()
	_apply_palette(cfg)
	_apply_hair(cfg)
	_apply_accessories(cfg)
	return true


func config() -> Dictionary:
	return _cfg if not _cfg.is_empty() else config_for(_config_key)


static func config_for(key: String) -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var entry: Variant = (parsed as Dictionary).get(key, {})
	return entry if entry is Dictionary else {}


func has_model() -> bool:
	return _art != null


func height() -> float:
	return _height


## The hair or accessory node `_apply_hair`/`_apply_accessories` attached
## under that exact name, or null if none was (either the config named none,
## or it was `visible: false`). Public so a test can assert presence/absence
## without reaching into `_art`'s tree itself.
func find_part(part_name: String) -> MeshInstance3D:
	if _art == null:
		return null
	return _art.find_child(part_name, true, false) as MeshInstance3D


## The material actually drawn on the rig's own mesh (never a hair/accessory
## placeholder), after `_apply_palette` has run. Null if nothing built.
func body_material() -> Material:
	return _body.get_active_material(0) if _body != null and _body.mesh != null else null


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_mesh_instance(child)
		if found != null:
			return found
	return null


func clip_for(role: String, fallback: String = "idle") -> String:
	return str(_clips.get(role, fallback))


func animation_player() -> AnimationPlayer:
	return _anim


## Every sibling of the loaded art, hidden. The scenes keep a capsule as the
## fallback, so a missing asset is a character who looks wrong rather than a
## character who is not there — but once the real body is up, the capsule is
## just a capsule standing inside it.
func _hide_placeholders() -> void:
	for child in get_children():
		if child != _art and child is Node3D:
			(child as Node3D).visible = false


func _build_art(path: String) -> bool:
	if path == "" or not ResourceLoader.exists(path):
		return false
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return false
	_art = packed.instantiate() as Node3D
	if _art == null:
		return false
	add_child(_art)
	_fit()
	_art.rotation.y = deg_to_rad(_model_yaw)
	# Captured before `_apply_hair`/`_apply_accessories` add their own
	# MeshInstance3D siblings, so `body_material()` always answers about the
	# rig's own mesh and never about a placeholder part.
	_body = _find_mesh_instance(_art)
	_anim = _find_animation_player(_art)
	if _anim == null:
		# KayKit's characters ship with no clips at all, so Godot creates no
		# AnimationPlayer for them. One is added here for the libraries to be
		# merged into; its root is the character, which is what the library
		# clips' track paths are relative to.
		_anim = AnimationPlayer.new()
		_anim.name = "AnimationPlayer"
		_art.add_child(_anim)
		_anim.root_node = _anim.get_path_to(_art)
	_merge_libraries()
	return true


## MQ1A removed `_tame_gait_arm_swing()` from here. It scaled the baked
## walk/sprint arm keys 0.45x toward the clip's frame-0 pose at load time,
## because the session that added it had no Blender to re-bake with. The
## frame-0 pose it preserved carried the actual defect — a permanently
## hyperextended elbow, keyed backward on this rig's forearm axis — so the
## hack removed the swing and kept the anatomical error. The clips are now
## authored on render-verified axes (animate_humanoid.py's AXES table) at
## the amplitude they ship at, and nothing corrects them at load.


## Pull clips from separate animation files onto this character.
##
## KayKit ships the mesh and the motion apart: the character .glb carries a
## 23-bone rig and zero clips, and the clips live in shared libraries built on
## that same rig. Godot will not connect them on its own, so the libraries are
## loaded and their animations copied across.
##
## They must share a skeleton for this to mean anything. If a library is built
## on a different rig the clips load and drive nothing, which looks exactly like
## a model with no animations — hence the count in the log.
func _merge_libraries() -> void:
	var paths: Array = config().get("animation_libraries", [])
	if paths.is_empty():
		return
	var added := 0
	for entry: Variant in paths:
		var path := str(entry)
		if not ResourceLoader.exists(path):
			push_error("%s animation library missing: %s" % [_config_key, path])
			continue
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			continue
		var source: Node = packed.instantiate()
		var player := _find_animation_player(source)
		if player != null:
			for clip in player.get_animation_list():
				var animation: Animation = player.get_animation(clip)
				if animation != null and not _anim.has_animation(clip):
					_library().add_animation(clip, animation.duplicate())
					added += 1
		source.queue_free()
	print("[%s] merged %d animation clips" % [_config_key, added])


func _library() -> AnimationLibrary:
	# Godot 4 keeps clips in named libraries; the imported character has an empty
	# default one, or none at all if it shipped with no clips.
	if not _anim.has_animation_library(""):
		_anim.add_animation_library("", AnimationLibrary.new())
	return _anim.get_animation_library("")


## Same measure-and-fit as creature_body: the model is scaled to the size the game
## already believes in, never the other way round. A character whose art is a
## head taller than the capsule the camera frames on is a character who floats.
##
## Measured in RENDER space (`render_bounds.gd`), which is the third and final
## form of this fix. The first version raced `global_transform`; 1ebd434
## replaced it with a local-transform chain — which is race-free and, for a
## SKINNED mesh, measures a chain the renderer does not use. The humans carry
## their real scale inside the skin (inverse binds ×100, Armature ×0.01), so
## the chain measurement read 0.018m, "corrected" by ×100, and the skeleton —
## which the renderer actually follows — was blown up to 180m. Every test
## measured the same chain and agreed the trainer was 1.80m while the owner's
## screen was full of his boots. render_bounds pushes the bind AABB through the
## SKELETON's chain and the collapsed skin transform instead, which is what the
## GPU does at rest pose, so a correctly-authored human measures ~1.8 and gets
## fit ≈ 1.0.
func _fit() -> void:
	var box: AABB = RENDER_BOUNDS.measure(_art)
	if box.size.y <= 0.0001:
		return
	var fit := _height / box.size.y
	# With render-space measurement the fit really is a small correction: the
	# humans measure ~1.8 and need ~×1.0, the creatures likewise. A fit near
	# ×100 means a measurement crossed an armature compensation again — the
	# exact bug this warning is a tripwire for.
	if fit > 10.0 or fit < 0.1:
		push_warning(("%s model measured %.5fm tall and needs a x%.2f correction " % [
			_config_key, box.size.y, fit
		]) + "to reach %.2fm. A rigged model should need ~x1; " % _height +
			"a factor like x100 means the measurement missed the skin's scale.")
	_art.scale = Vector3.ONE * fit
	_art.position = Vector3(
		-(box.position.x + box.size.x * 0.5) * fit,
		-box.position.y * fit,
		-(box.position.z + box.size.z * 0.5) * fit
	)


## OF8: the wake beat's bed pose. Neither human rig has a lie-down clip —
## `tools/art_pipeline/blender/animate_humanoid.py`'s `CLIPS` dict bakes
## exactly idle/walk/sprint/jump/throw, and there is no reference art to
## generate a sixth against (CLAUDE.md: no Meshy generation without an
## owner-supplied board) — so this fakes the pose by tipping `_art` onto its
## back rather than switching to a clip that does not exist. `play()` keeps
## driving `idle` underneath it for the small breathing motion; only the
## rig's overall orientation changes here.
##
## `_fit()` (above) already puts `_art`'s local origin at the character's own
## feet, centred over the standing footprint, so rotating `_art` in place
## pivots the body around its feet rather than sliding the whole rig
## sideways — the pivot itself does not need to move for this to read as
## "lying down starting from where they were standing".
##
## The angles are not hand-derived; Node3D's Euler composition was checked
## with a throwaway script (`transform.basis * Vector3(...)` on a few
## candidate rotations, off-tree, no scene needed) rather than assumed, after
## an early hand calculation of the same numbers turned out wrong. Of the two
## natural 90-degree tips, `(x=90, z=180)` is the one where the head end (the
## art's own local +Y, "up") lands on world -Z — toward the headboard/pillow
## end, the same end `BedPrompt` already sits over — while the face (`-Z`,
## "forward") ends up pointing world +Y, up at the ceiling, rather than down
## into the mattress. `model_yaw` is folded in for whichever way this
## particular rig's front actually faces; today both human configs (trainer,
## grandpa) declare `model_yaw: 0`, so it has no visible effect yet.
func set_lying(lying: bool) -> void:
	if _art == null or _lying == lying:
		return
	_lying = lying
	if lying:
		_art.rotation = Vector3(deg_to_rad(90.0), deg_to_rad(_model_yaw), deg_to_rad(180.0))
	else:
		_art.rotation = Vector3(0.0, deg_to_rad(_model_yaw), 0.0)


func is_lying() -> bool:
	return _lying


## The art root's own local transform. Exists for the same reason
## `body_material()` does — a test asserting the lying pose landed should not
## have to reach into `_art` by hand to do it.
func art_transform() -> Transform3D:
	return _art.transform if _art != null else Transform3D()


## A palette swap on an existing rig (R7.2's villagers) rather than a second
## Meshy generation: `docs/ASSET_LEDGER.md`'s only other free humanoid, KayKit's
## Ranger, is a ~2-heads-tall toon character next to the trainer/Grandpa/Warden's
## photoreal-ish proportions, and picking it would silently settle the open
## question in `ralph/BLOCKED.md` ("Creature and human art-pipeline cohesion")
## that CLAUDE.md says not to invent. This keeps the same mesh, skeleton and
## clips and only multiplies an existing surface's albedo, so a texture keeps
## its detail (cloth weave, skin shading) and only shifts hue/value — a
## StandardMaterial3D with just `albedo_color` set and no texture would
## flatten the model to a single flat colour, which is a worse look than the
## one being avoided.
##
## `palette` generalises the old single-colour `tint` to one entry per named
## material (spec §21: "per-material or per-region variation where possible"
## — a global multiply over every surface is the exact failure it names). A
## bare `tint` still works, unmodified, by being read as `{"*": tint}`: every
## one of R7.2's three villagers needs no data change. All three of today's
## rigs (trainer, Grandpa, Warden) happen to carry exactly one material each
## (`Material_1`, confirmed against the source .glb) so `palette` and `tint`
## currently colour the same one surface either way — the difference is real
## once a rig has more than one, which NP4's modular bases will.
## GF-B-010: the walk now runs for EVERY character, tinted or not, because it
## is also where the rigs' imported `metallic` is corrected -- and the four
## rigs that needed correcting most (trainer, Grandpa, the Warden, the grunt)
## are exactly the four that declare neither `palette` nor `tint` and so used
## to return here before touching a material. An absent tint reads as the
## identity multiply `#ffffff`, which is what `art.json` already writes
## explicitly for all five villagers, so this changes no colour anywhere: see
## `_shared_variant_material()` for why white is algebraically a no-op through
## both the albedo and the emission branch.
func _apply_palette(cfg: Dictionary) -> void:
	if _art == null:
		return
	var palette: Dictionary = cfg.get("palette", {})
	if palette.is_empty():
		palette = {"*": str(cfg.get("tint", "#ffffff"))}
	_palette_node(_art, palette)


func _palette_node(node: Node, palette: Dictionary) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		var surfaces := mesh.get_surface_count() if mesh != null else 0
		for surface in surfaces:
			var source: Material = instance.get_active_material(surface)
			var name := source.resource_name if source != null and source.resource_name != "" \
				else "surface_%d" % surface
			var hex: String = str(palette.get(name, palette.get("*", "")))
			if hex == "":
				hex = "#ffffff"
			instance.set_surface_override_material(
				surface, _shared_variant_material(source, name, Color(hex)))
	for child in node.get_children():
		_palette_node(child, palette)


## One Material per (model, material-or-part name, colour) tuple, shared by
## every character that asks for the same one, instead of `source.duplicate()`
## per character — the "mints a material per variant" mistake NP1 was told not
## to repeat. `vegetation.gd::_retint()`'s `_tint_for()` proves the same
## pattern for foliage (`ralph/BACKLOG.md`'s `SA1-lod`, keyed by everything
## that can change the output); this is that cache for humans.
##
## STALE-PROSE WARNING, GF-B-010, 2026-08-27. Everything below about emission
## describes rigs the project no longer ships. Measured on today's six .glb
## files (`tools/_probe_npc_materials.gd`): `emission_enabled` is FALSE on every
## body material, `emission_texture` is null and `emission_operator` is 0. The
## rigs were rebuilt since `NP2`/`STRANDED-P3` were written. The emission block
## at the bottom of this function is therefore dead for every character in the
## game today -- kept, not deleted, because it is correct for any rig that does
## arrive carrying emission, and because deleting it would throw away the one
## written record of why an emission floor has to be additive. Read it as
## history, not as a description of the assets.
##
## What was ACTUALLY crushing Team Tether to black is the `metallic` correction
## in the body of this function, not any of this: see its own comment.
## Found doing `NP2`: every one of these three rigs' source materials ships
## with `emission_enabled = true` and an `emission_texture` set to the SAME
## painted texture as `albedo_texture`, at a full white `emission` multiplier
## — a self-lit "painted" look, not a shading bug. Emission is additive and
## reads independently of lighting, so it swamps any `albedo_color` change
## completely: a still-life diagnostic tinting a Warden body pure red
## (`albedo_color = (1,0,0,1)`, confirmed via `body_material()`) rendered
## fully green, unchanged, because the emission pass painted the original
## texture over it regardless. This means `NP1`'s whole palette mechanism —
## shipped, unit-tested, believed working — has never actually been visible
## on screen; the tests only ever read `body_material().albedo_color`, never
## a rendered pixel. Tinting `emission` the same way `albedo_color` already
## was closes that gap without touching the "painted, self-lit" look itself:
## a fully white emission untouched by a "*" wildcard tint of `#ffffff`
## renders identically to before, and any other tint now visibly lands.
func _shared_variant_material(source: Material, name: String, colour: Color,
		finish: Dictionary = {}) -> Material:
	# `finish` joins the cache key because it changes the rendered material as
	# much as `colour` does; two accessories sharing a name and a colour but
	# asking for different metal would otherwise silently share one instance.
	var key := "%s|%s|%s|%s" % [str(_cfg.get("model", "")), name, colour.to_html(),
		("" if finish.is_empty() else "%s/%s" % [finish.get("metallic", ""), finish.get("roughness", "")])]
	if _variant_materials.has(key):
		return _variant_materials[key]
	var material: BaseMaterial3D = (source.duplicate() as BaseMaterial3D) \
		if source is BaseMaterial3D else StandardMaterial3D.new()
	material.albedo_color = material.albedo_color * colour
	# A default StandardMaterial3D is roughness 1.0 / metallic 0.0 -- perfectly
	# matte. On a flat-faced primitive under one directional key that renders as
	# a single uniform colour with no gradient anywhere across it, which is
	# precisely why the captain's chest badge photographed as "a flat pure-red
	# untextured rectangle" and read as a debug gizmo rather than insignia. The
	# shape ladder was not the problem; the absence of any shading model was.
	# Metal gives the face a specular falloff, so a primitive reads as a struck
	# metal object rather than as a colour swatch pasted over the costume.
	if finish.has("metallic"):
		material.metallic = float(finish["metallic"])
		material.metallic_specular = float(finish.get("metallic_specular", 0.5))
	elif material.metallic > 0.0 and material.metallic_texture == null:
		# GF-B-010, the actual cause of "an NPC renders as an unlit black
		# silhouette in daylight", reproduced and A/B'd in a controlled frame
		# (`tools/_probe_npc_metallic_ab.gd`): all six humanoid rigs render as
		# jet-black cut-outs beside a correctly lit crate, and forcing this one
		# property restores every fold, strap and boot.
		#
		# glTF 2.0's default for an ABSENT `metallicFactor` is 1.0, not 0.
		# Every one of the six rigs' .glb materials omits it -- checked in the
		# JSON chunk of trainer, Grandpa, villager_male, villager_female, the
		# Warden and the grunt -- so Godot imports each body as
		# `metallic = 1.0, roughness = 1.0`: a fully-rough METAL. A metal has
		# no diffuse term at all; its only response is a specular lobe that
		# roughness 1.0 spreads to nothing, so the body returns almost no light
		# whichever way the sun points. That is why the sun-azimuth hypothesis
		# could not explain it, and why the grass, trees, terrain and props in
		# the same frame are fine.
		#
		# The props are the proof rather than a counter-example. They omit
		# `metallicFactor` too, but they ship an ORM/metallic-roughness texture
		# (the crate: `T_Trim_Furniture_ORM.png`, blue channel), and the
		# per-texel blue multiplies that 1.0 back down to dielectric. So does
		# every Tetherbound creature .glb. The six humanoid rigs are the one
		# class in the project that carries a metallic factor with NO texture
		# to modulate it, which is exactly the condition tested here -- a rig
		# that later ships a real ORM map keeps whatever that map says, and a
		# rank badge that deliberately asks for metal (`finish`, above) is
		# handled by the branch that owns it.
		#
		# Roughness is deliberately left alone. It is the same absent-default
		# 1.0, but a fully rough dielectric is a correct matte cloth, and
		# picking a sheen for six rigs is a look decision this defect does not
		# license.
		material.metallic = 0.0
	if finish.has("roughness"):
		material.roughness = float(finish["roughness"])
	if material.emission_enabled:
		# STRANDED-P3: a dark tint (a Team Tether rank palette, e.g. the grunt's
		# original #4a5049) darkens the SAME colour into both albedo and this
		# self-lit emission at once, so the two channels that were supposed to
		# keep a figure legible in shade both crush toward black together
		# instead of one backstopping the other -- confirmed on Hess reading
		# as a near-silhouette against the band3 meadow.
		#
		# A first fix here (raising the palette's own luminance, plus scaling
		# `emission_energy_multiplier` up when the tint is dark) still rendered
		# Hess almost entirely black -- because a straight multiply can only
		# ever DARKEN a source pixel, never brighten one. Wherever the rig's
		# own painted emission texture is already near-zero (a dark uniform
		# panel, a shadowed fold), `texture * colour` stays near-zero no
		# matter how bright `colour` is, and no energy multiplier rescues a
		# value that was already zero going in.
		#
		# Fixed the same way `severed_spokes.gd::_tether_material()` handles
		# its own always-dark oxblood: an ADDITIVE floor, not a multiplier.
		# `lerp()` toward the tint colour guarantees the emission is never
		# darker than a fraction of the tint itself, regardless of what the
		# source pixel started at -- a near-black source region floors at
		# `colour * EMISSION_FLOOR_BLEND`, while a source region that was
		# already bright keeps most of its own painted variation.
		#
		# Gated on the tint actually being dark: every non-rank tint in the
		# game is `#ffffff` (art.json's identity multiply, after the villager
		# tint saga this same file's NP6 comment documents), and this floor
		# must stay a no-op there -- `colour.lerp(colour, x) == colour`, so
		# floor-then-identity is safe algebraically, but the energy-multiplier
		# bump below is not, and skipping the whole block is clearer than
		# relying on that algebra. TUNABLE.
		# THE FLOOR IS NOW GENUINELY ADDITIVE, which is what this block has claimed
		# to be since STRANDED-P3 and was not.
		#
		# The old implementation lerped `material.emission` -- the emission COLOUR,
		# which Godot uses as a MULTIPLIER over `emission_texture` whenever
		# `emission_operator` is `EMISSION_OP_MULTIPLY`. Probed directly on the
		# built rank materials: the operator is 1 (MULTIPLY) on every one of them,
		# inherited from the glTF import. So the "floor" raised a multiplier and
		# the product stayed dark, for exactly the reason the comment above gives
		# for albedo -- "a straight multiply can only ever DARKEN a source pixel,
		# never brighten one". The floor was subject to the same law it was
		# written to escape, and raising its blend from 0.5 to 0.72 moved the
		# rendered uniform by about one value point, which is how it was caught.
		#
		# What it cost: a blind round measured every Team Tether body at 0.11-0.18
		# lightness and reported the whole faction collapsing into
		# "interchangeable near-black smears" at thumbnail size -- meaning the
		# reserved oxblood the rank palettes carry was, in practice, absent from
		# the faction it exists to identify. The grunt rig's own texture is the
		# reason it needs a floor at all: sampled off `grunt_lod0_texture_0.png`,
		# its dominant values sit at 14-30 out of 255.
		#
		# Switching the operator to ADD makes the tint reach the surface no matter
		# how dark the texel under it is, which is the whole point. The added
		# amount is deliberately small: enough to carry hue and lift the uniform
		# into a value where hue survives distance, not enough to flatten the
		# painted panels, straps and folds into one self-lit slab. Texture
		# variation survives because the add is constant while the texture is not.
		#
		# Only tinted characters are affected. The gate skips any tint at
		# luminance >= 0.95, and every non-rank tint in the game is `#ffffff`
		# (art.json's identity multiply), so the trainer -- five independent
		# critics' named style anchor -- Grandpa and every villager render
		# bit-identical across this change. It reaches Team Tether and nothing
		# else, which is exactly the scope the defect has. TUNABLE.
		# 0.30, raised alongside the move to genuinely dark oxblood palettes: the
		# add is `colour * EMISSION_FLOOR_ADD`, so a darker tint contributes a
		# smaller floor and needs a larger coefficient to stay legible.
		# 0.06, down from 0.30. The floor's job shrank dramatically once the
		# faction colour moved into the rig's own texture: it no longer has to
		# manufacture a colour on a near-black surface, only to keep the very
		# darkest folds from crushing. At 0.30 it was adding the same absolute
		# amount to the blacks and the mids alike, which halved the texture's
		# 7.5x contrast ratio and produced the "washed, blacks lifted to grey"
		# reading a blind round gave the whole ranked cast. An additive floor is
		# the right tool for a crushing shadow and the wrong tool for a palette.
		const EMISSION_FLOOR_ADD := 0.06
		var tint_luminance := colour.r * 0.2126 + colour.g * 0.7152 + colour.b * 0.0722
		if tint_luminance < 0.95:
			material.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
			material.emission = colour * EMISSION_FLOOR_ADD
			material.emission_energy_multiplier = 1.0
		else:
			material.emission = material.emission * colour
	_variant_materials[key] = material
	return material


## A placeholder shape standing in for real hair geometry — trainer, Grandpa
## and the Warden still have no separable hair mesh, each one fused mesh,
## one material, confirmed against the source files, so their "swappable
## hair" can only mean the DATA and ATTACHMENT mechanism prototyped here.
## `CLAUDE.md`'s Prototyping section is explicit that a placeholder proves
## mechanics and is not to be judged as a look.
##
## `NP7` gave villager_female's base .glb a REAL separable piece: the
## twin-ponytail cut from the fused source mesh in Blender, patched at the
## scalp, re-skinned to the Head bone, and exported back in as a second
## mesh (`hair_ponytail`) already sitting inside the same file `_build_art`
## loaded — sibling to the body mesh, under the same Skeleton3D, already
## correctly posed by its own skin the same way the body is. So for a
## config whose base model ships that mesh, this function's job shrinks to
## exactly what the spec asks for — hide/show, and recolour if asked — and
## the manual `BoneAttachment3D` + offset path below is never reached: a
## skinned mesh needs no offset in the first place, which is the real fix
## for the class of bug `_attach_part`'s offset carries (see its own
## comment) rather than a workaround for it.
func _apply_hair(cfg: Dictionary) -> void:
	var hair: Dictionary = cfg.get("hair", {})
	if hair.is_empty():
		return
	var visible := bool(hair.get("visible", true))
	var real_part_name := str(hair.get("model_part", "hair_ponytail"))
	var real_part: MeshInstance3D = null
	if _art != null:
		real_part = _art.find_child(real_part_name, true, false) as MeshInstance3D
	if real_part != null:
		real_part.visible = visible
		if not visible:
			# Left named `real_part_name`, not `hair` -- `find_part("hair")`
			# correctly reports null, the same contract a placeholder's
			# absence gives, per this function's own doc below.
			return
		real_part.name = "hair"
		var hex_real := str(hair.get("color", hair.get("colour", "")))
		if hex_real != "":
			real_part.set_surface_override_material(0, _shared_variant_material(
				real_part.get_active_material(0), "hair", Color(hex_real)))
		return
	if not visible:
		return
	var mesh := _primitive_mesh(str(hair.get("shape", "sphere")), 0.11)
	var part := _attach_part(mesh, str(hair.get("bone", "Head")), Vector3(0, 0.08, 0), "hair")
	if part == null:
		return
	var hex := str(hair.get("color", hair.get("colour", "#2b1b12")))
	part.set_surface_override_material(
		0, _shared_variant_material(StandardMaterial3D.new(), "hair", Color(hex)))


## Same placeholder reasoning as `_apply_hair`, for however many entries `cfg`
## names. Each is independently visible/hidden and coloured — the mechanism
## spec §21 and the NPC board ask for ("hide/show accessories via separate
## mesh parts"); the shapes themselves are stand-ins until real geometry
## exists.
func _apply_accessories(cfg: Dictionary) -> void:
	var accessories: Array = cfg.get("accessories", [])
	for entry: Variant in accessories:
		if not entry is Dictionary:
			continue
		var acc := entry as Dictionary
		if not bool(acc.get("visible", true)):
			continue
		var mesh := _primitive_mesh(str(acc.get("shape", "box")), float(acc.get("size", 0.12)))
		var offset := Vector3.ZERO
		var raw_offset: Array = acc.get("offset", [])
		if raw_offset.size() == 3:
			offset = Vector3(raw_offset[0], raw_offset[1], raw_offset[2])
		var name := "accessory_%s" % str(acc.get("name", "accessory"))
		var part := _attach_part(mesh, str(acc.get("bone", "Hips")), offset, name)
		if part == null:
			continue
		if str(acc.get("shape", "box")) in ["disc", "ring"]:
			# CylinderMesh is built around Y; a chest badge lies in the coronal
			# plane, so tip it a quarter turn to face forward off the bone.
			part.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
		var hex := str(acc.get("color", acc.get("colour", "#5a3d21")))
		var finish := {}
		for property: String in ["metallic", "metallic_specular", "roughness"]:
			if acc.has(property):
				finish[property] = acc[property]
		part.set_surface_override_material(
			0, _shared_variant_material(StandardMaterial3D.new(), name, Color(hex), finish))


func _primitive_mesh(shape: String, size: float) -> PrimitiveMesh:
	match shape:
		"box":
			var box := BoxMesh.new()
			box.size = Vector3.ONE * size
			return box
		"ring":
			# The rim of a struck medal. A blind round named the chest badge "a
			# flat, unshaded, borderless dark-red ellipse... it reads as a paint
			# splat or a debug decal", and pointed at the fix in the same
			# sentence: these characters' CAP badge is a proper gold ring-and-dot
			# device, and the bare blob below it looks unfinished by comparison.
			# A torus laid in the coronal plane behind a `disc` gives the chest
			# badge that same ring-and-dot reading, with a curved rim that
			# catches the key from a different angle than the flat face does.
			var ring := TorusMesh.new()
			ring.inner_radius = size * 0.40
			ring.outer_radius = size * 0.50
			ring.rings = 24
			return ring
		"disc":
			# A struck medal: a shallow cylinder whose rim curves away from the
			# key light, giving the shape a lit edge and a shaded one. A `box`
			# badge presents ONE flat face square to the camera and, being a
			# plane, takes exactly one shade across the whole of it -- which is
			# what made the captain's insignia photograph as a flat red
			# rectangle with no shading model at all. CylinderMesh is built
			# around the Y axis, so `_apply_accessories` lays it onto the chest;
			# a mesh resource cannot carry that rotation itself.
			var disc := CylinderMesh.new()
			disc.top_radius = size * 0.5
			disc.bottom_radius = size * 0.5
			disc.height = size * 0.22
			disc.radial_segments = 24
			return disc
		"capsule":
			var capsule := CapsuleMesh.new()
			capsule.radius = size * 0.5
			capsule.height = size * 2.0
			return capsule
		_:
			var sphere := SphereMesh.new()
			sphere.radius = size * 0.5
			sphere.height = size
			return sphere


## Finds the named bone on whatever Skeleton3D `_art` carries and hangs a new
## MeshInstance3D off it via BoneAttachment3D, so the part follows the rig
## through every clip instead of standing fixed relative to the root. Falls
## back to a plain child of `_art`, offset up by the character's own height,
## if the bone or the skeleton is not found — a body with no matching bone
## gets a static part rather than silently no part at all.
##
## `NP7`/`NP1-geometry`'s history flagged a bug here: a manual `offset` like
## `_apply_hair`'s old placeholder `Vector3(0, 0.08, 0)` was said to land at
## roughly 1/100th scale in-game, blamed on the same Armature-chain
## compensation `render_bounds.gd`'s own comment documents for the
## giant-player bug (inverse-bind matrices ×100 into a skin, offset by a
## 0.01-scale `Armature` node). Checked directly against today's shipped
## rigs before touching this function — a scratch probe reading
## `attachment.global_transform` and `Head` bone `global_rest`/`global_pose`
## on both the trainer and villager_female found `Armature` and `Skeleton3D`
## both at scale (1,1,1), and a placeholder offset of `Vector3(0, 0.08, 0)`
## landing exactly 0.08m from the bone origin, correctly rotated with it —
## not reproducible on the rigs this project ships today. The giant-player
## fix (`render_bounds.gd`, `_fit()` above) most likely already closed this
## as a side effect: it stopped `_art.scale` itself from ever being blown up
## to ~100, which is the other half a residual node-scale would need to
## produce a 1/100 offset in the first place. Hardened anyway, per the
## backlog item's own "fix while you're in this function" — dividing the
## authored offset (and the instance's own scale) by whatever scale the
## attachment chain actually carries keeps `offset` in real-world metres
## regardless, at zero cost while that scale is 1.0 as it is today.
func _attach_part(mesh: Mesh, bone: String, offset: Vector3, part_name: String) -> MeshInstance3D:
	if _art == null:
		return null
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	var skeleton := _find_skeleton(_art)
	if skeleton != null and skeleton.find_bone(bone) >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = bone
		skeleton.add_child(attachment)
		attachment.add_child(instance)
		# `global_transform` needs the node inside the tree to mean anything —
		# harmless in normal play (character_model.gd is always a child of a
		# Player/NPC node already in the tree by the time build() runs) but a
		# real, previously-silent bug for any off-tree caller (found by NP8's
		# accessory addition: tools/capture_village_npcs.gd builds a model
		# before adding it to the scene, and this printed a Godot engine error
		# — "!is_inside_tree()" — every time, silently falling through to a
		# wrong 0-scale transform rather than the intended identity fallback).
		var chain_scale: Vector3 = (
			attachment.global_transform.basis.get_scale() if attachment.is_inside_tree()
			else Vector3.ONE
		)
		var safe_scale := Vector3(
			chain_scale.x if absf(chain_scale.x) > 0.0001 else 1.0,
			chain_scale.y if absf(chain_scale.y) > 0.0001 else 1.0,
			chain_scale.z if absf(chain_scale.z) > 0.0001 else 1.0)
		instance.position = Vector3(
			offset.x / safe_scale.x, offset.y / safe_scale.y, offset.z / safe_scale.z)
		if not safe_scale.is_equal_approx(Vector3.ONE):
			instance.scale = Vector3.ONE / safe_scale
	else:
		_art.add_child(instance)
		instance.position = offset + Vector3(0, _height, 0)
	return instance


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


## OF24: the trainer rig's own `Skeleton3D`, for a caller that needs to hang
## something off a bone directly rather than through `_apply_accessories`'
## single-mesh-plus-palette shape (scripts/player/torch.gd's carried torch is
## a multi-part prop -- stick, flame, embers -- not a coloured primitive).
## Null the same way `find_part()` answers null: no art built yet, or no
## skeleton on whatever did build.
func skeleton() -> Skeleton3D:
	return _find_skeleton(_art) if _art != null else null


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


## Cross-faded rather than cut. A body that snaps between walk and idle reads as
## broken even when the states are correct.
##
## `looping` sets the underlying Animation resource's loop mode before playing
## it, the same way `creature_animator.gd`'s `_play()` already does for creatures.
## Every clip `animate_humanoid.py` bakes ships as LOOP_NONE — a bare export
## default, never set per-clip — so without this, a continuous state like
## "walk" (1.38s) plays its cycle once and freezes mid-stride for as long as
## the state holds, which reads as "the character has no animation" even
## though the clip exists, resolves, and the caller is asking for it every
## frame. Confirmed directly against the trainer's own .glb: idle, walk,
## sprint, jump and throw all measured `loop_mode == LOOP_NONE`.
func play(clip: String, looping: bool = true) -> void:
	if _anim == null or clip == _current or not _anim.has_animation(clip):
		return
	_current = clip
	var animation := _anim.get_animation(clip)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	_anim.play(clip, 0.18)


## OF5: keep foot cadence honest against the ground. A gait clip is authored
## for one body speed (art.json `gait_reference_speeds`, matching what
## `animate_humanoid.py` derived from movement.json); played at 1x while the
## controller moves at any OTHER speed, the feet skate — the single loudest
## thing the owner read as "running and walking look unnatural". Scaling
## playback by actual speed / authored speed keeps the feet planted through
## acceleration, slopes, collisions, and any future movement.json retune,
## with no re-bake.
##
## Called every frame by whoever owns the body's state (trainer_model.gd),
## with the CURRENT role so a non-gait role resets the player to 1x — the
## scale is on the whole AnimationPlayer, and a jump or throw slowed to the
## trainer's take-off speed would be its own new bug. Clamped: below 0.5x a
## gait reads as slow-motion rather than as slowing down (the idle
## cross-fade already covers speeds that low), and above 1.4x as frantic.
func match_gait_rate(role: String, ground_speed: float) -> void:
	if _anim == null:
		return
	var reference := float(_gait_speeds.get(role, 0.0))
	if reference <= 0.0:
		_anim.speed_scale = 1.0
		return
	_anim.speed_scale = clampf(ground_speed / reference, 0.5, 1.4)


## MQ1A: weight in the transitions. The gait clips are steady-state cycles;
## what sells a start, a stop and a hard turn is the BODY tipping into the
## acceleration — a sprinter leans out of the blocks, a stopping runner sits
## back, a turning one banks. The controller owns yaw; this leans the whole
## model a few degrees about its own local X (pitch into/out of travel) and
## Z (bank into a turn) from the actual planar acceleration, smoothed so a
## one-frame velocity spike cannot snap the spine. Godot's YXZ euler order
## applies X/Z inside the yaw the controller already set, so the two writers
## compose instead of fighting.
##
## Caller passes the planar velocity each physics tick; limits live in
## movement.json's `gait_feel` block (TUNABLE) and arrive here as a config
## dict so this base class stays free of gameplay file reads.
var _tilt := Vector2.ZERO      # x = pitch degrees, y = roll degrees
var _tilt_prev_velocity := Vector3.ZERO


func apply_momentum_tilt(planar_velocity: Vector3, delta: float, feel: Dictionary) -> void:
	if delta <= 0.0:
		return
	var accel := (planar_velocity - _tilt_prev_velocity) / delta
	_tilt_prev_velocity = planar_velocity
	accel.y = 0.0

	var yaw := rotation.y
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var lateral := Vector3(cos(yaw), 0.0, -sin(yaw))

	var lean_per := float(feel.get("lean_deg_per_accel", 0.18))
	var pitch_limit := float(feel.get("pitch_limit_deg", 7.0))
	var roll_limit := float(feel.get("roll_limit_deg", 8.0))
	var rate := float(feel.get("smoothing_rate", 9.0))

	var target := Vector2(
		clampf(accel.dot(forward) * lean_per, -pitch_limit, pitch_limit),
		clampf(accel.dot(lateral) * lean_per, -roll_limit, roll_limit))
	var blend := 1.0 - exp(-rate * delta)
	_tilt = _tilt.lerp(target, blend)

	# Forward lean is negative X for a +Z-facing model; bank rolls the top of
	# the body toward the inside of the turn. Signs verified in the MQ1A turn
	# capture rather than derived on paper.
	rotation.x = deg_to_rad(-_tilt.x)
	rotation.z = deg_to_rad(-_tilt.y)


## MQ1B. Terrain adaptation: leans the body toward the ground's own slope
## and settles the model's visual height to the ground under its stance,
## ADDING to (never overwriting) apply_momentum_tilt's rotation.x/z above --
## call this AFTER apply_momentum_tilt each frame so a sprint launch on a
## slope both leans into the acceleration and banks into the hill.
##
## Root-level only: no bone pose is ever touched, so this can never produce
## a knee inversion or a broken pelvis, and there is no discrete IK blend to
## snap -- the entire correction is the same exponential smoothing
## apply_momentum_tilt already uses. The trade CLAUDE.md's "do not add
## complexity for its own sake" line asks for: a single foot catching a
## sharp local bump can still show a small gap, which true per-foot IK would
## close and this does not attempt to.
##
## `centre_delta` is (ground height under the capsule's own feet) minus
## (the capsule's current Y) — a small relative offset, not an absolute
## world height, since `position.y` below is local to this node and the
## capsule already carries the model to its own correct world height.
## `h_left`/`h_right`/`h_forward`/`h_back` are absolute ground heights
## already sampled by the caller (trainer_model.gd, which has the world's
## `ground_height_at` reachable) at the model's own stance width/stride
## ahead — only their DIFFERENCE across each pair feeds the slope angle, so
## they need no such relative conversion. This method stays free of any
## Node-tree lookup itself, the same reasoning apply_momentum_tilt already
## gives for taking `feel` as a plain Dictionary rather than reading
## movement.json directly. Any NAN sample (no ground under a probe point,
## e.g. a doorway or a cliff edge) skips the update for that frame rather
## than lurching toward a garbage angle.
var _terrain_tilt := Vector2.ZERO   # x = pitch degrees, y = roll degrees
var _terrain_height := 0.0          # smoothed local Y offset, metres


func apply_terrain_adaptation(
	centre_delta: float, h_left: float, h_right: float, h_forward: float, h_back: float,
	stance_width: float, stride_ahead: float, delta: float, feel: Dictionary
) -> void:
	if delta <= 0.0:
		return
	if is_nan(centre_delta) or is_nan(h_left) or is_nan(h_right) or is_nan(h_forward) or is_nan(h_back):
		return
	if stance_width <= 0.0 or stride_ahead <= 0.0:
		return

	# Slope angle each axis carries, from the height difference across the
	# probe pair over the known distance between them -- same atan2(rise,
	# run) shape terrain_playground.json's own slope math uses elsewhere.
	var roll_deg := rad_to_deg(atan2(h_right - h_left, stance_width * 2.0))
	var pitch_deg := rad_to_deg(atan2(h_forward - h_back, stride_ahead * 2.0))

	var lean_scale := float(feel.get("terrain_lean_scale", 0.5))
	var pitch_limit := float(feel.get("terrain_pitch_limit_deg", 18.0))
	var roll_limit := float(feel.get("terrain_roll_limit_deg", 18.0))
	var rate := float(feel.get("terrain_smoothing_rate", 6.0))

	# Un-negated target, exactly matching apply_momentum_tilt's own shape
	# (that method's own target.x is `accel.dot(forward) * lean_per`, no
	# pre-negation) — the single negation lives ONLY at the `rotation.x +=`
	# line below, the same one place momentum tilt puts it. A first version
	# of this method negated here AND at that line, which is not "extra
	# caution", it is two negatives making a positive: render evidence
	# (tools/capture_slope_test.gd's own debug print) caught the body
	# leaning AWAY from a climb instead of into it before this fix.
	var target := Vector2(
		clampf(pitch_deg * lean_scale, -pitch_limit, pitch_limit),
		clampf(roll_deg * lean_scale, -roll_limit, roll_limit)
	)
	var blend := 1.0 - exp(-rate * delta)
	_terrain_tilt = _terrain_tilt.lerp(target, blend)

	# `+=`, not an assignment: this ADDS to whatever apply_momentum_tilt just
	# set rotation.x/z to (see trainer_model.gd's own call order — momentum
	# tilt runs first, every frame, and DOES assign rather than add, so
	# rotation.x/z is always freshly momentum-only before this line runs).
	# A delta-tracking version that subtracted its own prior contribution
	# before adding the new one was tried and measured wrong (tools/
	# capture_slope_test.gd's debug print converged to ~0 deg of lean
	# instead of the ~9deg a real climb should produce) — it silently
	# assumed rotation.x carries the previous frame's terrain lean forward,
	# which momentum tilt's own reset makes false. Plain `+=` is correct
	# FOR THIS CALL ORDER; the contract is real (this must run after a
	# per-frame reset), not a bug to engineer around.
	#
	# Forward lean is negative X for a +Z-facing model, same convention
	# apply_momentum_tilt's own comment records; cresting a rise (ground
	# ahead higher, pitch_deg/target.x positive) must pitch the body forward
	# into the climb, i.e. rotation.x more negative.
	rotation.x += deg_to_rad(-_terrain_tilt.x)
	rotation.z += deg_to_rad(-_terrain_tilt.y)

	# Settle the model's own visual height to the ground centred under its
	# stance -- never the capsule's own position, which the controller
	# already keeps physically correct. Clamped well under a step height so
	# this can only ever read as the feet finding the ground, never as the
	# body detaching from the capsule that carries it.
	var height_target := clampf(centre_delta, -0.12, 0.12)
	_terrain_height = lerpf(_terrain_height, height_target, blend)
	position.y = _terrain_height
