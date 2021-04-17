unit rTreeView;

interface

uses
  Classes, ComCtrls;

type
  TNodeType  = (ntEmpty, ntRoot, ntGroup, ntItem, ntSubItem, ntULevel1, ntULevel2, ntULevel3);
  TSortMode  = (stNone, stTypeId, stTypeName, stRecordId, stRecordName);
  TGotoMode  = (gtNoChangeSelection, gtClearSelection, gtSelectTopNode);
  TAExpMode  = (emNone, emRoot, emGroups, emAll);

  TNodeTypes = set of TNodeType;

  TNodeData  = ^RNodeData;
  RNodeData  = record
    NodeType: TNodeType;
    RecordId: Integer;
  end;

  TrTreeView = class (TTreeView)
  private
    fListRootOnly: Boolean;
    fListEmpty: string;
    fListDelim: Char;
    fSortType: TSortMode;
    fAExpMode: TAExpMode;
    fUserOnChange: TTVChangedEvent;
    procedure ExpandRoot;
    procedure ExpandGroups;
    procedure SetSortType(const Value: TSortMode);
  public
    constructor Create(AOwner: TComponent); override;
    function CreateTypeNode(Parent: TTreeNode; const NodeType: TNodeType;
      const RecordId, NormalImage, SelectedImage: Integer; const NodeText: string): TTreeNode;
    function GetNodeId(Node: TTreeNode): Integer;
    function GetNodeIndex(Node: TTreeNode): Integer;
    function GetNodeImage(Node: TTreeNode): Integer;
    function GetNodeKey(Node: TTreeNode): RNodeData;
    function GetNodeType(Node: TTreeNode): TNodeType;
    function GetNodePath(Node: TTreeNode; const DelimChar: Char = '\'): string;
    function GetIdList(RootNode: TTreeNode; Types: TNodeTypes): string;
    function FindNode(const Types: TNodeTypes; const RecordId: Integer): TTreeNode; overload;
    function FindNode(const Index: Integer): TTreeNode; overload;
    function FindNode(const Text: string): TTreeNode; overload;
    function FindNodePart(const Text: string): TTreeNode;
    function FindSubNode(RootNode: TTreeNode; const Types: TNodeTypes; const RecordId: Integer): TTreeNode; overload;
    function GotoNode(const Types: TNodeTypes; const RecordId: Integer; const IfEmpty: TGotoMode): Boolean; overload;
    function GotoNode(const Index: Integer; const IfEmpty: TGotoMode): Boolean; overload;
    function CheckNodeParent(Node, Parent: TTreeNode): Boolean;
    procedure Sort(SortMode: TSortMode); overload;
    procedure Sort; overload;
    procedure AutoExpand(AExpMode: TAExpMode); overload;
    procedure AutoExpand; overload;
    procedure UpdateNodeKey(Node: TTreeNode; const NodeType: TNodeType; const RecordId: Integer);
    procedure UpdateNodeType(Node: TTreeNode; const NodeType: TNodeType);
    procedure UpdateNodeId(Node: TTreeNode; const RecordId: Integer);
    procedure UpdateNodeImages(Node: TTreeNode; const NormalImage, SelectedImage: Integer);
    procedure UpdateNodeText(Node: TTreeNode; const NodeText: string);
    procedure DeleteSelection;
    procedure OnChangeEvent_Block;
    procedure OnChangeEvent_Unblock;
  protected
    procedure Delete(Node: TTreeNode); override;
  published
    property SortType: TSortMode read fSortType write SetSortType default stTypeName;
    property AutoExpandMode: TAExpMode read fAExpMode write fAExpMode default emRoot;
    property ListRootOnly: Boolean read fListRootOnly write fListRootOnly default False;
    property ListEmptyValue: string read fListEmpty write fListEmpty;
    property ListDelimChar: Char read fListDelim write fListDelim;
  end;

const
  DefaultSelectedNodes = [ntGroup, ntItem];

implementation

uses
  SysUtils, Themes, RVclUtils, StrUtils;

{ TrTreeView }

constructor TrTreeView.Create(AOwner: TComponent);
begin
  inherited;
  fSortType := stTypeName;
  fAExpMode := emRoot;
  fUserOnChange := nil;
  fListDelim := ',';
  fListEmpty := '-1';
  fListRootOnly := False;
end;

procedure TrTreeView.SetSortType(const Value: TSortMode);
begin
  if Value <> fSortType then
  begin
    fSortType := Value;
    if Items.Count > 0 then Sort(fSortType);
  end;
end;

function TrTreeView.CreateTypeNode(Parent: TTreeNode;
  const NodeType: TNodeType; const RecordId, NormalImage,
  SelectedImage: Integer; const NodeText: string): TTreeNode;
var
  NodeKey: TNodeData;
begin
  if Assigned(Parent)
  then Result := Items.AddChild(Parent, NodeText)
  else Result := Items.Add(nil, NodeText);
  if Assigned(Result) then
  begin
    Result.ImageIndex := NormalImage;
    Result.SelectedIndex := SelectedImage;
    New(NodeKey);
    NodeKey^.NodeType := NodeType;
    NodeKey^.RecordId := RecordId;
    Result.Data := NodeKey;
  end;
end;

function TrTreeView.FindNode(const Types: TNodeTypes;
  const RecordId: Integer): TTreeNode;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
    if (Items[i].Data <> nil)
    and (TNodeData(Items[i].Data)^.NodeType in Types)
    and (TNodeData(Items[i].Data)^.RecordId = RecordId) then
    begin
      Result := Items[i];
      Break;
    end;
end;

function TrTreeView.FindNode(const Index: Integer): TTreeNode;
begin
  Result := nil;
  if (Index >= 0) and (Index < Items.Count) then
    Result := Items[Index];
end;

function TrTreeView.FindNode(const Text: string): TTreeNode;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
    if SameText(Items[i].Text, Text) then
    begin
      Result := Items[i];
      Break;
    end;
end;

function TrTreeView.FindNodePart(const Text: string): TTreeNode;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
    if AnsiContainsText(Items[i].Text, Text) then
    begin
      Result := Items[i];
      Break;
    end;
end;

function TrTreeView.FindSubNode(RootNode: TTreeNode; const Types: TNodeTypes; const RecordId: Integer): TTreeNode;
var
  Chld: TTreeNode;
begin
  Result := nil;
  if RootNode <> nil then
  begin
    Chld := RootNode.GetFirstChild;
    while (Result = nil) and (Chld <> nil) do
    begin
      if (Chld.Data <> nil)
      and (TNodeData(Chld.Data)^.NodeType in Types)
      and (TNodeData(Chld.Data)^.RecordId = RecordId)
      then Result := Chld
      else FindSubNode(Chld, Types, RecordId);
      Chld := RootNode.GetNextChild(Chld);
    end;
  end;
end;

function TrTreeView.GetNodeId(Node: TTreeNode): Integer;
begin
  Result := intDisable;
  if (Node <> nil) and (Node.Data <> nil) then
    Result := TNodeData(Node.Data)^.RecordId;
end;

function TrTreeView.GetNodeImage(Node: TTreeNode): Integer;
begin
  Result := intDisable;
  if Node <> nil then
    Result := Node.ImageIndex;
end;

function TrTreeView.GetNodeIndex(Node: TTreeNode): Integer;
begin
  Result := intDisable;
  if Node <> nil then
    Result := Node.AbsoluteIndex;
end;

function TrTreeView.GetNodeKey(Node: TTreeNode): RNodeData;
begin
  Result.NodeType := ntEmpty;
  Result.RecordId := intDisable;
  if (Node <> nil) and (Node.Data <> nil) then
    Result := TNodeData(Node.Data)^;
end;

function TrTreeView.GetNodeType(Node: TTreeNode): TNodeType;
begin
  Result := ntEmpty;
  if (Node <> nil) and (Node.Data <> nil) then
    Result := TNodeData(Node.Data)^.NodeType;
end;

function TrTreeView.GotoNode(const Types: TNodeTypes;
  const RecordId: Integer; const IfEmpty: TGotoMode): Boolean;
var
  Node: TTreeNode;
begin
  Result := False;
  Node := FindNode(Types, RecordId);
  if Node = nil then
    case IfEmpty of
      gtClearSelection: Selected := nil;
      gtSelectTopNode: Selected := TopItem;
    end
  else Selected := Node;
end;

function TrTreeView.GotoNode(const Index: Integer; const IfEmpty: TGotoMode): Boolean;
var
  Node: TTreeNode;
begin
  Result := False;
  Node := FindNode(Index);
  if Node = nil then
    case IfEmpty of
      gtClearSelection: Selected := nil;
      gtSelectTopNode: Selected := TopItem;
    end
  else Selected := Node;
end;

procedure TrTreeView.Sort(SortMode: TSortMode);

  function RTVSortProc(Node1, Node2: TTreeNode; Data: Integer): Integer; stdcall;
  var
    NodeKey1, NodeKey2: TNodeData;
  begin
    Result := 0;
    NodeKey1 := Node1.Data;
    NodeKey2 := Node2.Data;
    if (NodeKey1 <> nil) and (NodeKey2 <> nil) then
    begin
      case TSortMode(Data) of
        stNone: Result := 0;
        stRecordId: Result := NodeKey1^.RecordId - NodeKey2^.RecordId;
        stRecordName: Result := AnsiCompareStr(Node1.Text, Node2.Text);
        stTypeId:
        begin
          Result := Integer(NodeKey1^.NodeType) - Integer(NodeKey2^.NodeType);
          if Result = 0 then Result := NodeKey1^.RecordId - NodeKey2^.RecordId;
        end;
        stTypeName:
        begin
          Result := Integer(NodeKey1^.NodeType) - Integer(NodeKey2^.NodeType);
          if Result = 0 then Result := AnsiCompareStr(Node1.Text, Node2.Text);
        end;
      end;
    end
  end;

begin
  CustomSort(@RTVSortProc, Integer(SortMode));
end;

procedure TrTreeView.Sort;
begin
  Sort(fSortType);
end;

procedure TrTreeView.OnChangeEvent_Block;
begin
  if Assigned(OnChange) then
  begin
    fUserOnChange := OnChange;
    OnChange := nil;
  end;
end;

procedure TrTreeView.OnChangeEvent_Unblock;
begin
  if Assigned(fUserOnChange) then
  begin
    OnChange := fUserOnChange;
    fUserOnChange := nil;
  end;
end;

function TrTreeView.GetIdList(RootNode: TTreeNode; Types: TNodeTypes): string;

  procedure ProcessNode(Node: TTreeNode; const RootOnly: Boolean);
  var
    Chld: TTreeNode;
  begin
    if (Node <> nil) and (Node.Data <> nil) then
    begin
      if TNodeData(Node.Data)^.NodeType in Types then
      begin
        Result := Result + fListDelim + IntToStr(TNodeData(Node.Data)^.RecordId);
        if RootOnly then Exit;
      end;
      Chld := Node.GetFirstChild;
      while Chld <> nil do
      begin
        ProcessNode(Chld, False);
        Chld := Node.GetNextChild(Chld);
      end;
    end;
  end;

begin
  Result := EmptyStr;
  ProcessNode(RootNode, fListRootOnly);
  if Result = EmptyStr
  then Result := fListEmpty
  else System.Delete(Result, 1, 1);
end;

function TrTreeView.CheckNodeParent(Node, Parent: TTreeNode): Boolean;
var
  OwnNode: TTreeNode;
begin
  Result := Parent = Node;
  OwnNode := Node.Parent;
  while not Result and Assigned(OwnNode) do
  begin
    Result := OwnNode = Parent;
    OwnNode := OwnNode.Parent;
  end;
end;

function TrTreeView.GetNodePath(Node: TTreeNode; const DelimChar: Char = '\'): string;
var
  OwnNode: TTreeNode;
begin
  if Assigned(Node) then
  begin
    Result := Node.Text;
    OwnNode := Node.Parent;
    while Assigned(OwnNode) do
    begin
      Result := OwnNode.Text + DelimChar + Result;
      OwnNode := OwnNode.Parent;
    end;
  end
  else Result := EmptyStr;
end;

procedure TrTreeView.ExpandRoot;
var
  RootNode: TTreeNode;
begin
  RootNode := Items.GetFirstNode;
  while RootNode <> nil do
  begin
    RootNode.Expand(False);
    RootNode := RootNode.GetNextSibling;
  end;
end;

procedure TrTreeView.ExpandGroups;

  procedure ExpandNode(Node: TTreeNode);
  var
    Chld: TTreeNode;
  begin
    if (Node.Data <> nil)
    and (TNodeData(Node.Data).NodeType in [ntRoot, ntGroup]) then
    begin
      Node.Expand(False);
      Chld := Node.GetFirstChild;
      while Chld <> nil do
      begin
        ExpandNode(Chld);
        Chld := Node.GetNextChild(Chld);
      end;
    end;
  end;

var
  RootNode: TTreeNode;
begin
  RootNode := Items.GetFirstNode;
  while RootNode <> nil do
  begin
    ExpandNode(RootNode);
    RootNode := RootNode.GetNextSibling;
  end;
end;

procedure TrTreeView.AutoExpand(AExpMode: TAExpMode);
begin
  case AExpMode of
    emRoot: ExpandRoot;
    emGroups: ExpandGroups;
    emAll: FullExpand;
  end;
end;

procedure TrTreeView.AutoExpand;
begin
  AutoExpand(fAExpMode);
end;

procedure TrTreeView.UpdateNodeId(Node: TTreeNode; const RecordId: Integer);
begin
  if (Node <> nil) and (Node.Data <> nil) then
    TNodeData(Node.Data)^.RecordId := RecordId;
end;

procedure TrTreeView.UpdateNodeImages(Node: TTreeNode; const NormalImage, SelectedImage: Integer);
begin
  if Node <> nil then
  begin
    Node.ImageIndex := NormalImage;
    Node.SelectedIndex := SelectedImage;
  end;
end;

procedure TrTreeView.UpdateNodeKey(Node: TTreeNode; const NodeType: TNodeType; const RecordId: Integer);
begin
  if (Node <> nil) and (Node.Data <> nil) then
  begin
    TNodeData(Node.Data)^.NodeType := NodeType;
    TNodeData(Node.Data)^.RecordId := RecordId;
  end;
end;

procedure TrTreeView.UpdateNodeText(Node: TTreeNode; const NodeText: string);
begin
  if Node <> nil then
    Node.Text := NodeText;
end;

procedure TrTreeView.UpdateNodeType(Node: TTreeNode; const NodeType: TNodeType);
begin
  if (Node <> nil) and (Node.Data <> nil) then
    TNodeData(Node.Data)^.NodeType := NodeType;
end;

procedure TrTreeView.DeleteSelection;
var
  NextSelected: TTreeNode;
begin
  Items.BeginUpdate;
  try
    NextSelected := FindNextToSelect;
    Selected.Delete;
    Selected := NextSelected;
  finally
    Items.EndUpdate;
  end;
end;

procedure TrTreeView.Delete(Node: TTreeNode);
var
  NodeData: TNodeData;
begin
  inherited Delete(Node);
  if Node.Data <> nil then
  begin
    NodeData := Node.Data;
    Node.Data := nil;
    Dispose(NodeData);
  end;
end;

end.

