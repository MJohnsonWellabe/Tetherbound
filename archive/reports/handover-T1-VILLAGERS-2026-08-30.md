# T1-VILLAGERS handover — 2026-08-30

Branch `ralph/T1-VILLAGERS` off `origin/ralph/LAND-0830I`. Standing down on the
coordinator's instruction; this is the complete state.

**Nothing new was generated.** No Meshy spend, no new mesh, no new humanoid. The
only bodies discussed here are ones already built, rigged, animated and
installed on `main`.

**What shipped:** one wiring fix (`officer_b`), the corrected humanoid
inventory, and the audit itself.
**What did not ship:** the villager reallocation. It is an owner decision and
§4 lays out what he is deciding between, with frames.

---

## 1. Which named villagers have differentiated presentation today — and by what mechanism

The only two body-resolution paths that exist are
`character_model.gd::config_for(config_key)` → `data/config/art.json`, and
`npc_ranks.gd::config_for(rank, base)`. There is no third mechanism, so nothing
was giving the named cast distinct presentation by some route I had not checked.

### Named cast on a **bespoke installed body** (mesh-level differentiation)

Nobody. Not one named villager has their own mesh.

### Named cast on a **shared rig + variant** (material/scale-level differentiation)

Twelve characters on two meshes:

| Character | key | mesh | differentiator actually applied |
|---|---|---|---|
| Mira | `villager_farmer` | villager_female | hair `#5c3a22` |
| Tam | `villager_smith` | villager_female | hair `#8a8578` |
| Sela | `villager_ranger` | villager_female | hair `#7a3c22` |
| Halda | `villager_ranger` | villager_female | hair `#8f8f96` |
| Rae | `villager_farmer` | villager_female | hair `#7a4a2c` |
| Bryn | `villager_farmer` | villager_female | hair `#c9a86a` |
| Juno | `villager_ranger` | villager_female | rig default |
| Old Bram | `villager_farmer` | villager_female | hair `#d6d2c8` |
| Oskar | `villager_keeper` | villager_male | **height only** (1.78) |
| Bram | `villager_keeper` | villager_male | **height only** (1.78) |
| Kell | `villager_keeper` | villager_male | **height only** (1.78) |
| Quarry Foreman | `villager_quarryman` | villager_male | **height only** (1.80) |

### The mechanism is weaker than the config assumes — measured, not asserted

Spec §21 and this repo's own history rest on "NPCs differ primarily by hair
colour". Measured off the rendered frames at conversation distance
(`shots/mira-*.png`, `shots/tam-*.png`):

| | `art.json` says | actually renders as |
|---|---|---|
| Mira (`villager_farmer`) | `#5c3a22` = (92, 58, 34) | **(62.6, 36.1, 15.6)** |
| Tam (`villager_smith`) | `#8a8578` = (138, 133, 120) | **(30.7, 25.8, 18.4)** |

The tint is a straight `albedo * colour` multiply, which can only **darken**, so
`villager_smith`'s intended **silver-grey renders near-black**. Mira and Tam come
out as "brown-haired woman" and "dark-haired woman" — in identical faces,
identical green hoods, identical white tunics, identical belts. This is the same
mechanism `npc_ranks.json`'s own `_comment_palette_crush` documents for body
tints, reappearing on the hair channel where nobody had measured it.

**And on the male rig there is no hair dial at all.** Only `villager_female`
carries a separable `hair_ponytail` mesh (NP7); `villager_male` has none, so
Oskar, Bram, Kell and the Quarry Foreman are separated by **height alone** —
1.78, 1.78, 1.78, 1.80. Three of them are literally identical.

---

## 2. Which named NPCs read as generic extras, and what each actually needs

| Character | Screen time | What it needs |
|---|---|---|
| **Bram** | inn shop, whole chapter | The `innkeeper` body (installed). His own assistant Wilhelm is wearing it — see §4. A tint cannot fix this: he and Oskar are the same mesh at the same height. |
| **Tam** | first-hour tools, shop, tournament semi-final | A **male** body, whatever is decided about bespoke. He is "him" in every dialogue comment and is standing on `villager_female`. Cheapest correct fix is `villager_quarryman`; the best is `craftsperson`. |
| **Mira** | first-hour required visit, shop, tournament quarter-final | Separation from Tam. Today they are the same face in the same costume with hair that renders three shades apart. |
| **Oskar** | creature trade, tournament final | Separation from Bram and Kell — currently height-identical on the same mesh. |
| **Old Bram** | optional named battle, a real story beat | A **male** body. An old male champion renders as a young woman with white hair. `local_historian` is the installed fit. |
| Quarry Foreman, Kell, Sela, Halda, Rae, Juno, Bryn | one to three greetings each | Nothing urgent. The shared rig is the right answer for this tier; Sela/Halda/Rae/Bryn already differ by hair on the rig that supports it. |

The two **sex mismatches** (Tam, Old Bram) are the only items here I would call
defects rather than judgement calls. Neither was recorded anywhere in the repo.

There is also a **name collision** worth knowing: Bram the village innkeeper and
Old Bram the retired champion at (195, 905) are two different people who share a
first name.

---

## 3. What shipped on this branch

**`officer_b` wired to Warder Ness** (`stronghold_checkpoint`, band 5).
`officer_a` was carrying both Officer Dell (band 3) and Warder Ness (band 5) —
the only Team Tether body doing double duty — while `officer_b` sat installed
and unplaced.

This is **not** a re-litigation of `T1-HALL-3`. That lane pulled
`officer_b`/`grunt_c`/`captain_a` off the three bodies **inside the Hall** after
JUDGE-5 read them there; those three are untouched. The checkpoint is past the
Sigil gate but outside the Hall and was in none of the frames JUDGE-5 judged.
One line plus a comment; trivially revertible.

**`docs/art/HUMANOID_ASSET_INVENTORY.md` corrected** — see §5.

**`docs/ASSET_LEDGER.md`** carries the audit, the measurements and the
differentiator limits.

**`tools/_capture_t1_villagers.gd`** — the capture tool, kept because the next
pass on this will want it.

---

## 4. The open owner question: bespoke bodies for Mira, Tam, Oskar and Bram?

### What he is deciding between

**Option A — variant presentation only** (the status quo, possibly re-tuned).
Keep the four on the shared villager rigs and try to separate them with hair,
tint and height.

**Option B — move four installed bodies onto them.** No new art; take four
bodies that are already built and standing on walk-ons who duplicate these
characters' own jobs.

| Character | Their own opening line | Proposed body | Board panel | Currently worn by |
|---|---|---|---|---|
| Mira | "Meadow Keeper's what they call me" + runs the store | `creature_caretaker` | 13 | Fenn ("Oskar swaps them, I look after them in between") |
| Tam | "Field Scout when I'm out past the fence. **Smith when I'm in.**" | `craftsperson` — "builds and repairs structures and tools" | 12 | Ada ("the workshop's not mine") |
| Oskar | "Bridgehand's my trade — I keep the old crossing in one piece" | `wandering_trainer` | 20 | **nobody — installed and unplaced** |
| Bram | "Innkeeper's the whole of it." | `innkeeper` | 9 | Wilhelm ("Bram runs the counter, I run everything Bram doesn't have time for") |

Oskar's costs nothing at all. The other three take a body from a walk-on who is
that character's own subordinate, and those walk-ons go to the shared rigs.

### Frames

`ralph/reports/T1-VILLAGERS/shots/`. Real Meadows, real grass, real light, shot
at **3.8m** — the radius `village_npcs.gd::add_prompt` offers the "Greet <name>"
prompt at, so it is the distance the player is actually standing at when they
look at this person. Every shutter gated on `tools/capture_check.gd`.

**The pair that makes the argument** — open these two together:

- `bram-innkeeper-CURRENT-villager_male.png` — Bram, the innkeeper, behind his
  own inn counter: a young man in a plain brown waistcoat, the same body and
  outfit as Oskar, facing a wall.
- `wilhelm-walkon-WEARS-innkeeper-body.png` — Wilhelm, Bram's assistant: a big,
  hearty, red-bearded innkeeper in an apron with a green scarf and tool belt.

The assistant looks like the innkeeper. The innkeeper looks like a placeholder.

Also worth opening together: `mira-CURRENT-villager_female.png` and
`tam-CURRENT-villager_female.png` — the same person twice, and one of them is
supposed to be a man. And `ada-walkon-WEARS-craftsperson-body.png`, where a
female-named villager is a red-bearded man in goggles.

**These frames double as Option B previews.** Every body Option B proposes is
already standing in the village on a walk-on, photographed here at the same
range: Bram would look like Wilhelm does, Tam like Ada does. Nothing about
Option B needs to be imagined.

### My recommendation: Option B

Not on general "named characters deserve better" grounds, but on three specific
ones:

1. **Option A cannot separate the men at all.** `villager_male` has no hair
   mesh. Oskar, Bram and Kell are the same mesh at the same height, and body
   tint is a darkening multiply on a fused material. There is no dial left to
   turn.
2. **The bodies Option B wants were designed for these exact jobs.** The board's
   Village & Settlement row is close to a portrait set for this village's named
   cast; `T3-INSTALL` wired those bodies onto whoever had a config slot free,
   and `T1-CAST` then placed the walk-ons. The inversion is an accident of
   ordering, not a decision anyone made.
3. **It costs nothing.** Four installed bodies move; the displaced walk-ons are
   two-line NPCs for whom the shared rig is genuinely the right tier.

Against it: three of the four bodies leave a walk-on who then looks generic.
That is the correct trade — a two-line NPC should look generic before the
character the player buys from all chapter does.

**A ready-to-run implementation exists** at
`/tmp/.../scratchpad/apply.py` in this session and, more usefully, is fully
specified in this document and the ledger. It is a config-only change to
`data/config/village_npcs.json` and
`data/config/bands/band1_lower_meadows/trainers.json`, dry-run clean on copies
of both files. **Do not carry the `hair` blocks across** — the generated bodies
have no `hair_ponytail`, so a `hair` override attaches a primitive sphere to the
head; `old_champion_bram`'s block in particular has to be deleted, not moved.

If the owner picks Option A instead, the two sex mismatches still need fixing:
Tam → `villager_quarryman`, Old Bram → `villager_quarryman` with a pale tint.

---

## 5. Team Tether: measured, reported, not retuned

Measured off `shots/10-tether-rank-ladder.png` — daylight, 8.4m, a 32×40px torso
patch per body, Rec. 709 luma on the sRGB the player's monitor shows:

| Body | rank | torso luma |
|---|---|---|
| `grunt` (rank default) | grunt | **25.0** / 255 |
| `officer_a` (Officer Dell) | officer | **63.1** / 255 |
| `officer_b` (Warder Ness) | officer | **48.1** / 255 |
| `captain_a` | captain | **22.7** / 255 |
| `warden` | warden | **10.7** / 255 |

Mean 33.9. **This corroborates the ~30.6/255 figure** rather than contradicting
it — the rank-default `grunt` body, which is what the three reverted Hall bodies
now use, sits at 25.0. Not retuned, per instruction.

Two further observations from the same frame, both free and both worth a lane:

- **Rank no longer reads as a ladder, and the `base` override is why.**
  `npc_ranks.json` intends an ascending value step — grunt `#dcdcdc`, officer
  `#eeeeee`, captain `#ffffff`. That assumed one shared body. With per-individual
  bodies the multiply lands on five *different* textures, and the rendered
  ordering breaks: the captain (22.7) reads **darker** than both officers, and
  the Warden is darkest of all. Five distinct people, no visible chain of
  command.
- **The copper medallion is not visible at 8.4m** on grunt, either officer, or
  the captain. Only the Warden's disc reads. The badge offsets in
  `npc_ranks.json` were derived from the **grunt rig's** measured chest depth
  (~0.140m); a different base mesh does not share that depth, so a `base`
  override can sink the badge into the coat. Worth checking per body if rank
  legibility matters.

One defect on the newly wired body, reported and **not** retuned because it
belongs to the lane above: in `tether-03-officer-ness-officer_b-NEWLY-WIRED.png`
Warder Ness's **face renders as an unlit black void** at conversation range,
with the hair reading as one solid magenta mass. That is part of what JUDGE-5
was describing. The captain in `tether-04-captain-captain_a.png` has the
opposite problem — a blown-out white face. Both are properties of the generated
atlases and of the same lighting pass, not of the `base` override mechanism;
`officer_a` beside them reads correctly.

So on the brief's "keep rank legible" check: **individual identity now reads
well and rank does not.** Wiring `officer_b` improves the first, does not affect
the second either way, and carries the face defect above.

Faction identity is intact — the violet/purple accent reads consistently across
all five bodies at this distance.

---

## 6. What went into `docs/art/HUMANOID_ASSET_INVENTORY.md`

That file said current `main` has **six** humanoid rigs. It has **28** installed
humanoid `.glb` bodies. The six were accurate when written; `T1-NPC-CAST` and
`T3-INSTALL` added 22 more, all rigged, animated and keyed into `art.json`, and
the inventory was never updated. A pass reading only that file concludes the
village has two civilian bodies to work with when it has fifteen — which is
plausibly part of how this allocation went the way it did.

Added to it:

- an amendment note at the six-rig table, and a full **28-body table** grouped
  by base families / Team Tether / village / trail;
- **four bodies installed and standing nowhere** — `officer_b` (now wired, so
  three remain: `wandering_trainer`, `rival_trainer`, `young_trainer`) — with an
  instruction to check that list before generating anything;
- **`captain_accessory` is not a body.** It contains no mesh — two reference
  turnarounds behind a `.gdignore`, kept from the `captain_a`/`captain_b`
  generation, with no `art.json` key because there is nothing to key. Recorded
  so no future pass hunts for the mesh its name implies;
- the **differentiator limits** in one place: `villager_male` has no separable
  hair mesh; the generated bodies have none either, so moving a character onto
  one means removing the `hair` block rather than carrying it across.

---

## 7. Evidence quality

`tools/capture_check.gd` caught two real defects in my own capture tool on the
first framed round, both of which would have quietly invalidated every frame:
**Terrain3D was streaming around the gameplay camera**, not the capture camera;
and **`WorldWeather` was still processing**, so sky and light would have drifted
across the pass. Fixed; every committed frame reports `capture_check clean`.

Three more were caught only by opening the PNGs, which is the part `capture_check`
explicitly cannot do:

1. **The tool was photographing the backs of people's heads.** These rigs are
   authored facing **+Z**, not Godot's conventional −Z.
2. **The occlusion test was blocked by the subject itself** — `npc_body.gd`
   builds its collider as a child, so excluding the body node was not enough;
   every candidate angle failed and the camera fell through to a fallback
   standing inside a wall.
3. **Mira is indoors.** OF31 moved the merchant behind her counter inside
   `cottage_a`, so every 3.8m stand around her is through a wall. The tool now
   searches range as well as angle and steps in to 2.4m for her.

`00-village-square-wide.png` was **deleted rather than committed**: it framed
open forest with no village and no NPCs in it. The centroid-based wide framing
does not work and I did not have the render budget to fix it after the stand-down.
The per-character frames carry the argument.

---

## 8. Not done, deliberately

- **The villager reallocation** — owner decision, §4.
- **The Team Tether luminance lane** — measured in §5, untouched per instruction.
- **The rank-ladder and badge-depth findings in §5** — reported, not fixed; both
  need their own pass and neither is in this lane's scope.
- **The three Hall bodies** — `T1-HALL-3` removed those overrides on JUDGE-5
  evidence; not reopened.
- **`young_trainer`, `rival_trainer`, `wandering_trainer`** stay installed and
  unplaced. Inventing a character to justify a body is the wrong direction; Bryn
  was the one candidate for `rival_trainer` and is a teacher, not a rival ("I've
  nothing left to teach you out here").
- **`campfire_traveler` and `traveling_merchant`** remain un-rigged and
  un-installed, exactly as the T1-RIG-2 handover left them.
