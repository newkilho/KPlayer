-- ==============================================================
-- Project : KPlayer
-- Author  : Kilho, Oh
-- ==============================================================

local mp = require 'mp'
local assdraw = require 'mp.assdraw'
local opt = require 'mp.options'

-- Options
local options = {
    bar_height = 68,
    bar_margin = 0,
    autohide_timeout = 2,
    seekbar_height = 4,
    seekbar_hover_height = 6,
    seekbar_padding = 16,
    volume_width = 80,
    thumbnail_enabled = false,
    font_size = 14,
    bg_alpha = 0.55,
    topbar_height = 40,
}
opt.read_options(options, "controls")

-- State
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
    sub_visible = true,
    filename = "",
    hover_close = false,
    hover_topbar_min = false,
    hover_topbar_fs = false,
    hover_list = false,
    hover_settings = false,
    hover_prev = false,
    hover_next = false,
}

-- Utilities
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

-- Colors
local color = {
    red         = "0000FF",
    red_hover   = "1A1AFF",
    white       = "FFFFFF",
    white_dim   = "CCCCCC",
    dark        = "000000",
    dark_bar    = "141414",
    gray        = "888888",
    gray_light  = "AAAAAA",
    seekbar_bg  = "3D3D3D",
    seekbar_buf = "6E6E6E",
    vol_bg      = "3D3D3D",
}

local alpha = {
    bar_bg   = string.format("%02X", math.floor((1 - options.bg_alpha) * 255)),
    full     = "00",
    half     = "80",
    hidden   = "FF",
}

-- Icons (ASS vector drawing paths, 24x24 Material Design)
local icons = {
    full_off = "{\\p1}m 0 0 m 24 24 m 6 8 l 4 8 l 4 18 b 4 19.1 4.9 20 6 20 l 16 20 l 16 18 l 6 18 m 18 4 l 10 4 b 8.9 4 8 4.9 8 6 l 8 14 b 8 15.1 8.9 16 10 16 l 18 16 b 19.1 16 20 15.1 20 14 l 20 6 b 20 4.9 19.1 4 18 4 m 18 14 l 10 14 l 10 6 l 18 6{\\p0}",
    full_on  = "{\\p1}m 0 0 m 24 24 m 3 3 l 21 3 l 21 21 l 3 21 m 5 5 l 5 19 l 19 19 l 19 5{\\p0}",
    vol_off  = "{\\p1}m 0 0 m 24 24 m 16.5 12 b 16.5 10.23 15.48 8.71 14 7.97 l 14 10.18 l 16.45 12.63 b 16.48 12.43 16.5 12.22 16.5 12 m 19 12 b 19 12.94 18.8 13.82 18.46 14.64 l 19.97 16.15 b 20.63 14.91 21 13.5 21 12 b 21 7.72 18.01 4.14 14 3.23 l 14 5.29 b 16.89 6.15 19 8.83 19 12 m 4.27 3 l 3 4.27 l 7.73 9 l 3 9 l 3 15 l 7 15 l 12 20 l 12 13.27 l 16.25 17.52 b 15.58 18.04 14.83 18.45 14 18.7 l 14 20.76 b 15.38 20.45 16.63 19.81 17.69 18.95 l 19.73 21 l 21 19.73 l 12 10.73 l 4.27 3 m 12 4 l 9.91 6.09 l 12 8.18{\\p0}",
    vol_on   = "{\\p1}m 0 0 m 24 24 m 3 9 l 3 15 l 7 15 l 12 20 l 12 4 l 7 9 m 16.5 12 b 16.5 10.23 15.48 8.71 14 7.97 l 14 16.02 b 15.48 15.29 16.5 13.77 16.5 12 m 14 3.23 l 14 5.29 b 16.89 6.15 19 8.83 19 12 b 19 15.17 16.89 17.85 14 18.71 l 14 20.77 b 18.01 19.86 21 16.28 21 12 b 21 7.72 18.01 4.14 14 3.23{\\p0}",
    close    = "{\\p1}m 0 0 m 24 24 m 19 6.41 l 17.59 5 l 12 10.59 l 6.41 5 l 5 6.41 l 10.59 12 l 5 17.59 l 6.41 19 l 12 13.41 l 17.59 19 l 19 17.59 l 13.41 12{\\p0}",
    pause    = "{\\p1}m 0 0 m 24 24 m 6 19 l 10 19 l 10 5 l 6 5 m 14 5 l 14 19 l 18 19 l 18 5{\\p0}",
    list     = "{\\p1}m 0 0 m 24 24 m 3 18 l 21 18 l 21 16 l 3 16 m 3 13 l 21 13 l 21 11 l 3 11 m 3 8 l 21 8 l 21 6 l 3 6{\\p0}",
    play     = "{\\p1}m 0 0 m 24 24 m 8 5 l 8 19 l 19 12{\\p0}",
    next     = "{\\p1}m 0 0 m 24 24 m 6 18 l 14.5 12 l 6 6 l 6 18 m 16 6 l 16 18 l 18 18 l 18 6 l 16 6{\\p0}",
    prev     = "{\\p1}m 0 0 m 24 24 m 6 6 l 8 6 l 8 18 l 6 18 m 9.5 12 l 18 18 l 18 6{\\p0}",
    set      = "{\\p1}m 0 0 m 24 24 m 19.14 12.94 b 19.18 12.64 19.2 12.33 19.2 12 b 19.2 11.68 19.18 11.36 19.13 11.06 l 21.16 9.48 b 21.34 9.34 21.39 9.07 21.28 8.87 l 19.36 5.55 b 19.24 5.33 18.99 5.26 18.77 5.33 l 16.38 6.29 b 15.88 5.91 15.35 5.59 14.76 5.34 l 14.4 2.81 b 14.36 2.57 14.16 2.4 13.92 2.4 l 10.08 2.4 b 9.84 2.4 9.65 2.57 9.61 2.81 l 9.25 5.34 b 8.66 5.59 8.12 5.92 7.63 6.29 l 5.24 5.33 b 5.01 5.25 4.76 5.33 4.64 5.55 l 2.72 8.87 b 2.6 9.08 2.66 9.34 2.86 9.48 l 4.84 11.06 b 4.8 11.36 4.8 11.69 4.8 12 b 4.8 12.31 4.82 12.64 4.87 12.94 l 2.84 14.52 b 2.66 14.66 2.61 14.93 2.72 15.13 l 4.64 18.45 b 4.76 18.67 5.01 18.74 5.24 18.67 l 7.63 17.71 b 8.13 18.09 8.66 18.41 9.25 18.66 l 9.61 21.19 b 9.65 21.43 9.84 21.6 10.08 21.6 l 13.92 21.6 b 14.16 21.6 14.36 21.43 14.4 21.19 l 14.76 18.66 b 15.35 18.41 15.89 18.08 16.38 17.71 l 18.77 18.67 b 19 18.75 19.25 18.67 19.37 18.45 l 21.29 15.13 b 21.4 14.92 21.34 14.66 21.14 14.52 l 19.14 12.94 m 12 15.6 b 10.02 15.6 8.4 13.98 8.4 12 b 8.4 10.02 10.02 8.4 12 8.4 b 13.98 8.4 15.6 10.02 15.6 12 b 15.6 13.98 13.98 15.6 12 15.6{\\p0}",
    min      = "{\\p1}m 0 0 m 24 24 m 5 11 l 19 11 l 19 13 l 5 13{\\p0}",
}

-- Layout
local layout = {}

local function calc_layout()
    local W = state.osd_w
    local H = state.osd_h
    local bh = options.bar_height
    local bm = options.bar_margin
    local pad = options.seekbar_padding

    layout.W = W
    layout.H = H

    local tbh = options.topbar_height
    layout.topbar = { x = 0, y = 0, w = W, h = tbh }

    local icon_r = 10
    layout.topbar_min_btn = {
        cx = W - 88,
        cy = tbh / 2,
        hx = W - 88 - icon_r,
        hy = tbh / 2 - icon_r,
        hw = icon_r * 2,
        hh = icon_r * 2,
    }

    layout.topbar_fs_btn = {
        cx = W - 54,
        cy = tbh / 2,
        hx = W - 54 - icon_r,
        hy = tbh / 2 - icon_r,
        hw = icon_r * 2,
        hh = icon_r * 2,
    }

    layout.close_btn = {
        cx = W - 20,
        cy = tbh / 2,
        hx = W - 20 - icon_r,
        hy = tbh / 2 - icon_r,
        hw = icon_r * 2,
        hh = icon_r * 2,
    }

    layout.title_text = { x = 16, y = tbh / 2 }

    layout.bar = { x = 0, y = H - bh - bm, w = W, h = bh }

    local sb_h = options.seekbar_height
    if state.hover_seekbar then sb_h = options.seekbar_hover_height end

    local sb_top_margin = 10
    layout.seekbar = {
        x  = pad,
        y  = layout.bar.y + sb_top_margin,
        w  = W - pad * 2,
        h  = sb_h,
    }

    local btn_area_top = layout.bar.y + sb_top_margin + options.seekbar_hover_height + 4
    local btn_area_bot = layout.bar.y + bh - 12
    local btn_cy = (btn_area_top + btn_area_bot) / 2

    layout.play_btn    = { cx = 36,      cy = btn_cy, r = 20 }
    layout.prev_btn    = { cx = 60,      cy = btn_cy }
    layout.next_btn    = { cx = 84,      cy = btn_cy }
    layout.vol_btn     = { cx = 110,     cy = btn_cy }
    layout.vol_slider  = {
        x = 128, y = btn_cy - 3, w = options.volume_width, h = 4,
        cx = 128, cy = btn_cy,
    }
    layout.time_text   = { x = 128 + options.volume_width + 12, y = btn_cy }
    layout.settings_btn = { cx = W - 68, cy = btn_cy }
    layout.list_btn     = { cx = W - 38, cy = btn_cy }
end

-- Hit testing
local function in_rect(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

local function in_circle(x, y, cx, cy, r)
    local dx = x - cx
    local dy = y - cy
    return dx*dx + dy*dy <= r*r
end

local function check_hover()
    local mx = state.mouse_x
    local my = state.mouse_y
    local L = layout

    if not L.bar then return end

    state.hover_seekbar   = in_rect(mx, my, L.seekbar.x, L.seekbar.y - 10, L.seekbar.w, L.seekbar.h + 20)
    state.hover_play      = in_circle(mx, my, L.play_btn.cx, L.play_btn.cy, 11)
    state.hover_mute      = in_rect(mx, my, L.vol_btn.cx - 9, L.vol_btn.cy - 9, 18, 18)
    state.hover_volume    = in_rect(mx, my, L.vol_slider.cx, L.vol_slider.cy - 10, L.vol_slider.w, 20)
    if L.close_btn then
        state.hover_close = in_rect(mx, my, L.close_btn.hx, L.close_btn.hy, L.close_btn.hw, L.close_btn.hh)
    end
    if L.topbar_fs_btn then
        state.hover_topbar_fs = in_rect(mx, my, L.topbar_fs_btn.hx, L.topbar_fs_btn.hy, L.topbar_fs_btn.hw, L.topbar_fs_btn.hh)
    end
    if L.topbar_min_btn then
        state.hover_topbar_min = in_rect(mx, my, L.topbar_min_btn.hx, L.topbar_min_btn.hy, L.topbar_min_btn.hw, L.topbar_min_btn.hh)
    end
    if L.list_btn then
        state.hover_list = in_rect(mx, my, L.list_btn.cx - 9, L.list_btn.cy - 9, 18, 18)
    end
    if L.settings_btn then
        state.hover_settings = in_rect(mx, my, L.settings_btn.cx - 9, L.settings_btn.cy - 9, 18, 18)
    end
    if L.prev_btn then
        state.hover_prev = in_rect(mx, my, L.prev_btn.cx - 9, L.prev_btn.cy - 9, 18, 18)
    end
    if L.next_btn then
        state.hover_next = in_rect(mx, my, L.next_btn.cx - 9, L.next_btn.cy - 9, 18, 18)
    end
end

-- [perf] Cache ASS format strings
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

-- [perf] Cache icon format strings
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

-- Drawing helpers
local function draw_rect(a, x, y, w, h, color_str, alpha_str)
    a:new_event()
    a:pos(0, 0)
    a:an(7)
    a:append(get_ass_fmt(color_str, alpha_str))
    a:draw_start()
    a:rect_cw(x, y, x + w, y + h)
    a:draw_stop()
end

local function draw_rounded_rect(a, x, y, w, h, r, color_str, alpha_str)
    a:new_event()
    a:pos(0, 0)
    a:an(7)
    a:append(get_ass_fmt(color_str, alpha_str))
    a:draw_start()
    r = math.min(r, h/2, w/2)
    local x2, y2 = x + w, y + h
    a:move_to(x + r, y)
    a:line_to(x2 - r, y)
    a:bezier_curve(x2, y, x2, y, x2, y + r)
    a:line_to(x2, y2 - r)
    a:bezier_curve(x2, y2, x2, y2, x2 - r, y2)
    a:line_to(x + r, y2)
    a:bezier_curve(x, y2, x, y2, x, y2 - r)
    a:line_to(x, y + r)
    a:bezier_curve(x, y, x, y, x + r, y)
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

local function draw_icon(a, icon_path, cx, cy, size, col, al)
    a:new_event()
    a:pos(cx - size / 2, cy - size / 2)
    a:an(7)
    a:append(get_icon_fmt(size, col, al))
    a:append(icon_path)
end

-- [perf] Hover color helper
local function hcol(flag)
    return flag and color.white or color.white_dim
end

-- Render
local function render()
    if not state.visible then mp.set_osd_ass(state.osd_w, state.osd_h, ""); return end

    calc_layout()
    check_hover()

    local W, H, L = layout.W, layout.H, layout
    local a = assdraw.ass_new()

    if state.idle then
        -- FF8800
        draw_circle(a, W/2, H/2 - 40, 42, "333333", "00")
        a:new_event()
        a:pos(W/2 - 12, H/2 - 58)
        a:an(7)
        a:append("{\\bord0\\shad0\\1c&H000000&\\p1}")
        a:append("m 0 0 l 0 36 l 32 18")
        a:append("{\\p0}")

        -- Text
        a:new_event()
        a:pos(W/2, H/2 + 30)
        a:an(5)
        a:append("{\\fs34\\bord0\\shad0\\1c&H333333&\\b1}KPlayer")
    end
    
    -- top bar
    draw_rect(a, L.topbar.x, L.topbar.y, L.topbar.w, L.topbar.h, color.dark_bar, alpha.bar_bg)

    -- title
    local title_str = state.filename ~= "" and ass_escape(state.filename) or ""
    local title_max_x = W - 138
    a:new_event(); a:pos(L.title_text.x, L.title_text.y); a:an(4)
    a:append(string.format("{\\fs%d\\bord0\\shad0\\1c&H%s&\\1a&H00&\\clip(0,0,%d,%d)}%s", options.font_size + 4, color.white_dim, title_max_x, options.topbar_height, title_str))

    -- top minimize button
    if L.topbar_min_btn then
        draw_icon(a, icons.min, L.topbar_min_btn.cx, L.topbar_min_btn.cy, 20, hcol(state.hover_topbar_min), "00")
    end

    -- top fullscreen button
    if L.topbar_fs_btn then
        draw_icon(a, state.fullscreen and icons.full_off or icons.full_on,
                  L.topbar_fs_btn.cx, L.topbar_fs_btn.cy, 20, hcol(state.hover_topbar_fs), "00")
    end

    -- close button
    local cb = L.close_btn
    draw_icon(a, icons.close, cb.cx, cb.cy, 20, hcol(state.hover_close), "00")

    -- control bar bg
    local grad_h = L.bar.h + 4
    draw_rect(a, L.bar.x, L.bar.y - 4, L.bar.w, grad_h, color.dark_bar, alpha.bar_bg)

    -- seek bar
    local sb = L.seekbar
    local sb_h = sb.h
    local dur = state.duration
    local pos_ratio = dur > 0 and clamp(state.position / dur, 0, 1) or 0

    draw_rounded_rect(a, sb.x, sb.y, sb.w, sb_h, sb_h / 2, color.seekbar_bg, "00")

    if state.hover_seekbar then
        local hover_ratio = clamp((state.mouse_x - sb.x) / sb.w, 0, 1)
        local played_w  = math.max(sb_h, pos_ratio   * sb.w)
        local hovered_w = math.max(sb_h, hover_ratio * sb.w)
        if hover_ratio >= pos_ratio then
            draw_rounded_rect(a, sb.x, sb.y, hovered_w, sb_h, sb_h / 2, color.seekbar_buf, "00")
        end
        draw_rounded_rect(a, sb.x, sb.y, played_w,  sb_h, sb_h / 2, color.red, "00")
        draw_circle(a, sb.x + hover_ratio * sb.w, sb.y + sb_h / 2, sb_h * 0.9, color.white, "00")
    else
        local played_w = math.max(sb_h, pos_ratio * sb.w)
        draw_rounded_rect(a, sb.x, sb.y, played_w, sb_h, sb_h / 2, color.red, "00")
    end

    local chapters = state.chapter_list
    for i = 1, #chapters do
        local ch = chapters[i]
        if ch.time and dur > 0 then
            local cx = sb.x + (ch.time / dur) * sb.w
            draw_rect(a, cx - 1, sb.y - 1, 2, sb_h + 2, color.white, "44")
        end
    end

    -- play/pause
    local pb = L.play_btn
    local is_playing = (not state.idle) and (not state.paused)
    draw_icon(a, is_playing and icons.pause or icons.play, pb.cx, pb.cy, 22, hcol(state.hover_play), "00")

    -- prev / next
    draw_icon(a, icons.prev, L.prev_btn.cx, L.prev_btn.cy, 18, hcol(state.hover_prev), "00")
    draw_icon(a, icons.next, L.next_btn.cx, L.next_btn.cy, 18, hcol(state.hover_next), "00")

    -- volume
    local vb = L.vol_btn
    draw_icon(a, state.muted and icons.vol_off or icons.vol_on, vb.cx, vb.cy, 18, hcol(state.hover_mute), "00")

    local vs = L.vol_slider
    draw_rounded_rect(a, vs.cx, vs.cy - vs.h / 2, vs.w, vs.h, vs.h / 2, color.vol_bg, "00")
    local vol_ratio = state.muted and 0 or clamp(state.volume / 100, 0, 1)
    if vol_ratio > 0 then
        draw_rounded_rect(a, vs.cx, vs.cy - vs.h / 2, vol_ratio * vs.w, vs.h, vs.h / 2, color.white, "00")
    end
    if state.hover_volume then
        draw_circle(a, vs.cx + vol_ratio * vs.w, vs.cy, vs.h + 1, color.white, "00")
    end

    -- time
    local tt = L.time_text
    a:new_event(); a:pos(tt.x, tt.y); a:an(4)
    a:append(string.format("{\\fn%s\\fs%d\\bord0\\shad0\\1c&H%s&\\1a&H%s&}%s {\\1c&H%s&}/ %s",
        "Arial", options.font_size, color.white, "00", format_time(state.position),
        color.gray_light, format_time(dur)))

    -- playlist button
    draw_icon(a, icons.list, L.list_btn.cx, L.list_btn.cy, 18, hcol(state.hover_list), "00")

    -- settings button
    draw_icon(a, icons.set, L.settings_btn.cx, L.settings_btn.cy, 18, hcol(state.hover_settings), "00")

    -- seek tooltip
    if state.hover_seekbar and dur > 0 then
        local seek_ratio = clamp((state.mouse_x - sb.x) / sb.w, 0, 1)
        local seek_time  = format_time(seek_ratio * dur)
        local tip_x = clamp(state.mouse_x, sb.x + 30, sb.x + sb.w - 30)
        local tip_y = sb.y - 12
        draw_rounded_rect(a, tip_x - 26, tip_y - 18, 52, 20, 3, color.dark, "22")
        a:new_event(); a:pos(tip_x, tip_y - 8); a:an(5)
        a:append(string.format("{\\fn%s\\fs%d\\bord0\\shad0\\1c&H%s&\\1a&H00&}%s",
            "Arial Bold", options.font_size - 1, color.white, seek_time))
    end

    mp.set_osd_ass(W, H, a.text)
end

local function request_render()
    render()
end

local function update_sub_margin()
    if state.osd_h <= 0 then return end

    if state.visible then
        mp.set_property_number("sub-margin-y", options.bar_height + 20)
    else
        mp.set_property_number("sub-margin-y", 40)
    end
end

local function start_autohide()
    if state.idle then return end
    if state.autohide_timer then state.autohide_timer:kill() end
    state.autohide_timer = mp.add_timeout(options.autohide_timeout, function()
        state.visible = false
        update_sub_margin()
        render()
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

-- Mouse move
mp.observe_property("mouse-pos", "native", function(_, pos)
    if not pos then return end
    local moved = math.abs(pos.x - last_mouse_x) > 1 or math.abs(pos.y - last_mouse_y) > 1
    last_mouse_x, last_mouse_y = pos.x, pos.y
    state.mouse_x, state.mouse_y = pos.x, pos.y
    if moved then show_controls()
    else request_render() end
end)

-- Click handler
mp.add_key_binding("MOUSE_BTN0", "controls-click", function(e)
    if e.event ~= "press" then
        if e.event == "up" then
            if state.visible then start_autohide() end
            request_render()
        end
        return
    end

    if not state.visible then
        show_controls()
        return
    end

    local mx, my, L = state.mouse_x, state.mouse_y, layout
    if not L.bar then return end

    -- close button -> send to Delphi via script-message
    if state.hover_close then
        mp.commandv("script-message", "close")
        return
    end

    -- top minimize button
    if state.hover_topbar_min then
        mp.commandv("script-message", "minimize")
        return
    end

    -- top fullscreen button
    if state.hover_topbar_fs then
        mp.command("cycle fullscreen")
        show_controls()
        return
    end

    if state.hover_seekbar and state.duration > 0 then
        local seek_ratio = clamp((mx - L.seekbar.x) / L.seekbar.w, 0, 1)
        mp.set_property_number("time-pos", seek_ratio * state.duration)
        start_autohide()
        return
    end

    if state.hover_play then
        if state.idle then
            mp.commandv("script-message", "next")
        else
            mp.command("cycle pause")
        end
        start_autohide()
        return
    end
    if state.hover_prev then mp.commandv("script-message", "prev"); start_autohide(); return end
    if state.hover_next then mp.commandv("script-message", "next"); start_autohide(); return end
    if state.hover_mute then mp.command("cycle mute");  start_autohide(); return end
    if state.hover_volume then
        local vs = L.vol_slider
        local ratio = clamp((mx - vs.cx) / vs.w, 0, 1)
        mp.set_property_number("volume", math.floor(ratio * 100))
        start_autohide()
        return
    end

    -- playlist button -> send to Delphi
    if state.hover_list then
        mp.commandv("script-message", "playlist")
        start_autohide()
        return
    end

    -- settings button -> send to Delphi
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

-- Property observers
mp.observe_property("duration",       "number", function(_, v) v = v or 0;     if state.duration   ~= v then state.duration   = v; request_render() end end)
mp.observe_property("time-pos",       "number", function(_, v) v = v or 0;     if state.position   ~= v then state.position   = v; request_render() end end)
mp.observe_property("pause",          "bool",   function(_, v) v = v or false; if state.paused     ~= v then state.paused     = v; request_render() end end)
mp.observe_property("volume", "number", function(_, v)
    v = v or 100
    if v > 100 then
        mp.set_property_number("volume", 100)
        v = 100
    end
    if state.volume ~= v then
        state.volume = v
        mp.commandv("script-message", "volume", tostring(math.floor(v)))
        request_render()
    end
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
mp.observe_property("speed",          "number", function(_, v) v = v or 1.0;   if state.speed      ~= v then state.speed      = v; request_render() end end)
mp.observe_property("sub-visibility", "bool",   function(_, v) if state.sub_visible ~= v then state.sub_visible = v; request_render() end end)
mp.observe_property("chapter-list",   "native", function(_, v) state.chapter_list = v or {}; request_render() end)
mp.observe_property("osd-width",  "number", function(_, v) if v and v > 0 and state.osd_w ~= v then state.osd_w = v; request_render() end end)
mp.observe_property("osd-height", "number", function(_, v) if v and v > 0 and state.osd_h ~= v then state.osd_h = v; update_sub_margin(); request_render() end end)

-- Key bindings
mp.add_key_binding("SPACE", "yt-play-pause", function() mp.command("cycle pause"); show_controls() end)
mp.add_key_binding("RIGHT", "yt-seek-fwd",   function() mp.command("seek 5");      show_controls() end)
mp.add_key_binding("LEFT",  "yt-seek-back",  function() mp.command("seek -5");     show_controls() end)
mp.add_key_binding("l", "yt-seek-fwd10",     function() mp.command("seek 10");     show_controls() end)
mp.add_key_binding("j", "yt-seek-back10",    function() mp.command("seek -10");    show_controls() end)
mp.add_key_binding("k", "yt-pause",          function() mp.command("cycle pause"); show_controls() end)
mp.add_key_binding("m", "yt-mute",           function() mp.command("cycle mute");  show_controls() end)
mp.add_key_binding("f", "yt-fullscreen",     function() mp.command("cycle fullscreen"); show_controls() end)
mp.add_key_binding("c", "yt-sub-toggle",     function() mp.command("cycle sub-visibility"); show_controls() end)
mp.add_key_binding("n", "yt-next-chapter",   function() mp.command("add chapter 1");  show_controls() end)
mp.add_key_binding("p", "yt-prev-chapter",   function() mp.command("add chapter -1"); show_controls() end)

for i = 0, 9 do
    mp.add_key_binding(tostring(i), "yt-seek-" .. i, function()
        if state.duration > 0 then
            mp.set_property_number("time-pos", state.duration * i / 10)
            show_controls()
        end
    end)
end

local speeds = {0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0}

mp.add_key_binding(">", "yt-speed-up", function()
    local cur = state.speed
    for _, s in ipairs(speeds) do
        if s > cur then mp.set_property_number("speed", s); mp.osd_message("재생 속도: " .. s .. "x", 1); break end
    end
    show_controls()
end)

mp.add_key_binding("<", "yt-speed-down", function()
    local cur = state.speed
    for i = #speeds, 1, -1 do
        if speeds[i] < cur then mp.set_property_number("speed", speeds[i]); mp.osd_message("재생 속도: " .. speeds[i] .. "x", 1); break end
    end
    show_controls()
end)

-- Events
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
mp.register_event("seek",              function() show_controls() end)
mp.register_event("playback-restart",  function() show_controls() end)

state.paused = mp.get_property_bool("pause", true)
state.visible = true

mp.set_property("osd-level", "0")

request_render()
