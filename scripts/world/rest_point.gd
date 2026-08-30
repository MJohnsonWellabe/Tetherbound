extends Node3D

## An AUTHORED camp you can actually use.
##
## T4-REGIONS measured the defect this closes
## (`ralph/reports/REGION_AUDIT_2026-08-30.md`): `props.gd` places meshes and
## nothing else, so `trail_camp` (18 props, a bed, a lit bonfire, a bench and a
## stool), `ranger_camp` (a bed and an anvil) and `riverwatch_rest` (a bed, and
## the word "rest" in its own name) were scenery. The audit ranked it third
## across the whole chapter and was blunt about why it is worse than having no
## camps: five named, well-dressed sites teach the player to walk over and be
## refused, while the only real rest in the game is a portable buildable
## available anywhere.
##
## What this offers is deliberately the SAME OFFER the player-built camp makes,
## not a second, better one:
##
##   * **Rest until morning** -- `night_rest.gd`, the one shared definition,
##     which `camp.gd` now also calls. Same day advance, same trainer heal,
##     same completed creature-bed rests, same autosave.
##   * **Craft** -- the base recipe tier, the same `craft_panel.gd` the built
##     camp opens. Exit criterion H5: "Camp and home offer recovery, crafting,
##     food, storage, personalization."
##   * **a working creature bed**, where the camp already authored a bed prop.
##     This is the half that makes "recovery" mean something away from home:
##     `game_state.gd::_tick_creature_bed_recovery()` heals an occupant
##     gradually whether or not the player stands there, so an injured creature
##     left at the ranger camp is genuinely UNAVAILABLE and genuinely
##     recovering -- exit criterion H3's "injury creates real expedition
##     decisions", which cannot land while every bed in the wild is a mesh.
##
## SUPERSEDED PROSE, named rather than quietly overwritten. `riverwatch_rest`'s
## own `_why` in band3's props.json said "Deliberately NOT a healer or a second
## camp mechanic -- the game has exactly one rest structure (scripts/build/
## camp.gd) and this is not a second one", and `ranger_camp`'s said "Salvage,
## not shelter". Those were coherent decisions when rest lived in one buildable.
## They are what the audit measured as a FAIL against exit criterion E's "a
## sensible camp/recovery opportunity", and the coordinator directive that
## follows the audit reverses them. This is still not a SECOND rest mechanic:
## it is the SAME one, reached from the camps the world already advertises.
##
## Nothing here decides where a camp is or what it looks like. Sites, props and
## dressing stay in `data/config/bands/<band>/props.json`; this reads one
## optional `rest` block off a cluster and stands the offer up.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const NIGHT_REST := preload("res://scripts/world/night_rest.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const CRAFT_PANEL := preload("res://scripts/ui/craft_panel.gd")

## Reserved `build_index` range for authored camp beds.
##
## `creature_bed.gd` already reserves `-1` (UNASSIGNED) and `-2`
## (AUTHORED_STRONGHOLD_REST, the Hall's recovery point). A bed's index is what
## a resting creature stores in `rest_bed_index` and what `occupant_index()`
## matches on, so two beds sharing one index would show the same sleeping
## creature in both and let neither be filled twice.
##
## Indices are AUTHORED in props.json rather than assigned in cluster order on
## purpose: an index handed out by position would shift the moment a camp is
## added or reordered, and a save written before that shift would wake with its
## creature bound to a bed that has moved to another band. Explicit ids in data
## survive both. They must be <= this bound so they can never collide with a
## player's own beds, which are numbered from 0 upward by the build store.
const AUTHORED_BED_INDEX_CEILING := -10

var _spec: Dictionary = {}
var _craft_panel: CanvasLayer = null
var _bed: Node3D = null


## `spec` is one cluster's `rest` block. Positions are WORLD metres [x, z], the
## same convention every other key in props.json uses; ground height is sampled
## here, so an author never writes a Y.
func build(spec: Dictionary) -> void:
	_spec = spec

	var at: Array = spec.get("at", [])
	if at.size() < 2:
		push_error("rest block has no `at`; the camp offers nothing")
		return
	var x := float(at[0])
	var z := float(at[1])
	var ground := _ground_height(x, z)
	if is_nan(ground):
		push_error("no ground under rest point at %.0f, %.0f" % [x, z])
		return
	position = Vector3(x, ground, z)

	var label := str(spec.get("label", "Rest until morning"))
	var radius := float(spec.get("radius", 3.2))
	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	# Raised to roughly waist height for the same reason camp.gd raises its
	# own: interactable.gd draws its sight line from ITS position, and one
	# sitting on the ground is occluded by the first tussock between here and
	# the player.
	prompt.position = Vector3(0.0, 0.6, 0.0)
	prompt.call("configure", label, radius, true)
	prompt.connect("activated", _on_rest)
	add_child(prompt)

	# `craft` (optional, default true). The built camp offers crafting beside
	# its fire and so should a camp with a workbench, an anvil or a whetstone
	# standing in it -- which is every one of these. A site that should not
	# (a Team Tether posting, say) sets it false rather than being a different
	# kind of node.
	if bool(spec.get("craft", true)):
		var craft_at: Array = spec.get("craft_at", [])
		var craft_prompt: Node3D = INTERACTABLE.new()
		craft_prompt.name = "CraftInteractable"
		# Its own offset so the two prompts arbitrate cleanly rather than
		# landing on top of one another at distance zero -- interactable.gd's
		# `priority`/position pair, used exactly as camp.gd uses it.
		craft_prompt.position = (Vector3(float(craft_at[0]) - x, 0.6, float(craft_at[1]) - z)
			if craft_at.size() >= 2 else Vector3(1.6, 0.6, 0.0))
		craft_prompt.call("configure", str(spec.get("craft_label", "Craft")), radius, true)
		craft_prompt.connect("activated", _on_craft)
		add_child(craft_prompt)

	_build_creature_bed(spec.get("creature_bed", {}))


## The camp's own bed, made real.
##
## `build_real(false)`: the same argument the stronghold's recovery point
## passes, and for the same measured reason -- `build_real()`'s default sets
## the chapter's `creature_bed_built` objective flag, and a bed built with the
## world at boot would complete the tournament ladder's "Build a Creature Bed"
## rung before the player owns a hammer.
func _build_creature_bed(raw: Variant) -> void:
	if not raw is Dictionary or (raw as Dictionary).is_empty():
		return
	var spec := raw as Dictionary
	var at: Array = spec.get("at", [])
	if at.size() < 2:
		push_error("rest block's creature_bed has no `at`")
		return
	var index := int(spec.get("bed_index", 0))
	if index > AUTHORED_BED_INDEX_CEILING:
		push_error("authored camp bed index %d is not in the reserved range (<= %d); refusing to place it where it could collide with a player's own bed"
			% [index, AUTHORED_BED_INDEX_CEILING])
		return
	var x := float(at[0])
	var z := float(at[1])
	var ground := _ground_height(x, z)
	if is_nan(ground):
		push_error("no ground under authored camp bed at %.0f, %.0f" % [x, z])
		return
	_bed = CREATURE_BED.new()
	_bed.name = "CampCreatureBed"
	_bed.position = Vector3(x, ground, z)
	_bed.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	add_child(_bed)
	_bed.call("build_real", false)
	_bed.call("set_build_index", index)


func _on_rest() -> void:
	NIGHT_REST.rest(self)


## Built on the first activation, not up front -- most camps are walked past,
## and most of the ones that are used are used for rest. Same reasoning
## camp.gd's own craft prompt gives.
func _on_craft() -> void:
	if _craft_panel == null or not is_instance_valid(_craft_panel):
		_craft_panel = CRAFT_PANEL.new()
		get_tree().root.add_child(_craft_panel)
	_craft_panel.call("open")


## Walks up for whatever owns the terrain, exactly like `props.gd` does -- this
## node is a child of a props cluster group, so the world is two levels up, and
## a rest point placed inside the Warrens' own props instance would find the
## cave floor instead.
func _ground_height(x: float, z: float) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", x, z))
		node = node.get_parent()
	return NAN
