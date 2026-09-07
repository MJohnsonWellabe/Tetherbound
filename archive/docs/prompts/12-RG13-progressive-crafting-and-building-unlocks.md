# RG13 — Progressive crafting and building unlocks

## Goal
Replace the current front-loaded crafting/build catalogue with a discovery-based progression. A brand-new player should begin knowing **zero crafting recipes and zero non-tutorial build recipes**. Recipes and build pieces are learned through NPC instruction, material discovery, and progression milestones so new possibilities arrive in understandable chunks while playing.

This is not a UI-only hide pass. The knowledge/unlock state must be authoritative, saved, loaded, and enforced by the gameplay systems that actually craft and build.

## Owner direction
Owner playtest: “Too many recipes are unlocked at the start.”

Clarified design direction:
- Beginning should be **nothing**.
- Talk to one NPC and they teach you how to make a potion.
- Talk to another NPC and they teach you how to make an orb.
- Obtaining/discovering materials unlocks appropriate construction tiers.
- Wood discovery unlocks wood structures.
- Stone discovery unlocks more structures.
- Later progression materials unlock their later recipe tiers in the same readable way.
- The overall progression should feel like learning the world, not opening a completed crafting manual on minute one.

## Current state to inspect before changing anything
Read current main before implementation, especially:
- `data/recipes/recipes.json`
- `data/recipes/recipes_rootstone.json`
- `data/recipes/recipes_ironwood.json`
- `data/items/buildables.json`
- `scripts/ui/craft_panel.gd`
- `scripts/ui/build_menu.gd`
- recipe/build lookup helpers in `scripts/items/item_db.gd` or current equivalent
- `autoload/game_state.gd`
- `autoload/progression_state.gd`
- current NPC/dialogue/progression scripts that teach or grant items, especially Tam and any potion/healing/tutorial NPC
- save/load code and tests around progression flags
- `MEADOWS_PROGRESSION_SPEC.md` and current tutorial/onboarding work so this does not create contradictory sequencing

Important existing behavior:
- Recipes already support optional `unlocked_by` progression flags.
- `orb_basic` is already gated by `recipe_orb_basic`, currently associated with Tam.
- Most base recipes are currently ungated.
- Rootstone and Ironwood recipe files explicitly say they are known automatically once their material is available. **That design is superseded by this owner directive.**
- `buildables.json` currently has no equivalent unlock field and exposes the whole catalogue.

## Player-facing behavior
### New game
A fresh save must not open the craft screen or build menu to a wall of recipes.

At the very beginning:
- No potion recipe is known.
- No orb recipe is known.
- No axe/pickaxe/knife/hoe/seed recipe is silently known.
- No full structure catalogue is silently known.
- If the UI is opened before anything has been learned, show an intentional empty/locked-state message such as “You haven’t learned any recipes yet” rather than looking broken.

### NPC-taught recipes
Use the existing progression flag system rather than inventing a parallel recipe-book subsystem.

At minimum:
- One appropriate early NPC teaches the **Small Potion** recipe.
- A different appropriate NPC teaches the **Basic Orb** recipe.

Preserve existing authored NPC roles where they already fit. Tam already has a historical/current relationship to the basic orb recipe; do not arbitrarily move that unless current content makes another owner-approved route clearly authoritative.

The teaching event must:
1. set the recipe unlock flag,
2. give clear player feedback that a new recipe was learned,
3. make it immediately appear in the appropriate craft interface,
4. persist across save/load,
5. never repeat as though it were newly learned after the flag is set.

### Material-discovery unlocks
Material acquisition should reveal sensible construction/crafting opportunities.

The rule is **first meaningful acquisition/discovery of the material**, not merely walking near a node.

At minimum:
- First acquisition of **wood** unlocks the clearly wood-based starter structure set.
- First acquisition of **stone** unlocks additional stone or wood+stone structures.
- First acquisition of **Rootstone** unlocks the Rootstone recipe tier that is appropriate at that progression point.
- First acquisition of **Ironwood** unlocks the Ironwood recipe tier that is appropriate at that progression point.

Do not use one broad “unlock everything from this file” shortcut if entries belong at materially different points in progression. Use data-driven unlock metadata so individual recipes/buildables can be assigned to a milestone cleanly.

### Structure unlock philosophy
`data/items/buildables.json` currently contains things such as camp, floor, wall, door, roof, fence, workbench, storage, creature bed.

Add an unlock contract to buildables comparable to recipes. The build menu must list only known pieces, and placement must reject unknown pieces even if some stale/test path tries to arm one directly.

Use the owner’s progression rule when assigning the existing catalogue:
- Simple wood construction becomes available when wood is learned/acquired.
- Stone and mixed wood/stone construction becomes available once stone is learned/acquired.
- Specialized utility/furniture pieces should unlock when their gameplay concept is introduced rather than simply because they happen to cost wood.

Examples of “concept introduction” pieces include workbench, storage, creature bed, farming-related pieces, or anything that belongs to onboarding beats. Coordinate with RG18 rather than dumping them all into the first material tier.

### Recipe unlock philosophy
Avoid a giant permanent tree. The Meadows design already intends a small readable economy.

Use three kinds of unlock triggers:
1. **NPC taught** — knowledge someone explicitly teaches, such as potion/orb basics.
2. **Material discovered** — recipes that naturally become understandable when a new material tier is obtained.
3. **Progression/system introduced** — recipes tied to a mechanic such as farming, riding, creature care, etc.

Do not leave recipes globally known simply because their ingredient cost might prevent immediate crafting. The owner explicitly rejected “material cost is the gate” as the only progression model.

## Data design
Prefer extending the existing `unlocked_by` concept rather than building a second recipe knowledge database.

For recipes:
- Continue to support `unlocked_by` progression flags.
- Every player-facing recipe should have an intentional unlock path.
- An absent `unlocked_by` should no longer mean “known from minute one” for normal Meadows recipes unless there is a very deliberate technical/bootstrap exception documented in data.

For buildables:
- Add equivalent data-driven unlock metadata (`unlocked_by` or the project’s current naming convention).
- Centralize the “is this known?” query in GameState/data helpers so both UI and actual placement share the same answer.

For material discovery:
- Add persistent progression flags for first acquisition where they do not already exist, e.g. conceptually `material_wood_discovered`, `material_stone_discovered`, `material_rootstone_discovered`, `material_ironwood_discovered`.
- Trigger them from the authoritative inventory acquisition path or a narrow shared hook that covers gathering/rewards/pickups without firing on mere inspection.
- Avoid scattering unlock calls across every individual wood/stone node script.
- Unlock flags must survive save/load.

## Unlock feedback
When a new recipe or build set becomes known, give a concise readable notification. Examples:
- “Recipe learned: Small Potion”
- “Recipe learned: Orb”
- “New building pieces unlocked” with a compact list or icon treatment if multiple pieces arrive together.

Do not spam one toast per structure if five pieces unlock from the same first wood pickup. Batch related unlocks into one understandable event.

## Current tier files that must be reconciled
### Base recipes
`data/recipes/recipes.json` currently includes:
- orb_basic
- potion_small
- axe
- pickaxe
- knife
- hoe
- berry_seeds

Do not simply add the same unlock flag to every one. Assign each according to the owner’s discovery/tutorial philosophy and current authored progression.

### Rootstone
`data/recipes/recipes_rootstone.json` currently contains Rootstone-tier upgrades including greater orb/tool reinforcement/saddle-related content and explicitly says no `unlocked_by` is needed because Rootstone itself is the gate. Update that assumption. First Rootstone acquisition/progression should unlock only the Rootstone knowledge appropriate to that point, using persistent flags/data.

### Ironwood
`data/recipes/recipes_ironwood.json` currently uses the same material-only philosophy. Update it to the new knowledge progression model.

Do not change costs, power, heal values, durability bonuses, catch multipliers, or recipe outputs just because unlock logic is changing.

## Preserve
- Existing inventory/material economy.
- Existing recipe cost/output data unless a change is strictly required for unlock plumbing.
- Existing crafting mechanics.
- Existing basic orb teaching path where current NPC authored content already implements it successfully.
- Grandpa’s starting item grants unless a separate backlog item changes them.
- Rootstone/Ironwood as the Meadows material progression tiers.
- Small/readable crafting tree philosophy.
- Save compatibility with existing saves.

For existing saves, choose a migration strategy that does not arbitrarily wipe earned progression. Infer known recipes/build pieces from existing progression/material ownership where reliable, and document any unavoidable migration behavior.

## Do not
- Do not solve this by merely hiding rows in `craft_panel.gd` while `GameState.craft()` still allows them.
- Do not hard-code screen-specific arrays of visible recipe ids.
- Do not create a second parallel “known recipes” save structure if progression flags already solve the problem.
- Do not make every recipe unlock simultaneously on the first wood/stone pickup.
- Do not invent a large skill tree, XP tree, technology-point system, or research currency.
- Do not rebalance crafting costs under this task.
- Do not remove recipes/content from the game just to reduce the starting list.

## Acceptance criteria
1. A brand-new save begins with zero normal crafting recipes known.
2. Craft UI opened before learning anything presents an intentional empty state.
3. The potion recipe is learned through an NPC teaching event and persists.
4. The basic orb recipe is learned through a separate NPC teaching event and persists.
5. Recipes not yet learned are neither displayed nor craftable through alternate/direct code paths.
6. The build catalogue begins intentionally limited/empty according to current tutorial sequencing rather than exposing all pieces.
7. First wood acquisition unlocks the intended wood construction tier.
8. First stone acquisition unlocks the intended additional stone/mixed construction tier.
9. First Rootstone and Ironwood acquisition/progression unlock their intended later recipe knowledge rather than relying only on ingredient possession.
10. Specialized pieces such as farming/creature-care/workbench/storage are coordinated with their gameplay introduction and are not all accidentally released by the first wood pickup.
11. Unlock notifications are clear and batched where appropriate.
12. Unlock state saves and loads correctly.
13. Existing saves migrate safely.
14. Costs, recipe outputs, catch multipliers, tool durability values, and unrelated gameplay remain unchanged.

## Tests / verification
Add or update tests that prove behavior, not just data presence.

At minimum test:
- fresh progression => no known normal recipes,
- fresh progression => locked recipe cannot be crafted directly,
- NPC recipe flag => recipe becomes known/craftable,
- save/load preserves recipe unlock,
- first material acquisition sets its discovery flag exactly once,
- wood discovery changes build catalogue as intended,
- stone discovery adds the next intended pieces without exposing later tiers,
- Rootstone/Ironwood unlock logic,
- unknown buildable cannot be armed/placed through direct pending-build manipulation,
- existing-save migration path.

Perform a real Meadows traversal on controller:
1. start fresh,
2. open craft/build UI and confirm no overwhelming catalogue,
3. learn potion,
4. learn orb from the separate NPC,
5. gather wood and observe the wood-building unlock,
6. gather stone and observe the next construction unlock,
7. continue far enough or use a controlled test fixture to confirm Rootstone/Ironwood tiers,
8. save/reload between unlocks and verify state is stable.

## Definition of done
RG13 is done when crafting/building feels discovered through play: the player starts knowing nothing, learns basic recipes from people, sees construction possibilities expand as materials enter their hands, and continues unlocking later tiers through Meadows progression. The UI and underlying gameplay rules agree on what is known, and the state is persistent and data-driven.