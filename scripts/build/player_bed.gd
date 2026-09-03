extends Node3D

## OWNER-0902-CAMP-SPLIT: the player's own bedroll, split out of camp.gd's
## bundled camp into its own independently placeable buildable
## (`data/items/buildables.json`'s `bedroll`) -- carries the "Rest until
## morning" interaction that used to sit beside camp.gd's fire. Named
## `player_bed.gd` rather than `camp_bed.gd`/`bed.gd` to keep it unmistakably
## distinct from `scripts/build/creature_bed.gd`, an unrelated buildable
## (`creature_bed`) for a creature's own care, not the trainer's.
##
## Resting fades the world out, advances `Game.day`, heals the party and the
## trainer, and fades back in -- GAME_DESIGN.md's early tutorial ends exactly
## here: "build campfire + bed and rest with starter." That beat now needs
## the bedroll placed specifically (not the tent or campfire), which is why
## the rest logic moved here rather than staying on whichever piece the old
## bundle happened to attach it to.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const CAMP_TENT := preload("res://scripts/build/camp_tent.gd")
const AUDIO_CUES := preload("res://scripts/ui/audio_cues.gd")

## CAMP-SHELTER-0903, owner playtest 2026-09-03 item 7: "You should have to
## have the tent over your head to sleep." Duplicated from
## `build_placer.gd::PLACED_GROUP`/`BUILDING_ID_META` rather than preloading
## that script from here -- `build_placer.gd` already preloads THIS file to
## spawn a placed bedroll, and a two-way preload cycle between them is worth
## avoiding for two string literals that are load-bearing nowhere else.
const PLACED_GROUP := "placed_building"
const BUILDING_ID_META := "building_id"

## The camp set's own bed -- `docs/specs/ASSET_LEDGER.md`'s generated_camp asset,
## already used at ground level for the trainer's own sleeping spot before
## this split (and, unscaled, distinct from `creature_bed.gd`'s squashed pad
## composition of the SAME mesh for a creature's own rest).
const MESH_PATH := "res://assets/props/generated_camp/camp_bed.glb"
## T1-CAMP, carried over from camp.gd: measured (tools/_probe_t1_camp.gd) --
## camp_bed.glb's own local origin sits 0.215m above its own geometric base
## (the same glTF-export quirk `creature_bed.gd`'s own `BED_SINK_LIFT`
## compensates for on its scaled copy of this mesh). Unscaled here, so the
## raw offset applies directly.
const BED_SINK := 0.215

const FADE_SECONDS := 1.2

var _piece: Node3D = null


func build_ghost() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.position.y = BED_SINK
	_piece.call("build_ghost", MESH_PATH)


func build_real() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.position.y = BED_SINK
	_piece.call("build_real", MESH_PATH)

	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(0.0, 0.5, 1.0)
	prompt.call("configure", "Rest until morning", 2.6, true)
	prompt.connect("activated", _on_rest)
	add_child(prompt)


func tint_ghost(ok: bool) -> void:
	if _piece != null and is_instance_valid(_piece):
		_piece.call("tint_ghost", ok)


## CAMP-SHELTER-0903. True if any placed, non-removed tent's roof (per
## `camp_tent.gd::contains_point`) currently covers this bedroll's own
## position. Reads the live scene tree rather than `GameState.placed_buildings`
## directly -- this node IS one of the placed pieces that tree already tracks,
## and a tent standing beside it is another, so walking `PLACED_GROUP` finds
## both without this file needing to know how `GameState` stores either.
func _tent_overhead() -> bool:
	for node: Node in get_tree().get_nodes_in_group(PLACED_GROUP):
		if str(node.get_meta(BUILDING_ID_META, "")) != "tent":
			continue
		var tent := node as Node3D
		if tent == null or not is_instance_valid(tent):
			continue
		if CAMP_TENT.contains_point(tent.global_position, rad_to_deg(tent.rotation.y), global_position):
			return true
	return false


## Rest: fade out, new day, everyone healed, fade in. The fade is the same
## two-node canvas the opening's wake uses, built here because a bedroll can
## exist in a world with no sequence director.
func _on_rest() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the night cannot pass")
		return

	# CAMP-SHELTER-0903: a live footprint check against whatever tent is
	# CURRENTLY standing, not a flag recorded at placement time -- so a
	# bedroll a tent was later dismantled from stops sleeping, and (the flip
	# side, for save compatibility) a bedroll placed before this rule existed
	# starts working the moment a tent goes up over it, with no migration.
	if not _tent_overhead():
		game.call("push_world_message", "You need a tent over the bedroll to rest here")
		AUDIO_CUES.play(&"ui_error")
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
	# bedroll in a scene with no day/night setup (a test scene, say) still
	# rests fine with nothing to reset.
	for look: Node in get_tree().get_nodes_in_group("day_cycle"):
		if look.has_method("reset_to_morning"):
			look.call("reset_to_morning")
	# R3.1. "Frequent autosave" — resting is the natural checkpoint this game
	# already asks the player to return to, the same precedent survival games
	# with a sleep beat use for it.
	game.call("save_game", int(game.call("autosave_slot")))
	print("[player_bed] rested; day %d" % day)
