"""Build the review from actual engine captures and completed validation logs."""
from pathlib import Path
import hashlib
import json
import re
import statistics

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / 'docs'


def read(name):
    return json.loads((ROOT / name).read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


protected = read('.runtime/graphics86-baseline-protected.json')
changes = [n for n, h in protected.items() if digest(ROOT / n).lower() != h.lower()]
assert changes == ['version.json'], changes
before = read('docs/athlete88-after-capture.json')
after = read('docs/graphics89-after-capture.json')
for key in ['teams', 'seed', 'phase', 'clock', 'ball', 'velocity', 'rng',
            'players', 'lighting', 'pose_hash', 'resolution', 'quality']:
    assert before[key] == after[key], key
views = ['wide', 'arena', 'crowd', 'court-net', 'face', 'profile', 'body', 'hands', 'clay']
for view in views:
    for key in ['eye', 'focus', 'fov']:
        assert before[view][key] == after[view][key], (view, key)
    assert (DOCS / f'athlete88-after-{view}.png').is_file()
    assert (DOCS / f'graphics89-after-{view}.png').is_file()

suites = ['Graphics86', 'Graphics85', 'Settings53', 'ControllerSettings53', 'Fluidity84',
          'SetterPose81', 'Setter81', 'LegendInputs75', 'LegendServe81', 'Attack80',
          'Defense80', 'Arena82', 'Arenas70', 'Kits45', 'Replay65', 'ReplayEvents65',
          'Bench71', 'CareerPlayed66', 'CareerEngine66']
for suite in suites:
    stem = ROOT / f'.runtime/Test-{suite}-graphics89-current'
    out = Path(str(stem) + '.stdout.log').read_text(encoding='utf-8-sig')
    err = Path(str(stem) + '.stderr.log').read_text(encoding='utf-8-sig')
    err = re.sub(r'ERROR: Failed to read the root certificate store\.\s+at: get_system_ca_certificates[^\n]*', '', err)
    assert 'PASS' in out, suite
    assert not re.search(r'ERROR:|SCRIPT ERROR|SHADER ERROR|Parse Error', err), (suite, err)

reports = {}
for name in ['presets', 'lifecycle', 'editor-tests', 'full-match',
             'online-database', 'online-substitutions', 'online-replay']:
    reports[name] = read(f'docs/graphics89-{name}.json')
    assert reports[name].get('pass', False), name
collision = read('docs/graphics89-collisions-after.json')
collision_before = read('docs/graphics86-collisions-before.json')
assert collision == collision_before, 'Collision shapes changed'
performance = {}
for preset in range(4):
    runs = [read(f'docs/graphics89-performance-p{preset}-r{i}.json')
            for i in (range(1, 4) if preset == 2 else [1])]
    assert all(r['contacts'] == 26 for r in runs)
    performance[str(preset)] = {'runs': len(runs), 'raw': runs}
    for metric, keys in {'fps': ['mean_fps'], 'gpu_ms': ['gpu_render_ms', 'mean_ms'],
                         'p99_ms': ['frame', 'p99_ms'],
                         'engine_memory_bytes': ['video_memory_bytes', 'max']}.items():
        values = []
        for run in runs:
            value = run
            for key in keys:
                value = value[key]
            values.append(value)
        performance[str(preset)][metric] = {'mean': statistics.mean(values),
            'min': min(values), 'max': max(values),
            'stddev': statistics.stdev(values) if len(values) > 1 else None}
report = {'pass': True, 'version': '0.89.0', 'integrated_in_main_game': True,
          'protected_files_checked': len(protected), 'unchanged': len(protected) - 1,
          'intentional_metadata_change': changes, 'pose_camera_lighting_identical_to_88': True,
          'core_suites': suites, 'reports': reports, 'collisions': collision,
          'performance': performance,
          'limits': ['Benchmarks on RTX 5080, not emulated low-end hardware.',
                     'High: three repeats; other presets: one descriptive run each.',
                     'Engine resource cache can retain allocations between scenes.',
                     'Online tests are loopback host/guest, not Internet latency tests.',
                     'Only the pilot slot and two male crowd variants use scan anatomy.'],
          'update_preservation': {'selective_fixtures': 7, 'result': 'PASS',
              'logs': ['.runtime/graphics89-selective-update.stdout.log',
                       '.runtime/graphics89-update-data.stdout.log']}}
for name in report['update_preservation']['logs']:
    content = (ROOT / name).read_bytes()
    decoded = content.decode('utf-16' if content.startswith(b'\xff\xfe') else 'utf-8-sig')
    if 'selective-update' in name:
        fixture_result = json.loads(decoded.strip().splitlines()[-1])
        assert fixture_result['pass'] and len(fixture_result['cases']) == 7
    else:
        assert 'UPDATE75 PASS' in decoded
(DOCS / 'graphics89-validation.json').write_text(json.dumps(report, indent=2), encoding='utf-8')

page = '''<!doctype html><html lang="it"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Spike Forever 0.89 - confronto grafico</title>
<style>*{box-sizing:border-box}body{margin:0;background:#09121e;color:#edf3fa;font:16px system-ui}main{max-width:1550px;margin:auto;padding:28px}h1{font-size:clamp(28px,3vw,45px)}p{color:#b8c7db;line-height:1.6}nav{display:flex;gap:8px;flex-wrap:wrap;margin:18px 0}button,select{background:#172b40;color:inherit;padding:12px;border:1px solid #506078;border-radius:8px;cursor:pointer}button[aria-pressed=true]{background:#ddb765;color:#102033}#stage{position:relative;aspect-ratio:16/9;overflow:hidden;border:1px solid #586477;border-radius:12px}#stage img{position:absolute;width:100%;height:100%;object-fit:contain}#new{clip-path:inset(0 0 0 50%)}#line{position:absolute;left:50%;height:100%;width:2px;background:#ffcd70}input{width:100%;accent-color:#ddb765}.labels{display:flex;justify-content:space-between;margin:12px 0;color:#edc478}a{color:#edc478}table{border-collapse:collapse;width:100%;margin:25px 0}td,th{padding:12px;border-bottom:1px solid #34465a;text-align:left}#quality{width:100%;border-radius:12px}.tag{color:#edc478;letter-spacing:2px;font-size:12px}</style>
<main><div class="tag">0.89.0 / GIOCO PRINCIPALE</div><h1>Palazzetto, personaggi e qualit&agrave; scalabile</h1>
<p>Immagini catturate dal gioco. Il confronto con il prototipo 0.88 mantiene identiche posa, camera, illuminazione, impostazioni Ultra e stato della simulazione. Il confronto storico con la 0.85 include anche le revisioni di illuminazione precedenti: non &egrave; una misura della sola geometria.</p>
<select id="baseline" aria-label="Versione di confronto"><option value="88">Confronto controllato: prototipo 0.88</option><option value="85">Confronto storico: versione pubblicata 0.85</option></select><nav id="views"></nav>
<div class="labels"><span id="oldLabel">PRIMA / PROTOTIPO 0.88</span><span>DOPO / GIOCO PRINCIPALE 0.89</span></div><div id="stage"><img id="old" alt="Prima"><img id="new" alt="Dopo"><div id="line"></div></div><input id="slider" type="range" min="0" max="100" value="50" aria-label="Divisore prima dopo">
<h2>Quattro preset, risorse realmente diverse</h2><p>Stessa scena, stesso stato di gioco. Basso riduce geometria, texture, densit&agrave; del pubblico, effetti e dettagli. Le impostazioni personalizzate restano disponibili.</p><nav id="presets"></nav><img id="quality" alt="Preset grafico"><p id="stats"></p>
<table><thead><tr><th>Preset</th><th>Texture volto</th><th>Triangoli testa</th><th>Spettatori</th><th>GPU media</th><th>Memoria del motore</th></tr></thead><tbody>ROWS</tbody></table>
<p>1920 &times; 1080, Forward+, RTX 5080. Alto: tre misure; gli altri: una misura descrittiva ciascuno. Non sono test di PC meno potenti. La memoria indicata &egrave; un'allocazione del motore, non la memoria totale del driver. La cache pu&ograve; trattenere risorse dopo un cambio di preset.</p>
<p><a href="GRAPHICS_89.md">Rapporto tecnico</a> &middot; <a href="graphics89-validation.json">Verifiche complete</a> &middot; <a href="athlete88-review.html">Evoluzione geometrica del volto</a> &middot; <a href="../assets/art/athlete88/ATTRIBUTION.md">Scansione e attribuzione</a></p></main>
<script>
const views=[['wide','Gameplay'],['arena','Palazzetto'],['crowd','Pubblico'],['court-net','Campo e rete'],['face','Volto'],['profile','Profilo'],['body','Corpo'],['hands','Mani e tessuto'],['clay','Geometria']];let shot='wide';
function show(id){shot=id;const historic=document.querySelector('#baseline').value==='85';const permitted=['wide','arena','crowd','court-net'];if(historic&&!permitted.includes(id))shot='wide';document.querySelector('#old').src=historic?'graphics86-before-'+shot+'.png':'athlete88-after-'+shot+'.png';document.querySelector('#new').src='graphics89-after-'+shot+'.png';document.querySelector('#oldLabel').textContent=historic?'PRIMA / VERSIONE 0.85':'PRIMA / PROTOTIPO 0.88';document.querySelectorAll('#views button').forEach(b=>{b.disabled=historic&&!permitted.includes(b.dataset.id);b.setAttribute('aria-pressed',b.dataset.id===shot)})}
for(const[id,label]of views){const b=document.createElement('button');b.textContent=label;b.dataset.id=id;b.onclick=()=>show(id);document.querySelector('#views').appendChild(b)}document.querySelector('#baseline').onchange=()=>show(shot);document.querySelector('#slider').oninput=e=>{document.querySelector('#new').style.clipPath='inset(0 0 0 '+e.target.value+'%)';document.querySelector('#line').style.left=e.target.value+'%'};show('wide');
const data=PRESETS;const names=['Basso','Medio','Alto','Ultra'];function quality(i){document.querySelector('#quality').src='graphics89-preset-'+i+'.png';const d=data[i];document.querySelector('#stats').textContent=names[i]+' / testa '+d.head_triangles.toLocaleString('it-IT')+' triangoli / texture '+d.texture_width+' px / pubblico '+d.crowd_visible+' / scala rendering '+Math.round(d.render_scale*100)+'%';document.querySelectorAll('#presets button').forEach((b,n)=>b.setAttribute('aria-pressed',n===i))}names.forEach((n,i)=>{const b=document.createElement('button');b.textContent=n;b.onclick=()=>quality(i);document.querySelector('#presets').appendChild(b)});quality(2);
</script></html>'''
presets = reports['presets']['presets']
rows = []
for i, name in enumerate(['Basso', 'Medio', 'Alto', 'Ultra']):
    p, perf = presets[i], performance[str(i)]
    rows.append(f"<tr><td>{name}</td><td>{p['texture_width']}</td><td>{p['head_triangles']:,}</td><td>{p['crowd_visible']}</td><td>{perf['gpu_ms']['mean']:.2f} ms</td><td>{perf['engine_memory_bytes']['mean']/1048576:.0f} MiB</td></tr>")
page = page.replace('ROWS', ''.join(rows)).replace('PRESETS', json.dumps(presets))
(DOCS / 'graphics89-review.html').write_text(page, encoding='utf-8')
print('GRAPHICS89 REVIEW AND VALIDATION PASS')
