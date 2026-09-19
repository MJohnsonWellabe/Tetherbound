# D95 — Transport is Godot ENet on a listen server, with two channels

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

Godot's built-in high-level multiplayer over `ENetMultiplayerPeer`: the hosting player's process
is the server, up to three clients join by direct IP or a LAN beacon (`PacketPeerUDP`). Two ENet
channels: one for ledger and encounter traffic, one for snapshots, so a late-join snapshot never
queues behind movement. Port, peer cap (4), timeouts and the downed window live in
`data/config/multiplayer.json`. No Steam, no relay, no dedicated server, no host migration in
this pass (directive rules 11–12).

## Why

The directive (§6) accepts LAN/direct-IP for the first pass. ENet needs no addon, no external
service, and runs headless, which is what lets every net smoke run in CI. A relay transport can be
added behind the same `Session` API later without touching gameplay code.

## Constrains

`scripts/net/session.gd` (lane 2.A) owns the peer, the channels and the registry; nothing else
calls `multiplayer.` directly except synchronizers and spawners configured by their lanes.
