"""Reproducible extraction/editing of the eight user supplied arena recordings.

Only Python's standard library and the checked-in ffmpeg binaries are required.
The videos are inputs; only the derived Ogg audio bank is shipped with the game.
"""
from __future__ import annotations

import argparse
import array
import hashlib
import json
import math
import os
from pathlib import Path
import random
import re
import subprocess
import wave


ROOT = Path(__file__).resolve().parents[1]
FFMPEG = ROOT / "tools/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe"
FFPROBE = FFMPEG.with_name("ffprobe.exe")
OUTPUT = ROOT / "assets/audio/arena"
WORK = ROOT / ".runtime/audio38-source"
SOURCE_NAMES = ["applause 2", "applause 3", "crowd 2", "crowd", "drums", "horn", "in between", "sneakers"]


def run(args: list[str]) -> str:
    result = subprocess.run([str(a) for a in args], capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode:
        raise RuntimeError(result.stderr)
    return result.stdout + result.stderr


def db(value: float) -> float:
    return round(20 * math.log10(max(value, 1e-9)), 2)


def inspect_wave(path: Path) -> dict:
    with wave.open(str(path), "rb") as reader:
        rate, channels = reader.getframerate(), reader.getnchannels()
        values = array.array("h", reader.readframes(reader.getnframes()))
    frame = max(channels, int(rate * .01) * channels)
    energies = [math.sqrt(sum(v * v for v in values[n:n + frame]) / max(1, len(values[n:n + frame]))) / 32768 for n in range(0, len(values), frame)]
    audible = [n for n, value in enumerate(energies) if value > .004]
    duration = len(values) / rate / channels
    start = max(0.0, (audible[0] * .01 if audible else 0) - .04)
    end = min(duration, (audible[-1] * .01 + .04 if audible else duration))
    return {
        "duration": round(duration, 4), "active_start": round(start, 3), "active_end": round(end, 3),
        "sample_peak_dbfs": db(max(abs(v) for v in values) / 32768),
        "rms_dbfs": db(math.sqrt(sum(v * v for v in values) / len(values)) / 32768),
        "rms_half_second_dbfs": [db(math.sqrt(sum(e * e for e in energies[i:i + 50]) / len(energies[i:i + 50]))) for i in range(0, len(energies), 50)],
    }


def decode(source: Path, target: Path) -> dict:
    run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", source, "-vn", "-map", "0:a:0", "-ac", "1", "-ar", "24000", "-c:a", "pcm_s16le", target])
    result = inspect_wave(target)
    result.update({"source": source.name, "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest()})
    return result


def normalization_filter(source: Path, before: str, target_lufs: float) -> tuple[str, dict]:
    report = run([FFMPEG, "-hide_banner", "-i", source, "-vn", "-af", before + f",loudnorm=I={target_lufs}:TP=-3:LRA=8:print_format=json", "-f", "null", "-"])
    match = re.search(r'\{\s*"input_i"[\s\S]+?\}', report)
    if not match:
        raise RuntimeError("Missing loudness report: " + str(source))
    measured = json.loads(match.group())
    second = (
        f"loudnorm=I={target_lufs}:TP=-3:LRA=8:measured_I={measured['input_i']}:"
        f"measured_TP={measured['input_tp']}:measured_LRA={measured['input_lra']}:"
        f"measured_thresh={measured['input_thresh']}:offset={measured['target_offset']}:linear=true"
    )
    return second, measured


def render(name: str, group: str, sources: list[dict], raw_file: Path, tempo: float = 1.0, target: float = -20, equalizer: str = "") -> dict:
    destination = OUTPUT / (name + ".ogg")
    # Room response is added at runtime on Arena only, preserving the dry attack.
    # EBU R128 needs a complete 400ms measurement block, including short foley.
    before = f"highpass=f=75,lowpass=f=12500,atempo={tempo},apad=pad_dur=0.2"
    if equalizer:
        before += "," + equalizer
    normalization, measured = normalization_filter(raw_file, before, target)
    duration = float(json.loads(run([FFPROBE, "-v", "error", "-show_entries", "format=duration", "-of", "json", raw_file]))["format"]["duration"]) / tempo
    fadeout = min(.25, duration * .2)
    filters = before + "," + normalization + f",afade=t=in:st=0:d=0.015,afade=t=out:st={max(.01, duration - fadeout)}:d={fadeout},alimiter=limit=0.84:level=false"
    run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", raw_file, "-vn", "-af", filters, "-ar", "44100", "-ac", "2", "-c:a", "libvorbis", "-q:a", "5", destination])
    analysis = WORK / (name + "-verify.wav")
    run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", destination, "-ar", "24000", "-ac", "1", analysis])
    statistics = inspect_wave(analysis)
    statistics.pop("rms_half_second_dbfs")
    report = run([FFMPEG, "-hide_banner", "-i", destination, "-af", "loudnorm=I=-20:TP=-3:print_format=json", "-f", "null", "-"])
    loudness = json.loads(re.search(r'\{\s*"input_i"[\s\S]+?\}', report).group())
    return {"file": destination.name, "group": group, "sources": sources, "tempo": tempo, "normalization_target_lufs": target, "integrated_lufs": float(loudness["input_i"]), "true_peak_dbtp": float(loudness["input_tp"]), "equalizer": equalizer, "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(), **statistics}


def excerpt(source: Path, offset: float, length: float, name: str) -> Path:
    target = WORK / (name + "-raw.wav")
    run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-ss", str(offset), "-i", source, "-t", str(length), "-vn", "-ar", "44100", "-ac", "2", target])
    return target


def whistle(name: str, kind: int) -> Path:
    """Pealess referee whistle: breath envelope, two beating partials, airy noise."""
    rng = random.Random(8070 + kind)
    rate = 44100
    duration = [.42, .55, .65, .73, .48, .85][kind]
    samples = array.array("h")
    phase_a = phase_b = 0.0
    smooth_noise = 0.0
    for n in range(int(rate * duration)):
        t = n / rate
        attack = min(1.0, t / .018)
        release = min(1.0, (duration - t) / .07)
        interruption = .35 if kind in (2, 5) and .24 < t < .28 else 1.0
        breath = attack * release * interruption * (.92 + .08 * math.sin(t * 34))
        flutter = 30 * math.sin(t * math.tau * (20 + kind)) + 7 * math.sin(t * math.tau * 87)
        phase_a += math.tau * (2810 + kind * 39 + flutter) / rate
        phase_b += math.tau * (3120 + kind * 29 + flutter * .7) / rate
        noise = rng.uniform(-1, 1)
        smooth_noise = .68 * smooth_noise + .32 * noise
        tone = (.33 * math.sin(phase_a) + .24 * math.sin(phase_b) + .11 * (noise - smooth_noise)) * breath
        value = int(max(-.9, min(.9, tone)) * 32767)
        samples.extend((value, value))
    target = WORK / (name + "-raw.wav")
    with wave.open(str(target), "wb") as writer:
        writer.setnchannels(2); writer.setsampwidth(2); writer.setframerate(rate); writer.writeframes(samples.tobytes())
    return target


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-directory", type=Path, default=Path(os.environ["USERPROFILE"]) / "Videos/Captures")
    parser.add_argument("--analyze-only", action="store_true")
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True); WORK.mkdir(parents=True, exist_ok=True)
    recordings = {}
    for name in SOURCE_NAMES:
        source = args.source_directory / (name + ".mp4")
        info = decode(source, WORK / (name + "-source.wav"))
        recordings[name] = info
        print(name, json.dumps(info), flush=True)
    (WORK / "source-analysis.json").write_text(json.dumps(recordings, indent=2), encoding="utf-8")
    if args.analyze_only:
        return
    manifest = []

    def crop(group: str, count: int, names: list[str], length: float, target: float) -> None:
        for index in range(count):
            source_name = names[index % len(names)]
            info = recordings[source_name]
            actual_length = min(length, (info["active_end"] - info["active_start"]) * .82)
            available = max(0, info["active_end"] - info["active_start"] - actual_length - .15)
            cycle = index // len(names)
            total = math.ceil(count / len(names))
            offset = info["active_start"] + .08 + available * ((cycle + .15) / max(1, total))
            # The recordings include browser/recording pauses in the middle.
            # Keep rhythmic excerpts inside their measured continuous passages.
            continuous = {
                "applause 2": [4.65, 10.0, 22.1, 29.5],
                "applause 3": [6.25, 9.7, 18.0, 22.4],
                "drums": [4.1, 5.5, 7.2, 8.8, 10.3, 11.7],
                "horn": [6.6, 8.1, 14.9, 21.1, 28.2, 34.7],
            }
            if source_name in continuous:
                offset = continuous[source_name][cycle % len(continuous[source_name])]
            name = f"{group}_{index:02d}"
            raw = excerpt(args.source_directory / (source_name + ".mp4"), offset, actual_length, name)
            variation = [1.0, .985, 1.025, .97, 1.015, 1.04][index % 6]
            equalizer = "equalizer=f=180:t=q:w=0.7:g=1.2" if group in ("drums", "applause") and index % 2 else ""
            manifest.append(render(name, group, [{"file": source_name + ".mp4", "offset_seconds": round(offset, 4), "length_seconds": round(actual_length, 4)}], raw, variation, target, equalizer))
            print("rendered", name, flush=True)

    crop("applause", 8, ["applause 2", "applause 3"], 6.0, -20)
    crop("drums", 6, ["drums"], 6.0, -21)
    crop("crowd", 8, ["crowd", "crowd 2"], 3.8, -21)
    crop("interlude", 4, ["in between"], 5.2, -22)
    crop("horn", 6, ["horn"], 1.5, -23)
    # Distinct source gestures, extracted around separate transients, not 12
    # differently named copies of one shoe squeak.
    sneaker_info = recordings["sneakers"]
    sneaker_wave = WORK / "sneakers-source.wav"
    with wave.open(str(sneaker_wave), "rb") as reader:
        values = array.array("h", reader.readframes(reader.getnframes()))
    frame = 240
    peaks = [(max(abs(v) for v in values[n:n + frame]) / 32768, n / 24000) for n in range(0, len(values) - frame, frame)]
    selected = []
    for peak, offset in sorted(peaks, reverse=True):
        if .10 < offset < sneaker_info["duration"] - .25 and all(abs(offset - previous) >= .43 for previous in selected):
            selected.append(offset)
        if len(selected) == 12:
            break
    selected.sort()
    if len(selected) != 12:
        raise RuntimeError("Need twelve distinct sneaker gestures")
    for index, centre in enumerate(selected):
        name = f"sneaker_{index:02d}"
        offset = max(0, centre - .10)
        raw = excerpt(args.source_directory / "sneakers.mp4", offset, .42, name)
        manifest.append(render(name, "sneaker", [{"file": "sneakers.mp4", "offset_seconds": round(offset, 4), "length_seconds": .42}], raw, [1, .97, 1.035][index % 3], -25))
        print("rendered", name, flush=True)
    # Additional authored rhythms combine distinct snippets at an unobtrusive
    # relative drum level; each stem keeps its own pulse, no artificial echo.
    for index in range(4):
        name = f"rhythm_{index:02d}"
        applause_name = ["applause 2", "applause 3"][index % 2]
        applause_offset = [4.65, 6.25, 22.1, 22.4][index]
        drum_offset = [4.1, 6.0, 8.0, 10.0][index]
        a = excerpt(args.source_directory / (applause_name + ".mp4"), applause_offset, 6, name + "a")
        b = excerpt(args.source_directory / "drums.mp4", drum_offset, 6, name + "b")
        raw = WORK / (name + "-raw.wav")
        run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", a, "-i", b, "-filter_complex", "[1:a]volume=0.18[d];[0:a][d]amix=inputs=2:normalize=0", raw])
        manifest.append(render(name, "rhythm", [{"file": applause_name + ".mp4", "offset_seconds": applause_offset, "length_seconds": 6}, {"file": "drums.mp4", "offset_seconds": drum_offset, "length_seconds": 6, "gain": .18}], raw, 1, -21))
        print("rendered", name, flush=True)
    for index in range(6):
        name = f"whistle_{index:02d}"
        manifest.append(render(name, "whistle", [{"type": "authored_synthesis", "algorithm": "two breath-modulated partials, beating/air noise", "seed": 8070 + index}], whistle(name, index), 1, -24))
        print("rendered", name, flush=True)
    result = {"schema": 1, "description": "Derived user recordings, 44.1kHz stereo Vorbis, dry sources plus Arena runtime room reverb", "source_analysis": recordings, "variants": manifest, "count": len(manifest), "groups": {group: sum(item["group"] == group for item in manifest) for group in sorted({item["group"] for item in manifest})}}
    (OUTPUT / "manifest.json").write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({"count": len(manifest), "groups": result["groups"], "size_bytes": sum(p.stat().st_size for p in OUTPUT.glob("*.ogg"))}), flush=True)


if __name__ == "__main__":
    main()
