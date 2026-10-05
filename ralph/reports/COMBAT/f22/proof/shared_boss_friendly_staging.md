# smoke_net_shared_boss friendly-target staging (coordinator-authorized)

Host unchanged: encounter_host.gd resolves a swing onto the nearest in-arc body, the opponent included, before any roll (MULTIPLAYER §6).
Staging fix: the teammate is placed on the side away from the boss, and an attempt counts only when the boss is >65 deg off the swing line or farther than the teammate. The assertions are unchanged.

- local run 1: ALL CHECKS PASSED
- local run 2: ALL CHECKS PASSED
- local run 3: ALL CHECKS PASSED

## Opposite-the-boss staging (5874a553, re-applied b1a00e36): quiet-CPU 5x
- run 1 exit 0 ALL CHECKS PASSED
- run 2 exit 0 ALL CHECKS PASSED
- run 3 exit 0 ALL CHECKS PASSED
- run 4 exit 0 ALL CHECKS PASSED
- run 5 exit 0 ALL CHECKS PASSED
- Earlier loaded-CPU attempt: 2/5 ALL PASS. The other three hit time limits (smoke budget, team fight unfinished, peer hello). The one that reached the friendly section passed it.
