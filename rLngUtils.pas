unit RLngUtils;

interface

uses
  Windows;

function lng_GetSystemLCID: LCID;
function lng_GetSystemLang: UINT;

function lng_GetLcidHex4(const iLCID: LCID): string;
function lng_GetLcidAbbr(const iLCID: LCID): string;
function lng_GetLcidName(const iLCID: LCID): string;
function lng_GetLangName(const iLANG: UINT): string;

function lng_LCIDToCodePage(iLCID: LCID): Integer;
function lng_LCIDToCharset(iLCID: LCID): Byte;

implementation

uses
  SysUtils;

function GetSystemDefaultLCID: LCID; stdcall; external kernel32 name 'GetSystemDefaultLCID';
function GetSystemDefaultUILanguage: UINT; stdcall; external kernel32 name 'GetSystemDefaultUILanguage';
function TranslateCharsetInfo(lpSrc: DWORD; var lpCs: TCharsetInfo; dwFlags: DWORD): BOOL; stdcall; external 'gdi32.dll';

function lng_GetSystemLCID: LCID;
begin
  Result := GetSystemDefaultLCID;
end;

function lng_GetSystemLang: UINT;
begin
  Result := GetSystemDefaultUILanguage;
end;

function lng_GetLcidHex4(const iLCID: LCID): string;
begin
  Result := Format('%.4x', [iLCID]);
end;

function lng_GetLcidAbbr(const iLCID: LCID): string;
var
  sLangAbbr: array [0..4] of Char;
begin
  try
    if Win32Check(GetLocaleInfo(iLCID, LOCALE_SABBREVLANGNAME, sLangAbbr, SizeOf(sLangAbbr)) <> 0) then
      Result := sLangAbbr;
  except
    Result := EmptyStr;
  end;
end;

function lng_GetLcidName(const iLCID: LCID): string;
var
  sLangName: array [0..127] of Char;
begin
  try
    if Win32Check(GetLocaleInfo(iLCID, LOCALE_SLANGUAGE, sLangName, SizeOf(sLangName)) <> 0) then
      Result := sLangName;
  except
    Result := EmptyStr;
  end;
end;

function lng_GetLangName(const iLANG: UINT): string;
var
  sLangName: array[0..127] of Char;
begin
  try
    if Win32Check(VerLanguageName(iLANG, sLangName, SizeOf(sLangName)) = 0) then
      Result := sLangName;
  except
    Result := EmptyStr;
  end;
end;

function lng_LCIDToCodePage(iLCID: LCID): Integer;
const
  CP_ACP = 0;                                // system default code page
  LOCALE_IDEFAULTANSICODEPAGE = $00001004;   // default ansi code page
var
  ResultCode: Integer;
  Buffer: array [0..6] of Char;
begin
  Result := CP_ACP;
  if Win32Check(GetLocaleInfo(iLCID, LOCALE_IDEFAULTANSICODEPAGE, Buffer, SizeOf(Buffer)) <> 0) then
  begin
    Val(Buffer, Result, ResultCode);
    if ResultCode <> 0 then
      Result := CP_ACP;
  end;
end;

function lng_LCIDToCharset(iLCID: LCID): Byte;
var
  CS: TCharsetInfo;
begin
  Result := DEFAULT_CHARSET;
  if Win32Check(TranslateCharsetInfo(lng_LCIDToCodePage(iLCID), CS, TCI_SRCCODEPAGE)) then
    Result := CS.ciCharset;
end;

end.
