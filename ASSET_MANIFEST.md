# TETHERBOUND — Asset Manifest

Every asset in `public/` gets a row here before it is committed. No row, no
commit. CC0 or public domain only, per `ASSETS.md`.

| File | Source URL | Author | License | Date pulled | Modified? |
|---|---|---|---|---|---|
| _(none yet)_ | | | | | |

## Why this table is empty

Nothing has been downloaded. Everything visible in the game through M4 is built
from primitives in code, which `ASSETS.md` explicitly calls correct and expected
for the early milestones: "A pal is a capsule with a tinted sphere head. A tree
is a cylinder and a cone."

What is currently placeholder geometry:

| Thing | Built from | Lives in |
|---|---|---|
| Trees, rocks, bushes, grass, reeds, flowers | cylinders, cones, icospheres, boxes | `src/world/Prototypes.ts` |
| Pals, all 15 species | one capsule-and-sphere rig, re-proportioned and tinted per species from `species.json` | `src/entities/PalMesh.ts` |
| People | one capsule-and-sphere rig, tinted per role, Tether wears an orange sash | `src/entities/NPC.ts` |
| Village houses | box plus a four-sided pyramid roof | `src/world/Structures.ts` |
| Standing stones | leaning boxes around a cylinder altar | `src/world/Structures.ts` |
| The Meadows Hall | boxes, a ridge roof, iron tether posts, a segmented road | `src/world/Hall.ts` |
| The arena ring, the catch ring, the sigil | a torus and two CSS gradients | `src/game/CombatMode.ts`, `src/ui/styles/game.css` |

Replacing these is M5's first art task. Because every species maps to
`baseModel + tint + scale + accessory` in `species.json`, swapping in real
models is a data change plus one file, not a gameplay change.

Fonts are the system UI stack (`ui-sans-serif, system-ui, ...`). Nothing is
embedded, so no font licence applies.
