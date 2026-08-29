# T1-NPC-CAST — Meadows NPC Design Board classification & spend plan

**Branch:** `ralph/T1-NPC-CAST`. **Owner instruction:** "have it done as much of this as it can with my meshy credits. budget well."
**Envelope:** up to 1,800 credits (of a 3,410 balance; 900 reserved for the concurrent T1-CREATURE-MESH lane).
**Board:** `docs/art/reference/npc-board-2026-08-30/00_MEADOWS_NPC_DESIGN_BOARD.png` (1536×1024, read in full, panel by panel).

## Bottom line, first

**Recommended spend: 0 credits mandatory, ~90 credits optional (Traveling Merchant's cart, sourced-first).**

All 25 named NPCs are satisfiable by the six installed production humanoid
rigs (`docs/art/HUMANOID_ASSET_INVENTORY.md`) through the existing
per-material palette/hair/badge variant system that `character_model.gd` and
`npc_ranks.gd` already implement and that eight villagers and seventeen
Team-Tether-ranked NPCs already ship on today. None of the 25 clears the bar
CLAUDE.md and the inventory set for a new humanoid mesh: *"a real
player-facing need the existing six cannot satisfy."* The board's own
HUMANOID RIG & MESHY GUIDELINES panel agrees — *"Use the existing
Tetherbound human base rig... All characters fit the same humanoid rig for
animations"* — and its masthead says the same thing a second time. This
board is a retexture/variant/placement specification for a cast that is
already almost entirely built, not a request for 25 (or even a handful of)
new generations.

**Hand back essentially the full 1,800-credit envelope.** Reserve nothing
beyond the ~90 credits below, and only spend that after a free-asset search
comes up empty (see #17).

This is not a reluctant minimum reading of the brief — it is the board and
the inventory agreeing independently, which the brief itself flagged as the
finding that should shape the whole plan, and it held up under scrutiny of
every one of the 25 entries individually, not just the ones that were
obviously trivial.

## What "retexture" would even buy here, and why it doesn't apply

`meshy.py`'s `texture` command (30 credits) retextures a mesh against a
concept crop. Every one of today's six humanoid rigs is **one fused
MeshInstance3D, one material** (`npc_ranks.json`'s own measured note: skin,
face and clothing share one texture, confirmed against the imported `.glb`
for the grunt rig). A Meshy retexture pass replaces that whole texture
wholesale — it cannot selectively repaint clothing while leaving the
painted face alone, which is exactly the failure `art.json`'s villager
history already lived through three times (`tint` first darkened faces,
then was removed outright after the owner called it "looks stupid" twice).
Retexturing a rig to change one NPC's outfit colour risks re-opening that
exact defect for a new set of characters, on a mesh with no UV-region mask
to protect the face — the tooling to do that safely (a hue-band mask like
`tm_orb_emissive_mask.png`, or a per-region repaint script like
`tools/repaint_grunt_faction.py`) does not exist for any of the six human
rigs. So even where a board panel visually differs from an installed rig,
"spend 30 credits to retexture it" is not the correct next step; the
already-installed `hair`/`palette`/`accessories` mechanism is (§ "The real
limit" below explains where that mechanism runs out, and what to do
instead).

## Classification table

Columns: **#** = board number. **Rig** = the installed archetype it maps
to. **Spend** = Meshy credits this NPC needs. Ordered by the board's own
groups, with a value note on where each sits in "how often the player
actually meets this person" (Job 4's ordering instruction) — worked out
from the role legend plus `data/config/npc_ranks.json` (every Team Tether
rank appears repeatedly across all five bands) and `data/config/trainers.json`
/`village_npcs.json` (the eight already-shipped roster members).

### Team Tether (rank ladder — met constantly, every band)

| # | Name | Role legend | Classification | Rig / mechanism | Spend |
|---|---|---|---|---|---|
| 1–3 | Grunt A/B/C | Battle/Trainer | **Zero — already fully served.** | `grunt` rank, `npc_ranks.json` | 0 |
| 4–5 | Officer A/B | Battle/Trainer | **Zero — already fully served.** | `officer` rank (base `grunt`) | 0 |
| 6–7 | Captain A/B | Battle/Trainer, Story/Key Info | **Zero today; real gap flagged, not a Meshy job.** | `captain` rank (base `grunt`) | 0 |
| 8 | Warden (Meadows) | Battle/Trainer, Story/Key Info | **DO NOT TOUCH.** Already rebuilt from board 16. | `assets/characters/warden/warden_lod0.glb` | 0 |

**1–3, Grunts.** `data/config/npc_ranks.json` and the grunt rig already carry
eight-plus named grunts across all five bands (Dorn, Pell, Kest, Hess,
Orrin, `south_bridge_grunt`, `stronghold_patrol`, `stronghold_outer_watch`,
`patrol_ridgeline`) sharing one texture on purpose — rank is the identity,
not the individual. The board's three grunt sketches (cap, ponytail,
short-hair) read as concept-art variety for the *faction*, exactly the
footing the inventory already gives the Warden's own board panel: reference
for the faction's visual language, not a work order for three meshes.
Nothing in the game currently needs three visually distinct grunt bodies —
the player never sees Grunt A stand next to Grunt B and needs to tell them
apart; they see a rank badge.

**4–5, Officers.** Same reasoning. `officer` rank already exists (Officer
Dell, Warder Solene, Warder Ness) with its own badge tier over the grunt
rig.

**6–7, Captains — the one place the board argues for something real.** The
TEAM TETHER NOTES panel: *"Grunts have simpler gear, Officers add command
pieces, **Captains have distinctive silhouettes**."* `npc_ranks.json`'s own
`_comment_ladder` independently says the identical thing from the
engineering side, unprompted by this board: *"real rank READING at distance
needs silhouette — different headgear, shoulder kit, a coat at captain —
which is accessory geometry."* Two independent sources naming the same gap
is real signal. **This is still not a Meshy job**, for two reasons: (a) a
silhouette-changing coat/cape is *accessory geometry* layered on the
existing rig, the same category as the badge system, not a new humanoid
body — CLAUDE.md's new-mesh bar is about the body, and the existing four
captains (`relay_captain`/Captain Vance, `captain_riverwatch`/Captain
Oreth, `captain_field`/Captain Halder, `captain_ridge`/Captain Vess,
`stronghold_elite`/Keeper Hald) already read as captains by badge alone
today without it; (b) building that geometry is scripts-and-accessory work
(`character_model.gd`'s `_apply_accessories`/`_attach_part`, currently
primitive-shape only — box/sphere/ring/disc, no arbitrary mesh), squarely
outside this lane's file ownership ("scripts beyond what a material variant
genuinely requires"). **Flagged to the coordinator as a real, evidenced
follow-up ticket** — a coat/cape accessory mesh for the captain rank,
buildable the same way `torch_prop.tscn` was (built geometry, no Meshy
credit) or as a small owner-referenced prop generation if a built primitive
can't sell "coat" — not something this session should spend budget or
scope on.

**8, Warden.** CLAUDE.md and the inventory are explicit and this session
did not reopen it. Confirmed `assets/characters/warden/warden_lod0.glb`
exists and is wired in `art.json`. The board's Warden panel is reference
for the faction's visual language only.

**A second, unprompted finding on the rank ladder — scale.** The board's
own SCALE REFERENCE panel: Grunt 1.7m, Officer 1.8m, Captain 1.9m, Warden
2.0m. `data/config/art.json`'s installed `grunt` block measures the rig at
1.80m. But `npc_ranks.gd::config_for()` (`scripts/characters/npc_ranks.gd`,
~line 49) only copies `palette` and `badges`/`accessories` from a rank entry
onto the base config — **it has no `height` passthrough**, so officer and
captain currently render at the exact same 1.80m as a grunt, not the
graduated 1.8/1.9m the board asks for and the game's own rank system
otherwise implements faithfully. This is a zero-Meshy-cost, near-zero-risk
fix (one `if rank_entry.has("height"): cfg["height"] = rank_entry["height"]`
line in `config_for()`, plus a `"height": 1.8` / `1.9` key on the two rank
entries in `npc_ranks.json`) — **flagged for the coordinator rather than
made here**, since it touches `scripts/characters/npc_ranks.gd`, which sits
right at this lane's ownership boundary ("scripts beyond what a material
variant genuinely requires") and other lanes may be mid-edit on rank
presentation.

### Village & Settlement (met often — the square is a hub every band-1 player revisits)

| # | Name | Role legend | Classification | Rig / mechanism | Spend |
|---|---|---|---|---|---|
| 9 | Innkeeper | Services/Rest | **Zero — already shipped.** Bram, `villager_keeper`. | existing | 0 |
| 12 | Craftsperson | Services/Crafting | **Zero — already shipped.** Tam, `villager_smith`. | existing | 0 |
| 11 (board prints "31") | Trader | Services/Shops | **Zero — variant of an existing base, or arguably redundant with Mira.** | `villager_male`/`villager_female` + new hair | 0 |
| 14 | Farmer | Neutral/Flavor | **Zero — variant.** Note: `villager_farmer` is Mira's *config_key* (a leftover name from R7.2, before OF31 turned her into the merchant); a distinct Farmer NPC needs a **new** hair colour on the same `villager_female` base, not reuse of Mira's own #5c3a22. | `villager_female` + new hair | 0 |
| 10 | Inn Helper | Services/Rest | **Zero — variant.** | `villager_female` + new hair | 0 |
| 13 | Creature Caretaker | Services/Healing | **Zero — variant.** Thematically adjacent to Oskar's swap but a distinct "teaches bonding" role; new NPC, existing rig. | `villager_female`/`male` + new hair | 0 |
| 15 | Local Historian | Exploration/Lore | **Zero — arguably already served by Grandpa Elias** (lore/history beats already in his dialogue). If a second, distinct Historian is wanted, `old_champion_bram`'s own entry already records why: *not* Grandpa's rig again ("a second NPC wearing Grandpa's face reads as Grandpa") — use `villager_male`/`female` + new hair instead. | existing or variant | 0 |
| 16 | Young Trainer | Battle/Trainer | **Zero — variant.** Reuses `trainer` or a villager base + hair; a recurring rival-adjacent role like Mira/Oskar/Tam. | `trainer`/villager + hair | 0 |
| 17 | Traveling Merchant | Neutral/Shops | **Zero for the person** (villager base + hair). **The cart is a separate prop, not a humanoid** — see below. | villager + hair; cart = prop | 0 (+ up to 90, optional) |

**17, Traveling Merchant's cart.** Cropped and inspected at 3× (board panel
17): a two-wheeled wooden hand-cart loaded with cloth bundles and baskets,
clearly a separate object the figure pushes, not character geometry.
`tools/art_pipeline/prop_views.json` + `crop_prop_views.py` is the existing,
cheaper path for exactly this (used for the camp set and the three hero
objects), and it is genuinely a one-scene flavour prop, not something the
player meets often — checked `assets/props/quaternius_fantasy`,
`quaternius_survival`, `kenney_survival` and the rest of `assets/props/` for
an existing or sourceable hand-cart first; none exists on disk today. Two
honest options, in order: **(a) source a CC0/permissively-licensed hand-cart
model** (Kenney/Quaternius/Poly Haven-class packs; this session did not have
a live sourcing pass budgeted and did not fetch one — flagged as the first
thing to try, per CLAUDE.md's "Asset work" section explicitly permitting
sourcing over generating) before spending anything; **(b) if sourcing comes
up empty, a modest prop-tier Meshy generation** (image-to-3D preview ×3 +
retexture the winner, ≈90 credits, the same recipe as `camp_tent`), from a
single board crop — the cart is drawn once, at one angle, with no
turnaround, so `views.json`'s multi-view requirement doesn't apply and a
prop generation from one strong reference image is the right tier. **Not
committed to the 1,800 envelope; flagged as the one item worth a small
optional spend, sourcing-first.**

### Trail & Wilderness (met occasionally — one or a few encounters each, scattered across bands)

| # | Name | Role legend | Classification | Rig / mechanism | Spend |
|---|---|---|---|---|---|
| 18 | Rival Trainer | Battle/Rival | **Zero — variant.** | `trainer`/villager + hair | 0 |
| 19 | Field Researcher | Exploration/Info | **Zero — variant.** | villager + hair | 0 |
| 20 | Wandering Trainer | Battle/Random | **Zero for the human.** Companion creature at their side is existing-roster territory (T1-CREATURE-MESH's, not mine) — flagged, not touched. | villager + hair | 0 |
| 21 | Lost Traveler | Exploration/Side Quest | **Zero — variant.** | villager + hair | 0 |
| 22 | Campfire Traveler | Exploration/Rumors | **Zero — variant.** | villager + hair | 0 |
| 23 | Alpha Tracker | Exploration/Info | **Zero — variant.** Binoculars/tool-belt via the existing primitive accessory system. **Flagged below as a dialogue tie-in worth raising, not mine to write.** | villager + hair + primitive accessory | 0 |
| 24 | Courier | Neutral/Delivery | **Zero — variant.** Satchel/scroll-case via the existing primitive accessory system. | villager + hair + primitive accessory | 0 |
| 25 | Former Tether Member | Story/Key Info | **Zero — variant.** Visual choice (defector reads as ex-grunt in a neutral palette, or as a plain villager) is a character-design call for whoever owns dialogue, not an art-pipeline decision; either is zero Meshy cost. | grunt rig (neutral palette) or villager + hair | 0 |

**23, Alpha Tracker — worth flagging even though the dialogue isn't mine.**
A concurrent creature-expansion lane is adding nine creatures with Alpha
tiers plus habitat/weather/time gating (per this brief). *"Tracks Alpha and
rare creatures. Knows their habits"* is a ready-made in-world teacher for a
rarity system that currently has no other way to explain itself to the
player. Zero art cost either way — raising it because the coordinator asked
to hear it, not because it changes this plan's spend.

## The real limit in the existing variant system — and what NOT to do about it

Worth being honest about, since it's the one place "just retexture it"
sounds plausible and isn't the right answer. `villager_male` (the
`villager_keeper`/`villager_quarryman` base under Oskar, Kell, Bram, the
Quarry Foreman) has **no separable hair mesh** — only `villager_female` got
one cut out in NP7. Its `tint` was **removed outright**, twice, after two
rounds of owner playtest both said whole-body hue shifts "look stupid," and
nothing replaced it (`_comment_accessory_tried_and_reverted` in `art.json`:
a belt-pouch accessory was tried and reverted after it rendered in the
wrong place). The honest state today: **Oskar, Kell and Bram are visually
identical**, by design, and the game already accepts that — CLAUDE.md's own
stated fallback is "identical NPCs are preferable to ugly whole-body hue
shifts."

Several of this board's male-presenting roles (Innkeeper is already Bram;
Craftsperson is already Tam on the *other* base, which does have hair; but
Trader, Courier, Local Historian, Lost Traveler, Alpha Tracker, Rival
Trainer, Wandering Trainer as drawn skew male on the board) will hit this
same wall if all placed on `villager_male`. Two honest paths, neither of
which is "spend a Meshy retexture on the whole rig" (see above for why that
risks re-tinting the face again): **(a) place several of them on
`villager_female` instead** — nothing in the board or the design forces a
1:1 gender match to the sketch, and `villager_female`'s hair mesh is a real,
already-working differentiator; **(b) a genuinely worthwhile, zero-Meshy
follow-up** would be a `tools/repaint_grunt_faction.py`-style local texture
tool that segments `villager_male`'s one fused texture into a skin/face
region and a clothing region (the same UV-space technique
`tools/creature_anatomy_maps.py` already proved out for the creature
roster's identity overlays), so a clothing-only tint becomes possible
without ever multiplying the face again. That is real engineering work,
outside this lane's scope and ownership, and is flagged for the coordinator
rather than attempted here.

## What "good" looks like, so a placement pass doesn't need to re-derive this

- **Team Tether (1–8):** no visual change needed to be board-satisfying.
  Good = the rank ladder stays legible at combat distance (badge + palette,
  already shipped) and the Warden stays untouched. The captain-silhouette
  and rank-height gaps are logged, not silently accepted as fine — but they
  are follow-up tickets, not this plan's spend.
- **Village/Settlement (9–17) and Trail/Wilderness (18–25):** good = each
  new NPC lands on an existing rig with a hair colour or palette genuinely
  distinct from every other NPC already on that base (the game already
  keeps a running distinctness list — see `art.json`'s own comments citing
  each other's hex, e.g. Halda's `_comment` naming farmer/smith/ranger/Bryn
  by hex to justify its own choice) and a placement/behaviour that matches
  its Exploration/Info/Shops/Trainer role from the legend. None of that is
  an art decision this lane should make unilaterally — it is NPC placement
  and dialogue, explicitly out of this lane's file ownership.
- **Traveling Merchant's cart, if pursued:** good = a two-wheeled cart
  silhouette recognisable against the board's panel 17 at typical player
  viewing distance, loaded-goods read as a shape (not painted detail) so it
  survives the same scale a `camp_tent`-class prop ships at.

## Colour palette — transcribed from pixels, not the printed labels

The board's own printed hex captions render as AI-generated gibberish text
at this resolution (illegible even at 4× zoom — see
`docs/art/reference/npc-board-2026-08-30/`'s COLOR PALETTE GUIDE panel).
Per this brief's own instruction not to trust a paraphrase, these were
**pixel-sampled directly from each swatch** (median of a 7×7px block,
avoiding the swatch's own gradient edge) rather than read off the printed
caption:

| Name | Measured hex |
|---|---|
| Tether Purple | `#8650D6` |
| Dark Charcoal | `#3A3834` |
| Meadows Green | `#6C7735` |
| Warm Brown | `#8B6138` |
| Sky Blue | `#74B5D4` |
| Cream / Linen | `#E4D6C2` |
| Ember Orange | `#F38A37` |
| Slate Gray | `#6B6B68` |

Not currently needed for any spend in this plan (nothing here generates
against the palette), but recorded for whoever authors the new villager hair
colours/palettes above, so a "Trader" or "Courier" hair pick can stay in the
board's own colour family rather than drifting into an already-used hex
(`art.json` already discourages colour collisions explicitly in its own
comments — see Halda's).

## Job 3 (prepare Meshy inputs) — does not apply

No mandatory Meshy call exists in this classification, so there is nothing
to crop or prompt-author under `views.json`/`meshy.py` today. If the
coordinator green-lights the optional Traveling Merchant cart (~90 credits,
after a sourcing attempt fails), the single board crop needed is panel 17
(`docs/art/reference/npc-board-2026-08-30/00_MEADOWS_NPC_DESIGN_BOARD.png`,
roughly px region [1160,470]–[1340,660] at native resolution, verified by
inspection this session) — that crop is trivial to cut and is not blocking;
not cut speculatively because the sourcing step should happen first and
might make it unnecessary entirely.

## Running total against the envelope

| Item | Credits | Committed? |
|---|---|---|
| 25 humanoid NPCs (all classifications above) | 0 | — |
| Traveling Merchant cart (prop, sourcing-first) | 0–90 | Optional, not committed |
| **Total against 1,800 envelope** | **0 (up to 90 optional)** | |
| **Handed back to the coordinator** | **≥1,710 of 1,800** | |

This is deliberately not "spend the envelope because it exists." Per the
brief's own framing: if the honest classification says the cast fits in far
less than 1,800, say so and hand the difference back. It does, by a wide
margin, and this plan does.
