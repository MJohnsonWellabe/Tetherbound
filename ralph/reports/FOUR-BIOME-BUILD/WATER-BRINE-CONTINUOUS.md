# Water Reedhaven-to-Brine continuous segment

Status: controller-only helper implemented; production-world traversal is
unproven and queued behind the playable-path full-world slot.

`tests/helpers/water_brine_segment.gd` accepts an already-running Water world
at the paid Reedhaven departure. It fails closed unless the repair is durable,
Tovin is undefeated, the production trainer/prompt/two-member team exist, and
the caller's campaign party has a healthy available active creature. It never
resets the game, moves an actor directly, grants a party member, repairs HP or
stamina, adds inventory, or writes a progression fact.

The helper drives this bounded production chain:

1. stow any held campaign tool through its controller hotbar action;
2. physically reach the repaired Reedhaven departure;
3. swim the authored 107.088m human-level sheltered route and land dry at
   Brine Steps;
4. walk the authored Brine Steps spine through points 1, 2 and 3, keeping the
   final approach to Tovin under 120m;
5. deploy the existing active party creature through controller recall;
6. physically reach a grounded Tovin challenge stance, win the real prompt
   through `InteractionArbiter`, and fight both authored level-46 opponents
   through directional and quick-attack input. The harness does not write ally
   position or orientation: production combat faces the ally when it consumes
   an attack, and the real movement input closes range;
7. require both `defeated_water_trainer_tovin` and the production WaterDocks
   completion `water_dock_brine_steps_trial_won`.

The Tovin NPC body resolves from Brine Steps centre `(420,660)` plus the reused
NPC offset `(9,23)`, not the unused trainer placement offset. Its XZ is
`(429,683)`. The selected spine point 3 is `(329.729,723.208)`, a 107.105m
horizontal approach. That is source geometry only; the baked grade, obstacles,
prompt offer and battle still require production runtime proof.

Focused checks cover the fail-closed result plus the exact authored route,
critical trainer identity, reused NPC, level, team size and species.

The optional opening composition `-- --through-brine` provides exactly the
five-species, level-44 party already used by the Stormwood continuous chapter
entry diagnostic, before Water world creation. It is a bounded synthetic carried
party, not an earned Stormwood save. It adds no Water flags/materials, pose, HP
or stamina, and performs no later party write. The default and Reedhaven-only
opening modes remain party-empty. Production runtime is still required; stop at
the first physical or combat defect rather than bypassing it.
