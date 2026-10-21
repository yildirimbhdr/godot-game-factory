#!/usr/bin/env python3
"""Report whether a Movie Maker .wav actually contains sound. usage: check_audio.py <file.wav>"""
import sys, wave, struct

with wave.open(sys.argv[1], "rb") as w:
    ch, width, rate, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
    raw = w.readframes(n)
fmt = {2: "h", 4: "i"}.get(width)
if fmt is None:
    sys.exit(f"unsupported sample width {width}")
samples = struct.unpack("<%d%s" % (len(raw) // width, fmt), raw)
full = float(2 ** (8 * width - 1))
peak = max((abs(s) for s in samples), default=0) / full
active = sum(1 for i in range(0, len(samples), ch) if abs(samples[i]) / full > 0.01)
print(f"seconds={n / rate:.1f} peak={peak:.3f} active_ms={int(1000 * active / rate)}")
if peak <= 0.02:
    sys.exit(3)   # silent
if peak >= 0.995:
    print("clipping detected", file=sys.stderr)
    sys.exit(4)
sys.exit(0)
