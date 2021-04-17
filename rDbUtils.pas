unit rDbUtils;

interface

const
  fnID                   = 'id';
  fnID_REF               = 'id_%s';
  fnGUID                 = 'guid';
  fnOWNER_ID             = 'owner_id';
  fnGROUP_ID             = 'id_groups';
  fnFULLNAME             = 'fullname';
  fnPASSWORD             = 'password';
  fnNAME                 = 'name';
  fnNAME_S               = 'name_s';
  fnNOTES                = 'notes';
  fnNUMBER               = 'number';
  fnDATE                 = 'date';
  fnCOUNT                = 'cnt';
  fnCELLCOLOR            = 'cell_color';
  fnFONTCOLOR            = 'font_color';
  fnFONTSTYLE            = 'font_style';
  fnTYPE                 = 'type';
  fnMODE                 = 'mode';
  fnDEF_VALUE            = 'def_value';
  fnVALUE_INT            = 'value_int';
  fnVALUE_CHAR           = 'value_char';
  fnVALUE_REAL           = 'value_real';
  fnVARIABLES            = 'variables';
  fnCREATED              = 'created';
  fnDELETED              = 'deleted';
  fnBLOCKED              = 'blocked';
  fnCHANGED              = 'changed';
  fnDATECREATE           = 'date_create';
  fnDATECHANGE           = 'date_change';
  fnID_USERS             = 'id_users';
  fnID_CREATOR           = 'id_creator';
  fnID_CHANGER           = 'id_changer';
  fnOBJECT_ID            = 'object_id';
  fnATTACHS_CNT          = 'attachs_cnt';

  {$IFDEF MySQL}
  sqlExecProc              = 'CALL ';
  sqlTimeFormat            = 'hh:nn:ss';
  {$ELSE}
  sqlExecProc              = 'EXEC ';
  sqlTimeFormat            = 'hh:nn:ss';
  {$ENDIF}
  sqlQuote                 = '''';
  sql2Quote                = '''''';
  sqlNull                  = 'NULL';

function dbBoolToSQL(const Value: Boolean): string;
function dbStrToSQL(const sValue: string; const bNullIfEmpty: Boolean): string;
function dbStrToSQLDef(const sValue, sNullValue: string): string;
function dbTextToSQL(const sValue: string; const iMaxLen: Integer): string;
function dbFloatToSQL(const Value: Double; const ZeroNull: Boolean = False): string;
function dbDateToSQL(const DateFmt: string; const DateVal: TDateTime): string;
function dbDateTimeToSQL(const DateFmt: string; const DateVal: TDateTime): string;

implementation

uses
  rStrUtils,
  System.SysUtils;

function dbBoolToSQL(const Value: Boolean): string;
begin
  if Value then Result := '1' else Result := '0';
end;

function _dbStrToSQL(const sValue: string): string;
begin
  {$IFDEF MySQL}
  Result := EncodeEscapeChars(sValue);
  {$ELSE}
  Result := StringReplace(sValue, sqlQuote, sql2Quote, [rfReplaceAll]);
  {$ENDIF}
end;

function dbStrToSQL(const sValue: string; const bNullIfEmpty: Boolean): string;
begin
  if (sValue = EmptyStr) and bNullIfEmpty
  then Result := sqlNull
  else Result := sqlQuote + _dbStrToSQL(sValue) + sqlQuote;
end;

function dbStrToSQLDef(const sValue, sNullValue: string): string;
begin
  if (sValue = EmptyStr)
  then Result := sqlQuote + sNullValue + sqlQuote
  else Result := sqlQuote + _dbStrToSQL(sValue) + sqlQuote;
end;

function dbTextToSQL(const sValue: string; const iMaxLen: Integer): string;
begin
  if (iMaxLen > 1) and (Length(sValue) > iMaxLen)
  then Result := _dbStrToSQL(Copy(sValue, 1, iMaxLen))
  else Result := _dbStrToSQL(sValue);
end;

function dbFloatToSQL(const Value: Double; const ZeroNull: Boolean = False): string;
var
  FormatSettings: TFormatSettings;
begin
  if ZeroNull and (Value = 0) then Result := sqlNull
  else begin
    FormatSettings.ThousandSeparator := #0;
    FormatSettings.DecimalSeparator := '.';
    Result := FloatToStr(Value, FormatSettings);
  end;
end;

function dbDateToSQL(const DateFmt: string; const DateVal: TDateTime): string;
var
  fQuote, fDateFmt: string;
begin
  Result := EmptyStr;
  if DateVal <> 0 then
  begin
    if Trim(DateFmt) <> EmptyStr then
    begin
      fQuote := '';
      fDateFmt := DateFmt;
      if (DateFmt[1] = '''') and (DateFmt[Length(DateFmt)] = '''') then
      begin
        fQuote := '''';
        fDateFmt := Copy(DateFmt, 2, Length(DateFmt) - 2);
      end;
      if (DateFmt[1] = '#') and (DateFmt[Length(DateFmt)] = '#') then
      begin
        fQuote := '#';
        fDateFmt := Copy(DateFmt, 2, Length(DateFmt) - 2);
      end;
    end;
    Result := fQuote + FormatDateTime(fDateFmt, DateVal) + fQuote;
  end
  else Result := sqlNull;
end;

function dbDateTimeToSQL(const DateFmt: string; const DateVal: TDateTime): string;
var
  fQuote, fDateFmt: string;
begin
  Result := EmptyStr;
  if Trim(DateFmt) <> EmptyStr then
  begin
    fQuote := '';
    fDateFmt := DateFmt + #32 + sqlTimeFormat;
    if (DateFmt[1] = '''') and (DateFmt[Length(DateFmt)] = '''') then
    begin
      fQuote := '''';
      fDateFmt := Copy(DateFmt, 2, Length(DateFmt) - 2) + #32 + sqlTimeFormat;
    end;
    if (DateFmt[1] = '#') and (DateFmt[Length(DateFmt)] = '#') then
    begin
      fQuote := '#';
      fDateFmt := Copy(DateFmt, 2, Length(DateFmt) - 2) + #32 + sqlTimeFormat;
    end;
  end;
  Result := fQuote + FormatDateTime(fDateFmt, DateVal) + fQuote;
end;

end.
