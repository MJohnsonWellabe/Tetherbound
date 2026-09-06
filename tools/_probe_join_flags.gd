extends SceneTree

## Scratch probe (lane 2.B): `scripts/ui/title_screen.gd`'s command-line flag
## reader, exercised without launching a game. Both functions are static and
## take their tokens as arguments precisely so this is possible -- a flag
## reader that can only be checked by starting the game is a flag reader
## nothing checks.
##
##   godot --headless --path . --script tools/_probe_join_flags.gd

const TITLE := preload("res://scripts/ui/title_screen.gd")

var checks := 0
var fails := 0


func _ok(c: bool, m: String) -> void:
	checks += 1
	if not c:
		fails += 1
	print(("PASS: " if c else "FAIL: ") + m)


func _flags(tokens: Array) -> Dictionary:
	var packed := PackedStringArray()
	for t: Variant in tokens:
		packed.append(str(t))
	return TITLE.parse_multiplayer_flags(packed)


func _initialize() -> void:
	var none := _flags(["--headless", "--path", "."])
	_ok(none.is_empty(), "an ordinary launch asks for no multiplayer (%s)" % str(none))

	var bare := _flags(["--mp-host"])
	_ok(str(bare.get("mode", "")) == "host" and int(bare.get("port", -1)) == 0,
		"--mp-host alone is host-on-the-configured-port (%s)" % str(bare))

	var spaced := _flags(["--mp-host", "27100"])
	_ok(str(spaced.get("mode", "")) == "host" and int(spaced.get("port", 0)) == 27100,
		"--mp-host 27100 (%s)" % str(spaced))

	var equals := _flags(["--mp-host=27100"])
	_ok(str(equals.get("mode", "")) == "host" and int(equals.get("port", 0)) == 27100,
		"--mp-host=27100 (%s)" % str(equals))

	# peer_runner.gd puts a bare `TB_NET_RUN_ID=...` token in argv. A bare
	# --mp-host followed by somebody else's token must not eat it as a port.
	var stray := _flags(["--mp-host", "TB_NET_RUN_ID=net-1"])
	_ok(str(stray.get("mode", "")) == "host" and int(stray.get("port", -1)) == 0,
		"--mp-host does not swallow a neighbouring non-port token (%s)" % str(stray))

	var join_bare := _flags(["--mp-join", "192.168.1.24"])
	_ok(str(join_bare.get("mode", "")) == "join" and str(join_bare.get("address", "")) == "192.168.1.24"
			and int(join_bare.get("port", -1)) == 0,
		"--mp-join 192.168.1.24 defaults its port (%s)" % str(join_bare))

	var join_port := _flags(["--mp-join=192.168.1.24:27015"])
	_ok(str(join_port.get("mode", "")) == "join" and str(join_port.get("address", "")) == "192.168.1.24"
			and int(join_port.get("port", 0)) == 27015,
		"--mp-join=192.168.1.24:27015 (%s)" % str(join_port))

	var join_host := _flags(["--mp-join", "study.local:27100"])
	_ok(str(join_host.get("address", "")) == "study.local" and int(join_host.get("port", 0)) == 27100,
		"--mp-join takes a hostname too (%s)" % str(join_host))

	_ok(_flags(["--mp-join"]).is_empty(), "--mp-join with no address asks for nothing")
	_ok(_flags(["--mp-join", "--verify-export"]).is_empty(), "--mp-join does not eat the next FLAG")
	_ok(_flags(["--mp-join", "192.168.1.24:banana"]).is_empty(), "a non-numeric port is refused outright")

	# Both places Godot keeps arguments have to work, and the FIRST flag wins.
	var both := _flags(["--mp-host=27100", "--mp-join=1.2.3.4"])
	_ok(str(both.get("mode", "")) == "host", "the first flag on the line wins (%s)" % str(both))

	var split := TITLE.split_address("10.0.0.5", 27015)
	_ok(str(split.get("address", "")) == "10.0.0.5" and int(split.get("port", 0)) == 27015,
		"split_address falls back to the port it was given (%s)" % str(split))
	_ok(TITLE.split_address("  ", 27015).is_empty(), "split_address refuses whitespace")
	_ok(TITLE.split_address("10.0.0.5:0", 27015).is_empty(), "split_address refuses port 0")
	_ok(TITLE.split_address("10.0.0.5:70000", 27015).is_empty(), "split_address refuses a port above 65535")
	_ok(str(TITLE.split_address("[fe80::1]:27015", 0).get("address", "")) == "fe80::1",
		"a bracketed literal keeps its port split at the LAST colon (%s)"
			% str(TITLE.split_address("[fe80::1]:27015", 0)))

	print("assertions run: %d, failed: %d" % [checks, fails])
	quit(1 if fails > 0 else 0)
