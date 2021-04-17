unit rTgIntf2;

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

  tTgAccessMode = (tgaDirectly, tgaProxy, tgaGateway);

  tTgBotAuth = record
    fAccessMode: tTgAccessMode;
    sGateway: string;
    sBotToken: string;
    iTimeout: Integer;
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
    tgUser: tTgUser;
    iDate: Int64;
    iUntilDate: Int64;
    sText: string;
  end;

  tTgUpdateType = (tgmUnknown, tgmMessage, tgmEditedMessage, tgmChannelPost, tgmCallbackQuery, tgmMyChatMember);

  tTgUpdate = record
    idUpd: Int64;
    sJson: string;
    tgType: tTgUpdateType;
    tgMsg: tTgMessage;
  end;

  tTgUpdates = array of tTgUpdate;

const
  stgApiProxyHist    = 'https://api.telegram.org/bot_{token}/';
  stgApiDirectly     = 'https://api.telegram.org/bot%0:s/%1:s';
  stgApiGateway      = '?bot=%0:s&method=%1:s';

  stgHttpJSON        = 'application/json';
  stgHttpEncoding    = 'gzip, deflate, sdch';
  stgHttpUserAgent   = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36';

  stgApiGetMe        = 'getMe';
  stgApiGetUpdates   = 'getUpdates';
  stgApiSendMessage  = 'sendMessage';
  stgApiDelMessage   = 'deleteMessage';

  stgOk              = 'ok';
  stgResult          = 'result';
  stgId              = 'id';
  stgChat            = 'chat';
  stgChatId          = 'chat_id';
  stgType            = 'type';
  stgDate            = 'date';
  stgData            = 'data';
  stgText            = 'text';
  stgFrom            = 'from';
  stgIsBot           = 'is_bot';
  stgStatus          = 'status';
  stgUntilDate       = 'until_date';
  stgUser            = 'user';
  stgKicked          = 'kicked';
  stgMember          = 'member';
  stgMessageId       = 'message_id';
  stgUpdateId        = 'update_id';
  stgReplyId         = 'reply_to_message_id';
  stgNotifyDisable   = 'disable_notification';
  stgWebPrevDisable  = 'disable_web_page_preview';
  stgNewChatMember   = 'new_chat_member';
  stgTitle           = 'title';
  stgUsername        = 'username';
  stgFirstName       = 'first_name';
  stgLastName        = 'last_name';
  stgLangCode        = 'language_code';
  stgMessage         = 'message';
  stgMarkup          = 'reply_markup';
  stgParseMode       = 'parse_mode';
  stgOffset          = 'offset';
  stgTimeout         = 'timeout';
  stgErrorCode       = 'error_code';
  stgErrorDesc       = 'description';
  stgParseHTML       = 'HTML';
  stgUpdateType: array [tTgUpdateType] of string =
                      ('unknown',
                       'message',
                       'edited_message',
                       'channel_post',
                       'callback_query',
                       'my_chat_member');

function  tg_UpdatesParse(const jsonRes: string): tTgUpdates;
procedure tg_UpdatesFree(var arrUpdates: tTgUpdates);
function  tg_GetMe(const botAuth: tTgBotAuth): tTgUser;
function  tg_UpdatesGet(const botAuth: tTgBotAuth; const idOffset: Int64; var bOk: Boolean): tTgUpdates;
function  tg_UpdatesWait(const botAuth: tTgBotAuth; const idOffset: Int64; const iTimeout: Integer): tTgUpdates;
function  tg_SendMessage(const botAuth: tTgBotAuth;
  const idChat: Int64; const sMessage, sMarkup: string; const idReply: Int64;
  const bNotNotify: Boolean = False; const bShowLinks: Boolean = False): tTgMessage;
procedure tg_DeleteMessage(const botAuth: tTgBotAuth; const idChat: Int64; const idMessage: Int64);

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

function tg_ResultAsJson(const strJson: string): ISuperObject;
begin
  Result := SO(strJson);
  if Assigned(Result) then
  begin
    if not Result.B[stgOk] then
      raise ETgError.CreateError(Result.I[stgErrorCode], Result.S[stgErrorDesc]);
  end
  else raise ETgError.CreateError(-1, rsErrJsonIsNull);
end;

function tg_UserDecode(const jsonUser: ISuperObject): tTgUser;
begin
  Initialize(Result);
  if Assigned(jsonUser) then
  begin
    with Result do
    begin
      idUser := jsonUser.I[stgId];
      sJson := jsonUser.AsString;
      bIsBot := jsonUser.B[stgIsBot];
      sUsername := jsonUser.S[stgUsername];
      sFirstName := jsonUser.S[stgFirstName];
      sLastName := jsonUser.S[stgLastName];
      sLngCode := jsonUser.S[stgLangCode];

      if sUsername = EmptyStr then
        sUsername := IntToStr(idUser);

      if sFirstName <> EmptyStr then
        sFullName := sFirstName;
      if sLastName <> EmptyStr then
      begin
        if sFullName = EmptyStr
        then sFullName := sLastName
        else begin
          if not SameText(sFirstName, sLastName) then
            sFullName := sFullName + #32 + sLastName;
        end;
      end;
      if sFullName = EmptyStr then
        sFullName := sUsername;
    end;
  end;
end;

function tg_FromChatDecode(const jsonChat: ISuperObject): tTgUser;
begin
  Initialize(Result);
  if Assigned(jsonChat) then
  begin
    with Result do
    begin
      idUser := jsonChat.I[stgId];
      sJson := jsonChat.AsString;
      bIsBot := False;
      sUsername := jsonChat.S[stgUsername];
      if sUsername = EmptyStr then
        sUsername := jsonChat.S[stgTitle];
      sFirstName := jsonChat.S[stgFirstName];
      sLastName := jsonChat.S[stgLastName];
      sLngCode := jsonChat.S[stgLangCode];

      if sUsername = EmptyStr then
        sUsername := IntToStr(idUser);

      if sFirstName <> EmptyStr then
        sFullName := sFirstName;
      if sLastName <> EmptyStr then
      begin
        if sFullName = EmptyStr
        then sFullName := sLastName
        else begin
          if not SameText(sFirstName, sLastName) then
            sFullName := sFullName + #32 + sLastName;
        end;
      end;
      if sFullName = EmptyStr then
        sFullName := sUsername;
    end;
  end;
end;

function tg_ChatDecode(const jsonChat: ISuperObject): tTgChat;
begin
  Initialize(Result);
  if Assigned(jsonChat) then
  begin
    with Result do
    begin
      idChat := jsonChat.I[stgId];
      sJson := jsonChat.AsString;
      if jsonChat.S[stgTitle] = EmptyStr
      then sTitle := jsonChat.S[stgUsername]
      else sTitle := jsonChat.S[stgTitle];
      sChatType := jsonChat.S[stgType];
    end;
  end;
end;

function tg_MessageDecode(const jsonMsg: ISuperObject): tTgMessage;
begin
  Initialize(Result);
  if Assigned(jsonMsg) then
  begin
    with Result do
    begin
      idMsg := jsonMsg.I[stgMessageId];
      if idMsg = 0 then idMsg := jsonMsg.I[stgId];
      sJson := jsonMsg.AsString;
      iDate := jsonMsg.I[stgDate];
      sText := jsonMsg.S[stgText];
      tgChat := tg_ChatDecode(jsonMsg.O[stgChat]);
      if Assigned(jsonMsg.O[stgFrom])
      then tgFrom := tg_UserDecode(jsonMsg.O[stgFrom])
      else tgFrom := tg_FromChatDecode(jsonMsg.O[stgChat]);
    end;
  end;
end;

function tg_CallbackDecode(const jsonMsg: ISuperObject): tTgMessage;
begin
  Initialize(Result);
  if Assigned(jsonMsg) then
  begin
    with Result do
    begin
      idMsg := jsonMsg.O[stgMessage].I[stgMessageId];
      sJson := jsonMsg.AsString;
      sText := jsonMsg.S[stgData];
      tgChat := tg_ChatDecode(jsonMsg.O[stgMessage].O[stgChat]);
      tgFrom := tg_UserDecode(jsonMsg.O[stgFrom]);
    end;
  end;
end;

function tg_ChatMemberDecode(const jsonMsg: ISuperObject): tTgMessage;
begin
  Initialize(Result);
  if Assigned(jsonMsg) then
  begin
    with Result do
    begin
      idMsg := jsonMsg.I[stgDate];
      sJson := jsonMsg.AsString;
      iDate := jsonMsg.I[stgDate];
      sText := jsonMsg.O[stgNewChatMember].S[stgStatus];
      iUntilDate := jsonMsg.O[stgNewChatMember].I[stgUntilDate];
      tgUser := tg_UserDecode(jsonMsg.O[stgNewChatMember].O[stgUser]);
      tgChat := tg_ChatDecode(jsonMsg.O[stgChat]);
      tgFrom := tg_UserDecode(jsonMsg.O[stgFrom]);
    end;
  end;
end;

function tg_UpdateDecode(const jsonUpd: ISuperObject): tTgUpdate;
var
  i: tTgUpdateType;
begin
  Initialize(Result);
  if Assigned(jsonUpd) then
  begin
    with Result do
    begin
      idUpd := jsonUpd.I[stgUpdateId];
      sJson := jsonUpd.AsString;

      tgType := tgmUnknown;
      for i := tgmMessage to High(tTgUpdateType) do
      begin
        if jsonUpd.S[stgUpdateType[i]] <> EmptyStr then
        begin
          tgType := i;
          case tgType of
            tgmMyChatMember:
              tgMsg := tg_ChatMemberDecode(jsonUpd.O[stgUpdateType[i]]);
            tgmCallbackQuery:
              tgMsg := tg_CallbackDecode(jsonUpd.O[stgUpdateType[i]]);
            else
              tgMsg := tg_MessageDecode(jsonUpd.O[stgUpdateType[i]]);
          end;
          Break;
        end;
      end;
    end;
  end;
end;

function tg_UpdatesDecode(const jsonRes: ISuperObject): tTgUpdates;
var
  jsonUpds: TSuperArray;
  i, iCount: Integer;
begin
  Initialize(Result);
  jsonUpds := jsonRes[stgResult].AsArray;
  iCount := jsonUpds.Length;
  if iCount > 0 then
  begin
    SetLength(Result, iCount);

    for i := 0 to iCount - 1 do
    begin
      Initialize(Result[i]);
      Result[i] := tg_UpdateDecode(jsonUpds[i]);
    end;
  end;
end;

function tg_UpdatesParse(const jsonRes: string): tTgUpdates;
var
  jsonUpdates: ISuperObject;
begin
  jsonUpdates := tg_ResultAsJson(jsonRes);
  try
    Result := tg_UpdatesDecode(jsonUpdates);
  finally
    Finalize(jsonUpdates);
  end;
end;

procedure tg_UpdatesFree(var arrUpdates: tTgUpdates);
var
  i: Integer;
begin
  if Length(arrUpdates) > 0 then
  begin
    for i := Low(arrUpdates) to High(arrUpdates) do
      Finalize(arrUpdates[i]);
    Finalize(arrUpdates);
  end;
end;

function tg_API(const botAuth: tTgBotAuth; const sApiMethod, sParams: string): string;
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
    if botAuth.iTimeout > 0 then
    begin
      IdHTTP.ConnectTimeout := botAuth.iTimeout;
      IdHTTP.ReadTimeout := botAuth.iTimeout;
    end;
    IdHTTP.HandleRedirects := True;
    IdHTTP.Request.Accept := stgHttpJSON;
    IdHTTP.Request.ContentType := stgHttpJSON;
    IdHTTP.Request.AcceptEncoding := stgHttpEncoding;
    IdHTTP.Request.UserAgent := stgHttpUserAgent;
    IdHTTP.IOHandler := IdCSLL;

    if (botAuth.fAccessMode = tgaProxy) and (botAuth.sGateway <> EmptyStr) then
    begin
      with rProxy_StrToProxy(botAuth.sGateway) do
      begin
        IdHTTP.ProxyParams.ProxyServer := sServer;
        IdHTTP.ProxyParams.ProxyPort := iPort;
        IdHTTP.ProxyParams.ProxyUsername := sUsername;
        IdHTTP.ProxyParams.ProxyPassword := sPassword;
      end;
    end;

    try
      try
        if (botAuth.fAccessMode = tgaGateway) and (botAuth.sGateway <> EmptyStr) then
        begin
          IdHTTP.Post(botAuth.sGateway + Format(stgApiGateway, [botAuth.sBotToken, sApiMethod]), fRequest, fResponse);
          Result := fResponse.DataString;
        end
        else begin
          IdHTTP.Post(Format(stgApiDirectly, [botAuth.sBotToken, sApiMethod]), fRequest, fResponse);
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

function tg_GetMe(const botAuth: tTgBotAuth): tTgUser;
var
  jsonRes: ISuperObject;
begin
  FillChar(Result, SizeOf(Result), 0);

  jsonRes := tg_ResultAsJson(tg_API(botAuth, stgApiGetMe, EmptyStr));
  try
    Result := tg_UserDecode(jsonRes[stgResult]);
  finally
    Finalize(jsonRes);
  end;
end;

function tg_UpdatesGet(const botAuth: tTgBotAuth; const idOffset: Int64; var bOk: Boolean): tTgUpdates;
var
  jsonMsg: ISuperObject;
begin
  jsonMsg := SO;
  try
    jsonMsg.I[stgOffset] := idOffset;

    Result := tg_UpdatesParse(tg_API(botAuth, stgApiGetUpdates, jsonMsg.AsJSon));
  finally
    Finalize(jsonMsg);
  end;
end;

function tg_UpdatesWait(const botAuth: tTgBotAuth; const idOffset: Int64; const iTimeout: Integer): tTgUpdates;
var
  jsonMsg: ISuperObject;
begin
  jsonMsg := SO;
  try
    jsonMsg.I[stgOffset] := idOffset;
    jsonMsg.I[stgTimeout] := iTimeout;

    Result := tg_UpdatesParse(tg_API(botAuth, stgApiGetUpdates, jsonMsg.AsJSon));
  finally
    Finalize(jsonMsg);
  end;
end;

function tg_SendMessage(const botAuth: tTgBotAuth;
  const idChat: Int64; const sMessage, sMarkup: string; const idReply: Int64;
  const bNotNotify: Boolean = False; const bShowLinks: Boolean = False): tTgMessage;
var
  jsonMsg, jsonRes: ISuperObject;
begin
  Initialize(Result);

  jsonMsg := SO;
  try
    jsonMsg.I[stgChatId] := idChat;
    jsonMsg.S[stgText] := sMessage;
    jsonMsg.S[stgParseMode] := stgParseHTML;
    if idReply <> 0 then
      jsonMsg.I[stgReplyId] := idReply;
    if bNotNotify then
      jsonMsg.B[stgNotifyDisable] := True;
    if not bShowLinks then
      jsonMsg.B[stgWebPrevDisable] := True;
    if sMarkup <> EmptyStr then
      jsonMsg.O[stgMarkup] := SO(sMarkup);
    jsonRes := tg_ResultAsJson(tg_API(botAuth, stgApiSendMessage, jsonMsg.AsJSon()));
    try
      Result := tg_MessageDecode(jsonRes[stgResult]);
    finally
      Finalize(jsonRes);
    end;
  finally
    Finalize(jsonMsg);
  end;
end;

procedure tg_DeleteMessage(const botAuth: tTgBotAuth; const idChat: Int64; const idMessage: Int64);
var
  jsonRes, jsonMsg: ISuperObject;
begin
  jsonMsg := SO;
  try
    jsonMsg.I[stgChatId] := idChat;
    jsonMsg.I[stgMessageId] := idMessage;
    jsonRes := tg_ResultAsJson(tg_API(botAuth, stgApiDelMessage, jsonMsg.AsJSon));
    Finalize(jsonRes);
  finally
    Finalize(jsonMsg);
  end;
end;

end.
