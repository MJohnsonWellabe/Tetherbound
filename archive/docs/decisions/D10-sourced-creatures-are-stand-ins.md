# D10 — Sourced creature and character art is a stand-in, and the gap is named

**Status:** accepted
**Found during:** MA1/MA2, the first two art passes

## The decision

Every creature and character mesh in the build is a **stand-in**. They exist to
prove the systems around them — rigging, clip mapping, scaling to a gameplay
collider, animation driven by combat state — not to be the game's look.

The gap between them and the owner's bar is recorded, measured, and left open
rather than argued away. It closes by commissioning or making art, and by
nothing else.

## Why this is written down at all

Because the alternative is what nearly happened twice: a rubric that quietly
exempts the assets it is hardest to fix.

`CLAUDE.md` says creature appeal must not be judged on *placeholders*. That rule
exists so nobody condemns a creature **design** on the strength of a grey
capsule. The visual-judge skill originally carried a caveat extending that to
sourced art, which turned it into a permanent exemption for exactly the thing
the owner's bar is about. That caveat was removed; the skill now says so
explicitly and says why.

The distinction that matters:

- A **capsule** carries no design claim. Judging it tells you nothing.
- A **sourced, finished-looking mesh** is being offered as the game's look every
  time it appears in a frame. Judge it as the game's look.

## What two rounds of blind review established

Round 1 (`archive/reports/docs-reviews-full/MA-01-first-art-pass.md`), unprompted, led with it: *"the
roster is one adequate stock mesh, one blob, and a Minecraft skin."*

Round 2 (`MA-02`), after the entire roster was replaced with better art from
better sources, led with it again, in numbers: two creatures from two different
pipelines with zero albedo variation between them, and a trainer at a 1:2.2
head-to-body ratio against the key art's 1:6.5.

Swapping one set of free assets for a better set of free assets moved the
*world* a great deal and moved the *creatures* not at all. That is the finding.

## What follows from it

1. **Keep the stand-ins.** Rigged, animated, correctly scaled stand-ins are
   worth far more than capsules: they exercise the clip pipeline, the fit code,
   the animator, and the combat-state mapping, all of which survive the art
   being replaced.
2. **Never let a stand-in set a design decision.** Species identity, silhouette
   language and roster composition are authored from `GAME_DESIGN.md` §26 and
   the key art's silhouette row, not reverse-engineered from what a free pack
   happened to contain. Bramblit is a Triceratops mesh today; Bramblit is not a
   triceratops.
3. **Keep spending on the world.** The critic's own split says roughly two
   thirds of its complaints are scene work. Ground materials, lighting, scatter
   authoring, landmarks, VFX and HUD are all reachable with free assets and
   engine work, and MA-02 shows they move.
4. **Report the gap in the critic's words, not mine.** The owner chose "free art
   only, report the gap". A blind reviewer's measurements are stronger evidence
   for what has to be bought than any argument made by the person who wants to
   buy it.

## What this does not license

It is not a reason to stop iterating, and it is not a reason for the critic to
go soft. Every round still gets both bar questions answered, and every round's
verdict is committed — including the failures. The point of naming the
un-closable gap is so the *closable* ones stop hiding behind it.
