# HANDOVER — T1-STORMWALL, 2026-08-30

Branch: `ralph/T1-STORMWALL`, off `origin/main` @ `1d7fc8e7`. Pushed.

Two orphaned defects, each independently spotted by multiple passes and
owned by neither. Both fixed. Evidence in
`ralph/reports/T1-STORMWALL/shots/`.

---

## Defect 1 — the four grey slabs behind the Meadows Hall

**Root cause, measured rather than assumed.** `tools/_probe_stormwall_hall.gd`
(new, this task) boots the real world and reads `RiftCollapse.horizon()` and
`Stronghold`'s own position:

```
Hall site (world XZ): (8.0, 7560.0)
StormWall origin: (-37.06, 7618.89)  seam (spoke road end): (-33.99, 7513.46)
Hall -> origin: 74.2m   Hall -> seam: 62.7m
StormWall_0: dist_from_hall=362.8m off_axis_vs_seam=6.9deg
StormWall_1: dist_from_hall=408.7m off_axis_vs_seam=4.9deg
StormWall_2: dist_from_hall=332.4m off_axis_vs_seam=8.8deg
```

`T1-HALL`'s re-site (already on `main`, `stronghold.json`'s
`_comment_ow5d_relocation`) put the Hall's `site.at` at (8,7560) — 63-74m from
`rift_collapse.gd`'s own storm-road seam/origin. The three `StormWall` slabs
sit 332-409m from the Hall and 5-9° off the seam's own forward bearing —
**inside** the file's own documented sweet spot ("at the seam the effect
works — 365-461m out"), not outside it. So this is **not** the
visibility/lifecycle bug GATE-E-STRONGHOLD-ART already fixed for the 2km
Band-4 case: `visible_within_metres` cannot tell "seen from the seam, as
designed" apart from "seen from the Hall", because the Hall now sits almost
exactly where the seam already put a viewer. Shrinking the visibility band
would also blank the wall at the storm road's own dead end, deleting the read
the file's own header says is "what the player has looked at across the
broken bridge for the entire chapter" — which is not this file's call to make
unilaterally.

What actually changed is **context, not distance**: at the seam this flat
single-colour unshaded quad is the only thing in a 200m-empty-meadow shot;
next to the Hall's coursed, lit, textured stone it reads as exactly what it
is — a hard-edged rectangle — instead of weather.

**Fix: materials, in `rift_collapse.gd` only.** `_slab_mask()` procedurally
generates (no new asset, no Meshy generation — same rule the rest of this
file already follows for its own geometry) a per-slab seeded noise+feather
texture: internal cloud-like variation, edges feathered into a bank instead
of a hard rectangle, and a base that thins toward the ground fog instead of
ending on a visible sill. `_scale_group`'s animation is untouched — it still
only writes `albedo_color.a`, which multiplies with the mask's own alpha, so
the breathing pulse and the collapse/reveal fade work exactly as before, and
`_cover()`/`horizon()` (mesh area × `albedo_color.a`) never see the texture.

**Evidence** — same camera stand (raised above the Band 5 treeline at the
Sigil Gate approach, aimed at the Hall, `tools/_capture_stormwall_hall_evidence.gd`),
rendered before and after, xvfb + `--rendering-driver opengl3`:

- `shots/defect1-before-stormwall-behind-hall.png` — three crisp, hard-edged
  grey rectangles stacked behind the Hall's roofline. This is the reported
  defect, reproduced.
- `shots/defect1-after-stormwall-behind-hall.png` — same vantage, same slabs,
  now a soft irregular dark cloud bank behind the roofline instead of
  geometric cards.

**Tests.** `tests/smoke_boss.gd` (SG44's own horizon before/after +
barrier-holds probe) and `tests/smoke_gate_e_finale.gd` both run green on the
fixed tree (full logs were captured this session; both print their pass
lines: `boss smoke test passed`, `gate E finale smoke test passed`).

**Not done / left for whoever owns the Hall lane next**, per JUDGE-4's own
Q2-D13-adjacent read and this task's own file-ownership boundary (I do not
touch `stronghold.gd`): the trainer is unlit in night frames, and the Hall's
own occupation/lighting pass is a separate, in-flight concern
(`ralph/reports/handover-T1-HALL-REBUILD-2026-08-30.md`). Nothing here
should conflict with it — `rift_collapse.gd` and its config are untouched
outside `_slab_material`/`_slab_mask`/the one call-site seed argument.

---

## Defect 2 — the capture-check hole

**What was wrong.** `tools/capture_check.gd` (brought into this branch from
`origin/ralph/T1-GROUND-3`, which has not landed on `main` yet — see
"Provenance" below) checks camera-current, grass-follows-camera,
Terrain3D-streams-to-camera and weather-pinned-and-frozen. None of those
catch a camera that is simply pointed at nothing, or standing inside the
world. JUDGE-4's `H-04-gate-mouth.png` (Hall lane,
`origin/ralph/T1-HALL-REBUILD`) is exactly that: shot from below the terrain,
two thirds stone diffuse, one third grass seen edge-on from underneath.

**A second, real bug found while fixing the first.** Both the pre-existing
Terrain3D-streaming check and my new ground check look up the terrain node —
but they searched by node **name** `"Terrain3D"`. This project's own
`playground_world.gd` names its instance `terrain.name = "Terrain"`
(`playground_world.gd:631`). The name search never matched, so the inherited
terrain-streaming check has been silently dead in this project the whole
time it existed, and my first pass at the ground check inherited the same
dead lookup. Fixed by searching by `get_class() == "Terrain3D"` instead
(`_find_terrain`), which can't be defeated by however a scene author named
the instance. Verified the fix actually mattered: before it, my own
demonstration below showed the hardened check still silently PASSING the
known-bad H-04 pose.

**What was added**, respecting the file's own header note that every check
runs at the shutter (inside `problems()`, called from `require()`/
`warn_only()` at capture time, not at `make_current()` time) so a pose that
drifted after setup is still caught:

1. `_ground_problems` — samples `Terrain3DData::get_height` at the camera's
   own XZ (the same call `playground_world.gd::ground_height_at` already
   uses to place everything else in the project) and fails if the camera is
   at or below that surface, past a 0.15m clearance margin sized to never
   paper over a real below-ground shot while not flagging a legitimate
   ankle-height framing pose.
2. `_embedded_problems` — a `PhysicsDirectSpaceState3D.intersect_point` query
   at the camera's own position, catching the broader case a heightfield
   sample cannot: a camera embedded in a wall or a rock, not just under open
   terrain. Best-effort by design (no physics space → says nothing, never
   crashes the capture).
3. `_subject_problems` — optional (`subject: Node3D = null` on `problems()`/
   `require()`/`warn_only()`, so no existing single-arg or two-arg call site
   breaks). Projects every corner of the subject's own world-space visual
   AABB through the camera and fails only if none of it lands inside the
   viewport — the "ideally" half of JUDGE-4's routing note, and also what
   would have caught Q2-D12's eight mis-framed A/B close-ups.

**Nothing already-checked was weakened.** Camera-current, grass-bound, grass
non-empty, Terrain3D-streaming (now actually functional) and
weather-pinned-and-frozen are all still there, unchanged in behaviour, still
gated the same way (`require()` aborts, `warn_only()` doesn't).

**Evidence — demonstrated on `origin/ralph/T1-HALL-REBUILD` itself**, per the
task's own instruction. `tools/_verify_stormwall_capture_check.gd` (run from
a worktree checked out at that branch, hardened `capture_check.gd` copied in
uncommitted for the demonstration only — nothing pushed to that branch)
reproduces `_judge_capture_hall.gd`'s own H-03-ramp-foot (known-good) and
H-04-gate-mouth (known-bad) camera-pose math exactly and runs
`CAPTURE_CHECK.problems()` against each:

```
H-03-ramp-foot (known-good) eye=(8.0, -3.539567, 7505.0) ground_here=-5.24
  capture_check: PASS (no problems)

H-04-gate-mouth (known-bad, JUDGE-4) eye=(8.0, -3.367165, 7542.0) ground_here=-1.67
  capture_check: FAIL (correct) --
    * the capture camera sits at y=-3.37, at or below the terrain height -1.67
      at its own XZ (0.15m clearance required) -- this is a below-ground shot,
      the JUDGE-4 H-04-gate-mouth.png defect (ralph/reports/JUDGE-4-2026-08-30.md)
```

Full log: `shots/defect2-capture-check-h04-verification.txt`. The actual
known-bad frame, reproduced independently on this branch's own (older,
pre-REBUILD) `_judge_capture_hall.gd` — same defect, same camera math, same
underground stone-texture result:
`shots/defect2-H-04-gate-mouth-known-bad-frame.png`.

### Provenance — `capture_check.gd` is not yet on `main`

The task brief said it "landed today," but as of this branch's base
(`origin/main` @ `1d7fc8e7`) it does not exist there — it exists only on
`origin/ralph/T1-GROUND-3` (unlanded, a large vegetation/scatter-rebake
lane). I copied `tools/capture_check.gd`/`.uid` from that branch's tip and
hardened the copy on this branch, per the file-ownership note that this file
is mine. **Whoever lands `T1-GROUND-3` needs to reconcile**: my copy is
strictly a superset of that branch's version (same public API, same
existing checks, plus the three additions and the `_find_terrain` fix above)
— taking mine should be a safe resolution, but it hasn't been diffed against
whatever `T1-GROUND-3` does with it after this point if that branch keeps
moving.

---

## File ownership honoured

Touched only `scripts/world/rift_collapse.gd`, `data/config/rift_collapse.json`
(not touched, in the end — the fix stayed in code), `tools/capture_check.gd`
(+`.uid`), and new standalone tools (`_probe_stormwall_hall.gd`,
`_capture_stormwall_hall_evidence.gd`, `_verify_stormwall_capture_check.gd` —
the last one only ever existed in the T1-HALL-REBUILD worktree, never
committed there or here). Did not touch `stronghold.gd`, `landmark.gd`,
terrain/grass/scatter configs, species/spawns, opening/gate files, camp
files, `objectives.json`, `performance.json`, or UI.

## Merge note

`origin/main` did not move during this session (checked at push time,
`1d7fc8e7`). Nothing to merge forward.
