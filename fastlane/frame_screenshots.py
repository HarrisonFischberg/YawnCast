#!/usr/bin/env python3
"""Turn the raw captures in fastlane/raw/ into captioned App Store screenshots.

    python3 fastlane/frame_screenshots.py

Writes fastlane/screenshots/en-US/<n>-<name>-6.9.png (1320x2868) and -6.3.png (1206x2622).
Edit CAPTIONS to change the words; drop a new capture in raw/ with a matching name to add one.
Needs Pillow, Young Serif (in the app bundle) and Inter (brew install --cask font-inter).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent
RAW, OUT = ROOT / "raw", ROOT / "screenshots" / "en-US"
SERIF = ROOT.parent / "YawnCast/Fonts/YoungSerif-Regular.ttf"
SANS = next(p for p in [Path.home() / "Library/Fonts/Inter-Medium.otf", Path("/Library/Fonts/Inter-Medium.otf"),
                        Path("/usr/share/fonts/opentype/inter/Inter-Medium.otf")] if p.exists())

CAPTIONS = {
    "1-nowplaying-city": ("Fall asleep to\nany podcast", "Tap the Moon and close your eyes."),
    "2-library-underwater": ("Six animated\nnight scenes", "Drifting fish, fireflies, soft rain."),
    "3-new-beach": ("New episodes,\nby day", "The latest from your shows, calmly."),
    "4-library-rainforest": ("Your library,\nyour way", "Big artwork or a tidy list."),
    "5-explore-mountain": ("Find shows to\ndrift off to", "Picks from your interests and the charts."),
    "6-topics-midnight": ("Start with what\nyou love", "Pick a few topics. We'll find the shows."),
}

W, H = 1320, 2868          # 6.9" canvas; 6.3" is a straight resize (same aspect within 0.1%)
PHONE_W, PHONE_TOP = 930, 760
RADIUS, BEZEL = 120, 22


def frame(shot: Image.Image, title: str, sub: str) -> Image.Image:
    # Background: the capture itself, blurred and dimmed, so each card takes its scene's colours.
    bg = shot.resize((W, H)).filter(ImageFilter.GaussianBlur(70))
    bg = ImageEnhance.Brightness(bg).enhance(0.55)
    shade = Image.linear_gradient("L").resize((W, H)).point(lambda v: int(170 * (1 - v / 255) ** 2))
    bg.paste((5, 6, 20), mask=shade)

    d = ImageDraw.Draw(bg)
    d.multiline_text((W / 2, 190), title, font=ImageFont.truetype(str(SERIF), 112), fill="white",
                     anchor="ma", align="center", spacing=18)
    d.text((W / 2, 520), sub, font=ImageFont.truetype(str(SANS), 50), fill=(255, 255, 255, 200), anchor="ma")

    ph = round(shot.height * PHONE_W / shot.width)
    screen = shot.resize((PHONE_W, ph), Image.LANCZOS)
    x, y = (W - PHONE_W) // 2, PHONE_TOP
    box = (x - BEZEL, y - BEZEL, x + PHONE_W + BEZEL, y + ph + BEZEL)

    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle((box[0], box[1] + 30, box[2], box[3] + 30), RADIUS + BEZEL, fill=200)
    bg.paste((0, 0, 0), mask=shadow.filter(ImageFilter.GaussianBlur(50)))

    d = ImageDraw.Draw(bg)
    d.rounded_rectangle(box, RADIUS + BEZEL, fill=(8, 8, 12), outline=(90, 90, 110), width=3)
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *screen.size), RADIUS, fill=255)
    bg.paste(screen, (x, y), mask)
    return bg


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*.png"):
        old.unlink()
    for name, (title, sub) in CAPTIONS.items():
        card = frame(Image.open(RAW / f"{name}.png").convert("RGB"), title, sub)
        card.save(OUT / f"{name}-6.9.png", optimize=True)
        card.resize((1206, 2622), Image.LANCZOS).save(OUT / f"{name}-6.3.png", optimize=True)
        print(name)
