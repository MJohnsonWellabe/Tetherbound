extends RefCounted

## Explicit test entry inside the normal exported game. Official 4.7 templates
## disable --script path overrides, so the title dispatches this private flag.
## The existing production-scene route still owns setup, movement and evidence.
const FLAG := "--f26-route"
const ROUTE_SCRIPT := "res://tools/capture_lookdev_route.gd"


static func requested(arguments: PackedStringArray) -> bool:
	return arguments.has(FLAG)


static func start(title: Control) -> void:
	# The explicit entry bypasses _build(), so none of the normal title
	# callbacks may run while the deferred route setup tears it down.
	title.process_mode = Node.PROCESS_MODE_DISABLED
	title.hide()
	_begin.bind(title).call_deferred()


static func _begin(title: Control) -> void:
	var tree := title.get_tree()
	if tree.get_script() != null:
		push_error("F26 export entry refuses to replace an existing custom MainLoop")
		tree.quit(1)
		return
	var route := load(ROUTE_SCRIPT) as Script
	if route == null or not route.can_instantiate():
		push_error("F26 export entry could not load the packaged route")
		tree.quit(1)
		return
	print("F26 EXPORT ENTRY: existing production route selected")
	tree.paused = false
	if tree.current_scene == title:
		tree.current_scene = null
	title.get_parent().remove_child(title)
	title.queue_free()
	# Attaching the SceneTree script invokes its inherited constructor, which
	# defers _run until the existing autoloads and this title teardown are ready.
	tree.set_script(route)
	if tree.get_script() != route:
		push_error("F26 export entry could not attach the route MainLoop")
		tree.quit(1)
