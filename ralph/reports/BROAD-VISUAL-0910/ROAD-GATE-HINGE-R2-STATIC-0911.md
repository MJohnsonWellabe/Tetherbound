# Road Gate — hinged open-state static candidate

Disposition: **EXPECTED PASS; production capture required.**

The current R1 production evidence supersedes the older named-location strip used by
the POLISH regrade. Its locked gate is already a clear, authored village threshold:
textured timber posts/caps/braces, joined leaf, installed lanterns, readable lock,
civic shield/crest, continuous fencing, a strong road axis, and distinct day/night
value structure. No additional prop or material pass is justified by those frames.

The remaining visible defect is confined to the open state. The 4.07 m leaf previously
rotated 90 degrees around its centre without translating, so it remained lengthwise
through the road centre and read as a loose fence panel floating in the passage. The
new pose derives half-width from the built prefab AABB, preserves the right-hand jamb
edge, and moves the free edge entirely to the far/village side of the threshold.

This correct hinge transform is shared by every caller of the established RoadGate
body, including the Pond, Trail and Sigil leaves. It changes no lock, key, flag, prompt,
collision, traversal seal or dialogue behavior: collision is disabled by the same
authoritative open path before the visual re-pose.

R2 should qualify for strict PASS if production frames confirm the opened leaf rests
cleanly against the far-side fence/jamb without terrain clipping. Static geometry
proves the hinge edge is invariant and the free edge clears more than four metres past
the threshold plane, but it cannot certify the final terrain contact visually.
