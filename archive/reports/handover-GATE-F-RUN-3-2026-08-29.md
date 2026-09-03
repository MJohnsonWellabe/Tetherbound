# Handover — Gate F run 3, resumption session, 2026-08-29

**Branch:** `ralph/GATE-F-RUN-3`. **Last commit pushed:** `76351308` ("X03
in-flight snapshot, killed mid-run for owner stand-down").
**Run directory:** `ralph/reports/gate-f-run-20260828T183531Z`.
**Stood down by explicit owner instruction mid-turn** (coordination tooling
dropped out; lanes being stopped and restarted fresh). Not a failure of this
lane, not a criticism — see the owner's own message.

This is the fourth session to carry this run. The first three got it from
S01 through S06 plus assorted RIG-5 through RIG-18 fixes (see
`RESUMED_RUN_20260829.md` and `RESTARTS.md` in the run directory for that
history — I did not re-derive any of it, and neither should you).

---

## 1. What I was asked to do, and where I actually got to

Asked to resume from an in-flight S07 snapshot and carry the chain through
S08, S09, S10, then X01 through X08, then write the run's findings with
GAME and RIG findings clearly separated.

**Got to:** S07, S08, S09 all completed cleanly. S10 hit a genuine cost-gate
BLOCKER and did not complete. X02 completed cleanly. X03 was killed mid-run
by the stand-down and produced no usable evidence. **X01, X04, X05, X06,
X07, X08 were never started.** The final GAME/RIG findings write-up
(`GATE_F_RUN_3_FINDINGS.md` / `GATE_F_RUN_3_RIG_FINDINGS.md`) **was not
done** — both files are still in the state the third session left them,
which is stale (they narrate RIG-11 as if still unfixed; it has been fixed
and re-verified since S06).

Commits this session, oldest first (all on `ralph/GATE-F-RUN-3`):

```
258c318b  S07 in-flight snapshot reclaimed before any real evidence -- superseded, re-run pending
237b0ba7  S07 complete (River & Relay / Band 3) -- corridor stranding reinforced
729a9736  S08 complete (Upper Meadows / Band 4) -- same stranding
3c82cfe3  S09 complete (Stronghold approach / Band 5) -- same stranding, new save-handoff tab defect
60548372  S10 BLOCKED at step 26/121 -- real combat cost makes the finale infeasible on this host
c2c868a4  X02 complete (build/craft/gather lab) -- repeated d-pad focus-navigation defect
76351308  X03 in-flight snapshot, killed mid-run for owner stand-down
```

Every one of these is pushed. Nothing in my working tree is uncommitted —
verified with `git status --short` immediately before writing this file.

---

## 2. Done and verified, vs done but unverified, vs still open

**Done and verified** (each has `INVENTORY.json` with `"complete": true`,
committed, pushed):
- S07 — 99/99 steps, 68 PASS / 22 FAIL / 9 DELEGATED.
- S08 — 135/135 steps, 102 PASS / 22 FAIL / 11 DELEGATED.
- S09 — 76/76 steps, 56 PASS / 12 FAIL / 8 DELEGATED.
- X02 — 170/170 steps, 146 PASS / 20 FAIL / 4 DELEGATED.

**Done but incomplete-and-preserved-as-such** (this is itself the correct
evidence state per protocol, not a gap to close):
- S10 — 27/121 steps ran before a real BLOCKER. `BLOCKER.md`/`INCOMPLETE.md`
  are written. No `S10-exit` save exists.

**Killed, not evidence:**
- X03 — only world stand-up telemetry exists. Re-run needed from scratch.

**Never started, still fully open:**
- X01 (controller/menu exhaustion matrix — 1203 steps, the largest segment
  in the whole protocol by step count)
- X04 (combat lab — needs S04-exit, S06-exit, S09-exit; all three already
  exist and are complete, so X04 can start immediately)
- X05 (save/session lifecycle — needs every `S0n-exit`; S10-exit does not
  exist, so X05 will need to either accept S01-S09 only or be judged
  against what's available — this is a judgment call for whoever runs it,
  not something I decided)
- X06 (abuse & failure sweep — needs S03-exit, S05-exit; **read section 4
  below before running this one, it is very likely to repeat S10's shape**)
- X07 (DIAG world/regional audit — teleport-permitted, no journey-save
  dependency, should be cheap and fast)
- X08 (DIAG performance audit — teleport-permitted, no journey-save
  dependency, should be cheap and fast)

**Final findings write-up: not started this session.** The two documents
(`ralph/reports/GATE_F_RUN_3_FINDINGS.md` and
`ralph/reports/GATE_F_RUN_3_RIG_FINDINGS.md`) still read as the third
session left them. **Do not treat their current text as current** — in
particular `GATE_F_RUN_3_FINDINGS.md`'s opening section says "there is not
one `combat_start` event in this run" and blames RIG-11; that was true
when it was written and is no longer true (S07-S09 all have real telemetry,
`party size 1` throughout is now attributable to the South Bridge
stranding, not RIG-11).

---

## 3. The numbers, with how I got them

Godot binary: downloaded `4.7-stable` linux editor fresh this session
(container had none) —
```
curl -sSL -o godot.zip \
  https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip
```
sha256 not re-verified against `RUN_METADATA.json`'s recorded
`f85bbc6b15e22416c7d797cd60b63286dd67b9cb13498847056c18520ae55a75` — I
downloaded fresh rather than checking whether it matched byte-for-byte.
**Do this check before trusting cross-session frame-cost comparisons if it
matters to you**; I did not have reason to believe it would differ (same
tag, same official release asset) but did not confirm.

Import cache: `godot --headless --path . --import`, ~5 minutes, produced
`.godot/imported/`. Not committed (gitignored), so **every fresh container
needs to redo this** — budget 5 minutes before the first segment.

Per-segment wall time actually observed (CPU-seconds from `ps` at process
exit, single core, this container):
- S07: ~39 min wall, 99 steps
- S08: ~63 min wall, 135 steps
- S09: ~24 min wall, 76 steps
- S10: ~7 min wall to the BLOCKER at step 26/121
- X02: ~7.5 min wall, 170 steps

Estimating a segment's worst-case wall time before running it: sum
`args.budget_frames` across its `move_to` steps in `tools/gate_f/segments/
<ID>.json`, multiply by ~0.017 s/frame (walking baseline measured this
session). This undercounts badly once real combat is involved — S10's own
cost gate re-measured combat at 0.097 s/frame, **more than double** the
walking baseline, from a single `combat_quick` exchange. I do not have a
reliable per-segment worst-case estimate that accounts for this; treat any
number I give as a floor, not a ceiling.

S10's own BLOCKER, verbatim from the harness:

```
re-priced at in-play, the REST of this segment predicts 40195 s (11.2 h)
against 13974 s of the 14400 s ceiling left: 413884 planned frames at a
MEASURED 0.097 s/frame in THIS scene, plus a 0 s boot. The last price was
0.0400 s/frame. A GPU or a split evidence lane -- not a shorter wait; the
waits exist so fights resolve.
```

`severed_spokes` recovery-volume trigger counts (from grepping each
segment's own stdout log for `[severed_spokes] player went over the edge`,
logs not retained past this session — re-derive from a fresh run if you
need this again): S07 ≈ 649, S08 and S09 similar order of magnitude (not
recorded precisely, I was tracking the pattern not the exact count by
then).

---

## 4. What I learned that is not visible in the diff

### The South Bridge stranding is now the dominant fact about this entire run, past S04

This is the single most important thing to carry forward. It was already
an **open, not-chased-further** finding when I picked this run up (see
`RESTARTS.md`'s last entry and the two inherited-open-findings block in the
prompt that resumed me). I did not go looking for it. It found itself,
repeatedly, in the ordinary course of running S07 through S10:

**Every single `move_to` step in S07, S08, S09, and the first 22 steps of
S10 failed**, each one stopping between 1.6 km and 6.3 km short of its
target, and **every failure lands the player back at nearly the same tiny
cluster of local coordinates** — roughly x∈[0,16], y∈[-8,-2], z∈[1317,1326]
— which is the South Bridge carve corridor's own centre, already named in
`RESTARTS.md` ("stuck oscillating near (8,-3,~1317)"). The player has not
made net progress past that point since partway through S05. `scripts/
world/severed_spokes.gd`'s own recovery volume — a real game system that
catches a player who falls off the world and returns them to the road — is
firing on the order of 600+ times per segment, always at the same handful
of positions, which reads as the walk primitive being sent into the same
un-crossable spot over and over rather than as isolated bad luck.

**Consequence for everything downstream:** every band-3/4/5 objective flag
(`relay_captain_defeated`, `captive_rescued`, `relay_disabled`,
`mill_crossing_restored`, all three `defeated_captain_*` flags,
`hall_approach_open`, and whatever S10 would have asserted past step 22) is
unset **as a direct, mechanical consequence of the player never arriving**,
not as an independent finding about that band's own content. Read
S07/S08/S09's FAIL counts as "the stranding, counted once per assertion
that depends on it," not as 22+22+12 independent defects. I said this
explicitly in each segment's own commit message so it wouldn't need
re-deriving.

**What I do NOT know, and could not determine without repairing something**
(which I was told not to do, both by the standing protocol's operator role
and by an explicit routine instruction partway through this session): is
this the RIG's straight-line `move_to` primitive failing to navigate around
a real, legitimate terrain hazard that a real player with full movement
freedom would walk around easily — or is it a genuine GAME defect where the
walkable path itself is broken/absent at this exact spot? The prior
session's own open-finding writeup already flagged this ambiguity and named
the precise probe needed (`_ally`/`_ally.fainted`/`_ally_body`/
`is_instance_valid(_ally_body)` at the exact frame a challenge press lands)
without answering it. I have **more data volume** now (three more full
segments' worth) but **not a different kind of evidence** — I did not
attempt the probe, on the same "not chased further" basis the prior session
used. Do not read my added volume as new triangulation; it's the same shape
repeated, which raises confidence this is systemic but does not distinguish
RIG from GAME.

**One data point that might help distinguish them, which I noticed but did
not chase:** X02, running from `S03-exit` (before the stranding), did NOT
show this pattern — its two `move_to` FAILs were ordinary short misses of
tens to a few hundred metres, nothing like the multi-kilometre pattern.
So whatever this is, it is specific to something that changed at or after
S05, not a general property of the `move_to` primitive. That narrows it
usefully: it is not "straight-line walking is always this bad," it is
"something about the state at/after the South Bridge is different."

### S10's cost-gate BLOCKER is very likely NOT a rig mispricing bug (unlike CD-7c)

CD-7c, fixed earlier in this run, was a genuine pricing artifact: dividing
a slow Load screen's wall-clock time by the handful of physics frames that
ticked during it produced a wildly wrong s/frame extrapolation. I looked
for the same shape here and don't think it's present: S10's price jump
(0.0400 → 0.097 s/frame) happens **immediately after a real combat exchange**
(S10-23/24/25: `combat_quick` × 38, a party switch, `combat_quick` × 24),
and S10's remaining content (gauntlet, elites, the Warden, the legendary
choice) is combat-dense. A sustained ~2.4x cost through combat-heavy content
is a plausible real measurement, not a divide-by-a-handful-of-frames
artifact. I did not fix this or attempt a rig change — I was explicitly
told this session to record defects rather than repair them — but if a
future session wants to actually get S10 evidence, my read is that the
fix is a genuine capacity one (a faster host, or splitting S10 into
smaller segments each under the 14400 s ceiling) rather than a pricing-logic
bug to patch.

### X06 will very likely hit the same wall S10 did — budget accordingly before running it

I surveyed but did not run X06. Its own `move_to` steps carry
`budget_frames` up to 200,000 each, fourteen of them, summing to
~2.42M frames — at even the *walking* baseline (0.04 s/frame) that's
~26.9 hours, several times the 14400 s per-segment ceiling. Worse: most of
those large-budget targets (the river, Old Mill Crossing, the sigil gate,
the Hall shutter, the Warrens, "walk back over the South Bridge after
crossing") are exactly the far-side-of-the-bridge locations S07-S10 could
never reach. **I expect X06 to reproduce the corridor-stranding pattern for
most of its second half and then hit a cost-gate BLOCKER similar to S10's,
probably sooner** since it's seeded from `S05-exit` (already-stranded) not
a later save. Whoever runs it next should not be surprised by a BLOCKER
partway through, and should not spend hours waiting past the point the
pattern is already obvious from the first two or three large-budget misses.

### The Godot binary and import cache are not part of this branch and cost real time to rebuild

Every fresh container needs: download 4.7-stable (~75 MB, a minute or two),
then `godot --headless --path . --import` (~5 minutes, produces ~600+ step
reimport log, all warnings, no errors seen). Budget this before estimating
how long a fresh session needs before its first segment can even start.

### Git branch hygiene: watch for a stale local branch ref on a fresh checkout

Early this session, `git fetch && git reset --hard origin/ralph/GATE-F-RUN-3`
left me in a **detached HEAD**, with a stale local branch ref
`ralph/GATE-F-RUN-3` still pointing at a commit ~50 commits behind origin
(from before some earlier session force-pushed a rewritten history — I did
not investigate when or why, only that origin was self-consistent with
everything in the run directory and the stale local ref was not). A plain
`git push -u origin ralph/GATE-F-RUN-3` failed as non-fast-forward because
of this stale ref, not because of any real conflict. Fixed with
`git push origin HEAD:ralph/GATE-F-RUN-3` followed by
`git checkout -B ralph/GATE-F-RUN-3 origin/ralph/GATE-F-RUN-3`. **If a
fresh session hits the same non-fast-forward error on first push, check
`git branch -vv` before assuming real divergence** — it may just be a stale
local ref from container setup predating the branch's actual current tip.

### A tool-misuse note for whoever reads my transcript

Early in this session I called `ScheduleWakeup`, which is scoped to `/loop`
dynamic-mode sessions, not a background-task resumption like this one. It
did register a routine (visible as "Poke — Gate F run 3 lane" in
`list_triggers`), which then correctly fired and told me not to end turns
on background waits — which was good advice regardless of how it arrived,
and I followed it for the rest of the session (foreground polling loops
instead of ending turns on `run_in_background` waits). I did not clean up
that routine before stand-down; a successor or the owner may want to
`delete_trigger` it if it's not wanted, or leave it if it's useful for the
next lane.

---

## 5. Disagreements / things I believe are wrong or worth owner attention

1. **`ralph/reports/GATE_F_RUN_3_FINDINGS.md`'s current text is stale and
   should not be read as current.** It states flatly that RIG-11 blocked
   all combat and that no `combat_start` event exists anywhere in the run.
   That was accurate when written (after S01/S02) and has not been true
   since S06. Whoever writes the final version needs to fold in S03-S09's
   real (if stranded) evidence, not just append to the existing text.

2. **The South Bridge stranding deserves promotion from "open finding,
   not chased further" to "the dominant fact this run has to report,"**
   given how much of S05 through S10 it now explains. I want to flag this
   as my own judgment, not something the protocol told me to conclude: five
   consecutive segments (S05-S09) plus the first fifth of S10 have produced
   effectively zero new information about bands 2 through 5's actual
   content, because the player is not reaching any of it. If a future
   session's mandate is "get band 2-5 evidence," the actual prerequisite
   work is resolving this stranding (or at minimum running the probe the
   prior session already named), not running more journey segments against
   the same stuck save chain.

3. **I did not verify the Godot binary's sha256 against the frozen
   `RUN_METADATA.json` value.** Flagging this as a gap in my own rigor,
   not a finding about the game — see section 3.

---

## 6. File footprint

**Everything I touched is inside `ralph/reports/gate-f-run-20260828T183531Z/`
and `ralph/reports/`, plus this handover file. I did not touch any game
code, data, or config** (per the operator role — verified with
`git status --short` before every commit this session; nothing outside
`ralph/reports/` ever appeared as a pending change).

Created/modified this session:
- `ralph/reports/gate-f-run-20260828T183531Z/S07-superseded-2/` (renamed
  from the prior session's in-flight `S07/`)
- `ralph/reports/gate-f-run-20260828T183531Z/S07/` (new, complete)
- `ralph/reports/gate-f-run-20260828T183531Z/S08/` (new, complete)
- `ralph/reports/gate-f-run-20260828T183531Z/S09/` (new, complete)
- `ralph/reports/gate-f-run-20260828T183531Z/S10/` (new, BLOCKED/incomplete
  — `BLOCKER.md`, `INCOMPLETE.md`, no `saves/S10-exit.json`)
- `ralph/reports/gate-f-run-20260828T183531Z/X02/` (new, complete)
- `ralph/reports/gate-f-run-20260828T183531Z/X03/` (new, killed mid-run,
  telemetry only, not evidence)
- `ralph/reports/gate-f-run-20260828T183531Z/RESTARTS.md` (appended one row,
  the S07 supersession)
- `ralph/reports/handover-GATE-F-RUN-3-2026-08-29.md` (this file)

**Not touched, still stale, needs work:**
- `ralph/reports/GATE_F_RUN_3_FINDINGS.md`
- `ralph/reports/GATE_F_RUN_3_RIG_FINDINGS.md`

---

## 7. What I would do next, concretely

1. Run X04 first — its three entry saves (S04/S06/S09-exit) all already
   exist and are complete, and it's a combat lab so it will directly test
   whether combat itself works correctly when a fight *can* start, which is
   the single most valuable missing data point right now (S07-S09 never got
   a real fight to happen at all because of the stranding, so we have zero
   post-RIG-11 combat evidence).
2. Run X07 and X08 next (DIAG, teleport-permitted, no stranded-save
   dependency, should be cheap — my best guess is under 15 minutes each
   given they have no `move_to` steps at all).
3. Run X01 (large step count but no large `move_to` budgets — likely long
   in wall-clock purely from 1203 sequential steps, not from the stranding;
   budget accordingly, probably over an hour).
4. Run X06 last, and stop it early (don't wait out a multi-hour BLOCKER) once
   the first two or three far-side move_to steps reproduce the stranding
   pattern — that's confirmation, not new information, per section 4 above.
5. Run X05 and decide there, with fresh eyes, whether "every S0n-exit"
   without an S10-exit is close enough to proceed or needs an owner call.
6. Only then write the final `GATE_F_RUN_3_FINDINGS.md` /
   `GATE_F_RUN_3_RIG_FINDINGS.md`, and lead with the South Bridge stranding
   as the headline finding, not a footnote — see section 5.2.
