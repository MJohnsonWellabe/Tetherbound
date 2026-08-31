# Coordinator handover — 2026-08-31 21:35 UTC

Written by the outgoing coordinator for its successor, at the owner's
request ("archive everything including yourself. it's time for a new
coordinator"). Three lanes are deliberately left running — the owner said
"keep those three going" — do not archive them on arrival; pick up
monitoring them instead.

## Live lanes at handover (3) — do not archive on arrival

| Lane | Session | Branch | State / what to do next |
|---|---|---|---|
| **GATE-F-CAPSTONE-2** | `session_01K6aTrnpLWi4FDm8F9LUFfd` | `ralph/GATE-F-CAPSTONE-2` | Real full start-to-finish capstone playthrough, restarted clean after CAP-1 landed. Was on segment S06 at handover, S05 save pushed. Hourly check-in trigger `trig_01QstJiHWPrwjnTFc29rMQAb` (fires `9 * * * *`, bound to this session) is live — let it keep firing. If it surfaces a new blocking finding (like CAP-1/CAP-2 below), follow the same protocol: stop the capstone from cascading past the finding, spin up a **separate** dedicated investigation session (do not let the capstone operator fix its own finding — `GATE_F_MASTER_PROTOCOL.md` §13 role separation), land the fix through the normal branch/CI/sweep process, then restart the capstone fresh once the fix is on `main`. |
| **CAP-2** | `session_01NqS2KpQew9CHvmy3DAhCPX` | none yet | Investigating a finding from the capstone's S03/S04: no way to heal a living-but-damaged creature outside of fainting (a real dead end, same class of defect as CAP-1). Was actively running at handover, no branch pushed yet. When it reports back: review its fix like CAP-1's — build a landing branch off current `main`, run the targeted test slice + full suite, push, verify CI job-by-job (not badge), dispatch `ralph-sweep.yml`, confirm landing via `git merge-base --is-ancestor <tip> origin/main`. Once landed, restart the capstone per the note above. |
| **VISUAL-CENSUS-2026-08-31** | `session_01T2mkcTX45pLaS9kNGrGZJi` | `ralph/VISUAL-CENSUS-2026-08-31` | Full blind visual-judge sweep across environment/village/creatures/combat/humanoid cast/camps/HUD/terrain, per the owner's "we are going to need to run a visual judge on everything and have something else start fixing visuals where they're not right." **Diagnosis only** — it is explicitly told not to fix anything itself. When it reports back it should have pushed `VISUAL-CENSUS-2026-08-31.md` plus a new "Wave 3 — visual census" table in `ralph/reports/audit/BACKLOG-FROM-AUDIT-2026-08-31.md`. Land that report doc the same way the D6 status report was landed (merge onto current `main`, verify no code changed, push, CI, sweep). Then launch Wave 3 fixes as separate bite-sized sessions, one per defect, same discipline as Wave 1/2 below — **do not** batch a multi-step visual fix (diagnose-then-fix) into one session; split it, per the owner's standing instruction earlier this session: "keep everything in small discrete tasks... I want these to be very focused sub streams."

## What landed today (2026-08-31), confirmed by ancestor check, not badge

- `ralph/LAND-BACKLOG-0831` → GAME-F4 save/load fix (8 Gate-F-leg branches
  reconciled), CAP-1 fix, and Wave 1 backlog items (knife scale, rarity
  legibility, HUD health/day-time/story-tracker, I5/I6/I7 diagnoses, C1-NESS-FACE
  diagnosis, D6 mip-probe diagnosis, B2-GRASS-SEPARATION negative finding).
- `ralph/LAND-BACKLOG-0831-2` → Wave 2 backlog items: F3-GRANDPA-DIALOGUE,
  BED-SCALE-POSE, GLOW-PICKUPS-ONLY, VILLAGE-BERRIES, I6-MINIMAP-HEADING-FIX.
- `ralph/LAND-D6-STATUS` → D6-SEAM-PROBE-FIX's negative result (three shader
  fix mechanisms ruled out with real render evidence; the branch ships a
  verified 0-line shader revert, not a fix — see
  `ralph/reports/audit/D6-seam-probe/SHADER-FIX-STATUS-2026-08-31.md` for the
  full attempt log and the most promising untested lead: a control-map
  paint-boundary artifact, not a tile-position one).
- `ralph/LAND-BACKLOG-WAVE2-NOTE` → ledger bookkeeping only (marks Wave 2 items
  landed in `BACKLOG-FROM-AUDIT-2026-08-31.md`); should be through CI (docs-only
  fast path) and swept by the time you read this — confirm with
  `git merge-base --is-ancestor 5152429a... origin/main` before treating it as done.

All Wave 1 and Wave 2 backlog sessions are archived. `BACKLOG-D6-SEAM-PROBE-FIX`'s
session is archived too (it correctly stopped after ruling out its approaches
rather than continuing to iterate — do not reopen it; if someone wants to try
the paint-boundary lead, spin up a **new** session with that report as its brief).

## Still queued in the backlog ledger, not yet launched

See `ralph/reports/audit/BACKLOG-FROM-AUDIT-2026-08-31.md` for the full picture.
Held items (`NPC-DIALOGUE-TERSE`, `E-SCENE-TUNING`, `VILLAGE-LAYOUT`) are still
waiting on their owning Gate-F-leg lanes' scope (S03/S04/S06/S09) — check
whether those lanes have landed before launching. Wave 3 (visual census
findings) will appear once the census session above reports back.

## Process notes worth not re-learning the hard way

1. **`ralph-sweep.yml` has `MAX_BEHIND=20`.** A branch built off an
   older `main` and left for a while (a session iterating for ~2 hours, e.g.)
   can fall behind that cutoff and get silently skipped with "too far behind
   main to sweep, left alone" — not a failure, just needs a manual rebase onto
   current `main` (build a small `ralph/LAND-*` branch, merge the stale branch
   in, verify, push, dispatch the sweep again). Don't assume "sweep ran, badge
   green" means everything you expected actually landed — always check
   `git merge-base --is-ancestor <expected-tip> origin/main` for each branch
   you dispatched the sweep for.
2. **CI's `changes` job fast-skips pure `.md`-only commits** ("nothing but
   documentation changed") — a docs-only push can go green in ~1 minute
   legitimately, that's not a hidden failure. Adding even one `.gd.uid` or
   image file alongside the markdown drops it back to the full ~58-shard,
   ~15-25 minute run (longer than usual today due to runner-queue contention
   from many concurrent branch pushes).
3. **Never archive a session before confirming its branch's work actually
   landed** (merged into a landing branch that's since been confirmed on
   `main`), not merely "pushed" or "review_ready". Caught myself doing this
   once with `BACKLOG-KNIFE-SCALE` earlier in this session — the fix was to
   check `git log --all --oneline | grep <topic>` against the landing branch
   before archiving, and to re-merge it in when it turned out to be missing.
4. **Never archive a session that's still actively producing unpushed work.**
   If a session hasn't pushed anything yet, archiving it discards that work
   permanently — there is no branch to recover it from. Only archive once a
   session has pushed everything it has (even a partial/status-only commit,
   the way D6 did when it gave up on its fix attempts).
5. **A capstone finding a genuine blocker is not a capstone failure — it's
   the point.** CLAUDE.md's binding execution principle ("done when the
   complete player path produces the intended experience") only gets tested
   by an actual full playthrough; CAP-1 (tutorial-catch could faint your only
   creature with no way to revive it) and CAP-2 (no way to heal a living
   damaged creature) are exactly the class of bug unit tests can't catch.
   Treat each one exactly like CAP-1: stop the capstone, investigate
   separately, fix, land, restart clean.
6. **Stale one-shot poke triggers accumulate** (`trig_*` records for S05–S10CDE
   unblock/checkpoint pokes, all now-archived sessions) — they're harmless
   (poke-only, no cron, never fire on their own) but clutter `list_triggers`.
   Left them alone this handover for time; a cleanup pass with `delete_trigger`
   on anything whose `persistent_session_id` points to an archived session
   would be good housekeeping whenever there's slack.

## Mission reminder

Per `CLAUDE.md`: finish the Meadows as a complete, enjoyable first chapter —
roughly a 3-4 hour focused first clear — not as a collection of implemented
systems. The capstone passing clean end-to-end is the actual finish line for
that; keep chaining Gate F work toward it, and keep the backlog/visual-census
fixes flowing in parallel as bite-sized, independently-landable sessions.
