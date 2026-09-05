# What the code-blind judge was given

Round 1, N09-BRIDGE-CHECKPOINT-0905.

Two contact sheets and nothing else about this lane: `_sheet_bridge_ab.png` and
`_sheet_signpost_ab.png` (each row is the same stand rendered twice, labelled A
and B, with no statement of which is older or which is the newer work),
`docs/reference/`, the owner's board
`docs/art/reference/18_Signpost_Bridge_Modular_Props.png`, and
`.claude/skills/visual-judge/SKILL.md`.

**The questions are W22-BRIDGE-SIGNPOST-0904's own four**, unchanged, so that this
round's answers sit directly against the landing judge's
(`ralph/reports/W22-BRIDGE-SIGNPOST-0904/JUDGE.md`) — which is what this lane's
acceptance criterion asks for:

1. For each signpost row, which of A/B is closer to board 18's "Directional (Multi)"
   panel, and why; are the destination names legible at 1280x800 in both?
2. For each bridge deck row, which of A/B is closer to board 18's "Bridge Plank &
   Rail" panel, and why?
3. For the bridge approach rows: does the crossing read as HELD by a faction from the
   approach — barricade, banners, a guard, a light — in A, in B, in neither?
4. What is still wrong in the better of the two, ranked.

The judge was not told which sheet column was the new work, what had changed, or
what this lane hoped to hear. It was told the columns are labelled A and B, that it
was **not** told which column was the newer work, and explicitly that it must not
assume either column is the improvement. It was instructed not to read any source,
report, config or anything else under `ralph/`, `scripts/` or `data/`.

**The column order is deliberately the opposite of W22's.** That lane put its
"before" in A and its "after" in B, and its judge identified B as the finished pass;
a second round using the same layout would let a judge score by position rather than
by frame. Here **A is the newer work and B is the older**, and the judge was told
neither fact.

---

## Round 2

Round 1 flipped the barricade-texture and signpost-lettering verdicts and did **not** flip
the barricade-placement or guard-colour ones (see `JUDGE.md`). Round 2 changed only those
two things and re-rendered the two checkpoint stands, so the round-2 sheet is two rows,
`_sheet_checkpoint_r2_ab.png` — `bridge-approach-played` and `bridge-checkpoint-shoulder`,
A this lane, B `main`, both rendered in this container minutes apart from the same base.

A **fresh** sub-agent was used, with no memory of round 1 and no access to round 1's
frames, verdict or scratch directory. It was given the one sheet, the same
`docs/reference/`, the same board 18 and the same visual-judge skill, and the same
column-blindness instruction. Its questions were narrowed to the two open items and were
written to be answerable only by measuring:

1. Does the crossing read as HELD by a faction from the approach — barricade, banners, a
   guard, a light — in A, in B, in neither?
2. The barricades: (a) textured or untextured blockout, in A and in B? (b) beside the road
   or controlling passage across it — **measure the road's own width in the frame and the
   width of the clear gap left between the two pieces, and say what could pass through it**,
   for A and B separately.
3. The guard: does she wear the faction's colour — the oxblood on the banners in the same
   frame — in A, in B, in neither? **Sample the torso and the banner cloth in the same
   frame and compare hue, saturation and the red-to-blue ratio.**
4. What is still wrong at this checkpoint in the better column, ranked worst first?
5. An explicit SHIP / DO NOT SHIP call on the checkpoint dressing, and for each thing still
   short, whether closing it is art that must be made or scene/material work with what is
   already in the frame.

It was not told which column was newer, what had changed, that a previous round existed,
or what this lane hoped to hear.
