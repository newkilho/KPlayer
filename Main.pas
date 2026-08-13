{===============================================================================

Project : KPlayer
Author  : Kilho, Oh
Engine  : libmpv (GPL-2.0-or-later)
Tree    : Virtual Treeview (MPL 1.1)

This program links against libmpv (GPL-2.0-or-later).
When distributed in binary form, the complete corresponding
source code must be made available under the GPL.

Icon: https://www.flaticon.com/free-icon/play_2377793

해야할일:
=========
  [+] 설치 프로그램 실행시 간단한 소개 추가
  [+] 설치 후 첫 실행시 파일 연결 등록(레지스터리)

히스토리:
========
  0.9.6
  [+] 일괄 추가+재생 함수 추가 - 새로 들어간 첫 항목 판별, 추가 루프 BeginUpdate/EndUpdate (TFrmList.AddFiles)
  [*] 드롭 시 폴더/비지원 확장자/재생목록 경로가 그대로 재생되어 "파일을 찾을 수 없습니다 - <폴더명>" 후 재생 안 되던 문제 - 드롭 경로 대신 목록 항목부터 재생 (Main.FormCreate FDragFile, TFrmList.FormCreate FDragFile)

  0.9.5
  [*] 시작 시 저장 목록을 디스크 확인 없이 로드 - 네트워크 드라이브 타임아웃으로 창 표시가 늦던 문제, 없는 파일은 재생 시 SkipMissing 이 정리 (List.pas: LoadPlaylist, AddFile ACheckDisk 파라미터)
  [*] 시작 로드의 중복 검사를 전체 노드 탐색(O(n²)) 대신 줄 단위 정렬 필터로 변경 (List.pas: LoadPlaylist)
  [*] 시작 로드의 목록 추가를 BeginUpdate/EndUpdate 로 묶음 (List.pas: LoadPlaylist)

  0.9.4
  [*] 랜덤 재생이 한 바퀴 끝나면 반복 설정과 무관하게 새 사이클을 시작 (List.pas: Rand)
  [+] 없는 파일은 재생 시 목록에서 빼고 다음 곡으로 (List.pas: SkipMissing)
  [+] 목록에서 Del 키로 선택 항목 삭제 (List.pas: ListDataKeyDown)
  [+] 환경설정 '일반' 에 항상 위 - SetWindowPos 방식 (Main.pas: SetTopMost)
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
  [+] 확장자별 파일 연결 아이콘 - exe 옆 Icon\<확장자>.ico 사용, 없으면 exe 아이콘으로 폴백 (Assoc.pas: ExtIconRef, AssocRegister)
  [+] 제거 시 파일 연결 원복 - KPlayer.exe /uninst 로 등록분 전체 해제 후 창 없이 종료 (KPlayer.dpr, Assoc.pas: AssocUnregisterAll)
  [*] 연결 해제를 확장자 기반으로 분리 - 노출 목록(AssocExts)에서 빠진 확장자도 소유 목록으로 해제 (Assoc.pas: AssocUnregisterExt)
  [+] Inno Setup 설치 스크립트 추가 - 사용자별 설치(%LOCALAPPDATA%\Programs\KPlayer), Icon 폴더 동봉 (KPlayer.iss)

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

const
  // Lua 중앙 알림 색 (RGB hex, KPlayer.lua 가 ASS BGR 로 반전). 기본 파라미터에 쓰여 클래스 선언보다 앞 필수.
  ALERT_INFO  = 'FFFFFF';
  ALERT_WARN  = 'FFC048';
  ALERT_ERROR = 'FF5555';

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
    function IsLoaded: Boolean;
    function IsEOF: Boolean;
    procedure SetPause(AState: Boolean);
    procedure Alert(const AMsg: string; const AColor: string = ALERT_INFO);

    procedure HandlePlay(const AFile: string);
    procedure HandleStop;
    procedure HandlePause;
    procedure HandleStartupParams;
    procedure SetTopMost(AState: Boolean);

    property Config: TConfig read FConfig;
    property Volume: Double read FVolume write SetVolume;
    property RepeatMode: Integer read FRepeatMode write SetRepeatMode;
    property RandomMode: Integer read FRandomMode write SetRandomMode;
  end;

var
  FrmKPlayer: TFrmKPlayer;

implementation

{$R *.dfm}

uses List, Setup, Assoc;

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

  if ReportMemoryLeaksOnShutDown then Theme := 'n:\Release\KPlayer.lua' else // 디버그
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

  // 자막 기본 끔 — 자막 버튼으로 켬
  if FConfig.ReadInteger('sub_visible', 0) <> 0 then
    MPVPlayer.SetOptionString('sub-visibility', 'yes')
  else
    MPVPlayer.SetOptionString('sub-visibility', 'no');

  MPVPlayer.SetOptionString('sub-font-size', IntToStr(FConfig.ReadInteger('sub_size', 55)));
  MPVPlayer.SetOptionString('slang', FConfig.ReadString('sub_lang', 'ko,kor,en,eng'));

  // 환경설정 '영상' 카드 값 — 재시작 시에만 반영
  MPVPlayer.SetOptionString('vo', CfgOpt('vo', VoValues)); // 기본 = gpu-next 아닌 안정 버전
  MPVPlayer.SetOptionString('hwdec', CfgOpt('hwdec', HwdecValues));
  MPVPlayer.SetOptionString('gpu-api', CfgOpt('gpu_api', GpuApiValues));
  MPVPlayer.SetOptionString('video-sync', CfgOpt('video_sync', VideoSyncValues));

  // 영상 안정화 (필요시만 적용)
  MPVPlayer.SetOptionString('deinterlace', CfgOpt('deinterlace', DeintValues));

  // 스케일링 (품질/안정 균형)
  MPVPlayer.SetOptionString('scale', CfgOpt('scale', ScaleValues));
  MPVPlayer.SetOptionString('cscale', 'bilinear');

  // mpv 로그: 기본 미사용
  LLogFile := '';
  {$IFDEF DEBUG}
  //LLogFile := ExtractFilePath(ParamStr(0)) + 'KPlayer.log';
  {$ENDIF}

  // 4번째 인자 = 로그 경로, '' = 기록 안 함
  MPVPlayer.InitPlayer(IntToStr(Handle), '', '', LLogFile, True);

  MPVPlayer.Command(['set', 'screenshot-directory', FConfig.ReadString('shot_dir', DesktopPath)]);

  // EOF 시 마지막 프레임 정지 — 래퍼의 keep-open-pause=no 는 EOF 에도 pause=false → OSD 가 재생 중처럼 보임
  MPVPlayer.Command(['set', 'keep-open-pause', 'yes']);

  MPVPlayer.Command(['set', 'screenshot-template', '%f-%n']);
  MPVPlayer.Command(['set', 'screenshot-format', CfgOpt('shot_format', ShotFmtValues)]);
  MPVPlayer.Command(['set', 'volume', FloatToStr(Volume)]);

  // 음량 평준화 (환경설정 '음성' 카드)
  if FConfig.ReadInteger('normalize', 1) <> 0 then
    MPVPlayer.Command(['set', 'af', NormFilters[EnsureRange(FConfig.ReadInteger('norm_level', 1), 0, High(NormFilters))]]);

  MPVPlayer.Command(['load-script', Theme]);

  // OSD 폰트 = 윈도우 UI 기본 폰트
  MPVPlayer.Command(['script-message', 'ui-font', Screen.MessageFont.Name]);

  FDragFile := TDragFile.Create(Self,
  procedure(const Files: TArray<string>)
  begin
    // HandlePlay 직접 호출 시 mpv 만 재생, 목록 '재생 중' 표시 누락 → FrmList 경유.
    // 재생 시작점은 드롭 경로가 아니라 목록에 실제로 들어간 첫 항목 (AddFiles 주석).
    FrmList.AddFiles(Files, not IsPlay);
  end);

  SetTopMost(FConfig.ReadInteger('topmost', 0) <> 0);

  // 파일 연결 exe 경로 재기록 — 포터블 폴더 이동 시 옛 경로 방지
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

  // 전체화면 커서 표시/숨김 — 컨트롤바 표시에 동기화
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

  // 우리가 lua 로 보낸 메시지 (script-message 는 호스트에도 옴) — 무시
  if SameText(ACommand, 'mbtn') or SameText(ACommand, 'ui-font')
  or SameText(ACommand, 'dpi') or SameText(ACommand, 'alert') then
    Exit;

  // 커서가 컨트롤 위인지 — 창 드래그 억제용
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
    FrmList.TrackFinished;
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

// 콤보 인덱스(INI) → mpv 옵션 문자열
function TFrmKPlayer.CfgOpt(const AKey: string; const AValues: array of string): string;
begin
  Result := AValues[EnsureRange(FConfig.ReadInteger(AKey, 0), 0, High(AValues))];
end;

procedure TFrmKPlayer.SetRandomMode(const Value: Integer);
begin
  FRandomMode := Value;
  FConfig.WriteInteger('random', Value);

  if FrmList <> nil then
    FrmList.UpdateModeIcons;
end;

procedure TFrmKPlayer.SetRepeatMode(const Value: Integer);
begin
  FRepeatMode := Value;
  FConfig.WriteInteger('repeat', Value);

  // 목록 창 아이콘 즉시 갱신 — FormCreate 의 INI 읽기 시점엔 FrmList 없음
  if FrmList <> nil then
    FrmList.UpdateModeIcons;
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

// 항상 위 ('일반' 카드). fsStayOnTop 금지 — VCL 핸들 재생성 시 mpv wid 무효 → 영상 사라짐.
// 재생목록 창도 같이 올림 (본체만 올리면 목록이 뒤로 숨음).
procedure TFrmKPlayer.SetTopMost(AState: Boolean);
const
  SWP_FLAGS = SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE;
var
  LAfter: HWND;
begin
  if AState then
    LAfter := HWND_TOPMOST
  else
    LAfter := HWND_NOTOPMOST;

  SetWindowPos(Handle, LAfter, 0, 0, 0, 0, SWP_FLAGS);

  if (FrmList <> nil) and FrmList.HandleAllocated then
    SetWindowPos(FrmList.Handle, LAfter, 0, 0, 0, 0, SWP_FLAGS);
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
    Screen.Cursor := crDefault;   // 창모드는 항상 커서 표시 (안전장치)
  end;
end;

procedure TFrmKPlayer.HandleZoomIn(AStep: Double);
var
  LCur: Double;
begin
  LCur := 0;
  MPVPlayer.GetPropertyDouble('video-zoom', LCur);
  MPVPlayer.SetPropertyDouble('video-zoom', LCur + AStep);
end;

procedure TFrmKPlayer.HandleZoomOut(AStep: Double);
var
  LCur: Double;
begin
  LCur := 0;
  MPVPlayer.GetPropertyDouble('video-zoom', LCur);
  MPVPlayer.SetPropertyDouble('video-zoom', LCur - AStep);
end;

// 파일 열림 여부 (일시정지도 True) — IsPlay 와 달리 idle 판정용
function TFrmKPlayer.IsLoaded: Boolean;
var
  LName: string;
begin
  Result := False;
  if MPVPlayer = nil then Exit;

  MPVPlayer.GetPropertyString('filename', LName);
  Result := LName <> '';
end;

// EOF 정지 상태인가 (keep-open 이 마지막 프레임 유지 중)
function TFrmKPlayer.IsEOF: Boolean;
var
  LEOF: string;
begin
  Result := False;
  if MPVPlayer = nil then Exit;

  MPVPlayer.GetPropertyString('eof-reached', LEOF);
  Result := SameText(LEOF, 'yes');
end;

// 화면 중앙 일시 알림 — 표시/소멸은 KPlayer.lua. 색 = RGB hex (ALERT_* 상수)
procedure TFrmKPlayer.Alert(const AMsg: string; const AColor: string);
begin
  if (MPVPlayer = nil) or (AMsg = '') then Exit;

  MPVPlayer.Command(['script-message', 'alert', AMsg, AColor]);
end;

procedure TFrmKPlayer.SetPause(AState: Boolean);
const
  YesNo: array[Boolean] of string = ('no', 'yes');
begin
  if MPVPlayer <> nil then
    MPVPlayer.Command(['set', 'pause', YesNo[AState]]);
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

procedure TFrmKPlayer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  LSpeed: Double;
begin
  if MPVPlayer = nil then Exit;

  case Key of
    // 탐색
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

    // 프레임 이동
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

    // 음량
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

    // 배속
    VK_OEM_4: // [ : 배속 -10%
      begin
        LSpeed := 1.0;
        MPVPlayer.GetPropertyDouble('speed', LSpeed);
        SetSpeed(LSpeed * 0.9091);
        Key := 0;
      end;

    VK_OEM_6: // ] : 배속 +10%
      begin
        LSpeed := 1.0;
        MPVPlayer.GetPropertyDouble('speed', LSpeed);
        SetSpeed(LSpeed * 1.1);
        Key := 0;
      end;

    Ord('Z'): // 배속을 1.0 으로
      if Shift = [] then
      begin
        SetSpeed(1.0);
        Key := 0;
      end;

    Ord('X'): // 배속 -0.1
      if Shift = [] then
      begin
        AddSpeed(-0.1);
        Key := 0;
      end;

    Ord('C'): // 배속 +0.1
      if Shift = [] then
      begin
        AddSpeed(0.1);
        Key := 0;
      end;

    // 일시정지 — 열린 파일 없으면 다음 곡
    VK_SPACE:
      begin
        FrmList.Play('');
        Key := 0;
      end;

    // 자막
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

    // 스크린샷
    Ord('S'):
      begin
        MPVPlayer.Command(['screenshot']);
        Key := 0;
      end;

    // 화면
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
        // mpv fullscreen 속성 = 단일 상태원 (observer → HandleFullScreen)
        if WindowState = wsMaximized then
          MPVPlayer.Command(['set', 'fullscreen', 'no']);
        Key := 0;
      end;

    // 재생목록
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

    // 종료
    {
    Ord('Q'):
      begin
        HandleClose;
        Key := 0;
      end;
    }
  end;
end;

procedure TFrmKPlayer.WMMouseWheel(var Msg: TWMMouseWheel);
begin
  if MPVPlayer = nil then Exit;

  if Msg.WheelDelta > 0 then
    MPVPlayer.Command(['seek', '-5'])
  else
    MPVPlayer.Command(['seek', '5']);

  Msg.Result := 1;
end;

// 왼쪽 버튼 상태 → KPlayer.lua
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
