# D8 combat and D6 item art — blind pass, round 1

One Fable critic, both sets, blind, per `ralph/OWNER_DIRECTIVES_2026-08-22.md` §5.
**A — no. B — no.**

## The headline, and the question it raises before anyone acts on it

> *"02-move-firing-clean is titled as the firing moment, and there is no firing
> in it. No projectile, no launch effect, no dust, no attack pose... Put 01, 02
> and 03 clean side by side and they are the same still life three times."*

> *"05-trainer-battle-hud names an opponent that is nowhere in the frame... only
> a distant idle NPC and the text 'You backed off.' The trainer-battle frame
> contains no battle."*

**This is either a devastating game finding or a fourth harness failure, and the
two demand opposite responses.** This sweep's harnesses have already
photographed the wrong thing three times in three tools. It is under
investigation and is NOT recorded here as a game defect until the mechanism is
established. Whatever the answer, it is worth having: "the fight has no VFX" and
"the capture shot the wrong instant" are different work.

The empty TEAM panel — five OPEN SLOT rows down the middle of a fight — points
the same way: the capture probably never seeded a party.

## Combat findings that stand regardless

- **The camera frames the wrong participant.** The piloted creature fills the
  bottom-centre with its rear to camera, a quarter of the frame, face never
  visible, while the enemy is *"a ~40px speck at mid-distance. The fight happens
  between a large rump and a distant dot."*
- **The danger telegraph is invisible to the player it warns.** The red
  "incoming — move" ring is stamped on the player creature's own back shell and
  occluded by its body. *"A danger telegraph the player physically cannot see is
  worse than none."*
- **HUD, on a controller-first title:** keyboard glyphs (`[C]`, `F`, `1`, `2`)
  throughout; the ability card overlaps the Orbs tray and amputates slots 3-5;
  "ACTIVE COMPANION — No creature out" while the player is piloting a creature.
- Good, and worth keeping: the enemy nameplate hierarchy, and the coaching lines
  ("incoming — move", "it's open — hit it"), *"a genuinely nice idea, correctly
  placed"*.

## Items: a second oxblood leak, and an inventory that cannot identify itself

**`world-ironwood`'s canopy sits in the reserved oxblood band — the danger
colour has leaked onto a friendly gatherable.** That is the second independent
leak found blind in this sweep; the first is the player's buildable roof
(`ralph/reports/VISUAL_STRUCTURES_AND_GROUND_2026-08-23.md`). Neither critic was
told the colour meant anything.

**Every icon is monochrome white on an identical dark tile.** No colour coding
by kind, rarity or anything else — *"Palworld's inventory is full-colour
precisely because colour is what survives a glance."* On top of that, the glyphs
themselves duplicate: axe = hoe = pickaxe is one T-mattock; four of six
consumables are one flask; heartstone = rootstone = stone is one fractured hex.
The torch is *"a two-pixel vertical line with a dot — invisible at any zoom."*
This is the screen the player opens most.

**The gather nodes wear the wrong identities:**
- `world-berries` **has zero berries** — a green bush with purple trumpet flowers.
- `world-fiber` is neon-violet flowers at ~3x scale and a **colour-twin of the
  berry bush** — the two most-gathered plant nodes share one identity.
- `world-wood` is *"a dead, leafless, charcoal-black tree... in a biome sold as
  cozy-and-inviting, the friendliest gathering verb in the game points at a
  burnt, haunted prop."*
- **Stone and rootstone read reversed** — the common stone is exotic coal-black,
  the special rootstone is ordinary granite. *"The common item wears the exotic
  look."*

**The held-tool frames are this sweep's fourth invalid set.** Every tool renders
STOWED on the back or hip rather than in hand, the camera faces the character's
back so the attachment is occluded anyway, and `held-fishing_rod` contains no
rod at all. The set cannot answer the question it was built to ask, and the
critic said so. Re-shoot required before any held-tool finding is credited —
though `held-hammer` showing *"an untextured near-black rectangular beam ~1.4m
long, no discernible head"* is consistent with the data (`items.json` gives the
hammer `quaternius_survival/Axe.obj`) and is a real defect either way.

**What works:** `world-rootstone` is *"the best prop in either set"*; the axe and
pickaxe heads are real assets; the village in `05-trainer-battle-clean` is
*"cozy and correctly scaled"*; and the icon sheet's own SHARED-ICON flagging is
*"honest and well-organized bookkeeping — the flags just haven't been acted on."*

## Known and already fixed before this pass ran

The critic reported the icon sheet cropped at ~26 of 55 tiles with the GEAR row
cut off. That was a viewport height bug found and fixed earlier the same day
(2200 -> 2800px); this pass judged the pre-fix sheet. The re-shoot is queued.
