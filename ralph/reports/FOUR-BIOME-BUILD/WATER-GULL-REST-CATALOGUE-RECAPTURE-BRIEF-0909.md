# Gull Rest signal site — catalogue recapture brief

Date: 2026-09-09  
Status: changed strategy completed mechanically; visual acceptance remains external

## Finding

The mature catalogue pipeline can render the frozen Gull Rest candidate without
the failed site-specific helper or a new world harness. `tools/catalogue_survey.ps1`
already mounts the production Water scene, selects one canonical destination by
substring, uses `Game.debug_teleport_to`, settles the real trainer on production
ground, and captures the production spring-arm camera and ordinary gameplay HUD at
day and night. Its argument construction passes `--output=<nonempty path>` as one
PowerShell array element. Omitting `-Output` lets the wrapper create its own unique
timestamped `res://shots/catalogue/water/<stamp>` directory, removing the empty-output
mechanism from the failed custom launch.

For destination 19, the catalogue derives forward from destination 20. The retained
coordinates produce heading `(0.141, -0.990)`. The frozen site at `(-70, 881.5)` is
23.66 m forward and essentially centered laterally from the retained stand-19 camera,
so this unchanged canonical production view directly targets the candidate. It is an
ordinary camera/HUD appearance view after debug travel. It is not evidence that a
player physically walked either adjacent route leg.

The mature tool has no supplemental movement-frame contract. It therefore cannot
replace the failed helper's promised incoming-spine traversal receipt. That limitation
does not prevent a first trustworthy appearance pair; any future physical-route proof
must use a separately reviewed gameplay path rather than being inferred from these
frames.

## Frozen production input

Commit `a8ec5de76` remains the candidate source boundary. The four candidate-specific
files in the current workspace are byte-identical to the report's frozen hashes:

- `data/config/water_gull_rest_signal_site.json` —
  `B8EEAB0BA46CE0C4D63C185B6237F7CA47CA004A0D4148E64AA5CFEC8E215329`
- `scripts/world/water_gull_rest_signal_site.gd` —
  `740C920F7CB21B3935E33A5BA5CAAD2604DD255CB2B382386DC4E42EC0654FCE`
- `tests/test_water_gull_rest_signal_site.gd` —
  `AA140BCE3D8BEB67113FE9E010DDE6739CF44AC6F6AB8B6922C1410A4C8023B4`
- `tools/_capture_water_gull_rest_signal_site.gd` — retained failure artifact only,
  `A78F5083203EE5B2253652152576EE1E6D6896763B34B0B2C16BCD872E90EAAC`

The production mount in `scripts/world/water_world.gd` remains the committed
non-simulation Gull Rest delegation. No candidate geometry, materials, collision,
terrain sampling, actors, pickups, routes, camera, lighting, or progression may change
for this evidence run.

The established catalogue files are also unchanged from their mature pipeline:

- `tools/catalogue_survey.ps1` —
  `F315CBD2DDCC1609B346321F8A9DF694FA18866CEB5D49E6ADADB5B8CC426241`
- `tools/catalogue_survey.gd` —
  `B7D0FD316B05ED95A04045ACCC430C69A946E000701226F29183F48373B7BB66`
- `tools/catalogue_survey_validate.ps1` —
  `50CC5FEFDCFD17E7C40D7186CE53F70E613D8D7EE052C4952CC97818C33A1B33`

## Launch plan

Preflight without Godot:

```powershell
tools/catalogue_survey_validate.ps1 -Biome water -Subset gull_rest_signal_spire -Json
```

It must enumerate exactly these two planned identities at authored X/Z
`(-72.615, 899.886)`:

- `water__gull_rest__19__gull_rest_signal_spire__day`
- `water__gull_rest__19__gull_rest_signal_spire__night`

After root grants the exclusive full-world lease, invoke the established wrapper and
let it choose the fresh output root:

```powershell
tools/catalogue_survey.ps1 -Biome water `
  -Godot C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe `
  -Subset gull_rest_signal_spire
```

The outer launcher should retain merged wrapper output, the wrapper-created
`engine.log`, a 600-second process ceiling, 90% system-commit and 400-process guards,
and all engine child/system receipts. Do not use
`tools/_capture_water_gull_rest_signal_site.gd`, add output flags to it, or create
another capture subclass.

## Evidence acceptance and limits

Mechanical acceptance requires wrapper exit 0; manifest `complete=true`, planned and
captured counts `2/2`, failures `[]`; both exact PNG names present, nonempty and
1280x800; distinct day/night hashes; manifest destination, player, production camera,
heading and observed-clock records; and a complete raw-error/warning inventory.

Visual review may judge only what the two unchanged canonical frames show: whether the
installed signal lookout is visible as the named landmark, is terrain-grounded, reads
coherently by day and night, and avoids a material/composition regression. The result
does not prove ordinary route traversal, exact support contact, interaction, campaign
progress, or whole-Water visual acceptance.

## Preserved failures

The first custom attempt stopped before world boot on two warning-as-error type
inferences. The second booted Water but split its output argument into empty
`--output=` plus an unrelated value; all three PNG writes targeted the filesystem root
and failed. It retained no frames or manifest and produced six error lines: three PNG
save errors and three tool failures. Its control flow reaching save calls is not a
quantitative movement/contact receipt. Both failures remain recorded in
`WATER-GULL-REST-SIGNAL-SITE-0909.md` and are not superseded by this strategy.

## Completed mature-catalogue result

Root granted one run of the exact plan above. It created
`shots/catalogue/water/20260909T170250Z` and printed `CATALOGUE SURVEY OK: 2/2`.
The manifest is `complete=true`, planned/captured `2/2`, failures `[]`, and contains
the exact two preflight identities. Both records use player X/Z
`(-72.614998, 899.885986)`, heading `(0.141057, -0.990001)`, and the same production
camera X/Z `(-73.332474, 904.921570)`. Requested and observed clocks agree at day and
night. Terrain and resolved ground are both `28.851131`; player Y is `28.849829`.

- day PNG: 1280x800, 1,516,140 bytes,
  `9547C982ED53DA1B84AC9EEBFA4231EB937B1B043A7D671639DF5A5B91C7B3A2`
- night PNG: 1280x800, 1,263,422 bytes,
  `84B0DD9CAE6B11070C31077D172E177129D090C63B218EA9AC12EF18D14ADD8D`
- manifest:
  `51DDD7666F8D5767AC855C5D4A897E517EE16933845F1CBC70E5D9A248426C94`

The run lasted from `2026-09-09T17:02:49.5934542Z` to
`17:03:08.1317139Z`. Peak system commit was 61.54% and peak process count was 254;
owned PIDs 4056, 5564, 6968 and 14204 are terminal, and Godot count returned to zero.
The guard did not fire. The outer `Start-Process` receipt's `exit_code` field is null
because its refreshed process handle did not retain the child exit value; it is kept
null rather than relabelled. The outer shell returned 0, the wrapper reached its normal
2/2 success line, and the complete manifest validates the images. Strict engine-exit
acceptance remains unproven because the retained process handle did not preserve that
child exit code. No rerun was made to fill the missing receipt field.

Wrapper stderr and `engine.log` contain the same seven known warning starts: one
physics-interpolation deprecation and missing mipmaps for the albedo and normal maps of
meadow grass, dirt path and rock scree. Both streams contain zero `ERROR`,
`SCRIPT ERROR`, out-of-memory or allocation-failure lines. Raw receipts are under
`.artifacts/gull-rest-catalogue-mature-0909`.

Both frames visibly contain the installed signal structure in front of the ordinary
trainer and HUD. The transient First Shore story banner overlaps the structure's upper
platform/signal area in both frames; this is retained ordinary UI, not cleared or
recaptured. Whether that occlusion and the structure's day/night presentation satisfy
the visual bar belongs to independent review. The manifest establishes the trainer's
ground resolution, but does not measure the site's four support contacts or physical
route traversal; those claims remain limited exactly as stated above.
