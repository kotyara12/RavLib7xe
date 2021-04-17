unit rxStrUtilsE;

interface

uses
  System.SysUtils;

function WordCount(const S: string; const WordDelims: TSysCharSet): Integer;
{ WordCount given a set of word delimiters, returns number of words in S. }

function WordPosition(const N: Integer; const S: string;
  const WordDelims: TSysCharSet): Integer;
{ Given a set of word delimiters, returns start position of N'th word in S. }

function ExtractWord(N: Integer; const S: string;
  const WordDelims: TSysCharSet): string;
function ExtractWordPos(N: Integer; const S: string;
  const WordDelims: TSysCharSet; var Pos: Integer): string;
function ExtractDelimited(N: Integer; const S: string;
  const Delims: TSysCharSet): string;
{ ExtractWord, ExtractWordPos and ExtractDelimited given a set of word
  delimiters, return the N'th word in S. }

function ExtractSubstr(const S: string; var Pos: Integer;
  const Delims: TSysCharSet): string;
{ ExtractSubstr given a set of word delimiters, returns the substring from S,
  that started from position Pos. }

function IsWordPresent(const W, S: string; const WordDelims: TSysCharSet): Boolean;
{ IsWordPresent given a set of word delimiters, returns True if word W is
  present in string S. }

implementation

function WordCount(const S: string; const WordDelims: TSysCharSet): Integer;
var
  SLen, I: Cardinal;
begin
  Result := 0;
  I := 1;
  SLen := Length(S);
  while I <= SLen do
  begin
    while (I <= SLen) and CharInSet(S[I], WordDelims) do
      Inc(I);
    if I <= SLen then Inc(Result);
    while (I <= SLen) and not CharInSet(S[I], WordDelims) do
      Inc(I);
  end;
end;

function WordPosition(const N: Integer; const S: string;
  const WordDelims: TSysCharSet): Integer;
var
  Count, I: Integer;
begin
  Count := 0;
  I := 1;
  Result := 0;
  while (I <= Length(S)) and (Count <> N) do
  begin
    { skip over delimiters }
    while (I <= Length(S)) and CharInSet(S[I], WordDelims) do
      Inc(I);
    { if we're not beyond end of S, we're at the start of a word }
    if I <= Length(S) then Inc(Count);
    { if not finished, find the end of the current word }
    if Count <> N then
      while (I <= Length(S)) and not CharInSet(S[I], WordDelims) do
        Inc(I)
    else
      Result := I;
  end;
end;

function ExtractWord(N: Integer; const S: string;
  const WordDelims: TSysCharSet): string;
var
  I: Integer;
  Len: Integer;
begin
  Len := 0;
  I := WordPosition(N, S, WordDelims);
  if I <> 0 then
    { find the end of the current word }
    while (I <= Length(S)) and not CharInSet(S[I], WordDelims) do
    begin
      { add the I'th character to result }
      Inc(Len);
      SetLength(Result, Len);
      Result[Len] := S[I];
      Inc(I);
    end;
  SetLength(Result, Len);
end;

function ExtractWordPos(N: Integer; const S: string;
  const WordDelims: TSysCharSet; var Pos: Integer): string;
var
  I, Len: Integer;
begin
  Len := 0;
  I := WordPosition(N, S, WordDelims);
  Pos := I;
  if I <> 0 then
    { find the end of the current word }
    while (I <= Length(S)) and not CharInSet(S[I], WordDelims) do
    begin
      { add the I'th character to result }
      Inc(Len);
      SetLength(Result, Len);
      Result[Len] := S[I];
      Inc(I);
    end;
  SetLength(Result, Len);
end;

function ExtractDelimited(N: Integer; const S: string;
  const Delims: TSysCharSet): string;
var
  CurWord: Integer;
  I, Len, SLen: Integer;
begin
  CurWord := 0;
  I := 1;
  Len := 0;
  SLen := Length(S);
  SetLength(Result, 0);
  while (I <= SLen) and (CurWord <> N) do
  begin
    if CharInSet(S[I], Delims) then
      Inc(CurWord)
    else
    begin
      if CurWord = N - 1 then
      begin
        Inc(Len);
        SetLength(Result, Len);
        Result[Len] := S[I];
      end;
    end;
    Inc(I);
  end;
end;

function ExtractSubstr(const S: string; var Pos: Integer;
  const Delims: TSysCharSet): string;
var
  I: Integer;
begin
  I := Pos;
  while (I <= Length(S)) and not CharInSet(S[I], Delims) do
    Inc(I);
  Result := Copy(S, Pos, I - Pos);
  if (I <= Length(S)) and CharInSet(S[I], Delims) then Inc(I);
  Pos := I;
end;

function IsWordPresent(const W, S: string; const WordDelims: TSysCharSet): Boolean;
var
  Count, I: Integer;
begin
  Result := False;
  Count := WordCount(S, WordDelims);
  for I := 1 to Count do
    if ExtractWord(I, S, WordDelims) = W then
    begin
      Result := True;
      Exit;
    end;
end;

end.