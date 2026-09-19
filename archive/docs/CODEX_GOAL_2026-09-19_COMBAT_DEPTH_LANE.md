# Codex goal — combat depth lane, 2026-09-19

**Scope authority:** `docs/owner/OWNER_DIRECTIVE_2026-09-19_LANE_RESTRUCTURE_CONTENT_AND_COMBAT_SPLIT.md`
splits this out of the Meadows lane so combat work stops competing with content
and visual work for the same session. Also read
`docs/owner/OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md` for
the render-lock file and plan/results checkpoint mechanics — they apply to this
lane too, as the fourth lowest render-lock priority (Meadows, Cloudreach,
Combat, then the Stormwood/Water survey).

## Start here

**Verify current implementation state before assuming anything is built.** The
2026-09-12 owner playtest approved a decision — the dodge/step-back verb is
Option B, the burst step, per `docs/specs/COMBAT_DEPTH_PLAN.md` §5 — but no
combat code has actually changed since; the Meadows lane's work in the
intervening week was entirely Gate F campaign/harness work, not combat. Read
`combat_manager.gd`, `wild_creature.gd`, `combat_ai.gd`, and `combat.json`
directly rather than trusting any doc's claim about what's already built.

Work `docs/specs/COMBAT_DEPTH_PLAN.md` §8's sequence, in order:

1. **COMBAT-1**: poise, stagger, player wind-up interrupt, hitstop, flinch
   (§4.2, §4.5). No new buttons. This is what ends "hold RT and win."
2. **COMBAT-2**: creature wind/stamina (§4.1), per-species caps, satiety/bond
   ties.
3. **COMBAT-3**: telegraph retune (0.55s -> 0.8s baseline) and the burst step
   (§5) — the owner-approved dodge verb. `A` on the pad becomes a short,
   wind-costed directional dash, no invulnerability frames.
4. **COMBAT-4**: the Y-skill slot and level-based learnsets (§4.3) — new
   `slot: "skill"` moves in `moves.json`, a `learnset` per species,
   `progression.gd` learning on level-up, Team screen "next move at level N".
5. **COMBAT-5**: the opponent answers back (§4.4) — AI charged-move use,
   wind-up reaction, low-health behavior per G-3 profile, officer skill use.
6. **COMBAT-6**: widen the type chart from 1.25/0.8 to 1.5/0.67, scale VFX by
   effectiveness, re-run the tournament and Warden smokes since both were
   tuned on the old chart.
7. **COMBAT-7**: the early fight ladder (§6) — dialogue and profile authoring
   only, no new code, using the ladder table already specified.

Use the two-pilot measurement harness in §7 (`smoke_combat_baseline.gd`'s
MASHER, plus a new READER pilot) to prove each step actually changes the
button-mash math, not just that code compiles.

## What is explicitly out of scope

- Anything not in `COMBAT_DEPTH_PLAN.md`'s ladder. Two decisions in that plan's
  §9 are still genuinely open and NOT approved by any owner directive: item 4
  (moves learned by level vs. TM-only — actually already answered by COMBAT-4
  above, level-based) and item 6 (the type chart widening — approved above as
  part of COMBAT-6). If you find a decision point not already resolved in this
  document or `COMBAT_DEPTH_PLAN.md` itself, stop and ask rather than invent.
- Meadows content/visual work, Cloudreach, Stormwood, Water. This lane is
  combat systems only.
- A second simultaneous opponent, combos longer than one move, blocking of any
  kind, held inputs, a separate combat scene, human weapons, or any change to
  catching or the five-creature rule — all explicitly excluded by
  `COMBAT_DEPTH_PLAN.md` §8 itself.

## Process

Write your plan to `ralph/reports/COMBAT-0919/PLAN.md` before implementing,
covering which step(s) of the seven you're starting with and why, your test
plan (including the two-pilot harness), and render-lock handling for any
capture (Warden/tournament smokes may want a visual check, though most of this
work is headless-testable). Hold for
`ralph/reports/COMBAT-0919/PLAN-APPROVED.md`. Write results to
`ralph/reports/COMBAT-0919/RESULTS.md` as work progresses.

Steps 1, 2, and 6 are the cheapest to validate (config-plus-small-code,
judgeable within a normal session). Steps 3 and 4 are larger. Do them in order;
don't skip ahead to a later step because it looks more interesting.
