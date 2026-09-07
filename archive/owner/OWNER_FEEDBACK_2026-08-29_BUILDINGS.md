# Owner feedback, 2026-08-29 — constructed buildings

Owner-play evidence, given directly. Under `CLAUDE.md`'s precedence rules this
is newer owner evidence and it outranks every other document in this repo for
what it covers.

## The verdict

| Location | Owner's judgement |
|---|---|
| The castle | **Bad.** |
| The stronghold | **Bad.** |
| Burrow Warrens — **interior** | **Good.** The rebuilt interior is liked. |
| Burrow Warrens — **exterior** | **Bad.** |

## What this confirms and what it corrects

The 2026-08-28 playtest localised "some locations still look lame" to a class
of space: "basically everywhere we had to build an under ground or build a
building". `CONTENT-0828B` answered that with a shared constructed-interior
method (`scripts/world/interior_structure.gd`) giving constructed rooms bays,
a jointed course, ceiling ribs landed on the bay divisions, framed openings
and corner posts, consumed by `burrow_warrens.gd` and `stronghold.gd`.

**That method worked for the Warrens interior and the owner now says so.**
Do not rewrite it. Do not "improve" the Warrens interior. It is the one part
of this class of space that is currently right, and it is the reference for
what right looks like.

**It did not fix three things**, and this feedback is what says so:

1. **The Warrens EXTERIOR.** The interior method never touched the approach,
   entrance, or how the burrow reads as an object in the landscape. A good
   room behind a bad door still reads as bad.
2. **The stronghold.** `stronghold.gd` consumes the same method, so the
   method alone is not sufficient there — the stronghold's problem is
   something the interior grammar does not reach. Diagnose before dressing.
3. **The castle.** Named separately from the stronghold, so treat it as a
   separate site until inspection proves otherwise.

## Direction for the lane that picks this up

This is `TETHERBOUND_VISUAL_STUNNING_PASS.md` §16 (architecture polish) with
owner evidence attached, and it interacts with §12 (landmarks and sightlines):
the stronghold and Meadows Hall are supposed to be visually dominant landmarks
that orient the player, so "bad building" and "weak landmark" may be the same
defect seen twice.

Work in this order:

1. **Render all four before changing anything.** Warrens exterior, Warrens
   interior (as the positive reference), stronghold exterior and interior, and
   the castle. Judge from the frames, not the code.
2. **Say what is actually wrong** in each, specifically. Silhouette? Scale?
   Door proportion? Foundation grounding? Material consistency? Repetition?
   Composition from the approach? The owner has given a verdict, not a
   diagnosis, and the diagnosis is the lane's job.
3. **Work out why the interior method succeeded** and whether the same
   thinking extends to exteriors and to the stronghold, or whether exteriors
   need their own grammar. That is the real question here.
4. Then fix, re-render, and compare against the Warrens interior as the bar.

Do not overfill with props. Every object should look intentionally placed.
`scripts/world/interior_structure.gd` is load-bearing and liked; extend it or
sit beside it, never replace it.
