# Stormwood Crown Arch visual candidate — 2026-09-09

## Scope and source finding

The current blind audit named `stormwood__hollow_crown__07__the_crown_arch__day.png`
as a plain pale landmark. The production emitter for that frame was
`scripts/world/stormwood_arch_runtime.gd::_build`, not a filename-matched capture
fixture. It put one material override across `WallEntrance.obj`; the Crown's lit
state then applied emission to the whole masonry surface. The retained baseline
shows the result as a near-white block by day and night.

The player-built path separately used `scripts/build/stormwood_arch_piece.gd`.
This candidate makes that file the shared visible presentation while leaving the
runtime as owner of ancient interaction, passage and footing collision.

## Production candidate

- Uses installed `WallEntranceBricks.obj`. Godot identifies its two imported
  surfaces as `LightRock` (broad masonry) and `DarkRock` (raised bricks).
- Gives broad masonry a non-emissive storm-slate finish. Only the installed raised
  brick surface receives stormglass colour and relight emission.
- Mirrors only the installed raised-detail geometry so both travel directions have
  the same visual identity. The opaque masonry shell is not duplicated.
- Keeps the existing unlit, half-linked and fully linked states. The Crown's
  half-linked presentation uses the existing `0.18` flare; a linked arch uses the
  full state. Ghost validity tint still covers the whole preview.
- `build_display()` adds no collision for ancient arches. `build_real()` still adds
  exactly two jamb boxes and one lintel box around the open aperture.

No arch positions, scale contract, prompt, collider dimensions, Area3D, travel,
ledger claim, inventory cost, save/progression fact or realm transition changed.

## Two bounded visual rounds

Round one restricted emission correctly but made the broad frame collapse to a
near-black block in the production day/night stand. It is retained at
`shots/catalogue/stormwood/round-crown-20260909T115800Z/` and was not accepted as
the production candidate.

Round two lifted the masonry to readable storm-slate and added the reverse-facing
installed brick detail. Final evidence is
`shots/catalogue/stormwood/round-crown-20260909T120117Z/`:

- `stormwood__hollow_crown__07__the_crown_arch__day.png`
- `stormwood__hollow_crown__07__the_crown_arch__night.png`
- `crown-arch-before-after.png` (baseline/final, day/night)
- `manifest.json`, `engine.log`, wrapper logs and `memory-watch.csv`

The Compatibility/OpenGL3 production scene captured 2/2 planned frames with
`manifest.complete=true`, zero capture failures and a clean raw scan for `ERROR:`,
`SCRIPT ERROR`, parse errors and `FAILED`. The guard peaked at 67.35% committed
memory and 248 processes; the 600-second, 90%-commit and 400-process stops did not
fire. The process chain exited and the render lease was released.

That canonical camera still stands inside the arch and therefore crops the full
silhouette. It proved that the pale whole-mesh emission was gone and that the rear
masonry remained readable at 08:00 and 23:00, but it was weak evidence for the
small raised details and full approach silhouette. Source inspection after capture
found that the first reverse-face transform reflected detail around the asymmetric
mesh bounds and buried it 0.125–0.191 m inside the rear shell. The corrected transform
uses the actual ornament-footprint planes from the installed OBJ: front detail base
`z=0.089286`, rear LightRock face `z=-0.396199`, and the source detail's own
0.023–0.025 m outward depth. A focused test verifies both front and rear details
project at least 0.05 m after four-metre normalization.

The final geometry proof is retained at
`shots/catalogue/stormwood/round-crown-geometry-20260909T122632Z/`. It contains a
fresh canonical day/night pair plus two labelled production-camera contexts. After
the canonical setup, the capture assigns no actor, arch or camera transform: it waits
until the real `RegionBanner` is hidden, walks the real trainer with `move_back`
12.341 m to the west, captures the full rear face, walks with `move_forward` 20.350 m
through the arch to `(493.067, 74.001, 2701.705)`, then holds `look_right` to orbit
the production rig 176.914 degrees and captures the full front face. The final point
is 8.067 m east of the Crown's `x=485` plane and grounded within 0.001 m of `y=74`.
Both frames visibly contain the whole arch and the cyan raised details outside their
respective shell faces; Senn remains in the authored opening. The manifest resolves
the runtime node as `StormglassArches/e_crown` at `(485, 74, 2700)`, yaw 90, with
`ArchPresentation` present. It is complete with four frames and no failures.

The successful run used PID 11080 from `2026-09-09T12:26:33.022Z` through
`12:27:31.714Z` (58.69 s). The guard peaked at 68.77% system commit and 253 processes;
the 600-second, 90%-commit and 400-process stops did not fire. Raw logs contain no
`ERROR:` or `SCRIPT ERROR`. An earlier completion attempt is retained at
`round-crown-geometry-20260909T122408Z`: its canonical pair and rear frame succeeded,
but the 24 m passage target stopped at a finite 21.845 m after natural collision
deflection and the receipt then hit a `Window`/SceneTree API error. It exited 1 and is
not presented as passing evidence. No third material round or actor relocation was
used. Independent code-blind judgment belongs to the root lane; this report does not
claim that the Stormwood biome or Crown landmark passes.

Capture identity is not inferred from the HUD. The final manifest records the
production Stormwood scene, player `(485, 75.7801, 2700)`, terrain/resolved floor
`y=74`, camera `(479.9136, 78.6113, 2700)` and heading `+X`; the authored `e_crown`
is exactly `(485, 2700)`, yaw 90. `Challenge Senn` is expected because Stormwood's
`archwright_senn_crown_footing` is authored at that same coordinate. The transient
`Cinder Verge` banner is queued during the world's entry spawn before the quick
same-realm catalogue teleport and remains visible for its 3.2-second HUD lifetime;
it does not describe the manifest position.

## Mechanical evidence

- `test_stormwood_arch_piece.gd`: 4 tests / 31 assertions / 0 failed after the final
  candidate. It verifies imported surface identity, split materials, shared relight
  state, visual-only ancient construction, ghost tint, four-metre normalization and
  the unchanged three-shape constructed aperture. No raw engine errors.
- `smoke_stormwood_arches.gd`: `STORMWOOD ARCHES: PASS`. This exercises production
  relighting, linked travel, Crown construction, dismantling and return refusal.
  Its raw exit retains the pre-existing `5 ObjectDB instances were leaked` warning
  and `ERROR: 2 resources still in use at exit`; these are not hidden or counted as
  a clean raw-error run.
- `git diff --check` on the three owned source/test files: pass.

## Receipts

Final independent disposition: **A No / B No**, candidate held. The reused
image-only reviewer saw the final east/front, west/rear and canonical night
frames (01–03) and still found flat architectural form, exposed plinth, competing
foliage colors and poor ground/night hierarchy. See
`VISUAL-WAVE-IMAGE-REVIEW-0909.md` for the full review and independence disclosure.
The geometry correction establishes visible rear detail, not accepted landmark
art. No third material tune is authorized by this bounded task.

| File | SHA-256 |
|---|---|
| `scripts/build/stormwood_arch_piece.gd` | `114C7C724FEFFC46CE6519D1E0BFBC0587D96DFC230C1BB3DFC37FDC0321D961` |
| `scripts/world/stormwood_arch_runtime.gd` | `5A77C3D40556D78A3A5C1E3ED3415BDFBD0F1E1081867A34673C7F351CCA67EF` |
| `tests/test_stormwood_arch_piece.gd` | `9D3EF7AD094A00867F4334C691F1D15C11A67BB487602330524D7125070C8EFC` |
| final day frame | `920F2B65960767776855F4B8CA816632D64933024A52FCAE5F1C83C19466B17A` |
| final night frame | `E2170240EB96D6DA4F84774624720017F88B02E1AB8C682B138F1084F03FE27B` |
| final west/rear context | `95899DED5D474C0F1440AC57EAEB01F04560247CB720E9B6E615466DD7E11E04` |
| final east/front context | `1273CBF0E3BB2E8EEF0FFE9E8C65C249A7A9CE45222CF3A72F7B417A4AD5505D` |
| before/after sheet | `8AD1B65EE6BE542A9218F843B353A8B760606B28AFAB175034461FA67F1D40E6` |
| final manifest | `4556162D21BAFCB73C42B6E5DA9D3AE31EE1765A8C034B0944BA990A0B053BDD` |
| final wrapper receipt | `3136E30039D21DAC023868F4BE480319BF6DC2307D2E99515487C9935EDCD39D` |
| final memory watch | `DCAF1AE9A2447A41189B583D344899D0436C4EFA6346EFA637356D2A312D3046` |
