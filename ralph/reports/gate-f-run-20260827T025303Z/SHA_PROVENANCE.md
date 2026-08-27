# The `sha` field in this run's telemetry is NOT the candidate SHA

**Read this before trusting the `sha` field on any event in this run.**

## What happens

`tools/gate_f/run_segment.sh` stamps every segment with `git rev-parse HEAD`
*at the moment that segment launches*:

```
SHA="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
```

The run commits evidence **per segment** — that is the protocol's own durability
rule, so a container reclaim costs one segment rather than the whole run. So HEAD
advances between segments, and each segment therefore stamps a **different** SHA,
none of which is the candidate.

| | SHA recorded |
|---|---|
| **candidate (the thing under test)** | `f082bdf6265760ca9835e1065361fbbf87475d69` |
| `overhead` | `f082bdf6` (ran before the first evidence commit) |
| `S01` | `c9f23a31` (the freeze commit) |
| `S02` onward | drifts with each evidence commit |

## Why the evidence is still sound

**Every commit between the candidate and any segment's stamped SHA touches only
`ralph/reports/`.** Verified mechanically, not asserted:

```
$ git diff --name-only f082bdf6..HEAD | grep -v '^ralph/reports/'
(no output)
```

No game code, data, config, scene, asset, shader or test differs between the
candidate and any segment's recorded SHA. The build that produced every
observation in this run **is** `f082bdf6`. Re-run any segment at the candidate
and you are running identical game bytes.

## Why it was not fixed

`tools/gate_f/**` is **FROZEN** for the operator role. The standing rule allows
exactly one exception — a single genuinely blocking error — and this is not
blocking: it mislabels evidence that is otherwise correct, and the mislabelling is
fully recoverable from this file plus `git log`. Changing `run_segment.sh` to pin
a candidate SHA is a legitimate improvement and belongs to whoever next holds the
harness outside a run, not to the operator during one (§13).

## What Phase B should do with it

Treat `sha` on every event in this run as **"HEAD when the segment launched"**,
and treat `ralph/reports/gate-f-candidate/RUN_METADATA.json`'s `candidate_sha` as
the authority on what was under test. They are not the same field and, in this
run, never carry the same value after `overhead`.

This is recorded under §C.5 (instrumentation honesty): the harness's own
self-description is wrong in a specific, bounded way, and hiding that would be
worse than the defect.
