unit RVarListEx;

interface

uses
  SysUtils, Classes;

type
  ERVarListError        = class (Exception);

const
  VarDate               = 'Date:YYYY.MM.DD HH:NN:SS';
  VarDayOfWeek          = 'WeekDay';
  VarAppFile            = 'AppFile';
  VarAppDir             = 'AppDir';
  VarAppFull            = 'AppFull';
  VarRunDir             = 'RunDir';
  VarCurrDir            = 'CurrDir';
  VarComputerName       = 'ComputerName';
  VarComputerIp         = 'ComputerIp';
  VarUserName           = 'UserName';
  VarWindowsName        = 'WindowsName';
  VarWindowsNumber      = 'WindowsNumber';
  VarWindowsVersion     = 'WindowsVersion';
  VarWindowsVersionLng  = 'WindowsVersionLng';
  VarWindowsProductType = 'WindowsType';
  VarWindowsDir         = 'WindowsDirectory';
  VarWindowsSysDir      = 'WindowsSystemDirectory';
  VarWindowsPrograms    = 'WindowsPrograms';
  VarWindowsPrograms86  = 'WindowsPrograms_x86';
  VarWindowsPrgCommon   = 'WindowsProgramsCommon';
  VarWindowsPrgCommon86 = 'WindowsProgramsCommon_x86';
  VarWindowsDirSh       = 'WinDir';
  VarWindowsSysDirSh    = 'WinSysDir';

  VarAllUsersAppData    = 'WSD_AllUsers_AppData';
  VarAllUsersDesktop    = 'WSD_AllUsers_Desktop';
  VarAllUsersStartMenu  = 'WSD_AllUsers_StartMenu';
  VarAllUsersStartUp    = 'WSD_AllUsers_StartUp';
  VarAllUsersPrograms   = 'WSD_AllUsers_Programs';
  VarAllUsersDocuments  = 'WSD_AllUsers_Documents';
  VarAllUsersTemplates  = 'WSD_AllUsers_Templates';
  VarAllUsersFavorites  = 'WSD_AllUsers_Favorites';

  VarCurrUserProfile    = 'WSD_CurrUser_Profile';
  VarCurrUserAppData    = 'WSD_CurrUser_AppData';
  VarCurrUserDesktop    = 'WSD_CurrUser_Desktop';
  VarCurrUserStartMenu  = 'WSD_CurrUser_StartMenu';
  VarCurrUserStartUp    = 'WSD_CurrUser_StartUp';
  VarCurrUserPrograms   = 'WSD_CurrUser_Programs';
  VarCurrUserDocuments  = 'WSD_CurrUser_Documents';
  VarCurrUserTemplates  = 'WSD_CurrUser_Templates';
  VarCurrUserFavorites  = 'WSD_CurrUser_Favorites';
  VarCurrUserLocalData  = 'WSD_CurrUser_LocalAppData';
  VarCurrUserNetHood    = 'WSD_CurrUser_NetHood';
  VarCurrUserTemp       = 'WSD_CurrUser_Temp';

  DateTag      = 'DATE';
  WeekTag      = 'WEEKDAY';
  CharTag      = '$';
  DateChar     = ':';
  OffsChar     = '!';
  VarsChar     = '=';
  TagsDefC     = '%';
  DigChars     = ['0'..'9','.',',','+','-'];

{ == Выделяем из строки имя и значение переменной ============================== }
procedure StrToVariable(const FullStr: string; var VarName, VarValue: string);
function  VariableToStr(const VarName, VarValue: string): string;
{ == Выделение имени переменной из описания ==================================== }
function  ExtractVarName(const FullVarName: string; const TagsChar: Char = TagsDefC): string;
function  UpdateVarName(const VarName: string; const TagsChar: Char = TagsDefC): string;
{ == Добавление переменной в список ============================================ }
procedure AddVariable(Vars: TStrings; const VarName, VarValue: string); overload;
procedure AddVariable(Vars: TStrings; const VarText: string); overload;
procedure DelVariable(Vars: TStrings; const VarName: string);
{ == Добавление списка переменной в список ===================================== }
procedure AddVariableList(Vars: TStrings; const AddVars: TStrings); overload;
procedure AddVariableList(Vars: TStrings; const AddVars: string); overload;
{ == Добавление стандартных переменных ========================================= }
procedure AddStandartVariables(Vars: TStrings; const AddUsersFolders: Boolean);
procedure DelStandartVariables(Vars: TStrings; const DelAllUsersFolders, DelCurrUserFolders: Boolean);
{ == Получение имени переменной ================================================ }
function GetVariableName(Vars: TStrings; Index: Integer): string;
{ == Получение переменной по имени ============================================= }
function GetVariableValue(Vars: TStrings; const VarName: string; const CheckExists: Boolean = False): string;
{ == Получение переменной по имени с преобразованием =========================== }
function GetVariable(Vars: TStrings; const VarName: string;
  const VDate: TDateTime = 0; const TagsChar: Char = '%'): string;
function GetVariableNoErrors(Vars: TStrings; const VarName: string;
  const VDate: TDateTime = 0; const TagsChar: Char = '%'): string;
{ == Замена тегов в строке из произвольного списка ============================= }
function ReplaceTags(Vars: TStrings; const Source: string;
  const RaiseError: Boolean; const VDate: TDateTime = 0;
  const TagsChar: Char = TagsDefC; const ProcessDate: Boolean = True): string; overload;
function ReplaceTags(const Source, ExtVars: string; const RaiseError: Boolean): string; overload;
{ == Замена тегов в списке строк =============================================== }
procedure ReplaceList(Vars: TStrings; List: TStrings;
  const VDate: TDateTime = 0; const ProcessDate: Boolean = True);

implementation

uses
  RSysUtils, RIpTools, RWinVer, RDialogs, RVclUtils,
  DateUtils, Windows, ShellApi, ShlObj;

resourcestring
  ETagNotFound        = 'Переменная ''%%%s%%'' не найдена в списке переменных!';
  ETagUnterminatedTag = 'Незавершенная переменная в строке ''%s''!';
  ETagSymbolError     = 'Некорректный символ: ''%s''! Символ должен содержать префикс $ и код символа от 0 до 255.';

{ == Выделяем из строки имя и значение переменной ============================== }

procedure StrToVariable(const FullStr: string; var VarName, VarValue: string);
begin
  if Pos(VarsChar, FullStr) > 0 then
  begin
    VarName := Trim(Copy(FullStr, 1, Pos(VarsChar, FullStr) - 1));
    VarValue := Copy(FullStr, Pos(VarsChar, FullStr) + 1,
      Length(FullStr) - Pos(VarsChar, FullStr));
  end
  else begin
    VarName := FullStr;
    VarValue := EmptyStr;
  end;
end;

function VariableToStr(const VarName, VarValue: string): string;
begin
  Result := VarName + VarsChar + VarValue;
end;

{ == Выделение имени переменной из описания ==================================== }
function ExtractVarName(const FullVarName: string; const TagsChar: Char = TagsDefC): string;
begin
  Result := Trim(FullVarName);
  while (Length(Result) > 0) and (Result[1] = TagsChar) do
    Delete(Result, 1, 1);
  while (Length(Result) > 0) and (Result[Length(Result)] = TagsChar) do
    Delete(Result, Length(Result), 1);
end;

function UpdateVarName(const VarName: string; const TagsChar: Char = TagsDefC): string;
begin
  Result := ExtractVarName(VarName, TagsChar);
  if Result <> EmptyStr then
    Result := TagsChar + Result + TagsChar;
end;

{ == Добавление переменной в список ============================================ }
procedure AddVariable(Vars: TStrings; const VarName, VarValue: string);
begin
  if Vars.IndexOfName(VarName) = -1 then
    Vars.Add(VariableToStr(VarName, VarValue))
  else begin
    Vars.Values[VarName] := VarValue;
    // Bug fixed: Если значение переменной пустое, переменная удалялась
    if VarValue = EmptyStr then
      Vars.Add(VariableToStr(VarName, VarValue))
  end;
end;

procedure AddVariable(Vars: TStrings; const VarText: string);
var
  VarName, VarValue: string;
begin
  StrToVariable(VarText, VarName, VarValue);
  AddVariable(Vars, VarName, VarValue);
end;

procedure DelVariable(Vars: TStrings; const VarName: string); overload;
var
  Idx: Integer;
begin
  Idx := Vars.IndexOfName(VarName);
  if Idx > -1 then
    Vars.Delete(Idx);
end;

{ == Добавление списка переменной в список ===================================== }
procedure AddVariableList(Vars: TStrings; const AddVars: TStrings);
var
  i, iCount: Integer;
begin
  Vars.BeginUpdate;
  try
    iCount := AddVars.Count - 1;
    for i := 0 to iCount do
      AddVariable(Vars, AddVars.Names[i], AddVars.Values[AddVars.Names[i]]);
  finally
    Vars.EndUpdate;
  end;
end;

procedure AddVariableList(Vars: TStrings; const AddVars: string);
var
  VarBuff: TStringList;
begin
  VarBuff := TStringList.Create;
  try
    VarBuff.Text := AddVars;
    AddVariableList(Vars, VarBuff);
  finally
    VarBuff.Free;
  end;
end;

{ == Добавление стандартных переменных ========================================= }
procedure AddStandartVariables(Vars: TStrings; const AddUsersFolders: Boolean);
begin
  Vars.BeginUpdate;
  try
    // Каталоги и файлы
    AddVariable(Vars, VarAppFile, ExtractFileName(ParamStr(0)));
    AddVariable(Vars, VarAppDir, ExtractFilePath(ParamStr(0)));
    AddVariable(Vars, VarAppFull, ParamStr(0));
    AddVariable(Vars, VarRunDir, ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))));
    AddVariable(Vars, VarCurrDir, GetCurrentDir);
    // Имя компьютера, IP-адрес, имя пользователя
    AddVariable(Vars, VarComputerName, GetComputerNetName);
    AddVariable(Vars, VarComputerIp, GetIPAddressOnName(GetComputerNetName));
    AddVariable(Vars, VarUserName, GetCurrentUserName);
    // Идентификаторы ОС
    AddVariable(Vars, VarWindowsName, GetWindowsVersion(GetWindowsVersionData, sFmtWindowsVersionAbbr));
    AddVariable(Vars, VarWindowsNumber, GetWindowsVersion(GetWindowsVersionData, sFmtWindowsVersionNumber));
    AddVariable(Vars, VarWindowsProductType, GetWindowsVersion(GetWindowsVersionData, sFmtWindowsVersionProdType));
    AddVariable(Vars, VarWindowsVersion, GetWindowsVersion(GetWindowsVersionData, sFmtWindowsVersionName));
    AddVariable(Vars, VarWindowsVersionLng, GetWindowsVersion(GetWindowsVersionData, sFmtWindowsVersionNameLng));
    // Системные папки Windows
    AddVariable(Vars, VarWindowsDir, GetWindowsDir);
    AddVariable(Vars, VarWindowsDirSh, GetWindowsDir);
    AddVariable(Vars, VarWindowsSysDir, GetShellFolder(CSIDL_SYSTEM, False));
    AddVariable(Vars, VarWindowsSysDirSh, GetShellFolder(CSIDL_SYSTEM, False));
    // Папки программ
    AddVariable(Vars, VarWindowsPrograms, GetShellFolder(CSIDL_PROGRAM_FILES, False));
    // if GetShellFolder(CSIDL_PROGRAM_FILESX86, False) <> EmptyStr then
    AddVariable(Vars, VarWindowsPrograms86, GetShellFolder(CSIDL_PROGRAM_FILESX86, False));
    AddVariable(Vars, VarWindowsPrgCommon, GetShellFolder(CSIDL_PROGRAM_FILES_COMMON, False));
    // if GetShellFolder(CSIDL_PROGRAM_FILES_COMMONX86, False) <> EmptyStr then
    AddVariable(Vars, VarWindowsPrgCommon86, GetShellFolder(CSIDL_PROGRAM_FILES_COMMONX86, False));
    if AddUsersFolders then
    begin
      // Все пользователи
      AddVariable(Vars, VarAllUsersAppData, GetShellFolder(CSIDL_COMMON_APPDATA, False));
      AddVariable(Vars, VarAllUsersStartMenu, GetShellFolder(CSIDL_COMMON_STARTMENU, False));
      AddVariable(Vars, VarAllUsersPrograms, GetShellFolder(CSIDL_COMMON_PROGRAMS, False));
      AddVariable(Vars, VarAllUsersStartUp, GetShellFolder(CSIDL_COMMON_STARTUP, False));
      AddVariable(Vars, VarAllUsersDesktop, GetShellFolder(CSIDL_COMMON_DESKTOPDIRECTORY, False));
      AddVariable(Vars, VarAllUsersDocuments, GetShellFolder(CSIDL_COMMON_DOCUMENTS, False));
      AddVariable(Vars, VarAllUsersTemplates, GetShellFolder(CSIDL_COMMON_TEMPLATES, False));
      // Текущий пользователь
      AddVariable(Vars, VarCurrUserProfile, GetShellFolder(CSIDL_PROFILE, False));
      AddVariable(Vars, VarCurrUserAppData, GetShellFolder(CSIDL_APPDATA, False));
      AddVariable(Vars, VarCurrUserLocalData, GetShellFolder(CSIDL_LOCAL_APPDATA, False));
      AddVariable(Vars, VarCurrUserStartMenu, GetShellFolder(CSIDL_STARTMENU, False));
      AddVariable(Vars, VarCurrUserPrograms, GetShellFolder(CSIDL_PROGRAMS, False));
      AddVariable(Vars, VarCurrUserStartUp, GetShellFolder(CSIDL_STARTUP, False));
      AddVariable(Vars, VarCurrUserDesktop, GetShellFolder(CSIDL_DESKTOPDIRECTORY, False));
      AddVariable(Vars, VarCurrUserDocuments, GetShellFolder(CSIDL_PERSONAL, False));
      AddVariable(Vars, VarCurrUserTemplates, GetShellFolder(CSIDL_TEMPLATES, False));
      AddVariable(Vars, VarCurrUserFavorites, GetShellFolder(CSIDL_FAVORITES, False));
      AddVariable(Vars, VarCurrUserNetHood, GetShellFolder(CSIDL_NETHOOD, False));
      AddVariable(Vars, VarCurrUserTemp, GetTempDir);
    end;
  finally
    Vars.EndUpdate;
  end;
end;

procedure DelStandartVariables(Vars: TStrings; const DelAllUsersFolders, DelCurrUserFolders: Boolean);
begin
  Vars.BeginUpdate;
  try
    // Каталоги и файлы
    DelVariable(Vars, VarAppFile);
    DelVariable(Vars, VarAppDir);
    DelVariable(Vars, VarAppFull);
    DelVariable(Vars, VarRunDir);
    DelVariable(Vars, VarCurrDir);
    // Имя компьютера, IP-адрес, имя пользователя
    DelVariable(Vars, VarComputerName);
    DelVariable(Vars, VarComputerIp);
    DelVariable(Vars, VarUserName);
    // Идентификаторы ОС
    DelVariable(Vars, VarWindowsName);
    DelVariable(Vars, VarWindowsVersion);
    DelVariable(Vars, VarWindowsVersionLng);
    // Системные папки Windows
    DelVariable(Vars, VarWindowsDir);
    DelVariable(Vars, VarWindowsDirSh);
    DelVariable(Vars, VarWindowsSysDir);
    DelVariable(Vars, VarWindowsSysDirSh);
    // Папки программ
    DelVariable(Vars, VarWindowsPrograms);
    DelVariable(Vars, VarWindowsPrograms86);
    DelVariable(Vars, VarWindowsPrgCommon);
    DelVariable(Vars, VarWindowsPrgCommon86);
    if DelAllUsersFolders then
    begin
      // Все пользователи
      DelVariable(Vars, VarAllUsersAppData);
      DelVariable(Vars, VarAllUsersStartMenu);
      DelVariable(Vars, VarAllUsersPrograms);
      DelVariable(Vars, VarAllUsersStartUp);
      DelVariable(Vars, VarAllUsersDesktop);
      DelVariable(Vars, VarAllUsersDocuments);
      DelVariable(Vars, VarAllUsersTemplates);
    end;
    if DelCurrUserFolders then
    begin
      // Текущий пользователь
      DelVariable(Vars, VarCurrUserProfile);
      DelVariable(Vars, VarCurrUserAppData);
      DelVariable(Vars, VarCurrUserLocalData);
      DelVariable(Vars, VarCurrUserStartMenu);
      DelVariable(Vars, VarCurrUserPrograms);
      DelVariable(Vars, VarCurrUserStartUp);
      DelVariable(Vars, VarCurrUserDesktop);
      DelVariable(Vars, VarCurrUserDocuments);
      DelVariable(Vars, VarCurrUserTemplates);
      DelVariable(Vars, VarCurrUserFavorites);
      DelVariable(Vars, VarCurrUserNetHood);
    end;
  finally
    Vars.EndUpdate;
  end;
end;

{ == Получение имени переменной ================================================ }
function GetVariableName(Vars: TStrings; Index: Integer): string;
begin
  Result := Vars.Names[Index];
end;

{ == Получение переменной по имени ============================================= }
function GetVariableValue(Vars: TStrings; const VarName: string; const CheckExists: Boolean = False): string;
var
  Index: Integer;
begin
  if CheckExists then
  begin
    Index := Vars.IndexOfName(VarName);
    if Index > -1
    then Result := Vars.Values[VarName]
    else raise ERVarListError.CreateFmt(ETagNotFound, [VarName]);
  end
  else Result := Vars.Values[VarName];
end;

{ == Получение переменной по имени с преобразованием =========================== }
function GetVariable(Vars: TStrings; const VarName: string;
  const VDate: TDateTime = 0; const TagsChar: Char = '%'): string;
begin
  if Vars.IndexOfName(VarName) > -1 then
    Result := ReplaceTags(Vars, Vars.Values[VarName], True, VDate, TagsChar)
  else
    Result := EmptyStr;
end;

function GetVariableNoErrors(Vars: TStrings; const VarName: string;
  const VDate: TDateTime = 0; const TagsChar: Char = '%'): string;
begin
  if Vars.IndexOfName(VarName) > -1 then
    Result := ReplaceTags(Vars, Vars.Values[VarName], False, VDate, TagsChar)
  else
    Result := EmptyStr;
end;

{ == Замена тегов в строке из произвольного списка ============================= }
function ReplaceTags(Vars: TStrings; const Source: string;
  const RaiseError: Boolean; const VDate: TDateTime = 0;
  const TagsChar: Char = '%'; const ProcessDate: Boolean = True): string;
var
  i, iCount, v, vCount, DatePos: Integer;
  Tagged, Repl: Boolean;
  Tag, Rep, OffsetS: string;
  Val: Byte;
  OffsetF: Double;
begin
  Result := EmptyStr;
  Tag := EmptyStr;
  Tagged := False;
  iCount := Length(Source);
  for i := 1 to iCount do
  begin
    if Source[i] = TagsChar then
    begin
      if Tagged then
      begin
        Tagged := False;
        if Tag = EmptyStr then
        begin
          // Два символа подряд
          Rep := TagsChar;
          Repl := True;
        end
        else begin
          Repl := False;
          Rep := TagsChar + Tag + TagsChar;
          Tag := AnsiUpperCase(Tag);
          // Вставляем дату
          if Pos(DateTag, Tag) = 1 then
          begin
            if ProcessDate then
            begin
              OffsetF := 0;
              DatePos := Length(DateTag) + 1;
              // считываем смещение значения
              if Tag[DatePos] = OffsChar then
              begin
                OffsetS := EmptyStr;
                Inc(DatePos);
                while (Tag[DatePos] in DigChars) and (DatePos <= Length(Tag)) do
                begin
                  OffsetS := OffsetS + Tag[DatePos];
                  Inc(DatePos);
                end;
                OffsetF := RStrToFloatDef(OffsetS, 0);
              end;
              // считываем формат даты
              if Tag[DatePos] = DateChar then
                Inc(DatePos);
              if VDate = 0
              then Rep := FormatDateTime(Copy(Tag, DatePos, Length(Tag) - DatePos + 1), Now + OffsetF)
              else Rep := FormatDateTime(Copy(Tag, DatePos, Length(Tag) - DatePos + 1), VDate + OffsetF);
            end;
            Repl := True;
          end;
          // Вставляем день недели
          if Pos(WeekTag, Tag) = 1 then
          begin
            if ProcessDate then
            begin
              DatePos := Length(WeekTag) + 1;
              if Tag[DatePos] = OffsChar then
                Inc(DatePos);
              // считываем смещение значения
              OffsetS := EmptyStr;
              Inc(DatePos);
              while (Tag[DatePos] in DigChars) and (DatePos <= Length(Tag)) do
              begin
                OffsetS := OffsetS + Tag[DatePos];
                Inc(DatePos);
              end;
              OffsetF := RStrToFloatDef(OffsetS, 0);
              // возвращаем номер дня недели
              if VDate = 0
              then Rep := IntToStr(DayOfTheWeek(Now + OffsetF))
              else Rep := IntToStr(DayOfTheWeek(VDate + OffsetF));
            end;
            Repl := True;
          end;
          // Код символа
          if Pos(CharTag, Tag) = 1 then
          begin
            Tag := Copy(Tag, 2, Length(Tag) - 1);
            if Pos(CharTag, Tag) = 1
            then Rep := TagsChar + Tag + TagsChar
            else begin
              try
                Val := StrToInt(Tag);
              except
                if RaiseError
                then raise ERVarListError.CreateFmt(ETagSymbolError, [Tag])
                else Val := 32;
              end;
              Rep := Chr(Val);
              Repl := True;
            end;
          end;
          // "Постоянные" теги
          if Assigned(Vars) then
          begin
            vCount := Vars.Count - 1;
            for v := 0 to vCount do
              if Tag = AnsiUpperCase(Vars.Names[v]) then
              begin
                Rep := ReplaceTags(Vars, Vars.ValueFromIndex[v], RaiseError, VDate);
                Repl := True;
                Break;
              end;
          end;
        end;
        Result := Result + Rep;
        if RaiseError and not Repl then
          raise ERVarListError.CreateFmt(ETagNotFound, [Tag]);
      end
      else begin
        Tag := EmptyStr;
        Tagged := True;
      end;
    end
    else begin
      if Tagged
      then Tag := Tag + Source[i]
      else Result := Result + Source[i];
    end;
  end;
  // 2012-02-19: Fixed bug
  // При одиночном TagsChar возвращалась только часть строки до TagsChar
  if Tagged then
  begin
    if RaiseError then
      raise ERVarListError.CreateFmt(ETagUnterminatedTag, [Source]);
    Result := Result + TagsChar + Tag;
  end;
end;

function ReplaceTags(const Source, ExtVars: string; const RaiseError: Boolean): string;
var
  slVars: TStringList;
begin
  slVars := TStringList.Create;
  try
    AddStandartVariables(slVars, True);
    if ExtVars <> EmptyStr then
      AddVariableList(slVars, ExtVars);

    Result := ReplaceTags(slVars, Source, RaiseError, Now);
  finally
    slVars.Free;
  end;
end;

{ == Замена тегов в списке строк =============================================== }
procedure ReplaceList(Vars: TStrings; List: TStrings;
  const VDate: TDateTime = 0; const ProcessDate: Boolean = True);
var
  i, iCount: Integer;
begin
  iCount := List.Count - 1;
  for i := 0 to iCount do
    List[i] := ReplaceTags(Vars, List[i], True, VDate, TagsDefC, ProcessDate);
end;

end.
