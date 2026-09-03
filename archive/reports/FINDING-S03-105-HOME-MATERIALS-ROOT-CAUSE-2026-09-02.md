# S03-105 root cause: a harness/script bug, not a production defect

**Author:** operator agent, `ralph/GATE-F-S03-CATCH-LOOP`.
**Candidate:** `72a0966a` (this branch), run `ralph/reports/gate-f-run-20260902T122646Z-s03full`.
**Assigned by:** coordinator check-in, trigger `trig_01V1SeMCNZju7yzBQ7DpRWnE`, 2026-09-02T12:54:05Z.

## Verdict, up front

**Harness/segment-authoring bug. Not a production defect. No overlap with
`ralph/OWNER-0901-PLAYER-SLEEP-V2` or `ralph/OWNER-0902-REST-VISIBILITY`.**

`S03.json`'s knife-equip steps (`S03-67-equip`, `S03-73-equip`,
`S03-77-equip`, `S03-85-equip`, `S03-89-equip`, `S03-93-equip`,
`S03-99-equip`) all press `hotbar_5` to select the knife. In this run's own
actual save state (`gate-f-run-20260902T122646Z-s03full/S03/saves/
S03-exit.json`), the real, live hotbar array is:

```
hotbar = ['', 'axe', 'pickaxe', 'knife', '']
```

Knife is at array index 3 — which `hotbar_4` selects (`playground_hud.gd`'s
`HOTBAR_ACTIONS = ["hotbar_1".."hotbar_5"]` read loop maps `HOTBAR_ACTIONS[i]`
to hotbar array index `i` directly, 0-indexed both sides). `hotbar_5` selects
index 4, which is empty (`''`). Every knife-equip press this run selected
nothing, `equipped` stayed `{hotbar_slot: -1, item: ''}` through all seven
attempts (confirmed directly in `events.jsonl`), `harvest_logic.gd` refuses
fiber with no tool equipped, and all 8 fiber-node visits yielded 0 fiber
against an 18-fiber bill (camp 10 + creature_bed 8). That alone is sufficient
to fail `S03-105`'s `home_materials_gathered` check regardless of anything
else.

## Why `hotbar_5` is there: a prior "fix" that over-corrected

`git log`/the step's own `observation` field explain the history: the
original script pressed `hotbar_4` for the knife and a 2026-08-31 pass
("RIG, 2026-08-31") "corrected" it to `hotbar_5`, citing one specific prior
run's exit save that recorded the hotbar as `['', 'axe', 'pickaxe', '',
'knife']` — knife in the LAST slot, empty in the fourth. That measurement
does not match this run's, and does not match
`tools/gate_f/probe_tool_equip_depleted_bag.gd` — an isolated, controlled
probe from the SAME investigation lineage ("T2-GATEF-RUN5, GAME-9/RIG-24")
that reconstructs a realistically-depleted bag and asserts, as its own PASS
condition, that the `focus_item`-based assign sequence (the same one
`S03-56d`-`S03-56i` runs) lands the knife at hotbar index 3 — i.e.
`hotbar_4`. The probe was right; the one-run "correction" that followed it
was not, and nothing re-ran the probe against the "corrected" number before
shipping it.

I have not chased why that one earlier run recorded the knife one slot
over — a plausible read is that some other item was mid-cycle-bound at the
moment that specific run's snapshot was taken, or that run's own bag
composition differed slightly (this file's own history already documents
that the assign sequence is sensitive to what has been spent/gained before
it runs) — but I'm not asserting a theory I haven't verified, and it does
not change the fix: this run's actual save is ground truth for this
candidate, it agrees with the probe, and `hotbar_4` is correct.

## Secondary, smaller, NOT fully explained: 2 of 7 wood nodes also came up empty

Wood also fell short of its own bill (16 gathered vs. 18 needed: camp 12 +
creature_bed 6), though far less dramatically than fiber's 0/18. Matching
`gather` telemetry events to their walk timestamps: attempts at (16,-28)
[`S03-65`] and (40.5,-28) [`S03-79`] and (6,-34) [`S03-91`] produced no
wood gain; the other four did.

- **(16,-28) is explained**: it's the FIRST gather node in the whole
  sequence, and unlike every later node it has no individual `-equip` step
  before it (`S03-56` binds the tools to hotbar slots but never itself
  presses a hotbar button to make one ACTIVE, so the very first node is
  worked with nothing equipped). This is the same class of bug as the
  fiber one, on the wood side, at the boundary between "assign" and
  "equip."
- **(40.5,-28) and (6,-34) are NOT explained yet.** Both have their own
  `hotbar_2` (axe) equip step immediately before them, identical in shape
  to the four that succeeded. I have not root-caused why these two
  specifically came up empty — flagging rather than guessing. Candidates
  I have not checked: a `close_enough`/arrival-radius issue putting the
  player just outside these two nodes' specific interaction range, a
  terrain/collision quirk at those two coordinates, or something in
  `harvest_logic.gd` unrelated to tool state. Stone (3/3) and berries (2/2)
  had no such gaps, which argues against a generic timing/budget cause and
  for something specific to these two positions or this specific node type
  at those positions — but that is a hypothesis, not a finding.

## Recommended fix (not yet made, per your instruction to report before fixing)

1. `S03.json`: the 7 knife-equip steps, `hotbar_5` -> `hotbar_4`.
2. `S03.json`: give the FIRST gather node (`S03-65`, wood) its own
   `hotbar_2` equip step, matching every later node's own shape, so the
   sequence does not depend on an implicit carry-over from `S03-56` that
   isn't actually there.
3. Re-run and confirm `home_materials_gathered` sets and the wood/stone/
   fiber tallies clear the bill (18/8/18) with the same margin the
   segment's own economy comment already expects.
4. The two unexplained wood gaps ((40.5,-28), (6,-34)) are not blocking by
   themselves (wood would clear the bill once (16,-28) is fixed: 16+4=20 >=
   18) — recommend leaving them as a named open thread rather than chasing
   them now, unless you want them run down before calling S03-105 closed.

Holding on implementing any of this until you've seen the root cause, as
asked.
