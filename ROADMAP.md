# TETHERBOUND — Roadmap

Philosophy: build quick, iterate. Every milestone ends with something deployed to Pages and playable on a phone. If a milestone cannot be demoed on a phone, it is not done.

**Status: M0 done, M1 partial, M2 done, M3 done, M4 done.** A cold start reaches the Meadow Sigil, verified end to end in a real browser by `tests/smoke/hall.spec.ts`. What M1 still owes is listed under its own heading and in D32.

---

## M0 — Walk on ground (target: 1 session)

- Vite + TS + Three.js scaffold, GitHub Actions deploying to Pages.
- Seeded heightfield terrain, chunk streaming, 5-chunk view distance.
- Capsule character controller, third person camera.
- Touch stick and look-drag, WASD and mouse.
- `?stats=1` performance readout.

**Done when:** you can walk around a seeded world on your phone at 60fps, live on Pages.

---

## M1 — Survive and build (target: 2 sessions) — PARTIAL

- [x] Health, stamina, hunger with the middle-tier rules.
- [ ] Trees, rocks, bushes as harvestable nodes. Axe, pick, knife.
- [x] Inventory, 24 slots, stacking, all-or-nothing removal. No drag-and-drop UI yet.
- [ ] Workbench, campfire, bed. Cooking and food buffs. *(Recipes and station gating exist in `recipes.json` and `Crafting.canCraft`; nothing places a station.)*
- [ ] Snap-grid build mode with the wood tier pieces.
- [x] Faint, satchel drop, respawn, satchel recovery on walk-over.
- [x] localStorage save and load, with validation and a party clamp.

**Done when:** you can chop, cook, build a shack, sleep, and reload into it. **Not yet.** Gathering, cooking and building are the gap. See D32 for why M4 went first and why this is the first thing M5 should pick up.

---

## M2 — Pals and combat (target: 3 sessions) — DONE

- [x] Pal entities, wander/graze/flee/aggro FSM, spawn tables by biome and time of day.
- [x] Combat Mode enter and exit, arena framing, HUD swap. A state, not a scene.
- [x] Quick attack, power attack with charge, dodge with telegraph windows.
- [x] Type ring and damage formula, unit tested across all 25 pairs.
- [x] Throw: catch ring, shake sequence, catch roll. Two taps, not a drag arc (D30).
- [x] Capture, party add, the five-slot enforcement and the release screen.
- [x] XP, levels, affinity, faint and revive.

**Done when:** you can find a Tuftmoth, fight it, throw an orb, catch it, and it fights for you at level 4. **Yes.**

The enemy telegraph fires in the last `windupMs` of a cast rather than the first: announcing it at the start of a 1.2s cast put the flash a full second before impact and left the dodge window unreachable. A failed throw now also locks the player out for the free-attack window, or missing cost nothing.

---

## M3 — Game shape (target: 2 sessions) — DONE

- [x] Hollowbrook Village, Grandpa Orin, the starter choice scene.
- [x] Dialogue system, data driven from `dialogue.json`. Effects are opaque strings the Game applies.
- [x] Party screen with the permanent release ledger, pal cards, compass strip.
- [x] Full 15-species Meadows roster with real spawn weights by biome and phase.
- [x] Loamking at the standing stones, seeded 500 to 700m out.
- [x] Save export and import strings, base64, round-trip tested.
- [ ] Map screen. The compass carries navigation for now.

**Done when:** a new player can start cold, pick a starter, and know what to do next without being told. **Yes.** Orin points east and names the Hall; the compass shows it and the road stub leads back.

---

## M4 — The Meadows Hall (target: 2 sessions) — DONE

- [x] Hall exterior and interior, seeded placement 900 to 1200m out, road stub back to the village.
- [x] Tether grunts, two fights, two pals each.
- [x] Bracken Holt, three-pal fight, collar mechanics, un-catchable enemies. A Hall fight cannot be fled.
- [x] Cut-tether victory sequence, Loamking recruit offer through the six-way release screen.
- [x] Meadow Sigil badge, Orb Bench unlock, Truestone Orb, all gated on the `badge_meadow` flag.

**Done when:** the game has a beginning, a middle, and a win state. **Yes**, and `tests/smoke/hall.spec.ts` drives the whole spine in a real browser: Orin, a starter, both grunts, Bracken's three collared pals, the sigil.

Placement is tested across six seeds for the distance band, the waterline, facing the village, and determinism. The Hall floor sits at terrain height rather than on a raised plinth, because the controller has no physics and walks the heightfield (D29).

---

## M5 — Feel (target: 2 sessions)

- **First: close M1.** Harvest nodes, tool durability, placeable stations, cooking, build mode. Until those land the loop is walk, fight, catch, and the world is a corridor to the Hall rather than somewhere worth crossing. See D32.
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
