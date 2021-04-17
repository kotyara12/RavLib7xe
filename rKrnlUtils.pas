unit RKrnlUtils;

interface

uses
  TlHelp32, Windows, Classes, SysUtils;

type
  TProcessList32 = array of TProcessEntry32;
  TModuleList32  = array of TModuleEntry32;

function  ProcessIsRunning(const ExeName: string; const bSelfIgnored: Boolean): Boolean;

procedure GetProcessList(var ProcessList: TProcessList32);
procedure GetModuleList(var ModuleList: TModuleList32);

implementation

uses
  RDialogs;

function ProcessIsRunning(const ExeName: string; const bSelfIgnored: Boolean): Boolean;
var
  hSnapshoot: THandle;
  pe32: TProcessEntry32;
  hSelfProcessId: DWORD;
begin
  Result := False;
  hSnapshoot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hSnapshoot <> THandle(-1) then
  begin
    try
      pe32.dwSize := SizeOf(TProcessEntry32);
      if (Process32First(hSnapshoot, pe32)) then
      begin
        if bSelfIgnored
        then hSelfProcessId := GetCurrentProcessId
        else hSelfProcessId := 0;
        repeat
          Result := SameText(ExeName, pe32.szExeFile)
                and (pe32.th32ProcessID <> hSelfProcessId);
        until Result or not Process32Next(hSnapshoot, pe32);
      end;
    finally
      CloseHandle(hSnapshoot);
    end;
  end;
end;

procedure GetProcessList(var ProcessList: TProcessList32);
var
  hSnapshoot: THandle;
  pe32: TProcessEntry32;
begin
  SetLength(ProcessList, 0);
  hSnapshoot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hSnapshoot = THandle(-1) then
    RaiseLastOSError;
  try
    pe32.dwSize := SizeOf(TProcessEntry32);
    if (Process32First(hSnapshoot, pe32)) then
    begin
      repeat
        SetLength(ProcessList, Length(ProcessList) + 1);
        ProcessList[High(ProcessList)] := pe32;
      until not Process32Next(hSnapshoot, pe32);
    end;
  finally
    CloseHandle(hSnapshoot);
  end;
end;

procedure GetModuleList(var ModuleList: TModuleList32);
var
  hSnapshoot: THandle;
  me32: TModuleEntry32;
begin
  SetLength(ModuleList, 0);
  hSnapshoot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hSnapshoot = THandle(-1) then
    RaiseLastOSError;
  try
    me32.dwSize := SizeOf(TModuleEntry32);
    if (Module32First(hSnapshoot, me32)) then
    begin
      repeat
        SetLength(ModuleList, Length(ModuleList) + 1);
        ModuleList[High(ModuleList)] := me32;
      until not Module32Next(hSnapshoot, me32);
    end;
  finally
    CloseHandle(hSnapshoot);
  end;
end;

end.
