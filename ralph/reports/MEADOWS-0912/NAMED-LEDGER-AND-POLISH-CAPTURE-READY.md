# Meadows named ledger and remaining POLISH source audit — 2026-09-12

## Exact count reconciliation

The canonical Meadows visual-review ledger contains **23 unique named places, not 24**.

- `data/config/map_landmarks.json` contains 9 landmark rows and 13 region rows: 22 raw rows.
- The Tether Relay and Old Mill Crossing each intentionally appear in both arrays, so those 22 rows represent 20 unique places.
- The Inn and Practice Meadow are authored named routes in `data/config/terrain_playground.json`, outside the map list.
- Stronghold Approach is the third external named destination, authored in the Meadows section of `data/config/debug_teleport_spots.json`.
- Therefore the review set is `20 mapped + 3 external = 23`.

This matches `ralph/reports/BROAD-VISUAL-0910/MEADOWS-NAMED-LOCATIONS-BLIND-REGRADE-0911.md`, which explicitly derives and enumerates all 23, and `docs/HANDOFF_FULL_GAME_2026-09-11.md`, whose Meadows row records a total of 23. The adjacent Water row, not Meadows, records 24 named destinations.

## The Inn

Latest accepted pixels are the R7 common-room set and the earlier focused exterior identity set. They leave The Inn at POLISH because the room is broad, pale, sparse, clean/evenly lit, and dominated by simple box-built architecture; the bed remains partly visible, while the exterior night pair carries a strong red cast.

The current production R10 candidate is already the supported next step and should not be stacked with another unseen treatment. It adds installed wood albedo/normal/roughness to the architectural timber and counter, irregular floor/runner wear, non-repeated table service, a lower open lodging screen, and a warm bar-first night hierarchy. The R10 capture also corrects the exterior and interior evidence bearings. Focused Inn contracts already pin texture use, collision-free wear/screen dressing, varied occupation, and night light ordering.

**Disposition:** production/source and focused checks are ready; serialize `INN-COMMON-ROOM-R10` before any further edit.

## The Highfield

R14 is the latest accepted production evidence and independently earns **PASS**.
The wide pair establishes the road, fenced drove pasture, stock camp, herd, and pale
shade-tree landmark; the compressed pair joins the working camp, open threshold, and
nearby animals in one readable ordinary-player composition. The strict `03`/`04` pair
also clears R12's last blocker by presenting the full production alpha and a full
ordinary Meadowhart together, separated and uncropped, with the larger alpha silhouette
visible in both clocks.

**Disposition:** promote The Highfield from POLISH to **PASS** on
`HIGHFIELD-HERO-IDENTITY-R14`; see that round's `REPORT.md`. Residual mottled ground,
simple camp materials, and cool crushed night foreground are non-blocking shared polish,
not reasons to reopen this named-location row.

## The Rise

Latest accepted pixels are R2. They remain POLISH because the close road-end view is crowded by foreground stones, ordinary tree masses, and the fingerpost; the hero crown does not control that gameplay frame, and night reveals pale foliage/rock value discontinuities.

The current production R3 candidate is already the supported correction. It increases the single wind-shaped hero tree, moves the three bounded crown stones away from the road-end foreground, and uses the existing small local sightline clearing to remove the accidental tree wall. It does not add another hero, alter either road, or widen the broader hillside clearing. The capture's matched close view now aims at the actual crown. Focused checks pin one hero, three distinct bounded stones, named-region containment, road clearance, and the two scoped clearing lenses.

**Disposition:** production/source and focused checks are ready; serialize `THE-RISE-IDENTITY-R3-OPEN-CROWN` before changing night values. R3 pixels must decide whether a later local material adjustment is justified.

## The Ridgeline Watch

R5 is the latest accepted production evidence and independently earns **PASS**.
The route pair holds the complete watch silhouette at an ordinary 34 m approach with
the production creature population still present; the opposite pair connects a winding
dirt route to the tower; and the service pair proves an attached, supported lean-to,
stairs, fire, workers, supplies and equipment in one readable day/night composition.
The night practicals preserve both use and landmark silhouette without any injected
content.

**Disposition:** promote The Ridgeline Watch from POLISH to **PASS** on
`RIDGELINE-WATCH-R5-FRAMED`; see that round's `REPORT.md`. The broad pale upper rail,
simple scaffold geometry and mottled meadow ground remain non-blocking shared polish.

## Stronghold Approach

R6 is the latest accepted production evidence and independently earns **PASS**.
The four-pair route sequence preserves the road, wildlife, repeated pylon/cable run,
occupied threshold, ramp, and fortified Hall from 377.33 m through the 80.89 m final
overlook. In the closest night frame, the ramp's local surface value and shallow
cross-courses now expose its broad plane, grade, and distinct upper landing without
lifting global exposure or making the cyan machinery dominant. This closes R5's sole
promotion blocker while retaining its selective facade modelling.

**Disposition:** promote Stronghold Approach from POLISH to **PASS** on
`final-stronghold-approach-06`; see that round's `REPORT.md`. Repeated planar
architecture, the cropped close creature in pair `03`, and broad smooth slopes remain
non-blocking shared polish.

## Source-lane conclusion

No production visual edits were added by this ledger audit or its later independent
review updates. Named-location promotions recorded above come only from completed
production captures and fresh code-blind verdicts; unseen source candidates do not
change a grade. Stacking new art changes before a queued capture would erase the
ability to attribute a PASS or failure to the repair already waiting for evidence.
