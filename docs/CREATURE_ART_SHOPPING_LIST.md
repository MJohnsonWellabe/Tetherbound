# Creature and character art — what to buy, and why free art will not do it

**Status:** for the owner to decide. Nothing here has been bought.
**Budget:** **$50 total for creatures**, set by the owner. Rewritten against it.
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

## The budget, and what it changes

The owner set it after this document's first draft:

> *"I'm not going to spend over $100 on assets. find creatures in the $10-$50
> range. total I'll spend $50 on creatures but I'm also going to try to find more
> free ones."*

**$50, total, for creatures.** That is a smaller number than the first draft was
written against, and it does not just scale the recommendation down — it changes
which recommendation is right.

The original argument was *buy the whole roster from one studio*, because
cohesion is the complaint that survived two blind reviews and six creatures from
six artists fail the same review that six from one artist pass. At $60–120 that
was affordable. At $50 it is not: six creatures at $10–20 each is $60 at the
absolute floor and realistically $90.

So the strategy inverts. **Do not spread $50 across six mediocre buys.** Buy
**three** creatures from one studio at $10–20 each — the party cap is five and
the vertical slice needs far fewer than that — and fill the rest of the roster
from the free packs already in the ledger. Three good cohesive creatures beside
three decent free ones is a better picture than six uniformly cheap ones, and it
leaves the free-vs-paid comparison visible in the same frame, which is exactly
the evidence needed to decide whether to spend more later.

## Candidates, re-ranked against $50

### 1. Meshtint — three creatures, individually ★ recommended

- **Price:** roughly **$10–20 each**; **three for $30–50**, inside the cap.
- **Format:** FBX + PNG alongside the Unity package. FBX is the one we need, and
  Godot 4.7 imports FBX with animation natively — already proven, the current
  creatures are FBX.
- **Style:** stylised, textured, rigged, with idle/move/attack/die — which is the
  minimum `smoke_art` enforces and the thing most free packs fail.
- **Why it survives the budget cut:** it is the only option that sells creatures
  **one at a time**. Every other candidate is a bundle, and a bundle at any price
  above $50 is simply out regardless of how good it is.
- **Which three:** pick from the `GAME_DESIGN.md` §26 silhouette row, choosing on
  the critic's own criteria rather than on taste — hue-opposed to a green meadow,
  readable at 40px, and a silhouette that reads as a combatant.
- [meshtint.com](https://www.meshtint.com/) · also on the Unity Asset Store

### 2. Everything else on the original list — out on price alone

Recorded so none of it gets re-priced later.

| Pack | Price | Verdict against a $50 cap |
|---|---|---|
| N-hance *Stylized Fantasy Creatures Bundle* | $149.99 | **3× the budget.** Was second choice, and is the closest match to Palworld's register on this list. Also URP-only materials, so it costs rebuild time on top of money. |
| PROTOFACTOR *Heroic Fantasy Creatures Vol 1* | $349.99 | **7× the budget**, and was already not recommended — semi-realistic, past the target rather than short of it. |
| Synty POLYGON | $349.99 / $30 per month | **7× the budget**, and would buy the exact flat-shaded untextured look the critic has now rejected twice. The worst outcome available at any price. |
| CGTrader *Animalz — Cartoon 3D Animals* | $49.00 | **Inside the budget and still a no.** Ships `.blend` only — 16 files, 1.56 GB, no FBX or glTF — and this environment has neither Blender nor `bpy`, so the files cannot be opened or converted. Its advertised "50 poses" are rig poses, not baked clips, so it would not solve the animation problem either. Paying $49 for unopenable files is the one mistake this table exists to prevent. |

## What free art has already covered

Since the first draft, three of the four things this document said would need
buying turned out not to.

- **The trainer.** Styloo's "The Company" knight is CC0 and now in the build —
  2K textures, a real silhouette, and the critic's "numerically, mostly a
  floating head" complaint answered for free. It shipped no animation at all,
  which is why `animation_retarget.gd` exists (`docs/decisions/D11`).
- **The creatures, partly.** The owner supplied `Animals.glb` and the roster is
  now designed animals rather than a frog standing in for a rabbit. Their five
  quadrupeds share one bone-naming convention, so the same retargeter animates
  all of them from one map.
- **Landmarks.** Quaternius Medieval Village MegaKit, CC0, 170 models free.
- **Water.** Needed no asset at all — one disc and a shader.

**So the paid question is now narrower than it was: three creatures, $50.**
Everything else on the critic's "needs art that is not in the build" list has
been answered without spending anything.

## Recommendation

Buy **three Meshtint creatures for $30–50**, chosen from the §26 silhouette row
on measured criteria, and keep the free roster for the rest.

If a blind round after that still leads with the creatures, the honest question
is no longer which pack to buy — it is whether a marketplace pack closes this at
all, or whether the answer is commissioned art. `docs/decisions/D10` is where
that decision belongs.

## What not to do

- Do not buy Synty for creatures. See above.
- Do not buy a bundle to get three creatures. Every bundle on this list costs
  more than the whole budget, and buying one to use a fifth of it is how a $50
  cap turns into $150.
- Do not buy anything that ships `.blend` only. There is no Blender here.
- Do not download from `desirefx.me` or similar. It redistributes commercial
  packs without licence; the pack it was offering retails for $150.
- Do not use `CC BY-NC` models (e.g. the Sketchfab Desert Dragon). NonCommercial
  poisons any future sale, and the licence cannot be removed later.
- Do not use models whose uploader credits a film or game studio as the original
  rights holder (e.g. the Sketchfab Quetzalcoatlus, credited to Frontier and
  Universal). An uploader cannot grant CC-BY over someone else's model.
- Do not mix studios inside the roster, however good the individual models are.
  That is the mistake the build already made and was caught for.
