# KPlayerResource.rc 의 RCDATA 줄 → KPlayerResource.res (RES32 직접 작성).
# windres 를 안 쓰는 이유: Lazarus 에 딸린 windres 는 C 전처리기(cc1)가 없어 "preprocessing failed" 로 죽는다
# (2026-09-29 실측). .rc 는 목록 역할만 한다 — 형식: <이름> RCDATA "<파일>" (한 줄에 하나, 주석 /* */ 무시).
# 이름은 대문자로 넣는다 (rc/windres 와 같음 — FindResource 는 대소문자 무시).
# 실행: python Tools\MakeRes.py   (build.bat 이 원본이 더 새로우면 부른다)
import os
import re
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RC = os.path.join(ROOT, 'KPlayerResource.rc')
OUT = os.path.join(ROOT, 'KPlayerResource.res')

RT_RCDATA = 10
LANG = 0x0409


def pad4(b):
    return b + b'\0' * ((-len(b)) % 4)


def entry(rtype, name, data, flags=0x0030, lang=LANG):
    t = struct.pack('<HH', 0xFFFF, rtype) if isinstance(rtype, int) else (rtype + '\0').encode('utf-16-le')
    n = struct.pack('<HH', 0xFFFF, name) if isinstance(name, int) else (name + '\0').encode('utf-16-le')
    tn = pad4(t + n)
    tail = struct.pack('<IHHII', 0, flags, lang, 0, 0)
    header_size = 8 + len(tn) + len(tail)
    hdr = struct.pack('<II', len(data), header_size) + tn + tail
    return hdr + pad4(data)


def main():
    text = open(RC, encoding='ascii').read()
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    items = re.findall(r'^\s*([\w\-]+)\s+RCDATA\s+"([^"]+)"', text, flags=re.M)
    assert items, 'no RCDATA lines in ' + RC

    # 빈 선두 항목 = RES32 서명 (MakeIconRes.py 와 같음 — 플래그/언어 0)
    out = [entry(0, 0, b'', flags=0, lang=0)]
    for name, path in items:
        path = path.replace('\\\\', '\\')
        with open(os.path.join(ROOT, path), 'rb') as f:
            data = f.read()
        out.append(entry(RT_RCDATA, name.upper(), data))
        print('%-18s %8d  %s' % (name.upper(), len(data), path))

    with open(OUT, 'wb') as f:
        f.write(b''.join(out))
    print('-> ' + OUT)


if __name__ == '__main__':
    main()
