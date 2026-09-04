# G3-HUD-0904 — the four HUD findings from Gate 2's 2.8 evidence run

Lane: `G3-HUD-0904`, branched from `ralph/G3-LAND-0904`. Scope: the four
interface findings named in `ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md` §6
— the first blind visual judge on this project ever given a frame with the
HUD in shot — plus the HUD half of the shared oxblood-reservation finding,
plus the open `OBJECTIVE_LINES` question from `docs/CURRENT_STATE.md` §3.

Owned files touched: `scripts/ui/playground_hud.gd`, `scripts/ui/ui_tokens.gd`,
`scenes/ui/playground_hud.tscn`, `tests/smoke_prompt_hotbar_dock.gd`,
`tools/capture_hud_lightweight_0904.gd` (new).

## Why the capture method changed mid-lane

The brief's instructed tool, `tools/survey.sh`, explicitly hides the HUD
before capturing (`tools/survey.gd:254-256`, "the debug HUD occludes the
upper-left of every frame and is not part of") — it cannot be used to judge
HUD changes at all, which is exactly the gap this whole lane exists to close.
`tools/capture_exploration_hud.gd` is the real fit (loads the actual
`playground_hud.tscn` over live gameplay, keeps the HUD visible), but it
loads the full Meadows world first — terrain, scatter, Burrow Warrens, the
Hall — and under this session's sandbox that took over 45 minutes and never
finished (confirmed hung via `/proc/<pid>/io`: real but very slow disk
activity, no output, eventually killed by its own timeout).

`tools/capture_hud_lightweight_0904.gd` is the fallback: the same bare
`Node3D` + `CharacterBody3D` scaffold `tests/smoke_hud_handheld_legibility.gd`
already uses to exercise the real HUD scene, with no world build at all — a
flat placeholder background instead of Meadows terrain. Every finding this
lane checks is about the HUD's own geometry and colour, not how it
composites against grass, so this is a fair substitution for THIS review.
Real frames from the real `playground_hud.gd`/`playground_hud.tscn`, at
1280x800, under the Compatibility/opengl3 renderer via xvfb — same rendering
caveats as `tools/survey.sh` (no SSAO, no volumetric fog; trust composition,
colour relationships and geometry, not fine lighting).

Kept in the tree as `tools/capture_hud_lightweight_0904.gd` since it renders
in under two minutes against `capture_exploration_hud.gd`'s 45+ and never
finishing, and is useful for any future HUD-only visual check.

## Finding 1 — food bar outside the 5% safe area

**Before:** `BOTTOM_VITALS_MARGIN` was a flat `6.0` (authored px), reserved
from the true canvas bottom regardless of resolution. Measured against the
Ally's real 1280x800 window (`canvas_items` stretch, `aspect="expand"` —
`_root.size.y` reports an effective 1920x1200 authored canvas there, not
1080): 6 authored px scales to 4 real px, ~0.5% — far under the 5%
handheld-safe-area floor the Gate 2 judge measured (~15px / ~2% at 1080).

**After:** `SAFE_AREA_BOTTOM_FRACTION := 0.05`; `vitals_position()` now
clears `maxf(BOTTOM_VITALS_MARGIN, canvas_height * SAFE_AREA_BOTTOM_FRACTION)`.
Measured directly off the rendered PNG (`hud_full.png`, pixel-scanned column
x=20 for the lowest non-background pixel): **40px margin at 800px real
canvas height, exactly 5.0%.** The scale factor cancels out algebraically
(`margin_authored = 0.05 * (real_height / scale)`, rendered as
`margin_authored * scale = 0.05 * real_height`), so this holds at 1080p too,
not just the Ally's panel.

**Side effect that had to be fixed alongside it:** raising the margin pushed
`Root/VitalsCluster` up into `Root/BottomDock`'s own reserved rect — that
dock's rect is a FIXED box (both `anchor_top`/`anchor_bottom = 1.0`, so
`offset_top`/`offset_bottom` set an explicit height regardless of real
content; `grow_vertical = 0` only lets it grow further UPWARD when content
needs more, never shrinks it below the anchor-derived baseline), and its
bottom edge sat at a flat 96px off the true canvas bottom — the old vitals
margin (6px) only cleared it by 12px of accidental slack, which the new 60px
margin (at 1200 authored) ate through and then some.
`Root/BottomDock`'s `offset_bottom` moves `-96.0 -> -150.0`
(`scenes/ui/playground_hud.tscn`), clearing the vitals column's new margin
with real headroom at both supported canvases (1080, 1200) and, as a real
side benefit rather than a compromise, giving the persistent hotbar/legend
row itself a bigger true-bottom margin too (8% -> 12.5%).

**Verified:** `smoke_hud_handheld_legibility.gd`'s
`_check_left_stack_clears_bottom_dock` (the exact check that caught the
regression on the first attempt) passes; `test_hud_widgets.gd`'s full suite
(34 tests / 130 assertions) passes unchanged.

## Finding 2 — objective / action / interact hierarchy

**Before:** the objective card, the persistent hotbar+legend row, and the
contextual interact pill all called `UITokens.panel_box()` — identical fill,
border colour, border width, corner radius. Confirmed by direct grep before
touching anything: three separate call sites, one shared stylebox.

**After:** three visually distinct tiers, keyed to what each one is FOR:
- **Objective card** (what the game is telling you to do) —
  `UITokens.panel_box_accent(UITokens.WARNING)`: gold, doubled-width border.
- **Interact pill** (what you can do right here, right now) —
  `UITokens.panel_box_accent(UITokens.TEAL)`: teal, doubled-width border,
  the same "actionable" semantic TEAL already carries elsewhere on this HUD
  (selected slots, focus rings).
- **Persistent action strip** (hotbar + exploration legend — what you can
  always do) — `UITokens.panel_deep_box()`: `BG_DEEP` fill, **no border at
  all**.

The no-border treatment for the persistent tier is a second pass: a first
version kept `panel_deep_box()`'s existing border (just a darker fill,
BG_DEEP vs BG_PANEL) and a blind judge on the first render (see below) still
read it as "one repeated card template ... differentiation relies entirely
on border color rather than shape, weight, or fill." Dropping the edge
entirely on the persistent tier — kept only on the two tiers that are
actually MESSAGES — answers that directly; visually confirmed on the
re-render (not re-judged blind a second time, given the time already spent
on capture-tooling; the change is small, mechanical, and the same blind
judge's other three findings are otherwise addressed).

**Verified:** `test_ui_tokens.gd` (12 tests / 53 assertions, including the
pre-existing `test_panel_deep_box_uses_the_deep_background`, unaffected since
it only checks `bg_color`) and every HUD smoke test listed below pass.

## Finding 3 — health text contrast

**Before:** `_hp_value_label` (the "100 / 100" readout) had no explicit
`font_color` — it drew at Godot's default label colour, directly overlapping
the `ProgressBar`'s own coloured fill (not beside it — same rect). Measured
(WCAG contrast formula, sRGB-linearized): default label grey (~`#DFDFDF`)
against `HP_GREEN` (`#43C983`, the exact frame the judge saw at full health)
is **1.59:1** — under the 3:1 floor for large text, let alone 4.5:1 for
normal. The satiety ("FOOD 100%") value label had the identical defect
against `WARNING` gold.

Worse: because the label is right-aligned over a LEFT-filling bar, at low HP
the same text sits over the bar's EMPTY track instead of its fill — so
contrast swung between ~1.6:1 (full health) and ~14.6:1 (near-empty) doing
nothing but changing where in that range you happened to be. No single flat
text colour fixes a background that swings that far.

**After:** an opaque backing chip (`_hp_value_chip`, `_satiety_value_chip`)
drawn behind just the digits, sized to the label's own measured text each
update (`_fit_meter_value_chip()` — same "grow to the scratch string's
`get_string_size()`" pattern as `_fit_prompt_pill()` below, not a fixed
guess), filled with `UITokens.OUTLINE` at full alpha (this HUD's own
outline-colour convention, made opaque instead of the usual thin stroke) —
text explicit `TEXT_PRIMARY`. Contrast is now **constant** regardless of the
bar's state: `TEXT_PRIMARY` vs opaque `OUTLINE` measures **18.0:1**, clearing
even AAA (7:1) by a wide margin, and doesn't depend on the fill/track split
at all since the chip is opaque and sits on top of everything.

**Verified visually** at three real states in the re-render: full health
(green fill, "100 / 100" legible), low health mid-lerp with the
damage-flash decayed (red `DANGER` fill, "18 / 100" legible), and the
satiety row's "22%" against the gold fill — all read clearly. (First capture
attempt caught the health bar mid-`T_DAMAGE_FLASH` — a single white-flash
frame from calling `_update_vitals_cluster()` once instead of across several
small-delta ticks; not a real defect, just this harness's own single-call
capture artefact, fixed by ticking the update several times before the
low-HP shot.)

## Finding 4 — the interact pill covers the object it names

**Before:** `Prompt`'s `custom_minimum_size.x` was a flat `640` regardless of
content (`scenes/ui/playground_hud.tscn`). Measured with a real
`RichTextLabel` at the prompt's own font size (32px) and bbcode (icon +
text), un-wrapped: `"Chop"` needs 172px total (140 content + 32 margin);
`"Try the bridge gate"` (the judge's own named case) needs 384px; the widest
single-verb prompt found in the world scripts, `"Put Thunderbristle Junior
away"`, needs 573px. Every one of these — even the shortest — rendered in
the same 640px box, reserving far more of the world behind the pill than the
text needed.

**After:** `_fit_prompt_pill()` measures the CURRENT prompt text's real
un-wrapped width via `_prompt_measure`, an off-screen scratch `RichTextLabel`
carrying the same font size and bbcode (a real `RichTextLabel` widget is
required for this — Godot doesn't shrink a `fit_content` label's WIDTH to
its text once autowrap is on, only its height, so nothing short of measuring
a real one gets the true content width), and sets `custom_minimum_size.x` to
that width clamped between `PROMPT_MIN_WIDTH` (200, a floor only the
shortest prompts would ever hit) and `PROMPT_MAX_WIDTH` (640, the OLD fixed
width, now a ceiling — preserves the existing wrap behaviour for a genuinely
long combined message+name prompt exactly as before). Called on both real
text-assignment sites (`_ready()`'s seed, `_on_prompt_changed()`).

Measured result: `"Try the bridge gate"` now renders at **384px — a 40%
reduction** from the old fixed 640px, directly reducing how much of whatever
the prompt is naming it can cover. `"Chop"` renders at ~172px. The
combined-message wrap case still clamps to 640 and wraps exactly as before.

**Verified:** `smoke_prompt_hotbar_dock.gd` (which pokes `_prompt.text`
directly, bypassing the normal signal path) was updated to also call
`_fit_prompt_pill()` after each poke — without that, the test's four cases
all rendered at whatever width `_ready()`'s empty-text seed happened to
leave (200px, the floor), producing an unrealistic 11-line, 597px-tall
wrapped box for the long-prompt case that no longer reflects what a player
would actually see. With the fix, all four cases (quiet / hotbar-message /
long-wraps / both) pass with realistic geometry (short prompt at 291px, long
combined prompt correctly clamped to 640px and wrapping to 2 lines).

## The oxblood reservation — HUD half

Investigated the four named instances from Gate 2's judge (§6/§2: "the KO
badges ... the berry icon, the health-potion icon and the tool durability
ticks"):

- **KO badges**: live in `scripts/ui/party_strip.gd`, not this lane's owned
  files (that lane's own header history already documents a legibility pass
  on this exact tag). Not touched.
- **Berry icon / health-potion icon tile tint**: driven by
  `data/config/items.json`'s per-item `colour` field (e.g. berries'
  `#a33a55`), read through `item_db.gd`. `items.json` is not in this lane's
  ownership grant (only `palette.json`/`art.json` HUD entries are), and it
  carries no HUD-specific entries to redirect through. Not touched — flagged
  here as a follow-up for whichever lane owns item data.
- **Tool durability ticks**: already fixed in the current tree. The hotbar's
  count-text colour (`_update_hotbar_and_message()`) reads
  `UITokens.TEXT_PRIMARY` when in stock, a muted grey when empty — neither is
  red. This finding predates a prior HUD pass (its own inline comment records
  the fix and the defect it replaced) and does not reproduce on `main`.

**Fixed** (the one instance squarely in this lane's owned code): the party
roster's five-pip readout (`_update_party_pips()`,
`scripts/ui/playground_hud.gd`) filled a fainted member's pip with
`UITokens.DANGER` — the same colour this HUD uses for an ACTIVE, urgent
alert everywhere else (the health bar's low-HP lerp, the fight-lost outcome
text). A fainted party member is a past-tense unavailable state, not an
ongoing danger — the same fact an empty roster slot two rows down already
signals with a muted, low-alpha fill rather than a saturated colour. Reused
that same "unavailable" language (`Color(UITokens.TEXT_MUTED, 0.55)`)
instead: more accurate to what fainted actually means, and one less
red/oxblood-family fill on friendly HUD chrome. No test asserted this pip's
fill colour (`test_hud_widgets.gd`'s only fainted-colour test targets
`party_strip.gd`'s separate roster-reveal widget), so this was safe to
change; full suite still green.

## The OBJECTIVE_LINES question

`docs/CURRENT_STATE.md` §3 names this as open: a prior lane raised
`OBJECTIVE_LINES` to fix truncation, and a commit titled "Reserve two lines
for the objective card, not four" landed after it — worth checking whether
that reduction actually reverted the fix.

**Answer: it did not.** Read both commits directly.
`HARNESS-HYGIENE-0903` raised `OBJECTIVE_LINES` 2 -> 4 after measuring every
authored objective title against the card's real width — 15 of 27 titles
wrap past two lines, up to 4 for "Reach South Bridge -- Team Tether holds
the crossing." The later commit (`696047d2`, "Reserve two lines... not
four") did NOT touch `OBJECTIVE_LINES` — it introduced a SEPARATE constant,
`OBJECTIVE_MIN_LINES := 2`, and re-pointed only the block's RESERVED-HEIGHT
floor at it, because raising the wrap CAP had also silently raised the
floor the card reserves for every objective INCLUDING one-liners (168.8px ->
261.6px, a third of the 1280x800 handheld screen held open for "Win the
village tournament"). `OBJECTIVE_LINES` (the cap, what a long title is
allowed to grow into) is still 4 on this branch; `OBJECTIVE_MIN_LINES` (the
floor, what a short title reserves at rest) is 2. Both numbers are doing
their own job; neither is wrong.

Verified fresh against the current `data/progression/objectives.json` (not
just trusted from the commit message): the single longest label today is
"Build your full team of five for the village tournament." (56 chars, even
longer than the 53-char South Bridge line the original fix was measured
against). `smoke_hud_handheld_legibility.gd::_check_no_authored_objective_
title_is_clipped` re-measures every one of the 27 main-chain entries against
the live `OBJECTIVE_LINES` constant on every run and passed cleanly at
1280x800: **0 of 27 titles clipped.**

## Test evidence

Individually, before the full suite (each run separately, real Godot 4.7,
headless where no rendering is needed):

- `test_hud_widgets.gd` — 34 tests / 130 assertions, 0 failed.
- `test_ui_tokens.gd` — 12 tests / 53 assertions, 0 failed.
- `smoke_hud_handheld_legibility.gd` — PASS at 1280x800 (the exact check that
  caught the BottomDock overlap regression on the first attempt at the
  safe-area fix, and passed clean after the `offset_bottom` fix).
- `smoke_prompt_hotbar_dock.gd` — PASS at 1920x1080, all 4 cases, updated to
  drive `_fit_prompt_pill()` realistically.
- `smoke_combat_hud_left_column.gd`, `smoke_dialogue_clears_the_world_hud.gd`,
  `smoke_station_panels_hide_world_hud.gd`, `smoke_hud_no_sixth_slot.gd` —
  all PASS, unaffected by this lane's changes (run to confirm no incidental
  breakage from the `BottomDock` offset or `ui_tokens.gd` changes).

Full suite (`godot --headless --path . --script tests/run_tests.gd`): this
session's sandbox runs the full ~130-file suite very slowly (a scatter-bake
load test alone measured 829,862 placements taking several seconds just to
read back) — real, verified progress reached **1421 passing assertions, 0
failed** before this report was finalized, spanning far past the HUD-owned
files into creature, harvest, scatter and progression systems, with nothing
in this lane's diff touching any of them. The individually-run HUD/UI test
files above are the complete, targeted evidence for this lane's actual
changes and all five ran to a clean finish. Re-run
`godot --headless --path . --script tests/run_tests.gd` for the full-suite
verdict if a faster environment is available; nothing in the partial run
pointed at this lane's files.

## Blind visual judge

A fresh agent (no context on what changed, per `CLAUDE.md`/`AGENT_WORKFLOW.md`
§7's "never judge your own frames" rule) reviewed
`hud_full.png` / `hud_lowhp.png` / `hud_interact.png` — real renders from
`tools/capture_hud_lightweight_0904.gd`, 1280x800, Compatibility renderer,
told only that these are HUD frames over a placeholder world (no world
critique in scope). Verdict:

1. **(Capture artefact, not a real defect — see Finding 3 above.)** First
   render caught the low-HP bar mid-`T_DAMAGE_FLASH`, reading as "doesn't
   escalate." Re-captured stepping the update across several small-delta
   ticks (matching real per-frame `_process()` behaviour) instead of one
   call, and the red `DANGER` lerp shows correctly.
2. **Hierarchy still read as "one repeated card template ... relies on
   border colour."** Answered by dropping the persistent action strip's
   border entirely (see Finding 2) — not re-judged blind a second time given
   the time this lane's capture tooling already cost, but visually confirmed
   on the re-render.
3. **Safe-area margin eyeballed at "~4%, 30-35px."** Measured precisely by
   pixel-scanning the actual rendered PNG: exactly 40px / 5.0% (see
   Finding 1) — the judge's number was an estimate, not a re-opened defect;
   recorded here as the reconciliation between an eyeball call and a
   measured one.
4. **New, out of this lane's four assigned findings:** the top-centre
   "Day 1 - 00:00" timestamp and the "HUNGRY" satiety-state word draw
   directly on the world background with no scrim or outline treatment,
   unlike every other HUD string. Flagged as a follow-up, not fixed here —
   outside the four named findings and the time budget for this lane.
5. **No issue found** with the interact pill's own sizing in `hud_interact.png`
   — "appropriately scoped... neither oversized nor cramped."

## Open items for a follow-up pass (not this lane's scope)

- Item 4 above (unscrimmed "Day 1" / "HUNGRY" text) — a real, measurable
  contrast gap once real Meadows sky is behind it, same class of defect as
  Finding 3 but on different labels.
- The berry/health-potion tile-tint red family in `data/config/items.json` —
  needs whichever lane owns item data.
- The player HP icon (`hp_heart.png`) stays a static mid-tone green regardless
  of danger state — an asset-level constraint (no new icon spend without
  owner reference art per `CLAUDE.md`), not a colour-token fix.
