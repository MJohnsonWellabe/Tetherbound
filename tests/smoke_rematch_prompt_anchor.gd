extends SceneTree

## Native regression for the real NPC facing callbacks and ordinary arbiter X.
## An empty scene supplies no art, campaign, ground, fight or save proof. The
## actual F20 reload/rematch smoke must still admit the canonical encounter.
const NPC := preload("res://scripts/npc/npc_body.gd")
const PROMPT := preload("res://scripts/repeatables/rematch_prompt.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
var checks := 0
var failures := 0
var activated: Object

func _init() -> void: _run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1
	print("REMATCH ANCHOR ", "PASS " if value else "FAIL ", message)

func _run() -> void:
	await process_frame
	var fixture := Node3D.new()
	root.add_child(fixture)
	var player := Node3D.new()
	fixture.add_child(player)
	var arbiter := ARBITER.new()
	fixture.add_child(arbiter)
	arbiter.set_player(player)
	arbiter.activated.connect(func(provider: Object) -> void: activated = provider)
	var trainer := NPC.new()
	fixture.add_child(trainer)
	trainer.global_position = Vector3(78, 0, 44)
	trainer.set_player(player)
	var talk := trainer.add_prompt("Talk to Bryn", 3.8)
	var prompts: Array[Node3D] = []
	for offset: float in [-1.5, 1.5]:
		var prompt := PROMPT.new(Vector3(offset, 0, 0))
		prompt.configure("R1 rematch" if offset < 0 else "Endgame rematch", 3.8, true)
		trainer.add_child(prompt)
		prompts.append(prompt)
	for index in 2:
		var expected := trainer.global_position + Vector3(-1.5 if index == 0 else 1.5, 0, 0)
		player.global_position = expected + Vector3(-0.25 if index == 0 else 0.25, 0.9, 0)
		trainer.rotation.y = PI
		for frame in 8: await process_frame
		_check(not is_equal_approx(trainer.rotation.y, PI), "actual NPC facing callback turns the trainer")
		_check(prompts[index].global_position.is_equal_approx(expected), "side prompt stays at its world offset while facing changes")
		_check(talk.get_parent() == trainer and prompts[index].get_parent() == trainer, "both interactions retain trainer lifetime ownership")
		_check(arbiter.winning_provider() == prompts[index] and arbiter.winner().get("actionable") == true,
			"the approached side wins over the central talk and opposite rematch")
		activated = null
		for pressed: bool in [true, false]:
			var event := InputEventAction.new()
			event.action = "interact"
			event.pressed = pressed
			event.strength = 1.0 if pressed else 0.0
			Input.parse_input_event(event)
			for frame in 2:
				await physics_frame
				await process_frame
		_check(activated == prompts[index], "ordinary X activates the same side after the NPC turns")
	trainer.global_position += Vector3(7, 2, -4)
	for frame in 4: await process_frame
	for index in 2:
		_check(prompts[index].global_position.is_equal_approx(trainer.global_position + Vector3(-1.5 if index == 0 else 1.5, 0, 0)),
			"relocating the trainer carries its side interaction")
	var retained: WeakRef = weakref(prompts[1])
	trainer.free()
	_check(retained.get_ref() == null, "freeing the trainer removes its detached-transform prompt")
	fixture.free()
	print("REMATCH ANCHOR: %d checks, %d failures; synthetic scene, actual NPC/arbiter input" % [checks, failures])
	quit(0 if failures == 0 else 1)
