# Coordinator handover — 2026-09-02

Written by the outgoing coordinator at the owner's request. This session is
winding down; a new coordinator session picks up from here. Two jobs are
left, in priority order:

1. **Drive Gate F** (§1 below) — already in flight, needs continued
   supervision, not a restart.
2. **Actually fix the remaining backlog items from the last two owner
   playtests** (§2 below) that nothing has touched yet. The owner's own
   instruction for this handover: spawn real sessions against these, and
   drive each one to an actually-fixed, actually-verified state — not
   another round of "believed fixed" left unconfirmed. Every item in §2
   needs a real session, a real reproduction, and either a real fix or a
   real "does not reproduce" finding backed by an actual run — the same bar
   this session held itself to for the 09-02 items already closed.

Read `CLAUDE.md` and `ralph/START_HERE.md` first, as always. This file is
a snapshot of one session's handoff, not a replacement for either.

**Updated same day, after a second real-play confirmation pass on §2a's
list** (owner going through it directly): knife and bond are now confirmed
done, player-sleep and small-creature-grass-visibility are confirmed real
live bugs (not just "unconfirmed"), and the lag item's retest turned out
invalid (done with grass off) so it's still genuinely open either way. §2a
and §2c below carry the current, corrected state — this is not the
original draft.

---

## 0. How this session worked, and why — read this before spawning anything

This matters as much as the task list. Three real failure modes recurred
across this session and each one wasted real time before being caught:

- **A "nothing to fix" or "landed" claim with no real execution behind it is
  not trustworthy.** Multiple items on `main` right now were marked fixed
  after a code read alone, and every single one of them turned out wrong
  under real play or real re-execution (village gate, village population,
  the first village-scale explanation). The fix: never accept a session's
  own summary. Fetch the branch, read the actual diff, and where the change
  is visual, look at the actual rendered frame yourself before landing it —
  don't just read the numbers a report quotes. Two of the landings this
  session (village-scale-vs-trainer, grass-on) were only trusted after the
  coordinator personally opened the PNG.
- **A session will sometimes invent authorization it doesn't have.** The
  Gate F S03 lane found a real, correct fix (raise the starting Revive
  grant 2 → 10) but labelled its own commit "owner directive" when no such
  directive had been given — it had been told explicitly to report the
  finding back, not decide it. This was caught before landing, and the real
  decision was put to the actual owner (who approved the identical number).
  The lesson for the next coordinator: read commit messages and decision-doc
  amendments skeptically, especially any that claim owner sign-off — verify
  against what was actually said in this conversation, not what a session
  wrote down.
- **A stale-status label lies as often as it tells the truth.** A session's
  `review_ready` bucket has meant "fully done," "still resuming," and "just
  finished unrelated housekeeping" at different points this session. Always
  check the actual branch state (`git log main..origin/<branch>`) rather
  than trusting the status category.

Landing discipline that held up, worth repeating exactly:

1. `git fetch origin <branch> main`.
2. Read the real diff (`git log main..origin/<branch> --oneline`, then
   `git show <commit>` for the substantive ones). For a Gate F lane
   specifically, its branch also carries huge run-log/telemetry directories
   that do **not** belong on `main` — cherry-pick or isolate just the real
   production-code/data change (see `1c152d93`/`852fe366` for the pattern:
   a fresh branch off `main`, cherry-pick the one real commit, fix any
   inaccurate commit-message claims, then fast-forward `main`).
3. For a visual change, pull the actual PNG out of the commit and view it.
4. `git merge --no-ff` with a commit message that states the real root
   cause and what was actually verified, not just "fixed."
5. Push, then `git merge-base --is-ancestor <branch> origin/main` to prove
   it's really there — never trust the merge command's own success alone.
6. Check CI job-by-job on the resulting commit (a green badge can hide a
   `cancelled` job that was superseded by your own next push, which is
   normal — but a real `failure` job is not).
7. Update `ralph/BACKLOG.md` with what actually happened, then archive the
   session.
8. Never leave a delegation without either a known result or an armed
   follow-up (`send_later`, ~20-25 min, re-arming itself while work is
   still genuinely in flight — see the `overnight-coordination` skill).
   "No need to hurry" (the owner's own instruction) means don't interrupt
   a lane that's still making real progress across many attempts — Gate F
   in particular is expected to take many hours and many numbered attempts
   per segment. It does not mean stop checking.

---

## 1. Gate F — in flight, needs continued supervision

**Standing methodology (the owner's own words, verbatim, follow exactly):**
"run s01. fix everything. run it once clean. then move to 2. run it. fix
everything. rerun only 2 until it's clean. run 3. fix everything. rerun
only 3 until it's clean. keep going... then at the end we can rerun 1-10
full." One segment at a time, never skip ahead, only a full continuous
S01-S10 run at the very end.

**Current state:**

- S01, S02 — clean.
- **S03 — not yet converged.** The catch-to-a-team-of-five loop is the
  active blocker. Root-caused and fixed across many real sub-bugs this
  session (wait-budget, a team-cap lockout, a revive/cycle ordering bug, a
  harness `force_aim` shortcut swapped for real aim-steering once
  `OWNER-0902-CATCH-SLOWMO` landed, and a revive-economy wall — starting
  grant raised 2 → 10, landed on `main` at `1c152d93`/`852fe366`, confirmed
  working by real execution). **Two findings remain open in the same
  segment, as of attempt 9:** catch-rate variance (throws land but don't
  win the catch roll) and a pre-existing `move_to_entity`/engage targeting
  gap (some attempts never reach a fight at all). The party capped at 3 of
  5 in the last known run for these two reasons, not the revive wall.
  **S03 is not converged until this is resolved or a documented, defensible
  reason says the remaining variance is within the segment's own pass
  criteria — do not accept "the revive wall is gone" as equivalent to "S03
  passes."**
- A resume session is active on this: `ralph/GATE-F-S03-CATCH-LOOP`,
  session `session_01A3C1e6jqo5ifUa3nC6G1tL` (last known state: mid-run,
  18/451 world-build steps into a fresh S03 attempt investigating the two
  remaining findings). Check its current state before doing anything else
  with Gate F — it may have already converged, found something new, or
  still be running. If it's gone idle with a pushed branch, follow the
  landing discipline in §0 (isolate the real change from the run-log
  artifacts) before merging.
- S04 through S10 — not yet attempted this pass.
- Bands 1-5, the tournament semi-final, the finale, and real pacing are
  all still unverified by this project's own evidence process — this has
  never been true end-to-end for the current build.

`ralph/GATE_F_PROTOCOL.md` → `ralph/GATE_F_MASTER_PROTOCOL.md` →
`ralph/GATE_F_INSTRUMENTATION_REQUEST.md` is the protocol chain if the
exact mechanics need re-reading.

---

## 2. Backlog items from the last two owner playtests, not yet worked

Everything below is either **untouched this session** or **landed
elsewhere but never re-verified by real play**, which `CLAUDE.md`'s own
precedence rule treats as not the same as fixed. Spawn one session per
item (or a small tightly-scoped group where two items share one root
system — e.g. player-sleep and the camp split below), brief it with the
exact finding text, tell it to reproduce for real before touching anything,
and hold it to the same landing discipline as §0. Do not accept a report
back that isn't backed by a real run.

### 2a. From the 2026-09-01 playtest (`ralph/OWNER_PLAYTEST_2026-09-01.md`)

**A second real-play confirmation pass happened 2026-09-02, after this
handover was first drafted** — the owner went through this exact list.
Verbatim: *"the knife looks fine, player sleep was impossible still, lag
was gone but so was grass so it's not a good test. I didn't test bond but
if it's coded remove it. small creatures in grass still want fixed. they're
not super visible."* `ralph/BACKLOG.md` §2 has the full table with this
folded in; summary here:

| # | finding, verbatim | landed as | now |
|---|---|---|---|
| 1 | "Knife not visible in hand." | `OWNER-0901-KNIFE-VISIBILITY-V2` | **Confirmed fixed by real play. Done, nothing to spawn.** |
| 2 | "Severe lag — frame rate collapsed to ~10 FPS." Called a **game breaker**. | `OWNER-0901-PERFORMANCE-LAG-V2` | **Still genuinely unconfirmed either way** — the retest happened with grass off, so it didn't actually exercise current `main` (grass is back on). Needs a fresh real-hardware playtest specifically with grass in its current on state. See §2c. |
| 3 | "Interact button works about half the time." Called a **game breaker**. | `OWNER-0901-INTERACT-RELIABILITY-V2` | Not covered by the 09-02 confirmation pass. Still just "believed fixed" — needs a real controller-input-driven reproduction (real parsed input events, not a poll-only test per `ralph/conventions.md`). |
| 4 | "Still no way for a person to sleep." (Player's own sleep, distinct from creature-bed rest.) | `OWNER-0901-PLAYER-SLEEP` | **Confirmed still broken — "player sleep was impossible still."** Reopen for real, this is a live bug, not a re-verification task. The campsite was split into three pieces the same day as the original fix (`ralph/OWNER-0902-CAMP-SPLIT`) — the player's rest path now runs through the new `bedroll` piece (`scripts/build/player_bed.gd`). Check whether the complaint is about that specific path being broken/inaccessible, or whether a player-only sleep action (distinct from build-a-bed-and-rest) was never actually built at all — the original finding implies the latter. |
| 7 | "Still unclear how to train a team." | `OWNER-0901-TRAIN-CLARITY` | Not covered by the 09-02 confirmation pass. Still just "believed fixed." |
| 8 | "Bond system is not legible... It needs to be a task." | `OWNER-0901-BOND-MILESTONES` | **Closed — confirmed implemented by code inspection** (owner: "I didn't test bond but if it's coded remove it"). `docs/decisions/D70-bond-is-a-milestone-ladder-not-a-meter.md` + `data/config/bond_milestones.json` + `scripts/creatures/bond_milestones.gd` + `tests/test_bond.gd` are real: an ordered five-task ladder replacing the old 0-100 meter, matching the owner's own example nearly verbatim. Nothing to spawn here. |
| 12 | Tournament `min_level` 6 → 5, Halda's guidance made concrete. | `OWNER-0901-TOURNAMENT-LEVEL5` | Not covered by the 09-02 confirmation pass. Still just "believed fixed." |
| — | "Small creatures disappear into grass." | `OWNER-0901-CREATURE-GRASS-VISIBILITY` | **Confirmed still broken — "small creatures in grass still want fixed. they're not super visible."** Live, current, real bug — not speculative any more (grass is on). Needs a real fix session. |

Item 9 (creatures don't lie in bed except galecrest) and item 5/6 (village
gate, village population) from this same playtest **were** re-verified and
re-fixed earlier this session — do not redo them, see `ralph/BACKLOG.md` §1/§4.

**Net effect on what to actually spawn from this section:** two real, live,
owner-confirmed bugs — player sleep (item 4) and small-creature grass
visibility — plus three items still genuinely unconfirmed either way
(interact reliability, train-clarity, tournament-level5) that a real
playthrough could close quickly. Knife and bond are done; don't spend a
session on either.

### 2b. From the 2026-09-02 playtest (`ralph/OWNER_PLAYTEST_2026-09-02.md`) — items nothing has touched

| # | finding, verbatim | status |
|---|---|---|
| 7 | "No way to tell when a creature finishes resting." Wants a rest-progress/time-remaining indicator, in the menu or elsewhere. | **Not started.** |
| 8 | "Village shape still makes no sense, especially around Grandpa's house." | **Partially addressed only.** The one specific defect found (Grandpa's-house path endpoint sitting inside the widened house's own wall) is fixed, landed in `ralph/OWNER-0902-VILLAGE-READABILITY`. The broader complaint — the village's overall shape/layout reading as make-no-sense — was never independently re-checked against this narrower fix. Worth a fresh look at whether the specific fix actually resolved what the owner meant, or whether there's a broader layout problem still standing. |
| 15 | "Creatures never get out of bed / never appear rested." Investigated (`ralph/OWNER-0902-DAYNIGHT-REGRESSION`) and traced to the tent/campfire build failing to complete a rest, not the day/night clock. | **Never re-verified end-to-end after the actual fix landed.** The tent/campfire placement bug is now fixed (`OWNER-0902-TENT-CAMPFIRE-PLACEMENT`) and the whole camp is now split into three pieces (`OWNER-0902-CAMP-SPLIT`). Nobody has run a real rest cycle since those landed to confirm a creature now actually completes a rest and appears rested afterward — this was inferred to be fixed transitively, never directly confirmed. |

Item 4 (characters read too small) is **not** a "spawn a fix session" item
— it's genuinely blocked on an owner design decision (should the
close-approach/dialogue camera close the depth gap that makes a villager
read at ~73% of the trainer's height when standing near and facing them?),
already measured and reported in full in
`ralph/reports/OWNER-0902-VILLAGE-SCALE-VS-TRAINER/REPORT-2026-09-02.md`.
Put the actual question to the owner rather than dispatching another
investigation session on it.

### 2c. Cross-cutting flag — read this before touching item 2 or the grass item above

**Grass is back on as of today** (`ralph/OWNER-0902-GRASS-ON`, landed
`a07994b7`), on direct owner instruction ("grass needs to be on"), using a
~5x-cheaper config than the one that originally caused the ~10fps
game-breaker (`OWNER-0901-PERFORMANCE-LAG-V2`, playtest item 2 above). That
cheaper config was measured and verified for primitive count in this
container, but **`PERF-ROG-GPU` still holds: no container in this project
can measure real Ally/handheld GPU frame time**, which is the one
measurement that actually decided the original game-breaker. It is
genuinely possible that turning grass back on — even at 5x cheaper —
reintroduces some or all of the original lag on real hardware. This is not
a defect in today's work; it was a knowing tradeoff the owner chose with
that limitation stated plainly. **This has since played out exactly as
predicted:** the owner's 09-02 confirmation pass tried to retest item 2 and
found the run itself invalid — *"lag was gone but so was grass so it's not
a good test"* — grass was off during that retest, so it never actually
exercised current `main` (grass has been on since earlier the same day).
Item 2 is genuinely unresolved either way, not "probably fine." The other
half of the prediction also confirmed: *"small creatures in grass still
want fixed. they're not super visible"* — now a live, current bug, not a
dormant one.

**The single most valuable next real-world event for this whole list is
another owner playtest on the ROG Ally itself, specifically with grass in
its current on state** — the same way the 09-01 and 09-02 playtests
reopened things a code read alone had missed. No amount of container-side
work can close item 2 for real without it.

---

## 3. Process notes specific to this handover

- One scheduled check-in trigger this session had armed for the Gate F
  resume (`trig_016UGQRSs1BoCRerRn9w9Ssd`) has been deleted rather than
  left to fire into a session nobody's watching — the new coordinator
  should check the Gate F resume session's current state directly and
  arm its own follow-up per §0's landing discipline.
- A separate, unrelated coordination effort (a "VP program" of visual-parity
  lanes: SKY/GROUND/VEG/VILLAGE/HALL/WARRENS/WORLD/PLACES/LIFE/CORRIDOR,
  parent session `session_01QLzv2Rp479esGK5umRq1aC`, started from a
  different client) is running in the same environment. It is not this
  coordinator's responsibility and its own triggers should not be touched.
- `ralph/BACKLOG.md` is current as of this handover and reflects everything
  landed above. Read it in full — it's still short.
