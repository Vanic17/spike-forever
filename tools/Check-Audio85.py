"""Validate distributable WAV headers and optionally decode every audio file."""
from pathlib import Path
import argparse, concurrent.futures, hashlib, json, struct, subprocess

ROOT = Path(__file__).resolve().parents[1]
FFMPEG = ROOT / 'tools/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe'

def inspect(path):
    data = path.read_bytes()
    if data[:4] != b'RIFF' or data[8:12] != b'WAVE':
        raise ValueError(f'{path}: invalid RIFF/WAVE header')
    if struct.unpack_from('<I', data, 4)[0] + 8 != len(data):
        raise ValueError(f'{path}: inconsistent RIFF length')
    offset, fmt, size = 12, None, None
    while offset + 8 <= len(data):
        tag, length = struct.unpack_from('<4sI', data, offset)
        if offset + 8 + length > len(data):
            raise ValueError(f'{path}: truncated chunk')
        if tag == b'fmt ':
            fmt = struct.unpack_from('<HHIIHH', data, offset + 8)
        elif tag == b'data':
            size = length
        offset += 8 + length + length % 2
    if fmt is None or size is None:
        raise ValueError(f'{path}: missing fmt/data chunk')
    codec, channels, rate, byte_rate, align, bits = fmt
    if codec != 1 or channels not in (1, 2) or bits != 16:
        raise ValueError(f'{path}: expected PCM16 mono/stereo, got {fmt}')
    if align != channels * bits // 8 or byte_rate != rate * align or size % align:
        raise ValueError(f'{path}: inconsistent sample layout')
    return {'path': path.relative_to(ROOT).as_posix(), 'channels': channels,
            'sample_rate': rate, 'bits': bits, 'frames': size // align,
            'duration': size / byte_rate, 'sha256': hashlib.sha256(data).hexdigest()}

def decode(path):
    result = subprocess.run([str(FFMPEG), '-v', 'error', '-xerror', '-threads', '1',
                             '-i', str(path), '-f', 'null', '-'], capture_output=True, timeout=90)
    return {'path': path.relative_to(ROOT).as_posix(), 'pass': result.returncode == 0,
            'error': result.stderr.decode('utf-8', errors='replace').strip()}

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--decode-all', action='store_true')
    parser.add_argument('--report', default='docs/audio85-validation.json')
    args = parser.parse_args()
    wavs = [inspect(p) for p in sorted((ROOT / 'assets').rglob('*.wav'))]
    decoded = []
    if args.decode_all:
        audio = sorted(p for p in (ROOT / 'assets/audio').rglob('*')
                       if p.suffix.lower() in ('.wav', '.ogg', '.mp3'))
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            decoded = list(pool.map(decode, audio))
    report = {'pass': all(r['pass'] for r in decoded), 'wav_count': len(wavs),
              'decoded_count': len(decoded), 'wav_files': wavs, 'decodes': decoded}
    (ROOT / args.report).write_text(json.dumps(report, indent=2), encoding='utf-8')
    assert report['pass'], [r for r in decoded if not r['pass']]
    print(f'AUDIO85 PASS {len(wavs)} WAV headers; {len(decoded)} full decodes')
