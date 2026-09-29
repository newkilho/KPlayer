unit OSUtil;

// OS 별 창·셸 기법 모음. Windows 구현만 있고 그 밖은 LCL 일반 동작 또는 no-op —
// macOS 이식 때 {$ELSE} 쪽만 채운다 (호출부에 IFDEF 를 흩뿌리지 않으려고 한 곳에 모음).

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls;

// 항상 위. fsStayOnTop 금지 — 핸들 재생성 시 mpv wid 무효 → 영상 사라짐. 그래서 창 핸들에 직접.
procedure SetWindowTopMost(AForm: TCustomForm; AState: Boolean);

// 테두리 없는 창을 마우스로 끌기. 뗄 때까지 안 돌아온다 (Windows 이동 루프).
// False = 이 OS 는 미지원 (호출부가 클릭 처리만).
function StartWindowDrag(AForm: TCustomForm): Boolean;

// OS UI 기본 글꼴 이름 — OSD 글꼴 (KPlayer.lua ui-font). LCL Screen 에는 VCL 의 MessageFont 가 없다.
function UIFontName: string;

// 관리자 ↔ 일반 프로세스 간 파일 드롭 허용 (UIPI). Delphi K.DragFile 이 하던 것.
procedure AllowDropFromLowerIntegrity(AHandle: THandle);

// 다크 타이틀바 (Windows 10 1809+)
procedure SetDarkTitleBar(AHandle: THandle);

// 바탕화면 폴더 (끝 구분자 포함). 못 얻으면 exe 폴더.
function DesktopPath: string;

// 현재 Ctrl 이 눌렸나 (키 이벤트 밖에서)
function CtrlDown: Boolean;

type
  // 창 프로시저 가로채기 콜백. AHandled=True 면 결과를 그대로 돌려주고 LCL 로 안 넘김.
  TWndHookEvent = function(AMsg: Cardinal; AW: PtrUInt; AL: PtrInt;
    var AHandled: Boolean): PtrInt of object;

// Win32 서브클래스로 창 메시지를 LCL 보다 먼저 본다. LCL win32 는 목록에 없는 메시지(WM_USER 미만, 예:
// WM_DEVICECHANGE)를 폼 message 메서드로 넘기지 않는다 (win32callback.inc: else → Msg >= WM_USER 만).
// 반환 객체를 Free 하면 해제. 비-Windows 는 nil (아무 일 없음).
function HookWindowMessages(AHandle: THandle; AEvent: TWndHookEvent): TObject;

// 가장자리 WM_NCLBUTTONDOWN(AHit = HTLEFT..HTBOTTOMRIGHT) → 크기 조절 루프. 끝나야 돌아온다.
// bsNone(WS_POPUP)은 WM_NCHITTEST 가 HTRIGHT 등을 줘도 WS_THICKFRAME 없으면 DefWindowProc 가 크기 조절 안 함
// (1.1.4.0 실측: 끌어도 그대로, 붙이면 됨). 상시로 켜 두면 안 됨 — LCL 폼 Width = 창 − AdjustWindowRectEx(현재 스타일)
// 이라 실제 창이 14px 커진다 (SetBounds·ResizeWindow 어긋남). 그래서 루프 동안만 켠다.
// 켜진 동안 테두리 안 보이게 창 쪽에서 WM_NCCALCSIZE(wParam≠0) → 0. 비-Windows 는 아무 일 없음.
procedure RunSizingLoop(AHandle: THandle; AHit: PtrUInt; APos: PtrInt);

implementation

uses
  {$IFDEF WINDOWS}Windows, ShlObj,{$ENDIF}
  LCLType, LCLIntf;

{$IFDEF WINDOWS}
const
  WM_COPYGLOBALDATA = $0049;
  MSGFLT_ALLOW = 1;

type
  // FPC windows 유닛에 W 판이 없다
  TNonClientMetricsW = record
    cbSize: UINT;
    iBorderWidth, iScrollWidth, iScrollHeight, iCaptionWidth, iCaptionHeight: Integer;
    lfCaptionFont: LOGFONTW;
    iSmCaptionWidth, iSmCaptionHeight: Integer;
    lfSmCaptionFont: LOGFONTW;
    iMenuWidth, iMenuHeight: Integer;
    lfMenuFont, lfStatusFont, lfMessageFont: LOGFONTW;
    iPaddedBorderWidth: Integer;
  end;
{$ENDIF}

procedure SetWindowTopMost(AForm: TCustomForm; AState: Boolean);
{$IFDEF WINDOWS}
const
  SWP_FLAGS = SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE;
var
  LAfter: HWND;
begin
  if (AForm = nil) or not AForm.HandleAllocated then Exit;
  if AState then
    LAfter := HWND_TOPMOST
  else
    LAfter := HWND_NOTOPMOST;
  Windows.SetWindowPos(AForm.Handle, LAfter, 0, 0, 0, 0, SWP_FLAGS);
end;
{$ELSE}
begin
  // TODO macOS: NSWindow level
end;
{$ENDIF}

function StartWindowDrag(AForm: TCustomForm): Boolean;
begin
  {$IFDEF WINDOWS}
  // LCL 의 Perform 은 LCL 메시지 경로라 Win32 이동 루프가 안 돈다 → 창 프로시저로 직접.
  Windows.ReleaseCapture;
  Windows.SendMessage(AForm.Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0);
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function UIFontName: string;
{$IFDEF WINDOWS}
var
  NCM: TNonClientMetricsW;
begin
  Result := '';
  FillChar(NCM, SizeOf(NCM), 0);
  NCM.cbSize := SizeOf(NCM);
  if SystemParametersInfoW(SPI_GETNONCLIENTMETRICS, SizeOf(NCM), @NCM, 0) then
    Result := UTF8Encode(UnicodeString(PWideChar(@NCM.lfMessageFont.lfFaceName[0])));
  if Result = '' then
    Result := 'Segoe UI';
end;
{$ELSE}
begin
  Result := 'sans-serif';
end;
{$ENDIF}

procedure AllowDropFromLowerIntegrity(AHandle: THandle);
{$IFDEF WINDOWS}
type
  TChangeWindowMessageFilterEx = function(hWnd: HWND; Msg: UINT; Action: DWORD;
    pChangeFilterStruct: Pointer): BOOL; stdcall;
var
  F: TChangeWindowMessageFilterEx;
begin
  F := TChangeWindowMessageFilterEx(GetProcAddress(GetModuleHandle('user32.dll'),
    'ChangeWindowMessageFilterEx'));
  if not Assigned(F) then Exit;
  F(AHandle, WM_DROPFILES, MSGFLT_ALLOW, nil);
  F(AHandle, WM_COPYDATA, MSGFLT_ALLOW, nil);
  F(AHandle, WM_COPYGLOBALDATA, MSGFLT_ALLOW, nil);
end;
{$ELSE}
begin
end;
{$ENDIF}

procedure SetDarkTitleBar(AHandle: THandle);
{$IFDEF WINDOWS}
type
  TDwmSetWindowAttribute = function(hwnd: HWND; dwAttribute: DWORD; pvAttribute: Pointer;
    cbAttribute: DWORD): HRESULT; stdcall;
var
  Lib: HMODULE;
  F: TDwmSetWindowAttribute;
  UseDark: BOOL;
begin
  Lib := LoadLibrary('dwmapi.dll');
  if Lib = 0 then Exit;
  try
    F := TDwmSetWindowAttribute(GetProcAddress(Lib, 'DwmSetWindowAttribute'));
    if Assigned(F) then
    begin
      UseDark := True;
      F(AHandle, 20, @UseDark, SizeOf(UseDark));   // DWMWA_USE_IMMERSIVE_DARK_MODE
    end;
  finally
    FreeLibrary(Lib);
  end;
end;
{$ELSE}
begin
end;
{$ENDIF}

// CSIDL_DESKTOPDIRECTORY 는 OneDrive 리디렉션·타 언어에서도 실제 경로 (USERPROFILE+'\Desktop' 조립은 그때 틀림).
function DesktopPath: string;
{$IFDEF WINDOWS}
var
  Buf: array[0..MAX_PATH] of WideChar;
begin
  FillChar(Buf, SizeOf(Buf), 0);
  if SHGetSpecialFolderPathW(0, @Buf[0], CSIDL_DESKTOPDIRECTORY, False) then
    Result := IncludeTrailingPathDelimiter(UTF8Encode(UnicodeString(PWideChar(@Buf[0]))))
  else
    Result := ExtractFilePath(ParamStr(0));
end;
{$ELSE}
begin
  Result := IncludeTrailingPathDelimiter(GetUserDir) + 'Desktop' + PathDelim;
  if not DirectoryExists(Result) then
    Result := IncludeTrailingPathDelimiter(GetUserDir);
end;
{$ENDIF}

function CtrlDown: Boolean;
begin
  Result := GetKeyState(VK_CONTROL) < 0;
end;

{$IFDEF WINDOWS}
type
  TSubclassProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM;
    uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;

function SetWindowSubclass(hWnd: HWND; pfnSubclass: TSubclassProc; uIdSubclass: UINT_PTR;
  dwRefData: DWORD_PTR): BOOL; stdcall; external 'comctl32.dll' name 'SetWindowSubclass';
function RemoveWindowSubclass(hWnd: HWND; pfnSubclass: TSubclassProc;
  uIdSubclass: UINT_PTR): BOOL; stdcall; external 'comctl32.dll' name 'RemoveWindowSubclass';
function DefSubclassProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
  stdcall; external 'comctl32.dll' name 'DefSubclassProc';

const
  HookSubclassID = $4B48;   // 'KH'

type
  TWinHook = class
  private
    FWnd: HWND;
    FEvent: TWndHookEvent;
    FHooked: Boolean;
  public
    destructor Destroy; override;
  end;

function HookProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM;
  uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;
var
  H: TWinHook;
  Handled: Boolean;
begin
  H := TWinHook(Pointer(dwRefData));
  if uMsg = WM_NCDESTROY then
  begin
    RemoveWindowSubclass(hWnd, @HookProc, HookSubclassID);
    H.FHooked := False;
  end
  else if Assigned(H.FEvent) then
  begin
    Handled := False;
    Result := H.FEvent(uMsg, wParam, lParam, Handled);
    if Handled then Exit;
  end;
  Result := DefSubclassProc(hWnd, uMsg, wParam, lParam);
end;

destructor TWinHook.Destroy;
begin
  if FHooked and IsWindow(FWnd) then
    RemoveWindowSubclass(FWnd, @HookProc, HookSubclassID);
  inherited;
end;

function HookWindowMessages(AHandle: THandle; AEvent: TWndHookEvent): TObject;
var
  H: TWinHook;
begin
  H := TWinHook.Create;
  H.FWnd := AHandle;
  H.FEvent := AEvent;
  H.FHooked := SetWindowSubclass(AHandle, @HookProc, HookSubclassID, DWORD_PTR(H));
  Result := H;
end;

procedure SetSizingFrame(AHandle: THandle; AOn: Boolean);
var
  S, N: LONG_PTR;
begin
  S := GetWindowLongPtrW(AHandle, GWL_STYLE);
  if AOn then N := S or WS_THICKFRAME else N := S and not WS_THICKFRAME;
  if N = S then Exit;
  SetWindowLongPtrW(AHandle, GWL_STYLE, N);
  SetWindowPos(AHandle, 0, 0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);
end;

procedure RunSizingLoop(AHandle: THandle; AHit: PtrUInt; APos: PtrInt);
begin
  SetSizingFrame(AHandle, True);
  try
    DefWindowProcW(AHandle, WM_NCLBUTTONDOWN, AHit, APos);   // → SC_SIZE 모달 루프
  finally
    SetSizingFrame(AHandle, False);
  end;
end;
{$ELSE}
function HookWindowMessages(AHandle: THandle; AEvent: TWndHookEvent): TObject;
begin
  Result := nil;
end;

procedure RunSizingLoop(AHandle: THandle; AHit: PtrUInt; APos: PtrInt);
begin
end;
{$ENDIF}

end.
