# Stormwood lane (F09–F11) — work-order evidence

Live F-row verdicts belong in STATE (coordinator-owned). This file holds the lane's
work-order evidence; each work order updates its own section in place.

## Baseline check (main `49ef712f`)

Existing production, not rebuilt: Surge clock/phases, lightning with shelter/rod
safety, ancient and built Stormglass arches, harvests, pickups, camps, rod stations,
Crown heartstone/Rootgate, Dynamo and ending/Water gate, 26 trainers, 19 NPCs and the
Deepwood Circuit side chain (`BROAD-VISUAL-0910/STORMWOOD-DEEPWOOD-CIRCUIT01.md`).
The other five WORLD §11 chains lacked authored player interactions
(`BROAD-VISUAL-0910/STORMWOOD-SIDE-CHAIN-REMAINDER.md`).

Local environment: Godot 4.7-stable headless, Linux container, no GPU. The existing
`tests/smoke_stormwood_transition.gd` reaches `STORMWOOD READY` but fails its
Stormwood→Cloudreach return leg ("Cloudreach scene did not return from Stormwood")
on **unmodified** main in this container as well as on the work-order branch; it is
not a CI job. Recorded as an environment/timing observation, not a regression claim.

## WO-F10-01 — What the Crown Remembers (`stormwood_crown_remembers`)

- **Anchor:** F10 / ACCEPTANCE §6.1 F10 ("all six selected Stormwood chains satisfy §5
  with distinct lure/action/payoff/acknowledgement and persistent receipts"); WORLD §11
  Stormwood row "Read the three surviving records around grove, then speak to Wen".
- **Branch:** `ralph/stormwood-crown-remembers` from `49ef712f`.
- **Player result:** On the Crown island, three lit, glass-scored record stones around
  the heartstone grove (`scripts/world/stormwood_crown_records.gd`) offer "Read the
  Crown record". Each plays its own authored text (Rain Ledger, Root Census, burned
  reversal mark). The first read reveals progress; all three complete the reading;
  Wen then acknowledges the complete account (after, never instead of, the main truth
  conversation, and still after the Long Storm) and points to the existing Crown cache
  (`stormwood_pickup_pocket_203`, the authored TM, by Neri's watch) without claiming it
  was reserved: the cache is an ordinary world pickup that may already be taken. No new
  item or reward; the cache keeps its original one-time receipt. No main Heartstone/Rootgate
  flag is written.
- **State:** three world-scoped facts `stormwood:side_crown_remembers_record:<id>`
  (existing `stormwood:` world prefix), counted by the chain's existing step flags
  through the chapter's host-led realm-ledger writer. Steps 1/2 are count steps
  (1 of 3, 3 of 3); their aggregate events cannot be sent to skip the records.

| Criterion | Witness | Expected | Observed |
|---|---|---|---|
| Records count once, need all three, Wen completes; save/load | `tests/test_stormwood_crown_remembers.gd` | pass | 4 tests pass locally (PR #222) |
| Wen branch never pre-empts truth; survives Long Storm | same, `test_wen_reports_records_only_after_truth_and_until_complete` | pass | pass |
| Seats on Crown island, flat, ≥6 m from baked trees/rocks, ≥8 m from pickups/NPCs/heartstone | same, `test_record_seats_are_clear_readable_island_ground` (real bake + heightfield) | pass | pass |
| Production prompt → conversation → ledger fact; locked before Crown; reread adds no revision; world save/load | `tests/smoke_stormwood_crown_records.gd` | OK | `STORMWOOD CROWN RECORDS OK: 22 assertions, 0 failures` |
| Real Stormwood scene mounts the records | `tests/smoke_stormwood_transition.gd` | `STORMWOOD READY` | READY, no script error (return leg fails identically on main; see above) |

**Limits:** No ordinary-play walk from an earned save; the Crown still requires the
arch route. No two-process peer run of this chain (world-scope writes use the same
realm-ledger path the Deepwood Circuit and heartstone use). Visual quality of the
record stones is not judged. The smoke is not yet a CI job (`.github/**` is shared).

**Independent review (PR #222):** changes requested → fixed: Wen's cache line no longer
claims the store was reserved for readers; the burned record now agrees with Wen's truth
line (the mark runs *out of* the split tree); records count on the panel's `completed`
(last line read), not a cancellable `finished`; record stones use the neutral portrait
plate. Kept as-is (nit): step 3's objective can show before Wen will give the report,
because the report follows the main truth conversation by design.

## WO-F10-02 — Pim's Parcels (`stormwood_pims_parcels`)

- **Anchor:** F10 / WORLD §11 row "Collect sealed parcels; deliver to three existing households on restored arch roads; return to Pim … two small potions per eligible character once. Delivery is three flags."
- **Player result:** Pim (Lantern Pools) offers parcels after pair A links; Marl (Ashfoot), Oswin (Rodline Post) and Lio (Lantern Hollow, after the Rootgate) each receive one (a delivery conversation plus a crate that appears beside them). Pim's return pays 2 Small Potions per character, once per world, through the existing `reward_grant` delivery; its (world namespace, source, stable character) receipt — MULTIPLAYER's personal-once rule — is both the host's duplicate guard and, via the replicated delivery journal, how a peer knows it has been paid. Any other character who later speaks to Pim collects their own share once. No new flag, so no shared `flag_scopes.json` change is needed (an earlier portable-flag design was withdrawn).
- **Witnesses:** `tests/test_stormwood_pims_parcels.gd` (chain, greetings, recipients, ledger pays each character once and the journal shows it, other worlds keep their own receipt).

## WO-F10-03 — Dark Arches (`stormwood_dark_arches`)

- **Interpretation (write-back requested for WORLD §11):** §5.3 authors no Dynamo-region arch, so "Deepwood/Dynamo pairs" is read as ancient pairs C (Rodline↔Lantern Hollow) and D (Old Rodfolk Hall↔Fallen Giant), neither required by a main objective.
- **Player result:** after the Rootgate, trying a dark C/D arch records its inspection; relighting all four ends through the existing paid relight claim submits step 2; Hesk's report completes it. Old saves with those ends already lit still reach steps 1–2.
- **Open:** "visible on known map" needs an arch layer in the shared map UI.
- **Witnesses:** `tests/test_stormwood_dark_arches.gd`; `tests/smoke_stormwood_arches.gd` dark-arch segment (real prompts, 12 Stormglass for four ends, step-2 event).

## WO-F10-04 — Raise a Road (`stormwood_raise_a_road`)

- **Player result:** after Ondra's recipe, two optional footings are chosen at their own prompts (Deepwood only after the Rootgate; the Still Grove/Crown footing never counts); a bound pair on both chosen footings completes the build step; travelling it each way records each direction; Ondra acknowledges the road. The chain is four steps (choose / build+bind / both directions / report).
- **Disclosed:** a bound pair already standing on two footings is credited for the build step once they are chosen; two peers choosing different footings in the same round trip can record a third choice.
- **Witnesses:** `tests/test_stormwood_raise_a_road.gd`; `tests/smoke_stormwood_arches.gd` road segment (real footing prompts, BuildPlacer pair, passage travel both ways).

## WO-F11-01 — Per-participant Stormheart offers and explicit accept/refuse

- **Defect fixed:** main reserved the one freed Stormheart for the first claimant ("already offered its bond to another trainer"), contrary to the current hard rule.
- **Player result:** the Dynamo captures each fighter's stable character when they join (persisted, so a disconnect cannot drop them); at the release each recorded fighter has their own once-only offer through their own five-slot ceremony. The offer ends on a Yes/No line: Yes joins (at five: release one or let it go), No leaves it free; each answer writes the world receipt `stormwood:legendary_resolution:<accepted|refused>:<character>` (mirroring the Meadows finale). A character with no offer owed (did not fight, or already holds a Stormheart receipt) gets no creature but can let the world's single offer fact land, so Waterward never waits on absent fighters. Legacy single-recipient saves migrate their claim and seed that recipient as sole participant.
- **Witnesses:** `tests/test_stormwood_ending.gd`; `tests/smoke_stormwood_stormheart_participants.gd` (host authority with registered peers: fighters incl. a disconnected one recorded, onlooker refused but can land the world fact, receipt holder gets nothing, each participant its own creature, separate accepted/refused receipts, no re-offer after reload).
- **Not proven:** two-process network run with a remote recipient disconnecting at claim acknowledgement; client ceremony UI in a rendered run.

## Consolidated landing (`ralph/stormwood-landing`)

Per the coordinator's throughput condition, WO-F10-01…04 and WO-F11-01 land as one branch/PR after #215, with the granted `ci.yml` steps for `smoke_stormwood_crown_records.gd` and `smoke_stormwood_stormheart_participants.gd`. After merging main at `47774c35` (#215): all `test_stormwood_*` suites plus flag-scope/chapter/portrait suites pass; smokes Crown records 22/0, Stormheart participants 16/0, Stormheart choice 13/0, arches PASS, heartstone 12/0.

## WO-F09-01 — Walkable roads, second Dynamo road, footing rule, five pockets (`ralph/stormwood-f09-walkable-roads`)

- **Anchor:** F09 / ACCEPTANCE §6.1 F09 ("four loops, three shortcuts, five pockets and alternate routes; a closed Arch cannot be bypassed"). WORLD §5.1/§5.3 and the coordinator's F09 rulings: C, D and the player road are the far-side shortcuts; for the arch-only Crown and the single Rootgate pass, the arch is the second route; a walled dead-end clearing with a moved reward is a pocket.
- **Measured baseline** (read-only audit, production heightfield, true slope, 45° floor limit):
  - The closed Rootgate and the arch-only Crown cannot be bypassed.
  - 5 walkable loops.
  - conductor_road's last leg climbed 73.8° and deepwood_road's first leg 52–58°.
  - Deepwood→Dynamo had one road.
  - 0 pockets.
- **Player result:**
  - **Roads:** both Rootgate legs follow the pass floor, now at most 23.4°. `dynamo_west_approach` (Deepwood Rod Station → Ember Bivouac, at most 19.7°) is the second Deepwood→Dynamo road.
  - **Roadside creatures:** the 13 pairs that lined the old legs are re-seated beside the new road (`tools/stormwood_reroute_road_visibility.py`, using the ROAD author's own placer). Every critical road keeps two forward-visible creatures at every 10 m sample.
  - **Arches:** a Stormglass arch stands only on one of the five footings, and only one arch per footing. The three-road cap is proven with an old-save fixture, free-build is still refused off a footing, and a legacy off-footing arch never captures a legal twin.
  - **Pockets:** five walled dead-end pockets, one per walkable region. Each is 16 × 16 m with a dead-trunk palisade plus static collision, and a 5 m mouth facing its road, 112–351 m off the road. Each holds an existing optional reward moved inside.
  - **Forest scatter:**
    - It is re-baked with per-road and per-cell seeds, so a future road edit re-plants only near that road.
    - An 18 m collider clearing at each named fight; the nearest collider to any named fight is 18.96 m away, where the largest envelope is 13.89 m.
    - No trunk or rock inside any road corridor (the old bake had 25 rocks on roads).
    - No collider inside any pocket.
- **Witnesses:**
  - `test_stormwood_route_walkability` (fails on the old data)
  - `test_stormwood_pockets` (dead end, walkable interior, reachable from a road, rewards, spawn discs clear, runtime colliders, bake clear)
  - `test_stormwood_named_fight_clearings`
  - `test_stormwood_arch_building`
  - `test_road_creature_visibility` (granted baseline update: conductor 249→259 and deepwood 300→302 samples, 0 failing on both builds)
  - `test_stormwood_glass_field_approach`, `test_stormwood_scatter_bake`
  - smokes: arches, pickup runtime, hosted rewards
  - In total, 456+ headless tests pass in the reviewer's broad run. A second bake is byte-identical.
- **Independent review:** request changes (2 blocking, 3 should-fix), then approve. The follow-up fixed the palisade spacing and moved `cinder_verge_cluster_19` off the Verge pocket.
- **Open:**
  - No in-engine capture of the pockets or of the re-planted forest yet (render slot).
  - The scatter still does not clear trainer, NPC, harvest or pickup seats. There are 7 near-contacts, the same count as the old bake.
  - `blackwater_elder` stands on a deepwood_road vertex.
  - The arch commit at the footing centre is routed to the co-op lane.
  - The coordinator edits WORLD.md's route count (nine → ten) on landing.
