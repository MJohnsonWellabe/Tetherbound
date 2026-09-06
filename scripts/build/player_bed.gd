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
const CAMP_FILL_LIGHT := preload("res://scripts/world/camp_fill_light.gd")
const NIGHT_REST := preload("res://scripts/world/night_rest.gd")

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

## The fade timing, kept here because `tools/gate_f/probe_rest_cycle_e2e.gd`
## and `tests/helpers/gate_b_tail_segment.gd` both document their waits against
## "player_bed.gd's own fade". The fade itself is `night_rest.gd`'s now, and
## this is the same 1.2 s it uses -- if one moves, move both.
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
	CAMP_FILL_LIGHT.attach(self, 0.7)

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


## Rest: fade out, new day, everyone healed, fade in.
##
## The fade and the night itself both live in `night_rest.gd` now. They used to
## be copied out here, and the copy had drifted: it wrote
## `player_slept_at_home` through the MERGED progression view rather than the
## sleeper's own store, and it called `save_game()` directly rather than going
## through D100's `autosave_here()` routing -- so on a client the bedroll would
## have written the host's world. Two definitions of "what a night costs" is
## exactly the defect `night_rest.gd` was created to end; this file simply had
## never been moved onto it.
##
## Going through `NIGHT_REST.rest()` is also what gets this bedroll D105's
## sleep vote for free: solo it is byte-for-byte the same fade and the same
## night, and with a second player in the session it casts a vote instead.
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
	#
	# Checked HERE and not in `night_rest.gd` because it is this buildable's
	# rule: an authored trail camp and Grandpa's bed have no tent and are not
	# supposed to need one.
	if not _tent_overhead():
		game.call("push_world_message", "You need a tent over the bedroll to rest here")
		AUDIO_CUES.play(&"ui_error")
		return

	NIGHT_REST.rest(self)


## Kept as the direct-call seam `tests/smoke_gateb_flags.gd` drives (it calls
## this method by name to pass a night without the interact prompt), delegating
## to the one shared definition rather than carrying a second copy of it.
func _pass_the_night(game: Node) -> void:
	NIGHT_REST.pass_the_night(self, game)
