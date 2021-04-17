unit rTgAPI;

interface

uses
  SuperObject, rHttpUtils, rProxy;

type
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

  TTgAPI = class
  private
    fToken: string;
    fProxy: TProxyListCustom;
  protected
    function DecodeFrom(const jsonUser: ISuperObject): tTgUser;
    function DecodeFromChat(const jsonChat: ISuperObject): tTgUser;
    function DecodeChat(const jsonChat: ISuperObject): tTgChat;
    function DecodeMessage(const jsonMsg: ISuperObject): tTgMessage;
    function DecodeCallback(const jsonMsg: ISuperObject): tTgMessage;
    function DecodeUpdate(const jsonUpd: ISuperObject): tTgUpdate;
    function DecodeUpdates(const jsonRes: ISuperObject; var bOk: Boolean): tTgUpdates;
    function ParseUpdates(const jsonRes: string; var bOk: Boolean): tTgUpdates;

    function CallAPI(const sApiMethod, sParams: string): string;
  public
    constructor Create(plProxy: TProxyListCustom; const aToken: string);

    function  UpdatesGet(const idOffset: Int64; var bOk: Boolean): tTgUpdates;
    function  UpdatesWait(const idOffset: Int64; const iTimeout: Integer; var bOk: Boolean): tTgUpdates;

    function  SendMessage(const idChat: Int64; const sMessage, sMarkup: string; const idReply: Int64;
      const bNotNotify: Boolean = False; const bShowLinks: Boolean = False): tTgMessage;
    procedure DeleteMessage(const idChat, idMessage: Int64);
  end;

implementation

uses
  SysUtils, Classes,
  IdTCPConnection, IdTCPClient, IdIcmpClient, IdHTTP, IdCompressorZLib, IdReplyRFC,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdCookieManager,
  rDialogs;


{ TTgAPI }

constructor TTgAPI.Create(plProxy: TProxyListCustom; const aToken: string);
begin
  fToken := aToken;
  fProxy := plProxy;
end;

{ -- Decode structures --------------------------------------------------------- }

function TTgAPI.DecodeFrom(const jsonUser: ISuperObject): tTgUser;
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

function TTgAPI.DecodeFromChat(const jsonChat: ISuperObject): tTgUser;
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


function TTgAPI.DecodeChat(const jsonChat: ISuperObject): tTgChat;
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

function TTgAPI.DecodeMessage(const jsonMsg: ISuperObject): tTgMessage;
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
      tgChat := DecodeChat(jsonMsg.O['chat']);
      if Assigned(jsonMsg.O['from'])
      then tgFrom := DecodeFrom(jsonMsg.O['from'])
      else tgFrom := DecodeFromChat(jsonMsg.O['chat']);
    end;
  end;
end;

function TTgAPI.DecodeCallback(const jsonMsg: ISuperObject): tTgMessage;
begin
  FillChar(Result, SizeOf(Result), 0);

  if Assigned(jsonMsg) then
  begin
    with Result do
    begin
      idMsg := jsonMsg.O['message'].I['message_id'];
      sJson := jsonMsg.AsString;
      sText := jsonMsg.S['data'];
      tgChat := DecodeChat(jsonMsg.O['message'].O['chat']);
      tgFrom := DecodeFrom(jsonMsg.O['from']);
    end;
  end;
end;

function TTgAPI.DecodeUpdate(const jsonUpd: ISuperObject): tTgUpdate;
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
        tgMsg := DecodeMessage(jsonUpd.O['message']);
      end;

      if jsonUpd.S['edited_message'] <> EmptyStr then
      begin
        tgType := tgmEditedMessage;
        tgMsg := DecodeMessage(jsonUpd.O['edited_message']);
      end;

      if jsonUpd.S['channel_post'] <> EmptyStr then
      begin
        tgType := tgmChannelPost;
        tgMsg := DecodeMessage(jsonUpd.O['channel_post']);
      end;

      if jsonUpd.S['callback_query'] <> EmptyStr then
      begin
        tgType := tgmCallbackQuery;
        tgMsg := DecodeCallback(jsonUpd.O['callback_query']);
      end;
    end;
  end;
end;

function TTgAPI.DecodeUpdates(const jsonRes: ISuperObject; var bOk: Boolean): tTgUpdates;
var
  jsonUpds: TSuperArray;
  i, iCount: Integer;
begin
  SetLength(Result, 0);

  if Assigned(jsonRes) and jsonRes.B['ok'] then
  begin
    bOk := True;
    jsonUpds := jsonRes['result'].AsArray;

    iCount := jsonUpds.Length;
    if iCount > 0 then
    begin
      SetLength(Result, iCount);

      for i := 0 to iCount - 1 do
        Result[i] := DecodeUpdate(jsonUpds[i]);
    end;
  end
  else bOk := False;
end;

function TTgAPI.ParseUpdates(const jsonRes: string; var bOk: Boolean): tTgUpdates;
begin
  Result := DecodeUpdates(SO(jsonRes), bOk);
end;

{ -- Call API ------------------------------------------------------------------ }

function TTgAPI.CallAPI(const sApiMethod, sParams: string): string;
var
  IdHTTP: TIdHTTP;
  IdCZip: TIdCompressorZLib;
  IdCSLL: TIdSSLIOHandlerSocketOpenSSL;
  iErrCnt: Integer;
  fRequest, fResponse: TStringStream;
  fProxy403: TProxyData;
  bState: Boolean;
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
    IdHTTP.HandleRedirects := True;
    IdHTTP.Request.Accept := 'application/json';
    IdHTTP.Request.ContentType := 'application/json';
    IdHTTP.Request.AcceptEncoding := 'gzip, deflate, sdch';
    IdHTTP.Request.UserAgent := 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.80 Safari/537.36';
    IdHTTP.IOHandler := IdCSLL;

    if Assigned(fProxy) then
    begin
      with fProxy.GetProxy do
      begin
        IdHTTP.ProxyParams.ProxyServer := sServer;
        IdHTTP.ProxyParams.ProxyPort := iPort;
        IdHTTP.ProxyParams.ProxyUsername := sUsername;
        IdHTTP.ProxyParams.ProxyPassword := sPassword;
      end;
    end;

    iErrCnt := 0;
    FillChar(fProxy403, SizeOf(fProxy403), 0);
    repeat
      try
        bState := False;
        try
          IdHTTP.Post(Format('https://api.telegram.org/bot%0:s/%1:s', [fToken, sApiMethod]), fRequest, fResponse);

          bState := True;
          if Assigned(fProxy) then
            fProxy.FixTry(True);
          if fProxy403.sServer <> EmptyStr then
            fProxy.FixTry(fProxy403, False);
        finally
          IdHTTP.Disconnect;
        end;
      except
        on E: Exception do
        begin
          if (E.ClassType = EIdHTTPProtocolException) then
          begin
            if Assigned(fProxy) then
            begin
              // 400 Bad Request
              if EIdReplyRFCError(E).ErrorCode = 400 then
              begin
                fProxy.FixTry(True);
                raise;
              end;

              // 429 Too Many Requests
              if EIdReplyRFCError(E).ErrorCode = 429 then
              begin
                fProxy.FixTry(True);
                raise;
              end;

              // 403 Forbidden
              if EIdReplyRFCError(E).ErrorCode = 403 then
              begin
                if fProxy403.sServer = EmptyStr then
                begin
                  fProxy403.sServer := IdHTTP.ProxyParams.ProxyServer;
                  fProxy403.iPort := IdHTTP.ProxyParams.ProxyPort;
                  fProxy403.sUsername := IdHTTP.ProxyParams.ProxyUsername;
                  fProxy403.sPassword := IdHTTP.ProxyParams.ProxyPassword;
                end;

                Inc(iErrCnt);
                if iErrCnt < fProxy.Count then
                begin
                  fProxy.Next;
                  Continue;
                end
                else raise;
              end;

              // Proxy error
              Inc(iErrCnt);
              if iErrCnt < 30
              then fProxy.FixTry(False)
              else raise;
            end
            else raise;
          end
          else raise;
        end;
      end;
    until bState;

    fResponse.Position := 0;
    Result := fResponse.DataString;
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

{ -- Public -------------------------------------------------------------------- }

function TTgAPI.UpdatesGet(const idOffset: Int64; var bOk: Boolean): tTgUpdates;
var
  jsonMsg: ISuperObject;
begin
  jsonMsg := SO;
  jsonMsg.I['offset'] := idOffset;

  Result := ParseUpdates(CallAPI('getUpdates', jsonMsg.AsJSon), bOk);
end;

function TTgAPI.UpdatesWait(const idOffset: Int64; const iTimeout: Integer; var bOk: Boolean): tTgUpdates;
var
  jsonMsg: ISuperObject;
begin
  jsonMsg := SO;
  jsonMsg.I['offset'] := idOffset;
  jsonMsg.I['timeout'] := iTimeout;

  Result := ParseUpdates(CallAPI('getUpdates', jsonMsg.AsJSon), bOk);
end;

function TTgAPI.SendMessage(const idChat: Int64; const sMessage, sMarkup: string; const idReply: Int64;
  const bNotNotify: Boolean = False; const bShowLinks: Boolean = False): tTgMessage;
var
  jsonMsg, jsonRes: ISuperObject;
begin
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

  jsonRes := SO(CallAPI('sendMessage', jsonMsg.AsJSon));
  if Assigned(jsonRes) and jsonRes.B['ok']
  then Result := DecodeMessage(jsonRes['result'])
  else FillChar(Result, SizeOf(Result), 0);
end;

procedure TTgAPI.DeleteMessage(const idChat: Int64; const idMessage: Int64);
var
  jsonMsg: ISuperObject;
begin
  jsonMsg := SO;
  jsonMsg.I['chat_id'] := idChat;
  jsonMsg.I['message_id'] := idMessage;
  CallAPI('deleteMessage', jsonMsg.AsJSon);
end;

end.
