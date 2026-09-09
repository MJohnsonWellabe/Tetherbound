# Water First Shore return-gate site — 2026-09-09

## Source and composition

The independent image review finds the installed-masonry return gate almost
edge-on and isolated on uninterrupted ground. The gate remains fixed at
`(12, ~1.881, 162)`, yaw 0. Water arrival is `(0, ~1.929, 162)`, so ordinary
arrival reaches it from the west edge. Dockkeeper Mara is `(-5,154)`, Campkeeper
Elin is `(11,141)`, and Swimmer Pell is `(53.368,151.502)` to the east/southeast.
No actor or route coordinate changes.

`water_first_shore_gate_site.gd` mounts a visual-only threshold court beside the
production `RealmGate`. Three installed `Floor_UnevenBrick` courses ground the
fixed threshold. Seven staggered courses bend from the arrival around the gate's
south/front face and continue toward Pell. Two unequal installed `Rock_Medium`
stones frame the outside edges. Every piece samples Water terrain at its own
centre and grounds its measured render bounds, avoiding one hovering slab across
the beach slope.

The site contains no `CollisionObject3D`. The RealmGate remains sole owner of its
2.95 m opening, four-metre prompt, barrier collision, locked/open state and travel.
The conservative rotated half-diagonal of each framing rock clears the complete
prompt circle. The shared gate mesh/material file is untouched. No terrain, light,
weather, camera, route, cast, progression or save state changes.

## Focused evidence

- `test_water_first_shore_gate_site.gd`: 2 tests / 60 assertions / 0 failed.
  Loads all 12 installed assets, measures and grounds their render bounds, proves
  the site is collision-free and verifies conservative rock/prompt clearance.
- `test_water_return_connection.gd`: 6 tests / 40 assertions / 0 failed. The
  mounted gate position, destination, authority, state and Stormwood arrival
  contract remain unchanged.
- Both focused logs have no `ERROR:`, `SCRIPT ERROR`, parse error or `FAILED`.
- JSON parsing and `git diff --check` pass.

## Production image evidence

The production capture is retained at
`shots/catalogue/water/round-first-shore-gate-site-20260909T130808Z`:

- `first-shore-return-gate-ordinary-front-day.png`
- `first-shore-return-gate-ordinary-front-night.png`
- `manifest.json`, `wrapper-receipt.json`, `memory-watch.csv`, and complete
  engine/stdout/stderr logs

This is the production Water scene with its ordinary gameplay HUD. The real
player begins at the authored `(0, ~1.929, 162)` First Shore arrival, walks three
legs using only left-stick input, and faces the fixed gate using only ordinary
look input. All three legs reached. Total displacement was 14.726 m; the final
player position was `(11.882, 2.935, 153.359)`, grounded and 8.705 m from the
gate. The look finished within 3.52 degrees of the requested bearing. The region
banner was not visible. Day and night share the same player, camera and gate
positions. The manifest records 12 site pieces, unlocked gate state, two frames,
no fixture failures and `complete: true`.

PID 16180 ran from `2026-09-09T13:08:08.3711195Z` to
`2026-09-09T13:08:48.5065032Z`, exit 0. The 600 s / 90 percent committed-memory /
400-process guard ended on ordinary process exit after 40.135 s. Peak committed
memory was 56.775 percent and peak process count was 255. Complete raw-log scan
has no `ERROR:`, `SCRIPT ERROR`, parse error or `FAILED`; the logs contain only
the existing interpolation deprecation and Terrain3D no-mipmap warnings.

The frame honestly exposes an adjacent production-world visual issue: the large
plain rectangle right of the gate is
`WaterDocks/first_shore_to_reedhaven_dockBarrier`, not part of this site and not
a fixture/render defect. `water_dock_actions.gd` creates its 10.0 x 2.5 x 0.35 m
BoxMesh and matching collision at `(0, ground, 167)` while
`water_swim_lesson_complete` is unset. `water_swimming.json` explicitly calls
the barrier's dimensions starting kitbash geometry pending visual acceptance.
It is a meaningful progression blocker and must not be removed as scenery; the
ordinary fresh-arrival image shows that its provisional presentation competes
strongly with the gate site.

Source SHA-256 at capture:

- `water_world.gd`: `8A060B0DFA2C25C2F8D6B3E71306118D830CFD70120E9FF415EEB1E27399371F`
- `water_first_shore_gate_site.gd`: `BB86D1E4348FA6D5678C62EEF3638190CF3066D7D9C8D7C8036C3F4ADE92CD39`
- `water_first_shore_gate_site.json`: `5D7DB2E3221155F54B6B05C87D29B383F34679EE1E4A79C79C3AEF373A0FAC73`
- `test_water_first_shore_gate_site.gd`: `333DED13D1DFCD99B3BBDFD156DF0BCBA90414F9FAA12A07EA2D384BBD7CD8F1`
- `_capture_water_first_shore_gate_site.gd`: `99A70E00AEF18CB965527CED3AEB0DC5C8DE48642EDF514A002E866886AEDE07`

The site candidate and its matched pair remain pending independent image
judgment. No second Water material/composition round was started.

## First Shore dock blocker follow-up

Independent wave-2 judgment remained A/B No and identified the adjacent authored
dock barrier as the dominant frame defect. The original 10.0 x 2.5 x 0.35 m
plain BoxMesh has therefore been replaced only for
`first_shore_to_reedhaven_dock` by three courses of five installed Quaternius
wood-fence bays. The Single/Extension1/Extension2 cross-brace variants alternate
deterministically. Each roughly two-metre bay is normalized by only 1–2 percent
in X; three courses are fitted by less than one percent in Y to occupy exactly
the old 2.5 m height. The result is a closed working-dock timber lattice whose
visible X/Y/depth bounds correspond to the existing collision.

The existing `BoxShape3D(width, height, 0.35)`, barrier transform, unlock flag,
current gating, `_barriers` ownership and whole-body removal in `_refresh()` are
unchanged. The imported fence scenes add no collision. Every later dock retains
the existing BoxMesh presentation path.

The first focused bounds run correctly failed 1 of 54 assertions: the right edge
landed at +5.019 m because `Prop_WoodenFence_Extension2` has an asymmetric local
X origin. The implementation now subtracts each installed variant's measured
AABB centre after scaling. The retained corrected run passes 2 tests / 54
assertions / 0 failed, proving visible X `-5..+5`, Y `0..2.5`, depth <= 0.13 m,
15 installed visual roots, zero added collision, First-Shore-only scope and the
unchanged shared collision source. `git diff --check` passes.

Final production evidence is retained at
`shots/catalogue/water/round-first-shore-fullheight-dock-20260909T132638Z`.
Both ordinary day/night frames share player/camera/gate positions. All three
left-stick route legs reached; the player finished grounded after 14.598 m of
displacement, 8.557 m from the gate; ordinary look reached and the region banner
was clear. `manifest.complete` is true with two frames and no failures. PID 3516
ran `2026-09-09T13:26:38.6311638Z` through `13:27:21.0806482Z`, exit 0 after
42.449 s. The guard peaked at 57.795 percent committed memory and 258 processes;
no limit fired. Complete capture-log scan has no `ERROR:`, `SCRIPT ERROR`, parse
error or `FAILED`.

Final follow-up SHA-256:

- `water_dock_actions.gd`: `EEC90628D5338857F12B2A131D53D202A69ED56F88838F60BAA099765628A99F`
- `test_water_first_shore_dock_barrier_visual.gd`: `8BC4217A296A6B3BD1D8121DEF9F30192BBD65C7AC5B6ABB9BB178BAAE3EEB3E`
- final day frame: `0794CBEED66D22411F19165EA22CDC9C2F1B1812ED5E21438D95593537E6A9F1`
- final night frame: `8CEC2FBB8340F65DE92DFC840E7F5013E4C7DFAE475F11373324F4EB0B49B597`
- final manifest: `0E6C38C568B98FBE765AE1428F252227CB4F27015CE02874E5C0F399C91401AA`

Independent image review is complete in `VISUAL-WAVE3-IMAGE-REVIEW-0909.md`: both visual bars remain No. The timber barrier reads more clearly, but the isolated gate, sheet-like paving, coarse surfaces and dark night composition still fail the destination scene. This candidate is retained locally and held from shipping; no additional material-only round is authorized for this scene.
