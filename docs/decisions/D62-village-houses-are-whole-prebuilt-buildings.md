# D62. Village houses are whole prebuilt buildings; only the home stays hand-stacked

Kind: implementation

Every Hollowbrook house used to be Fantasy Town Kit wall and roof tiles
stacked in code (`houseA`/`houseB`/`houseC` in `scripts/asset-jobs.mjs`).
Measured before this change: roofs ran 36-51% of total building height, worst
on the Meadows Hall itself at 64% (a stated 8m building rendering 22.6m tall).
The owner played it, said the houses "look atrocious," and chose explicitly:
whole prebuilt house models, and separately that houses are set dressing now,
not enterable, except the player's own home.

## What changed

Four ring slots (every house but the player's own) now use whole,
already-composed GLBs from Quaternius's Medieval Village Pack (CC0, via
poly.pizza, same artist as every creature and humanoid already in the game):
`village_house_b`, `village_house_c`, `village_inn`, `village_blacksmith`.
The pipeline treats them exactly like any other static prop
(`scripts/asset-jobs.mjs`'s `prop` transform: bake to vertex colours, merge to
one mesh, seat at y=0), the same path stations and dressing already use.
`models.buildings.village.variants` is the new pool; `Structures.ts` picks it
for every ring slot except `homeIndex`, which always gets
`HOUSE_VARIANTS[0]` (house_a) regardless of that index, decoupling the home's
model choice from wherever the ring happens to put it.

**The home stays the Kenney composite.** house_a is the one house with a
doorway aperture, a `DoorRegistry` entry, a wall-ring gap, and the
`furnishHome()` numbers below, because the opening scene (GAME_DESIGN.md
section 3) happens inside it. Building a comparable interior/door contract for
a whole prebuilt Quaternius house was more churn than the visual gain was
worth for one building; the mismatch between one composite house and four
prebuilt ones is not visible from outside since players never compare them
side by side.

**Village houses have no door at all**, not a locked one: the new variants
carry no `door` field, so the existing `if (door)` branches in `Structures.ts`
never register a `DoorRegistry` entry, mount a leaf, or cut a wall-ring gap.
The wall ring falls through to the `else` branch that already existed for a
model with no door config, which sizes the collider from the real loaded
mesh's own bounding box rather than a guessed footprint.

**Village dressing is now mostly the same pack**: well, bonfire, two market
stands, two benches, a barrel, a crate, a cart and a fence are Quaternius
pieces replacing (or, for well/cart/fence, reusing the same output filename
as) their Kenney Fantasy Town Kit equivalents. Kenney's lantern and the Hall's
banner stay, no Quaternius equivalent was pulled for either.

**Home interior**: `furnishHome()` (`Structures.ts`) now places a nightstand
(Kenney Furniture Kit `sideTable`) with a lamp standing on it instead of the
old bare emissive cylinder floating at y=1.3 with nothing under it, plus a
chair, a bookcase and a rug (same kit), all with the same load-or-degrade
contract as the existing bed. The floor slab was widened and recentred
(`landmarks.json`'s `home.floor`, 4.2x5.2 offset toward the back wall only ->
5.6x5.6 centred) to actually cover the room; the old size left bare ground
showing at the doorway and ran 2m past the back wall.

## The gamma bake, found by looking at the result

The Quaternius Medieval Village Pack bakes shading into its own textures.
Measured average `COLOR_0` per channel across the shipped output: 0.10-0.16
for every piece from this pack, against 0.48-0.67 for the Kenney pieces
sitting beside them in the same scene (`house_a`, the lantern). Under this
engine's single directional light with no baked-in fill of its own, that read
as a near-black silhouette rather than a lit building; a screenshot from the
village square looked like a rendering bug before the cause was traced to the
source texture. `bakeToVertexColors` (`scripts/lib/glbtool.mjs`) gained an
optional `gamma` parameter, `c' = c ^ gamma` per channel, applied only to this
pack's jobs (`gamma: 0.4`). A gamma curve lifts shadows more than highlights;
a flat multiply strong enough to fix 0.13 would have clipped the pack's own
brighter surfaces to white.

## Performance: real, and only partly closed

Every new building runs 5,700-7,800 raw triangles against 760-2,840 for the
Kenney composite next to it. Two mitigations landed:

- `simplify: 0.4` on the four building jobs, same lever ground cover uses.
  It only bought back ~20-30% (village_blacksmith: 7,659 -> 5,395 tris) and a
  sweep of the simplifier's error bound from 0 to 5.0 could not push it
  further: these ship flat-shaded, a unique vertex per face, so there is no
  shared topology left for an edge collapse to exploit. This is a hard floor
  from the source art, not a knob.
- The four village buildings no longer cast shadows (`Structures.ts`, the
  home still does). Measured effect at the worst position below: small.

Measured with `tools/lib/game.mjs`'s `stats()`, 1280x720, SwiftShader:

| Position | Before (Kenney houses) | After (prebuilt, simplified, no-shadow) |
|---|---|---|
| Village square centre | not measured (no regression) | 3.1-3.8ms, 154 draws |
| ~7m from the nearest big building | 4.2ms, 167 draws | 11.9-13.7ms, 169-171 draws |
| Open meadow, away from the village | not measured (no regression) | 3.0-3.4ms, 132 draws |

Draw calls barely moved (each building is still one merged mesh, one draw
call, per D47/the `prop` contract). Frame time is fine everywhere except
close to one of the four heavy buildings, where it is roughly 3x the 8ms
budget CLAUDE.md sets. The cause, confirmed by toggling shadow casting off
entirely for a real measurement (not a live `renderList` mutation, which
corrupts Babylon's internal cache and produced a false 560ms reading during
diagnosis): main-pass fragment overdraw from these buildings' own layered,
partly-open architecture (stilts, roof overhangs, see-through archways all
overlapping in screen space), not vertex count, not shadow-map cost, and not
a backface-culling bug (checked live: culling and winding are both correct).

**Not fixed this session.** Closing this needs either LOD proxies built from
normal-smoothed geometry (so a decimator has topology to work with, unlike
the flat-shaded shipped mesh) or picking less architecturally "open" models
for the slots closest to normal player paths. Flagged rather than forced,
per CLAUDE.md's own "cut scope and note it" rule: a smaller village that
ships this session beats a fully-optimized one that does not.
