# Livewire host-window regression

CI run 34205399274, PR80 head 226aaf070, completed with 25 successful jobs,
three skips and one failed job: MP2, 101994586189. Root read every job status
and retrieved the failed job's log. Tamsin MP4 passed first attempt separately.

## Failure evidence

Livewire's first-attempt smoke failed only the check that the coordinator had
sampled the released cooldown with 180–350ms remaining. The released baseline
hit landed at 08:44:40.769 UTC; the window assertion failed at 08:44:41.811.
The next fresh action was rejected, HP/sequence stayed unchanged, and the last
accepted action stayed 806. All other smokes in MP2 passed first attempt.

The existing helper alternated a remote host probe and a remote one-frame wait
while trying to sample a 170ms-wide interval. Those control-channel round trips
can skip that interval. The log does not contain the exact remaining-ms value
at failure, so no exact overshoot is claimed. This is not a shard timeout or a
demonstrated failure of the host's cooldown enforcement.

## Repair under validation

The host now performs the same bounded, read-only wait locally and returns its
authority snapshot. The coordinator keeps the existing 180–350ms assertion.
Deadline identity, host role, a 180-frame maximum, real subsequent remote strike,
unchanged HP/sequence and unchanged accepted-action checks remain enforced.
No deadline, action, HP, cooldown multiplier, move profile or hit rule is written
by this helper. The sampled remaining time is printed on success and failure.

Parser check passes. Two-peer runtime validation completed exit 0 at
`.artifacts/livewire-host-window-20260908/`, coordinator log
`C:/Users/mattj/AppData/Local/Temp/livewire-host-window-20260908.log`.
The inactive and released windows were sampled with 316ms and 331ms remaining,
respectively, both within the unchanged 180–350ms bounds. Real subsequent early
strikes were refused without advancing HP, sequence or accepted action; Livewire
activation, elapsed strikes and release checks all passed. NET_RUN has no failure
or fatal entry. Independent review confirmed the helper does not write authority.

The run still logs old-scene replication/cache errors on realm travel. On host
shutdown it additionally reports a detached-body transform read from
`StormwoodAuthoritativeFight._exit_tree -> stop_opponent -> set_engaged`.
That teardown defect is assigned separately; this is not a zero-engine-error run.
The timing repair has local runtime evidence but still needs its next CI verdict.
