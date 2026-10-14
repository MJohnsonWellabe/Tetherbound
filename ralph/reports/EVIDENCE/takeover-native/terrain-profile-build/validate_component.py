import sys,pathlib,json,re,math,hashlib,struct
from PIL import Image
stdout=pathlib.Path(sys.argv[1]).read_text(encoding='utf-8-sig');folder=pathlib.Path(sys.argv[2]);report=json.loads((folder/'component.json').read_text())
assert report['failures']==[] and len(report['observations'])==4
final=re.findall(r'^TERRAIN_COMPONENT_RESULT (.+)$',stdout,re.M);assert len(final)==1 and json.loads(final[0])==report
positions=[(96.2,14),(112.2,14),(344.3,926.6),(96.2,14)];lod_positions=[];images=[]
for index,row in enumerate(report['observations']):
    assert row['index']==index and row['physics_interpolation'] is True and row['regions']>0
    assert row['mesh_lods']>=2 and row['mesh_size']>0 and row['viewport']==[1280,720]
    assert abs(row['camera'][0]-positions[index][0])<.01 and abs(row['camera'][2]-positions[index][1])<.01
    # Exact raw config is snapshotted by the supervisor, not an assumed spacing.
    cfg=json.loads(pathlib.Path(sys.argv[3]).read_text());spacing=float(cfg['vertex_spacing']);assert spacing>0
    expected=[math.floor(v/spacing)*spacing for v in row['camera']]
    assert all(abs(a-b)<.01 for a,b in zip(expected,row['snapped']))
    segment=stdout.split(f'TERRAIN_COMPONENT_CAMERA_BEGIN {index}',1)[1].split('TERRAIN_COMPONENT_OBSERVED',1)[0]
    matches=re.findall(r'Snapping clipmap LOD\s*(\d+)\s+to position:\s*\(\s*([-\d.eE]+),\s*([-\d.eE]+),\s*([-\d.eE]+)\s*\)',segment)
    lod={int(n):(float(x),float(y),float(z)) for n,x,y,z in matches}
    assert set(lod)==set(range(row['mesh_lods'])),(index,lod)
    for n,actual in lod.items():
        step=2**(n+1)*spacing
        # All fixture coordinates are positive; C++ round ties away from zero.
        wanted=(math.floor(row['camera'][0]/step+.5)*step,0,math.floor(row['camera'][2]/step+.5)*step)
        assert all(abs(a-b)<.01 for a,b in zip(actual,wanted)),(index,n,actual,wanted)
    lod_positions.append(lod)
    paths=[folder/f'camera-{index}-{kind}.png' for kind in ('visible','hidden')]
    a,b=[Image.open(p).convert('RGB') for p in paths];assert a.size==b.size==(1280,720)
    changed=0;count=0;luma=[]
    for y in range(0,720,8):
        for x in range(0,1280,8):
            av=a.getpixel((x,y));bv=b.getpixel((x,y));changed+=math.sqrt(sum(((aa-bb)/255)**2 for aa,bb in zip(av,bv)))>.05;count+=1;luma.append(sum(c*w/255 for c,w in zip(av,(.2126,.7152,.0722))))
    assert changed/count>.10 and max(luma)>.08 and max(luma)-min(luma)>.05
    assert abs(changed/count-row['visible_changed_fraction'])<.01
    for p in paths:images.append(dict(path=str(p),bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
assert lod_positions[0][0]!=lod_positions[1][0]
assert all(lod_positions[0][n]!=lod_positions[2][n] for n in lod_positions[0])
assert lod_positions[0]==lod_positions[3]
assert len(list(folder.glob('*.png')))==8 and sum(x['bytes'] for x in images)<=64*1024**2
print(json.dumps(dict(status='COMPONENT_NUMERIC_PASS_VISUAL_REVIEW_PENDING',observations=4,images=images,validated_native_lod_positions=lod_positions)))
