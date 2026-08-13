unit List;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.Dwmapi, Winapi.UxTheme, System.SysUtils,
  System.Variants, System.Classes, System.IOUtils, System.StrUtils, System.Types,
  System.ImageList, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.FileCtrl, Vcl.Menus, Vcl.ImgList, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree,
  VirtualTrees.AncestorVCL, VirtualTrees.Types,VirtualTrees, SVGIconImage, SVGIconImageListBase,
  SVGIconImageList, VTScrollbar, K.DragFile;

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
  end;
  PItemData = ^TItemData;

  TFrmList = class(TForm)
    ListData: TVirtualStringTree;
    Panel1: TPanel;
    BtnRepeat: TSVGIconImage;
    ListIcon: TSVGIconImageList;
    BtnRandom: TSVGIconImage;
    BtnAdd: TSVGIconImage;
    BtnDel: TSVGIconImage;
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
    procedure BtnRepeatMouseEnter(Sender: TObject);
    procedure BtnRepeatMouseLeave(Sender: TObject);
    procedure BtnRepeatMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BtnRepeatMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
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
    FDarkSB: TVTDarkScrollbar;
    FDragNode: PVirtualNode;
    FDragFile: TDragFile;
    FPlaylistDepth: Integer;   // 재생목록 상호 참조 무한 재귀 방지
    FSkipDepth: Integer;       // 없는 파일 연속 건너뛰기 안전장치
    FDragStart: TPoint;
    FSavedSelection: TArray<PVirtualNode>;

    // 랜덤 상태 (사이클 내 중복 없음)
    FShuffleHistory: TArray<string>;  // 실제 재생 순서 (Prev 가 되짚음)
    FShufflePos: Integer;             // 현재 곡 이력 인덱스 (-1=없음)
    FCyclePlayed: TStringList;        // 이번 사이클 재생 완료 파일

    function FindActiveNode: PVirtualNode;
    procedure UpdateButtonColor(Btn: TSVGIconImage; Hover: Boolean);
    procedure WMScrollFocusedNode(var Msg: TMessage); message WM_APP + 1;

    function CurrentActiveFileName: string;
    function PlaylistContains(const AFileName: string): Boolean;
    function PickRandomUnplayed: string;
    procedure ResetShuffle;
    procedure AppendShuffleHistory(const AFileName: string);
    procedure PruneShuffleMissing;
    procedure AddPlaylist(const AFileName: string);
    function FindNodeByName(const AFileName: string): PVirtualNode;
    procedure SkipMissing(const AFileName: string);
  private
    procedure EndPlayback;
    procedure PlayFirst;
  public
    procedure UpdateModeIcons;
    procedure SavePlaylist;
    procedure LoadPlaylist;
    procedure AddFile(AFileName: string; ACheckDisk: Boolean = True);
    procedure AddFiles(const AFiles: TArray<string>; APlay: Boolean);
    procedure DelFile(AMode: TDeleteMode);
    procedure SetRepeat;
    procedure SetRandom;
    procedure Play(AFileName: string);
    procedure Prev;
    procedure Next;
    procedure Rand;
    procedure TrackFinished;
  end;

const
  WM_SCROLL_FOCUSED_NODE = WM_APP + 1;

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

var
  FrmList: TFrmList;

implementation

{$R *.dfm}

uses Main, Setup, Assoc;

{$I Const.inc}

procedure SetDarkTitleBar(AHandle: HWND);
var
  UseDarkMode: BOOL;
begin
  UseDarkMode := True;
  DwmSetWindowAttribute(AHandle, 20, @UseDarkMode, SizeOf(UseDarkMode));
end;

procedure TFrmList.FormCreate(Sender: TObject);
begin
  Randomize;

  FCyclePlayed := TStringList.Create;
  FCyclePlayed.Sorted := True;
  FCyclePlayed.Duplicates := dupIgnore;
  FCyclePlayed.CaseSensitive := False;
  FShufflePos := -1;

  BorderIcons := [biSystemMenu];
  SetDarkTitleBar(Handle);

  Color := COLOR_BG_MAIN;

  UpdateButtonColor(BtnRepeat, False);
  UpdateButtonColor(BtnRandom, False);
  UpdateButtonColor(BtnAdd, False);
  UpdateButtonColor(BtnDel, False);

  ListData.NodeDataSize := SizeOf(TItemData);

  ListData.BevelInner := bvNone;
  ListData.BevelOuter := bvNone;
  ListData.BorderStyle := bsNone;

  ListData.Header.Columns.Add.Text := '';
  ListData.Header.Options := ListData.Header.Options + [hoAutoResize];
  ListData.TreeOptions.AutoOptions := ListData.TreeOptions.AutoOptions + [toAutoScroll];
  ListData.TreeOptions.PaintOptions := ListData.TreeOptions.PaintOptions + [toHideFocusRect] - [toShowRoot, toShowTreeLines]; // , toUseExplorerTheme
  ListData.TreeOptions.SelectionOptions := ListData.TreeOptions.SelectionOptions + [toFullRowSelect, toMultiSelect, toExtendedFocus];
  ListData.TreeOptions.MiscOptions := ListData.TreeOptions.MiscOptions + [toReportMode, toWheelPanning] - [toAcceptOLEDrop, toVariableNodeHeight];
  ListData.DefaultNodeHeight := 24;


  ListData.Color := COLOR_BG_MAIN;
  ListData.Font.Color := COLOR_TEXT_NORMAL;
  ListData.Colors.SelectionTextColor := COLOR_TEXT_SELECTED;
  ListData.Colors.FocusedSelectionColor := COLOR_SELECT_FOCUSED;
  ListData.Colors.FocusedSelectionBorderColor := COLOR_SELECT_FOCUSED;
  ListData.Colors.UnfocusedSelectionColor := COLOR_SELECT_UNFOCUSED;
  ListData.Colors.UnfocusedSelectionBorderColor := COLOR_SELECT_UNFOCUSED;

  FDarkSB := TVTDarkScrollbar.Create(ListData);

  FDragFile := TDragFile.Create(ListData,
  procedure(const Files: TArray<string>)
  begin
    AddFiles(Files, False);   // 목록 창 드롭은 추가만 (재생은 본체 창 드롭에서)
  end);

  // 저장 목록 먼저, 명령줄 파일 뒤에. 재생은 명령줄 파일이 가져감
  // (HandleStartupParams 가 그것만 Play) — 연결 파일 더블클릭 시 지난 목록 첫 곡 시작 방지.
  LoadPlaylist;

  FrmKPlayer.HandleStartupParams;
end;

procedure TFrmList.FormDestroy(Sender: TObject);
begin
  // 이 폼이 FrmKPlayer 보다 먼저 파괴(dpr 생성 역순) — 여기서 저장해야 Config 생존.
  SavePlaylist;

  FDragFile.Free;
  FDarkSB.Free;
  FCyclePlayed.Free;
end;

procedure TFrmList.FormResize(Sender: TObject);
begin
  BtnAdd.Left := ClientWidth - ScaleValue(46);
  BtnDel.Left := ClientWidth - ScaleValue(26);
end;

procedure TFrmList.BtnRepeatMouseEnter(Sender: TObject);
begin
  UpdateButtonColor(TSVGIconImage(Sender), True);
end;

procedure TFrmList.BtnRepeatMouseLeave(Sender: TObject);
begin
  UpdateButtonColor(TSVGIconImage(Sender), False);
end;

procedure TFrmList.BtnRepeatMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    TSVGIconImage(Sender).FixedColor := COLOR_ICON_PRESSED;
end;

procedure TFrmList.BtnRepeatMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    UpdateButtonColor(TSVGIconImage(Sender), False);

    case TSVGIconImage(Sender).Tag of
      1: SetRepeat;
      2: SetRandom;
      3: PopAdd.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
      4: PopDel.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
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
var
  Dialog: TOpenDialog;
  FileName: string;
begin
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Options := Dialog.Options + [ofAllowMultiSelect, ofFileMustExist, ofEnableSizing];
    Dialog.Filter := 'Media Files|*.mp3;*.mp4;*.avi;*.mkv;*.asf;*.mov;*.wmv|All Files|*.*';

    if Dialog.Execute then
      for FileName in Dialog.Files do
        AddFile(FileName);
  finally
    Dialog.Free;
  end;
end;

procedure TFrmList.BtnAddPopupFolderClick(Sender: TObject);
var
  FolderPath: string;
begin
  FolderPath := '';
  if SelectDirectory('폴더 선택', '', FolderPath) then
    AddFile(FolderPath);
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

  if FileExists(Item^.FileName) then
    Text := TPath.GetFileNameWithoutExtension(Item^.FileName)
  else
    Text := Item^.FileName;

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

  FDragStart := Point(X, Y);
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
  M: Integer;
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
      for var N in FSavedSelection do
        ListData.Selected[N] := True;
      SetLength(FSavedSelection, 0);
    end;

    FDragNode := ListData.GetNodeAt(FDragStart.X, FDragStart.Y);
    Exit;
  end;

  TargetNode := ListData.GetNodeAt(X, Y);
  if not Assigned(TargetNode) then Exit;

  M := Integer(TargetNode.Index) - Integer(FDragNode.Index);
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
    1: Result := '전체 반복';
    2: Result := '한 곡 반복';
  else
    Result := '반복 없음';
  end;

  // 랜덤 = 한 바퀴 후 재섞어 계속 재생 → '반복 없음' 무의미.
  if (FrmKPlayer.RepeatMode = 0) and (FrmKPlayer.RandomMode = 1) then
    Result := Result + ' (랜덤이 켜져 있어 계속 재생됩니다)';
end;

function RandomHint: string;
begin
  if FrmKPlayer.RandomMode = 1 then
    Result := '랜덤 켜짐 — 목록을 섞어 재생하고, 한 바퀴 돌면 다시 섞습니다'
  else
    Result := '랜덤 꺼짐 — 목록 순서대로 재생합니다';
end;

procedure TFrmList.UpdateButtonColor(Btn: TSVGIconImage; Hover: Boolean);
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

procedure TFrmList.WMScrollFocusedNode(var Msg: TMessage);
begin
  if Assigned(ListData.FocusedNode) then
    ListData.ScrollIntoView(ListData.FocusedNode, False);
end;

// .m3u8=UTF-8 규격, .m3u 는 ANSI(CP949) 흔함. BOM 우선; 없으면
// UTF-8 왕복 인코딩 바이트 수 불일치(=깨진 바이트) 시 ANSI.
function ReadPlaylistText(const AFileName: string): string;
var
  LBytes: TBytes;
  LEncoding: TEncoding;
  LPreamble: Integer;
begin
  Result := '';

  LBytes := TFile.ReadAllBytes(AFileName);
  if Length(LBytes) = 0 then
    Exit;

  LEncoding := nil;
  LPreamble := TEncoding.GetBufferEncoding(LBytes, LEncoding, TEncoding.UTF8);

  if (LPreamble = 0) and
     (Length(TEncoding.UTF8.GetBytes(TEncoding.UTF8.GetString(LBytes))) <> Length(LBytes)) then
    LEncoding := TEncoding.ANSI;

  Result := LEncoding.GetString(LBytes, LPreamble, Length(LBytes) - LPreamble);
end;

// TPath.Combine 은 잘못된 문자에 예외 — 재생목록엔 URL/이상한 줄 섞임 → 미사용.
function IsAbsolutePath(const APath: string): Boolean;
begin
  Result := ((Length(APath) >= 3) and (APath[2] = ':') and
             CharInSet(APath[3], ['\', '/'])) or
            ((Length(APath) >= 2) and (APath[1] = '\') and (APath[2] = '\'));
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
      Lines.Text := ReadPlaylistText(AFileName);

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
        else if Line.StartsWith('#') then
          Continue;   // #EXTM3U/#EXTINF 등 주석/지시자

        if Line = '' then
          Continue;

        // 스트리밍 URL 스킵 — 목록 창은 파일 경로 기준 (없는 파일 취급, 어차피 진입 불가).
        if Line.Contains('://') then
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
// 파일 = exe 폴더 KPlayer.lst — 설정 ini 와 같은 자리, 포터블 이동 추종.
// 형식 = 경로 한 줄씩 평문(UTF-8 BOM). .lst 확장자 = 탐색기의 재생목록 오인 방지.
// 읽기는 ReadPlaylistText → 메모장 ANSI 저장도 읽힘.
function PlaylistFile: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + AppName + '.lst';
end;

function SavePlaylistEnabled: Boolean;
begin
  Result := (FrmKPlayer <> nil) and (FrmKPlayer.Config <> nil) and
            (FrmKPlayer.Config.ReadInteger('save_playlist', 1) <> 0);
end;

procedure DeletePlaylistFile;
begin
  if TFile.Exists(PlaylistFile) then
    TFile.Delete(PlaylistFile);
end;

// 종료 시 호출(FormDestroy). 예외 나가면 종료 중 오류 창 → 통째 차단 (읽기 전용 폴더 실행 사례 있음).
procedure TFrmList.SavePlaylist;
var
  LLines: TStringList;
  LNode: PVirtualNode;
  LItem: PItemData;
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
        LLines.SaveToFile(PlaylistFile, TEncoding.UTF8);
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
  LLine, LPath: string;
begin
  if not SavePlaylistEnabled then
    Exit;

  try
    if not TFile.Exists(PlaylistFile) then
      Exit;

    LLines := TStringList.Create;
    LSeen := TStringList.Create;
    try
      // AddFile 노드 중복 검사 생략 대신 줄 단위 사전 필터.
      LSeen.Sorted := True;
      LSeen.CaseSensitive := False;

      LLines.Text := ReadPlaylistText(PlaylistFile);

      ListData.BeginUpdate;
      try
        for LLine in LLines do
        begin
          LPath := Trim(LLine);
          if (LPath = '') or LPath.StartsWith('#') then
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
  except
    on E: Exception do ;
  end;
end;

// ACheckDisk=False = 시작 로드 전용, 디스크 무접근 (이유: LoadPlaylist 주석).
procedure TFrmList.AddFile(AFileName: string; ACheckDisk: Boolean);
var
  Node: PVirtualNode;
  Item: PItemData;
  SearchRec: TSearchRec;
begin
  if ACheckDisk then
  begin
    if TDirectory.Exists(AFileName) then
    begin
      if FindFirst(TPath.Combine(AFileName, '*'), faAnyFile, SearchRec) = 0 then
      try
        repeat
          if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
            Continue;
          AddFile(TPath.Combine(AFileName, SearchRec.Name));
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
      Exit;
    end;

    if not FileExists(AFileName) then
      Exit;
  end;

  // 지원 확장자 = Assoc.pas AssocExts 단일 출처 (파일 연결 카드 공용).
  if not IsMediaFile(AFileName) then
    Exit;

  // 재생목록 = 항목으로 안 넣고 내부 경로 전개. 넣으면 목록엔 한 줄인데
  // mpv 는 내부 재생목록 별도 진행 → 다음/이전 버튼과 실제 재생 어긋남.
  if IsPlaylistFile(AFileName) then
  begin
    // 시작 로드는 미전개 (읽기 = 디스크 접근).
    if ACheckDisk then
      AddPlaylist(AFileName);
    Exit;
  end;

  // 시작 로드: 빈 목록 + 사전 중복 필터 → 노드 검사(O(n²)) 생략.
  if ACheckDisk then
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

  Node := ListData.AddChild(nil);
  Item := ListData.GetNodeData(Node);
  ListData.NodeHeight[Node] := 24;
  Item^.FileName := AFileName;
  Item^.IsActive := False;
end;

// 일괄 추가 + 재생. 드롭 경로를 그대로 Play 하면 안 되는 이유 — 폴더는 내용물만 항목이
// 되고(AddFile 재귀), 비지원 확장자는 걸러지고, 재생목록은 내부 경로로 펼쳐진다.
// 셋 다 '목록에 없는 경로' 라 Play 가 SkipMissing/mpv 오류로 빠졌다 (폴더 드롭 시
// "파일을 찾을 수 없습니다 — <폴더명>" + 재생 안 됨).
// 그래서 추가 전 마지막 노드를 표시해 두고 그 다음(= 이번에 새로 들어간 첫) 노드부터 재생.
procedure TFrmList.AddFiles(const AFiles: TArray<string>; APlay: Boolean);
var
  Mark, Node: PVirtualNode;
  Item: PItemData;
begin
  if Length(AFiles) = 0 then
    Exit;

  Mark := ListData.GetLast;

  ListData.BeginUpdate;
  try
    for var S in AFiles do
      AddFile(S);
  finally
    ListData.EndUpdate;
  end;

  if not APlay then
    Exit;

  if Assigned(Mark) then
    Node := ListData.GetNext(Mark)
  else
    Node := ListData.GetFirst;

  // 새로 들어간 것 없음(전부 중복) → 드롭한 첫 경로가 이미 목록에 있으면 그것을 재생.
  if not Assigned(Node) then
    Node := FindNodeByName(AFiles[0]);

  if not Assigned(Node) then
    Exit;

  Item := ListData.GetNodeData(Node);
  if Assigned(Item) then
    Play(Item^.FileName);
end;

procedure TFrmList.DelFile(AMode: TDeleteMode);
var
  Node: PVirtualNode;
  NextNode: PVirtualNode;
  Item: PItemData;
  ToDelete: TArray<PVirtualNode>;
  DeleteCount: Integer;
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
    for Node in ToDelete do
      ListData.DeleteNode(Node);
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
  // 폼 생성 중(DFM 스트리밍 전) 호출 가능
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

// 없는 파일 하나 제거 + 다음 곡. 일괄 정리 금지 — 네트워크/USB 일시 분리 시 목록이 조용히 비워짐.
procedure TFrmList.SkipMissing(const AFileName: string);
const
  MaxSkip = 64;   // 목록 전체가 없는 파일일 때 안전장치
var
  Node, NextNode: PVirtualNode;
  Item: PItemData;
  NextName: string;
  IsRandom: Boolean;
begin
  IsRandom := FrmKPlayer.RandomMode = 1;
  NextName := '';

  // 건너뛴 이유 화면 알림 (목록 창 닫혀 있으면 항목 삭제 인지 불가)
  FrmKPlayer.Alert('파일을 찾을 수 없습니다 — ' + ExtractFileName(AFileName),
    ALERT_ERROR);

  Node := FindNodeByName(AFileName);
  if Assigned(Node) then
  begin
    // 삭제 전 다음 항목 기억 — 삭제 후엔 활성 없음 → Next 가 맨 처음으로 감.
    if not IsRandom then
    begin
      NextNode := ListData.GetNext(Node);
      if Assigned(NextNode) then
      begin
        Item := ListData.GetNodeData(NextNode);
        if Assigned(Item) then
          NextName := Item^.FileName;
      end;
    end;

    ListData.DeleteNode(Node);
    PruneShuffleMissing;   // 셔플 이력/사이클에서도 제거
  end;

  if ListData.RootNodeCount = 0 then
  begin
    EndPlayback;
    Exit;
  end;

  if FSkipDepth >= MaxSkip then
    Exit;

  Inc(FSkipDepth);
  try
    if IsRandom then
      Rand
    else if NextName <> '' then
      Play(NextName)
    else if FrmKPlayer.RepeatMode = 1 then
      // 마지막 항목이 없는 파일 — 삭제 후 Next 무동작 → 처음 곡 직접 재생.
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

  // 파일 소실(외부 삭제/이동, USB 분리 등) → 목록 제거 + 다음. mpv 에 넘기면 오류 후 재생 정지.
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
          ListData.FocusedNode := Node;
      end;
      Node := ListData.GetNext(Node);
    end;
  finally
    ListData.EndUpdate;
  end;

  if Assigned(ListData.FocusedNode) then
    PostMessage(Handle, WM_SCROLL_FOCUSED_NODE, 0, 0);
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
  Candidates: TArray<string>;
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
  NewHist: TArray<string>;
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
