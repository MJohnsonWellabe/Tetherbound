# Where the screenshots live

The four documents beside this one are the *written* record of the 2026-08-15
full blind playtest. The **visual** record — 267 screenshots, 223 MB — is not in
`main`. It is on the branch:

    claude/blind-playtest-planning-g371qr

under `playtest_evidence/2026-08-15_full_blind_test/`, alongside a `.gdignore`
so Godot never tries to import them.

## Do not delete that branch

It is the only copy. Everything else that branch carried (`BLIND_PLAYTEST_FINDINGS.md`,
`PLAYER_LOG.md`, `POST_BLIND_CORRECTIONS.md`, `FINAL_PLAYTEST_REPORT.md`) landed
on `main` and the branch is otherwise superseded — which makes it look exactly
like the ~40 other dead `ralph/*` and `scratch/*` branches that were cleaned up
on 2026-08-17. It is not one of them.

## Why they were left off `main` (OPS5, 2026-08-17)

Deliberate, and worth re-reading before anyone reverses it. `main`'s tree is
already ~1384 MB. These frames would add ~223 MB — a 16% permanent increase to
every clone, and `ci.yml` runs `actions/checkout` in **19 jobs per run**, so the
cost is paid on every push forever.

The frames are evidence for findings that are already written down and already
acted on. That is not worth a 16% tax on every CI job in perpetuity. If a future
playtest needs its frames in `main`, the answer is probably Git LFS or an
external bucket, not raw PNGs in the tree.

## If you ever need them

    git fetch origin claude/blind-playtest-planning-g371qr
    git checkout claude/blind-playtest-planning-g371qr -- playtest_evidence/

Read them, and do not commit them to `main`.
