# Current landmark baseline

Source: `04ca924248421de076bc6827d5014d2933f591e7`, after the accepted
P2-042 weather activation and integration of main's owned-carrier Fly change.
Bark grounding, candy, dialogue and HUD-vitals candidates remained disabled.

The existing location and route capture helpers completed 48 and 30 frames
respectively on the native Windows/NVIDIA Compatibility renderer. Every
image was verified at 1920x1080. Both engine manifests report complete with
no failures. All observed weather phases were Calm.

`locations/` and `routes/` each retain two contact-sheet pages, a compact
manifest with source/reproduction provenance, and `catalog-coverage.json`
mapping every requested original sighting to its catalog item. All mapped
sightings are present: P2-037, P2-038, P2-039, P2-040, P2-041 and P2-043.
Raw images remain local under `.tmp/stormwood-phase2/catalog-baseline-01/`
and `catalog-baseline-02/`.

These are current production baselines, not accepted fixes. Debug travel,
clock pinning and the production-camera stand selection are disclosed in the
engine manifests. Capture completion does not prove that a subject is visible
or readable: some approach views are blocked by foreground vegetation or
trunks, which the blind review must distinguish from the named art defect.
Day/night labels do not imply a different Stormwood sky; its purple storm
look is preserved. These images do not prove earned progression, continuous
traversal, device performance or the complete chapter frame matrix.
