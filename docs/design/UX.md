# User Experience

## Contract and status

Tetherbound must be fully playable on an Xbox-layout controller at native **1920×1080** on a seven-inch ROG Ally and remain legible at the **1280×720** stress raster, from a fresh start through the four-chapter ending, by one to four players. The required Ally performance target is 15 W, 30 fps floor, P95≤33.3 ms and P99≤50 ms over the named 30-minute representative run, plus a three-hour memory/stability session; it is currently unproven. Controller-first means every required action is reachable, legible and reversible without a keyboard. Keyboard and mouse remain complete, remappable alternatives.

The interaction model has no held buttons, chords or hidden long-press variants. A press initiates one verb. Context changes may reuse a physical control only when the contexts are mutually exclusive and the player can predict the meaning. Combat never gives the human an attack. The active creature receives combat inputs directly and in real time.

**Built foundation:** the project has a data-described menu, rebindings, last-input device tracking, UI tokens, Xbox glyph assets, explicit input contexts, collision tests, a five-slot quick bar, map/menu shortcuts, combat burst and multiplayer downed/revive. **Partially built:** rebound-aware glyph coverage, Ally-wide layout consistency, onboarding, map/wayfinding, traversal contexts and contextual prompt arbitration. The tap-start revive input correction is implemented in the first-expedition branch; its host authority and full downed-player presentation remain open. **Not built targets:** the Y combat skill, the revised bond calibration/migration and strain UI/mechanics. Source implementation does not imply landing or complete acceptance.

## 1. Interaction principles

1. **One press, one result.** Holding a trigger must not repeat an attack. Holding X must not be required to revive, gather, build or confirm. No shoulder chord hides a required verb.
2. **State owns meaning.** World, combat, orb aim, build placement, menu, map and narrative modal are explicit contexts. A screen or state that owns input silences readers underneath it.
3. **Prompts tell the truth.** Show the current binding and last-used device. Never show controller and keyboard prompts simultaneously. A disabled verb explains why in one short line.
4. **The centre stays playable.** HUD supports direction, team state and danger without covering the trainer, active creature, target or attack geometry.
5. **Critical information uses at least two channels.** Colour pairs with icon/shape/text; essential audio pairs with visual/haptic feedback; map direction pairs heading with landmark/beacon.
6. **Progress is concrete.** Bond names a task and count. Objectives state what and why. Strain states its consequence. Bars do not hide the action that changes them.
7. **Co-op remains local and readable.** Menus do not pause a multi-peer session. Each prompt belongs to the local character, while world transactions visibly wait for host acknowledgement.

## 2. Default controller map

The table is the target default. User rebindings may change buttons while preserving context ownership and conflict checks.

### 2.1 Exploration and ordinary traversal

| Control | On-foot world verb | Notes |
|---|---|---|
| Left stick | Move | Analogue magnitude; no separate walk toggle. |
| Right stick | Camera | Manual input suppresses assistance briefly. |
| L3 | Sprint | A press toggles the current sprint request; no hold requirement. Auto-run remains a separate remappable accessibility action. |
| R3 | Target / lock | Selects or toggles the legal encounter target/camera lock. It never targets an ambient creature outside the encounter. |
| A | Jump | Mounted: hop. Fly: launch on the authored second-jump condition, then discrete climb request while in a valid current; never a held ascent. |
| X | Interact / use contextual selected tool | One arbitration winner: person, pickup, bed, build hammer, revive target or other provider. Torch, hammer and catching are hotbar tools, not dedicated buttons. |
| Y | Open Satchel | Combat replaces this with the species skill. |
| B | Quick-item slot 1 | Does not open the game menu. |
| D-pad left / up / right / down | Quick-item slots 2 / 3 / 4 / 5 | Direct selection/use; no radial hold. |
| LB | Cycle selected party creature | One press advances in player order. |
| RB | Call out / put away selected creature | Putting the active creature away is also the wild-combat flee verb. |
| LT | No ordinary-world verb | Attacks only when creature combat owns the input; rotates only after build placement owns it. |
| RT | No ordinary-world verb | Attacks only when creature combat owns the input; rotates only after build placement owns it. |
| View | Full map | Dedicated shortcut. |
| Menu | Game menu | B closes the menu. |
| Share | Auto-run toggle | Existing optional binding; may be rebound or left unused. |

Ground riding keeps the same mental map: left stick steer, right stick camera, L3 sprint toggle, R3 target/lock, A hop, X interact, RB dismount/recall through the same creature verb. Camera assistance may settle behind the current heading after manual-look inactivity, but it does not consume R3. Ground sprint and hop cost no traversal stamina. Swimming retains world interaction and camera controls; movement is analogue and no button must be held merely to remain afloat. Fly's current held-A climb behavior violates the no-hold rule and is a migration target: A issues discrete launch/climb requests, while `SYSTEMS.md` owns exact cost and climb duration. No context may resolve that violation with a chord.

### 2.2 Creature combat

| Control | Combat verb | State rule |
|---|---|---|
| Left stick | Move the active creature | Free movement outside committed action states. |
| Right stick / R3 | Camera / target-lock toggle | Manual look wins over framing assistance; R3 locks only the legal encounter opponent. |
| RT | Quick attack | Tap. Existing timing remains in `COMBAT.md`; no held repeat. |
| LT | Charged attack | Tap. “Charged” describes the move, not a button hold. |
| Y | Species skill | **Target, not built.** One equipped geometry/control skill; world Y remains Satchel because the contexts are exclusive. |
| A | Burst step | Built target: **3 m over 0.20 s**, current stick direction, facing if neutral, Wind cost, no invulnerability. It replaces jump in combat. |
| LB | Cycle to next available creature | No fainted selection, no auto-switch; 1.5 s switch lockout. |
| RB | Flee/recall | Wild fights only. Trainer fights refuse with a short reason and do not withdraw the creature. |
| X | Enter orb aim / release throw | Wild fights only and only with a legal target/orb. Trainer-owned or fainted targets refuse. |
| B / D-pad | Assigned consumables | B is slot 1 except while orb aim owns it as Cancel. |
| View / Menu / world Y | Unavailable | Map, menu and Satchel do not open during active combat. |

The party strip never changes order when combat starts. It shows all five permanent slots, living/fainted/unavailable state, selected/active identity and LB behavior. After a faint, combat waits for an explicit LB replacement in solo; co-op peers continue their own action. No sixth emergency slot appears.

Orb aim is a distinct subcontext: right stick aims; left stick repositions the exposed trainer within allowed combat control; X releases; B cancels; hotbar input is silent. Control leaves the active creature during aim and that creature remains vulnerable. Catching never spends or deletes a party slot.

### 2.3 Building

| Context | Controls |
|---|---|
| Catalogue | Left stick/D-pad navigate; A select; B close; LB/RB previous/next category. World movement is silent although the multiplayer world continues. |
| Placement | Left stick move trainer; right stick camera; X place; B put ghost away/exit; LT/RT rotate left/right; D-pad up/down changes snap step and left/right changes piece; LB/RB previous/next category; Y dismantles the aimed owned piece. Keyboard Build reopens catalogue. |

The build hammer gives X/build interaction priority only while equipped. Placement feedback distinguishes valid, blocked, unaffordable and host-pending states by shape/text as well as colour. Dismantle is a tap with a bounded confirmation for destructive/high-value cases, not a hold.

### 2.4 Menus, map and modal screens

| Context | Controls |
|---|---|
| Menu shell | Left stick/D-pad navigate; A confirm; B close/back; LB/RB previous/next tab; Y and View jump to Satchel/Map when the shell permits. |
| Satchel | A pick up/place stack; X use; Menu drop; R3 split; L3 assign to quick bar; B back; LB/RB tabs. Destructive drop uses a confirm panel. |
| Creatures | A/X activate the focused row/action; Menu evolve when eligible; R3 rename; L3 mark Best Creature; LB/RB tabs. Every borrowed verb has an on-screen legend. |
| Full map | Left stick pan; LT/RT zoom out/in; L3/R3 previous/next realm; A place/select personal marker; B back; LB/RB leave the tab. Player heading points tip-first; peers and named revealed places are distinct markers. |
| Narrative/name/starter modal | A or X advance/confirm; B cancels only when cancellation is valid; left/right changes a choice. A mandatory opening choice cannot be escaped into a broken state. |

Every screen sets initial focus, retains a visible focus treatment, restores a sensible focus after rebuild and scrolls the focused element into view. Information required for selection is visible without a mouse tooltip. The menu footer reflects the active screen, not a universal list of irrelevant controls.

The shared visual language is deep blue-gray translucent panels at roughly 70–90% readable opacity, pale thin borders, cyan/teal interaction accents, warm gold progression accents, semantic type/status colours and compact rounded forms. It does not use scroll-like fantasy frames. Inventory uses a clear grid → category → selected-item detail hierarchy. Crafting always shows the selected recipe, owned/needed ingredient counts, action state and the reason a disabled action cannot run. Dialogue remains compact and consistently shows the actual speaker name/portrait and current confirm glyph.

Layouts use anchors and containers at both native 1920×1080 and the 1280×720 stress raster. Desktop-only hard-coded offsets cannot be the sole positioning rule. Realm transitions show the destination identity and visible loading/progress feedback; a blank frame, frozen picker or unexplained input lock is a failure. Collision/fall recovery and safe seating must complete before interaction resumes.

Legacy saves may contain a sixth stored hotbar assignment even though release exposes five controls. On migration, if the sixth item is not already assigned and one of the five visible bindings is empty, move its binding to the first empty position. Otherwise remove only the inaccessible binding and show once: “Quick slot 6 was retired; the item remains in your Satchel.” The inventory stack is never consumed, dropped or hidden by this migration.

### 2.5 Co-op downed and revive

`scripts/player/downed_state.gd` now implements tap-start progress on the first-expedition branch. `data/config/multiplayer.json::downed` sets `revive_progress_s=3.0` and a `revive_move_deadzone_m=0.3` horizontal deadzone. `tests/smoke_net_revive.gd` passes the real two-peer tap/release/cancel/movement/recovery path (45 checks). The older hold names remain compatibility aliases. The complete target follows; host-authorized completion and the downed player's progress display are still unbuilt corrections to the inherited direct-peer protocol:

1. A downed teammate exposes one `Revive <name>` interaction inside the existing **2.5 m** radius.
2. The reviver taps X once to start. A clearly visible **3.0 s proximity progress** begins. No button remains pressed.
3. Progress continues while the same reviver remains in radius, within the allowed movement deadzone, undamaged, active and not downed. Moving out of the deadzone/radius, taking damage, changing realm, losing the body or tapping X again resets the attempt. Another interactable cannot steal X after revive start.
4. Completion sends one host-authorized revive request. Existing recovery baseline remains 35% health and 35% stamina unless `SYSTEMS.md` changes it; satiety is untouched. The existing 45 s multiplayer downed window remains the baseline.
5. The downed player sees remaining window, reviver name/progress and the result. Other peers see a concise icon, not a full-screen panel.

This keeps the three-second exposure decision through proximity and state rather than physical button duration. Solo has no revive window. A revive avoids the normal death satchel; timeout follows ordinary death exactly once.

### 2.6 Regional credits

The homecoming's normal completion saves `homecoming_seen` before opening a
local credits overlay. An older acknowledged save gets the overlay after
Grandpa's repeat greeting if `regional_credits_seen` is absent. Interrupted
dialogue never triggers it. The overlay owns local input and hides the local
HUD through the existing modal protocol; other players continue in the world.
It must not pause the tree, reload the scene, move the trainer or alter the party.

At1280×720 use at least48px safe margins,44px title and24px body text, with a
fixed, initially focused **Continue exploring** button below a scrollable roll.
These are720p raster sizes: the1920×1080 project canvas uses72-unit margins,
66-unit title and36-unit body, and54 units/s for the36px/s scroll target below.
After1.5s the roll advances36px/s, stopping at the bottom without closing.
Tap A/Enter or the button to continue; B/Esc skips. Ignore the opening input
edge for0.25s. No hold/chord or timed reading gate. Honour an existing reduced
motion preference if available; do not introduce another setting for this slice.

Continue/Skip means acknowledged, not that every credit was watched. Persist
player-scoped `regional_credits_seen` for the same character only while still
eligible in Meadows. Save failure rolls that flag back, closes with a readable
retry notice and permits replay after the next greeting. Realm/session/character
changes dispose the overlay without acknowledgement. Successful closure
restores world controls, camera and HUD. No sequel prompt follows.

**Partial implementation:** `regional_homecoming.gd`, `sequence_director.gd`,
`ui/regional_credits.gd` and `config/regional_credits.json` implement this local
slice; `test_regional_homecoming.gd` owns transaction checks. Complete earned
ending, guest/device acceptance and final shipped-asset attribution remain open.
**Out of scope:** a global party ceremony, a replay gallery, new rewards, final
license clearance, credits music and civilian dock/return-journey content.

## 3. HUD hierarchy and information budgets

### 3.1 Exploration

The persistent layer contains the objective/why line, party strip, five quick slots and only the capabilities relevant to the current device/context. The screen centre and lower aiming area remain clear. Interaction appears as a short local prompt with verb, object and current glyph. Repeated refusal messages such as “needs a saddle” or “cannot throw here” use a cooldown and do not fire every press.

The current objective is one main story line. It names the next action and reason, and may point to a location the player has legitimately learned. The world provides a visible waypoint beam for the next critical destination; NPC directions reveal named landmarks on the map. The beam is guidance, not a trail. Optional activities use world lures and map knowledge rather than auto-pinning every unseen reward.

Each chapter contains 6–10 meaningful optional activities, with at least one useful optional payoff per principal region. The UI groups them into authored chains/locations rather than treating every pickup as an activity. Pins derive from accepted/revealed state and never become progression authority.

After current-world `water_currents_restored`, the main-story tracker and
journal show the two personal ending rows from
`data/config/regional_ending_objectives.json`, using the current realm's next
return gate or Grandpa as destination. The existing objective beam and map
diamond follow the same row. The first receipt moves guidance to finishing
credits; both receipts clear the active objective. Local Requests remain
available. This is presentation over existing flags, not a new reward or
travel system. Old realm presentation must remove only its own map marker
during handoff; it cannot erase the new realm's objective.

### 3.2 Combat

The active panel shows creature name/type, HP, Wind current/cap, charged energy, skill availability/cooldown, strain consequence if relevant and current consumable counts. The target panel shows target name/type, HP, status, range state and the current actionable tell. Type effectiveness uses text/icon plus colour and repeats no more often than `COMBAT.md` permits.

The HUD distinguishes wind-up, active threat, recovery/punish, protected boss tell, stagger and invalid input. Attack geometry in the world remains primary; a text warning cannot compensate for an invisible tell. The target marker attaches to the rendered upper bound and does not jump to ambient creatures.

### 3.3 Progression moments

Ordinary XP, bond task credit and resource gain use compact, rate-limited feed rows. Level, completed bond node, evolution, relic, major recipe and chapter reward use a larger moment banner with audio/haptic support. A remote peer's moment cannot cover the local player's attack tell.

The progression feed is one per-player, **64-event**, sequence-numbered log. Presenters poll events since their last sequence and track epoch changes; they do not rebuild rewards from counters or replace the feed while mounted. Producers own XP, bond, item, flag and other awards, then append the presentation event. The feed never awards progression itself. Disconnect/reload must not replay a reward as new.

## 4. Bond target and migration presentation

Bond remains five concrete nodes completed in **any order**, not a continuous affection meter and not an ordered gate. The new target calibration is:

| Node | New target | Credit rule |
|---|---:|---|
| Victories together | **20** | Wild or trainer victory. Credit this creature only when eligible/present under the CREATURES participation rule. |
| Landmarks together | **3 distinct** | Credit when this creature visits the landmark, even if the player globally discovered it earlier. Identity is `(creature_id, landmark_id)`. |
| Travel together | **4,000 m** | Supported player travel with this creature present under the CREATURES rule; teleports and debug movement do not count. |
| Qualifying rests | **3** | Credit only a completed creature-bed night rest for this creature. Each credited rest is separated from the previous one by a newly credited victory or landmark. Waking early does not count. |
| Real feeds | **5** | A feed counts only when it restores at least **10 nourishment** after nourishment fell by that amount since the creature's previous credited feed. Repeated feeding at full nourishment does not count. |

The existing implementation baseline is 50 wild victories, three newly globally discovered landmarks, 4,000 m, four completed bed nights and ten feeds. It already counts completed tasks as unordered despite stale JSON comments. The new calibration, per-creature landmark history and nourishment-separated feed rule are **not built**. `CREATURES.md` owns the save migration and participation semantics.

`CREATURES.md` owns record-level migration. The UX contract is that the completed-node count never drops, an old fully bonded creature remains fully bonded, visible counters reflect the migrated state, and no unavailable global history is presented as a fabricated per-creature landmark. The migration screen needs at most one concise line: “Bond tasks were updated; earned nodes were kept.”

The Creatures tab shows five node icons, completed count, each task's current/target value and what the next completion grants. More than one task may advance at once. Field feedback says the verb (`+bond · landmark`) and creature name; it does not imply an ordered “next task.” Late catches therefore begin every node immediately.

## 5. Strain and rest presentation

Strain is a **new target, not built at the baseline**. `SYSTEMS.md` owns its gameplay effect and persistence. The accumulation contract is:

`strain_gain = 0.10 × (actual non-overkill HP damage taken in the encounter / uninjured max HP) + (0.10 if fainted at least once in the encounter else 0)`

Settle that gain once at encounter resolution and count the faint surcharge at most once, even if an encounter permits another faint after revival. Clamp total strain to **0.25**. There is no night multiplier, unrested multiplier, revive surcharge or starvation contribution. A revive does not add separate strain beyond the encounter's one faint term. Damage cannot be double-counted on both predicted and resolved events.

UI displays strain as 0–25% with explicit consequence text supplied by the actual SYSTEMS consumer. The HP bar hatches the unavailable end segment created by `effective maximum = uninjured maximum × (1 − strain)` and labels it “Rest to recover.” Do not show a decorative bar before strain changes something, and do not hide a penalty behind an unlabeled red edge. A gain event briefly shows amount and cause, then recedes. The team screen shows each creature's strain beside HP/rest state.

A physical creature bed heals from 0 to full over **120 s** of ordinary world time and reduces strain linearly from its assignment-start value to zero over the same interval; a valid completed night finishes the occupied bed. Rest clears HP damage and strain only for creatures actually assigned to qualifying beds. Unbedded creatures' HP and strain remain unchanged. Waking early keeps the partial HP/strain recovery already earned but does not grant a qualifying bond rest. The bed screen names occupant, HP, strain, time remaining and whether sleeping now will complete it.

Rest is preparation, never a hunger tax. Satiety remains slow and nonlethal; the interface never threatens starvation death. Bed shortages must be visible before the player commits to a night.

## 6. Onboarding and teaching sequence

The first ten minutes teach through required play, then remove scaffolding:

1. **Wake and orient.** Grandpa's interior establishes movement, camera, X interaction and the current objective. The door cannot bypass Grandpa; if approached early, Grandpa intervenes in fiction.
2. **Choose and name.** Show all three starter names, portraits/silhouettes, type, immediate combat read and later traversal promise before confirmation. Only one is received; the others never enter wild/trainer/trade supply.
3. **Pilot.** A safe real fight teaches RT quick, telegraphed movement response, Wind, LT charged after earned energy and A burst. The human is visibly outside the attack role.
4. **Catch.** A legal wild fight gives the physical Orb aim handover, explicit odds and the exact opening anti-deadlock grant: **50 basic Orbs, 3 small potions, 5 berries and 10 revives**. These are a one-time opening floor, never repeatable income. Failure guidance remains diegetic and bounded.
5. **Care and prepare.** Teach a real feed, creature bed, 120 s/night completion and light satiety. The first source-configured campsite requires tent, campfire, player bedroll and **one** creature bed. The player bedroll functions only inside a sufficiently large tent/shelter. Controller prompts teach assignment, feeding, waking and shelter state.
6. **Build the five.** The road gives visible catches, the pond alpha prompt and concrete “level and bond” guidance before South Bridge.
7. **Tournament consent.** Halda says concretely to **feed, rest and reach level 5**, asks “Do you want to enter?”, then asks whether the player is ready before each round. The player may leave before committing.

The source configuration currently requires one creature bed for the first camp. The standing pre-tournament target is separate and not fully reflected by that consumer: before entry, the player must be able to afford, place and learn **three creature beds, one for each tournament entrant**. Supply/readiness work must add the other two without pretending the current one-bed check already satisfies it. A compact readiness panel lists level, feed/rest state, three legal bed assignments and shelter; it does not hide a requirement behind a generic refusal.

**Target registrar selection:** before each tournament round, show the same five owned companions and let the player choose an ordered three (A selects/removes, left/right moves focus, X confirms only at exactly three, B cancels). No creature changes owner or becomes stored. The other two stay visibly owned but cannot deploy in that round. The five-owned/all-five-level5 training milestone remains a sticky learned achievement; current feed/rest/happy requirements at consent apply to the registered three. Selection can change between rounds or retries, never during a fight. Battle LB cycles only those three; this is a tournament rule shown before consent, not a hidden party-cap change. This resolves the current five-derived care consumer versus the recovered three-entrant/three-bed requirement and is **not built**.

The tournament is an eight-slot bracket with three player fights and four other entrants resolved through simulation. Existing trainers fill it. The South Bridge Team Tether grunt occurs before Oskar; the final opponent rides Meadowhart. The reward is the saddle recipe even though Rootstone becomes available later. A tournament loss heals the entrant team and permits that round to be retried; this is the explicit exception to one fight per trainer. Completion makes Halda restore the party. Recovery messaging must distinguish the retry exception from ordinary defeated trainers, whose challenge prompt disappears.

Each new chapter teaches one traversal/system verb in a safe authored situation before requiring it: Fly and realm-map selection in Cloudreach; Surge phases and arches in Stormwood; swimming/current/mounted-water state in Tidewake. Reopening a tutorial is available from Settings/Help. A tooltip is dismissed by an ordinary confirm/cancel press, never a timed hold.

A new co-op character joins at Grandpa's Village, completes name/character and starter choice before ordinary world interaction, appears physically to peers and uses a compact player name on the map. A returning portable character skips creation and retains its own party/map/inventory. Neither path may grant a second opening kit or duplicate a starter.

## 7. Wayfinding, map and objectives

The minimap and full-map triangle point tip-first in the trainer's facing direction. Party peers show chosen names at a compact scale. Each realm has separate exploration/reveal/marker coordinates and a visible selector; no cross-realm marker bleed.

The map begins with Grandpa's Village and roads revealed. An NPC who names a place can reveal it through fog. Players can add, name and remove personal markers. The map is not a creature radar and does not grant fast travel. Debug teleport is development scaffolding and absent from a normal release flow.

The Pond alpha receives a marker at about **300 m** once learned; that marker persists until the alpha is caught or defeated. The doorstep alpha remains optional and legally catchable. Each relay grunt exposes its owned shutdown point, and the authored “defeat all Meadows trainers” objective reports stable trainer identities rather than inferring completion from a raw count.

Critical wayfinding uses four aligned channels: landmark composition, road/route grammar, NPC language/map reveal and the current-objective beacon. A continuous observed player must still understand where to go when one channel is briefly hidden. Completion telemetry proves arrival, not comprehension.

Task presentation remains finite: one main story line, authored local chains, and a bounded transient event feed. No generic branching quest engine, abandon timers, repeatable daily list or indiscriminate unseen pins are in minimum scope. Rewards and flags commit exactly once; a map pin is derived presentation, never the authority that grants completion.

Wild defeat persistence remains an unresolved owner decision: defeated wilds either never return, or return only after a long/meaningful authored interval. No UX copy, timer or respawn icon may present either outcome as settled until that decision is made. Permanent resources and placed pickups remain the clearer one-time rule.

## 8. ROG Ally legibility and accessibility

At the 1280×720 stress raster (and at least equivalently at native 1920×1080):

- essential body text is at least **18 px**, primary prompts/buttons **20 px**, headings **24 px**, and critical changing numbers **22 px**;
- a focused action target is at least **44 px** high and uses a minimum **2 px** visible focus edge or equivalent filled state;
- primary text on a stable panel targets **4.5:1** contrast; large/iconographic state targets at least **3:1**; text over the world uses an opaque/translucent plate or the established outline/shadow treatment;
- critical content respects a **32 px** final-pixel safe inset; no required prompt is cut by 16:9 overscan or UI scaling;
- labels wrap or scroll by focus; they never shrink below the floor to fit;
- type, rarity, danger, valid/invalid and player identity do not depend on colour alone.

The established logical UI token scale (19/23/26/28/32/42/56) remains a starting system, but acceptance measures the final raster, not authored logical pixels. Test the Satchel, Creatures detail, crafting owned/needed list, map, Settings, combat and four-player HUD at 720p with maximum expected names/counts.

Interaction regression checks are explicit: inventory-full use refuses with the item/count and a recovery action; Stamina Shroom names the stat it actually changes; every creature skill/power-move description fits or scrolls at focus without hiding cost/effect; the team HUD keeps the same player-defined order on combat entry; ground mounts preserve sprint, jump, dismount and legal remount with rider/saddle alignment visible. Small Potion's current 50 HP result is acceptable only with the substantially increased availability promised by opening/road supply; if earned play still strands the player, increase healing or supply rather than hiding the shortage in text.

Accessibility minimum:

- remap every gameplay action for controller and keyboard/mouse, with immutable access to navigation/reset;
- adjustable look sensitivity and inversion per axis;
- subtitle/dialogue text size and background opacity;
- reduced motion that lowers camera impulse, UI animation and nonessential flashes without changing host combat timing;
- camera shake 0–100%, default modest;
- aim-assistance strength/off as an individual setting, never attack bending;
- distinct icon/shape reinforcement for type and warning colours;
- separate Master, Music, Ambience, SFX, Creatures and UI volume controls;
- a “reset controls” action accessible even after a bad remap.

Glyphs use the last input device and the player's current binding. The current `input_glyph.gd` last-device behavior is built, but several icons still reflect defaults after rebinding; rebound-aware prompts are an open target. Avoid simultaneous keyboard/controller legends except inside the Controls screen where comparing bindings is the point.

## 9. Input collision and validation contract

`data/config/input_contexts.json` is the machine-readable context inventory. Every action appears in at least one context. Tests fail if two live actions share a button/axis unless they are an explicit same-verb alias. World Y/Satchel and combat Y/Skill are valid reuse because the contexts are exclusive. World A/Jump, combat A/Burst and menu A/Confirm follow the same rule. X interaction, build place, Orb release and revive start require a single owner at a time.

The input harness must refuse a press absent from the live context. Runtime readers consult the same input-owner state before polling. Every new interaction provides tests for default binding, rebinding, context entry/exit, no double-fire and prompt accuracy. A context transition clears buffered presses so the press that closes one screen cannot attack, place or confirm behind it.

## 10. Current implementation matrix

| Feature | Baseline | Target/disposition |
|---|---|---|
| World controller map/hotbar | **Built foundation.** Five assignable slots and context machinery exist; current readers still need an owner-map audit. | Restore R3 target/lock, remove world LT Build ownership, preserve hammer-as-hotbar/X priority, and convert sprint/fly behaviors that still depend on hold semantics. |
| Combat inputs | **Partially built.** RT/LT, A burst, LB, RB/X and aim exist. | Add explicit combat Y skill; preserve attack timings and prevent held repeat. |
| Menus/rebinding/glyphs | **Built foundation.** Data menu, controls UI, last-device tracking and UI tokens exist. | Make every shown glyph rebound-aware; complete 720p and accessibility validation. |
| Co-op revive | **Partial:** tap-start 3 s proximity, 0.3 m horizontal deadzone, 2.5 m radius and 45 s window implemented; two-peer smoke passes. | Keep recovery baseline. Add host validation to the inherited direct-peer completion protocol and complete downed-player progress presentation; do not claim the old code was host-authorized. |
| Bond | **Built baseline.** Unordered five tasks at 50 wild/3 new global/4000/4 bed nights/10 feeds. | Migrate to 20 all-victory/3 per-creature landmarks/4000/3 rests/5 nourishment-separated feeds; preserve earned nodes. |
| Strain | **Not built.** No live strain field/config consumer. | Add bounded 0.25 rule through SYSTEMS/CREATURES, then expose consequence and recovery. |
| Creature beds | **Partially matches target.** 120 s healing and night completion exist. | Ensure only bedded creatures clear HP/strain; unbedded state unchanged; update messaging/tests. |
| Wayfinding/map | **Substantial built foundation.** Beacon, realm map, markers/reveals and peer presence exist. | Observed-player comprehension remains unaccepted; verify headings, 300 m persistent Pond-alpha marker, relay/trainer objectives and activity packaging. |
| Onboarding/readiness | **Broad sequence built, experience unaccepted.** Opening systems and tournament exist; source camp consumer requires one creature bed. | Preserve exact one-time kit, add/teach the three-bed pre-tournament target, shelter, explicit level/feed/rest checks and bracket retry/recovery at 720p/1080p. |

## 11. Out of scope

- Held-button combat, revive, radial menus or hidden chords.
- Human attacks, autonomous companion command wheels or a sixth emergency fighter.
- Touch-first/mobile layouts, motion controls or platform-specific PlayStation glyph production for minimum Windows release.
- Creature radar, release-build debug teleport or unrestricted fast travel.
- Generic branching quest engine, daily/repeatable task board or every pickup as an objective.
- A continuous affection meter replacing named bond tasks.
- Night/unrested strain multipliers, revive-added strain, starvation warnings or passive bed XP.
- Treating telemetry as proof that a player understood, cared or chose voluntarily.

## 12. Recovery dispositions

- **S06/S17/S20 and D14/D15/D28/D33/D68/D89:** retain slot/hotbar, finite task feed, one map database, data menu, remaps, shared UI tokens, explicit contexts and harness refusal.
- **S12/S13:** retain mandatory Grandpa/name/catch opening and its intro-only anti-deadlock guarantees; do not convert temporary safety floors into global systems.
- **S14/S16:** retain starter traversal promises, visible pre-choice explanation, persistent saddle and physical-gate limits; traversal input must obey no-hold policy.
- **DR02/D70/D76:** current bond is unordered despite stale headers. The revised targets above supersede baseline calibration while preserving earned nodes; CREATURES owns migration.
- **DR07/D75/D79:** gatekeeper refusal is in-fiction, uses highest creature and tells the remedy; it is not a floating UI lock.
- **DR08/D32/D68:** retain explicit L3 sprint, R3 target/lock, LB switch, RB recall/flee, X interact/throw/place, Y world Satchel, B/D-pad quick slots, hotbar hammer/catching and no auto-switch/held selector; combat Y is the newly authorized contextual skill. LT/RT do not become a direct world-build shortcut.
- **DR22/D81/D87:** retain faction plate/actual speaker/player-readout exceptions and mask-only hair treatment in dialogue presentation.
- **DR23/D89:** context-valid press evidence and runtime ownership are required; a binding's existence alone proves nothing.
- **B19:** retain five skills, level/progress/source/benefit/cap display and first-Cloudreach reveal; exact mechanics live in SYSTEMS.
- **B27/B30:** retain companion/pickup readability, roster-pressure team details and no-free-hotel staging; old pixel/distance samples require current-camera validation.
- **Owner recovery:** restore full world/build/menu/combat controller contexts, tournament consent, map reveal/markers, party-order stability, no message spam and Ally readability. Replace held co-op revive explicitly rather than treating it as a hard-rule exception.
