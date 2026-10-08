unit Thumb;

// 진행바 미리보기 — 재생용과 별개인 두 번째 mpv(소리·자막 없음, 일시정지)를 이 스레드가 돌린다.
// 요청(파일, 시각) → 키프레임 탐색 → 소프트웨어 렌더(MPV_RENDER_API_TYPE_SW)로 작은 프레임 → BMP 바이트 → UI 스레드.
// 요청은 마지막 것만 산다 (마우스가 움직이는 동안 쌓인 것은 버림). 파일은 첫 요청 때 연다 (호버 안 하면 디코더 안 띄움).
// 재생 mpv 의 창(wid)·옵션과 무관 — 같은 DLL 의 별도 핸들. mpv API 는 스레드 안전.

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs,
  MPVClient, MPVRender;

type
  // ABytes = BMP 파일 바이트, AW×AH = 픽셀 크기 (UI 스레드에서 호출)
  TThumbEvent = procedure(const ABytes: TBytes; AW, AH: Integer) of object;

  TThumbnailer = class(TThread)
  private
    FLock: TCriticalSection;
    FWake: TEvent;
    FOnThumb: TThumbEvent;
    // 요청 (UI 스레드가 쓰고 이 스레드가 읽음 — FLock)
    FReqFile: string;
    FReqTime: Double;
    FReqSeq: Integer;
    // 결과 (이 스레드가 쓰고 Deliver 가 읽음 — FLock)
    FOut: TBytes;
    FOutW, FOutH: Integer;
    // 이 스레드 전용
    FMpv: PMPVHandle;
    FRender: PMPVRenderContext;
    FFile: string;          // 열어 둔 파일
    FLoaded: Boolean;       // FILE_LOADED 받음
    FW, FH: Integer;        // 렌더 크기 (영상 비율)
    FBuf: TBytes;
    procedure Open;
    procedure Close;
    procedure Cmd(const AArgs: array of string);
    function PropStr(const AName: string): string;
    procedure Drain;
    function RenderFrame: Boolean;
    procedure Publish;
    procedure Deliver;
  protected
    procedure Execute; override;
  public
    constructor Create(AOnThumb: TThumbEvent);
    destructor Destroy; override;
    // AFile = 재생 중 파일 경로, ATime = 초. 같은 요청이면 무시.
    procedure Request(const AFile: string; ATime: Double);
  end;

const
  ThumbWidth = 256;   // 렌더 폭 px. 화면엔 CSS 160 으로 줄여 보인다 (배율 높은 화면 대비 여유)

implementation

procedure RenderUpdate(cb_ctx: Pointer); cdecl;
begin
  TEvent(cb_ctx).SetEvent;   // mpv 쪽 스레드 — 깨우기만
end;

constructor TThumbnailer.Create(AOnThumb: TThumbEvent);
begin
  FLock := TCriticalSection.Create;
  FWake := TEvent.Create(nil, False, False, '');
  FOnThumb := AOnThumb;
  FReqSeq := 0;
  inherited Create(False);
end;

destructor TThumbnailer.Destroy;
begin
  Terminate;
  FWake.SetEvent;
  inherited;   // WaitFor — Execute 끝에서 mpv 정리
  FWake.Free;
  FLock.Free;
end;

procedure TThumbnailer.Request(const AFile: string; ATime: Double);
begin
  FLock.Enter;
  try
    if (AFile = FReqFile) and (Abs(ATime - FReqTime) < 0.05) then Exit;
    FReqFile := AFile;
    FReqTime := ATime;
    Inc(FReqSeq);
  finally
    FLock.Leave;
  end;
  FWake.SetEvent;
end;

procedure TThumbnailer.Cmd(const AArgs: array of string);
var
  Args: array of PMPVChar;
  Strs: array of UTF8String;
  I: Integer;
begin
  SetLength(Strs, Length(AArgs));
  SetLength(Args, Length(AArgs) + 1);
  for I := 0 to High(AArgs) do
  begin
    Strs[I] := UTF8String(AArgs[I]);
    Args[I] := PMPVChar(Strs[I]);
  end;
  Args[Length(AArgs)] := nil;
  mpv_command(FMpv, @Args[0]);
end;

function TThumbnailer.PropStr(const AName: string): string;
var
  P: PMPVChar;
begin
  Result := '';
  P := mpv_get_property_string(FMpv, PMPVChar(UTF8String(AName)));
  if P = nil then Exit;
  Result := string(UTF8String(P));
  mpv_free(P);
end;

procedure TThumbnailer.Open;
const
  // 디코드만 가볍게: 소리·자막·스크립트·설정 파일·캐시 없음, 키프레임 탐색, 루프 필터 생략
  Opts: array[0..19, 0..1] of string = (
    ('vo', 'libmpv'), ('ao', 'null'), ('audio', 'no'), ('sid', 'no'), ('sub-auto', 'no'),
    ('audio-file-auto', 'no'), ('pause', 'yes'), ('keep-open', 'always'), ('idle', 'yes'),
    ('config', 'no'), ('load-scripts', 'no'), ('ytdl', 'no'), ('terminal', 'no'),
    ('input-default-bindings', 'no'), ('osd-level', '0'), ('cache', 'no'),
    ('hr-seek', 'no'), ('hwdec', 'no'), ('vd-lavc-skiploopfilter', 'all'), ('vd-lavc-fast', 'yes'));
var
  I: Integer;
  Api: UTF8String;
  Params: array[0..1] of mpv_render_param;
begin
  FMpv := mpv_create;
  if FMpv = nil then Exit;
  for I := 0 to High(Opts) do
    mpv_set_option_string(FMpv, PMPVChar(UTF8String(Opts[I, 0])), PMPVChar(UTF8String(Opts[I, 1])));
  if mpv_initialize(FMpv) < 0 then
  begin
    mpv_terminate_destroy(FMpv);
    FMpv := nil;
    Exit;
  end;
  Api := MPV_RENDER_API_TYPE_SW;
  Params[0].type_ := MPV_RENDER_PARAM_API_TYPE;
  Params[0].data := PAnsiChar(Api);
  Params[1].type_ := MPV_RENDER_PARAM_INVALID;
  Params[1].data := nil;
  if mpv_render_context_create(@FRender, FMpv, @Params[0]) < 0 then
  begin
    FRender := nil;
    mpv_terminate_destroy(FMpv);
    FMpv := nil;
    Exit;
  end;
  mpv_render_context_set_update_callback(FRender, mpv_render_update_fn(@RenderUpdate), FWake);
end;

// 렌더 컨텍스트를 코어보다 먼저 (MPVRender.pas 규칙)
procedure TThumbnailer.Close;
begin
  if FRender <> nil then
  begin
    mpv_render_context_free(FRender);
    FRender := nil;
  end;
  if FMpv <> nil then
  begin
    mpv_terminate_destroy(FMpv);
    FMpv := nil;
  end;
end;

// 쌓인 mpv 이벤트 비우기. 파일 열림(FILE_LOADED)만 본다 — 영상 크기 → 렌더 크기.
procedure TThumbnailer.Drain;
var
  E: P_mpv_event;
  DW, DH: Integer;
begin
  repeat
    E := mpv_wait_event(FMpv, 0);
    case E^.event_id of
      MPV_EVENT_FILE_LOADED:
        begin
          FLoaded := True;
          DW := StrToIntDef(PropStr('dwidth'), 0);
          DH := StrToIntDef(PropStr('dheight'), 0);
          FW := ThumbWidth;
          if (DW > 0) and (DH > 0) then
            FH := Round(ThumbWidth * DH / DW)
          else
            FH := ThumbWidth * 9 div 16;
          if FH > ThumbWidth then FH := ThumbWidth;   // 세로 영상은 정사각으로 (mpv 가 여백)
          if FH < 16 then FH := 16;
        end;
    end;
  until E^.event_id = MPV_EVENT_NONE;
end;

// 새 프레임이 있으면 FBuf 에 그린다
function TThumbnailer.RenderFrame: Boolean;
var
  Size: array[0..1] of Integer;
  Stride: NativeUInt;
  Fmt: UTF8String;
  Params: array[0..4] of mpv_render_param;
begin
  Result := False;
  if (mpv_render_context_update(FRender) and MPV_RENDER_UPDATE_FRAME) = 0 then Exit;
  if (FW <= 0) or (FH <= 0) then Exit;
  Size[0] := FW;
  Size[1] := FH;
  Stride := FW * 4;
  SetLength(FBuf, Stride * FH);
  Fmt := 'bgr0';   // BMP 32bpp 와 같은 바이트 순서
  Params[0].type_ := MPV_RENDER_PARAM_SW_SIZE;
  Params[0].data := @Size[0];
  Params[1].type_ := MPV_RENDER_PARAM_SW_FORMAT;
  Params[1].data := PAnsiChar(Fmt);
  Params[2].type_ := MPV_RENDER_PARAM_SW_STRIDE;
  Params[2].data := @Stride;
  Params[3].type_ := MPV_RENDER_PARAM_SW_POINTER;
  Params[3].data := @FBuf[0];
  Params[4].type_ := MPV_RENDER_PARAM_INVALID;
  Params[4].data := nil;
  Result := mpv_render_context_render(FRender, @Params[0]) >= 0;
end;

// FBuf → BMP (위→아래, 32bpp, 4번째 바이트는 불투명으로) → FOut
procedure TThumbnailer.Publish;
const
  HDR = 14 + 40;
var
  B: TBytes;
  N, I: Integer;
  P: PByte;

  procedure W32(AOfs: Integer; AV: Integer);
  begin
    PInteger(@B[AOfs])^ := AV;
  end;

  procedure W16(AOfs: Integer; AV: Word);
  begin
    PWord(@B[AOfs])^ := AV;
  end;

begin
  N := FW * FH * 4;
  SetLength(B, HDR + N);
  FillChar(B[0], HDR, 0);
  B[0] := Ord('B');
  B[1] := Ord('M');
  W32(2, HDR + N);
  W32(10, HDR);
  W32(14, 40);
  W32(18, FW);
  W32(22, -FH);   // 음수 = 위에서 아래
  W16(26, 1);
  W16(28, 32);
  W32(34, N);
  Move(FBuf[0], B[HDR], N);
  P := @B[HDR + 3];
  for I := 0 to FW * FH - 1 do
  begin
    P^ := 255;
    Inc(P, 4);
  end;
  FLock.Enter;
  try
    FOut := B;
    FOutW := FW;
    FOutH := FH;
  finally
    FLock.Leave;
  end;
  Queue(Deliver);
end;

procedure TThumbnailer.Deliver;
var
  B: TBytes;
  W, H: Integer;
begin
  FLock.Enter;
  try
    B := FOut;
    W := FOutW;
    H := FOutH;
    FOut := nil;
  finally
    FLock.Leave;
  end;
  if (B <> nil) and Assigned(FOnThumb) then
    FOnThumb(B, W, H);
end;

// 일시정지라 프레임은 열기·탐색 때만 온다 → 요청 뒤 그려진 프레임은 전부 보낸다 (탐색 완료 이벤트와 프레임 도착
// 순서에 기대지 않음. 열린 직후 첫 프레임이 잠깐 보였다가 탐색 프레임으로 바뀔 수 있다)
procedure TThumbnailer.Execute;
var
  Seq, DoneSeq: Integer;
  F: string;
  T: Double;
begin
  Open;
  if FMpv = nil then Exit;
  DoneSeq := 0;
  try
    while not Terminated do
    begin
      FWake.WaitFor(200);
      if Terminated then Break;

      Drain;

      FLock.Enter;
      try
        Seq := FReqSeq;
        F := FReqFile;
        T := FReqTime;
      finally
        FLock.Leave;
      end;

      if F <> FFile then
      begin
        FFile := F;
        FLoaded := False;
        if F <> '' then Cmd(['loadfile', F]) else Cmd(['stop']);
        Continue;   // FILE_LOADED 뒤 다음 바퀴에서 탐색
      end;

      // 새 요청 → 탐색. 진행 중인 탐색이 있어도 덮어쓴다 (마지막 것만)
      if FLoaded and (Seq <> DoneSeq) then
      begin
        DoneSeq := Seq;
        Cmd(['seek', FormatFloat('0.000', T, DefaultFormatSettings), 'absolute+keyframes']);
      end;

      if RenderFrame and (DoneSeq > 0) then Publish;
    end;
  finally
    Close;
  end;
end;

end.
