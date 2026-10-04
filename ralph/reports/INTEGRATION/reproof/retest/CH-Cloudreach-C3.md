# CH-Cloudreach-C3 — Two-peer flight/realm, rejoin, reload; Solmane once, per participant

**Verdict: FAIL**

Shares its runs with F08 (code under test 826d273c3), as the action allowed:
- Solmane two-peer proof `f08_5_solmane_two_peer.json`: **PASS**, exit 0, 74 PASS. The host accepts with space and the guest refuses at five, each with its own receipt, with no re-offer after rejoin or a host restart. See F08-5.md and F08-5.two_peer.PROOF.md.
- `smoke_net_cloudreach_veyra_reconnect`: **FAIL**. It stops at step #18, a stale negative control (the Ila client route is no longer unfixed), so the Veyra reconnect/reload/no-double-grant steps never ran. See F08-2.md.

The card fails because its reconnect/reload half is not re-proven. The hypothesis is the stale negative control in the smoke, not the product (see F08-2.md).
