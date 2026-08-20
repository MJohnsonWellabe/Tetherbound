extends Node

## Turns the Build tab's armed choice into a thing standing in the world.
##
## `GameState.pending_build` has been the honest end of the build screen since
## the menu shipped — the tab arms an id and nothing read it. This reads it:
## while a build is armed, a ghost of the piece hovers ahead of the player,
## snapped onto the world's 2m module grid (`build_grid.gd`, matching
## `building_prefabs.json`'s own grid) or flush against a same-type neighbour
## when one is close enough, rotatable, green where it can stand and red (or
## amber, snapped-but-blocked) where it cannot. `build_place` plants it, per
## D34's own action, not `interact` — see that decision's "double-read"
## section for why the old binding was retired. Costs go through
## `GameState.build_cost_for` / `can_afford`, which is the one gate the
## free-build toggle is allowed to bend (docs/decisions/D16).
##
## `camp` and `storage` keep their own hand-authored geometry (`camp.gd`,
## `storage_container.gd`) because each carries state and an interaction, not
## just a mesh. Every other `buildables.json` entry (R2.6: floor, wall, door,
## roof, fence; R2.7: workbench) is plain geometry, placed generically through
## `build_piece.gd` from the catalogue's own `mesh` path.
##
## BG1: this is the ONE placement system, serving both the player's own base
## (M8's original purpose) and the OF4 castle rebuild (D28) — there is no
## second, landmark-only copy of any of this.

const CAMP := preload("res://scripts/build/camp.gd")
const STORAGE_CONTAINER := preload("res://scripts/build/storage_container.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const BUILD_GRID := preload("res://scripts/build/build_grid.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const CRAFT_PANEL := preload("res://scripts/ui/craft_panel.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
const AUDIO_CUES := preload("res://scripts/ui/audio_cues.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

## Ids placed by their own hand-authored script rather than build_piece.gd's
## generic path — kept as one list so the "is this a special id" question is
## answered in exactly one place instead of every branch below re-deriving it.
## R4.8: `creature_bed` joins this list for its interaction, not for any
## saved state — unlike `storage`, it has nothing worth persisting (a rest is
## momentary), so `_spawn_building`'s `state_data` branch stays storage-only.
const STATEFUL_IDS := ["camp", "storage", "creature_bed"]

## R3.1. Every node this script has planted for real, ghost excluded — how
## `restore_from_game` finds and clears the old set before rebuilding from a
## loaded save, and how `GameState.load_game` finds this node at all.
const PLACED_GROUP := "placed_building"
const BUILD_PLACER_GROUP := "build_placer"

## Which catalogue id a placed node came from, stashed as node metadata
## rather than a new exported var on `build_piece.gd`/`camp.gd`/
## `storage_container.gd` — those three scripts do not otherwise need to know
## their own catalogue id, and every reader of it (only `_neighbour_positions`
## below) lives in this file.
const BUILDING_ID_META := "building_id"

## R3.1-remainder. This node's own index into `GameState.placed_buildings` —
## how `sync_state_to_game` below finds the array entry a live stateful
## piece's current data belongs on, cheaper than adding a second id field to
## the save format just to link a node back to its own record.
const PLACED_INDEX_META := "placed_index"

## BG1's original rotate action (project.godot, data/config/menu.json's
## "Building" controls group): rotates the armed ghost one FIXED 90-degree
## step, regardless of `_rotation_step_deg` below. Keyboard T and gamepad
## D-pad down were both unused by any existing action — see the input-map
## audit in this file's own commit message / ralph/DONE.md entry. Kept
## working unchanged by D34 (`build_rotate_left`/`build_rotate_right` are
## additive, not a replacement) so muscle memory from BG1 still turns a piece.
const ROTATE_ACTION := "build_rotate"

## D34/spec 13: fine rotation and placement's own actions, added alongside
## `ROTATE_ACTION` rather than instead of it (`docs/decisions/D34`).
## `build_place` retires the old `interact` double-read
## `interaction_arbiter.gd`'s header names — placement no longer touches
## `interact` at all.
const ROTATE_LEFT_ACTION := "build_rotate_left"
const ROTATE_RIGHT_ACTION := "build_rotate_right"
const SNAP_CYCLE_ACTION := "build_snap_cycle"
const PLACE_ACTION := "build_place"
const CANCEL_ACTION := "build_cancel"

## D34/spec 13.3: the local grid overlay's reach around the ghost and its
## two line weights. Metres.
const GRID_RADIUS := 8.0
const GRID_MINOR_STEP := 0.5
const GRID_MAJOR_STEP := 1.0
## Top of the spec's 8-12% / 18-25% bands rather than the middle: the first
## capture round showed the grid all but vanishing into sunlit grass at
## 10%/20% (tunable — but stay inside the spec band, the grid must assist,
## not carpet the meadow).
const GRID_MINOR_ALPHA := 0.12
const GRID_MAJOR_ALPHA := 0.25

## D34/spec 13.2: on-screen size of a snap-candidate dot, and how much
## brighter the one `build_grid.resolve_position` would actually choose
## (always `neighbours_in_range`'s first entry) reads next to the rest.
const SNAP_DOT_RADIUS := 8.0

## Metres ahead of the player the ghost sits.
const PLACE_AHEAD := 3.0
## A camp needs ground this flat. Steeper reads as a tent on a cliff.
const MAX_SLOPE_RISE := 0.8
## Below this, two grid cells count as "the same cell" for the
## already-occupied check — comfortably smaller than the smallest float
## drift `snappedf` can introduce, comfortably larger than none.
const SAME_CELL_EPSILON := 0.01

@export var player_path: NodePath
@export var camera_rig_path: NodePath

var _player: Node3D = null
var _camera_rig: Node = null
var _ghost: Node3D = null
var _ghost_ok := false
var _ghost_id := ""
## OF23: why the ghost currently refuses to place — "" when it is fine.
## `_hint_text` folds this into the always-visible control strip so "can't
## afford / too steep / occupied" reads the instant the ghost turns red, not
## only after a wasted `build_place` press and a bare `ui_error` beep.
var _ghost_reason := ""
## Previous frame's `snapped_to_neighbour`, per `AudioCues` wiring below --
## `build_snap` plays on the false->true edge only, not every frame the ghost
## happens to already be sitting snapped.
var _was_snapped := false
## Continuous yaw in degrees, replacing BG1's `_ghost_rotation_steps: int`.
## `ROTATE_ACTION` still turns this by a fixed 90 regardless of
## `_rotation_step_deg`; `ROTATE_LEFT_ACTION`/`ROTATE_RIGHT_ACTION` turn it by
## `_rotation_step_deg`. Reset whenever a new ghost is created (`_drop_ghost`)
## so switching pieces in the Build menu does not carry a rotation the player
## chose for a different piece onto the next one.
var _yaw_deg := 0.0
## D34/spec 13.4's `build_snap_cycle`: the step size a left/right rotate press
## turns the ghost by. NOT reset by `_drop_ghost` — this is a placer-wide
## preference ("I am doing fine work right now"), not a per-ghost value.
var _rotation_step_deg: float = BUILD_GRID.SNAP_STEP_DEGS[0]

## The piece armed on the previous frame, and whether `PLACE_ACTION` is
## currently barred from planting it. Together these are the fix for the
## owner's playtest report: *"you go to build, select the thing you want to
## build and it just places. there is no decision for you, you don't place it,
## you don't rotate, there's no grid."*
##
## The whole ghost/rotate/grid system below was working the entire time — it
## just never got a frame to run. `build_place` is bound to LMB, and
## `build_menu.gd::_pick()` arms `pending_build` and closes on that same click.
## `Input.is_action_just_pressed` is GLOBAL polling: it knows nothing about the
## Button that consumed the click, and it stays true for the whole physics
## frame the press landed in. So the click that chose the piece also satisfied
## the place check further down this function, in that same frame, and the
## piece went straight into the ground `PLACE_AHEAD` metres away — before a
## ghost was ever drawn.
##
## The rule now: **arming never places.** A newly armed piece bars the place
## action until it has been seen released at least once, so planting always
## costs a fresh, deliberate press. Arming from a path that never touched the
## place button (a keyboard pick, a gamepad pick) clears the bar on the very
## next frame, so nothing gets slower for them.
var _armed_last := ""
var _place_blocked := false

## D34/spec 13.2-13.4: the placer's own screen-space overlay (snap dots, the
## bottom-center control strip) and the world-space local grid mesh, all
## built lazily on first use rather than in `_ready` — most of a session has
## no ghost armed, and there is no reason to pay for three extra nodes until
## one is.
var _overlay: CanvasLayer = null
var _snap_dots: Control = null
var _hint_label: RichTextLabel = null
var _grid_mesh: MeshInstance3D = null
## World X/Z positions the snap dots draw this frame, nearest (the one
## `build_grid.resolve_position` would actually choose) first. Read by
## `_on_snap_dots_draw`, written by `_show_ghost`.
var _snap_candidates: Array = []


func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	_camera_rig = get_node_or_null(camera_rig_path)
	add_to_group(BUILD_PLACER_GROUP)
	restore_from_game(_game())


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _physics_process(_delta: float) -> void:
	var game := _game()
	if game == null or _player == null:
		return
	var armed := str(game.get("pending_build"))
	# Arming — including swapping straight from one piece to another without
	# disarming in between — bars the place action until it is released. See
	# `_place_blocked`'s comment for why this exists.
	if armed != _armed_last:
		_armed_last = armed
		_place_blocked = armed != ""
	if armed == "":
		_drop_ghost()
		return

	# UI-PAD2: this node is `PROCESS_MODE_PAUSABLE` (the default), which stops
	# it for every panel that pauses the tree -- but `build_menu.gd`
	# deliberately does NOT pause (its own header explains why: the world
	# stays live behind it, the whole point of the Valheim feel), so an armed
	# ghost kept reading `build_place`/rotate/cancel/snap out from under a
	# REOPENED menu. Exactly the shape of leak `input_owner.gd` exists to
	# close, for a poller that had never asked it
	# (`grep -n "input_owner" scripts/build/build_placer.gd` used to return
	# nothing). The ghost still tracks the aim point below regardless, so the
	# world does not visibly freeze while a menu happens to be open on top of
	# it -- only the actions that would change or spend the ghost are gated.
	if INPUT_OWNER.current(get_tree()) != null:
		_show_ghost(game, armed)
		# RG4: a build_place press swallowed here used to give no signal at
		# all -- the ghost stays green (legal), nothing lands, and nothing
		# says why, which reads as "builds don't work" rather than "something
		# else has your input right now" (a story dialogue, the starter
		# picker -- anything `input_owner.gd`'s group holds). Every OTHER
		# refusal in this file (occupied/steep/can't afford) already gets
		# this same cue; a press eaten here is not different from those.
		if Input.is_action_just_pressed(PLACE_ACTION):
			AUDIO_CUES.play(&"ui_error")
		return

	if Input.is_action_just_pressed(CANCEL_ACTION):
		game.set("pending_build", "")
		_drop_ghost()
		return

	if Input.is_action_just_pressed(ROTATE_ACTION):
		_yaw_deg = fposmod(_yaw_deg + BUILD_GRID.ROTATION_STEP_DEG, 360.0)
	if Input.is_action_just_pressed(ROTATE_LEFT_ACTION):
		_yaw_deg = fposmod(_yaw_deg - _rotation_step_deg, 360.0)
	if Input.is_action_just_pressed(ROTATE_RIGHT_ACTION):
		_yaw_deg = fposmod(_yaw_deg + _rotation_step_deg, 360.0)
	if Input.is_action_just_pressed(SNAP_CYCLE_ACTION):
		_rotation_step_deg = BUILD_GRID.next_snap_step_deg(_rotation_step_deg)

	_show_ghost(game, armed)
	if _place_blocked:
		# Never plant on the frame a piece was armed. The bar lifts as soon as
		# the button is up — which for a mouse pick is the moment the player
		# lets go of the click that chose the piece, and for every other pick
		# path is the very next frame.
		if not Input.is_action_pressed(PLACE_ACTION):
			_place_blocked = false
	elif Input.is_action_just_pressed(PLACE_ACTION):
		if _ghost_ok:
			_place(game, armed)
		else:
			AUDIO_CUES.play(&"ui_error")


## The mesh path a plain catalogue entry places, or "" if it has none (an id
## the catalogue doesn't know, or one of the stateful ids above).
func _piece_mesh(game: Node, id: String) -> String:
	if STATEFUL_IDS.has(id):
		return ""
	var items: RefCounted = game.get("items")
	if items == null:
		return ""
	var entry: Dictionary = items.call("buildable", id)
	return str(entry.get("mesh", ""))


## OF24: the same catalogue entry's own `light` block, {} for anything that
## has none (every entry but the torch, today). Fed straight into
## `build_piece.gd::build_real` -- see that file's own comment on why this is
## generic rather than torch-specific.
func _piece_light(game: Node, id: String) -> Dictionary:
	if STATEFUL_IDS.has(id):
		return {}
	var items: RefCounted = game.get("items")
	if items == null:
		return {}
	var entry: Dictionary = items.call("buildable", id)
	var light: Variant = entry.get("light", {})
	return light if light is Dictionary else {}


## The ghost: the armed piece's own silhouette at half alpha, coloured by
## legality. Rebuilt whenever the armed id changes, so switching pieces in
## the Build tab swaps the ghost rather than leaving the old one behind.
func _show_ghost(game: Node, armed: String) -> void:
	if _ghost != null and is_instance_valid(_ghost) and _ghost_id != armed:
		_drop_ghost()

	if _ghost == null or not is_instance_valid(_ghost):
		_ghost_id = armed
		if armed == "camp":
			_ghost = CAMP.new()
			_ghost.name = "CampGhost"
			_ghost.call("build_ghost")
		elif armed == "storage":
			_ghost = STORAGE_CONTAINER.new()
			_ghost.name = "StorageGhost"
			_ghost.call("build_ghost")
		elif armed == "creature_bed":
			_ghost = CREATURE_BED.new()
			_ghost.name = "CreatureBedGhost"
			_ghost.call("build_ghost")
		else:
			var mesh_path := _piece_mesh(game, armed)
			_ghost = BUILD_PIECE.new()
			_ghost.name = "PieceGhost"
			_ghost.call("build_ghost", mesh_path)
		get_parent().add_child(_ghost)

	var forward := -_player.global_transform.basis.z
	if _camera_rig != null and _camera_rig.has_method("planar_basis"):
		forward = -(_camera_rig.call("planar_basis") as Basis).z
	var raw_spot := _player.global_position + forward * PLACE_AHEAD

	var ground := _ground_height(raw_spot)
	if is_nan(ground):
		_ghost.visible = false
		_ghost_ok = false
		_ghost_reason = ""
		_set_overlay_visible(false)
		return

	var resolved := BUILD_GRID.resolve_position(raw_spot, ground, _neighbour_positions(armed))
	var spot: Vector3 = resolved.position
	var snapped_to_neighbour: bool = resolved.snapped_to_neighbour
	if snapped_to_neighbour and not _was_snapped:
		AUDIO_CUES.play(&"build_snap")
	_was_snapped = snapped_to_neighbour

	# Slope check by sampling the corners the bedroll would cover. Skipped
	# when snapped to a neighbour: `spot.y` is already that neighbour's own
	# ground-clamped height, and re-checking raw terrain slope under it would
	# reject the very thing snapping exists for — continuing a wall run over
	# ground that dips slightly from where the first piece sat.
	var rise := 0.0
	if not snapped_to_neighbour:
		for corner: Vector3 in [Vector3(1.2, 0, 0), Vector3(-1.2, 0, 0), Vector3(0, 0, 1.2), Vector3(0, 0, -1.2)]:
			var h := _ground_height(spot + corner)
			if not is_nan(h):
				rise = maxf(rise, absf(h - ground))

	var occupied := _cell_occupied(armed, spot)
	var too_steep := rise > MAX_SLOPE_RISE
	var afford := _can_afford(game, armed)
	_ghost_ok = not too_steep and not occupied and afford
	# OF23: one reason, picked in the order a player would want to hear it —
	# "something is already there" and "the ground won't take it" are about
	# THIS spot and get fixed by moving; "can't afford it" is true everywhere
	# and would drown the other two out if it went first.
	_ghost_reason = ""
	if occupied:
		_ghost_reason = "Something is already here"
	elif too_steep:
		_ghost_reason = "Too steep to build here"
	elif not afford:
		_ghost_reason = "Can't afford this — check the build menu for what's short"
	_ghost.visible = true
	_ghost.global_position = spot
	_ghost.rotation.y = deg_to_rad(_yaw_deg)

	# D34/spec 13: valid (green), invalid (red, nowhere near a neighbour and
	# still blocked), or unsupported (amber, snapped flush against a real
	# neighbour but still blocked by something else — slope, overlap, cost).
	# Falls back to the plain two-state `tint_ghost` for camp/storage's own
	# hand-authored ghosts, which do not implement the three-state call.
	var state := BUILD_PIECE.STATE_VALID
	if not _ghost_ok:
		state = BUILD_PIECE.STATE_UNSUPPORTED if snapped_to_neighbour else BUILD_PIECE.STATE_INVALID
	if _ghost.has_method("tint_ghost_state"):
		_ghost.call("tint_ghost_state", state)
	else:
		_ghost.call("tint_ghost", _ghost_ok)

	_snap_candidates = BUILD_GRID.neighbours_in_range(raw_spot, _neighbour_positions(armed))
	_update_overlay(spot)


## World X/Z positions of every already-placed piece sharing `armed`'s
## catalogue id — the candidate set `build_grid.gd`'s neighbour-snap searches,
## and (via `_cell_occupied`) the exact-overlap check below. Restricted to the
## same id, not every placed piece, so a wall run snaps against other walls
## without a nearby floor tile or fence post pulling it off-line — the literal
## "wall-to-wall, floor-to-floor" the task asks for.
func _neighbour_positions(armed: String) -> Array:
	var out: Array = []
	for node: Node in get_tree().get_nodes_in_group(PLACED_GROUP):
		if node == _ghost:
			continue
		if str(node.get_meta(BUILDING_ID_META, "")) == armed:
			out.append((node as Node3D).global_position)
	return out


## True if a piece of the SAME type already occupies `spot`'s grid cell —
## placing the ghost exactly on top of one it already snapped flush against,
## which `build_grid.gd::resolve_position` deliberately never returns on its
## own but which is still reachable (the raw grid-snap path, no neighbour in
## range, landing on an existing piece's own cell).
func _cell_occupied(armed: String, spot: Vector3) -> bool:
	for pos: Vector3 in _neighbour_positions(armed):
		if absf(pos.x - spot.x) < SAME_CELL_EPSILON and absf(pos.z - spot.z) < SAME_CELL_EPSILON:
			return true
	return false


func _can_afford(game: Node, armed: String) -> bool:
	return game != null and bool(game.call("can_afford", armed))


## The plain node-creation half of placement, shared with `restore_from_game`
## below — spends nothing and does not touch position, so a save restore can
## reuse it without re-charging the satchel for a piece it already paid for.
## `yaw_deg` is applied to the whole node: every stateful piece's own
## sub-parts (`camp.gd`'s fire/bedroll, `storage_container.gd`'s prompt) are
## positioned in ITS local space, so rotating the root carries them with it.
##
## `index` (R3.1-remainder) is this node's future position in
## `GameState.placed_buildings` — stashed as metadata so `sync_state_to_game`
## can find its way back without a position-based search. `state_data`, when
## given, is a stateful piece's own saved payload (a chest's `storage_state
## .save_data()` output) to restore onto the freshly-built node immediately;
## a fresh placement (not a load) always passes null, since there is nothing
## yet to restore.
func _spawn_building(game: Node, id: String, yaw_deg: float = 0.0, index: int = -1, state_data: Variant = null) -> Node3D:
	var placed: Node3D = null
	if id == "camp":
		placed = CAMP.new()
		placed.name = "Camp"
		get_parent().add_child(placed)
		placed.call("build_real")
	elif id == "storage":
		placed = STORAGE_CONTAINER.new()
		placed.name = "Storage"
		get_parent().add_child(placed)
		placed.call("build_real")
		if state_data != null:
			var state: RefCounted = placed.get("state")
			if state != null:
				state.call("load_data", state_data)
	elif id == "creature_bed":
		placed = CREATURE_BED.new()
		placed.name = "CreatureBed"
		get_parent().add_child(placed)
		placed.call("build_real")
	else:
		var mesh_path := _piece_mesh(game, id)
		placed = BUILD_PIECE.new()
		placed.name = "Piece_%s" % id
		get_parent().add_child(placed)
		placed.call("build_real", mesh_path, _piece_light(game, id))
		# The workbench is a crafting STATION now, not scenery. Owner brief:
		# "use the workbench to craft capture orbs, knives, axes, pickaxes" --
		# it was placeable geometry with no interaction at all, which is most
		# of why the owner reported building as not working: the loop's centre
		# piece did nothing. Same Craft prompt the campfire carries (camp.gd's
		# R2.4 pattern), opening the same panel, so "at the campfire or
		# workbench" -- the claim craft_panel.gd has made in its own header
		# since R2.4 -- is finally true rather than half true. Attached here
		# rather than in a new stateful class because a prompt is the ONLY
		# thing the workbench adds over plain geometry; this path also runs on
		# `restore_from_game`, so a loaded bench keeps its prompt for free.
		if id == "workbench":
			var craft_prompt: Node3D = INTERACTABLE.new()
			craft_prompt.name = "CraftInteractable"
			craft_prompt.position = Vector3(0.0, 0.6, 0.9)
			craft_prompt.call("configure", "Craft", 2.6, true)
			craft_prompt.connect("activated", _open_craft_panel)
			placed.add_child(craft_prompt)
	placed.rotation.y = deg_to_rad(yaw_deg)
	placed.set_meta(BUILDING_ID_META, id)
	if index >= 0:
		placed.set_meta(PLACED_INDEX_META, index)
	placed.add_to_group(PLACED_GROUP)
	return placed


## The workbench's half of R2.4's "at the campfire or workbench". One panel
## instance, lazily built, exactly as camp.gd::_on_craft() keeps its own --
## two stations, one screen, zero copies of the recipe logic.
var _craft_panel: CanvasLayer = null


func _open_craft_panel() -> void:
	if _craft_panel == null or not is_instance_valid(_craft_panel):
		_craft_panel = CRAFT_PANEL.new()
		get_tree().root.add_child(_craft_panel)
	_craft_panel.call("open")


func _place(game: Node, armed: String) -> void:
	# Spend first, all-or-nothing; the inventory refuses partial removals.
	var inventory: RefCounted = game.get("inventory")
	for requirement: Variant in (game.call("build_cost_for", armed) as Array):
		var need: Dictionary = requirement
		if not bool(inventory.call("remove", str(need.get("id", "")), int(need.get("n", 0)))):
			push_error("could not spend the cost for '%s' after can_afford said yes" % armed)
			return

	var yaw_deg := _yaw_deg
	# R3.1-remainder: `register_building` below appends, so the size right
	# now is the index the new entry is about to occupy.
	var index := int((game.get("placed_buildings") as Array).size())
	var placed := _spawn_building(game, armed, yaw_deg, index)
	placed.global_position = _ghost.global_position
	# R3.1. The registry, not this node, is what a save actually persists —
	# see GameState.placed_buildings.
	game.call("register_building", armed, placed.global_position, yaw_deg)
	# BUILD-FLOW (owner 2026-08-18): selection persists after a successful
	# placement. The next physics tick moves the same ghost to the next candidate
	# location; costs and registration still happen once per fresh Place edge.
	# Only explicit Cancel or choosing another catalogue entry clears/replaces it.
	AUDIO_CUES.play(&"build_place")


## R3.1. Rebuild everything `GameState.placed_buildings` remembers: called
## once at boot (a no-op the first time a save is ever written, since the
## list starts empty) and again by `GameState.load_game` whenever the player
## loads a slot mid-session. Existing placed pieces are cleared first so a
## mid-session load cannot leave two copies of the same building standing on
## top of each other.
func restore_from_game(game: Node) -> void:
	if game == null:
		return
	for node in get_tree().get_nodes_in_group(PLACED_GROUP):
		node.queue_free()
	var buildings: Array = game.get("placed_buildings") as Array
	for i in buildings.size():
		var entry: Variant = buildings[i]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var record := entry as Dictionary
		var id := str(record.get("id", ""))
		var position: Array = record.get("position", [])
		if id.is_empty() or position.size() != 3:
			continue
		# Absent on a save written before BG1 shipped rotation — see
		# GameState.register_building's own comment on why that is not a
		# version bump.
		var yaw_deg := float(record.get("yaw_deg", 0.0))
		# R3.1-remainder: `record.get("state")` is null for any piece with
		# nothing to restore (every non-storage id, and a storage entry from
		# a save written before this shipped) — `_spawn_building` already
		# treats null as "nothing to restore."
		var placed := _spawn_building(game, id, yaw_deg, i, record.get("state"))
		placed.global_position = Vector3(float(position[0]), float(position[1]), float(position[2]))
		# R3.1 VERSION 2: buildings placed before yaw was tracked default to 0.
		placed.rotation.y = deg_to_rad(float(record.get("yaw_deg", 0.0)))


## R3.1-remainder. The reverse of the `state_data` half of restore: called by
## `GameState.save_game` right before it writes, so a chest's live, currently-
## held contents (`storage_state.gd`, owned by the scene node, never by
## `placed_buildings` itself) land in the record a save actually persists.
## Only pieces this placer itself planted carry `PLACED_INDEX_META`, so a
## piece from a stale or foreign group membership is silently skipped rather
## than guessed at.
func sync_state_to_game(game: Node) -> void:
	if game == null:
		return
	var buildings: Array = game.get("placed_buildings") as Array
	for node in get_tree().get_nodes_in_group(PLACED_GROUP):
		if str(node.get_meta(BUILDING_ID_META, "")) != "storage":
			continue
		var index := int(node.get_meta(PLACED_INDEX_META, -1))
		if index < 0 or index >= buildings.size():
			continue
		var state: RefCounted = node.get("state")
		if state == null:
			continue
		(buildings[index] as Dictionary)["state"] = state.call("save_data")


func _drop_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_ghost_ok = false
	_ghost_reason = ""
	_ghost_id = ""
	_was_snapped = false
	_yaw_deg = 0.0
	_snap_candidates = []
	_set_overlay_visible(false)


func _ground_height(at: Vector3) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", at.x, at.z))
		node = node.get_parent()
	return NAN


# --- D34/spec 13.2-13.4: placement feedback -----------------------------


## Builds the placer's own screen-space overlay (snap dots + the bottom-center
## control strip) on first use. A `CanvasLayer` at `LAYER_WORLD_PANELS` so it
## sits over the 3D world but under any real menu (`UITokens.LAYER_MENU`),
## matching where the placed-piece ghost itself already reads as "in the
## world, not in a menu."
func _ensure_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		return
	_overlay = CanvasLayer.new()
	_overlay.name = "BuildPlacerOverlay"
	_overlay.layer = UITokens.LAYER_WORLD_PANELS
	get_tree().root.add_child(_overlay)

	_snap_dots = Control.new()
	_snap_dots.name = "SnapDots"
	_snap_dots.set_anchors_preset(Control.PRESET_FULL_RECT)
	# HUD-shaped Control over the game world: IGNORE per the house rule
	# (scenes note in this task's own brief) — this never blocks a click.
	_snap_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_snap_dots.draw.connect(_on_snap_dots_draw)
	_overlay.add_child(_snap_dots)

	_hint_label = RichTextLabel.new()
	_hint_label.name = "PlacementHints"
	_hint_label.bbcode_enabled = true
	_hint_label.fit_content = true
	_hint_label.scroll_active = false
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.add_theme_font_size_override("normal_font_size", UITokens.FONT_LABEL)
	UITokens.make_text_legible(_hint_label)
	_overlay.add_child(_hint_label)

	_grid_mesh = MeshInstance3D.new()
	_grid_mesh.name = "BuildGridVisual"
	var mesh := ImmediateMesh.new()
	_grid_mesh.mesh = mesh
	var grid_material := StandardMaterial3D.new()
	grid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_material.vertex_color_use_as_albedo = true
	grid_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_grid_mesh.material_override = grid_material
	get_parent().add_child(_grid_mesh)
	_build_grid_geometry(mesh)


## Line geometry authored ONCE, centred on the mesh's own local origin —
## `_update_overlay` below only ever moves `_grid_mesh`'s transform, never
## rebuilds this, which is what "update its transform when the ghost moves
## cell" (spec 13.3) asks for rather than a per-frame rebuild.
func _build_grid_geometry(mesh: ImmediateMesh) -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var steps := int(ceil(GRID_RADIUS / GRID_MINOR_STEP))
	for i in range(-steps, steps + 1):
		var offset := i * GRID_MINOR_STEP
		if absf(offset) > GRID_RADIUS:
			continue
		# `i` counts GRID_MINOR_STEP steps from center; every other one lands on
		# a whole GRID_MAJOR_STEP line (0.5 * even = a multiple of 1.0).
		var is_major := i % 2 == 0
		var alpha := GRID_MAJOR_ALPHA if is_major else GRID_MINOR_ALPHA
		var colour := UITokens.BUILD_ACCENT if is_major else UITokens.TEAL
		# One line running along X at constant Z=offset, one along Z at
		# constant X=offset — the crosshatch a plan-view grid needs.
		_add_grid_line(mesh, Vector3(-GRID_RADIUS, 0, offset), Vector3(GRID_RADIUS, 0, offset), colour, alpha)
		_add_grid_line(mesh, Vector3(offset, 0, -GRID_RADIUS), Vector3(offset, 0, GRID_RADIUS), colour, alpha)
	mesh.surface_end()


## One line, subdivided so its vertex alpha can fade with distance from the
## mesh's own local origin (spec 13.3's "fading by distance from center") —
## a single two-vertex segment can only interpolate colour along its own
## length, which for a line that PASSES THROUGH the center would fade out at
## one end and back in at the other, never dimming at the center where the
## ghost actually stands.
const _GRID_LINE_SEGMENTS := 12

func _add_grid_line(mesh: ImmediateMesh, a: Vector3, b: Vector3, colour: Color, base_alpha: float) -> void:
	for s in _GRID_LINE_SEGMENTS:
		var t0 := float(s) / _GRID_LINE_SEGMENTS
		var t1 := float(s + 1) / _GRID_LINE_SEGMENTS
		var p0 := a.lerp(b, t0)
		var p1 := a.lerp(b, t1)
		var fade0 := clampf(1.0 - Vector2(p0.x, p0.z).length() / GRID_RADIUS, 0.0, 1.0)
		var fade1 := clampf(1.0 - Vector2(p1.x, p1.z).length() / GRID_RADIUS, 0.0, 1.0)
		mesh.surface_set_color(Color(colour, base_alpha * fade0))
		mesh.surface_add_vertex(p0)
		mesh.surface_set_color(Color(colour, base_alpha * fade1))
		mesh.surface_add_vertex(p1)


## Called every frame a ghost is visible: moves the (already-built) grid mesh
## and the control-strip label into place, and asks the snap-dot layer to
## redraw against this frame's `_snap_candidates`.
func _update_overlay(ghost_spot: Vector3) -> void:
	_ensure_overlay()
	_set_overlay_visible(true)
	_grid_mesh.global_position = Vector3(
		snappedf(ghost_spot.x, BUILD_GRID.GRID_SIZE), ghost_spot.y, snappedf(ghost_spot.z, BUILD_GRID.GRID_SIZE)
	)
	_hint_label.text = _hint_text()
	_position_hint_label()
	_snap_dots.queue_redraw()


func _set_overlay_visible(shown: bool) -> void:
	if _snap_dots != null and is_instance_valid(_snap_dots):
		_snap_dots.visible = shown
	if _hint_label != null and is_instance_valid(_hint_label):
		_hint_label.visible = shown
	if _grid_mesh != null and is_instance_valid(_grid_mesh):
		_grid_mesh.visible = shown


## D34/spec 13.4: bottom-center strip naming the four verbs a ghost responds
## to right now, glyph-first the same way every other control hint in this
## project reads (`input_glyph.gd`).
## OF23: prefixed with WHY the ghost is red when it is — a bare `ui_error` on
## a wasted `build_place` press used to be the only signal a bad spot ever
## gave. `_ghost_reason` is set (or cleared) every frame in `_show_ghost`, so
## this reads correctly the instant the ghost turns red, not only after a
## failed press.
func _hint_text() -> String:
	var controls := "%s Rotate    %s Snap step    %s Place    %s Cancel" % [
		"%s/%s" % [INPUT_GLYPH.icon(ROTATE_LEFT_ACTION, 28), INPUT_GLYPH.icon(ROTATE_RIGHT_ACTION, 28)],
		INPUT_GLYPH.icon(SNAP_CYCLE_ACTION, 28),
		INPUT_GLYPH.icon(PLACE_ACTION, 28),
		INPUT_GLYPH.icon(CANCEL_ACTION, 28),
	]
	if _ghost_reason.is_empty():
		return controls
	return "[color=#%s]%s[/color]    %s" % [UITokens.DANGER.to_html(false), _ghost_reason, controls]


func _position_hint_label() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var width: float = maxf(_hint_label.get_minimum_size().x, _hint_label.size.x)
	_hint_label.position = Vector2((viewport_size.x - width) * 0.5, viewport_size.y - 96.0)


## D34/spec 13.2: 1-4 dots at the neighbour cell centers within snap range,
## the one `resolve_position` would actually snap to drawn brighter (teal)
## than the rest (the panel border colour) — connected to `Control.draw`
## rather than a subclassed `_draw()` so this stays one file, the same
## technique `_snap_dots` itself is wired up with in `_ensure_overlay`.
func _on_snap_dots_draw() -> void:
	if _snap_candidates.is_empty():
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	for i in _snap_candidates.size():
		var pos: Vector3 = _snap_candidates[i]
		if camera.is_position_behind(pos):
			continue
		var screen := camera.unproject_position(pos)
		var colour := UITokens.TEAL if i == 0 else UITokens.BORDER
		_snap_dots.draw_circle(screen, SNAP_DOT_RADIUS, colour)
