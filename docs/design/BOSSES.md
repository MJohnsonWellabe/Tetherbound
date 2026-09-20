# Tetherbound Named Encounters and Boss Contract

**Status:** Design and source catalogue. “Current” rows reproduce baseline data at `b8eda8858`. Mechanics marked **target** are acceptance requirements or proposed tuning and are not claims that runtime code already implements them.

## 1. Combat language shared by named fights

Combat is real-time and creature-piloted. The player directly moves the active creature and uses:

- **RT:** quick attack.
- **LT:** charged attack.
- **Y:** geometry-changing skill learned at level 4. This is a required target and is not fully built across the roster.
- **A:** 3 m burst step over 0.2 s, no invulnerability frames.
- Mid-fight switching and fleeing where the encounter permits them.

Shared baseline:

| Rule | Baseline |
|---|---:|
| Poise | 40 maximum |
| Poise regeneration | 20/s after 2 s without poise damage |
| Stagger | 0.6 s; one critical opening at ×1.5 |
| Wind meter | 100 maximum |
| Wind costs | quick 12, charged 35, skill 24, burst 30 |
| Wind regeneration | 18/s after 0.6 s delay |
| Type graph | 1.25 advantage / 0.80 disadvantage |
| Ordinary boss telegraph floor | 0.8 s |
| Heavy/signature telegraph floor | 1.1 s |
| Entry damage limit | no single hit ≥50% of expected entry max HP |

An attack may be quicker than 0.8 s only when the same creature and move were already taught safely and a non-time cue gives at least equivalent notice. No encounter uses an unavoidable combo, off-camera strike, spawn hit or recovery-cancelling chain. **Target co-op scaling:** shared boss HP is the solo value plus **65% per additional admitted participant**; damage per hit remains at the solo value and within the solo readability limit. Adds, simultaneous lanes or shorter recovery may change only where a fight specifies them and must preserve a safe answer.

The type chart remains the eight-type source graph with 1.25/0.80 magnitudes. Named fights may use better composition and authored moves, but they do not secretly replace the global graph.

## 2. What makes a named fight

Every named encounter must answer three sentences:

1. **Look:** what the player sees or hears before committing.
2. **Do:** what action or team decision differs from an ordinary fight.
3. **Change:** what route, reward, person or world state changes afterward.

A name, larger scale and more HP do not satisfy this contract. Named fights use the fewest phases their idea needs. Trainer ladders normally remain sequential team fights; they do not acquire artificial boss phases.

Reusable authored behavior profiles are starting tuning:

| Profile | Target behavior |
|---|---|
| WALL | telegraph .85 s, recovery 1.1 s, power ×1.5, chase 3.4, reposition 2.5; holds ground and gives a long punish window |
| CHARGER | preferred range 4.5 m, lunge 7 m, telegraph .6 s, recovery .9 s, cooldown 1.6 s, power ×1.3; distance is part of the cue |
| DIVER | telegraph .4 s only with long positional cue, lunge 5.5 m, reposition 7 m/1.6 s, cooldown .9 s, power ×.9 |
| CURRENT | cooldown .7 s, recovery .55 s, reposition .5 s/2 m, power ×.8; sustained pressure rather than burst damage |
| ACE | telegraph 1.0 s, recovery 1.2 s, lunge 6 m, cooldown 1.8 s, first delay 2.5 s, power ×1.8 |

These profile values came from the recovered Gate 3 contract. Per-body combat overrides exist in some Meadows data, but each consumer must be source-verified before the row is called built.

### 2.1 Deterministic target expansion for every ordinary trainer

Every trainer row in §§5–8 uses this rule unless §4 gives that encounter a major specification. This is a **target recipe**, not a claim that the current trainer controller consumes `CREATURES.md` roles or Y skills. It closes the old meaning of “baseline”: baseline means “no current per-encounter override,” while the target still has a complete behavior recipe.

1. Keep the catalogue team and send-out order exactly as written. Never sort by role, level or type.
2. Read each species' role and Y family from `docs/design/CREATURES.md` §§4–6. Normalize the role to the first matching profile in this fixed priority: **WALL** for `anchor`, `tank`, `wall`, `bulwark`, `guardian`, `counter` or `interceptor`; **CHARGER** for `bruiser`, `breaker`, `gap-closer` or `punisher`; **DIVER** for `diver`, `dive`, `duelist`, `ambusher`, `skirmisher`, `harrier`, `flanker`, `pursuit`, `hunter`, `scout`, `runner`, `spotter` or `disruptor`; **CURRENT** for `controller`, `current`, `ranged`, `screen`, `zone`, `trapper`, `sweeper`, `artillery`, `support`, `decoy` or `kiter`. The ordered match resolves compound roles: `ambush counterattacker` is WALL, `defensive counter bruiser` is WALL and `reactive current skirmisher` is DIVER. An unmatched role is a data-validation failure; it cannot silently fall back to generic AI. Ordinary trainers never receive ACE merely because they are last in a list.
3. Apply the numeric profile in §2, then clamp its tell/recovery upward to the chapter teaching floor: Meadows before South Bridge **1.0/.9 s**; South Bridge onward **.9/.75 s**; Cloudreach **.85/.70 s**; Stormwood and Tidewake **.8/.6 s**. A heavy or charged signature still uses at least **1.1 s** tell. Profile power, lunge, chase, reposition and cooldown remain unchanged.
4. Skill access escalates without inventing moves. Before South Bridge, trainer creatures use quick and charged only. From South Bridge through the Meadows finale, only the last send-out may use its level-4 Y. In Cloudreach, the second and later send-outs may use Y. In Stormwood and Tidewake, every send-out may use Y, with the first Y delayed **4.0 s** and **2.5 s** respectively. Y costs **24 Wind**, has a **10 s** cooldown and uses the family in `CREATURES.md`: Snare checks a target at 3–5 m that moved at least 1 m in the previous .5 s; Slow field checks a target within 6 m and no same-owner field already active; Shove checks a target within 4 m and a 70° facing cone; Dash checks an unobstructed swept lane to a target 3–6 m away; Veil checks an observed player charged wind-up for .25 s. When its condition and cost are met, Y has first priority. Otherwise WALL uses quick at ≤3 m, charged at >3–6 m and chases beyond 6 m; CHARGER uses quick at ≤3 m, charged/lunge at >3–7 m with a clear swept lane and approaches otherwise; DIVER uses charged after completing its reposition when the target is >3–6 m, quick at ≤3 m and repositions otherwise; CURRENT uses charged on every third non-Y attack when the target is within 8 m with line of sight, quick on the other two and repositions when range or line of sight fails. Attack cooldown begins after recovery. Major specifications override this selector where they name a sequence.
5. Team, order and already-authored terrain provide encounter identity. Profile movement uses existing cover, slope, waterline and wind lanes for spacing and line of sight. An ordinary trainer cannot create a custom phase, synchronize or strengthen an environmental hazard, add environmental damage, or turn a cliff, deep-water edge or lightning lane into a forced hit. Admission and reposition paths must always retain a collision-tested safe answer.

This rule makes every ordinary catalogue row implementable without a designer choosing behavior later. Major rows retain the same source team/order but use their explicit §4 timing, phases and payoff where those differ.

## 3. Authority, failure and persistence

- The host owns trainer sequence, boss HP, phase, hazards, participants, rewards and shared flags.
- Clients submit input/intent. They do not submit damage, boss HP, phase completion or a progression flag.
- One-time rewards are journaled before delivery. Reconnect resumes or acknowledges the same transaction.
- A loss returns the player to the named recovery point and resets only the current attempt. Previously opened routes, collected materials and earlier chapter flags remain.
- Joining an active shared fight receives the current host snapshot as an observer. It watches the currently admitted enemy and becomes an admitted, reward-eligible participant only on the **next enemy send-out**, never at a phase boundary inside the current enemy. Late join after victory reconstructs aftermath and cannot replay rewards. Leaving and rejoining cannot increase boss HP twice or enter a reward ledger retroactively.
- Trainer-owned creatures cannot be caught. Aquaryn and the source-marked named wilds may resolve by catch or defeat. A story creature is offered only where its chapter explicitly frees it into a voluntary ceremony; Cloudreach grants Wings and a key but no creature adoption or offer.

## 4. Major encounter specifications

### 4.1 Burrow Warrens Guardian — Meadows, L14

**Current source:** required guardian in `data/config/burrow_warrens.json`; the recovered Gate 3 contract assigns WALL and Earth Fist. The vault door and reward branch are landed.

**Look.** A 1.7-scale Burrowback controls the den. A warm seam and under-door spill keep the shut vault visible during the fight.

**Do.** Earth Fist uses a 6.5 m lunge and 72° cone. Target timing is 1.1 s ground/foreleg tell, 0.8 s active commitment and 1.2 s recovery. Ordinary pressure follows WALL: .85 s tell and 1.1 s recovery. Step laterally or burst through the cone edge, break poise during recovery and avoid trading into the armored front.

**Change/reward.** Victory opens the physical vault and awards the required Rootstone/Heartstone progression, two Greater Orbs and useful equipment/material value. The Elder Trailpup branch becomes reachable.

**Failure.** Return to the nearest quarry/warrens recovery point; guardian and door reset, collected external resources remain.

### 4.2 Captain Vance and the Relay — Meadows, 11/11/12

**Current team:** Galecrest11, Duskhush11, Tuskroot12. Tuskroot is the ace and CHARGER target.

**Look.** Relay machinery, captive and occupied crossing establish stakes before the challenge.

**Do.** Galecrest tests air spacing, Duskhush tests visibility/position and Tuskroot closes 7 m after a .8 s minimum full-body charge cue, then recovers .9 s. The player must switch rather than solve all three with one type.

**Change/reward.** The captive is freed, the relay is disabled and Old Mill Crossing physically reopens. The answered owner decision is built: over 12 seconds, the relay's live drain skin fades and vegetation returns only inside `relay_core`, `relay_yard` and `relay_approach`. The quarry and all other drained stations remain held until the chapter ending, and baked terrain colour/control-map discoloration cannot heal at runtime.

### 4.3 Sigil captains — Meadows

These are three distinct trainer exams, not one three-phase boss.

- **Oreth:** Mosshell13 WALL → Trailpup14 baseline → Brooktail15 CURRENT. Tests patience, a neutral reset and then sustained pressure. Awards first Sigil.
- **Halder:** Duskhush13 baseline → Tuskroot14 CHARGER → Meadowhart15 CURRENT. Tests range control and sustained pressure across an exposed field. Awards second Sigil.
- **Vess:** Trailpup14 baseline → Duskhush15 baseline → Galecrest16 DIVER. The route supplies the endurance test and the ace supplies the reposition read. Awards third Sigil.

Road order is Oreth → Halder → Vess. The three saved Sigils open the Hall approach. Defeat returns to the last regional camp and does not clear any captain.

### 4.4 Keeper Hald — Meadows, 18/19/19

**Current team:** Galecrest18 DIVER, Burrowback19 baseline, Mosshell19 WALL.

This is the mandatory kit check before the Warden. Galecrest teaches movement, the middle round provides a reset and Mosshell tests patient punishment. Hald's defeat opens the chamber approach. A physical bed after him allows preparation; it is not available at the exterior waystop.

### 4.5 Warden Aldis — Meadows, 18/18/19/19/20

**Current implementation:** an ordinary host-owned sequential trainer record, not a bespoke boss script. Its five authored combat override blocks and TM quicks are in band data; runtime consumption must remain verified.

| Order | Creature | Role and timing |
|---:|---|---|
| 1 | Burrowback18 | WALL; .85 s tell, 1.1 s recovery; `rock_throw` |
| 2 | Galecrest18 | DIVER; positional entry plus .4 s strike tell, 5.5 m lunge, 1.6 s reposition; `wind_blade` |
| 3 | Brooktail19 | CURRENT; .7 s cooldown/.55 s recovery; `aqua_shot` |
| 4 | Meadowhart19 | CHARGER; 7 m lunge, .8 s visible charge floor, .9 s recovery; `rock_throw` |
| 5 | Tuskroot20 | ACE/Earth Fist; 2.5 s first delay, 1.1 s signature tell, 6.5 m/72° cone, 1.2 s recovery; `rock_throw` |

**Look.** The duty board shows the garrison without spoiling Chamber Five. The arena stays clear, the Warden uses the highest rank treatment and the machine is visible only when the story permits it.

**Do.** The sequence repeats four learned behavior shapes before the Earth Fist final exam. Warden-only TM quicks make the first exchange stronger without adding HP sponge scaling.

**Change/reward.** `defeated_warden` opens the legendary chamber, then the player disables the tether, frees the Veridian Stag and resolves the voluntary ceremony. Region healing, Heart, Cloudreach key and crossing follow.

**Failure.** Return to the post-Hald bed/recovery point. The Warden roster resets; earlier gauntlet victories and rest state remain. In co-op the host owns send-out order and reward; all present participants share world victory, while the one legendary offer uses stable-recipient ownership.

### 4.6 Captain Veyra, Eye of the Anchor — Cloudreach, 31/32/34

**Current team:** Aeriex31, Cloudfang32, Galecrest34. **Current arena data:** radius 36 m, three rotating wind lanes and three lee pockets.

**Stage A — Crosswind Command.** This is Veyra's normal three-creature trainer sequence. Wind lanes rotate at 8°/s on a 6 s cycle, telegraph **1.4 s**, push up to 7 m/s and leave **1.5 s** recovery windows. Aeriex controls lanes, Cloudfang pursues, Galecrest is the switching ace.

**Stage B — Anchor Overload.** Begins immediately after the second of Veyra's three creatures is defeated, when one remains. Relay arc rotates −14°/s on a 5 s cycle, telegraphs **1.6 s**, pushes up to 10 m/s and leaves **1.4 s** recovery. Lee pockets remain safe and no arc may overlap every pocket.

**Stage C — Break the Eye.** Begins after Veyra's team falls. The player pilots a creature through the same readable wind language and disables west, crown and east relays within 3.8 m. This is movement interaction, not another HP bar. Recovery currents inside 53 m prevent an invisible instant-death fall; a full failure returns to Summit Bivouac.

**Change/reward.** The extraction network stops, winds restore, settlements reconnect and Aila grants Wings, the Stormwood key and overlook. Host snapshots own lanes/relays; each relay flag and final reward are idempotent.

### 4.7 Captain Marrow and the Dynamo — Stormwood, 42/43/43/44/44

**Current team:** Tanglevolt42, Stormraven43, Stormbrush43, Sparkit44, Voltarach44. **Current implementation:** mounted and focused-tested.

**Bank Cycle.** Four banks around a 42 m arena charge **6.0 s**, fire **0.8 s**, recover **2.0 s**. Three grounded plates of 3.5 m radius are safe. The captain's sequential team fights within the lanes.

**Overload.** Starts when two of five creatures remain. Charge shortens to **3.0 s**, fire remains **0.8 s**, recovery becomes **1.0 s**. A bank strike is capped at **25% max HP** and applies Static for 8 s; it cannot combine with a creature attack into an unavoidable spawn hit.

**Break the Core — current implementation.** Begins after the fifth creature falls. Human locomotion pauses and the deployed companion is piloted to four conduits. Each bank serial is **6.0 s charge + .8 s fire + .2 s recovery = 7.0 s**, while all four banks make the full **28.0 s** cycle; conduit reach is 3.2 m. Current code clears partial conduit progress when that full cycle increments. The former phrase “within one cycle” was ambiguous and made a solo reading of a single 7 s bank serial impossible on paper.

**Break the Core — selected target revision.** A visible **30.0 s shared conduit countdown** starts when Break begins and spans bank serials. Land four host-validated quick attacks on **four distinct conduits** before it expires; duplicate strikes do not advance the count, and the HUD shows `0/4` through `4/4` beside the countdown. At expiry with fewer than four, clear only the partial conduit set and restart Break with a fresh 30.0 s window. Do not reset the captain win/approach state and do not advance world progress. Break repeats only on timeout; success records `captain_marrow_dynamo_core` once and opens containment. A full-party faint restores everyone at Ember Bivouac and resets only the Break attempt.

This is a deliberate solo-feasibility revision while preserving the current banks and four-conduit idea. Acceptance must independently prove a collision-valid route of **≤120 m** through all four distinct conduits. At the common **5.6 m/s** move speed, 120 m takes at most **21.43 s**; four quick attacks at **.18 s wind-up + .22 s recovery = .40 s each** add **1.60 s**, for an analytic ceiling of **23.03 s** and **6.97 s** margin. The live controller test must include collision, turns and active bank lanes and still finish within 30.0 s; the arithmetic alone is not acceptance.

**Change/reward.** The fourth conduit records Marrow victory and opens containment. Stormheart offers companionship; Spark and its shrine follow, then the Water key and Waterward view.

**Failure.** A roster loss returns contributors to Ember Bivouac and resets that roster attempt. Break timeout repeats Break in place as specified above; a full-party faint during Break returns to the Bivouac. Chapter approach flags remain. Reconnect resumes the persisted roster/Break state. Host validates body, move, action sequence, cooldown, range and facing.

### 4.8 Aquaryn — Tidewake, L49

**Current implementation:** host-owned wild alpha; catch or defeat shares one resolution.

| Phase | Threshold | Attack | Telegraph / recovery / cooldown | Shape |
|---|---:|---|---|---|
| Shore Crest | 100% | tail sweep | 1.25 / 2.4 / 4.0 s | 8 m, 140°, ×1.0 |
| Tidal Run | <70% | wake sweep | 1.5 / 3.0 / 4.5 s | 9 m, 100°, ×1.05; visible surface route every 12 s |
| Broken Wake | <35% | frontal jet | 1.7 / 2.8 / 4.0 s | 16 m, 28°, ×1.15; route every 9 s |

Aquaryn moves 4.5 m/s on shore and 8 m/s on its visible surface channel. Submergence is presentation only; the target never becomes unreachable or demands diving. Engage radius is 32 m, abandon radius 100 m with 8 s grace.

**Change/reward.** Defeat or legal host-validated catch sets `water_aquaryn_resolved` and grants eligible stable characters the durable personal flag `water_swim_stone_earned`; the Swim Stone is not an inventory item and is never consumed. On catch, the host journals the stable character ID and exact Aquaryn creature before publishing the shared outcome. If the catcher already has five creatures, the game refuses the catch **before aim/throw and before any orb debit**. The player may cancel or leave, release one creature outside the encounter, and begin a fresh unresolved attempt; Aquaryn is never staged as a temporary sixth. Defeat still resolves progression and grants the personal swim flag. Replacement/release inside a delivery ceremony applies only to voluntary freed-legendaries, not this normal wild catch. Later valid characters attune beside Iona within 5 m; the shared alpha does not respawn for them. Catching Aquaryn is optional and cannot be a progression deadlock.

### 4.9 Tidecoil — Tidewake, L54

**Current source:** `water_deep_watch_tidecoil`, optional named encounter at Deep Watch; never random and never a mount. A bespoke multi-phase controller is not currently evidenced.

**Target fight.** This has two intensity bands on the same CURRENT-style body and adds no new attack. From 100–50% HP, a cycle uses a visible **1.1 s** current intake, **.8 s** lateral sweep, **1.2 s** recovery and **1.0 s** cooldown; every third cycle exposes a sheltered eddy for **2.0 s**, where poise damage is rewarded. Below 50%, timing becomes **1.1/.8/1.2/.8 s** and the eddy opens every second cycle. Damage and power do not rise at the threshold. The creature stays surface-readable; no dive or oxygen system. One sweep remains under the 50% entry-hit ceiling and cannot chain into a second hit before recovery.

**Target change/reward.** Settling Tidecoil reveals the authored Skill Candy III pocket and leads the player to the separate Deep Watch chart action that reduces the return current. Current source reserves the named encounter, completion flag and reward role, but does not prove that Tidecoil victory itself opens the shortcut. It does not grant a mount, story key or second legendary offer. Loss returns to the Deep Watch landing.

The paragraph above is **target behavior**, not a claim that current named-spawn data implements it.

### 4.10 Officer Venn — Tidewake, 53/53/53

**Current team:** Cannonback53, Riptusk53, Riverdrake53; ACE profile label.

Venn is the exterior Veilfall exam. Cannonback uses WALL space control, Riptusk a CHARGER lane and Riverdrake a CURRENT finish. Target tells follow the shared profile floors; there is no separate phase controller. Victory opens the final waterfall approach. Failure returns to the exterior Veilfall camp and leaves Sluice progress intact.

### 4.11 Captain Nerissa — Tidewake, four L55

**Current team:** Cannonback, Mirejaw, Riverdrake, Riptusk at L55. The current source implements an ACE-labelled hosted trainer behind two ordered Veilfall controls. The recovered design names Channel Cycle, Pressure Rise and Break Tether; the environmental staging below is a **target integration**, not current acceptance.

**Channel Cycle.** Cannonback and Mirejaw fight while one side channel announces a sweep for **1.2 s**, remains active **0.8 s** and drains for **1.6 s**. A sweep deals **10% of the struck creature's maximum HP once per wave**. At least half the 42×44 m Heart Chamber remains safe. It cannot overlap a creature tell into a forced combo; if a creature at 5.6 m/s cannot leave the announced lane during the complete tell from its current legal position, that wave deals no damage.

**Pressure Rise.** Riverdrake begins the third send-out. Channel cadence becomes **1.0 s tell / .8 s active / 1.2 s recovery** and alternates sides; damage remains 10% max HP once per wave. It never overlaps a creature signature tell, and the same full-tell exit test suppresses damage when no legal escape exists.

**Break Tether.** Riptusk is the fourth and final roster member. It uses CHARGER with **1.1 s heavy tell**, .9 s recovery and a marked lane. Defeating it, rather than damaging an environmental object during combat, sets the captain flag and enables the separate tether interaction.

**Change/reward.** Captain defeat permits the physical `guardian_tether` control. No relic or Guardian is delivered until the player deliberately releases and resolves the offer. Failure returns to the exterior camp; the intake pump/sluice wheel remain open.

### 4.12 Abyssal Guardian — Tidewake, L55 offer

This is not a combat boss. The Guardian is captive until Nerissa falls. Interacting with the tether records `water_tether_disabled` and `water_guardian_freed`; the freed creature then volunteers. The first valid nearby stable character may reserve the one offer. Save occurs before delivery. A full team opens the existing ceremony; refusal still settles the offer.

Settlement records `water_guardian_settled`, `water_currents_restored` and `realm_relic_water_earned`. Tideglass is placed later at the Meadows home shrine. All present peers see the restored-current world, but only the chosen stable character can receive the creature.

## 5. Source catalogue — Meadows trainer encounters

These 31 rows are current band data. “Baseline” means no bespoke behavior should be inferred from the row.

| ID / display | Team in send-out order | Current or intended test role |
|---|---|---|
| `practice_trainer` | Bramblebun2, Mudsnout3 | opening baseline |
| `trainer_mira` | Bramblebun4 | single-creature quick-read lesson |
| `trainer_oskar` | Meadowhart6, Mosshell7 | switching/durability lesson |
| `trainer_tam` | Pipwing5, Mudsnout6 | authored-move lesson |
| `south_bridge_grunt` | Mudsnout10, Burrowback12 | physical bridge gate |
| `tournament_quarter_mira` | Bramblebun7, Mudsnout8 | tournament quarterfinal |
| `tournament_semi_tam` | Pipwing9, Mosshell9 | tournament semifinal |
| `tournament_final_oskar` | Mudsnout10, Mosshell10, Meadowhart11 | tournament composition final |
| `shepherd_the_rise` | Trailpup3, Trailpup4 | optional early baseline |
| `wanderer_trail_camp` | Mudsnout6, Pipwing7 | optional mixed-type baseline |
| `old_champion_bram` | Meadowhart6, Galecrest7 | optional late-Band1 mobility |
| `quarry_picket_dorn` | Bramblebun9, Burrowback9 | quarry gate baseline |
| `warrens_watch_pell` | Mudsnout10, Bramblebun10, Duskhush11 | cave-door composition |
| `band2_outrider_kest` | Burrowback12, Duskhush12 | optional Stone & Root test |
| `night_watch_farro` | Trailpup12, Duskhush13 | optional night encounter |
| `relay_picket_hess` | Bramblebun8, Mudsnout8 | relay escalation 1 |
| `relay_picket_orrin` | Burrowback9, Pipwing9 | relay escalation 2 |
| `relay_officer_dell` | Mosshell10, Burrowback10, Galecrest10 | relay officer composition |
| `relay_captain` / Vance | Galecrest11, Duskhush11, Tuskroot12 | Tuskroot CHARGER; crossing payoff |
| `captain_riverwatch` / Oreth | Mosshell13, Trailpup14, Brooktail15 | WALL→baseline→CURRENT; Sigil |
| `captain_field` / Halder | Duskhush13, Tuskroot14, Meadowhart15 | baseline→CHARGER→CURRENT; Sigil |
| `captain_ridge` / Vess | Trailpup14, Duskhush15, Galecrest16 | baseline→baseline→DIVER; Sigil |
| `patrol_ridgeline` | Burrowback13, Galecrest14 | optional ridge baseline |
| `pasture_drover_juno` | Burrowback13, Mudsnout13 | optional pasture baseline |
| `lost_creature_rue` | Burrowback14, Trailpup15 | optional recovery story |
| `stronghold_patrol` / Verrick | Trailpup15, Burrowback16 | garrison floor |
| `stronghold_courtyard` / Solene | Mosshell16, Reedwing17, Mudsnout17 | three-body numeric escalation |
| `stronghold_elite` / Hald | Galecrest18, Burrowback19, Mosshell19 | DIVER→baseline→WALL; mandatory door |
| `warden_aldis` | Burrowback18, Galecrest18, Brooktail19, Meadowhart19, Tuskroot20 | WALL→DIVER→CURRENT→CHARGER→ACE final exam |
| `stronghold_outer_watch` | Burrowback15, Duskhush15 | optional approach baseline |
| `stronghold_checkpoint` / Ness | Trailpup16, Galecrest16, Mosshell16 | recovered CURRENT pressure at Sigil gate; verify consumer |

The recovered encounter contract and these Halder/Vess source rows agree. Oreth's lowered L15 ace and the Warden/Hald changes are also present in current data; remaining open questions concern evidence and world payoff rather than silently replacing these teams.

**Target tournament registration.** The ownership/training milestone remains sticky: the player must have owned five creatures and trained all five to at least level 5. At the registrar, the player selects and orders exactly **three of the owned five** for the tournament. All five remain owned and visible, but only those registered three can deploy in the current round. Registration may change between rounds or after a retry only while outside combat; there is no mid-round reserve substitution, hidden sixth creature, storage box or temporary party. At each round's consent prompt, only the registered three must be fed, rested and happy. The camp must provide **three physical creature beds** even though the current initial-camp source has one. Mira, Tam and Oskar then use the exact source teams above under §2.1; the player’s registered order is the initial deployment order, with later switching allowed among those three.

## 6. Source catalogue — Cloudreach trainers

| ID / name | Team | Source role |
|---|---|---|
| `trainer_ila_lower_ring` / Ila | Breezetail19, Ribbonray21 | optional basic switching/ledge spacing |
| `trainer_orrin_bridge_watch` / Orrin | Aeriex21, Craghorn23 | optional narrow arena/forced reposition |
| `tether_lieutenant_senn` / Senn | Cliffspike22, Cloudfang24 | required anchor pulse/switch pressure |
| `keeper_maela_trial` / Maela | Aeriex23, Galecrest25 | required crosswind movement/recovery lesson |
| `young_trainer_tavi_upper_ring` / Tavi | Craghorn26, Skyrill28, Galecrest29 | optional three-body counter-switch/elevation |
| `officer_voss_summit_approach` / Voss | Stormcapra29, Cloudfang30, Skyrill31 | required gust denial/aggressive switching |
| `captain_veyra_storm_anchor` / Veyra | Aeriex31, Cloudfang32, Galecrest34 | required finale and three-relay movement exam |

## 7. Source catalogue — Stormwood trainers and named wilds

| ID / name | Team or level | Source role |
|---|---|---|
| `tamsin_surge_lesson` / Tamsin | Stormraven32, Voltwig33 | critical shelter/reposition lesson |
| `rodfolk_pathfinder_elin` / Elin | Thundertunnel33, Sparkit34 | critical narrow ash lane |
| `lieutenant_dace_hollows_rod` / Dace | Tanglevolt35, Glimmermoth36, Sparkit36 | critical picket/switch pressure |
| `traveller_ivo_lantern_pools` / Ivo | Mosshock34, Glimmermoth35 | critical pool counter-switch |
| `lieutenant_varga_rodline_bridge` / Varga | Tanglevolt37, Tanglevolt38, Stormraven39 | critical bridge choke |
| `officer_maren_verge_rod` / Maren | Sparkit32, Voltwig33, Mosshock34 | critical hazard-lane reposition |
| `archwright_senn_crown_footing` / Senn | Staticub39, Stormraven40 | critical glass-ring spacing |
| `archivist_wen_crown_trial` / Wen | Staticub40, Sparkit40 | critical wall timing/counter-switch |
| `crown_wayfarer_nell` / Nell | Glimmermoth40, Glimmermoth41 | critical telegraph read |
| `officer_nysa_deepwood_rod` / Nysa | Stormbrush40, Glimmermoth41, Staticub42 | critical hazard lanes |
| `rodfolk_guard_bram` / Bram | Stormraven40, Staticub41 | critical canopy recovery |
| `outerworks_lieutenant_sera` / Sera | Thundertunnel41, Sparkit42, Stormbrush42 | critical outer-works lanes |
| `officer_kestrel_outer_works` / Kestrel | Stormraven41, Tanglevolt42, Mosshock43 | critical discharge/counter-switch |
| `captain_marrow_dynamo_core` / Marrow | Tanglevolt42, Stormraven43, Stormbrush43, Sparkit44, Voltarach44 | critical Dynamo roster |
| `tamsin_ash_ring` | Voltwig32, Stormraven33 | optional open-arena scout |
| `ranger_pax_sentinel` / Pax | Thundertunnel33, Glimmermoth34 | optional pursuit |
| `courier_pim_pool_loop` / Pim | Mosshock34, Sparkit35 | optional waterline reposition |
| `traveller_ivo_moss_detour` | Mosshock35, Glimmermoth36 | optional dark-pool switch |
| `rodline_scout_kael` / Kael | Tanglevolt36, Sparkit37 | optional ridge pursuit |
| `rodline_keeper_fenn` / Fenn | Voltwig37, Mosshock38 | optional lane control |
| `rodline_duelist_ren` / Ren | Tanglevolt38, Stormraven39 | optional wind-up dive read |
| `rook_circuit_lantern` / Rook | Stormraven40, Staticub41, Stormbrush42 | optional ace counter-switch |
| `circuit_lena_giant` / Lena | Staticub40, Thundertunnel41 | optional Hall telegraph drill |
| `circuit_orin_blackwater` / Orin | Mosshock41, Glimmermoth42 | optional ravine pressure |
| `circuit_mira_lantern` / Mira | Mosshock39, Staticub40 | optional shelter/recovery choice |
| `circuit_tavi_rodline` / Tavi | Sparkit41, Tanglevolt42 | optional rod hazard lane |
| `hollows_alpha` | L38 CHARGER | named alpha |
| `capacitor_alpha` | L40 DIVER | named alpha |
| `crown_guardian` | L41 WALL | mandatory Crown guard |
| `old_rodfolk_hall_guardian` | L43 ACE | optional dungeon guardian |
| `blackwater_elder` | L43 CURRENT | optional current-pressure elder |
| `glass_field_alpha` | L42 CHARGER | named alpha |

These six source rows provide region, position, level, catchability and a reusable behavior profile but no complete encounter contract. The table below is the selected **proposal candidate** that closes that source gap without requesting a new creature mesh. Each encounter is one 100–0% combat phase, uses its configured placeholder body, the body's existing quick/charged VFX and the shared projected telegraph shapes; it does not acquire a custom phase transition.

| Encounter | Proposed numeric attack template and visible identity | Proposed payoff |
|---|---|---|
| `hollows_alpha` / Hollows Alpha | Voltarach38 at the existing Glowmoss Hollows position; CHARGER uses **.8 s tell, 7 m lunge, .9 s recovery, 1.6 s cooldown, ×1.3 power**. Its existing slow field uses §2.1's 24-Wind/10 s rule. Glowmoss and the full-body lane cue provide the look. | Catch-or-defeat sets `stormwood:named:hollows_alpha:cleared`; admitted participants receive one deduplicated Great Candy. A catch creates only the catcher’s one creature. |
| `capacitor_alpha` / Capacitor Alpha | Voltarach40 at the existing Conductor Run position; DIVER uses a **1.1 s visible route-line cue + .8 s strike tell, 5.5 m lunge, .6 s recovery, .9 s cooldown, 7 m reposition over 1.6 s, ×.9 power**. Slow field follows the same Y rule. | Catch-or-defeat sets `stormwood:named:capacitor_alpha:cleared` and exposes the already-authored approach to the six Crown-grade Stormglass nodes; no direct extra item grant. |
| `crown_guardian` / Crown Guardian | Staticub41 at the Hollow Crown guard position; WALL uses **.85 s tell, 1.1 s recovery, 1.6 s cooldown, chase 3.4, reposition 2.5, ×1.5 power**. Shove uses §2.1's trigger. Crown glass and a stationary frontal guard stance provide the look. | Catch-or-defeat sets `stormwood:named:crown_guardian:cleared`, permitting Wen, Heartstone and Rootgate progression already associated with this guard. |
| `old_rodfolk_hall_guardian` / Old Rodfolk Hall Guardian | Tanglevolt43 at the existing hall position; ACE uses **1.1 s tell, 1.2 s recovery, 6 m lunge, 1.8 s cooldown, 2.5 s first-attack delay, ×1.8 power**. Snare follows §2.1. Existing hall architecture and a lit lane telegraph provide the look. | Catch-or-defeat sets `stormwood:named:old_rodfolk_hall_guardian:cleared`; admitted participants receive one deduplicated Rare Candy. |
| `blackwater_elder` / Blackwater Elder | Mosshock43 at the existing Blackwater position; CURRENT uses **.8 s tell, .6 s recovery, .7 s cooldown, .5 s/2 m reposition, ×.8 power**. Veil follows §2.1. The existing pool edge and visible exit to dry ground frame its pressure. | Catch-or-defeat sets `stormwood:named:blackwater_elder:cleared`; admitted participants receive one deduplicated Glowmoss Tonic. |
| `glass_field_alpha` / Glass Field Alpha | Voltarach42 at the existing Dynamo glass-field position; CHARGER uses **.8 s tell, 7 m lunge, .9 s recovery, 1.6 s cooldown, ×1.3 power** and the standard slow field. A projected lane across existing glass, with an unobstructed side exit, provides the look. | Catch-or-defeat sets `stormwood:named:glass_field_alpha:cleared`; admitted participants receive two deduplicated Stormglass. |

The completion flag is a world-once receipt; proposed candy/material rewards are personal-once receipts for participants admitted before the current enemy began. A successful catch has one host-journaled recipient and never copies the creature to peers. Full-party faint leaves the once flag unset and returns Hollows Alpha to Lantern Pools Camp, Capacitor Alpha to Rodline Refuge, Crown Guardian to Still Grove Shelter, both Deepwood encounters to Lantern Hollow Waycamp and Glass Field Alpha to Ember Bivouac. Failed catch alone does not end the encounter. Catch and reward commits are journaled before publication. The proposal must be added to data/controller/tests before any row is called built; current source proves only the placement, placeholder, profile and generic once flag.

## 8. Source catalogue — Tidewake trainers and named encounters

| ID / name | Team | Source profile/role |
|---|---|---|
| `water_trainer_pell_trial` / Pell | Torrentoad43, Mosshell43 | CURRENT; optional lesson |
| `water_trainer_fen` / Fen | Riverdrake44, Sirenseal44 | DIVER |
| `water_trainer_lysa` / Lysa | Cragclaw45, Mirejaw45 | WALL |
| `water_trainer_daro` / Daro | Riptusk45, Torrentoad45 | CHARGER |
| `water_trainer_tovin` / Tovin | Cannonback46, Riverdrake46 | ACE |
| `water_trainer_keir` / Keir | Mosshell46, Cragclaw46 | WALL |
| `water_trainer_rune` / Rune | Riverdrake47, Sirenseal47 | DIVER |
| `water_trainer_solm` / Solm | Mirejaw47, Mangrove Monitor47 | CURRENT |
| `water_trainer_irva` / Irva | Riptusk48, Cannonback48 | CHARGER |
| `water_trainer_nel` / Nel | Torrentoad47, Sirenseal47 | CURRENT |
| `water_trainer_oswin` / Oswin | Riverdrake48, Mirejaw48 | DIVER |
| `water_trainer_tal` / Tal | Mosshell49, Cannonback49 | WALL |
| `water_trainer_sera` / Sera | Mangrove Monitor50, Riptusk50 | CURRENT |
| `water_trainer_odan` / Odan | Sirenseal50, Riverdrake50 | DIVER |
| `water_trainer_yara` / Yara | Mosshell51, Mangrove Monitor51, Sirenseal51 | ACE |
| `water_trainer_bex` / Bex | Cragclaw51, Cannonback51 | WALL |
| `water_trainer_calder` / Calder | Riptusk52, Torrentoad52, Riverdrake52 | CHARGER |
| `water_trainer_vera` / Vera | Cannonback52, Sirenseal52 | CURRENT |
| `water_trainer_tess` / Tess | Mirejaw54, Riverdrake54, Sirenseal54 | DIVER |
| `water_trainer_fennel` / Fennel | Mirejaw53, Mangrove Monitor53 | CURRENT |
| `water_trainer_venn` / Venn | Cannonback53, Riptusk53, Riverdrake53 | ACE; Veilfall gate |
| `water_trainer_morra` / Morra | Cragclaw54, Mirejaw54, Cannonback54 | WALL |
| `water_trainer_evi` / Evi | Sirenseal54, Riverdrake54, Mosshell54 | DIVER |
| `water_trainer_nerissa` / Nerissa | Cannonback55, Mirejaw55, Riverdrake55, Riptusk55 | ACE; final captain |
| `water_lantern_shell_sentinel` | Cannonback45 | named encounter |
| `water_gull_basalt_claw` | Cragclaw47 | named encounter |
| `water_brine_root_watcher` | Mirejaw47 | named encounter |
| `water_drowned_garden_songweaver` | Sirenseal51 | named encounter |
| `water_deep_watch_tidecoil` | Tidecoil54 | optional apex |
| `water_aquaryn_alpha` | Aquaryn49 | scripted catch-or-defeat alpha |
| `water_abyssal_guardian_release` | Guardian55 | scripted non-combat offer |

The five `water_*` named rows immediately before Aquaryn are the data-named encounter census; Aquaryn and the Guardian live in separate scripted systems. Metrics must state whether they include those systems rather than calling the same body two encounters.

Current source intent for the five data-named rows is binding where present. The numeric attacks and delivery semantics below are the selected **proposal candidate** where source currently reserves only intent/reward role. All reuse the configured Water adapter body, existing quick/charged VFX and shared telegraph geometry; none requires a new mesh.

| Encounter | Phase and proposed numeric attack template | Payoff |
|---|---|---|
| Lantern Shell Sentinel / Cannonback45 | One 100–0% phase. WALL uses `aqua_shot`/`tidal_burst` with **.85 s tell, 1.1 s recovery, 1.6 s cooldown, chase 3.4, reposition 2.5, ×1.5 power**; slow field uses 24 Wind/10 s. The Cannonback holds Lantern Cove's rock arch and turns at 90°/s, so circling beyond its 70° firing cone exposes the side. | Catch-or-defeat records `water_named_lantern_shell_sentinel_resolved`; a deduplicated personal Skill Candy I pickup becomes claimable for each admitted participant. |
| Basalt Claw / Cragclaw47 | One 100–0% phase. WALL uses `shell_bash`/`tremor_roll` with **.85 s tell, 1.1 s recovery, 1.6 s cooldown, chase 3.4, reposition 2.5, ×1.5 power**; shove uses 24 Wind/10 s. Its frontal tell covers 70° and the basalt shelf retains a collision-tested flank at least 4 m wide. | Catch-or-defeat records `water_named_gull_basalt_claw_resolved`; a deduplicated personal Great Candy pickup becomes claimable. |
| Root Watcher / Mirejaw47 | One 100–0% phase. This named source intent overrides ordinary role normalization with CHARGER: `splash_snap`/`undertow`, **.8 s tell, 7 m lunge, .9 s recovery, 1.6 s cooldown, ×1.3 power**; veil uses 24 Wind/10 s. The lunge lane reaches from the damp gully onto dry footing and remains visible for the full tell. | Catch-or-defeat records `water_named_brine_root_watcher_resolved`; a deduplicated personal Revive pickup becomes claimable. |
| Garden Songweaver / Sirenseal51 | One 100–0% phase. CURRENT uses `aqua_shot`/`undertow` with **.8 s tell, .6 s recovery, .7 s cooldown, .5 s/2 m reposition, ×.8 power**; snare uses 24 Wind/10 s. It holds the shallow fringe while the authored dry approach remains a safe line-of-sight break. | Catch-or-defeat records `water_named_drowned_garden_songweaver_resolved`; a deduplicated personal Skill Candy II pickup becomes claimable. |
| Tidecoil, the Abyss Serpent / Tidecoil54 | Two intensity bands use the exact timings in §4.9: **1.1/.8/1.2/1.0 s** through 50% with an eddy every third cycle, then **1.1/.8/1.2/.8 s** with an eddy every second cycle. Slow field uses 24 Wind/10 s and cannot cover the whole sheltered eddy. | Catch-or-defeat records `water_named_deep_watch_tidecoil_resolved`; a deduplicated personal Skill Candy III pickup becomes claimable and the separate chart lead becomes visible. It grants no mount, key or legendary offer. |

For these catchable wilds, the host journals one catch recipient and never copies a creature. Personal reward placement is journaled once for each participant admitted before that enemy began; observers wait for a later enemy and cannot join a single-body named wild mid-fight. Full-party faint returns to that island's last accepted camp/landing, resets the body and leaves completion/reward receipts unset. A full five-creature party is refused before throw or orb debit and must free capacity before a fresh catch attempt; defeat remains a valid resolution.

`scripts/combat/water_encounter_director.gd` now instantiates named replacement plans and carries completion/reward metadata, superseding the config rows' stale `authored_optional_encounter_not_runtime_instantiated` text. That proves spawn integration, not delivery of every reserved reward or the bespoke Tidecoil phase design above.

## 9. Rewards and difficulty checks

- Named trainers use their existing first-win rewards and ordinary per-creature XP. No hidden XP multiplier compensates for bad pacing.
- A boss reward must still matter when reached: route access, relic/key, compatible equipment/TM, traversal unlock or a visible world change.
- No named fight grants a copied legendary, arbitrary skill levels or progression flags unrelated to its chapter.
- Test expected-entry parties, one deliberately unfavorable composition and 1–4 participants.
- Record maximum single hit, unavoidable damage, time-to-first-safe-read, faint/revive consumption, switches, burst/skill use and whether the player can state the intended answer.
- A reader should reliably outperform a masher. The campaign acceptance target remains reader ≤55% of masher HP loss and ≥75% success across representative top fights, with sample size disclosed.

## 10. Built status and out of scope

| Area | Baseline status |
|---|---|
| Meadows trainer ladder/Warden/ceremony | Landed and broadly tested; some profile-consumer and fresh-play acceptance remain |
| Cloudreach trainer ladder/Veyra/three relays | Landed with continuous chapter witness; visual/cadence acceptance open |
| Stormwood named placements/generic once flags | Landed; the six numeric contracts and proposed personal payoffs in §7 are target, not built |
| Stormwood Dynamo/ending | Landed and focused-tested under current timing; the 30 s conduit revision requires implementation and acceptance; later chapter not continuously earned |
| Tidewake trainer data/Aquaryn/Veilfall/Guardian | Landed and focused-tested in slices; normal-party finale and campaign ending not accepted |
| Tidewake five named spawn plans/metadata | Spawn integration landed; the numeric contracts and reserved reward delivery in §§4.9/8 are target, not built |
| Level-4 Y geometry skill across roster | Required, not fully built |
| Tidecoil bespoke behavior | Target design, not built evidence |
| Nerissa environmental phase integration | Target design, current hosted roster/Veilfall gates landed |

Out of scope: human combat, guns, shields, block/parry, held-button defense, invulnerable dodge, player-scaled enemy levels, arbitrary HP inflation, catching trainer creatures, forced legendary capture, new boss meshes without owner references, copied co-op legendary rewards, and turning every named trainer into a three-phase spectacle.

Primary sources: `data/config/bands/*/trainers.json`; `data/config/cloudreach_chapter.json`; `data/config/cloudreach_finale.json`; `data/config/stormwood_trainers.json`; `data/config/stormwood_encounters.json`; `data/config/stormwood_dynamo.json`; `data/config/stormwood_chapter.json`; `data/config/water_characters.json`; `data/config/water_encounters.json`; `data/config/water_alpha.json`; `data/config/water_veilfall.json`; `data/config/water_combat.json`; corresponding runtime/test files; and the recovered Gate 3 encounter and biome build contracts recorded in `ralph/reports/PLAN-REWRITE/FINDINGS.md`.
