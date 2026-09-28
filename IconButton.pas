unit IconButton;

// 재생목록 창 하단 아이콘 버튼 — Delphi 판 TSVGIconImage 대체 (LCL 에 SVG 컨트롤 없음).
// 그림 = RCDATA 'list-<이름>' (Res\list-*.png, 128px 알파 마스크, Tools\MakeListIcons.py 생성).
// 그릴 때 컨트롤 크기로 면적 평균 축소 + FixedColor 로 칠함 → 어떤 DPI 에서도 한 벌의 PNG 로 선명.
// 코드로 만든다 (LFM 에 두면 IDE 디자이너가 클래스를 몰라 폼이 안 열림).

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, IntfGraphics, FPImage, GraphType;

type
  TIconButton = class(TGraphicControl)
  private
    FImageIndex: Integer;
    FFixedColor: TColor;
    FCache: TBitmap;        // 현재 크기·색으로 칠한 그림
    FCacheIndex: Integer;
    FCacheColor: TColor;
    FCacheSize: Integer;
    procedure SetImageIndex(AValue: Integer);
    procedure SetFixedColor(AValue: TColor);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property ImageIndex: Integer read FImageIndex write SetImageIndex;
    property FixedColor: TColor read FFixedColor write SetFixedColor;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

const
  // ImageIndex 순서 = Delphi 판 TSVGIconImageList 순서
  IconNames: array[0..4] of string = ('repeat', 'repeat-one', 'random', 'plus', 'minus');

implementation

uses
  LCLType;

var
  GMasks: array[Low(IconNames)..High(IconNames)] of TLazIntfImage;

function LoadMask(AIndex: Integer): TLazIntfImage;
var
  Res: TResourceStream;
  Png: TPortableNetworkGraphic;
begin
  Result := GMasks[AIndex];
  if Result <> nil then Exit;

  Res := TResourceStream.Create(HInstance, 'list-' + IconNames[AIndex], RT_RCDATA);
  try
    Png := TPortableNetworkGraphic.Create;
    try
      Png.LoadFromStream(Res);
      Result := Png.CreateIntfImage;
    finally
      Png.Free;
    end;
  finally
    Res.Free;
  end;
  GMasks[AIndex] := Result;
end;

function Max1(A, B: Integer): Integer; inline;
begin
  if A > B then Result := A else Result := B;
end;

// 마스크 알파를 ASize 로 면적 평균 축소, 색 = AColor
procedure RenderTinted(AMask: TLazIntfImage; ASize: Integer; AColor: TColor; ADest: TBitmap);
var
  Dst: TLazIntfImage;
  SW, SH, X, Y, SX, SY, SX0, SX1, SY0, SY1: Integer;
  Sum, Cnt: Int64;
  RGB: LongInt;
  C: TFPColor;
begin
  SW := AMask.Width;
  SH := AMask.Height;
  RGB := ColorToRGB(AColor);

  Dst := TLazIntfImage.Create(0, 0);
  try
    Dst.DataDescription.Init_BPP32_B8G8R8A8_BIO_TTB(ASize, ASize);
    Dst.CreateData;
    for Y := 0 to ASize - 1 do
    begin
      SY0 := Y * SH div ASize;
      SY1 := Max1((Y + 1) * SH div ASize, SY0 + 1);
      for X := 0 to ASize - 1 do
      begin
        SX0 := X * SW div ASize;
        SX1 := Max1((X + 1) * SW div ASize, SX0 + 1);
        Sum := 0;
        Cnt := 0;
        for SY := SY0 to SY1 - 1 do
          for SX := SX0 to SX1 - 1 do
          begin
            Inc(Sum, AMask.Colors[SX, SY].Alpha);
            Inc(Cnt);
          end;
        C.Red := (RGB and $FF) * $101;
        C.Green := ((RGB shr 8) and $FF) * $101;
        C.Blue := ((RGB shr 16) and $FF) * $101;
        if Cnt > 0 then
          C.Alpha := Sum div Cnt
        else
          C.Alpha := 0;
        Dst.Colors[X, Y] := C;
      end;
    end;
    ADest.LoadFromIntfImage(Dst);
  finally
    Dst.Free;
  end;
end;

{ TIconButton }

constructor TIconButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFixedColor := clBlack;
  FCacheIndex := -1;
  SetInitialBounds(0, 0, 16, 16);
end;

destructor TIconButton.Destroy;
begin
  FCache.Free;
  inherited;
end;

procedure TIconButton.SetImageIndex(AValue: Integer);
begin
  if FImageIndex = AValue then Exit;
  FImageIndex := AValue;
  Invalidate;
end;

procedure TIconButton.SetFixedColor(AValue: TColor);
begin
  if FFixedColor = AValue then Exit;
  FFixedColor := AValue;
  Invalidate;
end;

procedure TIconButton.Paint;
var
  S: Integer;
begin
  if (FImageIndex < Low(IconNames)) or (FImageIndex > High(IconNames)) then Exit;

  S := Width;
  if Height < S then S := Height;
  if S <= 0 then Exit;

  if (FCache = nil) or (FCacheIndex <> FImageIndex) or (FCacheColor <> FFixedColor) or
     (FCacheSize <> S) then
  begin
    if FCache = nil then
      FCache := TBitmap.Create;
    try
      RenderTinted(LoadMask(FImageIndex), S, FFixedColor, FCache);
    except
      FreeAndNil(FCache);   // 리소스 누락 — 그리지 않음
      Exit;
    end;
    FCacheIndex := FImageIndex;
    FCacheColor := FFixedColor;
    FCacheSize := S;
  end;

  Canvas.Draw((Width - S) div 2, (Height - S) div 2, FCache);
end;

procedure FreeMasks;
var
  I: Integer;
begin
  for I := Low(GMasks) to High(GMasks) do
    FreeAndNil(GMasks[I]);
end;

initialization

finalization
  FreeMasks;

end.
