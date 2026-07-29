unit Setup;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShlObj, System.SysUtils, System.Variants,
  System.Classes, System.Math, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.FileCtrl, Vcl.CategoryButtons, Vcl.WinXPanels, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ButtonGroup, Vcl.Buttons, Vcl.ImgList, System.Win.Registry,
  Winapi.ShellAPI, Winapi.ShLwApi, Winapi.CommCtrl,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree,
  VirtualTrees.AncestorVCL, VirtualTrees.Types, VirtualTrees,
  K.Theme, K.Config.INI, Assoc;

// 환경설정 창. 좌측 내비(SpeedButton.Tag = 카드 인덱스) + TCardPanel 이고,
// 카드마다 TScrollBox 하나다. 배치는 모두 디자이너에 있다.
//
// 값은 바뀔 때마다 저장된다 (ControlChange → SaveValues + ApplyLive).
// 확인/취소도 닫기 버튼도 없다. 컨트롤을 추가하면 LoadValues 와 SaveValues
// 두 곳에 키를 같이 넣어야 한다.
//
// 행 규격 — 행 간격 64, 라벨 Top 은 21/85/149..., 컨트롤 Top = 라벨 +7,
// 설명 라벨은 라벨 +18 에 Font.Height -11 / clGray. 라벨 Left 24, 컨트롤은
// Anchors=[akTop,akRight] 로 우측 24px. 폭은 콤보 170 / 트랙바 190 /
// 에디트 250 / [찾기] 60.
//
// volume 과 sub-visibility 는 Lua 가 observe 하므로 OSD 에 즉시 반영된다.
// 볼륨 최대가 100 인 것은 Lua 가 초과분을 100 으로 되돌리기 때문이고,
// slang(기본 자막 언어)은 다음 파일부터 적용된다.

// 캡처 기본 저장 폴더 = 바탕화면. exe 폴더는 쓰지 않는다 — Program Files
// 아래면 쓰기 권한이 없고, 프로그램 폴더에 캡처가 쌓이는 것도 곤란하다.
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
    LblSaveList: TLabel;
    LblSaveListDesc: TLabel;
    CboSaveList: TComboBox;
    LblShotDir: TLabel;
    LblShotDirDesc: TLabel;
    EdtShotDir: TEdit;
    BtnShotDir: TButton;
    LblShotFmt: TLabel;
    CboShotFmt: TComboBox;
    LblTopMost: TLabel;
    CboTopMost: TComboBox;
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
    CboNormalize: TComboBox;
    LblNormLevel: TLabel;
    CboNormLevel: TComboBox;
    CardSub: TCard;
    BoxSub: TScrollBox;
    LblSubVisible: TLabel;
    LblSubVisibleDesc: TLabel;
    CboSubVisible: TComboBox;
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
    MemoAssocLog: TMemo;
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
    procedure TreeAssocGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean;
      var ImageIndex: TImageIndex);
    procedure TreeAssocPaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
    procedure TreeAssocBeforeCellPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
    procedure TreeAssocMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure TreeAssocMouseLeave(Sender: TObject);

    function BadgeBusy: Boolean;
    function BadgeRect(ACanvas: TCanvas; const ACell: TRect): TRect;
  private
    FLoading: Boolean;

    // 트리를 채우는 중에는 체크 이벤트를 무시한다. VST 의 CheckState 대입은
    // 그 자체로 OnChecked 를 부르므로, 창을 열어 체크를 복원하는 것만으로
    // 등록/해제가 일어난다.
    FFilling: Boolean;

    // 확장자별 아이콘 인덱스 캐시 (IconUnknown = 아직 안 물어봤다).
    // 창을 다시 열어도 유지된다.
    FIconIndex: array of Integer;

    // 체크 이벤트를 모아 한 번만 반영하는 타이머. 그룹 체크는 자식마다
    // OnChecked 를 주므로 그대로 처리하면 전체 훑기가 38번 반복된다.
    FApplyTimer: TTimer;

    // 레지스트리 감시. 남이 기본 앱을 바꾸면 목록·색·아이콘을 다시 읽는다.
    //   FWatcher      - 감시 스레드 (창이 떠 있는 동안만)
    //   FWatchTimer   - 알림을 모으는 디바운스 (폭주해도 한 번만 갱신)
    //   FQuietUntil   - 우리가 쓴 직후의 알림은 무시하는 시각
    //   FDirty        - 연결 카드가 아닐 때 온 변경 (카드로 올 때 반영)
    FWatcher: TThread;
    FWatchTimer: TTimer;
    FQuietUntil: UInt64;
    FDirty: Boolean;
    FAssocIcons: TImageList;   // 확장자 아이콘 (폼이 소유 → 따로 해제하지 않는다)

    // 직접 그린 체크박스 그림 (시스템 것은 강조색으로 꽉 차 너무 진하다).
    // 만든 뒤 InsertComponent 로 폼에 넘기므로 따로 해제하지 않는다.
    FCheckImages: TImageList;

    // 열어 둔 [기본 앱 선택] 창의 뒷정리 대상 (숨긴 속성 창 + 임시 파일).
    // 선택 창이 닫히는 시점을 알 수 없어 이 창으로 돌아올 때 정리한다.
    FPicker: TPickerJob;

    // 마우스가 올라간 [강제설정] 뱃지. 그 뱃지에만 테두리를 그린다.
    FBadgeHot: PVirtualNode;

    // 선택 창을 여는 중. 그 동안 모든 뱃지가 회색(비활성)이 된다.
    FBadgeBusy: Boolean;

    // 선택 창을 띄우는 중. 그 안에서 메시지를 돌리므로 연타를 막아야 한다.
    FPicking: Boolean;

    procedure FillAbout;

    procedure SetupAssocTree;
    procedure FillAssoc;
    function ExtIconIndex(AIndex: Integer): Integer;
    procedure ResetIcons;
    procedure ApplyAssoc;
    procedure RefreshAssocStates;
    procedure UpdateAssocHint;
    procedure LayoutAssocColumns;
    procedure ApplyTimerTick(Sender: TObject);
    procedure WatchTimerTick(Sender: TObject);
    procedure AssocChanged;
    procedure RefreshAssocView;
    procedure PickDefaultApp(const AExt: string);
    procedure ClosePicker;
    procedure LogAssoc(const AMsg: string);
    procedure TreeAssocClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormHide(Sender: TObject);

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

const
  // 아이콘 캐시의 '아직 안 물어봤다' 표시 (-1 은 '셸이 못 준다' 는 뜻으로 쓴다)
  IconUnknown = -2;

  // 연결 트리의 행 두께. 여기 한 곳만 고친다 (재생목록은 List.pas 의 24).
  // 방식도 재생목록과 같다 — toVariableNodeHeight 와 toAutoChangeScale 을 끄고,
  // 노드마다 NodeHeight 를 직접 넣는다. OnMeasureItem 을 쓰면 마우스가 지나간
  // 행만 다시 재어 두께가 들썩인다.
  AssocRowHeight = 28;

  // 상태 뱃지. HTML 규격을 그대로 옮겼다 (padding 0 6px / radius 3px / 11px,
  // 배경 #fde8e8, 글자 #9b1c1c). 창이 라이트 고정이라 다크 값은 두지 않는다.
  // 테두리는 평소 없고 마우스가 올라가면 글자색으로 드러난다.
  // Delphi 색상값은 BGR 순서다.
  BadgeBackColor = $00E8E8FD;
  BadgeTextColor = $001C1C9B;   // 호버 테두리도 이 색
  BadgeRadius    = 3;           // 크게 주면 GDI 라 계단이 보인다
  BadgeFontSize  = -11;
  BadgePadX      = 6;
  // 높이는 숫자로 고정하지 않고 글자 높이에 위아래로 이 값을 더한다.
  // 11px 글자의 실제 높이가 15px 이라 18 로 고정하면 여백이 1/2 로 갈린다.
  BadgePadY      = 4;

  // 선택 창을 여는 동안의 비활성 색. 문구를 바꾸면 뱃지 크기가 달라지므로
  // 글자는 그대로 두고 회색으로만 바꾼다.
  BadgeDisBackColor = $00F0F0F0;
  BadgeDisTextColor = $00A0A0A0;

  // 글자는 '할 일' 이 아니라 '상태' 다 — 체크로 등록은 이미 됐으므로 적용을
  // 다시 요구하는 문구는 헷갈린다. 누를 수 있다는 신호는 호버 테두리와 손
  // 모양 커서가 맡는다.
  BadgeTextNormal = '적용안됨';

{$R *.dfm}

{$I Const.inc}

function B2I(AValue: Boolean): Integer;
begin
  if AValue then Result := 1 else Result := 0;
end;

// 켜고 끄는 항목은 '사용안함/사용함' 콤보다. 순서는 0 = 사용안함 고정 —
// 뒤집으면 설정 파일에 이미 들어 있는 0/1 의 의미가 반대로 읽힌다.
function CboOn(ACombo: TComboBox): Boolean;
begin
  Result := ACombo.ItemIndex = 1;
end;

procedure SetCboOn(ACombo: TComboBox; AValue: Boolean);
begin
  ACombo.ItemIndex := B2I(AValue);
end;

// CSIDL_DESKTOPDIRECTORY 는 OneDrive 리디렉션이나 다른 언어에서도 실제 경로를
// 돌려준다 (USERPROFILE + '\Desktop' 조립은 그 경우 틀린다).
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

  // 선택 창이나 설정 앱을 다녀오면 상태를 다시 읽어야 한다.
  // DFM 이 아니라 코드로 붙인다 (디자이너가 지우지 못하게).
  OnActivate := FormActivate;
  OnHide := FormHide;

  // 체크 이벤트를 모으는 타이머 (폼이 소유 → 함께 해제된다)
  FApplyTimer := TTimer.Create(Self);
  FApplyTimer.Enabled := False;
  FApplyTimer.Interval := 80;
  FApplyTimer.OnTimer := ApplyTimerTick;

  // 레지스트리 알림을 모으는 타이머
  FWatchTimer := TTimer.Create(Self);
  FWatchTimer.Enabled := False;
  FWatchTimer.Interval := 300;
  FWatchTimer.OnTimer := WatchTimerTick;

  // 로그와 정보 카드는 디버그 빌드에서만 쓴다 (Main.pas 가 lua 경로를 가르는
  // 것과 같은 기준). 훅을 걸지 않으면 Assoc.pas 는 문자열도 만들지 않는다.
  MemoAssocLog.Visible := ReportMemoryLeaksOnShutDown;
  BtnAbout.Visible := ReportMemoryLeaksOnShutDown;

  if ReportMemoryLeaksOnShutDown then
  begin
    AssocLogProc :=
      procedure(AMsg: string)
      begin
        LogAssoc(AMsg);
      end;

    // 로그를 그대로 복사해 보고할 수 있게 앞머리에 환경을 적어 둔다.
    LogAssoc('exe = ' + ParamStr(0));
    LogAssoc(AssocEnvInfo);
    LogAssoc(Format('Windows %d.%d build %d',
      [TOSVersion.Major, TOSVersion.Minor, TOSVersion.Build]));
  end;

  SetTheme(Self);
end;

// 이 폼은 한 번만 생성되고 ShowModal 로 재사용된다. 볼륨이나 반복 모드는 창
// 밖에서도 바뀌므로 열 때마다 다시 읽어야 옛 값이 보이지 않는다.
procedure TFrmSetup.FormShow(Sender: TObject);
begin
  if BtnAbout.Visible then
    FillAbout;   // 감춘 카드를 채우려고 mpv 버전까지 물어볼 이유가 없다

  FillAssoc;   // 연결 상태는 창 밖에서도 바뀌므로 열 때마다 다시 읽는다
  LoadValues;

  // 창이 떠 있는 동안만 감시한다 (닫으면 스레드도 없앤다).
  if FWatcher = nil then
    FWatcher := AssocWatch(
      procedure
      begin
        AssocChanged;
      end);
end;

// 연결 카드 오른쪽 메모에 한 줄. 복사해 붙일 수 있게 시각을 앞에 둔다.
procedure TFrmSetup.LogAssoc(const AMsg: string);
begin
  // 폼 안에서 직접 부르는 곳도 있으므로 여기서도 막는다 (FormCreate 참고)
  if not ReportMemoryLeaksOnShutDown then
    Exit;

  if MemoAssocLog = nil then
    Exit;

  if MemoAssocLog.Lines.Count > 400 then
    MemoAssocLog.Clear;

  MemoAssocLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + AMsg);

  // 마지막 줄이 보이게 스크롤
  SendMessage(MemoAssocLog.Handle, EM_LINESCROLL, 0, MemoAssocLog.Lines.Count);
end;

// 선택 창이나 설정 앱을 다녀오면 기본 앱이 바뀌어 있을 수 있다. 선택 창이
// 닫히는 시점을 알 수 없어, 이 창으로 돌아오는 순간을 뒷정리 지점으로 쓴다.
procedure TFrmSetup.FormActivate(Sender: TObject);
begin
  if (FPicker.Sheet <> 0) or (FPicker.TempFile <> '') then
  begin
    ClosePicker;
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);

    // 선택 창에서 기본 앱이 바뀌었을 수 있다 → 아이콘도 다시 얻는다
    ResetIcons;
  end;

  if (PnlMain.ActiveCard = CardAssoc) and (TreeAssoc.RootNodeCount > 0) then
    RefreshAssocView;
end;

// 창을 닫을 때도 뒷정리한다 (선택 창을 열어 둔 채로 이 창을 닫는 경우).
procedure TFrmSetup.FormHide(Sender: TObject);
begin
  // 대기 중인 체크 반영이 있으면 닫기 전에 마무리한다
  if FApplyTimer.Enabled then
  begin
    FApplyTimer.Enabled := False;
    ApplyAssoc;
  end;

  FWatchTimer.Enabled := False;
  AssocUnwatch(FWatcher);

  ClosePicker;
end;

procedure TFrmSetup.BtnNavClick(Sender: TObject);
var
  B: TSpeedButton;
begin
  B := Sender as TSpeedButton;

  PnlMain.ActiveCardIndex := B.Tag;
  LblTitle.Caption := B.Caption;

  // 다른 카드에 있는 동안 연결이 바뀌었으면 지금 반영한다.
  if FDirty and (PnlMain.ActiveCard = CardAssoc) then
    RefreshAssocView;
end;

// 파일 연결 카드. 상태는 레지스트리에서 직접 읽는다 (INI 에 캐시하지 않는다) —
// 다른 플레이어가 연결을 가져갔을 때 캐시는 거짓말을 한다.

type
  // 트리 노드 데이터. 그룹 헤더 노드와 확장자 노드가 같은 레코드를 쓴다.
  TAssocNode = record
    IsGroup: Boolean;
    Group:   TAssocGroup;
    Index:   Integer;   // AssocExts 인덱스 (그룹 노드는 -1)
    Icon:    Integer;   // FAssocIcons 인덱스 (없으면 -1)
    State:   TAssocState;
  end;
  PAssocNode = ^TAssocNode;

// 확장자의 아이콘을 얻어 이미지 리스트에 넣고 그 인덱스를 돌려준다
// (SHGFI_USEFILEATTRIBUTES 라 그 확장자의 파일이 실제로 없어도 된다).
// 셸 호출이라 38개를 한꺼번에 하면 창이 뜰 때 멈춘다 — 보이는 항목만 부르고
// 결과는 FIconIndex 에 담아 재사용한다.
function TFrmSetup.ExtIconIndex(AIndex: Integer): Integer;
var
  LInfo: TSHFileInfo;
  LIcon: TIcon;
begin
  Result := FIconIndex[AIndex];
  if Result <> IconUnknown then
    Exit;

  Result := -1;   // 실패하면 다시 시도하지 않는다 (셸이 못 주는 확장자다)
  FIconIndex[AIndex] := Result;

  if SHGetFileInfo(PChar('x' + AssocExts[AIndex].Ext), FILE_ATTRIBUTE_NORMAL,
       LInfo, SizeOf(LInfo),
       SHGFI_ICON or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES) = 0 then
    Exit;

  if LInfo.hIcon = 0 then
    Exit;

  LIcon := TIcon.Create;
  try
    LIcon.Handle := LInfo.hIcon;   // TIcon 이 소유권을 가져간다 (Free 에서 파괴)
    Result := FAssocIcons.AddIcon(LIcon);
    FIconIndex[AIndex] := Result;
  finally
    LIcon.Free;
  end;
end;

// 아이콘은 '그 확장자에 지금 연결된 프로그램' 의 것이다. 연결이 바뀌면 옛
// 아이콘이 남으므로 캐시를 버리고 다시 얻게 한다 (보이는 항목만 다시 얻는다).
procedure TFrmSetup.ResetIcons;
var
  I: Integer;
  LNode: PVirtualNode;
  LData: PAssocNode;
begin
  FAssocIcons.Clear;

  for I := 0 to High(FIconIndex) do
    FIconIndex[I] := IconUnknown;

  LNode := TreeAssoc.GetFirst;
  while LNode <> nil do
  begin
    LData := TreeAssoc.GetNodeData(LNode);
    if (LData <> nil) and not LData^.IsGroup then
      LData^.Icon := IconUnknown;

    LNode := TreeAssoc.GetNext(LNode);
  end;
end;

// 체크박스 그림을 직접 만든다. VTV 7 의 CheckImageKind 는 ckSystemDefault /
// ckCustom 둘뿐이고 시스템 것은 강조색으로 꽉 차 너무 튄다.
//
// 그림 순서는 VTV 가 정한 것을 따른다 (BaseAncestorVcl.CreateSystemImageSet):
//   0            빈 그림
//   1..8         라디오 (안 씀. 자리만 채운다)
//   9..12        체크 해제 (보통/마우스/누름/사용불가)
//   13..16       체크
//   17..20       혼합 (그룹의 일부만 체크)
function MakeSoftCheckImages(ASize: Integer): TImageList;
const
  MaskColor = clFuchsia;
var
  LBmp: TBitmap;
  I: Integer;

  procedure PaintOne(AIdx: Integer);
  var
    LRect: TRect;
    LRadio, LChecked, LMixed: Boolean;
    LBorder, LMark: TColor;
    LInset: Integer;
  begin
    LBmp.Canvas.Brush.Color := MaskColor;
    LBmp.Canvas.Brush.Style := bsSolid;
    LBmp.Canvas.FillRect(Rect(0, 0, ASize, ASize));

    LRadio := AIdx < 8;
    LChecked := (AIdx >= 4) and (AIdx <= 7) or ((AIdx >= 12) and (AIdx <= 15));
    LMixed := AIdx >= 16;

    // 상태별 진하기. 마우스가 올라가면 살짝 진해지고, 사용불가는 옅어진다.
    case AIdx mod 4 of
      1: begin LBorder := $00909090; LMark := $00606060; end;   // 마우스 올림
      2: begin LBorder := $00808080; LMark := $00505050; end;   // 누름
      3: begin LBorder := $00D0D0D0; LMark := $00C0C0C0; end;   // 사용불가
    else
      begin LBorder := $00ACACAC; LMark := $00707070; end;      // 보통
    end;

    LRect := Rect(1, 1, ASize - 1, ASize - 1);

    LBmp.Canvas.Brush.Color := clWhite;
    LBmp.Canvas.Pen.Color := LBorder;
    LBmp.Canvas.Pen.Width := 1;

    if LRadio then
      LBmp.Canvas.Ellipse(LRect)
    else
      LBmp.Canvas.Rectangle(LRect);

    if LMixed then
    begin
      // 혼합은 가운데 작은 네모로 (일부만 체크됨)
      LInset := ASize div 4;
      LBmp.Canvas.Brush.Color := LMark;
      LBmp.Canvas.FillRect(Rect(LInset, LInset, ASize - LInset, ASize - LInset));
    end
    else if LChecked then
    begin
      // 체크 표시. 굵기 2px 로 두 선을 긋는다.
      LBmp.Canvas.Pen.Color := LMark;
      LBmp.Canvas.Pen.Width := 2;
      LBmp.Canvas.Polyline([
        Point(ASize div 4, ASize div 2),
        Point(ASize * 45 div 100, ASize * 72 div 100),
        Point(ASize * 78 div 100, ASize * 28 div 100)]);
    end;

    Result.AddMasked(LBmp, MaskColor);
  end;

begin
  Result := TImageList.CreateSize(ASize, ASize);
  Result.Handle := ImageList_Create(ASize, ASize, ILC_COLOR32 or ILC_MASK, 0,
    Result.AllocBy);
  Result.Masked := True;
  Result.BkColor := clWhite;

  LBmp := TBitmap.Create;
  try
    LBmp.SetSize(ASize, ASize);

    // 0번은 빈 그림이다 (VTV 가 '표시 없음' 에 쓴다).
    LBmp.Canvas.Brush.Color := MaskColor;
    LBmp.Canvas.FillRect(Rect(0, 0, ASize, ASize));
    Result.AddMasked(LBmp, MaskColor);

    for I := 0 to 19 do
      PaintOne(I);
  finally
    LBmp.Free;
  end;
end;

// 두 열의 폭을 뱃지 글자 길이에서 정한다. 숫자로 박아 두면 문구를 바꾸거나
// 영어로 바꿀 때 뱃지가 칸에 갇혀 잘린다.
procedure TFrmSetup.LayoutAssocColumns;
const
  // 트리 폭 300 - 테두리 2 - 세로 스크롤바 17
  ColsWidth  = 281;
  CellPadX   = 8;    // 뱃지 밖 여백 (칸 좌우)
  ExtMinWidth = 120; // 확장자 열이 이보다 좁아지지 않게
var
  LBmp: TBitmap;
  LWidth: Integer;
begin
  // 폼 생성 중에도 불리므로 트리의 Canvas 를 쓰지 않는다 (핸들이 없을 수 있다).
  LBmp := TBitmap.Create;
  try
    LBmp.Canvas.Font.Assign(TreeAssoc.Font);
    LBmp.Canvas.Font.Height := BadgeFontSize;

    LWidth := LBmp.Canvas.TextWidth(BadgeTextNormal);
  finally
    LBmp.Free;
  end;

  LWidth := LWidth + (BadgePadX + CellPadX) * 2;

  if LWidth > ColsWidth - ExtMinWidth then
    LWidth := ColsWidth - ExtMinWidth;

  TreeAssoc.Header.Columns[1].Width := LWidth;
  TreeAssoc.Header.Columns[0].Width := ColsWidth - LWidth;
end;

procedure TFrmSetup.SetupAssocTree;
var
  I: Integer;
begin
  FAssocIcons := TImageList.Create(Self);   // 폼이 소유 → 폼과 함께 해제된다
  FAssocIcons.Width := 16;
  FAssocIcons.Height := 16;
  FAssocIcons.ColorDepth := cd32Bit;

  SetLength(FIconIndex, Length(AssocExts));
  for I := 0 to High(FIconIndex) do
    FIconIndex[I] := IconUnknown;

  TreeAssoc.NodeDataSize := SizeOf(TAssocNode);
  TreeAssoc.Images := FAssocIcons;

  // 체크박스는 우리가 그린 것으로 (시스템 것은 강조색으로 꽉 차 너무 진하다)
  FCheckImages := MakeSoftCheckImages(GetSystemMetrics(SM_CXMENUCHECK));
  InsertComponent(FCheckImages);   // 폼이 소유 → 폼과 함께 해제된다
  TreeAssoc.CustomCheckImages := FCheckImages;
  TreeAssoc.CheckImageKind := ckCustom;

  TreeAssoc.BevelInner := bvNone;
  TreeAssoc.BevelOuter := bvNone;
  TreeAssoc.BorderStyle := bsSingle;


  // 헤더는 감추고 (DFM: Header.Options = []) 열은 둘로 쓴다.
  //   0 - 체크박스 + 아이콘 + 확장자
  //   1 - 동작. 남이 기본 앱을 잡고 있으면 [적용안됨] 뱃지를 그리고, 그 칸을
  //       클릭하면 [기본 앱 선택] 창을 띄운다.
  TreeAssoc.Header.Columns.Clear;
  TreeAssoc.Header.Columns.Add;

  with TreeAssoc.Header.Columns.Add do
    Alignment := taCenter;   // 뱃지를 가운데

  LayoutAssocColumns;   // 폭은 뱃지 글자 길이에서 계산한다

  TreeAssoc.Header.MainColumn := 0;

  TreeAssoc.OnBeforeCellPaint := TreeAssocBeforeCellPaint;
  TreeAssoc.OnMouseMove := TreeAssocMouseMove;
  TreeAssoc.OnMouseLeave := TreeAssocMouseLeave;

  // 항목을 클릭하면 판정 근거를 로그에 찍는다 (이 창은 힌트를 쓰지 않는다).
  TreeAssoc.OnClick := TreeAssocClick;

  // 트리 형태 — 접기 버튼, 들여쓰기(DFM Indent = 20), 점선 연결선.
  // 연결선은 toShowTreeLines 만으로 부족하다. 기본으로 들어 있는
  // toHideTreeLinesIfThemed 가 테마가 켜져 있으면 선을 그리지 않으므로 같이
  // 빼야 한다.
  TreeAssoc.TreeOptions.PaintOptions := TreeAssoc.TreeOptions.PaintOptions +
    [toUseBlendedSelection, toHideFocusRect, toUseExplorerTheme, toHotTrack,
     toShowButtons, toShowRoot, toShowTreeLines] -
    [toHideTreeLinesIfThemed];

  TreeAssoc.LineStyle := lsDotted;
  TreeAssoc.LineMode := lmNormal;
  TreeAssoc.TreeOptions.SelectionOptions := TreeAssoc.TreeOptions.SelectionOptions +
    [toFullRowSelect];

  // 행 높이는 고정이다. 다시 재는 경로가 없어야 마우스가 지나가도 두께가
  // 변하지 않는다 (높이는 FillAssoc 이 노드마다 직접 넣는다).
  TreeAssoc.TreeOptions.MiscOptions := TreeAssoc.TreeOptions.MiscOptions +
    [toCheckSupport] - [toAcceptOLEDrop, toVariableNodeHeight];

  // toAutoChangeScale 은 반드시 꺼야 한다. 켜져 있으면 폰트가 바뀔 때마다
  // (CMFontChanged → AutoScale) 행 높이를 '글자 높이 + TextMargin' 으로
  // 덮어쓰고 기존 노드까지 그 비율로 줄인다 — 28 을 넣어도 창이 뜨는 사이에
  // 19 가 되어 있었다.
  TreeAssoc.TreeOptions.AutoOptions :=
    TreeAssoc.TreeOptions.AutoOptions - [toAutoChangeScale];

  TreeAssoc.DefaultNodeHeight := AssocRowHeight;

  // 그룹 노드를 켜고 끄면 자식 체크가 따라간다 (그 반대도)
  TreeAssoc.TreeOptions.AutoOptions := TreeAssoc.TreeOptions.AutoOptions +
    [toAutoTristateTracking];
end;

procedure TFrmSetup.FillAssoc;
var
  LGroup: TAssocGroup;
  LGroupNode, LNode: PVirtualNode;
  LData: PAssocNode;
  I, LOn, LTotal: Integer;
  LTick: UInt64;
begin
  LTick := GetTickCount64;

  FBadgeHot := nil;         // 아래에서 노드를 다 지운다 (남기면 죽은 포인터다)
  FFilling := True;

  // 채우는 동안 삼상태 추적을 끈다. 켜 두면 자식 체크 하나가 그룹을 바꾸고
  // 그 변경이 다시 자식 전체로 퍼져 결국 전부 체크된다. 그룹 상태는 자식을
  // 다 넣은 뒤 직접 정한다.
  TreeAssoc.TreeOptions.AutoOptions :=
    TreeAssoc.TreeOptions.AutoOptions - [toAutoTristateTracking];

  TreeAssoc.BeginUpdate;
  try
    // FAssocIcons 는 비우지 않는다 (FIconIndex 가 인덱스를 들고 있다)
    TreeAssoc.Clear;

    for LGroup := Low(TAssocGroup) to High(TAssocGroup) do
    begin
      LGroupNode := TreeAssoc.AddChild(nil);
      TreeAssoc.NodeHeight[LGroupNode] := AssocRowHeight;
      LData := TreeAssoc.GetNodeData(LGroupNode);
      LData^.IsGroup := True;
      LData^.Group := LGroup;
      LData^.Index := -1;
      LData^.Icon := -1;
      TreeAssoc.CheckType[LGroupNode] := ctTriStateCheckBox;

      LOn := 0;
      LTotal := 0;

      for I := Low(AssocExts) to High(AssocExts) do
      begin
        if AssocExts[I].Group <> LGroup then
          Continue;

        Inc(LTotal);

        LNode := TreeAssoc.AddChild(LGroupNode);
        TreeAssoc.NodeHeight[LNode] := AssocRowHeight;
        LData := TreeAssoc.GetNodeData(LNode);
        LData^.IsGroup := False;
        LData^.Group := LGroup;
        LData^.Index := I;
        LData^.Icon := IconUnknown;   // 처음 그릴 때 얻는다

        LData^.State := AssocStateOf(AssocExts[I].Ext);

        TreeAssoc.CheckType[LNode] := ctCheckBox;

        // 체크는 '등록 여부' 다 (기본 앱 여부가 아니다). 이게 없으면 창을 열고
        // 버튼 한 번 누른 순간 기존 등록이 전부 해제된다.
        if LData^.State.Registered then
        begin
          TreeAssoc.CheckState[LNode] := csCheckedNormal;
          Inc(LOn);
        end;
      end;

      // 그룹 체크는 자식 상태에서 직접 정한다 (삼상태 추적을 껐으므로).
      if LOn = 0 then
        TreeAssoc.CheckState[LGroupNode] := csUncheckedNormal
      else if LOn = LTotal then
        TreeAssoc.CheckState[LGroupNode] := csCheckedNormal
      else
        TreeAssoc.CheckState[LGroupNode] := csMixedNormal;

      TreeAssoc.Expanded[LGroupNode] := True;
    end;
  finally
    TreeAssoc.EndUpdate;

    // 사용자 클릭에는 다시 삼상태 추적이 필요하다 (그룹 클릭 → 자식 전체)
    TreeAssoc.TreeOptions.AutoOptions :=
      TreeAssoc.TreeOptions.AutoOptions + [toAutoTristateTracking];

    FFilling := False;
  end;

  // 느려지면 어디가 무거운지 알아야 한다 (아이콘 조회가 대부분을 차지한다).
  // 소유 목록 개수도 같이 찍는다 — 체크가 이 목록에서 복원되므로, 예상과
  // 다르면 해제가 목록을 못 지운 것이다 (시작 시 SyncFileAssoc 이 되살린다).
  LogAssoc(Format('트리 채우기 %dms (확장자 %d개, 소유 목록 %d개)',
    [GetTickCount64 - LTick, Length(AssocExts), Length(AssocOwnedList)]));

  UpdateAssocHint;
end;

procedure TFrmSetup.TreeAssocFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  LData: PAssocNode;
begin
  LData := Sender.GetNodeData(Node);
  Finalize(LData^);   // State.Other 문자열 해제
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
    CellText := AssocExts[LData^.Index].Ext
  else if AssocNeedsUser(LData^.State) then
    // 사용자가 손대야 넘어오는 경우 — 남이 기본 앱을 쥐고 있거나, 기본 앱이
    // 우리를 가리키는데 등록이 없거나(Broken).
    // 글자는 상태와 무관하게 고정이다 (바꾸면 뱃지 크기가 달라져 거슬린다).
    CellText := BadgeTextNormal;
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
  if (LData = nil) or LData^.IsGroup then Exit;

  // 아이콘은 여기서 처음 얻는다 — 화면에 보이는 항목만 셸에 물어본다.
  if LData^.Icon = IconUnknown then
    LData^.Icon := ExtIconIndex(LData^.Index);

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
    Exit;   // 그룹 노드는 기본 글자색 (들여쓰기와 접기 버튼으로 구분된다)

  // 확장자는 상태와 무관하게 기본 글자색이다. 다른 프로그램이 기본 앱인 것은
  // [강제설정] 뱃지가 뜨는 것으로 알 수 있으므로 색까지 쓰지 않는다.
  if Column > 0 then
  begin
    // 뱃지 안 글자 (배경은 TreeAssocBeforeCellPaint 가 그린다).
    // 11px — 본문보다 작게 해서 태그처럼 보이게 한다.
    TargetCanvas.Font.Height := BadgeFontSize;

    if BadgeBusy then
      TargetCanvas.Font.Color := BadgeDisTextColor
    else
      TargetCanvas.Font.Color := BadgeTextColor;
  end;
end;

// 체크 상태를 레지스트리에 반영한다 (적용 버튼 없이 체크하는 즉시).
// 체크는 '연결 프로그램 후보로 등록' 만을 뜻한다 — 기본 앱 지정은 프로그램이
// 할 수 없어 뱃지를 눌러 선택 창에서 하게 한다.
//
// 트리를 다시 만들지(FillAssoc) 않는 것이 중요하다. 이 프로시저는 OnChecked
// 안에서도 불리는데 그때 노드를 해제하면 VST 가 죽는다. 그래서 표시 갱신은
// RefreshAssocStates 로 제자리에서 한다.
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

      // 바뀐 것만 건드린다. 전부 다시 쓰면 느리고, 백업해 둔 '이전 ProgID' 도
      // 우리 것으로 덮어쓴다.
      if LWant <> AssocOwned(AssocExts[LData^.Index].Ext) then
      begin
        if LWant then
        begin
          LogAssoc(AssocExts[LData^.Index].Ext + ': 후보 등록');
          AssocRegister(LData^.Index);
        end
        else
        begin
          LogAssoc(AssocExts[LData^.Index].Ext + ': 등록 해제');
          AssocUnregister(LData^.Index);
        end;

        Inc(LChanged);
      end;
    end;

    LNode := TreeAssoc.GetNext(LNode);
  end;

  if LChanged = 0 then
    Exit;

  LogAssoc(Format('%d개 처리 완료 (소유 목록 %d개)',
    [LChanged, Length(AssocOwnedList)]));

  // 지금부터 잠깐 오는 알림은 우리가 만든 것이다 (감시가 되받지 않게 한다)
  FQuietUntil := GetTickCount64 + 700;

  EnsureAppRegistered;

  // 모두 선택/해제는 레지스트리 쓰기가 수십 번이라 멈춘 것처럼 보인다
  Screen.Cursor := crHourGlass;

  // 탐색기가 아이콘/연결을 다시 읽게 한다. SHCNF_FLUSH 는 셸의 모든 수신자를
  // 기다려 창이 멈추므로 쓰지 않는다.
  try
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);

    ResetIcons;   // 연결이 바뀌었으니 아이콘도 다시 얻는다
    RefreshAssocStates;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFrmSetup.PickDefaultApp(const AExt: string);
var
  LIndex: Integer;
begin
  if FPicking then
    Exit;   // 이미 띄우는 중이다 (더블클릭·연타로 두 번 들어온다)

  LIndex := AssocIndexOf(AExt);
  if LIndex < 0 then
    Exit;

  LogAssoc(AExt + ': 기본 앱 선택 창 요청');

  if not AssocOwned(AExt) then
  begin
    AssocRegister(LIndex);
    LogAssoc(AExt + ': 후보 등록');
  end;
  EnsureAppRegistered;

  ClosePicker;   // 앞서 열어 둔 것이 남아 있으면 먼저 정리한다

  // 선택 창이 이 창 가운데 근처에 뜨게 한다 (숨긴 속성 창 위치를 기준으로
  // 배치되므로, 그 위치를 여기로 잡아 준다).
  FPicking := True;
  try
    if ShowDefaultAppPicker(AExt, FPicker,
         Point(Left + Width div 2, Top + Height div 2)) then
      Exit;   // 뒷정리와 상태 갱신은 이 창으로 돌아올 때 (FormActivate)

    // 선택 창을 띄우지 못했다 → 설정 앱으로 보낸다.
    ClosePicker;
    LogAssoc(AExt + ': 선택 창 실패 → 설정 앱');
    ShowDefaultApps(Handle, True);
  finally
    FPicking := False;
  end;
end;

procedure TFrmSetup.ClosePicker;
begin
  ClosePickerJob(FPicker);
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
      LData^.State := AssocStateOf(AssocExts[LData^.Index].Ext);

    LNode := TreeAssoc.GetNext(LNode);
  end;

  TreeAssoc.Invalidate;
  UpdateAssocHint;
end;

// 트리 오른쪽 안내문. 평소에는 비워 두고, 남이 기본 앱을 쥐고 있는 확장자가
// 있을 때만 그 개수와 함께 알린다 — 체크(등록)만으로는 안 되는 경우를
// 사용자가 알아야 하기 때문이다.
procedure TFrmSetup.UpdateAssocHint;
var
  LNode: PVirtualNode;
  LData: PAssocNode;
  LOther, LBroken: Integer;
  LText: string;
begin
  LOther := 0;
  LBroken := 0;

  LNode := TreeAssoc.GetFirst;
  while LNode <> nil do
  begin
    LData := TreeAssoc.GetNodeData(LNode);

    // 세는 기준은 뱃지가 뜨는 조건과 같아야 한다 (AssocNeedsUser) — 체크하지
    // 않은 확장자는 남이 쥐고 있어도 알리지 않는다.
    if (LData <> nil) and not LData^.IsGroup and
       AssocNeedsUser(LData^.State) then
      if LData^.State.Broken then
        Inc(LBroken)
      else
        Inc(LOther);

    LNode := TreeAssoc.GetNext(LNode);
  end;

  LText := '';

  if LOther > 0 then
    LText := Format('%d개 확장자를 다른 프로그램이 사용 중입니다. 등록은 되었지만 ' +
      'Windows 가 그쪽을 우선하므로, 기본 앱 설정에서 KPlayer 로 직접 바꿔야 합니다.',
      [LOther]);

  // 기본 앱은 KPlayer 인데 연결이 없는 경우 — 아무것도 열리지 않는 상태다.
  if LBroken > 0 then
  begin
    if LText <> '' then
      LText := LText + sLineBreak + sLineBreak;

    LText := LText + Format('%d개 확장자는 연결이 끊어져 있습니다. ' +
      '[적용안됨] 을 누르면 되살립니다.', [LBroken]);
  end;

  LblAssocHint.Caption := LText;
end;

// 체크하면 즉시 반영한다. 그룹을 클릭하면 자식 체크는 VST 가 바꾸고 이벤트는
// 그룹 하나로 오므로, 개별 노드가 아니라 전체를 훑어 반영한다.
procedure TFrmSetup.TreeAssocChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if FFilling then
    Exit;   // 창을 열며 체크를 복원하는 중이다 — 레지스트리를 건드리면 안 된다

  // 타이머를 다시 걸어 마지막 이벤트 뒤 한 번만 돈다 (모두 선택이면 38번 온다)
  FApplyTimer.Enabled := False;
  FApplyTimer.Enabled := True;
end;

procedure TFrmSetup.ApplyTimerTick(Sender: TObject);
begin
  FApplyTimer.Enabled := False;
  ApplyAssoc;
end;

// 감시 스레드가 변경을 알려 왔다. 여기서 바로 갱신하지 않는다 —
//   · 우리가 방금 쓴 것이면 무시한다 (알림의 대부분이 이것이다)
//   · 연결 카드가 아니면 표시만 해 두고 카드로 올 때 반영한다
//   · 그 외에는 타이머를 다시 걸어 마지막 알림 뒤 한 번만 돈다
procedure TFrmSetup.AssocChanged;
begin
  if GetTickCount64 < FQuietUntil then
    Exit;

  if PnlMain.ActiveCard <> CardAssoc then
  begin
    FDirty := True;
    Exit;
  end;

  FWatchTimer.Enabled := False;
  FWatchTimer.Enabled := True;
end;

procedure TFrmSetup.WatchTimerTick(Sender: TObject);
begin
  FWatchTimer.Enabled := False;
  RefreshAssocView;
end;

// 화면을 지금 상태로 맞춘다 (제자리 갱신만 — 트리를 다시 만들지 않는다).
procedure TFrmSetup.RefreshAssocView;
begin
  FDirty := False;

  ResetIcons;          // 연결이 바뀌면 아이콘도 그 프로그램 것으로 바뀐다
  RefreshAssocStates;
end;

// 클릭 처리. 뱃지 열은 [기본 앱 선택] 창을 띄우고, 확장자 열은 판정 근거를
// 로그에 남긴다.
procedure TFrmSetup.TreeAssocClick(Sender: TObject);
var
  LPos: TPoint;
  LHit: THitInfo;
  LData: PAssocNode;
  LExt: string;
  LLine: string;
begin
  LPos := TreeAssoc.ScreenToClient(Mouse.CursorPos);
  TreeAssoc.GetHitTestInfoAt(LPos.X, LPos.Y, True, LHit);

  if LHit.HitNode = nil then Exit;

  LData := TreeAssoc.GetNodeData(LHit.HitNode);
  if (LData = nil) or LData^.IsGroup then Exit;

  LExt := AssocExts[LData^.Index].Ext;

  if LHit.HitColumn = 1 then
  begin
    if not AssocNeedsUser(LData^.State) then
      Exit;

    // Broken 은 다시 등록하는 것만으로 해결된다. 고를 것이 없는 선택 창을
    // 띄우면 무엇을 하라는 건지 알 수 없으므로 여기서 끝낸다.
    if LData^.State.Broken then
    begin
      AssocRegister(LData^.Index);
      LogAssoc(LExt + ': 연결 되살림 (기본 앱은 이미 KPlayer)');

      // 우리가 쓴 직후의 알림은 감시가 무시하게 한다 (ApplyAssoc 과 같은 처리)
      FQuietUntil := GetTickCount64 + 700;

      RefreshAssocView;
      Exit;
    end;

    // 여는 동안 모든 뱃지를 회색으로. 선택 창을 여는 사이 메시지를 돌리므로
    // 지금 다시 그려 둔다.
    FBadgeBusy := True;
    TreeAssoc.Invalidate;
    TreeAssoc.Update;
    try
      PickDefaultApp(LExt);
    finally
      FBadgeBusy := False;
      TreeAssoc.Invalidate;
    end;

    Exit;
  end;

  LogAssoc(Format('%s: 등록=%s 우리것=%s 잠김=%s 깨짐=%s 상대=%s',
    [LExt, BoolToStr(LData^.State.Registered, True),
     BoolToStr(LData^.State.Ours, True), BoolToStr(LData^.State.Hard, True),
     BoolToStr(LData^.State.Broken, True), LData^.State.Other]));

  for LLine in AssocResolveInfo(LExt).Split([sLineBreak]) do
    LogAssoc('  ' + LLine);
end;

// 선택 창을 여는 중인가 (그 동안 모든 뱃지가 회색이 된다). FBadgeBusy 를 같이
// 보는 이유는 FPicking 이 켜지기 전의 첫 그리기에도 적용해야 하기 때문이다.
function TFrmSetup.BadgeBusy: Boolean;
begin
  Result := FBadgeBusy or FPicking;
end;

// 뱃지 사각형. 글자 크기에 맞춰(좌우 padding 6 / 위아래 4) 칸 가운데에 놓는다 —
// 칸 전체를 채우면 태그가 아니라 버튼처럼 보인다.
function TFrmSetup.BadgeRect(ACanvas: TCanvas; const ACell: TRect): TRect;
var
  LFontHeight: Integer;
  LWidth, LHeight: Integer;
begin
  // 글자 크기는 뱃지 글꼴로 재야 맞는다 (캔버스는 원래대로 돌려 둔다)
  LFontHeight := ACanvas.Font.Height;
  try
    ACanvas.Font.Height := BadgeFontSize;
    LWidth := ACanvas.TextWidth(BadgeTextNormal) + BadgePadX * 2;
    LHeight := ACanvas.TextHeight(BadgeTextNormal) + BadgePadY * 2;
  finally
    ACanvas.Font.Height := LFontHeight;
  end;

  if LWidth > ACell.Width then
    LWidth := ACell.Width;

  // 행 안에서는 위아래로 최소 2px 은 남긴다
  if LHeight > ACell.Height - 4 then
    LHeight := ACell.Height - 4;

  Result.Left := ACell.Left + (ACell.Width - LWidth) div 2;
  Result.Right := Result.Left + LWidth;
  Result.Top := ACell.Top + (ACell.Height - LHeight) div 2;
  Result.Bottom := Result.Top + LHeight;
end;

// 뱃지 배경. 글자는 VST 가 그 위에 그린다 (글꼴과 색은 TreeAssocPaintText).
procedure TFrmSetup.TreeAssocBeforeCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
var
  LData: PAssocNode;
  LRect: TRect;
begin
  if Column <> 1 then Exit;

  LData := Sender.GetNodeData(Node);
  if (LData = nil) or LData^.IsGroup or not AssocNeedsUser(LData^.State) then Exit;

  // 기준은 CellRect 가 아니라 ContentRect 다. VST 는 글자를 ContentRect
  // 가운데에 그리고 열 Margin 은 왼쪽에만 붙으므로, CellRect 로 잡으면 글자가
  // 뱃지 안에서 오른쪽으로 밀린다.
  LRect := BadgeRect(TargetCanvas, ContentRect);

  // 칸을 넘지 않게 (좁은 열에서 ContentRect 가 칸보다 클 수 있다)
  if LRect.Left < CellRect.Left then
    LRect.Offset(CellRect.Left - LRect.Left, 0);
  if LRect.Right > CellRect.Right then
    LRect.Offset(CellRect.Right - LRect.Right, 0);

  if BadgeBusy then
    TargetCanvas.Brush.Color := BadgeDisBackColor
  else
    TargetCanvas.Brush.Color := BadgeBackColor;

  // RoundRect 는 펜으로 윤곽을 그리므로 테두리를 아예 뺄 수 없다. 평소에는
  // 배경색과 같은 펜을 쓰고, 마우스가 올라간 뱃지에만 글자색으로 드러낸다.
  if (Node = FBadgeHot) and not BadgeBusy then
    TargetCanvas.Pen.Color := BadgeTextColor
  else
    TargetCanvas.Pen.Color := TargetCanvas.Brush.Color;

  TargetCanvas.RoundRect(LRect, BadgeRadius, BadgeRadius);
end;

// 뱃지 위에서는 손 모양 커서 — 누를 수 있다는 신호다. 그리고 그 뱃지에만
// 테두리를 그리도록 표시해 둔다 (바뀐 행만 다시 그린다).
procedure TFrmSetup.TreeAssocMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  LHit: THitInfo;
  LData: PAssocNode;
  LHot: PVirtualNode;
begin
  TreeAssoc.GetHitTestInfoAt(X, Y, True, LHit);

  LHot := nil;
  if (LHit.HitNode <> nil) and (LHit.HitColumn = 1) then
  begin
    LData := TreeAssoc.GetNodeData(LHit.HitNode);
    if (LData <> nil) and not LData^.IsGroup and AssocNeedsUser(LData^.State) then
      LHot := LHit.HitNode;
  end;

  // 여는 중에는 누를 수 없으니 손 모양도 주지 않는다
  if (LHot <> nil) and not BadgeBusy then
    TreeAssoc.Cursor := crHandPoint
  else
    TreeAssoc.Cursor := crDefault;

  if LHot = FBadgeHot then Exit;

  if FBadgeHot <> nil then
    TreeAssoc.InvalidateNode(FBadgeHot);

  FBadgeHot := LHot;

  if FBadgeHot <> nil then
    TreeAssoc.InvalidateNode(FBadgeHot);
end;

// 트리를 벗어나면 뱃지 테두리도 지운다 (MouseMove 는 더 오지 않는다).
procedure TFrmSetup.TreeAssocMouseLeave(Sender: TObject);
begin
  if FBadgeHot = nil then Exit;

  TreeAssoc.InvalidateNode(FBadgeHot);
  FBadgeHot := nil;
end;

procedure TFrmSetup.BtnAssocDefaultsClick(Sender: TObject);
begin
  // 체크는 이미 반영되어 있다. 다만 아무것도 체크하지 않았어도 설정 앱의
  // '기본 앱' 목록에는 KPlayer 가 보여야 한다.
  EnsureAppRegistered;

  ShowDefaultApps(Handle, False);
end;

// 선택 버튼 3개를 한 핸들러가 처리한다 (Tag: 0 주요 파일 / 1 모두 선택 /
// 2 모두 해제). 셋 다 지금 체크를 무시하고 결과를 그대로 만든다 — [주요 파일]
// 은 표의 Main 만 켜고 나머지는 끈다.
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
        case LTag of
          1: LOn := True;                                  // 모두 선택
          2: LOn := False;                                  // 모두 해제
        else
          LOn := AssocExts[LData^.Index].Main;              // 주요 파일만
        end;

        if LOn then
          TreeAssoc.CheckState[LNode] := csCheckedNormal
        else
          TreeAssoc.CheckState[LNode] := csUncheckedNormal;
      end;

      LNode := TreeAssoc.GetNext(LNode);
    end;
  finally
    TreeAssoc.EndUpdate;
  end;

  // 위 CheckState 대입으로 OnChecked 가 이미 왔고(VST 의 SetCheckState 는
  // DoCheckClick 을 부른다) 그때마다 타이머가 다시 걸렸다. 여기서 끄고 한 번만
  // 반영한다 — 기다릴 이유가 없다.
  FApplyTimer.Enabled := False;
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
  Config.WriteInteger('save_playlist', 1);
  Config.WriteString('shot_dir', DesktopPath);
  Config.WriteInteger('shot_format', 0);
  Config.WriteInteger('topmost', 0);

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

// 값
procedure TFrmSetup.LoadValues;
begin
  if Config = nil then Exit;

  FLoading := True;
  try
    CboRepeat.ItemIndex := EnsureRange(CfgInt('repeat', 0), 0, CboRepeat.Items.Count - 1);
    CboRandom.ItemIndex := EnsureRange(CfgInt('random', 0), 0, CboRandom.Items.Count - 1);
    SetCboOn(CboSaveList, CfgInt('save_playlist', 1) <> 0);
    EdtShotDir.Text := CfgStr('shot_dir', DesktopPath);
    CboShotFmt.ItemIndex := EnsureRange(CfgInt('shot_format', 0), 0, CboShotFmt.Items.Count - 1);
    SetCboOn(CboTopMost, CfgInt('topmost', 0) <> 0);

    CboHwdec.ItemIndex := EnsureRange(CfgInt('hwdec', 0), 0, CboHwdec.Items.Count - 1);
    CboVo.ItemIndex := EnsureRange(CfgInt('vo', 0), 0, CboVo.Items.Count - 1);
    CboGpuApi.ItemIndex := EnsureRange(CfgInt('gpu_api', 0), 0, CboGpuApi.Items.Count - 1);
    CboScale.ItemIndex := EnsureRange(CfgInt('scale', 0), 0, CboScale.Items.Count - 1);
    CboDeint.ItemIndex := EnsureRange(CfgInt('deinterlace', 0), 0, CboDeint.Items.Count - 1);
    CboVideoSync.ItemIndex := EnsureRange(CfgInt('video_sync', 0), 0, CboVideoSync.Items.Count - 1);

    TrkVolume.Position := EnsureRange(Round(Config.ReadDouble('volume', 100)),
      TrkVolume.Min, TrkVolume.Max);
    SetCboOn(CboNormalize, CfgInt('normalize', 1) <> 0);
    CboNormLevel.ItemIndex := EnsureRange(CfgInt('norm_level', 1), 0, CboNormLevel.Items.Count - 1);

    SetCboOn(CboSubVisible, CfgInt('sub_visible', 0) <> 0);
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

  // shot_dir 은 여기서 쓰지 않는다. 같이 기록하면 '직접 고른 폴더' 와 '기본값이
  // 표시된 것' 을 구분할 수 없어, 나중에 기본 폴더를 바꿔도 반영되지 않는다.
  // [찾기] 로 실제 선택했을 때만 BtnShotDirClick 이 기록한다.

  // 목록 자체는 종료할 때 List.SavePlaylist 가 쓴다 (여기는 켜짐/꺼짐만)
  Config.WriteInteger('save_playlist', B2I(CboOn(CboSaveList)));

  Config.WriteInteger('shot_format', CboShotFmt.ItemIndex);
  Config.WriteInteger('topmost', B2I(CboOn(CboTopMost)));

  Config.WriteInteger('hwdec', CboHwdec.ItemIndex);
  Config.WriteInteger('vo', CboVo.ItemIndex);
  Config.WriteInteger('gpu_api', CboGpuApi.ItemIndex);
  Config.WriteInteger('scale', CboScale.ItemIndex);
  Config.WriteInteger('deinterlace', CboDeint.ItemIndex);
  Config.WriteInteger('video_sync', CboVideoSync.ItemIndex);

  Config.WriteInteger('normalize', B2I(CboOn(CboNormalize)));
  Config.WriteInteger('norm_level', CboNormLevel.ItemIndex);

  Config.WriteInteger('sub_visible', B2I(CboOn(CboSubVisible)));
  Config.WriteInteger('sub_size', TrkSubSize.Position);
  Config.WriteString('sub_lang', EdtSubLang.Text);
end;

// 재시작 없이 반영되는 항목만 mpv 에 넘긴다. vo / gpu-api / hwdec / scale /
// deinterlace / video-sync 는 초기화 옵션이라 Main.FormCreate 에서만 적용된다.
procedure TFrmSetup.ApplyLive;
var
  MPV: TMPVPlayer;
  SubVis: string;
begin
  if FrmKPlayer = nil then Exit;

  // 항상 위는 mpv 와 무관하다 — 플레이어가 없어도 적용해야 하므로 먼저 처리한다.
  FrmKPlayer.SetTopMost(CboOn(CboTopMost));

  MPV := FrmKPlayer.MPVPlayer;
  if MPV = nil then Exit;

  MPV.Command(['set', 'screenshot-directory', EdtShotDir.Text]);
  MPV.Command(['set', 'screenshot-format', ShotFmtValues[CboShotFmt.ItemIndex]]);
  MPV.Command(['set', 'volume', IntToStr(TrkVolume.Position)]);

  if CboOn(CboNormalize) then
    MPV.Command(['set', 'af', NormFilters[CboNormLevel.ItemIndex]])
  else
    MPV.Command(['set', 'af', '']);

  if CboOn(CboSubVisible) then SubVis := 'yes' else SubVis := 'no';

  MPV.Command(['set', 'sub-visibility', SubVis]);
  MPV.Command(['set', 'sub-font-size', IntToStr(TrkSubSize.Position)]);
  MPV.Command(['set', 'slang', EdtSubLang.Text]);
end;

// 이벤트
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

// 설정
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
