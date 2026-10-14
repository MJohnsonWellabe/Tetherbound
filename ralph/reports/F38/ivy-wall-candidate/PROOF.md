# P2-062 arena wall ivy — OFF, native validation blocked

- 13 Oct 2026 05:19 CT. Existing Warden/Galewisp baseline blind FAIL; see ../fight-camera/PROOF.md.
- Source geometry: 24m-wide arena, west-wall center x=-12.6/thickness1.2m, interior face x=-12.0. Arena west-wall Vine2 band anchors at x=-11.4,0.6m inside the room.
- Candidate changes that one band's coordinate to x=-12.0 when its placement_candidate_enabled flag is true. Default false; count8, scale0.85–1.55, tint, scatter/RNG and roof-lip vines unchanged.
- Vine2 is an installed alpha-MASK,double-sided card; bounds x[-0.4941,0.8921],y[-2.1205,0.482],z[-0.0447,0.1691]. Mesh root has no transform. No invented asset, creature resizing or gameplay/collision change.
- Placement-based approach replaces blind count/scale reduction. Source supports possible intrusion, but no per-frame camera transform proves which exact instance covers the pixels.
- Root reviewed the small data/ivy-only code diff; JSON parses, baseline flag false, no overlapping source change in new main1f6d7e2108.
- C-floor abort in preceding P2-034 run blocks native validation. Candidate unjudged/OFF; no READY, improvement or closure claim.
- Next proof: matched Low OFF/ON Warden views with unchanged camera/time/weather and real fight, log camera poses/visible geometry, neutral blind review. Do not remove roof-lip decoration or change creature scale to manufacture a pass.
