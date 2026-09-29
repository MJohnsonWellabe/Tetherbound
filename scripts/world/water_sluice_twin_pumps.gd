extends Node3D

## Two visible, grounded machines at the Sluice Isle Twin Pumps landmark.
## The route passes between them; collision follows the approved pump asset's
## measured footprint rather than leaving a large walk-through prop.
const PUMP := preload("res://assets/environment/tidewake/pump_station/pump_station.tscn")
const FOOTPRINT_M := Vector3(4.71, 3.2, 1.95)


func build(world: Node3D) -> void:
	var config: Dictionary = world.get("config")
	for island: Dictionary in config.get("islands", []):
		if str(island.get("id", "")) != "sluice_isle":
			continue
		var assembly: Dictionary = island.get("pump_assemblage", {})
		if not bool(assembly.get("enabled", false)):
			return
		for index in (assembly.get("units", []) as Array).size():
			var unit: Dictionary = assembly.units[index]
			var raw_at: Array = unit.get("at_xz_m", [])
			if raw_at.size() != 2:
				continue
			var x := float(raw_at[0])
			var z := float(raw_at[1])
			var ground := float(world.call("ground_height_at", x, z))
			if not is_finite(ground) or ground <= 0.0:
				continue
			var pump := Node3D.new()
			pump.name = "SluicePump%d" % (index + 1)
			pump.position = Vector3(x, ground - float(unit.get("sink_m", 0.35)), z)
			pump.rotation.y = deg_to_rad(float(unit.get("yaw_deg", 0.0)))
			pump.scale = Vector3.ONE * float(unit.get("scale", 1.0))
			add_child(pump)
			var visible := PUMP.instantiate() as Node3D
			visible.name = "ApprovedPumpStation"
			pump.add_child(visible)
			var solid := StaticBody3D.new()
			solid.name = "PumpFootprint"
			pump.add_child(solid)
			var collision := CollisionShape3D.new()
			collision.name = "MeasuredPumpBounds"
			var bounds := BoxShape3D.new()
			bounds.size = FOOTPRINT_M
			collision.shape = bounds
			collision.position.y = FOOTPRINT_M.y * 0.5
			solid.add_child(collision)
		return
