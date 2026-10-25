import sys
from PIL import Image
out=sys.argv[1]; fs=sys.argv[2:]
ims=[Image.open(f).convert('RGB').resize((960,540),Image.LANCZOS) for f in fs]
s=Image.new('RGB',(960,540*len(ims)),(20,20,20))
for i,im in enumerate(ims): s.paste(im,(0,i*540))
s.save(out)
