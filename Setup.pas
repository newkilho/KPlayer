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
  K.Theme, K.Config.INI, K.Translate, Assoc;

// 캡처 기본 폴더 = 바탕화면. exe 폴더 금지 — Program Files 쓰기 권한 없음 + 프로그램 폴더에 캡처 쌓임.
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
    procedure FormActivate(Sender: TObject);
    procedure FormHide(Sender: TObject);
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

    // 트리 채우는 중 체크 이벤트 무시. CheckState 대입 자체가 OnChecked 를 불러
    // 체크 복원만으로 등록/해제됨.
    FFilling: Boolean;

    // 확장자별 아이콘 인덱스 캐시 (IconUnknown = 미조회). 창 재오픈에도 유지.
    FIconIndex: array of Integer;

    // 체크 이벤트 배칭 타이머. 그룹 체크 = 자식마다 OnChecked → 그대로면 전체 훑기 38회.
    FApplyTimer: TTimer;

    // 레지스트리 감시 — 남이 기본 앱 바꾸면 목록·색·아이콘 재로드.
    //   FWatcher      감시 스레드 (창 떠 있는 동안만)
    //   FWatchTimer   알림 디바운스 (폭주해도 1회 갱신)
    //   FQuietUntil   우리 쓰기 직후 알림 무시 시각
    //   FDirty        연결 카드 밖에서 온 변경 → 카드 진입 시 반영
    FWatcher: TThread;
    FWatchTimer: TTimer;
    FQuietUntil: UInt64;
    FDirty: Boolean;
    FAssocIcons: TImageList;   // 확장자 아이콘 (폼 소유 → 해제 불필요)

    // 직접 그린 체크박스 (이유: MakeSoftCheckImages). InsertComponent 로 폼 소유 → 해제 불필요.
    FCheckImages: TImageList;

    // [기본 앱 선택] 뒷정리 대상 (숨긴 속성 창 + 임시 파일). 닫힘 시점 불명 → 이 창 복귀 시 정리.
    FPicker: TPickerJob;

    // 호버 중인 [적용안됨] 뱃지 — 그 뱃지만 테두리.
    FBadgeHot: PVirtualNode;

    // 선택 창 여는 중 → 모든 뱃지 회색(비활성).
    FBadgeBusy: Boolean;

    // 선택 창 띄우는 중 — 내부에서 메시지 루프 돌므로 연타 방지.
    FPicking: Boolean;

    // 트리에 그릴 번역 문구. _() 는 리소스 전체를 훑는데 GetText 는 셀마다 불린다 —
    // 그대로 두면 스크롤이 끈다. 갱신 지점은 FormCreate 한 곳.
    FGroupText: array[TAssocGroup] of string;
    FBadgeText: string;

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
  // 아이콘 캐시 미조회 표시 (-1 = 셸이 못 줌)
  IconUnknown = -2;

  // 연결 트리 행 두께 — 여기만 고침 (재생목록은 List.pas 의 24). 방식 동일:
  // toVariableNodeHeight·toAutoChangeScale 끄고 노드마다 NodeHeight 직접 대입.
  // OnMeasureItem 은 마우스 지나간 행만 재측정 → 두께 들썩임.
  AssocRowHeight = 28;

  // 상태 뱃지 = HTML 규격 이식 (padding 0 6px / radius 3px / 11px, 배경 #fde8e8,
  // 글자 #9b1c1c). 창 라이트 고정 → 다크 값 없음. 테두리 평소 없음, 호버 시
  // 글자색. Delphi 색상 = BGR.
  BadgeBackColor = $00E8E8FD;
  BadgeTextColor = $001C1C9B;   // 호버 테두리도 이 색
  BadgeRadius    = 3;           // 크게 주면 GDI 계단
  BadgeFontSize  = -11;
  BadgePadX      = 6;
  // 높이 = 글자 높이 + 상하 이 값 (고정 아님). 11px 글자 실높이 15px → 18 고정 시 여백 1/2 갈림.
  BadgePadY      = 4;

  // 선택 창 여는 동안 비활성 색. 문구 바꾸면 뱃지 크기 변동 → 글자 유지, 회색만.
  BadgeDisBackColor = $00F0F0F0;
  BadgeDisTextColor = $00A0A0A0;

  // 글자는 '할 일' 아닌 '상태' — 체크로 등록 완료라 적용 요구 문구는 혼동.
  // 클릭 가능 신호 = 호버 테두리 + 손 커서.
  BadgeTextNormal = '적용안됨';

{$R *.dfm}

{$I Const.inc}

function B2I(AValue: Boolean): Integer;
begin
  if AValue then Result := 1 else Result := 0;
end;

// 온오프 항목 = '사용안함/사용함' 콤보. 0 = 사용안함 고정 — 뒤집으면 기존 설정 0/1 의미 반전.
function CboOn(ACombo: TComboBox): Boolean;
begin
  Result := ACombo.ItemIndex = 1;
end;

procedure SetCboOn(ACombo: TComboBox; AValue: Boolean);
begin
  ACombo.ItemIndex := B2I(AValue);
end;

// CSIDL_DESKTOPDIRECTORY 는 OneDrive 리디렉션·타 언어에서도 실제 경로 (USERPROFILE+'\Desktop' 조립은 그때 틀림).
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
var
  LGroup: TAssocGroup;
begin
  PnlMain.ActiveCardIndex := 0;
  LblTitle.Caption := BtnGeneral.Caption;

  Translate(Self);

  // 트리에 그릴 문구는 미리 캐시 — SetupAssocTree 의 열 폭 계산이 뱃지 번역문을 잰다.
  for LGroup := Low(TAssocGroup) to High(TAssocGroup) do
    FGroupText[LGroup] := _(AssocGroupNames[LGroup]);

  FBadgeText := _(BadgeTextNormal);

  SetupAssocTree;

  FApplyTimer := TTimer.Create(Self);
  FApplyTimer.Enabled := False;
  FApplyTimer.Interval := 80;
  FApplyTimer.OnTimer := ApplyTimerTick;

  FWatchTimer := TTimer.Create(Self);
  FWatchTimer.Enabled := False;
  FWatchTimer.Interval := 300;
  FWatchTimer.OnTimer := WatchTimerTick;

  // 로그·정보 카드는 디버그 빌드 전용 (Main.pas 의 lua 경로 분기와 같은 기준).
  // 훅 없으면 Assoc.pas 는 문자열도 안 만듦.
  MemoAssocLog.Visible := ReportMemoryLeaksOnShutDown;
  BtnAbout.Visible := ReportMemoryLeaksOnShutDown;

  if ReportMemoryLeaksOnShutDown then
  begin
    AssocLogProc :=
      procedure(AMsg: string)
      begin
        LogAssoc(AMsg);
      end;

    // 로그 복사 보고용 — 앞머리에 환경 기록.
    LogAssoc('exe = ' + ParamStr(0));
    LogAssoc(AssocEnvInfo);
    LogAssoc(Format('Windows %d.%d build %d',
      [TOSVersion.Major, TOSVersion.Minor, TOSVersion.Build]));
  end;

  SetTheme(Self);
end;

// 폼은 1회 생성, ShowModal 재사용. 볼륨·반복·연결 상태는 창 밖에서도 바뀜 → 열 때마다 재로드.
procedure TFrmSetup.FormShow(Sender: TObject);
begin
  if BtnAbout.Visible then
    FillAbout;   // 감춘 카드에 mpv 버전 조회 불필요

  FillAssoc;
  LoadValues;

  // 창 떠 있는 동안만 감시 (닫으면 스레드 해제).
  if FWatcher = nil then
    FWatcher := AssocWatch(
      procedure
      begin
        AssocChanged;
      end);
end;

// 연결 카드 메모에 한 줄. 복사용 시각 접두.
procedure TFrmSetup.LogAssoc(const AMsg: string);
begin
  // 폼 내부 직접 호출도 있어 여기서도 차단 (FormCreate 참고)
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

// 선택 창/설정 앱 다녀오면 기본 앱 변동 가능. 닫힘 시점 불명 → 이 창 복귀 순간이 뒷정리 지점.
procedure TFrmSetup.FormActivate(Sender: TObject);
begin
  if (FPicker.Sheet <> 0) or (FPicker.TempFile <> '') then
  begin
    ClosePicker;
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);

    // 기본 앱 변동 가능 → 아이콘 재취득
    ResetIcons;
  end;

  if (PnlMain.ActiveCard = CardAssoc) and (TreeAssoc.RootNodeCount > 0) then
    RefreshAssocView;
end;

// 창 닫을 때도 뒷정리 (선택 창 열어 둔 채 닫는 경우).
procedure TFrmSetup.FormHide(Sender: TObject);
begin
  // 대기 중 체크 반영 마무리
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

  // 타 카드에 있는 동안의 연결 변경분 반영.
  if FDirty and (PnlMain.ActiveCard = CardAssoc) then
    RefreshAssocView;
end;

// 파일 연결 카드. 상태는 레지스트리 직접 읽기 (INI 캐시 금지 — 남이 연결 가져가면 캐시가 거짓말).

type
  // 트리 노드 데이터 — 그룹 헤더/확장자 노드 공용.
  TAssocNode = record
    IsGroup: Boolean;
    Group:   TAssocGroup;
    Index:   Integer;   // AssocExts 인덱스 (그룹 노드는 -1)
    Icon:    Integer;   // FAssocIcons 인덱스 (없으면 -1)
    State:   TAssocState;
  end;
  PAssocNode = ^TAssocNode;

// 확장자 아이콘을 이미지 리스트에 넣고 인덱스 반환 (SHGFI_USEFILEATTRIBUTES →
// 실제 파일 불필요). 셸 호출이라 38개 일괄 시 창 멈춤 — 보이는 항목만 부르고
// 결과는 FIconIndex 재사용.
function TFrmSetup.ExtIconIndex(AIndex: Integer): Integer;
var
  LInfo: TSHFileInfo;
  LIcon: TIcon;
begin
  Result := FIconIndex[AIndex];
  if Result <> IconUnknown then
    Exit;

  Result := -1;   // 실패 시 재시도 안 함 (셸이 못 주는 확장자)
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

// 아이콘 = 현재 연결 프로그램 것. 연결 변경 시 옛 아이콘 잔존 → 캐시 버리고 재취득 (보이는 항목만).
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

// 체크박스 직접 그림. VTV 7 CheckImageKind = ckSystemDefault/ckCustom 뿐,
// 시스템 것은 강조색 꽉 차 튐.
// 그림 순서 = VTV 규약 (BaseAncestorVcl.CreateSystemImageSet):
//   0 빈 그림 / 1..8 라디오(안 씀, 자리 채움) / 9..12 체크 해제(보통/마우스/
//   누름/사용불가) / 13..16 체크 / 17..20 혼합(그룹 일부만 체크)
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

    // 상태별 진하기: 호버 살짝 진하게, 사용불가 옅게.
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
      // 혼합 = 가운데 작은 네모 (일부만 체크)
      LInset := ASize div 4;
      LBmp.Canvas.Brush.Color := LMark;
      LBmp.Canvas.FillRect(Rect(LInset, LInset, ASize - LInset, ASize - LInset));
    end
    else if LChecked then
    begin
      // 체크 표시 — 2px 두 선.
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

    // 0번 = 빈 그림 (VTV '표시 없음' 용).
    LBmp.Canvas.Brush.Color := MaskColor;
    LBmp.Canvas.FillRect(Rect(0, 0, ASize, ASize));
    Result.AddMasked(LBmp, MaskColor);

    for I := 0 to 19 do
      PaintOne(I);
  finally
    LBmp.Free;
  end;
end;

// 열 폭 = 뱃지 글자 길이 기반. 숫자 고정 시 문구/언어 변경에 뱃지가 칸에 갇혀 잘림.
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
  // 폼 생성 중에도 불림 → 트리 Canvas 금지 (핸들 없을 수 있음).
  LBmp := TBitmap.Create;
  try
    LBmp.Canvas.Font.Assign(TreeAssoc.Font);
    LBmp.Canvas.Font.Height := BadgeFontSize;

    LWidth := LBmp.Canvas.TextWidth(FBadgeText);
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
  FAssocIcons := TImageList.Create(Self);
  FAssocIcons.Width := 16;
  FAssocIcons.Height := 16;
  FAssocIcons.ColorDepth := cd32Bit;

  SetLength(FIconIndex, Length(AssocExts));
  for I := 0 to High(FIconIndex) do
    FIconIndex[I] := IconUnknown;

  TreeAssoc.NodeDataSize := SizeOf(TAssocNode);
  TreeAssoc.Images := FAssocIcons;

  FCheckImages := MakeSoftCheckImages(GetSystemMetrics(SM_CXMENUCHECK));
  InsertComponent(FCheckImages);   // 폼이 소유 → 폼과 함께 해제된다
  TreeAssoc.CustomCheckImages := FCheckImages;
  TreeAssoc.CheckImageKind := ckCustom;

  TreeAssoc.BevelInner := bvNone;
  TreeAssoc.BevelOuter := bvNone;
  TreeAssoc.BorderStyle := bsSingle;


  // 헤더 감춤 (DFM: Header.Options = []), 열 둘:
  //   0 체크박스+아이콘+확장자
  //   1 동작 — 남이 기본 앱이면 [적용안됨] 뱃지, 그 칸 클릭 시 [기본 앱 선택] 창.
  TreeAssoc.Header.Columns.Clear;
  TreeAssoc.Header.Columns.Add;

  with TreeAssoc.Header.Columns.Add do
    Alignment := taCenter;   // 뱃지를 가운데

  LayoutAssocColumns;

  TreeAssoc.Header.MainColumn := 0;

  TreeAssoc.OnBeforeCellPaint := TreeAssocBeforeCellPaint;
  TreeAssoc.OnMouseMove := TreeAssocMouseMove;
  TreeAssoc.OnMouseLeave := TreeAssocMouseLeave;

  // 클릭 시 판정 근거 로그 (이 창은 힌트 미사용).
  TreeAssoc.OnClick := TreeAssocClick;

  // 트리 형태 — 접기 버튼, 들여쓰기(DFM Indent=20), 점선 연결선. toShowTreeLines
  // 만으론 부족 — 기본 포함된 toHideTreeLinesIfThemed 가 테마 시 선 생략 → 같이 제거.
  TreeAssoc.TreeOptions.PaintOptions := TreeAssoc.TreeOptions.PaintOptions +
    [toUseBlendedSelection, toHideFocusRect, toUseExplorerTheme, toHotTrack,
     toShowButtons, toShowRoot, toShowTreeLines] -
    [toHideTreeLinesIfThemed];

  TreeAssoc.LineStyle := lsDotted;
  TreeAssoc.LineMode := lmNormal;
  TreeAssoc.TreeOptions.SelectionOptions := TreeAssoc.TreeOptions.SelectionOptions +
    [toFullRowSelect];

  // 행 높이 고정 — 재측정 경로 없어야 호버에도 불변 (높이는 FillAssoc 이 노드마다 대입).
  TreeAssoc.TreeOptions.MiscOptions := TreeAssoc.TreeOptions.MiscOptions +
    [toCheckSupport] - [toAcceptOLEDrop, toVariableNodeHeight];

  // toAutoChangeScale 필수 OFF. 켜면 폰트 변경마다 (CMFontChanged → AutoScale)
  // 행 높이를 '글자 높이+TextMargin' 으로 덮고 기존 노드도 비율 축소 —
  // 28 넣어도 창 뜨는 사이 19 됨.
  TreeAssoc.TreeOptions.AutoOptions :=
    TreeAssoc.TreeOptions.AutoOptions - [toAutoChangeScale];

  TreeAssoc.DefaultNodeHeight := AssocRowHeight;

  // 그룹 체크 ↔ 자식 체크 연동
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

  FBadgeHot := nil;         // 아래에서 노드 전부 삭제 (남기면 죽은 포인터)
  FFilling := True;

  // 채우는 동안 삼상태 추적 OFF. 켜 두면 자식 체크 하나 → 그룹 변경 → 자식 전체
  // 전파 → 전부 체크됨. 그룹 상태는 자식 삽입 후 직접 결정.
  TreeAssoc.TreeOptions.AutoOptions :=
    TreeAssoc.TreeOptions.AutoOptions - [toAutoTristateTracking];

  TreeAssoc.BeginUpdate;
  try
    // FAssocIcons 는 안 비움 (FIconIndex 가 인덱스 보유)
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
        LData^.Icon := IconUnknown;   // 첫 그리기 때 취득

        LData^.State := AssocStateOf(AssocExts[I].Ext);

        TreeAssoc.CheckType[LNode] := ctCheckBox;

        // 체크 = 등록 여부 (기본 앱 아님). 없으면 창 열고 버튼 한 번에 기존 등록 전부 해제됨.
        if LData^.State.Registered then
        begin
          TreeAssoc.CheckState[LNode] := csCheckedNormal;
          Inc(LOn);
        end;
      end;

      // 그룹 체크는 자식 상태로 직접 결정 (삼상태 추적 OFF 상태).
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

    // 사용자 클릭엔 삼상태 추적 복원 (그룹 클릭 → 자식 전체)
    TreeAssoc.TreeOptions.AutoOptions :=
      TreeAssoc.TreeOptions.AutoOptions + [toAutoTristateTracking];

    FFilling := False;
  end;

  // 병목 추적용 (대부분 아이콘 조회). 소유 목록 개수도 기록 — 체크는 이 목록에서
  // 복원되므로 예상과 다르면 해제가 목록 못 지운 것 (시작 시 SyncFileAssoc 이 되살림).
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
      CellText := FGroupText[LData^.Group];
    Exit;
  end;

  if Column <= 0 then
    CellText := AssocExts[LData^.Index].Ext
  else if AssocNeedsUser(LData^.State) then
    // 사용자 개입 필요 — 남이 기본 앱이거나, 기본 앱은 우리인데 등록 없음(Broken).
    // 글자는 상태 무관 고정 (바꾸면 뱃지 크기 변동, 거슬림).
    CellText := FBadgeText;
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

  // 아이콘 최초 취득 지점 — 보이는 항목만 셸 조회.
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
    Exit;   // 그룹 노드는 기본 글자색 (들여쓰기·접기 버튼으로 구분)

  // 확장자도 상태 무관 기본 글자색 — 남이 기본 앱임은 [적용안됨] 뱃지로 충분, 색 불사용.
  if Column > 0 then
  begin
    // 뱃지 안 글자 (배경은 TreeAssocBeforeCellPaint). 11px = 본문보다 작게 → 태그 느낌.
    TargetCanvas.Font.Height := BadgeFontSize;

    if BadgeBusy then
      TargetCanvas.Font.Color := BadgeDisTextColor
    else
      TargetCanvas.Font.Color := BadgeTextColor;
  end;
end;

// 체크 상태를 레지스트리에 즉시 반영 (적용 버튼 없음). 체크 = 후보 등록만 —
// 기본 앱 지정은 프로그램 불가, 뱃지 → 선택 창에서.
// 트리 재생성(FillAssoc) 금지 — OnChecked 안에서도 불리는데 그때 노드 해제하면
// VST 죽음. 표시 갱신은 RefreshAssocStates 로 제자리에서.
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

      // 변경분만 — 전부 다시 쓰면 느리고 백업된 '이전 ProgID' 도 우리 것으로 덮임.
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

  // 직후 알림은 우리 것 — 감시가 되받지 않게
  FQuietUntil := GetTickCount64 + 700;

  EnsureAppRegistered;

  // 모두 선택/해제 = 레지스트리 쓰기 수십 번 → 멈춘 듯 보임
  Screen.Cursor := crHourGlass;

  // 탐색기 아이콘/연결 재로드. SHCNF_FLUSH 는 셸 전체 수신자 대기 → 창 멈춤, 금지.
  try
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);

    ResetIcons;   // 연결 변경 → 아이콘 재취득
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
    Exit;   // 이미 띄우는 중 (더블클릭·연타 재진입)

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

  ClosePicker;   // 이전 잔여분 먼저 정리

  // 선택 창을 이 창 가운데 근처에 — 숨긴 속성 창 위치 기준으로 배치되므로 그 위치를 여기로.
  FPicking := True;
  try
    if ShowDefaultAppPicker(AExt, FPicker,
         Point(Left + Width div 2, Top + Height div 2)) then
      Exit;   // 뒷정리·상태 갱신은 이 창 복귀 시 (FormActivate)

    // 선택 창 실패 → 설정 앱.
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

// 노드 재생성 없이 상태(연결 프로그램/기본 앱)만 재로드. 아이콘 유지 —
// 이미지 리스트 재생성 필요하고, 등록으로 바뀐 아이콘은 창 재오픈 시 반영.
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

// 트리 오른쪽 안내문. 평소 빈 채, 남이 기본 앱인 확장자 있을 때만 개수와 함께 —
// 체크(등록)만으론 안 되는 경우를 사용자가 알아야 함.
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

    // 세는 기준 = 뱃지 조건 (AssocNeedsUser) — 미체크 확장자는 남이 쥐어도 미고지.
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
    LText := Format(_('%d개 확장자를 다른 프로그램이 사용 중입니다. 등록은 되었지만 ' +
      'Windows 가 그쪽을 우선하므로, 기본 앱 설정에서 KPlayer 로 직접 바꿔야 합니다.'),
      [LOther]);

  // 기본 앱 = KPlayer 인데 연결 없음 — 아무것도 안 열리는 상태.
  if LBroken > 0 then
  begin
    if LText <> '' then
      LText := LText + sLineBreak + sLineBreak;

    LText := LText + Format(_('%d개 확장자는 연결이 끊어져 있습니다. ' +
      '[적용안됨] 을 누르면 되살립니다.'), [LBroken]);
  end;

  LblAssocHint.Caption := LText;
end;

// 체크 즉시 반영. 그룹 클릭 시 자식 체크는 VST 가 바꾸고 이벤트는 그룹 하나 → 전체 훑어 반영.
procedure TFrmSetup.TreeAssocChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if FFilling then
    Exit;   // 체크 복원 중 — 레지스트리 금지

  // 타이머 재장전 — 마지막 이벤트 뒤 1회 (모두 선택 시 38번 옴)
  FApplyTimer.Enabled := False;
  FApplyTimer.Enabled := True;
end;

procedure TFrmSetup.ApplyTimerTick(Sender: TObject);
begin
  FApplyTimer.Enabled := False;
  ApplyAssoc;
end;

// 감시 스레드 변경 통지. 즉시 갱신 안 함 — 우리가 방금 쓴 것 무시(알림 대부분),
// 연결 카드 밖이면 FDirty 만 (카드 진입 시 반영), 그 외 타이머 재장전으로 마지막 알림 뒤 1회.
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

// 화면을 현 상태로 (제자리 갱신만 — 트리 재생성 없음).
procedure TFrmSetup.RefreshAssocView;
begin
  FDirty := False;

  ResetIcons;          // 연결 변경 → 아이콘도 그 프로그램 것
  RefreshAssocStates;
end;

// 클릭: 뱃지 열 = [기본 앱 선택] 창, 확장자 열 = 판정 근거 로그.
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

    // Broken 은 재등록만으로 해결 — 고를 것 없는 선택 창은 혼란만, 여기서 끝.
    if LData^.State.Broken then
    begin
      AssocRegister(LData^.Index);
      LogAssoc(LExt + ': 연결 되살림 (기본 앱은 이미 KPlayer)');

      // 직후 알림 무시 (ApplyAssoc 과 동일)
      FQuietUntil := GetTickCount64 + 700;

      RefreshAssocView;
      Exit;
    end;

    // 여는 동안 전 뱃지 회색. 여는 사이 메시지 루프 돌므로 지금 다시 그려 둠.
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

// 선택 창 여는 중? (전 뱃지 회색). FBadgeBusy 병행 — FPicking 켜지기 전 첫 그리기에도 적용 위해.
function TFrmSetup.BadgeBusy: Boolean;
begin
  Result := FBadgeBusy or FPicking;
end;

// 뱃지 사각형 — 글자 크기 기준(padding 좌우 6/상하 4) 칸 가운데. 칸 전체 채우면 버튼처럼 보임.
function TFrmSetup.BadgeRect(ACanvas: TCanvas; const ACell: TRect): TRect;
var
  LFontHeight: Integer;
  LWidth, LHeight: Integer;
begin
  // 글자 크기는 뱃지 글꼴로 측정 (캔버스 원복)
  LFontHeight := ACanvas.Font.Height;
  try
    ACanvas.Font.Height := BadgeFontSize;
    LWidth := ACanvas.TextWidth(FBadgeText) + BadgePadX * 2;
    LHeight := ACanvas.TextHeight(FBadgeText) + BadgePadY * 2;
  finally
    ACanvas.Font.Height := LFontHeight;
  end;

  if LWidth > ACell.Width then
    LWidth := ACell.Width;

  // 행 안 상하 최소 2px 여백
  if LHeight > ACell.Height - 4 then
    LHeight := ACell.Height - 4;

  Result.Left := ACell.Left + (ACell.Width - LWidth) div 2;
  Result.Right := Result.Left + LWidth;
  Result.Top := ACell.Top + (ACell.Height - LHeight) div 2;
  Result.Bottom := Result.Top + LHeight;
end;

// 뱃지 배경. 글자는 VST 가 위에 (글꼴·색은 TreeAssocPaintText).
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

  // 기준 = ContentRect (CellRect 아님). VST 는 글자를 ContentRect 가운데,
  // 열 Margin 은 왼쪽만 → CellRect 기준이면 글자가 뱃지에서 오른쪽 밀림.
  LRect := BadgeRect(TargetCanvas, ContentRect);

  // 칸 안 넘게 (좁은 열에선 ContentRect > 칸 가능)
  if LRect.Left < CellRect.Left then
    LRect.Offset(CellRect.Left - LRect.Left, 0);
  if LRect.Right > CellRect.Right then
    LRect.Offset(CellRect.Right - LRect.Right, 0);

  if BadgeBusy then
    TargetCanvas.Brush.Color := BadgeDisBackColor
  else
    TargetCanvas.Brush.Color := BadgeBackColor;

  // RoundRect 는 펜 윤곽 필수 (테두리 제거 불가) — 평소 펜 = 배경색, 호버 뱃지만 글자색.
  if (Node = FBadgeHot) and not BadgeBusy then
    TargetCanvas.Pen.Color := BadgeTextColor
  else
    TargetCanvas.Pen.Color := TargetCanvas.Brush.Color;

  TargetCanvas.RoundRect(LRect, BadgeRadius, BadgeRadius);
end;

// 뱃지 위 = 손 모양 커서(누를 수 있다는 신호) + 그 뱃지만 테두리 표시.
// 바뀐 행만 재그리기.
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

  // 여는 중 = 누를 수 없음 → 손 모양도 없음
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

// 트리 벗어남 → 뱃지 테두리 제거 (MouseMove 더 안 옴).
procedure TFrmSetup.TreeAssocMouseLeave(Sender: TObject);
begin
  if FBadgeHot = nil then Exit;

  TreeAssoc.InvalidateNode(FBadgeHot);
  FBadgeHot := nil;
end;

procedure TFrmSetup.BtnAssocDefaultsClick(Sender: TObject);
begin
  // 체크는 이미 반영됨. 단 체크 0개여도 설정 앱 '기본 앱' 목록에 KPlayer 노출 필요.
  EnsureAppRegistered;

  ShowDefaultApps(Handle, False);
end;

// 선택 버튼 3개 공용 핸들러 (Tag 0=주요 파일 / 1=모두 선택 / 2=모두 해제).
// 셋 다 현재 체크 무시하고 결과를 덮어씀 — [주요 파일] = 표의 Main 만 켜고 나머지 끔.
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

      // 그룹 노드는 자식 체크 따라 자동 (toAutoTristateTracking)
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

  // 위 CheckState 대입 → OnChecked 이미 발생(VST SetCheckState 가 DoCheckClick 호출),
  // 매번 타이머 재설정됨. 여기서 끄고 한 번만 반영 — 기다릴 이유 없음.
  FApplyTimer.Enabled := False;
  ApplyAssoc;
end;

procedure TFrmSetup.BtnResetClick(Sender: TObject);
begin
  if Config = nil then Exit;

  if TaskMessageDlg(_('모든 설정을 기본값으로 되돌립니다.'),
       _('지금 화면의 값과 저장된 설정이 모두 기본값으로 바뀝니다.') + sLineBreak +
       _('파일 연결은 바뀌지 않습니다.'),
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

  // LoadValues 는 FLoading 중 → 컨트롤 이벤트 죽음. SaveValues 직접 호출해
  // Main 메모리의 반복/랜덤/볼륨까지 갱신 (List.pas 가 FrmKPlayer.RepeatMode 를
  // 직접 읽음 → INI 만 고치면 부족).
  LoadValues;
  SaveValues;
  ApplyLive;
end;

procedure TFrmSetup.BtnShotDirClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := EdtShotDir.Text;

  if SelectDirectory(_('스크린샷을 저장할 폴더를 선택하세요.'), '', Dir) then
  begin
    EdtShotDir.Text := Dir;

    // 직접 고른 경우에만 INI 기록 (SaveValues 는 이 키 안 건드림)
    if Config <> nil then
      Config.WriteString('shot_dir', Dir);

    ControlChange(Sender);
  end;
end;

// 정보 카드 — 버전은 런타임에만 알 수 있어 여기서 채움.
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
  MemAbout.Lines.Add(_('실행 파일') + ': ' + ParamStr(0));
  MemAbout.Lines.Add('');
  MemAbout.Lines.Add(_('이 프로그램은 libmpv (GPL-2.0-or-later) 를 사용합니다.'));
  MemAbout.Lines.Add(_('재생 목록은 Virtual Treeview (MPL 1.1) 를 사용합니다.'));
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

  // 반복/랜덤/볼륨 = Main 이 값+저장 소유 → 프로퍼티로 전달.
  if FrmKPlayer <> nil then
  begin
    FrmKPlayer.RepeatMode := CboRepeat.ItemIndex;
    FrmKPlayer.RandomMode := CboRandom.ItemIndex;
    FrmKPlayer.Volume := TrkVolume.Position;
  end;

  // shot_dir 기록 금지 — 같이 쓰면 '직접 고른 폴더' 와 '기본값 표시' 구분 불가 →
  // 나중에 기본 폴더 바꿔도 반영 안 됨. [찾기] 로 실제 선택 시 BtnShotDirClick 만 기록.

  // 목록 자체는 종료 시 List.SavePlaylist 가 기록 (여기는 켜짐/꺼짐만)
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

// 재시작 없이 반영되는 항목만 mpv 로. vo / gpu-api / hwdec / scale / deinterlace /
// video-sync = 초기화 옵션 → Main.FormCreate 에서만 적용.
procedure TFrmSetup.ApplyLive;
var
  MPV: TMPVPlayer;
  SubVis: string;
begin
  if FrmKPlayer = nil then Exit;

  // 항상 위 = mpv 무관 → 플레이어 없어도 적용해야 하므로 먼저.
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
