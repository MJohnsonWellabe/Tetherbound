# Lane C bounty authority evidence

`8528443fbc02f010fc0f86e6b16391a7c8f61c7e` defers the first rejoin declaration while an exact character training row is pending. Existing character/peer/world/namespace/epoch/request/stream bindings remain required. Only accepted authority ACK permits the bound declaration retry. Independent reviewer `/root/kitchen_review`: **APPROVE**.

The branch's flag-on candidate begins at `b72b540235f6d1b71abd8ddd4e53a23cddcec66a`; it is not a completed F43 release claim. Review found that the pristine saved rollover counter is zero, while rotation requires a one-based day. `e0372e908d5d34b736777bc475cb68287c93399d` derives the production bounty day as validated completed rollovers plus one, without advancing the host clock. Existing rotation assertions start from actual schema defaults and verify that the next counter increment refreshes the board. Independent reviewer: **APPROVE**, bounded F43#0/#3 source.

Hosted run `37626095584`, artifact `11483549464`, exact checkout `e0372e908d5d34b736777bc475cb68287c93399d`: **364 tests / 5,197 assertions / zero failures**, 38 existing files directly naming the changed shared authority/composition/capture/bounty sources. Earlier run `37623384090` passed 128 tests / 2,300 assertions on the preceding authority cut.

`e60859b5d7` extends existing `smoke_net_foundations` to require three live first-day bounties before replacing the pristine world counter with its disclosed populated-storage fixture. Its native flag-on run is still pending. The smoke's storage/rejoin checks are not proof of actual claimed bounty rewards.

Remaining gates: pristine production admission, named production rejoin, personal persistence, actual reward-claim reconnect proof and applicable board capture/judge. F43#2 and blanket F43#0–3 remain open. The actor-vitals shipping flag remains false.
