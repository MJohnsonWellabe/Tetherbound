# Gull Rest shadow bias and vertex-normal diagnosis

Six native Compatibility 1920×1080 frames, seed 2042, all valid with zero
camera displacement. Each case retains shadow opacity one. Baseline game commit
is `20088d8e5`; `working.patch` records the uncommitted grass-colony changes
present throughout this batch (subsequently committed as `d3a535bab`). Both dune
gates were enabled only during capture and restored false. These frames are
controlled comparisons within this batch, not exact matches to the earlier
surface batch's grass. Local diagnostic source is retained here; it extends
the source retained in `../surface-01-ablation/diagnostic.gd.txt`.

| Variant | Observed result |
|---|---|
| Baseline: normal bias 1.7, bias 0.06 | Fine foreground bands and jagged cliff shading persist |
| Normal bias 0, bias 0.06 | Bands become much stronger; additional artifacts appear on the right slope |
| Normal bias 0, bias 0.2 | Strong bands persist |
| Normal bias 1.7, bias 0.2 | No useful removal of baseline bands |
| Central-gradient vertex normals, original biases | Changes cliff shadow boundary but does not remove ground bands |
| Central-gradient vertex normals, bias 0.2 | Bands remain; no accepted improvement |

All requested bias values and installed shader hashes were read back at capture.
Removing normal bias is contraindicated by these frames. A modest constant-bias
increase and reconstructed vertex normals are insufficient; neither shader
rewrite nor bias change is integrated. The grass-colony implementation is
visible but this diagnostic does not accept its art quality across islands.

Next step is source-backed investigation of effective Compatibility shadow
controls. In particular, `LIGHT_VERTEX` must not be assumed to affect shadows:
Godot tracks that renderer limitation in
[issue 101119](https://github.com/godotengine/godot/issues/101119). No visual
criterion is accepted by this root technical analysis.
