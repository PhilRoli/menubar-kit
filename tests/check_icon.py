"""Asserts a README icon PNG: 256x256 RGBA, transparent corners, opaque tile body."""
import struct, sys, zlib
data = open(sys.argv[1], "rb").read()
assert data[:8] == b"\x89PNG\r\n\x1a\n"
pos, idat, w = 8, b"", 0
while pos < len(data):
    n, kind = struct.unpack(">I4s", data[pos:pos + 8])
    body = data[pos + 8:pos + 8 + n]
    if kind == b"IHDR":
        w, h, depth, ctype = struct.unpack(">IIBB", body[:10])
        assert (w, h, depth, ctype) == (256, 256, 8, 6), (w, h, depth, ctype)
    if kind == b"IDAT":
        idat += body
    pos += 12 + n
raw = zlib.decompress(idat)
stride = 1 + w * 4
rows, prev = [], bytearray(w * 4)
for y in range(w):
    f, line = raw[y * stride], bytearray(raw[y * stride + 1:(y + 1) * stride])
    for i in range(len(line)):
        a = line[i - 4] if i >= 4 else 0
        b = prev[i]
        c = prev[i - 4] if i >= 4 else 0
        if f == 1: line[i] = (line[i] + a) & 255
        elif f == 2: line[i] = (line[i] + b) & 255
        elif f == 3: line[i] = (line[i] + (a + b) // 2) & 255
        elif f == 4:
            p = a + b - c
            pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
            line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
    rows.append(line)
    prev = line
alpha = lambda x, y: rows[y][x * 4 + 3]
assert alpha(0, 0) == 0 and alpha(255, 255) == 0, "corners must be transparent"
assert alpha(128, 40) == 255, "tile body must be opaque"
