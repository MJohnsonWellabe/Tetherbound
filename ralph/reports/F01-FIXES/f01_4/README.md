# F01#4: the practice target wins the tutorial engage offer

**Defect** (reproof row4-5, terrapup run 1): `encounter_director.gd::_engageable()` offered the nearest live wild in range. An ambient Mudsnout 2.56 m away therefore took the opening's practice fight from the practice Bramblebun 5.3 m away ("Engage Mudsnout").

**Fix.** The selection is now `choose_engage_target()`, a pure function.
- While the opening is on a beat listed in `opening.json` `encounter.practice_engage_priority_beats` (`walk_out`, `encounter`), an in-range creature of the practice species wins over a nearer creature of another species.
- An out-of-range, fainted or caught practice creature never blocks the ordinary nearest choice.
- `sequence_director.gd::_sync_practice_engage_priority()` pushes the species every frame and clears it on every other beat, so the priority ends at the first catch.
- Tunable: an empty list disables it.

**Tests:** `tests/test_practice_engage_priority.gd` (8 tests).
- The measured reproof field (2.56 m Mudsnout vs 5.33 m Bramblebun) offers the Bramblebun.
- With no priority, the nearest creature still wins.
- An out-of-range practice creature does not block; among several practice creatures the nearest wins; nothing in range offers nothing.
- The shipping config gives the priority on exactly its beats and ends it at `road`; an empty list disables it.
- The production wiring is source-checked.
- With the adjacent opening suites: 48 tests, 0 failed.

**Independent review:** APPROVE, no blocking findings. Its non-blocking findings (comment placement, syncing before the pending early return, a wiring test, comment wording) are addressed in the follow-up commit.

Not yet re-run: the full `smoke_gate_b_continuous --gate-b-full-chain` for terrapup, the run that originally met the Mudsnout.
