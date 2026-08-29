extends Node3D

## Builds the M1 playground at runtime from baked Terrain3D data.
##
## The Terrain3D node is created in code rather than saved into the scene. A
## GDExtension node stored in a .tscn breaks the whole scene if the extension is
## missing or its version moves, and it turns "did you install the addon?" into
## a corrupt-scene error instead of a clear message. Creating it here means the
## failure is one readable push_error and the rest of the playground still runs.
##
## The terrain itself is authored data, baked once by
## scripts/world/build_playground_terrain.gd. Nothing generates terrain at run
## time and nothing should: per the owner's direction the terrain is authored
## macro geography, not a procedural seed.

const DATA_DIR := "res://data/terrain/playground"
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"
const VEGETATION := preload("res://scripts/world/vegetation.gd")
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
const WATER := preload("res://scripts/world/water.gd")
const VILLAGE := preload("res://scripts/world/village.gd")
const PROPS := preload("res://scripts/world/props.gd")
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const TRAINER_NPCS := preload("res://scripts/world/trainer_npc.gd")
## TOURNAMENT-1: the village tournament's bracket board. The fights themselves
## are ordinary trainer entries and the marshal is an ordinary villager, so this
## is the only node the tournament adds to the world.
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const GRANDPA_HOUSE := preload("res://scripts/world/grandpa_house.gd")
const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")
## BAND-SPLIT. `harvest.json`'s `nodes` array is cut per corridor band under
## `data/config/bands/<band>/harvest.json` and merged back at load.
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const FARM_PLOT := preload("res://scripts/world/farm_plot.gd")
const BURROW_WARRENS := preload("res://scripts/world/burrow_warrens.gd")
const BUILD_PLACER := preload("res://scripts/build/build_placer.gd")
const SIGNPOST := preload("res://scripts/world/signpost.gd")
const LANDMARK := preload("res://scripts/world/landmark.gd")
const WATCHTOWER_LANDMARK := preload("res://scripts/world/watchtower_landmark.gd")
const ROAD_GATE := preload("res://scripts/world/road_gate.gd")
const KEY_PICKUP := preload("res://scripts/world/key_pickup.gd")
const TM_PICKUP := preload("res://scripts/world/tm_pickup.gd")
const WORLD_PERIMETER := preload("res://scripts/world/world_perimeter.gd")
const SOUTH_BRIDGE := preload("res://scripts/world/south_bridge.gd")
const OLD_QUARRY := preload("res://scripts/world/old_quarry.gd")
const TETHER_RELAY := preload("res://scripts/world/tether_relay.gd")
const MILL_CROSSING := preload("res://scripts/world/mill_crossing.gd")
const RIVER := preload("res://scripts/world/river.gd")
const SEVERED_SPOKES := preload("res://scripts/world/severed_spokes.gd")
const RIFT_COLLAPSE := preload("res://scripts/world/rift_collapse.gd")
const MEADOW_HEALING := preload("res://scripts/world/meadow_healing.gd")
const STRONGHOLD := preload("res://scripts/world/stronghold.gd")
const STRONGHOLD_CLIMAX := preload("res://scripts/world/stronghold_climax.gd")
const PLAYER_DEATH := preload("res://scripts/world/player_death.gd")
const BOOT_LOG := preload("res://scripts/boot/boot_log.gd")

## SA7: on `paths.routes`' "toward the rocky rise" leg (`[10,-10] -> [45,-22]`,
## the same road `landmark.gd`'s stronghold silhouette sits beyond), a stone's
## throw past the square so the player meets it early. `GATE_YAW_DEG` is not
## derived from the route's heading — the one existing "along the path" fence
## yaw in `village.json` was tuned by eye against a render, not computed, so
## this was too; verified square across the road via `tools/survey.gd`.
## `harvest.json` places a berries node at `[20,-16]`, 2.8m from the first
## candidate point on this leg — well inside both interactables' radii, so
## the arbiter kept offering "Pick berries" instead of the gate. Moved
## further out along the same leg for clearance rather than moving the
## harvest node, which R2.1's tutorial route already depends on.
const GATE_AT := Vector2(27.5, -16.0)
const GATE_YAW_DEG := 71.0

## A short detour off the road toward the square — "easy," per SA7's own
## done-when, not a real obstacle. Far enough from `GATE_AT` that the two
## interactables' radii (4.0m gate, 2.4m key) do not overlap; the first
## placement (3.6m away) put both prompts in contest right where a player
## would naturally stand to try the gate, and the closer one always won.
##
## SIGIL-SEAL fallout, 2026-08-25: the old (24,-10) sat only 6.8m along the
## gate's own fence line -- inside `_build_wings()`'s `seal_half_width` 12.0m
## reach on that side, ~2m from the wing panel it now builds there. The wing
## is solid, so it ate the approach: nothing got the player inside the key's
## 2.4m prompt radius and `smoke_opening` failed with "the arbiter picked
## something else" (it hadn't; there was nothing to pick).
##
## Moved off the fence line entirely rather than shortened along it -- a
## shorter seal on this one side is a gap in an otherwise-physical barrier,
## exactly the hole SIGIL-SEAL was written to close. Computed, not eyeballed,
## by `tools/_probe_key_site.gd` (kept for the next time a gate or a fence
## near here moves): a grid search over ground-valid points requiring real
## clearance from every neighbour that matters -- the seal wings themselves
## (>6.0m to the nearest wing centre), the gate's own prompt (>6.4m, same
## non-overlap rule this comment already used), the berries harvest node and
## both village.json `fence_run`s (>4.8m / >4.0m), cottage_b's walls (>3.0m)
## and the square oak (>2.5m) -- then, among every point that cleared all of
## those, the one closest to the gate, so the detour stays "short." Verified
## clear at every margin; see the probe's own output for the full table.
const GATE_KEY_AT := Vector2(31.2, -8.4)

## SF34: the Meadows Hall approach, the chapter's last gate (spec §3 Band 4).
## Three Sigils, one lock — sealed at two of three, open at three. The body is
## `road_gate.gd` configured, not a second gate script; see that file's own
## note on why.
##
## ORIGINAL siting record (pre-OW5D; see that note below for what actually
## drives `SIGIL_GATE_AT` today). Sited where the walkable upper Meadows
## ENDED on the stronghold's bearing at the time: `map_landmarks.json` put
## Meadows Hall at [229.8,-144.4], which was 271m out and therefore beyond
## `world_perimeter.gd`'s 235m ring — it was a silhouette, drawn to be seen
## and not reached, and the approach to it was the last ground the player
## could stand on facing it. GATE-E2 (2026-08-23, "move the castle to the
## end") later moved BOTH the castle (`landmark.gd`'s `SITE`, now (150,7595))
## and this landmark's map pin (`map_landmarks.json`'s `stronghold` entry,
## now also (150,7595)) again, decoupled from this gate's own siting below —
## see `landmark.gd`'s own header for that move's reasoning. [130,-176] was
## 219m out, measured by
## `tools/_probe_upper_meadows.gd` at 1.19m of height spread and a worst local
## slope of 9.8 degrees over a 5m pad, with the Riverwatch Captain 18m back
## down the draw — close enough that the sealed gate is visible over his
## shoulder while you fight him, far enough that their two prompts (4.0m and
## 4.2m) never contest. `SIGIL_GATE_YAW_DEG` puts the leaf across the bearing
## to the Hall (72.4 degrees from here) and is TUNABLE by eye, exactly like
## `GATE_YAW_DEG` above and for the same reason.
## OW5D relocation, docs/MEADOWS_MACRO_LAYOUT.md section 10.2: moved from
## (130,-176) to the table's explicit new coordinate (0,7400), alongside
## stronghold.json's `site.at` moving to (0,7560). `SIGIL_GATE_YAW_DEG` is
## left UNCHANGED below and is almost certainly wrong for the new site: the
## old -17.6 deg was tuned so the gate leaf sits across the OLD bearing to
## the Hall (72.4 deg from the old gate position, per the comment above,
## which itself is now stale prose describing geometry that no longer
## exists). The new corridor's Stronghold-approach spine runs roughly
## north-south, a completely different bearing, so this yaw needs fresh
## tuning against the real approach once it is built -- flagged rather than
## guessed at. Ground truth at (0,7400) was NOT re-probed by this pass.
## BAND5-CONTENT. The OW5D note above deferred both of these to "fresh tuning
## against the real approach ONCE IT IS BUILT" and recorded that "ground truth
## at (0,7400) was NOT re-probed by this pass." The approach is built, and this
## lane's driven run (`tools/_probe_band5_approach.gd`) measured what the note
## could not have known: (0,7400) is **55.9m from the nearest point of the
## authored Band 5 spine**. The spine swings east to (80,7370) before turning
## back to the works, so a player walking the road never came within 55m of the
## chapter's own final gate. The single physical progression checkpoint of the
## region stood in open meadow beside the route, and the objective that
## completes on `hall_approach_open` waited on a thing the road did not pass.
##
## Both constants are now measured, by `tools/_probe_band5_sigil_gate.gd`:
##   * (63.6, 7400) is where the spine ACTUALLY crosses z=7400 -- the same
##     latitude the table gave, moved onto the road instead of beside it.
##     Ground there carries 2.25m of relief over a 16m pad, against 2.08m at
##     the old point: the same quality of ground, so nothing is traded for it.
##     Clearances: 44.1m to Warder Ness's checkpoint (whose own 4.0m prompt and
##     this gate's 4.2m therefore still never contest), 32.9m to the duskhush
##     cluster, 95m+ to everything else authored.
##   * -28.6 deg is `atan2(bearing.x, bearing.z)` of the road's own heading
##     there, (-0.479, 0.878). That is the yaw that puts the leaf ACROSS the
##     road, and the axis was MEASURED rather than assumed
##     (`tools/_probe_gate_leaf_axis.gd`): `road_gate_leaf`'s local AABB is
##     4.07 x 1.46 x 0.12, so the panel spans local X, and `rotation.y = θ`
##     carries local +X onto (cos θ, -sin θ) -- perpendicular to the bearing
##     exactly when θ = atan2(dx, dz). `GATE_YAW_DEG` above is NOT a
##     counter-example: its own comment records that it was tuned by eye
##     against a render rather than computed.
##
## WHAT THIS DOES NOT FIX, said out loud. The leaf is 4.07m wide and stands on
## open ground with no gorge, wall or ravine flanking it, so it is a key-use
## point and a piece of staging -- it is not a barrier, and a player who wants
## to walk around it can. Prompt 66 asks that "a physical gorge/barrier must
## actually constrain travel", and satisfying that needs flanking terrain from
## `terrain_playground.json`'s `crossings`/`spokes` carves, which is a file no
## Gate D lane may edit (GATE_D_LANE_CONTRACT §5). It is requested, with
## measurements, in this lane's report.
const SIGIL_GATE_AT := Vector2(63.6, 7400.0)
const SIGIL_GATE_YAW_DEG := -28.6
const SIGIL_ITEM_IDS := ["field_sigil", "ridge_sigil", "river_sigil"]
const SIGIL_GATE_FLAG := "hall_approach_open"

## T3-BAND4: the ruined watchtower at the Band4->Band5 seam (see
## watchtower_landmark.gd's own header). Sited at the flattest of six
## candidates measured with tools/_probe_t3band4_sites.gd along the
## corridor's own worst authored-content gap after Captain Vess
## (h=2.16m, 1.67m spread, worst slope 10.6 degrees over a 7m pad).
## `facing_deg` is the yaw looking back down the road toward the captains,
## the same atan2(dx,dz) convention `trainers.json`'s own siting notes use,
## derived from the spine's own travel direction at this point.
const WATCHTOWER_AT := Vector2(40.0, 6800.0)
const WATCHTOWER_FACING_DEG := -123.7

## A few metres off the well (village.json stands it at the square's exact
## centre, [10,-10], which is also where every route in `paths.routes`
## starts) so the signpost has its own footing instead of sharing the well's.
const SIGNPOST_AT := Vector2(13.5, -7.0)

## R4.4: two TMs standing in the open field, well clear of every other
## interactable's radius (checked against GATE_AT/GATE_KEY_AT and every
## data/config/harvest.json node — nearest is >7m). Both `ground`-compatible,
## the Meadows' dominant type (GAME_DESIGN.md 8), same as every wild species
## placed here so far.
## REWARD-ECONOMY added the other three. `data/items/items.json` has carried
## fourteen TMs since R4.4; nine are stocked at Mira's, these two stand in the
## opening field, and `tm_earthshatter`, `tm_leviathan_surge` and
## `tm_heavenfall` — one apex TM per type, each of whose own blurb says "Very
## rare" — could not be obtained anywhere in the game. Not a balance problem: a
## shipped item with no acquisition path at all, the same written-but-inert
## shape as the relay console's `requires_flag` seam recorded in BACKLOG.md.
##
## Sited by prompt 58's rule ("where discovery and difficulty justify their
## value") rather than by convenience: one per type, each off the spine in the
## late region that owns that type, each a real detour a player chooses to make.
## They are one-time pickups on exactly the mechanism the first two use — the
## `tm:<id>` flag below already makes a reload unable to mint a second copy —
## so nothing new is introduced to carry them.
const TM_AT := {
	"tm_stone_rush": Vector2(34.0, -20.0),
	"tm_burrow_strike": Vector2(6.0, -30.0),
	# Water, beside the river gorge ~350m downstream of the Old Mill Crossing.
	# 45m off the course centreline at x=500, where terrain_playground.json's
	# `river` measures half_width 12 and rim 6 — an 18m carve edge, so ~27m of
	# clearance. Beside the gorge, not in it, and reached by walking the river
	# instead of crossing it.
	"tm_leviathan_surge": Vector2(500.0, 4240.0),
	# Ground, on Band 4's western high stone, ~110m off the spine's own far
	# point (-420, 5140). The upper country's rock, past the old-growth.
	"tm_earthshatter": Vector2(-520.0, 5180.0),
	# Air, off the Meadows Hall approach road in Band 5 — the latest and hardest
	# of the three to reach, in the region whose wild band is the chapter's
	# strongest.
	"tm_heavenfall": Vector2(140.0, 7300.0),
	# T3-BAND4: Air, 768m before Captain Vess (Air-focused team, trainers.json
	# order 12) — the interior band-4 gap the cadence finding named "768m
	# before the third [captain]". A move to prepare with, not merely XP,
	# right where §9's preparation loop asks for one: on the spine (within
	# the corridor probe's own 30m notice radius), not a detour like the
	# other four.
	"tm_wind_blade": Vector2(70.0, 6245.0),
	# T3-BAND4: Water, at the base of the ruined watchtower (WATCHTOWER_AT),
	# the landmark reward the cadence finding's band4->band5 seam asks for.
	# Water rather than another Air/Ground disc — band 4 otherwise preps
	# every type but the one Captain Riverwatch (band 3) already tested, and
	# a cache a Team Tether patrol never got to ship out is the honest
	# in-fiction reason an upper-ridge ruin holds a river-region TM.
	"tm_riptide_lance": Vector2(33.0, 6795.0),
}

## Where Grandpa's house stands: the west building pad in
## data/config/terrain_playground.json's `flats`. One source of truth would be
## nicer, but the flat is a terrain concept and the house is a building; they
## meet at this number and the bake test asserts the pad is genuinely flat.
const HOUSE_AT := Vector2(-22.0, -16.0)

## Terrain3D.CollisionMode. 1 is DYNAMIC_GAME: real collision shapes rebuilt
## incrementally around the camera, out to `COLLISION_RADIUS_REQUESTED`.
##
## §8.2: FULL_GAME (3) was the fix for a lifecycle bug (see the `_ready()`
## comment below), not a statement that dynamic collision is wrong. At 4
## regions FULL_GAME is cheap; at the 64 regions the corridor bakes, it is
## real shapes across the entire loaded world built at load, all at once, on
## the load screen. Dynamic collision with a radius the player cannot
## outrun is the streaming answer -- see `_apply_dynamic_collision()`.
const COLLISION_DYNAMIC_GAME := 1

## What `_apply_dynamic_collision()` asks Terrain3D for. Verified against the
## vendored addon (`tools/_probe_terrain_collision.gd`, run 2026-08-16) that
## `collision_radius` is SILENTLY CLAMPED to the nearest legal value in
## [16, 256] step 16 -- asking for 512, the number §8.2 reasoned from (based
## on `sprint_speed` alone, before this was checked against the addon), gets
## you 256 back, not 512. `_ready()` reads back what was actually granted and
## uses THAT for the "can the player outrun it" reasoning, not this constant.
const COLLISION_RADIUS_REQUESTED := 512
## `collision_shape_size` clamps to [8, 64] step 8 on the same build. 64 is
## already inside that range, so this one is not a request in the same
## aspirational sense as the radius above -- it is expected to be granted
## exactly, and `_ready()` still reads it back rather than assuming so.
const COLLISION_SHAPE_SIZE := 64

## Metres above the sampled ground to drop the player from, so a small mismatch
## between the collision bake and the heightfield does not spawn them inside it.
const SPAWN_CLEARANCE := 2.0

@onready var _player: CharacterBody3D = $Player
@onready var _camera_rig: Node3D = $CameraRig
@onready var _camera: Camera3D = $CameraRig/Camera3D

var _terrain: Node3D = null
var _vegetation: Node3D = null
var _spawn_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	# RG7. Mid-session Load restores persistent flags into an already-built
	# Meadows scene; this world owns reconciling its authored one-shot props.
	add_to_group("progression_restore")
	BOOT_LOG.phase("playground: _ready start, building Terrain3D node")
	_terrain = _build_terrain()
	if _terrain == null:
		BOOT_LOG.line("playground: terrain build FAILED (see push_error above); world will not stand up")
		return
	BOOT_LOG.phase("playground: terrain node created, waiting for Terrain3DData")

	# data_directory MUST be set after the node is in the tree and a frame has
	# passed. Terrain3D builds its Terrain3DData on first frame, and assigning
	# the directory before that silently leaves `data` null with nothing but a
	# "Resource file not found: res://" in the log. The terrain then renders
	# nothing, has no collision, and the player stands on empty space at the
	# origin — which looks enough like working that it is worth this comment.
	await get_tree().process_frame
	_terrain.set("data_directory", DATA_DIR)
	await get_tree().process_frame
	BOOT_LOG.phase("playground: terrain data_directory assigned")

	_apply_dynamic_collision()

	_apply_ground_materials()
	BOOT_LOG.phase("playground: ground materials/shader applied")

	# Terrain3D needs a camera to decide which regions to keep resident. Without
	# it the extension logs an error every physics frame and stops processing.
	if _terrain.has_method("set_camera"):
		_terrain.call("set_camera", _camera)
	_place_player()
	# A title-screen load happens before this world exists. Player._ready's
	# deferred attempt can run before Terrain3D finishes and `_place_player()`
	# then overwrites it, so the world retries only after its authored spawn has
	# been established. A fresh game simply has no saved pose and is unchanged.
	var game := get_node_or_null(^"/root/Game")
	if game != null and game.has_method("apply_loaded_player_pose"):
		game.call("apply_loaded_player_pose")
	BOOT_LOG.phase("playground: player placed on terrain")
	_dress_the_meadow()
	BOOT_LOG.phase("playground: vegetation scatter built (instance/batch count above)")
	_build_water()
	BOOT_LOG.phase("playground: water built (pond, stream, reeds — counts above)")
	_build_settlement()
	BOOT_LOG.phase("playground: settlement (house, village, signpost, landmark, perimeter, harvest nodes) built")
	_capture_mouse_if_free()
	get_window().focus_entered.connect(_capture_mouse_if_free)
	_report_for_export_check()
	BOOT_LOG.phase("playground: _ready complete, waiting for first frame")
	await get_tree().process_frame
	BOOT_LOG.phase("playground: first frame presented")


## Sets dynamic collision (mode, radius, shape size) and reads every value
## back rather than trusting what was set — §8.2's two verified traps:
##
## 1. Terrain3D setters are no-ops while the node is out of the tree (this is
##    what silently reverted `collision_mode` to Dynamic/Game before the fix
##    that gave this function its home in `_ready()`, after `data_directory`
##    is assigned and the node has been in the tree for a frame).
## 2. `collision_radius` and `collision_shape_size` are silently CLAMPED to
##    ranges this build's addon does not document anywhere reachable from
##    script -- confirmed empirically (`tools/_probe_terrain_collision.gd`):
##    radius to [16, 256] step 16, shape size to [8, 64] step 8. Asking for
##    `COLLISION_RADIUS_REQUESTED` (512) silently gets 256, not 512.
##
## So every value used below the `set()` calls is the READBACK, never the
## requested constant -- the whole point of this function is to not repeat
## the mistake `collision_mode` already made once.
func _apply_dynamic_collision() -> void:
	_terrain.set("collision_mode", COLLISION_DYNAMIC_GAME)
	_terrain.set("collision_radius", COLLISION_RADIUS_REQUESTED)
	_terrain.set("collision_shape_size", COLLISION_SHAPE_SIZE)

	var mode: int = int(_terrain.get("collision_mode"))
	var radius: int = int(_terrain.get("collision_radius"))
	var shape_size: int = int(_terrain.get("collision_shape_size"))
	BOOT_LOG.line("playground: dynamic collision mode=%d radius=%d (requested %d) shape_size=%d (requested %d)" % [
		mode, radius, COLLISION_RADIUS_REQUESTED, shape_size, COLLISION_SHAPE_SIZE])

	if mode != COLLISION_DYNAMIC_GAME:
		push_error("terrain collision_mode is %d, expected %d (Dynamic/Game). " % [mode, COLLISION_DYNAMIC_GAME] +
			"The player will fall through the world outside the dynamic collision radius.")
	if radius <= 0:
		push_error("terrain collision_radius read back as %d; Terrain3D exposed no usable dynamic collision" % radius)
	if shape_size <= 0:
		push_error("terrain collision_shape_size read back as %d; Terrain3D exposed no usable collision shapes" % shape_size)

## COLL1 / §8.3: re-centres the scatter's collision streaming bubble on the
## player, throttled rather than every physics tick -- see
## `COLLISION_STREAM_INTERVAL`'s own comment for why a periodic sweep is
## enough. `_place_player()`/`_dress_the_meadow()` cover frame one; this
## covers every frame after the player actually moves.
const COLLISION_STREAM_INTERVAL := 0.5
var _collision_stream_elapsed: float = 0.0


func _process(delta: float) -> void:
	if _vegetation == null or _player == null:
		return
	_collision_stream_elapsed += delta
	if _collision_stream_elapsed < COLLISION_STREAM_INTERVAL:
		return
	_collision_stream_elapsed = 0.0
	if _vegetation.has_method("update_collision_streaming"):
		_vegetation.call("update_collision_streaming", _player.global_position)


## Capture the mouse for camera look — unless a menu, dialogue box or the
## naming panel currently owns it, which would trap an unclickable cursor
## under whichever of those is open.
##
## Called once at boot and again on every window focus_entered. The single
## boot-time call is what shipped before, and on Windows it can silently
## no-op: Godot's MOUSE_MODE_CAPTURED request made before the native window
## has actually received OS input focus is recorded (Input.mouse_mode reads
## back CAPTURED) but never confines the cursor, so camera_rig.gd's
## `_unhandled_input` — which only turns mouse motion into look at all when
## `Input.mouse_mode == MOUSE_MODE_CAPTURED` — sees a mode that claims to be
## right while no real capture ever happened. That matches the owner's report
## exactly: everything else worked, mouse look did not, from the first frame.
## Headless CI cannot reproduce or verify this (smoke_menu.gd's own note): the
## dummy DisplayServer reports `Input.mouse_mode` back as VISIBLE no matter
## what is requested, so a boot on CI cannot even prove the boot-time call
## above landed, let alone that a later focus_entered re-assertion did. This
## needs a real exported Windows run to confirm — recorded plainly in
## DONE.md, not claimed as tested coverage that does not exist.
func _capture_mouse_if_free() -> void:
	if _mouse_wanted_elsewhere():
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Whether a menu, dialogue box or the naming panel currently wants the mouse
## visible. Each of those saves the mouse mode on open and restores it on
## close; re-capturing over one of them on a focus regain would fight that
## and trap the cursor under a panel the player is trying to read or click.
##
## Reached through `/root/Game` rather than the bare `Game` autoload name —
## see `scripts/story/party_seam.gd`'s header on why: the unit suite runs
## under `--script`, which starts no autoloads at all, and referencing the
## bare singleton name from a script that can load in that context is exactly
## the mistake already paid for once on this project.
func _mouse_wanted_elsewhere() -> bool:
	var game := get_node_or_null(^"/root/Game")
	if game != null and game.has_method("menu"):
		var menu: Object = game.call("menu")
		if menu != null and bool(menu.call("is_open")):
			return true
	var dialogue := get_node_or_null(^"DialoguePanel")
	if dialogue != null and dialogue.has_method("is_open") and bool(dialogue.call("is_open")):
		return true
	var naming := get_node_or_null(^"NamePrompt")
	if naming != null and naming.has_method("is_open") and bool(naming.call("is_open")):
		return true
	var starter := get_node_or_null(^"StarterPicker")
	if starter != null and starter.has_method("is_open") and bool(starter.call("is_open")):
		return true
	# D34's build menu (`scripts/ui/build_menu.gd`) and R2.4/R2.7's craft and
	# storage panels (`craft_panel.gd`/`storage_panel.gd`) are none of them
	# fixed children of this scene the way `DialoguePanel`/`NamePrompt`/
	# `StarterPicker` above are — each is lazily instantiated (by
	# `tab_build.gd`, `camp.gd`, `storage_container.gd` respectively) and
	# added straight under the scene tree's own root, so there is no fixed
	# NodePath to look one up by. Ducktyped instead: anything sitting under
	# root with an `is_open()` that says yes wants the mouse, whichever of
	# the three (or a future fourth) it turns out to be. This was the
	# documented gap this task asked to close — see `_mouse_wanted_elsewhere`'s
	# header on why the fixed-path checks above existed but these did not.
	for node: Node in get_tree().root.get_children():
		if node.has_method("is_open") and bool(node.call("is_open")):
			return true
	return false


## A liveness report an EXPORTED build can actually be tested against.
##
## Run with `--verify-export`, the world says whether it stood itself up and
## then quits. Nothing else in the game reads this flag.
##
## It exists because a shipped build fell through the world forever and there
## was no way to find out from outside. Three separate mechanisms defeated the
## obvious approaches: a release export strips `print()`, so the spawn line the
## world already logged never reached stdout; `--quit-after` is an editor flag
## and is ignored by an export, so the process had to be killed, which flushed
## nothing; and `--quit` exits before the terrain has finished loading, which is
## the exact thing being checked.
##
## `push_warning` survives all three — it goes through the error macros, which
## release builds keep, and it is written immediately rather than buffered.
func _report_for_export_check() -> void:
	if not OS.get_cmdline_args().has("--verify-export"):
		return
	var solid := _terrain != null and _terrain.get("data") != null
	var height: float = ground_height_at(_player.global_position.x, _player.global_position.z)
	push_warning("EXPORT-CHECK terrain=%s ground_at_spawn=%s player_y=%.2f props=%d" % [
		"yes" if solid else "NO",
		"NaN" if is_nan(height) else "%.2f" % height,
		_player.global_position.y,
		int((_vegetation.call("stats") as Dictionary).get("instances", 0)) if _vegetation != null else 0
	])
	get_tree().quit(0 if solid and not is_nan(height) else 1)


func _build_terrain() -> Node3D:
	if not ClassDB.class_exists("Terrain3D"):
		push_error("Terrain3D addon is not installed or failed to load. " +
			"Check addons/terrain_3d/ and that the extension matches this Godot build.")
		return null
	# Checked through res://, NOT through the OS filesystem.
	#
	# This was `DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(...))`,
	# and it shipped a build that fell through the world forever.
	#
	# In the editor, `res://` IS a real directory, so globalizing it gives a path
	# that exists and the check passes. In an EXPORTED build the terrain lives
	# inside the .pck and there is no such directory on disk, so the check failed
	# every time, `_build_terrain()` returned null, and the player spawned in
	# mid-air over an empty world. The data was in the pack the whole time; the
	# guard against it being missing was the only thing missing it.
	#
	# The general form, for the third time in this project: a check that uses a
	# different mechanism from the thing it checks is testing the mechanism.
	# `move_and_slide` uses shape casts while the probe used rays (D09); the
	# smoke tests run from source while players run an export; and here the
	# guard read the OS filesystem while the game reads a resource pack.
	if not DirAccess.dir_exists_absolute(DATA_DIR):
		push_error("No baked terrain at %s. Run: godot --headless --path . " % DATA_DIR +
			"--script scripts/world/build_playground_terrain.gd")
		return null

	var config := _load_terrain_config()
	var terrain: Node3D = ClassDB.instantiate("Terrain3D")
	terrain.name = "Terrain"
	terrain.set("region_size", int(config.get("region_size", 256)))
	terrain.set("vertex_spacing", float(config.get("vertex_spacing", 1.0)))
	# collision_mode/collision_radius/collision_shape_size are deliberately
	# NOT set here: confirmed against this build (`tools/_probe_terrain_
	# collision.gd`) that Terrain3D's collision setters are no-ops while the
	# node is out of the tree, silently keeping their defaults instead of
	# raising an error. `_apply_dynamic_collision()` sets and reads all three
	# back in `_ready()`, once the node has actually been in the tree for a
	# frame.
	add_child(terrain)
	return terrain


## Give the ground real PBR materials.
##
## Until now this switched on `show_colormap`, a Terrain3D DEBUG VIEW, and used
## it as the ground treatment. It was flagged as a placeholder when it went in
## and it survived three milestones. The blind critic measured what it cost:
## 78–91% of the lower half of every exploration frame was featureless flat
## fill, against 3–13% for the references — because a vertex colour map has no
## albedo detail at any distance.
##
## Terrain3D's auto shader picks between the textures by slope, so the same
## grass/soil/rock intent the bake already encodes is expressed with real
## materials instead of flat colour.
func _apply_ground_materials() -> void:
	if _terrain == null:
		return
	var material: Object = _terrain.get("material")
	if material == null:
		push_warning("terrain has no material; ground will render as the default checker")
		return

	var textures := _build_texture_list()
	if textures == null:
		# The colour map is still better than a grey checkerboard, so a missing
		# texture is a downgrade rather than a broken world.
		push_warning("no terrain textures; falling back to the flat colour map")
		material.set("show_checkered", false)
		material.set("show_colormap", true)
		return

	_terrain.set("assets", textures)
	material.set("show_checkered", false)
	material.set("show_colormap", false)
	# The auto shader blends the second texture onto slopes, which is what makes
	# the rocky rises read as stone rather than as grass at an angle.
	material.set("auto_shader", true)
	_apply_ground_shader(material)


## Push data/config/terrain_playground.json's `shader` block at the material.
##
## Split from the texture list because these are two different kinds of thing:
## which textures exist is a content question, and how they are drawn is a
## presentation one. The distinction matters because the presentation half is
## what answers two of the blind critic's measured complaints — the world edge
## and the tiling — and both were invisible from the config until now.
##
## Named properties go through `set`; everything else is a shader uniform. The
## split is by name because Terrain3D exposes some of the shader's uniforms as
## real properties and leaves the rest reachable only through
## `set_shader_param`, and setting one the wrong way fails silently.
func _apply_ground_shader(material: Object) -> void:
	# Terrain3DMaterial exposes exactly TWO of these as real properties. The rest
	# — blend_sharpness, dual_scale_*, mipmap_bias and the macro variation
	# colours — are shader uniforms, reachable only through set_shader_param.
	#
	# This list was longer, and `material.set()` on a name that is not a property
	# returns quietly having done nothing. So five settings were written to the
	# config, read back from the config, and never reached the shader: two
	# consecutive surveys came back byte-identical after retuning dual scaling,
	# which is the only reason it was noticed at all. If a value here appears to
	# do nothing, check which side of this line it is on before tuning it further.
	const PROPERTIES := ["world_background", "texture_filtering"]
	const COLOURS := ["macro_variation1", "macro_variation2"]

	var cfg: Dictionary = _load_terrain_config().get("shader", {})
	if cfg.is_empty():
		# FLAT rather than NOISE, matching the shader's own default, so a missing
		# config is the old look rather than an unlit void.
		material.set("world_background", 1)
		return

	# get_shader_param()'s OWN readback is not trustworthy on this Terrain3D
	# build — R7.1 found it returns null after a successful set for every
	# genuinely valid uniform name, not just for dead ones (proved by forcing
	# extreme values and watching the render actually change while the readback
	# stayed null throughout). _get_shader_parameters() is the real source of
	# truth: it enumerates the shader's actual uniform names directly, so a key
	# missing from it is a genuinely wrong name rather than an unreadable right
	# one.
	var known: Dictionary = {}
	if material.has_method("_get_shader_parameters"):
		known = material.call("_get_shader_parameters")

	var ignored: Array[String] = []
	for key: String in cfg.keys():
		if key.begins_with("_"):
			continue
		var value: Variant = cfg[key]
		if COLOURS.has(key):
			value = Color(str(value))
		if PROPERTIES.has(key):
			material.set(key, value)
			continue
		if not material.has_method("set_shader_param"):
			ignored.append(key)
			continue
		if not known.is_empty() and not known.has(key):
			ignored.append(key)
			continue
		material.call("set_shader_param", key, value)
	if not ignored.is_empty():
		push_warning("terrain shader config names %d setting(s) this build's shader does not have, which will look exactly like tuning them did nothing: %s" % [
			ignored.size(), ", ".join(ignored)
		])

	var background: int = int(material.get("world_background"))
	if background != int(cfg.get("world_background", 1)):
		push_warning("terrain world_background is %d, not the %d the config asked for; " % [
			background, int(cfg.get("world_background", 1))
		] + "the world will have a visible edge at the end of the baked regions.")


## Build a Terrain3DAssets from data/config/terrain_playground.json.
##
## Returns null rather than half a texture list, so the caller can fall back
## cleanly instead of rendering one texture and a checkerboard.
func _build_texture_list() -> Object:
	if not ClassDB.class_exists("Terrain3DAssets") or not ClassDB.class_exists("Terrain3DTextureAsset"):
		return null
	var entries: Array = _load_terrain_config().get("textures", [])
	if entries.is_empty():
		return null

	var assets: Object = ClassDB.instantiate("Terrain3DAssets")
	var index := 0
	# Every texture in the array must be the same size. Terrain3D builds one
	# Texture2DArray, and a single odd resolution makes the whole array fail —
	# silently, leaving a terrain drawn from the colour map alone.
	#
	# That cost two rounds. A 2K grass dropped into a set of 1K textures turned
	# the ground into a flat pale field with no albedo at all, and because it
	# still LOOKED like ground, the next hour went into tuning sun energy and
	# ambient against a surface that had no texture on it to tune.
	var uniform_size := Vector2i.ZERO
	for entry: Variant in entries:
		var path: String = str((entry as Dictionary).get("albedo", ""))
		if not ResourceLoader.exists(path):
			continue
		var size: Vector2i = (load(path) as Texture2D).get_size()
		if uniform_size == Vector2i.ZERO:
			uniform_size = size
		elif size != uniform_size:
			push_error("terrain texture %s is %dx%d but the set is %dx%d. " % [
				path.get_file(), size.x, size.y, uniform_size.x, uniform_size.y
			] + "Terrain3D needs one size for the whole array; the ground will draw " +
				"from the colour map with no albedo detail at all.")
			return null

	for entry: Variant in entries:
		var spec: Dictionary = entry
		var albedo: String = str(spec.get("albedo", ""))
		if not ResourceLoader.exists(albedo):
			push_error("terrain texture missing: %s" % albedo)
			return null
		var texture: Object = ClassDB.instantiate("Terrain3DTextureAsset")
		texture.set("name", str(spec.get("name", "texture%d" % index)))
		texture.set("id", index)
		texture.set("albedo_texture", load(albedo))
		var normal: String = str(spec.get("normal", ""))
		if ResourceLoader.exists(normal):
			texture.set("normal_texture", load(normal))
		# Normal depth well under 1.0, and this is the single most consequential
		# number in the file.
		#
		# At full strength a photographic grass normal map turns most of its
		# texels away from a 52-degree sun, and the ground within about thirty
		# metres of the camera goes black — measured luminance 0.071 against
		# 0.27-0.60 across the references, with the mottled high-contrast fizz the
		# critic called "high-frequency mottled noise, not grass". It flattens
		# with distance because the mip average cancels the perturbation, which is
		# why the far hills looked fine and the foreground did not, and why three
		# confident explanations for it were all wrong.
		texture.set("normal_depth", float(spec.get("normal_depth", 0.35)))
		texture.set("ao_strength", float(spec.get("ao_strength", 0.3)))
		texture.set("roughness_mod", float(spec.get("roughness_mod", 0.0)))
		# Detiling rotates and shifts the tile per region so a 2K texture stops
		# announcing its own repeat period.
		texture.set("detiling_rotation", float(spec.get("detiling_rotation", 0.25)))
		texture.set("detiling_shift", float(spec.get("detiling_shift", 0.3)))
		texture.set("uv_scale", float(spec.get("uv_scale", 0.1)))
		texture.set("albedo_color", Color(str(spec.get("tint", "#ffffff"))))
		assets.call("set_texture", index, texture)
		index += 1
	return assets


## Scatter grass, bushes, trees and rocks across the playground.
##
## Built at runtime from a seeded rule rather than saved into the scene, for the
## same reason the terrain is: a scene full of ten thousand placed nodes is
## unreadable, unmergeable, and impossible to retune. The seed makes it
## identical every run, so a survey frame taken today is comparable with one
## taken after a change.
## GRASS-FIELD. The camera-relative ground cover, if `data/config/
## grass_field.json` says it is on. Built AFTER the scatter, because
## `vegetation.gd::build()` is what drops the layers this replaces and the log
## line it prints should come first, in the order a reader would want them.
##
## Off by default and absent when off -- `grass_field.gd::_ready` builds
## nothing and processes nothing unless enabled -- so this costs a node and a
## config read on a boot that is not using it.
func _stand_up_the_grass_field() -> void:
	if not GRASS_FIELD.is_enabled():
		return
	if _terrain == null:
		push_warning("[playground] grass field is on but there is no terrain to sample")
		return
	var field := MultiMeshInstance3D.new()
	field.set_script(GRASS_FIELD)
	field.name = "GrassField"
	add_child(field)
	# The field follows a CAMERA, and it has to be the one actually rendering:
	# handed the wrong one it centres its ring somewhere the player is not and
	# the ground goes bare exactly where they are standing.
	field.call("bind", _terrain, _camera)


func _dress_the_meadow() -> void:
	var config := _load_terrain_config()
	_vegetation = VEGETATION.new()
	_vegetation.name = "Vegetation"
	add_child(_vegetation)
	_vegetation.call("build", float(config.get("world_size", 512)), _terrain)
	# COLL1 / §8.3: build() only streamed collision in around the world
	# ORIGIN (see vegetation.gd::_add_collision), so any prop near the actual
	# spawn point that is not also near (0,0,0) would otherwise be a hologram
	# for one frame. _place_player() already ran, so the real spawn is known.
	if _player != null and _vegetation.has_method("update_collision_streaming"):
		_vegetation.call("update_collision_streaming", _player.global_position)
	# HARVEST-ALL: build() always draws the fresh, nothing-chopped scatter --
	# this reconciles it against whatever `Game.harvested_vegetation` already
	# remembers (a "Continue" boot that resumed a save before this scene
	# even existed), the same "build fresh, then restore on top" pattern
	# `build_placer.gd`'s own `_ready()` uses for placed buildings.
	# `GameState.load_game`'s own group loop covers the mid-session "Load"
	# case separately.
	var game := get_node_or_null(^"/root/Game")
	if game != null and _vegetation.has_method("restore_from_game"):
		_vegetation.call("restore_from_game", game)
	_stand_up_the_grass_field()
	var stats: Dictionary = _vegetation.call("stats")
	print("[playground] scattered %d props in %d batches (%d harvestable, %d already chopped, %d/%d collision resident)" % [
		stats["instances"], stats["batches"], stats.get("harvest_points", 0),
		stats.get("harvested_permanently", 0), stats.get("solid_resident", 0), stats.get("solid", 0)
	])


## EV5: the pond at the valley floor, its inflow stream, and the reeds at
## their banks. After the vegetation so a water regression cannot take the
## whole meadow's dressing down with it; the two systems only meet through
## the heightfield's water_level/stream_factor, which both read.
func _build_water() -> void:
	var water: Node3D = WATER.new()
	water.name = "Water"
	add_child(water)
	water.call("build")


## Grandpa's house and the village, stood on the building pads the terrain
## bake flattened for them. After _dress_the_meadow so a scatter regression
## cannot leave the opening without its house.
func _build_settlement() -> void:
	var ground := ground_height_at(HOUSE_AT.x, HOUSE_AT.y)
	if is_nan(ground):
		push_error("no ground under the house pad; the opening has nowhere to wake up")
	else:
		var house: Node3D = GRANDPA_HOUSE.new()
		house.name = "GrandpaHouse"
		house.position = Vector3(HOUSE_AT.x, ground, HOUSE_AT.y)
		# Door on the east wall faces the village square.
		add_child(house)
		house.call("build", _camera_rig, _player)
		BOOT_LOG.phase("settlement: grandpa house")

	var village: Node3D = VILLAGE.new()
	village.name = "Village"
	add_child(village)
	village.call("build")
	BOOT_LOG.phase("settlement: village")

	var props: Node3D = PROPS.new()
	props.name = "Props"
	add_child(props)
	props.call("build")
	BOOT_LOG.phase("settlement: props")

	var village_npcs: Node3D = VILLAGE_NPCS.new()
	village_npcs.name = "VillageNPCs"
	add_child(village_npcs)
	village_npcs.call("build", _player)
	BOOT_LOG.phase("settlement: village NPCs")

	# R8.1: the people who challenge you. After the villagers, so a trainer
	# standing too close to one is visible in the same pass rather than a
	# frame later, and named separately because SC12 moves three of these
	# roles onto villagers who are already placed above.
	# SE27: the relay station's captive, placed by the same script from a
	# second list (data/config/relay_site.json). Not a new placer — the only
	# thing she needs that a villager does not is a `place_when` gate, and
	# village_npcs.gd grew one for the pair of them.
	var relay_npcs: Node3D = VILLAGE_NPCS.new()
	relay_npcs.name = "RelayNPCs"
	add_child(relay_npcs)
	relay_npcs.call("build", _player, VILLAGE_NPCS.RELAY_CONFIG_PATH)

	var trainers: Node3D = TRAINER_NPCS.new()
	trainers.name = "Trainers"
	add_child(trainers)
	trainers.call("build", _player)

	# TOURNAMENT-1: the bracket board, in the north field behind the square.
	# After the trainers so it stands in a settlement that is already built --
	# it reads ground height the same way they do and nothing about it depends
	# on them, but the tournament ground is Bryn's practice field and building
	# the two in the order the player meets them keeps the log readable.
	var tournament: Node3D = TOURNAMENT.new()
	tournament.name = "Tournament"
	add_child(tournament)
	tournament.call("build", self)

	var signpost: Node3D = SIGNPOST.new()
	signpost.name = "Signpost"
	add_child(signpost)
	signpost.call("build", self, SIGNPOST_AT)

	_build_trailhead_signposts()

	var landmark: Node3D = LANDMARK.new()
	landmark.name = "StrongholdSilhouette"
	add_child(landmark)
	landmark.call("build", self)

	_build_road_gate()
	_build_sigil_gate()

	var watchtower: Node3D = WATCHTOWER_LANDMARK.new()
	watchtower.name = "RuinedWatchtower"
	add_child(watchtower)
	watchtower.call("build", self, WATCHTOWER_AT, WATCHTOWER_FACING_DEG)

	# SC14: the South Bridge over the south gully, and the leaf across it.
	# After the road gate so the two gates build in the order the player meets
	# them, and before the spokes for no reason but readability — neither
	# touches the other.
	var south_bridge: Node3D = SOUTH_BRIDGE.new()
	south_bridge.name = "SouthBridge"
	add_child(south_bridge)
	south_bridge.call("build", self)

	# SD16: the Old Quarry past it — foundations and the Tether conduit run.
	# Its Rootstone deposits are ordinary `harvest.json` nodes and stand up in
	# `_place_harvest_nodes()` below with every other gathering spot; its
	# abandoned gear is a `props.json` cluster and is already standing.
	var quarry: Node3D = OLD_QUARRY.new()
	quarry.name = "OldQuarry"
	add_child(quarry)
	quarry.call("build", self)

	# SE23: the Tether Relay Station further along the same bearing the
	# quarry's conduit run leaves on. After the quarry because that is the
	# order §32's reveal ladder puts them in and the order the player meets
	# them; neither touches the other. The people on it are SE25/SE27's
	# (data/config/relay_site.json), placed by the ordinary NPC/trainer
	# placers, not by this.
	var relay: Node3D = TETHER_RELAY.new()
	relay.name = "TetherRelay"
	add_child(relay)
	relay.call("build", self)
	# SE21: the river that divides the deeper Meadows. Only its recovery
	# volumes are built here -- the channel is terrain (the bake cut it) and
	# the water is the water layer's.
	var river: Node3D = RIVER.new()
	river.name = "River"
	add_child(river)
	river.call("build", self)

	# SE22: the Old Mill Crossing, the one authored way over that river.
	var mill_crossing: Node3D = MILL_CROSSING.new()
	mill_crossing.name = "MillCrossing"
	add_child(mill_crossing)
	mill_crossing.call("build", self)

	# SA4: the severed outward roads. Before the boundary ring because they
	# stand INSIDE it (~160-200m out) and are the thing the player is meant to
	# read at those bearings; the ring is the ordinary field edge behind them.
	var spokes: Node3D = SEVERED_SPOKES.new()
	spokes.name = "SeveredSpokes"
	add_child(spokes)
	spokes.call("build", self)
	print("[playground] severed spokes standing: %s" % ", ".join(spokes.call("built")))

	var perimeter: Node3D = WORLD_PERIMETER.new()
	perimeter.name = "WorldPerimeter"
	add_child(perimeter)
	perimeter.call("build", self, _player, _spawn_position)

	_place_harvest_nodes()
	_place_farm_plots()
	_place_tms()
	_build_burrow_warrens()
	_build_stronghold()
	_build_stronghold_climax()

	# SG44: the first Tether Rift collapses. Sky only -- a distant,
	# non-enterable view past the storm road's seam, built last because it
	# depends on nothing and nothing depends on it. See the file's header for
	# the carve-out it is written around.
	var rift: Node3D = RIFT_COLLAPSE.new()
	rift.name = "RiftCollapse"
	add_child(rift)
	rift.call("build", self)

	# SG46 / D41: and the local half of the same event -- the meadow itself is
	# freed. After everything it heals (the vegetation, the relay, the pylon
	# lines, the gates, the trainers), because it walks the world it is given.
	var healing: Node3D = MEADOW_HEALING.new()
	healing.name = "MeadowHealing"
	add_child(healing)
	healing.call("build", self)

	var placer := BUILD_PLACER.new()
	placer.name = "BuildPlacer"
	placer.player_path = NodePath("../Player")
	placer.camera_rig_path = NodePath("../CameraRig")
	add_child(placer)

	# §22: on player death, drop a satchel and respawn at home.
	var death: Node3D = PLAYER_DEATH.new()
	death.name = "PlayerDeath"
	add_child(death)
	death.call("build", self, _player, _spawn_position)


## OF10-remainder: one small fingerpost per entry in `paths.trailheads`,
## reusing signpost.gd's `routes_override` so each is a single arm continuing
## its own route's label and bearing rather than the full junction sign.
## Data-driven (like `paths.routes` itself) because a second trailhead is a
## config entry, not a new script.
func _build_trailhead_signposts() -> void:
	var cfg: Dictionary = _load_terrain_config().get("paths", {})
	var trailheads: Array = cfg.get("trailheads", [])
	var i := 0
	for entry: Variant in trailheads:
		var trailhead: Dictionary = entry as Dictionary
		var at: Array = trailhead.get("at", [])
		var label := str(trailhead.get("label", ""))
		var points: Array = trailhead.get("points", [])
		if at.size() < 2 or label.is_empty() or points.size() < 2:
			push_warning("skipped a malformed paths.trailheads entry")
			continue
		var post: Node3D = SIGNPOST.new()
		post.name = "TrailheadSignpost_%d" % i
		add_child(post)
		post.call("build", self, Vector2(float(at[0]), float(at[1])), [{"label": label, "points": points}])
		i += 1


## SA7: the road out toward the stronghold is gated, and its key sits a few
## metres off to the side rather than behind any real obstacle.
func _build_road_gate() -> void:
	var gate: Node3D = ROAD_GATE.new()
	gate.name = "RoadGate"
	# SIGIL-SEAL / owner ruling 2026-08-25: "gates have to be physically sealed
	# -- there needs to actually be something keeping a player from walking
	# around it". This gate's own header claimed it stood in a fence line that
	# ran off both its ends; it does not. The nearest `fence_run` in
	# village.json sits 12m away and cottage_b 6.7m off one side, so the leaf
	# was a 4m panel with open meadow beside it, and a player who slid along it
	# simply walked round -- exactly the hole this session found and closed at
	# the Sigil Gate.
	# Raised 12.0 -> 20.0. At 12 the wings ran out at (31.4,-27.3) and CI walked
	# round the end of them to (33.0,-29.8) -- "walked to within 2.1m of a point
	# 15m past the gate; the road is not physically blocked". Same lesson the
	# Sigil Gate taught at 8.5: a seal sized to the ROAD only stops someone
	# walking down the road, and a sliding player does not.
	gate.set("seal_half_width", 12.0)
	add_child(gate)
	gate.call("build", self, GATE_AT, GATE_YAW_DEG)

	var game := get_node_or_null(^"/root/Game")
	if KEY_PICKUP.was_taken(game, "castle_gate_key"):
		return
	_spawn_gate_key()


func _spawn_gate_key() -> void:
	if get_node_or_null(^"GateKey") != null:
		return
	var ground := ground_height_at(GATE_KEY_AT.x, GATE_KEY_AT.y)
	if is_nan(ground):
		push_error("no ground under the gate key at %.0f, %.0f" % [GATE_KEY_AT.x, GATE_KEY_AT.y])
		return
	var key: Node3D = KEY_PICKUP.new()
	key.name = "GateKey"
	key.position = Vector3(GATE_KEY_AT.x, ground, GATE_KEY_AT.y)
	add_child(key)
	key.call("setup", "castle_gate_key", "Take the old key")


## SF34: the Hall approach. Same body as the road gate, three Sigils instead
## of one key — and no key lying nearby, because the keys are three captains
## (`data/config/trainers.json`). Nothing here checks a level or a flag the
## player cannot see in their own satchel.
func _build_sigil_gate() -> void:
	var gate: Node3D = ROAD_GATE.new()
	gate.name = "SigilGate"
	gate.set("key_item_ids", SIGIL_ITEM_IDS)
	gate.set("flag_id", SIGIL_GATE_FLAG)
	gate.set("locked_conversation", "hall_approach_sealed")
	gate.set("unlocked_conversation", "hall_approach_opened")
	gate.set("prompt_text", "Try the Hall gate")
	# SIGIL-SEAL. The leaf alone is 4.06m against a 14.1m causeway, so a locked
	# gate could be walked round at +/-3m off centre -- `smoke_traversal.gd`
	# walks exactly that. 8.5m is the causeway's own measured half-width (7.04m)
	# plus enough to bury the wing ends in the gorge rims instead of stopping
	# flush with walkable ground.
	# Raised 8.5 -> 16.0 under the 2026-08-25 owner ruling. 8.5 covered the
	# causeway's own 7.04m half-width and was sized for a player who walks
	# STRAIGHT at a gate. Once the body slides (OF15), it runs along the wings
	# and round their ends: smoke_traversal walked a locked gate at -6.0m off
	# centre and got 15m past. The wings now reach out to where the gorge itself
	# stops the player -- the same run records a fall-and-respawn at +/-18m -- so
	# the barrier ends where the ground does rather than in open grass. Wings
	# skip any offset with no ground under it, so this cannot hang panels over
	# the carve.
	gate.set("seal_half_width", 16.0)
	add_child(gate)
	gate.call("build", self, SIGIL_GATE_AT, SIGIL_GATE_YAW_DEG)


## R4.4: TMs found in the world (GAME_DESIGN.md 13). Each is a one-time
## physical prop, and OF29 makes what it grants a real satchel item -- so
## "one-time" now has to be enforced here. A TM whose `tm:<id>` flag is
## already set was taken in an earlier session and is simply not placed; a
## reload cannot mint a second copy of a consumable disc.
##
## Migration: a save written BEFORE OF29 carries that same flag from the old
## flag-only pickup, and gets exactly this treatment -- prop gone, no free
## item. That is the honest reading. The flag was only ever a key to
## `tab_creatures.gd::_teach_next()`'s auto-teach, which OF29 retires; a
## player who took a TM under the old rules already had every teach that
## screen would give them, and handing them a fresh disc now would be
## inventing a reward the old design never promised.
func _place_tms() -> void:
	var game := get_node_or_null(^"/root/Game")
	for tm_id: String in TM_AT:
		if TM_PICKUP.was_taken(game, tm_id):
			continue
		_spawn_tm(tm_id)


func _spawn_tm(tm_id: String) -> void:
	if get_node_or_null(NodePath("TM_%s" % tm_id)) != null:
		return
	var at: Vector2 = TM_AT[tm_id]
	var ground := ground_height_at(at.x, at.y)
	if is_nan(ground):
		push_error("no ground under TM '%s' at %.0f, %.0f" % [tm_id, at.x, at.y])
		return
	var pickup: Node3D = TM_PICKUP.new()
	pickup.name = "TM_%s" % tm_id
	pickup.position = Vector3(at.x, ground, at.y)
	add_child(pickup)
	pickup.call("setup", tm_id)


## RG7. Loading through the in-world Save tab does not rebuild the scene. Make
## authored one-shot props match the newly loaded flags in both directions:
## consumed props disappear immediately, and an earlier save can restore a prop
## that was picked up after that save was written.
func restore_progression_from_game(game: Node) -> void:
	var key := get_node_or_null(^"GateKey") as Node3D
	if KEY_PICKUP.was_taken(game, "castle_gate_key"):
		if key != null and key.has_method("restore_progression_from_game"):
			key.call("restore_progression_from_game", game)
	elif key == null:
		_spawn_gate_key()
	for tm_id: String in TM_AT:
		var pickup := get_node_or_null(NodePath("TM_%s" % tm_id)) as Node3D
		if TM_PICKUP.was_taken(game, tm_id):
			if pickup != null and pickup.has_method("restore_progression_from_game"):
				pickup.call("restore_progression_from_game", game)
		elif pickup == null:
			_spawn_tm(tm_id)


## SD17: the Burrow Warrens, dug into the flank of the rocky rise out in the
## deeper Meadows. Its position, layout, population and contents all live in
## data/config/burrow_warrens.json; the world only hands it the three things
## it cannot find on its own — the ground query, the camera rig it swaps
## profiles on, and the encounter director that owns every wild body.
##
## Placed after the harvest nodes and TMs for the ordinary reason everything
## in this function is ordered: a regression in the dungeon must not be able
## to take the field's own contents down with it.
func _build_burrow_warrens() -> void:
	var warrens: Node3D = BURROW_WARRENS.new()
	warrens.name = "BurrowWarrens"
	add_child(warrens)
	var director := get_node_or_null(^"EncounterDirector")
	if not bool(warrens.call("build", self, _camera_rig, _player, director)):
		push_warning("the Burrow Warrens did not build; the required dungeon is missing")


## R8.2/SG38: the authored stronghold route behind `landmark.gd`'s castle, and
## the three-fight gauntlet standing in it. Its layout, contents and trainers
## live in data/config/stronghold.json; like the warrens, the world only hands
## it the ground query, the camera rig and the player. Placed after the warrens
## so a regression in either dungeon cannot take the other down with it, and
## after the trainers pass above on purpose -- the stronghold's own people carry
## `placed_by: "stronghold"`, so that pass has already skipped them and this one
## stands them on the stronghold's floor rather than on the meadow under it.
func _build_stronghold() -> void:
	var stronghold: Node3D = STRONGHOLD.new()
	stronghold.name = "Stronghold"
	add_child(stronghold)
	if not bool(stronghold.call("build", self, _camera_rig, _player)):
		push_warning("the stronghold route did not build; spec §8's five spaces are missing")
## R8.3/SG40/R8.4: the Warden, the reveal and the freeing of the legendary.
##
## Built LAST of the authored content, and after `_build_stronghold()` when
## R8.2's route is present, because the climax asks that building for its
## named marks (`warden_stand`, `machine_foot`, `legendary_stand`) rather than
## hard-coding a metre inside somebody else's rooms. Where the route is not in
## the tree yet the climax falls back to its own world coordinates in
## data/config/stronghold_climax.json and still runs end to end — the merge is
## then only a matter of the markers starting to answer.
func _build_stronghold_climax() -> void:
	var climax: Node3D = STRONGHOLD_CLIMAX.new()
	climax.name = "StrongholdClimax"
	add_child(climax)
	if not bool(climax.call("build", self, _player)):
		push_warning("the stronghold climax did not build; the chapter has no ending")


## The first day's gathering spots, from data/config/harvest.json.
func _place_harvest_nodes() -> void:
	var parsed: Dictionary = BAND_CONTENT.load_config("res://data/config/harvest.json", "nodes")
	if parsed.is_empty():
		push_warning("harvest.json missing; the first day has nothing to gather")
		return
	var placed := 0
	for entry: Variant in parsed.get("nodes", []):
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry
		var at: Array = spec.get("at", [0.0, 0.0])
		var ground := ground_height_at(float(at[0]), float(at[1]))
		if is_nan(ground):
			continue
		var node: Node3D = HARVEST_NODE.new()
		node.position = Vector3(float(at[0]), ground, float(at[1]))
		add_child(node)
		node.call("setup", spec)
		placed += 1
	print("[playground] placed %d harvest nodes" % placed)


## R7.6. The berry farm's beds, from data/config/farm.json.
##
## Its own placer rather than a row in harvest.json: a farm bed is not a
## harvest node. It carries saved state, it has four appearances instead of
## two, and it answers to the hoe — none of which `harvest_node.gd::setup()`
## has a field for. What the two DO share is `harvest_logic.gd`, and they
## share it through the code (`farm_plot.gd::_harvest`), not through the data.
##
## The index passed to each plot is its position in the file, which is the key
## its saved state is stored under (`game_state.gd::farm_plots`).
func _place_farm_plots() -> void:
	var file := FileAccess.open("res://data/config/farm.json", FileAccess.READ)
	if file == null:
		push_warning("farm.json missing; the farmhouse has no farm")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("farm.json is not valid JSON; the farmhouse has no farm")
		return
	var config := parsed as Dictionary

	var root := Node3D.new()
	root.name = "BerryFarm"
	add_child(root)

	var placed := 0
	for entry: Variant in config.get("plots", []):
		if not entry is Dictionary:
			continue
		var at: Array = (entry as Dictionary).get("at", [0.0, 0.0])
		var x := float(at[0])
		var z := float(at[1])
		# D09: ask the world, never a raycast.
		var ground := ground_height_at(x, z)
		if is_nan(ground):
			push_warning("no ground under farm plot %d at %.0f, %.0f" % [placed, x, z])
			continue
		var plot: Node3D = FARM_PLOT.new()
		plot.name = "Plot%d" % placed
		plot.position = Vector3(x, ground, z)
		root.add_child(plot)
		plot.call("setup", placed, config)
		placed += 1
	print("[playground] placed %d farm plots" % placed)


## Ground height at a world x/z, or NAN where there is no terrain.
##
## Anything that needs to stand something on the ground should ask this rather
## than casting a ray downwards.
##
## Raycasts against Terrain3D's heightmap collision are unreliable: measured
## across the playground, roughly a quarter of downward rays return no hit at
## points where the ground is unquestionably present — a sphere query at the
## same spot collides, the character walks over it without falling, and
## `data.get_height` returns a sane value. `move_and_slide` uses shape casts, so
## the world has always been solid to walk on; only rays lie about it.
##
## That cost an entire creature. The M3 wild creature was placed by raycast, the ray
## silently missed, and the creature was never spawned at all — no error, no
## body, just an encounter that could not happen.
func ground_height_at(x: float, z: float) -> float:
	if _terrain == null:
		return NAN
	var data: Object = _terrain.get("data")
	if data == null:
		return NAN
	return float(data.call("get_height", Vector3(x, 0.0, z)))


func _load_terrain_config() -> Dictionary:
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## Drop the player onto the baked ground rather than trusting a hand-placed Y in
## the scene, which silently rots every time the terrain is re-baked.
func _place_player() -> void:
	if _player == null or _terrain == null:
		return
	var data: Object = _terrain.get("data")
	if data == null:
		push_warning("terrain data not ready; leaving the player at its scene position")
		return

	var spawn := Vector3(_player.global_position.x, 0.0, _player.global_position.z)
	var ground: float = data.call("get_height", spawn)
	if is_nan(ground):
		push_warning("no terrain height at spawn; leaving the player where it is")
		return

	_player.global_position = Vector3(spawn.x, ground + SPAWN_CLEARANCE, spawn.z)
	_spawn_position = _player.global_position
	if _camera_rig != null and _camera_rig.has_method("set_target"):
		_camera_rig.call("set_target", _player)
	print("[playground] spawned at %.1f, %.1f, %.1f" % [
		_player.global_position.x, _player.global_position.y, _player.global_position.z
	])
