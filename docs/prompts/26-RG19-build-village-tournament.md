# RG19-build — Build the early village tournament

## Goal
Implement the owner-approved local tournament as the Meadows' first major progression gate, using RG19-spec's canonical creature-condition model.

Player loop:
**catch/build a full five-creature team -> train and care for them -> qualify -> enter the village tournament -> fight through a small bracket -> win coins -> receive the story nudge that sends you toward Team Tether / the eastbound bridge route.**

## Dependency
Read and obey the RG19 condition decision produced by `25-RG19-spec-creature-condition-model.md`. If it has not landed, do not invent rested/fed/happy semantics inside this task.

Also integrate with RG16/RG18 objective state rather than building a parallel quest chain.

## Owner decisions — locked
- Tournament is near the beginning in Grandpa's village.
- Player should gather **five creatures** for it; five is also the game's permanent ownership cap.
- Creatures must be trained and in suitable condition: rested, fed, happy.
- Level requirement exists as a tunable readiness threshold; the owner's original "level 3 or something" explicitly left the number flexible.
- Winning pays coins and sets the player on the way to fight Team Tether.

## Tournament organizer / entry flow
Use an existing/reused village NPC rig and normal dialogue system. The organizer should:
- explain the tournament and requirements when first encountered;
- show a clear readiness summary rather than a vague "not ready" refusal;
- point the player toward actions that fix each failure;
- allow entry immediately once the shared readiness query passes;
- never require owning more than five or storing creatures elsewhere.

Do not bury the requirements only in dialogue; RG19-spec's team UI must also expose them.

## Eligibility
Create one authoritative data-driven readiness check used by both UI and tournament registration. At minimum it checks:
- party/ownership count = 5;
- each entrant meets the tunable minimum level;
- each entrant satisfies rested/fed/happy per RG19-spec;
- no entrant is in an invalid state such as fainted if the condition spec says that disqualifies them.

Never duplicate the thresholds in organizer dialogue, quest code and tournament code.

## Bracket
Use the **smallest coherent local tournament bracket** that feels like an event and exercises trainer combat more than once. Prefer existing trainer/battle infrastructure and Meadows species. Bracket size, teams and levels are data/TUNABLE; do not create a tournament-specific combat engine.

Requirements:
- sequential trainer battles with clear between-round state;
- normal trainer-owned-creature rule: they cannot be caught;
- defeat/retry behavior is understandable and does not permanently brick the tournament;
- if recovery between rounds is intended by existing trainer flow/spec, make it explicit and data-driven; otherwise do not silently full-heal the party;
- bracket progress persists if the player saves/exits at a supported break point, or deliberately restarts the current tournament run if that is the simpler documented rule. Do not leave ambiguous half-state.

## Reward / story handoff
On first victory:
- grant a meaningful coin reward through the existing inventory/currency system;
- set one persistent tournament-victory progression flag;
- update RG16/RG18 objective spine to the post-tournament **head toward the bridge / Team Tether route** state;
- appropriate NPC dialogue acknowledges the win and points outward;
- reward cannot be farmed repeatedly unless repeat tournaments are explicitly built later.

Do not duplicate the bridge/pylon logic owned by RG16/RG17/STORM-GATE.

## World presentation
The tournament should read as a real village activity, not a menu teleport detached from the world. Reuse village architecture/arena-capable open space if suitable; author only the minimum dressing needed. No new human meshes. Use current UI/theme and controller-first interaction.

## Preserve
- real-time piloted creature combat;
- no human fighting;
- no shields/dodge addition;
- five-creature cap;
- trainer creatures cannot be caught;
- existing trainer reward/progression systems;
- save versioning;
- RG16/RG18 objectives.

## Edge cases
- player arrives with fewer than five;
- five owned but one under-level;
- condition failure on one or several creatures;
- creature faints just before registration;
- player qualifies before first talking to organizer;
- save/load before entry, between supported rounds, after loss, and after victory;
- repeated interaction after victory cannot pay the first-clear reward again.

## Acceptance criteria
1. Tournament is discoverable in/near Grandpa's village and tied into the current objective system.
2. Five-creature readiness is evaluated from one shared source.
3. Player can see exactly why they are/aren't eligible.
4. Eligibility responds correctly to training, feeding, resting and happiness changes.
5. Player can enter and complete a multi-battle local bracket using existing combat systems.
6. Tournament progress/retry behavior is deterministic and documented.
7. First victory grants coins exactly once.
8. Victory sets persistent progression and advances the main objective toward Team Tether/bridge.
9. Save/load does not duplicate rewards or regress to pre-tournament objective.
10. Fully controller-operable on Ally.

## Testing / verification
Add focused tests for readiness combinations, first-clear reward idempotence, tournament victory flag/objective handoff, save/reload, and trainer catch prohibition. Run trainer/combat/progression/save tests. Drive controller interactions with real InputMap joypad events where UI is involved. Capture the organizer/arena/event presentation and run visual review.

## Definition of done
A new player can understand the goal, build and care for a five-creature team, prove that team in a village tournament, receive a tangible reward, and then be clearly sent into the Meadows' Team Tether progression.