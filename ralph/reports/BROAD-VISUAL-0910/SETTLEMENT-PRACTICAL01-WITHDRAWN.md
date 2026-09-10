# Settlement practical light 01 — withdrawn

Status: **WITHDRAWN.** The bounded exterior window-spill candidate had correct
construction and day/night lifecycle evidence, but the matched native comparison and
fresh blind review found no meaningful visual improvement. The candidate is preserved
under `.artifacts/broad-visual-0910/settlement-practical01/`; root removed it from
production rather than tuning light energy without visual evidence.

## Candidate scope

The candidate added one warm `SpotLight3D` to each of two existing Meadows facade
recipes: Grandpa's `farmhouse_shell` and Village `cottage_a`. Each light was attached to
an installed `Window_Wide_Flat1` source at local offset `(0, 1.73, 0.45)`, faced forward
through the configured facade, used energy 0 by day and 2.2 at night, and faded from
30–40 m. It did not change exposure, ambient light, interiors, geometry, collision,
NPCs, routes, camera, HUD, or gameplay. No benefit outside those two authored Meadows
facades was claimed.

## Validation receipts

- `settlement-practical-unit-first` ran from `2026-09-10T10:01:03.3938424Z` to
  `10:01:09.8625192Z` and exited 1 before tests ran. The retained parse error was
  `Cannot infer the type of "source_matches" variable because the value doesn't have a
  set type` (1 test, 0 assertions).
- After making that test variable explicit, `settlement-practical-unit-second` ran from
  `10:01:36.3346472Z` to `10:01:41.3931918Z` and passed 3 tests / 27 assertions with no
  engine errors. It covered day/night energy, the two authored facade sockets, measured
  source bounds, duplication, range/cone/shadows, and distance fade.
- `settlement-practical-lifecycle-first` ran the real SceneTree lifecycle from
  `10:01:50.7099120Z` to `10:01:55.7253738Z`, exited 0, and reported zero failures for
  day 0 → night 2.2 → day 0.
- Native ON capture `settlement-practical-native-on-first` ran from
  `10:02:10.3644659Z` to `10:03:44.7495451Z`; matched OFF control
  `settlement-practical-native-off-first` ran from `10:03:59.6039630Z` to
  `10:05:33.1740320Z`. Both exited 0 with two day/night frames and no engine errors.
- The audit-enhanced ON receipt `settlement-practical-on-receipt-first` ran from
  `10:18:14.6060985Z` to `10:20:03.0037307Z` and exited 0. Its manifest proves exactly
  two visible placed lights. Both read energy 0 by day and 2.2 at night. Camera distance
  was 26.074 m for `GrandpaHouse/KitShell/SettlementPracticalLight` and 24.256 m for
  `Village/cottage_a_3/SettlementPracticalLight`, both inside the 30 m fade start. Each
  matched its configured `Window_Wide_Flat1` with zero socket-position error and
  light-minus-window offset `(0, 1.73, 0.45)`; the recorded global forward vectors also
  follow their respective facades. This rules out the suspected lifecycle, placement,
  facing, and distance-culling failures in the supplied view.

## Visual disposition

`JUDGE-SETTLEMENT-PRACTICAL01.md` judged the ON and OFF pairs a tie and found no
meaningful environmental improvement. Day/night identity was clear in both, while the
night yard still lacked readable local warmth and middle values. The candidate therefore
does not meet its acceptance condition of a visible, localized threshold/NPC readability
gain, despite being active and correctly bound.

No further energy tuning is justified by this evidence. Ordinary entered-store light
contrast remains open: these exterior catalogue frames and two exterior spill sources do
not validate the lighting a player sees after entering a shop or other interior.
