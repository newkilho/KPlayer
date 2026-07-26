{===============================================================================

Project : KPlayer
Author  : Kilho, Oh
Engine  : libmpv (GPL-2.0-or-later)
Tree    : Virtual Treeview (MPL 1.1)

This program links against libmpv (GPL-2.0-or-later).
When distributed in binary form, the complete corresponding
source code must be made available under the GPL.

Icon: https://www.flaticon.com/free-icon/play_2377793

History:
========
  0.9.4
  [+] 환경설정 '연결' 카드 추가 - 확장자 38종을 KPlayer 로 연결/해제, 체크 즉시 반영 (Setup.pas: CardAssoc/TreeAssoc, AssocExts, AssocRegister/AssocUnregister)
  [+] 시작 시 등록된 파일 연결의 exe 경로 갱신 - 포터블 폴더 이동 대응 (Setup.pas: SyncFileAssoc / Main.FormCreate)
  [*] 지원 확장자를 AssocExts 하나로 통일 - AddFile 의 하드코딩 7종 제거 (List.pas: IsMediaFile)
  [+] 재생목록 파일(.m3u/.m3u8/.pls) 을 항목으로 펼침 - 상대경로/ANSI·UTF-8 판별 (List.pas: AddPlaylist)
  [+] 환경설정 전면 개편 - 디자이너 배치, 카드별 즉시 적용, 기본값 복원을 좌측 메뉴로 (Setup.pas/Setup.dfm)
  [+] 키보드 볼륨/재생 조작 시 화면 중앙 인디케이터 - 페이드 인·아웃 + 아이콘 줌 (KPlayer.lua: draw_bezel, show_bezel)
  [+] OSD 글꼴을 윈도우 UI 기본 폰트로 맞춤 - script-message ui-font (Main.FormCreate / KPlayer.lua)
  [*] 캡처 기본 저장 폴더를 바탕화면으로 - 미지정 시 exe 폴더를 쓰지 않는다 (Setup.pas: DesktopPath)
  [*] 자막 트랙이 없으면 자막 버튼을 만들지 않음 (KPlayer.lua: calc_layout)
  [*] Lua 메시지를 영어로, 배속 토스트는 '1.5x' 형식으로 (KPlayer.lua)
  [*] 키보드 조작 시 상단/하단 컨트롤바가 뜨지 않게 - seek/playback-restart 이벤트 제거 (KPlayer.lua)
  [*] 대화상자를 TaskMessageDlg 로 - 버튼 캡션/아이콘을 OS 가 제공 (Setup.pas)
  [-] TDragFile 이 해제되지 않던 문제 수정 (List.pas: FDragFile)
  [-] 마우스 이동 등 불필요한 로그 제거, mpv 로그 파일은 기본 미사용 (Main.pas, MPVPlayer.pas)

  0.9.3
  [+] 키보드 배속 조절 추가 - Z(1.0 리셋)/X(-0.1)/C(+0.1), 수식키 없을 때만, 0.1 단위 정규화·0.25~4.0 clamp (SetSpeed, AddSpeed, FormKeyDown)
  [+] 배속 변경 시 화면 중앙 OSD 토스트 표시 (KPlayer.lua: draw_speed_toast, show_speed_toast, speed observer)
  [+] 자막 토글 버튼 추가 - 트랙 유무로 활성/비활성, 클릭 시 표시 토글 (KPlayer.lua: icons.sub, sub_btn, sid observer, render, click handler)
  [+] 랜덤 재생 중복 방지(셔플) - 사이클 내 미재생 곡만 선택 (Rand, PickRandomUnplayed, ResetShuffle, PruneShuffleMissing, FShuffleHistory/FShufflePos/FCyclePlayed)
  [*] 랜덤 중 이전곡을 셔플 순서상 실제 이전 곡으로 변경 (Prev)
  [+] 전체화면 마우스 커서 자동 숨김 - 컨트롤바 표시에 동기화 (KPlayer.lua: update_cursor / OnScriptMessage 'cursor', HandleFullScreen)
  [*] 전체화면 해제를 mpv fullscreen 속성으로 일원화 (FormKeyDown: VK_ESCAPE)
  [*] 재생 목록 노드 높이 고정 처리 방식 변경 - toVariableNodeHeight 제거, DefaultNodeHeight := 24 설정 (TFrmList.FormCreate)
  [*] 노드 추가 시 높이값 직접 지정 - ListData.NodeHeight[Node] := 24 추가 (TFrmList.AddFile)
  [+] 오디오 노멀라이징(음량 평준화) 추가

  0.9.2
  [*] 실행 인자에 전달된 기존 파일을 재생 목록에 추가하고 첫 파일을 자동 재생하도록 처리

  0.9.1
  [*] 렌더링 및 디코딩 기본 옵션 추가 - vo=gpu, hwdec=auto-safe, gpu-api=auto 설정 추가
  [*] 화면 동기화 옵션 추가 - video-sync=display-resample 설정 추가
  [*] 인터레이싱 처리 방식 변경 - deinterlace=yes → deinterlace=auto 로 변경
  [*] 스케일링 옵션 조정 - scale=bilinear → scale=lanczos 변경, cscale=bilinear 유지

================================================================================}

unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Types, System.Math, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, MPVBasePlayer, MPVPlayer,
  K.Theme, K.DragFile, K.Config.INI, K.Update;

type
  TFrmKPlayer = class(TForm)
    Menu: TPopupMenu;
    BtnAbout: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    FConfig: TConfig;
    FDragFile: TDragFile;
    FVolume: Double;
    FRepeatMode: Integer;
    FRandomMode: Integer;
    FOverControl: Boolean;
    FLastMouseX: Integer;
    FLastMouseY: Integer;
    FLeftDown: Boolean;

    procedure SendLeftButton(ADown: Boolean);
    procedure OnScriptMessage(ASender: TObject; const ACommand: string; AParams: TStrings);

    procedure HandleClose;
    procedure HandleMinimize;
    procedure HandleZoomIn(AStep: Double);
    procedure HandleZoomOut(AStep: Double);
    procedure HandleFullScreen(AState: Boolean);
    procedure HandleSettings;
    procedure HandlePlayList;

    procedure WMNCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMMouseWheel(var Msg: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure SetVolume(const Value: Double);
    procedure SetRandomMode(const Value: Integer);
    procedure SetRepeatMode(const Value: Integer);

    procedure SetSpeed(const Value: Double);
    procedure AddSpeed(const Delta: Double);

    function CfgOpt(const AKey: string; const AValues: array of string): string;
  public
    MPVPlayer: TMPVPlayer;
    Theme: string;

    function IsPlay: Boolean;

    procedure HandlePlay(const AFile: string);
    procedure HandleStop;
    procedure HandlePause;
    procedure HandleStartupParams;

    property Config: TConfig read FConfig;
    property Volume: Double read FVolume write SetVolume;
    property RepeatMode: Integer read FRepeatMode write SetRepeatMode;
    property RandomMode: Integer read FRandomMode write SetRandomMode;
  end;

var
  FrmKPlayer: TFrmKPlayer;

implementation

{$R *.dfm}

uses List, Setup;

{$I Const.inc}

procedure TFrmKPlayer.FormCreate(Sender: TObject);
var
  LLogFile: string;
begin
  Application.Title := Caption;

  BorderStyle := bsNone;
  SetFormCorners(Handle, True);
  Width := 640;
  Height := 400;

  FLastMouseX := -1;
  FLastMouseY := -1;

  FConfig := TConfig.Create(AppName);

  Volume := FConfig.ReadDouble('volume', 100);
  RepeatMode := FConfig.ReadInteger('repeat', 0);
  RandomMode := FConfig.ReadInteger('random', 0);

  if ReportMemoryLeaksOnShutDown then Theme := 'n:\Release\KPlayer.lua' else // Debug
  Theme := ExtractFilePath(ParamStr(0)) + 'KPlayer.lua';

  if not MPVLibLoaded(ExtractFilePath(ParamStr(0))) then
  begin
    ShowMessage('MPV DLL 로드 실패');
    Application.Terminate;
    Exit;
  end;

  if not FileExists(Theme) then
  begin
    Showmessage('필수 파일이 없습니다.');
    Application.Terminate;
    Exit;
  end;

  MPVPlayer := TMPVPlayer.Create;
  MPVPlayer.OnScriptMessage := OnScriptMessage;

  // 파일 없어도 플레이어 종료 방지
  MPVPlayer.SetOptionString('idle', 'yes');

  // 자막 기본 표시 여부 (기본값은 비활성 — 자막 버튼으로 켜야 표시됨)
  if FConfig.ReadInteger('sub_visible', 0) <> 0 then
    MPVPlayer.SetOptionString('sub-visibility', 'yes')
  else
    MPVPlayer.SetOptionString('sub-visibility', 'no');

  MPVPlayer.SetOptionString('sub-font-size', IntToStr(FConfig.ReadInteger('sub_size', 55)));
  MPVPlayer.SetOptionString('slang', FConfig.ReadString('sub_lang', 'ko,kor,en,eng'));

  // 렌더링 및 호환성 안정화 — 환경설정 '영상' 카드의 값 (재시작 시에만 반영)
  MPVPlayer.SetOptionString('vo', CfgOpt('vo', VoValues)); // 기본은 gpu-next 대신 안정 버전
  MPVPlayer.SetOptionString('hwdec', CfgOpt('hwdec', HwdecValues));
  MPVPlayer.SetOptionString('gpu-api', CfgOpt('gpu_api', GpuApiValues));
  MPVPlayer.SetOptionString('video-sync', CfgOpt('video_sync', VideoSyncValues));

  // 영상 안정화 (필요시만 적용)
  MPVPlayer.SetOptionString('deinterlace', CfgOpt('deinterlace', DeintValues));

  // 스케일링 (품질/안정 균형)
  MPVPlayer.SetOptionString('scale', CfgOpt('scale', ScaleValues));
  MPVPlayer.SetOptionString('cscale', 'bilinear');

  // mpv 로그 파일. 평소에는 쓰지 않는다.
  LLogFile := '';
  {$IFDEF DEBUG}
  //LLogFile := ExtractFilePath(ParamStr(0)) + 'KPlayer.log';
  {$ENDIF}

  // 초기화 (4번째 인자 = 로그 파일 경로, 빈 문자열이면 기록하지 않음)
  MPVPlayer.InitPlayer(IntToStr(Handle), '', '', LLogFile, True);

  MPVPlayer.Command(['set', 'screenshot-directory',
    FConfig.ReadString('shot_dir', DesktopPath)]);
  MPVPlayer.Command(['set', 'screenshot-template', '%f-%n']);
  MPVPlayer.Command(['set', 'screenshot-format', CfgOpt('shot_format', ShotFmtValues)]);
  MPVPlayer.Command(['set', 'volume', FloatToStr(Volume)]);

  // 음량 평준화 (환경설정 '음성' 카드)
  if FConfig.ReadInteger('normalize', 1) <> 0 then
    MPVPlayer.Command(['set', 'af',
      NormFilters[EnsureRange(FConfig.ReadInteger('norm_level', 1), 0, High(NormFilters))]]);

  MPVPlayer.Command(['load-script', Theme]);

  // OSD 글자를 윈도우 UI 기본 폰트로 맞춘다.
  MPVPlayer.Command(['script-message', 'ui-font', Screen.MessageFont.Name]);

  FDragFile := TDragFile.Create(Self,
  procedure(const Files: TArray<string>)
  begin
    if Length(Files) = 0 then Exit;

    for var S in Files do
      FrmList.AddFile(S);

    if not IsPlay then
      HandlePlay(Files[0]);
  end);

  // 등록해 둔 파일 연결의 exe 경로를 현재 위치로 다시 기록한다.
  // 포터블이라 폴더를 옮기면 등록된 실행 명령이 옛 경로를 가리켜
  // 더블클릭이 '파일을 찾을 수 없음' 으로 끝난다. (Setup.pas)
  SyncFileAssoc;

  CheckUpdate(procedure(Quit: Boolean; Data: string)
  begin
    if Quit then
    begin
      Close;
      Exit;
    end;
  end);
end;

procedure TFrmKPlayer.FormDestroy(Sender: TObject);
begin
  FreeAndNil(MPVPlayer);
  FreeAndNil(FDragFile);
  FreeAndNil(FConfig);
end;

procedure TFrmKPlayer.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  Resize := (NewWidth >= 384) and (NewHeight >= 216);
end;

// ScriptMessage 처리하기
procedure TFrmKPlayer.OnScriptMessage(ASender: TObject; const ACommand: string; AParams: TStrings);
begin
  if SameText(ACommand, 'close') then
  begin
    HandleClose;
    Exit;
  end;

  if SameText(ACommand, 'minimize') then
  begin
    HandleMinimize;
    Exit;
  end;

  if SameText(ACommand, 'settings') then
  begin
    HandleSettings;
    Exit;
  end;

  if SameText(ACommand, 'playlist') then
  begin
    HandlePlayList;
    Exit;
  end;

  if SameText(ACommand, 'fullscreen') then
  begin
    if AParams.Count > 0 then
    begin
      HandleFullScreen(AParams[0] = 'on');
    end;
    Exit;
  end;

  // 전체화면에서 컨트롤바 표시 여부에 맞춰 마우스 커서 표시/숨김
  if SameText(ACommand, 'cursor') then
  begin
    if AParams.Count > 0 then
    begin
      if SameText(AParams[0], 'hide') then
        Screen.Cursor := crNone
      else
        Screen.Cursor := crDefault;
    end;
    Exit;
  end;

  // 우리가 KPlayer.lua 로 보낸 메시지다. script-message 는 스크립트뿐 아니라
  // 이쪽(호스트)에도 그대로 전달되므로 여기서 무시한다.
  if SameText(ACommand, 'mbtn') or SameText(ACommand, 'ui-font')
  or SameText(ACommand, 'dpi') then
    Exit;

  // 커서가 컨트롤 위에 있는지 (창 드래그 억제용)
  if SameText(ACommand, 'hit') then
  begin
    if AParams.Count > 0 then
      FOverControl := (AParams[0] = '1');
    Exit;
  end;

  if SameText(ACommand, 'prev') then
  begin
    FrmList.Prev;
    Exit;
  end;

  if SameText(ACommand, 'next') then
  begin
    FrmList.Next;
    Exit;
  end;

  if SameText(ACommand, 'finished') then
  begin
    FrmList.Stop;
    Exit;
  end;

  if SameText(ACommand, 'volume') then
  begin
    if AParams.Count > 0 then
      Volume := StrToFloatDef(AParams[0], Volume);
    Exit;
  end;

  ShowMessage('알 수 없는 script-message: ' + ACommand);
end;

// 환경설정에 콤보 인덱스로 저장된 값을 mpv 옵션 문자열로 바꾼다.
function TFrmKPlayer.CfgOpt(const AKey: string; const AValues: array of string): string;
begin
  Result := AValues[EnsureRange(FConfig.ReadInteger(AKey, 0), 0, High(AValues))];
end;

procedure TFrmKPlayer.SetRandomMode(const Value: Integer);
begin
  FRandomMode := Value;
  FConfig.WriteInteger('random', Value);
end;

procedure TFrmKPlayer.SetRepeatMode(const Value: Integer);
begin
  FRepeatMode := Value;
  FConfig.WriteInteger('repeat', Value);
end;

procedure TFrmKPlayer.SetVolume(const Value: Double);
begin
  FVolume := Value;
  FConfig.WriteDouble('volume', Value);
end;

const
  SpeedMin = 0.25;
  SpeedMax = 4.0;

procedure TFrmKPlayer.SetSpeed(const Value: Double);
begin
  MPVPlayer.SetPropertyDouble('speed', EnsureRange(Value, SpeedMin, SpeedMax));
end;

procedure TFrmKPlayer.AddSpeed(const Delta: Double);
var
  LCur: Double;
begin
  LCur := 1.0;
  MPVPlayer.GetPropertyDouble('speed', LCur);
  SetSpeed(Round((LCur + Delta) * 10) / 10);
end;

procedure TFrmKPlayer.WMNCHitTest(var Msg: TWMNCHitTest);
const
  ResizeBorder = 8;
var
  P: TPoint;
  IsLeft, IsRight, IsTop, IsBottom: Boolean;
begin
  inherited;

  if WindowState = wsMaximized then
  begin
    Msg.Result := HTCLIENT;
    Exit;
  end;

  P := ScreenToClient(Point(Msg.XPos, Msg.YPos));

  IsLeft   := P.X <= ResizeBorder;
  IsRight  := P.X >= Width  - ResizeBorder;
  IsTop    := P.Y <= ResizeBorder;
  IsBottom := P.Y >= Height - ResizeBorder;

  if      IsLeft  and IsTop    then Msg.Result := HTTOPLEFT
  else if IsRight and IsTop    then Msg.Result := HTTOPRIGHT
  else if IsLeft  and IsBottom then Msg.Result := HTBOTTOMLEFT
  else if IsRight and IsBottom then Msg.Result := HTBOTTOMRIGHT
  else if IsLeft               then Msg.Result := HTLEFT
  else if IsRight              then Msg.Result := HTRIGHT
  else if IsTop                then Msg.Result := HTTOP
  else if IsBottom             then Msg.Result := HTBOTTOM;
end;

procedure TFrmKPlayer.HandleClose;
begin
  MPVPlayer.Stop;
  Close;
end;

procedure TFrmKPlayer.HandleMinimize;
begin
  WindowState := wsMinimized;
end;

procedure TFrmKPlayer.HandleFullScreen(AState: Boolean);
begin
  if AState then
  begin
    SetFormCorners(Handle, False);
    //FormStyle   := fsStayOnTop;
    WindowState := wsMaximized;
  end
  else
  begin
    //FormStyle   := fsNormal;
    WindowState := wsNormal;
    SetFormCorners(Handle, True);
    Screen.Cursor := crDefault;   // 창모드에선 항상 커서 표시 (안전장치)
  end;
end;

// Zoom-In (ex. 0.1)
procedure TFrmKPlayer.HandleZoomIn(AStep: Double);
var
  LCur: Double;
begin
  LCur := 0;
  MPVPlayer.GetPropertyDouble('video-zoom', LCur);
  MPVPlayer.SetPropertyDouble('video-zoom', LCur + AStep);
end;

// Zoom-Out (ex. 0.1)
procedure TFrmKPlayer.HandleZoomOut(AStep: Double);
var
  LCur: Double;
begin
  LCur := 0;
  MPVPlayer.GetPropertyDouble('video-zoom', LCur);
  MPVPlayer.SetPropertyDouble('video-zoom', LCur - AStep);
end;

function TFrmKPlayer.IsPlay: Boolean;
var
  Pause: string;
  FileName: string;
begin
  if MPVPlayer = nil then Exit(False);

  MPVPlayer.GetPropertyString('pause', Pause);
  MPVPlayer.GetPropertyString('filename', FileName);

  Result := (FileName <> '') and (Pause <> 'yes');
end;

procedure TFrmKPlayer.HandlePlayList;
var
  R: TRect;
begin
  if FrmList.Visible then
  begin
    FrmList.Hide;
  end
  else
  begin
    R := Self.Monitor.WorkareaRect;

    FrmList.Left := R.Right - FrmList.Width;
    FrmList.Top  := R.Bottom - FrmList.Height;

    FrmList.Show;
  end;
end;

procedure TFrmKPlayer.HandleStartupParams;
var
  I: Integer;
  FileName: string;
  FirstFile: string;
begin
  FirstFile := '';

  for I := 1 to ParamCount do
  begin
    FileName := ParamStr(I);
    if not FileExists(FileName) then
      Continue;

    FrmList.AddFile(FileName);

    if FirstFile = '' then
      FirstFile := FileName;
  end;

  if (FirstFile <> '') and not IsPlay then
    FrmList.Play(FirstFile);
end;

procedure TFrmKPlayer.HandleSettings;
begin
  FrmSetup.ShowModal;
end;

procedure TFrmKPlayer.HandlePlay(const AFile: string);
begin
  if (MPVPlayer <> nil) and (AFile <> '') then
    MPVPlayer.OpenFile(AFile);
end;

procedure TFrmKPlayer.HandleStop;
begin
  if MPVPlayer <> nil then
    MPVPlayer.Stop;
end;

procedure TFrmKPlayer.HandlePause;
begin
  if MPVPlayer <> nil then
    MPVPlayer.Command(['cycle','pause']);
end;

// Keyboard input
procedure TFrmKPlayer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  LSpeed: Double;
begin
  if MPVPlayer = nil then Exit;

  case Key of
    // Seek
    VK_LEFT:
      begin
        if ssCtrl in Shift then
          MPVPlayer.Command(['add', 'chapter', '-1'])
        else if ssShift in Shift then
          MPVPlayer.Command(['seek', '-1', 'exact'])
        else
          MPVPlayer.Command(['seek', '-5']);
        Key := 0;
      end;

    VK_RIGHT:
      begin
        if ssCtrl in Shift then
          MPVPlayer.Command(['add', 'chapter', '1'])
        else if ssShift in Shift then
          MPVPlayer.Command(['seek', '1', 'exact'])
        else
          MPVPlayer.Command(['seek', '5']);
        Key := 0;
      end;

    // Frame stepping
    VK_OEM_COMMA:  // ,
      begin
        MPVPlayer.Command(['frame-back-step']);
        Key := 0;
      end;

    VK_OEM_PERIOD: // .
      begin
        MPVPlayer.Command(['frame-step']);
        Key := 0;
      end;

    // Volume
    VK_UP:
      begin
        MPVPlayer.Command(['add', 'volume', '5']);
        Key := 0;
      end;

    VK_DOWN:
      begin
        MPVPlayer.Command(['add', 'volume', '-5']);
        Key := 0;
      end;

    Ord('9'):
      begin
        MPVPlayer.Command(['add', 'volume', '-2']);
        Key := 0;
      end;

    Ord('0'):
      begin
        MPVPlayer.Command(['add', 'volume', '2']);
        Key := 0;
      end;

    Ord('M'):
      begin
        MPVPlayer.Command(['cycle', 'mute']);
        Key := 0;
      end;

    // Playback speed
    VK_OEM_4: // [ : -10% (clamp)
      begin
        LSpeed := 1.0;
        MPVPlayer.GetPropertyDouble('speed', LSpeed);
        SetSpeed(LSpeed * 0.9091);
        Key := 0;
      end;

    VK_OEM_6: // ] : +10% (clamp)
      begin
        LSpeed := 1.0;
        MPVPlayer.GetPropertyDouble('speed', LSpeed);
        SetSpeed(LSpeed * 1.1);
        Key := 0;
      end;

    Ord('Z'): // reset speed to 1.0 (PotPlayer style)
      if Shift = [] then
      begin
        SetSpeed(1.0);
        Key := 0;
      end;

    Ord('X'): // speed -0.1
      if Shift = [] then
      begin
        AddSpeed(-0.1);
        Key := 0;
      end;

    Ord('C'): // speed +0.1
      if Shift = [] then
      begin
        AddSpeed(0.1);
        Key := 0;
      end;

    // Pause (if no video, play next track)
    VK_SPACE:
      begin
        FrmList.Play('');
        Key := 0;
      end;

    Ord('P'):
      begin
        MPVPlayer.Command(['cycle', 'pause']);
        Key := 0;
      end;

    // Subtitles
    Ord('V'):
      begin
        MPVPlayer.Command(['cycle', 'sub-visibility']);
        Key := 0;
      end;

    Ord('J'):
      begin
        if ssShift in Shift then
          MPVPlayer.Command(['cycle', 'sub', 'down'])
        else
          MPVPlayer.Command(['cycle', 'sub']);
        Key := 0;
      end;

    // Screenshot
    Ord('S'):
      begin
        MPVPlayer.Command(['screenshot']);
        Key := 0;
      end;

    // Screen
    VK_RETURN:
      begin
        MPVPlayer.Command(['cycle', 'fullscreen']);
        Key := 0;
      end;

    Ord('F'):
      begin
        MPVPlayer.Command(['cycle', 'fullscreen']);
        Key := 0;
      end;

    VK_ESCAPE:
      begin
        // mpv fullscreen 속성을 단일 상태원으로 유지 (observer가 HandleFullScreen 호출)
        if WindowState = wsMaximized then
          MPVPlayer.Command(['set', 'fullscreen', 'no']);
        Key := 0;
      end;

    // Playlist
    VK_NEXT:  // PageDown
      begin
        FrmList.Next;
        Key := 0;
      end;

    VK_PRIOR: // PageUp
      begin
        FrmList.Prev;
        Key := 0;
      end;

    // Exit
    {
    Ord('Q'):
      begin
        HandleClose;
        Key := 0;
      end;
    }
  end;
end;

// Mouse input
procedure TFrmKPlayer.WMMouseWheel(var Msg: TWMMouseWheel);
begin
  if MPVPlayer = nil then Exit;

  if Msg.WheelDelta > 0 then
    MPVPlayer.Command(['seek', '-5'])
  else
    MPVPlayer.Command(['seek', '5']);

  Msg.Result := 1;
end;

// 왼쪽 버튼 상태를 KPlayer.lua 로. 바뀔 때만 보낸다.
procedure TFrmKPlayer.SendLeftButton(ADown: Boolean);
begin
  if FLeftDown = ADown then Exit;
  FLeftDown := ADown;

  if MPVPlayer = nil then Exit;
  if ADown then
    MPVPlayer.Command(['script-message', 'mbtn', '1'])
  else
    MPVPlayer.Command(['script-message', 'mbtn', '0']);
end;

procedure TFrmKPlayer.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Dragging: Boolean;
begin
  Dragging := False;

  if Button = mbLeft then
  begin
    if (WindowState <> wsMaximized) and (not FOverControl) then
    begin
      Dragging := True;
      ReleaseCapture;
      Perform(WM_NCLBUTTONDOWN, HTCAPTION, 0);
    end;
  end;

  if MPVPlayer = nil then Exit;
  if Dragging then Exit;

  case Button of
    mbLeft:   MPVPlayer.Command(['keydown', 'MBTN_LEFT']);
    mbMiddle: MPVPlayer.Command(['keydown', 'MBTN_MID']);
  end;

  if Button = mbLeft then
    SendLeftButton(True);
end;

procedure TFrmKPlayer.FormMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if MPVPlayer = nil then Exit;

  if (X <> FLastMouseX) or (Y <> FLastMouseY) then
  begin
    FLastMouseX := X;
    FLastMouseY := Y;
    MPVPlayer.Command(['mouse', IntToStr(X), IntToStr(Y)]);
  end;

  SendLeftButton(ssLeft in Shift);
end;

procedure TFrmKPlayer.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if MPVPlayer = nil then Exit;

  case Button of
    mbLeft:   MPVPlayer.Command(['keyup', 'MBTN_LEFT']);
    mbMiddle: MPVPlayer.Command(['keyup', 'MBTN_MID']);
  end;

  if Button = mbLeft then
    SendLeftButton(False);
end;

end.
