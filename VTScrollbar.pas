unit VTScrollbar;

// 재생목록 트리의 어두운 오버레이 스크롤바 (평소 2px, 호버·드래그 6px, 잠잠하면 숨김).
// 비-Windows: 아무것도 안 함 — 호출부(List)가 트리 기본 스크롤바를 켠다 (macOS 는 기본이 오버레이 스크롤바).
//
// 구조 (1.1.0.0 재작성 — 스크롤 때 바 떨림 해결):
// - 바 = 트리의 **형제 창**(폼의 자식, 트리 위 Z순서). 트리 DC 에 직접 그리면 laz VT 의 DoSetOffsetXY 가
//   ScrollWindowEx 로 클라이언트 전체(바 포함)를 밀어 다음 WM_PAINT 까지 바가 반대로 튄다 → 드래그·휠 때 떨림.
//   형제 창 + 트리 WS_CLIPSIBLINGS 면 밀기·그리기가 바 영역을 비켜 간다 (LCL 은 WS_CLIPSIBLINGS 를 안 준다).
// - 바 창은 WM_NCHITTEST = HTTRANSPARENT — 마우스는 밑의 트리로. 입력은 트리 Win32 서브클래스(SetWindowSubclass)가
//   받는다 (잡기 영역 10px = 보이는 굵기와 별개). LCL WindowProc 는 SetTimer/WM_MOUSELEAVE 를 먼저 먹어 서브클래스.
// - 위치 동기화: 오프셋은 휠·키·드래그 말고도 바뀐다 (재생 중 항목 보이기, 끌기 자동 스크롤, 항목 추가/삭제 → RangeY).
//   어떤 변화든 트리 WM_PAINT 가 뒤따르므로 거기서 (위치, 범위, 높이) 를 비교해 바를 다시 그린다.

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Types, Math, Graphics, laz.VirtualTrees
  {$IFDEF WINDOWS}, Windows, Messages{$ENDIF};

type
  TVTDarkScrollbar = class
  private
    const
      CTimerID = $53B1;
      CSubclassID = $4B50;   // 'KP'
      CHideMS = 900;
  private
    FTree   : TLazVirtualStringTree;
    FBarW   : Integer;       // 잡기 영역 폭 (트리 오른쪽 끝)

    FClrTrack : TColor;
    FClrThumb : TColor;
    FClrDrag  : TColor;

    FVisible  : Boolean;     // 표시 요청 (타이머가 끔)
    FHot      : Boolean;     // 트랙 호버 → 6px
    FDragging : Boolean;
    FDragScrY : Integer;
    FDragPos0 : Integer;
    FHooked   : Boolean;

    {$IFDEF WINDOWS}
    FBar      : HWND;        // 바 창 (트리의 형제)
    FShown    : Boolean;     // 바 창이 실제로 보이는가
    FBarRect  : TRect;       // 바 창 위치 (부모 클라이언트 좌표)
    // 마지막으로 그린 상태 — WM_PAINT 에서 바뀌었는지 비교
    FLastPos, FLastMax, FLastH: Integer;

    function TreeWndProc(AWnd: HWND; AMsg: UINT; AW: WPARAM; AL: LPARAM): LRESULT;
    function BarWndProc(AWnd: HWND; AMsg: UINT; AW: WPARAM; AL: LPARAM): LRESULT;
    procedure CreateBarWindow;
    procedure PaintBar(DC: HDC);

    procedure BarShow;
    procedure BarHide;
    procedure UpdateBar;     // 표시 여부·위치·굵기 반영 + 즉시 다시 그리기
    procedure SyncIfChanged;
    procedure RequestMouseLeave;

    function TrackR: TRect;
    function VisualTrackR: TRect;
    function ThumbR: TRect;
    function CurPos: Integer;
    function MaxScrollPos: Integer;
    procedure ScrollTo(NewPos: Integer);
    {$ENDIF}
  public
    constructor Create(ATree: TLazVirtualStringTree);
    destructor Destroy; override;

    property BarWidth: Integer read FBarW write FBarW;
  end;

// 이 OS 에서 오버레이 스크롤바가 동작하는가 (False 면 호출부가 기본 스크롤바를 쓴다)
function DarkScrollbarSupported: Boolean;

implementation

function DarkScrollbarSupported: Boolean;
begin
  {$IFDEF WINDOWS}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

{$IFDEF WINDOWS}

const
  CBarClass = 'KPlayerVTBar';

type
  // RangeY 는 protected — 같은 유닛의 파생 형변환으로 접근
  TVTAccess = class(TLazVirtualStringTree);

  TSubclassProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM;
    uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;

function SetWindowSubclass(hWnd: HWND; pfnSubclass: TSubclassProc; uIdSubclass: UINT_PTR;
  dwRefData: DWORD_PTR): BOOL; stdcall; external 'comctl32.dll' name 'SetWindowSubclass';
function RemoveWindowSubclass(hWnd: HWND; pfnSubclass: TSubclassProc;
  uIdSubclass: UINT_PTR): BOOL; stdcall; external 'comctl32.dll' name 'RemoveWindowSubclass';
function DefSubclassProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
  stdcall; external 'comctl32.dll' name 'DefSubclassProc';

function SubclassProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM;
  uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;
begin
  Result := TVTDarkScrollbar(Pointer(dwRefData)).TreeWndProc(hWnd, uMsg, wParam, lParam);
end;

// 바 창 프로시저 — 인스턴스는 GWLP_USERDATA (WM_NCCREATE 의 lpCreateParams 로 받음. FPC 에 PCreateStructW 없음 — lpCreateParams 위치는 A/W 같다)
function BarProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  Obj: TVTDarkScrollbar;
begin
  if uMsg = WM_NCCREATE then
    SetWindowLongPtrW(hWnd, GWLP_USERDATA, LONG_PTR(PCreateStruct(lParam)^.lpCreateParams));
  Obj := TVTDarkScrollbar(Pointer(GetWindowLongPtrW(hWnd, GWLP_USERDATA)));
  if Assigned(Obj) then
    Result := Obj.BarWndProc(hWnd, uMsg, wParam, lParam)
  else
    Result := DefWindowProcW(hWnd, uMsg, wParam, lParam);
end;

var
  BarClassDone: Boolean = False;

procedure RegisterBarClass;
var
  WC: TWndClassW;
begin
  if BarClassDone then Exit;
  FillChar(WC, SizeOf(WC), 0);
  WC.lpfnWndProc := @BarProc;
  WC.hInstance := HInstance;
  WC.hCursor := LoadCursor(0, IDC_ARROW);
  WC.lpszClassName := CBarClass;
  BarClassDone := Windows.RegisterClassW(WC) <> 0;
end;

{$ENDIF}

{ ================= Constructor / Destructor ================= }

constructor TVTDarkScrollbar.Create(ATree: TLazVirtualStringTree);
begin
  inherited Create;

  FTree := ATree;
  FBarW := 10; // 잡기 영역 폭 — 보이는 굵기(VisualTrackR)와 별개

  FClrTrack := $00242424;
  FClrThumb := $00606060;
  FClrDrag  := $00B0B0B0;

  {$IFDEF WINDOWS}
  // 트리 핸들이 다시 만들어지면 서브클래스·스타일도 사라진다 — 목록 창은 한 번 만들어 계속 쓰므로 생성 시 1회로 충분.
  SetWindowLongPtrW(FTree.Handle, GWL_STYLE,
    GetWindowLongPtrW(FTree.Handle, GWL_STYLE) or WS_CLIPSIBLINGS);
  CreateBarWindow;
  FHooked := SetWindowSubclass(FTree.Handle, @SubclassProc, CSubclassID, DWORD_PTR(Self));
  {$ENDIF}
end;

destructor TVTDarkScrollbar.Destroy;
begin
  {$IFDEF WINDOWS}
  if FHooked and Assigned(FTree) and FTree.HandleAllocated then
    RemoveWindowSubclass(FTree.Handle, @SubclassProc, CSubclassID);
  if (FBar <> 0) and IsWindow(FBar) then
  begin
    KillTimer(FBar, CTimerID);
    SetWindowLongPtrW(FBar, GWLP_USERDATA, 0);
    DestroyWindow(FBar);
  end;
  FBar := 0;
  {$ENDIF}
  inherited;
end;

{$IFDEF WINDOWS}

procedure TVTDarkScrollbar.CreateBarWindow;
begin
  RegisterBarClass;
  // WS_EX_NOACTIVATE: 클릭이 통과하지만 혹시라도 활성화를 뺏지 않게. 처음엔 숨김.
  FBar := CreateWindowExW(WS_EX_NOACTIVATE, CBarClass, nil,
    WS_CHILD or WS_CLIPSIBLINGS, 0, 0, 0, 0,
    FTree.Parent.Handle, 0, HInstance, Self);
end;

{ ================= Layout (트리 클라이언트 좌표) ================= }

function TVTDarkScrollbar.TrackR: TRect;
begin
  Result := Types.Rect(FTree.ClientWidth - FBarW, 0, FTree.ClientWidth, FTree.ClientHeight);
end;

// 보이는 띠 — 평소 2px, 호버·드래그 6px, 잡기 영역 가운데.
function TVTDarkScrollbar.VisualTrackR: TRect;
var
  W, TW: Integer;
begin
  Result := TrackR;
  if FDragging or FHot then
    W := 6
  else
    W := 2;

  TW := Result.Right - Result.Left;
  if W > TW then
    W := TW;

  Result.Left := Result.Left + (TW - W) div 2;
  Result.Right := Result.Left + W;
end;

function TVTDarkScrollbar.CurPos: Integer;
begin
  Result := -FTree.OffsetY;
end;

function TVTDarkScrollbar.MaxScrollPos: Integer;
begin
  Result := Max(0, Integer(TVTAccess(FTree).RangeY) - FTree.ClientHeight);
end;

procedure TVTDarkScrollbar.ScrollTo(NewPos: Integer);
begin
  FTree.OffsetY := -Max(0, Min(NewPos, MaxScrollPos));
  // 본문 먼저 — 그 WM_PAINT 의 SyncIfChanged 가 바도 옮긴다. BarShow 는 표시·시계 리셋.
  UpdateWindow(FTree.Handle);
  BarShow;
end;

// 엄지 — 트랙 전체 높이 기준 (트리 클라이언트 좌표, 가로는 잡기 영역 전체)
function TVTDarkScrollbar.ThumbR: TRect;
var
  Track  : TRect;
  View   : Integer;
  TrackH : Integer;
  ThLen  : Integer;
  ThOfs  : Integer;
  Total  : Integer;
begin
  View := FTree.ClientHeight;
  Total := MaxScrollPos + View;

  if Total <= View then
    Exit(Types.Rect(0, 0, 0, 0));

  Track  := TrackR;
  TrackH := Track.Bottom - Track.Top;

  ThLen := Max(20, MulDiv(TrackH, View, Total));
  ThOfs := MulDiv(CurPos, TrackH - ThLen, Max(1, Total - View));

  Result := Types.Rect(Track.Left, Track.Top + ThOfs, Track.Right, Track.Top + ThOfs + ThLen);
  InflateRect(Result, -2, -2);
end;

{ ================= Show / Hide ================= }

procedure TVTDarkScrollbar.BarShow;
begin
  FVisible := True;
  SetTimer(FBar, CTimerID, CHideMS, nil);   // 같은 ID 재호출 = 시계 리셋
  UpdateBar;
end;

procedure TVTDarkScrollbar.BarHide;
begin
  FVisible := False;
  KillTimer(FBar, CTimerID);
  UpdateBar;
end;

// 바 창을 현재 상태에 맞춘다. 위치·크기가 같으면 SetWindowPos 생략 (불필요한 트리 노출 무효화 방지).
// 숨길 때·가늘어질 때 드러나는 트리 영역은 Windows 가 트리에 무효화를 준다.
procedure TVTDarkScrollbar.UpdateBar;
var
  Want: Boolean;
  R: TRect;
begin
  if FBar = 0 then Exit;

  Want := FVisible and (MaxScrollPos > 0) and FTree.HandleAllocated and IsWindowVisible(FTree.Handle);

  FLastPos := CurPos;
  FLastMax := MaxScrollPos;
  FLastH   := FTree.ClientHeight;

  if not Want then
  begin
    if FShown then
    begin
      ShowWindow(FBar, SW_HIDE);
      FShown := False;
    end;
    Exit;
  end;

  R := VisualTrackR;
  MapWindowPoints(FTree.Handle, GetParent(FBar), R, 2);

  if not FShown or not EqualRect(R, FBarRect) then
  begin
    FBarRect := R;
    SetWindowPos(FBar, HWND_TOP, R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top,
      SWP_NOACTIVATE or SWP_SHOWWINDOW);
    FShown := True;
  end;

  InvalidateRect(FBar, nil, False);
  UpdateWindow(FBar);
end;

// 트리가 다시 그려질 때 — 오프셋·범위·높이가 바뀌었으면 바를 옮긴다 (표시 중일 때만. 프로그램 스크롤로 바를 켜지는 않음).
procedure TVTDarkScrollbar.SyncIfChanged;
begin
  if (CurPos <> FLastPos) or (MaxScrollPos <> FLastMax) or (FTree.ClientHeight <> FLastH) then
    UpdateBar;
end;

procedure TVTDarkScrollbar.RequestMouseLeave;
var
  TME: TTrackMouseEvent;
begin
  TME.cbSize := SizeOf(TME);
  TME.dwFlags := TME_LEAVE;
  TME.hwndTrack := FTree.Handle;
  TME.dwHoverTime := 0;
  TrackMouseEvent(TME);
end;

{ ================= Painting (바 창) ================= }

// 바 창 전체 = VisualTrackR. 메모리 DC 에 트랙+엄지를 그려 한 번에 BitBlt (창 안 깜빡임 없음).
procedure TVTDarkScrollbar.PaintBar(DC: HDC);
var
  MemDC: HDC;
  Bmp: HBITMAP;
  OldBmp, OldPen, OldBr: HGDIOBJ;
  CR, Thumb, VTrack: TRect;
  W, H: Integer;
  Br: HBRUSH;
begin
  GetClientRect(FBar, CR);
  W := CR.Right;
  H := CR.Bottom;
  if (W <= 0) or (H <= 0) then Exit;

  MemDC := CreateCompatibleDC(DC);
  Bmp := CreateCompatibleBitmap(DC, W, H);
  OldBmp := SelectObject(MemDC, Bmp);
  try
    Br := CreateSolidBrush(ColorToRGB(FClrTrack));
    FillRect(MemDC, CR, Br);
    DeleteObject(Br);

    // 엄지: 세로는 트리 좌표 → 바 창 좌표 (바 창 Top = 트랙 Top), 가로는 바 창 전체
    VTrack := VisualTrackR;
    Thumb := ThumbR;
    if not IsRectEmpty(Thumb) then
    begin
      Thumb := Types.Rect(0, Thumb.Top - VTrack.Top, W, Thumb.Bottom - VTrack.Top);

      // 호버는 굵기만 6px, 색은 드래그 중에만 밝게.
      if FDragging then
        Br := CreateSolidBrush(ColorToRGB(FClrDrag))
      else
        Br := CreateSolidBrush(ColorToRGB(FClrThumb));

      OldPen := SelectObject(MemDC, GetStockObject(NULL_PEN));
      OldBr  := SelectObject(MemDC, Br);
      // NULL_PEN: 우·하 경계 1px 미채움 — +1 보정해야 2px 가 실제 2px.
      RoundRect(MemDC, Thumb.Left, Thumb.Top, Thumb.Right + 1, Thumb.Bottom + 1, Min(W, 8), Min(W, 8));
      SelectObject(MemDC, OldPen);
      SelectObject(MemDC, OldBr);
      DeleteObject(Br);
    end;

    BitBlt(DC, 0, 0, W, H, MemDC, 0, 0, SRCCOPY);
  finally
    SelectObject(MemDC, OldBmp);
    DeleteObject(Bmp);
    DeleteDC(MemDC);
  end;
end;

function TVTDarkScrollbar.BarWndProc(AWnd: HWND; AMsg: UINT; AW: WPARAM; AL: LPARAM): LRESULT;
var
  PS: TPaintStruct;
  DC: HDC;
begin
  case AMsg of
    // 마우스는 밑의 트리로 (같은 스레드 창이라 HTTRANSPARENT 가 통한다)
    WM_NCHITTEST:
      Exit(HTTRANSPARENT);

    WM_ERASEBKGND:
      Exit(1);

    WM_PAINT:
      begin
        DC := BeginPaint(AWnd, PS);
        try
          PaintBar(DC);
        finally
          EndPaint(AWnd, PS);
        end;
        Exit(0);
      end;

    // 잠잠 → 즉시 숨김(페이드 없음). 호버·드래그 중이면 연기.
    WM_TIMER:
      if AW = CTimerID then
      begin
        if not (FHot or FDragging) then
          BarHide;
        Exit(0);
      end;
  end;

  Result := DefWindowProcW(AWnd, AMsg, AW, AL);
end;

{ ================= 트리 서브클래스 ================= }

function TVTDarkScrollbar.TreeWndProc(AWnd: HWND; AMsg: UINT; AW: WPARAM; AL: LPARAM): LRESULT;
var
  X, Y: Integer;
  CursorPos: TPoint;
  TrackH, ThLen, NewPos, PrevPos: Integer;
  ThR: TRect;
  WasHot: Boolean;
begin
  case AMsg of

    // 스크롤·항목 변화는 모두 여기로 온다 → 바 위치 동기화
    WM_PAINT:
      begin
        Result := DefSubclassProc(AWnd, AMsg, AW, AL);
        if FShown then
          SyncIfChanged;
        Exit;
      end;

    WM_SIZE, WM_MOVE, WM_WINDOWPOSCHANGED:
      begin
        Result := DefSubclassProc(AWnd, AMsg, AW, AL);
        if FShown or FVisible then
          UpdateBar;
        Exit;
      end;

    WM_SHOWWINDOW:
      begin
        Result := DefSubclassProc(AWnd, AMsg, AW, AL);
        if AW = 0 then
          BarHide;
        Exit;
      end;

    // 트리가 스스로 처리. 실제 밀렸을 때만 바 표시 (커서 이동 등 화면 안 움직이는 키는 제외).
    WM_MOUSEWHEEL, WM_VSCROLL, WM_KEYDOWN:
      begin
        PrevPos := CurPos;
        Result := DefSubclassProc(AWnd, AMsg, AW, AL);
        if CurPos <> PrevPos then
        begin
          UpdateWindow(AWnd);   // 본문과 바를 같은 차례에 — 바만 먼저 가면 어긋나 보인다
          BarShow;
        end;
        Exit;
      end;

    WM_LBUTTONDOWN:
      begin
        X := SmallInt(LoWord(DWORD(AL)));
        Y := SmallInt(HiWord(DWORD(AL)));

        if PtInRect(TrackR, Types.Point(X, Y)) and (MaxScrollPos > 0) then
        begin
          ThR := ThumbR;
          InflateRect(ThR, 0, 2);   // ThumbR 의 -2 여백까지 잡기

          if PtInRect(ThR, Types.Point(X, Y)) then
          begin
            FDragging := True;
            GetCursorPos(CursorPos);
            FDragScrY := CursorPos.Y;
            FDragPos0 := CurPos;
            SetCapture(AWnd);
            BarShow;   // 드래그 색·6px 로
          end
          else if Y < ThR.Top then
            ScrollTo(CurPos - FTree.ClientHeight)
          else
            ScrollTo(CurPos + FTree.ClientHeight);

          Exit(0);
        end;

        Exit(DefSubclassProc(AWnd, AMsg, AW, AL));
      end;

    WM_MOUSEMOVE:
      begin
        X := SmallInt(LoWord(DWORD(AL)));
        Y := SmallInt(HiWord(DWORD(AL)));

        if FDragging then
        begin
          GetCursorPos(CursorPos);

          TrackH := TrackR.Bottom - TrackR.Top;
          ThLen := Max(20, MulDiv(TrackH, FTree.ClientHeight, MaxScrollPos + FTree.ClientHeight));

          NewPos := FDragPos0 +
            MulDiv(CursorPos.Y - FDragScrY, MaxScrollPos, Max(1, TrackH - ThLen));

          if NewPos <> CurPos then
            ScrollTo(NewPos);
          Exit(0);
        end;

        // 호버는 트랙 안/밖 전환 순간만 (2px↔6px)
        WasHot := FHot;
        FHot := PtInRect(TrackR, Types.Point(X, Y)) and (MaxScrollPos > 0);

        if FHot <> WasHot then
        begin
          if FHot then
            RequestMouseLeave;   // 트랙 이탈 시 WM_MOUSELEAVE 수신용
          BarShow;
        end;

        Exit(DefSubclassProc(AWnd, AMsg, AW, AL));
      end;

    WM_LBUTTONUP, WM_CAPTURECHANGED:
      begin
        if FDragging then
        begin
          FDragging := False;
          if AMsg = WM_LBUTTONUP then
            ReleaseCapture;
          BarShow;   // 보통 색 복귀 + 숨김 시계 재시작
          if AMsg = WM_LBUTTONUP then
            Exit(0);
        end;

        Exit(DefSubclassProc(AWnd, AMsg, AW, AL));
      end;

    // LCL 도 자체 TrackMouseEvent 로 이 메시지를 쓴다 → 처리 후 넘긴다.
    WM_MOUSELEAVE:
      begin
        if FHot and not FDragging then
        begin
          FHot := False;
          BarShow;   // 6px → 2px, 숨김 시계 재시작
        end;
        Exit(DefSubclassProc(AWnd, AMsg, AW, AL));
      end;

    WM_NCDESTROY:
      begin
        RemoveWindowSubclass(AWnd, @SubclassProc, CSubclassID);
        FHooked := False;
      end;

  end;

  Result := DefSubclassProc(AWnd, AMsg, AW, AL);
end;

{$ENDIF}

end.
