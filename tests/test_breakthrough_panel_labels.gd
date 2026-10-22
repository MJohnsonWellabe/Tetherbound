extends "res://tests/test_case.gd"

## The Master/Kitchen chooser names each companion: an empty nickname used to
## leave the row blank, and two unnamed creatures of one species read alike.
const PANEL := preload("res://scripts/masters/breakthrough_panel.gd")

func test_unnamed_companions_show_species_and_same_names_carry_their_slot() -> void:
	var cards := [{"nickname": "Bud", "species_id": "terrapup"}, {"nickname": "", "species_id": "bramblebun"},
		{"nickname": "", "species_id": "mudsnout"}, {"nickname": "", "species_id": "bramblebun"}, {"species_id": "pipwing"}]
	assert_eq(PANEL.party_labels(cards), ["Bud", "Bramblebun (2)", "Mudsnout", "Bramblebun (4)", "Pipwing"] as Array[String])

func test_a_nickname_matching_another_row_is_also_disambiguated() -> void:
	var cards := [{"nickname": "Mudsnout", "species_id": "terrapup"}, {"nickname": "  ", "species_id": "mudsnout"}]
	assert_eq(PANEL.party_labels(cards), ["Mudsnout (1)", "Mudsnout (2)"] as Array[String])

## A long cook list ran past the view and down-focus stopped at the 14th row.
## Rows chain explicitly, skip disabled rows, and the scroll follows focus.
func test_rows_chain_focus_past_the_visible_list() -> void:
	var panel = PANEL.new()
	panel._ready()
	for index in 20:
		panel._button("Row %d" % index, func() -> void: pass, index == 5)
	panel._link_focus()
	var rows: Array = panel._list.get_children().filter(func(n: Node) -> bool: return n is Button and not n.disabled)
	assert_eq(rows.size(), 19)
	for index in rows.size() - 1:
		assert_eq(rows[index].get_node(rows[index].focus_neighbor_bottom), rows[index + 1])
		assert_eq(rows[index + 1].get_node(rows[index + 1].focus_neighbor_top), rows[index])
	assert_true((panel.get_child(1) as ScrollContainer).follow_focus)
	panel.free()

## The controller's B is menu_cancel; the chooser used to close only on the
## built-in ui_cancel, which has no pad binding, so a pad could not leave it.
func test_controller_cancel_closes_the_chooser() -> void:
	for action: StringName in [&"menu_cancel", &"ui_cancel"]:
		var press := InputEventAction.new()
		press.action = action
		press.pressed = true
		assert_true(PANEL.is_cancel(press), str(action))
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	assert_false(PANEL.is_cancel(accept))

## The panel's bounded resend: one per second, sixty in all.
const RETRY_S := 1.0
const RETRIES := 60

class FeedService extends Node:
	var sent: Array = []
	func view() -> Dictionary: return {}
	func submit(op: String, intent: Dictionary, _source: Node) -> Dictionary:
		sent.append([op, intent.duplicate(true)])
		return {"ok": false, "resolved": false, "code": "awaiting_saved_decision"}

## F48 guest feast feed: the guest fed right after cooking, the host answered
## owner_passive_original_pending (the cook's owner checkpoint was still
## settling) and nothing sent the feed again, so it never committed. The same
## original intent is resent; after the bounded retries the row is released
## with a retry message rather than left pending forever.
func test_a_momentary_feed_refusal_resends_the_same_intent_then_offers_a_retry() -> void:
	var panel = PANEL.new()
	panel._ready()
	panel.show() # open() shows it
	var service := FeedService.new()
	panel._service = service
	panel._source = service
	panel._feed("pup", "feast_t1_ground", "")
	var intent := {"creature_uid": "pup", "feast_item": "feast_t1_ground", "choice": ""}
	assert_eq(service.sent, [["feast_feed", intent]])
	var momentary := {"ok": false, "durable": false, "resolved": false, "code": "owner_passive_original_pending"}
	assert_false(panel.accept_completion("feast_feed", {"creature_uid": "other", "feast_item": "feast_t1_ground", "choice": ""}, momentary),
		"another attempt's refusal is not this press's")
	assert_true(panel.accept_completion("feast_feed", intent, momentary))
	panel._process(RETRY_S * 0.5)
	assert_eq(service.sent.size(), 1, "the resend waits its interval")
	panel._process(RETRY_S)
	assert_eq(service.sent, [["feast_feed", intent], ["feast_feed", intent]], "the same original intent is sent again")
	assert_eq(panel._pending_action, "feast_feed")
	assert_eq(panel._message.text, "Saving your earlier action first…", "a resend keeps the player-facing message")
	for attempt in RETRIES - 1:
		panel.accept_completion("feast_feed", intent, momentary)
		panel._process(RETRY_S)
	assert_eq(service.sent.size(), RETRIES + 1, "retries are bounded")
	assert_true(panel.accept_completion("feast_feed", intent, momentary))
	assert_eq(panel._pending_action, "", "an exhausted press releases the row for another press")
	assert_true(str(panel._message.text).contains("Press again"), panel._message.text)
	panel._process(RETRY_S)
	assert_eq(service.sent.size(), RETRIES + 1, "nothing is sent after release")
	# A fresh press starts a fresh bound; a saved answer ends it.
	panel._feed("pup", "feast_t1_ground", "")
	assert_true(panel.accept_completion("feast_feed", intent, momentary))
	panel._process(RETRY_S)
	assert_true(panel.accept_completion("feast_feed", intent,
		{"ok": true, "settled": true, "durable": true, "owner_saved": true, "owner_acknowledged": true}))
	assert_eq(panel._pending_action, "")
	var sent_before := service.sent.size()
	panel._process(RETRY_S)
	assert_eq(service.sent.size(), sent_before, "a saved feed is never resent")
	panel.free()
	service.free()

const MOMENTARY := {"ok": false, "durable": false, "resolved": false, "code": "owner_passive_original_pending"}
const FEED_INTENT := {"creature_uid": "pup", "feast_item": "feast_t1_ground", "choice": ""}

func _waiting_feed_panel(service: Node):
	var panel = PANEL.new()
	panel._ready()
	panel.show()
	panel._service = service
	panel._source = service
	panel._feed("pup", "feast_t1_ground", "")
	panel.accept_completion("feast_feed", FEED_INTENT, MOMENTARY)
	return panel

## Review of the resend: closing the Kitchen ends it. A refused press was not
## admitted, so the row is released and nothing commits after the player left.
func test_closing_the_kitchen_stops_a_waiting_resend() -> void:
	var service := FeedService.new()
	var panel = _waiting_feed_panel(service)
	panel.close()
	assert_eq(panel._pending_action, "", "a closed panel holds no refused press")
	for i in 3: panel._process(RETRY_S)
	assert_eq(service.sent.size(), 1, "nothing is resent after close")
	# A refusal for a press already in flight when the panel closed is released too.
	var in_flight = _waiting_feed_panel(service)
	in_flight._process(RETRY_S)
	in_flight.hide()
	assert_true(in_flight.accept_completion("feast_feed", FEED_INTENT, MOMENTARY))
	assert_eq(in_flight._pending_action, "")
	var sent_before := service.sent.size()
	in_flight._process(RETRY_S)
	assert_eq(service.sent.size(), sent_before)
	panel.free()
	in_flight.free()
	service.free()

## Leaving the scene the Kitchen was opened in ends the resend as well; the
## panel lives under the root and would otherwise outlive the scene.
class ScenePanel extends "res://scripts/masters/breakthrough_panel.gd":
	var scene: Node
	func _current_scene() -> Node: return scene

func test_a_scene_change_stops_a_waiting_resend() -> void:
	var first := Node.new()
	var second := Node.new()
	var service := FeedService.new()
	var panel := ScenePanel.new()
	panel._ready()
	panel.scene = first
	panel.open(service, "feed", service, "")
	panel._feed("pup", "feast_t1_ground", "")
	var sent_before := service.sent.size()
	panel.accept_completion("feast_feed", FEED_INTENT, MOMENTARY)
	panel._process(RETRY_S)
	assert_eq(service.sent.size(), sent_before + 1, "same scene: the resend goes")
	panel.accept_completion("feast_feed", FEED_INTENT, MOMENTARY)
	panel.scene = second
	panel._process(RETRY_S)
	assert_eq(service.sent.size(), sent_before + 1, "no resend into another scene")
	assert_eq(panel._pending_action, "", "the row is released with a retry message")
	assert_true(str(panel._message.text).contains("Press again"))
	panel.free()
	first.free()
	second.free()
	service.free()
