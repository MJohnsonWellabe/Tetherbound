# Handoff — 2026-08-16 session (creature colour redo, opening, brief remainder)

Written at the owner's request on stopping, so the next session (or the loop)
picks this up without re-deriving it. Everything below is **on `main`**;
the working tree is clean.

## What the owner asked for

1. **Redo the creature colour pass** — "the other agent didn't have our art
   that we had as reference." The first vivid pass (`OF28` base half) was
   authored blind to the owner's boards and went jewel-toned.
2. **Redo Grandpa's dialogue** as the implementation brief describes.
3. **Audit** what else from the original 12-section brief is genuinely open.

Then, after seeing renders: fix the spheres in the sky, and stop the
stronghold reading "sterile / plain grey all the way through."

## Shipped this session (nine commits, all on `main`)

| Commit | What |
|---|---|
| `0d89ac7` | Vendored the owner's two boards into `docs/reference/` + ledger row |
| `bd7198f` | Grandpa's briefing rewritten to the board's five beats (299 → 208 words) |
| `75603e6` | The roster repainted to the boards (14 species redirected, 4 shinies reauthored) |
| `0bf516c` | Workbench becomes a crafting station; axe/pickaxe/knife recipes |
| `894949e` | Temporary creature tonics (the potions board's other half) |
| `e187ba2` | Step-up assist — the trainer can climb a kerb |
| `af0a70e` | Castle re-massed at board scale, in place, with colliders |
| `1c4408a` | Rank badges were 100× too large (the sky spheres); stronghold palette variety |

### The root-cause fix worth knowing about

The boards lived only in a chat thread, which is *why* a sibling session
painted the roster against a direction it could not see. They are committed
now (`docs/reference/owner-board-2026-08-15-*.png`) and named in
`ASSET_LEDGER.md` as **the authority for the roster's ordinary colourways**.
Any future colour work should be judged against those two files.

### Creature colour: what the redo actually changed

`data/creatures/shiny_colourways.json`'s `vivid_rules`, regenerated through
`tools/repaint_creature_textures.py`. Fourteen species redirected to the
boards; **duskhush, brooktail and veridian were already right and were kept**.
Four shinies reauthored so a rare never sits next to its own ordinary
(galecrest swapped roles, pipwing took back the retired yellow, bramblebun
went snow-white, trailpup/mudsnout separated).

Method, because it matters more than the numbers: three render rounds of
`tools/capture_shiny_pairs.gd`, with a **blind critic** between rounds judging
the sheet against the vendored boards. Its three "off direction" calls
(mudsnout, tuskroot, duskhush) and its "the boards' most repeated instruction
is moss and it is absent" note drove rounds 2 and 3.

**One trap for the next person:** the capture rig runs ~2× flat light through
ACES, so a timid `val_scale` (0.85) reads as *no change at all* in the frame.
"Midnight" and "deep brown" had to be authored genuinely dark (0.55–0.70) to
survive. Do not tune these by reading the JSON.

**Second trap:** removing a species' `vivid_rules` does nothing at runtime —
`creature_body.gd` swaps by file existence, so the stale `*_vivid.png` keeps
loading. Regenerate or delete the PNGs, and re-import.

## Status of the original 12-section brief

| § | Status |
|---|---|
| 1 Creature colour | **Done** (this session) |
| 2 Moves + TMs | Done (previous session) |
| 3 Hotbar | Done (previous session) |
| 4 Building / workbench | **Done** — placement fixed previously; station + tool recipes this session |
| 5 Gathering | Done (previous session) |
| 6 Blacksmith | Mostly — Tam gives tools + teaches `orb_basic`. **Gap: nothing tells the player the orb ladder (Rootstone → Ironwood) exists.** Owner deprioritised it |
| 7 Grandpa opening | **Done** (this session) |
| 8 Potions | **Done** — permanent elixirs previously (D47), temporary tonics this session |
| 9 Map / minimap | Done (previous session) |
| 10 Traversal | **Partly** — step-up assist shipped. **The route-walk half is NOT done** (see below) |
| 11 Castle / stronghold | **Partly** — exterior re-massed. **Grunts and the "occupied" read are not done** |
| 12 Validation | Smoke-verified throughout; an owner play-pass is still the real gate |

## Open work, in priority order

1. **Stronghold reads sterile.** The owner's last note: "make the whole thing
   look a little more like the actual castle in the back and give it color not
   a plain grey all the way through." `1c4408a` added variety (castle-palette
   accents, timber ceilings, a dark base course) but the dominant read is still
   pale — under the day sun the light stone blows out to bone-white, which is
   what "sterile" actually looks like.
   **Next step:** darken `data/config/stronghold.json`'s `site.stone` /
   `floor_colour` and add `stone_light` / `stone_dark` / `timber` keys (the
   script already reads all four, with the castle's retint values as
   fallbacks). An attempt at this was reverted because
   `json.dumps` reflowed the whole file into a 432-line diff — **edit that
   file by hand, or preserve its array formatting**, or the change is
   unreviewable.
2. **Grunts / the occupied read** at the stronghold (brief §11). The trainers
   exist (`stronghold_patrol`, `stronghold_courtyard`, `stronghold_elite`,
   `warden_aldis`); what is missing is banners, patrol presence and menace
   around the new walls.
3. **Traversal route-walk** (brief §10, and `OF15`'s open evidence gap). The
   step-up assist is in and guarded; nobody has yet walked the intended routes
   logging where the player wedges.
4. **Orb-ladder legibility** (brief §6). Small; owner deprioritised it.

## Verification notes for whoever is next

- **Re-import after every rebase.** Twice this session a "failure" was a stale
  `.godot/imported` cache, not a bug. `godot --headless --path . --import`.
- Unit suite: 953 tests green at the last full run.
- Smokes exercised this session and passing: `smoke_opening`,
  `smoke_free_build` (now proves the workbench loop end to end),
  `smoke_combat`, `smoke_playground`, `smoke_stronghold`, `smoke_traversal`,
  and the new `smoke_step_up`.
- **Rendering is the slow part, not the code.** No GPU here — llvmpipe
  software rasterisation, and every capture boots the whole Meadows first.
  Budget 3–5 minutes per capture run and ~15 for `smoke_traversal`.
- `tools/capture_castle.gd` (new) renders the fortress from the **north and
  east** deliberately: the stronghold complex owns the entire southern
  approach, so a camera south of the castle stands inside the Outer Works.

## Two things that were wrong and are worth remembering

- **The sky spheres were rank badges**, authored 100× too large in
  `npc_ranks.json` (size 7–16 and offset `[0,30,25]` applied as metres).
  `character_model.gd`'s own default of `0.12` was the giveaway. Eleven NPCs
  wore 3.5–8 m spheres thirty metres overhead. Fixed by dividing by 100, which
  preserves the intended 7 cm → 16 cm rank ladder exactly.
- **The "grainy creatures" were my QA crops, not the assets.** The roster
  sheet gives each creature ~90 px; upscaling that 3× with nearest-neighbour
  to check hue makes everything look degraded. Judge quality from
  `tools/capture_species_closeup.gd`, and use the roster sheet only for
  colour triage.
