# OWNER-0901-PERFORMANCE-LAG-V2 — the ~10fps game-breaker, root-caused

`branch: ralph/OWNER-0901-PERFORMANCE-LAG-V2` · `owner report: 2026-09-01
playtest, item 2, named a game breaker` · `harness: tools/perf_render_stats.gd`

The owner's words: "Severe lag -- frame rate collapsed to ~10 FPS." Their own
hypothesis was the minimap re-rendering every step. A prior lane
(`ralph/OWNER-0901-PERFORMANCE-LAG`, now idle/archived) had started bisecting
toward `grass_field.gd`/`grass_field.json` but landed nothing beyond two
`.uid` companion files -- no finding, no fix, no measurement. This branch
starts from that same suspicion and actually measures it.

## The minimap hypothesis: already fixed, not the cause

`scripts/ui/minimap.gd`'s own header records `OP23-01`: the fog overlay used
to repaint every cell in a 512x2048 grid on every discovery tick (837ms
measured, 735ms of it `cell_at()`, "the freeze-every-few-feet"). That was
fixed on 2026-08-28 -- the fog texture now patches only the dirty rect
`MapState` tracked, and `_draw()` only fires when the player actually moved
past an epsilon or the map's fog revision advanced. Read cold, the file does
not reproduce "re-renders like every step." The owner's phrase is real
evidence of a *symptom* (the game visibly stutters while walking), not proof
of *which* system causes it -- and general GPU overload while walking through
the meadow would produce exactly the same felt symptom.

## What actually is: `grass_field`, unmeasured on real hardware by its own admission

`data/config/grass_field.json`'s `enabled` flag was flipped `true` on
2026-08-27 (`181b7bf4`, "owner asked for the procedural ground cover in a
playable build") specifically so it could be evaluated on the Ally, with
every comment in the file stating plainly that no container in this project
can measure GPU cost and that the Ally result was the open question. Every
density number added since (`tuft_count` raised to its own test-pinned
ceiling of 300,000, a 90,000-instance stone tier, three cover tiers totalling
another ~79,000 instances) shipped on the same "NOT MEASURED" basis.

**Measured here**, with the project's own `tools/perf_render_stats.gd`
(real `RenderingServer` counters -- draw calls and primitives submitted per
frame are the same structural numbers a ROG Ally's GPU would be handed;
only this box's own frame *time* is meaningless, and none is quoted), at
`band1_open` (open meadow, representative of ordinary walking), same bake,
only the `grass_field.enabled` flag changed:

| state | draw calls | primitives | objects |
|---|---|---|---|
| `enabled: true` (what shipped) | 7320 | **31,757,567** | 6315 |
| `enabled: false` (this fix) | 7366 | **9,250,290** | 6361 |

`grass_field` alone is **22,507,277 primitives -- 71% of everything the
frame draws**, and every one of them comes from its own `MultiMeshInstance3D`
nodes (the tuft ring, the stone ring, and three cover tiers), which carry
**no per-instance distance culling**: everything inside the ring's
`custom_aabb` is submitted every frame regardless of what the camera is
actually pointed at, because the ring is authored to follow the camera and
its AABB essentially never leaves the frustum.

Draw calls barely move (7320 -> 7366, `grass_field` is *fewer* draw calls
off than on because vegetation.gd's baked-scatter layers batch differently)
-- confirming `PERF-ROG-GPU`'s standing finding that the Compatibility
renderer counts MultiMesh *batches*, not instances. The cost here is
entirely vertex/fragment throughput inside those batches, which is exactly
the failure mode a software-rasterised container was always structurally
blind to (frame *time* meaningless) but a real handheld iGPU was always
going to feel directly. That mismatch -- draw calls fine, primitives
catastrophic -- is what a ~10fps collapse with no other symptom (no reported
stutter in menus, dialogue, or indoors) looks like.

## The fix

`data/config/grass_field.json`: `enabled` reverted `true -> false`. One line,
fully reversible, and it is the exact contingency the flag and its
suppression list were built for -- the file's own `_comment_enabled` already
said "a bad handheld result has to be one boolean away from gone rather than
a revert." A dated comment (`_comment_enabled_ownerplaytest_20260901`)
records the measurement above in place, so the next lane does not have to
re-derive it.

**Why not just cut the counts instead of going fully off** (the file's older
guidance: "tuft_count... is the first number to cut if the Ally says no"):
grass blades are ~68% of `grass_field`'s own 22.5M primitives
(`tuft_count` x `blades_per_tuft` x `blade_segments` x 2 tris/segment), so
even a proportionate half-cut across every tier leaves multiple millions of
primitives riding on the same uncullable architecture that just produced a
game-breaking ~10fps result -- and there is no way to verify from this
container that a smaller number is safe without another real-device round
trip, which is guessing dressed up as a number. Reverting to the documented
default is the one lever provable from here: it is a measured 3.4x primitive
cut back to the corridor's previously-shipped configuration, which was never
flagged as laggy in any owner playtest before `grass_field` shipped on.

**What would be a real fix for `grass_field` itself**, left for whoever
revisits it: actual per-instance or per-tile distance culling (e.g.
`RenderingServer.instance_geometry_set_visibility_range` per lattice layer,
or splitting the ring into multiple MultiMeshes gated by camera distance so
far layers stop submitting instead of only fading their shader output),
not smaller counts on the same all-or-nothing architecture. That is
unbuilt and belongs in front of the flag next time, not behind it.

## Verification

- `godot --headless --path . --script tests/run_tests.gd -- --only=grass_field`
  -- 10 tests, 61 assertions, 0 failed. The suite already handles both
  states of the flag (`test_the_flag_and_the_suppression_list_agree` asserts
  the flag and the suppression list agree whichever way the flag is set), so
  turning it off is a covered, not merely permitted, state.
- Full suite (`tests/run_tests.gd`, no filter) run in the background against
  this change; see the branch's CI run / this session's follow-up for the
  final tally.

## Reproducing the measurement

```
GODOT=/root/.cache/tetherbound-art/godot   # tools/art_pipeline/setup.sh godot fetches this fresh in a new container
$GODOT --headless --path . --import        # required once; this container has no .godot/ cache

xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --path . \
  --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/perf_render_stats.gd -- --label=grass-ON --views=band1_open
# then flip data/config/grass_field.json's `enabled` and repeat with --label=grass-OFF
```

Never add `--headless` to that second command -- it hangs forever combined
with a real rendering driver, and even if it did not, the Dummy driver
reports zero for every `RENDER_*` monitor, which is the number this
measurement exists to read (`tools/perf_render_stats.gd`'s own header,
`ralph/conventions.md`).
