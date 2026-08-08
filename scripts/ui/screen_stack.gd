extends CanvasLayer

## The only place a menu can be open, and the only place gameplay gets suspended
## for one.
##
## A stack rather than a single current screen because M5's release ceremony is a
## screen that opens over the party list and has to come back to it, and because
## the alternative — every screen knowing which screen to restore — is how you end
## up trapped in an inventory with no way out.
##
## ONE WAY IN AND ONE WAY OUT, for the reason `encounter_director` gives about
## fights and `build_mode` repeats about building: "One place, so a new way of
## entering a fight cannot forget half of it." Here the half that gets forgotten
## is suspending the world, and the symptom is a player walking off a cliff while
## reading their party list.
##
## Input is READ here and dispatched to the top screen. Screens do not poll input
## themselves. A screen that reads `menu_cancel` on its own would fire on the same
## press this one uses to pop it, and the player would lose two screens per press.

const STYLE := preload("res://scripts/ui/ui_style.gd")
const SETTINGS := preload("res://scripts/ui/settings.gd")

signal opened()
signal closed()

## Hold-to-repeat, so a five-slot list can be walked with the stick held over
## rather than clicked five times, without a flick past the item you wanted.
## Tunable.
const NAV_DELAY := 0.40
const NAV_REPEAT := 0.13
## Well past the 0.2 stick deadzone in the input map. A menu that steps at 0.21
## drifts one row at a time on a worn pad resting on a desk.
const NAV_DEADZONE := 0.55

@export var player_path: NodePath

## A convenience for scene wiring, not a keybinding system: one action opens one
## screen. `inventory` (I / Y) and the party screen are the intended pair. Leave
## the action empty and the stack only opens when something calls `push()`.
@export var toggle_action: StringName = &""
@export var toggle_screen_path: NodePath

## HUD layers to hide while a screen is open.
##
## The M1 debug HUD renders its raw readouts — `speed 0.0`, `grounded`,
## `keyboard: W` — in world space behind the menu panel, where the panel edge
## clips them mid-word. A blind reviewer of the first party-menu frames called
## it out as raw internal state a player should never see, and was right: it is
## developer instrumentation, not interface, and a modal screen is exactly when
## it should be out of the way.
@export var hide_while_open: Array[NodePath] = []

var _player: Node = null
var _stack: Array[Control] = []

## What locomotion was BEFORE the first screen opened.
##
## Captured rather than assumed. Combat and build mode both disable locomotion
## themselves; a menu opened during a fight that "restored" movement on close
## would hand the player a walk they were never supposed to have, and it would
## only show up when somebody opened their party mid-ambush.
var _locomotion_was: bool = true

var _nav_left: float = 0.0
var _nav_last: Vector2i = Vector2i.ZERO

## Swallows the frame a screen opened or closed on.
##
## `build_mode` documents the same guard for the same reason: the press that
## opens the mode is otherwise also read as the first action inside it. Here the
## button that opens the party menu (Y) and the button that confirms in it (A)
## are different, but `menu_cancel` and `build_toggle`/`combat_run` are not
## reliably different once you add screens to more contexts, and one guard costs
## a frame nobody can perceive.
var _guard: bool = false


func _ready() -> void:
	# The whole point of the stack is that it keeps running while the tree it
	# paused does not. Set here as well as in the scene so an instance built in
	# code cannot come up frozen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_node_or_null(player_path)

	# The stack is in every world scene and every menu preview, which makes it
	# the boot seam for user settings: saved rebinds go onto the InputMap and the
	# volume onto the Master bus BEFORE the player touches anything. Idempotent,
	# so a second stack in a harness costs nothing.
	SETTINGS.apply()

	# Screens authored as children of the stack start hidden. Otherwise a party
	# menu wired into the world scene is on screen at boot, which reads as the
	# game starting in a menu.
	for child in get_children():
		var screen := child as Control
		if screen != null:
			screen.visible = false


## Put a screen on top. Safe to call with a screen that is not in the tree yet.
func push(screen: Control) -> void:
	if screen == null:
		return
	# Pushing the same screen twice would leave a copy on the stack that one pop
	# cannot clear, and the player would press B and watch nothing happen.
	if _stack.has(screen):
		return
	if screen.get_parent() == null:
		add_child(screen)
	elif screen.get_parent() != self:
		screen.reparent(self)

	_stack.append(screen)
	screen.visible = true
	if screen.has_method("on_pushed"):
		screen.call("on_pushed")
	_mark_active()

	# EVERY push swallows a frame, not just the first. It used to guard only when
	# the stack opened from empty, which was fine while a screen could only be
	# opened by a button — and stopped being fine the moment one screen could open
	# another from a DIRECTION. The party menu opens the rename grid on left/right;
	# without this, the stick that is still held over carries straight through into
	# the new screen and walks its cursor before the player has seen it appear.
	# The guard also clears the hold-to-repeat timer, so the first step in the new
	# screen costs a fresh NAV_DELAY rather than inheriting one mid-repeat.
	_guard = true

	if _stack.size() == 1:
		_set_gameplay_active(false)
		opened.emit()
	_mark_stacking()


## Take the top screen off. Closes the stack when it was the last one.
func pop() -> void:
	if _stack.is_empty():
		return
	var screen: Control = _stack.pop_back()
	screen.visible = false
	if screen.has_method("on_popped"):
		screen.call("on_popped")
	_mark_active()

	# Same on the way back down: the press that closed the top screen must not also
	# land on the screen underneath it.
	_guard = true

	if _stack.is_empty():
		_set_gameplay_active(true)
		closed.emit()
	_mark_stacking()


## Everything off, in order, so each screen still gets its `on_popped`. Used when
## something outside the menus needs control back immediately — a fight starting,
## a cutscene, a load.
func clear() -> void:
	while not _stack.is_empty():
		pop()


func top() -> Control:
	return _stack.back() if not _stack.is_empty() else null


func is_open() -> bool:
	return not _stack.is_empty()


func depth() -> int:
	return _stack.size()


## Screens below the top stay VISIBLE and go inactive.
##
## Hiding them was the first version. It made M5's "keep one, release one" confirm
## appear to throw the six pals away and then bring them back, which is precisely
## the anxiety that screen exists to avoid. A dimmed list you can still see reads
## as "this is about those", which is true.
## Tell each screen whether something is on top of it, so it can deepen its own
## scrim. Called after every push and pop, because the answer changes for the
## screen underneath as well as for the one arriving.
func _mark_stacking() -> void:
	for i in _stack.size():
		var screen: Control = _stack[i]
		if screen != null and screen.has_method("set_stacked"):
			screen.call("set_stacked", i > 0)


func _mark_active() -> void:
	for i in _stack.size():
		var screen := _stack[i]
		if screen.has_method("set_screen_active"):
			screen.call("set_screen_active", i == _stack.size() - 1)


## Hand control back and forth between the world and the menus. One place, so a
## new way of opening a screen cannot forget half of it.
##
## Two mechanisms, because there are two kinds of gameplay input to stop.
## `set_locomotion_enabled` stops the player walking. Pausing the tree stops
## `combat_manager` and `build_mode`, which poll `Input.is_action_just_pressed`
## in `_physics_process` and cannot be talked out of it from here — a paused node
## does not get a physics frame, so it does not get the press. This node runs
## with PROCESS_MODE_ALWAYS and therefore keeps reading input itself.
## Show or hide the HUD layers named in `hide_while_open`.
func _set_huds_visible(shown: bool) -> void:
	for path in hide_while_open:
		var layer: Node = get_node_or_null(path)
		if layer is CanvasLayer:
			(layer as CanvasLayer).visible = shown
		elif layer is CanvasItem:
			(layer as CanvasItem).visible = shown


func _set_gameplay_active(active: bool) -> void:
	_set_huds_visible(active)
	if _player != null and _player.has_method("set_locomotion_enabled"):
		if active:
			_player.call("set_locomotion_enabled", _locomotion_was)
		else:
			if _player.has_method("locomotion_enabled"):
				_locomotion_was = bool(_player.call("locomotion_enabled"))
			_player.call("set_locomotion_enabled", false)
	get_tree().paused = not active


## The one node that sees every input event in every scene the menus live in,
## which makes it the feed for `ui_style`'s last-device detector. OBSERVING,
## not consuming: gameplay input is still read from the Input singleton in
## `_physics_process` below, and nothing here marks an event handled.
func _input(event: InputEvent) -> void:
	STYLE.note_input(event)


## Input is read in `_physics_process`, never `_process`.
##
## `build_mode` and `encounter_director` both record what getting this wrong
## costs: `Input.is_action_just_pressed()` is scoped to the frame the press was
## recorded in, so a system reading it from `_process` while another reads from
## `_physics_process` will sometimes each see a different half of one press. A
## menu is the worst place for that, because the other half is a jump or a
## charged attack going into the world you thought you had suspended.
func _physics_process(delta: float) -> void:
	_read_toggle()
	if _stack.is_empty():
		return
	if _guard:
		_guard = false
		_nav_left = 0.0
		_nav_last = Vector2i.ZERO
		return
	_read_navigation(delta)
	_read_buttons()


## One button, one screen — and now more than one pair.
##
## `toggle_action` / `toggle_screen_path` is the original wiring and still works;
## after it, every child screen that declares an `open_action` of its own gets a
## look. M9 adds the inventory and the map, and three exported paths on the stack
## with three exported actions beside them is three chances for the indices to
## stop lining up. A screen naming its own button cannot drift from itself.
##
## FIRST MATCH WINS AND STOPS. That matters because two actions can be bound to
## the same physical button — `inventory` and `party_menu` were both on gamepad Y
## until M9 moved the party to the Menu button — and when they are, the press must
## open ONE screen rather than whichever one the loop happened to reach second.
func _read_toggle() -> void:
	if _try_toggle(toggle_action, get_node_or_null(toggle_screen_path) as Control):
		return
	for child in get_children():
		var screen := child as Control
		if screen == null:
			continue
		var declared: Variant = screen.get("open_action")
		if declared == null:
			continue
		if _try_toggle(StringName(declared), screen):
			return


## Returns true when the press was CONSUMED, whether or not a screen moved.
func _try_toggle(action: StringName, screen: Control) -> bool:
	if action == &"" or screen == null or not InputMap.has_action(action):
		return false
	if not Input.is_action_just_pressed(action):
		return false
	# The same button closes it, but only from its own screen. Pressing Y inside
	# a confirm dialog should not tear the confirm and its parent down together.
	if top() == screen:
		pop()
		return true
	if _stack.is_empty():
		push(screen)
		return true
	# Something else is open. The press is ignored rather than swapping screens
	# under the player, and it is not consumed, so a stack whose own toggle is
	# elsewhere still gets its turn.
	return false


## Stick and D-pad, with a repeat. The `move_*` actions rather than a separate set
## of menu directions: this is a controller-first game with one left stick, and a
## second binding for the same physical input is a second thing to get wrong.
func _read_navigation(delta: float) -> void:
	var horizontal := Input.get_axis("move_left", "move_right")
	# `get_axis(negative, positive)` returns positive - negative, so pushing
	# forward reads NEGATIVE here. That matches screen space, where up is -Y.
	var vertical := Input.get_axis("move_forward", "move_back")

	# MENUS MOVE IN STRAIGHT LINES. A stick shoved into a corner clears the
	# deadzone on both axes at once, and until the party screen grew a left/right
	# verb that was harmless because horizontal did nothing. It is not harmless
	# now: a diagonal would open the rename screen AND step the party cursor off
	# the pal it opened for, so coming back would leave the highlight one row from
	# where it was. The dominant axis wins and the other is dropped; on a grid of
	# letters this is also just what a player means by "left".
	if absf(horizontal) >= absf(vertical):
		vertical = 0.0
	else:
		horizontal = 0.0

	var step := Vector2i(_step(horizontal), _step(vertical))

	if step == Vector2i.ZERO:
		_nav_last = Vector2i.ZERO
		_nav_left = 0.0
		return

	if step != _nav_last:
		_nav_last = step
		_nav_left = NAV_DELAY
		_navigate(step)
		return

	_nav_left -= delta
	if _nav_left <= 0.0:
		_nav_left = NAV_REPEAT
		_navigate(step)


func _step(value: float) -> int:
	if absf(value) < NAV_DEADZONE:
		return 0
	return 1 if value > 0.0 else -1


func _navigate(step: Vector2i) -> void:
	var screen := top()
	if screen != null and screen.has_method("navigate"):
		screen.call("navigate", step.x, step.y)


func _read_buttons() -> void:
	var screen := top()
	if screen == null:
		return
	if Input.is_action_just_pressed("menu_confirm"):
		if screen.has_method("confirm"):
			screen.call("confirm")
		return
	if Input.is_action_just_pressed("menu_cancel"):
		# The screen gets first refusal. A screen in a sub-state — renaming a pal,
		# say — needs B to back out of the sub-state before it backs out of the
		# screen, and only the screen knows it is in one.
		if screen.has_method("cancel") and bool(screen.call("cancel")):
			return
		pop()
