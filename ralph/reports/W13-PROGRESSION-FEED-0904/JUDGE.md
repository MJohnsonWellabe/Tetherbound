# Visual judge — W13 progression feed, round 1

Frames judged: `_sheet_round1.png`, `banner_level_up.png`, `banner_milestone.png`,
`strip_bond_tick.png`, `team_screen.png`. All 1280x800. Background, terrain and lighting
ignored as instructed; this is an interface review only.

## Verdict

The information architecture is broadly right — a centre event plate with a three-tier
hierarchy, a left team strip, a right objective plate, a modal roster with a preview —
and one line in the roster screen ("Belt 5 / 5   Full. A sixth creature means letting one
go.") is the best-written piece of UI in the set. But the execution has three defects
severe enough that a player would read them as bugs, not style. First, the notification
plate is composited over a live interaction prompt: "He is waiting at the table
downstairs. E when you are next to him." is visible through the plate and physically
collides with the headline "Pip · bond 1 / 5" in all three HUD frames. Second, the team
strip rows overflow — the active row renders the name as "Biscui" with no ellipsis, prints
"Lv 7bond 2/5" with no space between the level and the bond label, and squeezes the bar
into 28px that then runs into the row's rounded border. Third, the per-creature feed tags
("+bond · discovered"), which are the entire point of this feature, are drawn in a dull
olive-amber with no plate behind them at roughly 1.3:1 contrast against the backdrop —
they are already marginal on a flat blue and will vanish outright over sunlit meadow
grass. Separately, every anchored HUD element sits 27–53px inside the 5% overscan margin,
and the value chips on the HP and FOOD bars cover the fill they are supposed to annotate.

## a. Legibility at 1280x800, handheld, arm's length

Fine as-is: the banner headline (20px cap height, ~10.6:1), the banner's second line, the
MAIN STORY body text, the roster tab row, "Belt 5 / 5" and the roster creature names
(13px). Those are all comfortably readable.

Not fine:

- **`+bond · discovered` / `+bond · fed` feed tags** (`banner_level_up`, `banner_milestone`,
  `strip_bond_tick`). The most saturated pixel in the glyphs measures (142,122,65) against
  the (59,112,148) backdrop — **~1.3:1**. There is no plate, only a 1px dark shadow. This
  is the single worst legibility item in the set, and it is the new feature's payload.
  By contrast the teal `+314 XP` on the same column measures ~3:1 and is readable, so the
  feed is internally inconsistent about whether its own tags are visible.
- **`bond 1 / 5` in the team strip rows** — dim amber on the dark row plate, **2.73:1** at
  ~9px cap height. Below the 3:1 floor even for large text, and this is small text.
- **Hotbar keycap digits** (`1`–`5`) and the inline key glyphs in the action bar
  (`M`,`I`,`B`,`R`,`C`) are ~5–6px inside an 11px white cap. At native size `3` reads as
  `2`, `4` reads as a Greek mu, `5` reads as `S`. These are the glyphs a player must read
  to act.
- **`4/10 MEALS FED TOGETHER`** (`team_screen`) is set in a squared LCD-style face used
  nowhere else in the UI, 8px tall, with a vertical-bar slash — it reads as "4110" at a
  glance.
- **`MAIN STORY` eyebrow** is letterspaced grey caps at ~3px effective stroke; it is
  decoration, not a readable label.
- **Crowding**, not size: `Lv 7bond 2/5` (Biscuit, `banner_level_up`; Moss,
  `banner_milestone`) and `Lv 8bond 1/5` (Ridge, `strip_bond_tick`) have zero space between
  the level value and the following word, and `2/5` then touches the bar with no gap.
- In `strip_bond_tick` the entire team strip is at ~25% opacity: the Ridge row that just
  changed measures **2.25:1** and its `+bond · fed` tag **1.92:1**, while the centre banner
  is at 100%. If that is a fade tail it is fine; if that is the resting state of the strip
  it is unreadable.

## b. Do the plates read as important without being obnoxious?

The three-tier hierarchy inside the banner is correct in principle and legible in practice:
amber headline (`Pip · bond 1 / 5`) > white bold consequence line (`landmarks discovered
together · +1% attack and defence (now +1%)`) > small grey history line (`Kite · bond 1 / 5
· Biscuit reached Lv 7`). A player can tell at a glance what just happened and what it
bought them. Keep that structure.

What undercuts it:

- **The plate is not opaque enough to own its own space.** The interaction prompt behind it
  bleeds through the top band and runs straight through the headline. Two strings occupy
  the same pixels in all three HUD frames.
- **The banner and the MAIN STORY tracker use the identical amber 2px border and identical
  plate fill.** A transient "this just happened" event and a permanent objective card are
  given the same urgency treatment, so the banner has nothing left that marks it as an
  event. One of the two needs a different weight.
- **Amber has no reserved meaning left.** It is doing the banner border, the quest tracker
  border, the FOOD fill, the bond label, the feed tags, the roster status chips and the
  current-milestone dot — seven jobs. Nothing is signalled by it any more. (The oxblood
  danger reservation from `docs/reference/README.md` is not violated; amber's overuse is a
  separate problem.)
- **The headline names the wrong event in the level-up frame.** In `banner_level_up` the
  headline is `Pip · bond 1 / 5` and the level-up (`Biscuit reached Lv 7`) is demoted to the
  smallest, greyest line. Whatever the plate is titled after, a level-up should not be the
  thing hidden in tier three.
- **Redundancy.** Four rows of the team strip carry the identical tag `+bond · discovered`.
  Four copies of the same sentence is noise; one team-level line would say the same thing.
- Size is reasonable: 599x105 for the banner is assertive without being a takeover.

## c. Clipping, overlap, overscan

The 5% safe area at 1280x800 is x ∈ [64, 1215], y ∈ [40, 759]. Measured element bounds:

| Element | Bounds | Verdict |
|---|---|---|
| HP plate | x 11..204, y 660..692 | **53px inside the left margin** |
| FOOD plate | x 11..204, y 703..759 | **53px inside left; bottom sits exactly on 759** |
| Team strip | x 37..299, y 261..466 | **27px inside the left margin** |
| Minimap | x 1100..1242, y 37..179 | **27px past right, 3px past top** |
| Quest tracker | x 1010..1242 | **27px past right** |
| Hotbar / action bar | both end x 1242 | **27px past right** |
| Roster modal (`team_screen`) | L/R exactly 64, T/B 37 | on the line horizontally, **3px past vertically** |

So the safe area is not respected anywhere: the whole HUD is anchored to roughly a 1%
margin, not 5%. On a display that actually clips, the FOOD bar and the top of the minimap
go first.

Actual clipping and overlap, independent of overscan:

- **`Biscui`** — the active creature's name is truncated mid-word in `banner_level_up` and
  `banner_milestone`, with no ellipsis. The name is the row's primary identifier.
- **Bond bar clipped by its own row border.** On the Biscuit row the bar's dark remainder
  runs into the rounded right edge of the plate; there is no trailing padding.
- **HP and FOOD value chips break their containers.** The opaque black `100 / 100` and
  `100%` chips sit *on top of* the right half of the bar fill and overhang the plate's
  rounded right edge, with a sliver of green/amber fill poking out beyond them. At any
  partial value the chip covers exactly the part of the bar that shows how full it is.
  The FOOD plate additionally has ~100px of empty gutter to the left of the word `FOOD`,
  and its bar sits at a different x and height than the HP bar above, so the two do not
  read as a column.
- **`QUICK` and `CHARGED` tags** (`team_screen`) are clipped at the right by the scroll
  region — the `K` of `QUICK` is partly under the scrollbar.
- **The creature preview is cut on two sides.** The model's left flank and its right haunch
  are sliced flat by the render viewport's edges, producing a hard vertical white edge
  against pure black at x≈660. The subject touches the box on three sides with no margin.
- **The minimap's black backing square** extends past the rounded teal frame drawn inside
  it, so four black corners stick out; the white bearing marker at the bottom straddles the
  frame line rather than sitting inside or outside it.

## d. The roster/party panel — do the small labels and bars read?

They do not, and the failures are separable:

- **The unlabelled green bar next to `Lv 7`** cannot be identified. It sits immediately
  after the text `bond 2/5`, so adjacency says "this is the bond meter" — but Moss at
  `bond 1/5` shows a *full* bar while Biscuit at `bond 2/5` shows a *partial* one, so it
  demonstrably is not bond. Whichever quantity it is (HP is the likely read), its placement
  makes it lie.
- **The bars are not comparable across rows in the HUD strip.** They are pushed rightward by
  variable-width text, so they start at different x. In the roster modal the bars are
  properly aligned in a column (x 190..288 on four rows) — that is the correct behaviour,
  and the HUD strip should copy it.
- **28px is not a bar.** In the HUD strip the bond/HP bar is 28px wide and ~5px tall. A
  five-step value in 28px is 5.6px per step; it cannot be read as a quantity, only as
  "green".
- **`Tired · Fed · Restless`** (`team_screen`) is the worst offender. All three words are
  rendered in the same amber at the same weight, on all five creatures, with no on/off
  distinction — and `Tired` and `Restless` are semantically contradictory, so a player
  reads it as three simultaneous active conditions. As displayed the status row carries
  literally zero per-creature information: it is byte-identical on every row.
- **The white double-ring glyph** at the right of each roster row is the highest-contrast
  element in the row, is identical on all five rows, and is unlabelled. The eye is pulled to
  the one thing that says nothing.
- **`Bond 2/5`** is the lowest-contrast text in the row (5.75:1, 10px grey) despite being
  the panel's headline concept.
- **Portraits do not identify creatures.** Biscuit, Ridge and Kite share one pixel-identical
  badger thumbnail; Moss and Pip share one pixel-identical rabbit thumbnail. The only
  per-creature differentiator is a brown vs olive band on the frame, whose meaning is not
  stated anywhere. Worse, Biscuit's badger thumbnail does not depict the armoured stone
  quadruped shown in the preview beside it — portrait and preview disagree about what the
  selected creature looks like.
- In the HUD strip the icons are ~24px versions of the same two images and are
  indistinguishable at that size.
- Positive: the teal selection outline on the active row is unambiguous in both the HUD strip
  and the modal, and `· Active` as a name suffix is a clean way to mark the piloted creature.

## e. The menu/detail screen — is the progress list scannable?

There is no scannable progress list on this screen. What exists:

- **The five-dot track captioned `4/10 MEALS FED TOGETHER`.** The track has five nodes but
  the caption counts to ten, so the picture and the number disagree about the scale. The
  three states are a filled cyan dot, a filled *green* dot, an amber partial ring, and two
  grey hollow rings — that is two different colours both apparently meaning "done", and the
  whole distinction lives in ~7px of colour. At arm's length you cannot tell finished from
  current from future; you can only tell "some dots are brighter on the left". The caption's
  typeface is unique to this one element.
- **The moves list** (`Pebble Toss`, `Stone Rush`) uses the *same* white triangle icon for
  both moves — and the same glyph again for the `Ground` type at the top of the panel. Type
  and move share an icon, and the two moves are visually identical. The only differentiator,
  the `QUICK` / `CHARGED` tag, is the low-contrast right-edge item that gets clipped.
- **The EXP bar is invisible.** At `EXP 0 / 374` the track is a near-black hairline on a dark
  navy panel; you cannot see its extent, and there is no fill colour anywhere to establish
  what a filled one would look like.
- A scrollbar runs down the right side from y≈200 to y≈680, so there is more content below
  the fold that this frame never shows — whatever the "progress lines" are meant to be, they
  are not visible on first open.

So: no, a player cannot tell at a glance which entries are finished and which one is in
progress. Fixing that needs a real list — one row per milestone, a filled/current/pending
state that differs in *shape and value*, not only hue, and the current row given weight.

## f. Would these overlays hurt during action?

Yes, in two specific ways.

- **The banner occupies the centreline.** It spans x 340..939, y 110..215 — dead centre
  horizontally, directly above the reticle, and it is the highest-contrast object on screen
  (amber border, 10.6:1 headline) — brighter than the health bar. During a real-time fight
  that is a 599px-wide bar drawn across the creature you are piloting toward. The Palworld
  reference (`docs/reference/palworld-05-base-building.jpg`) puts its equivalent tutorial
  and event stack in the top-right corner and keeps the centre clear; that is the fix, and
  it also removes the collision in (b).
- **It already obscures the thing a player needs.** The interaction prompt "He is waiting at
  the table downstairs. E when you are next to him." is exactly the kind of prompt that is
  time-sensitive, and the banner is drawn over it. The banner does not merely risk covering
  something important — in these frames it is covering something important.

Lesser: the hotbar block (872..1242 x 506..629) is a 370x123 empty box in the lower right
carrying nothing but five key numbers. Empty, it is a large dark rectangle sitting where
peripheral vision watches for flanking; it should collapse or dim when unfilled. The team
strip is well-placed at upper-left and does not intrude.

## Ranked, addressable

1. **The interaction prompt renders through and collides with the notification banner**
   (`banner_level_up`, `banner_milestone`, `strip_bond_tick`). Two strings on the same
   pixels, on the headline. Highest-visibility bug in the set.
2. **Feed tags are invisible.** `+bond · discovered` / `+bond · fed` at ~1.3:1 against the
   backdrop, unplated. Over meadow grass they disappear. The feature's payload needs a
   plate or a much higher-value colour (the teal `+314 XP` already works — match it).
3. **Team strip rows overflow.** `Biscui` truncated with no ellipsis; `Lv 7bond 2/5` and
   `Lv 8bond 1/5` with no separating space; the bar squeezed to 28px and clipped by the row
   border. Fix the row's column widths so the name is never truncated and the bar has a
   fixed left edge across rows (the roster modal already does this correctly).
4. **HP and FOOD value chips cover the bar fill and overhang their plates.** At any partial
   value the number hides the reading. Also fix the FOOD plate's 100px left gutter and align
   the two bars into a column.
5. **The unlabelled green bar in the strip reads as the bond meter and is not.** Either
   label it, move it away from `bond x/5`, or make bond the thing it shows.
6. **`Tired · Fed · Restless` is identical on all five roster rows** and shows no on/off
   state, while containing two contradictory words. As drawn it conveys nothing.
7. **Safe area is ~1%, not 5%.** Every anchored element is 27–53px inside the margin; the
   minimap crosses the top edge and the FOOD plate sits exactly on the bottom limit.
8. **The banner sits on the screen centreline** and outranks the health bar in contrast.
   Move it off the reticle, or drop its weight below the HUD's.
9. **The milestone dot track contradicts its own caption** (5 nodes vs `4/10`) and encodes
   done/current/pending in ~7px of hue, with two different "done" colours.
10. **Banner and quest tracker share one amber border treatment**, so a transient event and
    a permanent objective look equally urgent. Give the event plate its own weight.
11. **Creature preview is clipped on two sides and framed rear-on**, on a pure-black box
    that out-contrasts everything in the panel, with the subject touching three edges.
12. **Roster portraits are duplicated across creatures and disagree with the preview model** —
    three creatures share one badger thumbnail, two share one rabbit, and Biscuit's
    thumbnail is not the creature rendered next to it.
13. **`QUICK` / `CHARGED` clipped by the scrollbar**; both moves and the type share one white
    triangle icon; the `EXP 0 / 374` track is invisible against the panel.
14. **Keycap glyphs are ~6px** and misread (`3`→`2`, `4`→`mu`, `5`→`S`); the `4/10 MEALS FED
    TOGETHER` caption uses a one-off LCD face whose slash reads as a `1`.
15. **Amber carries seven unrelated meanings.** Reserve it for one.
