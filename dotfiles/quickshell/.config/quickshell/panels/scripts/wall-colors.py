#!/usr/bin/env python3
"""Sort wallpapers into colour buckets (Red, Orange, ... Monochrome) for the picker.
Uses the thumbnails from ~/.local/bin/wallpaper-thumbs and caches results by mtime.
Prints JSON: {"file name": {"hex": "#rrggbb", "bucket": "Blue"}, ...}"""
import colorsys, json, os, subprocess, sys

HOME = os.path.expanduser("~")
WALLS = os.path.join(HOME, "Pictures/Wallpapers")
THUMBS = os.path.join(HOME, ".cache/wallpaper/thumbs")
CACHE = os.path.join(HOME, ".cache/wallpaper/colors.json")
EXTS = (".jpg", ".jpeg", ".png", ".webp")

def bucket(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    if s < 0.18 or v < 0.12:
        return "Monochrome"
    h *= 360
    if h < 15 or h >= 335: return "Red"
    if h < 40: return "Orange"
    if h < 70: return "Yellow"
    if h < 165: return "Green"
    if h < 250: return "Blue"
    if h < 290: return "Purple"
    return "Pink"

def dominant(path):
    """Quantise to 6 colours and pick the one with the best count * saturation."""
    out = subprocess.run(["magick", path + "[0]", "-resize", "64x64!", "-colors", "6",
                          "-format", "%c", "histogram:info:-"],
                         capture_output=True, text=True).stdout
    best, best_score, fallback, fallback_n = None, -1, (128, 128, 128), -1
    for line in out.splitlines():
        try:
            n = int(line.split(":")[0])
            hexv = line.split("#")[1][:6]
            r, g, b = (int(hexv[i:i + 2], 16) for i in (0, 2, 4))
        except (IndexError, ValueError):
            continue
        _, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        if n > fallback_n:
            fallback, fallback_n = (r, g, b), n
        score = n * (s ** 1.5) * (0.3 + v)
        if s >= 0.18 and v >= 0.12 and score > best_score:
            best, best_score = (r, g, b), score
    # only call it colourful if the saturated colour covers a decent share of the image
    if best and best_score > 64 * 64 * 0.04:
        return best
    return fallback

def main():
    try:
        cache = json.load(open(CACHE))
    except (OSError, ValueError):
        cache = {}
    out, changed = {}, False
    for name in sorted(os.listdir(WALLS)):
        if not name.lower().endswith(EXTS):
            continue
        src = os.path.join(WALLS, name)
        mtime = int(os.path.getmtime(src))
        c = cache.get(name)
        if not c or c.get("mtime") != mtime:
            thumb = os.path.join(THUMBS, name + ".jpg")
            r, g, b = dominant(thumb if os.path.exists(thumb) else src)
            c = {"hex": "#%02x%02x%02x" % (r, g, b), "bucket": bucket(r, g, b), "mtime": mtime}
            cache[name] = c
            changed = True
        out[name] = {"hex": c["hex"], "bucket": c["bucket"]}
    if changed:
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        json.dump(cache, open(CACHE, "w"))
    json.dump(out, sys.stdout)

main()
