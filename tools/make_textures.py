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


def flat(x, y):
    return grey(255)


def gradient(x, y):
    return grey(255 - int(85 * y / 15))


def glossy(x, y):
    if y == 0:
        return grey(255)
    if y < 8:
        return grey(max(225, 245 - 3 * y))
    return grey(max(140, 195 - 6 * (y - 8)))


def spark(x, y):
    dx = abs(x - 7.5) / 7.5
    dy = abs(y - 31.5) / 31.5
    a = max(0.0, 1.0 - dx) ** 2 * max(0.0, 1.0 - dy) ** 0.5
    return (255, 255, 255, int(255 * a))


def tipbar(x, y):
    return (240, 190, 60, 255)


if __name__ == "__main__":
    write_tga("flat.tga", 128, 16, flat)
    write_tga("gradient.tga", 128, 16, gradient)
    write_tga("glossy.tga", 128, 16, glossy)
    write_tga("spark.tga", 16, 64, spark)
    write_tga("tipbar.tga", 16, 16, tipbar)
    print("textures written to", os.path.normpath(OUT))
