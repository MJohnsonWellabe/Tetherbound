# CLAUDE.md — Working Agreement

You are building **TETHERBOUND**, a Babylon.js open-world survival-craft creature-collector that deploys to GitHub Pages and must play well on a PC handheld.

The renderer is Babylon, not the Three.js named in `docs/03_TECHNICAL_ARCHITECTURE.md`. `docs/decisions/D01-renderer-is-babylon-not-three.md` has the reasoning and the guardrail that keeps it reversible. Only `src/core/babylon.ts` and `src/core/babylonLoaders.ts` may import the engine, and `tests/bundle.test.ts` fails the build if anything else does.

The game bible lives in `docs/`. Read in this order before writing code:

1. `docs/00_EXECUTIVE_VISION.md` — the pitch and the one rule everything serves
2. `docs/01_GAME_DESIGN.md` — every system, stat, formula and content list
3. `docs/02_ART_BIBLE.md` — the visual target and the critic-loop process
4. `docs/06_VISUAL_SYSTEM_PHASING.md` — the system-by-system order and status
5. `docs/03_TECHNICAL_ARCHITECTURE.md` — the stack and the repo structure
6. `docs/04_ASSET_PIPELINE.md` — sourcing and the manifest requirement
7. `docs/05_ROADMAP.md` — milestone order and the full biome plan

They are the source of truth. If something here conflicts with them, they win, and you flag the conflict. Two exceptions, both already decided and both recorded, where the docs are wrong and this file is right:

- **Assets are not CC0-only.** `docs/04_ASSET_PIPELINE.md` still says they are. The owner waived it twice (D42, and again with these documents). `ASSET_MANIFEST.md` is a provenance log, not a licence gate.
- **Post-processing is allowed and the phone budget is dead.** `docs/03_TECHNICAL_ARCHITECTURE.md` still budgets an iPhone 12 at under 150 draw calls with no post-processing. D28 moved the target to a ROG Ally; D63 lifted the ceiling and added the colour grade.

## Development philosophy

Build quick, iterate. Working and ugly beats elegant and unfinished. Ship each milestone to Pages before starting the next one. When a design decision is ambiguous and both options are reasonable, pick one, write it down as a new file in `docs/decisions/`, and keep moving. Do not stop to ask about small things. `DECISIONS.md` explains the format; `npm run decisions` lists what is already recorded, and reading that list first will save you rediscovering a bug someone already paid for.

Stop and ask only when the choice would be expensive to reverse: schema shape, the party cap, the input abstraction, the biome data boundary.

## Hard constraints, never violate

1. **Party cap is five.** Enforced in `Party.add()` and nowhere else. There is no code path that produces a party of six.
2. **The player never wields a weapon.** Tools gather and build. They cannot target pals or people.
3. **The throw is always available in combat**, from the first frame of a fight.
4. **No storage box, no pal bank.** Releasing is permanent.
5. **Every tunable number lives in `src/data/*.json`.** If you type a stat, cost, rate, duration, or curve constant into a system file, you have made a mistake.
6. **No `Math.random()` in world generation.** Seeded RNG only.
7. **Every shipped asset has a manifest row** in `ASSET_MANIFEST.md` before commit. Licence is not a gate (D42); provenance is. `tests/assets.test.ts` checks coverage both ways, so a file cannot ship without a row and a row cannot outlive its file.
8. **PC handheld is the primary target.** The reference device is a ROG Ally: 1080p, 120Hz, gamepad plus touchscreen. Test at 1280x720 first. Nothing may depend on hover, and every control must be reachable on a gamepad. Touch stays supported and must keep working, but it no longer constrains the perf budget, the view distance, or the UI layout. Changed from mobile-first at the owner's direction, logged as D28.

## Code standards

- TypeScript strict. No `any` outside third-party shims.
- Pure functions for all game math. Side effects live in systems, never in formulas.
- One responsibility per file. If a file passes 300 lines, split it.
- Fixed 60Hz simulation via the accumulator in `Loop.ts`. Never multiply gameplay values by raw frame delta.
- Dispose every geometry, material, and texture you create. Chunk unload must be leak-free.
- Comments explain why, not what. Skip the obvious ones.
- No new dependency without a one-line justification in `docs/decisions/`. The approved list is @babylonjs/core, @babylonjs/loaders, howler, simplex-noise and firebase (D01, D05). Dev dependencies are freer.

## Commands

```bash
npm run dev        # local, opens on network so a phone can hit it
npm run typecheck
npm run test
npm run build
npm run preview
npm run assets         # optimize assets_raw into public, and rewrite the manifest
npm run assets:fetch   # download sources into assets_raw/ (gitignored)
npm run decisions      # index of docs/decisions/, and the next free number
```

Looking at what the game renders, which is not optional before claiming a
visual change worked:

```bash
export CHROMIUM_PATH=/opt/pw-browsers/chromium   # or the tools launch nothing
npm run build && npm run preview -- --port 4173 --strictPort &
node tools/probe.mjs shots-x --close   # 3 frames, fast, head height
node tools/survey.mjs --out shots-x    # all 9, slow
node tools/sheet.mjs --in shots-x --out shots-x/_sheet.png
```

Use `probe` while iterating and `survey` for the record. `--close` is the only
framing that shows ground cover honestly; the survey's 3.2m eye pitched down
flattens a tuft into a speck. Frame times from either are software-rendered and
are not a device measurement.

`npm run dev` must bind `--host` so the phone on the same wifi can load it. Print the LAN URL.

## Workflow

- One milestone per branch, squash merge to `main`.
- Every commit must pass typecheck and tests. The deploy workflow enforces this.
- After each milestone: update `docs/05_ROADMAP.md` with what actually shipped, add any new files to `docs/decisions/`, and post the Pages URL.
- Write the test before the formula for anything in `combat/` or `party/`.

## Performance discipline

Check `?stats=1` at the end of every session. If draw calls pass 150 or frame time passes 8ms at 1080p, fix it before adding the next feature. Performance debt in a web renderer compounds faster than any other kind.

Instanced meshes and shared materials from day one. Object pools for pals, orbs, particles, and damage numbers from day one. Retrofitting these is a rewrite.

## Writing style for all docs and in-game text

Direct and specific. No filler, no marketing voice. No em dashes. Avoid "not X, but Y" constructions. In-game dialogue is terse and grounded; Grandpa Orin does not make speeches.

## What to do when stuck

If a system is fighting you for more than 30 minutes, cut scope and note it in `docs/decisions/`. A simpler version that ships this session is worth more than the right version next week. Structural integrity was cut this way already and the game is better for it.
