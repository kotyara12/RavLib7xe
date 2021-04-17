unit rFrmStore;

interface

uses
  Forms, Graphics, ExtCtrls, Grids, ComCtrls;

{ == Сохранение позиции формы ================================================== }
procedure ini_SaveFormPosition(Form: TForm);
procedure reg_SaveFormPosition(Form: TForm);
procedure ini_LoadFormPosition(Form: TForm; const LoadState, LoadPosition: Boolean);
procedure reg_LoadFormPosition(Form: TForm; const LoadState, LoadPosition: Boolean);

{ == Сохранение произвольного параметра ======================================== }
procedure ini_SaveValueInt(Form: TForm; const sName: string; iValue: Integer);
procedure reg_SaveValueInt(Form: TForm; const sName: string; iValue: Integer);
function  ini_LoadValueInt(Form: TForm; const sName: string; const iDef: Integer): Integer;
function  reg_LoadValueInt(Form: TForm; const sName: string; const iDef: Integer): Integer;
procedure ini_SaveValueBool(Form: TForm; const sName: string; iValue: Boolean);
procedure reg_SaveValueBool(Form: TForm; const sName: string; iValue: Boolean);
function  ini_LoadValueBool(Form: TForm; const sName: string; const iDef: Boolean): Boolean;
function  reg_LoadValueBool(Form: TForm; const sName: string; const iDef: Boolean): Boolean;

{ == Сохранение панелей TCoolBar =============================================== }
procedure ini_SaveCoolBar(Form: TForm; CoolBar: TCoolBar);
procedure reg_SaveCoolBar(Form: TForm; CoolBar: TCoolBar);
procedure ini_LoadCoolBar(Form: TForm; CoolBar: TCoolBar);
procedure reg_LoadCoolBar(Form: TForm; CoolBar: TCoolBar);

{ == Сохранение ширины столбцов TListView ====================================== }
procedure ini_SaveListColumns(Form: TForm; ListView: TListView; const SaveState: Boolean = True);
procedure reg_SaveListColumns(Form: TForm; ListView: TListView; const SaveState: Boolean = True);
procedure ini_LoadListColumns(Form: TForm; ListView: TListView; const LoadState: Boolean = True);
procedure reg_LoadListColumns(Form: TForm; ListView: TListView; const LoadState: Boolean = True);

{ == Сохранение ширины столбцов TCustomGrid ====================================== }
procedure ini_SaveGridColumns(Form: TForm; Grid: TDrawGrid);
procedure reg_SaveGridColumns(Form: TForm; Grid: TDrawGrid);
procedure ini_LoadGridColumns(Form: TForm; Grid: TDrawGrid);
procedure reg_LoadGridColumns(Form: TForm; Grid: TDrawGrid);

implementation

uses
  SysUtils, IniFiles, Registry, Classes, Controls, Windows, Messages, rxStrUtilsE;

const
  sFormName         = '%s.%s';
  sKeyName          = '\Software\RavSoft\%s';
  sFrmExt           = '.frm';
  sMDISuffix        = '.MDIChildren';

const
  siFlags           = 'Flags';
  siShowCmd         = 'ShowCmd';
  siMinMaxPos       = 'MinMaxPos';
  siMinMaxPosR      = 'MinMaxPos_%dx%d';
  siNormPos         = 'NormPos';
  siNormPosR        = 'NormPos_%dx%d';
  siPixels          = 'PixelsPerInch';
  siMDIChild        = 'MDI Children';
  siListCount       = 'Count';
  siItem            = 'Item%d';
  siFont            = 'Font%s';
  siFormPos         = '%d,%d,%d,%d';
  siCoolBar         = '%s.Band%d';
  siCoolBand        = '%s,%s,%s,%d';
  siListMultiSelect = '%s.MultiSelect';
  siListGridLines   = '%s.GridLines';
  siListColumn      = '%s.Column%d';
  siGridColumn      = '%s.Column%d';

const
  Delims = [',',' '];
  Delim  = [','];

function GetFormIdf(Form: TForm): string;
begin
  Result := Form.ClassName;
  if Form.FormStyle = fsMDIChild then
    Result := Result + SMDISuffix;
end;

function ini_GetModuleFormFile: string;
begin
  Result := ChangeFileExt(GetModuleName(HInstance), sFrmExt);
end;

function reg_GetFormRegKey(Form: TForm): string;
begin
  Result := Format(sKeyName,
    [ExtractFileName(ChangeFileExt(GetModuleName(HInstance), EmptyStr))]);
end;

{ == Сохранение позиции формы ================================================== }
procedure custom_SaveFormPosition(Form: TForm; Ini: TCustomIniFile);
var
  Section: string;
  Placement: TWindowPlacement;
begin
  Placement.Length := SizeOf(TWindowPlacement);
  if GetWindowPlacement(Form.Handle, @Placement) then
  begin
    // Генерируем имя секции
    Section := GetFormIdf(Form);
    // Устанавливаем свойства формы
    if (Form = Application.MainForm) and IsIconic(Application.Handle) then
      Placement.ShowCmd := SW_SHOWMINIMIZED;
    if (Form.FormStyle = fsMDIChild) and (Form.WindowState = wsMinimized) then
      Placement.Flags := Placement.Flags or WPF_SETMINPOSITION;
    // Сохраняем свойства формы
    Ini.WriteInteger(Section, siFlags, Placement.Flags);
    Ini.WriteInteger(Section, siShowCmd, Placement.ShowCmd);
    Ini.WriteInteger(Section, siPixels, Screen.PixelsPerInch);
    Ini.WriteString(Section, siMinMaxPos,
       Format(siFormPos, [Placement.ptMinPosition.X, Placement.ptMinPosition.Y,
       Placement.ptMaxPosition.X, Placement.ptMaxPosition.Y]));
    Ini.WriteString(Section, Format(siMinMaxPosR, [Screen.Width, Screen.Height]),
       Format(siFormPos, [Placement.ptMinPosition.X, Placement.ptMinPosition.Y,
       Placement.ptMaxPosition.X, Placement.ptMaxPosition.Y]));
    Ini.WriteString(Section, siNormPos,
       Format(siFormPos, [Placement.rcNormalPosition.Left, Placement.rcNormalPosition.Top,
       Placement.rcNormalPosition.Right, Placement.rcNormalPosition.Bottom]));
    Ini.WriteString(Section, Format(siNormPosR, [Screen.Width, Screen.Height]),
       Format(siFormPos, [Placement.rcNormalPosition.Left, Placement.rcNormalPosition.Top,
       Placement.rcNormalPosition.Right, Placement.rcNormalPosition.Bottom]));
  end;
  Ini.UpdateFile;
end;

procedure ini_SaveFormPosition(Form: TForm);
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    custom_SaveFormPosition(Form, Ini);
  finally
    Ini.Free;
  end;
end;

procedure reg_SaveFormPosition(Form: TForm);
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    custom_SaveFormPosition(Form, Reg);
  finally
    Reg.Free;
  end;
end;

{ == Восстановление позиции формы ============================================== }
{$HINTS OFF}

type
  TNastyForm = class(TScrollingWinControl)
  private
    FActiveControl: TWinControl;
    FFocusedControl: TWinControl;
    FBorderIcons: TBorderIcons;
    FBorderStyle: TFormBorderStyle;
    FSizeChanging: Boolean;
    FWindowState: TWindowState; { !! }
  end;

  THackComponent = class(TComponent);

{$HINTS ON}

procedure custom_LoadFormPosition(Form: TForm; Ini: TCustomIniFile; const LoadState, LoadPosition: Boolean);
var
  Section, PosStr: string;
  Placement: TWindowPlacement;
  WinState: TWindowState;
  DataFound, UpdateForm: Boolean;
begin
  if LoadState or LoadPosition then
  begin
    Placement.Length := SizeOf(TWindowPlacement);
    if GetWindowPlacement(Form.Handle, @Placement) then
    begin
      // Генерируем имя секции
      Section := GetFormIdf(Form);
      // Устанавливаем свойства формы
      if not IsWindowVisible(Form.Handle) then Placement.ShowCmd := SW_HIDE;
      UpdateForm := True;
      // Считываем позицию формы
      if LoadPosition then
      begin
        DataFound := False;
        Placement.Flags := Ini.ReadInteger(Section, siFlags, Placement.Flags);
        PosStr := Ini.ReadString(Section, Format(siMinMaxPosR, [Screen.Width, Screen.Height]), EmptyStr);
        if PosStr = EmptyStr then PosStr := Ini.ReadString(Section, siMinMaxPos, EmptyStr);
        if PosStr <> EmptyStr then
        begin
          DataFound := True;
          Placement.ptMinPosition.X := StrToIntDef(ExtractWord(1, PosStr, Delims), 0);
          Placement.ptMinPosition.Y := StrToIntDef(ExtractWord(2, PosStr, Delims), 0);
          Placement.ptMaxPosition.X := StrToIntDef(ExtractWord(3, PosStr, Delims), 0);
          Placement.ptMaxPosition.Y := StrToIntDef(ExtractWord(4, PosStr, Delims), 0);
        end;
        PosStr := Ini.ReadString(Section, Format(siNormPosR, [Screen.Width, Screen.Height]), EmptyStr);
        if PosStr = EmptyStr then PosStr := Ini.ReadString(Section, siNormPos, EmptyStr);
        if PosStr <> EmptyStr then
        begin
          DataFound := True;
          Placement.rcNormalPosition.Left := StrToIntDef(ExtractWord(1, PosStr, Delims), Form.Left);
          Placement.rcNormalPosition.Top := StrToIntDef(ExtractWord(2, PosStr, Delims), Form.Top);
          Placement.rcNormalPosition.Right := StrToIntDef(ExtractWord(3, PosStr, Delims), Form.Left + Form.Width);
          Placement.rcNormalPosition.Bottom := StrToIntDef(ExtractWord(4, PosStr, Delims), Form.Top + Form.Height);
        end;
        if Screen.PixelsPerInch <> Ini.ReadInteger(Section, siPixels,
          Screen.PixelsPerInch) then DataFound := False;
        if DataFound then
        begin
          if not (Form.BorderStyle in [bsSizeable, bsSizeToolWin]) then
            Placement.rcNormalPosition := Rect(Placement.rcNormalPosition.Left,
              Placement.rcNormalPosition.Top, Placement.rcNormalPosition.Left + Form.Width,
              Placement.rcNormalPosition.Top + Form.Height);
          if Placement.rcNormalPosition.Right > Placement.rcNormalPosition.Left then
          begin
            if (Form.Position in [poScreenCenter, poDesktopCenter]) and
              not (csDesigning in Form.ComponentState) then
            begin
              THackComponent(Form).SetDesigning(True);
              try
                Form.Position := poDesigned;
              finally
                THackComponent(Form).SetDesigning(False);
              end;
            end;
            SetWindowPlacement(Form.Handle, @Placement);
          end;
        end;
      end;
      // Считываем состояние формы
      if LoadState then
      begin
        WinState := wsNormal;
        if ((Application.MainForm = Form) or (Application.MainForm = nil))
        and ((Form.FormStyle = fsMDIForm) or ((Form.FormStyle = fsNormal)
        and (Form.Position = poDefault))) then WinState := wsMaximized;
        Placement.ShowCmd := Ini.ReadInteger(Section, siShowCmd, SW_HIDE);
        case Placement.ShowCmd of
          SW_SHOWNORMAL, SW_RESTORE, SW_SHOW:
            WinState := wsNormal;
          SW_MINIMIZE, SW_SHOWMINIMIZED, SW_SHOWMINNOACTIVE:
            WinState := wsMinimized;
          SW_MAXIMIZE: WinState := wsMaximized;
        end;
        if (WinState = wsMinimized) and ((Form = Application.MainForm)
        or (Application.MainForm = nil)) then
        begin
          TNastyForm(Form).FWindowState := wsNormal;
          PostMessage(Application.Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
          UpdateForm := False;
        end
        else begin
          if Form.FormStyle in [fsMDIChild, fsMDIForm] then
            TNastyForm(Form).FWindowState := WinState
          else Form.WindowState := WinState;
        end;
      end;
      if UpdateForm then Form.Update;
    end;
  end;
end;

procedure ini_LoadFormPosition(Form: TForm; const LoadState, LoadPosition: Boolean);
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    custom_LoadFormPosition(Form, Ini, LoadState, LoadPosition);
  finally
    Ini.Free;
  end;
end;

procedure reg_LoadFormPosition(Form: TForm; const LoadState, LoadPosition: Boolean);
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    custom_LoadFormPosition(Form, Reg, LoadState, LoadPosition);
  finally
    Reg.Free;
  end;
end;

{ == Сохранение произвольного параметра ======================================== }
procedure custom_SaveValueInt(Form: TForm; Ini: TCustomIniFile; const sName: string; iValue: Integer);
begin
  Ini.WriteInteger(GetFormIdf(Form), sName, iValue);
  Ini.UpdateFile;
end;

procedure ini_SaveValueInt(Form: TForm; const sName: string; iValue: Integer);
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    custom_SaveValueInt(Form, Ini, sName, iValue);
  finally
    Ini.Free;
  end;
end;

procedure reg_SaveValueInt(Form: TForm; const sName: string; iValue: Integer);
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    custom_SaveValueInt(Form, Reg, sName, iValue);
  finally
    Reg.Free;
  end;
end;

function custom_LoadValueInt(Form: TForm; Ini: TCustomIniFile; const sName: string; iDef: Integer): Integer;
begin
  Result := Ini.ReadInteger(GetFormIdf(Form), sName, iDef);
end;

function ini_LoadValueInt(Form: TForm; const sName: string; const iDef: Integer): Integer;
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    Result := custom_LoadValueInt(Form, Ini, sName, iDef);
  finally
    Ini.Free;
  end;
end;

function reg_LoadValueInt(Form: TForm; const sName: string; const iDef: Integer): Integer;
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    Result := custom_LoadValueInt(Form, Reg, sName, iDef);
  finally
    Reg.Free;
  end;
end;

procedure custom_SaveValueBool(Form: TForm; Ini: TCustomIniFile; const sName: string; iValue: Boolean);
begin
  Ini.WriteBool(GetFormIdf(Form), sName, iValue);
  Ini.UpdateFile;
end;

procedure ini_SaveValueBool(Form: TForm; const sName: string; iValue: Boolean);
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    custom_SaveValueBool(Form, Ini, sName, iValue);
  finally
    Ini.Free;
  end;
end;

procedure reg_SaveValueBool(Form: TForm; const sName: string; iValue: Boolean);
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    custom_SaveValueBool(Form, Reg, sName, iValue);
  finally
    Reg.Free;
  end;
end;

function custom_LoadValueBool(Form: TForm; Ini: TCustomIniFile; const sName: string; iDef: Boolean): Boolean;
begin
  Result := Ini.ReadBool(GetFormIdf(Form), sName, iDef);
end;

function ini_LoadValueBool(Form: TForm; const sName: string; const iDef: Boolean): Boolean;
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    Result := custom_LoadValueBool(Form, Ini, sName, iDef);
  finally
    Ini.Free;
  end;
end;

function reg_LoadValueBool(Form: TForm; const sName: string; const iDef: Boolean): Boolean;
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    Result := custom_LoadValueBool(Form, Reg, sName, iDef);
  finally
    Reg.Free;
  end;
end;

{ == Сохранение панелей TCoolBar =============================================== }
procedure custom_SaveCoolBar(Form: TForm; Ini: TCustomIniFile; CoolBar: TCoolBar);
var
  SectionName: string;
  i, iCount: Integer;
begin
  SectionName := GetFormIdf(Form);
  iCount := CoolBar.Bands.Count - 1;
  for i := 0 to iCount do
    Ini.WriteString(SectionName, Format(siCoolBar, [CoolBar.Name, i]),
      Format(siCoolBand, [CoolBar.Bands[i].Control.Name,
        BoolToStr(CoolBar.Bands[i].Visible),
        BoolToStr(CoolBar.Bands[i].Break),
        CoolBar.Bands[i].Width]));
  Ini.UpdateFile;
end;

procedure ini_SaveCoolBar(Form: TForm; CoolBar: TCoolBar);
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    custom_SaveCoolBar(Form, Ini, CoolBar);
  finally
    Ini.Free;
  end;
end;

procedure reg_SaveCoolBar(Form: TForm; CoolBar: TCoolBar);
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    custom_SaveCoolBar(Form, Reg, CoolBar);
  finally
    Reg.Free;
  end;
end;

procedure custom_LoadCoolBar(Form: TForm; Ini: TCustomIniFile; CoolBar: TCoolBar);
var
  SectionName, DataStr: string;
  Control: TControl;
  Band: TCoolBand;
  i: Integer;
begin
  SectionName := GetFormIdf(Form);
  i := 0;
  DataStr := Ini.ReadString(SectionName, Format(siCoolBar, [CoolBar.Name, i]), EmptyStr);
  while DataStr <> EmptyStr do
  begin
    Control := CoolBar.FindChildControl(Trim(ExtractWord(1, DataStr, Delims)));
    if Assigned(Control) then
    begin
      Band := CoolBar.Bands.FindBand(Control);
      if Assigned(Band) and (i < CoolBar.Bands.Count) then
      begin
        Band.Index := i;
        case WordCount(DataStr, Delims) of
          3:
          begin
            Band.Visible := True;
            Band.Break := StrToBoolDef(Trim(ExtractWord(2, DataStr, Delims)), Band.Break);
            Band.Width := StrToIntDef(Trim(ExtractWord(3, DataStr, Delims)), Band.Width);
          end;
          4:
          begin
            Band.Visible := StrToBoolDef(Trim(ExtractWord(2, DataStr, Delims)), Band.Visible);
            Band.Break := StrToBoolDef(Trim(ExtractWord(3, DataStr, Delims)), Band.Break);
            Band.Width := StrToIntDef(Trim(ExtractWord(4, DataStr, Delims)), Band.Width);
          end;
        end;
      end;
    end;
    Inc(i);
    DataStr := Ini.ReadString(SectionName, Format(siCoolBar, [CoolBar.Name, i]), EmptyStr);
  end;
end;

procedure ini_LoadCoolBar(Form: TForm; CoolBar: TCoolBar);
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    custom_LoadCoolBar(Form, Ini, CoolBar);
  finally
    Ini.Free;
  end;
end;

procedure reg_LoadCoolBar(Form: TForm; CoolBar: TCoolBar);
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    custom_LoadCoolBar(Form, Reg, CoolBar);
  finally
    Reg.Free;
  end;
end;

{ == Сохранение ширины столбцов ListView ======================================= }
procedure custom_SaveListColumns(Form: TForm; Ini: TCustomIniFile; ListView: TListView; const SaveState: Boolean = True);
var
  SectionName: string;
  i, iCount: Integer;
begin
  SectionName := GetFormIdf(Form);
  if SaveState then
  begin
    Ini.WriteBool(SectionName, Format(siListGridLines, [ListView.Name]), ListView.GridLines);
    Ini.WriteBool(SectionName, Format(siListMultiSelect, [ListView.Name]), ListView.MultiSelect);
  end;
  iCount := ListView.Columns.Count - 1;
  for i := 0 to iCount do
    Ini.WriteInteger(SectionName, Format(siListColumn, [ListView.Name, i]),
      ListView.Columns[i].Width);
  Ini.UpdateFile;
end;

procedure ini_SaveListColumns(Form: TForm; ListView: TListView; const SaveState: Boolean = True);
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    custom_SaveListColumns(Form, Ini, ListView, SaveState);
  finally
    Ini.Free;
  end;
end;

procedure reg_SaveListColumns(Form: TForm; ListView: TListView; const SaveState: Boolean = True);
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    custom_SaveListColumns(Form, Reg, ListView, SaveState);
  finally
    Reg.Free;
  end;
end;

procedure custom_LoadListColumns(Form: TForm; Ini: TCustomIniFile; ListView: TListView; const LoadState: Boolean = True);
var
  SectionName: string;
  i, iCount: Integer;
begin
  SectionName := GetFormIdf(Form);
  if LoadState then
  begin
    ListView.GridLines := Ini.ReadBool(SectionName, Format(siListGridLines, [ListView.Name]), ListView.GridLines);
    ListView.MultiSelect := Ini.ReadBool(SectionName, Format(siListMultiSelect, [ListView.Name]), ListView.MultiSelect);
  end;
  iCount := ListView.Columns.Count - 1;
  for i := 0 to iCount do
    ListView.Columns[i].Width := Ini.ReadInteger(SectionName,
      Format(siListColumn, [ListView.Name, i]), ListView.Columns[i].Width);
end;

procedure ini_LoadListColumns(Form: TForm; ListView: TListView; const LoadState: Boolean = True);
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    custom_LoadListColumns(Form, Ini, ListView, LoadState);
  finally
    Ini.Free;
  end;
end;

procedure reg_LoadListColumns(Form: TForm; ListView: TListView; const LoadState: Boolean = True);
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    custom_LoadListColumns(Form, Reg, ListView, LoadState);
  finally
    Reg.Free;
  end;
end;

{ == Сохранение ширины столбцов TCustomGrid ====================================== }
procedure custom_SaveGridColumns(Form: TForm; Ini: TCustomIniFile; Grid: TDrawGrid);
var
  SectionName: string;
  i, iCount: Integer;
begin
  SectionName := GetFormIdf(Form);
  iCount := Grid.ColCount - 1;
  for i := 0 to iCount do
    Ini.WriteInteger(SectionName, Format(siGridColumn, [Grid.Name, i]), Grid.ColWidths[i]);
  Ini.UpdateFile;
end;

procedure ini_SaveGridColumns(Form: TForm; Grid: TDrawGrid);
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    custom_SaveGridColumns(Form, Ini, Grid);
  finally
    Ini.Free;
  end;
end;

procedure reg_SaveGridColumns(Form: TForm; Grid: TDrawGrid);
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    custom_SaveGridColumns(Form, Reg, Grid);
  finally
    Reg.Free;
  end;
end;

procedure custom_LoadGridColumns(Form: TForm; Ini: TCustomIniFile; Grid: TDrawGrid);
var
  SectionName: string;
  i, iCount: Integer;
begin
  SectionName := GetFormIdf(Form);
  iCount := Grid.ColCount - 1;
  for i := 0 to iCount do
    Grid.ColWidths[i] := Ini.ReadInteger(SectionName, Format(siGridColumn, [Grid.Name, i]), Grid.ColWidths[i]);
end;

procedure ini_LoadGridColumns(Form: TForm; Grid: TDrawGrid);
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ini_GetModuleFormFile);
  try
    custom_LoadGridColumns(Form, Ini, Grid);
  finally
    Ini.Free;
  end;
end;

procedure reg_LoadGridColumns(Form: TForm; Grid: TDrawGrid);
var
  Reg: TRegistryIniFile;
begin
  Reg := TRegistryIniFile.Create(reg_GetFormRegKey(Form));
  try
    custom_LoadGridColumns(Form, Reg, Grid);
  finally
    Reg.Free;
  end;
end;

end.
