unit VTScrollbar;

{
  재생목록 트리용 오버레이 스크롤바.

  ── 표시 규칙: 이벤트로만, 즉시 전환 ──────────────────────────
  · 평소에는 보이지 않는다
  · 스크롤이 일어나면 2px 로 나타난다
  · 트랙에 마우스를 올리면 6px (잡기 쉽게)
  · 잠잠해지면(900ms) 사라진다 — 호버·드래그 중에는 사라지지 않는다

  처음 판은 페이드였다 — 15ms 틱마다 불투명도를 올렸다 내렸다 하며
  배경과 섞어 그렸는데, 그 중간 단계가 색이 변하며 깜빡이는 것처럼
  보였다 (Nemo 의 메모 스크롤바에서 먼저 드러나 그쪽을 이 구조로
  고쳤고, 여기도 맞춘 것이다). 지금은 '잠잠해졌나' 를 보는 일회성
  타이머 하나만 남고, 나타나고 사라지는 것은 전부 즉시 전환이다.

  그리기는 띠(TrackR)를 화면에서 떠 와 메모리 비트맵에 합성한 뒤
  BitBlt 한 방으로 되돌린다 — 화면 DC 에 트랙·썸을 차례로 그리면
  그 중간 과정이 떨림으로 보인다. 트리 본문이 띠 밑까지 그려지므로
  (에디트처럼 여백을 잡을 수 없다) 배경을 칠하는 대신 화면을 뜬다.
  같은 이유로 바를 지울 때는 띠를 무효화해 트리가 제 내용을 다시
  그리게 한다.

  Nemo 의 MemoScrollbar.pas 와 구조가 같다. 다른 것은 좌표계(여기는
  OffsetY/RangeY 픽셀, 그쪽은 에디트 줄 단위)와 색(여기는 어두운 배경의
  고정 팔레트, 그쪽은 노트 배경의 음영)뿐이다.
}

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

    FVisible  : Boolean;   // 지금 바가 화면에 있는가
    FHot      : Boolean;   // 트랙 위에 마우스가 있는가 → 6px
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
  FBarW := 10; // slim overlay hit width

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

// 눈에 보이는 좁은 띠. 평소 2px, 호버·드래그 중 6px — 즉시 전환.
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

  // BarShow 가 띠 무효화 + UpdateWindow 로 밀린 본문과 바를 한 번에 정리한다
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
  StartHideTimer;   // 잠잠해지면 숨긴다 — 다시 부르면 시계가 처음부터 돈다

  // 바로 PaintOverlay 를 부르지 않는다. 여기 그리기는 화면을 떠 와 합성하는
  // 방식이라, 트리가 ScrollWindow 로 민 화면에는 이전에 그려 둔 바의 잔상이
  // 남아 있고 그것까지 판에 뜨면 지워지지 않는다. 띠를 무효화해 트리가 제
  // 내용으로 되살리게 한 뒤(UpdateWindow → WM_PAINT), 훅의 WM_PAINT 처리가
  // 깨끗한 판 위에 바를 얹는다.
  InvalidateStrip;
  UpdateWindow(FTree.Handle);
end;

// 트리 본문이 띠 밑까지 그려져 있으므로 배경을 칠해 지울 수 없다 —
// 무효화해서 트리가 제 내용을 다시 그리게 한다.
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
  // SetTimer 는 같은 ID 로 다시 부르면 시간을 처음부터 다시 잰다
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

  // 스크롤할 것이 없어졌다(목록이 줄었다) — 바를 거둔다
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
      // 지금 화면을 떠 와서 그 위에 그린다 — 띠 밑의 본문을 살리기 위해서다
      BitBlt(MemDC, 0, 0, Strip.Width, Strip.Height,
        DC, Strip.Left, Strip.Top, SRCCOPY);

      // 이하 좌표는 비트맵 기준 — 띠의 원점만큼 옮긴다
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
        // 호버로는 색을 바꾸지 않는다(굵기만 6px). 드래그 중에만 밝아진다.
        if FDragging then
          Br := CreateSolidBrush(ColorToRGB(FClrDrag))
        else
          Br := CreateSolidBrush(ColorToRGB(FClrThumb));

        OldPen := SelectObject(MemDC, GetStockObject(NULL_PEN));
        OldBr  := SelectObject(MemDC, Br);

        // NULL_PEN 이면 오른쪽·아래 경계 1px 이 채워지지 않는다 —
        // +1 로 보정해야 2px 가 정말 2px 로 나온다.
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
        // 바가 떠 있는 동안에는 바 기둥을 업데이트 영역에서 뺀다. 빼지 않으면
        // 트리가 그 자리를 제 내용으로 지우고 우리가 다시 얹는 두 번 쓰기가
        // 되는데, 드래그처럼 다시 그리기가 잦을 때 그 사이가 깜빡임으로
        // 보인다. 기둥의 잔상은 어차피 PaintOverlay 가 전체 높이를 덮고,
        // 기둥 밖 여백은 트리가 정상적으로 되살린다.
        if FVisible and (MaxScrollPos > 0) then
        begin
          ThR := VisualTrackR;
          ValidateRect(FTree.Handle, @ThR);
        end;

        FOldWnd(M);
        PaintOverlay;   // 본문이 다시 그려질 때 바를 다시 얹는다
        Exit;
      end;

    // 트리는 휠·키·스크롤 메시지를 스스로 처리한다. 실제로 밀렸을 때만
    // 바를 보인다 (커서 이동처럼 화면이 안 움직이는 키는 바를 띄우지 않게).
    WM_MOUSEWHEEL, WM_VSCROLL, WM_KEYDOWN:
      begin
        PrevPos := CurPos;
        FOldWnd(M);
        if CurPos <> PrevPos then
          BarShow
        else if FVisible then
          PaintOverlay;   // 밀리지 않았어도 다시 그려진 본문 위에 얹는다
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

        // 호버는 트랙 안/밖이 바뀌는 순간에만 처리한다 (2px ↔ 6px).
        // 굵기가 바뀌므로 이전 폭의 흔적을 트리가 지우게 한 뒤 다시 얹는다.
        WasHot := FHot;
        FHot := PtInRect(TrackR, Point(X, Y)) and (MaxScrollPos > 0);

        if FHot <> WasHot then
        begin
          if FHot then
          begin
            RequestMouseLeave;   // 트랙을 벗어날 때 WM_MOUSELEAVE 를 받기 위해
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
          BarShow;   // 보통 색으로 되돌리고 숨김 시계를 다시 돈다
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

    // 잠잠해졌다 — 즉시 숨긴다 (페이드 없음). 호버·드래그 중이면 미룬다.
    WM_TIMER:
      begin
        if M.WParam = CTimerID then
        begin
          if FHot or FDragging then
            Exit;   // 시계가 도는 채로 둔다 — 다음 틱에 다시 본다

          BarHide;
          Exit;
        end;
      end;

  end;

  FOldWnd(M);
end;

end.
