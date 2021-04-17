unit rParse;

interface

uses
  Classes;

type
  TParse_ToNotFound = (tfError, tfEmpty, tfEOL);

  TParse_Idfs = record
    sBlockFrom: string;
    sBlockTo: string;
    sSubBlockFrom: string;
    sSubBlockTo: string;
    sFrom: string;
    sTo: string;
  end;

function  Parse_GetValue(const sText, sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
function  Parse_CutValue(var sText: string; const sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
function  Parse_CutFirstValue(var sText: string; const sFrom: string): string;

function  Parse_GetBlockValue(const sText, sBlockFrom, sBlockTo, sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
function  Parse_GetBlockValueAuto(const sText, sBlockFrom, sBlockTo, sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
function  Parse_GetSubBlockValue(const sText, sBlockFrom, sBlockTo, sSubBlockFrom, sSubBlockTo, sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
function  Parse_GetSubBlockValueAuto(const sText, sBlockFrom, sBlockTo, sSubBlockFrom, sSubBlockTo, sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
function  Parse_GetIdfs(const sText: string; const rIdfs: TParse_Idfs; const aToMode: TParse_ToNotFound = tfError): string;

procedure Parse_GetRefs(const sText: string; slRefs, slKeys: TStrings);

function  Parse_ReplaceOnList(const sIsStr, sReplaceList: string): string;

function  Parse_ConvertCharset(const sText: string): string;

implementation

uses
  SysUtils, StrUtils, rHtmlUtils, RDialogs, RCsvUtils;

resourcestring
  rsErrTagsNotFound = 'Не удалось найти тэги "%0:s" - "%1:s" в тексте!';

function Parse_GetValue(const sText, sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
var
  iPosFrom, iLenCopy: Integer;
begin
  Result := '';

  if sFrom = ''
  then iPosFrom := 1
  else iPosFrom := Pos(UpperCase(sFrom), UpperCase(sText));

  if iPosFrom > 0 then
  begin
    iPosFrom := iPosFrom + Length(sFrom);

    if sTo = ''
    then iLenCopy := Length(sText) - iPosFrom + 1
    else iLenCopy := Pos(AnsiUpperCase(sTo), AnsiUpperCase(RightStr(sText, Length(sText) - iPosFrom + 1))) - 1;

    if iLenCopy < 0 then
    begin
      case aToMode of
        tfError:
          raise Exception.CreateFmt(rsErrTagsNotFound, [sFrom, sTo]);
        tfEOL:
          iLenCopy := Length(sText) - iPosFrom + 1;
        else Exit;
      end;
    end;

    Result := rCsv_ExtractQuotedStr(Trim(Copy(sText, iPosFrom, iLenCopy)));
  end;
end;

function Parse_CutValue(var sText: string; const sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
var
  iPosFrom, iLenCopy, iLenDelete: Integer;
begin
  Result := '';

  iPosFrom := Pos(AnsiUpperCase(sFrom), AnsiUpperCase(sText));
  if iPosFrom > 0 then
  begin
    iPosFrom := iPosFrom + Length(sFrom);

    if sTo = '' then
    begin
      iLenCopy := Length(sText) - iPosFrom + 1;
      iLenDelete := Length(sText);
    end
    else begin
      iLenCopy := Pos(AnsiUpperCase(sTo), AnsiUpperCase(RightStr(sText, Length(sText) - iPosFrom + 1))) - 1;
      iLenDelete := iPosFrom + iLenCopy + Length(sTo) - 1;
    end;

    if (iLenCopy < 0) or (iLenDelete < 1) then
    begin
      case aToMode of
        tfError:
          raise Exception.CreateFmt(rsErrTagsNotFound, [sFrom, sTo]);
        tfEOL:
        begin
          iLenCopy := Length(sText) - iPosFrom + 1;
          iLenDelete := Length(sText);
        end;
        else Exit;
      end;
    end;

    Result := rCsv_ExtractQuotedStr(Trim(Copy(sText, iPosFrom, iLenCopy)));

    Delete(sText, 1, iLenDelete);
  end;
end;

function Parse_CutFirstValue(var sText: string; const sFrom: string): string;
var
  iPosFrom, iPosNext: Integer;
begin
  Result := '';

  iPosFrom := Pos(AnsiUpperCase(sFrom), AnsiUpperCase(sText));
  if iPosFrom > 0 then
  begin
    iPosFrom := iPosFrom + Length(sFrom);

    iPosNext := PosEx(AnsiUpperCase(sFrom), AnsiUpperCase(sText), iPosFrom + 1);
    if iPosNext = 0 then
      iPosNext := Length(sText) + 1;

    Result := rCsv_ExtractQuotedStr(Trim(Copy(sText, iPosFrom, iPosNext - iPosFrom)));

    Delete(sText, 1, iPosNext - 1);
  end;
end;


function Parse_GetBlockValue(const sText, sBlockFrom, sBlockTo, sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
begin
  Result := Parse_GetValue(Parse_GetValue(sText, sBlockFrom, sBlockTo, aToMode), sFrom, sTo, aToMode);
end;

function Parse_GetBlockValueAuto(const sText, sBlockFrom, sBlockTo, sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
begin
  if sBlockFrom = '' then
    Result := Parse_GetValue(sText, sFrom, sTo, aToMode)
  else
    Result := Parse_GetValue(Parse_GetValue(sText, sBlockFrom, sBlockTo, aToMode), sFrom, sTo, aToMode);
end;

function Parse_GetSubBlockValue(const sText, sBlockFrom, sBlockTo, sSubBlockFrom, sSubBlockTo, sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
begin
  Result := Parse_GetValue(Parse_GetValue(Parse_GetValue(sText, sBlockFrom, sBlockTo, aToMode), sSubBlockFrom, sSubBlockTo, aToMode), sFrom, sTo, aToMode);
end;

function Parse_GetSubBlockValueAuto(const sText, sBlockFrom, sBlockTo, sSubBlockFrom, sSubBlockTo, sFrom, sTo: string; const aToMode: TParse_ToNotFound = tfError): string;
begin
  if sSubBlockFrom = '' then
    Result := Parse_GetBlockValueAuto(sText, sBlockFrom, sBlockTo, sFrom, sTo, aToMode)
  else
    Result := Parse_GetValue(Parse_GetValue(Parse_GetValue(sText, sBlockFrom, sBlockTo, aToMode), sSubBlockFrom, sSubBlockTo, aToMode), sFrom, sTo, aToMode);
end;

function Parse_GetIdfs(const sText: string; const rIdfs: TParse_Idfs; const aToMode: TParse_ToNotFound = tfError): string;
begin
  Result := Parse_GetSubBlockValueAuto(sText,
    rIdfs.sBlockFrom, rIdfs.sBlockTo,
    rIdfs.sSubBlockFrom, rIdfs.sSubBlockTo,
    rIdfs.sFrom, rIdfs.sTo,
    aToMode);
end;

procedure Parse_GetRefs(const sText: string; slRefs, slKeys: TStrings);
var
  iPos, iEnd, iLen, i: Integer;
  sRef: string;
begin
  if sText <> '' then
  begin
    iEnd := 0;
    repeat
      iPos := PosEx('<a href=', LowerCase(sText), iEnd + 1);
      if iPos > 0 then
      begin
        iEnd := PosEx('</a>', LowerCase(sText), iPos + 1);
        iLen := 4;
        if iEnd = 0 then
        begin
          iEnd := PosEx('< /a>', LowerCase(sText), iPos + 1);
          iLen := 5;
        end;
        if iEnd = 0 then
        begin
          iEnd := PosEx('</a >', LowerCase(sText), iPos + 1);
          iLen := 5;
        end;
        if iEnd = 0 then
        begin
          iEnd := PosEx('< /a >', LowerCase(sText), iPos + 1);
          iLen := 6;
        end;

        sRef := Trim(Copy(sText, iPos, iEnd - iPos + iLen));

        if sRef <> '' then
        begin
          if Assigned(slKeys) then
          begin
            for i := 0 to slKeys.Count - 1 do
            begin
              if AnsiContainsText(sRef, slKeys[i]) then
              begin
                sRef := Parse_GetValue(sRef, '<a href="', '"');
                if sRef <> '' then
                  slRefs.Add(sRef);
                Break;
              end;
            end;
          end
          else slRefs.Add(sRef);
        end;
      end;
    until (iPos = 0) or (iEnd < iPos);
  end;
end;

function Parse_ReplaceOnList(const sIsStr, sReplaceList: string): string;
var
  fReplList: TStringList;
  i, iCount: Integer;
begin
  Result := sIsStr;

  if sReplaceList <> '' then
  begin
    fReplList := TStringList.Create;
    try
      fReplList.Text := sReplaceList;

      iCount := fReplList.Count - 1;
      for i := 0 to iCount do
        Result := AnsiReplaceText(Result, fReplList.Names[i], fReplList.ValueFromIndex[i]);
    finally
      fReplList.Free;
    end;
  end;
end;

function Parse_ConvertCharset(const sText: string): string;
var
  sCharset: string;
begin
  Result := sText;

  sCharset := Parse_GetBlockValue(sText, '<head>', '</head>', 'charset=', '>');

  if ContainsText(sCharset, 'utf-8') then
    Result := UTF8ToUnicodeString(RawByteString(sText));
end;

end.
