#!/usr/bin/env python3
"""Generates Odyssey's textures as 32-bit uncompressed TGA files (no dependencies).

Run from the repo root: python3 tools/make_textures.py
"""
import os
import struct

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Media")


def write_tga(name, width, height, pixel):
    """pixel(x, y) -> (r, g, b, a), ints 0..255; y = 0 is the TOP row."""
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, width, height, 32, 8)
    rows = []
    for y in range(height - 1, -1, -1):  # TGA rows are stored bottom to top
        row = bytearray()
        for x in range(width):
            r, g, b, a = pixel(x, y)
            row += bytes((b, g, r, a))
        rows.append(bytes(row))
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, name), "wb") as f:
        f.write(header + b"".join(rows))


def grey(v):
    return (v, v, v, 255)


def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)


def fill(x, y):
    # Subtle vertical shading; the palette colour and gradient are applied in game.
    return grey(255 - int(55 * y / 31))


def gloss(x, y):
    # White highlight fading out over the top half.
    a = int(90 * max(0.0, 1.0 - y / 15.0)) if y < 16 else 0
    return (255, 255, 255, a)


def glow(x, y):
    # Soft rounded rectangle used as a halo behind the neon fill (additive blend).
    ex = smoothstep(0, 16, min(x, 63 - x))
    ey = smoothstep(0, 12, min(y, 31 - y))
    return (255, 255, 255, int(255 * ex * ey))


def round_mask(x, y):
    # Pill-shaped alpha mask, 512x16 so the ends stay round on a typical 480x18 bar.
    w, h, r = 512, 16, 8.0
    cx = min(max(x + 0.5, r), w - r)
    cy = h / 2.0
    d = ((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2) ** 0.5
    a = max(0.0, min(1.0, r - d + 0.5))
    return (255, 255, 255, int(255 * a))


def spark(x, y):
    dx = abs(x - 7.5) / 7.5
    dy = abs(y - 31.5) / 31.5
    a = max(0.0, 1.0 - dx) ** 2 * max(0.0, 1.0 - dy) ** 0.5
    return (255, 255, 255, int(255 * a))


def tipbar(x, y):
    return (240, 190, 60, 255)


if __name__ == "__main__":
    write_tga("fill.tga", 128, 32, fill)
    write_tga("gloss.tga", 128, 32, gloss)
    write_tga("glow.tga", 64, 32, glow)
    write_tga("round-mask.tga", 512, 16, round_mask)
    write_tga("spark.tga", 16, 64, spark)
    write_tga("tipbar.tga", 16, 16, tipbar)
    print("textures written to", os.path.normpath(OUT))
