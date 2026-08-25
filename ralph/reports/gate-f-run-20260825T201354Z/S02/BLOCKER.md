# BLOCKER — S02 still cannot leave Grandpa's house. Four attempts, one outcome.

**Segment:** S02 (Opening). **Best result:** 62 PASS / 12 FAIL, no exit save.
**Consequence:** unchanged — S03–S10 chain from the previous exit save and X01–X06
seed from journey saves, so all remain blocked. X07 and X08 are done.

## What was fixed, and what it bought

Attempt 1's diagnosis was wrong and is corrected in `S02-superseded-1/` and in
`tools/opening_fix/FINDING.md` on `ralph/OPENING-STARTER-FOCUS`. The real defect
there was **in the step-script, not the game**: `S02-15 "walk down to Grandpa"`
targeted `[-22,-16]`, the house *origin*, with `close_enough: 3.0`. `move_to`
compares **x/z only**, and the bed sits 0.89 m from Grandpa in x/z while **3.3 m
above him in y** — the player wakes on the loft (`grandpa_house.gd`, `LOFT_W 4.6`,
`FLOOR_H 3.2`). So the step passed honestly while leaving the player one storey up,
and the segment pressed `interact` 31 times through the floor.

Routing the walk through the house's own published stair markers —
`stairs_top` `(-21.5, 3.20, -18.1)` and `stairs_bottom` `(-18.0, 0.12, -18.1)`,
which exist verbatim "for anything that has to NAVIGATE the house" — fixed that
half. From attempt 2 on, the player descends, Grandpa's prompt offers, the briefing
opens, the starter is chosen, and **`party_size` reaches 1: the starter is caught
and named through the production path.** That is 10 assertions recovered and the
opening's core beat proven working.

## What is still blocked, and why it is not a press-count problem

From the briefing onward a `narrative_modal` owns input continuously and the player
never leaves the house. `S02-30` reports:

```
FAIL locomotion never came back: held 7201 frames by input_context
'narrative_modal' while 58.8 m short of (30, -40) at (-23.0, 1.0, -15.0)
```

`S02-63` names the holder: **`owner=DialoguePanel`**.

Three separate configurations of the step that answers `grandpa_named` were run,
plus a 5 s transition wait, and **the result did not move**:

| attempt | S02-28 presses | extra wait | PASS/FAIL | modal block | exit save |
|---|---|---|---|---|---|
| 2 | 12 × settle 20 | — | 61 / 12 | 256.4 → 377.4 (121 s) | none |
| 3 | 20 × settle 30 | 5 s | 62 / 12 | 259.4 → 380.7 (121 s) | none |
| 4 | 4 × settle 30 | 5 s | 62 / 12 | 242.0 → 381.0 (139 s) | none |

The same twelve assertions fail in all three, with the same values. **The number of
`interact` presses is not the variable**, which is what rules out the obvious
reading that the script simply under-presses a conversation. `grandpa_named` is
**three lines** (`data/dialogue/opening.json`), so 4, 12 and 20 taps are all
sufficient, and all three behave identically.

Two facts constrain any explanation:

1. **Nothing is pressing anything for the last ~110 s of the block.** The taps span
   about 10 s; the modal stays up for two more minutes with the harness idle inside
   a held walk.
2. **The block ends at exactly 7201 held frames, twice, to the frame** — i.e. the
   instant `S02-30`'s `held_budget_frames: 7200` expires and the walk gives up.
   A modal that clears precisely when the *observer* stops waiting is the detail
   worth handing to whoever picks this up.

`dialogue_panel.gd:172-176` reads `interact` from `_physics_process`, the same tick
as `interaction_arbiter.gd:271-275`, and a probe
(`tools/opening_fix/probe_interact_edge.gd`) confirms the harness's injection shape
does satisfy `is_action_just_pressed` in a `_physics_process` reader. So "the
presses never arrive" is measured to be false.

## Operator position

I made **two** changes to `tools/gate_f/segments/S02.json` and no changes to any
game file: the stair routing (evidence-backed, decisive, recovered the opening) and
the transition allowance plus press count (bounded, and it changed nothing). I then
stopped, having said in advance that a third distinct wall would end the tuning
rather than start another round. Continuing would have meant reshaping a frozen
step-script against a game behaviour I do not understand, alone, until something
went green — which is how a run stops being evidence.

Every attempt is preserved: `S02-superseded-1/` (the pre-stairs run and its
corrected diagnosis), `-2/`, `-3/`, and this directory as attempt 4.

**No game file changed, so no new candidate SHA is required and there is no §1.6
pre-fix/post-fix seam.** All S01, X07 and X08 evidence remains valid against
`a3f61b60`.
