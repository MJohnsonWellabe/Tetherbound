# Stormwood Crown route: next executable slice — 2026-09-08

## Scope

This is a source-derived implementation brief for extending the existing
chapter-entry `Segment` after it earns `stormwood:arch_recipe_known`. It does
not re-prove the flag wiring already covered by the chapter tests, does not use
a world run, and does not claim that the physical route has passed. The slice
ends at the released Rootgate and does not enter Act III or the Dynamo.

## Production route and ordinary actions

The authored Act-II sequence is explicit in
`data/config/stormwood_chapter.json:218-292`: Ondra's dialogue unlocks the
recipe, Crown-grade glass precedes construction, the constructed arch is the
only route across the Glass Sink, the Crown guardian precedes Wen, and Wen
precedes the heartstone's Rootgate release.

The executable route should perform these actions in order:

1. **Recover at Still Grove, then meet the Capacitor Alpha.** Still Grove's
   real camp is at `(-130, 2730)` and is unlocked by Varga
   (`data/config/stormwood_camps.json:9`; `scripts/world/stormwood_camps.gd:23-27`).
   Use its normal Rest prompt if the Varga fight left the party depleted. Walk
   from Ondra along `conductor_road` through `(-630,2930)` to `(-1080,3020)`
   (`data/config/stormwood_world.json:45`). The named `capacitor_alpha` is a
   level-40 Voltarach at that second point
   (`data/config/stormwood_encounters.json:5923-5936`). Let proximity start the
   production wild fight, answer it with controller combat/catching, and require
   `stormwood:named:capacitor_alpha:cleared`; wins and catches are the two
   production outcomes that retire once-only wilds
   (`scripts/combat/encounter_director.gd:3261-3286`).

2. **Gather the exact construction materials.** The Still Grove Crown footing
   changes only the glass row from ordinary to Crown grade
   (`scripts/world/stormwood_arch_build_rules.gd:5-11`). One arch therefore
   needs six `stormglass_crown`, two `thunderwood_frame`, and four
   `conductor_vine`; each frame separately costs three `thunderwood` and one
   vine (`data/items/buildables.json:145-164` and
   `data/recipes/recipes_stormwood.json:156-174`). The total raw gather is:

   - 6 Crown-grade Stormglass;
   - 6 Thunderwood;
   - 6 Conductor Vine (two for the frames, four for the arch).

   A deterministic, ordinary-tool set of authored sources is:

   | Resource | Authored sites | Position | Yield | Tool/window |
   |---|---|---:|---:|---|
   | Thunderwood | `conductor_run_099`, `conductor_run_094` | `(-1300,3030)`, `(-1300,2900)` | 4 each | axe; every surge phase |
   | Conductor Vine | `conductor_run_097`, `conductor_run_092` | `(-1600,3030)`, `(-1600,2900)` | 3 each | knife; every surge phase |
   | Crown glass | `conductor_run_075`, `conductor_run_074` | `(-1150,2380)`, `(-1300,2380)` | 3 each | pickaxe; Break/Fading only |

   These exact rows are the production catalogue at
   `data/config/stormwood_harvests.json:1617-1654`,
   `data/config/stormwood_harvests.json:2009-2072`, and
   `data/config/stormwood_harvests.json:2119-2182`. The integrated item definition confirms
   that Crown glass is pickaxe-gathered (`data/items/items.json:1064-1073`).
   Gather ordinary wood/vine while following the west loop, then use Rodline
   Refuge at `(-660,2318)` as the safe wait for Break/Fading rather than idling
   exposed at a charged seam. From Rodline the first selected Crown site is
   about 494 m away. The authored usable window is 120 seconds of Break plus
   60 seconds of Fading (`data/config/stormwood_surge.json:3`); the executable
   segment keeps that travel independently bounded and must measure whether it
   reaches the seams in the live world rather than assume the distance fits.
   Require inventory counts, not only the chapter flag.

3. **Craft two frames through the camp UI.** Return to Rodline Refuge. Its
   `RestPoint` mounts a distinct `CraftInteractable` beside the rest prompt and
   activation opens the production `CraftPanel`
   (`scripts/world/rest_point.gd:90-119`, `scripts/world/rest_point.gd:163-170`).
   Activate that exact provider through `InteractionArbiter`, move real UI
   focus until the panel's `_recipe_ids` entry is `thunderwood_frame`, and send
   two `ui_accept` presses. Each focused row calls `Game.craft` through the
   normal button (`scripts/ui/craft_panel.gd:330-370`,
   `scripts/ui/craft_panel.gd:458-465`). Assert two frames, six wood spent and
   two of the six vines spent; then close the panel by its ordinary cancel.

4. **Raise the Crown twin through Build mode.** Walk the authored road back to
   Still Grove and stand three metres behind the footing at `(-160,2750)`.
   The fixed twin is the lit `e_crown` arch at `(485,2700)`
   (`data/config/stormwood_arches.json:15-18`). Open the catalogue with the
   normal `build_shortcut` input; the world HUD routes that input to the real
   menu (`scripts/ui/playground_hud.gd:4230-4242`). Move controller focus to
   Structures / `stormglass_arch` and confirm. `_pick` must arm
   `Game.pending_build` and close the menu (`scripts/ui/build_menu.gd:722-757`).
   The affordability gate already accepts Crown glass for this selection
   (`autoload/game_state.gd:2098-2108`).

   Use ordinary look input until the live ghost's raw point is within five
   metres of the footing. `BuildPlacer` projects the ghost three metres ahead,
   snaps it to the authored socket, applies the socket yaw, and checks the
   footing-specific cost (`scripts/build/build_placer.gd:476-511`,
   `scripts/build/build_placer.gd:592-655`). Only then press `build_place`.
   Assert one new paid `stormglass_arch` record at the socket, exact Crown
   material spend, the linked fixed-twin metadata, and
   `stormwood:crown_arch_built`. The placement intent captures and submits the
   dynamic socket cost to the host ledger
   (`scripts/build/build_placer.gd:797-835`), while the arch runtime emits the
   constructed chapter event only after the committed record links to
   `e_crown` (`scripts/world/stormwood_arch_runtime.gd:135-186`).

5. **Cross the actual arch and settle the Crown guardian.** Walk out of and
   back through the constructed passage; do not call the travel service. The
   runtime places the player 3.5 m beyond `e_crown` and emits
   `arch:crown_arrived` only for that target
   (`scripts/world/stormwood_arch_runtime.gd:197-242`,
   `scripts/world/stormwood_arch_runtime.gd:244-270`). Require
   `stormwood:crown_reached`, then walk the safe Crown-ring anchors from the
   arch at `(485,2700)` toward `(590,2540)`, `(805,2545)` and the heartstone
   centre (`data/config/stormwood_world.json:52`). The once-only level-41
   `crown_guardian` is at `(700,74,2700)`
   (`data/config/stormwood_encounters.json:5938-5951`). Require a real win or
   catch and `stormwood:named:crown_guardian:cleared`; a loss must use ordinary
   party recovery and re-engagement rather than a flag or HP write.

6. **Hear Wen, release the Rootgate, and prove the physical opening.** Archivist
   Wen stands at `(700,74.15,2700)` (`data/config/stormwood_npcs.json:136-147`).
   Before guardian clear, production deliberately offers a refusal; only the
   `crown_reached + crown_guardian:cleared` branch selects her in-progress
   truth conversation (`scripts/world/stormwood_chapter.gd:18-27`,
   `scripts/world/stormwood_chapter.gd:99-130`). Activate Wen's exact prompt,
   drain dialogue through interact input, and require
   `stormwood:engine_truth_learned`.

   The separate `CrownHeartstone/HeartstoneInteractable` sits at approximately
   `(700, *, 2710)` and becomes actionable only after both guardian and truth
   facts (`scripts/world/stormwood_crown.gd:45-74`). Activate that exact
   provider and require `stormwood:rootgate_released` plus
   `stormwood:act_ii_complete`. Return through the built arch, follow the
   remaining conductor-road anchors `(-630,2930)`, `(-1080,3020)`,
   `(-1120,3290)`, and cross the gate at `(-650,3550)` to a point north of it.
   The production gate is a 90 x 40 x 15 collision body whose visibility and
   collision are disabled by the released fact
   (`scripts/world/stormwood_world.gd:206-212`,
   `scripts/world/stormwood_world.gd:226-238`). Stop there; do not approach
   Lantern Hollow or claim Act-III coverage.

## Two real contract disconnects to keep visible

1. The chapter text says to “Pass the Capacitor Grove guardian” before Crown
   glass (`data/config/stormwood_chapter.json:230-239`), but its only runtime
   prerequisite is `stormwood:arch_recipe_known`. Conductor Run harvests have
   no region gate (`scripts/world/stormwood_harvest_runtime.gd:10-17`), and the
   harvest refusal helper likewise gates only Crown/Deepwood/Dynamo regions
   (`scripts/world/stormwood_harvest_rules.gd:13-22`). A repository search finds
   no consumer of `stormwood:named:capacitor_alpha:cleared`. The player can walk
   directly to the seams and complete the objective without the named guardian.
   The bounded construction helper walks the authored Capacitor road point and
   explicitly requires the named once-only clear fact from ordinary encounter
   handling. That preserves the authored acceptance path, but it does not repair
   the missing production prerequisite: ordinary players remain able to bypass
   the Alpha outside the harness.

2. The chapter's `crown_glass_gathered` event is emitted after **any one**
   claimed Crown-grade site once the recipe is known
   (`scripts/world/stormwood_harvest_runtime.gd:65-75`). Each selected site
   yields three, while the footing costs six. The exact placement cost still
   prevents a free or underpaid build, so this is not a softlock; it is a
   misleading half-complete objective. Runtime acceptance must assert six in
   inventory before opening Build mode.

## Next bounded implementation brief

The bounded continuation is prepared separately in
`tests/helpers/stormwood_crown_build_segment.gd`, guarded by
`tests/test_stormwood_crown_build_segment_contract.gd`. It begins only from a
live player at Ondra with `stormwood:arch_recipe_known`, no Crown construction
fact and no selected harvest receipt. It then uses ordinary movement and combat,
the six named harvest interactions above, two controller-driven frame crafts,
controller-driven catalogue selection, a live green socket ghost, and one paid
`build_place`. The helper stops at `stormwood:crown_arch_built`; it does not
extend to Crown travel in the same coding slice.

The all-or-nothing production Thunderwood nodes yield four each, so the honest
six-node route gathers **8** Thunderwood, spends 6 on the two frames, and carries
2 forward. It cannot claim to have gathered exactly 6 without fabricating a
partial node payout. The focused contract reads the production harvest, recipe
and build catalogues and pins that resource balance; it also bans direct
inventory, progression, build-selection, craft and placement mutation.

Focused cache-read validation on 2026-09-08 passed 6 tests / 78 assertions
across the Crown helper and the separate charged-window boundary contract, with
no native `ERROR:` in `%TEMP%/stormwood-charged-window-contract.log`. This is
parse/pure-contract evidence only; the Crown helper remains physically unrun.

The existing continuous wrapper remains separate from this helper until its
Ondra-bound prefix earns a clean runtime verdict. After that verdict, composition
is the smallest next step: invoke the helper with the same live tree/world/Game
and diagnose its first actual physical boundary. Do not extend to Crown travel
before the resource/craft/build boundary is settled.

That harness-only extension is parallel-safe with Water and CI work and makes
no production claim. If production repair is separately authorized, the narrow
source lane is the Capacitor prerequisite plus six-unit objective semantics in
`stormwood_harvest_rules.gd` / `stormwood_harvest_runtime.gd`, with focused
harvest progression tests; it must not be folded silently into the harness.
