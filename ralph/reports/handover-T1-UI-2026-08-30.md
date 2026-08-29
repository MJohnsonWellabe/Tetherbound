# Handover — T1-UI — 2026-08-30

**Branch:** `ralph/T1-UI`, off `origin/main` at `a97f3e84`.

## What I was asked to do

1. Audit the owner board's (`docs/reference/owner-board-2026-08-15-systems-and-castle.png`)
   "UI / SYSTEM FIXES CHECKLIST" panel against the live build, push the audit
   first, then implement what turns out to be genuinely mine and genuinely
   unmet. Two items (movement/stairs, TM multipliers + ranged move VFX) are
   explicitly not mine — audit and report, do not fix.
2. A bounded §20 visual-polish pass on HUD/menus per
   `docs/owner-direction/TETHERBOUND_VISUAL_STUNNING_PASS.md` — readable
   controller prompts, typography, panel/margin consistency, hotbar
   readability, map legibility, objective presentation, party strip,
   tournament/captain presentation, level-up/catch/reward celebrations —
   without changing gameplay behaviour or building new UI architecture.

## The audit — pushed first, as instructed

`ralph/reports/UI_BOARD_AUDIT_2026-08-30.md` (commit `05d094ab`). Full
evidence table in that file; short version:

| # | Item | Verdict |
|---|---|---|
| 1 | Hotbar: consumables + tools only | **UNMET — fixed this session** |
| 2 | Workbench: build orbs, craft tools, repair | Mostly met; repair-gating is a documented SD18 decision, not a gap |
| 3 | Blacksmith: orb recipes | **MET** (Tam, D39) |
| 4 | Tools: axes chop, rocks give extra materials | **MET** (RG9 chop-then-gather) |
| 5 | Gatherables: downed trees/rock piles, not icons | **MET** (RG9/RG10) |
| 6 | Map: M / dedicated ROG button | **MET** (keyboard M + `JOY_BUTTON_BACK`/View) |
| 7 | Minimap: orientation + player arrow | **MET** (derived rotation math, rotating triangle) |
| 8 | Movement: stairs/slopes | Not mine — overlaps T2-STRANDING, reported only |
| 9 | TMs better than base moves | Not mine, genuinely unmet — overlaps T3-TYPECHART |
| 10 | More ranged moves, unique VFX | Not mine — overlaps T3-TYPECHART, reported only |

**The board lists ten items, not eleven** — the routing brief's count was off
by one; corrected in the audit file.

**Six of the ten items the board asks for were already fully met by work that
landed after the board's 2026-08-15 date**, none of it re-touched here per
`CLAUDE.md`'s "evidence-backed already-fixed is valid, don't rewrite a
working system to produce a diff." Only item 1 was a genuine gap.

## What I implemented, done and verified

### 1. Hotbar: consumables + tools only (`autoload/game_state.gd`)

`HOTBAR_KINDS_REFUSED := ["resource", "currency"]` was a refusal LIST, so
every other item kind — `gear` (orbs, saddle), `key`, `material`
(saddle_frame), `tm`, `elixir`, `armor` — passed `hotbar_can_hold()` and
could be assigned from the backpack grid, but `_use_hotbar_slot()` has no
use-path for any of them: pressing one always answered "is not something you
can use here." Replaced with `HOTBAR_KINDS_ALLOWED := ["tool", "consumable",
"food"]` — an allow-list of the exact three kinds the bar's own press-handler
knows how to spend.

**Verified**: `tests/smoke_playground.gd` (extended with an `orb_basic`
refusal assertion, mirroring the existing `wood` one) — `smoke: OK`.
`tests/smoke_menu.gd` — its own "place onto a quick slot" check bound
`orb_basic`, which the fix now correctly refuses; moved that half of the
check to `potion_small` (a `consumable`) so it keeps testing the BIND
mechanic rather than asserting the now-forbidden behaviour — `menu smoke
test passed`.

Commit `a35538ce`.

### Two capture-tool bugs fixed while verifying the §20 backlog (`tools/_capture_ui_survey.gd`)

Found while checking `ralph/BACKLOG.md`'s `VIS-UI-remainder` entries against
current `main` before touching anything (see "what I did NOT change" below
for why most of that list turned out to be stale). Neither is a game defect.

- **VIS-UI-r1**: the party-strip closeup (`08-party-strip.png`) set
  `position` directly via `_place_widget()`, but `party_strip.gd::_ready()`
  had already captured `_rest_position` at mount, and `set_pinned(true)`'s
  `_reveal()` snaps `position` straight back to that stale value — so the
  frame came back a blank near-black rectangle. Now calls
  `set_rest_position()` with the same origin. **Visually confirmed**: the
  regenerated frame shows the full five-row roster, portraits, HP bars, the
  KO badge and the REST tag, all legible.
- **VIS-UI-r2**: the stamina-arc closeup (`09-stamina-arc.png`) shared the
  party-strip's near-black `Color(0.08, 0.09, 0.10)` backdrop. The arc's own
  unfilled track is a dark neutral at 40% alpha, authored to sit over a lit
  3D world — against that backdrop it nearly vanishes, reading as "a
  bracket, not a meter" (the exact wording a blind critic used on it).
  `_widget_stage()` now takes an optional backdrop colour; the stamina-arc
  shot passes a mid-grey. **Visually confirmed**: the regenerated frame
  shows both the dark unfilled track and the teal filled arc clearly against
  the mid-grey.
- **Bonus, found while confirming the r1 fix**: the party-strip crop was
  ALSO undersized — `_place_widget(strip, Vector2(250.0, 540.0), 60.0)` used
  a hardcoded size that predates the widget's own recorded growth
  (`party_strip.gd`'s header: "WIDTH grows 250 -> 420"; current
  `ROW_SIZE.x` is 336, `TOTAL_HEIGHT` 308), and the stale 250px crop cut the
  HP bars off the right edge of every captured frame. Now reads
  `PARTY_STRIP.ROW_SIZE.x` / `PARTY_STRIP.TOTAL_HEIGHT` live off the widget
  so a future resize can't go stale here again.

Commit `a35538ce` (bundled with the hotbar fix); the crop fix is a
follow-up, see commit list below.

## What I investigated and deliberately did NOT change — this is the part worth reading

`ralph/BACKLOG.md`'s `VIS-UI-remainder` section (2026-08-23) lists
`VIS-UI-r1` through `r7` as "in this lane's files, ready to fix." I checked
each against current `main` before touching anything, because `CLAUDE.md` is
explicit that a newer owner reproduction reopens a defect but stale prose
does not, and this repo has a documented history of confidently-wrong
backlog entries. Findings:

- **r1, r2**: real, but capture-tool-only (fixed above).
- **r3** (combat HUD left column self-collision): **already fixed**, with a
  dedicated passing test — `tests/smoke_combat_hud_left_column.gd` passes
  cleanly (`the roster and the active-creature plate cannot land on each
  other`). `combat_hud.gd::_party_strip_position()` measures the panel's
  real `get_global_rect()`, not its stale authored offset. No action taken.
- **r4** (dialogue panel doesn't hide the world HUD): **I got this one
  wrong, then caught it myself and reverted.** I initially wired
  `dialogue_panel.gd` to `INPUT_OWNER.set_world_hud_visible()` the same way
  the five station panels are, matching the backlog's literal prescription.
  Running `tests/smoke_dialogue_clears_the_world_hud.gd` against my change
  immediately failed it (`only 0 visible HUD widgets during the
  conversation`) — that test's own header explains why: the REPORTED
  symptom ("RB — Call out Terrapup" ghosting under the dialogue box) was
  already fixed by a different, more surgical route
  (`_yield_bottom_to_build_menu()` and `_exploration_legend_should_show()`
  already stand the bottom dock down while `dialogue_panel.gd`'s
  `INPUT_OWNER.GROUP` membership makes `INPUT_OWNER.current(tree) != null`),
  and the test deliberately leaves open whether blanket-hiding the WHOLE HUD
  during a conversation is even wanted — a conversation is not a menu, and
  the minimap/party strip/vitals are useful information a player might want
  mid-conversation. My "fix" would have hidden all of that on every single
  dialogue line in the game. **Reverted.** Confirmed the test passes clean
  on unmodified `dialogue_panel.gd`. No net change to this file.
- **r5** (text truncation, four frames), **r6** (trainer prints through
  station panels), **r7** (four button-glyph languages): no dedicated test
  exists for any of these to check quickly. `craft_panel.gd` already sets
  `OVERRUN_TRIM_ELLIPSIS` on its cost label (r5's craft-panel half looks
  already addressed); the pause-menu footer is already dynamic and
  controller-first (`game_menu.gd::legend()`, reads live off the InputMap) —
  but its own comment admits the gamepad half stays literal TEXT rather than
  a real icon glyph because "input_glyph.gd's icons need a RichTextLabel and
  this is a plain Label," which is r7's residual finding and NOT something I
  attempted: converting every plain-Label footer across the menu system to
  RichTextLabel to carry real icon glyphs is exactly the "major new UI
  architecture" §20 says not to build inside this pass, not a bounded
  polish fix. Left as a named remainder rather than guessed at from static
  reading after r3/r4 both turned out to already be handled — I was not
  going to trust a third read of the same 2026-08-23 list without rendering
  something.

**The pattern across r1–r4 is the finding worth repeating to the next
lane**: half of a four-day-old "ready to fix" list was already fixed, and
the one item I attempted from stale prose without rendering it first was
wrong. Verify by running the dedicated test or capturing a frame before
touching anything this list names.

## Evidence captured

The full `tools/_capture_ui_survey.gd` sweep (23 frames, `--rendering-driver
opengl3` under `xvfb-run`) was **still in flight when this handover was
written** — the world phase alone runs ~90 boot/settle frames against the
full Meadows scene (143k+ props, 315k grass tufts) before its first shoot,
and this environment's software GL is slower than the tool's own measured
baseline. Two frames were already spot-checked directly against the r1/r2
fixes above (both confirmed working — see those items). If the survey
finished after this was written, the frames are under `shots/ui/` (gitignored
at repo root) and should be copied to `ralph/reports/T1-UI/shots/` per the
brief before anyone else relies on them; if it did not finish, re-run:

    xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
      --rendering-driver opengl3 --resolution 1920x1080 \
      --script tools/_capture_ui_survey.gd

**The party-strip crop fix below was made AFTER the in-flight survey run
started**, so that run's own `08-party-strip.png` does not reflect it — only
a fresh run will. Re-run before trusting that specific frame.

## Done-and-verified vs done-but-unverified vs still-open

**Done and verified:**
- Hotbar allow-list (item 1) — passing smoke tests, both directly exercising
  the new refusal.
- Capture-tool r1/r2 fixes — visually confirmed against regenerated frames.

**Made but not yet re-rendered:**
- Capture-tool party-strip crop fix (`PARTY_STRIP.ROW_SIZE.x`/`TOTAL_HEIGHT`
  instead of the stale hardcoded `250x540`) — reasoned from the widget's own
  constants (confirmed via source: `ROW_SIZE.x` is 336, crop was 250+120
  margin = 370 wide, so the fix is real by arithmetic), but made after the
  in-flight survey run had already started with the old code, so it has not
  been confirmed by a fresh render the way r1/r2 were. Re-run the survey and
  check `08-party-strip.png`'s right edge before treating this as verified.

**Done but only reasoned from source, not rendered:** none shipped in this
category — everything above was either test-verified or frame-verified,
deliberately, after the r4 lesson.

**Still open, reported not fixed:**
- Item 2's repair-gating (owner board says "Workbench: ... repair"; current
  repair is free from the backpack anywhere, not gated to standing at the
  bench) — a named SD18 decision against building station-gating machinery,
  not an oversight. Flagged for the coordinator to decide whether it's worth
  reopening as a design question.
- Items 8/9/10 (movement/stairs, TM multipliers, ranged move VFX) — audited,
  not touched, per file ownership.
- VIS-UI-r5/r6/r7 — real but unverified without rendering; r7 specifically
  needs an owner/architecture call before anyone touches it.
- §20's celebration-moment ask (level-up/catch/reward): checked briefly.
  Catch success already has a dedicated capture-reticle animation
  (`play_success`/`play_break`) plus a coloured outcome line. Level-up is
  currently plain text only (`combat_hud.gd::_set_xp_line()`, "X reached Lv
  N") with no visual flourish — a real, bounded candidate for a future pass,
  not attempted here given the size of the audit/hotbar/capture-tool work
  already in this session and the priority of verifying rather than
  guessing.

## What I learned that is NOT visible in the diff

- The owner board's own checklist glyphs are a bullet style, not a
  completion marker — every item uses the same green check regardless of
  whether the board's own DIALOGUE panel numbers its lines 1-5 with plain
  numerals. Worth stating explicitly since a literal read could mislead a
  future audit into treating the board as "these are already done."
- The `VIS-UI-remainder` backlog list is significantly stale (see r3/r4
  above) despite being dated the same day as its own "not converged"
  framing — it was written faithfully at the time, but nobody reconciled it
  against the round-3 fixes that landed in the SAME sweep. `ralph/DONE.md`
  has zero entries closing any `VIS-UI-r*` item, so there is no record
  anywhere that r3 (at least) is fixed except the passing test itself.
  Worth a bookkeeping pass by whoever owns that list next.
- Running the actual capture survey (`tools/_capture_ui_survey.gd`) takes
  materially longer than the tool's own header estimates (~15-23 min) under
  this environment's software GL — budget accordingly.

## Disagreements / things worth the coordinator's attention

- The routing brief said the board's checklist has eleven items; it has ten.
  Corrected in the audit file, noted here so nobody re-derives eleven from
  the brief instead of the board.
- Most of the board's checklist was already met before this lane started.
  Per the brief's own framing, that is a genuinely good outcome, reported
  plainly rather than papered over with invented work.

## Full file footprint

- `ralph/reports/UI_BOARD_AUDIT_2026-08-30.md` (new)
- `autoload/game_state.gd` (hotbar allow-list)
- `tests/smoke_playground.gd` (new hotbar-refusal assertion)
- `tests/smoke_menu.gd` (quick-slot bind check moved off `orb_basic`)
- `tools/_capture_ui_survey.gd` (r1/r2 capture bugs + party-strip crop fix)
- `ralph/reports/handover-T1-UI-2026-08-30.md` (this file)
- `ralph/reports/T1-UI/shots/` — created, empty at handover time; the capture
  survey (see "Evidence captured" above) had not finished, so nothing was
  copied in yet. `shots/` at repo root is gitignored per the brief's own
  warning that a prior lane lost evidence there — copy frames INTO the
  reports path, not just leave them at repo root, before relying on them.

## What I would do next

1. Re-run the full UI capture survey with the crop fix in and hand the
   frames to a Fable judge for the blind read this file cannot substitute
   for.
2. If the owner confirms level-up deserves a real celebration (not just
   text), it is a small, bounded, well-isolated change in
   `combat_hud.gd::_set_xp_line()` — a tween-driven scale/colour pop on the
   level-up branch only, guarded by the existing
   `tests/test_level_up_announcement.gd`.
3. r7 (button-glyph consistency) needs an architecture decision, not a
   guess: either accept literal-text footers as the permanent second style
   for plain-Label surfaces, or budget converting them to RichTextLabel.
   Not mine to decide unilaterally inside a "bounded polish, no new
   architecture" pass.
4. Item 2's repair-gating is a real design question (should repair require
   standing at a placed workbench?) that SD18 already answered "no, and
   here's why" — reopening it should be an explicit owner call, not a UI
   lane's unilateral reversal of a recorded decision.
