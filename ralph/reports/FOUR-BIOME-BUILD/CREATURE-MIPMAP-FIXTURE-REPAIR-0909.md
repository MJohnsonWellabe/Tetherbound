# Creature mipmap fixture repair — 2026-09-09

Status: fixture repair validated. The viewport, runtime mipmap treatment and capture
guards pass, but the captured A/B images have not yet been analyzed against the causal
experiment's preregistered metrics. No production material, texture, import, runtime
or scene file changed.

## Retained viewport failure and repair

The earlier renderer requested 1280x800 from the root viewport, but the physical
window remained 1920x1200. That invalidated its capture-size assumption. The fixture
now owns a `SubViewport` sized 1280x800, gives it an independent 3D world, parents the
stage and camera beneath it, waits for `RenderingServer.frame_post_draw`, and rejects
the capture before saving unless the returned image is exactly 1280x800. The
non-rendering preflight no longer asserts a physical viewport size.

The first guarded Compatibility run of this repair produced 162 PNGs, all physically
1280x800. Its manifest contained 162 records. Sparkit remained 11 mip levels in both
branches; a generated-vivid sample remained 0 in A and generated 10 in B. The clean
preflight independently proved seven active 0-to-10 treatments and the Sparkit
11-to-11 control.

## Retained projected-size failure

That renderer correctly exited nonzero with 104 projected-height failures across 13
species. The distinct measured heights were Skyrill 258.59, Tanglevolt 239.74,
Voltwig 223.02, Voltarach 222.62, Mosshock 235.51, Staticub 221.22, Stormraven
230.16, Mangrove Monitor 248.80, Mirejaw 272.52, Riverdrake 236.80, Cragclaw
220.28, Sirenseal 243.16 and Riptusk 222.16 pixels. Each failed in all four offsets
and both branches. The manifest therefore has `complete=false`; these captures are
fixture evidence, not a completed causal comparison.

The analytic distance used only the body's vertical half-extent. Perspective expansion
of the nearer corners of a deep full-body AABB is a source-supported explanation for
the estimate placing many species too close, but the next fit run must establish
whether it accounts for the observed failures. The prepared source correction brackets
the 180-pixel target from the analytic estimate and performs 24 fixed bisection
iterations against the actual projected full-body AABB. It runs once before either
material branch. The resulting camera is then shared by A and B, and the four
preregistered subpixel offsets remain unchanged. The existing 140-to-220
projected-height guard and viewport-bounds guard are unchanged.

## Validated camera-fit capture

After source review, the latest probe passed `--check-only` and one guarded
Compatibility-renderer run completed with 162 records, 162 PNGs and no manifest
failure. Every PNG is physically 1280x800. All 160 isolated records satisfy the
unchanged body guard; projected heights range from 180.0000 to 180.0001 pixels. All
recorded materials retain filter 3. The generated-vivid A records retain zero mip
levels and their B records contain 10; Sparkit remains 11 in both branches.

The validated output is `.artifacts/creature-mipmap-camera-fit-0909/captures`.
`verification.json` records zero bad dimensions, body guards, treatments, changed
held-input hashes and renderer error lines. The terminal census found zero Godot
processes. Passing these fixture guards establishes a valid capture set; it does not
establish that mipmaps pass the cohort, stability, value-range or face-contrast
criteria.

The three held paint inputs were frozen before capture and unchanged afterward:

- Pebblik: `4935559AB859D5236345A305EE7B74237193A7BD8E860DE3D21D98BF037313B6`;
- Voltarach: `D00D1ACE21C8F10E27405962245A26974327AB83BA8C6FACD7A798728DB42262`;
- Torrentoad: `9FD5DC2D07F4A6A5F23178F0511CB42F368295D85A1D7922141F8FC5EBE06815`.
