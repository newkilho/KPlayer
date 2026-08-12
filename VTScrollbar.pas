unit VTScrollbar;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.CommCtrl,
  System.Classes,
  System.Math,
  System.Types,
  Vcl.Graphics,
  VirtualTrees;

type
  TVTDarkScrollbar = class
  private
    const
      CTimerID = $53B1;
  private
    FTree   : TVirtualStringTree;
    FOldWnd : TWndMethod;
    FBarW   : Integer;

    FClrTrack : TColor;
    FClrThumb : TColor;
    FClrDrag  : TColor;

    FVisible  : Boolean;   // 바 표시 중
    FHot      : Boolean;   // 트랙 호버 → 6px
    FDragging : Boolean;
    FDragScrY : Integer;
    FDragPos0 : Integer;
    FTimerOn  : Boolean;

    procedure TreeWndProc(var M: TMessage);
    procedure PaintOverlay;
    procedure BarShow;
    procedure BarHide;
    procedure InvalidateStrip;
    procedure StartHideTimer;
    procedure StopHideTimer;
    procedure RequestMouseLeave;

    function TrackR: TRect;
    function VisualTrackR: TRect;
    function ThumbR: TRect;
    function CurPos: Integer;
    function MaxScrollPos: Integer;
    procedure ScrollTo(NewPos: Integer);

  public
    constructor Create(ATree: TVirtualStringTree);
    destructor Destroy; override;

    property BarWidth: Integer read FBarW write FBarW;
  end;

implementation

type
  TVTAccess = class(TVirtualStringTree);

{ ================= Constructor / Destructor ================= }

constructor TVTDarkScrollbar.Create(ATree: TVirtualStringTree);
begin
  inherited Create;

  FTree := ATree;
  FBarW := 10; // 잡기 영역 폭 — 보이는 굵기(VisualTrackR)와 별개

  FClrTrack := $00242424;
  FClrThumb := $00606060;
  FClrDrag  := $00B0B0B0;

  FOldWnd := ATree.WindowProc;
  ATree.WindowProc := TreeWndProc;
end;

destructor TVTDarkScrollbar.Destroy;
begin
  if Assigned(FTree) then
  begin
    StopHideTimer;
    FTree.WindowProc := FOldWnd;
  end;
  inherited;
end;

{ ================= Layout ================= }

function TVTDarkScrollbar.TrackR: TRect;
begin
  Result := Rect(
    FTree.ClientWidth - FBarW,
    0,
    FTree.ClientWidth,
    FTree.ClientHeight
  );
end;

// 보이는 띠 — 평소 2px, 호버·드래그 6px.
function TVTDarkScrollbar.VisualTrackR: TRect;
var
  W: Integer;
begin
  Result := TrackR;
  if FDragging or FHot then
    W := 6
  else
    W := 2;

  if W > Result.Width then
    W := Result.Width;

  Result.Left := Result.Left + (Result.Width - W) div 2;
  Result.Right := Result.Left + W;
end;

function TVTDarkScrollbar.CurPos: Integer;
begin
  Result := -FTree.OffsetY;
end;

function TVTDarkScrollbar.MaxScrollPos: Integer;
begin
  Result :=
    Max(0,
      TVTAccess(FTree).RangeY -
      FTree.ClientHeight);
end;

procedure TVTDarkScrollbar.ScrollTo(NewPos: Integer);
begin
  FTree.OffsetY :=
    -Max(0, Min(NewPos, MaxScrollPos));

  // BarShow = 띠 무효화 + UpdateWindow → 밀린 본문·바 일괄 정리
  BarShow;
end;

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
    Exit(TRect.Empty);

  Track  := TrackR;
  TrackH := Track.Height;

  ThLen :=
    Max(20,
      MulDiv(TrackH, View, Total));

  ThOfs :=
    MulDiv(
      CurPos,
      TrackH - ThLen,
      Max(1, Total - View)
    );

  Result :=
    Rect(
      Track.Left,
      Track.Top + ThOfs,
      Track.Right,
      Track.Top + ThOfs + ThLen
    );

  InflateRect(Result, -2, -2);
end;

{ ================= Show / Hide ================= }

procedure TVTDarkScrollbar.BarShow;
begin
  FVisible := True;
  StartHideTimer;   // 잠잠→숨김, 재호출 = 시계 리셋

  // PaintOverlay 직접 호출 금지: 화면을 떠 와 합성하므로 ScrollWindow 로 밀린
  // 화면의 이전 바 잔상까지 판에 떠 안 지워짐. 띠 무효화→UpdateWindow→WM_PAINT
  // 로 트리가 되살린 깨끗한 판 위에 훅이 바를 얹는다.
  InvalidateStrip;
  UpdateWindow(FTree.Handle);
end;

// 본문이 밑까지 그려져 배경칠로 못 지움 — 무효화로 재그리기.
procedure TVTDarkScrollbar.BarHide;
begin
  FVisible := False;
  StopHideTimer;
  InvalidateStrip;
end;

procedure TVTDarkScrollbar.InvalidateStrip;
var
  R: TRect;
begin
  R := TrackR;
  InvalidateRect(FTree.Handle, @R, False);
end;

procedure TVTDarkScrollbar.StartHideTimer;
begin
  // 같은 ID SetTimer 재호출 = 시간 리셋
  SetTimer(FTree.Handle, CTimerID, 900, nil);
  FTimerOn := True;
end;

procedure TVTDarkScrollbar.StopHideTimer;
begin
  if not FTimerOn then
    Exit;
  KillTimer(FTree.Handle, CTimerID);
  FTimerOn := False;
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

{ ================= Painting ================= }

procedure TVTDarkScrollbar.PaintOverlay;
var
  DC, MemDC: HDC;
  Bmp: HBITMAP;
  OldBmp: HGDIOBJ;
  Strip: TRect;
  Thumb, VTrack, VThumb: TRect;
  Br: HBRUSH;
  OldPen, OldBr: HGDIOBJ;
begin
  if not FVisible then
    Exit;

  Strip := TrackR;
  if (Strip.Width <= 0) or (Strip.Height <= 0) then
    Exit;

  // 스크롤 대상 없음(목록 축소) → 바 숨김
  if MaxScrollPos <= 0 then
  begin
    BarHide;
    Exit;
  end;

  DC := GetDC(FTree.Handle);
  if DC = 0 then Exit;

  try
    MemDC := CreateCompatibleDC(DC);
    Bmp := CreateCompatibleBitmap(DC, Strip.Width, Strip.Height);
    OldBmp := SelectObject(MemDC, Bmp);
    try
      // 화면을 떠 와 그 위에 그림 — 띠 밑 본문 보존
      BitBlt(MemDC, 0, 0, Strip.Width, Strip.Height,
        DC, Strip.Left, Strip.Top, SRCCOPY);

      // 이하 비트맵 좌표 — 띠 원점만큼 이동
      VTrack := VisualTrackR;
      OffsetRect(VTrack, -Strip.Left, -Strip.Top);
      Thumb := ThumbR;
      OffsetRect(Thumb, -Strip.Left, -Strip.Top);
      VThumb := Thumb;
      VThumb.Left := VTrack.Left;
      VThumb.Right := VTrack.Right;

      Br := CreateSolidBrush(ColorToRGB(FClrTrack));
      FillRect(MemDC, VTrack, Br);
      DeleteObject(Br);

      if not Thumb.IsEmpty then
      begin
        // 호버는 굵기만 6px, 색은 드래그 중에만 밝게.
        if FDragging then
          Br := CreateSolidBrush(ColorToRGB(FClrDrag))
        else
          Br := CreateSolidBrush(ColorToRGB(FClrThumb));

        OldPen := SelectObject(MemDC, GetStockObject(NULL_PEN));
        OldBr  := SelectObject(MemDC, Br);

        // NULL_PEN: 우·하 경계 1px 미채움 — +1 보정해야 2px 가 실제 2px.
        RoundRect(
          MemDC,
          VThumb.Left,
          VThumb.Top,
          VThumb.Right + 1,
          VThumb.Bottom + 1,
          Min(VThumb.Width, 8),
          Min(VThumb.Width, 8)
        );

        SelectObject(MemDC, OldPen);
        SelectObject(MemDC, OldBr);
        DeleteObject(Br);
      end;

      BitBlt(DC, Strip.Left, Strip.Top, Strip.Width, Strip.Height,
        MemDC, 0, 0, SRCCOPY);
    finally
      SelectObject(MemDC, OldBmp);
      DeleteObject(Bmp);
      DeleteDC(MemDC);
    end;
  finally
    ReleaseDC(FTree.Handle, DC);
  end;
end;

{ ================= WndProc ================= }

procedure TVTDarkScrollbar.TreeWndProc(var M: TMessage);
var
  X, Y: Integer;
  CursorPos: TPoint;
  TrackH, ThLen, NewPos, PrevPos: Integer;
  ThR: TRect;
  WasHot: Boolean;
begin
  case M.Msg of

    WM_ERASEBKGND:
      begin
        M.Result := 1;
        Exit;
      end;

    WM_PAINT:
      begin
        // 바 표시 중엔 바 기둥을 업데이트 영역에서 제외(ValidateRect). 안 빼면
        // 트리 지움→바 재얹기 두 번 쓰기 → 잦은 재그리기(드래그)에서 깜빡임.
        // 기둥 잔상은 PaintOverlay 가 전체 높이 덮음, 기둥 밖은 트리가 되살림.
        if FVisible and (MaxScrollPos > 0) then
        begin
          ThR := VisualTrackR;
          ValidateRect(FTree.Handle, @ThR);
        end;

        FOldWnd(M);
        PaintOverlay;   // 본문 재그리기 때 바 재얹기
        Exit;
      end;

    // 트리가 스스로 처리. 실제 밀렸을 때만 바 표시(커서 이동 등 화면 안
    // 움직이는 키는 제외).
    WM_MOUSEWHEEL, WM_VSCROLL, WM_KEYDOWN:
      begin
        PrevPos := CurPos;
        FOldWnd(M);
        if CurPos <> PrevPos then
          BarShow
        else if FVisible then
          PaintOverlay;   // 안 밀려도 재그려진 본문 위에 재얹기
        Exit;
      end;

    WM_LBUTTONDOWN:
      begin
        X := SmallInt(LoWord(M.LParam));
        Y := SmallInt(HiWord(M.LParam));

        if PtInRect(TrackR, Point(X, Y)) and (MaxScrollPos > 0) then
        begin
          ThR := ThumbR;

          if PtInRect(ThR, Point(X, Y)) then
          begin
            FDragging := True;
            GetCursorPos(CursorPos);
            FDragScrY := CursorPos.Y;
            FDragPos0 := CurPos;
            SetCapture(FTree.Handle);
            BarShow;   // 드래그 색·6px 로
          end
          else
          begin
            if Y < ThR.Top then
              ScrollTo(CurPos - FTree.ClientHeight)
            else
              ScrollTo(CurPos + FTree.ClientHeight);
          end;

          M.Result := 0;
          Exit;
        end;

        FOldWnd(M);
        Exit;
      end;

    WM_MOUSEMOVE:
      begin
        X := SmallInt(LoWord(M.LParam));
        Y := SmallInt(HiWord(M.LParam));

        if FDragging then
        begin
          GetCursorPos(CursorPos);

          TrackH := TrackR.Height;
          ThLen := Max(20,
            MulDiv(TrackH,
              FTree.ClientHeight,
              MaxScrollPos + FTree.ClientHeight));

          NewPos :=
            FDragPos0 +
            MulDiv(
              CursorPos.Y - FDragScrY,
              MaxScrollPos,
              Max(1, TrackH - ThLen)
            );

          ScrollTo(NewPos);
          Exit;
        end;

        // 호버는 트랙 안/밖 전환 순간만(2px↔6px). 굵기 변화 → 이전 폭 흔적을
        // 트리가 지운 뒤 재얹기.
        WasHot := FHot;
        FHot := PtInRect(TrackR, Point(X, Y)) and (MaxScrollPos > 0);

        if FHot <> WasHot then
        begin
          if FHot then
          begin
            RequestMouseLeave;   // 트랙 이탈 시 WM_MOUSELEAVE 수신용
            FVisible := True;
          end;
          StartHideTimer;
          InvalidateStrip;
        end;

        FOldWnd(M);
        Exit;
      end;

    WM_LBUTTONUP:
      begin
        if FDragging then
        begin
          FDragging := False;
          ReleaseCapture;
          BarShow;   // 보통 색 복귀 + 숨김 시계 재시작
          Exit;
        end;

        FOldWnd(M);
        Exit;
      end;

    WM_MOUSELEAVE:
      begin
        if FHot then
        begin
          FHot := False;
          StartHideTimer;
          InvalidateStrip;   // 6px → 2px
        end;
        Exit;
      end;

    // 잠잠 → 즉시 숨김(페이드 없음). 호버·드래그 중이면 연기.
    WM_TIMER:
      begin
        if M.WParam = CTimerID then
        begin
          if FHot or FDragging then
            Exit;   // 시계 유지 — 다음 틱 재판정

          BarHide;
          Exit;
        end;
      end;

  end;

  FOldWnd(M);
end;

end.
