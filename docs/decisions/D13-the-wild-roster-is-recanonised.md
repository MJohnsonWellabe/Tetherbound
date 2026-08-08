# D13 — The Meadows wild roster is recanonised by the owner's pack

**Status:** accepted for names, composition and evolution. **One open question
on scale**, flagged below rather than decided.
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

## The open question: scale

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
decision, and the pack itself says to flag conflicts. Until it is answered,
`species.json` keeps D12's numbers, because they are what the game currently
ships and what the three produced starters were fitted to.

Nothing else in the roster work depends on the answer: heights are one number
per species in a data file, applied at load by `pal_body._fit()`, so the models
do not have to be rebuilt whichever way it goes.

## Consequences for work already done

- `species.json` currently holds `tuskroot` as a base species with a
  stand-in model. It stays for now — it is still a real creature, just
  reached by evolution — but it needs `mudsnout` in front of it, and the
  evolution link has no representation in data yet. There is no evolution
  system in the project at all; this is the first thing that will ask for one.
- `bramblebun` is unaffected: still a base wild Ground species, still the
  first creature the player meets in `docs/OPENING_SEQUENCE.md`.
- The thirteen text-to-3D prompts committed in `tools/art_pipeline/meshy.py`
  were written against the old roster. Ridgewolf's is now dead, Mudsnout has
  none, and every other prompt should be rewritten from these sheets rather
  than from the old boards — the whole reason the pack exists is that it
  replaces guesswork with drawn reference.
