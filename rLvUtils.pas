unit rLvUtils;

interface

uses
  ComCtrls;

procedure ScrollToItem(LV: TListView; LI: TListItem);
procedure ScrollToSelectedItem(LV: TListView);
procedure ScrollToLastItem(LV: TListView);

implementation

uses
  Windows, Messages;

procedure ScrollToItem(LV: TListView; LI: TListItem);
var
  Fix: Integer;
begin
  if Assigned(LI) and (LV.VisibleRowCount > 0) then
  begin
    Fix := LV.TopItem.Index;
    while (LI.Index < LV.TopItem.Index) and (LV.TopItem.Index > 0) do
    begin
      SendMessage(LV.Handle, WM_VSCROLL, SB_LINEUP, 0);
      if Fix = LV.TopItem.Index then Break
      else Fix := LV.TopItem.Index;
    end;
    Fix := LV.TopItem.Index;
    while (LI.Index >= LV.TopItem.Index + LV.VisibleRowCount)
    and (LV.TopItem.Index + LV.VisibleRowCount < LV.Items.Count) do
    begin
      SendMessage(LV.Handle, WM_VSCROLL, SB_LINEDOWN, 0);
      if Fix = LV.TopItem.Index then Break
      else Fix := LV.TopItem.Index;
    end;
  end;
end;

procedure ScrollToSelectedItem(LV: TListView);
begin
  ScrollToItem(LV, LV.Selected);
end;

procedure ScrollToLastItem(LV: TListView);
begin
  if LV.Items.Count > 0 then
    ScrollToItem(LV, LV.Items[LV.Items.Count - 1]);
end;

end.