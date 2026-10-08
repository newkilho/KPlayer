# 하단 시간 칩의 7세그먼트 숫자 → ui\icons\dg-*.svg (fill=currentColor). 직접 그린 5×9, 획 굵기 1.
# 경과: NLDDigiLabel(D:\Component\Delphi\NLDDigiLabel) DEFAULT_(10X20) → 07X15 → 더 작고 선명하게 이 5×9 (사용자 요청 2026-10-08).
# 7×12 획 2 로 굵게도 해 봤으나 취소 (사용자 결정 2026-10-08).
# 1px 획은 픽셀 칸에 딱 맞아야 선명하다 — 뾰족한 획 끝·매끈한 사선은 안티앨리어싱으로 회색 번짐 (캡처 실측).
# 그래서 획 = 정수 사각형, 모서리 픽셀은 비워 획 마디를 보이게, '/' 는 줄마다 1칸 계단.
# 꺼진 획은 dg-8(전 획)을 어두운 색으로 깔아 표현 (CSS). 칸을 정수 위치에 놓는 것도 CSS 몫 (#time).
# 결과 svg 는 커밋한다 (빌드 이벤트 없음 — MakeListIcons.py 와 같음). 새 파일이면 KPlayerResource.rc 에 줄 추가.
# 실행: python Tools\MakeDigits.py
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'ui', 'icons')

W, H = 5, 9
MID = 4   # 가운데 가로 획의 줄 (위 칸 1~3, 아래 칸 5~7)

# 획 = (x, y, 폭, 높이). a 위 b 오른쪽 위 c 오른쪽 아래 d 아래 e 왼쪽 아래 f 왼쪽 위 g 가운데
SEG = {
    'a': (1, 0, W - 2, 1),
    'b': (W - 1, 1, 1, MID - 1),
    'c': (W - 1, MID + 1, 1, H - MID - 2),
    'd': (1, H - 1, W - 2, 1),
    'e': (0, MID + 1, 1, H - MID - 2),
    'f': (0, 1, 1, MID - 1),
    'g': (1, MID, W - 2, 1),
}
DIGIT = ['abcdef', 'bc', 'abdeg', 'abcdg', 'bcfg', 'acdfg', 'acdefg', 'abc', 'abcdefg', 'abcdfg']


def rect(x, y, w, h):
    return 'M%d %dh%dv%dh%dZ' % (x, y, w, h, -w)


def write(name, w, h, paths):
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d">'
           '<path fill="currentColor" d="%s"/></svg>') % (w, h, ''.join(paths))
    with open(os.path.join(OUT, name), 'w', newline='\n') as f:
        f.write(svg)


def main():
    for n, segs in enumerate(DIGIT):
        write('dg-%d.svg' % n, W, H, [rect(*SEG[s]) for s in segs])
    # ':' — 1px 점 둘, 위·아래 칸 각각의 가운데
    write('dg-col.svg', 1, H, [rect(0, MID // 2, 1, 1), rect(0, H - 1 - MID // 2, 1, 1)])
    # '/' — 14세그먼트식 사선 획 둘 (오른쪽 위 ↗, 왼쪽 아래 ↙), 가운데 줄에서 끊김. 줄마다 1칸 계단
    x0, y0, x1, y1 = W - 1, 1, 0, H - 2   # 위 첫 줄 칸 x · 아래 끝 줄 칸 x

    def col(y):
        return round(x0 + (x1 - x0) * (y - y0) / (y1 - y0))
    write('dg-sl.svg', W, H, [rect(col(y), y, 1, 1) for y in range(1, H - 1) if y != MID])


main()
