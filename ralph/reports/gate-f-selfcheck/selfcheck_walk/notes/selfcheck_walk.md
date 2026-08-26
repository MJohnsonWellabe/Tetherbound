# selfcheck_walk — Harness self-check (DIAG): corridor walking, the 2 Hz trace, and both halves of the dead-travel meter

### SC-W-01 — boot the real Meadows
- expected: the real world scene stands up and the point-of-interest scan finds the chapter's content
- actual: booted world in 88767 ms (240 settle frames)
- events: t=88.77
- verdict: PASS

### SC-W-02 — stand still for ten seconds
- expected: the 2 Hz trace runs while nothing moves: about 20 rows, position constant, region grandpas_village
- actual: waited 600 physics frames
- events: t=98.63
- verdict: PASS

### SC-W-03 — DIAG: go to the band 1 trail spine
- expected: the player stands on the band 1 spine, clear of the opening's dialogue, starter picker and naming prompt -- each of which takes locomotion until answered, and all three of which are protocol segment S01's subject rather than this instrument check's. The distance and dead-travel accumulators reset, so nothing about this jump reaches a pacing figure.
- actual: DIAG teleport to (-40, 180); distance/dead-travel accumulators reset
- events: t=99.99
- verdict: PASS

### SC-W-04 — the teleport landed where it said
- expected: the player is on the spine point, standing on the ground rather than falling through it
- actual: 0.0 m from (-40, 180), wanted within 3.0
- events: t=99.99
- verdict: PASS

### SC-W-05 — face down the trail
- expected: the camera turns on the right stick to look along the next leg of the spine
- actual: camera turned to 131 deg in 57 frames
- events: t=101.06
- verdict: PASS

### SC-W-06 — walk sixty seconds through populated band 1
- expected: the left stick is held fully forward for 3600 physics frames -- one minute of real walking, driven by the same poll player_controller.gd reads
- actual: left stick held (0.00, -1.00) for 3600 frames
- events: t=161.08
- verdict: PASS

### SC-W-07 — the walk actually covered ground
- expected: sixty seconds of held stick moved the player at least 100 m. Anything less means the walk is stuck on terrain, and every meter reading after it would be about that instead.
- actual: walked 162.3 m this segment (wanted >= 100.0)
- events: t=161.08
- verdict: PASS

### SC-W-08 — the trace ran at 2 Hz throughout
- expected: 10 s idle plus 60 s walking at 2 Hz is about 140 rows
- actual: route.csv has 140 rows (wanted >= 130)
- events: t=161.08
- verdict: PASS

### SC-W-09 — the meter kept resetting inside band 1
- expected: over 100+ m walked through populated band 1 the dead-travel run is still under 30 m, because it reset every time a wild creature, harvest node or landmark came within the section F radius. A meter that never reset would read here as the whole distance walked.
- actual: dead_travel=0.0 m now, peak 24.9 m this segment (ceiling 30.0)
- events: t=161.08
- verdict: PASS

### SC-W-10 — walk on into the empty ground past band 1
- expected: two more minutes of held stick, carrying the walk out of the populated spine
- actual: left stick held (0.00, -1.00) for 7200 frames
- events: t=281.10
- verdict: PASS

### SC-W-11 — the meter accumulated once the content stopped
- expected: somewhere in that walk the player covered more than 25 m with nothing inside 30 m. The threshold is deliberately modest and the reason is a finding, not a fudge: measured on main, 326 m walked along the band 1 spine peaked the meter at 34.5 m and ended at 9.3 m, because band 1's content keeps arriving inside the radius. HOW FAR dead travel actually runs in this chapter is the journey segments' question (protocol section D, never from a DIAG segment); all this assertion has to prove is that the meter climbs at all, which a meter stuck at zero would fail and a meter that never reset would pass at 326.
- actual: dead_travel peaked at 24.9 m this segment (wanted >= 25.0); 162.3 m walked in total
- events: t=281.10
- verdict: FAIL

### SC-W-12 — close the segment
- expected: a note event closes the segment
- actual: route.csv's dead_travel_m and nearest_poi_dist_m columns are the raw evidence for both assertions above; read them side by side
- events: t=281.10
- verdict: PASS
