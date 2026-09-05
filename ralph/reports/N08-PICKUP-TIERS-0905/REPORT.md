# N08-PICKUP-TIERS — report

Branch: `ralph/N08-PICKUP-TIERS-0905`, from `origin/main` at `f8a47ee4`.
Lane brief: `ralph/briefs/0905-followup/N08-PICKUP-TIERS.md` (with `COMMON.md`) — **not
present on any pushed ref when this lane started** (see "The brief" below). The lane
worked from the session title (*"make pickup tiers distinguishable by more than hue"*),
the W17 round-2 and W18 round-1 code-blind verdicts that raised the defect, and the
owner's board 17.

## What a player gets

Three candy grades that a player can tell apart, and rank, without a key and without
hue: a Good Candy is a small green candy with a leaf-disc on its crown; a Great Candy is
a bigger blue candy wearing a **star** and standing in a **bright ring on the ground**;
a Rare Candy is the biggest, amber, wearing a **spiked crown**, standing in a wider ring,
with two **wings** swept up and out from its wrapper ends, and the widest, loudest glow of
the three. More parts is worth more — one, two, three — which is the owner's own board-17
language (leaf / star and sparkle / crown, wings, glow). Every candy in the world also
turns slowly on the spot, the one motion cue every item game uses, and stays on the
ground.

Rare stopped being cream. Its glow was the same pale gold as its albedo tint, added at
1.7x, which clipped toward the white the meadow's cup flowers already own; it is now a
saturated amber carried on its own emission colour under a light albedo.

## The brief

`ralph/briefs/0905-followup/` exists on no branch, tag or PR head of the repository
(checked every remote ref at 13:40 UTC) and no other session was reachable to supply it.
Per the launch instruction ("make the smallest defensible call and record it"), the lane
took its scope from the session title and the two verdicts that routed this exact ask to
the coordinator: W18's `JUDGE-pickup-tiers.md` — *"give Rare a hue outside the
cream/white flower palette, and make the tiers differ by size or added shape as well as
tint"* — and W17's round 2 (*"what separates them is size, colour hue, and the number of
side attachments — all three changing at once"*; the wings *"appear to float"*). File
ownership was taken as the loader that owns the tier look and its test, plus one new
capture tool. `CURRENT_STATE.md` was not edited: it is the landing lane's file in this
cycle and every N-lane would collide on it.

**What the lane assumed and may be wrong about if the brief says otherwise:** that the
mesh is out of scope (no generation, per `CLAUDE.md`); that `pickup_glow.gd`,
`item_cache_pickup.gd`, `vegetation.gd` and `items.json` are other lanes' files and were
not touched; that grounded candies are wanted (no hover).
