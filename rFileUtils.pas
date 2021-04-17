unit rFileUtils;

interface

uses
  SysUtils, Classes, Windows;

// Размер файла ----------------------------------------------------------------
function GetFileSize(const FileName: string): Int64;
function FileGetSize(const FileName: string; const RaiseIsError: Boolean = False): Int64;
function FileHandleGetSize(const FileHandle: THandle; const RaiseIsError: Boolean = False): Int64;
function FileSizeToStr(const iSize: Int64): string;
function FileGetSizeS(const FileName: string): string;

// Проверка наличия файлов по маске --------------------------------------------
function FilesExists(const Directory, FileMask: string; const SubDirs: Boolean): Boolean;

implementation

uses
  Types, IOUtils, rSysUtils;

// Размер файла ----------------------------------------------------------------
function GetFileSize(const FileName: string): Int64;
var
  SearchRec: TSearchRec;
begin
  if FindFirst(ExpandFileName(FileName), faAnyFile, SearchRec) = 0
  then Result := SearchRec.Size
  else Result := -1;
  System.SysUtils.FindClose(SearchRec);
end;

function FileGetSize(const FileName: string; const RaiseIsError: Boolean = False): Int64;
var
  FileHandle: THandle;
begin
  Result := -1;
  FileHandle := FileOpen(FileName, fmOpenRead or fmShareDenyWrite);
  try
    if FileHandle <> INVALID_HANDLE_VALUE then
      Result := FileHandleGetSize(FileHandle, RaiseIsError)
    else
      if RaiseIsError then
        RaiseSystemError;
  finally
    FileClose(FileHandle);
  end;
end;

function FileHandleGetSize(const FileHandle: THandle; const RaiseIsError: Boolean = False): Int64;
var
  dwLoSize, dwHiSize: DWord;
  iLastError: Cardinal;
begin
  Result := -1;
  dwLoSize := Windows.GetFileSize(FileHandle, @dwHiSize);
  iLastError := GetLastError;
  if (dwLoSize = INVALID_FILE_SIZE) and (iLastError <> NO_ERROR) then
  begin
    if RaiseIsError then
      RaiseSystemError(iLastError);
  end
  else begin
    Int64Rec(Result).Lo := dwLoSize;
    Int64Rec(Result).Hi := dwHiSize;
  end;
end;

function FileSizeToStr(const iSize: Int64): string;
const
  iKb = 1024;
  iMb = 1024 * 1024;
  iGb = 1024 * 1024 * 1024;
  fKb = '%.2n Kb';
  fMb = '%.2n Mb';
  fGb = '%.2n Gb';
  fSb = '%d b';
begin
  Result := '';
  if iSize > 0 then
  begin
    if iSize > iGb
    then Result := Format(fGb, [iSize / iGb])
    else begin
      if iSize > iMb
      then Result := Format(fMb, [iSize / iMb])
      else begin
        if iSize > iKb
        then Result := Format(fKb, [iSize / iKb])
        else Result := Format(fSb, [iSize]);
      end;
    end;
  end;
end;

function FileGetSizeS(const FileName: string): string;
begin
  Result := FileSizeToStr(FileGetSize(FileName, True));
end;

// Проверка наличия файлов по маске --------------------------------------------
function FilesExists(const Directory, FileMask: string; const SubDirs: Boolean): Boolean;
var
  lFiles: TStringDynArray;
begin
  Result := False;
  if SubDirs
  then lFiles := TDirectory.GetFiles(Directory, FileMask, TSearchOption.soAllDirectories, nil)
  else lFiles := TDirectory.GetFiles(Directory, FileMask, TSearchOption.soTopDirectoryOnly, nil);
  try
    Result := Length(lFiles) > 0;
  finally
    SetLength(lFiles, 0);
  end;
end;

end.
