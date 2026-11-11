STATUS: land
BRANCH: tb/below6-abyssal-land (cut from origin/main 8df122a83, after #910; READY is in the same commit)

# F36#30 Abyssal Guardian: matte hide, ON (LANE-BELOW6, 11 Nov 2026)

The grade is LANE-REMAKES' work; its texture and OFF flag landed in PR #910. This landing only turns the flag on.

## Verdict
`ralph/reports/GPU-PASS/1108/G-below6-abyssal-matte.md` on `tb/item-scout-1108` 44f5b38be (GPU High, three code-blind judges, confirming batch):

| Row | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| F36#30 Abyssal Guardian (land form) | 5.22 | 5.77 | +0.55 | 3/3 |
| F36#88 Water Abyssal Guardian | 4.81 | 4.81 | 0.00 | 3/3 level |

- Land form: "glossy vinyl" PRESENT -> PARTIAL 3/3. The row is still under 6; LANE-THINGS' faint grounding (landing separately) is expected to stack on it.
- Water form: level. The flag also gives it the matte values; it neither gains nor loses, and the row gets nothing from this landing.
- High only; Medium has not been judged.

## Flags
- ON: `creature_coat_flags.json remakes_floor_abyssal_guardian`, with `_why_on` citing the verdict and both scores.

## Files
- `data/config/creature_coat_flags.json` (one flag flipped, `_why_on` added)
- `tests/test_remakes_floor_landed.gd` (the "Abyssal stays OFF" test becomes "ships ON, cites the verdict, the land form wears the floor1 hide at roughness 0.86")

## Tests
Run in the lane checkout with main's flag files and these two files copied over: `--only=remakes_floor_landed,creature_coat_flags,texture_import_policy,remake_owner1101_finish,creature_model_flags`: 21 tests, 3919 assertions, 0 failed; the per-file lines show `test_abyssal_matte_hide_ships_on` ok. No full suite (one config flag).

## Not fixed (judges, 3/3)
- The hit is almost identical to standing; the faint never goes down (LANE-THINGS' faint grounding).
- Blade or flipper legs read odd (2/3); smooth skin with no scale detail.
