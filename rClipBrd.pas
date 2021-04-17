{ **** UBPFD *********** by delphibase.endimus.com ****
>> ���������/�������� ������ �� ������ ������ (�������� � �����������)

��� Win2k ������� �������� ������� ������ � Clipboard ClipBoard.AsText:='�����'
� ����������� �������� � Word'� ���������� ������������..
������������� ��������, ��� �������� ����������� (��� ������ :) )
� ����� ������������� �������� ����� ����� Win-����������� ���� �������� ��� 2 �-���..
��������� �� ����/���������� ������ � Unicode - WideString..
�� �� ���� ������������, ������ ��� ������� ��� �������������
����������� �/�� AnsiString.

���� ��������� ������������ ������ (NT), �� ������������ ���� ������,
����� ���������� ����������� ���������/�-���.
�����!

�����������: ClipBrd
�����:       Shaman_Naydak, shanturov@pisem.net
Copyright:   Shaman_Naydak
����:        26 ���� 2002 �.
***************************************************** }

unit RClipBrd;

interface

procedure PutStringIntoClipBoard(const Str: WideString);
function  GetStringFromClipboard: WideString;

implementation

uses
  Windows, Messages, Classes, Graphics, ClipBrd;

procedure PutStringIntoClipBoard(const Str: WideString);
var
  Size: Integer;
  Data: THandle;
  DataPtr: Pointer;
begin
  Size := Length(Str);
  if Size = 0 then
    exit;
  if not IsClipboardFormatAvailable(CF_UNICODETEXT) then
    Clipboard.AsText := Str
  else begin
    Size := Size shl 1 + 2;
    Data := GlobalAlloc(GMEM_MOVEABLE + GMEM_DDESHARE, Size);
    try
      DataPtr := GlobalLock(Data);
      try
        Move(Pointer(Str)^, DataPtr^, Size);
        Clipboard.SetAsHandle(CF_UNICODETEXT, Data);
      finally
        GlobalUnlock(Data);
      end;
    except
      GlobalFree(Data);
      raise;
    end;
  end;
end;

function GetStringFromClipboard: WideString;
var
  Data: THandle;
begin
  if not IsClipboardFormatAvailable(CF_UNICODETEXT) then
    Result := Clipboard.AsText
  else begin
    Clipboard.Open;
    Data := GetClipboardData(CF_UNICODETEXT);
    try
      if Data <> 0 then
        Result := PWideChar(GlobalLock(Data))
      else
        Result := '';
    finally
      if Data <> 0 then
        GlobalUnlock(Data);
      Clipboard.Close;
    end;
  end;
end;

end.
