STATUS: land

# THINGS-FLIGHTTOOL landing (flight capture take-off race)

Branch `tb/things-flighttool-land`, cut from main f421556c. Tooling only: `tools/phase2_capture_realm_flight.gd`.

**Blocker reproduced.** "double Jump denied" with an empty reason at the first stands, intermittently (GPU lane, both trees, about an hour of retries on the F38#15 close-out). On CPU here: five stands denied before one took off, so the row's frames came out as 03/04/05 from a later stand.

**Cause.** The Fly press was sent a fixed number of frames after the first jump, sometimes before the trainer had left the floor or after they had landed again, so the game never saw a mid-air press.

**Fix.** The tool waits until the trainer is airborne before the Fly press, and if Fly did not deploy with no denial reason, it jumps again (up to four tries). It prints `FLIGHT STAND index=<n> at <xz>` so a run that used a later stand is visible in the log.

**Check.** CPU, Meadows, default carrier: `FLIGHT STAND index=0`, frames 01-launch, 02-glide, 03-landed, `failures=[]`. One run on `tb/things` (same patch); not run on GPU.
