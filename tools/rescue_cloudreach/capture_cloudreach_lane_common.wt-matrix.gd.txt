extends RefCounted

## Shared bits for the Cloudreach lane's evidence captures
## (ralph/reports/CLOUDREACH-LANE/). Frames come from the PRODUCTION camera rig
## following the real trainer -- never a free survey camera -- aimed the way a
## player's stick would aim it (`camera_rig.gd::yaw`), and composed into one
## contact sheet in Godot because the container has no image tools.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 --script tools/<capture>.gd
##
## Never combine `--headless` with a rendering driver (WORKFLOW §7).


## Yaw that points the rig's forward (-Z of `Basis(UP, yaw)`) from `from` at `to`.
static func yaw_towards(from: Vector3, to: Vector3) -> float:
	var d := to - from
	return atan2(-d.x, -d.z)


static func save_frame(tree: SceneTree, dir: String, name: String, frames: Array) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var image := tree.root.get_texture().get_image()
	var path := "%s/%s.png" % [dir, name]
	var err := image.save_png(path)
	if err != OK:
		push_error("capture: could not write %s (%d)" % [path, err])
		return ""
	frames.append({"name": name, "image": image})
	print("CAPTURE wrote %s" % path)
	return path


## A grid of the captured frames at half size, row-major in capture order.
static func contact_sheet(frames: Array, path: String, columns: int = 3, cell_w: int = 640) -> void:
	if frames.is_empty():
		return
	var first: Image = frames[0]["image"]
	var cell_h := int(round(float(cell_w) * float(first.get_height()) / float(first.get_width())))
	var rows := int(ceil(float(frames.size()) / float(columns)))
	var gap := 6
	var sheet := Image.create(columns * cell_w + (columns + 1) * gap, rows * cell_h + (rows + 1) * gap, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.08, 0.08, 0.09))
	for i in frames.size():
		var img: Image = (frames[i]["image"] as Image).duplicate()
		img.convert(Image.FORMAT_RGB8)
		img.resize(cell_w, cell_h, Image.INTERPOLATE_BILINEAR)
		var x := gap + (i % columns) * (cell_w + gap)
		var y := gap + (i / columns) * (cell_h + gap)
		sheet.blit_rect(img, Rect2i(0, 0, cell_w, cell_h), Vector2i(x, y))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	sheet.save_png(path)
	print("CAPTURE sheet %s (%d frames)" % [path, frames.size()])
