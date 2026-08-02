# D08. Save ordering is a revision counter, never a timestamp

Kind: implementation

`rev` increments only on a server-acknowledged write, which makes it a real
happens-before edge. `savedAt` is display only.

Phones cross timezones, get set by hand, and drift. Ordering two saves by wall
clock will eventually pick the wrong one, and the failure mode is silent data
loss.
