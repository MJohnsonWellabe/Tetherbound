# T2 device profile Q1: current direction at 7 inches (blocked, nothing shipped)

The Cards lane's T2 device judge (`ralph/reports/CARDS/t2_device/JUDGE.md`, Q1 WEAK) found the currents findable at 7 inches, but not which way they flow. It assigned that to the Tidewake lane.

**Method, every round:**
- `tools/capture_tidewake_f13_5.gd --only=currents` at 1920x1080 opengl3 (computer capture, no Ally hardware).
- Three crossings: First Shore to Reedhaven, Brine Steps to Shellwatch, Salt Crown to Sluice Isle. Each is seen from its dock and captured twice, 0.5 s apart.
- The frames go on a sheet whose cells are 586x330, the physical width of a 7-inch panel.
- One fresh code-blind judge per round answers the Cards lane's Q1 wording.

All four rounds were local and uncommitted. Each was reverted.

| Round | Cue | 7-inch verdict | What the judge saw |
|---|---|---|---|
| rocks r1 | Marker rocks at the direct lane's edges 18-32 m from each dock, each with a 16 m foam V wake trailing downstream | WEAK | The long V arms read as perspective lines converging on the far island. |
| rocks r2 | Low rocks with a round foam pillow upstream and a tapering tail downstream | WEAK | Seen end-on, the foam around each rock spreads sideways and muddles even the axis. |
| darts r1 | Filled foam darts (wide base upstream, point downstream), 6 m long, on sparse lanes; comets off | WEAK | At full size the nearest dart "clearly points down, toward the camera", which is correct. At 7 inches the darts are white flecks. |
| darts r2 (`darts_r2_sheet_7inch.jpg`) | Darts 14 m long and 6 m wide; dashes dimmed | WEAK | The darts are 15-25 px shards at sheet size, and their points read as "left" about as often as "toward the camera". Only one Salt Crown frame hints at direction, and its partner frame loses it. |

**Reading:** each crossing is seen end-on from a low beach camera, so any flat mark on the water is foreshortened about tenfold.
- Rock wakes and darts each scored WEAK twice at 7 inches.
- Earlier flat cues: chevrons (F13#5 r2, WEAK at normal size: "read as crosses"); comets (F13#5 r3, WEAK on still-frame ambiguity at normal size, and the shipped look is the Cards T2 Q1 WEAK at 7 inches).

**Untried next approach:** a vertical cue that reads in profile, such as standing-wave ridges whose foam spills down the downstream face. That means a finer displaced ribbon mesh with lit normals and an opaque ridge body. It is a larger change, with no evidence yet that it reads.
