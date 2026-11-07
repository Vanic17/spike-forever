from pathlib import Path
import hashlib, json, statistics
from PIL import Image

root=Path(__file__).resolve().parent.parent
docs=root/'docs'
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
shots=['face','profile','body','wide','hands','clay']
before,after=[read(docs/f'athlete87-{side}-capture.json') for side in ['before','after']]
for key in ['teams','seed','phase','clock','ball','velocity','rng','players','lighting','pose_hash','resolution']:
    assert before[key]==after[key],key
for shot in shots:
    for key in ['eye','focus','fov']:assert before[shot][key]==after[shot][key],(shot,key)
    for side in ['before','after']:
        with Image.open(docs/f'athlete87-{side}-{shot}.png') as im:assert im.size==(1920,1080)
protected=read(root/'.runtime/graphics86-baseline-protected.json')
changed=[name for name,value in protected.items() if sha(root/name).lower()!=value.lower()]
assert not changed,changed
starting=read(root/'.runtime/athlete87-start-hashes.json')
changed_graphics=[name for name,value in starting.items() if sha(root/name)!=value]
assert set(changed_graphics)=={'src/visual_graphics86.gd','src/player_appearance.gd'},changed_graphics
report={'pass':True,'published':False,'one_athlete_only':True,'lighting_identical':True,'pose_identical':True,'protected_files_unchanged':len(protected),'changed_existing_source':changed_graphics,'views':shots,'resolution':[1920,1080],'tests':read(docs/'athlete87-tests.json'),'geometry':read(docs/'athlete87-build.json'),'performance':{}}
for side in ['before','after']:
    runs=[read(docs/f'athlete87-performance-{side}-r{i}.json') for i in range(1,4)]
    assert all(r['contacts']==26 and r['msaa']==2 and r['render_scale']==1 for r in runs)
    report['performance'][side]={}
    for metric,path in {'fps':['mean_fps'],'p99_ms':['frame','p99_ms'],'gpu_ms':['gpu_render_ms','mean_ms'],'memory_bytes':['video_memory_bytes','max'],'draw_calls':['draw_calls','mean'],'primitives':['primitives','mean']}.items():
        values=[]
        for r in runs:
            for key in path:r=r[key]
            values.append(r)
        report['performance'][side][metric]={'mean':statistics.mean(values),'min':min(values),'max':max(values),'stddev':statistics.stdev(values)}
(docs/'athlete87-validation.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf8')
page='''<!doctype html><html lang="it"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Spike Forever — atleta pilota</title>
<style>*{box-sizing:border-box}body{margin:0;background:#0b111b;color:#eef2f8;font:16px system-ui}main{max-width:1550px;margin:auto;padding:30px}h1{font-size:clamp(28px,3vw,46px);margin:8px 0}p{color:#b9c5d6;line-height:1.6;max-width:1000px}.tag{color:#e8bd68;font-size:12px;letter-spacing:2px}nav{display:flex;gap:8px;flex-wrap:wrap;margin:24px 0}button{background:#172334;border:1px solid #3b4a61;border-radius:8px;color:inherit;padding:12px 20px;cursor:pointer}button[aria-pressed=true]{background:#d6b15b;color:#101722;border-color:#d6b15b}#stage{position:relative;aspect-ratio:16/9;border:1px solid #344458;border-radius:12px;overflow:hidden}#stage img{position:absolute;inset:0;width:100%;height:100%;object-fit:contain}#new{clip-path:inset(0 0 0 50%)}#line{position:absolute;top:0;bottom:0;left:50%;width:2px;background:#f4cb70}#labels{display:flex;justify-content:space-between;margin:10px 0;color:#e8bd68}input{width:100%;accent-color:#e8bd68}aside{display:flex;gap:16px;flex-wrap:wrap;margin-top:20px}.card{flex:1;min-width:220px;background:#142031;border-radius:12px;padding:18px}.card strong{display:block;margin-bottom:6px}a{color:#e8bd68}footer{margin-top:24px;color:#9baec4}#caption{min-height:52px}</style>
<main><div class="tag">PROTOTIPO LOCALE · UN SOLO ATLETA · NON PUBBLICATO</div><h1>Il giocatore, a parità di luce</h1><p>Testa anatomica differente e scolpita, palpebre aperte, ciocche tridimensionali, rilievi delle mani, unghie e pieghe della divisa. Le immagini provengono dal gioco: stessa identità, scheletro, posa, camera, luce e stato dello scambio.</p><nav id="views"></nav><div id="labels"><span>PRIMA — prototipo 0.86</span><span>DOPO — atleta pilota</span></div><div id="stage"><img id="old" alt="Giocatore precedente"><img id="new" alt="Nuovo atleta pilota"><div id="line"></div></div><input id="slider" aria-label="Divisore prima dopo" type="range" min="0" max="100" value="50"><p id="caption"></p><aside><div class="card"><strong>Geometria</strong>Nuova testa da fonte locale, ulteriormente scolpita. Capelli e barba con volume reale; mani e divisa modificate nella mesh.</div><div class="card"><strong>Confronto controllato</strong>Le viste grigie nascondono capelli e barba in entrambe le immagini e uniformano il materiale, per confrontare il viso.</div><div class="card"><strong>Ambito</strong>Gli altri undici atleti mantengono il modello precedente. Le scarpe hanno varianti indipendenti. Gameplay e animazioni invariati.</div></aside><footer><a href="ATHLETE_PROTOTYPE_87.md">Rapporto e limiti</a> · <a href="athlete87-validation.json">Misure e verifiche</a><p id="performance"></p></footer></main><script>
const shots=[['face','Volto'],['profile','Profilo'],['body','Corpo intero'],['wide','Gameplay'],['hands','Mani e divisa'],['clay','Geometria grigia']];const notes={face:'Primo piano del viso, con identica illuminazione e posa. Il nuovo groom è un preset pilota, non un ritratto del giocatore reale.',profile:'Profilo: naso, mento, arcata sopraccigliare e volume dei capelli.',body:'Corpo intero: stessa animazione. Le proporzioni del rig e i punti di contatto non vengono modificati.',wide:'Vista durante lo stesso scambio. Le scarpe hanno le stesse varianti cromatiche nei due confronti.',hands:'Dettaglio della mano e della divisa. Sono presenti rilievi geometrici, non soltanto normal map.',clay:'Solo il viso in materiale grigio, senza capelli o barba su entrambe le versioni. Occhi e altri elementi mantengono la posizione della medesima posa.'};
const nav=document.getElementById('views');function select(id){document.querySelectorAll('button').forEach(b=>b.setAttribute('aria-pressed',b.dataset.id===id));document.getElementById('old').src='athlete87-before-'+id+'.png';document.getElementById('new').src='athlete87-after-'+id+'.png';document.getElementById('caption').textContent=notes[id]}for(const [id,label]of shots){const b=document.createElement('button');b.textContent=label;b.dataset.id=id;b.onclick=()=>select(id);nav.appendChild(b)}document.getElementById('slider').oninput=e=>{document.getElementById('new').style.clipPath='inset(0 0 0 '+e.target.value+'%)';document.getElementById('line').style.left=e.target.value+'%'};select('face');</script></html>'''
b=report['performance']['before'];a=report['performance']['after']
text=f"Tre prove per versione, RTX 5080, Forward+, 1920×1080 Alto, 4× MSAA, 120 Hz fisica, VSync disattivato. FPS medi: {b['fps']['mean']:.2f} → {a['fps']['mean']:.2f}. GPU: {b['gpu_ms']['mean']:.3f} → {a['gpu_ms']['mean']:.3f} ms. Il costo riguarda un solo atleta pilota, non un'intera rosa."
page=page.replace('<p id="performance"></p>','<p id="performance">'+text+'</p>')
(docs/'athlete87-review.html').write_text(page,encoding='utf8')
print('ATHLETE87 REVIEW AND INVARIANTS PASS')
