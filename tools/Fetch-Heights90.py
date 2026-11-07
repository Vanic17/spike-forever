"""Collect official heights without modifying the database; exact player IDs first."""
from pathlib import Path
import concurrent.futures,datetime,hashlib,html,json,re,urllib.request,unicodedata
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'.runtime/heights90';OUT.mkdir(parents=True,exist_ok=True)
db=json.loads((ROOT/'assets/gameplay/league.json').read_text(encoding='utf-8-sig'))
def text(s):return ' '.join(html.unescape(re.sub('<[^>]+>',' ',s)).split())
def normal(s):return ''.join(c for c in unicodedata.normalize('NFKD',s).casefold() if c.isalnum())
def fetch(team):
    url=team['roster'][0]['jersey_number_metadata']['source_url']
    cache=OUT/(team['id']+'.html')
    raw=cache.read_bytes() if cache.exists() else urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=45).read()
    (OUT/(team['id']+'.html')).write_bytes(raw)
    rows=[]
    for tr in re.findall(r'<tr\b[^>]*class="Dettaglio[^"]*".*?</tr>',raw.decode('utf8',errors='replace'),re.S|re.I):
        keys=re.findall(r'/player/([A-Za-z0-9_-]+)',tr)
        if not keys:continue
        cells=[text(td) for td in re.findall(r'<td\b[^>]*>(.*?)</td>',tr,re.S|re.I)]
        heights=[int(c) for c in cells if re.fullmatch(r'\d{3}',c) and 150<=int(c)<=230]
        if len(set(heights))!=1:continue
        rows.append({'key':keys[0].upper(),'height_cm':heights[0],'row':cells,'source_url':url,'player_url':'https://www.legavolley.it/player/'+keys[0],'page_sha256':hashlib.sha256(raw).hexdigest()})
    result=[]
    for p in team['roster']:
        key=str(p.get('appearance',{}).get('photo_source_url') or '').rstrip('/').split('/')[-1].upper()
        matches=[r for r in rows if r['key']==key]
        if len(matches)!=1:
            matches=[r for r in rows if all(normal(n) in normal(' '.join(r['row'])) for n in p['name'].split())]
        result.append({'id':p['id'],'name':p['name'],'team':team['id'],'evidence':matches[0] if matches and len(set(r['height_cm'] for r in matches))==1 else None})
    print(team['id'],sum(bool(r['evidence']) for r in result),'/',len(result),flush=True)
    return result
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    records=[r for rows in pool.map(fetch,db['teams']) for r in rows]
report={'checked_at':datetime.date(2026,11,7).isoformat(),'source':'Official Lega Volley team roster height column, exact athlete ID match','players':records,'complete':all(r['evidence'] for r in records)}
(OUT/'evidence.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf8')
print('TOTAL',sum(bool(r['evidence']) for r in records),'/',len(records),'UNRESOLVED',[(r['name'],r['id']) for r in records if not r['evidence']])
