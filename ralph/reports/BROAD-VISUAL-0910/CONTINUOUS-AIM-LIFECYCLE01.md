# Continuous aim lifecycle diagnostic 01

Status: the canonical fresh `--through-rest` prefix passed this run. The earlier 219-second aim-loss failure did not reproduce, so this is one passing path and not evidence that the old intermittent failure is fixed.

## Run

`continuous-aim-lifecycle-first` ran the canonical `smoke_four_biome_continuous.gd` through the rested-team checkpoint under the diagnostic subclass. The guarded headless process ran from 04:59:34 to 05:12:05, exited 0 without engine errors, and reported `requested_prefix_passed=true`, `reached=rested_team`, `failures=[]`, and 742.83 seconds inside the campaign smoke.

The prefix completed the fresh opening catch, village, earned team, material gathering, paid camp and real rest sequence. Its coverage observer recorded 1,970.02m of observed travel across 179 samples. It counted 141 samples below two visible-forward bodies and one undersampled interval. The observer labels its nearest route only as `nearest_only_not_membership`; it does not establish whether those samples were on a road, indoors, or elsewhere. These counts describe this prefix's observed camera path and are not a formal ROAD-oracle contradiction or a four-biome completion claim.

## Aim lifecycle evidence

The tracer attached to the production `ThrowAim` node through `SceneTree.node_added` before that node's `_ready()`. It recorded 61 lifecycle entries:

- 1 pre-ready node attachment;
- 10 `aim_entered` signals;
- 10 `aim_exited` signals;
- 10 `orb_struck` signals;
- 30 sampled state transitions;
- 0 `throw_refused`, `orb_missed`, or cancel-path exits.

Every observed `aim_exited` stack was `ThrowAim._release <- _tick_aiming <- _physics_process`. At the signal boundary the state was `THROWN`, an orb was live, and the last sampled report was nonempty and eligible. Each was followed by `orb_struck` and the normal `THROWN -> IDLE` transition with cooldown 0.9. No exit stack contained `_leave_aim`, `disarm`, `menu_cancel`, or `combat_run` cancellation.

The frame-10327 exit highlighted during the live run was an ordinary release against `Wild_bramblebun_0_3`: its last report was eligible, line of sight was true, trajectory was unblocked, state changed from AIMING to THROWN, and the stack entered from `_release`. No relevant input remained pressed at the exit signal. It was followed by a physical strike.

## Disposition and limits

This run distinguishes normal release exits from cancellation and shows no unexplained aim loss on one complete fresh prefix. It does not reproduce the older failure where a late correct target had line of sight but `preview={}`, which only establishes that ThrowAim was no longer AIMING at that observation point. Because no cancellation occurred here, the cause of that older state loss remains unresolved. No production behavior or canonical smoke input, timing, assertion, inventory, HP, or state was changed by the tracer.
