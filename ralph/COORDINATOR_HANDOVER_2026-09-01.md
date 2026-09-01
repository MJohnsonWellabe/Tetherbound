# Coordinator handover — 2026-09-01

Written by the outgoing coordinator for its successor, at the owner's
request ("your time with me is over. I want a new coordinator which I'll
spawn but you write the doc for it"). Read this whole document before
touching anything. It replaces `ralph/START_HERE.md`'s current routing —
update that file's CURRENT STATE section to point here once you've read it,
per the standing rule that a stale routing doc is worse than none.

Do these five things today, in this order. The first is a hard blocker; the
rest can run in parallel lanes once it clears.

## 1. Get `ralph/LAND-MEGA-0901` green and land it on `main` — DO THIS FIRST

**Load `.claude/skills/overnight-coordination/SKILL.md` before you do anything
else in this section.** It exists because of mistakes made earlier in this
exact session — a real regression sat unwatched for six-plus hours because no
follow-up was armed, and a broken monitoring approach looked like it was
working when it wasn't. Don't repeat either.

### Current state

- `origin/ralph/LAND-MEGA-0901` (tip `9cc25bb6` at handover) is a single
  consolidated branch carrying **every** piece of overnight work — roughly
  180 commits ahead of `main`. It was built by merging ~20 individually-ready
  branches together, verified branch-by-branch against `main` (either a real
  git ancestor, or independently confirmed via test-merge that its content
  was already present under a different commit hash — see the branch's own
  merge commit messages for the specific reasoning per branch).
- `main` is still at `42a8641e` (a Gate F capstone checkpoint from the
  previous evening) — **nothing has landed on `main` today.** That is the
  single most important fact in this document.
- Every other `ralph/*` branch has already been deleted except `ralph-status`
  (kept as a historical log per the owner — pure documentation, safe to
  delete whenever you want, no code in it) and `ralph/LAND-MEGA-0901` itself.
  There is nothing else to consolidate. Do not go looking for more branches
  to fold in — this was done exhaustively, branch by branch, with the actual
  test-merge diff checked for each one, not assumed.

### The one open blocker: `Verify free_build` fails

The most recent full CI run on `ralph/LAND-MEGA-0901`
(`https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/33498366322`,
job `verify-gate-a-ui-build-shard`) failed on `Verify free_build`, **twice in
a row across two different pushes**, with the identical signature both
times:

```
FAIL: holding move_forward moved the player 82.01m while the build menu was open
FAIL: holding jump rose the player 129.04m while the build menu was open
```

This is real, not a flake — same magnitude both times, on two different
commits. `build_menu.gd` is documented elsewhere in the codebase
(`interaction_arbiter.gd`'s own header comment) as "the one panel in this
game that deliberately does not pause the tree," so player movement while it
is open has to be frozen some other way than `SceneTree.paused` — and
whatever mechanism does that is not doing it, or was never doing it and
`smoke_free_build.gd` just started catching it. Everything else on that run
passed, including `Verify post_modal_control` (a real regression found and
fixed earlier tonight — see that fix's own commit message,
`7d13f4c6`/`cf0b8fb5` era, for the investigation methodology if you need a
model for this one) and `authored_camps` (the old known arbiter flake, now
fixed, confirmed clean on every recent run).

Root-cause this before merging to `main`. Candidates worth checking first,
in no particular order: `scripts/player/` movement input reads and whether
they check `INPUT_OWNER`/menu-open state the way `interaction_arbiter.gd`
does; whether `build_menu.gd` opening should be setting some kind of
movement-lock flag that isn't wired up, or was wired up and got clobbered by
one of tonight's merges. `git log --oneline origin/main..origin/ralph/LAND-MEGA-0901`
gives you the full commit list if you need to bisect. If you don't have a
faster lead, delegate the actual bisection to a lane with Godot access (the
coordinator's own shell has none) rather than guessing from logs alone — see
the overnight-coordination skill's section on this exact situation.

### Once it's green

1. Fetch and confirm: `git fetch origin && git log --oneline origin/main..origin/ralph/LAND-MEGA-0901 | wc -l`
   should still show real content, and the CI run for the actual final
   commit should be fully green — read every job, not just the badge.
2. Merge `ralph/LAND-MEGA-0901` into `main` (merge commit, not squash — the
   individual commit history documents a lot of real investigation and
   should survive).
3. Confirm landing with `git merge-base --is-ancestor origin/ralph/LAND-MEGA-0901 origin/main`
   — never trust the CI badge or a session's own say-so for this.
4. `ralph/LAND-MEGA-0901` can be deleted once its content is confirmed an
   ancestor of `main`.

## 2. Full docs cleanup

Owner's own words: "a full docs cleanup as in delete the old Ralph docs and
back log and any old start here files that are out dated." Do this only
after step 1 lands — don't clean up the map while you're still using it to
navigate.

`ralph/` currently holds 52 markdown files, ~22,000 lines total. Two of them
are enormous and almost entirely historical: `ralph/DONE.md` (17,107 lines)
and `ralph/BACKLOG.md` (4,069 lines). Neither is wrong to have accumulated —
CLAUDE.md calls `BACKLOG.md` "the complete ledger/history" by design — but
the owner is explicitly saying that era is over and wants the clutter gone,
not archived-in-place.

Before deleting `ralph/BACKLOG.md`, **extract anything still actionable into
section 5 below's lane list first** — once it's gone, it's gone, and it is
the only remaining record of some genuinely unlanded backlog items (see
section 5).

Suggested approach, not a mandate — use your own judgment once you've read
the actual files, since some of this is easy to misjudge from a title alone:

- **Almost certainly safe to delete outright**: dated coordination/handover
  logs once their content is fully superseded (`COORDINATION_2026-08-25_*`,
  `COORDINATOR_HANDOVER_2026-08-29*`, `HANDOVER_2026-08-25*`,
  `HANDOVER_CONSOLIDATION_2026-08-25.md`, `STATE_OF_THE_THREE_TRACKS_2026-08-29.md`,
  `WEEKEND_MEADOWS_SPRINT_2026-08-21.md`) — this handover doc and the two
  before it (`2026-08-31`, this one) are the only ones anyone still needs,
  and even those stop mattering once their content is acted on.
- **Gate-specific evidence docs from gates that are long done**
  (`GATE_D3_EVIDENCE_2026-08-22.md`, `GATE_D5_EVIDENCE.md`,
  `GATE_D5_VISUAL_PASS_2026-08-22.md`, `GATE_D_LANE_CONTRACT.md`,
  `GATE_D_REMAINDERS.md`, `GATEB_TOURNAMENT_EVIDENCE_2026-08-22.md`,
  `GATE_C_EVIDENCE.md`) — check `ralph/ACTIVE_GAME_PLAN.md` for which gates
  are actually closed before deleting their evidence, in case anything in
  Gate D/C is still open.
- **Old owner playtest docs** (`OWNER_PLAYTEST_2026-08-18.md` through
  `OWNER_PLAYTEST_2026-08-30B.md`) — these are raw transcripts of what the
  owner said on each date. `OWNER_PLAYTEST_2026-09-01.md` (today's) is
  current and should stay; the rest are only worth keeping if something in
  them is still unaddressed — cross-check against `BACKLOG.md`/`DONE.md`
  before deleting, since that's exactly the kind of check that's easy to
  skip and regret.
- **`ralph/START_HERE.md` itself** — currently dated 2026-08-30 and full of
  stale routing. Once this handover's own content is acted on, rewrite
  `START_HERE.md` fresh rather than patching it again — it has accreted
  "CURRENT STATE" sections on top of "CURRENT STATE" sections for a while
  now (see its own file for how deep that goes) and reading it cold is
  exactly the "old start here files that are out dated" problem the owner
  named directly.
- **Keep**: `CLAUDE.md` (repo root, not in `ralph/`), `docs/GAME_DESIGN.md`,
  `docs/MEADOWS_PROGRESSION_SPEC.md`, `docs/TETHERBOUND_GAME_VISION.md`, the
  `docs/decisions/D*.md` canon records, `docs/ASSET_LEDGER.md`,
  `docs/art/HUMANOID_ASSET_INVENTORY.md`, `ralph/GATE_F_MASTER_PROTOCOL.md`
  (still governs the redo in section 4), and `.claude/skills/*` (including
  the `overnight-coordination` one written tonight). None of these are
  "old Ralph docs" in the sense the owner means — they're the actual current
  spec and canon, not process bookkeeping.
- Don't delete anything under `ralph/reports/` or `ralph/reports/audit/`
  without checking it's not the only copy of a finding that's still open —
  these are evidence, not process notes, and the owner's ask was about
  "docs" in the routing/bookkeeping sense, not the evidence trail.

## 3. Creature visual lane: field → bed → combat capture, blind review, fix

Owner's own words, verbatim, worth keeping intact rather than paraphrased:

> "I want a lane for visuals of every creature in a field then in bed then
> in combat, then a blind review of every frame, then a fix it everything
> the blind review says. The creatures need some glow, some illuminescense.
> They should be good colors, good size, and look good. They shouldn't look
> photo realistic. They should fit the game."

This is three lanes in sequence, not one:

**Lane A — capture.** Every creature species, in three contexts: standing in
a field (open ground, natural light — the existing survey/contact-sheet
pipeline in `.claude/skills/visual-judge/SKILL.md` and `tools/survey.sh` is
the right starting point, but that skill surveys *scenes*, not
*per-species-per-context* — you'll need a new capture script closer in shape
to `tools/_capture_bed_pose_survey.gd` (added tonight by the just-landed
`OWNER-0901-CREATURE-BED-POSE` work — read it for the pattern: instantiate a
real `creature_body.gd`, real materials, no mocks, one frame per
species/context, systematic naming), resting in a creature bed (that same
tool already renders this context, may be reusable directly), and mid-fight
in real combat (`smoke_combat.gd`/`tools/gate_f/` harness patterns for how
to stand up a real fight headlessly). One capture pass, all species, all
three contexts — a full contact sheet per context, plus individual frames.

**Lane B — blind review.** Follow `.claude/skills/visual-judge/SKILL.md`'s
actual mechanism exactly: a sub-agent that has never seen the conversation,
the diff, or what changed, looking only at the rendered frames plus
`docs/reference/` (the keyart board and the Palworld comparison shots) and
`GAME_DESIGN.md` §25. Don't have it review the whole scene composite the
skill normally produces — point it at the new per-creature/per-context
sheets from Lane A instead, and ask specifically about each creature's
legibility, color, size, and whether it reads as "fits this game" per the
skill's own standing instruction not to excuse a look just because the asset
is a stand-in. The owner's glow/luminescence ask maps directly onto
`_apply_field_separation()`/the `field_emission`/`field_rim` levers already
built tonight (`OWNER-0901-CREATURE-GRASS-VISIBILITY`,
`BACKLOG-B3-RARITY-LEGIBILITY`) — the review should say explicitly, per
creature, whether that lever needs raising, and the fix lane below has a
real mechanism to turn the dial rather than inventing a new one.

**Lane C — fix.** One session per finding, same discipline the owner set
standing weeks ago and this session has followed all night: small, focused,
one defect at a time, not one giant "fix everything" session. The owner's
constraints, repeated for whoever writes each fix's brief: good colors, good
size, visible against terrain (the whole reason the grass-separation work
exists), **not photorealistic** — stylised, fits the existing cohesive
world, per `GAME_DESIGN.md` §25's "stylised realism between Valheim and
Palworld." No new creature meshes or Meshy generations — CLAUDE.md is
absolute on this. Every fix is materials/scale/rim-and-glow-lever tuning on
the assets already installed, the same vocabulary tonight's
`OWNER-0901-CREATURE-GRASS-VISIBILITY` lane already proved out for three
species.

## 4. Redo Gate F, if it can be done

The owner's phrasing was conditional — "then a lane to redo gate f if it can
be done" — so the first job of this lane is judging feasibility, not
assuming it. Context for that judgment:

- `ralph/GATE_F_MASTER_PROTOCOL.md` is still the governing document — read
  its §13 role separation before doing anything: a capstone playthrough
  session **tests and records findings only**, never fixes its own defects.
  A separate lane does the fixing.
- Multiple capstone attempts ran tonight and in prior sessions
  (`GATE-F-CAPSTONE-1`, `-2`, `-3`, and the earlier `GATE-F-LEG-S03` through
  `S10CDE` chain) — all of their evidence is now merged into `main` via
  `ralph/LAND-MEGA-0901` under `ralph/reports/gate-f-*` and
  `ralph/reports/gate-f-run-*`. Read the most recent findings before
  starting a fresh run rather than re-discovering the same walls:
  - **`GATE-F-CAPSTONE-3`** found a catch-loop stall at S03 — worth checking
    first whether tonight's `GATEF-HARNESS-CATCH-TRACKING` fix (landed,
    fixes the harness's own scripted-throw aiming at a stale target
    position) actually resolves it, since that fix went in after this
    finding was recorded.
  - **`GATE-F-LEG-S04`**'s real finding (trainer battles ending outright on
    the active creature's faint even with a healthy bench) is now fixed and
    landed tonight — a fresh Gate F run should confirm the tournament
    semi-final is actually winnable now, which no capstone attempt has yet
    verified against the fix.
  - Several capstones found the chapter structurally blocked earlier than
    the tournament (`GATE-F-FULL`'s TRAVERSAL-F8: "the rig carries the
    chapter 1.3 km to the South Bridge; the game stops it 12.6 m short";
    `GATE-F-CAPSTONE-2`'s own S06 finding: "the chapter is walled at the
    South Bridge; bands 2-5 unreachable"). Confirm whether that's still true
    on current `main` before investing in a full redo — if the chapter is
    still walled well before the tournament, a full capstone run can't even
    reach the fights whose fix you're trying to verify.
- If a full capstone redo isn't yet worth the cost given the above, a
  narrower targeted verification (just the tournament, just the S03 stretch)
  may answer more per hour spent — that's the "if it can be done" judgment
  call the owner left to you.

## 5. Backlog lanes

Before `ralph/BACKLOG.md` is touched in the docs cleanup (section 2), pull
its still-open items into fresh individual lane briefs, same shape as every
`OWNER-0901-*` lane run tonight: one focused branch per item, small enough
to land in one CI cycle, evidence required before any "already fine"
conclusion is accepted (see the `OWNER-0901-VILLAGE-GATE-ROADS` /
`-V2` story in `ralph/OWNER_PLAYTEST_2026-09-01.md` for exactly what happens
when that discipline is skipped once). Batch the resulting branches into one
consolidated landing branch before pushing, exactly like tonight — the
"batch, don't fragment CI" lesson in the overnight-coordination skill
applies to this as much as anything else.

## What NOT to do

- Don't force-push over `ralph/LAND-MEGA-0901` or `main`.
- Don't merge to `main` with a reproducing CI failure, ever — the free_build
  failure in section 1 blocks everything downstream.
- Don't skip archiving/tracking sessions as lanes complete — every session in
  this document's five work streams should get archived once its work is
  confirmed landed, same as every lane tonight.
- Don't spend a Meshy generation or add a new humanoid/creature mesh without
  owner-supplied reference art — CLAUDE.md is absolute on this, and the
  creature visual lane (section 3) is explicitly a tuning pass on installed
  assets, not new art.
