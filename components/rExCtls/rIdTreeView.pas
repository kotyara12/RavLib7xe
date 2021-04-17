unit rIdTreeView;

interface

uses
  Classes, ComCtrls, RVclUtils;

type
  TRGotoNodeMode = (gmNoChangeSelection, gmClearSelection, gmSelectTopItem, gmRaiseException);

  TrIDTreeView = class (TTreeView)
  private
    FSortOnlyData: Boolean;
    FListDelimiter: Char;
    FListEmptyValue: string;
    FExtOnChange: TTVChangedEvent;
  public
    constructor Create(AOwner: TComponent); override;
    function GetNodeId(Node: TTreeNode): Integer;
    function GetNodeAbsIndex(Node: TTreeNode): Integer;
    function GetNodeImageIndex(Node: TTreeNode): Integer;
    procedure DeleteSelectedNode; // ver 1.4.0.17
    function GetSelectedId: Integer;
    function GetSelectedAbsIndex: Integer;
    function GetSelectedImageIndex: Integer;
    function FindNodeId(const AId: Integer): TTreeNode;
    function FindNodeIdImages(const AId: Integer; const AImages: TByteSet): TTreeNode;
    function FindNodeAbsIndex(const AIndex: Integer): TTreeNode;
    function FindSubNodeId(Node: TTreeNode; const AId: Integer): TTreeNode;
    function FindSubNodeIdImages(Node: TTreeNode; const AId: Integer; const AImages: TByteSet): TTreeNode;
    procedure GoToNodeId(const Mode: TRGotoNodeMode; const AId: Integer);
    procedure GoToNodeIdImages(const Mode: TRGotoNodeMode; const AId: Integer; const AImages: TByteSet);
    procedure GoToNodeAbsIndex(const Mode: TRGotoNodeMode; const AIndex: Integer);
    function CheckNodeOwner(Node, Owner: TTreeNode): Boolean; // ver. 1.2.0.14
    function GetNodePath(Node: TTreeNode): string; // ver 2.5.0.79
    function GetNodeIdList(Node: TTreeNode): string;
    function GetNodeIdListImages(Node: TTreeNode; const AImages: TByteSet): string;
    function GetSelectedIdList: string;
    function GetSelectedIdListImages(const AImages: TByteSet): string;
    function AddFirstNode(const AId, AImageIndex, ASelectedIndex: Integer;
      const AText: string): TTreeNode;
    function AddChildNode(OwnerNode: TTreeNode;
      const AId, AImageIndex, ASelectedIndex: Integer;
      const AText: string): TTreeNode;
    procedure UpdateNodeId(Node: TTreeNode; const AId: Integer);
    procedure UpdateNodeText(Node: TTreeNode; const AText: string);
    procedure DataSortOnId;
    procedure Sort;
    procedure DisableOnChange;
    procedure RestoreOnChange;
  protected
    procedure Delete(Node: TTreeNode); override;
  published
    property SortDataOnlyId: Boolean read FSortOnlyData write FSortOnlyData default False;
    property ListDelimiter: Char read FListDelimiter write FListDelimiter default ',';
    property ListEmptyValue: string read FListEmptyValue write FListEmptyValue;
  end;

  TrKindIDTreeView = class (TTreeView)
  private
    FSortOnlyData: Boolean;
    FListDelimiter: Char;
    FListEmptyValue: string;
    FExtOnChange: TTVChangedEvent;
  public
    constructor Create(AOwner: TComponent); override;
    function GetNodeId(Node: TTreeNode): RKindId;
    function GetNodeAbsIndex(Node: TTreeNode): Integer;
    function GetNodeImageIndex(Node: TTreeNode): Integer;
    procedure DeleteSelectedNode; // ver 1.4.0.17
    function GetSelectedId: RKindId;
    function GetSelectedAbsIndex: Integer;
    function GetSelectedImageIndex: Integer;
    function FindNodeId(const AId: RKindId): TTreeNode; overload;
    function FindNodeId(const AId, AKind: Integer): TTreeNode; overload;
    function FindNodeIdKinds(const AId: Integer; const AKinds: array of Integer): TTreeNode;
    function FindNodeIdImages(const AId: RKindId; const AImages: TByteSet): TTreeNode;
    function FindNodeAbsIndex(const AIndex: Integer): TTreeNode;
    function FindSubNodeId(Node: TTreeNode; const AId: RKindId): TTreeNode; overload;
    function FindSubNodeId(Node: TTreeNode; const AId, AKind: Integer): TTreeNode; overload;
    function FindSubNodeIdKinds(Node: TTreeNode; const AId: Integer; const AKinds: array of Integer): TTreeNode;
    function FindSubNodeIdImages(Node: TTreeNode; const AId: RKindId; const AImages: TByteSet): TTreeNode;
    procedure GoToNodeId(const Mode: TRGotoNodeMode; const AId: RKindId); overload;
    procedure GoToNodeId(const Mode: TRGotoNodeMode; const AId, AKind: Integer); overload;
    procedure GoToNodeIdKinds(const Mode: TRGotoNodeMode; const AId: Integer; const AKinds: array of Integer);
    procedure GoToNodeIdImages(const Mode: TRGotoNodeMode; const AId: RKindId; const AImages: TByteSet);
    procedure GoToNodeAbsIndex(const Mode: TRGotoNodeMode; const AIndex: Integer);
    function CheckNodeOwner(Node, Owner: TTreeNode): Boolean; // ver. 1.2.0.14
    function GetNodeIdList(Node: TTreeNode): string;
    function GetNodeIdListKinds(Node: TTreeNode; const AKinds: array of Integer): string;
    function GetNodeIdListImages(Node: TTreeNode; const AImages: TByteSet): string;
    function GetSelectedIdList: string;
    function GetSelectedIdListKinds(const AKinds: array of Integer): string;
    function GetSelectedIdListImages(const AImages: TByteSet): string;
    function AddFirstNode(const AId: RKindId; const AImageIndex, ASelectedIndex: Integer;
      const AText: string): TTreeNode; overload;
    function AddChildNode(OwnerNode: TTreeNode;
      const AId: RKindId; const AImageIndex, ASelectedIndex: Integer;
      const AText: string): TTreeNode; overload;
    function AddFirstNode(const AId, AKind, AImageIndex, ASelectedIndex: Integer;
      const AText: string): TTreeNode; overload;
    function AddChildNode(OwnerNode: TTreeNode;
      const AId, AKind, AImageIndex, ASelectedIndex: Integer;
      const AText: string): TTreeNode; overload;
    procedure UpdateNodeId(Node: TTreeNode; const AId: RKindId); overload;
    procedure UpdateNodeId(Node: TTreeNode; const AId, AKind: Integer); overload;
    procedure UpdateNodeText(Node: TTreeNode; const AText: string);
    procedure DataSortOnId;
    procedure Sort;
    procedure DisableOnChange;
    procedure RestoreOnChange;
  protected
    procedure Delete(Node: TTreeNode); override;
  published
    property SortDataOnlyId: Boolean read FSortOnlyData write FSortOnlyData default False;
    property ListDelimiter: Char read FListDelimiter write FListDelimiter default ',';
    property ListEmptyValue: string read FListEmptyValue write FListEmptyValue;
  end;

implementation

uses
  Themes, SysUtils;

resourcestring
  SGotoNodeNotFound = 'Ошибка перемещения: элемент с индексом [%d] не найден в структуре данных!';

{ == TrIDTreeView ================================================================ }
constructor TrIDTreeView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ReadOnly := True;
  HideSelection := False;
  RowSelect := True;
  FSortOnlyData := False;
  FListDelimiter := ',';
  FListEmptyValue := '-1';
  FExtOnChange := nil;
end;

// Отключение и воостановление обработчика события OnChange --------------------
procedure TrIDTreeView.DisableOnChange;
begin
  if Assigned(OnChange) then
  begin
    FExtOnChange := OnChange;
    OnChange := nil;
  end;
end;

procedure TrIDTreeView.RestoreOnChange;
begin
  if Assigned(FExtOnChange) then
  begin
    OnChange := FExtOnChange;
    FExtOnChange := nil;
  end;
end;

// Сортировка ------------------------------------------------------------------
procedure TrIDTreeView.DataSortOnId;

  function DataSortProc(Node1, Node2: TTreeNode; Data: Integer): Integer; stdcall;
  var
    Id1, Id2: TId;
  begin
    Id1 := TId(Node1.Data);
    Id2 := TId(Node2.Data);
    if TrIDTreeView(Node1.TreeView).SortDataOnlyId or (Node1.ImageIndex = Node2.ImageIndex) then
    begin
      if Assigned(Id1) and Assigned(Id2)
      then Result := Id1^ - Id2^
      else Result := 0;
    end
    else Result := Node1.ImageIndex - Node2.ImageIndex;
  end;

begin
  CustomSort(@DataSortProc, 0);
end;

procedure TrIDTreeView.Sort;
begin
  case SortType of
    stData: DataSortOnId;
    stText: AlphaSort;
  end;
end;

// Получение идентификаторов ---------------------------------------------------
function TrIDTreeView.GetNodeId(Node: TTreeNode): Integer;
begin
  Result := -1;
  if Assigned(Node) and Assigned(Node.Data) then
    Result := TId(Node.Data)^;
end;

function TrIDTreeView.GetNodeAbsIndex(Node: TTreeNode): Integer;
begin
  Result := -1;
  if Assigned(Node) then
    Result := Node.AbsoluteIndex;
end;

function TrIDTreeView.GetNodeImageIndex(Node: TTreeNode): Integer;
begin
  Result := -1;
  if Assigned(Node) then
    Result := Node.ImageIndex;
end;

function TrIDTreeView.GetSelectedId: Integer;
begin
  Result := GetNodeId(Self.Selected);
end;

function TrIDTreeView.GetSelectedAbsIndex: Integer;
begin
  Result := GetNodeAbsIndex(Self.Selected);
end;

function TrIDTreeView.GetSelectedImageIndex: Integer;
begin
  Result := GetNodeImageIndex(Self.Selected);
end;

// Удаление элемента с переносом выделения на другой ---------------------------
procedure TrIDTreeView.DeleteSelectedNode; // ver 1.4.0.17
var
  VisNode, DelNode: TTreeNode;
begin
  if Assigned(Selected) then
  begin
    DelNode := Selected;
    VisNode := DelNode.GetPrevVisible;
    if not Assigned(VisNode) then VisNode := DelNode.GetNextVisible;
    if not Assigned(VisNode) then VisNode := TopItem;
    Selected := VisNode;
    Items.Delete(DelNode);
  end;
end;

// Поиск элемента --------------------------------------------------------------
function TrIDTreeView.FindNodeId(const AId: Integer): TTreeNode;
var
  i: Integer;
  Node: TTreeNode;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
  begin
    Node := Items[i];
    if Assigned(Node.Data) and (TId(Node.Data)^ = AId) then
    begin
      Result := Node;
      Break;
    end;
  end;
end;

function TrIDTreeView.FindNodeIdImages(const AId: Integer; const AImages: TByteSet): TTreeNode;
var
  i: Integer;
  Node: TTreeNode;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
  begin
    Node := Items[i];
    if Assigned(Node.Data) and (TId(Node.Data)^ = AId)
    and (Node.ImageIndex in AImages) then
    begin
      Result := Node;
      Break;
    end;
  end;
end;

function TrIDTreeView.FindNodeAbsIndex(const AIndex: Integer): TTreeNode;
begin
  if AIndex > -1 then
  begin
    if AIndex < Items.Count
    then Result := Items[AIndex]
    else Result := Items[Items.Count - 1];
  end
  else Result := nil;
end;

// Поиск подэлемента -----------------------------------------------------------
function TrIDTreeView.FindSubNodeId(Node: TTreeNode; const AId: Integer): TTreeNode;
var
  ChNode: TTreeNode;
begin
  Result := nil;
  ChNode := Node.GetFirstChild;
  while Assigned(ChNode) and not Assigned(Result) do
  begin
    if Assigned(ChNode.Data) and (TId(ChNode.Data)^ = AId)
    then Result := ChNode
    else begin
      Result := FindSubNodeId(ChNode, AId);
      ChNode := Node.GetNextChild(ChNode);
    end;
  end;
end;

function TrIDTreeView.FindSubNodeIdImages(Node: TTreeNode; const AId: Integer;
  const AImages: TByteSet): TTreeNode;
var
  ChNode: TTreeNode;
begin
  Result := nil;
  ChNode := Node.GetFirstChild;
  while Assigned(ChNode) and not Assigned(Result) do
  begin
    if Assigned(ChNode.Data) and (TId(ChNode.Data)^ = AId)
    and (ChNode.ImageIndex in AImages)
    then Result := ChNode
    else begin
      Result := FindSubNodeIdImages(ChNode, AId, AImages);
      ChNode := Node.GetNextChild(ChNode);
    end;
  end;
end;

// Перемещение по индексу или ID -----------------------------------------------
procedure TrIDTreeView.GoToNodeId(const Mode: TRGotoNodeMode; const AId: Integer);
var
  Node: TTreeNode;
begin
  Node := FindNodeId(AId);
  if Assigned(Node) then Selected := Node
  else begin
    case Mode of
      gmClearSelection: Selected := nil;
      gmSelectTopItem: Selected := TopItem;
      gmRaiseException: raise Exception.CreateFmt(SGotoNodeNotFound, [AId]);
    end;
  end;
end;

procedure TrIDTreeView.GoToNodeIdImages(const Mode: TRGotoNodeMode; const AId: Integer; const AImages: TByteSet);
var
  Node: TTreeNode;
begin
  Node := FindNodeIdImages(AId, AImages);
  if Assigned(Node) then Selected := Node
  else begin
    case Mode of
      gmClearSelection: Selected := nil;
      gmSelectTopItem: Selected := TopItem;
      gmRaiseException: raise Exception.CreateFmt(SGotoNodeNotFound, [AId]);
    end;
  end;
end;

procedure TrIDTreeView.GoToNodeAbsIndex(const Mode: TRGotoNodeMode; const AIndex: Integer);
var
  Node: TTreeNode;
begin
  Node := FindNodeAbsIndex(AIndex);
  if Assigned(Node) then Selected := Node
  else begin
    case Mode of
      gmClearSelection: Selected := nil;
      gmSelectTopItem: Selected := TopItem;
      gmRaiseException: raise Exception.CreateFmt(SGotoNodeNotFound, [AIndex]);
    end;
  end;
end;

// Проверка, является ли Owner владельцем (прямым или косвенным) для Node ------
function TrIDTreeView.CheckNodeOwner(Node, Owner: TTreeNode): Boolean;
var
  OwnNode: TTreeNode;
begin
  Result := Owner = Node;
  OwnNode := Node.Parent;
  while not Result and Assigned(OwnNode) do
  begin
    Result := OwnNode = Owner;
    OwnNode := OwnNode.Parent;
  end;
end;

// Генерация пути к текущей ноде -----------------------------------------------
function TrIDTreeView.GetNodePath(Node: TTreeNode): string; // ver 2.5.0.79
var
  ParentNode: TTreeNode;
begin
  if Assigned(Node) then
  begin
    Result := Node.Text;
    ParentNode := Node.Parent;
    while Assigned(ParentNode) do
    begin
      Result := ParentNode.Text + '\' + Result;
      ParentNode := ParentNode.Parent;
    end;
  end
  else Result := EmptyStr;
end;

// Генерация списка ID ---------------------------------------------------------
function TrIDTreeView.GetNodeIdList(Node: TTreeNode): string;

  procedure AddNodeId(Node: TTreeNode);
  var
    ChildNode: TTreeNode;
  begin
    if Assigned(Node.Data) and (TId(Node.Data)^ > -1) then
      Result := Result + FListDelimiter + IntToStr(TId(Node.Data)^);
    ChildNode := Node.GetFirstChild;
    while Assigned(ChildNode) do
    begin
      AddNodeId(ChildNode);
      ChildNode := Node.GetNextChild(ChildNode);
    end;
  end;

begin
  Result := EmptyStr;
  if Assigned(Node) then AddNodeId(Node);
  if Result = EmptyStr then Result := FListEmptyValue
  else System.Delete(Result, 1, 1);
end;

function TrIDTreeView.GetNodeIdListImages(Node: TTreeNode; const AImages: TByteSet): string;

  procedure AddNodeId(Node: TTreeNode);
  var
    ChildNode: TTreeNode;
  begin
    if Assigned(Node.Data) and (TId(Node.Data)^ > -1)
    and (Node.ImageIndex in AImages) then
      Result := Result + FListDelimiter + IntToStr(TId(Node.Data)^);
    ChildNode := Node.GetFirstChild;
    while Assigned(ChildNode) do
    begin
      AddNodeId(ChildNode);
      ChildNode := Node.GetNextChild(ChildNode);
    end;
  end;

begin
  Result := EmptyStr;
  if Assigned(Node) then AddNodeId(Node);
  if Result = EmptyStr then Result := FListEmptyValue
  else System.Delete(Result, 1, 1);
end;

function TrIDTreeView.GetSelectedIdList: string;
begin
  Result := GetNodeIdList(Self.Selected);
end;

function TrIDTreeView.GetSelectedIdListImages(const AImages: TByteSet): string;
begin
  Result := GetNodeIdListImages(Self.Selected, AImages);
end;

// Добавление ------------------------------------------------------------------
function TrIDTreeView.AddFirstNode(const AId, AImageIndex, ASelectedIndex: Integer;
  const AText: string): TTreeNode;
var
  Id: TId;
begin
  Result := nil;
  try
    Result := Self.Items.Add(nil, AText);
    Result.ImageIndex := AImageIndex;
    Result.SelectedIndex := ASelectedIndex;
    New(Id);
    Id^ := AId;
    Result.Data := Id;
  except
    if Assigned(Result) then Self.Delete(Result);
    raise;
  end;
end;

function TrIDTreeView.AddChildNode(OwnerNode: TTreeNode;
  const AId, AImageIndex, ASelectedIndex: Integer;
  const AText: string): TTreeNode;
var
  Id: TId;
begin
  Result := nil;
  try
    Result := Self.Items.AddChild(OwnerNode, AText);
    Result.ImageIndex := AImageIndex;
    Result.SelectedIndex := ASelectedIndex;
    New(Id);
    Id^ := AId;
    Result.Data := Id;
  except
    if Assigned(Result) then Self.Delete(Result);
    raise;
  end;
end;

// Редактирование --------------------------------------------------------------
procedure TrIDTreeView.UpdateNodeId(Node: TTreeNode; const AId: Integer);
var
  Id: TId;
begin
  if Assigned(Node) then
  begin
    if Assigned(Node.Data) then
      TId(Node.Data)^ := AId
    else begin
      New(Id);
      Id^ := AId;
      Node.Data := Id;
    end;
  end;
end;

procedure TrIDTreeView.UpdateNodeText(Node: TTreeNode; const AText: string);
begin
  if Assigned(Node) then
    Node.Text := AText;
end;

procedure TrIDTreeView.Delete(Node: TTreeNode);
var
  NodeData: TId;
begin
  inherited Delete(Node);
  if Node.Data <> nil then
  begin
    NodeData := Node.Data;
    Node.Data := nil;
    Dispose(NodeData);
  end;
end;

{ == TrKindIDTreeView ========================================================== }
constructor TrKindIDTreeView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ReadOnly := True;
  HideSelection := False;
  RowSelect := True;
  FSortOnlyData := False;
  FListDelimiter := ',';
  FListEmptyValue := '-1';
  FExtOnChange := nil;
end;

// Отключение и воостановление обработчика события OnChange --------------------
procedure TrKindIDTreeView.DisableOnChange;
begin
  if Assigned(OnChange) then
  begin
    FExtOnChange := OnChange;
    OnChange := nil;
  end;
end;

procedure TrKindIDTreeView.RestoreOnChange;
begin
  if Assigned(FExtOnChange) then
  begin
    OnChange := FExtOnChange;
    FExtOnChange := nil;
  end;
end;

// Сортировка ------------------------------------------------------------------
procedure TrKindIDTreeView.DataSortOnId;

  function DataSortProc(Node1, Node2: TTreeNode; Data: Integer): Integer; stdcall;
  var
    Id1, Id2: TKindId;
  begin
    Id1 := TKindId(Node1.Data);
    Id2 := TKindId(Node2.Data);
    if Assigned(Id1) and Assigned(Id2) then
    begin
      if TrKindIDTreeView(Node1.TreeView).SortDataOnlyId or (Id1^.Kind = Id2^.Kind)
      then Result := Id1^.Id - Id2^.Id
      else Result := Id1^.Kind - Id2^.Kind;
    end
    else Result := 0;
  end;

begin
  CustomSort(@DataSortProc, 0);
end;

procedure TrKindIDTreeView.Sort;
begin
  case SortType of
    stData: DataSortOnId;
    stText: AlphaSort;
  end;
end;

// Получение идентификаторов ---------------------------------------------------
function TrKindIDTreeView.GetNodeId(Node: TTreeNode): RKindId;
begin
  // Result := KindId(-1, -1);
  Result.Id := -1;
  Result.Kind := -1;
  if Assigned(Node) and Assigned(Node.Data) then
    Result := TKindId(Node.Data)^;
end;

function TrKindIDTreeView.GetNodeAbsIndex(Node: TTreeNode): Integer;
begin
  Result := -1;
  if Assigned(Node) then
    Result := Node.AbsoluteIndex;
end;

function TrKindIDTreeView.GetNodeImageIndex(Node: TTreeNode): Integer;
begin
  Result := -1;
  if Assigned(Node) then
    Result := Node.ImageIndex;
end;

function TrKindIDTreeView.GetSelectedId: RKindId;
begin
  Result := GetNodeId(Self.Selected);
end;

function TrKindIDTreeView.GetSelectedAbsIndex: Integer;
begin
  Result := GetNodeAbsIndex(Self.Selected);
end;

function TrKindIDTreeView.GetSelectedImageIndex: Integer;
begin
  Result := GetNodeImageIndex(Self.Selected);
end;

// Удаление элемента с переносом выделения на другой ---------------------------
procedure TrKindIDTreeView.DeleteSelectedNode; // ver 1.4.0.17
var
  Vis: TTreeNode;
begin
  if Assigned(Selected) then
  begin
    Vis := Selected.GetPrevVisible;
    if not Assigned(Vis) then Vis := Selected.GetNextVisible;
    if not Assigned(Vis) then Vis := TopItem;
    Items.Delete(Selected);
    Selected := Vis;
  end;
end;

// Поиск элемента --------------------------------------------------------------
function TrKindIDTreeView.FindNodeId(const AId: RKindId): TTreeNode;
var
  i: Integer;
  Node: TTreeNode;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
  begin
    Node := Items[i];
    if Assigned(Node.Data) and (TKindId(Node.Data)^.Id = AId.Id)
    and (TKindId(Node.Data)^.Kind = AId.Kind) then
    begin
      Result := Node;
      Break;
    end;
  end;
end;

function TrKindIDTreeView.FindNodeId(const AId, AKind: Integer): TTreeNode;
var
  i: Integer;
  Node: TTreeNode;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
  begin
    Node := Items[i];
    if Assigned(Node.Data) and (TKindId(Node.Data)^.Id = AId)
    and (TKindId(Node.Data)^.Kind = AKind) then
    begin
      Result := Node;
      Break;
    end;
  end;
end;

function TrKindIDTreeView.FindNodeIdKinds(const AId: Integer; const AKinds: array of Integer): TTreeNode;
var
  i: Integer;
  Node: TTreeNode;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
  begin
    Node := Items[i];
    if Assigned(Node.Data) and (TKindId(Node.Data)^.Id = AId)
    and ValueInList(TKindId(Node.Data)^.Kind, AKinds) then
    begin
      Result := Node;
      Break;
    end;
  end;
end;

function TrKindIDTreeView.FindNodeIdImages(const AId: RKindId; const AImages: TByteSet): TTreeNode;
var
  i: Integer;
  Node: TTreeNode;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
  begin
    Node := Items[i];
    if Assigned(Node.Data) and (TKindId(Node.Data)^.Id = AId.Id)
    and (TKindId(Node.Data)^.Kind = AId.Kind)
    and (Node.ImageIndex in AImages) then
    begin
      Result := Node;
      Break;
    end;
  end;
end;

function TrKindIDTreeView.FindNodeAbsIndex(const AIndex: Integer): TTreeNode;
begin
  if AIndex > -1 then
  begin
    if AIndex < Items.Count
    then Result := Items[AIndex]
    else Result := Items[Items.Count - 1];
  end
  else Result := nil;
end;

// Поиск подэлемента -----------------------------------------------------------
function TrKindIDTreeView.FindSubNodeId(Node: TTreeNode; const AId: RKindId): TTreeNode;
var
  ChNode: TTreeNode;
begin
  Result := nil;
  ChNode := Node.GetFirstChild;
  while Assigned(ChNode) and not Assigned(Result) do
  begin
    if Assigned(ChNode.Data) and (TKindId(ChNode)^.Id = AId.Id)
    and (TKindId(ChNode)^.Kind = AId.Kind)
    then Result := ChNode;
    ChNode := Node.GetNextChild(ChNode);
  end;
end;

function TrKindIDTreeView.FindSubNodeId(Node: TTreeNode; const AId, AKind: Integer): TTreeNode;
var
  ChNode: TTreeNode;
begin
  Result := nil;
  ChNode := Node.GetFirstChild;
  while Assigned(ChNode) and not Assigned(Result) do
  begin
    if Assigned(ChNode.Data) and (TKindId(ChNode)^.Id = AId)
    and (TKindId(ChNode)^.Kind = AKind)
    then Result := ChNode;
    ChNode := Node.GetNextChild(ChNode);
  end;
end;

function TrKindIDTreeView.FindSubNodeIdKinds(Node: TTreeNode; const AId: Integer;
  const AKinds: array of Integer): TTreeNode;
var
  ChNode: TTreeNode;
begin
  Result := nil;
  ChNode := Node.GetFirstChild;
  while Assigned(ChNode) and not Assigned(Result) do
  begin
    if Assigned(ChNode.Data) and (TKindId(ChNode)^.Id = AId)
    and ValueInList(TKindId(ChNode)^.Kind, AKinds)
    then Result := ChNode;
    ChNode := Node.GetNextChild(ChNode);
  end;
end;

function TrKindIDTreeView.FindSubNodeIdImages(Node: TTreeNode; const AId: RKindId;
  const AImages: TByteSet): TTreeNode;
var
  ChNode: TTreeNode;
begin
  Result := nil;
  ChNode := Node.GetFirstChild;
  while Assigned(ChNode) and not Assigned(Result) do
  begin
    if Assigned(ChNode.Data) and (TKindId(ChNode)^.Id = AId.Id)
    and (TKindId(Result)^.Kind = AId.Kind) and (ChNode.ImageIndex in AImages)
    then Result := ChNode;
    ChNode := Node.GetNextChild(ChNode);
  end;
end;

// Перемещение по индексу или ID -----------------------------------------------
procedure TrKindIDTreeView.GoToNodeId(const Mode: TRGotoNodeMode; const AId: RKindId);
var
  Node: TTreeNode;
begin
  Node := FindNodeId(AId);
  if Assigned(Node) then Selected := Node
  else begin
    case Mode of
      gmClearSelection: Selected := nil;
      gmSelectTopItem: Selected := TopItem;
      gmRaiseException: raise Exception.CreateFmt(SGotoNodeNotFound, [AId.Id]);
    end;
  end;
end;

procedure TrKindIDTreeView.GoToNodeId(const Mode: TRGotoNodeMode; const AId, AKind: Integer);
var
  Node: TTreeNode;
begin
  Node := FindNodeId(AId, AKind);
  if Assigned(Node) then Selected := Node
  else begin
    case Mode of
      gmClearSelection: Selected := nil;
      gmSelectTopItem: Selected := TopItem;
      gmRaiseException: raise Exception.CreateFmt(SGotoNodeNotFound, [AId]);
    end;
  end;
end;

procedure TrKindIDTreeView.GoToNodeIdKinds(const Mode: TRGotoNodeMode; const AId: Integer; const AKinds: array of Integer);
var
  Node: TTreeNode;
begin
  Node := FindNodeIdKinds(AId, AKinds);
  if Assigned(Node) then Selected := Node
  else begin
    case Mode of
      gmClearSelection: Selected := nil;
      gmSelectTopItem: Selected := TopItem;
      gmRaiseException: raise Exception.CreateFmt(SGotoNodeNotFound, [AId]);
    end;
  end;
end;

procedure TrKindIDTreeView.GoToNodeIdImages(const Mode: TRGotoNodeMode; const AId: RKindId; const AImages: TByteSet);
var
  Node: TTreeNode;
begin
  Node := FindNodeIdImages(AId, AImages);
  if Assigned(Node) then Selected := Node
  else begin
    case Mode of
      gmClearSelection: Selected := nil;
      gmSelectTopItem: Selected := TopItem;
      gmRaiseException: raise Exception.CreateFmt(SGotoNodeNotFound, [AId.Id]);
    end;
  end;
end;

procedure TrKindIDTreeView.GoToNodeAbsIndex(const Mode: TRGotoNodeMode; const AIndex: Integer);
var
  Node: TTreeNode;
begin
  Node := FindNodeAbsIndex(AIndex);
  if Assigned(Node) then Selected := Node
  else begin
    case Mode of
      gmClearSelection: Selected := nil;
      gmSelectTopItem: Selected := TopItem;
      gmRaiseException: raise Exception.CreateFmt(SGotoNodeNotFound, [AIndex]);
    end;
  end;
end;

// Проверка, является ли Owner владельцем (прямым или косвенным) для Node ------
function TrKindIDTreeView.CheckNodeOwner(Node, Owner: TTreeNode): Boolean;
var
  OwnNode: TTreeNode;
begin
  Result := Owner = Node;
  OwnNode := Node.Parent;
  while not Result and Assigned(OwnNode) do
  begin
    Result := OwnNode = Owner;
    OwnNode := OwnNode.Parent;
  end;
end;

// Генерация списка ID ---------------------------------------------------------
function TrKindIDTreeView.GetNodeIdList(Node: TTreeNode): string;

  procedure AddNodeId(Node: TTreeNode);
  var
    ChildNode: TTreeNode;
  begin
    if Assigned(Node.Data) and (TKindId(Node.Data)^.Id > -1) then
      Result := Result + FListDelimiter + IntToStr(TKindId(Node.Data)^.Id);
    ChildNode := Node.GetFirstChild;
    while Assigned(ChildNode) do
    begin
      AddNodeId(ChildNode);
      ChildNode := Node.GetNextChild(ChildNode);
    end;
  end;

begin
  Result := EmptyStr;
  if Assigned(Node) then AddNodeId(Node);
  if Result = EmptyStr then Result := FListEmptyValue
  else System.Delete(Result, 1, 1);
end;

function TrKindIDTreeView.GetNodeIdListKinds(Node: TTreeNode; const AKinds: array of Integer): string;

  procedure AddNodeId(Node: TTreeNode);
  var
    ChildNode: TTreeNode;
  begin
    if Assigned(Node.Data) and (TKindId(Node.Data)^.Id > -1)
    and ValueInList(TKindId(Node.Data)^.Kind, AKinds) then
      Result := Result + FListDelimiter + IntToStr(TKindId(Node.Data)^.Id);
    ChildNode := Node.GetFirstChild;
    while Assigned(ChildNode) do
    begin
      AddNodeId(ChildNode);
      ChildNode := Node.GetNextChild(ChildNode);
    end;
  end;

begin
  Result := EmptyStr;
  if Assigned(Node) then AddNodeId(Node);
  if Result = EmptyStr then Result := FListEmptyValue
  else System.Delete(Result, 1, 1);
end;

function TrKindIDTreeView.GetNodeIdListImages(Node: TTreeNode; const AImages: TByteSet): string;

  procedure AddNodeId(Node: TTreeNode);
  var
    ChildNode: TTreeNode;
  begin
    if Assigned(Node.Data) and (TKindId(Node.Data)^.Id > -1)
    and (Node.ImageIndex in AImages) then
      Result := Result + FListDelimiter + IntToStr(TKindId(Node.Data)^.Id);
    ChildNode := Node.GetFirstChild;
    while Assigned(ChildNode) do
    begin
      AddNodeId(ChildNode);
      ChildNode := Node.GetNextChild(ChildNode);
    end;
  end;

begin
  Result := EmptyStr;
  if Assigned(Node) then AddNodeId(Node);
  if Result = EmptyStr then Result := FListEmptyValue
  else System.Delete(Result, 1, 1);
end;

function TrKindIDTreeView.GetSelectedIdList: string;
begin
  Result := GetNodeIdList(Self.Selected);
end;

function TrKindIDTreeView.GetSelectedIdListKinds(const AKinds: array of Integer): string;
begin
  Result := GetNodeIdListKinds(Self.Selected, AKinds);
end;

function TrKindIDTreeView.GetSelectedIdListImages(const AImages: TByteSet): string;
begin
  Result := GetNodeIdListImages(Self.Selected, AImages);
end;

// Добавление ------------------------------------------------------------------
function TrKindIDTreeView.AddFirstNode(const AId: RKindId; const AImageIndex, ASelectedIndex: Integer;
  const AText: string): TTreeNode;
var
  Id: TKindId;
begin
  Result := nil;
  try
    Result := Self.Items.Add(nil, AText);
    Result.ImageIndex := AImageIndex;
    Result.SelectedIndex := ASelectedIndex;
    New(Id);
    Id^ := AId;
    Result.Data := Id;
  except
    if Assigned(Result) then Self.Delete(Result);
    raise;
  end;
end;

function TrKindIDTreeView.AddFirstNode(const AId, AKind, AImageIndex, ASelectedIndex: Integer;
  const AText: string): TTreeNode;
var
  Id: TKindId;
begin
  Result := nil;
  try
    Result := Self.Items.Add(nil, AText);
    Result.ImageIndex := AImageIndex;
    Result.SelectedIndex := ASelectedIndex;
    New(Id);
    Id^.Id := AId;
    Id^.Kind := AKind;
    Result.Data := Id;
  except
    if Assigned(Result) then Self.Delete(Result);
    raise;
  end;
end;

function TrKindIDTreeView.AddChildNode(OwnerNode: TTreeNode;
  const AId: RKindId; const AImageIndex, ASelectedIndex: Integer;
  const AText: string): TTreeNode;
var
  Id: TKindId;
begin
  Result := nil;
  try
    Result := Self.Items.AddChild(OwnerNode, AText);
    Result.ImageIndex := AImageIndex;
    Result.SelectedIndex := ASelectedIndex;
    New(Id);
    Id^ := AId;
    Result.Data := Id;
  except
    if Assigned(Result) then Self.Delete(Result);
    raise;
  end;
end;

function TrKindIDTreeView.AddChildNode(OwnerNode: TTreeNode;
  const AId, AKind, AImageIndex, ASelectedIndex: Integer;
  const AText: string): TTreeNode;
var
  Id: TKindId;
begin
  Result := nil;
  try
    Result := Self.Items.AddChild(OwnerNode, AText);
    Result.ImageIndex := AImageIndex;
    Result.SelectedIndex := ASelectedIndex;
    New(Id);
    Id^.Id := AId;
    Id^.Kind := AKind;
    Result.Data := Id;
  except
    if Assigned(Result) then Self.Delete(Result);
    raise;
  end;
end;

// Редактирование --------------------------------------------------------------
procedure TrKindIDTreeView.UpdateNodeId(Node: TTreeNode; const AId: RKindId);
var
  Id: TKindId;
begin
  if Assigned(Node) then
  begin
    if Assigned(Node.Data) then
      TKindId(Node.Data)^ := AId
    else begin
      New(Id);
      Id^ := AId;
      Node.Data := Id;
    end;
  end;
end;

procedure TrKindIDTreeView.UpdateNodeId(Node: TTreeNode; const AId, AKind: Integer);
var
  Id: TKindId;
begin
  if Assigned(Node) then
  begin
    if Assigned(Node.Data) then
    begin
      TKindId(Node.Data)^.Id := AId;
      TKindId(Node.Data)^.Kind := AKind;
    end
    else begin
      New(Id);
      Id^.Id := AId;
      Id^.Kind := AKind;
      Node.Data := Id;
    end;
  end;
end;

procedure TrKindIDTreeView.UpdateNodeText(Node: TTreeNode; const AText: string);
begin
  if Assigned(Node) then
    Node.Text := AText;
end;

procedure TrKindIDTreeView.Delete(Node: TTreeNode);
var
  NodeData: TKindId;
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
