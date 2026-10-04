extends "res://scripts/ui/system_screen.gd"

## F42 presentation over F43 bounty_board.view() and the canonical action
## producer. No accept step, rotation, payout, delivery debit or save here.
## Binds F43 bounty_interaction_adapter's view/claim/reconcile methods and
## action_completed signal. Pending recovery belongs to that producer.
var _source: Node
var _waiting := false
var _durable := false
var _claim_context: Dictionary = {}

static func attach(adapter: Node) -> CanvasLayer:
	if config().get("enabled") != true or not is_instance_valid(adapter): return null
	if not adapter.has_signal("open_requested"): return null
	var existing := adapter.get_node_or_null(^"BountyBoardPanel")
	if existing is CanvasLayer: return existing
	var panel: CanvasLayer = load("res://scripts/ui/bounty_board_panel.gd").new()
	panel.name = "BountyBoardPanel"
	adapter.add_child(panel)
	adapter.connect("open_requested", panel.call("open_requested_callback"))
	return panel

func open_requested_callback() -> Callable:
	return _on_open_requested

func _on_open_requested(_view: Dictionary, adapter: Node) -> void:
	open(adapter)

func open(board: Node) -> bool:
	if config().get("enabled") != true or not is_instance_valid(board) or (_waiting and board != _source): return false
	if _waiting and _claim_context != character_context(get_node_or_null(^"/root/Game")): return false
	for method: String in ["view", "claim", "reconcile"]:
		if not board.has_method(method): return false
	if not board.has_signal("action_completed"): return false
	if is_instance_valid(_source) and _source != board and _source.is_connected("action_completed", present_result):
		_source.disconnect("action_completed", present_result)
	_source = board
	if not board.is_connected("action_completed", present_result): board.connect("action_completed", present_result)
	if not begin("Bounty board", "A Claim / Deliver · B Leave · New bounties at dawn"): return false
	_rebuild()
	return true

func _rebuild() -> void:
	var focus := clear_body()
	var raw: Variant = _source.call("view")
	if not raw is Dictionary or raw.get("ready") != true or not raw.get("rows") is Array \
			or raw.rows.size() != 3:
		status.text = "The board is waiting for the host's morning update."
		finish()
		return
	status.text = "Waiting for the host to save the original claim." if _waiting else "All three bounties are active for your character. New bounties at dawn."
	for row: Dictionary in raw.rows:
		var instance := str(row.get("instance", ""))
		line(body, "%s · %s" % [str(row.get("kind", "")).replace("_", " ").capitalize(), str(row.get("biome", "")).capitalize()], TOKENS.FONT_SECTION)
		line(body, str(row.get("title", row.get("id", "Bounty"))))
		if row.get("kind") == "material_delivery":
			var game := get_node_or_null(^"/root/Game")
			var local: RefCounted = game.get("local") if game != null else null
			var inventory: RefCounted = local.get("inventory") if local != null else null
			var owned := int(inventory.call("count", str(row.get("item", "")))) if inventory != null else -1
			line(body, "Deliver %s ×%d%s" % [str(row.get("item", "")), int(row.get("count", 0)), " · Have %d" % owned if owned >= 0 else " · Inventory unavailable"])
		else:
			line(body, "Complete" if row.get("complete") == true else "In progress")
		var rewards: Array[String] = []
		for reward: Dictionary in row.get("rewards", []):
			rewards.append("%s ×%d" % [str(reward.get("id", "")).replace("_", " ").capitalize(), int(reward.get("n", 0))])
		line(body, "Reward: " + " · ".join(rewards))
		var paid: bool = row.get("paid") == true
		button(body, "Claimed" if paid else "Deliver and claim" if row.get("kind") == "material_delivery" else "Claim",
			_claim.bind(instance), instance, not paid and row.get("claimable") == true and not _waiting)
	if _waiting:
		button(body, "Check original claim", _reconcile, "reconcile")
	finish(focus)

func _claim(instance: String) -> void:
	if _waiting or instance.is_empty() or not is_instance_valid(_source): return
	# F43 validates the instance against the admitted board; no client rewards,
	# day, progress, character id or costs enter the business intent.
	_waiting = true
	_durable = false
	_claim_context = character_context(get_node_or_null(^"/root/Game"))
	_rebuild()
	status.text = "Waiting for the host to save this claim."
	var result: Variant = _source.call("claim", instance)
	if result is Dictionary: present_result(result)

func _reconcile() -> void:
	if _waiting and is_instance_valid(_source): _source.call("reconcile")

## The bound producer delivers ONLY its original claim's terminal verdict.
## A lost notification stays pending; reopening must not create a new claim.
func present_result(result: Dictionary) -> void:
	if not _waiting: return
	if result.get("durable") == true: _durable = true
	if result.get("ok") == true and result.get("owner_saved") == true and result.get("durable") == true \
			and result.get("owner_acknowledged") == true:
		_waiting = false
		_durable = false
		if _shown:
			_rebuild()
			status.text = "Bounty claimed and saved."
	elif result.get("terminal") == true and result.get("durable") == false and not _durable:
		_waiting = false
		if _shown:
			_rebuild()
			status.text = str(result.get("reason", "The claim was refused. Your items were kept."))

func _process(delta: float) -> void:
	super._process(delta)
	if _shown and not is_instance_valid(_source): close()

func _exit_tree() -> void:
	if is_instance_valid(_source) and _source.is_connected("action_completed", present_result):
		_source.disconnect("action_completed", present_result)
	super._exit_tree()
