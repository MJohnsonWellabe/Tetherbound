extends SceneTree

## Photographs every item in `data/items/items.json` as the player actually
## sees it, for a blind visual critic (`.claude/skills/visual-judge/SKILL.md`).
##
## Three forms per item, per the owner's brief -- not every item has all
## three, and which ones are MISSING is the whole point of this tool:
##
##   1. ICON      -- the satchel-slot glyph `tab_backpack.gd::_icon_for()`
##                    loads off `items.json`'s own `icon` path. All 55 have
##                    one; a lot of them are the SAME file as another item's.
##   2. HELD       -- the mesh `tool_hold.gd` bone-attaches to the trainer's
##                    hand while a `kind: "tool"` item is equipped
##                    (`held_model`/`held_offset`/`held_rotation_deg`). Only
##                    the 7 tools carry this key at all, and one of the 7
##                    (`fishing_rod`) carries it EMPTY on purpose (D24: no
##                    vendored rod mesh) -- equipped, and invisible.
##   3. WORLD      -- the gatherable node `harvest_node.gd` builds in the
##                    corridor for a `kind: "resource"` item, spec'd per band
##                    in `data/config/bands/*/harvest.json`. Only 6 of the 8
##                    `resource` items have one; `berry_seeds` and
##                    `heartstone` never grow in the world (seeds come from a
##                    recipe or Mira; the heartstone is a single hand-placed
##                    reward, not a harvest node -- see items.json's own
##                    `_comment_heartstone`).
##
##   xvfb-run -a -s "-screen 0 1440x2200x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1440x2200 \
##     --script tools/_capture_item_art.gd
##
## NEVER `--headless` with a real `--rendering-driver`: verified on this box
## (ralph/conventions.md, "Art pipeline traps") that the combination hangs
## forever with no error and no crash -- the process prints its first line and
## then sits in silence until killed, leaving a zombie Godot process pinned to
## whatever cwd it started in. `--headless` alone is correct and fast for
## tests, which render nothing; it is specifically paired with a rendering
## driver that it hangs. Always `xvfb-run` for the virtual display instead.
##
## ## Why the icon sheet is 1440x2200 and not the usual 1280x720/800
##
## Requirement is a GRID a critic can judge as a family in one look (criterion
## 1 of the visual-judge rubric: "view the sheet as if at 30%"), not 55
## separate small captures nobody can compare against each other. Grouped by
## `kind` (11 groups; the biggest, `tm`, is 14 items and wraps to 2 rows at 10
## columns), so the sheet answers "are tools distinguishable from consumables"
## and "which TMs are indistinguishable from each other" directly rather than
## needing the reader to cross-reference 55 filenames. The sheet MEASURES its
## own content height after layout and prints a WARN if anything would be
## clipped, rather than trusting the arithmetic that picked 1440x2200.
##
## ## Why held/world shots are a bare stage, not `meadows_playground.tscn`
##
## `capture_chop_swing.gd`'s own header already paid for this lesson --
## `ralph/BACKLOG.md`'s PERF-LOD entry records four capture attempts that died
## to the corridor's ~130k-prop boot cost on this exact container, one at 43
## minutes with no frame written. Nothing photographed here needs the
## corridor: it needs one player body, one bone-attached prop, or one
## hand-placed harvest node. So this builds the same sun/sky/flat-pad stage
## `capture_chop_swing.gd` and `capture_interior.gd` already use, plus the
## real `scenes/player/player.tscn` -- everything else in this file is either
## pure 2D (the icon sheet) or a single `harvest_node.gd` instance built from
## a spec copied verbatim out of `data/config/bands/*/harvest.json` (the same
## "spec copied from the game, not invented" rule `capture_chop_swing.gd`'s
## own `_build_target()` documents), never the corridor itself.
##
## ## FRAME BUDGET, measured against the corridor probe's own worst-case rate
##
## `tools/_probe_corridor_survey.gd` measured ~2.4s/frame under llvmpipe for a
## 143,630-prop world at 1280x800. This stage carries a flat plane, one player
## and one prop -- nowhere near that weight -- but budgeting against the
## corridor's own worst-case number rather than an unmeasured guess for a
## lighter scene keeps this honest:
##
##   icon sheet:    2 layout frames + 10 settle + 4 pose            =  16 frames
##   stage boot:    once, player + lighting + ground settle         =  30 frames
##   7 held shots:  7 x (15 settle + 4 pose)                        = 133 frames
##   6 world shots: 6 x (14 settle + 4 pose + 1 free-settle)        = 114 frames
##   ------------------------------------------------------------------------
##   total                                                          = 293 frames
##
## 293 frames x 2.4s (ceiling) = 703s = ~11.7 minutes, under the 15-minute
## target with room to spare, and the icon sheet alone (16 of those frames) is
## UI-only so its real cost is a fraction of a second regardless of the
## per-frame ceiling used for the rest of the arithmetic.

const ITEM_DB := preload("res://autoload/item_db.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")

const OUT_DIR := "res://shots/items"
## Tall enough for all 55 items plus their 11 kind headings. The first run
## measured its own content at 2479px inside a 2200px viewport and said so
## rather than writing a silently truncated sheet -- the bottom rows, which are
## where the TMs and key items sit, were simply not in the frame. A critic
## shown that sheet would have been judging a partial inventory without any way
## to know it, which is the same class of error as photographing an empty world
## and calling the region empty. 2800 clears the measured 2479 with room for
## the layout to grow by a row or two before anyone has to think about it again.
const RESOLUTION := Vector2i(1440, 2800)

const ICON_COLUMNS := 10
const ICON_TILE := Vector2(120.0, 150.0)
const ICON_SETTLE_FRAMES := 10
const ICON_POSE_FRAMES := 4

const STAGE_SETTLE_FRAMES := 30
const TOOL_SETTLE_FRAMES := 15
const WORLD_SETTLE_FRAMES := 14
const POSE_FRAMES := 4

## GAME_DESIGN.md / art.json: the trainer's authored height, and the ruler
## every held/world frame is checked against.
const TRAINER_HEIGHT_M := 1.8

## Display order for the icon sheet's kind sections. Any kind `items.json`
## carries that is not named here still gets a section -- appended, sorted --
## rather than silently dropped, so a new `kind` added later cannot vanish
## from the sheet unnoticed.
const KIND_ORDER: Array[String] = [
	"tool", "consumable", "food", "resource", "material",
	"gear", "key", "tm", "elixir", "armor", "currency",
]

## The 7 `kind: "tool"` items, in items.json's own order. `fishing_rod` is
## deliberately last and deliberately included even though it draws nothing --
## this is the shot that PROVES `held_model: ""` rather than hiding it.
const TOOL_SHOTS: Array[String] = [
	"axe", "pickaxe", "hammer", "knife", "hoe", "torch", "fishing_rod",
]

## One harvest-node spec per gatherable, each copied verbatim (model +
## model_scale) from that item id's FIRST entry across
## `data/config/bands/*/harvest.json` in band order (band1..band5) --
## `capture_chop_swing.gd::_build_target()`'s own precedent for "spec copied
## from the game, not invented". `berry_seeds` has no entry anywhere in those
## five files and is not photographed here; that absence is a finding, printed
## by `_print_static_findings()` rather than silently skipped.
const WORLD_NODES: Array[Dictionary] = [
	{
		"item": "wood", "amount": 4, "label": "Gather deadwood",
		"model": "res://assets/environment/stylized_nature/DeadTree_2.gltf",
		"model_scale": 0.22,
	},
	{
		"item": "stone", "amount": 3, "label": "Gather stone",
		"model": "res://assets/environment/stylized_nature/Rock_Medium_2.gltf",
		"model_scale": 1.0,
	},
	{
		"item": "fiber", "amount": 4, "label": "Gather fiber",
		"model": "res://assets/environment/stylized_nature/Plant_7_Big.gltf",
		"model_scale": 1.3,
	},
	{
		"item": "berries", "amount": 3, "label": "Gather berries",
		"model": "res://assets/environment/stylized_nature/Bush_Common_Flowers.gltf",
		"model_scale": 1.2,
	},
	{
		"item": "rootstone", "amount": 3, "label": "Gather rootstone",
		"model": "res://assets/environment/stylized_nature/Rock_Medium_1.gltf",
		"model_scale": 1.15,
	},
	{
		"item": "ironwood", "amount": 3, "label": "Gather ironwood",
		"model": "res://assets/environment/stylized_nature/TwistedTree_1.gltf",
		"model_scale": 0.28,
	},
]

## Fixed world-space vantage for every held-tool shot -- FIXED, not the
## exploration rig, per the brief: the same eye and target for all 7 tools is
## what makes a comically large or small one a defect visible in a still
## rather than an artefact of a different framing per shot.
const CAM_EYE := Vector3(1.9, 1.55, -2.3)
const CAM_TARGET := Vector3(0.0, 0.95, 0.0)
const CAM_FOV := 42.0

## Fixed vantage for every world-node shot: the player stands `NODE_AHEAD`
## metres out (same placement `capture_chop_swing.gd::_build_target()` uses
## for its own tree), so the 1.80m trainer is in every frame as the ruler
## visual-judge criterion 8 asks for.
const NODE_AHEAD := 1.6
const WORLD_CAM_EYE := Vector3(2.6, 1.7, -1.9)
const WORLD_CAM_TARGET := Vector3(0.0, 1.0, 0.5)


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var db: RefCounted = ITEM_DB.new()
	var ids: Array = db.call("ids")
	print("[items] %d items in data/items/items.json" % ids.size())

	var icon_users := _icon_users(db, ids)
	_print_static_findings(db, ids, icon_users)

	await _shoot_icon_sheet(db, ids, icon_users)

	var stage := await _build_stage()
	if stage.is_empty():
		quit(1)
		return
	await _shoot_held_tools(db, stage)
	await _shoot_world_nodes(stage)

	_print_inventory(db, ids, icon_users)
	print("")
	print("done -> %s" % OUT_DIR)
	print("Software rendering under the Compatibility renderer: composition,")
	print("silhouette and scale agreement are trustworthy; frame times are not")
	print("a performance measurement.")
	quit(0)


## --- static audit: findings that need no render at all ---------------------

## Which icon path each item points at, keyed by path so a shared file's
## every user is visible in one lookup.
func _icon_users(db: RefCounted, ids: Array) -> Dictionary:
	var out: Dictionary = {}
	for id_v in ids:
		var id := str(id_v)
		var path := str((db.call("definition", id) as Dictionary).get("icon", ""))
		if not out.has(path):
			out[path] = []
		(out[path] as Array).append(id)
	return out


## Printed BEFORE any frame is rendered, because none of it needs one -- it is
## all sitting directly in items.json and data/config/bands/*/harvest.json.
## A blind critic looking at renders still benefits from this being on the
## record: a shared icon or an empty held_model is not a rendering defect the
## sheet can fully dramatise on its own (two identical PNGs just look like two
## correct PNGs unless you already know they are meant to differ).
func _print_static_findings(db: RefCounted, ids: Array, icon_users: Dictionary) -> void:
	print("")
	print("[static audit] icon-path sharing:")
	var shared_item_count := 0
	var shared_paths: Array = icon_users.keys()
	shared_paths.sort()
	for path_v in shared_paths:
		var path := str(path_v)
		var users: Array = icon_users[path]
		if users.size() <= 1:
			continue
		shared_item_count += users.size()
		print("  SHARED  %-58s -> %s" % [path, ", ".join(users)])
	print("  %d/%d items (%.0f%%) share an icon file with at least one other item." % [
		shared_item_count, ids.size(), 100.0 * shared_item_count / maxf(1.0, float(ids.size()))])

	print("")
	print("[static audit] held-mesh sharing/absence among the 7 tools:")
	var held_paths: Dictionary = {}
	for tool_id in TOOL_SHOTS:
		var held := str((db.call("definition", tool_id) as Dictionary).get("held_model", ""))
		if held.is_empty():
			print("  PLACEHOLDER %-12s held_model is empty -- equips but is never drawn (D24: no vendored fishing-rod mesh)" % tool_id)
			continue
		if not held_paths.has(held):
			held_paths[held] = []
		(held_paths[held] as Array).append(tool_id)
	for path_v in held_paths.keys():
		var users: Array = held_paths[path_v]
		if users.size() > 1:
			print("  SHARED   %-58s -> %s" % [str(path_v), ", ".join(users)])
	var hammer_held := str((db.call("definition", "hammer") as Dictionary).get("held_model", ""))
	if hammer_held.findn("axe") != -1:
		print("  MISLABELED hammer's held_model is '%s' -- a survival-pack AXE mesh standing in for a hammer, not a shared file but still not a hammer shape" % hammer_held)

	print("")
	print("[static audit] world-node coverage among the resource items:")
	var world_ids: Array = []
	for spec in WORLD_NODES:
		world_ids.append(str(spec.get("item")))
	for id_v in ids:
		var id := str(id_v)
		if str(db.call("kind", id)) != "resource":
			continue
		if world_ids.has(id):
			continue
		print("  NO WORLD NODE  %-14s kind=resource but no entry in any data/config/bands/*/harvest.json -- never seen growing" % id)

	print("")
	print("[static audit] harvest-node material fixups -- the red-leak check:")
	var scattered := _scatter_models()
	if scattered.is_empty():
		print("  UNKNOWN  data/config/vegetation.json unreadable; fixup coverage NOT checked")
	else:
		var leaked := 0
		for spec in WORLD_NODES:
			var model := str(spec.get("model", ""))
			if scattered.has(model):
				continue
			leaked += 1
			print("  NO MATERIAL FIXUP  %-12s %s is listed in NO vegetation.json layer, so this node renders the vendored pack's RAW texture -- no `retexture`, no `retint`" % [
				str(spec.get("item")), model.get_file()])
		if leaked == 0:
			print("  all %d world nodes are built from models a scatter layer covers" % WORLD_NODES.size())


## Every model path any `data/config/vegetation.json` scatter layer lists.
##
## Read here because `harvest_node.gd::_material_fixups_for_model()` matches BY
## MODEL PATH: a harvest node built from a model no layer mentions silently gets
## neither the layer's `retexture` nor its `retint`, and renders whatever the
## vendored pack shipped. That is not a hypothetical failure mode -- it is the
## mechanism behind the red ironwood canopy that independent blind reviews have
## now reported THREE times (band4_upper_meadows_ironwood/harvest.json's
## `_comment_red_leak_d4b` records the first two, and the whole-game item pass
## found it again on `world-ironwood`). `Leaves_TwistedTree_C.png` is
## RGB(167,23,23), and TwistedTree_1 and _3 are in no layer, so a node authored
## from either one wears a saturated crimson canopy -- on a FRIENDLY gatherable,
## in the hue `data/config/palette.json` reserves for Team Tether and nothing
## else.
##
## The check is here rather than in the fix because this tool photographs the
## game as it is: the model below is copied verbatim from the game's own config
## and MUST stay that way, or the capture stops being evidence. So the tool
## reports the defect instead of hiding it, and the fourth blind review does not
## have to spend a finding rediscovering it.
func _scatter_models() -> Dictionary:
	var out: Dictionary = {}
	var file := FileAccess.open("res://data/config/vegetation.json", FileAccess.READ)
	if file == null:
		return out
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return out
	var layers: Variant = (parsed as Dictionary).get("layers", {})
	if not layers is Dictionary:
		return out
	for key in (layers as Dictionary).keys():
		var layer: Variant = (layers as Dictionary)[key]
		if not layer is Dictionary:
			continue
		var models: Variant = (layer as Dictionary).get("models", [])
		if models is Array:
			for m: Variant in (models as Array):
				out[str(m)] = true
		var single := str((layer as Dictionary).get("model", ""))
		if single != "":
			out[single] = true
	return out


## --- phase 1: the icon sheet -------------------------------------------------

func _shoot_icon_sheet(db: RefCounted, ids: Array, icon_users: Dictionary) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	root.add_child(canvas)
	await process_frame

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	canvas.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "ITEM ICON SHEET -- %d items, grouped by kind (data/items/items.json)" % ids.size()
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var grouped: Dictionary = {}
	for id_v in ids:
		var id := str(id_v)
		var kind := str(db.call("kind", id))
		if not grouped.has(kind):
			grouped[kind] = []
		(grouped[kind] as Array).append(id)

	var order: Array[String] = KIND_ORDER.duplicate()
	for kind_v in grouped.keys():
		var kind := str(kind_v)
		if not order.has(kind):
			order.append(kind)

	var shared_count := 0
	for kind in order:
		if not grouped.has(kind):
			continue
		var kind_ids: Array = grouped[kind]
		kind_ids.sort()

		var header := Label.new()
		header.text = "%s  (%d)" % [kind.to_upper(), kind_ids.size()]
		header.add_theme_font_size_override("font_size", 16)
		header.modulate = Color(0.75, 0.85, 1.0)
		vbox.add_child(header)

		var grid := GridContainer.new()
		grid.columns = ICON_COLUMNS
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		vbox.add_child(grid)

		for id_v2 in kind_ids:
			var id := str(id_v2)
			var def := db.call("definition", id) as Dictionary
			var path := str(def.get("icon", ""))
			var users: Array = icon_users.get(path, [])
			var is_shared: bool = users.size() > 1
			if is_shared:
				shared_count += 1
			grid.add_child(_icon_tile(db, id, path, is_shared))

	# Layout resolves over the next couple of idle frames; measure it rather
	# than trusting the arithmetic in the header comment.
	await process_frame
	await process_frame
	var content_h: float = vbox.size.y + 60.0
	if content_h > float(RESOLUTION.y):
		print("WARN icon sheet content measures %.0fpx tall inside a %dpx viewport -- bottom rows are clipped; raise RESOLUTION.y or ICON_COLUMNS" % [
			content_h, RESOLUTION.y])
	else:
		print("[icons] sheet content measures %.0fpx tall inside a %dpx viewport -- fits" % [content_h, RESOLUTION.y])

	for i in ICON_SETTLE_FRAMES:
		await process_frame
	for i in ICON_POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	var path := "%s/00-icon-sheet.png" % OUT_DIR
	if image == null or image.save_png(path) != OK:
		print("FAIL icon-sheet: could not save %s" % path)
	else:
		print("shot -> %s  (%d items, %d/%d sharing an icon with another item)" % [
			path, ids.size(), shared_count, ids.size()])

	canvas.queue_free()
	await process_frame


func _icon_tile(db: RefCounted, id: String, path: String, is_shared: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = ICON_TILE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.14, 0.15, 0.18)
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.border_color = Color(0.85, 0.35, 0.2) if is_shared else Color(0.25, 0.28, 0.32)
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.corner_radius_bottom_left = 6
	box.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", box)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)

	var icon_wrap := CenterContainer.new()
	icon_wrap.custom_minimum_size = Vector2(84.0, 84.0)
	col.add_child(icon_wrap)

	var texture: Texture2D = null
	if not path.is_empty() and ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	if texture != null:
		# Same expand/stretch pair tab_backpack.gd's own preview icon uses
		# (`_preview_icon`), so a tile here reads the way the real satchel
		# preview reads rather than a different stretch inventing a different
		# silhouette.
		var rect := TextureRect.new()
		rect.texture = texture
		rect.custom_minimum_size = Vector2(72.0, 72.0)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_wrap.add_child(rect)
	else:
		print("FAIL %-20s icon path missing or failed to load: '%s'" % [id, path])
		var swatch := ColorRect.new()
		swatch.color = db.call("colour", id) as Color
		swatch.custom_minimum_size = Vector2(72.0, 72.0)
		icon_wrap.add_child(swatch)
		var missing := Label.new()
		missing.text = "NO FILE"
		missing.add_theme_font_size_override("font_size", 10)
		missing.modulate = Color(1.0, 0.3, 0.3)
		col.add_child(missing)

	var name_label := Label.new()
	name_label.text = str(db.call("item_name", id))
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(108.0, 0.0)
	col.add_child(name_label)

	var id_label := Label.new()
	id_label.text = id
	id_label.add_theme_font_size_override("font_size", 10)
	id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	id_label.modulate = Color(0.6, 0.63, 0.68)
	col.add_child(id_label)

	if is_shared:
		var tag := Label.new()
		tag.text = "SHARED ICON"
		tag.add_theme_font_size_override("font_size", 10)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.modulate = Color(1.0, 0.55, 0.3)
		col.add_child(tag)

	return panel


## --- shared bare stage for phases 2 and 3 -----------------------------------

## Sun, sky and fog, in the shape `capture_chop_swing.gd`/`capture_interior.gd`
## already use. Plain daylight on purpose -- these frames are about a prop and
## a mesh, and a graded time-of-day would put the thing being judged in shadow.
func _build_lighting(world: Node3D) -> void:
	var env_holder := WorldEnvironment.new()
	env_holder.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_holder.environment = env
	world.add_child(env_holder)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48.0, 40.0, 0.0)
	world.add_child(sun)


## A flat pad with collision, so the CharacterBody3D has something to stand on.
func _build_ground(world: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.31, 0.38, 0.22)
	material.roughness = 1.0
	mesh.material_override = material
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.4, 40.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.2, 0.0)
	body.add_child(shape)
	world.add_child(body)


## One player, one flat pad, one fixed camera -- reused across both the held-
## tool and world-node phases so the stage is built exactly once. Returns {}
## on a failure that would make every later shot meaningless, rather than
## limping on and photographing nothing repeatedly.
func _build_stage() -> Dictionary:
	var world := Node3D.new()
	world.name = "ItemStage"
	root.add_child(world)
	await process_frame

	_build_lighting(world)
	_build_ground(world)

	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	if player == null:
		push_error("scenes/player/player.tscn did not instantiate as a CharacterBody3D")
		return {}
	player.name = "Player"
	world.add_child(player)
	player.global_position = Vector3.ZERO

	var camera := Camera3D.new()
	camera.name = "ItemCamera"
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	for i in STAGE_SETTLE_FRAMES:
		await process_frame

	var hold := player.get_node_or_null(^"ToolHold")
	var model := player.get_node_or_null(^"Model")
	if hold == null or model == null:
		push_error("player scene has no ToolHold/Model; nothing here can be photographed")
		return {}

	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no /root/Game autoload; equipped_tool would never reach the hand")
		return {}

	return {
		"world": world, "player": player, "camera": camera,
		"hold": hold, "model": model, "game": game,
	}


## --- phase 2: held tools -----------------------------------------------------

func _shoot_held_tools(db: RefCounted, stage: Dictionary) -> void:
	var hold: Node = stage["hold"]
	var camera: Camera3D = stage["camera"]
	var player: Node3D = stage["player"]
	var game: Node = stage["game"]

	camera.fov = CAM_FOV
	camera.global_position = CAM_EYE
	camera.look_at(CAM_TARGET, Vector3.UP)

	print("")
	print("[held] trainer is %.2fm tall; a believable tool reads well under 100%% of that on its longest axis" % TRAINER_HEIGHT_M)

	for tool_id in TOOL_SHOTS:
		# The tool reaches the hand exactly the way it does in play: the Game
		# autoload's `equipped_tool`, watched every frame by tool_hold.gd's own
		# `_sync_equipped()`. Set and wait, rather than reach into the prop
		# system directly.
		game.set("equipped_tool", tool_id)
		for i in TOOL_SETTLE_FRAMES:
			await process_frame

		var held_path := str((db.call("definition", tool_id) as Dictionary).get("held_model", ""))
		var prop: Variant = hold.call("prop_node")
		if prop == null:
			print("PLACEHOLDER held/%-12s nothing bone-attached (held_model='%s') -- equipped but invisible in the trainer's hand" % [tool_id, held_path])
		else:
			print("  held/%-12s prop=%-24s %s" % [tool_id, (prop as Node).name, _prop_size_line(prop as Node3D)])

		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		var path := "%s/held-%s.png" % [OUT_DIR, tool_id]
		if image == null or image.save_png(path) != OK:
			print("FAIL held/%s: could not save %s" % [tool_id, path])
		else:
			print("shot -> %s" % path)

	game.set("equipped_tool", "")


## World-space size of whatever is bone-attached, measured off its own
## MeshInstance3Ds rather than local mesh bounds -- the prop hangs off a
## BoneAttachment3D inside a skeleton `character_model._fit()` has scaled, so
## local size and the size a player actually sees are not the same number,
## same measurement `capture_chop_swing.gd::_report_prop_size()` makes.
func _prop_size_line(prop: Node3D) -> String:
	var bounds := AABB()
	var seen := false
	for node in _all_descendants(prop):
		var mesh := node as VisualInstance3D
		if mesh == null:
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		bounds = box if not seen else bounds.merge(box)
		seen = true
	if not seen:
		return "no VisualInstance3D under the prop"
	var longest: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	return "longest axis %.2fm (%.0f%% of a %.2fm trainer)" % [
		longest, 100.0 * longest / TRAINER_HEIGHT_M, TRAINER_HEIGHT_M]


func _all_descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_all_descendants(child))
	return out


## --- phase 3: world-form gatherables -----------------------------------------

func _shoot_world_nodes(stage: Dictionary) -> void:
	var world: Node3D = stage["world"]
	var camera: Camera3D = stage["camera"]
	var game: Node = stage["game"]
	game.set("equipped_tool", "")

	camera.fov = CAM_FOV
	camera.global_position = WORLD_CAM_EYE
	camera.look_at(WORLD_CAM_TARGET, Vector3.UP)

	print("")
	for spec in WORLD_NODES:
		var item_id := str(spec.get("item"))
		var node := HARVEST_NODE.new()
		node.name = "WorldNode"
		world.add_child(node)
		node.call("setup", spec)
		node.position = Vector3(0.0, 0.0, NODE_AHEAD)

		for i in WORLD_SETTLE_FRAMES:
			await process_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		var path := "%s/world-%s.png" % [OUT_DIR, item_id]
		if image == null or image.save_png(path) != OK:
			print("FAIL world/%s: could not save %s" % [item_id, path])
		else:
			print("shot -> %s  (model=%s)" % [path, str(spec.get("model"))])

		node.queue_free()
		await process_frame


## --- the inventory ------------------------------------------------------------

## The single most useful thing this tool produces: which of the 55 items have
## bespoke art at each of the three layers, and which fall back to something
## shared or absent. Printed once, after every render, so it reads as a table
## rather than being scattered across the per-frame log lines above.
func _print_inventory(db: RefCounted, ids: Array, icon_users: Dictionary) -> void:
	print("")
	print("=== FULL %d-ITEM ART INVENTORY ===" % ids.size())
	print("%-20s %-11s %-11s %-13s %-9s" % ["id", "kind", "icon", "held", "world"])

	var world_ids: Array = []
	for spec in WORLD_NODES:
		world_ids.append(str(spec.get("item")))

	var sorted_ids: Array = ids.duplicate()
	sorted_ids.sort_custom(func(a, b): return "%s:%s" % [db.call("kind", str(a)), str(a)] < "%s:%s" % [db.call("kind", str(b)), str(b)])

	var bespoke_icons := 0
	for id_v in sorted_ids:
		var id := str(id_v)
		var def := db.call("definition", id) as Dictionary
		var kind := str(db.call("kind", id))
		var path := str(def.get("icon", ""))
		var users: Array = icon_users.get(path, [])
		var icon_state: String = "bespoke" if users.size() <= 1 else "SHARED x%d" % users.size()
		if users.size() <= 1:
			bespoke_icons += 1

		var held_state := "n/a"
		if TOOL_SHOTS.has(id):
			held_state = "PLACEHOLDER" if str(def.get("held_model", "")).is_empty() else "captured"

		var world_state := "n/a"
		if world_ids.has(id):
			world_state = "captured"
		elif kind == "resource":
			world_state = "NO NODE"

		print("%-20s %-11s %-11s %-13s %-9s" % [id, kind, icon_state, held_state, world_state])

	print("")
	print("icon totals:  %d/%d items (%.0f%%) have a bespoke icon file; %d/%d (%.0f%%) reuse another item's icon file." % [
		bespoke_icons, ids.size(), 100.0 * bespoke_icons / float(ids.size()),
		ids.size() - bespoke_icons, ids.size(), 100.0 * (ids.size() - bespoke_icons) / float(ids.size())])
	print("held totals:  %d/%d tools draw a real mesh in the trainer's hand; 1/%d (fishing_rod) equips invisibly." % [
		TOOL_SHOTS.size() - 1, TOOL_SHOTS.size(), TOOL_SHOTS.size()])
	print("world totals: %d gatherable resource ids have a harvest-node model; see the static audit above for which resources have none." % world_ids.size())
