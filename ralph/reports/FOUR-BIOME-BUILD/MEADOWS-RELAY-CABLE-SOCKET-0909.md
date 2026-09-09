# Meadows Relay cable socket — 2026-09-09

## Verdict at source freeze

The Wave14 source-blind apparatus finding is an actual geometry defect. The
cube-like cyan endpoint in `shots/locations/06-relay-apparatus-day.png` was not
connected to the installed apparatus or to the platform. This candidate now
adds a visible, non-colliding stone stanchion from the unchanged platform to
each of the three existing socket brackets. Initialized component geometry is
green. One guarded, exact-camera static production capture shows the formerly
floating bracket visibly connected to the deck. That evidence is sufficient
only for the narrow socket-attachment visual question; independent image review
and shipping acceptance remain with root.

The older relay gate candidate and its two failed airborne/reset route attempts
remain frozen and failed. None of the gate, platform, terrain, route, or
collision code was changed in this cable-socket lane.

## Source attribution

`tether_relay.gd::_build_cable_links` put every cable landing at the fallback
apparatus radius 3.4 and at `deck_y + height*0.5`: y10.0 + 2.1 = y12.1.
`_build_cable_socket` then placed a 0.5 x 0.55 x 0.4 stone box only 0.18m
inward from that point. It built no support to the deck and did not measure or
intersect `relay_apparatus.glb`. The radius describes fallback massing and does
not guarantee that the generated hero mesh has a surface at y12.1. A sky gap
was therefore possible by construction and is visible in the retained frame.

The three existing landing points are:

| Run | Landing `(x,y,z)` | Nearest support edge margin inside 10x10 deck |
| --- | --- | --- |
| west | `(4.4045, 12.1, -11.1962)` | 2.2645m |
| east | `(10.4, 12.1, -9.0)` | 1.46m |
| south | `(6.5506, 12.1, -12.3702)` | 1.4898m |

These positions show that a vertical support can meet the known deck without
moving the endpoint or altering the platform.

## Bounded change

- `scripts/world/tether_relay.gd`, cable-link/socket section only: the existing
  socket bracket is now built with a 0.28m square weathered-stone stanchion.
  The support bottom is exactly deck y10.0 and its top overlaps the bracket
  underside by 0.08m. The existing cyan cap and cable landing are unchanged.
- `data/config/tether_relay.json`, `cable_links` only: owns support width,
  depth, and overlap values.
- `tools/_probe_relay_cable_socket_geometry.gd`: deferred initialized
  SceneTree proof that instantiates the same production mount builder.

The support and bracket are `MeshInstance3D` nodes. No `CollisionObject3D` is
created, so player movement and platform collision are unchanged. Both meshes
use the existing relay weathered-stone material; the live cap still uses the
existing conduit material identity.

## Focused initialized proof

Command:

```powershell
C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe `
  --headless --path C:\Projects\Tetherbound `
  --script res://tools/_probe_relay_cable_socket_geometry.gd
```

Current result: **23 assertions, 0 failed**, exit 0. The probe attaches a
translated and yaw-rotated fixture to the live SceneTree, waits one frame, and
then verifies the actual support/bracket nodes in global space for all three
runs:

- support bottom equals the transformed deck plane;
- support top overlaps the actual bracket underside by exactly the configured
  0.08m;
- support and bracket bounds overlap in global XZ;
- support is centered under the bracket;
- support footprint stays inside the unchanged deck;
- support adds no collision.

No Godot process existed before or after either tiny component invocation.
The initial component output is retained under
`.artifacts/relay-cable-socket-geometry-20260909/`; after the wording
clarification to make 0.08m the exact bracket-underside overlap, the current
source was rerun under `.artifacts/relay-cable-socket-geometry-20260909-r2/`.

## Guarded matched production capture

Root granted one static matched capture after source/component review. The run
used the mature `tools/_capture_locations.gd --only=06-relay` lifecycle under
the mandatory external guard, Compatibility/OpenGL3 on the NVIDIA RTX 3050 at
1280x800. It started `2026-09-09T16:58:00.5548574Z` and ended
`2026-09-09T16:59:11.2582223Z`; launcher PID 6656 owned PIDs
`[6656, 2228, 9632]`. Exit code was 0, stop reason was empty, and zero Godot
processes remained. Across 27 samples, peak system commit was 80.21%, peak
system process count 260, peak owned private bytes 5,982,703,616 and peak owned
working set 2,266,058,752. The 600-second, 90%-commit and 400-process limits did
not fire.

The tool wrote four day frames with zero failures. It retained the same three
known analytic-fallback warnings under the exterior approach seats `(339,3777)`,
`(336,3780)` and `(342,3772)`. The apparatus shot and the other two shots did
not report missing collision. All camera-player distances were 3.6–7.5m.

In the exact apparatus camera, the before frame shows sky continuously below
and to the sides of the dark socket block. The matched after frame shows a
weathered-stone vertical member continuing from that block down to the raised
deck edge. The cyan cap and sagged cable remain readable and unchanged. This is
the intended narrow improvement. The other frames retain relay context and do
not show a platform redesign.

Before and after frames were copied into immutable, distinct evidence folders
around the run:

- `.artifacts/meadows-relay-cable-socket-0909/static-capture/baseline/`
- `.artifacts/meadows-relay-cable-socket-0909/static-capture/after/`

| Frame | Baseline SHA-256 | After SHA-256 |
| --- | --- | --- |
| approach | `3F054B325A0AACE6D5E64BD58F2586EA5B864D95D416F8C968AA5230E2281C9B` | `8B87F3289E78338CCED3DB51B7ABD2FCC702B525B00B8CAD51E94035FA05914A` |
| standing | `5B02D6DF24930759A31E88D09DFD9A08E169EB822B0DFB53EFD47732A804FDBB` | `0B1033391842042C968552737DB2EAD4CE0836AF0B56E5F5D84E06EDCBA6F9BB` |
| apparatus | `82D547031C6100BCA75DB68ABC05F2FF82D9FF1D9C3EF92B1D29571A736EE235` | `438FD03E1219E5494EED3B7965E1B1E11B3772F2A483E2E4250A5A50C7D3C3A8` |
| road | `8955C2769EA839A9A84149465930003D511B6082DB4D408A440CA99A7D300415` | `68AA178CE1A83845F7644FD9DE60263FDCF33F11D596B897959E130BC36163F0` |

This static tool teleports among authored viewpoints. Because the socket delta
adds no collision and component proof establishes actual contact, root selected
it for narrow appearance evidence only. It is not traversal evidence. The held
gate's airborne/reset attempts remain failed; these images cannot accept gate
passage, ramp/deck traversal, or head clearance. A shipping patch for this lane
must exclude the held gate candidate.

## Evidence and hashes

| Artifact | SHA-256 |
| --- | --- |
| `scripts/world/tether_relay.gd` | `056B4DE878540AB4290CCDFE05601C0687C18E53044F220CE4DAC6342F49DA4E` |
| `data/config/tether_relay.json` | `0182EF4B613A5889AF11E97FD8216BA380AB5DF33A05BD62CB6B6836D56157CC` |
| `tools/_probe_relay_cable_socket_geometry.gd` | `8B9ECC77B17C5DC815197E7D813FD391A7EBCDAB172F74B89E19D92101DC25BD` |
| current r2 `engine.log` | `907F63AD701184F10D3CD2229E25248824FFE350BDEF7ECDD1C6B189BC327207` |
| current r2 `stdout-stderr.log` | `C2F9E47F95E2073C4745E604F633C33C28325BC3C0BF05A3C0E1C55209D9CB6F` |
| preserved source-blind `static-capture/baseline/06-relay-apparatus-day.png` | `82D547031C6100BCA75DB68ABC05F2FF82D9FF1D9C3EF92B1D29571A736EE235` |

The last row above identifies the preserved baseline copy. The mutable
`shots/locations/06-relay-apparatus-day.png` now contains the after image with
SHA-256 `438FD03E1219E5494EED3B7965E1B1E11B3772F2A483E2E4250A5A50C7D3C3A8`.

Guard receipt and raw diagnostics:

| Artifact | SHA-256 |
| --- | --- |
| `static-capture/result.json` | `00AA2362FB132D6181884969539D6DE74C2E270D426C404EF0C751D84F501442` |
| `static-capture/console.log` | `0EA499B4D29C9018EB0697ABA54C35F150A69E09602A7182C78185A568AF4ED3` |
| `static-capture/stderr.log` | `3FA19C076B651705F3B1EA77F9E24B6531FC54EA926A9A081251959FB5E36E88` |
| `static-capture/engine.log` | `F418CB62E8D885BA4AD2CB04FE7924E1492A2191AECEED3AC8CAFEC6264E783C` |
| `static-capture/resources.csv` | `CC1F0CA43B0BCFC3B97AE85F321970FD46CA211FC68B09F5F05C416129FF2454` |
| `static-capture/run.ps1` | `BCFCDAFD9B1444461A7C610CA42B7F1A2E4874BCD48927AD04FBE28DD1252546` |

Raw current component evidence:

- `.artifacts/relay-cable-socket-geometry-20260909-r2/engine.log`
- `.artifacts/relay-cable-socket-geometry-20260909-r2/stdout-stderr.log`

Neutral exact-camera pair for independent image-only critique:

- before: `.artifacts/meadows-relay-cable-socket-0909/static-capture/baseline/06-relay-apparatus-day.png`
- after: `.artifacts/meadows-relay-cable-socket-0909/static-capture/after/06-relay-apparatus-day.png`
