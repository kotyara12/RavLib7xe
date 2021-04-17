unit rStrUtils;

interface

uses
  SysUtils;

function AddDelimStrEx(const BaseStr, AddStr, DelimStr: string): string;
function AddDelimStr(const BaseStr, AddStr: string): string;

function EncodeEscapeChars(const sInStr: string): string;
function DecodeEscapeChars(const sInStr: string): string;

function ExtractValueQuoted(const sInStr: string): string;
function ExtractValueDelimited(const sInStr: string; const fDelims: TSysCharSet): string;

implementation

function AddDelimStrEx(const BaseStr, AddStr, DelimStr: string): string;
begin
  if AddStr <> EmptyStr then begin
    if BaseStr = EmptyStr then
      Result := AddStr
    else
      Result := BaseStr + DelimStr + AddStr;
  end
  else
    Result := BaseStr;
end;

function AddDelimStr(const BaseStr, AddStr: string): string;
begin
  Result := AddDelimStrEx(BaseStr, AddStr, ', ');
end;

function EncodeEscapeChars(const sInStr: string): string;
var
  i, iCount: Integer;
begin
  Result := EmptyStr;

  iCount := Length(sInStr);
  for i := 1 to iCount do
  begin
    case sInStr[i] of
      #00: Result := Result + '\0';
      #01: Result := Result + '\1';
      #02: Result := Result + '\2';
      #03: Result := Result + '\3';
      #04: Result := Result + '\4';
      #05: Result := Result + '\5';
      #06: Result := Result + '\6';
      #07: Result := Result + '\a';
      #08: Result := Result + '\b';
      #09: Result := Result + '\t';
      #10: Result := Result + '\n';
      #11: Result := Result + '\v';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
      #27: Result := Result + '\e';
      '''': Result := Result + '\''';
      '"': Result := Result + '\"';
      '?': Result := Result + '\?';
      '\': Result := Result + '\\';
      else Result := Result + sInStr[i];
    end;
  end;
end;

function DecodeEscapeChars(const sInStr: string): string;
var
  i: Integer;
begin
  Result := EmptyStr;

  i := 1;
  while i <= Length(sInStr) do
  begin
    if (sInStr[i]='\') and (i < Length(sInStr)) then
    begin
      case sInStr[i + 1] of
        '0': Result := Result + #00;
        '1': Result := Result + #01;
        '2': Result := Result + #02;
        '3': Result := Result + #03;
        '4': Result := Result + #04;
        '5': Result := Result + #05;
        '6': Result := Result + #06;
        'a': Result := Result + #07;
        'b': Result := Result + #08;
        't': Result := Result + #09;
        'n': Result := Result + #10;
        'v': Result := Result + #11;
        'f': Result := Result + #12;
        'r': Result := Result + #13;
        'e': Result := Result + #27;
        else Result := Result + sInStr[i + 1];
      end;
      Inc(i, 2);
    end
    else begin
      Result := Result + sInStr[i];
      Inc(i);
    end;
  end;
end;

function ExtractValueQuoted(const sInStr: string): string;
var
  i, iCount: Integer;
  bValue: Boolean;

  function IsDoubleQuote(const iPos: Integer): Boolean;
  begin
    Result := (iPos < iCount) and (sInStr[iPos] = '"') and (sInStr[iPos + 1] = '"');
  end;

  function IsSingleQuote(const iPos: Integer): Boolean;
  begin
    Result := (iPos <= iCount) and (sInStr[iPos] = '"') and not IsDoubleQuote(iPos);
  end;

begin
  Result := EmptyStr;

  i := 0;
  iCount := Length(sInStr);
  bValue := False;
  while i < iCount do
  begin
    Inc(i);

    if IsSingleQuote(i) then
    begin
      Result := Result + sInStr[i];
      bValue := not bValue;
      if not bValue then
        Break;
    end
    else begin
      if bValue then
      begin
        Result := Result + sInStr[i];
        if IsDoubleQuote(i) then
        begin
          Inc(i);
          Result := Result + sInStr[i];
        end;
      end;
    end;
  end;
end;

function ExtractValueDelimited(const sInStr: string; const fDelims: TSysCharSet): string;
var
  i, iCount: Integer;
begin
  Result := EmptyStr;

  iCount := Length(sInStr);
  for i := 1 to iCount do
  begin
    if CharInSet(sInStr[i], fDelims)
    then Break
    else Result := Result + sInStr[i];
  end;
end;

end.
