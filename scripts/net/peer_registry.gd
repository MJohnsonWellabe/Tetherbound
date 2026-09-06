extends RefCounted

## Stage B Wave 2 lane 2.A. WHO IS IN THIS SESSION.
##
## Host-authoritative: only the host mutates rows; every change is replicated
## WHOLE (`save_data()` -> `load_data()`), never as a delta. A registry is four
## short rows at most (D95's peer cap is 4), so a delta protocol would cost more
## to get wrong than the whole payload costs to send.
##
## Pure `RefCounted` on purpose, exactly like `world_state.gd` /
## `player_state.gd`: no `Node`, no `multiplayer.`, no signals. `session.gd`
## owns the transport and does the emitting; this file only knows the mapping
##
##     peer id  <->  character id  <->  display name  <->  realm
##
## plus the two Wave 4/5 placeholder flags (`sleeping` for D105's sleep vote,
## `downed` for the revive window). They are stored and replicated from today so
## the later waves add behaviour rather than a new field on the wire.
##
## ## Peer ids are not small
##
## `ralph/reports/MP-0C-SPIKE-ENET-0905/REPORT.md` finding 2: ENet hands clients
## large random 32-bit ids (`2098775056`, `1519229912`); only the listen server
## is a small number (1). Nothing here assumes an order, a range, or a density
## -- rows are keyed by the real id and `rows()` sorts by it purely so two peers
## hash the same list in the same order.

## The host's own id under Godot's high-level multiplayer. Not a guess: the
## server end of an `ENetMultiplayerPeer` is always 1.
const HOST_PEER_ID := 1

## peer_id:int -> row Dictionary. Never handed out by reference; every accessor
## duplicates, so a caller cannot mutate the registry by holding a row.
var _rows: Dictionary = {}

## Bumped on every mutation, the same "did anything move" counter
## `world_state.gd` keeps. `session.gd` replicates when this changes.
var revision: int = 0


## A row with every field present, whatever the caller left out. One shape,
## always -- a replicated row with a missing key is the kind of thing that
## reads fine on the host and crashes a client three waves later.
static func make_row(peer_id: int, character_id: String = "", display_name: String = "",
		realm: String = "meadows") -> Dictionary:
	return {
		"peer_id": peer_id,
		"character_id": character_id,
		"display_name": display_name,
		"realm": realm,
		"sleeping": false,
		"downed": false,
	}


## Add or overwrite a peer's row. Returns the stored row.
##
## Rejoin (deliverable 4's half that Wave 2 can honestly do today): when
## `character_id` is already present under a DIFFERENT peer id, that old row is
## dropped first and its realm carried onto the new one, so a client whose
## socket died and reconnected resumes where its character was rather than
## appearing twice.
func add(peer_id: int, character_id: String = "", display_name: String = "",
		realm: String = "meadows") -> Dictionary:
	var carried_realm := realm
	if not character_id.is_empty():
		var previous := peer_for_character(character_id)
		if previous != 0 and previous != peer_id:
			carried_realm = str((_rows[previous] as Dictionary).get("realm", realm))
			_rows.erase(previous)
	var row := make_row(peer_id, character_id, display_name, carried_realm)
	_rows[peer_id] = row
	revision += 1
	return row.duplicate(true)


func remove(peer_id: int) -> bool:
	if not _rows.has(peer_id):
		return false
	_rows.erase(peer_id)
	revision += 1
	return true


func clear() -> void:
	_rows.clear()
	revision += 1


func has(peer_id: int) -> bool:
	return _rows.has(peer_id)


func size() -> int:
	return _rows.size()


func row(peer_id: int) -> Dictionary:
	if not _rows.has(peer_id):
		return {}
	return (_rows[peer_id] as Dictionary).duplicate(true)


## Every row, ordered by peer id. The order is the point: two peers comparing
## registries compare `fingerprint()`, and an unordered `Dictionary.values()`
## would hash differently on two processes holding identical data.
func peer_ids() -> Array:
	var ids: Array = _rows.keys()
	ids.sort()
	return ids


func rows() -> Array:
	var out: Array = []
	for id in peer_ids():
		out.append((_rows[id] as Dictionary).duplicate(true))
	return out


## The peer currently holding `character_id`, or 0 -- never -1: `0` is
## `MultiplayerPeer`'s own "no peer" value and the only id ENet will never
## assign, so it is the honest sentinel here too.
func peer_for_character(character_id: String) -> int:
	if character_id.is_empty():
		return 0
	for id: int in _rows.keys():
		if str((_rows[id] as Dictionary).get("character_id", "")) == character_id:
			return id
	return 0


func set_realm(peer_id: int, realm: String) -> bool:
	return _set_field(peer_id, "realm", realm)


## `sleeping` (D105's vote) / `downed` (Wave 5). Nothing in Wave 2 reads them;
## they exist so the wire shape does not change when those waves land.
func set_flag(peer_id: int, key: String, value: bool) -> bool:
	if key != "sleeping" and key != "downed":
		return false
	return _set_field(peer_id, key, value)


func _set_field(peer_id: int, key: String, value: Variant) -> bool:
	if not _rows.has(peer_id):
		return false
	var r: Dictionary = _rows[peer_id]
	if r.get(key) == value:
		return false
	r[key] = value
	revision += 1
	return true


## The whole registry, as it goes on the wire and into a report.
func save_data() -> Dictionary:
	return {"revision": revision, "rows": rows()}


## Replace everything. Tolerant of every missing key, the same contract
## `world_state.gd::load_data()` gives `save_game.gd`: a malformed replication
## payload leaves an EMPTY registry rather than a half-applied one, because a
## half-applied registry is indistinguishable from a real disagreement.
func load_data(data: Dictionary) -> void:
	_rows.clear()
	var raw: Variant = data.get("rows", [])
	if typeof(raw) == TYPE_ARRAY:
		for entry: Variant in (raw as Array):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var e: Dictionary = entry
			var id := int(e.get("peer_id", 0))
			if id == 0:
				continue
			var r := make_row(id, str(e.get("character_id", "")),
				str(e.get("display_name", "")), str(e.get("realm", "meadows")))
			r["sleeping"] = bool(e.get("sleeping", false))
			r["downed"] = bool(e.get("downed", false))
			_rows[id] = r
	revision = int(data.get("revision", revision + 1))


## What two peers compare to say "our registries agree". Deliberately NOT
## `revision`: two peers can hold identical rows having taken different numbers
## of steps to get there (the host counted its own join; a client that joined
## late did not), and comparing bookkeeping instead of content would report a
## disagreement that is not one. `hash()` of the ordered rows is the content.
func fingerprint() -> int:
	return hash(JSON.stringify(rows(), "", true))
