import sys
from PIL import Image, ImageDraw, ImageFilter
sys.argv=['x']
from preview_render import render
D='/home/user/tetherbound/assets/creatures/tetherbound/bramblebun_redesign/models/'
TEX={'CURRENT (shipped vivid albedo)':D+'bramblebun_redesign_extracted_base_color_vivid.png',
     'CANDIDATE (Meshy 01a0d688)':'candidate/tex0_base_color.png'}
YAWS=[(0,'front'),(40,'3/4 front'),(90,'side'),(150,'3/4 rear'),(180,'back')]
S=420
frame=Image.open('/tmp/claude-0/-home-user/c5e09b24-64e9-5f4d-827d-b9212dd8b5d5/scratchpad/judge/frames/C-03-closing-in.png').convert('RGB')
grass=frame.crop((700,190,1120,470)).resize((S,S))   # real in-game meadow patch
rows=[]
for label,tp in TEX.items():
    tiles=[]
    for yaw,name in YAWS:
        im=render(tp,yaw,S); im.save(f"renders/{'cur' if label.startswith('CUR') else 'cand'}_{yaw}.png"); tiles.append((im,name))
    # 30% scale on real grass, front 3/4 and rear
    g=grass.copy()
    for (im,_),(ox) in ((tiles[1],30),(tiles[3],220)):
        small=im.resize((int(S*0.4),int(S*0.4)),Image.LANCZOS)
        mask=Image.eval(small.convert('L'),lambda q:0)
        sp=small.load(); mp=mask.load()
        for y in range(small.size[1]):
            for x in range(small.size[0]):
                if sp[x,y]!=(46,50,56): mp[x,y]=255
        g.paste(small,(ox,200),mask)
    tiles.append((g,'40% on in-game grass'))
    rows.append((label,tiles))
W=S*6+70; H=len(rows)*(S+40)+40+S+40
sheet=Image.new('RGB',(W,H),(24,26,30)); dr=ImageDraw.Draw(sheet)
dr.text((10,10),'Bramblebun retexture validation - shipped mesh + own UVs, flat-lit software preview (not an engine render)',fill=(230,230,230))
y=40
for label,tiles in rows:
    dr.text((10,y),label,fill=(255,220,120))
    for i,(im,name) in enumerate(tiles):
        sheet.paste(im,(10+i*(S+10),y+18)); dr.text((14+i*(S+10),y+22),name,fill=(220,220,220))
    y+=S+40
# bottom: style reference, Meshy thumbnail, albedo pair
dr.text((10,y),'Inputs / Meshy outputs: agent-drafted style reference | Meshy thumbnail | shipped vivid albedo | candidate albedo',fill=(255,220,120))
refs=[Image.open('ref/bramblebun_style_ref_final.png'),Image.open('candidate/thumbnail.png'),
      Image.open(D+'bramblebun_redesign_extracted_base_color_vivid.png'),Image.open('candidate/tex0_base_color.png')]
for i,im in enumerate(refs):
    sheet.paste(im.convert('RGB').resize((S,S)),(10+i*(S+10),y+18))
sheet.save('comparison_current_vs_candidate.png')
print(sheet.size)
