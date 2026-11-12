#!/usr/bin/env python3
"""WCAG contrast check for every YawnCast theme.

Reads the colors straight from YawnCast/Design/Theme.swift (what ships), checks the
pairs the UI actually draws, and flags drift from replica/design/tokens.<id>.json.

    python3 scripts/contrast.py          # table + failures, exit 1 on any failure

Text pairs need 4.5:1 (AA, body text). Non-text pairs (icons, key edges, focus
rings, page dots) need 3:1 (WCAG 1.4.11). Scene themes draw animated art behind
the bg color; those were checked against their brightest band separately
(ACCEPTANCE V5.3/V6.2) and are not re-checked here.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
THEME_SWIFT = ROOT / "YawnCast/Design/Theme.swift"
TOKENS = str(ROOT / "replica/design/tokens.{}.json")

# (foreground, background, minimum, where it appears[, foreground opacity])
PAIRS = [
    ("text", "bg", 4.5, "titles, body"),
    ("text", "surface", 4.5, "search field text, list rows"),
    ("text", "raised", 4.5, "key labels, mini player, bubbles"),
    ("textMuted", "bg", 4.5, "captions, eyebrows"),
    ("textMuted", "surface", 4.5, "search placeholder, list-row author"),
    ("textMuted", "raised", 4.5, "mini player show name"),
    ("bg", "text", 4.5, "primary key label (Play, Subscribe)"),
    ("onAccent", "accent", 4.5, "Moon key when on, interest chips"),
    ("danger", "bg", 4.5, "playback error"),
    ("accent", "bg", 3.0, "Moon glyph, new-episode dot (non-text)"),
    ("text", "surface", 3.0, "scrubber fill vs track (non-text)"),
    ("text", "raised", 4.5, "Moon key subtitle, Sleep off (MoonKey 0.85 opacity)", 0.85),
    ("onAccent", "accent", 4.5, "Moon key subtitle, Sleep on (MoonKey 0.85 opacity)", 0.85),
    ("textMuted", "bg", 3.0, "unselected page dot (PageDots 0.75 opacity, non-text)", 0.75),
    ("fadeMark", "bg", 3.0, "lit fade mark: lantern, firefly, star (non-text)"),
    ("fadeMark", "raised", 3.0, "lit fade dot in the mini player (non-text)"),
    ("text", "bg", 3.0, "dark fade mark outline (FadeMarks 0.6 opacity, non-text)", 0.6),
]

FIELDS = ("bg", "surface", "raised", "border", "text", "textMuted", "accent", "onAccent", "danger")
TOKEN_NAMES = {"textMuted": "text-muted", "onAccent": "on-accent"}


def themes():
    src = THEME_SWIFT.read_text()
    for m in re.finditer(r"static let (\w+) = Theme\((.*?)\n    \)", src, re.S):
        body = m.group(2)
        tid = re.search(r'id: "(\w+)"', body).group(1)
        colors = {f: int(h, 16) for f, h in re.findall(r"\b(\w+): Color\(hex: 0x([0-9A-Fa-f]{6})\)", body)}
        # Theme.fadeMark: the accent, except where Theme.swift names another colour for a scene.
        override = re.search(r"var fadeMark: Color \{ scene == \.(\w+) \? Color\(hex: 0x([0-9A-Fa-f]{6})\)", src)
        colors["fadeMark"] = int(override.group(2), 16) if override and f"scene: .{override.group(1)}" in body else colors["accent"]
        yield tid, "scene:" in body, colors


def luminance(rgb):
    def channel(c):
        c /= 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def blend(fg, bg, alpha):
    out = 0
    for shift in (16, 8, 0):
        f, b = (fg >> shift) & 0xFF, (bg >> shift) & 0xFF
        out |= round(f * alpha + b * (1 - alpha)) << shift
    return out


def ratio(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def main():
    failures, drift = [], []
    print(f"{'theme':<11}" + "".join(f"{fg[:6]}/{bg[:6]:<7}" for fg, bg, *_ in PAIRS))
    for tid, has_scene, c in themes():
        cells = []
        for fg, bg, minimum, where, *alpha in PAIRS:
            r = ratio(blend(c[fg], c[bg], alpha[0]) if alpha else c[fg], c[bg])
            ok = r >= minimum
            cells.append(f"{r:5.2f}{' ' if ok else '!'}       ")
            if not ok:
                failures.append(f"{tid}: {fg} on {bg} = {r:.2f}:1 (needs {minimum}:1) — {where}")
        print(f"{tid:<11}" + "".join(cells))
        tokens = TOKENS.format(tid)
        try:
            tok = json.loads(open(tokens).read())["color"]
        except FileNotFoundError:
            drift.append(f"{tid}: no {tokens.split('/')[-1]}")
            continue
        for f in FIELDS:
            want = tok.get(TOKEN_NAMES.get(f, f), "").lstrip("#").upper()
            if want and want != f"{c[f]:06X}":
                drift.append(f"{tid}: {f} is {c[f]:06X} in Theme.swift, {want} in tokens")
    for line in drift:
        print("drift:", line)
    for line in failures:
        print("FAIL:", line)
    print(f"{len(failures)} failure(s), {len(drift)} token drift note(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
