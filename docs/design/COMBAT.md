# Combat

## Contract and implementation boundary

Combat pays for the product: direct control of a chosen creature must offer readable decisions worth repeating. A fight asks where to stand, when to commit, which move fits, when to spend a meter and whether to switch. Benchmark (owner, 2026-09-29, RD-13): Palworld- and Monster-Hunter-class fun, meaning hits that land with weight, enemies whose patterns can be learned, and a visible reason to switch. The human never deals damage. The trainer supports the fight with **Tether Commands** (§10, owner, 2026-09-29, RD-12), which never damage anything. There is no commanded pet AI, shield, block, held-charge input or invulnerability roll.

**Built foundation (main `1c3f0b0d`):** `scripts/combat/{combat_manager,combat_ai,combat_math,combat_arena,move_projectile,impact_flash,telegraph_glow,contact_spacing,target_marker,type_chart}.gd`, `scripts/vfx/{combat_vfx,vfx_burst,body_glow}.gd`, `scripts/creatures/wild_creature.gd`, `data/config/{combat,type_chart,vfx,camera}.json`, `data/moves/{moves,tms}.json` (52 moves, each with `slot`, geometry and a `vfx` block of `kind` projectile/melee). Unit coverage `test_combat_{math,ai,stagger,wind,burst}.gd` and siblings. Built presentation: wind, poise, burst, shaped moves, adaptive camera, hitstop (`combat.json::hitstop`), impact flash (`combat.json::impact`), stagger ring (`stagger_feedback`), heavy-tell labelling (`telegraph`), the type-verdict line (`effect_banner`), the charged camera nudge and projectile travel with the `arrived` signal. **Partially built:** readable spacing, target framing, network equivalents and compelling difficulty.

**Not built (targets from the owner design interview of 2026-09-29):** the three-slot loadout plus ultimate (§1, §8), learnsets and move mastery (§8), the ultimate meter (§2, §8), Tether Commands (§10), knockback, reaction poses, damage numbers and rumble (§11), data-driven enemy patterns and the tag-switch combo (§12), the move-effects archetype library (§13) and shared/unique ultimates (§8.4). None of these exist in source. Acceptance is ACCEPTANCE §6.2 rows F21–F25 and F35; this file does not restate their criteria.

Numbers labelled **target** or **starting value** are implementation work, tunable in the named config file. Unless a rule is explicitly tagged **built/current**, an unlabelled normative rule in this document is also a target and must not be reported as landed. CREATURES owns species loadouts and roles; TRAINING owns move acquisition, learnsets and mastery thresholds; HOMESTEAD owns gear tiers; BOSSES owns named-fight exceptions; this file owns shared resolution, inputs, meters and presentation rules.

## 1. Input, states and commitment

**Target default map (owner, 2026-09-29, RD-11, RD-12; CODEX_START_HERE §3.5):**

| Input | Verb | Rules |
|---|---|---|
| Left stick | Move | 5.6 m/s, acceleration 34, friction 30, turn 13 rad/s; walking spends no wind. |
| X | Quick move | Tap. Base power 9, windup 0.18 s, recovery 0.22 s, cooldown 0.40 s. Builds energy only on a landed hit. |
| Y | Charged move | **Tap-start.** Base power 38, windup 0.55 s, recovery 0.50 s, cooldown 1.20 s. Requires 100 energy. "Charged" names the move, not a hold; no held charging, no release timing. |
| B | Utility move | Tap. The equipped utility (§6): geometry/control first, never a second full-strength nuke. Common cooldown and wind cost from the move row (starting 10 s / 24 wind). |
| RB, then a face button | Ultimate | Only when the active creature's ultimate meter is full (§8.3). **Tap sequence, not a chord:** a tap of RB arms the ultimate for `combat.json::ultimate.arm_window_s` (starting 1.5 s); the next tap of X, Y or B fires it. A dodges and disarms. Nothing is held. With the meter not full, RB refuses with a short HUD reason and no cost. |
| A | Burst step (dodge) | Built 3 m over 0.20 s; 30 wind; stick direction, facing if neutral. No invulnerability and no action cancellation. |
| D-pad up / left / right / down | Tether Commands | Rally / Item throw / Tag-switch combo / Tether Snare (§10). Tap; the command meter pays. |
| LB | Cycle creature | Next living, available member in player order. 1.5 s switch lockout. No automatic switch on faint. |
| LT | Orb aim (wild only) | Enters the orb-aim subcontext (UX §2.2). In aim: right stick aims, X releases, B cancels. Trainer-owned or fainted targets refuse. |
| RT | Flee/recall (wild only) | 0.5 s delay with a visible HUD cue; trainer fights refuse with clear feedback. No accidental arena-edge fleeing. |
| Right stick / R3 | Look / soft lock | **Target:** right-stick motion manually overrides framing without changing target. An R3 press toggles facing/framing assistance on the current encounter opponent only; it never selects an ambient creature or a different encounter target. |

The owner specified X/Y/B/A, RB + face and the d-pad commands. The LT orb aim and RT flee placements are this contract's proposal for the verbs those bindings displaced; they need the F23#0 controller-mapping test and the F42 input-collision tests before landing. The owner also named "LB + face" as an alternative command layout; it is a Controls-screen preset only, because LB is the default creature cycle, and it uses the same tap-then-tap latch as RB.

**Built/current map (superseded by the target above when F23 lands):** RT quick, LT charged, A burst, LB cycle, RB run/recall, X orb aim/release, B and d-pad assigned consumables (the combat context comment in `input_contexts.json` puts food and orbs on the d-pad). **Superseded (owner, 2026-09-29, RD-11, RD-12):** the RT/LT attack pair, the target Y "species skill" at level 4 and direct free consumable use in combat. Consumables are now used through the Item throw command (§10).

**Owner-tuned pace (2026-09-29, `combat.json` `player_pace`).** Every player move's windup and recovery run at x0.85 of the base values above (the cooldown scale stays 1.0: the energy meter gates the charged attack and the hosted net smokes time against the authored 1.2 s lock), and the charged arc is +15 degrees. The opponent baseline is faster too (recovery 0.6 s, attack cooldown 0.9 s, back-off 0.5 s; profiles that author their own keep them). Utility and ultimate rows author their own timings and take the same pace scale.

Combat state: `admission → deploy/input_guard → active → resolving → exit`. A trainer's next opponent returns through deploy without leaving the encounter. Actor state: `idle/move`, `windup`, `active strike`, `recovery`, `burst`, `stagger`, `ultimate`, `fainted`; aim temporarily hands input to the human while the active creature remains vulnerable. One action owns movement at a time. A strike cannot survive its actor fainting, being withdrawn or its action generation changing.

Built input guard 0.25 s prevents the engage press attacking immediately; input buffer 0.30 s retains at most one pending attack. **Target:** newest valid move press replaces an older queued press, no queue of held repeats; the queue expires on switch, stagger, aim, ultimate, exit or menu ownership change. Holding a button does not repeatedly attack. Cooldown begins at commitment; a cancelled attack still spends resources and retains cooldown. Windup/recovery root voluntary movement; authored lunge is separate and applied once. Walls stop movement rather than accumulate impulse for later. Commands (§10) are not queued behind a move; a command press either resolves at once or refuses.

**Switch target:** permitted from idle or recovery after the attack's hit has resolved; prohibited during windup, burst, stagger, ultimate and orb flight. Switching does not heal, refill energy/wind/ultimate, clear Strain or reset per-creature cooldowns. Carry resource/cooldown/meter state by creature identity, not slot. Incoming creature occupies the ally's legal supported position, with no switch invulnerability; retain enemy committed tell/facing. Switch animation 0.20 s; next voluntary switch after 1.5 s. The Tag-switch combo (§10.2) is a switch and obeys the same lockout. A faint leaves a clear LB prompt and pauses enemy attack issuance until a replacement is selected, maximum no timer in solo; in co-op other participants continue. All five unavailable means loss, never a sixth emergency fighter.

Out of scope: jump attacks, sprint attacks, combo trees, orders to an autonomous pet, friendly fire, human damage abilities, held or chorded inputs. Simultaneous player-owned attackers stay out of scope except the single authored joint strike of the Tag-switch combo (§10.2, owner, 2026-09-29, RD-12).

## 2. Wind, energy and meters

Baseline `combat.json`: wind 100; quick 12, charged 35, utility 24 (was the skill cost), burst 30; regeneration 18/s after 0.6 s outside windup/recovery. Species overrides exist: Galewisp 80/24; Mosshell 125/14. Energy 100 maximum; landed quick +26; charged spends 100. Misses earn 0. A multi-target/multi-hit visual is one hit for energy; only the encounter target takes damage in the minimum version.

Preserve the current nourishment/bond Wind scales (`data/config/creature_condition.json`, `scripts/combat/combat_manager.gd::host_wind_profile`):

`cap = species_cap × (0.65 + 0.35 × nourishment/100 + (fed ? 0.10 : 0) + 0.025 × bond_nodes)`

`regen = species_regen × (1 + 0.02 × bond_nodes)`.

**Target trait order:** compute the current nourishment/bond cap and regeneration above first, then apply each trait once (TRAINING §6 owns the trait pool, including the former personality traits; the examples here are the legacy set). Calm multiplies the resulting regeneration by 1.05. Watchful multiplies **burst cost only** by 0.95 (30→28.5 before the ordinary affordability check); it never reduces the utility wind cost. Duplicate traits on one creature are refused. Swift may multiply Veil movement to 1.47; no trait changes Veil duration, removes its wind cost or creates invulnerability. Gear (HOMESTEAD) and Rally (§10) apply after traits, each once.

The current consumer applies the nourishment interpolation, then fed and bond cap additions, then any general cap multiplier; regeneration applies the bond multiplier and then any general regeneration multiplier. Preserve that order. No health damage at zero nourishment. Show actual current/cap, not a misleading 100-full bar for a reduced cap.

If a quick or charged cannot pay its wind cost, it may still commit: wind becomes 0, windup×2, power×0.6; charged still requires/spends 100 energy. Burst/utility refuse insufficient wind, with a quiet dry cue, no cost/cooldown, no input queue. Movement and switching remain available. **Target resource lifecycle:** regeneration cannot run during hitstop, except other independent encounters' clocks continue normally; bench creatures regenerate wind at the same idle rate, retain cooldowns and cannot generate energy or ultimate meter off-screen; encounter exit restores Wind normally, while energy and ultimate meter reset to 0 only when the next encounter begins. Never regain combat resources from a failed catch or rejoining the same encounter.

**Meters (owner, 2026-09-29, RD-11, RD-12).** Two new meters join wind and energy:

| Meter | Belongs to | Fills from | Spent by | Section |
|---|---|---|---|---|
| Ultimate | each creature (by identity) | that creature's landed hits | its ultimate, only when full | §8.3 |
| Command | the player (trainer) | the piloted creature's landed hits | Tether Commands | §10.1 |

**Superseded (owner, 2026-09-29, RD-11, RD-12):** the former out-of-scope line "a third combat resource". Still out of scope: ammunition, sprint stamina shared with wind, drain merely for walking, hard helpless exhaustion, any meter that fills from pressing rather than landing.

## 3. Damage, types and stat growth

Built base damage (`combat_math.gd`, `combat.json.damage`):

`D = max(1, P × 2 × ATK/(ATK+DEF) × U[0.90,1.10] × effectiveness × bonuses)`.

`P` is the move's power multiplier times its slot base (quick 9, charged 38; utility and ultimate rows declare their own base), with exhausted scaling when relevant. **Target:** `P` also carries the move's mastery multiplier `(1 + mastery_bonus(rank))` exactly once (TRAINING §7, `data/config/move_mastery.json`, starting +5% per rank) and, for ultimates, the breakthrough growth multiplier (§8.4). Apply evolution/level/individuality, bond, Best Creature, gear and traits to effective stats once; don't multiply the same bonus at both stat and damage stages. `bonuses` holds only encounter-time multipliers (stagger crit, Rally); their product is capped at `combat.json::damage.max_bonus_product` (starting 1.6). Enemy `damage_scale=1.6` is a global baseline layered after its profile, not a replacement for move/type arithmetic. Trainer base power 10.4 overlays wild 8 before explicit per-member overrides. New boss designs must use the same arithmetic, not scripted HP subtraction.

Types belong to the **attacking move**, tested against defender primary and secondary types. Current graph 1.25 advantage/0.80 resistance is retained. Multiply the two defending-type cells, apply `data/config/type_chart.json` dual-type clamp; neutral omitted cells 1.0, no immunity. CREATURES carries the graph and primary-type TM rule. Crit is one 1.5 multiplier and comes only from the stagger punish token (§4); there is no random critical chance. Show effective/resisted verdict once per pairing, then no more often than 6 s; rearm on switch/new opponent (built `effect_banner`). Damage numbers (§11) style every hit, which is separate from this verdict line.

**Explicit disagreement:** archived COMBAT_DEPTH_PLAN proposed 1.5/0.67. Do not implement it by default. Existing 2× apex TM and uneven roster distribution compound it; the type-chart source explains why. Make correct moves legible and species play differently before making every wrong matchup oppressive. Retune only as one coherent roster/TM/boss change with all starter routes measured.

Preserve the landed Stormwood Electric TM profiles in `data/moves/moves.json`: Static Snap is a 1.15 quick; Voltaic Whip a 1.30 charged; Thunder Break a 1.60 charged; Stormfall a 2.00 charged. Their authored slot, geometry and timing travel with the move. SYSTEMS owns the stack-1 teaching item and consumption transaction; these numbers may change only as an explicit combat/roster retune, never through a generic type-chart pass.

Out of scope: physical/special split, accuracy rolls after geometry already hit, random critical chance, elemental immunity, unbounded multiplicative buff stacks.

## 4. Poise, stagger and a readable punish

**Built:** pool 40, regeneration 20/s after 2 s, stagger 0.6 s, next-hit crit 1.5, charged-into-telegraph interrupt (`data/config/combat.json::poise`), cyan stagger ring (`stagger_feedback`). **Candidate target correction, not a first-fun prerequisite:** pool remains 40 points but each landed damage event removes `100 × actual_HP_damage / uninjured_max_HP` points. This normalizes breaks across levels; current raw-damage interpretation must not be mistaken for this proposed rule. Ignore overkill when deriving poise damage. Moves that do no HP damage (most utilities, every Tether Command) do no poise damage unless their row explicitly says so.

**Target stagger lifecycle (F21#2):** at zero, cancel current windup/projectile issuance, clear pending input/impulse, play the stagger reaction (§11) and enter stagger for 0.6 s. The stagger is the bonus-damage window: one punish crit token expires when stagger ends or is consumed by one landed hit. At stagger exit reset poise to maximum and grant 0.8 s resistance to another break. Hits still deal HP damage in this resistance window. This prevents repeated zero-poise stagger and frame-by-frame crit farming. A charged hit during an **interruptible** TELEGRAPH forces a break even if poise remains. It cannot re-break during stagger/resistance. An ultimate does not force a break by itself; it deals poise damage like any hit. Boss move rows explicitly identify protected heavy tells; protection has a distinct white outer ring and sound, never a surprise invisible rule.

Base profile pools: WALL 60, CHARGER 40, DIVER 30, CURRENT 35, ACE 60. Ordinary stagger 0.6 s; clearly authored boss punish windows 0.8–1.2 s. Profile values are target tuning, stored with encounter data. Player uses 40 unless a species trait explicitly changes it. Interrupt windows must be reachable: a 0.55 s charged cannot answer a tell already almost over; the correct action can be burst or movement instead.

**Hitstop/network contract (built values, `combat.json::hitstop`):** quick 30 ms, charged 70 ms, stagger-crit 120 ms freeze affected actor presentation/combat clocks, not camera/UI, weather, networking or other encounters. **Target additions:** utility hits 40 ms and ultimate impact 140 ms (starting values, same block). Authoritative outcomes occur once; clients do not delay or duplicate a hit because their render frame freezes. Reduced-motion mode disables camera impulse and reduces hitstop presentation without changing host timing. §11 owns the rest of the impact feedback.

Out of scope: permanent stun, interrupting any boss action indiscriminately, armour immunity hidden from the tell, animation-dependent damage that differs across peers.

## 5. Geometry, targeting and camera

**Strike re-aim (owner-tuned exception, 2026-09-29, `combat.json` `strike_reaim`).** Facing is otherwise committed at the start of the windup; a charged strike turns up to 45 degrees toward the target just before the hit is tested (solo, and before the intent is sent in a session), so a circling opponent cannot slip an aimed power attack. A target behind the striker still dodges it.

Each move declares `kind`, range, cone, windup, recovery, power and lunge in `moves.json`. Already built examples: Pebble Toss is a 9 m projectile with 26° cone and 0 lunge; Stone Rush is 3.2 m/80° with 7.5 lunge. Preserve these distinct profiles. Hit validation uses current action facing at commitment and supported movement, not a damage roll based solely on distance. **Target:** facing tracks during the first half of windup, then locks; a telegraph's displayed shape matches that locked strike shape. Projectiles collide along their travelled segment and cannot pass through world walls.

**Target spacing/fit contract:** body size is not range. Replace the existing compensating 2.75× collider-radii spacing with measured directional rendered half-extents plus 0.6 m visible clearance; collision remains gameplay geometry. A melee range includes the two contacting hull extents plus the move's authored gap allowance. Projectile range is free travel beyond its launch surface. Validate head-on, broadside, large/small and all-alpha pairs. No shrinking the creature to hide a bad camera under current art rules. **Built (contact spacing, `scripts/combat/contact_spacing.gd`, `combat.json` `contact_spacing`):** at contact range the pair is held apart by the two directional rendered half-extents (fitted-art ellipse) plus 0.6 m, floored at the colliders (ceiling `max_separation_m`). The opponent's `preferred_range` floors at that separation; every reach (player, host peer profile, opponent) floors at the pair's longest separation (each body's longest half-extent) plus 0.5 m, so no hold-apart or turn opens a dodge. The ally yields at once; the host-authoritative opponent holds and yields only a deficit older than 0.35 s (ally pinned). Bursts and travelling lunges are exempt until they end. Swept correction, before the arena hold. The 2.75× collider floor remains as a lower bound. Knockback (§11) is swept through the same correction and never breaks it.

Baseline arena radius 11 m. **Target:** ordinary arena radius `clamp(ceil(2 × (ally_radius + foe_radius) + 7), 11, 26)` using gameplay radii, plus a separate fit test against rendered extents and 0.6 m clearance. If the terrain footprint cannot fit, move admission to the authored encounter pad before fighting; never teleport a running fight or clip both creatures into scenery. Boss pads are authored and checked against the largest legal party pairing. Arena edge slides actors along a low readable boundary; can't leave by sprinting, flight, water current, burst or knockback. Burst collision sweeps its path; maximum actual displacement 3 m, no multiplying impulse each frame.

Camera baseline FOV 46°, distance 9.5 m, pivot 2.3 m, pitch −25° (was 68°/6 m; tuned in the Meadows visual pass so the ally keeps its screen size while the opponent, at twice the ally's depth under the old lens, no longer renders at half size — evidence `ralph/reports/MEADOWS-VISUAL-PASS/`). **Target fit/acceptance:** dynamic fit includes both real rendered bounds with 82% maximum screen fill and shared room collision. Current maximum extra distance 30 m is a safety ceiling, not a desirable shot. Neutral-look tracking deadzone 10°, strength 4, max 120°/s, manual grace 0.4 s are retained starting values. Camera must show both combatants' facing and the actionable tell in 90% of active combat samples; no continuous actionable-tell occlusion longer than 0.25 s. Manual orbit may intentionally hide the foe; exclude those intervals from automatic-framing metrics but still test collision recovery. A tight room that cannot meet this with legal bodies is a level/arena defect, not permission to crop the enemy.

**Fight camera body-size matrix (target, F21#4; catalog P2-062/P2-092 class).** Classify each actor by rendered height: **small** ≤ 2.5 m, **normal** 2.5–5 m, **giant** > 5 m (starting values, `data/config/camera.json` fight block `size_classes`; every creature is already taller than the 1.80 m trainer). Each of the nine ally × foe pairings has a validated framing offset (distance, pivot height, pitch) in the same block, applied on top of the dynamic fit above. The shot must keep both actors fully framed, their on-screen boxes overlapping by no more than `max_actor_overlap` (starting 10% of the smaller box), and never frame mostly empty arena: the frame centre biases toward the midpoint of the two rendered bounds, not the arena centre. Ultimates may push the camera in by at most 10% of distance and never cut (§8.3). The size matrix is judged code-blind from frames at the normal combat camera.

One target is the current encounter opponent; ambient creatures never steal target. HUD chevron attaches to rendered upper bound; ranged marker distinguishes in range/out of range without forcing lock-on. Aim assist may slow look near target; it does not bend missed attacks or select a different enemy.

Out of scope: cinematic camera cuts during active tells, universal hard lock, screen-filling telegraph bloom, outdoor camera settings silently applied inside narrow rooms.

## 6. Utility moves (replaces the Y skill)

**Superseded (owner, 2026-09-29, RD-11):** the parked candidate "every species learns one assigned Y skill at level 4, one equipped skill". The Y button is now the charged move. The five skill families become **utility moves** in the B slot, joined by new ones. TRAINING §7 owns which utilities a species learns (L5 and L15 unlocks, breakthroughs); this section owns their effects.

Utility is utility first: no extra full-strength nuke, no energy reward. Effects cannot stack their duration; repeated application refreshes only to the remaining maximum, and bosses have explicit resistance. Common cost and cooldown are per row (starting 24 wind, 10 s). At least ten utility moves exist and every role can equip at least two (F23#2).

| Utility | Target effect (starting values, `moves.json` rows) | Cost of the decision |
|---|---|---|
| Snare | Aim 5 m/70°; 0.25 s windup/0.30 s recovery; root 1 s, damage 0.25×quick power. Boss root 0.5 s; cannot interrupt protected move. | Set up a charged but commit near the foe. |
| Slow field | Place under target point ≤6 m; radius 2.5 m, 3 s, movement×0.5 inside; 0.30/0.35 s; no damage. | Controls a route, doesn't stop a strike already in range. |
| Shove | 4 m/80° cone; 0.25/0.35 s; 2 m swept push; 0.35×quick power. Heavy bosses move 0.75 m. | Opens range, can push a target out of charged reach. |
| Dash strike | 6 m swept advance; 0.25/0.35 s; 0.50×quick power once; no invulnerability, stops at collision. | Closes distance but can run into a committed tell. |
| Veil | 0.20/0.30 s; movement×1.40 for 1.5 s. | Repositioning only: no damage reduction, invulnerability, untargetability, block state or incoming-damage cancellation. |
| Heal pulse | 0.35/0.40 s; restores 12% of the user's max HP; no effect on the foe. | Spends a turn not dealing damage; host-validated, never revives. |
| Bramble trap | Place ≤5 m; arms after 0.5 s; first foe entering is rooted 0.8 s; lasts 6 s; one per user. | Predicts the route; wasted if the foe never steps in. |
| Hearten (buff aura) | 0.30/0.35 s; user's next landed hit within 4 s gains +15% power. | Tempo cost for a bigger punish. |
| Sap (debuff hex) | Aim 7 m/40°; 0.30/0.35 s; target takes +10% damage for 4 s. | Only pays if followed up in the window. |
| Quake ring | 0.40/0.45 s; 3 m ring around the user; 0.8 m push and 0.30×quick power. | Clears a close foe; long recovery if it whiffs. |

Boss-specific fields may reuse shapes but must not silently alter the player's version. TMs keep the primary-type rule (TRAINING §7).

## 7. Difficulty and encounter quality

Default **Adventure** targets, measured over 24 fixed seeds and all three starters at region-entry levels with declared average IVs and ordinary available supplies:

* Floor trainer: reader's median lead HP cost≤55% of masher's; reader win rate≥90%, masher may still win at meaningful cost.
* Top trainer from Meadows Band 3 onward: reader wins≥75%; masher loses its lead every run; reader median party HP cost≤55% of masher's. Across a chapter's named trainer fights, a masher loses at least one in≥25% of playthroughs (per starter, 1−Π masher win rate). Owner decision 2026-09-28 (F04#7 option c), replacing the per-fight 25% team wipe; the chapter-level 25% is the Balance lane's reading of the owner's intent. The same form applies to Tidewake F14#0, which the Tidewake lane measures (BOSSES §9). No test quietly stops after lead faint and calls it a team wipe.
* Ordinary wild: beginner masher win rate≥90%, lead HP cost 15–30%; opening tutorial exempt. A wild is not an early progression wall.
* No single hit removes≥50% of an uninjured, full-health, entry-level neutral-matchup creature. Test the worst allowed variance and legal type/TM modifiers, not the mean. Enemy ultimates, if BOSSES authors any, obey the same rule.
* Tournament win rate≥75% for the declared entry party. Warden at his re-derived level (~21–22, owner, 2026-09-29, RD-10) wins≥50% and is never tuned softer than the chapter's elite trainer under the same fixed-seed protocol.
* Ordinary wild target 20–45 s; trainer creature 30–60 s; named multi-creature fight 2–5 min; finale 3–7 min excluding dialogue. Master 1v1s (BOSSES) 1–3 min. Failure is excessive HP padding or long periods with no decision.

**Band-order anti-mash proof (target, F22#1):** in the new order Meadows → Tidewake → Cloudreach → Stormwood (owner, 2026-09-29, RD-10), across 12+ seeds per biome band, the reader wins ≥0.9 and the masher loses its lead creature materially more often. This band sweep sits beside the 24-seed named-fight floors above, it does not replace them. PROGRESSION owns the band levels; gear tier per band follows HOMESTEAD (F33#2).

Reader policy reacts after 0.25 s, dodges shown geometry, attacks recoveries, preserves enough wind for a response, uses its utility where the pattern invites it, spends commands and the ultimate at sensible moments and switches on a real mismatch or a combo window. Masher closes and presses quick/charged/utility/ultimate on availability without responding, never dodges and never switches. This comparison proves decisions have value; it does not measure real-player enjoyment. ACCEPTANCE requires agent-piloted ordinary fights and blind footage review; human preference stays unmeasured.

The archived absolute floor-trainer target of 25–80% lead-HP cost and its ≤25% five-creature wipe band are superseded by the normalized reader/masher comparison: absolute HP cost drifts as levels, IVs and legal compositions widen. The 15–30% ordinary-wild cost, one-hit<50%, tournament≥75% and Warden≥50%/not-softer-than-elite bars remain explicit acceptance floors until measured evidence authorizes a retune.

**Target accessibility setting, not built:** Assisted Adventure applies incoming damage×0.75 and tells×1.25, preserving rewards/flags and every mechanic. Host chooses difficulty for shared encounters and announces change before next admission; no mid-fight toggles. No hard mode at minimum launch. Manual aim/sensitivity/accessibility are individual. Difficulty is not a license to hide broken cameras or essential instructions.

A good fight introduces one readable question, offers at least two honest responses, punishes repeated refusal, rewards correct play, and finishes before that question becomes repetition. BOSSES must specify this for every named encounter, including the five Masters.

## 8. Loadout, mastery and ultimates

### 8.1 Loadout (owner, 2026-09-29, RD-11)

Every creature fights with `{quick, charged, utility, ultimate}` (F23#0). Quick, charged and utility are chosen from the moves the creature knows; a move may only fill a slot matching its row's `slot`. The ultimate is assigned by species (§8.4), not chosen. Loadouts change only at the Altar or a forward camp (UX §14, §15), never in the field or in combat (F23#3). **Superseded (owner, 2026-09-29, RD-11):** the one-quick-one-charged move set. Slot dispatch lives in `combat_manager.gd`; the loadout and mastery map are character-scope creature fields (TRAINING §10), host-validated on edit, saved per creature and preserved through evolution.

### 8.2 Move mastery (owner, 2026-09-29, RD-11)

Each known move has rank 1–5 rising with landed uses (TRAINING §7 owns thresholds; starting 0/25/75/150/300 in `data/config/move_mastery.json`). Combat applies it in two places only: the damage multiplier in `P` (§3) and the effect tier (§13.3). Mastery is credited from host-resolved hit events, once per event; misses, hits on an already-fainted target and hits during a replayed reconnect snapshot credit nothing. Mastery never changes timing, range, cone or cost, so a rank 5 move reads the same to the opponent's tell logic.

### 8.3 Ultimate meter and firing (owner, 2026-09-29, RD-11)

Each creature carries its own ultimate meter (max 100) keyed by identity. It fills only from that creature's landed hits: starting +6 per quick, +14 per charged, +4 per damaging utility, 0 from the ultimate itself and 0 from damage taken (`combat.json::ultimate`). Bench creatures neither gain nor lose meter; the meter resets to 0 at the next encounter start. The HUD shows it (UX §3.2). The ultimate fires only when full (F23#5), through the RB-then-face latch (§1), and only from idle or recovery. Firing empties the meter.

Presentation lasts 2–3 s (F35#3). During it the user is in the `ultimate` actor state: committed, rooted except for authored travel, not switchable. Its target is held in a hit reaction and cannot start a new windup; a protected heavy tell already committed continues (§4). Other combatants in co-op are not paused and see a shortened, attenuated version. Damage resolves on arrival of the ultimate's effect (§13.2), at the row's power (starting base 84, i.e. 2.2× charged), and against a named or boss opponent never exceeds `ultimate.max_fraction_of_named_hp` (starting 0.20) of its max HP per firing. Wild opponents never fire ultimates; whether a named trainer, boss or Master does is BOSSES' decision per profile. No camera cut; a push-in of at most 10% distance.

### 8.4 Shared and unique ultimates (owner, 2026-09-29, RD-27)

- **Unique ultimates** for the three starters, the legendaries and evolved forms: Terrapup, Ripplet, Galewisp, Veridian, Abyssal Guardian, Solmane, the Stormwood legendary, Tuskroot, Ashtusk, Cannonback, Stormcapra and the storm bear (CREATURES §4 owns the list; F35#1). Wild Cannonback and Stormcapra use the evolved form's unique ultimate.
- **Shared ultimates:** 16–20 type × role rows (F35#0). Role is the creature's combat role family from CREATURES: WALL, CHARGER, DIVER or CURRENT (ACE is a boss overlay, not a species role). A row exists for each type × role pair the roster uses; `data/moves/ultimates.json` declares a fallback row for any unused pair, and a mapping test fails on an unmapped species.
- **Growth:** an ultimate's rank equals the creature's completed breakthrough tiers (0–5). Each tier raises its power (starting +10% per tier) and visibly upgrades its presentation (count, size, a secondary layer; F35#2). Evolution keeps the tier.
- **Composition:** each ultimate is built from one or more archetypes (§13) plus a bespoke element; each is distinguishable from every other unique ultimate in frames (F35#4) and stays readable in a four-player fight.

## 9. Integration, verification and recovery dispositions

Host owns strikes, poise, status, resource and meter spends, command effects and outcome for shared fights. Inputs carry encounter/action generation and monotonic sequence; a duplicate cannot spend or hit twice. MULTIPLAYER defines scaling and admission. Animation, audio, VFX and UI subscribe to resolved events and cannot award XP, essence, mastery or meter. Hitstop never stalls host heartbeats. Catch handover preserves encounter ownership; exit clears visual nodes/providers before realm teardown. Loss and finalized human death withdraw only the affected participant.

**Scope and save of new combat state (multiplayer-native):**

| State | Scope | Authority | Transaction / duplication rule | Save and reconnect |
|---|---|---|---|---|
| Loadout, mastery | character (creature) | host validates at Altar/forward camp; mastery from host hit events | edit id applied once; each hit event credits once | saved per creature; survives rejoin (F23#3) |
| Ultimate meter | encounter (per creature) | host | fill from resolved hit events only; firing spends atomically | not saved; rejoining the same encounter takes the host value, never a refill |
| Command meter | encounter (per player) | host | fill from that player's resolved hits; spend with a command request id | not saved; same rule |
| Rally / Snare effects | encounter | host | one active instance per source; refresh, never stack | not saved; lapse on encounter exit |
| Item throw consumption | character inventory | host | the existing quick-slot consumption transaction, keyed to the command request id | inventory saves as today; a replayed request consumes nothing |
| Trainer gear command upgrades | character | host reads equipped gear at encounter admission | gear changes mid-fight are refused | saved with character (HOMESTEAD) |

Run one 15–30 minute agent-piloted expedition using the existing quick/charged/burst/switch combat, current poise and current roster before judging the new slots. The four-chapter scope decision in ACCEPTANCE §3 excluded the L4 skill, Strain, revised bond and normalized poise; the L4 skill is now superseded by the utility slot, which is in scope (F23). Strain, revised bond and normalized poise remain parked. Diagnose and tune concrete failures within current rules first; do not start a repeated cohort or new harness programme.

For implementation targets, retain the relevant focused action/poise/resource regression tests; real varied-size world fights; manual controller/mouse samples; host/client simultaneous-hit and reconnect; two-player and four-player boss; tight-room camera motion; exported build error scan; the no-held-input mapping test (F23#0) and the creature-attributed damage test (F24#1). Use the 24-seed comparison and the 12-seed band sweep only where a change needs them. Main's tests are regression foundations, not proof of new targets.

Recovery carried: FINDINGS S05,S16,S27–28, decision records D07/D08/D31/D32/D68/D77 and original COMBAT_DEPTH_PLAN. Normalized poise stays a parked candidate; the L4 skill design is superseded by §6 (owner, 2026-09-29, RD-11); retain burst Option B and defer loud types. Agent-piloted C2/C3 and independent fight-footage review must fail if mashing stays equally effective or a move's visible shape lies. Human enjoyment remains unmeasured.

## 10. Tether Commands (owner, 2026-09-29, RD-12)

The trainer fights beside the team with four support commands on the d-pad, powered by a command meter. **The human never deals damage:** every damage event names a creature as its source, and a test proves it (F24#1). Commands do no HP or poise damage. The trainer is not a combat target, keeps no handover (unlike orb aim) and plays a short gesture animation; the player keeps piloting the creature throughout. Acceptance F24#0–#5.

### 10.1 Command meter

One meter per player, max 100, reset to 0 at encounter start. It fills from the **piloted creature's** landed hits (starting +8 quick, +15 charged, +5 damaging utility, 0 from ultimates or tag-switch joint strikes) at the rate multiplier of the equipped trainer gear (§10.4). Values in `data/config/tether_commands.json`. An unaffordable or illegal command refuses with a short reason, spends nothing and is not queued.

### 10.2 The four commands

| D-pad | Command | Starting cost | Effect (starting values) | Limits |
|---|---|---:|---|---|
| Up | **Rally** | 50 | The player's active creature, and whoever that player switches in, gains +10% damage and +25% wind regeneration for 6 s. | Own creatures only; refresh, never stack; counts inside the §3 bonus cap. |
| Left | **Item throw** | 25 | Throws the first non-empty item in the trainer's pouch to the player's active creature (potion, food, buff consumable) through the existing consumption transaction. | No item deals damage. Orbs are never thrown this way (LT aim only). Pouch size comes from gear (§10.4); the pouch is filled outside combat (UX §15.3). |
| Right | **Tag-switch combo** | 40 | Within `combo_window_s` (starting 1.0 s) after the active creature lands a hit, switches to the next available creature (LB order); the incoming creature enters with its quick move at ×1.5 power while the outgoing creature adds a parting strike at ×0.5, both on the current target (§12.3). | Obeys the 1.5 s switch lockout and switch prohibitions (§1). Both strikes are creature-attributed and resolved by the host. |
| Down | **Tether Snare** | 60 | The trainer casts a tether line at a **wild** opponent: movement ×0.6 for 3 s and +0.10 to that player's catch chance while it lasts, capped by `catch_math.gd`'s existing maximum. | Refuses any trainer-owned creature (F24#3) and any target whose profile declares snare immunity (bosses). No damage, no poise damage. One snare per target. |

### 10.3 Co-op

Each player's commands affect only that player's own creatures (Rally, Item throw, Tag-switch) and, for Snare, only that player's catch chance; the Snare's slow is one shared host-owned effect on the target and a second player's snare only refreshes it (F24#5). The client sends `{encounter_id, generation, sequence, command_id}`; the host checks meter, legality and cost, spends once, applies and replicates. A duplicate or late request spends nothing.

### 10.4 Trainer gear upgrades

Workbench trainer-gear tiers upgrade commands (F24#4, F33#4): meter rate (starting ×1.00/1.15/1.30/1.45 by tier), pouch size (starting 1/2/3/3) and snare strength (starting slow ×0.6/0.55/0.5/0.45, catch bonus +0.10/0.12/0.14/0.16). HOMESTEAD owns the gear items and tiers; `tether_commands.json` owns the per-tier command numbers. Gear is read at encounter admission.

## 11. Impact feedback (owner, 2026-09-29, RD-13)

Every landed hit produces tunable hitstop, knockback scaled by move weight, a target reaction and a damage number (F21#0). All values live in `data/config/combat.json` (impact block) and are presentation except knockback displacement, which the host resolves.

**Move weight.** Each move row may declare `weight`: light, medium, heavy or ultimate. Default by slot: quick light, utility medium, charged heavy, ultimate ultimate.

| Weight | Hitstop | Knockback (starting) | Target reaction | Shake / rumble |
|---|---|---|---|---|
| Light | 30 ms (built) | 0.3 m | flinch (`hit` clip) | none |
| Medium | 40 ms | 0.6 m | flinch | none |
| Heavy | 70 ms (built) | 1.2 m | stagger-back clip, or `hit` with a procedural 8° recoil lean where no clip exists | light shake (built 0.65° charged nudge), light rumble |
| Ultimate | 140 ms | 2.0 m | stagger-back | medium shake and rumble |
| Stagger-crit | 120 ms (built) | as the move | stagger (poise break) | light shake, sharp rumble |

**Knockback** is a host-resolved, swept impulse, applied once, reduced by the target's size class (giant ×0.5) and profile (bosses and ACE ×0.5), stopped by collision and the arena edge, and followed by the contact-spacing correction (§5). It never pushes a target out of the arena or into scenery. F36 owns the reaction and stagger poses per species.

**Damage numbers** rise from the target's rendered upper bound and fade over 0.8 s, appearing on arrival (§13.2), never before the visible hit (F25#3). Styles (F21#1): ordinary numbers plain and pale; **crit** gold, 1.35× size with a burst mark; **super-effective** larger with a type-colour outline and an up-chevron; **resisted** smaller, grey, with a down-chevron. Oxblood/red is never used (reserved for Team Tether). Hits on the local player's own creature use the same styles at 0.85× size. In co-op, peers' hits show at 60% opacity and 0.8× size. Multi-hit bodies landing within 0.15 s merge into one number. Setting: damage numbers On / Own only / Off (UX §18).

**Crit, effective and resisted** also differ by sound (AUDIO §5) and flash (built `impact_flash.gd`, scaled per class), so no channel carries them alone.

**Shake and rumble** (F21#3): heavy, crit and ultimate impacts add camera shake and controller rumble. Camera shake keeps the built 0–100% setting; rumble gets its own 0–100% setting with Off. Reduced motion disables shake. Only the local player's own encounter drives their shake and rumble; peers' fights never do. None of this changes host timing.

**Proof:** a code-blind judge prefers after over before on "hits feel weighty and readable" from matched frame sequences, and fights hold frame rate on the Medium preset (F21#5).

## 12. Enemy patterns, telegraphs, anti-mash and switching (owner, 2026-09-29, RD-13)

### 12.1 Opponent decisions

Opponent machine retains close→telegraph→strike→recover→reposition. State decisions use observations available at that time; no reading future inputs or RNG. Baseline tells≥0.80s, heavy≥1.10s, recovery≥0.60s; the heavy threshold is built as `telegraph.heavy_tell_s`. Fast repeat attacks are separate marked sequences with a safe escape direction. **Target:** each attack is chosen from its role's data-driven pattern set (§12.2) in `combat.json` (AI/pattern block), not a single generic strike. Early wilds (the first Meadows band) use one pattern plus basic repositioning so the first fights stay learnable; after South Bridge, trainer opponents build energy with landed quicks and use a charged at full meter if in range. Wild energy gain ×0.5. Officers, Masters and major bosses add authored patterns (BOSSES).

**Wilds reposition, dodge and punish (F22#0):** after its recovery a wild strafes or backs off instead of standing to trade; when a player's charged or ultimate windup is visible for 0.25 s at >3 m it may burst aside (response cooldown starting 6 s for wilds, 4 s for DIVER/CHARGER trainers); when the player's creature is in recovery within reach it may issue a quick after a 0.25 s observation. No perfect frame reactions. At ≤30% HP: WALL telegraph +0.2 s/power ×1.15; DIVER reposition +0.4 s; CURRENT reposition −0.2 s but recovery +0.15 s after every third strike. These are observable tradeoffs, not arbitrary enrage stat walls.

**Current bounded exception:** the Warrens guardian uses BOSSES §4.1's explicit quick/Earth Fist sequence through the existing state machine, with a frozen selected-move profile and final-half heavy heading commitment. Ordinary enemies remain on their prior behavior until the pattern block lands.

### 12.2 Patterns per role (at least two each, F22#0)

| Role | Pattern A | Pattern B | Read and answer |
|---|---|---|---|
| WALL | **Slam:** heavy frontal cone, tell 1.1 s, long recovery. | **Quake ring:** radial ring tell 1.2 s around itself. | Step out of the cone or burst out of the ring, then punish the recovery. |
| CHARGER | **Rush:** lane telegraph 0.9 s, long travel. | **Double rush:** a marked second lane re-aims 0.3 s after the first ends. | Sidestep the lane; the second rush is the tell to wait for before punishing. |
| DIVER | **Leap-in:** ground marker at the landing point, tell 1.0 s. | **Hit-and-retreat:** quick strike then backstep; punishable at the backstep's end. | Leave the marker; chase only after the retreat ends. |
| CURRENT | **Volley:** three projectiles in a fan, tell 0.9 s. | **Zone:** a field that persists 3 s. | Move laterally across the fan; leave or avoid the zone. |
| ACE | Combines two role patterns plus one authored pattern per named fight. | — | BOSSES owns each named pattern (F22#4). |

Each pattern row declares tell duration, telegraph shape (cone, lane, ring, marker, fan or field), safe escape direction and recovery. The displayed shape is the strike's real geometry (§5). A code-blind judge must name the role of five different creatures from fight footage (F22#3), so roles also differ in ranges, movement and utility (CREATURES).

### 12.3 Switching value (F22#2)

Switching must win fights, not just swap bodies. Three sources: the **Tag-switch combo** (§10.2), a joint strike available only right after a landed hit; **type matchup** (§3), because a switch changes the attacking move's type; and **per-identity resources** (§2), because a benched creature keeps its cooldowns and ultimate meter. A switching reader must beat a non-switching reader on the same seeds.

### 12.4 Anti-mash proof

§7 defines reader and masher. The proof runs the 12+-seed band sweep in the new order and re-captures named fights for C3 (Warden, captains, relay officers, Nerissa, Veyra, the Stormwood finale). That evidence closes or supersedes F04#1, F04#2, F04#6, F04#7, F10#6 and F14#1 (F22#4; CODEX_START_HERE §7.5).

Out of scope: three damage cooldown buttons, dynamic difficulty reading player skill, omniscient evasive AI, enemy commands/combos that no visible tell explains, enemy blocking or shields.

## 13. Move-effects archetype library (owner, 2026-09-29, RD-23)

Every move shows its real object: pebbles fly, fireballs burn, lightning strikes from the sky (F25). Moves map to about 24 archetypes plus bespoke ultimates, within an Ally performance budget.

### 13.1 Archetypes

Each archetype has a body (mesh or CPUParticles3D), trail, impact and sound id (AUDIO §5.1), configured in `data/config/vfx.json` (F25#0).

| # | Archetype | Body and read | Damage resolves on |
|---:|---|---|---|
| 1 | Stone throw | pebbles, rock or boulder by parameters: several small stones in an arc, or one stone with a heavy arc | first stone's arrival |
| 2 | Fireball | burning orb with trail, explosion | arrival |
| 3 | Flame cone | short cone of flame | cone reaching target |
| 4 | Ember burst | radial sparks around the user | burst front |
| 5 | Sky lightning strike | bolt striking the target from above after a short marker | bolt contact |
| 6 | Chain lightning arc | arc jumping user → target | arc contact |
| 7 | Water jet | pressurised stream | stream contact |
| 8 | Bubble volley | several bubbles in a spread | first bubble's arrival |
| 9 | Tidal wave | wavefront rolling forward | wavefront contact |
| 10 | Wind blade | crescent blade | arrival |
| 11 | Tornado | travelling funnel | funnel contact |
| 12 | Ice shard volley | several shards | first shard's arrival |
| 13 | Frost breath | cold cone | cone reaching target |
| 14 | Shadow bolt | dark orb with wisps | arrival |
| 15 | Psychic pulse | expanding ring of distortion | ring contact |
| 16 | Root/stone spikes | spikes erupting under the target after a ground marker | eruption |
| 17 | Quake ring | ground ring expanding from the user | ring contact |
| 18 | Claw/bite slash trail | slash arcs on contact | contact (melee) |
| 19 | Charge-dash trail | body trail during a lunge | contact (melee) |
| 20 | Heal pulse | soft ring on the user | no damage |
| 21 | Buff aura | aura on the user | no damage |
| 22 | Debuff hex | sigil on the target | no damage |
| 23 | Guard flash | brief white flash on a protected tell or poise-resistance window; **visual only**, blocking does not exist | no damage |
| 24 | Catch/tether beam | orb throw and Tether Snare line | no damage |

### 13.2 Mapping and damage on arrival

Every move row's `vfx` block names one `archetype` plus parameters: `count`, `size`, `colour`, `arc`, `speed`, `spread`, `trail` and `impact_scale`. The parameters distinguish Pebble Toss (three small stones) from a rock throw (one boulder) within the one stone-throw archetype. A test fails on any unmapped move (F25#1). The built `kind: projectile|melee` blocks remain as the fallback until each move is mapped.

Damage resolves when the effect arrives: the host decides the hit at the strike (built geometry rule, §5) and the presentation holds the impact, flash, number and sound until the effect's `arrived` signal (the built `move_projectile.gd` contract, extended to every archetype). The table above names each archetype's arrival point; any other exception is documented per archetype (F25#3). A ranged move still cannot be dodged once in the air, because it was decided at the strike.

### 13.3 Mastery tiers and colour

Mastery rank scales the effect (F25#5): rank 1 base; rank 3 adds count or starting +15% size; rank 5 adds a secondary trail or impact layer (per-archetype values in `vfx.json`). Ultimate tiers follow §8.4. Colours come from `vfx.json::type_colours`; fire archetypes stay orange-gold, and no player-creature effect uses oxblood/red. Telegraphs and effects are shaped bodies; no flat magenta rings or slabs (ART_DIRECTION).

### 13.4 Budget and Compatibility fallback

Each archetype has a particle budget in `vfx.json` (starting 48 particles for an ordinary effect, 160 for an ultimate) and each encounter an active cap (starting 384); past the cap, trails cull before bodies and impacts. A worst-case four-creature fight holds frame rate on the Medium preset capture (F25#4). Bodies are meshes or CPUParticles3D; GPUParticles3D is allowed only where the Compatibility (Low) preset has a mesh or CPU fallback that still shows the object, because the renderer default stays Compatibility until the owner's Ally test (owner, 2026-09-29, RD-25). The built reason in `move_projectile.gd` (software-GL survey captures cannot trust GPU particles) still holds for every capture used as evidence.
