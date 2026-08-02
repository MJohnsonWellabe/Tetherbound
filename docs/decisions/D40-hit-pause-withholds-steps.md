# D40. Hit pause withholds simulation steps, it does not scale time

Kind: implementation

A freeze frame on impact has two obvious implementations and both break rules
this project already committed to.

Scaling `dt` toward zero is the common one. It violates the first rule in
`ARCHITECTURE.md`: simulation runs at a fixed 60Hz and gameplay is never scaled
by a variable delta. Every tuned constant in the game is written against a fixed
step, so a variable one silently retunes stamina drain, the 0.6s telegraph in
M2, and the catch-ring shrink, all at once and invisibly.

Skipping `requestAnimationFrame` is the other. Not rendering is what a hang
looks like, and it strands the accumulator: the banked time is still owed, so
the frame after the freeze runs a burst of catch-up steps and the world
teleports forward at exactly the moment the player regains control.

What `src/fx/hitPause.ts` does instead: the accumulator in `Loop.ts` runs
untouched and still spends the time it banked, but `main.ts` returns early from
the simulation body for the withheld steps. Rendering continues every frame. The
world does not advance, and the withheld time is discarded rather than replayed.
The spiral-of-death guard is never engaged because nothing accumulates.

The cap (`fx.json`, `hitPause.maxMs`) is load-bearing rather than polite.
Requests take the maximum of pending and requested rather than summing, so a
stream of impacts cannot each extend the freeze until the game stops simulating.
`tests/fx.test.ts` asserts the withheld time for any request is the requested
time plus at most one step, and that a pause always ends.

Input still runs during a freeze. Its edge detection banks a press otherwise,
and the buffered input fires on the frame the world resumes.
