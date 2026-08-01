# TETHERBOUND — Architecture

## Stack

| Layer | Choice | Why |
|---|---|---|
| Renderer | Three.js (latest stable, npm) | Requirement |
| Language | TypeScript, strict mode | Catches data-shape errors early in a data-driven game |
| Bundler | Vite | Fast HMR, trivial GitHub Pages build |
| State | Plain TS modules and a small event bus. No React, no Redux. | The HUD is DOM overlay, not a component tree |
| UI | HTML/CSS overlay on top of the canvas | Cheaper and more accessible than in-canvas UI |
| Physics | Custom capsule-vs-heightfield character controller. No physics engine. | A full physics lib is scope we do not need |
| Audio | Howler.js | Mobile autoplay handling is already solved there |
| Save | localStorage + base64 export | No backend |
| Deploy | GitHub Actions to GitHub Pages | Requirement |

Set `base` in `vite.config.ts` to `/<repo-name>/` or Pages will 404 every asset.

## Repo layout

```
/
├─ index.html
├─ vite.config.ts
├─ public/
│  ├─ models/            # .glb, Draco compressed
│  ├─ textures/          # .ktx2 or .webp
│  └─ audio/
├─ src/
│  ├─ main.ts            # bootstrap, canvas, loop start
│  ├─ core/
│  │  ├─ Engine.ts       # renderer, scene, camera, fixed-step loop
│  │  ├─ Loop.ts         # fixed 60Hz update, decoupled render
│  │  ├─ EventBus.ts
│  │  ├─ Input.ts        # unified touch + keyboard/mouse
│  │  ├─ AssetLoader.ts  # GLTF/Draco/KTX2, progress, caching
│  │  └─ SaveManager.ts
│  ├─ world/
│  │  ├─ WorldGen.ts     # seeded noise, biome mask
│  │  ├─ ChunkManager.ts # stream, LOD, dispose
│  │  ├─ Scatter.ts      # poisson-disk props
│  │  ├─ Landmarks.ts    # village, hall, standing stones
│  │  └─ TimeOfDay.ts
│  ├─ entities/
│  │  ├─ Player.ts
│  │  ├─ Pal.ts
│  │  ├─ PalAI.ts        # wander/graze/flee/aggro FSM
│  │  ├─ SpawnManager.ts
│  │  └─ NPC.ts
│  ├─ combat/
│  │  ├─ CombatMode.ts   # enter/exit, camera framing, arena
│  │  ├─ Damage.ts       # pure functions, unit tested
│  │  ├─ Throw.ts        # arc, ring timing, catch roll
│  │  └─ MoveResolver.ts
│  ├─ survival/
│  │  ├─ Vitals.ts       # health/stamina/hunger ticks
│  │  ├─ Inventory.ts
│  │  ├─ Crafting.ts
│  │  └─ Satchel.ts      # faint drop
│  ├─ building/
│  │  ├─ BuildMode.ts
│  │  ├─ SnapGrid.ts     # socket matching
│  │  └─ PieceRegistry.ts
│  ├─ party/
│  │  ├─ Party.ts        # HARD CAP 5 lives here and only here
│  │  ├─ Progression.ts  # xp, levels, affinity
│  │  └─ Release.ts
│  ├─ ui/
│  │  ├─ HUD.ts
│  │  ├─ screens/
│  │  └─ styles/
│  ├─ data/
│  │  ├─ species.json
│  │  ├─ moves.json
│  │  ├─ items.json
│  │  ├─ recipes.json
│  │  ├─ pieces.json
│  │  ├─ spawns.json
│  │  └─ dialogue.json
│  └─ types/
└─ tests/                # vitest, pure logic only
```

## Non-negotiable rules

1. **Everything tunable lives in `src/data/*.json`.** No stat, cost, rate, or curve is written inline in a system file. If a designer would want to change it, it is data.
2. **The party cap is enforced in exactly one place**, `Party.add()`. Every other path goes through it. There is no second code path that can put six pals in a party.
3. **Damage, catch, and XP math are pure functions** in `combat/Damage.ts`, `combat/Throw.ts`, and `party/Progression.ts`. They take numbers, return numbers, touch no globals, and are unit tested.
4. **Fixed timestep of 60Hz for simulation**, render decoupled and interpolated. Accumulator pattern in `Loop.ts`. Never scale gameplay by raw frame delta.
5. **Combat Mode is a state, not a scene.** The world keeps rendering. No loading screen ever appears after initial boot.
6. **Dispose everything.** Every geometry, material, and texture created by ChunkManager gets disposed on unload. Leaks kill mobile within minutes.

## Performance budget

Target 60fps on an iPhone 12 and a 2019 mid-range Android, 60fps on any desktop from the last six years.

| Metric | Budget |
|---|---|
| Draw calls | < 150 |
| Triangles on screen | < 300k |
| Textures resident | < 120 MB |
| Initial bundle + first chunk | < 8 MB |
| Time to interactive on 4G | < 6s |

Techniques required from milestone 1, not retrofitted later:

- `InstancedMesh` for all scatter props. Grass, trees, rocks, and flowers are instanced per chunk.
- Shared materials. One material per prop family, tinted with instance color attributes.
- Object pooling for pals, damage numbers, particles, and orbs.
- Frustum culling on, plus a manual distance cull for pals beyond 3 chunks.
- Texture atlasing for props. KTX2 with Basis where the loader supports it, WebP fallback.
- Cap `pixelRatio` at 2, and at 1.5 on touch devices.
- Shadow map at 1024 on desktop, 512 on mobile, single directional light casting.
- No post-processing in v0.1 except an optional cheap vignette.

Add a `?stats=1` URL flag that shows an FPS, draw call, and triangle readout. Use it every session.

## Input abstraction

`Input.ts` exposes an intent layer, never raw events:

```ts
interface Intent {
  move: { x: number; y: number };   // -1..1
  look: { x: number; y: number };
  sprint: boolean;
  jump: boolean;
  interact: boolean;
  primary: { down: boolean; heldMs: number };
  dodge: -1 | 0 | 1;
  slot: 1|2|3|4|5|null;
}
```

Touch and keyboard both write into this. Gameplay code reads only this. Detect touch capability at boot and mount the correct control layer.

## Character controller

Capsule against the heightfield. Sample terrain height at the capsule base, resolve penetration along the surface normal, apply gravity, clamp slope to 45 degrees, step offset of 0.4m. Prop collision uses simple sphere and AABB tests against a per-chunk list, no broadphase library needed at this density.

## World generation determinism

```
worldSeed: string
chunkRng  = mulberry32(hash(worldSeed, chunkX, chunkZ))
```

Every placement decision derives from `chunkRng`. Never call `Math.random()` anywhere in generation. A save file stores only the seed plus deltas (harvested nodes, placed structures, killed field bosses), not the terrain.

## Save schema

```ts
interface SaveV1 {
  schemaVersion: 1;
  seed: string;
  createdAt: number; savedAt: number;
  player: { pos: Vec3; rot: number; health: number; stamina: number; hunger: number; buffs: Buff[] };
  inventory: ItemStack[];
  party: PalState[];          // length <= 5, validated on load
  releasedLedger: { species: string; level: number; day: number }[];
  structures: { pieceId: string; pos: Vec3; rot: number; tier: number }[];
  worldDeltas: { harvested: string[]; bossesDown: Record<string, number> };
  progress: { badges: string[]; flags: string[]; day: number; timeOfDay: number };
}
```

`SaveManager.load()` validates, clamps `party.length` to 5, and refuses to import a save whose `schemaVersion` it does not have a migration for.

## Testing

Vitest on pure logic only. No renderer tests, no e2e in v0.1.

Required test coverage:
- Type effectiveness matrix returns the right multiplier for all 25 pairs.
- Damage formula is monotonic in ATK and inverse-monotonic in DEF.
- Catch chance stays inside 0.01 and 0.95 across the full input range.
- `Party.add()` throws or returns a `needsRelease` signal at 5, never appends a sixth.
- XP curve is strictly increasing and level 50 is reachable.
- Save round-trips through export and import without loss.

## Deployment

`.github/workflows/deploy.yml` on push to `main`: install, typecheck, test, build, upload artifact, deploy to Pages. A failing typecheck or test blocks the deploy.
