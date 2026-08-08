# D12 — The build grid is 2m/3m/90°, measured from the art rather than chosen

**Status:** accepted
**Milestone:** M8, pulled forward
**Authorised by:** the owner, directly — *"a user should be able to go into a
build mode and select any of those pieces to build. then there should be a grid
to snap them to like in valheim"*

## Why this is a decision and not an implementation detail

The words **"grid" and "snap" appear nowhere in any design document.**
`GAME_DESIGN.md` §20 commits to build *categories* — floors, walls, roofs,
doors, fences, beds — and to a tutorial that has you build a shelter, a bed and
a campfire. It says nothing about how a piece is positioned. `CLAUDE.md` lists
changing the stronghold/base structure among the things to flag rather than
invent, so this needed an owner decision before it could exist, and it got one.

Terminology, because the codebase is easy to misread here: **"stronghold" in
this project means an enemy Team Tether fortress**, not the player's base. The
thing being built is the player's *home*.

## The decision

A **2m horizontal cell, a 1m half-step, a 3m storey, 90° rotation.**

Every one of those numbers was **read off the Quaternius Medieval Village
MegaKit's own glTF accessors**, not chosen and not tuned:

| measurement | value | evidence |
|---|---|---|
| wall width | **2.000 m** | all eighteen full-height walls, to three decimals, no exceptions |
| wall height | 3.123 m | `Wall_Arch` is exactly 0..3.0; the others carry a 0.123m decorative cap that overlaps the course above, so the *storey* is 3.0 |
| floor | **2 × 2 m** | all five, origin dead centre |
| half-floors | 1 × 2 and 2 × 1 | which is where the 1m half-step comes from |
| stair rise | **1.0 m** | `Stairs_Exterior_*` are 2.0 × 1.0 × 2.0 — three per storey, exactly |
| roof naming | interior span in metres, always even | `Roof_RoundTiles_4x4` covers 2×2 cells with ~0.75m eaves |

The kit is authored **in metres with no node-level scale**, so unlike the nature
packs it needs no `base_scale` correction — the same trap that had grass
rendering taller than the player.

**This is why the grid is not a tunable.** `data/config/building.json` carries
reach, slope tolerance and ghost colours, all of which are opinions. The grid is
a fact about the art. Changing it without changing the art pack makes pieces
stop meeting each other, and the config says so where a reader will find it.

## The trap that shaped the data format

**The kit uses two different origins.** A floor's origin is the centre of its
tile. A wall's is the bottom-centre of a 2m **edge**. Snap both the same way and
every wall lands half a cell out — which looks like a rotation bug, or like bad
models, and is neither.

So every piece in `data/building/pieces.json` declares an `anchor`, `cell` or
`edge`, and `build_grid.snap()` dispatches on it. An edge anchor also **returns
its own yaw**: a wall lies *along* the edge it sits on, so taking the facing
from the player instead floats walls diagonally across cell corners.
`test_walls_and_floors_disagree_about_their_anchor` exists to make a refactor
that unifies them fail loudly.

## Colliders are measured too

`pieces.json` was **generated** by a script that read each model's bounds; no
extent in it was typed. A collider that disagrees with its art is a wall you can
walk through or a floor with an invisible kerb, and both get reported as physics
bugs rather than as the data errors they are.

## What this decision does not settle

- **Costs.** The design says building consumes Wood/Stone/Fiber/Berries. **No
  inventory exists**, so building cannot cost what the game cannot hold. Free
  placement is a stated scope decision, and the config has a comment saying so
  rather than a silent absence.
- **Stations.** Campfire, bed, pal bed, workbench, storage and berry plot are on
  the M8 list and are deliberately absent: each is a thing with behaviour, not a
  piece of geometry.
- **Structural integrity.** `GAME_DESIGN.md` defers it explicitly — *"unless
  building proves to need it"* — and nothing here changes that.

## The acceptance, and why the test is not it

`tests/smoke_build.gd` places a floor and four walls, saves, reloads, compares
every field, and removes one. It passes. It would **also** pass with every wall
half a cell out, every wall facing the wrong axis, and the roof six metres in
the air.

That last one is not hypothetical: the first run of `tools/preview_build.gd`
added the storey height twice and produced a roof hanging in the sky over a
doorless box. Every assertion passed. One look at the frame found it in a
second.

So the acceptance for this system is **a rendered house with the 1.80m trainer
standing beside it** — `shots/_build_outside.png`. Same principle as D11's
retargeter: the failure modes here all produce data that is structurally valid
and visually wrong.

## See also

- `scripts/building/build_grid.gd` — the maths, and the measurements in its header
- `data/building/pieces.json` — the catalogue, generated from the models
- `data/config/building.json` — the tunables, and the note on why costs are absent
- `docs/decisions/D09-never-raycast-for-ground.md` — placement asks the
  heightfield first; its closing section was written for this milestone
