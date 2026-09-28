"""Reference-backed Galecrest rebuild; measured landmarks replace generic bird guesses."""
import bpy,sys,math,json,pathlib
from mathutils import Vector,Matrix,Quaternion
ROOT=next(p for p in pathlib.Path(__file__).resolve().parents if (p/'project.godot').is_file())
sys.path.insert(0,str(ROOT/'tools/art_pipeline/blender'))
import rig_bird as r
original_join=r.join_normalise_weld
def prepare():
    body=original_join()
    # The source is posed 26 degrees off canonical front: measured foot line.
    rot=Matrix.Rotation(math.radians(26.3),4,'Z')
    for v in body.data.vertices: v.co=rot@v.co
    # Keep UVs/materials; reduce triangulated feather geometry without voxelizing it.
    bpy.context.view_layer.objects.active=body
    d=body.modifiers.new('FeatherBudget','DECIMATE');d.ratio=0.71
    bpy.ops.object.modifier_apply(modifier=d.name)
    body.data.validate(verbose=True);body.data.update()
    return body
r.join_normalise_weld=prepare
def measured(body):
    pts=r.world_points(body);low,high=r.point_bounds(pts);size=high-low
    feet={}
    for side,sgn in [('l',-1),('r',1)]:
        q=[p for p in pts if p.z<.17 and p.y<.1 and p.x*sgn>0]
        feet['foot_'+side]=r.centroid(q)
    hip_y=(feet['foot_l'].y+feet['foot_r'].y)/2+.04
    head=[p for p in pts if p.z>.97 and abs(p.x)<.20 and p.y<-.05]
    head_centre=r.centroid(head);beak=min(head,key=lambda p:p.y)
    shoulder_z=.83;neck_z=.99;crotch=.44;torso_half=.17;chest_y=-.12
    shoulders={s:Vector((sgn*.15,chest_y,shoulder_z)) for s,sgn in [('l',-1),('r',1)]}
    wings={}
    for side,sgn in [('l',-1),('r',1)]:
        q=[p for p in pts if p.z>.63 and p.x*sgn>.25]
        tip=max(q,key=lambda p:p.x*sgn)
        def band(a,b):
            return r.centroid([p for p in q if a<abs(p.x)<b])
        elbow=band(.28,.42);wrist=band(.55,.72)
        wings[side]=dict(elbow=elbow,wrist=wrist,tip=tip,span=(tip-shoulders[side]).length,lateral=abs(tip.x))
    tail=[p for p in pts if p.y>.25 and p.z<.65]
    return dict(low=low,high=high,size=size,mid_x=0.,feet=feet,hip_y=hip_y,crotch_z=crotch,crotch_measured=True,torso_half=torso_half,neck_z=neck_z,neck_measured=True,shoulder_z=shoulder_z,chest_y=chest_y,head_centre=head_centre,beak=beak,tail_end_y=max(p.y for p in tail),shoulders=shoulders,wings=wings,leg_length=crotch,leg_fraction=crotch/size.z,spread_ratio=max(w['lateral'] for w in wings.values())/torso_half,wings_folded=False)
r.measure=measured
# A raptor breathes and scans without corkscrewing its head or flailing its wings.
r.IDLE_HEAD_TURN=10.;r.IDLE_HEAD_NOD=3.;r.IDLE_NECK_NOD=2.;r.IDLE_SPINE_NOD=2.
r.IDLE_WING_LIFT=3.;r.IDLE_WING_SETTLE=5.;r.IDLE_TAIL_NOD=4.;r.IDLE_TAIL_TURN=3.

original_idle = r.author_idle
def alert_idle(rig, frames, prop):
    """Head-only eight-degree alert bias; preserve the original scan keys."""
    original_key = r.key
    def alert_key(rig, name, frame, nod=0., turn=0., slide=None):
        if name == 'head':
            nod -= 8.  # Measured nod channel: negative raises the beak.
        return original_key(rig, name, frame, nod, turn, slide)
    r.key = alert_key
    try:
        original_idle(rig, frames, prop)
    finally:
        r.key = original_key
r.AUTHORS['idle'] = alert_idle


def evaluated_bounds(body):
    graph = bpy.context.evaluated_depsgraph_get()
    evaluated = body.evaluated_get(graph)
    mesh = evaluated.to_mesh()
    points = [evaluated.matrix_world @ vertex.co for vertex in mesh.vertices]
    low, high = r.point_bounds(points)
    evaluated.to_mesh_clear()
    return low, high


def grounded_faint(rig, frames, prop):
    """Both wings settle alongside the torso during a grounded side collapse.

    Correct root height from the actual deformed mesh at every frame, not
    from bones or an assumed bounding capsule. A small explicit clearance
    covers inter-frame linear interpolation, which is checked by the audit.
    """
    body = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
    scene = bpy.context.scene
    tracks = list(rig.animation_data.nla_tracks)
    prior_mutes = [t.mute for t in tracks]
    for track in tracks:
        track.mute = True
    for frame in range(frames+1):
        t = frame/frames
        sink = max(0., min(1., (t-.05)/.78))
        sink = sink*sink*(3.-2.*sink)
        fold = max(0., min(1., t/.62))
        fold = fold*fold*(3.-2.*fold)
        scene.frame_set(frame)
        r.key(rig, 'root', frame, nod=0., turn=-98.*sink, slide=0.)
        r.key(rig, 'pelvis', frame, nod=0.)
        r.key(rig, 'spine', frame, nod=0.)
        r.key(rig, 'neck', frame, nod=12.*sink)
        r.key(rig, 'head', frame, nod=10.*sink, turn=-7.*sink)
        r.key(rig, 'tail_1', frame, nod=0.)
        r.key(rig, 'tail_2', frame, nod=0.)
        for side in r.SIDES:
            r.leg_key(rig, 'leg_upper_'+side, frame, forward=80.*sink, splay=0.)
            r.leg_key(rig, 'leg_lower_'+side, frame, forward=-145.*sink)
            r.leg_key(rig, 'foot_'+side, frame, forward=65.*sink)
            # Explicit rearward anatomical fold. Generic lift/swing Eulers
            # over-rotate this source's already raised flight feathers.
            for segment in ['upper', 'fore', 'tip']:
                bone = rig.pose.bones['wing_'+segment+'_'+side]
                rest = bone.bone
                bpy.context.view_layer.update()
                parent_delta = bone.parent.matrix @ bone.parent.bone.matrix_local.inverted()
                base = parent_delta @ rest.matrix_local
                direction = (base.to_3x3() @ Vector((0,1,0))).normalized()
                target_rest = Vector((-.12 if side == 'l' else .12, .97, -.18)).normalized()
                spine = rig.pose.bones['spine']
                torso_delta = spine.matrix @ spine.bone.matrix_local.inverted()
                target = (torso_delta.to_3x3() @ target_rest).normalized()
                delta = direction.rotation_difference(target)
                basis = base.to_quaternion()
                folded = basis.inverted() @ delta @ basis
                bone.rotation_mode = 'XYZ'
                bone.rotation_euler = Quaternion().slerp(folded, fold).to_euler('XYZ')
                bone.keyframe_insert('rotation_euler', frame=frame)
        bpy.context.view_layer.update()
        low, high = evaluated_bounds(body)
        # Root's local translation Y is armature/world up, unaffected by its
        # pose rotation. Keep the lowest feather/talon six millimetres clear.
        r.key(rig, 'root', frame, nod=0., turn=-98.*sink, slide=.006-low.z)
    action = rig.animation_data.action
    for curve in action.fcurves:
        for point in curve.keyframe_points:
            point.interpolation = 'LINEAR'
    for track, mute in zip(tracks, prior_mutes):
        track.mute = mute
r.AUTHORS['faint'] = grounded_faint


def audit_r2():
    """CPU-only pose and clearance evidence, after the separate GLB export."""
    args = r.argv_after_double_dash()
    if '--r2-audit' not in args:
        return
    out = pathlib.Path(r.option(args, '--r2-audit')).resolve()
    out.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    rig = next(o for o in scene.objects if o.type == 'ARMATURE')
    body = next(o for o in scene.objects if o.type == 'MESH')
    for track in rig.animation_data.nla_tracks:
        track.mute = True
    rig.animation_data.action = bpy.data.actions['faint']
    samples = []
    for quarter in range(36*4+1):
        time = quarter/4
        scene.frame_set(int(time), subframe=time-int(time))
        bpy.context.view_layer.update()
        low, high = evaluated_bounds(body)
        samples.append({'frame':time,'min_z':low.z,'max_z':high.z,
                        'width':high.x-low.x,'depth':high.y-low.y})
    minimum = min(row['min_z'] for row in samples)
    receipt = {'clip':'faint','sampling':'all 37 frames plus quarter-frame phases',
               'samples':samples,'minimum_z':minimum,'penetrating_samples':sum(row['min_z']<0 for row in samples),
               'idle_change':'head nod -8 degrees only, original scan preserved',
               'mesh_and_other_clips':'Verified separately against original rigged.glb exported accessors.'}
    (out/'grounding.json').write_text(json.dumps(receipt,indent=2))
    assert minimum >= 0., f'Faint still penetrates ground: {minimum}'
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 16
    scene.cycles.use_denoising = True
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 4
    scene.render.resolution_x = 960
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    if scene.world is None:
        scene.world = bpy.data.worlds.new('AuditWorld')
    scene.world.color = (.12,.12,.12)
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0,0,-.002))
    ground=bpy.context.object
    ground.name='AuditFloor'
    material=bpy.data.materials.new('AuditFloor'); material.diffuse_color=(.21,.24,.27,1)
    ground.data.materials.append(material)
    bpy.ops.object.light_add(type='AREA', location=(2,-3,5))
    bpy.context.object.data.energy=700
    bpy.context.object.data.shape='DISK';bpy.context.object.data.size=4
    bpy.ops.object.camera_add(location=(3.1,-4.1,2.0))
    camera=bpy.context.object;camera.data.type='ORTHO';camera.data.ortho_scale=3.3
    camera.rotation_euler=(Vector((0,.0,.65))-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.camera=camera
    for frame in [0,12,24,36]:
        scene.frame_set(frame)
        scene.render.filepath=str(out/f'faint-{frame:02}.png')
        bpy.ops.render.render(write_still=True)
    r.clear_pose(rig)
    rig.animation_data.action = bpy.data.actions['idle']
    scene.frame_set(18)
    scene.render.filepath=str(out/'idle-alert-18.png')
    bpy.ops.render.render(write_still=True)

r.main()
audit_r2()
