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

히스토리:
========
  1.0.1.0
  [*] 우클릭 '화면 크기' 항목명을 50% / 100% / 150% / 200% 로 - '원본 화면 (n.nx)' 넷은 어색, PotPlayer·GOM 관례, 번역 불필요 (Main.dfm: MnuOrig50~200 / Main.pas: FormCreate / Translate.txt: '원본 화면' 그룹 제거)

  1.0.0.0
  [+] 설치 직후 주요 확장자 자동 연결 - 인스톨러 [Run] 이 /inst 로 실행하면 등록 후 평소처럼 계속 실행 (Assoc.pas: AssocRegisterMain / Main.pas: FormCreate / KPlayer.iss: [Run])
  [*] 파일 연결 아이콘을 exe 리소스로 - Icon\*.ico 를 Tools\MakeIconRes.py 가 RT_ICON 1000+/RT_GROUP_ICON 40000+ 로 KPlayerIcons.res 생성(MAINICON 과 ID 충돌 회피), DefaultIcon = "exe",-ID, exe 옆 Icon\ 폴더·설치본 항목 제거 (Assoc.pas: ExtIconRef, IconIds.inc / KPlayer.dpr / KPlayer.iss)
  [*] KPlayer.lua 를 exe 리소스(RCDATA 'script')에 내장 - 실행 시 %TEMP%\KPlayer\ 에 풀어 load-script, exe 옆 파일 불필요, 설치본에서 제외 (Main.pas: ExtractScript, FormCreate / KPlayerResource.rc / KPlayer.iss)
  [+] 시작 화면 원 로고를 버튼으로 - 클릭 시 목록 있으면 첫 항목 재생, 없으면 파일 열기 대화상자, 마우스 올리면 밝아짐, 창 드래그 억제 (KPlayer.lua: hover_logo, check_hover, alpha.logo_*_hover / Main.pas: OnScriptMessage 'logo')
  [+] 우클릭 '만든이 오길호' 클릭 시 홈페이지(go.kilho.net/kplayer) 열기 (Main.pas: BtnAboutClick / Const.inc: AppHome)
  [+] 우클릭 메뉴에 '파일 열기'/'폴더 열기' - 화면 크기 위, 구분선 (Main.pas: MnuOpenFileClick, MnuOpenFolderClick / Main.dfm: MnuOpenFile, MnuOpenFolder / List.pas: OpenFolder)
  [+] 파일 열기 단축키 Ctrl+O - 환경설정 '단축키' 재생목록 위, 목록 창 [추가] 와 같은 대화상자, 필터는 AssocExts 38종 (미디어/비디오/오디오/모든 파일) (Hotkey.pas: kaOpenFile / List.pas: OpenFiles, BtnAddPopupClick / Main.pas: ExecAction)
  [*] 두 번째 실행부터 둥근 모서리가 사라지던 문제 - RestoreWindow 의 Position := poDesigned 가 핸들을 재생성해 SetFormCorners 무효, DFM 을 poDesigned 로 고정하고 미저장 시 직접 가운데 배치 (Main.pas: RestoreWindow / Main.dfm: Position)
  [+] 환경설정 '마우스' 카드 - 왼쪽 클릭/더블클릭/가운데 버튼/휠 위아래 마다 기능 선택 (팟플레이어 방식), 왼쪽 클릭은 이동 없이 뗀 뒤 더블클릭 시간만큼 지연 (Hotkey.pas: MouseDefs, MouseMap, LoadMouse / Main.pas: ExecMouse, FormMouseDown, ClickTimerTick, WMMouseWheel / Setup.pas: CardMouse, FMouseCbo)
  [+] 환경설정 '단축키' 카드 - 동작 29종의 키를 지정/해제/기본값, 중복 키는 이전 동작에서 자동 해제, INI key_* (TShortCut 정수) (Hotkey.pas: KeyDefs, KeyMap, LoadKeys, SaveKey, FindKeyAction / Main.pas: FormKeyDown, ExecAction / Setup.pas: CardKeys, FillKeys, EdtKeyKeyDown)
  [*] 기본 자막 언어를 OS 언어에서 계산 (2자+3자 코드 + 영어 폴백), 직접 고친 값만 INI 기록 - ko 고정이라 타 언어 사용자에게 한국어 자막이 먼저 잡히던 것 (Setup.pas: DefaultSubLang, LoadValues, SaveValues, ApplyLive / Main.pas: FormCreate)
  [+] 캡션에 항상 위 압정 버튼 - 최소화 왼쪽, 꺼짐은 사선 표시, 환경설정 '항상 위' 와 상태 공유 (KPlayer.lua: icons.pin, cap_pin, draw_caption_pin, topmost-state / Main.pas: OnScriptMessage 'topmost', 'topmost-query', SetTopMost, SendTopMost)
  [*] 환경설정에서 글꼴 등 다른 항목을 바꾸면 켜 둔 자막이 꺼지던 문제 - sub-visibility 는 '자막 기본 표시' 콤보를 바꿀 때만 전송 (Setup.pas: ApplyLive, ControlChange)
  [*] 환경설정 카드가 마우스 휠로 스크롤되지 않던 문제 - 포커스 컨트롤 대신 마우스 아래 스크롤박스로 (Setup.pas: MouseWheelHandler)
  [*] 스크린샷 폴더 [찾기] 대화상자가 '항상 위' 창 뒤로 숨던 문제 - 설정 창 소유 TFileOpenDialog 로 교체 (Setup.pas: BtnShotDirClick)
  [*] 환경설정 카드의 설명 라벨 제거, '저장 폴더' → '스크린샷 폴더', 스크롤 하단 여백 (Setup.dfm: VertScrollBar.Margin)
  [+] 환경설정 '자막' 카드에 스타일 옵션 - 글꼴·굵게·글자색·외곽선 두께/색·그림자·세로 위치·정렬·자막 파일 스타일 우선(sub-ass-override) (Setup.pas: ApplySubStyle, FillFonts, BtnSubColorClick / Main.pas: FormCreate / Assoc.pas: SubAlignValues, SubAssValues)
  [*] 컨트롤바 표시 때 자막을 올렸다 내리던 것 제거 - sub-margin-y 40 고정, 마우스만 움직여도 자막이 들썩이던 문제 (KPlayer.lua: update_sub_margin 삭제)
  [+] 우클릭 메뉴 '화면 크기' - 원본 화면 0.5x/1.0x/1.5x/2.0x(영상 픽셀 × 배율) / 전체 화면 / 꽉찬 화면(keepaspect=no), 창모드 복귀 시 비율 복원 (Main.pas: MenuPopup, MnuOriginalClick, EnterFullScreen, HandleFullScreen / Main.dfm: MnuScreen)
  [+] 재생 창 크기 옵션 ('일반' 카드) - 마지막 크기 유지 / 영상 크기에 맞춤 / 전체 화면, 종료 시 창 위치·크기 저장 (Main.pas: RestoreWindow, SaveWindow, ResizeWindow, HandleVideoSize, ApplyWindowMode / MPVPlayer.pas: OnVideoSize, DoEventVideoReconfig / Setup.pas: CboWinSize)

  0.9.8.0
  [+] 목록 창 드롭·[추가] 버튼·폴더 추가도 추가한 첫 항목부터 자동 재생 - 불러왔는데 더블클릭해야 시작되던 혼동 해소 (List.pas: FormCreate FDragFile, BtnAddPopupClick, BtnAddPopupFolderClick)
  [*] 탐색기 더블클릭·명령줄 인자로 재생목록/폴더를 열면 재생이 안 걸리던 문제 - 인자 경로 대신 목록에 들어간 첫 항목부터 재생, 폴더 인자도 처리 (Main.pas: HandleStartupParams / List.pas: AddFiles, AddFile, FAddFirst)
  [*] 없는 파일을 재생 시 목록에서 자동 삭제하던 것 제거 - 항목은 두고 전체 경로로 표시만, 삭제는 [삭제]→없는 파일 (List.pas: SkipMissing, Play)
  [*] 재생 중인 파일이 전체 경로로 표시되던 문제 - 재생 성공 시 Missing 해제 (List.pas: Play)
  [+] 드라이브 연결/해제와 목록 창 표시 때 존재 재검사 - 없음 표시 항목만, 드라이브 통지는 2초 디바운스 (Main.pas: FVerifyTimer, WMDeviceChange, VerifyTimerTick, HandlePlayList / List.pas: StartVerify)
  [*] 존재 확인 스레드가 루트(드라이브/UNC 공유) 단위로 선판정 - 끊긴 공유에서 파일마다 수 초 막히던 것 제거 (List.pas: PathRoot, TFileCheckThread.Execute)
  [*] 부분 재검사 결과가 검사 범위 밖 항목을 덮어쓰지 않도록 확인 목록 전달 (List.pas: ApplyMissing)

  0.9.7.0
  [*] 대량 드롭 시 UI 멈춤 - 추가 시점의 파일 존재 확인 제거, 미디어 확장자면 디스크 접근 없이 바로 추가 (List.pas: AddFile)
  [+] 파일 존재 확인을 배경 스레드로 - 결과만 목록에 반영, 세대 카운터로 이전 검사 취소 (List.pas: TFileCheckThread, StartVerify, ApplyMissing, GVerifyGen)
  [*] 그리기 경로(OnGetText)의 FileExists 제거 - 스레드가 채우는 Missing 캐시 사용 (List.pas: TItemData.Missing, ListDataGetText)
  [*] 일괄 추가 중복 검사를 노드 탐색(O(n²)) 대신 해시표로 (List.pas: FAddSeen, AddFiles, AddFile)
  [*] 시작 로드 후에도 존재 확인을 배경으로 수행 (List.pas: LoadPlaylist)
  [*] 파일/폴더 추가 메뉴도 일괄 추가 경로 사용 (List.pas: BtnAddPopupClick, BtnAddPopupFolderClick)
  [+] 본체 창 드롭은 목록을 비우고 떨군 것만 추가 후 재생, 목록 창 드롭은 기존 목록에 덧붙임 (List.pas: ReplaceFiles / Main.FormCreate FDragFile)
  [*] 무음 상태에서 음량을 조절해 0 이 아니게 되면 무음 해제 (Main.pas: AddVolume, FormKeyDown)
  [+] TAB 으로 재생/파일 정보 패널 토글 - 자체 ASS 패널 1초 갱신, TAB 은 VCL 이 먹으므로 Application.OnMessage 에서 가로챔 (Main.pas: AppMessage, OnScriptMessage 'info' 무시 / KPlayer.lua: ov_info, info_rows, render_info, set_info, script-message 'info')

  0.9.6.0
  [+] 일괄 추가+재생 함수 추가 - 새로 들어간 첫 항목 판별, 추가 루프 BeginUpdate/EndUpdate (TFrmList.AddFiles)
  [*] 드롭 시 폴더/비지원 확장자/재생목록 경로가 그대로 재생되어 "파일을 찾을 수 없습니다 - <폴더명>" 후 재생 안 되던 문제 - 드롭 경로 대신 목록 항목부터 재생 (Main.FormCreate FDragFile, TFrmList.FormCreate FDragFile)
  [+] 다국어 지원 - ko/en/ja/zh/ru/it/fr/es/ar
  [+] 설치 시작 시 소개 화면 추가

  0.9.5.0
  [*] 시작 시 저장 목록을 디스크 확인 없이 로드 - 네트워크 드라이브 타임아웃으로 창 표시가 늦던 문제, 없는 파일은 재생 시 SkipMissing 이 정리 (List.pas: LoadPlaylist, AddFile ACheckDisk 파라미터)
  [*] 시작 로드의 중복 검사를 전체 노드 탐색(O(n²)) 대신 줄 단위 정렬 필터로 변경 (List.pas: LoadPlaylist)
  [*] 시작 로드의 목록 추가를 BeginUpdate/EndUpdate 로 묶음 (List.pas: LoadPlaylist)

  0.9.4.0
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

  0.9.3.0
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

  0.9.2.0
  [*] 실행 인자에 전달된 기존 파일을 재생 목록에 추가하고 첫 파일을 자동 재생하도록 처리

  0.9.1.0
  [*] 렌더링 및 디코딩 기본 옵션 추가 - vo=gpu, hwdec=auto-safe, gpu-api=auto 설정 추가
  [*] 화면 동기화 옵션 추가 - video-sync=display-resample 설정 추가
  [*] 인터레이싱 처리 방식 변경 - deinterlace=yes → deinterlace=auto 로 변경
  [*] 스케일링 옵션 조정 - scale=bilinear → scale=lanczos 변경, cscale=bilinear 유지

================================================================================}

unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils, System.Variants, System.Classes,
  System.Types, System.Math, System.IOUtils, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, MPVBasePlayer, MPVPlayer,
  K.Theme, K.DragFile, K.Config.INI, K.Update, Hotkey;

const
  // Lua 중앙 알림 색 (RGB hex, KPlayer.lua 가 ASS BGR 로 반전). 기본 파라미터에 쓰여 클래스 선언보다 앞 필수.
  ALERT_INFO  = 'FFFFFF';
  ALERT_WARN  = 'FFC048';
  ALERT_ERROR = 'FF5555';

type
  TFrmKPlayer = class(TForm)
    Menu: TPopupMenu;
    BtnAbout: TMenuItem;
    MnuOpenFile: TMenuItem;
    MnuOpenFolder: TMenuItem;
    N2: TMenuItem;
    MnuScreen: TMenuItem;
    MnuOrig50: TMenuItem;    // Tag = 배율 % = 캡션 '50%'~'200%' (숫자라 번역 없음, PotPlayer·GOM 관례. 공용 MnuOriginalClick)
    MnuOrig100: TMenuItem;
    MnuOrig150: TMenuItem;
    MnuOrig200: TMenuItem;
    MnuFull: TMenuItem;
    MnuStretch: TMenuItem;
    N1: TMenuItem;
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
    procedure MenuPopup(Sender: TObject);
    procedure MnuOpenFileClick(Sender: TObject);
    procedure BtnAboutClick(Sender: TObject);
    procedure MnuOpenFolderClick(Sender: TObject);
    procedure MnuOriginalClick(Sender: TObject);
    procedure MnuFullClick(Sender: TObject);
    procedure MnuStretchClick(Sender: TObject);
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
    FVerifyTimer: TTimer;   // 드라이브 변경 통지 뭉침 방지 (WMDeviceChange)
    FFullOnce: Boolean;     // 재생 창 크기 '전체 화면' 은 세션당 1회 (ESC 로 풀면 다음 곡에 다시 안 감)
    FStretch: Boolean;      // 꽉찬 화면 (keepaspect=no) 중 — 전체화면 해제 시 keepaspect 복원 판단
    FClickTimer: TTimer;    // 왼쪽 클릭 기능 지연 — 더블클릭이면 취소 (FormMouseDown / ClickTimerTick)

    procedure SendLeftButton(ADown: Boolean);
    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure OnScriptMessage(ASender: TObject; const ACommand: string; AParams: TStrings);

    procedure ExecAction(AAction: TKeyAction);
    procedure ExecMouse(AEvent: TMouseEvent);
    procedure ClickTimerTick(Sender: TObject);
    procedure HandleClose;
    procedure HandleMinimize;
    procedure HandleZoomIn(AStep: Double);
    procedure HandleZoomOut(AStep: Double);
    procedure HandleFullScreen(AState: Boolean);
    procedure EnterFullScreen(AStretch: Boolean);
    procedure HandleSettings;
    procedure HandlePlayList;
    procedure HandleVideoSize(ASender: TObject; AWidth, AHeight: Integer);
    procedure RestoreWindow;
    procedure SaveWindow;
    procedure ResizeWindow(AWidth, AHeight: Integer);

    procedure WMDeviceChange(var Msg: TMessage); message WM_DEVICECHANGE;
    procedure VerifyTimerTick(Sender: TObject);

    procedure WMNCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMMouseWheel(var Msg: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure SetVolume(const Value: Double);
    procedure SetRandomMode(const Value: Integer);
    procedure SetRepeatMode(const Value: Integer);

    procedure SetSpeed(const Value: Double);
    procedure AddSpeed(const Delta: Double);
    procedure AddVolume(const Delta: Integer);

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
    function ExtractScript: string;
    procedure SetTopMost(AState: Boolean);
    procedure SendTopMost;
    procedure ApplyWindowMode;

    property Config: TConfig read FConfig;
    property Volume: Double read FVolume write SetVolume;
    property RepeatMode: Integer read FRepeatMode write SetRepeatMode;
    property RandomMode: Integer read FRandomMode write SetRandomMode;
  end;

var
  FrmKPlayer: TFrmKPlayer;

implementation

{$R *.dfm}

uses List, Setup, Assoc, K.Translate;

{$I Const.inc}

procedure TFrmKPlayer.FormCreate(Sender: TObject);
var
  LLogFile, LSubLang: string;
begin
  //Lang := 'en';
  Translate(Self);
  Application.Title := Caption;

  BorderStyle := bsNone;
  SetFormCorners(Handle, True);

  FLastMouseX := -1;
  FLastMouseY := -1;

  FConfig := TConfig.Create(AppName);
  LoadKeys(FConfig);   // 단축키 표 (Hotkey.pas) — FormKeyDown 이 본다
  LoadMouse(FConfig);

  FClickTimer := TTimer.Create(Self);
  FClickTimer.Enabled := False;
  FClickTimer.Interval := GetDoubleClickTime;
  FClickTimer.OnTimer := ClickTimerTick;
  RestoreWindow;

  Volume := FConfig.ReadDouble('volume', 100);
  RepeatMode := FConfig.ReadInteger('repeat', 0);
  RandomMode := FConfig.ReadInteger('random', 0);

  // KPlayer.lua 는 exe 리소스(RCDATA 'script') — exe 옆 파일을 읽지 않는다 (1.0.0.0).
  // 디버그는 n:\Release 의 파일이 있으면 그걸로 (빌드 없이 lua 수정 시험).
  Theme := '';
  if ReportMemoryLeaksOnShutDown and FileExists('n:\Release\KPlayer.lua') then
    Theme := 'n:\Release\KPlayer.lua';

  if not MPVLibLoaded(ExtractFilePath(ParamStr(0))) then
  begin
    ShowMessage(_('MPV DLL 로드 실패'));
    Application.Terminate;
    Exit;
  end;

  if Theme = '' then
    Theme := ExtractScript;
  if Theme = '' then
  begin
    Showmessage(_('필수 파일이 없습니다.'));
    Application.Terminate;
    Exit;
  end;

  MPVPlayer := TMPVPlayer.Create;
  MPVPlayer.OnScriptMessage := OnScriptMessage;
  MPVPlayer.OnVideoSize := HandleVideoSize;

  // 파일 없어도 플레이어 종료 방지
  MPVPlayer.SetOptionString('idle', 'yes');

  // 자막 기본 끔 — 자막 버튼으로 켬
  if FConfig.ReadInteger('sub_visible', 0) <> 0 then
    MPVPlayer.SetOptionString('sub-visibility', 'yes')
  else
    MPVPlayer.SetOptionString('sub-visibility', 'no');

  MPVPlayer.SetOptionString('sub-font-size', IntToStr(FConfig.ReadInteger('sub_size', 55)));
  // 기본 자막 언어: '' = OS 언어 기준 (Setup.DefaultSubLang)
  LSubLang := FConfig.ReadString('sub_lang', '');
  if LSubLang = '' then LSubLang := DefaultSubLang;
  MPVPlayer.SetOptionString('slang', LSubLang);

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

  // 자막 스타일 ('자막' 카드) — 글꼴·색·외곽선·위치·ASS 덮어쓰기. 즉시 반영도 같은 함수 (Setup.ApplyLive).
  ApplySubStyle(FConfig, MPVPlayer);

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

  // TAB 은 FormKeyDown 까지 오지 않는다 — VCL 이 포커스 이동(다이얼로그 키)으로 먼저 먹는다.
  // 실측 2026-08-28: 폼이 받은 키를 로그로 찍어보니 Shift(16)·Space(32)·'\'(220) 은 오는데
  // TAB(9) 은 안 왔다. 그래서 VCL 배분 전 단계인 Application.OnMessage 에서 가로챈다.
  Application.OnMessage := AppMessage;

  FDragFile := TDragFile.Create(Self,
  procedure(const Files: TArray<string>)
  begin
    // HandlePlay 직접 호출 시 mpv 만 재생, 목록 '재생 중' 표시 누락 → FrmList 경유.
    // 재생 시작점은 드롭 경로가 아니라 목록에 실제로 들어간 첫 항목 (AddFiles 주석).
    // 본체 창 드롭 = 목록 교체 + 재생. 덧붙이려면 목록 창에 떨군다 (TFrmList.FormCreate).
    FrmList.ReplaceFiles(Files);
  end);

  SetTopMost(FConfig.ReadInteger('topmost', 0) <> 0);

  // 드라이브 연결/해제 통지는 여러 번 연달아 온다 + 붙은 직후엔 아직 못 읽는다 → 2초 뒤 한 번만.
  FVerifyTimer := TTimer.Create(Self);
  FVerifyTimer.Enabled := False;
  FVerifyTimer.Interval := 2000;
  FVerifyTimer.OnTimer := VerifyTimerTick;

  // 설치 직후 (인스톨러 [Run] 이 /inst 로 실행, 칼무리 동일) — 주요 확장자 등록 후 평소처럼 계속 실행.
  // 포터블은 스위치가 없으니 등록 안 됨. 이후 실행은 아래 SyncFileAssoc 이 소유 목록만 유지.
  if FindCmdLineSwitch('inst', ['/'], True) then
    AssocRegisterMain;

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
  Application.OnMessage := nil;   // 폼보다 오래 사는 Application 이 죽은 메서드를 부르지 않게

  SaveWindow;
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

  // 캡션 압정 (KPlayer.lua cap_pin). 상태 정본은 여기 — SetTopMost 가 INI 기록 + lua 회신.
  if SameText(ACommand, 'topmost') then
  begin
    if AParams.Count > 0 then
      SetTopMost(AParams[0] = 'on');
    Exit;
  end;

  // lua 초기화 뒤 현재 상태 요청 (load-script 직후 보낸 것은 유실 가능)
  if SameText(ACommand, 'topmost-query') then
  begin
    SendTopMost;
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
  or SameText(ACommand, 'dpi') or SameText(ACommand, 'alert')
  or SameText(ACommand, 'info') or SameText(ACommand, 'topmost-state') then
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

  // 시작 화면 원 로고 클릭 (KPlayer.lua hover_logo) — 목록 있으면 첫 항목, 없으면 파일 열기
  if SameText(ACommand, 'logo') then
  begin
    if FrmList.ListData.RootNodeCount > 0 then
      FrmList.Next
    else
      FrmList.OpenFiles;
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

  ShowMessage(_('알 수 없는 script-message') + ': ' + ACommand);
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

// 음량 증감. 무음 중이라도 결과 음량이 0 이 아니면 무음 해제 (KPlayer.lua 슬라이더와 동일 규칙).
procedure TFrmKPlayer.AddVolume(const Delta: Integer);
var
  LVol: Double;
  LMute: Boolean;
begin
  if MPVPlayer = nil then Exit;

  MPVPlayer.Command(['add', 'volume', IntToStr(Delta)]);

  LVol := 0;
  // TMPVErrorCode 는 Integer — 음수만 실패 (MPV_ERROR_SUCCESS 는 MPVClient 유닛이라 uses 밖).
  if MPVPlayer.GetPropertyDouble('volume', LVol) < 0 then Exit;
  if LVol <= 0 then Exit;

  LMute := False;
  if (MPVPlayer.GetPropertyBool('mute', LMute) >= 0) and LMute then
    MPVPlayer.SetPropertyBool('mute', False);
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

// USB·네트워크 드라이브가 붙거나 빠지면 목록의 '없는 파일' 판정이 통째로 뒤집힌다.
// 검사 자체는 배경 스레드(TFileCheckThread) 라 여기선 타이머만 다시 건다.
// DBT_DEVNODES_CHANGED 까지 받는 이유 — 매핑 드라이브 복구가 볼륨 통지 없이 오는 경우가 있다.
procedure TFrmKPlayer.WMDeviceChange(var Msg: TMessage);
const
  DBT_DEVICEARRIVAL        = $8000;
  DBT_DEVICEREMOVECOMPLETE = $8004;
  DBT_DEVNODES_CHANGED     = $0007;
begin
  inherited;

  if (Msg.WParam = DBT_DEVICEARRIVAL) or (Msg.WParam = DBT_DEVICEREMOVECOMPLETE) or
     (Msg.WParam = DBT_DEVNODES_CHANGED) then
    if FVerifyTimer <> nil then
    begin
      FVerifyTimer.Enabled := False;   // 통지 뭉침 → 마지막 것 기준으로 재시작
      FVerifyTimer.Enabled := True;
    end;
end;

procedure TFrmKPlayer.VerifyTimerTick(Sender: TObject);
begin
  FVerifyTimer.Enabled := False;

  if FrmList <> nil then
    FrmList.StartVerify(True);   // 재연결로 바뀌는 건 '없음 → 있음' 뿐
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

// 항상 위 ('일반' 카드 + 캡션 압정). fsStayOnTop 금지 — VCL 핸들 재생성 시 mpv wid 무효 → 영상 사라짐.
// 재생목록 창도 같이 올림 (본체만 올리면 목록이 뒤로 숨음).
// 두 곳에서 조작하므로 여기서 INI 까지 기록 — 설정 창은 LoadValues 가 INI 를 다시 읽어 콤보가 맞는다.
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

  if FConfig <> nil then
    FConfig.WriteInteger('topmost', Ord(AState));
  SendTopMost;
end;

// 캡션 압정 표시 동기화 (KPlayer.lua topmost-state)
procedure TFrmKPlayer.SendTopMost;
const
  OnOff: array[Boolean] of string = ('off', 'on');
begin
  if MPVPlayer = nil then Exit;
  MPVPlayer.Command(['script-message', 'topmost-state',
    OnOff[FConfig.ReadInteger('topmost', 0) <> 0]]);
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
    if FStretch then
    begin
      FStretch := False;   // 꽉찬 화면은 전체화면에서만 — 창모드 복귀 시 비율 복원
      MPVPlayer.Command(['set', 'keepaspect', 'yes']);
    end;
  end;
end;

// 우클릭 '화면 크기'. 전체 화면 = 비율 유지 / 꽉찬 화면 = keepaspect=no 로 여백 없이 늘림.
// 전체화면 진입은 mpv fullscreen 속성 경유 (observer → HandleFullScreen, 단일 상태원).
procedure TFrmKPlayer.EnterFullScreen(AStretch: Boolean);
begin
  FStretch := AStretch;
  if AStretch then
    MPVPlayer.Command(['set', 'keepaspect', 'no'])
  else
    MPVPlayer.Command(['set', 'keepaspect', 'yes']);
  MPVPlayer.Command(['set', 'fullscreen', 'yes']);
end;

procedure TFrmKPlayer.MenuPopup(Sender: TObject);
var
  HasVideo: Boolean;
begin
  HasVideo := (MPVPlayer <> nil) and (MPVPlayer.VideoWidth > 0);   // 체크 표시는 안 함 (사용자 결정)
  MnuOrig50.Enabled  := HasVideo;
  MnuOrig100.Enabled := HasVideo;
  MnuOrig150.Enabled := HasVideo;
  MnuOrig200.Enabled := HasVideo;
end;

// 우클릭 '만든이' → 홈페이지 (Const.inc AppHome)
procedure TFrmKPlayer.BtnAboutClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar(AppHome), nil, nil, SW_SHOWNORMAL);
end;

// 우클릭 '파일 열기'/'폴더 열기' — 목록 창 [추가] 메뉴·Ctrl+O 와 같은 경로
procedure TFrmKPlayer.MnuOpenFileClick(Sender: TObject);
begin
  FrmList.OpenFiles;
end;

procedure TFrmKPlayer.MnuOpenFolderClick(Sender: TObject);
begin
  FrmList.OpenFolder;
end;

// 화면 크기 n% = 창을 영상 픽셀 크기 × 배율(Tag %) 로 (화면보다 크면 비율 축소 — ResizeWindow). 전체화면 중이면 먼저 해제.
procedure TFrmKPlayer.MnuOriginalClick(Sender: TObject);
var
  Pct: Integer;
begin
  Pct := (Sender as TMenuItem).Tag;
  if WindowState = wsMaximized then
  begin
    MPVPlayer.Command(['set', 'fullscreen', 'no']);
    // observer 경유 해제는 비동기 (lua → script-message → Synchronize) → 지금 바로 창모드로.
    // 나중에 오는 HandleFullScreen(False) 재호출은 무해 (멱등).
    HandleFullScreen(False);
  end;
  if MPVPlayer.VideoWidth > 0 then
    ResizeWindow(MPVPlayer.VideoWidth * Pct div 100, MPVPlayer.VideoHeight * Pct div 100);
end;

procedure TFrmKPlayer.MnuFullClick(Sender: TObject);
begin
  EnterFullScreen(False);
end;

procedure TFrmKPlayer.MnuStretchClick(Sender: TObject);
begin
  EnterFullScreen(True);
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

// 재생 창 크기 ('일반' 카드 win_mode): 0=마지막 크기 유지 / 1=영상 크기에 맞춤 / 2=전체 화면.
// ('지정 크기' 는 넣었다 뺐다 — 2026-09-11 사용자 결정. 우클릭 '화면 크기' 배율로 충분.)
// mpv autofit/geometry 는 wid 임베드라 무효 (창 주인이 Delphi) → 여기서 직접.
// 시작 시 크기·위치는 항상 마지막 값. 문의 (2026-09-11): 640×400 고정이라 매번 늘려야 했다.
procedure TFrmKPlayer.RestoreWindow;
var
  R: TRect;
  L, T, W, H: Integer;
begin
  W := FConfig.ReadInteger('win_width', 640);
  H := FConfig.ReadInteger('win_height', 400);
  W := Max(W, 384);   // FormCanResize 하한
  H := Max(H, 216);

  L := FConfig.ReadInteger('win_left', MaxInt);
  T := FConfig.ReadInteger('win_top', MaxInt);
  if (L = MaxInt) or (T = MaxInt) then
  begin
    // 위치 미저장 → 주 모니터 가운데. DFM 은 poDesigned 고정 — Position 을 런타임에 바꾸면
    // RecreateWnd 로 핸들이 바뀌어 FormCreate 의 SetFormCorners 가 날아간다 (둥근 모서리 사라짐, 2026-09-13).
    R := Screen.WorkAreaRect;
    SetBounds(R.Left + (R.Width - W) div 2, R.Top + (R.Height - H) div 2, W, H);
    Exit;
  end;

  // 저장된 모니터가 빠졌거나 해상도가 줄었을 수 있다 → 그 자리의 작업 영역 안으로 당김.
  R := Screen.MonitorFromPoint(Point(L + W div 2, T + H div 2)).WorkareaRect;
  W := Min(W, R.Width);
  H := Min(H, R.Height);
  L := EnsureRange(L, R.Left, R.Right - W);
  T := EnsureRange(T, R.Top, R.Bottom - H);
  SetBounds(L, T, W, H);
end;

// 전체화면(wsMaximized) 중 종료면 안 쓴다 — 최대화 좌표가 '마지막 크기' 로 남으면 안 됨.
procedure TFrmKPlayer.SaveWindow;
begin
  if (FConfig = nil) or (WindowState <> wsNormal) then Exit;
  FConfig.WriteInteger('win_left', Left);
  FConfig.WriteInteger('win_top', Top);
  FConfig.WriteInteger('win_width', Width);
  FConfig.WriteInteger('win_height', Height);
end;

// 창 중심 고정 리사이즈. 작업 영역 초과분은 비율 유지해 축소, 하한 384×216, 화면 밖이면 안으로.
procedure TFrmKPlayer.ResizeWindow(AWidth, AHeight: Integer);
var
  R: TRect;
  S: Double;
  L, T: Integer;
begin
  R := Monitor.WorkareaRect;
  if (AWidth > R.Width) or (AHeight > R.Height) then
  begin
    S := Min(R.Width / AWidth, R.Height / AHeight);
    AWidth := Round(AWidth * S);
    AHeight := Round(AHeight * S);
  end;
  AWidth := Max(AWidth, 384);
  AHeight := Max(AHeight, 216);

  L := EnsureRange(Left + (Width - AWidth) div 2, R.Left, R.Right - AWidth);
  T := EnsureRange(Top + (Height - AHeight) div 2, R.Top, R.Bottom - AHeight);
  SetBounds(L, T, AWidth, AHeight);
end;

// 파일별 첫 영상 크기 (MPVPlayer.OnVideoSize, UI 스레드). 오디오 전용은 안 온다.
// 맞춤은 곡마다 적용 (팟플레이어 동일). 목록에 해상도가 섞이면 창이 곡마다 바뀐다 —
// 거슬린다는 문의 오면 '첫 파일만' 옵션 추가.
procedure TFrmKPlayer.HandleVideoSize(ASender: TObject; AWidth, AHeight: Integer);
var
  Mode: Integer;
begin
  Mode := FConfig.ReadInteger('win_mode', 0);

  if Mode = 2 then
  begin
    if not FFullOnce then
    begin
      FFullOnce := True;
      MPVPlayer.Command(['set', 'fullscreen', 'yes']);   // 단일 상태원 → observer → HandleFullScreen
    end;
    Exit;
  end;

  if WindowState <> wsNormal then Exit;   // 전체화면·최소화 중엔 창 안 건드림

  if Mode = 1 then
    ResizeWindow(AWidth, AHeight);
end;

// 환경설정에서 바꾼 즉시 반영 (Setup.ApplyLive). 전체 화면 모드는 여기서 안 켠다 — 설정 창 위로 덮인다.
procedure TFrmKPlayer.ApplyWindowMode;
begin
  if WindowState <> wsNormal then Exit;
  if (FConfig.ReadInteger('win_mode', 0) = 1) and (MPVPlayer <> nil) and (MPVPlayer.VideoWidth > 0) then
    ResizeWindow(MPVPlayer.VideoWidth, MPVPlayer.VideoHeight);
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
    FrmList.StartVerify(True);   // 없음 표시된 항목만 재확인 (전수 검사는 부하)
    R := Self.Monitor.WorkareaRect;

    FrmList.Left := R.Right - FrmList.Width;
    FrmList.Top  := R.Bottom - FrmList.Height;

    FrmList.Show;
  end;
end;

// 탐색기 더블클릭 / '연결 프로그램' / 명령줄로 들어온 경로.
// 인자를 그대로 Play 하면 안 된다 (AddFiles 주석과 같은 이유) — 재생목록(.m3u/.pls)은
// 항목이 아니라 내부 경로로 펼쳐지고, 폴더는 내용물만 항목이 되며, 비지원 확장자는
// 걸러진다. 셋 다 '목록에 없는 경로' 라 Play 가 그대로 mpv 에 넘겨 무반응이었다
// (재생목록을 열면 목록엔 들어오는데 재생이 안 걸려 더블클릭해야 시작됐다 — 2026-08-29 문의).
// → 드롭과 같은 AddFiles 로 넘겨 '목록에 실제로 들어간 첫 항목' 부터 재생.
// FileExists 로 거르지 않는다 — 폴더 인자가 통째로 무시됐다. 존재 확인은 AddFiles 의 배경 검사.
// 리소스 'script' 를 %TEMP%\KPlayer\KPlayer.lua 로 풀고 경로 반환 ('' = 실패). mpv load-script 는 파일 경로만
// 받으므로 문자열 로드 불가. 내용이 같으면 다시 쓰지 않는다 — 다른 인스턴스가 읽는 중 덮어쓰는 경우 회피.
function TFrmKPlayer.ExtractScript: string;
var
  Res: TResourceStream;
  Data: TBytes;
  Dir: string;
begin
  Result := '';
  if FindResource(HInstance, 'script', RT_RCDATA) = 0 then Exit;

  Res := TResourceStream.Create(HInstance, 'script', RT_RCDATA);
  try
    SetLength(Data, Res.Size);
    if Res.Size > 0 then
      Res.ReadBuffer(Data[0], Res.Size);
  finally
    Res.Free;
  end;

  try
    Dir := TPath.Combine(TPath.GetTempPath, AppName);
    TDirectory.CreateDirectory(Dir);
    Result := TPath.Combine(Dir, 'KPlayer.lua');
    if not (TFile.Exists(Result) and (TFile.ReadAllBytes(Result) = Data)) then
      TFile.WriteAllBytes(Result, Data);
  except
    Result := '';
  end;
end;

procedure TFrmKPlayer.HandleStartupParams;
var
  I: Integer;
  FileName: string;
  Files: TArray<string>;
begin
  for I := 1 to ParamCount do
  begin
    FileName := ParamStr(I);

    // 스위치(/uninst 등)는 KPlayer.dpr 이 처리 — 여기선 경로만.
    if (FileName = '') or CharInSet(FileName[1], ['/', '-']) then
      Continue;

    Files := Files + [FileName];
  end;

  if Length(Files) = 0 then
    Exit;

  FrmList.AddFiles(Files, not IsPlay);
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

// 키 → 동작은 Hotkey.KeyMap (환경설정 '단축키' 카드에서 변경). 여기 남는 건 고정 키뿐.
procedure TFrmKPlayer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  A: TKeyAction;
begin
  if MPVPlayer = nil then Exit;

  case Key of
    VK_ESCAPE:
      begin
        // mpv fullscreen 속성 = 단일 상태원 (observer → HandleFullScreen)
        if WindowState = wsMaximized then
          MPVPlayer.Command(['set', 'fullscreen', 'no']);
        Key := 0;
      end;
  else
    if FindKeyAction(ShortCut(Key, Shift), A) then
    begin
      ExecAction(A);
      Key := 0;
    end;
  end;
end;

// 단축키 동작 본체 (옛 FormKeyDown case 문). 표 순서 = Hotkey.TKeyAction.
procedure TFrmKPlayer.ExecAction(AAction: TKeyAction);
var
  LSpeed: Double;
begin
  if MPVPlayer = nil then Exit;

  case AAction of
    kaPause:         FrmList.Play('');   // 열린 파일 없으면 다음 곡
    kaSeekBack:      MPVPlayer.Command(['seek', '-5']);
    kaSeekFwd:       MPVPlayer.Command(['seek', '5']);
    kaSeekBackExact: MPVPlayer.Command(['seek', '-1', 'exact']);
    kaSeekFwdExact:  MPVPlayer.Command(['seek', '1', 'exact']);
    kaChapterPrev:   MPVPlayer.Command(['add', 'chapter', '-1']);
    kaChapterNext:   MPVPlayer.Command(['add', 'chapter', '1']);
    kaFrameBack:     MPVPlayer.Command(['frame-back-step']);
    kaFrameFwd:      MPVPlayer.Command(['frame-step']);
    kaVolUp:         AddVolume(5);
    kaVolDown:       AddVolume(-5);
    kaVolUpFine:     AddVolume(2);
    kaVolDownFine:   AddVolume(-2);
    kaMute:          MPVPlayer.Command(['cycle', 'mute']);
    kaSpeedDown10, kaSpeedUp10:
      begin
        LSpeed := 1.0;
        MPVPlayer.GetPropertyDouble('speed', LSpeed);
        if AAction = kaSpeedDown10 then
          SetSpeed(LSpeed * 0.9091)
        else
          SetSpeed(LSpeed * 1.1);
      end;
    kaSpeedDown:     AddSpeed(-0.1);
    kaSpeedUp:       AddSpeed(0.1);
    kaSpeedReset:    SetSpeed(1.0);
    kaSubToggle:     MPVPlayer.Command(['cycle', 'sub-visibility']);
    kaSubNext:       MPVPlayer.Command(['cycle', 'sub']);
    kaSubPrev:       MPVPlayer.Command(['cycle', 'sub', 'down']);
    kaScreenshot:    MPVPlayer.Command(['screenshot']);
    kaFullScreen:    MPVPlayer.Command(['cycle', 'fullscreen']);
    kaListPrev:      FrmList.Prev;
    kaListNext:      FrmList.Next;
    kaOpenFile:      FrmList.OpenFiles;
    kaPlayList:      HandlePlayList;
    kaSettings:      HandleSettings;
    kaTopMost:       SetTopMost(FConfig.ReadInteger('topmost', 0) = 0);
  end;
end;

procedure TFrmKPlayer.WMMouseWheel(var Msg: TWMMouseWheel);
begin
  if MPVPlayer = nil then Exit;

  if Msg.WheelDelta > 0 then
    ExecMouse(meWheelUp)
  else
    ExecMouse(meWheelDown);

  Msg.Result := 1;
end;

// 마우스 이벤트 → 기능 (Hotkey.MouseMap, 환경설정 '마우스' 카드)
procedure TFrmKPlayer.ExecMouse(AEvent: TMouseEvent);
begin
  if MPVPlayer = nil then Exit;

  case MouseMap[AEvent] of
    mfFullScreen: MPVPlayer.Command(['cycle', 'fullscreen']);
    mfStretch:
      if WindowState = wsMaximized then
        MPVPlayer.Command(['set', 'fullscreen', 'no'])
      else
        EnterFullScreen(True);
    mfPause:      ExecAction(kaPause);
    mfNextFile:   ExecAction(kaListNext);
    mfPrevFile:   ExecAction(kaListPrev);
    mfSeekFwd:    ExecAction(kaSeekFwd);
    mfSeekBack:   ExecAction(kaSeekBack);
    mfVolUp:      ExecAction(kaVolUp);
    mfVolDown:    ExecAction(kaVolDown);
  end;
end;

procedure TFrmKPlayer.ClickTimerTick(Sender: TObject);
begin
  FClickTimer.Enabled := False;
  ExecMouse(meLClick);
end;

// TAB = 재생/파일 정보 패널 토글 (KPlayer.lua 의 script-message 'info').
// FormKeyDown 이 아닌 여기서 받는다 — TAB 은 VCL 이 다이얼로그 키로 먼저 먹어 거기까지 안 온다.
// 본체 창이 활성일 때만 (환경설정·목록 창의 탭 이동은 그대로 둔다). Ctrl+Tab 은 창 전환이라 제외.
procedure TFrmKPlayer.AppMessage(var Msg: TMsg; var Handled: Boolean);
begin
  if Msg.message <> WM_KEYDOWN then Exit;
  if Msg.wParam <> VK_TAB then Exit;
  if MPVPlayer = nil then Exit;
  if Screen.ActiveCustomForm <> Self then Exit;
  if GetKeyState(VK_CONTROL) < 0 then Exit;

  MPVPlayer.Command(['script-message', 'info']);
  Handled := True;
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

// 왼쪽 버튼 (영상 영역 = FOverControl 아님):
//   창모드 누름 → WM_NCLBUTTONDOWN 이동 루프 (뗄 때까지 안 돌아옴). 돌아왔을 때 창이 안 움직였으면 '클릭'.
//   클릭 기능은 더블클릭 시간만큼 미뤄 실행 (FClickTimer) — 두 번째 누름(ssDouble)이 오면 취소하고 더블클릭 기능.
//   Windows 는 첫 DOWN 시각 기준으로 두 번째 DOWN 을 DBLCLK 으로 만들고, 타이머는 UP 에서 시작하므로 겹치지 않는다.
//   컨트롤바 위는 lua 가 처리 — 더블클릭도 두 번째 클릭으로 그대로 넘긴다 (다음 버튼 연타 등).
procedure TFrmKPlayer.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
begin
  if (Button = mbLeft) and (ssDouble in Shift) then
    FClickTimer.Enabled := False;

  if (Button = mbLeft) and (not FOverControl) then
  begin
    if ssDouble in Shift then
    begin
      ExecMouse(meDblClick);
      Exit;
    end;

    if WindowState <> wsMaximized then
    begin
      R := BoundsRect;
      ReleaseCapture;
      Perform(WM_NCLBUTTONDOWN, HTCAPTION, 0);
      if (MouseMap[meLClick] <> mfNone) and EqualRect(R, BoundsRect) then
        FClickTimer.Enabled := True;
      Exit;
    end;

    // 전체화면: 이동 없음 → 바로 클릭 후보
    if MouseMap[meLClick] <> mfNone then
      FClickTimer.Enabled := True;
  end;

  if MPVPlayer = nil then Exit;

  case Button of
    mbLeft:   MPVPlayer.Command(['keydown', 'MBTN_LEFT']);
    mbMiddle:
      begin
        MPVPlayer.Command(['keydown', 'MBTN_MID']);
        if not FOverControl then ExecMouse(meMClick);
      end;
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
