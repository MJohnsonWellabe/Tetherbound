> **This is a second, independent blind round**, run by lane W24-LANDING during the
> consolidated landing pass, at a moment when W13's own `JUDGE.md` had not yet been pushed
> and its report cited a verdict file that did not exist on the branch. Both rounds are kept:
> `JUDGE.md` is W13's own and judges five frames; this one judged the round-1 contact sheet
> alone. The two judges were given the same skill and reference material, no code, and no
> knowledge of each other.
>
> **They converge on the same three severe defects**, independently: the notification plate
> composited over the live "He is waiting at the table downstairs" interaction prompt; the
> party-strip rows overflowing ("Biscui", "Lv 7bond 2/5" with no space); and the feed tags
> that are the point of the feature drawn at roughly 1.3:1 against the backdrop, marginal on
> a flat scaffold and gone over sunlit grass. Two blind judges reaching the same three
> findings from different frame sets is the strongest signal in this batch's evidence.

# Blind judge verdict — W13's progression HUD sheet

Run by lane W24-LANDING, not by W13, during the consolidated landing pass for
`ralph/LAND-0904-3`. W13 committed `shots/_sheet_round1.png` and cited a verdict at this
path that was never committed; the owner directive of 2026-09-05 02:24 UTC asks the
landing lane to run one blind round for visual work no lane already has a verdict on, so
this is that round, on the frames W13 already shot. **No new render was made** — a
software-GL capture of the real world costs 20–50 minutes and the sheet existed.

**Method.** A code-blind sub-agent (opus) was given only three things: the visual-judge
skill at `.claude/skills/visual-judge/SKILL.md`, the art direction material in
`docs/reference/`, and the contact sheet. It was told the sheet shows four HUD frames at
1280×800 and was asked specific questions about legibility, occlusion, the party strip,
the menu and coherence. It was told nothing about what changed, which lane produced it,
or what anyone hoped it would say, and was explicitly instructed not to read any source,
any report, or anything else under `ralph/`. It split the sheet into its four frames and
sampled contrast numerically.

**The call: not shippable for a first playable.** Reproduced below as written.

## What it found good

One coherent system with a real identity: a near-black navy plate at about 90 % opacity, a
humanist sans, gold for progression, cyan for selection. Where the plate is used the type
is strong — the banner's gold headline measures **8.8:1** against its own plate, the white
body line **14.7:1**, the action-bar labels **14.8:1**. The active-row treatment (cyan
border, lighter fill, white left tick) "reads instantly" in both the party strip and the
menu. Nothing reads as imported from another game.

## The evidentiary hole, in its own words

> **There is no world in these frames.** 74.6 % of the HUD frame is a single flat colour
> (59,112,148). The minimap is empty. So the question I was asked — "is each banner legible
> against the world behind it" — cannot be answered from this sheet. Against flat blue,
> plated elements are legible and unplated ones already fail. Over the Meadows grass,
> sunlit terrain and high-chroma skies, the unplated elements will fail harder and the
> plated ones are untested.

This is the limitation W13's own report names (§4, "Visual"): the frames are over the
lightweight HUD scaffold, not real terrain, for the render-time reason. The judge reached
the same conclusion independently and says the survey must be re-shot over Meadows terrain
before anyone judges it again.

## Defects the judge attributes, ordered as it ordered them

Numbering is the judge's. **Bold** marks the ones that are W13's own elements; the rest are
pre-existing HUD and menu furniture visible in the same frames, which this lane did not
build and which no lane in this batch owns.

1. **The banner is drawn on top of a live interaction prompt and ghosts it.** "He is waiting
   at the table downstairs…" bleeds through the plate at **1.28:1**, a grey smear through the
   "Pip · bond 1/5" headline. Visible in a still, with no fight happening.
2. **The banner sits in the worst region for combat**: x 342–937, y 120–212 — the centre 46 %
   of width at 15–27 % of height. It does not cover the action bar or hotbar, so button
   prompts survive; "what it covers is the fight".
3. The health and food readouts cover their own bars: at 100/100 the health bar reads about
   55 % full and food about 40 %. Pre-existing.
4. **The per-creature bond indicator is unreadable** — gold "bond 1/5" at **1.85:1** against
   the row plate, "the least legible text in the frame".
5. **The green pill encodes nothing visible**: 26 px of green on all four rows at bond 1/5;
   four creatures at four levels and two bond values produce five visually identical bars,
   and the bar is unlabeled.
6. **The progression feed text is invisible**: "+bond · discovered" and "+bond · fed" are
   gold and unplated at **1.34:1**; "+314 XP" teal at 3.49:1. "Over grass they will not
   exist."
7. **Text clipping and collision in the party rows**: "Biscuit" truncated to "Biscui" with no
   ellipsis; "Lv 7bond 2/5" runs together with zero space on the selected row. The layout has
   no minimum-gap constraint, so any longer creature name breaks it.
8. Portraits do not identify creatures: five roster rows use two portrait images, and the 3D
   preview matches neither. Cut-outs on unremoved white backgrounds. Pre-existing / W04's
   area, not W13's.
9. "Tired · Fed · Restless" appears identically on all five rows, two of the three words
   contradicting each other. Pre-existing.
10. Menu text below usable contrast: the EXP track at **1.28:1**, footer hints at 2.21:1,
    "Bond 2/5" at 3.18:1, the clock at 1.65:1. Mixed — the EXP track and bond line are W13's
    surface, the footer and clock are not.
11. The scrollbar clips the move-category labels. Pre-existing.
12. Two typefaces: a squared/techno face used for a sentence of body copy ("4/10 MEALS FED
    TOGETHER") where everything else is humanist sans — "the one place on the sheet where a
    fragment genuinely looks imported". W13's surface.
13. The meals progress track is incoherent: five dots for a 4/10 value, three different dot
    treatments in one row. W13's surface.
14. The minimap frame does not match its own plate; the map is empty. Pre-existing.
15. No shared safe-area grid: four different margins and a 5 px plate overlap in one screen.
    Pre-existing.
16. The hotbar floats, anchored to nothing, slots empty. Pre-existing.
17. Icon hierarchy inverted in the detail pane; one icon reused for two moves. Pre-existing.
18. **Copy defects**: the banner's second line, "landmarks discovered together · +1 % attack
    and defence (now +1 %)", is "a subjectless fragment that restates its own number", and
    reads as string concatenation; its third line is a backlog queue competing with the
    headline.
19. Menu whitespace unbalanced; the creature preview is a near-black rectangle at 1.23:1 with
    the model unlit. Pre-existing.

## Direct answers to the questions put to it

- **Plate separation:** plate-to-background 3.0:1, text on it 8.8–14.7:1. "So yes, on this
  sheet. But the world is a flat mid-blue with no texture, so this proves the plate works
  against nothing at all."
- **Occlusion:** upper-centre band, 46 % of width. "It will not cover buttons. It will cover
  the fight, and it already covers a world prompt."
- **Party strip:** rows are distinguishable and the active row obvious; the progress
  indicators "exist but are not readable".
- **Menu:** the frame captured is the Creatures roster, not the task list — the Quests tab
  was not shot, so "which single row is next" **cannot be judged from this sheet**. This
  matters: W13's report claims the Team screen's one-NEXT behaviour as a bar, and the frames
  do not carry it. The runtime smoke does assert it.
- **Coherence:** one system, with two breaks — the squared face in body copy, and a selection
  cyan that "is not on the board palette".

## What the landing lane does with this

Nothing in the code. W13's tests and smokes are green and reproduce exactly (533 tests /
829,776 assertions across the batch, 0 failed; `smoke_progression_feedback` OK), so the
feature works; the judge's finding is that several of its readouts are **drawn too faint to
read**, which no test asserts. The three that are unambiguously W13's and unambiguously
severe — the feed labels at 1.34:1, the bond text at 1.85:1, and the banner ghosting a live
world prompt — are recorded here and in the landing report for the owner and for whoever
picks the HUD contrast pass up. Defects 3, 8, 9, 11, 14, 15, 16, 17 and 19 are pre-existing
furniture and are not this batch's to answer.

The judge's own closing instruction stands as the next action for the feature:
re-shoot this survey over real Meadows terrain, and fix 1–9 before it is judged again.
