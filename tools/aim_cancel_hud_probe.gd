extends "res://tools/aim_cancel_windup_probe.gd"

## Isolated input-ownership experiment: actual HUD polling plus the retained
## synthetic combat wrapper and production ThrowAim. No campaign/world boot.
const HUD_SCENE := preload("res://scenes/ui/playground_hud.tscn")
var game: Node

func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("aim cancel HUD probe watchdog")
		quit(1))
	Engine.max_fps = 60
	game = root.get_node("Game")
	game.inventory.add("orb_basic", 4)
	game.inventory.add("axe", 1)
	game.hotbar[0] = "axe"
	game.equipped_tool = ""
	var positive := Node3D.new()
	positive.name = "HotbarPositiveControl"
	root.add_child(positive)
	current_scene = positive
	positive.add_child(HUD_SCENE.instantiate())
	for i in 4:
		await process_frame
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_B
	button.pressed = true
	Input.parse_input_event(button)
	Input.flush_buffered_events()
	for i in 4:
		await process_frame
	var live := _require(game.equipped_tool == "axe", "actual HUD uses physical B to equip slot-one axe outside aim")
	button = InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_B
	button.pressed = false
	Input.parse_input_event(button)
	Input.flush_buffered_events()
	current_scene = null
	positive.queue_free()
	await process_frame
	if not live:
		_finish()
		return
	# Independent case setup, before aim measurement. No stock/tool repairs later.
	game.equipped_tool = ""
	await _windup_case("stale cancellation with actual HUD", true, true, false, 60)
	_finish()


func _build(adversarial_order: bool, initial_target_x: float = 0.0, blocked: bool = false) -> void:
	await super(adversarial_order, initial_target_x, blocked)
	current_scene = f.world
	f.world.add_child(HUD_SCENE.instantiate())
	for i in 4:
		await process_frame


func _teardown() -> void:
	if cancel_consumed:
		# Do not end the fixture at the successful physics cancel. The live HUD
		# polls in idle, so its next callbacks are part of the ownership interval.
		for i in 3:
			await process_frame
		print("HUD_CANCEL_OBSERVATION tool=", game.equipped_tool,
			" stock=", f.aim.stock(), " aim=", f.manager.is_aiming())
		_require(game.equipped_tool == "", "aim cancellation never also equips the slot-one tool")
		_require(f.aim.stock() == initial_stock and not f.manager.is_aiming(),
			"cancel remains free and closed after actual HUD idle polls")
	current_scene = null
	await super()
