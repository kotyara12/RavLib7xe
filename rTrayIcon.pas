unit rTrayIcon;

interface

uses
  Messages, Forms, Graphics;

const
  tiAdd        = 1;
  tiDelete     = 2;
  tiModify     = 3;

  WM_TRAYICON  = WM_USER + $1200;

procedure ShowTrayIcon(AForm: TForm; AIcon: TIcon;
  const AIconMode: Integer; const AHintText: string = '');
procedure ShowTrayIcon_MainForm(AForm: TForm;
  const AIconMode: Integer; const AHintText: string = '');

implementation

uses
  Windows, ShellApi, SysUtils;

resourcestring
  ssICON_IconFormNotFound      = '»конка формы не найдена!';

procedure ShowTrayIcon(AForm: TForm; AIcon: TIcon; const AIconMode: Integer; const AHintText: string = '');
var
  Nim: TNotifyIconData;
begin
  with Nim do
    begin
      // cbSize := SizeOf(TNotifyIconData);
      cbSize := SizeOf;
      Wnd := AForm.Handle;
      uID := 0;
      uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
      if AIcon <> nil
      then hIcon := AIcon.Handle
      else hIcon := 0;
      uCallbackMessage := WM_TRAYICON;
    end;
    if AHintText = EmptyStr
    then StrPLCopy(Nim.szTip, AForm.Caption, SizeOf(Nim.szTip) - SizeOf(Char))
    else StrPLCopy(Nim.szTip, AHintText, SizeOf(Nim.szTip) - SizeOf(Char));
  case AIconMode of
    tiAdd:    Shell_NotifyIcon(Nim_Add, @Nim);
    tiDelete: Shell_NotifyIcon(Nim_Delete, @Nim);
    tiModify: Shell_NotifyIcon(Nim_Modify, @Nim);
  end;
end;

procedure ShowTrayIcon_MainForm(AForm: TForm; const AIconMode: Integer; const AHintText: string = '');
begin
  if AForm.Icon <> nil then
    ShowTrayIcon(AForm, AForm.Icon, AIconMode, AHintText);
end;

end.
