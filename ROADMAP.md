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

**Shipped.** Babylon rather than Three (D1). Seeded heightfield, 128m chunks at
view distance 3, LOD, full disposal. Props batched by spatial cell rather than
by chunk (D29). Capsule controller, third person camera. Input as three layers
behind one Intent: keyboard/mouse, touch, and gamepad (D31). Day/night with fog
tuned to the prop draw distances. `?stats=1` readout.

Perf, measured at 1280x720 in a dense grove: **67 draw calls, 137k triangles**,
down from 1576 and 224k. Retargeted from phone to ROG Ally (D28).

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

**Shipped.** Vitals, inventory and crafting. Harvest nodes on trees, rocks and
bushes with seeded drops and tool-action matching, and the no-weapon rule
enforced as an allowlist (D33). Build mode on the hammer with pure snap logic.
Workbench, campfire, bed, tanning rack and orb bench as placeable stations; the
campfire revives fainted pals one at a time, the bed sets the respawn point and
sleeps to morning when nothing hostile is near. Faint drops the satchel, keeps
tools, and wakes you at your bed. SaveManager on the SaveV1 schema with autosave,
base64 export/import, a rollback slot and the party clamped to five on load.

Verified in a browser: 40 wood placed a floor for 4 and refunded 2 on undo, a
campfire revived a fainted pal after 30s, fainting dropped 40 wood and kept the
axe, collecting returned all 43 items, and stations plus respawn survived
export/import.

**Not done:** the drag-and-drop inventory screen and the radial build menu.
Both are UI over systems that already work, and both land with M3's screens.

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

**Shipped.** All 15 Meadows species in `species.json` with stat blocks, catch
rates, level bands, time windows and the model mapping ASSETS.md specifies.
Wander/graze/flee/aggro FSM, pooled at the 12-pal cap, seeded spawn tables by
biome and time of day with night level bonuses. Combat Mode as a state, not a
scene (D34). Quick and power attacks off hold length, enemy telegraph with a
dodge window that negates entirely, swap vulnerability. The throw available from
frame one, catch ring, three shakes, and the exact section 7 formula. Flee at
20% HP. Party with the cap in `add()` and nowhere else, the two-step release
screen, XP, levels and affinity.

Verified in a browser: a grazehorn L9 spawned, walking into it entered combat,
the fifth orb held, and the party went from one pal to two. A sixth capture was
refused and opened the release screen; the party never held six.

99 unit tests on the pure math, including all 25 type pairs and a 3,240-case
sweep of the catch clamp.

**Not done:** the pal detail screen and portrait pips as real UI; the combat
HUD is a text readout until M5.

---

## M3 — Game shape (target: 2 sessions)

- Hollowbrook Village, Grandpa Orin, the starter choice scene.
- Dialogue system, data driven from `dialogue.json`.
- Party screen, pal detail screen, map screen, compass.
- Full 15-species Meadows roster with real spawn weights.
- Loamking field boss at the standing stones.
- Save export and import strings.

**Done when:** a new player can start cold, pick a starter, and know what to do next without being told.

**Shipped.** The village, Orin, the dialogue system, the full roster and the
Loamking already existed from earlier sessions; this pass closed the actual
gap in the "done when": a fresh game landed the player at the world origin
with an empty party and nothing on screen telling them anything, so combat
was silently unreachable until someone happened to walk into Orin.

- **The wake-up.** A new game now spawns inside the player's own furnished
  house (`Structures.ts`'s `HomeAnchor`) instead of the bare origin, reusing
  the existing boot-overlay fade rather than adding a second one. A loaded
  save is untouched: it overwrites the spawn point with its own saved
  position, same as before.
- **The starting kit moved into the scene.** `main.ts` no longer pre-stuffs
  the inventory; `orin_intro`'s `give:` effects (already written) are now the
  only source of the axe, pick, knife, hammer, wood and three orbs.
- **`Objectives.ts` / `objectives.json`.** A short, ordered, data-driven
  objective chain (talk to Orin, catch a tuftmoth, head east) with three
  predicate kinds (flag, party size, item count), rendered through the
  existing `HUD.setPrompt` and compass, that a loaded save catches up on
  silently rather than toasting stale progress.
- **A guaranteed, docile first catch.** `SpawnManager.spawnScripted` places a
  specific pal at a specific spot; a new `docile` pin on `PalAI.stepAi` locks
  it to wander/graze regardless of its species' own aggro/flee data; a new
  `guaranteed` term in `Throw.ts`'s catch formula (`orbs.json`'s
  `guaranteedChance`) makes the first orb thrown at it land, exactly once,
  while `first_catch` is unset (D60).
- **The unreachable fight now says why.** Walking up to a wild pal with an
  empty party shows a one-time "Talk to Grandpa Orin first" toast instead of
  silently doing nothing.

Verified end to end on a wiped save with the real build (`npm run build` +
`npm run preview`): empty inventory and party at boot, the prompt and compass
pin tracking the active step, Orin's kit and starter landing correctly, the
scripted tuftmoth spawning docile and catching on the first orb, the party
reaching two, and the objective chain advancing to "follow the road east."
439 pre-existing tests plus 24 new ones, all green; `npm run typecheck` clean.

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

### What actually shipped

The CC0-only constraint was waived by the owner partway through, which
changed the ceiling on everything visual (D42). `ASSET_MANIFEST.md` is now a
provenance log rather than a licence gate.

- **Asset pipeline.** `npm run assets` drives a declarative job list from
  gitignored `assets_raw/` into `public/`, baking prop palettes to vertex
  colours and regenerating the manifest. Two long-standing pipeline lies were
  found and fixed: the simplify pass had never once run, and freshness meant
  "the output file exists", so editing a job was a silent no-op (D52).
- **World.** Every prop, building, station and standing stone is a real model
  with the primitive builders kept permanently as the per-slot fallback (D44).
  Terrain gained a detail texture, water gained scroll and bob, and the sky
  gained a gradient dome.
- **Creatures and people.** All fifteen species are distinct rigged,
  skeletal-animated creatures addressed by game verb through a clip map
  (D45); the player and NPCs are rigged humanoids. The active party pal now
  follows you around the world, which is the loudest signal the game is a
  creature-collector.
- **Combat presentation.** Fights stage both creatures on a facing line, play
  real attack and hit clips, throw a visible orb along an arc, and frame
  themselves with a camera request the player rig owns (D46). The ASCII combat
  readout is gone.
- **Interface.** Real vitals bars, a compass that will not overprint itself,
  nameplates over wild pals, and the interaction prompt separated from
  persistent state.
- **Two rendering bugs worth remembering.** Placed structures were drawn
  inside out because a mirrored transform was carried on every clone (D47),
  and every prop in the world was drawn mirrored across the origin because
  `Mesh.clone(name, null)` does not detach a clone from its parent (D53).
  The second one is why the Meadows looked empty through several sessions of
  density tuning that could not possibly have worked.

**Deferred to M5b:** the audio pass, the balance pass on catch rates and
Bracken, and onboarding. The visual-judge loop also left open items on
shadows, night legibility and aerial perspective.

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
