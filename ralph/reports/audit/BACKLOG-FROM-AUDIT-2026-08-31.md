# Backlog derived from the full-state audit — 2026-08-31

**Not `ralph/BACKLOG.md`.** That file has its own Gate-F regeneration protocol
(§16.2: the reviewer receives run evidence blind, so appending to it out of
band would contaminate that process). This is a separate, dated ledger built
straight from the audit's own evidence — sections A–K (`ralph/reports/audit/
A..K-2026-08-31.md`), `GATE-F-FULL-2026-08-31.md`, `VISUAL-CENSUS-2026-08-31.md`
(in progress), and the owner's 2026-08-30 evening playtest
(`ralph/OWNER_PLAYTEST_2026-08-30B.md`). Every item below cites its source.

## How this is organized

- **Wave 1 (launched 2026-08-31)** — bite-sized, no owner decision required,
  no file overlap with the ten Gate-F-leg lanes currently fixing game systems
  band-by-band. Each is its own `ralph/BACKLOG-<id>` branch.
- **Wave 2 (queued, not yet launched)** — bite-sized but deliberately held
  back because it touches a file or system a Gate-F-leg lane currently owns.
  Launch once the naming lane lands.
- **Needs an owner decision** — a real, cheap fix exists, but which fix is a
  call only the owner can make.
- **Not bite-sized** — real, cited, but multi-day/needs new art/needs a
  played chapter run. Feeds the completion plan directly; no lane assigned.

---

## Wave 1 — launched

| id | item | source | closing cost |
|---|---|---|---|
| `BACKLOG-C1-NESS-FACE` | Warder Ness's face is a black void at conversation range | Audit C1 | ~1hr investigation + re-render |
| `BACKLOG-D6-SEAM-PROBE` | visible terrain seams; clipmap AND generic mip-bias/debug-overlays now ruled out too — cause is named: per-tile detiling rotation in `terrain_ground.gdshader`'s `accumulate_material()` (see `ralph/reports/audit/D6-seam-probe/FOLLOWUP-2026-08-31.md`) | Audit D6 | cause is nameable now; needs a shader fix that softens the per-tile rotation discontinuity without removing detiling (which fixes the 2K-texture-repeat complaint it exists for) — new task, not attempted this session |
| `BACKLOG-I5-OBJECTIVES-TEST` | a test-fidelity bug in the objectives smoke test (not a game bug) | Audit I5 | ~15 min, test-only |
| `BACKLOG-I6-MINIMAP-HEADING` | minimap heading defect, standing, unowned | Audit I6 | ~half a day |
| `BACKLOG-I7-CREATURES-TAB-TEST` | Creatures-tab controller-isolation coverage gap | Audit I7 | ~half a day, new smoke test |
| `BACKLOG-B3-RARITY-LEGIBILITY` | rarity legible on sight fails for 3 of 4 tiers (direct code read, not a rendering judgement) | Audit B3 | code-level, contained |
| `BACKLOG-HUD-LAYOUT` | owner: health bar to lower-left; on-screen day/time tracker; shrink/relocate the main-story tracker | Owner playtest items 19–21 | HUD-only, contained |
| `BACKLOG-KNIFE-SCALE` | "the knife is comically large" | Owner playtest item 13 | mesh-scale only |

---

## Wave 2 — landed 2026-08-31

Held items above were launched once their owning Gate-F-leg lanes reached/passed
the relevant file scope; all five below are on `main` (via `ralph/LAND-BACKLOG-0831-2`),
verified by `git merge-base --is-ancestor` against `origin/main`, not by CI badge alone.

| id | item | source | status |
|---|---|---|---|
| `BACKLOG-F3-GRANDPA-DIALOGUE` | Grandpa Elias has zero dialogue from tournament sign-up onward and no reaction to the ending, while every other named NPC has both (~30 lines, 5 conversations, one read-ladder in `sequence_director.gd`) | Audit F3 | **landed** |
| `BACKLOG-BED-SCALE-POSE` | owner: creature beds too small; creatures stand on beds instead of lying | Owner playtest items 11, 14 | **landed** |
| `BACKLOG-GLOW-PICKUPS-ONLY` | owner: only key items/TMs/orbs/potions should glow; bulk nodes (trees/wood/stone) should not, or grass should clear space around them | Owner playtest item 3, adjacent to Audit D3 | **landed** |
| `BACKLOG-VILLAGE-BERRIES` | owner: "there needs to be more berries in the village" | Owner playtest item 15 | **landed** |
| `BACKLOG-I6-MINIMAP-HEADING-FIX` | minimap heading test compared a net-displacement chord across an OF15 deflection event instead of tail heading | Audit I6 (diagnosis), fix same day | **landed** |

Still queued, unchanged from the original hold reasons:

| id | item | source | why still held |
|---|---|---|---|
| `BACKLOG-NPC-DIALOGUE-TERSE` | owner: "all NPCs talk too much, just have them be short and to the point" | Owner playtest item 5 | tournament/trainer dialogue (Mira/Tam/Oskar/Halda) is inside `S04`'s active scope; do the mechanical terseness pass once S04 lands so it isn't editing files S04 is also touching |
| `BACKLOG-E-SCENE-TUNING` | E1 (village orientation fails by day), E3 (Team Tether occupation absent), E4 (2 of 3 camps fail as rest points), E5 (Warrens dressing/lighting) — all flagged "scene-tuning, cheap" | Audit E | camp/village/Warrens scenes overlap `S03`, `S06`, `S09` — sequence after they land |
| `BACKLOG-VILLAGE-LAYOUT` | owner: "the village layout is still terrible"; village NPC spread (owner items 4, 16) | Owner playtest + Audit E1 | placement of Mira/Tam/Oskar/Halda affects the tournament and practice systems `S03`/`S04` depend on; touch only decorative NPCs, after those land |

---

## Needs an owner decision (real fix exists, no lane assigned)

- **C4** — Mira, Tam, Oskar, Old Bram fail "named characters individual" (two sex mismatches measured). An Option A/B decision is already on record; closing it is config-only once chosen.
- **C3** — two stylistic Team Tether bodies, cosmetic-only either way.
- **I4** — a harvest bare-hand doc/code drift, needs a small owner call plus ~1hr.
- **D5b** — the river reads as a canal; rim noise + regen exists as a fix, bank-angle change is capped pending an owner call. (Same defect the owner's own playtest item 8 names independently.)
- **D7** — aerial-perspective horizon-band limit needs an owner fog decision.
- **G4/G5** (from the earlier exit-criterion audit pass) — bands 4–5 introduce zero new catchable species; the challenge ladder's typing axis is flat across all 27 rungs. Both are content/design-scope, not bugs.
- **G3/roll_new_worlds** — `D-0830-1` stays off pending Gate F re-baseline; sequence after the Gate-F-leg lanes land.
- **STALE-GATE_AT** — `scripts/world/playground_world.gd::GATE_AT` is still `(27.5, -16.0)`, the pre-OP-0830-1 gate position; its own doc comment already says the real gate is "the point where that line crosses this road — (38.7, -19.9)" (`village_boundary.json`'s `RoadGate`, correct), but the constant itself was never updated to match. Found reconciling `GATE-F-LEG-S10CDE`'s merge, which had aimed a walk at the stale value and still passed (dead code: `GATE_AT` is never actually passed to anything that builds or checks a real interactable — only referenced in its own and a neighbour's comments — so nothing player-facing reads the wrong number today). Harmless now; worth a one-line fix before anything is ever wired to it.
- **TOURNAMENT-SEMI-DIFFICULTY** — `GATE-F-LEG-S04`'s isolated tournament run lost the semi-final to the same pattern 5+ times running (a Mosshell charged hit for 87.8 damage, one-shotting a creature at 64% HP) before the lane was cut off for unproductive iteration (13 runs, no stable result, its one behavioral change attempted a reactive auto-switch-on-faint that would have reversed `combat_manager.gd`'s documented D32 design — not that lane's call to make; discarded, not merged). `data/creatures/species.json`'s own mosshell entry admits "nobody has fought one yet." Potion/revive healing between rounds does work (confirmed by the same lane). At `tournament.json`'s own documented minimum entry state (`min_party_size: 5`, `min_level: 6`, checked against the five strongest of an owned team), this may be genuinely too hard for a blind first attempt, or it may be a scripted-battler-AI artifact (no real player uses potions/switches as reactively as a crude auto-battler). Needs either an owner balance pass on Mosshell's charged-move damage, or a real (human or better-scripted) playtest of the semi-final specifically before concluding it is actually too hard. Not fixed here.
- **B2-GRASS-SEPARATION** — `BACKLOG-B2-GRASS-SEPARATION`'s own lane swept Bramblebun's full safe height range (0.86m, the "too small to see" clearance floor, through 1.15m) and confirmed no point in it restores the pre-redesign 1.06-1.15 grass-separation ratio; `field_rim` was already proven a no-op-to-negative lever. Left at the already-best point in range (1.00m / rim 0.0), not silently reverted. Closing this for real needs an albedo/value change to the `bramblebun_redesign` mesh (a new Meshy generation, which CLAUDE.md gates on owner-supplied reference art) or an owner-approved size push past "modest." Full method in `ralph/reports/audit/BACKLOG-B2-GRASS-SEPARATION-2026-08-31.md`.
- **D6-SEAM-PROBE-FIX** — `BACKLOG-D6-SEAM-PROBE-FIX` tried three fix mechanisms against the per-tile detiling rotation named in `FOLLOWUP-2026-08-31.md` (boundary feather, footprint-vs-tile-size fade, Terrain3D bilerp/region_mip fade) plus surgical single-component tests; none removed the seam at the reference camera stand. Real new findings, not a stall: zeroing BOTH detiling components (rotation and shift) together via shader code does remove the seam, matching the known-good A/B, so a fade is mechanically the right shape — the missing piece is the trigger condition. The footprint-vs-tile-size theory is ruled out directly (measured <0.02 tile units via a lighting-independent EMISSION readout, nowhere near the "spans multiple tiles" threshold it needed). The strongest untested lead: this may be a control-map paint-boundary artifact (path texture meeting grass, i.e. `texture_id[0]` changing) rather than a same-texture detiling-tile artifact at all — a fade on `blend`/neighbouring-texel `texture_id[0]` divergence, not tile position, would follow directly if confirmed. The branch reverts `shaders/terrain_ground.gdshader` to a verified 0-line diff from `main` (no behavior change ships from it) and carries every attempt as its own honest commit plus before/after renders. Full writeup: `ralph/reports/audit/D6-seam-probe/SHADER-FIX-STATUS-2026-08-31.md`.

---

## Not bite-sized — feeds the completion plan directly

- **GAME-F2/F4/F5, PROGRESSION-F7, TRAVERSAL-F8** (GATE-F-FULL) — assigned to the ten active Gate-F-leg lanes; not duplicated here.
- **J1/J2** — the open world and the Meadows Hall read as two different productions; the Hall silhouette fix has *regressed* (+33.1 → +11.6) because a later lane landed art on top of it without re-running the measurement. Real, multi-day art/material work; also a process fix (re-run the silhouette probe on every future Hall-exterior landing) that should go in `ralph/conventions.md`.
- **D3** — open-field shape/silhouette interest; the scatter placement-rule defect is a design+code pass, not a bug fix.
- **I3** — progression legibility as a played path cannot be determined without a new smoke test (~half a day) *and* matches the owner's own item 17 ("what do I need for the tournament") — worth a real UI feature once S04 lands, not just a test.
- **J4** — ROG Ally performance; no container can determine this, needs the owner's hardware.
- Owner items 6 (village wall/gate), 7 (TEAM counter drift), 8 (river source), 9/18/22/23 (day/rest/clock — likely one root cause), 10 (building recipes illegible), 17 (training/tournament clarity), 24 (camping build-menu category) — all recorded in `ralph/OWNER_PLAYTEST_2026-08-30B.md`'s own triage; several are already being answered live by the Gate-F-leg lanes (S03's home-building fix, the tournament-requirement work).

---

## Sources

- `ralph/reports/audit/{A,B,C,D,E,F,G,H,I,J,K}-2026-08-31.md`
- `ralph/reports/gate-f-full/DEFECTS.md`, `ralph/reports/audit/GATE-F-FULL-2026-08-31.md`
- `ralph/OWNER_PLAYTEST_2026-08-30B.md`
