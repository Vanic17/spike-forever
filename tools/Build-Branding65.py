"""Faithful rasterization of official vector artwork; no generative redraw."""
from pathlib import Path
import zipfile,io,json,hashlib,urllib.request
import pymupdf as fitz
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1]; cache=R/'.runtime/branding65'; out=R/'assets/ui/branding'; out.mkdir(parents=True,exist_ok=True)
choices={
'allianz-milano':('Milano_COLORE_PDF.pdf','Milano_BIANCO_PDF.pdf','MIL'),
'cisterna-volley':('Cisterna/CISTERNA_COLORE.pdf','Cisterna/CISTERNA_BIANCO.pdf','CIS'),
'cucine-lube-civitanova':('CIVITANOVA_LOGO/CIVITANOVA-pdf/CIVITANOVA-colore.pdf','CIVITANOVA_LOGO/CIVITANOVA-pdf/CIVITANOVA-bianco.pdf','CIV'),
'acqua-santanna-cuneo':('cuneo_voley_logo/PDF/Logo Cuneo Volley_COLORE.pdf','cuneo_voley_logo/PDF/Logo Cuneo Volley Bianco.pdf','CUN'),
'gas-sales-bluenergy-piacenza':('Piacenza_COLORE_ROSSO_BLU_orizzontale.pdf','Piacenza_BIANCO_orizzontale.pdf','PIA'),
'itas-trentino':('Trento/TRENTO-colore_PDF.pdf','Trento/TRENTO-bianco_JPG.pdf','TRE'),
'pallavolo-padova':('SuperLega_Padova/Padova_COLORE_PDF.pdf','SuperLega_Padova/Padova_BIANCO_PDF.pdf','PAD'),
'rana-verona':('Verona/VERONA_COLOREBIANCO_PDF.pdf','Verona/VERONA_COLOREBIANCO_PDF.pdf','VER'),
'sir-susa-scai-perugia':('Perugia_COLORE_AI copia.pdf','Perugia_BIANCO_AI.pdf','PER'),
'tinet-prata-di-pordenone':('SuperLega_Prata/Prata_COLORE.pdf','SuperLega_Prata/Prata_BIANCO.pdf','PRA'),
'valsa-group-modena':('Modena/MV_Logo_Blu.pdf','Modena/MV_Logo_Bianco.pdf','MOD'),
'vero-volley-monza':('Monza_COLORE_PDF.pdf','Monza_BIANCO_PDF.pdf','MON')}
archives=json.loads((cache/'archives.json').read_text()); urls={r['club']:r['url'] for r in archives}
def render(data,path):
 doc=fitz.open(stream=data,filetype='pdf'); page=doc[0]
 # First pass locates the transparent artwork, then the vector source is
 # re-rendered at sufficient density rather than enlarging a thumbnail.
 pix=page.get_pixmap(matrix=fitz.Matrix(1,1),alpha=True)
 im=Image.frombytes('RGBA',(pix.width,pix.height),pix.samples)
 box=im.getchannel('A').getbbox(); assert box,path
 factor=min(20,2200/max(box[2]-box[0],box[3]-box[1]))
 pix=page.get_pixmap(matrix=fitz.Matrix(factor,factor),alpha=True)
 im=Image.frombytes('RGBA',(pix.width,pix.height),pix.samples); im=im.crop(im.getchannel('A').getbbox())
 im.save(path,optimize=True)
 return {'size':im.size,'source_sha256':hashlib.sha256(data).hexdigest(),'texture_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'vector_paths':len(page.get_drawings())}
manifest={'source_page':'https://www.legavolley.it/documenti/loghi-lega-e-club','clubs':{}}
for club,(color,white,abbr) in choices.items():
 z=zipfile.ZipFile(cache/(club+'.zip')); row={'abbreviation':abbr,'source_archive':urls[club],'artwork':{}}
 for variant,name in [('color',color),('white',white)]:
  # Transparent official PNGs avoid exporting PDF presentation swatches as
  # part of the club crest. Never upscale a raster or key away logo details.
  pngs=[n for n in z.namelist() if n.lower().endswith('.png') and not n.startswith('__MACOSX') and 'bianco' in n.lower()]
  use_png=(variant=='white' and club not in ['pallavolo-padova','tinet-prata-di-pordenone','itas-trentino'])
  if club=='rana-verona':
   name='Verona/VERONA_BIANCO_PNG.png' if variant=='white' else 'Verona/VERONA_COLORE_PNG.png';use_png=True
  elif use_png and pngs: name=pngs[0]
  path=out/(club+'-'+variant+'.png')
  if use_png:
   data=z.read(name); im=Image.open(io.BytesIO(data)).convert('RGBA'); original=im.size
   im=im.crop(im.getchannel('A').getbbox());im.save(path,optimize=True)
   metadata={'size':im.size,'original_size':original,'source_sha256':hashlib.sha256(data).hexdigest(),'texture_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'vector_paths':0,'method':'official original transparent PNG, alpha bounds cropped, no upscaling'}
  else: metadata=render(z.read(name),path)
  row[variant]=path.relative_to(R).as_posix();row['artwork'][variant]={'member':name,**metadata}
 manifest['clubs'][club]=row
p=cache/'superlega.pdf'
if not p.exists():p.write_bytes(urllib.request.urlopen(urllib.request.Request('https://www.legavolley.it/wp-content/uploads/2020/07/CREDEM-SUPERLEGA.pdf',headers={'User-Agent':'Mozilla/5.0'}),timeout=40).read())
metadata=render(p.read_bytes(),out/'superlega.png')
manifest['superlega']={'path':'assets/ui/branding/superlega.png','source':'https://www.legavolley.it/wp-content/uploads/2020/07/CREDEM-SUPERLEGA.pdf',**metadata}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
(R/'docs/branding65-sources.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
# Inspection sheet only; never used as in-game artwork.
sheet=Image.new('RGB',(1200,800),'#142643'); d=ImageDraw.Draw(sheet)
for i,(club,row) in enumerate(manifest['clubs'].items()):
 x=(i%4)*300;y=(i//4)*250
 im=Image.open(R/row['white']);im.thumbnail((250,175));sheet.paste(im,(x+(300-im.width)//2,y+15),im)
 d.text((x+10,y+195),club,fill='white')
sheet.save(R/'docs/branding65-preview.png')
print('BRANDING65',len(choices),'official clubs, color + white, vector-derived artwork',metadata)
