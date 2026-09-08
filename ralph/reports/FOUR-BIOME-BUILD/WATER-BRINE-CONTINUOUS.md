# Water Reedhaven-to-Brine continuous segment

Status: passed in the production opening composition. Reedhaven-to-Brine
crossing, the repaired graded Tovin approach, both authored opponents and the
durable Brine trial outcome all completed without a post-arrival fixture write.

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
4. walk the authored Brine Steps spine through points 1 to 5, retaining the
   graded route all the way to Tovin's pier-side placement;
5. deploy the existing active party creature through controller recall;
6. physically reach a grounded Tovin challenge stance, win the real prompt
   through `InteractionArbiter`, and fight both authored level-46 opponents
   through directional and quick-attack input. The harness does not write ally
   position or orientation: production combat faces the ally when it consumes
   an attack, and the real movement input closes range;
7. require both `defeated_water_trainer_tovin` and the production WaterDocks
   completion `water_dock_brine_steps_trial_won`.

The failed production run proved that Tovin's old reused-NPC placement at
`(429,683)` required an ungraded summit chord: the player stopped below it at
`(408.952,43.667,733.921)` with zero confinement resets. The prepared reused-NPC
offset puts Tovin at `(395,809)`, beside p5 and 22.29 m before departure. See
`TOVIN-APPROACH.md` for the passed production terrain, ordinary walking and
live-arbiter offer evidence.

Focused checks cover the fail-closed result plus the exact authored route,
critical trainer identity, reused NPC, level, team size and species.

The optional opening composition `-- --through-brine` provides exactly the
five-species, level-44 party already used by the Stormwood continuous chapter
entry diagnostic, before Water world creation. It is a bounded synthetic carried
party, not an earned Stormwood save. It adds no Water flags/materials, pose, HP
or stamina, and performs no later party write. The default and Reedhaven-only
opening modes remain party-empty. Production runtime is still required; stop at
the first physical or combat defect rather than bypassing it.

## Production verdict

Command:

`Godot_v4.7-stable_win64_console.exe --headless --path . --log-file
%TEMP%\water-opening-brine-tovin-repaired.log --script
tests/smoke_water_opening_continuous.gd -- --through-brine`

Exit 0. The one continuous process passed production arrival and Pell dialogue,
64.488 m physical lesson swim, Reedhaven human crossing, four exact named
harvest interactions, exact material-consuming repair, the 107.088 m Brine
crossing, graded p1-through-p5 walking, both Tovin opponents, surviving ally HP
`294.5 / 358`, and durable `defeated_water_trainer_tovin` plus
`water_dock_brine_steps_trial_won`. Every segment returned `ok: true` with an
empty failure list. Native `ERROR` / `SCRIPT ERROR` scan was clean. The only
warnings were the separately owned ordinary Brine ecology sites `_010/_011`.

This is the bounded synthetic carried-party fixture described above, not an
earned Stormwood-to-Water save seam. Within that disclosed boundary, the Water
opening through Tovin is now production-proven.
