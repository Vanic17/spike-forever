"""Fetch the attributed Infinite scan, never run downloaded code."""
from pathlib import Path
import urllib.request,json,hashlib
root=Path(__file__).resolve().parent.parent
dest=root/'assets/art/athlete88/source'
dest.mkdir(parents=True,exist_ok=True)
url='https://api.github.com/repos/keijiro/InfiniteScan/git/trees/master?recursive=1'
req=urllib.request.Request(url,headers={'User-Agent':'SpikeForever-local-prototype'})
tree=json.load(urllib.request.urlopen(req,timeout=45))
(root/'.runtime/athlete88-source-tree.json').write_text(json.dumps(tree,indent=2))
for entry in tree['tree']:
    path=entry['path']
	
    if not path.startswith('Assets/InfiniteScan/'):continue
    if entry.get('type')!='blob' or not path.lower().endswith(('.obj','.fbx','.png','.jpg','.txt','.md')):continue
    if entry.get('size',0)>100_000_000:continue
    target=dest/Path(path).name
    raw='https://raw.githubusercontent.com/keijiro/InfiniteScan/'+tree['sha']+'/'+path
    data=urllib.request.urlopen(urllib.request.Request(raw,headers={'User-Agent':'SpikeForever-local-prototype'}),timeout=60).read()
    target.write_bytes(data)
    print(path,len(data),hashlib.sha256(data).hexdigest())
