extends "res://tools/_capture_stormwood_stormheart_context.gd"

## Second retained approach after the production named-site correction.
## Reuses ordinary look/walk helpers and keeps the canonical frame.

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Stormheart context requires a rendering display")
		quit(1)
		return
	if not _parse_args() or not _load_plan():
		quit(1)
		return
	if _biome_id != "stormwood" or _planned.size() != 1:
		push_error("Stormheart context requires one Stormwood Glass Field day row")
		quit(1)
		return
	var row: Dictionary = _planned[0]
	var at: Array = row.position_xz
	if str(row.time) != "day" or Vector2(float(at[0]), float(at[1])).distance_to(Vector2(-310.0, 5050.0)) > 0.01:
		push_error("Stormheart context requires the unchanged Glass Field coordinate and day")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not _output_is_fresh():
		quit(1)
		return
	_begin_manifest()
	_manifest["supplemental_contract"] = "Retain the canonical Glass Field day frame. Wait for the region banner; aim the real camera at Stormheart with ordinary look input, capture, walk backward 12m using ordinary input, re-aim, and capture. Then walk left 20m and re-aim for an additional approach view. No actor or camera transform assignments after canonical setup. Debug catalogue setup and day clock freeze remain audit-only."
	_manifest["supplemental_planned_frame_ids"] = ["stormwood__stormheart__glass_field_look", "stormwood__stormheart__glass_field_backstep_look", "stormwood__stormheart__glass_field_lateral_look"]
	_write_manifest()
	if not await _mount_production_world() or not _prepare_capture_shell():
		_finish(false)
		return
	await _capture_row(row)
	if _records.size() != 1:
		_finish(false)
		return
	var tree := _world.get_node_or_null("StormheartTree") as Node3D
	if tree == null:
		_failures.append("Production StormheartTree is absent")
		_finish(false)
		return
	_manifest["stormheart_runtime"] = {"path": str(tree.get_path()), "position": _vec3(tree.global_position), "world_scene": _world.scene_file_path}
	var banner := await _wait_for_region_banner_clear()
	_manifest["region_banner_clear"] = banner
	if not bool(banner.get("cleared", false)):
		_failures.append("Region banner did not clear")
		_finish(false)
		return
	var aim := await _aim_at_tree(tree)
	if not bool(aim.get("reached", false)):
		_failures.append("Ordinary camera look did not reach Stormheart framing")
		_finish(false)
		return
	await _capture_context("stormwood__stormheart__glass_field_look", "split trunk and living crown from Glass Field", aim)
	var walk := await _walk_action(&"move_back", 12.0)
	_manifest["ordinary_backstep"] = walk
	if not bool(walk.get("finite", false)) or float(walk.get("horizontal_distance_m", 0.0)) < 11.5:
		_failures.append("Ordinary backstep did not reach the approach offset")
		_finish(false)
		return
	var second_aim := await _aim_at_tree(tree)
	if bool(second_aim.get("reached", false)):
		await _capture_context("stormwood__stormheart__glass_field_backstep_look", "approach parallax after ordinary backstep", {"walk": walk, "look": second_aim})
	else:
		_failures.append("Ordinary look after backstep did not reach Stormheart framing")
	var lateral := await _walk_action(&"move_left", 20.0)
	_manifest["ordinary_lateral_step"] = lateral
	if not bool(lateral.get("finite", false)) or float(lateral.get("horizontal_distance_m", 0.0)) < 19.5:
		_failures.append("Ordinary lateral approach did not reach 20m")
		_finish(false)
		return
	var lateral_aim := await _aim_at_tree(tree)
	if bool(lateral_aim.get("reached", false)):
		await _capture_context("stormwood__stormheart__glass_field_lateral_look", "tree silhouette after ordinary lateral approach", {"walk": lateral, "look": lateral_aim})
	else:
		_failures.append("Ordinary lateral look did not reach Stormheart framing")
	var alpha := _world.get_node_or_null("Named_glass_field_alpha") as Node3D
	_manifest["named_alpha_witness"] = {"present": alpha != null, "position": _vec3(alpha.global_position) if alpha != null else [], "home": str(alpha.get("home")) if alpha != null else "", "presentation_preserved": "Production named encounter; no probe relocation, hiding or scale mutation"}
	_finish(_failures.is_empty() and _records.size() == 4)
