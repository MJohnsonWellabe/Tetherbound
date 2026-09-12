# Ironwood ancient-tree reference — code-blind selection (2026-09-11)

## Verdict

**Winner: Candidate A**

Ranking: **A > C > B**.

All three images were judged only from their visible content. Candidate A is the
strongest Meshy reference of the set, although the three panels appear to depict
related variants rather than one perfectly consistent turntable. Use the left panel
as the primary silhouette and the other two only as secondary form guidance.

## 1. Candidate A — SELECT

Candidate A most immediately reads as a colossal, extremely old hero tree. Its trunk
has the broadest load-bearing mass, the clearest root-to-trunk continuity, and the
best large/medium/small scale ladder: spreading foot roots, fused trunk columns,
major lateral boughs, then a broad crown. The canopy reads as one accumulated crown
with useful negative-space breaks rather than a stack of separate pom-poms. Broad
value groups and the low, wide silhouette should survive gameplay distance better
than the finer branch gestures in the other candidates.

Meshy risks:

- Dense foliage hides several major branch junctions, so reconstruction may produce
  a solid canopy shell or branches that terminate inside leaf masses.
- The hollow openings and deeply undercut roots may close, become paper-thin, or
  generate non-manifold cavities.
- Numerous exposed root fingers may fuse into the ground plane or become fragile,
  noisy geometry. Preserve a single broad structural root plinth and simplify the
  smallest fingers.
- The three panels are not an exact rotational match. Giving them equal authority
  could average away the strongest left-panel crown and invent contradictory branch
  connections.
- Fine moss and bark striation should remain texture/normal information; asking the
  mesh to reproduce it will create surface noise and poor LODs.

## 2. Candidate C — viable alternate

Candidate C has the clearest emblematic silhouette: its enormous root arch would be
recognizable from far away and creates an obvious authored landmark. Its crown is
fairly coherent and its roots make good contact with the ground. It ranks below A
because the arch dominates so completely that the tree can read as two trunks joined
over a doorway, while the upper mass does not feel as heavy or ancient as A. The
large unsupported bridge-like trunk curves also weaken structural plausibility.

Meshy risks:

- The central arch may be filled in, flattened into a façade, or reconstructed as
  disconnected trunks; it requires explicit negative-space preservation.
- Long crossing limbs can merge or self-intersect, especially because their topology
  differs between the three panels.
- Root density is high and could become a melted skirt at ground contact.
- The orange fissures are visually appealing but may be baked as inconsistent colour
  noise rather than clean material channels.
- Rounded crown lobes may simplify into several large foliage balls unless the outer
  silhouette and internal gaps are preserved deliberately.

## 3. Candidate B — do not select

Candidate B is attractive but reads as an old windswept tree rather than an
unmistakably colossal ironwood. Its trunk is comparatively narrow, the crown breaks
into more discrete tufts, and several long horizontal branches carry visually heavy
foliage with little apparent support. It offers less monumental base mass and a less
stable gameplay-distance read than A or C.

Meshy risks:

- Thin, extended boughs are likely to warp, merge into foliage, or become fragile
  disconnected geometry.
- The isolated crown clusters invite a pom-pom result and inconsistent gaps.
- Strongly different bends across the three panels give reconstruction no reliable
  shared trunk axis.
- The small entrance/hollow and root details may disappear once the overall model is
  scaled and reduced for gameplay LODs.

## Reconstruction direction for Candidate A

Prioritize the left-panel outer silhouette, a massive continuous root plinth, four to
six primary trunk/bough masses, and a single broad crown with a few large intentional
gaps. Treat secondary root fingers, moss, bark grooves and small leaf clumps as
material or later cleanup detail. Require a clean underside and closed, thick geometry
around the principal hollow before accepting the Meshy result.
