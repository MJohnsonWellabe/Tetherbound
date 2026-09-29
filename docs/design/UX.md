# User Experience

## Contract and status

Tetherbound must be fully playable on an Xbox-layout controller at native **1920×1080** on a seven-inch ROG Ally and remain legible at the **1280×800** handheld capture and the **1280×720** stress raster, from a fresh start through the four-biome ending, by one to four players. The required Ally performance target is 15 W, 30 fps floor, P95≤33.3 ms and P99≤50 ms over the named 30-minute representative run, plus a three-hour memory/stability session; it is currently unproven. Controller-first means every required action is reachable, legible and reversible without a keyboard. Keyboard and mouse remain complete, remappable alternatives.

The interaction model has no held buttons, chords or hidden long-press variants, except Fly traversal, which may use held climb/descend (owner, 2026-09-27). The Home Key's ~2 s raise is an animation after one tap, not a hold (owner, 2026-09-29, RD-18). The combat ultimate and the optional LB command preset are **tap-then-tap latches** (tap the bumper, then tap a face button), never simultaneous chords (§2.2). A press initiates one verb. Context changes may reuse a physical control only when the contexts are mutually exclusive and the player can predict the meaning. Combat never gives the human an attack. The active creature receives combat inputs directly and in real time.

**Built foundation:** the project has a data-described menu, rebindings, last-input device tracking, UI tokens, Xbox glyph assets, explicit input contexts, collision tests, a five-slot quick bar, map/menu shortcuts, combat burst and multiplayer downed/revive. **Partially built:** rebound-aware glyph coverage, Ally-wide layout consistency, onboarding, map/wayfinding, traversal contexts and contextual prompt arbitration. The tap-start revive input correction is implemented in the first-expedition branch; its host authority and full downed-player presentation remain open. **Not built targets:** the revised bond calibration/migration and strain UI/mechanics (parked), and every screen and context from the owner design interview of 2026-09-29: the three-slot-plus-ultimate combat map and its HUD meters (§2.2, §3.2), the Home Key (§11), Crossing Hall portals and waystones (§12), the Shrine Room (§13), the Altar (§14), homestead stations, forward camps and the trainer pouch (§15), gear (§16), the research log and bounty board (§17), graphics presets and combat-feedback settings (§18), the old-save refusal (§19) and the new-system lessons (§6.1). **Superseded (owner, 2026-09-29, RD-11):** the Y combat species skill. Source implementation does not imply landing or complete acceptance. Acceptance for the new screens is ACCEPTANCE §6.2 F42 (screens and HUD), F46 (onboarding), F18 (Home Key and portals), F31 (stations), F23/F24 (combat inputs) and F26 (graphics presets).

**Every new modal and screen in this contract registers with `input_owner`** and declares its context in `data/config/input_contexts.json`: `home_key_raise`, `portal_arch`, `shrine`, `altar`, `station`, `forward_camp`, `gear`, `research`, `bounty_board`, `graphics_settings`, `old_save_refusal`, `lesson`, plus the combat subcontexts `ultimate_armed` and (preset only) `command_armed`. None stacks on another; opening one closes or refuses behind a narrative modal (F46#2).

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
| A | Jump | Mounted: hop. Riding Ripplet on water: Dive/surface toggle after its L30 breakthrough (tap, TRAINING §9; proposed binding). Fly: launch on the authored second-jump condition; climb/descend may be held (owner, 2026-09-27). |
| X | Interact / use contextual selected tool | One arbitration winner: person, pickup, bed, build hammer, revive target or other provider. Torch, hammer and catching are hotbar tools, not dedicated buttons. |
| Y | Open Satchel | Combat replaces this with the charged move; the contexts are exclusive. |
| B | Quick-item slot 1 | Does not open the game menu. Any quick slot may hold the Home Key (§11). |
| D-pad left / up / right / down | Quick-item slots 2 / 3 / 4 / 5 | Direct selection/use; no radial hold. |
| LB | Cycle selected party creature | One press advances in player order. |
| RB | Call out / put away selected creature | Putting the active creature away is also the wild-combat flee verb. |
| LT | No ordinary-world verb | Attacks only when creature combat owns the input; rotates only after build placement owns it. |
| RT | No ordinary-world verb | Attacks only when creature combat owns the input; rotates only after build placement owns it. |
| View | Full map | Dedicated shortcut. |
| Menu | Game menu | B closes the menu. |
| Share | Auto-run toggle | Existing optional binding; may be rebound or left unused. |

Ground riding keeps the same mental map: left stick steer, right stick camera, L3 sprint toggle, R3 target/lock, A hop, X interact, RB dismount/recall through the same creature verb. Camera assistance may settle behind the current heading after manual-look inactivity, but it does not consume R3. Ground sprint and hop cost no traversal stamina. Swimming retains world interaction and camera controls; movement is analogue and no button must be held merely to remain afloat. **Superseded (owner, 2026-09-27):** the former rule that Fly's held-A climb violated the no-hold rule. Fly may use held climb/descend; `SYSTEMS.md` owns exact cost and climb duration. No other traversal may borrow that exception, and no context may use a chord.

### 2.2 Creature combat

**Target map (owner, 2026-09-29, RD-11, RD-12; COMBAT §1 owns timings):**

| Control | Combat verb | State rule |
|---|---|---|
| Left stick | Move the active creature | Free movement outside committed action states. |
| Right stick / R3 | Camera / target-lock toggle | Manual look wins over framing assistance; R3 locks only the legal encounter opponent. |
| X | Quick move | Tap; no held repeat. |
| Y | Charged move | Tap-start. "Charged" describes the move, not a button hold. World Y remains Satchel because the contexts are exclusive. |
| B | Utility move | Tap; cooldown and wind cost shown on its HUD icon. |
| RB, then X/Y/B | Ultimate | Only with a full ultimate meter. RB tap enters `ultimate_armed` for the arm window (COMBAT §1); the HUD highlights the three face icons; the next face tap fires. A dodges and disarms. With the meter not full, RB shows "Ultimate not ready" once, rate-limited. |
| A | Burst step (dodge) | Built 3 m over 0.20 s, current stick direction, facing if neutral, Wind cost, no invulnerability. It replaces jump in combat. |
| D-pad up / left / right / down | Tether Commands | Rally / Item throw / Tag-switch combo / Tether Snare (COMBAT §10). A refused command names its reason (not enough meter, pouch empty, no combo window, trainer's creature). |
| LB | Cycle to next available creature | No fainted selection, no auto-switch; 1.5 s switch lockout. |
| LT | Enter orb aim | Wild fights only and only with a legal target/orb. Trainer-owned or fainted targets refuse. Proposed binding (COMBAT §1). |
| RT | Flee/recall | Wild fights only, 0.5 s delay with a visible cue. Trainer fights refuse with a short reason and do not withdraw the creature. Proposed binding (COMBAT §1). |
| View / Menu / world Y | Unavailable | Map, menu and Satchel do not open during active combat. |

**Built/current map (superseded when F23/F24 land):** RT quick, LT charged, A burst, LB cycle, RB flee/recall, X orb aim/release, B and d-pad assigned consumables. Consumables in combat now go through the Item throw command, which draws from the trainer's pouch (§15.3). The optional **LB + face** command preset (Settings → Controls) moves the four commands to a tap-then-tap LB latch (`command_armed`) and moves creature cycling to the d-pad; F42's collision tests must pass for both layouts before the preset ships.

The party strip never changes order when combat starts. It shows all five permanent slots, living/fainted/unavailable state, selected/active identity and LB behavior. After a faint, combat waits for an explicit LB replacement in solo; co-op peers continue their own action. No sixth emergency slot appears.

Orb aim is a distinct subcontext: right stick aims; left stick repositions the exposed trainer within allowed combat control; X releases; B cancels; hotbar and command input are silent. Control leaves the active creature during aim and that creature remains vulnerable. Catching never spends or deletes a party slot.

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
| Satchel | A pick up/place stack; X use; Menu drop; R3 split; L3 assign to a quick slot or pouch slot (§15.3); B back; LB/RB tabs. Destructive drop uses a confirm panel. Key items (Home Key, portal keys) show Drop disabled with "Key items stay with you." |
| Creatures | A/X activate the focused row/action; R3 rename; L3 mark Best Creature; LB/RB tabs; a Gear panel per creature (§16). Every borrowed verb has an on-screen legend. **Superseded (owner, 2026-09-29, RD-28):** "Menu evolve when eligible". Evolution is offered only when a breakthrough feast is fed (§14). |
| Full map | Left stick pan; LT/RT zoom out/in; L3/R3 previous/next realm (in `data/config/biome_order.json` order); A place/select personal marker; B back; LB/RB leave the tab. Player heading points tip-first; peers, named revealed places, activated waystones and signposted Masters are distinct markers. |
| Narrative/name/starter modal | A or X advance/confirm; B cancels only when cancellation is valid; left/right changes a choice. A mandatory opening choice cannot be escaped into a broken state. |

Every screen sets initial focus, retains a visible focus treatment, restores a sensible focus after rebuild and scrolls the focused element into view. Information required for selection is visible without a mouse tooltip. The menu footer reflects the active screen, not a universal list of irrelevant controls.

The shared visual language is deep blue-gray translucent panels at roughly 70–90% readable opacity, pale thin borders, cyan/teal interaction accents, warm gold progression accents, semantic type/status colours and compact rounded forms. It does not use scroll-like fantasy frames. Inventory uses a clear grid → category → selected-item detail hierarchy. Crafting always shows the selected recipe, owned/needed ingredient counts, action state and the reason a disabled action cannot run. Dialogue remains compact and consistently shows the actual speaker name/portrait and current confirm glyph.

Layouts use anchors and containers at both native 1920×1080 and the 1280×720 stress raster. Desktop-only hard-coded offsets cannot be the sole positioning rule. Realm transitions show the destination identity and visible loading/progress feedback; a blank frame, frozen picker or unexplained input lock is a failure. Collision/fall recovery and safe seating must complete before interaction resumes.

**Superseded for v27-and-older saves (owner, 2026-09-29, RD-35):** those saves are refused (§19), so the following migration no longer runs on them; it stays the rule for any later format that could carry a sixth binding. Legacy saves may contain a sixth stored hotbar assignment even though release exposes five controls. On migration, if the sixth item is not already assigned and one of the five visible bindings is empty, move its binding to the first empty position. Otherwise remove only the inaccessible binding and show once: “Quick slot 6 was retired; the item remains in your Satchel.” The inventory stack is never consumed, dropped or hidden by this migration.

### 2.5 Co-op downed and revive

`scripts/player/downed_state.gd` now implements tap-start progress on the first-expedition branch. `data/config/multiplayer.json::downed` sets `revive_progress_s=3.0` and a `revive_move_deadzone_m=0.3` horizontal deadzone. `tests/smoke_net_revive.gd` passes the real two-peer tap/release/cancel/movement/recovery path (45 checks). The older hold names remain compatibility aliases. The complete target follows; host-authorized completion and the downed player's progress display are still unbuilt corrections to the inherited direct-peer protocol:

1. A downed teammate exposes one `Revive <name>` interaction inside the existing **2.5 m** radius.
2. The reviver taps X once to start. A clearly visible **3.0 s proximity progress** begins. No button remains pressed.
3. Progress continues while the same reviver remains in radius, within the allowed movement deadzone, undamaged, active and not downed. Moving out of the deadzone/radius, taking damage, changing realm, losing the body or tapping X again resets the attempt. Another interactable cannot steal X after revive start.
4. Completion sends one host-authorized revive request. Existing recovery baseline remains 35% health and 35% stamina unless `SYSTEMS.md` changes it; satiety is untouched. The existing 45 s multiplayer downed window remains the baseline.
5. The downed player sees remaining window, reviver name/progress and the result. Other peers see a concise icon, not a full-screen panel.

This keeps the three-second exposure decision through proximity and state rather than physical button duration. Solo has no revive window. A revive avoids the normal death satchel; timeout follows ordinary death exactly once.

### 2.6 Regional credits

**Target trigger (owner, 2026-09-29, RD-22; F20):** credits no longer follow Tidewake. Tidewake's dock exchange closes Tidewake's chapter only. After the Stormwood finale the objective line reads "Use your Home Key: Grandpa is waiting"; the player uses the Home Key (§11), walks to the farm, and the homecoming plays with the actual five. The overlay rules below are unchanged; "eligible in Meadows" now means eligible after the Stormwood finale, at the farm. After credits, using the fifth key at the fifth arch makes it stir (§12.3); that is a world beat, not a sequel prompt.

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

The current objective is one main story line. It names the next action and reason, and may point to a location the player has legitimately learned. When the active creature or any of the five reaches a level cap, a secondary line names the remedy once ("Breakthrough needed: find the Master at <place>") and the signpost appears on the map; it never replaces the main line. The world provides a visible waypoint beam for the next critical destination; NPC directions reveal named landmarks on the map. The beam is guidance, not a trail. Optional activities use world lures and map knowledge rather than auto-pinning every unseen reward.

Each chapter contains 6–10 meaningful optional activities, with at least one useful optional payoff per principal region. The UI groups them into authored chains/locations rather than treating every pickup as an activity. Pins derive from accepted/revealed state and never become progression authority.

**Superseded trigger (owner, 2026-09-29, RD-22):** the ending rows below move from Tidewake's `water_currents_restored` to the Stormwood finale, and their destination becomes "use the Home Key, then Grandpa" (F20). The presentation rules stay. Former text: after current-world `water_currents_restored`, the main-story tracker and
journal show the two personal ending rows from
`data/config/regional_ending_objectives.json`, using the current realm's next
return gate or Grandpa as destination. The existing objective beam and map
diamond follow the same row. The first receipt moves guidance to finishing
credits; both receipts clear the active objective. Local Requests remain
available. This is presentation over existing flags, not a new reward or
travel system. Old realm presentation must remove only its own map marker
during handoff; it cannot erase the new realm's objective.

### 3.2 Combat

The active panel shows creature name/type, HP, Wind current/cap, charged energy, strain consequence if relevant and the local player's pouch count. The target panel shows target name/type, HP, status, range state and the current actionable tell.

**Target combat HUD (owner, 2026-09-29, RD-11, RD-12; F42#2):**

- **Move cluster** (lower right): four icons in the face-button diamond (X quick, Y charged, B utility, A dodge), each with its current glyph. Y shows the energy gate as a fill; B shows a cooldown sweep and wind cost; any unaffordable action dims with a shape change, not colour alone, and a press names the reason once.
- **Ultimate meter:** a ring around the RB glyph beside the cluster, per active creature (it changes with the switched-in creature, because the meter belongs to the creature). Full: the ring closes and pulses once, with a sound. Armed (`ultimate_armed`): X/Y/B icons take a bright edge and a short arm-window arc.
- **Command meter** (lower left, above the party strip): one bar with tick marks at each command's cost and the four d-pad icons (Rally, Item throw with pouch count, Tag-switch, Snare). Affordable icons are lit; Tag-switch shows its combo-window arc only while the window is open; Snare is struck through in trainer fights.
- **Damage numbers** are world-space (COMBAT §11) and obey the setting in §18.
- **Budget:** the persistent combat HUD, excluding world-space numbers and markers, covers at most 20% of the screen at 1280×800 (starting value, `data/config/hud.json`); the centre and lower aiming area stay clear. Four-player: peers' meters are not shown; the party strip shows only each peer's active creature and HP. The 7-inch rule (§8) applies. Type effectiveness uses text/icon plus colour and repeats no more often than `COMBAT.md` permits.

The HUD distinguishes wind-up, active threat, recovery/punish, protected boss tell, stagger and invalid input. Attack geometry in the world remains primary; a text warning cannot compensate for an invisible tell. The target marker attaches to the rendered upper bound and does not jump to ambient creatures.

### 3.3 Progression moments

Ordinary XP, bond task credit, essence gain, mastery progress, research task ticks and resource gain use compact, rate-limited feed rows. Level, completed bond node, breakthrough, evolution, mastery rank, relic, relic hung, portal unlocked, Master recipe, bounty claimed, research biome title, major recipe and chapter reward use a larger moment banner with audio/haptic support. Each moment belongs to the local character: in co-op each participant sees their own key, relic and recipe receipts (owner, 2026-09-29, RD-21). A remote peer's moment cannot cover the local player's attack tell.

The progression feed is one per-player, **64-event**, sequence-numbered log. Presenters poll events since their last sequence and track epoch changes; they do not rebuild rewards from counters or replace the feed while mounted. Producers own XP, bond, item, flag and other awards, then append the presentation event. The feed never awards progression itself. Disconnect/reload must not replay a reward as new.

**Trainer-result readability correction, partial:** an observed two-round,
five-companion result repeated each creature's level announcement and grew
nearly the full720p height (`MEADOWS-PAYOFFS/_sheet_reunion.png`). The displayed
moment group must combine repeated `level_up` records for the same nonzero
creature identity into one growth summary: first old level, last new level,
summed level/stat gains and all newly unlocked trait/evolution notices.
Distinct creatures with the same nickname remain distinct. The final receipt's
per-creature XP/current progress appears once; its item/coin wording stays
intact. Bond, catalyst and other distinct moments remain individually visible.
This changes derived presentation only: the per-player feed, actual awards,
pause/reload behavior and save data are unchanged. Source owners are
`progression_feed.gd` and `playground_hud.gd::_render_moment_events`; focused
feed tests and the existing HUD lifecycle fixture verify the bounded change.
Out of scope: a notification-history menu, pagination, smaller text, truncating
rewards, or a claim that all possible long-name/mixed-reward cards now fit.

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
2. **Choose and name.** Show all three starter names, portraits/silhouettes, type, immediate combat read and later traversal promise (Terrapup rides in the Meadows; Ripplet swims in Tidewake and dives after its L30 breakthrough; Galewisp flies in Cloudreach; owner, 2026-09-29, RD-32) before confirmation. **Superseded (RD-32):** Ripplet's Teleport promise is removed from this screen and every other UI (F37#3). Only one is received; the others never enter wild/trainer/trade supply.
3. **Pilot.** A safe real fight teaches X quick, telegraphed movement response, Wind, Y charged after earned energy and A dodge (target map; the built opening still teaches RT/LT until F23 lands). The human is visibly outside the attack role.
4. **Catch.** A legal wild fight gives the physical Orb aim handover, explicit odds and the exact opening anti-deadlock grant: **50 basic Orbs, 3 small potions, 5 berries and 10 revives**. These are a one-time opening floor, never repeatable income. Failure guidance remains diegetic and bounded.
5. **Care and prepare.** Teach a real feed, creature bed, 120 s/night completion and light satiety. The first source-configured campsite requires tent, campfire, player bedroll and **one** creature bed. The player bedroll functions only inside a sufficiently large tent/shelter. Controller prompts teach assignment, feeding, waking and shelter state.
6. **Build the five.** The road gives visible catches, the pond alpha prompt and concrete “level and bond” guidance before South Bridge.
7. **Tournament consent.** Halda says concretely to **feed, rest and reach level 5**, asks “Do you want to enter?”, then asks whether the player is ready before each round. The player may leave before committing.

The first camp still requires one creature bed. The pre-tournament journal then teaches **three creature beds, one for each tournament entrant**, with a visible1/3–3/3 count. `home.preparation_creature_beds` makes the gathering target include the other two beds without changing the old `home_built` milestone; the journal states the full30wood/8stone/34fiber bill. Halda checks all three bed milestones only before first entry and names preparation when some requirements remain. Already-entered saves retire this lesson. These consumers are implemented; earned supply, legal placement and usable care remain runtime acceptance questions. A single compact panel showing shelter and all three legal assignments alongside care is still a presentation target, not an implemented picker feature.

**Registrar selection:** the current source shows the same five owned companions and lets the player choose an ordered three (A selects/removes, left/right moves focus, X confirms only at exactly three, B cancels). No creature changes owner or becomes stored. The other two stay visibly owned but cannot deploy in that round. The five-owned/all-five-level5 training milestone remains a sticky learned achievement; current feed/rest/happy requirements at consent apply to the registered three. Selection can change between rounds or retries, never during a fight. Battle LB cycles only those three; this is a tournament rule shown before consent, not a hidden party-cap change. `autoload/party.gd` persists the order by durable UID and fails closed when a selected identity is missing or ambiguous. The selector and three-bed guidance/checks are implemented; earned preparation and full rendered player-path acceptance remain open.

The tournament is an eight-slot bracket with three player fights and four other entrants resolved through simulation. Existing trainers fill it. The South Bridge Team Tether grunt occurs before Oskar; the final opponent rides Meadowhart. The reward is the saddle recipe even though Rootstone becomes available later. A tournament loss heals the entrant team and permits that round to be retried; this is the explicit exception to one fight per trainer. Final victory dialogue restores the party; Halda explains the mounted payoff without owning its reward. Recovery messaging must distinguish the retry exception from ordinary defeated trainers, whose challenge prompt disappears.

Each new biome teaches one traversal/system verb in a safe authored situation before requiring it, in the play order Meadows → Tidewake → Cloudreach → Stormwood (owner, 2026-09-29, RD-10): swimming/current/Ripplet surface-mount state in Tidewake; Fly in Cloudreach; Surge phases and arches in Stormwood. Realm-map selection is taught at the first portal (§12). Reopening a tutorial is available from Settings/Help. A tooltip is dismissed by an ordinary confirm/cancel press, never a timed hold.

A new co-op character joins at Grandpa's Village, completes name/character and starter choice before ordinary world interaction, appears physically to peers and uses a compact player name on the map. A returning portable character skips creation and retains its own party/map/inventory. Neither path may grant a second opening kit or duplicate a starter. Every new character receives their own Home Key at Grandpa's handover beat; a joining character who has passed that beat in no world still gets it once, at first arrival, never twice.

### 6.1 New-system lessons (target, F46)

Grandpa or a village resident introduces each new system when it first matters (owner, 2026-09-29). Each lesson is one short in-fiction exchange plus at most one prompt card, owned by the `lesson` context, skippable with B at any line, recorded per character so it never repeats, and reopenable from Settings → Help. Lessons never stack: a lesson that becomes due during another modal, a fight or a cutscene waits until the world context is free (F46#2).

| System | Who teaches | When it first matters | The one thing the player must leave knowing |
|---|---|---|---|
| Home Key | Grandpa | the handover beat F18 chooses (practice catch or tournament send-off) | Tap it anywhere safe to return to the Crossing Hall; it is free and yours. |
| Homestead and stations | Grandpa | first return to the farm with the Home Key | The farm's stations make your five stronger; each shows its next upgrade. |
| Altar and essence | Grandpa | first essence pickup, or first return home with essence | Spend essence here on the creature you choose; fights still give a little XP. |
| Tether Commands | Grandpa | first fight after the command meter unlocks (F24 picks the point; proposal: the practice catch for Item throw and Snare, the first two-creature fight for Rally and Tag-switch) | Hits fill your meter; the d-pad spends it; you never fight yourself. |
| Utility and loadout | Grandpa or the Altar prompt | first utility unlock (L5) | Equip it at the Altar or a forward camp; B uses it. |
| Breakthroughs and Masters | a village resident (WORLD names who), then the objective line | first creature reaching the L10 cap | Find the Master, win a 1v1, learn the feast, cook it, feed it. |
| Ascension Feasts and evolution | the Kitchen and Altar prompts | first feast recipe learned | Feasts need this biome's materials plus one ingredient of your creature's type; some creatures may evolve, and staying is also fine. |
| Traits and Trait Seeds | the Altar prompt | first release at the Altar | Release distils one trait into a seed for your five. |
| Portals, keys and waystones | the Crossing Hall's resident (WORLD names who) | first portal key in the satchel (Warden's drop) | Use the key on its arch once; portals send you to your last waystone. |
| Shrine Room and relic power | the same resident | first relic in the satchel | Hang it to unlock that biome's station upgrades; carry one relic power. |
| Forward camps | Tam | kit recipe unlocked | A small camp anywhere: bed, cookpot, field workbench; travel recipes only. |
| Gear | Tam or the Forge prompt | first ingot refined | A Harness and a Charm per creature; each biome's boss is meant for that tier. |
| Research log | the research keeper | first visit or first research task ticked | Meeting creatures you won't keep still pays essence. |
| Bounty board | Halda | first morning after the tournament | Three bounties each morning; claim at the board. |

At every gate an agent-piloted new player must be able to state the next goal (F46#1); the objective line (§3.1) carries that goal after the lesson closes.

## 7. Wayfinding, map and objectives

The minimap and full-map triangle point tip-first in the trainer's facing direction. Party peers show chosen names at a compact scale. Each realm has separate exploration/reveal/marker coordinates and a visible selector; no cross-realm marker bleed.

The map begins with Grandpa's Village and roads revealed. An NPC who names a place can reveal it through fog. Players can add, name and remove personal markers. The map is not a creature radar and does not itself grant fast travel: the only fast travel is the Home Key to the Crossing Hall (§11) and a portal from the Hall to the last activated waystone (§12) (owner, 2026-09-29, RD-18, RD-19). Activated waystones, the current return waystone per biome and signposted Masters show as distinct markers. Debug teleport is development scaffolding and absent from a normal release flow.

The Pond alpha receives a marker at about **300 m** once learned; that marker persists until the alpha is caught or defeated. The doorstep alpha remains optional and legally catchable. Each relay grunt exposes its owned shutdown point, and the authored “defeat all Meadows trainers” objective reports stable trainer identities rather than inferring completion from a raw count.

Critical wayfinding uses four aligned channels: landmark composition, road/route grammar, NPC language/map reveal and the current-objective beacon. A continuous observed player must still understand where to go when one channel is briefly hidden. Completion telemetry proves arrival, not comprehension.

Task presentation remains finite: one main story line, authored local chains, three bounties per morning (§17.2) and a bounded transient event feed. No generic branching quest engine, abandon timers or indiscriminate unseen pins are in minimum scope. **Superseded (owner, 2026-09-29, RD-31):** the former exclusion of a repeatable daily list; the bounty board is that list, capped at three. Rewards and flags commit exactly once; a map pin is derived presentation, never the authority that grants completion.

Ordinary wild sites follow WORLD §2.5: they may repopulate after two world days and a full-party exit from their principal region. Do not show a precise countdown or imply that a named alpha, trainer, reward or permanent resource returns. The map/journal may describe a habitat as living without promising a specific creature. A re-entering peer sees the host's same current site state; save/reload does not flash a premature spawn.

## 8. ROG Ally legibility and accessibility

**The 7-inch rule (target, F42#2, #3):** everything the player must read, on the HUD or on any screen, is read on a seven-inch handheld at arm's length. Every new HUD element and screen is captured at native **1920×1080** and at **1280×800**, and a code-blind 7-inch device-profile judge passes both (ACCEPTANCE §6.1 device profile). The raster floors below apply to the smallest of those captures and to the 1280×720 stress raster. If a screen fails, it gets fewer items per page or a scroll, never smaller text.

At the 1280×720 stress raster (and at least equivalently at native 1920×1080 and 1280×800):

- essential body text is at least **18 px**, primary prompts/buttons **20 px**, headings **24 px**, and critical changing numbers **22 px**;
- a focused action target is at least **44 px** high and uses a minimum **2 px** visible focus edge or equivalent filled state;
- primary text on a stable panel targets **4.5:1** contrast; large/iconographic state targets at least **3:1**; text over the world uses an opaque/translucent plate or the established outline/shadow treatment;
- critical content respects a **32 px** final-pixel safe inset; no required prompt is cut by 16:9 overscan or UI scaling;
- labels wrap or scroll by focus; they never shrink below the floor to fit;
- type, rarity, danger, valid/invalid and player identity do not depend on colour alone.

The established logical UI token scale (19/23/26/28/32/42/56) remains a starting system, but acceptance measures the final raster, not authored logical pixels. Test the Satchel, Creatures detail, crafting owned/needed list, map, Settings, combat and four-player HUD, and every new screen (Altar, stations, gear, research, bounty board, Shrine Room, portal prompts, graphics presets, old-save refusal), at 720p and 1280×800 with maximum expected names/counts.

Interaction regression checks are explicit: inventory-full use refuses with the item/count and a recovery action; Stamina Shroom names the stat it actually changes; every creature skill/power-move description fits or scrolls at focus without hiding cost/effect; the team HUD keeps the same player-defined order on combat entry; ground mounts preserve sprint, jump, dismount and legal remount with rider/saddle alignment visible. Small Potion's current 50 HP result is acceptable only with the substantially increased availability promised by opening/road supply; if earned play still strands the player, increase healing or supply rather than hiding the shortage in text.

Accessibility minimum:

- remap every gameplay action for controller and keyboard/mouse, with immutable access to navigation/reset;
- adjustable look sensitivity and inversion per axis;
- subtitle/dialogue text size and background opacity;
- reduced motion that lowers camera impulse, UI animation and nonessential flashes without changing host combat timing;
- camera shake 0–100%, default modest;
- aim-assistance strength/off as an individual setting, never attack bending;
- controller rumble 0–100% with Off, and damage numbers On / Own only / Off (target, §18);
- distinct icon/shape reinforcement for type and warning colours;
- separate Master, Music, Ambience, SFX, Creatures and UI volume controls;
- a “reset controls” action accessible even after a bad remap.

Glyphs use the last input device and the player's current binding. The current `input_glyph.gd` last-device behavior is built, and icons follow rebinding: a rebound action draws its new button, or names it in text when the vendored pack has no art. Avoid simultaneous keyboard/controller legends except inside the Controls screen where comparing bindings is the point.

## 9. Input collision and validation contract

`data/config/input_contexts.json` is the machine-readable context inventory. Every action appears in at least one context. Tests fail if two live actions share a button/axis unless they are an explicit same-verb alias. World Y/Satchel and combat Y/Charged are valid reuse because the contexts are exclusive. World A/Jump, combat A/Burst and menu A/Confirm follow the same rule, as do world B/quick slot 1 and combat B/Utility, and world d-pad quick slots and combat d-pad Tether Commands. X interaction, build place, Orb release, revive start, portal/arch, waystone, pedestal and station interaction require a single owner at a time. The `ultimate_armed` latch consumes exactly one following face press and expires on its window, on switch, stagger, aim or context change; it never fires from a press that was already down when RB was tapped. The Home Key raise owns input for its duration and releases it on arrival, cancel or refusal.

The input harness must refuse a press absent from the live context. Runtime readers consult the same input-owner state before polling. Every new interaction provides tests for default binding, rebinding, context entry/exit, no double-fire and prompt accuracy. A context transition clears buffered presses so the press that closes one screen cannot attack, place or confirm behind it.

## 10. Current implementation matrix

| Feature | Baseline | Target/disposition |
|---|---|---|
| World controller map/hotbar | **Built foundation.** Five assignable slots and context machinery exist; current readers still need an owner-map audit. | Restore R3 target/lock, remove world LT Build ownership, preserve hammer-as-hotbar/X priority, and convert sprint/fly behaviors that still depend on hold semantics. |
| Combat inputs | **Partially built.** RT/LT, A burst, LB, RB/X and aim exist. | **Retargeted (owner, 2026-09-29, RD-11, RD-12):** X/Y/B slots, RB-latch ultimate, d-pad Tether Commands, LT aim, RT flee (§2.2); preserve attack timings and prevent held repeat. The Y skill target is superseded. |
| Combat HUD meters | **Not built.** Energy fill and target panel exist. | Move cluster, ultimate ring, command bar and damage-number setting (§3.2, §18); F42#2. |
| Home Key, portals, waystones, Shrine Room | **Not built.** | §11–§13; F18, F31#2. |
| Altar, stations, gear, forward camp, pouch | **Not built.** Craft panel, bed and camp screens exist. | §14–§16; F23#3, F27, F28, F30, F31, F33, F34, F42#1. |
| Research log, bounty board | **Not built.** Quest log tab exists. | §17; F43, F45. |
| Graphics presets | **Not built.** Settings shell exists; renderer is Compatibility. | §18; F26#1. |
| Old-save refusal | **Not built.** Saves up to v27 migrate today. | §19; F16#0. |
| New-system lessons | **Not built.** | §6.1; F46. |
| Menus/rebinding/glyphs | **Built foundation.** Data menu, controls UI, last-device tracking and UI tokens exist. Settings → Accessibility holds reduced motion, camera shake 0–100% (default = the tuned 0.65° charged roll), look sensitivity (25–200%), per-axis look inversion, aim assistance Full/Reduced/Off (throw help only), and dialogue text size (100/125/150%) and background opacity (`motion_prefs.gd`, `look_prefs.gd`, `text_prefs.gd`), all pad-reachable and saved. | `input_glyph.gd::icon()` now draws the rebound button (or names it when no art is vendored); complete 720p and accessibility validation. Every §8 accessibility-minimum setting now exists; 720p fit and on-device review remain. |
| Co-op revive | **Partial:** tap-start 3 s proximity, 0.3 m horizontal deadzone, 2.5 m radius and 45 s window implemented; two-peer smoke passes. | Keep recovery baseline. Add host validation to the inherited direct-peer completion protocol and complete downed-player progress presentation; do not claim the old code was host-authorized. |
| Bond | **Built baseline.** Unordered five tasks at 50 wild/3 new global/4000/4 bed nights/10 feeds. | Migrate to 20 all-victory/3 per-creature landmarks/4000/3 rests/5 nourishment-separated feeds; preserve earned nodes. |
| Strain | **Not built.** No live strain field/config consumer. | Add bounded 0.25 rule through SYSTEMS/CREATURES, then expose consequence and recovery. |
| Creature beds | **Partially matches target.** 120 s healing and night completion exist. | Ensure only bedded creatures clear HP/strain; unbedded state unchanged; update messaging/tests. |
| Wayfinding/map | **Substantial built foundation.** Beacon, realm map, markers/reveals and peer presence exist. | Observed-player comprehension remains unaccepted; verify headings, 300 m persistent Pond-alpha marker, relay/trainer objectives and activity packaging. |
| Onboarding/readiness | **Broad sequence built, experience unaccepted.** First camp uses one bed; the journal and Halda then require three for first tournament entry. | Preserve exact one-time kit; prove earned three-bed preparation, shelter, level/feed/rest guidance and bracket retry/recovery at720p/1080p; add the Home Key handover and §6.1 lessons. |

## 11. Home Key (target, F18; owner, 2026-09-29, RD-18)

Grandpa gives each character a Home Key during the opening (§6.1). It sits in the Satchel's key category, can be assigned to any quick slot, and cannot be dropped, sold, traded or lost in a death satchel (F18#0). It is free and has no cooldown.

**Use flow (one tap, F18#1):**

1. The player taps the Home Key's quick slot, or chooses Use on it in the Satchel (the Satchel closes).
2. The client checks the refusal list below and, if clear, sends `home_key_use {request_id}` to the host. The host validates the same list. A refused request shows one line and a quiet error cue, rate-limited to once per 2 s.
3. `input_owner` passes to `home_key_raise`. The trainer raises the key for ~2 s (starting value, `data/config/portals.json`) with a building glow and sound. A ground mount is dismounted and the out creature recalled at the start. B cancels at no cost. If an encounter admits the player during the raise, the raise cancels with no cost.
4. The screen fades; the realm transition shows "Crossing Hall" and visible progress (§2.4 rule).
5. The trainer arrives at the Hall's home arch, is safely seated, and input returns to the world context.

**Refusals (owner list, RD-18), each with its stated reason:**

| State | Line shown |
|---|---|
| Combat (any encounter the player is in) | "Not during a fight." |
| Dialogue | "Finish the conversation first." |
| Cutscene | Silent; the press is not delivered. |
| Swimming (human or on a swim mount) | "Reach solid ground first." |
| Mid-flight | "Land first." |
| Downed in co-op (extension of the owner list; the player cannot act) | "You can't use it while down." |

**Co-op:** each player has their own Home Key and it moves only that player and their own creatures (F18#4). The host validates and performs the transfer into the session's Hall. Peers see the raise and light; no peer is pulled along. No other state changes: nothing is saved as a travel receipt, and the key is never consumed.

## 12. Crossing Hall: arches, keys and waystones (target, F17, F18, F20)

The Hall's nave holds the home arch and seven portal arches: Tidewake, Cloudreach and Stormwood live-capable, four sealed (owner, 2026-09-29, RD-17). Arch prompts use the ordinary X interaction and the `portal_arch` context.

### 12.1 Arch states and prompts

| Arch state | Prompt / line | A press does |
|---|---|---|
| Home arch | "Home arch" (no action) | — |
| Live, locked, no key | "Tidewake · Recommended Lv 20 · Needs the Tidewake Portal Key" | nothing; the line is the answer (F18#2) |
| Live, locked, key held | "Use Tidewake Portal Key" | consumes the key once, unlocks the arch permanently for this character (and the host world), plays the unlock moment, then shows the open prompt |
| Live, open | "Enter Tidewake · Recommended Lv 20 · to <waystone name>" | realm transition to the character's last activated waystone in that biome, else the biome entry (RD-19) |
| Live, open through the host's world only | as above, plus once: "Open in this world. Your own key opens it in other worlds." | same; no permanent unlock is written for this character (F48#3) |
| Sealed (biomes 5–8) | "Sealed" on inspect only | nothing; no repeated refusal |

The recommended level comes from the portal sign data (F19#5). A team below it gets the same prompt with one caution line; there is no hidden level gate. The arch's glow state (sealed, locked, open) reads by shape and light as well as text.

### 12.2 Waystones (owner, 2026-09-29, RD-19)

A waystone activates on touch, with no press: a moment banner "Waystone awakened: <name>" the first time, and the map marks it. Touching any activated waystone makes it that biome's return point; the feed shows "Return point: <name>" (rate-limited). An X press at a waystone shows its name and "Portals from the Hall bring you here." Waystones do not teleport between each other. Activation and the return point are character-scoped, host-validated and persist through reload (F18#3).

### 12.3 The fifth arch (owner, 2026-09-29, RD-22)

With the fifth portal key held, the fifth arch prompts "Use the fifth key". The first use plays the stir (glow, low hum, dust) and one line from Grandpa or the Hall's resident meaning "not ready yet" (F20#2). It never opens, adds no quest, marker or sequel prompt. Later presses show "The arch is quiet." Whether the fifth key is consumed or kept as a keepsake is WORLD's call.

## 13. Shrine Room: hang a relic, choose a power (target, F31#2; owner, 2026-09-29, RD-20)

Eight pedestals: four live, four sealed. At a live pedestal with that biome's relic in the Satchel, X prompts "Hang <relic>". Hanging plays a moment banner naming what it unlocked: "<Biome> station upgrades unlocked: <Forge attachment>, <Kitchen attachment>, <Altar attachment>, <Den attachment>" (HOMESTEAD owns the names). The hang is character-scoped and host-validated with a transaction id; the relic item moves to the pedestal once and cannot be hung twice.

The relic power screen (`shrine` context) then opens, and can be reopened at any pedestal outside combat: it lists hung relics with their power in one line each, marks the active one, and A makes the focused relic active (the existing one-active rule; the power selection moves here from its former place). B closes. What each pedestal *displays* to peers follows MULTIPLAYER's shrine-state rule (F17#5).

## 14. Altar (target, F23, F27, F28, F29, F30, F42#1; owner, 2026-09-29, RD-03, RD-06, RD-11, RD-28, RD-30)

The Altar is a homestead station screen (`altar` context). A left column lists the five in party order; the right shows the focused creature. LB/RB change tabs. A guest uses the host's Altar at the host's attachment tier and spends their own items (RD-21); the header says "Host's Altar · <tier>". Every spend shows a host-pending state until acknowledged, and never applies twice. TRAINING owns every rule and number below; this section owns presentation.

| Tab | Shows | Verbs |
|---|---|---|
| **Level** | level, XP to next, cap; owned essence of each payable type; cost of the next level; Tether Candy count. At cap: "Breakthrough needed: <Master>, <place>" with "Show on map". | A spends one level (one press, one level; repeated presses allowed; no hold-to-repeat). Left/right on "Pay with" chooses the essence for dual types. X spends one Tether Candy on one level. |
| **Breakthrough** (shown only when capped and a matching feast is in the Satchel) | the feast and the tier it lifts | A feeds it. Where an evolution line exists, the evolve-or-stay panel opens: two cards (current form, evolved form) with silhouette, name and stat change, and the line "Staying is permanent for this tier." Both choices need one confirm. |
| **Loadout** | quick, charged, utility and ultimate slots; each known move's damage, cost, cooldown, effect and mastery rank | A on a slot lists legal moves for it; A equips. The ultimate slot is read-only and shows its breakthrough tier. |
| **Traits** | rolled traits (0–3) with rarity by icon and text; taught-trait slots, locked ones labelled "Unlocks at the L10/L30/L50 breakthrough" | A on an open slot lists Trait Seeds; the teach confirm shows the essence cost. |
| **Mastery** | each known move's rank 1–5, progress to next, what the next rank changes | view only |
| **Release** | payout preview (essence by type) and the creature's traits | A starts release; the player picks one trait to distil (or none); a destructive confirm names the creature and nickname: "This can't be undone." |

A forward camp's bed or field workbench offers the Loadout tab only (F23#3, F34#2).

## 15. Homestead stations, forward camps and the pouch (target, F31, F34; owner, 2026-09-29, RD-15, RD-16)

### 15.1 Station panels

Workbench, Forge, Kitchen, Den and Farm plots share one panel layout (`station` context); chests keep the container screen. Each panel has:

- a header: station name and its built attachments as icons (live biomes only; reserved tiers are not shown);
- **one "Next upgrade" line** at the top (F31#3), always a single target: "Next upgrade: Smoker. Hang the Tideglass relic.", or "Next upgrade: Smoker. Driftwood 6/8 · Tidesteel ingot 2/4", or "All upgrades built." Workbench and Farm, which take no attachments, show their next unlockable recipe instead. No tech-tree screen is required;
- the recipe list, filtered to the station's tier, with locked recipes shown dim with their reason ("Needs the Smoker");
- the §2.4 crafting detail: selected recipe, owned/needed counts, action state and the reason a disabled action cannot run.

Timed work (smelting, cooking) is tap-start with a visible progress bar that continues while the player stays at the station, the same proximity pattern as revive (§2.5); leaving or B stops it, as HOMESTEAD defines. Nothing runs while the player is away (F31#4). A guest's panel header reads "Host's Forge · <tier>"; the output goes to the guest's own Satchel (F31#5).

The Den panel offers rest, grooming (shed drops appear in the feed) and the gear display. Farm plots use per-plot X prompts: plant (a type-crop picker), tend and harvest, each one press.

### 15.2 Forward camps

The field workbench panel carries a "Travel tier" badge. Recipes above travel tier show dim with "Needs the <station> at home" (F34#1). The bed offers rest, save and the Altar's Loadout tab.

### 15.3 Trainer pouch

The pouch holds the items the Item throw command uses (COMBAT §10). In the Satchel, L3 "Assign" offers the five quick slots and the pouch slots (1–3 by trainer gear tier). The Satchel shows the pouch as a short row under the quick bar. Pouch assignment, like quick-bar assignment, never moves or consumes the stack.

## 16. Gear (target, F33, F42#1; owner, 2026-09-29, RD-14)

The Creatures tab's Gear panel shows each creature's Harness and Charm slots: item, tier (Rootiron, Tidesteel, Skyglass, Stormglass), upgrade +1 to +3, the stat change against the currently equipped piece, and a preview of the accent on the creature. Equipping is one press and happens where HOMESTEAD permits; elsewhere the verb shows its reason. The trainer's Equipment panel lists trainer gear with one line per hazard it covers ("Storm static: protected") and the Tether Command upgrades it grants (meter rate, pouch size, snare strength). All gear is personal in co-op.

## 17. Research log and bounty board (target, F43, F45; owner, 2026-09-29, RD-31)

### 17.1 Research log

A journal tab (`research` context) with biome tabs in play order. Each biome lists its species with seen and caught state; focusing one shows its three or more tasks with progress counts and the essence each pays, and ticks paid tasks. Each biome shows its completion percentage and, at 100%, its title. Released and never-kept creatures count (F45#2). No task hints at an unseen creature's location; the log is not a radar.

### 17.2 Bounty board

Halda's board in the village (`bounty_board` context) shows three cards each in-game morning, drawn from unlocked biomes (F43#0). A card shows its kind (catch with a trait, defeat an alpha, deliver materials, win a rematch), target, biome, reward and progress. All three are active for the character once posted; there is no accept step. Completed cards show "Claim" and pay at the board with A (starting behavior); deliveries show owned/needed counts and consume on claim. Claims are host-validated per bounty instance and pay once. Before dawn the board says "New bounties at dawn." The journal lists active bounties; they never replace the main objective line. Bounties are personal in co-op.

## 18. Settings: graphics presets and combat feedback (target, F26#1, F21#3; owner, 2026-09-29, RD-25)

**Graphics** (`graphics_settings` context, Settings → Graphics):

| Control | Values | Notes |
|---|---|---|
| Preset | Low, Medium, High, Custom | Low is the Compatibility renderer. Medium and High use the Forward+ path. Changing any toggle below selects Custom. |
| Volumetric fog, SSAO, SSIL, Glow | On/Off | Forward+ only; on Low they show dim with "Not available on Low". |
| Shadow quality | Off, Low, Medium, High | |
| Draw distance | Near, Normal, Far | LOD distance. |
| Frame-rate overlay | On/Off | Needed for the owner's ROG Ally test. |

Switching between Low and Medium/High changes renderer and needs a restart: the screen says "Applies after restart" and offers "Restart now" or "Later"; it never restarts silently. The setting persists per device, not per character, and is never sent to peers. The shipped default stays the current renderer until the owner's Ally test passes (Medium handheld ≥30 fps, 40 preferred; F26#5). Values live in `data/config/art.json` or the preset file F26 chooses.

**Combat feedback** (Settings → Accessibility, beside the built camera-shake and reduced-motion controls): damage numbers On / Own only / Off; controller rumble 0–100% with Off; ultimate input "RB then face" (default) or "RB alone"; Tether Command layout "D-pad" (default) or "LB then face" (§2.2).

## 19. Old-save refusal (target, F16#0; owner, 2026-09-29, RD-35)

Saves from v27 and older are refused, not migrated; this is an owner override of the migration rule for this redesign only. On the title screen, loading such a save opens the `old_save_refusal` panel:

> **This save is from an older version**
> Tetherbound was rebuilt, and saves from before this update can't be loaded. Your old save file is kept, untouched.
> [Start a new game] [Back]

"Start a new game" has initial focus and starts a new game in a fresh slot; it never writes over the refused file. "Back" returns to the title. The save list labels such a slot "Older version". A co-op join that presents a v27-or-older portable character is refused with the same wording ("This character is from an older version and can't join.") and offers character creation. The refusal never crashes, never deletes and never overwrites. Migration discipline resumes for every later format change.

## 20. Out of scope

- Held-button combat, revive, radial menus or hidden chords.
- Human attacks, autonomous companion command wheels or a sixth emergency fighter.
- Touch-first/mobile layouts, motion controls or platform-specific PlayStation glyph production for minimum Windows release.
- Creature radar, release-build debug teleport or unrestricted fast travel (the Home Key reaches only the Hall; portals reach only the last waystone; waystones do not link to each other).
- Generic branching quest engine or every pickup as an objective. **Superseded (owner, 2026-09-29, RD-31):** the exclusion of a daily/repeatable task board; the bounty board (§17.2) is in scope at three per morning.
- A tech-tree screen for stations, a mastery skill tree or a trait-crafting screen.
- A continuous affection meter replacing named bond tasks.
- Night/unrested strain multipliers, revive-added strain, starvation warnings or passive bed XP.
- Treating telemetry as proof that a player understood, cared or chose voluntarily.

## 21. Recovery dispositions

- **S06/S17/S20 and D14/D15/D28/D33/D68/D89:** retain slot/hotbar, finite task feed, one map database, data menu, remaps, shared UI tokens, explicit contexts and harness refusal.
- **S12/S13:** retain mandatory Grandpa/name/catch opening and its intro-only anti-deadlock guarantees; do not convert temporary safety floors into global systems.
- **S14/S16:** retain starter traversal promises (now Ride, Swim with Dive at L30, Fly; RD-32), visible pre-choice explanation and persistent saddle. **Superseded (owner, 2026-09-29, RD-17):** physical-gate limits between biomes; portals replace them. Traversal input obeys the no-hold policy except Fly (owner, 2026-09-27).
- **DR02/D70/D76:** current bond is unordered despite stale headers. The revised targets above supersede baseline calibration while preserving earned nodes; CREATURES owns migration.
- **DR07/D75/D79:** gatekeeper refusal is in-fiction, uses highest creature and tells the remedy; it is not a floating UI lock.
- **DR08/D32/D68:** retain explicit L3 sprint, R3 target/lock, LB switch, X interact/throw/place in the world, Y world Satchel, B/D-pad world quick slots, hotbar hammer/catching and no auto-switch/held selector. LT/RT do not become a direct world-build shortcut. **Superseded in combat (owner, 2026-09-29, RD-11, RD-12):** combat Y skill, RB flee, X orb aim and B/d-pad consumables; see §2.2.
- **DR22/D81/D87:** retain faction plate/actual speaker/player-readout exceptions and mask-only hair treatment in dialogue presentation.
- **DR23/D89:** context-valid press evidence and runtime ownership are required; a binding's existence alone proves nothing.
- **B19:** retain five skills, level/progress/source/benefit/cap display and first-Cloudreach reveal; exact mechanics live in SYSTEMS.
- **B27/B30:** retain companion/pickup readability, roster-pressure team details and no-free-hotel staging; old pixel/distance samples require current-camera validation.
- **Owner recovery:** restore full world/build/menu/combat controller contexts, tournament consent, map reveal/markers, party-order stability, no message spam and Ally readability. Replace held co-op revive explicitly rather than treating it as a hard-rule exception.
