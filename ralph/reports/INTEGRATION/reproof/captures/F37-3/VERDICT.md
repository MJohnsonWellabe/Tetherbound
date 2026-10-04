# F37#3 — Old Ripplet Teleport promise removed from docs and UI (re-scan on main)

- Commit under test: **a0f9e50b3** (origin/main after PR #526). Earlier scan on 826d273c3: VERDICT_826d273c3.md (FAIL, one residual cell).
- Method: formal static scan with `git grep` against `origin/main` (no frames, no renderer)

## Commands

```
git grep -niE "ripplet[^.]{0,120}teleport|teleport[^.]{0,120}ripplet" origin/main -- docs data scripts/ui
git grep -n "^| S4" origin/main -- docs/ACCEPTANCE.md
git show origin/main:docs/ACCEPTANCE.md | grep -ci "fly/teleport"          # -> 0
git grep -niI "teleport" origin/main -- data scripts/ui                     # reviewed every hit
git grep -niI "ripplet" origin/main -- scripts/ui | grep -i "teleport|warp|blink"   # -> none
```

## Hits on a0f9e50b3

| Location | Disposition |
|---|---|
| docs/ACCEPTANCE.md:45 (S4 status) | Now reads "substantial traversal built; starter Fly, Ripplet swim/dive (RD-32) and no-hold climb integration incomplete." **Residual fixed.** |
| docs/ACCEPTANCE.md:33 | "S4's Ripplet Teleport promise is replaced by Ripplet swim/dive (RD-32)" — removal notice. OK. |
| docs/ACCEPTANCE.md:176 | F37 (3) criterion text. OK. |
| docs/TECHNICAL.md:37, :97 | "Ripplet Teleport dropped" / "dropped with Teleport (RD-32)" — removal notices. OK. |
| docs/design/SYSTEMS.md:183 | "world-map teleport-anywhere" out of scope; no Ripplet teleport. OK. |
| data/creatures/species.json:35, :389, :520 | Developer comments citing the archived spec filename `C1_RIDEABLE_ROSTER_FLY_TELEPORT.md` for Burrowback/Terrapup/Tuskroot riding. Not player-facing, no Ripplet teleport behaviour. Informational. |
| scripts/ui/tab_settings.gd (many lines) | Debug-teleport settings list (development scaffolding). Unrelated to Ripplet. OK. |
| other data/ hits | "no teleport"/anti-teleport accounting/position comments. OK. |

No Ripplet Teleport ability, move, anchor, cooldown, tooltip or promise remains in docs/, data/ or scripts/ui/.

## Verdict: PASS (on a0f9e50b3)
