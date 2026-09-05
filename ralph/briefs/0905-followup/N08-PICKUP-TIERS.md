# N08-PICKUP-TIERS

**Source:** W18-DENSITY-B4-B5-0904's report (explicitly routed to the coordinator, with a
specific ask), and W00-ICONS-0904's report (hue-collision findings).

## Why
A blind judge could not reliably tell pickup tiers apart in the world: it found the Great
(mint) unaided, found the Rare (cream) only by scanning, and could not find the Good at all
(a framing issue in W18's own capture, not this lane's problem). Its verdict: *"The only
difference between the two objects I can find is hue… far too subtle to tell apart in play."*
Separately, W00 found specific colour collisions between the candy/mushroom icon set and
other item tints that read as duplicates on the same UI.

## Owns
`scripts/world/band_pickups.gd` (the tier-instancing loader — tint, medallion, wing
application only, not placement/siting) and `data/items/items.json` (tint fields only).

## Do

**1. Differentiate pickup tiers by more than hue (W18's specific ask).** In
`band_pickups.gd`, where per-tier tint/medallion/wings are applied at instancing:
   - Give the Rare tier a hue clearly outside the cream/white flower palette it currently
     collides with in the world (the meadow's existing white cup flowers). Pick a hue that
     doesn't fall in the existing danger-red or Team-Tether-oxblood reserved range either.
   - Make tiers differ by SIZE or SHAPE in addition to tint — e.g. a scale step per tier, or
     an added silhouette element (the medallion/wings already exist for some tiers per the
     report; check whether they can be made more prominent or added to the tier currently
     missing one).
   - Do not touch the base mesh (`candy_pickup.glb`) or ask for new art — everything here is
     material/tint/scale/existing-attachment application at instancing time.

**2. Fix known hue collisions from `items.json` tints (W00).** Three specific collisions the
lane's judges measured: Rare Candy `#e0a92e` reads too close to Greater Orb's mean tint;
Stamina Shroom `#d98a2e` reads too close to Prime Orb's; Great Candy `#3f6fd0` reads too close
to Speed Shroom's `#4a7fd6`. Nudge whichever side makes more sense (prefer keeping the more
established/older item's tint and moving the newer one) so each pair is clearly distinguishable
in a HUD-sized icon, not just at full render size.

## Verify
- Render the same three-tier comparison stands W18's capture tool used (`Great` on the wind
  ridge crest, `Good` on the Highfield south paddock, `Rare` at the herd bull — see
  `tools/_capture_w18_pickups.gd` in `ralph/reports/W18-DENSITY-B4-B5-0904/REPORT.md`) before
  and after, at the same 7 m eye-height framing.
- Run a fresh code-blind judge on the after frames, asking specifically whether the three
  tiers are now distinguishable without prior knowledge of which is which — this is the exact
  question W18's judge failed. Don't tell it what changed.
- For the icon-tint fixes, a side-by-side render of each named colliding pair at actual HUD
  icon size, confirmed distinguishable by the same or a fresh judge.
- Confirm `test_band_pickups.gd` and any icon test (`test_item_icons.gd`) still pass —
  you're changing tint values, not structure.

## Acceptance
A fresh blind judge, given only the after frames and not told which tier is which, correctly
identifies all three tiers by sight. The three named icon-tint collisions are resolved at
actual UI size.
