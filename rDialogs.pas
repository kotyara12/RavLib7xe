unit RDialogs;

interface

function  CustomMsgBox(const Caption, Text: string; Flags: Integer): Integer;
function  ErrorBox(const Text: string): Integer;
function  InfoBox(const Text: string): Integer;
function  CautionBox(const Text: string): Integer;
function  WarningBox(const Text: string): Integer;
function  WarningBoxYN(const Text: string): Integer;
function  WarningBoxNY(const Text: string): Integer;
function  ErrorBoxYN(const Text: string): Integer;
function  ErrorBoxNY(const Text: string): Integer;
function  QueryBoxYN(const Caption, Text: string): Integer;
function  QueryBoxNY(const Caption, Text: string): Integer;
function  QueryBoxYNC(const Caption, Text: string): Integer;
function  QueryBoxNYC(const Caption, Text: string): Integer;
function  QueryBoxCYN(const Caption, Text: string): Integer;
function  QueryBoxStdYN(const Text: string): Integer;
function  QueryBoxStdNY(const Text: string): Integer;
function  QueryBoxStdYNC(const Text: string): Integer;
function  QueryBoxStdNYC(const Text: string): Integer;
function  QueryBoxStdCYN(const Text: string): Integer;
function  DeleteQueryStd: Boolean;
function  DeleteQueryName(const Name: string): Boolean;
function  DeleteQueryText(const Text: string): Boolean;
function  DeleteQueryMulti(const RecCount: Integer): Boolean;
function  CloseAppQuery: Boolean;
procedure StrNotFoundBox(const Text: string);

resourcestring
  SDlgError             = 'Ошибка';
  SDlgInfo              = 'Информация';
  SDlgCaution           = 'Внимание!';
  SDlgWarning           = 'Предупреждение';
  SDlgQuery             = 'Подтверждение';

  SMsgStrNotFound       = 'Строка "%s" не найдена!';
  SMsgProcessCounts     = 'Из %d записей успешно обработано - %d, пропущено - %d.';

  SQueryDeleteSelected  = 'Удалить выделенную запись?';
  SQueryDeleteCount     = 'Удалить все выделенные записи (всего будет удалено %d записи(ей))?';
  SQueryDeleteText      = 'Удалить запись "%s"?';
  SQueryCloseApp        = 'Завершить работу с программой?';
  SQueryBreakOperation  = 'Во время обработки данных произошла ошибка. Прервать выполнение операции?';
  (* SQueryProcAllRecords  = 'Обработать все показанные записи (всего %d записи(ей)) - "Да" / "Yes",'#13 +
                          'либо только выделенные записи (выбрано %d записи(ей)) - "Нет" / "No"?'#13#13 +
                          'Для отмены операции и выхода без обработки нажмите "Отмена" / "Cancel".'; *)

implementation

uses
  SysUtils, Themes, Forms, Controls, Windows;
  
function CustomMsgBox(const Caption, Text: string; Flags: Integer): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(Caption), Flags);
end;

function ErrorBox(const Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(SDlgError), MB_ICONERROR + MB_OK);
end;

function InfoBox(const Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(SDlgInfo), MB_ICONINFORMATION + MB_OK);
end;

function CautionBox(const Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(SDlgCaution), MB_ICONWARNING + MB_OK);
end;

function WarningBox(const Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(SDlgWarning), MB_ICONWARNING + MB_OK);
end;

function WarningBoxYN(const Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(SDlgWarning), MB_ICONWARNING + MB_YESNO + MB_DEFBUTTON1);
end;

function WarningBoxNY(const Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(SDlgWarning), MB_ICONWARNING + MB_YESNO + MB_DEFBUTTON2);
end;

function ErrorBoxYN(const Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(SDlgWarning), MB_ICONERROR + MB_YESNO + MB_DEFBUTTON1);
end;

function ErrorBoxNY(const Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(SDlgWarning), MB_ICONERROR + MB_YESNO + MB_DEFBUTTON2);
end;

function QueryBoxYN(const Caption, Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(Caption), MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON1);
end;

function QueryBoxNY(const Caption, Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(Caption), MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2);
end;

function QueryBoxYNC(const Caption, Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(Caption), MB_ICONQUESTION + MB_YESNOCANCEL + MB_DEFBUTTON1);
end;

function QueryBoxNYC(const Caption, Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(Caption), MB_ICONQUESTION + MB_YESNOCANCEL + MB_DEFBUTTON2);
end;

function QueryBoxCYN(const Caption, Text: string): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(Caption), MB_ICONQUESTION + MB_YESNOCANCEL + MB_DEFBUTTON3);
end;

function QueryBoxStdYN(const Text: string): Integer;
begin
  Result := QueryBoxYN(SDlgQuery, Text);
end;

function QueryBoxStdNY(const Text: string): Integer;
begin
  Result := QueryBoxNY(SDlgQuery, Text);
end;

function QueryBoxStdYNC(const Text: string): Integer;
begin
  Result := QueryBoxYNC(SDlgQuery, Text);
end;

function QueryBoxStdNYC(const Text: string): Integer;
begin
  Result := QueryBoxNYC(SDlgQuery, Text);
end;

function QueryBoxStdCYN(const Text: string): Integer;
begin
  Result := QueryBoxCYN(SDlgQuery, Text);
end;

function DeleteQueryStd: Boolean;
begin
  Result := QueryBoxNY(SDlgWarning, SQueryDeleteSelected)= IDYES;
end;

function DeleteQueryName(const Name: string): Boolean;
begin
  Result := QueryBoxNY(SDlgWarning, Format(SQueryDeleteText, [Name]))= IDYES;
end;

function DeleteQueryText(const Text: string): Boolean;
begin
  Result := QueryBoxNY(SDlgWarning, Text)= IDYES;
end;

function DeleteQueryMulti(const RecCount: Integer): Boolean;
begin
  if RecCount = 1
  then Result := QueryBoxNY(SDlgWarning, SQueryDeleteSelected)= IDYES
  else Result := QueryBoxNY(SDlgWarning, Format(SQueryDeleteCount, [RecCount]))= IDYES;
end;

function CloseAppQuery: Boolean;
begin
  Result := QueryBoxNY(Application.Title, SQueryCloseApp)= IDYES;
end;

procedure StrNotFoundBox(const Text: string);
begin
  InfoBox(Format(SMsgStrNotFound, [Text]));
end;

end.

