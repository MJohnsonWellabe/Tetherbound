# Combat

## Contract and implementation boundary

Combat pays for the product: direct control of a chosen creature must offer readable decisions worth repeating. A fight asks where to stand, when to commit, which move fits and whether to switch. The human never attacks; no commanded pet AI, shield, block, held-charge input or invulnerability roll.

**Built foundation:** `scripts/combat/{combat_manager,combat_ai,combat_math,combat_arena,move_projectile,type_chart}.gd`, `scripts/creatures/wild_creature.gd`, `data/config/{combat,type_chart}.json`, `data/moves/moves.json`; unit coverage `test_combat_{math,ai,stagger,wind,burst}.gd`. Main `b8eda885` contains wind, poise, burst, shaped moves and adaptive camera. **Partially built:** readable spacing, target framing, network equivalents and compelling difficulty. **Not built candidate targets:** the third skill/learnsets, normalized poise and complete opponent reactions specified below. They are not prerequisites for the first owner fun check. Test presence is not acceptance; no fresh full combat matrix was run for this plan.

Numbers labelled **target** are implementation work, not changes made by this documentation PR. Unless a rule is explicitly tagged **built/current**, an unlabelled normative rule in this document is also a target and must not be reported as landed. Existing quick/charged values are retained unless a move overrides them. CREATURES owns species loadouts; BOSSES owns exceptions; this file owns shared resolution.

## 1. Input, states and commitment

| Input | Verb | Rules |
|---|---|---|
| Left stick | Move |5.6m/s, acceleration34, friction30, turn13rad/s; walking spends no wind. |
| RT | Quick | Tap. Base power9, windup0.18s, recovery0.22s, cooldown0.40s. Builds energy only on a landed hit. |
| LT | Charged | Tap. Base power38, windup0.55s, recovery0.50s, cooldown1.20s. Requires100 energy. No held charging. |
| Y | Species skill | **Target:** level4 unlock; geometry/control action,10s cooldown,24 wind. |
| A | Burst step | Built3m over0.20s;30 wind; stick direction, facing if neutral. No invulnerability and no action cancellation. |
| LB | Cycle creature | Next living, available member in player order.1.5s switch lockout. No automatic switch on faint. |
| RB | Run/recall | Wild fights only;0.5s delay. Trainer fights refuse with clear feedback. No accidental arena-edge fleeing. |
| X | Aim/release orb | Wild-only catching handover; human is not a combat target. See CREATURES. |
| B / D-pad | Assigned consumable | Existing context mapping in UX; B cancels orb aim while aiming. |
| Right stick / R3 | Look / soft lock | **Target:** right-stick motion manually overrides framing without changing target. An R3 press toggles facing/framing assistance on the current encounter opponent only; it never selects an ambient creature or a different encounter target. |

Combat state: `admission → deploy/input_guard → active → resolving → exit`. A trainer's next opponent returns through deploy without leaving the encounter. Actor state: `idle/move`, `windup`, `active strike`, `recovery`, `burst`, `stagger`, `fainted`; aim temporarily hands input to the human while the active creature remains vulnerable. One action owns movement at a time. A strike cannot survive its actor fainting, being withdrawn or its action generation changing.

Built input guard0.25s prevents the engage press attacking immediately; input buffer0.30s retains at most one pending attack. **Target:** newest valid attack replaces an older queued attack, no queue of held repeats; queue expires on switch, stagger, aim, exit or menu ownership change. Holding a trigger does not repeatedly attack. Cooldown begins at commitment; a cancelled attack still spends resources and retains cooldown. Windup/recovery root voluntary movement; authored lunge is separate and applied once. Walls stop movement rather than accumulate impulse for later.

**Switch target:** permitted from idle or recovery after the attack's hit has resolved; prohibited during windup, burst, stagger and orb flight. Switching does not heal, refill energy/wind, clear Strain or reset per-creature cooldowns. Carry resource/cooldown state by creature identity, not slot. Incoming creature occupies the ally's legal supported position, with no switch invulnerability; retain enemy committed tell/facing. Switch animation0.20s; next voluntary switch after1.5s. A faint leaves a clear LB prompt and pauses enemy attack issuance until a replacement is selected, maximum no timer in solo; in co-op other participants continue. All five unavailable means loss, never a sixth emergency fighter.

Out of scope: jump attacks, sprint attacks, combo trees, simultaneous player-owned attackers, orders to an autonomous pet, friendly fire, human damage abilities.

## 2. Wind and energy

Baseline `combat.json`: wind100; quick12, charged35, skill24, burst30; regeneration18/s after0.6s outside windup/recovery. Species overrides exist: Galewisp80/24; Mosshell125/14. Energy100 maximum; landed quick+26; charged spends100. Misses earn0. A multi-target/ multi-hit visual is one hit for energy; only the encounter target takes damage in the minimum version.

Preserve the current nourishment/bond Wind scales (`data/config/creature_condition.json`, `scripts/combat/combat_manager.gd::host_wind_profile`):

`cap = species_cap × (0.65 + 0.35 × nourishment/100 + (fed ? 0.10 : 0) + 0.025 × bond_nodes)`

`regen = species_regen × (1 + 0.02 × bond_nodes)`.

**Target trait order:** compute the current nourishment/bond cap and regeneration above first, then apply each revealed trait once. Calm multiplies the resulting regeneration by1.05. Watchful multiplies **burst cost only** by0.95 (30→28.5 before the ordinary affordability check); it never reduces the common24-Wind skill cost. A primary and revealed secondary trait may both apply, but duplicate traits on one creature are refused. Swift may multiply Veil movement to1.47; no trait changes Veil duration, removes its24-Wind cost or creates invulnerability. Trait effects remain unbuilt until this formula order and host replication land.

The current consumer applies the nourishment interpolation, then fed and bond cap additions, then any general cap multiplier; regeneration applies the bond multiplier and then any general regeneration multiplier. Preserve that order. No health damage at zero nourishment. Show actual current/cap, not a misleading100-full bar for a reduced cap.

If a quick or charged cannot pay its wind cost, it may still commit: wind becomes0, windup×2, power×0.6; charged still requires/spends100 energy. Burst/skill refuse insufficient wind, with a quiet dry cue, no cost/cooldown, no input queue. Movement and switching remain available. **Target resource lifecycle:** regeneration cannot run during hitstop, except other independent encounters' clocks continue normally; bench creatures regenerate at the same idle rate, retain cooldowns and cannot generate energy off-screen; encounter exit restores Wind normally, while energy resets to0 only when the next encounter begins. Never regain combat resources from a failed catch or rejoining the same encounter. These bench/reset semantics require identity-persistent implementation proof before they are current.

Out of scope: a third combat resource, ammunition, sprint stamina shared with wind, drain merely for walking, hard helpless exhaustion.

## 3. Damage, types and stat growth

Built base damage (`combat_math.gd`, `combat.json.damage`):

`D = max(1, P × 2 × ATK/(ATK+DEF) × U[0.90,1.10] × effectiveness × bonuses)`.

`P` is the move's power multiplier times quick9/charged38, with exhausted scaling when relevant. Apply evolution/level/individuality, bond and Best Creature to effective stats once; don't multiply the same bonus at both stat and damage stages. Enemy `damage_scale=1.6` is a global baseline layered after its profile, not a replacement for move/type arithmetic. Trainer base power10.4 overlays wild8 before explicit per-member overrides. New boss designs must use the same arithmetic, not scripted HP subtraction.

Types belong to the **attacking move**, tested against defender primary and secondary types. Current graph1.25 advantage/0.80 resistance is retained. Multiply the two defending-type cells, apply `data/config/type_chart.json` dual-type clamp; neutral omitted cells1.0, no immunity. CREATURES carries the graph and primary-type TM rule. Crit is one1.5 multiplier. Show effective/resisted verdict once per pairing, then no more often than6s; rearm on switch/new opponent.

**Explicit disagreement:** archived COMBAT_DEPTH_PLAN proposed1.5/0.67. Do not implement it by default. Existing2× apex TM and uneven roster distribution compound it; the type-chart source explains why. Make correct moves legible and species play differently before making every wrong matchup oppressive. Retune only as one coherent roster/TM/boss change with all starter routes measured.

Preserve the landed Stormwood Electric TM profiles in `data/moves/moves.json`: Static Snap is a1.15 quick; Voltaic Whip a1.30 charged; Thunder Break a1.60 charged; Stormfall a2.00 charged. Their authored slot, geometry and timing travel with the move. SYSTEMS owns the stack-1 teaching item and consumption transaction; these numbers may change only as an explicit combat/roster retune, never through a generic type-chart pass.

Out of scope: physical/special split, accuracy rolls after geometry already hit, random critical chance, elemental immunity, unbounded multiplicative buff stacks.

## 4. Poise, stagger and a readable punish

**Built:** pool40, regeneration20/s after2s, stagger0.6s, next-hit crit1.5, charged-into-telegraph interrupt (`data/config/combat.json::poise`). **Candidate target correction, not a first-fun prerequisite:** pool remains40 points but each landed damage event removes `100 × actual_HP_damage / uninjured_max_HP` points. This normalizes breaks across levels; current raw-damage interpretation must not be mistaken for this proposed rule. Ignore overkill when deriving poise damage. Skills that do no HP damage do no poise damage unless their row explicitly says so.

**Target stagger lifecycle:** at zero, cancel current windup/projectile issuance, clear pending input/impulse, play flinch and enter stagger for0.6s. One punish crit token expires when stagger ends or is consumed by one landed hit. At stagger exit reset poise to maximum and grant0.8s resistance to another break. Hits still deal HP damage in this resistance window. This prevents repeated zero-poise stagger and frame-by-frame crit farming. A charged hit during an **interruptible** TELEGRAPH forces a break even if poise remains. It cannot re-break during stagger/resistance. Boss move rows explicitly identify protected heavy tells; protection has a distinct white outer ring and sound, never a surprise invisible rule.

Base profile pools: WALL60, CHARGER40, DIVER30, CURRENT35, ACE60. Ordinary stagger0.6s; clearly authored boss punish windows0.8–1.2s. Profile values are target tuning, stored with encounter data. Player uses40 unless a species trait explicitly changes it. Interrupt windows must be reachable: a0.55s charged cannot answer a tell already almost over; the correct action can be burst or movement instead.

**Target hitstop/network contract:** quick30ms, charged70ms, stagger-crit120ms freezes affected actor presentation/combat clocks, not camera/UI, weather, networking or other encounters. Authoritative outcomes occur once; clients do not delay or duplicate a hit because their render frame freezes. Reduced-motion mode disables camera impulse and reduces hitstop presentation without changing host timing.

Out of scope: permanent stun, interrupting any boss action indiscriminately, armour immunity hidden from the tell, animation-dependent damage that differs across peers.

## 5. Geometry, targeting and camera

Each move declares `kind`, range, cone, windup, recovery, power and lunge in `moves.json`. Already built examples: Pebble Toss is a9m projectile with26° cone and0 lunge; Stone Rush is3.2m/80° with7.5 lunge. Preserve these distinct profiles. Hit validation uses current action facing at commitment and supported movement, not a damage roll based solely on distance. **Target:** facing tracks during the first half of windup, then locks; a telegraph's displayed shape matches that locked strike shape. Projectiles collide along their travelled segment and cannot pass through world walls.

**Target spacing/fit contract:** body size is not range. Replace the existing compensating2.75× collider-radii spacing with measured directional rendered half-extents plus0.6m visible clearance; collision remains gameplay geometry. A melee range includes the two contacting hull extents plus the move's authored gap allowance. Projectile range is free travel beyond its launch surface. Validate head-on, broadside, large/small and all-alpha pairs. No shrinking the creature to hide a bad camera under current art rules.

Baseline arena radius11m. **Target:** ordinary arena radius `clamp(ceil(2 × (ally_radius + foe_radius) + 7), 11, 26)` using gameplay radii, plus a separate fit test against rendered extents and0.6m clearance. If the terrain footprint cannot fit, move admission to the authored encounter pad before fighting; never teleport a running fight or clip both creatures into scenery. Boss pads are authored and checked against the largest legal party pairing. Arena edge slides actors along a low readable boundary; can't leave by sprinting, flight, water current or burst. Burst collision sweeps its path; maximum actual displacement3m, no multiplying impulse each frame.

Camera baseline FOV46°, distance9.5m, pivot2.3m, pitch−25° (was 68°/6m; tuned in the Meadows visual pass so the ally keeps its screen size while the opponent, at twice the ally's depth under the old lens, no longer renders at half size — evidence `ralph/reports/MEADOWS-VISUAL-PASS/`). **Target fit/acceptance:** dynamic fit includes both real rendered bounds with82% maximum screen fill and shared room collision. Current maximum extra distance30m is a safety ceiling, not a desirable shot. Neutral-look tracking deadzone10°, strength4, max120°/s, manual grace0.4s are retained starting values. Camera must show both combatants' facing and the actionable tell in90% of active combat samples; no continuous actionable-tell occlusion longer than0.25s. Manual orbit may intentionally hide the foe; exclude those intervals from automatic-framing metrics but still test collision recovery. A tight room that cannot meet this with legal bodies is a level/arena defect, not permission to crop the enemy.

One target is the current encounter opponent; ambient creatures never steal target. HUD chevron attaches to rendered upper bound; ranged marker distinguishes in range/out of range without forcing lock-on. Aim assist may slow look near target; it does not bend missed attacks or select a different enemy.

Out of scope: cinematic camera cuts during active tells, universal hard lock, screen-filling telegraph bloom, outdoor camera settings silently applied inside narrow rooms.

## 6. Third skill and opponent decisions — candidate target, not built

Every species learns its assigned Y skill at level4; a higher-level catch already knows it. One equipped skill, one quick, one charged. Skill is utility first; no extra full-strength nuke. Common cooldown10s/wind24; no energy reward. Effects cannot stack their duration; repeated application refreshes only to the remaining maximum, and bosses have explicit resistance below.

| Skill family | Exact target effect | Cost of the decision |
|---|---|---|
| Snare | Aim5m/70°;0.25s windup/0.30s recovery; root1s, damage0.25×quick power. Boss root0.5s; cannot interrupt protected move. | Set up a charged but commit near the foe. |
| Slow field | Place under target point ≤6m; radius2.5m,3s duration, movement×0.5 while inside;0.30/0.35s; no damage. | Controls a route, doesn't stop a strike already in range. |
| Shove |4m/80° cone;0.25/0.35s;2m swept push;0.35×quick power. Heavy bosses move0.75m. | Opens range, can push a target out of charged reach. |
| Dash strike |6m swept advance;0.25/0.35s;0.50×quick power once; no invulnerability, stops at collision. | Closes distance but can run into a committed tell. |
| Veil |0.20s windup/0.30s recovery; movement×1.40 for1.5s. | Repositioning only: no damage reduction, invulnerability, untargetability, block state or incoming-damage cancellation. |

Species table assigns one family with a named presentation; no new combat status framework beyond these five. Boss-specific fields may reuse shapes but must not silently alter the player's version. TMs retain quick/charged compatibility for minimum release; replacing Y via TMs is deliberately deferred from the archived proposal to keep the role legible.

Opponent machine retains close→telegraph→strike→recover→reposition. State decisions use observations available at that time; no reading future inputs or RNG. Baseline tells≥0.80s, heavy≥1.10s, recovery≥0.60s; fast repeat attacks are separate marked sequences with a safe escape direction. Early wilds use quick only; after South Bridge, trainer opponents build energy with landed quicks and use a charged at full meter if in range. Wild energy gain×0.5. Officers/major bosses gain one authored utility skill.

**Current bounded exception:** the Warrens guardian uses BOSSES§4.1's explicit quick/Earth Fist sequence through the existing state machine, with a frozen selected-move profile and final-half heavy heading commitment. This is a major encounter's authored pattern, not implementation of the ordinary-trainer energy/role/Y targets above. Ordinary enemies remain on their prior behavior unless their content explicitly enables the charged cadence. No player energy costs, move definitions or global damage scale change.

DIVER/CHARGER trainers may respond to a visible player charged windup after0.25s observation, at>3m, by repositioning if not already committed; response cooldown4s, no perfect frame reactions. At≤30%HP: WALL telegraph+0.2s/power×1.15; DIVER reposition+0.4s; CURRENT reposition−0.2s but recovery+0.15s after every third strike. These are observable tradeoffs, not arbitrary enrage stat walls. The ordinary wild is a safe place to learn an action; the gatekeeper combines learned actions.

Out of scope: three damage cooldown buttons, dynamic difficulty reading player skill, omniscient evasive AI, enemy commands/combos that no visible tell explains.

## 7. Difficulty and encounter quality

Default **Adventure** targets, measured over24 fixed seeds and all three starters at region-entry levels with declared average IVs and ordinary available supplies:

* Floor trainer: reader's median lead HP cost≤55% of masher's; reader win rate≥90%, masher may still win at meaningful cost.
* Top trainer from Meadows Band3 onward: reader wins≥75%; masher loses its lead every run and loses the full team in≥25% of runs. No test quietly stops after lead faint and calls it a team wipe.
* Ordinary wild: beginner masher win rate≥90%, lead HP cost15–30%; opening tutorial exempt. A wild is not an early progression wall.
* No single hit removes≥50% of an uninjured, full-health, entry-level neutral-matchup creature. Test the worst allowed variance and legal type/TM modifiers, not the mean.
* Tournament win rate≥75% for the declared entry party. Warden at L19 wins≥50% and is never tuned softer than the chapter's elite trainer under the same fixed-seed protocol.
* Ordinary wild target20–45s; trainer creature30–60s; named multi-creature fight2–5min; finale3–7min excluding dialogue. Failure is excessive HP padding or long periods with no decision.

Reader policy reacts after0.25s, avoids shown geometry, attacks recoveries, preserves enough wind for a response, uses utility for its geometry and switches on a real mismatch. Masher closes and attacks on availability without responding. This comparison proves decisions have value; it does not prove fun. Human protocol in ACCEPTANCE remains mandatory.

The archived absolute floor-trainer target of25–80% lead-HP cost and its ≤25% five-creature wipe band are superseded by the normalized reader/masher comparison: absolute HP cost drifts as levels, IVs and legal compositions widen. The 15–30% ordinary-wild cost, one-hit<50%, tournament≥75% and Warden L19≥50%/not-softer-than-elite bars remain explicit acceptance floors until measured evidence authorizes a retune.

**Target accessibility setting, not built:** Assisted Adventure applies incoming damage×0.75 and tells×1.25, preserving rewards/flags and every mechanic. Host chooses difficulty for shared encounters and announces change before next admission; no mid-fight toggles. No hard mode at minimum launch. Manual aim/sensitivity/accessibility are individual. Difficulty is not a license to hide broken cameras or essential instructions.

A good fight introduces one readable question, offers at least two honest responses, punishes repeated refusal, rewards correct play, and finishes before that question becomes repetition. BOSSES must specify this for every named encounter.

## 8. Integration, verification and recovery dispositions

Host owns strikes, poise, status, resource spends and outcome for shared fights. Inputs carry encounter/action generation and monotonic sequence; a duplicate cannot spend or hit twice. MULTIPLAYER defines scaling and admission. Animation, audio and UI subscribe to resolved events and cannot award XP. Hitstop never stalls host heartbeats. Catch handover preserves encounter ownership; exit clears visual nodes/providers before realm teardown. Loss and finalized human death withdraw only the affected participant.

First run one 15–30 minute owner expedition using the existing quick/charged combat, current poise and current roster. Keep this mechanics test to the minimum needed to decide whether combat is fun enough to continue; do not require the L4 skill, Strain, revised bond or normalized poise, and do not begin a repeated cohort or new harness programme.

For implementation targets subsequently selected, retain the relevant focused action/poise/resource regression tests; real varied-size world fights; manual controller/mouse samples; host/client simultaneous-hit and reconnect; two-player and four-player boss; tight-room camera motion; exported build error scan. Use the specified 24-seed comparison only where a balance change actually needs it, rather than as a gate to the first fun check. Main's tests are regression foundations, not proof of new targets. Keep the unmerged combat branch's verdicts explicitly tied to its hash until changes land.

Recovery carried: FINDINGS S05,S16,S27–28, decision records D07/D08/D31/D32/D68/D77 and original COMBAT_DEPTH_PLAN. Retain normalized poise and the unbuilt skill/AI as candidate targets, retain burst Option B, and defer loud types and skill-TM replacement. No automated-play green substitutes for owner feel acceptance. Acceptance must fail if mashing stays equally effective or a move's visible shape lies.
