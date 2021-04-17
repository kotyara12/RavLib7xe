unit rVclUtils;

interface

uses
  Classes, Controls, SysUtils;

type
  RId2 = record
    iId1: Integer;
    iId2: Integer;
  end;

  RKindId = record
    Id: Integer;
    Kind: Integer;
  end;

  TTextStyle = ^RTextStyle;
  RTextStyle = record
    FontStyle: Integer;
    FontColor: Integer;
    BackColor: Integer;
  end;

  TIntegerObject = class (TObject)
  private
    fValue: Integer;
  public
    constructor Create(const aValue: Integer);
    property Value: Integer read fValue write fValue;
  end;

  TId              = ^Integer;
  TId2             = ^RId2;
  TKindId          = ^RKindId;

  TByteSet         = set of Byte;

  EDllException    = class(Exception);
  EDLLLoadError    = class(Exception);
  EDLLCantFindProc = class(Exception);

const
  intDisable                   = -1;
  intFieldToColumnWidth        = 6;

  // �������������� ����� �������
  SNullText                    = '<NULL>';
  SBlobText                    = '{DATA}';
  SNoneText                    = '???';
  SFieldText                   = '%s="%s"';

  // ���������� ������
  SAnyFile                     = '*.*';
  SIniExt                      = '.ini';

  // ����������� ������� "�� ���������"
  chListDivChar                = ',';
  chDefDivChar                 = ';';
  chDivChars                   = [',',';'];

  // ����������� ���� ��������
  tagDbUpdate                  = 9995;
  tagError                     = 9998;

  // ���� �����������
  imBm_Properties              = 9;
  imBm_Folder                  = 26;
  imBm_OpenFolder              = 27;

  imOk                         = 0;
  imCancel                     = 1;
  imSave                       = -1;
  imNew                        = 8;
  imEdit                       = 9;
  imDeleted                    = 10;
  imLink                       = 28;
  imFree                       = 29;

  cEOF                         = #13#10;
  cCR                          = #10;
  cLF                          = #13;
  cTAB                         = #9;

{ == ��������, �������� �� �������� � ������������ ������ ====================== }
function ValueInList(const Value: Integer; const ValuesList: array of Integer): Boolean;
{ == ����� ������� �� ����� ��������� ���������� =============================== }
procedure StartWait;
procedure StopWait;
procedure ExitWait;
procedure PauseWait;
procedure ContiniueWait;
function  IsNotWait: Boolean;
{ == ���������� ��������� ���������� =========================================== }
procedure ToggleControls(Control: TWinControl; const Enabled: Boolean);
{ == ����� ���������� � ������� ������ ������� ���������� ====================== }
procedure ShowInStatusBar(const Msg: string);
procedure ShowInStatusBarPanel(const Panel: Integer; Msg: string);
{ == �������� ���������� ��������� ============================================= }
procedure Delay(MSecs: Longint);
{ == ��������� ������ RKindId ================================================== }
function  KindId(const AId, AKind: Integer): RKindId;
{ == ���������� �������������� Boolean � ������ � ������� ====================== }
function RBoolToStr(const aValue: Boolean): string;
function RStrToBool(const aValue: string): Boolean;
{ == �������������� ������ � ����� (������ ������� ������������) =============== }
function RIntToStr(const aValue: Integer): string;
function RFloatToStr(const aValue: Extended): string;
function RStrToInt(const StrValue: string): Integer;
function RStrToIntDef(const StrValue: string; const DefValue: Integer): Integer;
function RStrToFloat(const StrValue: string): Extended;
function RStrToFloatDef(const StrValue: string; const DefValue: Extended): Extended;
{ == �������������� ��������� � ����� ========================================== }
function RVarToInteger(const VarValue: Variant): Integer;

implementation

uses
  Forms, Windows, StdCtrls, ComCtrls, Variants;

const
  StatusBarName = 'StatusBar';

var
  iWaitCount, tWaitCount: Integer;

{ TIntegerObject }

constructor TIntegerObject.Create(const aValue: Integer);
begin
  inherited Create;

  fValue := aValue;
end;

{ == ��������, �������� �� �������� � ������������ ������ ====================== }
function ValueInList(const Value: Integer; const ValuesList: array of Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := Low(ValuesList) to High(ValuesList) do
  begin
    Result := Value = ValuesList[i];
    if Result then Break;
  end;
end;

{ == ����� ������� �� ����� ��������� ���������� =============================== }

procedure StartWait;
begin
  Inc(iWaitCount);
  Screen.Cursor := crHourGlass;
end;

procedure StopWait;
begin
  if iWaitCount > 0 then Dec(iWaitCount);
  if iWaitCount = 0 then Screen.Cursor := crDefault;
end;

procedure ExitWait;
begin
  iWaitCount := 0;
  Screen.Cursor := crDefault;
end;

function IsNotWait: Boolean;
begin
  Result := iWaitCount = 0;
end;

procedure PauseWait;
begin
  tWaitCount := iWaitCount;
  ExitWait;
end;

procedure ContiniueWait;
begin
  iWaitCount := tWaitCount;
  if iWaitCount = 0 then Screen.Cursor := crDefault else Screen.Cursor := crHourGlass;
end;

{ == ���������� ��������� ���������� =========================================== }
procedure ToggleControls(Control: TWinControl; const Enabled: Boolean);
var
  i: Integer;
begin
  for i := 0 to Control.ControlCount - 1 do
  begin
    if Control.Controls[i] is TWinControl
    then ToggleControls(TWinControl(Control.Controls[i]), Enabled);
    if not (Control.Controls[i] is TLabel) then
      Control.Controls[i].Enabled := Enabled;
  end;
end;

{ == ����� ���������� � ������� ������ ������� ���������� ====================== }
procedure ShowInStatusBar(const Msg: string);
var
  Sb: TStatusBar;
begin
  if Assigned(Application.MainForm) then
  begin
    Sb := TStatusBar(Application.MainForm.FindComponent(StatusBarName));
    if Assigned(Sb) then
    begin
      if Sb.SimplePanel
      then Sb.SimpleText := Msg
      else Sb.Panels[Sb.Tag].Text := Msg;
    end;
  end;
  Application.ProcessMessages;
end;

procedure ShowInStatusBarPanel(const Panel: Integer; Msg: string);
var
  Sb: TStatusBar;
begin
  Sb := TStatusBar(Application.MainForm.FindComponent(StatusBarName));
  if Assigned(Sb) then Sb.Panels[Panel].Text := Msg;
  Application.ProcessMessages;
end;

{ == �������� ���������� ��������� ============================================= }
procedure Delay(MSecs: Longint);
var
  FirstTickCount, Now: Longint;
begin
  FirstTickCount := GetTickCount;
  repeat
    Application.ProcessMessages;
    Now := GetTickCount;
  until (Now - FirstTickCount >= MSecs) or (Now < FirstTickCount);
end;

{ == ��������� ������ RKindId ================================================== }
function KindId(const AId, AKind: Integer): RKindId;
begin
  Result.Id := AId;
  Result.Kind := AKind;
end;

{ == ���������� �������������� Boolean � ������ � ������� ====================== }
function RBoolToStr(const aValue: Boolean): string;
begin
  if aValue then Result := '1' else Result := '0';
end;

function RStrToBool(const aValue: string): Boolean;
begin
  Result := aValue = '1';
end;

{ == �������������� ������ � ����� (������ ������� ������������) =============== }
function RIntToStr(const aValue: Integer): string;
var
  i: Integer;
begin
  Result := IntToStr(aValue);

  i := Length(Result) - 2;
  while i > 1 do
  begin
    Insert(#32, Result, i);
    i := i - 3;
  end;
end;

function RFloatToStr(const aValue: Extended): string;
begin
  Result := StringReplace(FloatToStr(aValue), FormatSettings.DecimalSeparator, '.', [rfReplaceAll]);
end;

function RStrToInt(const StrValue: string): Integer;
var
  i: Integer;
  IntValue: string;
begin
  IntValue := EmptyStr;
  for i := 1 to Length(StrValue) do
    if CharInSet(StrValue[i], ['-','0'..'9']) then
      IntValue := IntValue + StrValue[i];
  Result := StrToInt(IntValue);
end;

function RStrToIntDef(const StrValue: string; const DefValue: Integer): Integer;
var
  i: Integer;
  IntValue: string;
begin
  IntValue := EmptyStr;
  for i := 1 to Length(StrValue) do
    if CharInSet(StrValue[i], ['-','0'..'9']) then
      IntValue := IntValue + StrValue[i];
  Result := StrToIntDef(IntValue, DefValue);
end;


function RStrToFloat(const StrValue: string): Extended;
var
  i: Integer;
  IntValue: string;
begin
  IntValue := EmptyStr;
  for i := 1 to Length(StrValue) do
    if CharInSet(StrValue[i], ['-','0'..'9']) then
      IntValue := IntValue + StrValue[i]
    else begin
      if CharInSet(StrValue[i], ['.',',',FormatSettings.DecimalSeparator]) then
        IntValue := IntValue + FormatSettings.DecimalSeparator;
    end;
  Result := StrToFloat(IntValue);
end;

function RStrToFloatDef(const StrValue: string; const DefValue: Extended): Extended;
var
  i: Integer;
  IntValue: string;
begin
  IntValue := EmptyStr;
  for i := 1 to Length(StrValue) do
    if CharInSet(StrValue[i], ['-','0'..'9']) then
      IntValue := IntValue + StrValue[i]
    else begin
      if CharInSet(StrValue[i], ['.',',', FormatSettings.DecimalSeparator]) then
        IntValue := IntValue + FormatSettings.DecimalSeparator;
    end;
  Result := StrToFloatDef(IntValue, DefValue);
end;

{ == �������������� ��������� � ����� ========================================== }
function RVarToInteger(const VarValue: Variant): Integer;
begin
  if not VarIsNull(VarValue) and VarIsOrdinal(VarValue) then
    Result := VarValue
  else
    Result := -1
end;

initialization
  iWaitCount := 0;
  tWaitCount := 0;

end.
