# Branch supersession and deletion list, recorded 2026-08-23

Branch deletion remains blocked from Claude sessions at the credential
level: `git push origin --delete` returns HTTP 403, and the GitHub MCP
server exposes no delete-branch tool. Same state as the 2026-08-22 report.
Whoever holds owner credentials (owner directly, or ChatGPT connected with
the owner's GitHub auth) should run the commands below.

All containment claims were verified with `git merge-base --is-ancestor`
against `origin/main` (05bbc48a) and `origin/ralph/integration-D`
(tip as of 2026-08-23, ~34 min before this check) after a full
`git fetch --prune`.

## Phase 0a — safe to delete NOW

- `claude/gates-abc-verification-ne0rwx` — fully contained in `main`.
- `ralph/render-invocation` — tip commit `eb77d5f4` is byte-identical to
  the tip of `claude/ralph-multi-gate-coord-4lkb0n`; an exact duplicate
  ref. The claude/ branch is kept as the survivor.

```
git push origin --delete claude/gates-abc-verification-ne0rwx
git push origin --delete ralph/render-invocation
```

## Phase 0b — delete ONLY AFTER integration-D (+ D1 + D2) lands on main

Each of these is a verified ancestor of `ralph/integration-D`. They carry
nothing that branch does not. Once integration-D's content is actually on
`origin/main` (check `git log origin/main`, not bookkeeping or CI badges),
re-run `git merge-base --is-ancestor origin/<branch> origin/main` per
branch and delete on confirmation:

```
git push origin --delete claude/d3-setup-kf3tcf
git push origin --delete claude/gate-d-meadows-regions-x68est
git push origin --delete claude/start-d4-j5v3ax
git push origin --delete claude/start-d5-abf6zi
git push origin --delete ralph/gate-d-band3-river-relay
git push origin --delete ralph/gate-d-band4-upper-meadows
git push origin --delete ralph/gate-d-band5-stronghold-approach
git push origin --delete ralph/gate-d-wild-streaming
```

The D1/D2 lanes (`claude/start-d1-odnxb2`, `claude/start-d2-tqigvx`,
`ralph/gate-d-band1-lower-meadows`, `ralph/gate-d-band2-quarry-warrens`)
and `ralph/integration-D` itself join this list only after their work
lands; each has 5–10 commits not yet in integration-D as of this writing.

## Kept — carry unmerged unique work (as of 2026-08-23)

| branch | unique commits vs integration-D | note |
|---|---|---|
| `claude/gate-a-core-verbs-8aaw7g` | 5 | Gate A build-segment work |
| `claude/ralph-multi-gate-coord-4lkb0n` | 5 | survivor of the render-invocation duplicate pair |
| `ralph/HUD-EMPHASIS` | 6 | likely superseded by integration lineage; needs per-commit check before deletion |
| `ralph/integration-2` | 14 | scatter re-bake vs merged vegetation config; check supersession |
| `chatgpt/owner-playtest-2026-08-21` | 2 | owner-evidence lineage |
| `scratch/render-catchup` | 1 | render-diagnostic instrumentation |
| `ralph/branch-supersession-cleanup` | 1 | one doc commit (`ralph/reports/SUPERSESSION-2026-08-22.md`); merge that file to main, then delete |
| `ralph-status` | n/a | separate 980-commit status lineage; intentional, keep |

The six branches indexed in `SUPERSESSION-2026-08-22.md` (TOURNAMENT-1/2,
HUD-GLYPHS/LAYOUT/POPUP, WEATHER-LIGHT, DPAD-COLLISION) are confirmed
already deleted from the remote.
