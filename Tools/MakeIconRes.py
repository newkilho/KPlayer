# Icon\*.ico → KPlayerIcons.res (RT_ICON/RT_GROUP_ICON) + IconIds.inc (확장자 → 그룹 ID 표).
# .rc 로 못 하는 이유: 리소스 컴파일러가 RT_ICON ID 를 1 부터 매겨 IDE 가 만드는 KPlayer.res 의
# MAINICON(RT_ICON 1·2·3) 과 충돌 → 링커가 한쪽을 버려 그림이 엉킨다. 여기서는 RT_ICON 1000+,
# RT_GROUP_ICON 40000+ (ZipMania 와 동일 대역) 로 직접 쓴다.
# 실행: python Tools\MakeIconRes.py   (Icon\ 이 바뀔 때만. 출력 둘 다 저장소에 넣는다)
# DefaultIcon 레지스트리 값 = "<exe>",-<그룹 ID>  (Assoc.ExtIconRef)
import struct, glob, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_DIR = os.path.join(ROOT, 'Icon')
RES_OUT = os.path.join(ROOT, 'KPlayerIcons.res')
INC_OUT = os.path.join(ROOT, 'IconIds.inc')

RT_ICON, RT_GROUP_ICON = 3, 14
FIRST_IMAGE_ID = 1000
FIRST_GROUP_ID = 40000
LANG = 0x0409   # KPlayer.res (VerInfo_Locale 1033) 와 동일


def res_entry(rtype, rid, data, flags=0x1010, lang=None):
    # RES32: DataSize, HeaderSize, Type(0xFFFF,id), Name(0xFFFF,id), DataVersion, MemFlags, Lang, Version, Chars
    if lang is None:
        lang = LANG
    hdr = struct.pack('<IIHHHHIHHII', len(data), 32, 0xFFFF, rtype, 0xFFFF, rid, 0, flags, lang, 0, 0)
    pad = (-len(data)) % 4
    return hdr + data + b'\0' * pad


def read_ico(path):
    with open(path, 'rb') as f:
        buf = f.read()
    reserved, itype, count = struct.unpack_from('<HHH', buf, 0)
    assert reserved == 0 and itype == 1, path
    entries = []
    for i in range(count):
        w, h, cc, rsv, planes, bits, size, off = struct.unpack_from('<BBBBHHII', buf, 6 + i * 16)
        entries.append((w, h, cc, rsv, planes, bits, buf[off:off + size]))
    return entries


def main():
    files = sorted(glob.glob(os.path.join(ICON_DIR, '*.ico')), key=lambda p: os.path.basename(p).lower())
    assert files, 'Icon\\*.ico 없음'

    # 빈 선두 항목 = RES32 서명. HeaderSize 0x20 외 전부 0 — 플래그/언어를 채우면 RLINK32 가
    # 'Unsupported 16bit resource' 로 거부한다 (2026-09-13 실측).
    out = [res_entry(0, 0, b'', flags=0, lang=0)]
    table = []
    image_id = FIRST_IMAGE_ID
    for gi, path in enumerate(files):
        ext = os.path.splitext(os.path.basename(path))[0].lower()
        group_id = FIRST_GROUP_ID + gi
        images = read_ico(path)
        grp = struct.pack('<HHH', 0, 1, len(images))
        for (w, h, cc, rsv, planes, bits, data) in images:
            out.append(res_entry(RT_ICON, image_id, data))
            grp += struct.pack('<BBBBHHIH', w, h, cc, rsv, planes, bits, len(data), image_id)
            image_id += 1
        out.append(res_entry(RT_GROUP_ICON, group_id, grp))
        table.append((ext, group_id))

    with open(RES_OUT, 'wb') as f:
        f.write(b''.join(out))

    lines = ['// Tools\\MakeIconRes.py 가 생성한다. 손으로 고치지 않는다. 확장자(점 없음) → KPlayerIcons.res 의 RT_GROUP_ICON ID.',
             'const',
             '  IconIds: array[0..%d] of record Ext: string; Id: Word; end = (' % (len(table) - 1)]
    lines += ['    (Ext: %-8s Id: %d)%s' % ("'%s';" % ext, gid, ',' if i < len(table) - 1 else '')
              for i, (ext, gid) in enumerate(table)]
    lines.append('  );')
    with open(INC_OUT, 'w', encoding='utf-8-sig', newline='\r\n') as f:
        f.write('\n'.join(lines) + '\n')

    print('%d icons, %d images -> %s, %s' % (len(table), image_id - FIRST_IMAGE_ID, RES_OUT, INC_OUT))


if __name__ == '__main__':
    main()
