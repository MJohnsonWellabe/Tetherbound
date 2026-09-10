# Cloudreach Windscar Beacon — 2026-09-09

Status: one source-bound open-beacon candidate passed focused geometry checks. The
first production-world evidence run failed its ordinary grounded view and route. One
authorized corrected proof run then passed the complete grounded route, but its
conservative full-bounds image assertion failed. The sequence is stopped after that
second world attempt. No overall visual acceptance is claimed.

## Attribution and contract

The retained stand 05 pair showed the camera inside the old Windscar Beacon's solid
primitive skin. Source confirmed that the runtime landmark consisted of an 8 m radius
plinth, a 3.8 m radius by 26 m tower, a crossarm and a signal cylinder, all centred on
the authored player survey anchor `(-260, 500, 2680)`. Those meshes had no matching
collision. The configured landmark is a major ground-traversal silhouette, visible
from Broken Causeways and Windscar Ravine, so an opaque skin occupying the survey and
camera position violated both the landmark and traversal presentation.

The candidate preserves the authored anchor and its 26 m scale. It places a two-frame
open arch 15 m forward on the retained heading `(0.7568230, 0.6536199)`, centred at XZ
`(-248.64766, 2689.80420)`. Installed `Wall_Arch.gltf` supplies the two native-textured
frames, installed `Prop_Support.gltf` supplies crown depth braces, and the existing
`torch_prop.tscn` supplies the signal. Direct glTF buffer measurement found source arch
bounds `[-1,0,0]..[1,3,0.06404569]` and an aperture half-width of `0.8333333` with
minimum height `1.835863`. Scale `(4.8,8,4)` therefore retains a 9.6 m by 24 m
architectural face and opens a measured 8.0 m by 14.686904 m passage. The production
world AABB, including the signal, is 8.112762 by 26.329956 by 8.855713 m.

The four independently sampled masonry sockets and ten matching collision boxes cover
only the visible feet, frame posts and headers. The authored anchor remains open. The
nearest authored pickup-to-solid clearance is 6.584853 m. No pickup, actor, route,
progression, camera, terrain, time or lighting datum changes.

## Exact source scope

- `data/config/cloudreach_windscar_beacon_visual.json`
- `scripts/world/cloudreach_windscar_beacon_site.gd`
- `tests/test_cloudreach_windscar_beacon_site.gd`
- `tools/_capture_cloudreach_windscar_beacon_site.gd`
- one preload and `_build_windscar_beacon()` delegation in
  `scripts/world/cloudreach_world.gd`

Current source SHA-256 values:

- `cloudreach_world.gd`: `55A15721B96E4B389AC283CA3EE8D1E63AB0E1584DE53D52F6644945535572D3`
- site helper: `21BAFAB8F6A5E03CDBBB28DB3BE0F8125D211328C557E430A65B954ED11E5BDF`
- visual config: `3151C6E9AB17B1E5ABF2BA6949EA832F2A8C55F45E65E3AF6849928F3ACFDCFF`
- focused test: `6A621EA690FA7C98445A2FD52944959FA966CD380E7EC4E07B57ABA20157C27D`
- corrected capture helper: `DB965E1A83842B522BA0D113947A2E1E73DCE059E58F7B65049A2F0FFFBED733`

## Focused evidence

Two failed fixture shapes are retained rather than hidden:

1. `.artifacts/cloudreach-windscar-beacon-0909/focused` ran from
   `15:37:59.146Z` to `15:38:00.674Z` and exited 1. It attempted global-transform
   measurements off-tree, producing 21 `ERROR` lines and `2 tests / 1 failed`.
   Raw SHA-256: `2F3731125013059735D460E394D599319E8932166FEFFFBB0397E07B92B49575`.
2. `.artifacts/cloudreach-windscar-beacon-0909/focused-corrected` ran from
   `15:45:48.664Z` to `15:45:50.065Z`. Its apparent exit 0 is invalid evidence: the
   synchronous runner had no `SceneTree`, emitted one `SCRIPT ERROR` and one `WARNING`,
   and aborted the transform assertions. Raw SHA-256:
   `76D0DD96F0293AC4D97AA25C640522668170FAC89746F87D7DD0451C5FCBCBEC`.

The final deferred initialized-child run is retained under
`.artifacts/cloudreach-windscar-beacon-0909/focused-initialized-final`. It ran from
`15:48:58.432Z` to `15:49:01.340Z`, exited 0, and reported `2 tests / 25 child
assertions / 0 failed`. It contains no `ERROR`, `SCRIPT ERROR` or `WARNING` lines.
Raw SHA-256:
`33BC2C4B34C788B6C9E8CE0B4E5BF96419B3474396561D6A40CD6AE450C520A3`.

That run proves two installed frames, four finite terrain feet, ten solid colliders,
maximum support-contact delta `0.0000132256` m, the measured aperture and the 6.584853
m pickup clearance using initialized global transforms.

## Production capture and valid evidence

The authorized world run is under
`.artifacts/cloudreach-windscar-beacon-0909/world-capture`; frames and manifest are in
`shots/catalogue/cloudreach/round-windscar-open-beacon-20260909T1555Z`. It ran from
`2026-09-09T15:56:14.707Z` to `15:58:40.748Z` for 146.041 s. Peak system commit was
75.79%, peak process count 255, no guard fired, and Godot process count was zero at
lease release. The launcher serialized `exit_code:null`; the manifest and raw tool
finish are therefore the result authority.

The canonical day and night frames retain the exact stand 05 anchor, heading, 70-degree
FOV and production camera. Both record a grounded player at y `500.1302`. Their
projected site rectangles are approximately x `617.85..1310.13` and y
`-1815.84..617.89`: the central passage and installed uprights are visible, while the
24 m crown naturally crops from this near-base view. These frames are presentation
evidence only. They do not prove a walked route.

Production terrain-contact telemetry is valid independently of the failed route. All
four foundation bottoms measure y `499.6500122` against expected y `499.65`, a delta of
`0.00001221` m. Their radial distances from the authored anchor are 14.866 and 16.401
m; normalized against the actual 46 by 44 m elliptical ledge they are `0.651..0.736`,
inside the crown.

The manifest is correctly `complete:false`. The ordinary frame is a cliff face, its
player is not grounded, and the complete structure is outside the viewport. It is not
ordinary-view evidence. The reported first navigation arrival is also invalid: an
XZ-only result says `reached:true` while the player is airborne at y `-86.945`. Fall
recovery then sends the player near the realm entry and the through-aperture leg ends
at `(-279.374,180.028,540.374)`. No aperture traversal occurred.

Raw scan, keeping duplicated engine logging separate:

- `console.log`: 0 `ERROR`, 0 `SCRIPT ERROR`, 0 `WARNING`;
- `stderr.log`: 2 tool `ERROR` lines and 257 `WARNING` lines — one pre-existing
  Cloudreach surface warning and 256 runaway-velocity warnings caused by the failed
  falling route;
- `engine.log`: duplicates the same 2 errors and 257 warnings.

The retained frame hashes are:

- canonical day:
  `04CBFEA75716E4DAEC269A82FF060BF26CF19C379EFCA424C2ACC00309CF446A`;
- canonical night:
  `8099AF8110A512FEFA1292CF564ED9D7816A50E163FB9B541BE7599273B7E96A`;
- failed ordinary day:
  `736849914E82A4D7519892FB0EF6F78BAACB4B52DA73D72D813233AF529BAA34`;
- incomplete manifest:
  `9E531450744B432EBF48ED1ACF08BE1DF589DCF02F063BAC885B349F590540B4`.

## Failure mechanism and corrected proof route

The failed start `(-276,2696)` was selected from the authored pickup ring. That XZ is
inside the broad runtime surface rectangle (`half=(17,17)`), so `ground_height_at()`
can report y 500, but it is just outside the actual 46 by 44 m elliptical ledge:
`sqrt((16/23)^2+(16/22)^2)=1.006408`. The capture helper accepted that phantom ground,
waited, and the player fell down the cliff. An authored pickup XZ was therefore not
evidence of a walkable court.

A bounded proof correction requires no production geometry change. Starting from the
already verified grounded canonical anchor, ordinary input can first walk 12 m against
the retained heading to `(-269.081876,2672.156561)`. This point has elliptical norm
`0.532000` and is 27 m from the beacon centre. From there the player can face the full
silhouette, return through the anchor, and continue through the central aperture to
anchor plus heading times 19 m, `(-245.620363,2692.418778)`, whose elliptical norm is
`0.842334`. Any future helper must reject non-finite ground, ungrounded starts and
arrivals, or arrivals outside the crown height band before recording XZ success.

At the close of the first attempt that corrected route was a source-and-footprint plan,
not evidence from that run. The following authorized attempt executes it.

## Corrected final proof attempt

The authorized corrected run is retained under
`.artifacts/cloudreach-windscar-beacon-0909/world-capture-corrected`, with output in
`shots/catalogue/cloudreach/round-windscar-open-beacon-proof2-20260909T1620Z`. It ran
from `2026-09-09T16:12:48.595Z` to `16:14:59.069Z` for 130.474 s. Peak system commit
was 76.07%, peak process count 255, no guard fired, and Godot process count was zero at
lease release. As in the first run, the launcher serialized `exit_code:null`; the raw
tool finish and manifest are the result authority.

The helper starts from the verified grounded canonical anchor, then uses ordinary
stick input for every proof leg and rejects XZ-only arrival unless the player is also
on the floor and within 6 m of the y 500 crown band. All three legs passed with zero
confined resets:

- establish grounded approach: 11.496 m travelled, ending grounded at
  `(-268.7014,500.1309,2672.4866)`, 0.504 m from the intended inside-crown point;
- approach back to anchor: 10.996 m travelled, ending grounded at
  `(-260.4000,500.1309,2679.6528)`, 0.530 m from the anchor;
- through aperture: 19.153 m travelled, ending grounded at
  `(-245.9996,497.9271,2692.0864)`, 0.504 m from the intended far-side point.

This is valid production traversal evidence for the full aperture. The 2.073 m final
height delta is the actual crown relief and remains inside the explicit 6 m crown
band. Foundation contact again passed at `0.00001221` m.

The corrected ordinary frame is grounded and visibly contains the installed arch from
its grass-level feet through the complete architectural crown. The manifest still
correctly records `complete:false`, because `_visibility()` projects all eight corners
of one aggregate axis-aligned world AABB. Its rectangular volume includes empty corner
space created by the two thin rotated frames. The projected rectangle is x
`771.64..1150.54`, y `231.84..1006.17`, so one empty lower AABB corner falls below the
800 px viewport and triggers `ordinary view does not contain the complete signal
structure`. This is a conservative capture-assertion failure; it cannot be reported as
an automated full-bounds pass. The visible frame can be reviewed as image evidence,
and the separate telemetry above is the traversal proof.

The corrected raw logs contain one pre-existing Cloudreach no-surface `WARNING` and
one tool `ERROR` for that full-bounds assertion. There are no script errors, fall
recoveries or velocity-ceiling warnings. `engine.log` duplicates the same warning and
error; `console.log` is clean and records all three PNG saves plus the final failed
manifest status.

Corrected evidence SHA-256 values:

- canonical day:
  `E4A261BF8DEF70A12C923ED3C7203019A41E43F0EF866176F79A8CED3959D234`;
- canonical night:
  `C36BF5B3B66CAA59AFCF6AE16A1D9B8A59580C092451F6D1C90C85CA13FE8CCF`;
- grounded ordinary day:
  `E9CA401ADFCA95D8FFDB577BE9D5E25D2421BA1BEEC6E4BE64DF6A5522ABFE43`;
- incomplete corrected manifest:
  `A691E6CC6A92A4FF198C869E25D42FA16BF9B866635C898A9815FF434E449E6A`;
- corrected stderr:
  `CD2730F723C55065DC4E14CE1EB9CEFBD79FCBC0E11AE6BE35D62E4381962773`;
- corrected guard receipt:
  `6263913BCB06F19EC26CB7BC924019528E6D6DC81DACEA78FDFA8CFA4F65C4BC`.

No third run or further structural adjustment was made.
