# HANDOVER — T1-ARCH-STRONGHOLD, 2026-08-29

Coordination tooling dropped out; this lane was told to stop, push
everything, and write this up rather than continue. This is that writeup.

Branch: `ralph/T1-ARCH-STRONGHOLD`, pushed to origin.
Commit: `7231e0f304fe8162fb5160cd1f1c810cd694baf5` (only commit on this
branch beyond its fork point `de5d656` off `ralph/LAND-0829A`).
**Verified pushed**: `git rev-parse HEAD` and
`git rev-parse origin/ralph/T1-ARCH-STRONGHOLD` both print `7231e0f...` as
of this writeup. Working tree is clean — nothing uncommitted, nothing
stashed.

Owner note: the stand-down message says `main` is now at `961a8c02` and
`ralph/LAND-0829B` already carries "the work you pushed earlier today" —
this lane pushed exactly once, the `7231e0f` commit above, at roughly
13:00 in this session (before the stand-down). If `LAND-0829B` was cut
before that push landed, this branch's commit may not be integrated yet;
check for it by content (search for `_build_exterior_dressing` in
`scripts/world/stronghold.gd`) rather than assuming.

## 1. What I was asked to do, and where I got to

Task: fix the stronghold's exterior, which both the owner and an
independent Fable judge (reading nothing this lane or the prior same-day
T1-ARCH pass wrote) called BAD — the judge specifically: "the worst-reading
structure in the world right now" from the flank, "a featureless
near-black box... no roofline articulation, no openings, no banners, no
machinery, no propaganda."

Four asks in the brief, in order: (1) fix the value/lighting problem, (2)
fix the approach-vs-wall texture scale collision, (3) add articulation and
Team-Tether occupation dressing, (4) re-render the same frames and compare.

**Where I got to:** (1), (2) and (3) are implemented and I believe correct
— see §2 for what's verified vs not. (4) is done for the two subject
frames (`S-ext-01`, `S-ext-02`) but I never got a second, INDEPENDENT judge
pass on it (I was told explicitly not to judge my own work, and the
stand-down landed before I could route it back). Performance measurement
(explicitly required in the brief: "measure frame cost before and after")
was **not completed** — see §2.

## 2. Done and verified vs done-but-unverified vs open

### Done and verified (I rendered it and looked at the pixels)

- **Root cause of why the prior T1-ARCH pass didn't fix this.** A same-day
  earlier pass (commit `b871610` on `main`, already merged before I
  started) added fire+sky-fill lights but ONLY on the gate/south face of
  `outer_works`. Its own report said so outright and named "a full
  occupation-scale dressing pass" as separate, un-attempted work. I
  confirmed this is exactly why the judge's `S-ext-02` (a flank stand, not
  a gate stand) still read as a near-black box — verified by reading the
  actual light coordinates in `stronghold.json` (all at local z≈-13, i.e.
  the south face only) against the flank camera stand's geometry.
- **Flank lighting.** Added `lights_flanks` to `stronghold.json`: the same
  fire+sky-fill recipe re-aimed at the `-x`/`+x` walls of `outer_works` and
  `courtyard`. Rendered before/after at the judge's own corrected camera
  stand (`tools/_judge_capture_arch_0829.gd`, copied over from
  `ralph/JUDGE-VISUAL` — see §4 for why that copy matters). BEFORE:
  featureless near-black box. AFTER: warm-lit, clearly stone, readable at
  distance.
- **Exterior occupation dressing** (`_build_exterior_dressing`/
  `_dress_exterior_wall` in `scripts/world/stronghold.gd`): Team Tether
  hardware (oxblood girder+pillars+live teal conduit, reusing
  `_tether_material()`/`_live_material()` already validated elsewhere in
  this file) bolted onto the TRUE outward face for the first time —
  `_build_trim()`'s existing bands/pillars mount 0.35m onto a wall's INNER
  face and have never been visible from outside the building. Plus a
  coping+merlon roofline (the "no roofline articulation beyond one step"
  complaint). Rendered and visible: crenellated silhouette break, visible
  hardware, banners.
- **A real bug I caught myself, not told about**: the first render showed
  banners as thin red slivers, not visible flags — my initial rotation
  assumed the model's local forward was Godot's default -Z, matching how
  `building_prefabs.json` places the castle's own banners (all at
  `yaw_deg: 0`). That assumption was WRONG for this asset. I opened
  `assets/buildings/quaternius_castle/Banner.obj` directly (it's a text
  OBJ, readable with `head`) and read its vertex data: it is a
  wall-bracket flagpole, a short post near local origin with a horizontal
  arm reaching to `x=0.673` carrying the flag at the TIP — so this
  specific asset's "forward" is local **+X**, not -Z. Recomputed the
  rotation (`Vector3(1,0,0).rotated(UP, yaw) == (cos(yaw), 0, -sin(yaw))`,
  solved for each wall's outward normal), re-rendered, confirmed banners
  now read as actual flags at both the gate and the flank. This is worth
  flagging forward: **`building_prefabs.json`'s castle banner placements
  all use `yaw_deg: 0`, which — if my read of this mesh is right — means
  every one of them has the pole pointing along whatever the castle's own
  east/west axis is at that wall, not necessarily outward from the wall it
  sits on.** I did not check whether this ships a similar (already-live)
  defect on the castle itself; see §5.
- **Approach texture-scale collision** (`_build_exterior_facing`/
  `_face_rect`): a thin (6cm) decorative skin at a finer tile
  (`STONE_TILE * EXTERIOR_FACE_TILE_MULT`, 1.8x) flush against every true
  exterior wall face, deliberately NOT a retune of the shared
  `_wall_material(true)` every chamber wall (including the three roofed
  interior rooms) uses — so the already-validated interiors
  (CONTENT-0828B rounds 1-6) cannot drift. I looked at the rendered gate
  face before/after; it reads less collided but I did not do a pixel-ruler
  measurement the way the original `STONE_TILE` derivation did (see
  `stronghold.gd`'s own header comment on `STONE_TILE` for that method) —
  worth a second look with actual measurement rather than my eyeball.
- **Gate frame** (`_build_gate_frame`): proud stone jambs + a lintel
  around the entrance, replacing "a plain rectangular hole." Rendered,
  visible, reads as a real doorway with a shadow line now.
- **Traversal/logic safety**: `tests/smoke_stronghold.gd` (the project's
  own headless boot-and-walk-the-route test) passed twice after my edits
  — once right after the geometry refactor, once again after the banner
  rotation fix. Route order, doors, gauntlet trainers, recovery bed and
  the machine are all still intact. Command:
  `godot --headless --path . --script tests/smoke_stronghold.gd`

### Done but NOT independently verified

- **No second-pass judge review.** My own instructions explicitly say "you
  do not judge your own work... the coordinator will route them back to
  the independent judge." That never happened before stand-down. The
  before/after frames exist (see §3) but nobody but me has looked at the
  "after" ones.
- **The "H"-shaped hardware motif** (girder band + 2 oxblood pillars + 1
  bright teal conduit, repeated identically on every dressed wall) reads
  as Team-Tether machinery to me and is visually consistent with the
  pylon language the judge praised, but it is also fairly repetitive
  (literally the same shape twice in one `S-ext-02` frame, since two
  chambers' flanks are both visible). I did not have time to vary it. A
  fresh eye should judge whether this is "consistent faction vocabulary"
  or "copy-pasted and it shows."
- **Courtyard's dressing** was built by the same code path as
  `outer_works` but I never captured a camera stand that shows it — only
  `outer_works`' flank and gate got rendered (those are the judge's own
  two subject frames). If a successor wants proof the courtyard actually
  looks right too, that's a new capture, not a re-run of an existing one.

### Still open

- **Performance measurement — not done.** The brief explicitly says
  "measure frame cost before and after at the stronghold." I set up to do
  this properly with the project's own `tools/perf_render_stats.gd`
  (which already has a `stronghold_approach` view built in — no new
  tooling needed) but the stand-down landed mid-run and I killed the
  in-flight process rather than let it finish. See
  `ralph/reports/T1-ARCH-STRONGHOLD_2026-08-29.md`'s Performance section
  for the exact command and my node-count-based (NOT measured) estimate:
  roughly +16 OmniLights (all `shadow_enabled = false`), ~60 decorative
  boxes, 8 banner mesh instances, all static/built-once. The number I'd
  check first is total OmniLight count in this one building (~28 after
  this change) against whatever the ROG Ally per-scene light budget
  actually is — I don't know that budget and didn't find it documented.
- **`stronghold.json`'s own `_comment_ow5d_relocation`** already flags
  `yaw_deg: 90` as "very likely WRONG" for the corridor's real north
  approach bearing. I did not touch this — it's a full re-siting job
  (probe grid, every chamber/light/mark recomputed) that a prior lane
  explicitly deferred to a future reviewer, and I had neither the time nor
  the mandate to redo it. Still open, still flagged, still real.
- **The castle's own remaining flatness** (unrelated Quaternius-kit
  texture/AO issue) — out of scope for this lane by the brief's own
  wording, untouched.

## 3. The numbers / evidence trail

- Judge's original verdict: `ralph/reports/JUDGE-VISUAL-2026-08-29.md` on
  branch `ralph/JUDGE-VISUAL`, frames in
  `ralph/reports/judge-visual-2026-08-29/` on that same branch (NOT this
  one — I read them via `git show origin/ralph/JUDGE-VISUAL:<path>`,
  never merged them here).
- Prior same-day T1-ARCH report (the one that fixed only the gate face):
  `ralph/reports/T1-ARCH_buildings_2026-08-29.md`, already on `main`.
- My own report, with the full before/after narrative:
  `ralph/reports/T1-ARCH-STRONGHOLD_2026-08-29.md` (this branch).
- Smoke test: `godot --headless --path . --script tests/smoke_stronghold.gd`
  — passed twice, output ended `stronghold smoke test passed`, exit 0
  both times.
- Render command (reproduces the judge's own corrected camera stands):
  ```
  godot --headless --path . --import
  xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
    --rendering-driver opengl3 --resolution 1280x800 \
    --script tools/_judge_capture_arch_0829.gd
  ```
  Output lands in `res://shots/judge0829/` (gitignored — not in this
  branch's diff, regenerate with the command above). I have local copies
  under this session's scratchpad only; they do not survive session end.
  **A successor needs to re-run this command to see the frames** — they
  are not preserved anywhere durable.
- Performance command (not completed, see §2):
  ```
  xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
    --resolution 1280x720 --script tools/perf_render_stats.gd -- --label=<name>
  ```
  Run once on `git stash`-ed (pre-my-changes) files with `--label=before`,
  once on the current tree with `--label=after`, compare the
  `stronghold_approach` row.

## 4. What I learned that is not visible in the diff

- **Godot is not pre-installed in this environment.** `which godot`,
  `find / -iname godot*` — nothing. It has to be fetched fresh every
  session with the project's own documented recipe (found in
  `ralph/lanes/COMMON.md`/`COORDINATORS.md`):
  ```
  curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip
  unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64
  mv Godot_v4.7-stable_linux.x86_64 /usr/local/bin/godot
  ```
  This worked fine through the proxy. `xvfb-run` and the mesa/llvmpipe
  packages were already present; only the Godot binary itself was
  missing. A successor session will hit this too — budget 1-2 minutes for
  the download, then `godot --headless --path . --import` before any
  render (also 1-2 min).
- **A self-matching `pgrep` trap in a chained wait script cost me a full
  30-minute Monitor timeout for nothing.** I wrote a `Monitor` command
  that did `while kill -0 $(pgrep -f "smoke_stronghold.gd" | head -1); do
  sleep 3; done` to wait for a smoke test to finish before chaining into a
  render. The monitor's OWN shell process's command line contains the
  literal string `"smoke_stronghold.gd"` (because that's the pattern
  text, right there in the script `pgrep -f` is searching for), so
  `pgrep -f` matched the monitor script's own process and the loop never
  exited. Lost 30 minutes to this. **Lesson for whoever waits on a
  process by name in this environment: `pgrep -f` matches your own
  command line if your own command line contains the search string —
  match on a more specific substring that can't appear in your own
  invocation (e.g. the full absolute script path plus a distinguishing
  flag), or just use `run_in_background: true` on the target command
  directly and let the harness's own completion notification do the
  waiting instead of hand-rolling a poll loop.**
- **`Vector3.ONE * scale` on an OBJ-imported mesh will silently distort if
  the OBJ's own axes aren't uniform** — not an issue I hit, but I checked
  `Banner.obj`'s vertex data closely enough to note the asset is NOT
  axis-symmetric (post along Y, arm along X, thin along Z) so a future
  non-uniform scale on it would need to know which axis is which; I used
  uniform scale (`BANNER_SCALE = 2.2`, matching the castle's own value) so
  this didn't bite me, just flagging it since I had the vertex data open
  anyway.
- **The stronghold's chamber-wall material function (`_wall_material`)
  is used for BOTH the true exterior yard walls AND the three roofed
  interior rooms' walls** — there is no existing "is this face outward-
  facing" concept in the codebase before this lane; I built one
  (`_opening_on(id, side).is_empty()` as the perimeter test, which
  `_build_wall` already computes for a different reason) rather than
  finding one already there. Worth knowing if a future lane wants to do
  something else per-face (e.g. weathering, grime) — the hook I built
  (`EXTERIOR_CHAMBERS` + the `_wall_rects`/`_face_rect` pair) is reusable
  for that, not just for what I used it for.
- **I did NOT find a documented ROG-Ally light/draw-call budget anywhere**
  in `docs/` — I looked for one before guessing at how many lights was
  "too many" and came up empty. If one exists, I didn't find it; if one
  doesn't, that's worth someone establishing before more lanes keep
  adding unshadowed omnis to already-lit buildings on instinct the way I
  just did.

## 5. Things I believe are wrong, or worth a second look, elsewhere

- **`building_prefabs.json`'s castle banner placements might all be
  mis-rotated the same way mine were, and nobody would have caught it
  from a distant silhouette shot.** Every castle banner entry uses
  `yaw_deg: 0`. If `Banner.obj`'s local-+X-forward convention (which I
  verified directly from its vertex data, not guessed) applies the same
  way there, every castle banner is pointing along whatever direction
  local +X maps to at THAT mount's own placement transform, not
  necessarily outward from its wall — which could read as "banner glued
  flat against the stone, barely visible edge-on" exactly like mine did
  before my fix, and would be very easy to miss in a wide establishing
  shot (the castle's own `C-01`-`C-04` frames are all fairly distant). I
  have NOT verified this — it's a hypothesis from reading one asset's
  geometry, not a finding from rendering the castle. Worth a five-minute
  close-up render of one castle banner before anyone spends more effort
  on the castle's "bannerless" complaint, because if I'm right the
  banners are already there and just invisible for the same reason mine
  were.
- **The prior T1-ARCH report's own performance framing is worth reusing,
  not re-deriving**: `tools/perf_render_stats.gd`'s header explicitly
  says llvmpipe's own frame TIME is meaningless in this environment and
  the structural counters (draw calls / primitives / objects) are what
  carries to the real ROG Ally target. I mention this because it would be
  easy for a successor to instead try to time frames by hand and draw a
  false conclusion from software-rasterizer wall-clock noise — the tool
  already exists specifically to avoid that trap, use it rather than
  rolling a new one.
- **Nothing in the spec or brief was wrong that I found.** The brief's own
  diagnosis (read the judge report, check the prior lane's own admission
  of what it left undone) was accurate and saved me from re-diagnosing
  something already correctly diagnosed twice.

## 6. File footprint

Changed (all committed in `7231e0f`):
- `scripts/world/stronghold.gd` — new methods `_wall_rects`,
  `_build_exterior_facing`, `_exterior_face_material`, `_face_rect`,
  `_build_exterior_dressing`, `_dress_exterior_wall`, `_hang_banner`,
  `_build_gate_frame`; `_build_wall` refactored to use `_wall_rects`
  (behavior-preserving — verified via the smoke test); new consts
  (`EXTERIOR_CHAMBERS`, `BANNER_MODEL`, `BANNER_COLOUR`, `BANNER_SCALE`,
  `EXTERIOR_FACE_TILE_MULT`, `EXTERIOR_FACE_SKIN`, `COPING_H`,
  `COPING_PROUD`, `MERLON_W`, `MERLON_H`, `MERLON_GAP`); `_build_lights`
  now reads `lights_flanks` in addition to `lights`; three new calls
  wired into `build()` (`_build_exterior_facing`, `_build_exterior_dressing`,
  `_build_gate_frame`, placed after `_build_lights()` and before
  `_build_interior_area()`).
- `data/config/stronghold.json` — new `lights_flanks` array (16 entries)
  and its own `_comment_lights_flanks`; one comment appended to the
  existing `_comment_lights_exterior` recording what the prior pass left
  undone and why this one exists.
- `tools/_judge_capture_arch_0829.gd` (+ `.gd.uid`) — copied verbatim from
  `origin/ralph/JUDGE-VISUAL` so this branch can reproduce the judge's
  exact camera stands without depending on that branch. NOT authored by
  me; do not re-tune it here, tune it on `JUDGE-VISUAL` if it needs
  changing, or this branch silently diverges from what the judge actually
  looked at.
- `ralph/reports/T1-ARCH-STRONGHOLD_2026-08-29.md` — new, this lane's own
  before/after writeup.
- `ralph/reports/handover-T1-ARCH-STRONGHOLD-2026-08-29.md` — this file.

Was about to change, did not get to:
- Nothing mid-edit. The working tree was clean at stand-down (verified:
  `git status --short` and `git diff --stat` both empty before writing
  this handover). Everything I had touched was already committed.

Not touched, but adjacent and worth knowing about for collision
avoidance:
- `scripts/world/landmark.gd` (the castle) and
  `data/config/building_prefabs.json` (castle module placements,
  including its banners) — read but not edited. See §5's banner-rotation
  hypothesis before anyone touches these.
- `scripts/world/interior_structure.gd` and the three roofed interior
  chambers (`tether_approach`, `warden_arena`, `legendary_chamber`) —
  explicitly left alone per the brief ("load-bearing... do not disturb"),
  and my own exterior-facing/dressing code is gated
  (`EXTERIOR_CHAMBERS = ["outer_works", "courtyard"]`) so it structurally
  cannot reach them.
- `scripts/world/stronghold_occupation.gd` — the CASTLE's own occupation
  system (braziers, tether lamps, camp). I read it closely for technique
  (housing/lens ratio math, flicker recipe) but did not call it or modify
  it; my exterior dressing on the stronghold building is a separate,
  simpler implementation in `stronghold.gd` itself, not a reuse of that
  file. If a future lane wants flicker/torch-prop-quality fire on the
  stronghold's flanks (mine are static-energy OmniLights, no flicker),
  that file is the pattern to port, not extend in place.

## 7. What I would do next, concretely

1. Run the performance comparison that never finished (§2/§3 has the
   exact commands). If the light count is a real problem, the cheapest
   fix is probably collapsing the 3-fire-lights-per-flank pattern to 2
   with a slightly larger range each, mirroring what the castle's own
   validated recipe already proves works at a similar wall length.
2. Get an independent judge pass on the `S-ext-01`/`S-ext-02` after-frames
   (regenerate them with the render command in §3 first — they don't
   survive between sessions). I believe they're a large improvement but I
   am not the judge.
3. Five-minute close-up render of a single castle banner to check §5's
   hypothesis before it either wastes someone's time re-diagnosing
   "bannerless" from scratch or gets silently missed forever.
4. If the judge comes back with anything about the hardware motif reading
   as repetitive (§2's flagged unknown), the fix is probably varying
   which of {girder, pillar-pair, conduit, banner-pair} appears on which
   wall rather than always all four — `_dress_exterior_wall` already
   takes a `hardware: bool`, extending it to a bitmask or a per-call
   subset would be a small change.
5. Courtyard's own dressed flanks have never been rendered — worth one
   capture before anyone assumes they look as good as outer_works' does
   just because the code path is shared.
