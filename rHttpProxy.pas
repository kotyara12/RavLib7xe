unit rHttpProxy;

interface

uses
  Classes, rHttpUtils;

type
  TProxyProtocol = (ppHttp, ppHttps, ppSocks4, ppSocks5);
  TProxyProtocols = set of TProxyProtocol;
  TProxyLevel = (plTransparent, plAnonymous, plDistorting, plElite);
  TProxyLevels = set of TProxyLevel;

  (*****************************************************************************
  TProxyServer = record
    sServer: string;
    iPort: Word;
    sUsername: string;
    sPassword: string;
    sCountry: string;
    fProtocol: TProxyProtocol;
    fLevel: TProxyLevel;
    iUpTime: Integer;
    iRTime: Integer;
  end;
  *****************************************************************************)

  PProxyItem = ^TProxyItem;
  TProxyItem = record
    fData: TProxyData;
    pNext: PProxyItem;
  end;

  TProxyListCustom = class
  private
    fProtocols: TProxyProtocols;
    fLevels: TProxyLevels;
    fCountry: string;
    fMinUpTime: Integer;
    fMaxRTime: Integer;
    fMaxCount: Integer;
    fProxyFirst: PProxyItem;
    fProxyLast: PProxyItem;
    fProxyCount: Integer;
  protected
    procedure FillList; virtual; abstract;
  public
    constructor Create(const aProtocols: TProxyProtocols;
      const aLevels: TProxyLevels; const aCountry: string;
      const aUpTime, aRTime, aCount: Integer);
    destructor Destroy; override;
    procedure Clear;
    procedure ProxyAdd(const aProxy: TProxyData); overload;
    procedure ProxyAdd(const aServer, aPort, aUsername, aPassword: string); overload;
    procedure PushCurr;
    function GetCurr: TProxyData;
    function GetNext: TProxyData;
  end;

  TProxyDbNet = class (TProxyListCustom)
  private
    function LoadPage(const iPage: Integer): Integer;
  protected
    procedure FillList; override;
  end;

implementation

uses
  SysUtils, StrUtils, rxStrUtilsE, SynaCode, rParse, rDialogs;

{ TProxyListCustom }

constructor TProxyListCustom.Create(const aProtocols: TProxyProtocols;
  const aLevels: TProxyLevels; const aCountry: string;
  const aUpTime, aRTime, aCount: Integer);
begin
  inherited Create;

  fProtocols := aProtocols;
  fLevels := aLevels;
  fCountry := aCountry;
  fMinUpTime := aUpTime;
  fMaxRTime := aRTime;
  fMaxCount := aCount;

  fProxyFirst := nil;
  fProxyLast := nil;
  fProxyCount := 0;
end;

destructor TProxyListCustom.Destroy;
begin
  Clear;

  inherited Destroy;
end;

procedure TProxyListCustom.Clear;
var
  pItem: PProxyItem;
begin
  while Assigned(fProxyFirst) do
  begin
    pItem := fProxyFirst;
    fProxyFirst := fProxyFirst.pNext;
    Dispose(pItem);
  end;

  fProxyLast := nil;
  fProxyCount := 0;
end;

procedure TProxyListCustom.PushCurr;
var
  pItem: PProxyItem;
begin
  if Assigned(fProxyFirst) then
  begin
    pItem := fProxyFirst;
    fProxyFirst := fProxyFirst.pNext;

    Dec(fProxyCount);

    if fProxyLast = pItem then
      fProxyLast := nil;

    Dispose(pItem);
  end
  else fProxyCount := 0;
end;

procedure TProxyListCustom.ProxyAdd(const aProxy: TProxyData);
var
  pItem: PProxyItem;
begin
  New(pItem);
  pItem^.fData := aProxy;
  pItem^.pNext := nil;

  Inc(fProxyCount);

  if not Assigned(fProxyFirst) then
    fProxyFirst := pItem;

  if Assigned(fProxyLast) then
    fProxyLast.pNext := pItem;

  fProxyLast := pItem;
end;

procedure TProxyListCustom.ProxyAdd(const aServer, aPort, aUsername, aPassword: string);
var
  fData: TProxyData;
begin
  if (aServer <> EmptyStr) and (aPort <> EmptyStr) then
  begin
    fData.sServer := aServer;
    fData.iPort := StrToInt(aPort);
    fData.sUsername := aUsername;
    fData.sPassword := aPassword;

    ProxyAdd(fData);
  end;
end;

function TProxyListCustom.GetCurr: TProxyData;
begin
  FillChar(Result, SizeOf(Result), 0);

  if not Assigned(fProxyFirst) then
    FillList;

  if Assigned(fProxyFirst) then
    Result := fProxyFirst^.fData;
end;

function TProxyListCustom.GetNext: TProxyData;
begin
  PushCurr;

  Result := GetCurr;
end;

{ TProxyDbNet }

procedure TProxyDbNet.FillList;
const
  iPageSize   = 15;
var
  iPage, iPageCnt: Integer;
begin
  Clear;

  iPage := 0;
  repeat
    Inc(iPage);
    iPageCnt := LoadPage(iPage);
  until (fProxyCount >= fMaxCount) or (iPageCnt < iPageSize);
end;

function TProxyDbNet.LoadPage(const iPage: Integer): Integer;
const
  urlList     = 'http://proxydb.net/';
  urlProtocol = 'protocol=%s';
  urlLevels   = 'anonlvl=%d';
  urlCountry  = 'country=%s';
  urlUpTime   = 'min_uptime=%d';
  urlRTime    = 'max_response_time=%d';
  urlOffset   = 'offset=%d';
  iPageSize   = 15;
var
  urlParams, urlGet: string;
  i, iCount, iNumk: Integer;
  sResp, sTable, sRow, sScript: string;
  v1, v2, v2p, v2r, v3: string;

  function HexToStr(const sHex: string): string;
  var
    iBuf, iRes: Integer;
  begin
    Result := EmptyStr;

    Val('$' + sHex, iBuf, iRes);
    if iRes = 0 then
      Result := Chr(iBuf);
  end;

begin
  Result := 0;

  // Формируем параметры
  urlParams := EmptyStr;

  if ppHttp in fProtocols then
    urlParams := rHttp_ConcatParams(urlParams, Format(urlProtocol, ['http']));
  if ppHttps in fProtocols then
    urlParams := rHttp_ConcatParams(urlParams, Format(urlProtocol, ['https']));
  if ppSocks4 in fProtocols then
    urlParams := rHttp_ConcatParams(urlParams, Format(urlProtocol, ['socks4']));
  if ppSocks5 in fProtocols then
    urlParams := rHttp_ConcatParams(urlParams, Format(urlProtocol, ['socks5']));

  if plTransparent in fLevels then
    urlParams := rHttp_ConcatParams(urlParams, Format(urlLevels, [1]));
  if plAnonymous in fLevels then
    urlParams := rHttp_ConcatParams(urlParams, Format(urlLevels, [2]));
  if plDistorting in fLevels then
    urlParams := rHttp_ConcatParams(urlParams, Format(urlLevels, [3]));
  if plElite in fLevels then
    urlParams := rHttp_ConcatParams(urlParams, Format(urlLevels, [4]));

  if fCountry <> EmptyStr then
  begin
    iCount := WordCount(fCountry, [';', ',']);
    for i := 1 to iCount do
      urlParams := rHttp_ConcatParams(urlParams, Format(urlCountry, [Trim(ExtractWord(i, fCountry, [';', ',']))]));
  end;

  if fMinUpTime > 0 then
    urlParams := rHttp_ConcatParams(urlParams, Format(urlUpTime, [fMinUpTime]));

  if fMaxRTime > 0 then
    urlParams := rHttp_ConcatParams(urlParams, Format(urlRTime, [fMaxRTime div 1000]));

  if iPage > 1 then
    urlParams := rHttp_ConcatParams(urlParams, Format(urlOffset, [(iPage - 1) * iPageSize]));

  // Формируем запрос
  if urlParams = EmptyStr
  then urlGet := urlList
  else urlGet := urlList + '?' + urlParams;

  // Загружаем страницу
  sResp := rHTTP_GetEx(nil, urlGet, sslNone, True);
  if sResp <> EmptyStr then
  begin
    // Вырезаем таблицу с данными
    sTable := Parse_getValue(sResp, '<tbody>', '</tbody>');
    if sTable <> EmptyStr then
    begin
      iNumk := StrToIntDef(Parse_GetBlockValue(sResp, '<div style="display:none" data-', '</div>', '="', '"'), 0);
      repeat
        sRow := Parse_CutFirstValue(sTable, '<tr>');
        if sRow <> EmptyStr then
        begin
          sScript := Parse_GetValue(sRow, '<script>', '</script>');
          v1 := ReverseString(Parse_GetBlockValue(sScript, 'var', 'split', '''', ''''));
          v2 := Parse_GetValue(sScript, 'atob(''', '''.replace');
          v2r := EmptyStr;
          repeat
            v2p := Parse_CutFirstValue(v2, '\x');
            if v2p <> EmptyStr then
              v2r := v2r + HexToStr(v2p);
          until v2p = EmptyStr;
          v3 := IntToStr(StrToInt(Parse_GetValue(sScript, 'var pp = (', '-')) + iNumk);

          ProxyAdd(v1 + string(DecodeBase64(AnsiString(v2r))), v3, EmptyStr, EmptyStr);

          Inc(Result);
        end;
      until sRow = EmptyStr;
    end;
  end;
end;

end.
