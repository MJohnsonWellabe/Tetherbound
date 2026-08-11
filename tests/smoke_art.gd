extends SceneTree

## Does the art that is supposed to be in the game actually load, at the size
## the game thinks it is?
##
##   godot --headless --path . --script tests/smoke_art.gd
##
## Art has no unit tests; whether it is any good is a human's call from rendered
## frames. But whether it LOADED, whether it is the size its collider claims,
## and whether it silently fell back to a capsule are all mechanical, and all
## invisible in a passing combat test — a fight works perfectly against an
## invisible opponent.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")

const SETTLE_FRAMES := 300
## How far a rendered model may sit under the collider that represents it.
##
## Was 0.35m, which is wide enough to hide a real bug and did. `pal_body._fit()`
## clamps a model's scale by its footprint, and a long quadruped tripped that
## clamp and rendered visibly shorter than its declared height while a compact
## creature beside it got its full size — so the largest creature in the game
## read as the smallest. The owner spotted it in a screenshot; this test did not,
## because a third of a metre of slack covered it.
##
## 0.08m is tight enough that any silent rescale fails here. A creature that
## genuinely cannot meet its height needs `footprint_allowance` raising in data,
## which is a decision somebody makes rather than a clamp applying quietly.
const HEIGHT_TOLERANCE := 0.08

## ...but only DOWNWARDS. Above the collider, a creature gets much more room.
##
## `_fit()` scales a model by its REST bounds, and this test measures it after
## three hundred frames of its idle clip — by which point an ear, a tail or a
## raised paw is legitimately above where the rest pose put it. A wolf measured
## 1.57m against a 1.45m collider for exactly that reason, and it was correct.
##
## The failure this test exists to catch is the opposite sign: the footprint
## clamp quietly scaling a creature DOWN so the art no longer fills the collider
## that gameplay reaches with. Being asymmetric keeps that catch at 8cm while
## letting an animation breathe.
const HEIGHT_OVERSHOOT := 0.30

var _failures: Array[String] = []
var _world: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_every_species_has_art()
	_the_creatures_in_the_world_loaded_their_models()
	_the_trainer_has_a_model_and_animations()
	_every_human_fits_at_its_declared_height()
	_the_villagers_still_tint_the_way_r7_2_shipped()
	_the_npc_variant_system_differentiates_independently()
	_the_team_tether_ranks_read_as_distinct()
	_the_meadow_was_dressed()
	_vegetation_kept_its_lod_chain()
	_report()


## Species data must name a model, and the model must exist. A typo here shows
## up as a capsule in a screenshot and nowhere else.
func _every_species_has_art() -> void:
	for id: String in SPECIES.table().keys():
		var look: Dictionary = SPECIES.placeholder(id)
		var path := str(look.get("model", ""))
		if path == "":
			_fail("species '%s' names no model" % id)
			continue
		if not ResourceLoader.exists(path):
			_fail("species '%s' names a model that does not exist: %s" % [id, path])


## The creatures actually standing in the world, checked as they are rendered
## rather than as they are configured.
func _the_creatures_in_the_world_loaded_their_models() -> void:
	var director: Node = _world.get_node_or_null(^"EncounterDirector")
	if director == null:
		_fail("no encounter director; no creatures to check")
		return

	var bodies: Array[Node3D] = []
	for wild in (director.call("wild_pals") as Array):
		bodies.append(wild as Node3D)
	var ally: Node3D = director.call("ally_body") as Node3D
	if ally != null:
		bodies.append(ally)
	if bodies.is_empty():
		_fail("no creature bodies were spawned at all")
		return

	for body in bodies:
		var id := str(body.get("species_id"))
		if not bool(body.call("has_model")):
			_fail("'%s' fell back to the placeholder capsule; its model did not load" % id)
			continue

		# Fitted, not assumed. The three shipped models arrived at 263, 94 and
		# 3.8 units tall with two of the three centred on their origin rather
		# than standing on it, so "it loaded" and "it is the right size" are
		# genuinely separate questions.
		var wanted := float(body.call("body_height"))
		var actual := _rendered_height(body.call("model_pivot") as Node3D)
		if actual <= 0.0:
			_fail("'%s' has a model with no measurable size" % id)
		elif actual < wanted - HEIGHT_TOLERANCE:
			_fail("'%s' renders only %.2fm tall against a %.2fm collider. " % [id, actual, wanted] +
				"Something scaled it DOWN — check the footprint clamp in pal_body._fit().")
		elif actual > wanted + HEIGHT_OVERSHOOT:
			_fail("'%s' renders %.2fm tall against a %.2fm collider; that is more than an " % [
				id, actual, wanted
			] + "animation should add, so the model is not fitted to its gameplay size.")
		else:
			print("  %-16s model %.2fm, collider %.2fm" % [id, actual, wanted])
		_the_creature_has_the_clips_it_claims(body, id)


## Every clip a species names must exist on its model, under that exact name.
##
## Clip names are per-pack — the shipped creatures use `Armature|Frog_Attack`
## and `Armature|Triceratops_Run` — so a rename in data or a swapped model
## silently produces a creature that never animates. Nothing that reads game
## state can see that: the fight resolves perfectly against a creature frozen
## mid-pose.
func _the_creature_has_the_clips_it_claims(body: Node3D, id: String) -> void:
	var clips: Dictionary = SPECIES.placeholder(id).get("animations", {})
	if clips.is_empty():
		_fail("'%s' declares no animations; it will stand rigid through every fight" % id)
		return

	var anim := _find_animation_player(body)
	if anim == null:
		_fail("'%s' has no AnimationPlayer despite declaring %d clips" % [id, clips.size()])
		return

	for role: String in clips.keys():
		var clip := str(clips[role])
		if not anim.has_animation(clip):
			_fail("'%s' names a '%s' clip called '%s', which its model does not have" % [id, role, clip])

	# The four combat actually drives. A creature with no attack clip swings
	# invisibly, which reads as the hit not happening.
	for required in ["idle", "attack", "faint"]:
		if not clips.has(required):
			_fail("'%s' has no '%s' clip; combat drives that one" % [id, required])


func _the_trainer_has_a_model_and_animations() -> void:
	var model: Node3D = _world.get_node_or_null(^"Player/Model") as Node3D
	if model == null:
		_fail("the player has no Model node")
		return

	var anim := _find_animation_player(model)
	if anim == null:
		_fail("the trainer has no AnimationPlayer; it will stand rigid in every frame")
		return

	# Every clip the config asks for has to exist under the name it asks for.
	# A mistyped clip name is a trainer frozen in a T-pose, which no test that
	# reads state can see.
	var cfg: Dictionary = _art_config().get("trainer", {}).get("clips", {})
	for role: String in cfg.keys():
		var clip := str(cfg[role])
		if not anim.has_animation(clip):
			_fail("the trainer's '%s' clip is named '%s', which the model does not have" % [role, clip])

	# And he has to be the SIZE the config asks for — measured in RENDER space.
	#
	# This check has been wrong twice, in opposite directions. It did not exist
	# when the owner first played a build with an enormous trainer; then it
	# measured `global_transform × get_aabb()`, which for a SKINNED mesh walks
	# a node chain the renderer never uses — the humans carry their real scale
	# inside the skin (inverse binds ×100, Armature ×0.01), so the AABB read
	# 1.80m while the skeleton the GPU actually follows was 100× that, and the
	# owner's second playtest was ALSO full of boots while this test passed.
	# `render_bounds.gd` composes skeleton chain × collapsed skin, which is the
	# transform the renderer applies at rest pose.
	var wanted := float(_art_config().get("trainer", {}).get("height", 1.8))
	var box: AABB = RENDER_BOUNDS.measure(model)
	if box.size.y <= 0.0001:
		_fail("the trainer has no visible mesh; he is not on screen at all")
	elif absf(box.size.y - wanted) > 0.25:
		_fail("the trainer renders %.2fm tall but data/config/art.json asks for %.2fm" % [
			box.size.y, wanted])
	else:
		print("  trainer          model %.2fm, configured %.2fm, %d clips" % [
			box.size.y, wanted, anim.get_animation_list().size()])


## Every human in art.json, built standalone and measured as the renderer will
## draw it — plus the fit-factor tripwire.
##
## The playground scene only contains the trainer (Grandpa spawns later, the
## Warden not at all), so the in-scene check above cannot cover them. Building
## each config key directly covers all three, and asserting the fit factor
## stays near ×1 catches the whole class of bug where a measurement crosses an
## armature compensation and "corrects" a model that was already right: the
## factor that comes out of that mistake is ×100, never ×1.2.
func _every_human_fits_at_its_declared_height() -> void:
	for key in ["trainer", "grandpa", "warden"]:
		var declared := float(_art_config().get(key, {}).get("height", 0.0))
		if declared <= 0.0:
			_fail("art.json's '%s' block declares no height" % key)
			continue
		var holder := Node3D.new()
		holder.set_script(CHARACTER_MODEL)
		root.add_child(holder)
		if not bool(holder.call("build", key)):
			_fail("'%s' failed to build from art.json" % key)
			holder.queue_free()
			continue
		var art: Node3D = null
		for child in holder.get_children():
			if child is Node3D and (child as Node3D).visible:
				art = child
		if art == null:
			_fail("'%s' built but has no visible art" % key)
			holder.queue_free()
			continue
		var rendered: float = (RENDER_BOUNDS.measure(art) as AABB).size.y * art.scale.y
		if absf(rendered - declared) > 0.1:
			_fail("'%s' renders %.2fm against a declared %.2fm" % [key, rendered, declared])
		elif art.scale.y > 10.0 or art.scale.y < 0.1:
			_fail("'%s' needed a x%.1f fit correction; a rigged human should need ~x1. " % [
				key, art.scale.y
			] + "A factor like x100 means the measurement crossed the armature scale again.")
		else:
			print("  %-16s human %.2fm, declared %.2fm, fit x%.2f" % [
				key, rendered, declared, art.scale.y])
		holder.queue_free()


## NP1 replaced the flat `_apply_tint` multiply with `_apply_palette`, which
## reads `tint` as a legacy `{"*": tint}` palette entry when no `palette` key
## is present. R7.2's three villagers still carry only `tint` — this is the
## regression guard that the translation actually keeps producing a coloured
## body rather than silently doing nothing now that the field is read
## differently.
func _the_villagers_still_tint_the_way_r7_2_shipped() -> void:
	for key in ["villager_farmer", "villager_keeper", "villager_smith"]:
		var cfg: Dictionary = _art_config().get(key, {})
		var tint := str(cfg.get("tint", ""))
		if tint == "":
			_fail("'%s' has lost its R7.2 tint entry" % key)
			continue
		var holder := Node3D.new()
		holder.set_script(CHARACTER_MODEL)
		root.add_child(holder)
		if not bool(holder.call("build", key)):
			_fail("'%s' failed to build from art.json" % key)
			holder.queue_free()
			continue
		var material: Material = holder.call("body_material")
		if material == null or not material is BaseMaterial3D:
			_fail("'%s' built with no material to check its tint against" % key)
		else:
			var albedo: Color = (material as BaseMaterial3D).albedo_color
			# The exact colour depends on the source texture's own albedo, which
			# this test cannot know without loading it — but a tint that did
			# nothing leaves an untouched StandardMaterial3D default (flat white,
			# 1,1,1), which no villager's rustier/greener/bluer wardrobe should be.
			if albedo.is_equal_approx(Color(1, 1, 1)):
				_fail("'%s' rendered with an untinted default material; the palette " % key +
					"translation of its legacy 'tint' may not have run")
			else:
				print("  %-16s tint '%s' -> albedo %s" % [key, tint, albedo])
		holder.queue_free()


## NP1's own "done when": two NPCs built from the SAME base model differ in
## outfit colour (`palette`), hair and visible accessories independently of
## one another. The hair/accessory shapes are placeholder primitives — no
## rig ships separable geometry for either yet (see `_apply_hair`'s own
## comment) — so this checks the DATA-driven mechanism, not a look.
func _the_npc_variant_system_differentiates_independently() -> void:
	var base_model := str(_art_config().get("trainer", {}).get("model", ""))
	if base_model == "":
		_fail("no trainer model configured; cannot exercise the NPC variant system")
		return

	var variant_a := {
		"model": base_model, "height": 1.8,
		"palette": {"Material_1": "#c0392b"},
		"hair": {"visible": true, "color": "#111111"},
		"accessories": [{"name": "satchel", "visible": true, "color": "#7a5230"}],
	}
	var variant_b := {
		"model": base_model, "height": 1.8,
		"palette": {"Material_1": "#2e7d32"},
		"hair": {"visible": false},
		"accessories": [{"name": "satchel", "visible": false}],
	}

	var a := _build_from_config(variant_a)
	var b := _build_from_config(variant_b)
	if a == null or b == null:
		_fail("NP1 variant system: one of the two test builds produced no art")
		if a != null:
			a.queue_free()
		if b != null:
			b.queue_free()
		return

	var material_a: Variant = a.call("body_material")
	var material_b: Variant = b.call("body_material")
	if material_a == null or material_b == null:
		_fail("NP1 variant system: no body material on one of the two test builds")
	elif (material_a as BaseMaterial3D).albedo_color.is_equal_approx(
		(material_b as BaseMaterial3D).albedo_color
	):
		_fail("NP1 variant system: two different palette entries produced the same outfit colour")

	if a.call("find_part", "hair") == null:
		_fail("NP1 variant system: hair.visible=true did not attach a hair part")
	if b.call("find_part", "hair") != null:
		_fail("NP1 variant system: hair.visible=false attached a hair part anyway")

	if a.call("find_part", "accessory_satchel") == null:
		_fail("NP1 variant system: an accessory with visible=true did not attach")
	if b.call("find_part", "accessory_satchel") != null:
		_fail("NP1 variant system: an accessory with visible=false attached anyway")

	print("  npc variant      palette, hair and accessories differ independently")
	a.queue_free()
	b.queue_free()


## `NP2`: grunt/officer/captain/warden each reuse the Warden's rig through
## `npc_ranks.gd`. A blind visual pass rejected a first version that used only
## the body's own palette (`character_model.gd`'s single fused material means
## that can only ever shift brightness) — it read as "a lighting gradient, not
## a rank system." The badge NP1's accessory mechanism attaches is the real
## rank marker now, so this checks the badge attaches with a distinct colour
## per rank, not just the secondary body tint.
func _the_team_tether_ranks_read_as_distinct() -> void:
	var ranks: Array = NPC_RANKS.rank_ids()
	if ranks.is_empty():
		_fail("no Team Tether ranks configured; data/config/npc_ranks.json is empty or missing")
		return

	var seen_badges: Dictionary = {}
	var seen_bodies: Dictionary = {}
	for rank: String in ranks:
		var cfg: Dictionary = NPC_RANKS.config_for(rank)
		if cfg.is_empty():
			_fail("'%s' produced no config; the Warden base or the rank's own entry is missing" % rank)
			continue

		var holder := _build_from_config(cfg)
		if holder == null:
			_fail("'%s' failed to build from its rank config" % rank)
			continue

		var badge: Variant = holder.call("find_part", "accessory_badge")
		if badge == null:
			_fail("'%s' has no rank badge attached" % rank)
		else:
			var badge_material: Material = (badge as MeshInstance3D).get_active_material(0)
			if badge_material == null or not badge_material is BaseMaterial3D:
				_fail("'%s' badge has no material to read its colour from" % rank)
			else:
				var badge_colour: Color = (badge_material as BaseMaterial3D).albedo_color
				for other_rank: String in seen_badges:
					if badge_colour.is_equal_approx(seen_badges[other_rank]):
						_fail("'%s' and '%s' badges are the same colour; ranks must read apart" % [rank, other_rank])
				seen_badges[rank] = badge_colour
				print("  rank %-10s badge -> %s" % [rank, badge_colour])

		# Only grunt/officer/captain declare a body palette; the Warden's own
		# untinted painted texture is correct by design and asserting "not
		# default white" against it would be a false failure.
		if cfg.has("palette"):
			var material: Variant = holder.call("body_material")
			if material == null or not material is BaseMaterial3D:
				_fail("'%s' built with no body material to check its tint against" % rank)
			else:
				var albedo: Color = (material as BaseMaterial3D).albedo_color
				if albedo.is_equal_approx(Color(1, 1, 1)):
					_fail("'%s' rendered with an untinted default body material; its rank palette did not apply" % rank)
				for other_rank: String in seen_bodies:
					if albedo.is_equal_approx(seen_bodies[other_rank]):
						_fail("'%s' and '%s' bodies are the same colour" % [rank, other_rank])
				seen_bodies[rank] = albedo

		holder.queue_free()


func _build_from_config(cfg: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.set_script(CHARACTER_MODEL)
	root.add_child(holder)
	if not bool(holder.call("build_from_config", cfg)):
		holder.queue_free()
		return null
	return holder


func _the_meadow_was_dressed() -> void:
	var vegetation: Node = _world.get_node_or_null(^"Vegetation")
	if vegetation == null:
		_fail("no vegetation node; the meadow is bare")
		return
	var stats: Dictionary = vegetation.call("stats")
	var instances := int(stats.get("instances", 0))
	var batches := int(stats.get("batches", 0))
	print("  vegetation: %d props in %d batches" % [instances, batches])

	if instances <= 0:
		_fail("the scatter placed nothing; the meadow is bare")
		return
	# Instancing is not an optimisation here, it is the only way this layer can
	# exist on a handheld. One draw call per prop would be thousands.
	if batches > 0 and instances / batches < 20:
		_fail("%d props across %d batches; the scatter is not actually instancing" % [instances, batches])

	# Every layer in the config has to be present in the world. A layer that
	# silently placed nothing looks exactly like a layer nobody wrote.
	var drawn := {}
	for child in vegetation.get_children():
		drawn[child.name] = true
	for layer: String in RULES.config().get("layers", {}).keys():
		if layer.begins_with("_"):
			continue
		var models: Array = RULES.config()["layers"][layer].get("models", [])
		var any := false
		for entry: Variant in models:
			if drawn.has(str(entry).get_file().get_basename()):
				any = true
				break
		if not any:
			_fail("layer '%s' has no props in the world" % layer)


## SA1-lod: vegetation.gd::_retint() used to rebuild every scattered mesh from
## surface_get_arrays() alone, which only round-trips the base LOD0 geometry
## and silently dropped the importer's LOD chain and shadow mesh -- invisible
## in a screenshot, since LOD0 still looks correct up close. Reads the LOD
## chain back off a RETINTED instance actually standing in the world and
## compares it to the un-retinted source file, so a future regression that
## reintroduces the rebuild-from-arrays pattern fails here instead of shipping
## as a silent bandwidth cliff.
func _vegetation_kept_its_lod_chain() -> void:
	var vegetation: Node = _world.get_node_or_null(^"Vegetation")
	if vegetation == null:
		return  # already failed in _the_meadow_was_dressed()

	# CommonTree_1 is scattered by data/config/vegetation.json and its source
	# .gltf carries a real multi-level LOD chain on both surfaces (bark, leaves)
	# from meshes/generate_lods=true at import -- dense enough that a
	# regression back to LOD0-only is not a rounding difference.
	const SOURCE := "res://assets/environment/stylized_nature/CommonTree_1.gltf"
	var source_mesh := _first_mesh(SOURCE)
	if source_mesh == null:
		_fail("SA1-lod check: could not load the source mesh %s directly" % SOURCE)
		return
	var source_lods := _lod_level_counts(source_mesh)
	if source_lods.is_empty() or source_lods.max() <= 0:
		_fail("SA1-lod check: %s has no LOD levels to begin with; pick a different source model" % SOURCE)
		return

	var node: MultiMeshInstance3D = null
	for child in vegetation.get_children():
		if child is MultiMeshInstance3D and child.name == "CommonTree_1":
			node = child as MultiMeshInstance3D
			break
	if node == null:
		_fail("SA1-lod check: CommonTree_1 was not scattered into the world; cannot verify its LOD chain")
		return

	var retinted := node.multimesh.mesh as ArrayMesh
	if retinted == null:
		_fail("'%s' scatter mesh is not an ArrayMesh" % node.name)
		return
	if retinted.shadow_mesh == null:
		_fail("'%s' lost its shadow mesh when retinted" % node.name)

	var retinted_lods := _lod_level_counts(retinted)
	if retinted_lods != source_lods:
		_fail("'%s' retinted LOD chain is %s, source is %s -- retinting is discarding LOD levels again" % [
			node.name, retinted_lods, source_lods
		])
	else:
		print("  vegetation LOD   %s survives retint: %s" % [node.name, retinted_lods])


## The first mesh found in a freshly loaded, standalone instance of `path` --
## NOT the one drawn in the world, so it carries the importer's original LOD
## chain untouched by any layer's retint.
func _first_mesh(path: String) -> ArrayMesh:
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var scene: Node = packed.instantiate()
	var meshes := _mesh_instances(scene)
	var result: ArrayMesh = null
	if not meshes.is_empty():
		result = meshes[0].mesh as ArrayMesh
	scene.queue_free()
	return result


## ArrayMesh has no public getter for a surface's LOD dictionary -- only the
## internal `_surfaces` storage property (Array[Dictionary], one entry per
## surface, `lods` key present when the importer generated levels), which is
## exactly what Resource.duplicate() copies through and what vegetation.gd's
## fix relies on. Reading it back here is how "the LOD data" gets checked
## mechanically instead of by eye, per this task's own acceptance criteria.
func _lod_level_counts(mesh: ArrayMesh) -> Array:
	var counts: Array = []
	var surfaces: Array = mesh.get("_surfaces")
	for entry: Variant in surfaces:
		var d: Dictionary = entry
		var lods: Variant = d.get("lods", {})
		counts.append(lods.size() if (lods is Dictionary or lods is Array) else 0)
	return counts


func _rendered_height(node: Node3D) -> float:
	if node == null:
		return 0.0
	# Render-space, same instrument as production's fit. `node` is the model
	# PIVOT — the fitted art hangs under it, so the chain measure already
	# carries the fit scale.
	var box: AABB = RENDER_BOUNDS.measure(node)
	return box.size.y


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null and node.visible:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _art_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/art.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("art: OK — models loaded, sized to their colliders, and the meadow is dressed.")
		quit(0)
		return
	for line in _failures:
		print("art FAIL: %s" % line)
	quit(1)
