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

## WO-F11-02 — Stormheart offer: landing-review follow-ups (`ralph/stormwood-f11-followups`)

- **Anchor:** F11 / ACCEPTANCE §6.1 F11 (per-participant accept/refuse at space and capacity, through disconnect/reload, without duplicate grants); CLAUDE.md legendary rule; MULTIPLAYER.md:95.
- **Player result:**
  - **Only an explicit No refuses.** That is B on the Yes/No line, which the panel draws as "[A] Yes  [B] No". Any other close, before or on that line, answers nothing and the offer is asked again. This matches the Meadows finale, which settles only from an explicit answer.
  - **Yes during another catch ceremony** waits for that ceremony, then starts the Stormheart's own. It no longer stalls for the rest of the session.
  - **Old saves with no recorded fighters** give an offer to their first claimant only. Every later character gets no creature, but can still land the world offer fact, so Waterward is never softlocked.
  - **The host decides from its own claims and world receipts.** A client's "already answered" value can only withhold a creature, never grant one.
  - **The Yes effect** queued on the dialogue panel is consumed by the ending.
- **Witnesses:**
  - `tests/test_stormwood_ending.gd`: 12 tests / 65 assertions.
  - `tests/smoke_stormwood_stormheart_choice.gd`: 22/0. It uses a real `menu_cancel` press, closes before and on the Yes/No line, and answers Yes during a stand-in catch ceremony.
  - `tests/smoke_stormwood_stormheart_participants.gd`: 23/0. It covers a legacy later claimant, and a lying client refused from the host's own receipt.
  - Negative controls: each fix, when reverted, fails its test. With the old ending, the new smoke segment hangs instead of passing.
  - Merged with WO-F10-05: all `test_stormwood_*` suites 231 tests / 25047 assertions / 0 failed.
- **Independent review:** approved in two rounds. Should-fix 3 (the stall after Yes) is fixed in 73650882d and re-approved.
- **Open:**
  - **(shared grant requested)** A No in one world still withholds a real offer in another. The portable receipt does not record Yes vs No; fixing it needs a player flag in `flag_scopes.json`.
  - **(shared grant requested)** The No is read from input state on the panel's tick, not from a runner `declined` signal. The reviewer verified this correct today for keyboard and joypad.
  - A claim that deterministically fails to decode now re-asks rather than stalling. No is the exit.
  - No two-process network run and no rendered ceremony yet.
- **Independent-review follow-ups (commits ea9b43fff, 3fa9ffa8c, 155ff7456, 043a449f6):**
  - **Legacy saves no longer reward the first claimant.** With no recorded fighters, a claim is judged against the Dynamo's persisted `fighter_characters` (plus `contributors` peers mapped to characters where a connected peer still names one), and failing that only the host's own character. A guest who claims first gets nothing but can still land the world offer fact; the host keeps its offer. The resolved list is saved with the first claim.
  - **Break reach needs a live creature.** Break join, pruning and conduit strikes accept only a visible body whose creature has not fainted: the host's own is the director's ally instance, another peer's is the card the host holds. A discharge outside a fight now faints the director's ally instance and hides the follower, as a fight does. The field control read the creature from the follower body, which carries none, so it never piloted; it now reads the director's ally.
  - **A full-party faint restores everyone.** `dynamo_recovery` goes to contributors and to every Stormwood peer whose trainer is within `arena_radius_m` of the core.
  - **Refusal comes from the runner.** `dialogue_runner.gd` emits `declined(id)` from `confirm(false)` before closing, and the panel forwards it. The ending sets its refusal from that signal instead of raw input. An explicit No refuses; a close re-asks.
  - **Portable acceptance.** A Yes that keeps the Stormheart sets player flag `stormwood:legendary_offer_accepted`. The client's cross-world hint is now `already_accepted`: a refusal in world A no longer withholds world B's offer, and a stale ceremony receipt from another world is dropped when the character asks. An acceptance still withholds. `stormwood:legendary_ceremony_settled` keeps its same-world resume role.
  - **Pim's thanks gives way.** THANKS holds until this character has heard it while paid here (`stormwood:pims_parcels_reward_received`, already player-scoped); then her post-storm greeting returns. A world that still owes the rate drops that receipt. `_paid()` is null-safe.
- **Follow-up witnesses** (with the flag line below present locally):
  - All `test_stormwood_*` + `test_dialogue_runner` + flag-scope suites: 325 tests / 26678 assertions / 0 failed.
  - Smokes: stormheart_choice 32/0, stormheart_participants 27/0, dynamo_break_faint 37/0, crown_records 22/0, arches PASS.
  - Negative controls: removing the runner's `declined` emit fails its runner test. Restoring the first-claimant fallback fails 9 participants checks. Unwiring the ending's `declined` fails 3 choice checks. Restoring the old `_on_offer` and no acceptance flag fails 8. Old reach check fails 7, old hazard/pruning 7, contributors-only recovery 1, old field-control read 1. Pim without `unless_flag` fails 1. Without the `_paid()` guard it raises SCRIPT ERROR.
  - Still stubbed in the real-faint path: session, hub transport, combat manager, arena, camera, arbiter and player rig. The director script is attached without `_ready()`, so its ally is assigned, not summoned. The recovery teleport is not applied.
- **Coordinator action:** add `"stormwood:legendary_offer_accepted",` to `player.ids` in `data/progression/flag_scopes.json`. Without it `test_the_portable_acceptance_is_player_owned_despite_the_stormwood_world_prefix` fails.
- **Open (follow-ups):**
  - On the host, a remote fighter's faint is seen only through its card (deploy-time hit points), a hidden/freed proxy, or leaving the realm; the owner's discharge damage does not reach the host's card.
  - A fighter whose deployed creature faints is out of the Break even with conscious reserves.
  - `tests/helpers/stormwood_earned_marrow_segment.gd` reads `ally.get("instance")`, which a follower never has; that earned segment needs the same director read.
- **Second review round (commits 2fc889836, 182b2a0d4):**
  - **B1/S2/S3 — answers scoped to a claim.** Each answer is a player flag `stormwood:legendary_answer:<reserved Stormheart uid>:accepted|refused`. A resent claim resumes only from its own answer, or from its own creature in the party (matched by uid, so levelling or renaming does not matter). A bare `stormwood:legendary_ceremony_settled` with no scoped answer is from an older build: it reads as an acceptance, becomes an explicit one before the first scoped answer, and is never cleared. The stale-receipt heuristic is gone.
  - **S4.** The legacy fallback is the Dynamo's `fighter_characters`, else the host's own character. The host is a best guess for saves that recorded nobody, and a real guest fighter on such a save is denied. Old-session contributor peer ids are not mapped. The host never publishes an empty list: it publishes the marker `(none)`, so clients never read it as a solo freeing.
  - **B2.** A discharge damages the piloted creature directly only in `break_core` with no trainer battle active, so Marrow's between-rounds gap is safe. A faint calls `CONDITION.note_faint`.
  - **S1.** The owning client reports `dynamo_ally_fainted` (creature uid, `party_down`). The host accepts it only from a Break participant in Stormwood, and only for the creature on its card.
  - **S5.** BOSSES §4.7 plus COMBAT ("All five unavailable means loss"): a fighter leaves the Break only when their whole party is down or they leave Stormwood. The Bivouac recovery restores every member with `home_recovery.gd::rest()`, the camp creature bed's rest, which also granted its rest XP (removed in round three).
- **Second-round witnesses** (flag lines present locally): all `test_stormwood_*` + `test_dialogue_runner` + flag-scope suites 329 tests / 26696 assertions / 0 failed. Smokes: stormheart_choice 37/0 (two separately mounted worlds), stormheart_participants 27/0, dynamo_break_faint 50/0, crown_records 22/0, arches PASS.
- **Second-round negative controls:**

  | Change reverted | Result |
  |---|---|
  | Bare receipt no longer treated as acceptance | 1 unit fail |
  | Resume keyed on the bare receipt | 4 choice fails |
  | Host always added to the fallback | 1 unit + 2 participants fails |
  | Empty participant list published | 1 unit fail |
  | No Break or battle guard on discharge damage | 4 fails |
  | No `note_faint` | 1 fail |
  | Faint reports ignored by the host | 2 fails + SCRIPT ERROR |
  | No client report | 2 fails |
  | Old one-creature drop | 1 fail |
  | No restore on recovery | 3 fails |
- **Coordinator action (second round):** add player id `"stormwood:legendary_offer_accepted",` and player prefix `"stormwood:legendary_answer:",` to `data/progression/flag_scopes.json`.
- **Open:**
  - After a faint, sending out the next conscious creature uses the director's existing party swap/summon; that is not exercised here.
  - A remote creature revived by an item in mid-Break stays refused for that uid until the Break resets or its owner re-deploys another creature.
  - An older build's unacknowledged refusal in the same world is asked again, since it carries no scoped answer.
- **Third review round (commits d1994784d, 87bcba90c):**
  - **N1.** Suppose a world's never-answered claim is resent after the character accepted a Stormheart elsewhere, or holds an older build's bare receipt. It now settles as not kept with "A Stormheart already walks with you." instead of reopening the offer. As a second guard, the host sends no creature for an acceptance hint, even while it holds that character's unsettled claim. The host's resend still delivers that claim.
  - **Recovery** uses `heal_fully()` only: no rest XP for a wipe.
  - **Availability rule.** Whole-party-down follows `party.gd`'s rule for taking the field: a creature that is fainted or resting cannot.
  - **Guarded `party_down`.** A reported `party_down` counts only after this attempt heard that the peer's deployed creature fainted.
- **Third-round witnesses:** all `test_stormwood_*` + `test_dialogue_runner` + flag-scope suites 330 / 26703 / 0 failed. Smokes: stormheart_choice 41/0 (adds "unanswered in D, Yes in C, back to D → one Stormheart, D settles not kept"), stormheart_participants 28/0, dynamo_break_faint 52/0, crown_records 22/0, arches PASS.
- **Third-round negative controls:**

  | Change reverted | Result |
  |---|---|
  | Client guard off | 2 choice fails |
  | Host guard off | 1 participants + 1 unit fail |
  | Camp rest restored | 1 fail (no-XP check) |
  | Bare `party_down` accepted | 2 fails |
  | Resting ignored | 1 unit fail |

## WO-F10-06 — Surge phases readable without HUD (`ralph/stormwood-f10-surge-readability`)

- **Anchor:** F10 / ACCEPTANCE §6.1 F10: lightning with a 1.2 s / 3 m telegraph, and Calm/Building/Break/Fading readable without HUD text. The restored-sky view has to be distinct. ART_DIRECTION and SYSTEMS define the Stormwood look for each phase.
- **Found:** before this work, the four phases differed only by a ground and dead-tree tint. There were three causes:
  - Stormwood's rain emitter was never made visible.
  - No phase set its own sky.
  - The aftermath (`stormwood:long_storm_ended`) had no presentation.
- **Player result.** Everything is driven by config and built per peer from replicated state, in `scripts/world/stormwood_surge.gd` and `stormwood_lightning.gd`.
  - **Phase skies** under a realm-owned storm ceiling, day and night:
    - Calm: neutral-grey overcast with drizzle.
    - Building: olive, with dimmed, copper-dulled ground.
    - Break: violet, with the darkest ground and heavy slanted rain.
    - Fading: warm and breaking up.
  - **Aftermath:** Calm opens to blue sky with no rain.
  - **Floors:** the storm horizon/fog never drops below 65% of native luminance and the ceiling never below 30%. The storm never raises night fill light.
  - **Break flashes:** only in the local Break, or from a strike within 40 m. A strike in another phase stays a local bolt.
  - **Telegraph:** a ground-hugging ring that reads the game's combat hazard colour from `combat.json` (#ff40e6; see JUDGE.md round 3). It has a dark interior, pulses at 2→7 Hz and flashes white-hot at impact, with the exact 3 m / 1.2 s contract. The build costs 0.40 ms (17 height samples, one cached mesh), and its shader is prewarmed.
- **Witnesses:**
  - `tests/test_stormwood_surge_presentation.gd` and `tests/smoke_stormwood_lightning_cleanup.gd`; together with the Stormwood suites, 270 tests / 25,360 assertions pass.
  - Negative controls, in the round reports: flash gate, fade dip, ambient cap, telegraph radius, rain hidden, height-call budget, floors, telegraph colour, lens distance, day Break luminance.
  - Captures are in `visual/surge/`: before/after strips and night sheets, and `sheet_round4.jpg`.
- **Independent review:** 4 rounds of code review; the final verdict is approve. 4 blind visual judges with shuffled neutral frames: 12/13, 10/11, partial, then **9/9** time-of-day and weather grouping, with each day frame paired to its night frame (`visual/surge/JUDGE.md`).
- **Open:**
  - **Rain, dry disc:** the lens-safe slanted rain leaves a rain-free disc of about 9 m around the player. The fix is to centre the near emitter on the camera, which also closes the reviewer's 2° spread note on the lens test.
  - **Night at 30% size:** Calm, Building and Fading merge.
  - **Telegraph read:** the ring reads as a zone rather than an unambiguous "move out". Any change belongs to the shared combat colour.
  - **Not verified here:**
    - no Ally GPU profile;
    - the flash has only been seen in stills;
    - no audio.
  - **Region-wide, outside this branch:** no sun shadows, an empty horizon, grass that stays bright under dark skies, and no rain wetness.

## WO-F10-07 — Rain around the camera, and gentler Break flashes (`ralph/stormwood-f10-rain-camera`)

- **Anchor:** F10 visual acceptance. This closes the WO-F10-06 "rain, dry disc" item and the final review's reduced-motion finding (UX §8/§275: reduced motion lowers non-essential flashes).
- **Found:**
  - **Dry disc:** the lens-safe near rain ring was centred on the PLAYER with an inner radius of 10.6 m, so the nearest drop was about 9 m from the trainer. Rain only showed against the far sky (`visual/surge/after/r4_break_upwind.jpg`).
  - **Lens test gap:** the test ignored the base emitter's 2° spread, which adds up to about 0.7 m of sideways drift.
  - **Flash problems:** Break's distant sky flashes were up to 1.0 on the same 4–8 s cadence as real strikes. With no telegraph, one could read as a missed warning. They also ignored `MOTION_PREFS.reduced_motion()`.
- **Player result** (`scripts/world/stormwood_surge.gd`, `data/config/stormwood_surge.json`):
  - **Rain placement:** the rain emitter now sits 3 m above the ACTIVE CAMERA (`rain_centre`). Every peer follows its own camera, including the riding profile and a rig retargeted to a piloted creature.
  - **Derived near ring:** its inner radius is 1.5 m lens clearance + half the wind drift + the spread drift + the streak's sideways half-extent (about 3.9 m), and it is 8 m wide. Rain now falls over the trainer and the near ground.
  - **Distant flashes:** now 0.20–0.35 of a strike's flash (echo 0.25), on a separate 9–16 s cadence.
  - **Reduced motion:** scales every sky flash, distant and strike, by 0.15. The telegraph ring and the local bolt are gameplay tells and are unchanged.
- **Witnesses:**
  - **New tests** in `tests/test_stormwood_surge_presentation.gd`:
    - the lens test now models the camera-centred ring with `sin(spread)·v·t`;
    - `test_rain_reaches_the_trainer` (≤ 3 m at every camera distance and yaw);
    - distant flashes weaker and slower than strikes;
    - reduced motion scales sky flashes.
  - **Smoke:** `tests/smoke_stormwood_lightning_cleanup.gd` checks that under reduced motion the ring and bolt still draw and the sky flash is 0.15.
  - **Negative controls:**
    - the round-4 player-centred ring fails the reach test (8.37 m);
    - dropping the spread term fails the lens test (0.80 m);
    - ignoring reduced motion fails;
    - round-4 flash strengths fail.
  - **Frames:** `visual/surge/sheet_rain_camera.jpg`, with 4 frames compared against `r4_break_upwind.jpg`.
- **Review follow-up (`7faf5d42c`): no rain under roofs, plus reduced-motion nits.**
  - **Roof suppression:**
    - Every 0.25 s, the shelter check casts physics rays up from the trainer (starting at head height) and from the camera.
    - Any hit fades the near rain layer out over 0.6 s, and back in outside.
    - Canopy and rod radius are ignored on purpose, so rain under trees stays.
    - The far layer is untouched.
    - The rain volume is clamped to at most 16 m above the ground under the camera.
  - **Reduced motion:**
    - The strike's local light is scaled by 0.15.
    - The telegraph rim is steady; its growing fill still carries the 1.2 s timing.
    - The config records why the scale is 0.15 rather than `impulse_scale()`'s 0: the flash rhythm is one of the cues that name Break without HUD text.
  - **Test hygiene:** the presentation tests save and restore the static pref in `before_each`/`after_each`, so a failing test can't leave it set.
  - **Witnesses:**
    - Unit tests: roof fade without a snap, far layer untouched, height clamp, steady rim.
    - The cleanup smoke puts a StaticBody roof over the trainer: near rain goes to 0.00, then back to 1.00 once the roof is removed. Under reduced motion the strike light reads 1.20 of 8.
    - Negative controls, each failing: roof probe disabled, fade that snaps, strike light unscaled, rim pulsing under reduced motion.
    - `visual/surge/sheet_rain_roof.jpg`: inside the real Ashfoot shelter (ranger station) the room is dry, while the same building from 11 m outside stands in rain.
- **Foreground rain and review N1/N2** (`3947f56c0`, `5a10d9feb`)
  - **Judge finding:** in the normal and night Break frames the bottom ~45% of the view (the grass between the camera and the trainer) was dry. Near streaks read as blunt, vertical, opaque "sticks".
  - **How it was measured** (`tools/capture_stormwood_surge_phases.gd` `rainmeasure`, production camera, the four raincam poses):
    - **Analytic:** 6000 points were sampled from the LIVE near emitter's parameters and projected through the production Camera3D. A point counts only if it is above the terrain and not occluded (physics ray).
    - **Live:** a rain-on vs rain-off pixel diff, with the ground cover hidden.
    - The raw numbers are in `visual/surge/after/rain_measure_{before,after}.json`. The masks are in `visual/surge/sheet_rain_foreground_measure.jpg`.

    | Shot (Break) | Drops above ground before → after | Drops seen in bottom 45% (of 6000) | Live streaks in bottom 45% |
    |---|---|---|---|
    | day, normal camera | 25% → 53% | 122 → 387 | 45 → 98 |
    | day, upwind camera | 28% → 59% | 75 → 318 | 27 → 76 |
    | day, riding profile | 27% → 52% | 160 → 479 | 51 → 84 |
    | night, normal camera | 25% → 53% | 122 → 387 | 44 → 73 |

  - **Root cause:** geometry, not contrast. The camera-centred near column spawned from camera −4 m to +10 m and fell for 1.4 s (about 18 m). At any moment 72–75% of the drops were below the terrain, and the few above it were mostly above eye level.
  - **Fix:**
    - The near layer now spawns in a band 0.2–6.5 m above the floor. The floor is the higher of the terrain under the camera and the trainer. The band is still centred on the camera horizontally, and each drop lives 0.5 s.
    - The shorter drift lets the derived lens-safe inner radius come in to 2.8 m, and lens clearance is still ≥ 1.5 m.
    - Drops fade in and out over their life.
    - Streaks are thin tapered translucent spindles (1.8 cm base) on a 14° wind slant, where they had been opaque boxes.
    - Near and far layers have separate night tints.
  - **Remaining trade-off:** the very bottom ~15% of a level-pitch frame (ground 2.5–4 m from the lens) stays sparse. Drops there would come within the lens clearance.
  - **Tests:**
    - `test_near_rain_fills_the_foreground` needs ≥ 35 drops in the bottom 45% in Break. The HEAD geometry gives 15.1 and fails; this is the negative control.
    - N1 `test_rain_volume_follows_a_raised_trainer`: its control, a clamp against the terrain only, fails (centre at 16 m under a trainer at 60 m).
    - N2 smoke `RAIN ROOF SUBJECT`: its control, probing the trainer instead of the framed subject, fails.
  - **Frames:** `rc_day_break`, `rc_day_break_upwind`, `rc_day_break_riding`, `rc_night_break` and the two roof frames were re-captured under their existing names (older versions are in git). `sheet_rain_camera.jpg` is rebuilt.
- **Open:**
  - The riding frame uses the production riding camera PROFILE on the trainer, with no mount.
  - Night rain is intentionally faint.
  - No Ally GPU profile has been taken.

## WO-F10-08: Stormwood is always the purple storm (`ralph/stormwood-f10-rain-camera`, `220bd0268`)

- **Owner direction** (about `visual/surge/after/rc_day_break_upwind.jpg`): *"I love the purple sky look in some of the screenshots. We should not have day and night in stormwood. It should just always be that kind of purple rainy sky regardless of time of day."*
- **Owner ruling on the aftermath:** Stormwood stays purple after the Long Storm is broken. *"The aftermath shows only through lighter rain, no lightning and the scars."*
- **Player result.** Presentation only, in `scripts/world/stormwood_surge.gd` and `data/config/stormwood_surge.json`.
  - **One storm look at every hour.** Stormwood's own WorldLook instance gets a config in which every time-of-day preset is the same storm reference: the day preset plus `presentation.storm_base.overrides`. Those overrides are the key light's angle (−44°/140°), its energy (1.4) and colour (#e8e0f4), and purple-grey clouds and haze.
    - Sky, clouds, fog, ambient, exposure and the key light's angle, energy and colour are therefore the same at every hour. Shadows no longer rotate.
    - The world clock, the day counter, `is_dark()`, the shared night-rest authority and encounter night roles are untouched.
    - The pin lives on that WorldLook instance only, so the next realm loads `art.json` as before.
    - Setting `storm_base.pin_time_of_day` to false brings the clock look back.
  - **Phases, all in the purple family of the day-Break anchor.** They read from rain density (0.3 / 0.6 / 1.0 / 0.15), lightning cadence and flashes (Break only), ceiling value and motion, fog and key level (0.8 / 0.38 / 0.24 / 0.7). The sky is never blue or white and never night-black.
  - **Aftermath (every aftermath phase).** It is separated from Calm by:
    - lighter rain (0.1 against Calm's 0.3);
    - no sky flashes;
    - the stillest ceiling (speed 0.003 and contrast 0.1, against Calm's 0.006 and 0.18);
    - the lightest ceiling (#9894b4);
    - a steadier, higher key light (0.9 against 0.8).
  - **Gameplay left alone.** The aftermath's Surge timings (`aftermath_seconds`) and real aftermath-Break strikes are rules, and are unchanged.
  - **Night lights.** The capacitor grove's `night_light_*` and the glass field's `night_light` were already unconditional, not clock-gated. They needed no change and stay at their modest energies (1.45 and 0.84).
- **Tests** (`tests/test_stormwood_surge_presentation.gd`):
  - **New:**
    - `test_look_is_identical_at_every_hour`: for every phase, and for the aftermath, the look WorldLook would layer is identical at hours 0/6/12/18. That covers sky top and horizon, fog colour and density, ambient colour and energy, exposure, and key energy, angle and colour.
    - `test_leaving_stormwood_restores_the_clock_look`: the pin never mutates `art.json`, the day length and the `is_dark()` window are unchanged, and a fresh realm's WorldLook has moving sun and night again.
  - **Rewritten to the new rule** (none skipped). Each old name maps to its replacement:
    - `test_night_base_from_real_art_config_dims_storm_sky` → `test_storm_base_is_identical_at_every_hour`
    - `test_cross_fade_through_native_sky_has_no_dip_at_night_dusk_or_dawn` → `test_cross_fade_between_phases_has_no_dip_at_any_hour`
    - `test_storm_ambient_never_brightens_the_night` → `test_storm_ambient_never_exceeds_the_storm_base`
    - `test_ceiling_builds_and_opens_in_the_aftermath` → `test_ceiling_builds_and_stays_in_the_aftermath`
    - `test_aftermath_calm_restores_sky_and_is_distinct` → `test_aftermath_is_the_calmest_purple`
    - `test_aftermath_flag_hides_rain_in_production_path` → `test_aftermath_flag_lightens_rain_in_production_path`
    - `test_night_break_has_its_own_hue` → `test_break_keeps_its_violet_identity_at_every_hour`
    - `test_ceiling_breakup_closes_at_night` → `test_fading_breakup_is_the_same_at_every_hour`
    - `test_rain_slants_fades_with_depth_and_dims_at_night` → `test_rain_slants_and_fades_with_depth`
    - `test_day_break_sky_is_clearly_lighter_than_night_break` → `test_break_sky_is_a_storm_afternoon_at_every_hour`
    - `test_night_phases_separate_by_hue_and_value` → `test_phases_separate_within_the_purple_family`
  - **Negative control:** setting `pin_time_of_day` to false (the clock blend restored) fails 6 tests, including the every-hour test ("Break sky_top same at 23:00: expected 545179, got 282639").
- **Frames** (`visual/surge/sheet_purple_phases.jpg`, `after/purple_{calm,building,break,fading,aftermath}_h{12,00}.jpg`, records in `after/frames_after_purple.json`):
  - Each hour-12/hour-0 pair matches: mean luminance of the sky region is identical to within 0.4/255. Break's ground differs only because a live strike telegraph happened to land in the hour-12 frame.
  - The rain frames (`rc_*`, roof) were re-rendered with the pin as well. `rc_night_break` (hour 23) now matches the day look.
- **Clock-keyed and NOT changed** (shared scripts outside this lane, or gameplay; listed for the owner's pending gameplay ruling):
  - `scripts/player/torch.gd`: the trainer's torch auto-lights when `is_dark()`.
  - `scripts/world/campfire_glow.gd` and `camp_fill_light.gd`: camp fire and fill light only when dark.
  - `scripts/audio/world_audio.gd`: night ambience layer.
  - `scripts/world/inn_interior.gd`: reads `time_of_day`.
  - The HUD clock.
  - Creature/character night emission floors come through WorldLook and are therefore pinned too. The encounter night roles and night rest are gameplay and were deliberately not touched.
- **Open:**
  - As stills, Calm, Fading and the aftermath sit close together. Their separation is mostly rain density, ceiling motion and flashes, which read best in motion.
  - No blind judge has seen the purple set yet.


### WO-F10-08, round 2: every phase in the deep purple (`cb067c58f`, `62f14e95f`)

- **Owner direction** (about `sheet_purple_phases.jpg`, round 1): *"I like the building and break pictures. The other two aren't fantastic enough."* Calm, Fading and the post-release aftermath therefore move into the deep purple family of Building and Break. That covers sky, ceiling, fog, key and ambient; nothing is pale lavender or grey. The clock pin is kept.
- **How phases separate now.** The sky changes only in small value steps inside the deep purple. The other cues are:

  | Phase | Rain | Wind slant | Ceiling speed / contrast | Lightning | Fog + | Key / ambient | `surge_intensity()` |
  |---|---|---|---|---|---|---|---|
  | Calm | 0.4 | 0.45 | 0.008 / 0.3 (slow) | none | 0.0008 | 0.42 / 0.6 | 0.25 |
  | Building | 0.65 | 0.85 | 0.03 / 0.5 (fast) | faint in-cloud flicker only (sheet glow 0.15) | 0.0016 | 0.3 / 0.45 | 0.65 |
  | Break | 1.0 | 1.0 | 0.045 / 0.55 (fastest) | strikes, distant flashes and a persistent in-cloud sheet glow (0.9) | 0.0026 | 0.2 / 0.38 | 1.0 |
  | Fading | 0.15 | 0.7 | 0.014 / 0.3 (slowing) | none | 0.0012 | 0.4 / 0.58 | 0.4 |
  | Aftermath | 0.08 | 0.3 | 0.002 / 0.12 (almost still) | none | 0.0006 | 0.45 / 0.62 | 0.1 |

- **Judge-7 findings folded in:**
  1. **Break lightning a still can catch.** The ceiling shader has a new sheet glow: fbm patches that pulse slowly inside the cloud body. Break carries 0.9, and Building only 0.15, which reads as a rare, faint flicker. The glow is multiplied by the reduced-motion flash scale (floor 0.15, unchanged) and its clock freezes under reduced motion. There is no strobing.
  2. **The ground darkens with the phase** through the key light and ambient, not a screen tint. Break's ground mean is 23/255, Building 33, Calm and Fading about 40, the aftermath 44.
  3. **Fog and the distant rain curtain scale with the phase.** Fog density is added per phase as above. The far rain layer grows to 1200 drops and follows `rain_amount`.
  4. **Ceiling motion order:** Calm slow, Building fast, Break fastest, Fading slowing, aftermath almost still. This is tested.
  5. **Hue stays in the purple family.** Fading's pink horizon is gone. Every row is within 15° of Break's hue.
- **Hook.** `StormwoodSurge.surge_intensity()` is a read-only 0–1 value, blended with the cross-fade. It is there for the ground-electricity effect on another branch; that effect is not built here.
- **Review nits:**
  - `is_instance_valid(target)` is checked before `target is Node3D`.
  - The rain band anchors on the framed subject's last grounded height, so jumps don't bob the field.
  - The camera ground is sampled every frame and eased at 8/s. It snaps on teleports of more than 20 m. The old 0.25 s steps are gone.
  - On steep slopes, 6 ring samples at 6 m raise the band floor to (highest sample − 2 m).
  - The `pin_time_of_day: false` branch is tested.
  - Separation thresholds are visible margins, not token ones.
- **Tests** (`tests/test_stormwood_surge_presentation.gd`, 41 tests):
  - `test_every_phase_sits_in_the_deep_purple_band`: sky top, horizon and ceiling are 0.8–1.15× Break's luminance and within 15° of its hue.
  - `test_phases_separate_by_non_sky_cues`: adjacent phases differ in at least two of these cues, and the ceiling-motion and rain orders hold:
    - rain by at least 0.2;
    - ceiling speed by at least 1.5×;
    - wind by at least 0.2;
    - sheet glow by at least 0.1;
    - flashes.
  - `test_sheet_glow_reaches_the_ceiling_and_respects_reduced_motion`
  - `test_phase_wind_and_intensity_hook`
  - `test_rain_anchor_holds_through_jumps_and_eases_on_slopes`
  - `test_pin_off_restores_the_clock_look`
  - `test_look_is_identical_at_every_hour` is kept.
- **Negative control N24:** the round-1 pale Calm row fails `test_every_phase_sits_in_the_deep_purple_band`. Calm's sky top is 1.19×, its horizon 1.24× and its ceiling 1.27× Break's luminance.
- **Frames:**
  - `visual/surge/sheet_purple_phases.jpg` and `after/purple_{calm,building,break,fading,aftermath}_h{12,00}.jpg` were re-shot under the same names. Their records are in `after/frames_after_purple.json`.
  - `visual/surge/sheet_purple_motion.jpg` holds 4 frames per phase, 0.25 s of game time apart, at hour 12. The capture group is `--only=purplemotion`, and the surge clocks are in `after/frames_after_purplemotion.json`.
- **What I saw:**
  - All five phases are now the deep purple. Sky means are 52–62/255 (the round-1 pale set was 86–98).
  - The hour-12 and hour-0 pairs match: sky 55.1/55.0 (Calm), 59.5/59.5 (Building), 51.8/52.3 (Break), 54.7/54.6 (Fading) and 61.6/61.7 (aftermath).
  - In the motion strip, Break shows lighter in-cloud glow patches low on the horizon that change from frame to frame. Its rain is the densest and most slanted.
  - Building has heavy slanted rain and a textured ceiling, with no visible glow in these four frames.
  - Calm and Fading show sparse, near-vertical rain.
  - The aftermath is the stillest: a smooth ceiling and only a few drops.
- **Open:**
  - The grass still reads fairly green in Calm, Fading and the aftermath. The darkening is only through light and ambient, by design.
  - Building has no distant flashes, only the faint glow, which rarely shows in stills.
  - The slope-floor ring is exercised by the anchor test's easing but has no direct steep-terrain fixture.
  - No blind judge has seen the round-2 set.
