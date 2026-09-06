extends "res://scripts/ui/menu_tab.gd"

## Stage B Wave 2 lane 2.B. WHO IS IN THIS WORLD.
##
## Added the way every other screen in this menu is added -- an entry in
## `data/config/menu.json` and a script that extends `menu_tab.gd`. The shell
## (`scripts/ui/game_menu.gd`) is not edited to add a tab and was not edited to
## add this one.
##
## ## It has to be honest when there is nobody else here
##
## A solo player opening this tab is the COMMON case, not the error case, and
## the trap this whole lane was warned about lives right here: with no session
## `multiplayer.is_server()` is true and `get_unique_id()` is 1, so a tab that
## asked the multiplayer API would confidently draw a host and a peer id for a
## process that never opened a socket. Everything below asks
## `scripts/net/session.gd` instead, and asks it EVERY POLL rather than caching
## an answer at build time -- a player can host, be kicked, and be back on the
## title screen without this tab being rebuilt in between.
##
## So the tab draws one of three honest things:
##
##   1. a session with company -> the roster, and a Remove button per guest if
##      this peer is the host;
##   2. a solo session (one peer, which is what solo IS -- see session.gd's
##      header) -> you, plus the address and port a friend needs to reach you;
##   3. no session at all, because the port could not be bound -> that, said
##      plainly, because "nobody can join you" is a thing the player needs to
##      know rather than an empty list to puzzle over.

const PEER_REGISTRY := preload("res://scripts/net/peer_registry.gd")

## Rows are rebuilt only when this changes (`menu_tab.gd`'s rule): rebuilding a
## focusable list every frame destroys the focused node every frame, and on a
## controller that means the cursor cannot be moved at all.
var _rows: Array = []
var _summary: Label = null
var _detail: Label = null
var _list: VBoxContainer = null


func build() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()

	var header := Label.new()
	header.text = "Players"
	header.add_theme_font_size_override("font_size", 24)
	add_child(header)

	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", 20)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	add_child(_list)

	for row: Variant in _peer_rows():
		_add_row(row as Dictionary)

	_detail = Label.new()
	_detail.add_theme_font_size_override("font_size", 19)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_color_override("font_color", Color("#9db3a8"))
	add_child(_detail)

	poll()


func _add_row(peer: Dictionary) -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)

	var who := Label.new()
	who.custom_minimum_size = Vector2(460, 0)
	who.add_theme_font_size_override("font_size", 22)
	line.add_child(who)

	var peer_id := int(peer.get("peer_id", 0))
	var kick: Button = null
	# The host never gets a Remove button beside its own row, and a client
	# never gets one at all -- `Session.kick()` refuses both, and a button that
	# is refused when pressed is worse than a button that is not there.
	if _is_host() and peer_id != PEER_REGISTRY.HOST_PEER_ID and peer_id != 0:
		kick = Button.new()
		kick.text = "Remove"
		kick.custom_minimum_size = Vector2(160, 52)
		kick.focus_mode = Control.FOCUS_ALL
		kick.pressed.connect(func() -> void: _on_kick(peer_id))
		line.add_child(kick)

	_list.add_child(_panel(line, 12))
	_rows.append({"peer_id": peer_id, "label": who, "kick": kick})


func first_focus() -> Control:
	for row: Variant in _rows:
		var button: Variant = (row as Dictionary).get("kick")
		if button != null:
			return button as Control
	return null


## Peer count plus the registry's own content fingerprint. Both, because the
## count alone would miss a peer leaving and another arriving between two
## polls, and the fingerprint alone is 0 on a process with no session.
func revision() -> int:
	var session := _session()
	if session == null:
		return 0
	if not bool(session.call("is_active")):
		return 1
	var stamp := int(session.call("peer_count")) * 1000003
	if session.has_method("registry_fingerprint"):
		stamp += int(session.call("registry_fingerprint"))
	# Host-ness is part of the SHAPE of this screen (it decides whether the
	# rows carry a Remove button), so a peer that stopped being the host has
	# to rebuild, not merely re-label.
	return stamp * 2 + int(_is_host())


func poll() -> void:
	if _summary == null:
		return
	var session := _session()
	if session == null or not bool(session.call("is_active")):
		_summary.text = "This world is not open to anyone else."
		_detail.text = "The network port could not be opened, so nobody can join this game. Everything else plays exactly as it always has."
		return

	var peers: Array = _peer_rows()
	var local := int(session.call("local_peer_id"))
	for row: Variant in _rows:
		var entry: Dictionary = row
		var label: Label = entry.get("label")
		var peer_id := int(entry.get("peer_id", 0))
		var found := _row_for(peers, peer_id)
		if label == null:
			continue
		if found.is_empty():
			# A peer that left between two polls. Said rather than left
			# stale; the next `revision()` change rebuilds the list without it.
			label.text = "(left the world)"
			var kick: Variant = entry.get("kick")
			if kick != null:
				(kick as Button).disabled = true
			continue
		var tags: Array[String] = []
		if peer_id == PEER_REGISTRY.HOST_PEER_ID:
			tags.append("host")
		if peer_id == local:
			tags.append("you")
		if bool(found.get("downed", false)):
			tags.append("down")
		if bool(found.get("sleeping", false)):
			tags.append("asleep")
		var who_name := str(found.get("display_name", ""))
		if who_name.is_empty():
			who_name = "Trainer"
		label.text = "%s — %s%s" % [who_name, str(found.get("realm", "meadows")),
			"  (%s)" % ", ".join(tags) if not tags.is_empty() else ""]

	var count := int(session.call("peer_count"))
	var cap := int(session.call("max_peers"))
	if count <= 1:
		_summary.text = "You are playing alone. Up to %d players can share this world." % cap
		_detail.text = "A friend joins from their own title screen — Join a Game — and picks your world off the list, or types %s." % _invite_address(session)
		return
	_summary.text = "%d of %d players in this world." % [count, cap]
	_detail.text = "Others join with %s." % _invite_address(session) if _is_host() \
		else "The host decides who is in this world."


func _on_kick(peer_id: int) -> void:
	var session := _session()
	if session == null or not bool(session.call("is_host")):
		say("Only the host can remove a player.")
		return
	var found := _row_for(_peer_rows(), peer_id)
	var who := str(found.get("display_name", "That player")) if not found.is_empty() else "That player"
	if bool(session.call("kick", peer_id)):
		say("%s was removed from the world." % who)
	else:
		say("%s could not be removed." % who)


## This machine's address, for a player to read out to a friend. Every IPv4
## address the box actually has, because a laptop on wifi and ethernet at once
## has two and only one of them is the one the friend can reach -- guessing
## which and printing one would be the wrong one about half the time.
func _invite_address(session: Node) -> String:
	# The port actually being hosted, not merely the configured default: a host
	# launched with `--mp-host 27100` is on 27100, and reading the config here
	# would hand their friend a number nothing is listening on. `Session` does
	# not expose its bound port; the LAN beacon does, because the title screen
	# gave it that port on the way into the world (`lan_beacon.gd::served_port`).
	var port := int(session.call("default_port"))
	var game := state()
	var beacon := game.get_node_or_null(^"LanBeacon") if game != null else null
	if beacon != null and int(beacon.call("served_port")) > 0:
		port = int(beacon.call("served_port"))
	var found: Array[String] = []
	for address: String in IP.get_local_addresses():
		if address.contains(":") or address.begins_with("127."):
			continue
		found.append("%s:%d" % [address, port])
	if found.is_empty():
		return "this machine's address, port %d" % port
	return " or ".join(found)


func _peer_rows() -> Array:
	var session := _session()
	if session == null or not bool(session.call("is_active")):
		return []
	var rows: Variant = session.call("peers")
	return rows as Array if rows is Array else []


func _row_for(rows: Array, peer_id: int) -> Dictionary:
	for row: Variant in rows:
		var entry: Dictionary = row
		if int(entry.get("peer_id", 0)) == peer_id:
			return entry
	return {}


## Asked of the session every time, never cached: authority is re-read per
## frame, and with no session at all `is_host()` is deliberately true (a solo
## player is a host with no clients).
func _is_host() -> bool:
	var session := _session()
	return session != null and bool(session.call("is_host"))


func _session() -> Node:
	var game := state()
	if game == null:
		return null
	var s: Variant = game.get("session")
	return s as Node
