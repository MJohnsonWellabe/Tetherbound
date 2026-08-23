extends CharacterBody3D

## The physical body of a creature: how it looks, and how it moves.
##
## A CharacterBody3D rather than a Node3D because combat is piloted
## (docs/decisions/D07). Both fighters move under their own power over the same
## terrain the trainer walks on, so they need the same collision treatment. The
## earlier version faked motion by offsetting a mesh, which was fine for a fight
## in which nobody moved and is wrong now.
##
## Everything above this — the combat manager, the AI, the encounter director —
## talks to `request_move`, `add_impulse`, `face_towards` and `place_on_ground`,
## and never touches `velocity`. That is what lets the player's creature and the wild
## one share one movement implementation while being driven by a stick and by a
## state machine respectively.
##
## M11 replaces `_build_placeholder` with a rigged model. Nothing else here
## changes.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const ANIMATOR := preload("res://scripts/creatures/creature_animator.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const VISUAL := preload("res://scripts/creatures/creature_visual.gd")
const BUILT_FLOOR := preload("res://scripts/world/built_floor.gd")
const ALPHA_AURA := preload("res://scripts/creatures/alpha_aura.gd")

## CREATURE-IDENTITY-2 alpha presence. Warm gold rather than a warning red:
## an alpha is a bigger animal, not an attack telegraph, and combat already owns
## red (`combat/telegraph_glow.gd`). Tunable here rather than in config because
## these are one look, not a per-region balance number -- if the roster ever
## wants per-species alpha colours they belong in the species table, not in a
## global.
const ALPHA_RIM_STRENGTH := 0.65
const ALPHA_RIM_TINT := 0.15
const ALPHA_AURA_COLOUR := Color("#ffd479")

## The grounding ray starts this far above the requested spot and traces this far
## down.
##
## Generous on purpose. At 12m up, a spawn point on a hill started the ray
## *inside* the terrain — a downward ray from underground never exits, so the
## placement failed silently and the creature was never spawned at all. The
## playground's relief is about 72m, so the start has to clear the tallest thing
## that can be above a point the caller thought was ground level.
const GROUND_PROBE_UP := 120.0
const GROUND_PROBE_DOWN := 300.0

## How much wider than its collider a creature's art may be.
##
## Above 1 because a quadruped's body legitimately overhangs the capsule that
## represents it — a fox is longer than it is wide and the collider is a
## cylinder. Far above 1 and creatures visibly interpenetrate before their
## colliders touch, which reads as attacks landing at the wrong distance.
const FOOTPRINT_ALLOWANCE := 2.4

## OF27 placeholder tint: a deliberately garish magenta-shift multiply,
## applied to both albedo AND emission (see `_shared_variant_material`'s own
## comment for why emission has to be included). This is not the shiny
## LOOK — OF28 owns that, per-species, in real palette data — it exists only
## to prove the roll -> save -> tint pipeline actually changes what renders.
## Values above 1.0 on purpose: multiplying a mid-value albedo by ~1 leaves it
## nearly unchanged, and "nearly unchanged" is exactly the kind of tint that
## silently fails to prove anything in a screenshot.
const SHINY_PLACEHOLDER_TINT := Color(2.6, 0.12, 2.6)

var species_id: String = ""
var display_name: String = ""

## OF27: "make a version that is a 'shiny' like Pokemon go... nothing
## different than just the colors" (owner report). Set through `setup()`/
## `set_shiny()`, never rolled here — this node draws whatever it is told,
## the same way it never decides its own species.
var shiny: bool = false

## CREATURE-IDENTITY-2. Whether this body is its cluster's ALPHA.
##
## WILD-ECOLOGY (prompt 60) already spawns cluster leaders with a level bonus
## and a size multiplier, and `encounter_director._make_alpha` sets a meta flag
## so a test can find one -- but nothing about an alpha's PRESENTATION differed
## from its neighbours', so at the distance where a 1.3x size difference is
## ambiguous (which is most distances, with no ordinary member of the same
## species conveniently standing beside it) the player had no way to know a
## fight was going to be harder than the last one.
##
## Set through `set_alpha()`, never decided here -- same rule as `shiny`.
var alpha: bool = false

var _height: float = 1.0
var _radius: float = 0.4
var _footprint_allowance: float = FOOTPRINT_ALLOWANCE

## Requested movement for this physics frame, cleared after it is consumed.
## Cleared rather than latched on purpose: a driver that stops driving stops the
## creature, so a state machine that forgets to say "stand still" cannot leave a
## creature sliding across the arena forever.
var _requested: Vector3 = Vector3.ZERO
var _requested_speed: float = 0.0

## Attack lunges and knockbacks, decaying. Separate from `velocity` so being hit
## mid-stride reads as a shove rather than as a cancelled input.
var _impulse: Vector3 = Vector3.ZERO

var _speed: float = 5.0
var _acceleration: float = 34.0
var _friction: float = 30.0
var _turn_speed: float = 13.0
var _gravity: float = 26.0
var _impulse_damping: float = 9.0

## Optional arena that holds this creature inside a boundary. Null outside
## combat, which is why the wild creature can wander freely before it is engaged.
var arena: Node = null

## The world node that answers `ground_height_at`. Found once, then cached.
var _ground_source: Node = null

## True when a real model loaded. False means the capsule fallback is showing,
## which is a visible, reported failure rather than a silent one.
var _has_model: bool = false

## Drives the model's clips. Null when a creature fell back to the capsule,
## which has nothing to animate.
var _animator: RefCounted = null

@onready var _collision: CollisionShape3D = $Collision
@onready var _model: Node3D = $Model
@onready var _body: MeshInstance3D = $Body
@onready var _head: MeshInstance3D = $Head


## The pivot the art hangs off. Procedural motion moves this, never the body:
## the body's position is gameplay and belongs to the combat manager.
func model_pivot() -> Node3D:
	return _model


func has_model() -> bool:
	return _has_model


func _ready() -> void:
	_load_config()
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()
	if species_id != "" and _body != null:
		_build_placeholder()


## A hidden creature is switched off entirely — no physics, no collider.
##
## The player's creature exists in the world the whole time and is only hidden
## outside combat, so that deploying it is not a hitch in the one frame that
## most needs to be smooth. But an invisible CharacterBody3D standing inside the
## trainer is still a solid object, and two overlapping bodies resolve the
## overlap by shoving each other apart: the trainer was launched off the
## playground at 500 m/s, accelerating, on the first frame of every run.
func _on_visibility_changed() -> void:
	set_physics_process(visible)
	if _collision != null:
		# Deferred because visibility is usually flipped from inside a physics
		# callback, and changing a collider's state mid-step is not allowed.
		_collision.set_deferred("disabled", not visible)


func _load_config() -> void:
	var cfg: Dictionary = MATH.config().get("creature_movement", {})
	_speed = float(cfg.get("speed", _speed))
	_acceleration = float(cfg.get("acceleration", _acceleration))
	_friction = float(cfg.get("friction", _friction))
	_turn_speed = float(cfg.get("turn_speed", _turn_speed))
	_gravity = float(cfg.get("gravity", _gravity))
	_impulse_damping = float(cfg.get("impulse_damping", _impulse_damping))


## Configure from the species table. Safe to call before or after the node is in
## the tree; the mesh is built on whichever happens second.
##
## `is_shiny` defaults false so every existing caller that has not been
## taught about OF27 yet keeps building the ordinary, untinted body it always
## has. A wild spawn is the one caller that does not know its own shiny
## status yet at `setup()` time (the roll happens after `populate()` calls
## this) — see `set_shiny()` below for how that one re-tints after the fact.
func setup(id: String, is_shiny: bool = false) -> void:
	species_id = id
	shiny = is_shiny
	display_name = str(SPECIES.definition(id).get("display_name", id))
	if is_inside_tree() and _body != null:
		_build_placeholder()


## Change shiny status on a body that may already be built, and re-tint it —
## the wild-spawn path: `encounter_director._roll_wild_level` rolls the
## outcome from the seeded per-spawn stream AFTER `populate()` has already
## called `setup()` and built this body (the shiny draw has to be the
## stream's LAST draw, so every earlier draw stays byte-for-byte what it was
## before OF27 — see that function's own comment). A no-op if the status has
## not actually changed, so a caller that calls this defensively every frame
## cannot re-tint (and re-cache) a material it already tinted.
func set_shiny(value: bool) -> void:
	if shiny == value:
		return
	shiny = value
	_refresh_shiny_tint()


## CREATURE-IDENTITY-2. Mark this body as its cluster's alpha and re-dress it.
##
## Same shape and the same reasons as `set_shiny()` above: the director decides
## alpha status in `_make_alpha()` AFTER the body has been built and populated,
## so this has to work on an existing body, and it is a no-op when the status
## has not changed so a defensive caller cannot re-swap a material every frame.
func set_alpha(value: bool) -> void:
	if alpha == value:
		return
	alpha = value
	_refresh_shiny_tint()


## PW2 (BAND1-D1). An individual's gameplay size as a multiple of its
## species' own, for alpha/elder variants: 1.0 is an ordinary creature.
##
## It scales `_height` and `_radius` TOGETHER, before the capsule is built,
## which is the only correct place for it. PW2's own rule is "do not alter
## hitboxes merely because visual scale changes unless current creature
## collision already derives safely from scale" -- and the note below is why
## scaling the art instead would break exactly that: the collider, the hit
## cone's reach and the catch accuracy bonus all read `_height`/`_radius`, and
## `_fit()` then scales the model to match. Scale those two and the art, the
## reach and the catch odds all move together. Scale the node and only the
## picture changes, which is the invisible discrepancy PW2 forbids.
##
## Must be set BEFORE `populate()`; afterwards the capsule already exists.
var body_scale: float = 1.0


func _build_placeholder() -> void:
	var look: Dictionary = SPECIES.placeholder(species_id)
	var size_factor: float = maxf(body_scale, 0.01)
	_height = float(look.get("height", 1.0)) * size_factor
	_radius = float(look.get("radius", 0.4)) * size_factor
	# How long a body may be for its width, as a multiple of its collider
	# diameter. Per species because it is a fact about the animal: a triceratops
	# is genuinely several times longer than it is wide and a frog is not.
	_footprint_allowance = float(look.get("footprint_allowance", FOOTPRINT_ALLOWANCE))

	# The collider is built from the SPECIES, never from the art.
	#
	# Gameplay size is `height` and `radius`, and those drive the capsule, the
	# hit cone's reach, and the catch accuracy bonus through `body_radius()`.
	# Art is then scaled to fit that. The other way round — letting a model's
	# bounding box set the collider — means importing a new creature silently
	# retunes combat, and a fight that changes because an artist exported at a
	# different scale is not a fight anybody can tune.
	var shape := CapsuleShape3D.new()
	shape.radius = _radius
	shape.height = maxf(_height, _radius * 2.0 + 0.01)
	_collision.shape = shape
	_collision.position = Vector3(0.0, _height * 0.5, 0.0)

	if not _build_model(look):
		_build_capsule(look)
	_refresh_shiny_tint()


## Load the species' model and fit it to the gameplay size. Returns false when
## there is nothing to load or it failed, so the caller can fall back.
func _build_model(look: Dictionary) -> bool:
	var path := str(look.get("model", ""))
	if path == "":
		return false
	if not ResourceLoader.exists(path):
		push_error("species '%s' names a model at %s that does not exist" % [species_id, path])
		return false
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("species '%s' model at %s did not load as a scene" % [species_id, path])
		return false

	for child in _model.get_children():
		child.free()
	var art: Node3D = packed.instantiate() as Node3D
	if art == null:
		push_error("species '%s' model root is not a Node3D" % species_id)
		return false
	_model.add_child(art)
	_fit(art, float(look.get("model_scale", 1.0)))

	# Sourced models point in whatever direction their author chose, and there
	# is no convention to rely on. Combat faces creatures along +Z (`facing()`),
	# so this is the per-species correction, verified by looking at a survey
	# frame rather than assumed.
	_model.rotation.y = deg_to_rad(float(look.get("model_yaw", 0.0)))

	_body.visible = false
	_head.visible = false
	_has_model = true
	_build_animator(art, look)
	return true


## Wire the model's AnimationPlayer to the role names the species declares.
##
## Clip names are per-pack and live in data: the shipped creatures use
## `Armature|Frog_Attack` and `Armature|Triceratops_Run`. Nothing in code knows
## those strings, so a new creature is a data edit.
func _build_animator(art: Node3D, look: Dictionary) -> void:
	var players: Array[Node] = art.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		push_warning("model for '%s' has no AnimationPlayer; it will not animate" % species_id)
		return
	_animator = ANIMATOR.new(players[0] as AnimationPlayer, look.get("animations", {}))


## Scale and centre an imported model so it stands on the node's origin at the
## species' gameplay height.
##
## Every model arrives differently: measured across the three shipped creatures,
## one was 263 units tall with its origin at its middle, one was 94 units with
## the same problem, and one was 3.8 units standing on its feet. Hand-tuning a
## scale and an offset per model is three magic numbers per species that nobody
## can check. Measuring the bounds and fitting is none.
func _fit(art: Node3D, extra_scale: float) -> void:
	var box := _bounds(art)
	if box.size.y <= 0.0001:
		push_warning("model for '%s' has no measurable height; leaving it unscaled" % species_id)
		return

	# Fit to the gameplay VOLUME, not just to the height.
	#
	# Scaling by height alone works for something upright and fails badly for
	# anything low and long: the shipped rabbit measures nearly as wide and deep
	# as it is tall, so matching its height gave a two-metre-wide rabbit sitting
	# next to a fox half its footprint. Taking the tighter of the two fits keeps
	# a creature inside the space its collider claims.
	#
	# But the clamp must never shrink a creature QUIETLY, and it used to.
	#
	# A long quadruped fitted to its height overruns a footprint allowance
	# written for compact creatures, so it was scaled back down — and rendered
	# visibly shorter than the height its own collider claims, while a stubby
	# creature beside it got its full declared size. That is the exact "art and
	# gameplay disagree" failure this function exists to prevent, and it hid
	# because `smoke_art` allowed 0.35m of slack. The owner spotted it before any
	# test did.
	#
	# So: the allowance is per species, because how long a body is for its width
	# is a fact about the animal; and when the clamp does bite, it says so.
	var footprint := maxf(box.size.x, box.size.z)
	var fit := _height / box.size.y
	if footprint > 0.0001:
		var allowed: float = (_radius * 2.0 * _footprint_allowance) / footprint
		if allowed < fit:
			push_warning(("'%s' is %.0f%% longer than its footprint allowance and " % [
				species_id, (fit / allowed - 1.0) * 100.0
			]) + ("has been scaled down to %.2fm instead of the %.2fm its collider claims. " % [
				_height * allowed / fit, _height
			]) + "Raise `footprint_allowance` or `radius` for this species.")
		fit = minf(fit, allowed)
	fit *= maxf(extra_scale, 0.01)
	art.scale = Vector3.ONE * fit
	# Feet to the origin, and centred on it horizontally.
	art.position = Vector3(
		-(box.position.x + box.size.x * 0.5) * fit,
		-box.position.y * fit,
		-(box.position.z + box.size.z * 0.5) * fit
	)


## Measure a model as it will actually render.
##
## Through `render_bounds.gd`, which is the shared answer to the two ways this
## measurement has been wrong: `global_transform` races add_child (a fitted
## Triceratops 528 metres tall), and a local node chain never sees a SKIN's
## scale (a 180-metre trainer that every AABB test swore was 1.80m). The
## creature models are authored with skin and armature both at 1.0, so for
## them this is the same number the old chain produced — the guard is against
## the next asset that is not.
func _bounds(node: Node3D) -> AABB:
	return RENDER_BOUNDS.measure(node)


## The original capsule, now only a fallback. A missing model renders as this
## and says so, rather than leaving an invisible creature the player can still
## be killed by.
func _build_capsule(look: Dictionary) -> void:
	var colour := Color(str(look.get("colour", "#cccccc")))
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85

	var torso := CapsuleMesh.new()
	torso.radius = _radius
	torso.height = maxf(_height, _radius * 2.0 + 0.01)
	_body.mesh = torso
	_body.material_override = material
	_body.position = Vector3(0.0, _height * 0.5, 0.0)
	_body.visible = true

	# A smaller sphere forward and high, so the capsule has a front. Without it
	# there is no reading which way a creature is facing — and in a fight where
	# attacks are aimed, facing is the information the player needs most.
	var snout := SphereMesh.new()
	snout.radius = _radius * 0.55
	snout.height = _radius * 1.1
	_head.mesh = snout
	_head.material_override = material
	_head.position = Vector3(0.0, _height * 0.82, _radius * 0.9)
	_head.visible = true
	_has_model = false


## --- variant tinting (OF27) --------------------------------------------------
##
## Modelled directly on `scripts/characters/character_model.gd`'s
## `_apply_palette`/`_palette_node`/`_shared_variant_material` — same
## dict-of-material-name-to-colour contract, same recursive walk, same shared-
## material cache, same emission fix. Kept as a second implementation rather
## than a shared one because the two operate on different shapes (that file
## takes hex strings through `art.json`; this one takes `Color`s directly,
## since OF27 has no palette data file yet to hold hex strings in — see
## `_shiny_palette()`) and because creature_body.gd already has no dependency
## on scripts/characters/, which this would otherwise create.

## Re-applies (or applies for the first time) whatever tint `shiny` implies.
## Called after every model/capsule build, and from `set_shiny()` when shiny
## status changes on a body that already exists. Does nothing when not shiny
## — OF27 never needs to UN-tint a body, because nothing ever un-shinies a
## creature once rolled, so there is no "restore the original material" path
## to maintain.
func _refresh_shiny_tint() -> void:
	## OF28 (owner directive, quoted in ralph/BACKLOG.md): a colourway is a
	## REPAINT, never a tint — "if our newt is blue, I want red. not blue
	## with a red shade over it." tools/repaint_creature_textures.py writes
	## two sets of siblings from data/creatures/shiny_colourways.json:
	## `*_vivid.png` (the ORDINARY creature, repainted off the shipped
	## naturalistic mud toward the mystical palette — "more mystical like in
	## palworld") and `*_shiny.png` (the rare variant). Both swap albedo AND
	## emission, because the emission channel carries the same painted image
	## on these assets and swapping albedo alone would be invisible (the NP2
	## lesson, again).
	##
	## A shiny with no authored colourway falls back to OF27's placeholder
	## tint so it is never silently indistinguishable; an ordinary creature
	## with no vivid colourway simply keeps its shipped texture.
	##
	## CREATURE-IDENTITY-2 adds a third: `*_alpha.png`, the cluster leader.
	## Shiny wins over alpha when a creature is both -- a shiny is one in 128
	## and is the rarer thing to have to recognise -- and an alpha with no
	## authored alpha colourway falls back to the ordinary `vivid` one, so a
	## species can gain the variant later without any code change here.
	var suffix := "vivid"
	if shiny:
		suffix = "shiny"
	elif alpha:
		suffix = "alpha"
	if _has_model and _swap_colourway_textures(suffix):
		_apply_alpha_presence()
		return
	if _has_model and suffix == "alpha" and _swap_colourway_textures("vivid"):
		_apply_alpha_presence()
		return
	if shiny:
		_apply_variant_tint(_shiny_palette())
	_apply_alpha_presence()


## CREATURE-IDENTITY-2. The half of alpha presence that is not the texture:
## a rim light on the body and a slow ring of drifting motes around it.
##
## The colourway (`*_alpha.png`) carries the material difference the owner board
## asks for -- heavier stone plates on burrowback, storm-blue tips on galecrest
## -- but it only differs on the species that have one authored, and a texture
## difference alone is not visible against a sunlit meadow at fifty metres. The
## rim is: BaseMaterial3D's own rim term brightens exactly the silhouette edge,
## which is the part of an animal a player can still resolve at the distance
## where they choose whether to walk toward it.
##
## Rim rather than emission because these models are already self-lit (the
## painted albedo is wired into the emission slot, which is what
## creatures_visual.json's `emission_scale` exists to tame) -- raising emission
## on an alpha would brighten its whole body toward the pale wash that pass was
## fixing, and would not touch the outline at all.
##
## The materials this edits are the per-species swap materials cached in
## `_shiny_swap_materials`, so the edit is keyed by the `alpha` suffix and can
## never leak onto an ordinary creature of the same species: an alpha that fell
## back to the shared `vivid` material gets its own duplicate first.
func _apply_alpha_presence() -> void:
	if _aura != null:
		_aura.queue_free()
		_aura = null
	if not alpha or shiny:
		return
	if _has_model:
		_rim_light_node(_model)
	_aura = ALPHA_AURA.attach(self, _radius * 1.5, _height, ALPHA_AURA_COLOUR)


func _rim_light_node(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var source: Material = instance.get_active_material(surface)
			if not (source is BaseMaterial3D):
				continue
			var material := source as BaseMaterial3D
			if not material.resource_name.ends_with("_alpha_rim"):
				material = material.duplicate() as BaseMaterial3D
				material.resource_name = "%s_alpha_rim" % material.resource_name
				instance.set_surface_override_material(surface, material)
			material.rim_enabled = true
			material.rim = ALPHA_RIM_STRENGTH
			material.rim_tint = ALPHA_RIM_TINT
	for child in node.get_children():
		_rim_light_node(child)


## Walks the model's surfaces looking for materials whose albedo texture has
## a `_<suffix>` sibling on disk; swaps albedo+emission to the repainted pair
## on a cached duplicate material. Returns true if at least one surface
## swapped — a shiny caller falls back to the placeholder tint otherwise.
func _swap_colourway_textures(suffix: String) -> bool:
	_colourway = suffix
	return _swap_node_textures(_model)


## Which colourway `_swap_node_textures` is currently applying. A plain field
## rather than an argument threaded through the recursion, which would have to
## reach the two static helpers as well for no benefit.
var _colourway: String = "vivid"

## The alpha's drifting motes, freed and rebuilt whenever the body is re-dressed
## (a model rebuild through `apply_size_multiplier` is the live case -- without
## this the old aura would be left parented to the replaced art).
var _aura: Node3D = null


func _swap_node_textures(node: Node) -> bool:
	var swapped := false
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		var surfaces := mesh.get_surface_count() if mesh != null else 0
		for surface in surfaces:
			# Clear any override this node already applied BEFORE reading the
			# material back.
			#
			# CREATURE-IDENTITY-2 found this the hard way. `get_active_material`
			# returns the override when one is set, so the second swap on the
			# same body was reading the FIRST swap's output: an alpha
			# burrowback, which is dressed `vivid` at build time and re-dressed
			# `alpha` when the director marks it, asked for the alpha sibling of
			# `..._base_color_vivid.png` -- a file that does not and should not
			# exist -- found nothing, and silently stayed vivid. Clearing first
			# makes every swap derive from the model's own shipped material, so
			# colourways never chain.
			instance.set_surface_override_material(surface, null)
			var source: Material = instance.get_active_material(surface)
			if not (source is BaseMaterial3D):
				continue
			var replacement := _swapped_material(source as BaseMaterial3D, species_id, _colourway)
			if replacement != null:
				instance.set_surface_override_material(surface, replacement)
				swapped = true
	for child in node.get_children():
		if _swap_node_textures(child):
			swapped = true
	return swapped


## One swapped Material per source material, shared by every body of the same
## species — same cache discipline as `_shared_variant_material` below.
static var _shiny_swap_materials: Dictionary = {}


static func _swapped_material(source: BaseMaterial3D, species: String, suffix: String) -> BaseMaterial3D:
	var shiny_albedo := _texture_for(source.albedo_texture, species, suffix)
	if shiny_albedo == null:
		return null
	var key := "%d:%s" % [source.get_instance_id(), suffix]
	if _shiny_swap_materials.has(key):
		return _shiny_swap_materials[key]
	var copy := source.duplicate() as BaseMaterial3D
	copy.resource_name = "%s_%s" % [source.resource_name, suffix]
	copy.albedo_texture = shiny_albedo
	if copy.emission_enabled:
		var shiny_emission := _texture_for(source.emission_texture, species, suffix)
		copy.emission_texture = shiny_emission if shiny_emission != null else shiny_albedo
		# CREATURE-PRESENTATION: these materials wire the painted albedo into
		# the emission slot at full energy, so a creature in daylight renders as
		# its own texture plus a second unshaded copy of itself -- which is what
		# turns a saturated mid-brown map into a pale peach animal and flattens
		# the value contrast a face needs. Tunable in creatures_visual.json.
		copy.emission_energy_multiplier *= VISUAL.emission_scale()
	_shiny_swap_materials[key] = copy
	return copy


## `<texture path minus .png>_shiny.png`, or null when no repaint exists —
## the naming contract tools/repaint_creature_textures.py writes. A texture
## embedded inside a .glb has no usable resource_path; those species'
## repaints live at the tool's extracted-texture path instead, keyed by
## species id (the tool extracts the glb's images before repainting them).
static func _texture_for(tex: Texture2D, species: String, suffix: String) -> Texture2D:
	if tex == null:
		return null
	var path := tex.resource_path
	var candidate := ""
	if path != "" and path.ends_with(".png"):
		candidate = "%s_%s.png" % [path.get_basename(), suffix]
	else:
		candidate = "res://assets/creatures/tetherbound/%s/models/%s_extracted_base_color_%s.png" % [species, species, suffix]
	if not ResourceLoader.exists(candidate):
		return null
	return load(candidate) as Texture2D


## OF27's placeholder answer to "what colour is a shiny": one magenta-shift
## wildcard, applied to every surface with no more specific entry. OF28 owns
## the real answer — per-species base AND shiny palettes read from data
## (spec: OF27 is "nothing different than just the colors" made to WORK;
## OF28 is choosing what the colors actually are) — and is expected to
## replace this function's body with a data read, not to touch
## `_apply_variant_tint` itself.
func _shiny_palette() -> Dictionary:
	return {"*": SHINY_PLACEHOLDER_TINT}


## The tint hook. `colours` maps a mesh surface's material `resource_name`
## (or `"*"` as the wildcard every other name falls back to) to a `Color`
## multiplier, applied to both the real model (when one loaded) and the
## capsule fallback (when it did not) — a creature whose model failed to load
## should not also silently lose its shiny tint, the one thing a player
## catching it would actually notice.
func _apply_variant_tint(colours: Dictionary) -> void:
	if colours.is_empty():
		return
	if _has_model:
		_tint_node(_model, colours)
	else:
		_tint_capsule(colours)


func _tint_node(node: Node, colours: Dictionary) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		var surfaces := mesh.get_surface_count() if mesh != null else 0
		for surface in surfaces:
			var source: Material = instance.get_active_material(surface)
			var name := source.resource_name if source != null and source.resource_name != "" \
				else "surface_%d" % surface
			var colour: Variant = colours.get(name, colours.get("*"))
			if colour == null:
				continue
			instance.set_surface_override_material(
				surface, _shared_variant_material(source, name, colour as Color))
	for child in node.get_children():
		_tint_node(child, colours)


## The capsule fallback sets `material_override` directly (`_build_capsule`
## above), which takes rendering priority over any per-surface override —
## `_tint_node`'s `set_surface_override_material` calls would compile, cache
## a material, and change nothing on screen. Handled as its own small path
## instead of folding into `_tint_node` so that mismatch cannot silently
## reappear the way character_model.gd's own NP2 history warns an
## albedo-only tint can.
func _tint_capsule(colours: Dictionary) -> void:
	var colour: Variant = colours.get("*")
	if colour == null:
		return
	for node in [_body, _head]:
		if node == null or node.material_override == null:
			continue
		node.material_override = _shared_variant_material(
			node.material_override, "capsule", colour as Color)


## One Material per (species, material-or-part name, colour) tuple, shared by
## every body of the same species asking for the same tint — the same "mints
## a material per variant" mistake `character_model.gd`'s own cache comment
## warns against, avoided the same way.
##
## Found doing `NP2` on the human rigs, and treated as true here on the same
## authority (OF27's own brief): these creature assets ship
## `emission_enabled = true` with the SAME painted texture set as both
## `albedo_texture` and `emission_texture`, at a full white `emission`
## multiplier — a self-lit "painted" look, not a shading bug. Emission is
## additive and reads independently of lighting, so it swamps any
## `albedo_color` change completely; an albedo-only tint here would compile,
## pass a material-only unit test, and still be invisible in a render.
## `smoke_art.gd`'s own shiny check asserts the emission channel specifically
## for exactly this reason. Tinting `emission` the same way `albedo_color`
## already is closes the gap either way.
static var _variant_materials: Dictionary = {}


func _shared_variant_material(source: Material, name: String, colour: Color) -> Material:
	var key := "%s|%s|%s" % [species_id, name, colour.to_html()]
	if _variant_materials.has(key):
		return _variant_materials[key]
	var material: BaseMaterial3D = (source.duplicate() as BaseMaterial3D) \
		if source is BaseMaterial3D else StandardMaterial3D.new()
	material.albedo_color = material.albedo_color * colour
	if material.emission_enabled:
		material.emission = material.emission * colour
	_variant_materials[key] = material
	return material


func body_height() -> float:
	return _height


## What counts as a clean hit on this creature. Read by the orb for collision and
## by the catch formula for accuracy, so a bigger creature is genuinely easier to
## hit and that shows up in the odds rather than only in the physics.
## Grow this body, gameplay size and all.
##
## WILD-ECOLOGY alphas need to read as bigger AND fight as bigger, and those are
## the same fact here: `_height` and `_radius` drive the capsule, the collider,
## the hit cone's reach and -- through `body_radius()` -- the catch accuracy
## bonus. `_build_placeholder`'s own comment says so: "Gameplay size is `height`
## and `radius`... Art is then scaled to fit that."
##
## So this multiplies the gameplay size and rebuilds from it, rather than
## setting `scale` on the node. Scaling the node was the first attempt and it is
## wrong in a way that is invisible until someone throws an orb: the art would
## be 35% bigger while `body_radius()` returned the unscaled value and `centre()`
## sat low on the model, so throws that visually struck the creature would
## resolve as edge hits or misses. That is `reticle_outside_body`, which this
## project has already spent a debugging session on once.
##
## Call after `populate()`; it re-runs the sizing path over the new numbers.
func apply_size_multiplier(multiplier: float) -> void:
	if multiplier <= 0.0 or is_equal_approx(multiplier, 1.0):
		return
	_height *= multiplier
	_radius *= multiplier
	var shape := CapsuleShape3D.new()
	shape.radius = _radius
	shape.height = maxf(_height, _radius * 2.0 + 0.01)
	_collision.shape = shape
	_collision.position = Vector3(0.0, _height * 0.5, 0.0)
	var look: Dictionary = SPECIES.placeholder(species_id)
	if not _build_model(look):
		_build_capsule(look)
	_refresh_shiny_tint()


func body_radius() -> float:
	return _radius


## Where an attack aimed at this creature should be measured to: the middle of
## the body rather than the point between its feet.
func centre() -> Vector3:
	return global_position + Vector3.UP * (_height * 0.5)


## Facing, on the horizontal plane. This is what an attack is aimed along.
func facing() -> Vector3:
	var forward := global_transform.basis.z
	forward.y = 0.0
	return Vector3.FORWARD if forward.length() < 0.01 else forward.normalized()


## --- driving --------------------------------------------------------------

## Ask to move in a world-space direction this frame. Must be called every frame
## the creature should be moving; see `_requested`.
## The species' own config speed, for a caller that wants to scale it (a
## tonic) without re-reading the config or reaching into `_speed`.
func base_speed() -> float:
	return _speed


func request_move(direction: Vector3, speed: float = -1.0) -> void:
	_requested = Vector3(direction.x, 0.0, direction.z)
	if _requested.length() > 1.0:
		_requested = _requested.normalized()
	_requested_speed = _speed if speed < 0.0 else speed
	# Real movement beats a stale one-shot pose. See `creature_animator.gd`'s
	# `cancel_hold` for why: a creature already being driven again must not
	# stay frozen on an attack/hit pose for the rest of that clip's length.
	if _requested.length() > 0.01 and _animator != null:
		_animator.call("cancel_hold")


func add_impulse(direction: Vector3, strength: float) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length() < 0.01:
		return
	_impulse += flat.normalized() * strength


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		# Small downward bias, the same trick the trainer uses, so the creature
		# stays pinned to slopes instead of skipping off every crest.
		velocity.y = -2.0

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if _requested.length() < 0.01:
		horizontal = horizontal.move_toward(Vector3.ZERO, _friction * delta)
	else:
		horizontal = horizontal.move_toward(_requested * _requested_speed, _acceleration * delta)
		_turn_towards(_requested, delta)

	_impulse = _impulse.move_toward(Vector3.ZERO, _impulse_damping * _impulse.length() * delta)

	velocity.x = horizontal.x + _impulse.x
	velocity.z = horizontal.z + _impulse.z
	move_and_slide()

	if arena != null:
		arena.call("hold_inside", self)

	if _animator != null:
		var moving := Vector3(velocity.x, 0.0, velocity.z).length()
		_animator.call("tick", delta, moving, _speed)

	_requested = Vector3.ZERO


func _turn_towards(direction: Vector3, delta: float) -> void:
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = rotate_toward(rotation.y, target_yaw, _turn_speed * delta)


## --- animation, poked by combat ---------------------------------------------
##
## Speed tells the body how to move; it cannot tell it that a blow just landed.
## These are the three moments combat has to announce.

func play_attack() -> void:
	if _animator != null:
		_animator.call("play_once", "attack")


func play_hit() -> void:
	if _animator != null:
		_animator.call("play_once", "hit")


func play_faint() -> void:
	if _animator != null:
		_animator.call("play_faint")


func revive_animation() -> void:
	if _animator != null:
		_animator.call("revive")


## --- catching, the creature's half ------------------------------------------
##
## Being caught happens TO the body, so the body owns the two animations: being
## drawn into the orb, and bursting back out of it. Both animate the VISUAL
## children only (`Model`, and the capsule fallback's `Body`/`Head`) — the
## gameplay node, its collider and its transform stay untouched, because a
## scaled CharacterBody3D is a physics problem and the fight still owns this
## node's position. Physics-clock tweens, for the same reason impact_flash.gd
## runs on the physics clock: presentation that only advances on render frames
## is invisible to the survey harness and unreviewable.

var _catch_tween: Tween = null
var _visual_rest: Dictionary = {}


func _visual_children() -> Array[Node3D]:
	var visuals: Array[Node3D] = []
	for node in [_model, _body, _head]:
		if node != null and node.visible:
			visuals.append(node)
	return visuals


## Drawn into the orb: shrink toward the strike point, then hide. Replaces the
## old presentation, which was `visible = false` on the strike frame — the
## creature POPPED out of existence, and the one moment the whole mechanic
## builds to had no body. Ends by hiding the node (which also disables physics
## and the collider, via `_on_visibility_changed`) and restoring the visual
## children, so nothing downstream ever sees a shrunken creature.
func play_absorb(world_point: Vector3, seconds: float) -> void:
	# The creature is already spoken for; it must not wander, attack or slide
	# while it is being converted into light.
	set_physics_process(false)
	velocity = Vector3.ZERO

	_kill_catch_tween()
	_visual_rest.clear()
	var visuals := _visual_children()
	for node in visuals:
		_visual_rest[node] = node.transform

	var local_point := to_local(world_point)
	_catch_tween = create_tween().set_parallel(true)
	_catch_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for node in visuals:
		_catch_tween.tween_property(node, "scale", Vector3.ONE * 0.02, seconds) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_catch_tween.tween_property(node, "position", local_point, seconds) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_catch_tween.chain().tween_callback(_finish_absorb)


func _finish_absorb() -> void:
	visible = false
	_restore_visuals()


## Burst back out of a failed catch: reappear small and pop up to full size
## with an overshoot, so the breakout reads as an event rather than a toggle.
func play_breakout(seconds: float) -> void:
	_kill_catch_tween()
	_visual_rest.clear()
	# Restore visibility FIRST (re-enables physics and the collider), then
	# animate the visuals up from nothing.
	visible = true
	_catch_tween = create_tween().set_parallel(true)
	_catch_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for node in _visual_children():
		var rest_scale: Vector3 = node.scale
		_visual_rest[node] = node.transform
		node.scale = Vector3.ONE * 0.05
		_catch_tween.tween_property(node, "scale", rest_scale, seconds) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _restore_visuals() -> void:
	for node in _visual_rest:
		if is_instance_valid(node):
			(node as Node3D).transform = _visual_rest[node]
	_visual_rest.clear()


func _kill_catch_tween() -> void:
	if _catch_tween != null and _catch_tween.is_valid():
		_catch_tween.kill()
	_catch_tween = null


## Turn to face a world point, immediately. Used when a fight is arranged and by
## the peaceful idle; combat turning goes through `_turn_towards`.
func face_towards(point: Vector3) -> void:
	var to := point - global_position
	to.y = 0.0
	if to.length() < 0.01:
		return
	rotation.y = atan2(to.x, to.z)


## Move to an x/z position and sit on the ground under it.
##
## Asks the world for the ground height first, and only falls back to a ray.
##
## The ray used to be the whole implementation, and it was wrong. Downward rays
## against Terrain3D's heightmap collision miss roughly a quarter of the time at
## points where the ground is definitely present — a shape query at the same
## spot collides and the character walks over it happily, because `move_and_slide`
## uses shape casts and only rays lie. A wild creature placed by ray simply never
## spawned: no error, no body, no encounter.
##
## The fallback stays for anything the terrain does not know about — a rock, a
## structure, whatever M8 builds — where a ray is the only answer available.
func place_on_ground(target: Vector3) -> bool:
	if not is_inside_tree():
		return false

	var height := _ground_height(target.x, target.z)
	if is_nan(height):
		height = _ray_ground(target)
	if is_nan(height):
		# Leaving it where it is beats teleporting it into the sky, and the
		# caller is told so it can pick somewhere else.
		return false

	global_position = Vector3(target.x, height, target.z)
	velocity = Vector3.ZERO
	_impulse = Vector3.ZERO
	return true


## The world's own ground query, found by walking up the tree. Cached, because
## this runs every frame for a wandering creature.
##
## Discovered rather than injected so a creature can be dropped into any scene: a
## world that offers `ground_height_at` is used, and one that does not falls
## through to the ray without anybody having to wire anything.
## GATE-E: corrected upward by a BUILT floor when a building stands over the
## same spot. The terrain under the stronghold's five spaces is metres below
## the floor the player walks in on, and a creature placed by the terrain
## answer lands under the building -- see `scripts/world/built_floor.gd` for
## the measurement and what it cost the finale. Outside a building
## `BUILT_FLOOR.resolve` returns the terrain answer unchanged, so nothing in
## the open meadow moves.
func _ground_height(x: float, z: float) -> float:
	if _ground_source == null or not is_instance_valid(_ground_source):
		_ground_source = _find_ground_source()
	if _ground_source == null:
		return NAN
	return BUILT_FLOOR.resolve(self, x, z, float(_ground_source.call("ground_height_at", x, z)))


func _find_ground_source() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return node
		node = node.get_parent()
	return null


func _ray_ground(target: Vector3) -> float:
	var world := get_world_3d()
	if world == null:
		return NAN
	var space := world.direct_space_state
	if space == null:
		return NAN
	var from := Vector3(target.x, target.y + GROUND_PROBE_UP, target.z)
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * GROUND_PROBE_DOWN)
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(query)
	return NAN if hit.is_empty() else float((hit["position"] as Vector3).y)
