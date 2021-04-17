unit RProxy;

interface

uses
  Classes, rHttpUtils;

type
  TProxyItem = record
    aData: TProxyData;
    iTryCnt: Integer;
    iErrCnt: Integer;
  end;

  TProxyProtocol = (ppHttp, ppHttps, ppSocks4, ppSocks5);
  TProxyProtocols = set of TProxyProtocol;
  TProxyLevel = (plTransparent, plAnonymous, plDistorting, plElite);
  TProxyLevels = set of TProxyLevel;

  TProxyListCustom = class
  private
    fProxy: array of TProxyItem;
    fIndex: Integer;
    fAutoNext: Boolean;
    fMaxErr: Integer;
    fWrnSize: Integer;
    fList: string;
    fOnWarning: TNotifyEvent;
    function  Find(const aProxy: TProxyData): Integer;
    procedure LoadList;
    procedure SaveList;
    procedure Add(const aProxy: TProxyData);
    procedure Del(const iIndex: Integer);
    procedure Fix(const iIdx: Integer; const bOk, bNextOk: Boolean);
  protected
    procedure AddProxy(const aServer: string; const aPort: Word; const aUsername: string; const aPassword: string);
    procedure FillList; virtual; abstract;
  public
    constructor Create(const fileList: string);
    destructor Destroy; override;

    procedure Append(const aProxy: TProxyData);
    function  Count: Integer;
    procedure Clear;
    procedure Update;
    procedure Reset;
    procedure Next;
    function  GetProxy: TProxyData;
    procedure FixTry(const bOk: Boolean); overload;
    procedure FixTry(const aProxy: TProxyData; const bOk: Boolean); overload;

    property MaxErrors: Integer read fMaxErr write fMaxErr;
    property AutoNext: Boolean read fAutoNext write fAutoNext;
    property WarningSize: Integer read fWrnSize write fWrnSize;
    property OnWarningSize: TNotifyEvent read fOnWarning write fOnWarning;
  end;

  TProxyList = class (TProxyListCustom)
  protected
    procedure FillList; override;
  end;

  TProxyListParse = class (TProxyListCustom)
  private
    fProtocols: TProxyProtocols;
    fLevels: TProxyLevels;
    fCountry: string;
    fMinUpTime: Integer;
    fMaxRTime: Integer;
    fMaxCount: Integer;
  public
    constructor Create(const fileList: string;
      const aProtocols: TProxyProtocols;
      const aLevels: TProxyLevels; const aCountry: string;
      const aUpTime, aRTime, aCount: Integer);

    property Protocols: TProxyProtocols read fProtocols write fProtocols;
    property Levels: TProxyLevels read fLevels write fLevels;
    property Country: string read fCountry write fCountry;
    property MinUpTime: Integer read fMinUpTime write fMinUpTime;
    property MaxRTime: Integer read fMaxRTime write fMaxRTime;
    property MaxCount: Integer read fMaxCount write fMaxCount;
  end;

  TProxyDbNet = class (TProxyListParse)
  private
    function LoadPage(const iPage: Integer): Integer;
  protected
    procedure FillList; override;
  end;

function proxy_Str2Proxy(const sProxy: string): TProxyData;
function proxy_Proxy2Str(const aProxy: TProxyData): string;

implementation

uses
  SysUtils, StrUtils, SynaCode, rxStrUtilsE, rParse, rDialogs;

const
  fnDefProxyFile               = 'proxy.lst';

resourcestring
  rsErrProxyListIsEmpty        = 'Список proxy серверов пуст!';

function proxy_Str2Proxy(const sProxy: string): TProxyData;
var
  sSrvPort: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  if sProxy <> EmptyStr then
  begin
    sSrvPort := Trim(ExtractWord(1, sProxy, ['|']));
    Result.sServer := Trim(ExtractWord(1, sSrvPort, [':']));
    Result.iPort := StrToInt(Trim(ExtractWord(2, sSrvPort, [':'])));
    Result.sUsername := Trim(ExtractWord(2, sProxy, ['|']));
    Result.sPassword := Trim(ExtractWord(3, sProxy, ['|']));
  end;
end;

function proxy_Proxy2Str(const aProxy: TProxyData): string;
begin
  Result := EmptyStr;
  if aProxy.sServer <> EmptyStr then
    Result := aProxy.sServer + ':' + IntToStr(aProxy.iPort);
  if (Result <> EmptyStr) and (aProxy.sUsername <> EmptyStr) then
    Result := Result + '|' + aProxy.sUsername + '|' + aProxy.sPassword;
end;

{ TProxyListCustom }

constructor TProxyListCustom.Create(const fileList: string);
begin
  fList := fileList;
  if fList = EmptyStr then
    fList := ExtractFilePath(ParamStr(0)) + fnDefProxyFile;

  fMaxErr := 5;
  fWrnSize := 0;
  fAutoNext := False;
  fOnWarning := nil;

  LoadList;
end;

destructor TProxyListCustom.Destroy;
begin
  SetLength(fProxy, 0);

  inherited Destroy;
end;

function TProxyListCustom.Count: Integer;
begin
  Result := Length(fProxy);
end;

function TProxyListCustom.Find(const aProxy: TProxyData): Integer;
var
  i: Integer;
begin
  Result := -1;
  if Length(fProxy) > 0 then
  begin
    for i := Low(fProxy) to High(fProxy) do
    begin
      if SameText(fProxy[i].aData.sServer, aProxy.sServer)
      and (fProxy[i].aData.iPort = aProxy.iPort)
      and (fProxy[i].aData.sUsername = aProxy.sUsername)
      and (fProxy[i].aData.sPassword = aProxy.sPassword) then
      begin
        Result := i;
        Break;
      end;
    end;
  end;
end;

procedure TProxyListCustom.Add(const aProxy: TProxyData);
begin
  SetLength(fProxy, Length(fProxy) + 1);
  with fProxy[High(fProxy)] do
  begin
    aData := aProxy;
    iTryCnt := 0;
    iErrCnt := 0;
  end;
end;

procedure TProxyListCustom.AddProxy(const aServer: string; const aPort: Word; const aUsername: string; const aPassword: string);
begin
  SetLength(fProxy, Length(fProxy) + 1);
  with fProxy[High(fProxy)] do
  begin
    aData.sServer := aServer;
    aData.iPort := aPort;
    aData.sUsername := aUsername;
    aData.sPassword := aPassword;
    iTryCnt := 0;
    iErrCnt := 0;
  end;
end;

procedure TProxyListCustom.Append(const aProxy: TProxyData);
begin
  if Find(aProxy) = -1 then
  begin
    Add(aProxy);
    SaveList;
  end;
end;

procedure TProxyListCustom.Del(const iIndex: Integer);
var
  iLast: Integer;
begin
  if Length(fProxy) > 0 then
  begin
    iLast := High(fProxy);
    if iIndex < iLast then
      Move(fProxy[iIndex + 1], fProxy[iIndex], SizeOf(TProxyItem) * (iLast - iIndex));
    SetLength(fProxy, Length(fProxy) - 1);
  end;

  if (Length(fProxy) = 0) or (fIndex > High(fProxy)) then
    Reset;
end;

procedure TProxyListCustom.Clear;
begin
  SetLength(fProxy, 0);
  fIndex := -1;
end;

procedure TProxyListCustom.Reset;
begin
  if Length(fProxy) > 0
  then fIndex := Low(fProxy)
  else fIndex := -1;
end;

procedure TProxyListCustom.Next;
begin
  if Length(fProxy) > 0 then
  begin
    Inc(fIndex);
    if fIndex > High(fProxy) then
      fIndex := Low(fProxy);
  end
  else fIndex := -1;
end;

procedure TProxyListCustom.LoadList;
var
  slProxy: TStringList;
  i, iCount: Integer;
begin
  SetLength(fProxy, 0);
  if (fList <> EmptyStr) and FileExists(fList) then
  begin
    slProxy := TStringList.Create;
    try
      slProxy.LoadFromFile(fList);
      iCount := slProxy.Count - 1;
      for i := 0 to iCount do
        Add(proxy_Str2Proxy(slProxy[i]));
    finally
      slProxy.Free;
    end;
  end;
  Reset;
end;

procedure TProxyListCustom.SaveList;
var
  slProxy: TStringList;
  i: Integer;
begin
  if fList <> EmptyStr then
  begin
    slProxy := TStringList.Create;
    try
      ForceDirectories(ExtractFilePath(fList));
      if Length(fProxy) > 0 then
      begin
        for i := Low(fProxy) to High(fProxy) do
          slProxy.Add(proxy_Proxy2Str(fProxy[i].aData));
      end;
      slProxy.SaveToFile(fList);
    finally
      slProxy.Free;
    end;
  end;
end;

procedure TProxyListCustom.Update;
begin
  if Length(fProxy) = 0 then
  begin
    FillList;
    SaveList;
    Reset;
  end;

  if Length(fProxy) = 0 then
    raise Exception.Create(rsErrProxyListIsEmpty);
end;

function TProxyListCustom.GetProxy: TProxyData;
begin
  Update;

  if fIndex > -1 then
    Result := fProxy[fIndex].aData;
end;

procedure TProxyListCustom.Fix(const iIdx: Integer; const bOk, bNextOk: Boolean);
begin
  if (Length(fProxy) > 0) and (iIdx > -1) then
  begin
    Inc(fProxy[iIdx].iTryCnt);

    if bOk then
    begin
      fProxy[iIdx].iErrCnt := 0;
      if bNextOk then Next;
    end
    else begin
      Inc(fProxy[iIdx].iErrCnt);
      if fProxy[iIdx].iErrCnt >= fMaxErr then
      begin
        Del(iIdx);
        SaveList;

        if (fWrnSize > 0) and (Length(fProxy) <= fWrnSize)
          and Assigned(fOnWarning) then
            fOnWarning(Self);
      end
      else Next;
    end;
  end;
end;

procedure TProxyListCustom.FixTry(const bOk: Boolean);
begin
  Fix(fIndex, bOk, fAutoNext);
end;

procedure TProxyListCustom.FixTry(const aProxy: TProxyData; const bOk: Boolean);
begin
  Fix(Find(aProxy), bOk, False);
end;

{ TProxyList }

procedure TProxyList.FillList;
begin
  // nothing
end;

{ TProxyListParse }

constructor TProxyListParse.Create(const fileList: string;
  const aProtocols: TProxyProtocols; const aLevels: TProxyLevels;
  const aCountry: string; const aUpTime, aRTime, aCount: Integer);
begin
  inherited Create(fileList);

  fProtocols := aProtocols;
  fLevels := aLevels;
  fCountry := aCountry;
  fMinUpTime := aUpTime;
  fMaxRTime := aRTime;
  fMaxCount := aCount;
end;

{ TProxyDbNet }

procedure TProxyDbNet.FillList;
const
  iPageSize   = 15;
var
  iPage, iPageCnt: Integer;
begin
  iPage := 0;
  repeat
    Inc(iPage);
    iPageCnt := LoadPage(iPage);
  until (Count >= fMaxCount) or (iPageCnt < iPageSize);
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
  i, iCount, iNumk, iPort: Integer;
  sResp, sTable, sRow, sScript: string;
  v1, v2, v2p, v2r: string;

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
    sTable := Parse_GetValue(sResp, '<tbody>', '</tbody>');
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
          iPort := StrToInt(Parse_GetValue(sScript, 'var pp = (', '-')) + iNumk;

          AddProxy(v1 + string(DecodeBase64(AnsiString(v2r))), iPort, EmptyStr, EmptyStr);

          Inc(Result);
        end;
      until sRow = EmptyStr;
    end;
  end;
end;

end.

