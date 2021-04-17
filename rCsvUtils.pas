unit RCsvUtils;

interface

uses
  Classes;

function rCsv_QuotedStr(const sInStr: string): string;
function rCsv_ExtractQuotedStr(const sInStr: string): string;
function rCsv_CommaText(const slInText: TStringList; const chDiv: Char = ','): string;

implementation

uses
  SysUtils;

function rCsv_QuotedStr(const sInStr: string): string;
var
  i: Integer;
begin
  Result := sInStr;
  for i := Length(sInStr) downto 1 do
    if Result[i] = '"' then
      Insert('""', Result, i);
  Result := '"' + Result + '"';
end;

function rCsv_ExtractQuotedStr(const sInStr: string): string;
var
  i: Integer;
begin
  Result := Trim(sInStr);
  if (Length(Result) > 1) and (Result[1] = '"') and (Result[Length(Result)] = '"') then
  begin
    Delete(Result, 1, 1);
    Delete(Result, Length(Result), 1);
    for i := Length(Result) downto 1 do
    begin
      if Result[i] = '"' then
      begin
        if not ((i > 1) and (Result[i - 1] = '"')) then
          Delete(Result, i, 1);
      end;
    end;
  end;
end;

function rCsv_CommaText(const slInText: TStringList; const chDiv: Char = ','): string;
var
  i, iCount: Integer;
begin
  Result := '';
  iCount := slInText.Count - 1;
  for i := 0 to iCount do
  begin
    if Result = ''
    then Result := rCsv_QuotedStr(slInText[i])
    else Result := Result + chDiv + rCsv_QuotedStr(slInText[i]);
  end;
end;

end.
