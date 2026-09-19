# D13 — The Meadows wild roster is recanonised by the owner's pack

> Starter scale amended by D19 (owner decision, 2026-08-09).
>
> Extended by D23 (owner spec, 2026-08-11): a fourth distinction rule —
> **Burrowback must not read as Terrapup** — and a hard constraint that all
> such separation is done by material and palette, never by regenerating a
> mesh.
>
> This file's "the twelve Meadows wild species and the one evolution" is
> amended by D71 (owner instruction, 2026-08-30): Mudsnout now evolves into
> Tuskroot **or** Ashtusk, depending on which catalyst stone is spent. The
> biome still has exactly one evolving species; that species no longer has
> exactly one destination.
> Vocabulary note: written when the game called its creatures "pals"; R1.1 (2026-08-14) renamed the term to "creature" throughout the codebase without rewriting this historical record.

**Status:** accepted, in full. The scale conflict below was put to the owner
and answered: **D12's peer scale stands.**
**Decided:** on delivery of `Tetherbound_Meadows_Wild_Canon_Pack.zip`

## The decision

`docs/art/wild/` is the source of truth for the **twelve Meadows wild species
and the one evolution**. Its own directive: *"When a previous note or
placeholder conflicts with this pack, follow this pack."*

The pack does not cover the starters, the legendary, Grandpa, the Warden or
the player character. Those six are already produced and are untouched by it.

## What changed

| | before (`REFERENCE_CANON.md`) | now |
|---|---|---|
| Wild species | 13 | **12**, plus 1 evolution |
| Evolutions | Trailpup → Ridgewolf | **Mudsnout → Tuskroot**, and nothing else |
| **Ridgewolf** | a species | **retired.** "That the canine evolves in Meadows" is named as a superseded assumption |
| **Mudsnout** | did not exist | **new.** Ground pig / rooting runt, the pre-evolution of Tuskroot |
| **Tuskroot** | a base wild species | now the **evolved** form, not something you meet as a base creature |
| Reference quality | boards `05`–`08`, which contradicted each other | five real turnaround sheets, `01`–`04` quality |

Three distinction rules are now explicit, and all three exist to stop a wild
creature reading as something the player already knows:

- **Meadowhart** must not read like the legendary. It is a practical rideable
  mount, "lighter, friendlier, more practical — less sacred".
- **Trailpup** must not read like the Ground starter. Leaner, coyote-like, and
  specifically **not stone-mantled** — the mantle is Terrapup's.
- **Galecrest** must not read like the Air starter. A true raptor, "not a
  starter-like cute fox-bird hybrid".

## The scale conflict, and how it was settled

**This is the one thing the pack and an existing accepted decision disagree
about, and it is not being resolved silently.**

`D12-pals-are-peers-not-pets.md` records the owner's instruction to scale
creatures up to stand as peers to the 1.8 m trainer — *"just want them to have
more emphasis and focus in the game so the large size will be good"* — and
`species.json` was rebuilt around it: Bramblebun 1.35 m, Tuskroot 2.00 m.

The pack's implementation notes say **"Average size around player scale
(0.6–1.6 m)"**, and its scale chart draws Bramblebun at roughly 0.5 m and
Tuskroot at roughly 1.5 m. Its directive also says *"Do not design the roster
as tiny critters plus one giant mount"* and asks for creatures that feel
"physically present".

Both are the owner's words. They point at different numbers:

| | D12 (in the game today) | this pack |
|---|---|---|
| Bramblebun | 1.35 m | ~0.5 m |
| Tuskroot | 2.00 m | ~1.5 m |
| stated range | 1.35–2.00 m | 0.6–1.6 m |

The two are not as far apart as they look — both are reacting against the same
thing, creatures so small they live in the bottom quarter of the frame — but
they cannot both be entered into `species.json`.

**Asked, not assumed.** `CLAUDE.md` forbids silently inventing a major design
decision, and the pack itself says to flag conflicts. It was put to the owner
with both sets of numbers side by side.

### The answer: D12's peer scale stands

`species.json` keeps 1.35–2.00 m, and the wild roster is built to it. The
pack's sheets remain authoritative for everything else about these creatures —
name, anatomy, palette, silhouette, materials, the distinction rules — and its
scale chart is treated the way sheets `01`–`04`'s centimetre figures already
are under D12: as the creature's **biology**, true on the page, while game
scale is a separate question that the owner has answered twice now in the same
direction.

Practically this means each species is drawn from its sheet and then given a
height in the D12 band, keeping the sheets' **relative** ordering — Pipwing and
Bramblebun smallest, Meadowhart, Galecrest and Tuskroot largest — so the
variety the pack asks for survives even though the floor is higher. The pack's
own worry, *"do not design the roster as tiny critters plus one giant mount"*,
is satisfied more comfortably at peer scale than below it.

No model has to be rebuilt for this: height is one number per species in a data
file, applied at load by `pal_body._fit()`.

## Consequences for work already done

- `species.json` currently holds `tuskroot` as a base species with a
  stand-in model. It stays for now — it is still a real creature, just
  reached by evolution — but it needs `mudsnout` in front of it, and the
  evolution link has no representation in data yet. There is no evolution
  system in the project at all; this is the first thing that will ask for one.
- `bramblebun` is unaffected: still a base wild Ground species, still the
  first creature the player meets in `docs/specs/OPENING_SEQUENCE.md`.
- The thirteen text-to-3D prompts committed in `tools/art_pipeline/meshy.py`
  were written against the old roster. Ridgewolf's is now dead, Mudsnout has
  none, and every other prompt should be rewritten from these sheets rather
  than from the old boards — the whole reason the pack exists is that it
  replaces guesswork with drawn reference.
