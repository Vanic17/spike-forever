"""Independently verify every archived byte and selective download offset."""
from pathlib import Path, PurePosixPath
import hashlib
import json
import sys
import zipfile
import zlib

archive = Path(sys.argv[1]).resolve()
index = json.loads(archive.with_name('SpikeForever-UpdateIndex.json').read_text(encoding='utf-8-sig'))
archive_hash = hashlib.file_digest(archive.open('rb'), 'sha256').hexdigest()
assert index['archive']['size'] == archive.stat().st_size
assert index['archive']['sha256'] == archive_hash
with zipfile.ZipFile(archive) as z, archive.open('rb') as raw:
    manifest = json.loads(z.read('release-manifest.json').decode('utf-8-sig'))
    assert manifest['version'] == index['version'] == '0.89.0'
    assert set(manifest['files']) == set(index['files'])
    assert set(z.namelist()) == set(manifest['files']) | {'release-manifest.json'}
    assert len(z.namelist()) == len(set(z.namelist()))
    for name, expected in manifest['files'].items():
        path = PurePosixPath(name)
        assert not path.is_absolute() and '..' not in path.parts and ':' not in name
        assert path.parts[0] not in ['.runtime', '.updates', '.git', 'user', 'saves', 'careers']
        assert path.name not in ['roster-overrides.json', 'hosts.yml', 'settings.cfg']
        assert not name.startswith(('tools/github/', 'tools/git/'))
        info = z.getinfo(name)
        with z.open(info) as stream:
            actual = hashlib.file_digest(stream, 'sha256').hexdigest()
        assert actual == expected, name
        entry = index['files'][name]
        assert entry['sha256'] == actual and entry['size'] == info.file_size
        assert entry['compressed_size'] == info.compress_size
        # This is the exact byte range the updater requests from the ZIP.
        raw.seek(entry['offset'])
        compressed = raw.read(entry['compressed_size'])
        payload = zlib.decompress(compressed, -15) if entry['compression'] == 8 else compressed
        assert len(payload) == entry['size']
        assert hashlib.sha256(payload).hexdigest() == actual, name
    for required in ['src/stadium_fidelity89.gd', 'src/pilot_quality89.gd',
                     'src/online_command89.gd', 'docs/online89-command-tests.json',
                     'assets/art/quality89/beard_full3.res',
                     'src/character_quality89.gd', 'assets/art/athlete88/ATTRIBUTION.md',
                     'assets/art/athlete88/source/License.txt',
                     'assets/art/athlete88/head.res', 'assets/art/quality89/head0.res',
                     'assets/art/quality89/crowd/v04_l3.res',
                     'docs/graphics89-validation.json', 'docs/graphics89-review.html',
                     'tools/godot/Godot_v4.5.1-stable_win64.exe']:
        assert required in manifest['files'], required
old = archive.parent.parent / 'v0.85.0-graphics-audio/SpikeForever-UpdateIndex.json'
baseline = json.loads(old.read_text(encoding='utf-8-sig'))
changed = [n for n, v in index['files'].items()
           if baseline['files'].get(n, {}).get('sha256') != v['sha256']]
result = {'pass': True, 'version': manifest['version'], 'files': len(manifest['files']),
          'bytes': archive.stat().st_size, 'sha256': archive_hash,
          'selective_update_from_85': {'changed_files': len(changed),
              'compressed_payload_bytes': sum(index['files'][n]['compressed_size'] for n in changed),
              'unchanged_files': len(index['files']) - len(changed)},
          'verified': ['all SHA256', 'all CRC through ZIP stream', 'all raw selective byte ranges',
                       'source license and attribution', 'no personal profiles or CLI credentials']}
report = archive.with_name('package89-verification.json')
report.write_text(json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps(result))
