"""Import 2026/27 fixtures as facts; never import real-life results.

Public source HTML stays in .runtime only. The game ships normalized fixture
facts, URL/hash provenance, and independent source-tuple comparisons.
"""
from pathlib import Path
from datetime import date
from collections import Counter
import urllib.request, json, re, html, hashlib
ROOT=Path(__file__).resolve().parents[1]
CACHE=ROOT/'.runtime/career66-source'; CACHE.mkdir(parents=True,exist_ok=True)
DEST=ROOT/'data/competitions'; DEST.mkdir(parents=True,exist_ok=True)
PRIMARY='https://ww2.legavolley.it/Calendario.asp?Anno=2026&IdCampionato=999&IdFase={phase}&IdSquadra=0'
COMPARE='https://www.dallarivolley.com/it-it/i-calendari-dei-campionati-di-serie-a-maschili-202627.aspx'
FORMULA='https://www.legavolley.it/formula-superlega-2026-27/'
VERIFIED='2026-10-29'
MONTHS={name.lower():i+1 for i,name in enumerate(['Gennaio','Febbraio','Marzo','Aprile','Maggio','Giugno','Luglio','Agosto','Settembre','Ottobre','Novembre','Dicembre'])}

def fetch(name,url):
    path=CACHE/(name+'.html')
    if not path.exists(): path.write_bytes(urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=45).read())
    return path.read_bytes()

def strip(text): return re.sub(r'\s+',' ',html.unescape(re.sub('<[^>]*>',' ',text))).strip()
def normalized(text): return strip(text).replace('’',"'").replace('Cuneo Volley',"Acqua Sant'Anna Cuneo").lower()
teams=json.loads((ROOT/'assets/gameplay/league.json').read_text(encoding='utf-8'))['teams']
ids={normalized(t['name']):t['id'] for t in teams}
def team_id(name): return ids[normalized(name)]
def day(text):
    m=re.search(r'(\d{1,2})\s+(\w+)\s+(20\d\d)',text,re.I)
    if m: return date(int(m[3]),MONTHS[m[2].lower()],int(m[1])).isoformat()
    raise ValueError('Missing date '+text)

fixtures=[]; sources=[]
for phase,name in [(1,'calendar'),(2,'return')]:
    url=PRIMARY.format(phase=phase); raw=fetch(name,url); text=raw.decode('windows-1252',errors='replace')
    sources.append({'url':url,'sha256':hashlib.sha256(raw).hexdigest(),'verified_at':VERIFIED})
    for table in re.split(r'<table\b[^>]*\bId="GareGiornata"[^>]*>',text,flags=re.I):
        header=re.search(r'<span>(\d+)(?:ª|&ordf;) Giornata (Andata|Ritorno)\s*-(.*?)</span>',table,re.I|re.S)
        if not header: continue
        round_no=int(header[1])+(11 if phase==2 else 0)
        original=day(strip(header[3])); baseline_time=re.search(r'Ore\s*(\d\d:\d\d)',strip(header[3]))
        for row in re.findall(r'<tr\b[^>]*\bId="EvenRow"[^>]*>(.*?)</tr>',table,re.I|re.S):
            cells=re.findall(r'<td\b[^>]*>(.*?)</td>',row,re.I|re.S)
            assert len(cells)==7,(round_no,len(cells))
            cells=list(map(strip,cells)); notes=cells[6]
            actual=re.search(r'(\d{1,2})/(\d{1,2})/(20\d\d)',notes)
            scheduled=date(int(actual[3]),int(actual[2]),int(actual[1])).isoformat() if actual else original
            time=re.search(r'Ore\s*(\d\d:\d\d)',notes) or baseline_time
            fixtures.append({'id':'sl2026-'+cells[0].zfill(3),'competition':'regular','round':round_no,'home':team_id(cells[1]),'away':team_id(cells[3]),'original_date':original,'scheduled_date':scheduled,'kickoff_time':time[1] if time else '', 'venue':cells[5], 'source_url':url,'verified_at':VERIFIED,'official':True,'status':'scheduled'})

assert len(fixtures)==132,len(fixtures)
fixtures.sort(key=lambda f:(f['round'],f['id']))
for n in range(1,23):
    games=[f for f in fixtures if f['round']==n]
    assert len(games)==6
    assert len({t for f in games for t in [f['home'],f['away']]})==12
assert len({(f['home'],f['away']) for f in fixtures})==132
home=Counter(f['home'] for f in fixtures); away=Counter(f['away'] for f in fixtures)
assert set(home.values())=={11} and set(away.values())=={11}

# Independent published calendar includes all132, with Cuneo's pre-sponsor name.
raw=fetch('compare',COMPARE); text=raw.decode('utf-8',errors='replace')
start=text.index('CALENDARIO SUPERLEGA CREDEM BANCA 2026/2027')
end=text.find('CALENDARIO SERIE A2',start)
text=html.unescape(re.sub('<[^>]*>','\n',text[start:end if end!=-1 else None]))
lines=[re.sub(r'\s+',' ',s).strip() for s in text.splitlines() if s.strip()]
comparison=[]; round_no=0
for line in lines:
    if line.startswith('Giornata '): round_no=int(re.search(r'Giornata (\d+)',line)[1])
    if ' - ' in line:
        a,b=line.split(' - ',1)
        if normalized(a) in ids and normalized(b) in ids: comparison.append((round_no,team_id(a),team_id(b)))
actual=[(f['round'],f['home'],f['away']) for f in fixtures]
assert len(comparison)==132,len(comparison)
assert sorted(actual)==sorted(comparison),'Independent pairing/round mismatch'
signature=hashlib.sha256(json.dumps(sorted(actual),separators=(',',':')).encode()).hexdigest()
report={'fixtures':132,'teams':12,'rounds':22,'games_per_team':22,'home_per_team':11,'away_per_team':11,'all_pairings_crosschecked':True,'results_imported':False,'tuple_sha256':signature,'comparison_url':COMPARE,'comparison_source_sha256':hashlib.sha256(raw).hexdigest(),'official_sources':sources,'verified_at':VERIFIED}
data={'schema_version':1,'season':'2026/27','timezone':'Europe/Rome','official':True,'verified':True,'sources':sources,'comparison':report,'fixtures':fixtures}
(DEST/'superlega_2026_27.json').write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
(ROOT/'docs/career66-calendar-validation.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
# Source tuple facts are retained separately for an offline all-pair test.
(DEST/'superlega_2026_27_source_tuples.json').write_text(json.dumps({'source_url':COMPARE,'source_sha256':hashlib.sha256(raw).hexdigest(),'tuples':comparison},indent=2)+'\n',encoding='utf-8')
print('CALENDAR66 PASS 132 official fixtures, all132 independent pair/round matches,11home/11away, noresults',signature)
