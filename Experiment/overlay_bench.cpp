// KilhoUI 반투명 측정 — overlay_test.cpp 의 자식 창 방식(확인됨)으로 비용·크기 조절 동기화를 잰다.
//   overlay_bench.exe <scenario> <video> <libmpv-2.dll> <out-prefix> <seconds> [fs]
//   scenario none   : 오버레이 창 없음 (mpv 만 — 기준선)
//            static : 한 번 그리고 그대로
//            clock  : 1초마다 시간 글자 갱신 (Present1 더티 영역 = 글자 칸만)
//            anim   : 매 vblank 전체 다시 그리기 (페이드 애니메이션 = 최악)
//            hidden : 만든 뒤 SW_HIDE (KilhoUI set_visible(0))
//            resize : 창 크기를 단계적으로 바꾸며 매 단계 캡처·어긋남 측정 (<out>.log, <out>_NN.bmp)
//   fs     : 모니터 전체 크기 테두리 없는 창 (전체 화면)
// CPU·GPU 는 바깥 PowerShell(bench.ps1)이 잰다. 이 프로그램은 <seconds> 뒤 스스로 끝난다.
#define WIN32_LEAN_AND_MEAN
#ifndef UNICODE
#define UNICODE
#endif
#define _WIN32_WINNT 0x0A00
#include <windows.h>
#include <d3d11.h>
#include <dxgi1_2.h>
#include <d2d1_1.h>
#include <dwrite.h>
#include <dcomp.h>
#include <dwmapi.h>
#include <stdio.h>
#include <math.h>
#include <string>

typedef void *(*fn_create)();
typedef int (*fn_init)(void *);
typedef int (*fn_setopt)(void *, const char *, const char *);
typedef int (*fn_cmd)(void *, const char **);

enum { S_NONE, S_STATIC, S_CLOCK, S_ANIM, S_HIDDEN, S_RESIZE };
static int g_scn;
static FILE *g_log;
static HWND g_main, g_ovl;
static std::wstring g_out;
static int g_w, g_h, g_tick;

static ID3D11Device *g_d3d;
static IDXGISwapChain1 *g_sc;
static ID2D1DeviceContext *g_dc;
static ID2D1Bitmap1 *g_back;
static IDCompositionDevice *g_dcomp;
static IDCompositionTarget *g_target;
static IDCompositionVisual *g_visual;
static IDWriteTextFormat *g_fmt;

#define LOG(...) do { fprintf(g_log, __VA_ARGS__); fputc('\n', g_log); fflush(g_log); } while (0)
#define CHK(x) do { HRESULT _h = (x); if (FAILED(_h)) { LOG("FAIL %s = 0x%08lx", #x, (unsigned long)_h); return false; } } while (0)

static bool make_target()
{
    IDXGISurface *surf = NULL;
    CHK(g_sc->GetBuffer(0, __uuidof(IDXGISurface), (void **)&surf));
    D2D1_BITMAP_PROPERTIES1 bp = {};
    bp.pixelFormat.format = DXGI_FORMAT_B8G8R8A8_UNORM;
    bp.pixelFormat.alphaMode = D2D1_ALPHA_MODE_PREMULTIPLIED;
    bp.dpiX = bp.dpiY = 96;
    bp.bitmapOptions = D2D1_BITMAP_OPTIONS_TARGET | D2D1_BITMAP_OPTIONS_CANNOT_DRAW;
    HRESULT hr = g_dc->CreateBitmapFromDxgiSurface(surf, &bp, &g_back);
    surf->Release();
    CHK(hr);
    g_dc->SetTarget(g_back);
    return true;
}

static bool init_gfx(HWND hwnd, int w, int h)
{
    CHK(D3D11CreateDevice(NULL, D3D_DRIVER_TYPE_HARDWARE, NULL, D3D11_CREATE_DEVICE_BGRA_SUPPORT,
                          NULL, 0, D3D11_SDK_VERSION, &g_d3d, NULL, NULL));
    IDXGIDevice *dxgi = NULL; IDXGIAdapter *ad = NULL; IDXGIFactory2 *fac = NULL;
    CHK(g_d3d->QueryInterface(__uuidof(IDXGIDevice), (void **)&dxgi));
    CHK(dxgi->GetAdapter(&ad));
    CHK(ad->GetParent(__uuidof(IDXGIFactory2), (void **)&fac));
    DXGI_SWAP_CHAIN_DESC1 sd = {};
    sd.Width = w; sd.Height = h;
    sd.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    sd.SampleDesc.Count = 1;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.BufferCount = 2;
    sd.Scaling = DXGI_SCALING_STRETCH;
    sd.SwapEffect = DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL;
    sd.AlphaMode = DXGI_ALPHA_MODE_PREMULTIPLIED;
    CHK(fac->CreateSwapChainForComposition(g_d3d, &sd, NULL, &g_sc));
    ID2D1Factory1 *d2f = NULL;
    CHK(D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, __uuidof(ID2D1Factory1), NULL, (void **)&d2f));
    ID2D1Device *d2dev = NULL;
    CHK(d2f->CreateDevice(dxgi, &d2dev));
    CHK(d2dev->CreateDeviceContext(D2D1_DEVICE_CONTEXT_OPTIONS_NONE, &g_dc));
    if (!make_target()) return false;
    g_dc->SetTextAntialiasMode(D2D1_TEXT_ANTIALIAS_MODE_GRAYSCALE);
    IDWriteFactory *dw = NULL;
    CHK(DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory), (IUnknown **)&dw));
    CHK(dw->CreateTextFormat(L"Malgun Gothic", NULL, DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL,
                             DWRITE_FONT_STRETCH_NORMAL, 20.0f, L"ko-kr", &g_fmt));
    typedef HRESULT (WINAPI *fn_dc)(IDXGIDevice *, REFIID, void **);
    fn_dc create = (fn_dc)GetProcAddress(LoadLibraryW(L"dcomp.dll"), "DCompositionCreateDevice");
    CHK(create(dxgi, __uuidof(IDCompositionDevice), (void **)&g_dcomp));
    CHK(g_dcomp->CreateTargetForHwnd(hwnd, FALSE, &g_target));
    CHK(g_dcomp->CreateVisual(&g_visual));
    CHK(g_visual->SetContent(g_sc));
    CHK(g_target->SetRoot(g_visual));
    return true;
}

// 제목 바(상단 40) + 컨트롤 바(하단 56) 반투명, 시간 글자. resize 는 가장자리에 불투명 표식 띠(파랑 위 / 자홍 아래, 각 20px).
static void draw(float fade)
{
    float w = (float)g_w, h = (float)g_h;
    g_dc->BeginDraw();
    g_dc->Clear(D2D1::ColorF(0, 0, 0, 0));
    ID2D1SolidColorBrush *br = NULL;
    g_dc->CreateSolidColorBrush(D2D1::ColorF(0, 0, 0, 0.55f * fade), &br);
    g_dc->FillRectangle(D2D1::RectF(0, 0, w, 40), br);
    g_dc->FillRectangle(D2D1::RectF(0, h - 56, w, h), br);
    br->SetColor(D2D1::ColorF(1, 1, 1, fade));
    const wchar_t *t1 = L"KPlayer 제목 — DirectWrite 회색조";
    g_dc->DrawText(t1, (UINT32)wcslen(t1), g_fmt, D2D1::RectF(12, 7, w, 40), br);
    wchar_t t2[64];
    swprintf(t2, 64, L"00:%02d / 01:23:45", g_tick % 60);
    g_dc->DrawText(t2, (UINT32)wcslen(t2), g_fmt, D2D1::RectF(70, h - 42, w, h), br);
    if (g_scn == S_RESIZE) {
        br->SetColor(D2D1::ColorF(0, 0, 1, 1));
        g_dc->FillRectangle(D2D1::RectF(0, 0, w, 20), br);
        br->SetColor(D2D1::ColorF(1, 0, 1, 1));
        g_dc->FillRectangle(D2D1::RectF(0, h - 20, w, h), br);
    }
    br->Release();
    g_dc->EndDraw();
}

static void present(const RECT *dirty)
{
    DXGI_PRESENT_PARAMETERS pp = {};
    if (dirty) { pp.DirtyRectsCount = 1; pp.pDirtyRects = (RECT *)dirty; }
    g_sc->Present1(1, 0, &pp);
    g_dcomp->Commit();
}

static void resize_overlay(int w, int h)
{
    if (!g_sc || w <= 0 || h <= 0 || (w == g_w && h == g_h)) return;
    g_dc->SetTarget(NULL);
    g_back->Release(); g_back = NULL;
    g_sc->ResizeBuffers(0, w, h, DXGI_FORMAT_UNKNOWN, 0);
    g_w = w; g_h = h;
    make_target();
    draw(1);
    present(NULL);
}

// 캡처 — 가운데 열을 위에서 아래로 훑어 표식 띠 위치, 오른쪽 끝 열의 영상 유무
static void capture_step(int step, int expect_w, int expect_h)
{
    POINT o = { 0, 0 }; ClientToScreen(g_main, &o);
    int w = expect_w, h = expect_h;
    HDC scr = GetDC(NULL), mem = CreateCompatibleDC(scr);
    BITMAPINFO bi = {};
    bi.bmiHeader.biSize = sizeof bi.bmiHeader;
    bi.bmiHeader.biWidth = w; bi.bmiHeader.biHeight = -h;
    bi.bmiHeader.biPlanes = 1; bi.bmiHeader.biBitCount = 32;
    void *bits = NULL;
    HBITMAP bmp = CreateDIBSection(scr, &bi, DIB_RGB_COLORS, &bits, NULL, 0);
    HGDIOBJ old = SelectObject(mem, bmp);
    BitBlt(mem, 0, 0, w, h, scr, o.x, o.y, SRCCOPY | CAPTUREBLT);
    unsigned *px = (unsigned *)bits;
    auto is_mag = [](unsigned c) { int r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255; return r > 200 && g < 60 && b > 200; };
    auto is_blue = [](unsigned c) { int r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255; return r < 60 && g < 60 && b > 200; };
    int cx = w / 3;
    int mag_top = -1, mag_rows = 0, blue_rows = 0;
    for (int y = 0; y < h; y++) {
        unsigned c = px[y * w + cx];
        if (is_mag(c)) { mag_rows++; if (mag_top < 0) mag_top = y; }
        if (is_blue(c)) blue_rows++;
    }
    // 영상 오른쪽 끝: keepaspect=no 라 영상이 창을 채워야 한다 — 끝 열이 회색(창 배경 #808080)·검정이면 mpv 가 아직 옛 크기
    unsigned edge = px[(h / 2) * w + (w - 2)];
    int er = (edge >> 16) & 255, eg = (edge >> 8) & 255, eb = edge & 255;
    bool video_edge = !((abs(er - eg) < 8 && abs(eg - eb) < 8));   // 무채색이 아니면 영상
    LOG("step %02d size %dx%d  overlay: magenta top=%d (expect %d, err %+d) rows=%d blue rows=%d  video right edge=%s #%06X",
        step, w, h, mag_top, h - 20, mag_top < 0 ? 9999 : mag_top - (h - 20), mag_rows, blue_rows,
        video_edge ? "video" : "STALE", edge & 0xFFFFFF);
    if (step % 10 == 0) {
        wchar_t name[32]; swprintf(name, 32, L"_%02d.bmp", step);
        BITMAPFILEHEADER fh = {};
        fh.bfType = 0x4D42; fh.bfOffBits = sizeof fh + sizeof bi.bmiHeader; fh.bfSize = fh.bfOffBits + w * h * 4;
        FILE *f = _wfopen((g_out + name).c_str(), L"wb");
        if (f) { fwrite(&fh, sizeof fh, 1, f); fwrite(&bi.bmiHeader, sizeof bi.bmiHeader, 1, f); fwrite(bits, 4, (size_t)w * h, f); fclose(f); }
    }
    SelectObject(mem, old); DeleteObject(bmp); DeleteDC(mem); ReleaseDC(NULL, scr);
}

static void run_resize()
{
    // 800x450 ↔ 1200x675 왕복, 60 단계 — 사용자가 가장자리를 끄는 속도 정도 (단계당 한 vblank). 화면(1280 폭) 안에 두려고 (0,0)
    SetWindowPos(g_main, NULL, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
    RECT wr; GetWindowRect(g_main, &wr);
    RECT cr; GetClientRect(g_main, &cr);
    int fw = (wr.right - wr.left) - cr.right, fh = (wr.bottom - wr.top) - cr.bottom;
    int stale = 0, ovl_bad = 0;
    for (int i = 0; i <= 60; i++) {
        double t = i <= 30 ? i / 30.0 : (60 - i) / 30.0;
        int w = 800 + (int)lround(400 * t), h = 450 + (int)lround(225 * t);
        SetWindowPos(g_main, NULL, 0, 0, w + fw, h + fh, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
        MSG m; while (PeekMessageW(&m, NULL, 0, 0, PM_REMOVE)) DispatchMessageW(&m);
        DwmFlush();                       // 한 번 합성된 화면을 잡는다
        capture_step(i, w, h);
    }
    (void)stale; (void)ovl_bad;
}

static LRESULT CALLBACK ovl_proc(HWND h, UINT m, WPARAM w, LPARAM l)
{
    if (m == WM_NCHITTEST) return HTCLIENT;
    return DefWindowProcW(h, m, w, l);
}

static LRESULT CALLBACK main_proc(HWND h, UINT m, WPARAM w, LPARAM l)
{
    switch (m) {
    case WM_SIZE:
        if (g_ovl) {
            int cw = LOWORD(l), ch = HIWORD(l);
            MoveWindow(g_ovl, 0, 0, cw, ch, FALSE);
            resize_overlay(cw, ch);
        }
        return 0;
    case WM_TIMER:
        if (w == 1) { PostQuitMessage(0); return 0; }
        if (w == 2) {                     // clock: 1초마다 시간 칸만
            g_tick++;
            draw(1);
            RECT d = { 60, g_h - 50, 260, g_h - 10 };
            present(&d);
            return 0;
        }
        if (w == 3) { KillTimer(h, 3); run_resize(); PostQuitMessage(0); return 0; }
        return 0;
    case WM_DESTROY: PostQuitMessage(0); return 0;
    }
    return DefWindowProcW(h, m, w, l);
}

int wmain(int argc, wchar_t **argv)
{
    if (argc < 6) return 2;
    const wchar_t *s = argv[1];
    g_scn = !wcscmp(s, L"static") ? S_STATIC : !wcscmp(s, L"clock") ? S_CLOCK : !wcscmp(s, L"anim") ? S_ANIM
          : !wcscmp(s, L"hidden") ? S_HIDDEN : !wcscmp(s, L"resize") ? S_RESIZE : S_NONE;
    g_out = argv[4];
    int secs = _wtoi(argv[5]);
    bool fs = argc > 6 && !wcscmp(argv[6], L"fs");
    g_log = _wfopen((g_out + L".log").c_str(), L"w");
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
    HINSTANCE hi = GetModuleHandleW(NULL);
    WNDCLASSW wc = {};
    wc.lpfnWndProc = main_proc; wc.hInstance = hi; wc.lpszClassName = L"BenchMain";
    wc.hCursor = LoadCursor(NULL, IDC_ARROW); wc.hbrBackground = (HBRUSH)GetStockObject(GRAY_BRUSH);
    RegisterClassW(&wc);
    wc.lpfnWndProc = ovl_proc; wc.lpszClassName = L"BenchOvl"; wc.hbrBackground = NULL;
    RegisterClassW(&wc);

    int x = 100, y = 100, W = 960, H = 540;
    DWORD style = WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN;
    RECT r = { 0, 0, W, H };
    if (fs) {
        MONITORINFO mi = { sizeof mi };
        GetMonitorInfoW(MonitorFromPoint(POINT{ 0, 0 }, MONITOR_DEFAULTTOPRIMARY), &mi);
        r = mi.rcMonitor; x = r.left; y = r.top; W = r.right - r.left; H = r.bottom - r.top;
        style = WS_POPUP | WS_CLIPCHILDREN;
    } else AdjustWindowRectEx(&r, style, FALSE, WS_EX_TOPMOST);
    g_main = CreateWindowExW(WS_EX_TOPMOST, L"BenchMain", L"overlay bench", style,
                             x, y, r.right - r.left, r.bottom - r.top, NULL, NULL, hi, NULL);
    ShowWindow(g_main, SW_SHOW);
    SetForegroundWindow(g_main);
    RECT cr; GetClientRect(g_main, &cr); W = cr.right; H = cr.bottom;

    HMODULE mpv = LoadLibraryW(argv[3]);
    fn_create c = (fn_create)GetProcAddress(mpv, "mpv_create");
    fn_init in = (fn_init)GetProcAddress(mpv, "mpv_initialize");
    fn_setopt so = (fn_setopt)GetProcAddress(mpv, "mpv_set_option_string");
    fn_cmd cmd = (fn_cmd)GetProcAddress(mpv, "mpv_command");
    void *h = c();
    char wid[32]; snprintf(wid, sizeof wid, "%lld", (long long)(INT_PTR)g_main);
    so(h, "wid", wid); so(h, "vo", "gpu"); so(h, "hwdec", "auto-safe"); so(h, "loop-file", "inf");
    so(h, "osc", "no"); so(h, "input-default-bindings", "no"); so(h, "input-vo-keyboard", "no");
    so(h, "input-cursor", "no"); so(h, "config", "no"); so(h, "keepaspect", "no");
    in(h);
    char path[MAX_PATH * 3]; WideCharToMultiByte(CP_UTF8, 0, argv[2], -1, path, sizeof path, NULL, NULL);
    const char *args[] = { "loadfile", path, NULL };
    cmd(h, args);

    if (g_scn != S_NONE) {
        g_ovl = CreateWindowExW(WS_EX_NOREDIRECTIONBITMAP, L"BenchOvl", L"", WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS,
                                0, 0, W, H, g_main, NULL, hi, NULL);
        g_w = W; g_h = H;
        if (!init_gfx(g_ovl, W, H)) return 1;
        draw(1);
        present(NULL);
        if (g_scn == S_HIDDEN) ShowWindow(g_ovl, SW_HIDE);
    }
    DEVMODEW dm = { }; dm.dmSize = sizeof dm;
    EnumDisplaySettingsW(NULL, ENUM_CURRENT_SETTINGS, &dm);
    LOG("scenario=%ls fs=%d client=%dx%d display=%lux%lu@%luHz pid=%lu", s, fs, W, H,
        dm.dmPelsWidth, dm.dmPelsHeight, dm.dmDisplayFrequency, GetCurrentProcessId());

    if (g_scn == S_RESIZE) SetTimer(g_main, 3, 2500, NULL);
    else SetTimer(g_main, 1, secs * 1000, NULL);
    if (g_scn == S_CLOCK) SetTimer(g_main, 2, 1000, NULL);

    MSG msg;
    for (;;) {
        if (g_scn == S_ANIM) {            // 매 vblank 다시 그리기 — 메시지 비우고 그리고 Present(1) 이 vsync 대기
            bool quit = false;
            while (PeekMessageW(&msg, NULL, 0, 0, PM_REMOVE)) {
                if (msg.message == WM_QUIT) { quit = true; break; }
                TranslateMessage(&msg); DispatchMessageW(&msg);
            }
            if (quit) break;
            static int f; f++;
            draw(0.5f + 0.5f * (float)fabs(sin(f / 30.0)));
            present(NULL);
        } else {
            if (GetMessageW(&msg, NULL, 0, 0) <= 0) break;
            TranslateMessage(&msg); DispatchMessageW(&msg);
        }
    }
    LOG("done");
    fclose(g_log);
    TerminateProcess(GetCurrentProcess(), 0);
    return 0;
}
