extends RefCounted

## EV6: the settlement's buildings, composed ONCE from Medieval Village
## MegaKit modules (docs/decisions/D24 — the one civilian architectural
## family) and reused as prefabs.
##
## Bible §12 is explicit: "Create prefabs/scenes from modules once, then
## reuse. Do not construct every building from loose pieces at runtime."
## The recipe for each building lives in data/config/building_prefabs.json
## and is assembled into a template Node3D exactly once per run; every
## placement gets a duplicate() of that template. The recipe is the design,
## written once — village.gd never sees a module, only a prefab name.
##
## Materials: the kit's glTF modules share one trim-texture family
## (MI_Plaster, MI_WoodTrim, MI_RoundTiles, MI_UnevenBrick, MI_RockTrim...).
## R9.4-remainder-3's requirement survives the kit swap: village.json must be
## able to lift a structure's roof the way a vegetation layer retints a leaf.
## `retint` maps a material name to a colour; the surface's material is
## duplicated and its albedo_color set (the albedo TEXTURE stays — the colour
## multiplies it), so one dark family never again needs a mesh swap to fix.

const MODULES_DIR := "res://assets/buildings/quaternius_medieval"
const CONFIG_PATH := "res://data/config/building_prefabs.json"

## VISUAL-CORRIDOR fix (2026-08-23): applied to EVERY prefab's own retint
## dict at template-build time (see `_build_template`'s call to
## `_apply_retint` below), not opt-in per recipe. `MI_RockTrim` ships with no
## `metallicFactor` in the kit's glTF export -- glTF's own spec default
## (1.0, full metal) fills the gap, the exact same missing-factor shape
## `MI_Plaster` had (this file's own top comment, and
## `build_material_finish.gd`'s BUILD-KIT-2 header, both independently found
## the same kit-export gap on a different material). A full-metal surface
## with no reflection probes (Compatibility renderer, realtime lighting
## only) just mirrors the sky, which is why the low RockTrim border skirt
## "every building sits on" (this file's own vocabulary comment above) reads
## as ice-blue chrome rather than stone -- confirmed by direct load
## (`Prop_ExteriorBorder_Straight1.gltf`: metallic=1.0, albedo (1,1,1,1)
## white) on the exact module the quarry_foundation ramp uses, the worst
## instance a blind critic named ("ramp slabs read literally as slabs of
## ice"). EV6-remainder-well-rocktrim-shadow already diagnosed and fixed
## this bug once, but only for the `well` recipe, which happens to carry its
## own `retint` block; every OTHER MI_RockTrim user (the workshop and every
## cottage's border skirt, quarry_foundation, ranger_station, mill, the
## farmhouse shell, the inn...) never got it, because `_apply_retint` only
## ever touched a recipe's own authored dict. `structure.stone_grey`
## (`data/config/palette.json`) is this project's already-authored warm-grey
## stone value -- reused here rather than inventing a new one, per that
## file's own job ("one source for materials... so they cannot drift
## apart"); the well keeps its own paler `#f0e2c4` (a deliberate, well-
## specific warm tone from its own three-round history), since a recipe's
## own retint entry for a material still wins over this baseline (see
## `_merge_baseline`).
const BASELINE_RETINT := {
	"MI_RockTrim": {"color": "#b4b1a6", "metallic": 0.0},
}

var _recipes: Dictionary = {}
var _templates: Dictionary = {}
## (material name, colour) -> tinted duplicate, shared across every surface
## that asks, so a retint costs one material per colour rather than one per
## mesh surface.
var _tinted: Dictionary = {}
## Where cached templates get parked, set by `set_template_holder`. Nothing
## renders through it (it stays hidden) -- it exists only so the template
## trees `_build_template` builds are real SceneTree members instead of
## orphan Nodes. An un-parented Node3D with mesh children still creates
## RenderingServer-side GPU buffers the moment a Mesh resource is touched,
## but nothing ever calls its destructor at engine shutdown if it was never
## added to the tree and never explicitly freed -- `_templates` intentionally
## keeps every template alive for the whole session, so "explicitly free it"
## was never the right fix. Confirmed by a real crash: the exported build's
## own RenderingServer teardown found hundreds of un-freed buffers or
## textures ("Buffer with GL ID of NNNN: leaked N bytes") from exactly this
## many orphan template trees, immediately followed by a heap-corrupting
## double free and a SIGABRT -- reproduced locally, absent on pre-EV6 main
## (0 leaked buffers there) and present with or without the farmhouse-shell
## follow-up (so this is EV6's own settlement rebuild, not a later addition).
var _holder: Node3D = null


func set_template_holder(holder: Node3D) -> void:
	_holder = holder


## EV6-crash-remainder: `_templates` are real Node3D trees, built once and
## kept only so `instantiate()` can `duplicate()` them again for a repeated
## prefab (three `fence_run` placements share one template) — but they are
## NEVER added to the SceneTree. Godot's own node-vs-Resource contract only
## auto-frees Nodes that are IN the tree; an unparented Node3D is a leak by
## definition, and every caller here is one: village.gd keeps its composer
## alive as a member for the session (so its templates leak until process
## exit), and grandpa_house.gd/road_gate.gd each build a LOCAL composer that
## goes out of scope — and leaks its template — the instant `build()` returns.
##
## That leak was invisible until a real exported binary's own shutdown proved
## it dangerous: the RenderingServer's exit-time cleanup force-frees every
## mesh/material RID it still has on the books (the "leaked ... bytes" wave
## in an export's run.log), and Godot's separate leftover-Object sweep THEN
## frees these still-alive, still-registered orphan template nodes and their
## MeshInstance3D children — releasing the very same RIDs a second time.
## `double free or corruption (!prev)` / SIGABRT is that second free landing
## on memory the RenderingServer already returned. The editor and every
## in-editor smoke test never reach this: they don't run a real GL driver
## through a real process exit the way `tools/verify_export.sh`'s exported
## binary does, so the race between the two cleanup passes never fires.
##
## The fix frees every cached template the moment THIS composer object is
## about to be freed — ordinary GDScript refcounting, well before the engine
## ever reaches its own end-of-process sweep. Freeing a template Node does
## NOT touch the meshes/materials still referenced by the DUPLICATES already
## placed in the world: those are independently-refcounted Resources, not
## owned exclusively by the template, so they stay alive exactly as long as
## a placed building still points at them.
func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	# `is_instance_valid()` must run BEFORE `is Node`, not after: `and` short-
	# circuits left-to-right, so the old `template is Node and is_instance_
	# valid(template)` order ran `is Node` on every template regardless of
	# validity. Godot's `is` operator needs the object's live class info to
	# answer that, which a freed instance no longer has — querying it throws
	# "Left operand of 'is' is a previously freed instance" instead of the
	# false a stale reference should quietly produce. `is_instance_valid()`
	# is the one call in this pair documented safe to run on a freed
	# reference, so it has to gate everything else.
	for template: Variant in _templates.values():
		if is_instance_valid(template) and template is Node:
			(template as Node).free()
	_templates.clear()


func load_recipes() -> bool:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("building_prefabs.json missing; no prefabs to place")
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("building_prefabs.json is not valid JSON")
		return false
	_recipes = (parsed as Dictionary).get("prefabs", {})
	return not _recipes.is_empty()


## The raw recipe for a prefab, or an empty Dictionary. Read-only: callers that
## need to know a prefab's own SHAPE -- `village.gd` asking whether a structure
## has a floor and how wide its modules run -- should ask the recipe rather than
## keep a second list of building sizes somewhere else.
func recipe(prefab_name: String) -> Dictionary:
	return _recipes.get(prefab_name, {})


func has_prefab(prefab_name: String) -> bool:
	return _recipes.has(prefab_name)


## The recipe's own collider list (local space), or [] when the placer should
## fall back to one combined-AABB box.
func colliders(prefab_name: String) -> Array:
	var recipe: Dictionary = _recipes.get(prefab_name, {})
	return recipe.get("colliders", [])


## R7.8. The recipe's own `door` dict — `leaf_module`, `at` (doorway centre,
## same local space as `colliders`), and optionally `width`/`height`/
## `open_yaw_deg` — or `{}` when the prefab has no player-openable door.
func door_spec(prefab_name: String) -> Dictionary:
	var recipe: Dictionary = _recipes.get(prefab_name, {})
	return recipe.get("door", {})


## R7.8. The child index of the door leaf module inside a placed duplicate of
## this prefab, or -1. `_build_template`/`instantiate` preserve the recipe's
## own module order 1:1 into scene-tree child order (glTF root node names
## vary with how each piece was exported, so an index into the SAME list the
## recipe already declares is the one lookup that cannot go stale with it).
func door_leaf_index(prefab_name: String) -> int:
	var spec := door_spec(prefab_name)
	var leaf_module := str(spec.get("leaf_module", ""))
	if leaf_module.is_empty():
		return -1
	var recipe: Dictionary = _recipes.get(prefab_name, {})
	var i := 0
	for entry: Variant in recipe.get("modules", []):
		if entry is Dictionary and str((entry as Dictionary).get("module", "")) == leaf_module:
			return i
		i += 1
	return -1


## R7.8. The recipe's own `room` dict for a generic interior template
## (`cottage_interior.gd`) — inner half-extents and door lane, read from the
## kit rather than chosen, the same way `shop_interior.gd`'s own constants
## were derived from cottage_a. `{}` when the prefab authors no room (the
## interior script then falls back to its own defaults).
func room_spec(prefab_name: String) -> Dictionary:
	var recipe: Dictionary = _recipes.get(prefab_name, {})
	return recipe.get("room", {})


## A ready-to-place duplicate of the prefab's template. Built on first
## request, cached after.
func instantiate(prefab_name: String) -> Node3D:
	if not _templates.has(prefab_name):
		var template := _build_template(prefab_name)
		if template == null:
			return null
		_templates[prefab_name] = template
	# `duplicate()` copies EVERY property of the template, `visible` included
	# — and `_build_template` deliberately hides the template so it never
	# renders at the origin while parked in `_holder`. Without this line every
	# placed copy inherits that hidden flag too: the whole settlement built,
	# collided and stood on the ground with a straight face, never drawing a
	# single pixel. Every caller wants a visible duplicate; nothing here ever
	# wants a hidden one back.
	var copy := (_templates[prefab_name] as Node3D).duplicate()
	copy.visible = true
	return copy


func _build_template(prefab_name: String) -> Node3D:
	var recipe: Dictionary = _recipes.get(prefab_name, {})
	if recipe.is_empty():
		push_error("unknown building prefab: %s" % prefab_name)
		return null
	var root := Node3D.new()
	root.name = prefab_name
	for entry: Variant in recipe.get("modules", []):
		if not entry is Dictionary:
			continue
		var spec := entry as Dictionary
		var module := str(spec.get("module", ""))
		var dir := str(spec.get("dir", MODULES_DIR))
		# OF4-rebuild: the castle kit (BG2) ships OBJ+MTL, not glTF -- the same
		# format the Furniture/Survival props already use directly as a bare
		# `Mesh` (grandpa_house.gd::_furnish). glTF stays the default lookup
		# since every other kit composed here is glTF; OBJ is a fallback, not
		# a replacement, so an existing recipe's behaviour is unchanged.
		var node: Node3D = null
		var gltf_path := "%s/%s.gltf" % [dir, module]
		var obj_path := "%s/%s.obj" % [dir, module]
		if ResourceLoader.exists(gltf_path):
			var scene: PackedScene = load(gltf_path)
			node = scene.instantiate() as Node3D
		elif ResourceLoader.exists(obj_path):
			var mesh: Mesh = load(obj_path)
			var mi := MeshInstance3D.new()
			mi.name = module
			mi.mesh = mesh
			node = mi
		else:
			push_error("prefab %s: module missing: %s (.gltf or .obj)" % [prefab_name, module])
			continue
		var at: Array = spec.get("at", [0.0, 0.0, 0.0])
		node.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
		# Euler YXZ (Godot's default rotation order): yaw applies first, then
		# pitch, then roll — so a module can be yawed into a vertical plane and
		# rolled around the world axis it now faces. EV6-remainder added
		# pitch/roll for the mill's water wheel: rim pieces are fence sections
		# yawed 90 into the y-z plane, then rolled to their rim angle. Plain
		# buildings keep using yaw_deg alone.
		node.rotation = Vector3(
			deg_to_rad(float(spec.get("pitch_deg", 0.0))),
			deg_to_rad(float(spec.get("yaw_deg", 0.0))),
			deg_to_rad(float(spec.get("roll_deg", 0.0)))
		)
		var s := float(spec.get("scale", 1.0))
		node.scale = Vector3.ONE * s
		root.add_child(node)
	_apply_retint(root, _merge_baseline(recipe.get("retint", {})))
	if _holder != null:
		root.visible = false
		_holder.add_child(root)
	return root


## `BASELINE_RETINT` underneath, the recipe's own `retint` block on top --
## a recipe that names the same material (only `well` does today, for
## `MI_RockTrim`) is authoring a deliberate choice and wins; every other
## recipe gets the baseline correction it was never asked to opt into.
## Applied once per prefab at template-build time (`_build_template` is the
## only caller), not per-instance -- `instantiate()`'s own `duplicate()`
## carries the corrected surface override forward for free.
func _merge_baseline(recipe_retint: Dictionary) -> Dictionary:
	var merged: Dictionary = BASELINE_RETINT.duplicate(true)
	for key in recipe_retint:
		merged[key] = recipe_retint[key]
	return merged


## Per-placement retint (village.json's own `retint` key) — applied to a
## duplicate, never to the cached template.
func apply_retint(node: Node3D, retint: Dictionary) -> void:
	_apply_retint(node, retint)


func _apply_retint(node: Node3D, retint: Dictionary) -> void:
	if retint.is_empty():
		return
	for mi: MeshInstance3D in _mesh_instances(node):
		for surface in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(surface)
			if mat == null or not mat is StandardMaterial3D:
				continue
			var mat_name := mat.resource_name
			if not retint.has(mat_name):
				continue
			# A retint value is either a colour string, or a dictionary when
			# the surface also needs to GLOW — window glass wants the warm
			# interior light grandpa_house.gd's own windows carry, because
			# under the Compatibility renderer an interior light does not
			# reliably reach an exterior pane (D01/D06). Emissive glass is
			# how every lit window in this project works.
			var spec: Variant = retint[mat_name]
			var colour: Color
			var emission := Color.BLACK
			var energy := 0.0
			var texture := ""
			var metallic := -1.0 ## -1 means "leave the imported value alone"
			if spec is Dictionary:
				var d := spec as Dictionary
				colour = Color(str(d.get("color", "#ffffff")))
				if d.has("emission"):
					emission = Color(str(d["emission"]))
					energy = float(d.get("energy", 0.85))
				# A texture SWAP, for the one case a multiply cannot reach:
				# the settlement's authored trees share the scattered trees'
				# raw leaf sheet, whose zero blue channel no tint can move —
				# vegetation.json swaps it for the pack's muted Leaves.png
				# and then tints, so the recipe does the same.
				texture = str(d.get("texture", ""))
				# A PBR property override, for the one case a colour multiply
				# cannot reach: MI_RockTrim imports with metallic=1.0 (a bare-
				# metal setting a stone surface never wants), which starves it
				# of diffuse ambient response — under the Compatibility
				# renderer's real-time-only lighting (no reflection probes),
				# a full-metal surface has nothing to reflect in shadow and
				# reads flat and cold next to a dielectric neighbour lit by
				# the same ambient. `EV6-remainder-well-rocktrim-shadow`.
				if d.has("metallic"):
					metallic = float(d["metallic"])
			else:
				colour = Color(str(spec))
			var key := "%s|%s|%s|%.2f|%s|%.2f" % [mat_name, colour.to_html(), emission.to_html(), energy, texture, metallic]
			if not _tinted.has(key):
				var dup := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_color = colour
				if energy > 0.0:
					dup.emission_enabled = true
					dup.emission = emission
					dup.emission_energy_multiplier = energy
				if texture != "" and ResourceLoader.exists(texture):
					dup.albedo_texture = load(texture)
				if metallic >= 0.0:
					dup.metallic = metallic
				_tinted[key] = dup
			mi.set_surface_override_material(surface, _tinted[key])


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found


## Combined AABB of every mesh under `node`, in `node`'s own space — the
## fallback collider and the grounding footprint. Same transform walk as
## props.gd: glTF meshes sit under importer-added transform nodes, so each
## mesh AABB is carried through its chain of local transforms.
func combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var has := false
	for mi in _mesh_instances(node):
		var xform := _relative_transform(mi, node)
		var aabb := xform * mi.mesh.get_aabb()
		result = result.merge(aabb) if has else aabb
		has = true
	return result


func _relative_transform(node: Node3D, ancestor: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var walk: Node = node
	while walk != null and walk != ancestor:
		if walk is Node3D:
			xform = (walk as Node3D).transform * xform
		walk = walk.get_parent()
	return xform
