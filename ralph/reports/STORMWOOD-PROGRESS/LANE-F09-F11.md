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

## WO-F10-05 — Named-fight identities and the Dynamo Break faint (`ralph/stormwood-f10-named-profiles`)

- **Anchor:** F10 / ACCEPTANCE §6.1 F10 (named fights pass C2/C3); BOSSES §7 named payoffs and §4.7 Dynamo ("a full-party faint … resets only the Break attempt").
- **Player result:**
  - Each named wild carries its own BOSSES §7 combat block and a personal once-only payoff. Tells and recoveries are floored at 0.8 s and 0.6 s.
    - Hollows Alpha pays great_candy.
    - Old Rodfolk Hall Guardian pays rare_candy.
    - Blackwater Elder pays glowmoss_tonic.
    - Glass Field Alpha pays stormglass×2.
  - The Dynamo's conduit Break has a 30 s window, shown in-world as "Conduits n/4 · s".
  - A full-party faint during Break keeps the captain win. It clears the partial conduits and sends the party to Ember Bivouac once, and Break then waits until a fighter's creature is back inside the 48 m arena.
  - A reload keeps that wait and does not replay the wipe.
  - A player who arrives during Break can strike conduits. Under BOSSES §3 they are an observer: no captain-win reward and no Stormheart offer. `dynamo_join` needs a live creature inside the arena.
- **Witnesses:** `tests/test_stormwood_named_fight_profiles.gd`, `tests/test_stormwood_dynamo.gd`, `tests/smoke_stormwood_dynamo_break_faint.gd` (17/0, with a CI step added under the Stormwood grant). A negative control with the arena re-admit removed fails the rejoin assertions. After merging `ralph/stormwood-landing`: all `test_stormwood_*` suites 227 tests / 25026 assertions / 0 failed; Stormheart participants 16/0, choice 13/0.
- **Independent review:** payoffs approved. The Break-faint change first got "request changes":
  - (blocking) a returning fighter could not reach Marrow's prompt;
  - (should-fix) a reload replayed the wipe;
  - (should-fix) late arrivals earned rewards and offers.
  All three are fixed and re-reviewed (approve).
- **Not proven:**
  - A rendered fight run.
  - Capacitor Alpha's 1.1 s route-line cue.
  - A captain-fight joiner who never passed `_add_participant` and disconnects before the release drops out of the offer set (existing limit).
