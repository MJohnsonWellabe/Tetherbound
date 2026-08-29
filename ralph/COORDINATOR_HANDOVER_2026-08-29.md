# Coordinator handover — 2026-08-29 11:40 UTC

Written by the outgoing coordinator for its successor. The overnight Routine
carries the operational protocol; this document carries what the Routine does
not: the live lane roster, the reasoning behind it, and the mistakes worth not
repeating.

## Live lanes at handover (8)

| Lane | Session | Branch | State / what is expected back |
|---|---|---|---|
| Warrens regression | `session_015JyhptmjXmhDZUfNeDTKGp` | `ralph/LAND-0829A` | **Critical path.** Root cause found, fix pushed `1656a714`, was checking a CI shard failure. Gates the LAND-0829A landing. |
| Gate F run 3 | `session_01UUsXzUUN4uCVWeXK1u8PhH` | `ralph/GATE-F-RUN-3` | Evidence run. S01–S08 done, RIG-5..RIG-18 recorded. Owes S09, S10, X01–X08. Records defects, does not fix them. |
| T3-RELAY | `session_014jvhRLfGvRXmYSdVP5mbXZ` | `ralph/T3-RELAY` | Tether Relay, first real enemy operation (§7). |
| T3-STRONGHOLD | `session_01FJUaj12fPf5rJNoiFpj49F` | — | Stronghold Approach / Meadows Hall, the exam. |
| T1-CAMP | `session_01ML2yKwcJtD3V23xa4UCYiS` | `ralph/T1-CAMP` | Campsite assets, first-hour beat (§17). |
| **Fable visual judge** | `session_01KfSj1FeS7goqnxBkCP9uab` | `ralph/JUDGE-VISUAL` | **New.** Blind verdict on 8 landed visual subjects. Renders FIRST, reads lane reports only afterward, reports disagreements. |
| T3-REWARD | `session_01Um4PKupsbmVjPiRm7v9o28` | `ralph/T3-REWARD` | **New.** Reward ladder §14 + roster temptation §11. |
| T1-CREATURE | `session_01The55kzW1eEMsv9A4HYsCB` | `ralph/T1-CREATURE` | **New.** Creature presentation §15. No new meshes, no Meshy. |

The last three were spawned at 11:35 and had not reported when this was
written. They are unproven; check them early.

## Why the judge lane exists

A large amount of visual work landed in the last 24 hours — castle triplanar
UVs and weathering, sun disc, warrens mound, stronghold lighting, water,
grass-far, terrain macro — and **not one frame of it was reviewed by anything
but the lane that wrote it.** The owner's model routing designates Fable as
the judge and it had never once been used.

The castle is the concrete case: the owner said "bad", a lane then found and
fixed a metallic-import bug and zero UVs, and nobody looked at the result.
This repo has repeatedly accumulated "confirmed fixed" prose while frames
stayed bad, which is why the judge is briefed to render before reading any
report and to report every disagreement between the two.

## Mistakes made in this session, worth not repeating

1. **I attributed a nondeterministic failure to a lane interaction.** I held
   seven lanes for hours on the theory that they broke the Warrens vault in
   combination. They never did — `wild_creature.gd`'s `_rng.randomize()` makes
   it a per-boot coin flip. The corrected account is in the Routine. Lesson:
   with a nondeterministic test, one green run proves nothing, and "A passes,
   A+B fails" is not evidence of causation.

2. **I diffed branches against `main` instead of their merge-base**, which
   manufactured phantom changes and nearly made me disbelieve a correct
   finding. Always use the merge-base.

3. **I read only page 1 of `list_sessions` for days.** `has_more` was true
   every time. Three lanes sat finished-but-unarchived for hours behind that
   boundary. Page until `has_more` is false.

4. **I rebased and pushed 8 branches at once**, queuing ~440 CI jobs and
   stalling everything. One integration branch, not many sweeps.

5. **I asked the owner questions I could have answered myself.** Stale routing
   docs were mine to fix, not to raise.

## Mechanics that are not obvious

- **Cross-session `SendMessage` does NOT reach cloud sessions.** To wake an
  idle lane: `create_trigger` with `persistent_session_id`, then
  `fire_trigger`. This works — two lanes woke within a minute today and one
  delivered the Warrens root cause.
- **`update_trigger` cannot change `persistent_session_id`.** To move the
  overnight Routine to a new coordinator you must delete and recreate it.
  Do that BEFORE archiving the old coordinator or the heartbeat dies.
- Sonnet lanes end a turn rather than looping. Idle-mid-task is the normal
  failure mode, not a crash. Wake them in place; do not archive them, their
  context is the valuable part.
- Sessions get 403 on remote ref delete. Stale branches need owner deletion.

## Open items for the owner

- **A live Meshy API key sits in the prompt text of three dormant Routines**
  (`Ralph`, `Ralph Lane B`, `Ralph Lane C`, last fired 2026-08-15). It is
  readable by anything that lists triggers. Worth rotating and stripping.
- `ralph/CONTENT-0828B` is confirmed fully superseded and needs deletion.
- Band 4's Air preparation beat before Captain Vess is unmet — recorded in
  `scripts/world/playground_world.gd` at the `TM_AT` collision note.

## Branch state at handover

- `main` @ `d6e77c79`
- `ralph/LAND-0829A` — 22 ahead, 0 behind, carries 7 lanes + the Warrens fix.
  The integration vehicle. Land when CI is green at JOB level.
- `ralph/GATE-F-RUN-3` — 54 ahead, evidence only, lane actively pushing.
  Leave alone until the run finishes.
- `ralph/CONTENT-0828B` — superseded, awaiting owner deletion.
