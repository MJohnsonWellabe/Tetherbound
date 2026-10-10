extends Node

## Mounted once by the ordinary objective beacon. No reward, level, travel,
## inventory or save-writer ownership. Personal acknowledgements use the
## existing ledger flag operation and normal character save lifecycle.
const RULES := preload("res://scripts/onboarding/lesson_rules.gd")
const PANEL := preload("res://scripts/onboarding/lesson_panel.gd")
const OWNER := preload("res://scripts/ui/input_owner.gd")
const HOLD := preload("res://scripts/ui/presentation_hold.gd")
var _panel: CanvasLayer
var _identity := ""
var _realm := ""
var _pending: Dictionary = {}
var _retry_at := 0
var _replay := ""
var _replaying := false

static func attach(game: Node) -> Node:
	if game == null: return null
	var existing := game.get_node_or_null("OnboardingLessons")
	if existing != null: return existing
	var service := new()
	service.name = "OnboardingLessons"
	game.add_child(service)
	return service

func _ready() -> void:
	_panel = PANEL.new()
	add_child(_panel)
	_panel.connect("dismissed", _dismissed)
	var game := get_parent()
	if game.has_signal("portal_action_result"):
		game.connect("portal_action_result", _arrival_result)

func _player() -> RefCounted:
	return get_parent().get("local")

func _process(_delta: float) -> void:
	if RULES.config().get("enabled") != true: return
	var player := _player()
	if player == null: return
	var identity := str(player.get("character_id"))
	if identity != _identity:
		# Closing a departing character's card must never acknowledge it for
		# the new character. The dismissal callback checks this binding too.
		_pending.clear()
		_replay = ""
		if _panel.call("is_open"): _panel.call("close", false)
		_identity = identity
	var realm := str(get_parent().get("current_realm"))
	if realm != _realm:
		# Leaving the teacher is not a dismissal or a personal lesson receipt.
		if _panel.call("is_open"): _panel.call("close", false)
		_replay = ""
		_realm = realm
	if not _pending.is_empty():
		_flush_receipts()
		return
	if not _world_free(): return
	var row: Dictionary = {}
	_replaying = not _replay.is_empty()
	if _replaying:
		for candidate: Dictionary in RULES.config().get("lessons", []):
			if candidate.id == _replay: row = candidate.duplicate(true)
	else:
		# A missed Grandpa lesson must not silence Tam when his own system
		# unlocks. Preserve authored order among teachers actually present.
		for due_candidate: Dictionary in RULES.config().get("lessons", []):
			var id := str(due_candidate.id)
			if player.get("flags").call("has", RULES.PREFIX + id) == true: continue
			if RULES.available(id, player) and _teacher_near(due_candidate):
				row = due_candidate.duplicate(true)
				break
	if row.is_empty() or not _teacher_near(row): return
	row = RULES.lesson(row, player)
	# Content lives with its installed speaker's dialogue, with no reward effects.
	var dialogue: Variant = preload("res://scripts/data/redesign_data.gd").json(str(row.dialogue_path))
	var conversation: Dictionary = dialogue.get("conversations", {}).get(str(row.conversation), {}) if dialogue is Dictionary else {}
	row["speaker"] = str(conversation.get("speaker", ""))
	row["lines"] = conversation.get("lines", [])
	if _panel.call("open", row): _replay = ""

func _world_free() -> bool:
	if get_tree().paused or OWNER.current(get_tree()) != null or HOLD.active(get_tree()): return false
	var game := get_parent()
	var session: Node = game.get("session")
	if session == null or session.call("snapshot_ready") != true: return false
	var scene := get_tree().current_scene
	var combat := scene.get_node_or_null("CombatManager") if scene != null else null
	if combat != null and combat.has_method("is_fighting") and combat.call("is_fighting") == true: return false
	return game.call("find_player") != null

func _teacher_near(row: Dictionary) -> bool:
	if _replaying: return true
	var game := get_parent()
	if str(game.get("current_realm")) != "meadows": return false
	var actor: Node3D = game.call("find_player")
	var scene := get_tree().current_scene
	var teacher: Node3D = scene.find_child(str(row.get("teacher_node", "")), true, false) as Node3D if scene != null else null
	if actor == null or teacher == null: return false
	return actor.global_position.distance_to(teacher.global_position) <= float(row.get("radius_m", 5.0))

func replay(id: String) -> bool:
	if RULES.config().get("enabled") != true or not RULES.available(id, _player()): return false
	_replay = id
	return true

func _dismissed(id: String) -> void:
	var player := _player()
	if player == null or str(player.get("character_id")) != _identity or _replaying: return
	_pending[RULES.PREFIX + id] = true
	_retry_at = 0
	_flush_receipts()

func _flush_receipts() -> void:
	var player := _player()
	if player == null or str(player.get("character_id")) != _identity: return
	for flag: String in _pending.keys():
		if player.get("flags").call("has", flag) == true: _pending.erase(flag)
	if _pending.is_empty() or Time.get_ticks_msec() < _retry_at: return
	_retry_at = Time.get_ticks_msec() + 3000
	var ledger: Node = get_parent().get("ledger")
	if ledger == null: return
	for flag: String in _pending.keys():
		# Omit peers: the authenticated submitter is the sole recipient.
		ledger.call("submit", {"kind": "grant_player_flag", "realm": "meadows", "id": flag})

func _arrival_result(result: Dictionary) -> void:
	# Only the authenticated, saved grounded arrival qualifies as a home return.
	# A permit or mere `ok` must never stand in for a completed Home Key trip.
	if RULES.config().get("enabled") != true or result.get("kind") != "home_key_finish" \
			or result.get("ok") != true or result.get("arrival_applied") != true \
			or result.get("durable") != true: return
	var player := _player()
	if player == null or str(player.get("character_id")) != _identity or not RULES.available("home_key", player): return
	_pending[RULES.PREFIX + "trigger:home_return"] = true
	_retry_at = 0
	_flush_receipts()
