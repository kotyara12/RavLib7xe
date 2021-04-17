unit RMultInst2;

// (C) Copyright by RavSoft.
// Данный модуль блокирует запуск второй копии программы.
// Для реализации этой функции просто включите его в раздел uses программы.
// Модуль основан на методе Пачеко (Pacheco) и Тайхайра (Teixeira).

interface

const
  MI_QUERYWINDOWHANDLE   = 1;
  MI_RESPONDWINDOWHANDLE = 2;

  MI_NO_ERROR            = 0;
  MI_FAIL_SUBCLASS       = 1;
  MI_FAIL_CREATE_MUTEX   = 2;

function GetMIError: Integer;

implementation

uses Forms, Windows, SysUtils, StrUtils, rDialogs;

resourcestring
  rsERR_FAIL_SUBCLASS_S        = 'Ошибка инициализации процедуры обработки сообщений Windows!';
  rsERR_FAIL_CREATE_MUTEX_S    = 'Ошибка создания мьютекса "%s"!';

var
  UniqueAppStr: string;
  RegMsgId: Integer;
  WProc: TFNWndProc = nil;
  MutexHandle: THandle = 0;
  MIError: Integer = 0;

function GetMIError: Integer;
begin
  Result := MIError;
end;

function RMultInstWndProc(Handle: HWND; Msg: Integer; wParam, lParam: Longint): Longint; stdcall;
begin
  Result := 0;
  if Msg = RegMsgId then
  begin
    case wParam of
      MI_QUERYWINDOWHANDLE:
      begin
        {$IFDEF HIDDENAPP}
          if IsWindowVisible(Application.Handle) then
          begin
            if IsIconic(Application.Handle) then
              Application.Restore;
            if not IsWindowVisible(Application.MainForm.Handle) then
              ShowWindow(Application.MainForm.Handle, SW_SHOWNORMAL);
            Application.BringToFront;
          end;
        {$ELSE}
          if IsIconic(Application.Handle) then Application.Restore;
          if not IsWindowVisible(Application.Handle) then
            ShowWindow(Application.Handle, SW_SHOWNORMAL);
          if not IsWindowVisible(Application.MainForm.Handle) then
            ShowWindow(Application.MainForm.Handle, SW_SHOWNORMAL);
          Application.BringToFront;
        {$ENDIF}
        PostMessage(HWND(lParam), RegMsgId, MI_RESPONDWINDOWHANDLE, Application.MainForm.Handle);
      end;
      MI_RESPONDWINDOWHANDLE:
      begin
        SetForegroundWindow(HWND(lParam));
        Application.Terminate;
      end;
    end;
  end
  else
    Result := CallWindowProc(WProc, Handle, Msg, wParam, lParam);
end;

procedure SubClassApplication;
begin
  WProc := TFNWndProc(SetWindowLong(Application.Handle, GWL_WNDPROC, Longint(@RMultInstWndProc)));
  if WProc = nil then
  begin
    MIError := MIError or MI_FAIL_SUBCLASS;
    {$IFNDEF HIDDENAPP}
    ErrorBox(rsERR_FAIL_SUBCLASS_S);
    {$ENDIF}
  end;
end;

procedure BroadcastFocusMessage;
var
  BSMRecipients: DWORD;
begin
  Application.ShowMainForm := False;
  BSMRecipients := BSM_APPLICATIONS;
  BroadCastSystemMessage(BSF_IGNORECURRENTTASK or BSF_POSTMESSAGE, @BSMRecipients,
    RegMsgId, MI_QUERYWINDOWHANDLE, Application.Handle);
end;

procedure DoFirstInstance;
begin
  MutexHandle := CreateMutex(nil, False, PChar(UniqueAppStr));
  if MutexHandle = 0 then
  begin
    MIError := MIError or MI_FAIL_CREATE_MUTEX;
    {$IFDEF HIDDENAPP}
    BroadcastFocusMessage; // 07.12.09 - close HIDDEN application on error
    {$ELSE}
    ErrorBox(Format(rsERR_FAIL_CREATE_MUTEX_S, [UniqueAppStr]));
    {$ENDIF}
  end;
end;

procedure InitInstance;
begin
  SubClassApplication;
  if OpenMutex(MUTEX_ALL_ACCESS, False, PWideChar(UniqueAppStr)) = 0
  then DoFirstInstance
  else BroadcastFocusMessage;
end;

initialization
  UniqueAppStr := AnsiReplaceText(Application.ExeName, '\', '-');
  RegMsgId := RegisterWindowMessage(PWideChar(UniqueAppStr));
  InitInstance;

finalization
  if WProc <> nil then
    SetWindowLong(Application.Handle, GWL_WNDPROC, LongInt(WProc));
  if MutexHandle <> 0 then
  begin
    ReleaseMutex(MutexHandle);
    CloseHandle(MutexHandle);
  end;
end.

