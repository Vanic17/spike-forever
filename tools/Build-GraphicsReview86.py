from pathlib import Path
import hashlib, json, statistics

docs=Path('docs')
metrics={'mean_fps':('mean_fps',),'frame_mean_ms':('frame','mean_ms'),'frame_p95_ms':('frame','p95_ms'),'frame_p99_ms':('frame','p99_ms'),'gpu_mean_ms':('gpu_render_ms','mean_ms'),'renderer_cpu_mean_ms':('renderer_cpu_ms','mean_ms'),'physics_cpu_mean_ms':('physics_tick_cpu','mean_ms'),'video_memory_bytes':('video_memory_bytes','max'),'draw_calls':('draw_calls','mean'),'primitives':('primitives','mean')}
summary={'runs_per_version':3,'hardware':'RTX 5080 / NVIDIA 621.01 / Godot 4.5.1 Forward+','conditions':'1920x1080, high, 100% 3D, MSAA 4x, no VSync, uncapped, 4s warmup + 16s measurement, receive-set-pipe, 26 contacts/run','versions':{}}
for side in ['before','after']:
    runs=[json.loads((docs/f'graphics86-performance-{side}-high-r{i}.json').read_text()) for i in range(1,4)]
    for run in runs:
        assert run['render_scale']==1 and run['msaa']==2 and run['contacts']==26
    values={}
    for key,path in metrics.items():
        samples=[]
        for run in runs:
            value=run
            for part in path:value=value[part]
            samples.append(value)
        values[key]={'mean':statistics.mean(samples),'min':min(samples),'max':max(samples),'sample_stddev':statistics.stdev(samples)}
    summary['versions'][side]=values
    aggregate=json.loads(json.dumps(runs[0]))
    for path in metrics.values():
        samples=[]
        for run in runs:
            value=run
            for part in path:value=value[part]
            samples.append(value)
        target=aggregate
        for part in path[:-1]:target=target[part]
        target[path[-1]]=statistics.mean(samples)
    (docs/f'graphics86-performance-{side}-summary.json').write_text(json.dumps(aggregate,indent=2),encoding='utf8')
(docs/'graphics86-performance-summary.json').write_text(json.dumps(summary,indent=2),encoding='utf8')

# Reuse the established local review layout; only the evidence and labels differ.
template=Path('tools/Build-GraphicsReview85.py').read_text(encoding='utf8')
template=template.replace('graphics85-performance-before-high.json','graphics86-performance-before-summary.json').replace('graphics85-performance-after-high.json','graphics86-performance-after-summary.json')
template=template.replace('graphics85-','graphics86-').replace('GRAPHICS_UPGRADE_85.md','GRAPHICS_UPGRADE_86.md').replace('0.84.0','0.85.0')
exec(compile(template,'review_layout86','exec'),{})
p=docs/'graphics86-review.html';page=p.read_text(encoding='utf8')
page=page.replace('PATCH 0.85.0 · VALIDAZIONE','PROTOTIPO 0.86 · SOLO LOCALE')
page=page.replace('Incluso nella patch 0.85.0 insieme alla correzione di importazione audio.','Prototipo grafico locale basato sulla 0.85.0. Non pubblicato su GitHub.')
page=page.replace("['replay','Replay']","['replay','Replay'],['arena','Palazzetto']")
page=page.replace('Mesh e rig dei giocatori conservati. I limiti delle forme e delle texture facciali originali restano dichiarati nel rapporto.','Rig e animazioni conservati. Un solo atleta usa geometria rifinita: non è una nuova scansione facciale. Nel rapporto sono distinti risultati, limiti e nuovi asset necessari.')
page=page.replace('<nav aria-label="Inquadrature" id="views"></nav>','<nav aria-label="Inquadrature" id="views"></nav><div class="slider"><label for="phase">Versione dopo:</label><select id="phase" style="padding:10px;background:#142335;color:#edf2f7;border:1px solid #2d4358;border-radius:8px"><option value="after">Prototipo completo</option><option value="lighting">Solo distribuzione della luce</option><option value="prototype">Luce + atleta pilota</option></select></div>')
page=page.replace('const scenes=',"const phase=document.getElementById('phase');let activeScene='wide';const scenes=")
page=page.replace('function select(id){for', 'function select(id){activeScene=id;for')
page=page.replace("(k==='old'?'before':'after')","(k==='old'?'before':phase.value)")
page=page.replace("select('wide');</script>","phase.onchange=()=>select(activeScene);select('wide');</script>")
b=summary['versions']['before']['mean_fps'];a=summary['versions']['after']['mean_fps']
note=f'Tre esecuzioni per versione. FPS medi delle singole prove: prima {b["min"]:.2f}–{b["max"]:.2f}; dopo {a["min"]:.2f}–{a["max"]:.2f}. Il costo GPU aumenta leggermente: non viene dichiarato un aumento generale delle prestazioni.'
page=page.replace('una misura locale, non una garanzia su altri PC',note+' Una piattaforma locale, non una garanzia su altri PC')
page=page.replace('I confronti mantengono','I confronti mantengono')
p.write_text(page,encoding='utf8')
print('GRAPHICS86 REVIEW READY / six views / three stages / repeated measurements')
