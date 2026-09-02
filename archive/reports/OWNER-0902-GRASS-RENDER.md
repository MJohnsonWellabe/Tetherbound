# OWNER-0902-GRASS-RENDER — grass is off on purpose; a cheaper "on" now exists but is unproven on hardware

`branch: ralph/OWNER-0902-GRASS-RENDER` · `owner report: 2026-09-02 playtest, item 1` ·
`harness: tools/perf_render_stats.gd, tools/run_tests.gd --only=grass_field`

The owner's words: "the grass didn't render." This investigation had one job:
find out whether that is the intended effect of `OWNER-0901-PERFORMANCE-LAG-V2`
(which turned `grass_field` off the day before, for a measured ~10fps
game-breaker) or a second, new defect stacked on top of it — and, per
CLAUDE.md's precedence rules and the coordinator's brief, not to assume the
answer either way.

## 1. Is grass on or off right now?

**Off.** `data/config/grass_field.json`'s `enabled` is `false` on `main`
(`20c6e78a`, 2026-09-01). This is the documented, deliberate state: the flag's
own `_comment_enabled` says "OFF BY DEFAULT... a bad handheld result has to be
one boolean away from gone" and the 2026-09-01 note records exactly that
handheld result. The owner's "the grass didn't render" is that flag doing what
it was flipped to do the day before — **not a new bug**.

Re-verified independently this session, not just read off the config: fetched
the project's pinned Godot 4.7-stable, imported the project, and reran
`tools/perf_render_stats.gd` at `band1_open` on unmodified `main`. Result:
9,204,537 primitives — matching the 2026-09-01 report's own `enabled=false`
figure of 9,250,290 to within run-to-run noise. The tool and the measurement
both reproduce cleanly in this container.

## 2. Does a cheaper middle ground exist?

Partially, and it is real, not guessed — every number below was produced by
the same tool the 2026-09-01 fix used, in this same container, not estimated.

**What was tried.** The 2026-09-01 report already rejected "halving a few
counts" as unprovable — a proportionate half-cut still leaves multiple
millions of uncullable primitives on an architecture nobody can measure GPU
cost on here. So this went further: `tuft_count` 300,000 → 75,000 (4x),
`blades_per_tuft` 6 → 4, `blade_segments` 4 → 3, `stones.count` 90,000 →
25,000 (3.6x), and all three `cover_tiers` counts cut 2.5-3.3x
(`bushes`/`flowers` 14,800 → 6,000, `litter` 49,000 → 15,000) — a compounding
cut across every cost lever in the file at once, not one knob.

**Measured**, `tools/perf_render_stats.gd` at `band1_open`, same bake, only
`grass_field.json` changed:

| config | primitives | vs. game-breaker | vs. shipped (off) |
|---|---|---|---|
| `enabled: false` (shipped) | 9,204,537 | 29% | — |
| `enabled: true`, thinned (this branch, not shipped enabled) | 13,692,485 | 43% | +49% |
| `enabled: true`, 2026-08-27 config (the game-breaker) | 31,757,567 | 100% | +245% |

The field's own contribution drops from 22.5M primitives to about 4.5M — a
~5x cut — and the whole scene lands at 43% of the primitive load that produced
the owner's ~10fps report. Draw calls barely move in any of the three rows
(consistent with `PERF-ROG-GPU`'s standing finding that the Compatibility
renderer counts MultiMesh batches, not instances), so this is the same
vertex/fragment-bound picture as before, just a much smaller version of it.

**Does it still look like grass?** A player-eye-height screenshot at the same
`band1_open` site (`ralph/reports/OWNER-0902-GRASS-RENDER/shots/band1_eye_level_thinned.png`)
shows a real, legible ground cover — visible tufts at multiple distances,
clover/bush-shaped ground plants, pale flowers — not a bald or broken field.
This is a sanity check, not the project's usual blind visual-judge pass
(no reference-art comparison, no second reviewer), so treat it as "does not
look obviously broken," not "approved."

**What this is not.** It is not the architectural fix the 2026-09-01 report
named as the real answer — actual per-instance/tile distance culling (e.g.
`RenderingServer.instance_geometry_set_visibility_range` per lattice layer, or
splitting the ring into camera-distance-gated MultiMeshes) is still unbuilt.
Every item in the ring, thinned or not, is still submitted every frame
regardless of where the camera is looking. This is the same lever the file
already documented — the counts — pushed harder and actually measured, not a
new mechanism. And it does not clear a real-device A/B: `PERF-ROG-GPU` still
records that GPU-bound frame time on the Ally is the one thing no container in
this project can measure, and that is exactly what a ~10fps result was.

## 3. What shipped on this branch, and what didn't

`data/config/grass_field.json`: the five cut counts above, landed, with a
dated comment (`_comment_enabled_ownerplaytest_20260902`) recording this
measurement in place, the same pattern the 2026-09-01 fix used. **`enabled`
stays `false`** — unchanged. This is not a tuning call this session gets to
make unilaterally: the flag's whole design point, restated in three separate
comments across two owner playtests now, is that turning it on is a decision
reserved for a real handheld pass, not for whichever container happens to be
measuring it. What changed is which numbers that flag will submit the next
time someone (owner or lane) does flip it — a config that is provably ~5x
cheaper than the one that just broke the game, instead of the same one again.

The old, denser numbers are recorded in the new comment's last sentence in
case the owner wants to A/B the original density instead of this cut one from
scratch: `tuft_count 300000 / blades_per_tuft 6 / blade_segments 4 /
stones.count 90000 / bushes.count 14800 / flowers.count 14800 / litter.count
49000`.

Verification: `tests/run_tests.gd --only=grass_field` — 10 tests, 61
assertions, 0 failed, against the new counts. The suite's own ceilinged
assertions (`field_radius <= 72`, `tuft_count <= 300000`) are ceilings, not
exact-value pins, so cutting further inside them needed no test change.

## 4. The actual ask for the owner

This is the "ask instead of inventing" case CLAUDE.md names directly: no
container available to any lane can tell you whether 13.7M primitives (or any
other number short of the old 31.7M) is affordable on the ROG Ally's real
GPU — only the Ally can answer that, and the owner is the one who can run it
there. Two honest options, not a recommendation:

- **Leave it off.** Zero risk, zero grass, matches what shipped and what the
  owner has already played.
- **Flip `enabled: true` and play it on the Ally.** This branch's numbers are
  the ones it will submit if you do — a real, measured 5x-cheaper version of
  the config that broke the game, not the original. If it still lags, the
  next lever is further cuts to the same five numbers (still bounded by the
  test ceilings), or waiting for the unbuilt distance-culling architecture
  the 2026-09-01 report already named as the actual fix; if it's fine, it is
  the first grass config ever confirmed on real hardware rather than shipped
  on a guess.

Not done, and flagged rather than silently skipped: a blind visual-judge pass
of the thinned config against the project's reference art (every other
density change in this file went through one; this one only got a sanity
screenshot), and the real per-instance culling architecture itself.
