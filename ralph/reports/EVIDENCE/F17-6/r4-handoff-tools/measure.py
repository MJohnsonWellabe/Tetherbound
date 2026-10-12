import sys
from PIL import Image, ImageStat
d = sys.argv[1]
def m(n, box):
    im = Image.open(f"{d}/{n}.png").convert("L")
    return ImageStat.Stat(im.crop(box)).mean[0]
ok = True
far = m("nave_night", (480, 100, 820, 320)); print(f"nave_night far-end region mean {far:.1f} (>=8)"); ok &= far >= 8
for x0 in range(0, 1280, 160):
    for y0 in range(0, 560, 140):
        v = m("nave_night", (x0, y0, x0 + 160, y0 + 140))
        if v < 8: print(f"  nave_night tile ({x0},{y0}) mean {v:.1f} < 8"); ok = False
for n, box in [("nave", (0, 300, 120, 520)), ("shrine", (140, 320, 320, 560)), ("shrine", (960, 330, 1110, 560))]:
    day, night = m(n + "_day", box), m(n + "_night", box)
    print(f"sealed infill {n}{box}: day {day:.1f} night {night:.1f} (night<=day)"); ok &= night <= day
wd, wn = m("shrine_day", (380, 110, 900, 210)), m("shrine_night", (380, 110, 900, 210))
print(f"shrine plaster above opening: day {wd:.1f} night {wn:.1f} ratio {wn / wd:.2f} (<=0.6)"); ok &= wn <= 0.6 * wd
bd, bn = m("shrine_day", (390, 270, 890, 350)), m("shrine_night", (390, 270, 890, 350))
print(f"shrine back wall: day {bd:.1f} night {bn:.1f} ratio {bn / bd:.2f} (<=0.6)"); ok &= bn <= 0.6 * bd
print("ALL CLEAR" if ok else "NOT CLEAR")
