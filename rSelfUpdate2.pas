unit RSelfUpdate2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TmplDialogSimple, StdCtrls, Buttons, ExtCtrls, Types, IOUtils;

type
  TSelfUpdateState = (suNotFound, suInstalled, suError);

  TfrmUpdateInformer = class(TDialogSTemplate)
    lblVersionCur: TLabel;
    edVersionCur: TEdit;
    lblVersionNew: TLabel;
    edVersionNew: TEdit;
    lblVersionDsc: TLabel;
    edVersionDsc: TMemo;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function rsu2_SelfUpdate(const sSuCfgFile: string; const bSilentMode: Boolean; const iLngId: DWord): TSelfUpdateState;

implementation

{$R *.dfm}

uses
  StrUtils, IniFiles, RxVerInf, rxStrUtilsE,
  rVclUtils, rDialogs, rSysUtils, rHttpUtils, rMsgStd,
  rCrc32, rLngUtils, rProgress;

type
  TrSU_UpdMode = (umHTTP, umFILE);

  TrSU_VerData = record
    sVerId: string;
    sDescr: string;
    sSource: string;
    sOrigin: string;
    sCrc32: string;
    sGlbDeleteAfter: string;
    sGlbDeleteBefore: string;
    sGlbExecAfter: string;
    sGlbExecBefore: string;
    sExeDeleteAfter: string;
    sExeDeleteBefore: string;
    sExeExecAfter: string;
    sExeExecBefore: string;
  end;

resourcestring
  rsSU2_CheckSelfUpdates    = 'Поиск доступных обновлений...';
  rsSU2_InstallSelfUpdates  = 'Загрузка и установка обновления "%s"...';
  rsSU2_UpdatesNotFound     = 'Обновлений не найдено!';
  rsSU2_DescrNotFound       = '< Описание обновления не доступно >';
  rsSU2_UpdateOk            = 'Установка обновления "%s" успешно выполнена.'#13#13'Для завершения установки необходимо перезапустить программу!';

  rsSU2_ErrorMain           = 'Ошибка системы самообновления программы!'#13#13'%s';
  rsSU2_ErrorCheckUpdates   = 'Ошибка поиска обновлений!'#13#13'%s';
  rsSU2_ErrorInstallUpdate  = 'Ошибка установки обновления!'#13#13'%s';
  rsSU2_ErrorBadCrc32       = 'Неверная контрольная сумма скачанного файла, обновление невозможно. Перезапустите программу и попробуйте еще раз.';

const
  rSU_TempMask              = '*.~*';
  rSU_InfFile               = 'SelfUpdates.inf';
  rSU_UpdFile               = 'SelfUpdate_%s.upd';
  rSU_UpdDir                = 'UpdDescr';
  rSU_UpdDescSmp            = 'UpdDescr_%s.txt';
  rSU_UpdDescLngNum         = 'UpdDescr_%d_%s.txt';
  rSU_UpdDescLngStr         = 'UpdDescr_%s_%s.txt';
  rSU_TempDir               = 'SelfUpdate\';

{ == Удаление временных файлов ================================================= }

procedure rsu2_DeleteTempFiles(const sExeFile: string);
var
  lFiles: TStringDynArray;
  i: Integer;
begin
  lFiles := TDirectory.GetFiles(ExtractFilePath(sExeFile), rSU_TempMask, TSearchOption.soTopDirectoryOnly, nil);
  try
    for i := Low(lFiles) to High(lFiles) do
    begin
      try
        TFile.Delete(lFiles[i]);
      except
      end;
    end;
  finally
    SetLength(lFiles, 0);
  end;
end;

{ == Определение версии программы ============================================== }

function rsu2_GetExeVersion: string;
var
  VerInfo: TVersionInfo;
begin
  VerInfo := AppVerInfo;
  try
    Result := VerInfo.FileVersion;
  finally
    VerInfo.Free;
  end;
end;

function rsu2_ExtractBuild(const sVer: string): Integer;
begin
  Result := StrToIntDef(Trim(ExtractWord(4, sVer, ['.', ',', '-', '_'])), 0);
end;

{ == Определяем режим загрузки файлов ========================================== }

function rsu2_GetUpdMode(const sFile: string): TrSU_UpdMode;
begin
  Result := umFILE;
  if AnsiStartsText('http://', sFile) or AnsiStartsText('https://', sFile) then
    Result := umHTTP;
end;

{ == Загрузка файла ============================================================ }

function rsu2_GetFile(const sSrcFile, sDstFile: string): TrSU_UpdMode;
begin
  // Создаем каталог назначения при необходимости
  TDirectory.CreateDirectory(ExtractFilePath(sDstFile));

  // Собственно загрузка файла
  Result := rsu2_GetUpdMode(sSrcFile);
  case Result of
    umHTTP:
    begin
      rHttp_DownloadFile(sSrcFile, sDstFile, rHttp_IsSSL(sSrcFile));
    end;

    umFILE:
    begin
      TFile.Copy(sSrcFile, sDstFile, True);
    end;
  end;
end;

{ == Чтение файла описания версии ============================================== }

function rsu2_ReadInfFile(const sInfFile, sExeName, sVerDef: string): TrSU_VerData;
const
  sGlobalOptions = 'GlobalOptions';
var
  fInf: TMemIniFile;
begin
  FillChar(Result, SizeOf(TrSU_VerData), 0);

  fInf := TMemIniFile.Create(sInfFile);
  try
    Result.sVerId := fInf.ReadString(sExeName, 'VerId', sVerDef);
    Result.sDescr := fInf.ReadString(sExeName, 'Description', EmptyStr);
    Result.sSource := fInf.ReadString(sExeName, 'DownloadUrl', EmptyStr);
    Result.sOrigin := fInf.ReadString(sExeName, 'OriginalFileName', EmptyStr);
    Result.sCrc32 := fInf.ReadString(sExeName, 'ChecksumCRC32', EmptyStr);
    Result.sGlbDeleteBefore := fInf.ReadString(sGlobalOptions, 'DeleteBefore', EmptyStr);
    Result.sGlbDeleteAfter := fInf.ReadString(sGlobalOptions, 'DeleteAfter', EmptyStr);
    Result.sGlbExecBefore := fInf.ReadString(sGlobalOptions, 'ExecBefore', EmptyStr);
    Result.sGlbExecAfter := fInf.ReadString(sGlobalOptions, 'ExecAfter', EmptyStr);
    Result.sExeDeleteBefore := fInf.ReadString(sExeName, 'DeleteBefore', EmptyStr);
    Result.sExeDeleteAfter := fInf.ReadString(sExeName, 'DeleteAfter', EmptyStr);
    Result.sExeExecBefore := fInf.ReadString(sExeName, 'ExecBefore', EmptyStr);
    Result.sExeExecAfter := fInf.ReadString(sExeName, 'ExecAfter', EmptyStr);
  finally
    fInf.Free;
  end;
end;

procedure rsu2_GetDescription(slText: TStrings; const rVerInf: TrSU_VerData;
  const sUpdDir, sLocDir: string; const iLngId: DWord);
var
  sDscFile: string;
begin
  sDscFile := sLocDir + Format(rSU_UpdDescSmp, [rVerInf.sVerId]);
  try
    try
      if iLngId = 0 then
        rsu2_GetFile(sUpdDir + Format(rSU_UpdDescSmp, [rVerInf.sVerId]), sDscFile)
      else begin
        try
          rsu2_GetFile(sUpdDir + Format(rSU_UpdDescLngStr, [lng_GetLcidAbbr(iLngId), rVerInf.sVerId]), sDscFile);
        except
          try
            rsu2_GetFile(sUpdDir + Format(rSU_UpdDescLngNum, [iLngId, rVerInf.sVerId]), sDscFile);
          except
            rsu2_GetFile(sUpdDir + Format(rSU_UpdDescSmp, [rVerInf.sVerId]), sDscFile);
          end;
        end;
      end;
    except
      slText.Clear;
    end;

    if FileExists(sDscFile) then
      slText.LoadFromFile(sDscFile)
    else
      slText.Text := rsSU2_DescrNotFound;
  finally
    if FileExists(sDscFile) then
    begin
      try
        DeleteFile(sDscFile);
      except
        on E: Exception do
          ErrorBox(E.Message);
      end;
    end;
  end;
end;

{ == Запрос к пользователю ===================================================== }

function rsu2_QueryUpdate(const sExeVer: string; const rVerInf: TrSU_VerData; const slVerDsc: TStrings): Boolean;
begin
  with TfrmUpdateInformer.Create(Application) do
  begin
    try
      edVersionCur.Text := sExeVer;
      edVersionNew.Text := rVerInf.sDescr;
      edVersionDsc.Lines.Assign(slVerDsc);

      Result := ShowModal = mrOk;
    finally
      Free;
    end;
  end;
end;

{ == Копирование файлов из одного каталога в другой ============================ }

procedure rsu2_CopyFiles(const sSourceDir, sDestDir: string);
var
  lList: TStringDynArray;
  sDestName: string;
  i: Integer;
begin
  // Обрабатываем подкаталоги
  lList := TDirectory.GetDirectories(sSourceDir, '*', TSearchOption.soTopDirectoryOnly);
  try
    for i := Low(lList) to High(lList) do
      rsu2_CopyFiles(lList[i], TPath.Combine(sDestDir, ExtractFileName(lList[i])));
  finally
    SetLength(lList, 0);
  end;

  // Копируем файлы
  lList := TDirectory.GetFiles(sSourceDir, '*', TSearchOption.soTopDirectoryOnly);
  try
    for i := Low(lList) to High(lList) do
    begin
      sDestName := TPath.Combine(sDestDir, ExtractFileName(lList[i]));
      if TFile.Exists(sDestName) then
      begin
        try
          // Пробуем перезаписать файл без переименования
          TFile.Copy(lList[i], sDestName, True);
        except
          // Если перезаписать не удалось, то переименуем целевой файл во временный и попробуем еще раз
          RenameFile(sDestName, ChangeFileExt(sDestName, ReplaceStr(ExtractFileExt(sDestName), '.', '.~')));
          TFile.Copy(lList[i], sDestName, True);
        end;
      end
      else TFile.Copy(lList[i], sDestName, True);
    end;
  finally
    SetLength(lList, 0);
  end;
end;

{ == Удаление файлов по списку ================================================= }

procedure rsu2_DeleteFiles(const sExePath, sFileList: string);
var
  i, iCount: Integer;
  sFile: string;
begin
  iCount := WordCount(sFileList, [';']);
  for i := 1 to iCount do
  begin
    sFile := IncludeTrailingPathDelimiter(sExePath) + Trim(ExtractWord(i, sFileList, [';']));
    if FileExists(sFile) then
    begin
      try
        DeleteFile(sFile);
      except
        on E: Exception do
          ErrorBox(E.Message);
      end;
    end;
  end;
end;

{ == Выполнение файлов по списку =============================================== }

procedure rsu2_ExecFiles(const sTmpPath, sFileList: string);
var
  i, iCount: Integer;
  sFile: string;
begin
  iCount := WordCount(sFileList, [';']);
  for i := 1 to iCount do
  begin
    sFile := IncludeTrailingPathDelimiter(sTmpPath) + Trim(ExtractWord(i, sFileList, [';']));
    if FileExists(sFile) then
      WinExec32(sTmpPath, sFile, SW_SHOWDEFAULT, True, nil, 60);
  end;
end;

{ == Вызов системы самообновления ============================================== }

function rsu2_SelfUpdate(const sSuCfgFile: string; const bSilentMode: Boolean; const iLngId: DWord): TSelfUpdateState;
var
  sExeFile, sExeVer, sInfFile, sTmpPath, sUpdFile, sSfxFile: string;
  uMode: TrSU_UpdMode;
  rVerInf: TrSU_VerData;
  slVerDescr: TStringList;
  bUpdateFound, bFileLoad: Boolean;
  iTryCnt, iSfxRes: Integer;
begin
  Result := suNotFound;
  try
    sExeFile := ParamStr(0);
    sInfFile := ExtractFilePath(sExeFile) + rSU_InfFile;
    slVerDescr := TStringList.Create;
    try
      // -- Поиск обновлений ---------------------------------------------------
      StartWait;
      ShowProgress(rsSU2_CheckSelfUpdates, 5);
      try
        try
          // Удаляем временные файлы
          rsu2_DeleteTempFiles(sExeFile);
          UpdateProgressStep(1); // 1

          // Опрделяем текущую версию программы
          sExeVer := rsu2_GetExeVersion;
          UpdateProgressStep(1); // 2

          // Скачиваем файл описания обновления
          uMode := rsu2_GetFile(sSuCfgFile, sInfFile);
          UpdateProgressStep(1); // 3

          // Читаем описание версии
          rVerInf := rsu2_ReadInfFile(sInfFile, ExtractFileName(sExeFile), sExeVer);
          UpdateProgressStep(1); // 4

          // Сравниваем версии
          bUpdateFound := (rsu2_ExtractBuild(sExeVer) < rsu2_ExtractBuild(rVerInf.sVerId))
                      and (rVerInf.sSource <> EmptyStr);

          // Загружаем описание версии
          if bUpdateFound then
          begin
            case uMode of
              umHTTP:
                rsu2_GetDescription(slVerDescr, rVerInf,
                rHttp_ExtractFilePath(sSuCfgFile) + rSU_UpdDir + '/',
                ExtractFilePath(sExeFile), iLngId);

              umFILE: rsu2_GetDescription(slVerDescr, rVerInf,
                IncludeTrailingPathDelimiter(ExtractFilePath(sSuCfgFile) + rSU_UpdDir),
                ExtractFilePath(sExeFile), iLngId);
            end;
          end;
          UpdateProgressStep(1); // 5
        except
          on E: Exception do
          begin
            Result := suError;
            if not bSilentMode then
              ErrorBox(Format(rsSU2_ErrorCheckUpdates, [E.Message]));
            Exit;
          end;
        end;
      finally
        CloseProgress;
        StopWait;
      end;
      // -- Обновление или вывод сообщения -------------------------------------
      if bUpdateFound then
      begin
        // -- Запрос к пользователю --------------------------------------------
        if rsu2_QueryUpdate(sExeVer, rVerInf, slVerDescr) then
        begin
          // -- Обновление -----------------------------------------------------
          StartWait;
          ShowProgress(Format(rsSU2_InstallSelfUpdates, [rVerInf.sVerId]), 14);
          try
            try
              // Генерируем временный каталог для обновления
              sTmpPath := ExtractFilePath(sExeFile) + rSU_TempDir;
              sUpdFile := sTmpPath + Format(rSU_UpdFile, [rVerInf.sVerId]);
              sSfxFile := sTmpPath + rVerInf.sOrigin;
              try
                // Удаляем временный каталог, если он был ("на всякий случай")
                TDirectory.Delete(ExcludeTrailingPathDelimiter(sTmpPath), True);
                UpdateProgressStep(1); // 1

                // Создаем временный каталог для обновления
                TDirectory.CreateDirectory(sTmpPath);
                UpdateProgressStep(1); // 2

                // Загружаем файл для обновления (3 попытки)
                iTryCnt := 0;
                repeat
                  bFileLoad := True;
                  try
                    // Удаляем файл, если он уже был
                    if FileExists(sUpdFile) then
                      TFile.Delete(sUpdFile);

                    // Загружаем файл
                    rsu2_GetFile(rVerInf.sSource, sUpdFile);

                    // Проверим, скачался ли файл
                    if not FileExists(sUpdFile) then
                      raise Exception.CreateFmt(rsErrFileNotFound, [sUpdFile]);

                    // Проверяем контрольную сумму файла
                    if (rVerInf.sCrc32 <> EmptyStr) and not SameText(FileCRC32_STR(sUpdFile), rVerInf.sCrc32) then
                      raise Exception.Create(rsSU2_ErrorBadCrc32);
                  except
                    on E: Exception do
                    begin
                      bFileLoad := False;
                      Inc(iTryCnt);
                      if iTryCnt >= 3 then raise;
                    end;
                  end;
                until bFileLoad;
                UpdateProgressStep(1); // 3

                // Файл обновления загружен - переименовываем его
                TFile.Move(sUpdFile, sSfxFile);
                UpdateProgressStep(1); // 4

                // На всякий еще раз проверим, есть ли такой файл
                if not FileExists(sSfxFile) then
                  raise Exception.CreateFmt(rsErrFileNotFound, [sSfxFile]);
                UpdateProgressStep(1); // 5

                // Распаковываем архив (выполняем его)
                iSfxRes := WinExec32(sTmpPath, sSfxFile, SW_SHOWNORMAL, True, nil, 60);
                if iSfxRes <> S_OK then
                  raise Exception.Create(GetSystemError);
                UpdateProgressStep(1); // 6

                // Удаляем сам архив из временной папки
                iTryCnt := 0;
                while FileExists(sSfxFile) do
                begin
                  if not DeleteFile(sSfxFile) then
                  begin
                    Inc(iTryCnt);
                    if iTryCnt > 100 then
                      raise Exception.Create(GetSystemError);
                    Delay(100);
                  end;
                end;
                UpdateProgressStep(1); // 7

                // Проверим, появились ли файлы во временной папке
                if TDirectory.IsEmpty(sTmpPath) then
                  raise Exception.CreateFmt(rsErrFileNotFound, [sTmpPath + '*']);
                UpdateProgressStep(1); // 8

                // Удаляем файлы "перед обновлением"
                if rVerInf.sGlbDeleteBefore <> EmptyStr then
                  rsu2_DeleteFiles(ExtractFilePath(sExeFile), rVerInf.sGlbDeleteBefore);
                if rVerInf.sExeDeleteBefore <> EmptyStr then
                  rsu2_DeleteFiles(ExtractFilePath(sExeFile), rVerInf.sExeDeleteBefore);
                UpdateProgressStep(1); // 9

                // Выполняем файлы "перед обновлением"
                if rVerInf.sGlbExecBefore <> EmptyStr then
                  rsu2_ExecFiles(sTmpPath, rVerInf.sGlbExecBefore);
                if rVerInf.sGlbExecBefore <> EmptyStr then
                  rsu2_ExecFiles(sTmpPath, rVerInf.sGlbExecBefore);
                UpdateProgressStep(1); // 10

                // Переписываем файлы из временной папки в основную
                rsu2_CopyFiles(sTmpPath, ExtractFilePath(sExeFile));
                UpdateProgressStep(1); // 11

                // Выполняем файлы "после обновления"
                if rVerInf.sGlbExecAfter <> EmptyStr then
                  rsu2_ExecFiles(sTmpPath, rVerInf.sGlbExecAfter);
                if rVerInf.sGlbExecAfter <> EmptyStr then
                  rsu2_ExecFiles(sTmpPath, rVerInf.sGlbExecAfter);
                UpdateProgressStep(1); // 12

                // Удаляем файлы "после обновления"
                if rVerInf.sGlbDeleteAfter <> EmptyStr then
                  rsu2_DeleteFiles(ExtractFilePath(sExeFile), rVerInf.sGlbDeleteAfter);
                if rVerInf.sExeDeleteAfter <> EmptyStr then
                  rsu2_DeleteFiles(ExtractFilePath(sExeFile), rVerInf.sExeDeleteAfter);
                UpdateProgressStep(1); // 13

                // Возвращаем результат
                Result := suInstalled;
              finally
                // Удаляем временный каталог, если он есть
                if DirectoryExists(ExcludeTrailingPathDelimiter(sTmpPath)) then
                  TDirectory.Delete(ExcludeTrailingPathDelimiter(sTmpPath), True);
                UpdateProgressStep(1); // 14
              end;
            except
              on E: Exception do
              begin
                Result := suError;
                ErrorBox(Format(rsSU2_ErrorInstallUpdate, [E.Message]));
              end;
            end;
          finally
            CloseProgress;
            StopWait;
          end;

          // Выводим сообщение
          if Result = suInstalled then
            CautionBox(Format(rsSU2_UpdateOk, [rVerInf.sDescr]));
        end;
      end
      else begin
        if not bSilentMode then
          InfoBox(rsSU2_UpdatesNotFound);
      end;
    finally
      // -- Завершение работы --------------------------------------------------
      slVerDescr.Free;
      // Удаляем информационный файл, если он скачан
      if (sInfFile <> EmptyStr) and FileExists(sInfFile) then
      begin
        DeleteFile(sInfFile);
        if TDirectory.IsEmpty(ExtractFilePath(sInfFile)) then
          TDirectory.Delete(ExtractFilePath(sInfFile), False);
      end;
    end;
  except
    on E: Exception do
    begin
      ErrorBox(Format(rsSU2_ErrorMain, [E.Message]));
      Result := suError;
    end;
  end;
end;

end.
