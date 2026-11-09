import json, pathlib, urllib.request, concurrent.futures, statistics, math, hashlib, time, sys
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent))

ROOT=pathlib.Path(__file__).resolve().parents[1]; CACHE=ROOT/'.runtime/condition99/research'
players=[p for t in json.loads((ROOT/'assets/gameplay/league.json').read_text(encoding='utf-8-sig'))['teams'] for p in t['roster']]
def num(x):
    try:return float(x.replace(',','.'))
    except (ValueError,AttributeError):return 0.
def get_games(p,year,serie):
    code=p.get('height_metadata',{}).get('player_url',p.get('appearance',{}).get('photo_source_url','')).rstrip('/').split('/')[-1].split('?')[0]
    if not code or code=='None':return [],None
    url=f'https://ww2.legavolley.it/Statistiche_i.asp?cmd=no_combo2&Fase=1&TipoStat=2.2&Serie={serie}&AnnoInizio={year}&Atleta={code}'
    path=CACHE/f'{code}-{year}-{serie}.html'
    if not path.exists():
        for retry in range(2):
            try:
                data=urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=22).read();path.write_bytes(data);break
            except Exception:
                if retry: return [],{'url':url,'error':'unavailable'}
                time.sleep(.3)
    raw=path.read_bytes(); parser=Tables();parser.feed(raw.decode('cp1252',errors='replace'))
    rows=[r for r in parser.rows if len(r)==23 and num(r[1])>0 and any(w in r[0].lower() for w in ['andata','ritorno'])]
    return rows,{'url':url,'sha256':hashlib.sha256(raw).hexdigest(),'season':f'{year}/{year+1}','series':serie,'appearances':len(rows)}
def observations(rows,role):
    metrics={}
    def add(k,rate,n,noise):metrics.setdefault(k,[]).append((rate,n,noise))
    for r in rows:
        sets=num(r[1]);n=num(r[15]);good=num(r[18]);bad=num(r[16])+num(r[17])
        if n>=(4 if role=='middle_blocker' else 8):
            rate=(good-bad)/n;add('attack',rate,n,max(0,(good+bad)/n-rate*rate)/n)
        n=num(r[9]);good=num(r[12]);bad=num(r[10])+num(r[11])
        if n>=8:
            rate=(good-bad)/n;add('receive',rate,n,max(0,(good+bad)/n-rate*rate)/n)
        n=num(r[4]);errors=num(r[6])
        if n>=5:
            rate=errors/n;add('serve',rate,n,rate*(1-rate)/n)
        if sets>=3:add('block',num(r[21])/sets,sets,num(r[21])/(sets*sets))
    return metrics
WEIGHTS={'outside_hitter':{'attack':.65,'receive':.25,'serve':.1},'opposite':{'attack':.85,'serve':.15},'middle_blocker':{'attack':.65,'block':.25,'serve':.1},'libero':{'receive':1},'setter':{'serve':.7,'block':.3}}
def review(p):
    evidence=[]; pooled={}; usable=0
    for year in [2025,2024,2023]:
        rows,source=get_games(p,year,1)
        if not rows:rows,source=get_games(p,year,2)
        if not rows:continue
        metrics=observations(rows,p['role']);source['usable_metrics']={k:len(v) for k,v in metrics.items()};evidence.append(source)
        for key,values in metrics.items():
            if key not in WEIGHTS[p['role']] or len(values)<4:continue
            # Demean each season. Changes in average ability are not inconsistency.
            centre=sum(v[0]*v[1] for v in values)/sum(v[1] for v in values)
            pooled.setdefault(key,[]).extend((v[0]-centre,v[1],v[2]) for v in values)
        usable+=len(rows)
        sufficient=sum(weight for key,weight in WEIGHTS[p['role']].items() if len(pooled.get(key,[]))>=12 and (key=='block' or sum(v[1] for v in pooled[key])>=(60 if p['role']=='middle_blocker' and key=='attack' else 100)))>=.60
        if len(evidence)>=2 and sufficient:break
    details={};weighted=0;total=0;matches=0
    for key,weight in WEIGHTS[p['role']].items():
        values=pooled.get(key,[])
        if len(values)<12:continue
        attempts=sum(v[1] for v in values)
        if key!='block' and attempts<(60 if p['role']=='middle_blocker' and key=='attack' else 100):continue
        variance=sum(v[0]*v[0]*v[1] for v in values)/attempts
        noise=sum(v[2]*v[1] for v in values)/attempts
        spread=math.sqrt(max(0,variance-.35*noise))
        # Metric units are normalized, not divided by the athlete's skill mean.
        scale={'attack':.18,'receive':.22,'serve':.13,'block':.30}[key]
        weighted+=weight*spread/scale;total+=weight;matches=max(matches,len(values))
        details[key]={'matches':len(values),'opportunities':attempts,'weighted_sd':round(math.sqrt(variance),5),'sampling_noise':round(noise,6),'regularity_spread':round(spread,5)}
    eligible=total>=.60 and matches>=12
    return {'id':p['id'],'name':p['name'],'role':p['role'],'condition_form':'C','score':round(weighted/total,6) if total else None,'eligible':eligible,'confidence':'medium' if eligible and p['role']!='setter' else 'low','metrics':details,'sources':evidence,'basis':'within-player, within-season opportunity-adjusted variability; no overall or average skill used','limitation':'Setter ratings use service/block regularity as a proxy; setting-quality counts are unavailable in these official match logs.' if p['role']=='setter' else ('insufficient match observations: neutral C' if not eligible else '')}
if __name__=='__main__':
    CACHE.mkdir(parents=True,exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        rows=[]
        for i,row in enumerate(pool.map(review,players)):
            rows.append(row)
            if (i+1)%20==0:print('Reviewed',i+1,'/',len(players),flush=True)
    for role in WEIGHTS:
        group=sorted([r for r in rows if r['role']==role and r['eligible']],key=lambda r:r['score'])
        for i,r in enumerate(group):
            q=(i+.5)/len(group)
            r['role_percentile']=round(q,4)
            r['condition_form']='A' if q<=.18 else 'B' if q<=.50 else 'C' if q<=.85 else 'D'
    report={'method':'role-relative, within-player match variability, shrunk for sampling noise; stable ability is not form','reviewed_at':'2026-11-09','players':{r['id']:r for r in rows},'counts':{k:sum(r['condition_form']==k for r in rows) for k in 'ABCD'},'supported':sum(r['eligible'] for r in rows),'total':len(rows)}
    (ROOT/'.runtime/condition99/research-results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps({k:v for k,v in report.items() if k not in ['players']},ensure_ascii=False),flush=True)
