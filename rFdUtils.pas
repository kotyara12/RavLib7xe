unit rFdUtils;

interface

uses
  System.Classes, Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Consts, FireDAC.Stan.Error,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Stan.ExprFuncs, FireDAC.Comp.Client, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet;

const
  S_FD_FileExt_SQLite = '.db';
  S_FD_CreateUTF8 = 'CreateUTF8';
  S_FD_CreateUTF16 = 'CreateUTF16';
  S_FD_ReadWrite = 'ReadWrite';
  S_FD_ReadOnly = 'ReadOnly';
  S_FD_Normal = 'Normal';
  S_FD_Exclusive = 'Exclusive';
  S_FD_Full = 'Full';

function  fdOpenDb(const sConnStr: string): TFDConnection; overload;
procedure fdFreeDb(var fdDb: TFDConnection);

function  fdOpenDb_SQLite(const sDatabaseName: string;
  const sOpenMode: string = S_FD_ReadWrite;
  const sLockMode: string = S_FD_Exclusive): TFDConnection; overload;
function  fdOpenDb_SQLite: TFDConnection; overload;

function  fdQueryOpen(const fdDb: TFDConnection; const sSQL: string; const sName: string = ''): TFDQuery;
procedure fdQueryExec(const fdDb: TFDConnection; const sSQL: string; const sName: string = '');

function  fdTableOpen(const fdDb: TFDConnection; const sTableName, sIndexFieldNames: string; const sName: string = ''): TFDTable; overload;
function  fdTableOpen(const fdDb: TFDConnection; const sTableName: string; const sName: string = ''): TFDTable; overload;

function  fdDataSetIsOpen(fdDataSet: TFDDataSet): Boolean;
function  fdDataSetIsNotEmpty(fdDataSet: TFDDataSet): Boolean;
procedure fdDataSetFree(fdDataSet: TFDDataSet);

function  fdSPAddParamBoolean(fdSP: TFDStoredProc; const aName: string; const aValue: Boolean): TFDParam;
function  fdSPAddParamByte(fdSP: TFDStoredProc; const aName: string; const aValue: Byte; const bZeroNull: Boolean): TFDParam;
function  fdSPAddParamWord(fdSP: TFDStoredProc; const aName: string; const aValue: Word; const bZeroNull: Boolean): TFDParam;
function  fdSPAddParamInteger(fdSP: TFDStoredProc; const aName: string; const aValue: Integer; const bZeroNull: Boolean): TFDParam;
function  fdSPAddParamInt64(fdSP: TFDStoredProc; const aName: string; const aValue: Int64; const bZeroNull: Boolean): TFDParam;
function  fdSPAddParamCurrency(fdSP: TFDStoredProc; const aName: string; const aValue: Currency; const bZeroNull: Boolean): TFDParam;
function  fdSPAddParamBCD(fdSP: TFDStoredProc; const aName: string; const aValue: Currency; const bZeroNull: Boolean): TFDParam;
function  fdSPAddParamDateTime(fdSP: TFDStoredProc; const aName: string; const aValue: TDateTime; const bZeroNull: Boolean): TFDParam;
function  fdSPAddParamDateTimeStamp(fdSP: TFDStoredProc; const aName: string; const aValue: TDateTime; const bZeroNull: Boolean): TFDParam;
function  fdSPAddParamAnsiString(fdSP: TFDStoredProc; const aName: string; const aValue: AnsiString; const bZeroNull: Boolean): TFDParam;
function  fdSPAddParamWideString(fdSP: TFDStoredProc; const aName: string; const aSize: Integer; const aValue: string; const bZeroNull: Boolean): TFDParam;
function  fdSPAddParamAnsiMemo(fdSP: TFDStoredProc; const aName: string; const aSize: Integer; const aValue: AnsiString; const bZeroNull: Boolean): TFDParam;
function  fdSPAddParamWideMemo(fdSP: TFDStoredProc; const aName: string; const aSize: Integer; const aValue: string; const bZeroNull: Boolean): TFDParam;

implementation

uses
  System.SysUtils, Vcl.Forms,
  Winapi.ActiveX;

const
  S_FD_QueryTemplate         = 'fdQuery_%s';
  S_FD_TableTemplate         = 'fdTable_%s';


{ == Fire DAC Connection ======================================================= }

function fdOpenDb(const sConnStr: string): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  Result.LoginPrompt := False;
  Result.Open(sConnStr);
end;

procedure fdFreeDb(var fdDb: TFDConnection);
begin
  if Assigned(fdDb) then
  begin
    fdDb.Close;
    FreeAndNil(fdDb);
  end;
end;

{ -- SQLite -------------------------------------------------------------------- }

function fdOpenDb_SQLite(const sDatabaseName: string;
  const sOpenMode: string = S_FD_ReadWrite;
  const sLockMode: string = S_FD_Exclusive): TFDConnection;
const
  csSQLite = '%s=%s;%s=%s;%s=%s;%s=%s';
begin
  Result := fdOpenDb(Format(csSQLite,
    [S_FD_ConnParam_Common_DriverID, S_FD_SQLiteId,
     S_FD_ConnParam_Common_Database, sDatabaseName,
     S_FD_ConnParam_SQLite_OpenMode, sOpenMode,
     S_FD_ConnParam_SQLite_LockingMode, sLockMode]));
end;

function fdOpenDb_SQLite: TFDConnection;
begin
  Result := fdOpenDb_SQLite(
    ChangeFileExt(Application.ExeName, S_FD_FileExt_SQLite),
    S_FD_ReadWrite, S_FD_Normal);
end;

{ == Tables & Queries ========================================================== }

function fdCreateQueryName(const sTemplate: string): string;
var
  ID: TGUID;
begin
  Result := EmptyStr;
  if CoCreateGuid(ID) = S_OK then
    Result := Format(sTemplate, [StringReplace(Copy(GUIDToString(ID), 2, 36), '-', '_', [rfReplaceAll, rfIgnoreCase])]);
end;

function fdQueryOpen(const fdDb: TFDConnection; const sSQL: string; const sName: string = ''): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  try
    if sName = EmptyStr
    then Result.Name := fdCreateQueryName(S_FD_QueryTemplate)
    else Result.Name := sName;
    Result.Connection := fdDb;

    Result.Open(sSQL);
  except
    fdDataSetFree(Result);
    raise;
  end;
end;

procedure fdQueryExec(const fdDb: TFDConnection; const sSQL: string; const sName: string = '');
var
  fdQuery: TFDQuery;
begin
  fdQuery := TFDQuery.Create(nil);
  try
    if sName = EmptyStr
    then fdQuery.Name := fdCreateQueryName(S_FD_QueryTemplate)
    else fdQuery.Name := sName;
    fdQuery.Connection := fdDb;

    fdQuery.ExecSQL(sSQL);
  finally
    fdDataSetFree(fdQuery);
  end;
end;

function fdTableOpen(const fdDb: TFDConnection; const sTableName, sIndexFieldNames: string; const sName: string = ''): TFDTable;
begin
  Result := TFDTable.Create(nil);
  if sName = EmptyStr
  then Result.Name := fdCreateQueryName(S_FD_TableTemplate)
  else Result.Name := sName;
  Result.Connection := fdDb;
  if sIndexFieldNames <> EmptyStr then
    Result.IndexFieldNames := sIndexFieldNames;
  try
    Result.Open(sTableName);
  except
    fdDataSetFree(Result);
    raise;
  end;
end;

function fdTableOpen(const fdDb: TFDConnection; const sTableName: string; const sName: string = ''): TFDTable;
begin
  Result := fdTableOpen(fdDb, sTableName, EmptyStr, sName);
end;

function fdDataSetIsOpen(fdDataSet: TFDDataSet): Boolean;
begin
  Result := Assigned(fdDataSet) and fdDataSet.Active;
end;

function fdDataSetIsNotEmpty(fdDataSet: TFDDataSet): Boolean;
begin
  Result := Assigned(fdDataSet) and fdDataSet.Active and not fdDataSet.IsEmpty;
end;

procedure fdDataSetFree(fdDataSet: TFDDataSet);
begin
  if Assigned(fdDataSet) then
  begin
    if fdDataSet.Active then fdDataSet.Close;
    FreeAndNil(fdDataSet);
  end;
end;

{ == Stored Procs ============================================================== }

function fdSPAddParamBoolean(fdSP: TFDStoredProc; const aName: string; const aValue: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftBoolean;
    Result.FDDataType := dtBoolean;
    Result.AsBoolean := aValue;
  end;
end;

function fdSPAddParamByte(fdSP: TFDStoredProc; const aName: string; const aValue: Byte; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftByte;
    Result.FDDataType := dtByte;
    if bZeroNull and (aValue = 0)
    then Result.Clear
    else Result.AsByte := aValue;
  end;
end;

function fdSPAddParamWord(fdSP: TFDStoredProc; const aName: string; const aValue: Word; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftWord;
    Result.FDDataType := dtUInt16;
    if bZeroNull and (aValue = 0)
    then Result.Clear
    else Result.AsWord := aValue;
  end;
end;

function fdSPAddParamInteger(fdSP: TFDStoredProc; const aName: string; const aValue: Integer; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftInteger;
    Result.FDDataType := dtInt32;
    if bZeroNull and (aValue = 0)
    then Result.Clear
    else Result.AsInteger := aValue;
  end;
end;

function fdSPAddParamInt64(fdSP: TFDStoredProc; const aName: string; const aValue: Int64; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftLargeint;
    Result.FDDataType := dtInt64;
    if bZeroNull and (aValue = 0)
    then Result.Clear
    else Result.AsLargeInt := aValue;
  end;
end;

function fdSPAddParamCurrency(fdSP: TFDStoredProc; const aName: string; const aValue: Currency; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftCurrency;
    Result.FDDataType := dtCurrency;
    if bZeroNull and (aValue = 0)
    then Result.Clear
    else Result.AsCurrency := aValue;
  end;
end;

function fdSPAddParamBCD(fdSP: TFDStoredProc; const aName: string; const aValue: Currency; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftBCD;
    Result.FDDataType := dtBCD;
    if bZeroNull and (aValue = 0)
    then Result.Clear
    else Result.AsBCD := aValue;
  end;
end;

function fdSPAddParamDateTime(fdSP: TFDStoredProc; const aName: string; const aValue: TDateTime; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftDateTime;
    Result.FDDataType := dtDateTime;
    if bZeroNull and (aValue = 0)
    then Result.Clear
    else Result.AsDateTime := aValue;
  end;
end;

function fdSPAddParamDateTimeStamp(fdSP: TFDStoredProc; const aName: string; const aValue: TDateTime; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftTimeStamp;
    Result.FDDataType := dtDateTimeStamp;
    if bZeroNull and (aValue = 0)
    then Result.Clear
    else Result.AsDateTime := aValue;
  end;
end;

function fdSPAddParamAnsiString(fdSP: TFDStoredProc; const aName: string; const aValue: AnsiString; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftString;
    Result.FDDataType := dtAnsiString;
    if bZeroNull and (aValue = '')
    then Result.Clear
    else Result.AsAnsiString := aValue;
  end;
end;

function fdSPAddParamWideString(fdSP: TFDStoredProc; const aName: string; const aSize: Integer; const aValue: string; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftWideString;
    Result.FDDataType := dtWideString;
    Result.Size := aSize;
    if bZeroNull and (aValue = '')
    then Result.Clear
    else Result.AsWideString := aValue;
  end;
end;

function fdSPAddParamAnsiMemo(fdSP: TFDStoredProc; const aName: string; const aSize: Integer; const aValue: AnsiString; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftMemo;
    Result.FDDataType := dtMemo;
    Result.Size := aSize;
    if bZeroNull and (aValue = '')
    then Result.Clear
    else Result.AsMemo := aValue;
  end;
end;

function fdSPAddParamWideMemo(fdSP: TFDStoredProc; const aName: string; const aSize: Integer; const aValue: string; const bZeroNull: Boolean): TFDParam;
begin
  Result := fdSP.Params.Add;
  with Result do
  begin
    Result.Position := fdSP.Params.Count + 1;
    {$IFDEF MSSQL}
    Result.Name := '@' + aName;
    {$ELSE}
    Result.Name := aName;
    {$ENDIF}
    Result.ParamType := ptInput;
    Result.DataType := ftWideMemo;
    Result.FDDataType := dtWideMemo;
    Result.Size := aSize;
    if bZeroNull and (aValue = '')
    then Result.Clear
    else Result.AsWideMemo := aValue;
  end;
end;

end.
