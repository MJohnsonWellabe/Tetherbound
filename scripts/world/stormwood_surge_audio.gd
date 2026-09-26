extends Node

## Realm-scoped audio observer for the Stormwood Surge and its lightning
## (AUDIO §4.3, §9 captions, §12.1 routing). It changes no gameplay: it only
## watches what the Surge and the lightning already do and, for each cue in
## data/config/stormwood_audio.json, appends a row to `cue_log` and plays the
## cue's asset IF that asset exists. Today no Stormwood asset exists, so every
## row records `asset_present: false, played: false`; the same code plays the
## cues once real files land at the contract's paths. No audio is invented.
##
## Owners (AUDIO §8, §12.1 "fires once from the correct owner"):
## - Phase beds follow THIS peer's own presentation of the replicated Surge
##   clock (StormwoodSurge.presentation_key(), at the local trainer's region).
## - Strike cues come only from Session.stormwood_strike_received, the
##   replicated lightning event: the host emits it locally, a client gets it
##   by RPC. No peer infers a strike from its own clock, and each id is
##   de-duplicated, so each warning and impact fires once per peer.
## A simulation-only shell (a host's realm with no local listener) is silent.
##
## Teardown: `_exit_tree` stops every bed this node started (the AudioManager
## pool lives under the tree root and would otherwise outlive the realm),
## disconnects from Session and clears the log.
const CONFIG_PATH := "res://data/config/stormwood_audio.json"
const AUDIO := preload("res://scripts/audio/audio_manager.gd")
const LONG_STORM_ENDED := "stormwood:long_storm_ended"

var config: Dictionary = {}
var world: Node3D
var surge: Node
var session: Node
## One row per fired cue, in firing order.
var cue_log: Array[Dictionary] = []
var _phase := ""
var _released := false
var _bed: Node = null
var _bed_stream: Resource = null
var _warned: Dictionary = {}
var _impacted: Array[int] = []


static func load_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return parsed if parsed is Dictionary else {}


## Every cue definition in the contract, flattened: phase beds, the release
## bed and the four strike-chain layers.
static func all_cues(contract: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for phase: String in (contract.get("phase_cues", {}) as Dictionary):
		var row: Dictionary = contract.phase_cues[phase].duplicate()
		row["source"] = "phase:" + phase
		result.append(row)
	if contract.has("release_cue"):
		var release: Dictionary = contract.release_cue.duplicate()
		release["source"] = "release"
		result.append(release)
	for layer: String in ["warning", "strike", "body", "decay"]:
		var cue: Variant = contract.get("strike_chain", {}).get(layer)
		if cue is Dictionary:
			var row: Dictionary = (cue as Dictionary).duplicate()
			row["source"] = "strike:" + layer
			result.append(row)
	return result


func _ready() -> void:
	config = load_config()
	world = get_parent() as Node3D
	if world == null or bool(world.get("simulation_only")):
		set_process(false)
		return
	surge = world.get_node_or_null("StormwoodSurge")
	session = get_node_or_null("/root/Game/Session")
	if session != null and session.has_signal("stormwood_strike_received"):
		session.stormwood_strike_received.connect(_on_strike)


func _process(_delta: float) -> void:
	if surge == null or not is_instance_valid(surge):
		return
	# The Surge sets its presentation key in its own _process (it is mounted
	# before this node, so it has run this frame); wait for its first one.
	if str(surge.get("_last_phase")).is_empty():
		return
	var key := str(surge.call("presentation_key"))
	if key.begins_with("aftermath:"):
		if not _released:
			_released = true
			_phase = key.trim_prefix("aftermath:")
			_start_bed(config.get("release_cue", {}), _phase)
		return
	if key == _phase:
		return
	_phase = key
	var cue: Variant = config.get("phase_cues", {}).get(key)
	if cue is Dictionary:
		_start_bed(cue, key)


func _on_strike(event: Dictionary) -> void:
	if not is_inside_tree():
		return
	var id := int(event.get("id", -1))
	var kind := str(event.get("kind", ""))
	var at: Variant = event.get("at")
	if not at is Vector3:
		return
	var chain: Dictionary = config.get("strike_chain", {})
	if kind == "warning":
		if _warned.has(id) or _impacted.has(id):
			return
		_warned[id] = true
		_fire(chain.get("warning", {}), at, id)
	elif kind == "impact":
		if _impacted.has(id):
			return
		_impacted.append(id)
		_warned.erase(id)
		if _impacted.size() > 256:
			_impacted.pop_front()
		for layer: String in ["strike", "body", "decay"]:
			_fire(chain.get(layer, {}), at, id)


func _start_bed(cue: Dictionary, phase: String) -> void:
	_stop_bed()
	var player: Node = _fire(cue, null, -1, phase)
	if player != null:
		_bed = player
		_bed_stream = player.get("stream")


func _stop_bed() -> void:
	# The pool reuses players; stop only one still carrying this bed's stream.
	if is_instance_valid(_bed) and _bed.get("stream") == _bed_stream:
		_bed.call("stop")
	_bed = null
	_bed_stream = null


## Log one cue and play it only if its asset exists. Returns the player.
func _fire(cue: Dictionary, at: Variant, strike_id: int, phase: String = "") -> Node:
	if cue.is_empty():
		return null
	var path := str(cue.get("asset_path", ""))
	var present := not path.is_empty() and ResourceLoader.exists(path)
	var positional := bool(cue.get("positional", false)) and at is Vector3
	var player: Node = null
	if present:
		if positional:
			player = AUDIO.play_file_at(path, str(cue.id), at, str(cue.get("bus", "SFX")))
		else:
			player = AUDIO.play_file(path, str(cue.id), str(cue.get("bus", "SFX")))
	cue_log.append({
		"cue": str(cue.get("id", "")),
		"phase": phase if not phase.is_empty() else _phase,
		"aftermath": _released,
		"strike_id": strike_id,
		"t_msec": Time.get_ticks_msec(),
		"surge_clock_s": surge_clock(),
		"position": [at.x, at.y, at.z] if at is Vector3 else null,
		"bus": str(cue.get("bus", "")),
		"positional": bool(cue.get("positional", false)),
		"asset_path": path,
		"asset_present": present,
		"played": player != null,
		"caption": _caption(str(cue.get("caption", "")), at),
	})
	return player


## The replicated Surge clock (seconds), or -1 when unavailable.
func surge_clock() -> float:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return -1.0
	var storm: Variant = (game.get("realm_environment") as Dictionary).get("stormwood", {})
	var raw: Variant = storm.get("elapsed", -1.0) if storm is Dictionary else -1.0
	return float(raw) if raw is float or raw is int else -1.0


## §9 direction wedge relative to the local trainer's facing.
func _caption(text: String, at: Variant) -> String:
	if not text.contains("{direction}"):
		return text
	var player: Node3D = null
	if world != null:
		player = world.get_node_or_null("Player") as Node3D
	var direction := "nearby"
	if at is Vector3 and player != null:
		var offset: Vector3 = (at as Vector3) - player.global_position
		offset.y = 0.0
		var dirs: Dictionary = config.get("caption_directions", {})
		if offset.length() > float(dirs.get("near_m", 4.0)):
			var forward := -player.global_basis.z
			forward.y = 0.0
			var right := player.global_basis.x
			right.y = 0.0
			var ahead := offset.normalized().dot(forward.normalized())
			var side := offset.normalized().dot(right.normalized())
			if absf(ahead) >= absf(side):
				direction = "ahead" if ahead >= 0.0 else "behind"
			else:
				direction = "right" if side >= 0.0 else "left"
	return text.replace("{direction}", direction)


func _exit_tree() -> void:
	_stop_bed()
	if session != null and is_instance_valid(session) \
			and session.stormwood_strike_received.is_connected(_on_strike):
		session.stormwood_strike_received.disconnect(_on_strike)
	cue_log.clear()
	_warned.clear()
	_impacted.clear()
	_phase = ""
	_released = false
