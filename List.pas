unit List;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.Dwmapi, Winapi.UxTheme,
  System.SysUtils, System.Variants, System.Classes, System.IOUtils, System.StrUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.FileCtrl,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL, VirtualTrees.Types,
  VirtualTrees,
  K.DragFile,
  VTScrollbar, SVGIconImage, System.ImageList, Vcl.ImgList,
  SVGIconImageListBase, SVGIconImageList, Vcl.Menus;

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
    procedure ListDataMeasureItem(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; var NodeHeight: TDimension);
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
    FDragStart: TPoint;
    FSavedSelection: TArray<PVirtualNode>;
  
    function FindActiveNode: PVirtualNode;
    procedure UpdateButtonColor(Btn: TSVGIconImage; Hover: Boolean);
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

uses Main;

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
  ListData.TreeOptions.MiscOptions := ListData.TreeOptions.MiscOptions + [toReportMode, toVariableNodeHeight, toWheelPanning] - [toAcceptOLEDrop];

  ListData.Color := COLOR_BG_MAIN;
  ListData.Font.Color := COLOR_TEXT_NORMAL;
  ListData.Colors.SelectionTextColor := COLOR_TEXT_SELECTED;
  ListData.Colors.FocusedSelectionColor := COLOR_SELECT_FOCUSED;
  ListData.Colors.FocusedSelectionBorderColor := COLOR_SELECT_FOCUSED;
  ListData.Colors.UnfocusedSelectionColor := COLOR_SELECT_UNFOCUSED;
  ListData.Colors.UnfocusedSelectionBorderColor := COLOR_SELECT_UNFOCUSED;

  // Helpers
  FDarkSB := TVTDarkScrollbar.Create(ListData);

  TDragFile.Create(ListData,
  procedure(const Files: TArray<string>)
  begin
    for var S in Files do
      FrmList.AddFile(S);
  end);
end;

procedure TFrmList.FormDestroy(Sender: TObject);
begin
  FDarkSB.Free;
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

procedure TFrmList.ListDataMeasureItem(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; var NodeHeight: TDimension);
begin
  if NodeHeight <> ScaleValue(24) then
    NodeHeight := ScaleValue(24);
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

procedure TFrmList.AddFile(AFileName: string);
const
  SupportedExt: array[0..6] of string =
    ('.mp3', '.mp4', '.avi', '.mkv', '.asf', '.mov', '.wmv');
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

  if IndexText(TPath.GetExtension(AFileName), SupportedExt) < 0 then
    Exit;

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
    ListData.ScrollIntoView(ListData.FocusedNode, False);
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
    Rand;
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

procedure TFrmList.Rand;
var
  Node: PVirtualNode;
  Item: PItemData;
  Count: Integer;
  Pick: Integer;
  I: Integer;
begin
  Count := ListData.RootNodeCount;
  if Count = 0 then
    Exit;

  Pick := Random(Count);

  Node := ListData.GetFirst;
  for I := 1 to Pick do
    Node := ListData.GetNext(Node);

  Item := ListData.GetNodeData(Node);
  if Assigned(Item) then
    Play(Item^.FileName);
end;

procedure TFrmList.Stop;
var
  ActiveNode: PVirtualNode;
  FirstNode: PVirtualNode;
  NextNode: PVirtualNode;
  Item: PItemData;
begin
  ActiveNode := FindActiveNode;

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

    2: // Repeat current video
    begin
      if Assigned(ActiveNode) then
      begin
        Item := ListData.GetNodeData(ActiveNode);
        if Assigned(Item) then
          Play(Item^.FileName);
      end;
    end;
  end;
end;

end.
