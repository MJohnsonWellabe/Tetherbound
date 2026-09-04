# D73 — Evidence is machine-made, and the visual bars run beside Gate 3

**Date:** 2026-09-04 · **Decided by:** orchestrator, on the owner's direction of
the same day: *"there can not be any human performed parts to the plan"*, *"I
could run a script that I just have to kick off"*, *"I want you to decide on any
open questions"*, and *"while gate 3 is running we should be doing more to get
the visual bars cleared."*

This records nine decisions. Eight are the open questions the ledgers had been
holding for the owner; the ninth is the process rule that makes the first eight
answerable without them.

## 1. The owner's only job is the double-click

`tools/owner/KICKOFF.cmd` is the whole human contribution to evidence. It runs
`docs/acceptance/KICKOFF_RUN.md` end to end on a Windows machine with a GPU and
pushes what it produced to `owner-run/<stamp>`. No owner playtest, no owner
confirmation, no owner screenshot is a precondition for closing anything any
more. Where a ledger row says "needs owner confirmation on hardware", the
kickoff run's telemetry, video sheets and frame-rate file on the same hardware
are that confirmation.

**The ROG Ally is the reference box.** It is a Windows PC with a GPU, so the run
belongs on it: the frame-rate numbers are then the real ones and the four
hardware-only items (interact reliability, frame rate with grass on, player
sleep, day/night advancing) close from the run's own evidence. A desktop is an
acceptable second box for the frames and the chain when the Ally is busy; its
`fps.json` is then labelled by machine and is not the Ally's number.

**Gate 4's evidence is the kickoff run**, not a human playthrough. The chain
runs twice in it over time: once with the harness's documented grants for
reliability, and once (`--gate-b-full-chain`-style, when a no-grant journey
exists) for balance. Until the no-grant journey exists the grants are recorded,
as they always were, and balance is read off the curve tests plus the run's
level and XP timeline.

## 2. The visual bars are answered on the GPU route strip

Every Bar A / Bar B verdict to date was made from a handful of fixed stands,
rendered in software, with no creature in frame. From now on the blind judge
answers both bars on the **route strip**: one frame every 40 m along the
authored spine at the player's eye height, day and night, rendered on the
kickoff machine's GPU (`tools/_capture_route_strip.gd`, sheets in
`ralph/reports/OWNER-KICKOFF-<stamp>/frames/`). The fixed stands remain for
before/after work on a specific stand. The rubric's "do not trust fine lighting"
caveat lifts on GPU frames.

**A gate does not close on a judge "no".** `docs/CURRENT_STATE.md` §5 recorded
that Gate 2's task list could complete with both bars still answered no. That
is now disallowed: a gate whose acceptance names the bars closes only when the
route-strip judge answers yes on the bands the gate covers, or when a written
owner note in `docs/owner/` accepts the specific named gaps. The gate stays open
otherwise, and its remaining work is the judge's ranked list.

## 3. Procedural augmentation of the installed family is allowed

The hard rule forbids **new meshes and Meshy generations**. It does not forbid
building on the meshes already installed. Explicitly permitted from now on:

- foliage cards, leaf-cluster impostors or shader-driven canopy break-up
  applied to the installed nature family's trees;
- noise-displaced or re-proportioned variants generated at bake time from the
  installed rock and stone meshes;
- material and shader variants of any installed mesh.

Still forbidden: buying, downloading or generating a new mesh family, and any
Meshy spend without owner reference art. The judges' "art not in the build"
list (canopy structure, rock variety) is therefore in scope for the visual
track (`docs/ROADMAP.md`, Gate 3 parallel track).

## 4. Grass clump cards ship behind the flag

The blade-shape redesign (clump cards) waited on an owner answer since
2026-09-02. Decision: implement it in `grass_field.gd` behind a
`grass_field.json` key, **on by default**, judged on the next route strip. If
the judge names the cards as worse than the blades on the same stands, the flag
goes off in one commit. The 75k-tuft density decision is unchanged.

## 5. Corridor-fill tree scale is re-rolled once, before Band 2's bake

The "one lollipop, repeated" tree-lines are `corridor_fill`'s own draw, not
anchors, and widening its `scale_min`/`scale_max` re-rolls the whole corridor's
RNG stream. That is done **once**, as the first bake window of Gate 3, before
the Band 2 lane bakes on top of it, and never again per band. Band lanes then
author against the re-rolled fill.

## 6. Dialogue camera pushes in; villagers keep their size

"Villagers read too small in dialogue" is a camera-depth problem. Decision: a
conversation push-in (the camera moves to a two-shot at ~3.5 m over the
duration of the fade) rather than any change to villager scale, which the
owner has already had cut and re-cut. Implemented as a bounded task under the
visual track; judged from the S03 video sheets.

## 7. Grandpa's loft bed is closed by harness evidence

Whether the owner "ever tried" the loft bed cannot be answered and no longer
needs to be. `smoke_gate_b_continuous` sleeps in it and the kickoff run's S02
video shows it. Reopen only from a kickoff-run S02 or S03 defect row.

## 8. D50's loops satisfy the rebuild plan; no macro redesign

`docs/owner/MEADOWS_QUALITY_REBUILD_PLAN.md` §5 asks that the world "must not
feel like one long corridor" and lists regional loops, reconnects and
overlooks. D50 §3.2 authored ten loops off the spine and D36 sized the named
regions. Decision: the ask is satisfied by finishing those loops with content
in Gate 3, band by band. There is no macro-layout redesign, and no lane may
propose one without a new owner directive. The kickoff run's dead-travel and
temptation counts are how "feels like a corridor" is measured from now on.

## 9. Locomotion is judged from video, and is on the visual track

The rebuild plan's `MQ1A/MQ1B` locomotion items never reached the roadmap. They
are added to the Gate 3 visual track. Their acceptance is a code-blind judge
reading walk and sprint frame strips cut from the kickoff run's video (eight
consecutive frames at 30 fps, rear and side), which is the first motion
evidence this project has had. No owner viewing is required.

## Consequences

- `docs/ROADMAP.md` gains the Gate 3 parallel visual track and a Gate 4 whose
  evidence is the kickoff run.
- `docs/CURRENT_STATE.md` rows marked "needs owner confirmation" are closed or
  reopened by the next kickoff run, not by a playtest note.
- The visual-judge skill is fed route sheets first, fixed stands second.
