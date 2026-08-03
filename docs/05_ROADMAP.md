# 05 — Roadmap

See `docs/vision/00_EXECUTIVE_VISION.md` for what each milestone is in service
of. Every milestone that touches rendering must run the critic loop in
`docs/02_ART_BIBLE.md`, worked system by system per the order and status
table in `docs/06_VISUAL_SYSTEM_PHASING.md`, before being marked done.

Philosophy: quality wins over pace. Every milestone ends with something deployed
to Pages and playable on a phone, but "done" for anything rendered means it has
cleared the critic loop in `docs/02_ART_BIBLE.md`, not just that it works. There
are no session targets below on purpose: a milestone takes as long as it takes
to clear its bar. If a milestone is running long, cut a system out of it into a
later milestone or out of v0.1 scope entirely, logged in
`docs/archive/DECISIONS.md`. Never ship a system under-baked to hit a deadline.

---

## M0 — Walk on ground

- Vite + TS + Babylon.js scaffold, GitHub Actions deploying to Pages.
- Seeded heightfield terrain, chunk streaming, 5-chunk view distance.
- Capsule character controller, third person camera.
- Touch stick and look-drag, WASD and mouse.
- `?stats=1` performance readout.

**Done when:** you can walk around a seeded world on your phone at 60fps, live on Pages, and the ground/sky/lighting system has cleared the M0 critic loop in `docs/02_ART_BIBLE.md` against `docs/reference/` — stylized, not a flat gray plane with a default skybox.

---

## M1 — Survive and build

- Health, stamina, hunger with the middle-tier rules.
- Trees, rocks, bushes as harvestable nodes. Axe, pick, knife.
- Inventory, 24 slots, drag and drop, mobile-friendly.
- Workbench, campfire, bed. Cooking and food buffs.
- Snap-grid build mode with the wood tier pieces.
- Faint, satchel drop, respawn at bed.
- localStorage save and load.

**Done when:** you can chop, cook, build a shack, sleep, and reload into it, and vegetation and building pieces have both cleared their critic loops — no see-through walls, no sparse foliage, no primitive capsules standing in for trees.

---

## M2 — Pals and combat

- Pal entities, wander/graze/flee/aggro FSM, spawn tables by chunk and time of day.
- Combat Mode enter and exit, arena framing, HUD swap.
- Quick attack, power attack with charge, dodge with telegraph windows.
- Type ring and damage formula, unit tested.
- Throw: arc preview, catch ring, shake sequence, catch roll.
- Capture, party add, the five-slot enforcement and the release screen.
- XP, levels, affinity, faint and revive.

**Done when:** you can find a Tuftmoth, fight it, throw an orb, catch it, and it fights for you at level 4, and the pal's cel-shaded model and its silhouette against the meadow have cleared the critic loop — readable at combat distance, not a tinted placeholder.

---

## M3 — Game shape

- Hollowbrook Village, Grandpa Orin, the starter choice scene.
- Dialogue system, data driven from `dialogue.json`.
- Party screen, pal detail screen, map screen, compass.
- Full 15-species Meadows roster with real spawn weights.
- Loamking field boss at the standing stones.
- Save export and import strings.

**Done when:** a new player can start cold, pick a starter, and know what to do next without being told.

---

## M4 — The Meadows Hall

- Hall exterior and interior, seeded placement, road stub.
- Tether grunts, two fights.
- Bracken Holt, three-pal fight, collar mechanics, un-catchable enemies.
- Cut-tether victory sequence, Loamking recruit offer.
- Meadow Sigil badge, Orb Bench unlock, Truestone Orb.

**Done when:** the game has a beginning, a middle, and a win state.

---

## M5 — Cohesion and feel

Every system by this point has already cleared its own critic loop
individually. M5 is the whole-scene pass, not the first time art gets
attention:

- Full-scene critic pass: capture the same 8 reference viewpoints from
  `docs/02_ART_BIBLE.md` together in one sitting and check they read as one
  consistent world, not eight individually-passing systems that don't quite
  agree with each other on light, palette, or scale.
- Full audio pass.
- Screen shake, hit pause, damage numbers, particles.
- Day/night lighting and fog tuning.
- Balance pass on catch rates, XP curve, and Bracken's difficulty.
- Onboarding polish, first-session drop-off review.

**Done when:** you would hand it to a stranger without apologizing, and the
whole-scene critic pass signs off on cohesion, not just each part in
isolation.

---

## M6 — Biome template

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
