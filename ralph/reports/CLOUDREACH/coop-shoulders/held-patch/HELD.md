# Co-op route shoulders — held, reverted on tb/cloudreach

Coordinator ruling, #356 (issuecomment-5853153239, item 3). The live co-op build
of the solo route shoulders measured 60–89 s on 4 vCPU. The realm-transition
wait is 120 s, and a Cloudreach build had already exceeded it (B16). So the
three commits are reverted on `tb/cloudreach` and kept here as `git am`
patches:

- a9f7b73b: Cloudreach co-op builds the same route shoulders as single player
- db6e96de: per-station yields, shells still defer, geometry-hash proof
- 63bad4bf: evidence: two-peer net smokes pass; re-run on current main

Behaviour after the revert is main's: a live multiplayer build defers the
geological shoulders (it keeps the visible and colliding route ribbons), and
solo keeps them. To land the patches again, first either make the
realm-transition timeout progress-aware (with a test) or show a comfortable
two-peer margin on render.yml. The evidence above this folder is the
measurement record.
