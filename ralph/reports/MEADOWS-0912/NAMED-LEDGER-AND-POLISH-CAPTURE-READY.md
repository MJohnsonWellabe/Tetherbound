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

Latest accepted pixels are R5. They remain POLISH because the herd, open drove gate, and stock camp do not consistently resolve as one composition; mounted creatures dominate the close views, while the wider pasture retains too much undifferentiated ground and too little vertical identity.

The current production R6 candidate is already the evidence-supported repair: one 25 m old pasture tree behind the working group, trunk-only collision, and paired drover lanterns provide a shared day/night vertical backplane without moving encounters, closing the gate lane, shrinking creatures, or expanding the broad scatter edit. Its capture viewpoints have been raised toward the new shared silhouette. Focused checks pin scale, position, encounter clearance, trunk-only collision, lantern count, production wiring, open route, camp/gate/herd spacing, and ground-cover preservation.

**Disposition:** production/source and focused checks are ready; serialize `HIGHFIELD-HERO-IDENTITY-R6` before any further edit.

## The Rise

Latest accepted pixels are R2. They remain POLISH because the close road-end view is crowded by foreground stones, ordinary tree masses, and the fingerpost; the hero crown does not control that gameplay frame, and night reveals pale foliage/rock value discontinuities.

The current production R3 candidate is already the supported correction. It increases the single wind-shaped hero tree, moves the three bounded crown stones away from the road-end foreground, and uses the existing small local sightline clearing to remove the accidental tree wall. It does not add another hero, alter either road, or widen the broader hillside clearing. The capture's matched close view now aims at the actual crown. Focused checks pin one hero, three distinct bounded stones, named-region containment, road clearance, and the two scoped clearing lenses.

**Disposition:** production/source and focused checks are ready; serialize `THE-RISE-IDENTITY-R3-OPEN-CROWN` before changing night values. R3 pixels must decide whether a later local material adjustment is justified.

## Source-lane conclusion

No additional production visual edits were added in this audit. All three evidence-supported repairs are already present at the current source head but remain unseen in their named pending rounds. Stacking new art changes before those captures would erase the ability to attribute a PASS or failure to the repair already queued. The only new source change is the focused static ledger/capture-round contract.
