# RG16 — Tournament-first objective and eastbound progression

## Goal
Fix the player's lack of direction by giving the Meadows a clear, persistent objective spine that matches the owner's current intended progression:

1. After the opening, the player's first major goal is **prepare a team for the local village tournament**.
2. The player gathers/catches enough creatures and prepares them for tournament entry.
3. The tournament itself is implemented/spec'd under RG19; RG16 must not duplicate its bracket, condition, or reward systems.
4. **After the tournament is won**, the major objective changes to heading east toward the bridge / Team Tether route.

The player should always know what their next major goal is and where that goal is taking them without needing a giant waypoint beam or GPS trail.

## Owner decisions — locked

- The bridge is **not** the first post-opening destination.
- First major goal: **gather enough pals/creatures to fight in the local tournament**.
- The tournament is in/near Grandpa's village and is the early-game proving ground.
- Current RG19 direction already records the owner's intended tournament shape: catch five creatures, prepare them, enter, win coins, then set out against Team Tether. Treat the exact tournament entry thresholds and creature-condition rules as RG19 scope, not RG16 scope.
- Once the tournament is won, the major journey objective becomes **head east toward the bridge / Team Tether route**.
- Navigation should be reinforced by dialogue, HUD objective text, map/minimap objective state, the road, and later RG17's tether-pylon navigation spine.
- Do **not** add a giant floating waypoint beam or magical GPS breadcrumb trail unless an existing system already does so and the owner has explicitly approved it elsewhere.

## Current problem
The opening currently gives the player the high-level fiction (Team Tether, strongholds, pylons) and eventually says the dirt road "goes where you're going," but the player has no concrete early-game destination or milestone. The original RG16 note suggested "head east to the bridge," but the owner has now clarified that this skips an important early progression beat: building a team and competing in the local tournament.

This newer owner decision supersedes the earlier bridge-first wording.

## Relevant current systems / files to inspect
Before changing anything, inspect current `main` and use existing systems rather than creating parallel state:

- `data/dialogue/opening.json`
  - `grandpa_house`
  - `grandpa_named`
  - `grandpa_road`
- `scripts/world/quest_log.gd`
- current HUD objective presentation
- `autoload/map_state.gd`
- `scripts/ui/minimap.gd`
- `scripts/ui/tab_map.gd`
- current objective/dynamic marker handling in map state
- progression flag store (`autoload/progression_state.gd` / `Game.progression`)
- tournament planning/backlog item `RG19`
- `docs/CURRENT_STATE.md`
- any existing tournament/arena/NPC work that has landed since this prompt was written

## Desired player-facing progression

### Phase A — opening/tutorial
Grandpa still establishes the broad mission against Team Tether and gives the starter/tutorial handoff.

Do not overload the first conversation with tournament mechanics before the player even has a creature. The opening can foreshadow the village tournament, but detailed entry requirements should be introduced only when they become actionable.

### Phase B — first major objective: prepare for the village tournament
After the player has completed the initial starter/first-catch handoff and the game enters free play, the major objective should clearly become something equivalent to:

> **Prepare for the village tournament**

A useful supporting/sub-objective can communicate the immediate action, e.g.:

> **Build a full team**

or, if RG19 has already locked five as the entry roster:

> **Catch five creatures for your team**

Do not hard-code a duplicate numeric requirement in RG16 if RG19 owns the authoritative entry rule. Prefer querying the tournament-entry state or sharing one data source if that implementation exists by the time this is executed.

### Phase C — tournament registration / readiness
The objective system should naturally hand the player toward the village tournament once they are eligible or near eligibility.

Examples of acceptable objective evolution:

- `Prepare for the village tournament`
- `Build a team for the village tournament`
- `Meet the tournament organizer`
- `Enter the village tournament`

The exact wording can follow existing voice/UI conventions, but the hierarchy should be clear: first prepare, then enter.

RG16 does **not** define the full rested/fed/happy gate, bracket, rewards, arena flow, or battle sequence. Those belong to RG19. RG16 only needs to surface the correct current objective state and route the player to the tournament content when appropriate.

### Phase D — after tournament victory
Winning the local tournament becomes the moment the Meadows' wider adventure visibly opens.

At that point:

- major objective changes to something equivalent to **Head east to the bridge**;
- Grandpa and/or the tournament organizer can reinforce that Team Tether lies along that route;
- the map/minimap objective marker should now point toward the relevant eastbound destination using the existing dynamic objective marker system;
- the road should physically support that route;
- RG17's tether pylons should later reinforce the same direction as an in-world navigation spine.

This is the correct place for the original RG16 "head east to the bridge" idea — **after** the tournament, not immediately after the opening.

## Dialogue requirements

### Grandpa
Revise only what is necessary. Preserve his established voice: warm, brief, urgent, not exposition-heavy.

The post-opening dialogue should make the tournament feel like the player's sensible first proving ground rather than a random side activity.

Conceptual intent, not mandatory final wording:

- You are not ready to march straight at Team Tether with one creature.
- Build a proper team.
- The village tournament is where young trainers prove they can handle one.
- Win there, then take the east road toward the bridge.

Do not turn Grandpa into a tutorial manual listing every tournament requirement. The tournament organizer/NPC should own the detailed eligibility explanation once RG19 implements it.

### Tournament NPC / organizer
If RG19 already provides an organizer, reuse that NPC. If not, RG16 may only create the minimum objective hook needed to point toward where RG19 will attach; avoid fully authoring tournament content here.

The detailed entry rules should be explained where the player tries to enter, not buried in Grandpa's opening speech.

## Objective/HUD behavior

The player should have one clear major objective at a time.

Required progression state:

1. Opening/tutorial beat objective(s).
2. `Prepare for the village tournament` once free play begins.
3. Tournament-entry objective once preparation requirement is met.
4. Tournament active / win objective as appropriate to existing quest architecture.
5. `Head east to the bridge` after tournament victory.

Use existing objective/quest state machinery where possible. Do not create a second quest framework for RG16.

The objective must persist through save/load and must not regress to an earlier objective after reload.

## Map/minimap behavior

Reuse the existing objective marker path.

During tournament preparation:

- If there is a useful tournament location/organizer marker, surface it without making the player feel forced to stand there while still gathering creatures.
- If the player is simply being asked to build a team, the HUD text itself may be more important than a constantly pinned location.

Once the tournament is won:

- objective marker should point to the appropriate eastbound bridge/route destination;
- it must use the same map state that RG15's minimap/full map read;
- do not duplicate coordinate sources.

RG15 separately owns minimap orientation and full-map zoom/pan; do not reimplement that here.

## Relationship to RG19

RG19 is the authoritative tournament-mechanics item.

Current owner-approved concept recorded in backlog:

- local village tournament near the beginning;
- catch five creatures;
- level/prepare them appropriately;
- well rested / well fed / happy condition matters;
- tournament victory gives coins;
- winning sets the player on their way to fight Team Tether.

RG16 should integrate with this state but **must not silently hard-code RG19's still-tunable numeric thresholds**.

If RG19 has not landed yet, implement RG16 with clean progression seams/flags that RG19 can satisfy later, and document the dependency rather than inventing tournament mechanics inside RG16.

If RG19 has landed, inspect its actual flags/API and use them directly.

## Preserve

- Existing opening beats and starter choice flow.
- Grandpa's established voice and urgency.
- Existing quest/objective framework.
- Existing map/minimap data source and objective marker system.
- Save/load persistence of progression.
- The later bridge/Team Tether route.
- The five-creature cap fiction.
- The rule that RG19 owns tournament mechanics and creature-condition thresholds.

## Do not

- Do not send the player directly to the bridge immediately after the opening.
- Do not make the tournament feel optional if it is the intended first major progression gate.
- Do not add a giant floating waypoint beam/GPS trail.
- Do not build a second quest system.
- Do not duplicate tournament eligibility logic in objective code.
- Do not invent permanent numeric thresholds for level/rest/fed/happy in this item.
- Do not break save/load by making objective state purely transient UI state.

## Edge cases

- Player catches enough creatures before talking to the tournament organizer.
- Player reaches the tournament location early with too few/unprepared creatures.
- Player leaves the village and explores before being tournament-ready.
- Player saves and reloads during preparation.
- Player saves and reloads after qualifying but before entering.
- Player saves and reloads after winning; objective must remain eastbound, not revert to tournament prep.
- Player has already met future RG19 entry requirements when the objective phase changes.
- Older saves from before this objective spine existed should migrate to the most appropriate objective based on existing progression flags rather than restart the opening.

## Acceptance criteria

1. On a new game, after the starter/first-catch opening handoff, the player receives a clear major objective to prepare for the local village tournament.
2. The early-game objective does **not** immediately tell the player to head east to the bridge.
3. The objective text remains visible/readable through the normal HUD/quest presentation.
4. Tournament preparation/entry state is derived from shared progression/tournament state, not a duplicated local boolean if RG19 provides one.
5. The player can understand that building a team is the next meaningful goal.
6. Once tournament victory is recorded, the major objective changes to heading east toward the bridge / Team Tether route.
7. The eastbound objective appears correctly on the map/minimap using the existing objective marker data path.
8. Save/load preserves whichever objective phase the player has actually reached.
9. Reloading after tournament victory cannot re-trigger Grandpa's earlier tournament-preparation instruction as the active objective.
10. Existing opening, starter, first-catch, map, and save regressions remain green.

## Testing / verification

At minimum:

- `test_dialogue_runner`
- `test_progression_state`
- relevant objective/quest tests
- relevant save/load tests
- relevant map-state tests

Add focused coverage for the progression sequence:

1. new game -> opening -> first catch -> tournament preparation objective;
2. insufficient roster -> objective remains preparation-oriented;
3. tournament eligibility state -> objective advances appropriately;
4. tournament victory flag/state -> objective becomes eastbound bridge objective;
5. save/reload in each phase preserves the correct objective;
6. old-save migration selects the correct phase from progression state.

Run an actual ROG Ally/controller playthrough of the handoff, not only unit tests. Verify that a player who knows nothing about the implementation can answer both questions at every stage:

- **What am I supposed to do next?**
- **Where am I supposed to go when location matters?**

## Definition of done

RG16 is done when the Meadows has a coherent first-goal-to-world-goal spine:

**starter / first catch -> build a tournament-ready team -> enter/win the village tournament -> head east toward the bridge and Team Tether**

and that progression is communicated consistently through dialogue, HUD objective state, map/minimap markers, and persistent progression without duplicating RG19's tournament mechanics.