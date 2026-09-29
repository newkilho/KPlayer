unit List;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Types, StrUtils, Math, Generics.Collections,
  Graphics, Controls, Forms, Dialogs, StdCtrls, ExtCtrls, Menus, LCLType, LCLIntf,
  laz.VirtualTrees, VTScrollbar, IconButton, KTranslate, Media;

type
  TDeleteMode = (
    dmSelected,
    dmUnselected,
    dmAll,
    dmMissing
  );

  TItemData = record
    FileName: string;
    IsActive: Boolean;
    Missing: Boolean;   // 파일 없음. 판정은 TFileCheckThread — 그리기 경로에서 디스크 안 본다.
  end;
  PItemData = ^TItemData;

  { TFrmList }

  TFrmList = class(TForm)
    Panel1: TPanel;
    PopAdd: TPopupMenu;
    PopDel: TPopupMenu;
    BtnAddPopup: TMenuItem;
    BtnAddPopupFolder: TMenuItem;
    BtnDelPopup: TMenuItem;
    BtnDelPopupUnselected: TMenuItem;
    BtnDelPopupAll: TMenuItem;
    BtnDelPopupMissing: TMenuItem;
    PopMenu: TPopupMenu;
    BtnDelContext: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure BtnDelPopupClick(Sender: TObject);
    procedure BtnDelPopupUnselectedClick(Sender: TObject);
    procedure BtnDelPopupAllClick(Sender: TObject);
    procedure BtnDelPopupMissingClick(Sender: TObject);
    procedure BtnDelContextClick(Sender: TObject);
    procedure BtnAddPopupClick(Sender: TObject);
    procedure BtnAddPopupFolderClick(Sender: TObject);
    procedure ListDataFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure ListDataGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure ListDataPaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
    procedure ListDataNodeDblClick(Sender: TBaseVirtualTree;
      const HitInfo: THitInfo);
    procedure ListDataKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ListDataMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListDataMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ListDataMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    // 하단 아이콘 버튼 — 코드로 만든다 (IconButton 머리말). Tag 1=반복 2=랜덤 3=추가 4=삭제
    BtnRepeat: TIconButton;
    BtnRandom: TIconButton;
    BtnAdd: TIconButton;
    BtnDel: TIconButton;

    FDarkSB: TVTDarkScrollbar;
    FDragNode: PVirtualNode;
    FPlaylistDepth: Integer;   // 재생목록 상호 참조 무한 재귀 방지
    FSkipDepth: Integer;       // 없는 파일 연속 건너뛰기 안전장치
    FDragStart: TPoint;
    FSavedSelection: array of PVirtualNode;
    FAddSeen: TDictionary<string, Boolean>;   // 일괄 추가 중에만 사는 중복 검사표 (nil = 노드 선형 검사)
    FAddFirst: string;                        // 일괄 추가 중 처음 만난 미디어 경로 (전부 중복일 때의 재생 기준)

    // 랜덤 상태 (사이클 내 중복 없음)
    FShuffleHistory: TStringArray;    // 실제 재생 순서 (Prev 가 되짚음)
    FShufflePos: Integer;             // 현재 곡 이력 인덱스 (-1=없음)
    FCyclePlayed: TStringList;        // 이번 사이클 재생 완료 파일

    function MakeButton(ATag, AImage, ALeft: Integer): TIconButton;
    procedure BtnMouseEnter(Sender: TObject);
    procedure BtnMouseLeave(Sender: TObject);
    procedure BtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BtnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

    function FindActiveNode: PVirtualNode;
    procedure UpdateButtonColor(Btn: TIconButton; Hover: Boolean);
    procedure ScrollFocusedAsync(Data: PtrInt);

    function CurrentActiveFileName: string;
    function PlaylistContains(const AFileName: string): Boolean;
    function PickRandomUnplayed: string;
    procedure ResetShuffle;
    procedure AppendShuffleHistory(const AFileName: string);
    procedure PruneShuffleMissing;
    procedure AddPlaylist(const AFileName: string);
    function FindNodeByName(const AFileName: string): PVirtualNode;
    function ExpandFolder(const AFileName: string): TStringArray;
    procedure SkipMissing(const AFileName: string);
  private
    procedure EndPlayback;
    procedure PlayFirst;
  public
    // 트리는 코드로 만든다 (LFM 에 두면 IDE 디자이너가 laz.virtualtreeview 등록에 매인다 — OpenSide 선례)
    ListData: TLazVirtualStringTree;

    procedure StartVerify(AMissingOnly: Boolean = False);   // 외부 사건(드라이브 재연결·목록 창 표시) 뒤 재검사
    procedure UpdateModeIcons;
    procedure SavePlaylist;
    procedure LoadPlaylist;
    procedure AddFile(AFileName: string; ACheckDisk: Boolean = True);
    // AExpand = '열기' 경로(탐색기 인자·본체 드롭·열기 대화상자) — 파일 하나면 같은 폴더 파일 자동 추가 (ExpandFolder)
    procedure AddFiles(const AFiles: TStringArray; APlay: Boolean; AExpand: Boolean = False);
    procedure OpenFiles;   // 파일 열기 대화상자 → AddFiles+재생 ([추가] 버튼, Ctrl+O, 본체 우클릭)
    procedure OpenFolder;  // 폴더 선택 → AddFiles+재생 ([추가]▸폴더, 본체 우클릭)
    procedure ReplaceFiles(const AFiles: TStringArray);
    procedure DelFile(AMode: TDeleteMode);
    procedure SetRepeat;
    procedure SetRandom;
    procedure Play(AFileName: string);
    procedure Prev;
    procedure Next;
    procedure Rand;
    procedure TrackFinished;
    procedure ApplyMissing(const AChecked, AMissing: TStringArray);
  end;

const
  COLOR_BG_MAIN          = $00202020;
  COLOR_TEXT_NORMAL      = $00E0E0E0;
  COLOR_TEXT_ACTIVE      = $0000FFFF;
  COLOR_TEXT_SELECTED    = $00FFFFFF;
  COLOR_SELECT_FOCUSED   = $004D361A;
  COLOR_SELECT_UNFOCUSED = $00382818;
  COLOR_ICON_NORMAL      = $007A848A;
  COLOR_ICON_HOVER       = $0040A6FA;
  COLOR_ICON_PRESSED     = $002C6FA6;
  COLOR_ICON_ACTIVE      = $0040A6FA;

  ListRowHeight = 24;   // 96dpi 기준 (Scale96ToForm)

var
  FrmList: TFrmList;

implementation

{$R *.lfm}

uses Main, Config, OSUtil;

{$I Const.inc}

// 목록 파일 존재 확인 = 배경 스레드. UI 스레드에서 하면 대량 드롭·네트워크 경로에서 멈춘다.
// 세대(GVerifyGen)로 취소한다 — 새 검사 시작·폼 파괴 때 증가하고, 지난 스레드는 결과를 버린다.
type
  TFileCheckThread = class(TThread)
  private
    FFiles: TStringArray;
    FGen: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFiles: TStringArray; AGen: Integer);
  end;

  // 검사 결과 운반체. TThread.Queue(nil, ...) 로 넘긴다 — 스레드 자신(Self)으로 Queue 하면
  // FreeOnTerminate 해제 때 TThread.Destroy 가 큐 항목을 지워 결과가 사라진다. 적용 후 스스로 해제.
  TVerifyResult = class
    Files, Missing: TStringArray;
    Gen: Integer;
    procedure Apply;
  end;

var
  GVerifyGen: Integer = 0;

procedure TVerifyResult.Apply;
begin
  try
    if (GVerifyGen = Gen) and (FrmList <> nil) then
      FrmList.ApplyMissing(Files, Missing);
  finally
    Free;
  end;
end;

constructor TFileCheckThread.Create(const AFiles: TStringArray; AGen: Integer);
begin
  FFiles := AFiles;
  FGen := AGen;
  FreeOnTerminate := True;
  inherited Create(False);
end;

// 경로의 루트 = 드라이브(D:\) 또는 UNC 공유(\\서버\공유\). ExtractFileDrive 가 둘 다 준다.
function PathRoot(const APath: string): string;
begin
  Result := ExtractFileDrive(APath);
  if Result <> '' then
    Result := IncludeTrailingPathDelimiter(Result);
end;

procedure TFileCheckThread.Execute;
var
  LFiles, LMissing: TStringArray;
  LRoots: TDictionary<string, Boolean>;
  LRoot: string;
  LCount, I, LGen: Integer;
  LRootUp: Boolean;
  LResult: TVerifyResult;
begin
  LGen := FGen;
  LFiles := FFiles;
  SetLength(LMissing, Length(LFiles));
  LCount := 0;

  // 루트 단위 선판정 — 끊긴 공유는 FileExists 하나가 수 초 막힌다. 루트가 죽었으면
  // 그 아래는 파일별로 묻지 않고 전부 없음 처리 (호출 N회 → 루트 수 회).
  LRoots := TDictionary<string, Boolean>.Create;
  try
    for I := 0 to High(LFiles) do
    begin
      if Terminated or (GVerifyGen <> LGen) then
        Exit;

      LRoot := LowerCase(PathRoot(LFiles[I]));
      if not LRoots.TryGetValue(LRoot, LRootUp) then
      begin
        LRootUp := (LRoot = '') or DirectoryExists(LRoot);
        LRoots.Add(LRoot, LRootUp);
      end;

      if (not LRootUp) or (not FileExists(LFiles[I])) then
      begin
        LMissing[LCount] := LFiles[I];
        Inc(LCount);
      end;
    end;
  finally
    LRoots.Free;
  end;
  SetLength(LMissing, LCount);

  LResult := TVerifyResult.Create;
  LResult.Files := LFiles;
  LResult.Missing := LMissing;
  LResult.Gen := LGen;
  TThread.Queue(nil, LResult.Apply);
end;

function TFrmList.MakeButton(ATag, AImage, ALeft: Integer): TIconButton;
begin
  Result := TIconButton.Create(Self);
  Result.Parent := Panel1;
  Result.Tag := ATag;
  Result.ImageIndex := AImage;
  Result.SetBounds(Scale96ToForm(ALeft), Scale96ToForm(12), Scale96ToForm(16), Scale96ToForm(16));
  Result.OnMouseDown := BtnMouseDown;
  Result.OnMouseUp := BtnMouseUp;
  Result.OnMouseEnter := BtnMouseEnter;
  Result.OnMouseLeave := BtnMouseLeave;
end;

procedure TFrmList.FormCreate(Sender: TObject);
begin
  Randomize;

  FCyclePlayed := TStringList.Create;
  FCyclePlayed.Sorted := True;
  FCyclePlayed.Duplicates := dupIgnore;
  FCyclePlayed.CaseSensitive := False;
  FShufflePos := -1;

  // BorderIcons 는 LFM 에서 (OnCreate 에서 바꾸면 핸들 재생성 — GUI.md 0장 #2)
  SetDarkTitleBar(Handle);

  Color := COLOR_BG_MAIN;
  Panel1.Color := COLOR_BG_MAIN;

  BtnRepeat := MakeButton(1, 0, 10);
  BtnRandom := MakeButton(2, 2, 32);
  BtnAdd := MakeButton(3, 3, 148);
  BtnDel := MakeButton(4, 4, 170);

  UpdateButtonColor(BtnRepeat, False);
  UpdateButtonColor(BtnRandom, False);
  UpdateButtonColor(BtnAdd, False);
  UpdateButtonColor(BtnDel, False);

  ListData := TLazVirtualStringTree.Create(Self);
  ListData.Parent := Self;
  ListData.Align := alClient;
  ListData.PopupMenu := PopMenu;
  ListData.ScrollBarOptions.ScrollBars := ssNone;
  ListData.OnFreeNode := ListDataFreeNode;
  ListData.OnGetText := ListDataGetText;
  ListData.OnPaintText := ListDataPaintText;
  ListData.OnKeyDown := ListDataKeyDown;
  ListData.OnMouseDown := ListDataMouseDown;
  ListData.OnMouseMove := ListDataMouseMove;
  ListData.OnMouseUp := ListDataMouseUp;
  ListData.OnNodeDblClick := ListDataNodeDblClick;
  ListData.NodeDataSize := SizeOf(TItemData);

  ListData.BorderStyle := bsNone;

  ListData.Header.Columns.Add.Text := '';
  ListData.Header.Options := ListData.Header.Options + [hoAutoResize];
  ListData.TreeOptions.AutoOptions := ListData.TreeOptions.AutoOptions + [toAutoScroll];
  ListData.TreeOptions.PaintOptions := ListData.TreeOptions.PaintOptions + [toHideFocusRect] - [toShowRoot, toShowTreeLines];
  ListData.TreeOptions.SelectionOptions := ListData.TreeOptions.SelectionOptions + [toFullRowSelect, toMultiSelect, toExtendedFocus];
  ListData.TreeOptions.MiscOptions := ListData.TreeOptions.MiscOptions + [toReportMode, toWheelPanning] - [toAcceptOLEDrop, toVariableNodeHeight];
  ListData.DefaultNodeHeight := Scale96ToForm(ListRowHeight);

  ListData.Color := COLOR_BG_MAIN;
  ListData.Font.Color := COLOR_TEXT_NORMAL;
  ListData.Colors.SelectionTextColor := COLOR_TEXT_SELECTED;
  ListData.Colors.FocusedSelectionColor := COLOR_SELECT_FOCUSED;
  ListData.Colors.FocusedSelectionBorderColor := COLOR_SELECT_FOCUSED;
  ListData.Colors.UnfocusedSelectionColor := COLOR_SELECT_UNFOCUSED;
  ListData.Colors.UnfocusedSelectionBorderColor := COLOR_SELECT_UNFOCUSED;

  Translate(Self);

  // Translate 는 Caption 계열만 훑는다 — Hint 는 직접 (반복/랜덤 힌트는 UpdateButtonColor 가 만듦).
  BtnAdd.Hint := _('추가 — 파일 / 폴더');
  BtnDel.Hint := _('삭제 — 선택 / 선택 외 / 전체 / 없는 파일 (Del 키: 선택 항목)');

  // 오버레이 스크롤바 (Windows). 그 밖의 OS 는 기본 스크롤바.
  if DarkScrollbarSupported then
    FDarkSB := TVTDarkScrollbar.Create(ListData)
  else
    ListData.ScrollBarOptions.ScrollBars := ssVertical;

  // 파일 드롭 = LFM 의 AllowDropFiles + OnDropFiles (FormDropFiles). 관리자 실행이어도 탐색기 드롭 허용.
  AllowDropFromLowerIntegrity(Handle);

  // 저장 목록 먼저, 명령줄 파일 뒤에. 재생은 명령줄 파일이 가져감
  // (HandleStartupParams 가 그것만 Play) — 연결 파일 더블클릭 시 지난 목록 첫 곡 시작 방지.
  LoadPlaylist;

  FrmKPlayer.HandleStartupParams;
end;

procedure TFrmList.FormDestroy(Sender: TObject);
begin
  Inc(GVerifyGen);   // 돌고 있는 검사 스레드 결과 폐기 (폼이 사라진다)

  // 이 폼이 FrmKPlayer 보다 먼저 파괴(lpr 생성 역순) — 여기서 저장해야 Config 생존.
  SavePlaylist;

  FDarkSB.Free;
  FCyclePlayed.Free;
end;

// 목록 창 드롭도 추가한 첫 항목부터 재생 (본체 창 드롭과 달리 기존 목록은 유지).
// 불러왔는데 재생이 안 걸려 더블클릭해야 했다는 문의 (2026-08-29) → 자동 재생으로 통일.
// 자막 파일은 목록 대신 재생 중 영상에 (FrmKPlayer.AddSubtitles).
procedure TFrmList.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
  LFiles, LSubs: TStringArray;
  I, N, NS: Integer;
begin
  SetLength(LFiles, Length(FileNames));
  SetLength(LSubs, Length(FileNames));
  N := 0;
  NS := 0;
  for I := 0 to High(FileNames) do
    if IsSubtitleFile(FileNames[I]) then
    begin
      LSubs[NS] := FileNames[I];
      Inc(NS);
    end
    else
    begin
      LFiles[N] := FileNames[I];
      Inc(N);
    end;
  SetLength(LFiles, N);
  SetLength(LSubs, NS);

  if N > 0 then
    AddFiles(LFiles, True);
  FrmKPlayer.AddSubtitles(LSubs);
end;

procedure TFrmList.FormResize(Sender: TObject);
begin
  if (BtnAdd = nil) or (BtnDel = nil) then Exit;   // FormCreate 전 Resize
  BtnAdd.Left := ClientWidth - Scale96ToForm(46);
  BtnDel.Left := ClientWidth - Scale96ToForm(26);
end;

procedure TFrmList.BtnMouseEnter(Sender: TObject);
begin
  UpdateButtonColor(TIconButton(Sender), True);
end;

procedure TFrmList.BtnMouseLeave(Sender: TObject);
begin
  UpdateButtonColor(TIconButton(Sender), False);
end;

procedure TFrmList.BtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    TIconButton(Sender).FixedColor := COLOR_ICON_PRESSED;
end;

procedure TFrmList.BtnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if Button = mbLeft then
  begin
    UpdateButtonColor(TIconButton(Sender), False);

    P := Mouse.CursorPos;
    case TIconButton(Sender).Tag of
      1: SetRepeat;
      2: SetRandom;
      3: PopAdd.PopUp(P.X, P.Y);
      4: PopDel.PopUp(P.X, P.Y);
    end;
  end;
end;

procedure TFrmList.BtnDelPopupClick(Sender: TObject);
begin
  DelFile(dmSelected);
end;

procedure TFrmList.BtnDelPopupUnselectedClick(Sender: TObject);
begin
  DelFile(dmUnselected);
end;

procedure TFrmList.BtnDelPopupAllClick(Sender: TObject);
begin
  DelFile(dmAll);
end;

procedure TFrmList.BtnDelPopupMissingClick(Sender: TObject);
begin
  DelFile(dmMissing);
end;

procedure TFrmList.BtnDelContextClick(Sender: TObject);
begin
  DelFile(dmSelected);
end;

procedure TFrmList.BtnAddPopupClick(Sender: TObject);
begin
  OpenFiles;
end;

// 필터는 AssocExts 전체 (단일 출처) — 하드코딩 7종이라 .ts/.flac 등이 대화상자에서 안 보이던 것 (2026-09-13).
procedure TFrmList.OpenFiles;
var
  Dialog: TOpenDialog;
  I: Integer;
  Video, Audio, All: string;
  LFiles: TStringArray;
begin
  Video := '';
  Audio := '';
  All := '';
  for I := Low(AssocExts) to High(AssocExts) do
  begin
    All := All + ';*' + AssocExts[I].Ext;
    case AssocExts[I].Group of
      agVideo: Video := Video + ';*' + AssocExts[I].Ext;
      agAudio: Audio := Audio + ';*' + AssocExts[I].Ext;
    end;
  end;
  Delete(All, 1, 1);   // 선행 ';'
  Delete(Video, 1, 1);
  Delete(Audio, 1, 1);

  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Options := Dialog.Options + [ofAllowMultiSelect, ofFileMustExist, ofEnableSizing];
    // '비디오'/'오디오' 그룹은 연결 카드와 공유 (영문 'Video files'/'Audio files')
    Dialog.Filter := _('미디어 파일') + '|' + All + '|' + _('비디오') + '|' + Video + '|'
      + _('오디오') + '|' + Audio + '|' + _('모든 파일') + '|*.*';

    if Dialog.Execute then
    begin
      SetLength(LFiles, Dialog.Files.Count);
      for I := 0 to Dialog.Files.Count - 1 do
        LFiles[I] := Dialog.Files[I];
      AddFiles(LFiles, True, True);   // 중복 해시표·배경 존재 확인 공용, 추가 후 재생
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TFrmList.BtnAddPopupFolderClick(Sender: TObject);
begin
  OpenFolder;
end;

procedure TFrmList.OpenFolder;
var
  FolderPath: string;
  LFiles: TStringArray;
begin
  FolderPath := '';
  if SelectDirectory(_('폴더 선택'), '', FolderPath) then
  begin
    SetLength(LFiles, 1);
    LFiles[0] := FolderPath;
    AddFiles(LFiles, True);   // 폴더 추가도 첫 항목부터 재생
  end;
end;

procedure TFrmList.ListDataFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  Item: PItemData;
begin
  Item := Sender.GetNodeData(Node);
  Finalize(Item^);
end;

procedure TFrmList.ListDataGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  Item: PItemData;
  Text: string;
begin
  Item := Sender.GetNodeData(Node);
  if not Assigned(Item) then Exit;

  // 그리기마다 호출 — 디스크 확인 금지. TFileCheckThread 가 채운 Missing 만 본다.
  if Item^.Missing then
    Text := Item^.FileName
  else
    Text := ChangeFileExt(ExtractFileName(Item^.FileName), '');

  case Column of
    0: CellText := Text;
  end;
end;

procedure TFrmList.ListDataPaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var
  Item: PItemData;
begin
  Item := Sender.GetNodeData(Node);
  if Assigned(Item) and Item^.IsActive then
    TargetCanvas.Font.Color := COLOR_TEXT_ACTIVE
  else
    TargetCanvas.Font.Color := COLOR_TEXT_NORMAL;
end;

procedure TFrmList.ListDataNodeDblClick(Sender: TBaseVirtualTree;
  const HitInfo: THitInfo);
var
  Item: PItemData;
begin
  if Assigned(HitInfo.HitNode) then
  begin
    Item := Sender.GetNodeData(HitInfo.HitNode);
    if Assigned(Item) then
      Play(Item^.FileName);
  end;
end;

// Del = 목록에서 제거 (파일 삭제 아님). KeyPreview 아닌 트리 이벤트 — 타 컨트롤 입력 가로채기 방지.
procedure TFrmList.ListDataKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_DELETE) and (Shift = []) and (ListData.SelectedCount > 0) then
  begin
    DelFile(dmSelected);
    Key := 0;
  end;
end;

procedure TFrmList.ListDataMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  HitNode, Node: PVirtualNode;
  Idx: Integer;
begin
  SetLength(FSavedSelection, 0);
  if Button <> mbLeft then Exit;

  FDragStart := Types.Point(X, Y);
  FDragNode := nil;

  HitNode := ListData.GetNodeAt(X, Y);
  if Assigned(HitNode) and ListData.Selected[HitNode] and (ListData.SelectedCount > 1) then
  begin
    SetLength(FSavedSelection, ListData.SelectedCount);
    Idx := 0;
    Node := ListData.GetFirstSelected;
    while Assigned(Node) do
    begin
      FSavedSelection[Idx] := Node;
      Inc(Idx);
      Node := ListData.GetNextSelected(Node);
    end;
  end;
end;

procedure TFrmList.ListDataMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  TargetNode, Node, Neighbor: PVirtualNode;
  M, I: Integer;
  SelData, NewData: PItemData;
  TempData: TItemData;
begin
  if not (ssLeft in Shift) then
    Exit;

  if not Assigned(FDragNode) then
  begin
    if (Abs(X - FDragStart.X) < 4) and (Abs(Y - FDragStart.Y) < 4) then
      Exit;

    if Length(FSavedSelection) > 0 then
    begin
      for I := 0 to High(FSavedSelection) do
        ListData.Selected[FSavedSelection[I]] := True;
      SetLength(FSavedSelection, 0);
    end;

    FDragNode := ListData.GetNodeAt(FDragStart.X, FDragStart.Y);
    Exit;
  end;

  TargetNode := ListData.GetNodeAt(X, Y);
  if not Assigned(TargetNode) then Exit;

  M := Integer(TargetNode^.Index) - Integer(FDragNode^.Index);
  if M = 0 then Exit;
  if M > 0 then M := 1 else M := -1;

  if M < 0 then
  begin
    Node := ListData.GetFirst;
    while Assigned(Node) and not ListData.Selected[Node] do
      Node := ListData.GetNext(Node);
    if not Assigned(Node) or not Assigned(ListData.GetPrevious(Node)) then Exit;
  end
  else
  begin
    Node := ListData.GetLast;
    while Assigned(Node) and not ListData.Selected[Node] do
      Node := ListData.GetPrevious(Node);
    if not Assigned(Node) or not Assigned(ListData.GetNext(Node)) then Exit;
  end;

  ListData.BeginUpdate;
  try
    if M > 0 then
      Node := ListData.GetLast
    else
      Node := ListData.GetFirst;

    while Assigned(Node) do
    begin
      if ListData.Selected[Node] then
      begin
        if M > 0 then Neighbor := ListData.GetNext(Node)
                 else Neighbor := ListData.GetPrevious(Node);

        if Assigned(Neighbor) then
        begin
          SelData := ListData.GetNodeData(Node);
          NewData := ListData.GetNodeData(Neighbor);
          TempData := SelData^;
          SelData^ := NewData^;
          NewData^ := TempData;

          ListData.Selected[Neighbor] := True;
          ListData.Selected[Node] := False;
        end;
      end;

      if M > 0 then Node := ListData.GetPrevious(Node)
               else Node := ListData.GetNext(Node);
    end;
  finally
    ListData.EndUpdate;
  end;

  FDragNode := TargetNode;

  if Y < 20 then
    ListData.OffsetY := ListData.OffsetY - 10
  else if Y > ListData.ClientHeight - 20 then
    ListData.OffsetY := ListData.OffsetY + 10;

  ListData.Invalidate;
end;

procedure TFrmList.ListDataMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  SetLength(FSavedSelection, 0);
  FDragNode := nil;
end;

function TFrmList.FindActiveNode: PVirtualNode;
var
  Node: PVirtualNode;
  Item: PItemData;
begin
  Result := nil;
  Node := ListData.GetFirst;
  while Assigned(Node) do
  begin
    Item := ListData.GetNodeData(Node);
    if Assigned(Item) and Item^.IsActive then
      Exit(Node);
    Node := ListData.GetNext(Node);
  end;
end;

// 아이콘 툴팁 — 아이콘만으론 모드 불명. 상태 변경 시(UpdateButtonColor) 재생성.
function RepeatHint: string;
begin
  case FrmKPlayer.RepeatMode of
    1: Result := _('전체 반복');
    2: Result := _('한 곡 반복');
  else
    Result := _('반복 없음');
  end;

  // 랜덤 = 한 바퀴 후 재섞어 계속 재생 → '반복 없음' 무의미.
  if (FrmKPlayer.RepeatMode = 0) and (FrmKPlayer.RandomMode = 1) then
    Result := Result + ' ' + _('(랜덤이 켜져 있어 계속 재생됩니다)');
end;

function RandomHint: string;
begin
  if FrmKPlayer.RandomMode = 1 then
    Result := _('랜덤 켜짐 — 목록을 섞어 재생하고, 한 바퀴 돌면 다시 섞습니다')
  else
    Result := _('랜덤 꺼짐 — 목록 순서대로 재생합니다');
end;

procedure TFrmList.UpdateButtonColor(Btn: TIconButton; Hover: Boolean);
begin
  case Btn.Tag of
    1: // 반복
    begin
      Btn.Hint := RepeatHint;

      case FrmKPlayer.RepeatMode of
        0:
        begin
          Btn.ImageIndex := 0;

          if Hover then
            Btn.FixedColor := COLOR_ICON_HOVER
          else
            Btn.FixedColor := COLOR_ICON_NORMAL;
        end;

        1:
        begin
          Btn.ImageIndex := 0;
          Btn.FixedColor := COLOR_ICON_ACTIVE;
        end;

        2:
        begin
          Btn.ImageIndex := 1;
          Btn.FixedColor := COLOR_ICON_ACTIVE;
        end;
      end;
    end;

    2: // 랜덤
    begin
      Btn.Hint := RandomHint;

      if FrmKPlayer.RandomMode = 0 then
      begin
        if Hover then
          Btn.FixedColor := COLOR_ICON_HOVER
        else
          Btn.FixedColor := COLOR_ICON_NORMAL;
      end
      else
        Btn.FixedColor := COLOR_ICON_ACTIVE;
    end;

  else
    begin
      if Hover then
        Btn.FixedColor := COLOR_ICON_HOVER
      else
        Btn.FixedColor := COLOR_ICON_NORMAL;
    end;
  end;
end;

// 재생 항목으로 스크롤 — Play 의 BeginUpdate/EndUpdate 뒤에 (Delphi 판 PostMessage WM_APP+1 대신)
procedure TFrmList.ScrollFocusedAsync(Data: PtrInt);
begin
  if Assigned(ListData.FocusedNode) then
    ListData.ScrollIntoView(ListData.FocusedNode, False);
end;

// TPath.Combine 은 잘못된 문자에 예외 — 재생목록엔 URL/이상한 줄 섞임 → 미사용.
function IsAbsolutePath(const APath: string): Boolean;
begin
  Result := ((Length(APath) >= 3) and (APath[2] = ':') and
             (APath[3] in ['\', '/'])) or
            ((Length(APath) >= 2) and (APath[1] = '\') and (APath[2] = '\')) or
            ((Length(APath) >= 1) and (APath[1] = '/'));   // 유닉스 절대경로 (macOS 대비)
end;

procedure TFrmList.AddPlaylist(const AFileName: string);
const
  MaxDepth = 3;   // 재생목록 중첩 한도
var
  Lines: TStringList;
  Dir, Line, Path: string;
  IsPls: Boolean;
  Eq, I: Integer;
begin
  if FPlaylistDepth >= MaxDepth then
    Exit;

  Inc(FPlaylistDepth);
  try
    Dir := ExtractFilePath(AFileName);
    IsPls := SameText(ExtractFileExt(AFileName), '.pls');

    Lines := TStringList.Create;
    try
      try
        // .m3u8=UTF-8 규격, .m3u 는 ANSI(CP949) 흔함 — BOM/UTF-8 유효성으로 판별 (Config.DecodeText)
        Lines.Text := ReadTextFile(AFileName);
      except
        Exit;
      end;

      for I := 0 to Lines.Count - 1 do
      begin
        Line := Trim(Lines[I]);
        if Line = '' then
          Continue;

        if IsPls then
        begin
          // [playlist] 의 File1=... 만 경로 (Title1=/Length1= 등 스킵)
          if not StartsText('File', Line) then
            Continue;

          Eq := Pos('=', Line);
          if Eq = 0 then
            Continue;

          Line := Trim(Copy(Line, Eq + 1, MaxInt));
        end
        else if Line[1] = '#' then
          Continue;   // #EXTM3U/#EXTINF 등 주석/지시자

        if Line = '' then
          Continue;

        // 스트리밍 URL 스킵 — 목록 창은 파일 경로 기준 (없는 파일 취급, 어차피 진입 불가).
        if Pos('://', Line) > 0 then
          Continue;

        if IsAbsolutePath(Line) then
          Path := Line
        else
          Path := ExpandFileName(Dir + Line);   // 상대경로는 재생목록 위치 기준

        AddFile(Path);   // 확장자 필터/중복 검사 = AddFile 담당
      end;
    finally
      Lines.Free;
    end;
  finally
    Dec(FPlaylistDepth);
  end;
end;

// 목록 저장/복원 (환경설정 '일반 → 재생목록 저장').
// 파일 = 설정 ini 와 같은 자리(Config.AppDataDir) KPlayer.lst — Windows 는 exe 폴더, 포터블 이동 추종.
// 형식 = 경로 한 줄씩 평문(UTF-8 BOM). .lst 확장자 = 탐색기의 재생목록 오인 방지.
// 읽기는 ReadTextFile → 메모장 ANSI 저장도 읽힘.
function PlaylistFile: string;
begin
  Result := AppDataDir + AppName + '.lst';
end;

function SavePlaylistEnabled: Boolean;
begin
  Result := (FrmKPlayer <> nil) and (FrmKPlayer.Config <> nil) and
            (FrmKPlayer.Config.ReadInteger('save_playlist', 1) <> 0);
end;

procedure DeletePlaylistFile;
begin
  if FileExists(PlaylistFile) then
    DeleteFile(PlaylistFile);
end;

// 종료 시 호출(FormDestroy). 예외 나가면 종료 중 오류 창 → 통째 차단 (읽기 전용 폴더 실행 사례 있음).
procedure TFrmList.SavePlaylist;
const
  BOM: array[0..2] of Byte = ($EF, $BB, $BF);
var
  LLines: TStringList;
  LNode: PVirtualNode;
  LItem: PItemData;
  LStream: TFileStream;
  LText: string;
begin
  try
    // 방금 껐어도 옛 파일 남으면 다음 실행에서 부활. 빈 목록 상태도 보존 필요 → 둘 다 파일 삭제.
    if not SavePlaylistEnabled then
    begin
      DeletePlaylistFile;
      Exit;
    end;

    LLines := TStringList.Create;
    try
      LLines.LineBreak := #13#10;
      LNode := ListData.GetFirst;
      while Assigned(LNode) do
      begin
        LItem := ListData.GetNodeData(LNode);
        if Assigned(LItem) and (LItem^.FileName <> '') then
          LLines.Add(LItem^.FileName);
        LNode := ListData.GetNext(LNode);
      end;

      if LLines.Count = 0 then
        DeletePlaylistFile
      else
      begin
        LText := LLines.Text;
        LStream := TFileStream.Create(PlaylistFile, fmCreate);
        try
          LStream.WriteBuffer(BOM, SizeOf(BOM));
          if LText <> '' then
            LStream.WriteBuffer(LText[1], Length(LText));
        finally
          LStream.Free;
        end;
      end;
    finally
      LLines.Free;
    end;
  except
    on E: Exception do ;
  end;
end;

// 시작 시 명령줄 처리 전 호출(FormCreate). 없는 파일 안 거름 — 네트워크
// 드라이브 존재 확인 타임아웃 → 창 표시 지연. 정리는 재생 시점 SkipMissing.
procedure TFrmList.LoadPlaylist;
var
  LLines, LSeen: TStringList;
  LPath: string;
  I: Integer;
begin
  if not SavePlaylistEnabled then
    Exit;

  try
    if not FileExists(PlaylistFile) then
      Exit;

    LLines := TStringList.Create;
    LSeen := TStringList.Create;
    try
      // AddFile 노드 중복 검사 생략 대신 줄 단위 사전 필터.
      LSeen.Sorted := True;
      LSeen.CaseSensitive := False;

      LLines.Text := ReadTextFile(PlaylistFile);

      ListData.BeginUpdate;
      try
        for I := 0 to LLines.Count - 1 do
        begin
          LPath := Trim(LLines[I]);
          if (LPath = '') or (LPath[1] = '#') then
            Continue;

          if LSeen.IndexOf(LPath) >= 0 then
            Continue;
          LSeen.Add(LPath);

          AddFile(LPath, False);
        end;
      finally
        ListData.EndUpdate;
      end;
    finally
      LSeen.Free;
      LLines.Free;
    end;

    StartVerify;   // 시작 로드도 존재 확인은 배경 (네트워크 경로 타임아웃 → 창 표시 지연 방지)
  except
    on E: Exception do ;
  end;
end;

// ACheckDisk=False = 시작 로드 전용, 디스크 무접근 (이유: LoadPlaylist 주석).
//
// ACheckDisk=True 여도 파일 존재는 확인하지 않는다 — 대량 드롭에서 FileExists 가 항목 수만큼
// 디스크를 때려 UI 가 멈췄다. 없는 파일 표시는 StartVerify 스레드가 나중에 켠다.
// 디스크를 보는 경우는 둘뿐: 미디어 확장자가 아닌 경로의 폴더 여부(폴더 드롭 전개)와
// 재생목록 파일 읽기. 미디어 파일만 잔뜩 떨구면 디스크 접근 0회.
procedure TFrmList.AddFile(AFileName: string; ACheckDisk: Boolean);
var
  Node: PVirtualNode;
  Item: PItemData;
  SearchRec: TSearchRec;
  LKey, LDir: string;
begin
  // 지원 확장자 = Media.pas AssocExts 단일 출처 (파일 연결 카드 공용).
  if not IsMediaFile(AFileName) then
  begin
    if not ACheckDisk then
      Exit;

    // 확장자로 안 걸린 것만 폴더인지 물어본다.
    if not DirectoryExists(AFileName) then
      Exit;

    LDir := IncludeTrailingPathDelimiter(AFileName);
    if FindFirst(LDir + '*', faAnyFile, SearchRec) = 0 then
    try
      repeat
        if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
          Continue;
        AddFile(LDir + SearchRec.Name);
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
    Exit;
  end;

  // 재생목록 = 항목으로 안 넣고 내부 경로 전개. 넣으면 목록엔 한 줄인데
  // mpv 는 내부 재생목록 별도 진행 → 다음/이전 버튼과 실제 재생 어긋남.
  if IsPlaylistFile(AFileName) then
  begin
    // 시작 로드는 미전개 (읽기 = 디스크 접근).
    if ACheckDisk then
      AddPlaylist(AFileName);
    Exit;
  end;

  // 전부 중복이라 새 노드가 하나도 안 생겼을 때 AddFiles 가 재생할 기준.
  // 인자 경로로는 못 찾는 경우가 있다 — 재생목록/폴더는 목록에 그 경로가 없다(내용물만 들어간다).
  if Assigned(FAddSeen) and (FAddFirst = '') then
    FAddFirst := AFileName;

  // 시작 로드: 빈 목록 + 사전 중복 필터 → 노드 검사(O(n²)) 생략.
  if ACheckDisk then
  begin
    if Assigned(FAddSeen) then
    begin
      // 일괄 추가 중 — 해시표 O(1). 노드 선형 검사는 항목 수² 라 대량 드롭에선 그것만으로 멈춘다.
      LKey := LowerCase(AFileName);
      if FAddSeen.ContainsKey(LKey) then
        Exit;
      FAddSeen.Add(LKey, True);
    end
    else
    begin
      Node := ListData.GetFirst;
      while Assigned(Node) do
      begin
        Item := ListData.GetNodeData(Node);
        if Assigned(Item) and SameText(Item^.FileName, AFileName) then
          Exit;
        Node := ListData.GetNext(Node);
      end;
    end;
  end;

  Node := ListData.AddChild(nil);
  Item := ListData.GetNodeData(Node);
  ListData.NodeHeight[Node] := Scale96ToForm(ListRowHeight);
  Item^.FileName := AFileName;
  Item^.IsActive := False;
  Item^.Missing := False;   // 확인 전엔 있다고 본다 (StartVerify 가 정정)
end;

// 목록 전체를 배경 스레드로 넘겨 존재 여부를 확인시킨다. 이전 검사는 세대 증가로 취소.
// AMissingOnly=True = 이미 없음으로 표시된 항목만 다시 본다 (드라이브 재연결·목록 창 표시).
// 목록 전체를 훑는 것은 추가/로드 때뿐 — 수천 항목짜리 목록에서 창 열 때마다 전수 검사하면
// 디스크·네트워크를 그만큼 때린다. 재연결로 바뀌는 것은 '없음 → 있음' 뿐이고, 반대 방향
// (있던 파일이 사라짐) 은 재생 시점 SkipMissing 이 잡는다.
procedure TFrmList.StartVerify(AMissingOnly: Boolean);
var
  LFiles: TStringArray;
  LCount: Integer;
  Node: PVirtualNode;
  Item: PItemData;
begin
  SetLength(LFiles, ListData.RootNodeCount);
  LCount := 0;
  Node := ListData.GetFirst;
  while Assigned(Node) do
  begin
    Item := ListData.GetNodeData(Node);
    if Assigned(Item) and ((not AMissingOnly) or Item^.Missing) then
    begin
      if LCount >= Length(LFiles) then
        SetLength(LFiles, LCount + 64);
      LFiles[LCount] := Item^.FileName;
      Inc(LCount);
    end;
    Node := ListData.GetNext(Node);
  end;
  SetLength(LFiles, LCount);

  // 검사할 게 없으면 세대도 올리지 않는다 — 진행 중인 전수 검사를 헛되이 취소하지 않게.
  if LCount = 0 then
    Exit;

  Inc(GVerifyGen);
  TFileCheckThread.Create(LFiles, GVerifyGen);
end;

// 스레드 결과 반영 (메인 스레드). 그 사이 노드가 바뀔 수 있어 포인터가 아닌 경로로 대조한다.
// AChecked = 이 스레드가 실제로 확인한 범위. 그 밖의 노드는 건드리지 않는다 —
// 부분 검사(StartVerify(True)) 결과로 검사하지 않은 항목까지 '있음' 으로 되돌리면 안 된다.
procedure TFrmList.ApplyMissing(const AChecked, AMissing: TStringArray);
var
  LSet, LScope: TDictionary<string, Boolean>;
  Node: PVirtualNode;
  Item: PItemData;
  LKey: string;
  LMiss, LDirty: Boolean;
  I: Integer;
begin
  LDirty := False;
  LSet := TDictionary<string, Boolean>.Create;
  LScope := TDictionary<string, Boolean>.Create;
  try
    for I := 0 to High(AMissing) do
      LSet.AddOrSetValue(LowerCase(AMissing[I]), True);
    for I := 0 to High(AChecked) do
      LScope.AddOrSetValue(LowerCase(AChecked[I]), True);

    Node := ListData.GetFirst;
    while Assigned(Node) do
    begin
      Item := ListData.GetNodeData(Node);
      if Assigned(Item) then
      begin
        LKey := LowerCase(Item^.FileName);
        if LScope.ContainsKey(LKey) then
        begin
          LMiss := LSet.ContainsKey(LKey);
          if Item^.Missing <> LMiss then
          begin
            Item^.Missing := LMiss;
            LDirty := True;
          end;
        end;
      end;
      Node := ListData.GetNext(Node);
    end;
  finally
    LScope.Free;
    LSet.Free;
  end;

  if LDirty then
    ListData.Invalidate;
end;

// 일괄 추가 + 재생. 드롭 경로를 그대로 Play 하면 안 되는 이유 — 폴더는 내용물만 항목이
// 되고(AddFile 재귀), 비지원 확장자는 걸러지고, 재생목록은 내부 경로로 펼쳐진다.
// 셋 다 '목록에 없는 경로' 라 Play 가 SkipMissing/mpv 오류로 빠졌다 (폴더 드롭 시
// "파일을 찾을 수 없습니다 — <폴더명>" + 재생 안 됨).
// 그래서 추가 전 마지막 노드를 표시해 두고 그 다음(= 이번에 새로 들어간 첫) 노드부터 재생.
// 폴더 자동 추가로 늘어났으면 예외 — 연 파일부터 (3화를 열었는데 1화부터 재생되면 안 됨).
procedure TFrmList.AddFiles(const AFiles: TStringArray; APlay: Boolean; AExpand: Boolean);
var
  Mark, Node: PVirtualNode;
  Item: PItemData;
  I: Integer;
  LFiles: TStringArray;
  LTarget: string;
begin
  if Length(AFiles) = 0 then
    Exit;

  LFiles := AFiles;
  LTarget := '';
  if AExpand and (Length(AFiles) = 1) then
  begin
    LFiles := ExpandFolder(AFiles[0]);
    if Length(LFiles) > 1 then
      LTarget := AFiles[0];
  end;

  Mark := ListData.GetLast;

  FAddFirst := '';
  FAddSeen := TDictionary<string, Boolean>.Create;
  try
    Node := ListData.GetFirst;
    while Assigned(Node) do
    begin
      Item := ListData.GetNodeData(Node);
      if Assigned(Item) then
        FAddSeen.AddOrSetValue(LowerCase(Item^.FileName), True);
      Node := ListData.GetNext(Node);
    end;

    ListData.BeginUpdate;
    try
      for I := 0 to High(LFiles) do
        AddFile(LFiles[I]);
    finally
      ListData.EndUpdate;
    end;
  finally
    FreeAndNil(FAddSeen);
  end;

  StartVerify;   // 존재 확인은 여기서부터 배경으로

  if not APlay then
    Exit;

  if LTarget <> '' then
    Node := FindNodeByName(LTarget)
  else if Assigned(Mark) then
    Node := ListData.GetNext(Mark)
  else
    Node := ListData.GetFirst;

  // 새로 들어간 것 없음(전부 중복) → 이번에 처음 만난 미디어 경로부터 재생.
  // FAddFirst 를 먼저 보는 이유 — 재생목록/폴더 인자는 AFiles 에 그 경로가 있어도
  // 목록엔 없다(내용물만 들어간다). 남은 경우 대비로 인자 경로도 한 번 본다.
  if not Assigned(Node) and (FAddFirst <> '') then
    Node := FindNodeByName(FAddFirst);

  if not Assigned(Node) then
    Node := FindNodeByName(AFiles[0]);

  if not Assigned(Node) then
    Exit;

  Item := ListData.GetNodeData(Node);
  if Assigned(Item) then
    Play(Item^.FileName);
end;

// 본체 창 드롭 전용 — 기존 목록을 버리고 떨군 것만 남긴다 (목록 창 드롭은 AddFiles = 덧붙임).
// 재생 시작은 양쪽 같다.
// 넣을 게 하나도 없으면(미지원 확장자만) 목록을 지우지 않는다 — 전엔 비우고 재생이 멈췄다 (1.1.1.0).
procedure TFrmList.ReplaceFiles(const AFiles: TStringArray);
var
  I: Integer;
  LAny: Boolean;
begin
  LAny := False;
  for I := 0 to High(AFiles) do
    if DirectoryExists(AFiles[I]) or IsMediaFile(AFiles[I]) then
    begin
      LAny := True;
      Break;
    end;
  if not LAny then
    Exit;

  DelFile(dmAll);              // 재생 중이던 항목도 사라짐 → 아래 AddFiles 가 새 첫 곡을 건다
  AddFiles(AFiles, True, True);
end;

procedure TFrmList.DelFile(AMode: TDeleteMode);
var
  Node: PVirtualNode;
  NextNode: PVirtualNode;
  Item: PItemData;
  ToDelete: array of PVirtualNode;
  DeleteCount, I: Integer;
  ActiveNode: PVirtualNode;
  ActiveDeleted: Boolean;
  FirstNode: PVirtualNode;
  FirstItem: PItemData;
  ShouldDelete: Boolean;
begin
  ActiveNode := FindActiveNode;
  ActiveDeleted := False;
  DeleteCount := 0;
  SetLength(ToDelete, 0);

  Node := ListData.GetFirst;
  while Assigned(Node) do
  begin
    NextNode := ListData.GetNext(Node);
    Item := ListData.GetNodeData(Node);
    ShouldDelete := False;

    if Assigned(Item) then
    begin
      case AMode of
        dmSelected:
          ShouldDelete := ListData.Selected[Node];
        dmUnselected:
          ShouldDelete := not ListData.Selected[Node];
        dmAll:
          ShouldDelete := True;
        dmMissing:
          ShouldDelete := not FileExists(Item^.FileName);
      end;
    end;

    if ShouldDelete then
    begin
      SetLength(ToDelete, DeleteCount + 1);
      ToDelete[DeleteCount] := Node;
      Inc(DeleteCount);

      if Node = ActiveNode then
        ActiveDeleted := True;
    end;

    Node := NextNode;
  end;

  if DeleteCount = 0 then
    Exit;

  ListData.BeginUpdate;
  try
    for I := 0 to High(ToDelete) do
      ListData.DeleteNode(ToDelete[I]);
  finally
    ListData.EndUpdate;
  end;

  PruneShuffleMissing;   // 사라진 파일 → 이력·사이클에서 제거

  if not ActiveDeleted then
    Exit;

  FirstNode := ListData.GetFirst;

  if not Assigned(FirstNode) then
  begin
    EndPlayback;   // 목록 전부 삭제됨
    Exit;
  end;

  FirstItem := ListData.GetNodeData(FirstNode);
  Play(FirstItem^.FileName);
end;

procedure TFrmList.PlayFirst;
var
  Node: PVirtualNode;
  Item: PItemData;
begin
  Node := ListData.GetFirst;
  if not Assigned(Node) then
  begin
    EndPlayback;
    Exit;
  end;

  Item := ListData.GetNodeData(Node);
  if Assigned(Item) then
    Play(Item^.FileName)
  else
    EndPlayback;
end;

// 더 재생할 것 없을 때. 정지 아닌 '마지막 프레임 멈춤' — mpv stop 은 파일
// 언로드 → 화면 검정, 첫 실행 상태. '재생 중' 표시도 유지 (화면에 영상 잔존).
procedure TFrmList.EndPlayback;
begin
  ResetShuffle;              // 다음 랜덤 = 새 사이클
  FrmKPlayer.SetPause(True);
end;

procedure TFrmList.UpdateModeIcons;
begin
  // 폼 생성 중(버튼 생성 전) 호출 가능
  if (BtnRepeat = nil) or (BtnRandom = nil) then
    Exit;

  UpdateButtonColor(BtnRepeat, False);
  UpdateButtonColor(BtnRandom, False);
end;

procedure TFrmList.SetRepeat;
begin
  FrmKPlayer.RepeatMode := (FrmKPlayer.RepeatMode + 1) mod 3;
  UpdateButtonColor(BtnRepeat, True);
end;

procedure TFrmList.SetRandom;
begin
  FrmKPlayer.RandomMode := 1 - FrmKPlayer.RandomMode;
  ResetShuffle;   // 새 사이클 시작
  UpdateButtonColor(BtnRandom, True);
end;

function TFrmList.FindNodeByName(const AFileName: string): PVirtualNode;
var
  Item: PItemData;
begin
  Result := ListData.GetFirst;
  while Assigned(Result) do
  begin
    Item := ListData.GetNodeData(Result);
    if Assigned(Item) and SameText(Item^.FileName, AFileName) then
      Exit;
    Result := ListData.GetNext(Result);
  end;
end;

function CompareFileNames(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := NaturalCompare(ExtractFileName(List[Index1]), ExtractFileName(List[Index2]));
end;

// 같은 폴더 파일 자동 추가 (INI folder_add: 0=끔 1=관련 파일만 2=모든 파일, 기본 1 — 팟플레이어·곰 관례).
// 대상 = 연 파일과 같은 종류(비디오/오디오) — 영상 열었는데 폴더의 mp3 가 끼지 않게. 재생목록 파일은 제외.
// 결과는 자연 정렬(2화 < 10화), 연 파일 포함. 확장 안 하면 [AFileName] 그대로.
// 연 파일은 인자 문자열 그대로 넣는다 — AddFiles 가 FindNodeByName(인자) 로 재생 시작점을 찾는다.
// '.' 으로 시작하는 이름 제외 — macOS 가 USB 에 남기는 '._영상.mp4' (AppleDouble) 가 재생 실패 항목으로 끼는 것.
function TFrmList.ExpandFolder(const AFileName: string): TStringArray;
var
  LMode, LIndex: Integer;
  LGroup: TAssocGroup;
  LDir, LName: string;
  LList: TStringList;
  SearchRec: TSearchRec;
  I: Integer;
begin
  SetLength(Result, 1);
  Result[0] := AFileName;

  LMode := FrmKPlayer.Config.ReadInteger('folder_add', 1);
  if LMode = 0 then
    Exit;

  LIndex := AssocIndexOf(ExtractFileExt(AFileName));
  if LIndex < 0 then
    Exit;
  LGroup := AssocExts[LIndex].Group;
  if LGroup = agList then
    Exit;

  LDir := ExtractFilePath(ExpandFileName(AFileName));
  LName := ExtractFileName(AFileName);

  LList := TStringList.Create;
  try
    LList.Add(AFileName);

    if FindFirst(LDir + '*', faAnyFile, SearchRec) = 0 then
    try
      repeat
        if (SearchRec.Attr and faDirectory) <> 0 then
          Continue;
        if (SearchRec.Name = '') or (SearchRec.Name[1] = '.') then
          Continue;
        if SameText(SearchRec.Name, LName) then
          Continue;

        LIndex := AssocIndexOf(ExtractFileExt(SearchRec.Name));
        if (LIndex < 0) or (AssocExts[LIndex].Group <> LGroup) then
          Continue;
        if (LMode = 1) and not IsRelatedName(LName, SearchRec.Name) then
          Continue;

        LList.Add(LDir + SearchRec.Name);
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;

    LList.CustomSort(CompareFileNames);

    SetLength(Result, LList.Count);
    for I := 0 to LList.Count - 1 do
      Result[I] := LList[I];
  finally
    LList.Free;
  end;
end;

// 없는 파일 = 목록에서 지우지 않고 '없음' 표시만 + 다음 곡 (표시는 전체 경로 — ListDataGetText).
// 자동 삭제 금지 (2026-09-05 결정) — 네트워크/USB 일시 분리면 목록이 조용히 비워지고,
// 지우는 시점은 사용자가 정한다 ([삭제] → 없는 파일).
procedure TFrmList.SkipMissing(const AFileName: string);
const
  MaxSkip = 64;   // 목록 전체가 없는 파일일 때 안전장치 (항목이 남으니 목록이 비어 끝나지 않는다)
var
  Node, NextNode: PVirtualNode;
  Item: PItemData;
  NextName: string;
  IsRandom: Boolean;
begin
  IsRandom := FrmKPlayer.RandomMode = 1;
  NextName := '';

  // 건너뛴 이유 화면 알림 (목록 창 닫혀 있으면 표시 변화 인지 불가)
  FrmKPlayer.Alert(_('파일을 찾을 수 없습니다') + ' — ' + ExtractFileName(AFileName),
    ALERT_ERROR);

  Node := FindNodeByName(AFileName);
  if Assigned(Node) then
  begin
    Item := ListData.GetNodeData(Node);
    if Assigned(Item) then
      Item^.Missing := True;
    ListData.InvalidateNode(Node);

    if IsRandom then
      // 항목이 남으므로 이번 사이클에 다시 뽑힐 수 있다 → 재생한 것으로 쳐서 제외.
      FCyclePlayed.Add(AFileName)
    else
    begin
      NextNode := ListData.GetNext(Node);
      if Assigned(NextNode) then
      begin
        Item := ListData.GetNodeData(NextNode);
        if Assigned(Item) then
          NextName := Item^.FileName;
      end;
    end;
  end;

  if ListData.RootNodeCount = 0 then
  begin
    EndPlayback;
    Exit;
  end;

  if FSkipDepth >= MaxSkip then
  begin
    EndPlayback;   // 전부 없는 파일 — 삭제를 안 하니 목록이 비어 멈추는 경로가 없다.
    Exit;
  end;

  Inc(FSkipDepth);
  try
    if IsRandom then
      Rand
    else if NextName <> '' then
      Play(NextName)
    else if FrmKPlayer.RepeatMode = 1 then
      // 마지막 항목이 없는 파일 → Next 가 갈 곳 없음 → 처음 곡 직접 재생.
      PlayFirst
    else if not FrmKPlayer.IsPlay then
      // 뒤에 재생할 것 없음 → 정지. 다른 곡 재생 중이면 불간섭
      // (없는 파일 클릭이 보던 영상을 멈추면 안 됨).
      EndPlayback;
  finally
    Dec(FSkipDepth);
  end;
end;

procedure TFrmList.Play(AFileName: string);
var
  ActiveNode: PVirtualNode;
  Node: PVirtualNode;
  Item: PItemData;
begin
  if (AFileName = '') then
  begin
    // 재생/일시정지 토글. mpv 에 열린 파일 없으면(정지) pause 토글 무효 → 재오픈.
    ActiveNode := FindActiveNode;

    if Assigned(ActiveNode) and FrmKPlayer.IsLoaded and
       not FrmKPlayer.IsEOF then
      FrmKPlayer.HandlePause
    else if Assigned(ActiveNode) then
    begin
      // 파일 언로드 또는 끝 정지 → 처음부터 재오픈
      // (끝에서 pause 만 풀면 즉시 다시 끝 → 무동작).
      Item := ListData.GetNodeData(ActiveNode);
      if Assigned(Item) then
        Play(Item^.FileName);
    end
    else
      Next;   // 재생 중 없음 → 첫 곡부터

    Exit;
  end;

  // 파일 소실(외부 삭제/이동, USB 분리 등) → 항목은 두고 '없음' 표시 + 다음. mpv 에 넘기면 오류 후 재생 정지.
  if not FileExists(AFileName) then
  begin
    SkipMissing(AFileName);
    Exit;
  end;

  ListData.BeginUpdate;
  try
    Node := ListData.GetFirst;
    while Assigned(Node) do
    begin
      Item := ListData.GetNodeData(Node);
      if Assigned(Item) then
      begin
        Item^.IsActive := SameText(Item^.FileName, AFileName);
        ListData.Selected[Node] := Item^.IsActive;
        if Item^.IsActive then
        begin
          // 위 FileExists 통과 = 실존 확인. StartVerify 는 추가/로드 때만 도므로
          // 검사 당시 없던(네트워크·USB 지연) 파일의 Missing 이 그대로 남아
          // 재생 중인데도 전체 경로로 표시됐다 → 여기서 해제.
          Item^.Missing := False;
          ListData.FocusedNode := Node;
        end;
      end;
      Node := ListData.GetNext(Node);
    end;
  finally
    ListData.EndUpdate;
  end;

  if Assigned(ListData.FocusedNode) then
    Application.QueueAsyncCall(ScrollFocusedAsync, 0);
  FrmKPlayer.HandlePlay(AFileName);
end;

procedure TFrmList.Prev;
var
  ActiveNode: PVirtualNode;
  Item: PItemData;
  PrevNode: PVirtualNode;
begin
  if FrmKPlayer.RandomMode = 1 then
  begin
    // 실제 재생된 랜덤 순서 역추적
    if FShufflePos > 0 then
    begin
      Dec(FShufflePos);
      Play(FShuffleHistory[FShufflePos]);
    end;
    Exit;
  end;

  ActiveNode := FindActiveNode;
  if not Assigned(ActiveNode) then
    Exit;

  PrevNode := ListData.GetPrevious(ActiveNode);
  if not Assigned(PrevNode) then
    Exit;

  Item := ListData.GetNodeData(PrevNode);
  if Assigned(Item) then
    Play(Item^.FileName);
end;

procedure TFrmList.Next;
var
  ActiveNode: PVirtualNode;
  Item: PItemData;
  NextNode: PVirtualNode;
begin
  if FrmKPlayer.RandomMode = 1 then
  begin
    Rand;
    Exit;
  end;

  ActiveNode := FindActiveNode;
  if Assigned(ActiveNode) then
  begin
    NextNode := ListData.GetNext(ActiveNode);
    if Assigned(NextNode) then
    begin
      Item := ListData.GetNodeData(NextNode);
      if Assigned(Item) then
        Play(Item^.FileName);
    end;
    Exit;
  end;

  NextNode := ListData.GetFirst;
  if Assigned(NextNode) then
  begin
    Item := ListData.GetNodeData(NextNode);
    if Assigned(Item) then
      Play(Item^.FileName);
  end;
end;

function TFrmList.CurrentActiveFileName: string;
var
  Node: PVirtualNode;
  Item: PItemData;
begin
  Result := '';
  Node := FindActiveNode;
  if Assigned(Node) then
  begin
    Item := ListData.GetNodeData(Node);
    if Assigned(Item) then
      Result := Item^.FileName;
  end;
end;

function TFrmList.PlaylistContains(const AFileName: string): Boolean;
var
  Node: PVirtualNode;
  Item: PItemData;
begin
  Result := False;
  Node := ListData.GetFirst;
  while Assigned(Node) do
  begin
    Item := ListData.GetNodeData(Node);
    if Assigned(Item) and SameText(Item^.FileName, AFileName) then
      Exit(True);
    Node := ListData.GetNext(Node);
  end;
end;

// 사이클 미재생 곡 하나 무작위 (현재 곡 제외). 없으면 ''.
function TFrmList.PickRandomUnplayed: string;
var
  Node: PVirtualNode;
  Item: PItemData;
  Cur: string;
  Candidates: TStringArray;
  N: Integer;
begin
  Result := '';
  Cur := CurrentActiveFileName;
  SetLength(Candidates, ListData.RootNodeCount);
  N := 0;

  Node := ListData.GetFirst;
  while Assigned(Node) do
  begin
    Item := ListData.GetNodeData(Node);
    if Assigned(Item)
      and (FCyclePlayed.IndexOf(Item^.FileName) < 0)
      and not SameText(Item^.FileName, Cur) then
    begin
      Candidates[N] := Item^.FileName;
      Inc(N);
    end;
    Node := ListData.GetNext(Node);
  end;

  if N > 0 then
    Result := Candidates[Random(N)];
end;

procedure TFrmList.AppendShuffleHistory(const AFileName: string);
begin
  SetLength(FShuffleHistory, Length(FShuffleHistory) + 1);
  FShuffleHistory[High(FShuffleHistory)] := AFileName;
  FShufflePos := High(FShuffleHistory);
end;

// 새 사이클 시작. 현재 곡은 '이미 들은 것' 으로 등록.
procedure TFrmList.ResetShuffle;
var
  Cur: string;
begin
  SetLength(FShuffleHistory, 0);
  FShufflePos := -1;
  FCyclePlayed.Clear;

  Cur := CurrentActiveFileName;
  if Cur <> '' then
  begin
    AppendShuffleHistory(Cur);
    FCyclePlayed.Add(Cur);
  end;
end;

// 목록에서 사라진 파일을 이력·사이클 기록에서 제거
procedure TFrmList.PruneShuffleMissing;
var
  I, W, RemovedBeforePos: Integer;
  NewHist: TStringArray;
begin
  W := 0;
  RemovedBeforePos := 0;
  SetLength(NewHist, Length(FShuffleHistory));
  for I := 0 to High(FShuffleHistory) do
  begin
    if PlaylistContains(FShuffleHistory[I]) then
    begin
      NewHist[W] := FShuffleHistory[I];
      Inc(W);
    end
    else if I <= FShufflePos then
      Inc(RemovedBeforePos);
  end;
  SetLength(NewHist, W);
  FShuffleHistory := NewHist;

  FShufflePos := FShufflePos - RemovedBeforePos;
  if FShufflePos > High(FShuffleHistory) then
    FShufflePos := High(FShuffleHistory);
  if FShufflePos < -1 then
    FShufflePos := -1;

  for I := FCyclePlayed.Count - 1 downto 0 do
    if not PlaylistContains(FCyclePlayed[I]) then
      FCyclePlayed.Delete(I);
end;

procedure TFrmList.Rand;
var
  Cur: string;
  Pick: string;
begin
  if ListData.RootNodeCount = 0 then
    Exit;

  // Prev 로 되돌아온 상태 → 이력 전진 우선
  if (FShufflePos >= 0) and (FShufflePos < High(FShuffleHistory)) then
  begin
    Inc(FShufflePos);
    Play(FShuffleHistory[FShufflePos]);
    Exit;
  end;

  Cur := CurrentActiveFileName;
  if Cur <> '' then
    FCyclePlayed.Add(Cur);

  Pick := PickRandomUnplayed;

  if Pick = '' then
  begin
    // 한 바퀴 완료 → 새 사이클. 반복 설정 무시 — 랜덤 = 섞어 계속 듣는 모드,
    // 한 바퀴 후 정지는 무용.
    FCyclePlayed.Clear;

    // 직전 곡이 새 사이클 첫 곡으로 재등장 방지
    if Cur <> '' then
      FCyclePlayed.Add(Cur);

    Pick := PickRandomUnplayed;

    // 한 곡뿐이면 그 곡 재재생
    if (Pick = '') and (Cur <> '') then
      Pick := Cur;
  end;

  if Pick = '' then
  begin
    // 목록 빔 (또는 재생할 것 없음)
    EndPlayback;
    Exit;
  end;

  FCyclePlayed.Add(Pick);
  AppendShuffleHistory(Pick);
  Play(Pick);
end;

// 곡 종료 시 (script-message 'finished') 다음 재생 결정. mpv keep-open=yes 라
// 파일 끝나도 자체 언로드 없음 → 재생할 것 없으면 직접 정지 (안 하면 OSD 만 재생 중 표시 잔존).
procedure TFrmList.TrackFinished;
var
  ActiveNode: PVirtualNode;
  NextNode: PVirtualNode;
  Item: PItemData;
begin
  ActiveNode := FindActiveNode;

  // 한 곡 반복 = 랜덤 무관 최우선
  if FrmKPlayer.RepeatMode = 2 then
  begin
    if Assigned(ActiveNode) then
    begin
      Item := ListData.GetNodeData(ActiveNode);
      if Assigned(Item) then
        Play(Item^.FileName);
    end;
    Exit;
  end;

  // 랜덤: Rand 가 사이클 끝 처리 + 재섞기 담당
  if FrmKPlayer.RandomMode = 1 then
  begin
    Rand;
    Exit;
  end;

  // 순차 재생
  case FrmKPlayer.RepeatMode of
    0: // 반복 없음
    begin
      // 마지막 곡이면 정지. Next 는 다음 없으면 무동작(수동 클릭엔 그게 맞음) → 여기서 분기.
      if Assigned(ActiveNode) and not Assigned(ListData.GetNext(ActiveNode)) then
        EndPlayback
      else
        Next;

      Exit;
    end;

    1: // 전체 반복
    begin
      if not Assigned(ActiveNode) then
      begin
        Next;
        Exit;
      end;

      NextNode := ListData.GetNext(ActiveNode);
      if Assigned(NextNode) then
      begin
        Next;
        Exit;
      end;

      PlayFirst;   // 마지막 곡 → 처음으로
    end;
  end;
end;

end.
