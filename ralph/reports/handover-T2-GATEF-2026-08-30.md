# Handover — T2-GATEF operator lane, interim, 2026-08-30

**Branch:** `ralph/T2-GATEF`, off `origin/main@a97f3e84`. **Run directory:**
`ralph/reports/gate-f-run-20260828T183531Z`. **Status: interim, not final.**
This is written at a natural pause point — every segment this lane could run
without an external fix has been run, and the remaining work (X03, X06, and
the full S03-S10 re-run) is blocked on a fix landing on `ralph/T2-BUILDPLACE`.
I am continuing to watch for it; this document will be updated or superseded
once it lands and the re-run happens.

---

## 1. What I was asked to do, and what actually happened

Asked to: (1) rewrite the two stale findings documents from the run's own
evidence, (2) run X04, X07, X08, then (3) re-run X03, (4) run X01, (5)
decide on and run X05, (6) run X06 last and stop it early, (7) write this
handover.

**What actually happened diverged from that ordering twice, both times
because the coordinator's own segment-exposure claims turned out to be
wrong** — caught once by me (X04's `S06-exit` entry is not position-clean)
and once by a concurrent lane (`T2-STRANDING`: the real contamination
boundary is `S02-exit`/`S03-exit`, not S05 or S06, and it's the party's HP,
not position, that matters). The coordinator revised the brief twice in
response, correctly, and said so. **X03 and X06 were never run** — they were
gated off partway through by the coordinator's first correction and have
stayed gated since, correctly, because the concurrent stranding
investigation was still active. **The S03-S10 re-run is now a new standing
assignment** (added by the owner via the coordinator, after this lane's work
was already in flight) that supersedes the original "re-run X03" task — it
is larger and is the actual prerequisite for X03 and X06 both.

## 2. Segments run, in the order they actually happened

| Segment | Result | Notes |
|---|---|---|
| (docs) | Rewrote `GATE_F_RUN_3_FINDINGS.md` and `GATE_F_RUN_3_RIG_FINDINGS.md` from the run's own `INVENTORY.json`/`events.jsonl`/`notes/*.md` | Done first, per brief. Both then updated four more times as new findings landed (RIG-19 through RIG-22, GAME-0, GAME-5, GAME-6). |
| X04 | Complete, 104/124 PASS, 12 FAIL, 8 DELEGATED, **0 `combat_start`** | Compromised: all three entry saves carry a fainted party (found after the fact, via T2-STRANDING); its own `move_to` steps separately undershoot every combat site regardless (RIG-19, found by this operator). Annotated in place, not deleted — `X04/CONTAMINATED_ENTRY_SAVES.md`. |
| X07 | Complete, 183/266 PASS, 3 FAIL, 80 DELEGATED | Clean, DIAG/teleport, no save dependency. Found RIG-20 (region containment reports `corridor` even 5.7-6.3km from the bridge, at the Stronghold approach and the Hall — open question for T2-STRANDING, not resolved here). |
| X08 | Complete, 62/62 PASS | Clean, DIAG/teleport, no save dependency. No findings. |
| X05 | **Stopped deliberately by this operator**, 10 of 16 `seed_save` blocks completed, no `INVENTORY.json` | 8 real `S0n-exit` blocks + 2 extra slot saves are real evidence. Stopped after the remaining blocks (missing `S10-exit` + 5 missing `X06-awkward-*` saves) reproduced the known RIG-4 pattern 4 times in a row — confirmation, not new information. Found RIG-22 (the same RIG-14 tab-cycle defect, unfixed, in X05's own save-verification steps — no confirmed evidence anywhere in this run that the Save tab actually writes a file). `X05/INCOMPLETE.md` explains the decision. |
| X01 | Complete, 1092/1203 PASS, 103 FAIL, 8 DELEGATED | Found GAME-6 (10 matrix cells across two tabs show `menu_cancel` failing to close the pause shell — confirmed tab-specific by contrast with a passing Map-tab probe). Confirmed RIG-5 recurring (two 60-second `move_to` stalls held by a narrative modal). Only 4-5 of 103 FAILs mention combat — consistent with T2-STRANDING's read that X01 is low-exposure to the fainted-party contamination despite its own entries carrying it. |
| X03 | **Not run — held**, per the coordinator's gate | Both entry saves (`S05-exit`, `S08-exit`) are contaminated; re-run needed once the chain is healthy. |
| X06 | **Not run — held**, same gate | Seeded from `S03-exit`/`S05-exit`, both contaminated; would also hit a genuine multi-hour cost-gate BLOCKER even once healthy (2.42M `move_to` frames). |

## 3. The two exposure corrections, in detail (this matters more than any single segment result)

1. **This operator's own correction** (commit `40ac89d2`): the coordinator's
   first exposure table called X04's `S06-exit` entry "pre-stranding." I
   checked `S06`'s own `route.csv` directly and found its last position is
   inside the exact stranding cluster — not pre-stranding at all,
   positionally. This was still incomplete, in a way that mattered more (see
   next).
2. **T2-STRANDING's correction, one level deeper** (`origin/ralph/
   T2-STRANDING@08506512`): checked exit-save *party contents*, not
   position, and found the real boundary is `S02-exit`/`S03-exit` — every
   exit save from S03 onward carries a permanently fainted party, because
   S03's own catch loop faints the player's only creature on a fair roll and
   nothing in the run ever healed it. **This is the root cause of the
   position-stranding too**: a fainted party can't be summoned, so
   `can_challenge()` correctly refuses every gate fight, so the South Bridge
   (a real, correctly-locked barrier) never opens, so every `move_to` past
   it is walking into a wall — which is what drives the position clustering.
   One root cause, two symptoms. **Verdict: RIG, not GAME, confirmed live in
   the engine** (T2-STRANDING's own probe, `probe_stranding_cause.gd`).

**Lesson for whoever reads this next**: an exposure claim based on segment
*structure* (which save a `.json` file names) is not the same fact as an
exposure claim based on save *contents* (what's actually in that file), and
the gap between them was wrong twice before someone checked the file
itself. Read the save, not the inference.

## 4. Two severe findings that surfaced along the way, not from this lane's own running

Both are credited to other lanes, not verified independently by this
operator, and both changed how the findings documents read:

- **GAME-0** (T2-BUILDPLACE, `cb3e8b56`): `encounter_director.gd::
  interaction_offer()` unconditionally returns a priority-100, distance-0
  "is out of the fight" prompt whenever the tracked ally is fainted, with no
  proximity gate — outranking *every* other interaction in the world for the
  rest of the live session, until a reload. A real player whose only
  creature faints during the ordinary opening catch attempts becomes unable
  to interact with anything, with no hint that a reload is the fix. Not
  fixed (belongs to `scripts/combat/**`, owned by a concurrent T3-TYPECHART
  lane) — named loudly for whoever picks it up next.
- **GAME-5** (T2-STRANDING): a narrower, related gap — `trainer_npc.gd`
  shows the same `defeated` dialogue line whether a trainer was actually
  beaten or the challenger has no usable creature, and `party.gd::
  all_fainted()` has zero callers anywhere, so nothing explains the state to
  a player. Not a soft-lock (creature beds are always reachable), just
  confusing.

## 5. What I would do next, concretely, in order

1. **Keep watching `origin/ralph/T2-BUILDPLACE`** for its fix to land and
   for `ralph/reports/handover-T2-BUILDPLACE-2026-08-30.md`. As of this
   writing it is at commit `9275e3b4` (a full S03 replay was in flight to
   confirm a healthy exit save; no confirmation had landed yet).
2. **When it lands, verify the save myself before trusting it** — per
   T2-STRANDING's own stated lesson, read `S03-exit.json`'s actual party HP,
   do not infer health from `"complete": true`.
3. **Then own the S03-S10 re-run**, seeding each segment from the previous
   segment's freshly-produced healthy exit, superseding (never deleting) the
   existing S03-S09 directories per `RESTARTS.md`'s own convention, with an
   annotation explaining the originals ran against a fainted party.
4. **S10 will very likely hit its own real cost-gate BLOCKER again** — that
   one is a genuine capacity limit (0.097 s/frame measured through real
   combat against a 14400s ceiling), not a pricing bug. Splitting it into
   sub-segments each under the ceiling is worth trying; this is my own
   judgment call to make when I get there, not yet decided.
5. **X03 and X06 unblock at the same moment** the healthy chain exists —
   run X03 first (cheaper), X06 last and stop it early per the existing
   guidance if it reproduces a new stranding-shaped pattern (it should not,
   post-fix, but confirm rather than assume).
6. **Re-run X04 and X05** once healthy saves exist — both were compromised
   or incomplete this pass for reasons the fix should resolve. X04
   additionally needs RIG-19's `move_to` budget-sizing gap addressed by
   whoever owns `tools/gate_f/segments/X04.json` next, or it will undershoot
   its combat sites again regardless of party health.
7. **Do not re-run X01, X07, X08** — all three are either genuinely clean
   (X07/X08) or only marginally exposed in a way already accounted for
   (X01), and re-running them would not change their findings.

## 6. Disagreements / judgment calls I made, stated plainly

1. **I killed X05 mid-run rather than letting it finish.** The remaining 6
   of 16 blocks were guaranteed, predictable RIG-4 non-evidence (missing
   `S10-exit` + 5 missing `X06-awkward` saves), and the pattern had already
   reproduced 4 times before I stopped it. I judged the ~15-20 minutes that
   would have bought zero new information not worth spending, applying the
   same reasoning the coordinator's own brief used for X06. I believe this
   was correct, but it is a real deviation from "run every listed segment to
   completion," stated here rather than left implicit.
2. **I did not independently verify GAME-0 or GAME-5/RIG-21's live-engine
   claims** — I relayed them from the T2-STRANDING and T2-BUILDPLACE
   commits, cited exactly, with clear "not verified by this operator"
   language in both findings documents. I did independently verify the
   parts I could check cheaply from this run's own artifacts (exit-save
   positions for RIG-13's correction, the exit-save table's shape being
   consistent with what I could read directly).
3. **The two findings documents have now been rewritten so many times in
   one session that "rewritten once, cleanly, from the ground up" (the
   original brief) has become "living documents updated in place as new
   information landed."** I believe this is the right call given how fast
   the ground truth changed underneath this run (three separate corrections
   to the same root cause in one afternoon), but a future reader should know
   the documents' own history is itself evidence of how unstable this run's
   "current understanding" was — see each document's own inline
   corrections rather than trusting a single clean narrative.

## 7. File footprint

**Owned and touched, all inside `ralph/reports/`:**
- `ralph/reports/GATE_F_RUN_3_FINDINGS.md` — rewritten, then updated 5 times
- `ralph/reports/GATE_F_RUN_3_RIG_FINDINGS.md` — rewritten, then updated 4 times
- `ralph/reports/gate-f-run-20260828T183531Z/X04/` (new, complete, plus `CONTAMINATED_ENTRY_SAVES.md`)
- `ralph/reports/gate-f-run-20260828T183531Z/X07/` (new, complete)
- `ralph/reports/gate-f-run-20260828T183531Z/X08/` (new, complete)
- `ralph/reports/gate-f-run-20260828T183531Z/X05/` (new, stopped, plus `INCOMPLETE.md`)
- `ralph/reports/gate-f-run-20260828T183531Z/X01/` (new, complete)
- `ralph/reports/gate-f-run-20260828T183531Z/X03-killed-1/` (renamed from the prior session's killed `X03/`, no content changed)
- `ralph/reports/handover-T2-GATEF-2026-08-30.md` (this file)

**Verified before every commit** (`git status --short`): nothing outside
`ralph/reports/` ever appeared as a pending change. No game code, data, or
config was touched by this lane.

**Environment note for the next session**: Godot 4.7-stable linux editor,
sha256 `f85bbc6b15e22416c7d797cd60b63286dd67b9cb13498847056c18520ae55a75`
(verified against `RUN_METADATA.json`'s recorded value — this session did
that check the prior session flagged skipping), installed at
`~/.cache/tetherbound-art/godot`. Import cache built fresh
(`.godot/imported`, 1492 files, gitignored — redo `godot --headless --path .
--import` on a fresh container, ~5 min).
