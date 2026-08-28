# CONTENT-0828B — the Warrens payoff, verified; constructed interiors, as a method

Branch `ralph/CONTENT-0828B`. Two owner complaints from
`ralph/OWNER_PLAYTEST_2026-08-28.md`: the Burrow Warrens payoff (§6) and
"constructed spaces look lame" (§4a).

---

## 1. The Burrow Warrens payoff — ALREADY ON `main`, now verified and asserted

`ralph/CONTENT-0828` landed the payoff on `main` before this lane opened: the
guardian routed through the game's own alpha system, a branch door with a lit
seam that sinks when the guardian falls, a boss-scale payout (90 coins, 5
rootstone, 2 Greater Orbs, 1 revive, 140 xp), and the vault's Terrapup named
`Elder Terrapup`. Under CLAUDE.md's "evidence-backed *already fixed* is valid",
the work here was to verify it rather than rebuild it.

**It verifies, and the walked evidence is in `tests/smoke_warrens.gd`:** the cave
walks entrance-to-branch (52 m), the shutter blocks until the flag is set and
opens after, and the clear pays every item its own config names.

**What was NOT verified, and is now.** Every part of CONTENT-0828's answer to
this complaint was *presentation* — the alpha colourway, the rim, the mote
aura, the size multiplier, the signature move — and **nothing asserted any of
it.** The whole payoff could have regressed to a big ordinary burrowback and
the test would have passed and printed the same line. `smoke_warrens.gd` now
asserts, against the config rather than against numbers copied into the test:

- the guardian carries the same `alpha` meta the field's own alphas do;
- its **gameplay** size scaled, not just its art — `body_height()` against the
  species height times `guardian.scale`, because the capsule, the hit cone's
  reach and the catch accuracy bonus all read that and a silhouette that its
  own body does not share is what `creature_body.gd` calls "the invisible
  discrepancy PW2 forbids";
- its charged move is the configured `signature_move`, which is what makes it a
  different fight rather than a longer one.

**One correction worth recording, because it nearly became a false bug report.**
The first version of that assertion read `body_scale` and failed at 1.00
against a config asking 1.35. `body_scale` is the **before-populate** input
field; the guardian is dressed *after* the director spawns it, so it goes
through `apply_size_multiplier()`, which scales the live `_height`/`_radius`
and leaves `body_scale` alone. The product was correct and the assertion was
wrong. It now reads the public accessors.

### What this lane changed about the payoff

Nothing about the design. Two presentation defects found in frames:

- **The prize was an untextured box.** `_build_prize()` called `_box(...,
  _rock())` and `_box()` defaults `textured` to false, so the object at the
  bottom of the chapter's one required dungeon — the thing the entire descent
  is for — was a flat grey cube with a dome on it. That is the same idiom the
  owner rejected for the TM ("cardboard cards"), on the payoff object. It is
  now the cave's own stone, **stepped** into two courses so it reads as
  something built to hold an object rather than as a crate, and the stone
  itself went 0.22 → 0.30 m radius: at 44 cm across a dark eight-metre room the
  light around it was doing all the work of saying something was there and the
  object none.

---

## 2. Constructed spaces — the defect is the METHOD, so the fix is a method

> *"burrow warrens and the castle are the lame looking locations. basically
> everywhere we had to build an under ground or build a building"*

The owner named a **class** of space. `ralph/CONTENT-0828` did a one-off
dressing pass on the Warrens and said so honestly in its own report: *"the walls
themselves are still flat planes and the ceiling is still a slab between its
corners. This pass changes what the room's EDGES do; it does not give the space
vertical interest, level changes, or a silhouette."* It also left the stronghold
untouched, deliberately. That remainder is this lane's scope.

### Why constructed space reads as unfinished here — a mechanism, not taste

Both builders compose a room the same way: a floor box, a ceiling box and four
wall boxes, each one flat plane from corner to corner carrying one triplanar
material at one scale. That gives a room exactly **two scales of incident** —
the room itself (tens of metres) and its props (under a metre). The meadow
outside has five or six: canopy, trunk, bush, fern, tuft, pebble. A surface with
no scale reference in it reads as a blockout however good its texture is, and
that missing **middle scale** is the whole complaint.

The second half is that indoor light here cannot rescue it. Every interior
`OmniLight3D` in both files sets `shadow_enabled = false` — a deliberate
Compatibility-renderer/handheld cost decision, and this lane does **not** reopen
it. Outdoors the sun models form for free. Indoors, a box standing 30 cm off a
wall is lit almost identically to the wall, so the separation has to be built
into the **geometry and its material value**, because no light in these rooms is
going to supply it.

### The method — `scripts/world/interior_structure.gd`

One file, five passes on the junctions and runs a built space actually has:

| pass | what it puts back |
|---|---|
| `bays` | a vertical member with a capital at a repeating pitch along every wall — the scale reference the room has none of, and the largest of the five |
| `course` | a jointed horizontal band at mid-height, one segment per bay, breaking the vertical run |
| `ribs` | ceiling members spanning the short axis, landed **on the bay divisions** so wall and roof read as one structure |
| `reveals` | a jamb-and-lintel frame at both ends of every cut passage, so a doorway is a made thing and not a hole in a plane |
| `corners` | an L-pier in each internal corner — the prior pass's own finding, *"a cave does not have corners"*, and neither does a hall |

**One grammar, two vocabularies.** The passes are identical for a cave and a
fortress; what differs is `jitter` and the materials the consumer hands over. At
`jitter: 0` the members land on their pitch exactly and read as masonry. Above
zero each piece takes a small lean, inset and scale variation and the same code
reads as rock ribbing. That is why this is one file and not two: the owner named
a class of space, so the fix has to be something a class of space can consume.

Rules every pass keeps, each a defect this repo has already paid for:

- **nothing is solid** — no colliders, ever (`stronghold.gd::_build_trim`:
  "a girder with a collider is a ledge the player can stand on halfway up a
  wall");
- **nothing enters a doorway**, tested against the consumer's own recorded list;
- **nothing reaches past `MAX_PROJECT_M` (0.5 m)** — half the metre both
  builders reserve from every wall via `ARENA_WALL_MARGIN`, which
  `combat_arena_bounds_at()` hands to combat as a promise. Enforced in the
  module rather than trusted to each config, so no data edit can silently
  shrink an arena a fight was tuned against.

The two consumers are `burrow_warrens.gd::_build_structure` and
`stronghold.gd::_build_structure`, each about forty lines: collect chambers,
hand over the doorway and opening lists it already records, supply a
role→material callable. Everything else is data
(`burrow_warrens.json`/`stronghold.json` → `interior_structure`).

**Node cost, since it is real:** 170 members across the Warrens' five chambers,
353 across the stronghold's five spaces. Both printed at build. `bay_pitch_m`
is the dial if a perf pass needs it; `enabled: false` turns the whole thing off.

### Three material bugs the frames found, which no amount of geometry fixes

Rendering the change is what turned these up, and each is the same shape as
`MAT-BLOCKOUT` and `STRONGHOLD-MAT`: a surface reached down a code path that
never warmed its material, because `_box()` defaults `textured` to `false`.

1. **Every floor in the Burrow Warrens was untextured** — chambers, passages
   and the outdoor approach ramp — while the walls and ceilings beside them were
   fully textured. It is the largest surface in every room in the dungeon. It
   now takes `Ground030`, the dirt/pebble surface the meadow's own paths already
   use: **a different material from the walls, deliberately**, because a cave
   floor is what has fallen off the walls and been walked on, and giving it the
   wall's own stone would fix "untextured" while leaving the room a single
   material from floor to ceiling — which is the other half of what makes these
   spaces read as blockout.
2. **Every ceiling in the stronghold was untextured** — a flat `_timber()`
   colour on a slab up to 28×28 m, filling the top third of both interior
   frames, and seen end-on over every doorway as a tan block. Textured, and
   darkened, so the new ribs read against it.
3. **Round 1's structure members were the same colour as the walls.** Both
   consumers' role defaults returned the wall's own tone for shafts and corners,
   and the frames came back with walls that had no members in them at all — the
   geometry was there and the photograph showed nothing. Structure is now a
   lighter stone than the infill it stands against, with the recessed course and
   the overhead ribs darker: dressed stone against rubble, which is both what
   this actually is and the only cue available under shadowless omnis. In the
   Warrens the members also needed their own material rather than `_material()`,
   which lerps 75% toward `ROCK_TINT` — correct for the walls, and it leaves a
   member with a quarter of its configured colour.

---

## Evidence

`tools/capture_constructed_interiors.gd` renders eight stands through the real
path (`xvfb-run` + `opengl3` at 1280x800; never `--headless` with a real
driver). Four in the Warrens, four in the stronghold — **the castle's interior
has never been photographed before**, and six of the eight stands are rooms no
previous pass looked at, which is the failure CONTENT-0828's own report named:
*"its blind rounds never caught it because the interior frames it took were the
mouth, the hall and the dressing — not the two deep rooms."*

Half-scale before/after pairs are committed at `docs/evidence/content-0828b/`
(the container is ephemeral and `shots/` is gitignored).

