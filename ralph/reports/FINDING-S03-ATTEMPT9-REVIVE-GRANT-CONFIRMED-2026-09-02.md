# S03 attempt 9 finding: the 10-Revive grant closes the revive wall for real

**Author:** operator agent, `ralph/GATE-F-S03-CATCH-LOOP`, attempt 9.
**Candidate:** `680e9026450838cccbea192e4c65702b7664519c` (this branch, carrying
the 2 -> 10 Revive grant raise).
**Run directory:** `ralph/reports/gate-f-run-20260901T220548Z-s03fix/S03`,
seeded from a freshly regenerated `S02` (`S02-superseded-1` was the stale
pre-fix save; the exit save this attempt actually used is the current `S02`).
**Segment:** S03 catch loop, all 10 numbered attempts. 406P/32F/6SKIP.

## In one line

The Revive economy wall found in attempts 6 and 7 is gone: every one of the
9 recovery blocks that ran this attempt found and used a Revive
(`focus_item 'revive'` PASS, all 9 — no `"the satchel does not hold it at
all"` anywhere in this run), 5 faints were recovered in full, and the party
never got stuck unable to re-engage. The party still didn't reach 5 this run
(stayed at 3), but for two reasons unrelated to revives — see §2 — not
because recovery ran out.

## 0. A process note: attempt 8 tested nothing

Before this attempt, an intermediate run ("attempt 8") was executed against
the same run directory's existing `S02-exit.json` and came back still
showing the 2-Revive wall. Investigation found why: `S03` does not replay
the opening dialogue itself, it loads a save produced by an earlier `S02`
run — one generated before the `opening.json` edit landed, so its telemetry
still read `gained [... revive +2]`. That attempt's S03 output was
superseded (`S03-superseded-8`) without being reported as a finding, since
it never actually exercised the fix. `S02` was re-run fresh against current
`main` before this attempt (`S02-superseded-1` holds the stale run); its own
telemetry now shows `gained [revive +10]`, confirmed before S03 ran.

## 1. The revive wall: gone

Every recovery block's `focus_item 'revive'` step (`S03-32ar2` through
`S03-32ir2`, all 9 that had a chance to run) reports:

```
actual: focus_item 'revive': cursor on cell 5 after 5 move(s) (from cell 0)
verdict: PASS
```

No `FAIL` anywhere in this run reading `"the satchel does not hold it at
all"`. Five faints occurred (Moss x2, Bramblebun x3) and inventory at the
end of the segment still shows `"revive": 5` — five spent, five left. The
starting grant now comfortably covers the faint rate this ladder produces,
with headroom to spare, which is exactly the design intent recorded in
D40's amendment.

## 2. Why the party still capped at 3 (not a revive problem)

Two separate, already-documented gaps, neither new:

1. **Catch RNG.** 5 throws landed this run (`catch_throw` at t=208, 248,
   293, 438, 465) and every one resolved to a `catch_result` with **no**
   `"party grew"` observation following — all 5 missed the catch roll, not
   the throw itself. `data/config/catching.json`'s steep `hp_curve` makes
   an under-weakened target (this segment's opener only weakens to
   ~50-65% HP) a real chance of failing even a dead-centre throw. This is
   the same variance noted in attempt 7's finding (§3 there); attempt 7 got
   1 landed catch out of 5 throws, this run got 0 out of 5 — both inside
   ordinary RNG range for a catch chance well under even odds at that HP
   band.
2. **The pre-existing engage/targeting gap** (attempt 7's finding §4): of
   the 10 numbered attempts, several again never reached a fight at all —
   `move_to_entity`/`interact_with` FAILs at attempts d, f, g, j this run,
   plus one `track_aim` budget-out at attempt e. Same class of defect
   already flagged as out of scope for the revive/aiming question.

Exit party: 3 members (Moss at 39.3/117.6, one Bramblebun fainted at 0 HP
but revivable, one Bramblebun at 46.8/93.7), objective still "Build your
full team of five." Not a stall — the segment simply ran out of its 10
numbered attempts before RNG and the engage gap let it land a 4th catch.

## 3. Conclusion

The owner's fix (raise the starting Revive grant 2 -> 10, `680e9026`)
directly answers attempt 7's open question and is confirmed working by
real, live execution: this ladder no longer runs out of Revives under any
attempt observed so far. The remaining gap to a full five-creature party
in one scripted pass is catch-rate variance and the engage/targeting
coverage gap, both pre-existing and independent of this fix — candidates
for separate follow-up, not a reason to revisit the Revive grant.
