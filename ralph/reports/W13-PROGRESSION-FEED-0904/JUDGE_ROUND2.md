# Visual judge — W13 progression feed, round 2 (interface only)

## Verdict

The interface is competently composed and it is not ugly. Plates are consistently
rounded and stroked, the menu's tab row is genuinely good, the notification plate's
three-tier structure is the right idea, and nothing is broken in a way that stops the
screen being read at desk distance on a monitor. But almost none of it is built for a
7-inch handheld. Outside the notification headline and a handful of menu titles, the
entire UI runs at 11–14 px type (8–10 px cap height), which is roughly half the size a
console or handheld layout normally uses, and a large number of the small elements sit
between 1.3:1 and 2.8:1 contrast. On top of that there are two hard defects that are not
matters of taste: the health and food numeric plates are drawn on top of the bars they
label, leaving a stranded sliver of fill poking out past each plate; and the persistent
HUD breaches the 5% safe area on all four edges. Separately, the two "different"
notification banners are 98.9% identical pixels, and several bars and badges in the
roster carry no information at all while occupying the most visually dominant positions.

(Only the interface is judged here. The world-art bar questions in the standing rubric —
palette against the key art, and the Palworld comparison — are not answerable from these
frames, since the backdrop is scaffolding and no terrain, foliage or lighting is present.)

---

## a. Legibility at 1280x800, handheld, arm's length

**Short answer: no.** One headline passes comfortably; nearly everything else is
undersized, and about a dozen elements are also under-contrasted.

**Too small.** At 1280x800 on a ~7-inch panel the usual floor for body text is about
2.5–3% of screen height, i.e. a 20–24 px font with a ~15 px cap. Measured glyph heights
in these frames:

| Element | Frame | Glyph height | Verdict |
|---|---|---|---|
| Banner headline "Pip · bond 1 / 5" | banner_level_up / _milestone | 22 px (cap ~15) | passes |
| "Biscuit  Lv 7" panel title, "Ground" | team_screen | 22 px | passes |
| Roster strip creature names | all HUD frames | 16–17 px | marginal |
| Banner line 2 "landmarks discovered together…" | banners | 15 px | marginal |
| Bottom hint bar "Map / Satchel / Build…" | all HUD frames | 18 px | marginal |
| Banner line 3 "Kite · bond 1 / 5 · Biscuit reached Lv 7 · Moss · bond 2 / 5" | banners | **11 px** | too small |
| Strip "Lv 7", "bond 1/5" | all HUD frames | **12 px** | too small |
| Roster card "Lv 7", "Bond 2/5" | team_screen | **10 px** | too small |
| "EXP 0 / 374", "374 EXP to Lv 8" | team_screen | **10–11 px** | too small |
| "Pebble Toss" / "Power x0.8  Energy +26" | team_screen | **13 px** | too small |
| "QUICK" / "CHARGED" | team_screen | **11–12 px** | too small |
| "MAIN STORY" eyebrow | all HUD frames | **9 px** | too small |
| "NEXT: 4/10 MEALS FED TOGETHER" | team_screen | **9 px** | too small |
| Footer "A / Enter  Select…" | team_screen | **12 px** | too small |
| Hotbar key-cap glyphs (1–5) | all HUD frames | **~7 px glyph in a 14 px badge** | too small |

**Too low contrast.** Measured foreground peak against the background it sits on:

- **"Day 1 · 00:00"** (banner_level_up, top centre): **1.53:1**. This is the worst text in
  the set. It has no plate — only a hard 1 px dark drop shadow, and the shadow is
  *higher* contrast against the glyph (5.29:1) than the glyph is against what is behind
  it, so the text reads as a smudge. Because it has no plate, its legibility is entirely
  at the mercy of whatever the world puts behind it.
- **"bond 1/5" on the four unselected roster-strip rows**: **2.30:1** (dimmed amber
  134,114,60 on 38,65,80). The selected row's "bond 2/5" is 5.38:1, so the dimming step
  for unselected rows is far too aggressive — it takes a real value below readable.
  "Lv 7" on those same rows is **3.72:1**.
- **"Bond 2/5" on the roster cards** (team_screen): **2.75:1**.
- **Empty Appraisal pips** (team_screen, the two hollow dots after the three cyan ones):
  **1.67:1**. You cannot count the denominator, so "Appraisal ●●●○○" reads as
  "Appraisal ●●●" — the rating loses its scale.
- **Hollow milestone rail nodes** (team_screen, bottom of detail column): **1.81:1**.
- **The EXP track** (team_screen): **1.28:1**. At 0/374 there is no fill, so a near-black
  3 px rule sits on dark navy and reads as a stray divider rather than an empty bar.
- **"Grandpa's Village"**: 4.86:1 with no plate. Acceptable here, but like the clock it
  is unprotected and will fail over bright terrain.
- **"QUICK" / "CHARGED" / "Appraisal" / "EXP 0/374"**: 3.85–4.45:1. Passable on a monitor,
  thin at 10–12 px on a handheld.

**Crowded.** The banner's third line packs four separate events into 378 px of 11 px type
separated only by middots (banner_milestone). Line 2 and line 3 are 7 px apart
vertically, so they read as one block rather than two ranks.

**Legible and fine:** the menu tab row, "Belt 5 / 5 — Full. A sixth creature means letting
one go.", "HP 163 / 163", "ATK 29  DEF 26", the bottom hint bar wording, and the banner
headline and its second line. Those are the parts to size the rest of the UI *up* toward.

---

## b. Do the notification plates read as important without being obnoxious?

Importance: yes, arguably too much. Hierarchy inside them: only partly.

**The plate itself.** The amber-stroked dark plate is the loudest thing on the screen and
it is centred — it definitely reads as important. The problem is that it does not read as
*a notification*, because the persistent MAIN STORY objective plate on the right uses the
**identical amber border on the identical dark fill**. A player has no chrome cue that
tells a momentary celebration apart from a permanent objective card. Give the transient
plate its own treatment (or let the objective card drop to a neutral stroke).

**Internal hierarchy — three ranks, and the middle one wins.** Measured contrast:
headline amber 8.75:1, line 2 bold white **14.41:1**, line 3 grey 8.68:1. The supporting
line is the highest-contrast text in the plate. The headline only wins on size (22 px vs
15 px), so at a glance the eye lands on "landmarks discovered together · +1% attack and
defence (now +1%)" before it lands on "Pip · bond 1 / 5". Drop line 2 to a mid grey and
that inverts correctly.

**Line 3 is unlabelled history presented as detail.** "Kite · bond 1 / 5 · Biscuit
reached Lv 7 · Moss · bond 2 / 5" is a recent-events list, but nothing marks it as such,
so it reads as more facts about Pip. In banner_level_up it is the *only* place the actual
level-up appears ("Biscuit reached Lv 7"), in the smallest and dimmest rank, while the
headline is about Pip's bond and the toast beside the roster says "+314 XP". Three
different events are on screen simultaneously and nothing tells the player which one just
fired.

**The two banner types are the same picture.** A pixel diff of banner_level_up.png against
banner_milestone.png shows **1.07% of pixels differ**, confined to three bands: the
banner's third line (y 240–253), and the toast area (y 294–317 and y 330–353). The plate's
border, headline and second line are **byte-identical**. Whatever distinguishes a
level-up from a milestone, it is not visible in the plate.

**Amber is doing six unrelated jobs.** Across these frames the same amber marks: the
notification border, the MAIN STORY border, bond values in the strip, the FOOD bar and
its label, the "Tired · Fed · Restless" status line, and the "Day 1" menu-header counter.
"Amber means pay attention" therefore means nothing. On the plus side, the reserved
oxblood danger colour does not appear anywhere, which is correct.

---

## c. Clipping, overlap, and the 5% safe area

At 1280x800 the 5% safe rectangle is **x 64–1216, y 40–760**. Every persistent HUD cluster
is outside it.

| Element (banner_level_up, identical in the other HUD frames) | Measured bounds | Breach |
|---|---|---|
| Health plate | x 12–203, y 661–691 | left edge 52 px outside |
| FOOD plate | x 12–203, y 704–758 | left edge 52 px outside |
| Roster strip (TEAM header + 5 rows) | x 37–316 | left edge 27 px outside |
| MAIN STORY plate | x 1011–1242 | right edge 26 px outside |
| Hotbar plate | x 872–1241 | right edge 25 px outside |
| Bottom hint bar | x 616–1241 | right edge 25 px outside |
| Minimap frame | x 1125–1236, y 43–154 | right edge 20 px outside |

The team_screen menu panel (x 63–1215, y 36–762) sits essentially on the safe line, which
is fine for a full-screen dialog, and its content is comfortably inside.

**Two pairs of elements occupying the same pixels — both in the bottom-left HUD, all three
HUD frames:**

1. **The health bar fill and the "100 / 100" readout plate.** On scanline y=676 the green
   fill runs x 21–199; the opaque near-black readout plate runs x 106–191 and is drawn on
   top of it. Because the plate stops at 191 and the fill's rounded cap ends at 199, an
   **8 px green sliver survives to the right of the plate**, which reads as a rendering
   error, not a design.
2. **The food bar fill and the "100%" readout plate.** Amber fill x 40–199, plate x 137–180,
   leaving the **same stranded amber sliver at x 181–199**. Additionally the amber word
   "FOOD" begins at x 40 with zero gap to the amber fill's left cap, in the same hue, so
   the label visually merges into the bar.

The two rows are also inconsistent with each other: health is 31 px tall with an icon,
food is 54 px tall with a word.

**Two more near-collisions worth fixing before they become collisions:**

- team_screen: **"QUICK" ends at x 1195; the vertical scrollbar track occupies x 1197–1201.**
  Two pixels of clearance. "CHARGED" ends at the same x. Any longer tag or a slightly wider
  font clips.
- team_screen, milestone rail: node 3's amber progress arc is **drawn ~2 px right of centre
  of its own grey ring**, so it looks like a clipped or mis-blitted sprite rather than a
  half-filled node.

**Not clipped, contrary to expectation:** no creature name is truncated anywhere, and the
roster cards keep a healthy 22 px gap between the status line and the "Bond n/5" label.

---

## d. The roster / party panel: do the small labels and bars mean anything?

This is where the most information is lost.

**The bars carry no data.** In the roster strip (all three HUD frames) the green pill is
**exactly 28 px wide and fully filled on all five rows** — Biscuit at bond 2/5 and Moss at
bond 1/5 get identical bars. Because the pill is glued immediately to the right of the
"bond n/5" text, it reads as the bond meter and therefore actively contradicts the number
beside it. In team_screen the roster cards repeat the mistake at larger scale: the bar next
to "Lv N" is **exactly 99 px and 100% filled on all five cards** (Lv 7, 7, 8, 9, 10), while
the detail panel for that same selected creature reads **"EXP 0 / 374"**. Whatever these
bars are, the frame gives the player no way to know, and one reading of them is flatly
contradicted elsewhere on the same screen.

**"Tired · Fed · Restless" is lit identically on every card.** Three status words, all in
the same amber, all at full brightness, on all five creatures — and two of them are
mutually contradictory (tired and restless). Read as a state display it is nonsense; read
as a legend it is unlabelled and is the second-loudest line on each card. Either dim the
inactive states hard or drop to a single active state per creature.

**The white interlocking-rings glyph is the loudest thing on each card and says nothing.**
Roughly 30 px, pure white, the highest-contrast mark in the roster column, identical on all
five cards. It out-ranks the creature's own name visually while carrying zero
differentiating information. If it is a bond icon it should be next to "Bond 2/5" and it
should change with the value.

**Distinguishable from each other?** Only "Lv N" and "Bond n/5" are; and "Bond n/5" is at
2.75:1 so it is the hardest thing on the card to read. The bar, the rings glyph and the
status line are all indistinguishable across creatures.

**Not truncated, no run-together.** Biscuit, Moss, Ridge, Pip, Kite all fit; "Biscuit ·
Active" fits; gaps between "Lv N", "bond n/5" and the bar in the strip are 6–8 px. That
part is clean. Note only that the middot is doing three different jobs on one card
("Biscuit · Active" as apposition, "Tired · Fed · Restless" as a list).

**One cross-frame inconsistency:** in strip_bond_tick.png the "+bond · fed" toast sits at
y 370–383, level with **Ridge** (bond 1/5), but the creature that ticked to 2/5 is **Moss**.
In banner_milestone.png the identical toast sits at y 335–348, correctly level with Moss.
In the still, the toast is pointing at the wrong creature.

---

## e. The menu detail screen: is the progress list scannable?

There is no list of progress lines — there is a **five-node rail 145 px wide with 7 px
nodes**, and one caption. It is not scannable, for four separate reasons.

1. **The two completed nodes are different colours.** Node 1 is cyan (54,214,203); node 2
   is a mint green. Same state, two colours, so it reads as two different kinds of done.
2. **The current node reads as a bug.** Node 3 is a grey ring with an amber crescent
   offset 2 px to its right. It does not read as "in progress"; it reads as a misaligned
   sprite.
3. **The remaining nodes are invisible.** Hollow rings at 1.81:1 against the panel. You
   cannot count how many remain, so you cannot tell where in the track you are.
4. **The caption is in the wrong typeface and misreads.** "NEXT: 4/10 MEALS FED TOGETHER"
   is set in a squared LCD/techno face that appears nowhere else in the UI (everything else
   is a humanist sans). In that face the X has no diagonals, so **"NEXT" renders as
   "NEHT"** — I read it wrong before I zoomed in. It is also 9 px tall, and the word gap
   between "FED" and "TOGETHER" measures **under 3 px** while the gap after "NEXT:" is
   9 px, so the last two words run together. The same face is used for the hotbar key-caps,
   where **"4" reads as "N" and "3" reads as "J"** at 7 px.

So: *which is finished* is guessable only from the two solid dots, *which is current* is
undermined by a misalignment that looks like an artifact, and *how many remain* is not
readable at all.

Two more problems in that column, while I am in it:

- **The type badge and both move icons are the same white triangle.** "Ground", "Pebble
  Toss" and "Stone Rush" all get the identical mountain glyph, stacked down the panel.
  Three identical icons in one column teach the player nothing and make the two moves
  indistinguishable at a glance.
- **The column's rhythm is wrong.** There is a ~90 px dead gap between "Appraisal" and
  "EXP 0/374", while the bottom is crowded — "Power x1.0  Cost 100" sits about 20 px above
  the milestone rail. Redistribute that space downward.
- The portrait sits on a **pure black (#000), square-cornered, unstroked rectangle** (x 380–660,
  y 200–681) that matches nothing else in the UI — every other plate is rounded and stroked
  on a dark navy. It punches a hole in the panel. The creature also touches both the left
  and right edges of that rectangle (body x 380–659 in a plate x 380–660), i.e. zero padding.
- The screen title "Creatures" is directly above the active tab "Creatures". One of them
  can go.

---

## f. Would these overlays obscure something during action, or pull the eye off centre?

**Yes, the banner would, and badly.** The notification plate is opaque, 600 x 93 px, at
x 340–939 / y 173–266 — dead centre horizontally, occupying the band 22–33% down the
screen. In a third-person game that is exactly where a creature's head and upper body sit
at engagement distance. It has no transparency and the most saturated stroke on screen, so
it both occludes and out-competes whatever is behind it.

It is worse than one plate, because the top-centre column is a **stack of four**: the clock
(y 43–58), the location title (y 87–110), the interaction hint plate (y 126–158) and the
banner (y 173–266). That is a continuous 220 px of centred UI down the most valuable part
of the frame. A milestone firing mid-fight would land right on the target. Move the
progression plate off centre — the toast pattern already used beside the roster is the
right idea and is correctly peripheral.

The other overlays are fine on this count. The roster strip, health/food, minimap and
hint bar are all edge-anchored. The "+314 XP" / "+bond · fed" toasts are small and sit
beside the roster where they belong.

**Two controller-first issues visible in these frames**, given the ROG Ally target:

- The HUD's bottom hint bar offers **keyboard keys only** — M, I, B, R, C — while the
  team_screen footer offers proper dual prompts ("A / Enter Select", "B / Esc Close",
  "LB / Q Prev tab", "RB / Tab Next tab"). On a controller-first handheld the HUD is the
  one that has to be right.
- Within a single frame the key presentation is inconsistent: the bottom bar puts keys in
  key-cap badges, while the interaction hint sets the key as plain body text
  ("**E** when you are next to him").

---

## Ranked, addressable

1. **Body text is roughly half handheld size.** Everything except the banner headline and
   the menu titles runs at 10–14 px. Raise the floor to a ~20 px font / ~15 px cap and
   re-lay-out from there. Worst offenders: banner line 3 (11 px), roster card "Lv N" /
   "Bond n/5" (10 px), "EXP 0/374" and "374 EXP to Lv 8" (10–11 px), the milestone caption
   (9 px), the "MAIN STORY" eyebrow (9 px), the hotbar key glyphs (7 px).
2. **The health and food numeric plates are drawn on top of their own bars** (all HUD
   frames), stranding an 8 px green sliver at x 192–199 and an amber sliver at x 181–199
   past the right edge of each plate. Reads as a bug. Put the readout beside the bar, or
   inset it and clip the fill behind it.
3. **The persistent HUD breaches the 5% safe area on all four edges**: health/food at x 12
   (52 px in), roster strip at x 37 (27 px in), MAIN STORY at x 1242, hotbar and hint bar
   at x 1241, minimap at x 1236 (20–26 px out).
4. **Bars that carry no information and contradict the numbers next to them.** The 28 px
   strip pill is identical on all five rows despite differing bond values; the 99 px card
   bar is 100% filled on all five creatures while the same creature's detail panel reads
   EXP 0/374. Either make them read the value or delete them.
5. **The level-up and milestone banners are visually identical** — 1.07% of pixels differ,
   none of them in the plate's border, headline or second line. Give the two event classes
   distinguishable chrome.
6. **The banner sits opaquely in the top-centre action band** (x 340–939, y 173–266), on top
   of a four-deep stack of centred UI running y 43–266. Move progression feedback off the
   centre column.
7. **"Tired · Fed · Restless" is lit identically on all five creatures** in team_screen, and
   is self-contradictory. Show one active state, or dim the inactive ones hard.
8. **Low-contrast micro-elements.** "Day 1 · 00:00" at 1.53:1 with no plate; the EXP track
   at 1.28:1; empty Appraisal pips at 1.67:1; hollow rail nodes at 1.81:1; unselected-row
   "bond 1/5" at 2.30:1; card "Bond 2/5" at 2.75:1. The unselected-row dimming step in
   particular is too aggressive.
9. **The LCD/techno typeface.** "NEXT" renders as "NEHT", "4" as "N" and "3" as "J". It
   also appears exactly once in the whole UI. Replace it with the UI sans.
10. **"FED" and "TOGETHER" run together** — under 3 px of word space against 9 px elsewhere
    in the same string.
11. **Amber is overloaded across six unrelated meanings**, and the transient banner shares
    its border treatment exactly with the persistent MAIN STORY card.
12. **Milestone rail node 3's amber arc is offset ~2 px from its ring**, so "current" reads
    as a rendering artifact; and the two completed nodes are two different colours.
13. **The same white triangle icon serves the type badge and both moves** in team_screen.
14. **HUD prompts are keyboard-only (M/I/B/R/C)** on a controller-first target, and the
    interaction hint sets its key as plain text while the bottom bar uses key-caps.
15. **The portrait's pure-black, square-cornered, unstroked rectangle** matches nothing else
    in the UI and gives the creature zero padding at the left and right edges.
16. **"QUICK" / "CHARGED" clear the scrollbar by 2 px** (x 1195 vs x 1197).
17. **The white interlocking-rings glyph outranks the creature's name** on every roster card
    while carrying no per-creature information.
18. **Layout tidy-ups in team_screen:** ~90 px dead gap between "Appraisal" and "EXP 0/374"
    against a crowded lower column; the "Creatures" title duplicates the active
    "Creatures" tab beneath it; the health and food HUD rows differ in height (31 vs 54 px)
    and in whether they use an icon or a word.
