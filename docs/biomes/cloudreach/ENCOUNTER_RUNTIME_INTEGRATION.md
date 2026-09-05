# Cloudreach encounter runtime

`scripts/combat/cloudreach_encounter_director.gd` subclasses the production encounter
director. `cloudreach_combat_manager.gd` subclasses its production combat manager.
The existing real-time creature combat, AI, switching, ownership/catch rules, XP and
trainer-round/payout machinery remain the execution path. No party slots, storage,
human attack or substitute stat curve is introduced.

`data/config/cloudreach_encounters.json` supplies placements, prerequisite flags,
AI behavior profiles and reward tiers. It translates all seven authored chapter
ladder teams from their replaceable species slots into the production trainer shape.
Six wild habitat sites draw deterministic weighted choices and legal levels from the
six chapter encounter tables, using the production world seed. Wilds instantiate
within 130 m, sleep by full 3D distance and use a 180-second replenishment cooldown.
These 12 potential wild bodies are an initial encounter spine, not evidence of final
chapter density or final creature art.

## World integration

1. Add a `cloudreach_combat_manager.gd` node named `CombatManager`, setting
   `ground_world` to the Cloudreach world root.
2. Create `cloudreach_encounter_director.gd` as `EncounterDirector`, set its
   `player_path`, `manager_path` and `camera_rig_path` to the real production siblings,
   then call `setup(world, reused_npcs)` before adding it to the tree. The dictionary
   maps the config's `reuse_npc_id` to existing NPC bodies that support `add_prompt`.
   Supply Orrin, Maela, Tavi and Veyra from the chapter's NPC runtime to avoid duplicate
   humans; omitted entries instantiate their installed authored profile.
3. Call `set_arbiter(existing_arbiter)` and connect the usual combat HUD/party/input
   paths. This director intentionally grants no default starter. The player's existing
   owned active creature is deployed through the production recall/summon action.
4. Each trainer's real shared prompt starts `begin_trainer_battle` at ordinary range
   after prerequisites. Defeated/locked/unavailable challenges disappear. These prompts
   currently challenge directly; their chapter conversations remain separate NPC
   prompts. If prebattle dialogue is required for a particular trainer, hand that exact
   trainer spec to `begin_trainer_battle` on its actual dialogue-finished callback.
5. Verify every config position against a real nearby floor and approach. All positions
   are full `[x,y,z]`. The config deliberately does not flatten them into Meadows XZ.
   Captain Veyra's provisional arena position matches the finale config behind Summit
   Eyrie at `[100,1160,5450]`; the owning world pass must author/verify that deck.

## Finale and story callbacks

- `trainer_started(id)` — connect captain ID to `finale.encounter_started`.
- `trainer_opposition_changed(id, remaining, initial)` — connect to
  `finale.opposition_remaining`; real round resolution supplies counts.
- `trainer_victory(id)` — emitted once from the production final-round victory path,
  before recording the trainer's canonical defeat flag. Connect the captain to
  `finale.encounter_won`; connect other IDs to the physical chapter runtime's validated
  trainer-result adapter. If the chapter callback records the flag, ordinary trainer
  rewards still pay once. Otherwise the inherited director writes the flag and pays.
- `trainer_lost(id)` — connect captain loss to the finale's bivouac recovery with the
  currently controlled body. Other losses preserve existing recovery behavior.

The definitive guard is the existing canonical `defeat_flag`, read from the live
`Game.progression`. Reload preserves defeats and suppresses rematches/rewards.
The victory callback does not replay on load. Realm Hearts and the Water key are never
trainer inventory rewards; those remain the chapter's later reward conversation.

Behavior profiles tune actual enemy telegraph, recovery, pursuit and reposition
values. The chapter's broader mechanic tags remain present, but this package does
not claim an independently implemented AI counter-switch system or every environmental
trainer hazard. Wire the finale's wind/arc mechanics separately. Existing production
trainer teams send creatures sequentially; the player retains normal party switching.

## Stacked-floor fixes

The new per-body `cloudreach_combat_surface.gd` adapter feeds the production creature
ground-source slot using the body's current elevation. The manager similarly seats
the human observer on the floor nearest the current fight. These prevent a fight on
a lower Cloudreach route from snapping onto an unrelated upper deck.

The shared `scripts/combat/throw_preview.gd` now prefers `ground_height_near(at)` when
the world offers it, preserving `ground_height_at(x,z)` for Meadows. It starts an
ImmediateMesh surface only when a visible ribbon dash exists, preventing empty-surface
errors on degenerate/near-eye arcs. The stacked-floor regression checks actual generated
ribbon geometry and a landing marker on the lower deck. A real GPU catch-view capture
and blind review remain required for visual acceptance.

## Verification

`tests/test_cloudreach_encounters.gd`: 2 tests / 331 assertions, covering all seven
trainer teams, installed humanoid profiles, real species level curves/AI overrides,
valid item rewards, canonical defeat persistence and six deterministic weighted wild
tables with legal level ranges.

`tests/smoke_cloudreach_encounters.gd` uses the production director/manager, production
creature bodies and shared interaction arbiter in an isolated scene with real stacked
collision floors. It drives a trainer challenge through input, verifies creature
movement through real stick input, resolves both real trainer rounds, observes XP and
one-time reward/callback, reloads flags and rejects duplicate payout. It also verifies
that the production throw path refuses trainer ownership specifically and accepts
wild catch aim, while preserving party size. Only lethal enemy damage is a test-only
subclass seam; it invokes the production reward and resolution flow. No test shortcut
ships in the production manager.

The first fixture run used an incorrect orb item ID and therefore tested empty-stock
refusal; this was corrected to `orb_basic` and an exact ownership-refusal assertion
was added. The next run exposed the production stacked-floor throw-preview defect,
which was fixed rather than hidden by the fixture.

Latest validation: the live fixture exits 0 with no script/resource errors. The
encounter suite plus existing catch-math suite passes 38 tests / 494 assertions.

Still required: world placements and arena clearance, all seven approaches/dialogue
handoffs, continuous unassisted battle/balance evidence, actual catch throw/capture
result and five-slot replacement path in Cloudreach, finale integration, visual
captures/judgment and production hardware performance measurement. This isolated
fixture is not a full chapter completion claim.
