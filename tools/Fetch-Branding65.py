from pathlib import Path
import urllib.request, re, json, concurrent.futures, sys
ROOT=Path(__file__).resolve().parents[1]
CACHE=ROOT/'.runtime/branding65'; CACHE.mkdir(parents=True,exist_ok=True)
def fetch(url):
 return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=40).read()
def inspect(item):
 name,url=item; p=CACHE/(name+'.html')
 if not p.exists(): p.write_bytes(fetch(url))
 s=p.read_text(encoding='utf-8',errors='replace')
 links=re.findall(r'(?:href|src)=[\"\']([^\"\']+)',s)
 selected=[u for u in links if any(k in u.lower() for k in ['logo','superlega','.zip','.eps','.pdf','.ai','.svg'])]
 print(name,json.dumps(list(dict.fromkeys(selected)),ensure_ascii=True))
 return s
if __name__=='__main__':
 if '--download' in sys.argv:
  manifest=json.loads((ROOT/'assets/ui/branding/manifest.json').read_text(encoding='utf-8'))
  def download(item):
   name,row=item; url=row['source_archive']; target=CACHE/(name+'.zip')
   if not target.exists(): target.write_bytes(fetch(url))
   return {'club':name,'url':url}
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
   rows=list(pool.map(download,manifest['clubs'].items()))
  (CACHE/'archives.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
  print('Downloaded',len(rows),'official club packages')
 else: inspect(('media','https://www.legavolley.it/documenti/loghi-lega-e-club'))
