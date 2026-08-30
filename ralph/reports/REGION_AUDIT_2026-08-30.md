# Region audit — the Meadows against its own definition of a finished region

**Lane:** T4-REGIONS (audit). **Date:** 2026-08-30. **Base:** `origin/main` @ `44744fe8`.

This is the first time the project has checked its regions against
`docs/TETHERBOUND_GAME_VISION.md` §8. It is deliberately blunt. A FAIL with a
metre count and a file reference is worth more than a generous PASS, and this
audit exists so the full-chapter playthrough does not have to discover these the
expensive way.

---

## 1. Method, and what this audit can and cannot see

### What was measured

- Every band config under `data/config/bands/<band>/` — spawns, trainers,
  harvest, props, vegetation — read as data, not summarised from prose.
- The real placement code in `scripts/world/playground_world.gd` (TMs, item
  caches, the Sunstone, the ruined watchtower, the gates), parsed directly out
  of the GDScript.
- The authored route: `data/config/terrain_playground.json` → `trail.bands[]`,
  the OW5C spine from the village gate to the stronghold gate.
- `data/creatures/species.json`, `data/config/spawn_tables.json`,
  `data/progression/objectives.json`, `data/dialogue/`, `data/config/map_landmarks.json`.

### The dead-travel probe

`tools/region_cadence_probe.py` (committed with this report) walks the authored
spine and measures dead travel against the authoritative cadence target in
`docs/owner-direction/TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md` §12:

> the player should **rarely go more than roughly 60–90 seconds** without seeing
> or encountering a meaningful reason to fight, catch, gather, investigate,
> prepare, change direction, or anticipate something clearly visible ahead.

Two design decisions make the number honest, and both matter:

**It models coverage, not point-to-point spacing.** A POI at perpendicular
offset `d` from the spine covers the arc interval `s ± sqrt(R² − d²)`. The gaps
are what is left uncovered. An average-gap metric would let six things in a
clump excuse the 700m after it; this does not.

**It tiers content, and uses per-kind notice radii.** A flat radius over
ordinary respawning wildlife makes *any* world pass — the first run of this
probe returned 100% coverage and zero dead runs across all five bands, which is
a fact about the metric, not about the Meadows. A human standing on a ridge
(50m) and a berry bush in long grass (22m) are not noticeable at the same
distance. Three tiers are reported:

| tier | contents |
|---|---|
| **A — structural** | trainers, landmarks, named regions, prop clusters, alphas/elders, built structures, TM discs, caches, signposts |
| **B** | A + harvest nodes |
| **C** | B + ordinary creature clusters |

**Tier A is the one that matters.** "The Meadows feels dead" is never a
complaint about the density of respawning bramblebun.

### Speed conversion

From `data/config/movement.json`: walk 5.0 m/s, sprint 8.6 m/s. Sprint is
stamina-limited (100 stamina, 12/s drain, exhausted below 10, 18/s regen after
1.1s delay), so sustained sprint is impossible. The real cruise is a sawtooth —
7.5s sprinting (64.5m), then 6.1s walking while regenerating (30.5m) = **6.99
m/s sustained**. So §12's 60–90s is:

- **300–450 m** for a walking player
- **419–629 m** at sprint cruise

Grading: **PASS ≤ 450m · PARTIAL ≤ 629m · FAIL > 629m** — a stretch that busts
90s even at sprint cruise is dead by any reading.

### What this audit could NOT see

**No frames were captured. There is no Godot binary in this container** (`which
godot` → nothing). Every judgement below rests on authoring data and placement
code, which is primary evidence for content, cadence, ecology and progression —
but it is *not* evidence for how anything looks. Per
`ralph/MEADOWS_EXIT_CRITERION.md`'s evidence rule, I am not going to launder a
config assertion into a visual verdict.

Consequently, two criteria are only half-judged everywhere, and I say so in each
band rather than quietly scoring them:

- **recognizable geography** — I can judge whether the landform, water and
  landmarks are *authored*; I cannot judge whether they *read*.
- **day/night readability** — I can judge whether night changes the ecology; the
  lighting half is not mine to close and is routed to the visual lane.

I did not attempt a capture rather than produce the exact defect the exit
criterion warns about (frames with no grass geometry plus haze the build lacks).

---

## 2. Headline measurements

### Dead travel — longest uncovered run per band, in metres

| band | spine | **A structural** | B +gathering | C everything |
|---|---:|---:|---:|---:|
| band1 lower meadows | 2403 m | **397 PASS** | 397 PASS | 0 PASS |
| band2 stone & root | 2653 m | **396 PASS** | 208 PASS | 64 PASS |
| band3 the river lock | 2375 m | **668 FAIL** | 256 PASS | 0 PASS |
| band4 upper meadows / ironwood | 3436 m | **1161 FAIL** | 310 PASS | 7 PASS |
| band5 stronghold approach | 651 m | **0 PASS** | 0 PASS | 0 PASS |

**Total authored spine: 11,519 m** — 2304s walking / 1648s at cruise. That is
**27–38 minutes of one-way required traversal, before any backtracking**, in a
chapter targeting 3–4 hours. Captain hunts and preparation loops re-walk it.

### Sensitivity — the two FAILs are not threshold artifacts

Longest tier-A dead run with all notice radii scaled:

| band | ×0.75 | ×1.0 | ×1.5 | ×2.0 | ×3.0 |
|---|---:|---:|---:|---:|---:|
| band1 | 487 | 397 | 220 | 43 | 0 |
| band2 | 484 | 396 | 221 | 146 | 75 |
| band3 | 718 | **668** | 568 | 468 | 268 |
| band4 | 1211 | **1161** | 846 | 798 | **709** |
| band5 | 123 | 0 | 0 | 0 | 0 |

**Band 4 still FAILs at ×3** — that is assuming the player notices a trainer at
150m, a camp at 180m, a TM disc at 105m and a landmark at 600m. It is not a
tuning artifact. Band 3 needs ×3 to pass and is PARTIAL-to-FAIL across the
plausible range.

### Roster temptation — new catchable species introduced per band

| band | species present | **new here** | alphas / elders | exceptional individuals |
|---|---:|---|---:|---|
| band1 | 9 | bramblebun, mudsnout, paddlenewt, mosshell, brooktail, pipwing, reedwing, galecrest, meadowhart | 1 elder | mosshell elder |
| band2 | 6 | trailpup, burrowback, duskhush, **nightburrow** | 4 | nightburrow (aspect variant) |
| band3 | 14 | **stormtrail, riftfrill** (1 individual each) | 2 | stormtrail, riftfrill |
| band4 | 8 | **NONE** | 4 | stormtrail (a second copy of a band-3 species) |
| band5 | 7 | **NONE** | 1 | none |

Two structural facts behind that table:

1. **`roll_new_worlds` ships `false`** (`data/config/spawn_tables.json:5`), and
   `spawn_tables.gd::plan_for` returns `{}` immediately at the authored seed
   (`scripts/combat/spawn_tables.gd:156-159`) — *"the roller is never entered."*
   So the shipping world is exactly the authored `species` field. **The four
   type-coverage species that exist only in the tables — `sparkit`,
   `cindercub`, `shadelet`, `frostclaw` — are unreachable in the shipping
   build.** They are the only Electric/Fire/Dark/Ice in the roster.
2. **`ashtusk` is placed in zero bands.** It is a full aspect variant with an
   owner board (`docs/art/reference/creature-expansion-2026-08-30/08_Ashtusk_tuskroot_variant.png`),
   an entry in `species.json` and a recolour spec in `aspect_variants.json` —
   and no spawn anywhere. The other three variants (nightburrow, stormtrail,
   riftfrill) all ship. This is the single cheapest roster-temptation fix
   available and it lands in exactly the band that has none.

### Optional content

`data/progression/objectives.json` carries **24 main objectives and 1 local
one** (`band1_old_champion`). `docs/MEADOWS_PROGRESSION_SPEC.md` §6 asks for
**"around 6–10 meaningful optional activities"** and names eight candidates.
Implemented: **one** (The Old Champion). Absent: Lost Creature, Broken Cart,
Night Watch, River Nest, Meadowhart Herd, Team Tether Patrols as a tracked
thread. Deep Warren exists in geometry only — `burrow_warrens.json` has a
`vault` chamber flagged `"branch": true` holding the heartstone, which is a real
optional branch but is not a tracked objective.

### Camps are set dressing

`scripts/world/props.gd` contains **no interactable, prompt or rest logic** — it
places meshes. Every authored camp in the world (`trail_camp` with a `camp_bed`
and a lit `Bonfire_Fire`; `ranger_camp` with a `Bed_Twin1`; `riverwatch_rest`
with a bed; `ridge_patrol_camp` with a `camp_tent` and `campfire_stone_ring`) is
**non-functional scenery**. The actual rest mechanic is `camp.gd::_on_rest()` on
a camp the *player builds*, per `objectives.json`'s own note on
`tournament_sleep`. So the world advertises rest spots that cannot be used,
while the real one is portable and available anywhere. That combination is worse
than either alone: it teaches the player to walk to a camp and be refused.

---

## 3. Band-by-band

Legend: **PASS** / **PARTIAL** / **FAIL**, each with the file, line or measured
number behind it.

---

### BAND 0 — HOMEBOUND (village, farmhouse, yard, starter clearing)

Band 0 has **no `data/config/bands/band0/` directory**. Its content lives in
`village.json`, `village_npcs.json`, `farm.json`, `opening.json`,
`tournament.json` and `band1_lower_meadows/`. That is a bookkeeping asymmetry,
not a defect — but it does mean band 0 is invisible to every band-level tool the
project has, including this probe's spine (band 0 stays in `paths.routes`).

| # | criterion | verdict | evidence |
|---|---|---|---|
| 1 | recognizable geography | **PARTIAL** | 14 structures (`village.json`), four authored dirt roads out of the square to Grandpa's House / Practice Meadow / The Pond / The Rise (`terrain_playground.json` `paths.routes`), three named regions within 90m. Authored well. Visual read not judged — no frames. |
| 2 | a clear reason to enter | **PASS** | Player starts here. `opening.json` + the unskippable Grandpa gate; `objectives.json` main chain rungs 1–12 are all band 0/1. |
| 3 | ordinary wild ecology | **PASS** | Practice Meadow cluster at `spawns.json` order 0 (bramblebun ×3, centre `[30,0,-40]`); 9 species across band 0/1. |
| 4 | team-building temptation | **PASS** | Three unique starters, then the whole 9-species Lower Meadows set is new. Temptation is at its structural maximum here. |
| 5 | gathering / resources | **PASS** | `harvest.json` wood ×9, fiber ×12, stone ×5, berries ×3 + the work area (anvil, workbench, whetstone) at `props.json` order 0. |
| 6 | trainer / challenge presence | **PASS** | Mira, Oskar, Tam as villager-trainers at z −16…−1, Bryn the practice trainer at z 9, plus the four-round tournament at `[20,12]`. |
| 7 | optional discovery or detour | **PARTIAL** | The Rise and The Pond are authored destinations with their own roads, and `tm_stone_rush` / `tm_burrow_strike` are free finds at `[34,−20]` / `[6,−30]`. But zero *tracked* optional objectives — the sole `local` objective in the game is band 1's. |
| 8 | memorable encounter | **PASS** | Starter choice + naming + first catch + the tournament final. This is the strongest-authored segment in the chapter. |
| 9 | camp / recovery | **PASS** | The one place the criterion genuinely passes, because the rest mechanic is *taught* here — `tournament_build_home`, `tournament_build_creature_beds`, `tournament_sleep` are explicit rungs and `camp.gd::_on_rest()` writes `player_slept_at_home`. |
| 10 | navigation & route hierarchy | **PASS** | Signpost at `[13.5,−7]`, road gate at `[27.5,−16]` with a physical key at `[31.2,−8.4]`, four roads, seeded map reveal (`map_landmarks.json` `starting_reveal`). |
| 11 | transition / payoff into next region | **PASS** | Win the tournament → `open_road_gate` → `head_to_south_bridge`. A physical gate and key, not a level check. |
| 12 | no long purposeless stretch | **PASS** | Everything is within ~90m of the square. |
| 13 | day/night readability | **FAIL** *(ecology half)* | **Zero night-gated spawns in band 0/1** — `spawns.json` has 0 `time` entries across all 55 clusters, and one weather entry (rain reedwing). The player's entire first hour contains no evidence that night changes the world, and spec §6's "Night Watch — investigate nighttime activity and introduce Duskhush" is unimplemented. Lighting half not judged. |

**Band 0 verdict:** the strongest region in the chapter, and the only one where
the camp/recovery criterion is genuinely met. Its one real hole is that night
does not exist yet as a concept.

---

### BAND 1 — LOWER MEADOWS · spine 2403 m

| # | criterion | verdict | evidence |
|---|---|---|---|
| 1 | recognizable geography | **PARTIAL** | Pond valley / Creek Hollow at `[-342,507]`, The Rise, oak grove, starter stream, South Bridge at `[0,1330]` all authored. Visual read not judged. |
| 2 | a clear reason to enter | **PASS** | `head_to_south_bridge`: *"Reach South Bridge — Team Tether holds the crossing."* |
| 3 | ordinary wild ecology | **PASS** | 55 clusters, 180 individuals, 9 species. Densest band in the chapter. |
| 4 | team-building temptation | **PASS** | All 9 species are new here. Plus the mosshell **elder** at `[-490,0,555]`. |
| 5 | gathering / resources | **PASS** | 32 nodes: wood 9, fiber 12, stone 5, berries 3, + `potion_small`, `orb_basic`, `travel_pack`. |
| 6 | trainer / challenge presence | **PARTIAL** | 9 trainers on paper; **7 of them sit in the village at z −16…12**. Outside the hub the entire 2403m band has **two**: Old Bram at z 905 and the South Bridge grunt at z 1314. Spec §BAND 1 asks for "roughly three named local trainers" as a circuit — Mira/Oskar/Tam exist but never leave the square, so the circuit is a conversation, not a journey. |
| 7 | optional discovery or detour | **PASS** | Old Champion Bram is the chapter's only tracked local objective (`band1_old_champion`), with its own rest-site prop cluster at `[195,906]`; `tm_wind_blade` at `[336,786]`; the Creek Hollow detour; `bridge_repair_site` at `[-391,521]`. |
| 8 | memorable encounter | **PASS** | Old Bram (optional, difficult, retired trainer) and the South Bridge gate fight. |
| 9 | camp / recovery | **FAIL** | `trail_camp` at `[343,936]` is the best-dressed camp in the game — 18 props, a bed, a lit bonfire, bench, stool — and **it cannot be used**. `props.gd` has no interaction. It is a map landmark (`band1_trail_camp`) that promises rest and delivers scenery. |
| 10 | navigation & route hierarchy | **PASS** | Signpost, road gate, 5 landmarks and 3 regions within notice of the spine; the spine itself is the road. |
| 11 | transition / payoff into next region | **PASS** | South Bridge is a physical gated crossing with a required trainer, exactly as spec asks ("not a UI level lock"). |
| 12 | no long purposeless stretch | **PASS** | Longest tier-A dead run **397 m** (79s walk / 57s cruise). Two runs near the limit: **arc 998–1395 (397 m)** and **arc 263–604 (341 m)**. Within target but with no margin. |
| 13 | day/night readability | **FAIL** *(ecology half)* | Zero night spawns, as band 0. |

**Band 1 verdict:** content-rich and close to finished. The two real gaps are a
trainer circuit that never leaves the village and a flagship camp that is a
prop.

---

### BAND 2 — STONE & ROOT · spine 2653 m

| # | criterion | verdict | evidence |
|---|---|---|---|
| 1 | recognizable geography | **PARTIAL** | Old Quarry `[403,1794]`, Burrow Warrens `[-420,2470]`, ranger camp, ridge trails. Two strong named regions. Visual read not judged. |
| 2 | a clear reason to enter | **PASS** | `clear_the_burrow_warrens`; Rootstone is the gate to the next crafting tier. |
| 3 | ordinary wild ecology | **PASS** | 57 clusters, 196 individuals; the population shifts to Ground (burrowback 50, trailpup 47, mudsnout 48) exactly as spec asks. |
| 4 | team-building temptation | **PASS** | 4 new species incl. **nightburrow** (aspect variant, night-only, `[-168,0,2940]`, `level_bonus: 5`), plus 4 alphas at ×1.3 scale. Meets FUN §11's 2–3 credible reasons. |
| 5 | gathering / resources | **PASS** | The best-differentiated band: **rootstone ×5 and ironwood ×5** are introduced here, plus `potion_large`, `revive`, `hide_boots`, `stoneguard_brew`. A real tier step. |
| 6 | trainer / challenge presence | **PARTIAL** | Three trainers over 2653 m — Dorn @1668, Pell @2585, Kest @2980 — all `rank: grunt`. No captain, no named local trainer with a story. Adequate spacing, thin identity. |
| 7 | optional discovery or detour | **PARTIAL** | The Warrens `vault` chamber (`burrow_warrens.json`, `"branch": true`) holding the heartstone is a genuine optional branch and the evolution-item source. But it is untracked, and spec §6's "Deep Warren" as a *harder* branch is not what shipped — the vault is one adjacent room. |
| 8 | memorable encounter | **PASS** | Warren Guardian: burrowback, level 14, ×1.35 scale, signature `earth_fist`, in the `den` chamber. A proper guardian. |
| 9 | camp / recovery | **FAIL** | `ranger_camp` at `[-258,2258]` — 9 props incl. a bed, anvil, cabinet, bench — non-interactable, same as band 1. It is even a named map landmark (`band2_ranger_camp`). |
| 10 | navigation & route hierarchy | **PASS** | Two landmarks, two regions, quarry station and supply cache as waypoints. |
| 11 | transition / payoff into next region | **PARTIAL** | Rootstone → upgrades is a real payoff. But the band ends at z 3180 and the *next* thing of structural interest is 668 m away (see band 3, criterion 12). The handoff itself is the dead spot. |
| 12 | no long purposeless stretch | **PASS** | Longest tier-A run **396 m**, with a second at **390 m** (arc 1888–2278) and a third at **219 m** at the band tail. Passing, but this band has four runs over 150 m — the thinnest structural spacing of any passing band. |
| 13 | day/night readability | **PASS** *(ecology half)* | **12 night-gated clusters** — 11 duskhush plus the nightburrow. The only band where night genuinely changes the ecology. This is the model the other bands should copy. |

**Band 2 verdict:** the best-realised middle band. Rootstone, the Warrens, the
guardian, the night ecology and nightburrow all land. Its camp is dressing and
its trainers have no faces.

---

### BAND 3 — THE RIVER LOCK · spine 2375 m

| # | criterion | verdict | evidence |
|---|---|---|---|
| 1 | recognizable geography | **PARTIAL** | The river is real: `terrain_playground.json` `river.course` runs the full world width at z ≈ 4080–4200, half-width 12–13 m, depth 11–13 m, water level −9. But **a 12 m-deep gorge is a negative-space feature — it has no silhouette and cannot be seen until you are on it.** Spec asks the river to be "an unmistakable regional landmark"; a cut in the ground is unmistakable only at the rim. Flagged for the visual lane rather than scored FAIL, since I have no frames. |
| 2 | a clear reason to enter | **PASS** | Four main objectives: `defeat_the_relay_captain`, `rescue_the_captive`, `disable_the_relay`, `restore_the_mill_crossing`. The strongest objective cluster in the chapter. |
| 3 | ordinary wild ecology | **PASS** | 52 clusters, 14 species — the widest variety anywhere, correctly mixing water (brooktail, paddlenewt, reedwing) with the established set. |
| 4 | team-building temptation | **PARTIAL** | Two new species, **one individual each**: `stormtrail` `[318,0,3830]` (rain-gated) and `riftfrill` `[-176,0,4098]` (night-gated). Both are aspect variants and both are genuinely wanted — but they are conditional singletons. A player who crosses this band in clear weather by day sees **zero** new species. Against FUN §11's "2–3 credible reasons", this is one-and-a-half, gated behind weather and time the player does not control. |
| 5 | gathering / resources | **FAIL** | 23 nodes: wood 5, fiber 6, stone 5, berries 3 — **band-1-tier materials**. No rootstone. No ironwood. Band 2 introduced both; band 3 regresses to the starting economy. The only tier items are one `hide_leggings` and one `attack_tonic`. A player arriving from Stone & Root finds the resource ladder has gone backwards. |
| 6 | trainer / challenge presence | **PARTIAL** | Five trainers — but **four of them sit within an 84 m span** at the relay (Hess @3680, Orrin @3710, Captain @3757, Dell @3764). The fifth, Captain Riverwatch, is 586 m further at @4350. So the band is 2375 m long and structurally has *two* trainer locations. The relay escalation itself (grunt → grunt → officer → captain) is correctly authored per spec. |
| 7 | optional discovery or detour | **PARTIAL** | `tm_leviathan_surge` at `[500,4240]` is a real apex detour — the comment describes it as reached "by walking the river instead of crossing it". Beyond that: nothing tracked. Spec §6's "River Nest" is unimplemented. |
| 8 | memorable encounter | **PASS** | The Tether Relay: three-stage escalation into the Relay Captain, a freed captive, disabled machinery and a restored crossing (`mill_crossing.gd`, flag `mill_crossing_restored`). This is the chapter's mid-point set piece and it is properly built. |
| 9 | camp / recovery | **FAIL** | `riverwatch_rest` at `[211,3700]` has a bed and is named "rest". Non-interactable. Same defect. |
| 10 | navigation & route hierarchy | **PARTIAL** | Old Mill Crossing `[-152,4203]` and the relay `[350,3760]` are strong landmarks — but they are both in the middle third. The band's first 668 m and last 519 m have no landmark at all. |
| 11 | transition / payoff into next region | **PASS** | The crossing physically opens and the world changes state. Exactly what spec §BAND 3 asks for. |
| 12 | no long purposeless stretch | **FAIL** | **668 m dead at the band opening** (arc 0–668 = world `(0,3180)` → `(145,3628)`) — 134s walking, 96s at cruise. Nothing tier-A at all: no trainer, no camp, no landmark, no structure, no alpha. The player crosses from Stone & Root into the band named for the chapter's biggest landmark and walks for over two minutes past ordinary spawns before anything acknowledges it. A second run of **519 m** (arc 1855–2375) covers the exit to band 4. Together, **1187 m of this 2375 m band — half of it — is structurally empty.** |
| 13 | day/night readability | **PARTIAL** *(ecology half)* | 4 night clusters (3 duskhush + riftfrill) and 4 rain clusters (3 reedwing + stormtrail). Real, but both of the band's unique species are locked behind these conditions rather than merely enhanced by them. |

**Band 3 verdict:** an excellent set piece with 1187 m of nothing wrapped around
it, a resource economy that goes backwards, and its two new species gated behind
weather and time.

---

### BAND 4 — UPPER MEADOWS / IRONWOOD · spine 3436 m — **the weakest region in the chapter**

| # | criterion | verdict | evidence |
|---|---|---|---|
| 1 | recognizable geography | **PARTIAL** | Ironwood Grove `[-345,5060]`, Ridgeline Watch `[-250,6490]`, Broken Tower `[40,6800]` and a real `watchtower_landmark.gd` at `WATCHTOWER_AT = (40,6800)`. Three named regions is the most of any band. Visual read not judged. |
| 2 | a clear reason to enter | **PASS** | `defeat_the_captains` + the three Sigils physically opening the Hall approach (`SIGIL_GATE_AT = (63.6,7400)`). |
| 3 | ordinary wild ecology | **PASS** | 78 clusters, 274 individuals — the largest population in the chapter. |
| 4 | team-building temptation | **FAIL** | **Zero new species across 3436 m.** All 8 present (meadowhart, trailpup, galecrest, burrowback, mudsnout, pipwing, duskhush, stormtrail) were already available in bands 1–3. The only "exceptional" individual is a single `stormtrail` — a **second copy of a band-3 species**. The four alphas are ×1.3–1.35 scale re-skins of creatures the player has fought for two hours. This is the band where VISION §3 says the player should feel *"at least one creature the player wanted but could not justify keeping"*, and FUN §11 requires 2–3 credible reasons to reconsider the five. There are none. `ashtusk` — a finished aspect variant with an owner board — is placed nowhere in the game and belongs here. |
| 5 | gathering / resources | **PASS** | 25 nodes with **ironwood ×10** as the clear tier material, plus `revive`, `potion_large`, `hide_helm`, `swift_tonic`. |
| 6 | trainer / challenge presence | **PARTIAL** | Four trainers over 3436 m — the sparsest density in the chapter (one per 859 m). Juno @5400, Captain Field @5590, then **870 m of nothing** to Captain Ridge @6460 and the ridgeline patrol @6470, which are 10 m apart. Two of the three regional captains are here; the third (Riverwatch) is in band 3. |
| 7 | optional discovery or detour | **PARTIAL** | `tm_earthshatter` `[-520,5180]` and `tm_aerial_flash` `[85,6260]` are real finds, and the ruined watchtower holds `tm_riptide_lance` `[33,6795]`. Nothing tracked; spec §6's "Meadowhart Herd" discovery pointing at the riding saddle is unimplemented despite meadowhart being the rideable species and 30 of them living here. |
| 8 | memorable encounter | **PARTIAL** | Two captains with Sigil rewards are structurally memorable. But there is no guardian, no unique creature, no set piece between them — nothing this band will be remembered *for* the way band 2 is remembered for the Warrens and band 3 for the Relay. |
| 9 | camp / recovery | **FAIL** | **One prop cluster in the entire 3436 m band** — `ridge_patrol_camp` at `[-236,6472]`, with a tent and a stone fire ring, and (like every other camp) non-interactable. Spec §BAND 4 names "ruined watchtower, Team Tether patrol camps, trainer road" — the watchtower exists in code, the camps are singular, the trainer road is four people. |
| 10 | navigation & route hierarchy | **PARTIAL** | Three named regions, but they cluster at the band's two ends (Ironwood Grove at z 5060, Ridgeline Watch at z 6490). The 1161 m between has no landmark, and the watchtower — the one thing built to be seen from far off — sits at z 6800, past the dead stretch, not inside it. |
| 11 | transition / payoff into next region | **PASS** | Three Sigils → the Hall approach gate. Physical, earned, correct. |
| 12 | no long purposeless stretch | **FAIL — the worst in the chapter** | **1161 m dead** (arc 1386–2547 = world `(211,5618)` → `(-145,6365)`): **232 seconds walking, 166 seconds at sprint cruise.** That is 2.6× the 90s target at walking pace and 1.8× at cruise. It survives every sensitivity test — **still 709 m at ×3 notice radii**. What is actually in it: 30+ ordinary clusters of pipwing / galecrest / mudsnout / meadowhart / burrowback / trailpup, six harvest nodes, and one TM. Nothing else — no camp, no ruin, no NPC, no Team Tether presence, no landmark, no alpha, no new species. Note the near-miss: `tm_aerial_flash` was placed *specifically to close this gap* (its comment in `playground_world.gd` says so) but sits **38 m off the spine against a 35 m notice radius**, and even when credited it only splits the run into ~907 m + ~254 m — the 907 m is still a FAIL. Two further runs of 342 m and 166 m sit either side. `playground_world.gd:256-265` already records that band 4's Air-prep beat is *"STILL UNMET"*; this measurement is the size of that debt. |
| 13 | day/night readability | **PARTIAL** *(ecology half)* | 6 night clusters, **all duskhush** — the same night creature as bands 2 and 3, with nothing unique to the upper country. One rain-gated stormtrail. |

**Band 4 verdict:** the longest band in the chapter, with the fewest trainers per
metre, one prop cluster, zero new species, no set piece, and a 1161 m hole in
the middle. On the measurements this is where the Meadows will lose a player.

---

### BAND 5 — STRONGHOLD APPROACH · spine 651 m

| # | criterion | verdict | evidence |
|---|---|---|---|
| 1 | recognizable geography | **PARTIAL** | Meadows Hall at `[8,7590]`, flagged `"silhouette": true` in `map_landmarks.json` — the only landmark in the game with that flag, and correct for the climax. `stronghold_occupation.json` adds braziers, tether lamps, sky fill and a camp. Visual read not judged; note `MEADOWS_EXIT_CRITERION.md` E2 lists Meadows Hall as **in flight** and previously "the worst-reading structure in the world". |
| 2 | a clear reason to enter | **PASS** | `fight_through_the_hall`, `defeat_the_warden`, `shut_down_the_machine`. |
| 3 | ordinary wild ecology | **PARTIAL** | 23 clusters, 78 individuals, 7 species — correctly the sparsest, since the land is drained. But at 651 m this is still dense enough that "drained" reads as "slightly fewer of the same creatures". |
| 4 | team-building temptation | **FAIL** | **Zero new species. One alpha** (galecrest, `[-25,0,7255]`, ×1.4). VISION §3 and FUN §15 both ask for "one last meaningful opportunity to prepare, rest, adjust the five or pursue a tempting optional challenge" immediately before the Warden — and the five-creature rule is about to be made emotionally decisive by the legendary. There is nothing here to want. |
| 5 | gathering / resources | **FAIL** | **8 nodes total**: fiber ×2, wood ×2, stone ×3, revive ×1. No ironwood, no rootstone. The final preparation region offers band-1 materials, which means it cannot support the "last chance to prepare" beat it is supposed to carry. |
| 6 | trainer / challenge presence | **PASS** | Six trainers with a real rank ladder — grunt @7140, officer @7440, then elite/patrol/officer/**Warden Aldis** @7557–7569. Correct escalation into the exam. |
| 7 | optional discovery or detour | **PARTIAL** | `tm_heavenfall` `[140,7300]`, the Sunstone `[121,7336]` and the `elixir_might` cache `[-165,7065]` are three real finds in 651 m — good density. Nothing tracked or narrative. |
| 8 | memorable encounter | **PASS** | The Warden (`warden_aldis`, `rank: warden`, xp_bonus 400) and the legendary chamber. |
| 9 | camp / recovery | **FAIL** | Three prop clusters, all 4-prop supply caches (`outer_watch_cache`, `road_watch_drop`, `the_waystop`). **No bed, no fire, no camp anywhere in band 5** — and this is the band whose entire design purpose per FUN §15 is final rest and preparation. The player's only option is to build one. |
| 10 | navigation & route hierarchy | **PASS** | The Hall silhouette dominates; the Sigil gate at `[63.6,7400]` is an explicit checkpoint. |
| 11 | transition / payoff into next region | **PASS** | `settle_the_roster` → `see_what_changed`, with `meadow_healing.json` and `legendary_freed`-conditional villager greetings in `village_npcs.json` (Mira, Oskar). The world genuinely responds. |
| 12 | no long purposeless stretch | **PASS** | **0 m dead.** 100% tier-A coverage — the only band that achieves this. At 651 m it is short and dense, which is right for a final approach. |
| 13 | day/night readability | **FAIL** *(ecology half)* | **Zero night-gated and zero weather-gated spawns.** The climax approach is time- and weather-invariant. |

**Band 5 verdict:** correctly paced and correctly escalated, and the only band
with no dead travel. It fails the three criteria that make it the *preparation*
region it is supposed to be: nothing to want, nothing to gather, nowhere to rest.

---

## 4. Prioritized gaps across the chapter

Ranked by **how much a real player would feel it**, not by how easy it is to fix.

| # | gap | band | lane | why it ranks here |
|---|---|---|---|---|
| **1** | **1161 m of structurally empty spine** (232s walk / 166s cruise), robust at ×3 notice radii. Two more runs of 342 m and 166 m beside it. | band4 | **content** | This is the single longest stretch of nothing in the game, in the longest band, immediately before the endgame. A player who is going to put the Meadows down will put it down here. `playground_world.gd:256-265` already flags this band's unmet preparation beat; this is its measured size. |
| **2** | **Zero new species in bands 4 and 5** — 4087 m of the chapter's back half introduces nothing catchable. `ashtusk` is a finished aspect variant with an owner board, placed nowhere. | band4, band5 | **content** | VISION §10's acceptance is *"I cared which creatures made my five"* and *"at least one creature the player wanted but could not justify keeping."* The chapter stops making that offer exactly when the five-creature rule is about to become emotionally decisive at the legendary. Placing `ashtusk` in band 4 is close to free and fixes the cheapest half. |
| **3** | **Every authored camp in the world is non-interactable scenery.** `props.gd` has no interaction logic; rest is `camp.gd::_on_rest()` on a player-built camp. | all bands | **gameplay** | Five named, well-dressed camps — one a map landmark with a lit fire and a bed — teach the player to walk over and be refused. Actively worse than having no camps. Band 5, the designated final-preparation region, has no bed or fire at all. |
| **4** | **668 m dead at the band-3 opening** + 519 m at its exit = half the River Lock is structurally empty, wrapped around a good set piece. | band3 | **content** | The player crosses into the band named for the chapter's biggest landmark and walks two minutes past ordinary spawns before anything acknowledges the transition. |
| **5** | **The resource ladder goes backwards.** Band 2 introduces rootstone + ironwood; band 3 drops to wood/fiber/stone/berries; band 5 offers 8 nodes of band-1 materials. | band3, band5 | **content** | Breaks the Valheim-tier progression the spec is explicitly built on, and leaves band 5 unable to support the "last chance to prepare" beat it exists for. |
| **6** | **One optional activity in the whole chapter** (`band1_old_champion`) against spec §6's "6–10 meaningful optional activities". Lost Creature, Broken Cart, Night Watch, River Nest, Meadowhart Herd all unimplemented. | all bands | **content** | VISION §10: *"I was tempted off the direct route."* Right now the player is tempted off it exactly once, in band 1. Meadowhart Herd is nearly free — meadowhart is the rideable species and 30 live in band 4. |
| **7** | **Night does not exist in the first hour or the last.** Bands 0/1 and band 5 have zero night-gated spawns; bands 3/4's night content is duskhush everywhere. | band0/1, band4, band5 | **content** | Criterion 13 is a per-region requirement. Band 2 shows the pattern working (12 clusters + nightburrow); nothing else copies it. Spec §6's "Night Watch" would fix the opening. |
| **8** | **Trainers cluster instead of distributing.** Band 1: 7 of 9 in the village, 2 across 2403 m. Band 3: 4 of 5 within an 84 m span. Band 4: one per 859 m, with an 870 m gap. | band1, band3, band4 | **content** | Spec §BAND 1 asks for a trainer *circuit*; Mira/Oskar/Tam never leave the square. Trainers are the cheapest fix for gaps #1 and #4 — they are people the world already has. |
| **9** | **Four roster species are unreachable in the shipping build.** `sparkit`, `cindercub`, `shadelet`, `frostclaw` exist only in `spawn_tables.json`, and `roll_new_worlds: false` + `plan_for`'s authored-seed early return means the roller is never entered. | — | **install** | These are the roster's only Electric/Fire/Dark/Ice. This is a deliberate, documented ship decision (coordinate with T2-GATEF, per the config comment) — flagged so it is a decision someone is making, not one that happens by default. It is also the ready-made answer to gap #2 if the flag is ever flipped. |
| **10** | **The river has no silhouette.** A 12 m-deep, 24 m-wide gorge cannot be seen until the rim; spec asks it to be "an unmistakable regional landmark". | band3 | **visual** | Ranked below the content gaps because I have no frames and cannot confirm how it reads. Needs a picture before anyone acts on it. |
| **11** | **Two criteria could not be judged: how the world looks, and whether night is legible.** No Godot binary in this container; `art.json`'s own night comments record three rounds ending at *"if this still reads as dim-day rather than night, adjustment_saturation is the next dial"*. Meadows Hall is listed **in flight** in `MEADOWS_EXIT_CRITERION.md` E2. | all bands | **visual** | Not a finding — a hole in this audit. Criteria 1 and 13's lighting half need a frame-based pass with the grass sanity-check the exit criterion mandates. |

### Two things worth protecting

Audits should say what not to break. Both of these are the standing good examples:

- **Band 2's night ecology** — 12 night-gated clusters plus `nightburrow` is the
  only place criterion 13 is genuinely met. It is the template for bands 0/1,
  4 and 5.
- **Band 0's rest teaching** — `tournament_build_home` → `build_creature_beds` →
  `tournament_sleep` → `tournament_feed_team` is the one place the camp/recovery
  criterion passes, and it passes because the mechanic is *taught through
  objectives* rather than placed as furniture. Gap #3's fix should extend this,
  not replace it.

---

## 5. Reproducing these numbers

```
python3 tools/region_cadence_probe.py              # full tiered report
python3 tools/region_cadence_probe.py --radius 80  # explicit notice radius
python3 tools/region_cadence_probe.py --json       # writes cadence_probe.json
```

The probe parses `playground_world.gd` for code-placed POIs rather than
restating their coordinates, so it cannot silently drift from the world it
measures. Every metre in this report came out of it; every file reference was
read directly. No claim here rests on a rendered frame, and none should be read
as one.
