# Done

Append-only. Newest at the top. One entry per shipped backlog item: what
shipped, the commit, and anything the next firing should know.

## EV8 — Lighting and atmosphere

Two rounds of the blind pass, both entirely local (five renders total, one
push). Closes `R9.4-remainder-2`.

**Root cause of the pale horizon (`R9.4-remainder-2`) was not fog.** Every
outdoor frame showed a large pale wavy dune-shaped mass filling 30-50% of the
upper frame past the 512m bake — not subtle washing, an actively ugly shape,
because Terrain3D's `world_background = 2` (NOISE) continues the terrain
procedurally with visible dune-like relief and no colour/texture control.
`FLAT` (1) was already ruled out (0.146 luminance seam). The untried third
option, `world_background = 0` (NONE) — draw nothing past the bake, let the
real sky show through — turned out to be the fix: `frame_stats` sky% dropped
from ~40-52% to 12-26% across the five exploration frames, inside or near
Palworld's 2-21% reference range, with no seam regression (max 0.09 across
all five, well under the FLAT-mode 0.146-0.18 benchmark).

**Root cause of the sky-treatment inconsistency (EV8's other named defect)
was the photographic HDRI panoramas.** `day.hdr`/`golden.hdr` are static
equirect photos with their own baked-in sun position, unrelated to
`art.json`'s `sun.pitch_deg`/`yaw_deg` — so whichever way a viewpoint faced,
the photographed sky and the real `DirectionalLight3D` could disagree about
where the light was coming from. Round 1's blind critic caught this exactly:
`02-valley-floor`'s sky read as dusk while its own ground lit as bright
midday, same "day" preset as three other frames that looked correctly
midday. Dropped both panoramas back to the existing procedural-gradient
fallback (already built for this purpose, previously used only by `night`),
whose glow is generated from the real sun direction and so cannot disagree
with the ground in any direction — not just survey's five. Confirmed:
`02`'s sky matches `01`/`03`/`04` exactly after the fix. Costs the cloud
detail the panoramas bought; `ProceduralSkyMaterial` cannot render clouds at
all (documented in `world_look.gd`'s own long-standing comment) — an
accepted, deliberate trade for the consistency EV8 exists to deliver, not an
oversight.

**A third, smaller fix**: `fog_colour` didn't match `sky.horizon_colour` for
any of the three time presets (`day` was `#cdd0c6` vs. a `#b9c8cf` horizon).
Since `fog_sky_affect` is deliberately 0 (the sky is never fogged), those two
colours are the only thing that has to agree for distance-fogged terrain to
meet the sky without a seam — round 1's critic caught this too, as a hard
pale band sitting well short of the true horizon in `03-rise-overlook`.
Matched all three presets' fog colour to their own horizon colour.

**Round 2 also caught `05-spawn-low-sun`'s ground crushed near-black**
against a still-bright sky once the panorama stopped partially masking it.
Lifted golden's `ambient_energy` 1.15 → 1.5 (measured: near-field luminance
0.126 → 0.139); the cool ambient tint stays deliberate (real golden-hour sky
fill reads cool against a warm key).

**Stopped after round 2**, not because nothing moved (round 2 named real
things round 1 hadn't) but because what was left split cleanly into
out-of-scope and structural-tradeoff, neither of which EV8 can address:
frame emptiness/density and creature/character art quality were both
round 1's and round 2's #1 and #2 ranked gaps, and both are already owned
elsewhere — `EV3` (scatter/clustering) and `BLOCKED.md`'s standing
creature-appeal entry, respectively, not new findings this task can act on.
One genuinely unresolved residual: `03-rise-overlook` still shows a soft
grey-white horizontal band at the horizon, unmoved by the fog-colour fix
(`frame_stats` seam stayed 0.009 before and after) — this looks like a
structural consequence of `world_background = 0` at this viewpoint's
elevated, grazing-angle look: gaps between distant ridgelines show the sky
dome's own sky-hemisphere/ground-hemisphere seam through them. Small (well
under any seam threshold that's flagged a problem elsewhere in this file)
and not further reachable by fog or ambient tuning; worth knowing about if
`EV3`/`EV5` end up reshaping the terrain this viewpoint looks across.

Warm sun and cool ambient fill (the bible's other two `EV8` asks) were
already correctly built via `art.json` + `world_look.gd` before this task —
verified intact, not reworked.

`80db19f` (config-only: `data/config/art.json`,
`data/config/terrain_playground.json`) · `tests: none` named; ran
`tests/smoke_art.gd` anyway since the touched file also carries creature/human
config (untouched sections) — green.

## EV9 (first slice) — the exploration HUD, for real this time
`eea16a9` · `tests: smoke_menu` green, plus `run_tests.gd` (299/299),
`smoke_mouse_look`, `smoke_playground`, `smoke_opening`, all run locally
headless before push.

`playground_hud.gd`/`.tscn` rebuilt from the M1 debug dump into the real
exploration HUD bible §16 describes: a styled health/stamina panel (dark
translucent, teal border, rounded corners, "HP"/"STA" labels) that fades to
a low-emphasis state when full and idle rather than to invisible, a
party/orb count panel reading `Game.party`/`Game.inventory` live, and the
contextual interact prompt read from `InteractionArbiter.prompt()`. The old
always-on movement/input telemetry dump is still there — genuinely still
needed for M1 tuning — just behind an F3 toggle now instead of covering a
third of the screen by default.

**Scoped deliberately small.** EV9's full brief (inventory grid + crafting
panel reskin, input-glyph device tracking, objective line, icons, a display
font) is bigger than one "smallest coherent version" pass, especially after
watching visual-judge iteration cost on `SA0-orbs`/`SA0-orbs-remainder`. Full
remainder list is in `BACKLOG.md`'s EV9 entry — read it before starting the
next EV9 slice rather than re-deriving the same scope split.

**Visual-judge, 3 rounds** (`tools/capture_exploration_hud.gd`, two frames —
idle and a forced-hurt state — of the same viewpoint):
- Round 1 found the vitals bars unlabeled, low-contrast against their own
  track (fill alpha 0.28 was reading as a rendering glitch, not a calm
  state), and the two panels looking visually mismatched. Fixed: added
  "HP"/"STA" labels, raised the idle-fade floor to 0.55.
- Round 2 found the panels reading as flat engine-default rectangles — the
  10px corner radius and 30%-alpha border were too subtle to register, and
  the label padding looked cramped. Fixed: border alpha/width up, corner
  radius 10→14, labels vertically centered against their bars.
- Round 3 verdict: **"Coherent, intentional game UI? Yes."** Two small notes
  (bar-fill corner radius vs. panel radius, stamina teal too close to the
  border teal) fixed inline without a further round. Everything else the
  critic named it explicitly split out as "needs new assets" (icon glyphs, a
  branded display font, gradient bar fills) rather than more scene tuning —
  that split is what seeded the BACKLOG remainder list above.

**Also swept up in this push:** three `.uid` sidecar files
(`scripts/ui/starter_picker.gd.uid`, `tests/helpers/unhandled_probe.gd.uid`,
`tools/capture_starter_picker.gd.uid`) that earlier firings had left
uncommitted next to already-tracked scripts. Harmless on their own — Godot
just regenerates them — but a fresh checkout would regenerate a *different*
random uid than the one already baked into any `.tscn` reference, which is
the kind of thing that only surfaces as a confusing import error much later.
Committed them rather than filing a ticket for something this cheap to fix.

**For the next EV9 firing:** the auto-merge bot rebased this branch once on
its own (`ralph-bot`, run 328) and still hadn't landed it several minutes
later because two other lanes (`R9.4-remainder-8`, then a run of `EV4`
commits) kept moving `main` underneath it. Rebasing it myself and
force-pushing (`--force-with-lease`, safe since it's a solo-owned feature
branch with no one else's commits on it) is what actually got it merged —
worth doing proactively rather than waiting out the bot's retry cycle when
`main` is this active.

## LP2 — `smoke_opening` beat-3 press flake: a pattern fix, the race not directly reproduced
`tests: smoke_opening`, green locally 3/3 (always exactly 14 presses, matching
`grandpa_house`'s real line count) before push.

**What was ruled out, in order, each with real evidence rather than a guess:**

- **The dialogue content itself.** `data/dialogue/opening.json`'s
  `grandpa_house` entry has exactly 14 lines and no conditional branches; the
  passing runs' "14 presses" is not a coincidence, it is the real count. No
  `randi`/`randf`/`randomize` anywhere in `dialogue_runner.gd` or
  `sequence_director.gd`. `dialogue_runner.gd::advance()` is fully
  deterministic — one `advance()` call, one line, always, until `close()`.
  So the only way to close in 7 real presses is for `advance()` to fire twice
  per test-side press, not for the conversation to genuinely be shorter.
- **The arbiter re-activating Grandpa while his conversation is already
  open.** `interaction_arbiter.gd` and `dialogue_panel.gd` both read
  `interact` by polling `Input.is_action_just_pressed` from their own
  `_physics_process`, so a press could plausibly be seen by both. But
  `sequence_director.gd::_start_conversation()` guards
  `if _dialogue.is_open(): return false` — re-firing Grandpa's `activated`
  signal while his conversation is running is already a safe no-op, so this
  cannot be adding extra `advance()` calls.
- **A one-off timing coincidence.** It isn't: 14 lines closing in exactly 7
  presses is exactly half, and the failing CI run's own log shows this held
  for the *whole* conversation, not one press out of many — whatever caused
  it, it was consistent across the run, not a single unlucky frame.

**What is left, and could not be forced to reproduce here despite three
separate attempts** (a bare `is_action_just_pressed` probe against an idle
SceneTree, 60 repeats of the same probe against the real, fully-loaded
meadows playground under its actual 23k-prop background load, and a probe
that explicitly forced `action_press()` and the parsed `InputEventAction`
onto different physics frames by hand) — all three came back with exactly one
`is_action_just_pressed` hit per logical press, never two. A fourth attempt
under `xvfb-run` + `--rendering-driver opengl3` (the one condition
`conventions.md` already documents as 25× slower and prone to exactly this
class of flake under CPU load) was tried specifically to force real
Godot physics-catch-up — multiple physics ticks running between two
`_process()` calls when a frame falls behind — but it did not finish inside
this firing's time budget and was killed rather than let run indefinitely.

**The fix shipped anyway, on the strength of the elimination above plus an
exact precedent already proven in this same file.** `dialogue_panel.gd` and
`interaction_arbiter.gd` both poll `Input.is_action_just_pressed` from
`_physics_process` — exactly the reader class `smoke_opening.gd`'s own
`_press_polled()` comment already names for `menu_confirm`: *"under a heavy
scene the two [signals] can land in DIFFERENT physics frames, which a
polling reader counts as two presses. Typing 'Bud' came out 'Buudd'."* Beat
3's `interact` presses were the one place still using `_press()` (which
sends `action_press()` AND a parsed `InputEventAction`, "belt and braces")
against that same class of reader. `docs/HANDOFF.md` §10's actual rule — the
reason `_press()` sends both in the first place — is scoped to **UI focus
navigation**, which `interact` never drives, unlike `ui_*`. Switched both
call sites (`_grandpa_says_his_piece`'s advance loop and the shared
`_walk_to_and_activate`) to `_press_polled("interact")`, matching the
already-established pattern exactly rather than inventing a new one.

**Say this plainly rather than overclaim it: this removes a real, provable
redundancy (an unnecessary parsed event feeding a purely-polled reader,
already a demonstrated failure class in this file) but the specific race
that produced the "7 vs 14" observation was not directly reproduced either
before or after the fix.** If `smoke_opening` flakes again on beat 3 with a
press-count anomaly, that is new information — either this was not the whole
cause, or the timing window this fix closes is not the one CI hit. The next
firing to see that recurrence should re-open this rather than assume it is
solved, and the `xvfb-run` reproduction attempt above is the fastest
remaining path to a forced repro if it comes to that.

## EV2 — An approved Meadows nature subset
`f4bf576` (curate + variant tints) · `2fe56e7` (round 2: fix cyan-highlight
artifact) · `1cdd5e2` (round 3: widen hue/value spread) · `tests: smoke_art`
green locally throughout; full suite (299 tests) also green, confirming no
regression from trimming layer model lists.

Curated `trees` (standard canopy) from 5 CommonTree forms to the 3 with the
widest canopy footprint (measured with `measure_models.gd`, not guessed —
the acceptance bar is a silhouette read at thumbnail size, not a triangle
count), and `grove` (hero trees) from 5 TwistedTree forms to the 3 with the
widest footprint, tallest height and most asymmetric silhouette. Added a new
`saplings` layer reusing the two dropped CommonTree forms at young-tree scale
instead of discarding them — same species, a different age, no new geometry.
Gave `vegetation.gd::_build_batch` an optional per-MODEL `variant_retint`
lookup (falls back to the layer's existing per-material `retint` when a model
has no entry) so a layer can assign controlled spring/deep/yellow-green
variants instead of one flat colour, since several models share one material
name and a layer-wide colour can't tell them apart.

**Three real rounds of the mandatory local blind-judge pass, each one
finding something genuine — this is the record of what each one caught and
fixed, not a pass-first-try story:**

- **Round 1** (initial curation + first variant colours, reusing R9.4's
  shipped `#9dcaff` as `spring`): an independent blind critic found visible
  cyan/teal flecks in canopy highlights, described unprompted as "a stray
  specular/vertex-color artifact." Traced algebraically: `#9dcaff` and its
  darkened sibling are BLUE-hued multiply colours (hue ~213°) that land in
  the intended green family on `Leaves.png`'s dark/average texels but
  multiply through nearly unchanged on the texture's bright highlight
  speckle, reading as cyan on the lit parts of the canopy specifically.
- **Round 2**: replaced the tint family with green-hued multiplies (hue
  77–112° instead of 213°). A second, independent blind critic confirmed the
  flecks were gone (zero cyan/teal pixels found by its own pixel scan) — but
  its close inspection found the three variants still rendered in a tight
  63–84° hue band once scene lighting compressed the on-paper 77–112° spread
  further, reading as one uniform green rather than 2–3 distinguishable
  varieties.
- **Round 3**: widened both hue AND value (not hue alone) — `deep` in
  particular is now genuinely darker, not just a different hue at the same
  brightness (values 0.09/0.19/0.20 vs round 2's 0.19/0.19/0.20), while a
  highlight-case check (synthetic near-white texel multiply) confirmed the
  wider spread still stays short of the ~150° line where the round-1
  artifact started. A third independent blind critic confirmed no fleck
  regression and found genuine, sortable colour variety in the farm-cluster
  frame (pale sage / mid olive / dark saturated green) — one specific
  treeline in a different frame still read as fairly uniform, but that
  reads as the stochastic scatter happening to draw similar models in that
  one local cluster rather than a mechanism failure, since the same
  mechanism visibly works elsewhere in the same frame set.

**Stopped after round 3**, not because it passed clean, but because both
objectively-fixable defects the critics named (the cyan artifact, the
variant separation) show confirmed, independently-verified improvement, and
what's left is genuinely outside `EV2`'s lever — see below.

**Two honest remainders, not faked:**

- **Wetland forms** (bible's "1–2 forms near river") — not done. No river
  exists yet (`EV5`, unshipped) and there is nothing to place wetland
  vegetation near.
- **Rock family's "2–3 large" tier** — not done. The imported subset has no
  distinct large-format rock mesh; the fuller Stylized Nature MegaKit that
  might carry one is itch.io-blocked (`EV1-remainder`). Reusing the existing
  `Rock_Medium` meshes in a second layer was considered and rejected: it
  would put the same model in two layers' `models` lists, which
  `vegetation.gd::_build_batch` groups by model path for drawing —
  `_warn_about_shared_models`'s own docstring explains why that silently
  drops one layer's tint/collision settings. The single `rocks` layer's
  existing 0.28–2.1 scale span already produces large-boulder reads from the
  same 3 medium meshes and stands as the honest ceiling.

**Two new findings opened in `BACKLOG.md`, not chased here** (both found
independently by multiple blind critics across the three rounds, neither
fixable with `EV2`'s own lever): `EV2-trunk-colour` (tree trunks render pale
salmon/pink instead of brown bark — source bark textures are ordinary warm
browns, so this looks like a lighting/minification effect on thin geometry
under the Compatibility renderer, not a texture or retint bug) and
`EV2-landmark-ceiling` (even the best 3-of-5 hero-tree subset doesn't read
as a true landmark specimen against the key art — a critic's own verdict was
that this needs broader-canopy geometry the imported subset doesn't have,
which is the same itch.io block as the rock tier, not a curation problem).

## SA1-lod — vegetation stops discarding the importer's LOD chain
`de8657c` · `tests: smoke_art`, green locally before every push (three of
them — see below), and in CI (run 31511759144, then 31514823852 attempt 2).

Root cause: `vegetation.gd::_retint()` rebuilt every scattered mesh with a
fresh `ArrayMesh` via `surface_get_arrays()`/`add_surface_from_arrays()`,
which only round-trips base LOD0 geometry — there is no public getter for the
importer's LOD dict, so it and the shadow mesh were silently dropped on every
retint. Every tree and tuft therefore drew at LOD0 at every distance, 23,452
instances of it. Fix: `duplicate(false)` the source mesh instead of rebuilding
it — `ArrayMesh.duplicate()` carries the LOD chain over through its own
`_surfaces` storage, and `surface_set_material()` on the duplicate retints
without touching any of that. `false` (no subresource duplication) is
deliberate: the shadow mesh carries no material and is never touched, so
sharing the one original instance across every retint variant is correct and
free. `smoke_art.gd` gained a check that reads the LOD chain and shadow mesh
back off a retinted `CommonTree_1` standing in the world and compares it to
the un-retinted source file; verified it fails against the pre-fix code
([0, 0], no shadow mesh) and passes against the fix ([10, 4], matching the
source).

**Shipping this took three rebase-and-push cycles, none of them code
changes.** The fix itself was already correct and CI-green when this firing
picked it up — a previous firing (`ralph-lane-generalist`) had done the real
work and left its lease reading `shipped`, but `ralph/SA1-lod` had never
actually fast-forwarded `main`: three other lanes (`NP1`, `SA0-orbs-
remainder`, `ralph/tether-hero-boards`) were landing on `main` in the same
window, and `ralph-merge.yml`'s fast-forward-only gate lost that race
repeatedly. This firing rebased onto current `main` and re-pushed three times
(never touched `main` directly, never force-pushed it) until one push's CI
finished before the next lane's landed. One of those CI runs failed for a
real but unrelated reason — see `LP2` below, opened from the same evidence.

## LP2 opened — `smoke_opening` beat-3 press-count flake
Not fixed, recorded in `BACKLOG.md` Phase -0.95. Same commit (`c8ece6a`)
failed once and passed twice across three runs (one CI, one CI rerun, one
local) with zero code differences — closing Grandpa's conversation in 7
presses on the failing run and 14 on both passing ones. Likely the same class
of frame-timing race `smoke_opening.gd`'s own comments already warn about for
polled input, not investigated further here; see the `BACKLOG.md` entry for
the evidence trail.

## SA0-orbs-remainder — lighting, UI-chrome ownership, creature appeal
`c5b492c` (scope note + BLOCKED.md split) · `d18899f` (rim light + selected
label) · `tests: smoke_opening` green locally, both before and after a rebase
onto current `main`.

Picked up the three open questions `SA0-orbs`'s own remainder left, one at a
time:

**(a) One more lighting pass, since the remainder said it had "reachable
value."** Added a cool-tinted rim/kicker light against the warm key + ambient
— the specific gap round 4's blind critic named by name ("no visible
rim/kicker light… compare this to any of the Palworld shots"). Ran a fifth
blind-judge round: the rim light helped the two pale creatures (Ripplet,
Galewisp) separate from the dark orb background, but did little for the
darker Terrapup, and the round's other findings were either repeats (creature
material quality — see below) or apparent misreadings with no basis in the
code (a claimed "selected creature renders larger/closer" and a "pose swap on
selection" — neither exists; the only per-frame difference is the picker's
own intentional idle turntable spin, and more real time had passed in the
second capture). The one genuinely new, cheap, real finding — the selected
orb's name label carried no cue of its own, "an easy win being left on the
table" — got its own fix (gold colour + a couple points larger, matching the
ring) and a sixth render to confirm it visually. Stopped there: five rounds
of blind judging is already past `R9.4`'s own four-round precedent, and every
remaining finding across rounds 4–5 was either this label nit (now fixed) or
the same "creature art itself is below the bar" verdict every single round
independently reached — which is exactly the wall `conventions.md`'s
stopping rule exists to detect, not a premature stop.

**(b) Who owns wiring `EV1`'s Kenney Input Prompts icons into narrative UI.**
Did not build a device-aware icon system inside the picker — that would have
duplicated `EV9` and left `dialogue_panel.gd`/`name_prompt.gd` inconsistent
with it. Instead read `docs/ENVIRONMENT_AND_UI_BIBLE.md` directly: §16
("Dialogue") asks for "a controller-first continue prompt" and §18's own
worked example opens with "E / X button for interact" — the literal hint
`dialogue_panel.gd` draws today as bracket text. `EV9`'s one-paragraph
`BACKLOG.md` summary just never said its own source material already covered
narrative panels. Fixed with a scope-note naming `dialogue_panel.gd`,
`name_prompt.gd` and `scripts/ui/starter_picker.gd` explicitly, so whoever
picks up `EV9` does not have to rediscover this mid-task.

**(c) Whether the creature-appeal gap needs its own backlog item.** It does
not — "improve creature appeal" has no concrete done-when a firing could aim
at without first deciding how much material/lighting rework is worth
committing against a fixed ceiling (`D23` §20 forbids new creature meshes at
any balance). That is a resourcing call, not a design decision on
`CLAUDE.md`'s flagged list, but it still is not a firing's to make
unilaterally. Opened as a new `BLOCKED.md` entry instead — "Does the creature
roster clear a Palworld-level appeal bar, or does it need to?" — distinct
from `SA5`/`SA6`'s narrow pairwise mandate (stopping two specific species
reading alike), asking the owner whether a roster-wide pass is worth
commissioning at all.

## EV4 — Paths become a control-map material, not a colour-map tint
`f5d77ec` (mechanism) · `6b12e30`/`eacf0f3` (tint/relief tuning, later
reverted) · `9e25288` (edge-wobble fix) · `c6e6763` (dedicated `path`
texture) · `tests: smoke_traversal`, green locally; full 299-test suite also
run as a broader check since `playground_heightfield.gd`'s `path_factor()`
is shared with `scatter_rules.gd`, all green.

**The mechanism absorbs `R9.4-remainder-4` and `R7.1-found-3` and genuinely
ships.** `build_playground_terrain.gd`'s `_paint_control_map` used to paint
paths only as a lerp toward a tan colour on the COLOUR map, over whatever
texture the slope-driven control map had already chosen — "a worn-earth
tint," never a different material, which is exactly what both critics named.
It now paints a real texture id into the CONTROL map along every route
(`_path_control`, ~2148 pixels), overriding the slope-driven choice rather
than tinting on top of it. The old `paths.tint` colour-map lerp is removed
outright, not layered under the new mechanism.

**The edge is genuinely organic, not a mathematically exact offset.**
`path_factor()` (`playground_heightfield.gd`) perturbs its own fade band
with a dedicated noise field (`_path_edge`) so the boundary bulges and
pinches rather than tracing a perfect parallel curve of the route polyline —
verified test-side (`test_the_paths_reach_where_they_promise` still passes:
route waypoints stay fully on-path, well-off-road points stay fully clear)
and visually (`the-rise-route.png` shows a path that narrows and widens
along its length).

**Five blind-judge rounds on `tools/capture_paths.gd` (new — four
standing-eye-level viewpoints on the actual routes; neither the fixed
five-viewpoint survey nor `capture_wayfinding.gd` frames the ground at the
angle a path needs to be judged from). The first four rounds tuned the wrong
lever; round 5 found the right one and the material genuinely improved:**

- **Round 1** (mechanism only, reusing `soil`/`Ground003_Color.jpg` at its
  original neutral-grey tint): "essentially the grass shader recolored a
  darker green-brown... no visible soil/dirt texture break."
- **Round 2** (`soil.tint` → warm `#d19e6b`): measured movement
  (`frame_stats.py`: saturation/chroma/hue shifted warmer) but a NEW defect
  — "irregular near-black blotches... a broken material/vertex-paint blend"
  on the hillside slope band — plus the path still "clearly carries
  grass-blade geometry... underneath" up close.
- **Round 3** (`soil.normal_depth` 0.4→0.15, tint eased to `#c7a680`,
  mirroring the grass texture's own earlier relief fix): root-caused rounds
  1-2's real problem — `Ground003_Color.jpg` is a photo of a weedy lawn with
  real green grass tufts painted into its own albedo, not a clean dirt
  photo, so no tint or relief value can repaint it. Critic still said
  "tinted grass, not dirt" (same core complaint) but separately named a
  resolution problem in the edge itself: "jagged, stair-stepped."
- **Round 4** (`_path_edge` frequency 0.2→0.05, octaves 2→1, so the wobble's
  wavelength is long enough for the bake's 1m vertex grid to resolve without
  aliasing): addressed round 3's edge-geometry finding specifically.
- **Round 5 — the actual fix.** Another lane sourced and ledgered ambientCG
  `Ground030` (a real dirt/pebble pathway photo, no baked-in grass) and
  `Ground037` independently while this task was in flight, deliberately
  leaving them unwired to avoid a collision (see its own `EV4-textures`
  commit on `main`). Wired `Ground030` in as a NEW `path` texture entry
  (`_texture_ids`/`_path_control` prefer it over `soil`, falling back
  gracefully if absent) and reverted `soil` to its original R9.4 values,
  since it goes back to being a hillside-only texture. **Cost a debugging
  detour worth recording**: the rebase that brought `Ground030`/`Ground037`
  in landed AFTER the local `.godot/` import cache had already been built,
  so the two new textures were never actually imported — `_build_texture_
  list()`'s own uniform-size guard (correctly) refused to build a mismatched
  array and the WHOLE terrain, not just the path, silently fell back to the
  flat colour map (a wash of pale near-white). Re-running `godot --headless
  --path . --import` fixed it — `conventions.md`'s own "import cache does
  not travel between worktrees" warning, hit for real. Once genuinely
  rendering, the blind critic's verdict changed materially: "mostly a
  different material, not simple grass tinting... real progress... [the
  path] correctly connects the well, Grandpa's house, the barn and the
  hilltop landmark... works as a navigational read" — the clearest
  affirmative verdict any round produced.

**Stopping here with two named, narrower remainders — not a silent pass.**
Round 5 did not fully clear the bar: the critic still names green
moss-blotch patches on the path texture reading "too saturated and too
crisply circular... a texture-blend artifact rather than moss," and a
stepped/aliased path edge specifically where a route climbs the hillside
slope (distinct from round 4's flat-ground fix). `EV4-textures` is
downgraded from "source a texture" (done) to a tuning-scope remainder for
the moss-blotch saturation and the slope-specific edge stepping.
`EV4-hillside-seam`'s round-3 zigzag finding gets a real answer round 5
provides for free: `soil` reverted to its untouched original values and the
hillside still reads "mottled... blotchy all over the dome" to a fresh
blind critic, which settles the attribution question the original entry
left open — **pre-existing, not introduced by EV4.**

## SA0-orbs — the starter choice moves into Grandpa's conversation
`2036b28` (director+data+tests) · `4912dc1`..`55e708c` (five visual-pass fixes)
`tests: smoke_opening, smoke_wake_softlock`, both green locally, both replayed
green again after a rebase onto current main.

Owner directive, 2026-08-11: *"the starters should be in orbs and you preview
them while talking to Grandpa."* The three starters no longer stand outside
Grandpa's door as physical bodies you walk up to. `scripts/ui/starter_picker.gd`
(new) opens automatically the instant his briefing conversation closes — still
indoors — and previews all three live: a real creature body inside its own
`SubViewport`, the same construction `tools/preview_creatures.gd` uses for the
art survey, each with `own_world_3d = true` so three creatures and three lights
never leak into the meadow's own world or each other's. `sequence_director.gd`
drops the ~50 lines that placed, tracked and freed the three physical starter
bodies (`_starter_bodies`, `_starter_prompts`, `STARTER_COLLISION_LAYER`, the
whole of the old `_spawn_starters`) in favour of reading a choice back from the
picker's `chosen` signal — the same "ask a panel, read the outcome" split this
file already keeps with `dialogue_panel.gd` and `name_prompt.gd`.

**Reverses a written decision, amended rather than silently edited.**
`docs/OPENING_SEQUENCE.md` and `data/config/opening.json`'s `starters` block
both used to say the choice is "physical, not a menu… a list box would undo
it." Both now record the reversal in place, with the owner's own words as the
reason. Grandpa's actual spoken lines in `data/dialogue/opening.json` are
rewritten to match — he no longer sends the player out a door to meet three
creatures that no longer stand there.

**`tests/smoke_opening.gd` redriven for the new mechanic**, not just patched:
beat 4 used to walk the player outside and activate a "Choose <name>"
interactable; it now closes Grandpa's conversation for real and waits for the
picker to open **on its own** (proving the director's own beat-driven open
logic, not calling it directly), then drives orb selection and confirmation
with the real `ui_right`/`menu_confirm` actions — the same "real buttons, not
method calls" rule the naming grid below it already followed.

**The blind visual-judge pass ran four uncapped rounds** (`conventions.md`),
and it is the honest reason this shipped later than the code did — this is new
UI a player can see, so the rule applied. Round-by-round, because the specific
bugs are worth keeping:

- **Round 1** found the orbs rendering **completely empty** — `pal_body.gd`'s
  `setup()` gates its mesh build on `is_inside_tree()`, and the orb shell was
  still off-tree when `setup()` ran, so nothing errored and nothing built. This
  is the exact trap `tools/preview_creatures.gd`'s own header names, and it was
  missed here on the first attempt anyway — worth a second read next time
  something builds a creature off the main scene tree. Also found the square
  `SubViewport` render visibly poking past the round panel border. Both fixed:
  the shell now goes into the live `Orbs` tree before the creature is built
  inside it, and a `canvas_item` shader on the `SubViewportContainer` masks the
  render to a circle and vignettes the rim.
- **Round 2** (post-fix) found the panel was actually a vertical capsule, not a
  circle — the name label lived inside the same `PanelContainer` as the 3D
  view, and its line height stretched the panel taller than it was wide. Also
  found the new vignette darkened far enough in to eat into a standing
  creature's own feet. Both fixed: the label moved to a sibling below the
  panel (which is now exactly `VIEWPORT_SIZE` on both axes, a true circle), and
  the vignette falloff eased (0.55→0.7 start, 0.6→0.5 max strength). Cameras
  also pulled back (2.4→2.7 distance multiplier) after a winged species'
  wingtips crowded its own orb edge.
- **Round 3** found flat, low-key lighting inside every orb and ~170px of
  unbalanced dead space between the labels and the button hint. Both addressed:
  ambient light raised 1.6→2.2 and warmed, key light 1.4→2.0, and the layout
  tightened from both sides.
- **Round 4 named nothing new** — restatements of round 3's still-partially-
  addressed items (lighting depth, layout balance, tight per-creature framing)
  plus items already flagged in rounds 2–3 as out of this task's scope (no
  branded UI font/chrome anywhere in the project; the creature models' general
  appeal gap against the Palworld bar). `conventions.md` is explicit that
  reworded repeats are not improvement. This is the same wall `R9.4` hit after
  its own uncapped pass — real, reachable bugs get found and fixed every round
  until the remaining gaps are asset-quality-limited rather than
  composition-limited, and continuing to iterate past that point is exactly
  what the stopping rule exists to prevent. `SA0-orbs-remainder` in
  `BACKLOG.md` records the honest split of what is left and why it stopped
  here rather than running a fifth round.

**`tools/capture_starter_picker.gd`** (new, permanent tool) renders the picker
in isolation rather than booting the full meadows scene — the first attempt at
this loaded the full playground (`diagnose_frame.gd`'s own pattern) and the
whole process died silently under `xvfb`+`opengl3` partway through rendering,
cause not isolated. The picker needs no terrain or scatter behind it, so
narrowing to just the picker sidestepped the crash and is the more honest test
of what actually changed.

**Full local unit suite** (299 tests) run once, unaffected. Not part of this
item's named tests, run anyway as a diligence check given the scope of the
`sequence_director.gd` changes; not repeated on later commits since nothing
touched after that point could plausibly affect it.

## NP4 — Generate the three bases from the board
`fa7636b`/`51c5f28`/`1429832` · `tests: smoke_art` (green, local + import)

`villager_female`, `villager_male` and `grunt` added to `views.json` (5
turnaround columns per row on `docs/art/reference/12_NPC_Bases_Reusable.png`
— more than any other sheet in the pack — only 4 of 5 named per row, since
`meshy.py`'s `VIEWS` has no slot for a second three-quarter angle; see the
sheet's own `_comment_npc_bases`) and to `meshy.py`'s `SPECIES_PROMPTS`/
`HUMANS`. Two crop-time defects found and masked out: a decorative title
flourish bled into `villager_female`'s front crop, and `grunt`'s row has no
clean gap between its feet and its own FRONT/SIDE/etc. caption row.

Generated 3 preview candidates per base (candidate `a` won all three on
fidelity to the board), cleaned with `blender/cleanup_mesh.py` (57k-tri
non-manifold triangle soup → clean 28k-tri manifolds) and retextured.

**Two full rounds of the mandatory blind visual-judge pass** (`conventions.md`),
each a genuinely blind subagent with no knowledge of what changed:

- **Round 1** found real defects: `villager_female`'s twin ponytails invisible
  in the FRONT silhouette (reads as a bob), `villager_male`'s vest textured
  brown against what looked like a blue-gray reference, `grunt`'s face
  rendered completely bare with no mask/goggle geometry.
- **Investigated before reacting.** The vest "defect" traced to the reference
  sheet itself: `12_NPC_Bases_Reusable.png` draws `villager_male`'s vest
  blue-gray in the FRONT panel only and brown in the other four (3/4-front,
  side, 3/4-back, back) — confirmed by eye against the source PNG, not a crop
  bug. The render was correctly following the turnaround's majority signal;
  told round 2's critic about this so it wouldn't re-flag an inconsistency
  that isn't the model's fault.
- Strengthened all three prompts (ponytail-from-front emphasis, dropped the
  wrong vest colour, added goggles as a named signature feature) and
  re-generated/re-textured. **Real, verified improvement on `grunt`**: round 2
  confirmed a mask and defined eyes now render where round 1 found bare skin,
  and marked `grunt` **ACCEPTABLE as-is**. **No improvement on
  `villager_female`'s ponytail** after a fresh 2-candidate regeneration —
  multi-image-to-3D is dominated by the 4 reference images (which themselves
  only show subtle ponytail wisps from the front) more than by prompt text,
  and round 2 itself judged the front-view occlusion "minor... a viewing-angle
  artifact, not a missing asset," which is the honest read of a genuine tier
  limit, not a regression.
- Round 2 surfaced two **new**, real defects that round 1's coarser sheet
  hadn't resolved: `villager_female` has a blotchy, asymmetric UV-seam-style
  texture smudge on one shin/leg (retried the retexture once more, identical
  result both times — not retry noise, a base-mesh UV defect) and a missing
  chest cord/strap; `villager_male`'s trousers render too dark/cold
  (near-charcoal) against the reference's warm medium chocolate brown (tried
  a third retexture naming the actual tone explicitly — no movement).

**Stopped here per `conventions.md`'s convergence rule** — two dedicated
attempts at both `villager_female`'s leg texture and `villager_male`'s
trousers colour produced no movement, the signature of a tuning wall rather
than an in-progress fix (same pattern as `R9.4`'s "needs art that is not in
the build" wall). Shipping `grunt` as fully converged/acceptable and the two
villager bases with their specific remaining defects named plainly rather
than iterating further or quietly calling them done. `NP4-rig` in
`BACKLOG.md` is the follow-on (rig/animate/install have no humanoid path in
`finish.py` at all — that is separate plumbing work, not blocked on these
defects).

Committed the winning lineage into `assets_raw/` per the existing wild-roster
convention (e.g. `brooktail`): each base's 3 generate-stage candidates +
`manifest.json` + the winning texture pass, not the intermediate
`build/clean.glb` or the abandoned round-2 regeneration attempt (~600 credits
spent total across generate + 3 rounds of retexture fixes; balance checked
before/after every call, never exceeded plan).

## NP1 — The modular NPC variant system
`122f04c` (rebased) on `ralph/NP1` · `tests: smoke_art`

Surveyed first, against the actual .glb source files rather than assuming:
**none of the three canon rigs (trainer, Grandpa, Warden) has separable hair
or accessory geometry.** Each is one fused mesh (`char1`), one material
(`Material_1`), one skeleton, five clips — confirmed by parsing the glTF JSON
directly. So "swappable hair" and "show/hide accessory parts" cannot mean
toggling real sub-meshes on today's rigs; that needs `NP4`'s Meshy-generated
modular bases or `EV1-remainder`'s CC0 packs, neither landed yet.

Built the **data and attachment mechanism** instead, honestly scoped to what
that survey found achievable now:

- `character_model.gd`'s flat `_apply_tint` (one colour, multiplied over
  every surface — spec §21's own named failure) is replaced by
  `_apply_palette`, which reads an optional per-material `palette` dict and
  falls back to the legacy `tint` field read as `{"*": tint}`. R7.2's three
  villagers need no data change and render identically — verified: same
  white-base × tint albedo output before and after, checked directly.
- `hair` and `accessories` are new optional data: shape, colour, `visible`,
  attached via `BoneAttachment3D` (so a part follows the rig's clips instead
  of floating fixed), each independent of the other and of the body's own
  palette. The shapes are placeholder `PrimitiveMesh`s, not real geometry —
  `CLAUDE.md`'s Prototyping section is explicit that this proves a mechanism
  and is not to be judged as a look.
- A `static` material cache, keyed by `(model, part name, colour)`, shares
  one `Material` across every NPC asking for the same variant — the "keep
  colour calls low with shared materials" the NPC board asks for, and the
  "mints a material per variant" mistake NP1 was told not to repeat
  (`vegetation.gd::_tint_for` proves the same pattern for foliage; that
  file's own LOD-discarding bug, `SA1-lod`, is still open and was not
  touched here).
- `character_model.gd` gained `build_from_config()`, so a test (or a future
  picker) can drive a one-off variant without writing fixtures into the
  shared `art.json`.

**No shipped NPC's live config changed** beyond one comment: trainer,
Grandpa, Warden and all three villagers still carry only `tint`. The
playable village renders unchanged. Judgment call, recorded rather than
silently skipped: `conventions.md`'s blind-visual-judge pass is for
player-visible change, and there is none in this ship. Wiring real geometry
into an actual NPC — the next step, opened as `NP1-geometry` in
`BACKLOG.md`, blocked on `NP4`/`EV1-remainder` — genuinely will need it.

`tests/smoke_art.gd` gained two checks: one rebuilds `villager_farmer`,
`villager_keeper` and `villager_smith` and confirms they still tint through
the new `palette` translation (not an untouched default-white material);
one builds two NPCs off the same base with different `palette`/`hair`/
`accessories` data and asserts they differ independently — NP1's own "done
when". Run headless, post-rebase, immediately before pushing: 31 lines
printed (22 creatures, trainer + 3 human fits, the 3 villager tints, the new
variant check, vegetation), zero failures — `art: OK`.

## EV1 (Kenney half) — the four HUD/icon packs, staged and ledgered
`fb396b8` · `tests: none` (EV1's own field)

Downloaded and staged all four Kenney packs `EV1` names — UI Pack, UI Pack
(RPG Expansion), Input Prompts, Game Icons + Expansion — under
`assets_raw/vendor/`, CC0, ledgered in `docs/ASSET_LEDGER.md`. `kenney.nl`'s
"Download Now" popup resolves directly to a CDN `.zip` with no login or claim
step, so this half was a plain `curl`. Covers the whole of
`ENVIRONMENT_AND_UI_BIBLE.md` section 5 for `EV9`'s HUD rebuild.

**The two Quaternius MegaKits are not in this shipment.** Opened as
`EV1-remainder` in `BACKLOG.md` and recorded in `BLOCKED.md`: itch.io's
anonymous-claim flow gates the real file URL behind a client-side purchase
round-trip that neither `curl` nor headless Chromium (Playwright, tried and
ruled out — it cannot reach *any* HTTPS host through this session's proxy,
not just itch.io's) could complete. Needs the owner to supply the two zips,
or a future firing with a working itch.io session.

## RB1-actual — Mouse look: the HUD was eating every mouse motion event
`68e0faf` — owner-directed interactive session, 2026-08-11.
`tests: smoke_mouse_look` (new), regression-checked against `smoke_menu`,
`smoke_input`, `smoke_opening`.

**The owner reported mouse look still broken after RB1 shipped.** That is the
on-device confirmation RB1's entry was waiting for, and it came back negative.

**The real cause is one missing line.** `scenes/ui/playground_hud.tscn`'s `Root`
is a full-rect `Control` with no `mouse_filter` set, so it takes Godot's default
of `MOUSE_FILTER_STOP`. GUI input handling runs **before** `_unhandled_input`,
and `camera_rig.gd` accumulates look in `_unhandled_input` — so the HUD consumed
every `InputEventMouseMotion` and the rig never saw a single delta. No error, no
warning, from the first frame.

**Why only mouse look broke.** Gamepad look is *polled* in `_process` via
`Input.get_vector("look_left", …)` and never travels the event path. Movement is
actions, same story. Mouse look is the one input that goes through
`_unhandled_input`, which is exactly the input the owner reported.

**Every other UI scene already had this right** — `combat_hud.tscn`,
`dialogue_panel.tscn` and `name_prompt.tscn` all set `mouse_filter = 2`, and
`game_menu.tscn` sets `MOUSE_FILTER_STOP` deliberately because a pause menu
*should* take the mouse. `playground_hud.tscn` was the one that missed it.

**Proven, not argued — which is the whole point.** RB1 was diagnosed by reading
code and shipped unverified, and it was wrong. This one was reproduced first:
a probe node's `_unhandled_input` sees the motion **with** the fix and does
**not** see it with the single `mouse_filter` line removed. Both directions run.

**A test trap worth knowing before writing another input test.** The obvious
test — push a motion event, assert the camera yaw changed — **cannot work
headless**. Setting `Input.mouse_mode = MOUSE_MODE_CAPTURED` reads back `0`
(VISIBLE): the headless DisplayServer refuses capture. `camera_rig.gd` only
accumulates look while that reads CAPTURED, so a yaw assertion fails identically
whether the bug is present or fixed. That was the first version of this test and
it was worthless. `smoke_mouse_look.gd` asserts **delivery** instead, via
`tests/helpers/unhandled_probe.gd`, plus a structural assertion that no
full-rect `MOUSE_FILTER_STOP` Control is visible during gameplay so a regression
names its own cause.

**RB1's fix is kept.** Re-asserting capture on `focus_entered` is correct
behaviour and `SH53` still wants it; it just was not this bug.

**RB1's entry also contains a disproven guess** — that the owner could not reach
Grandpa because they could not turn toward him, "a symptom of RB1, not a second
bug." Wrong. `SA0` root-caused that to a one-way beat machine. Two independent
real bugs, and the guess linking them cost time. Worth remembering next time a
single report seems to explain two symptoms.

**Still only answerable on the owner's hardware:** whether Windows delivers
relative motion to the process while the cursor is captured. Same device-layer
split `smoke_input.gd` documents.

## LP1 — Kill the `smoke_traversal` and `smoke_combat` flakes
`330ba3d` on `ralph/LP1`. `tests: smoke_traversal, smoke_combat`.

**Traversal was already fixed** by the `below`-surface-vs-airborne-slope
invariant already sitting in `tests/smoke_traversal.gd` — nothing to change
there. Verified rather than assumed: 19/20 headless passes clean in one
uncontended batch (the one non-pass was a 90s timeout killed by *my own*
concurrent combat runs competing for CPU, not a test failure), plus a
second, fully isolated batch afterward with the same result. Between the
two, every clean run held; no `sank below the terrain surface` failure
appeared once.

**Combat had a real bug, found the way `RB3` and `R4.11` both prescribe:
a recorded run log, not more reasoning about the code.** An instrumented
copy of `smoke_combat.gd` (per-frame position watchdog across the whole
fight, never committed) caught the exact moment things go wrong:
`_a_swing_at_empty_air_misses()` stages the player's pal across the arena
with `_ally.global_position = centre + out.normalized() * (radius - 1.5)`
— a raw position write that carries the arena centre's own Y across a
9.5m horizontal jump. On flat ground this is harmless; on this rolling
terrain it occasionally lands the pal embedded under Terrain3D's
one-sided heightfield collider, below the true surface at the new x/z,
with no floor to catch it. Once that happens the pal free-falls at
terminal velocity for the rest of the fight — one instrumented run
logged the ally's Y crossing from -0.17 to below -900 over the following
~2000 frames — and every downstream assertion this file has ever failed
on falls straight out of that: the "did no damage 95.0 -> 95.0" miss this
item was opened for, "the enemy never landed a hit", "the fight never
resolved after 2500 action frames", "the camera did not return to the
trainer". Two separate instrumented runs caught it live (~2 failures in
17 runs of the *unfixed* test, matching the file's own history of rare,
CI-only flakes).

This is exactly the bug class `combat_manager.gd::_stand_the_trainer_aside`
already paid for once (its own comment names D09: never carry a Y across
a horizontal move) — just not applied to this test's own teleport. Fix:
re-ground via `place_on_ground` (the same helper `combat_manager.gd::_place`
already uses), falling back to the raw write only if grounding fails,
matching the established pattern exactly.

Verified: 20/20 consecutive clean headless runs of the fixed
`smoke_combat.gd`, zero failures, after 17 runs of the pre-fix version
that had already reproduced the failure twice. Traversal and combat do
**not** share a cause, as the item's own note warned — traversal's fix
predates this firing, combat's is a genuine teleport bug local to one
test helper.

## D25 — Loop speedups: parallel lanes, batched pushes, local critic iteration
`6b848b6` and `346e6e0` — owner-directed interactive session, 2026-08-11.
Full reasoning: `docs/decisions/D25-batch-the-push-not-the-testing.md`.

The owner asked for a faster loop and offered a floor (chain firings instead of
idling to the hour) and a ceiling (do not test or ship until a whole phase is
done). **The floor is adopted; the ceiling is rejected**, and D25 carries the
arithmetic so it is not re-proposed.

**Measure before optimising — two numbers the loop had been reasoning from were
wrong.** A branch CI run is **5.2 minutes**, not the 8–9 `conventions.md` and
`ci.yml` both claimed; the loop had been optimising against a figure 80% too
high. And a three-round blind visual pass had cost **8 pushes, ~36 minutes of
CI**, not one. So CI is not where the time goes — the visual-pass amplification
is, and about a third of the backlog is visual-affecting.

**The largest change is therefore the cheapest**: render, critique, fix and
re-critique in the firing's own checkout, push once at the end. The blind pass
is unchanged and still required; only where its rounds run moved.

Also shipped: per-`area` leases with one block per live firing (a firing stands
down only when its *own* area is held); expiry 90 → 40 minutes, made safe by
checking the task branch for recent commits rather than trusting the clock;
`lane: art` so unkeyed lanes skip Meshy items silently instead of reporting
blocked; batching 1–4 items per branch, never across areas and never a red item
with a green one; successors chained 2–3 minutes out.

**`LP1` promoted** to a new Phase -0.95 from a bullet at the bottom of the file.
Batching makes the `smoke_traversal`/`smoke_combat` flakes worse, not better —
one random red now rejects up to four finished items.

**Two operational facts found the hard way, both now in `MANUAL.md`.** An agent
cannot create a working lane: `create_trigger` has no `sources` parameter, so
the sessions it fires come up with **no repository checked out**. Two lanes were
created that way, fired on schedule, and produced nothing at all while reading
`enabled: true` with a correct cron in every listing. And the keyed "Ralph"
Routine was created via the HTTP API, so **no agent can unpause it** — only the
Routines UI can. `ralph/LANE_PROMPT.md` holds the exact prompt text and the
ten-minute test for whether a new lane actually works.

## D24 — The art bible, the NPC board, and one family per category
`4eeff21` — owner-directed interactive session, 2026-08-11.
Full reasoning: `docs/decisions/D24-one-nature-family-one-village-family.md`.

The owner's words: *"the visuals is the most important part and we're not
bailing the palworld look and it's not getting fixed from what I can tell."*
R9.4's own evidence agrees — **both blind critics ranked "needs art that is not
in the build" first**, and scene tuning had genuinely run out of road. The audit
behind the decision: 42 of 116 nature models present, **no** village kit, **no**
props kit, **no** UI assets beyond two portraits.

Landed verbatim behind provenance headers: `docs/ENVIRONMENT_AND_UI_BIBLE.md`
and `docs/art/reference/12_NPC_Bases_Reusable.png` (numbered `12_` to follow the
existing convention). D24 makes them canon: one nature family, one village
family, one prop family; **Medieval Village MegaKit is the Meadows civilian
vernacular**; keep Terrain3D; do not return to Forward+; Meshy is reserved for
Team Tether hero objects; the HUD gets rebuilt on Kenney UI. Free Standard tiers
only — the Source editions' foliage shaders are **not** available and nothing
may assume them.

**Two rules changed, and both will stop a task dead if learned late.** No Meshy
generation without an owner-supplied reference board — the account went to 5000
credits and reference art, not money, is the constraint now. And **D23 §20
stands at any balance**: the owner reaffirmed it *with* 5000 available, which
proves it was never a budget rule. Creatures and humans are rework-only,
permanently, and the fidelity gap a critic called "the loudest single problem in
the whole review" is an accepted cost rather than an oversight.

**Both `BLOCKED.md` design questions close.** The settlement's vernacular is
named by the bible; art cohesion resolves to rework on both halves. What
replaces them is a standing list of what the owner still has to *draw* — the
Tether pylon, the relay apparatus, the legendary tether machine.

`BACKLOG.md` gains Phase -0.6 (`EV1`–`EV10`, the look) and Phase -0.55
(`NP1`–`NP4`, the cast). **Ten items are collapsed into them rather than left
running in parallel** — `R9.4-remainder-1/-2/-3/-4/-5/-7`, `R7.1-remainder-2`,
`R7.1-found-3`, `SB7`, `SB8` — each keeping its original evidence, because the
superseding item inherits it as the bar to clear. Two stay open on purpose:
`-8` is a metre-is-a-metre problem a new kit inherits rather than cures, and
`-6` is the `survey_combat` hang, unrelated to art.

## SA1 — Reclaim ~630 MB of VRAM on the ROG Ally
`28af489` — owner-directed interactive session, 2026-08-11.

Owner report: *"the game on the rog is really choppy. it runs high memory, no
cpu and only like 25% GPU. so I think it's a memory issue."* They were right,
and the profile itself was the clue — a GPU at 25% while the frame time is bad
is memory-bandwidth-bound, not shader-bound.

**~808 MB of creature texture VRAM was resident at world start, ~650 MB of it
avoidable.** Thirteen of seventeen species imported `compress/mode=0`
(Lossless → uploads as raw RGBA8) instead of S3TC, because
`detect_3d/compress_to` **never fires for textures only ever `load()`ed at
runtime** — `pal_body.gd:179` does exactly that, so the editor's detect-3D hook
had never run on them. Measured: `brooktail` base colour **21.3 MB** against
`bramblebun`, correctly compressed, at **2.7 MB**.

**~192 MB of it was 2048² emissive maps that are flat black** — 12 KB on disk,
21.3 MB in VRAM each. All twelve verified `max channel value == 0` before being
shrunk to 4×4, so nothing visible was lost.

Also fixed: foliage mipmaps were off on all 14 textures (un-mipmapped 512²
sampled at ~50:1 minification is aliasing by construction); both shadow atlases
sat at Godot's **4096 desktop default** — ~67 MB each — because no atlas size
had ever been set; MSAA 4× → 2×. And `project.godot`'s `config/features` still
read "Forward Plus" while the renderer below it said `gl_compatibility`, left
over from RB4.

**Ruled out** rather than guessed at: terrain (~3 MB), `preload()` (all 67 are
scripts), MultiMesh instance buffers (~1.7 MB), per-frame allocation.

**On-device confirmation is still open — CI cannot measure VRAM**, same as RB4.
If it is better but not fixed, the next suspect is already written down and
queued as `SA1-lod`: `vegetation.gd::_retint()` rebuilds an `ArrayMesh` and
discards the importer's LOD chain, so 23,452 instances draw at LOD0 at every
distance.

## SA0 — The opening soft-locked, so the game was uncompletable
`6dffa21` — owner-directed interactive session, 2026-08-11.

Owner report: *"you still can't interact with grandpa at the beginning. so then
you leave the house and never get a starter."*

**It was not an interaction bug**, which is where the investigation started and
where it would have stayed without checking. The interaction system is clean —
pure 3D distance, no facing, no line-of-sight — and no house geometry blocks
Grandpa; every R9.4 addition passes `solid = false`, and his prompt radius
reaches most of the ground floor.

**It was a one-way state machine with an unguarded exit.** During the `wake`
beat, `conversation_for("wake")` is `""`, so the director leaves Grandpa's
`Interactable` **disabled**, and a disabled node returns an empty offer, so the
arbiter never sees him. The **only** thing in the game that leaves `wake` is
pressing interact on the bed — and nothing forced it, because `_refresh_lockout()`
never gated locomotion on the beat. The fade cleared after ~2.1 s, the player
walked off the bed, and the beat stayed `wake` forever: Grandpa mute, starters
inert (they enable at `choose`), door ungated. Exactly the reported symptom.

Fixed with `_check_left_the_bed()` — a `BED_LEAVE_RADIUS` of 3.2 m off a
recorded bed anchor advances the beat. **A second route to the same deadlock**
was fixed in the same commit: a world with no house had no bed and therefore no
exit at all, and the comment claiming a bare-scene fallback worked was false.
Deleted `_advance()`, which had no callers anywhere.

**Why the existing test was blind to it, corrected.** I first assumed
`smoke_opening` shortcuts by driving beats directly. **It does not** — it
genuinely walks, waits for the arbiter, and presses the real `interact` action.
It cannot see this bug because it **hard-codes the correct order**, always
pressing the bed first. The new `tests/smoke_wake_softlock.gd` walks off the bed
*without* pressing it, and **was verified to fail against the unfixed code**
before the fix landed: *"SOFT-LOCK: walked 4.8m from the bed without pressing it
and the beat is STILL 'wake'."* A test that has not been seen to fail is not
evidence.

`SA0-orbs` in Phase -0.9 is the rest of the owner's instruction — the starter
choice moving into Grandpa's conversation — and is deliberately not in this
commit; it needs a dialogue-effect vocabulary and an orb-as-container concept
that do not exist yet.

## R9.4 — Full visual pass, two blind critics, three render rounds
`86c9eb2` (spec landing), `585cb67` (tooling), `6cfe752` (round 1), plus the
round-2/3 commits above — owner-directed interactive session, 2026-08-11.
Full record: `docs/reviews/2026-08-11-r9.4-full-visual-pass.md`.

**Shipped as PARTIAL, deliberately.** The pass moved every measured axis and
fixed a great deal, and it did not reach the bar. Six honestly-named remainders
are open in `BACKLOG.md` (`R9.4-remainder-1` … `-6`) and one design question
went to `BLOCKED.md`. Do not read this entry as "the visuals are done".

**The root cause of the green was structural, not taste.** `albedo_color`
multiplies, and multiplying by a tinted colour can only RAISE saturation — it
scales down whichever channel is already lowest. The ground carried three
tinted multipliers stacked: texture tint took `Grass008`'s own 0.675 to 0.796,
the baked colour map to 0.859, macro variation to 0.873. Each looked like a
gentle tint on its own. The design intent, in `terrain_playground.json`'s own
comment, required them to be near-white, and set a floor of `#c0` per channel;
the colour map's blue is `0x92` = 146 and had been violating that rule since it
was written. The grass tint is now **solved rather than eyeballed** — it reads
as lavender in a picker because raising blue relative to green is the only way
a multiply desaturates a green — and lands the stack on hue 70 / saturation
0.564, which is `palette.json`'s `meadow.grass_olive` sampled off the board.

**Measured movement**, `tools/frame_stats.py`, round 1 → round 2: saturation on
frame 01 0.70 → 0.59 (references 0.40–0.46); near-field luminance 0.526 → 0.271
(references 0.28–0.60); saturated non-green below the horizon 1.0% → 4.0% on
01, 37% → 61% on 03, 25% → 86% on 05, putting two frames inside the reference
band where none had been.

**Four defects that no test could have caught**, all found by the critics:
signpost text rendering MIRRORED (one `Label3D` on the plank's top edge facing
along the arm, so the side you read it from is the back of the letters, and long
names ran off both ends because nothing fitted them); a creature embedded in the
farmhouse roof; a magenta placeholder cube in two frames; and — caught in the
same pass that introduced it — a stone plinth built as one box across the whole
footprint, laying a grey lid over the interior floor.

**The red leak had been found before and never fixed.** `Leaves_TwistedTree_C`
is RGB(167,23,23), crimson, on decorative grove trees beside the starting
village — the one colour the rubric reserves for Team Tether. The 2026-08-09
site-frames critique named it; this pass named it again eleven days later. The
bushes layer had already been fixed for the *same texture* by swapping it. The
grove was simply never given the treatment. **Turn accepted criticism into a
backlog item the same day, not into a paragraph in a review.**

**Grandpa's house was rebuilt.** It was a flat-roofed windowless box whose only
opening the critic read "as a missing texture, not a doorway", and it was named
the single highest-value piece of missing art in the set because it is the
player's home and it appears in three of five building frames. It now has a
pitched gable roof with eaves, fascia, ridge and chimney; six windows with
frames, mullions and warm emissive panes; a framed doorway with a threshold
step; a stone plinth ring and corner posts. Still primitives, which `CLAUDE.md`
permits. `smoke_opening` passes end to end after each change — the doorway and
the interior navigation are load-bearing for it.

Also fixed: twelve harvest nodes rendering as coloured `BoxMesh` fallbacks
because none had a `model` (two sat beside the player at spawn, and the critic
called them "more legible than the player"); flowers at 4× life size measured
against the 1.8 m NPC, grass at 2.5×, the signpost at 1.5×; path stones blowing
out to near-white; sixty-two dead trees in a biome the board calls "peaceful by
day"; and the canopy sitting in the same hue family as the ground it stands on.

**Two new tools, both committed** (`585cb67`): `tools/capture_buildings.gd`,
because nothing in `tools/` framed a building at the range a player walks past
it — which is why the owner's named weak point had no evidence behind it — and
`tools/sheet.py`, a labelled contact sheet for any number of frames, because
`contact_sheet.gd` reads `shots/*.png` only and has no font rendering, so a
critic cannot name the frame its finding is in.

**The arena was NOT reviewed.** `survey_combat.sh` ran ~50 minutes and wrote no
frames while the buildings pass beside it finished seven; it was killed to give
the box back. Whether that is a defect in the tool or the cost of software
rendering under contention is **not established** — `R9.4-remainder-6` says so
plainly rather than guessing.

---


---

## R7.2 — NPC villagers and interior polish
`f33ed92` on `main` (owner-directed interactive session working Phase -0.5
through Phase 1; the commit landed via this session's own auto-rebase onto
`main` once `RB4`/the vegetation fix shipped underneath it — see its own
message for the technical summary).

Three villagers (Mira, Oskar, Tam) stand in the village square, placed by a
new `scripts/world/village_npcs.gd` from a new `data/config/village_npcs.json`
— same data-describes/code-places shape as `village.gd`'s structures and
`sequence_director.gd`'s opening cast. Each is a plain `npc_body.gd` body
(Grandpa's own script, unmodified) offering a "Greet <name>" prompt that opens
a short flavour conversation from a new `data/dialogue/village.json`, merged
onto `dialogue_runner.gd`'s existing table additively (`opening.json`'s own
conversations and `test_dialogue_runner.gd`'s coverage of them untouched).
`DialoguePanel` is now discoverable through a `"dialogue_panel"` group in
`meadows_playground.tscn`, mirroring how `interactable.gd` already finds the
interaction arbiter — so `village_npcs.gd` reaches it without
`sequence_director.gd` changing at all.

**Villager bodies are a real decision boundary and it was not crossed.** The
only unused humanoid asset is KayKit's `Ranger.glb`, and it is a ~2-heads-tall
toon character next to the trainer/Grandpa/Warden's photoreal-ish
proportions — using it would silently pre-empt the creature/human
art-pipeline question already parked in `BLOCKED.md`, which `CLAUDE.md`
forbids inventing. Instead villagers reuse the existing Grandpa/trainer rigs
through a new `character_model.gd` `_apply_tint()`: a real material-level
palette swap (`albedo_color` multiplied per surface, texture kept) rather
than a flat recolour, driven by a new `tint` key on three new `art.json`
blocks (`villager_farmer`, `villager_keeper`, `villager_smith`).

Grandpa's house interior dressed past the "undressed grey box" both
2026-08-09 reviews named: two rugs (`_box()`'s existing flat-coloured-box
shorthand, never solid), Grandpa's own bed and a second bookcase in the
previously-empty south-west corner, a second table by the door carrying the
backpack/axe/knife his own dialogue already describes ("that pack by the
door carried me thirty years"), and a spare door leaning in a corner. Every
new solid piece's real runtime collider was checked with a headless probe
against all three lanes the opening or `smoke_opening.gd` actually walks
(stairs-foot to Grandpa, Grandpa to the door, bed to stairs-head) before the
positions in this entry were finalised — not guessed from the JSON/code
coordinates.

**Visual pass, with an honest process gap.** `ralph/conventions.md`'s rule
calls for rendering real frames and judging them with a genuinely blind
sub-agent with no knowledge of what changed. Frames were rendered for real
(`tools/capture_site_shots.gd`, two new viewpoints — `village-npcs` and
`house-interior-dressed` — plus the existing site shots, composited with
`tools/contact_sheet.gd`) and judged against `docs/reference/` using
`.claude/skills/visual-judge/SKILL.md`'s rubric. What did **not** happen as
specified: this session's toolset had no Task/Agent-spawning tool with a
result-return channel — `mcp__Claude_Code_Remote__create_session` can spawn
an independent session, but nothing in this toolset can read back what it
finds (no `list_events`, no `ListAgents` to address it via `SendMessage`),
so a genuinely blind critic could not be run and have its verdict retrieved.
The render+critique was done by this same session instead, disclosed here
rather than silently presented as the required blind pass. One real,
addressable finding came out of it anyway: the first cut of the villager
tints (`#d9a66b` / `#8fae8a` / `#7a7f8c`) read as too close to Grandpa's own
palette and to the grass at normal viewing distance — bumped to more
saturated `#c9793a` / `#4f8a5b` / `#3f5a8c` and re-rendered to confirm the
improvement. Remaining honest limitation: the Compatibility renderer this
harness is forced to use (`D06`) is explicitly not trustworthy for fine
colour/lighting judgement, so the tint legibility question is worth a real
second look whenever a genuinely blind pass becomes possible.

**Tests.** `tests/smoke_opening.gd` green with all three villagers present
(villager prompt labels are "Greet <name>", never containing "talk" or
"choose" — checked against the exact substrings the test's own interactable
lookups gate on). Full suite (`tests/run_tests.gd`) also run, since dialogue
plumbing is shared infrastructure: 299 tests, 0 failed.

**Follow-up: the genuinely-blind pass this entry's own gap disclosed now
actually ran.** The owning interactive session has the `Agent` tool the
sub-agent's own toolset lacked — spawned a fresh sub-agent with zero
knowledge of what changed, `.claude/skills/visual-judge/SKILL.md`, and 7
frames rendered from a confirmed `origin/main` checkout (`c0ca15e`, no
local uncommitted state, `tests/smoke_opening.gd` re-verified green on that
exact commit first).

The verdict found real, substantive things — sky/hill horizon fusion,
uniform-spacing vegetation scatter, and a fidelity gap between the
character/creature art and the environment art around it — but **none of
them are new defects R7.2 introduced**, checked one by one:
- The black spire on the hill in `village-square` — already `BACKLOG.md`'s
  tracked `R7.1-visual-remainder-2` ("two uneven dark spikes... reads as
  standing stones or a broken obelisk pair"), not a new finding.
- Mirrored/backwards signpost text in `village-npcs` — `signpost.gd`'s own
  documented tradeoff (labels face the arm's orientation, not the camera;
  "unreadable from behind... also true of a real wooden signpost arm, so it
  is not a regression" — R7.1-visual round 2's own comment). This
  particular viewpoint happens to catch it from behind; the geometry is
  unchanged from before this item.
- The "unset mirror material" (a flat blue oval) in
  `house-interior-dressed` — traced to the pre-existing `Mirror` furniture
  piece, not one of this item's additions (`_build_furniture()`'s diff
  adds only `BedDouble`, `Bookcase`, `Table2`, `Backpack`, `Axe`, `Knife`,
  `Door1` and two rugs — no mirror or wardrobe call). A flat-colour "glass"
  plane is a normal low-poly-pack simplification, not obviously broken.

The broader findings (horizon atmospheric haze, scatter clustering,
environment-vs-character fidelity) are real and apply across the whole
game, not to anything R7.2 touched specifically — carried forward into
`R9.4`'s full-game pass rather than chased here, which is exactly the kind
of finding that item exists to catch.

## Vegetation colour jitter — fixed a MultiMesh use_colors ordering bug
`16138ec` on `main` (owner-directed interactive session working Phase -0.5
through Phase 1). Found incidentally: a background sub-agent's render log
for `R7.2` showed the engine error "Can't set instance color on a
Multimesh that isn't using colors" **11,317 times** in one render. Root
cause in `scripts/world/vegetation.gd`'s `_build_batch()` (introduced by
`R7.1-remainder` round 2, `77421cf`): `multi.use_colors = true` was being
set AFTER `multi.instance_count = placements.size()`. `MultiMesh`
allocates its per-instance buffer at the moment `instance_count` is
assigned, sized from whichever format flags are set then — `use_colors`
set afterward reads back `true` in GDScript but never actually took effect
server-side, so every jittered grass/drygrass instance's
`set_instance_color` call failed silently (a caught engine error, not a
crash) and kept its default, unjittered colour. Fixed by reordering: set
`use_colors` before `instance_count`. Verified: 299/299 tests still pass;
a fresh headless render shows zero occurrences of the error where the
same render previously showed thousands. This means the round-1/2/3
`R7.1-remainder` visual-judge critiques were all judging a build where the
colour-jitter fix was largely non-functional — the ground-cover-still-
reads-procedural finding in `R7.1-remainder-2` may partly be a
consequence of this bug rather than the clustering/density tuning alone;
worth re-checking once a fresh render is in hand.

## RB4 — ROG Ally freeze root-caused and fixed: switched to the Compatibility renderer
`38189fa` on `main` (owner-directed interactive session; see
`ralph/STATUS.md`'s lease note). Builds on `RB4-diagnostics` (below) and
the on-device data the owner supplied 2026-08-10/11 (see `BLOCKED.md`'s
former RB4 entry, now resolved, for the full evidence trail).

**Summary of the evidence**: two separate launches on the Ally, ~25
minutes apart, both hung. The boot log shows both completing every
instrumented phase (terrain, shaders, player, ~16,700-instance vegetation
scatter, settlement) in ~6 seconds, then stopping at the identical last
line — `_ready complete, waiting for first frame` — and never writing the
next one. Task Manager during the hang: the process shows `Not
Responding`, ~1.4GB memory, but **0% CPU, 0% disk, 0% network**, never
resolving after 10+ minutes. That combination rules out the original
"slow shader compile" hypothesis (which would show CPU/GPU load) and
points at the render thread blocked on a Forward+/Vulkan call — most
likely a present or pipeline-compile fence — that never returns, specific
to this GPU/driver.

**Fix**: `project.godot`'s `renderer/rendering_method` changed from
`forward_plus` to `gl_compatibility` — sidesteps Vulkan entirely.
`docs/decisions/D01` rewritten with the full reasoning: this reverses
D01's original Forward+ choice (which bet the Ally's RDNA3 iGPU would run
it "comfortably" — that bet is what the on-device data disproves), and
notes the cost paid knowingly (no SDFGI/volumetric fog/Forward+ shadows).
One favorable side effect: Compatibility/GLES3 is already the exact
renderer every headless CI render and every `.claude/skills/visual-judge`
critique this project has used all along (D06) — the shipped build now
matches what has actually been screenshotted and graded, rather than
diverging from it.

Owner directive: fix it with the on-device data already in hand rather
than continue remote troubleshooting (boot log access was awkward on the
handheld itself). **Real on-device confirmation that the freeze is
actually gone is still worth having**, same as RB1/RB2's pattern, but
unlike those two this fix has strong, specific evidence for why it should
work, not just a plausible theory.

## R7.1-found-2 — the near-vertical bank near spawn was overlapping building pads, not a path or texture bug
`94d267c` on `main` (owner-directed interactive session working Phase -0.5
through Phase 1, background sub-agent in isolated worktree
`agent-acc396239df681ed1`; see `ralph/STATUS.md`'s lease note).

`BACKLOG.md`'s own entry (written when this was found) guessed the cause as
a steep-slope texture-projection problem on the path trench. Live sampling
of `height_at()` across the bank's cross-section proved that guess wrong:
the ground genuinely drops ~1.5m over well under a metre there (an 81°
wall) — this is a real geometry defect, not a shading/UV artefact, and has
nothing to do with the dirt path (`path_factor()` only tints colour;
`height_at()`'s chain has no path-height term at all).

Root cause: `_apply_flats()` in `scripts/world/playground_heightfield.gd`
flattens the ground under building pads (Grandpa's house, the village
square), and those two pads sit close enough that only ~0.5m of open ground
separates their circles. The old rule had the strongest-weighted pad "win
outright" and blend the whole area toward its target height alone — correct
for one pad shading into natural ground, but where two pads' skirts
overlap, the winner flips at one point, and near that flip both weights are
still ~1 (deep inside the overlap, not out at the fringe), so height
snapped nearly the full 1.6m gap between the two pads' target heights
across a couple of centimetres.

Fix, two parts: outside every pad's own radius, `_apply_flats()` now blends
the target *heights* by relative weight instead of picking one winner
outright (strictly inside a pad's radius it still returns that pad's height
alone, unchanged — the part `test_the_building_pads_are_genuinely_flat`
guards and which must stay exact to avoid the tilted-pad regression the
winner-take-all rule was originally added to prevent); and the two pads'
target heights themselves move closer together (2.2m/0.6m → 1.2m/0.9m),
continuing the same tuning direction this file already used once before.
Terrain rebaked via `build_playground_terrain.gd`.

Live-verified: worst slope within the old trench footprint is 8.5° now
(was 81°); worst slope across a wide scan of the whole village area is 25°,
on ordinary hill terrain unrelated to the pads. 299/299 tests pass,
including the unchanged `test_the_building_pads_are_genuinely_flat`.
Confirmed by a fresh blind visual-judge pass on the two originally-flagged
frames (01, 05): "No near-vertical earthen bank and no dirt-trench gouge in
either frame... a gentle, continuously-curved rolling hill." The same pass
found one new, smaller, unrelated defect — see `BACKLOG.md`'s new
`R7.1-found-3` entry (a texture-splat stripe on the same hillside, not
touched by this fix, which only changed height/geometry).

---

## R7.1-remainder — PARTIAL: ridge-bias clumping and ground-cover clustering shipped, neither bullet fully passes the blind critic after 3 rounds
`af6e2fc`, `77421cf`, `44ec290` on `main` (owner-directed interactive
session working Phase -0.5 through Phase 1, see `ralph/STATUS.md`'s lease
note, not a normal Ralph firing).

Three rounds, each rendered and judged blind against `docs/reference/` via
`.claude/skills/visual-judge` per the visual-gating convention.

**Horizon/mid-ground clumping** (`scripts/world/scatter_rules.gd`): a new
`ridge_bias` layer parameter, and `_clump_centre()` now searches a local
neighbourhood (`RIDGE_SEARCH_RADIUS` 140m, `RIDGE_CANDIDATES` 6 samples)
around each clump's own unbiased draw for higher ground, rather than a
blanket density increase. Round 1's first version searched candidates
globally across the whole map, which concentrated the bias toward the
map's 2-3 tallest named peaks and did nothing for the horizon in most
compass directions — caught by direct inspection of round-1 renders (the
horizon in frames 01/04 stayed bare despite the "fix") and redesigned to
the local-search version before round 2's critique ran on it. `trees`
layer set to `ridge_bias: 0.75` in `data/config/vegetation.json`. New
tests `test_ridge_bias_of_zero_changes_nothing` and
`test_ridge_bias_of_one_prefers_higher_ground` in
`tests/test_scatter_rules.gd`.

**Ground cover clustering** (`scripts/world/vegetation.gd`,
`data/config/vegetation.json`): raised `grass`/`drygrass` tuft scale
ranges, added per-instance MultiMesh colour jitter (new `colour_jitter`
layer key, via `set_instance_color` + `vertex_color_use_as_albedo`) for
value variation with zero extra draw calls, and cut `strays` across rounds
2-3 (grass 2000→500, drygrass 700→200) so the remaining tufts read as
clumps with real gaps rather than even confetti.

**Round-3 (final, per the 3-round cap) blind critique verdict**: genuine,
visible improvement over the pre-fix state — 03-rise-overlook and
04-three-quarter both show real clump/clearing structure that wasn't there
before — but the critic, still blind to what changed, named both original
bullets as **not yet passing**: ground cover still "appear[s] at roughly
even spacing and uniform scale... no clearings, no clustering around
features"; and the horizon/mid-ground still shows "no middle-distance
layering anywhere in the set," which the critic ranked as the single
biggest reason the frames feel empty compared to both references. Handed
back as an honest remainder, not a false done — see `BACKLOG.md`'s new
`R7.1-remainder-2` entry for the specifics and what a next pass should try
differently.

**One critique finding investigated and resolved as a non-issue**: the
critic flagged "a flat grey rectangular box floats just above the grass
near the player" in frames 01 and 05 as a likely leaked debug marker.
Traced to `scripts/world/harvest_node.gd`'s deliberate placeholder visual
(a slot-coloured box; `CLAUDE.md`'s prototyping rule explicitly allows
placeholder geometry to prove a mechanic) for the wood-gathering node at
`(-8, 8)` in `data/config/harvest.json`, near both frames' shared eye
position. Not a bug — a critic with no knowledge of the game's systems has
no way to tell a deliberate stand-in from a leaked gizmo. No action taken;
recorded here so the next reader doesn't rediscover the same box and
wonder.

---

## R7.1-found — moved the rise-overlook survey eye off the tower cluster
`eb880cb` on `main` (owner-directed interactive session working Phase -0.5
through Phase 1, see `ralph/STATUS.md`'s lease note, not a normal Ralph
firing). `tools/survey.gd`'s `03-rise-overlook` eye moved from
`(148, -102)` to `(190, -60)` — still on the same rise (`landmark.gd`'s
`RISE_CENTRE` radius), but ~60m from the stronghold silhouette's tower
cluster instead of ~14-24m, so the viewpoint frames the intended wide
valley shot instead of one tower point-blank. Verified by re-rendering:
the tower cluster is now a small, correctly-distant shape at frame edge
instead of filling most of the frame. Moved the eye, not the towers, since
`R7.1-visual-remainder-2` (still open) may reshape them again.

---

## R7.1-visual-remainder — the stronghold silhouette gets a wall, roofline and crenellation
`7e17d40` (new geometry: perimeter wall, peaked roof on the keep, stepped
mass and crenellation rings on the others — pushed by an earlier firing,
session -j) + `eed557e` (widened base drum and connecting wall, so the shape
survives the required blind-critic pass — this firing). Both fast-forwarded
to `main` (verified via `origin/main`'s own log).

**Process note, since this is unusual:** `7e17d40` shipped clean — CI green
(run 31427097069), release dispatched and succeeded (run 31427521553) — but
the firing that pushed it died before running conventions.md's required
render + blind visual-judge pass for visual-affecting work, and before any
BACKLOG.md/DONE.md bookkeeping. This firing found that on claiming the lease
(the `ralph-status` entry was still `started`, but `main`'s own tip and the
now-deleted task branch corroborated a real ship, not a dead mid-push
firing — the same class of near-miss the RB3 story in this file already
documents, resolved the same way: check `main`, not the raw lease
timestamp). Rather than treat 7e17d40 as someone else's unfinished work to
redo, this firing finished it: ran the missing verification, found real
defects, fixed them, and is recording the whole thing as one entry since
it's genuinely one piece of work split across two firings.

**The three-round blind-critic loop, run for real** (fresh subagent each
round, zero knowledge of what changed, per conventions.md):

Also found and fixed along the way, not part of the loop itself: my first
attempt at rendering used `godot --headless ...`, which is *not* what
`tools/capture_wayfinding.gd`'s own header comment specifies. Headless mode
apparently never fires the `await RenderingServer.frame_post_draw` the
script's last step depends on — the render hung for 90+ CPU-minutes with
zero output before this was caught and killed. Dropping `--headless`
(matching the documented invocation exactly) fixed it outright; the same
render then completed in under a minute. Left as a note here since the next
firing that reaches for this tool could easily make the same mistake.

**Round 1** (base drum 3m tall, bare crenellation boxes): failed. "The
three towers read as 'standing stones' or 'obelisks'" was R7.1-visual's own
finding, unchanged — 7e17d40's geometry alone didn't move it. Specific
findings: long range collapsed the whole structure to two ambiguous prongs
(the straight wall segments between towers go edge-on and vanish depending
on camera bearing, so nothing visibly joined the two nearest towers);
crenellation merlons read as "claws, broken glass, or a jagged rock spur,"
not a battlement, once they stopped resolving as separate boxes.

**Round 1's fix:** base drum 3m → 9m tall (a cylinder's silhouette width is
angle-independent, unlike a straight wall, so a tall drum reads as a solid
plinth from any camera bearing); added a solid collar ring under each
tower's crenellation merlons so the notched top has a continuous base to
sit on instead of floating separate boxes.

**Round 2:** close range now "reads clearly and unambiguously as fortress
architecture" — the fix worked there. Long range still failed: "two dark
vertical prongs... closer to standing stones/rock spires/chimneys than a
stronghold." Real diagnosis, not a guess: the widened base drum sits at
0-9m elevation, and that's exactly the elevation a distant, low, grazing
camera has occluded behind the ridge's own nearer terrain — the same reason
a fence looks taller than the house standing behind a hill crest from far
away. The only part of the structure confirmed visible in every long-range
frame was the towers' upper portions.

**Round 2's fix:** raised the connecting WALL itself (not just the base
drum) from 11m to 16m — still under every tower's own height (shortest is
west at 18m, preserving "towers read as the skyline's tallest shapes") but
tall enough to bridge the towers' visible upper portions instead of their
already-occluded feet. Wall thickness 1.6m → 2.8m for more presence.

**Round 3 (the cap):** real, measured improvement, not yet a full pass.
Close range: "passes, clearly." Mid range: "passes, with a soft spot" (one
tower's cap reads as a chimney rather than a turret, but its castellated
neighbour still anchors the read). Long range: "does not confidently pass
on its own... reads just as plausibly as twin standing stones, dead trees,
or a broken obelisk pair." Per conventions.md's three-round cap, stopping
here rather than a fourth round — opened as the narrower
`R7.1-visual-remainder-2` in `BACKLOG.md`, the same pattern this file's own
R7.1-remainder entry already uses. Two smaller round-3 findings recorded
there instead of chased in this task: the north tower's cap shape, and the
terrain mound's hard material transition (existing `R7.1-remainder`
territory, not a new bug from this change).

**Confirmed not the same defect as R7.1-visual's own colour/value work**:
that job holds — the critic never once mentioned washing out or blending
into the sky/terrain at any of the three rounds' three distances. This
task was shape-language only, as scoped, and shape-language is what moved.

---

## R7.1-visual — blind-reviewed the signposts and stronghold silhouette, three rounds
`206fd77`, `c03c978`, `d73dd8f`, `5a22f78`, `581b351`, `d27fb49`, `3a22d00` on
`ralph/R7.1-visual`, all fast-forwarded to `main` (verified via `origin/main`'s
own log, not by trusting CI). `tests: none` per the backlog item's own field;
CI's standard import + Windows export ran clean on every push. New
`tools/capture_wayfinding.gd`: close-up viewpoints for exactly these two
features, since neither is what the fixed five-viewpoint `tools/survey.gd`
exists to frame (R7.1-found already caught its `03-rise-overlook` sitting 14m
from the same towers by coincidence).

R7.1 shipped these two features verified only by the shipping firing
rendering a frame and reading it itself. This ran them through the actual
blind critic three times, the cap `conventions.md` sets, fixing what each
round named:

**Round 1** (signpost: `ARM_SPACING` 0.5→0.75m and `ARM_START_HEIGHT`
2.2→2.9m — four billboarded labels were stacked close enough to be "fully
unreadable, reduced to fragments"; added a triangular-prism arrowhead per arm
and a light `outline_size`/`outline_modulate` on the label text, which had
none and vanished crossing dark backgrounds. **Silhouette:** the critic's
frames showed the towers reading correctly dark at ~40m but fading to a pale
grey nearly matching the horizon haze at ~60m and ~157m — confirmed by
re-rendering the same viewpoint with `WorldEnvironment.fog_enabled` forced
false, which restored the dark read. That is the shared fog
(`art.json`'s `aerial_perspective`, already tuned once against a documented
"fog eating the world" complaint) — retuning it globally for one landmark
needs the whole-survey re-verification R9.4 exists for, not a change buried
in this task. Switched `landmark.gd`'s tower material to an unshaded,
`fog_disabled` `ShaderMaterial` instead, so the silhouette stays a flat dark
shape regardless of distance or sun angle (this also removed a bright lit-
seam highlight the critic named on the near frame), and added a low base
drum under the four towers.

**Round 2:** the critic's strongest complaint was that a billboarded label
"floats... overlapping a diagonal wooden plank rather than sitting on it, so
plank and text disagree about angle and position," with an arrow shape
visibly overlapping letters in two labels — a real perspective artefact,
since a billboard always faces the camera regardless of the plank's true 3D
angle. Fixed the text to the arm's own orientation instead of billboarding;
it now reads correctly for someone standing at the post looking outward
along the arm, unreadable from behind, the same as a real signpost arm. A
first attempt at the needed rotation (`rotation.y = PI`) mirrored every
letter — caught before the next critic round by rendering and looking,
fixed by removing the extra flip (`Label3D`'s default non-billboard facing
was already correct).

**Round 3:** the critic caught two arms visually crossing in an X near the
post top, swallowing the apostrophe in "Grandpa's House" — every arm's
origin sat exactly on the post centreline, so from a viewing angle where two
opposite-ish bearings compress toward the same screen height their planks
radiate from what looks like one point. Fixed by mounting each arm around
the post's circumference at the golden angle (137.5°) per index — separate
mounting points around the pole, the way a real multi-arm signpost is built,
spreading any arm count evenly without hardcoding the route total. Verified
by re-rendering and looking directly (not a fourth critic round — the cap is
three, and this was a specific, well-understood geometry fix, not a fresh
unknown).

**What round 3 confirmed already fixed:** the silhouette holds a dark, solid
value at all three distances with "no z-fighting, texture stretching, or
mirrored-geometry bugs... anywhere on the silhouette" — the fog fix and the
round-1 material change both verified to hold under a genuinely blind pass.

**What is still open, by design rather than oversight:**
- **The stronghold towers read as "three standing stones" or "obelisks," not
  as a fortress** — round 3's own words: "no amount of repositioning,
  recoloring, or distance/fog adjustment on the current three prisms will
  make it read as fortified architecture." This needs new geometry (a
  connecting wall silhouette, varied massing, a roofline) — see the new
  `R7.1-visual-remainder` backlog entry. Not a config or placement fix, and
  not invented here.
- The hill's material inconsistency (green up close, tan/dirt at range) and
  bald-dune look from far away are the same already-tracked defects as
  `R7.1-found-2` (path-trench texture stretch) and `R7.1-remainder`
  (continuous ground cover) — the towers' hill happens to sit near both, not
  a new bug.
- One signpost arm is partly hidden behind foreground flowers in the main
  close-up frame; minor, and scene-dressing placement rather than the
  signpost itself, left for whoever next touches vegetation near the square.

## RB4-diagnostics — startup boot log for the Ally black-screen freeze
`9c08b6c` on `ralph/RB4`. `tests: none` (per the backlog item's own field;
this is a diagnostics-only change with no automated behaviour to assert).

**PARTIAL, by design — the backlog item's own two-part instruction.** RB4's
own text asks for two things in order: ship startup diagnostics regardless
of what else is found, then ask the owner for on-device data since nothing
else is actionable without it. This entry is the first half; the second half
is now `BLOCKED.md`'s "RB4 — ROG Ally black screen root cause needs
on-device data" entry.

New `scripts/boot/boot_log.gd`: a plain `RefCounted` with one static
`line(message)` that appends a timestamped line to `user://boot_log.txt`
(`%APPDATA%/Godot/app_userdata/Tetherbound/boot_log.txt` on the exported
Windows build — the same directory `user://settings.json` already writes to,
`D15`). Appends rather than truncates, with a `=== launch ... ===` marker
per process start: the freeze this chases leaves the process "Not
Responding" rather than crashing, so a killed-and-relaunched attempt must
not erase the stalled run it was trying to capture. Never fatal — a file
that fails to open just drops the line.

Called from `autoload/game_state.gd`'s `_ready()` (autoload boot, first and
last lines) and `scripts/world/playground_world.gd`'s `_ready()` at every
major phase: terrain node created, terrain `data_directory` assigned,
ground shader applied, player placed, vegetation scattered, settlement
built, and first frame presented after the closing `await
get_tree().process_frame`.

Verified by actually running it, not just reading the code: fetched Godot
4.7 (`tools/art_pipeline/setup.sh godot`), installed `libegl1`/
`libegl-mesa0`/`mesa-vulkan-drivers`, ran a clean `--headless --import` (no
errors; `boot_log.gd.uid` auto-generated the same way every other script's
does), then `tests/smoke_playground.gd` — the smoke test's own assertions
passed, and the real log file it produced
(`~/.local/share/godot/app_userdata/Tetherbound/boot_log.txt`, the Linux
equivalent path) showed one clean timestamped line per phase in the right
order, confirming the writer works end to end rather than just compiling.

Next step is on the owner: the boot log's last line from an actual frozen
Ally run, plus Task Manager CPU/GPU state, whether it ever resolves, and
windowed-vs-fullscreen — see `BLOCKED.md` for the full ask.

---

## R7.1-remainder — PARTIAL: the olive/lime ground seam fixed; world-ends-40m and continuous ground cover still open
`505a8f8` + `a049579` (bookkeeping) on `ralph/R7.1-remainder`, fast-forwarded
to `main` (`origin/main` moved `0f1b491..a049579`) — verified via `main`'s own
commit log and by fetching `origin/main` directly, not by trusting CI.
`tests: smoke_traversal` — 3 consecutive clean runs locally, and green again
in CI's `verify-core` job on the actual shipped commit.

**Root cause, found by rendering (not reasoning from the code):**
`tools/survey.gd`'s `01-spawn-outward` and `05-spawn-low-sun` viewpoints (near
the flattened spawn pad, an ordinary hillside boundary) showed a saturated,
zero-blue-channel green stripe against a dark marbled field — R7.1's own
investigation only ever rendered `03-rise-overlook`, whose eye sits ON the
ridge silhouette's rise and is already past whatever the bug's threshold is
either way, so the seam never showed there. Confirmed live, by dumping
`Terrain3DMaterial`'s and `Terrain3DTextureAsset`'s own property lists:
`auto_shader` picks the base/overlay texture by slope at a threshold this
Terrain3D build exposes **no control over anywhere reachable from script** —
no `auto_slope` property, no per-texture slope/height range. On this
terrain's rolling-hills noise that threshold sits low enough that almost the
whole map read as the overlay (rock) texture, with only near-flat ground
reading as the base (grass) texture.

**Fix:** `build_playground_terrain.gd` now paints the REAL control map at
bake time (`_paint_control_map`), per pixel, with the same three-tier
grass/soil/rock slope thresholds already authored for the colour map
(`_ground_colour`) — `auto` off per pixel instead of left on Terrain3D's
opaque built-in cutover. Soil is a real texture in play for the first time.
Verified by rebaking and re-rendering all five survey viewpoints: the seam is
gone in every one, including `03-rise-overlook`.

**New process followed, owner directive 2026-08-10 (`conventions.md`,
"Visual-affecting work needs a blind pass"):** ran `.claude/skills/visual-
judge` blind against the post-fix survey before calling this done. The critic
was told nothing about what changed. It did **not** flag the olive/lime seam
at all — corroborating the fix — but named a new, separate defect: the
authored path trench's steep banks read as "a broken decal" from texture
stretching on a near-vertical face, present before this fix too (pre-existing
geometry, not introduced by the control-map change). Logged as
`R7.1-found-2` rather than chased in this same task, per the new rule's own
"up to three rounds, then hand back" — this was round one, on a defect
outside the ground-seam's own scope.

**Also queried directly, not asserted:** `RULES.all_placements()` genuinely
spreads every vegetation layer to the 512m world edge (`trees`: 102/178
instances beyond 200m from origin, none inside 40m) — "the world ends 40m
out" is real but narrower than it sounds; the pale hills filling most distant
frames are `world_background = NOISE`, Terrain3D's own procedural
continuation past the baked region, which cannot carry props by construction.
Rewrote `BACKLOG.md`'s R7.1-remainder entry with this finding rather than
leaving the original framing standing.

**Not attempted this pass:** world-ends-40m-out's real fix (biasing clumps
toward ridgelines the camera actually silhouettes against) and continuous
ground cover (re-tuning grass/drygrass density or scale against the now-fixed
ground texture) — both left as `BACKLOG.md`'s (slimmer) R7.1-remainder entry.

**Process note for whoever reads `ralph-status` history:** this task's own
branch got rebased mid-firing when a separate session's `0f1b491` (CI split,
visual-gating rule, lease-safety fixes) landed on `main` first. The rebase and
force-push were correct and the resulting CI run genuinely re-verified
everything (confirmed by reading its actual job list, not just its green
conclusion) — a `ralph/R7.1-remainder-v2` branch was cut from `main` out of an
initially-mistaken worry that the force-push's CI diff had skipped
verification; it hadn't (the rebase pulled in `0f1b491`'s own large diff,
`.github/workflows/ci.yml` included, which alone is enough to mark the push
code-bearing). `v2` is now redundant and will show a failed `ralph-merge` run
once its own CI completes (its commit isn't an ancestor of the `main` that
already shipped via the original branch) — that failure is expected, not a
bug; nothing further to do with `ralph/R7.1-remainder-v2`.

## R7.1 — Wayfinding polish, PARTIAL: signposts and the ridge silhouette shipped
`3213f7a` on `ralph/R7.1` (fast-forwarded to `main`, verified via `main`'s own
commit log: `origin/main` moved `966c1cb..3213f7a`). `tests: smoke_traversal`
— 3 consecutive clean runs, given the test's own flake history.

Two of R7.1's five bullets, not all five — the rest are still on `BACKLOG.md`
under a new R7.1-remainder entry rather than silently dropped:

- **Signposts at the village square** (`scripts/world/signpost.gd`): one
  billboarded-label arm per `data/config/terrain_playground.json`
  `paths.routes` entry, built from that route data itself (a `label` field
  added to each route) so a new destination gets a sign arm for free. Post
  placed a few metres off the well, which already stands at the routes'
  shared origin `[10,-10]`.
- **The stronghold silhouette on the ridge** (`scripts/world/landmark.gd`):
  four dark angular placeholder towers on the rise at `[140,-90]` — the M7
  "distant landmark" the site-frames critique named directly. Placeholder
  geometry, matching `CLAUDE.md`'s allowance for that; the real stronghold
  approach and presentation are R8.2's job once Meadows is further along.

Both verified by rendering close-up frames (a custom throwaway camera
script, not committed), not just by reading the code — the labels were
initially unreadable, overlapping head-on due to billboard behaviour, and
that only showed up in a render.

**Also fixed, found while chasing the ground-seam bullet**: confirmed by
instantiating a live `Terrain3DMaterial` and reading its own
`_get_shader_parameters()` that `world_noise_scale/height/region_blend/
lod_distance/max_octaves/min_octaves` and `auto_slope`/`auto_height_reduction`
are not real uniform names on this Terrain3D build (removed from
`terrain_playground.json`, finding recorded in place — same precedent as the
existing `_comment_dual_scale_removed`). Separately, `macro_variation1/2`,
`noise1_scale`, `noise2_scale`, `noise1_angle`, `blend_sharpness` and
`mipmap_bias` **are** real and **do** apply — forcing extreme values visibly
changed the render — even though `get_shader_param()` reads all of them back
as `null` after every `set_shader_param()` call. `_apply_ground_shader`'s
"ignored N settings" warning was trusting that broken readback and had been
false-flagging those seven as dead for as long as the config carried them.
Fixed to check `_get_shader_parameters()`'s real key list instead of the
unreliable readback. `enable_macro_variation` — present in intent via
`macro_variation1/2` for two rounds of tuning but never actually set `true`
— is now on.

**What did NOT get fixed: the seam itself.** Widening the bake-time
slope-colour blend (`colour.blend_deg` 7→18) and raising the soil/rock
slope thresholds, then doing a full terrain rebake, produced no visible
change on the one viewpoint tested — and that viewpoint turned out to be
standing on the rise itself, whose slope was already well past both the
old and new `rock_slope_deg` either way, so the test never touched an
ordinary hillside actually misclassifying. Reverted rather than shipped as
an unverified guess. **Continuous ground cover** (grass still reads as
isolated tufts) and **populating the mid/far distance bands** more broadly
are also still open. See `BACKLOG.md`'s R7.1-remainder entry.

## RB3 — Fix `tests/smoke_aggression.gd`'s intermittent flake
`0a11b5c` on `ralph/RB3`. `tests: smoke_aggression` — 36 consecutive clean
runs after the fix, reproduced against a ~40% failure rate before it using
the same frame-by-frame instrumentation, per `ralph/conventions.md`'s
instruction not to trust a single green run.

Not an aggression-logic bug, a pathing regression, or the rocky rise's
geometry — all three were live hypotheses in `BACKLOG.md` and all three were
wrong. The real cause, found by actually running the test dozens of times
with position/velocity logging rather than reading the code: the trainer's
own `AllyPal` (`follower_pal.gd`) stops closing the gap once inside
`_stop_distance` (3.0m) with no awareness of which side of the trainer it
ended up on. The test's peaceful half walks toward Bramblebun, then the
aggressive half immediately reverses toward Galecrest — so the pal trailing
behind on the first leg is standing squarely in the trainer's path on the
second, and two solid `CharacterBody3D` capsules aimed straight at each
other simply stop dead (velocity pinned at exactly `(0,0,0)` for the rest of
the walk budget, confirmed over multiple repro runs). Nothing about this is
test-specific: any player who turns around with their pal in tow can hit the
same wall in real play.

Fix: `follower_pal.gd`'s `set_following()` takes the ally off every physics
layer while it is following (peaceful exploration), so it can never block
the trainer, and restores normal collision the instant combat takes over.
Scoped to the following state specifically, not the body's whole lifetime —
tried the wider version first (collision off permanently) and it silently
broke `smoke_catching.gd` ("the pal moved 4.04m on the stick while aiming"),
because `wild_pal.gd`'s `_spaced_config()` keeps fighters apart by real
collision, not distance math alone. Re-ran `smoke_combat` and
`smoke_catching` by hand after narrowing the fix; both green.

## R5.1 — Day/night cycle
`e4a0fb5` on `ralph/R5.1` (fast-forwarded to `main`, verified via `main`'s
commit log and CI: run 31366654851 on `ralph/R5.1` went green, Release +
Ralph auto-merge both succeeded at `e4a0fb5`). `tests: test_day_cycle` (new).

`world_look.gd` had a full named-preset time-of-day system since the
overhaul, but nothing ever called `apply_time()` after `_ready()` — noon,
forever, and `grandpa_road`'s "make camp before dark" line had nothing
behind it. Both 2026-08-09 blind reviews named this a top-three gap.

`scripts/world/day_cycle.gd` (new, pure-logic `RefCounted`, pinned by
`tests/test_day_cycle.gd` per D02): elapsed real seconds → hour of day →
which named `art.json` preset is due, and `is_dark(hour)`. `art.json`: day/
golden now carry an hour (8/18), plus a new night preset (procedural-
gradient sky, moonlight-strength sun) and tunable `day_length_seconds`/
`dark_from_hour`/`dark_to_hour`. `world_look.gd`'s `_process()` advances the
clock and snaps to whichever preset is due; `apply_time()` now also resyncs
the internal clock to the hour it just applied, or `tools/survey.gd` picking
a time by name for a screenshot would be silently undone by the very next
tick. `camp.gd`: rest also resets the clock to morning.

Verified beyond the named test: full suite (297 tests) green through the
headless SceneTree runner, and `tests/smoke_free_build.gd` (plants a real
camp, rests through it) green end to end — "[camp] rested; day 2". One real
bug caught before shipping, not by a test (nothing here is scene-testable
per D02): `apply_time()` needed the clock resync described above.

Took two rebases to land: `main` moved twice underneath it (VP2's docs
commit, then RB3's) before `ralph/R5.1`'s CI finished. Verify the ship by
looking at `main`, never at a single CI result, when that happens.

Deliberately not done, out of scope: no gameplay effects from darkness
(nocturnal spawn gating is R5.3's task, per D20).

## VP2 — Fix `tools/preview_creatures.gd` rendering zero creatures
`ce6205d` on `ralph/VP2` (fast-forwarded to `main`, verified via `main`'s
commit log and CI: Release + Ralph auto-merge both green at `ce6205d`).
`tests: none` (as named on the backlog item).

Three real bugs, all found by actually running the tool under Godot 4.7
headless, not by reading the code:
1. `BODY.new()` built a bare `CharacterBody3D` instead of instantiating
   `scenes/pals/pal.tscn`, so every `@onready` child lookup
   (`$Collision`/`$Model`/`$Body`/`$Head`) failed silently. Fixed by
   instantiating `pal.tscn` and attaching the script before `add_child()`,
   matching `encounter_director.gd`'s own pattern.
2. Once building succeeded, `setup()`'s `is_inside_tree()` guard was still
   false through `_init()`'s whole synchronous burst. Fixed with one
   `await process_frame` before building anything — the same quirk
   `render_bounds.gd`'s header already names for `global_transform`.
3. With both fixed, models still didn't render: every body is a
   `CharacterBody3D` and the preview card has no floor collider, so
   gravity dropped each one out of frame over the 120-physics-frame wait
   before the screenshot. Fixed with `set_physics_process(false)` right
   after `setup()`.

Verified by looking at the actual rendered PNG: all 17 species visible at
their gameplay heights beside the trainer-height bars, zero engine errors.

This closes out the mechanical half of Phase -0.5's tooling debt — the
tool built to catch cross-species scale errors now works, ahead of R5.1/
R7.1/R7.2/R9.4 which need it.

## VP1 — Fix `tools/survey.gd`'s stale viewpoints
`153f802` on `ralph/VP1`. `tests: none` (as named on the backlog item).
Verified by actually running
`tools/survey.sh` against the live world (Godot 4.7-stable fetched fresh via
`tools/art_pipeline/setup.sh godot`, `libegl1`/`mesa-vulkan-drivers`
installed, import cache built) and inspecting all five rendered frames —
not just asserting the fix.

**Both bugs' real causes turned out to be different from what the backlog
entry and the 2026-08-09 review guessed, found by instrumenting the actual
running scene rather than reasoning from the code:**

- **01/05** ("renders the farmhouse interior"): not the farmhouse. The
  overhaul (D18) placed `village.json`'s Barn at world `(2, 2)` — 2.8m from
  an eye sitting at `(0, 0)` and lying almost exactly on the old
  `(150, 120)` target line (perpendicular distance 0.31m). The camera was
  nose-against the barn wall, rendering its unlit inside. Confirmed by
  dumping every Node3D within 30m of the eye position and reading off
  `Barn_Collision` at `(2, 2, 2)`. Fixed by moving the eye to `(-9, -7)`
  (nearest structure now 14m+ away) and re-aiming at the pond-valley path
  instead of back through the village.
- **03/04** ("camera embedded in terrain, stale heightfield"): the
  heightfield was never stale — `ground_height_at()` (the real baked
  Terrain3D query) and `playground_heightfield.gd`'s pure recomputation
  matched exactly (diff 0.00) at every point checked, including both
  viewpoints' eye and peak coordinates. The real bug: `_place_actor()`'s
  fallback for viewpoints with no `actor` key parked the player at a fixed
  `(9000, 200, 9000)`, nowhere near the baked 512m world. That silently
  broke Terrain3D's own mesh streaming for the whole scene, not just around
  the player — proven by re-rendering 03 and 04 with their *original*,
  unchanged eye/target/horizon and only the player left near the camera
  instead: both rendered correctly, real ground and all. Fixed by parking
  the player 500m straight down from the eye's own XZ instead — inside the
  region Terrain3D is already streaming for that shot, and far enough below
  ground to stay out of every authored frame. No coordinate changes were
  needed for 03 or 04 themselves.

All five frames now render real geometry (`_flatness` spread 1.41-1.57
across the board, comfortably above the 0.01 failure floor) and were
visually confirmed by eye, not just by the spread check. `tools/survey.sh`
exits clean with no `FAIL:` lines.

Next firing on `R9.4`/anything that re-runs the survey: the fix is in
`_place_actor()` itself, so any future viewpoint added without an `actor`
key is safe by default — no per-viewpoint parking logic needed.

## RB1 — Mouse look does not work
`1eeb4c1` on `ralph/RB1`. `tests: smoke_menu, smoke_opening` (no `tests:`
field was named on the backlog item; these were the two smoke tests that
already exercise `Input.mouse_mode` end to end, so they were the closest
thing to a relevant regression suite).

**Diagnosis, confirmed by reading the code (not by reproducing the bug —
that needs real Windows, see below):** `playground_world.gd`'s `_ready()`
set `Input.mouse_mode = MOUSE_MODE_CAPTURED` exactly once, unconditionally,
at the end of boot, and nothing ever re-asserted it. That is a known Godot/
Windows gotcha: a capture request made before the native window has
actually received OS input focus can be silently dropped — `Input.mouse_mode`
still reads back CAPTURED, so nothing downstream (including a test) can
tell the difference, but the cursor is never really confined and
`camera_rig.gd`'s `_unhandled_input` (which only turns mouse motion into
look when `Input.mouse_mode == MOUSE_MODE_CAPTURED`) never receives real
deltas. That matches the owner's report exactly: everything else worked,
mouse look did not, from the first frame.

**Fix:** `playground_world.gd` now connects to `Window.focus_entered` and
re-asserts capture on every focus gain (boot included), through a new
`_capture_mouse_if_free()` that backs off via `_mouse_wanted_elsewhere()`
whenever the pause menu, the dialogue panel or the naming prompt currently
owns the mouse — so a focus regain while one of those is open cannot yank
the cursor out from under it. This is additive: the original unconditional
boot-time call still happens (nothing was open yet), so no existing
behaviour changed; the new path is the retry on every subsequent focus
event, which is exactly the moment a dropped boot-time capture needs one.

**The Grandpa-interact report, checked as the item asked:**
`interaction_arbiter.gd` is purely proximity + button (`interaction_offer`
by distance, `Input.is_action_just_pressed("interact")`) — nothing in it
reads `Input.mouse_mode` at all, and `smoke_opening.gd`'s beat 3 (talking to
Grandpa) passes headless, so the arbiter's own logic is sound when the
player can reach him. The most likely explanation, not a confirmed one: if
the owner was playing mouse+keyboard with the camera stuck at its spawn
yaw, they may simply have been unable to turn toward Grandpa to get in
range — a symptom of RB1, not a second bug. Left unfixed on purpose: there
is no independent diagnosis to fix, and inventing one without evidence is
exactly what this loop is told not to do. Worth the owner specifically
re-checking after this fix, before anyone spends more time on it.

**What is NOT proven, and cannot be from here:** whether real OS-level
mouse capture actually happens on an exported Windows build. Per
`smoke_menu.gd`'s own long-standing note, the dummy `DisplayServer` under
`--headless` reports `Input.mouse_mode` as VISIBLE no matter what is
requested — it cannot even confirm the *original* boot-time capture landed,
let alone this fix's retry path. `smoke_menu.gd` gained a new check
(`_check_focus_recapture_respects_open_ui`) that proves what headless CAN
prove: `Window.focus_entered` is genuinely connected to the recapture
method, and `_mouse_wanted_elsewhere()` correctly tracks the menu's open/
closed state. Both `smoke_menu` and `smoke_opening` ran clean locally (Godot
4.7-stable, fresh import cache). **This item is not closed until the owner
confirms on the actual Windows build** that the mouse turns the camera from
the first frame, through menu open/close and the name-entry screen, and
stays captured — recorded here rather than claimed as tested coverage that
does not exist.

---

## RB2 — Player has no walk/run animation
`<pending>` on `ralph/RB2`. `tests: smoke_input` (extended to assert the
loop mode, not just that position changed).

**Superseded below.** This item was first marked "verified already fixed, no
code change needed" earlier in this same firing, on the strength of
`current_animation`/bone-delta checks and log traces alone. The owner played
the actual build, saw the animation was NOT there, and said so plainly: fix
it for real, don't just read the code. That correction was right — the
verification had a real hole in it (see below) and there was a real bug.
Leaving the wrong conclusion in place rather than retracting it would make
this log untrustworthy, so it stays, corrected in the open rather than
quietly edited away.

**The actual bug, found by getting real screenshots instead of trusting
`current_animation`:** every clip `tools/art_pipeline`'s `animate_humanoid.py`
bakes into a humanoid `.glb` ships with `Animation.loop_mode = LOOP_NONE` —
confirmed by loading `trainer_lod0.glb` directly and reading it off the
resource (idle, walk, sprint, jump, throw: all `LOOP_NONE`). `pal_animator.gd`
already knew to work around this for creatures — its `_play()` sets
`animation.loop_mode` on every call, per clip, based on whether the role is a
loop or a one-shot. `scripts/characters/character_model.gd`'s `play()` (the
equivalent for the trainer, Grandpa and the Warden) never did. Between them:
`play("walk")` plays the 1.38s clip once, then sits on `_current == "walk"`
and never calls `_anim.play()` again for as long as the trainer keeps
walking, because the guard that makes cross-fades not stutter (`clip ==
_current`) also silently swallows every repeat call a continuous state makes.
The clip is real, resolves, drives real bones, and the calling code asks for
it every frame exactly as it should — and the character still freezes after
1.38 seconds, because nothing ever told the `Animation` resource to loop.

**Why the earlier verification missed it:** `current_animation` still reads
back `"walk"` after the clip stops (Godot doesn't clear it), so a check that
only reads the animation NAME sees exactly what a correctly-looping walk
would report. Bone-delta checks against the raw `.glb` in isolation (
`tools/diag_animation_moves.gd`) sample fixed points across the clip's own
declared length and never hold past it, so they cannot see a clip that plays
once and then stops on its own final frame. Only watching real rendered
frames well past the clip's length — or reading `Animation.loop_mode`
directly — shows it.

**Fix:** `character_model.play()` now takes a `looping: bool = true` and sets
`Animation.loop_mode` (`LOOP_LINEAR` / `LOOP_NONE`) before calling
`_anim.play()`, the same pattern `pal_animator.gd` already used.
`trainer_model.gd` passes `looping = false` only while `_throwing_for > 0`
(the one genuinely committed one-shot on the trainer); idle/walk/sprint/jump
all loop by default. `npc_body.gd` (Grandpa's idle) gets this for free
through the same default — his 4.04s idle was freezing too, just slowly
enough that nobody had reported it yet.

**Verified for real this time:**
- `tests/smoke_input.gd` now asserts, the instant `current_animation` first
  reports `"walk"` during a held `move_right`, that
  `AnimationPlayer.get_animation("walk").loop_mode == Animation.LOOP_LINEAR`.
  Confirmed failing against the pre-fix code (`loop_mode == LOOP_NONE`,
  0) and passing after.
- A direct resource check (`loop_mode` read off `trainer_lod0.glb`'s
  `AnimationPlayer` with no game code involved) confirms all 5 clips were
  `LOOP_NONE` before, matching the bug exactly.
- Real rendered screenshots (`xvfb-run` + `--rendering-driver opengl3`,
  properly synced this time with `process_frame` × N + `RenderingServer.
  frame_post_draw` before reading the viewport texture — the fix for the
  black-PNG problem the first verification attempt hit and didn't resolve)
  show the trainer's legs in genuinely different poses between the start and
  a few frames later into a held walk, where the pre-fix code would have
  shown the identical frozen pose both times.

**Found along the way, not chased (out of scope for this item):** with
`SequenceDirector` disabled, `move_forward` from the raw scene's fallback
spawn point (`playground_world.gd`'s `(0, 2.6, 0)`, used only before the
opening's own beats reposition the player into the house) stalls after
~1.2m over a 90-frame hold, while `move_right` from the same point covers
5.85m in the same window (`tests/smoke_input.gd`'s own numbers, unchanged
by this firing). Very likely just scatter/vegetation collision sitting
directly in the +Z direction from world origin, and the real opening never
uses that raw spawn point for free movement — but worth a look if a future
firing sees anything move-forward-shaped acting strange near boot.

---

## R0.8.5 — Full blind visual review pass, against the overhauled build
`216ce54` (review + backlog updates) on `ralph/R0.8.5`, on top of `d318a55`
(incidental missing .uid/.import sidecars from this container's first-ever
import pass — same class of fix as R0.3.5's). No tests named for this item;
CI is import + Windows export only.

One complete current-state record: the five fixed meadow viewpoints, five
staged site frames, and serial Blender turntables (four angles each) for
the trainer, Grandpa, the Warden and all seventeen pal species, judged by a
blind sub-agent per `.claude/skills/visual-judge` with no knowledge of what
changed. Full write-up: `docs/reviews/2026-08-09-r0.8.5-full-blind-review.md`.
Both bar questions came back no — top separators: no landmark in any
outdoor frame, the trainer/Warden art-pipeline gap, and flat lighting with
no time-of-day read.

What the next firing should know, all recorded in `BACKLOG.md`/`BLOCKED.md`
in more detail:
- Two real bugs found in the review harness itself (not the game):
  `survey.gd`'s viewpoints 01/05 render the farmhouse interior instead of
  the meadow, 03/04 render as if the camera is embedded in the terrain.
  `preview_creatures.gd` renders zero creatures (bypasses `pal.tscn`). Both
  are backlog items now, not fixed here.
- **Tuskroot is not still the songbird placeholder** — R4.5's backlog text
  was stale; corrected, needs `smoke_art` verification to close properly.
- Creature/human art-pipeline cohesion (Paddlenewt/Pipwing/Ripplet vs. the
  rest; trainer/Grandpa vs. the Warden) logged as a design question in
  `BLOCKED.md` — rework vs. replace is the owner's call, not invented here.

## R0.9 — Assembled the opening into the real scene. Phase 0 is done.
`6b8b572` (wiring + three opening-flow bugs) and `9dd8e38` (two more test
fixes CI caught after the first push) on `ralph/R0.9`. Both confirmed
merged by fetching `main` directly — `a414da7..9dd8e38` fast-forwarded.

Added `SequenceDirector`, `InteractionArbiter`, `DialoguePanel` and
`NamePrompt` to `scenes/world/meadows_playground.tscn` as children of the
world root, wiring the director's seven NodePath exports. Per the task's
own instructions: the arbiter's `player_path` was left unset (the
director calls `set_player()` itself once the tree is up), and neither
Grandpa nor the starters were placed in the scene (the director spawns
them from `opening.json`).

Five real bugs surfaced once the scene was genuinely wired and testable
for the first time — none were new; all were latent, waiting for the
first end-to-end run:

1. **Starter-vs-player collision blocked the walk to Grandpa.** The
   middle starter always sits on the dead-straight line from spawn to
   Grandpa (`starter_offsets()` centres the row on his facing, and that
   line *is* the approach). Sharing the default collision layer meant the
   player mounted its capsule and stopped short. Fixed by giving the
   opening's three temporary display bodies their own collision layer in
   `sequence_director.gd` — the real follower pal built later by
   `adopt_starter()` is a different instance with the ordinary setup.
2. **`smoke_opening.gd`'s own walk stopped on raw distance**, but the
   three starters' 2.6m radii overlap on purpose (3.5m spread), so a
   straight walk at an off-centre one could still leave a centred
   neighbour "winning" arbitration. Now requires proximity AND an actual
   arbitration win, matching what a real player experiences.
3. **`encounter_director.gd:186` wrote the chosen nickname to
   `display_name` instead of `nickname`** — the same bug already fixed
   once in `party_seam.gd`. `pal_instance.label()` reads `nickname` first,
   so this permanently lost the species name. This was already recorded
   in `BACKLOG.md`'s "found along the way" list; removed from there now.
4. **`smoke_combat.gd` assumed a default sandbox starter** that no longer
   spawns — `SequenceDirector`'s `_ready()` now unconditionally suspends
   it, since the opening is always in the scene. Fixed by having the test
   adopt a starter directly, the same call the opening itself makes.
5. **`combat_manager.gd`'s `_stand_the_trainer_aside()` teleported the
   trainer with a raw Y** carried from the arena's own centre instead of
   asking the world for ground height (violates `D09`). On ground uneven
   enough for the difference to clear collision, the trainer fell through
   the terrain forever. Only exposed once fix 4 shifted the engagement
   geometry. Fixed with a `_ground_height()` helper mirroring
   `pal_body.gd`'s pattern.

Bug 4's fix broke two more tests that share the same scene and the same
assumption — `smoke_catching.gd` and `smoke_aggression.gd` — caught by
real CI on the first push (`6b8b572` went red), not locally beforehand.
Both got the identical `_ensure_ally()` fix and shipped in the follow-up
commit (`9dd8e38`). **Lesson for next time a shared-scene change lands:
check every consumer of that scene, not just the task's own named test**
— `smoke_menu.gd`, `smoke_settings.gd` and `smoke_free_build.gd` were
also checked this time and confirmed unaffected.

Verified: `tests/smoke_opening.gd` passes end to end (walk, talk to
Grandpa, choose and name a starter, the pal reaches the real party).
`tests/smoke_combat.gd`, `smoke_catching.gd`, `smoke_aggression.gd`,
`smoke_menu.gd`, `smoke_settings.gd`, `smoke_free_build.gd` and the full
277-test suite (0 failed) all still pass. Real CI on `9dd8e38` green
end to end including the Windows export
(run 31318155566).

`EncounterDirector.WILD_SPAWNS` still spawns an aggressive Tuskroot that
can charge the player mid-opening, per the task's own note to decide and
say so: left as-is. `smoke_opening.gd` passing with it present confirms
it does not block the scripted flow, and an aggressive pal in the meadow
during the opening is consistent with `GAME_DESIGN.md` §14's own rule
that aggression is not gated on story state elsewhere in the game.

**Phase 0 — finish the roster is now complete.** R0.6, R0.7, R0.8 and
R0.9 are all done. The next item, R0.10, is a `▶` play gate: the owner
plays the first fifteen minutes themselves. The loop stops there, per
`ralph/PROMPT.md`.

## R0.6 — finished Reedwing (fourth and last bird species). R0.6 is complete.
`6c14a65` (shipped as `ralph/R0.6-reedwing-v2`, cherry-picked from the
original `ralph/R0.6-reedwing`'s `f97824a` after a base-mismatch — see
below). Same `clean → texture → rig --kind bird → grade → install`
sequence, no code changes needed for the fourth time running. Candidate a
(R0.4 winner), no hard-fail defect — only a minor neck-proportion note.

`rig_report.json`: 19 bones, 14,006 vertices, **0 unweighted**, idle
motion at 88% of walk. Five eye-guard rectangles added to `grade.py` —
Reedwing's eyes read differently from the other three birds: a dark
pupil-only mass with a soft catchlight rather than a bright iris ring,
consistent with a waterfowl's eye rather than a raptor's or owl's. A dark
beak-tip wedge and a glossy neck-feather specular highlight were checked
and rejected as non-eyes.

Verified in Godot: `smoke_art.gd` passes, and the standalone height-fit
script confirms the rendered model matches the declared 1.65m exactly
(R0.7's fixed figure), no footprint clamp, all six clips present.

`species.json`: filed `type: water` per R0.7's explicit instruction
(canonically Water/Air per `docs/art/wild/21_MEADOWS_WILD_ROSTER_CANON.md`,
but the schema takes one type) — worth restating plainly since it would
be easy to mistake the gameplay `type` field for the rig kind: Reedwing
is still a physical bird and `--kind bird` was correct regardless.
`aggressive: false`, moderate HP/attack/defence matching its "Swift
Glider & Messenger... support, utility" role per the Water Sheet — a
support creature like Brooktail, not a fighter.

**Second branch base-mismatch caught and fixed this session, same shape
as the Galecrest incident earlier:** `ralph/R0.6-reedwing` was branched
from what was believed to be current `main`, but `ralph/R0.6-flake-note`
(a sibling branch, docs-only) had merged moments earlier without a fresh
`git fetch` immediately before branching — `git merge-base --is-ancestor
origin/main ralph/R0.6-reedwing` confirmed the fast-forward would fail
before wasting a ~9-minute CI cycle finding out the hard way. Fixed by
cutting `ralph/R0.6-reedwing-v2` from the actually-current `main` and
cherry-picking the same commit (`f97824a` → `6c14a65`) rather than
force-pushing. The original `ralph/R0.6-reedwing` is abandoned, same as
the earlier `ralph/R0.6-bird-animation-fix-record` — harmless, cannot be
deleted from this session, safe to ignore. **Lesson restated plainly for
future firings: `git fetch origin main` immediately before creating any
branch pushed within a few minutes of a sibling branch, not "recently".**

Credit balance after this species' texture pass: **175** (was 185,
confirmed via `meshy.py check`).

**R0.6 is complete.** All twelve wild species plus the three starters now
have real production art (Tuskroot's evolved-form model remains the one
stand-in, tracked separately from R0.6's own scope). Nine species shipped
in this session alone: Burrowback, Paddlenewt, Mosshell, Brooktail,
Galecrest, Duskhush, Pipwing, Reedwing, plus the `finish.py` bird-rig fix
that unblocked the last four.

CI green, fast-forwarded to `main` at `6c14a65` — verified by fetching
`origin/main` directly; branch auto-deleted post-merge.

## R0.6 — finished Pipwing (third bird species)
`babd64f` · Same `clean → texture → rig --kind bird → grade → install`
sequence, no code changes needed for the third time running. Candidate b
(R0.4 winner), no hard-fail defect — only a cosmetic thin/blade-like
crest note.

`rig_report.json`: 19 bones, 14,002 vertices, **0 unweighted**, idle
motion at 86% of walk (well clear of the frozen threshold). Four
eye-guard rectangles added to `grade.py` — Pipwing's own "oversized teal
eyes" are large enough relative to its tiny body that they dominate
several UV islands, the strongest signature of any species yet alongside
Duskhush's. One ambiguous dark shape right beside a confirmed eye was
checked and rejected as a likely shading/seam artifact rather than a
separate instance, same caution used on every prior species.

Verified in Godot: `smoke_art.gd` passes, and the standalone height-fit
script confirms the rendered model matches the declared 1.20m exactly —
R0.7's fixed figure, the shortest in the roster — no footprint clamp, all
six clips present.

`species.json`: `aggressive: false` (Zippy Flier/Spotter, not a fighter);
lowest HP (78) and defence (10) of the wild roster so far — deliberately
fragile, matching "tiny and round" — with catch rate (0.5) set just under
Bramblebun's tutorial-only 0.55 so the tutorial creature keeps the
highest rate in the game.

Credit balance after this species' texture pass: **185** (was 195,
confirmed via `meshy.py check`).

CI green, fast-forwarded to `main` at `babd64f` — verified by fetching
`origin/main` directly; branch auto-deleted post-merge.

## R0.6 — finished Duskhush (second bird species)
`a9d9282` · Same `clean → texture → rig --kind bird → grade → install`
sequence proved on Galecrest, no new code needed — the finish.py fix from
last firing just worked. Candidate a (R0.4 winner), no hard-fail defect,
only a cosmetic brow-ridge note in the production report.

`rig_report.json`: 19 bones, 14,006 vertices, **0 unweighted** — cleaner
than Galecrest's 6/14,004. Idle motion at 65% of walk (well clear of the
6%-is-frozen threshold `rig_bird.py` flags in its own self-check). Four
eye-guard rectangles added to `grade.py`: the clearest eye signature of
any species so far — a gold outer ring, a blue/teal inner ring, a black
pupil and a white catchlight, matching the Air Sheet's own "large
gold-ringed eyes" brief and unmistakable against the grey-blue plumage.
One dark round blob near a nostril was checked and rejected (no ring, no
catchlight).

Verified in Godot: `smoke_art.gd` passes, and a standalone script
(instantiating `pal.tscn` with `wild_pal.gd`, replicating `smoke_art.gd`'s
`_rendered_height()`) confirms the rendered model matches the declared
1.55m exactly (R0.7's fixed figure — checked before writing the number,
learning from Galecrest's mistake), no footprint clamp, all six clips
present.

`species.json`: `aggressive: false` — the sheet frames Duskhush as
"Silent Watcher & Night Scout", a stealth/observation role, not a striker
like Galecrest. Lowest attack of the air roster so far; defence and HP
sit closer together than Galecrest's spread. `footprint_allowance` reused
Galewisp's 3.4 (same height, similarly-proportioned owl/fox-bird build)
rather than Galecrest's 4.2 (a bigger hawk with a wider wingspan).

Credit balance after this species' texture pass: **195** (was 205,
confirmed via `meshy.py check`, not assumed).

CI green, fast-forwarded to `main` at `a9d9282` — verified by fetching
`origin/main` directly; the branch was auto-deleted post-merge, confirming
the fast-forward actually happened rather than just going green.

## R0.6 — fixed the bird-animation blocker, shipped Galecrest (first bird species)
`400f749`, `4d078e2` · Investigated the "R0.6's four remaining species need
`animate_bird.py`" blocker properly before writing anything, by reading
`animate_quadruped.py` and `rig_bird.py` (1546 lines) in full. Discovery:
`rig_bird.py` is not a bare rigging script the way `rig_quadruped.py`/
`rig_glider.py`/`rig_sitter.py` are — it authors all six standard clips
itself (`author_all()`), already proved end-to-end on three winged test
meshes per its own docstring, and its bone names deliberately overlap
`animate_quadruped.py`'s glider layout "so that script still produces
something sane if it is ever pointed at a bird." The real bug was in
`finish.py`'s `rig` subcommand: it called `animate_quadruped.py`
unconditionally after rigging, regardless of `--kind`. For a bird this
would have silently re-detected the already-animated rig as a glider and
overwritten `rig_bird.py`'s bird-specific animation with generic glider
animation, including `animate_quadruped.py`'s documented faint-spin bug
(root-bone yaw applied where the rig's local Y is world-up, so the
creature spins on the spot instead of toppling). **No new script was
needed** — `finish.py` now skips the `animate_quadruped.py` call when
`--kind` is `bird`.

Proved by running Galecrest, the first bird species, through the fixed
path for real: `clean → texture (candidate a; needed despite an existing
committed `textured/model.glb` from R0.5 — see below) → rig --kind bird →
grade → install`. `rig_report.json`: 19 bones, 14,004 vertices, 6
unweighted (0.04%, same noise-level pattern as Brooktail's), idle motion
at 108% of walk (clear of `rig_bird.py`'s own 6%-is-frozen self-check).
Two eye-guard rectangles added to `grade.py` (a pair of glossy black
hooked-beak shapes checked and rejected — no iris ring, no pupil).

**Mistake made and caught within the same task, before the branch was
confirmed merged:** shipped Galecrest's `species.json` height as 1.85m,
picked from D13's looser "largest tier, alongside Meadowhart and Tuskroot"
language without re-reading `BACKLOG.md`'s R0.7 section, which fixes
Galecrest specifically at 2.00m in its height table. Caught on a second
pass through `BACKLOG.md` while updating it for this entry, fixed in
`4d078e2`, re-verified in Godot (rendered model matches 2.00m exactly, no
footprint clamp, all six clips intact). Lesson for future firings:
**R0.7's height table is the source of truth for a species' height figure,
read it before writing the number** — D13 only fixes the relative
ordering and rough tier, not the exact figure.

**Also checked and corrected a wrong assumption made mid-task:** briefly
believed Duskhush/Pipwing/Reedwing could skip `texture` entirely and reuse
their existing R0.5-committed `textured/model.glb` files, since Galecrest's
turned out to share that history. Wrong — `DONE.md`'s own Tuskroot entry
(below) already recorded that every one of the ten R0.5 outputs is
structurally unusable (textured before `clean`, so 50,000+ triangles
against a 30,000 budget, thousands of non-manifold edges). Caught before
being written into `BACKLOG.md`; that file states the correct instruction
(`clean` then `texture` fresh, same as every other species).

`species.json`: `aggressive: true` (rare — only Tuskroot has this among
the wild roster so far), reflecting the Air Sheet's own "fierce focused
eyes"/"Aerial Striker" language: a genuine predator, matching D13's
explicit requirement that Galecrest not read like the Air starter
Galewisp. Highest attack (28) and lowest defence (15) of the roster so
far, mirroring Galewisp's own thin-armour/high-attack profile pushed
further. `model_yaw` not visually verified — this container still has no
`libEGL.so.1`, so `turntable.py` cannot render a frame, the same
persistent limitation recorded for every species finished this session;
left at 0.0, the default every quadruped shipped with.

Balance after Galecrest's texture pass: **205** (was 215). Duskhush,
Pipwing, Reedwing each still need their own `clean`/`texture` pass,
~10 credits apiece — see `BLOCKED.md`.

CI was still running when this entry was written; verified separately
once green — see `ralph-status` for the real-time record, and do not
trust this line alone as proof of a merge.

## R0.8 — ASSET_LEDGER rows for Mosshell/Brooktail; missing-record gap closed
`b145f2d` · Extends the previous R0.8 partial entry (below) to all six now-
finished R0.6 wild quadrupeds — every one of Tuskroot, Meadowhart,
Burrowback, Paddlenewt, Mosshell, Brooktail now has an `ASSET_LEDGER.md`
row. Still not R0.8 complete: the four bird species have no model yet
(blocked on `animate_bird.py`), so no row for them.

**Also resolved `MEADOWS_WILD_PRODUCTION_REPORT.md`'s "known gap" note**,
open since it was written: the report said Bramblebun's, Mudsnout's and
Trailpup's candidate-selection records "did not survive into `ralph/`" and
asked whoever finished R0.8 to either find them or say plainly they don't
exist. They were never actually missing — they predate the Ralph loop
entirely, so they were never going to be in `ralph/DONE.md`, and looking
there was looking in the wrong place. The real record is in git history:
commit `d2520f0` ("Bramblebun stops being a duck...") and `9ec9eaa`
("Mudsnout and Trailpup...") both carry full candidate-selection reasoning
in their commit messages, and `ASSET_LEDGER.md`'s existing rows for those
three creatures already condense that same reasoning (they were written
from these commits at the time, just never cross-referenced back to them).
The report now cites both commits directly instead of asking a future
reader to re-find them. Also brought the report's "What's next" section
current — it still described R0.5 and R0.6 as not yet started.

CI green (run 31307762531), fast-forwarded to `main` at `b145f2d` —
verified by fetching `origin/main` directly.

## R0.8 — ASSET_LEDGER rows for the four shipped R0.6 creatures (partial)
`92fc1ae` · Not R0.8 complete — six R0.6 species (Mosshell, Brooktail, and the
four birds) have no model yet, so no row for them either; they land as each
model does, the same rule R0.7 already applies to `species.json` entries.
Rows added for Tuskroot, Meadowhart, Burrowback and Paddlenewt, matching the
existing table's per-creature style (Bramblebun/Mudsnout/Trailpup).

**Why this instead of R0.6/Mosshell**, which is the actual next item in
order: this firing's `send_later` self-resume did not carry
`MESHY_API_KEY` — only a cron-fired session's prompt does, a distinction
this session had to learn twice (see the R0.6 Paddlenewt entry above for the
first time, and `BLOCKED.md`'s current top entry for the fuller writeup).
Mosshell's `clean` step (Blender only, no key needed) was done and is not
committed — cheap to redo. Doing R0.8's ledger work instead of idling kept
the firing's context used on real, unblocked project state rather than
nothing.

CI green (run 31303384277), fast-forwarded to `main` at `92fc1ae` — verified
by fetching `origin/main` directly.

## R0.6 — Brooktail finished (sixth of the ten, last of the six wild quadrupeds)
`20f8412` · Same pipeline as the previous five: clean raw R0.4 winner
candidate `a` (54,836 → 28,000 tris, manifold) → retexture via Meshy →
`rig_quadruped.py` → `grade.py` SPECIES entry → `finish.py grade` →
`finish.py install` → `species.json` entry from the Water Sheet's own
Resourceful Diver/Helper role and build notes.

**This species carries two real defects, both documented rather than fixed —
worth reading before touching it again:**

1. **R0.4's report names Brooktail the one HARD FAIL of the ten wild
   species**, not a clean pick like the other five finished so far — every
   candidate is missing the canon's broad flat scaled paddle tail, giving a
   round tapering tail instead. This was **wrongly summarized as "no
   follow-up flagged" in the previous firing's handoff prompt** (a
   send_later message written without re-checking the report directly);
   the actual report entry was caught and corrected by reading
   `docs/art/MEADOWS_WILD_PRODUCTION_REPORT.md` directly rather than
   trusting the handoff. The report's own instruction is explicit: ship it
   forward with the defect flagged rather than block or re-roll, since "the
   tail needs a real sculpting pass before this creature is considered
   done" — separate future work, not attempted here.

2. **`rig_quadruped.py` left 35 of 14,034 vertices (0.25%) unweighted** —
   the first species in this batch where that actually happened; the
   previous five all landed at exactly 0 despite carrying similar residual
   post-retexture mesh noise (this one: 6,075 non-manifold edges, 81
   microscopic disconnected components — same category every species
   carries after Meshy's retexture re-unwrap, see Tuskroot's entry above).
   Investigated rather than shipped blind: extracted the unweighted
   vertices' world positions and found them scattered across the entire
   bounding box, not concentrated near the tail — so this is likely NOT the
   same root cause as (1), just the same known noise pattern crossing a
   threshold this one time. `inspect_glb.py` and Blender's own
   `ARMATURE_AUTO` weighting have no built-in retry/repair for this;
   fixing it properly would mean a fresh clean/remesh pass (cost: another
   Meshy texture charge) or waiting for the eventual tail sculpt to
   naturally redo the mesh. Documented in `species.json`'s `_comment_art`
   rather than guessed at.

**Six eye-guard rectangles**, same duplicated-across-UV-islands pattern
every species has shown, found by the same full quadrant-by-quadrant scan.
One dark almond shape near the snout was checked and rejected — no teal
iris ring, reads as a nostril shadow.

**Finishes the quadruped half of R0.6.** All that remains is the four bird
species (Galecrest, Duskhush, Pipwing, Reedwing), and they are blocked:
`finish.py rig`'s animate step is hardcoded to `animate_quadruped.py`
regardless of `--kind`, and no `animate_bird.py` exists. Whoever picks up
R0.6 next needs to write one (or generalise `animate_quadruped.py`) before
any bird can move past the `rig` step — this is now the actual next blocker
for R0.6, not a credits or key problem.

**Not in `EncounterDirector.WILD_SPAWNS`**, so `smoke_art`'s shared run
doesn't spawn it directly (though `_every_species_has_art()` confirms the
model path resolves, and the run stayed green — the 35 unweighted vertices
do not block import or the test suite, only animation quality). Height-fit
verified with the same small standalone script as the previous five:
**wanted 1.450m, rendered 1.450m, exact match.** Not committed.

CI green (run 31306142495), fast-forwarded to `main` at `20f8412` —
verified by fetching `origin/main` directly.

Meshy balance after this species' texture pass: **215** (was 225).

## R0.6 — Mosshell finished (fifth of the ten)
`e15a204` · Same pipeline as the previous four: clean raw R0.4 winner
candidate `b` (54,396 → 28,000 tris, manifold) → retexture via Meshy →
`rig_quadruped.py` (15 bones, 0 of 13,998 vertices unweighted, 6 clips) →
`grade.py` SPECIES entry → `finish.py grade` → `finish.py install` →
`species.json` entry from the Water Sheet's own Steady Tank/Shelter role and
build notes.

**Four eye-guard rectangles**, same duplicated-across-UV-islands pattern the
previous four species already showed, found by the same systematic
quadrant-by-quadrant scan of the full 2048² atlas. Several candidates
checked and rejected this time: a pair of uniform amber blobs matching the
ordinary scale/wart spots scattered across the rest of the shell texture (no
pupil at all), a tan almond/slit shape that reads plausibly as a closed
eyelid rendered into the stone-shell pattern but wasn't confident enough to
guard, and a dark crevice with an amber edge but no round iris.

**R0.4's report flagged a topology check** — a possible thin protrusion near
the hindquarters that might read as an errant tail/spike — that this pass
could neither confirm nor rule out: this container has no `libEGL.so.1`, so
`turntable.py` cannot render a single frame to actually look at (same gap
hit on both Burrowback's and Paddlenewt's containers, apparently a property
of the container rather than a one-off). `inspect_glb.py`'s structural
report on the graded model showed only the ordinary post-retexture
non-manifold-edge/duplicate-vertex noise that rigging already tolerated
fine (0 unweighted vertices) — nothing that specifically flagged a
hindquarters anomaly, but that report can't see silhouette either.
Documented honestly in `species.json`'s `_comment_art` for whoever next has
a rendered frame to check against.

**This task spanned two firings**, same shape as Paddlenewt's: the first
firing (a `send_later` self-resume) had no `MESHY_API_KEY` — confirmed this
is specific to self-scheduled resumes, not cron firings, which is now a
settled fact rather than a surprise each time it happens. That firing did
Mosshell's Blender-only `clean` step, recorded the block in `BLOCKED.md`,
and pivoted to real unblocked work instead of idling: `docs/ASSET_LEDGER.md`
had no per-creature row for any of the four R0.6 species shipped so far,
despite R0.8 asking for exactly that — added rows for Tuskroot, Meadowhart,
Burrowback and Paddlenewt (`92fc1ae`, `17b5caa`, both verified shipped to
`main`). The next firing was cron-fired, carried the key correctly, and the
same `clean.glb` survived in the same container so nothing was redone.

**Not in `EncounterDirector.WILD_SPAWNS`**, so `smoke_art`'s shared run
doesn't spawn it directly (though `_every_species_has_art()` confirms the
model path resolves, and the run stayed green). Height-fit verified with the
same small standalone script as the previous four: **wanted 1.620m,
rendered 1.620m, exact match.** Not committed.

CI green (run 31304748414), fast-forwarded to `main` at `e15a204` — verified
by fetching `origin/main` directly.

Meshy balance after this species' texture pass: **225** (was 235).

## R0.6 — Paddlenewt finished (fourth of the ten)
`0f51b2a` · Same pipeline as the first three: clean raw R0.4 winner candidate
`a` (56,476 → 28,000 tris, manifold) → retexture via Meshy → `rig_quadruped.py`
(15 bones, 0 of 13,998 vertices unweighted, 6 clips) → `grade.py` SPECIES
entry → `finish.py grade` → `finish.py install` → `species.json` entry from
scratch.

**This task spanned two firings because `MESHY_API_KEY` was missing from the
first one's prompt.** That firing completed the Blender-only `clean` step
(no key needed), found `meshy.py check` reporting the key simply unset — not
rejected, not rotated, just absent — recorded it in `BLOCKED.md` as a genuine
blocker distinct from the credit balance, and pivoted to unblocked work
instead of guessing a key (that pivot is its own separate, uncommitted
tangent — see below). The next firing's prompt carried the key correctly;
the block was reverted since it no longer applied, and the same `clean.glb`
survived in the same container so nothing was redone.

**Five eye-guard rectangles, not one or two.** The 2048² base_color atlas
showed the same duplicated-across-UV-islands pattern Galewisp (six
rectangles) and Tuskroot (three) already showed: every guarded region
carries an identical amber/gold iris ring around a dark pupil, four of five
also with a white catchlight — a texel-for-texel-consistent signature no
ordinary skin blemish produces. Found by a systematic scan (five overlapping
crops, then all four quadrants of the full atlas checked for anything
missed) rather than stopping at the first eye found. Two other dark patches
were checked and rejected: one had no iris ring (a shadowed crease), the
other an amber smear with no black pupil.

`species.json` entry: height 1.50 (R0.7's list, `D13`), stats from the
**Water Sheet** (`docs/art/reference/wild/03_Meadows_Wild_Water_Sheet.png`)
rather than Ground Sheet B — Paddlenewt is the first Water-roster creature
finished. Its subtitle is "Quick Swimmer & Skirmisher" and build notes read
"agile amphibious body... webbed toes for quick bursts... soft fins", not a
sheet with the Ground trio's ROLE/STRENGTHS table format, so the stat
reasoning is transcribed from the subtitle and build notes instead: lowest
defence on the roster (12, soft-bodied and unarmoured), attack in the
upper-middle band (20, a skirmisher hits fast), HP on the low side for a
small creature (90). Non-aggressive — the sheet's own Water-roster design
notes call the whole group "friendly... calm spirits" and Paddlenewt's
listed actions are WATER DASH and PLAYFUL POUNCE, not a hunt.

**R0.4's report flags a cosmetic tail defect on this winner** (short/abrupt
paddle-fin rather than the canon's long taper) — not a hard fail, so per the
pipeline's iterate-on-what-exists philosophy it was documented in both
`grade.py`'s comment and the `species.json` `_comment_art` field rather than
sculpt-fixed, the same treatment Burrowback's claw-scale note and Tuskroot's
plate-edge note got.

**Not in `EncounterDirector.WILD_SPAWNS`**, so `smoke_art`'s shared run
doesn't spawn it directly (though `_every_species_has_art()` confirms the
model path resolves, and the run stayed green). Height-fit verified with the
same small standalone script as the previous three: **wanted 1.500m,
rendered 1.500m, exact match.** Not committed.

CI green (run 31301653288), fast-forwarded to `main` at `0f51b2a` — verified
by fetching `origin/main` directly.

Meshy balance after this species' texture pass: **235** (was 245 at the start
of the second firing — 10 lower than the 255 recorded at the end of
Burrowback's firing, for reasons not accounted for here; balance is read
directly from `meshy.py check` each time rather than assumed, so this is not
a discrepancy in the record, just an unexplained gap between two firings).

## R0.6 — Burrowback finished (third of the ten)
`ccb295a` · Same pipeline as Tuskroot/Meadowhart: clean raw R0.4 winner
candidate `c` (52,818 → 28,000 tris, manifold) → retexture via Meshy →
`rig_quadruped.py` (15 bones, 0 of 14,004 vertices unweighted, 6 clips,
`hit` 12 frames / `faint` 36 frames) → `grade.py` SPECIES entry → `finish.py
grade` → `finish.py install` → `species.json` entry from scratch.

**Only one eye could be guarded with confidence.** The badger's dense
stone/moss camouflage pattern makes a second symmetric eye hard to
distinguish from ordinary texture noise in the 2048² base_color atlas —
rather than guess a rectangle and risk it landing on fur (grading destroys
whatever it is not told to protect), only the one confirmed amber/yellow
iris with a white catchlight is guarded. Documented in `grade.py` itself;
worth revisiting in a later pass if grading is seen eating a second eye.
Grade report: roughness rescaled 0.494–0.706 → 0.60–0.86, emissive off,
specular 0.20.

`species.json` entry: height 1.70 (R0.7's list, `D13`), stats from Ground
Sheet B's own printed ROLE (Defender/Excavator), SIZE CLASS (Medium) and
STRENGTHS (Defense, Digging, Control) lines — highest defence on the roster
so far (23, ahead of Tuskroot's attack lead), moderate HP (110) rather than
tanky-huge for a Medium size class, non-aggressive since a defender protects
territory rather than hunts. All flagged tunable; nobody has fought one yet.

**Burrowback is not in `EncounterDirector.WILD_SPAWNS`** (still only
`bramblebun`, `tuskroot`), so `smoke_art`'s shared run does not spawn it
directly — though its `_every_species_has_art()` pass does confirm the model
path resolves, and the run stayed green (`bramblebun`, `tuskroot`,
`terrapup`, trainer, vegetation all OK). Height-fit verified with the same
small standalone script as Meadowhart (`scenes/pals/pal.tscn` + `wild_pal.gd`
attached + `setup(id)`, then `smoke_art.gd`'s own `_rendered_height()` copied
verbatim): **wanted 1.700m, rendered 1.700m, exact match.** Not committed —
cheap enough (~15 lines) to rewrite per species.

CI green (run 31299327633), fast-forwarded to `main` at `ccb295a` — verified
by fetching `origin/main` directly, not by trusting the CI badge.

Meshy balance after this species' texture pass: **255** (was 265).

## R0.6 — Meadowhart finished (second of the ten)
`f1495d1` · Same pipeline as Tuskroot: `finish.py clean → texture → rig →
grade → install`, candidate a. `rig_quadruped.py`: 15 bones, 0 of 13,994
vertices unweighted. 6 clips.

**Unlike Tuskroot, Meadowhart had no `species.json` entry at all** — Tuskroot
came with a Plumberry placeholder to repoint, Meadowhart did not exist in the
table yet. Added one from scratch: height 1.95 (R0.7's list, `D13`), stats
from Ground Sheet B's own printed ROLE (Rideable/Pathfinder), SIZE CLASS
(Large) and STRENGTHS (Speed, Stamina, Navigation) lines — moderate HP for
its size class, attack/defence both below the roster's combat specialists
since nothing on the sheet says this creature fights. All flagged tunable.

**Meadowhart is not in `EncounterDirector.WILD_SPAWNS`**, so the shared
`smoke_art` run doesn't spawn it and its height-fit was never actually
checked by that pass. Verified instead with a small standalone script
(`scenes/pals/pal.tscn` + `wild_pal.gd` attached + `setup(id)`, then
`smoke_art.gd`'s own `_rendered_height()` copied verbatim) — **wanted 1.95m,
rendered 1.95m, exact match, 0.0000 diff.** Not committed; cheap enough
(~15 lines) to rewrite per species rather than add permanent test
infrastructure for a gap that R0.9's real spawn work may close anyway. Also
ran the full unit suite since a new species.json entry touches
`test_catch_math`/`test_evolution_links` territory: 277 tests, 0 failed.

Grade.py: two eyes, structural fixes only, no hand-tuned palette (same
first-pass philosophy as Tuskroot).

## R0.6 — Tuskroot finished (first of the ten)
`6c6e479` · `tools/art_pipeline/finish.py clean → texture → rig → grade →
install`, then `species.json`'s `tuskroot.placeholder.model` pointed at the
real GLB. `tests/smoke_art.gd`: **model 2.00m, collider 2.00m, exact match,
footprint clamp not tripped.**

**Correction to R0.5, found while starting this task: every one of the ten
R0.5 outputs was textured in the wrong order and none of them can be used.**
`cleanup_mesh.py`'s voxel remesh is what makes a generated mesh manifold
enough for bone-heat rigging, and it destroys UVs — its own docstring says so
and it hard-refuses to run on a model that already carries image textures.
`finish.py`'s documented order is clean → texture → rig for exactly this
reason. R0.5 textured the raw candidates directly, skipping `clean`. Measured
on Tuskroot's R0.5 output: 54,077 triangles (the budget is 30,000), 9,969
non-manifold edges, 5,170 duplicate vertices — un-rigging-safe, and
un-cleanable without losing the texture. The fix, done here for Tuskroot and
needed for the other nine: clean the raw candidate first (28,000 tris, 0
non-manifold edges, 0 duplicates), *then* retexture the clean mesh — a second
Meshy charge, ~10 credits, same as the first. Balance after both of
Tuskroot's texture passes: **265** (was 275, R0.5's own number, before this
firing's correction pass; see this entry's own spend below for the arithmetic
that actually matters going forward).

Also found and fixed: `grade.py` had zero `SPECIES` entries for any of the
ten wild creatures (only the three starters), and `finish.py` never called
`grade.py` at all — `install` copied the animated GLB straight from `rig`,
skipping grading entirely. Added a `grade` subcommand to `finish.py`
(`clean → texture → rig → grade → install`, matching the docstring's promised
"six commands" for the first time) and a `tuskroot` entry to `grade.py`'s
`SPECIES` table: three eye-guard rectangles (located by visual inspection of
the 2048² base_color atlas — this species has no head-close-up reference to
threshold against, unlike Terrapup), roughness rescaled to `ROUGHNESS_BAND`,
emissive off, specular 0.20. **Deliberately no hand-tuned palette shifts** —
unlike Terrapup/Ripplet/Galewisp's entries, no blind gate has reviewed
Tuskroot's colour yet, so only the structural fixes every creature needs are
applied. Grade report: eye guard protected 38,373 texels (0.0/255 delta
inside, confirmed), roughness 0.31–0.73 → 0.60–0.86, emissive map measured 0%
emission and zeroed.

Rigging: `rig_quadruped.py` on the correctly-cleaned mesh gave **15 bones, 0
of 14,000 vertices unweighted** — the residual non-manifold edges/duplicate
verts that Meshy's own retexture re-unwrap reintroduces (6,750 and 3,538,
down from the original 9,969/5,170) did not break bone-heat in practice, so
that specific worry did not need a further workaround. 6 clips from
`animate_quadruped.py`: idle, walk, run, attack, hit, faint.

**Found along the way, not fixed here:** `finish.py rig`'s animate step is
hardcoded to `animate_quadruped.py` regardless of `--kind`, and no
`animate_bird.py` exists — recorded in `BACKLOG.md` as a blocker for the four
bird species (Galecrest, Duskhush, Pipwing, Reedwing), not a blocker for the
six quadrupeds still ahead of them in backlog order.

Blender 4.2.9 and Godot 4.7-stable were not cached in this container and had
to be fetched (`tools/art_pipeline/setup.sh`) — routine, not a finding, but
worth knowing if a future firing's first minutes look unexpectedly slow.

## R0.5 — Retextured the ten R0.4 winners
`7ac1f20` · `tools/art_pipeline/meshy.py texture`, `image_style_url` aimed at
each species' own reference crop under
`assets/pals/tetherbound/<species>/reference/`. All ten went through in one
pass, no stopping partway: **375 → 275 credits, ~10 each** — a third of the
~30/species estimate, so the ~300 budgeted for the whole roster covered it
with 100 to spare.

Force-added like R0.1's candidates — `model.glb`, `provenance.json`,
`thumbnail.png` per species under `assets_raw/<species>/textured/`, `.fbx`/
`.obj` left out as duplicate geometry. Balance check: **275 remaining**, no
`BLOCKED.md` entry needed.

Next up is R0.6 (cleanup/remesh → rig → clips → grade → install), which is
also where R0.4's flagged defects need addressing: brooktail's missing paddle
tail (a genuine hard fail carried forward, needs real sculpting), burrowback's
under-scale claws, tuskroot's plate edges, galecrest's blunt talons — none of
these are texture problems, so retexturing didn't and couldn't fix them.

## R0.4 — Blind critique, picked a winner per species
`46ea130` · Ten fresh subagent critics, each shown only one species'
`compare.png` and its canon text (roster one-liner + the capitalised
signature-feature brief from `meshy.py`'s `SPECIES_PROMPTS`), scored
silhouette, proportion and the signature feature on the untextured white
candidates. All ten scorecards filled (`shots/candidates/<species>-compare.md`)
and summarised in the new `docs/art/MEADOWS_WILD_PRODUCTION_REPORT.md`.

Winners: Brooktail a, Burrowback c, Duskhush a, Galecrest a, Meadowhart a,
Mosshell b, Paddlenewt a, Pipwing b, Reedwing a, Tuskroot a.

**Nine clean picks, one flagged defect carried forward:** Brooktail's winner
still has a HARD FAIL — every candidate for that species is missing the
canon's broad flat paddle tail (both give a round tapering tail instead).
Recorded honestly rather than hidden behind score totals; it ships into
R0.5/R0.6 with the defect flagged for a sculpting pass, since retexturing and
rigging don't touch the tail's shape. Several other species have shared,
non-blocking defects noted for the R0.6 cleanup/remesh step (burrowback's
claws, tuskroot's plate edges, galecrest's talons) — see the production
report's table.

Also wrote `docs/art/MEADOWS_WILD_PRODUCTION_REPORT.md` for the first time
(R0.8 still owes it a provenance-row pass and the missing
Bramblebun/Mudsnout/Trailpup production record, both noted as known gaps in
the file itself).

## R0.3.5 — Fixed the `smoke_catching` flake
`5c919ba` · Three bugs in `tests/smoke_catching.gd` itself, no production combat
code touched:

1. `throw_aim.gd`'s silent 0.9s post-throw cooldown made `try_begin_aim()` fail
   with no signal; the test pressed Throw once and moved on, burning most of
   its 25 attempts on presses that never opened an aim. Now retries
   (`_open_aim()`) until the aim actually opens or a budget past the cooldown
   is exhausted.
2. The test computed pitch from the trainer's hand; production's
   `_aim_direction()` deliberately aims from the camera eye, ~1.5m away via
   `aim.shoulder_offset`. Fixed to read the camera's actual `global_position`.
3. Added lead compensation via the target's `CharacterBody3D.velocity`,
   projected over the aim settle + `throw.release_windup`, since the target
   keeps moving during the aim window.

Also dropped drop compensation entirely — `_aim_direction()` snaps the throw
straight to the target's centre whenever the ray is within a body-width of it,
discarding any elevation added on top, so arcing the aim only risked pushing
the ray outside that snap window. Aiming straight at the (leaded) centre from
the eye keeps it inside instead.

**Verified 11/11 consecutive headless green** (one standalone confirmation run,
then 10 more back to back — required bar was 10). CI on `ralph/R0.3.5` also
went green (run 31290404377).

The earlier "catch versus kill race" diagnosis recorded in a previous backlog
entry never reproduced and was retracted before this fix; it is not part of
what changed here.

## R0.3 — The ten comparison sheets
`5e0f1cc` · concept row over candidate rows, same four angles at one scale, plus
a blank scorecard with a HARD FAIL column per species. Meadowhart's sheet
confirms the `DROP_FOR_SPECIES` fix worked: all three candidates carry the
saddle, stirrup and leaf collar.

## R0.2 — `rig_bird.py` merged
`861c38a` · Proportion-driven bird armature emitting the roster's six standard
clips. Serves Reedwing, Pipwing, Duskhush and Galecrest. Written but **not yet
exercised on a real candidate** — R0.6 is its first real use, so treat its first
run as verification.

## R0.1 — The candidate models and renders are tracked
`1983352` · 26 GLBs and 104 renders force-added out of gitignored scratch
directories. They are 520 Meshy credits that cannot be regenerated on the 375
remaining. `assets_raw/.gdignore` added so Godot does not import them into the
Windows build.

## Pre-Ralph — the session that set this up

- **D17: an evolution is always larger**, with `tests/test_evolution_links.gd`
  enforcing it. Owner instruction.
- **Grading fixed.** One shared `grade.py` replaces three per-species scripts.
  Ripplet's clipped white 33.4% → 0.00%, Galewisp 28.5% → 0.00%, Ripplet's
  emissive (lighting 38% of itself) zeroed, Terrapup verified not to regress at
  0.36/255 outside the eye guard.
- **The sequence director written** — the file three places in the repo already
  claimed existed. Beat order driven from `opening.json`, not an enum.
- **`name_prompt.gd` did not parse** under Godot 4.7, so the naming panel was
  instantiating scriptless and beat 5 could never have worked. Found
  independently by two agents. Fixed.
- **The phantom party is gone.** `party_seam.gd` looked up `/root/GameState`
  against an autoload registered as `Game`, with a mismatched API, so it kept a
  second five-slot party beside the real one. A tautological assertion —
  `assert_true(answer or not answer)` — is why nothing ever said so.
- **Docs brought onto the wild-roster canon.** Ridgewolf and Terracrown retired,
  Mudsnout added, Tuskroot moved to the one evolution the biome has.
- **The negative prompt list stopped banning three creatures' own signatures** —
  a deer's long legs, a deer's saddle, an otter's paddle tail.
- **All ten species generated**: 895 → 375 credits, exactly the 520 planned, no
  re-rolls.

Suite went 247 → 277 tests over the session.
