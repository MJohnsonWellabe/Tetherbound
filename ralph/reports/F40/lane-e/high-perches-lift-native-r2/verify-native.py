from pathlib import Path
from PIL import Image,ImageDraw
import json,re,hashlib,struct,zlib
packet=Path('C:/CodexTemp/tetherbound-proof/native-e-401977bce7-high-perches-lift-r2')
raw=Path('D:/CodexTemp/tetherbound-native/d-e2d54b40aa/.tmp/e-high-perches-lift-401977-day-r2')
terminal=json.loads((packet/'capture-terminal.json').read_text(encoding='utf-8-sig'))
assert terminal['source']=='401977bce7041e4274f8e01e8075462ecd87a0de' and terminal['exit_code']==0 and terminal['reason']=='process_exit'
manifest=(raw/'manifest.txt').read_text(encoding='utf-8-sig')
assert '# frame matrix: 2 frames written, 0 rows skipped' in manifest
lines=manifest.splitlines();graphics=[json.loads(s[len('# graphics_capture '):]) for s in lines if s.startswith('# graphics_capture ')]
assert len(graphics)==1 and graphics[0]['source_commit']==terminal['source']
assert graphics[0]['preset']=='High' and graphics[0]['renderer']=='forward_plus' and graphics[0]['resolution']==[1920,1080]
rows=[s for s in lines if s.startswith('MANIFEST ')]
assert len(rows)==2
names=[s[len('MANIFEST '):].split(' | ')[0] for s in rows]
assert [n[:2] for n in names]==['19','20'] and 'perch-landing' in names[0] and 'perch-vista' in names[1]
files=sorted(p for p in raw.glob('*.png') if not p.name.startswith('_'))
assert {p.stem for p in files}==set(names) and len(files)==2
logs=(packet/'capture.stdout.log').read_text(encoding='utf-8-sig')+'\n'+(packet/'capture.stderr.log').read_text(encoding='utf-8-sig')
assert not re.search(r'^(SCRIPT ERROR:|ERROR:)',logs,re.M)
checks=[];contact=Image.new('RGB',(1920,565),(22,22,22));draw=ImageDraw.Draw(contact)
for i,p in enumerate(files):
 data=p.read_bytes();assert data[:8]==b'\x89PNG\r\n\x1a\n';offset=8;dims=None;ended=False
 while offset<len(data):
  n=struct.unpack('>I',data[offset:offset+4])[0];kind=data[offset+4:offset+8];payload=data[offset+8:offset+8+n]
  crc=struct.unpack('>I',data[offset+8+n:offset+12+n])[0];assert zlib.crc32(kind+payload)&0xffffffff==crc
  if kind==b'IHDR':dims=list(struct.unpack('>II',payload[:8]))
  offset+=n+12
  if kind==b'IEND':ended=True;break
 assert ended and offset==len(data) and dims==[1920,1080]
 with Image.open(p) as im:
  im.load();im=im.convert('RGB');im.thumbnail((960,540));contact.paste(im,(i*960,0));draw.text((i*960+4,543),p.stem,fill='white')
 checks.append({'original':str(p),'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'dimensions':dims,'png_crc_verified':True})
summary={'source':terminal['source'],'exit':0,'frames':2,'selected_rows':[19,20],'graphics':graphics[0],'manifest_sha256':hashlib.sha256((raw/'manifest.txt').read_bytes()).hexdigest(),'scope':'Two High Perches day rows only. Original staged chapter fixture, no whole criterion, blind PASS, earned route, motion or performance claim.'}
(packet/'native-image-integrity.json').write_text(json.dumps(checks,indent=2)+'\n')
(packet/'native-verified-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
contact.save(packet/'native-two-frame-contact.jpg',quality=94)
print(json.dumps(summary))

