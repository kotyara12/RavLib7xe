unit RLngDLL;

interface

uses
  Windows, Classes, Forms, SysUtils;

type
  TLCIDs = array of LCID;

function  rlr_NameLangModule(const iLCID: LCID): string;
function  rlr_InitLanguages(const iDefLCID, iSelLCID: LCID): LCID;
function  rlr_GetLanguagesLCIDs: TLCIDs;
procedure rlr_GetLanguagesList(slList: TStrings);

function  rlr_GetDefLCID: LCID;
function  rlr_GetLCID: LCID;
function  rlr_GetLangIdx(const iLCID: LCID; const iDefLCID: LCID): Integer;
function  rlr_GetIdxLang(const iIdx: Integer; const iDefLCID: LCID): LCID;

procedure rlr_CheckLCID(const iLCID: LCID);
function  rlr_SetLCID(const iLCID: LCID; const bRaiseIsNotFound: Boolean): LCID;

implementation

uses
  RSysUtils, RLngUtils, RDialogs;

resourcestring
  rsErrLangModuleNotFound          = 'языковый модуль "%s" не найден!';
  rsErrCannotLoadModule            = 'Ќе удалось загрузить €зыковый модуль "%s"!'#13#13'%s';

const
  sLangModuleMask                  = '%s_%s.lng';

var
  aLngList: TLCIDs;
  fDefLCID: LCID;
  fSelLCID: LCID;

function rlr_NameLangModule(const iLCID: LCID): string;
begin
  if iLCID = fDefLCID
  then Result := ParamStr(0)
  else Result := Format(sLangModuleMask, [ChangeFileExt(ParamStr(0), EmptyStr), lng_GetLcidAbbr(iLCID)]);
end;

procedure rlr_EnumLanguages;
var
  iLCID: LCID;
begin
 for iLCID := 0 to 65535 do
 begin
   if IsValidLocale(iLCID, LCID_INSTALLED)
     and FileExists(rlr_NameLangModule(iLCID)) then
   begin
     SetLength(aLngList, Length(aLngList) + 1);
     aLngList[High(aLngList)] := iLCID;
   end;
 end;
end;

function rlr_InitLanguages(const iDefLCID, iSelLCID: LCID): LCID;
begin
  fDefLCID := iDefLCID;
  fSelLCID := iDefLCID;

  rlr_EnumLanguages;

  Result := rlr_SetLCID(iSelLCID, False);
end;

function rlr_GetLanguagesLCIDs: TLCIDs;
var
  i: Integer;
begin
  SetLength(Result, Length(aLngList));

  for i := Low(aLngList) to High(aLngList) do
    Result[i] := aLngList[i];
end;

procedure rlr_GetLanguagesList(slList: TStrings);
var
  i: Integer;
begin
  slList.BeginUpdate;
  try
    slList.Clear;

    if Length(aLngList) = 0 then
      rlr_InitLanguages(1049, 1049);

    for i := Low(aLngList) to High(aLngList) do
      slList.Add(lng_GetLcidName(aLngList[i]));
  finally
    slList.EndUpdate;
  end;
end;

function rlr_GetDefLCID: LCID;
begin
  Result := fDefLCID;
end;

function rlr_GetLCID: LCID;
begin
  Result := fSelLCID;
end;

function rlr_GetLangIdx(const iLCID: LCID; const iDefLCID: LCID): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := Low(aLngList) to High(aLngList) do
  begin
    if aLngList[i] = iLCID then
    begin
      Result := i;
      Break;
    end;
  end;

  if Result = -1 then
  begin
    for i := Low(aLngList) to High(aLngList) do
    begin
      if aLngList[i] = iDefLCID then
      begin
        Result := i;
        Break;
      end;
    end;
  end;
end;

function rlr_GetIdxLang(const iIdx: Integer; const iDefLCID: LCID): LCID;
begin
  Result := iDefLCID;

  if (iIdx >= Low(aLngList)) and (iIdx <= High(aLngList)) then
    Result := aLngList[iIdx];
end;

{ == «агрузка €зыкового модул€ ================================================= }

procedure rlr_CheckLCID(const iLCID: LCID);
begin
  if (iLCID <> fDefLCID) and not FileExists(rlr_NameLangModule(iLCID)) then
    raise Exception.CreateFmt(rsErrLangModuleNotFound, [rlr_NameLangModule(iLCID)]);
end;

type
  TResReader = class(TReader)
  public
    procedure ReadPrefix(var Flags: TFilerFlags; var AChildPos: Integer); override;
  end;

procedure TResReader.ReadPrefix(var Flags: TFilerFlags; var AChildPos: Integer);
begin
  inherited ReadPrefix(Flags, AChildPos);
  Include(Flags, ffInherited);
end;

function rlr_SetResourceInstance(const NewInstance: Longint): Longint;
var
  CurModule: PLibModule;
begin
  Result := 0;

  CurModule := LibModuleList;
  while CurModule <> nil do
  begin
    if CurModule.Instance = HInstance then
    begin
      if CurModule.ResInstance <> CurModule.Instance then
        FreeLibrary(CurModule.ResInstance);
      CurModule.ResInstance := NewInstance;
      Result := NewInstance;
      Exit;
    end;

    CurModule := CurModule.Next;
  end;
end;

function rlr_InternalReloadComponentRes(const sResName: string; hInst: THandle; Instance: TComponent): Boolean;
var
  hRsrc: THandle;
  fStream: TResourceStream;
  fReader: TResReader;
begin
  Result := False;

  if hInst = 0 then
    hInst := HInstance;

  hRsrc := FindResource(hInst, PChar(sResName), RT_RCDATA);
  if hRsrc <> 0 then
  begin
    fStream := TResourceStream.Create(hInst, sResName, RT_RCDATA);
    try
      fReader := TResReader.Create(fStream, 4096);
      try
        fReader.ReadRootComponent(Instance);
      finally
        fReader.Free;
      end;
    finally
      fStream.Free;
    end;

    Result := True;
  end;
end;

procedure rlr_InitComponent(ClassType: TClass; Form: TForm);
begin
  if (ClassType = TComponent) or (ClassType = TForm) then Exit;

  rlr_InitComponent(ClassType.ClassParent, Form);

  rlr_InternalReloadComponentRes(ClassType.ClassName,
    FindResourcehInstance(FindClassHInstance(ClassType)),
    Form);
end;

function rlr_LoadLangModule(const iLCID: LCID; const bRaiseIsNotFound: Boolean): Boolean;
var
  sModuleName: string;
  hModuleLang: THandle;
  lModule: PLibModule;
  iIndex, iCount: Integer;
  fForm: TForm;
  bFormShow: Boolean;
  sFontName: string;
  iFontSize: Integer;
begin
  Result := False;
  try
    // «агружаем €зыковый модуль в пам€ть
    if iLCID = fDefLCID then
      hModuleLang := HInstance
    else begin
      sModuleName := rlr_NameLangModule(iLCID);
      if FileExists(sModuleName) then
      begin
        hModuleLang := LoadLibraryEx(PChar(sModuleName), 0, LOAD_LIBRARY_AS_DATAFILE);
        if hModuleLang = 0 then
          raise Exception.CreateFmt(rsErrCannotLoadModule, [sModuleName, GetSystemError]);
      end
      else begin
        if bRaiseIsNotFound
        then raise Exception.CreateFmt(rsErrLangModuleNotFound, [sModuleName])
        else Exit;
      end;
    end;

    // »щем главный модуль в списке загруженных модулей
    lModule := LibModuleList;
    while lModule <> nil do
    begin
      if lModule.Instance = HInstance then
      begin
        if lModule.ResInstance <> HInstance then
          FreeLibrary(lModule.ResInstance);
        lModule.ResInstance := hModuleLang;

        // ќбновл€ем формы приложени€
        iCount := Screen.FormCount - 1;
        for iIndex:= 0 to iCount do
        begin
          fForm := Screen.Forms[iIndex];

          bFormShow := fForm.Visible;
          sFontName := fForm.Font.Name;
          iFontSize := fForm.Font.Size;
          if bFormShow then fForm.Hide;
          try
            rlr_InitComponent(fForm.ClassType, fForm);
          finally
            fForm.Font.Name := sFontName;
            fForm.Font.Size := iFontSize;
            if bFormShow then fForm.Show;
          end;
        end;

        Result := True;
        Break;
      end;

      lModule := lModule.Next;
    end;
  except
    on E: Exception do
      ErrorBox(E.Message);
  end;
end;

type
  TSetThreadUILanguage = function (LangId: WORD): WORD; stdcall;

function rlr_SetLCID(const iLCID: LCID; const bRaiseIsNotFound: Boolean): LCID;
var
  lVersion: Longword;
  hHandle: THandle;
  SetThreadUILanguage: TSetThreadUILanguage;
begin
  Result := fSelLCID;

  if fSelLCID <> iLCID then
  begin
    if rlr_LoadLangModule(iLCID, bRaiseIsNotFound) then
    begin
      SetThreadLocale(iLCID);

      lVersion := GetVersion;
      if lVersion and $FF >= 6 then
      begin
        hHandle := LoadLibrary('kernel32.dll');
        try
          SetThreadUILanguage := GetProcAddress(hHandle, 'SetThreadUILanguage');
          if Assigned(SetThreadUILanguage) then
            SetThreadUILanguage(iLCID);
        finally
          FreeLibrary(hHandle);
        end;
      end;

      fSelLCID := iLCID;
      Result := fSelLCID;
    end
    else Result := rlr_SetLCID(fDefLCID, bRaiseIsNotFound);
  end;
end;

initialization
  fDefLCID := 0;
  fSelLCID := 0;
  SetLength(aLngList, 0);

finalization
  SetLength(aLngList, 0);

end.

