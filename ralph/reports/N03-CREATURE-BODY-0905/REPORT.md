# N03-CREATURE-BODY-0905 — report

Lane: **N03-CREATURE-BODY** (Fable), 2026-09-05 follow-up round. Session title:
*"CL-G7 material bug + play_rest signed-roll bug"*.

Branch: `ralph/N03-CREATURE-BODY-0905`, from `origin/main` at `f8a47ee4`.
Final commit: **__FINAL_COMMIT__**.

**One line per item, up front. Detail below.**

| Item | Verdict |
|---|---|
| CL-G7 — `ERROR: Parameter "material" is null.` at `material_get_instance_shader_parameters` on every world boot | **root-caused and fixed** in `creature_body.gd::_build_model()`'s teardown; probe and world-boot smokes clean |
| `play_rest()` signed-roll grounding — negative-roll species (terrapup, trailpup) sink under the creature bed | **fixed** (`radius * abs(sin(roll))`), pinned by a new unit test seen red first |

**A note on the brief.** `ralph/briefs/0905-followup/COMMON.md` and
`N03-CREATURE-BODY.md` were never pushed to the remote — no branch on `origin`
carries a `ralph/briefs/0905-followup/` directory (checked with `git ls-remote`
and by listing every `ralph/*` branch), and no peer session was reachable to
supply them. The lane was reconstructed from the session title, the CL-G7 row in
`docs/GATE2_GATE3_CLOSURE_PLAN.md` §2.B, and W12-COMPANION's routing note on
`play_rest()` (`ralph/reports/W12-COMPANION-0904/REPORT.md` §6). The report
follows `docs/AGENT_WORKFLOW.md` §4's completion contract and the 0904 lanes'
report shape. If COMMON.md asked for something beyond that, it is not here.

---

## Files changed

Game code:

- `scripts/creatures/creature_body.gd` — `_release_art()` (new) and its call from
  `_build_model()` (CL-G7); the `abs()` in `play_rest()`'s grounding term and the
  comment that explains it.
- `scripts/creatures/companion_presence.gd` — **comment only**: the routing note
  that pointed at `play_rest()`'s latent dip now says where it was fixed. No code.

Tests:

- `tests/test_creature_rest_pose.gd` (+ `.uid`) — new. Three tests on real bodies
  built from the shipped GLBs, detached from the tree the way
  `test_companion_presence.gd` is.

Tools:

- `tools/_probe_null_material_rebuild.gd` (+ `.uid`) — new. The CL-G7 isolation
  probe, three modes.

Docs:

- `docs/CURRENT_STATE.md` §3 — two rows (P2 bed pose, P3 CL-G7), both marked fixed.
- `docs/GATE2_GATE3_CLOSURE_PLAN.md` §2.B — the CL-G7 row's claimed-by / kind.
- `docs/GATE3_EXECUTION_PLAN.md` §6 — one sentence under the existing bullet.

No data, scene, asset, config or CI change. No new mesh, no Meshy, no decision
record (nothing here is a design choice).

---

## What changed, in player-facing terms

**A Terrapup or Trailpup put to sleep in a creature bed now lies ON the bed.**
Before, both species rolled onto their side and then sank most of a body-height
into the ground under the bed — terrapup's low side 1.24 m below the bed line,
trailpup's 0.61 m. Every other species was and is unaffected.

**Every world boot's log no longer opens with an engine error.** Nothing the
player sees changed for CL-G7 — the error was non-fatal in every lane that saw
it — but the closure plan named it for the reason it matters: an unexplained
`ERROR:` at the top of every boot log is exactly the noise that hid the
title-screen null call for weeks.

---

## Per item

### CL-G7 — the null-material engine error — **root-caused and fixed**

**The symptom, as every band report recorded it:**

```
ERROR: Parameter "material" is null.
   at: material_get_instance_shader_parameters (servers/rendering/dummy/storage/material_storage.cpp:264)
       [0] _build_model (res://scripts/creatures/creature_body.gd:492)
       [1] apply_size_multiplier (res://scripts/creatures/creature_body.gd:1403)
```

Line 492 is the teardown of the old art at the top of `_build_model()`:
`for child in _model.get_children(): child.free()`. The caller is
`burrow_warrens.gd::_dress_the_guardian()`, which re-sizes the Warren Guardian
straight after `spawn_wild` has built and dressed it.

**Reproduced in isolation** with `tools/_probe_null_material_rebuild.gd`: one
burrowback body in an otherwise empty tree, `set_alpha(true)` (which gives each
surface a `_alpha_rim` duplicate material) then `apply_size_multiplier(1.35)` —
the guardian's exact call order, nothing else in the scene. Before the fix:

| Probe mode | What it does | Result before fix |
|---|---|---|
| `same-frame` | dress and resize in one frame (the guardian's real order) | **2 errors**, one per rebuild |
| `next-frame` | one rendered frame between dressing and resizing | **2 errors** — so it is not a frame-timing race |
| `hold-materials` | keep a reference to every material the dressed art wears across the first rebuild, change nothing else | **1 error**, on the second (un-held) rebuild only |

The third row is the finding. Holding the materials alive removes the error for
exactly the rebuild they were held across, so the null material is an override
the freed MeshInstance3D was the last holder of. The mechanism: the dressing
passes (`_rim_light_node`, `_brighten_node`, `_night_floor_node`, the warrens'
own `_wire_self_light`) set a duplicated material as a surface override, held
only by that node. When the node is freed, C++ destroys the derived class's
members — the `Ref<Material>` overrides — before the `VisualInstance3D` base
destructor runs, so the material's RID is freed first; the base destructor then
calls the rendering server's `free(instance)`, which flushes the instance's
pending update and walks its surface materials, finds a RID that is set but no
longer resolves, and prints the null-parameter error from
`material_get_instance_shader_parameters`. Why the server's own freed-material
notification does not clear the RID out of the instance first was not traced
into the engine; the `next-frame` row shows it is not a matter of the instance
having been rendered once, and the fix does not depend on the answer.

**The fix**, `_release_art(node)`: walk the old art, clear every surface override
(`set_surface_override_material(surface, null)`) and `material_override`, then
free. The pending update then falls back to the shipped mesh material, which the
GLB keeps alive. It is the teardown's job to do this, not each dressing pass's,
so any future dressing pass that duplicates a material is covered.

After the fix, all three probe modes print no `ERROR` line, and neither does a
second species at a different multiplier (`terrapup 1.5`).

**On the real path**, one world boot each, grepped for `^ERROR:` and the exact
message: see Validation below.

**Not changed:** `burrow_warrens.gd`. The band reports filed this under
"guardian dressing" because that is the caller; the defect was in the body.

### `play_rest()` signed roll — **fixed**

W12-COMPANION found and fixed this arithmetic in `companion_presence.gd`'s camp
roll and wrote, in code and report, that `creature_body.gd::play_rest()`
"carries the same signed form for the bed pose and so has the same latent dip on
the two negative-roll species (terrapup, trailpup)", routing it rather than
touching a file outside its ownership. Verified rather than assumed: with the
signed form the new test fails at

| Species | `rest_roll_deg` | radius | pivot y (signed) | low side under bed line |
|---|---|---|---|---|
| terrapup | -45 | 0.875 | -0.738 m | **1.237 m** |
| trailpup | -45 | 0.429 | -0.423 m | **0.607 m** |

The grounding term was `_radius * sin(roll_rad)`; it is now
`_radius * absf(sin(roll_rad))`. Rolling a body either way dips its low side by
about a radius, so the correction is a lift in both directions. The sideways
re-centre keeps its sign on purpose — which way the body fell is what it means —
and the test asserts that too.

After the fix (`tools/_diag_rest_roll_math.gd`, real GLB, bind pose): terrapup's
pivot sits at y = +0.498 and its body-space AABB bottoms at -0.180 (the deliberate
0.12 m bedding sink plus fit geometry, against ~-1.42 before); trailpup's pivot
at +0.183, AABB bottom -0.006. `tools/_measure_bed_roster_fit.gd` still reports
every one of the 24 species `OK` inside the bed rim ellipse (terrapup's
`max_r/rim` 0.97 — it was always the tightest fit and the roll angle is unchanged).

Positive-roll species are unaffected by construction (`abs(sin)` equals `sin`
for them) and `test_positive_roll_is_unchanged` pins mudsnout's lift to the
pre-fix number. The zero-roll opt-outs (bramblebun, galecrest, veridian) route
through `play_faint()` before the term and are pinned too.

**Not rendered.** This container has no GPU; the fix is asserted on the geometry
directly, the way W12's own test does. A bed-pose capture round
(`tools/_capture_bed_species.gd`) on a GPU machine would show it, and is the
natural place for the next visual pass to look.

---

## Validation

### Seen red first

`test_creature_rest_pose.gd::test_negative_roll_lifts_not_dips` against the
unfixed `play_rest()`:

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_creature_rest_pose
  FAIL  test_creature_rest_pose.gd :: test_negative_roll_lifts_not_dips
          (terrapup: a roll grounds by LIFTING the pivot; it dipped 0.618m instead)
          (terrapup: the rolled model's low side is 1.237m under the bed line (roll -45.0 deg, pivot y -0.738))
          (trailpup: a roll grounds by LIFTING the pivot; it dipped 0.303m instead)
          (trailpup: the rolled model's low side is 0.607m under the bed line (roll -45.0 deg, pivot y -0.423))
3 tests, 20 assertions, 1 failed
```

The CL-G7 probe's before-fix output (2 / 2 / 1 errors by mode) is the equivalent
red for the other item.

### Unit

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_creature_rest_pose,test_companion_presence
30 tests, 164 assertions, 0 failed
```

Full suite, same command without `--only`: __UNIT_FULL__

### Runtime validation, on the real world

Each of these boots the Meadows world (the guardian is dressed during
`burrow_warrens` population) and is the path that used to log the error once per
boot:

__SMOKE_TABLE__

### Not run

No visual judge round: no GPU here and the change is geometric. No CI run had
finished at the time of this report; the branch carries no `[skip ci]` on its
final commit, so the push run is the verification to read.

---

## Known limitations, and what was deliberately not done

- **`burrow_warrens.gd` untouched.** The defect was in the callee.
- **No other teardown was changed.** `_build_model()` is the only place
  `creature_body.gd` frees dressed art. `character_model.gd` frees through
  `queue_free()` (deferred), which does not have the same ordering, and it was not
  in this lane's scope.
- **The bed pose is fixed for the two negative-roll species and unchanged for all
  others.** Whether -45 is the right angle for terrapup and trailpup is a
  tuning question `species.json` already owns and this lane did not reopen.
- **The `.uid` sidecars the import generated for the Cloudreach scripts** on
  `main` (`autoload/realm_heart_state.gd.uid` and eight others) were left
  untracked and are not in this branch: not this lane's files.

## For the landing lane

Two code files, one comment-only, plus test/tool/docs. No conflicts expected with
anything on `main` at `f8a47ee4`. Decision numbers: none taken.
