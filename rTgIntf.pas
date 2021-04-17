unit rTgIntf;

interface

uses
  SysUtils, rHttpUtils;

type
  ETgError = class (Exception)
  protected
    FErrorCode: Integer;
  public
    constructor CreateError(const AErrorCode: Integer;
     const AReplyMessage: string); reintroduce; virtual;
    property ErrorCode: Integer read FErrorCode;
  end;

  tTgUser = record
    idUser: Int64;
    sJson: string;
    bIsBot: Boolean;
    sUsername: string;
    sFirstName: string;
    sLastName: string;
    sFullName: string;
    sLngCode: string;
  end;

  tTgChat = record
    idChat: Int64;
    sJson: string;
    sTitle: string;
    sChatType: string;
  end;

  tTgMessage = record
    idMsg: Int64;
    sJson: string;
    tgChat: tTgChat;
    tgFrom: tTgUser;
    iDate: Integer;
    sText: string;
  end;

  tTgUpdateType = (tgmUnknown, tgmMessage, tgmEditedMessage, tgmChannelPost, tgmCallbackQuery);

  tTgUpdate = record
    idUpd: Int64;
    sJson: string;
    tgType: tTgUpdateType;
    tgMsg: tTgMessage;
  end;

  tTgUpdates = array of tTgUpdate;

function  tg_UpdatesParse(const jsonRes: string): tTgUpdates;
function  tg_GetMe(const aProxy: PProxyData; const sGateway, sBotToken: string; const iTimeout: Integer): tTgUser;
function  tg_UpdatesGet(const aProxy: PProxyData; const sGateway, sBotToken: string; const iTimeout: Integer; const idOffset: Int64; var bOk: Boolean): tTgUpdates;
function  tg_UpdatesWait(const aProxy: PProxyData; const sGateway, sBotToken: string; const idOffset: Int64; const iTimeout: Integer): tTgUpdates;
function  tg_SendMessage(const aProxy: PProxyData; const sGateway, sBotToken: string; const iTimeout: Integer;
  const idChat: Int64; const sMessage, sMarkup: string; const idReply: Int64;
  const bNotNotify: Boolean = False; const bShowLinks: Boolean = False): tTgMessage;
procedure tg_DeleteMessage(const aProxy: PProxyData; const sGateway, sBotToken: string; const iTimeout: Integer;
  const idChat: Int64; const idMessage: Int64);

implementation

uses
  Classes, SuperObject,
  IdTCPConnection, IdTCPClient, IdIcmpClient, IdHTTP, IdCompressorZLib, IdReplyRFC,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdCookieManager,
  rDialogs;

resourcestring
  rsErrJsonIsNull                 = 'JSON object is NULL';

{ ETgError }

constructor ETgError.CreateError(const AErrorCode: Integer; const AReplyMessage: string);
begin
  inherited Create(AReplyMessage);
  FErrorCode := AErrorCode;
end;

function tg_UserDecode(const jsonUser: ISuperObject): tTgUser;
begin
  FillChar(Result, SizeOf(Result), 0);

  if Assigned(jsonUser) then
  begin
    with Result do
    begin
      idUser := jsonUser.I['id'];
      sJson := jsonUser.AsString;
      bIsBot := jsonUser.B['is_bot'];
      sUsername := jsonUser.S['username'];
      sFirstName := jsonUser.S['first_name'];
      sLastName := jsonUser.S['last_name'];
      sLngCode := jsonUser.S['language_code'];

      if sUsername = EmptyStr then
        sUsername := Format('%d', [idUser]);

      if sFirstName <> EmptyStr then
        sFullName := sFirstName;
      if sLastName <> EmptyStr then
      begin
        if sFullName = EmptyStr
        then sFullName := sLastName
        else sFullName := sFullName + #32 + sLastName;
      end;
      if sFullName = EmptyStr then
        sFullName := sUsername;
    end;
  end;
end;

function tg_FromChatDecode(const jsonChat: ISuperObject): tTgUser;
begin
  FillChar(Result, SizeOf(Result), 0);

  if Assigned(jsonChat) then
  begin
    with Result do
    begin
      idUser := jsonChat.I['id'];
      sJson := jsonChat.AsString;
      bIsBot := False;
      sUsername := jsonChat.S['username'];
      if sUsername = EmptyStr then
        sUsername := jsonChat.S['title'];
      sFirstName := jsonChat.S['first_name'];
      sLastName := jsonChat.S['last_name'];
      sLngCode := jsonChat.S['language_code'];

      if sUsername = EmptyStr then
        sUsername := Format('%d', [idUser]);

      if sFirstName <> EmptyStr then
        sFullName := sFirstName;
      if sLastName <> EmptyStr then
      begin
        if sFullName = EmptyStr
        then sFullName := sLastName
        else sFullName := sFullName + #32 + sLastName;
      end;
      if sFullName = EmptyStr then
        sFullName := sUsername;
    end;
  end;
end;


function tg_ChatDecode(const jsonChat: ISuperObject): tTgChat;
begin
  FillChar(Result, SizeOf(Result), 0);

  if Assigned(jsonChat) then
  begin
    with Result do
    begin
      idChat := jsonChat.I['id'];
      sJson := jsonChat.AsString;
      if jsonChat.S['title'] = EmptyStr
      then sTitle := jsonChat.S['username']
      else sTitle := jsonChat.S['title'];
      sChatType := jsonChat.S['type'];
    end;
  end;
end;

function tg_MessageDecode(const jsonMsg: ISuperObject): tTgMessage;
begin
  FillChar(Result, SizeOf(Result), 0);

  if Assigned(jsonMsg) then
  begin
    with Result do
    begin
      idMsg := jsonMsg.I['message_id'];
      if idMsg = 0 then idMsg := jsonMsg.I['id'];
      sJson := jsonMsg.AsString;
      iDate := jsonMsg.I['date'];
      sText := jsonMsg.S['text'];
      tgChat := tg_ChatDecode(jsonMsg.O['chat']);
      if Assigned(jsonMsg.O['from'])
      then tgFrom := tg_UserDecode(jsonMsg.O['from'])
      else tgFrom := tg_FromChatDecode(jsonMsg.O['chat']);
    end;
  end;
end;

function tg_CallbackDecode(const jsonMsg: ISuperObject): tTgMessage;
begin
  FillChar(Result, SizeOf(Result), 0);

  if Assigned(jsonMsg) then
  begin
    with Result do
    begin
      idMsg := jsonMsg.O['message'].I['message_id'];
      sJson := jsonMsg.AsString;
      sText := jsonMsg.S['data'];
      tgChat := tg_ChatDecode(jsonMsg.O['message'].O['chat']);
      tgFrom := tg_UserDecode(jsonMsg.O['from']);
    end;
  end;
end;

function tg_UpdateDecode(const jsonUpd: ISuperObject): tTgUpdate;
begin
  FillChar(Result, SizeOf(Result), 0);

  if Assigned(jsonUpd) then
  begin
    with Result do
    begin
      idUpd := jsonUpd.I['update_id'];
      sJson := jsonUpd.AsString;

      tgType := tgmUnknown;
      if jsonUpd.S['message'] <> EmptyStr then
      begin
        tgType := tgmMessage;
        tgMsg := tg_MessageDecode(jsonUpd.O['message']);
      end;

      if jsonUpd.S['edited_message'] <> EmptyStr then
      begin
        tgType := tgmEditedMessage;
        tgMsg := tg_MessageDecode(jsonUpd.O['edited_message']);
      end;

      if jsonUpd.S['channel_post'] <> EmptyStr then
      begin
        tgType := tgmChannelPost;
        tgMsg := tg_MessageDecode(jsonUpd.O['channel_post']);
      end;

      if jsonUpd.S['callback_query'] <> EmptyStr then
      begin
        tgType := tgmCallbackQuery;
        tgMsg := tg_CallbackDecode(jsonUpd.O['callback_query']);
      end;
    end;
  end;
end;

function tg_UpdatesDecode(const jsonRes: ISuperObject): tTgUpdates;
var
  jsonUpds: TSuperArray;
  i, iCount: Integer;
begin
  SetLength(Result, 0);

  if Assigned(jsonRes) then
  begin
    if jsonRes.B['ok'] then
    begin
      jsonUpds := jsonRes['result'].AsArray;

      iCount := jsonUpds.Length;
      if iCount > 0 then
      begin
        SetLength(Result, iCount);

        for i := 0 to iCount - 1 do
          Result[i] := tg_UpdateDecode(jsonUpds[i]);
      end;
    end
    else raise ETgError.CreateError(jsonRes.I['error_code'], jsonRes.S['description']);
  end
  else raise ETgError.CreateError(-1, rsErrJsonIsNull);
end;

function tg_UpdatesParse(const jsonRes: string): tTgUpdates;
begin
  Result := tg_UpdatesDecode(SO(jsonRes));
end;

function tg_API(const aProxy: PProxyData; const sGateway, sBotToken, sApiMethod, sParams: string; const iTimeout: Integer): string;
var
  IdHTTP: TIdHTTP;
  IdCZip: TIdCompressorZLib;
  IdCSLL: TIdSSLIOHandlerSocketOpenSSL;
  fRequest, fResponse: TStringStream;
begin
  IdHTTP := TIdHTTP.Create;
  IdCZip := TIdCompressorZLib.Create;
  IdHTTP.Compressor := IdCZip;
  IdCSLL := TIdSSLIOHandlerSocketOpenSSL.Create;
  fRequest := TStringStream.Create(sParams);
  fResponse := TStringStream.Create('');
  try
    IdCSLL.SSLOptions.Method := sslvTLSv1_2;
    IdCSLL.SSLOptions.VerifyMode := [];
    if iTimeout > 0 then
    begin
      IdHTTP.ConnectTimeout := iTimeout;
      IdHTTP.ReadTimeout := iTimeout;
    end;
    IdHTTP.HandleRedirects := True;
    IdHTTP.Request.Accept := 'application/json';
    IdHTTP.Request.ContentType := 'application/json';
    IdHTTP.Request.AcceptEncoding := 'gzip, deflate, sdch';
    IdHTTP.Request.UserAgent := 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.80 Safari/537.36';
    IdHTTP.IOHandler := IdCSLL;

    if Assigned(aProxy) then
    begin
      with aProxy^ do
      begin
        IdHTTP.ProxyParams.ProxyServer := sServer;
        IdHTTP.ProxyParams.ProxyPort := iPort;
        IdHTTP.ProxyParams.ProxyUsername := sUsername;
        IdHTTP.ProxyParams.ProxyPassword := sPassword;
      end;
    end;

    try
      try
        if sGateway = EmptyStr then
        begin
          IdHTTP.Post(Format('https://api.telegram.org/bot%0:s/%1:s', [sBotToken, sApiMethod]), fRequest, fResponse);
          Result := fResponse.DataString;
        end
        else begin
          IdHTTP.Post(sGateway + Format('?bot=%0:s&method=%1:s', [sBotToken, sApiMethod]), fRequest, fResponse);
          Result := fResponse.DataString;
        end;
      except
        on E: Exception do
        begin
          if E is EIdReplyRFCError then
            raise ETgError.CreateError(EIdReplyRFCError(E).ErrorCode, E.Message)
          else raise;
        end;
      end;
    finally
      IdHTTP.Disconnect;
    end;
  finally
    FreeAndNil(fRequest);
    FreeAndNil(fResponse);
    if Assigned(IdCSLL) then
      FreeAndNil(IdCSLL);
    IdHTTP.Compressor := nil;
    FreeAndNil(IdCZip);
    FreeAndNil(IdHTTP);
  end;
end;

function tg_GetMe(const aProxy: PProxyData; const sGateway, sBotToken: string; const iTimeout: Integer): tTgUser;
var
  jsonRes: ISuperObject;
begin
  FillChar(Result, SizeOf(Result), 0);

  jsonRes := SO(tg_API(aProxy, sGateway, sBotToken, 'getMe', EmptyStr, iTimeout));
  if Assigned(jsonRes) then
  begin
    if jsonRes.B['ok'] then Result := tg_UserDecode(jsonRes)
    else raise ETgError.CreateError(jsonRes.I['error_code'], jsonRes.S['description']);
  end
  else raise ETgError.CreateError(-1, rsErrJsonIsNull);
end;

function tg_UpdatesGet(const aProxy: PProxyData; const sGateway, sBotToken: string; const iTimeout: Integer; const idOffset: Int64; var bOk: Boolean): tTgUpdates;
var
  jsonMsg: ISuperObject;
begin
  jsonMsg := SO;
  jsonMsg.I['offset'] := idOffset;

  Result := tg_UpdatesParse(tg_API(aProxy, sGateway, sBotToken, 'getUpdates', jsonMsg.AsJSon, iTimeout));
end;

function tg_UpdatesWait(const aProxy: PProxyData; const sGateway, sBotToken: string; const idOffset: Int64; const iTimeout: Integer): tTgUpdates;
var
  jsonMsg: ISuperObject;
begin
  jsonMsg := SO;
  jsonMsg.I['offset'] := idOffset;
  jsonMsg.I['timeout'] := iTimeout;

  Result := tg_UpdatesParse(tg_API(aProxy, sGateway, sBotToken, 'getUpdates', jsonMsg.AsJSon, iTimeout * 10000));
end;

function tg_SendMessage(const aProxy: PProxyData; const sGateway, sBotToken: string; const iTimeout: Integer;
  const idChat: Int64; const sMessage, sMarkup: string; const idReply: Int64;
  const bNotNotify: Boolean = False; const bShowLinks: Boolean = False): tTgMessage;
var
  jsonMsg, jsonRes: ISuperObject;
begin
  FillChar(Result, SizeOf(Result), 0);

  jsonMsg := SO;
  jsonMsg.I['chat_id'] := idChat;
  jsonMsg.S['text'] := sMessage;
  jsonMsg.S['parse_mode'] := 'HTML';
  if idReply <> 0 then
    jsonMsg.I['reply_to_message_id'] := idReply;
  if bNotNotify then
    jsonMsg.B['disable_notification'] := True;
  if not bShowLinks then
    jsonMsg.B['disable_web_page_preview'] := True;
  if sMarkup <> EmptyStr then
    jsonMsg.O['reply_markup'] := SO(sMarkup);
  jsonRes := SO(tg_API(aProxy, sGateway, sBotToken, 'sendMessage', jsonMsg.AsJSon(), iTimeout));
  if Assigned(jsonRes) then
  begin
    if jsonRes.B['ok'] then Result := tg_MessageDecode(jsonRes['result'])
    else raise ETgError.CreateError(jsonRes.I['error_code'], jsonRes.S['description']);
  end
  else raise ETgError.CreateError(-1, rsErrJsonIsNull);
end;

procedure tg_DeleteMessage(const aProxy: PProxyData; const sGateway, sBotToken: string; const iTimeout: Integer;
  const idChat: Int64; const idMessage: Int64);
var
  jsonRes, jsonMsg: ISuperObject;
begin
  jsonMsg := SO;
  jsonMsg.I['chat_id'] := idChat;
  jsonMsg.I['message_id'] := idMessage;
  jsonRes := SO(tg_API(aProxy, sGateway, sBotToken, 'deleteMessage', jsonMsg.AsJSon, iTimeout));
  if Assigned(jsonRes) then
  begin
    if not jsonRes.B['ok'] then
      raise ETgError.CreateError(jsonRes.I['error_code'], jsonRes.S['description']);
  end
  else raise ETgError.CreateError(-1, rsErrJsonIsNull);
end;

end.
