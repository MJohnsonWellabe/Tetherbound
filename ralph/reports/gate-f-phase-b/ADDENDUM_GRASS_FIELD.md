# Phase B addendum — candidate configuration: the grass field is OFF

**Received 2026-08-27T13:16Z** from the Coordinator, after all six deliverables
were published, as a build-configuration fact missing from the freeze record.
Not a proposed fix and not a developer excuse: §1.2 requires graphics settings to
be part of the freeze record, and this was absent from it.

**I verified every claim against the candidate before acting on any of it.**

## Verification

| claim | verified |
|---|---|
| `data/config/grass_field.json` has `"enabled": false` on `f082bdf6` | **yes** — `git show f082bdf6:data/config/grass_field.json` |
| `grass_field.gd::is_enabled()` reads that flag | **yes** — line 82–83 |
| `_ready()` returns immediately when false | **yes** — line 97–103: `set_process(false)`, `visible = false`, return. Its own comment: *"A disabled field is not a cheap field, it is an absent one."* |
| `playground_world.gd::_stand_up_the_grass_field()` returns early on the flag | **yes** — line 709–711, so the node never enters the tree |
| `suppressed_layers()` returns an empty Dictionary when disabled | **yes** — line 88–94: the `is_enabled()` guard returns `{}` before reading `suppress_scatter_layers` |
| no `[grass_field]` / "grass field is on" line in any run artifact | **yes** — `grep -ril 'grass_field\|grass field'` over the whole run directory returns nothing |

**Consequence, as stated and confirmed:** because `suppressed_layers()` is empty,
`vegetation.gd` suppresses nothing and builds **every** layer — `grass`,
`drygrass`, `flowers` and `groundmat` included. That is consistent with the
freeze record's own "762,058 props in 43 batches". The ground plane in all 79
X07 frames is the **baked scatter**. The procedural camera-relative grass field
is **absent from the candidate by configuration, not failing in it.**

## What I corrected, and what I did not

**Nothing had to be withdrawn.** I did not write, and had not drafted, any item
claiming the procedural grass field is missing, wrong, or regressed — I never
observed it and never named it. `GF-B-009` compares the relay/Hall ground plane
against ordinary meadow ground **inside the same frames**, and both are the
scatter system, so the comparison stands. What was missing was the *scoping*.

Corrections applied:

1. **`GF-B-009`** now names the scatter system explicitly, and carries the owner
   decision below as a dependency that may moot part of it.
2. **`SUMMARIES.md` §3 (regional plan)** now names which of the two ground
   systems each judgment is about.
3. **`SUMMARIES.md` §4 (performance plan)** and **`GF-B-001`** now record that
   the ~50 s stand-up was measured in the **maximum-placement** configuration
   (nothing suppressed). This is a scoping fact only — see the warning below.
4. **`COVERAGE_DEFECTS.md`** gains **CD-8**.
5. **`RECONCILIATION.md`** gains a note on `HIST-041`.
6. **`PROVISIONAL_BACKLOG.md` is deliberately NOT edited.** It is the hashed
   §16.2 record of what Gate F found blind. A fact that arrived afterwards does
   not get retconned into it; that is the whole point of hashing it. Its hash
   still verifies (`sha256sum -c` OK).

## The owner decision — reserved, and not mine

`grass_field.json`'s own `_comment_enabled` reserves this explicitly:

> *"OFF BY DEFAULT, deliberately, and this is the whole safety story for the
> change … the owner has to be able to switch between the two ground systems on
> the Ally itself, and a bad handheld result has to be one boolean away from gone
> rather than a revert. Turn on to evaluate; **do not turn on by default until a
> handheld pass says it is affordable.**"*

No container in this project can measure GPU cost (`PERF-ROG-GPU`; device frame
rate is **[OWNER-ONLY]**). **I do not decide this, do not assume it, and do not
recommend a default.** It is recorded as an open owner decision that gates the
ground-plane portion of the regional plan.

**A warning I want on the record.** The config states the field would suppress
**625,227 of 725,949 placements (86%)** of the non-colliding carpet. It would be
easy — and wrong — to read that together with `GF-B-001`'s ~50 s stand-up and
conclude that enabling the field would fix the freeze. That inference is not
available here: it trades a CPU placement cost this container **can** measure for
a GPU vertex cost it **cannot**, and the config already flags the ring as "a 43%
vertex increase on the most expensive tier, UNMEASURED ON THE DEVICE". `GF-B-001`
must be fixed on its own terms, not by flipping a flag whose cost is unknown.

## A second gap the freeze record exposes

Checking `ralph/reports/gate-f-candidate/RUN_METADATA.json` to confirm CD-8, I
found an unrelated contradiction worth recording:

> `"display_server": "X11 under xvfb-run"`

The freeze record says the run had a display server under xvfb. **Every journey
segment's frame manifest says the opposite** — 9,231 rows of *"headless: this
process has no display server and cannot render a frame"*. The metadata and the
artifacts disagree about the single fact that determined whether §11 could
execute at all. This strengthens `GF-B-003`: the capture pre-flight it asks for
would have caught the disagreement at step 1 instead of after the run.

## Corroboration for CD-5, from the freeze record itself

`RUN_METADATA.json`'s `suite_state_at_freeze.known_open_defect` records, at
freeze time:

> `tests/smoke_party_count_after_catches.gd` fails INTERMITTENTLY with *"could
> not engage the real wild body at Wild_bramblebun_0_3 (stopped 23.7m away
> (engage range 6.0m))"* … four hypotheses recorded as killed with the
> measurement that killed each.

That is **the same failure I reconstructed independently** from S02's telemetry —
a scripted walk stopping short of a wild creature and an `interact` press that
therefore engages nothing (`ADJUDICATION.md` §1.2, `COVERAGE_DEFECTS.md` CD-5).
It was a **known open defect at the moment of the freeze**, which means the run
was launched knowing its first required player action was unreliable.

Two consequences:

- **CD-5's confidence rises to HIGH**, and it gains a named, self-diagnosing
  reproduction that already exists in the test suite
  (`_why_the_engage_failed`) — a far cheaper starting point than re-running S02.
- **A precondition question for the next freeze**, which I raise rather than
  answer: §A.4 makes a green suite a coordinator precondition, and
  `reverified_in_container: false` plus a known-open engage defect on the
  chapter's **first required action** is a weak state to freeze on. Whether that
  should have blocked the freeze is a coordinator judgment, not a reviewer's —
  but the next freeze record should have to state it explicitly rather than
  carry it in a sub-field.
