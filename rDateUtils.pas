unit rDateUtils;

interface

// ƒекодирование даты в формате RSS "Thu, 08 Mar 2018 17:36:43 +0300"
function RSSToDateTime(const sDateValue: string; const bUTC: Boolean = False): TDateTime;
// ѕреобрабование даты из UTC в локальную
function UTCDateTimeToDateTime(aDate: TDateTime): TDateTime;
// ѕреобрабование даты из формата PHP в локальную
function PhpToDateTime(const sPhpDate: string): TDateTime;
// ѕреобразование даты из формата UTF ( 2020-02-16T07:30:31+00:00 ) в локальную с автопересчетом часового по€са
function UTFToDateTime(const sUTFDate, sLOCBias: string): TDateTime;
function DateTimeToUTF(const aLOCTime: TDateTime; const sLOCBias: string): string;

// ѕреобразование строки в дату по формату
function StrToDateFmt(const DateStr, DateFmt: string): TDate;
function StrToDateInt(const DateStr: string): TDate;

// ѕреобразование строки в дату по формату YYYY-MM-DD HH:NN:SS
function StrToDateTimeDef(const sDate: string): TDateTime;

implementation

uses
  rDialogs,
  SysUtils, StrUtils, DateUtils, Windows;

resourcestring
  rsInvalidDateTime           = 'Ќекорректна€ дата / врем€: ''%s''';

function MonthEng2Word(const sMonth: string): Word;
begin
  if SameText(sMonth, 'jan') then Result := 1
  else if SameText(sMonth, 'feb') then Result := 2
  else if SameText(sMonth, 'mar') then Result := 3
  else if SameText(sMonth, 'apr') then Result := 4
  else if SameText(sMonth, 'may') then Result := 5
  else if SameText(sMonth, 'jun') then Result := 6
  else if SameText(sMonth, 'jul') then Result := 7
  else if SameText(sMonth, 'aug') then Result := 8
  else if SameText(sMonth, 'sep') then Result := 9
  else if SameText(sMonth, 'oct') then Result := 10
  else if SameText(sMonth, 'nov') then Result := 11
  else if SameText(sMonth, 'dec') then Result := 12
  else Result := 0;
end;

// ƒекодирование даты в формате RSS
// 8 Mar 2018 17:36:43 +0300
// Thu, 8 Mar 2018 17:36:43 +0300
// Thu, 08 Mar 2018 17:36:43 +0300
// Thu, 8 Mar 2018 17:36:43.125 +0300
function RSSToDateTime(const sDateValue: string; const bUTC: Boolean = False): TDateTime;
var
  sDT, sBuf: string;
  bMilliseconds: Boolean;
  i, iHigh, iPart: Word;
  Y, M, D, H, N, S, L, Z: Word;

  procedure ProcessBuf;
  begin
    // InfoBox(Format('%s'#10'%s'#10'part=%d, buf=[%s]', [sDateValue, sDT, iPart, sBuf]));
    if sBuf <> '' then
    begin
      case iPart of
        1: D := StrToInt(sBuf);
        2: M := MonthEng2Word(sBuf);
        3: Y := StrToInt(sBuf);
        4: H := StrToInt(sBuf);
        5: N := StrToInt(sBuf);
        6: begin
          S := StrToInt(sBuf);
          bMilliseconds := sDT[i] = '.';
        end;
        else begin
          if bMilliseconds then
          begin
            L := StrToInt(sBuf);
            bMilliseconds := False;
          end
          else Z := StrToInt(sBuf);
        end;
      end;
      sBuf := '';
      Inc(iPart);
    end;
  end;

begin
  if Length(sDateValue) >= 19  then
  begin
    Y := 0; M := 0; D := 0; H := 0; N := 0; S := 0; L := 0; Z := 0;
    sDT := Trim(Copy(sDateValue, Pos(',', sDateValue) + 1, Length(sDateValue)));
    iPart := 1;
    sBuf := '';
    bMilliseconds := False;
    iHigh := Length(sDT);
    for i := 1 to iHigh do
    begin
      if CharInSet(sDT[i], [' ', '.', ':'])
      then ProcessBuf
      else sBuf := sBuf + sDT[i];
    end;
    ProcessBuf;

    Result := EncodeDateTime(Y, M, D, H, N, S, L);

    if bUTC and (Z <> 0) then
     Result := IncMinute(IncHour(Result, - Z div 100), - Z mod 100);
  end
  else raise Exception.CreateFmt(rsInvalidDateTime, [sDateValue]);
end;

// ѕреобрабование даты из UTC в локальную
function UTCDateTimeToDateTime(aDate: TDateTime): TDateTime;
var
  TZI: TTimeZoneInformation;
  LocalTime, UTCTime: TSystemTime;
begin
  GetTimeZoneInformation(TZI);
  DateTimeToSystemTime(aDate, UTCTime);
  SystemTimeToTzSpecificLocalTime(@TZI, UTCTime, LocalTime);
  Result := SystemTimeToDateTime(LocalTime);
end;

// ѕреобразование даты из формата PHP в локальную
function PhpToDateTime(const sPhpDate: string): TDateTime;
var
  Y, M, D, H, N, S: Word;
begin
  Result := 0;
  if sPhpDate <> EmptyStr then
  begin
    Y := StrToInt(Copy(sPhpDate, 1, 4));
    M := StrToInt(Copy(sPhpDate, 6, 2));
    D := StrToInt(Copy(sPhpDate, 9, 2));
    H := StrToInt(Copy(sPhpDate, 12, 2));
    N := StrToInt(Copy(sPhpDate, 15, 2));
    S := StrToInt(Copy(sPhpDate, 18, 2));

    Result := UTCDateTimeToDateTime(EncodeDate(Y, M, D) + EncodeTime(H, N, S, 0));
  end;
end;

// ѕреобразование даты из формата UTF ( 2020-02-16T07:30:31+00:00 ) в локальную
function UTFToDateTime(const sUTFDate, sLOCBias: string): TDateTime;
var
  dY, dM, dD, dH, dN, dS: Word;
  bhUTF, bmUTF, bhLOC, bmLOC: Integer;
  sUTFBias: string;
begin
  Result := 0;
  if sUtfDate <> EmptyStr then
  begin
    // 2020-02-16T07:30:31+00:00
    // 1234567890123456789012345
    dY := StrToInt(Copy(sUtfDate, 1, 4));
    dM := StrToInt(Copy(sUtfDate, 6, 2));
    dD := StrToInt(Copy(sUtfDate, 9, 2));
    dH := StrToInt(Copy(sUtfDate, 12, 2));
    dN := StrToInt(Copy(sUtfDate, 15, 2));
    dS := StrToInt(Copy(sUtfDate, 18, 2));
    Result := EncodeDateTime(dY, dM, dD, dH, dN, dS, 0);

    sUTFBias := Trim(Copy(sUtfDate, 20, 5));
    if (sUTFBias = 'Z') or (sUTFBias = 'z') then
      sUTFBias := '+00:00';

    if (sUTFBias <> EmptyStr) and (sLOCBias <> EmptyStr) and (sUTFBias <> sLOCBias) then
    begin
      bhUTF := StrToIntDef(Copy(sUTFBias, 2, 2), 0);
      if (sUTFBias[1] = '+') and (bhUTF > 0) then bhUTF := - bhUTF;
      if (bhUTF <> 0) then Result := IncHour(Result, bhUTF);

      bmUTF := StrToIntDef(Copy(sUTFBias, 5, 2), 0);
      if (sUTFBias[1] = '+') and (bmUTF > 0) then bmUTF := - bmUTF;
      if (bmUTF <> 0) then Result := IncMinute(Result, bmUTF);

      bhLOC := StrToIntDef(Copy(sLOCBias, 2, 2), 0);
      if (sLOCBias[1] = '-') and (bhLOC > 0) then bhLOC := - bhLOC;
      if (bhLOC <> 0) then Result := IncHour(Result, bhLOC);

      bmLOC := StrToIntDef(Copy(sLOCBias, 5, 2), 0);
      if (sLOCBias[1] = '-') and (bmLOC > 0) then bmLOC := - bmLOC;
      if (bmLOC <> 0) then Result := IncMinute(Result, bmLOC);
    end;
  end;
end;

function DateTimeToUTF(const aLOCTime: TDateTime; const sLOCBias: string): string;
begin
  if aLOCTime = 0
  then Result := ''
  else Result := FormatDateTime('yyyy-mm-dd', aLOCTime) + 'T' + FormatDateTime('hh:nn:ss', aLOCTime) + sLOCBias
end;

// ѕреобразование строки в дату по формату
function StrToDateFmt(const DateStr, DateFmt: string): TDate;
var
  FS: TFormatSettings;
  i: Integer;
begin
  FS := TFormatSettings.Create(SysLocale.DefaultLCID);
  FS.ShortDateFormat := DateFmt;
  for i := 1 to Length(DateFmt) do
    if not CharInSet(AnsiUpperCase(DateFmt)[i], ['D', 'M', 'Y']) then
    begin
      FS.DateSeparator := DateFmt[i];
      Break;
    end;
  Result := StrToDate(DateStr, FS);
end;

function StrToDateInt(const DateStr: string): TDate;
begin
  Result := EncodeDate(
    StrToInt(Copy(DateStr, 1, 4)),
    StrToInt(Copy(DateStr, 5, 2)),
    StrToInt(Copy(DateStr, 7, 2))
    );
end;

// ѕреобразование строки в дату по формату YYYY-MM-DD HH:NN:SS
function StrToDateTimeDef(const sDate: string): TDateTime;
begin
  Result := EncodeDateTime(
    StrToInt(Copy(sDate, 1, 4)),
    StrToInt(Copy(sDate, 6, 2)),
    StrToInt(Copy(sDate, 9, 2)),
    StrToInt(Copy(sDate, 12, 2)),
    StrToInt(Copy(sDate, 15, 2)),
    StrToInt(Copy(sDate, 18, 2)),
    0);
end;

end.
