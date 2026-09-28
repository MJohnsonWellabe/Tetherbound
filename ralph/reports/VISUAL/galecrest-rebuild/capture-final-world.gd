extends "res://tools/capture_cloudreach_frame_matrix.gd"

func _run_matrix() -> void:
	var base := OUT
	var total := 0
	for variant: String in ["vivid", "shiny", "alpha"]:
		var bird := _ally()
		if bird == null:
			quit(1)
			return
		bird.call("set_shiny", variant == "shiny")
		bird.call("set_alpha", variant == "alpha")
		for night: bool in [false, true]:
			_force_night = night
			OUT = base + "/" + variant + ("-night" if night else "-day")
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
			_frames.clear()
			_frame_by_row.clear()
			_manifest = FileAccess.open(OUT + "/manifest.txt", FileAccess.WRITE)
			_manifest_line("# Production CameraRig, installed Galecrest resource; forced colourway at ordinary size for material validation.")
			for row: Dictionary in ROWS:
				if int(row["n"]) not in [12, 13]:
					continue
				await _apply_row_flags(str(row.get("flags", "")))
				await _capture_row(row)
			_write_sheets()
			total += _frames.size()
			_manifest.close()
	print("Galecrest final: %d/12 frames, %d skips" % [total, _skips.size()])
	quit(0 if total == 12 and _skips.is_empty() else 1)
