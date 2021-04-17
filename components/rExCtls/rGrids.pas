unit rGrids;

interface

uses
  Types, Grids;

type
  TGetTextEvent = procedure (Sender: TObject; ACol, ARow: Longint; var Value: string) of object;
  TSetTextEvent = procedure (Sender: TObject; ACol, ARow: Longint; const Value: string) of object;

  TrOwnerDrawGrid = class (TDrawGrid)
  private
    FUpdating: Boolean;
    FNeedsUpdating: Boolean;
    FEditUpdate: Integer;
    FOnGetCellText: TGetTextEvent;
    FOnSetCellText: TSetTextEvent;
    procedure DisableEditUpdate;
    procedure EnableEditUpdate;
    procedure Update(ACol, ARow: Integer); reintroduce;
    function  GetCells(ACol, ARow: Integer): string;
    procedure SetCells(ACol, ARow: Integer; const Value: string);
  protected
    procedure DrawCell(ACol, ARow: Longint; ARect: TRect;
      AState: TGridDrawState); override;
    function  GetEditText(ACol, ARow: Longint): string; override;
    procedure SetEditText(ACol, ARow: Longint; const Value: string); override;
  public
    property Cells[ACol, ARow: Integer]: string read GetCells write SetCells;
  published
    property OnGetCellText: TGetTextEvent read FOnGetCellText write FOnGetCellText;
    property OnSetCellText: TSetTextEvent read FOnSetCellText write FOnSetCellText;
  end;

implementation

{ TrOwnerDrawGrid }

function TrOwnerDrawGrid.GetCells(ACol, ARow: Integer): string;
begin
  Result := '';
  if Assigned(FOnGetCellText) then
    FOnGetCellText(Self, ACol, ARow, Result);
end;

procedure TrOwnerDrawGrid.SetCells(ACol, ARow: Integer; const Value: string);
begin
  if Assigned(FOnSetCellText) then
    FOnSetCellText(Self, ACol, ARow, Value);
  Update(ACol, ARow);
end;

procedure TrOwnerDrawGrid.DrawCell(ACol, ARow: Integer; ARect: TRect;
  AState: TGridDrawState);
begin
  if DefaultDrawing then
    Canvas.TextRect(ARect, ARect.Left+2, ARect.Top+2, Cells[ACol, ARow]);
  inherited DrawCell(ACol, ARow, ARect, AState);
end;

function TrOwnerDrawGrid.GetEditText(ACol, ARow: Integer): string;
begin
  Result := Cells[ACol, ARow];
  if Assigned(OnGetEditText) then OnGetEditText(Self, ACol, ARow, Result);
end;

procedure TrOwnerDrawGrid.SetEditText(ACol, ARow: Integer; const Value: string);
begin
  DisableEditUpdate;
  try
    if Value <> Cells[ACol, ARow] then Cells[ACol, ARow] := Value;
  finally
    EnableEditUpdate;
  end;
  inherited SetEditText(ACol, ARow, Value);
end;

procedure TrOwnerDrawGrid.DisableEditUpdate;
begin
  Inc(FEditUpdate);
end;

procedure TrOwnerDrawGrid.EnableEditUpdate;
begin
  Dec(FEditUpdate);
end;

procedure TrOwnerDrawGrid.Update(ACol, ARow: Integer);
begin
  if not FUpdating then InvalidateCell(ACol, ARow)
  else FNeedsUpdating := True;
  if (ACol = Col) and (ARow = Row) and (FEditUpdate = 0) then InvalidateEditor;
end;

end.
