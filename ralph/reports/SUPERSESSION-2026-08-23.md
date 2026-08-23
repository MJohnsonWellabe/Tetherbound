# Branch supersession and deletion list, recorded 2026-08-23

**Updated after the full D landing on `main` (b923e202).** The earlier
revision of this file split deletions into now/later; the "later"
condition has been met, so this is now a single list.

**Second update, same day, after `integration-W1` landed (main now past
`1adfeacb`).** Re-verified against the new tip: `STRANDED-P3` and
`ralph/gate-d-wild-streaming` are now fully contained by ancestry (their
own tips are reachable from `main`); `ralph/GATE-E-LOGIC`'s tip commit
(`631989e6`) is patch-equivalent to `main`'s `653f4cdc` — it was rebased
after `main` already absorbed its content via `integration-W1`, so the two
differ only in hash. `claude/gate-a-core-verbs-8aaw7g` moves from "keep"
to "deletable": `STRANDED-P3` already reconciled both items it carried
(the chop clip landed under a fresh hash — `main`'s `0aa790c4` — and the
CI-wiring gap is now tracked precisely in `BACKLOG.md`'s `CI-COVERAGE-1`
entry, which supersedes this branch's own version of that same list).
`chatgpt/owner-playtest-2026-08-21` also moves to deletable: verified its
`ralph/OWNER_PLAYTEST_2026-08-21.md` content is the same file already on
`main` (landed via PR #19, `a2818217`), just a different commit lineage.
Four also-green `ralph/*` branches (`BAND2-FLOOR`, `SITE-DRESSING`,
`SITE-SHOTS`, `CREATURE-PRESENTATION`) were rebased onto this newer `main`
and re-pushed this pass — not yet in this list pending their fresh CI.

Branch deletion remains blocked from Claude sessions at the credential
level: `git push origin --delete` returns HTTP 403, and the GitHub MCP
server exposes no delete-branch tool. Whoever holds owner credentials
(owner directly, or ChatGPT connected with the owner's GitHub auth)
should run the commands below.

Verification method: `git merge-base --is-ancestor origin/<branch>
origin/main` for containment, and `git cherry origin/main origin/<branch>`
(patch-equivalence) for branches whose commits landed under different
hashes. Both run against `origin/main` at b923e202 after
`git fetch --prune`.

## Safe to delete — content fully on main

Contained by ancestry:

```
git push origin --delete claude/gates-abc-verification-ne0rwx
git push origin --delete claude/d3-setup-kf3tcf
git push origin --delete claude/gate-d-meadows-regions-x68est
git push origin --delete claude/start-d1-odnxb2
git push origin --delete claude/start-d2-tqigvx
git push origin --delete claude/start-d4-j5v3ax
git push origin --delete claude/start-d5-abf6zi
git push origin --delete ralph/gate-d-band1-lower-meadows
git push origin --delete ralph/gate-d-band2-quarry-warrens
git push origin --delete ralph/gate-d-band3-river-relay
git push origin --delete ralph/gate-d-band4-upper-meadows
git push origin --delete ralph/gate-d-band5-stronghold-approach
git push origin --delete ralph/gate-d-wild-streaming
git push origin --delete ralph/STRANDED-P3
git push origin --delete claude/gate-a-core-verbs-8aaw7g
git push origin --delete chatgpt/owner-playtest-2026-08-21
```

Patch-equivalent (every commit's diff already on main under a different
hash — `git cherry` reports zero unique patches):

```
git push origin --delete ralph/HUD-EMPHASIS
git push origin --delete ralph/integration-2
git push origin --delete ralph/GATE-E-LOGIC
```

Duplicate ref (tip identical to `claude/ralph-multi-gate-coord-4lkb0n`):

```
git push origin --delete ralph/render-invocation
```

## Keep for now — genuinely unique content

| branch | unique patches vs main | what it is |
|---|---|---|
| `claude/ralph-multi-gate-coord-4lkb0n` | 1 | the `--headless` render-hang record/diagnosis correction (doc). Land or fold into assessment notes, then delete. |
| `scratch/render-catchup` | 1 | render-diagnostic/timing instrumentation for the capture tools; relevant to the known capture-artefact remainder. Keep until the capture-tooling pass. |
| `ralph-status` | separate lineage | coordinator heartbeat branch; intentional, keep. |
| `claude/game-assessment-cleanup-g6gplm` | this branch | active assessment/cleanup session. |

The six branches indexed in `SUPERSESSION-2026-08-22.md` and
`ralph/integration-D` / `ralph/branch-supersession-cleanup` are confirmed
already deleted from the remote.
