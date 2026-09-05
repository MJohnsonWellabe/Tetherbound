# Blind judge — round 2 (frames `shots/vfx/0*` at `0089b1bc`, sheet `_sheet_round2.png`)

Code-blind sub-agent (opus), given only the sheet, the ten frames, `docs/reference/` and the
visual-judge skill; told nothing about what changed or what this lane hoped it would say. It
was given `00-squared-up` as a control and asked what each later frame adds over it.

## The bars moved

| | Round 1 | Round 2 |
|---|---|---|
| **A** — belongs to the key art's world | no | **yes** (weakly; "the light, not the world" is the residual) |
| **B** — the same kind of game as Palworld | no | **yes** ("the genre read is unmistakable") |

Round 1's verdict on `03` was that the ring read as a stun. Round 2: the amber torus is
*"the only effect in the entire set that survives the 30% test"* and *"clearly an aura"* —
the level-up is the frame the judge says gets closest to working.

## What it still says is wrong, and who owns it

**This lane's, fixed in the round-3 pass below:**
1. *"Flat tan rectangles… visible straight edges and square corners… no internal detail"* —
   the streak quads. Ranked the loudest defect in the set.
2. *"The entire body is flooded with a flat gold-amber tint"* that *"erases the separation
   between shell plate and fur"*, and makes being hurt and being rewarded the same picture —
   the rim glow at `rim_flat_mix` 0.38 / strength 1.1, raised in round 2 and a regression.
3. The level-up ring reads as *"one flat annulus decal"* because its near and far edges both
   draw in front of the creature.
4. Effects sit at the meadow's own hue: *"the effect is tan-to-amber, sitting on tan fur, in
   front of yellow-green sunlit grass."*

**Not this lane's, routed to the coordinator:**
- The white chevron above the creature clipping its ear (`target_marker.gd`).
- The blue-grey water plane cutting through the boulder and fence in `03` (world/water).
- The catch resolve camera parking inside the creature in `04` (`catching.json`
  `resolve_camera`) — the judge calls that frame *"indistinguishable from a bug"*, and it is
  the framing, not the sparkle.
- HUD: the day/time readout drawn under the enemy nameplate; the roster reading Lv 3 while the
  active card reads Lv 4 in the same frame; overlapped text in the bottom-left card.
- The enemy staged as a 35-pixel dot while the ally fills a third of the screen.
- Hit-reaction, knockout and capture-sequence **animation** — named by the judge as needing
  art that is not in the build, and out of scope for a VFX lane.

## Round 3 (this lane's four fixes, geometry and tunables only)

- **Streaks are soft on every edge.** Alpha now falls off across the width as well as along
  the length: a bright centre line, transparent side edges, fading to nothing at the tail,
  plus a round head so a spark reads as a bright point that left a trail rather than a shard.
  No hard corner remains in the effect.
- **Halos are near-black** (`darkened(0.82)`) instead of a darker version of the tint — a dark
  tan halo behind a tan mote on tan fur was more of the same hue.
- **The rim is a rim again**: `rim_flat_mix` 0.38 → 0.10, `rim_strength` 1.1 → 0.8, and the hit
  flash's `flat_mix` 0.7 → 0.3. The fresnel carries it; the body keeps its material separation.
- **The flourish is split across two surfaces**: the beam stays un-depth-tested (it runs
  through the body), while the rings and motes are depth-tested so their far halves pass
  behind the creature — `alpha_aura.gd`'s own stated reason, and the fix for "flat annulus".
- **Sparks stay white-hot longer** (`heat` 0.92, cooling over a longer fraction of life, a
  white core) so the mark that lands is a colour the meadow does not contain.

Round 3 is a third round against the two-round guidance in `COMMON.md`. It is taken because
the top-ranked finding is a **structural artefact with a geometry fix** (untextured quads with
hard corners), not another pass of size-and-colour tuning, and because fix 2 repairs a
regression this lane introduced in round 2. It is the last round; the ceiling and the
unjudged status of its frames are recorded in `REPORT.md`.
