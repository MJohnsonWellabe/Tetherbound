# Handover — T1-NPC-CAST, 2026-08-30

## CORRECTION, same session — the captain finding below was wrong until it was rendered

This handover originally matched the plan doc's first pass: zero Meshy
spend across all 25 NPCs, captains included, reasoned from reading
`npc_ranks.json`'s own code comments. The owner read that conclusion,
didn't buy it, and asked directly: build the three grunts, then officers,
then captains, and prove it. That was the right challenge — reasoning from
code comments about a palette/badge system is exactly the kind of claim
this codebase's own culture says to render before trusting (`ralph/
conventions.md`'s visual-judge discipline, and `npc_ranks.json`'s own
history of two prior blind-render corrections to this same rank system).

**Built it.** Installed Godot, wrote `tools/_capture_rank_variety.gd`
(mirrors the existing `_capture_character_cast.gd` staging pattern), and
rendered all eleven named grunts/officers/captains from
`data/config/bands/*/trainers.json` through the real
`trainer_npc.gd::model_config()` placement path — the same code that
places them in the actual game. Sent the lineup and portrait renders
directly to the owner.

**Result: the captain classification was wrong.** Every one of the eleven
figures — three grunts, three officers, five captains — is the same cap,
the same face mask, the same coat, the same boots. The only differences
anywhere in the set are a body colour/value shift and a coin-sized chest
badge that changes colour and grows slightly with rank. Pixel-sampling the
badge and torso confirmed the rank *config* genuinely differs per
individual (badge red-channel climbs cleanly grunt ~103–132 → officer
~146–158 → captain ~162–165) — not a script bug where everything silently
renders as grunt — but colour and a small badge are the *entire*
differentiation. The board's own TEAM TETHER NOTES line, *"Captains have
distinctive silhouettes,"* is not met. This directly overturns this
session's first-pass "already fully served" call for captains.

**Grunt/officer conclusion holds**, and the render is why: uniform,
anonymous rank-and-file across named individuals is consistent with this
codebase's own established intent elsewhere (`npc_ranks.json`'s own
comments call this out as the point, not a bug, for grunts), and nothing
in the board or the render argues otherwise for those two ranks.

**Revised recommendation:** one small, bounded Meshy spend —
~90–100 credits for a single coat/cape accessory mesh, generated once
against the board's own captain reference panels and reused across all
five named captains (the same "one mesh, many uses" economy the TM orb and
tether pylon already use in this project), not a new humanoid body and not
five separate generations. Reference crops prepared at
`assets/characters/captain_accessory/reference/`. A matching small
`character_model.gd` change (to accept a real mesh accessory, not only a
primitive shape) is needed to actually attach it, and is flagged rather
than made — it sits outside this lane's file ownership.

Every section below this point is the **original**, since-corrected
account, kept rather than rewritten so the correction has something
concrete to point at. Where a section's conclusion changed, that's called
out inline; do not treat the "zero mandatory spend" framing in the
sections below as current for captains — the box above and the plan doc
(`ralph/reports/NPC_CAST_PLAN_2026-08-30.md`) are current.

---

## What was asked

Coordinator brief: classify all 25 NPCs on the owner's Meadows NPC Design
Board (`docs/art/reference/npc-board-2026-08-30/00_MEADOWS_NPC_DESIGN_BOARD.png`),
decide which need a Meshy generation vs. which are satisfiable by the
existing six-rig humanoid cast, prepare Meshy inputs for anything that
genuinely needs generating, and write an executable plan — all before
spending any of an allocated 1,800-credit envelope (of a 3,410 balance, 900
reserved for the concurrent T1-CREATURE-MESH lane). This lane does not hold
the Meshy API key and does not run generation; the coordinator executes.
Push the classification table first, since it decides the spend.

## What I found and did

Read, in full: `CLAUDE.md`, the board image (all panels, at native and
zoomed resolution), `docs/art/HUMANOID_ASSET_INVENTORY.md`,
`docs/ASSET_LEDGER.md`, `tools/art_pipeline/meshy.py`,
`tools/art_pipeline/crop_views.py`/`views.json`,
`docs/art/HUMANOIDS_PRODUCTION_REPORT.md`, `docs/art/REFERENCE_CANON.md`,
`data/config/art.json`, `data/config/npc_ranks.json` +
`scripts/characters/npc_ranks.gd`, `data/config/village_npcs.json`,
`data/config/village.json`, `data/config/relay_site.json`,
`data/config/trade.json`, and every band's `trainers.json`
(`data/config/bands/band{1..5}_*/trainers.json`).

**Classified all 25 NPCs.** Full table with justification per entry:
`ralph/reports/NPC_CAST_PLAN_2026-08-30.md` (pushed first, per instruction).

**Headline result: zero mandatory Meshy spend.** Every NPC on the board —
Team Tether ranks included — is already satisfiable by the six installed
production rigs (`trainer`, `grandpa`, `warden`, `villager_male`,
`villager_female`, `grunt`) through the palette/hair/badge variant system
that `character_model.gd` and `npc_ranks.gd` already implement, and that the
game already ships on eight named villagers and seventeen-plus named
Team Tether NPCs across all five bands. The board's own rig-reuse panel and
the inventory say the same thing independently; this session verified that
claim against the actual live config rather than taking it on faith, and it
held for all 25 entries, not just the obvious ones.

The **one** optional item is the Traveling Merchant's cart (#17) — a prop,
not a humanoid, ~90 credits if a free CC0 asset can't be sourced first, not
committed to the envelope.

**Recommendation: hand back ≥1,710 of the 1,800-credit envelope.**

**Job 3 (prepare Meshy inputs) does not apply** — nothing in the
classification needs a Meshy call, so there was nothing to crop or write
prompts for. No `views.json` entries, no `meshy.py` prompt blocks were
added. This is a deliberate, evidenced outcome, not a skipped step.

**Two real, non-Meshy gaps found and flagged (not fixed — outside this
lane's file ownership, and flagged for the coordinator instead):**

1. **Captain silhouette.** The board's TEAM TETHER NOTES panel says
   *"Captains have distinctive silhouettes"* — the one place on the whole
   board that argues for something beyond retexture. `npc_ranks.json`'s own
   `_comment_ladder` independently (written before this board existed) says
   the identical thing: the rank ladder's only body-level dial is a
   darkening multiply, and real rank silhouette needs *"different headgear,
   shoulder kit, a coat at captain"* — accessory geometry. Two independent
   sources landing on the same gap is real signal, but the fix is accessory
   geometry / `character_model.gd` script work (currently primitive-shape
   only: box/sphere/ring/disc, no arbitrary mesh attachment), which sits
   outside "scripts beyond what a material variant genuinely requires." Not
   a Meshy job either way — flagged as a follow-up ticket.
2. **Rank height.** The board's SCALE REFERENCE panel (Grunt 1.7m, Officer
   1.8m, Captain 1.9m, Warden 2.0m) doesn't match what's actually installed:
   `npc_ranks.gd::config_for()` copies only `palette` and
   `badges`/`accessories` from a rank entry onto the base config, with no
   `height` passthrough — so officer and captain currently render at the
   grunt's exact 1.80m, not a graduated scale. One-line fix
   (`scripts/characters/npc_ranks.gd`, ~line 49) plus two data keys in
   `npc_ranks.json`; flagged rather than made, same ownership-boundary
   reasoning as above.

## What remains

- The coordinator decides whether to greenlight the ~90-credit optional
  cart prop, after (ideally) a sourcing attempt for a free CC0 hand-cart
  turns up nothing usable.
- Whichever lane owns NPC placement/dialogue (not this one — explicitly out
  of file ownership) still needs to actually author the ~14 new villager/
  trail NPC entries this classification clears for zero art cost (Inn
  Helper, Trader, Farmer as a distinct person from Mira, Creature Caretaker,
  Local Historian if distinct from Grandpa, Young Trainer, Rival Trainer,
  Field Researcher, Wandering Trainer, Lost Traveler, Campfire Traveler,
  Alpha Tracker, Courier, Former Tether Member) — each just needs an
  existing rig + an unused hair colour/palette, per the plan doc's "what
  good looks like" section.
- The two flagged engineering gaps (captain silhouette accessory geometry;
  rank height passthrough) are open tickets, not started.
- No Meshy generation was run by this session (by design — this lane never
  holds the key).

## What I learned that is NOT visible in the diff

- **The board's printed hex captions in the COLOR PALETTE GUIDE panel are
  illegible AI-generated gibberish text**, even at 4× zoom. I pixel-sampled
  every swatch directly instead (median of a 7×7px block, avoiding the
  swatch's own gradient) and recorded the measured hexes in the plan doc.
  Worth knowing for any future session that reads this board: don't trust
  OCR or a glance at the caption text, sample the swatch.
- **`villager_male` has no separable hair mesh and no working tint** (tint
  was removed outright, twice, after owner playtest called whole-body hue
  shifts "looks stupid" — it multiplies the fused face+skin+clothing
  material as one surface). Concretely, Oskar, Kell and Bram are visually
  identical today, by design, and the codebase already accepts that
  (CLAUDE.md's own stated fallback). Several of this board's male-presenting
  roles will hit the same wall if placed on `villager_male` — the plan doc
  recommends placing some on `villager_female` instead (which does have a
  real hair-mesh differentiator) rather than spending a Meshy retexture to
  try to fix `villager_male`, because a whole-rig retexture can't
  selectively touch clothing without re-touching the face (no UV mask
  exists for any human rig, unlike `tm_orb`'s emissive mask or the
  creature roster's anatomy-map overlays).
- **A Meshy `texture`/retexture call replaces a rig's one fused material
  wholesale** — it cannot leave a painted face alone while changing an
  outfit colour, because none of the six human rigs separates skin/face
  from clothing at the UV level. This is why "just retexture the parts that
  differ from the board" isn't actually a cheap option for any of these 25,
  even where a board sketch does look different from an installed rig.
- Board number **#11 prints as "31. TRADER"** — a typo on the board itself,
  not a numbering scheme this lane invented; treated it as #11 in sequence
  (between Inn Helper #10 and Craftsperson #12) since that's where it sits
  physically on the VILLAGE & SETTLEMENT row.
- The Meadows already has a **much deeper existing NPC/trainer cast** than
  the board's 25 might suggest at a glance — five bands' worth of named
  grunts/officers/captains plus eight village NPCs with a mature
  `greeting_when` branching dialogue system (D39's dual-role pattern:
  vendor branch + later trainer challenge, never rewritten only superseded).
  Any new NPC this board justifies should follow that existing pattern
  rather than inventing a new placement/dialogue mechanism.

## Disagreements with the brief

The brief's own framing already anticipated and explicitly welcomed this
outcome ("if the honest classification is that twenty of these twenty-five
need no Meshy call at all... say that plainly and hand the credits back —
that is a better outcome than a full envelope spent"), so there isn't a
disagreement to raise here so much as a confirmation, taken further than
the brief's own example number: **all 25**, not 20, come back at zero
mandatory spend, once checked individually against the live config rather
than assumed from the board alone. The two flagged engineering gaps
(captain silhouette, rank height) are the closest thing to a real
disagreement-adjacent finding — I'm recommending they NOT be treated as
Meshy work even though the captain one is the board's own strongest
argument for something new, because the actual fix lives in accessory
geometry/engineering, not generation.

## Full file footprint (UPDATED — supersedes the paragraph above, which predates the correction)

- **Added/updated:** `ralph/reports/NPC_CAST_PLAN_2026-08-30.md` (classification
  table + plan, pushed first, then revised in place after the render — see
  its own CORRECTION section).
- **Added/updated:** `ralph/reports/handover-T1-NPC-CAST-2026-08-30.md` (this
  file).
- **Added:** `tools/_capture_rank_variety.gd` — the evidence-render tool,
  committed (this repo's convention keeps `_capture_*.gd`/`_probe_*.gd`
  tools in the tree, unlike their PNG output).
- **Added:** `assets/characters/captain_accessory/reference/
  board_captain_a_turnaround.png` and `board_captain_b_turnaround.png` —
  reference crops for the recommended coat/cape generation, cut from the
  board's own panels 6–7. Not yet re-cut to a final Meshy-ready isolation
  (that's for whoever runs the generation, against the exact crop they
  choose to cut).
- **Not touched:** `views.json`/`meshy.py` prompt blocks (deliberately not
  added — see the plan doc's Job 3 section for why), `docs/ASSET_LEDGER.md`
  (no asset was actually generated this session, only reference crops
  saved; a ledger row belongs to whoever runs the generation), `assets/
  props/**` (the optional cart was not pursued), any dialogue/trainer/
  village-placement data (explicitly out of this lane's file ownership).
- **Not committed, by repo convention:** `shots/rank_variety/*.png` (top-level
  `shots/` is gitignored — render evidence, not a shipped asset). Sent
  directly to the owner instead via file delivery; referenced by path
  throughout both report docs for anyone who needs to regenerate it
  (`xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver
  opengl3 --resolution 1280x800 --script tools/_capture_rank_variety.gd`).
- Scratch work only, not committed: pixel-sampling scripts and cropped
  panel previews used to read the board and verify the render, under this
  session's own `/tmp` scratchpad — not part of the repo.
