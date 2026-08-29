# FINDING — the S03 build-placement failure is a RIG defect, not a GAME defect

**Verdict: RIG, confirmed live in the engine.** `build_menu.gd` /
`build_placer.gd` / `home_progress.gd` all behave exactly as designed at
every point checked. `S03.json`'s own gathering loop (`S03-65`..`S03-104`)
never equips a tool before pressing `interact` on a wood/stone/fiber node,
so — by a design that is itself pinned by a passing unit test — those
gathers silently yield zero, the satchel never affords camp or a creature
bed, and the build catalogue's own "can't afford, stay open" refusal
(`build_menu.gd:713-719`) is what the run's telemetry actually shows as
`input_context` stuck on `build_catalogue` (`S03-117`, `S03-130`,
`S03-143`, `S03-156`, `S03-169`) and `home_built`/`creature_bed_built_3`
never set (`S03-173`, `S03-205`).

## The chain, each link verified against source, a real save, and a live probe

1. **The run's own kept `S03-exit.json` has zero wood, zero stone, zero
   fiber, `placed_buildings: []`, and five berries.** Not "gathered less
   than the threshold" — genuinely none. `events.jsonl` for the whole
   segment contains zero occurrences of the strings "wood", "stone" or
   "fiber", and zero `gather` events.

2. **Wood, stone and fiber are all tool-gated; berries is not**
   (`data/items/items.json`: `wood.gathered_with = "axe"`,
   `stone.gathered_with = "pickaxe"`, `fiber.gathered_with = "knife"`, no
   `gathered_with` on `berries`). `harvest_logic.gd::gather()` returns
   `{"amount": 0}` whenever `equipped_tool != required` — including empty
   string, i.e. no tool equipped at all. This is not incidental behaviour:
   `tests/test_harvest.gd::test_gather_with_no_equipped_tool_is_refused`
   exists specifically to pin it, with the docstring "carrying an axe is
   not enough when no tool is visibly equipped."

3. **`S03.json` never equips a tool anywhere in its 20-node gathering
   loop.** Grepped directly: every gather step is `move_to` then `press
   interact` (x2), with no `hotbar`/`equip`/`assign_hotbar` step before,
   between, or after any of them. The harness has no such step type at all
   (`operator_harness.gd` has no `assign_hotbar`/`equip` action). Since
   `equipped_tool` starts empty and nothing in this segment's own steps
   ever changes it before the gathering loop, every wood/stone/fiber
   attempt is refused by design, exactly as berries (no gate) succeeds
   (5 in the final inventory) while the other three never appear at all.

4. **Live-engine confirmation, `tools/gate_f/probe_build_catalogue_arm_cause.gd`**
   (`godot --headless --path . --script
   tools/gate_f/probe_build_catalogue_arm_cause.gd`), against the real
   `build_menu.gd`/`build_placer.gd`/`home_progress.gd` in the production
   `meadows_playground.tscn`, driven through the same synthetic-controller
   path `S03.json` itself uses (`Input.parse_input_event`, not a bypass):
   - **Part 1**, at zero materials: arming camp reproduces the run's own
     observation exactly — the menu stays open, `pending_build` stays
     empty. This is `_pick()`'s own affordability refusal
     (`AUDIO_CUES.play(&"ui_error")`, no `close()`), not a broken
     catalogue-to-placement handoff.
   - **Part 2**, with camp's real cost (12 wood / 8 stone / 10 fiber)
     granted: the identical button sequence arms the piece, closes the
     menu, sets `pending_build == "camp"`, and a real `build_place` press
     produces a genuine `placed_building` node tagged `camp`.
   - **Part 3**, with creature_bed's cost (6 wood / 8 fiber) also granted:
     the same chain places a real `creature_bed`, and `home_progress.gd`
     sets `home_built` the instant both required pieces
     (`data/config/progression.json`: `home.required_pieces` is now just
     `{camp: 1, creature_bed: 1}`) stand in `GameState.placed_buildings`.
   - Full transcript ends `PROBE PASS`.

   **This is the direct answer to the brief's "diff `smoke_gate_a_rest_
   torch.gd` against S03's own steps."** That smoke test's own header says
   why it cannot answer this question on its own: it "directly arms
   free-build pieces" (`_game.set("pending_build", id)`) specifically to
   skip the catalogue, so its PASS never exercised `build_menu.gd::_pick()`
   at all. This probe closes that gap by driving the catalogue for real.

5. **A second, smaller, already-recorded RIG defect in the same
   neighbourhood, NOT the cause of the S03-117/S03-205 failures but worth
   naming**: `S03-181` ("focus Creature Bed") independently FAILs —
   `1 x ui_right did not move focus off` the first grid cell — in the
   furniture category, which holds Storage Chest then Creature Bed
   (`data/items/buildables.json` order). This probe's own Part 3 sidesteps
   it (`menu.call("_pick", 1)` directly) rather than re-diagnosing a
   second, separate focus bug while answering the RIG-or-GAME question.

## A secondary thread, opened but not closed: Mira's axe/pickaxe grant

Chasing "why is the satchel never affordable" one layer further: Tam's own
gift (`data/dialogue/village.json:181`, `tam_tools_given`) is **only**
`give:knife:1, give:torch:1` — no axe, no pickaxe. Those come exclusively
from Mira's unconditional first-visit conversation
(`village_mira_shop_intro`, `data/dialogue/village.json:29-39`,
`give:axe:1, give:pickaxe:1, give:coin:30, flag:mira_shop_open`), gated in
`data/config/village_npcs.json:26-28` purely by `unless_flag:
mira_shop_open` — no combat/ally-state gate at all.

The run's own `S03-exit.json` has **no axe, no pickaxe, and no
`mira_shop_open`/`opening:mira_visited` flag** — Mira's mandatory first-
visit grant never landed. `tools/gate_f/probe_mira_intro_grant.gd`
reproduces `S03-53`/`S03-54`'s exact button sequence (`interact` tap x1,
then x10 at 20-frame settle) against a real Mira, **twice** — once with a
fresh party, once with a real deployed-then-fainted active creature
(matching this run's own state at t=372, well after Moss's t=256 faint) —
and in **both** cases the grant lands cleanly and survives the segment's
own subsequent `S03-55`..`59` "fight" presses (`PROBE PASS` both times;
live prompt reads `"Greet Mira"`, never a fainted-ally refusal). So the
fainted party is **not** why the real run missed this grant, ruling out
the most obvious hypothesis by direct live test rather than by inference.

**Not resolved in this pass.** The remaining, most likely candidate —
untested here for time — is that `S03.json`'s `move_to` steps for the
village NPCs (Tam/Bryn/Mira/Oskar) use a raw authored coordinate rather
than `move_to_entity`, the pattern `ralph/conventions.md`'s own CD-5 fix
introduced specifically because a coordinate-only "arrived" check does not
guarantee the player is within a live entity's actual interaction range —
and this segment predates that fix for its village-NPC stops (unlike its
own later bramblebun catch loop, which already uses the safer
prompt-text-matching pattern from RIG-17). Tam's own gift landing
correctly is not a counter-example — line-of-sight/range at one authored
building-front coordinate proves nothing about another's. **Whoever picks
this up next**: rerun `probe_mira_intro_grant.gd`'s exact button sequence
but replace the teleport with the segment's own recorded walk (from
Bryn's practice ground, `(13,9)`, to `(19,-1)`) and print the live prompt
text at arrival, the same way `probe_stranding_cause.gd` and this session's
own catalogue probe did — that is the one step this pass did not take.

## Why this matters beyond S03

Both defects share the same shape as the South Bridge stranding
(`FINDING-T2-STRANDING-2026-08-30.md`): an early, quiet, unasserted state
gap (no tool equipped; possibly a missed NPC interaction) that only
becomes visible many steps later as a loud, heavily-asserted failure
(`input_context` stuck, a flag never set) whose own immediate neighbourhood
is not where the cause lives. Reading `build_menu.gd`/`build_placer.gd` in
isolation, or the failing assertions' own step text, would not have found
either cause; both needed the actual save contents and a live probe.

## Impact on other lanes

The fix (next commit) touches only `tools/gate_f/segments/S03.json` and
adds probe tooling under `tools/gate_f/`. No file under `scripts/`,
`data/`, or any other game-code/content path is touched by this finding —
`build_menu.gd`, `build_placer.gd`, `home_progress.gd`,
`harvest_logic.gd`, and `data/dialogue/village.json` are all confirmed
correct as shipped and none are modified here.
