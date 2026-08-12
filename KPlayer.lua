-- ==============================================================
-- 프로젝트 : KPlayer
-- 작성자   : Kilho, Oh
-- ==============================================================

local mp = require 'mp'
local assdraw = require 'mp.assdraw'
local opt = require 'mp.options'
local msg = require 'mp.msg'

-- 옵션
local options = {
    -- 하단 컨트롤 전체 높이 = 진행바 16 + 간격 2 + 버튼줄 48 + 아래 여백 8
    bar_height = 74,
    bar_margin = 0,
    autohide_timeout = 2,
    -- 유튜브 진행바: 평상시 2px, hover 시 4px
    seekbar_height = 2,
    seekbar_hover_height = 4,
    seekbar_padding = 12,
    volume_width = 60,
    thumbnail_enabled = false,
    font_size = 14,
    bg_alpha = 0.55,
    -- 하단 컨트롤 배경. 0=버튼·시간 칩 배경만으로 대비(유튜브 2024+), >0=그 알파로 아래가 짙어지는 그라데이션.
    bottom_scrim_alpha = 0,
    topbar_height = 32,
    -- 제목용. 한글·영문 한 폰트여야 같은 \fs 에서 한글만 안 작아짐. 실제 값은
    -- Delphi 가 시작 시 script-message ui-font 로 전달(OS UI 기본 폰트); 이건 그때까지의 기본값.
    topbar_font = "Malgun Gothic",
    -- 숫자(시간·볼륨·배속)용. approx_text_w() 근사가 Arial 숫자 기준(0.56em) — 바꾸면 시간 칩·툴팁 폭 어긋남.
    num_font = "Arial",
    -- \fs 는 em 아닌 줄높이(ascent+descent) 기준 — 맑은 고딕 upem 2048/줄높이 2724,
    -- \fs 20 = em 13px(100% DPI). 캡션바와 나란히 맞춘 값 — 폰트 바꾸면 재측정.
    topbar_font_size = 18,
    -- 상단바 배율. 0=display-hidpi-scale 따름 — 임베드(--wid) 시 1.0 으로 보고되는 경우가 있어 그때만 실제 배율 기입.
    topbar_scale = 0,
}
opt.read_options(options, "controls")

-- 상태
local state = {
    visible = false,
    mouse_x = 0,
    mouse_y = 0,
    osd_w = 1280,
    osd_h = 720,
    duration = 0,
    position = 0,
    paused = false,
    volume = 100,
    muted = false,
    fullscreen = false,
    dpi = 1.0,
    idle = false,
    seeking = false,
    seek_target = 0,
    hover_seekbar = false,
    hover_play = false,
    hover_volume = false,
    hover_fullscreen = false,
    hover_mute = false,
    autohide_timer = nil,
    chapter_list = {},
    speed = 1.0,
    speed_toast_text = "",
    speed_toast_until = nil,
    speed_toast_timer = nil,

    -- 중앙 알림 (Delphi 가 script-message alert 로 전송)
    alert_text  = "",
    alert_color = nil,
    alert_from  = nil,
    alert_until = nil,
    alert_timer = nil,
    -- 중앙 인디케이터(반투명 원+아이콘, 볼륨이면 상단 숫자). 볼륨 조절·재생/일시정지에서 잠깐 표시.
    bezel_icon = nil,
    bezel_text = nil,   -- 숫자 알약. nil=아이콘만
    bezel_from = nil,
    bezel_until = nil,
    bezel_timer = nil,
    -- observer 는 등록 직후 현재 값으로 1회 호출 — 그 최초 호출엔 표시 안 함(실행마다 인디케이터 뜨는 것 방지).
    vol_ready = false,
    pause_ready = false,
    sub_visible = false,
    has_sub = false,
    cursor_hidden = false,
    sub_margin = nil,      -- 마지막으로 설정한 sub-margin-y (같은 값 재설정 방지)
    filename = "",
    hover_close = false,
    hover_topbar_min = false,
    hover_topbar_fs = false,
    hover_list = false,
    hover_settings = false,
    hover_sub = false,
    hover_prev = false,
    hover_next = false,
    hover_vol_area = false,
    -- 유튜브식: 스피커 hover 시에만 음량 슬라이더 펼침
    vol_expanded = false,
    -- 누르고 있는 요소명 (CSS :active) — "play", "seek" …
    pressed = nil,
    -- 드래그로 조작 중인 대상 — nil / "seek" / "volume"
    dragging = nil,
    -- 컨트롤 전체 불투명도 0..1. 페이드 애니메이션이 구동.
    opacity = 0,
}

-- 유틸리티
local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function format_time(seconds)
    if not seconds or seconds < 0 then return "0:00" end
    seconds = math.floor(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    else
        return string.format("%d:%02d", m, s)
    end
end

local function ass_escape(str)
    str = str:gsub("\\", "\\\\")
    str = str:gsub("{", "\\{")
    return str
end

-- ==============================================================
-- 상단바. 아래 값 전부 논리 픽셀 — mpv 의 osd-width/osd-height 는 물리
-- 픽셀이라 그릴 때 display-hidpi-scale 곱함 (tb 테이블).
-- ==============================================================
local TOPBAR_H          = options.topbar_height  -- 윈도우 기본 캡션바와 같은 32
local TOPBAR_SCRIM_H    = 24    -- 바 아래로 더 그리는 그라데이션 꼬리
local CAP_SLOT_W        = 46    -- 캡션 버튼 슬롯 너비(윈도우 기본), 높이는 바 전체
local GLYPH_HALF        = 5     -- 글리프 반경 (≈10px 아이콘)
local GLYPH_LINE_W      = 1     -- 글리프 선 두께 (hairline)
local TITLE_X           = 14    -- 제목 좌측 여백
local TITLE_RIGHT_LIMIT = 144   -- 제목 우측 한계 폭 (버튼 3슬롯 회피)

-- 스크림 알파 곡선: 바 구간 0.92→0.72 선형, 꼬리 0.72*(1-u)^2 (제곱 감쇠라 끝이 안 뭉툭)
local SCRIM_A_TOP    = 0.92
local SCRIM_A_BOT    = 0.72
-- 그라데이션 근사 스트립 높이(정수 px). 바 구간은 알파 거의 평평해 굵게, 꼬리는 급감쇠라 1px.
local SCRIM_STEP_BAR  = 4
local SCRIM_STEP_TAIL = 1

-- DPI 곱한 실제 그리기 치수. state.dpi 변경 시에만 재계산.
local tb = {}
local _scrim_strips = nil

-- 실제 배율: 옵션 지정값 우선, 아니면 mpv 보고값.
local function ui_scale()
    local o = options.topbar_scale
    if o and o > 0 then return o end
    return state.dpi
end

local function apply_ui_scale()
    local s = ui_scale()
    tb.h          = math.floor(TOPBAR_H * s + 0.5)
    tb.scrim_h    = math.floor(TOPBAR_SCRIM_H * s + 0.5)
    -- 슬롯 폭·제목 우측 한계는 정수 필수 — 슬롯 경계 소수점이면 닫기 hover 배경
    -- 가장자리가 부분 커버리지로 흐려지고, 우측 한계는 \clip 의 %d 로 들어감.
    tb.slot_w     = math.floor(CAP_SLOT_W * s + 0.5)
    tb.glyph      = GLYPH_HALF * s
    tb.line_w     = math.max(1, math.floor(GLYPH_LINE_W * s + 0.5))
    tb.font_px    = math.floor(options.topbar_font_size * s + 0.5)
    tb.title_x    = TITLE_X * s
    tb.right_lim  = math.floor(TITLE_RIGHT_LIMIT * s + 0.5)
    tb.step_bar   = math.max(1, math.floor(SCRIM_STEP_BAR * s + 0.5))
    tb.step_tail  = math.max(1, math.floor(SCRIM_STEP_TAIL * s + 0.5))
    _scrim_strips = nil
    -- 배율 1.00 인데 화면이 실제 확대 상태면 mpv 가 DPI 못 읽은 것 → topbar_scale 옵션에 실제 배율 기입.
    msg.info(string.format("topbar scale %.2f - bar %dpx, title %dpx", s, tb.h, tb.font_px))
end

-- 색상
local color = {
    red         = "0000FF",
    red_hover   = "1A1AFF",
    white       = "FFFFFF",
    white_dim   = "CCCCCC",
    dark        = "000000",
    dark_bar    = "141414",
    gray        = "888888",
    gray_light  = "AAAAAA",
    -- 하단 컨트롤 트랙·칩 배경은 고정색 아닌 흰/검 + 알파.
    -- 상단바 (ASS 색상은 BGR)
    scrim       = "0A0A0A",
    -- 제목은 순백 — #CCCCCC 는 반투명 스크림 위 1px 획 대비 부족.
    title       = "FFFFFF",
    cap_idle    = "CCCCCC",  -- 캡션 글리프 평상시
    cap_hover   = "FFFFFF",  -- 캡션 글리프 hover
    close_bg    = "2311E8",  -- 닫기 hover 배경 #E81123
    logo_mark   = "222222",  -- 시작 화면 워드마크
}

-- ASS 알파: 0=불투명, 클수록 흐림. 색을 흐리는 게 아니라 배경색에 섞음 — 검정 배경에선 색을 밝게 잡아야 보임.
local alpha = {
    bar_bg   = string.format("%02X", math.floor((1 - options.bg_alpha) * 255)),
    full     = "00",
    half     = "80",
    hidden   = "FF",
    logo_mark       = "80",   -- 배경 워드마크
    -- 받침 원은 워드마크보다 어둡게, 삼각형은 한 단계만 밝게 — 밝기 순서 뒤집히면 글자가 원 앞을 지나는 듯 보임.
    logo_disc       = "E0",
    logo_play       = "AA",
}

-- 시작 화면 로고.
--   LOGO_FONT    : 워드마크 폰트. libass 는 폰트 목록 불가 — 이름 하나, Windows·macOS 공통 폰트.
--   LOGO_TILT    : \frz 각도(도). 반시계라 양수=오른쪽 올라감.
--   LOGO_FILL    : 워드마크가 창 폭의 몇 할
--   LOGO_MARK_ADV: 워드마크 폭 / \fs. Arial Black+"KPlayer" 실측, 기울여도 가로폭 거의 동일. 폰트 바꾸면 재측정.
--   LOGO_MARK_H  : 세로 상한 (가로로 긴 창에서만 걸림)
--   LOGO_MARK_DY : 워드마크를 아이콘 반지름의 몇 배 올릴지 (음수=위). 0 이면 글자 가운데를 아이콘이 가림.
local LOGO_FONT    = "Arial Black"
local LOGO_TILT    = 18
local LOGO_FILL    = 1.60
local LOGO_MARK_ADV = 3.8
local LOGO_MARK_H  = 0.45
local LOGO_MARK_DY = -0.9

-- ==============================================================
-- 하단 컨트롤 — 유튜브(2024+) 칩 스타일
-- CSS 원본 대응:
--   .ctrl-btn      40x40, radius 20, bg rgba(0,0,0,0.35), hover rgba(255,255,255,0.25)
--   .chip-group    prev/play/next 를 하나의 알약 배경에 묶음 (padding 2, gap 2)
--   .time-display  높이 40, radius 20, 좌우 padding 14, 같은 칩 배경
--   .progress      hit 영역 16px, 트랙 2px(hover 4px), thumb 13px
-- ASS 알파는 불투명도의 반대다: 알파바이트 = (1 - opacity) * 255
-- ==============================================================
local CTRL_PAD_B   = 8      -- 컨트롤 아래 여백
local PROGRESS_H   = 16     -- 진행바 hit 영역 높이
local PROGRESS_GAP = 2      -- 진행바 ↔ 버튼줄 간격
local ROW_H        = 48     -- 버튼줄 높이
local BTN_SIZE     = 40     -- 칩 버튼 한 변
local BTN_R        = 20     -- 칩 버튼 모서리 반경(= 원)
local BTN_GAP      = 8      -- 칩 사이 간격
local CHIP_PAD     = 2      -- 그룹 알약 안쪽 여백
local CHIP_GAP     = 2      -- 그룹 안 버튼 간격
local ICON_SIZE    = 24     -- 아이콘 박스 (svg 24x24)
local ICON_SIZE_CC = 28     -- 자막 아이콘만 viewBox 확대(2 2 20 20)를 반영
local VOL_SLIDER_M = 8      -- 슬라이더 좌우 여백
local VOL_TRACK_H  = 2      -- 음량 트랙 두께
local VOL_THUMB_R  = 6      -- 음량 thumb 반경 (12px)
local SEEK_THUMB_R = 6.5    -- 진행바 thumb 반경 (13px)
local TIME_PAD_X   = 14     -- 시간 칩 좌우 padding

local A_CHIP_BG    = "A6"   -- rgba(0,0,0,0.35)
local A_CHIP_HOVER = "BF"   -- rgba(255,255,255,0.25)
local A_TRACK      = "BF"   -- rgba(255,255,255,0.25)  진행바 트랙
local A_VOL_TRACK  = "A6"   -- rgba(255,255,255,0.35)  음량 트랙
local A_TOOLTIP    = "26"   -- rgba(0,0,0,0.85)

-- 애니메이션 (CSS transition 대응). 값 0..1 보관, 픽셀/알파 변환은 사용처에서.
-- 보간은 지수감쇠(ease-out) — 목표 안 넘고, tau=dur/3 이면 dur 내 약 95% 도달.
local ANIM_FADE  = 0.20   -- .controls   opacity   .2s
local ANIM_SEEK  = 0.10   -- .progress   height    .1s
local ANIM_THUMB = 0.10   -- thumb       scale     .1s
local ANIM_VOL   = 0.20   -- .volume-slider width  .2s
local ANIM_HOVER = 0.15   -- .ctrl-btn   background .15s
local ANIM_PRESS = 0.10   -- .ctrl-btn:active scale

local anims = {}

-- 목표 갱신 후 현재값 반환. 전진은 anim_step 이 한다.
local function anim(name, target, dur)
    local a = anims[name]
    if not a then
        a = { v = target, t = target }
        anims[name] = a
    end
    a.t = target
    a.tau = dur / 3
    return a.v
end

local function anim_step(dt)
    for _, a in pairs(anims) do
        if a.v ~= a.t then
            a.v = a.v + (a.t - a.v) * (1 - math.exp(-dt / a.tau))
            if math.abs(a.t - a.v) < 0.004 then a.v = a.t end
        end
    end
end

-- 미도달 값 존재 여부. 목표는 render() 안에서 갱신 — 반드시 render() 뒤에 검사해야 다음 프레임 예약됨.
local function anim_pending()
    for _, a in pairs(anims) do
        if a.v ~= a.t then return true end
    end
    return false
end

-- 컨트롤 소멸 후 hover/press/펼침을 0 으로 (fade 제외) — 안 하면 재표시 첫 프레임에 옛 hover 가 비침.
local function anim_reset()
    for name, a in pairs(anims) do
        if name ~= "fade" then a.v, a.t = 0, 0 end
    end
end

-- base 알파를 f(0..1)만큼 더 흐리게. 컨트롤 전체 페이드(state.opacity) 항상 함께 곱함.
local function fa(base, f)
    f = (f or 1) * state.opacity
    if f >= 0.999 then return base end
    if f <= 0.002 then return "FF" end
    local o = (255 - tonumber(base, 16)) * f
    return string.format("%02X", 255 - math.floor(o + 0.5))
end

-- 아이콘 (24x24 Material Design 을 ASS 벡터 경로로 옮긴 것)
local icons = {
    full_off = "{\\p1}m 0 0 m 24 24 m 6 8 l 4 8 l 4 18 b 4 19.1 4.9 20 6 20 l 16 20 l 16 18 l 6 18 m 18 4 l 10 4 b 8.9 4 8 4.9 8 6 l 8 14 b 8 15.1 8.9 16 10 16 l 18 16 b 19.1 16 20 15.1 20 14 l 20 6 b 20 4.9 19.1 4 18 4 m 18 14 l 10 14 l 10 6 l 18 6{\\p0}",
    full_on  = "{\\p1}m 0 0 m 24 24 m 3 3 l 21 3 l 21 21 l 3 21 m 5 5 l 5 19 l 19 19 l 19 5{\\p0}",
    vol_off  = "{\\p1}m 0 0 m 24 24 m 16.5 12 b 16.5 10.23 15.48 8.71 14 7.97 l 14 10.18 l 16.45 12.63 b 16.48 12.43 16.5 12.22 16.5 12 m 19 12 b 19 12.94 18.8 13.82 18.46 14.64 l 19.97 16.15 b 20.63 14.91 21 13.5 21 12 b 21 7.72 18.01 4.14 14 3.23 l 14 5.29 b 16.89 6.15 19 8.83 19 12 m 4.27 3 l 3 4.27 l 7.73 9 l 3 9 l 3 15 l 7 15 l 12 20 l 12 13.27 l 16.25 17.52 b 15.58 18.04 14.83 18.45 14 18.7 l 14 20.76 b 15.38 20.45 16.63 19.81 17.69 18.95 l 19.73 21 l 21 19.73 l 12 10.73 l 4.27 3 m 12 4 l 9.91 6.09 l 12 8.18{\\p0}",
    vol_on   = "{\\p1}m 0 0 m 24 24 m 3 9 l 3 15 l 7 15 l 12 20 l 12 4 l 7 9 m 16.5 12 b 16.5 10.23 15.48 8.71 14 7.97 l 14 16.02 b 15.48 15.29 16.5 13.77 16.5 12 m 14 3.23 l 14 5.29 b 16.89 6.15 19 8.83 19 12 b 19 15.17 16.89 17.85 14 18.71 l 14 20.77 b 18.01 19.86 21 16.28 21 12 b 21 7.72 18.01 4.14 14 3.23{\\p0}",
    close    = "{\\p1}m 0 0 m 24 24 m 19 6.41 l 17.59 5 l 12 10.59 l 6.41 5 l 5 6.41 l 10.59 12 l 5 17.59 l 6.41 19 l 12 13.41 l 17.59 19 l 19 17.59 l 13.41 12{\\p0}",
    pause    = "{\\p1}m 0 0 m 24 24 m 6 19 l 10 19 l 10 5 l 6 5 m 14 5 l 14 19 l 18 19 l 18 5{\\p0}",
    -- 재생목록. 원본 viewBox "9.2 9.4 18 18" → (x-9.2)*4/3, (y-9.4)*4/3 로 24x24 변환.
    -- 내용 중심 y 14.5 라 살짝 낮게 앉음 — 의도된 모양, 건드리지 말 것.
    list     = "{\\p1}m 0 0 m 24 24 m 17.77 16.03 l 17.77 25.16 25.32 20.6 17.77 16.04 17.77 16.04 m 2.67 16.03 l 14.75 16.03 14.75 19.07 2.67 19.07 m 2.67 3.84 l 20.8 3.84 20.8 6.88 2.67 6.88 m 2.67 9.93 l 20.8 9.93 20.8 12.97 2.67 12.97{\\p0}",
    play     = "{\\p1}m 0 0 m 24 24 m 8 5 l 8 19 l 19 12{\\p0}",
    next     = "{\\p1}m 0 0 m 24 24 m 6 18 l 14.5 12 l 6 6 l 6 18 m 16 6 l 16 18 l 18 18 l 18 6 l 16 6{\\p0}",
    prev     = "{\\p1}m 0 0 m 24 24 m 6 6 l 8 6 l 8 18 l 6 18 m 9.5 12 l 18 18 l 18 6{\\p0}",
    set      = "{\\p1}m 0 0 m 24 24 m 19.14 12.94 b 19.18 12.64 19.2 12.33 19.2 12 b 19.2 11.68 19.18 11.36 19.13 11.06 l 21.16 9.48 b 21.34 9.34 21.39 9.07 21.28 8.87 l 19.36 5.55 b 19.24 5.33 18.99 5.26 18.77 5.33 l 16.38 6.29 b 15.88 5.91 15.35 5.59 14.76 5.34 l 14.4 2.81 b 14.36 2.57 14.16 2.4 13.92 2.4 l 10.08 2.4 b 9.84 2.4 9.65 2.57 9.61 2.81 l 9.25 5.34 b 8.66 5.59 8.12 5.92 7.63 6.29 l 5.24 5.33 b 5.01 5.25 4.76 5.33 4.64 5.55 l 2.72 8.87 b 2.6 9.08 2.66 9.34 2.86 9.48 l 4.84 11.06 b 4.8 11.36 4.8 11.69 4.8 12 b 4.8 12.31 4.82 12.64 4.87 12.94 l 2.84 14.52 b 2.66 14.66 2.61 14.93 2.72 15.13 l 4.64 18.45 b 4.76 18.67 5.01 18.74 5.24 18.67 l 7.63 17.71 b 8.13 18.09 8.66 18.41 9.25 18.66 l 9.61 21.19 b 9.65 21.43 9.84 21.6 10.08 21.6 l 13.92 21.6 b 14.16 21.6 14.36 21.43 14.4 21.19 l 14.76 18.66 b 15.35 18.41 15.89 18.08 16.38 17.71 l 18.77 18.67 b 19 18.75 19.25 18.67 19.37 18.45 l 21.29 15.13 b 21.4 14.92 21.34 14.66 21.14 14.52 l 19.14 12.94 m 12 15.6 b 10.02 15.6 8.4 13.98 8.4 12 b 8.4 10.02 10.02 8.4 12 8.4 b 13.98 8.4 15.6 10.02 15.6 12 b 15.6 13.98 13.98 15.6 12 15.6{\\p0}",
    min      = "{\\p1}m 0 0 m 24 24 m 5 11 l 19 11 l 19 13 l 5 13{\\p0}",
    -- 자막(CC) — Material closed_caption 그대로
    sub      = "{\\p1}m 0 0 m 24 24 m 19 4 l 5 4 b 3.89 4 3 4.9 3 6 l 3 18 b 3 19.1 3.89 20 5 20 l 19 20 b 20.1 20 21 19.1 21 18 l 21 6 b 21 4.9 20.1 4 19 4 m 11 11 l 9.5 11 l 9.5 10.5 l 7.5 10.5 l 7.5 13.5 l 9.5 13.5 l 9.5 13 l 11 13 l 11 14 b 11 14.55 10.55 15 10 15 l 7 15 b 6.45 15 6 14.55 6 14 l 6 10 b 6 9.45 6.45 9 7 9 l 10 9 b 10.55 9 11 9.45 11 10 l 11 11 m 18 11 l 16.5 11 l 16.5 10.5 l 14.5 10.5 l 14.5 13.5 l 16.5 13.5 l 16.5 13 l 18 13 l 18 14 b 18 14.55 17.55 15 17 15 l 14 15 b 13.45 15 13 14.55 13 14 l 13 10 b 13 9.45 13.45 9 14 9 l 17 9 b 17.55 9 18 9.45 18 10 l 18 11{\\p0}",
}

-- 히트 판정
local function in_rect(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

-- libass 에 글자폭 측정 API 없음. Arial 숫자 기준 근사(숫자 0.56em, 구분자 0.30em) — num_font 바꾸면 계수 재측정.
local function approx_text_w(str, fs)
    local w = 0
    for i = 1, #str do
        local ch = str:sub(i, i)
        if ch == ":" or ch == " " or ch == "." then
            w = w + 0.30
        elseif ch == "/" then
            w = w + 0.34
        else
            w = w + 0.56
        end
    end
    return w * fs
end

-- 레이아웃
local layout = {}

-- 표시용 재생 위치. seek 드래그 중엔 커서 위치 — 탐색이 따라오기 전에도 손끝을 따라야 함.
local function display_pos()
    if state.dragging == "seek" and state.duration > 0 and layout.seekbar then
        local sb = layout.seekbar
        return clamp((state.mouse_x - sb.x) / sb.w, 0, 1) * state.duration
    end
    return state.position
end

local function calc_layout()
    local W = state.osd_w
    local H = state.osd_h
    local bh = options.bar_height
    local bm = options.bar_margin
    local pad = options.seekbar_padding

    layout.W = W
    layout.H = H

    local tbh = tb.h
    layout.topbar = { x = 0, y = 0, w = W, h = tbh }

    -- 캡션 슬롯 3개(최소화/최대화·복원/닫기). 슬롯이 상단바 높이 전체 = 히트 영역이 곧 슬롯 사각형.
    local sw = tb.slot_w
    local cy = tbh / 2
    layout.cap_min   = { x = W - 3 * sw, y = 0, w = sw, h = tbh, cx = W - 2.5 * sw, cy = cy }
    layout.cap_max   = { x = W - 2 * sw, y = 0, w = sw, h = tbh, cx = W - 1.5 * sw, cy = cy }
    layout.cap_close = { x = W - sw,     y = 0, w = sw, h = tbh, cx = W - 0.5 * sw, cy = cy }

    -- 정수 좌표 = 글리프 픽셀 격자 정렬 (소수점이면 획 흐려짐).
    layout.title_text = { x = math.floor(tb.title_x + 0.5), y = math.floor(cy + 0.5) }

    layout.bar = { x = 0, y = H - bh - bm, w = W, h = bh }

    -- 진행바: .progress 16px hit 영역, 트랙은 그 세로 중앙.
    layout.progress = {
        x  = pad,
        y  = layout.bar.y,
        w  = W - pad * 2,
        h  = PROGRESS_H,
        cy = layout.bar.y + PROGRESS_H / 2,
    }

    -- hover 트랙 굵어짐도 애니메이션 (.1s)
    local grow = anim("seek_h", state.hover_seekbar and 1 or 0, ANIM_SEEK)
    local sb_h = options.seekbar_height +
                 (options.seekbar_hover_height - options.seekbar_height) * grow
    layout.seekbar = {
        x = layout.progress.x,
        y = layout.progress.cy - sb_h / 2,
        w = layout.progress.w,
        h = sb_h,
    }

    -- 버튼줄
    local row_cy = layout.bar.y + PROGRESS_H + PROGRESS_GAP + ROW_H / 2
    local row_top = row_cy - BTN_SIZE / 2
    layout.row_cy = row_cy

    -- 왼쪽: prev/play/next 한 알약 그룹 (.chip-group)
    local gx = pad
    local group_w = CHIP_PAD * 2 + BTN_SIZE * 3 + CHIP_GAP * 2
    layout.chip_group = { x = gx, y = row_top, w = group_w, h = BTN_SIZE }
    local bx = gx + CHIP_PAD
    layout.prev_btn = { cx = bx + BTN_SIZE * 0.5,                 cy = row_cy }
    layout.play_btn = { cx = bx + BTN_SIZE * 1.5 + CHIP_GAP,      cy = row_cy, r = BTN_R }
    layout.next_btn = { cx = bx + BTN_SIZE * 2.5 + CHIP_GAP * 2,  cy = row_cy }

    -- 음량: 스피커 칩 + hover 시 펼쳐지는 슬라이더. 접힘=칩만, 펼침 후=슬라이더까지 판정 영역 — 경계 깜빡임 방지(히스테리시스).
    local vx = gx + group_w + BTN_GAP
    local vol_w = options.volume_width
    local exp_w = BTN_SIZE + VOL_SLIDER_M * 2 + vol_w
    -- 슬라이더 드래그 중엔 커서가 영역 밖이어도 펼침 유지
    local expanded = (state.dragging == "volume")
        or in_rect(state.mouse_x, state.mouse_y, vx, row_top, BTN_SIZE, BTN_SIZE)
    if not expanded and state.vol_expanded then
        expanded = in_rect(state.mouse_x, state.mouse_y, vx, row_top, exp_w, BTN_SIZE)
    end
    state.vol_expanded = expanded

    -- 히트 판정은 목표 상태(expanded)로, 그리기와 시간 칩 위치만 진행률(reveal)로.
    local reveal = anim("vol", expanded and 1 or 0, ANIM_VOL)
    layout.vol_btn    = { cx = vx + BTN_SIZE / 2, cy = row_cy }
    layout.vol_area   = { x = vx, y = row_top, h = BTN_SIZE,
                          w = BTN_SIZE + (exp_w - BTN_SIZE) * reveal }
    layout.vol_slider = { x = vx + BTN_SIZE + VOL_SLIDER_M, cy = row_cy, w = vol_w, h = VOL_TRACK_H }

    -- 시간 표시 칩 (.time-display)
    local time_str = format_time(display_pos()) .. " / " .. format_time(state.duration)
    local time_w = approx_text_w(time_str, options.font_size) + TIME_PAD_X * 2
    local tx = layout.vol_area.x + layout.vol_area.w + BTN_GAP
    layout.time_chip = { x = tx, y = row_top, w = time_w, h = BTN_SIZE }
    -- 칩 폭이 근사치라 좌측 padding 정렬이면 오차가 전부 우측 여백으로 몰림 — 글자는 칩 중앙.
    layout.time_text = { x = tx + time_w / 2, y = row_cy }

    -- 오른쪽: 자막 / 설정 / 재생목록 (오른쪽부터 채운다)
    local rx = W - pad - BTN_SIZE
    layout.list_btn     = { cx = rx + BTN_SIZE / 2, cy = row_cy }
    rx = rx - BTN_GAP - BTN_SIZE
    layout.settings_btn = { cx = rx + BTN_SIZE / 2, cy = row_cy }
    -- 자막 버튼은 자막 트랙 있을 때만. nil=그리기·hover·클릭 모두 생략, 오른쪽부터 채워 다른 버튼 안 밀림.
    if state.has_sub then
        rx = rx - BTN_GAP - BTN_SIZE
        layout.sub_btn = { cx = rx + BTN_SIZE / 2, cy = row_cy }
    else
        layout.sub_btn = nil
    end
end

-- 칩 버튼 히트 = 40x40 정사각 (CSS .ctrl-btn 박스).
local function hover_btn(mx, my, b)
    if not b then return false end
    return in_rect(mx, my, b.cx - BTN_SIZE / 2, b.cy - BTN_SIZE / 2, BTN_SIZE, BTN_SIZE)
end

local function set_hover(key, v)
    if state[key] == v then return false end
    state[key] = v
    return true
end

-- 창 드래그 억제. 호스트(Delphi)는 클릭 위치 무관 창 이동 시작 — 조작 요소 위면 알림 (script-message hit 1|0).
local function report_hit(v)
    if state.hit == v then return end
    state.hit = v
    mp.commandv("script-message", "hit", v and "1" or "0")
end

-- hover 갱신, 변경 여부 반환. false 이고 커서 추종 요소(진행바 툴팁)도 없으면 렌더 불요.
local function check_hover()
    local mx = state.mouse_x
    local my = state.mouse_y
    local L = layout

    if not L.bar then return false end

    local ch = false
    -- 드래그 중엔 진행바 밖이어도 hover (굵은 트랙+thumb 유지)
    ch = set_hover("hover_seekbar", (state.dragging == "seek")
        or in_rect(mx, my, L.progress.x, L.progress.y, L.progress.w, L.progress.h)) or ch
    ch = set_hover("hover_play", hover_btn(mx, my, L.play_btn)) or ch
    ch = set_hover("hover_mute", hover_btn(mx, my, L.vol_btn)) or ch
    ch = set_hover("hover_volume", state.vol_expanded and
        in_rect(mx, my, L.vol_slider.x - 4, L.vol_slider.cy - 10, L.vol_slider.w + 8, 20)) or ch
    -- 음량 영역 전체 (접힘 판정은 calc_layout 이 같은 사각형으로)
    local va_w = state.vol_expanded
        and (BTN_SIZE + VOL_SLIDER_M * 2 + options.volume_width) or BTN_SIZE
    ch = set_hover("hover_vol_area",
        in_rect(mx, my, L.vol_area.x, L.vol_area.y, va_w, L.vol_area.h)) or ch
    -- 캡션 버튼: 슬롯 전체 = 히트 영역 (윈도우 기본 캡션바와 동일)
    if L.cap_close then
        ch = set_hover("hover_close",
            in_rect(mx, my, L.cap_close.x, L.cap_close.y, L.cap_close.w, L.cap_close.h)) or ch
    end
    if L.cap_max then
        ch = set_hover("hover_topbar_fs",
            in_rect(mx, my, L.cap_max.x, L.cap_max.y, L.cap_max.w, L.cap_max.h)) or ch
    end
    if L.cap_min then
        ch = set_hover("hover_topbar_min",
            in_rect(mx, my, L.cap_min.x, L.cap_min.y, L.cap_min.w, L.cap_min.h)) or ch
    end
    ch = set_hover("hover_list",     hover_btn(mx, my, L.list_btn)) or ch
    ch = set_hover("hover_settings", hover_btn(mx, my, L.settings_btn)) or ch
    ch = set_hover("hover_sub",      hover_btn(mx, my, L.sub_btn)) or ch
    ch = set_hover("hover_prev",     hover_btn(mx, my, L.prev_btn)) or ch
    ch = set_hover("hover_next",     hover_btn(mx, my, L.next_btn)) or ch

    -- 컨트롤 표시 + 조작 요소 위일 때만 창 이동 차단
    report_hit((state.visible and (
        state.dragging ~= nil or
        state.hover_seekbar or state.hover_play or state.hover_prev or state.hover_next or
        state.hover_mute or state.hover_volume or state.hover_vol_area or
        state.hover_sub or state.hover_settings or state.hover_list or
        state.hover_close or state.hover_topbar_min or state.hover_topbar_fs)) and true or false)

    return ch
end

-- [perf] ASS 서식 문자열 캐시
local _ass_fmt_cache = {}
local function get_ass_fmt(color_str, alpha_str)
    alpha_str = alpha_str or "00"
    local key = color_str .. alpha_str
    local v = _ass_fmt_cache[key]
    if v then return v end
    v = string.format("{\\bord0\\shad0\\1c&H%s&\\1a&H%s&\\p1}", color_str, alpha_str)
    _ass_fmt_cache[key] = v
    return v
end

-- [perf] 아이콘 서식 문자열 캐시
local _icon_fmt_cache = {}
local function get_icon_fmt(size, col, al)
    col = col or color.white
    al = al or "00"
    local pct = math.floor(size / 24 * 100 + 0.5)
    local key = pct .. col .. al
    local v = _icon_fmt_cache[key]
    if v then return v end
    v = string.format("{\\bord0\\shad0\\1c&H%s&\\1a&H%s&\\fscx%d\\fscy%d}", col, al, pct, pct)
    _icon_fmt_cache[key] = v
    return v
end

-- 그리기 헬퍼
local function draw_rect(a, x, y, w, h, color_str, alpha_str)
    a:new_event()
    a:pos(0, 0)
    a:an(7)
    a:append(get_ass_fmt(color_str, alpha_str))
    a:draw_start()
    a:rect_cw(x, y, x + w, y + h)
    a:draw_stop()
end

-- 제어점을 코너에 두면 실제 원보다 안쪽으로 파임. 칩 버튼은 반경=높이/2(원)라 원 근사 상수 사용.
local KAPPA = 0.5523

local function draw_rounded_rect(a, x, y, w, h, r, color_str, alpha_str)
    a:new_event()
    a:pos(0, 0)
    a:an(7)
    a:append(get_ass_fmt(color_str, alpha_str))
    a:draw_start()
    r = math.min(r, h/2, w/2)
    local k = r * (1 - KAPPA)
    local x2, y2 = x + w, y + h
    a:move_to(x + r, y)
    a:line_to(x2 - r, y)
    a:bezier_curve(x2 - k, y, x2, y + k, x2, y + r)
    a:line_to(x2, y2 - r)
    a:bezier_curve(x2, y2 - k, x2 - k, y2, x2 - r, y2)
    a:line_to(x + r, y2)
    a:bezier_curve(x + k, y2, x, y2 - k, x, y2 - r)
    a:line_to(x, y + r)
    a:bezier_curve(x, y + k, x + k, y, x + r, y)
    a:draw_stop()
end

local function draw_circle(a, cx, cy, r, color_str, alpha_str)
    a:new_event()
    a:pos(0, 0)
    a:an(7)
    a:append(get_ass_fmt(color_str, alpha_str))
    a:draw_start()
    local k = r * 0.55
    a:move_to(cx - r, cy)
    a:bezier_curve(cx - r, cy - k, cx - k, cy - r, cx, cy - r)
    a:bezier_curve(cx + k, cy - r, cx + r, cy - k, cx + r, cy)
    a:bezier_curve(cx + r, cy + k, cx + k, cy + r, cx, cy + r)
    a:bezier_curve(cx - k, cy + r, cx - r, cy + k, cx - r, cy)
    a:draw_stop()
end

-- 상단바 그리기

-- 임의 각도 선분(닫기 X 의 대각선용).
local function draw_seg(a, x1, y1, x2, y2, w, col, al)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 0 then return end
    local nx, ny = -dy / len * w / 2, dx / len * w / 2
    a:new_event()
    a:pos(0, 0)
    a:an(7)
    a:append(get_ass_fmt(col, al))
    a:draw_start()
    a:move_to(x1 + nx, y1 + ny)
    a:line_to(x2 + nx, y2 + ny)
    a:line_to(x2 - nx, y2 - ny)
    a:line_to(x1 - nx, y1 - ny)
    a:draw_stop()
end

-- 축 정렬 hairline. 픽셀 격자 스냅 안 하면 2px 로 번짐.
local function snap(v) return math.floor(v) end

local function hline(a, y, x0, x1, col, al)
    draw_rect(a, snap(x0), snap(y), snap(x1) - snap(x0), tb.line_w, col, al)
end

local function vline(a, x, y0, y1, col, al)
    draw_rect(a, snap(x), snap(y0), tb.line_w, snap(y1) - snap(y0), col, al)
end

local function box_outline(a, cx, cy, hx, hy, col, al)
    local l, r = cx - hx, cx + hx
    local t, b = cy - hy, cy + hy
    hline(a, t, l, r, col, al)
    hline(a, b, l, r, col, al)
    vline(a, l, t, b, col, al)
    vline(a, r, t, b, col, al)
end

-- 캡션 글리프. kind 0=최소화 1=최대화 2=복원 3=닫기
local function draw_caption_glyph(a, kind, cx, cy, col)
    local h = tb.glyph
    local av = fa("00")   -- 컨트롤 전체 페이드에 동승
    if kind == 0 then
        hline(a, cy, cx - h, cx + h, col, av)
    elseif kind == 1 then
        box_outline(a, cx, cy, h, h, col, av)
    elseif kind == 2 then
        -- 복원: 0.8배 상자 둘을 0.42배 어긋나게 겹침
        local o, hs = h * 0.42, h * 0.8
        box_outline(a, cx + o, cy - o, hs, hs, col, av)
        box_outline(a, cx - o, cy + o, hs, hs, col, av)
    else
        -- 대각선은 스냅 불가 — 축 정렬 선과 굵기 같아 보이게 살짝 두껍게.
        local w = tb.line_w * 1.6
        draw_seg(a, cx - h, cy - h, cx + h, cy + h, w, col, av)
        draw_seg(a, cx - h, cy + h, cx + h, cy - h, w, col, av)
    end
end

-- 상단바 스크림. 제목 외곽선이 없어 이 배경이 유일한 대비 수단. ASS 에 알파
-- 그라데이션 없어 가로 스트립 근사. 스트립 경계는 정수 px 필수 — 겹치거나 부분
-- 커버리지로 만나면 줄무늬. [perf] W 무관이라 목록 1회 생성 (배율 변경 시 비움).
local function scrim_strips()
    if _scrim_strips then return _scrim_strips end
    local total = tb.h + tb.scrim_h
    local ratio = tb.h / total
    local strips = {}
    local y = 0
    while y < total do
        local step = (y < tb.h) and tb.step_bar or tb.step_tail
        local y1 = math.min(y + step, total)
        local t  = (y + y1) * 0.5 / total
        local av
        if t <= ratio then
            av = SCRIM_A_TOP + (SCRIM_A_BOT - SCRIM_A_TOP) * (t / ratio)
        else
            local k = 1 - (t - ratio) / (1 - ratio)
            av = SCRIM_A_BOT * k * k
        end
        strips[#strips + 1] = {
            y = y,
            h = y1 - y,
            a = string.format("%02X", math.floor((1 - av) * 255 + 0.5)),
        }
        y = y1
    end
    _scrim_strips = strips
    return strips
end

local function draw_topbar_scrim(a, W)
    local strips = scrim_strips()
    for i = 1, #strips do
        local s = strips[i]
        draw_rect(a, 0, s.y, W, s.h, color.scrim, fa(s.a))
    end
end

-- 캡션 버튼. 최소화·최대화는 글리프만 밝아지고, 닫기만 윈도우처럼 슬롯 전체 붉게.
local function draw_caption_btn(a, slot, kind, hovered)
    if not slot then return end
    if kind == 3 and hovered then
        draw_rect(a, slot.x, slot.y, slot.w, slot.h, color.close_bg, fa("00"))
    end
    draw_caption_glyph(a, kind, slot.cx, slot.cy,
                       hovered and color.cap_hover or color.cap_idle)
end

local function draw_icon(a, icon_path, cx, cy, size, col, al)
    a:new_event()
    a:pos(cx - size / 2, cy - size / 2)
    a:an(7)
    a:append(get_icon_fmt(size, col, al))
    a:append(icon_path)
end

-- 하단 컨트롤 칩. 바 배경 없이 버튼마다 반투명 알약, 아이콘 항상 흰색, hover 는 배경만 밝아짐.

-- 칩 버튼 하나 그리고 아이콘 배율 반환. own_bg=false 면 배경은 상위 알약(그룹/음량 영역)이 이미 그림.
local function draw_btn(a, name, b, hovered, own_bg)
    local hv = anim(name .. "_h", hovered and 1 or 0, ANIM_HOVER)
    local pr = anim(name .. "_p", (state.pressed == name) and 1 or 0, ANIM_PRESS)
    local sc = 1 - 0.08 * pr
    local s  = BTN_SIZE * sc
    local x, y = b.cx - s / 2, b.cy - s / 2
    if own_bg then
        draw_rounded_rect(a, x, y, s, s, BTN_R * sc, color.dark, fa(A_CHIP_BG))
    end
    if hv > 0 then
        draw_rounded_rect(a, x, y, s, s, BTN_R * sc, color.white, fa(A_CHIP_HOVER, hv))
    end
    return sc
end

-- bottom_scrim_alpha > 0 일 때만의 아래쪽 그라데이션 (스트립 근사).
local function draw_bottom_scrim(a, W, H, top_alpha)
    local h = options.bar_height + 12
    local y0 = H - h
    local steps = 12
    local step = h / steps
    for i = 0, steps - 1 do
        local t = (i + 0.5) / steps          -- 0 = 위, 1 = 아래
        local av = top_alpha * t * t         -- 위로 갈수록 빠르게 투명
        draw_rect(a, 0, y0 + i * step, W, step + 1, color.dark,
                  string.format("%02X", math.floor((1 - av) * 255 + 0.5)))
    end
end

-- 배속 토스트. 정중앙 ~1s, 컨트롤 표시와 무관.
local function draw_speed_toast(a, W, H)
    if not state.speed_toast_until or mp.get_time() >= state.speed_toast_until then return end
    local bw, bh = 96, 34
    local bx = W / 2 - bw / 2
    local by = H / 2 - bh / 2
    draw_rounded_rect(a, bx, by, bw, bh, 6, color.dark_bar, alpha.bar_bg)
    a:new_event(); a:pos(W / 2, H / 2); a:an(5)
    a:append(string.format("{\\fn%s\\fs%d\\bord0\\shad0\\1c&H%s&\\1a&H00&\\b1}%s",
        options.num_font, 22, color.white, ass_escape(state.speed_toast_text)))
end

-- 중앙 인디케이터(베젤): 반투명 원+아이콘, 볼륨일 때만 위쪽 숫자 알약. 컨트롤 표시와 무관, ~1s.
local bezel_ui = {
    circle_r  = 50,     -- 중앙 원 반경 (지름 100)
    icon      = 46,     -- 원 안 스피커 아이콘 크기
    pill_w    = 96,     -- 숫자 알약
    pill_h    = 36,
    pill_r    = 10,
    -- 알약 y = 화면 높이 비율 (고정 px 면 큰 창에서 위에 붙어 보임). 하한 = 상단바 회피.
    pill_y    = 0.15,
    pill_ymin = TOPBAR_H + 8,
    font_size = 24,
    a_circle  = "4C",   -- 원 배경 (약 70% 불투명)
    a_pill    = "33",   -- 알약 배경 (약 80% 불투명)
    show      = 1.0,    -- 총 표시 시간 (페이드 포함)
    fade_in   = 0.12,
    fade_out  = 0.25,
    -- 페이드 계수 0-1-0 을 배율에 그대로 쓰면 줌인/줌아웃 (숫자 알약은 크기 불변, 알파만).
    zoom_from = 0.75,   -- 페이드 시작/끝 배율
}

-- 베젤 페이드 계수(0..1). 컨트롤바 페이드와 무관.
local function bezel_fade()
    local u, fin = bezel_ui, state.bezel_until
    if not fin then return 0 end
    local now = mp.get_time()
    if now >= fin then return 0 end

    local f = 1
    local since = now - (state.bezel_from or now)
    if u.fade_in > 0 and since < u.fade_in then f = since / u.fade_in end
    local left = fin - now
    if u.fade_out > 0 and left < u.fade_out then f = math.min(f, left / u.fade_out) end
    return clamp(f, 0, 1)
end

-- 알파를 f 만큼 흐리게. fa() 와 달리 컨트롤바 페이드 안 곱함.
local function alpha_scale(base, f)
    if f >= 0.999 then return base end
    if f <= 0.002 then return "FF" end
    return string.format("%02X", 255 - math.floor((255 - tonumber(base, 16)) * f + 0.5))
end

-- 중앙 알림. Delphi 가 script-message alert <메시지> <색상> 전송 (FrmKPlayer.Alert).
-- 색상은 RGB 문자열, ASS 는 BGR — 여기서 뒤집음.
local alert_ui = {
    show      = 4.5,    -- 총 표시 시간 (페이드 포함)
    fade_in   = 0.15,
    fade_out  = 0.6,    -- 마지막에 천천히 소멸
    font_size = 20,
    height    = 38,
    pad_x     = 18,
    radius    = 8,
    -- 정중앙은 베젤이 쓰므로 조금 아래 (동시 표시 경우 있음).
    dy        = 96,
}

local function rgb_to_ass(rgb)
    rgb = tostring(rgb or ""):gsub("[^%x]", "")
    if #rgb ~= 6 then return color.white end
    return rgb:sub(5, 6) .. rgb:sub(3, 4) .. rgb:sub(1, 2)
end

local function alert_fade()
    local u, fin = alert_ui, state.alert_until
    if not fin then return 0 end
    local now = mp.get_time()
    if now >= fin then return 0 end

    local f = 1
    local since = now - (state.alert_from or now)
    if u.fade_in > 0 and since < u.fade_in then f = since / u.fade_in end
    local left = fin - now
    if u.fade_out > 0 and left < u.fade_out then f = math.min(f, left / u.fade_out) end
    return clamp(f, 0, 1)
end

local function draw_alert(a, W, H)
    local f = alert_fade()
    if f <= 0.002 or state.alert_text == "" then return end
    local u = alert_ui

    local bw = approx_text_w(state.alert_text, u.font_size) + u.pad_x * 2
    local bx = W / 2 - bw / 2
    local by = H / 2 + u.dy - u.height / 2

    draw_rounded_rect(a, bx, by, bw, u.height, u.radius, color.dark_bar,
                      alpha_scale(alpha.bar_bg, f))

    a:new_event(); a:pos(W / 2, by + u.height / 2); a:an(5)
    a:append(string.format("{\\fn%s\\fs%d\\bord0\\shad0\\1c&H%s&\\1a&H%s&\\b1}%s",
        options.topbar_font or options.num_font, u.font_size,
        state.alert_color or color.white, alpha_scale("00", f),
        ass_escape(state.alert_text)))
end

local function draw_bezel(a, W, H)
    local f = bezel_fade()
    if f <= 0.002 or not state.bezel_icon then return end

    -- idle 엔 표시 안 함 — 같은 자리 시작 화면 로고와 겹침.
    if state.idle then return end

    local u = bezel_ui

    -- 중앙 원+아이콘. 배율 ease-out 으로 끝에서 부드럽게 멎음.
    local e  = 1 - (1 - f) * (1 - f)
    local sc = u.zoom_from + (1 - u.zoom_from) * e

    draw_circle(a, W / 2, H / 2, u.circle_r * sc, color.dark, alpha_scale(u.a_circle, f))
    draw_icon(a, state.bezel_icon,
              W / 2, H / 2, u.icon * sc, color.white, alpha_scale(alpha.full, f))

    -- 숫자 알약은 볼륨일 때만 (재생/일시정지는 아이콘만)
    if not state.bezel_text then return end

    local by = math.max(math.floor(H * u.pill_y + 0.5), u.pill_ymin)
    draw_rounded_rect(a, W / 2 - u.pill_w / 2, by, u.pill_w, u.pill_h, u.pill_r,
                      color.dark_bar, alpha_scale(u.a_pill, f))
    a:new_event(); a:pos(W / 2, by + u.pill_h / 2); a:an(5)
    a:append(string.format("{\\fn%s\\fs%d\\bord0\\shad0\\1c&H%s&\\1a&H%s&\\b1}%s",
        options.num_font, u.font_size, color.white, alpha_scale(alpha.full, f),
        ass_escape(state.bezel_text)))
end

-- 전체 화면에서 커서를 컨트롤바와 함께 숨김. mpv 의 cursor-autohide 는 남의 창
-- 임베드 시 동작 안 함 — 실제 커서는 Delphi 가 토글.
local function update_cursor()
    local hide = state.fullscreen and (not state.visible)
    if hide ~= state.cursor_hidden then
        state.cursor_hidden = hide
        mp.commandv("script-message", "cursor", hide and "hide" or "show")
    end
end

-- OSD 오버레이 2장. 재생 중엔 하단(시간·진행바)만 변함 — 갈라 두면 상단바 트랙은 갱신
-- 명령도 안 나감. 데이터가 이전과 같으면 update() 생략 — 초당 수십 회 time-pos 갱신이 걸러짐.
local ov_top = mp.create_osd_overlay("ass-events")
local ov_bot = mp.create_osd_overlay("ass-events")

local function put(ov, W, H, text)
    if ov.data == text and ov.res_x == W and ov.res_y == H then return end
    ov.res_x, ov.res_y, ov.data = W, H, text
    ov:update()
end

local function render()
    update_cursor()

    -- 페이드 목표. 실제값(state.opacity)은 tick 애니메이션이 이동.
    state.opacity = anim("fade", state.visible and 1 or 0, ANIM_FADE)

    if state.opacity <= 0.002 then
        -- 완전 숨김 — 컨트롤 무관 토스트·베젤·알림만 그림. 이전과 같으면 osd 명령 안 나감.
        anim_reset()
        report_hit(false)   -- 버튼 소멸 = 어디를 눌러도 창 이동
        put(ov_top, state.osd_w, state.osd_h, "")
        local t = assdraw.ass_new()
        draw_speed_toast(t, state.osd_w, state.osd_h)
        draw_bezel(t, state.osd_w, state.osd_h)
        draw_alert(t, state.osd_w, state.osd_h)
        put(ov_bot, state.osd_w, state.osd_h, t.text)
        return
    end

    calc_layout()
    check_hover()

    local W, H, L = layout.W, layout.H, layout
    local a = assdraw.ass_new()

    if state.idle then
        -- 시작 화면 — 기운 KPlayer 워드마크 위 재생 아이콘. 둘 다 반투명이라 겹친 곳은 밝아짐.
        -- 원·아이콘 크기는 bezel_ui 그대로 — 로고→베젤로 이어지는 자리라 값 갈리면 원 크기가 변해 보임.
        local r  = bezel_ui.circle_r
        local cx = W / 2
        local cy = H / 2
        local fs = math.floor(math.min(W * LOGO_FILL / LOGO_MARK_ADV,
                                       H * LOGO_MARK_H) + 0.5)

        a:new_event()
        a:pos(cx, cy + r * LOGO_MARK_DY)   -- 워드마크는 아이콘 위쪽
        a:an(5)
        a:append(string.format(
            "{\\fn%s\\fs%d\\frz%d\\fsp%d\\bord0\\shad0\\1c&H%s&\\1a&H%s&\\b1}KPlayer",
            LOGO_FONT, fs, LOGO_TILT, math.floor(fs * 0.03 + 0.5),
            color.logo_mark, alpha.logo_mark))

        -- 원도 반투명 — 뒤 글자가 비침 (불투명이면 글자 끊김).
        draw_circle(a, cx, cy, r, color.white, alpha.logo_disc)

        -- 삼각형은 컨트롤바·베젤과 같은 icons.play — draw_icon 이 크기·중심 맞춰줌.
        draw_icon(a, icons.play, cx, cy, bezel_ui.icon, color.white, alpha.logo_play)
    end
    
    -- 상단바 스크림
    draw_topbar_scrim(a, W)

    -- 제목: 좌측, 버튼 3슬롯 앞에서 잘림. 외곽선 없이 스크림으로만 대비.
    local title_str = state.filename ~= "" and ass_escape(state.filename) or ""
    local title_max_x = W - tb.right_lim
    a:new_event(); a:pos(L.title_text.x, L.title_text.y); a:an(4)
    a:append(string.format("{\\fn%s\\fs%d\\bord0\\shad0\\1c&H%s&\\1a&H%s&\\clip(0,0,%d,%d)}%s",
        options.topbar_font, tb.font_px, color.title, fa("00"), title_max_x, tb.h, title_str))

    -- 캡션 버튼 (최소화 / 최대화·복원 / 닫기)
    draw_caption_btn(a, L.cap_min, 0, state.hover_topbar_min)
    draw_caption_btn(a, L.cap_max, state.fullscreen and 2 or 1, state.hover_topbar_fs)
    draw_caption_btn(a, L.cap_close, 3, state.hover_close)

    -- 여기까지 상단 오버레이. 하단은 새 캔버스.
    put(ov_top, W, H, a.text)
    a = assdraw.ass_new()

    if options.bottom_scrim_alpha > 0 then
        draw_bottom_scrim(a, W, H, options.bottom_scrim_alpha)
    end

    -- 진행바
    local sb = L.seekbar
    local sb_h = sb.h
    local dur = state.duration
    local pos = display_pos()
    local pos_ratio = dur > 0 and clamp(pos / dur, 0, 1) or 0

    -- 로컬 파일만 재생 — 버퍼 구간 안 그림. 재생 위치는 픽셀 반올림해야 잦은
    -- time-pos 갱신이 같은 문자열로 수렴해 put() 에 걸림.
    draw_rounded_rect(a, sb.x, sb.y, sb.w, sb_h, sb_h / 2, color.white, fa(A_TRACK))

    local pos_x = math.floor(pos_ratio * sb.w + 0.5)
    local played_w = math.max(sb_h, pos_x)
    draw_rounded_rect(a, sb.x, sb.y, played_w, sb_h, sb_h / 2, color.red, fa("00"))

    local chapters = state.chapter_list
    for i = 1, #chapters do
        local ch = chapters[i]
        if ch.time and dur > 0 then
            local cx = sb.x + (ch.time / dur) * sb.w
            draw_rect(a, cx - 1, sb.y - 1, 2, sb_h + 2, color.white, fa("44"))
        end
    end

    -- thumb 은 커서 아닌 재생 위치. hover 시 커지고, 누르는 동안 1.25배.
    local thumb = anim("thumb", state.hover_seekbar and 1 or 0, ANIM_THUMB)
    local scrub = anim("scrub", (state.pressed == "seek") and 1 or 0, ANIM_THUMB)
    if thumb > 0.01 then
        draw_circle(a, sb.x + pos_x, L.progress.cy,
                    SEEK_THUMB_R * thumb * (1 + 0.25 * scrub), color.red, fa("00"))
    end

    -- prev/play/next: 한 알약 그룹
    local cg = L.chip_group
    draw_rounded_rect(a, cg.x, cg.y, cg.w, cg.h, BTN_R, color.dark, fa(A_CHIP_BG))
    local sc_prev = draw_btn(a, "prev", L.prev_btn, state.hover_prev, false)
    local sc_play = draw_btn(a, "play", L.play_btn, state.hover_play, false)
    local sc_next = draw_btn(a, "next", L.next_btn, state.hover_next, false)

    local is_playing = (not state.idle) and (not state.paused)
    local icon_a = fa("00")
    draw_icon(a, icons.prev, L.prev_btn.cx, L.prev_btn.cy, ICON_SIZE * sc_prev, color.white, icon_a)
    draw_icon(a, is_playing and icons.pause or icons.play,
              L.play_btn.cx, L.play_btn.cy, ICON_SIZE * sc_play, color.white, icon_a)
    draw_icon(a, icons.next, L.next_btn.cx, L.next_btn.cy, ICON_SIZE * sc_next, color.white, icon_a)

    -- 음량. 칩 배경이 스피커 칸 아닌 영역 전체 — 슬라이더 펼침 시 배경도 늘어나 한 알약.
    local vb = L.vol_btn
    local va = L.vol_area
    draw_rounded_rect(a, va.x, va.y, va.w, va.h, BTN_R, color.dark, fa(A_CHIP_BG))
    local sc_vol = draw_btn(a, "mute", vb, state.hover_mute, false)
    draw_icon(a, state.muted and icons.vol_off or icons.vol_on,
              vb.cx, vb.cy, ICON_SIZE * sc_vol, color.white, icon_a)

    -- 슬라이더는 왼쪽부터 드러남 (overflow:hidden 모양).
    local vol_ratio = state.muted and 0 or clamp(state.volume / 100, 0, 1)
    local vs = L.vol_slider
    local shown = clamp(va.x + va.w - VOL_SLIDER_M - vs.x, 0, vs.w)
    if shown > 1 then
        draw_rounded_rect(a, vs.x, vs.cy - vs.h / 2, shown, vs.h, vs.h / 2,
                          color.white, fa(A_VOL_TRACK))
        local fill = math.min(vol_ratio * vs.w, shown)
        if fill > 0 then
            draw_rounded_rect(a, vs.x, vs.cy - vs.h / 2, fill, vs.h, vs.h / 2,
                              color.white, fa("00"))
        end
        if vol_ratio * vs.w <= shown then
            draw_circle(a, vs.x + vol_ratio * vs.w, vs.cy, VOL_THUMB_R, color.white, fa("00"))
        end
    end

    -- 시간 (현재 / 전체)
    local tc = L.time_chip
    draw_rounded_rect(a, tc.x, tc.y, tc.w, tc.h, BTN_R, color.dark, fa(A_CHIP_BG))
    local tt = L.time_text
    a:new_event(); a:pos(tt.x, tt.y); a:an(5)
    a:append(string.format("{\\fn%s\\fs%d\\bord0\\shad0\\1c&H%s&\\1a&H%s&}%s / %s",
        options.num_font, options.font_size, color.white, icon_a,
        format_time(pos), format_time(dur)))

    -- 자막 버튼: 트랙 있을 때만, 켜짐=흰색 꺼짐=회색.
    if L.sub_btn then
        local sc_sub = draw_btn(a, "sub", L.sub_btn, state.hover_sub, true)
        local sub_col = state.sub_visible and color.white or color.gray
        draw_icon(a, icons.sub, L.sub_btn.cx, L.sub_btn.cy, ICON_SIZE_CC * sc_sub, sub_col, icon_a)
    end

    -- 설정 버튼
    local sc_set = draw_btn(a, "settings", L.settings_btn, state.hover_settings, true)
    draw_icon(a, icons.set, L.settings_btn.cx, L.settings_btn.cy,
              ICON_SIZE * sc_set, color.white, icon_a)

    -- 재생목록 버튼
    local sc_list = draw_btn(a, "list", L.list_btn, state.hover_list, true)
    draw_icon(a, icons.list, L.list_btn.cx, L.list_btn.cy,
              ICON_SIZE * sc_list, color.white, icon_a)

    -- seek tooltip: 진행바 위 시간 말풍선
    if state.hover_seekbar and dur > 0 then
        local seek_ratio = clamp((state.mouse_x - sb.x) / sb.w, 0, 1)
        local seek_time  = format_time(seek_ratio * dur)
        local tip_w = approx_text_w(seek_time, options.font_size - 1) + 12
        local tip_h = 20
        local tip_x = clamp(math.floor(state.mouse_x + 0.5),
                            sb.x + tip_w / 2, sb.x + sb.w - tip_w / 2)
        local tip_y = L.progress.y - 4 - tip_h
        draw_rounded_rect(a, tip_x - tip_w / 2, tip_y, tip_w, tip_h, 4, color.dark, fa(A_TOOLTIP))
        a:new_event(); a:pos(tip_x, tip_y + tip_h / 2); a:an(5)
        a:append(string.format("{\\fn%s\\fs%d\\bord0\\shad0\\1c&H%s&\\1a&H%s&}%s",
            options.num_font, options.font_size - 1, color.white, icon_a, seek_time))
    end

    draw_speed_toast(a, W, H)
    draw_bezel(a, W, H)
    draw_alert(a, W, H)

    put(ov_bot, W, H, a.text)
end

-- 프레임 스케줄러. request_render() 는 즉시 안 그리고 다음 프레임 1회 예약 —
-- 한 프레임에 이벤트 여러 번 와도 렌더 1회, 주사율 초과 안 함. 애니메이션 끝나면 예약도 멈춤(타이머 소멸).
local tick_timer = nil
local tick_last  = 0
local tick_delay = 1 / 60   -- 애니메이션 중: 화면 주사율
local IDLE_DELAY = 1 / 30   -- 그 외(재생 위치 갱신 등): 30fps 로 충분
local request_render   -- forward (tick 이 먼저 참조)

local function tick()
    local now = mp.get_time()
    local dt = now - tick_last
    if dt <= 0 or dt > 0.5 then dt = tick_delay end
    tick_last = now

    anim_step(dt)
    render()

    -- 토스트 표시 중에도 계속 그려야 사라질 때 갱신됨
    local toast = (state.speed_toast_until and now < state.speed_toast_until)
               or (state.bezel_until   and now < state.bezel_until)
               or (state.alert_until   and now < state.alert_until)
    if anim_pending() or toast then request_render() end
end

-- 숨겨진 채 전부 목표 도달이면 그릴 것 없음. 마지막 tick 이 이미 오버레이를 비워 예약 불요.
local function nothing_to_draw()
    if state.visible or state.opacity > 0.002 then return false end
    if state.speed_toast_until and mp.get_time() < state.speed_toast_until then return false end
    if state.bezel_until   and mp.get_time() < state.bezel_until   then return false end
    if state.alert_until   and mp.get_time() < state.alert_until   then return false end
    return not anim_pending()
end

request_render = function()
    if nothing_to_draw() then return end
    if not tick_timer then
        tick_timer = mp.add_timeout(tick_delay, tick)
        return
    end
    if tick_timer:is_enabled() then return end   -- 이미 예약됨
    -- 애니메이션 중만 주사율, 아니면 30fps (2시간 영상이면 진행바 1px 이동에 몇 초).
    local vf = bezel_fade()
    local iv = (anim_pending() or (vf > 0 and vf < 1)) and tick_delay
               or math.max(IDLE_DELAY, tick_delay)
    local wait = iv - (mp.get_time() - tick_last)
    tick_timer.timeout = (wait > 0) and wait or 0
    tick_timer:resume()
end

mp.observe_property("display-fps", "number", function(_, v)
    if v and v > 1 then tick_delay = clamp(1 / v, 1 / 144, 1 / 24) end
end)

-- 꼬리 0 제거 ("1.00"→"1", "1.50"→"1.5")
local function format_speed(v)
    local s = string.format("%.2f", v)
    s = s:gsub("0+$", "")
    s = s:gsub("%.$", "")
    return s
end

local function show_speed_toast(v)
    state.speed_toast_text = format_speed(v) .. "x"
    state.speed_toast_until = mp.get_time() + 1.0
    if state.speed_toast_timer then state.speed_toast_timer:kill() end
    state.speed_toast_timer = mp.add_timeout(1.0, function()
        state.speed_toast_until = nil
        request_render()
    end)
end

local function show_alert(text, col)
    state.alert_text  = tostring(text or "")
    state.alert_color = rgb_to_ass(col)
    state.alert_from  = mp.get_time()
    state.alert_until = state.alert_from + alert_ui.show

    if state.alert_timer then state.alert_timer:kill() end
    state.alert_timer = mp.add_timeout(alert_ui.show, function()
        state.alert_until = nil
        state.alert_text  = ""
        request_render()
    end)

    request_render()
end

mp.register_script_message("alert", function(text, col)
    show_alert(text, col)
end)

local function show_bezel(icon, text)
    local now = mp.get_time()

    -- 이미 떠 있으면 페이드인 재시작 안 함 (연타 시 깜빡임).
    if not (state.bezel_until and now < state.bezel_until) then
        state.bezel_from = now
    end

    state.bezel_icon = icon
    state.bezel_text = text
    state.bezel_until = now + bezel_ui.show
    if state.bezel_timer then state.bezel_timer:kill() end
    state.bezel_timer = mp.add_timeout(bezel_ui.show, function()
        state.bezel_until = nil
        request_render()
    end)
end

local function show_volume_bezel(v)
    show_bezel(state.muted and icons.vol_off or icons.vol_on,
               string.format("%d%%", math.floor(v + 0.5)))
end

-- 자막이 컨트롤에 안 가리게 아래 여백 조절. 마우스 이동마다 불림 — 값 바뀔 때만 설정 (매번이면 속성 설정·로그 누적).
local function update_sub_margin()
    if state.osd_h <= 0 then return end

    local m = state.visible and (options.bar_height + 20) or 40
    if state.sub_margin == m then return end

    state.sub_margin = m
    mp.set_property_number("sub-margin-y", m)
end

local function start_autohide()
    if state.autohide_timer then state.autohide_timer:kill() end
    -- idle·드래그 중엔 숨기지 않음 (마우스 정지여도).
    if state.idle or state.dragging then return end
    state.autohide_timer = mp.add_timeout(options.autohide_timeout, function()
        state.visible = false
        -- 재표시 때 슬라이더가 펼쳐진 채 뜨지 않게 접음
        state.vol_expanded = false
        update_sub_margin()
        request_render()   -- 즉시 안 지움. tick 이 페이드아웃
    end)
end

local function show_controls()
    state.visible = true
    update_sub_margin()
    start_autohide()
    request_render()
end

local last_mouse_x = -1
local last_mouse_y = -1

-- 드래그 중엔 키프레임 탐색(가벼움), 놓을 때 1회만 exact — 매 프레임 정확 탐색은 끊김.
local function drag_seek(exact)
    local sb = layout.seekbar
    if not sb or state.duration <= 0 then return end
    local r = clamp((state.mouse_x - sb.x) / sb.w, 0, 1)
    state.seek_target = r * state.duration
    -- 플래그는 문자열 하나여야 함. 3인자 분리 형식은 옛 문법 — 현재 mpv 에선 명령 실패.
    mp.commandv("seek", string.format("%.3f", state.seek_target),
                exact and "absolute+exact" or "absolute+keyframes")
end

local function drag_volume()
    local vs = layout.vol_slider
    if not vs then return end
    local r = clamp((state.mouse_x - vs.x) / vs.w, 0, 1)
    local v = math.floor(r * 100 + 0.5)
    if state.volume ~= v then mp.set_property_number("volume", v) end
    -- 음량 올리면 음소거 해제
    if v > 0 and state.muted then mp.set_property_bool("mute", false) end
end

-- 마우스 이동 재그리기는 3경우뿐 — 숨김→표시 / hover 대상 변경 / 툴팁 표시 중.
mp.observe_property("mouse-pos", "native", function(_, pos)
    if not pos then return end
    if pos.x == state.mouse_x and pos.y == state.mouse_y then return end
    -- 좌표는 항상 갱신 — hover 판정이 사용.
    state.mouse_x, state.mouse_y = pos.x, pos.y

    -- 드래그 중엔 다른 판정 불요. 창 밖도 계속 추적 (호스트가 마우스 캡처).
    if state.dragging then
        last_mouse_x, last_mouse_y = pos.x, pos.y
        if state.dragging == "seek" then drag_seek(false) else drag_volume() end
        request_render()
        return
    end

    -- 컨트롤 표시·autohide 리셋만 1px 임계. 기준점은 임계 넘었을 때만 이동 —
    -- 매 이벤트마다 옮기면 천천히 움직일 때 영원히 못 넘음.
    local far = math.abs(pos.x - last_mouse_x) > 1 or math.abs(pos.y - last_mouse_y) > 1
    if far then
        last_mouse_x, last_mouse_y = pos.x, pos.y
        local was_visible = state.visible
        state.visible = true
        update_sub_margin()
        start_autohide()
        if not was_visible then
            request_render()
            return
        end
    end

    if check_hover() or state.hover_seekbar then
        request_render()
    end
end)

-- 눌림(:active). 호스트의 keypress 는 누름+뗌 합본이라 mpv 가 "press" 만 주고 "누르는 중"
-- 없음 — 둘 다 받음: "down"=진짜 up 까지 유지, "press"=PRESS_MIN 뒤 자동 해제.
local PRESS_MIN = 0.12
local press_timer = nil
local press_time  = 0

local function clear_pressed()
    if press_timer then press_timer:kill(); press_timer = nil end
    if state.pressed then
        state.pressed = nil
        request_render()
    end
end

local function release_pressed()
    local rest = PRESS_MIN - (mp.get_time() - press_time)
    if rest <= 0 then clear_pressed(); return end
    if press_timer then press_timer:kill() end
    press_timer = mp.add_timeout(rest, clear_pressed)
end

-- 클릭 처리
mp.add_key_binding("MOUSE_BTN0", "controls-click", function(e)
    if e.event == "up" then
        -- 이 up 은 신뢰 불가 — mpv 는 버튼 누른 채 움직이면 드래그 첫 이동에서 스스로
        -- up 전송. 드래그 끝은 호스트의 실제 버튼 상태(script-message mbtn)로만 판단.
        if state.dragging then return end
        release_pressed()
        if state.visible then start_autohide() end
        request_render()
        return
    end
    -- "repeat" 등 무시.
    if e.event ~= "press" and e.event ~= "down" then return end

    if not state.visible then
        show_controls()
        return
    end

    local mx, my, L = state.mouse_x, state.mouse_y, layout
    if not L.bar then return end

    -- CSS :active — 누르는 동안 버튼 0.92 축소 (draw_btn 이 state.pressed 대조).
    state.pressed = (state.hover_seekbar and "seek")
        or (state.hover_play and "play") or (state.hover_prev and "prev")
        or (state.hover_next and "next") or (state.hover_mute and "mute")
        or (state.hover_sub and "sub") or (state.hover_settings and "settings")
        or (state.hover_list and "list") or nil
    press_time = mp.get_time()
    -- 합본 이벤트면 up 안 옴 — 해제 예약
    if e.event == "press" then release_pressed() end
    request_render()

    -- 닫기 — Delphi 로
    if state.hover_close then
        mp.commandv("script-message", "close")
        return
    end

    -- 최소화
    if state.hover_topbar_min then
        mp.commandv("script-message", "minimize")
        return
    end

    -- 전체 화면 전환
    if state.hover_topbar_fs then
        mp.command("cycle fullscreen")
        show_controls()
        return
    end

    -- 진행바: 누른 순간 그 위치로, 뗄 때까지 드래그 가능
    if state.hover_seekbar and state.duration > 0 then
        state.dragging = "seek"
        drag_seek(false)
        start_autohide()
        return
    end

    if state.hover_play then
        if state.idle then
            mp.commandv("script-message", "next")
        elseif mp.get_property_bool("eof-reached", false) then
            -- 끝 정지(keep-open). pause 만 풀면 곧 다시 끝 — 처음으로 되돌린 뒤 재생.
            mp.commandv("seek", 0, "absolute", "exact")
            mp.set_property_bool("pause", false)
        else
            mp.command("cycle pause")
        end
        start_autohide()
        return
    end
    if state.hover_prev then mp.commandv("script-message", "prev"); start_autohide(); return end
    if state.hover_next then mp.commandv("script-message", "next"); start_autohide(); return end
    if state.hover_mute then mp.command("cycle mute");  start_autohide(); return end
    -- 음량 슬라이더: 마찬가지로 누른 채 끌 수 있다
    if state.hover_volume then
        state.dragging = "volume"
        drag_volume()
        start_autohide()
        return
    end

    -- 재생목록 — Delphi 로 넘긴다
    if state.hover_list then
        mp.commandv("script-message", "playlist")
        start_autohide()
        return
    end

    -- 자막 토글 (버튼은 자막 트랙이 있을 때만 존재한다)
    if state.hover_sub then
        mp.command("cycle sub-visibility")
        start_autohide()
        return
    end

    -- 환경설정 — Delphi 로 넘긴다
    if state.hover_settings then
        mp.commandv("script-message", "settings")
        start_autohide()
        return
    end

    local in_topbar = in_rect(mx, my, L.topbar.x, L.topbar.y, L.topbar.w, L.topbar.h)
    local in_ctrlbar = in_rect(mx, my, L.bar.x, L.bar.y, L.bar.w, L.bar.h)
    if not in_topbar and not in_ctrlbar then
        start_autohide()
        return
    end

    start_autohide()

end, {complex = true})

-- 호스트가 주는 왼쪽 버튼 실제 상태 ("1" 눌림 / "0" 떼짐). mpv 의 up 은 신뢰 불가,
-- 창 밖에서 뗀 경우도 여기로 "0" 이 온다.
mp.register_script_message("mbtn", function(v)
    if v == "1" then return end
    if state.dragging == "seek" then
        state.dragging = nil
        drag_seek(true)          -- 놓은 지점으로 정확히
    else
        state.dragging = nil
    end
    release_pressed()
    if state.visible then start_autohide() end
    request_render()
end)

-- 속성 감시
mp.observe_property("duration",       "number", function(_, v) v = v or 0;     if state.duration   ~= v then state.duration   = v; request_render() end end)
mp.observe_property("time-pos",       "number", function(_, v) v = v or 0;     if state.position   ~= v then state.position   = v; request_render() end end)
mp.observe_property("pause", "bool", function(_, v)
    v = v or false
    if state.paused ~= v then
        state.paused = v
        -- 최초 콜백(등록 직후 현재 값) 은 제외
        if state.pause_ready then show_bezel(v and icons.pause or icons.play, nil) end
        request_render()
    end
    state.pause_ready = true
end)
mp.observe_property("volume", "number", function(_, v)
    v = v or 100
    if v > 100 then
        mp.set_property_number("volume", 100)
        v = 100
    end
    if state.volume ~= v then
        state.volume = v
        mp.commandv("script-message", "volume", tostring(math.floor(v)))
        -- 최초 콜백·슬라이더 드래그 중 제외 (슬라이더가 값 표시)
        if state.vol_ready and state.dragging ~= "volume" then show_volume_bezel(v) end
        request_render()
    end
    state.vol_ready = true
end)
mp.observe_property("mute",           "bool",   function(_, v) v = v or false; if state.muted      ~= v then state.muted      = v; request_render() end end)
mp.observe_property("fullscreen", "bool", function(_, v)
    v = v or false
    if state.fullscreen ~= v then
        state.fullscreen = v
        mp.commandv("script-message", "fullscreen", v and "on" or "off")
        request_render()
    end
end)
mp.observe_property("idle-active",    "bool",   function(_, v) v = v or false; if state.idle       ~= v then state.idle       = v; request_render() end end)
mp.observe_property("speed",          "number", function(_, v) v = v or 1.0;   if state.speed      ~= v then state.speed      = v; show_speed_toast(v); request_render() end end)
mp.observe_property("sub-visibility", "bool",   function(_, v) if state.sub_visible ~= v then state.sub_visible = v; request_render() end end)
mp.observe_property("sid",            "native", function(_, v) local has = (v ~= nil and v ~= false); if state.has_sub ~= has then state.has_sub = has; request_render() end end)
mp.observe_property("chapter-list",   "native", function(_, v) state.chapter_list = v or {}; request_render() end)
-- osd-width/height = 물리 픽셀 → 상단바 논리 치수에 이 배율을 곱해야 한다.
mp.observe_property("display-hidpi-scale", "number", function(_, v)
    v = (v and v > 0) and v or 1.0
    if state.dpi ~= v then
        state.dpi = v
        apply_ui_scale()
        request_render()
    end
end)

-- 임베드 시 mpv 가 DPI 를 못 읽음 → 창 소유자 Delphi 가 통지: script-message dpi 1.5
mp.register_script_message("dpi", function(v)
    v = tonumber(v)
    if not v or v <= 0 or state.dpi == v then return end
    state.dpi = v
    apply_ui_scale()
    request_render()
end)

-- OS UI 기본 폰트 = 로케일별 상이, mpv 에서는 알 수 없음. Delphi 가 Screen.MessageFont.Name
-- 전달: script-message ui-font "맑은 고딕". 미발견 시 libass 대체 폰트. 숫자 폰트는 유지.
mp.register_script_message("ui-font", function(name)
    if not name or name == "" or options.topbar_font == name then return end
    options.topbar_font = name
    apply_ui_scale()    -- 제목 폰트 크기(tb.font_px) 재계산
    request_render()
    msg.info("ui font: " .. name)
end)
mp.observe_property("osd-width",  "number", function(_, v) if v and v > 0 and state.osd_w ~= v then state.osd_w = v; request_render() end end)
mp.observe_property("osd-height", "number", function(_, v) if v and v > 0 and state.osd_h ~= v then state.osd_h = v; update_sub_margin(); request_render() end end)

-- 키보드 입력 없음: 포커스가 VCL 폼 → 키가 mpv 로 안 옴. 전부 Main.pas FormKeyDown 처리,
-- 여기엔 속성 변화만 도달. add_key_binding 은 동작할 것처럼 보여 혼란만 → 두지 않는다.

-- 이벤트
mp.register_event("file-loaded", function()
    state.visible  = true
    state.position = 0
    state.filename = mp.get_property("filename/no-ext") or ""
    mp.set_property("sub-ass-override", "force")
    mp.set_property_bool("pause", false)
    update_sub_margin()
    start_autohide()
    request_render()
end)

mp.observe_property("eof-reached", "bool", function(_, v)
    if v then
        mp.commandv("script-message", "finished")
    end
end)
-- 탐색/재생 재시작에 컨트롤 표시하려면 아래 두 줄 활성화. 현재 끔 — 키보드로 위치만
-- 옮겼는데 컨트롤이 올라오는 것 방지.
-- mp.register_event("seek",             function() show_controls() end)
-- mp.register_event("playback-restart", function() show_controls() end)

-- libass 는 서브픽셀 AA 없음. 힌팅("native" = 폰트 자체 힌터로 풀 힌팅) 켜면 작은 글자
-- 획이 픽셀 격자에 맞아 또렷해진다. 옵션명이 mpv 버전마다 다르고 OSD 적용 여부도 빌드마다
-- 달라 → 존재하는 것 전부 설정하고 적용된 것을 로그로 남긴다.
local function enable_font_hinting()
    local applied = {}
    for _, name in ipairs({ "sub-hinting", "osd-hinting", "sub-ass-hinting", "ass-hinting" }) do
        if mp.get_property(name) ~= nil then
            mp.set_property(name, "native")
            applied[#applied + 1] = name
        end
    end
    if #applied > 0 then
        msg.info("font hinting set to native: " .. table.concat(applied, ", "))
    else
        msg.info("no font hinting option found - this mpv build does not expose hinting control")
    end
end

state.paused = mp.get_property_bool("pause", true)
state.visible = true
enable_font_hinting()
apply_ui_scale()

mp.set_property("osd-level", "0")

request_render()
