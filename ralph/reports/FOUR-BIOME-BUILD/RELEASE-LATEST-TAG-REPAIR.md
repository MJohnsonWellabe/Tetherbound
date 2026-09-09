# Rolling `latest` release-tag identity repair

Date: 2026-09-09. This is an implementation and local mock-test report. It does
not mutate a live GitHub ref or claim post-landing release verification.

## Defect and preserved evidence

Release run `34308309474` completed successfully for exact main
`49da91d51953fb4b650f29b1399ae41218f68f86` and published new release asset
`551927103`, while `refs/tags/latest` still resolved to
`a8423f00fc0245af166222383b9c24dc7beb603e`. The existing
`softprops/action-gh-release@v2` step supplied `tag_name: latest`, which updates
the release asset and body but did not explicitly move the already-existing Git
ref. The prior mismatched run and ref receipts remain evidence; no workflow was
rerun and the live tag was not changed manually during this repair.

## Repair

`.github/workflows/release.yml` keeps its serial `release` concurrency group,
prerelease behavior, release name and stable by-tag download URL. It now:

1. supplies `target_commitish: ${{ github.sha }}` to the publishing action so a
   first-time release is created against the workflow's exact commit;
2. after the asset publish succeeds, runs `tools/release_latest_tag.mjs` with
   the workflow token;
3. reads `/git/ref/tags/latest`, force-updates the existing ref through
   `/git/refs/tags/latest` or creates the missing `refs/tags/latest` through
   `/git/refs`;
4. reads the ref back and fails the job unless both the returned ref name is
   exactly `refs/tags/latest` and its object SHA equals `GITHUB_SHA`.

The helper accepts no tag/ref argument. Its only ref name and API paths are
constants for literal `refs/tags/latest`; it cannot move a branch or a named
version tag. Repository and target SHA come from the standard workflow
environment and are validated before any request. Non-404 read failures,
mutation failures, malformed responses and final mismatches are terminal.

The ordering is deliberate: the ref is moved only after the release action has
successfully published the new archive. A failed export, package, runtime check
or asset upload therefore cannot advance the stable tag.

## Local validation

No test contacted GitHub or wrote external state.

`node --test tests/test_release_latest_tag.mjs` passed all four required cases:

- existing stale tag → `PATCH` with exact target SHA and `force: true`, then
  successful GET read-back;
- missing tag → `POST` with literal `refs/tags/latest`, then successful GET
  read-back;
- unexpected API error → terminal failure with no mutation request;
- read-back SHA mismatch → terminal failure.

`node --check` passed for the helper and test. `git diff --check` passed for the
workflow, helper and test. The workflow edit is limited to `target_commitish`
and the post-publish move/verification step; release concurrency remains
`cancel-in-progress: false`.

## Required landing verification

Root will land this change through the next pull request. The next release run
must be checked at its exact workflow SHA, and the live API read-back must show
`refs/tags/latest` equal to that SHA after asset publication. Until that happens,
the repair is locally proven but not live-proven, and the current stale-ref
receipt remains authoritative.
