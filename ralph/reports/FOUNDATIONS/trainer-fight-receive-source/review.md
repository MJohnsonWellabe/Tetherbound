# Actual heartbeat receive time, separate from liveness credit

F29 identified a real diagnostic defect in `f2fa698`: timeout receive time
was read from `last_heartbeat_t`, but successful world-build completion also
updates that field without receiving a heartbeat. The prior metadata could
therefore report completion time as packet time and make an old packet appear
fresh. That candidate and its failed-run evidence remain immutable; this is
a minimal committed successor, not a rewrite of its receipt.

The existing heartbeat receive branch now copies its already-sampled
`last_heartbeat_t` value into a dedicated `last_heartbeat_received_s` field.
This has one writer, only in that actual packet branch, and adds no clock
sample. Liveness, hash handling and successful world-build watchdog credit
retain their original source and behavior. World-build completion does not
write the dedicated stamp.

The timeout observation now uses that dedicated stamp and explicitly reports
`heartbeat_receive_time_known`. Both a heartbeat and its actual receive stamp
must exist; otherwise receive time/age is null. A valid stamp at time zero is
known, rather than mistaken for missing. The heartbeat copy and ordinary
latest heartbeat remain unchanged. No pumping, sending, deadline, verdict,
actor, input, frame/physics, cleanup or NET_RUN writer changes accompany this
fix. The existing coordinator observation ticks still describe timeout
*detection before teardown*, not an invented peer production timestamp.

The peer's nominal-window limit remains explicitly on its own driver clock;
receive age remains on the coordinator clock and is not peer sample age.
These clocks do not establish missing transmission or scheduling timing.
A stale sample stays stale; an absent packet/stamp stays unknown.

## Killing-row scope

Normal trainer rounds reuse their encounter ID. The existing killing row's
encounter, target UID, intent action, action ID and accepted action anchors
remain byte-for-byte present, with missing anchors null. No round identifier
is invented, rewritten or derived from that shared encounter ID.

The row now labels its scope `last_observed_kill_in_bound_encounter` and sets
`current_opponent_kill_known=false`. Its existing known=true describes an
actually observed, matching completion signal; it does not certify a kill of
the opponent currently on the field. A later round in the same encounter can
still have the earlier observed event, which must be read with its target,
action and signal time. Neither present HP nor encounter identity substitutes
for an unobserved killing action. Event capture, filtering, bounds, deepcopy,
connections and driver behavior remain unchanged.

## Source checks and delivery

The incremental runtime diff has seven additions and three replacements in
the two already allocated test files. Its inverse restores the complete
`f2fa698` harness and peer runner byte-for-byte. All other harness functions,
including world-build completion, watchdog and NET_RUN writer, are unchanged;
all peer source other than the literal scope labels is unchanged. The stamp
has exactly one write and reuses the original receive sample.

Six pure Python scalar policy controls cover packet then world completion,
completion without a packet, packet without stamp, valid zero-time packet,
later receive and stamp without a packet. These are source-policy controls,
not Godot or native tests. Whitespace and read-only patch checks pass.

`source-cut.json` pins both parent preimages and actual current ROOT preimages.
An incremental patch is provided against `f2fa698`; a cumulative two-file
patch is provided against ROOT's still-integrated `31e280`/startup source and
passes read-only ROOT apply check. Full preimages and both patches are kept in
Foundation's ignored scratch at the receipt paths. Original `f2fa698` reports,
controls and failed NET_RUN bytes are untouched.

No engine, parser, import, render, export, CI, push, new branch/chat/agent or
ROOT write occurred here. ROOT/F29 review and affected native validation
remain pending. Warden's cause and acceptance are still unproved. ROOT's
reported CI6170 unit2 assertion pass retains raw renderer/RID/resource errors
and ObjectDB leaks; that status is not used as zero-error or fight-cause proof.
