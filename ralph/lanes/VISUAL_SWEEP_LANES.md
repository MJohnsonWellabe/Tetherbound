# The whole-game visual sweep — lane contract

**Read this before fixing anything.** Five sessions run the owner's visual
mandate in parallel, each in its own container. This file is how they avoid
colliding, because they cannot message each other — the repo is the channel.

| lane | branch | owns | owner priority |
|---|---|---|---|
| VIS-UI | `ralph/VIS-UI` | HUD + every menu screen | first |
| VIS-WORLD | `ralph/VIS-WORLD` | grass, ground, trees, water, sky, weather | 1 |
| VIS-SITES | `ralph/VIS-SITES` | village, quarry, warrens, relay, stronghold | 2 |
| VIS-CAST | `ralph/VIS-CAST` | humanoid NPCs, then creatures | 3, 4 |
| VIS-MAKE | `ralph/VIS-MAKE` | buildables, prefabs, items, combat | 5 |

All five branch from `ralph/VISUAL-CORRIDOR`, which carries the eight capture
tools, `ralph/VISUAL_LEDGER.md`, and the five round-1 reports under
`ralph/reports/VISUAL_*`.

## The one rule that prevents the expensive conflict

**Only VIS-WORLD re-bakes the scatter, and only VIS-WORLD edits
`data/config/vegetation.json`.**

On 2026-08-23 two lanes re-baked `data/scatter/playground/` from different
sources and produced a 257-file conflict in which **not one source file
disagreed** — every conflict was a derived `.bin`. Neither side of such a
conflict is correct: `scatter_rules.gd::all_placements` is pure and seeded, so
the union is produced by merging the sources and re-baking, never by
`--theirs`/`--ours`. Picking a side silently discards half of one lane's work
and looks like a clean merge while doing it.

If your lane needs a vegetation change, record it and hand it to VIS-WORLD.

## After any bake, re-import before capturing

`godot --headless --path . --import`. A `--script` capture loads the IMPORTED
form out of `.godot/`, so overwriting an asset on disk leaves that cache alone
and the frames come back pixel-identical to the thing you just replaced —
reading as "the change did nothing". This repo has already lost a judging round
to exactly that.

## Findings already settled — do not redo or re-litigate these

- **The buildable wall is NOT warped.** Reported by a critic as slanted with a
  black gap and a lifted corner; disproven by pulling raw vertex data —
  the panel is a clean 2x3 m rectangle, the "diagonal lift" is the intentional
  Tudor V-brace (apex dips 2 mm), the "black gap" is wood-grain and AO. No
  change was made and none is wanted.
- **The player's buildable roof oxblood is fixed** — an invented `albedo`
  override in `build_material_finish.gd`; village roofs are the same module
  untinted, so the fix was deleting the override, not inventing a colour.
- **The ice-blue foundations are fixed** — `MI_RockTrim` ships with no
  `metallicFactor`, so glTF's spec default of 1.0 made it full metal, mirroring
  the sky. **This kit has now caused three reported visual defects the same
  way**; when a material reads as chrome or plastic, check for a missing factor
  before reaching for a repaint.
- **The Team Tether rank ladder is rebuilt** — the three ranks now build on the
  previously-orphaned `grunt_lod0.glb`, the Warden keeps his own rig, palettes
  moved to oxblood, badges escalate by shape, and badges are seated on measured
  chest depth. VIS-CAST's first round RE-JUDGES this rather than rebuilding it.

## Open questions that are NOT findings — establish before acting

- **"Combat has no visible action."** A critic found the engagement, move and
  hit frames identical, and the trainer-battle frame with no opponent in it.
  This is either a game defect or a capture failure and they need opposite
  work. VIS-MAKE resolves it from the code first.
- **The villagers read as 1.78 m children** — child faces and proportions at
  adult height. Whether they are adults or youths is a DESIGN decision. Ask the
  owner; do not decide it.

## This sweep's own harness defects — the pattern matters more than the list

Six times a survey photographed something other than its subject, and a blind
critic spent findings on it each time: the player seated inside two captains'
colliders and rendering as a 3.5 m totem pole; a creature stage with no
shadows and every creature seated on its own pivot so **the 1.80 m ruler
lied**; the ground capture reproducing the collider bug because the corridor's
fix was never ported; band 3 photographed under the wrong name; a clipped icon
sheet hiding half the inventory; a UI survey that read the `Game` autoload
before the tree mounted it and wrote zero frames.

**The lesson: a fix that lives in one tool does not protect the next tool that
does the same thing.** Port helpers; do not patch per-tool. And when a critic
reports something alarming, ask whether the harness caused it before believing
the game did — on this project the harness has been the answer more often.
