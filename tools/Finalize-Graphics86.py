"""Collect local-only graphics evidence; never publishes or changes game data."""
from pathlib import Path
import hashlib, json, re
from PIL import Image

root = Path(__file__).resolve().parent.parent
docs = root / 'docs'
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(name, data): (docs/name).write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding='utf8')

protected = read(root/'.runtime/graphics86-baseline-protected.json')
changed = [p for p,h in protected.items() if sha(root/p).lower() != h.lower()]
assert not changed, changed
before, after = [read(docs/f'graphics86-{side}-capture.json') for side in ['before','after']]
views = ['wide','player','crowd','court-net','replay','arena']
for k in before:
    if k not in views: assert before[k] == after[k], k
for view in views:
    for key in ['eye','focus','fov']: assert before[view][key] == after[view][key], (view,key)
    for side in ['before','after']:
        with Image.open(docs/f'graphics86-{side}-{view}.png') as im: assert im.size == (1920,1080)
collision = [sha(docs/f'graphics86-collisions-{s}.json') for s in ['before','after']]
assert collision[0] == collision[1]
save('graphics86-invariants.json', {'pass':True,'published':False,'visual_revision':'0.86 prototype','protected_files':len(protected),'changed_protected_files':changed,'game_version':read(root/'version.json'),'identical_capture_state':True,'identical_cameras':views,'capture_resolution':[1920,1080],'collision_sha256':collision[0],'collision_count':len(read(docs/'graphics86-collisions-after.json'))})

tests=[]
for p in sorted((root/'.runtime').glob('Test-*-graphics86.stdout.log')):
    err=p.with_name(p.name.replace('.stdout.','.stderr.'))
    out=p.read_text(encoding='utf8',errors='replace')
    errors=err.read_text(encoding='utf8',errors='replace')
    errors=re.sub(r'ERROR: Failed to read the root certificate store\.\s+at: get_system_ca_certificates[^\n]*','',errors)
    ok='PASS' in out and not re.search(r'ERROR:|SCRIPT ERROR|SHADER ERROR|Parameter .* is null',errors)
    assert ok,p
    tests.append({'suite':p.name.split('-graphics86')[0],'pass':ok})
assert len(tests)==19,len(tests)
for name in ['database','substitutions','replay']:
    assert read(docs/f'graphics86-online-{name}.json')['pass']
roster=(root/'.runtime/graphics86-roster-final.stdout.log').read_text(encoding='utf8',errors='replace')
assert 'GRAPHICS85 TEST PASS' in roster
editor=read(docs/'graphics86-editor-tests.json');assert editor['pass']
save('graphics86-regressions.json',{'pass':True,'offline_suites':tests,'online_pairs':['database','substitutions','replay'],'latest_roster_material_recheck':True,'latest_geometry_test':read(docs/'graphics86-tests.json'),'scene_lifecycle':read(docs/'graphics86-lifecycle.json'),'editor_import_and_two_vulkan_starts':editor})

stage=root/'dist/source-0.85.0-004f633cf8f1489d88b1f0a260bbee38'
files=[]
for p in sorted((root/'src').glob('*')):
    if not p.is_file() or p.suffix=='.uid': continue
    old=stage/'src'/p.name
    if not old.exists() or sha(p)!=sha(old): files.append({'path':p.relative_to(root).as_posix(),'sha256':sha(p),'new':not old.exists()})
for p in sorted((root/'assets/art/visual86').rglob('*')):
    if p.is_file() and p.suffix!='.import': files.append({'path':p.relative_to(root).as_posix(),'sha256':sha(p),'new':True})
save('graphics86-files.json',{'published':False,'baseline':'0.85.0','files':files,'protected_files_verified':len(protected)})

summary=read(docs/'graphics86-performance-summary.json')['versions']
rows=['| Misura | Prima: media (min–max) | Dopo: media (min–max) |','|---|---:|---:|']
for key,label,scale in [('mean_fps','FPS',1),('frame_mean_ms','Frame medio, ms',1),('frame_p95_ms','Frame p95, ms',1),('frame_p99_ms','Frame p99, ms',1),('gpu_mean_ms','GPU media, ms',1),('renderer_cpu_mean_ms','CPU renderer, ms',1),('physics_cpu_mean_ms','CPU simulazione, ms',1),('video_memory_bytes','Memoria video, MiB',1/1048576),('draw_calls','Draw call',1),('primitives','Primitivi, milioni',1/1000000)]:
    cells=[]
    for side in ['before','after']:
        v=summary[side][key];cells.append(f'{v["mean"]*scale:.3f} ({v["min"]*scale:.3f}–{v["max"]*scale:.3f})')
    rows.append('| '+label+' | '+' | '.join(cells)+' |')
soak=read(docs/'graphics86-full-match.json');assert soak['pass']
text=(docs/'GRAPHICS_UPGRADE_86.md').read_text(encoding='utf8')
text=text.replace('{{PERFORMANCE_TABLE}}','\n'.join(rows))
text=text.replace('{{FULL_MATCH_RESULT}}',f'Partita completata **15–2**, {soak["contacts"]} contatti e {soak["frames"]:,} frame in {soak["real_seconds"]:.1f} secondi: frame medio {soak["mean_frame_ms"]:.3f} ms, p99 {soak["p99_frame_ms"]:.3f} ms, {soak["frames_over_25ms"]} frame oltre 25 ms e {soak["frames_over_50ms"]} oltre 50 ms. Questo risultato riguarda lo scenario e il driver di test dichiarati, non ogni possibile partita.')
(docs/'GRAPHICS_UPGRADE_86.md').write_text(text,encoding='utf8')
print('GRAPHICS86 EVIDENCE PASS',len(protected),'protected files;',len(tests),'offline suites; six paired views')
