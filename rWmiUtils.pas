unit RWmiUtils;

interface

uses
  Classes, WbemScripting_TLB;

type
  T2DimStrArray = array of array of string;
  T2DimResult = packed record
    Instances: Integer;
    Rows: Integer;
  end;

const
  RootNameSpace     = 'root\CIMV2';

  WmiWQLTemplate    = 'SELECT %s FROM %s';
  WmiArg_Bios       = 'Win32_BIOS';
  WmiArg_Processor  = 'Win32_Processor';
  WmiArg_BaseBoard  = 'Win32_BaseBoard';
  WmiArg_DiskDrive  = 'Win32_DiskDrive';
  WmiArg_Windows    = 'Win32_OperatingSystem';

resourcestring
  SErrWmi_GetData   = 'Ошибка получения данных WMI "%s"!';
  SErrWmi_GetDataP  = 'Ошибка получения данных WMI "%s" (параметр "%s")!';

function MagWmiDate2DT(S: string; var UtcOffset: Integer): TDateTime;
function WmiGetPropStr(wmiProp: ISWbemProperty): string;
function WmiSearchIdx(const WmiResults: T2DimStrArray; const Prop: string): Integer;
function WmiSearch(const WmiResults: T2DimStrArray; const Prop: string; const Inst: Integer): string;

function WmiGetInfo(const Comp, NameSpace, User, Pass, Arg: string;
  var WmiResults: T2DimStrArray): T2DimResult;
procedure WmiGetOne_Get(const Arg, Prop: string; ResData: TStrings);
function  WmiGetOne_GetFirst(const Arg, Prop: string): string;
function  WmiGetOne_GetTotal(const Arg, Prop, Divider: string): string;
procedure WmiGetOne_WQL(const Arg, Prop: string; ResData: TStrings);
function  WmiGetOne_WQLFirst(const Arg, Prop: string): string;
function  WmiGetOne_WQLTotal(const Arg, Prop, Divider: string): string;

implementation

uses
  SysUtils, StrUtils, Windows, ActiveX, ComObj, Variants,
  RDialogs, RSysUtils;

const
  SWmiNullStr       = '';
  SWmiExecQueryId   = 'SELECT';
  SWmiQueryLanguage = 'WQL';

function MagWmiDate2DT(S: string; var UtcOffset: Integer): TDateTime;
// yyyymmddhhnnss.zzzzzzsUUU  +60 means 60 mins of UTC time
// 20030709091030.686000+060
// 1234567890123456789012345
var
  yy, mm, dd, hh, nn, ss, zz: Integer;
  timeDT: TDateTime;

  function GetNum(Offset, Len: integer): Integer;
  var
    E: Integer;
  begin
    Val(Copy(S, Offset, Len), Result, E);
  end;

begin
  Result := 0;
  UtcOffset := 0;
  if Length(S) >= 9 then 
  begin
    yy := GetNum(1, 4);
    mm := GetNum(5, 2);
    if (mm = 0) or (mm > 12) then Exit;
    dd := GetNum(7, 2);
    if (dd = 0) or (dd > 31) then Exit;
    if not TryEncodeDate (yy, mm, dd, Result) then
    begin
      Result := -1;
      Exit;
    end;
    if Length(S) >= 14 then 
    begin
      hh := GetNum(9, 2);
      nn := GetNum(11, 2);
      ss := GetNum(13, 2);
      zz := 0;
      if Length(S) >= 18 then zz := GetNum(16, 3);
      if not TryEncodeTime (hh, nn, ss, zz, timeDT) then Exit;
      Result := Result + timeDT;
      if Length(S) >= 22 then 
        UtcOffset := GetNum(22, 4);
    end;
  end;
end;

function WmiGetPropStr(wmiProp: ISWbemProperty): string;
var
  i: Integer;
begin
  Result := EmptyStr;
  if VarIsNull(wmiProp.Get_Value) then
    Result := SWmiNullStr
  else begin
    case wmiProp.CIMType of
      // Integer or VarArray
      wbemCimtypeSint8, wbemCimtypeUint8, wbemCimtypeSint16,
      wbemCimtypeUint16, wbemCimtypeSint32, wbemCimtypeUint32,
      wbemCimtypeSint64:
        if VarIsArray(wmiProp.Get_Value) then
        begin
          for i := 0 to VarArrayHighBound (wmiProp.Get_Value, 1) do
          begin
            if i > 0 then Result := Result + '|';
            Result := Result + IntToStr(wmiProp.Get_Value[i]);
          end;
        end
        else
          Result := IntToStr(wmiProp.Get_Value);
      // Float
      wbemCimtypeReal32, wbemCimtypeReal64:
        Result := FloatToStr(wmiProp.Get_Value);
      // Boolean
      wbemCimtypeBoolean:
        if wmiProp.Get_Value then Result := '1' else Result := '0';
      // String or VarArray
      wbemCimtypeString, wbemCimtypeUint64:
        if VarIsArray(wmiProp.Get_Value) then
        begin
          for i := 0 to VarArrayHighBound (wmiProp.Get_Value, 1) do
          begin
            if i > 0 then Result := Result + '|';
            Result := Result + string(wmiProp.Get_Value[i]);
          end;
        end
        else
          Result := string(wmiProp.Get_Value);
      // Datetime
      wbemCimtypeDatetime:
        Result := string(wmiProp.Get_Value);
      // Reference
      wbemCimtypeReference:
        Result := string(wmiProp.Get_Value);
      // Char16
      wbemCimtypeChar16:
        Result := '<16-bit character>';
      // Object
      wbemCimtypeObject:
        Result := '<CIM Object>';
    end;
  end;
end;

function WmiGetInfo(const Comp, NameSpace, User, Pass, Arg: string;
  var WmiResults: T2DimStrArray): T2DimResult;
var
  wmiLocator: TSWbemLocator;
  wmiServices: ISWbemServices;
  wmiObjectSet: ISWbemObjectSet;
  wmiObject: ISWbemObject;
  wmiPropSet: ISWbemPropertySet;
  wmiProp: ISWbemProperty;
  evInst, evProp: IEnumVariant;
  ovVar1, ovVar2: OleVariant;
  lwValue: LongWord;
  sValue: string;
  iInst, iRow: Integer;
begin
  Result.Instances := 0;
  Result.Rows := 0;
  SetLength(WmiResults, 0, 0);
  VarClear(ovVar1);
  VarClear(ovVar2);
  wmiLocator := TSWbemLocator.Create(nil);
  try
    // Подключаемся к WMI
    wmiServices := wmiLocator.ConnectServer(WideString(Comp), WideString(Namespace),
      WideString(User), WideString(Pass), '', '', 0, nil);
    // Выполняем запрос или запрашиваем указанные параметры
    if AnsiStartsText(SWmiExecQueryId, Arg) then
      wmiObjectSet := wmiServices.ExecQuery(Arg, 
        SWmiQueryLanguage, wbemFlagReturnImmediately, nil)
    else
      wmiObjectSet := wmiServices.InstancesOf(Arg, 
        wbemFlagReturnImmediately or wbemQueryFlagShallow, nil);
    // Считываем количество наборов параметров
    Result.Instances := wmiObjectSet.Count;
    if Result.Instances > 0 then
    begin
      // Считываем наборы параметров
      evInst := (wmiObjectSet._NewEnum) as IEnumVariant;
      iInst := 0;
      while (evInst.Next(1, ovVar1, lwValue) = S_OK) do
      begin
        wmiObject := IUnknown(ovVar1) as SWBemObject;
        wmiPropSet := wmiObject.Properties_;
        // Если количество строк больше, чем в результате - распределяем память
        if wmiPropSet.Count > Result.Rows then
        begin
          Result.Rows := wmiPropSet.Count;
          SetLength(WmiResults, Result.Instances + 1, Result.Rows);
        end;
        Inc(iInst);
        // Считываем параметры
        evProp := (wmiPropSet._NewEnum) as IEnumVariant;
        iRow := 0;
        while (evProp.Next(1, ovVar2, lwValue) = S_OK) do
        begin
          wmiProp := IUnknown(ovVar2) as SWBemProperty;
          sValue := WmiGetPropStr(wmiProp);
          WmiResults[0, iRow] := wmiProp.Name;
          WmiResults[iInst, iRow] := sValue;
          Inc(iRow);
          VarClear(ovVar2);
        end;
        VarClear(ovVar1);
      end;
    end;
  finally
    wmiLocator.Free;
    VarClear(ovVar1);
    VarClear(ovVar2);
  end;
end;

procedure WmiGetOne_Get(const Arg, Prop: string; ResData: TStrings);
var
  wmiLocator: TSWbemLocator;
  wmiServices: ISWbemServices;
  wmiObject: ISWbemObject;
  wmiObjectSet: ISWbemObjectSet;
  wmiProp: ISWbemProperty;
  ovVar: OleVariant;
  lwValue: LongWord;
  Enum: IEnumVariant;
begin
  ResData.Clear;
  VarClear(ovVar);
  wmiLocator := TSWbemLocator.Create(nil);
  try
    wmiServices := wmiLocator.ConnectServer('', RootNameSpace, '', '', '', '', 0, nil);
    wmiObject := wmiServices.Get(Arg, 0, nil);
    wmiObjectSet := wmiObject.Instances_(0, nil);
    if wmiObjectSet.Count > 0 then
    begin
      Enum := (wmiObjectSet._NewEnum) as IEnumVariant;
      while (Enum.Next(1, ovVar, lwValue) = S_OK) do
      begin
        try
          wmiObject := IUnknown(ovVar) as SWBemObject;
          wmiProp := wmiObject.Properties_.Item(Prop, 0);
          if AnsiSameText(wmiProp.Name, Prop) then
            ResData.Add(WmiGetPropStr(wmiProp));
        finally
          VarClear(ovVar);
        end;
      end;
    end;
  finally
    wmiLocator.Free;
  end;
end;

function WmiGetOne_GetFirst(const Arg, Prop: string): string;
var
  ResData: TStringList;
  i: Integer;
begin
  Result := EmptyStr;

  ResData := TStringList.Create;
  try
    WmiGetOne_Get(Arg, Prop, ResData);
    for i := 0 to ResData.Count - 1 do
      if ResData[i] <> EmptyStr then
      begin
        Result := ResData[i];
        Break;
      end;
  finally
    ResData.Free;
  end;
end;

function WmiGetOne_GetTotal(const Arg, Prop, Divider: string): string;
var
  ResData: TStringList;
  i: Integer;
begin
  Result := EmptyStr;

  ResData := TStringList.Create;
  try
    WmiGetOne_Get(Arg, Prop, ResData);
    for i := 0 to ResData.Count - 1 do
      if ResData[i] <> EmptyStr then
      begin
        if Result = EmptyStr
        then Result := ResData[i]
        else Result := Result + Divider + ResData[i];
      end;
  finally
    ResData.Free;
  end;
end;

procedure WmiGetOne_WQL(const Arg, Prop: string; ResData: TStrings);
var
  wmiLocator: TSWbemLocator;
  wmiServices: ISWbemServices;
  wmiObjectSet: ISWbemObjectSet;
  wmiObject: ISWbemObject;
  wmiProp: ISWbemProperty;
  ovVar: OleVariant;
  lwValue: LongWord;
  Enum: IEnumVariant;
begin
  ResData.Clear;
  VarClear(ovVar);
  wmiLocator := TSWbemLocator.Create(nil);
  try
    wmiServices := wmiLocator.ConnectServer('', RootNameSpace, '', '', '', '', 0, nil);
    wmiObjectSet := wmiServices.ExecQuery(Arg, SWmiQueryLanguage, wbemFlagReturnImmediately, nil);
    if wmiObjectSet.Count > 0 then
    begin
      Enum := (wmiObjectSet._NewEnum) as IEnumVariant;
      while (Enum.Next(1, ovVar, lwValue) = S_OK) do
      begin
        try
          wmiObject := IUnknown(ovVar) as SWBemObject;
          wmiProp := wmiObject.Properties_.Item(Prop, 0);
          if AnsiSameText(wmiProp.Name, Prop) then
            ResData.Add(WmiGetPropStr(wmiProp));
        finally
          VarClear(ovVar);
        end;
      end;
    end;
  finally
    wmiLocator.Free;
  end;
end;

function WmiGetOne_WQLFirst(const Arg, Prop: string): string;
var
  ResData: TStringList;
  i: Integer;
begin
  Result := EmptyStr;

  ResData := TStringList.Create;
  try
    WmiGetOne_WQL(Arg, Prop, ResData);
    for i := 0 to ResData.Count - 1 do
      if ResData[i] <> EmptyStr then
      begin
        Result := ResData[i];
        Break;
      end;
  finally
    ResData.Free;
  end;
end;

function WmiGetOne_WQLTotal(const Arg, Prop, Divider: string): string;
var
  ResData: TStringList;
  i: Integer;
begin
  Result := EmptyStr;

  ResData := TStringList.Create;
  try
    WmiGetOne_WQL(Arg, Prop, ResData);
    for i := 0 to ResData.Count - 1 do
      if ResData[i] <> EmptyStr then
      begin
        if Result = EmptyStr
        then Result := ResData[i]
        else Result := Result + Divider + ResData[i];
      end;
  finally
    ResData.Free;
  end;
end;

function WmiSearchIdx(const WmiResults: T2DimStrArray; const Prop: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(WmiResults[0])do
  begin
    if SameText(WmiResults [0, i], Prop) then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

function WmiSearch(const WmiResults: T2DimStrArray; const Prop: string; const Inst: Integer): string;
var
  i: Integer;
begin
  Result := EmptyStr;
  if Inst > 0 then
  begin
    i := WmiSearchIdx(WmiResults, Prop);
    if i >= 0 then Result := WmiResults[Inst, i];
  end;
end;

end.
