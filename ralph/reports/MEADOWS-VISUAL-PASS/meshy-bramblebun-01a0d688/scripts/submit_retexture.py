"""One Meshy retexture task for bramblebun_redesign, via tools/art_pipeline/meshy.py's own request/data_uri helpers.
Differs from `meshy.py texture` only in: agent-drafted style image, enable_original_uv=True (keep shipped UVs so the
texture can drop onto the existing rigged mesh), and a species-specific texture prompt. Key comes from env only."""
import sys, json, base64, pathlib, time
sys.path.insert(0, '/home/user/tetherbound/tools/art_pipeline')
import meshy
MODEL = pathlib.Path('/home/user/tetherbound/assets/creatures/tetherbound/bramblebun_redesign/models/creature_bramblebun_redesign_lod0.glb')
STYLE = pathlib.Path(__file__).parent / 'ref' / 'bramblebun_style_ref_final.png'
PROMPT = ("Stylized game creature texture for a jackalope-like hare: clean flat hand-painted colour blocks, "
          "warm russet-chestnut coat, cream-white chest, muzzle and toe tips, soft pink inner ears, dark bark-brown "
          "twig antlers, a few clean leaf-green moss leaves on the shoulders, large glossy dark eyes. "
          "Smooth even fur colour, no noise, no speckles, no scribbled lines, no baked shadows")
payload = {
    "model_url": "data:model/gltf-binary;base64," + base64.b64encode(MODEL.read_bytes()).decode(),
    "text_style_prompt": PROMPT[:600],
    "image_style_url": meshy.data_uri(STYLE),
    "enable_pbr": True,
    "enable_original_uv": True,
    "texture_resolution": "2k",
    "ai_model": "latest",
}
submitted = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
result = meshy.request("POST", meshy.ENDPOINTS["texture"], payload)
task_id = result.get("result") or result.get("id")
rec = {"task_id": task_id, "submitted_utc": submitted, "endpoint": meshy.ENDPOINTS["texture"],
       "model": str(MODEL), "style_image": str(STYLE), "text_style_prompt": PROMPT,
       "enable_pbr": True, "enable_original_uv": True, "texture_resolution": "2k", "ai_model": "latest"}
(pathlib.Path(__file__).parent / 'submission.json').write_text(json.dumps(rec, indent=2))
print("texture task:", task_id)
