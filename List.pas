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
    FPlaylistDepth: Integer;   // 재생목록이 서로를 가리킬 때 무한 재귀 방지
    FSkipDepth: Integer;       // 없는 파일을 연달아 건너뛸 때의 안전장치
    FDragStart: TPoint;
    FSavedSelection: TArray<PVirtualNode>;

    // 랜덤(한 사이클 안에서 중복 없이) 상태
    FShuffleHistory: TArray<string>;  // 실제 재생 순서 (Prev 로 되짚는다)
    FShufflePos: Integer;             // 지금 곡의 이력 인덱스 (-1 = 없음)
    FCyclePlayed: TStringList;        // 이번 사이클에 이미 재생한 파일들

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
    procedure AddFile(AFileName: string);
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

  // 창
  BorderIcons := [biSystemMenu];
  SetDarkTitleBar(Handle);

  // 테마
  Color := COLOR_BG_MAIN;

  UpdateButtonColor(BtnRepeat, False);
  UpdateButtonColor(BtnRandom, False);
  UpdateButtonColor(BtnAdd, False);
  UpdateButtonColor(BtnDel, False);

  // 목록 트리
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

  // 보조 객체
  FDarkSB := TVTDarkScrollbar.Create(ListData);

  FDragFile := TDragFile.Create(ListData,
  procedure(const Files: TArray<string>)
  begin
    for var S in Files do
      AddFile(S);
  end);

  // 저장된 목록을 먼저 올리고 명령줄 파일을 그 뒤에 붙인다. 재생은 명령줄
  // 파일이 가져간다 (HandleStartupParams 가 그 파일만 Play 한다) — 연결된
  // 파일을 더블클릭했을 때 지난 목록의 첫 곡이 대신 시작되면 안 된다.
  LoadPlaylist;

  FrmKPlayer.HandleStartupParams;
end;

procedure TFrmList.FormDestroy(Sender: TObject);
begin
  // 이 폼이 FrmKPlayer 보다 먼저 파괴된다 (dpr 의 생성 순서 역순). 그래서
  // 여기서 저장해야 FrmKPlayer.Config 가 아직 살아 있다.
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

// Del = 선택 항목을 목록에서 제거 (파일을 지우는 것이 아니다).
// 폼의 KeyPreview 가 아니라 트리의 이벤트에 붙인다 — 다른 컨트롤의 입력까지
// 가로채지 않게.
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

// 아이콘 툴팁. 상태가 바뀔 때마다(UpdateButtonColor 가 불릴 때) 다시 만든다.
// 아이콘만으로는 지금 어떤 모드인지 알기 어렵다.
function RepeatHint: string;
begin
  case FrmKPlayer.RepeatMode of
    1: Result := '전체 반복';
    2: Result := '한 곡 반복';
  else
    Result := '반복 없음';
  end;

  // 랜덤은 한 바퀴 돌면 다시 섞어 계속 재생하므로 '반복 없음' 이 무의미하다.
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

// 재생목록 파일을 읽는다. .m3u8 은 UTF-8 이 규격이지만 .m3u 은 ANSI(CP949)도
// 흔하다. BOM 이 있으면 그것을 따르고, 없으면 UTF-8 로 해석해 본 뒤 되돌려
// 인코딩했을 때 바이트 수가 달라지면(= 깨진 바이트가 있었다) ANSI 로 읽는다.
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

// TPath.Combine 은 잘못된 문자가 있으면 예외를 던지므로 쓰지 않는다
// (재생목록에는 URL 이나 이상한 줄이 섞여 들어온다).
function IsAbsolutePath(const APath: string): Boolean;
begin
  Result := ((Length(APath) >= 3) and (APath[2] = ':') and
             CharInSet(APath[3], ['\', '/'])) or
            ((Length(APath) >= 2) and (APath[1] = '\') and (APath[2] = '\'));
end;

procedure TFrmList.AddPlaylist(const AFileName: string);
const
  MaxDepth = 3;   // 재생목록 안의 재생목록
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
          // [playlist] 섹션의 File1=... 만 경로다 (Title1=, Length1= 등은 건너뛴다)
          if not StartsText('File', Line) then
            Continue;

          Eq := Pos('=', Line);
          if Eq = 0 then
            Continue;

          Line := Trim(Copy(Line, Eq + 1, MaxInt));
        end
        else if Line.StartsWith('#') then
          Continue;   // #EXTM3U, #EXTINF 같은 주석/지시자

        if Line = '' then
          Continue;

        // 스트리밍 URL 은 건너뛴다 — 재생목록 창은 파일 경로를 기준으로 동작한다
        // (없는 파일 취급되어 어차피 목록에 들어가지 못한다).
        if Line.Contains('://') then
          Continue;

        if IsAbsolutePath(Line) then
          Path := Line
        else
          Path := ExpandFileName(Dir + Line);   // 상대경로는 재생목록 위치 기준

        AddFile(Path);   // 확장자 필터/중복 검사는 AddFile 이 한다
      end;
    finally
      Lines.Free;
    end;
  finally
    Dec(FPlaylistDepth);
  end;
end;

// 목록 저장/복원 (환경설정 '일반 → 재생목록 저장').
//
// 저장 파일은 exe 폴더의 KPlayer.lst 다 — 설정 ini 와 같은 자리라 포터블로
// 폴더째 옮겨도 따라간다. 형식은 경로 한 줄씩인 평문(BOM 있는 UTF-8)이고,
// 확장자를 .lst 로 둬야 탐색기가 재생목록으로 오인하지 않는다. 읽기는
// ReadPlaylistText 를 쓰므로 메모장으로 ANSI 저장해도 읽힌다.
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

// 종료할 때 부른다 (TFrmList.FormDestroy). 여기서 예외가 나가면 종료 중에
// 오류 창이 뜨므로 통째로 막는다 — 읽기 전용 폴더에서 실행하는 경우가 있다.
procedure TFrmList.SavePlaylist;
var
  LLines: TStringList;
  LNode: PVirtualNode;
  LItem: PItemData;
begin
  try
    // 방금 끈 경우에도 예전 파일이 남으면 다음 실행에서 되살아난다.
    // '목록이 빈 상태' 도 그대로 보존해야 하므로 둘 다 파일을 지운다.
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

// 시작할 때 명령줄 처리보다 먼저 부른다 (TFrmList.FormCreate).
// 없는 파일·중복·지원하지 않는 확장자는 AddFile 이 걸러낸다.
procedure TFrmList.LoadPlaylist;
var
  LLines: TStringList;
  LLine: string;
begin
  if not SavePlaylistEnabled then
    Exit;

  try
    if not TFile.Exists(PlaylistFile) then
      Exit;

    LLines := TStringList.Create;
    try
      LLines.Text := ReadPlaylistText(PlaylistFile);

      for LLine in LLines do
      begin
        if (Trim(LLine) = '') or Trim(LLine).StartsWith('#') then
          Continue;
        AddFile(Trim(LLine));
      end;
    finally
      LLines.Free;
    end;
  except
    on E: Exception do ;
  end;
end;

procedure TFrmList.AddFile(AFileName: string);
var
  Node: PVirtualNode;
  Item: PItemData;
  SearchRec: TSearchRec;
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

  // 지원 확장자 목록은 Assoc.pas 의 AssocExts 하나다 (파일 연결 카드와 공용).
  if not IsMediaFile(AFileName) then
    Exit;

  // 재생목록은 그 파일을 항목으로 넣지 않고 안의 경로들을 펼친다.
  // 넣어버리면 목록에는 한 줄만 보이는데 mpv 는 내부 재생목록을 따로 돌려서
  // 다음/이전 버튼이 실제 재생과 어긋난다.
  if IsPlaylistFile(AFileName) then
  begin
    AddPlaylist(AFileName);
    Exit;
  end;

  Node := ListData.GetFirst;
  while Assigned(Node) do
  begin
    Item := ListData.GetNodeData(Node);
    if Assigned(Item) and SameText(Item^.FileName, AFileName) then
      Exit;
    Node := ListData.GetNext(Node);
  end;

  Node := ListData.AddChild(nil);
  Item := ListData.GetNodeData(Node);
  ListData.NodeHeight[Node] := 24;
  Item^.FileName := AFileName;
  Item^.IsActive := False;
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

  PruneShuffleMissing;   // 사라진 파일을 이력·사이클에서 뺀다

  if not ActiveDeleted then
    Exit;

  FirstNode := ListData.GetFirst;

  if not Assigned(FirstNode) then
  begin
    EndPlayback;   // 목록을 다 지웠다
    Exit;
  end;

  FirstItem := ListData.GetNodeData(FirstNode);
  Play(FirstItem^.FileName);
end;

// 목록 첫 곡을 재생한다. 없으면 재생을 끝낸다.
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

// 더 재생할 것이 없을 때. 정지가 아니라 '마지막 프레임에서 멈춤' 이다 —
// mpv stop 은 파일을 내려 화면이 검게 되고 처음 실행한 것과 같아진다.
// 목록의 '재생 중' 표시도 남긴다 (화면에 그 영상이 그대로 있다).
procedure TFrmList.EndPlayback;
begin
  ResetShuffle;              // 다음 랜덤은 새 사이클로 시작한다
  FrmKPlayer.SetPause(True);
end;

procedure TFrmList.UpdateModeIcons;
begin
  // 폼 생성 중(DFM 스트리밍 전)에 불릴 수 있다
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
  ResetShuffle;   // 새 사이클을 시작한다
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

// 없는 파일 하나를 목록에서 빼고 다음 곡으로 넘어간다. 한꺼번에 정리하지
// 않는다 — 네트워크 드라이브나 USB 가 잠깐 빠졌을 때 목록이 조용히 비워진다.
procedure TFrmList.SkipMissing(const AFileName: string);
const
  MaxSkip = 64;   // 목록 전체가 없는 파일일 때를 위한 안전장치
var
  Node, NextNode: PVirtualNode;
  Item: PItemData;
  NextName: string;
  IsRandom: Boolean;
begin
  IsRandom := FrmKPlayer.RandomMode = 1;
  NextName := '';

  // 왜 넘어갔는지 화면에 알린다 (목록 창이 닫혀 있으면 항목이 사라진 것도 모른다)
  FrmKPlayer.Alert('파일을 찾을 수 없습니다 — ' + ExtractFileName(AFileName),
    ALERT_ERROR);

  Node := FindNodeByName(AFileName);
  if Assigned(Node) then
  begin
    // 지우기 전에 다음 항목을 기억한다. 지운 뒤에는 활성 항목이 없어서
    // Next 가 목록 맨 처음으로 되돌아간다.
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
    PruneShuffleMissing;   // 셔플 이력/사이클에서도 뺀다
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
      // 마지막 항목이 없는 파일이었다 — 지운 뒤에는 Next 가 아무 일도 하지
      // 않으므로 처음 곡을 직접 재생한다.
      PlayFirst
    else if not FrmKPlayer.IsPlay then
      // 뒤에 재생할 것이 없다 → 멈춘다. 다른 곡이 재생 중이면 건드리지
      // 않는다 (없는 파일을 눌러 봤다고 보던 영상을 멈추면 안 된다).
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
    // 재생/일시정지 토글. 다만 mpv 에 열린 파일이 없으면(정지 상태) pause 를
    // 토글해도 아무 일도 일어나지 않으므로 다시 열어 준다.
    ActiveNode := FindActiveNode;

    if Assigned(ActiveNode) and FrmKPlayer.IsLoaded and
       not FrmKPlayer.IsEOF then
      FrmKPlayer.HandlePause
    else if Assigned(ActiveNode) then
    begin
      // 파일이 내려갔거나 끝에 멈춰 있다 -> 그 곡을 처음부터 다시 연다.
      // (끝에서 pause 만 풀면 곧바로 다시 끝에 닿아 아무 일도 일어나지 않는다)
      Item := ListData.GetNodeData(ActiveNode);
      if Assigned(Item) then
        Play(Item^.FileName);
    end
    else
      Next;   // 재생 중인 것이 없다 -> 첫 곡부터

    Exit;
  end;

  // 파일이 사라졌으면(외부에서 삭제/이동, USB 분리 등) 목록에서 빼고 다음으로
  // 넘긴다. mpv 에 넘겨도 오류만 나고 재생이 멈춘다.
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
    // 실제로 재생된 랜덤 순서를 거꾸로 되짚는다
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

// 이번 사이클에 아직 재생하지 않은 곡 하나를 무작위로 (지금 재생 중인 곡은
// 제외). 남은 것이 없으면 ''.
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

// 새 사이클을 시작한다. 지금 재생 중인 곡은 '이미 들은 것' 으로 넣어 둔다.
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

// 목록에서 사라진 파일을 이력과 사이클 기록에서 뺀다
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

  // Prev 로 되돌아온 상태면 먼저 이력을 앞으로 되짚는다
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
    // 한 바퀴 다 돌았다 → 새 사이클. 반복 설정은 보지 않는다 — 랜덤은 섞어
    // 계속 듣는 모드라 한 바퀴 돌고 멈추면 쓸 데가 없다.
    FCyclePlayed.Clear;

    // 방금 들은 곡이 새 사이클 첫 곡으로 또 나오지 않게 제외한다
    if Cur <> '' then
      FCyclePlayed.Add(Cur);

    Pick := PickRandomUnplayed;

    // 목록에 한 곡뿐이면 그 곡을 다시 재생한다
    if (Pick = '') and (Cur <> '') then
      Pick := Cur;
  end;

  if Pick = '' then
  begin
    // 목록이 비었다 (또는 재생할 것이 없다)
    EndPlayback;
    Exit;
  end;

  FCyclePlayed.Add(Pick);
  AppendShuffleHistory(Pick);
  Play(Pick);
end;

// 곡이 끝났을 때 (script-message 'finished'). 다음에 무엇을 재생할지 정한다.
// mpv 는 keep-open=yes 라 파일이 끝나도 스스로 내려가지 않으므로, 더 재생할
// 것이 없으면 우리가 멈춰야 한다 — 그러지 않으면 OSD 만 재생 중처럼 남는다.
procedure TFrmList.TrackFinished;
var
  ActiveNode: PVirtualNode;
  NextNode: PVirtualNode;
  Item: PItemData;
begin
  ActiveNode := FindActiveNode;

  // 한 곡 반복은 랜덤과 무관하게 먼저 처리한다
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

  // 랜덤은 Rand 가 사이클 끝 처리와 재섞기를 함께 맡는다
  if FrmKPlayer.RandomMode = 1 then
  begin
    Rand;
    Exit;
  end;

  // 순차 재생
  case FrmKPlayer.RepeatMode of
    0: // 반복 없음
    begin
      // 마지막 곡이었으면 정지한다. Next 는 다음이 없을 때 아무 것도 하지 않으므로
      // (사용자가 직접 누른 경우엔 그게 맞다) 여기서 갈라준다.
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

      PlayFirst;   // 마지막 곡이었다 — 처음으로 돌아간다
    end;
  end;
end;

end.
