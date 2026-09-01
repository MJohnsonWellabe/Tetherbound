extends SceneTree

## Photograph EVERY creature in the game for a blind visual critic, with the
## 1.80m trainer standing beside each one as the ruler `.claude/skills/
## visual-judge/SKILL.md` criterion 8 (Scale agreement) needs: "There is a
## ruler in the picture: the trainer is 1.80m. Measure against them." A
## creature alone against a backdrop cannot be judged for scale at all, which
## is exactly the miss that rubric's own header names -- "the owner spotted,
## instantly, that the largest creature in the game rendered smaller than a
## frog, and this rubric had no question that would have found it."
##
## SUPERSEDES `tools/preview_creatures.gd` FOR THIS PURPOSE, does not replace
## it. `preview_creatures.gd` puts all 17 species in one wide group shot with
## a decorative grey BOX BAR standing in for the trainer's height -- fine for
## "what colour is this species", useless for criterion 8, which tells the
## critic to measure against "the trainer" and hands it a box instead. That
## tool also has no shiny pass, no alpha pass, and one shared frame for the
## whole roster rather than one file per species a critic can open on its
## own. Keep `preview_creatures.gd` for its own job; this tool exists because
## nothing in the repo puts the REAL trainer rig beside one creature at a
## time.
##
## xvfb invocation (`ralph/conventions.md`, "Art pipeline traps already paid
## for" -- copied verbatim, do not improvise a different one):
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_creature_roster.gd
##
## NEVER run this with `--headless` ALSO passed alongside a real rendering
## driver. That exact combination hangs FOREVER with no error, no crash, no
## partial output -- verified on a bare scene with nothing else going on,
## and it is "the single most expensive trap in this repo" per
## conventions.md: four LOD captures, several map captures and two HUD
## captures were all abandoned as "contention" on 2026-08-22 before the real
## cause was found, and a hung run also leaves a ZOMBIE Godot process pinned
## to this worktree after the lane gives up on it. Drop `--headless`, keep
## `xvfb-run` for the virtual display -- `--headless` alone is still correct
## and fast for tests, which render nothing; it is specifically `--headless`
## PLUS a rendering driver that hangs.
##
## THIS FILE WAS NEVER RUN BY THE SESSION THAT WROTE IT. The coordinator runs
## captures later, serially, on a 4-core box already carrying another render
## -- running Godot from inside this authoring session would corrupt that
## in-flight run. Every number below is an engineering estimate against the
## patterns `tools/preview_creatures.gd`, `tools/capture_creature_bed.gd` and
## `tools/_probe_corridor_survey.gd` already prove out, not a measurement of
## THIS scene.
##
## FRAME BUDGET, costed against the worst per-frame number this repo has
## actually measured, not an assumed cheaper one:
##
##   `tools/_probe_corridor_survey.gd` measured ~2.4s per awaited frame under
##   llvmpipe (Compatibility renderer, software rasterised) -- but that cost
##   was paid rendering the FULL standing Meadows world, 143,630 scattered
##   props, every frame. This tool never stands that world up. The whole
##   scene here is a ground plane, one directional light, one trainer rig and
##   one creature at a time -- the same "small purpose-built scene over
##   `meadows_playground.tscn`" choice `capture_creature_bed.gd` already made
##   for exactly this reason. The real per-frame cost of a scene this small
##   should be far below 2.4s, but 2.4s is the only llvmpipe number this repo
##   has on record, so the budget below is costed against it rather than
##   against a guessed cheaper figure:
##
##     17 species x 2 variants (ordinary "vivid" + shiny)
##       x 2 views (front-on + rear three-quarter)            = 68 shots
##     1 alpha-scale demonstration (galecrest, the same pair
##       framing as the 68 above)                             =  1 shot
##     1 line-up frame (5 species + the trainer, one settle)  =  1 shot
##                                                              ----------
##                                                               70 shots
##
##   The rear view doubles the species pass and is worth it: see `REAR_YAW_DEG`
##   for why a front-only survey cannot photograph most of what the owner's
##   board asks these creatures to carry. MEASURED on this box rather than
##   estimated -- the whole 37-frame pass ran in well under a minute, so the
##   pessimistic 2.4s/frame budget below overstates this scene by roughly an
##   order of magnitude and 70 shots is still a sub-two-minute capture.
##
##   Per pair-shot (the 35 that are one creature + the trainer):
##     SETTLE_FRAMES (6, physics_frame) + POSE_FRAMES (2, process_frame)
##     = 8 awaited frames each. 35 x 8 = 280.
##   Line-up shot (five bodies built into the same tiny scene at once, so a
##   longer settle covers all of them landing on the idle crossfade):
##     LINEUP_SETTLE_FRAMES (20) + POSE_FRAMES (2) = 22 awaited frames.
##   One-time boot, before the first shutter (BOOT_FRAMES):
##     10 awaited frames.
##
##   280 + 22 + 10 = 312 awaited frames. 312 x 2.4s = 749s = ~12.5 minutes,
##   at the worst-case per-frame cost this repo has ever recorded, for a
##   scene roughly four orders of magnitude smaller (2 rigs vs 143,630 props)
##   than the one that cost was measured on. Comfortably under the 15-minute
##   target even before the small-scene discount is counted; if the real
##   per-frame cost turns out closer to a normal llvmpipe frame, the actual
##   run will finish in a small fraction of that.
##
## HOW CREATURE MODELS LOAD: `scenes/creatures/creature.tscn` is the same
## deliberately scriptless scene combat uses ($Collision/$Model/$Body/$Head),
## with `scripts/creatures/creature_body.gd` attached after instantiation and
## `setup(species_id, is_shiny)` called after `add_child()` -- that exact
## order, because `setup()` gates its mesh-building on `is_inside_tree()`
## and `_body != null`, both of which only become true once the node has
## actually entered a tree that is iterating (`preview_creatures.gd`'s own
## header, and `starter_picker.gd`'s comment on the same trap, name this
## explicitly). `setup(id, false)` is the game's ORDINARY look: OF28 made the
## "vivid" colourway (`data/creatures/shiny_colourways.json`) the shipped
## default, not an optional extra -- `creature_body._refresh_shiny_tint()`
## swaps to `*_vivid.png` siblings whenever `shiny` is false, and only falls
## back to the raw shipped texture where no colourway file exists. Every one
## of the 17 species in `data/creatures/shiny_colourways.json` has both a
## `rules` (shiny) and a `vivid_rules` block, so `setup(id, false)` is never
## the pre-repaint art. `setup(id, true)` swaps to the `*_shiny.png` set
## instead -- the same call `encounter_director.gd`'s wild roll and
## `starter_picker.gd`'s preview both make, just with the outcome known up
## front instead of rolled.
##
## The trainer loads through a different, code-only path:
## `scripts/npc/npc_body.gd` (extends `character_model.gd`) reads the
## `"trainer"` block of `data/config/art.json` -- height 1.8, matching this
## file's own `TRAINER_HEIGHT` -- and fits `assets/characters/trainer/
## trainer_lod0.glb` to it the same render-space-measured way
## `creature_body._fit()` fits a creature model. `npc_body.setup("trainer",
## null)` (the `null` is the player it would otherwise turn to look at --
## there is none in this capture, and `_process()` is null-safe about it)
## builds a correctly scaled, idle-animated trainer with no player controller
## and no CharacterBody3D physics dependency at all: it is the same call
## Grandpa and every villager NPC make to stand up.
##
## ALPHA/ELITE MATERIAL VARIANTS: the data declares none. Grepped
## `scripts/creatures/*.gd` and every `data/config/bands/*/spawns.json` for
## `alpha`/`elite` before writing this -- `alpha` is a SIZE multiplier only
## (`creature_body.apply_size_multiplier()`, called from
## `encounter_director._make_alpha()`), never a different texture or
## material; there is no "elite" creature material anywhere, only elite
## TRAINERS (ordinary creatures on a harder team, `data/config/trainers.json`
## / `data/config/stronghold.json`), which is a roster question, not a visual
## one. So the one alpha demonstration below is a SCALE shot, not a repaint:
## galecrest at `x1.2`, the largest of the three authored Galecrest alpha
## multipliers (`data/config/bands/band5_stronghold_approach/spawns.json`,
## the pack leader on the last stretch before the Hall; band3 and band4 each
## author their own Galecrest alpha lower on the same escalating ladder).
## BACKLOG-VISUAL-ALPHA-SCALE dropped all three off their old 1.3/1.3/1.4:
## that old top value read as barely bigger than an ordinary Tuskroot on a
## census AND, uncaught until then, stood taller than the Veridian Stag
## legendary at ordinary Galecrest's post-D69 2.10m height.
##
## Output: `res://shots/creatures/NN-<species>.png` for all 17 species (their
## ordinary/vivid look, the one the game actually ships), plus
## `NN-<species>-shiny.png` for the rare colourway, `13-galecrest-alpha.png`
## for the one alpha demonstration, and `00-lineup.png` for the multi-species
## comparison frame.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const NPC_BODY := preload("res://scripts/npc/npc_body.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const OUT_DIR := "res://shots/creatures"

## Metres. Matches `data/config/art.json`'s `trainer.height` exactly -- this
## constant is never used to BUILD the trainer (that reads the real config),
## only to print the ratio beside every measured creature height.
const TRAINER_HEIGHT := 1.8

## Order taken directly from the task's "WHAT TO SHOOT" list, which is also
## `data/creatures/species.json`'s own roster comment order. Numbering below
## (`01`..`17`) follows this array's index, not alphabetical order, so a
## human can cross-check the filename against the brief that asked for it.
const ORDER: Array[String] = [
	"terrapup", "ripplet", "galewisp", "bramblebun", "mudsnout", "trailpup",
	"burrowback", "meadowhart", "tuskroot", "paddlenewt", "mosshell",
	"brooktail", "galecrest", "duskhush", "pipwing", "reedwing", "veridian",
]

## The one alpha this pass demonstrates, and why: see the header's ALPHA
## MATERIAL VARIANTS note. `13` matches galecrest's own index in `ORDER`
## above, so the file sorts next to `13-galecrest.png` / `-shiny.png`.
const ALPHA_SPECIES := "galecrest"
const ALPHA_SCALE := 1.2
const ALPHA_INDEX := 13

## Five species answering the rubric's own example question -- "is the one
## you fight alongside bigger than the one you practise on" -- across the
## full size range D19 actually authored (1.35m to 2.60m):
##   pipwing    1.35m  the smallest thing in the biome
##   bramblebun 1.50m  "The practice creature" (species.json's own words) --
##                     common, generous to catch, the one you throw orbs at
##                     twenty times before deciding whether throwing is fun
##   terrapup   2.00m  a starter partner -- species.json calls it "the one
##                     that must never be lost in a frame", i.e. the one you
##                     fight ALONGSIDE
##   tuskroot   2.15m  "the one that comes at you" -- aggressive, evolved,
##                     the biome's one evolution line
##   veridian   2.60m  the legendary, above every other creature on purpose
##                     (D12: "above all of them")
const LINEUP_SPECIES: Array[String] = ["pipwing", "bramblebun", "terrapup", "tuskroot", "veridian"]
const LINEUP_X: Array[float] = [-3.6, -1.2, 1.4, 4.0, 6.8]
const LINEUP_TRAINER_X := -6.0

## --- fixed pair framing: identical for every one of the 35 pair shots -----
const PAIR_TRAINER_POS := Vector3(-2.3, 0.0, 0.0)
const PAIR_CREATURE_POS := Vector3(0.0, 0.0, 0.0)
## Every species is shot twice: front-on, and turned away from the camera.
##
## The rear view exists because a front-only survey cannot photograph what the
## owner's own creature board gives several species as their IDENTIFYING
## feature, and those features are dorsal: terrapup's leaf growth over the back
## and shoulders, burrowback's stacked stone shell plates, trailpup's shoulder
## growth and mudsnout's moss crown, plus every `overlays`/`overlays_shiny`
## entry in `shiny_colourways.json` whose `where` block selects on `up_min` --
## which is most of them, because moss and leaf growth sit on upward-facing
## surfaces by definition. Measured while raising terrapup's leaf coverage:
## the green share of its chromatic texels went 3.8% -> 11.3%, a tripling, and
## the front-on frame barely moved, because nearly all of it is on the back.
##
## A survey that cannot show the thing it changed cannot be judged on it, which
## is the same class of defect `ralph/VISUAL_LEDGER.md` already records six of
## under "this sweep's own harness defects". 145 degrees rather than a flat 180
## so the frame still carries some of the head and flank and reads as a
## three-quarter rear rather than a wall of back.
const REAR_YAW_DEG := 145.0

const CAM_POS := Vector3(-1.15, 1.55, 7.0)
const CAM_LOOK := Vector3(-1.15, 1.35, 0.0)
const FOV := 42.0

## --- line-up framing: its own shot, not held to "identical to the pairs" -
##
## BACKLOG-VISUAL-PIPWING-LINEUP-SCALE. Pipwing (0.76m, `species.json`) is the
## smallest lineup subject and sits closest to camera-centre in X (offset 3.8m
## from `LINEUP_CAM_POS.x`), while the ruler -- the trainer, at `LINEUP_TRAINER_X`
## -- sits 6.2m off-axis. At the OLD framing (z=13, fov=46) that put Pipwing
## roughly 6% CLOSER to the camera than the trainer it is measured against
## (13.5m vs 14.4m along the camera's view axis): real perspective foreshortening,
## not a data or seating bug -- `_seat_on_ground()` runs identically for every
## lineup subject and the single-species pass, and both read the same
## `species.json` height. A census caught it as "0.77m in its own frame vs
## 1.05m in the lineup" -- a ~36% swing -- because that ~6% distance skew reads
## as a much bigger PERCENTAGE error against a subject this small, while the
## other four lineup subjects (closer in absolute height to the trainer, so the
## same skew is a smaller fraction of them) "reconciled to within 2-4%" per the
## same census. Pulling the camera back and narrowing the FOV to match keeps
## every subject at the same screen position (same visible half-width at the
## new distance) while roughly quartering the relative camera-distance spread
## between the nearest and farthest subjects (was ~6.4% trainer-to-Pipwing,
## now ~1.8%), which is the actual lever for this class of error, not anything
## in the game's own transform data.
const LINEUP_CAM_POS := Vector3(0.2, 1.9, 26.0)
const LINEUP_CAM_LOOK := Vector3(0.2, 1.5, 0.0)
const LINEUP_FOV := 24.0

const BOOT_FRAMES := 10
const SETTLE_FRAMES := 6
const LINEUP_SETTLE_FRAMES := 20
const POSE_FRAMES := 2

var _world: Node3D = null
var _trainer: Node3D = null
var _camera: Camera3D = null


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	# `_init()` runs before the SceneTree itself starts iterating: nodes
	# added here get `_ready()` called (their `$Path` children resolve) but
	# `is_inside_tree()` stays false until the first yield back to the
	# engine. `creature_body.gd::setup()` gates its mesh-building on that
	# exact check -- `preview_creatures.gd`'s own header names this as the
	# cause behind a reverted attempt that silently built nothing. One frame
	# here, before anything else, is enough; every add_child()/setup() pair
	# after this point is already past the boundary and needs no further
	# per-node wait.
	await process_frame

	_world = Node3D.new()
	root.add_child(_world)
	_build_environment()

	for i in BOOT_FRAMES:
		await physics_frame
	print("[creature-roster] stage up, boot settled; starting the pass")

	await _run_species_pass()
	await _alpha_shot()
	await _lineup_shot()

	print("")
	print("creature roster written to %s" % OUT_DIR)
	print("Software rendering under the Compatibility renderer: composition,")
	print("colour and relative scale are trustworthy; frame times are not a")
	print("performance measurement.")
	quit(0)


## Ground, light and the one trainer/camera pair every non-line-up shot
## reuses without moving -- lighting copied from `preview_creatures.gd`,
## already the established "what colour is this creature, actually" recipe
## (flat ambient, ACES tonemap, neutral grey ground) rather than a new one.
func _build_environment() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.20, 0.22, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.82)
	# CALIBRATED, not chosen. This stage was over-exposing every subject by a
	# measured 2.3x and three consecutive blind creature rounds spent their
	# top-ranked finding on the result -- "the roster floats in high-key pastel",
	# "25-50% of body highlight regions clipped to pure white", and a duskhush
	# reported as "candy lavender" whose own albedo texture measures mean 65.6
	# with a 95th percentile of 135, i.e. a genuinely dark plum owl. The art was
	# not pastel; the photograph was.
	#
	# The proof is in the frame itself and costs nothing to re-check: the
	# BACKDROP is `BG_COLOR` and is not lit, and it renders at exactly its
	# authored (51,56,61). The FLOOR carries albedo (0.30,0.33,0.30), which
	# should land near (77,84,77), and it rendered at (174,200,184) -- 2.26x,
	# 2.38x, 2.39x per channel. Anything lit was that far off; anything unlit was
	# exact.
	#
	# Cause was simple addition: ambient 1.5 at a near-white colour is already
	# ~1.17 of light before the 1.6 key adds ~0.91 more at this elevation, and
	# these creature materials are ALSO self-lit (the painted albedo is wired
	# into the emission slot, tamed but not removed by
	# creatures_visual.json's `emission_scale`). Three sources summing past 3.0
	# where a neutral stage wants ~1.0.
	#
	# Set in two measured passes: 1.5/1.6 gave 2.3x, 0.55/0.85 gave 1.26x,
	# 0.44/0.68 landed it at 1.0; adding the rim light below pushed it back to 1.31,
	# so 0.35/0.55 re-lands it WITH the rim. The floor is the target, always. The values below are set so the floor renders at its own albedo. THE FLOOR
	# IS THE CALIBRATION TARGET: if a change here makes it drift off (77,84,77)
	# again, the survey is lying about colour and every verdict taken from it
	# inherits the error. Re-measure it, do not eyeball it.
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_node.environment = env
	_world.add_child(env_node)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(-35.0), 0.0)
	key.light_energy = 0.55
	# Godot defaults DirectionalLight3D.shadow_enabled to FALSE, and a bare
	# stage that does not set it renders every subject with no contact shadow at
	# all. A blind critic read exactly that off this survey's first run --
	# "everything floats on the pale ground like a sticker" -- and could not tell
	# whether it was the survey rig or the shipped renderer dropping creature
	# shadows. It is the rig: world_look.gd sets sun.shadow_enabled from art.json
	# defaulting to TRUE, so the real world casts them and only this stage did
	# not. A contact shadow is also what plants a creature on the ground plane,
	# which is half of judging its scale against the trainer.
	key.shadow_enabled = true
	_world.add_child(key)

	# A low RIM from behind, so a dark creature can never fall below its own
	# backdrop. A blind round measured galecrest's rare at mean luminance 43
	# against a 56 backdrop -- "a black cutout; eyes, feather pattern, everything
	# gone, the least readable frame on the sheet" -- and brooktail did the same
	# thing earlier. Those are art problems and are fixed in the colourways, but
	# the STAGE should not be the reason a legitimately dark creature becomes
	# unjudgeable: a roster is allowed dark members, and the survey has to be able
	# to photograph them. A rim separates a dark silhouette from a dark ground
	# without touching the exposure the floor is calibrated to -- it is aimed away
	# from the camera and carries no shadow, so it adds an edge and nothing else.
	var rim := DirectionalLight3D.new()
	rim.rotation = Vector3(deg_to_rad(-18.0), deg_to_rad(158.0), 0.0)
	rim.light_energy = 0.5
	rim.light_color = Color(0.86, 0.90, 1.0)
	rim.shadow_enabled = false
	_world.add_child(rim)

	# Decorative only, no collision -- both the trainer (a StaticBody3D under
	# npc_body.gd, no gravity) and every creature (physics_process frozen
	# below, the same fix preview_creatures.gd uses for a CharacterBody3D
	# with nothing to stand on) place themselves at y=0 directly rather than
	# falling onto a floor.
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.33, 0.30)
	floor_mesh.material_override = mat
	_world.add_child(floor_mesh)

	_trainer = Node3D.new()
	_trainer.set_script(NPC_BODY)
	_world.add_child(_trainer)
	_trainer.call("setup", "trainer", null)
	_trainer.global_position = PAIR_TRAINER_POS

	_camera = Camera3D.new()
	_camera.fov = FOV
	_world.add_child(_camera)
	_camera.global_position = CAM_POS
	_camera.look_at(CAM_LOOK, Vector3.UP)
	_camera.make_current()


## The 17 x 2 pass: every species, ordinary then shiny, trainer and camera
## never moving between them so the sheet is a real comparison rather than
## 34 independently-framed pictures.
func _run_species_pass() -> void:
	for i in ORDER.size():
		var id := ORDER[i]
		var idx := i + 1
		await _species_shot(idx, id, false, 0.0)
		await _species_shot(idx, id, true, 0.0)
		await _species_shot(idx, id, false, REAR_YAW_DEG)
		await _species_shot(idx, id, true, REAR_YAW_DEG)


## `yaw_deg` turns the CREATURE, never the camera -- the same choice
## `_capture_character_cast.gd` makes, and for the same reason: two frames that
## differ only in what is being photographed, never in how.
func _species_shot(idx: int, id: String, is_shiny: bool, yaw_deg: float) -> void:
	var suffix := "-shiny" if is_shiny else ""
	var view := "-rear" if not is_zero_approx(yaw_deg) else ""
	var name := "%02d-%s%s%s" % [idx, id, suffix, view]
	if not SPECIES.has(id):
		print("FAIL %s: no entry in data/creatures/species.json" % name)
		return

	var body := _spawn_creature(id, is_shiny, PAIR_CREATURE_POS, yaw_deg)
	for i in SETTLE_FRAMES:
		await physics_frame

	var path := "%s/%s.png" % [OUT_DIR, name]
	var ok: bool = await _capture(path)
	if ok:
		_report(name, body, "")
	body.queue_free()


## Not a texture variant (see the header's ALPHA/ELITE note) -- the data has
## none -- so this reuses the exact pair framing every ordinary/shiny shot
## uses, with the creature's gameplay size multiplied the same way
## `encounter_director._make_alpha()` does it in the real world.
func _alpha_shot() -> void:
	var body := _spawn_creature(ALPHA_SPECIES, false, PAIR_CREATURE_POS)
	body.call("apply_size_multiplier", ALPHA_SCALE)
	for i in SETTLE_FRAMES:
		await physics_frame

	var name := "%02d-%s-alpha" % [ALPHA_INDEX, ALPHA_SPECIES]
	var path := "%s/%s.png" % [OUT_DIR, name]
	var ok: bool = await _capture(path)
	if ok:
		var ordinary: float = float(SPECIES.placeholder(ALPHA_SPECIES).get("height", 0.0))
		_report(name, body, "  (ordinary %.2fm x%.1f alpha scale, data/config/bands/band5_stronghold_approach/spawns.json)" % [ordinary, ALPHA_SCALE])
	body.queue_free()


## One frame, five species, the trainer moved to the end of the line rather
## than a second copy built beside it -- five rigged bodies plus one trainer
## is still a tiny scene next to the 143,630-prop world this budget is
## costed against.
func _lineup_shot() -> void:
	_trainer.global_position = Vector3(LINEUP_TRAINER_X, 0.0, 0.0)

	var bodies: Array[Node3D] = []
	for i in LINEUP_SPECIES.size():
		var id := LINEUP_SPECIES[i]
		var at := Vector3(LINEUP_X[i], 0.0, 0.0)
		bodies.append(_spawn_creature(id, false, at))

	_camera.fov = LINEUP_FOV
	_camera.global_position = LINEUP_CAM_POS
	_camera.look_at(LINEUP_CAM_LOOK, Vector3.UP)

	for i in LINEUP_SETTLE_FRAMES:
		await physics_frame

	var path := "%s/00-lineup.png" % OUT_DIR
	var ok: bool = await _capture(path)
	if ok:
		for i in LINEUP_SPECIES.size():
			_report("  " + LINEUP_SPECIES[i], bodies[i], "")
		print("  00-lineup            wrote %d species + the trainer" % LINEUP_SPECIES.size())
	else:
		print("FAIL 00-lineup: could not stage the line-up frame")

	for body in bodies:
		body.queue_free()


## `creature.tscn` is deliberately scriptless -- its $Collision/$Model/$Body/
## $Head children are what creature_body.gd's @onready vars resolve against
## -- so the scene is instantiated first, added to the (already live) world,
## and only then does the script attach and `setup()` run. Same order
## `preview_creatures.gd` and `starter_picker.gd::_build_preview()` both use,
## for the same is_inside_tree() reason the header above explains.
func _spawn_creature(id: String, is_shiny: bool, at: Vector3, yaw_deg: float = 0.0) -> Node3D:
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.name = "Shot_%s_%s" % [id, ("shiny" if is_shiny else "ordinary")]
	body.set_script(BODY)
	_world.add_child(body)
	body.call("setup", id, is_shiny)
	body.global_position = at
	# Turned BEFORE seating, because `_seat_on_ground` measures a render-space
	# AABB and a yawed body presents a different one.
	body.rotation.y = deg_to_rad(yaw_deg)
	# No floor collider under it (see `_build_environment`'s comment); a
	# CharacterBody3D with nothing to stand on falls under gravity every
	# physics frame, which `preview_creatures.gd` already found the hard way.
	# Nothing here needs to move.
	body.set_physics_process(false)
	_seat_on_ground(body, at)
	return body


## Put the model's FEET on the ground line, not its pivot.
##
## Species models do not agree about where their origin sits -- some carry it
## at the mesh centre, some at the sole -- so placing every body at the same
## `global_position.y` leaves some floating and some sunk, by whatever each
## model's own authoring happened to choose. A blind critic caught this from
## the frames alone and named the consequence exactly: "creatures stand at
## inconsistent depths... in the lineup Terrapup reads TALLER than the trainer,
## which contradicts 'starter pup'. Pin every creature's pivot to the trainer's
## ground line or the ruler lies."
##
## That is the whole point of this survey, so it is worth the extra measure:
## criterion 8 asks a critic to compare each creature against a 1.80m human,
## and a subject sunk 20cm into the floor is a subject reported 20cm short.
## Measured in render space via `render_bounds.gd` for the same reason
## `_measured_height()` does -- a naive node-chain measurement once blew the
## 1.80m trainer up to 180m on a skinned rig.
func _seat_on_ground(body: Node3D, at: Vector3) -> void:
	var pivot: Node3D = body.get_node_or_null(^"Model") as Node3D
	if pivot == null:
		return
	var box: AABB = RENDER_BOUNDS.measure(pivot)
	if box.size == Vector3.ZERO:
		return
	# `measure()` reports in the pivot's own local space, so the offset it
	# implies has to be applied through the pivot's scale to land in world units.
	var foot: float = box.position.y * pivot.global_transform.basis.get_scale().y
	body.global_position = Vector3(at.x, at.y - foot, at.z)


func _capture(path: String) -> bool:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % path.get_file())
		return false
	if image.save_png(path) != OK:
		print("FAIL %s: save_png" % path.get_file())
		return false
	return true


## The number that makes criterion 8 checkable rather than arguable: how
## tall the model ACTUALLY renders, in the same render-space measurement
## `character_model.gd` already trusts for the trainer himself
## (`render_bounds.gd`'s whole reason to exist is that a naive node-chain
## measurement blew a 1.80m trainer up to 180m on a skinned rig once). A
## creature's `$Model` pivot carries only rotation, never scale -- the fit
## scale lives on its child -- so measuring the pivot in its own local space
## reads exactly what `creature_body._fit()` actually produced, including
## the cases where the footprint-volume clamp shrinks a model below its
## species.json `height` on purpose.
func _measured_height(body: Node3D) -> float:
	var pivot: Node3D = body.call("model_pivot") as Node3D
	if pivot != null:
		var box: AABB = RENDER_BOUNDS.measure(pivot)
		if box.size.y > 0.0001:
			return box.size.y
	return float(body.call("body_height"))


func _report(name: String, body: Node3D, extra: String) -> void:
	var measured := _measured_height(body)
	var has_model: bool = bool(body.call("has_model"))
	var tag := "" if has_model else "  WARN no model found, capsule fallback shot instead"
	print("  %-24s %5.2fm measured, trainer 1.80m, %.2fx%s%s" % [
		name, measured, measured / TRAINER_HEIGHT, extra, tag])
