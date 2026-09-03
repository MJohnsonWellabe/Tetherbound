# Capstone 3 finding: S03's catch-to-team-of-five loop stalls at 2, reproducibly

**Author:** operator agent, Gate F capstone 3, tester role.
**Candidate:** `4ef01e4063a11ea0b30035d4ccab5ec8b2be0b9c` (origin/main HEAD at run
start; carries CAP-1 and CAP-2). No game code, data, or config was changed to
produce this finding.
**Run directory:** `ralph/reports/gate-f-run-20260831T223853Z/`
**Segment:** S03, four attempts (`S03-superseded-1` through `-3`, and the
final `S03` kept for the chain).

## In one line

Across four independent fresh S03 attempts against the CAP-1+CAP-2-fixed
candidate, the party never grew past 2 creatures. `tournament_build_team`'s
own objective text is *"Catch and raise a team for the village tournament"*
and the segment's own step-script (`tools/gate_f/segments/S03.json`,
`S03-32a`..`S03-32j`, ten numbered catch attempts) exists to do exactly that
— but only attempt "a" ever completed a throw in any of the four runs; every
subsequent attempt (`b` through `j`) FAILed at "challenge it" before a fight
could even start.

**This reads as a harness retry-pacing/targeting defect, not a game defect**
— see §3. It nonetheless makes the rest of the chapter untestable through
this exact script, because tournament sign-up requires `min_party_size: 5`
(`data/config/tournament.json`) and this ladder cannot currently produce
that party.

## 1. What CAP-1 and CAP-2 are doing right, confirmed here

Both fixes are verifiably working in every attempt:

- The starter enters S03's first fight near-full (110.3/117.6, not the
  53/117.6 CAP-2 found pre-fix).
- `potion_small`, `berries`, and `revive` are all present in every S02-exit
  save produced this run.
- Revives are consumed exactly as designed: every faint in every attempt
  is followed by the fainted creature returning to play before the segment
  ends (except attempt 1, which had a THIRD faint after both Revives were
  already spent — see §2).

## 2. What varies between attempts (genuine RNG, not a defect)

| attempt | fights | faints | revives spent | ends fainted? | wood/stone/fiber |
|---|---|---|---|---|---|
| 1 (superseded-2) | 4 | 3 (ripplet×2, bramblebun×1) | 2 (both) | **yes**, ripplet 0/117.6 | 8/8/0 |
| 2 (superseded-3) | 4 | 2 (ripplet×1, bramblebun×1) | 2 (both) | no | 16/8/0 |
| 3 (kept as S03) | 3 | 2 (ripplet×1, bramblebun×1) | 2 (both) | no | 16/8/0 |

Combat outcomes (how much HP each fight costs, whether a creature faints
outright) clearly vary run to run — the same shape of variance the S02
catch-throw investigation established (`RESTARTS.md` in this run directory).
This part of the ladder is working as CAP-1/CAP-2 intended: the fix supplies
recovery items, and the outcome depends on how the fights go, not on whether
recovery is possible at all.

## 3. What does NOT vary: the catch loop stalls at attempt "a" every time

`grep -c '"type": "catch_throw"'` against each attempt's `events.jsonl`:
attempt 1 = 1, attempt 2 = 1, attempt 3 = 0, attempt 4 (kept) = 0. Party size
at segment close was 2 in all four. The FAIL reasons for attempts `b`
through `j` are consistent and specific — not a generic timeout:

```
### S03-32b2 -- challenge it (attempt 2)
- actual: FAIL the interaction arbiter is DISABLED -- a conversation, a
  naming prompt or a fight owns the screen (input_context 'combat'). No
  prompt is offered here and `interact` would go to whatever does own
  input.
```

```
### S03-32d2 -- challenge it (attempt 4)
- actual: FAIL the live prompt is "[img=...]xbox_rb.png[/img] Put Moss
  away", which does not contain "Engage" -- pressing here would activate a
  different provider. Not pressed.
```

```
### S03-32b2 -- challenge it (attempt 2)   [run 4]
- actual: FAIL the live prompt is "Ripplet is out of the fight.", which
  does not contain "Engage" -- pressing here would activate a different
  provider. Not pressed.
```

Reading the step sequence (`tools/gate_f/segments/S03.json` steps
`S03-30`..`S03-107`): each of the ten attempts is `move_to` a **fixed
coordinate** `(30, -40)`, `refresh_pois`, then `move_to_entity` the nearest
entity matching species `bramblebun`, then `interact_with` expecting the
prompt text `"Engage"`. After attempt "a" resolves (whether it wins, loses,
or catches), the script immediately moves on to attempt "b" at the *same*
fixed coordinate. Three things are visibly still true at that moment in
every run: the previous fight/catch has not finished unwinding
(`input_context` is still `combat`), the nearest `bramblebun` found by
`refresh_pois`/`move_to_entity` is the *same* individual (already fainted,
already caught, or already the player's own deployed creature), and the
live prompt is therefore "Put away" or "X is out of the fight" rather than
"Engage". None of attempts `b`-`j` ever recovers from this in any of the
four runs — once the loop desyncs from a live target after attempt "a", it
stays desynced.

**This is evidence of a harness defect, not a game defect**, for three
reasons: (1) the failure mode is about the *scripted retry's own pacing and
targeting*, not about wild creature availability — `refresh_pois` returning
the same already-resolved individual four times running is a query/targeting
bug, not a world-content shortage; (2) a real player, after catching or
losing to one wild creature, naturally walks toward a *different* visible
individual rather than returning to one fixed coordinate; (3) the FAIL text
itself names the mechanism precisely enough to locate the fix (wait for
combat to fully close, and/or exclude already-resolved entities from the
`refresh_pois` result) without touching any gameplay system.

## 4. A second, consistently reproduced shortfall: materials

Final inventory in every attempt shows `fiber: absent` (0) against the
segment's own documented requirement of 18, and `stone: 8` in three of four
attempts (the fourth's is not recorded but likely the same) against a
requirement of 8 — the exact one-node-wide margin `tools/gate_f/segments/
S03.json`'s own economy comment already documents. Consequently
`home_materials_gathered`, `home_built`, `creature_bed_built`,
`player_slept_at_home`, and `tournament_team_fed` never set in any attempt.
No individual `move_to`-to-a-harvest-node step ever FAILed, meaning the walk
to each node succeeded; the shortfall is in what was collected there, not in
reaching it. This is consistent with the same class of tool-equip-by-hand
issue the segment's own inline `_comment` blocks already flag ("T2-BUILDPLACE:
why the tools need binding by hand") — plausibly connected to the same
scripting fragility as §3, but not independently isolated here.

## 5. Disposition

Not routed to a game-code fix lane — the evidence points at
`tools/gate_f/segments/S03.json`'s own catch-retry loop and possibly its
gather/tool-equip sequence, which is Gate F **instrumentation** (§I of
`GATE_F_MASTER_PROTOCOL.md`), built pre-freeze and off-limits to the
operator mid-run ("the operator changes nothing during the run"). Recommend:

1. A harness-focused lane fixes `S03-32b`..`S03-32j` to (a) wait for
   `input_context` to leave `combat` before re-attempting, and (b) have
   `refresh_pois`/`move_to_entity` exclude entities already fought/caught
   this segment, so each of the ten attempts targets a genuinely live wild.
2. Re-run S03 after that fix to get real team-of-five/tournament-sign-up
   evidence. Until then, **no Gate F run through this exact script can
   produce valid S04+ (tournament and beyond) evidence** — every run will
   hand S04 a team of 2 against a `min_party_size: 5` requirement,
   regardless of how well CAP-1/CAP-2 hold up.
3. The materials/fiber shortfall (§4) is worth a look in the same pass,
   though it was not isolated from the catch-loop's own effects here.

This run continues into S04 anyway with the team-of-2 save, specifically to
record what the tournament sign-up flow actually shows a player short of the
requirement (E.6.12: "the guided chain should point at the next missing
prerequisite") — that evidence is valid and useful independent of the
above.
