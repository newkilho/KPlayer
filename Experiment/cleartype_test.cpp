// KilhoUI 반투명 실험 — mpv 자식 창 위에 투명 DirectComposition 창을 얹을 수 있나.
//   overlay_test.exe <mode> <video> <libmpv-2.dll> <out-prefix>
//   mode child   : 형제 자식 창(WS_EX_NOREDIRECTIONBITMAP) + 그 창 대상 DComp — KilhoUI 구조 그대로
//        topmost : 부모 창 대상 DComp(topmost=TRUE), 입력 창 없음
// 확인: ① 투명 부분에 영상이 보이나 (화면 캡처 → <out>.bmp) ② 클릭이 어느 창에 가나 (<out>.log)
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
#include <stdio.h>
#include <string>

typedef void *(*fn_create)();
typedef int (*fn_init)(void *);
typedef int (*fn_setopt)(void *, const char *, const char *);
typedef int (*fn_cmd)(void *, const char **);

static FILE *g_log;
static HWND g_main, g_ovl, g_mpvwin;
static bool g_topmost;
static bool g_cleartype;
static int g_clicks_ovl, g_clicks_main;
static std::wstring g_out;

static IDXGISwapChain1 *g_sc;
static ID2D1DeviceContext *g_dc;
static IDCompositionDevice *g_dcomp;
static IDCompositionTarget *g_target;
static IDCompositionVisual *g_visual;
static IDWriteTextFormat *g_fmt;

#define LOG(...) do { fprintf(g_log, __VA_ARGS__); fputc('\n', g_log); fflush(g_log); } while (0)
#define CHK(x) do { HRESULT _h = (x); if (FAILED(_h)) { LOG("FAIL %s = 0x%08lx", #x, (unsigned long)_h); return false; } } while (0)

static bool init_gfx(HWND target_hwnd, int w, int h)
{
    ID3D11Device *d3d = NULL;
    CHK(D3D11CreateDevice(NULL, D3D_DRIVER_TYPE_HARDWARE, NULL, D3D11_CREATE_DEVICE_BGRA_SUPPORT,
                          NULL, 0, D3D11_SDK_VERSION, &d3d, NULL, NULL));
    IDXGIDevice *dxgi = NULL; IDXGIAdapter *ad = NULL; IDXGIFactory2 *fac = NULL;
    CHK(d3d->QueryInterface(__uuidof(IDXGIDevice), (void **)&dxgi));
    CHK(dxgi->GetAdapter(&ad));
    CHK(ad->GetParent(__uuidof(IDXGIFactory2), (void **)&fac));

    DXGI_SWAP_CHAIN_DESC1 sd = {};
    sd.Width = w; sd.Height = h;
    sd.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    sd.SampleDesc.Count = 1;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.BufferCount = 2;
    sd.Scaling = DXGI_SCALING_STRETCH;                 // composition 스왑체인은 NONE 불가
    sd.SwapEffect = DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL;
    sd.AlphaMode = DXGI_ALPHA_MODE_PREMULTIPLIED;
    CHK(fac->CreateSwapChainForComposition(d3d, &sd, NULL, &g_sc));

    ID2D1Factory1 *d2f = NULL;
    CHK(D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, __uuidof(ID2D1Factory1), NULL, (void **)&d2f));
    ID2D1Device *d2dev = NULL;
    CHK(d2f->CreateDevice(dxgi, &d2dev));
    CHK(d2dev->CreateDeviceContext(D2D1_DEVICE_CONTEXT_OPTIONS_NONE, &g_dc));
    IDXGISurface *surf = NULL;
    CHK(g_sc->GetBuffer(0, __uuidof(IDXGISurface), (void **)&surf));
    D2D1_BITMAP_PROPERTIES1 bp = {};
    bp.pixelFormat.format = DXGI_FORMAT_B8G8R8A8_UNORM;
    bp.pixelFormat.alphaMode = D2D1_ALPHA_MODE_PREMULTIPLIED;
    bp.dpiX = bp.dpiY = 96;
    bp.bitmapOptions = D2D1_BITMAP_OPTIONS_TARGET | D2D1_BITMAP_OPTIONS_CANNOT_DRAW;
    ID2D1Bitmap1 *back = NULL;
    CHK(g_dc->CreateBitmapFromDxgiSurface(surf, &bp, &back));
    g_dc->SetTarget(back);
    g_dc->SetTextAntialiasMode(g_cleartype ? D2D1_TEXT_ANTIALIAS_MODE_CLEARTYPE : D2D1_TEXT_ANTIALIAS_MODE_GRAYSCALE);

    IDWriteFactory *dw = NULL;
    CHK(DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory), (IUnknown **)&dw));
    CHK(dw->CreateTextFormat(L"Malgun Gothic", NULL, DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL,
                             DWRITE_FONT_STRETCH_NORMAL, 20.0f, L"ko-kr", &g_fmt));

    typedef HRESULT (WINAPI *fn_dc)(IDXGIDevice *, REFIID, void **);
    fn_dc create = (fn_dc)GetProcAddress(LoadLibraryW(L"dcomp.dll"), "DCompositionCreateDevice");
    if (!create) { LOG("FAIL DCompositionCreateDevice not found"); return false; }
    CHK(create(dxgi, __uuidof(IDCompositionDevice), (void **)&g_dcomp));
    CHK(g_dcomp->CreateTargetForHwnd(target_hwnd, g_topmost ? TRUE : FALSE, &g_target));
    CHK(g_dcomp->CreateVisual(&g_visual));
    CHK(g_visual->SetContent(g_sc));
    CHK(g_target->SetRoot(g_visual));
    LOG("gfx ok: composition swapchain %dx%d premultiplied, dcomp target hwnd=%p topmost=%d", w, h, (void *)target_hwnd, g_topmost);
    return true;
}

static void draw(int w, int h)
{
    g_dc->BeginDraw();
    g_dc->Clear(D2D1::ColorF(0, 0, 0, 0));
    ID2D1SolidColorBrush *br = NULL;
    g_dc->CreateSolidColorBrush(D2D1::ColorF(0.1f, 0.1f, 0.1f, 1.0f), &br);
    g_dc->FillRectangle(D2D1::RectF(20, 60, 460, 110), br);              // A: 불투명 칩
    br->SetColor(D2D1::ColorF(0, 0, 0, 0.55f));
    g_dc->FillRectangle(D2D1::RectF(20, 160, 460, 210), br);             // B: 반투명 바
    br->SetColor(D2D1::ColorF(1, 1, 1, 1));
    const wchar_t *t = L"KPlayer 제목 Title 00:12 / 01:23:45";
    g_dc->DrawText(t, (UINT32)wcslen(t), g_fmt, D2D1::RectF(30, 70, 460, 110), br);
    g_dc->DrawText(t, (UINT32)wcslen(t), g_fmt, D2D1::RectF(30, 170, 460, 210), br);
    g_dc->DrawText(t, (UINT32)wcslen(t), g_fmt, D2D1::RectF(30, 270, 460, 310), br);   // C: 완전 투명
    br->Release();
    HRESULT hr = g_dc->EndDraw();
    LOG("EndDraw 0x%08lx mode=%s", (unsigned long)hr, g_cleartype ? "cleartype" : "grayscale");
    g_sc->Present(1, 0);
    g_dcomp->Commit();
}

// 글자 칸에서 색 번짐(서브픽셀) 픽셀 수 — R·G·B 중 최대-최소 차가 큰 픽셀. 회색조면 거의 0.
static void fringe(unsigned *px, int w, const char *name, int x0, int y0, int x1, int y1)
{
    int n = 0, maxd = 0;
    for (int y = y0; y < y1; y++) for (int x = x0; x < x1; x++) {
        unsigned c = px[y * w + x];
        int r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255;
        int mx = r > g ? (r > b ? r : b) : (g > b ? g : b), mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
        if (mx - mn > maxd) maxd = mx - mn;
        if (mx - mn > 24) n++;
    }
    LOG("%s: chroma pixels=%d max chroma=%d", name, n, maxd);
}

static void save_screen(const RECT &rc, const std::wstring &path)
{
    int w = rc.right - rc.left, h = rc.bottom - rc.top;
    HDC scr = GetDC(NULL), mem = CreateCompatibleDC(scr);
    BITMAPINFO bi = {};
    bi.bmiHeader.biSize = sizeof bi.bmiHeader;
    bi.bmiHeader.biWidth = w; bi.bmiHeader.biHeight = -h;
    bi.bmiHeader.biPlanes = 1; bi.bmiHeader.biBitCount = 32;
    void *bits = NULL;
    HBITMAP bmp = CreateDIBSection(scr, &bi, DIB_RGB_COLORS, &bits, NULL, 0);
    HGDIOBJ old = SelectObject(mem, bmp);
    BitBlt(mem, 0, 0, w, h, scr, rc.left, rc.top, SRCCOPY | CAPTUREBLT);
    BITMAPFILEHEADER fh = {};
    fh.bfType = 0x4D42; fh.bfOffBits = sizeof fh + sizeof bi.bmiHeader; fh.bfSize = fh.bfOffBits + w * h * 4;
    FILE *f = _wfopen(path.c_str(), L"wb");
    if (f) { fwrite(&fh, sizeof fh, 1, f); fwrite(&bi.bmiHeader, sizeof bi.bmiHeader, 1, f); fwrite(bits, 4, (size_t)w * h, f); fclose(f); }
    fringe((unsigned *)bits, w, "A opaque chip  ", 30, 66, 450, 104);
    fringe((unsigned *)bits, w, "B 55% bar      ", 30, 166, 450, 204);
    fringe((unsigned *)bits, w, "C transparent  ", 30, 266, 450, 304);
    // 투명 영역(가운데) 픽셀 몇 개 — 영상이 비치면 testsrc2 의 색, 아니면 단색(검정/배경)
    unsigned *px = (unsigned *)bits;
    for (int i = 1; i <= 3; i++) {
        int x = w * i / 4, y = h / 2;
        LOG("center pixel (%d,%d) = #%06X", x, y, px[y * w + x] & 0xFFFFFF);
    }
    SelectObject(mem, old); DeleteObject(bmp); DeleteDC(mem); ReleaseDC(NULL, scr);
}

static BOOL CALLBACK find_mpv(HWND h, LPARAM)
{
    if (h != g_ovl && GetParent(h) == g_main) { g_mpvwin = h; return FALSE; }
    return TRUE;
}

static const char *who(HWND h)
{
    if (h == g_ovl) return "overlay";
    if (h == g_main) return "main";
    if (h == g_mpvwin) return "mpv";
    return "other";
}

static void click_at(int cx, int cy)
{
    POINT pt = { cx, cy };
    HWND hit = WindowFromPoint(pt);
    LOG("WindowFromPoint(%d,%d) = %s", cx, cy, who(hit));
    SetCursorPos(cx, cy);
    INPUT in[2] = {};
    in[0].type = in[1].type = INPUT_MOUSE;
    in[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    in[1].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(2, in, sizeof(INPUT));
}

static LRESULT CALLBACK ovl_proc(HWND h, UINT m, WPARAM w, LPARAM l)
{
    if (m == WM_LBUTTONDOWN) { g_clicks_ovl++; LOG("overlay WM_LBUTTONDOWN"); }
    if (m == WM_NCHITTEST) return HTCLIENT;
    return DefWindowProcW(h, m, w, l);
}

static LRESULT CALLBACK main_proc(HWND h, UINT m, WPARAM w, LPARAM l)
{
    switch (m) {
    case WM_LBUTTONDOWN: g_clicks_main++; LOG("main WM_LBUTTONDOWN"); break;
    case WM_TIMER: {
        RECT rc; GetClientRect(h, &rc);
        POINT o = { 0, 0 }; ClientToScreen(h, &o);
        if (w == 1) {
            EnumChildWindows(g_main, find_mpv, 0);
            if (g_mpvwin) {
                wchar_t cls[64]; GetClassNameW(g_mpvwin, cls, 64);
                LONG st = GetWindowLongW(g_mpvwin, GWL_STYLE), ex = GetWindowLongW(g_mpvwin, GWL_EXSTYLE);
                LOG("mpv window class=%ls style=%08lX exstyle=%08lX clipsiblings=%d", cls, st, ex, (st & WS_CLIPSIBLINGS) != 0);
            } else LOG("mpv window not found");
            if (g_ovl) SetWindowPos(g_ovl, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
            HWND top = GetWindow(g_main, GW_CHILD);
            LOG("top child = %s", who(top));
        } else if (w == 2) {
            RECT sr = { o.x, o.y, o.x + rc.right, o.y + rc.bottom };
            save_screen(sr, g_out + L".bmp");
            click_at(o.x + rc.right / 2, o.y + rc.bottom / 2);        // 투명 영역
            click_at(o.x + 36, o.y + rc.bottom - 28);                // 빨간 버튼
        } else if (w == 3) {
            LOG("clicks: overlay=%d main=%d", g_clicks_ovl, g_clicks_main);
            PostQuitMessage(0);
        }
        KillTimer(h, w);
        return 0;
    }
    case WM_DESTROY: PostQuitMessage(0); return 0;
    }
    return DefWindowProcW(h, m, w, l);
}

int wmain(int argc, wchar_t **argv)
{
    if (argc < 5) return 2;
    g_topmost = wcscmp(argv[1], L"topmost") == 0;
    g_cleartype = argc > 5 && wcscmp(argv[5], L"cleartype") == 0;
    g_out = argv[4];
    g_log = _wfopen((g_out + L".log").c_str(), L"w");
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
    HINSTANCE hi = GetModuleHandleW(NULL);

    WNDCLASSW wc = {};
    wc.lpfnWndProc = main_proc; wc.hInstance = hi; wc.lpszClassName = L"OvlMain";
    wc.hCursor = LoadCursor(NULL, IDC_ARROW); wc.hbrBackground = (HBRUSH)GetStockObject(GRAY_BRUSH);
    RegisterClassW(&wc);
    wc.lpfnWndProc = ovl_proc; wc.lpszClassName = L"OvlChild"; wc.hbrBackground = NULL;
    RegisterClassW(&wc);

    const int W = 960, H = 540;
    RECT r = { 0, 0, W, H };
    AdjustWindowRectEx(&r, WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN, FALSE, WS_EX_TOPMOST);
    g_main = CreateWindowExW(WS_EX_TOPMOST, L"OvlMain", L"overlay test", WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
                             100, 100, r.right - r.left, r.bottom - r.top, NULL, NULL, hi, NULL);
    ShowWindow(g_main, SW_SHOW);
    SetForegroundWindow(g_main);

    // mpv: wid = 본체 창 (KPlayer 와 같음 — mpv 가 그 안에 자기 자식 창을 만든다)
    HMODULE mpv = LoadLibraryW(argv[3]);
    if (!mpv) { LOG("FAIL load libmpv"); return 1; }
    fn_create c = (fn_create)GetProcAddress(mpv, "mpv_create");
    fn_init in = (fn_init)GetProcAddress(mpv, "mpv_initialize");
    fn_setopt so = (fn_setopt)GetProcAddress(mpv, "mpv_set_option_string");
    fn_cmd cmd = (fn_cmd)GetProcAddress(mpv, "mpv_command");
    void *h = c();
    char wid[32]; snprintf(wid, sizeof wid, "%lld", (long long)(INT_PTR)g_main);
    so(h, "wid", wid); so(h, "vo", "gpu"); so(h, "hwdec", "auto-safe"); so(h, "loop-file", "inf");
    so(h, "osc", "no"); so(h, "input-default-bindings", "no"); so(h, "input-vo-keyboard", "no");
    so(h, "input-cursor", "no"); so(h, "config", "no");
    LOG("mpv_initialize = %d", in(h));
    char path[MAX_PATH * 3]; WideCharToMultiByte(CP_UTF8, 0, argv[2], -1, path, sizeof path, NULL, NULL);
    const char *args[] = { "loadfile", path, NULL };
    LOG("loadfile = %d", cmd(h, args));

    HWND target = g_main;
    if (!g_topmost) {
        g_ovl = CreateWindowExW(WS_EX_NOREDIRECTIONBITMAP, L"OvlChild", L"", WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS,
                                0, 0, W, H, g_main, NULL, hi, NULL);
        target = g_ovl;
    }
    if (!init_gfx(target, W, H)) return 1;
    draw(W, H);

    SetTimer(g_main, 1, 1500, NULL);   // mpv 창 찾기·z-order
    SetTimer(g_main, 2, 3000, NULL);   // 캡처 + 클릭
    SetTimer(g_main, 3, 3800, NULL);   // 결과·종료
    MSG msg;
    while (GetMessageW(&msg, NULL, 0, 0) > 0) { TranslateMessage(&msg); DispatchMessageW(&msg); }
    const char *q[] = { "quit", NULL };
    cmd(h, q);
    fclose(g_log);
    TerminateProcess(GetCurrentProcess(), 0);   // mpv 종료 대기 생략
    return 0;
}
