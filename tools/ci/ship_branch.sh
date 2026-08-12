#!/usr/bin/env bash
# Ship one `ralph/**` branch to main, if and only if CI passed on the exact
# commit being shipped.
#
#   tools/ci/ship_branch.sh <branch> [<verified-sha>]
#
# Two callers, one implementation:
#
#   - `ralph-merge.yml` passes the sha CI just went green on. Event-driven,
#     immediate.
#   - `ralph-sweep.yml` passes no sha. The script then looks up whether the
#     branch tip has a green run of its own. Poll-driven, catches whatever the
#     events missed.
#
# It lives in a script rather than inline YAML because there are now two callers
# and this routine has already destroyed unmerged work once (see the delete step
# below). Two hand-maintained copies of it is not a risk worth taking.
#
# WHY A SWEEPER EXISTS AT ALL — the bug this file was extracted to fix.
#
# `ralph-merge.yml` triggers on `workflow_run: [CI] completed`. When main has
# moved under a branch it rebases, force-pushes, and dispatches CI with
# `gh workflow run`. The dispatch works and CI runs. But GitHub does not raise
# workflow events for runs initiated with the default GITHUB_TOKEN -- its
# recursion guard -- so when that dispatched run finishes, no `workflow_run`
# event fires and `ralph-merge.yml` never wakes up again. The branch sits
# green, rebased, tested and unmergeable, forever.
#
# Measured on 2026-08-11: every branch whose green run came from a `push`
# merged; every branch whose green run came from a `workflow_dispatch` was
# stranded. Four at once (`EV3`, `EV4-textures-remainder`, `EV9`, `LP3`), and
# `LP3` had burned six CI runs ping-ponging through the rebase path.
#
# This is the same guard that left `release.yml` unfired for twelve hours and
# twenty-five commits. Escaping it on the way IN (dispatch works) does not
# escape it on the way OUT (the completion event still does not fire). Twice
# bitten: the fix is to stop depending on an event arriving at all.
#
# Exit codes: 0 = handled (shipped, or deliberately not shipped).
#             1 = needs a human. Nothing was pushed.
set -uo pipefail

BRANCH="${1:?usage: ship_branch.sh <branch> [<verified-sha>]}"
SHA="${2:-}"

# How many times one branch may be rebased before we stop and say so.
#
# `ralph-merge.yml` shipped with no cap and a comment predicting this: "If a
# branch is ever seen rebasing more than two or three times, that assumption is
# wrong and this needs a cap." `LP3` reached six. The prediction was right, so
# here is the cap. Each rebase costs a full CI run, so an uncapped ping-pong
# burns the runner budget silently.
MAX_REBASES="${MAX_REBASES:-3}"

note()  { echo "::notice::$*"; }
warn()  { echo "::warning::$*"; }
fail()  { echo "::error::$*"; }

git config user.name  "ralph-bot"
git config user.email "ralph-bot@users.noreply.github.com"

if ! git fetch --quiet origin "$BRANCH"; then
  warn "$BRANCH no longer exists on the remote. Nothing to ship."
  exit 0
fi

# Re-fetch main and sit exactly on it before deciding anything. A job can wait
# minutes for its turn in the concurrency queue while earlier merges advance
# main, and every check below reads origin/main -- a stale ref would
# mis-classify a fast-forwardable branch as needing a rebase, and then "rebase"
# it onto a base it was already on.
#
# A scratch branch rather than `main` itself, because the sweeper calls this in
# a loop and the rebase path below leaves HEAD on the branch it rebased. Landing
# on a known ref every time makes each call independent of the last one.
git fetch --quiet origin main
git checkout --quiet -B __ship origin/main

TIP="$(git rev-parse "origin/$BRANCH")"

## Is there a completed, successful CI run for this exact commit?
##
## Used twice: the sweeper asks it to decide whether an un-merged branch has
## already earned its way to main, and the rebase path asks it to avoid
## re-testing a commit that has already passed. `EV3` was dispatched twice on
## the same sha because nothing checked.
green_run_for() {
  local sha="$1" count
  # --limit, because `gh run list` defaults to 20 and a branch that has been
  # rebased a few times burns runs quickly. The tip's own run must not fall out
  # of the window, or a green branch reads as never-tested and is left forever.
  count="$(gh run list --workflow=ci.yml --branch "$BRANCH" --limit 100 \
             --json headSha,status,conclusion \
             --jq "[.[] | select(.headSha == \"$sha\" and .status == \"completed\" and .conclusion == \"success\")] | length" \
           2>/dev/null)" || return 1
  [ "${count:-0}" -gt 0 ]
}

if [ -z "$SHA" ]; then
  # Sweeper mode. The branch tip has to have earned this on its own.
  SHA="$TIP"
  if ! green_run_for "$SHA"; then
    echo "$BRANCH: tip $SHA has no completed green CI run. Leaving it alone."
    exit 0
  fi
  note "$BRANCH: tip $SHA is green and was never merged. Shipping it."
else
  # Event mode. Verify the commit CI passed on is still the one we would ship:
  # workflow_run fires per run, and a branch can be pushed again while the run
  # is in flight. Shipping the newer, untested commit would defeat the gate.
  if [ "$TIP" != "$SHA" ]; then
    note "$BRANCH moved since CI ran ($SHA is no longer its tip). Not shipping; the newer commit gets its own run."
    exit 0
  fi
fi

if git merge-base --is-ancestor "$SHA" origin/main; then
  note "$SHA is already on main. Nothing to do."
  exit 0
fi

# main moved while CI ran. Under one writer this was rare and a firing rebased
# by hand. Under ~10 concurrent lanes it is the common case -- main moves during
# most 5-minute CI runs -- so rebase it here instead.
#
# This does NOT weaken the fast-forward guarantee:
#   - a CLEAN rebase resolves nothing ambiguous; that is what clean means. A
#     conflicting one still stops dead, below.
#   - the rebased commit is RE-TESTED before it can merge. Nothing reaches main
#     without a green run on the exact commit that lands.
if ! git merge-base --is-ancestor origin/main "$SHA"; then
  # Every rebase this script performs dispatches exactly one CI run, so the
  # count of dispatched runs IS the rebase count -- no extra state to keep.
  #
  # Counted SINCE THE BRANCH WAS LAST PUSHED BY ITS AUTHOR, not over all time.
  # Two reasons. A firing pushing new work is a fresh start and should not
  # inherit the previous round's attempts. And the branches alive when this cap
  # was written had already burned up to six dispatches each to the very bug
  # being fixed here -- an all-time count would permanently block exactly the
  # branches the fix is meant to rescue.
  # shellcheck disable=SC2016  # $all and $last are jq variables, not shell ones
  rebases="$(gh run list --workflow=ci.yml --branch "$BRANCH" --limit 100 \
               --json event,createdAt --jq '
                 . as $all
                 | ([$all[] | select(.event == "push") | .createdAt] | max) as $last
                 | [$all[] | select(.event == "workflow_dispatch"
                     and ($last == null or .createdAt > $last))] | length
               ' 2>/dev/null || echo 0)"
  if [ "${rebases:-0}" -ge "$MAX_REBASES" ]; then
    fail "$BRANCH has already been rebased ${rebases} times and still cannot fast-forward. Stopping rather than burning another CI run. A human or a firing has to land it. Nothing was pushed."
    exit 1
  fi

  note "main moved under $BRANCH. Rebasing it (attempt $((rebases + 1))/${MAX_REBASES})."

  git checkout --quiet -B "$BRANCH" "$SHA"
  if ! git rebase origin/main; then
    git rebase --abort || true
    # `git rebase --abort` leaves HEAD (and the whole working tree) sitting on
    # $BRANCH's OLD, pre-rebase tip -- whatever that branch looked like when it
    # was last synced with main. If it predates this very script being added to
    # the repo, THIS FILE disappears from the checkout along with everything
    # else main has gained since. `ralph-sweep.yml` calls this script in a loop
    # against one shared checkout, so that is not cosmetic: every branch after
    # this one in the same sweep then fails with "ship_branch.sh: No such file
    # or directory" and is silently never shipped -- caught for real on
    # 2026-08-11, where one conflicting branch (`EV3`) stranded six other
    # already-green branches (`SA2-flake` among them) behind it, sweep after
    # sweep, until this line existed. Land back on a scratch branch pinned to
    # `origin/main` -- guaranteed to contain every file main has, including
    # this one -- so a failure here costs only this branch, never the rest of
    # the loop.
    git checkout --quiet -B __ship origin/main
    fail "$BRANCH conflicts with main and cannot be rebased automatically. A human or a firing has to resolve it. Nothing was pushed."
    exit 1
  fi

  REBASED="$(git rev-parse HEAD)"

  # --force-with-lease, not --force: if the branch moved while we were
  # rebasing, the firing that moved it is still working and its commit must not
  # be discarded. Losing work here is unrecoverable from the remote.
  if ! git push --quiet --force-with-lease origin "$BRANCH"; then
    warn "$BRANCH moved while rebasing; leaving it alone. Its own CI run will drive the next attempt."
    exit 0
  fi

  # A rebase onto an unchanged main is deterministic, so this commit may already
  # have been built and tested by an earlier attempt. Re-testing it would be the
  # `EV3` double-dispatch. Ship it directly instead.
  if green_run_for "$REBASED"; then
    note "Rebased $BRANCH to $REBASED, which already has a green run. Shipping it without re-testing."
    git checkout --quiet -B __ship origin/main
    SHA="$REBASED"
  else
    # The push above CANNOT trigger CI (the GITHUB_TOKEN recursion guard
    # described at the top of this file), so dispatch explicitly. And because
    # the completion of THAT run cannot trigger ralph-merge.yml either,
    # `ralph-sweep.yml` is what actually lands it.
    if gh workflow run ci.yml --ref "$BRANCH"; then
      note "Rebased $BRANCH onto main and dispatched CI. The sweeper ships it when that run goes green."
    else
      warn "Rebased $BRANCH but could NOT dispatch CI. The sweeper will not ship it until someone re-runs CI on it."
    fi
    exit 0
  fi
fi

if ! git merge --quiet --ff-only "$SHA"; then
  fail "$BRANCH ($SHA) would not fast-forward onto main after all. Nothing was pushed."
  exit 1
fi
if ! git push --quiet origin HEAD:main; then
  warn "Lost the race pushing main for $BRANCH. The next sweep picks it up."
  exit 0
fi
note "Shipped $BRANCH ($SHA) to main."

# Only ever reached when main actually moved. The first version of this routine
# keyed the delete off step success instead, and deleted a branch it had just
# declined to ship -- `git push --delete` on unmerged work is unrecoverable from
# the remote. That is why every early return above exits BEFORE this point.
git push --quiet origin --delete "$BRANCH" || true

# `release.yml` triggers on push to main, and the push above cannot fire it --
# same GITHUB_TOKEN recursion guard. The loop went twelve hours and twenty-five
# commits believing otherwise, publishing nothing while the download link served
# whatever the last human merge had built.
#
# Not fatal: a failure to publish must not fail a merge that already happened.
if gh workflow run release.yml --ref main; then
  note "Dispatched Release for the new main."
else
  warn "Could not dispatch Release; run it by hand from the Actions tab."
fi
