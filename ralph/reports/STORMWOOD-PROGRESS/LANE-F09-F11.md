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
- **Captures:** 36 player-camera frames under `visual/f09/`, with HUD on, day and Calm pinned, and state staged (`stormwood:rootgate_released`). See `sheet_pockets_after.jpg` and `sheet_roads_forest_before_after.jpg`; the before frames are main's data and bake.
  - At walking height each pocket reads as an enclosure of giant dead trunks with touching bases.
  - The rewards and their prompts are inside, and nothing is floating or buried.
  - The rerouted Rootgate valley and the new Dynamo road read as tree-lined routes. The Ember Bivouac arrival is no longer blocked by two trunks.
- **Open:**
  - **Visual (from the captures):**
    - Crowns show sky through the palisade at 2–5 m, above head height; the bases are closed.
    - From 30 m out, three of the five pocket mouths are hard to read (hidden by a nearby tree, the slope or a boulder). No lure yet.
    - The new scatter hides the rod-station tower from the middle of `dynamo_west_approach`.
    - Roads have no visible surface; this is pre-existing, since roads are corridors, not carved paths.
  - The scatter still does not clear trainer, NPC, harvest or pickup seats. There are 7 near-contacts, the same count as the old bake.
  - `blackwater_elder` stands on a deepwood_road vertex.
  - The arch commit at the footing centre is routed to the co-op lane.
  - The coordinator edits WORLD.md's route count (nine → ten) on landing.

## WO-F09-02 — Pocket mouths, Dynamo tower sightline, seat clearings (`ralph/stormwood-f09-pocket-polish`, stacked on WO-F09-01)

- **Pocket lure** (`stormwood_pockets.gd`, `stormwood_pockets.json` `mouth_lure`): two wayfinding lamps flank each mouth, on posts against the wall's outer face. They use the Stormheart ascent-lamp vocabulary: the installed `Lantern_Wall.gltf`, an amber flame, a short warm OmniLight and a bark-finish post. Each post has a static collider on every peer; the lamp art is client-only. Nothing is red.
- **Approach cone** (`stormwood_pockets.json` `approach_clear`, read by the scatter): the cone starts 6 m either side of the mouth, widens at 20°, and runs out 45 m. No tree or colliding rock stands inside it. Ground cover is kept out of its first 18 m.
  - On the old bake, 4 of the 5 cones held a trunk or boulder. This includes the 6 m trunk at Verge, the boulder at 15 m at Hollows and the trunk at 30 m at Conductor.
- **Dynamo tower** (`stormwood_world.json` `landmark_sightlines.dynamo_west_to_stormheart`): a 22 m clearing runs from the road bend (-700,4820) to the Dynamo core (-100,5470), which removes 28 trees.
  - The tower the captures showed is the Dynamo core. The rod station is a 9 m pylon and is not visible at this range.
- **Seats** (`stormwood_vegetation.json` `seat_clearings`):
  - No collider surface within 3.5 m of a trainer or NPC, and within 2.0 m of a harvest node or pickup. Collider reach is taken at the layer's scale_max.
  - No ground cover centred within 3.0 m of a trainer or NPC, or within 1.5 m of a harvest node or pickup.
  - Result: the nearest surfaces are trainer 6.93 m, NPC 5.99 m, harvest 2.37 m and pickup 2.54 m. On the old bake they were 0.69, 5.99, −0.21 and 0.53 m.
  - **Bake staleness:** the seat files are *not* whole-file SOURCES. Only each seat's kind, id and XZ position enter the fingerprint (`seat_fingerprint_text`). Moving, adding or removing a trainer, NPC, harvest or pickup stales the bake, and production refuses vegetation until it is re-baked. Dialogue, party or item edits do not stale it. Every `stormwood_pockets.json` edit, including the lamp tunables, still stales the bake as before.
- **Comment:** the scatter comment now says what the per-road seeds do and do not isolate. The shared `occupied` table and a rejection's skipped draws can re-plant later roads and cells.
- **Witnesses:**
  - The new `test_stormwood_scatter_clearances` covers seats, sightlines and approach cones. On the WO-F09-01 bake it fails 3 of 5: 19 crowded seats, 28 sightline trees and 4 dirty cones.
  - `test_stormwood_pockets` now counts the two lure-post colliders.
  - Two bakes are byte-identical.
  - `--only=test_stormwood_,test_road_creature_visibility,test_scatter_,vegetation` ran 68 files, 344 tests, 0 failed and 0 SCRIPT ERROR.
  - Smokes pass: pickup runtime, hosted rewards and arches.
- **Captures:** `visual/f09/wo02_after/` (6 frames plus `frames_wo02.json`) and `visual/f09/sheet_wo02_mouths_sightline_before_after.jpg`. The before frames are WO-F09-01's `after/`.
  - At 30 m, every mouth now has a clear axis and is marked by two pale amber lamps at head height. The Verge trunk, the Hollows boulder and the Conductor trunk are gone.
  - The lamps are small, roughly 8 px at 1280×720, and the flame reads pale yellow rather than warm in daylight. They mark the mouth, but they are not a strong lure from road distance (112–351 m).
  - The gap itself still shows back-wall trunks through it.
  - `dynamo_west_mid`: the tower is fully visible again on the hill.
  - This container's import cache lacks `Rocks_Diffuse_meadows.png`, so the renders logged load errors for it. The rocks look the same pale grey as in WO-F09-01's frames.
- **Open:**
  - The lure is not visible from the road itself.
  - The flames overexpose in daylight.
  - The lamps have no night capture.
  - The sightline is a straight 44 m-wide lane that could read as cut from above.
  - The WO-F09-01 open items still stand.

## WO-F09-03 — Pocket spurs, junction lamps, review follow-ups (`ralph/stormwood-f09-pocket-spurs`, stacked on WO-F09-02)

- **Finding:** pocket centres stood 112–351 m off their roads, and nothing on a road pointed to a pocket.
- **Fix: one spur per pocket** (`stormwood_world.json`, `"kind": "spur"`, with `pocket_id`, `joins` and the joined road's `requires_unlock`). Each spur is a straight lane from the nearest point on its road to the mouth. The mouths already faced that point, so no bend was needed.
  - Verge → `ash_road` 270 m; Hollows → `crown_sightline_loop` 137 m; Conductor → `conductor_road` 341 m; Deepwood → `hall_loop` 155 m; Dynamo → `dynamo_west_approach` 103 m.
  - The steepest graded corridor sample is 17.7° (Dynamo). The others are at most 11.1°.
  - **Why spurs, not moved pockets:** spurs are data plus one lamp. Moving pockets would re-validate five interiors, five moved rewards, spawn discs and region bounds, and 40–80 m would still leave a pocket out of sight of the road.
- **Junction lamp** (`stormwood_pockets.json` `spur_marker`): a third `mouth_lure` lamp post. It stands 10 m up the spur and 3.5 m to its right, clear of every road corridor, faces the road, and has its own collider.
- **Route consumers checked:**
  - The ROAD visibility model, the audit/author tools and the four-biome observer read only `critical`.
  - `smoke_stormwood_continuous._walk_route` selects routes by id.
  - The trainers-near-routes test: no trainer's nearest route is a spur.
  - The glass-sink and walkability tests grade spurs like roads, and they pass.
  - `test_stormwood_pockets` now means "roads" as non-spur routes.
- **Scatter:** spurs get the corridor clearing but no roadside stand. A stand would line a dead-end lane like a through road and claim tree cells the background forest now fills. The re-bake changed 34694 → 34691 placements. On the old bake, 3 of 5 spur lanes held a collider 0.47–1.58 m from the centre line.
- **Review LOWs:**
  - (a) The mouth-to-road search now sweeps the 0.4 m capsule past every committed baked collider and lamp post, and must reach a non-spur road. It has a built-in control: a closed ring of trunks outside the mouth must fail the same search, and it does.
  - (b) An unpaired legacy arch with no saved footing no longer counts against the three-road cap, and no longer blocks the Crown twin. A legacy arch that is half of a standing pair still counts, because that road still travels. The existing cap tests use paired legacy roads and are unchanged. There are two new tests, and both fail on the old rule.
  - (c) Config `draw_distance`: the 190 palisade trunks and the lamp art stop drawing at 250 m, with a 30 m fade. The 15 lamp lights use Light3D distance fade, ending at 60 m, because lights have no visibility range.
  - (d) The frame maths is now in one place, `stormwood_pocket_frame.gd`, which is a bake source. The pocket collider reach is `max(collision_radius × scale_max)` and still equals 2.61.
  - (e) A seat row without a position is skipped.
- **Witnesses:**
  - Two bakes are byte-identical.
  - `--only=test_stormwood_,test_road_creature_visibility,test_scatter_,vegetation` ran 68 files and 348 tests, with 0 failed and 0 SCRIPT ERROR.
  - `test_stormwood_pockets` has 10 tests, 0 failed.
  - Both smokes pass: `smoke_stormwood_arches` and `smoke_stormwood_pickup_runtime`.
- **Captures:** `visual/f09/wo03_after/` (5 road-side junction frames, 1 mid-spur frame, `frames_wo03.json`) and `visual/f09/sheet_wo03_spurs.jpg`. The frames were not self-judged; the blind judge is with the coordinator.
- **Open:**
  - The spur has no surface, like the roads. Much of the forest here is open grass with sparse trees, so the cleared corridor alone draws no visible line.
  - WORLD.md says "nine top-level route records"; the data now has 15 (10 roads + 5 spurs). The coordinator owns that edit.
  - There is still no night capture of the lamps.

## WO-F09-04 — Routes visible on the ground, junction lamps, electrified roads (`ralph/stormwood-f09-road-surface`, stacked on WO-F09-03, merged with main fe07d0d28)

- **Finding (code-blind judge on `sheet_wo03_spurs.jpg`):** a player walking the road would not notice a side path. Roads and spurs were invisible on the ground. The junction lamp read as decoration.
  - **Root cause:** the Stormwood bake wrote heights only, and every control texel stayed on Terrain3D's auto shader.
- **Route paint** (`build_stormwood_terrain.gd`, new `data/config/stormwood_road_surface.json`):
  - **What is painted:** every one of the 15 routes, including the 5 spurs.
  - **Texel value:** `base = overlay = path` (terrain_playground slot 3), blend 0, auto bit cleared. This is Meadows' measured base-id rule; a partial blend does not draw on this build. Every other texel keeps the default auto texel.
  - **Lane half-width by kind:** critical 2.8 m, alternate and loop 2.5 m, island 2.3 m, spur 2.0 m.
  - **Edge:** 0.45 m of coherent wander on a 26 m wavelength, plus a 0.6 m per-texel fringe. The fringe uses an integer hash, so it is the same on every machine.
  - **Spur junction:** the spur flares 2.4 m wider at the junction, easing out over 14 m.
  - **Result:** 29,580 texels painted.
  - **Grass:** `grass_field.gd` reads the same control map, so grass leaves the lanes and its stone tier fills them. No shared file was edited.
- **Height proof:**
  - `tools/probe_stormwood_terrain_channels.gd` decodes every region, old against new. In all 108 regions the height_map, color_map and height_range are identical. The sha256 over all height bytes is `56dcc98c…65e7d2` both before and after.
  - Only the control map differs: 40 regions, 29,580 texels, every one `0x18c00000`.
  - `test_committed_heights_still_match_the_heightfield` samples about 3,000 committed heights against `stormwood_heightfield.gd`. The worst difference is under 1 mm.
- **Determinism:**
  - Godot's resource saver had been giving every region's map images a random `Image_xxxxx` id. Two bakes of the same content therefore differed in bytes, including the previously committed files.
  - The bake now names the three map sub-resources before saving.
  - Two full in-place bakes are byte-identical over all 109 files (108 regions + manifest). The sha256 of the sorted `sha256sum` list is `d045fbf2…4dbfe`.
  - The manifest fingerprint now covers the surface config and `terrain_playground.json` too (it already covered `stormwood_world.json`). Moving a route stales the bake.
- **Scatter:** the `stormwood_pockets.json` edit stales the scatter fingerprint (the whole file is a source). I re-baked it. All 108 bins are byte-identical and only `manifest.json` changed.
- **Junction lamps** (`spur_marker.lamp` overrides `mouth_lure` for the junction post only):
  - Post 5.2 m, lantern ×2.1, flame centre 4.7 m up (2.6× the trainer).
  - Pale post `#e2cfa4`, which separates from the dark trunks.
  - Unshaded flame at emission 8, plus a 1.2 m additive glow billboard built from a generated radial gradient (no new asset).
  - It stands on the verge of the painted spur, inside its tree-cleared corridor. The mouth lamps are unchanged.
- **Compatibility fades, measured** (`tools/probe_compat_fade_synthetic.gd`: a still scene with the pocket config's exact settings; in-world diffs were swamped by wind and sky motion even with a noise floor):
  - **Lamp light (Light3D distance fade, gone by 60 m): works.**
    - Floor light under the lamp by camera distance: 20 m 42.9, 44 m 6.9, 50 m 4.4, 55 m 1.9, 59 m 0.08, 62 m 0, 70 m 0.
    - No fallback needed.
  - **Palisade and lamp meshes (visibility_range_end 250 m, margin 30 m, FADE_SELF): no fade in Compatibility.**
    - The box is at full brightness at 249, 265 and 279 m, and gone at 285 m. That is a hard pop at `models_m + models_fade_m` = 280 m.
    - The config comment's "fading over models_fade_m" is therefore not true on this renderer. I did not re-tune it: any `stormwood_pockets.json` edit stales the scatter bake.
  - **In-world frame pairs:** `wo04_fade/` and `sheet_wo04_fade.jpg`, with numbers in `world_fade_probe.txt`.
    - Lamp at 40 m and 70 m, light on and hidden. The light was raised to energy 40 for the probe, and rain was hidden.
    - Palisade at 230 m and 270 m.
    - At 40 m the warm ground pool shows with the light on. In the 70 m pair a wild bird creature stands between the camera and the lamp. The palisade is a small grey clump on the horizon at both 230 and 270 m, as expected for a cut at 280 m.
- **Review nit, route grounding:** `test_stormwood_trainers_data` measured the trainer anchor's route distance against every route, spurs included.
  - **Rule now:** a trainer is route-grounded only against **through routes**, which is every kind except `spur` (a spur is a dead-end lane to one pocket).
  - A new control shows that the Verge pocket mouth (on its spur, far from any road) fails the check, and passes only if the spur is counted as a road.
  - **Proposed WORLD.md wording, for the coordinator:** "Route-grounded placements (trainer anchors) measure distance to through routes only; `kind: spur` lanes to pockets do not count."
- **Owner direction (verbatim):** "Can you make the path and roads electrified with yellow electricity flowing through them somehow in the ground."
  - **Build:** `scripts/world/stormwood_road_current.gd`, `shaders/stormwood_road_current.gdshader`, and `data/config/stormwood_road_current.json`. The config is kept separate from the surface config so tuning the look never stales the terrain bake.
  - **Geometry:**
    - Every route and spur gets terrain-conforming ribbon chunks: at most 48 m long, 1 m rows, 5 columns, lifted 8 cm on the live Terrain3D height.
    - The ribbon is 0.85 of the painted lane width, and the shader feathers it to nothing well inside that.
    - 574 chunks share one ShaderMaterial. They have no colliders and cast no shadow, and each has a visibility_range_end of 150 m.
    - The shader fades the current out over the last 25 m itself, because FADE_SELF does not work in Compatibility.
    - A vertex depth-pull (a slide along the view ray, so nothing moves on screen) keeps the far, coarser terrain mesh from swallowing the ribbon.
  - **Look:**
    - Additive and unshaded: three meandering, jagged, broken cracks per lane plus a hairline web.
    - Comet-shaped charge pulses run along each crack on its own phase, with a pointed head. They flow at 7 m/s with 11 m spacing.
    - A light crackle flicker plays on top.
    - Colours are `#fff4b0` core and `#ffc21a` edge (yellow/gold). They are not the magenta telegraph `#ff40e6` and not Team Tether oxblood.
  - **Flow direction:** toward the Dynamo `(-100, 5470)`. Each open route flows from its end farther from the Dynamo to its nearer end.
    - Closed loops (the five loops and `crown_ring`, whose first point equals their last) have no nearer end. They flow in polyline order.
  - **Presentation only:** nothing is built when `simulation_only`. The only script work after build is a 0.5 s timer.
  - **Reduced motion** (`motion_prefs`): flow drops to 1.2 m/s and flicker to 0. The timer follows the setting live.
  - **Storm coupling:** `set_storm_intensity(0..1)` sets one uniform.
    - The timer reads `StormwoodSurge.phase`. Main's surge-readability exposes no phase signal, so this reads its public field; `stormwood_surge.gd` is not edited.
    - Per-phase values come from config: Calm 0.55, Building 0.78, Break 1.0, Fading 0.4, eased over 2.5 s.
    - After `stormwood:long_storm_ended` (the flag the surge itself reads for its aftermath) the value is 0.18.
    - No OmniLights were added at junctions.
  - **Cost** (per-frame records in `frames_wo04_current.json`):
    - 8–14 chunks are within draw range at any stand, out of 574.
    - At the motion-strip stand, frame draw calls are 5,744 with the current and 5,740 without: +4.
    - Build time is not separately measured; it is inside the world build.
    - Not profiled on an Ally.
- **Tests (each with its negative control):**
  - `test_stormwood_road_surface`, 10 tests:
    - Every centreline has at least 97% path texels. Control: routes moved 40 m sideways, and an unpainted map.
    - No path texel is more than 7.8 m from every route. Control: a stray painted patch is found.
    - The last 12 m to each spur's mouth and its first 20 m are painted. Control: 12 m inside the pocket is not path.
    - Painted width per kind is within 0.9 m of config. Controls: double width is rejected, and a 1.2 m synthetic lane measures as its own width.
    - The junction flare is wider at 7 m than at 30 m. Control: no flare gives a flat half-width.
    - The bake is fresh against its fingerprint. Control: moving a spur point 1 m stales it.
    - Committed heights equal the heightfield. Control: a field 1 m higher is caught.
    - Junction lamp size, emission, halo and collider all come from config. Control: the unchanged mouth lamp fails the 2.4× height check.
    - Config validation. Control: an unknown route kind and an unknown slot are refused.
  - `test_stormwood_road_current`, 7 tests:
    - Chunks cover at least 98% of every route and spur. Control: stripping the spur chunks is caught.
    - Chunks have a range limit, no shadow, one shared material and no collision. Control: an added body is found.
    - Nothing is built on simulation_only. Control: a presentation world does build.
    - Reduced motion gives calm flow and 0 flicker. Control: the live toggle back restores both.
    - Colours come from config and have a yellow-gold hue (35–65°). Controls: magenta and oxblood are rejected.
    - The ribbon lies inside the lane and flows toward the Dynamo. Controls: width fraction 1.3 leaves the lane, and an outbound polyline is reversed.
    - Intensity comes from config per phase and is clamped. Control: an unknown phase reads as Calm.
  - `test_stormwood_trainers_data`: the spur rule above.
  - Tests, SCRIPT ERROR grep: the final run of the added/changed files (`test_stormwood_road_surface`, `test_stormwood_road_current`, `test_stormwood_pockets`, `test_stormwood_trainers_data` and `test_stormwood_terrain_bake`): 35 tests, 3,665 assertions, 0 failed, 0 SCRIPT ERROR. Before the main merge, `--only=test_stormwood_,test_road_creature_visibility,test_scatter_,vegetation` ran 365 tests, 0 failed, 0 SCRIPT ERROR.
- **Captures** (production CameraRig, HUD off, Calm; `visual/f09/README.md` has per-frame notes):
  - `wo04_after/`, sheet `sheet_wo04_spurs.jpg`: road paint only (the current not mounted); the six spur frames and two road stretches.
  - `wo04_current/`, sheets `sheet_wo04_current_day.jpg` and `sheet_wo04_current_night_motion.jpg`: the same eight frames with the current, two stretches at the art.json `night` preset, and a four-frame motion strip at a pinned shader clock of 100.00, 100.25, 100.50 and 100.75 s.
  - `wo04_fade/`, sheet `sheet_wo04_fade.jpg`: see above.
  - **Sky:** main's new surge skies are merged, so these show the Calm overcast. The always-purple sky is not on this branch.
  - The frames were not re-judged blind.
- **Open:**
  - **Understory on the lanes:** the scatter's non-colliding understory (ferns, mushroom shelves, bushes) still stands on painted lanes in places, e.g. Conductor's junction. Only colliders keep the road corridor. Fixing this means a `stormwood_scatter.gd` rule and a re-bake.
  - **Palisade pop:** it pops at 280 m instead of fading, and the config comment overstates it (see above).
  - **Path colour:** the path slot keeps the Stormwood `737080` multiplier, so the dirt is mid-brown rather than Palworld-pale.
  - **Current by day:** the current is subtle in daylight, by design, since it is additive. It is judged at night / on the storm sky.
  - **Not verified:** no blind re-judge, no Ally profile, and the current's Surge coupling has not been seen live across a Break.


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


### WO-F11-03: LB prompt after a Break faint

- **Finding (step 1, real director):** LB already sends out the next creature during Break. `party_cycle` goes to `encounter_director.gd` `_read_creature_control_input()`, then `party.cycle_active(1)`. That step skips fainted and resting creatures and bumps `revision`. `_sync_active_creature()` sees a hidden but valid `_ally_body` whose creature is not the new active one. It dismisses that body (`queue_free`) and summons the new active creature as a visible follower. The field control then pilots the follower once it is within reach of the arena. `summon_active_creature()` alone (the `creature_recall` path) is a no-op while the hidden fainted body is still deployed. The only gap was that nothing told the player to press LB. No shared file is changed.
- **Change:** `stormwood_dynamo.gd` `_apply_local_hazard()`, on a Break discharge faint, pushes one world message: "<name> fainted. Press <party_cycle> to send out <next>." The button name comes from `input_glyph.gd` `action_name()`, so it follows rebinding and shows LB on a pad. `next_available()` mirrors `cycle_active(1)`. The message is sent once per faint, because a fainted creature takes no more damage. It is not sent when no creature can take the field, since the existing full-party wipe runs instead. The game still does not switch creatures on its own.
- **Witnesses:** all `test_stormwood_*` suites: 241 tests, 25103 assertions, 0 failed. Smokes: dynamo_break_faint 66/0, stormheart_choice 41/0, stormheart_participants 28/0. No SCRIPT ERROR.
- **Negative controls:**

  | Change reverted | Result |
  |---|---|
  | Prompt push removed | 1 smoke fail |
  | `next_available` counts a resting creature | 2 smoke fails + 1 unit fail |
  | In test: no LB press | The fainted creature stays active and hidden, and the prompt is not repeated |
- **Review should-fix: pause while choosing a replacement.** COMBAT says a faint "pauses enemy attack issuance until a replacement is selected … in co-op other participants continue."
  - **When it pauses.** The host freezes Break: no `rules.advance`, no bank fire and no countdown. It does this while no current participant has a live creature and at least one participant is waiting to replace a fainted one.
  - **How liveness is read.** The host's own creature is the director's `ally_instance`. Another peer's is the card the host holds, down once that peer reports the creature fainted with `dynamo_ally_fainted`.
  - **Publishing.** The state event carries the pause as `paused`.
  - **What does not pause.** Only participants count. A recall with no faint behind it never pauses. The existing logic still drops a participant who leaves, and a full-party faint still takes the wipe path.
  - **Prompt re-show.** A still-paused Break shows the prompt once more after 4 s, and never a third time.
  - **Not changed.** The arena readout is outside this lane, so it shows the frozen seconds with no "paused" label.
- **Witnesses:** all `test_stormwood_*` suites: 241 tests, 25103 assertions, 0 failed. Smokes: dynamo_break_faint 77/0, stormheart_choice 41/0, stormheart_participants 28/0.
- **Pause negative controls:**

  | Change reverted | Result |
  |---|---|
  | Pause disabled | 6 fails |
  | A live partner ignored | 1 fail (the co-op check) |
  | Re-show removed | 1 fail |

## WO-F11-04: earned Dynamo → aftermath witness (`ralph/stormwood-f11-proof`)

**Status: STOPPED at the named Capacitor Alpha (first step after Ondra's recipe), after three real attempts.** The Dynamo, the Stormheart offer, the aftermath, the reload and the captures were not reached. No F11 clause is met by this witness.

- **Platform:** Linux container, Godot 4.7-stable, headless `--script` runs (no render for the witness itself).
- **Input:** ordinary controller actions injected as `InputEventAction` (stick, interact, combat_quick, party_cycle, creature_recall, ui_*, menu_cancel) through the existing segment helpers. Each helper lists its own exceptions.
- **Starting save origin:** `tests/smoke_stormwood_continuous.gd` with its disclosed in-memory seam. That seam supplies nine completed-Cloudreach world flags, a party of five at level 44 (sparkit, mudsnout, bramblebun, terrapup, brooktail) and knife/axe/pickaxe on the hotbar. It sets no `stormwood:*` flag. With `--witness-dir=user://f11_witness`, the first real disk save (autosave slot 0 plus the world/character split) is written at the authored Stormwood arrival, before any Stormwood action. The same live run then continues.
- **Route:** the normal route by ordinary input, with the instrumented timing the segments already declare: 8x weather/locomotion clock, and combat at 1x.
- **Command:** `godot --headless --path . --script tests/smoke_stormwood_continuous.gd -- --through-aftermath --witness-dir=user://f11_witness`, then the same command with `--verify-reload` in a new process.

### Fixes the runs showed (all Stormwood-owned, each committed before the next run)

| Run | First failure | Diagnosis | Fix |
|---|---|---|---|
| 2 (`--through-crown`) | Varga's 3rd round lost | Prefix route fights ran at the 8x clock, but the press cadence is wall-clock | `_fight_current_encounter` runs combat at 1x, as the Crown helper already did |
| 3 | Varga lost again (worn lead) | A trainer sequence is fought by one creature; the lead was worn by road fights | Before a named trainer, send out the fittest member with ordinary LB presses |
| 4 | Route-09 reward press taken by Keeper Ondra | The pickup stood exactly on Ondra | Pickup moved 7 m along the road. Regression: `test_stormwood_pickups` overlap check (fails on the old data) |
| 5 | Capacitor Alpha lost with a 113/436 lead | Same worn-lead cause, in the Crown chain | `_ensure_usable_ally` in the Crown helper also leads with the fittest member |
| 6 | Hollows rod switch press taken by route-06 | The pickup stood exactly on the rod station and Dace | Pickup moved 9 m along the road; the overlap test pins it |
| 6 | Alpha: no fight in four approaches | Engage offers the nearest body, always a Tanglevolt escort; the helper refused to press it | Answer an escort that holds Engage, then approach again (up to 8 approaches) |

| 7 | Alpha: whole party wiped | See below | None. Stopped: third Alpha attempt |

### Per-step timing (headless wall clock, commit 9407429a0 for run 7)

| Run | Prefix: arrival → Ondra's recipe | Capacitor Alpha → paid Crown | Total |
|---|---|---|---|
| 4 (a91d59ec5) | PASS 1062.3 s | FAIL 100.1 s (lost with a 113/436 lead) | 19m36s |
| 6 (5ca1a839e) | PASS 1058.6 s | FAIL 69.4 s (no fight: Engage always offered an escort) | 19m00s |
| 7 (9407429a0) | PASS 1094.8 s | FAIL 223.1 s (party wiped) | 22m11s |

SCRIPT ERROR count is 0 in every run log. Across the last three runs the prefix passed from the disk-saved arrival. It includes Hesk, Tamsin, the sheltered Break, pair A, Maren, Dace, pair B, Act I, Varga, and route 09 and Ondra's recipe.

### The Capacitor Alpha stop (run 7, exact log lines)

- `PARTY before Capacitor Alpha re-engagement: sparkit 320/320, mudsnout 0/363 fainted, bramblebun 185/345, terrapup 94/436, brooktail 0/334 fainted`
  - This is how the party reaches the Alpha, with no rest since Ashfoot. The conductor-road wilds on the way there fainted two members.
- `ENGAGING the Alpha's escort Wild_tanglevolt_881250888_1` → `FIGHT end Capacitor Alpha escort outcome=won` (sparkit 117/320 left).
- The second escort: `outcome=lost` (bramblebun fainted, escort at 54/318). Sparkit then finished that escort (`live approach 3 outcome=won`).
- `FIGHT start Capacitor Alpha ally=sparkit 100/320 enemy=voltarach L40 511/511` → `lost`, with the Alpha at 314.9/511.
- `FIGHT start ... live approach 4 ally=terrapup 94/436` → `lost`, with the Alpha at 121.3/511.
- `F11 WITNESS STEP FAIL Capacitor Alpha, Crown gathering, two frames, paid Crown arch wall=223.1s`, then `ordinary party-cycle/recall left no usable ally before Capacitor Alpha re-engagement (healthy=0)`.

**Diagnosis.** This is not a softlock and not a production defect in the Alpha's code path. The fight admits, runs host-validated strikes and publishes outcomes. The harness mashes quick attacks with no dodge. It arrives with two of five fainted and two worn, because the route never rests. It must then beat two L35 escorts and an L40 Alpha of 511 HP in sequence.

**The next step, not taken because of the attempt limit:** rest at Rodline Refuge (its camp bed and rest prompt are 0.7 km back along the same road) before the Conductor Road. Then answer the escorts and the Alpha with a full party. That is ordinary player preparation, not a fixture.

**Open question for owner or design:** is a named alpha with two escorts, fought one at a time from the road, intended to require a rest stop before it? C2/C3 tuning belongs to COMBAT, not this lane.

### Run 8 onward: rest before the Alpha (coordinator order after 0a653a7c2)

- **Rest step** (c46170432 and 62dcc3009): at the start of the Crown segment the player rests at **Still Grove Shelter**. That is the camp beside Ondra, where the segment begins, and the nearest camp on the route; Rodline Refuge is 630 m back. It takes one night per worn creature. Each night uses ordinary input: Interact with the creature bed, pad Down/A to that creature's row, B to close, then Interact with the camp's "Rest at" prompt. If the road fights leave a creature fainted before the grove, the segment walks back and rests again. The rest runs at the 1x clock: at 8x, run 9 pressed the bed five times and nothing activated.
- **Pickup seats** (f7266aaaf): route pickups 05, 07, 16 and 18 moved 8 m along the route, off Pim, Bryn, Rook and Kestrel. Run 10 lost a press to Bryn on route 07, which had passed in earlier runs. The scatter is re-baked (manifest fingerprint only). test_stormwood_scatter_bake, pickups, pickup_runtime and continuous_route_pickups: 13 tests, 0 failed.

| Run | Commit | Prefix | Crown step |
|---|---|---|---|
| 8 | c46170432 | PASS 1121.3 s | FAIL 0.0 s: precondition "knife on the controller hotbar" |
| 9 | e1166322b | PASS 1114.3 s. Tools `knife x1 axe x1 pickaxe x1` | FAIL 13.1 s: `still_grove_shelter creature bed never won the InteractionArbiter` (winner was that bed; the 8x tap was lost) |
| 10 | 62dcc3009 | FAIL 829.9 s: `stormwood_pickup_route_07 route reward press activated competing provider .../Warden-Elect Bryn/Interactable` | not reached |
| 11 | f7266aaaf | PASS 1115.3 s. `F11 WITNESS TOOLS after prefix: knife x0 axe x0 pickaxe x0 hotbar=["knife", "axe", "pickaxe", "", ""]` | FAIL 0.0 s: `Crown segment requires the campaign-earned knife on the controller hotbar (inventory knife x0, axe x0, pickaxe x0, hotbar [...], equipped 'pickaxe')` |

SCRIPT ERROR count is 0 in runs 8 to 11.

**Moved pickup seats, for the reviewer** (`data/config/stormwood_pickups.json`, [x, y, z]). Each moved seat carries a `_why_moved_f11` note. The new y is `stormwood_heightfield.height_at` + the original 0.35 m, and every new spot is still on the critical route. The scatter is re-baked for each move: 0a653a7c2 for 06/09, f7266aaaf for the rest.

| Pickup | NPC or station it sat on | Before | After | Commit |
|---|---|---|---|---|
| route_09 | Keeper Ondra | [-160, 34.89, 2700] | [-166.1, 35.34, 2696.6] | 0aeaf2f7c |
| route_06 | Hollows rod station / Dace | [-900, 32.3, 1780] | [-896.8, 31.08, 1788.4] | 5ca1a839e |
| route_05 | Courier Pim | [-380, 32.58, 1400] | [-384.2, 32.34, 1393.2] | f7266aaaf |
| route_07 | Warden-Elect Bryn | [-700, 44.38, 2300] | [-702.9, 43.69, 2292.5] | f7266aaaf |
| route_16 | Ace Trainer Rook | [-150, 61.34, 4460] | [-158.0, 61.15, 4460.3] | f7266aaaf |
| route_18 | Officer Kestrel | [-100, 107.92, 5350] | [-104.6, 107.91, 5343.4] | f7266aaaf |

`test_stormwood_pickups::test_no_new_pickup_shares_an_npc_interaction_circle` pins these clear. It still lists route_19 (on the ground 150 m below Marrow's platform) and pocket_203 (Neri's pocket, off route).

**Stopped (stop rule: second failure of the same new step, runs 8 and 11).**

- **What the evidence shows.** The whole inventory is empty while the hotbar still binds the tools. Only `player_death.gd::_die_now()` does that: it moves the inventory into a death satchel and respawns the trainer at the nearest safe camp. Still Grove Shelter, the respawn camp, is 30 m from Ondra, so the harness walk would hide the teleport.
- **Most likely killer.** Stormwood lightning on the 116-second Conductor Road walk, run at the wrapper's 8x weather clock with no dodge or shelter.
- **Not confirmed.** Neither run logged the death. 083e0348f now prints each finalized death with the active walk; it has not been run.
- **Proposed next step** (a harness change, not a game change): after a logged death, walk back to the satchel and take it with its ordinary prompt, as a player would. Or run the Conductor Road walk at the 1x weather clock so telegraphs can be avoided.
- **Alpha.** Not reached with a rested party, so there are no fight numbers for the tuning question.

### Runs 12 and 13: lightning handling, satchel recovery, the camp rest (commits 544f87648, 2e7e43c9c)

- **Harness** (`tests/helpers/stormwood_field_safety.gd`, used by both walkers):
  - The walker reads the production strike warnings. While a live warning's radius (3 m + 1.5 m) holds the trainer, it steers the stick out of it.
  - It logs every warning, hit and death with the walk or fight in progress.
  - After a death it walks back to the satchel and takes every stack out through the satchel's prompt and storage panel.
  - Conductor Road walks in the prefix, and every walk the Crown segment makes, run at the real 1x clock.

**Death diagnosis confirmed (run 13).** The trainer was killed by lightning while standing still during a creature fight on the conductor road. The walker cannot dodge there, because in a fight the stick drives the creature, not the trainer. Exact lines:

```
F11 STRIKE HIT during 'fight during conductor road to Keeper Ondra' at (-484.1492, 58.75578, 2521.029) damage=18.0 health_left=82.0/100.0
... four more identical hits at the same point, health 64 -> 46 -> 28 -> 10 ...
F11 TRAINER DEATH during 'fight during conductor road to Keeper Ondra' at (-484.1492, 58.75578, 2521.029); strikes so far {"damage":90.0,"deaths":1,"dodge_frames":0,"hits":5,"threats":0,"warnings":6}
F11 SATCHEL walking back to (-484.1492, 58.75578, 2521.029) from (-660.1802, 46.38821, 2320.671)
F11 SATCHEL recovered 4 stack(s); knife x1 axe x1 pickaxe x1
```

The respawn was at Rodline Refuge, and the satchel was then recovered by ordinary input. In run 12 the prefix saw 5 warnings, 275 dodge frames, 0 hits and 0 deaths. So walking plus dodging avoids strikes; standing still in a fight does not.

**Tuning question** (reported, not changed):
- **What happens:** a Stormwood strike targets a trainer's current position every 4–8 s, and the trainer stands still for a whole creature fight.
- **Result:** in one ordinary road fight, one strike point landed 6 of 6 warnings, at 18 damage each (cap 25% of 100). The trainer went 100 → 0 and died.
- **Why it matters:** "Human never fights" means the trainer has no way to react during a fight except to lose it.
- **Question:** should `stormwood_lightning.gd` skip a trainer whose creature is in combat, or should fights avoid exposed ground in Break? This is for COMBAT/SYSTEMS. The death also drops the tool satchel mid-route.

**Camp rest works.** Both runs rested at Still Grove Shelter over three ordinary nights and ended with every creature at full HP:
`RESTED the whole party at still_grove_shelter over 3 night(s) with ordinary bed and rest prompts`.

**Stopped (second failure of the same new step):** the call-out right after the rest.
- **Run 12:** `ordinary LB did not send out the fittest member before after resting at still_grove_shelter`.
- **Run 13:** the same line. That run pressed the recall button when no creature was out, and it made no difference.
- **Cause:** not known. Bedding a creature puts the follower away, and the director state after the last night is not in either log.
- **Next:** 80067c1ec makes this failure print the best, active and out creature, the ally body, the arbiter, the input owner, the pause, the fight and the clock. It has not been run. The next run should name the cause in one line.
- **Not reached:** the Alpha itself, so there are still no rested-party fight numbers.

| Run | Commit | Prefix | Strikes in prefix | Crown step | Wall |
|---|---|---|---|---|---|
| 12 | 544f87648 | PASS 1214.5 s, tools kept | 5 warnings, 0 hits, 0 deaths | rest OK; FAIL 23.4 s at the call-out | 20m57s |
| 13 | 2e7e43c9c | PASS 1252.8 s, tools recovered from satchel | 6 warnings, 6 hits, 1 death (in a fight) | rest OK; FAIL 23.9 s at the call-out | 21m34s |

SCRIPT ERROR count is 0 in both runs.

### Run 14 and the lightning ruling (commits 42f7b8dc7, 49d9ab27f)

- **Run 14** (ccbd1d4ba, 80067c1ec diagnostics).
  - **Prefix:** PASS in 1257.9 s. The same lightning death happened in a conductor-road fight (6 hits, 108 damage); the satchel was recovered and the tools kept.
  - **Rest:** Still Grove rest OK over 3 nights.
  - **Call-out failure, now with its cause:** `ordinary LB did not send out the fittest member before after resting at still_grove_shelter (best=terrapup active=bramblebun ally=bramblebun ally_body=true no_usable_ally=false arbiter_enabled=true input_owner=<none> paused=false fighting=false time_scale=1.0)`.
  - **Reading:** a creature was out and nothing blocked input, but the Crown helper's joypad-event LB taps changed nothing. The prefix Segment's action-event taps do send out its fittest member.
  - **Classification:** harness-side, but not proven to be harness-only. Whether a physical LB on a real pad works after a camp rest is not measured here.
  - **Fix** (49d9ab27f): the same action-event taps as the prefix, each LB press logged, recall if nobody is out, and one retry of the whole send-out.
- **Coordinator interim ruling** (pending the owner's decision): "While the local trainer is committed to a creature fight, storm strikes do not target the trainer's position. They may still land in the arena as telegraphed hazards the piloted creature can avoid. Strikes resume on the trainer when the fight ends."
  - **Change** (42f7b8dc7): `stormwood_surge.json` strike `spare_trainer_in_fight: true`, with a `_why` note.
  - **Aim:** host-side per peer in `stormwood_lightning.gd`. A strike chosen for a fighting trainer aims at that peer's piloted creature with the normal 1.2 s / 3 m telegraph, or is skipped if no creature is out. Impacts never damage a fighting trainer.
  - **Who counts as fighting:** the host's own combat manager or hosted trainer battle; any open encounter record listing the peer; or a registered Stormwood hosted fight.
  - **Limitation:** a guest's unshared local wild fight is not visible to the host.
  - **Tests:**
    - `test_stormwood_lightning_spare`, 5 tests and 16 assertions: a fighting trainer is never aimed at or hit and the creature is; targeting resumes when the record is done; only the fighting peer is exempt; the flag-false negative control aims at and hits the trainer.
    - `smoke_stormwood_lightning` 24/0 and `smoke_stormwood_lightning_cleanup` PASS.
  - **Not changed:** strikes still cannot damage a creature (none are wired to). The ruling's "hazards the creature can avoid" are presentation only.

### Runs 15 and 16: the Capacitor Alpha is cleared by a rested party

| Run | Commit | Prefix | Crown step | First failure |
|---|---|---|---|---|
| 15 | 49d9ab27f | PASS 1206.6 s; 8 warnings dodged, 0 hits | rest (3 nights), send-out OK on the retry, escorts, **Alpha CLEARED**; FAIL 966.4 s | `stormwood_harvest_conductor_run_099 never won the InteractionArbiter` |
| 16 | ce6d8367e | PASS 1249.5 s; 0 hits | rest, re-rest after a road-fight KO, **Alpha CLEARED**; FAIL 1072.5 s | SCRIPT ERROR in `_activate_exact` diagnostic: the Thunderwood prompt was a freed instance |

- **Alpha fight numbers, fully rested:**
  - Run 15: terrapup L46 won with 143.9/444 left against voltarach L40 511.8 HP. 108 player hits, 28 enemy hits, 19 player misses; 131 s.
  - Run 16: bramblebun L46 won with 82.7/351.5 left. 103 hits dealing 512.3 damage, 23 enemy hits dealing 268.8; 95.6 s.
  - No tuning stop applies.
- **LB presses.** In both runs, every other LB press left the active creature unchanged: the press landed while the director was redeploying after the previous switch. The retry covers it. Whether a real pad has the same dead press is not measured here.
- **Gather diagnosis (run 16).** The run died with a SCRIPT ERROR in the harness's own failure message, which called a method on the freed Thunderwood prompt.
  - Reading: the Interact press is answered by the equipped axe's swing, which gathers the node and frees it. The helper then saw no activation of the exact prompt.
  - This is a harness reading, not proven: the receipt was not checked before the run ended.
  - Fix, e47fa1758: a prompt freed by our own press returns to the caller, which checks the receipt and the yield. A prompt freed during the approach fails with its own message.
- **Run 15's lone strike hit.** It was logged during the "fight during Capacitor Grove road point" phase, right after that fight was lost. The phase label lags, so this was after the fight ended, not a breach of the spare rule.

### WO-F11-EARNED (branch `ralph/stormwood-f11-earned`, from main 08fcc2055): review fixes, then parked

- **Platform:** Linux container, Godot 4.7-stable, headless `--script`.
- **Input:** as above. The send-out now uses ordinary joypad LB/RB events at 1x/60 Hz, and satchel recovery uses pad right/A/B.
- **Starting save origin:** unchanged (the disclosed Cloudreach seam, then the disk save at the Stormwood arrival).
- **Route and command:** unchanged. `--through-aftermath --witness-dir=user://f11_witness`, then `--verify-reload`.

**Review findings fixed (each committed):**

| Finding | Commit | Result |
|---|---|---|
| Closed-Arch smoke: the flank Rootgate lines aimed short of the crossing line; the final z was judged instead of the max z; there was no reach check and no real negative control | 5f64f3b0f | 15 passed, 0 failed, 0 SCRIPT ERROR (`f11_earned/closed_arch_bypass.txt`). The run 1 reach check caught pair E approaches 1 and 7 stopping short of the kill-plane edge. The edge is now the point where the ground falls away past the player's 45° `floor_max_angle`. The controls (collider disabled, temporary bridge) both register a crossing. |
| LB send-out retry | 04b04368d | **Cause:** `_tap` held a button for two physics frames. Input is flushed once per process frame, and a slow headless Stormwood frame runs several physics steps (always at 8x/480 Hz, and even at 1x/60 Hz, which is where run 14 failed). So the press and release arrived in one flush. **Fix:** `_tap` also holds for two process frames. The send-out runs at 1x with joypad LB, logs each press, and reports a dead press instead of retrying. No LB binding bug is shown so far; this is **not yet exercised by a run**. |
| Harvest node freed during the approach | 04b04368d | The node's `tree_exiting` is now logged with its receipt, the tool, whether a swing is running, the distance, and the last swings and Interact presses. Cause not yet observed (no run reached the gathers). |
| `stormwood_field_safety.gd` freed satchel; `Button.pressed.emit()` / `panel.close()` | 04b04368d | A freed satchel or panel is never touched. Stacks are taken with pad right/A and the panel is closed with B. Satchel recoveries are counted. |
| Strike ruling wiring | 0cc759c34 | Four cases through the real `_process`/`_resolve` in `smoke_stormwood_lightning` (40 assertions, 0 failures). Removing the `_resolve` spare check fails 2; removing the aim spare fails 1. A comment now states that fight state is read at impact. |

- **Witness reporting:** the continuous smoke now ends with `F11 WITNESS SAFETY TOTAL trainer_deaths=… satchel_recoveries=…`, summed over every step.
- **Earned run (run 18, 04b04368d + 5f64f3b0f):**
  - **Stopped by me after ~12 min** on the coordinator's SNOWBALL re-order (F10#1 first), still inside the prefix. The last line was `DIAGNOSTIC: START Lantern Pools charged-window wait`, after Dace and `lower_rods_disabled`.
  - At that point: 0 SCRIPT ERROR, and no step result, death or satchel line. So trainer deaths and satchel recoveries are both 0 up to the stop; no final totals line printed.
  - Witness dir removed. No F11 clause was reached.
- **Run 19** (after F10#1; commits up to 57813ecd5):
  - **Prefix:** PASS in 1193.5 s. 10 warnings, 275 dodge frames, 0 hits, 0 deaths, 0 satchel recoveries; tools kept.
  - **Crown step:** rest over 3 nights. The send-out used ordinary joypad LB at 1x: **every press changed the active creature**, for example `LB press 1 (joypad button, 6 physics frames): active brooktail -> sparkit`, and presses 2–4 did the same. So the dead-press cause is confirmed and no LB binding bug is shown.
  - **Road KO:** a road fight knocked out terrapup. The party re-rested one night and the send-out worked again.
  - **Alpha:** both escorts won. `Capacitor Alpha outcome=won`: bramblebun L46 finished at 88.6/351.5 against voltarach L40 (511.8 HP), with 102 hits in 95.6 s.
  - **Harvest frees, now named:** every "freed during the approach" node was freed by the harness's own Interact press. The press starts the equipped tool's swing, and the swing resolves on the node at its impact frame. Example: `HARVEST NODE stormwood_harvest_conductor_run_099 left the tree ...: receipt=true equipped=axe swinging=true distance=0.37 recent=[... interact press winner=.../stormwood_harvest_conductor_run_099/Interactable; ... swing_started ...; ... swing_connected stormwood_harvest_conductor_run_099]`. Each gather committed its exact receipt and yield. This is not a game bug.
  - **Stop:** the thirty-minute Crown watchdog expired while the step was still gathering Crown glass (2 of the Crown nodes taken). Nothing was stuck. 0 SCRIPT ERROR. Total wall time 50m10s.
  - **Totals:** the final `F11 WITNESS SAFETY TOTAL trainer_deaths=0 satchel_recoveries=0 ...` covered the prefix only, because the watchdog path dropped the Crown step's counts.
  - **Fix** (the next commit): the Crown step gets a 60-minute capacity, and an unfinished step's strike and death counts are printed and summed.
- **Run 20** (60-minute Crown capacity):
  - **Prefix:** PASS in 1200.2 s. 1 warning, 0 hits, 0 deaths.
  - **Crown step:** rest, send-out, escorts, Alpha, and the four west-loop gathers.
  - **Stop:** the step left Rodline Refuge on a "fading" window and reached `stormwood_harvest_conductor_run_075` after the window closed: `did not commit its exact live yield/receipt: gained=0 expected=3`. Crown step FAIL at 1618.5 s.
  - **Strikes:** `F11 WITNESS STRIKES crown {"damage":18.0,"deaths":0,"dodge_frames":1048,"hits":1,"satchel_recoveries":0,...,"warnings":21}`.
  - **Totals:** `SAFETY TOTAL trainer_deaths=0 satchel_recoveries=0`. 0 SCRIPT ERROR.
  - **Harness fix** (next commit): leave for the seams only when the runtime's own open window at the seams is at least 150 s. This is the prefix's rule.
- **Run 21** (150 s window rule):
  - **Prefix:** PASS in 1190.5 s. 8 warnings, 0 hits, 0 deaths.
  - **Alpha:** the Alpha won on its second approach. The first ended `outcome=lost` with brooktail fainted and the Alpha at 239.7/511.8.
  - **Window rule works:** `WAITED ... { "phase": "break", "open_seconds": 179.8 }`, then 78.1 s left after seam 075 and 46.1 s after 074. All six sources were taken ("SIX sources yielded6 Crown glass/8 Thunderwood/6 vine") and both frames were crafted.
  - **Stop:** a road fight at the Still Grove road point was lost (sparkit fainted). The build then failed with `controller right stick could not face the Still Grove footing`. Crown step FAIL at 2069.6 s.
  - **Strikes:** `STRIKES crown {"damage":18.0,"deaths":0,"hits":1,"satchel_recoveries":0,"warnings":29}`. 0 SCRIPT ERROR.
  - **Harness fix** (89ffa24a1): the turn fights out any running fight first. If it still cannot turn, it reports the camera, fight, input-owner, pause, arbiter and clock state.
- **Next** (queue items 2–3): rerun the same command. The first things to read are the LB press lines after the Still Grove rest and any `HARVEST NODE … left the tree` line.

### Not produced

- The Dynamo Break, the Stormheart offer (solo accept at five), the Long Storm aftermath and the Spark were not reached in the earned run.
- The disk save, restart and load were not reached either. `--verify-reload` exists but has not run.
- The captures were not taken. `tools/capture_stormwood_f11_proof.gd` is committed and unrun. No render was started.

### Verdict (ACCEPTANCE §6.1 F11)

- "Dynamo and Stormheart resolve from the earned route": **NOT MET.** The earned route stops at the Capacitor Alpha, three segments before the Dynamo.
- "Long Storm aftermath, Spark/shrine … persist": **NOT MET by earned evidence.** The existing focused tests remain staged-only.
- "Eligible peers accept/refuse independently at space and capacity through disconnect/reload, without duplicated grants": **NOT MET.** The two-peer WIP is parked (see the sub-note below).

Seven other pickup/NPC overlaps remain (route_05, 07, 16, 18, 19 and pocket_203). The test lists them so the list can only shrink. They are an open finding.

### Batch-5 nit: Break faint prompt pause (commit 091f54cab)

- **Bug.** Recalling the fainted creature with nothing sent out ("none") left the host's Break paused forever.
- **Fix.** A participant now holds the pause only while its fainted creature is still the deployed one. A reload (`restore_progression_from_game`) ends every open prompt and publishes the resumed Break.
- **Tests.** `smoke_stormwood_dynamo_break_faint` now has 90/0 assertions, with one test per exit: creature, none, cancel by reload, cancel by wipe, disconnect, and timeout. `test_stormwood_dynamo` is 12/0.
- **Negative control.** The unfixed controller fails 3 of 90 (none, reload, disconnect).
- **Timeout.** COMBAT says "no timer in solo", so a lapsed faint toast is not a choice, and the test pins that the solo pause holds. The coordinator's list named timeout as an exit that must clear the pause. That conflicts with COMBAT and is left for an owner/coordinator decision rather than adding a timer.

### Sub-note: parked two-peer WIP (superseded by coordinator order)

`tests/smoke_net_stormwood_stormheart_offers.gd` and `tests/helpers/stormheart_peer_runner.gd` (commit 2ac6f9b23) are parked until the X05 two-peer proof command lands. The smoke is held out of CI discovery.

- **Last result:** two real ENet processes; the staged Dynamo frees the Stormheart; both characters are recorded as participants; the host's own offer, Yes and receipt pass.
- **Where it stops:** the guest's offer is refused because the host's proxy for the guest never leaves the Stormwood arrival point. Not yet diagnosed.
- **Consequence:** F11-B (two-peer, disconnect, capacity, no duplicate grants over the network) has no live proof from this lane.

## WO-F11-05: two-peer Stormheart proof at space and capacity (`ralph/stormwood-f11-two-peer`)

**Result: every scenario below is a rendered two-peer PASS.** Game code is unchanged from `origin/main` 10b635d38. Every commit on this branch adds only scenario JSON under `tools/net/proof_scenarios/stormwood_f*` and evidence under `ralph/reports/STORMWOOD-PROGRESS/two_peer/`. No game fix was needed. `tools/net/proof_steps.gd` (lane X05) was not edited.

- **Platform:** Linux container, Godot 4.7-stable. Two real peer processes over loopback ENet, rendered with `--render` (xvfb, opengl3, 960x540 captures). This is local evidence, not internet or Steam acceptance.
- **Tool:** lane X05's `tools/net/run_two_peer_proof.sh` + `tools/net/proof_steps.gd` + `tests/smoke_net_proof_two_peer.gd`.
- **Command, per scenario `<S>`:** `tools/net/run_two_peer_proof.sh tools/net/proof_scenarios/<S>.json --render --out=ralph/reports/STORMWOOD-PROGRESS/two_peer/<S>`. The runs were serial, one render at a time.
- **Starting saves:**
  - The host always loads the named save `tools/net/proof_saves/host_meadows_stormwood_route_open/`: Meadows, Stormwood route open, party empty.
  - The guest is a fresh trainer (`boot world`).
  - Both enter Stormwood through `Game.enter_realm`.
- **Disclosed setup:**
  - x05's `stormheart_fixture` stands in for playing the Dynamo fight. It sets both peers as Dynamo contributors and commits Marrow's defeat flag through the ledger.
  - Capacity scenarios fill one belt with five through `party_grant` (the game's `party_seam.add`). No named five-creature save exists.
  - The Waterward scenario uses `teleport` to stand beside the view and gate prompts.
  - The F09 scenario uses `storage_grant` for Stormglass and `explore_at` to stand at each arch.
  - Everything from the offer on is the game's own code, driven by ordinary presses: the Yes/No dialogue, the Team-tab release ceremony (`ui_down` / `ui_accept` / `menu_cancel`), the prompts and the saves.
- **Input:** the harness injects the physical joypad/key binding plus the action (`peer_runner.gd` `_press_edge`), guarded by `input_contexts.json`.
- **Evidence kept:** `PROOF.md`, 256-colour PNGs, gzipped `worlds/` and `characters/` receipts, `NET-SUMMARY.md`, `NET_RUN.json` and `LOG-EXCERPTS.txt` (every SCRIPT ERROR with context and every `[downed]` line; from the Arch run on). Raw logs and `saves/` slot copies were deleted for disk.

| Scenario (`<S>`) | Evidence commit | Run id | Verdict | SCRIPT ERROR |
|---|---|---|---|---|
| `stormwood_f11_mirror_host_refuses_guest_accepts`: space both sides, host No, guest Yes, double press | ad9806d8a | net-20260925T191033Z-20478 | PASS | 0 |
| `stormwood_f11_mirror_clean_health`: the same mirror, asserting trainers up (DownedState `local_downed=false`, none expired or revived; the host as authority reports `downed_peers=[]`) on arrival, just before each answer and right after each answer | (the commit that adds this section) | net-20260925T203118Z-3042 | PASS (100/100 both, no `[downed]` line) | 0 |
| `stormwood_f11_capacity_guest_full_releases_belt`: guest at five says Yes and releases bramblebun; host (space) Yes | b0f610b1b | net-20260925T191830Z-22102 | PASS | 0 |
| `stormwood_f11_capacity_host_full_lets_stormheart_go`: host at five says Yes, lets the Stormheart go (a refusal); guest (space) Yes | 8f0e62409 | net-20260925T192701Z-23676 | PASS | 1 (guest; text lost, see below) |
| `…_host_full_lets_stormheart_go_rerun`: same steps | 14416a5c5 | net-20260925T202421Z-1718 | PASS | 0 |
| `stormwood_f09_arch_gates_two_peer_reload`: pair A relit by both peers, B dark, C gated, save/reload | 481676ff1 | net-20260925T194551Z-27097 | PASS | 0 |
| `stormwood_f11_disconnect_guest_rejoins_answers_once`: two drop/rejoins, save/reload, replays | 47d2a4a71 | net-20260925T200502Z-30959 | PASS | 0 |
| `stormwood_f11_waterward_gate_two_peer_reload`: host charts the sky, guest opens the gate once, save/reload | 9faec484d | net-20260925T201217Z-32081 | PASS | 1 (identified, shared code) |

### What the runs show

- **Space.** In the x05 original and in both mirror runs, each peer keeps its own answer on both sides. Each peer's world and character receipts carry its own accept or refuse, and the host's saved world holds each answer exactly once. The pre-offer saves hold no answer (non-vacuous baseline).
- **Capacity.**
  - A sixth `party_seam.add` is refused.
  - A Yes at five does not settle by itself. `stormwood_ending.gd` `_begin_local_ceremony` puts the Stormheart in `Game.pending_catch`. The Team tab opens on the release ceremony ("You caught the Stormheart. The belt holds five, and one of the six goes free."; `input_context` `menu_creatures`). While the choice is open nothing is added and nothing is recorded.
  - Guest run: the guest lets bramblebun go ("Let Bramblebun go? … the Stormheart takes it"). The belt becomes terrapup, ripplet, galewisp, mudsnout, fulgocobra. The world records the guest's acceptance.
  - Host run: the host lets the newcomer go ("Let the Stormheart go? … your five keep their holders"). Its five are unchanged. The world and the host's character record a refusal, "exactly as letting the newcomer go at five".
  - In both runs the other peer's own offer is still its own, and it keeps one.
- **No duplicate grant.** A second press on an answered prompt finds it dark ("Answer the freed Stormheart", `enabled=false`) on the host and on the guest. This holds in the mirror run, the capacity runs, after reconnects, and after `save_reload_here`. Party lists stay at exactly one fulgocobra per accepting peer.
- **Disconnect/reload, partial.**
  - A dropped client lands on the title (`session.gd` `_on_server_disconnected` → `_return_to_title`).
  - It rejoins through `production_join` (title `_join_via` → JoinDriver) as the same character. Its owed offer is still its own. It says Yes once.
  - A second drop and rejoin, then `save_reload_here` on both peers (host `autosave_here` + `load_slot`; guest character save + apply), grant nothing further.
  - **Both drops happen while the offer is owed but not yet opened.** No proof step opens the offer and stops before Yes/No. The step needed is `stormheart_open_offer` in `tools/net/proof_steps.gd`: walk up, press the prompt, wait for the offer panel, return without answering. It is left to lane X05.
- **Waterward gate.**
  - The host's view press sets `stormwood:waterward_revealed` and the one-time `realm_key_water` on both peers.
  - The guest reads the 3-line `stormwood_waterward_aftermath` conversation, then presses the gate once. The host commits the key consumption and `realm_gate_water_unlocked` together.
  - The frame reads "The Waterward gate is open." / "Enter Tidewake".
  - After reload, both peers keep the open gate and the charted sky. The host's saved world lacks the quoted `"realm_key_water"` flag.
  - A second gate press is not made, because it enters Tidewake.
- **F09 gates.**
  - The host and the guest each relight one arch of pair A through its "Relight … · 3 Stormglass" prompt, and each pays its own Stormglass.
  - Stepping into Ashfoot carries the host to its twin (z 500 → 1436.5). Dark pair B carries nobody (z 1350 stays). Pair C, behind the closed Rootgate, is unavailable (z 2260 stays).
  - After reload the lit flags hold on both peers, and the guest travels the pair back (→ z 503.5). The host's saved world has A lit and B/C unlit, and lacks `stormwood:rootgate_released`.
  - The closed-pair rows are recorded positions, not numeric assertions.

### Findings (not fixed here: shared files)

- **Freed `winning_provider`.** `scripts/world/interaction_arbiter.gd` `_recompute()` returns early while the arbiter is disabled (lines 384-386, for example while a dialogue holds input). A provider freed meanwhile stays cached in `_winning_provider`, and `winning_provider()` (line 305) returns it unvalidated.
  - It surfaced as `SCRIPT ERROR: Trying to cast a freed object` at `scripts/player/conversation_camera.gd:175` (`_arbiter.call("winning_provider") as Node3D`). That happens when the guest's Stormheart release conversation starts (`stormwood_ending.gd:152` → `:732` → `dialogue_panel.gd:197/367`). The effect is that the camera does not push in for that conversation.
  - It also crashed the `downed` probe (`tools/net/peer_runner.gd:5939`).
  - It is intermittent. It is the likely source of the first host-full run's lost SCRIPT ERROR, which did not recur in the rerun.
  - Minimal fix, for the owner: validate the provider before the cast, or clear it on the disabled path.
- **`stormheart_answer` stand-offsets (X05 step).** On an already-dark prompt the step tries all six stand-offsets and leaves the trainer at the last one, below or at the edge of the core platform. The trainer then falls and goes down (the 0/100 HUD frames and `[downed]` lines after double-press rows).
  - The first mirror run's guest was already at 0/100 in its arrival frame, before any answer, so that one is a separate, unexplained arrival fall. The clean-health mirror rerun has no double press. It asserts both trainers up around every answer and ends at 100/100 on both peers.
  - In the clean rerun the guest's own `downed` probe is taken on arrival and after the answers, not just before. During its release conversation the freed-`winning_provider` fault above crashes that probe (first attempt, not committed), so the pre-answer check reads the host's authority view (`downed_peers=[]`).

### Limitations

- The Dynamo fight is not played in these runs (the fixture stands in for it). The five-creature belts come from `party_grant`. The platform walk, the arch roads and the realm arrival are placement or teleport.
- Disconnect is not tested with the offer panel open (see the missing `stormheart_open_offer` step above).
- Process kill or relaunch is not tested (the process stays alive).
- The host is not disconnected.
- This is loopback ENet only.
- The Rootgate release (opening pair C) is not shown.
- The first host-full run's SCRIPT ERROR text was not retained.
## WO-F10-09: two-peer proof of each side chain's persistent receipts (`ralph/stormwood-f11-earned`)

**Status: PASS.** Rendered two-process run 7 (scenario at 5bcf224ca, game fixes 769effdff and b10a21419): 250 steps, verdict PASS, exit 0, 0 SCRIPT ERROR in either peer log.

- **Command:** `tools/net/run_two_peer_proof.sh tools/net/proof_scenarios/stormwood_f10_side_chain_receipts.json --render`
- **Evidence:** `two_peer/stormwood_f10_side_chain_receipts/`: PROOF.md, frames per peer, the gzipped world/character saves at `before` / `complete` / `after`, LOG-EXCERPTS.txt, NET-SUMMARY.md and NET_RUN.json.
- **Platform:** Linux container, Godot 4.7-stable, two real ENet processes on loopback, opengl3 under xvfb. This is local evidence, not internet or Steam acceptance.
- **Starting save origin:**
  - Host: `tools/net/proof_saves/host_meadows_stormwood_route_open`.
  - Guest: a fresh trainer.
  - Both entered Stormwood with `enter_realm`.
- **Input:** ordinary Interact presses on the production prompts and NPC conversations, plus `explore_at` debug travel to each spot.

**How each chain was proved.** For every chain, the final step and each earlier step that has its own runtime were played through the production path. Every completion flag reached both peers. Both peers then ran `save_reload_here`, and every completion held on both peers and in the saved files.

| Chain | Who | Played through production | Fixtured (disclosed) | Repeat attempt |
|---|---|---|---|---|
| Dark Arches | host | "Relight" on c_rodline, c_lantern, d_hall and d_giant (the inspection count and 12 Stormglass taken). The arch runtime emits step 2. Hesk's report completes the chain. | ashfoot_arch_relit and rootgate_released (main-route facts); 12 Stormglass granted | Hesk answers with his ordinary lines, not the report |
| Pim's Parcels | guest (client path); host | Guest: Pim's offer, the Marl, Oswin and Lio deliveries, then Pim's return, which completes the chain and pays the guest 2 Small Potions through `reward_grant`. Host: Pim's thanks pays the host once. | lantern_pools_linked | Guest: thanks with the potions still at 2. Host: ordinary lines with the potions still at 2. |
| What the Crown Remembers | host | Three record prompts, then Wen's records conversation | crown_reached, crown guardian cleared, engine_truth_learned; standing on the Crown by debug travel | Wen answers with her ordinary lines |
| Glass for Bryn | guest | Bryn's offer, then Bryn's request, then the host-owned delivery (takes the guest's 3 Stormglass and 2 Conductor Vine), then the inspect prompt | bryn_met; the materials granted | Bryn's thanks. Carrying 3 Stormglass and 2 Vine again, Bryn does not ask again and nothing is taken. |
| Raise a Road | host | Footing prompts for Verge Road and Hollows Road, then two Stormglass Arches built (`build_place`). The runtime emits step 2. The road is walked both ways, which sets both departed flags and step 3. Ondra's report completes the chain. | arch_recipe_known; the arches built with Free Build (materials not charged) | Ondra answers with an ordinary line |
| Deepwood Circuit | host | Rook's offer; the chapter runtime credits three circuit wins; Rook's return | lantern_hollow_reached; three circuit trainers' defeat facts (lena_giant, orin_blackwater, tavi_rodline) stand in for three hosted fights | Rook answers with his ordinary lines |

- **Glass for Bryn runtime:** it is on main and complete. All three steps ran through it here.
- **Saved-file checks** (`check_saved`):
  - **Baseline** (non-vacuous): the host's pre-run world holds all five prerequisite facts and no side-chain flag or rate. The guest's pre-run character holds no rate.
  - **After the reload:**
    - The host world holds all six completion flags, the `stormwood_pims_parcels` journal and both character ids.
    - Both characters hold `potion_small` and `stormwood:pims_parcels_reward_received`.

**Game bugs the run found (Stormwood-owned, fixed, each with a regression):**

1. **Arch travel TO the Verge Road footing was always refused** ("Clear the far footing before travelling"; runs 1 and 4).
   - **Cause:** the arrival point sat at terrain height, inside the footing's level slab on sloping ground.
   - **Fix** (769effdff): `stormwood_arch_runtime.gd` lands the traveller on the floor under the point.
   - **Regression:** `tests/smoke_stormwood_road_arrival.gd` is 9/0; against the old code it fails that leg. Its negative control shows the old capsule overlapping `Footing_verge_road`.
2. **Deepwood Circuit wins were never credited** (run 4).
   - **Symptom:** `SCRIPT ERROR: Trying to assign value of type 'Nil' to a variable of type 'Dictionary'` at `stormwood_chapter.gd` `_credit_existing_circuit_wins`, on both peers.
   - **Cause:** the chapter read `authored_specs` from the EncounterDirector, which has none; the cast lives on StormwoodTrainers.
   - **Fix:** b10a21419.
   - **Regression:** the wiring smoke's stub no longer hides the bug. It fails 5 checks against the old code and passes with the fix. `test_stormwood_deepwood_circuit` is 19/0.

**Harness and infrastructure notes:**

- **Slow replication after a screenshot:** in rendered runs 2 and 3, the guest's first replicated fact after the first rendered screenshot arrived later than 1200 physics frames. A diagnostic run measured it at 783 frames. The scenario now waits 3600.
- **Repeat press at the Bryn inspect spot:** after completion the inspect prompt is disabled, and the press there reaches the new care point's "Rest at the rod crews' shelter" offer instead.

**Findings for owners (not fixed here):**

- **Shared file:** `scripts/world/night_rest.gd` mounts `/root/Game/Session/SleepVote` lazily, only in a process that rests.
  - The guest's rest press (above) sent its vote to a host that had never rested. The host logged `ERROR: Node not found: "Game/Session/SleepVote"` and `Invalid packet received` (LOG-EXCERPTS, peer-0 lines 296–359).
  - A guest's rest vote can never reach a host that has not rested first.
- **Harness gap:** there is no proof step that presses until a dialogue closes. Conversations are read with an exact press count taken from `data/dialogue/stormwood.json`.
- **Presentation** (Stormwood data, not fixed):
  - Rook stands inside the d_giant arch opening, and a large wild creature perches on top of it (`06_host_rook_return`, `07_after_reload_and_repeats`).
  - Hesk's dialogue portrait is a young villager, and Wen's is an old man (`01_host_hesk_report`, `03_host_wen_records`).
- **Side effect of repeat visits:** finishing an NPC's ordinary conversation emits that NPC's ordinary main-story line event (`stormwood_chapter.gd` `DIALOGUE_EVENTS`).
- **Trainer deaths and satchel recoveries:** none. Both trainers ended at 100/100 with no satchel (`downed` probe, step 244).

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
