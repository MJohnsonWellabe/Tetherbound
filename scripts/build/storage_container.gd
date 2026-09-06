extends Node3D

## R2.7. A placed storage chest: `build_piece.gd`'s generic geometry, plus a
## real, independent inventory (`storage_state.gd`) and an interact prompt
## that opens the transfer panel — one of several `buildables.json` entries
## that carry state, so it gets its own hand-authored script the same way
## `campfire.gd`/`player_bed.gd`/`camp_tent.gd` do, rather than teaching
## `build_piece.gd` to sometimes have state and sometimes not.
##
## ## D103, lane 3.D: two players share this chest
##
## A deposit is no longer a write this node makes. It is a `storage_txn` INTENT
## submitted to `Game.ledger`, quoting the revision this peer last saw for this
## container; the host commits exactly one write per revision and refuses the
## rest with `stale_revision`. The committed contents come back as a delta and
## are loaded here — on the host and on every client, through the same
## `_on_delta_applied` — so nobody's deposit is silently overwritten by
## somebody else's stale copy of the chest.
##
## Solo is not a second path: solo IS the host, `submit()` commits in-process,
## the delta is emitted before `submit()` returns, and the chest ends up holding
## exactly what it held before this lane existed.
##
## The revision is READ from `WorldLedger.storage_revision()` and quoted back,
## never counted here: revisions are session-scoped and deliberately not
## persisted (lane 3.A), and a private counter carried across a reload would
## refuse the first honest write after every load.

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const STORAGE_STATE := preload("res://scripts/world/storage_state.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const STORAGE_PANEL := preload("res://scripts/ui/storage_panel.gd")

const MESH_PATH := "res://assets/props/quaternius_fantasy/Crate_Wooden.gltf"

## The metadata `build_placer.gd` stamps on every piece it plants: this node's
## index into `GameState.placed_buildings`, and the realm the record belongs
## to. Read here rather than duplicated, so the container key a peer quotes is
## derived from the same record on every process.
const PLACED_INDEX_META := "placed_index"
const REALM_META := "realm"

## Not owned per-instance: one panel node is reused and re-pointed at
## whichever chest opened it, the same one-instance-built-lazily pattern
## campfire.gd uses for its own craft panel.
##
## Still correct under Stage B: `static` is process-global, and a process still
## holds exactly ONE local player with one screen. A second peer is a second
## PROCESS with its own static. The day one process drives two local players
## (split-screen), this becomes a real hazard and has to become per-player —
## see ralph/reports/MP-3D-STORAGE-0906/REPORT.md.
static var _panel: CanvasLayer = null

## The committed contents changed (a delta landed, or this peer's own write
## committed in-process). The open panel redraws from this rather than polling.
signal storage_changed

## The ledger said no, with one sentence a player can act on.
signal storage_refused(reason: String)

var state: RefCounted = null

var _piece: Node3D = null

## The write this peer has outstanding with the host, while a client waits for
## an answer: `{"revision", "direction", "item", "moved", "state"}`. Empty
## whenever nothing is in flight. NOTHING local changes while it is set — the
## panel must never show a deposit that has not committed.
var _pending: Dictionary = {}

## The last pending write this peer settled off an arriving delta, kept only
## until the next submit. It is the undo record for the one case a
## `storage_set` delta cannot be told apart from somebody else's: see
## `_resolve_pending`.
var _settled: Dictionary = {}


func _ready() -> void:
	_connect_ledger()


func build_ghost() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.call("build_ghost", MESH_PATH)


func build_real() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.call("build_real", MESH_PATH)

	var game := get_node_or_null(^"/root/Game")
	var db: RefCounted = game.get("items") if game != null else null
	state = STORAGE_STATE.new(db)
	_connect_ledger()

	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(0.0, 0.6, 0.7)
	prompt.call("configure", "Open Storage", 2.6, true)
	prompt.connect("activated", _on_open)
	add_child(prompt)


## Legal (green) or not (red), at ghost alpha either way — delegated to the
## same build_piece.gd every other non-camp entry uses.
func tint_ghost(ok: bool) -> void:
	if _piece != null and is_instance_valid(_piece):
		_piece.call("tint_ghost", ok)


func _on_open() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = STORAGE_PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open", self)


# --- identity ------------------------------------------------------------------

## The realm this chest's RECORD belongs to, off the node's own metadata — not
## `Game.current_realm` (D97). Two peers can stand in two realms at once; the
## realm an intent is stamped with must come from the thing being written, and
## a chest only ever exists in the realm it was planted in.
func realm() -> String:
	return str(get_meta(REALM_META, "meadows"))


## This chest's index into `GameState.placed_buildings`, or -1 for a chest no
## placer planted (a ghost, or a test fixture).
func placed_index() -> int:
	return int(get_meta(PLACED_INDEX_META, -1))


## The key every peer quotes for this chest's revision. Derived from the
## record's STABLE uid, so two processes looking at the same chest name it the
## same thing without exchanging an id of their own -- and, unlike the index
## this used to use, keep naming it the same thing after somebody dismantles a
## structure below it. Under index addressing a chest inherited the revision
## counter of whatever key it renumbered onto, and its owner met a spurious
## "someone else changed that container" on the next honest write.
func container_key() -> String:
	return container_key_for(realm(), building_uid())


## This chest's stable record id, or "" for a chest no placer planted.
func building_uid() -> String:
	var index := placed_index()
	if index < 0:
		return ""
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return ""
	var buildings: Variant = game.get("placed_buildings")
	if not (buildings is Array) or index >= (buildings as Array).size():
		return ""
	var record: Variant = (buildings as Array)[index]
	return str((record as Dictionary).get("uid", "")) if record is Dictionary else ""


static func container_key_for(container_realm: String, uid: String) -> String:
	return "storage:%s:%s" % [container_realm, uid]


# --- the two transfers ------------------------------------------------------------

## Put `n` of `item_id` in. Returns `world_ledger.gd`'s verdict shape: `ok` when
## it committed here and now (solo or host), `pending` when the host has still
## to answer, and otherwise a refusal whose `reason` is one sentence to show.
##
## `expected_revision` is the revision the CALLER saw, for a caller that read it
## earlier than this call -- that is what optimistic concurrency is quoting, and
## a caller who looked at the chest a moment ago should quote what it looked
## like then. `-1` (the panel's case, and every solo press) means "read it now".
func submit_deposit(item_id: String, n: int, expected_revision: int = -1) -> Dictionary:
	return _submit("deposit", item_id, n, expected_revision)


## Take `n` of `item_id` back out. Same verdict shape, same rules.
func submit_withdraw(item_id: String, n: int, expected_revision: int = -1) -> Dictionary:
	return _submit("withdraw", item_id, n, expected_revision)


func _submit(direction: String, item_id: String, n: int, expected_revision: int = -1) -> Dictionary:
	var game := get_node_or_null(^"/root/Game")
	if game == null or state == null:
		return _refusal("The world is not ready yet.")
	var player_inventory: RefCounted = game.get("inventory")
	var transport: Node = game.get("ledger") as Node
	if player_inventory == null or transport == null:
		return _refusal("The world is not ready yet.")
	# A new write ends the undo window on the previous one.
	_settled = {}

	# Work out what the chest WOULD hold, without touching either side: until
	# the ledger commits, nothing here has moved.
	var preview: Dictionary = state.call("preview_" + direction, player_inventory, item_id, n)
	var moved := int(preview.get("moved", 0))
	if moved <= 0:
		# Nothing would move (the satchel is short, or the chest is full).
		# `deposit()`'s own all-or-nothing contract, not an error to shout at
		# the player about.
		return _refusal("")

	var container := container_key()
	var expected := expected_revision if expected_revision >= 0 \
		else _storage_revision(transport, container)
	var verdict: Dictionary = transport.call("submit", {
		"kind": "storage_txn",
		"realm": realm(),
		"container": container,
		"index": placed_index(),
		"uid": building_uid(),
		"expected_revision": expected,
		"state": preview.get("state", []),
	})

	if bool(verdict.get("ok", false)):
		# Host or solo: `submit()` already emitted the delta, so this chest is
		# holding the committed contents. All that is left is this player's own
		# half of the move, which no delta carries — `storage_set` addresses the
		# container, never a satchel.
		_settle(direction, item_id, moved, player_inventory)
		storage_changed.emit()
		return verdict

	if bool(verdict.get("pending", false)):
		# A client, waiting on the host. Change NOTHING: `delta_applied`
		# resolves this, `intent_refused` cancels it.
		_pending = {
			"revision": expected, "direction": direction, "item": item_id,
			"moved": moved, "state": preview.get("state", []),
		}
		return verdict

	storage_refused.emit(str(verdict.get("reason", "")))
	return verdict


## This player's own half of a committed move. The chest's half rides the
## delta; a satchel is per-peer and no peer can write another's, which is why
## `world_ledger.gd` deliberately keeps inventories out of `storage_txn`.
func _settle(direction: String, item_id: String, moved: int, player_inventory: RefCounted) -> void:
	if moved <= 0 or player_inventory == null:
		return
	if direction == "deposit":
		player_inventory.call("remove", item_id, moved)
	else:
		player_inventory.call("add", item_id, moved)


# --- the ledger conversation --------------------------------------------------------

func _connect_ledger() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	var transport: Node = game.get("ledger") as Node
	if transport == null:
		return
	if not transport.is_connected("delta_applied", _on_delta_applied):
		transport.connect("delta_applied", _on_delta_applied)
	if not transport.is_connected("intent_refused", _on_intent_refused):
		transport.connect("intent_refused", _on_intent_refused)


## A committed delta landed. Every peer runs this, host included, so the chest
## on screen and the chest in `placed_buildings` cannot drift apart.
func _on_delta_applied(delta: Dictionary) -> void:
	if state == null:
		return
	var mine := container_key()
	var changed := false
	for raw: Variant in (delta.get("ops", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var op := raw as Dictionary
		if str(op.get("op", "")) != "storage_set" or str(op.get("container", "")) != mine:
			continue
		state.call("load_data", op.get("state", []))
		changed = true
		_resolve_pending(op)
	if changed:
		storage_changed.emit()


## Did the write this peer is waiting on turn out to be the one that committed?
##
## The host commits exactly one write per revision, so a `storage_set` at
## `expected + 1` is THE winner for the revision we quoted. Comparing the
## committed contents against what we asked for is what tells us whether that
## winner was us: a delta at our revision carrying somebody else's contents
## means we lost, and our satchel must stay exactly as it is — the refusal is
## already on its way.
func _resolve_pending(op: Dictionary) -> void:
	if _pending.is_empty():
		return
	if int(op.get("revision", 0)) != int(_pending.get("revision", -1)) + 1:
		return
	var committed: Variant = op.get("state", [])
	if not _same_contents(committed, _pending.get("state", [])):
		_pending = {}
		return
	var game := get_node_or_null(^"/root/Game")
	if game != null:
		_settle(str(_pending.get("direction", "")), str(_pending.get("item", "")),
			int(_pending.get("moved", 0)), game.get("inventory") as RefCounted)
	# Kept as an undo record. Two peers depositing the SAME item and count from
	# the same revision produce byte-identical contents, and `storage_set`
	# carries no submitter and no `txn_id`, so the test above cannot tell that
	# apart -- the loser would settle as if it had won and its items would
	# simply cease to exist. The host still sends the loser a refusal, which
	# arrives moments later and is unambiguous, so a refusal that lands on an
	# already-settled write puts the satchel back (`_on_intent_refused`). The
	# clean fix is a `txn_id` on the op; that is lane 3.A's file, and the
	# handover is in ralph/reports/MP-3D-STORAGE-0906/REPORT.md.
	_settled = _pending
	_pending = {}


## The host refused an intent. `_rpc_verdict` only reaches the peer whose
## intent it was, so a refusal here is always ours — and only the chest with a
## write in flight has anything to drop.
func _on_intent_refused(kind: String, _code: String, reason: String) -> void:
	if kind != "storage_txn":
		return
	if not _pending.is_empty():
		# Nothing was settled: the satchel and the chest are untouched, which
		# is exactly what "change nothing until it commits" bought.
		_pending = {}
		storage_refused.emit(reason)
		return
	if _settled.is_empty():
		return
	# A refusal for a write this peer already settled off an ambiguous delta.
	# Put the satchel back the way the player left it.
	var game := get_node_or_null(^"/root/Game")
	if game != null:
		_settle("withdraw" if str(_settled.get("direction", "")) == "deposit" else "deposit",
			str(_settled.get("item", "")), int(_settled.get("moved", 0)),
			game.get("inventory") as RefCounted)
	_settled = {}
	storage_refused.emit(reason)


## The revision this peer must quote next for `container`. Read off the live
## `WorldLedger`, never counted locally. A transport whose ledger has not been
## built yet has seen no writes, which is the same thing revision 0 means.
func _storage_revision(transport: Node, container: String) -> int:
	var book: Variant = transport.get("ledger")
	if book == null:
		return 0
	return int((book as RefCounted).call("storage_revision", container))


## Two `save_data()` arrays holding the same stacks in the same slots. Compared
## field by field rather than with `==` because a stack that crossed the wire
## came back through JSON, where every `n` is a float.
static func _same_contents(a: Variant, b: Variant) -> bool:
	if typeof(a) != TYPE_ARRAY or typeof(b) != TYPE_ARRAY:
		return false
	var left := a as Array
	var right := b as Array
	if left.size() != right.size():
		return false
	for i in left.size():
		var l: Variant = left[i]
		var r: Variant = right[i]
		var l_empty := typeof(l) != TYPE_DICTIONARY
		var r_empty := typeof(r) != TYPE_DICTIONARY
		if l_empty != r_empty:
			return false
		if l_empty:
			continue
		var ld := l as Dictionary
		var rd := r as Dictionary
		if str(ld.get("id", "")) != str(rd.get("id", "")):
			return false
		if int(ld.get("n", 0)) != int(rd.get("n", 0)):
			return false
		if int(ld.get("durability", -1)) != int(rd.get("durability", -1)):
			return false
		if int(ld.get("durability_bonus", -1)) != int(rd.get("durability_bonus", -1)):
			return false
	return true


func _refusal(reason: String) -> Dictionary:
	return {
		"ok": false, "kind": "storage_txn", "peer": 0, "code": "offline",
		"reason": reason, "pending": false, "delta": {"seq": 0, "realm": "", "ops": []},
	}
