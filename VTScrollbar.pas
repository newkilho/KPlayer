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
    FClrHot   : TColor;
    FClrDrag  : TColor;

    FDragging : Boolean;
    FDragScrY : Integer;
    FDragPos0 : Integer;
    FHot      : Boolean;
    FOpacity      : Byte;
    FTargetOpacity: Byte;
    FFadeStep     : Byte;
    FFadeInterval : Cardinal;
    FAutoHideDelay: Cardinal;
    FHideTick     : Cardinal;
    FTimerOn      : Boolean;

    procedure TreeWndProc(var M: TMessage);
    procedure PaintOverlay;
    procedure RequestMouseLeave;
    procedure StartFadeTimer;
    procedure StopFadeTimer;
    procedure KickFadeIn(Strong: Boolean = False);
    procedure UpdateFadeTarget;
    function BlendColor(Bg, Fg: TColor; A: Byte): TColor;
    function VisualTrackR: TRect;

    function TrackR: TRect;
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
  FClrHot   := $008C8C8C;
  FClrDrag  := $00B0B0B0;
  FOpacity := 0;
  FTargetOpacity := 0;
  FFadeStep := 24;
  FFadeInterval := 15;
  FAutoHideDelay := 900;
  FHideTick := GetTickCount;
  FTimerOn := False;

  FOldWnd := ATree.WindowProc;
  ATree.WindowProc := TreeWndProc;
end;

destructor TVTDarkScrollbar.Destroy;
begin
  if Assigned(FTree) then
  begin
    StopFadeTimer;
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

function TVTDarkScrollbar.VisualTrackR: TRect;
var
  W: Integer;
begin
  Result := TrackR;
  if FDragging or FHot then
    W := 6
  else
    W := 4;

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
var
  R: TRect;
begin
  FTree.OffsetY :=
    -Max(0, Min(NewPos, MaxScrollPos));

  R := TrackR;
  InvalidateRect(FTree.Handle, @R, False);
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

{ ================= Painting ================= }

function TVTDarkScrollbar.BlendColor(Bg, Fg: TColor; A: Byte): TColor;
var
  BR, BGn, BB: Byte;
  FR, FGn, FB: Byte;
  R, G, B: Integer;
begin
  Bg := ColorToRGB(Bg);
  Fg := ColorToRGB(Fg);

  BR := GetRValue(Bg);
  BGn := GetGValue(Bg);
  BB := GetBValue(Bg);
  FR := GetRValue(Fg);
  FGn := GetGValue(Fg);
  FB := GetBValue(Fg);

  R := (BR * (255 - A) + FR * A) div 255;
  G := (BGn * (255 - A) + FGn * A) div 255;
  B := (BB * (255 - A) + FB * A) div 255;
  Result := RGB(R, G, B);
end;

procedure TVTDarkScrollbar.PaintOverlay;
var
  DC: HDC;
  Thumb: TRect;
  VTrack, VThumb: TRect;
  Br: HBRUSH;
  OldPen, OldBr: HGDIOBJ;
  ThColor: TColor;
  BaseColor: TColor;
begin
  if (MaxScrollPos <= 0) or (FOpacity = 0) then
    Exit;

  DC := GetDC(FTree.Handle);
  if DC = 0 then Exit;

  try
    Thumb := ThumbR;
    VTrack := VisualTrackR;
    VThumb := Thumb;
    VThumb.Left := VTrack.Left;
    VThumb.Right := VTrack.Right;
    BaseColor := FTree.Color;

    Br := CreateSolidBrush(ColorToRGB(BlendColor(BaseColor, FClrTrack, FOpacity)));
    FillRect(DC, VTrack, Br);
    DeleteObject(Br);

    if Thumb.IsEmpty then Exit;

    if FDragging then
      ThColor := FClrDrag
    else if FHot then
      ThColor := FClrHot
    else
      ThColor := FClrThumb;

    Br := CreateSolidBrush(ColorToRGB(BlendColor(BaseColor, ThColor, FOpacity)));
    OldPen := SelectObject(DC, GetStockObject(NULL_PEN));
    OldBr  := SelectObject(DC, Br);

    RoundRect(
      DC,
      VThumb.Left,
      VThumb.Top,
      VThumb.Right,
      VThumb.Bottom,
      Min(VThumb.Width, 8),
      Min(VThumb.Width, 8)
    );

    SelectObject(DC, OldPen);
    SelectObject(DC, OldBr);
    DeleteObject(Br);

  finally
    ReleaseDC(FTree.Handle, DC);
  end;
end;

{ ================= Mouse Leave ================= }

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

{ ================= Fade ================= }

procedure TVTDarkScrollbar.StartFadeTimer;
begin
  if FTimerOn then
    Exit;
  SetTimer(FTree.Handle, CTimerID, FFadeInterval, nil);
  FTimerOn := True;
end;

procedure TVTDarkScrollbar.StopFadeTimer;
begin
  if not FTimerOn then
    Exit;
  KillTimer(FTree.Handle, CTimerID);
  FTimerOn := False;
end;

procedure TVTDarkScrollbar.KickFadeIn(Strong: Boolean);
begin
  if MaxScrollPos <= 0 then
  begin
    FTargetOpacity := 0;
    FOpacity := 0;
    StopFadeTimer;
    Exit;
  end;

  if Strong or FDragging then
    FTargetOpacity := 220
  else
    FTargetOpacity := 180;

  FHideTick := GetTickCount + FAutoHideDelay;
  StartFadeTimer;
end;

procedure TVTDarkScrollbar.UpdateFadeTarget;
begin
  if FDragging then
  begin
    FTargetOpacity := 220;
    Exit;
  end;

  if FHot then
  begin
    FTargetOpacity := 200;
    Exit;
  end;

  if Integer(GetTickCount - FHideTick) >= 0 then
    FTargetOpacity := 0;
end;

{ ================= WndProc ================= }

procedure TVTDarkScrollbar.TreeWndProc(var M: TMessage);
var
  X, Y: Integer;
  CursorPos: TPoint;
  TrackH, ThLen, NewPos: Integer;
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
        FOldWnd(M);
        PaintOverlay;
        Exit;
      end;

    WM_MOUSEWHEEL, WM_VSCROLL, WM_KEYDOWN:
      begin
        FOldWnd(M);
        KickFadeIn(False);
        PaintOverlay;
        Exit;
      end;

    WM_LBUTTONDOWN:
      begin
        X := SmallInt(LoWord(M.LParam));
        Y := SmallInt(HiWord(M.LParam));

        if PtInRect(TrackR, Point(X, Y)) then
        begin
          KickFadeIn(True);
          ThR := ThumbR;

          if PtInRect(ThR, Point(X, Y)) then
          begin
            FDragging := True;
            KickFadeIn(True);
            GetCursorPos(CursorPos);
            FDragScrY := CursorPos.Y;
            FDragPos0 := CurPos;
            SetCapture(FTree.Handle);
            PaintOverlay;
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
          KickFadeIn(True);
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

        WasHot := FHot;
        FHot := PtInRect(TrackR, Point(X, Y));

        if (not WasHot) and FHot then
          RequestMouseLeave;

        if FHot then
          KickFadeIn(False);

        if FHot <> WasHot then
          PaintOverlay;

        FOldWnd(M);
        Exit;
      end;

    WM_LBUTTONUP:
      begin
        if FDragging then
        begin
          FDragging := False;
          ReleaseCapture;
          FHideTick := GetTickCount + FAutoHideDelay;
          PaintOverlay;
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
          FHideTick := GetTickCount + 120;
          StartFadeTimer;
          PaintOverlay;
        end;
        Exit;
      end;

    WM_TIMER:
      begin
        if M.WParam = CTimerID then
        begin
          UpdateFadeTarget;

          if FOpacity < FTargetOpacity then
            FOpacity := Min(255, FOpacity + FFadeStep)
          else if FOpacity > FTargetOpacity then
            FOpacity := Max(0, FOpacity - FFadeStep);

          if (FOpacity = 0) and (FTargetOpacity = 0) and (not FHot) and (not FDragging) then
            StopFadeTimer;

          ThR := TrackR;
          InvalidateRect(FTree.Handle, @ThR, False);
          Exit;
        end;
      end;

  end;

  FOldWnd(M);
end;

end.
