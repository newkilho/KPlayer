"""Render the playlist window icons (List.pas) to 128px alpha-mask PNGs.

LCL has no SVG control (the Delphi build used TSVGIconImage), so the icons are
rasterised here once and tinted at runtime (List.pas: TIconButton). Output is
white RGBA with coverage in alpha: Res/list-<name>.png. The PNGs are linked as
RCDATA via KPlayerResource.rc.

Run after changing an icon, commit the PNGs (no build event - same policy as
MakeIconRes.py). Needs Pillow only.

    python Tools/MakeListIcons.py
"""

import math
import os
import re

from PIL import Image, ImageDraw

OUT = 128          # stored size; List.pas downsamples to the DPI size
SUPER = 8          # supersampling factor for antialiasing
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEST = os.path.join(ROOT, 'Res')

# name: (viewBox size, fill paths, stroke paths, stroke width)
ICONS = {
    'repeat': (24, [
        'M8 20v1.932a.5.5 0 0 1-.82.385l-4.12-3.433A.5.5 0 0 1 3.382 18H18a2 2 0 0 0 2-2V8h2v8a4 4 0 0 1-4 4H8zm8-16V2.068a.5.5 0 0 1 .82-.385l4.12 3.433a.5.5 0 0 1-.321.884H6a2 2 0 0 0-2 2v8H2V8a4 4 0 0 1 4-4h10z',
    ], [], 0),
    'repeat-one': (24, [
        'M8 20v1.932a.5.5 0 0 1-.82.385l-4.12-3.433A.5.5 0 0 1 3.382 18H18a2 2 0 0 0 2-2V8h2v8a4 4 0 0 1-4 4H8zm8-17.932a.5.5 0 0 1 .82-.385l4.12 3.433a.5.5 0 0 1-.321.884H6a2 2 0 0 0-2 2v8H2V8a4 4 0 0 1 4-4h10V2.068zM11 8h2v8h-2v-6H9V9l2-1z',
    ], [], 0),
    'random': (256, [
        'M237.65723,178.34277a8.00122,8.00122,0,0,1,0,11.31446l-24,24A8.00066,8.00066,0,0,1,200,208V191.98584a72.13911,72.13911,0,0,1-57.65332-30.13721L100.63379,103.4502A56.11029,56.11029,0,0,0,55.06445,80H32a8,8,0,0,1,0-16H55.06445a72.14126,72.14126,0,0,1,58.58887,30.15137l41.71289,58.39843A56.0996,56.0996,0,0,0,200,175.97168V160a8.00065,8.00065,0,0,1,13.65723-5.65723Zm-94.64356-71.36132a7.99621,7.99621,0,0,0,11.15918-1.86036l1.19336-1.67089A56.0996,56.0996,0,0,1,200,80.02832V96a8.00053,8.00053,0,0,0,13.65723,5.65723l24-24a8.00122,8.00122,0,0,0,0-11.31446l-24-24A8.00065,8.00065,0,0,0,200,48V64.01416a72.13911,72.13911,0,0,0-57.65332,30.13721l-1.19336,1.6709A7.9986,7.9986,0,0,0,143.01367,106.98145Zm-30.02734,42.0371a7.99642,7.99642,0,0,0-11.15918,1.86036l-1.19336,1.67089A56.11029,56.11029,0,0,1,55.06445,176H32a8,8,0,0,0,0,16H55.06445a72.14126,72.14126,0,0,0,58.58887-30.15137l1.19336-1.6709A7.9986,7.9986,0,0,0,112.98633,149.01855Z',
    ], [], 0),
    'plus': (24, [], ['M6 12H18M12 6V18'], 2),
    'minus': (24, [], ['M6 12L18 12'], 2),
}

TOKEN = re.compile(r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')


def tokens(d):
    return TOKEN.findall(d)


def arc_points(x1, y1, rx, ry, phi, large, sweep, x2, y2, steps=48):
    """SVG endpoint arc -> points (excluding start). SVG 1.1 F.6.5."""
    if rx == 0 or ry == 0:
        return [(x2, y2)]
    rx, ry = abs(rx), abs(ry)
    cp, sp = math.cos(math.radians(phi)), math.sin(math.radians(phi))
    dx, dy = (x1 - x2) / 2, (y1 - y2) / 2
    x1p = cp * dx + sp * dy
    y1p = -sp * dx + cp * dy
    lam = (x1p ** 2) / (rx ** 2) + (y1p ** 2) / (ry ** 2)
    if lam > 1:
        s = math.sqrt(lam)
        rx, ry = rx * s, ry * s
    num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
    den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
    co = math.sqrt(max(0.0, num / den)) if den else 0.0
    if large == sweep:
        co = -co
    cxp = co * rx * y1p / ry
    cyp = -co * ry * x1p / rx
    cx = cp * cxp - sp * cyp + (x1 + x2) / 2
    cy = sp * cxp + cp * cyp + (y1 + y2) / 2

    def ang(ux, uy, vx, vy):
        a = math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)
        return a

    t1 = ang(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
    dt = ang((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
    if not sweep and dt > 0:
        dt -= 2 * math.pi
    elif sweep and dt < 0:
        dt += 2 * math.pi
    n = max(4, int(steps * abs(dt) / (2 * math.pi)) + 1)
    pts = []
    for i in range(1, n + 1):
        t = t1 + dt * i / n
        x = cx + rx * math.cos(t) * cp - ry * math.sin(t) * sp
        y = cy + rx * math.cos(t) * sp + ry * math.sin(t) * cp
        pts.append((x, y))
    pts[-1] = (x2, y2)
    return pts


def cubic(p0, p1, p2, p3, steps=24):
    out = []
    for i in range(1, steps + 1):
        t = i / steps
        mt = 1 - t
        out.append((
            mt ** 3 * p0[0] + 3 * mt * mt * t * p1[0] + 3 * mt * t * t * p2[0] + t ** 3 * p3[0],
            mt ** 3 * p0[1] + 3 * mt * mt * t * p1[1] + 3 * mt * t * t * p2[1] + t ** 3 * p3[1],
        ))
    return out


def flatten(d):
    """Path data -> list of subpaths (point lists)."""
    tk = tokens(d)
    i = 0
    subs, cur = [], []
    x = y = sx = sy = 0.0
    cmd = None
    last_c2 = None

    def num():
        nonlocal i
        v = float(tk[i])
        i += 1
        return v

    def flag():
        # flags may be packed ("01" is two flags); the tokenizer keeps "0 1-.8" apart
        nonlocal i
        t = tk[i]
        if len(t) > 1 and t[0] in '01' and not t.startswith(('0.', '1.')):
            tk[i] = t[1:]
            return int(t[0])
        i += 1
        return int(float(t))

    while i < len(tk):
        t = tk[i]
        if re.match(r'[A-Za-z]', t):
            cmd = t
            i += 1
            if cmd in 'Zz':
                if cur:
                    subs.append(cur)
                cur = []
                x, y = sx, sy
                continue
        rel = cmd.islower()
        c = cmd.upper()
        if c == 'M':
            nx, ny = num(), num()
            if rel:
                nx, ny = x + nx, y + ny
            if cur:
                subs.append(cur)
            cur = [(nx, ny)]
            x, y = sx, sy = nx, ny
            cmd = 'l' if rel else 'L'
        elif c == 'L':
            nx, ny = num(), num()
            if rel:
                nx, ny = x + nx, y + ny
            cur.append((nx, ny))
            x, y = nx, ny
        elif c == 'H':
            nx = num()
            x = x + nx if rel else nx
            cur.append((x, y))
        elif c == 'V':
            ny = num()
            y = y + ny if rel else ny
            cur.append((x, y))
        elif c == 'C':
            a = [num() for _ in range(6)]
            if rel:
                a = [a[0] + x, a[1] + y, a[2] + x, a[3] + y, a[4] + x, a[5] + y]
            cur += cubic((x, y), (a[0], a[1]), (a[2], a[3]), (a[4], a[5]))
            last_c2 = (a[2], a[3])
            x, y = a[4], a[5]
        elif c == 'S':
            a = [num() for _ in range(4)]
            if rel:
                a = [a[0] + x, a[1] + y, a[2] + x, a[3] + y]
            c1 = (2 * x - last_c2[0], 2 * y - last_c2[1]) if last_c2 else (x, y)
            cur += cubic((x, y), c1, (a[0], a[1]), (a[2], a[3]))
            last_c2 = (a[0], a[1])
            x, y = a[2], a[3]
        elif c == 'A':
            rx, ry, phi = num(), num(), num()
            large, sweep = flag(), flag()
            nx, ny = num(), num()
            if rel:
                nx, ny = x + nx, y + ny
            cur += arc_points(x, y, rx, ry, phi, large, sweep, nx, ny)
            x, y = nx, ny
        else:
            raise ValueError('unsupported path command ' + cmd)
        if c not in 'CS':
            last_c2 = None
    if cur:
        subs.append(cur)
    return subs


def render(name, spec):
    vb, fills, strokes, sw = spec
    size = OUT * SUPER
    k = size / vb
    img = Image.new('L', (size, size), 0)
    dr = ImageDraw.Draw(img)
    for d in fills:
        for sub in flatten(d):
            if len(sub) >= 3:
                dr.polygon([(px * k, py * k) for px, py in sub], fill=255)
    for d in strokes:
        w = sw * k
        for sub in flatten(d):
            pts = [(px * k, py * k) for px, py in sub]
            dr.line(pts, fill=255, width=int(round(w)))
            for px, py in (pts[0], pts[-1]):
                dr.ellipse([px - w / 2, py - w / 2, px + w / 2, py + w / 2], fill=255)
    mask = img.resize((OUT, OUT), Image.LANCZOS)
    out = Image.new('RGBA', (OUT, OUT), (255, 255, 255, 0))
    out.putalpha(mask)
    os.makedirs(DEST, exist_ok=True)
    path = os.path.join(DEST, 'list-%s.png' % name)
    out.save(path, optimize=True)
    print(path)


if __name__ == '__main__':
    for n, s in ICONS.items():
        render(n, s)
