unit rHtmlUtils;

interface

uses
  Types, Classes;

type
  THtmlEncodeOption  = (
    heEof,           // преобразовывать переводы строк
    heQuotes,        // преобразовывать двойные кавычки
    heLinks,         // преобразовывать ссылки
    heAmp,           // преобразовывать & в &amp;
    heTags,          // преобразовывать <>
    heLows,          // преобразовывать системные символы (<$32) в html-коды
    heExtSymbols,    // преобразовывать "расширенный" набор символов
    heExtToCode      // преобразовывать "расширенный" набор символов в коды
    );
  THtmlEncodeOptions = set of THtmlEncodeOption;

  THtmlDecodeOption  = (
    hdBlocks,        // замена </p> и </div> на символы CRLF
    hdBr,            // замена <br> и <br/> на #10
    hdBrEx,          // замена <br> и <br/> на #13#10
    hdHr,            // замена <hr> и <hr/> на ---<br>
    hdHrEx,          // замена <hr> и <hr/> на <br>---<br>
    hdFormat,        // оставить форматирование текста
    hdLinks,         // оставить ссылки
    hdLinksAttr,     // оставить дополнительные атрибуты в сслыках
    hdEntities,      // преобразовывать html-обозначения символов
    hdCharCodes,     // преобразовывать html-коды символов
    hdExtSymbols     // преобразовывать unicode символы пунктуации в ansi
    );
  THtmlDecodeOptions = set of THtmlDecodeOption;

  THtmlRef = record
    sURL: string;
    sText: string;
  end;

  THtmlRefArray = array of THtmlRef;

function html_ReplaceSpaces(const sIsStr: string): string;

function html_CharToCode(const chIn: Char): string;
function html_CodeToChar(const sIn: string): Char;

function html_AmpersandToEntities(const sIsStr: string): string;
function html_CharsToEntities(const sIsStr: string; const Options: THtmlEncodeOptions): string;
function html_EntitiesToChars(const sIsStr: string): string;
function html_UnicodeToAnsiChars(const sIsStr: string): string;

function html_SysCharsToCodes(const sIsStr: string): string;
function html_CodesToChars(const sIsStr: string): string;

function html_HtmlEncode(const sInStr: string; const Options: THtmlEncodeOptions): string;
function html_HtmlDecode(const sInStr: string; const Options: THtmlDecodeOptions): string;

function html_ExtractRefs(const sInStr: string; const Options: THtmlDecodeOptions): THtmlRefArray;

implementation

uses
  SysUtils, StrUtils, rStrUtils, rDialogs;

function html_ReplaceSpaces(const sIsStr: string): string;
begin
  Result := StringReplace(
            StringReplace(sIsStr, '&nbsp; ', ' ', [rfReplaceAll, rfIgnoreCase]),
                                  '&nbsp;', ' ', [rfReplaceAll, rfIgnoreCase]);
end;

function html_CharToCode(const chIn: Char): string;
begin
  Result := '&#' + IntToStr(Word(chIn)) + ';';
end;

function html_CodeToChar(const sIn: string): Char;
var
  iLen: Integer;
begin
  Result := '?';

  iLen := Length(sIn);
  if (Pos('&#', sIn) = 1) and (Pos(';', sIn) = iLen) then
    Result := Char(StrToIntDef(Copy(sIn, 3, iLen - 3), Word('?')));
end;

function html_SysCharsToCodes(const sIsStr: string): string;
var
  i, iCount: Integer;
  iChr: Word;
begin
  Result := EmptyStr;

  iCount := Length(sIsStr);
  for i := 1 to iCount do
  begin
    iChr := Word(sIsStr[i]);
    if (iChr < 32) and (iChr <> 10) and (iChr <> 13)
    then Result := Result + html_CharToCode(sIsStr[i])
    else Result := Result + sIsStr[i];
  end;
end;

function html_AmpersandToEntities(const sIsStr: string): string;
var
  i, iCount: Integer;
begin
  Result := EmptyStr;
  iCount := Length(sIsStr);
  for i := 1 to iCount do
  begin
    if (sIsStr[i] = '&') and not ((i < iCount) and (sIsStr[i + 1] = '#'))
    then Result := Result + '&amp;'
    else Result := Result + sIsStr[i];
  end;
end;

function html_CodesToChars(const sIsStr: string): string;
const
  tagChar = '&#';
  tagCend = ';';
var
  iPos, i: Integer;
  sCode, sCend: string;
begin
  Result := sIsStr;
  iPos := 1;
  repeat
    iPos := Pos(tagChar, Result, iPos + 2);
    if iPos > 0 then
    begin
      i := iPos + 2;

      sCode := EmptyStr;
      sCend := EmptyStr;
      while (i <= Length(Result)) and (sCend = EmptyStr) do
      begin
        if Result[i] = tagCend
        then sCend := Result[i]
        else sCode := sCode + Result[i];
        Inc(i);
      end;

      Result := StringReplace(Result, tagChar + sCode + sCend,
                  Char(StrToIntDef(sCode, Word('?'))),
                  [rfReplaceAll, rfIgnoreCase]);
    end;
  until iPos = 0;
end;

function html_CharsToEntities(const sIsStr: string; const Options: THtmlEncodeOptions): string;
begin
  if heAmp in Options
  then Result := html_AmpersandToEntities(sIsStr)
  else Result := sIsStr;

  if heTags in Options then
  begin
    Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
    Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  end;

  if heQuotes in Options then
    Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);

  if heLows in Options then
    Result := html_SysCharsToCodes(Result);

  if heEof in Options then
    Result := StringReplace(
      StringReplace(Result, #13#10, '<br>', [rfReplaceAll]),
      #10, '<br>', [rfReplaceAll]);

  if heExtToCode in Options then
  begin
    Result := StringReplace(Result, '–', html_CharToCode('–'), [rfReplaceAll]);
    Result := StringReplace(Result, '—', html_CharToCode('—'), [rfReplaceAll]);
    Result := StringReplace(Result, '‘', html_CharToCode('‘'), [rfReplaceAll]);
    Result := StringReplace(Result, '’', html_CharToCode('’'), [rfReplaceAll]);
    Result := StringReplace(Result, '‚', html_CharToCode('‚'), [rfReplaceAll]);
    Result := StringReplace(Result, '“', html_CharToCode('“'), [rfReplaceAll]);
    Result := StringReplace(Result, '”', html_CharToCode('”'), [rfReplaceAll]);
    Result := StringReplace(Result, '„', html_CharToCode('„'), [rfReplaceAll]);
    Result := StringReplace(Result, '«', html_CharToCode('«'), [rfReplaceAll]);
    Result := StringReplace(Result, '»', html_CharToCode('»'), [rfReplaceAll]);
    Result := StringReplace(Result, '¶', html_CharToCode('¶'), [rfReplaceAll]);
    Result := StringReplace(Result, '§', html_CharToCode('§'), [rfReplaceAll]);
    Result := StringReplace(Result, '©', html_CharToCode('©'), [rfReplaceAll]);
    Result := StringReplace(Result, '®', html_CharToCode('®'), [rfReplaceAll]);
    Result := StringReplace(Result, '™', html_CharToCode('™'), [rfReplaceAll]);
    Result := StringReplace(Result, '°', html_CharToCode('°'), [rfReplaceAll]);
    Result := StringReplace(Result, '£', html_CharToCode('£'), [rfReplaceAll]);
    Result := StringReplace(Result, '€', html_CharToCode('€'), [rfReplaceAll]);
    Result := StringReplace(Result, '±', html_CharToCode('±'), [rfReplaceAll]);
    Result := StringReplace(Result, '×', html_CharToCode('×'), [rfReplaceAll]);
    Result := StringReplace(Result, '÷', html_CharToCode('÷'), [rfReplaceAll]);
    Result := StringReplace(Result, '¼', html_CharToCode('¼'), [rfReplaceAll]);
    Result := StringReplace(Result, '½', html_CharToCode('½'), [rfReplaceAll]);
    Result := StringReplace(Result, '¾', html_CharToCode('¾'), [rfReplaceAll]);
    Result := StringReplace(Result, 'ƒ', html_CharToCode('ƒ'), [rfReplaceAll]);
    Result := StringReplace(Result, '←', html_CharToCode('←'), [rfReplaceAll]);
    Result := StringReplace(Result, '↑', html_CharToCode('↑'), [rfReplaceAll]);
    Result := StringReplace(Result, '→', html_CharToCode('→'), [rfReplaceAll]);
    Result := StringReplace(Result, '↓', html_CharToCode('↓'), [rfReplaceAll]);
    Result := StringReplace(Result, '↔', html_CharToCode('↔'), [rfReplaceAll]);
    Result := StringReplace(Result, '♠', html_CharToCode('♠'), [rfReplaceAll]);
    Result := StringReplace(Result, '♣', html_CharToCode('♣'), [rfReplaceAll]);
    Result := StringReplace(Result, '♥', html_CharToCode('♥'), [rfReplaceAll]);
    Result := StringReplace(Result, '♦', html_CharToCode('♦'), [rfReplaceAll]);
    Result := StringReplace(Result, '…', html_CharToCode('…'), [rfReplaceAll]);
    Result := StringReplace(Result, '′', html_CharToCode('′'), [rfReplaceAll]);
    Result := StringReplace(Result, '″', html_CharToCode('″'), [rfReplaceAll]);
  end
  else begin
    if heExtSymbols in Options then
    begin
      Result := StringReplace(Result, '–', '&ndash;', [rfReplaceAll]);
      Result := StringReplace(Result, '—', '&mdash;', [rfReplaceAll]);
      Result := StringReplace(Result, '‘', '&lsquo;', [rfReplaceAll]);
      Result := StringReplace(Result, '’', '&rsquo;', [rfReplaceAll]);
      Result := StringReplace(Result, '‚', '&sbquo;', [rfReplaceAll]);
      Result := StringReplace(Result, '“', '&ldquo;', [rfReplaceAll]);
      Result := StringReplace(Result, '”', '&rdquo;', [rfReplaceAll]);
      Result := StringReplace(Result, '„', '&bdquo;', [rfReplaceAll]);
      Result := StringReplace(Result, '«', '&laquo;', [rfReplaceAll]);
      Result := StringReplace(Result, '»', '&raquo;', [rfReplaceAll]);
      Result := StringReplace(Result, '¶', '&para;', [rfReplaceAll]);
      Result := StringReplace(Result, '§', '&sect;', [rfReplaceAll]);
      Result := StringReplace(Result, '©', '&copy;', [rfReplaceAll]);
      Result := StringReplace(Result, '®', '&reg;', [rfReplaceAll]);
      Result := StringReplace(Result, '™', '&trade;', [rfReplaceAll]);
      Result := StringReplace(Result, '°', '&deg;', [rfReplaceAll]);
      Result := StringReplace(Result, '£', '&pound;', [rfReplaceAll]);
      Result := StringReplace(Result, '€', '&euro;', [rfReplaceAll]);
      Result := StringReplace(Result, '±', '&plusmn;', [rfReplaceAll]);
      Result := StringReplace(Result, '×', '&times;', [rfReplaceAll]);
      Result := StringReplace(Result, '÷', '&divide;', [rfReplaceAll]);
      Result := StringReplace(Result, '¼', '&frac14;', [rfReplaceAll]);
      Result := StringReplace(Result, '½', '&frac12;', [rfReplaceAll]);
      Result := StringReplace(Result, '¾', '&frac34;', [rfReplaceAll]);
      Result := StringReplace(Result, 'ƒ', '&fnof;', [rfReplaceAll]);
      Result := StringReplace(Result, '←', '&larr;', [rfReplaceAll]);
      Result := StringReplace(Result, '↑', '&uarr;', [rfReplaceAll]);
      Result := StringReplace(Result, '→', '&rarr;', [rfReplaceAll]);
      Result := StringReplace(Result, '↓', '&darr;', [rfReplaceAll]);
      Result := StringReplace(Result, '↔', '&harr;', [rfReplaceAll]);
      Result := StringReplace(Result, '♠', '&spades;', [rfReplaceAll]);
      Result := StringReplace(Result, '♣', '&clubs;', [rfReplaceAll]);
      Result := StringReplace(Result, '♥', '&hearts;', [rfReplaceAll]);
      Result := StringReplace(Result, '♦', '&diams;', [rfReplaceAll]);
      Result := StringReplace(Result, '…', '&hellip;', [rfReplaceAll]);
      Result := StringReplace(Result, '′', '&prime;', [rfReplaceAll]);
      Result := StringReplace(Result, '″', '&Prime;', [rfReplaceAll]);
    end;
  end;
end;

function html_EntitiesToChars(const sIsStr: string): string;
begin
  Result := sIsStr;

  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&lt;', '<', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&ndash;', '–', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&mdash;', '—', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&lsquo;', '‘', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&rsquo;', '’', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&sbquo;', '‚', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&ldquo;', '“', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&rdquo;', '”', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&bdquo;', '„', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&laquo;', '«', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&raquo;', '»', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&para;', '¶', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&sect;', '§', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&copy;', '©', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&reg;', '®', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&trade;', '™', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&deg;', '°', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&pound;', '£', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&euro;', '€', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&plusmn;', '±', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&times;', '×', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&divide;', '÷', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&frac14;', '¼', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&frac12;', '½', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&frac34;', '¾', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&fnof;', 'ƒ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&larr;', '←', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&uarr;', '↑', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&rarr;', '→', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&darr;', '↓', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&harr;', '↔', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&spades;', '♠', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&clubs;', '♣', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&hearts;', '♥', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&diams;', '♦', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&hellip;', '…', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&prime;', '′', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&Prime;', '″', [rfReplaceAll, rfIgnoreCase]);
end;

function html_UnicodeToAnsiChars(const sIsStr: string): string;
begin
  Result := sIsStr;

  Result := StringReplace(Result, '–', '-', [rfReplaceAll]);
  Result := StringReplace(Result, '—', '-', [rfReplaceAll]);
  Result := StringReplace(Result, '‘', '''', [rfReplaceAll]);
  Result := StringReplace(Result, '’', '''', [rfReplaceAll]);
  Result := StringReplace(Result, '‚', ',', [rfReplaceAll]);
  Result := StringReplace(Result, '“', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '”', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '„', ',,', [rfReplaceAll]);
  // Result := StringReplace(Result, '«', '<<', [rfReplaceAll]);
  // Result := StringReplace(Result, '»', '>>', [rfReplaceAll]);
  // Result := StringReplace(Result, '¶', '¶', [rfReplaceAll]);
  // Result := StringReplace(Result, '§', '§', [rfReplaceAll]);
  // Result := StringReplace(Result, '©', '(C)', [rfReplaceAll]);
  // Result := StringReplace(Result, '®', '(R)', [rfReplaceAll]);
  Result := StringReplace(Result, '™', 'TM', [rfReplaceAll]);
  // Result := StringReplace(Result, '°', '°', [rfReplaceAll]);
  Result := StringReplace(Result, '£', '£', [rfReplaceAll]);
  Result := StringReplace(Result, '€', '€', [rfReplaceAll]);
  // Result := StringReplace(Result, '±', '+-', [rfReplaceAll]);
  Result := StringReplace(Result, '×', '*', [rfReplaceAll]);
  Result := StringReplace(Result, '÷', '/', [rfReplaceAll]);
  Result := StringReplace(Result, '¼', '1/4', [rfReplaceAll]);
  Result := StringReplace(Result, '½', '1/2;', [rfReplaceAll]);
  Result := StringReplace(Result, '¾', '3/4;', [rfReplaceAll]);
  Result := StringReplace(Result, 'ƒ', 'f()', [rfReplaceAll]);
  Result := StringReplace(Result, '←', '<', [rfReplaceAll]);
  Result := StringReplace(Result, '↑', '{up}', [rfReplaceAll]);
  Result := StringReplace(Result, '→', '>', [rfReplaceAll]);
  Result := StringReplace(Result, '↓', '{down}', [rfReplaceAll]);
  Result := StringReplace(Result, '↔', '<->', [rfReplaceAll]);
  Result := StringReplace(Result, '♠', '{spades}', [rfReplaceAll]);
  Result := StringReplace(Result, '♣', '{clubs}', [rfReplaceAll]);
  Result := StringReplace(Result, '♥', '{hearts}', [rfReplaceAll]);
  Result := StringReplace(Result, '♦', '{diams}', [rfReplaceAll]);
  Result := StringReplace(Result, '…', '...', [rfReplaceAll]);
  Result := StringReplace(Result, '′', '''', [rfReplaceAll]);
  Result := StringReplace(Result, '″', '"', [rfReplaceAll]);
end;

function html_HtmlEncode(const sInStr: string; const Options: THtmlEncodeOptions): string;
var
  i, iCount: Integer;
  bTag, bUrl: Boolean;
  sTag, sVal: string;

  function EncodeText(const sValue: string): string;
  begin
    Result := html_CharsToEntities(sValue, Options);
  end;

begin
  if heLinks in Options then
    Result := EncodeText(sInStr)
  else begin
    Result := EmptyStr;

    bTag := False;
    bUrl := False;
    sTag := EmptyStr;
    sVal := EmptyStr;

    iCount := Length(sInStr);
    for i := 1 to iCount do
    begin
      if (sInStr[i] = '<') and not bTag then
      begin
        if sVal <> EmptyStr then
        begin
          Result := Result + EncodeText(sVal);
          sVal := EmptyStr;
        end;
        sTag := EmptyStr;
        bTag := True;

        Continue;
      end;

      if (sInStr[i] = '>') and bTag then
      begin
        bTag := False;
        sTag := Trim(sTag);

        // ссылки - открывающий тег
        if AnsiStartsText('a ', sTag) then
        begin
          bUrl := True;
          Result := Result + '<' + sTag + '>'
        end;

        // закрывающий тег
        if bUrl and AnsiSameText(sTag, '/a') then
        begin
          bUrl := False;
          Result := Result + '<' + sTag + '>';
        end;

        Continue;
      end;

      if bTag then
        sTag := sTag + sInStr[i]
      else
        sVal := sVal + sInStr[i];
    end;

    if sVal <> EmptyStr then
      Result := Result + EncodeText(sVal);
  end;
end;

function html_HtmlDecode(const sInStr: string; const Options: THtmlDecodeOptions): string;
var
  i, iCount: Integer;
  iPos: Integer;
  bTag, bUrl: Boolean;
  sTag, sVal: string;
  sValueBr, sValueHr: string;

  function DecodeText(const sValue: string): string;
  begin
    Result := html_ReplaceSpaces(sValue);

    if hdEntities in Options then
      Result := html_EntitiesToChars(Result);

    if hdCharCodes in Options then
      Result := html_CodesToChars(Result);
  end;

begin
  Result := EmptyStr;

  if hdBrEx in Options
  then sValueBr := #13#10
  else sValueBr := #10;

  sValueHr := '---' + sValueBr;
  if hdHrEx in Options then
    sValueHr := sValueBr + sValueHr;

  bTag := False;
  bUrl := False;
  sTag := EmptyStr;
  sVal := EmptyStr;
  iCount := Length(sInStr);
  for i := 1 to iCount do
  begin
    if (sInStr[i] = '<') and not bTag then
    begin
      if sVal <> EmptyStr then
      begin
        Result := Result + DecodeText(sVal);
        sVal := EmptyStr;
      end;
      sTag := EmptyStr;
      bTag := True;

      Continue;
    end;

    if (sInStr[i] = '>') and bTag then
    begin
      bTag := False;
      sTag := Trim(sTag);

      // переводы строк
      if AnsiStartsText('br', sTag) and ((hdBr in Options) or (hdBrEx in Options)) then
        Result := Result + sValueBr;

      // горизонтальная линия
      if AnsiStartsText('hr', sTag) and ((hdHr in Options) or (hdHrEx in Options)) then
        Result := Result + sValueHr;

      // блочная разметка
      if hdBlocks in Options then
      begin
        if AnsiStartsText('/p', sTag)   // конец абзаца
        or AnsiStartsText('/h', sTag)   // конец заголовка
        or AnsiStartsText('/div', sTag) // конец блока
        then Result := Result + #10;
      end;

      // форматирование текста
      if hdFormat in Options then
      begin
        if AnsiSameText('b', sTag) or AnsiSameText('/b', sTag)
        or AnsiSameText('i', sTag) or AnsiSameText('/i', sTag)
        or AnsiSameText('em', sTag) or AnsiSameText('/em', sTag)
        or AnsiSameText('strong', sTag) or AnsiSameText('/strong', sTag)
        or AnsiSameText('code', sTag) or AnsiSameText('/code', sTag)
        then Result := Result + '<' + sTag + '>';
      end;

      // ссылки
      if hdLinks in Options then
      begin
        // открывающий тег
        if AnsiStartsText('a ', sTag) then
        begin
          bUrl := True;
          // атрибуты ссылок
          if hdLinksAttr in Options then
            Result := Result + '<' + sTag + '>'
          else begin
            iPos := Pos(AnsiUpperCase('href='), AnsiUpperCase(sTag));
            if iPos > 0 then
            begin
              if sTag[iPos + 5] = '"'
              then sTag := ExtractValueQuoted(Copy(sTag, iPos + 5, Length(sTag) - iPos - 4))
              else sTag := '"' + ExtractValueDelimited(Copy(sTag, iPos + 5, Length(sTag) - iPos - 4), [#32]) + '"';

              Result := Result + '<a href=' + sTag + '>';
            end;
          end;
        end;

        // закрывающий тег
        if bUrl and AnsiSameText(sTag, '/a') then
        begin
          bUrl := False;
          Result := Result + '<' + sTag + '>';
        end;
      end;

      Continue;
    end;

    if bTag then
      sTag := sTag + sInStr[i]
    else
      sVal := sVal + sInStr[i];
  end;

  if sVal <> EmptyStr then
    Result := Result + DecodeText(sVal);
end;

function html_ExtractRefs(const sInStr: string; const Options: THtmlDecodeOptions): THtmlRefArray;
var
  i, iCount: Integer;
  iPos: Integer;
  bTag, bUrl: Boolean;
  sTag, sUrl, sVal: string;

  function DecodeText(const sValue: string): string;
  begin
    Result := html_ReplaceSpaces(sValue);

    if hdEntities in Options then
      Result := html_EntitiesToChars(Result);

    if hdCharCodes in Options then
      Result := html_CodesToChars(Result);

    if hdExtSymbols in Options then
      Result := html_UnicodeToAnsiChars(Result);
  end;

begin
  SetLength(Result, 0);

  bTag := False;
  bUrl := False;
  sTag := EmptyStr;
  sUrl := EmptyStr;
  sVal := EmptyStr;

  iCount := Length(sInStr);
  for i := 1 to iCount do
  begin
    if (sInStr[i] = '<') and not bTag then
    begin
      bTag := True;
      sTag := EmptyStr;

      if not bUrl then
      begin
        sUrl := EmptyStr;
        sVal := EmptyStr;
      end;

      Continue;
    end;

    if (sInStr[i] = '>') and bTag then
    begin
      bTag := False;
      sTag := Trim(sTag);

      // открывающий тег
      if AnsiStartsText('a ', sTag) then
      begin
        iPos := Pos(AnsiUpperCase('href='), AnsiUpperCase(sTag));
        if iPos > 0 then
        begin
          bUrl := True;
          if sTag[iPos + 5] = '"'
          then sUrl := ExtractValueQuoted(Copy(sTag, iPos + 5, Length(sTag) - iPos - 4))
          else sUrl := ExtractValueDelimited(Copy(sTag, iPos + 5, Length(sTag) - iPos - 4), [#32]);
          sVal := EmptyStr;
        end
        else begin
          bUrl := False;
          sUrl := EmptyStr;
          sVal := EmptyStr;
        end;
      end;

      // закрывающий тег
      if bUrl and AnsiSameText(sTag, '/a') then
      begin
        bUrl := False;
        if (sUrl <> EmptyStr) then
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)].sURL := sUrl;
          Result[High(Result)].sText := sVal;
        end;
      end;

      Continue;
    end;

    if bTag then
      sTag := sTag + sInStr[i]
    else begin
      if bUrl then
        sVal := sVal + sInStr[i];
    end;
  end;
end;

end.


