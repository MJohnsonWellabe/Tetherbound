# Minimap fog texture lifecycle 01

## Observed production failure

The first real two-peer Cloudreach split-realm run passed its functional cover
assertions but peer 0 logged two copies of:

```text
ERROR: The new image dimensions must match the texture size.
```

Both came from `ImageTexture.update()` in
`scripts/ui/minimap.gd::_rebuild_fog()` while a Cloudreach simulation shell
mounted and the local host remained in the Meadows.

The transition can legitimately replace the bound map and fog grid. The HUD
may first seed the minimap from the current Meadows scene and `Game.map`; the
Cloudreach runtime then explicitly configures it with the shell's Cloudreach
`MapState`. Meadows measures 512×2048 cells and Cloudreach 400×813. The old
code built a new correctly sized `Image` but unconditionally uploaded it with
`ImageTexture.update()` into the previous Meadows allocation. Godot requires
the update image to match the texture's size, format and mipmap state. This was
a GPU texture lifecycle defect; the trace does not show a persistent foreign
realm binding after Cloudreach's explicit configure call.

## Minimal correction

`minimap.gd` now caches the texture allocation descriptor. It keeps the
allocation-free `update()` path while size, format and mipmap state match, and
recreates the `ImageTexture` when any descriptor field changes. The focused
smoke uses real Meadows and Cloudreach `MapState` implementations and checks
map identity, cross-grid recreation, same-grid texture reuse, and a return to
Meadows. It does not use source-string assertions.

Current source hashes at the focused pass are:

- `scripts/ui/minimap.gd`: `758E55D531FF5ABF822530AAF8EF701859FDD1020ED6A2BE9A6593C5DB30F181`
- `tests/smoke_minimap_fog_texture_lifecycle.gd`: `9CBC20A3EB5B291CD2E73AACB76371E1D054A0A1F91552E35A2DA763FCB7AFE9`

## Focused negative and positive controls

The retained old-source control
`minimap-fog-lifecycle-control-first` ran from 2026-09-10
09:02:01–09:02:04 UTC and exited 1. It produced the two engine texture-size
errors plus two consequent assertions: the Cloudreach upload retained the
Meadows allocation and failed to recreate for the different real grid.

`minimap-fog-lifecycle-candidate-first` ran the same actual-map smoke from
09:02:14–09:02:19 UTC, exited 0, and recorded `errors: []` with
`meadows=(512, 2048)`, `cloudreach=(400, 813)`, and zero failures. The actual
runtime case proves the size-change branch and the stable-grid reuse branch;
format/mipmap comparison is guarded in code but was not independently forced
by this fixture.

## Two-peer integration receipt

`cloud-live-cover-net-second` ran `tests/smoke_net_split_realms.gd` from
09:11:29–09:15:07 UTC, exited 0, and passed all checks. A peer crossed from
Meadows into a real visible Cloudreach world while the host built a Cloudreach
simulation shell; the peers then exchanged realms. Real Cloudreach cover was
1,048,134 grass instances, 13,342 flowers and 778 bushes on each visible-world
side, while the simulation shell retained zero decorative cover.

Both peer logs contain zero `ImageTexture` dimension errors. Peer 1 contains
zero errors. Peer 0 is not globally error-free: it still contains the two
known unique departure-sync missing-node/cache error classes among a verbose
304 error lines. Those are outside this texture lifecycle change. The
integration receipt therefore proves removal of the specific minimap resize
error across the real realm transition; it does not certify the entire peer
log clean.

## Status

The focused negative control reproduces the old defect, the focused positive
control passes on the two real fog dimensions, and the subsequent two-peer
realm transition contains no recurrence of the ImageTexture size error. The
bounded lifecycle correction is retained.
