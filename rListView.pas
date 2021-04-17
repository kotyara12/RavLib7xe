unit rListView;

interface

uses
  ComCtrls;

{ Добавление нового элемена в список }
function  AddNewListItem(LV: TListView; AId: Integer; AName: string; AImage: Integer): TListItem;
function  AddNewListNotesItem(LV: TListView; AId: Integer; AName, ANotes: string; AImage: Integer): TListItem;
function  AddNewListItemSub1(LV: TListView; AId: Integer; AName, ASub1: string; AImage: Integer): TListItem;

{ Получение сведений об элененте }
function  GetItemID(LI: TListItem): Integer;
function  GetItemKindID(LI: TListItem): Integer;
function  GetCheckedIDList(LV: TListView): string;
function  GetIndexedIDList(LV: TListView; Index: Integer): string;
function  GetItemIndex(LI: TListItem): Integer;

{ Поиск элемента в списке }
function  LV_FindId(LV: TListView; const iId: Integer): TListItem;
function  LV_FindKindId(LV: TListView; const iId: Integer): TListItem;
function  LV_FindCaption(LV: TListView; const aCaption: string): TListItem;
function  LV_FindCaptionPart(LV: TListView; const aCaption: string): TListItem;
function  LV_FindSubitem(LV: TListView; const aSubitem: string; const iSid: Integer): TListItem;
function  LV_FindSubitemPart(LV: TListView; const aSubitem: string; const iSid: Integer): TListItem;
function  LV_FindText(LV: TListView; const aText: string): TListItem;
function  LV_FindTextPart(LV: TListView; const aText: string): TListItem;

procedure MarkAllItems(LV: TListView; AMark: Boolean);
procedure MarkItemsOnList(LV: TListView; IDList: string);

{ Перемещение записей из списка в список }
procedure MoveSelectedListItems(LV1, LV2: TListView; const ImBase, ImNew, ImReturn: Integer);
{ Перемещение элемента в списке }
procedure ReplaceItems(LV: TListView; const A, B: Integer);
procedure MoveSelectedItemUp(LV: TListView);
procedure MoveSelectedItemDown(LV: TListView);
function  MoveItemTo(LV: TListView; Item: TListItem; NewPosition: Integer): TListItem;
function  FindLastCheckedItem(LV: TListView): TListItem;
procedure MoveUpCheckedItems(LV: TListView);
{ Прокрутка списка на выделенный элемент }
procedure ScrollToSelectedItem(LV: TListView);
procedure ScrollToItem(LV: TListView; LI: TListItem);
procedure ScrollToLastItem(LV: TListView);

implementation

uses
  SysUtils, StrUtils, Windows, Messages, rxStrUtilsE, RVclUtils, rDialogs;

function AddNewListItem(LV: TListView; AId: Integer; AName: string; AImage: Integer): TListItem;
var
  ID: TId;
begin
  Result := LV.Items.Add;
  Result.Caption := AName;
  Result.ImageIndex := AImage;
  New(ID);
  ID^ := AId;
  Result.Data := ID;
end;

function AddNewListNotesItem(LV: TListView; AId: Integer; AName, ANotes: string; AImage: Integer): TListItem;
begin
  if ANotes <> EmptyStr
  then Result := AddNewListItem(LV, AId, AName + ' (' + ANotes + ')', AImage)
  else Result := AddNewListItem(LV, AId, AName, AImage);
end;

function AddNewListItemSub1(LV: TListView; AId: Integer; AName, ASub1: string; AImage: Integer): TListItem;
begin
  Result := AddNewListItem(LV, AId, AName, AImage);
  Result.SubItems.Add(ASub1);
end;

function GetItemID(LI: TListItem): Integer;
var
  ID: TId;
begin
  if LI <> nil then
  begin
    ID := LI.Data;
    if ID <> nil then Result := ID^ else Result := intDisable;
  end
  else Result := intDisable;
end;

function GetItemKindID(LI: TListItem): Integer;
var
  ID: TKindId;
begin
  if LI <> nil
  then
    begin
      ID := LI.Data;
      if ID <> nil then Result := ID^.Id else Result := intDisable;
    end
  else Result := intDisable;
end;

function GetItemIndex(LI: TListItem): Integer;
begin
  if LI <> nil
  then Result := LI.ImageIndex
  else Result := intDisable;
end;

{ == Поиск в ListView ================================================================================================== }

(* resolved
function FindAnyListItem(LV: TListView; const AId: Integer): TListItem;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (i < LV.Items.Count) and not ((GetItemID(LV.Items.Item[i]) = AId)) do
    Inc(i);
  if (i < LV.Items.Count) and (GetItemID(LV.Items.Item[i]) = AId)
  then Result := LV.Items.Item[i];
end;

function FindKindListItem(LV: TListView; const AId: Integer): TListItem;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (i < LV.Items.Count) and not ((GetItemKindID(LV.Items.Item[i]) = AId)) do
    Inc(i);
  if (i < LV.Items.Count) and (GetItemKindID(LV.Items.Item[i]) = AId)
  then Result := LV.Items.Item[i];
end;

function FindNameListItem(LV: TListView; const AName: string): TListItem;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (i < LV.Items.Count) and not (LV.Items.Item[i].Caption = AName) do
    Inc(i);
  if (i < LV.Items.Count) and (LV.Items.Item[i].Caption = AName)
  then Result := LV.Items.Item[i];
end;

function FindSubitemListItem(LV: TListView; const AName: string; AId: Integer): TListItem;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (i < LV.Items.Count) and not (LV.Items.Item[i].Subitems[AId] = AName) do
    Inc(i);
  if (i < LV.Items.Count) and (LV.Items.Item[i].Subitems[AId] = AName)
  then Result := LV.Items.Item[i];
end;
*)

function LV_FindId(LV: TListView; const iId: Integer): TListItem;
var
  i, iCount: Integer;
begin
  Result := nil;
  iCount := LV.Items.Count - 1;
  for i := 0 to iCount do
    if GetItemID(LV.Items[i]) = iId then
    begin
      Result := LV.Items[i];
      Break;
    end;
end;

function LV_FindKindId(LV: TListView; const iId: Integer): TListItem;
var
  i, iCount: Integer;
begin
  Result := nil;
  iCount := LV.Items.Count - 1;
  for i := 0 to iCount do
    if GetItemKindID(LV.Items[i]) = iId then
    begin
      Result := LV.Items[i];
      Break;
    end;
end;

function LV_FindCaption(LV: TListView; const aCaption: string): TListItem;
var
  i, iCount: Integer;
begin
  Result := nil;
  iCount := LV.Items.Count - 1;
  for i := 0 to iCount do
    if AnsiSameText(LV.Items[i].Caption, aCaption) then
    begin
      Result := LV.Items[i];
      Break;
    end;
end;

function LV_FindCaptionPart(LV: TListView; const aCaption: string): TListItem;
var
  i, iCount: Integer;
begin
  Result := nil;
  iCount := LV.Items.Count - 1;
  for i := 0 to iCount do
    if AnsiContainsText(LV.Items[i].Caption, aCaption) then
    begin
      Result := LV.Items[i];
      Break;
    end;
end;

function LV_FindSubitem(LV: TListView; const aSubitem: string; const iSid: Integer): TListItem;
var
  i, iCount: Integer;
begin
  Result := nil;
  iCount := LV.Items.Count - 1;
  for i := 0 to iCount do
    if AnsiSameText(LV.Items[i].SubItems[iSid], aSubitem) then
    begin
      Result := LV.Items[i];
      Break;
    end;
end;

function LV_FindSubitemPart(LV: TListView; const aSubitem: string; const iSid: Integer): TListItem;
var
  i, iCount: Integer;
begin
  Result := nil;
  iCount := LV.Items.Count - 1;
  for i := 0 to iCount do
    if AnsiContainsText(LV.Items[i].SubItems[iSid], aSubitem) then
    begin
      Result := LV.Items[i];
      Break;
    end;
end;

function LV_FindText(LV: TListView; const aText: string): TListItem;
var
  i, iCount: Integer;
  j, jCount: Integer;
begin
  Result := nil;
  iCount := LV.Items.Count - 1;
  for i := 0 to iCount do
  begin
    if AnsiSameText(LV.Items[i].Caption, aText) then
    begin
      Result := LV.Items[i];
      Break;
    end
    else begin
      jCount := LV.Items[i].SubItems.Count - 1;
      for j := 0 to jCount do
      begin
        if AnsiSameText(LV.Items[i].SubItems[j], aText) then
        begin
          Result := LV.Items[i];
          Break;
        end;
      end;
      if Assigned(Result) then
        Break;
    end;
  end;
end;

function LV_FindTextPart(LV: TListView; const aText: string): TListItem;
var
  i, iCount: Integer;
  j, jCount: Integer;
begin
  Result := nil;
  iCount := LV.Items.Count - 1;
  for i := 0 to iCount do
  begin
    if AnsiContainsText(LV.Items[i].Caption, aText) then
    begin
      Result := LV.Items[i];
      Break;
    end
    else begin
      jCount := LV.Items[i].SubItems.Count - 1;
      for j := 0 to jCount do
      begin
        if AnsiContainsText(LV.Items[i].SubItems[j], aText) then
        begin
          Result := LV.Items[i];
          Break;
        end;
      end;
      if Assigned(Result) then
        Break;
    end;
  end;
end;

function GetCheckedIDList(LV: TListView): string;
var
  i: Integer;
begin
  Result := EmptyStr;
  for i := 0 to LV.Items.Count - 1 do
    if LV.Items[i].Checked
    then Result := Result + IntToStr(GetItemId(LV.Items.Item[i])) + chListDivChar;
  if Result <> EmptyStr then
    Delete(Result, Length(Result), 1);
end;

function GetIndexedIDList(LV: TListView; Index: Integer): string;
var
  i: Integer;
begin
  Result := EmptyStr;
  for i := 0 to LV.Items.Count - 1 do
    if LV.Items[i].ImageIndex = Index
    then Result := Result + IntToStr(GetItemId(LV.Items.Item[i])) + chListDivChar;
  if Result <> EmptyStr then
    Delete(Result, Length(Result), 1);
end;

procedure MarkAllItems(LV: TListView; AMark: Boolean);
var
  i: Integer;
begin
  LV.Items.BeginUpdate;
  try
    for i := 0 to LV.Items.Count - 1 do
      LV.Items.Item[i].Checked := AMark;
  finally
    LV.Items.EndUpdate;
  end;
end;

procedure MarkItemsOnList(LV: TListView; IDList: string);
var
  i: Integer;
  LI: TListItem;
begin
  LV.Items.BeginUpdate;
  try
    for i := 1 to WordCount(IDList, [chListDivChar]) do
    begin
      LI := LV_FindId(LV, StrToInt(ExtractWord(i, IDList, [chListDivChar])));
      if LI <> nil then LI.Checked := True;
    end;
  finally
    LV.Items.EndUpdate;
  end;
end;

procedure MoveSelectedListItems(LV1, LV2: TListView; const ImBase, ImNew, ImReturn: Integer);
var
  i, j: Integer;
begin
  LV1.Items.BeginUpdate;
  LV2.Items.BeginUpdate;
  try
    for i := 0 to LV1.Items.Count - 1 do
      if LV1.Items[i].Selected then begin
        with LV2.Items.Add do
        begin
          if Assigned(LV1.Items[i].Data) then
          begin
            Data := LV1.Items[i].Data;
            LV1.Items[i].Data := nil;
          end;
          Caption := LV1.Items[i].Caption;
          for j := 0 to LV1.Items[i].SubItems.Count - 1 do
            Subitems.Add(LV1.Items[i].SubItems[j]);
          if LV1.Items[i].ImageIndex = ImReturn
          then ImageIndex := ImBase
          else ImageIndex := ImNew;
          Selected := True;
        end;
      end;
    for i := LV1.Items.Count - 1 downto 0 do
      if LV1.Items[i].Selected then LV1.Items.Delete(i);
  finally
    LV2.Items.EndUpdate;
    LV1.Items.EndUpdate;
  end;
end;

procedure ReplaceItems(LV: TListView; const A, B: Integer);
var
  TmplItem: TListItem;
begin
  if Assigned(LV.Items[A]) and Assigned(LV.Items[B]) then
  begin
    LV.Items.BeginUpdate;
    try
      TmplItem := LV.Items.Add;
      try
        TmplItem.Assign(LV.Items[A]);
        LV.Items[A].Assign(LV.Items[B]);
        LV.Items[B].Assign(TmplItem);
      finally
        TmplItem.Free;
      end;
    finally
      LV.Items.EndUpdate;
    end;
  end;
end;

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

procedure MoveSelectedItemUp(LV: TListView);
begin
  if Assigned(LV.Selected) and (LV.Selected.Index > 0) then
  begin
    ReplaceItems(LV, LV.Selected.Index, LV.Selected.Index - 1);
    LV.Selected := LV.Items[LV.Selected.Index - 1];
    ScrollToSelectedItem(LV);
  end;
end;

procedure MoveSelectedItemDown(LV: TListView);
begin
  if Assigned(LV.Selected) and (LV.Selected.Index < LV.Items.Count - 1) then
  begin
    ReplaceItems(LV, LV.Selected.Index, LV.Selected.Index + 1);
    LV.Selected := LV.Items[LV.Selected.Index + 1];
    ScrollToSelectedItem(LV);
  end;
end;

function MoveItemTo(LV: TListView; Item: TListItem; NewPosition: Integer): TListItem;
begin
  Result := nil;
  if Assigned(Item) and (NewPosition > intDisable) then
  begin
    LV.Items.BeginUpdate;
    try
      Result := LV.Items.Insert(NewPosition);
      Result.Assign(Item);
      Item.Data := nil;
      LV.Items.Delete(Item.Index);
    finally
      LV.Items.EndUpdate;
    end;
  end;
end;

function FindLastCheckedItem(LV: TListView): TListItem;
var
  i: Integer;
begin
  Result := nil;
  if LV.Items.Count > 0 then
  begin
    i := 0;
    while (i < LV.Items.Count) and (LV.Items[i].Checked) do
      if LV.Items[i].Checked then
      begin
        Result := LV.Items[i];
        Inc(i);
      end
  end;
end;

procedure MoveUpCheckedItems(LV: TListView);
var
  LastItem, NewItem: TListItem;
  i, NewIdx: Integer;
  SelectedFlag: Boolean;
begin
  LV.Items.BeginUpdate;
  try
    i := 0;
    while i < LV.Items.Count do
    begin
      if LV.Items[i].Checked then
      begin
        LastItem := FindLastCheckedItem(LV);
        if not Assigned(LastItem)
        then NewIdx := 0
        else NewIdx := LastItem.Index + 1;
        if NewIdx < i then
        begin
          SelectedFlag := LV.Selected = LV.Items[i];
          NewItem := LV.Items.Insert(NewIdx);
          NewItem.Assign(LV.Items[i + 1]);
          LV.Items[i + 1].Data := nil;
          LV.Items.Delete(i + 1);
          if SelectedFlag then LV.Selected := NewItem;
        end
        else Inc(i);
      end
      else Inc(i);
    end;
  finally
    LV.Items.EndUpdate;
  end;
end;

end.
