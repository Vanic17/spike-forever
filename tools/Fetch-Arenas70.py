"""Fetch original sponsor artwork, with a reproducible URL/SHA-256 manifest.
No logos are synthesized. Network is used only by this build-time tool.
"""
from pathlib import Path
import concurrent.futures, hashlib, html, json, re, urllib.request, sys
from urllib.parse import urljoin

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / '.runtime/stadi70'
PAGES = {
 'modena-partners':'https://www.modenavolley.it/partners/',
 'monza-partners':'https://www.verovolley.com/partner/',
 'verona-partners':'https://www.veronavolley.it/it-it/sponsor.aspx',
 'cuneo-partners':'https://cuneovolley.it/sponsor',
 'cisterna-partners':'https://cisternavolley.it/sponsor/',
 'joma':'https://www.joma-sport.com/it_IT/',
 'macron':'https://www.macron.com/it/',
 'mizuno':'https://emea.mizuno.com/eu/it-it/home/',
 'freddy':'https://www.freddy.com/',
 'allianz':'https://www.allianz.it/',
 'homcom':'https://www.aosom.it/',
 'bcc':'https://www.bcccarate.it/',
 'banca-alpi':'https://www.bancaalpimarittime.it/',
 'daken':'https://www.daken.it/',
 'suntory':'https://www.suntory.com/',
 'vim':'https://www.vimsrl.it/',
 'conit':'https://www.conit.it/',
 'airone':'https://www.aironegifts.com/',
}
MARKS = {
 'sir': 'https://www.sirsafetyperugia.it/assets/img/sponsor/sir_rev.png',
 'susa': 'https://www.sirsafetyperugia.it/assets/img/sponsor/susa.png',
 'vim': 'https://monettispa.it/wp-content/uploads/2021/12/vim_logo.svg',
 'itas': 'https://www.trentinovolley.it/wp-content/uploads/2025/02/itamutua.jpg',
 'trentino': 'https://www.trentinovolley.it/wp-content/uploads/2025/02/trentino.jpg',
 'errea': 'https://www.trentinovolley.it/wp-content/uploads/2025/02/errea.jpg',
 'lube': 'https://www.lubevolley.it/public/images/2025-09-15/cucinelube.png',
 'gas-sales': 'https://www.gassalesenergia.it/wp-content/uploads/2026/08/logo-gassales-color.svg',
 'bluenergy': 'https://www.gassalespiacenza.it/wp-content/uploads/2026/07/bluenergy-logo.png',
 'allianz': 'https://cisternavolley.it/wp-content/uploads/2025/01/ALLIANZ.png',
 'homcom': 'https://cdn.verovolley.com/wp-content/uploads/elementor/thumbs/logo-HOMCOM-by-Aosom-rspugaiorq5jzpskye75o39qcsxkpopavc429wcbm8.png',
 'bcc-carate': 'https://cdn.verovolley.com/wp-content/uploads/elementor/thumbs/LOGO_BCC_CARATE-E-TREVIGLIO_SPEC1_COLORE_RGB-r8spvi87hq6i3kpgja0mj3a7by19m3qp9t1p745aw4.png',
 'freddy': 'https://cdn.verovolley.com/wp-content/uploads/2025/07/FREDDY_NEW_LOGO_pos-.png',
 'rana': 'https://www.veronavolley.it/public/img/giovanni-rana-verona-volley-200453.png',
 'airone': 'https://www.veronavolley.it/public/img/logo-sito-partner-airone-191084.jpg',
 'valsa': 'https://www.modenavolley.it/wp/wp-content/uploads/2022/10/ValsaGroup_Logo.jpg',
 'bper': 'https://www.modenavolley.it/wp/wp-content/uploads/2022/10/BPER.jpg',
 'daken': 'https://daken.it/wp-content/uploads/2025/08/Logo_Daken_Nero-01.svg',
 'kioene': 'https://www.pallavolopadova.com/wp-content/uploads/2021/09/KIOENE_LOGO_RGB.png',
 'conit': 'https://cisternavolley.it/wp-content/uploads/2025/01/CONIT.png',
 'gesa': 'https://cisternavolley.it/wp-content/uploads/2025/01/GESA.png',
 'marini': 'https://cisternavolley.it/wp-content/uploads/2025/01/MARINI.png',
 'mizuno': 'https://emea.mizuno.com/on/demandware.static/-/Library-Sites-sharedLibrary_Mizuno/default/dw5ad15025/Campaigns2025/120th-logo.svg',
 'santanna': 'https://cuneovolley.it/storage/images/desktop/202610141523035455_logo-acqua-santanna.png',
 'macron': 'https://cuneovolley.it/storage/images/desktop/202610141525042638_macron.png',
 'tinet': 'https://volleyprata.it/wp-content/uploads/2023/09/tinet.svg',
 'suntory': 'https://upload.wikimedia.org/wikipedia/commons/3/34/SUNTORY_logo.svg',
 'banca-alpi': 'https://www.wownature.eu/wp-content/uploads/2023/07/logo-banca-alpi-marittime.jpeg',
}

def download_mark(item):
 key,url=item
 target=ROOT/'assets/art/arenas70/originals'/(key+('.svg' if '.svg' in url else '.png'))
 try:
  if not target.exists() or '--refresh' in sys.argv: target.write_bytes(fetch(url))
  raw=target.read_bytes()
  return key,{'url':url,'original':target.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(raw).hexdigest()}
 except Exception as exc: return key,{'error':str(exc),'url':url}

def fetch(url):
 return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=30).read()

def inspect(item):
 key,url=item
 try:
  file=CACHE/(key+'.html')
  if not file.exists(): file.write_bytes(fetch(url))
  source=file.read_text(encoding='utf-8',errors='replace')
  refs=[]
  for value in re.findall(r'(?:src|data-src|data-lazy-src|data-lazy-original|href)=["\']([^"\']+)',source):
   value=html.unescape(value)
   if value.startswith('data:'): continue
   if re.search(r'\.(?:svg|png|webp|jpg|jpeg)(?:\?|$)',value,re.I): refs.append(urljoin(url,value))
  refs=list(dict.fromkeys(refs))
  (CACHE/(key+'-assets.json')).write_text(json.dumps(refs,indent=2),encoding='utf-8')
  return key,len(refs)
 except Exception as exc: return key,str(exc)

if __name__=='__main__':
 CACHE.mkdir(parents=True,exist_ok=True)
 if '--download' in sys.argv:
  (ROOT/'assets/art/arenas70/originals').mkdir(parents=True,exist_ok=True)
  with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool: rows=dict(pool.map(download_mark,MARKS.items()))
  # Joma publishes its vector inline instead of as a separate image URL.
  joma_path=ROOT/'assets/art/arenas70/originals/joma.svg'
  if not joma_path.exists():
   source=fetch(PAGES['joma']).decode('utf-8',errors='replace')
   start=source.index('logo-home')
   joma_path.write_text(re.search(r'<svg\b.*?</svg>',source[start:],re.S).group(0),encoding='utf-8')
  rows['joma']={'url':PAGES['joma'],'original':joma_path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(joma_path.read_bytes()).hexdigest(),'method':'Exact inline SVG from official header'}
  (ROOT/'assets/art/arenas70/sources.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
  print(json.dumps({k:v.get('error','OK') for k,v in rows.items()}))
 else:
  with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
   for result in pool.map(inspect,PAGES.items()): print(result)
