"""Reproducible attack-only review candidates. Never writes into the repository.

Requires numpy and sibling evaluate_attack_contact.py. Existing GLB binary data is an
unchanged prefix; only authored attack rotation/forelimb translation samplers
are redirected to appended keys.
This is an authored first pass, not a general rig repair or visual approval.
"""
import argparse, copy, csv, hashlib, json, pathlib, struct, sys
import numpy as np
from evaluate_attack_contact import Model

OUT=pathlib.Path(__file__).resolve().parent
ROOT=None
SHAS={
 'tuskroot':'ff702d0d0a12d2a07da4d3929658beff76ac2573c42feb2ec487f0311875ebe2',
 'riptusk':'fc6cc22690bff0d14eaabb978699fc39bf350ca987e808fd5b19017f33ef35cc',
 'staticub':'d2f655f0e10790c6b068e2e3291ebede23d955c7d170fab1c4e62187aa4506a4',
 'solmane':'5ad45c7d043d3c191e88a8f9625bf0fc2cc7289383eba030766e29d553a26f5e',
 'fulgocobra':'0e54b261e0feaca9e32e46955f05c9672884215415fb69bc5b0de8fd373fd5fa',
}
SOURCE_INVARIANTS = {'tuskroot': {'binary_length': 11080356,
              'binary_sha256': 'a673676febe7f9af0d8a9bbb013e4e7f6c77fc3f115f8ce86762a117fe7ff3e0',
              'accessor_count': 289,
              'view_count': 293,
              'structure_sha256': 'fc1adf65ab5edbbe91bcb60acf4eef82b9054d2decd0b3302aa07e179e4c69df',
              'duration': 0.9583333134651184},
 'riptusk': {'binary_length': 5555196,
             'binary_sha256': 'ac51201e71298d4612d7527b7350f49f90f3682a70bd0758db8dd14c1a70a993',
             'accessor_count': 289,
             'view_count': 290,
             'structure_sha256': '7239dda38f82e42f69f0f2842e75854d2e0f2e893add549cc1dfc943d2bae4a9',
             'duration': 0.9583333134651184},
 'staticub': {'binary_length': 4937768,
              'binary_sha256': '22086d6941fdd582adb02d220f07e609d8c3a388496e194a9029c117b13fcb9b',
              'accessor_count': 289,
              'view_count': 290,
              'structure_sha256': 'b4c42d0d69aefe732b823b826774a1dfbc37e7e463716d4ae37726062162d812',
              'duration': 0.9583333134651184},
 'solmane': {'binary_length': 4786116,
             'binary_sha256': '8346b7fe1e89ade267965d3aad6757a93a416e1358fb82140ec1169820ca6816',
             'accessor_count': 289,
             'view_count': 290,
             'structure_sha256': '032a7706c0b64cc7d6ab09872d6cb135265913be22946f3436da441f79fffc2c',
             'duration': 0.9583333134651184},
 'fulgocobra': {'binary_length': 4905892,
                'binary_sha256': '920ecc5cab34944e4f982383ec34517fe0875c0d57172aece42eba01cac4213d',
                'accessor_count': 289,
                'view_count': 290,
                'structure_sha256': '77b7558901ee8027fcbc78d169e7567203f8ac05f4c1e2681b71dd1bb4eefa1e',
                'duration': 0.9583333134651184}}

# Rest -> readable preparation -> source-family anticipation/contact timing -> rest.
PHASES=np.array([0,.12,10/23,15/23,.83,1.0])
def motion(pitch=None,yaw=None):
    return {'pitch':pitch or [0]*6,'yaw':yaw or [0]*6}
PRESETS={
 'tuskroot':{
  # Load the shoulders above a planted pelvis, then turn the forequarter into
  # the tusk strike. Imported spine X points backwards: positive raises it.
  'spine':motion([0,1,10,2,1,0],[0,-1,-7,10,2,0]),
  'neck':motion([0,-1,-6,5,1,0]),
  'head':motion([0,-1,-5,9,2,0],[0,-2,-8,10,2,0]),
  'front_upper_l':motion([0,-3,-28,-5,-2,0]),
  'front_lower_l':motion([0,-1,-12,-2,-1,0]),
  'front_upper_r':motion([0,-1,-9,-2,-1,0]),
  'front_lower_r':motion([0,-1,-4,-1,-.5,0]),
 },
 'riptusk':{
  'spine':motion([0,1,11,2,1,0],[0,-1,-6,9,2,0]),
  'neck':motion([0,-1,-7,5,1,0],[0,-1,-3,4,1,0]),
  'head':motion([0,-1,-6,9,2,0],[0,-2,-8,10,2,0]),
  'front_upper_l':motion([0,-3,-25,-5,-2,0]),
  'front_lower_l':motion([0,-1,-10,-2,-1,0]),
  'front_upper_r':motion([0,-1,-8,-2,-1,0]),
  'front_lower_r':motion([0,-1,-4,-1,-.5,0]),
 },
 'staticub':{
  'spine':motion(yaw=[0,-.5,-2,3,1,0]),
  'neck':motion([0,-1,-4,2,1,0]),
  'head':motion([0,-1,-6,5,1,0]),
  'front_upper_l':motion([0,-3,-32,-6,-2,0]),
  'front_lower_l':motion([0,-1,-14,-2,-1,0]),
  'front_upper_r':motion([0,-2,-22,-4,-1,0]),
  'front_lower_r':motion([0,-1,-8,-2,-1,0]),
 },
 'solmane':{
  'spine':motion(yaw=[0,-.5,-2,3,1,0]),
  'neck':motion([0,-1,-4,2,1,0]),
  'head':motion([0,-1,-6,5,1,0]),
  'front_upper_l':motion([0,-2,-25,-5,-2,0]),
  'front_lower_l':motion([0,-1,-10,-2,-1,0]),
  'front_upper_r':motion([0,-2,-20,-4,-1,0]),
  'front_lower_r':motion([0,-1,-8,-2,-1,0]),
 },
 'fulgocobra':{
  'neck':motion([0,-2,-9,8,2,0],[0,-1,-4,5,1,0]),
  'head':motion([0,-3,-12,18,4,0],[0,-1,-4,6,1,0]),
 },
}

# Limb-local authored clearance, in source model units. These channels move
# only the named forelimbs; pelvis/root and posterior supports remain planted.
FORELIMB_LIFTS={
 'tuskroot':{'front_upper_l':.06},
 'riptusk':{'front_upper_l':.06},
 'staticub':{'front_upper_l':.085,'front_upper_r':.085},
}

def mul(a,b):
    av,aw=a[:3],a[3];bv,bw=b[:3],b[3]
    return np.r_[aw*bv+bw*av+np.cross(av,bv),aw*bw-av@bv]

def axis_angle(axis,degrees):
    axis=np.array(axis,dtype=float);axis/=np.linalg.norm(axis);a=np.deg2rad(degrees)/2
    return np.r_[axis*np.sin(a),np.cos(a)]

def envelope(values,phase):
    hi=min(max(int(np.searchsorted(PHASES,phase,side='right')),1),len(PHASES)-1)
    lo=hi-1;f=np.clip((phase-PHASES[lo])/(PHASES[hi]-PHASES[lo]),0,1)
    f=f*f*(3-2*f)
    return values[lo]*(1-f)+values[hi]*f

def append_accessor(doc,binary,values,kind):
    values=np.asarray(values,dtype='<f4')
    while len(binary)%4:binary.append(0)
    start=len(binary);binary.extend(values.tobytes())
    vi=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':start,'byteLength':values.nbytes})
    ai=len(doc['accessors']);a={'bufferView':vi,'componentType':5126,'count':len(values),'type':kind}
    if kind=='SCALAR':a.update(min=[float(values.min())],max=[float(values.max())])
    doc['accessors'].append(a);return ai

def invariant_digest(model,name,accessor_count,view_count):
    doc=model.d
    frozen={k:v for k,v in doc.items() if k not in ['animations','accessors','bufferViews','buffers']}
    frozen['accessors']=doc['accessors'][:accessor_count]
    frozen['bufferViews']=doc['bufferViews'][:view_count]
    frozen['other_animations']=[a for a in doc['animations'] if a['name']!='attack']
    attack=model.clips['attack']
    frozen['attack_targets']=[c['target'] for c in attack['channels']]
    frozen['unchanged_attack_channels']=[]
    for c in attack['channels']:
        t=c['target'];bone=model.nodes[t['node']]['name']
        changed=t['path']=='rotation' or (t['path']=='translation' and bone in FORELIMB_LIFTS.get(name,{}))
        if not changed:frozen['unchanged_attack_channels'].append([t,attack['samplers'][c['sampler']]])
    return hashlib.sha256(json.dumps(frozen,sort_keys=True,separators=(',',':')).encode()).hexdigest()

def verify_shipped_invariants(model,name):
    pinned=SOURCE_INVARIANTS[name]
    assert hashlib.sha256(model.bin[:pinned['binary_length']]).hexdigest()==pinned['binary_sha256'],name+' original mesh/animation binary changed'
    assert invariant_digest(model,name,pinned['accessor_count'],pinned['view_count'])==pinned['structure_sha256'],name+' geometry/material/other-clip structure changed'
    duration=max(float(model.acc(s['input'])[-1,0]) for s in model.clips['attack']['samplers'])
    assert abs(duration-pinned['duration'])<1e-7,name+' attack duration changed'

def author(name,source):
    m=Model(source);assert m.sha==SHAS[name],f'{name} source changed; re-review required'
    doc=copy.deepcopy(m.d);binary=bytearray(m.bin);attack=next(a for a in doc['animations'] if a['name']=='attack')
    duration=max(float(m.acc(s['input'])[-1,0]) for s in m.clips['attack']['samplers'])
    times=np.linspace(0,duration,round(duration*96)+1,dtype=np.float32)
    ti=append_accessor(doc,binary,times,'SCALAR');modified=[]
    for channel in attack['channels']:
        target=channel['target'];node=target['node'];bone=m.nodes[node]['name']
        if target['path']=='translation' and bone in FORELIMB_LIFTS.get(name,{}):
            # This broad paw first rotates through its sole before rising. Raise
            # only this forelimb while it curls, preserving rear support and body
            # origin. The authored lift returns to zero at both clip boundaries.
            parent=m.parent[node]
            up=np.linalg.solve(m.globals[parent][:3,:3],np.array([0,1,0]))
            peak=abs(PRESETS[name][bone]['pitch'][2])
            lift=FORELIMB_LIFTS[name][bone]
            values=[m.base[node]['translation']+up*(lift*abs(envelope(PRESETS[name][bone]['pitch'],float(t/duration)))/peak) for t in times]
            oi=append_accessor(doc,binary,values,'VEC3');si=len(attack['samplers'])
            attack['samplers'].append({'input':ti,'output':oi,'interpolation':'LINEAR'});channel['sampler']=si
            continue
        if target['path']!='rotation':continue
        base=m.base[node]['rotation'];preset=PRESETS[name].get(bone)
        quats=[]
        # Convert world-up into this bone's rest local frame. Yaw then preserves
        # vertical contact coordinates, unlike guessing from imported bone axes.
        up=np.linalg.solve(m.globals[node][:3,:3],np.array([0,1,0]))
        for time in times:
            phase=float(time/duration)
            if preset:
                pitch=envelope(preset['pitch'],phase);yaw=envelope(preset['yaw'],phase)
                q=mul(base,mul(axis_angle(up,yaw),axis_angle([1,0,0],pitch)))
            else:q=base.copy()
            q/=np.linalg.norm(q)
            if quats and np.dot(quats[-1],q)<0:q=-q
            quats.append(q)
        # Every attack bone is neutral at both boundaries, including source
        # channels that originally held their first anticipation key backwards.
        quats[0]=base/np.linalg.norm(base);quats[-1]=quats[0].copy()
        oi=append_accessor(doc,binary,quats,'VEC4')
        si=len(attack['samplers']);attack['samplers'].append({'input':ti,'output':oi,'interpolation':'LINEAR'})
        channel['sampler']=si;modified.append(bone)
    doc['buffers'][0]['byteLength']=len(binary)
    json_bytes=json.dumps(doc,separators=(',',':')).encode();json_bytes+=b' '*((-len(json_bytes))%4)
    binary+=b'\0'*((-len(binary))%4)
    glb=struct.pack('<III',0x46546c67,2,12+8+len(json_bytes)+8+len(binary))+struct.pack('<II',len(json_bytes),0x4e4f534a)+json_bytes+struct.pack('<II',len(binary),0x004e4942)+binary
    path=OUT/('creature_'+name+'_lod0.glb');path.write_bytes(glb)
    candidate=Model(path)
    verify_shipped_invariants(candidate,name)
    assert candidate.bin[:len(m.bin)]==m.bin
    for key in m.d:
        if key not in ['animations','accessors','bufferViews','buffers']:assert candidate.d[key]==m.d[key],key
    for a in m.d['animations']:
        if a['name']!='attack':assert candidate.clips[a['name']]==a,a['name']
    assert candidate.d['accessors'][:len(m.d['accessors'])]==m.d['accessors']
    assert candidate.d['bufferViews'][:len(m.d['bufferViews'])]==m.d['bufferViews']
    for c0,c1 in zip(m.clips['attack']['channels'],candidate.clips['attack']['channels']):
        assert c0['target']==c1['target']
        local_lift=c0['target']['path']=='translation' and m.nodes[c0['target']['node']]['name'] in FORELIMB_LIFTS.get(name,{})
        if c0['target']['path']!='rotation' and not local_lift:assert c0==c1
    return m,candidate,duration,{'source_sha256':m.sha,'candidate_sha256':candidate.sha,'original_binary_prefix_unchanged':True,'all_original_accessors_unchanged':True,'geometry_weights_materials_node_hierarchy_unchanged':True,'other_animation_json_and_binary_unchanged':True,'root_pelvis_translation_and_all_scale_channels_unchanged':True,'changed_attack_translation_bones':list(FORELIMB_LIFTS.get(name,{})),'changed_attack_rotation_bones':modified,'active_motion_bones':list(PRESETS[name]),'duration_seconds':duration}

def validate(name,source,candidate,duration,cfg):
    pos=np.concatenate([p[0] for p in source.parts]);size=np.ptp(pos,axis=0)
    fit=min(cfg['height']/size[1],2*cfg['radius']*cfg.get('footprint_allowance',1)/max(size[0],size[2]))*cfg.get('model_scale',1)
    rest=source.rest;floor=source.floor;contact=rest[:,1]<=floor+source.height*.015;mid=(rest[:,2].min()+rest[:,2].max())/2
    patches={'posterior':contact&(rest[:,2]<mid),'anterior':contact&(rest[:,2]>=mid)}
    rows=[];worst=None;displacement=np.zeros(len(rest));poses={}
    for t in np.unique(np.r_[np.linspace(0,duration,231),PHASES*duration]):
        p=candidate.pose('attack',t);delta=(p-rest)*fit;displacement=np.maximum(displacement,np.linalg.norm(delta,axis=1))
        row={'seconds':float(t),'phase':float(t/duration),**candidate.stats(p,fit)}
        row['source_minimum_m']=source.stats(source.pose('attack',t),fit)['minimum_m']
        row['max_displacement_m']=float(np.linalg.norm(delta,axis=1).max())
        for label,mask in patches.items():
            y=(p[mask,1]-floor)*fit
            row[label+'_patch_min_m']=float(y.min());row[label+'_patch_median_m']=float(np.median(y));row[label+'_patch_horizontal_max_m']=float(np.linalg.norm(delta[mask][:,[0,2]],axis=1).max())
        rows.append(row)
        if worst is None or row['minimum_m']<worst['minimum_m']:worst=row
    with (OUT/(name+'-contact.csv')).open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    for label,phase in [('rest',0),('anticipation',10/23),('strike',15/23)]:poses[label]=candidate.pose('attack',phase*duration)
    np.savez_compressed(OUT/(name+'-poses.npz'),**poses,bind=rest,names=candidate.names,fit=fit,floor=floor)
    neutral_errors=[float(np.max(np.linalg.norm(candidate.pose('attack',t)-rest,axis=1))*fit) for t in [0,duration]]
    assert max(neutral_errors)<.0001,neutral_errors
    return {'runtime_fit':float(fit),'fitted_height_m':float(size[1]*fit),'worst_sample':worst,'neutral_boundary_max_vertex_error_m':neutral_errors,'max_vertex_displacement_m':float(displacement.max()),'median_vertex_displacement_m':float(np.median(displacement)),'vertices_moving_over_5cm':int((displacement>.05).sum()),'total_vertices':len(rest),'pose_samples':{k:candidate.stats(p,fit) for k,p in poses.items()},'support_patch_definition':'bind vertices within lowest 1.5% of height, split by bind Z midpoint; anatomical proxy, not bone-name inference'}

def make_figures(report):
    from PIL import Image, ImageDraw, ImageFont
    checking=all(r['invariants'].get('check_only',False) for r in report.values())
    try:
        font=ImageFont.load_default(size=18);small=ImageFont.load_default(size=13)
    except TypeError:
        font=small=ImageFont.load_default()
    sheet=Image.new('RGB',(1800,1750),'white');draw=ImageDraw.Draw(sheet)
    draw.text((25,10),'CPU skin projections: bind / anticipation / strike. Blue = vertices moved > 1 cm; native art review still required.',font=font,fill='black')
    curves=Image.new('RGB',(1200,1550),'white');cd=ImageDraw.Draw(curves)
    legend=('Minimum deformed vertex height: installed asset (blue), bind floor (black). Metres at gameplay scale.' if checking else
            'Minimum deformed vertex height: original (red), candidate (blue), bind floor (black). Metres at gameplay scale.')
    cd.text((25,10),legend,font=font,fill='black')
    for row,(name,r) in enumerate(report.items()):
        data=np.load(OUT/(name+'-poses.npz'));poses=[data['bind'],data['anticipation'],data['strike']];bind=data['bind'];fit=float(data['fit']);floor=float(data['floor'])
        allp=np.concatenate(poses);lo=allp.min(axis=0);hi=allp.max(axis=0)
        scale=min(520/max(hi[2]-lo[2],.01),240/max(hi[1]-lo[1],.01))
        for col,(label,p) in enumerate(zip(['bind','anticipation','strike'],poses)):
            ox=col*600+35;oy=row*340+65
            def xy(v):return (ox+(v[2]-lo[2])*scale,oy+(hi[1]-v[1])*scale)
            ground=xy(np.array([0,floor,0]))[1];draw.line((ox,ground,ox+520,ground),fill='black',width=1)
            distance=np.linalg.norm(p-bind,axis=1)*fit
            for index,v in enumerate(p):
                x,y=xy(v);draw.point((int(x),int(y)),fill='#2277bb' if distance[index]>.01 else '#999999')
            draw.text((ox,oy-24),name+' / '+label,font=font,fill='black')
            draw.text((ox,oy+250),'Max motion %.2f m; peak pose min %.4f m'%(float(distance.max()),float((p[:,1].min()-floor)*fit)),font=small,fill='black')
        with (OUT/(name+'-contact.csv')).open() as f:candidate=list(csv.DictReader(f))
        baseline=[dict(x,minimum_m=x['source_minimum_m']) for x in candidate]
        ymin=min(float(x['minimum_m']) for x in baseline)-.12;ymax=.18;x0=110;y0=75+row*295;w=1030;h=210
        def plotxy(t,y):return (x0+t/.9583333134651184*w,y0+(ymax-y)/(ymax-ymin)*h)
        cd.text((25,y0-25),name,font=font,fill='black')
        floor_y=plotxy(0,0)[1];cd.line((x0,floor_y,x0+w,floor_y),fill='black',width=1)
        series=[(candidate,'#2277bb')] if checking else [(baseline,'#cc4455'),(candidate,'#2277bb')]
        for seq,color in series:cd.line([plotxy(float(x['seconds']),float(x['minimum_m'])) for x in seq],fill=color,width=3)
        cd.text((25,y0+h-15),'%.2f m'%ymin,font=small,fill='black');cd.text((x0,y0+h+5),'0.0 s',font=small,fill='black');cd.text((x0+w-60,y0+h+5),'0.958 s',font=small,fill='black')
        cd.text((x0,y0+h+25),'Candidate minimum: %.6f m; maximum vertex displacement: %.3f m'%(r['metrics']['worst_sample']['minimum_m'],r['metrics']['max_vertex_displacement_m']),font=small,fill='black')
    sheet.save(OUT/'candidate-pose-projections.png');curves.save(OUT/'contact-curves.png')

def main():
    global ROOT,OUT
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input-root',type=pathlib.Path,required=True,help='Repository containing data/creatures/species.json and installed assets')
    parser.add_argument('--output-dir',type=pathlib.Path,required=True,help='Candidate and diagnostic directory outside input repository')
    parser.add_argument('--check-only',action='store_true',help='Validate currently installed attacks without authoring candidate GLBs')
    parser.add_argument('--no-figures',action='store_true',help='Skip optional Pillow figures')
    parser.add_argument('--species',nargs='+',choices=list(SHAS),default=list(SHAS),help='Bound authoring/checking to selected species')
    args=parser.parse_args();ROOT=args.input_root.resolve();OUT=args.output_dir.resolve()
    if OUT==ROOT or ROOT in OUT.parents:parser.error('output directory must be outside the input repository')
    OUT.mkdir(parents=True,exist_ok=True)
    cfg=json.loads((ROOT/'data/creatures/species.json').read_text(encoding='utf-8'))['species'];report={}
    for name in args.species:
        settings=cfg[name]['placeholder'];path=ROOT/settings['model'].removeprefix('res://')
        if args.check_only:
            source=candidate=Model(path)
            verify_shipped_invariants(source,name)
            duration=max(float(source.acc(s['input'])[-1,0]) for s in source.clips['attack']['samplers'])
            invariants={'check_only':True,'source_sha256':source.sha,'duration_seconds':duration}
        else:source,candidate,duration,invariants=author(name,path)
        metrics=validate(name,source,candidate,duration,settings)
        aliases=[key for key,value in cfg.items() if isinstance(value,dict) and value.get('placeholder',{}).get('model')==settings['model']]
        report[name]={'invariants':invariants,'metrics':metrics,'preset':PRESETS[name],'species_sharing_asset':aliases}
        print(name,'minimum',round(metrics['worst_sample']['minimum_m'],4),'displacement',round(metrics['max_vertex_displacement_m'],3),'moving vertices',metrics['vertices_moving_over_5cm'],flush=True)
    (OUT/'candidate-report.json').write_text(json.dumps(report,indent=2))
    if not args.no_figures:make_figures(report)
    failed=[name for name,r in report.items() if r['metrics']['worst_sample']['minimum_m']<-.01]
    if failed:raise SystemExit('Contact regression: penetration exceeds 1 cm in '+', '.join(failed))

if __name__=='__main__':main()
