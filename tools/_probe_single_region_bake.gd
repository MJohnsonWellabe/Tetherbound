extends SceneTree

## OW5B / ralph/BAKE-GUARDS: a REAL, TIMED single-region bake, to anchor the
## unit cost §1.1 flags as measured-but-unvalidated. `_probe_corridor_
## footprint.gd`'s "BAKE COST PER PIXEL" section times field work only --
## height_at/slope_degrees_at/etc -- and says so in its own header: "excluding
## image allocation, control-word packing, PNG/res encoding and disk." This
## probe does the thing that gap leaves out: it runs an actual bake (real
## Image, real Terrain3D node, real import_images, real control-map paint,
## real save_directory to disk) for exactly one Terrain3D region, at the
## corridor's own region_size/vertex_spacing (256 / 2.0, pitch 512m), and
## times each phase with a wall clock.
##
## Deliberately scratch: writes to res://data/terrain/_probe_single_region,
## never res://data/terrain/playground, and does not touch
## data/config/terrain_playground.json. Delete the output directory after
## reading the numbers -- it is not part of the shipped bake and this branch
## is not changing the footprint.
##
##   godot --headless --path . --script tools/_probe_single_region_bake.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const ALIGNMENT := preload("res://scripts/world/terrain_region_alignment.gd")
const SCRATCH_DIR := "res://data/terrain/_probe_single_region"

const MAP_HEIGHT := 0
const MAP_CONTROL := 1
const MAP_COLOR := 2


func _init() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	if config.is_empty():
		push_error("no terrain config")
		quit(1)
		return

	# The corridor's own region_size/vertex_spacing (§1.3, §2), not the
	# currently-shipped 256/1.0 -- the point is to anchor the number that
	# feeds the 64-region projection, and that projection is at 2.0 spacing.
	var region_size := 256
	var spacing := 2.0
	var bounds := {"min_x": 0.0, "max_x": 512.0, "min_z": 0.0, "max_z": 512.0}
	var alignment_error := ALIGNMENT.check_alignment(bounds, region_size, spacing)
	if not alignment_error.is_empty():
		push_error("probe's own bounds are misaligned: %s" % alignment_error)
		quit(1)
		return

	var field: RefCounted = HEIGHTFIELD.new(config)
	var origin_x: float = bounds["min_x"]
	var origin_z: float = bounds["min_z"]
	var size_x := int(round((bounds["max_x"] - bounds["min_x"]) / spacing))
	var size_z := int(round((bounds["max_z"] - bounds["min_z"]) / spacing))
	print("single-region bake: %dx%d px at region_size=%d vertex_spacing=%.1f (one region, pitch %.0fm)" % [
		size_x, size_z, region_size, spacing, region_size * spacing])

	var colour_cfg: Dictionary = config.get("colour", {})
	var texture_step := float(colour_cfg.get("slope_sample_step", spacing))
	var rock_step := float(colour_cfg.get("slope_sample_step_rock", texture_step))

	var t_start := Time.get_ticks_usec()

	# --- phase 1: height + colour images, in memory ---
	var t0 := Time.get_ticks_usec()
	var height_image := Image.create_empty(size_x, size_z, false, Image.FORMAT_RF)
	var colour_image := Image.create_empty(size_x, size_z, false, Image.FORMAT_RGBA8)
	for pixel_z in size_z:
		var world_z := origin_z + pixel_z * spacing
		for pixel_x in size_x:
			var world_x := origin_x + pixel_x * spacing
			var height: float = field.call("height_at", world_x, world_z)
			height_image.set_pixel(pixel_x, pixel_z, Color(height, 0.0, 0.0, 1.0))
			var band: float = lerpf(texture_step, rock_step, clampf(field.call("rise_form_factor", world_x, world_z), 0.0, 1.0))
			var slope: float = field.call("slope_degrees_at", world_x, world_z, band)
			field.call("rock_bias_deg", world_x, world_z)
			field.call("building_apron_factor", world_x, world_z)
			field.call("drain_factor", world_x, world_z)
			field.call("stream_factor", world_x, world_z)
			colour_image.set_pixel(pixel_x, pixel_z, Color(0.5, 0.5, 0.5, 1.0))
	var us_colour_pass := Time.get_ticks_usec() - t0

	# --- phase 2: real Terrain3D node + import_images (the disk/encoding cost
	# the field-work-only probe explicitly excluded) ---
	var t1 := Time.get_ticks_usec()
	var terrain: Node = ClassDB.instantiate("Terrain3D")
	terrain.set("region_size", region_size)
	terrain.set("vertex_spacing", spacing)
	terrain.set("data_directory", SCRATCH_DIR)
	root.add_child(terrain)
	await process_frame
	var data: Object = terrain.get("data")
	if data == null:
		push_error("Terrain3D exposed no data object even after a frame")
		quit(1)
		return
	var images: Array[Image] = [null, null, null]
	images[MAP_HEIGHT] = height_image
	images[MAP_CONTROL] = null
	images[MAP_COLOR] = colour_image
	data.call("import_images", images, Vector3(origin_x, 0.0, origin_z), 0.0, 1.0)
	await process_frame
	var us_import_images := Time.get_ticks_usec() - t1

	# --- phase 3: control map paint (same per-pixel field calls
	# build_playground_terrain.gd's real _paint_control_map makes; the actual
	# base/overlay/blend arithmetic is a handful of comparisons and is not
	# where the cost is) ---
	var t2 := Time.get_ticks_usec()
	for pixel_z in size_z:
		var world_z := origin_z + pixel_z * spacing
		for pixel_x in size_x:
			var world_x := origin_x + pixel_x * spacing
			var band: float = lerpf(texture_step, rock_step, clampf(field.call("rise_form_factor", world_x, world_z), 0.0, 1.0))
			field.call("slope_degrees_at", world_x, world_z, band)
			field.call("rock_bias_deg", world_x, world_z)
			field.call("path_factor", world_x, world_z)
			field.call("building_apron_factor", world_x, world_z)
			field.call("drain_factor", world_x, world_z)
			field.call("stream_factor", world_x, world_z)
			field.call("path_dominant_dither", world_x, world_z)
			var pos := Vector3(world_x, 0.0, world_z)
			data.call("set_control_base_id", pos, 0)
			data.call("set_control_overlay_id", pos, 1)
			data.call("set_control_blend", pos, 0.0)
			data.call("set_control_auto", pos, false)
	var us_control_pass := Time.get_ticks_usec() - t2

	# --- phase 4: disk write ---
	var t3 := Time.get_ticks_usec()
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SCRATCH_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCRATCH_DIR))
	data.call("save_directory", SCRATCH_DIR)
	var us_save := Time.get_ticks_usec() - t3

	var us_total := Time.get_ticks_usec() - t_start
	var pixels := size_x * size_z

	print("")
	print("phase                    wall clock      us/px")
	print("height+colour images     %8.2f s   %8.2f" % [us_colour_pass / 1e6, us_colour_pass / float(pixels)])
	print("Terrain3D + import_images %7.2f s   %8.2f" % [us_import_images / 1e6, us_import_images / float(pixels)])
	print("control map paint        %8.2f s   %8.2f" % [us_control_pass / 1e6, us_control_pass / float(pixels)])
	print("save_directory (disk)    %8.2f s   %8.2f" % [us_save / 1e6, us_save / float(pixels)])
	print("TOTAL                    %8.2f s   %8.2f  (%d px, one region)" % [
		us_total / 1e6, us_total / float(pixels), pixels])
	print("")
	print("64-region projection at this per-pixel cost: %.2f min (%.2f s * 64)" % [
		(us_total / 1e6) * 64.0 / 60.0, (us_total / 1e6) * 64.0])
	print("scratch output at %s -- delete before committing, not part of the shipped bake" % SCRATCH_DIR)

	quit(0)
