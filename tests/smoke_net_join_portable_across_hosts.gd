extends "res://tests/helpers/net_harness.gd"

# peers: 3

## X05 / MULTIPLAYER §3 and §5, ACCEPTANCE M2 "rejoin/rehost" and portable
## identities: one character travels between two different hosts' worlds.
## Three real processes on the shipping Session and ledger RPCs:
##
##   peer 0 hosts world A and records world flag A;
##   peer 1 hosts world B and records world flag B;
##   peer 2, the traveller, joins A as one stable character, is granted a
##   personal flag by host A, saves its character, leaves deliberately, then
##   joins B as the same character.
##
## It must arrive in B carrying its own personal progress (read back from its
## character file), seeing B's world and not A's, while neither host's world
## changes and the traveller never writes a world file.

const TRAVELLER := "portable-smoke-traveller"
const WORLD_A_FLAG := "x05_portable_world_a"
const WORLD_B_FLAG := "x05_portable_world_b"
## A declared PLAYER-scope flag (progression_state.gd scope table): only
## declared player flags belong in the portable character file, so an
## undeclared test id would rightly stay behind.
const PERSONAL_FLAG := "water_swim_lesson_briefed"
## A world flag is expected to be ABSENT here; wait this long before saying so.
const ABSENT_FRAMES := 90


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(3, "world"):
		quit(await finish())
		return
	var port_a := int(((_peers[0] as Dictionary).get("hello", {}) as Dictionary).get("enet_port", 0))
	var port_b := int(((_peers[1] as Dictionary).get("hello", {}) as Dictionary).get("enet_port", 0))
	check(port_a > 0 and port_b > 0 and port_a != port_b, "two hosts on two ports (%d, %d)" % [port_a, port_b])

	check(_passed(await step(0, "host", {"port": port_a})), "host A opened its world")
	check(_passed(await step(1, "host", {"port": port_b})), "host B opened its world")
	check(_passed(await step(0, "story_flag", {"flag": WORLD_A_FLAG, "scope": "world"})),
		"host A recorded its world flag")
	check(_passed(await step(1, "story_flag", {"flag": WORLD_B_FLAG, "scope": "world"})),
		"host B recorded its world flag")

	# --- the traveller in world A ---------------------------------------------
	check(_passed(await step(2, "join", {"host": "127.0.0.1", "port": port_a,
		"character": {"character_id": TRAVELLER, "display_name": "Traveller"}})),
		"the traveller joined host A")
	var in_a := _as_dict(await probe(2, "session"))
	var peer_in_a := int(in_a.get("peer_id", 0))
	check(_passed(await step(2, "wait_flag", {"flag": WORLD_A_FLAG, "scope": "world"})),
		"in world A the traveller sees A's world flag")
	check(_passed(await step(2, "story_flag", {"flag": PERSONAL_FLAG, "scope": "player",
		"peers": [peer_in_a]})), "host A granted the traveller a personal flag")
	check(_passed(await step(2, "wait_flag", {"flag": PERSONAL_FLAG, "scope": "player"})),
		"the personal flag landed on the traveller")
	check(_passed(await step(2, "save_character_here", {})), "the traveller saved its character")
	var file_a := _as_dict(await probe(2, "character_file"))
	check(str(file_a.get("id", "")) == TRAVELLER, "the saved file is the traveller's (%s)" % str(file_a))
	check(_passed(await step(2, "leave", {"reason": "travelling"})), "the traveller left world A")
	check(_passed(await step(0, "expect_peers", {"count": 1}, 900)), "host A is alone again")

	# --- the same character in world B ----------------------------------------
	check(_passed(await step(2, "join", {"host": "127.0.0.1", "port": port_b,
		"character": {"character_id": TRAVELLER, "display_name": "Traveller"}})),
		"the same character joined host B")
	check(_passed(await step(2, "wait_flag", {"flag": PERSONAL_FLAG, "scope": "player"})),
		"its personal progress travelled with it")
	check(_passed(await step(2, "wait_flag", {"flag": WORLD_B_FLAG, "scope": "world"})),
		"in world B it sees B's world flag")
	check(not _passed(await step(2, "wait_flag", {"flag": WORLD_A_FLAG, "scope": "world",
		"budget_frames": ABSENT_FRAMES})), "world A's flag did not come along (no world import)")
	var b_rows: Array = _as_dict(await probe(1, "session")).get("rows", []) as Array
	var b_ids: Array = []
	for row: Variant in b_rows:
		b_ids.append(str(_as_dict(row).get("character_id", "")))
	check(b_ids.has(TRAVELLER) and b_ids.size() == 2, "host B admitted the same stable id (%s)" % str(b_ids))

	check(not _passed(await step(1, "wait_flag", {"flag": WORLD_A_FLAG, "scope": "world",
		"budget_frames": ABSENT_FRAMES})), "host B's world never received world A's flag")
	check(_passed(await step(0, "wait_flag", {"flag": WORLD_A_FLAG, "scope": "world"})),
		"host A still holds its own world flag")
	check(not _passed(await step(0, "wait_flag", {"flag": PERSONAL_FLAG, "scope": "player",
		"budget_frames": ABSENT_FRAMES})), "host A's own trainer never gained the traveller's flag")
	var traveller_worlds: Variant = await probe(2, "worlds_dir_entries")
	check(traveller_worlds is Array and (traveller_worlds as Array).is_empty(),
		"the traveller never wrote a world file (%s)" % str(traveller_worlds))
	var characters: Variant = await probe(2, "characters_dir_entries")
	check(characters is Array and (characters as Array).has(TRAVELLER),
		"the traveller keeps exactly its own portable character (%s)" % str(characters))

	quit(await finish())


func _passed(result: Variant) -> bool:
	return result is Dictionary and str((result as Dictionary).get("verdict", "")) == "PASS"


## A failed probe returns error text, not a Dictionary; see
## smoke_net_join_version_mismatch.gd.
func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}
