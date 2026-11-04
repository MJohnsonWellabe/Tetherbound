extends SceneTree

## Native regression: after credits a Master keeps her own challenge as the
## prompt for a player standing in front of or near her, while each side zone
## still wins for a player who steps toward it. Before the fix the zones sat at
## the trainer's foot height beside her raised challenge prompt, so the arbiter
## (nearest in 3D) offered "R1/Endgame rematch" unless the player stood within
## 0.37 m of her axis (earned F49 line, 3 Nov, Mira at (-401, 5053)).
## Synthetic scene: actual NPC prompt, rematch zone script and arbiter; no art,
## save or fight proof.
const NPC := preload("res://scripts/npc/npc_body.gd")
const ZONE := preload("res://scripts/repeatables/rematch_prompt.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
var checks := 0
var failures := 0

func _init() -> void: _run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1
	print("MASTER CHALLENGE ", "PASS " if value else "FAIL ", message)

func _run() -> void:
	await process_frame
	var fixture := Node3D.new()
	root.add_child(fixture)
	var player := Node3D.new()
	fixture.add_child(player)
	var arbiter := ARBITER.new()
	fixture.add_child(arbiter)
	arbiter.set_player(player)
	var master := NPC.new()
	fixture.add_child(master)
	master.global_position = Vector3(-401, 3.46, 5053)
	master.set_player(player)
	var challenge := master.add_prompt("Challenge Mira Emberlane", 3.8)
	var zones: Array[Node3D] = []
	for side: float in [-1.5, 1.5]:
		var zone := ZONE.new(ZONE.side_offset(challenge, master, side))
		zone.configure("R1 rematch" if side < 0 else "Endgame rematch", 3.8, true)
		master.add_child(zone)
		zones.append(zone)
	for frame in 4: await process_frame
	var lift := challenge.global_position.y - master.global_position.y
	_check(lift > 0.5, "the Master's own challenge prompt is raised above her feet (%.2f m)" % lift)
	for index in 2:
		_check(is_equal_approx(zones[index].global_position.y, challenge.global_position.y),
			"side zone %d sits level with her challenge prompt" % index)
	# Player positions relative to her feet, at ground level as in the game.
	var cases := [
		[Vector3(0.43, 0, -0.79), challenge, "the failing earned-line stand (0.43 m off her axis)"],
		[Vector3(0.6, 0, 2.0), challenge, "facing her from 2 m, 0.6 m to one side"],
		[Vector3(-0.6, 0, -2.0), challenge, "facing her from behind, 0.6 m to the other side"],
		[Vector3(0.0, 0, 1.2), challenge, "close in front of her"],
		[Vector3(1.3, 0, 0.3), zones[1], "stepped toward the Endgame side"],
		[Vector3(-1.3, 0, 0.3), zones[0], "stepped toward the R1 side"],
	]
	for row: Array in cases:
		player.global_position = master.global_position + (row[0] as Vector3)
		for frame in 8: await process_frame
		var expected: Node3D = row[1]
		_check(arbiter.winning_provider() == expected and arbiter.winner().get("actionable") == true,
			"%s offers %s (got %s)" % [row[2], str(expected.get("label")), str(arbiter.winner().get("label", "none"))])
	# The old foot-height zone lost the failing stand: keep the arithmetic pinned.
	var stand := master.global_position + Vector3(0.43, 0, -0.79)
	var old_zone := master.global_position + Vector3(1.5, 0, 0)
	_check(stand.distance_to(old_zone) < stand.distance_to(challenge.global_position),
		"regression: a foot-height side zone was nearer than her challenge at that stand")
	master.global_position += Vector3(7, 2, -4)
	for frame in 4: await process_frame
	for index in 2:
		_check(zones[index].global_position.is_equal_approx(master.global_position + Vector3(-1.5 if index == 0 else 1.5, lift, 0)),
			"relocating the Master carries side zone %d at her prompt's height" % index)
	fixture.free()
	print("MASTER CHALLENGE: %d checks, %d failures; synthetic scene, actual NPC/zone/arbiter" % [checks, failures])
	quit(0 if failures == 0 else 1)
