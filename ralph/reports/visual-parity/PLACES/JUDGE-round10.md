# Visual Judge — Places, Round 10 (Team Tether Hall stone pass)

Blind review. Compared `round9/locations/*.png` (PREVIOUS) against
`round10/locations/*.png` (NEW), the sheet `_sheet_r9_vs_r10.png`, and
`docs/reference/tetherbound-meadows-keyart.png`,
`docs/reference/owner-board-2026-08-15-systems-and-castle.png`,
`site/img/page-board.jpg`, and the `palworld-0*.jpg` set.

## 1. Hall up close — 10-stronghold-gate-day, 10-stronghold-gate-face-day, 11-castle-landmark-hall-100m-day

**PASS** (the headline fix landed).

- `10-stronghold-gate-face-day.png`: this was the worst offender in round 9 —
  a solid black cutout with nothing legible. In round 10 it is a fully lit
  gate tunnel: individual stone blocks with visible mortar joints on both
  flanking pillars, moss/ivy climbing the left pillar and the archway,
  distinct lit-vs-shadow value split between the near pillars and the
  darker rear archway, a red door with a cross/blade emblem visible through
  the arch, red banners, wood-beam fencing. Estimated luminance: sunlit
  pillar faces ~110–140/255 (a real mid-tone, not blown white); the recessed
  archway wall ~40–70/255. That is a genuine value range, not a flat wash —
  it reads as occupied and weathered, not "too light/too clean."
- `10-stronghold-gate-day.png`: the twin gate towers now show block coursing
  and moss staining on the sunlit face, crenellations, arrow-slit shapes,
  and a visible banner/pennant, versus round 9's near-silhouette. Estimated
  sunlit tower-face luminance ~90–120/255.
- `11-castle-landmark-hall-100m-day.png`: the Hall now reads as a
  multi-tower structure with tonal variation (moss-green tints against
  brown-grey stone) rather than a black block; silhouette against the green
  hillside and sky is legible.
- Weighed against the keyart board's "Team Tether Stronghold (Meadows Hall)"
  panel: the new gate-face material quality (blocks, mortar, moss) is in
  the right family, but the Hall still lacks that panel's scale drama —
  no visible ruin/rubble staging, no industrial pipework/apparatus dressing
  around the base, fewer banners, less ivy mass. Read as "a fortress," not
  yet "the occupied ruin-stronghold" of the reference.

## 2. Night Hall — 10-stronghold-gate-night, 10-stronghold-gate-face-night

**PARTIAL.**

- `10-stronghold-gate-night.png`: castle reads as a near-total black
  silhouette against the navy sky and moon (tower faces ~5–15/255), with a
  couple of small warm lit-window/torch dots at the gatehouse base. That's
  acceptable for a *distant* silhouette shot, but it does not show any wall
  texture — there is no sconce/brazier light large enough to reveal stone
  at this range.
- `10-stronghold-gate-face-night.png`: clearly better than round 9, which
  was essentially solid black end to end. Round 10 shows faint ambient
  definition on the two flanking pillars, two pale purple/lavender
  glowing crescent shapes (banner emblems catching light) left and right,
  and a visible sliver of dusk sky through the far archway. But it is still
  dominated by near-black (most of the frame ~5–20/255, crescents ~90–120,
  archway sliver ~60–90) and no stone block/mortar detail is actually
  visible on the walls — there's no placed brazier or sconce light hitting
  the stone directly, only ambient fill. Verdict: no longer a "flat black
  cutout," but the stone still does not read at night the way it now does
  by day. Falls short of the "sconce light on the walls" bar in the brief.

## 3. Sentries at the gate

**FAIL / NOT VISIBLE.** No human guards appear at the gate posts in either
`10-stronghold-gate-face-day.png` or `10-stronghold-gate-face-night.png` —
only the player character (and, in the day frame, a red shipping crate
prop sitting mid-path, which reads as an odd stray object at a fortress
threshold). A Team Tether grunt guard *is* present, but well inside the
courtyard near the forge/anvil on the right (visible in
`10-stronghold-courtyard-day.png` and `10-stronghold-courtyard-night.png`,
unchanged from round 9) — not stationed at the gate posts these two frames
were checking.

## 4. Courtyard night + Warrens standing (control)

**PASS — confirmed unchanged, no regression.**

- `10-stronghold-courtyard-night.png`: same guard position, same banner
  glow, same lighting as round 9 on visual inspection (file hash differs
  trivially, no observable pixel difference).
- `04-warrens-standing-day.png`: visually identical to round 9.

## 5. Regression sweep (all NEW frames)

- `05-relay-camp-*`, `06-relay-*`, `08-ridge-camp-*`, `09-waystop-*`
  (18 frames) are **byte-identical** (md5 match) to round 9 — zero
  regression risk, untouched by this pass.
- `04-warrens-approach-day.png`, `04-warrens-den-day.png`,
  `10-stronghold-approach-day.png`, `10-stronghold-approach-night.png`,
  `10-stronghold-courtyard-day.png` differ in file hash from round 9 but
  are visually indistinguishable side-by-side (same composition, geometry,
  lighting) — no observable regression, likely benign re-render noise.
- One pre-existing defect, **not a new regression** (present identically in
  both rounds): a bright cyan/teal diagonal line cuts across the sky in
  `10-stronghold-gate-day`, `10-stronghold-gate-night`,
  `10-stronghold-approach-day/night`, and
  `11-castle-landmark-hall-200m/400m-day` — reads as a stray
  cable/tether-line asset clipping through empty sky. Unresolved, worth
  fixing in a future pass, but out of scope for this round's regression
  check.

## Hall score vs. reference fortress/landmark panels

Previous round: ~3.5/10 for Places overall (Hall was the dominant drag,
scored as a flat black cutout).

**Hall this round: ~6/10.** The close gate-face material work alone would
score ~7–7.5/10 against the keyart's stronghold panel — real stone, mortar,
moss, believable lit/shadow value split. The composite score is pulled down
by: the night gate-face still failing to show stone (drags toward 4–5), the
400m landmark silhouette being soft/small against a hazy horizon compared to
the strong local contrast in `palworld-04-plateau-landmark.jpg`'s distant
spire, and the exterior long shots lacking the reference's ruin/rubble/
pipework staging and banner density. Net: a real, visible jump from round 9,
not yet at the reference bar.

## Ranked remaining defects

1. **No sentries at the gate posts** — the brief's own check fails outright;
   a fortress gate with zero visible guards at the threshold reads as
   undefended, undercutting "occupied stronghold."
2. **Night gate-face still doesn't show stone** — round 9's black-cutout
   problem is fixed by day but persists at night; no brazier/sconce light
   source is actually placed to hit the walls, only faint ambient fill.
3. **Distance landmark contrast is soft** — the 400m Hall silhouette blends
   into a hazy horizon band rather than holding a strong dark shape the way
   the Palworld landmark reference does; worth a stronger sky/haze value
   separation or a slightly higher-contrast silhouette pass.
4. (Minor/no-fix-needed-this-round) Stray red crate prop mid-path at the
   gate-face-day threshold reads as clutter rather than dressing; and the
   unresolved cyan diagonal sky-line artifact should get a ticket even
   though it's not new this round.

## Recommendation

**MERGE** — the round's actual target (Hall stone/material readability by
day) is a decisive, verifiable improvement with zero collateral regression
across the other 21 unchanged/confirmed-unchanged frames; carry the sentry
gap and the night gate-face material pass into the next round rather than
holding this one back.
