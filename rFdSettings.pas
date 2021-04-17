unit rFdSettings;

interface

uses
  Controls, FireDAC.Comp.Client;

const
  tnSysSettings  = 'ss_settings';

{ Проверка существования записи в таблице системных настроек }
function  fdDbsIsExists(fdDb: TFDConnection; const aId: Integer): Boolean;
{ Чтение значения из таблицы системных настроек }
function  fdDbsReadInteger(fdDb: TFDConnection; const aId, aDef: Integer): Integer;
function  fdDbsReadFloat(fdDb: TFDConnection; const aId: Integer; const aDef: Double): Double;
function  fdDbsReadDateTime(fdDb: TFDConnection; const aId: Integer; const aDef: TDateTime): TDateTime;
function  fdDbsReadDate(fdDb: TFDConnection; const aId: Integer; const aDef: TDate): TDate;
function  fdDbsReadTime(fdDb: TFDConnection; const aId: Integer; const aDef: TTime): TTime;
function  fdDbsReadString(fdDb: TFDConnection; const aId: Integer; const aDef: string): string;
function  fdDbsReadBoolean(fdDb: TFDConnection; const aId: Integer; const aDef: Boolean): Boolean;
{ Схранение значения в таблицев системных настроек }
procedure fdDbsSaveInteger(fdDb: TFDConnection; const aId, aValue: Integer);
procedure fdDbsSaveFloat(fdDb: TFDConnection; const aId: Integer; const aValue: Double);
procedure fdDbsSaveDateTime(fdDb: TFDConnection; const aId: Integer; const aValue: TDateTime);
procedure fdDbsSaveDate(fdDb: TFDConnection; const aId: Integer; const aValue: TDate);
procedure fdDbsSaveTime(fdDb: TFDConnection; const aId: Integer; const aValue: TTime);
procedure fdDbsSaveString(fdDb: TFDConnection; const aId: Integer; const aValue: string);
procedure fdDbsSaveBoolean(fdDb: TFDConnection; const aId: Integer; const aValue: Boolean);

implementation

uses
  SysUtils, DateUtils, rDbUtils, rFdUtils;

const
  sqlReadDbSettings    = 'SELECT %s FROM ss_settings WHERE id=%d';

function fdDbsReadInteger(fdDb: TFDConnection; const aId, aDef: Integer): Integer;
var
  qrySettings: TFDQuery;
begin
  Result := aDef;
  qrySettings := fdQueryOpen(fdDb, Format(sqlReadDbSettings, [fnVALUE_INT, aId]));
  try
    if fdDataSetIsNotEmpty(qrySettings) then
      Result := qrySettings.FieldByName(fnVALUE_INT).AsInteger;
  finally
    fdDataSetFree(qrySettings);
  end;
end;

function fdDbsReadFloat(fdDb: TFDConnection; const aId: Integer; const aDef: Double): Double;
var
  qrySettings: TFDQuery;
begin
  Result := aDef;
  qrySettings := fdQueryOpen(fdDb, Format(sqlReadDbSettings, [fnVALUE_REAL, aId]));
  try
    if fdDataSetIsNotEmpty(qrySettings) then
      Result := qrySettings.FieldByName(fnVALUE_REAL).AsFloat;
  finally
    fdDataSetFree(qrySettings);
  end;
end;

function fdDbsReadDateTime(fdDb: TFDConnection; const aId: Integer; const aDef: TDateTime): TDateTime;
begin
  Result := TDateTime(fdDbsReadFloat(fdDb, aId, aDef));
end;

function fdDbsReadDate(fdDb: TFDConnection; const aId: Integer; const aDef: TDate): TDate;
begin
  Result := DateOf(fdDbsReadDateTime(fdDb, aId, aDef));
end;

function fdDbsReadTime(fdDb: TFDConnection; const aId: Integer; const aDef: TTime): TTime;
begin
  Result := TimeOf(fdDbsReadDateTime(fdDb, aId, aDef));
end;

function fdDbsReadString(fdDb: TFDConnection; const aId: Integer; const aDef: string): string;
var
  qrySettings: TFDQuery;
begin
  Result := aDef;
  qrySettings := fdQueryOpen(fdDb, Format(sqlReadDbSettings, [fnVALUE_CHAR, aId]));
  try
    if fdDataSetIsNotEmpty(qrySettings) then
      Result := qrySettings.FieldByName(fnVALUE_CHAR).AsWideString;
  finally
    fdDataSetFree(qrySettings);
  end;
end;

function fdDbsReadBoolean(fdDb: TFDConnection; const aId: Integer; const aDef: Boolean): Boolean;
begin
  if aDef
  then Result := fdDbsReadInteger(fdDb, aId, 1) <> 0
  else Result := fdDbsReadInteger(fdDb, aId, 0) <> 0;
end;

{ == Проверка существования записи в таблице системных нстроек ================= }
function fdDbsIsExists(fdDb: TFDConnection; const aId: Integer): Boolean;
const
  sqlValueIsExists     = 'SELECT Count(*) AS cnt FROM ss_settings WHERE id=%d';
var
  qrySettings: TFDQuery;
begin
  Result := False;
  qrySettings := fdQueryOpen(fdDb, Format(sqlValueIsExists, [aId]));
  try
    if fdDataSetIsNotEmpty(qrySettings) then
      Result := qrySettings.FieldByName(fnCOUNT).AsInteger > 0;
  finally
    fdDataSetFree(qrySettings);
  end;
end;

{ == Сохранение значения в таблицев системных настроек ========================= }
procedure fdDbsSaveInteger(fdDb: TFDConnection; const aId, aValue: Integer);
const
  sqlNewIntValue  = 'INSERT INTO ss_settings (id, ' + fnVALUE_INT + ') VALUES (%d, %d)';
  sqlSaveIntValue = 'UPDATE ss_settings SET ' + fnVALUE_INT + '=%d WHERE id=%d';
begin
  if fdDbsIsExists(fdDb, aId)
  then fdQueryExec(fdDb, Format(sqlSaveIntValue, [aValue, aId]))
  else fdQueryExec(fdDb, Format(sqlNewIntValue, [aId, aValue]));
end;

procedure fdDbsSaveFloat(fdDb: TFDConnection; const aId: Integer; const aValue: Double);
const
  sqlNewIntValue  = 'INSERT INTO ss_settings (id, ' + fnVALUE_REAL + ') VALUES (%d, %s)';
  sqlSaveIntValue = 'UPDATE ss_settings SET ' + fnVALUE_REAL + '=%s WHERE id=%d';
var
  sqlValue: string;
begin
  sqlValue := dbFloatToSQL(aValue);
  if fdDbsIsExists(fdDb, aId)
  then fdQueryExec(fdDb, Format(sqlSaveIntValue, [sqlValue, aId]))
  else fdQueryExec(fdDb, Format(sqlNewIntValue, [aId, sqlValue]));
end;

procedure fdDbsSaveDateTime(fdDb: TFDConnection; const aId: Integer; const aValue: TDateTime);
begin
  fdDbsSaveFloat(fdDb, aId, aValue);
end;

procedure fdDbsSaveDate(fdDb: TFDConnection; const aId: Integer; const aValue: TDate);
begin
  fdDbsSaveDateTime(fdDb, aId, DateOf(aValue));
end;

procedure fdDbsSaveTime(fdDb: TFDConnection; const aId: Integer; const aValue: TTime);
begin
  fdDbsSaveDateTime(fdDb, aId, TimeOf(aValue));
end;

procedure fdDbsSaveString(fdDb: TFDConnection; const aId: Integer; const aValue: string);
const
  sqlNewIntValue  = 'INSERT INTO ss_settings (id, ' + fnVALUE_CHAR + ') VALUES (%d, ''%s'')';
  sqlSaveIntValue = 'UPDATE ss_settings SET ' + fnVALUE_CHAR + '=''%s'' WHERE id=%d';
begin
  if fdDbsIsExists(fdDb, aId)
  then fdQueryExec(fdDb, Format(sqlSaveIntValue, [dbTextToSQL(aValue, 255), aId]))
  else fdQueryExec(fdDb, Format(sqlNewIntValue, [aId, dbTextToSQL(aValue, 255)]));
end;

procedure fdDbsSaveBoolean(fdDb: TFDConnection; const aId: Integer; const aValue: Boolean);
begin
  if aValue
  then fdDbsSaveInteger(fdDb, aId, 1)
  else fdDbsSaveInteger(fdDb, aId, 0);
end;

end.
