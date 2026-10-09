extends "res://tests/smoke_water_swimming.gd"

## Run the unchanged production scene/input/recovery smoke with the shipping
## candidate's single flag ON, and verify the actual world hook before input.
## Scene/party/initial-pose fixtures are inherited and retain their scope.
var _collision_hook_checked := false


func _run() -> void:
	var collision_config: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/config/water_collision.json"))
	if not _expect(bool(collision_config.get("regional_collision_enabled", false)),
			"regional collision rollout proof requires the candidate flag ON"):
		return
	await super._run()


func _frames(count: int) -> void:
	if not _collision_hook_checked and is_instance_valid(world) \
			and bool(world.call("shell_build_complete")):
		var terrain: Node3D = world.get("terrain")
		var regions := world.get_node_or_null("WaterCollisionRegions")
		if not _expect(regions != null and bool(regions.get("installed")),
				"real water-world config hook installed regional collision before movement"):
			return
		var data: Object = terrain.get("data")
		var locations: Array = data.call("get_region_locations")
		if not _expect(int(regions.get("region_count")) == locations.size()
				and not locations.is_empty() and int(terrain.get("collision_mode")) == 0,
				"real water world retains every baked region through the native-to-region-body swap"):
			return
		_collision_hook_checked = true
		print("Water config-path collision rollout: %d actual baked regions before real swimming input" % locations.size())
	await super._frames(count)
