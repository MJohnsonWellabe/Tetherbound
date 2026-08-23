"""Groundcover geometry coverage in the lower half of a ground frame.

frame_stats.py's `nearL` samples only luma[h*0.85:], the bottom 15% of the
frame. In this survey the camera stands ON the path and aims down it, so that
band is the worn dirt itself -- ground the path_factor gate deliberately keeps
clear. nearL therefore cannot move when groundcover beside the path changes,
which is exactly what makes it the wrong axis for judging this work.

This measures the band the cover actually occupies: rows 50%-90%, the
mid-to-near ground either side of the path. The scatter's grass/flower models
render brighter and more saturated than the terrain photograph under the same
light, so a saturation floor in the green-yellow band separates plant geometry
from terrain wash reasonably well. It is a proxy, not a segmentation -- it is
reported as one, and only round-over-round DELTAS on identical viewpoints are
meaningful.
"""
import sys, os
import numpy as np
from PIL import Image

def hsv(rgb):
    mx = rgb.max(axis=2); mn = rgb.min(axis=2); d = mx - mn
    v = mx; s = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0.0)
    h = np.zeros_like(mx)
    m = d > 1e-6
    r, g, b = rgb[:,:,0], rgb[:,:,1], rgb[:,:,2]
    idx = m & (mx == r); h[idx] = ((g-b)[idx]/d[idx]) % 6
    idx = m & (mx == g); h[idx] = ((b-r)[idx]/d[idx]) + 2
    idx = m & (mx == b); h[idx] = ((r-g)[idx]/d[idx]) + 4
    return (h*60.0) % 360.0, s, v

def cover(path):
    rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)/255.0
    h, w, _ = rgb.shape
    band = rgb[int(h*0.50):int(h*0.90), :, :]
    hu, sa, va = hsv(band)
    plant = (hu > 60) & (hu < 150) & (sa > 0.45) & (va > 0.22)
    return 100.0*float(plant.sum())/plant.size

if __name__ == "__main__":
    dirs = sys.argv[1:]
    names = sorted(f for f in os.listdir(dirs[0]) if f.endswith("-day.png"))
    print("%-38s %s" % ("frame", "  ".join("%9s" % os.path.basename(d) for d in dirs)))
    print("-"*(38+11*len(dirs)))
    tot = [0.0]*len(dirs)
    for n in names:
        vals=[]
        for d in dirs:
            p=os.path.join(d,n)
            vals.append(cover(p) if os.path.exists(p) else float('nan'))
        for i,v in enumerate(vals): tot[i]+=v
        print("%-38s %s" % (n[:38], "  ".join("%8.3f%%" % v for v in vals)))
    print("-"*(38+11*len(dirs)))
    print("%-38s %s" % ("MEAN", "  ".join("%8.3f%%" % (t/len(names)) for t in tot)))
