# Creature and character art — what to buy, and why free art will not do it

**Status:** for the owner to decide. Nothing here has been bought.
**Written:** August 2026. Prices and licences checked on that date and will rot.

## Why this document exists

The owner set the bar as `docs/reference/palworld-0*.jpg` and chose "free art
only, report the gap". Two rounds of blind review have now reported the same
gap in the same place, and it is worth quoting rather than paraphrasing:

> **MA-01:** the roster is one adequate stock mesh, one blob, and a Minecraft skin.

> **MA-02:** two assets from two different pipelines, both untextured… Nothing in
> these frames has a second material… gap #1 — the creatures and the trainer —
> is the one the owner's bar is actually about, and it will still be there
> afterwards.

Between those two reviews the entire roster was replaced with better free art
and the complaint did not move. That is the finding: **swapping free assets for
better free assets does not close it.** The world half of the review moved a
long way in the same period (see `MA-02` and the MA3 commits), which is what
makes the creature half stand out as a different kind of problem.

`docs/decisions/D10` records the decision that follows from this. This document
is the other half of it — what closing it would actually cost.

## What the gap actually is

Not polygon count. Three specific things:

1. **No second material.** Every creature in the build is one flat albedo with
   zero variation across the body. Palworld's creatures have painted textures,
   layered materials, eye whites, and surface detail that reads at thumbnail
   size.
2. **No cohesion.** The two creatures come from two different packs with two
   different shading languages — smooth-shaded dense mesh beside hard-edged
   flat-shaded low-poly. The critic spotted this unprompted, twice.
3. **Not designed for this game.** The roster is whatever the free packs
   happened to contain — a frog standing in for a rabbit, a Triceratops standing
   in for Bramblit. `GAME_DESIGN.md` §26 names a silhouette row (rabbit, boar,
   deer, raptor, turtle, canine) and the build currently meets none of it.

Point 2 is the one that decides the shopping strategy: **buy the whole roster
from one studio.** Six good creatures from six different artists will fail the
same review that six from one artist would pass, and that is worth more than any
individual model's quality.

## Licence position, checked

Both major stores permit use in Godot, which was not obvious and is the thing
that would have wasted money:

- **Unity Asset Store** — assets are not restricted to Unity projects; the EULA
  governs redistribution, not engine. Watch for individually "restricted"
  assets, which are marked. ([Unity Support](https://support.unity.com/hc/en-us/articles/34387186019988-Can-I-use-assets-from-the-Asset-Store-with-other-engines))
- **Fab (Epic)** — the Standard licence permits use with any compatible tools,
  not just Unreal. The exception is content Epic itself owns — MetaHumans,
  Paragon, Quixel Megascans — which is Unreal-only. ([Fab licence docs](https://dev.epicgames.com/documentation/en-us/fab/licenses-and-pricing-in-fab))

In both cases the requirement is that assets ship **inside** the game and cannot
be extracted as standalone files. A Godot `.pck` satisfies that as well as any
other engine's package does.

**Practical requirement on top of the licence:** the pack must ship **FBX or
glTF**, not only engine-specific prefabs and URP materials. Godot 4.7 imports
FBX natively including animation, which is already proven — the current
creatures are FBX. A pack that is only a Unity `.unitypackage` of prefabs is
hours of unpicking.

## Candidates

Ranked by how directly each closes the gap above.

### 1. Meshtint — buy the roster one creature at a time ★ recommended

- **Price:** roughly $10–20 per creature; themed packs of 9–10 around $109–130.
- **Format:** FBX + PNG, and separately a Unity package. FBX is the one we need.
- **Style:** stylised, textured, rigged and animated, with idle/move/attack/die.
- **Why it fits:** this is the only option on the list that lets you buy
  **exactly the six silhouettes `GAME_DESIGN.md` §26 asks for, from one studio**,
  instead of buying 40 creatures to get 6 usable ones. Cohesion is the specific
  thing the critic keeps failing us on, and one studio's hand across six models
  buys it directly.
- **Cost to fix the roster:** roughly **$60–120** for six creatures.
- **Risk:** slightly simpler and cuter than Palworld's register — closer to the
  cartoon end. May land nearer the key art board than the Palworld bar.
- [meshtint.com](https://www.meshtint.com/) · also on the Unity Asset Store

### 2. N-hance Studio — Stylized Fantasy Creatures Bundle

- **Price:** **$149.99** (Unity Asset Store, v2.0.1, 580 MB).
- **Style:** the closest match on this list to Palworld's actual register —
  stylised but textured, with hue-shift colour customisation, which would let one
  mesh serve several species without looking recoloured.
- **Risk:** listed as **URP only**, which means the *materials* are Unity-specific
  even though the meshes are not. Budget time for rebuilding materials in Godot,
  and confirm FBX is in the package before buying.
- **Note:** this is the pack whose pirated copy appeared on `desirefx.me`. It is
  buyable from the actual publisher and that is the only way it should enter this
  project.
- [Unity Asset Store](https://marketplace.unity.com/packages/3d/characters/animals/stylized-fantasy-creatures-bundle-184409)

### 3. PROTOFACTOR — Heroic Fantasy Creatures Full Pack Vol 1

- **Price:** **$349.99** (Unity Asset Store, 2.8 GB).
- **Style:** semi-realistic fantasy monsters, heavily animated.
- **Verdict:** likely **past** the target rather than short of it. `GAME_DESIGN.md`
  §25 asks for stylised realism between Valheim and Palworld, and this sits on the
  far realistic side. It would also fight the Kenney/Quaternius world art badly.
  Listed for completeness, not recommended.
- [Unity Asset Store](https://assetstore.unity.com/packages/3d/characters/creatures/heroic-fantasy-creatures-full-pack-volume-1-5730)

### 4. Synty POLYGON — do not buy for this

- **Price:** $349.99 per pack, or $30/month for the library.
- **Why not:** Synty is flat-shaded untextured low-poly. That is **precisely the
  art language the critic has now rejected twice.** It is excellent work and it is
  the same category of thing we already have for free from Quaternius and Kenney.
  Spending $350 to arrive at the same review would be the worst outcome available.
- Recorded here so the question does not get asked again.

## The trainer is a separate and cheaper problem

The trainer does **not** need buying. **Quaternius Universal Base Characters +
Modular Character Outfits (Fantasy)** are CC0, free, glTF, humanoid-rigged and
retargetable, and give 12 outfits over a proper base body. That addresses the
proportion and material complaints the critic raised about the trainer
(measured 1:2.2 head-to-body against the key art's 1:6.5) at no cost.

Landmarks are likewise free: **Quaternius Medieval Village MegaKit**, CC0, 170
models in the free tier, which is the answer to *"nothing in the scatter system
produces a landmark"* and to Settlements being one of five promised key-art
features that the build delivers zero of.

**So the paid decision is only about creatures.** Everything else on the
critic's "needs art that is not in the build" list has a free answer.

## Recommendation

Buy **six Meshtint creatures, from one studio, matched to the `GAME_DESIGN.md`
§26 silhouette row**, for roughly $60–120. It is the cheapest option, it is the
only one that buys cohesion directly, and cohesion is the complaint that has now
survived two reviews.

If a round of blind review after that still says the creatures are short, the
next step is N-hance at $149.99, and at that point the honest question is
whether the answer is a marketplace pack at all rather than commissioned art.

## What not to do

- Do not buy Synty for creatures. See above.
- Do not download from `desirefx.me` or similar. It redistributes commercial
  packs without licence; the pack it was offering retails for $150.
- Do not use `CC BY-NC` models (e.g. the Sketchfab Desert Dragon). NonCommercial
  poisons any future sale, and the licence cannot be removed later.
- Do not use models whose uploader credits a film or game studio as the original
  rights holder (e.g. the Sketchfab Quetzalcoatlus, credited to Frontier and
  Universal). An uploader cannot grant CC-BY over someone else's model.
- Do not mix studios inside the roster, however good the individual models are.
  That is the mistake the build already made and was caught for.
