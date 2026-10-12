extends SceneTree

## F19#5 (2026-10-11): with the default UDP port already taken, Session.host()
## with no port asked for binds a nearby port and is an ACTIVE host -- not
## offline-solo, which skips host-authored durable rewards (the Warden's
## portal key and relic). An explicit port that is taken still fails.
##   godot --headless --path . --script tests/smoke_session_port_fallback.gd

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var session: Node = root.get_node_or_null(^"Session")
	if session == null:
		session = load("res://scripts/net/session.gd").new()
		root.add_child(session)
	await process_frame
	var port: int = session.call("default_port")
	var blocker := ENetMultiplayerPeer.new()
	if blocker.create_server(port, 1) != OK:
		print("PORT FALLBACK note: udp/%d already held elsewhere; still a taken default" % port)
		blocker = null
	if bool(session.call("host", port)):
		_failures.append("an explicitly asked, taken port must still refuse")
	if bool(session.call("is_active")):
		session.call("leave")
	if not bool(session.call("host")):
		_failures.append("no fallback port bound with the default taken")
	elif not bool(session.call("is_active")) or not bool(session.call("is_host")):
		_failures.append("the fallback host is not an active host")
	if blocker != null:
		blocker.close()
	print("PORT FALLBACK %s %s" % ["PASS" if _failures.is_empty() else "FAIL", str(_failures)])
	quit(0 if _failures.is_empty() else 1)
