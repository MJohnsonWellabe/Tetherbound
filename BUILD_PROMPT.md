# BUILD_PROMPT.md

Paste the block below into Claude Code in an empty repo that already contains `CLAUDE.md`, `GAME_DESIGN.md`, `ARCHITECTURE.md`, `ASSETS.md`, and `ROADMAP.md`.

---

## Kickoff prompt (M0 + M1)

```
Read CLAUDE.md, ARCHITECTURE.md, GAME_DESIGN.md, ASSETS.md, and ROADMAP.md in full before writing anything. They are the spec.

Build milestones M0 and M1 from ROADMAP.md in one pass. Do not ask me questions along the way. Where a small decision is ambiguous, choose, log it as a new file in docs/decisions/, and continue.

M0 deliverables:
- Vite + TypeScript + Three.js project scaffold with strict mode, vitest configured, and vite.config.ts base set to the repo name for GitHub Pages.
- .github/workflows/deploy.yml that runs typecheck, test, build, and deploys to Pages on push to main.
- Seeded simplex-noise heightfield terrain. 64m chunks, 5-chunk view distance, LOD at 3, full disposal on unload. Every generation decision uses a mulberry32 RNG seeded from the world seed plus chunk coords. No Math.random anywhere in world generation.
- Poisson-disk scatter of placeholder props (trees as cylinder plus cone, rocks as low-poly icospheres, bushes as spheres) using InstancedMesh, one instanced mesh per prop family per chunk, shared materials, instance color for tint variation.
- Capsule character controller against the heightfield: gravity, 45 degree slope clamp, 0.4m step offset, sprint, jump. No physics library.
- Third person over-the-shoulder camera with collision pullback.
- Input.ts exposing the Intent interface from ARCHITECTURE.md. Touch layer (left virtual stick, right drag look, on-screen buttons) and desktop layer (WASD, mouse look with pointer lock, space, shift). Gameplay reads only Intent.
- Fixed 60Hz accumulator loop in Loop.ts with interpolated rendering.
- Day/night cycle, 20 real minutes, sun position and fog color driven by time.
- ?stats=1 URL flag showing FPS, frame time, draw calls, and triangle count.
- npm run dev binds --host and prints the LAN URL.

M1 deliverables:
- Vitals system: health, stamina, hunger with the exact rules in GAME_DESIGN.md section 4, including starving damage, fainting, and the satchel drop.
- Harvest nodes on scatter props: trees give wood, rocks give stone and flint, bushes give fiber and berries. Node state persists in worldDeltas and respawns after 2 in-game days.
- Tools: stone axe, stone pick, hammer, flint knife with durability. Tools cannot target creatures or NPCs, enforce this explicitly.
- Inventory: 24 slots, stacking, a hotbar of 6, drag-and-drop that works with touch. HTML overlay UI, not in-canvas.
- Crafting from recipes.json. Workbench, campfire, bed, tanning rack as placeable stations. Campfire cooks food and applies the timed buffs from the design doc.
- Build mode: hammer equipped opens a radial piece menu. Snap-grid placement with socket matching within 0.5m, ghost preview with valid/invalid tint, rotate and elevation nudge, stamina cost, refund on removal. Wood tier pieces only, built from primitives, defined in pieces.json.
- Bed sets respawn point. Faint moves inventory to a satchel marker at the death location with a compass indicator.
- SaveManager: localStorage with the SaveV1 schema from ARCHITECTURE.md, autosave every 60s and on visibility change, load with validation and party-length clamping.
- Data files: items.json, recipes.json, pieces.json populated with real values from GAME_DESIGN.md sections 8. Create empty but schema-correct species.json, moves.json, spawns.json, and dialogue.json for M2.
- Vitest tests for: crafting cost resolution, inventory stacking and overflow, vitals tick math, and save round-trip.

All UI is mobile-first. 44px minimum touch targets. Test your layout assumptions at 390x844.

Placeholder art only. Do not download any assets in this pass.

When you finish, run typecheck and tests, commit, push, confirm the Pages deploy succeeded, and give me the live URL plus a short list of every decision you logged in docs/decisions/.
```

---

## Follow-up prompt (M2, run after M0 and M1 are live)

```
Read CLAUDE.md and GAME_DESIGN.md sections 5, 6, and 7 again, then build M2 from ROADMAP.md.

Populate species.json with all 15 Meadows species from the design doc, including base stat blocks you derive to fit the level bands and roles described, catch rates, spawn weights, time-of-day windows, and their two moves. Populate moves.json with quick attacks in the 8 to 14 power band and power attacks in the 40 to 70 band.

Build:
- Pal entities with a wander/graze/flee/aggro finite state machine, pooled, capped at 12 active within view distance, spawned from spawns.json by chunk type and time of day.
- Combat Mode as a state, not a scene. Camera pulls to arena framing, world keeps rendering, HUD swaps, soft fog ring marks the bounds. No loading screen.
- Real-time combat exactly as specified: auto-facing active pal, tap quick attack, hold-to-charge power attack gated on 100 charge, swipe or A/D dodge, 0.6s enemy telegraph where a timed dodge fully negates.
- Pure functions in combat/Damage.ts for the type ring and the damage formula, unit tested across all 25 type pairs.
- Throw system: drag-and-release arc with trajectory preview, shrinking catch ring with good and great bonus windows, three-shake sequence, catch roll using the exact formula in section 7. Failed throws consume the orb and grant the enemy a free attack window. Pure function in combat/Throw.ts, unit tested for the 0.01 to 0.95 clamp.
- Wild flee behavior at 20% HP, 25% per second.
- Party.ts with the five-slot cap enforced in add() and nowhere else. A sixth capture pauses and opens the release screen showing all six with level, affinity, and time held, behind a two-step confirm. Released pals go into releasedLedger and never return.
- Progression: XP curve, level ups, affinity gains and losses, faint and revive at campfire or 4 minutes.
- Party HUD pips, pal detail screen, swap on slot tap or number key.

Test-first for everything in combat/ and party/. Ship to Pages when green.
```

---

## Notes for the operator

Run these on a branch. After M0 and M1 land, actually play it on your phone for ten minutes before you queue M2. The character controller feel and the touch stick deadzone are the two things most likely to be wrong, and they are much cheaper to fix before combat is layered on top.
