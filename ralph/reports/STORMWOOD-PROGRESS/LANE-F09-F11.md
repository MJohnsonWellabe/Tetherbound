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
