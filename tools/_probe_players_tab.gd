extends SceneTree

## Scratch probe (lane 2.B): the Players tab in the states a player can be in.
## The pause-menu shell already drives it in `tests/smoke_menu.gd` (which walks
## every tab with a real pad); this checks what it SAYS, which a cycle test
## cannot see.
##
##   godot --headless --path . --script tools/_probe_players_tab.gd

const TAB := preload("res://scripts/ui/tab_players.gd")

var checks := 0
var fails := 0


func _ok(c: bool, m: String) -> void:
	checks += 1
	if not c:
		fails += 1
	print(("PASS: " if c else "FAIL: ") + m)


func _text(tab: Node) -> String:
	var out := ""
	for label: Variant in tab.find_children("*", "Label", true, false):
		out += str((label as Label).text) + " | "
	return out


## `build()` frees its old children with `queue_free()`, which lands at the end
## of the frame -- the house pattern every tab in this menu uses. So a probe
## that builds twice in one frame reads both builds' labels at once; the shell
## never does, because it rebuilds on a revision change and polls the frame
## after. One frame here is the difference.
func _rebuild(tab: Node) -> void:
	tab.call("build")
	await process_frame
	tab.call("poll")
	await process_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	# The autoload's own `_ready` (which mounts the session and the menu) has
	# not run yet when `_initialize()` is called.
	await process_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: no /root/Game")
		quit(1)
		return
	var menu: Object = game.call("menu")
	_ok(menu != null, "the menu shell is mounted, so the tab has something to read state through")

	var tab: Control = TAB.new()
	tab.set("menu", menu)
	root.add_child(tab)
	await _rebuild(tab)

	# 1. No session at all -- the port could not be bound, or nothing ever
	# hosted. This is what a headless tool or a failed bind looks like.
	var offline := _text(tab)
	_ok(offline.contains("not open to anyone else"),
		"with no session the tab says the world is closed rather than showing an empty list: %s" % offline)
	_ok(tab.call("first_focus") == null, "and offers nothing to press")
	_ok(int(tab.call("revision")) >= 0, "revision() answers without a session")
	var offline_revision := int(tab.call("revision"))

	# 2. A solo session, which is what every ordinary game is: one peer.
	var session: Node = game.get("session")
	_ok(session != null, "the session node exists")
	var hosted := bool(session.call("host", 27411))
	_ok(hosted, "hosted a one-peer session on udp/27411 for the probe")
	if not hosted:
		print("assertions run: %d, failed: %d" % [checks, fails])
		quit(1)
		return
	_ok(int(tab.call("revision")) != offline_revision,
		"revision() moved when the session appeared, so the shell rebuilds the tab")
	await _rebuild(tab)
	var solo := _text(tab)
	_ok(solo.contains("playing alone"), "solo says you are alone: %s" % solo)
	_ok(solo.contains("Up to 4 players"), "and names the cap D95 sets")
	# With no beacon mounted the tab can only quote the configured default --
	# which is honest, and is what a session-less tool sees.
	_ok(solo.contains(":%d" % int(session.call("default_port"))),
		"with no beacon the invite address quotes the configured port")
	# The title screen mounts a beacon on the way into the world and gives it
	# the port it actually hosted, so a host on a non-default port quotes that.
	var beacon: Node = load("res://scripts/mp/lan_beacon.gd").new()
	beacon.name = "LanBeacon"
	game.add_child(beacon)
	beacon.call("serve", 27411)
	await _rebuild(tab)
	var with_beacon := _text(tab)
	_ok(with_beacon.contains(":27411"),
		"with the beacon mounted it quotes the port actually hosted: %s" % with_beacon)
	_ok(solo.contains("host") and solo.contains("you"),
		"the one row is tagged both host and you")
	_ok(tab.call("first_focus") == null, "a host with no guests has nobody to remove")

	session.call("leave", "probe")
	await process_frame
	await _rebuild(tab)
	var after := _text(tab)
	_ok(after.contains("not open to anyone else"), "and it goes honest again when the session ends: %s" % after)

	print("assertions run: %d, failed: %d" % [checks, fails])
	quit(1 if fails > 0 else 0)
