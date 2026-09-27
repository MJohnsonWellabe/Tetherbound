extends SceneTree
## Imported hero asset: measured cage, shared materials, live and load shutdown.
## godot --headless --path . --script tests/smoke_machine_finish.gd

const FINISH = preload("res://scripts/world/tether_machine_finish.gd")
const HOLD = preload("res://scripts/world/stronghold.gd")
const CLIMAX = preload("res://scripts/world/stronghold_climax.gd")
const OCCUPATION = preload("res://scripts/world/stronghold_occupation.gd")
var failures: Array[String] = []
var checks := 0

class Holder extends Node3D:
	func machine() -> Node3D:
		return get_node("TetherMachine")

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
	print("CHECK %s %s" % ["PASS" if ok else "FAIL",label])

func _machine(holder: Node3D, spec: Dictionary) -> Node3D:
	var machine := Node3D.new()
	machine.name = "TetherMachine"
	holder.add_child(machine)
	var model := (load(str(spec.model)) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	machine.add_child(model)
	var builder := HOLD.new()
	builder.call("_fit_to_height",model,float(spec.height))
	builder.free()
	var light := OmniLight3D.new()
	light.name = "CoreLight"
	machine.add_child(light)
	return machine

func _emission(machine: Node) -> int:
	var count := 0
	for mesh: MeshInstance3D in machine.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var mat := mesh.get_active_material(surface) as BaseMaterial3D
			if mat != null and mat.emission_enabled and mat.emission_energy_multiplier > 0:
				count += 1
	return count

func _run() -> void:
	await process_frame
	var spec: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stronghold.json")) as Dictionary).machine
	var holder := Holder.new()
	root.add_child(holder)
	var machine := _machine(holder,spec)
	var climax := CLIMAX.new()
	climax.set("_stronghold",holder)
	var before: Dictionary = climax.call("_measure_cage",{})
	_check(not before.is_empty(),"source cage measurement exists")
	FINISH.apply(machine,spec)
	_check(climax.call("_measure_cage",{}) == before,"finish preserves all measured cage values")
	_check(machine.get_node("Hardware").get_parent() == machine,"hardware outside Model")
	_check(_emission(machine) == 1,"imported rune emission active")
	var other := Holder.new()
	root.add_child(other)
	var second := _machine(other,spec)
	FINISH.apply(second,spec)
	var watcher := OCCUPATION.new()
	root.add_child(watcher)
	watcher.watch_withdrawal(holder)
	_check(not watcher.withdrawn(),"new game machine active")
	root.get_node("Game").get("progression").call("set_flag","legendary_freed")
	watcher.call("_poll_withdrawal")
	_check(watcher.withdrawn(),"live flag triggers withdrawal")
	_check(not (machine.get_node("CoreLight") as Light3D).visible,"live core light disabled")
	_check(_emission(machine) == 0,"live runes unlit")
	_check(_emission(second) == 1,"shutdown does not mutate another instance's shared material")
	_check((machine.get_node("Hardware") as Node3D).visible,"static fittings remain")
	_check(climax.call("_measure_cage",{}) == before,"shutdown preserves cage values")
	var report := watcher.withdraw()
	_check(watcher.withdraw() == report,"withdrawal idempotent")
	var loaded := OCCUPATION.new()
	root.add_child(loaded)
	loaded.watch_withdrawal(other)
	_check(loaded.withdrawn(),"existing freed flag applies immediately on load")
	_check(not (second.get_node("CoreLight") as Light3D).visible,"loaded core light disabled")
	_check(_emission(second) == 0,"loaded runes unlit")
	climax.free()
	watcher.free()
	loaded.free()
	holder.free()
	other.free()
	print("Machine finish: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
