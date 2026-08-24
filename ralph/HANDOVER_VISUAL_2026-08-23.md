# Handover — the whole-game visual sweep and the choke points

Written to be picked up cold. Branch: `ralph/VISUAL-CORRIDOR`.

## What this was

**Owner directive, 2026-08-23:** the visual coordinator runs across the ENTIRE
game — "the ground, HUDs, every menu screen, every build, every asset type,
every region, every character, every creature, every tool, every consumable and
gatherable, every terrain, every pre-built building. The whole game relies on
all of this looking great. This is the most important ongoing task."

Pipeline, as the owner set it: **Sonnet captures → Fable judges and plans →
Sonnet executes**, repeating until `ralph/conventions.md`'s convergence rule
stops it. `ralph/OWNER_DIRECTIVES_2026-08-22.md` §5 is binding: blind review is
Fable-only and never judges evidence it produced.

## Where to start reading

1. `ralph/VISUAL_LEDGER.md` — the standing ledger. Domain table, what recurs
   across critics, this sweep's own harness defects, and the corrections.
2. `ralph/lanes/VISUAL_SWEEP_LANES.md` — the five parallel lanes, their file
   ownership, and the one rule that prevents the expensive conflict.
3. `ralph/reports/VISUAL_*_2026-08-23.md` — five blind verdicts with evidence.
4. `ralph/reports/CHOKE_POINTS_2026-08-23.md` — the impassability work.

## State of the eight visual domains

All eight judged blind at least once; corridor and creatures twice. **Every bar
question came back NO except two narrow yeses** (corridor B "trying", creature A
round 1, which round 2 reversed). Neither round-2 domain converged — both named
new defects, which is `conventions.md`'s definition of a round that improved.

Five sibling sessions own the ongoing work and are pushing to
`ralph/VIS-UI`, `ralph/VIS-WORLD`, `ralph/VIS-SITES`, `ralph/VIS-CAST`,
`ralph/VIS-MAKE`. **They are ahead of this branch.** VIS-WORLD has replaced the
photographic ground with generated stylised surfaces — a real art-direction
change nobody here has folded into the ledger yet. That is the biggest unread
item.

## The choke-point work — READ THIS BEFORE TOUCHING THE SIGIL GATE

Owner: *"we are relying on having to cross a bridge or choke point. It needs to
actually be impassable otherwise."*

| barrier | state |
|---|---|
| River / Old Mill Crossing | **SEALED** at 45° and 60°, needed nothing |
| South Bridge gully | **SEALED**, `half_length` 33 → 1040, re-baked, proven |
| Sigil Gate gorges | **see below — unresolved, and the last state is unverified** |

### The Sigil Gate, honestly

The gate leaf is 4.06 m. At the shipped `half_length` 40 the causeway measured
**38.1 m** — the gate covered 4.1 m of it, so it has been very nearly decorative
all along. That part of the owner's directive is real and still open.

**Three failed attempts to close it, each instructive:**

1. `half_length` 45, `end_fade` 14 — solved the ZERO-DEPTH point onto the leaf
   edge. Wrong: `_prepared_carve_depth` multiplies the along-axis smoothstep by
   the across-axis one, so **the cross-slope that actually stops a player scales
   down inside the fade collar**. The wall drops under 45° well before depth
   reaches zero. Real standable gap: 12.5 m.
2. `half_length` 53, `end_fade` 14 — chased the walkability boundary instead,
   but `half_length + end_fade` = 67 reached past the gate's own position
   (u ≈ 61), so both carves' fades overlapped there and `max()`-combining
   **carved a 4.3 m pit directly under the leaf**. Baked height at the gate went
   −1.09 → −5.38. That pit is what players were falling into.
3. `half_length` 58.5, `end_fade` **2.0** — a steep mouth, re-solved so
   `half_length + end_fade` = 60.5 stops 0.5 m short of the gate. Gate centre
   height back to baseline −1.09. Leaves a **1.0 m standable sliver** inside the
   leaf's span, with 2.5–2.8 m of margin against both failure modes.

**Attempt 3 was NOT shipped.** Its walkability was never proven — the container
restarted mid-verification — and a 1.0 m gap against a ~0.8 m player capsule is
exactly how an unreachable finale ships. The branch was deliberately restored to
`half_length` **40.0** (config and terrain together, from `7ab358ee`, so they
cannot disagree): a 33.4 m gap, measured at 38.1 m along the leaf's own axis.
Wide open, unambiguously walkable, **and still leaky**.

So the owner's directive is **OPEN for this one gate**. A leaky gate is better
than an unreachable finale; that ordering is the whole lesson here. Attempt 3's
values (`half_length` 58.5, `end_fade` 2.0) are recorded above and are the right
place to resume — they need one clean `smoke_traversal` run to accept or reject,
and that run is the only thing standing between them and shipping.

Note `end_fade` on the branch is **2.0**, not the 14.0 the chapter originally
shipped with — that came from attempt 3 and was kept because it is what the
restored bake was made from. Restoring the original taper needs a re-bake.

### The deeper problem nobody has solved

`SIGIL_GATE_YAW_DEG` is **−28.6**; the gorges are `axis_deg` **+28.6**. They are
**57° apart**, so the leaf does not sit square in the gap it closes. The owner
approved rotating the gorges to match. That work was started and not finished —
and note the wings (`sigil_gate_gorge_west_wing`/`_east_wing`) are placed
against the OLD diagonals' outward corners, so **rotating the diagonals without
moving the wings opens a new hole in the shoulders**.

## What is fixed and proven

- **The stronghold silhouette moved to the chapter's end.** `landmark.gd` built
  a 132-module castle (four towers, real gate, nine oxblood banners) at
  (229.8, −144.4) — a constant the OW5D migration left behind, 7.5 km from the
  stronghold it exists to loom behind. Now (150.0, 7595.0), **25.7 m clear on a
  separating axis**, plinth reseated (`PLINTH_BOTTOM` −2.5 → −3.0 for 0.93 m
  embedment), `map_landmarks.json` corrected. Tests: landmark 15/15, map 64/64,
  `smoke_stronghold.gd` passes.
  **Still open:** the thing the player WALKS INTO at (0, 7560) is still
  untextured blockout. The castle now looms behind it — that fixes the
  silhouette, not the destination.
- **The Team Tether rank ladder** builds on the previously-orphaned
  `grunt_lod0.glb`; the Warden keeps his own rig; badges escalate by shape and
  are seated on measured chest depth. A new test asserts the invariant.
- **The player's buildable roof** no longer wears Team Tether oxblood.
- **The ice-blue foundations** — a missing glTF `metallicFactor`.

## Traps this sweep paid for — do not re-learn these

- **NEVER `--headless` with `--rendering-driver opengl3`.** Hangs forever, no
  error, leaves zombies. Renders go through `xvfb-run`; `--headless` alone is
  correct for tests and `--check-only`.
- **~2.4 s per awaited frame** on the loaded world under llvmpipe. Budget frames
  and state the arithmetic; a survey that copied single-region counts did not
  reach its first shutter in 17 minutes.
- **A bake that is not re-imported never reaches a capture.** A change that is
  not re-baked never reaches the player.
- **Metallic is never a sheen in this renderer.** No reflection probe, so a
  metallic surface mirrors the sky or returns black. Four defects, each
  diagnosed from scratch as a colour problem. Check for a metallic value first.
- **NINE harness defects.** Six surveys photographed something other than their
  subject; a test declared a present, enabled collider missing; and a test's own
  dialogue panel captured input so every walk after it froze at its start
  position, reading as "the finale cannot be crossed". **When a critic or a test
  reports something alarming, ask whether the harness caused it before believing
  the game did — on this project the harness has been the answer more often.**
- **A `--only=` filter that matches no files reports success.**
  `--only=stronghold` matches nothing; the real test is `smoke_stronghold.gd`,
  outside `run_tests.gd`'s `test_*.gd` discovery.

## Open work, in the order I would take it

1. **Settle the Sigil Gate walkability** (above). Revert if it fails.
2. **Fold the five lanes into the ledger** — especially VIS-WORLD's ground
   rebuild, which bears on the owner's #1 priority and is unread.
3. **The stronghold destination** — bring the castle kit to (0, 7560), or accept
   the silhouette-only fix.
4. **Locations detail rig** — framing fixed and committed, frames NOT re-shot or
   re-judged.
5. **Two recorded, unfixed:** the relay camp's fire shot aims 6.72 m from the
   actual fire (needs a `look` change); the mill has no wheel module at all
   (78 modules, every one a wall, roof, window, corner, border or fence).
6. **The villagers' age** is a DESIGN question, not an art bug — measured head
   counts are villagers 4.9, trainer 5.2, grunt rig 6.5. Ask the owner.
