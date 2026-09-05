# N13-NIGHT-RESUME-0905 — blind judge verdicts

Two rounds. Both used a fresh code-blind sub-agent (`opus`) given only the contact
sheet, `docs/reference/` and `.claude/skills/visual-judge/SKILL.md`, told nothing about
the game's clock, what had changed, or what I hoped it would say, and instructed not to
read source. Both sheets are **shuffled and lettered** rather than labelled by hour: an
hour label tells the judge which frame is supposed to be the night one, which is the
question being asked. Keys are in the `*.key.txt` files beside the sheets and were
withheld from the judge.

Excerpted below; the full verdicts are long and the quotes are verbatim.

---

## Round 1 — `_sheet_blind.png`

Seven hours of one day from one camera, on **unmodified `origin/main`**. Columns A–G
shuffled. Question: rank by brightness, then say which read as night.

**Ranking returned: B → E → G → A → D → F → C.** Through the key that is hours
**8 → 12 → 18 → 20 → 22 → 3 → 0**, which is *exactly* the order
`probe_daynight_contrast.gd` measured (114.5, 104.5, 90.5, 77.0, 54.7, 43.2, 29.5). An
independent read of the same frames agreeing with the instrument, having never seen it.

> **"C, and only C."** … "Deep navy sky, the meadow at 20, warm lit windows on two
> houses, the boar reduced to a dark silhouette. Its mean of 29.9 is essentially the
> reference NIGHT panel's own mean of 32.9 — it is at the right brightness for this
> game's night."

C is **hour 0**. One frame out of seven.

> "**D is the near-miss and I would not call it night.** … A player would say 'it's got
> dark,' not 'it is night.'"

D is **hour 22**.

**This is the finding that produced the second fix (§4b).** No number I had found it;
the instrument said hour 22 was at 0.478 of midday and I had read that as night. The
judge, looking at the picture, did not.

Legibility at hour 0: *"Yes, but a quarter of the walkable foreground is genuinely
blank."* — 27.9% of the ground band below luminance 10, against the key art night
panel's 6.8%, and *"the boulder at left — a brown, clearly-modelled form in A, D and G
— is a solid black blob in C and F."* **Not caused by this lane and not fixed by it**
(nothing this lane changed touches hour 0's pixels at all — see round 2), but recorded
here because it is a real, measured night-legibility gap against the reference.

---

## Round 2 — `_sheet_blind_round2.png`

Two rows, same seven shuffled columns. Row 1 = the fixed tree, row 2 = base.

**Note on the committed sheet:** `_sheet_blind_round2.png` in this directory has been
regenerated from the **landed** tree so it matches what is on the branch. The verdict
quoted below was given on the `night_end`@2 version of row 1 — that is the whole point
of quoting it, since it is what caught the hour-3 regression that the landed tree then
fixed. Row 1 of the committed sheet therefore shows hour 3 at mean 42.0, not the 38.9
the judge saw; every other column is within capture noise of what it judged. Which row is which was not stated. Question: which columns read as night
per row, what differs, which progression is better, and has anything regressed.

**What it confirmed.** Night, per row: *"Row 1: E only. Row 2: E only"* — E is hour 0,
and *"it is pixel-identical between them (mean abs diff 0.51/255, ground-band diff
0.05)."* The tuned night look is preserved exactly, which is what the brief required.
Hours 8, 12 and 18 likewise: *"for C, D, G and E every non-zero pixel sits on a cloud
edge or a grass-blade tip… That is wind and vegetation sway between two captures, not a
lighting change."* Hour 22 moved 54.7 → 44.9, and of the base's brighter version:
*"row 2's F is now too bright to be part of the evening."*

On legibility, asked explicitly whether either row was worse:

> "**No — and if anything row 1 is worse** [is the question asked of row 2]… Nothing in
> row 2 crushed." … "Every frame that changed got brighter and gained ground detail."

(Read in the correct direction: the fixed tree's dusk frames are the darker ones, and
neither row crushed. No new banding, contouring, seams or artifacts: *"a 20px-wide
clear-sky strip gives 422–773 unique RGB triples per column… no contour rings, no
posterised sky, no new seams."*)

**What it caught, and I had not measured.**

> "**Row 2, clearly**" is the better progression. … "Row 1 has a **6.0-unit gap between
> F and A** — two of its seven states are within 13% of each other in brightness *and*
> nearly the same colour. One of row 1's seven lighting states is doing no work."
>
> "**Row 2's A is the only frame in the whole sheet with an actual sunset in it.** Warm
> horizon band, mauve sky, warm-lit rock face on the mound. … Row 1's A is the same
> scene with the colour drained out."

A is **hour 3**. Holding night all the way to hour 2 had eaten the dawn ramp: hour 3
sits just outside the dark window and used to blend night→dawn at t=0.60, and the
plateau dropped it to t=0.33. **A blind viewer preferred the unfixed tree, and was
right to.** Fixed by pulling `night_end` from hour 2.0 to 1.0 (t back to 0.50, night
still held 50 real seconds across 23→1) — commit `e88a4f35`.

**Also named, present identically in both rows, and NOT fixed here:**

> "There is no moonlight colour anywhere. E's ground is RGB(17.3, 22.4, 6.6) against the
> key art night reference's RGB(17, 28, 31). The build's darkest state is the day
> palette multiplied down; the reference's is the day palette shifted cool." … "no moon,
> no stars, day-lit cloud tops."

That is a real night-art finding with numbers behind it, it is in `art.json`'s night
`sky` block and `ambient_colour`, and it belongs to whoever owns the next night-art
pass — **not to this lane**, whose brief says explicitly not to touch the night values
NIGHT-LEGIBILITY tuned, and whose subject is the clock. Routed in the report.

---

## Round 3 — the correction, re-measured

`night_end` 2.0 → 1.0 was re-rendered on the same tripod. Numbers in
`contrast-stats-after.csv`. No third judging round was spent: the change is a partial
revert **toward** the configuration round 2 preferred, on the single axis round 2
named, and the two properties round 2 confirmed (midnight untouched, hour 22 darker)
are unaffected by it — `night.hour = 23` is what moves hour 22, and hour 0 sits inside
the plateau either way. `COMMON.md`'s "stop after two rounds that move nothing" is the
ceiling this respects.
