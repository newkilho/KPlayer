unit Setup;

// NOTE: Keep this area ASCII-only. The IDE inserts units into the uses clause
// by byte offset and miscounts multi-byte (Korean) comments placed before it,
// which corrupts the file. Korean notes live below the uses clause.

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShlObj, System.SysUtils, System.Variants,
  System.Classes, System.Math, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.FileCtrl, Vcl.CategoryButtons, Vcl.WinXPanels, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ButtonGroup, Vcl.Buttons, Vcl.ImgList, System.Win.Registry,
  Winapi.ShellAPI, Winapi.ShLwApi, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree,
  VirtualTrees.AncestorVCL, VirtualTrees.Types, VirtualTrees,
  K.Theme, K.Config.INI;

// 환경설정 창
//
// 구조 (모두 디자이너 배치)
// =========================
//   PnlMenu   - 좌측 내비 (SpeedButton.Tag = 카드 인덱스) + 하단 [기본값 복원],
//               LineMenu 로 우측과 구분
//   PnlRight
//     PnlHeader - LblTitle (선택한 카드 이름)
//     PnlMain   - TCardPanel / 카드마다 TScrollBox 하나
//
// 창을 닫는 버튼은 없다 (제목줄 X 로 닫는다). 값은 바뀔 때마다 저장되므로
// 닫기 시점에 할 일이 없다.
//
// 행 규격 (항목을 추가할 때 이 값에 맞춘다)
// ==========================================
//   섹션 제목은 쓰지 않는다. 행만 위에서부터 붙여 나간다.
//   첫 행 위 여백 8, 행 높이 48 (설명 라벨이 있으면 64) — 행 사이 여백은 없다
//   좌측 라벨 Left = 24 / 우측 컨트롤은 Anchors=[akTop,akRight] 로 우측 24px
//   행 top 기준: 제목 +13 (설명 없으면 세로 중앙), 설명 +31, 컨트롤은 세로 중앙
//   제목 라벨: 기본 폰트 / 설명 라벨: Font.Height -11, Color clGray
//   컨트롤 폭: 콤보 170 / 트랙바 190 / 에디트 250 / 체크 21 / 찾기 버튼 60
//
// 값 저장은 "즉시 적용" 이다. 컨트롤이 바뀌면 ControlChange → SaveValues +
// ApplyLive 가 돌아간다. 확인/취소 버튼은 없다.
//
// KPlayer.lua 와의 관계
// =====================
//   volume / sub-visibility 는 Lua 가 observe 하므로 OSD 컨트롤바에 즉시 반영된다.
//   볼륨 최대값이 100 인 이유: Lua 의 volume observer 가 100 초과를 100 으로
//   되돌리고 그 값을 script-message 로 되돌려 준다 (KPlayer.lua 참고).
//   slang(기본 자막 언어) 은 다음 파일을 열 때부터 적용된다.
//
// 컨트롤을 추가하면 LoadValues / SaveValues 두 곳에 키를 같이 넣어야 한다.

type
  // 파일 연결 카드에서 다루는 확장자 분류
  TAssocGroup = (agVideo, agAudio, agList);

  TAssocExt = record
    Ext:   string;        // '.mp4'
    Desc:  string;        // 탐색기에 보일 파일 종류 이름 (ProgID 기본값으로 쓸 예정)
    Group: TAssocGroup;
    Main:  Boolean;       // [주요 파일] 버튼으로 선택되는 것
  end;

const
  AssocGroupNames: array[TAssocGroup] of string = ('비디오', '오디오', '재생목록');

  // 재생 가능한 확장자의 단일 출처. 지금은 연결 카드만 쓰지만
  // List.AddFile 의 지원 확장자 필터도 나중에 이 표를 보게 바꾼다
  // (현재 AddFile 은 7개만 하드코딩되어 있어 목록과 연결이 어긋난다).
  AssocExts: array[0..37] of TAssocExt = (
    (Ext: '.mp4';  Desc: 'MP4 비디오';         Group: agVideo; Main: True),
    (Ext: '.mkv';  Desc: 'Matroska 비디오';    Group: agVideo; Main: True),
    (Ext: '.avi';  Desc: 'AVI 비디오';         Group: agVideo; Main: True),
    (Ext: '.mov';  Desc: 'QuickTime 비디오';   Group: agVideo; Main: True),
    (Ext: '.wmv';  Desc: 'Windows Media 비디오'; Group: agVideo; Main: True),
    (Ext: '.flv';  Desc: 'Flash 비디오';       Group: agVideo; Main: False),
    (Ext: '.webm'; Desc: 'WebM 비디오';        Group: agVideo; Main: True),
    (Ext: '.m4v';  Desc: 'MPEG-4 비디오';      Group: agVideo; Main: False),
    (Ext: '.mpg';  Desc: 'MPEG 비디오';        Group: agVideo; Main: False),
    (Ext: '.mpeg'; Desc: 'MPEG 비디오';        Group: agVideo; Main: False),
    (Ext: '.m2v';  Desc: 'MPEG-2 비디오';      Group: agVideo; Main: False),
    (Ext: '.ts';   Desc: 'MPEG 전송 스트림';   Group: agVideo; Main: True),
    (Ext: '.tp';   Desc: 'MPEG 전송 스트림';   Group: agVideo; Main: False),
    (Ext: '.trp';  Desc: 'MPEG 전송 스트림';   Group: agVideo; Main: False),
    (Ext: '.m2ts'; Desc: 'Blu-ray 비디오';     Group: agVideo; Main: False),
    (Ext: '.mts';  Desc: 'AVCHD 비디오';       Group: agVideo; Main: False),
    (Ext: '.vob';  Desc: 'DVD 비디오';         Group: agVideo; Main: False),
    (Ext: '.asf';  Desc: 'ASF 비디오';         Group: agVideo; Main: False),
    (Ext: '.rm';   Desc: 'RealMedia 비디오';   Group: agVideo; Main: False),
    (Ext: '.rmvb'; Desc: 'RealMedia 비디오';   Group: agVideo; Main: False),
    (Ext: '.ogv';  Desc: 'Ogg 비디오';         Group: agVideo; Main: False),
    (Ext: '.3gp';  Desc: '3GPP 비디오';        Group: agVideo; Main: False),
    (Ext: '.divx'; Desc: 'DivX 비디오';        Group: agVideo; Main: False),
    (Ext: '.mp3';  Desc: 'MP3 오디오';         Group: agAudio; Main: True),
    (Ext: '.flac'; Desc: 'FLAC 오디오';        Group: agAudio; Main: True),
    (Ext: '.aac';  Desc: 'AAC 오디오';         Group: agAudio; Main: False),
    (Ext: '.m4a';  Desc: 'MPEG-4 오디오';      Group: agAudio; Main: True),
    (Ext: '.wav';  Desc: 'WAV 오디오';         Group: agAudio; Main: True),
    (Ext: '.ogg';  Desc: 'Ogg 오디오';         Group: agAudio; Main: False),
    (Ext: '.opus'; Desc: 'Opus 오디오';        Group: agAudio; Main: False),
    (Ext: '.wma';  Desc: 'Windows Media 오디오'; Group: agAudio; Main: False),
    (Ext: '.ape';  Desc: 'Monkey''s Audio';    Group: agAudio; Main: False),
    (Ext: '.aiff'; Desc: 'AIFF 오디오';        Group: agAudio; Main: False),
    (Ext: '.mka';  Desc: 'Matroska 오디오';    Group: agAudio; Main: False),
    (Ext: '.dsf';  Desc: 'DSD 오디오';         Group: agAudio; Main: False),
    (Ext: '.m3u';  Desc: '재생목록';           Group: agList;  Main: False),
    (Ext: '.m3u8'; Desc: '재생목록';           Group: agList;  Main: False),
    (Ext: '.pls';  Desc: '재생목록';           Group: agList;  Main: False));

const
  // 콤보박스 인덱스 → mpv 옵션 값. 설정은 인덱스로 저장하므로
  // 항목 순서를 바꾸면 기존 INI 값의 의미가 바뀐다 (추가는 뒤에만).
  // Main.FormCreate 도 초기화 옵션을 적용할 때 이 표를 쓴다.
  HwdecValues:     array[0..2] of string = ('auto-safe', 'auto', 'no');
  VoValues:        array[0..1] of string = ('gpu', 'gpu-next');
  GpuApiValues:    array[0..3] of string = ('auto', 'd3d11', 'opengl', 'vulkan');
  ScaleValues:     array[0..3] of string = ('lanczos', 'bilinear', 'spline36', 'ewa_lanczos');
  DeintValues:     array[0..2] of string = ('auto', 'yes', 'no');
  VideoSyncValues: array[0..1] of string = ('display-resample', 'audio');
  ShotFmtValues:   array[0..1] of string = ('jpg', 'png');

  // 음량 평준화 프리셋 (dynaudnorm) — 0:낮게 1:보통 2:강하게
  NormFilters: array[0..2] of string = (
    'lavfi=[dynaudnorm=f=100:g=15:p=0.90:r=0.10:n=1]',
    'lavfi=[dynaudnorm=f=75:g=7:p=0.95:r=0.20:n=1]',
    'lavfi=[dynaudnorm=f=50:g=5:p=0.99:r=0.30:n=1]');

// 재생 가능한 파일인가 (확장자가 AssocExts 에 있는가).
// List.AddFile 의 필터가 이 함수를 쓴다 — 재생목록에 넣는 확장자와 파일 연결로
// 등록하는 확장자가 갈리면, 연결해서 더블클릭했는데 목록에 안 들어가는 일이
// 생긴다 (실제로 그랬다: 연결은 38종, 목록 필터는 7종).
function IsMediaFile(const AFileName: string): Boolean;

// 재생목록 파일인가 (.m3u / .m3u8 / .pls). 목록에 넣을 때 항목으로 펼쳐야 한다.
function IsPlaylistFile(const AFileName: string): Boolean;

// 등록해 둔 파일 연결을 현재 exe 경로로 다시 기록한다. 프로그램 시작 시
// 한 번 부른다 — 포터블이라 폴더가 바뀌면 등록된 실행 명령이 어긋나
// 더블클릭이 '파일을 찾을 수 없음' 으로 끝난다.
procedure SyncFileAssoc;

// 캡처 기본 저장 폴더 = 바탕화면.
// exe 폴더는 쓰지 않는다 — Program Files 아래면 쓰기 권한이 없고, 프로그램
// 폴더에 캡처가 쌓이는 것도 곤란하다. Main.FormCreate 도 이 값을 기본값으로 쓴다.
function DesktopPath: string;

type
  TFrmSetup = class(TForm)
    PnlMenu: TPanel;
    BtnGeneral: TSpeedButton;
    BtnVideo: TSpeedButton;
    BtnAudio: TSpeedButton;
    BtnSub: TSpeedButton;
    BtnAssoc: TSpeedButton;
    BtnAbout: TSpeedButton;
    LineMenu: TShape;
    PnlRight: TPanel;
    PnlHeader: TPanel;
    LblTitle: TLabel;
    LineHeader: TShape;
    PnlMain: TCardPanel;
    CardGeneral: TCard;
    BoxGeneral: TScrollBox;
    LblRepeat: TLabel;
    CboRepeat: TComboBox;
    LblRandom: TLabel;
    CboRandom: TComboBox;
    LblShotDir: TLabel;
    LblShotDirDesc: TLabel;
    EdtShotDir: TEdit;
    BtnShotDir: TButton;
    LblShotFmt: TLabel;
    CboShotFmt: TComboBox;
    CardVideo: TCard;
    BoxVideo: TScrollBox;
    LblHwdec: TLabel;
    LblHwdecDesc: TLabel;
    CboHwdec: TComboBox;
    LblVo: TLabel;
    LblVoDesc: TLabel;
    CboVo: TComboBox;
    LblGpuApi: TLabel;
    LblGpuApiDesc: TLabel;
    CboGpuApi: TComboBox;
    LblVideoSync: TLabel;
    LblVideoSyncDesc: TLabel;
    CboVideoSync: TComboBox;
    LblScale: TLabel;
    LblScaleDesc: TLabel;
    CboScale: TComboBox;
    LblDeint: TLabel;
    LblDeintDesc: TLabel;
    CboDeint: TComboBox;
    CardAudio: TCard;
    BoxAudio: TScrollBox;
    LblVolume: TLabel;
    LblVolumeDesc: TLabel;
    LblVolumeValue: TLabel;
    TrkVolume: TTrackBar;
    LblNormalize: TLabel;
    LblNormalizeDesc: TLabel;
    ChkNormalize: TCheckBox;
    LblNormLevel: TLabel;
    CboNormLevel: TComboBox;
    CardSub: TCard;
    BoxSub: TScrollBox;
    LblSubVisible: TLabel;
    LblSubVisibleDesc: TLabel;
    ChkSubVisible: TCheckBox;
    LblSubSize: TLabel;
    LblSubSizeValue: TLabel;
    TrkSubSize: TTrackBar;
    LblSubLang: TLabel;
    LblSubLangDesc: TLabel;
    EdtSubLang: TEdit;
    CardAssoc: TCard;
    TreeAssoc: TVirtualStringTree;
    BtnAssocAll: TButton;
    BtnAssocNone: TButton;
    BtnAssocMain: TButton;
    BtnAssocDefaults: TButton;
    LblAssocHint: TLabel;
    CardAbout: TCard;
    MemAbout: TMemo;
    BtnReset: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnNavClick(Sender: TObject);
    procedure BtnResetClick(Sender: TObject);
    procedure BtnShotDirClick(Sender: TObject);
    procedure ControlChange(Sender: TObject);
    procedure TrackChange(Sender: TObject);
    procedure BtnAssocSelectClick(Sender: TObject);
    procedure BtnAssocDefaultsClick(Sender: TObject);
    procedure TreeAssocChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeAssocFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeAssocGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAssocGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
      var HintText: string);
    procedure TreeAssocGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean;
      var ImageIndex: TImageIndex);
    procedure TreeAssocPaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
  private
    FLoading: Boolean;
    FAssocIcons: TImageList;   // 확장자 아이콘 (폼이 소유 → 따로 해제하지 않는다)

    procedure FillAbout;

    procedure SetupAssocTree;
    procedure FillAssoc;
    function ExtIconIndex(const AExt: string): Integer;
    function CurrentAssocName(const AExt: string): string;
    procedure ApplyAssoc;
    procedure RefreshAssocStates;

    procedure LoadValues;
    procedure SaveValues;
    procedure ApplyLive;
    procedure UpdateTrackLabels;

    function Config: TConfig;
    function CfgInt(const AKey: string; ADef: Integer): Integer;
    function CfgStr(const AKey, ADef: string): string;
  public
    { Public declarations }
  end;

var
  FrmSetup: TFrmSetup;

implementation

uses Main, MPVPlayer;

{$R *.dfm}

{$I Const.inc}

function B2I(AValue: Boolean): Integer;
begin
  if AValue then Result := 1 else Result := 0;
end;

// CSIDL_DESKTOPDIRECTORY 는 OneDrive 리디렉션이나 다른 언어 환경에서도 실제
// 바탕화면 경로를 돌려준다 (USERPROFILE + '\Desktop' 조립은 그 경우 틀린다).
function DesktopPath: string;
var
  Buf: array[0..MAX_PATH] of Char;
begin
  if SHGetSpecialFolderPath(0, Buf, CSIDL_DESKTOPDIRECTORY, False) then
    Result := IncludeTrailingPathDelimiter(Buf)
  else
    Result := ExtractFilePath(ParamStr(0));   // 못 얻으면 예전처럼 exe 폴더
end;

procedure TFrmSetup.FormCreate(Sender: TObject);
begin
  PnlMain.ActiveCardIndex := 0;
  LblTitle.Caption := BtnGeneral.Caption;

  SetupAssocTree;

  SetTheme(Self);
end;

// 이 폼은 dpr 에서 한 번만 생성되고 ShowModal 로 계속 재사용된다.
// 볼륨(키보드/OSD)이나 반복 모드(재생목록)는 이 창 밖에서도 바뀌므로
// 열 때마다 다시 읽어야 옛 값이 보이지 않는다.
procedure TFrmSetup.FormShow(Sender: TObject);
begin
  FillAbout;
  FillAssoc;   // 연결 상태는 창 밖에서도 바뀌므로 열 때마다 다시 읽는다
  LoadValues;
end;

procedure TFrmSetup.BtnNavClick(Sender: TObject);
var
  B: TSpeedButton;
begin
  B := Sender as TSpeedButton;

  PnlMain.ActiveCardIndex := B.Tag;
  LblTitle.Caption := B.Caption;
end;

// ---------------------------------------------------------------------------
// 파일 연결 카드
//
// 지금은 "보여주기" 까지만 한다 — 확장자 목록, 확장자 아이콘, 각 확장자의 현재
// 연결 프로그램. 체크 상태를 실제 레지스트리에 반영하는 [KPlayer로 연결] /
// [선택 기본앱 설정] 은 다음 단계다.
//
// 오른쪽 열은 레지스트리에서 직접 읽는다 (INI 에 캐시하지 않는다). 다른
// 플레이어가 연결을 가져갔을 때 캐시는 거짓말을 하기 때문이다.
// ---------------------------------------------------------------------------

type
  // 트리 노드 데이터. 그룹 헤더 노드와 확장자 노드가 같은 레코드를 쓴다.
  TAssocNode = record
    IsGroup: Boolean;
    Group:   TAssocGroup;
    Index:   Integer;   // AssocExts 인덱스 (그룹 노드는 -1)
    Icon:    Integer;   // FAssocIcons 인덱스 (없으면 -1)
    Current: string;    // 현재 연결 프로그램 이름 (툴팁을 띄울 때 채운다)
    Ours:    Boolean;   // 지금 KPlayer 로 열리는 확장자
    Locked:  Boolean;   // 다른 프로그램이 기본 앱으로 지정해 둠 (UserChoice)
  end;
  PAssocNode = ^TAssocNode;

// ---------------------------------------------------------------------------
// 레지스트리 계층 (모두 HKEY_CURRENT_USER — UAC 승격이 필요 없다)
//
//   Software\Classes\KPlayer.mp4               ProgID (설명/아이콘/실행 명령)
//   Software\Classes\.mp4                      (기본값) = 우리 ProgID
//   Software\Classes\.mp4\OpenWithProgIDs   '연결 프로그램' 후보로 노출
//   Software\Classes\Applications\KPlayer.exe   FriendlyAppName / SupportedTypes
//   Software\KPlayer\Capabilities              설정 앱의 '기본 앱' 목록용
//   Software\RegisteredApplications               위 Capabilities 등록
//   Software\KPlayer\FileAssoc                 등록 전 값 백업 + 소유 목록
//
// 기본 앱 자체(FileExts\.mp4\UserChoice)는 쓰지 않는다. 윈도우가 해시로
// 서명해 보호하므로 위조하면 연결이 초기화되고 업데이트마다 깨진다. 지정이 없던
// 확장자는 위 등록만으로 기본이 되고, 다른 프로그램이 잡아둔 확장자는 사용자가
// 윈도우 설정에서 직접 골라야 한다.
//
// 폼 메서드가 아니라 유닛 레벨 함수다. Main.FormCreate 가 SyncFileAssoc 을
// 부르는 시점에는 FrmSetup 이 아직 만들어지지 않았다.
//
// 참고: D:\Source\Rust\FILEASSOC.md
// ---------------------------------------------------------------------------

const
  // 백업 겸 소유 목록. 값 이름은 확장자('.mp4'), 데이터는 등록 전의 ProgID.
  // 데이터가 빈 문자열이면 "HKCU 에 원래 값이 없었다" 는 뜻이고, 해제할 때는
  // 값을 지워야 한다. 빈 문자열을 기본값으로 쓰면 HKLM 연결이 가려져
  // '앱을 선택하세요' 가 뜬다 (FILEASSOC.md 4절에 기록된 사고).
  AssocBackupKey = '\Software\KPlayer\FileAssoc';
  AssocCapKey    = '\Software\KPlayer\Capabilities';
  AssocClassKey  = '\Software\Classes\';

function ExtProgID(const AExt: string): string;
begin
  Result := 'KPlayer' + AExt;   // '.mp4' -> 'KPlayer.mp4'
end;

// 확장자에 연결된 ProgID. 사용자별 설정(HKCU)이 먼저고, 없으면 시스템 전체
// (HKEY_CLASSES_ROOT — HKLM 과 HKCU 가 합쳐진 뷰) 를 본다.
function ClassProgID(const AExt: string): string;
var
  LReg: TRegistry;
begin
  Result := '';

  LReg := TRegistry.Create(KEY_READ);
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    if LReg.OpenKey(AssocClassKey + AExt, False) then
    try
      if LReg.ValueExists('') then
        Result := LReg.ReadString('');
    finally
      LReg.CloseKey;
    end;

    if Result <> '' then
      Exit;

    LReg.RootKey := HKEY_CLASSES_ROOT;
    if LReg.OpenKey('\' + AExt, False) then
    try
      if LReg.ValueExists('') then
        Result := LReg.ReadString('');
    finally
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;
end;

// 확장자의 기본 앱으로 지정된 ProgID. 지정이 없으면 빈 문자열.
function UserChoiceProgID(const AExt: string): string;
var
  LReg: TRegistry;
begin
  Result := '';

  LReg := TRegistry.Create(KEY_READ);
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    if LReg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' +
         AExt + '\UserChoice', False) then
    try
      if LReg.ValueExists('ProgId') then
        Result := LReg.ReadString('ProgId');
    finally
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;
end;

// 확장자의 상태를 레지스트리 값만으로 판단한다.
// AssocQueryString 을 쓰지 않는 이유: 그 API 는 연결을 따라가 실행 파일의 버전
// 리소스까지 읽고, SHChangeNotify 직후에는 셸 연결 캐시가 비어 매번 새로
// 만든다. 확장자 수십 개에 한 번에 부르면 눈에 보이게 느려진다.
procedure ReadAssocState(const AExt: string; out AOurs, ALocked: Boolean);
var
  LPID, LChoice: string;
begin
  LPID := ExtProgID(AExt);
  LChoice := UserChoiceProgID(AExt);

  if LChoice <> '' then
  begin
    // 기본 앱이 명시적으로 지정된 상태 — 우선순위가 가장 높다
    AOurs := SameText(LChoice, LPID);
    ALocked := not AOurs;
  end
  else
  begin
    AOurs := SameText(ClassProgID(AExt), LPID);
    ALocked := False;
  end;
end;

// 우리가 등록해 둔 확장자인지 (= 백업 목록에 있는지).
// 백업 없이 등록했던 예전 버전을 위해 ProgID 키 존재도 함께 본다.
function AssocOwned(const AExt: string): Boolean;
var
  LReg: TRegistry;
begin
  Result := False;

  LReg := TRegistry.Create(KEY_READ);
  try
    LReg.RootKey := HKEY_CURRENT_USER;

    if LReg.OpenKey(AssocBackupKey, False) then
    try
      Result := LReg.ValueExists(AExt);
    finally
      LReg.CloseKey;
    end;

    if not Result then
      Result := LReg.KeyExists(AssocClassKey + ExtProgID(AExt) +
                               '\shell\open\command');
  finally
    LReg.Free;
  end;
end;

// 우리가 등록해 둔 확장자 전체. 노출 목록(AssocExts)이 아니라 레지스트리에서
// 읽는다 — 노출 목록을 줄여도 예전에 등록한 확장자가 방치되지 않는다.
function AssocOwnedList: TArray<string>;
var
  LReg: TRegistry;
  LNames: TStringList;
  I: Integer;
begin
  Result := nil;

  LReg := TRegistry.Create(KEY_READ);
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    if not LReg.OpenKey(AssocBackupKey, False) then
      Exit;
    try
      LNames := TStringList.Create;
      try
        LReg.GetValueNames(LNames);
        for I := 0 to LNames.Count - 1 do
          if LNames[I] <> '' then
            Result := Result + [LNames[I]];
      finally
        LNames.Free;
      end;
    finally
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;
end;

// AssocExts 에서 확장자의 인덱스. 없으면 -1.
function AssocIndexOf(const AExt: string): Integer;
var
  I: Integer;
begin
  for I := Low(AssocExts) to High(AssocExts) do
    if SameText(AssocExts[I].Ext, AExt) then
      Exit(I);

  Result := -1;
end;

function IsMediaFile(const AFileName: string): Boolean;
begin
  Result := AssocIndexOf(ExtractFileExt(AFileName)) >= 0;
end;

function IsPlaylistFile(const AFileName: string): Boolean;
var
  LIndex: Integer;
begin
  LIndex := AssocIndexOf(ExtractFileExt(AFileName));
  Result := (LIndex >= 0) and (AssocExts[LIndex].Group = agList);
end;

// 확장자와 무관한 1회성 등록 (앱 이름, 설정 앱 노출).
procedure EnsureAppRegistered;
var
  LReg: TRegistry;
  LExe: string;
begin
  LExe := ParamStr(0);

  LReg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    LReg.RootKey := HKEY_CURRENT_USER;

    if LReg.OpenKey(AssocClassKey + 'Applications\' + ExtractFileName(LExe), True) then
    try
      LReg.WriteString('FriendlyAppName', 'KPlayer');
    finally
      LReg.CloseKey;
    end;

    if LReg.OpenKey(AssocCapKey, True) then
    try
      LReg.WriteString('ApplicationName', 'KPlayer');
      LReg.WriteString('ApplicationDescription', 'libmpv 기반 미디어 플레이어');
    finally
      LReg.CloseKey;
    end;

    // 이게 있어야 윈도우 설정의 '기본 앱' 목록에 KPlayer 가 나타난다.
    if LReg.OpenKey('\Software\RegisteredApplications', True) then
    try
      LReg.WriteString('KPlayer', 'Software\KPlayer\Capabilities');
    finally
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;
end;

// 확장자 하나를 등록한다. 이미 등록돼 있어도 다시 부를 수 있다
// (SyncFileAssoc 이 exe 경로 갱신 목적으로 그렇게 쓴다).
procedure AssocRegister(const AIndex: Integer);
var
  LReg: TRegistry;
  LExt, LPID, LExe, LPrev: string;
begin
  LExt := AssocExts[AIndex].Ext;
  LPID := ExtProgID(LExt);
  LExe := ParamStr(0);

  LReg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    LReg.RootKey := HKEY_CURRENT_USER;

    if LReg.OpenKey(AssocClassKey + LPID, True) then
    try
      LReg.WriteString('', AssocExts[AIndex].Desc);
    finally
      LReg.CloseKey;
    end;

    // 아이콘은 exe 에 박힌 첫 번째 것을 쓴다 (,0) — 별도 .ico 배포가 필요 없다.
    if LReg.OpenKey(AssocClassKey + LPID + '\DefaultIcon', True) then
    try
      LReg.WriteString('', '"' + LExe + '",0');
    finally
      LReg.CloseKey;
    end;

    // %1 은 반드시 따옴표로 감싼다 — 공백/한글이 든 경로가 조각난다.
    if LReg.OpenKey(AssocClassKey + LPID + '\shell\open\command', True) then
    try
      LReg.WriteString('', '"' + LExe + '" "%1"');
    finally
      LReg.CloseKey;
    end;

    // 탐색기의 '연결 프로그램' 목록에 KPlayer 를 올린다. UserChoice 에 막혀
    // 기본이 되지 못해도 이것이 있어야 사용자가 직접 고를 수 있다.
    if LReg.OpenKey(AssocClassKey + LExt + '\OpenWithProgIDs', True) then
    try
      LReg.WriteString(LPID, '');
    finally
      LReg.CloseKey;
    end;

    if LReg.OpenKey(AssocClassKey + 'Applications\' + ExtractFileName(LExe) +
         '\SupportedTypes', True) then
    try
      LReg.WriteString(LExt, '');
    finally
      LReg.CloseKey;
    end;

    if LReg.OpenKey(AssocCapKey + '\FileAssociations', True) then
    try
      LReg.WriteString(LExt, LPID);
    finally
      LReg.CloseKey;
    end;

    // 확장자의 기본 클래스. 이것이 없으면 '연결 프로그램' 목록에만 오르고
    // 실제로 더블클릭으로 열리지는 않는다.
    LPrev := '';
    if LReg.OpenKey(AssocClassKey + LExt, True) then
    try
      if LReg.ValueExists('') then
        LPrev := LReg.ReadString('');

      LReg.WriteString('', LPID);
    finally
      LReg.CloseKey;
    end;

    // 등록 전 값을 백업한다. 이미 백업이 있으면 덮어쓰지 않는다 — 재등록 때
    // 덮어쓰면 '원래 값' 이 우리 자신이 되어 되돌릴 곳을 잃는다.
    // 빈 문자열도 유효한 백업이다 ("HKCU 에 원래 값이 없었음").
    if SameText(LPrev, LPID) then
      LPrev := '';

    if LReg.OpenKey(AssocBackupKey, True) then
    try
      if not LReg.ValueExists(LExt) then
        LReg.WriteString(LExt, LPrev);
    finally
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;
end;

procedure AssocUnregister(const AIndex: Integer);
var
  LReg: TRegistry;
  LExt, LPID, LPrev: string;
  LHasBackup: Boolean;
begin
  LExt := AssocExts[AIndex].Ext;
  LPID := ExtProgID(LExt);

  LReg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    LReg.RootKey := HKEY_CURRENT_USER;

    // 백업을 먼저 읽는다. OpenKeyReadOnly 는 쓰지 않는다 — 성공하면 인스턴스의
    // Access 를 KEY_READ 로 바꿔버려서 이어지는 쓰기가 예외로 죽는다.
    LPrev := '';
    LHasBackup := False;
    if LReg.OpenKey(AssocBackupKey, False) then
    try
      LHasBackup := LReg.ValueExists(LExt);
      if LHasBackup then
        LPrev := LReg.ReadString(LExt);
    finally
      LReg.CloseKey;
    end;

    // 확장자의 기본 클래스가 아직 우리 것일 때만 손댄다. 그 사이 사용자가 다른
    // 프로그램을 골랐다면 그 선택이 우선이다.
    if LReg.OpenKey(AssocClassKey + LExt, False) then
    try
      if LReg.ValueExists('') and SameText(LReg.ReadString(''), LPID) then
      begin
        if LPrev <> '' then
          LReg.WriteString('', LPrev)
        else
          LReg.DeleteValue('');   // 없던 상태로 — HKLM 연결이 다시 드러난다
      end;
    finally
      LReg.CloseKey;
    end;

    if LHasBackup then
      SHDeleteValue(HKEY_CURRENT_USER, PChar(Copy(AssocBackupKey, 2, MaxInt)),
        PChar(LExt));
  finally
    LReg.Free;
  end;

  // TRegistry.DeleteKey 는 하위 키가 있으면 실패한다 → SHDeleteKey (재귀 삭제)
  SHDeleteKey(HKEY_CURRENT_USER, PChar('Software\Classes\' + LPID));

  SHDeleteValue(HKEY_CURRENT_USER,
    PChar('Software\Classes\' + LExt + '\OpenWithProgIDs'), PChar(LPID));
  SHDeleteValue(HKEY_CURRENT_USER,
    PChar('Software\Classes\Applications\' + ExtractFileName(ParamStr(0)) +
      '\SupportedTypes'), PChar(LExt));
  SHDeleteValue(HKEY_CURRENT_USER,
    PChar('Software\KPlayer\Capabilities\FileAssociations'), PChar(LExt));

  // 기본 앱이 우리로 지정돼 있었다면 그 지정도 지운다. 지우는 것은 허용된다
  // (해시 보호는 '쓰기' 에만 걸린다). 남겨두면 연결이 없는데 기본 앱은
  // KPlayer 인 상태가 되어 탐색기가 빈 연결을 물고 있게 된다.
  if SameText(UserChoiceProgID(LExt), LPID) then
    SHDeleteKey(HKEY_CURRENT_USER,
      PChar('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' +
        LExt + '\UserChoice'));
end;

procedure SyncFileAssoc;
var
  LExts: TArray<string>;
  LExt: string;
  LIndex, LCount: Integer;
begin
  LExts := AssocOwnedList;
  if Length(LExts) = 0 then
    Exit;

  LCount := 0;

  for LExt in LExts do
  begin
    // 노출 목록에서 빠진 확장자는 설명 정보가 없어 다시 쓸 수 없다.
    // 해제는 환경설정 화면에서만 한다 (여기서 조용히 지우면 사용자가 모른다).
    LIndex := AssocIndexOf(LExt);
    if LIndex < 0 then
      Continue;

    AssocRegister(LIndex);   // exe 경로가 바뀌었어도 이 호출로 갱신된다
    Inc(LCount);
  end;

  if LCount > 0 then
  begin
    EnsureAppRegistered;
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
  end;
end;


// 확장자의 아이콘을 얻어 이미지 리스트에 넣고 그 인덱스를 돌려준다.
// SHGFI_USEFILEATTRIBUTES 덕분에 그 확장자의 파일이 실제로 없어도 된다.
function TFrmSetup.ExtIconIndex(const AExt: string): Integer;
var
  LInfo: TSHFileInfo;
  LIcon: TIcon;
begin
  Result := -1;

  if SHGetFileInfo(PChar('x' + AExt), FILE_ATTRIBUTE_NORMAL, LInfo, SizeOf(LInfo),
       SHGFI_ICON or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES) = 0 then
    Exit;

  if LInfo.hIcon = 0 then
    Exit;

  LIcon := TIcon.Create;
  try
    LIcon.Handle := LInfo.hIcon;   // TIcon 이 소유권을 가져간다 (Free 에서 파괴)
    Result := FAssocIcons.AddIcon(LIcon);
  finally
    LIcon.Free;
  end;
end;

// 확장자에 연결된 프로그램의 표시 이름. 연결이 없으면 빈 문자열.
function TFrmSetup.CurrentAssocName(const AExt: string): string;
var
  LLen: DWORD;
  LBuf: array[0..MAX_PATH] of Char;
begin
  Result := '';
  LLen := Length(LBuf);

  if AssocQueryString(0, ASSOCSTR_FRIENDLYAPPNAME, PChar(AExt), nil,
       LBuf, @LLen) = S_OK then
    Result := LBuf;

  // 연결이 없으면 실행 파일명("OpenWith.exe")이 그대로 나올 수 있다.
  if SameText(Result, 'OpenWith.exe') or SameText(Result, 'openwith') then
    Result := '';
end;

procedure TFrmSetup.SetupAssocTree;
begin
  FAssocIcons := TImageList.Create(Self);   // 폼이 소유 → 폼과 함께 해제된다
  FAssocIcons.Width := 16;
  FAssocIcons.Height := 16;
  FAssocIcons.ColorDepth := cd32Bit;

  TreeAssoc.NodeDataSize := SizeOf(TAssocNode);
  TreeAssoc.Images := FAssocIcons;

  TreeAssoc.BevelInner := bvNone;
  TreeAssoc.BevelOuter := bvNone;
  TreeAssoc.BorderStyle := bsSingle;

  // 헤더는 감추고 (DFM: Header.Options = []) 열은 하나만 쓴다.
  // 연결 프로그램을 두 번째 열로 두면 좁은 폭에서 확장자명을 밀어내므로,
  // 그 정보는 글자색(이미 KPlayer 로 연결됨)과 툴팁으로 옮겼다.
  // 폭은 클라이언트 폭에 맞춘다 (300 - 테두리 2 - 세로 스크롤바 17).
  TreeAssoc.Header.Columns.Clear;
  TreeAssoc.Header.Columns.Add.Width := 281;
  TreeAssoc.Header.MainColumn := 0;

  TreeAssoc.HintMode := hmTooltip;

  TreeAssoc.TreeOptions.PaintOptions := TreeAssoc.TreeOptions.PaintOptions +
    [toShowButtons, toShowRoot, toHideFocusRect] - [toShowTreeLines];
  TreeAssoc.TreeOptions.SelectionOptions := TreeAssoc.TreeOptions.SelectionOptions +
    [toFullRowSelect];
  TreeAssoc.TreeOptions.MiscOptions := TreeAssoc.TreeOptions.MiscOptions +
    [toCheckSupport] - [toAcceptOLEDrop, toVariableNodeHeight];

  // 그룹 노드를 켜고 끄면 자식 체크가 따라간다 (그 반대도)
  TreeAssoc.TreeOptions.AutoOptions := TreeAssoc.TreeOptions.AutoOptions +
    [toAutoTristateTracking];
end;

procedure TFrmSetup.FillAssoc;
var
  LGroup: TAssocGroup;
  LGroupNode, LNode: PVirtualNode;
  LData: PAssocNode;
  I: Integer;
begin
  TreeAssoc.BeginUpdate;
  try
    TreeAssoc.Clear;
    FAssocIcons.Clear;

    for LGroup := Low(TAssocGroup) to High(TAssocGroup) do
    begin
      LGroupNode := TreeAssoc.AddChild(nil);
      LData := TreeAssoc.GetNodeData(LGroupNode);
      LData^.IsGroup := True;
      LData^.Group := LGroup;
      LData^.Index := -1;
      LData^.Icon := -1;
      TreeAssoc.CheckType[LGroupNode] := ctTriStateCheckBox;

      for I := Low(AssocExts) to High(AssocExts) do
      begin
        if AssocExts[I].Group <> LGroup then
          Continue;

        LNode := TreeAssoc.AddChild(LGroupNode);
        LData := TreeAssoc.GetNodeData(LNode);
        LData^.IsGroup := False;
        LData^.Group := LGroup;
        LData^.Index := I;
        LData^.Icon := ExtIconIndex(AssocExts[I].Ext);

        // 다른 프로그램이 UserChoice 로 잡아둔 확장자는 우리가 기본 앱을
        // 바꿀 수 없다 (윈도우가 해시로 보호한다). 색으로 구분해 준다.
        ReadAssocState(AssocExts[I].Ext, LData^.Ours, LData^.Locked);

        TreeAssoc.CheckType[LNode] := ctCheckBox;

        // 체크 초기값은 "지금 등록되어 있는가" 다. 이게 없으면 창을 열고
        // [적용] 만 눌렀을 때 기존 연결이 전부 해제된다.
        if AssocOwned(AssocExts[I].Ext) then
          TreeAssoc.CheckState[LNode] := csCheckedNormal;
      end;

      TreeAssoc.Expanded[LGroupNode] := True;
    end;
  finally
    TreeAssoc.EndUpdate;
  end;
end;

procedure TFrmSetup.TreeAssocFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  LData: PAssocNode;
begin
  LData := Sender.GetNodeData(Node);
  Finalize(LData^);   // Current 문자열 해제
end;

procedure TFrmSetup.TreeAssocGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  LData: PAssocNode;
begin
  CellText := '';
  LData := Sender.GetNodeData(Node);
  if LData = nil then Exit;

  if LData^.IsGroup then
  begin
    if Column <= 0 then
      CellText := AssocGroupNames[LData^.Group];
    Exit;
  end;

  if Column <= 0 then
    CellText := AssocExts[LData^.Index].Ext;
end;

procedure TFrmSetup.TreeAssocGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: TImageIndex);
var
  LData: PAssocNode;
begin
  ImageIndex := -1;
  if (Kind <> ikNormal) and (Kind <> ikSelected) then Exit;
  if Column > 0 then Exit;

  LData := Sender.GetNodeData(Node);
  if (LData <> nil) and not LData^.IsGroup then
    ImageIndex := LData^.Icon;
end;

procedure TFrmSetup.TreeAssocPaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var
  LData: PAssocNode;
begin
  LData := Sender.GetNodeData(Node);
  if LData = nil then Exit;

  if LData^.IsGroup then
    Exit;   // 그룹 헤더는 기본 글자색

  // 이름 전체는 툴팁(TreeAssocGetHint)에 나온다.
  if LData^.Ours then
    TargetCanvas.Font.Color := $00206020    // 초록 = 이미 KPlayer 가 기본 앱
  else if LData^.Locked then
    TargetCanvas.Font.Color := clGrayText;  // 회색 = 다른 프로그램이 지정해 둠
end;

procedure TFrmSetup.TreeAssocGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
  var HintText: string);
var
  LData: PAssocNode;
begin
  HintText := '';
  LData := Sender.GetNodeData(Node);
  if (LData = nil) or LData^.IsGroup then Exit;

  HintText := AssocExts[LData^.Index].Desc;

  // 연결 프로그램 이름은 여기서만 필요하다. AssocQueryString 이 느려서
  // 목록 전체를 갱신할 때는 부르지 않고, 마우스를 올린 항목만 읽어 캐시한다.
  if LData^.Current = '' then
    LData^.Current := CurrentAssocName(AssocExts[LData^.Index].Ext);

  if LData^.Current <> '' then
    HintText := HintText + sLineBreak + '현재 연결: ' + LData^.Current
  else
    HintText := HintText + sLineBreak + '연결된 프로그램 없음';

  if LData^.Locked then
    HintText := HintText + sLineBreak +
      '기본 앱이 지정되어 있어 윈도우 설정에서 바꿔야 합니다';

  LineBreakStyle := hlbForceMultiLine;
end;

// 체크 상태를 레지스트리에 반영한다. [적용] 버튼은 없다 — 체크하는 즉시
// 이 코드가 돌고 결과 대화상자도 띄우지 않는다.
//
// 트리를 다시 만들지(FillAssoc) 않는 것이 중요하다. 이 프로시저는 OnChecked
// 안에서도 불리는데, 그때 노드를 해제하면 VST 가 방금 클릭한 노드를 계속
// 만지다가 죽는다. 그래서 표시 갱신은 RefreshAssocStates 로 제자리에서 한다.
procedure TFrmSetup.ApplyAssoc;
var
  LNode: PVirtualNode;
  LData: PAssocNode;
  LWant: Boolean;
  LChanged: Integer;
begin
  LChanged := 0;

  LNode := TreeAssoc.GetFirst;
  while LNode <> nil do
  begin
    LData := TreeAssoc.GetNodeData(LNode);

    if (LData <> nil) and not LData^.IsGroup then
    begin
      LWant := TreeAssoc.CheckState[LNode] = csCheckedNormal;

      // 바뀐 것만 건드린다. 클릭 한 번에 38개를 전부 다시 쓰면 느리고,
      // 등록해 둔 확장자의 '이전 ProgID' 보관값도 자기 것으로 덮어쓴다.
      if LWant <> AssocOwned(AssocExts[LData^.Index].Ext) then
      begin
        if LWant then
          AssocRegister(LData^.Index)
        else
          AssocUnregister(LData^.Index);

        Inc(LChanged);
      end;
    end;

    LNode := TreeAssoc.GetNext(LNode);
  end;

  if LChanged = 0 then
    Exit;

  EnsureAppRegistered;

  // 확장자를 한꺼번에 바꾸면(모두 선택/해제) 레지스트리 쓰기가 수십 번이라
  // 순간적으로 멈춘 것처럼 보인다.
  Screen.Cursor := crHourGlass;

  // 탐색기가 아이콘/연결을 다시 읽게 한다.
  // SHCNF_FLUSH 는 셸의 모든 수신자가 처리를 끝낼 때까지 기다리므로
  // 체크박스를 누를 때마다 창이 멈춘다. 비동기로 보낸다.
  try
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);

    RefreshAssocStates;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// 노드를 다시 만들지 않고 각 확장자의 현재 상태(연결 프로그램 / 기본 앱 지정
// 여부)만 다시 읽는다. 아이콘은 그대로 둔다 — 이미지 리스트를 다시 만들어야
// 하고, 등록으로 바뀐 아이콘은 창을 다시 열면 반영된다.
procedure TFrmSetup.RefreshAssocStates;
var
  LNode: PVirtualNode;
  LData: PAssocNode;
begin
  LNode := TreeAssoc.GetFirst;
  while LNode <> nil do
  begin
    LData := TreeAssoc.GetNodeData(LNode);

    if (LData <> nil) and not LData^.IsGroup then
    begin
      ReadAssocState(AssocExts[LData^.Index].Ext, LData^.Ours, LData^.Locked);
      LData^.Current := '';   // 툴팁을 띄울 때 다시 읽는다
    end;

    LNode := TreeAssoc.GetNext(LNode);
  end;

  TreeAssoc.Invalidate;
end;

// 체크박스를 누르면 그 즉시 반영한다.
// VST 는 사용자가 직접 클릭한 노드에만 OnChecked 를 준다 (코드로 CheckState 를
// 바꿀 때는 오지 않으므로 FillAssoc 의 초기 체크는 여기로 들어오지 않는다).
// 그룹 노드를 클릭하면 자식 체크는 VST 가 바꾸고 이벤트는 그룹 하나로 오므로,
// 개별 노드만 처리하지 않고 전체를 훑어 반영한다.
procedure TFrmSetup.TreeAssocChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  ApplyAssoc;
end;

procedure TFrmSetup.BtnAssocDefaultsClick(Sender: TObject);
begin
  // 체크는 이미 반영되어 있다. 다만 아무것도 체크하지 않았어도 설정 앱의
  // '기본 앱' 목록에는 KPlayer 가 보여야 한다.
  EnsureAppRegistered;

  // 기본 앱 지정은 윈도우 설정에서만 가능하다 (UserChoice 는 해시로 보호된다).
  // Win10/11 공통으로 이 URI 가 '기본 앱' 페이지를 연다.
  ShellExecute(Handle, 'open', 'ms-settings:defaultapps', nil, nil, SW_SHOWNORMAL);
end;

// 선택 버튼 3개를 한 핸들러가 처리한다 (Button.Tag).
//   0 = 주요 파일 / 1 = 모두 선택 / 2 = 모두 해제
// [모두 해제] 만 체크를 푼다. [주요 파일] 은 "더하기" 다 — 이미 켜져 있던
// 항목을 지우지 않는다. 하나 켜려고 누른 버튼이 다른 선택을 지우면 안 된다.
procedure TFrmSetup.BtnAssocSelectClick(Sender: TObject);
var
  LNode: PVirtualNode;
  LData: PAssocNode;
  LTag: Integer;
  LOn: Boolean;
begin
  LTag := (Sender as TButton).Tag;

  TreeAssoc.BeginUpdate;
  try
    LNode := TreeAssoc.GetFirst;
    while LNode <> nil do
    begin
      LData := TreeAssoc.GetNodeData(LNode);

      // 그룹 노드는 자식 체크에 따라 자동으로 정해진다 (toAutoTristateTracking)
      if (LData <> nil) and not LData^.IsGroup then
      begin
        if LTag = 2 then
          TreeAssoc.CheckState[LNode] := csUncheckedNormal
        else
        begin
          LOn := (LTag = 1) or AssocExts[LData^.Index].Main;

          if LOn then
            TreeAssoc.CheckState[LNode] := csCheckedNormal;
        end;
      end;

      LNode := TreeAssoc.GetNext(LNode);
    end;
  finally
    TreeAssoc.EndUpdate;
  end;

  // 코드로 CheckState 를 바꾸면 OnChecked 가 오지 않으므로 직접 반영한다.
  ApplyAssoc;
end;

procedure TFrmSetup.BtnResetClick(Sender: TObject);
begin
  if Config = nil then Exit;

  if TaskMessageDlg('모든 설정을 기본값으로 되돌립니다.',
       '지금 화면의 값과 저장된 설정이 모두 기본값으로 바뀝니다.' + sLineBreak +
       '파일 연결은 바뀌지 않습니다.',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Config.WriteInteger('repeat', 0);
  Config.WriteInteger('random', 0);
  Config.WriteString('shot_dir', DesktopPath);
  Config.WriteInteger('shot_format', 0);

  Config.WriteInteger('hwdec', 0);
  Config.WriteInteger('vo', 0);
  Config.WriteInteger('gpu_api', 0);
  Config.WriteInteger('scale', 0);
  Config.WriteInteger('deinterlace', 0);
  Config.WriteInteger('video_sync', 0);

  Config.WriteDouble('volume', 100);
  Config.WriteInteger('normalize', 1);
  Config.WriteInteger('norm_level', 1);

  Config.WriteInteger('sub_visible', 0);
  Config.WriteInteger('sub_size', 55);
  Config.WriteString('sub_lang', 'ko,kor,en,eng');

  // LoadValues 는 FLoading 중이라 컨트롤 이벤트가 죽는다. 그래서 SaveValues 를
  // 직접 한 번 불러 Main 이 메모리에 들고 있는 반복/랜덤/볼륨까지 갱신한다
  // (List.pas 가 FrmKPlayer.RepeatMode 를 직접 읽으므로 INI 만 고치면 부족하다).
  LoadValues;
  SaveValues;
  ApplyLive;
end;

procedure TFrmSetup.BtnShotDirClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := EdtShotDir.Text;

  if SelectDirectory('스크린샷을 저장할 폴더를 선택하세요.', '', Dir) then
  begin
    EdtShotDir.Text := Dir;

    // 직접 고른 경우에만 INI 에 남긴다 (SaveValues 는 이 키를 건드리지 않는다)
    if Config <> nil then
      Config.WriteString('shot_dir', Dir);

    ControlChange(Sender);
  end;
end;

// 정보 카드 — 버전은 실행 중에만 알 수 있으므로 여기서 채운다.
procedure TFrmSetup.FillAbout;
var
  S: string;
begin
  MemAbout.Lines.Clear;
  MemAbout.Lines.Add(AppName);
  MemAbout.Lines.Add('');

  if (FrmKPlayer <> nil) and (FrmKPlayer.MPVPlayer <> nil) then
  begin
    S := '';
    FrmKPlayer.MPVPlayer.GetPropertyString('mpv-version', S);
    if S <> '' then
      MemAbout.Lines.Add(S);

    S := '';
    FrmKPlayer.MPVPlayer.GetPropertyString('ffmpeg-version', S);
    if S <> '' then
      MemAbout.Lines.Add('FFmpeg ' + S);
  end;

  MemAbout.Lines.Add('');
  MemAbout.Lines.Add('실행 파일: ' + ParamStr(0));
  MemAbout.Lines.Add('');
  MemAbout.Lines.Add('이 프로그램은 libmpv (GPL-2.0-or-later) 를 사용합니다.');
  MemAbout.Lines.Add('재생 목록은 Virtual Treeview (MPL 1.1) 를 사용합니다.');
end;

// Value
procedure TFrmSetup.LoadValues;
begin
  if Config = nil then Exit;

  FLoading := True;
  try
    CboRepeat.ItemIndex := EnsureRange(CfgInt('repeat', 0), 0, CboRepeat.Items.Count - 1);
    CboRandom.ItemIndex := EnsureRange(CfgInt('random', 0), 0, CboRandom.Items.Count - 1);
    EdtShotDir.Text := CfgStr('shot_dir', DesktopPath);
    CboShotFmt.ItemIndex := EnsureRange(CfgInt('shot_format', 0), 0, CboShotFmt.Items.Count - 1);

    CboHwdec.ItemIndex := EnsureRange(CfgInt('hwdec', 0), 0, CboHwdec.Items.Count - 1);
    CboVo.ItemIndex := EnsureRange(CfgInt('vo', 0), 0, CboVo.Items.Count - 1);
    CboGpuApi.ItemIndex := EnsureRange(CfgInt('gpu_api', 0), 0, CboGpuApi.Items.Count - 1);
    CboScale.ItemIndex := EnsureRange(CfgInt('scale', 0), 0, CboScale.Items.Count - 1);
    CboDeint.ItemIndex := EnsureRange(CfgInt('deinterlace', 0), 0, CboDeint.Items.Count - 1);
    CboVideoSync.ItemIndex := EnsureRange(CfgInt('video_sync', 0), 0, CboVideoSync.Items.Count - 1);

    TrkVolume.Position := EnsureRange(Round(Config.ReadDouble('volume', 100)),
      TrkVolume.Min, TrkVolume.Max);
    ChkNormalize.Checked := CfgInt('normalize', 1) <> 0;
    CboNormLevel.ItemIndex := EnsureRange(CfgInt('norm_level', 1), 0, CboNormLevel.Items.Count - 1);

    ChkSubVisible.Checked := CfgInt('sub_visible', 0) <> 0;
    TrkSubSize.Position := EnsureRange(CfgInt('sub_size', 55), TrkSubSize.Min, TrkSubSize.Max);
    EdtSubLang.Text := CfgStr('sub_lang', 'ko,kor,en,eng');

    UpdateTrackLabels;
  finally
    FLoading := False;
  end;
end;

procedure TFrmSetup.SaveValues;
begin
  if Config = nil then Exit;

  // 반복/랜덤/볼륨은 Main 이 값과 저장을 함께 들고 있으므로 프로퍼티로 넘긴다.
  if FrmKPlayer <> nil then
  begin
    FrmKPlayer.RepeatMode := CboRepeat.ItemIndex;
    FrmKPlayer.RandomMode := CboRandom.ItemIndex;
    FrmKPlayer.Volume := TrkVolume.Position;
  end;

  // shot_dir 은 여기서 쓰지 않는다. 다른 항목을 만질 때마다 같이 기록되면
  // "사용자가 직접 고른 폴더"와 "기본값이 그냥 표시된 것"을 구분할 수 없게 되고,
  // 나중에 기본 폴더를 바꿔도 이미 박힌 값 때문에 반영되지 않는다.
  // 폴더는 [찾기]로 실제 선택했을 때만 BtnShotDirClick 에서 기록한다.
  Config.WriteInteger('shot_format', CboShotFmt.ItemIndex);

  Config.WriteInteger('hwdec', CboHwdec.ItemIndex);
  Config.WriteInteger('vo', CboVo.ItemIndex);
  Config.WriteInteger('gpu_api', CboGpuApi.ItemIndex);
  Config.WriteInteger('scale', CboScale.ItemIndex);
  Config.WriteInteger('deinterlace', CboDeint.ItemIndex);
  Config.WriteInteger('video_sync', CboVideoSync.ItemIndex);

  Config.WriteInteger('normalize', B2I(ChkNormalize.Checked));
  Config.WriteInteger('norm_level', CboNormLevel.ItemIndex);

  Config.WriteInteger('sub_visible', B2I(ChkSubVisible.Checked));
  Config.WriteInteger('sub_size', TrkSubSize.Position);
  Config.WriteString('sub_lang', EdtSubLang.Text);
end;

// 재시작 없이 반영되는 항목만 mpv 에 넘긴다.
// vo / gpu-api / hwdec / scale / deinterlace / video-sync 는 초기화 옵션이라
// Main.FormCreate 에서만 적용된다 (행 설명에 "재시작 후 적용" 으로 표기).
procedure TFrmSetup.ApplyLive;
var
  MPV: TMPVPlayer;
  SubVis: string;
begin
  if FrmKPlayer = nil then Exit;

  MPV := FrmKPlayer.MPVPlayer;
  if MPV = nil then Exit;

  MPV.Command(['set', 'screenshot-directory', EdtShotDir.Text]);
  MPV.Command(['set', 'screenshot-format', ShotFmtValues[CboShotFmt.ItemIndex]]);
  MPV.Command(['set', 'volume', IntToStr(TrkVolume.Position)]);

  if ChkNormalize.Checked then
    MPV.Command(['set', 'af', NormFilters[CboNormLevel.ItemIndex]])
  else
    MPV.Command(['set', 'af', '']);

  if ChkSubVisible.Checked then SubVis := 'yes' else SubVis := 'no';

  MPV.Command(['set', 'sub-visibility', SubVis]);
  MPV.Command(['set', 'sub-font-size', IntToStr(TrkSubSize.Position)]);
  MPV.Command(['set', 'slang', EdtSubLang.Text]);
end;

// Event
procedure TFrmSetup.ControlChange(Sender: TObject);
begin
  if FLoading then Exit;

  SaveValues;
  ApplyLive;
end;

procedure TFrmSetup.TrackChange(Sender: TObject);
begin
  UpdateTrackLabels;
  ControlChange(Sender);
end;

procedure TFrmSetup.UpdateTrackLabels;
begin
  LblVolumeValue.Caption := Format('%d%%', [TrkVolume.Position]);
  LblSubSizeValue.Caption := IntToStr(TrkSubSize.Position);
end;

// Config
function TFrmSetup.Config: TConfig;
begin
  if FrmKPlayer <> nil then
    Result := FrmKPlayer.Config
  else
    Result := nil;
end;

function TFrmSetup.CfgInt(const AKey: string; ADef: Integer): Integer;
begin
  Result := Config.ReadInteger(AKey, ADef);
end;

function TFrmSetup.CfgStr(const AKey, ADef: string): string;
begin
  Result := Config.ReadString(AKey, ADef);
end;

end.
