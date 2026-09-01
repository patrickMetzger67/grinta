#!/usr/bin/env python3
"""Generate training-version Grinta session synthesis share card example PNG."""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# AppColors.dark
PRIMARY = (0xF9, 0x5C, 0x1B, 255)
SECONDARY = (0xFF, 0x8A, 0x5B, 255)
BACKGROUND = (0x11, 0x12, 0x14, 255)
SURFACE = (0x1A, 0x1B, 0x1E, 255)
TEXT_PRIMARY = (0xF5, 0xF5, 0xF7, 255)
TEXT_SECONDARY = (0xAE, 0xAE, 0xB2, 255)
BORDER = (0x34, 0x36, 0x3C, 255)
SUCCESS = (0x35, 0xC7, 0x8A, 255)
WARNING = (0xF5, 0xB7, 0x4A, 255)

WIDTH, HEIGHT = 1080, 1920

FONTS_DIR = Path("/workspace/assets/fonts")
LOGO_PATH = Path("/workspace/assets/images/logoFondBlanc.png")
MATERIAL_ICONS = Path(
    "/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf"
)


def load_sf(weight: str, size: float) -> ImageFont.FreeTypeFont:
    mapping = {
        "regular": "SF-Pro-Display-Regular.otf",
        "medium": "SF-Pro-Display-Medium.otf",
        "semibold": "SF-Pro-Display-Semibold.otf",
        "bold": "SF-Pro-Display-Bold.otf",
    }
    return ImageFont.truetype(str(FONTS_DIR / mapping[weight]), size)


def load_icon_font(size: float) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(MATERIAL_ICONS), size)


def text_size(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont):
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def draw_icon(draw: ImageDraw.ImageDraw, codepoint: int, center, size: float, color):
    font = load_icon_font(size)
    ch = chr(codepoint)
    # Measure with font getbbox for accurate glyph box
    bbox = font.getbbox(ch)
    gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = center[0] - gw / 2 - bbox[0]
    y = center[1] - gh / 2 - bbox[1]
    draw.text((x, y), ch, font=font, fill=color)


def draw_rounded_rect(draw, xy, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def main():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(img)

    y = 48.0

    # Grinta logo
    logo = Image.open(LOGO_PATH).convert("RGBA")
    logo_h = 72
    logo_w = int(logo_h * logo.width / logo.height)
    logo = logo.resize((logo_w, logo_h), Image.Resampling.LANCZOS)
    img.alpha_composite(logo, (64, int(y)))
    y += logo_h + 28

    # NO match header (training / isMatch=false)

    # Player name
    name_font = load_sf("bold", 52)
    draw.text((64, y), "Léa Martin", font=name_font, fill=TEXT_PRIMARY)
    y += 72

    # Accent bar + "Synthèse joueur"
    draw_rounded_rect(
        draw,
        (64, y + 6, 64 + 8, y + 6 + 28),
        radius=4,
        fill=PRIMARY,
    )
    title_font = load_sf("bold", 30)
    draw.text((88, y), "Synthèse joueur", font=title_font, fill=TEXT_PRIMARY)
    y += 56

    metrics = [
        # icon_cp, label, value, unit, color
        (0xF0377, "Distance", "5.98", "km", PRIMARY),
        (0xF01B5, "Vitesse moy.", "3.4", "km/h", SECONDARY),
        (0xF5CA, "Vitesse max", "26.7", "km/h", SUCCESS),
        (0xF0254, "Acc. max", "6.69", "m/s²", WARNING),
        (0xF6B8, "Sprints", "9", "nb", PRIMARY),
        (0xF76D, "Acc. hautes", "8", "nb", WARNING),
        (0xF023C, "Haute vitesse", "30s", "", SECONDARY),
        (0xF767, "Workload", "175", "pts", SUCCESS),
    ]

    cols = 2
    gap = 20.0
    left = 64.0
    tile_w = (WIDTH - left * 2 - gap) / cols
    tile_h = 250.0

    value_font = load_sf("bold", 44)
    unit_font = load_sf("semibold", 22)
    label_font = load_sf("semibold", 24)

    for i, (cp, label, value, unit, color) in enumerate(metrics):
        col = i % cols
        row = i // cols
        x = left + col * (tile_w + gap)
        ty = y + row * (tile_h + gap)
        rect = (x, ty, x + tile_w, ty + tile_h)
        draw_rounded_rect(draw, rect, radius=22, fill=SURFACE)
        draw_rounded_rect(draw, rect, radius=22, outline=BORDER, width=2)

        draw_icon(draw, cp, (x + tile_w / 2, ty + 58), 44, color)

        # Value + unit centered
        value_w, value_h = text_size(draw, value, value_font)
        unit_w = 0
        unit_text = f" {unit}" if unit else ""
        if unit_text:
            unit_w, _ = text_size(draw, unit_text, unit_font)
        total_w = value_w + unit_w
        vx = x + (tile_w - total_w) / 2
        vy = ty + 118
        # Align baselines roughly
        draw.text((vx, vy), value, font=value_font, fill=TEXT_PRIMARY)
        if unit_text:
            # baseline align unit with value
            draw.text(
                (vx + value_w, vy + (44 - 22) * 0.55),
                unit_text,
                font=unit_font,
                fill=TEXT_SECONDARY,
            )

        label_w, _ = text_size(draw, label, label_font)
        draw.text(
            (x + (tile_w - label_w) / 2, ty + 180),
            label,
            font=label_font,
            fill=TEXT_SECONDARY,
        )

    out_paths = [
        Path("/opt/cursor/artifacts/grinta_session_synthesis_share_card_training_example.png"),
        Path("/workspace/docs/examples/grinta_session_synthesis_share_card_training_example.png"),
    ]
    for p in out_paths:
        p.parent.mkdir(parents=True, exist_ok=True)
        # Convert to RGB PNG (no alpha) for consistent sharing
        rgb = Image.new("RGB", img.size, BACKGROUND[:3])
        rgb.paste(img, mask=img.split()[3])
        rgb.save(p, format="PNG", optimize=True)
        print(f"Wrote {p} ({p.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
