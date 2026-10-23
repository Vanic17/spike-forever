"""Measure the actual Godot bus recording, including quiet/crossfade windows."""
from __future__ import annotations
import array
import json
import math
from pathlib import Path
import re
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
FFMPEG = ROOT / "tools/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe"
SOURCE = ROOT / "docs/arena39-mix-preview.wav"


def db(amplitude: float) -> float:
    return round(20 * math.log10(max(amplitude, 1e-9)), 3)


def main() -> None:
    with wave.open(str(SOURCE), "rb") as reader:
        rate, channels = reader.getframerate(), reader.getnchannels()
        samples = array.array("h", reader.readframes(reader.getnframes()))
    windows = {
        "stable_neutral_bed": (3.6, 6.0),
        "motif_fades_in": (6.4, 8.4),
        "service_continuity": (8.6, 10.8),
        "home_point": (11.8, 14.8),
        "away_point": (18.9, 20.6),
        "ambient_crossfade": (20.8, 24.6),
        "new_neutral_bed": (24.1, 25.0),
        "whole_recording": (0.0, len(samples) / rate / channels),
    }
    measurements = {}
    for name, (start, end) in windows.items():
        filters = f"atrim=start={start}:duration={end - start},asetpts=PTS-STARTPTS,loudnorm=I=-20:TP=-3:LRA=8:print_format=json"
        result = subprocess.run([str(FFMPEG), "-hide_banner", "-i", str(SOURCE), "-af", filters, "-f", "null", "-"], capture_output=True, text=True, encoding="utf-8", errors="replace")
        if result.returncode:
            raise RuntimeError(result.stderr)
        report = json.loads(re.search(r'\{\s*"input_i"[\s\S]+?\}', result.stderr).group())
        block_rms = []
        for step in range(round(start * 10), round(end * 10)):
            values = samples[int(step * .1 * rate) * channels:int((step + 1) * .1 * rate) * channels]
            block_rms.append(db(math.sqrt(sum(value * value for value in values) / max(1, len(values))) / 32768))
        measurements[name] = {
            "start": start, "end": round(end, 5),
            "integrated_lufs": float(report["input_i"]), "true_peak_dbtp": float(report["input_tp"]),
            "minimum_100ms_rms_dbfs": min(block_rms), "maximum_100ms_rms_dbfs": max(block_rms),
            "largest_adjacent_100ms_rms_drop_db": round(max([0.0] + [a - b for a, b in zip(block_rms, block_rms[1:])]), 3),
            "near_silent_100ms_blocks_below_minus_60db": sum(value < -60 for value in block_rms),
        }
    if measurements["ambient_crossfade"]["near_silent_100ms_blocks_below_minus_60db"]:
        raise AssertionError("An audible arena background must survive the ambient hand-off")
    if measurements["whole_recording"]["true_peak_dbtp"] >= -1.0:
        raise AssertionError("Mix must retain output headroom")
    report = {"source": SOURCE.name, "sample_rate": rate, "channels": channels, "windows": measurements}
    (ROOT / "docs/audio39-mix-measurements.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    print("ARENA MIX 39 PASS")


if __name__ == "__main__":
    main()
