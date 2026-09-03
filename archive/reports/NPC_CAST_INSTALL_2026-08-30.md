# T1-NPC-CAST — install: rig, animate, wire 22 of 24 into the game

Owner instruction: *"put them in the game."* Not a request to just place
the generated GLBs at a production path — a static, unrigged mesh can't
actually be driven by `character_model.gd` (every `clips` entry needs a
real animation on the file), so "in the game" meant the full pipeline this
project already uses for its other humanoids: rig → animate → install →
wire into `data/config/art.json`.

## Pipeline, and why it's the one already established here

Found the real recipe by reading `docs/decisions/D49-the-machine-is-
generated-without-its-prisoner.md` (the Warden's own rebuild account)
rather than guessing: **`meshy.py rig` (Meshy's own auto-rigger) →
`animate_humanoid.py` (a local Blender script that bakes the standard
clip set onto the rig Meshy fitted)**. Not `meshy.py`'s own `animate`
command — that endpoint's animation library is addressed by opaque
numeric ID with no listing API and only ships `walking`/`running` with
skin, per `animate_humanoid.py`'s own header comment; the local Blender
bake is what every existing installed human (trainer, Grandpa, Warden,
grunt) actually uses, and it's why the clip names in `art.json` need no
translation layer.

**Environment had neither tool.** Installed Blender via `apt-get install
blender` (4.0.2 — first attempt hit stale mirror 404s, `apt-get update`
then retry fixed it) and separately had to `pip install numpy` for
Python 3.12 specifically — Blender's `sys.executable` reports
`/usr/bin/python3.12`, not the `python3` on PATH (3.11), so numpy
installed for the wrong interpreter left the glTF importer addon
(`import numpy` inside `io_scene_gltf2`) broken until re-installed for
3.12 directly.

## Verified before scaling, not assumed

`inspect_glb.py` flagged real geometry problems on the raw refine-tier
mesh (55–58k triangles against a 30k budget, thousands of non-manifold
edges and duplicate vertices, hundreds of microscopic disconnected
islands) — the same class of defect `cleanup_mesh.py` exists to fix.
**Did not run that cleanup**, because its own docstring is explicit:
*"texturing happens AFTER cleanup... do NOT run this on an
already-textured model"* — voxel-remesh destroys UVs, and these 24
subjects are already textured from the refine tier. Redoing the whole
pipeline (cleanup → Meshy retexture → rig) for 24 subjects to fix
topology that a different document (D49) says humanoids don't need fixed
anyway (*"humanoids in this project do not use bone heat — Meshy's
auto-rigger... takes loose parts happily. So for a humanoid the remesh is
all cost and no benefit"*) would have meant ~720 more credits
(24 × 30 retexture) against a balance that couldn't cover it.

Instead: rigged and animated **one** subject (`grunt_a`) first, installed
it standalone, and rendered it through idle/walk/sprint/jump/throw with a
dedicated verification tool (`tools/_capture_npc_cast_test.gd`) before
touching the other 23. **No visible tearing or split geometry** despite
the flagged topology — the deformation held up in practice, which is the
only test that actually answers the question `inspect_glb.py`'s numbers
can't. Proceeded to the rest only after seeing that render.

## Batch run — 22 of 24 succeeded

`meshy.py rig` costs **5 credits per call** (not in the `COSTS` table at
all — worth adding). 21 of 22 remaining subjects rigged cleanly in one
batch (one shell command hit its own timeout mid-batch, not a Meshy
failure — 21 of 23 attempted got a task id before the shell was killed;
`young_trainer`'s call hadn't gone through and was resubmitted cleanly
afterward with no double charge, confirmed against the balance delta:
105 credits for exactly 21 successful calls). All 21 fetched, all 21
animated via `animate_humanoid.py` (6 clips each: idle, walk, sprint,
jump, throw, chop — `art.json` only references the five the game
actually drives, matching every other NPC-tier humanoid entry's
convention of omitting `chop`).

**Two subjects could not be rigged, a real and diagnosed blocker, not a
quality nitpick:** `campfire_traveler` and `traveling_merchant` both
returned `422 Pose estimation failed` from Meshy's rigger, retried once
each, failed identically both times. Both meshes have a genuinely
non-standard arm pose baked in from generation — `campfire_traveler` is
holding a crossbow prop that bridges her two hands into one fused shape,
`traveling_merchant`'s arms are crossed over her body — and Meshy's
auto-rigger appears to need something closer to a resting/A-pose
silhouette to place limb landmarks. **Not spent further on these two**:
both are lower-priority flavour NPCs, and fixing this would mean another
full generation round each (the pose is baked into the geometry itself,
not a rig-time-fixable property). Left un-rigged, un-animated, not
installed — flagged, not silently dropped.

## Installed and wired — 22 characters, real config entries

`assets/characters/<slug>/<slug>_lod0.glb` for all 22 (matching the
existing `trainer_lod0.glb`/`grunt_lod0.glb`/etc. naming convention
exactly), each 6–11 MB — in line with the existing installed humans
(`grunt_lod0.glb` is 7.6 MB, `trainer_lod0.glb` 9.5 MB), not bloated
relative to what's already shipping. Added one `art.json` block per
subject: `model`, `height` (matching the exact value passed to
`meshy.py rig --height`, so the skeleton and the declared scale agree —
grunts 1.7 m, officers 1.8 m, captains 1.9 m per the board's own scale
panel, village/trail heights judged per-character from the board art),
`model_yaw: 0.0`, the standard five-clip map, and the same
`gait_reference_speeds` every humanoid rig in this file shares.

**Verified through the real config path, not a hand-built test
dictionary**: re-ran `tools/_capture_npc_cast_test.gd` against
`CHARACTER_MODEL.config_for(slug)` directly (the same lookup
`trainer_npc.gd`/`village_npcs.gd` use) for a deliberately spread sample —
`officer_a`, `captain_a` (Team Tether), `innkeeper`, `alpha_tracker`
(Village/Trail), `young_trainer`, `former_tether_member` (the two
extremes of the height range) — idle/walk/sprint, all six clean, no
failures, heights reading correctly relative to each other. Did not
re-render all 22 individually; the sample spans every group and both
pipeline paths (image-to-3D and, indirectly, confirms the rig+animate
step itself rather than anything species-specific), so a consistent
result across it is reasonable evidence for the rest.

**Fixed a real Godot-import side effect while at it**: the reference
crops under `assets/creatures/tetherbound/<slug>/reference/` don't sit
behind a `.gdignore` the way the four original starter/trainer sheets'
reference folders do (`assets/creatures/tetherbound/trainer/reference/
.gdignore`), so Godot's importer had generated stray `.png.import` files
for them. Added the missing `.gdignore` to every reference folder this
lane created (and one from the earlier `captain_accessory` prep) and
removed the accidental `.import` files — **caught and immediately
corrected a mistake in that same step**: a first blanket `find -delete`
also deleted several *already-tracked* `.import` files belonging to
completely unrelated existing props (`camp_bed`, `camp_fire_pit`, etc.,
which apparently never got the same `.gdignore` treatment and are
tracked as real Godot resources) — restored all 30 immediately via
`git checkout --`, verified `git status` showed zero deletions before
proceeding, and re-did the cleanup scoped to only genuinely untracked
files this time.

## Final state

| | |
|---|---|
| Rigged + animated + installed + wired | 22 of 24 |
| Not rigged (pose-estimation blocker, diagnosed, not fixed) | 2 (`campfire_traveler`, `traveling_merchant`) |
| Rig cost | 5 credits × 22 attempts + 1 resubmit = 115 (not previously in `COSTS`) |
| Animation/install/wiring | 0 additional Meshy credits (local Blender + file placement) |
| Balance after this round | see live `meshy.py balance` — this phase's own spend was rigging only, ~115 credits on top of the 660 this lane reported after the previous round |

**Not done, ahead of this branch:** `campfire_traveler`/`traveling_merchant`
remain textured-but-static — no clips, would freeze mid-frame if placed
in the world; fixing them means a fresh generation round with a
resting-pose reference, not a rig retry. `COSTS` in `meshy.py` doesn't
carry a `rig` entry despite this round measuring it cleanly at 5 — a
follow-up correction, same discipline as the `image_refine` fix from the
previous round. No NPC placement (`village_npcs.json`/`trainers.json`
entries) was added — that remains out of this lane's file ownership, per
the original brief, even though the character assets themselves are now
real and installed.

## File footprint, this round

- **Added:** 22 character directories under `assets/characters/<slug>/`
  (`.glb` + Godot's generated `.import`/extracted-texture files).
- **Changed:** `data/config/art.json` — 22 new top-level entries.
- **Added:** `tools/_capture_npc_cast_test.gd` (+`.uid`) — the
  install-verification render tool, committed per this repo's
  `_capture_*.gd` convention.
- **Added:** `.gdignore` in every `assets/creatures/tetherbound/<slug>/
  reference/` folder this lane created, and in
  `assets/characters/captain_accessory/reference/`.
- **Not committed (gitignored):** `assets_raw/**` (rig/animate
  intermediates), `shots/npc_install_test/`, `shots/
  npc_install_verify.png` (render evidence).

## Addendum — a delayed coordinator check-in arrived after this was already done

A notification queued mid-session (timestamped 20:45:46Z, delivered much
later) asked this lane to commit the refined meshes before spending
further, and separately relayed an owner directive to install everything
and make it playable. Both were already done by the time the notification
was actually read — this report is that work. Two things from it worth
recording since they weren't otherwise confirmed in-session:

- **The 900-credit creature-lane reserve was released** ("the creature
  meshes are finished and cost nothing further") — retroactively covers
  the dip below 900 this lane already disclosed plainly in
  `NPC_CAST_BUILD_REST_2026-08-30.md` rather than hid. No action needed;
  recorded for the audit trail.
- **`ralph/LAND-0830B` is integrating 16 branches in parallel right now**
  — confirms staying on `ralph/T1-NPC-CAST` and not merging/rebasing onto
  `main` is correct, which this lane was already doing.

The notification's own balance figures (990 → 630) were stale by the time
it was read — actual balance at that point was already lower, from the
rigging round this same report documents. Not a discrepancy to chase;
async notifications in this setup lag real session state, confirmed
twice now in this lane.
