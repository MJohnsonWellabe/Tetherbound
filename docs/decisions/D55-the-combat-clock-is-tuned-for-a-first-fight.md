# D55. The combat clock is tuned for someone's first fight

Kind: conflict

Combat pacing is set so a player who has never seen the game can win and catch
a Tuftmoth on their first attempt and understand every input they used. Where
that fights `GAME_DESIGN.md` section 7, the owner's direction wins and the
conflict is recorded here.

**The conflict.** Section 7 specifies a 0.6s telegraph on the enemy power
attack. It is now 1.2s. At 0.6s the tell and the hit read as one event to
someone who has not learned the animation yet, so the dodge it exists to teach
cannot be learned from it. Nothing else about the telegraph changed: it is
still the dodge window and a correctly timed dodge still negates the attack
entirely.

**What else moved, and why each one:**

- **An opening grace of 2.5s.** The wild pal holds an alert pose and does
  nothing. Section 7 already promises the throw is available in the opening
  second; this is what makes that promise usable rather than theoretical,
  because previously the opening second was spent being attacked.
- **A 4s floor on attack cadence,** with a per-species `attackCadenceMs` in
  `species.json` that may be slower and never faster. The floor applies to the
  boss too. A boss earns its difficulty from health and power attacks, not
  from out-pacing the player's ability to read the screen.
- **Meadows HP doubled,** so a fight runs 20-40s instead of about 5. Five
  seconds is not enough time to try a button, see what it did, and try
  another.
- **Flee moved from 20% HP at 25%/sec to 10% at 12%/sec.** The old numbers
  meant a first encounter usually ended with the target running away, which
  teaches nothing and reads as a bug. The pressure to throw early survives;
  it just no longer wins most of the time.
- **The enemy holds its attacks while an orb is in the air.** Aiming is never
  punished. A telegraph already in flight still resolves, because cancelling a
  wind-up the player was warned about would teach the wrong lesson.
- **Hit pause on a landed blow raised to 0.4s.** This one needed two edits: the
  `hitPause.maxMs` ceiling was 140, which silently clamped any larger value, so
  raising the impact numbers alone would have done nothing at all. It is still
  a ceiling and still stops repeated hits compounding into a hang.

The tuning is entirely in `moves.json`, `species.json`, `orbs.json` and
`fx.json`. `tests/combatClock.test.ts` asserts the pacing *contract* rather
than the numbers: that the opening is quiet, that the throw is legal on the
opening tick, that nothing beats the cadence floor, and that aiming holds the
enemy. The numbers are expected to keep moving; those properties are not.

One thing the tests caught that review would not have: the boss was given a
3200ms cadence, under the 4000ms floor the code clamps to. The behaviour was
right and the data was a lie about it. Data that claims something the code
cannot do is worse than no data, because the next person tunes the wrong knob.
