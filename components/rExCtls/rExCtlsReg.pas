unit rExCtlsReg;

interface

procedure Register;

implementation

uses
  Classes, rSpin64, rFloatEdit, rIPEdit, rSortListView, rTreeView, rIdTreeView, rClrCombo, rGrids;

procedure Register;
begin
  RegisterComponents('Rav Soft', [TrFloatEdit, TrIPAddrEdit, TSpinEdit64, TrColorCombo,
    TrSortListView, TrTreeView, TrIDTreeView, TrKindIDTreeView, TrOwnerDrawGrid]);
end;

end.
