"""Index individual deflated ZIP members for verified selective HTTP ranges."""
from pathlib import Path
import argparse, hashlib, json, struct, zipfile

def build(archive: Path, output: Path):
    with zipfile.ZipFile(archive) as z, archive.open('rb') as raw:
        manifest=json.loads(z.read('release-manifest.json').decode('utf-8-sig'))
        files={}
        for name,digest in manifest['files'].items():
            info=z.getinfo(name)
            assert info.compress_type in (0,8) and not info.flag_bits & 1
            raw.seek(info.header_offset)
            header=raw.read(30)
            assert header[:4]==b'PK\x03\x04'
            filename,extra=struct.unpack_from('<HH',header,26)
            files[name]={'sha256':digest,'size':info.file_size,'compressed_size':info.compress_size,
                         'offset':info.header_offset+30+filename+extra,'compression':info.compress_type}
    h=hashlib.sha256()
    with archive.open('rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''): h.update(block)
    index={'schema':1,'version':manifest['version'],'archive':{'name':archive.name,'size':archive.stat().st_size,'sha256':h.hexdigest()},'files':files}
    output.write_text(json.dumps(index,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
    print(json.dumps({'files':len(files),'index_bytes':output.stat().st_size,'archive_bytes':archive.stat().st_size,'index_sha256':hashlib.sha256(output.read_bytes()).hexdigest()}))

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('archive',type=Path);p.add_argument('output',type=Path)
    a=p.parse_args();build(a.archive,a.output)
