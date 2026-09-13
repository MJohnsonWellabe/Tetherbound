# Meadows full-satchel pickups — retained smoke 02

**OWNER-0912 Tier 0 #11 verdict: PASS.**

Godot 4.7 stable booted the production Meadows scene and exited 0. The smoke
exercised both a world cache (`elixir_might`) and a band pickup (`good_candy`).
While the satchel was full, each pickup remained in the world, inventory stayed
unchanged, and the live HUD showed `Satchel is full.` at effective alpha 1.0.
After one slot was recovered, each same pickup collected successfully.

Command:

```powershell
Godot_v4.7-stable_win64_console.exe --headless --path . --log-file ralph/reports/MEADOWS-0912/inventory-full-pickups-smoke-02.log --script tests/smoke_meadows_inventory_full_pickups_0912.gd
```

Final receipt:

```text
meadows inventory-full pickups: OK -- world and band finds stayed put with clear full-satchel feedback, then collected after one slot was recovered.
```

The earlier `inventory-full-pickups-smoke-01.log` attempt is invalid: it was
interrupted after a concurrent shared-file edit exposed incomplete syntax. This
fresh run began only after the riding lane supplied a parse-stable commit.
