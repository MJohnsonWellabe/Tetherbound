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
	_tame_gait_arm_swing()
	return true


## Owner playtest report, second round, watching a rendered walk cycle:
## "his arms bend backwards and look unnatural." `tools/art_pipeline/blender/
## animate_humanoid.py::author_gait()` is a `bpy`-only offline script (no
## Blender exists in this environment to re-bake trainer_lod0.glb with
## retuned numbers), so this corrects the ALREADY-BAKED walk/sprint clips at
## load time instead: every keyframe on the upper-arm and forearm rotation
## tracks is pulled proportionally back toward that same clip's own rest
## pose (its first keyframe, which a cyclic clip already shares with its
## last). This shrinks the swing without needing to know this rig's own
## bone-axis convention or touching the authored ANGLE at all -- a
## `Quaternion.slerp` toward rest stays on the same rotation axis the
## original animator's key was already on, so a bend can only ever come out
## smaller, never in the wrong direction.
##
## SWING_KEEP was tuned against real renders, not guessed once and left: a
## probe of the baked walk clip (tools/_probe_gait_keys.gd) measured the
## forearm swinging from a 34deg resting bend to a 51deg peak and the upper
## arm swinging a full 63deg on top of that -- combined, the hand travelled
## all the way up past the ribcage toward the shoulder strap on a plain
## 5m/s walk (shots/gait/walk-quarter.png, before this fix: the near hand at
## collarbone height mid-stride, not the hip-to-thigh arc a loose walking
## swing actually has). 0.65 was tried first and rendered better but still
## tucked; 0.45 (kept) reads as a natural loose swing across the whole
## cycle in a fresh render, hand travelling hip-to-belt height rather than
## hip-to-collarbone. Only Arm/ForeArm are touched -- Hips/Spine/Leg/Foot
## were not part of the report and OF5 already spent real effort getting
## the legs right.
const ELBOW_TAME_CLIPS := ["walk", "sprint"]
const ELBOW_TAME_BONES := ["LeftArm", "RightArm", "LeftForeArm", "RightForeArm"]
const ELBOW_TAME_SWING_KEEP := 0.45


func _tame_gait_arm_swing() -> void:
	if _anim == null:
		return
	for clip_name in ELBOW_TAME_CLIPS:
		if not _anim.has_animation(clip_name):
			continue
		var library := _owning_library(clip_name)
		if library == null:
			continue
		var original: Animation = library.get_animation(clip_name)
		if original == null:
			continue
		# Duplicated before mutating: an imported glTF's Animation resources
		# are not guaranteed local-to-scene, so writing into `original`
		# directly could bleed into every other instance sharing the same
		# cached resource (every other trainer/grandpa/villager built from
		# this same .glb), not just this one character.
		var tamed: Animation = original.duplicate()
		for bone in ELBOW_TAME_BONES:
			_scale_rotation_track_toward_rest(tamed, bone, ELBOW_TAME_SWING_KEEP)
		library.remove_animation(clip_name)
		library.add_animation(clip_name, tamed)


func _owning_library(clip_name: String) -> AnimationLibrary:
	for library_name in _anim.get_animation_library_list():
		var library := _anim.get_animation_library(library_name)
		if library != null and library.has_animation(clip_name):
			return library
	return null


## Scales every keyframe on the rotation track whose bone path ends with
## `bone_suffix` proportionally toward that track's own first keyframe
## (`keep=1.0` leaves it untouched, `keep=0.0` freezes the bone at rest).
## `slerp` rather than a linear blend on the Euler components -- rotation
## interpolation that stays correct regardless of Euler order or gimbal
## position, and it cannot introduce a rotation axis that was not already in
## the original key.
func _scale_rotation_track_toward_rest(animation: Animation, bone_suffix: String, keep: float) -> void:
	for track_idx in animation.get_track_count():
		if animation.track_get_type(track_idx) != Animation.TYPE_ROTATION_3D:
			continue
		if not str(animation.track_get_path(track_idx)).ends_with(bone_suffix):
			continue
		var key_count := animation.track_get_key_count(track_idx)
		if key_count == 0:
			continue
		var rest: Quaternion = animation.track_get_key_value(track_idx, 0)
		for k in key_count:
			var original: Quaternion = animation.track_get_key_value(track_idx, k)
			animation.track_set_key_value(track_idx, k, rest.slerp(original, keep))


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
func _apply_palette(cfg: Dictionary) -> void:
	if _art == null:
		return
	var palette: Dictionary = cfg.get("palette", {})
	if palette.is_empty():
		var tint := str(cfg.get("tint", ""))
		if tint == "":
			return
		palette = {"*": tint}
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
				continue
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
func _shared_variant_material(source: Material, name: String, colour: Color) -> Material:
	var key := "%s|%s|%s" % [str(_cfg.get("model", "")), name, colour.to_html()]
	if _variant_materials.has(key):
		return _variant_materials[key]
	var material: BaseMaterial3D = (source.duplicate() as BaseMaterial3D) \
		if source is BaseMaterial3D else StandardMaterial3D.new()
	material.albedo_color = material.albedo_color * colour
	if material.emission_enabled:
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
		var hex := str(acc.get("color", acc.get("colour", "#5a3d21")))
		part.set_surface_override_material(
			0, _shared_variant_material(StandardMaterial3D.new(), name, Color(hex)))


func _primitive_mesh(shape: String, size: float) -> PrimitiveMesh:
	match shape:
		"box":
			var box := BoxMesh.new()
			box.size = Vector3.ONE * size
			return box
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
