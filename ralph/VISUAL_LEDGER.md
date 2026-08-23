# The whole-game visual ledger

**Owner directive, 2026-08-23:** the visual coordinator runs across the ENTIRE
game, not one corridor. Named in the directive: the ground, HUDs, every menu
screen, every build, every asset type, every region, every character, every
creature, every tool, every consumable and gatherable, every terrain, every
pre-built building. *"The whole game relies on all of this looking great. This
is the most important ongoing task."*

This file is that mandate's standing ledger: every visual domain, its capture
tool, its last blind verdict, and what is open. It is append-and-amend, not
append-only — a domain's row is updated in place when it is re-judged, because
the useful question is always "what does it look like NOW".

## The pipeline, as the owner set it

1. **Sonnet captures.** A worker authors the domain's capture tool and renders
   real in-game frames with it.
2. **Fable reviews.** A blind critic — no knowledge of what changed, no stake
   in the answer — produces notes and a plan against `docs/reference/`.
   `ralph/OWNER_DIRECTIVES_2026-08-22.md` §5 is binding here: blind visual
   review stays Fable-only, and must never judge evidence it produced.
3. **Sonnet executes** the plan.
4. Repeat until `ralph/conventions.md`'s convergence rule ends it: stop after
   two consecutive rounds that name no new defect and move no measured axis
   (`tools/frame_stats.py`). Convergence without a pass is a `BLOCKED.md`
   entry or a labelled `BACKLOG.md` remainder, never silent iteration.

## The one measurement that shapes every schedule here

This box renders in software (llvmpipe) on **four cores**. Measured on the
standing corridor world — 143,630 props — at 1280x800: **~2.4 seconds per
rendered frame**. Two consequences, both paid for once already:

- **A capture's cost is its awaited frame count, not its scene.** The first
  corridor survey budgeted 3,376 frames the way the single-region probes do
  and did not reach its first shutter in seventeen minutes. The world was
  never the problem; it stands up complete in under a minute.
- **Renders do not parallelise on this box.** llvmpipe takes every core, so a
  second Godot render does not halve the wall clock, it doubles both. Author
  capture tools in parallel — that is free — and run them one at a time.

## Domains

Status: `open` (never judged) · `in-flight` · `judged` (verdict recorded,
work open) · `converged` (two flat rounds, remainder recorded).

| # | Domain | Capture tool | Status | Last verdict |
|---|---|---|---|---|
| D1 | Regions / the corridor, bands 1-5, day+night | `tools/_probe_corridor_survey.gd` | captured, awaiting blind pass | — |
| D2 | HUD + every menu screen | (being authored) | open | — |
| D3 | Creatures — 17 species, shinies, alphas | `tools/_capture_creature_roster.gd` | tool ready, parse-checked | — |
| D4 | Characters — 6 rigs, Team Tether ranks | `tools/_capture_character_cast.gd` | tool ready, parse-checked | — |
| D5 | Buildings — 18 prefabs + player builds | `tools/_capture_structures.gd` | tool ready, parse-checked | — |
| D6 | Items — 55 tools/consumables/gatherables | `tools/_capture_item_art.gd` | tool ready, parse-checked | — |
| D7 | Ground / terrain / water / weather | `tools/_capture_ground_and_sky.gd` | tool ready, parse-checked | — |
| D8 | Combat presentation | (being authored) | open | — |

## Findings the capture pass has already produced

These came out of authoring the tools — reading what the game actually
references — and none of them needed a critic to see. Each is a defect a
player meets, recorded here so a blind round is not spent rediscovering it.

- **Every Team Tether character is a repainted Warden.** `npc_ranks.gd`
  hardcodes his rig as the base body for grunt, officer, captain and Warden
  alike, and `npc_ranks.json`'s own comment says that was a stopgap "until the
  only faction-appropriate rig actually installed is the Warden's". One IS
  installed: `assets/characters/grunt/grunt_lod0.glb` is imported, sits on
  disk, and is listed by `docs/art/HUMANOID_ASSET_INVENTORY.md` — which
  CLAUDE.md makes authoritative — as a "reusable Team Tether rank-and-file
  archetype", under a rule that says to use the grunt family for ordinary
  Team Tether personnel "rather than repainting a civilian and calling it a
  grunt". Nothing in `data/config/` or `scripts/` references it. This is the
  root of a defect two blind rounds have already circled in other words: the
  rank ladder reads as "someone duplicated a mesh four times and nudged an
  exposure value", and no palette tuning fixes four copies of one body. The
  antagonist faction the player fights for a whole chapter has one silhouette.
- **The hammer is an axe.** `items.json` gives `hammer` a `held_model` of
  `quaternius_survival/Axe.obj`. The player swings a visible axe to build.
- **The hoe is a pickaxe, twice over.** `hoe` draws `Pickaxe_Bronze.gltf`, the
  same mesh as `pickaxe`, AND uses `pickaxe.png` as its icon — indistinguishable
  in the hand and in the backpack. The fishing rod equips nothing at all.
  (`hoe`'s mesh reuse is a documented D24 stand-in; the icon collision and the
  hammer are not flagged anywhere as deliberate, and both are visible during
  the game's core verbs.)
- **Half the inventory is visually duplicated.** 28 of 55 items share an icon
  with at least one other item. `potion_small.png` covers 7 (the small potion,
  three elixirs, three tonics), `tm_charged.png` covers 9 TMs, `stone.png`
  covers stone/rootstone/heartstone. Rubric criterion 1 asks what is still
  identifiable at 30%; for half the inventory the answer is "the wrong item".
- **There is no alpha creature ART.** "Alpha" is purely
  `creature_body.apply_size_multiplier()` — a scale field. No elite creature
  material exists anywhere in `scripts/creatures/` or the band spawn tables.
  An alpha is a normal creature that is bigger.
- **The chapter has one colour.** Measured across the 12-frame day corridor:
  eleven of twelve frames carry exactly three hue families, and the same three
  every time — blue, chartreuse, yellow. That is the numeric form of the
  standing "palette incoherence" finding, and the baseline any groundcover or
  lighting change has to move.

## Standing facts a round should not re-derive

- **The bar is Palworld** (`docs/reference/palworld-0*.jpg`) and the project's
  own keyart (`docs/reference/tetherbound-meadows-keyart.png`). Both bar
  questions have historically answered **NO**.
- **Creatures and characters are the point**, not a footnote — the rubric says
  to say so first and plainly when they do not hold up.
- **No new creature meshes for the Meadows, ever** (CLAUDE.md). Differentiate
  with materials, textures, scale, animation, VFX, habitat, behaviour.
- **The 1.80 m trainer is the ruler.** A survey with no character in it cannot
  be asked the scale question at all — that invalidated a whole D5 round.
- **A capture with the player parked away from the shot photographs an empty
  world**, because creature spawning is driven off the player, and Terrain3D
  streams around whichever camera it was handed.
- **Pin the clock AND freeze it.** A pin that is not frozen wears off across a
  multi-viewpoint pass and the late frames come back in a dusk wash.
- **Never `--headless` with a real rendering driver.** It hangs forever with no
  error, and leaves zombie processes that then cause real contention.
