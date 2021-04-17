unit rSortListView;

interface

uses
  Classes, ComCtrls;

type
  TSortDirection = (sdAscending, sdDescending);

  TLVOwnerSortEvent = procedure(Sender: TObject; const SortColumn: Integer; SortDirection: TSortDirection) of object;

  TrSortListView = class(TListView)
  private
    fColumnToSort: Integer;
    fSortDirection: TSortDirection;
    fOwnerSort: TLVOwnerSortEvent;
    fExtOnCompare: TLVCompareEvent;
    procedure SetSortColumn(const Value: Integer);
    procedure SetSortDirection(const Value: TSortDirection);
    procedure ColumnsCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ColClick(Column: TListColumn); override;
    function  Sort: Boolean;
    procedure DeleteSelected; override;
  published
    property SortColumn: Integer read fColumnToSort write SetSortColumn default 0;
    property SortDirection: TSortDirection read fSortDirection write SetSortDirection;
    property OnCompare: TLVCompareEvent read fExtOnCompare write fExtOnCompare;
    property OnOwnerSort: TLVOwnerSortEvent read fOwnerSort write fOwnerSort;
  end;

implementation

uses
  Forms, Themes, Controls, SysUtils, StrUtils, rVclUtils, rDialogs;

resourcestring
  rsErrInvalidColumn  = 'Некорректное занчение номера столбца сортировки (%d)';

{ == RSortListView ============================================================= }

constructor TrSortListView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FlatScrollBars := True;
  ViewStyle := vsReport;
  ReadOnly := True;
  HideSelection := False;
  RowSelect := True;
  SortType := stData;
  inherited OnCompare := ColumnsCompare;
  fColumnToSort := 0;
  fSortDirection := sdAscending;
end;

procedure TrSortListView.ColumnsCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
var
  Column: Integer;

  function UniCompareText(const S1, S2: string): Integer;
  var
    D1, D2: Extended;
    E1, E2: Integer;
  begin
    Val(StringReplace(S1, ',', '.', []), D1, E1);
    Val(StringReplace(S2, ',', '.', []), D2, E2);
    if (E1 = 0) and (E2 = 0) then
    begin
      if D1 > D2
      then Result := 1
      else begin
        if D1 < D2
        then Result := -1
        else Result := 0;
      end;
    end
    else Result := AnsiCompareText(S1, S2);
  end;

begin
  if fColumnToSort = intDisable then
    Compare := 0
  else if (fColumnToSort = 0)
       // Fix error: 2008-04-20, version 4.1.0.240
       or (Item1.SubItems.Count < fColumnToSort)
       or (Item2.SubItems.Count < fColumnToSort) then
         Compare := UniCompareText(Item1.Caption, Item2.Caption)
       else begin
         Column := fColumnToSort - 1;
         Compare := UniCompareText(Item1.SubItems[Column], Item2.SubItems[Column]);
         // Add 2008-04-20, version 4.1.0.239
         if Compare = 0 then
           Compare := UniCompareText(Item1.Caption, Item2.Caption);
       end;
  if fSortDirection = sdDescending then
    Compare := - Compare;
  if Assigned(fExtOnCompare) then
    fExtOnCompare(Sender, Item1, Item2, fColumnToSort, Compare);
end;

function TrSortListView.Sort: Boolean;
begin
  StartWait;
  try
    Result := False;
    if OwnerData then
    begin
      if Assigned(fOwnerSort) then
      begin
        fOwnerSort(Self, fColumnToSort, fSortDirection);
        Result := True;
      end;
      if Result then
        Repaint;
    end
    else Result := (Self as TCustomListView).AlphaSort;
  finally
    StopWait;
  end;
end;

procedure TrSortListView.ColClick(Column: TListColumn);
begin
  if Column.Index = fColumnToSort then
  begin
    if fSortDirection = sdAscending
    then fSortDirection := sdDescending
    else fSortDirection := sdAscending;
    Sort;
  end
  else begin
    fColumnToSort := Column.Index;
    fSortDirection := sdAscending;
    Sort;
  end;
  inherited;
end;

procedure TrSortListView.SetSortColumn(const Value: Integer);
begin
  if (Value <> fColumnToSort) then begin
    if (Value < intDisable) or (Value >= Columns.Count) then
      raise Exception.CreateFmt(rsErrInvalidColumn, [Value]);
    fColumnToSort := Value;
    Sort;
  end;
end;

procedure TrSortListView.SetSortDirection(const Value: TSortDirection);
begin
  if Value <> fSortDirection then
  begin
    fSortDirection := Value;
    Sort;
  end;
end;

procedure TrSortListView.DeleteSelected;
var
  NextId: Integer;
begin
  if Items.Count > Selected.Index + 1
  then NextId := Selected.Index
  else NextId := Selected.Index - 1;
  inherited DeleteSelected;
  if NextId in [0..Items.Count - 1] then
    Selected := Items[NextId];
end;

end.
