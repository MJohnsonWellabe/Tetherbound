# TETHERBOUND — Roadmap

Philosophy: build quick, iterate. Every milestone ends with something deployed to Pages and playable on a phone. If a milestone cannot be demoed on a phone, it is not done.

---

## M0 — Walk on ground (target: 1 session)

- Vite + TS + Three.js scaffold, GitHub Actions deploying to Pages.
- Seeded heightfield terrain, chunk streaming, 5-chunk view distance.
- Capsule character controller, third person camera.
- Touch stick and look-drag, WASD and mouse.
- `?stats=1` performance readout.

**Done when:** you can walk around a seeded world on your phone at 60fps, live on Pages.

---

## M1 — Survive and build (target: 2 sessions)

- Health, stamina, hunger with the middle-tier rules.
- Trees, rocks, bushes as harvestable nodes. Axe, pick, knife.
- Inventory, 24 slots, drag and drop, mobile-friendly.
- Workbench, campfire, bed. Cooking and food buffs.
- Snap-grid build mode with the wood tier pieces.
- Faint, satchel drop, respawn at bed.
- localStorage save and load.

**Done when:** you can chop, cook, build a shack, sleep, and reload into it.

---

## M2 — Pals and combat (target: 3 sessions)

- Pal entities, wander/graze/flee/aggro FSM, spawn tables by chunk and time of day.
- Combat Mode enter and exit, arena framing, HUD swap.
- Quick attack, power attack with charge, dodge with telegraph windows.
- Type ring and damage formula, unit tested.
- Throw: arc preview, catch ring, shake sequence, catch roll.
- Capture, party add, the five-slot enforcement and the release screen.
- XP, levels, affinity, faint and revive.

**Done when:** you can find a Tuftmoth, fight it, throw an orb, catch it, and it fights for you at level 4.

---

## M3 — Game shape (target: 2 sessions)

- Hollowbrook Village, Grandpa Orin, the starter choice scene.
- Dialogue system, data driven from `dialogue.json`.
- Party screen, pal detail screen, map screen, compass.
- Full 15-species Meadows roster with real spawn weights.
- Loamking field boss at the standing stones.
- Save export and import strings.

**Done when:** a new player can start cold, pick a starter, and know what to do next without being told.

---

## M4 — The Meadows Hall (target: 2 sessions)

- Hall exterior and interior, seeded placement, road stub.
- Tether grunts, two fights.
- Bracken Holt, three-pal fight, collar mechanics, un-catchable enemies.
- Cut-tether victory sequence, Loamking recruit offer.
- Meadow Sigil badge, Orb Bench unlock, Truestone Orb.

**Done when:** the game has a beginning, a middle, and a win state.

---

## M5 — Feel (target: 2 sessions)

- Replace all placeholders with sourced CC0 models.
- Full audio pass.
- Screen shake, hit pause, damage numbers, particles.
- Day/night lighting and fog tuning.
- Balance pass on catch rates, XP curve, and Bracken's difficulty.
- Onboarding polish, first-session drop-off review.

**Done when:** you would hand it to a stranger without apologizing.

---

## M6 — Biome template (target: 1 session)

Refactor everything Meadows-specific into a biome definition so biome two is a data file plus a species pack plus a Hall, not a rewrite. This is the milestone that decides whether the other seven biomes take weeks or months. Do not skip it.

---

## Biomes and Halls, 2 through 8

| # | Biome | Feel | New mechanic | Hall | Warden | Sigil |
|---|---|---|---|---|---|---|
| 2 | **The Thicket** | Dense dark woodland | Light radius matters, night predators | Root Hall | Marla Vess | Thorn Sigil |
| 3 | **The Shoals** | Coast, tidepools, sea stacks | Swimming and stamina drowning | Tide Hall | Corin Bray | Salt Sigil |
| 4 | **The Mire** | Bog, fog, sunken ruins | Sinking terrain, poison status | Sunk Hall | Odalys Fen | Fen Sigil |
| 5 | **Frostcrown** | Alpine, snow, wind | Cold meter, insulated gear | Rime Hall | Sten Aurr | Rime Sigil |
| 6 | **The Dunes** | Desert, canyons, night cold | Heat meter, water carrying | Glass Hall | Nasrin Coale | Glass Sigil |
| 7 | **Emberfell** | Volcanic ash flats | Ash storms, heat damage zones | Ash Hall | Roque Tallow | Cinder Sigil |
| 8 | **Skyreach** | Floating stone, high winds | Vertical traversal, updrafts | Crown Hall | **The Steward** | Crown Sigil |

The Steward is Team Tether's founder and the final fight, a five-pal team at level 45 to 50.

---

## Post-launch candidates, ranked

1. Seed sharing and a daily seed.
2. Pal affinity events, small idle behaviors at your base.
3. New Game Plus that keeps your party and resets the world.
4. A sixth-slot dilemma twist: a permanent memorial structure at your base listing every pal you released.
5. Photo mode.
6. Co-op. Last, and only if the single player loop is genuinely good.

---

## Cut list, permanently

Breeding. Pal labor and automation. Player weapons. Storage boxes. Mounts. Move learning. Anything that softens the five-slot rule.
