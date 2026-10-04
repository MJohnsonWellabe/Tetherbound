# F37#3 — Old Ripplet Teleport promise removed from docs and UI

- Commit under test: 826d273c3 (origin/tb/integration)
- Method: formal static scan (no frames; no renderer involved)
- Criterion (ACCEPTANCE F37 (3)): "The old Ripplet Teleport promise is removed from docs and UI."

## Commands

```
grep -rniE "ripplet[^.]{0,120}teleport|teleport[^.]{0,120}ripplet" docs data scripts/ui
grep -rniI "teleport" data scripts/ui
for f in $(grep -rliI teleport docs); do grep -qi ripplet $f && grep -noiI ".{0,110}teleport.{0,110}" $f; done
grep -rniI "attune|ripplet.{0,60}(warp|blink|anchor)" data scripts/ui
```

## Hits

| Location | Text | Disposition |
|---|---|---|
| docs/ACCEPTANCE.md:45 (S4 row, status column) | "substantial traversal built; starter Fly/Teleport and no-hold climb integration incomplete." | **Residual promise.** Still lists starter (Ripplet) Teleport as pending integration work. Line 33 of the same file says S4's Ripplet Teleport promise is replaced by swim/dive (RD-32), but this cell was not updated. |
| docs/ACCEPTANCE.md:33 | "S4's Ripplet Teleport promise is replaced by Ripplet swim/dive (RD-32)." | Removal notice, not a promise. OK. |
| docs/ACCEPTANCE.md:176 | F37 (3) criterion text itself | OK. |
| docs/TECHNICAL.md:37 | "planned Ripplet surface swim and L30 Dive (RD-32, F37; Ripplet Teleport dropped)" | Removal notice. OK. |
| docs/TECHNICAL.md:97 | "Ripplet's attuned anchor/cooldown is dropped with Teleport (RD-32)." | Removal notice. OK. |
| data/creatures/species.json:35, :389, :520 | `_comment_rideable` cites the archived spec filename `C1_RIDEABLE_ROSTER_FLY_TELEPORT.md` (now under archive/docs/specs-2026-09-19/) | JSON developer comment on Burrowback/Terrapup/Tuskroot riding; cites a filename only, no Ripplet teleport behaviour. Not player-facing. Informational. |
| scripts/ui/* | Only debug-teleport settings list (tab_settings/tab_map/craft_panel comments) | Development scaffolding, unrelated to Ripplet. OK. |
| data/config/menu.json:116-117 | "Debug teleport" settings label | Debug setting, unrelated to Ripplet. OK. |

Other `teleport` hits in docs/design (SYSTEMS, WORLD, MULTIPLAYER, AUDIO, CREATURES, UX, COMBAT) and STATE are "no teleport-anywhere", anti-teleport accounting, debug-relocation or harness-teleport rules; none attributes Teleport to Ripplet.

No Ripplet Teleport ability, move, anchor, cooldown or tooltip exists in `data/` or `scripts/ui/`.

## Verdict: FAIL (one residual docs hit)

UI and data are clean. One docs cell still carries the promise: `docs/ACCEPTANCE.md:45` S4 status "starter Fly/Teleport ... integration incomplete". Fix for the owning lane: change that cell to swim/dive (RD-32) wording. Optional hygiene: the species.json comments cite an archived spec whose filename contains TELEPORT.

Replaces: no prior formal scan recorded for F37#3.
