# T1-NPC-CAST — Meadows NPC Design Board classification & spend plan

**Branch:** `ralph/T1-NPC-CAST`. **Owner instruction:** "have it done as much of this as it can with my meshy credits. budget well."
**Envelope:** up to 1,800 credits (of a 3,410 balance; 900 reserved for the concurrent T1-CREATURE-MESH lane).
**Board:** `docs/art/reference/npc-board-2026-08-30/00_MEADOWS_NPC_DESIGN_BOARD.png` (1536×1024, read in full, panel by panel).

## Bottom line, first — REVISED after rendering (see below for what changed)

**Recommended spend: ~90–100 credits for one captain-silhouette accessory (one mesh, reused across all five named captains), 0 elsewhere mandatory, ~90 more optional (Traveling Merchant's cart, sourced-first).**

This plan's first pass called every NPC on the board, captains included,
satisfiable at zero Meshy cost by the existing rig/palette/badge system —
reasoned from reading `npc_ranks.json`'s code comments, not from a render.
The owner pushed back and asked for the rank ladder to actually be built
and looked at rather than taken on faith. It was:
`tools/_capture_rank_variety.gd` renders all eleven named grunts/officers/
captains in `data/config/bands/*/trainers.json` through the real
`trainer_npc.gd::model_config()` placement path, the same code that puts
them in the world (`shots/rank_variety/`). **The render disproves the
original captain classification** — Captain Halder and Captain Hald
(`09-captain-halder-front.png`, `11-captain-hald-front.png`) are the same
cap, mask, coat and boots as every grunt in the lineup; the only
differences across all eleven figures are a body-value/hue shift and a
chest badge that changes colour and grows slightly with rank. The board's
own TEAM TETHER NOTES line — *"Captains have distinctive silhouettes"* — is
not met. **The grunt/officer conclusion holds** — uniform, anonymous
rank-and-file reads as the evident design intent elsewhere in this
codebase, and the render is consistent with that being fine, not a defect.
Full account of what changed and why:
`ralph/reports/handover-T1-NPC-CAST-2026-08-30.md`.

24 of the 25 named NPCs are satisfiable by the six installed production
humanoid rigs (`docs/art/HUMANOID_ASSET_INVENTORY.md`) through the existing
per-material palette/hair/badge variant system that `character_model.gd` and
`npc_ranks.gd` already implement and that eight villagers and seventeen
Team-Tether-ranked NPCs already ship on today. None of those 24 clears the
bar CLAUDE.md and the inventory set for a new humanoid mesh: *"a real
player-facing need the existing six cannot satisfy."* The board's own
HUMANOID RIG & MESHY GUIDELINES panel agrees — *"Use the existing
Tetherbound human base rig... All characters fit the same humanoid rig for
animations"* — and its masthead says the same thing a second time.

**Hand back most of the 1,800-credit envelope, not all of it.** ~90–100
credits for one captain accessory mesh (reused across all five named
captains — one generation, not five), plus the same ~90-credit optional
Traveling Merchant cart as before (sourcing-first). Still roughly
1,610–1,710 credits handed back.

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
| 6–7 | Captain A/B | Battle/Trainer, Story/Key Info | **Real gap, CONFIRMED BY RENDER — needs a small accessory generation.** | `captain` rank (base `grunt`) + new coat/cape accessory mesh | ~90–100 |
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

**6–7, Captains — CORRECTED after rendering, no longer "zero."** The first
pass of this plan reasoned from `npc_ranks.json`'s own code comments that
the badge system was probably enough and called this "not a Meshy job."
The owner asked for it to actually be built and looked at instead of taken
on faith, which was the right call: `tools/_capture_rank_variety.gd`
renders all five named captains (`relay_captain`/Captain Vance,
`captain_riverwatch`/Captain Oreth, `captain_field`/Captain Halder,
`captain_ridge`/Captain Vess, `stronghold_elite`/Keeper Hald) through the
real `trainer_npc.gd::model_config()` placement path, alongside three named
grunts and three named officers, same camera and lighting throughout
(`shots/rank_variety/`). **Every one of the eleven is the same cap, the
same face mask, the same coat, the same boots.** Pixel-sampling the badge
and torso across all eleven confirms the *config* genuinely differs per
individual and climbs a clean ladder (badge red-channel: grunts ~103–132,
officers ~146–158, captains ~162–165) — so this is not a rendering bug,
the rank system is working exactly as coded — but colour and a coin-sized
badge are the *entire* differentiation. The board's TEAM TETHER NOTES panel
says *"Captains have distinctive silhouettes."* They do not, confirmed by
render, not assumed from reading the palette code.

**This still is not a full humanoid regeneration** — CLAUDE.md's new-mesh
bar is about the body, and the body is fine — but it is now a real,
rendered-and-confirmed case for **one small accessory generation**: a
coat/cape/shoulder-piece mesh, generated once against the board's own
captain panels as reference art (satisfying CLAUDE.md's "never without
owner-supplied reference art" the same way the board already satisfies it
for everything else in this ledger), then reused as a single attachable
mesh across all five named captains — the same "one mesh, many uses"
economy as the TM orb and the tether pylon, not five separate generations.
Rough cost, using `meshy.py`'s own measured `COSTS` table and the
tether-pylon/relay-apparatus recipe (3 preview candidates, retexture the
winner): **~90 credits** (3×20 preview + 30 retexture), possibly +40 for a
refine pass if the winner needs it — call it **~90–100 credits**, not the
1,800 envelope. A primitive box/cylinder was tried and rejected once
already for the chest badge itself (`npc_ranks.json`'s own
`_comment_badge_shape`: it "rendered as a flat pure-red untextured
rectangle... a debug gizmo") — a coat needs real drape, which a primitive
cannot sell, so this is a case where the generation is the cheaper and more
honest option, not a shortcut around one.

**One real blocker, outside this lane's ownership, flagged rather than
worked around:** `character_model.gd`'s `_apply_accessories()`
(scripts/characters/character_model.gd:606-633) only ever builds a
`_primitive_mesh()` — there is no path today to attach a real mesh loaded
from a `.glb`, even though the underlying `_attach_part(mesh: Mesh, ...)`
function it calls already takes a generic `Mesh` and would accept one
unmodified. The minimal fix is small and scoped exactly to this need (read
an optional `"mesh_path"` key in an accessory entry and `load()` it instead
of calling `_primitive_mesh()` when present), but it is a change to
`scripts/characters/character_model.gd`, which sits outside "scripts
beyond what a material variant genuinely requires" as this lane's file
ownership is written. Flagged for the coordinator to route to whichever
lane owns that file, alongside the generation request above — the two are
a matched pair; the mesh is useless without the attachment path, and the
attachment path has nothing to attach without the mesh.

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

- **Team Tether, grunts/officers (1–5):** no visual change needed to be
  board-satisfying — render-confirmed uniform rank presentation, which
  matches this codebase's own established design intent for rank-and-file.
- **Team Tether, captains (6–7):** good = a captain is identifiable as a
  captain from the same distance/angle a player would recognise a grunt,
  by silhouette (coat/cape/shoulder shape), not only by walking up close
  enough to read a chest badge's colour. The render in
  `shots/rank_variety/` is the before-state to check the after against.
  The rank-height gap (officer/captain rendering at the grunt's 1.80m
  instead of the board's graduated 1.8/1.9m) is a separate, smaller,
  logged follow-up, not this plan's spend either.
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

## Job 3 (prepare Meshy inputs) — one real item now, after the correction

**Captain coat/cape accessory.** Reference crops saved at
`assets/characters/captain_accessory/reference/board_captain_a_turnaround.png`
and `board_captain_b_turnaround.png` — each is a clean 4-view turnaround
(front, 3/4, side, back) plus a head close-up, cropped straight from the
board's panels 6 and 7. The back view on both is the useful one: a
full-length trailing cape/coat with a stood-up collar, clearly a garment
distinct from anything on the grunt base today. This satisfies CLAUDE.md's
"never a Meshy generation without owner-supplied reference art" the same
way every other board-derived generation in `docs/ASSET_LEDGER.md` does.
**Not yet cut to `views.json`'s per-figure convention** (single-figure
crops with a measured `band`/`centres`, like the six sheets that file
already documents) — this is a garment, not a character turnaround, so
`crop_prop_views.py`'s prop path (the one used for `tether_pylon`/
`relay_apparatus`, front/side/rear crops of one object) is the closer fit,
and the coordinator or executing lane should re-crop tightly to just the
coat once a generation is actually approved, rather than this lane
guessing at the isolation Meshy will want. A `meshy.py` prompt block was
**not** added either, for the same reason — it's a small enough prompt
that whoever runs the generation should write it against the exact crop
they cut, following `NEGATIVE_PROP`/`STYLE_PROP`'s existing shape (a worn
garment, not a freestanding prop, so it will want its own style line
rather than reusing `STYLE_PROP` verbatim — e.g. "stylised cloth/leather
coat and cape, worn open over a humanoid torso, clean readable drape,
no character, no head, no hands").

The Traveling Merchant cart (#17) is unchanged from the first pass: sourcing-first, ~90 credits if that fails, not committed.

## Running total against the envelope

| Item | Credits | Committed? |
|---|---|---|
| 24 of 25 humanoid NPCs (all classifications except captains) | 0 | — |
| **Captain coat/cape accessory (one mesh, all five named captains)** | **~90–100** | **Recommended — render-confirmed gap** |
| Traveling Merchant cart (prop, sourcing-first) | 0–90 | Optional, not committed |
| **Total against 1,800 envelope** | **~90–100 recommended, up to ~190 with the optional cart** | |
| **Handed back to the coordinator** | **~1,610–1,710 of 1,800** | |

Still nowhere near the full envelope, and this is deliberately not "spend
it because it exists" — the captain spend is the one item in this whole
25-NPC board that survived being rendered and checked rather than assumed.
Everything else here held up under that same scrutiny at zero cost; this
one didn't, and the number changed because of that, not because 1,800 was
sitting there to spend.
