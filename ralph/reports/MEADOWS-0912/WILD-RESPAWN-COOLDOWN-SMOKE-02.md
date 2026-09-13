# Meadows wild-respawn cooldown — retained smoke 02

**OWNER-0912 Tier 0 #8 verdict: PASS.**

Run at commit `09b31bfb2` or later with Godot 4.7 stable, Windows headless:

```powershell
Godot_v4.7-stable_win64_console.exe --headless --path . --log-file ralph/reports/MEADOWS-0912/wild-respawn-cooldown-smoke-02.log --script tests/smoke_meadows_wild_respawn_cooldown_0912.gd
```

The production Meadows boot completed with exit code 0. The smoke cleared real actor
`Wild_bramblebun_1018_1`, streamed the cluster away and back, and proved the actor
remained absent through 299.75 seconds of the configured 300-second cooldown. At
300 seconds the same one-member cluster became available and the actor returned.

Receipt:

```text
{"actor":"Wild_bramblebun_1018_1","cluster_members":1,"configured_cooldown_seconds":300.0,"early_return_seconds_before_expiry":0.25,"final_available":true,"physical_engage_distance_m":3.2237491607666}
meadows wild respawn cooldown: OK -- a real cleared cluster stayed absent across streaming and the first 299.75s, then the same single actor returned at 300s.
```

This closes the retained rerun requirement for Tier 0 #8. It does not make claims
about other owner rows or the full Meadows campaign.
