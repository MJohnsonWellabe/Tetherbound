extends Node3D

## GAME_DESIGN.md §22: on player death, everything carried drops into a
## satchel at the death location. Old satchels never move and several can
## coexist, so `player_death.gd` spawns a fresh one of these per death rather
## than reusing a single instance.
##
## Reuses `storage_state.gd`/`storage_panel.gd` wholesale — a death satchel
## is "another slot+stack container standing in the world," exactly the shape
## a placed chest (`storage_container.gd`) already is. `set_slot()` rather
## than `add()` because these are the exact stacks the player was carrying,
## durability and all, not a fresh deposit that should re-pack or re-stack.
##
## ## D104/D-MP10, lane 3.C: a satchel belongs to somebody
##
## A satchel carries the character id of the player who died holding it
## (`WorldState.register_death_satchel`'s `owner` field, persisted since lane
## 3.A). Only that player may open it. Anyone else reads the owner's NAME on
## the prompt and, if they press it, is told in one sentence that it is not
## theirs — a shared world where a friend can walk over and empty the bag you
## died carrying is not the shared world this game wants.
##
## An UNOWNED satchel (`owner == ""`) is open to anybody, and that is not a
## hole: it is what every satchel in every save written before this lane is,
## and what a solo player who has never formed a session drops. Solo, the
## owner and the local id are the same string — usually both empty — so the
## check passes and the bag opens exactly as it always has.

const STORAGE_STATE := preload("res://scripts/world/storage_state.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")
const STORAGE_PANEL := preload("res://scripts/ui/storage_panel.gd")
const TRANSFER_RULES := preload("res://scripts/world/death_satchel_rules.gd")
signal storage_changed
signal storage_refused(reason: String)
var _glow_ready := false

func _ready() -> void:
	_connect_transfer_ledger()
	_attach_glow()

func _attach_glow() -> void:
	if is_inside_tree() and state != null and not _glow_ready:
		PICKUP_GLOW.attach(self, SATCHEL_GLOW_COLOUR)
		_glow_ready = true

const MESH_PATH := "res://assets/props/quaternius_fantasy/Bag.gltf"
const MESH_SCALE := 0.6

## The bag's own leather, warmed. A satchel holds whatever the player was
## carrying, so unlike every other pickup it has no single item colour to
## borrow -- and a warm tan is what separates "your dropped bag" from the
## cooler mineral tints the caches and deposits carry.
const SATCHEL_GLOW_COLOUR := Color("#e0a860")

## R3.2. Every death satchel joins this group, the same pattern
## `build_placer.gd`'s `PLACED_GROUP` uses for placed buildings — it is what
## lets `player_death.gd::sync_state_to_game`/`restore_from_game` find every
## live satchel in the scene without `GameState` needing a direct handle on
## each one.
const GROUP := "death_satchel"

## Shared across every satchel the same way `storage_container.gd`'s own
## panel is shared across every chest — one screen, re-pointed at whichever
## container opened it.
##
## Lane 3.C read lane 3.D's finding F4 on the identical pattern in
## `storage_container.gd` and reaches the same verdict for the same reason, and
## one more of its own. `static` is process-global; a process still drives
## exactly ONE local player with one screen, and a second peer is a second
## PROCESS with its own static. The extra reason here: a satchel now refuses
## anyone but its owner, and the ONLY player who can reach `_on_open` in this
## process is the local one — so even a second local player could not open two
## satchels' worth of somebody else's bag through this field. It becomes a real
## hazard the day one process drives two local players (split-screen), where
## two screens would fight over one panel, and it has to become per-player then.
static var _panel: CanvasLayer = null

var state: RefCounted = null

## D104/D-MP10. The character id of the player who dropped this. Empty means
## unowned — a legacy record, or a solo player who has never formed a session —
## and an unowned satchel opens for anybody.
var owner_character_id: String = ""


## `dropped` is `inventory.gd`'s `drain()` result: an ordered Array of
## `{id, n, ...}` stack dicts. `db` is the item database the transfer panel
## needs for names/icons, passed in rather than reached for through
## `/root/Game` so this stays testable headless the way `storage_state.gd` is.
## `owner` is the dropping player's character id (D104/D-MP10). Optional and
## defaulting to "" so every existing caller — and every satchel in a save
## written before this lane — keeps working as an unowned bag.
func build(dropped: Array, db: RefCounted, owner: String = "") -> void:
	owner_character_id = owner
	state = STORAGE_STATE.new(db)
	for i in dropped.size():
		state.inventory.call("set_slot", i, dropped[i])
	_build_visuals()


## R3.2. The load-side counterpart to `build()`: rehydrate a satchel from
## `storage_state.gd::save_data()`'s own output (a full-width array, `null`
## for an empty slot — see that file's header) instead of from a fresh
## `drain()`. `state.load_data` already re-coerces `n`/`durability` back from
## JSON's float-only numbers, so this needs no extra conversion of its own.
func restore(data: Variant, db: RefCounted, owner: String = "") -> void:
	owner_character_id = owner
	state = STORAGE_STATE.new(db)
	state.call("load_data", data)
	_build_visuals()


## OF20: `Bag.gltf` imports as a PackedScene (same pack, same `.import`
## sidecar shape as harvest_node.gd's own models), so `load(MESH_PATH)` handed
## straight to `MeshInstance3D.mesh` was an invalid assignment -- every death
## satchel was invisible. Same PackedScene-vs-Mesh branch as
## `harvest_node.gd::_build_visual` now uses, wrapped in a plain Node3D so
## `.scale` applies to the whole bag.
func _build_visuals() -> void:
	add_to_group(GROUP)
	_connect_transfer_ledger()

	if ResourceLoader.exists(MESH_PATH):
		var resource: Resource = load(MESH_PATH)
		if resource is PackedScene:
			var wrapper := Node3D.new()
			wrapper.add_child((resource as PackedScene).instantiate())
			wrapper.scale = Vector3.ONE * MESH_SCALE
			add_child(wrapper)
		elif resource is Mesh:
			var mesh := MeshInstance3D.new()
			mesh.mesh = resource as Mesh
			mesh.scale = Vector3.ONE * MESH_SCALE
			add_child(mesh)
		else:
			push_warning("death satchel mesh '%s' loaded as neither a Mesh nor a PackedScene" % MESH_PATH)

	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(0.0, 0.5, 0.6)
	# D104/D-MP10. Somebody else's bag says whose it is BEFORE it is pressed.
	# A refusal a player could have read off the prompt is a refusal they
	# should never have had to earn.
	prompt.call("configure", "Open Satchel" if can_open() else "%s's Satchel" % owner_name(),
		2.6, true)
	prompt.connect("activated", _on_open)
	add_child(prompt)

	# OP-0830-3. A death satchel is the one pickup the player is actively
	# HUNTING for, dropped wherever they happened to fall -- which is as likely
	# to be deep cover as open road. The shared highlight
	# (scripts/world/pickup_glow.gd) is what makes it findable; the tint is the
	# bag's own leather rather than an item colour, because a satchel is a
	# container and has no single item to speak for it.
	#
	# Registered AFTER the mesh, not before: `pickup_glow.gd` measures the
	# prop's own crown to decide where the mote sits, and a satchel that had not
	# built its bag yet would measure as flat.
	_attach_glow()


# --- whose bag is this ------------------------------------------------------

## May the player at THIS keyboard open it? True for an unowned satchel and for
## the owner's own; false for anybody else's.
func can_open() -> bool:
	if owner_character_id.is_empty():
		return true
	return owner_character_id == _local_character_id()


## The one sentence a player who is not the owner is given. Kept here rather
## than at the two call sites so the prompt and the refusal can never name
## different people.
func refusal() -> String:
	return "That satchel is %s's — only they can open it." % owner_name()


## The owner's display name, from the session's peer registry (lane 2.A), which
## is the one place a character id can be turned into a person. Falls back to
## "another trainer" for an owner who is not in this session at all: a satchel
## outlives the session it was dropped in, and a save reloaded solo has a
## registry with nobody in it.
func owner_name() -> String:
	if owner_character_id.is_empty():
		return "another trainer"
	var game := get_node_or_null(^"/root/Game")
	var session: Node = game.get("session") as Node if game != null else null
	if session != null and session.has_method("registry"):
		var registry: RefCounted = session.call("registry")
		if registry != null:
			var peer_id := int(registry.call("peer_for_character", owner_character_id))
			if peer_id != 0:
				var shown := str((registry.call("row", peer_id) as Dictionary).get("display_name", ""))
				if not shown.is_empty():
					return shown
	return "another trainer"


## This process's own character id. Read, never minted: `session.gd` mints one
## when a session is formed, and a satchel must not be the thing that decides a
## solo player suddenly has an identity.
func _local_character_id() -> String:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return ""
	var local: Variant = game.get("local")
	if local == null:
		return ""
	return str((local as RefCounted).get("character_id"))


func _on_open() -> void:
	if not can_open():
		var game := get_node_or_null(^"/root/Game")
		if game != null:
			game.call("push_world_message", refusal())
		return
	if _panel == null or not is_instance_valid(_panel):
		_panel = STORAGE_PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open", self)


func submit_deposit(item_id: String, n: int, expected_revision: int = -1) -> Dictionary:
	return _submit_transfer("deposit", item_id, n, expected_revision)

func submit_withdraw(item_id: String, n: int, expected_revision: int = -1) -> Dictionary:
	return _submit_transfer("withdraw", item_id, n, expected_revision)

func _record_uid() -> String:
	var game := get_node_or_null("/root/Game")
	var index := int(get_meta("death_satchel_index", -1))
	if game == null or index < 0 or index >= game.death_satchels.size():
		return ""
	return str(game.death_satchels[index].get("uid", "legacy_satchel_%d" % index))

func _submit_transfer(direction: String, item: String, count: int, expected: int) -> Dictionary:
	if not can_open():
		return _transfer_refused(refusal())
	var game := get_node_or_null("/root/Game")
	var uid := _record_uid()
	if game == null or state == null or uid.is_empty():
		return _transfer_refused("The satchel is not registered in this world.")
	var transport: Node = game.get("ledger")
	var result: Dictionary = transport.call("transfer_satchel", uid, direction, item, count, expected)
	if not result.get("ok", false) and not result.get("pending", false):
		storage_refused.emit(str(result.get("reason", "")))
	return result

func _connect_transfer_ledger() -> void:
	if not is_inside_tree():
		return
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	var transport: Node = game.get("ledger")
	if transport == null:
		return
	if not transport.delta_applied.is_connected(_on_transfer_delta):
		transport.delta_applied.connect(_on_transfer_delta)
	if not transport.intent_refused.is_connected(_on_transfer_refused):
		transport.intent_refused.connect(_on_transfer_refused)

func _on_transfer_delta(delta: Dictionary) -> void:
	for op: Dictionary in delta.get("ops", []):
		if str(op.get("op", "")) != "satchel_set" or str(op.get("uid", "")) != _record_uid():
			continue
		var game := get_node("/root/Game")
		var index: int = game.get("world").call("death_satchel_index_of", _record_uid())
		if index >= 0:
			state.load_data(game.get("death_satchels")[index].get("state", []))
		storage_changed.emit()

func _on_transfer_refused(kind: String, _code: String, reason: String, detail: Dictionary) -> void:
	if kind == "death_satchel_transfer" and str(detail.get("uid", "")) == _record_uid():
		storage_refused.emit(reason)

func _transfer_refused(reason: String) -> Dictionary:
	return {"ok": false, "pending": false, "kind": "death_satchel_transfer", "reason": reason}
