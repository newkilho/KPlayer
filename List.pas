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
    FDragStart: TPoint;
    FSavedSelection: TArray<PVirtualNode>;

    // Shuffle (random-without-repeat) state
    FShuffleHistory: TArray<string>;  // actual play order (for Prev navigation)
    FShufflePos: Integer;             // index into FShuffleHistory of current track (-1 = none)
    FCyclePlayed: TStringList;        // filenames already played in the current no-repeat cycle

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
  public
    procedure AddFile(AFileName: string);
    procedure DelFile(AMode: TDeleteMode);
    procedure SetRepeat;
    procedure SetRandom;
    procedure Play(AFileName: string);
    procedure Prev;
    procedure Next;
    procedure Rand;
    procedure Stop;
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

uses Main, Setup;

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

  // Windows
  BorderIcons := [biSystemMenu];
  SetDarkTitleBar(Handle);

  // Theme
  Color := COLOR_BG_MAIN;

  UpdateButtonColor(BtnRepeat, False);
  UpdateButtonColor(BtnRandom, False);
  UpdateButtonColor(BtnAdd, False);
  UpdateButtonColor(BtnDel, False);

  // VirtualTree
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

  // Helpers
  FDarkSB := TVTDarkScrollbar.Create(ListData);

  FDragFile := TDragFile.Create(ListData,
  procedure(const Files: TArray<string>)
  begin
    for var S in Files do
      AddFile(S);
  end);

  FrmKPlayer.HandleStartupParams;
end;

procedure TFrmList.FormDestroy(Sender: TObject);
begin
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

procedure TFrmList.UpdateButtonColor(Btn: TSVGIconImage; Hover: Boolean);
begin
  case Btn.Tag of
    1: // Repeat
    begin
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

    2: // Random
      if FrmKPlayer.RandomMode = 0 then
      begin
        if Hover then
          Btn.FixedColor := COLOR_ICON_HOVER
        else
          Btn.FixedColor := COLOR_ICON_NORMAL;
      end
      else
        Btn.FixedColor := COLOR_ICON_ACTIVE;

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

  // 지원 확장자 목록은 Setup.pas 의 AssocExts 하나다 (파일 연결 카드와 공용).
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

  PruneShuffleMissing;   // drop deleted files from the shuffle history/cycle

  if not ActiveDeleted then
    Exit;

  FirstNode := ListData.GetFirst;

  if not Assigned(FirstNode) then
  begin
    FrmKPlayer.HandleStop;
    Exit;
  end;

  FirstItem := ListData.GetNodeData(FirstNode);
  Play(FirstItem^.FileName);
end;

procedure TFrmList.SetRepeat;
begin
  FrmKPlayer.RepeatMode := (FrmKPlayer.RepeatMode + 1) mod 3;
  UpdateButtonColor(BtnRepeat, True);
end;

procedure TFrmList.SetRandom;
begin
  FrmKPlayer.RandomMode := 1 - FrmKPlayer.RandomMode;
  ResetShuffle;   // start a fresh no-repeat cycle (seeds the currently playing track)
  UpdateButtonColor(BtnRandom, True);
end;

procedure TFrmList.Play(AFileName: string);
var
  ActiveNode: PVirtualNode;
  Node: PVirtualNode;
  Item: PItemData;
begin
  if (AFileName = '') then
  begin
    ActiveNode := FindActiveNode;
    if Assigned(ActiveNode) then
      FrmKPlayer.HandlePause
    else
      Next;

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
    // Move back through the actual shuffle play order
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

// Random track from the playlist that has not been played this cycle
// (and is not the one currently playing). '' when nothing is left.
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

// Begin a fresh no-repeat cycle, seeding the currently playing track as "played"
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

// Drop history/cycle entries whose file is no longer in the playlist
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

  // If we previously navigated back with Prev, walk forward through history first
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
    // Every track has been played once -> cycle complete
    if FrmKPlayer.RepeatMode = 1 then
    begin
      // Repeat-all: reshuffle for a new cycle (avoid immediately repeating current)
      FCyclePlayed.Clear;
      if Cur <> '' then
        FCyclePlayed.Add(Cur);
      Pick := PickRandomUnplayed;
      // Single-track playlist: allow replaying the only track
      if (Pick = '') and (Cur <> '') then
        Pick := Cur;
    end;
  end;

  if Pick = '' then
  begin
    // Repeat off (or nothing else to play) -> stop after the full cycle
    FrmKPlayer.HandleStop;
    Exit;
  end;

  FCyclePlayed.Add(Pick);
  AppendShuffleHistory(Pick);
  Play(Pick);
end;

procedure TFrmList.Stop;
var
  ActiveNode: PVirtualNode;
  FirstNode: PVirtualNode;
  NextNode: PVirtualNode;
  Item: PItemData;
begin
  ActiveNode := FindActiveNode;

  // Repeat current track: applies regardless of random
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

  // Random: Rand handles no-repeat (stop at cycle end) and repeat-all (reshuffle)
  if FrmKPlayer.RandomMode = 1 then
  begin
    Rand;
    Exit;
  end;

  // Linear playback
  case FrmKPlayer.RepeatMode of
    0: // No repeat
    begin
      Next;
      Exit;
    end;

    1: // Repeat all videos
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

      FirstNode := ListData.GetFirst;
      if Assigned(FirstNode) then
      begin
        Item := ListData.GetNodeData(FirstNode);
        if Assigned(Item) then
          Play(Item^.FileName);
      end;
    end;
  end;
end;

end.
