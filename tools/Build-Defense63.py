import json, re, html, unicodedata, pathlib, statistics
from html.parser import HTMLParser
ROOT=pathlib.Path(__file__).resolve().parents[1]
SOURCES={'2025':'https://en.volleyballworld.com/volleyball/competitions/superlega/2025-2026/statistics/best-diggers/','vnl':'https://en.volleyballworld.com/volleyball/competitions/volleyball-nations-league/statistics/men/best-diggers/'}
for label,url in SOURCES.items():
    cached=ROOT/f'.runtime/diggers63-{label}.html'
    if not cached.exists():
        import urllib.request
        cached.parent.mkdir(parents=True,exist_ok=True)
        cached.write_bytes(urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=45).read())
class Table(HTMLParser):
    def __init__(self): super().__init__(); self.rows=[]; self.row=None; self.cell=None; self.link=''
    def handle_starttag(self,t,a):
        if t=='tr':
            self.handle_endtag('td'); self.handle_endtag('tr'); self.row=[]
        if t=='td' and self.row is not None:
            self.handle_endtag('td'); self.cell=[]
        if t=='a' and self.cell is not None: self.link=dict(a).get('href','')
    def handle_data(self,d):
        if self.cell is not None: self.cell.append(d)
    def handle_endtag(self,t):
        if t=='td' and self.cell is not None: self.row.append(' '.join(''.join(self.cell).split())); self.cell=None
        if t=='tr' and self.row is not None:
            if len(self.row)>=9: self.rows.append(self.row)
            self.row=None
def norm(s): return re.sub('[^a-z0-9]','',unicodedata.normalize('NFKD',s).encode('ascii','ignore').decode().lower())
data=json.loads((ROOT/'assets/gameplay/league.json').read_text(encoding='utf-8'))
tables=[]
for season in ['2025','vnl']:
    p=Table(); p.feed((ROOT/f'.runtime/diggers63-{season}.html').read_text(encoding='utf-8-sig'))
    tables.append(p.rows)
print('Official rows', [len(t) for t in tables])
if not tables[0]: raise RuntimeError('No actual official defense rows parsed')
print(tables[0][:2])
if '--inspect' in __import__('sys').argv: raise SystemExit
# Conservative role priors, independently of reception. Sample-size shrinkage
# prevents a reserve's ten lucky digs from outranking a full-season libero.
priors={'libero':88,'outside_hitter':76,'setter':70,'opposite':65,'middle_blocker':53}
aliases={'robertlandysimon':'simon','tommasoichino':'ichino','lukasporro':'porrol','paoloporro':'porrop','aleksandarnikolov':'anikolov','simonnikolov':'snikolov','vukasinmasulovic':'masulovicv','nemanjamasulovic':'masulovicn','flaviogualberto':'flavio','fernandogilkreling':'cachopa','youssefoussamarabbenntara':'bentara','wassimben tara':'bentara'}
aliases.update({'lucaporro':'porrol','simeonnikolov':'snikolov','flavioresendegualberto':'flavio','wassimbentara':'bentara','josemiguelgutierrez':'jgutierrez','poriyahosseinkhanzadeh':'poriya','iliyapetkov':'ipetkov','arthurbento':'arthur'})
vnl_aliases={'alessandromichieletto':'michieletto','simeonnikolov':'snikolov','shikunpeng':'pengshikun','lucaporro':'porrol','flavioresendegualberto':'flavio','arthurbento':'arthur'}
report=[]
for team in data['teams']:
    for p in team['roster']:
        name=norm(p['name']); surname=norm(p['name'].split()[-1]); wanted=aliases.get(name,surname)
        observations=[]
        for si,rows in enumerate(tables):
            lookup=vnl_aliases.get(name,wanted) if si==1 else wanted
            matches=[r for r in rows if norm(r[1])==lookup]
            if len(matches)!=1: continue
            r=matches[0]
            try: digs=float(r[3]); total=float(r[8]); success=float(r[7]); per_match=float(r[6])
            except ValueError: continue
            if total<=0: continue
            # Separate success/control from opportunity/volume. Digs/match
            # is used with a small weight, never as a raw totals ranking.
            prior=priors.get(p['role'],65)
            control=max(0,min(1,(success-20)/45))
            volume=max(0,min(1,per_match/7.0))
            measured=48+control*33+volume*15
            weight=(total/(total+90))*(1 if si==0 else .65)
            observations.append((measured,weight,{'competition':'SuperLega 2025-2026' if si==0 else 'VNL 2026','name':r[1],'digs':digs,'attempts':total,'success_percent':success,'digs_per_match':per_match}))
        prior=priors.get(p['role'],65)
        if observations:
            w=sum(o[1] for o in observations); value=round((prior+sum(o[0]*o[1] for o in observations))/(1+w))
            confidence='medium' if any(o[2]['attempts']>=100 for o in observations) else 'low'
        else:
            # No fabricated scouting claims: use the existing individual
            # rating only as a weak prior and mark the result as estimated.
            value=round(prior*.8+float(p['ratings'].get('generale',prior))*.2); confidence='low'
        p['ratings']['difesa']=max(0,min(99,value))
        p.setdefault('ratings_metadata',{})['difesa']={'method':'official-dig-control-shrunk-to-role-prior-v1' if observations else 'role-and-existing-overall-prior-only','confidence':confidence,'observations':[o[2] for o in observations]}
        report.append({'id':p['id'],'name':p['name'],'role':p['role'],'defense':p['ratings']['difesa'],'confidence':confidence,'data':bool(observations)})
(ROOT/'assets/gameplay/league.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
source_urls=['https://en.volleyballworld.com/volleyball/competitions/superlega/2025-2026/statistics/best-diggers/','https://en.volleyballworld.com/volleyball/competitions/volleyball-nations-league/statistics/men/best-diggers/']
import hashlib
source_hashes={s:hashlib.sha256((ROOT/f'.runtime/diggers63-{s}.html').read_bytes()).hexdigest() for s in ['2025','vnl']}
(ROOT/'docs/defense63-ratings.json').write_text(json.dumps({'sources':source_urls,'source_sha256':source_hashes,'method':'Editorial 0-99 estimates: successful dig control and digs/match, sample-size shrinkage to role priors; VNL evidence weighted 0.65. Non-matched players explicitly estimated, never official ratings. Source dates 2026-10-27.','formula':{'role_priors':priors,'measurement':'48+33*clamp((success_percent-20)/45)+15*clamp(digs_per_match/7)','weight':'attempts/(attempts+90), x0.65 for VNL','matched':'(role_prior+sum(measurement*weight))/(1+sum(weight))','unmatched':'0.8*role_prior+0.2*existing_overall'},'players':report},ensure_ascii=False,indent=2),encoding='utf-8')
print('Rated',len(report),'with actual data',sum(r['data'] for r in report))
